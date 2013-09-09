# NAME

Test::Kwalitee::Extra - Run Kwalitee tests including optional indicators, especially, prereq\_matches\_use

# VERSION

version v0.1.3

# SYNOPSIS

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

# DESCRIPTION

[CPANTS](http://cpants.cpanauthors.org/) checks Kwalitee indicators, which is not quality but automatically-measurable indicators how good your distribution is. [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) calcluates Kwalitee but it is not directly applicable to your module test. CPAN has already had [Test::Kwalitee](http://search.cpan.org/perldoc?Test::Kwalitee) for the test module of Kwalitee. It is, however, impossible to calculate `prereq_matches_use` indicator, because dependent module [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) itself cannot calculate `prereq_matches_use` indicator. It is marked as `needs_db`, but only limited information is needed to calculate the indicator. This module calculate `prereq_matches_use` to query needed information to [MetaCPAN](https://metacpan.org/).

For available indicators, see ["INDICATORS"](#INDICATORS) section.

# OPTIONS

You can specify including or excluding an indicator or a tag like [Exporter](http://search.cpan.org/perldoc?Exporter). Valid tags are `core`, `optional` and `experimental`. For indicators, see [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse).

Please NOTE that to specify tags are handled a bit differently from [Exporter](http://search.cpan.org/perldoc?Exporter). First, specifying an indicator is always superior to specifying tags, even though specifying an indicator is prior to specifying tags.

For example, 

    use Test::Kwalitee::Extra qw(!has_example :optional);

`!has_example` is in effect, that is `has_example` is excluded, even though `has_example` is an `optional` indicator.

Second, default excluded indicators mentioned in ["INDICATORS"](#INDICATORS) section are not included by specifying tags. For example, in the above example, `:optional` does not enable `is_prereq`. You can override it by explicitly specifying the indicator:

    use Test::Kwalitee::Extra qw(manifest_matches_dist);

## SPECIAL TAGS

Some tags have special meanings.

## `:no_plan`

If specified, do not call `Test::Builder::plan`. You may need to specify it, if this test is embedded into other tests.

## `:minperlver` <`version`\>

`prereq_matches_use` indicator ignores core modules. What modules are in core, however, is different among perl versions. If minimum perl version is specified in META.yml or such a meta information, it is used as minimum perl version. Otherewise, `$]`, the version of the current perl interpreter, is used.

If specified, this option overrides them.

# INDICATORS

In [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse), `prereq_matches_use` requires CPANTS DB setup by [Module::CPANTS::ProcessCPAN](http://search.cpan.org/perldoc?Module::CPANTS::ProcessCPAN). `is_prereq` really requires information of prereq of other modules but `prereq_matches_use` only needs mappings between modules and dists. So, this module query the mappings to MetaCPAN by using [MetaCPAN::API::Tiny](http://search.cpan.org/perldoc?MetaCPAN::API::Tiny).

Recently, [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) has been changed much. For actual available indicators, please consult `Module::CPANTS::Kwalitee::*` documentation. For default configuration, indicators are treated as follows:

- NOTES
    - __(+)__

        No longer available for [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) 0.88 or 0.90+.

    - __(++)__

        No longer available for [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) 0.90+.

    - __(+++)__

        No longer available for [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) 0.88 or 0.90+, moved to [Module::CPANTS::SiteKwalitee](https://github.com/cpants/Module-CPANTS-SiteKwalitee).

    - __(++++)__

        No longer available for [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) 0.88 or 0.90+, moved to [Module::CPANTS::SiteKwalitee](https://github.com/cpants/Module-CPANTS-SiteKwalitee) but supported by this module.
- Available indicators in core
    - has\_readme
    - has\_manifest
    - has\_meta\_yml
    - has\_buildtool
    - has\_changelog
    - no\_symlinks
    - has\_tests
    - buildtool\_not\_executable __(++)__
    - metayml\_is\_parsable
    - metayml\_has\_license __(optional for 0.88 or 0.90+)__
    - metayml\_conforms\_to\_known\_spec
    - proper\_libs __(for 0.87 or 0.89)__
    - no\_pod\_errors __(+)__
    - has\_working\_buildtool __(+)__
    - has\_better\_auto\_install __(+)__
    - use\_strict
    - valid\_signature __(+++)__
    - has\_humanreadable\_license __(for 0.87 or 0.89)__ | has\_human\_redable\_license __(for 0.88 or 0.90+)__
    - no\_cpants\_errors __(+)__
- Available indicators in optional
    - has\_tests\_in\_t\_dir
    - has\_example __(+)__
    - no\_stdin\_for\_prompting
    - metayml\_conforms\_spec\_current
    - metayml\_declares\_perl\_version
    - prereq\_matches\_use __(++++)__
    - use\_warnings
    - has\_test\_pod __(+)__
    - has\_test\_pod\_coverage __(+)__
- Excluded indicators in core
    - Can not apply already unpacked dist
        - extractable __(+)__
        - extracts\_nicely __(+)__
        - has\_version __(+)__
        - has\_proper\_version __(+)__
    - Already dirty in test phase
        - manifest\_matches\_dist
        - no\_generated\_files __(++)__
- Excluded indicators in optional
    - Can not apply already unpacked dist
        - proper\_libs __(for 0.88 or 0.90+)__
    - Needs CPANTS DB
        - is\_prereq __(+++)__
- Indicators with special note in experimental
    - build\_prereq\_matches\_use __(++++)__

# SEE ALSO

- [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) - Kwalitee indicators, except for prereq\_matches\_use, are calculated by this module.
- [Test::Kwalitee](http://search.cpan.org/perldoc?Test::Kwalitee) - Another test module for Kwalitee indicators.
- [Dist::Zilla::Plugin::Test::Kwalitee::Extra](http://search.cpan.org/perldoc?Dist::Zilla::Plugin::Test::Kwalitee::Extra) - Dist::Zilla plugin for this module.

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
