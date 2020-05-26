package WWW::PODViewer;

use Data::Dumper;
use Mojo::Base 'Mojolicious';
use Mojo::File 'path';
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
use Model::GetCommonConfig;

=head1 NAME

web-pod-viewer;

=head1 DESCRIPTION

Mojolicious app that servers perldocs from parrent tree.

=head2 Testing

COMMON_CONFIG_DIR=t/etc morbo script/web-pod-viewer.pl

=cut

my %packages;
my $curfile = Mojo::File->curfile;
my @x = @$curfile;
1 while ('lib' ne pop @x);
pop @x; #remove reponame
my $main = Mojo::File->new(@x);
my @ps;

# search for all packages
#say join(',', @packages);

sub startup {
	my $self = shift;
	my $config =  $self->config;
	$self->mode('development');
    $self->config(Model::GetCommonConfig->new->get_mojoapp_config($0));
    my $r = $self->routes->under($self->config->{hypnotoad}->{service_path});
    # Add another class with templates in DATA section
    push @{$self->renderer->classes}, __PACKAGE__;
    # other class with static files in DATA section
    push @{$self->static->classes}, __PACKAGE__;
    $self->plugin(PODViewer => {
        default_module => 'Test::ScriptX',
        allow_modules => \@ps,
        layout => 'default',
        route =>$r->any('/perldoc')
    });
    $r->get('/' => sub {
        my $c = shift;$c->stash(packages=>\%packages); $c->render('list')
    });
    Mojo::IOLoop->timer(0 => sub {
        for my $pm($main->list_tree->each) {
            next if "$pm" !~/(bin|lib|script)/;
            next if $pm->basename !~ /\.p[ml]$/ && $pm->basename =~ /\./;
            my $fh =$pm->open('<');
            while (my $line = <$fh> ) {

                if ($line =~ /^(?:package|use|require)\s+([\w\:]+)/) {
                    next if grep  {$1 eq $_} ('lib','v5','strict','warnings','open');
                    last if $line  eq '__DATA__' || $line  eq '__END__';
                    $packages{$1}++;
                }
            }
        }
        @ps = keys %packages; # register local Packages
        for my $i(reverse 0..$#ps) {
            my $keep = 0;
            my @dirs = split(/\:\:/, $ps[$i]);
            for my $dir($main->list({dir => 1})->each ) {
                my $name = $dir->child('lib',@dirs)->to_string.'.pm';
                if( -e $name) {
                    $keep = 1;
                }
            }
            if ($keep == 0) {
                delete $ps[$i];
            }
        }
    });
}
1;



__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="/yancy/bootstrap.css">
        <style>
            h1 { font-size: 1.65rem }
            h2 { font-size: 1.45rem }
            h3 { font-size: 1.25rem }
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
  % for my $pm (sort{$packages->{$b}<=>$packages->{$a}} keys %$packages) {
  <tr>
    <td>
    %= link_to $pm, url_for((config->{hypnotoad}->{service_path} ? '/'.config->{hypnotoad}->{service_path}:'')."/perldoc/$pm")->to_abs->to_string;
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

// when the page is closed have the browser send a POST
// to /exit to tell Mojolicious to shut down
// window.addEventListener(
//    "unload",
//    () => navigator.sendBeacon("/exit"),
//    false
// );

</script>

</body>
</html>
