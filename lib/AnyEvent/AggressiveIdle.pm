package AnyEvent::AggressiveIdle;

use Carp;
use AnyEvent;
use AnyEvent::Util;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION    = '0.03';

our @EXPORT     = qw(aggressive_idle);
our @EXPORT_OK  = qw(stop_aggressive_idle aggressive_idle);
our %EXPORT_TAG = ( all => [@EXPORT_OK] );

sub stop_aggressive_idle($) {
    our (%IDLE, $WATCHER);

    my ($no) = @_;

    croak "Invalid idle identifier: $no"
        unless $no and !ref($no) and $IDLE{$no};

    delete $IDLE{$no};
    undef $WATCHER unless %IDLE;
    return;
}

sub aggressive_idle(&) {
    our ($WOBJ, $WOBJR, %IDLE, $WATCHER, $NO);
    ($WOBJR, $WOBJ) = portable_pipe unless defined $WOBJ;
    $NO = 0 unless defined $NO;

    $WATCHER = AE::io $WOBJ, 1, sub {
        # localize keys (because idle processes can change
        # watchers list)
        my @pid = keys %IDLE;
        for (@pid) {
            next unless exists $IDLE{$_};
            $IDLE{$_}->($_);
        }
    } unless %IDLE;

    my $no = ++$NO;
    $IDLE{$no} = $_[0];

    return unless defined wantarray;
    return guard { stop_aggressive_idle $no };
}



1;
__END__

=head1 NAME

AnyEvent::AggressiveIdle - Aggressive idle processes for AnyEvent.

=head1 SYNOPSIS

    use AnyEvent::AggressiveIdle qw(aggressive_idle};

    aggressive_idle {
        ... do something important
    };


    my $idle;
    $idle = aggressive_idle {
        ... do something important

        if (FINISH) {
            undef $idle;    # do not call the sub anymore
        }
    };

=head1 DESCRIPTION

Sometimes You need to do something that takes much time but can be
split into elementary phases. If You use L<AE::idle|AnyEvent/idle>
and You program is a highload project, idle process can be delayed
for much time (second, hour, day, etc). L<aggressive_idle> will be
called for each L<AnyEvent> loop cycle. So You can be sure that Your
idle process will continue.

=head1 EXPORTS

=head2 aggressive_idle

Register Your function as aggressive idle watcher. If it is called
in B<VOID> context, the watcher wont be deinstalled. Be carrefully.

In B<NON_VOID> context the function returns a L<guard|AnyEvent::Util/guard>.
Hold the guard until You want to cancel idle process.


=head2 stop_aggressive_idle

You can use the function to stop idle process. The function receives
idle process B<PID> that can be received in idle callback (the first
argument).

Example:

    use AnyEvent::AggressiveIdle ':all'; # or:
    use AnyEvent::AggressiveIdle qw(aggressive_idle stop_aggressive_idle);

    aggressive_idle {
        my ($pid) = @_;
        ....

        stop_aggressive_idle $pid;
    }

The function will throw an exception if invalid PID is received.

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
