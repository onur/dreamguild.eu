
package DreamGuild::WWW::Helpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';


sub register {

  my ($self, $app) = @_;

  $app->helper (relative_date => \&relative_date);
  $app->helper (class_name => \&class_name);

}



my $sPerMinute = 60;
my $sPerHour = $sPerMinute * 60;
my $sPerDay = $sPerHour * 24;
my $sPerMonth = $sPerDay * 30;
my $sPerYear = $sPerDay * 365;


sub relative_date {

  my ($self, $time, $current_time) = @_;

  $current_time = time () unless defined ($current_time);

  my $elapsed = $current_time - $time;

  if ($elapsed == 0) {
    return "Just now";
  } elsif ($elapsed < $sPerMinute) {
    return "$elapsed seconds ago";
  } elsif ($elapsed < $sPerHour) {
    return int ($elapsed/$sPerMinute) . " minutes ago";
  } elsif ($elapsed < $sPerDay) {
    return int ($elapsed/$sPerHour) . " hours ago";
  } elsif ($elapsed < $sPerMonth) {
    return int ($elapsed/$sPerDay) . " days ago";
  } elsif ($elapsed < $sPerYear) {
    return int ($elapsed/$sPerMonth) . " months ago";
  } else {
    return int ($elapsed/$sPerYear) . " years ago";
  }

}



sub class_name {

  my ($self, $class, $talents) = @_;

  my $str = '';

  # FIXME: this looks like crap
  if (defined ($talents)) {
    if (defined ($talents->[0]->{selected}) &&
        defined ($talents->[0]->{spec}->{name})) {
     $str .= $talents->[0]->{spec}->{name} . ' ';
    } elsif (defined ($talents->[1]->{selected}) &&
             defined ($talents->[1]->{spec}->{name})) {
     $str .= $talents->[1]->{spec}->{name} . ' ';
    }
  }

  if ($class == 1) {
    $str .= 'Warrior';
  } elsif ($class == 2) {
    $str .= 'Paladin';
  } elsif ($class == 3) {
    $str .= 'Hunter';
  } elsif ($class == 4) {
    $str .= 'Rogue';
  } elsif ($class == 5) {
    $str .= 'Priest';
  } elsif ($class == 6) {
    $str .= 'Death Knight';
  } elsif ($class == 7) {
    $str .= 'Shaman';
  } elsif ($class == 8) {
    $str .= 'Mage';
  } elsif ($class == 9) {
    $str .= 'Warlock';
  } elsif ($class == 10) {
    $str .= 'Monk';
  } elsif ($class == 11) {
    $str .= 'Druid';
  }
 
  return $str;
}


1;
