#!/usr/bin/env perl

use Mojolicious::Lite;
use experimental 'signatures';

use Net::EmptyPort qw( empty_port );
use Browser::Open qw( open_browser );
use lib 'lib';
#use WWW::PODViewer;

##########################################################

my $filename = shift;

my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $filename or die "$filename: $!";

my $data = {};
my $titles = $csv->getline($fh);
my $xlabel = shift @{ $titles };
$data->{labels} = [];
$data->{datasets} = [
    map { +{ label => $_, data => [] } } @{ $titles }
];

while (my $row = $csv->getline($fh)) {
    push @{ $data->{labels} }, shift @{ $row };
    push @{ $data->{datasets}[ $_ ]{data} }, $row->[ $_ ]
        for 0..(scalar(@{ $row })-1);
}

close $fh or die "$filename: $!";

##########################################################

get '/' => sub ($c, @) {
    $c->render(
        'index',
        title  => $filename =~ s/[.]csv$//r,
        xlabel => $xlabel,
        cols   => $data,
    );
};
post '/exit' => sub { exit };

app->log->level('warn');

my $base_url = 'http://127.0.0.1:' . empty_port();
my $loop = Mojo::IOLoop->singleton;
 $loop->timer(0 => sub {
#    $server->silent(1);
    open_browser($base_url);
});
app->start('daemon','--listen', $base_url );

__DATA__
@@ index.html.ep
% # This pages includes output directly in the  <script>...</script>
% # tags.  Note that this is only safe because:
%
% #   (a) I'm using to_json which outputs characters not bytes so
% #       when Mojolicious does the final byte encoding everything will
% #        work out and not be double encoded, and
%
% #   (b) Mojo::JSON (unlike many other JSON libraries) *also* escapes
% #       any '/' as '\/' meaning that a rogue '</script>' in the data
% #       won't terminate the script tags and present a possible
% #       JavaScript injection attack
%
% use Mojo::JSON qw( to_json );
<html>
<script>
// when the page is closed have the browser send a POST
// to /exit to tell Mojolicious to shut down
window.addEventListener(
    "unload",
    () => navigator.sendBeacon("/exit"),
    false
);
</script>
<script src="https://cdn.jsdelivr.net/npm/chart.xkcd@1.1/dist/chart.xkcd.min.js"></script>
<body>
    <svg class="chart"></svg>
    <script>
        const chartElement = document.querySelector('.chart');
        const lineChart = new chartXkcd.Line(
            chartElement,
            {
                title: <%== to_json( $title ) %>,
                xLabel: <%== to_json( $xlabel ) %>,
                data: <%== to_json( $cols ) %>,
                options: {
                    legendPosition: chartXkcd.config.positionType.upLeft
                }
            }
        );
    </script>
</body>
</html>
