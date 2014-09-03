package Indexer;

use 5.12.2;

use warnings;
use strict;
use autodie;
use Carp;

use CAM::PDF;
require Bibliography;
use Data::Dumper;

use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Plan::StringType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Analysis::RegexTokenizer;
use Lucy::Index::Indexer;

use Moo;
use namespace::clean;
use Perl6::Slurp;

has schema => (
	is => 'lazy',
	builder => \&schema_builder,
);

has indexer => (
	is => 'lazy',
	builder => \&indexer_builder,
);

has bib => (
	is => 'ro',
	required => 1,
);

has searchpath => (
	is => 'ro',
	required => 1,
);

has indexpath => (
	is => 'ro',
	required => 1,
);

sub schema_builder {
	my $self = shift;

	my $schema = Lucy::Plan::Schema->new;

	my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
		language => 'en',
	);
	my $tokenizer = Lucy::Analysis::RegexTokenizer->new;
	my $type = Lucy::Plan::FullTextType->new(
		analyzer => $polyanalyzer,
	);
	my $tokentype = Lucy::Plan::FullTextType->new(
		analyzer => $tokenizer,
	);
	my $path_type = Lucy::Plan::StringType->new( indexed => 0 );
	my $highlightable = Lucy::Plan::FullTextType->new(
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

	return $schema;
}

sub indexer_builder {
	my $self = shift;

	my $indexer = Lucy::Index::Indexer->new(
		index => $self->indexpath,
		schema => $self->schema,
		create => 1,
		truncate => 1,
	);

	return $indexer;
}

sub read_pdf {
	my $self = shift;

	my $file = $self->searchpath.shift;
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

sub index_bib {
	my $self = shift;

	my $indexer = $self->indexer;

	for my $bib (@{$self->bib->bibs}) {
		my $file = $bib->{'txt'};
		my $text;
		if ( defined($file) ) {
			$text = slurp($file);
		} else {
			$file = $bib->{'pdf'};
			next unless defined($file);
			$text = $self->read_pdf($file);
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
};

1;
