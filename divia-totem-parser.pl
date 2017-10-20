#! /usr/bin/perl -s
# Les URL des "API" TOTEM sont l'oeuvre de rétro-ingénierie de  ma part
# une quelconque violation des droits d'utilisation n'est pas volontaire
# Merci de votre comprehension. Adrien_D

#Tests 
#Granville : -l=89 -a=666
#Europe : -l=185 -a=1498 

# USE for better code
use strict;
use warnings;

# USE for encodings
use utf8;
use Encode qw(encode decode);

# USE Modules
use Net::SSLeay; 
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;

#VAR Detect OS :
my $os = $^O;

# VARS in args (perl -s required)
our $l; #ARG -lignes = list lines
our $a; #ARG -arrets = list bus stop 
our $h; #ARG -h = help

# VAR total args
my $args = $ARGV[0];

# VARS in the script
my $relation;
my $url;
my $ua;
my $useragent;
my $response;
my @tmp;


# FUNCTIONS
sub help(){
	print "Utilisation : divia-totem-parser.pl [OPTION]... \n";
	print "Afficher des renseignements sur les lignes, les arrêts et les prochains passages des bus et tram DIVIA\n\n";
	print "\t-l\t\t\tLister toutes les lignes disponibles\n";
	print "\t-a=ID\t\t\tListes tous les arrêts pour une ligne définie selon son ID (listé par -l)\n";
	print "\t-l=LIGNE -a=ARRET\tCode de l'arrêt d'une ligne pour lesquels trouver les prochains passages (Les 2 sont requis)\n";
}

sub txt() {
	my $txt = $_[0];

	if ( $os eq "MSWin32")
	{
		$txt = encode( 'cp437' , $txt);
	}
	else
	{
		$txt = encode( 'utf-8' , $txt);
	}
	$txt =~ s/&#039;/'/;
	$txt =~ s/&gt;/:/;
	
	return $txt;
}


# SCRIPT

if ( defined  $h and $h eq 1 ) 
{
	&help;
	exit;
}
if ( (!defined $h and !defined $a and !defined $l) or ( defined $args and $args eq "--help" ) )
{
	&help;
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
					$data_line = &txt($tmp[1])." - ";
				}

				if ( $_ =~ /data-class/ )
				{
					@tmp = split qr/"/, $_;
					$tmp[1] =~ s/ perturb//g;
					$data_line = $data_line.&txt($tmp[1])." : ";
				}
				
				if ( $_ =~ /data-type/ )
				{
					@tmp = split qr/>|</, $_;
					$data_line = $data_line.&txt($tmp[2]); #A mettre dans une fonction genre txt() + remplacer les "&#039;" par ' 

					print $data_line."\n";
				}

				if ( $_ =~ /\/select/ ) #To skip tests after select list
				{
					$ok=0;
				}
			}
			else
			{
				if ($_ =~ /form_totem_home_search_ligne/) #To skip tests for website header
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
					$data_line = &txt($tmp[1]);
				}

				if ( $_ =~ /code-totem/ )
				{
					@tmp = split qr/>|</, $_;
					$data_line = &txt($tmp[2])." : ".$data_line;
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
		my $stop = "";
		my $line = "";
		my $dest = "";
		my $pass1 = "";
		my $pass2 = "";

		foreach (@html)
		{
			if ( $_ =~ /<div class="title">/ )
			{
				@tmp = split qr/>|</, $_;
				$stop = &txt($tmp[2]);
			}
			
			if ( $_ =~ /class="item"/ )
			{
				@tmp = split qr/"/, $_;
				$line = &txt($tmp[3]);
			}
			
			if ( $_ =~ /v-align/ )
			{
				@tmp = split qr/>|</, $_;
				$dest = &txt($tmp[2]);
			}
				
			if ($_ =~ /picto-bus|picto-tram|time1/) 
			{
				if ($_ =~ /picto-bus|picto-tram/)
				{
					$pass1=0;
				}
				else
				{
					@tmp = split qr/"/, $_;
					if ( length($tmp[3])) {
						$pass1 = &txt($tmp[3]);
					}
					else
					{
						$pass1 = &txt("Ne circule pas");
					}
				}
			}
			if ($_ =~ /time2/)
			{
				#print "$_\n";
				@tmp = split qr/"/, $_;
				$pass2 = &txt($tmp[3]);
			}
		}
		print "$stop ($line $dest) : $pass1 - $pass2\n";
		
	}
	else
	{
		print "Erreur TOTEM : $response->status_line \n";
	}
	exit;
}
