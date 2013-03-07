use inc::Module::Install;
name 'Data-WeightedRoundRobin';
all_from 'lib/Data/WeightedRoundRobin.pm';

requires 'Scope::Guard';

test_requires 'Test::More', 0.96;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'https://github.com/xaicron/p5-Data-WeightedRoundRobin';

WriteAll;
