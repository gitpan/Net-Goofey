#!/usr/bin/perl -w
#
# Example Goofey client using Net::Goofey
# 
# ObLegalStuff:
#    Copyright (c) 1998 Bek Oberin. All rights reserved. This program is
#    free software; you can redistribute it and/or modify it under the
#    same terms as Perl itself.
# 
# Last updated by gossamer on Fri Aug 28 17:31:20 EST 1998
#

use strict;
use Getopt::Std;

use Text::LineEditor;

use Net::Goofey;


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
} elsif ($opt{"v"}) {
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
   my $text = line_editor();

   print $Goofey->send($opt{"s"}, $text);

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
      my($message_type, $message_data) = $Goofey->listen();

      print STDERR "Client:  message type:  '$message_type'\n";
      print STDERR "Client:  message data:  '$message_data'\n";

      if ($message_type eq $Goofey_Exit) {
         die "Goofey:  Died at server request.\n";
      } elsif ($message_type eq $Goofey_Message) {
         print "Goofey Message:\n$message_data\n\n";
      } else {
         die "Goofey:  Unknown message type: '$message_type'";
      }

   }

} else {
   die "Unknown option.\n";
}


#
# End.
#
