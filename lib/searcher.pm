package searcher;

use 5.12.2;

use strict;
use warnings;

use KinoSearch::Search::IndexSearcher;
use Data::Dumper;

my $searcher = KinoSearch::Search::IndexSearcher->new( 
	index => 'KinoIndex',
);

sub query {
	my $query = shift;

	my $hits = $searcher->hits(
		query => $query,
		offset => 0,
		num_wanted => 1000,
	);

	my $highlighter = KinoSearch::Highlight::Highlighter->new(
		searcher => $searcher,
		query    => $query,
		field    => 'content'
	);

	my @result;

	while ( my $hit = $hits->next ) {
		my $entry = {
			score => $hit->get_score,
			title => $hit->{'title'},
			key => $hit->{'key'},
			author => $hit->{'author'},
			path => $hit->{'path'},
			pdf => $hit->{'pdf'},
			txt => $hit->{'txt'},
			excerpt => $highlighter->create_excerpt($hit),
		};

		my $file = $$entry{'txt'};
		$file //= $$entry{'pdf'};
		$$entry{'file'} = $file;

		push(@result, $entry);
	}

	return \@result;
}

1;
