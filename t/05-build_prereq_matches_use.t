use Test::Builder::Tester tests => 1;
use Test::More;
use Term::ANSIColor; # Core from 5.006
use FindBin;
use lib $FindBin::Bin;
my ($error, $remedy, $berror, $bremedy) = do 'prereq_matches_use_info.pl'; # To avoid use and require
eval {
	test_out('not ok 1 - build_prereq_matches_use by Test::Kwalitee::Extra');
	test_fail(+7);
	test_diag("  Detail: $berror");
	test_diag('  Detail: Missing: Pod::Coverage::TrustPod in Pod-Coverage-TrustPod, Test::Perl::Critic in Test-Perl-Critic');
	test_diag("  Remedy: $bremedy");

# To specify prereq like TestSuggests can not fix this behavior because complex prereq is not supported by tools.
	require Test::Kwalitee::Extra;
	Test::Kwalitee::Extra->import(qw(:no_plan !:core !:optional build_prereq_matches_use));

	test_test('expected failure of build_prereq_matches_use');
};

plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
