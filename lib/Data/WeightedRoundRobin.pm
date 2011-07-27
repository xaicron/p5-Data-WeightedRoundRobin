package Data::WeightedRoundRobin;

use strict;
use warnings;
our $VERSION = '0.01';

our $DEFAULT_WEIGHT = 100;

sub new {
    my ($class, $list, $args) = @_;
    $args ||= {};
    my $self = bless {
        rrlist         => [],
        weights        => 0,
        default_weight => $args->{default_weight} || $DEFAULT_WEIGHT,
    }, $class;
    $self->set($list) if $list;
    return $self;
}

sub _normalize {
    my ($self, $data) = @_;
    return unless defined $data;

    my ($value, $weight);

    # { value => 'foo', weight => 1 }
    if (ref $data eq 'HASH') {
        ($value, $weight) = @$data{qw/value weight/};
        return unless defined $value;
        return if defined $weight && $weight <= 0;
        $weight ||= $self->{default_weight},
    }
    # foo
    else {
        $value  = $data;
        $weight = $self->{default_weight};
    }

    return { value => $value, weight => $weight };
}

sub set {
    my ($self, $list) = @_;
    return unless $list;

    my $normalized = {};
    for my $data (@$list) {
        $data = $self->_normalize($data) || next;
        $normalized->{$data->{value}} = $data->{weight};
    }

    my $rrlist = [];
    my $weights = 0;
    for my $key (sort keys %$normalized) {
        unshift @$rrlist, {
            value  => $key,
            range  => $weights,
            weight => $normalized->{$key},
        };
        $weights += $normalized->{$key};
    }

    $self->{rrlist}  = $rrlist;
    $self->{weights} = $weights;

    return 1;
}

sub add {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};
    $value = $self->_normalize($value) || return;

    my $added = 1;
    for my $data (@$rrlist) {
        if ($data->{value} eq $value->{value}) {
            $added = 0;
            last;
        }
    }

    if ($added) {
        push @$rrlist, $value;
        $self->set($rrlist);
    }

    return $added;
}

sub replace {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};
    $value = $self->_normalize($value) || return;

    my $replaced = 0;
    for my $data (@$rrlist) {
        if ($data->{value} eq $value->{value}) {
            $data = $value;
            $replaced = 1;
            last;
        }
    }

    if ($replaced) {
        $self->set($rrlist);
    }

    return $replaced;
}

sub remove {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};

    my $removed = 0;
    my $newlist = [];
    for my $data (@$rrlist) {
        unless ($data->{value} eq $value) {
            push @$newlist, $data; 
        }
        else {
            $removed = 1;
        }
    }

    if ($removed) {
        $self->set($newlist);
    }

    return $removed;
}

sub next {
    my ($self, $key) = @_;
    my ($rrlist, $weights) = @$self{qw/rrlist weights/};

    my $value;
    my $rweight = rand($weights);
    for my $data (@$rrlist) {
        if ($data->{range} <= $rweight) {
            $value = $data->{value};
            last;
        }
    }
    return $value;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::WeightedRoundRobin -

=head1 SYNOPSIS

  use Data::WeightedRoundRobin;

=head1 DESCRIPTION

Data::WeightedRoundRobin is

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
