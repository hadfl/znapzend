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
        plan        => {
            validator   => $sv->backupPlan(),
            description => 'source dataset backup plan',
        },
        destinations => {
            optional => 1,
            array    => 1,
            members  => {
                dataset     => {
                    validator   => $sv->dataSet(),
                    description => 'destination dataset',
                },
                plan        => {
                    validator   => $sv->backupPlan(),
                    description => 'destination dataset backup plan',
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
    };
};

has cfg => sub {
    {
        recursive => 'on',
        dataset => 'tank/test',
        plan => '1w=>1h',
        destinations => [
            {
                dataset => 'backuptank/test',
                plan => '1w=>1h',
                worker => 'default',
                worker_cfg => {
                    mbuffer => 'mbuffer',
                },
            },
            {
                dataset => 'backuptank/test2',
                plan => '1w=>12h',
                worker => 'network',
                worker_cfg => {
                    mbuffer => 'mbuffer',
                    mbuffer_port => '9200',
                },
            },
        ],
        arraytest => [0, 2, 3, 4],
    }
};

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

    my $dp = Data::Processor->new(schema => $self->schema);

    my @error = $dp->validate(data => $self->cfg, verbose => 1)->as_array();

    print Dumper @error;
    print Dumper $self->cfg;
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
        $self->log->error("Worker Module $workerName not found");
    };
    require $file->{file};
    no strict 'refs';
    my $workerObj = "$file->{module}"->new();
    my $validator = Data::Processor->new(schema => $workerObj->schema);
    for ($validator->validate(data => $cfg)->as_array){
        die {msg => $_};
    }
    $workerObj->cfg($cfg);
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

