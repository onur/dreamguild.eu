
package DreamGuild::WWW::News;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;



sub list {
  my $self = shift;

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

  $self->render (news => $news);
}


sub post_get {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  $self->render (js_ckeditor => 1);
}


sub post_post {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);
  
  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'news/post_get',
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
