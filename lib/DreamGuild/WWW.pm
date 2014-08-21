package DreamGuild::WWW;
use Mojo::Base 'Mojolicious';

use DreamGuild::DB;
use DreamGuild::WWW::Helpers;


our $VERSION = '0.1';


sub before_filter {
  my $self = shift;

  my $uid = $self->session ('uid');
  return unless $uid;

  my $user_row = DreamGuild::DB::User->select ('where id = ?', $uid);
  return unless scalar (@{$user_row});

  # Getting main
  $user_row->[0]->{mainc} = DreamGuild::DB::Roster->load ($user_row->[0]->{main})
    if ($user_row->[0]->{main});

  # Getting open application count
  my $open_application_count = DreamGuild::DB::Application->count ('where status = 1');

  $self->stash ('user', $user_row->[0]);
  $self->stash ('open_application_count', $open_application_count);
}




# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secrets (['3c7a4779b7a08b9db4ac2980792569dd' . 
                   'ad27223703d092c9c1135449a792b637']);

  $self->defaults (layout => 'default');

  $self->hook(before_dispatch => \&before_filter);

  $self->plugin('DreamGuild::WWW::Helpers');


  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get ('/')->to('News#list');

  $r->get ('/news')->to ('News#list');
  $r->get ('/news/add')->to('News#add');
  $r->post ('/news/add')->to('News#add_post');

  $r->get ('/roster')->to('Roster#list');

  $r->get ('/register')->to ('user#register');
  $r->post ('/register')->to ('user#register_post');

  $r->get ('/login')->to ('user#login');
  $r->post ('/login')->to ('user#login_post');
  $r->get ('/logout')->to ('user#logout');

  $r->get ('/apply')->to ('Application#apply');
  $r->post ('/apply')->to ('Application#apply_post');

  $r->get ('/applications')->to ('Application#list');
  $r->get ('/applications/closed')->to ('Application#list', {app_status => 'closed'});

  $r->get ('/applications/:id')->to ('Application#application');
  $r->post ('/applications/:id')->to ('Application#application_questions_post');
  $r->post ('/applications/:id/comment')->to ('Application#application_add_comment');
  $r->get ('/applications/:id/vote/:vote')->to ('Application#application_vote');
  $r->get ('/applications/:id/accept')->to ('Application#application_accept');
  $r->post ('/applications/:id/decline')->to ('Application#application_decline');

  # Pages
  $r->get ('/pages/add')->to ('Pages#add');
  $r->post ('/pages/add')->to ('Pages#add_post');

  $r->get ('/:slug')->to ('Pages#page');
}


1;
