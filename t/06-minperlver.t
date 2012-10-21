use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(:minperlver 5.005 !:core !:optional prereq_matches_use));
};

plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
