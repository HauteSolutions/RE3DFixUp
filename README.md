# RE3DFixUp
Utility to post-process XPS Print Files to provide continued functionality of Full Spectrum Laser RetinaEngrave3D

(Please use the "Releases" link over on the right side of the GitHub page if you just want to download the EXE ------->

Full Spectrum Laser (FSL) designs and manufactures Laser machines which utilize proprietary controllers.  The only software
(Laser Driver) which will work with FSL Lasers is their own proprietary RetinaEngrave3D (RE3D) application.  Unfortunately,
FSL has discontinued support for RE3D which now leaves many of our very expensive lasers (which REQUIRE) this software
out in the cold.

Microsoft has recently released service (DLL) updates to its XPS Print Driver API.  FSL apparently uses XPS for data 
transport between user Design/CAD programs and their RE3D Laser Software.  Microsoft has apparently updated the data
specification for their XPS data format and implemented this new data format in the DLL's they have recently posted.
Unfortunately, FSL RE3D doesn't know how to handle certain aspects of this new data format and will IGNORE ASSOCIATED
DATA in the respective data stream.

Also, quite unfortunately, FSL refuses to update their RE3D software despite the fact that it no longer functions properly
and that it is the ONLY software we can use with our very expensive lasers.  FSL lasers, which use RE3D, are therefore
completely unusable in a "current" Operating Environment.

FSL's answer to this is to take our perfectly healthy Win10/Win11 machines and downgrade them to Win7.  Seriously, this is what
they told me!  FSL apparently thinks its OK to compromise the functionality of our whole entire systems just because
they don't want to update their software.

I've also seen some workarounds which suggest rolling back the XPS update which came down at the end of 2022.  But, similarly,
OTHER software (which IS properly maintained) may require on keeping these services up to date.  I'm also not going to
risk the integrity of OTHER software which chooses to keep up with the data format just because of one single player who 
chooses not to.  Its also likely a rollback for all future XPS updates wouold be required as well.

NEXT TIME:  Buy a Laser from a company who does not use proprietary hardware which requires proprietary software.  Also,
choose a laser manufacturer who is willing to support both their customers and product post-purchase.  Lesson Learned!

The changes which need to be made (based on my investigation) do not seem to be very complicated.  It took me about 6 hrs
to generate this utility from a completely cold start.  I had to do the data analysis and then write the corresponding code.
Imagine how much LESS TIME it would actually take an FSL Developer, who is starting with a knowledge of their underlying
data architecture, would take!  But no!  FSL is NOT interested!

The Problem:

Recently (Post Dec 2022) we are seeing vector entities being ignored when sending a cut file to RE3D.  This ONLY appears to
happen if an entity is duplicated within a drawing.  It doesn't appear to matter if its actually copied within the design
software or if its just created manually to be identical.  If RE3D sees identical entities in a file, it will simply ignore
them.  So far, I have only been able to reproduce this with CIRCLES.  I have NOT seen this happen with duplicated polygons.
Perhaps any object defined by linear vectors does not benefit from the XPS Data Update.  Anyway, it very well might effect
more than just circles.  Its a bit too early to tell...

How it Works:

The XPS Data Format has been updated to include a new data type which can be used for more efficient storage of entity info.
This new data format uses a "Dictionary" (inside the XPS file) to store the definition of entities which appear more than once
in a drawing.  Basically, the "Dictionary" defines the entity and then the "Pages" simply identify placement.  (To date, I've 
only seen this implemented for Circles but I expect it effects other objects as well).  It is this "Dictionary" definition
that RE3D ignores.  Accordingly, it only effects objects which are identical.  IOW:  if you have 5 identical circles in your drawing,
they will all use a single dictionary reference.  RE3D will ignore any/all objects defined in this way.

RE3DFixUp simply reads through the input file looking for any occurance of these "dictionary" objects and then uses the associated
Dictionary and Page info to create a record which matches the older data format (without a dictionary reference).

More Info:

By examination of the internal file header ("PK"), XPS files are simply ZIP archives.  Change the extension from .XPS to .ZIP
and you can extract all the Human-Readable files and folders which make up a single XPS File.  The actual drawing "Pages" are defined in
"\Documents\1\Pages\*.fpage" files and those files can/will reference entity definitions in a "\Resources\_D1.dict" file. If you
compare the fpage entry of a single unique entity (which does not use/require a Dictionary entry), an fpage entry for a
duplicated entity (which DOES use a dictionary entry), and the associated Dictionary entry for the duplicated entity, its fairly obvious
how the data in the dictionary entry can be used to reconstruct a standalone fpage entry for the object.  This is effectively what
RE3DFixUp does.

Usage:  

- Instead of printing directly to the "Full Spectrum Laser Print Driver", choose the "Microsft XPS Print Driver" instead
- Choose an output file extension (data format) of *.XPS (NOT the default *.OXPS)
- Optionally, you can install the free "Microsoft XPS Viewer" (recommended) to confirm the integrity of your output file
- Run RE3DFixup and select your XPS output file for processing.  This will generate a new file named *_RE3DFixed.XPS.
- Use the File -> Load option of RE3D to load that new file into RE3D

Options:

- If you want to see whats happening in more detail, you can create a single INI file named RE3DFixUp.ini in the same folder as 
  RE3DFixUp.exe.  In that file create a section named "[Config]" and create a single key named "TempFolder".  Set the value of
  that key to a folder you would like to use to store/preserve the original XPSInput architecture and the new XPSOutput architecture.
  For Example:
  
  [Config]
  TempFolder="C:\Temp\RE3dFixup"
  
  Normally, RE3DFixup uses the standard Windows User Temp Folder architecture for its work, but if you want to preseve the before/after
  contents of your XPS files then this is a simple way to do that.  (Note that if the "XPSInput" or "XPSOutput" subfolders exist, their
  contents will be completely replaced!!)
  
  If you want to manually adjust/test/tweak the contents of your XPSOutput folder, just remember all you need to do is zip up the contents
  of that folder and rename the resulting zip file to *.XPS.  You can confirm the integrity of your updates by using the 
  Microsoft XPS Viewer and/or RE3D itself.
  
  Notes:
  
  I expect we are pretty early on in identifying ALL the ramifications of the XPS update.  However, this utility solved all the problems
  I had encountered in my test cases.  It would be foolish to expect we are not going to find any more along the way.  Hopefully
  this utility will be helpful to some FSL Customers (unlike the company itself)...
