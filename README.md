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

Now, the script:

* Download the file <https://github.com/gorhill/paxml2kpxxml/blob/master/paxml2kpxxml.pl> onto your desktop
* Right-click onto the newly downloaded file and select [Properties]
* In the dialog box, click the [Permissions] tab
* Check [Allow executing file as program]
* Click [Close]

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

* Delete (or better, <http://linux.die.net/man/1/shred>) all copies of "mypa.xml" files, from your Windows and Ubuntu installations
* Delete (or better, <http://linux.die.net/man/1/shred>) copy of "mykpx.xml" file from your Ubuntu desktop
* Remove these files from the Windows and Ubuntu "trash cans" as well (applies only if you did not <http://linux.die.net/man/1/shred>)

Little kink(s):

Some characters in the Password Agent XML file caused the Perl script to choke. In my case, I had to manually edit the Password Agent XML file, to replace a ‘Á' with ‘A'. Doing such allowed the Perl script to work properly.
