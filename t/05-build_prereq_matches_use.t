use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Builder->new->todo_start('Tools cannot handle complex requirements e.g. TestSuggets');
	Test::Kwalitee::Extra->import(qw(!:core !:optional build_prereq_matches_use));
};

plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
