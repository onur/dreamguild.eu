
package DreamGuild::WWW::Admin;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;




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

  DreamGuild::DB->iterate (
    'SELECT id, uid, name FROM roster ORDER BY name ASC',
    sub {
      my $character = {
        id     => $_->[0],
        uid    => $_->[1],
        name   => $_->[2],
        owner  => 0
      };
      $uid = $_->[1] if ($_->[2] eq $account);
      push @{$characters}, $character;
    }
  );

  return $self->render (template => 'error',
                        error    => 'Unable to find user')
      if (!$uid);

  for (@{$characters}) {
    $_->{owner} = 1 if ($uid == $_->{uid});
  }

  $self->render (account => $account,
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

  
  $success_message = "Successfully assigned: <br> $account => " . join (', ', @alt_names);

  # If user chaged his main
  if ($current_main != $new_main) {
    my $user = DreamGuild::DB::User->load ($user_id);
    $user->update (main => $new_main);
    $success_message .= "<br>$account\'s new main changed to $new_main_name";
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


1;
