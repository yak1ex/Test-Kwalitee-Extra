package Test::Kwalitee::Extra;

use strict;
use warnings;

# VERSION

use version 0.77;
use Cwd;
use Carp;
use Test::Builder;
use MetaCPAN::API::Tiny;
use Module::CPANTS::Analyse;
use Module::CoreList;

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

		# already dirty in test phase
			no_generated_files => 1,
			manifest_matches_dist => 1,

		# broken in Module::CPANTS::Analyse 0.86 rt.cpan.org #80225
			metayml_conforms_to_known_spec => 1,
			metayml_conforms_spec_current  => 1,
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

# TODO: Retrieve error and remedy directly
sub _do_test_pmu
{
	my ($env, $error, $remedy, $berror, $bremedy) = @_;
	my ($test, $analyser) = @{$env}{qw(builder analyser)};
	return if ! _check_ind($env, { name => 'prereq_matches_use', is_extra => 1 }) &&
	          ! _check_ind($env, { name => 'build_prereq_matches_use', is_experimental => 1 });

	my $minperlver;
	if(exists $env->{minperlver}) {
		$minperlver = $env->{minperlver};
	} else {
		$minperlver = $];
		while(my (undef, $val) = each @{$analyser->d->{prereq}}) {
			if($val->{requires} eq 'perl') {
				$minperlver = $val->{version};
				last;
			}
		}
	}
	my $mcpan = MetaCPAN::API::Tiny->new;

	my (%build_prereq, %prereq);
	while(my (undef, $val) = each @{$analyser->d->{prereq}}) {
		next if _is_core($val->{requires}, $minperlver);
		my $result = $mcpan->module($val->{requires});
		croak 'Query to MetaCPAN failed for $val->{requires}' if ! exists $result->{distribution};
		$prereq{$result->{distribution}} = 1 if $val->{is_prereq} || $val->{is_optional_prereq};
		$build_prereq{$result->{distribution}} = 1 if $val->{is_prereq} || $val->{is_build_prereq} || $val->{is_optional_prereq};
	}
	my (@missing, @bmissing);
	while(my ($key, $val) = each %{$analyser->d->{uses}}) {
		next if _is_core($key, $minperlver);
		my $result = $mcpan->module($key);
		croak 'Query to MetaCPAN failed for $val->{requires}' if ! exists $result->{distribution};
		my $dist = $result->{distribution};
		push @missing, $key.' in '.$dist if $val->{in_code} && ! exists $prereq{$dist};
# Test::Pod% excluded by Module-CPANTS-ProcessCPAN-0.77
		push @bmissing, $key.' in '.$dist if $val->{in_tests} && $key !~ /^Test::Pod/ && ! exists $build_prereq{$dist};
	}

	my @ret;
	push @ret, [ @missing == 0, 'prereq_matches_use by '.__PACKAGE__, $error, $remedy, 'Missing: '.join(', ', sort @missing) ]
		if _check_ind($env, { name => 'prereq_matches_use', is_extra => 1 });
	push @ret, [ @bmissing == 0, 'build_prereq_matches_use by '.__PACKAGE__, $berror, $bremedy, 'Missing: '.join(', ', sort @bmissing) ]
		if _check_ind($env, { name => 'build_prereq_matches_use', is_experimental => 1 });
	return @ret;
}

sub _do_test
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($env) = @_;
	my ($test, $analyser) = @{$env}{qw(builder analyser)};
	my (@ind, $pmu_error, $pmu_remedy, $bpmu_error, $bpmu_remedy);
	foreach my $mod (@{$analyser->mck->generators}) {
		$mod->analyse($analyser);
		foreach my $ind (@{$mod->kwalitee_indicators}) {
			if($ind->{name} eq 'prereq_matches_use') {
				$pmu_error = $ind->{error};
				$pmu_remedy = $ind->{remedy};
			}
			if($ind->{name} eq 'build_prereq_matches_use') {
				$bpmu_error = $ind->{error};
				$bpmu_remedy = $ind->{remedy};
			}
			next if $ind->{needs_db};
			next if ! _check_ind($env, $ind);	
			my $ret = $ind->{code}($analyser->d, $ind);
			push @ind, [ $ret, $ind->{name}.' by '.$mod, $ind->{error}, $ind->{remedy}, $analyser->d->{error}{$ind->{name}} ];
		}
	}
	my (@pmu) = _do_test_pmu($env, $pmu_error, $pmu_remedy, $bpmu_error, $bpmu_remedy);
	push @ind, @pmu if @pmu; 
	if($env->{no_plan}) {
		$test->no_plan;
	} else {
		$test->plan(tests => scalar @ind);
	}
	foreach my $ind (@ind) {
		$test->ok($ind->[0], $ind->[1]);
		if(!$ind->[0]) {
			$test->diag('  Detail: ', $ind->[2]);
			$test->diag('  Detail: ', ref($ind->[4]) ? join(', ', @{$ind->[4]}) : $ind->[4]) if defined $ind->[4];
			$test->diag('  Remedy: ', $ind->[3]);
		}
	}
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
=pod

=head1 NAME

Test::Kwalitee::Extra - Run Kwalitee tests including optional indicators, especially, prereq_matches_use.

=head1 SYNOPSIS

  # Simply use, with disabling indicators
  use Test::Kwalitee::Extra qw(!has_example !metayml_declares_perl_version);

  # Use with eval guard, with disabling class
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

L<CPANTS|http://cpants.charsbar.org/> checks Kwalitee indicators, which is not quality 
but automatically-measurable indicators how good your distribution is.
L<Module::CPANTS::Analyse> calcluates Kwalitee but it is not directly applicable to your module test.
CPAN has already had L<Test::Kwalitee> for the test module of Kwalitee.
It is, however, limited to 13 indicators from 34 indicators (core and optional), as of 1.01.
Furthermore, L<Module::CPANTS::Analyse> itself cannot calculate C<prereq_matches_use> indicator.
It is marked as C<needs_db>, but only limited information is needed to calculate the indicator.
This module calculate C<prereq_matches_use> to query needed information to L<MetaCPAN|https://metacpan.org/>.

Currently, 18 core indicators and 8 optional indicators are available in default configuration. See L</INDICATORS> section.

=head1 OPTIONS

You can specify including or excluding an indicator or a tag like L<Exporter>.
Valid tags are C<core>, C<optional> and C<experimental>. See L<Module::CPANTS::Analyse> for indicators.

Please NOTE that to specify tags are handled a bit differently from L<Exporter>.
First, specifying an indicator is always superior to specifying tags, 
even though specifying an indicator is prior to specifying tags.
For example, 

  use Test::Kwalitee::Extra qw(!has_example :optional);

C<!has_example> is in effect, that is C<has_exaple> is excluded, even though C<has_example> is an C<optional> indicator.

Second, default excluded indicators mentioned in L</INDICATORS> section are not included by specifying tags.
For example, the above example, C<:optional> does not enable C<is_prereq> and C<metayml_conforms_spec_current>.
You can override it by explicitly specifying the indicator:

  use Test::Kwalitee::Extra qw(metayml_conforms_spec_current);

=head1 INDICATORS

In L<Module::CPANTS::Analyse>, prereq_matches_use requires CPANTS DB setup by L<Module::CPANTS::ProcessCPAN>.
is_prereq really requires information of prereq of other modules but prereq_matches_use only needs mappings between modules and dists.
So, this module query the mappings to MetaCPAN by using L<MetaCPAN::API::Tiny>.

For default configuration, indicators are treated as follows:

=over 4

=item Available indicators in core

=over 4

=item *

has_readme

=item *

has_manifest

=item *

has_meta_yml

=item *

has_buildtool

=item *

has_changelog

=item *

no_symlinks

=item *

has_tests

=item *

buildtool_not_executable

=item *

metayml_is_parsable

=item *

metayml_has_license

=item *

proper_libs

=item *

no_pod_errors

=item *

has_working_buildtool

=item *

has_better_auto_install

=item *

use_strict

=item *

valid_signature

=item *

has_humanreadable_license

=item *

no_cpants_errors

=back

=item Available indicators in optional

=over 4

=item *

has_tests_in_t_dir

=item *

has_example

=item *

no_stdin_for_prompting

=item *

metayml_declares_perl_version

=item *

prereq_matches_use

=item *

use_warnings

=item *

has_test_pod

=item *

has_test_pod_coverage

=back

=item Excluded indicators in core

=over 4

=item Can not apply already unpacked dist

=over 4

=item *

extractable

=item *

extracts_nicely

=item *

has_version

=item *

has_proper_version

=back

=item Already dirty in test phase

=over 4

=item *

fest_matches_dist

=item *

no_generated_files

=back

=item Broken in Module::CPANTS::Analyse 0.86 L<rt.cpan.org #80225|https://rt.cpan.org/Public/Bug/Display.html?id=80225>

=over 4

=item *

metayml_conforms_to_known_spec

=back

=back

=item Excluded indicators in optional

=over 4

=item Needs CPANTS DB

=over 4

=item *

is_prereq

=back

=item Broken in Module::CPANTS::Analyse 0.86 L<rt.cpan.org #80225|https://rt.cpan.org/Public/Bug/Display.html?id=80225>

=over 4

=item *

metayml_conforms_spec_current

=back

=back

=back

=head1 SEE ALSO

=over 4

=item *

L<Module::CPANTS::Analyse> - Kwalitee indicators, except for prereq_matches_use, are calculated by this module.

=item *

L<Test::Kwalitee> - Another test module for Kwalitee indicators.

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
