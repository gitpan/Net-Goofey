
BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::Goofey;
$loaded = 1;
print "ok 1\n";

# Connect
#my $Goofey = Net::Goofey->new("gossamer", "1uYpXRVnt+");
my $Goofey = Net::Goofey->new();
if ($Goofey) {
   print "ok 2\n";
} else {
   print "not ok 2\n";
}

if ($Goofey->who("skud")) {
   print "ok 3\n";
} else {
   print "not ok 3\n";
}

if ($Goofey->send("gossamer", "foo")) {
                  #`whoami` . " just tested Net::Goofey on " . `uname -a`)) {
   print "ok 4\n";
} else {
   print "not ok 4\n";
}

return 1;
