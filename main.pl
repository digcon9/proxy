#!/usr/bin/perl


use IO::Socket;
use IO::Socket::INET;

use feature ':5.10';
use strict;
use warnings;

use constant PROXY_PORT => 5555;


say 'Adware proxy';
my $main_socket = IO::Socket::INET->new(LocalPort => PROXY_PORT, Listen => '20', Type => getprotobyname('tcp'), ReuseAddr => 1);
$main_socket->close();


