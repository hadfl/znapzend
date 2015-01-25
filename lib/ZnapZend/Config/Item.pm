package ZnapZend::Config::Item;

use Mojo::Base -base;
use Data::Processor;
use ZnapZend::Utils;
use Data::Dumper;

has workerPath => sub {
    ['ZnapZend::Worker'];
};

has schema => sub {
    my $self = shift;
    my $sv   = ZnapZend::Utils->new(); 

    my $backItem = {
        dataset     => {
            validator   => $sv->dataSet(),
            description => 'source dataset',
        },
        plan    => {
            members => {
                '\d+[yMwdhms]' => {
                    regex => 1,
                    validator   => $sv->regexp(qr/^\d+[yMwdhms]$/),
                    description => 'source dataset backup plan element',
                },
            },
        },
        destinations => {
            optional => 1,
            array    => 1,
            members  => {
                dataset     => {
                    validator   => $sv->dataSet(),
                    description => 'destination dataset',
                },
                plan    => {
                    members => {
                        '\d+[yMwdhms]' => {
                            regex => 1,
                            validator   => $sv->backupPlan(),
                            description => 'destination dataset backup plan',
                        },
                    },
                },
                worker_cfg  => {
                    description => 'dummy entry. this will be replaced once the worker is loaded',
                },
                worker      => {
                    description => 'Worker Module to load for this backup destination',
                    transformer => sub {
                        my ($value, $parent) = @_;
                        return {
                            name => $value,
                            obj  => $self->loadWorker($value, $parent->{worker_cfg}),
                        };
                    },
                },
            },
        },
    };

    return {
        GLOBAL => {
            members => {
                workers => {
                    members => {
                    },
                },
            },
        },
        BACKUPSETS => {
            array => 1,
            members => {
                %$backItem,
                recursive       => {
                    validator   => $sv->elemOf(qw(on off)),
                    description => 'recursive backup',
                },
                subdatasets  => {
                    optional => 1,
                    array    => 1,
                    members  => {
                        %$backItem,
                    },
                },
                arraytest => {
                    array => 1,
                    validator => $sv->regexp(qr/^\d+$/, 'element must be numeric'),
                },
            },
        },
    };
};

has cfg => sub { die "must provide a config\n"; };

has workerInventory => sub {
    my $self   = shift;
    my $workerPath = $self->workerPath;
    my %workers;
    for my $path (@INC){
        for my $pPath (@$workerPath) {
            my @pDirs = split /::/, $pPath;
            my $fPath = File::Spec->catdir($path, @pDirs, '*.pm');
            for my $file (glob($fPath)) {
                my ($volume, $modulePath, $moduleName) = File::Spec->splitpath($file);
                $moduleName =~ s/\.pm$//;
                $workers{$moduleName} = {
                    module => $pPath . '::' . $moduleName,
                    file   => $file
                }
            }
        }
    }
    return \%workers;
};

sub snapWorker {
    my $self = shift;

    my $dp = Data::Processor->new($self->schema);

    my @error = $dp->validate($self->cfg)->as_array;

#    print Dumper $self->cfg;
#    print Dumper $self->schema;
    print Dumper @error;
}

sub sendWorker {
    my $self = shift;
    print "sendWorker\n";
}

sub loadWorker {
    my $self       = shift;
    my $workerName = shift;
    my $cfg        = shift;
    my $file = $self->workerInventory->{$workerName} or do {
       # $self->log->error("Worker Module $workerName not found");
       die "module '$workerName' not found\n";
    };
    require $file->{file};
    no strict 'refs';
    my $workerObj = "$file->{module}"->new();
    my $validator = Data::Processor->new($workerObj->schema);
    for ($validator->validate($cfg)->as_array){
        die {msg => $_};
    }
    $workerObj->cfg($cfg);

    #global schema; references for convenience
    my $globSect       = $self->schema->{GLOBAL}->{members};
    my $workerGlobSect = $workerObj->globSchema;

    for my $item (keys %$workerGlobSect){
        #don't process 'workers'
        next if $item eq 'workers';

        if (!exists $globSect->{$item}){
            $globSect->{$item} = $workerGlobSect->{$item};
        }
        else{
            if (my $validator = $globSect->{$item}->{validator}){
                $globSect->{$item}->{validator} = sub {
                    return $validator->(@_) // $workerGlobSect->{$item}->{validator}->(@_);
                };
            }
            else{
                $globSect->{$item}->{validator} = sub {
                    return $workerGlobSect->{$item}->{validator}->(@_);
                };
            }
        }
    }

    #class specific schema
    $globSect->{workers}->{members}->{$workerName}
        = $workerGlobSect->{workers}->{members}->{$workerName};
    
    return $workerObj;
}

1;

__END__

=head1 NAME

ZnapZend::Worker::default - default class for implementing znapzend plugins

=head1 SYNOPSIS

use ZnapZend::Config::Item
...
my $znapCfgItem = ZnapZend::Config::Item->new();
...

=head1 DESCRIPTION

default plugin for znapzend

=head1 ATTRIBUTES

=head2 confSchema

configuration schema template

=head1 METHODS

=head2 snapWorker

snapshot worker

=head2 sendWorker

send/recv worker

=head1 COPYRIGHT

Copyright (c) 2015 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>,
S<Dominik Hassler E<lt>hadfl@cpan.orgE<gt>>

=head1 HISTORY

 2015-01-20 had Initial Version

=cut

