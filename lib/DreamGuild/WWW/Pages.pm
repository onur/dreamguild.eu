
package DreamGuild::WWW::Pages;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;



sub page {
  my $self = shift;
  
  my $page_row = DreamGuild::DB::Pages->select ('where slug = ?', $self->param ('slug'));
  
  return $self->render (status   => '404',
                        template => 'error',
                        error    => 'This page doesn\'t exist!')
    unless (scalar (@{$page_row}));


  return $self->render (page => $page_row->[0]);
}


sub add {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  $self->render (js_ckeditor => 1);

  $self->render ();
}



sub add_post {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    if (!defined ($user) ||
        $user->level < 5);

  my $slug = $self->param ('slug');
  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'pages/add',
                        error => 'All fields are required')
    if (!$slug || !$title || !$content);

  DreamGuild::DB::Pages->new (
    slug    => $slug,
    title   => $title,
    content => $content
  )->insert;

  return $self->redirect_to ('/' . $slug);
}


1;
