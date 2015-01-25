package ZnapZend::Worker::default;

use Mojo::Base -base;
use ZnapZend::Utils;

has schema => sub {
    my $self = shift;
    my $sv   = ZnapZend::Utils->new(); 

    return {
        dataset     => {
            validator   => $sv->dataSet(),
            description => 'destination dataset',
            example     => 'root@backupdest:backuptank/bakdata',
        },
        plan    => {
            members => {
                '\d+[yMwdhms]' => {
                    regex => 1,
                    validator   => $sv->regexp(qr/^\d+[yMwdhms]$/),
                    description => 'destination dataset backup plan element (\d+[yMwdhms])',
                    example     => "1d => '1h'",
                },
            },
        },
        mbuffer => {
            validator   => $sv->regexp(qr/mbuffer/),
            description => 'mbuffer path backup',
        },
    };
};

has globSchema => sub {
    my $self = shift;
    my $sv = ZnapZend::Utils->new();

    return {
        binaries => {
            members => {
                ssh => {
                    validator => $sv->file('<'),
                },
            },
        },
        workers => {
            members => {
                default => {
                    members => {
                        mbuffer => {
                            optional => 1,
                            validator => $sv->file('<'),
                        },
                    },
                },
            },
        },
    };
};

has cfg => sub { {} };

sub sendWorker {

}

1;

__END__

=head1 NAME

ZnapZend::Worker::default - default class for implementing znapzend plugins

=head1 SYNOPSIS

use ZnapZend::Worker::default;
...
my $znapWrk = ZnapZend::Worker::default->new();
...

=head1 DESCRIPTION

default plugin for znapzend

=head1 ATTRIBUTES

=head2 schema

configuration schema template

=head1 METHODS

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

