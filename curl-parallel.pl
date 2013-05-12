#!/usr/bin/perl -w

# Given a list of urls in the stdin fetch the urls as quickly as possible
# and save into a directory
#
use LWP::Simple;
use File::Path;
use POSIX;
use File::Basename;

require LWP::Parallel::UserAgent;

my $batchSize = 100;
my @lines = ();
my $dir = "./".strftime("%Y%m%d_%H_%M", localtime())."/";

while (<>)
{
    chomp();
    push(@lines, $_);
    if (length(@lines) == $batchSize)
    {
	parallel_download(\@lines);
	@lines = ();
    }
}
parallel_download(\@lines);


sub parallel_download
{
   my ($AR_urls) = @_;
   if (!ref($AR_urls))
   {
        die "parallel_download expect argument to be ref to an array\n";
   }

  mkpath($dir) 
        unless(-d $dir);

   my $ua = LWP::Parallel::UserAgent->new();

   $ua->redirect (0); # prevents automatic following of redirects
   $ua->max_hosts(20); # sets maximum number of locations accessed in parallel
   $ua->max_req  (40); # sets maximum number of parallel requests per host
   
   my @A_requests = ();
   my %H_downloads = ();
   foreach my $S_url (@$AR_urls)
   {
     my $request = new HTTP::Request('GET', $S_url); 
     my $basename = basename($S_url);
     $basename =~ s/\W/_/g;
     my $download_file = $dir.$basename;     # _downloadPath has '/' at the end
     $ua->register($request, $download_file);
     $H_downloads{$S_url} = $dir.basename($S_url);
   }

   my $S_starttime = time();
   print "start ".scalar(localtime())." downloading urls in parallel\n";
   my $entries = $ua->wait();

   print "[DURATION ",(time() - $S_starttime),"] ";
   print "done  ".scalar(localtime())."downloading urls in parallel\n";

   foreach (keys %$entries) {
       my $response = $entries->{$_}->response;
       my $uri = $response->request->url;
       if ($response->is_success())
       {
            print "\n\nSUCCESS: Request to ",$uri, "returned code ", $response->code,
             ": ", $response->message, "\n";
       } else {
            print "\n\nERROR! Request to [$uri], returned code ", $response->code,
             ": ", $response->message, "\n";
       }
   }

   
}
