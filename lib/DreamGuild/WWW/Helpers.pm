
package DreamGuild::WWW::Helpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';


sub register {

  my ($self, $app) = @_;

  $app->helper (relative_date => \&relative_date);
  $app->helper (class_name => \&class_name);

}



my $timeUnits = [
  [ 'year',   60 * 60 * 24 * 364 ],
  [ 'month',  60 * 60 * 24 * 30  ],
  [ 'day',    60 * 60 * 24       ],
  [ 'hour',   60 * 60            ],
  [ 'minute', 60                 ]
];


sub relative_date {

  my ($self, $time, $current_time) = @_;

  $current_time = time () unless defined ($current_time);

  my $elapsed = $current_time - $time;

  return "Just now" if ($elapsed == 0);

  my $ret = '';
  for (@{$timeUnits}) {
    if ($elapsed >= $_->[1]) {
      my $num = int ($elapsed / $_->[1]);
      $ret .= "$num $_->[0]" . ($num > 1 ? 's' : '') . ' ago';
      last;
    }
  }

  return $ret;
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
