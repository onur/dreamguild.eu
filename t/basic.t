use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('DreamGuild::WWW');
$t->get_ok('/')->status_is(200)->content_like(qr/Dream/i);

done_testing();
