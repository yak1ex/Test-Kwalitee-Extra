use strict;
use warnings;

use Test::More;
use Test::Kwalitee::Extra qw();


# List of tests to run.
my $tests =
[
	{
		name     => '"file" section.',
		distdir  => 't/08-_get_packages_not_indexed/',
		no_index => {
			'file' =>
			[
				'LocalTest.pm'
			]
		},
		expected =>
		[
			'LocalTest',
		]
	},
	{
		name     => '"directory" section.',
		distdir  => 't/08-_get_packages_not_indexed/',
		no_index =>
		{
			'directory' =>
			[
				'LocalTest'
			]
		},
		expected =>
		[
			'LocalTest::Test',
		]
	},
	{
		name     => '"package" section.',
		distdir  => 't/08-_get_packages_not_indexed/',
		no_index =>
		{
			'package' =>
			[
				'LocalTest'
			]
		},
		expected =>
		[
			'LocalTest',
		]
	},
	{
		name     => '"namespace" section.',
		distdir  => 't/08-_get_packages_not_indexed/',
		no_index =>
		{
			'namespace' =>
			[
				'LocalTest',
			]
		},
		expected =>
		[
			'LocalTest',
			'LocalTest::Test',
		]
	},
];

plan(tests => scalar(@$tests)+1);

use_ok('Module::CPANTS::Analyse');

foreach my $test (@$tests) {
	# Prepare the Module::CPANTS::Analyse with the specific no_index information
	# for this test.
	my $d = bless(
		{
			'meta_yml' =>
			{
				'no_index' => $test->{'no_index'},
			},
			'uses' =>
			{
				'File::Spec' => {
					'in_code' => 1,
					'in_tests' => 0,
					'module' => 'File::Spec'
				},
				'LocalTest' => {
					'in_code' => 0,
					'in_tests' => 1,
					'module' => 'LocalTest'
				},
				'LocalTest::Test' => {
					'in_code' => 0,
					'in_tests' => 1,
					'module' => 'LocalTest::Test'
				},
			},
		},
		'Module::CPANTS::Analyse',
	);

	# Retrieve a list of packages used by the distribution but not indexed
	# according to META.yml.
	my $packages_not_indexed = Test::Kwalitee::Extra::_get_packages_not_indexed(
		d       => $d,
		distdir => $test->{'distdir'},
	);

	# Make sure the function identified the packages not indexed correctly.
	is_deeply(
		$packages_not_indexed,
		$test->{'expected'},
		$test->{'name'},
	) || diag(explain('Expected: ', $test->{'expected'}, 'Found: ', $packages_not_indexed));
}
