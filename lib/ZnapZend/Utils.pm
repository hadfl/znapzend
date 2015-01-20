package ZnapZend::Utils;

use Mojo::Base -base;

sub file {
    my $self = shift;
    my $op   = shift;
    my $msg  = shift;

    return sub {
        my $file = shift;
        return open (my $fh, $op, $file) ? undef : "$msg $file: $!";
    }
}

sub dir {
    my $self = shift;

    return sub {
        my $dir = shift;
        return -d $dir ? undef : "directory $dir does not exist";
    }
}

sub regexp {
    my $self = shift;
    my $rx   = shift;
    my $msg  = shift;
    return sub {
        my $value = shift;
        return $value =~ /$rx/ ? undef : "$msg ($value)";
    }
}

sub elemOf {
    my $self  = shift;
    my $elems = [ @_ ];

    return sub {
        my $value = shift;
        return (grep { $_ eq $value } @$elems) ? undef
            : 'expected a value from the list: ' . join(', ', @$elems);
    }
}

sub dataSet {
    my $self = shift;

    return sub {
        return undef;
    }
}

sub backupPlan {
    my $self = shift;

    return sub {
        return undef;
    }
}

1;

