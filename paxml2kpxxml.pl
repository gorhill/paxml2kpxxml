#!/usr/bin/perl

use warnings;
use strict;

# Load whole file in memory
my $input;
while (<>) {
 $input = $input . $_;
 }

# Password Agent generates an ISO-8859-1 XML file
use utf8;
utf8::encode($input);

# create XPath object
use XML::XPath;
my $xp = XML::XPath->new(xml=>$input);

use Date::Format;
my $maxmonth = 0;

sub parse_date {
 if ($_[0]) {
  $_[0] =~ /(\d{4})/;
  my $y = $1;
  $_[0] =~ /\b(\d\d)\D(\d\d)\b/;
  return [$2,$1,$y-1900];
  }
 return [7,7,2010-1900];
 }

# iterate through groups, entries
my %groups = ();
my $groupnodes = $xp->find('//group');
foreach my $groupnode ($groupnodes->get_nodelist) {
 my $groupname = $xp->find('name/text()', $groupnode);
 my $entrynodes = $xp->find('entry', $groupnode);
 for my $entrynode ($entrynodes->get_nodelist) {
  my $entryname = $xp->find('name/text()', $entrynode);
  my $account = $xp->find('account/text()', $entrynode);
  my $password = $xp->find('password/text()', $entrynode);
  my $url = $xp->find('link/text()', $entrynode);
  my $note = $xp->find('note/text()', $entrynode);
  my $date_added = parse_date($xp->find('date_added/text()', $entrynode));
  my $date_modified = parse_date($xp->find('date_modified/text()', $entrynode));
  my $date_expire = parse_date($xp->find('date_expire/text()', $entrynode));
  $groups{$groupname}{$entryname} = {'account'=>$account,'password'=>$password,'url'=>$url,'note'=>$note,'date_added'=>$date_added,'date_modified'=>$date_modified,'date_expire'=>$date_expire};
  # collect date data in order to figure date format
  foreach my $date ($date_added,$date_modified,$date_expire) {
   if (@$date[1] > $maxmonth) {
    $maxmonth = @$date[1];
    }
   }
  }
 }

# date format must be: YYYY-MM-DDTHH:MM:SS
my $date_template = q"%Y-%m-%dT12:00:00";
my $imday = $maxmonth <= 12 ? 0 : 1;

# generate keepassx xml file
# UNSAFE mode required, as the KeePassX's DOCTYPE doesn't
# match its first tag, causing XML::Writer to abort
use XML::Writer;
my $writer = new XML::Writer(UNSAFE => !0);

$writer->xmlDecl();
$writer->doctype("KEEPASSX_DATABASE");
$writer->startTag("database");

while (my ($groupname, $entries) = each %groups) {
 $writer->startTag("group");
 $writer->dataElement("title", $groupname);
 $writer->dataElement("icon", '0');
 while (my ($entryname, $details) = each %$entries) {
  $writer->startTag("entry");
  $writer->dataElement("title", $entryname);
  $writer->dataElement("icon", '0');
  $writer->dataElement("username", $details->{'account'});
  $writer->dataElement("password", $details->{'password'});
  $writer->dataElement("url", $details->{'url'});
  $writer->dataElement("comment", $details->{'note'});
  my @d = @{$details->{'date_added'}};
  $writer->dataElement("creation", strftime($date_template, @{[0,0,12,$d[0^$imday],$d[1^$imday]-1,$d[2],0,0,0]}));
  $writer->dataElement("lastaccess", '2010-07-17T12:00:00');
  @d = @{$details->{'date_modified'}};
  $writer->dataElement("creation", strftime($date_template, @{[0,0,12,$d[0^$imday],$d[1^$imday]-1,$d[2],0,0,0]}));
  @d = @{$details->{'date_expire'}};
  $writer->dataElement("creation", strftime($date_template, @{[0,0,12,$d[0^$imday],$d[1^$imday]-1,$d[2],0,0,0]}));
  $writer->endTag();
  }
 $writer->endTag();
 }

$writer->endTag();
$writer->end();
