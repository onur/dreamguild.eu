
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
    'SELECT id, name FROM roster ORDER BY name ASC',
    sub {
      push @{$characters}, {
        id     => $_->[0],
        name   => $_->[1],
      };
      $uid = $_->[0] if ($_->[1] eq $account);
      return 1;
    }
  );

  warn "UID: $uid";
  $self->render (account => $account,
                 characters => $characters);
}


1;
