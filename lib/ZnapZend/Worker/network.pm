package ZnapZend::Worker::network;

use Mojo::Base 'ZnapZend::Worker::default';
use Data::Processor;
use ZnapZend::Utils;

has schema => sub {
    my $sv = ZnapZend::Utils->new();
    return {
        %{shift->SUPER::schema},
        mbuffer_port => {
            validator => $sv->regexp(qr/^\d+$/),
         },
    };
};

has globSchema => sub {
    my $self = shift;
    my $sv = ZnapZend::Utils->new();

    return {
        zfs => {
            validator => $sv->regexp(qr/^[\w\/]+$/),
        },
        workers => {
            members => {
                network => {
                    members => {
                        mbuffer => {
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

