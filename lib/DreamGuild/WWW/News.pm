
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

  # Get recruitment info
  my $recruitment = DreamGuild::DB::Pages->select ('where slug = ?', 'recruitment');

  $self->render (recruitment => (scalar (@{$recruitment}) ?
                                 $recruitment->[0]->{content} : ''));
}


sub list {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

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


  # Get ticket numbers of user
  my $tickets = [];
  DreamGuild::DB->iterate (
    'SELECT lottery_ticket FROM roster WHERE lottery_ticket > 0 AND uid = ? ORDER BY lottery_ticket ASC', $user->{id},
    sub {
      push @{$tickets}, $_->[0];
    }
  );


  $self->render (news               => $news,
                 who_is_online      => $who_is_online,
                 tickets            => $tickets,
                 next_ticket_number => DreamGuild::DB->get_option ('next_ticket_number'),
                 unassigned_character_count => $unassigned_character_count);
}


sub add {
  my $self = shift;
  $self->render (js_ckeditor => 1);
}


sub add_post {
  my $self = shift;
  my $user = $self->stash ('user');

  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'news/add',
                        error => 'Title or content is empty!',
                        js_ckeditor => 1)
    if (!$title || !$content);

  DreamGuild::DB::News->new (
    uid     => $user->{id},
    title   => $title,
    content => $content,
    time     => time ()
  )->insert;

  return $self->redirect_to ('/');
}


sub admin_list {

  my $self = shift;

  my $news = [];
  DreamGuild::DB->iterate (
    'SELECT id, title FROM news ORDER BY id DESC',
    sub {
      push @{$news}, [ $_->[0], $_->[1] ];
    }
  );


  $self->render (news => $news);
}


sub edit {
  my $self = shift;

  my $page_row = DreamGuild::DB::News->select ('where id = ?', $self->param ('id'));
  
  return $self->render (status   => '404',
                        template => 'error',
                        error    => 'This page doesn\'t exist!')
    unless (scalar (@{$page_row}));


  $self->param (title => $page_row->[0]->{title});
  $self->param (content => $page_row->[0]->{content});

  return $self->render (template => 'news/add',
                        page => $page_row->[0],
                        js_ckeditor => 1);
}



sub edit_post {
  my $self = shift;

  my $new = DreamGuild::DB::News->load ($self->param ('id'));
  return $self->render (template => 'news/add',
                        error => 'Not found!',
                        js_ckeditor => 1)
    unless ($new);

  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'news/add',
                        error => 'Title or content is empty!',
                        js_ckeditor => 1)
    if (!$title || !$content);

  $new->update (
    title   => $title,
    content => $content,
  );

  $self->flash (text => $title . ' successfully edited.');
  return $self->redirect_to ('/admin/news');
}


sub remove {
  my $self = shift;

  my $new = DreamGuild::DB::News->load ($self->param ('id'));

  DreamGuild::DB::News->delete_where ('id = ?', $self->param ('id'));
  $self->flash (text => $new->{title} . ' successfully removed.');

  return $self->redirect_to ('/admin/news');
}

1;
