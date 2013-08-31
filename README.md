paxml2kpxxml
============

Perl script to convert a Moon Software's Password Agent XML file into open source KeepassX XML file.

I wrote this script years ago, thought I might as well throw it on Github in case it can still be of any use to someone. I don't know whether any of the stuff here is still relevant regarding Password Agent.

Instructions
============

After I moved from Windows to Ubuntu, for good, I had to find a replacement for Moon Software's Password Agent. After looking around a bit, I decided to go with KeePassX. Those used to Password Agent will feel right at home with KeePassX, a major difference being that the latter is Open Source.

Now, the problem was to convert all the data collected over the years in Password Agent to a format understood by KeePassX. Password Agent allows to export its content to an XML file, while KeePassX allows the import an XML file.

However, both XML files are not structured similarly, thus a converter is needed to translate Password Agent XML format into KeePassX XML format.

This is what the following steps do. Note that this was written based on my own installation, which is Ubuntu 10.04 (Lucid Lynx), and Password Agent version 2.3.4, and KeePassX version 0.4.3.

First things first: we need to export Password Agent's data to a Password Agent XML file

* Launch Password Agent and load the data file which needs to be converted
* Go to [File] menu and click the [Print & Export...] entry. A dialog box opens
* Click [all] where it says "Groups (select all | none):"
* Click [all] where it says "Fields (select all | none):"
* Pick [XML - export database] in "Output format" selector
* It doesn't matter what you pick in the "Sort by:" selector
* Click [Next]
* Enter "mypa.xml" as the file name to which your Password Agent XML file will be written and click [Finish]

Now you need to move this Password Agent XML file to your Ubuntu installation. Copy the file onto your Ubuntu Desktop.

Important: Be sure to not leave a copy of this file behind, as it contains all your ids/passwords in a human-readable format. This file should exists only until such time that KeePassX is up and running with all your data in it.

Now  we need to convert this newly saved Password Agent XML file to a KeePassX XML file. For this we will use a Perl script, and for this Perl script to execute, we need Perl.

* From your desktop, go to [Applications] menu and click [Ubuntu Software Center]
* In the search box (top right), enter "perl"
* In the resulting list, find the entry named "Larry Wall's Practical Extraction and Report Language / perl"
* Install it if not already installed

Now that you have Perl installed, we need to ensure that you have the "XML::Writer" Perl module installed as well:

* From your desktop, go to [Applications] menu and click [Ubuntu Software Center]
* In the search box (top right), enter "perl xml writer"
* In the resulting list, find the entry named "Perl module for writing XML documents / libxml-writer-perl"
* Install it if not already installed

While at it, ensure you have KeePassX installed:

* From your desktop, go to [Applications] menu and click [Ubuntu Software Center]
* In the search box (top right), enter "keepassx"
* In the resulting list, find the entry named "KeePassX / Cross Platform Password Manager"
* Install it if not already installed

Now, copy the Perl code below, and save it to a text file onto the Desktop of your Ubuntu installation (notice to Perl gurus out there: this my first ever Perl script, so don't be harsh on me):

* Right-click onto your Ubuntu desktop, and select [Create Document > Empty File...]
* Name the file "paxml2kpxxml.pl" (meaning Password Agent XML to KeePassX XML…)
* Right-click onto the newly created empty file and select [Properties]
* In the dialog box, click the [Permissions] tab
* Check [Allow executing file as program]
* Click [Close]
* Right-click onto the newly create empty file and select [Open]
* A dialog box opens, asking you whether you want to run or display the file. Click [Display]
* A text editor opens with the content of the newly created file — which is obviously empty
* Cut and paste the code below into the text editor:

    
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
    

Save the file and quit the text editor

So now we are ready to convert our Password Agent XML file to a KeePassX XML file.

* From your Desktop, click on [Applications], then [Accessories], then [Terminal]. A shell terminal should open.
* In the terminal, type "cd Desktop" and hit enter
* If you have properly followed each steps, your Desktop folder should contain your Password Agent XML file ("mypa.xml") and the Perl script file ("paxml2kpxxml.pl")
* In the terminal, type "./paxml2kpxxml.pl mypa.xml > mykpx.xml" and hit enter
* If all is well, you now have a new XML file on your Desktop, named "mykpx.xml" which file can be imported into KeePassX
* You can leave the terminal window

Password Agent doesn't save date information in a normalized fashion. Because of this, the script will try to guess the format the best it can. Default is to assume the format is Month/Day/Year. But it will try to detect if the format is Day/Month/Year (or Year/Month/Day, Year/Day/Month, etc.) and convert properly date information.

Now we just need to import the newly generated file into KeePassX:

* From your Desktop, click [Applications], then [Accessories], then [KeePassX] (where it is found usually)
* In KeePassX, click the [File] menu, then [Import from... > KeePassX XML (*.xml)]
* Select the "mykpx.xml" in your Desktop folder
* If the file is successfully imported, KeePassX will ask you for a master password, twice. Then from there you should save your file and explore the various settings to configure it to your taste

Very important, last steps:

* Delete all copies of "mypa.xml" files, from your Windows and Ubuntu installations
* Delete copy of "mykpx.xml" file from your Ubuntu desktop
* Remove these files from the Windows and Ubuntu "trash cans" as well

Little kink(s):

Some characters in the Password Agent XML file caused the Perl script to choke. In my case, I had to manually edit the Password Agent XML file, to replace a ‘Á' with ‘A'. Doing such allowed the Perl script to work properly.
