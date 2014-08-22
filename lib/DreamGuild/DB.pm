
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

  return if !$option || !$value;

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


1;
