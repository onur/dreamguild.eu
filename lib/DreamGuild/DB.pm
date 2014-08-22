
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


1;
