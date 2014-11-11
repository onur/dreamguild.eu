
package DreamGuild::Utils::Maintenance;

use DreamGuild::DB;


sub new {
  my $class = shift;
  bless {}, $class;
}


sub weekly {
  DreamGuild::DB->clear_accounts;
}


1;
