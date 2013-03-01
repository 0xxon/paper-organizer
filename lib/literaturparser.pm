package literaturparser;

use Dancer ':syntax';
use parseBib;
use searcher;

use Cwd qw/abs_path/;

our $VERSION = '0.1';

get '/' => sub {
    template 'index', { literatur => parseBib::getBibliography() };
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

    template 'search', { query => $query, results => searcher::query(params->{'query'}) };
};

get '/search' => sub {
    template 'search', { query => params->{'query'}, results => searcher::query(params->{'query'}) };
};

true;
