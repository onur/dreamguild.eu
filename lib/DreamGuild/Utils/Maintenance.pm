
package DreamGuild::Utils::Maintenance;

use strict;
use warnings;
use DreamGuild::DB;
use DreamGuild::Utils::Progress;


sub new {
  my $class = shift;
  bless {}, $class;
}


sub weekly {
  DreamGuild::DB->clear_accounts;

  # Update progress
  my $progress = DreamGuild::Utils::Progress->new;
  my $progress_data = $progress->get_total_progress;
  $progress->save_total_progress ($progress_data);
}


1;
