#!/usr/bin/perl

use strict;
use Time::Local;
use LWP::Simple;


print "\n";
my $basedir = "/sys/bus/w1/devices/";       #basedir for 1wire filesystem

my $remotehost = "http://www.ringserver.de/cgi-bin/gettemp.pl"; #url for remote script

my @files;
my $aktfile;
my $aktsensorname;
my $sensorname;
my $valuepath;
my $temperature;
my $parameterstring;
my $remoteaddress;

if (-d $basedir)                #proceed only if 1wire is present
  {
 opendir(DIR, $basedir) or die $!;
 @files =  readdir(DIR);                #read directorey entries
 closedir(DIR);

foreach (@files)
{
$aktfile = $_;



if( substr($aktfile,0,2) eq "28")       #proceed only if dirname starts with "28" => Dallas 18b20 sensors
{

   $sensorname = $aktfile;
   $sensorname =~s/-//;

   $valuepath=$basedir . "/". $aktfile ."/w1_slave";

   open FILE, $valuepath or die $!;
   while (<FILE>)
      {
      my $aktline= $_;          #reading sensor values

      if ($aktline=~m/t=/)      #look for temperature entry
          {
          $aktline=~m/\d{5}/;   #regex for temperature
          $temperature = $&;
            $parameterstring .= $sensorname . "=" . $temperature/10 . ";";  #assemble form data and cut last digit from temperature


          }



      }
   close FILES;

}




}
chop $parameterstring;          #remove last semicolon




  }
else
  {
  print "Keine Parameter gefunden\n";
  }












$remoteaddress=$remotehost . "?" . $parameterstring;    #assemble query

 my $content = get $remoteaddress;          #send query
  die "Couldn't get $remoteaddress" unless defined $content;    #check for success
#print "$content\n";

 exit (0);

