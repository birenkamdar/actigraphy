*** ACTIGRAPHY IMPORT & APPEND DO FILE **

**  Created August 2015 by Biren Kamdar, MD, MBA, MHS
**  Modified June 2024 by Onyeka Ezeokeke & Janelle Fine
**  Modified October 2024 by Biren Kamdar, MD, MBA, MHS

*** NOTE #1: CSV FILES
*   This do-file assumes that Actiwatch device data has already been downloaded as *.csv files using Actiware, and saved in a directory.
*   If your activity data has not yet been exported from Actiware, see the instructions in Appendix A below.

*** NOTE #2: COMMANDS TO INSTALL
*   This do-file uses the "dropmiss" command. To install, type the following 2 rows into the STATA command window:
*   net from http://www.stata-journal.com/software/sj15-4
*   net install dm0085

*** NOTE #3: STATA UPDATES
*   You may need to update STATA before running commands below, to update type: “update all”

**  YOU ARE READY TO GO! TO START:

**  Change directory to location of the the raw *.csv files 
*     In STATA, click 'File > Change Working Directory' and highlight and select the folder containing your actigraphy *.csv files
*     To dive into this directory again using this do file, copy the 'cd "FOLDER_NAME"' command from STATA and paste this 
*     command into line 27, without the quotation marks:
     
**** Folder containing *.csv files:
cd CALM-J1001_6_7_2021_4_17_00_PM_New_Analysis.csv


* Clear any data previously loaded
clear

* Start a log that will save the STATA results window into the file "importlog.smcl"
log using importlog, replace

* Make a list "csvfilelist" of all *.csv files found in that directory
local csvfilelist : dir "." files "*.csv"

* Import loop: for each *.csv file in the list "csvfilelist," do the following steps. Repeat for all *.csv files. 
foreach csvfile of local csvfilelist {

* Import the *.csv file, comma delimited
import delimited `csvfile', delimiter(comma)

* Convert string variables into numeric variables. The "force" option replaces any non-numbers with "." missing values.
* This turns all of the text/header information at the top of the Actigraphy file into missing values, and then the lines with missing values are dropped, leaving only the actual numerical data in the file.
destring v1,replace force
drop if  v1==.

* Drop any columns that contain only missing data
dropmiss,force

* The columns are imported with generic names v1, v2, v3, etc. Rename as the actual variable names
rename v1  line
rename v2  epoch
rename v3  day
rename v4  seconds
rename v5  date
rename v6  time
rename v7  offWrist
rename v8  activity
rename v9  marker
rename v10 whitelight
rename v11 redlight
rename v12 greenlight
rename v13 bluelight
rename v14 sleepwake
rename v15 mobility
rename v16 intervalstatus
rename v17 sleepwakestatus

* All variables are imported as strings. Convert the following list into numbers
foreach   X in line epoch day seconds offWrist marker whitelight redlight greenlight bluelight sleepwake mobility {
destring `X',replace force
}


* "gettoken" gets the file name (csvfile) which is then put into a variable "dtafile"
gettoken dtafile : csvfile
display "dtafile is `dtafile'"
generate dtafile = "`dtafile'"

** Save *.dta files, one per raw *.csv file with the same name
save `csvfile'.dta,replace
clear

* End of import loop. Go back to the top and repeat for the next *.csv file until all have been processed
}

*** APPENDING FILES ***

* Make a list "dtafilelist" of all *.dta files found in the current directory
local dtafilelist : dir "." files "*.dta"

* Append loop: for each *.dta file in the list "dtafilelist," append to the current data. Repeat for all *.dta 
*    files, ending up with one single file containing all of the data
foreach dtafile of local dtafilelist {	
append using `dtafile',nolabel force
}

* Format date and time from strings into usable dates and times
gen date1=date(date, "MD20Y")
format date1 %td
drop date
rename date1 date
gen time1=clock(time, "hms")
format time1 %tcHH:MM:SS
drop time
rename time1 time

* Put the filename, date, and time in the first columns for easy identification of what data is in that line
order dtafile date time, first

* Drop variables that are not needed. Note: Remove any variables from this list that you want to keep
drop marker whitelight redlight greenlight bluelight sleepwake mobility intervalstatus sleepwakestatus

* Change back to the directory containing the do file, and save the data. 
*    The filename is a generic "appended_data.dta," rename it afterwards if you would like a more descriptive name
cd ..
save appended_data.dta,replace

* Close log
log close


/* 

* -----------------------------------------
* APPENDICES 
* -----------------------------------------

*** APPENDIX A: EXPORTING FILES FROM ACTIWARE INTO *.csv FILES ***

1.  In the Actiware software, go to Tools > Options
2.  Click on the "Data List" tab
3.  Click "Select All" to select all variables (this is not the default, so it is very easy to export data with
      missing variables if this step is missed)
4.  Click on the "Export" tab
5.  Click on "Select All" 
6.  Click "OK"
7.  Go to Tools > Text File Export Batch
8.  Click "Next" at the verification of which database is open
9.  Choose "Individual Export Text Files" for the type of output you would like
10. Verify the folder into which you would like the *.csv files to go, and click "Browse" to choose a different 
      location if needed. 
11. Click "Next"
12. Choose which files/subjects you would like to export - you can click them individually or click "Select All"
13. Click "Next"
14. Leave "Suppress Error Messages" and "Overwrite Existing Files" unchecked and click "Next"
15. The export of the selected files will process, click "OK" when all are complete
16. Click "Finish"



*** APPENDIX B: ACTIGRAPHY FILE NAMING CONVENTION ***
   Make sure that all file names follow the same syntax when you activate the device. For example, include the subject number, wrist/ankle, and study site in the "Identity" field.

EXAMPLE = “subj101_wrist_left_xxxxx.csv”

   NOTE: Philips *.csv files have a 25-character limit, so keep identifiers concise.
   
  Helpful Tips: 
* * * Consistent Naming Syntax for Subject ID: Make sure that the subject "Identity" (i.e., subject ID) entered during device activation follows a consistent syntax. You can include information such as which wrist (left or right) or other relevant details in the file name. This is important for creating variables (e.g., left/right, wrist/ankle) based on the subject ID in the file name.
    Action: Use STATA commands such as ‘substr’ and ‘strmatch’ to extract specific information from the file name (like wrist position).
    
    See APPENDIX C for instructions on adding multiple variables (e.g., wrist position) from the *.csv file name if needed.



*** APPENDIX C: Using "substr" and "strmatch" to generate variables from the filename ***

   The Actiware software puts the subject "Identity" entered at the time of watch activation at the beginning of the output filename. So if information such as subject, left/right, wrist/ankle, or study site are made a part of this subject identifier when the watch is activated, that information will all be available in the filename and can be teased out into their own variables. The filename is contained in the variable "dtafile." 

 We will use the example filename "12345_LW_UCSD_6_16_2021_9_30_00_AM_New_Analysis," with "12345_LW_UCSD" 

   used as the subject identifier when activating the watch in the Actiware software. The following information 

   is contained: Subject ID = 12345, L/R = left, W/A = wrist, site = UCSD.

 "substr" takes apart a string of characters by counting and "collecting" characters
 "strmatch" searches a string for a given group of characters
  
 Subject ID: In our example, the subject ID is the first 5 characters of the filename (12345). 
   The substr command counts to the 1st character in "dtafile," and collects 5 characters to generate id = 12345.
   The following line and others below can be copied & pasted into this do-file or into the command window:
 generate id = (substr(dtafile,1,5))

 Left/Right Wrist/Ankle: Left/right is an "L" or "R" as the 7th character, and wrist/ankle is "W" or "A" as the
   8th character. The substr command counts to the 7th character and collects 1 character for L/R and to the 8th
   character and collects 1 character for W/A (these are "LW" in our example, indicating the left wrist).
 generate leftright=  (substr(dtafile,7,1))
 generate wristankle= (substr(dtafile,8,1))

  If you plan to use "substr" to put the Actiware subject ID information into variables, because it goes to a specific character count it is critical for the naming convention of your subject "Identity" entered at watch activation to use the exact same number of characters for all of your files. Then for your variables, count the number of characters to the information that you would like to extract and how many characters it uses, to tell "substr" what to collect. 
   
   Study Site: In the example filename, the study site is indicated by a group of letters ("UCSD"). In the example code below, other possible sites are shown as "ABC" and "DEF"
   The "strmatch" command searches the filename variable "dtafile" for the strings given. It is case-sensitive, so the codes are shown in both cases with the "or" symbol "|" to look for either one

 generate studysite=.
 replace  studysite=1 if (strmatch(dtafile,"*ucsd*"))|(strmatch(dtafile,"*UCSD*"))
 replace  studysite=2 if (strmatch(dtafile,"*abc*"))|(strmatch(dtafile,"*ABC*"))
 replace  studysite=3 if (strmatch(dtafile,"*def*"))|(strmatch(dtafile,"*DEF*"))


 
 *** APPENDIX D: Destringing activity ***
 
 Activity was not destrung in the loop in lines 73-76, to preserve the "NaN" values recorded by the watch when it is not recording activity, which happens when it senses that it is not on a wrist. 
 If you would like to destring activity (the "NaN" strings will change to missing values "."), you can copy and paste the following line into the code at line 77, or into the command window after running this do file:
 destring activity,replace force



* APPENDIX E: Handling Non-Numeric Data ("NaN"):
  If the actigraphy file contains “NaN” values (Not a Number) instead of blanks, STATA will import these as "strings" (text).
 This will prevent numerical analysis of the activity variable.
 
   Action: Convert “NaN” values to either numeric values (like zeros) or blank cells. To clean this in STATA, use the 'destring' command: 
  destring activity, force replace


* APPENDIX F: Exporting Final Dataset
   Once you have appended all individual *.csv files into a single STATA dataset (*.dta), you may need to export it for analysis in other programs.
   Action: In the STATA command window, use the Export > Text File command to save the data as a *.csv file. Alternatively, use Export > Data to Excel Spreadsheet to save it as an *.xls file.


*/
