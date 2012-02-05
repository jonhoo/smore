package Torrents::Torrentz;

use strict;
use warnings;
use URI::Escape;
our $VERSION = '1.00';
use base 'Exporter';
our @EXPORT = qw(search direct);

=head1 NAME

Torrents::Torrentz - Allows access to torrents on torrentz.eu

=head1 SYNOPSIS

use Torrents::Torrentz;
$torrents = search("Pioneer One");

=head1 DESCRIPTION

Methods for searching and fetching torrents from torrentz.eu

=head2 Functions

The following functions are exported by default

=head3 search

$torrents = search("Pioneer One");

Returns an arrayref of hashrefs, each containing:
  name: The name of the torrent
  url: URL for the torrent file
  quality: [0-1] quality rating (0 is fake, 1 is certified)

=cut

sub search {
  my $query = shift;
  $query = uri_escape($query);
  my $data = `curl -s http://torrentz.eu/search?f=$query | grep dl | grep -v sponsored`;
  $data =~ s@</dl><(dl|p)>@</dl>\n<$1>@g;

  my @online = split /\n/, $data;
  my @torrents = ();

  for my $torrent (@online) {
    chomp $torrent;

    $torrent =~ /a href="(.*?)"/;
    my $url = $1;

    my $rating = ($torrent =~ /verified by users/i) ? 1 : 0.5;

    $torrent =~ s{<b>(.*?)</b>}{$1}g;
    $torrent =~ s{^.*>(.*?)</a>.*}{$1}g;

    push @torrents, {
      name => $torrent,
      url => "http://torrentz.eu$url",
      quality => $rating
    };
  }

  return \@torrents;
}

=head3 direct

$supportsDirectTorrentLink = direct();

Returns 1 if this service supports direct download URLs, 0 otherwise

=cut

sub direct {
  return 0;
}

=head1 AUTHOR

Jon Gjengset <jon@thesquareplanet.com>

=cut

1;
