
package DreamGuild::WWW::Helpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';


sub register {

  my ($self, $app) = @_;

  $app->helper (relative_date => \&relative_date);
  $app->helper (class_name => \&class_name);
  $app->helper (imgur => \&imgur);
  $app->helper (user_theme => \&user_theme);
  $app->helper (user_theme_slug => \&user_theme_slug);

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


sub imgur {

  my ($self, $raw_imgur_url, $size, $subfix) = @_;

  $size ||= "original";
  $subfix ||= "jpg";

  my @imgur_parsed = $raw_imgur_url =~ /http[s]*:\/\/(?:i\.imgur\.com\/(.*?)\.(?:jpg|png|gif)|imgur\.com\/(?:gallery\/)?(.*))$/;

  my $imgur_id = (defined ($imgur_parsed[0]) ? $imgur_parsed[0] : $imgur_parsed[1]);

  return undef unless $imgur_id;

  my $imgur_url = "https://i.imgur.com/$imgur_id";

  # Get more types in: https://api.imgur.com/models/image
  if ($size eq 'small' || $size eq 's') {
    $imgur_url .= 's';
  } elsif ($size eq 'medium' || $size eq 'm') {
    $imgur_url .= 'm';
  } elsif ($size eq 'large' || $size eq 'l') {
    $imgur_url .= 'l';
  } elsif ($size eq 'huge' || $size eq 'h') {
    $imgur_url .= 'h';
  }

  # Subfix is always 
  if ($subfix eq 'png') {
    $imgur_url .= '.png';
  } elsif ($subfix eq 'gif') {
    $imgur_url .= '.gif';
  } else {
    $imgur_url .= '.jpg';
  }

  return $imgur_url;
}


sub user_theme {
  my $self = shift;
  my $user = $self->stash ('user');

  # Default theme: bootstrap
  if (!defined ($user->{theme}) || $user->{theme} == 0) {
    return '//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap.min.css';
  }

  # Slate
  elsif ($user->{theme} == 1) {
    return '//cdnjs.cloudflare.com/ajax/libs/bootswatch/3.2.0+1/slate/bootstrap.min.css';
  }

  # Bootstrap default
  elsif ($user->{theme} == 2) {
    return '//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap.min.css';
  }

  # Cerulean
  elsif ($user->{theme} == 3) {
    return '//cdnjs.cloudflare.com/ajax/libs/bootswatch/3.2.0+1/cerulean/bootstrap.min.css';
  }

  return '//cdnjs.cloudflare.com/ajax/libs/bootswatch/3.2.0+1/cyborg/bootstrap.min.css';
}


sub user_theme_slug {
  my $self = shift;
  my $user = $self->stash ('user');

  # Default theme: bootstrap
  if (!defined ($user->{theme}) || $user->{theme} == 0) {
    return 'bootstrap'
  }

  # Slate
  elsif ($user->{theme} == 1) {
    return 'slate';
  }

  # Bootstrap default and cerulean
  elsif ($user->{theme} == 2 || $user->{theme} == 3) {
    return 'bootstrap'
  }

  return 'cyborg';
}


1;
