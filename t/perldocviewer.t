use Test::More;
use Test::Mojo;
use Mojo::File 'curfile';
$ENV{COMMON_CONFIG_DIR}='t/etc';
my $t = Test::Mojo->new(curfile->dirname->sibling('script')->child('web-pod-viewer.pl'));
$t->get_ok('/')->status_is(200);
$t->get_ok('/perldoc/Test::ScriptX')->status_is(200);

done_testing;