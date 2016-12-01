#! /usr/bin/perl

use Net::SSLeay; 
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;

#Granville : arret=666_89
#Europe : arret=1498_185

#my $arret = "666_89";
my $arret = "1498_185";

my $ligne = 89;
my $arret = 666;

my $relation = $arret."_".$ligne;

my $url="https://www.divia.fr/totem/appli_resultat/ligne/$ligne/arret/$relation/";

my $ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 0 });
my $response = $ua->get($url);

if ($response->is_success) {
	#print $response->decoded_content;
	
	my @html = split qr/\R/, $response->decoded_content;
	my $pass1;
	my $pass2;
	my @tmp;

	foreach (@html)
	{
		if ($_ =~ /picto-bus|time1/) 
		{
			if ($_ =~ /picto-bus/)
			{
				$pass1="BUS";
			}
			else
			{
				@tmp = split qr/"/, $_;
				$pass1 = $tmp[3];
			}
		}
		if ($_ =~ /time2/)
		{
			#print "$_\n";
			@tmp = split qr/"/, $_;
			$pass2 = $tmp[3];
		}
	}


	print "Prochains Passages : $pass1 - $pass2\n";
}
else
{
	print "Erreur TOTEM : $response->status_line \n";
}
