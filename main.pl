#!/usr/bin/perl


use IO::Socket qw(:DEFAULT :crlf);
use IO::Socket::INET;
use autodie;

use feature ':5.10';
use subs /translate_header content_length http_read/;
use strict;
use warnings;

use constant BANNER => 'Adware proxy';
use constant HTTP_PORT => 80;
use constant PROXY_PORT => 5555;
use constant LISTEN_CAP => 20;


#Main program logic
main();


sub main{
	STDOUT->autoflush(1);
	say BANNER;
	my $main_socket = IO::Socket::INET->new(LocalPort => PROXY_PORT, Listen => LISTEN_CAP, Type => SOCK_STREAM, ReuseAddr => 1) or die "error in creating socket:$!";
	$main_socket->listen(LISTEN_CAP);
	while(1){
		next unless my $socket = $main_socket->accept();
		if(fork() == 0){
			my ($header, $host, $port);
			$main_socket->close();		
			my $remote_addr = $socket->peerhost;
			say "remote host: $remote_addr";
			{
				local $/ = CRLF.CRLF;
				$header = <$socket>;
			}
			print "HEADER: $header";
			print "End of HEAder";
			($header, $host, $port) = translate_header($header);
			$port //= HTTP_PORT;
			print "HEADER: $header";
			print "End of HEAder";
			my $connect_socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port) or die "can't connect to $host: $!";
			$connect_socket->print($header);
			my ($ret_header, $body) = http_read($connect_socket);
			print "ret header: $ret_header";
			my $content_length = content_length($ret_header);
			$socket->print($ret_header);
			$socket->print($body);
			$connect_socket->close();
			
		}
		$socket->close();
	}
	
	$main_socket->close;
}

sub translate_header($){
	my $header = shift;
	my($host, $port, $page, $proto) = $header =~ m!^GET http://([^/:]+)(:\d+)?(\S*) +(.*)!;
	$header =~ s!^GET .*!GET $page $proto!g;
	return ($header, $host, $port);
}

sub content_length($){
	my $header = shift;
	my ($content_length) = $header =~ /Content-Length: +(\d+)/;
	return $content_length;
}

sub http_read{
	my $socket = shift;
	my ($data, $temp);
	while(sysread($socket, $temp, 1024) > 0){
		$data .= $temp;
	}
	return seperate_header($data);
}

sub seperate_header{
	my $text = shift;
	my $pos = index($text, CRLF x 2);
	#returns header including CRLF x 2
	return (substr($text, 0, $pos + 2), substr($text, $pos + 2));
}	
