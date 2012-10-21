use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(!has_example));
};

plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
