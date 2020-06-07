use Test::More;
use Test::Mojo;
use Mojo::File qw/curfile path/;
use lib 'lib';
my $lib;
BEGIN {
   my $gitdir = Mojo::File->curfile;
   my @cats = @$gitdir;
   while (my $cd = pop @cats) {
       if ($cd eq 'git') {
           $gitdir = path(@cats,'git');
           last;
       }
   }

   $lib =  $gitdir->child('utilities-perl','lib')->to_string; #return utilities-perl/lib
};


use lib $lib;
use SH::UseLib;

$ENV{NO_SECURITY}=1;
$ENV{COMMON_CONFIG_DIR}='t/etc';

my $t = Test::Mojo->new(curfile->dirname->sibling('script')->child('web-pod-viewer.pl'));
my $path = '/podviewer';
$t->get_ok($path.'/')->status_is(200)->content_like(qr'ScriptX');
$t->get_ok($path.'/perldoc/Test::ScriptX')->status_is(200)->content_like(qr'ScriptX');

done_testing;