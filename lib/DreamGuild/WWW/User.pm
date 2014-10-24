
package DreamGuild::WWW::User;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::DB;
use Digest::SHA qw/sha1_hex/;


sub register {
  my $self = shift;
  

  if (!defined ($self->session ('app_id')) &&
      !defined ($self->session ('main_id'))) {
    return $self->redirect_to ('apply');
  }

  $self->render;
}


sub sha1_passwd {
  my ($self, $passwd) = @_;
  return sha1_hex ($passwd . $self->config ('secrets')->[1]);
}


sub register_post {
  my $self = shift;

  my $email    = $self->param ('email');
  my $password = $self->param ('password');
  my $password_confirm = $self->param ('password-confirm');


  if (!defined ($self->session ('app_id')) &&
      !defined ($self->session ('main_id'))) {
    return $self->redirect_to ('apply');
  }


  my $error = '';

  if (!$email || !$password || !$password_confirm) {
    return $self->render (template => 'user/register',
                          error    => 'Please fill all required fields');
  }

  # Check password match
  if ($password ne $password_confirm) {
    return $self->render (template => 'user/register',
                          error    => 'Passwords don\'t match');
  }


  $email =~ tr/[A-Z]/[a-z]/;

  # Check if this email already registered
  if (DreamGuild::DB::User->count ('where email = ?', $email)) {
    return $self->render (template => 'user/register',
                          error    => 'This e-mail address is already used. ' .
                                      'Try to log in if you are owner of '.
                                      ' this account or use different mail address');
  }

  my $user_row = DreamGuild::DB::User->new (
    email    => $email,
    password => $self->sha1_passwd ($password),
    level    => (defined ($self->session ('main_id')) ? 5 : 0),
    main     => 0,
    appid    => $self->session ('app_id') || 0,
    dkp      => 0,
    main     => $self->session ('main_id') || 0,
    join_time => time (),
    last_active => time ()
  )->insert;

  $self->session (uid => $user_row->id);


  # If user is applying redirect to application page
  if (my $app_id = $self->session ('app_id')) {
    my $row = DreamGuild::DB::Application->select ('where id = ?', $app_id);

    if ($row->[0]->{status} == 0 && $row->[0]->{uid} == 0) {
      $row->[0]->update (uid => $user_row->id);
      return $self->redirect_to ('applications/' . $row->[0]->{app_id});
    }
  } elsif (my $main_id = $self->session ('main_id')) {
    my $char = DreamGuild::DB::Roster->load ($main_id);
    $char->update (uid => $user_row->id, is_main => 1);
  }

  delete $self->session->{app_id} if defined ($self->session ('app_id'));
  delete $self->session->{main_id} if defined ($self->session ('main_id'));

  $self->redirect_to ('/');
}


sub login {
  my $self = shift;
  $self->render ();
}


sub login_post {
  my $self = shift;

  my $email    = $self->param ('email');
  my $password = $self->param ('password');


  return $self->render (template => 'user/login',
                        error => 'Please enter all required fields')

    if (!$email || !$password);

  # FIXME: need to check case insensitive email
  my $row = DreamGuild::DB::User->select ('where email = ? and password = ?',
                                          $email,
                                          $self->sha1_passwd ($password));


  unless (scalar (@{$row})) {
    return $self->render (template => 'user/login',
                          error => 'Invalid email address or password')
  }


  $self->session ('uid', $row->[0]->{id});

  $self->session (expiration => 7776000)
    if (defined $self->param ('remember-me'));


  # Check if user have a application
  # And if there's one redirect to application page
  $row = DreamGuild::DB::Application->select ('where uid = ? and status < 2',
                                              $row->[0]->{id});
  return $self->redirect_to ('/applications/' . $row->[0]->{app_id})
    if (scalar (@{$row}));



  # If everything goes well redirect to index
  $self->redirect_to ('/');
}


sub logout {
  my $self = shift;
  delete $self->session->{uid};
  $self->redirect_to ('/');
}


sub theme {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page')
    if (!defined ($user));

  $self->render;
}


sub theme_save {
  my $self = shift;
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page')
    if (!defined ($user));

  return $self->render (template => 'error',
                        error    => 'Invalid theme')
    if ($self->param ('theme') !~ /^\d+$/);


  DreamGuild::DB->do (
    'UPDATE user SET theme = ? WHERE id = ?',
    {},
    $self->param ('theme'),
    $user->{id}
  );

  $self->redirect_to ('/');
}


1;
