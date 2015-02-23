
package DreamGuild::WWW::Roster;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;
use DreamGuild::Utils::Progress;
use JSON::XS;



sub list {
  my $self = shift;
  my $user = $self->stash ('user');

  my $class = 0;
  $class = $self->param ('class')
    if (defined ($self->param ('class')) && $self->param ('class') =~ /^\d+$/);
  my $main = 1;

  $main = 0 if defined ($self->param ('all'));

  my $characters = ();
  my $counts = {
    classes      => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    classes_max  => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    classes_main => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ilvls_max    => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ilvls_main   => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    roles        => [0, 0, 0]
  };

  my $order = 'rank ASC';
  my $request_order = $self->param ('order') || '';

  if ($request_order eq 'ilvl') {
    $order = 'ailvl DESC';
  } elsif ($request_order eq 'name') {
    $order = 'name ASC';
  }


  DreamGuild::DB->iterate (
    'SELECT name, class, rank, thumbnail, spec, talents, ailvl, eilvl, level, is_main FROM roster ORDER BY ' . $order,
    sub {
      my $character = {
        name      => $_->[0],
        class     => $_->[1],
        rank      => $_->[2],
        thumbnail => $_->[3],
        spec      => $_->[4],
        talents   => ($_->[5] ? decode_json ($_->[5]) : undef),
        ailvl     => $_->[6],
        eilvl     => $_->[7],
        level     => $_->[8],
        is_main   => $_->[9]
      };

      # FIXME: this is a mess
      if (!$class) {
        if ($main) {
          push @{$characters}, $character if $character->{is_main};
        } else {
          push @{$characters}, $character;
        }
      } elsif ($class == $character->{class}) {
        if ($main) {
          push @{$characters}, $character if $character->{is_main};
        } else {
          push @{$characters}, $character;
        }
      }

      # increase class count
      ++$counts->{classes}->[$_->[1]- 1];
      ++$counts->{classes_max}->[$_->[1]- 1] if ($_->[8] >= 100);
      ++$counts->{classes_main}->[$_->[1]- 1] if ($_->[9] && $_->[8] >= 100);
      $counts->{ilvls_max}->[$_->[1]- 1] += $_->[7] if ($_->[8] >= 100);
      $counts->{ilvls_main}->[$_->[1]- 1] += $_->[7] if ($_->[8] >= 100 && $_->[9]);

      return 1;
    }

  );

  my $c = -1;
  for (@{$counts->{ilvls_max}}) {
    ++$c;
    next unless $counts->{classes_max}->[$c];
    $_ = int ($_ / $counts->{classes_max}->[$c]);
  }

  $c = -1;
  for (@{$counts->{ilvls_main}}) {
    ++$c;
    next unless $counts->{classes_main}->[$c];
    $_ = int ($_ / $counts->{classes_main}->[$c]);
  }

  $self->render (characters => $characters,
                 counts     => $counts);

}



sub lottery {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  my $users = [];
  my $tickets = [];    # ticket numbers of current user

  DreamGuild::DB->iterate (
    'SELECT id, name, class, lottery_ticket, uid FROM roster ORDER BY lottery_ticket ASC',
    sub {
      push @{$users}, {
        id     => $_->[0],
        name   => $_->[1],
        class  => $_->[2],
        ticket => $_->[3]
      };
      push @{$tickets}, $_->[3] if ($user->{id} == $_->[4] && $_->[3]);
      return 1;
    }
  );

  my $users_with_ticket = 0;
  $_->{ticket} and ++$users_with_ticket for (@{$users});

  # Select previous lotteries
  my $previous_lotteries = DreamGuild::DB::Lottery->select ('order by id asc');

  $self->render (count => $users_with_ticket,
                 users => $users,
                 tickets => $tickets,
                 next_ticket_number => DreamGuild::DB->get_option ('next_ticket_number') || 1,
                 previous_lotteries => $previous_lotteries);
}



sub lottery_result {
  my $self = shift;
  my $user = $self->stash ('user');

  my $lottery = DreamGuild::DB::Lottery->select ('where id = ?', $self->param ('id'));

  return $self->render (status => '404',
                        template => 'error',
                        error    => 'Lottery not found!')
    unless (scalar (@{$lottery}));


  $lottery->[0]->{tickets} = decode_json ($lottery->[0]->{tickets});

  # Select previous lotteries
  my $previous_lotteries = DreamGuild::DB::Lottery->select ('order by id asc');

  # Get ticket numbers of user
  my $tickets = [];
  DreamGuild::DB->iterate (
    'SELECT lottery_ticket FROM roster WHERE lottery_ticket > 0 AND uid = ? ORDER BY lottery_ticket ASC', $user->{id},
    sub {
      push @{$tickets}, $_->[0];
    }
  ) if ($user);

  $self->render (lottery => $lottery->[0],
                 previous_lotteries => $previous_lotteries,
                 next_ticket_number => DreamGuild::DB->get_option ('next_ticket_number'),
                 tickets => $tickets);
}


sub experience {
  my $self = shift;
  my $progress = DreamGuild::Utils::Progress->new->get_total_progress;

  # FIXME: this is used in so many places and cause so many code repeats
  my @boss_order = (
   'Kargath Bladefist',
   'The Butcher',
   'Brackenspore',
   'Tectus',
   'Twin Ogron',
   'Ko\'ragh',
   'Imperator Mar\'gok'
  );

  # count of progress
  my $people_with_6_7_H = 0;
  my $people_with_7_7_H = 0;
  my $people_with_7_7_N = 0;
  my $total_xp = 0;

  # ilvl chart
  my $people_with_680p = 0;
  my $people_with_670p = 0;
  my $people_with_660p = 0;
  my $people_with_650p = 0;

  for my $uid (keys %{$progress}) {
    # probably a for would be better
    # but I think this is much more readable and reliable
    if ($progress->{$uid}->{total}->{$boss_order[0]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[1]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[2]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[3]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[4]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[5]}->[2] &&
        $progress->{$uid}->{total}->{$boss_order[6]}->[2]) {
      $people_with_7_7_H++
    } elsif ($progress->{$uid}->{total}->{$boss_order[0]}->[2] &&
             $progress->{$uid}->{total}->{$boss_order[1]}->[2] &&
             $progress->{$uid}->{total}->{$boss_order[2]}->[2] &&
             $progress->{$uid}->{total}->{$boss_order[3]}->[2] &&
             $progress->{$uid}->{total}->{$boss_order[4]}->[2] &&
             $progress->{$uid}->{total}->{$boss_order[5]}->[2]) {
      $people_with_6_7_H++
    } elsif ($progress->{$uid}->{total}->{$boss_order[0]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[1]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[2]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[3]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[4]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[5]}->[1] &&
             $progress->{$uid}->{total}->{$boss_order[6]}->[1]) {
      $people_with_7_7_N++
    }

    if ($progress->{$uid}->{main_ilvl}) {
      if ($progress->{$uid}->{main_ilvl} >= 680) {
        $people_with_680p++;
      } elsif ($progress->{$uid}->{main_ilvl} >= 670) {
        $people_with_670p++;
      } elsif ($progress->{$uid}->{main_ilvl} >= 660) {
        $people_with_660p++;
      } elsif ($progress->{$uid}->{main_ilvl} >= 650) {
        $people_with_650p++;
      }
    }


    $total_xp += $progress->{$uid}->{points};
  }

  $self->render (js_chartjs => 1,
                 total_xp  => $total_xp,
                 people_with_6_7_H => $people_with_6_7_H,
                 people_with_7_7_H => $people_with_7_7_H,
                 people_with_7_7_N => $people_with_7_7_N,
                 people_with_680p  => $people_with_680p,
                 people_with_670p  => $people_with_670p,
                 people_with_660p  => $people_with_660p,
                 people_with_650p  => $people_with_650p,
                 progress => $progress);
}



sub ilvl_difference {

  my $self = shift;

  my $characters = {};
  my $ilvls = {};
  my $classes = {};

  DreamGuild::DB->iterate (
    'SELECT name, class, ilvl, time FROM ilvl_history ' .
    'JOIN roster ON ilvl_history.cid = roster.id WHERE ilvl > 0 ' .
    'ORDER BY time DESC',
    sub {
      $characters->{$_->[0]} = [] unless defined $characters->{$_->[0]};
      push @{$characters->{$_->[0]}}, [ $_->[1], $_->[2], $_->[3] ];
    }
  );


  for my $character (keys %{$characters}) {

    $classes->{$character} = $characters->{$character}->[0]->[0]
      if (defined $characters->{$character}->[0]->[0]);
    
    for (@{$characters->{$character}}) {

      my @time = localtime ($_->[2]);
      $time[5] += 1900;
      $time[4]++;

      $time[4] = "0$time[4]" if $time[4] < 10;
      $time[3] = "0$time[3]" if $time[3] < 10;

      my $time_str = "$time[5]-$time[4]-$time[3]";

      $ilvls->{$time_str} = {} unless defined $ilvls->{$time_str};

      $ilvls->{$time_str}->{$character} = $_->[1];


    }
    
  }

  # Rest is for chartjs
  my @labels = sort (keys (%{$ilvls}));
  my $chartjs_data = {};

  for my $character (keys (%{$classes})) {

    my $previous_ilvl = 0;

    $chartjs_data->{$character} = [];

    for my $time (@labels) {

      my $ilvl = $previous_ilvl;

      if (defined ($ilvls->{$time}->{$character})) {
        $ilvl = $previous_ilvl = $ilvls->{$time}->{$character};
      }

      push @{$chartjs_data->{$character}}, $ilvl;

    }

  }

  # write data into CSV
  open my $fh, ">/tmp/data.csv";
  # header
  print $fh "Player,";
  my $c = 0;
  for (@labels) {
    print $fh "$_," if ++$c % 7 == 0;
  }
  print $fh $labels[-1];
  print $fh "\n";
  for my $character (sort (keys (%{$classes}))) {
    next if ($chartjs_data->{$character}->[-1] < 670);
    print $fh "$character,";
    $c = 0;
    for my $ilvl (@{$chartjs_data->{$character}}) {
      if (++$c % 7 == 0) {
        print $fh "," if $ilvl == 0;
        print $fh "$ilvl," if $ilvl > 0;
      }
    }
    print $fh $chartjs_data->{$character}->[-1];
    print $fh "\n";
  }
  close $fh;

  $self->render (js_chartjs   => 1,
                 labels       => [ @labels ],
                 chartjs_data => $chartjs_data,
                 classes      => $classes);

}


1;
