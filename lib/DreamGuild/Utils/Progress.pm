
package DreamGuild::Utils::Progress;

use strict;
use warnings;
use DreamGuild::DB;
use JSON::XS;


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
      my $bosses = {};

      for my $boss (@{$raid->{bosses}}) {
        ++$lfr_count if ($boss->{lfrKills});
        ++$flex_count if ($boss->{flexKills});
        ++$normal_count if ($boss->{normalKills});
        ++$heroic_count if ($boss->{heroicKills});
        ++$mythic_count if ($boss->{mythicKills});

        my $name = $boss->{name};

        unless (defined ($bosses->{$name})) {
          # boss head counts: lfr, normal, heroic, mythic
          $bosses->{$name} = [ 0, 0, 0, 0 ];
        }

        $bosses->{$name}->[0] += $boss->{lfrKills};
        $bosses->{$name}->[1] += $boss->{normalKills};
        $bosses->{$name}->[2] += $boss->{heroicKills};
        $bosses->{$name}->[3] += $boss->{mythicKills};

      }

      push @{$progress}, { name       => $raid->{name},
                           boss_count => $boss_count,
                           lfr_count  => $lfr_count,
                           flex_count => $flex_count,
                           normal_count => $normal_count,
                           heroic_count => $heroic_count,
                           mythic_count => $mythic_count,
                           bosses     => $bosses };

    }
  }

  return $progress;
}



sub get_total_progress {
  my $self = shift;

  my $users = {};

  DreamGuild::DB::Roster->iterate (
    'where level = 100',
    sub {
      unless (defined ($users->{$_->{uid}})) {
        $users->{$_->{uid}} = {};
        $users->{$_->{uid}}->{characters} = [];
      }

      push @{$users->{$_->{uid}}->{characters}}, {
        id   => $_->{id},
        name => $_->{name},
        is_main => $_->{is_main},
        class => $_->{class},
        thumbnail => $_->{thumbnail},
        progress => $self->get_progress (decode_json ($_->{progress}), 'Highmaul')
      };

      if ($_->{is_main}) {
        $users->{$_->{uid}}->{main} = $_->{name};
        $users->{$_->{uid}}->{main_class} = $_->{class};
        $users->{$_->{uid}}->{main_thumbnail} = $_->{thumbnail};
      }

      return 1;
    }
  );


  # Getting last serialized and saved progress from database
  DreamGuild::DB::Progress->iterate (
    sub {
      return 1 unless defined $users->{$_->{uid}};
      $users->{$_->{uid}}->{previous_serialized} = $_->{progress};
      $users->{$_->{uid}}->{previous_rank}       = $_->{rank};
      $users->{$_->{uid}}->{previous_experience} = $_->{points};
      return 1;
    }
  );



  my %points = (
                          # LFR  N   H     M
   'Kargath Bladefist'  => [ 0,  1,  2,   10 ],
   'The Butcher'        => [ 0,  1,  2,   50 ],
   'Brackenspore'       => [ 0,  1,  2,   30 ],
   'Tectus'             => [ 0,  1,  2,   30 ],
   'Twin Ogron'         => [ 0,  1,  2,   20 ],
   'Ko\'ragh'           => [ 0,  1,  2,   10 ],
   'Imperator Mar\'gok' => [ 0,  2, 10,  100 ]
  );

  # Boss order in array required for serialization
  my @boss_order = (
   'Kargath Bladefist',
   'The Butcher',
   'Brackenspore',
   'Tectus',
   'Twin Ogron',
   'Ko\'ragh',
   'Imperator Mar\'gok'
  );


  for my $uid (keys %{$users}) {

    unless (defined $users->{$uid}->{total}) {
      $users->{$uid}->{total} = {};
      $users->{$uid}->{delta} = {};
      $users->{$uid}->{points} = 0;
    }

    for my $boss (keys %points) {
      unless (defined $users->{$uid}->{total}->{$boss}) {
        $users->{$uid}->{total}->{$boss} = [ 0, 0, 0, 0 ];
        $users->{$uid}->{delta}->{$boss} = [ 0, 0, 0, 0 ];
      }
    }

    # convert users previous kills to structure
    if (defined $users->{$uid}->{previous_serialized}) {
      $users->{$uid}->{previous_progress} = {};
      my @previous_kills = split /:/, $users->{$uid}->{previous_serialized};
      my $boss_index = 0;
      for my $boss (@boss_order) {
        $users->{$uid}->{previous_progress}->{$boss} = [];
        for (0..3) {
          push @{$users->{$uid}->{previous_progress}->{$boss}}, $previous_kills[$boss_index++];
        }
      }
    }

    # summarize character experience points and total kill counts
    for my $character (@{$users->{$uid}->{characters}}) {

      for my $instance (@{$character->{progress}}) {
        for my $boss (keys %points) {
          next unless defined $instance->{bosses}->{$boss};

          for (0..3) {
            $users->{$uid}->{total}->{$boss}->[$_] += $instance->{bosses}->{$boss}->[$_];
            $users->{$uid}->{points} += $points{$boss}->[$_] * $instance->{bosses}->{$boss}->[$_];
          }
        }
      }

    }

    # create delta structure
    for my $boss (keys %points) {
      for (0..3) {
        if (defined $users->{$uid}->{previous_progress}) {
          $users->{$uid}->{delta}->{$boss}->[$_] = $users->{$uid}->{total}->{$boss}->[$_] - $users->{$uid}->{previous_progress}->{$boss}->[$_];
        } else {
          $users->{$uid}->{delta}->{$boss}->[$_] = $users->{$uid}->{total}->{$boss}->[$_];
        }
      }
    }

    # Serialization progress
    $users->{$uid}->{serialized} = '';
    $users->{$uid}->{delta_serialized} = '';

    for my $boss (@boss_order) {
      for (0..3) {
        # seperator
        $users->{$uid}->{serialized} .= ':' if ($users->{$uid}->{serialized} ne '');
        $users->{$uid}->{delta_serialized} .= ':' if ($users->{$uid}->{delta_serialized} ne '');

        # serialize boss
        $users->{$uid}->{serialized} .= $users->{$uid}->{total}->{$boss}->[$_];
        $users->{$uid}->{delta_serialized} .= $users->{$uid}->{delta}->{$boss}->[$_];
      }
    }

  }

  # Set current rank of user
  my @experienced_sorted = sort { $users->{$b}->{points} <=> $users->{$a}->{points} }
                           keys (%{$users});

  for my $uid (keys %{$users}) {
    my $rank = 0;
    for (@experienced_sorted) {
      $rank++;
      last if $uid == $_;
    }
    $users->{$uid}->{rank} = $rank;
  }

  return $users;
}


sub save_total_progress {
  my ($self, $users) = @_;

  DreamGuild::DB->begin;

  for my $uid (keys %{$users}) {

    my %data = (
      uid => $uid,
      points => $users->{$uid}->{points},
      progress => $users->{$uid}->{serialized},
      rank => $users->{$uid}->{rank}
    );

    my $row = DreamGuild::DB::Progress->select ('where uid = ?', $uid);
    unless (scalar @{$row}) {
      DreamGuild::DB::Progress->new (%data)->insert;
    } else {
      delete ($data{uid});
      $row->[0]->update (%data);
    }

    DreamGuild::DB->do ('INSERT OR IGNORE INTO progress_history VALUES (?, ?, ?)',
                        {}, $uid, $data{points}, time ());

  }

  DreamGuild::DB->commit;

}


1;
