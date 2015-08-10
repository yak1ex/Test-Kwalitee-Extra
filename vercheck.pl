#!/usr/bin/perl

use strict;
use warnings;

my @targets = qw(
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.88.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.9002.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.91.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.92.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.94.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.95.tar.gz
	http://search.cpan.org/CPAN/authors/id/I/IS/ISHIGAKI/Module-CPANTS-Analyse-0.96.tar.gz
);
my $TGTDIR = 'targets';

mkdir $TGTDIR if !  -d $TGTDIR;
foreach my $target (@targets) {
	my $filename = $target;
	$filename =~ s,.*/,,;
	if(! -f "$TGTDIR/$filename") {
		system "wget -O $TGTDIR/$filename $target";
	}
}

foreach my $target (@targets) {
	my $filename = $target;
	$filename =~ s,.*/,,;
	system "cpanm -f $TGTDIR/$filename";
	system 'dzil test'; 
}
