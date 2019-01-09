#!perl

use strict;
use File::Spec;
use Test::More;
use IPC::Run qw(run);

if (!eval { require Socket; Socket::inet_aton('pool.sks-keyservers.net') }) {
    plan skip_all => "Cannot connect to the keyserver to check signatures";
} else {
    plan tests => 6;
}

$|=1;
sub _f ($) {File::Spec->catfile(split /\//, shift);}
0 == system $^X, _f"t/wrap.pl", "-x" or die;
for my $tdir (glob("t/test-dat*")) {
    chdir $tdir or die;
    my @system = ($^X, "-I../../lib/", "../../script/cpansign", "-v");
    my($in,$out,$err);
    run \@system, \$in, \$out, \$err;
    my $ret = $?;
    close $out;
    my $diff = join "\n", grep /^.SHA1/, split /\n/, $out;
    my $output = "dir[$tdir]system[@system]ret[$ret]out[$out]err[$err]diff[$diff]";
    SKIP: {
        if ((0!=$ret) && (($err =~ /\bkeyserver\s+communications\s+error\b/imsx) || ($err =~ /\bcan't\s+check\s+signature\b/imsx))) {
            skip "Unable to retrieve key:\n$output", 1;
        };
        ok(0==$ret, $output);
    }
    chdir "../../" or die;
}
