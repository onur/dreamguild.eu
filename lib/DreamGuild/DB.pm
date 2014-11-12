
package DreamGuild::DB;

use strict;
use warnings;

use ORLite {
  file    => 'share/data/database.db',
  unicode => 1
};



sub get_option {
  my ($self, $option) = @_;

  my $option_row = DreamGuild::DB::Options->select ('where option = ?', $option);
  return unless (scalar (@{$option_row}));

  return $option_row->[0]->{value};
}


sub save_option {
  my ($self, $option, $value) = @_;

  return if !defined ($option) || !defined ($value);

  my $option_row = DreamGuild::DB::Options->select ('where option = ?', $option);
  if (scalar (@{$option_row})) {
    $option_row->[0]->update (
      value => $value
    );
  } else {
    DreamGuild::DB::Options->new (
      option => $option,
      value  => $value
    )->insert;
  }

}


# This function will clear users who has registered but
# not submitted any application or declined
sub clear_accounts {

  DreamGuild::DB->begin;

  DreamGuild::DB->iterate (
    'SELECT user.id FROM application, user ' .
    'WHERE application.uid = user.id AND application.status != 2 ' .
        'AND user.last_active < ? AND application.update_time < ?',
    time () - 604800,
    time () - 604800,
    sub {
      DreamGuild::DB::User->delete_where ('id = ?', $_->[0]);
      return 1;
    }
  );

  DreamGuild::DB->commit;

}


sub log {
  my ($self, $type, $uid, $message) = @_;
  DreamGuild::DB::Log->new (
    type    => $type,
    uid     => $uid || 0,
    message => $message || '',
    time    => time ()
  )->insert;
}

1;
