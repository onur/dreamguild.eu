
package DreamGuild::Utils::Roster;

use strict;
use warnings;
use JSON::XS;
use Data::Dumper;
use DreamGuild::DB;
use File::Path qw/make_path/;
use LWP::UserAgent;



sub new {
  my $class = shift;
  bless {}, $class;
}


sub get {

  my $url = shift;
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get ($url);

  sleep 1;

  if ($response->is_success) {
    return $response->decoded_content;
  } else {
    return undef;
  }

}


sub get_player_list {
  my $self = shift;
  my $raw_content = get ('http://eu.battle.net/api/wow/guild/grim-batol/Dream?fields=members')
                        or die ('Unable to get member list');
  my $guild = decode_json ($raw_content);
  $self->{members} = $guild->{members};
  $self->get_player_details;
}


sub get_player_details {
  my $self = shift;
  for (@{$self->{members}}) {
    next if $_->{character}->{level} < 10;
    my $raw_content = get ('http://eu.battle.net/api/wow/character/Grim-Batol/' . $_->{character}->{name} . '?fields=items,progression,talents') or next;
    $_->{character}->{details} = decode_json ($raw_content);
  }
}



sub get_user_ids {
  my $self = shift;
  $self->{user_ids} = {};
  DreamGuild::DB::Roster->iterate (sub {
    $self->{user_ids}->{$_->name} = $_->id;
  });
}



sub download_avatar {

  my ($self, $avatar) = @_;

  my ($dir, $file) = $avatar =~ /^(.*)\/(.*?)$/;
  make_path ('share/data/avatars/' . $dir);

  my $ua = LWP::UserAgent->new;
  $ua->get ('https://eu.battle.net/static-render/eu/' . $avatar,
            ':content_file' => 'share/data/avatars/' . $avatar);
  
  # FIXME: code repeat
  # Get profile picture
  $avatar =~ s/avatar/profilemain/;
  $ua->get ('https://eu.battle.net/static-render/eu/' . $avatar,
            ':content_file' => 'share/data/avatars/' . $avatar);

}


sub update_roster {
  my $self = shift;

  $self->{last_update} = time ();

  $self->get_user_ids;
  $self->get_player_list unless defined $self->{members};

  DreamGuild::DB->begin;

  for (@{$self->{members}}) {

    my $uid = defined ($self->{user_ids}->{$_->{character}->{name}}) ? 
                  $self->{user_ids}->{$_->{character}->{name}} : 0;

    my %user = (

      name          => $_->{character}->{name},
      class         => $_->{character}->{class},
      race          => $_->{character}->{race},
      level         => $_->{character}->{level},
      ailvl         => $_->{character}->{details}->{items}->{averageItemLevel} || 0,
      # FIXME: 80+
      eilvl         => $_->{character}->{details}->{items}->{averageItemLevelEquipped} || 0,
      rank          => $_->{rank},
      thumbnail     => $_->{character}->{thumbnail},
      spec          => $_->{character}->{spec}->{name},
      role          => $_->{character}->{spec}->{order},
      talents       => (defined $_->{character}->{details}->{talents} ?
                            encode_json ($_->{character}->{details}->{talents})
                                : undef),
      items         => (defined $_->{character}->{details}->{items} ?
                            encode_json ($_->{character}->{details}->{items})
                                : undef),
      # FIXME: 80+
      progress      => (defined $_->{character}->{details}->{progression} ?
                            encode_json ($_->{character}->{details}->{progression}) : undef),
      achievement_points  => $_->{character}->{details}->{achievementPoints} || 0,
      last_update   => $self->{last_update},

      uid           => 0,
      is_main       => 0,

      # FIXME: everyones realm is grim-batol
      realm         => 'grim-batol'

    );

    if ($uid) {
      my $row = DreamGuild::DB::Roster->load ($uid);
      delete ($user{uid});
      delete ($user{is_main});
      $row->update (%user);
    } else {
      my $row = DreamGuild::DB::Roster->new (%user)->insert;
      $uid = $row->id;
    }

    $self->download_avatar ($_->{character}->{thumbnail});

    # Add history
    DreamGuild::DB->do ('INSERT OR IGNORE INTO lvl_history VALUES (?, ?, ?)', {}, $uid, $_->{character}->{level}, time ());
    DreamGuild::DB->do ('INSERT OR IGNORE INTO ilvl_history VALUES (?, ?, ?)', {}, $uid, $_->{character}->{details}->{items}->{averageItemLevel}, time ());
    DreamGuild::DB->do ('INSERT OR IGNORE INTO achievements_point_history VALUES (?, ?, ?)', {}, $uid, $_->{character}->{details}->{achievementPoints}, time ());

  }

  # remove removed heroes !?
  # FIXME: need to find a better solution
  #DreamGuild::DB::Roster->delete_where ('last_update < ?', $self->{last_update});

  DreamGuild::DB->log (1000);

  DreamGuild::DB->commit;
}




1;
