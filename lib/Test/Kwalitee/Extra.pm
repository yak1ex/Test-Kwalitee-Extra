package Test::Kwalitee::Extra;

use strict;
use warnings;

# VERSION

use Cwd;
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

		# broken in Module::CPANTS::Analyse 0.86 RT#80225
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

sub _check_enable
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

sub _do_test
{
	my ($env) = @_;
	my ($test, $analyser, $exclude) = @{$env}{qw(builder analyser exclude)};
	my @ind;
	foreach my $mod (@{$analyser->mck->generators}) {
		$mod->analyse($analyser);
		foreach my $ind (@{$mod->kwalitee_indicators}) {
			next if $ind->{needs_db};
			next if ! _check_enable($env, $ind);	
			my $ret = $ind->{code}($analyser->d, $ind);
			push @ind, [ $ret, $ind->{name}.' by '.$mod, $ind->{error}, $ind->{remedy}, $analyser->d->{error}{$ind->{name}} ];
		}
	}
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
	foreach my $arg (@arg) {
		if($arg eq ':no_plan') {
			$env->{no_plan} = 1;
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

Test::Kwalitee::Extra - Run Kwalitee tests including optional indicators and prereq_matches_use.

=head1 SYNOPSIS

  # Simply use, with disabling indicators
  use Test::Kwalitee::Extra qw(!has_example !metayml_declares_perl_version);

  # Use with eval guard, with disabling class
  use Test::More;
  eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(!:optional)); };
  plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;

=head1 DESCRIPTION

=head1 OPTIONS

You can specify enabling or disabling an indicator or a tag like L<Exporter>.
Tags are C<core>, C<optional> and C<experimental>. See L<Module::CPANTS::Analyse> for indicators.

Please NOTE that to specify tags are handled a bit differently from L<Exporter>.
First, specifying an indicator is always superior to specifying tags, 
even though specifying an indicator is prior to specifying tags.
For example, 

  use Test::Kwalitee::Extra qw(!has_example :optional);

C<!has_example> is in effect.

Second, default excluded indicators mentioned in INDICATORS section are not enabled by specifying tags.
For example, the above example, C<:optional> does not enable C<is_prereq> and C<metayml_conforms_spec_current>.
You can override explicitly specify the indicator.

  use Test::Kwalitee::Extra qw(metayml_conforms_spec_current);

=head1 INDICATORS

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

prereq_matches_use (not yet enabled)

In L<Module::CPANTS::Analyse>, this indicator requires CPANTS DB setup by L<Module::CPANTS::ProcessCPAN>.
is_prereq acutally requires information of other modules but prereq_matches_use only needs mappings between modules and dists.
So, this module query the mappings to MetaCPAN by using L<MetaCPAN::API::Tiny>.

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

=item Broken in Module::CPANTS::Analyse 0.86 RT#80225

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

=item Broken in Module::CPANTS::Analyse 0.86 RT#80225

=over 4

=item *

metayml_conforms_spec_current

=back

=back

=back

=head1 SEE ALSO

=over 4

=item *

L<Module::CPANTS::Analyse>

=item *

L<Test::Kwalitee>

=back

=cut
