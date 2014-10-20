
package DreamGuild::WWW::Roster;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;
use JSON::XS;



sub list {
  my $self = shift;
  my $user = $self->stash ('user');

  my $class = 0;
  $class = $self->param ('class')
    if (defined ($self->param ('class')) && $self->param ('class') =~ /^\d+$/);
  my $main = $self->param ('main') || 0;

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  my $characters = ();
  my $counts = {
    classes      => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    classes_max  => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    classes_main => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ilvls_max    => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ilvls_main   => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    roles        => [0, 0, 0]
  };

  DreamGuild::DB->iterate (
    'SELECT name, class, rank, thumbnail, spec, talents, ailvl, eilvl, level, is_main FROM roster ORDER BY rank ASC',
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
      ++$counts->{classes_max}->[$_->[1]- 1] if ($_->[8] >= 90);
      ++$counts->{classes_main}->[$_->[1]- 1] if ($_->[9] && $_->[8] >= 90);
      $counts->{ilvls_max}->[$_->[1]- 1] += $_->[7] if ($_->[8] >= 90);
      $counts->{ilvls_main}->[$_->[1]- 1] += $_->[7] if ($_->[8] >= 90 && $_->[9]);

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

  $self->render (count => $users_with_ticket,
                 users => $users,
                 tickets => $tickets,
                 next_ticket_number => DreamGuild::DB->get_option ('next_ticket_number') || 1);
}



sub lottery_result {
  my $self = shift;

  my $lottery = DreamGuild::DB::Lottery->select ('where id = ?', $self->param ('id'));

  return $self->render (status => '404',
                        template => 'error',
                        error    => 'Lottery not found!')
    unless (scalar (@{$lottery}));


  $lottery->[0]->{tickets} = decode_json ($lottery->[0]->{tickets});

  $self->render (lottery => $lottery->[0]);
}


1;
