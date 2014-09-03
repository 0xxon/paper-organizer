package Searcher;

use 5.12.2;

use strict;
use warnings;

use Carp;
use Lucy::Search::IndexSearcher;

use Moo;
use namespace::clean;

has indexpath => (
 is => 'ro',
 required => 1,
);

has searcher => (
	is => 'rw',
);

sub BUILD {
	my $self = shift;

	# First thing - look if the search path already exists. If not, this is probably
	# our first run and we have to create it first...

	unless (-d $self->indexpath) {
		croak("Index does not exist yet");
	}

	my $searcher = Lucy::Search::IndexSearcher->new(
		index => $self->indexpath,
	);
	$self->searcher($searcher);
}


sub query {
	my $self = shift;
	my $query = shift;
	my $searcher = $self->searcher;

	my $hits = $searcher->hits(
		query => $query,
		offset => 0,
		num_wanted => 1000,
	);

	my $highlighter = Lucy::Highlight::Highlighter->new(
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
