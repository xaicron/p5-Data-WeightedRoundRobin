use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);

subtest 'remove foo' => sub {
    my $guard = $dwr->save;
    $dwr->remove('foo');
    is $dwr->next, 'bar';
};

subtest 'remove bar' => sub {
    my $guard = $dwr->save;
    $dwr->remove('bar');
    is $dwr->next, 'foo';
};

done_testing;
