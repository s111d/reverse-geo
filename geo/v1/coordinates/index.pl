#!/usr/bin/perl 
use lib "/home/sid/PERL/lib"; 
use lib "/home/sid/PERL/lib/perl5";
use CGI; 
use LWP::Simple;
use JSON qw(decode_json);
#use Data::Dumper; 
use IPC::SharedCache;
use strict;

#Sometimes needed, but not this time
#use constant API_KEY => 'AIzaSyDqz-OZDj-NebP4ygINp0Ropd9epa45IFE';

sub create_entry {
  my $record = undef; 
  my ($lat, $long) = @_;
	
	my $api_url = sprintf("https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&sensor=true_or_false&key=%s", ($lat, $long, ''));

	my $json = get($api_url) or die('Failed to request Google API.');

	my $decoded_json = decode_json( $json );

	if ($decoded_json->{'status'} eq 'OK') {
	  #Picking up the one that supposed to be the most detailed	
	  my $most_detailed_address = $decoded_json->{'results'}[0];
	  #Country record tends to be closer to the end
	  foreach (reverse @{$most_detailed_address->{'address_components'}}){
		  my %hash = map { $_ => 1} @{$_->{'types'}};
		  if ($hash{'country'} == 1){
				$record = $_->{'short_name'};		
		  }
	  }
  }
	else{
	  #Error processing is badly missed here.
	}

	return \$record;							
}

sub validate_entry {
  #For brevity, assuming no need to invalide cache			
  return 1;
}

my $cgi = new CGI; 
#This couple should be validated before passing on further, 
#but we omit that for the sake of brevity.
my $latitude = $cgi->param('lat'); 
my $longitude = $cgi->param('lng'); 

#Note: production solution should be reboot-proof. This one isn't.
tie my %cache, 'IPC::SharedCache', 
		ipc_key => 'BOX1', 
		load_callback => [\&create_entry, $latitude, $longitude], 
		validate_callback => \&validate_entry, 
		debug=>1; 

my $country_code =  $cache{$latitude . '_' . $longitude};

print "Content-type: text/html\n\n"; 
printf ('{"Country":"%s"}', $$country_code);
