
package DreamGuild::DB;

use strict;
use warnings;

use ORLite {
  file    => 'share/data/database.db',
  unicode => 1
};

my $options = {};


sub load_options {

  DreamGuild::DB::Options->iterate (sub {
    $options->{$_->option} = $_->{value};
  });

}


sub get_option {
  my ($self, $option) = @_;
  return $options->{$option} if (defined $options->{$option});
  return undef;
}

load_options ();

1;
