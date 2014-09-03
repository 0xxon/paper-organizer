package LitParse;

use 5.12.2;

use strict;
use warnings;

use Dancer2;
use Bibliography;
use Searcher;

use Cwd qw/abs_path/;

our $VERSION = '0.1';

my $bib = Bibliography->new();
my $search = Searcher->new();

get '/' => sub {
	template 'index', { literatur => $bib->getBibliography() };
};

get qr{/lit/(.*\.bib)\.html} => sub {
	my ($path) = splat;
	my $abs_path = abs_path("./public/lit".$path);

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
