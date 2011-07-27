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

Data::WeightedRoundRobin - Serve data in a Weighted RoundRobin manner.

=head1 SYNOPSIS

  use Data::WeightedRoundRobin;
  my $dwr = Data::WeightedRoundRobin->new([
      qw/foo bar/,
      { value => 'baz', weight => 50 },
  ]);
  $drw->next; # foo : bar : baz = 100 : 100 : 50

=head1 DESCRIPTION

Data::WeightedRoundRobin is

=head1 METHODS

=over

=item C<< new([$list:ARRAYREF, $option:HASHREF]) >>

Creates a Data::WeightedRoundRobin instance.

  $dwr = Data::WeightedRoundRobin->new();               # empty rr data
  $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);  # foo : bar = 100 : 100

  # foo : bar : baz = 120 : 100 : 50
  $dwr = Data::WeightedRoundRobin->new([
      { value => 'foo', weight => 120 },
      'bar',
      { value => 'baz', weight => 50 },
  ]);

Sets default_weight option, DEFAULT is B<< $Data::WeightedRoundRobin::DEFAULT_WEIGHT >>.

  # foo : bar : baz = 0.3 : 0.7 : 1
  $dwr = Data::WeightedRoundRobin->new([
      { value => 'foo', weight => 0.3 },
      { value => 'bar', weight => 0.7 },
      { value => 'baz' },
  ], { default_weight => 1 });

=item C<< next() >>

Fetch a data.

  my $dwr = Data::WeightedRoundRobin->new([
      qw/foo bar/],
      { value => 'baz', weight => 50 },
  );
  
  # Infinite loop
  while (my $data = $dwr->next) {
      say $data; # foo : bar : baz = 100 : 100 : 50 
  }
 
=item C<< set($list:ARRAYREF) >>

Sets datum.

  $drw->set([
      { value => 'foo', weight => 100 },
      { value => 'bar', weight => 50  },
  ]);

You can specify the following data.

  [qw/foo/]              # eq [ { value => 'foo', weight => 100 } ]
  [{ value => 'foo' }]   # eq [ { value => 'foo', weight => 100 } ]

=item C<< add($value:SCALAR || $value:HASHREF) >>

Add a value. You can add NOT already value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
  is $dwr->add('baz'), 1, 'added baz';
  is $dwr->add('foo'), 0, 'foo is exists';
  is $dwr->add({ value => 'hoge', weight => 80 }), 1, 'added hoge with weight 80';
  is $dwr->add(), undef, 'error';

=item C<< replace($value:SCALAR || $value::HASHREF) >>

Replace a value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo/, { value => 'bar', weight => 50 }]);
  is $dwr->replace('baz'), 1, 'replaced bar'; 
  is $dwr->replace('hoge'), 0, 'hoge is not found';
  is $dwr->replace({ value => 'foo', weight => 80 }), 1, 'replaced foo with weight 80';
  is $dwr->replace(), undef, 'error';

=item C<< remove($value:SCALAR) >>

Remove a value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
  is $dwr->remove('foo'), 1, 'removed foo';
  is $dwr->remove('hoge'), 0, 'hoge is not found';
  is $dwr->remove(), undef, 'error';

=back

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
