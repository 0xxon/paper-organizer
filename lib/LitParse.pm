package LitParse;

use 5.12.2;

use strict;
use warnings;

use Dancer2;
use Bibliography;
use Searcher;
use Indexer;

use Cwd qw/abs_path/;

our $VERSION = '0.1';

my $searchpath = "public/lit";
my $indexpath = 'KinoIndex';

my $bib = Bibliography->new(searchpath => $searchpath);
my $indexer = Indexer->new(searchpath => $searchpath, indexpath => $indexpath, bib => $bib);

unless ( -d $indexpath ) {
	say "Running indexer for the first time...";
	$indexer->index_bib();
}

my $search = Searcher->new(indexpath => $indexpath);

get '/' => sub {
	template 'index', { literatur => $bib->getBibliography() };
};

get qr{/lit/(.*\.bib)\.html} => sub {
	my ($path) = splat;
	my $abs_path = abs_path("./".$searchpath.$path);

	template 'bibfile', { path => $path, bibfile => $abs_path };
};

post '/search' => sub {
	my $query = params->{'query'};
	my $history = session('searchHistory');
	$history //= [];

	push(@$history, $query);
	while(scalar @$history > 10) {
		shift @$history;
	}
	session(searchHistory => $history);

	template 'search', { query => $query, results => $search->query(params->{'query'}) };
};

get '/search' => sub {
	template 'search', { query => params->{'query'}, results => $search->query(params->{'query'}) };
};

true;
