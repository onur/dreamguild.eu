
package DreamGuild::Utils::Progress;

use strict;
use warnings;


sub new {
  my $class = shift;
  bless {}, $class;
}


# This function returns general progress of character progress
# It's like 6/7 HC Highmaul, 14/14 HC SOO etc.
# Designed to use in applications
sub get_progress {
  my $self = shift;
  my $data = shift;
  my @instances = @_;


  my $progress = [];

  for my $instance (@instances) {

    for my $raid (@{$data->{raids}}) {

      next if $instance ne $raid->{name};

      my $boss_count = scalar (@{$raid->{bosses}});
      my $lfr_count = 0;
      my $flex_count = 0;
      my $normal_count = 0;
      my $heroic_count = 0;
      my $mythic_count = 0;

      for my $boss (@{$raid->{bosses}}) {
        ++$lfr_count if ($boss->{lfrKills});
        ++$flex_count if ($boss->{flexKills});
        ++$normal_count if ($boss->{normalKills});
        ++$heroic_count if ($boss->{heroicKills});
        ++$mythic_count if ($boss->{mythicKills});
      }

      push @{$progress}, { name       => $raid->{name},
                           boss_count => $boss_count,
                           lfr_count  => $lfr_count,
                           flex_count => $flex_count,
                           normal_count => $normal_count,
                           heroic_count => $heroic_count,
                           mythic_count => $mythic_count };

    }
  }

  return $progress;
}


1;
