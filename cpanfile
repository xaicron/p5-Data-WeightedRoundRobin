requires 'Scope::Guard';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};

on test => sub {
    requires 'Test::More', '0.96';
};
