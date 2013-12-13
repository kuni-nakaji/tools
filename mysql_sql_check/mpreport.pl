#! /usr/bin/perl

use strict;
use warnings;
use JSON qw(from_json);

my %sql_cnt;
my $samples = 0;

while (my $line = <STDIN>) {
    $samples++;
    chomp $line;
    my $rows = from_json($line);
    for my $row (@$rows) {
        $sql_cnt{$row->{Info}}++
            if $row->{Info};
    }
}

for my $sql (sort { $sql_cnt{$b} <=> $sql_cnt{$a} } keys %sql_cnt) {
    printf(
        "%.3f:$sql\n",
        $sql_cnt{$sql} / $samples * 100,
        $sql,
    );
}