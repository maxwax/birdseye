#!/bin/bash
#
# birdseye.sh
#
# 2013 Maxwell Spangler, maxwell@maxwellspangler.com
#
# Birdseye creates a simple, well-presented HTML based report of a Linux
# systems hardware, software and configuration details.
# See http://www.maxwellspangler.com/linux/birdseye for more information.

# Version number set here: date produced plus a daily sequence version
VERSION="2013.0615.02"

# 2013.0615.02
#	Added -date option for --month and --year
#	Added -e --email options for command line handling of email
# 2013.0615.01
#	Removed old changelog, switched to date versioning
#	Fixing prompt in new email parameter (has name not email)
#	Removed commented out echo -n + read method for read -p

# Bash variable UID returns the user id # of the user
# Running as root, or running this script using sudo should return user 0
if [ $UID != 0 ]
then
	echo "You must be root or use 'sudo' to run birdseye."
	exit 1
fi

###########################################################
# functions
###########################################################

# Output a string of text to the html file
# with no line break so multiple strings can be placed on one line
function string {
	echo -n -e "${1}" >> $HTML
}

# Output a string of text to the html file
# with a trailing line break for readability
function line {
	echo -e "${1}" >> $HTML
}

# Output a string of text to the html file
# Wrap it in <p> so it can be styled as a line
function paragraph {
	echo -e "<p>${1}</p>" >> $HTML
}

# Output a bullet (<li>) entry 
# with a section reference ($1) and a text string ($2)
function list {
	echo -e "<li><a href=\"#$1\">$2</a></li>" >> $HTML
}

# Output a section header *for the table of contents* (<h2>)
# with a named anchor ($1) and a text string ($2)
function toc_section {
	echo -e "<h2><a name=\"$1\"><a href=\"$3\">$2</a></a></h2>" >> $HTML
}

#toc_section "<a name=\"toc_inter\"></a><a href=\"#section_inter\">Interrupts</a>" >> $HTML

# Output a section header *for detail reporting (non-toc!)* (<h2>)
# with a named anchor ($1) and a text string ($2)
function section {
	echo -e "<h2><a name=\"$1\">$2</a> <a href="#top" class="boxtop">Top</a></h2>" >> $HTML
}

# <h2> <a name=section_overview"

# Output a title to a single piece of data being reported
# with an anchor ($1) and a text string ($2)
function title {

	RAW_CMD=${3:-"null"}

	# If a third parameter has been passed, put it in parenthesis
	# without bold 
	if [[ $RAW_CMD != "null" ]]
	then
		echo -e "<h3><a name=\"$1\">$2 <span class=h3nobold>($3)</span></a> <a href="#top" class="boxtop">Top</a></h3>" >> $HTML
	else
		echo -e "<h3><a name=\"$1\">$2</a> <a href="#top" class="boxtop">Top</a></h3>" >> $HTML
	fi
}

# Output a subtitle to a single piece of data being reported
# with an anchor ($1) and a text string ($2)
function subtitle {

	RAW_CMD=${3:-"null"}

	# If a third parameter has been passed, put it in parenthesis
	# without bold 
	if [[ $RAW_CMD != "null" ]]
	then
		echo -e "<h4><a name=\"$1\">$2 <span class=h4nobold>($3)</span></a></h4>" >> $HTML
	else
		echo -e "<h4><a name=\"$1\">$2</a></h4>" >> $HTML
	fi
}

# Output a simple unordered list tag <ul> with optional class info
function unordered_list_open {
	echo -e "<ul $1>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function unordered_list_close {
	echo -e "</ul>" >> $HTML
}

# Output a simple unordered list tag <ul> with optional class info
function raw_open {
	echo -e "<pre class=\"PROGRAMLISTING\">" >> $HTML
}

# Output a simple unordered list tag <ul> with optional class info
function raw_close {
	echo -e "</pre>" >> $HTML
}

# Output a simple unordered list tag <ul> with optional class info
function textarea_open {
	echo -e "<textarea readonly wrap=hard cols=\"$1\" rows=\"$2\">" >> $HTML
}

# Output a simple unordered list tag <ul> with optional class info
# "</p> afterwards adds a little extra space before the next line
function textarea_close {
	echo -e "</textarea></p>" >> $HTML
}

# Output a simple unordered list tag <ul> with optional class info
function helpful_tip {
	echo -e "<div class=\"tip\">" >> $HTML
	echo -e "<blockquote class=\"tip\">" >> $HTML
	echo -e "$1" >> $HTML
	echo -e "</blockquote>" >> $HTML
	echo -e "</div>" >> $HTML
}

########################################################################
# Default Variable Handling 
########################################################################

# BIRDSEYE_ variables listed here are set to default values
# If a config file is found, any or all of these values may be
# overwritten.  Later code references these values regardless
# of whether their values come from these settings or an
# external configuration file.
export BIRDSEYE_TAG=""
export BIRDSEYE_NAME=""
export BIRDSEYE_EMAIL=""
export BIRDSEYE_GROUP=""
export BIRDSEYE_ISSUE=""
export BIRDSEYE_CFG_NOTES=""

export BIRDSEYE_FILENAME_DATE="no"
export BIRDSEYE_FILENAME_MONTH="no"
export BIRDSEYE_FILENAME_TIME="no"
export BIRDSEYE_FILENAME_HOST="no"
export BIRDSEYE_FILENAME_TAG="yes"

export BIRDSEYE_OUTPUT_FORCE="no"
export BIRDSEYE_PUBLIC_REPORT="no"
export BIRDSEYE_PROMPT_USER="yes"
export BIRDSEYE_CSS_FILE="no"
export BIRDSEYE_PUBLIC_REPORT="no"

# If a config file exists in the user's home directory, execute
# it to set BIRDSEYE_ variables and perform any user supplied processing
if [ -f $HOME/.birdseye.cfg ]
then
	echo "Using in $HOME/.birdseye.cfg:"
	. $HOME/.birdseye.cfg

	echo "Tag   $BIRDSEYE_TAG"
	echo "Name  $BIRDSEYE_NAME"
	echo "Email $BIRDSEYE_EMAIL"
	echo "Group $BIRDSEYE_GROUP"
	echo "Issue $BIRDSEYE_ISSUE"
	echo "Notes $BIRDSEYE_CFG_NOTES"
	echo
fi

# DEF_ variable are used later in processing the report
# Values are set to one of three sources:
# 1. The 'export BIRDSEYE_' lines above (empty values)
# 2. BIRDSEYE variable definitions in a user's .birdseye.cfg file
# 3. Default values set here
# In most cases, there is no config file, so these defaults are used.

DEF_TAG=${BIRDSEYE_TAG:-"birdseye"}
DEF_NAME=${BIRDSEYE_NAME:-"Unknown User"}
DEF_EMAIL=${BIRDSEYE_EMAIL:-"Unknown Email Address"}
DEF_GROUP=${BIRDSEYE_GROUP:-"Unknown Group"}
DEF_ISSUE=${BIRDSEYE_ISSUE:-"No issue specified."}
DEF_CFG_NOTES=${BIRDSEYE_CFG_NOTES:-"No configuration notes."}

DEF_CSS_FILE=${BIRDSEYE_CSS_FILE:-"internal"}

PUBLIC_REPORT=$BIRDSEYE_PUBLIC_REPORT
PROMPT_USER=$BIRDSEYE_PROMPT_USER

# default options for output filename.
# Use options from config file if possible (see above)
FILENAME_YEAR=$BIRDSEYE_FILENAME_YEAR
FILENAME_MONTH=$BIRDSEYE_FILENAME_MONTH
FILENAME_TIME=$BIRDSEYE_FILENAME_TIME
FILENAME_HOST=$BIRDSEYE_FILENAME_HOST
FILENAME_TAG=$BIRDSEYE_FILENAME_TAG

OUTPUT_FORCE=$BIRDSEYE_OUTPUT_FORCE

########################################################################
# Command Line : Syntax
########################################################################

# Display syntax
function usage {
	echo "Bird's Eye $VERSION"
	echo
	echo "usage: birdseye <options>"
	echo
	echo "-p --public  Produce a secure report with no IP networking or firewall info."
	echo "-q --quick   Don't prompt the user for tag and title information."
	echo "-d --debug   Enable debugging output."
	echo
	echo "-t --tag     Specify a tag to be included in the filename. 'rhel73' 'vers5hw'"
	echo "-n --name    Specify the name of the user producing this report. 'Lloyd Dobler'"
	echo "-e --email   Specify the email address of the user producing this report."
	echo "-g --group   Specify the group this report is associated with. 'Triage'"
	echo "-i --issue   Specify an issue being investigated. 'Network Fault'"
	echo "-h --hwnotes Specify a note about this hardware config. '1/2 cpus diabled'"
	echo
	echo "   --date    Include year and month in filename"
	echo "   --dt      Include year and month and 24-hour time in filename"
	echo
	echo "   --year    Include year in filename"
	echo "   --month   Include month & day in filename"
	echo "   --time    Include 24-hour format time in filename"
	echo "   --host    Include system's hostname in filename"
	echo "   --notag   Do not include report tag in filename (Default: include)"
	echo "   --force   Overwrite an existing output directory if it exists."
	echo

# future option?
#	echo "-c --css     Use an external CSS style file's contents '/home/user/style.css'"

# future option?
#	echo "-o --output  Specify the output filename."

}

########################################################################
# Command Line : Processing
########################################################################

while [ "$1" != "" ]
do

	# Process the next command line argument
	case $1 in 

		# Examine $1 for a command line parameter
		# If the parameter is identified set a value to be used later
		# If the parameter requires an option, 'shift' so $1 is the option
		# Process the option
		# After this case block, shift again so the next parameter is $1

		# enable debugging output
		-d | --debug )
			DEBUG="yes";;

		# produce a report without IP and firewall information 
		# that might lead to intrusion
		-p | --public )
			PUBLIC_REPORT="yes";;

		# don't prompt the user for information, just run it using defaults
		-q | --quick )
			PROMPT_USER="no";;

		# Include 24-hour format time in output filename
		--time )
			FILENAME_TIME="yes";;

		# Same as --month and --year : include date - convenience
		--date )
			FILENAME_YEAR="yes"
			FILENAME_MONTH="yes";;

		# Same as --month and --year : include date - convenience
		--dt )
			FILENAME_TIME="yes"
			FILENAME_YEAR="yes"
			FILENAME_MONTH="yes";;

		# Include YYYY format date in output filename
		--year )
			FILENAME_YEAR="yes";;

		# Include MMDD format date in output filename
		--month )
			FILENAME_MONTH="yes";;

		# Include hostname in output filename
		--host )
			FILENAME_HOST="yes";;

		# Don't include the tag in the output file
		--notag )
			FILENAME_TAG="no";;

		# Include hostname in output filename
		--force )
			OUTPUT_FORCE="yes";;

		# command line parameter: specify the output tag
		-t | --tag )
			shift
			DEF_TAG=$1;;

		# command line parameter: specify user's name in quotes
		-n | --name )
			shift
			DEF_NAME=$1;;

		# command line parameter: specify the user's email address
		-e | --email )
			shift
			DEF_EMAIL=$1;;

		# command line parameter: specify the user's group or team
		-g | --group )
			shift
			DEF_GROUP=$1;;

		# command line parameter: specify the issue being investigated
		-i | --issue )
			shift
			DEF_ISSUE=$1;;

		# command line parameter: specify notes on the hw configuration
		-h | --hwnotes )
			shift
			DEF_CFG_NOTES=$1;;

		# command line parameter: future option, specify output filename
		-o | --output )
			shift
			DEF_OUTPUT=$1;;

		# command line parameter: specify external CSS style file
		-c | --css )
			shift
			DEF_CSS_FILE=$1;;

		# Something we don't understand? show syntax and exit
		* )
		usage
		exit 1;;
	esac
	shift
done

########################################################################
# Debug only: Report DEF_ Variables
########################################################################

# If the DEBUG option was set, let's report some basic values here.
if [[ $DEBUG == "yes" ]]
then
	echo "Values after parameter processing:"
	echo "DEBUG PUBLIC_REPORT $PUBLIC_REPORT"
	echo "DEBUG PROMPT_USER $PROMPT_USER"
	echo "DEBUG DEF_OUTPUT $DEF_OUTPUT"
	echo "DEBUG DEF_CSS_FILE $DEF_CSS_FILE"
	echo
	echo "DEBUG DEF_TAG $DEF_TAG"
	echo "DEBUG DEF_NAME $DEF_NAME"
	echo "DEBUG DEF_EMAIL $DEF_EMAIL"
	echo "DEBUG DEF_GROUP $DEF_GROUP"
	echo "DEBUG DEF_ISSUE $DEF_ISSUE"
	echo "DEBUG DEF_CFG_NOTES $DEF_CFG_NOTES"
	echo
fi

###########################################################
# Prompt user for tag / name / email / group /issue / hw_notes
###########################################################

if [[ $PROMPT_USER == "no" ]]
then
	# set the working variables to the defaults
	MY_TAG=${DEF_TAG:-"null"}
	MY_NAME=${DEF_NAME:-"null"}
	MY_EMAIL=${DEF_EMAIL:-"null"}
	MY_GROUP=${DEF_GROUP:-"null"}
	MY_ISSUE=${DEF_ISSUE:-"null"}
	MY_CFG_NOTES=${DEF_CFG_NOTES:-"null"}
else

	####################
	read -p "Provide a short tag to include with this [$DEF_TAG] ?" MY_TAG

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_TAG=${MY_TAG:-"null"}

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [[ "$MY_TAG" != "null" ]] && [[ X"$MY_TAG" != X ]]
	then

		# Make this tag command line friendly by removing spaces
		MY_TAG=${MY_TAG//[[:space:]]/}

	else	
		# Make this tag command line friendly by removing spaces
		MY_TAG=${DEF_TAG//[[:space:]]/}
	fi

	####################
	read -p "What's your name [$DEF_NAME] ?" MY_NAME

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_NAME=${MY_NAME:-"null"}

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [ "$MY_NAME" != "null" ]
	then
		# redundant - this block is a template for future processing 

		# quote required - spaces will be included!
		MY_NAME="$MY_NAME"
	else	
		# quote required - spaces will be included!
		MY_NAME="$DEF_NAME"
	fi

	####################
	read -p "What's your email address [$DEF_EMAIL] ?" MY_EMAIL

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_EMAIL=${MY_EMAIL:-"null"}

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [ "$MY_EMAIL" != "null" ]
	then
		# redundant - this block is a template for future processing 

		# quote required - spaces will be included!
		MY_EMAIL="$MY_EMAIL"
	else	
		# quote required - spaces will be included!
		MY_EMAIL="$DEF_EMAIL"
	fi

	####################
	read -p "What group are you in (linuxqa,io,aps?) [$DEF_GROUP] ?" MY_GROUP

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_GROUP=${MY_GROUP:-"null"}

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [ "$MY_GROUP" != "null" ]
	then
		# redundant - this block is a template for future processing 

		MY_GROUP="$MY_GROUP"
	else	
		MY_GROUP="$DEF_GROUP"
	fi

	####################
	echo -e "A simple description for the issue being reported [$DEF_ISSUE] ?"
	read -p ":" MY_ISSUE

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_ISSUE="${MY_ISSUE:-"null"}"

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [ "$MY_ISSUE" != "null" ]
	then
		# redundant - this block is a template for future processing 

		# quote required - spaces will be included!
		MY_ISSUE="$MY_ISSUE"
	else	
		# quote required - spaces will be included!
		MY_ISSUE=$DEF_ISSUE
	fi

	####################
	echo -e "Notes about the system configuration? [$DEF_CFG_NOTES]"
	read -p ":" MY_CFG_NOTES

	# Keep a valid, non-null user supplied value or set it to "null"
	MY_CFG_NOTES="${MY_CFG_NOTES:-"null"}"

	# If the user value is not "null" and not "" then process it
	# otherwise, set it to the DEF_TAG value set earlier in the script
	if [ "$MY_CFG_NOTES" != "null" ]
	then
		# quote required - spaces will be included!
		MY_CFG_NOTES="$MY_CFG_NOTES"
	else	
		# quote required - spaces will be included!
		MY_CFG_NOTES="$DEF_CFG_NOTES"
	fi

fi

###########################################################
# Debug: Let's report our processed values
###########################################################

if [[ $DEBUG == "yes" ]]
then
	echo "Values after interactive prompting:"
	echo "DEBUG MY_TAG $MY_TAG"
	echo "DEBUG MY_NAME $MY_NAME"
	echo "DEBUG MY_EMAIL $MY_EMAIL"
	echo "DEBUG MY_GROUP $MY_GROUP"
	echo "DEBUG MY_ISSUE $MY_ISSUE"
	echo "DEBUG MY_CFG_NOTES $MY_CFG_NOTES"
	echo
fi

###########################################################
# Construct and output filename from various option settings
###########################################################

# slow, sometimes hostname only not FQDN
#MY_HOST=`hostname`

# fast, FQDN?
MY_HOST=$HOSTNAME

# Default prefix for all output filenames
FILENAME_DATA="birdseye"

# Append hostname to filename ?
if [[ $FILENAME_HOST == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.$MY_HOST
fi

# Append the user's tag to the filename?
if [[ $FILENAME_TAG == "yes" ]]
then
	FILENAME_DATA="$FILENAME_DATA.$MY_TAG"
fi

# Append year ("YYYY" format) to filename?
if [[ $FILENAME_YEAR == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%Y`
fi

# Append month-day ("MMDD" format) to filename?
if [[ $FILENAME_MONTH == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%m%d`
fi

# Append 24-hour time ("HHMM" format) to filename?
if [[ $FILENAME_TIME == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%H%M`
fi

# Set the working variable for the output directory to our constructed 
# output filename template
export OUTPUT_DIR="$FILENAME_DATA"

# Does the output directory exist? 
if [[ -d $OUTPUT_DIR ]]
then
	# If we haven't been told to force it, don't overwrite what might
	# be important existing data that can't be recreated
	if [[ $OUTPUT_FORCE == "no" ]]
	then
		echo "Directory $OUTPUT_DIR exists. Please remove or use --force"
		exit
	else
		echo "Directory $OUTPUT_DIR exists, using --force to replace it."
		# I'm paranoid about using 'rm -f' with a variable (especially as 
		# root) So we'll keep the existing directory and remove only the
		# old files that might conflict with THIS report.
		# Other files in the existing directory are kept 

		rm -f $OUTPUT_DIR/*.txt birdseye.$FILENAME_DATA.tar birdseye.$FILENAME_DATA.tar.gz
	fi
else # Our output directory does NOT exist

	# Let's try to make a new output directory
	mkdir $OUTPUT_DIR

	# Did we succeed?
	if [ $? != 0 ]
	then
		echo "Can't make $OUTPUT_DIR"
		exit
	fi
fi

# HTML is the name of our often used HTML format output file
HTML="$OUTPUT_DIR/$FILENAME_DATA.html"

# These additional ASCII files contain raw output and many users
# wish to have them seperate for processing with 'grep' and other
# programs.
FILENAME_DMI=dmidecode.$FILENAME_DATA.txt
FILENAME_CPU=cpuinfo.$FILENAME_DATA.txt
FILENAME_MSGS=messages.$FILENAME_DATA.txt
FILENAME_DMESG=dmesg.$FILENAME_DATA.txt
FILENAME_DMESG_NOTIME=dmesg-notime.$FILENAME_DATA.txt
FILENAME_INTER=interrupts.$FILENAME_DATA.txt
FILENAME_PCI=lspci.$FILENAME_DATA.txt
FILENAME_INITRD=initrd.$FILENAME_DATA.txt

FILE_DMI=$OUTPUT_DIR/$FILENAME_DMI
FILE_CPU=$OUTPUT_DIR/$FILENAME_CPU
FILE_MSGS=$OUTPUT_DIR/$FILENAME_MSGS
FILE_DMESG=$OUTPUT_DIR/$FILENAME_DMESG
FILE_DMESG_NOTIME=$OUTPUT_DIR/$FILENAME_DMESG
FILE_INTER=$OUTPUT_DIR/$FILENAME_INTER
FILE_PCI=$OUTPUT_DIR/$FILENAME_PCI
FILE_INITRD=$OUTPUT_DIR/$FILENAME_INITRD

###########################################################
# Set Traps: If the user cancels with control-c we'll use this to cleanup
###########################################################

trap "{ rm -r $OUTPUT_DIR $OUTPUT_DIR.tar $OUTPUT_DIR.tar.gz; exit 255 }" SIGINT SIGQUIT SIGTERM

###########################################################
# Empty the contents of each file with a simple echo statement
###########################################################

# Originally this was used to place a header on each file
# Emptying files now allows ALL future work to be a simple
# append output to each file
for EACH_FILE in \
	$HTML $FILE_DMI $FILE_CPU $FILE_MSGS $FILE_DMESG $FILE_DMESG_NOTIME \
	$FILE_INTER $FILE_PCI $FILE_INITRD
do
	echo -n > $EACH_FILE
done

###########################################################
# Processing: What distribution are we using?
#
# This will be important as we handle distribution-specific quirks
###########################################################

# Distribution: fedora, redhat, oracle, centos, suse, ubuntu
MY_DIST="null"

# Release version "5", "6", "11SP3"
MY_RELEASE="null"

# Release Family: "redhat" = (redhat, oracle, centos)
MY_DIST_FAMILY="null"

# Fedora contains fedora-release and redhat-release
# Oracle main contain oracle-release and redhat-release as well
#
# So, look for fedora first, set it and skip the others if found
# If not fedora, check for oracle, then redhat and others

if [ -f /etc/fedora-release ]
then
	MY_DIST="fedora"

	if [ `cat /etc/fedora-release | grep "release 16" | wc -l` -gt 0 ]
	then
		MY_RELEASE=16
	elif [ `cat /etc/fedora-release | grep "release 17" | wc -l` -gt 0 ]
	then
		MY_RELEASE=17
	elif [ `cat /etc/fedora-release | grep "release 18" | wc -l` -gt 0 ]
	then
		MY_RELEASE=18
	elif [ `cat /etc/fedora-release | grep "release 19" | wc -l` -gt 0 ]
	then
		MY_RELEASE=19
	fi

elif [ -f /etc/oracle-release ]
then
	MY_DIST="oracle"
	MY_DIST_FAMILY="redhat"

	if [ `cat /etc/oracle-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_RELEASE=5
	elif [ `cat /etc/oracle-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_RELEASE=6
	fi

elif [ -f /etc/centos-release ]
then
	MY_DIST="centos"
	MY_DIST_FAMILY="redhat"

	if [ `cat /etc/centos-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_RELEASE=5
	elif [ `cat /etc/centos-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_RELEASE=6
	fi

elif [ -f /etc/redhat-release ]
then
	MY_DIST="redhat"
	MY_DIST_FAMILY="redhat"

	if [ `cat /etc/redhat-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_RELEASE=5
	elif [ `cat /etc/redhat-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_RELEASE=6
	fi

elif [ -f /etc/SuSE-release ]
then
	MY_DIST="suse"
	MY_DIST_FAMILY="suse"

	if [ `cat /etc/SuSE-release | grep "Server 11" | wc -l` -gt 0 ]
	then
		MY_RELEASE="11"
	elif [ `cat /etc/SuSE-release | grep "Server 10" | wc -l` -gt 0 ]
	then
		MY_RELEASE="10"
	fi
	
fi

###########################################################
# LET'S GO: Produce the Report
###########################################################

line "<html>"

line "<head><title>Birdseye Report for $MY_HOST</title>"

#----------------------------------------------------------
# CSS STYLE SHEET for presentation
#----------------------------------------------------------

# future option, not tested yet
#if [[ $DEF_CSS_FILE != "null" ]] && [ -f "$DEF_CSS_FILE" ]
#then
#	cat "$DEF_CSS_FILE" >> $HTML
#else
	
cat >> $HTML << CSS-STYLE-SCRIPT
<style type="text/css">

body {
	/* chosen font */
	font-family: lucida, myriad pro, myriad, verdana, sans-serif;

	/* text color */
	color: #000;

	/* page color */
	background-color: #fff;

	/* white spage on left and right of page */
	margin-left: 25px;
	margin-right: 25px;

	/* font size, adjust to smaller at 93% for alternate look */
	font-size: 100%;
}

/* Heading Definitions */

/* Common settings to all heading styles */
h1, h2, h3, h4, h5, h6 {
	margin: 0 0 5px 0;
}

/*
	This is an example of how heading styles are used and how they
	are called using bash functions within birdseye

	function      h?  Example             Description
	n/a           h1 "Birdseye Report"    Report Title
	toc_section{} h2 "Hardware Summary"   Titles a section of TOC items
	section{}     h2 "Hardware Summary"   Titles a section of information
	title{}       h3 "Product Name"       Title for an item of data
	subtitle{}    h4 "Product Model"      Supplementary item of data

*/

/* Major heading : Used on top of report for title */
h1 {
  font-size: 1.8em;
  font-weight: bold;
  color: #3c6eb4;
}

/* Section heading: Used to separate sections */
h2 {
  font-size: 1.5em;
  font-weight: bold;
  color: #3c6eb4;
  text-decoration: underline;
}

/* Used as a title for each item of information being reported */
h3 {
  font-size: 1.2em;
  font-weight: bold;
  color: #3c6eb4; 
}

/* Used as a title for each sub-item of information being reported */
h4 {
  font-size: 0.95em;
  font-weight: bold;
}

/* Used to show raw commands in title without the title's bold */
.h3nobold {
	font-weight: underline;
	font-family: "Lucida Console", "Lucidatypewriter", "Fixed", "Andale Mono", "Courier New", "Courier"
}

/* Used to show raw commands in title without the title's bold */
.h4nobold {
	font-weight: normal;
	font-family: "Lucida Console", "Lucidatypewriter", "Fixed", "Andale Mono", "Courier New", "Courier"
}

/* Hovering over the link to the Birdseye Landing page */
h1 a:hover {
  color: #EC5800;
  text-decoration: none;
}

/* Hovering over a heading that links to something */
h2 a:hover,
h3 a:hover,
h4 a:hover {
  color: #666666;
  text-decoration: none;
}

/* Lists */
ol, ul, li {
  margin-top: 0.2em;
  margin-bottom: 0.1em; 
}

/* Overall Link Styles */
a:link      { color:#3c6eb4; text-decoration: none; }
a:visited   { color:#004E66; text-decoration: underline; }
a:active    { color:#3c6eb4; text-decoration: underline; }
a:hover     { color:#000000; text-decoration: underline; }

/* Text Styles */
p, ol, ul, li {
  line-height: 1.0em;
  font-size: 1.0em;
  margin: 2px 0 8px 0px;
}

/* This makes a little box with the word "Top" in it that takes the user
   back to the top of the page */
.boxtop {
  background-color: rgb(214,227,255);
  border-width: 1px;
  border-style: solid;
  border-radius: 8px;
  border-color: #CFCFCF;
  padding: 5px;
	font-size: 0.75em;
  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  box-shadow: 3px 3px 5px #DFDFDF;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
  margin: 0 0 0 1ex;
/*
  color: black;
  overflow: auto;
  background-color: #F7F7F7;
  width: 572px;
*/
}

/*
	Raw output data from commands,
	Presented as a box with soft, rounded corners, 3D shadowing, 
	A different background color,
	Uses a fixed width font to preserve raw output column formatting.
*/

.programlisting {

  border-width: 1px;
  border-style: solid;
  border-radius: 8px;
  border-color: #CFCFCF;
  background-color: rgb(238,232,213);
  padding: 12px;
/* changed to 0px 2013-01-27 looks better lined up on the left with everything else.  */
  margin: 0px 25px 20px 25px;
  overflow: auto;

  box-shadow: 3px 3px 5px #DFDFDF;
  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
}

blockquote.tip {

  background-color: #F5F298;
  color: black;

  border-width: 1px;
  border-style: solid;
  border-color: #DBDBCC;

  padding: 2ex;
  margin: 2ex 0 2ex 2ex;

  overflow: auto;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
  border-radius: 8px;

  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  box-shadow: 3px 3px 5px #DFDFDF;

}


</style>
CSS-STYLE-SCRIPT

#fi
# ABOVE: if/then/else handling ends for CSS external file & inline style

line "</head>"

#----------------------------------------------------------
# BODY of the report with content that matteres
#----------------------------------------------------------

line "<body>"

line "<h1><a name=\"Top\"><a href=http://www.maxwellspangler.com/linux/birdseye/>Bird's Eye</a> System Inventory for $MY_HOST</a></h1>" 

paragraph "Produced on `date "+%A, %B %d %Y at %H:%m"` by $MY_NAME ( $MY_EMAIL ) of $MY_GROUP"

if [[ $MY_ISSUE != "null" ]]
then
	paragraph "Issue <strong>$MY_ISSUE</strong>" 
else
	paragraph "Issue $MY_ISSUE" 
fi

if [[ $MY_CFG_NOTES != "null" ]]
then
	paragraph "Configuration Notes <strong>$MY_CFG_NOTES</strong>" 
	#paragraph "<strong>Configuration Notes</strong> $MY_CFG_NOTES" 
else
	paragraph "Configuration Notes $MY_CFG_NOTES" 
fi

paragraph "Capture File $OUTPUT_DIR"

line "<hr>"

line "<h2><a name=\"toc\">Table of Contents</a></h2>" 

line "<div class=\"toc_master\">"
paragraph "<a href=\"#toc_linux_summary\">Linux Overview</a>"
paragraph "<a href=\"#toc_hw_summary\">Hardware Overview</a>"
paragraph "<a href=\"#toc_cpuinfo\">Processor/CPU information</a>"
paragraph "<a href=\"#toc_inter\">Interrupts</a>"
paragraph "<a href=\"#toc_pci\">Expansion Cards (PCI, PCI-X, PCIe, etc)</a>"
paragraph "<a href=\"#toc_usb\">USB subsystem</a>"
paragraph "<a href=\"#toc_dmidecode\">System Board Information</a>"
paragraph "<a href=\"#toc_networking\">Networking</a>"
paragraph "<a href=\"#toc_storage\">Storage</a>"
paragraph "<a href=\"#toc_periphs\">Peripherals</a>"
paragraph "<a href=\"#toc_dmesg\">Boot messages</a>"
paragraph "<a href=\"#toc_messages\">Console/System Messages</a>"
paragraph "<a href=\"#toc_modules\">Kernel Modules</a>"
paragraph "<a href=\"#toc_udev\">udev configuration</a>"
paragraph "<a href=\"#toc_virt\">Virtualization</a>"
paragraph "<a href=\"#toc_sysctl\">System Control Parameters</a>"
paragraph "<a href=\"#toc_xwindows\">X-Windows</a>"
line "</div>"

line "<hr>"

line "<div class=\"toc_detail\">"

toc_section "toc_linux_summary" "Linux Summary" "#section_linux_summary"
unordered_list_open
list "item_hostname"		"System name (hostname)"
list "item_date"			"System date/time (date)"
list "item_uname"			"System identification (uname -a)"
list "item_issue"			"Distribution, Version (/etc/issue)"
list "item_lsb"				"Distribution, Release (lsb_release)"
unordered_list_close

toc_section "toc_hw_summary"  	"Hardware Summary" "#section_hw_summary"

unordered_list_open
list "item_product"			"Product Name (dmidecode -s system-product-name)"
list "item_processor_line"	"Processor Summary"
list "item_first_proc"		"First processor (cat /proc/cpuinfo)"
list "item_memsum"			"Memory (/proc/meminfo)"
list "item_bios_vendor"		"BIOS Vendor (dmidecode -s bios-vendor)"
list "item_bios_vers"		"BIOS Version (dmidecode -s bios-version)"
list "item_bios_date"		"BIOS Release Date (dmidecode -s bios-release-date)"
list "item_cmdline"			"Boot parameters (cat /proc/cmdline)"
list "item_lsinitrd" 		"initrd information (lsinitrd)"
unordered_list_close

toc_section "toc_cpuinfo"		"Processor/CPU information" "#section_processor"

unordered_list_open
list "item_proc_family"		"Processor Family (dmidecode -s processor-family)"
list "item_proc_vers"		"Processor Version (dmidecode -s processor-version)"
list "item_processor_lscpu"	"Processor Summary (lscpu, lscpu -e)"
list "item_processor_over"	"First Processor (cat /proc/cpuinfo)"
#list "item_processor"		"Processor (cat /proc/cpuinfo)"
list "item_numashow"		"NUMA Topology (numactl --show)"
list "item_numahw"			"NUMA Hardware topology (numactl --hardware)"
list "item_meminfo"			"Memory Info (cat /proc/meminfo)"
list "item_freemem"			"Free Memory (free)"
list "item_mtrr"			"MTRR (cat /proc/mtrr)"
unordered_list_close

toc_section "toc_inter"		"Interrupts" "#section_inter"

unordered_list_open
list "item_inter"			"Interrupts (cat /proc/interrupts)"
unordered_list_close

toc_section "toc_pci"		"Expansion Cards (PCI, PCI-X, PCIe, etc)" "#section_pci"

unordered_list_open
list "item_cards"			"Expansion cards (sutl cards)"
list "item_iomem"			"Peripheral IO memory (cat /proc/iomem)"
list "item_ioports"		"Peripheral IO ports (cat /proc/ioports)"
list "item_devices" 		"Devices (cat /proc/devices)"
list "item_lspci"			"PCI devices (lspci)"
list "item_lspcivv"		"PCI Devices Detail (lspci -vv)"
unordered_list_close

toc_section "toc_usb" "USB subsystem" "#section_usb"

unordered_list_open
list "item_lsusb"		"USB Devices (lsusb)"
list "item_lsusbpy"		"USB Devices Speed & Power (lsusb.py)"
list "item_lsusbv"		"USB Devices Detail (lsusb -v)"
list "item_lsusbt"		"USB Devices Tree (lsusb -t)"
unordered_list_close

toc_section "toc_dmidecode" "System Board Information" "#section_dmidecode"

unordered_list_open
list "item_dmidecode"		"System Board information (dmidecode)"
unordered_list_close

toc_section "toc_networking" "Networking" "#section_networking"

unordered_list_open
list "item_sutlnics"	"Network cards (sutl nics)"
list "item_nicinfo"		"Network port information (nic-info)"
list "item_nicports"	"Network port detail information (ifconfig, ethtool, ethtool -i)"
list "item_netstat"		"Network routing table (netstat)"
list "item_iproute"		"Network routing table (ip route)"
list "item_firewall"	"Firewall rules (iptables -L)"
unordered_list_close

toc_section "toc_storage"  	"Storage" "#section_storage"

unordered_list_open
list "item_sutlhbas"	"Host Bus Adapter information (sutl hbas)"
list "item_lsblk"		"Block Storage Devices (lsblk)"
list "item_lsscsi"		"SCSI Information (lsscsi)"
list "item_mount"		"Mounted filesystems (mount)"
list "item_procscsi"	"SCSI Information via proc (cat /proc/scsi/scsi)"
list "item_pvscan"		"LVM2: Physical Volumes (pvscan)"
list "item_vgscan"		"LVM2: Volume Groups (vgscan)"
list "item_lvscan"		"LVM2: Logical Volumes (lvscan)"
list "item_fstab"		"Filesystem mount table (fstab)"
unordered_list_close

toc_section "toc_periphs"  	"Peripherals" "#section_periphs"

unordered_list_open
list "item_cdinfo"			"DVD/CD drive info (cd-info)"
unordered_list_close

toc_section "toc_dmesg"		"Boot messages" "#section_dmesg"

unordered_list_open
list "item_dmesg"			"Linux boot messages (dmesg)"
list "item_dmesg_notime"	"Linux boot messages (dmesg)"
unordered_list_close

toc_section "toc_messages"	"Console/System Messages" "#section_messages"

unordered_list_open
list "item_messages"			"Linux system log (cat /var/log/messages | cat /var/log/syslog)"
unordered_list_close

toc_section "toc_modules"		"Kernel Modules" "#section_modules"

unordered_list_open
list "item_lsmod"				"Kernel Modules (lsmod)"
list "item_modinfo"				"Kernel Module Info (modinfo)"
unordered_list_close

toc_section "toc_udev"			"udev configuration" "#section_udev"

unordered_list_open
list "item_udevconf"			"udev configuration (cat /etc/udev.conf)"
list "item_udevrules"			"udev rules (cat /etc/udev/rules.d/*)"
unordered_list_close

toc_section "toc_virt"			"Virtualization" "#section_virt"

unordered_list_open
list "item_virshvers"			"Virtualization version (virsh version)"
list "item_virshnodeinfo"		"Virtualization nodes (virsh nodeinfo)"
list "item_virshnodecpu"		"Virtualization nodes cpus (virsh nodecpustats)"
list "item_virshnodemem"		"Virtualization nodes memory (virsh nodememstats)"
list "item_virshnodedevlist"	"Virtualization node devices (virsh nodedev-list)"
list "item_virshnodedevxml"		"Virtualization node devices xml (virsh nodedev-dumpxml)"
list "item_kvminfo"				"KVM Version (modinfo kvm)"
list "item_kvmhwinfo"			"KVM Hardware Version (modinfo kvm_intel | modinfo kvm_amd)"
unordered_list_close

toc_section "toc_sysctl"		"System Control Parameters" "#section_sysctl"

unordered_list_open
list "item_sysctl"				"System Control Parameters (sysctl)"
unordered_list_close

toc_section "toc_xwindows"			"X-Windows" "#section_xwindows"

unordered_list_open
list "item_xrandr"				"X RandR Info (xrandr)"
list "item_dpyinfo"				"X Display Info (xdpyinfo)"
list "item_glxinfo"				"GLX Info (glxinfo/glxinfo64)"
unordered_list_close

line "</div>"

line "<hr>"

echo "Table of Contents constructed"

###########################################################
# Linux Summary
###########################################################

section "section_linux_summary" "Linux Summary"

subtitle "item_hostname"	"System name" "hostname"
raw_open
hostname >> $HTML
raw_close

subtitle "item_date"		"System date/time" "date"
raw_open
date >> $HTML
raw_close

subtitle "item_uname"		"System identification" "uname -a"
raw_open
uname -a >> $HTML
raw_close

subtitle "item_issue"		"Distribution, Version" "/etc/issue"
raw_open
cat /etc/issue >> $HTML
raw_close

subtitle "item_lsb"			"Distribution, Release" "lsb_release"
raw_open
lsb_release -d >> $HTML
raw_close

###########################################################
# Hardware Summary
###########################################################

section "section_hw_summary" "Hardware Summary"

#subtitle "item_product"		"Product Name (dmidecode -s system-product-name)"
subtitle "item_product"		"Product Name" "dmidecode -s system-product-name"
raw_open
dmidecode -s system-product-name >> $HTML
raw_close

subtitle "item_processor_line"	"Processor Summary" "dmidecode -s processor-version"
raw_open
dmidecode -s processor-version | head -1 >> $HTML
raw_close

subtitle "item_memsum"			"Memory" "/proc/meminfo" 
raw_open
cat /proc/meminfo | grep MemTotal >> $HTML
raw_close

subtitle "item_bios_vendor"	"BIOS Vendor" "dmidecode -s bios-vendor"
raw_open
dmidecode -s bios-vendor >> $HTML
raw_close

subtitle "item_bios_vers"		"BIOS Version" "dmidecode -s bios-version"
raw_open
dmidecode -s bios-version  >> $HTML
raw_close

subtitle "item_bios_date"		"BIOS Release Date" "dmidecode -s bios-release-date"
raw_open
dmidecode -s bios-release-date  >> $HTML
raw_close

subtitle "item_cmdline"		"Boot parameters" "cat /proc/cmdline"
raw_open
cat /proc/cmdline >> $HTML
raw_close

subtitle "item_lsinitrd" 		"initrd information" "lsinitrd"

#MY_KERNEL=`uname -a | cut --delimiter=" " -f 3`
#MY_INITRD="/boot/initrd-$MY_KERNEL"

textarea_open 120 24
lsinitrd >> $HTML 2>&1
textarea_close

if [ -f $MY_INITRD ]
then
	#lsinitrd /boot/initrd-$MY_KERNEL >> $FILE_INITRD 2>&1
	lsinitrd >> $FILE_INITRD 2>&1
fi

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_INITRD target=_file_initrd>separate lsinitrd file.</a>"

###########################################################
# processor information
###########################################################
echo "Processor/CPU information"

section "section_processor" "Processor Information"

title "item_proc_family"	"Processor Family" "dmidecode -s processor-family"
# first line only please
raw_open
dmidecode -s processor-family | head -1 >> $HTML
raw_close

subtitle "item_proc_vers"		"Processor Version" "dmidecode -s processor-version"
# first line only please
raw_open
dmidecode -s processor-version | head -1 >> $HTML
raw_close

subtitle "item_processor_lscpu" "Processor Summary" "lscpu"
raw_open
lscpu >> $HTML
raw_close

subtitle "item_processor_lscpue" "Processor Summary" "lscpu -e"
raw_open
lscpu -e >> $HTML
raw_close

subtitle "item_processor_over"	"First Processor" "cat proc/cpuinfo"
raw_open
ENDLINE=`grep -n processor /proc/cpuinfo  | grep ": 1$" | cut -f 1 --delimiter=":"`

FIRSTCPU=`expr $ENDLINE - 1`

cat /proc/cpuinfo | head --lines $FIRSTCPU >> $HTML
raw_close

raw_open
line "`cat /proc/cpuinfo | grep processor | wc -l` count of `grep 'model name' /proc/cpuinfo | head -1 | cut -c 14-80` logical CPUs"
raw_close

cat /proc/cpuinfo >> $FILE_CPU

helpful_tip "<strong>Tip:</strong> Detailed information is available in the <a href=file:$BASE_FILE_CPU target=_file_cpu>separate cpu info file.</a>"

title "item_numashow"		"NUMA Topology" "numactl --show"

raw_open
if [ -f /sbin/numactl ] || [ -f /usr/bin/numactl ]
then
	numactl --show >> $HTML
else
	paragraph "numactl is not installed."
fi
raw_close 

helpful_tip "<strong>Tip:</strong> 'numactl --show' describes the NUMA policies for the current process.  It can be useful to see how physical CPUs and memory are organized."

title "item_numahw"			"NUMA Hardware topology" "numactl --hardware"
raw_open
if [ -f /sbin/numactl ] || [ -f /usr/bin/numactl ]
then
	numactl --hardware >> $HTML
else
	paragraph "numactl is not installed."
fi
raw_close

helpful_tip "<p><strong>Tip:</strong> 'numactl --topology' lists each node in the NUMA domain and produces table showing the cost of memory access from one node to another node."

title "item_meminfo"		"Memory Info" "cat /proc/meminfo"
raw_open
cat /proc/meminfo >> $HTML
raw_close

title "item_freemem"		"Free Memory" "free --giga"
raw_open
if [ `free -V | grep procps-ng | wc -l` -gt 0 ]
then
	free --human >> $HTML
else
	free -m >> $HTML
fi
raw_close

title "item_mtrr"			"MTRR" "cat /proc/mtrr"
raw_open
cat /proc/mtrr >> $HTML
raw_close

###########################################################
# interrupts 
###########################################################
echo "Interrupts"

section "section_inter" "Interrupts" "cat /proc/interrupts"
textarea_open 120 24
cat /proc/interrupts >> $HTML
textarea_close

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_INTER target=_file_inter>separate interrupts info file.</a><br>" >> $HTML

cat /proc/interrupts >> $FILE_INTER

###########################################################
# Expansion cards
###########################################################
echo "PCI Expansion cards"

section "section_pci" "Expansion Cards"
 
title "item_cards"			"Expansion cards" "sutl cards"

raw_open
if [ -f /usr/local/bin/sutl ]
then
	sutl cards >> $HTML
else
	line "'sutl' utility not installed, can't execute 'sutl cards'" 
fi
raw_close

title "item_iomem"			"Peripheral IO memory" "cat /proc/iomem"
raw_open
cat /proc/iomem >> $HTML
raw_close

title "item_ioports"		"Peripheral IO ports" "cat /proc/ioports"
raw_open
cat /proc/ioports >> $HTML
raw_close

title "item_devices" 		"Devices" "cat /proc/devices"
raw_open
cat /proc/devices >> $HTML
raw_close

title "item_lspci"			"PCI devices" "lspci"
raw_open
lspci >> $HTML
raw_close

title "item_lspcivv"		"PCI Devices Detail" "lspci -vv"
textarea_open 80 24
lspci -vv >> $HTML
lspci -vv >> $FILE_PCI
textarea_close

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_PCI target=_file_pci>separate lspci file.</a>"

###########################################################
# usb subsystem
###########################################################
echo "USB Subsystem"

section "section_usb" "USB Subsystem"

title "item_lsusb"			"USB Devices" "lsusb"
raw_open
lsusb >> $HTML
raw_close

title "item_lsusbpy"		"USB Devices Speed & Power" "lsusb.py"
raw_open
if [ -f /usr/bin/lsusb.py ]
then
	/usr/bin/lsusb.py >> $HTML
else
	echo "/usr/bin/lsusb.py is not installed." >> $HTML
fi
raw_close

title "item_lsusbv"			"USB Devices Detail" "lsusb -v"
raw_open
lsusb -v >> $HTML
raw_close

title "item_lsusbt"			"USB Devices Tree" "lsusb -t"
# redirect stderr to stdout as some information is sent do stderr too, not sure why.
raw_open
lsusb -t >> $HTML 2>&1
raw_close

###########################################################
# dmidecode devices 
###########################################################
echo "Dmidecode"

section "section_dmidecode" "System Board Information"

title "item_dmidecode" "System Board information" "dmidecode"

textarea_open 80 24
dmidecode >> $HTML
textarea_close 

dmidecode >> $FILE_DMI

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_DMI target=_file_dmi>separate dmidecode file.</a>"

###########################################################
# networking
###########################################################
echo "Networking"

section "section_networking" "Networking"

title "item_sutlnics"		"Network cards" "sutl nics"
if [ -f /usr/local/bin/sutl ]
then
	raw_open
	sutl nics >> $HTML
	raw_close
else
	line "# not installed: sutl nics"
fi

title "item_nicinfo"		"Network port information" "nic-info"
if [ -f /usr/local/bin/nic-info ]
then
	raw_open
	if [ $PUBLIC_REPORT = "yes" ]
	then
		echo "This is a public report and no IP networking information is included." >> $HTML
	else
		nic-info >> $HTML
	fi
	raw_close
else
	line "'nic-info' utility not installed, can't execute 'nic-info'" 
fi

title "item_nicports"		"Network port detail information" "ifconfig, ethtool, ethtool -i"
# process each ethernet device, skip vpn, bridges, localhost
raw_open

if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no IP networking information is included." >> $HTML
else

	if	( [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "18" ]] ) ||
		( [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "19" ]] )
	then
		for EACHNIC in $(ifconfig -a | fgrep " mtu " | grep -v lo | grep -v virbr | grep -v vboxnet | grep -v tap | awk -F " " '{print $1}')
		do
			if [ -f /usr/local/bin/sutl ]
			then
				sutl nics | grep $EACHNIC >> $HTML
			else
				line "NIC: $EACHNIC"
			fi

			line "# ifconfig $EACHNIC"
			ifconfig $EACHNIC >> $HTML

			line "# ethtool $EACHNIC"
			ethtool $EACHNIC >> $HTML

			line "# ethtool -i $EACHNIC"
			ethtool -i $EACHNIC >> $HTML

			line "----"
		done

	else
	#elif" " [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "18" ]] ) ||
	#	" " [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "19" ]] )
		for EACHNIC in $(ifconfig -a | fgrep " HWaddr " | grep -v lo | grep -v virbr | grep -v vboxnet | grep -v tap | awk -F " " '{print $1}')
		do
			if [ -f /usr/local/bin/sutl ]
			then
				sutl nics | grep $EACHNIC >> $HTML
			else
				line "NIC: $EACHNIC"
			fi

			line "# ifconfig $EACHNIC"
			ifconfig $EACHNIC >> $HTML
	
			line "# ethtool $EACHNIC"
			ethtool $EACHNIC >> $HTML

			line "# ethtool -i $EACHNIC"
			ethtool -i $EACHNIC >> $HTML
	
			line "----"
		done
	fi
fi
raw_close

title "item_netstat"		"Network routing table" "netstat"
raw_open
if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no routing information is included." >> $HTML
else
	netstat -nr >> $HTML
fi
raw_close

title "item_iproute"		"Network routing table" "ip route"
raw_open
if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no routing information is included." >> $HTML
else
	ip route  >> $HTML
fi
raw_close

title "item_firewall"		"Firewall rules" "iptables -L"

raw_open
if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no firewall information is included." >> $HTML
else
	iptables -L >> $HTML
fi
raw_close

###########################################################
# storage
###########################################################
echo "Storage"

section "section_storage" "Storage"

title "item_sutlhbas"	"Host Bus Adapter information" "sutl hbas"
if [ -f /usr/local/bin/sutl ]
then
	raw_open
	sutl hbas >> $HTML
	raw_close
else
	echo "'sutl' utility not installed, can't execute 'sutl cards'" >> $HTML
fi

title "item_lsblk"		"Block Storage Devices" "lsblk"
if [[ -f /usr/bin/lsblk ]]
then
	raw_open
	lsblk >> $HTML
	raw_close
fi

title "item_lsscsi"		"SCSI Information" "lsscsi"
if [[ -f /usr/local/bin/lsscsi ]] || [[ -f /usr/bin/lsscsi ]]
then
	raw_open
	lsscsi >> $HTML
	raw_close
fi

title "item_mount"		"Mounted filesystems" "mount"
line "Current mount, may not reflect status when issue occured."
raw_open
mount >> $HTML
raw_close

title "item_procscsi" "SCSI Information via proc" "cat /proc/scsi/scsi"
raw_open
cat /proc/scsi/scsi >> $HTML
raw_close

# Enable by default" "most RHEL and Fedora use LVM)
SHOW_LVM="yes"

if [ -f /usr/bin/pvscan ] || [ -f /sbin/pvscan ]
then

	PV_RESULTS=`pvscan | grep "  No matching physical volumes found" | wc -l`

	if [ $PV_RESULTS -ge 1 ]
	then
		SHOW_LVM="no"
	fi
fi
	
title "item_pvscan" "LVM2: Physical Volumes" "pvscan"
raw_open
# Regardless of whether physical volumes were found above, let pvscan
# report the status to the user.  Then use the SHOW_LVM variable set above
# to determine whether volume groups and logical volumes are processed.
#" "Skip those commands if no physical volumes are present)
pvscan >> $HTML
raw_close

title "item_vgscan" "LVM2: Volume Groups" "vgscan"
raw_open
if [ $SHOW_LVM == "yes" ]
then
	vgscan >> $HTML
else
	line "No physical volumes present per pvscan"
fi
raw_close

title "item_lvscan" "LVM2: Logical Volumes" "lvscan"
raw_open
if [ $SHOW_LVM == "yes" ]
then
	lvscan >> $HTML
else
	line "No physical volumes present per pvscan"
fi
raw_close

title "item_fstab" "Filesystem mount table" "fstab"
raw_open
cat /etc/fstab >> $HTML
raw_close

###########################################################
# Peripherals
###########################################################
echo "Perpherals"

section "section_periphs" "Peripherals"

title "item_cdinfo" "DVD/CD Drive Info" "cd-info"
raw_open
cd-info >> $HTML 2>&1
raw_close


###########################################################
# log files
###########################################################
section "section_dmesg" "Boot messages"

# SLES 11 SP2/SP3 does not have a dmesg which supports --notime
# If we don't have --notime this will report error 1, if we do error 0
if [ `dmesg --notime > /dev/null 2>&1; echo $?` == 0 ]
then
	# We have "--notime" option, use it.
	DMESG_NOTIME="yes"
else
	# We don't have "--notime" option, skip this, but leave the placeholder
	DMESG_NOTIME="no"
fi

title "item_dmesg_notime"		"Linux boot messages without timestamps" "dmesg --notime"
raw_open
if [ $DMESG_NOTIME == "yes" ]
then
	dmesg --notime >> $HTML
	dmesg --notime >> $FILE_DMESG_NOTIME
else
	line "dmesg on this system does not support the --notime option."
fi
raw_close

title "item_dmesg"		"Linux boot messages with timestamps" "dmesg"
raw_open
dmesg >> $HTML
dmesg >> $FILE_DMESG
raw_close

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_DMESG target=_file_dmesg>separate dmesg info file.</a>"

section "section_messages" "Console/System Messages"

title "item_messages"	"Linux system log" "cat /var/log/messages | cat /var/log/syslog"

# need to edit for debian, newer fedora, etc
if [ -f /var/log/messages ]
then
	echo "/var/log/messages:" >> $FILE_MSGS
	cat /var/log/messages >> $FILE_MSGS
elif [ -f /var/log/messages ]
then
	echo "/var/log/syslog:" >> $FILE_MSGS
	cat /var/log/syslog >> $FILE_MSGS
fi

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_MSGS target=_file_msgs>separate system log messages file.</a>"

###########################################################
# modules files
###########################################################
echo "Kernel modules"

section "section_modules" "Kernel Modules"

title "item_lsmod"		"Kernel Modules" "lsmod"
raw_open
lsmod >> $HTML
raw_close

title "item_modinfo"	"Kernel Module Info" "modinfo"
textarea_open 80 24
for EACHMOD in $(lsmod | grep -v Module | awk -F " " '{print $1}')
do
	echo >> $HTML
	modinfo $EACHMOD >> $HTML
done
textarea_close

###########################################################
# udev
###########################################################
echo "Udev subsystem"

section "section_udev" "udev configuration"

title "item_udevconf"	"udev configuration" "cat /etc/udev.conf"
raw_open
if [ -f /etc/udev.conf ]
then
	cat /etc/udev.conf >> $HTML
elif [ -f /etc/udev/udev.conf ]
then
	cat /etc/udev/udev.conf >> $HTML
fi
raw_close

title "item_udevrules"	"udev rules" "cat /etc/udev/rules.d/*"
raw_open
for EACHFILE in /etc/udev/rules.d/*
do
	echo "------------------------" >> $HTML
	echo "$EACHFILE" >> $HTML
	echo "------------------------" >> $HTML
	cat $EACHFILE >> $HTML
done
raw_close

###########################################################
# virtualization
###########################################################
echo "Virtualization"

section "section_virt" "Virtualization"

if [ -f /usr/bin/virsh ]
then

	title "item_virshvers"	"Virtualization version" "virsh version"
	# output stderr, problems seen that need to be captured -maxwell
	raw_open
	virsh version >> $HTML 2>&1
	raw_close

	title "item_virshnodeinfo"	"Virtualization nodes" "virsh nodeinfo"
	raw_open
	virsh nodeinfo >> $HTML
	raw_close

	title "item_virshnodecpu"	"Virtualization nodes" "virsh nodeinfo"
	raw_open
	virsh nodecpustats >> $HTML
	raw_close

	title "item_virshnodemem"	"Virtualization nodes" "virsh nodeinfo"
	raw_open
	virsh nodememstats >> $HTML
	raw_close

	title "item_virshnodedevlist"	"Virtualization nodes devices" "virsh nodedev-list"
	raw_open
	virsh nodedev-list>> $HTML
	raw_close

	title "item_virshnodedevxml"	"Virtualization nodes devices xml" "virsh nodedev-dumpxml"
	textarea_open 80 24
	for EACHDEV	in `virsh nodedev-list`
	do	
		virsh nodedev-dumpxml $EACHDEV >> $HTML
	done
	textarea_close

	title "item_kvminfo" "KVM Version" "modinfo kvm"
	raw_open
	modinfo kvm>> $HTML
	raw_close

	title "item_kvmhwinfo" "KVM Hardware Version" "modinfo kvm_intel | modinfo kvm_amd"
	raw_open
	if [ `lsmod | grep kvm_intel | wc -l` -gt 0 ]
	then
		modinfo kvm_intel >> $HTML
	fi
	if [ `lsmod | grep kvm_amd | wc -l` -gt 0 ]
	then
		modinfo kvm_amd >> $HTML
	fi
	raw_close
else
	echo "virsh is not installed in this environment." >> $HTML
fi

###########################################################
# sysctl files
###########################################################
echo "Sysctl"

section "section_sysctl" "System Control Parameters"

title "item_sysctl"	"System Control Parameters" "sysctl"

textarea_open 120 24
sysctl -a >> $HTML 2>&1
textarea_close

###########################################################
# X-Windows
###########################################################
echo "X-Windows"

section "section_xwindows" "X-Windows"

# Are we running X-Windows? How to check?

title "item_dpyinfo"	"X Display Info" "xdpyinfo"

raw_open
xrandr >> $HTML 2>&1
raw_close

title "item_dpyinfo"	"X Display Info" "xdpyinfo"

textarea_open 120 24
xdpyinfo >> $HTML 2>&1
textarea_close

title "item_xvinfo"	"Xvideo info" "xvinfo"

textarea_open 120 24
xvinfo >> $HTML 2>&1
textarea_close

title "item_glxinfo"	"GLX Info" "glxinfo"

textarea_open 120 24
glxinfo >> $HTML 2>&1
textarea_close

## - done - ####################################################

line "</body></html>" >> $HTML

# if we see an existing file, remove it so we can replace it.
if [ -f $OUTPUT_DIR.tar ]
then
	rm $OUTPUT_DIR.tar
fi
# if we see an existing file, remove it so we can replace it.
if [ -f $OUTPUT_DIR.tar.gz ]
then
	rm $OUTPUT_DIR.tar.gz
fi

echo -e "\nTaring up results."
tar cf $OUTPUT_DIR.tar $OUTPUT_DIR

echo "Compressing tar file."
gzip -9 $OUTPUT_DIR.tar

echo -e "Birdseye capture complete: $OUTPUT_DIR.tar.gz\n"
