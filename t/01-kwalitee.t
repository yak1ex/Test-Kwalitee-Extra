use Test::More;
eval {
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(!has_example !metayml_declares_perl_version));
};

plan( skip_all => "Test::Kwalitee::PrereqMatchesUse not installed: $@; skipping") if $@;
