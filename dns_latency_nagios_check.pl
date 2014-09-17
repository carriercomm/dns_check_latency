#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  check.pl
#
#        USAGE:  ./check.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Someone (), Something
#      COMPANY:  Classified
#      VERSION:  1.0
#      CREATED:  09/16/14 11:41:56
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use IO::Socket;
use Sys::Hostname;
use Getopt::Long;
use Time::HiRes qw(time);
use Data::Dumper;
my $server;
my $hostname = hostname;
my ($warning, $critical);
##Usage
sub usage {
	my $message = $_[0];
	if (defined $message && length $message) {
		$message .= "\n"
		unless $message =~ /\n$/;
	}
	my $command = $0;
	$command =~ s#^.*/##;
	print STDERR (
	$message,
 	"usage: $command -w|warning <int> -c|critical <int>\n" .
 	"       ...\n"
	);
	die("\n")
} ####End of subroutine usage
Getopt::Long::GetOptions(
			'w|warning=f'      =>  \$warning,
			'c|critical=f'	   =>  \$critical
			) or usage ("Invalid commmand line options.");

usage("No parameters specified") unless defined $warning && $critical;
usage("Warning should be less than critical value") unless ($warning < $critical);

##Take first entry from resolv.conf
open(FH, "</etc/resolv.conf") or die $!;
while (<FH>) {
	if ($_ =~ /^nameserver\ ([0-9].*)/) {
		$server = $1;
		last;
		}##End of if
	}##End of while
&check_latency($hostname, $server);

##Start of sub check_latency
sub check_latency {
	my ($hostname, $server) = @_;
	my ($format, @labels, $count, $buf);
	my $header = pack(
				'n C C n n n n',
				1,
				1,
				0,
				1,
				0,
				0,
				0
				);##End of pack $header
	for ( split( /\./, $hostname ) ) {
		$format .= 'C a* ';
		$labels[$count++] = length;
	#	print "@labels\n\n\n";
		$labels[$count++] = $_;
	#	print "@labels\n\n\n";
	#	print $format;
		}
	my $question = pack(
				$format.'C n n',
				@labels,
				0,#End of labels
				1,#Query A
				1 #Query IN
				);#Closing pack $question
	my $req_time = time; 
	#print "$req_time\n";
	##Send packet to nameserver
	my $sock = new IO::Socket::INET(
				PeerAddr => $server,
				PeerPort => '53',
				Proto => 'udp'
				);
	$sock->send($header.$question);
	{
	eval {
		local $SIG{ALRM} = sub { die "Timed Out waiting for response from $server"; };
		alarm 5;
		$sock->recv( $buf, 512 );#Recv packet size
		close($sock);
		};
	#print $@; ##print error
	if ($@) {
		print $@;
		exit 2;
		}
	}

	my @response = unpack('n C C n n n n', $buf);
	#print  @response;
	#print length $buf;
	my $resp_time1 = time;
	#print "$resp_time1\n";
	my $latency = $resp_time1 - $req_time;
	my $alarm = sprintf("%.3f", $latency);
	$alarm = $alarm * 1000;
	#print $response[4];
	#print @response;

	if (! $response[4]){
		print "No data for $hostname from $server\n";
        exit 2;
    }
	elsif ($alarm < $warning) {
		#printf "Latency for querying $hostname is %.3f\n", $latency;
		print "Latency for querying $hostname is $alarm ms\n";
		exit 0;
		}
	elsif ($alarm >= $warning && $alarm < $critical) {
		print "Latency for querying $hostname is $alarm ms\n";
		exit 2;
		}
	else {
		print "Latency for querying $hostname is $alarm ms\n";
		exit 1;
		}
	
		
	}##End of subroutine check_latency
