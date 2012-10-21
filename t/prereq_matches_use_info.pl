use Module::CPANTS::Kwalitee::Prereq;

my ($error, $remedy, $berror, $bremedy);

my $ref = Module::CPANTS::Kwalitee::Prereq->kwalitee_indicators;
while(my (undef, $val) = each @$ref) {
	($error, $remedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'prereq_matches_use';
	($berror, $bremedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'build_prereq_matches_use';
}

return ($error, $remedy, $berror, $bremedy);
