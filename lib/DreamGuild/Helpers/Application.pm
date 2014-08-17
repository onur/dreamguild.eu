
package DreamGuild::Helpers::Application;

use strict;
use warnings;
use DreamGuild::DB;
use DreamGuild::Utils::Progress;
use LWP::UserAgent;
use Digest::SHA qw/sha1_hex/;
use JSON::XS;
use File::Path qw/make_path/;


sub new {
  my ($class, $name) = @_;
  bless { name => $name }, $class;
}


sub check {
  my $self = shift;

  # Check this user is exist in roster
  return 1 if $self->check_roster;;
  return 2 if $self->check_existing_application;
  return 0 if !$self->check_battlenet;
  return 3 if $self->create_app;
  return -1;
}


sub check_roster {
  my $self = shift;
  my $row = DreamGuild::DB::Roster->select ('where name = ? COLLATE NOCASE', $self->{name});
  if (scalar (@{$row})) {
    $self->{main_id} = $row->[0]->{id};
    $self->{uid} = $row->[0]->{uid};
    return 1;
  }

  return 0;
}


sub check_battlenet {
  my $self = shift;
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get ('http://eu.battle.net/api/wow/character/Grim-Batol/'
                           . $self->{name} . '?fields=items,progression,talents');
                       
  return 0 unless $response->is_success;

  $self->{json_content} = decode_json ($response->decoded_content);

  return 1;
}


sub check_existing_application {
  my $self = shift;
  my @row = DreamGuild::DB::Application->
        select ('where name = ? and status < 2 COLLATE NOCASE', $self->{name});
  if (scalar (@row)) {
    $self->{app_id_hex} = $row[0]->app_id;
    return 1;
  }
  return 0;
}



sub generate_id {
  my $self = shift;
  my @numbers;
  push (@numbers, int (rand (10000000))) for (0..100);
  my $hex = sha1_hex (join ('', @numbers) . '3c7a4779b7a08b');
  # TODO: need to check existing id
  $self->{app_id_hex} = substr ($hex, 0, 8);
  $self->{app_id_hex} =~ tr/[a-z]/[A-Z]/;
}


sub download_avatar {

  my ($self, $avatar) = @_;

  my ($dir, $file) = $avatar =~ /^(.*)\/(.*?)$/;
  make_path ('share/data/avatars/' . $dir);

  my $ua = LWP::UserAgent->new;
  $ua->get ('https://eu.battle.net/static-render/eu/' . $avatar,
            ':content_file' => 'share/data/avatars/' . $avatar);

}


sub create_app {
  my $self = shift;

  $self->generate_id;

  return 0 unless $self->{json_content};

  $_ = $self->{json_content};

  my $progress = DreamGuild::Utils::Progress->new;

  my $row = DreamGuild::DB::Application->new (
    app_id        => $self->{app_id_hex},
    name          => $_->{name},
    class         => $_->{class},
    race          => $_->{race},
    level         => $_->{level},
    ailvl         => $_->{items}->{averageItemLevel} || 0,
    eilvl         => $_->{items}->{averageItemLevelEquipped} || 0,
    thumbnail     => $_->{thumbnail},
    talents       => (defined $_->{talents} ?
                          encode_json ($_->{talents}) : undef),
    items         => (defined $_->{items} ?
                          encode_json ($_->{items}) : undef),
    # TODO: need to use some progress to str helper
    progress      => (defined $_->{progression} ?
                          # TODO: need to get raid names from database
                          encode_json ($progress->get_progress ($_->{progression}, 'Siege of Orgrimmar')) : undef),
    achievement_points  => $_->{achievementPoints} || 0,
    time          => time (),
    update_time   => time (),

    # user id
    uid           => 0,

    # defaults
    status        => 0,
    yes           => 0,
    no            => 0,
    points        => 0
  )->insert;

  $self->{app_id} = $row->id;

  $self->download_avatar ($_->{thumbnail});

  return 1;
}


1;
