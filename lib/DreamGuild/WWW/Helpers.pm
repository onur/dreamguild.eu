
package DreamGuild::WWW::Helpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';


sub register {

  my ($self, $app) = @_;

  $app->helper (relative_date => \&relative_date);


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


1;
