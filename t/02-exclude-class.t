use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(:no_plan !:optional));
};

plan( skip_all => "Test::Kwalitee::PrereqMatchesUse not installed: $@; skipping") if $@;

ok(Test::Builder->new->current_test == 18);
