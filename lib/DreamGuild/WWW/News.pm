
package DreamGuild::WWW::News;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;




sub home {
  my $self = shift;
  my $user = $self->stash ('user');

  # redirect to news if its already a user
  return $self->redirect_to ('/news') if (defined ($user) && $user->level >= 5);


  # Check if user have a application
  # And if there's one redirect to application page
  if (defined ($user) && $user->{level} <= 1) {
    my $row = DreamGuild::DB::Application->select ('where uid = ? ORDER BY id DESC',
                                                   $user->{id});
    return $self->redirect_to ('/applications/' . $row->[0]->{app_id})
      if (scalar (@{$row}));
  }

  $self->render;
}


sub list {
  my $self = shift;
  my $user = $self->stash ('user');

  my $news = ();
  DreamGuild::DB->iterate (
    'SELECT name, class, title, content, time, thumbnail FROM news ' .
    'INNER JOIN user ON news.uid = user.id ' .
    'INNER JOIN roster ON user.main = roster.id ' .
    'ORDER BY news.id DESC',
    sub {
      push @{$news}, {
        name    => $_->[0],
        class   => $_->[1],
        title   => $_->[2],
        content => $_->[3],
        time    => $_->[4],
        thumbnail => $_->[5]
      };
    }
  );


  my $unassigned_character_count = 0;
  # If user is admin get unassigned_character_count
  $unassigned_character_count = DreamGuild::DB::Roster->count ('where uid = 0')
    if ($user->{level} >= 30);


  # Get who is online
  my $who_is_online = [];
  DreamGuild::DB->iterate (
    'SELECT name, class, thumbnail FROM user INNER JOIN roster ON roster.id = user.main WHERE last_active >= ? ORDER BY name ASC',
    time () - 3600,
    sub {
      push @{$who_is_online}, {
        name      => $_->[0],
        class     => $_->[1],
        thumbnail => $_->[2]
      };
    }
  );


  $self->render (news => $news,
                 who_is_online => $who_is_online,
                 unassigned_character_count => $unassigned_character_count);
}


sub add {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  $self->render (js_ckeditor => 1);
}


sub add_post {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);
  
  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'news/add',
                        error => 'Title or content is empty!')
    if (!$title || !$content);

  DreamGuild::DB::News->new (
    uid     => $user->{id},
    title   => $title,
    content => $content,
    time     => time ()
  )->insert;

  return $self->redirect_to ('/');
}

1;
