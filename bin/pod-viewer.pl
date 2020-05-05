package Cat;

use Mojo::File 'path';
use Mojo::Base 'Mojolicious';

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

my @packages;
my $curfile = Mojo::File->curfile;
my @x = @$curfile; 
pop @x; #remove filname
pop @x; #remove bin
pop @x; #remove reponame
my $main = Mojo::File->new(@x);
say "m $main";
for my $pm($main->list_tree->each) {
    say "x $pm";
    next if "$pm" !~/lib/;
    next if $pm->basename !=/\.pm$/;
    say "$pm";
    my $fh =$pm->open('<');
    while (my $line = <$fh> ) {
        
        if ($line =~ /^package\s+([\w\:]+)/) {
            push @packages, $1;
        }
    }
}

# search for all packages
say join(',', @packages);

sub startup {
	my $self = shift;
	my $config =  $self->config;

    $self->plugin(PODViewer => {
        default_module => 'Test::ScriptX',
        allow_modules => \@packages, #[qw( Yancy Mojolicious::Plugin::Yancy Test::ScriptX )]
        layout => 'default',
    });
    my $r = $self->routes;
    $r->get('/' => sub {my $c = shift;$c->stash(packages=>\@packages); $c->render('list')});
}
1;

package main;
#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use Mojolicious::Commands;

# Start command line interface for application
Mojolicious::Commands->start_app('Cat');


__DATA__
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="/yancy/bootstrap.css">
        <style>
            h1 { font-size: 2.00rem }
            h2 { font-size: 1.75rem }
            h3 { font-size: 1.50rem }
            h1, h2, h3 {
                position: relative;
            }
            h1 .permalink, h2 .permalink, h3 .permalink {
                position: absolute;
                top: auto;
                left: -0.7em;
                color: #ddd;
            }
            h1:hover .permalink, h2:hover .permalink, h3:hover .permalink {
                color: #212529;
            }
            pre {
                border: 1px solid #ccc;
                border-radius: 5px;
                background: #f6f6f6;
                padding: 0.6em;
            }
            .crumbs .more {
                font-size: small;
            }
        </style>
        <title><%= title %></title>
    </head>
    <body>
        %= content
    </body>
</html>

@@list.html.ep
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
* {
  box-sizing: border-box;
}

#myInput {
  background-image: url('/css/searchicon.png');
  background-position: 10px 10px;
  background-repeat: no-repeat;
  width: 100%;
  font-size: 16px;
  padding: 12px 20px 12px 40px;
  border: 1px solid #ddd;
  margin-bottom: 12px;
}

#myTable {
  border-collapse: collapse;
  width: 100%;
  border: 1px solid #ddd;
  font-size: 18px;
}

#myTable th, #myTable td {
  text-align: left;
  padding: 12px;
}

#myTable tr {
  border-bottom: 1px solid #ddd;
}

#myTable tr.header, #myTable tr:hover {
  background-color: #f1f1f1;
}
</style>
</head>
<body>

<h2>My perlmodules</h2>

<input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for names.." title="Type in a name">

<table id="myTable">
  <tr class="header">
    <th style="width:60%;">Name</th>
  </tr>
  % for my $pm (@$packages) {
  <tr>
    <td>
    %= link_to $pm, "/perldoc/$pm";
    </td>
  </tr>
  % }
</table>

<script>
function myFunction() {
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
  tr = table.getElementsByTagName("tr");
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    if (td) {
      txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }       
  }
}
</script>

</body>
</html>
