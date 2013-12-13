#! /usr/bin/perl

use strict;
use warnings;
use JSON qw(from_json to_json);

while (my $line = <STDIN>) {
    chomp $line;
    my $rows = from_json($line);
    for my $row (@$rows) {
        next unless $row->{Info};
        $row->{Info} =~ s/(?<=\W)-?(?:0x[0-9a-f]+|[0-9\.]+)|'.*?[^'\\]'|".*?[^\\]"/\?/gi;
        $row->{Info} =~ s/(\s+IN\s+)\([\?,\s]+\)/$1(...)/gi;
        $row->{Info} =~ s/(\s+VALUES\s+)[\(\)\?\,\s]+/$1.../gi;
    }
  print to_json($rows, { ascii => 1 }), "\n";
}
