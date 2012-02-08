#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use YAML::Syck;
use POSIX 'setsid';
use File::Basename;

$YAML::Syck::ImplicitTyping = 1;
my $dirname = dirname(__FILE__);

my $configFile = undef;
$configFile = "$dirname/config.yaml" if -e "$dirname/config.yaml";
$configFile = $ENV{'HOME'} . '/.smore.yaml' if -e $ENV{'HOME'} . '/.smore.yaml';
$configFile = './config.yaml' if -e './config.yaml';

my $config = LoadFile($configFile);
my $series = $config->{'series'};

my @lookup = @ARGV;
@lookup = keys %{ $series } if @ARGV == 0;

chdir dirname(__FILE__);
eval "use Torrents::" . $config->{'search'} . ";";

my @latest = ("", 0, 0);
sub se { 
  my $origfilename = shift;

  my $storeas = $origfilename;
  $storeas = shift if scalar @_ > 0;

  my $filename = $origfilename;

  $filename =~ s/_/ /g;
  $filename =~ s/\b\d{4}\b//g;
  $filename =~ s/480p//g;
  $filename =~ s/720p//g;
  $filename =~ s/1080p//g;
  $filename =~ s/1080i//g;
  $filename =~ s/x264//g;
  $filename =~ s/h264//g;

  $filename =~ s/^.*\[(\d+)\.(\d+)\]/S$1E$2 /g;
  while ( $filename =~ /\.(.*)\./ ) {
      $filename =~ s/\.(.*)\./ $1./g;
  }
  $filename =~ s/^.*\bS?(\d+)xE?(\d+)\b/S$1E$2 /g;
  $filename =~ s/^.*s(\d+)\s*e(\d+)\b/S$1E$2 /gi;
  $filename =~ s/^.*S(\d+)\s*Episode\s*(\d+)\b/S$1E$2 /gi;
  $filename =~ s/^.*Season\s*(\d+).*Episode\s*(\d+)\b/S$1E$2 /gi;
  $filename =~ s/^.*?(\d+)(\d{2})/S$1E$2 /g if $filename !~ /S\d+E\d+/;

  $filename =~ s/\[[^\[]+\]//g;

  $filename =~ s/ - //g;
  $filename =~ s/^S(\d)E/S0$1E/g;
  $filename =~ s/^S(\d+)E(\d)\b/S$1E0$2/g;
  $filename =~ s/^(S\d+E\d+)/$1 - /g;
  $filename =~ s/ - \././g;
  $filename =~ s/\s{2,}/ /g;
  $filename =~ s/ - ]/ - /g;
  $filename =~ s/\s{2,}/ /g;
  $filename =~ s/\s+\././g;
  $filename =~ s/ -\././g;

  return [] if $filename !~ /^S(\d+)E(\d+)/;
  if ($1 > $latest[1]) {
    @latest = ($storeas, $1, $2);
  } elsif ($1 == $latest[1] && $2 > $latest[2]) {
    $latest[0] = $storeas;
    $latest[2] = $2;
  }
}

sub processFile {
  return if -d $File::Find::name;
  &se($_);
}

my $i = 0;
for my $s (@lookup) {
  print "\n" if $i++ > 0;

  if (!exists $series->{$s}) {
    print "Found no matching series for '$s'...\n";
    next;
  }

  my $hit = $series->{$s};
  print "Looking up newest episode for " . $hit->{'name'} . "...\n";

  @latest = ('', 0, 0);
  find ( \&processFile, $hit->{'location'} );
  my @localLatest = ($latest[0], $latest[1], $latest[2]);
  @latest = ('', 0, 0);

  foreach my $torrent (@{ search($hit->{'name'}) }) {
    if ($torrent->{'quality'} > 0.1) {
      &se($torrent->{'name'}, $torrent);
    } else {
      #print STDERR "Skipping episode with low ranking (${torrent->{'quality'}}): ${torrent->{'name'}}\n";
    }
  }

  if ($latest[1] < $localLatest[1] || ($latest[1] == $localLatest[1] && $latest[2] <= $localLatest[2])) {
    print "No new episodes, sorry... (latest: ${latest[1]}:${latest[2]})\n";
    next;
  }

  print "New episode out! (local: ${localLatest[1]}:${localLatest[2]}, latest: ${latest[1]}:${latest[2]})\n";
  print "Download .torrent here: ${latest[0]->{'url'}}\n";
  
  if (direct() and defined $config->{'downloader'}) {
    print "Do you want me to start the download automatically? [Y/n] ";
    my $yes = <STDIN>;
    if ($yes !~ /^[nN]/) {
      defined (my $kid = fork) or print "Could not start download process: $!\n";
      if (!$kid) {
        setsid or die "Can't start a new session: $!";
        exec($config->{'downloader'}, $latest[0]->{'url'}) or die("Failed to launch download program " . $config->{'downloader'} . "... Sorry.\n");
      }

      print "Your torrent program should have opened, and prompted you to start the download. Enjoy!\n";
    }
  }
}
