#!/usr/bin/perl -w
#
# Example Goofey client using Net::Goofey
#
# Last updated by gossamer on Tue Aug 11 22:22:06 EST 1998
#

use strict;
use Net::Goofey;

use Getopt::Std;


my %opt;

sub die_nicely {
   my $signal = shift;

   print STDERR "Goofey got signal $signal, exiting.\n";
   exit;

}

sub user_help {

   print "Use the source, Luke.\n";
   return 1;
}

#
# Main
#

getopts('vhw:l:s:', \%opt);

if ($opt{"h"}) {
   # help requested
   &user_help();
   exit;
}

if ($opt{"v"}) {
   # version number
   print "Basic Net::Goofey client built with " . Net::Goofey::version() . "\n";
   exit;
}

# every other option requires a goofey connection so do it here
my $Goofey = Net::Goofey->new();
if (!$Goofey) {
   die "Failed to connect to Goofey server: $!\n";
}

# Go through other options
if ($opt{"w"}) {
   print $Goofey->who($opt{"w"});

} elsif ($opt{"l"}) {
   print $Goofey->list($opt{"l"});

} elsif ($opt{"s"}) {
   my $text;

   print $Goofey->send($opt{"s"}, "foo");
} elsif (!%opt) {
   # No options, register as resident goofey

   $Goofey->signon() || die "Couldn't sign on.";

   print "Successfully signed on, backgrounding client.\n";

   # At this point, we have a connection
   if (fork()) {
      # Parent process - die politely
      exit();
   }

   # This is the child process, backgrounded.  It stays alive to do stuff.

   # Set the interrupt handlers
   $SIG{INT} = $SIG{TERM} = \&die_nicely;

   while (1) {
      # Try to accept a connection
      # If we have one, answer it properly
      # else continue

   }

} else {
   die "Unknown option.\n";
}


#
# End.
#
