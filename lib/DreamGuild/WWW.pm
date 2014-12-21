package DreamGuild::WWW;
use Mojo::Base 'Mojolicious';

use DreamGuild::DB;
use DreamGuild::WWW::Helpers;


our $VERSION = '0.027';


sub before_filter {
  my $self = shift;

  $self->stash ('version', $VERSION);

  my $uid = $self->session ('uid');
  return unless $uid;

  my $user_row = DreamGuild::DB::User->select ('where id = ?', $uid);
  return unless scalar (@{$user_row});

  # Getting main
  $user_row->[0]->{mainc} = DreamGuild::DB::Roster->load ($user_row->[0]->{main})
    if ($user_row->[0]->{main});

  # Update last active column
  my $now = time ();
  if ($user_row->[0]->last_active + 3600 < $now) {
    $user_row->[0]->update (last_active => $now);
  }


  # Getting open application count
  my $open_application_count = DreamGuild::DB::Application->count ('where status = 1');

  $self->stash ('user', $user_row->[0]);
  $self->stash ('open_application_count', $open_application_count);
}



sub admin_bridge_callback {
  my $self = shift;
  my $user = $self->stash ('user');

  if (defined ($user) &&
      $user->{level} >= 30) {
    return 1;
  }

  $self->render (template => 'error',
                 error    => 'You don\'t have permission to see this page. Try to log in.');
  return undef;
}


sub about {
  my $self = shift;

  my $changes = '';

  open my $fh, 'Changes' or return $self->redirect_to ('/');
  $changes .= $_ while (<$fh>);
  close $fh;


  $self->render (template => 'about',
                 version => $VERSION,
                 mojolicious_version => $Mojolicious::VERSION,
                 perl_version => $^V,
                 changes => $changes);
}


# This method will run once at server start
sub startup {
  my $self = shift;

  $self->defaults (layout => 'default');

  $self->hook(before_dispatch => \&before_filter);

  $self->plugin('DreamGuild::WWW::Helpers');
  $self->plugin('Config' => { file => 'dreamguild.config' });

  $self->secrets ($self->config ('secrets'));

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get ('/')->to('News#list');

  $r->get ('/news')->to ('News#list');

  $r->get ('/roster')->to('Roster#list');
  $r->get ('/lottery')->to('Roster#lottery');
  $r->get ('/lottery/:id')->to('Roster#lottery_result');

  $r->get ('/register')->to ('user#register');
  $r->post ('/register')->to ('user#register_post');

  $r->get ('/login')->to ('user#login');
  $r->post ('/login')->to ('user#login_post');
  $r->get ('/logout')->to ('user#logout');

  $r->get ('/apply')->to ('Application#apply');
  $r->post ('/apply')->to ('Application#apply_post');

  $r->get ('/applications')->to ('Application#list');
  $r->get ('/applications/accepted')->to ('Application#list', {app_status => 'accepted'});
  $r->get ('/applications/rejected')->to ('Application#list', {app_status => 'rejected'});

  $r->get ('/applications/:id')->to ('Application#application');
  $r->post ('/applications/:id')->to ('Application#application_questions_post');
  $r->post ('/applications/:id/comment')->to ('Application#application_add_comment');
  $r->get ('/applications/:id/vote/:vote')->to ('Application#application_vote');
  $r->get ('/applications/:id/accept')->to ('Application#application_accept');
  $r->post ('/applications/:id/reject')->to ('Application#application_reject');
  $r->get ('/applications/:id/remove')->to ('Application#application_remove');

  $r->get ('/changes')->to (cb => \&about);

  $r->get ('/user/theme')->to ('User#theme');
  $r->post ('/user/theme')->to ('User#theme_save');


  # Admin bridge
  my $admin_bridge = $r->bridge ('/admin')->to (cb => \&admin_bridge_callback);

  $admin_bridge->get ('/')->to ('Admin#home');

  $admin_bridge->get ('/assign')->to ('Admin#assign');
  $admin_bridge->get ('/assign/list')->to ('Admin#assign_unassigned_list');
  $admin_bridge->get ('/assign/:account')->to ('Admin#assign_account');
  $admin_bridge->post ('/assign/:account')->to ('Admin#assign_account_post');

  $admin_bridge->get ('/pages')->to ('Pages#admin_list');
  $admin_bridge->get ('/pages/add')->to ('Pages#add');
  $admin_bridge->post ('/pages/add')->to ('Pages#add_post');
  $admin_bridge->get ('/pages/edit/:slug')->to ('Pages#edit');
  $admin_bridge->post ('/pages/edit/:slug')->to ('Pages#edit_post');
  $admin_bridge->get ('/pages/remove/:slug')->to ('Pages#remove');

  $admin_bridge->get ('/news')->to ('News#admin_list');
  $admin_bridge->get ('/news/add')->to('News#add');
  $admin_bridge->post ('/news/add')->to('News#add_post');
  $admin_bridge->get ('/news/edit/:id')->to ('News#edit');
  $admin_bridge->post ('/news/edit/:id')->to ('News#edit_post');
  $admin_bridge->get ('/news/remove/:id')->to ('News#remove');

  $admin_bridge->get ('/options/:option')->to ('Admin#edit_option');
  $admin_bridge->post ('/options/:option')->to ('Admin#edit_option_post');

  # End lottery
  $admin_bridge->post ('/lottery/give')->to('Admin#lottery_give');
  $admin_bridge->post ('/lottery/end')->to ('Admin#lottery_winner');

  $admin_bridge->get ('/recruitment')->to ('Admin#recruitment');

  # Pages
  $r->get ('/:slug')->to ('Pages#page');
}


1;
