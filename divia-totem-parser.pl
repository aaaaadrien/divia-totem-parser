#! /usr/bin/perl -s
# Les URL des "API" TOTEM sont l'oeuvre de rétro-ingénierie de  ma part
# une quelconque violation des droits d'utilisation n'est pas volontaire
# Merci de votre comprehension. Adrien_D


use strict;
use warnings;

use utf8;
use Encode qw(encode decode);

use Net::SSLeay; 
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;

#Granville : arret=666_89
#Europe : arret=1498_185


our $l; #ARG -lignes = list lines
our $a; #ARG -arrets = list bus stop 
our $h; #ARG -h = help

my $relation;
my $url;
my $ua;
my $useragent;
my $response;
my @tmp;


if ( defined  $h && $h eq 1 ) 
{
	print "Utilisation : divia-totem-parser.pl [OPTION]... \n";
	print "Afficher des renseignements sur les lignes, les arrêts et les prochains passages des bus et tram DIVIA\n\n";
	print "\t-l\tLister toutes les lignes disponibles\n";
	print "\t-a=ID\tListes tous les arrêts pour une ligne définie selon son ID (listé par -l)\n";
	print "\t-l=LIGNE -a=ARRET\tCode de l'arrêt d'une ligne pour lesquels trouver les prochains passages (Les 2 sont requis)\n";

	exit;
}


if ( defined  $l && $l eq 1 && !defined $a ) 
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
					$data_line = $data_line.encode( 'utf-8' , $tmp[2]); #A mettre dans une fonction genre txt() + remplacer les "&#039;" par ' 

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



if ( defined  $a && $a =~ /^\d+$/ && !defined $l ) 
{
	$url = "https://www.divia.fr/totem/appli_resultat/ligne/$a";	
	$ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 0 });
	$response = $ua->get($url);

	if ($response->is_success) {
		my @html = split qr/\R/, $response->decoded_content;
		my $ok = 0;
		my $data_line;

		foreach (@html)
		{
			if ( $ok eq 1 )	
			{
				if ( $_ =~ /title/ )
				{
					$data_line="";
					
					@tmp = split qr/>|</, $_;
					$data_line = $tmp[1];
				}

				if ( $_ =~ /code-totem/ )
				{
					@tmp = split qr/>|</, $_;
					$data_line = $tmp[2]." : ".$data_line;
					print $data_line."\n";
				}
			}
			else
			{
				if ($_ =~ /panel-totem-active/)
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






if ( defined $l && defined $a && $l =~ /^\d+$/ && $a =~ /^\d+$/) 
{

	my $ligne = $l;
	my $arret = $a;
	
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
	exit;
}
