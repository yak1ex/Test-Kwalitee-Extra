# NAME

Test::Kwalitee::Extra - Run Kwalitee tests including optional indicators, especially, prereq\_matches\_use

# VERSION

version v0.2.1

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

    # Avoid network access
    use Test::Kwalitee::Extra qw(!prereq_matches_use);
    # or, when experimental enabled
    use Test::Kwalitee::Extra qw(:experimental !prereq_matches_use !build_prereq_matches_use);

# DESCRIPTION

[CPANTS](http://cpants.cpanauthors.org/) checks Kwalitee indicators, which is not quality but automatically-measurable indicators how good your distribution is. [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) calcluates Kwalitee but it is not directly applicable to your module test. CPAN has already had [Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee) for the test module of Kwalitee. It is, however, impossible to calculate `prereq_matches_use` indicator, because dependent module [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) itself cannot calculate `prereq_matches_use` indicator. It is marked as `needs_db` which means pre-calculated module database is necessary, but only limited information is needed to calculate the indicator. This module calculate `prereq_matches_use` to query needed information to [MetaCPAN site](https://metacpan.org/) online.

For available indicators, see ["INDICATORS"](#indicators) section.

# OPTIONS

You can specify including or excluding an indicator or a tag like [Exporter](https://metacpan.org/pod/Exporter). Valid tags are `core`, `optional` and `experimental`. For indicators, see [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse).

Please NOTE that to specify tags are handled a bit differently from [Exporter](https://metacpan.org/pod/Exporter). First, specifying an indicator is always superior to specifying tags, even though specifying an indicator is prior to specifying tags.

For example, 

    use Test::Kwalitee::Extra qw(!has_example :optional);

`!has_example` is in effect, that is `has_example` is excluded, even though `has_example` is an `optional` indicator.

Second, default excluded indicators mentioned in ["INDICATORS"](#indicators) section are not included by specifying tags. For example, in the above example, `:optional` does not enable `is_prereq`. You can override it by explicitly specifying the indicator:

    use Test::Kwalitee::Extra qw(manifest_matches_dist);

## SPECIAL TAGS

Some tags have special meanings.

## `:no_plan`

If specified, do not call `Test::Builder::plan`. You may need to specify it, if this test is embedded into other tests.

## `:minperlver` <`version`>

`prereq_matches_use` indicator ignores core modules. What modules are in core, however, is different among perl versions. If minimum perl version is specified in META.yml or such a meta information, it is used as minimum perl version. Otherewise, `$]`, the version of the current perl interpreter, is used.

If specified, this option overrides them.

## `:retry` <`count`>

The number of retry to query to MetaCPAN. This is related with `prereq_matches_use` and `build_prereq_matches_use` indicators only.

Defaults to 5.

# CAVEATS

An optional indicator `prereq_matches_use` and an experimental indicator `build_prereq_matches_use` require HTTP access to [MetaCPAN site](https://metacpan.org/). If you want to avoid it, you can specify excluded indicators like

    # Avoid network access
    use Test::Kwalitee::Extra qw(!prereq_matches_use);

    # or, when experimental enabled
    use Test::Kwalitee::Extra qw(:experimental !prereq_matches_use !build_prereq_matches_use);

Or mitigate wait by tentative failures to reduce retry counts like

    # Try just one time for each query
    use Test::Kwalitee::Extra qw(:retry 1);

# INDICATORS

In [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse), `prereq_matches_use` requires CPANTS DB setup by [Module::CPANTS::ProcessCPAN](https://metacpan.org/pod/Module::CPANTS::ProcessCPAN). `is_prereq` really requires information of prereq of other modules but `prereq_matches_use` only needs mappings between modules and dists. So, this module query the mappings to MetaCPAN by using [MetaCPAN::API::Tiny](https://metacpan.org/pod/MetaCPAN::API::Tiny).

Recently, [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) has been changed much. For actual available indicators, please consult `Module::CPANTS::Kwalitee::*` documentation. For default configuration, indicators are treated as follows:

- NOTES
    - **(+)**

        No longer available for [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) 0.88 or 0.90+.

    - **(++)**

        No longer available for [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) 0.90+.

    - **(+++)**

        No longer available for [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) 0.88 or 0.90+, moved to [Module::CPANTS::SiteKwalitee](https://github.com/cpants/Module-CPANTS-SiteKwalitee).

    - **(++++)**

        No longer available for [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) 0.88 or 0.90+, moved to [Module::CPANTS::SiteKwalitee](https://github.com/cpants/Module-CPANTS-SiteKwalitee) but supported by this module.
- Available indicators in core
    - has\_readme
    - has\_manifest
    - has\_meta\_yml
    - has\_buildtool
    - has\_changelog
    - no\_symlinks
    - has\_tests
    - buildtool\_not\_executable **(++)**
    - metayml\_is\_parsable
    - metayml\_has\_license **(optional for 0.88 or 0.90+)**
    - metayml\_conforms\_to\_known\_spec
    - proper\_libs **(for 0.87 or 0.89)**
    - no\_pod\_errors **(+)**
    - has\_working\_buildtool **(+)**
    - has\_better\_auto\_install **(+)**
    - use\_strict
    - valid\_signature **(+++)**
    - has\_humanreadable\_license **(for 0.87 or 0.89)** | has\_human\_redable\_license **(for 0.88 or 0.90+)**
    - no\_cpants\_errors **(+)**
- Available indicators in optional
    - has\_tests\_in\_t\_dir
    - has\_example **(+)**
    - no\_stdin\_for\_prompting
    - metayml\_conforms\_spec\_current
    - metayml\_declares\_perl\_version
    - prereq\_matches\_use **(++++)**
    - use\_warnings
    - has\_test\_pod **(+)**
    - has\_test\_pod\_coverage **(+)**
- Excluded indicators in core
    - Can not apply already unpacked dist
        - extractable **(+)**
        - extracts\_nicely **(+)**
        - has\_version **(+)**
        - has\_proper\_version **(+)**
    - Already dirty in test phase
        - manifest\_matches\_dist
        - no\_generated\_files **(++)**
- Excluded indicators in optional
    - Can not apply already unpacked dist
        - proper\_libs **(for 0.88 or 0.90+)**
    - Needs CPANTS DB
        - is\_prereq **(+++)**
- Indicators with special note in experimental
    - build\_prereq\_matches\_use **(++++)**

# SEE ALSO

- [Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse) - Kwalitee indicators, except for prereq\_matches\_use, are calculated by this module.
- [Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee) - Another test module for Kwalitee indicators.
- [Dist::Zilla::Plugin::Test::Kwalitee::Extra](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::Kwalitee::Extra) - Dist::Zilla plugin for this module.

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
