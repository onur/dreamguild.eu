
package DreamGuild::WWW::Application;
use Mojo::Base 'Mojolicious::Controller';

use DreamGuild::Helpers::Application;
use DreamGuild::DB;
use DreamGuild::Utils::Progress;
use JSON::XS;


# FIXME: there is tons of code repeat in this module
# need to fix permission checks etc.


sub apply {
  my $self = shift;

  if ($self->stash ('user')) {
    return $self->render (template => 'application/apply',
                          error    => 'Please logout to send an application');
  }

  delete $self->session->{app_id} if defined ($self->session ('app_id'));
  delete $self->session->{main_id} if defined ($self->session ('main_id'));

  $self->render;
}


sub apply_post {
  my $self = shift;

  if ($self->stash ('user')) {
    return $self->render (template => 'application/apply',
                          error    => 'Please logout to send an application');
  }

  my $character = $self->param ('character');

  if (!$character) {
    return $self->render (template => 'application/apply',
                          error    => 'Please enter a character name');
  }


  my $app = DreamGuild::Helpers::Application->new ($character);
  my $app_status = $app->check;

  # $app_status
  # 0: dont exist in Grim Batol
  # 1: exist in roster
  # 2: app exist in applications
  # 3: new app created

  if ($app_status == 0) {
    return $self->render (template => 'application/apply',
                          error    => 'This character don\'t exist in ' .
                                      'Grim Batol EU');
  }
  
  elsif ($app_status == 1) {
    if ($app->{uid}) {
      return $self->render (template => 'application/apply',
                            error    => 'You can\'t apply as ' . $character);
    }
    $self->session ('main_id' => $app->{main_id});
    return $self->redirect_to ('/register');
  }

  elsif ($app_status == 2) {
    # FIXME: show login
    return $self->render (template => 'application/apply',
                          error    => 'This application is in progress. ' .
                                      'Please log in to see application ' .
                                      'details');
  }

  elsif ($app_status == 3) {
    $self->session ('app_id' => $app->{app_id});
    return $self->redirect_to ('register');
  }

  else {
    return $self->render (template => 'application/apply',
                          error    => 'Unknown error. ' .
                                      'Please contact web master.');
  }


  return $self->render (template => "application/apply");
}



sub application {
  my $self = shift;

  my $user = $self->stash ('user');
  my $app = shift || DreamGuild::DB::Application->select ('where app_id = ?', $self->param ('id'));

  return $self->render (template => 'error',
                        error    => 'Application does not exist!')
    if (!scalar (@{$app}));


  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to see this page. Try to log in.')
    # TODO: check this
    if (!defined ($user) ||
        ($user->level < 5 &&
         $user->id != $app->[0]->uid));

  return $self->application_questions ($app)
    if (!$app->[0]->questions);


  my $comments = DreamGuild::DB::ApplicationComments->select ('where appid = ?', $app->[0]->{id});
  for (@{$comments}) {
    my $sth = DreamGuild::DB->dbh->prepare ('SELECT name, class, thumbnail FROM roster INNER JOIN user ON roster.id = user.main WHERE user.id = ?');
    $sth->execute ($_->{uid});
    $_->{main} = $sth->fetchrow_hashref;

    if (!defined ($_->{main})) {
      $_->{main} = {
        class => $app->[0]->{class},
        name  => $app->[0]->{name},
        thumbnail => $app->[0]->{thumbnail}
      };
    }
  }

  $app->[0]->{talents}   = decode_json ($app->[0]->{talents});
  $app->[0]->{items}     = decode_json ($app->[0]->{items});
  $app->[0]->{questions} = decode_json ($app->[0]->{questions});
  $app->[0]->{progress}  = decode_json ($app->[0]->{progress});

  return $self->render (template    => 'application/details',
                        application => $app->[0],
                        comments    => $comments);

}



sub application_questions {

  my ($self, $app) = @_;

  $app->[0]->{progress} = decode_json ($app->[0]->{progress});
  $app->[0]->{talents}  = decode_json ($app->[0]->{talents});
  $app->[0]->{items}    = decode_json ($app->[0]->{items});

  return $self->render (template  => 'application/questions',
                        questions => decode_json (DreamGuild::DB->get_option ('questions')),
                        questions_description => DreamGuild::DB->get_option ('questions-description'),
                        application => $app->[0]);
}


sub application_questions_post {

  my $self = shift;
  my $app = DreamGuild::DB::Application->select ('where app_id = ?', $self->param ('id'));

  return $self->render (template => 'error',
                        error    => 'Application does not exist!')
    if (!scalar (@{$app}));

  return $self->render (template => 'error',
                        error    => 'Only owner can answer questions')
    if (!defined $self->session ('uid') ||
        $app->[0]->uid != $self->session ('uid'));

  my $questions = decode_json (DreamGuild::DB->get_option ('questions'));


  my $c = 0;

  for (@{$questions}) {
    for (@{$_->{questions}}) {
      $_->{answer} = $self->param ('ApplyQuestion' . $c) || undef;
      ++$c;
    }
  }

  $app->[0]->update (
    status => 1,
    questions => encode_json ($questions)
  );

  return $self->application ($app);

}



sub application_add_comment {
  my $self = shift;

  my $app = DreamGuild::DB::Application->select ('where app_id = ?', $self->param ('id'));
  my $user = $self->stash ('user');

  return $self->render (template => 'error',
                        error    => 'Application does not exist!')
    if (!scalar (@{$app}));

  return $self->render (template => 'error',
                        error    => 'You don\'t have permission to add comments')
    if (!defined ($user) ||
        ($user->level < 5 &&
         $user->id != $app->[0]->uid));

  return $self->render (template => 'error',
                        error    => 'Please enter a comment')
    if (!$self->param ('comment'));


  DreamGuild::DB::ApplicationComments->new (
    uid      => $user->{id},
    appid    => $app->[0]->{id},
    comment  => $self->param ('comment'),
    time     => time ()
  )->insert;

  return $self->redirect_to ('/application/' . $app->[0]->{app_id});
}


sub application_vote {
  my $self = shift;

  my $vote = $self->stash ('vote');
  my $user = $self->stash ('user');
  my $app = DreamGuild::DB::Application->select ('where app_id = ?', $self->param ('id'));

  $vote = ($vote eq 'yes' ? 1 : 0);

  return $self->render (json => { error => 'Application does not exist!' })
    if (!scalar (@{$app}));

  return $self->render (json => { error => 'You don\'t have permission to vote' })
    if (!defined ($user) ||
        ($user->level < 5));

  my $row = DreamGuild::DB::ApplicationVotes->select ('where uid = ? and appid = ?',
                                                       $user->{id},
                                                       $app->[0]->{id});
  # if user already voted this app
  if (scalar (@{$row})) {
    if ($row->[0]->{vote} != $vote) {
      $row->[0]->update (
        vote => $vote,
        time => time ()
      );
    }
  } else {

    DreamGuild::DB::ApplicationVotes->new (
      uid => $user->{id},
      appid => $app->[0]->{id},
      vote  => $vote,
      points => 0,
      time => time ()
    )->insert;

  }

  return $self->render (json => { ok => 1 });
}




sub list {
  my $self = shift;

  my $user = $self->stash ('user');
  my $status = $self->stash ('app_status');

  $status = ((defined ($status) and $status eq 'closed') ? 2 : 1);

  my $applications = DreamGuild::DB::Application->select ('where status = ?',
                                                          $status);
  for (@{$applications}) {
    $_->{progress} = decode_json ($_->{progress});
    $_->{talents}  = decode_json ($_->{talents});
    $_->{items}    = decode_json ($_->{items});
  }

  $self->render (applications => $applications);
}


1;
