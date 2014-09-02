package parseBib;

use 5.12.2;

use File::Find;
use Data::Dumper;
use autodie;

use Text::BibTeX;
use Perl6::Slurp;

my @bibfilenames;
my @bibs;

my $entry = Text::BibTeX::Entry->new();

sub getBibliography {
	@bibs = ();

	populateBibfiles();

	for my $filename ( @bibfilenames ) {
		my $content = slurp($filename);
		$entry->parse_s($content) or die();
		die "$filename" unless $entry->parse_ok();

		my $pdf;
		my $basename = $filename;
		$basename =~ s/\.bib$//;
		my $pdffile = $basename.".pdf";
		my $textfile = $basename.".txt";
		$filename =~ s#^public/lit##;

		my $hash = {
			key => $entry->key(),
			intKey => getEntry('key'),
			path => $filename,
			author => getEntry('author'),
			title => getEntry('title'),
		};

		if (-e $pdffile) {
			$pdffile =~ s#^public/lit##;
			$$hash{"pdf"} = $pdffile;
		}

		if ( -e $textfile) {
			$textfile =~ s#^public/lit##;
			$$hash{"txt"} = $textfile;
		}

		push(@bibs, $hash);
	}

	return \@bibs;
}

sub getEntry {
	my $name = shift;
	my $e = $entry->get($name) if $entry->exists($name);
	$e //= "";
	return $e;
}

sub populateBibfiles {
	my $searchpath = shift;
	$searchpath //= "public/lit";
	@bibfilenames = ();
	File::Find::find({wanted => \&wantBibs}, $searchpath);
}

sub wantBibs {
	return unless /\.bib$/;

	push(@bibfilenames, $File::Find::name);
}

1;
