use v5.10;
use strict;
use warnings;
use Module::CPANTS::Analyse;

my $u = Module::CPANTS::Analyse->new({ opts => { no_capture => 1 }, dist => '.' });

say join "\n", map { sprintf "%s,%d,%d", $_->{name}, $_->{is_extra} || 0, $_->{is_experimental} || 0 } map { @{$_->kwalitee_indicators} } @{$u->mck->generators};
