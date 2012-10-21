use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(!:core !:optional prereq_matches_use));
};

plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
