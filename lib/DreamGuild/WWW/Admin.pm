
package DreamGuild::WWW::Admin;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;
use JSON::XS;




sub assign {
  my $self = shift;
  my $users = [];

  DreamGuild::DB->iterate (
    'SELECT name, class, thumbnail FROM user INNER JOIN roster ON roster.id = user.main',
    sub {
      push @{$users}, {
        name      => $_->[0],
        class     => $_->[1],
        thumbnail => $_->[2]
      };
    }
  );

  $self->render (users => $users);
}


sub assign_account {
  my $self = shift;
  my $account = $self->param ('account');

  my $characters = [];
  my $uid = 0;
  my $main_id = 0;

  DreamGuild::DB->iterate (
    'SELECT id, uid, name FROM roster ORDER BY name ASC',
    sub {
      my $character = {
        id     => $_->[0],
        uid    => $_->[1],
        name   => $_->[2],
        owner  => 0
      };
      $main_id = $_->[0] if ($_->[2] eq $account);
      $uid = $_->[1] if ($_->[2] eq $account);
      push @{$characters}, $character;
    }
  );

  return $self->render (template => 'error',
                        error    => 'Unable to find user')
      if (!$uid && !$main_id);

  # If there is no UID
  # Create a blank account
  if (!$uid) {
    my $user_row = DreamGuild::DB::User->new (
      email    => $account . '-' . int (rand (1000000)) . '@dreamguild.eu',
      password => '',
      # level 1 is blank account
      level    => 1,
      dkp      => 0,
      main     => $main_id,
      join_time => time (),
      last_active => 0
    )->insert;
    $uid = $user_row->id;
    DreamGuild::DB->do ('UPDATE roster SET uid = ? WHERE name = ?',
      {}, $uid, $account);
    for (@{$characters}) {
      $_->{uid} = $uid if ($_->{name} eq $account);
    }
  }

  for (@{$characters}) {
    $_->{owner} = 1 if ($uid == $_->{uid});
  }

  $self->render (uid        => $uid,
                 account    => $account,
                 characters => $characters);
}


sub assign_account_post {
  my $self = shift;
  my $account = $self->param ('account');

  my $user_id = 0;
  my $current_main = 0;
  my $new_main = $self->param ('main');
  my @alts = $self->param ('alts');

  my $success_message = '';


  # First select main account of $account (main character name)
  DreamGuild::DB->iterate (
    'SELECT uid FROM roster WHERE name = ?', $account,
    sub {
      $user_id = $_->[0]
    }
  );

  return $self->render (template => 'error',
                        error    => 'Unable to find user')
      if (!$user_id);

  my @alt_names;
  my $new_main_name = '';
  for (@alts) {
    my $char = DreamGuild::DB::Roster->load ($_);

    my $is_main = 0;

    if ($char->{is_main}) {
      $current_main = $char->{id};
    }

    if ($char->{id} == $new_main) {
      $new_main_name = $char->{name};
      $is_main = 1;
    } elsif ($current_main == $new_main && $char->{name} eq $account) {
      $is_main = 1;
    }

    $char->update (
      uid => $user_id,
      is_main => $is_main
    );
    push @alt_names, $char->{name};
  }

  
  $success_message = "Successfully assigned: <br> $account =&gt; " . join (', ', @alt_names);

  # If user chaged his main
  if ($current_main != $new_main) {
    my $user = DreamGuild::DB::User->load ($user_id);
    if ($user->{main} != $new_main) {
      $user->update (main => $new_main);
      $success_message .= "<br>$account\'s new main changed to $new_main_name";
    }
  }

  $self->flash ('text' => $success_message);
  $self->redirect_to ('/admin/assign');
}


sub assign_unassigned_list {
  my $self = shift;
  my $characters = [];

  DreamGuild::DB->iterate (
    'SELECT name, thumbnail, class FROM roster WHERE uid = 0 ORDER BY name ASC',
    sub {
      push @{$characters}, [ $_->[0], $_->[1], $_->[2] ];
    }
  );

  $self->render (characters => $characters);
}


sub edit_option {
  my $self = shift;
  my $option = DreamGuild::DB::Options->select ('where option = ?', $self->param ('option'));

  return $self->render (template => 'error',
                        error    => 'This option doesn\'t exist!')
    unless (scalar (@{$option}));

  $self->render (option => $option->[0]);
}


sub edit_option_post {
  my $self = shift;
  my $option = DreamGuild::DB::Options->select ('where option = ?', $self->param ('option'));

  return $self->render (template => 'error',
                        error    => 'This option doesn\'t exist!')
    unless (scalar (@{$option}));

  my $value = $self->param ('value');

  if ($self->param ('option') eq 'questions') {
    my $json = JSON::XS->new;
    $json->incr_parse ($value) or
      return $self->render (template => 'error',
                            error    => 'Malformed JSON string. This may break ' .
                                        'whole application process. Please check ' .
                                        'questions again.');
  }

  $option->[0]->update (
    value => $value
  );

  $self->flash (text => 'Option: ' . $option->[0]->{option} . ' successfully edited.');
  $self->redirect_to ('/admin');
}



sub lottery_give {
  my $self = shift;
  my $cid  = $self->param ('cid');

  my $char = DreamGuild::DB::Roster->load ($cid);

  return $self->render (template => 'error',
                        error    => 'Invalid character')
    unless ($char);

  my $next_ticket_number = DreamGuild::DB->get_option ('next_ticket_number') || 1;

  if (defined ($char->{lottery_ticket}) && $char->{lottery_ticket} != 0) {
    $self->flash (text => "$char->{name} already have a ticket",
                  type => 'danger');
    return $self->redirect_to ('/lottery');
  }

  $char->update (
    lottery_ticket => $next_ticket_number
  );

  DreamGuild::DB->save_option ('next_ticket_number', $next_ticket_number + 1);

  $self->flash (text => 'You successfully gave a ticket to <strong>' . $char->name . '</strong>.<br>His ticket number is: ' . $next_ticket_number);
  $self->redirect_to ('/lottery');
}



sub lottery_winner {
  my $self = shift;

  if (!$self->param ('proof') || !$self->imgur ($self->param ('proof'))) {
    $self->flash ('text' => 'Proof is required and it must be a imgur URL',
                  type => 'danger');
    return $self->redirect_to ('/lottery');
  }

  my $participant = [];
  my $last_ticket = 0;
  my $winner_name = '';
  my $winner_ticket = 0;
  DreamGuild::DB->iterate (
    'SELECT id, name, class, lottery_ticket FROM roster WHERE lottery_ticket != 0 ORDER BY name ASC',
    sub {
      push @{$participant}, [ $_->[0], $_->[1], $_->[2], $_->[3] ];
      # Ok if guy with a last ticket leaves guild
      # we screwed. This is a design error in lottery system.
      # FIXME: Maybe I must stop removing characters from database
      $last_ticket = $_->[3] if ($_->[3] > $last_ticket);

      if ($self->param ('winner') == $_->[0]) {
        $winner_name = $_->[1];
        $winner_ticket = $_->[3];
      }

      return 1;
    }
  );

  if (!$self->param ('winner') || !scalar (@{$participant})) {
    $self->flash (text => 'Nobody have a ticket. I can\'t end this lottery',
                  type => 'danger');
    return $self->redirect_to ('/lottery');
  }

  my $row = DreamGuild::DB::Lottery->new (
    jackpot => $last_ticket * 250,
    time    => time (),
    winner  => $winner_name,
    winner_id => $self->param ('winner'),
    winner_ticket => $winner_ticket,
    proof   => $self->param ('proof'),
    tickets => encode_json ($participant)
  )->insert;

  # Set everyones lottery ticket and next_ticket_number to 0
  DreamGuild::DB->do ('UPDATE roster SET lottery_ticket = 0 WHERE lottery_ticket != 0');
  DreamGuild::DB->save_option ('next_ticket_number', 1);

  $self->flash (text => 'Lottery is successfully ended');
  $self->redirect_to ('/lottery/' . $row->{id});
}


1;
