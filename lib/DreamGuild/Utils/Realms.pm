
package DreamGuild::Utils::Realms;

use LWP::Simple;
use JSON::XS;
use DreamGuild::DB;
use Data::Dumper;


sub update_realm_list () {
  my $realms_raw = decode_json (get ('http://eu.battle.net/api/wow/realm/status')) || return undef;

  my $realms = [];

  for (@{$realms_raw->{realms}}) {
    push @{$realms}, [ $_->{name}, $_->{slug} ];
  }

  DreamGuild::DB->save_option ('realm-list', encode_json ($realms));
}


1;
