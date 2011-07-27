use inc::Module::Install;
name 'Data-WeightedRoundRobin';
all_from 'lib/Data/WeightedRoundRobin.pm';

#requires '';

#build_requires '';
test_requires 'Test::More', 0.96;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

auto_set_repository();

WriteAll;
