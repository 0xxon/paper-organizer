#!/usr/bin/env perl

use 5.12.2;

use warnings;

push (@INC, "./lib");

use CAM::PDF; 
require parseBib;
use Data::Dumper;

use KinoSearch::Plan::Schema;
use KinoSearch::Plan::FullTextType;
use KinoSearch::Plan::StringType;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Analysis::Tokenizer;
use KinoSearch::Index::Indexer;
use Perl6::Slurp;

my $schema = KinoSearch::Plan::Schema->new;
my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
	language => 'en',
);
my $tokenizer = KinoSearch::Analysis::Tokenizer->new;
my $type = KinoSearch::Plan::FullTextType->new(
	analyzer => $polyanalyzer,
);
my $tokentype = KinoSearch::Plan::FullTextType->new(
	analyzer => $tokenizer,
);
my $path_type = KinoSearch::Plan::StringType->new( indexed => 0 );
my $highlightable = KinoSearch::Plan::FullTextType->new(
	analyzer      => $polyanalyzer,
	highlightable => 1,
);

$schema->spec_field( name => 'title', type => $type );
$schema->spec_field( name => 'author', type => $type );
$schema->spec_field( name => 'key', type => $tokentype );
$schema->spec_field( name => 'path', type => $path_type );
$schema->spec_field( name => 'pdf', type => $path_type );
$schema->spec_field( name => 'txt', type => $path_type );
$schema->spec_field( name => 'content', type => $highlightable );
my $indexer = KinoSearch::Index::Indexer->new(
	index => 'KinoIndex',
	schema => $schema,
	create => 1,
	truncate => 1,
);

my $bibs = parseBib::getBibliography();

sub readThePdf {
	my $file = shift;
	my $text;

	say "Parsing $file";
	my $pdf;
	eval { $pdf = CAM::PDF->new($file); };
	if ( $@ || !defined($pdf) ) {
		say "Error opening $file";
		next;
	}
	for my $page (1..$pdf->numPages()) {
		say "Page: $page";
		my $pagetext;
	       	eval { $pagetext = $pdf->getPageText($page); };
		if ( $@ ) {
			say "Error parsing page $page";
		}
		$pagetext //= "";
		$text .= $pagetext;
	}

	return $text;
}

for my $bib (@$bibs) {
	my $file = $bib->{'txt'};
	my $text;
	if ( defined($file) ) {
		$text = slurp($file);
	} else {
		$file = $bib->{'pdf'};
		next unless defined($file);
		$text = readThePdf($file);
	}

	die unless defined($text);

	my $entry = {
		key => $bib->{'key'},
		title => $bib->{'title'},
		author => $bib->{'author'},
		content => $text,
		path => $bib->{'path'},
	};

	if ( defined($bib->{'txt'}) ) {
		$$entry{'txt'} = $bib->{'txt'};
	}
	if ( defined($bib->{'pdf'}) ) {
		$$entry{'pdf'} = $bib->{'pdf'};
	}
	
	die unless defined($entry);
	$indexer->add_doc($entry);
}

$indexer->commit;
