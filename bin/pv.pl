#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::File 'path';
use feature 'signatures';
use Net::EmptyPort qw( empty_port );
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


use WWW::PODViewer;
#use Browser::Open qw( open_browser );


my $base_url = 'http://127.0.0.1:' . empty_port();
my $app = WWW::PODViewer->new;

$app->hook(before_server_start => sub ($server, @) {
# sometimes does not work   $server->silent(1);
 });

$app->hook(before_dispatch => sub ($c, @) {
    $c->req->url->base(Mojo::URL->new($base_url.'/'));
});
my $loop = Mojo::IOLoop->singleton;
$loop->timer(0 => sub($server,@) {
    # $server->silent(1);
#    require Browser::Open;
#    Browser::Open::open_browser($base_url);
    my $out = "firefox $base_url &";
    print $out;
    print `$out`;
});
$app->start('daemon','--listen', $base_url );
