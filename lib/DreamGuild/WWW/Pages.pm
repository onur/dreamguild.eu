
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


sub admin_list {
  my $self = shift;

  my $pages = [];
  DreamGuild::DB->iterate (
    'SELECT slug, title FROM pages ORDER BY slug ASC',
    sub {
      push @{$pages}, [ $_->[0], $_->[1] ];
    }
  );


  $self->render (pages => $pages);
}


sub edit {
  my $self = shift;

  my $page_row = DreamGuild::DB::Pages->select ('where slug = ?', $self->param ('slug'));
  
  return $self->render (status   => '404',
                        template => 'error',
                        error    => 'This page doesn\'t exist!')
    unless (scalar (@{$page_row}));


  $self->param (slug  => $page_row->[0]->{slug});
  $self->param (title => $page_row->[0]->{title});
  $self->param (content => $page_row->[0]->{content});

  return $self->render (template => 'pages/add',
                        page => $page_row->[0],
                        js_ckeditor => 1);
}


sub edit_post {
  my $self = shift;

  my $page_row = DreamGuild::DB::Pages->select ('where slug = ?', $self->param ('slug'));
  
  return $self->render (status   => '404',
                        template => 'error',
                        error    => 'This page doesn\'t exist!')
    unless (scalar (@{$page_row}));


  my $slug = $self->param ('slug');
  my $title = $self->param ('title');
  my $content = $self->param ('content');

  return $self->render (template => 'pages/add',
                        error => 'All fields are required',
                        js_ckeditor => 1)
    if (!$slug || !$title || !$content);

  $page_row->[0]->update (
    'slug'    => $slug,
    'title'   => $title,
    'content' => $content
  );

  $self->flash (text => $title . ' successfully edited.');
  return $self->redirect_to ('/admin/pages');
}


sub remove {
  my $self = shift;

  DreamGuild::DB::Pages->delete_where ('slug = ?', $self->param ('slug'));
  $self->flash (text => $self->param ('slug') . ' successfully removed.');

  return $self->redirect_to ('/admin/pages');
}


1;
