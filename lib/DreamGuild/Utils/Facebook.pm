
package DreamGuild::Utils::Facebook;

use strict;
use warnings;
use DreamGuild::DB;
use DreamGuild::WWW;
use LWP::UserAgent;


sub new {
  my $class = shift;
 
  my %args = @_;
  my $self = {};

  $self->{name}        = $args{name}        || '';
  $self->{message}     = $args{message}     || '';
  $self->{description} = $args{description} || '';

  # Try to get access token from database
  $self->{access_token} = DreamGuild::DB->get_option ('facebook_access_token');

  my $dream = DreamGuild::WWW->new;
  $self->{access_token} = $dream->config ('facebook_access_token')
                              if (!$self->{access_token});

  $self->{group_id}   = $dream->config ('facebook_group_id');
  $self->{app_id}     = $dream->config ('facebook_app_id');
  $self->{app_secret} = $dream->config ('facebook_app_secret');

  # If its still not exist then die
  $self->{access_token} || die ('Access token is not available');

  bless $self, $class;
}


sub post {
  my $self = shift;

  return undef if (!$self->{access_token} || !$self->{group_id} ||
                   !$self->{message} || !$self->{app_id} ||
                   !$self->{access_token});

  $self->update_access_token;

  my $ua = LWP::UserAgent->new;
  my $url = 'https://graph.facebook.com/v2.2/' . $self->{group_id} . '/feed';

  $ua->post ($url, { access_token => $self->{access_token},
                     message      => $self->{message} });

}


sub update_access_token {
  my $self = shift;

  my $ua = LWP::UserAgent->new;
  my $url = 'https://graph.facebook.com/oauth/access_token?client_id=' .
            $self->{app_id} . '&client_secret=' . $self->{app_secret} .
            '&grant_type=fb_exchange_token&fb_exchange_token=' .
            $self->{access_token};
  my $response = $ua->get ($url);

  my ($access_token) = $response->decoded_content =~ /access_token=(\w+)&/;
  $self->{access_token} = $access_token;

  DreamGuild::DB->save_option ('facebook_access_token', $access_token);
}



1;
