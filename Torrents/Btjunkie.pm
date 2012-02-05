package Torrents::Btjunkie;

use strict;
use warnings;
use URI::Escape;
our $VERSION = '1.00';
use base 'Exporter';
our @EXPORT = qw(search direct);

=head1 NAME

Torrents::Btjunkie - Allows access to torrents on btjunkie.org

=head1 SYNOPSIS

use Torrents::Btjunkie;
$torrents = search("Pioneer One");

=head1 DESCRIPTION

Methods for searching and fetching torrents from btjunkie.org

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
  my @online = `curl -s http://btjunkie.org/search?q=$query | grep "background-image:url('/images/comment_icon.png')"`;
  my @torrents = ();
  for my $torrent (@online) {
    chomp $torrent;
    $torrent =~ /a href="(.*?)"/;
    my $url = $1;
    $torrent =~ s{<font color="#CC0000">}{}g;
    $torrent =~ s{</font>}{}g;
    $torrent =~ s{^.*class="BlckUnd">}{}g;
    $torrent =~ s{</div></td>.*}{}g;
    $torrent =~ /^(.*?)<.*?(\d+)$/;

    my $rating = $2/999;
    $rating = 0 if $rating < 0;
    $rating = 1 if $rating > 1;
    push @torrents, {
      name => $1,
      url => "http://dl.btjunkie.org$url/download.torrent",
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
  return 1;
}

=head1 AUTHOR

Jon Gjengset <jon@thesquareplanet.com>

=cut

1;
