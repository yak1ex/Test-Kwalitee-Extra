use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(:no_plan !:core !:optional metayml_is_parsable));
};

plan( skip_all => "Test::Kwalitee::PrereqMatchesUse not installed: $@; skipping") if $@;

ok(Test::Builder->new->current_test == 1);
