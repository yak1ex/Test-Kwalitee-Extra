# NAME

Test::Kwalitee::Extra - Run Kwalitee tests including optional indicators and prereq\_matches\_use.

# SYNOPSIS

    # Simply use, with disabling indicators
    use Test::Kwalitee::Extra qw(!has_example !metayml_declares_perl_version);

    # Use with eval guard, with disabling class
    use Test::More;
    eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(!:optional)); };
    plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;

# DESCRIPTION

# OPTIONS

You can specify enabling or disabling an indicator or a tag like [Exporter](http://search.cpan.org/perldoc?Exporter).
Tags are `core`, `optional` and `experimental`. See [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse) for indicators.

Please NOTE that to specify tags are handled a bit differently from [Exporter](http://search.cpan.org/perldoc?Exporter).
First, specifying an indicator is always superior to specifying tags, 
even though specifying an indicator is prior to specifying tags.
For example, 

    use Test::Kwalitee::Extra qw(!has_example :optional);

`!has_example` is in effect.

Second, default excluded indicators mentioned in INDICATORS section are not enabled by specifying tags.
For example, the above example, `:optional` does not enable `is_prereq` and `metayml_conforms_spec_current`.
You can override explicitly specify the indicator.

    use Test::Kwalitee::Extra qw(metayml_conforms_spec_current);

# INDICATORS

For default configuration, indicators are treated as follows:

                                                                        - Available indicators in core
                                                                        - has\_readme
                                                                    - has\_manifest
                                                                - has\_meta\_yml
                                                            - has\_buildtool
                                                        - has\_changelog
                                                    - no\_symlinks
                                                - has\_tests
                                            - buildtool\_not\_executable
                                        - metayml\_is\_parsable
                                    - metayml\_has\_license
                                - proper\_libs
                            - no\_pod\_errors
                        - has\_working\_buildtool
                    - has\_better\_auto\_install
                - use\_strict
            - valid\_signature
        - has\_humanreadable\_license
    - no\_cpants\_errors

                    - Available indicators in optional
                    - has\_tests\_in\_t\_dir
                - has\_example
            - no\_stdin\_for\_prompting
        - metayml\_declares\_perl\_version
    - prereq\_matches\_use (not yet enabled)

    In [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse), this indicator requires CPANTS DB setup by [Module::CPANTS::ProcessCPAN](http://search.cpan.org/perldoc?Module::CPANTS::ProcessCPAN).
    is\_prereq acutally requires information of other modules but prereq\_matches\_use only needs mappings between modules and dists.
    So, this module query the mappings to MetaCPAN by using [MetaCPAN::API::Tiny](http://search.cpan.org/perldoc?MetaCPAN::API::Tiny).

            - use\_warnings
        - has\_test\_pod
    - has\_test\_pod\_coverage

                                    - Excluded indicators in core
                                    - Can not apply already unpacked dist
                                - extractable
                        - extracts\_nicely
                - has\_version
        - has\_proper\_version

                    - Already dirty in test phase
                - fest\_matches\_dist
        - no\_generated\_files

            - Broken in Module::CPANTS::Analyse 0.86 RT\#80225
        - metayml\_conforms\_to\_known\_spec

            - Excluded indicators in optional
            - Needs CPANTS DB
        - is\_prereq

            - Broken in Module::CPANTS::Analyse 0.86 RT\#80225
        - metayml\_conforms\_spec\_current

# SEE ALSO

- [Module::CPANTS::Analyse](http://search.cpan.org/perldoc?Module::CPANTS::Analyse)
- [Test::Kwalitee](http://search.cpan.org/perldoc?Test::Kwalitee)
