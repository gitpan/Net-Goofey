package Net::Goofey;
#
# Perl interface to the Goofey server.
#
# Last updated by gossamer on Wed Jul 15 15:20:23 EST 1998
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

use IO::Socket;
use Sys::Hostname;
use Symbol;
use Fcntl;
use Carp;

require 'dumpvar.pl';

@ISA = qw(Exporter);
@EXPORT = qw( Default_Goofey_Port );
@EXPORT_OK = qw();
$VERSION = "0.3";


=head1 NAME

Net::Goofey - Communicate with a Goofey server

=head1 SYNOPSIS

   use Net::Goofey;
     
   $Goofey = Net::Goofey->new();
   $Goofey->signon();

=head1 DESCRIPTION

C<Net::Goofey> is a class implementing a simple Goofey client in
Perl.

=cut

###################################################################
# Some constants                                                  #
###################################################################

my $Default_Goofey_Port = 3987;
my $Default_Goofey_Host = "pluto.cc.monash.edu.au";

my $Client_Type = "G";
my $Client_Version = "3.51";  # This matches the ver of the base client we are imitating

my $Password_File = $ENV{"HOME"} . "/.goofeypw";

my $DEBUG = 1;

###################################################################
# Functions under here are member functions                       #
###################################################################

=head1 CONSTRUCTOR

=item new ( [ USERNAME [, PASSWORD [, HOST [, PORT ] ] ] ])

This is the constructor for a new Goofey object. 

C<USERNAME> defaults, in order, to the environment variables
C<GOOFEYUSER>, C<USER> then C<LOGNAME>.

C<PASSWORD> defaults to the contents of the file C<$HOME/.goofeypw>.

C<HOST> and C<PORT> refer to the remote host to which a Goofey
connection is required.

The constructor returns the open socket, or C<undef> if an error has
been encountered.

=cut

sub new {
   my $prototype = shift;
   my $username = shift;
   my $password = shift;
   my $host = shift;
   my $port = shift;

   my $class = ref($prototype) || $prototype;
   my $self  = {};

   warn "new\n" if $DEBUG > 1;

   $self->{"username"} = $username || $ENV{"GOOFEYUSER"} || $ENV{"USER"} || $ENV{"LOGNAME"} || "unknown";
   $self->{"password"} = $password || &find_password;
   $self->{"host"} = $host || $Default_Goofey_Host;
   $self->{"port"} = $port || $Default_Goofey_Port;
   $self->{"incoming_port"} = 0;      # It gets set later if it's needed
   $self->{"extended_options"} = "";  # Not yet implemented
   my $tty = `tty`;
   $self->{"tty"} = chomp($tty);

   # open the connection
   $self->{"socket"} = new IO::Socket::INET (
      PeerAddr => $self->{"host"},
      PeerPort => $self->{"port"},
   );
   croak "new: connect socket: $!" unless $self->{"socket"};

   bless($self, $class);
   return $self;
}


#
# destructor
#
sub DESTROY {
   my $self = shift;

   shutdown($self->{"socket"}, 2);
   close($self->{"socket"});

   return 1;
}


=head1 signon ( );

Register this client as the resident one.

=cut

sub signon {
   my $self = shift;

   $self->{"incoming_port"} = &find_incoming_port() ||
      die "Can't find an incoming port\n";

   # Empty command - register us as the main client
   return $self->send_request($self->build_request(""));

}

=head1 send ( USERNAME, MESSAGE );

Send a message to a goofey user 
(Will clients handle their own iteration for multi-user messages, or
should we? For now I'm assuming that they will do it.)

=cut

sub send {
   my $self = shift;
   my $username = shift;
   my $message = shift;

   return $self->do_request("s $username $message");
}

=head1 unsend ( USERNAME );

Delete your last message to USERNAME, provided (of course) they 
haven't read it.

=cut

sub unsend {
   my $self = shift;
   my $username = shift;
   my $message = shift;

   return $self->do_request("s! $username");
}

=head1 who ([USERNAME]);

Do a goofey -w (who) command on a user or on all users currently
connected.

=cut

sub who {
   my $self = shift;
   my $username = shift;

   return $self->do_request("w $username");
}

=head1 list ([USERNAME]);

Do a goofey -l (list) command on a user or on all users currently
connected.

=cut

sub list {
   my $self = shift;
   my $username = shift;
   
   return $self->do_request("l $username");
}

=head1 quiet ();

Sets you quiet.  The server will then keep your messages until you
unquiet.  This mode lets through messages from anybody on your unquiet
alias, though.

=cut

sub quiet {
   my $self = shift;
   
   return $self->do_request("Q-");
}

=head1 quietall ();

Sets you quiet to everybody.

=cut

sub quietall {
   my $self = shift;
   
   return $self->do_request("Q!");
}

=head1 unquiet ();

Sets you unquiet.

=cut

sub unquiet {
   my $self = shift;
   
   return $self->do_request("Q+");
}

=head1 version ( );

Returns version information.

=cut

sub version {
   my $ver = "Net::Goofey version $VERSION, equivalent to goofey C client version $Client_Version";
   return $ver;
}


###################################################################
# Functions under here are helper functions                       #
###################################################################

sub send_request {
   my $self = shift;
   my $request = shift;

   if (!defined(syswrite($self->{"socket"}, $request, length($request)))) {
      warn "syswrite: $!";
      return 0;
   }

   return 1;
   
}

sub get_answer {
   my $self = shift;

   my $buffer = "";
   my $buff1;
   
   while (sysread($self->{"socket"}, $buff1, 999999) > 0) {
      $buffer .= $buff1;
   }

   return $buffer;

}

sub build_request {
   my $self = shift;
   my $command = shift;

   my $request = "#" . $Client_Type . $Client_Version . "," . 
          $self->{"extended_options"} . 
          $self->{"username"} . "," .
          $self->{"password"} . "," .
          $self->{"incoming_port"} . "," .
          $self->{"tty"};
  if ($command) {
     $request .= "," . $command;
  }
  
  $request .= "\n";

  return $request;
}

#
# Does the whole build-send-getanswer thing
#
sub do_request {
   my $self = shift;
   my $command = shift;

   $self->send_request($self->build_request('*' . $command));
   shutdown($self->{"socket"},1);

   return $self->get_answer();
}

# Reads password from the file
sub find_password {
   my $password = "";

   open(PWD, $Password_File) || warn "Can't open password file '$Password_File': $!"; 
   $password = <PWD>;
   chomp($password);
   close(PWD);

   return $password;
}

# Searches for a port that the server can use to talk to us
sub find_incoming_port {
   my $port = 9473;

   return $port;
}

=pod

=head1 AUTHORS

Kirrily Robert <skud@monash.edu.au> and Bek Oberin
<gossamer@tertius.net.au>

=head1 COPYRIGHT

Copyright (c) 1998 Kirrily Robert & Bek Oberin.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# End code.
#
1;
