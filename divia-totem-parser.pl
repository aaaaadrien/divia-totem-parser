#! /usr/bin/perl -s
# Les URL des "API" TOTEM sont l'oeuvre de rétro-ingénierie de  ma part
# une quelconque violation des droits d'utilisation n'est pas volontaire
# Merci de votre comprehension. Adrien_D


use strict;
use warnings;

use utf8;

use Net::SSLeay; 
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;

#Granville : arret=666_89
#Europe : arret=1498_185

my $ligne = 89;
my $arret = 666;

our $l; #ARG -l = list lines
our $a; #ARG -a = list arrets

my $relation;
my $url;
my $ua;
my $useragent;
my $response;
my @tmp;

if ( $l eq 1 ) 
{
	$url = "https://www.divia.fr/totem/recherche";	
	$ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 0 });
	$response = $ua->get($url);

	if ($response->is_success) {
		my @html = split qr/\R/, $response->decoded_content;
		my $value;
		my $line;
		my $dir;
		my $ok = 0;
		my $data_line;

		foreach (@html)
		{
			if ( $ok eq 1 )
			{
				if ( $_ =~ /value/ )
				{
					$data_line="";
					
					@tmp = split qr/"/, $_;
					$data_line = $tmp[1]." - ";
				}

				if ( $_ =~ /data-class/ )
				{
					@tmp = split qr/"/, $_;
					$tmp[1] =~ s/ perturb//g;
					$data_line = $data_line.$tmp[1]." : ";
				}
				
				if ( $_ =~ /data-type/ )
				{
					@tmp = split qr/>|</, $_;
					$data_line = $data_line.$tmp[2];

					print $data_line."\n";
				}



				if ( $_ =~ /\/select/ )
				{
					$ok=0;
				}
			}
			else
			{
				if ($_ =~ /form_totem_home_search_ligne/)
				{
					$ok=1;
				}
			}
		}

	}
	else
	{
		print "Erreur TOTEM : $response->status_line \n";
	}


	exit; #Moche, a changer
}








$relation = $arret."_".$ligne;
$url="https://www.divia.fr/totem/appli_resultat/ligne/$ligne/arret/$relation/";
$ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 0 });
$response = $ua->get($url);


if ($response->is_success) {
	#print $response->decoded_content;
	
	my @html = split qr/\R/, $response->decoded_content;
	my $pass1;
	my $pass2;

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
