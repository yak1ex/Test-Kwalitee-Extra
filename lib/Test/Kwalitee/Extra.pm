package Test::Kwalitee::Extra;

use strict;
use warnings;

# ABSTRACT: Run Kwalitee tests including optional indicators, especially, prereq_matches_use
# VERSION

use version 0.77;
use Cwd;
use Carp;
use File::Find;
use File::Spec;
use Test::Builder;
use MetaCPAN::API::Tiny;
use Module::CPANTS::Analyse 0.87;
use Module::CPANTS::Kwalitee::Prereq;
use Module::CoreList;
use Module::Extract::Namespaces;

sub _exclude_proper_libs
{
	my $target_ver = version->parse($Module::CPANTS::Analyse::VERSION);
	return $target_ver == version->parse('0.88') || $target_ver > version->parse('0.89');
}

sub _init
{
	return {
		builder => Test::Builder->new,
		exclude => {
		# can not apply already unpacked dist
			extractable => 1,
			extracts_nicely => 1,
			has_version => 1,
			has_proper_version => 1,
			_exclude_proper_libs() ? (proper_libs => 1) : (),

		# already dirty in test phase
			no_generated_files => 1,
			manifest_matches_dist => 1,

		},
		include => {},
		core => 1,
		optional => 1,
		experimental => 0,
		analyser => Module::CPANTS::Analyse->new({
			distdir => cwd(),
			dist    => cwd(),
		}),
	};
}

sub _pmu_error_desc
{
	my ($error, $remedy, $berror, $bremedy);

	my $ref = Module::CPANTS::Kwalitee::Prereq->kwalitee_indicators;
	foreach my $val (@$ref) {
		($error, $remedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'prereq_matches_use';
		($berror, $bremedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'build_prereq_matches_use';
	}
	$error   ||= q{This distribution uses a module or a dist that's not listed as a prerequisite.};
	$remedy  ||= q{List all used modules in META.yml requires};
	$berror  ||= q{This distribution uses a module or a dist in it's test suite that's not listed as a build prerequisite.};
	$bremedy ||= q{List all modules used in the test suite in META.yml build_requires};

	return ($error, $remedy, $berror, $bremedy);
}

sub _check_ind
{
	my ($env, $ind) = @_;
	return 1 if $env->{include}{$ind->{name}};
	return 0 if $env->{exclude}{$ind->{name}};
	if($ind->{is_experimental}) { # experimental
		return $env->{experimental};
	} elsif($ind->{is_extra}) { # optional
		return $env->{optional};
	} else { # core
		return $env->{core};
	}
}

sub _is_core
{
	my ($module, $minperlver) = @_;
	return 0 if defined Module::CoreList->removed_from($module);
	my $fr = Module::CoreList->first_release($module);
	return 0 if ! defined $fr;
	return 1 if version->parse($minperlver) >= version->parse($fr);
	return 0;
}

sub _do_test_one
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my ($test, $ok, $name, $error, $remedy, $more) = @_;

	$test->ok($ok, $name);
	if(!$ok) {
		$test->diag('  Detail: ', $error);
		$test->diag('  Detail: ', ref($more) ? join(', ', @$more) : $more) if defined $more;
		$test->diag('  Remedy: ', $remedy);
	}
}

sub _do_test_pmu
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my ($env) = @_;
	my ($error, $remedy, $berror, $bremedy) = _pmu_error_desc();
	my ($test, $analyser) = @{$env}{qw(builder analyser)};
	return if ! _check_ind($env, { name => 'prereq_matches_use', is_extra => 1 }) &&
	          ! _check_ind($env, { name => 'build_prereq_matches_use', is_experimental => 1 });

	my $minperlver;
	if(exists $env->{minperlver}) {
		$minperlver = $env->{minperlver};
	} else {
		$minperlver = $];
		for my $val (@{$analyser->d->{prereq}}) {
			if($val->{requires} eq 'perl') {
				$minperlver = $val->{version};
				last;
			}
		}
	}
	my $mcpan = MetaCPAN::API::Tiny->new;

	my (%build_prereq, %prereq);
	foreach my $val (@{$analyser->d->{prereq}}) {
		next if _is_core($val->{requires}, $minperlver);
		my $result = $mcpan->module($val->{requires});
		croak 'Query to MetaCPAN failed for $val->{requires}' if ! exists $result->{distribution};
		$prereq{$result->{distribution}} = 1 if $val->{is_prereq} || $val->{is_optional_prereq};
		$build_prereq{$result->{distribution}} = 1 if $val->{is_prereq} || $val->{is_build_prereq} || $val->{is_optional_prereq};
	}

	# Look at META.yml to determine if the author specified modules provided
	# by the distribution that should not be indexed by CPAN.
	my $packages_not_indexed = _get_packages_not_indexed(
		d       => $analyser->d,
		distdir => $analyser->distdir,
	);

	my (@missing, @bmissing);
	while(my ($key, $val) = each %{$analyser->d->{uses}}) {
		next if version::is_lax($key);
		# Skip packages provided by the distribution but not indexed by CPAN.
		next if scalar( grep {$key eq $_} @$packages_not_indexed ) != 0;
		next if _is_core($key, $minperlver);
		my $result = $mcpan->module($key);
		croak 'Query to MetaCPAN failed for $val->{requires}' if ! exists $result->{distribution};
		my $dist = $result->{distribution};
		push @missing, $key.' in '.$dist if $val->{in_code} && ! exists $prereq{$dist};
		push @bmissing, $key.' in '.$dist if $val->{in_tests} && ! exists $build_prereq{$dist};
	}

	_do_test_one($test, @missing == 0, 'prereq_matches_use by '.__PACKAGE__, $error, $remedy, 'Missing: '.join(', ', sort @missing))
		if _check_ind($env, { name => 'prereq_matches_use', is_extra => 1 });
	_do_test_one($test, @bmissing == 0, 'build_prereq_matches_use by '.__PACKAGE__, $berror, $bremedy, 'Missing: '.join(', ', sort @bmissing))
		if _check_ind($env, { name => 'build_prereq_matches_use', is_experimental => 1 });
}

# Look at META.yml to determine if the author specified modules provided
# by the distribution that should not be indexed by CPAN.
sub _get_packages_not_indexed
{
	my (%args) = @_;
	my $d = delete $args{'d'};
	my $distdir = delete $args{'distdir'};

	# Check if no_index exists in META.yml
	my $meta_yml = $d->{'meta_yml'};
	return [] if !defined $meta_yml;
	my $no_index = $meta_yml->{'no_index'};
	return [] if !defined $no_index;

	# Get the uses, to determine which ones are no-index internals.
	my $uses = $d->{'uses'};
	return [] if !defined $uses;

	my $packages_not_indexed = {};

	# Find all the files corresponding to the 'file' and 'directory'
	# sections of 'no_index'.
	my @files = ();

	if (defined $no_index->{'file'}) {
		push @files, map { File::Spec->catdir($distdir, $_) } @{$no_index->{'file'}};
	}

	if (defined $no_index->{'directory'}) {
		my $filter_pm_files = sub {
			return if $File::Find::name !~ /\.pm$/;
			push(@files, $File::Find::name);
		};

		foreach my $directory (@{$no_index->{'directory'}}) {
			File::Find::find(
				$filter_pm_files,
				File::Spec->catdir($distdir, $directory),
			);
		}
	}

	# Extract the namespaces from those files.
	foreach my $file (@files) {
		my @namespaces = Module::Extract::Namespaces->from_file($file);
		foreach my $namespace (@namespaces) {
			next if !exists $uses->{$namespace};
			$packages_not_indexed->{$namespace} = undef;
		}
	}

	# 'package' section of no_index.
	if (defined $no_index->{'package'}) {
		foreach my $package (@{$no_index->{'package'}}) {
			next if !exists $uses->{$package};
			$packages_not_indexed->{$package} = undef;
		}
	}

	# 'namespace' section of no_index.
	if (defined $no_index->{'namespace'}) {
		foreach my $use (keys %$uses) {
			foreach my $namespace (@{$no_index->{'namespace'}}) {
				next if $use !~ /^\Q$namespace\E(?:::|$)/;
				$packages_not_indexed->{$use} = undef;
			}
		}
	}

	return [sort keys %$packages_not_indexed];
}

sub _count_tests
{
	my ($env) = @_;
	my ($test, $analyser) = @{$env}{qw(builder analyser)};
	my $count = 0;
	foreach my $mod (@{$analyser->mck->generators}) {
		foreach my $ind (@{$mod->kwalitee_indicators}) {
			next if $ind->{needs_db};
			next if ! _check_ind($env, $ind);
			++$count;
		}
	}
	# overrides needs_db
	++$count if ! _check_ind($env, { name => 'prereq_matches_use', is_extra => 1 });
	++$count if ! _check_ind($env, { name => 'build_prereq_matches_use', is_experimental => 1 });
	return $count;
}

sub _do_test
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($env) = @_;
	my ($test, $analyser) = @{$env}{qw(builder analyser)};

	if(! $env->{no_plan}) {
		$test->plan(tests => _count_tests(@_));
	}
	foreach my $mod (@{$analyser->mck->generators}) {
		$mod->analyse($analyser);
		foreach my $ind (@{$mod->kwalitee_indicators}) {
			next if $ind->{needs_db};
			next if ! _check_ind($env, $ind);
			_do_test_one(
				$test,
				$ind->{code}($analyser->d, $ind),
				$ind->{name}.' by '.$mod,
				$ind->{error},
				$ind->{remedy},
				$analyser->d->{error}{$ind->{name}}
			);
		}
	}
	_do_test_pmu($env);
}

my %class = ( core => 1, optional => 1, experimental => 1 );

sub import
{
	my ($pkg, @arg) = @_;
	my $env = _init();
	my $ind_seen = 0;
	while(my $arg = shift @arg) {
		if($arg eq ':no_plan') {
			$env->{no_plan} = 1;
		} elsif($arg eq ':minperlver') {
			$env->{minperlver} = shift @arg;
		} elsif($arg =~ /^!:/) {
			warn "Tag $arg appears after indicator" if $ind_seen;
			$arg =~ s/^!://;
			if($arg eq 'all') {
				$env->{core} = $env->{optional} = $env->{experimental} = 1;
			} elsif($arg eq 'none') {
				$env->{core} = $env->{optional} = $env->{experimental} = 0;
			} elsif($class{$arg}) {
				$env->{$arg} = 0;
			} else {
				warn "Unknown tag :$arg is used";
			}
		} elsif($arg =~ /^:/) {
			warn "Tag $arg appears after indicator" if $ind_seen;
			$arg =~ s/^://;
			if($arg eq 'all') {
				$env->{core} = $env->{optional} = $env->{experimental} = 0;
			} elsif($arg eq 'none') {
				$env->{core} = $env->{optional} = $env->{experimental} = 1;
			} elsif($class{$arg}) {
				$env->{$arg} = 1;
			} else {
				warn "Unknown tag :$arg is used";
			}
		} elsif($arg =~ /^!/) {
			$ind_seen = 1;
			$arg =~ s/^!//;
			$env->{exclude}{$arg} = 1;
			delete $env->{include}{$arg};
		} else {
			$ind_seen = 1;
			$env->{include}{$arg} = 1;
			delete $env->{exclude}{$arg};
		}
	}
	_do_test($env);
}

1;
__END__

=head1 SYNOPSIS

  # Simply use, with excluding indicators
  use Test::Kwalitee::Extra qw(!has_example !metayml_declares_perl_version);

  # Use with eval guard, with excluding class
  use Test::More;
  eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(!:optional)); };
  plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;

  # Typically, this test is limited to author test or release test
  BEGIN { # limited to release test
    unless ($ENV{RELEASE_TESTING}) { # or $ENV{AUTHOR_TESTING} for author test
      require Test::More;
      Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
  }
  use Test::More;
  eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(!:optional)); };
  plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;


=head1 DESCRIPTION

L<CPANTS|http://cpants.cpanauthors.org/> checks Kwalitee indicators, which is not quality 
but automatically-measurable indicators how good your distribution is.
L<Module::CPANTS::Analyse> calcluates Kwalitee but it is not directly applicable to your module test.
CPAN has already had L<Test::Kwalitee> for the test module of Kwalitee.
It is, however, limited to 13 indicators from 35 indicators (core and optional), as of 1.01.
Furthermore, L<Module::CPANTS::Analyse> itself cannot calculate C<prereq_matches_use> indicator.
It is marked as C<needs_db>, but only limited information is needed to calculate the indicator.
This module calculate C<prereq_matches_use> to query needed information to L<MetaCPAN|https://metacpan.org/>.

Currently, 19 core indicators and 9 optional indicators are available in default configuration. See L</INDICATORS> section.

=head1 OPTIONS

You can specify including or excluding an indicator or a tag like L<Exporter>.
Valid tags are C<core>, C<optional> and C<experimental>. For indicators, see L<Module::CPANTS::Analyse>.

Please NOTE that to specify tags are handled a bit differently from L<Exporter>.
First, specifying an indicator is always superior to specifying tags, 
even though specifying an indicator is prior to specifying tags.
For example, 

  use Test::Kwalitee::Extra qw(!has_example :optional);

C<!has_example> is in effect, that is C<has_exaple> is excluded, even though C<has_example> is an C<optional> indicator.

Second, default excluded indicators mentioned in L</INDICATORS> section are not included by specifying tags.
For example, in the above example, C<:optional> does not enable C<is_prereq>.
You can override it by explicitly specifying the indicator:

  use Test::Kwalitee::Extra qw(manifest_matches_dist);

=head2 SPECIAL TAGS

Some tags have special meanings.

=option C<:no_plan>

If specified, do not call C<Test::Builder::plan>.
You may need to specify it, if this test is embedded into other tests.

=option C<:minperlver> <C<version>>

C<prereq_matches_use> indicator ignores core modules.
What modules are in core, however, is different among perl versions.
If minimum perl version is specified in META.yml or such a meta information, it is used as minimum perl version.
Otherewise, C<$]>, the version of the current perl interpreter, is used.

If specified, this option overrides them.

=head1 INDICATORS

In L<Module::CPANTS::Analyse>, prereq_matches_use requires CPANTS DB setup by L<Module::CPANTS::ProcessCPAN>.
is_prereq really requires information of prereq of other modules but prereq_matches_use only needs mappings between modules and dists.
So, this module query the mappings to MetaCPAN by using L<MetaCPAN::API::Tiny>.

For default configuration, indicators are treated as follows:

=begin :list

= Available indicators in core

=for :list
* has_readme
* has_manifest
* has_meta_yml
* has_buildtool
* has_changelog
* no_symlinks
* has_tests
* buildtool_not_executable
* metayml_is_parsable
* metayml_has_license
* metayml_conforms_to_known_spec
* proper_libs
* no_pod_errors
* has_working_buildtool
* has_better_auto_install
* use_strict
* valid_signature
* has_humanreadable_license
* no_cpants_errors

= Available indicators in optional

=for :list
* has_tests_in_t_dir
* has_example
* no_stdin_for_prompting
* metayml_conforms_spec_current
* metayml_declares_perl_version
* prereq_matches_use
* use_warnings
* has_test_pod
* has_test_pod_coverage

= Excluded indicators in core

=begin :list

= Can not apply already unpacked dist

=for :list
* extractable
* extracts_nicely
* has_version
* has_proper_version

= Already dirty in test phase

=for :list
* manifest_matches_dist
* no_generated_files

=end :list

= Excluded indicators in optional

=begin :list

= Needs CPANTS DB

=for :list
* is_prereq

=end :list

=end :list

=head1 SEE ALSO

=for :list
* L<Module::CPANTS::Analyse> - Kwalitee indicators, except for prereq_matches_use, are calculated by this module.
* L<Test::Kwalitee> - Another test module for Kwalitee indicators.
* L<Dist::Zilla::Plugin::Test::Kwalitee::Extra> - Dist::Zilla plugin for this module.
