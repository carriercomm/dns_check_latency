dns_check_latency
=================

A simple perl script that checks dns latency, and exits with an appropriate exit status from a linux server without using NET::DNS. This script will read the 1st entry from resolv.conf, create a UDP packet DNS query with its hostname to look up for A record, and captures the time in 'ms' from the time the packet is send and until the packet is received.
