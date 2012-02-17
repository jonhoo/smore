package Torrents::Pirate;

use strict;
use warnings;
use URI::Escape;
our $VERSION = '1.00';
use base 'Exporter';
our @EXPORT = qw(search direct);

=head1 NAME

Torrents::Pirate - Allows access to torrents on thepiratebay.se

=head1 SYNOPSIS

use Torrents::Pirate;
$torrents = search("Pioneer One");

=head1 DESCRIPTION

Methods for searching and fetching torrents from thepiratebay.se

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
  my @online = `curl -s http://thepiratebay.se/search/$query/0/7/0 | grep "detLink" | grep 'a href="/torrent'`;
  my @torrents = ();
  for my $torrent (@online) {
    chomp $torrent;
    $torrent =~ /a href="(.*?)"/;
    my $url = $1;
    $torrent =~ s{^.*?Details for .*?">}{}g;
    $torrent =~ s{</a></div>.*}{}g;

    $url =~ m@^/torrent/(\d+)/(.+)$@;
    $url = "http://torrents.thepiratebay.se/$1/$2.$1.TPB.torrent";

    push @torrents, {
      name => $torrent,
      url => $url,
      quality => 0.5
    };
  }

  return \@torrents;
}

=head3 direct

$supportsDirectTorrentLink = direct();

Returns 1 if this service supports direct download URLs, 0 otherwise

=cut

sub direct {
  return 1;
}

=head1 AUTHOR

Jon Gjengset <jon@thesquareplanet.com>

=cut

1;
