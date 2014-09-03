package Bibliography;

use 5.12.2;

use File::Find;
use Data::Dumper;
use autodie;

use Moo;
use Text::BibTeX;
use namespace::clean;

use Perl6::Slurp;


has entry => (
	is => 'ro',
	default => sub { Text::BibTeX::Entry->new() },
);

has searchpath => (
	is => 'ro',
	required => 1,
);

has bibfilenames => (
	is => 'ro',
	default => sub { [] },
);

has 'bibs' => (
	is => 'ro',
	default => sub { [] },
);

sub BUILD {
	my $self = shift;

	$self->populateBibfiles();
}

sub getBibliography {
	my $self = shift;

	return $self->bibs;
}

sub getEntry {
	my $self = shift;
	my $name = shift;
	my $e = $self->entry->get($name) if $self->entry->exists($name);
	$e //= "";
	return $e;
}

sub populateBibfiles {
	my $self = shift;

	my $wantfunc = sub {
		return unless /\.bib$/;

		push(@{$self->bibfilenames}, $File::Find::name);
	};
	File::Find::find({wanted => $wantfunc}, $self->searchpath);

	for my $filename ( @{$self->bibfilenames} ) {
		my $content = slurp($filename);
		$self->entry->parse_s($content) or die();
		die "$filename" unless $self->entry->parse_ok();

		my $pdf;
		my $basename = $filename;
		$basename =~ s/\.bib$//;
		my $pdffile = $basename.".pdf";
		my $textfile = $basename.".txt";
		my $searchpath = $self->searchpath;
		$filename =~ s#^$searchpath##;

		my $hash = {
			key => $self->entry->key(),
			intKey => $self->getEntry('key'),
			path => $filename,
			author => $self->getEntry('author'),
			title => $self->getEntry('title'),
		};

		if (-e $pdffile) {
			$pdffile =~ s#^public/lit##;
			$$hash{"pdf"} = $pdffile;
		}

		if ( -e $textfile) {
			$textfile =~ s#^public/lit##;
			$$hash{"txt"} = $textfile;
		}

		push(@{$self->bibs}, $hash);
	}
}

1;
