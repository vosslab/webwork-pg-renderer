#!/usr/bin/env perl
use strict;
use warnings;

use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;

my $base = $ENV{SMOKE_BASE_URL} // 'http://localhost:3000';
my $ua   = Mojo::UserAgent->new;

my @targets = (
    { path => 'private/myproblem.pg', seed => 1234 },
);

for my $target (@targets) {
    my $res = $ua->post(
        "$base/render-api" => form => {
            sourceFilePath => $target->{path},
            problemSeed    => $target->{seed},
            outputFormat   => 'classic',
            format         => 'json',
        }
    )->result;

    if ($res->is_success) {
        my $json = decode_json($res->body);
        if ($json->{renderedHTML} && $json->{renderedHTML} =~ /Problem/ ) {
            print "[OK] $target->{path} seed=$target->{seed}\n";
        } else {
            die "[FAIL] $target->{path} missing expected content\n";
        }
    } else {
        die "[FAIL] $target->{path}: " . $res->code . " " . $res->message . "\n";
    }
}

print "pg-smoke complete\n";
