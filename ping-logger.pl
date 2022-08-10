#!/usr/bin/env perl

use strict;
use warnings;

use Net::Ping 2.74;

use Getopt::Long;
use Pod::Usage;


=head1 USAGE

  ./ping-logger.pl --hosts=4.2.2.2,google.com --frequency=3 \
      --sqlite_db=my-log.db --timeout=4 \
      --max-pings=20000 --max-runtime=43200

  ./ping-logger.pl --help

=head1 OPTIONS

=over

=item --hosts CSV-LIST-OF-HOSTS-TO-PING

comma-separated list of one or more hostname/ipaddresses to continuously ping. Hosts will
be pinged round-robin in the sane order suppplied

=item --frequency SECONDS

Number of secinds between each ping. With a frequency of 1, If 4 hosts are defined, each will
be pinged every 4 sedinds under pefect conditions. Real-world rates will depend on how long
each host takes to respond, and if not at all, the length of the timeout.

=item --timeout SECONDS

how long to wait for each host to reply to the ping before being recorded as "down" and moving on to
the next host in the list.

=item --sqlite_db DB_FILE_PATH

Path to SQLite db file to long each ping result. File will be created and ititialized if it does not
already exist.

=item --max-pings NUMBER [OPTIONAL]

If set, the program with automatically terminate after the suuplied number of pings hav ben sent

=item --max-runtime SECONDS [OPTIONAL]

If set, the program will automatically terminate after the supplied time has elapsed, regardless
of the number of pings actually sent. Note: if neither this option or the --max-pings option has
been setup,  the program will continue to run until manually terminated (SIGINT/SIGTERM)

=back

=cut


my @arglist = @ARGV; # Don't clobber @ARGV on general principals

Getopt::Long::Configure("pass_through");
Getopt::Long::Configure("no_ignore_case");

my $Opt = {
  # defaults:
  hosts   => '4.2.2.2,8.8.8.8,google.com',
  frequency    => 5,
  timeout      => 2,
  max_pings    => 0,
};



Getopt::Long::GetOptionsFromArray( \@arglist,
  'hosts=s@'         => \$Opt->{hosts},
  'frequency=i'      => \$Opt->{frequency},
  'timeout=i'        => \$Opt->{timeout},
  'max-pings=i'      => \$Opt->{max_pings},
  'help|?'           => sub { &_show_usage(1) },
) or &_show_usage(2);


my @hosts = split(/\s*\,\s*/,$Opt->{hosts});


my $ping_count = 0;

while (1) {
  
  for my $host (@hosts) {
    
    print join(''," [",++$ping_count,"] -> ping $host :  ");
  
    my $p = Net::Ping->new("icmp");
    $p->hires();
    my ($ret, $duration, $ip) = $p->ping($host, $Opt->{timeout});
    my $ip_info = "$host" eq "$ip" ? '' : "[ip: $ip] ";
    if($ret) {
      printf("$ip_info reply received in %.2f ms)\n",1000 * $duration);
    }
    else {
      printf("$ip_info request timed out (%.2f ms)\n",1000 * $duration);      
    }
    $p->close();
    
    if($Opt->{max_pings} && ($Opt->{max_pings} <= $ping_count)) {
      print "\n\nMax number of pings '$Opt->{max_pings}' has been reached.\n";
      print "Program terminating.\n\n";
      exit;
    }
  }
}
  





exit;

#############################################################
#############################################################
#############################################################

sub _show_usage {
  my ($arg, @extra) = @_;

  if ($arg =~ /^\d$/) {
    pod2usage($arg); # for calling the number variant, pod2usage(1) and pod2usage(2)
  } else {
    my %opt = (
      -message => join('',"ERROR:\n\n  ",$arg,"\n\n"),
      @extra # this can override and pass custom key/vals through
    );
    pod2usage(%opt);
  }

  exit; #should never be called
}
