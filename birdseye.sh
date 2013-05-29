#!/bin/bash
#
# birdseye.sh
#
# 2013 Maxwell Spangler, maxwell@maxwellspangler.com
# http://www.maxwellspangler.com/linux/birdseye
#
# Birdseye records a comprehensive inventory of a Linux system's
# environment and presents that in a single, organized html file for
# easy communication to developers and support staff.

VERSION="1.7.1"

# 1.7.1-2013-05-28 Added more BIRDSEYE config varible handling
#                  Added --year --month --time --notag filename options
#                  Added --force option to clobber output
#                  Renamed some variables; HOSTID now FILENAME_DATA
#                  Do not limit tag to 8 characters -- wide open now
# 1.7 - 2013-05-24 Porting to sles 11 sp3
#					handling no LVM physical volumes in use
#					handling lack of dmesg --notime
# 1.6 - 2013-04-29 Adding a few more commands like lscpu
#				   Added Peripherals and X-windows
# 1.5 - 2013-04-12 check for root user: error message if not root/sudo
# 1.4 - 2013-04-11 added command line parameters
#                  implemented public option - no networking published
# 1.3 - 2013-04-10 output filename option added
# 1.2 - 2013-04-05 refinements for big iron
# 1.1 - 2013-04-04 major cleanup in progress
# 				   added more functions: 
#				   : raw_open,raw_close
# 				   : textarea_open,textarea_close
# 				   : toc_section
#				   enabled external files via browser
#				   removed several files not used
# 1.0 - 2013-02-26 added lscpu

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
	echo -e "<h3><a name=\"$1\">$2</a> <a href="#top" class="boxtop">Top</a></h3>" >> $HTML
}

# Output a subtitle to a single piece of data being reported
# with an anchor ($1) and a text string ($2)
function subtitle {
	echo -e "<h4><a name=\"$1\">$2</a></h4>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function unordered_list_open {
	echo -e "<ul $1>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function unordered_list_close {
	echo -e "</ul>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function raw_open {
	echo -e "<pre class=\"PROGRAMLISTING\">" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function raw_close {
	echo -e "</pre>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function textarea_open {
	echo -e "<textarea readonly wrap=hard cols=\"$1\" rows=\"$2\">" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
# "</p> afterwards adds a little extra space before the next line
function textarea_close {
	echo -e "</textarea></p>" >> $HTML
}

# Output a simple unordered list tag <ul>
# with optional class info
function helpful_tip {
	echo -e "<div class=\"TIP\">" >> $HTML
	echo -e "<blockquote class=\"TIP\">" >> $HTML
	echo -e "$1" >> $HTML
	echo -e "</blockquote>" >> $HTML
	echo -e "</div>" >> $HTML
}

###########################################################
# default variable handling, prompt user for tags and titles
###########################################################

# BIRDSEYE variable are read from config file and used in initialization only
# export variables now so a subshell can set them in $HOME/.birdseye.cfg
export BIRDSEYE_TAG=""
export BIRDSEYE_NAME=""
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
export BIRDSEYE_PROMPT_USER="no"
export BIRDSEYE_CSS_FILE="no"
export BIRDSEYE_PUBLIC_REPORT="no"

# check for config file and execute to read in BIRDSEYE variables
if [ -f $HOME/.birdseye.cfg ]
then
	echo "Using in $HOME/.birdseye.cfg:"
	. $HOME/.birdseye.cfg

	echo "Tag   $BIRDSEYE_TAG"
	echo "Name  $BIRDSEYE_NAME"
	echo "Group $BIRDSEYE_GROUP"
	echo "Issue $BIRDSEYE_ISSUE"
	echo "Notes $BIRDSEYE_CFG_NOTES"
	echo

	# if we have a config file then we may have one or more 
	# (but not necessarily all) of these variables.
	# set the standard default variables to them, null if not set.
	DEF_TAG=${BIRDSEYE_TAG:-"null"}
	DEF_NAME=${BIRDSEYE_NAME:-"null"}
	DEF_GROUP=${BIRDSEYE_GROUP:-"null"}
	DEF_ISSUE=${BIRDSEYE_ISSUE:-"null"}
	DEF_CFG_NOTES=${BIRDSEYE_CFG_NOTES:-"null"}
else
	# If no config file, then set default values to static values here.
	DEF_TAG="birdseye"
	DEF_NAME="Unknown"
	DEF_GROUP="Unknown"
	DEF_ISSUE="not-specified"
	DEF_CFG_NOTES="none"
fi

###########################################################
# let's get started
###########################################################
PUBLIC_REPORT="no"
PROMPT_USER="yes"
CSS_FILE="null"

# default options for output filename.
# Use options from config file if possible (see above)
FILENAME_YEAR=$BIRDSEYE_FILENAME_YEAR
FILENAME_MONTH=$BIRDSEYE_FILENAME_MONTH
UILENAME_TIME=$BIRDSEYE_FILENAME_TIME
FILENAME_HOST=$BIRDSEYE_FILENAME_HOST
FILENAME_TAG=$BIRDSEYE_FILENAME_TAG

OUTPUT_FORCE=$BIRDSEYE_OUTPUT_FORCE

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
	echo "-g --group   Specify the group this report is associated with. 'Triage'"
	echo "-i --issue   Specify an issue being investigated. 'Network Fault'"
	echo "-h --hwnotes Specify a note about this hardware config. '1/2 cpus diabled'"
	echo
	echo "   --year    Include year in filename"
	echo "   --month   Include month & day in filename"
	echo "   --time    Include 24-hour format time in filename"
	echo "   --host    Include system's hostname in filename"
	echo "   --notag   Do not include report tag in filename (Default: include)"
	echo "   --force   Overwrite an existing output directory if it exists."
	echo
#	echo "-c --css     Use an external CSS style file's contents '/home/user/style.css'"
#	echo "-o --output  Specify the output filename."

}

while [ "$1" != "" ]
do
	case $1 in 

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

		# Include YYYY format date in output filename
		--year )
			FILENAME_YEAR="yes";;

		# Include MMDD format date in output filename
		--month )
			FILENAME_MONTH="yes";;

		# Include hostname in output filename
		--host )
			FILENAME_HOST="yes";;

		# Include hostname in output filename
		--notag )
			FILENAME_TAG="no";;

		# Include hostname in output filename
		--force )
			OUTPUT_FORCE="yes";;

		# specify the filename tag
		-t | --tag )
			shift
			DEF_TAG=$1;;

		-n | --name )
			shift
			DEF_NAME=$1;;

		-g | --group )
			shift
			DEF_GROUP=$1;;

		-i | --issue )
			shift
			DEF_ISSUE=$1;;

		-h | --hwnotes )
			shift
			DEF_CFG_NOTES=$1;;

		-o | --output )
			shift
			DEF_OUTPUT=$1;;

		-c | --css )
			shift
			CSS_FILE=$1;;

#		-f | --filename-host )
#			shift
#			FILENAME_HOST_FORMAT=$1;;

		* )
		usage
		exit 1;;
	esac
	shift
done

if [[ $DEBUG == "yes" ]]
then
	echo "Values after parameter processing:"
	echo "DEBUG PUBLIC_REPORT $PUBLIC_REPORT"
	echo "DEBUG PROMPT_USER $PROMPT_USER"
	echo "DEBUG DEF_OUTPUT $DEF_OUTPUT"
	echo "DEBUG CSS_FILE $CSS_FILE"
	echo
	echo "DEBUG DEF_TAG $DEF_TAG"
	echo "DEBUG DEF_NAME $DEF_NAME"
	echo "DEBUG DEF_GROUP $DEF_GROUP"
	echo "DEBUG DEF_ISSUE $DEF_ISSUE"
	echo "DEBUG DEF_CFG_NOTES $DEF_CFG_NOTES"
	echo
fi

###########################################################
# Prompt user for tag / name / group /issue / hw_notes
###########################################################

if [[ $PROMPT_USER == "no" ]]
then
	# set the working variables to the defaults
	MY_TAG=${DEF_TAG:-"null"}
	MY_NAME=${DEF_NAME:-"null"}
	MY_GROUP=${DEF_GROUP:-"null"}
	MY_ISSUE=${DEF_ISSUE:-"null"}
	MY_CFG_NOTES=${DEF_CFG_NOTES:-"null"}
else

	####################
	#echo -en "Provide a short tag to include with this [$DEF_TAG] ?"
	#read MY_TAG
	read -p "Provide a short tag to include with this [$DEF_TAG] ?" MY_TAG

	MY_TAG=${MY_TAG:-"null"}
	if [[ "$MY_TAG" != "null" ]] && [[ X"$MY_TAG" != X ]]
	then
		# quote required - spaces will be included!
		# slow
		#MY_TAG=`echo "$MY_TAG" | tr -d ' '`
		# fast
		MY_TAG=${MY_TAG//[[:space:]]/}

		# cut to first 8 characters
		#MY_TAG=${MY_TAG:0:8}
	else	
		# quote required - spaces will be included!
		MY_TAG="$DEF_TAG"
	fi

	####################
	#echo -en "What's your name [$DEF_NAME] ?"
	#read MY_NAME
	read -p "What's your name [$DEF_NAME] ?" MY_NAME
	MY_NAME=${MY_NAME:-"null"}
	if [ "$MY_NAME" != "null" ]
	then
		# quote required - spaces will be included!
		MY_NAME="$MY_NAME"
	else	
		# quote required - spaces will be included!
		MY_NAME="$DEF_NAME"
	fi

	####################
	#echo -en "What group are you in (linuxqa,io,aps?) [$DEF_GROUP] ?"
	#read MY_GROUP
	read -p "What group are you in (linuxqa,io,aps?) [$DEF_GROUP] ?" MY_GROUP

	# remove spaces
	MY_GROUP=${MY_GROUP//[[:space:]]/}

	MY_GROUP=${MY_GROUP:-"null"}
	if [ "$MY_GROUP" != "null" ]
	then
		MY_GROUP=$MY_GROUP
	else	
		MY_GROUP=$DEF_GROUP
	fi

	####################
	echo -e "A simple description for the issue being reported [$DEF_ISSUE] ?"
	#echo -n ":"
	#read MY_ISSUE
	read -p ":" MY_ISSUE
	MY_ISSUE="${MY_ISSUE:-"null"}"

	# quote required - spaces will be included!
	if [ "$MY_ISSUE" != "null" ]
	then
		# quote required - spaces will be included!
		MY_ISSUE="$MY_ISSUE"
	else	
		# quote required - spaces will be included!
		MY_ISSUE=$DEF_ISSUE
	fi

	####################
	echo -e "Notes about the system configuration: [$DEF_CFG_NOTES]"
	#echo -n ":"
	#read MY_CFG_NOTES
	read -p ":" MY_CFG_NOTES
	MY_CFG_NOTES="${MY_CFG_NOTES:-"null"}"

	# quote required - spaces will be included!
	if [ "$MY_CFG_NOTES" != "null" ]
	then
		# quote required - spaces will be included!
		MY_CFG_NOTES="$MY_CFG_NOTES"
	else	
		# quote required - spaces will be included!
		MY_CFG_NOTES="$DEF_CFG_NOTES"
	fi

fi

if [[ $DEBUG == "yes" ]]
then
	echo "Values after interactive prompting:"
	echo "DEBUG MY_TAG $MY_TAG"
	echo "DEBUG MY_NAME $MY_NAME"
	echo "DEBUG MY_GROUP $MY_GROUP"
	echo "DEBUG MY_ISSUE $MY_ISSUE"
	echo "DEBUG MY_CFG_NOTES $MY_CFG_NOTES"
	echo
fi

###########################################################
# got the input, go do it
###########################################################

# slow, sometimes hostname only not FQDN
MY_HOST=`hostname`

# fast, FQDN?
#MY_HOST=$HOSTNAME

# default for all conditions.
FILENAME_DATA="birdseye"

# Include hostname in output filename?
if [[ $FILENAME_HOST == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.$MY_HOST.
fi

# Include date in output filename?
if [[ $FILENAME_YEAR == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%Y`
fi

# Include date in output filename?
if [[ $FILENAME_MONTH == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%m%d`
fi

# Include 24hr time in output filename?
if [[ $FILENAME_TIME == "yes" ]]
then
	FILENAME_DATA=$FILENAME_DATA.`date +%H%M`
fi

# Include user's tag in filename?
if [[ $FILENAME_TAG == "yes" ]]
then
	FILENAME_DATA="$FILENAME_DATA.$MY_TAG"
fi

# Master directory for producing output files.
export CAPDIR="$FILENAME_DATA"

if [[ -d $CAPDIR ]]
then
	if [[ $OUTPUT_FORCE == "no" ]]
	then
		echo "Directory $CAPDIR exists. Please remove or use --force"
		exit
	else
		echo "Directory $CAPDIR exists, using --force to replace it."
	fi
fi

if [[ ! -d $CAPDIR ]]
then
	mkdir $CAPDIR
	if [ $? != 0 ]
	then
		echo "Can't make $CAPDIR"
		exit
	fi
else
	# careful! don't screw this up a
	rm -f $CAPDIR/*.txt birdseye.$FILENAME_DATA.tar birdseye.$FILENAME_DATA.tar.gz
fi

# summary file of small bits of info
# old way, let's assume the tag has the hostname in it?
# this should be an option
#HTML=$CAPDIR/birdseye.$FILENAME_DATA."$MY_TAG.".html
HTML="$CAPDIR/$FILENAME_DATA.html"

# detailed log files
BASE_FILE_DMI=dmidecode.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_CPU=cpuinfo.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_MSGS=messages.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_DMESG=dmesg.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_DMESG_NOTIME=dmesg-notime.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_INTER=interrupts.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_PCI=lspci.$FILENAME_DATA.$MY_TAG.txt
BASE_FILE_INITRD=initrd.$FILENAME_DATA.$MY_TAG.txt

FILE_DMI=$CAPDIR/$BASE_FILE_DMI
FILE_CPU=$CAPDIR/$BASE_FILE_CPU
FILE_MSGS=$CAPDIR/$BASE_FILE_MSGS
FILE_DMESG=$CAPDIR/$BASE_FILE_DMESG
FILE_DMESG_NOTIME=$CAPDIR/$BASE_FILE_DMESG
FILE_INTER=$CAPDIR/$BASE_FILE_INTER
FILE_PCI=$CAPDIR/$BASE_FILE_PCI
FILE_INITRD=$CAPDIR/$BASE_FILE_INITRD

# Empty the contents of each file to avoid old output
for EACH_FILE in \
	$HTML $FILE_DMI $FILE_CPU $FILE_MSGS $FILE_DMESG $FILE_DMESG_NOTIME \
	$FILE_INTER $FILE_PCI $FILE_INITRD
do
	#echo $EACH_FILE
	echo -n > $EACH_FILE
done

###########################################################
# trap any later work and cleanup if we control-c
###########################################################

trap "{ rm -r $CAPDIR $CAPDIR.tar $CAPDIR.tar.gz; exit 255 }" SIGINT SIGQUIT SIGTERM

###########################################################
# distributon and version handling
###########################################################

MY_DIST="null"
MY_RELEASE="null"

if [ -f /etc/redhat-release ]
then
	if [ `cat /etc/redhat-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_DIST="redhat"
		MY_RELEASE=5
	elif [ `cat /etc/redhat-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_DIST="redhat"
		MY_RELEASE=6
	fi

fi

if [ -f /etc/fedora-release ]
then
	if [ `cat /etc/fedora-release | grep "release 16" | wc -l` -gt 0 ]
	then
		MY_DIST="fedora"
		MY_RELEASE=16
	elif [ `cat /etc/fedora-release | grep "release 17" | wc -l` -gt 0 ]
	then
		MY_DIST="fedora"
		MY_RELEASE=17
	elif [ `cat /etc/fedora-release | grep "release 18" | wc -l` -gt 0 ]
	then
		MY_DIST="fedora"
		MY_RELEASE=18
	elif [ `cat /etc/fedora-release | grep "release 19" | wc -l` -gt 0 ]
	then
		MY_DIST="fedora"
		MY_RELEASE=19
	fi
fi

if [ -f /etc/oracle-release ]
then
	if [ `cat /etc/oracle-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_DIST="oracle"
		MY_RELEASE=5
	elif [ `cat /etc/oracle-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_DIST="oracle"
		MY_RELEASE=6
	fi
fi

if [ -f /etc/centos-release ]
then
	if [ `cat /etc/centos-release | grep "release 5." | wc -l` -gt 0 ]
	then
		MY_DIST="centos"
		MY_RELEASE=5
	elif [ `cat /etc/centos-release | grep "release 6." | wc -l` -gt 0 ]
	then
		MY_DIST="centos"
		MY_RELEASE=6
	fi

fi

if [ -f /etc/SuSE-release ]
then
	if [ `cat /etc/SuSE-release | grep "Server 11" | wc -l` -gt 0 ]
	then
		MY_DIST="SuSE"
		MY_RELEASE="11"
	elif [ `cat /etc/SuSE-release | grep "Server 10" | wc -l` -gt 0 ]
	then
		MY_DIST="SuSE"
		MY_RELEASE="10"
	fi
	
	#SUSE Linux Enterprise Server 11 (x86_64)
	#VERSION = 11
	#PATCHLEVEL = 2
fi

###########################################################
# Are we running in a VM? 
###########################################################

# works for a paravirtualized kernel but not for a fv linux kernel in a xen environment.
if [ `uname -a | grep xen | wc -l` -gt 0 ]
then
	XEN_VM=yes
else
	XEN_VM=no
fi

if [ `uname -a | grep xen | wc -l` -gt 0 ]
then
	KVM_VM=yes
else
	KVM_VM=no
fi

###########################################################
# Produce the report
###########################################################

line "<html>"

line "<head><title>Birdseye Report for $MY_HOST</title>"

#----------------------------------------------------------
# CSS STYLE SHEET for presentation
#----------------------------------------------------------

#if [[ $CSS_FILE != "null" ]] && [ -f "$CSS_FILE" ]
#then
#	cat "$CSS_FILE" >> $HTML
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

/* division class used to center header lines in simple, traditional pages */
.titleheader {
	text-align: center;
	background-color: rgb(212,226,255);
	padding: 10px 10px 10px 10px;

  border-width: 1px;
  border-style: solid;
  border-radius: 8px;
  border-color: #CFCFCF;
  padding: 5px;
  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  box-shadow: 3px 3px 5px #DFDFDF;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
}

/* basic table */
.simple_table {
	border-collapse: collapse;
	padding-top: 5px;
	padding-right: 5px;
	padding-bottom: 5px;
	padding-left: 5px;
}

/* basic table caption */
.simple_table caption {
	font-weight:bold;
}

/* borders for all cells */
.simple_table th,td {
	border: 1px solid;
}

/* basic table header cells */
.simple_table th {
	background-color: rgb(176,202,255);
}

/* basic table data cells */
.simple_table td {
	background-color: rgb(214,227,255);
	padding-top: 5px;
	padding-right: 5px;
	padding-bottom: 5px;
	padding-left: 5px;
}

/* division class used to center header lines in simple, traditional pages */
.official_links {
	text-align: center;
}

/* basic table */
.links_table {
/*
	border-collapse: collapse;
	padding-top: 5px;
	padding-right: 5px;
	padding-bottom: 5px;
	padding-left: 5px;
*/
	margin-left: auto;
	margin-right: auto;
}

/* basic table caption */
.links_table caption {
	font-weight:bold;
}

/* borders for all cells */
.links_table th,td {
	border: 1px solid;
}

/* basic table header cells */
.links_table th {
	background-color: rgb(176,202,255);
}

/* basic table data cells */
.links_table td {
	background-color: rgb(214,227,255);
	padding-top: 5px;
	padding-right: 8px;
	padding-bottom: 3px;
	padding-left: 8px;

  border-width: 1px;
  border-style: solid;
  border-radius: 8px;
  border-color: #CFCFCF;
  padding: 5px;
/*
	font-size: 0.75em;
*/
  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  box-shadow: 3px 3px 5px #DFDFDF;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
/*
  margin: 0 0 0 1ex;
*/
}
/* Heading Definitions */

h1, h2, h3, h4, h5, h6 {
	margin: 0 0 5px 0;
}

h1 {
  font-size: 1.8em;
  font-weight: bold;
  color: #3c6eb4; /* fedora logo color */
}

h2 {
  font-size: 1.5em;
  font-weight: bold;
  color: #3c6eb4; /* fedora logo color */
  text-decoration: underline;
}

h3 {
  font-size: 1.2em;
  font-weight: bold;
  color: #3c6eb4; /* fedora logo color */
}

h4 {
  font-size: 0.95em;
  font-weight: normal;
}

h5 {
  font-size: 0.9em;
  font-weight: normal;
}

h6 {
  font-size: 0.85em;
  font-weight: normal;
}

h1 a:hover {
  color: #EC5800;
  text-decoration: none;
}

h2 a:hover,
h3 a:hover,
h4 a:hover {
  color: #666666;
  text-decoration: none;
}

ol, ul, li {
/*
  font-size: 1.0em;
  line-height: 1.2em;
*/
  margin-top: 0.2em;
  margin-bottom: 0.1em; 
}

pre {
  font-family: monospace;
  font-size: 1.0em;
}


/* Link Styles */

a:link      { color:#3c6eb4; text-decoration: none; } /* fedora logo blue */
a:visited   { color:#004E66; text-decoration: underline; } /* darker blue */
a:active    { color:#3c6eb4; text-decoration: underline; } /* fedora logo blue */
a:hover     { color:#000000; text-decoration: underline; }

/* Text Styles */

p, ol, ul, li {
  line-height: 1.0em;
/*
  background-color: rgb(114,227,255);
*/
  font-size: 1.0em;
  margin: 2px 0 8px 0px;
}

/* box tops */
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

.programlisting {
  -moz-box-shadow: 3px 3px 5px #DFDFDF;
  -webkit-box-shadow: 3px 3px 5px #DFDFDF;
  -khtml-box-shadow: 3px 3px 5px #DFDFDF;
  -o-box-shadow: 3px 3px 5px #DFDFDF;
  box-shadow: 3px 3px 5px #DFDFDF;
  border-width: 1px;
  border-style: solid;
  padding: 12px;
/* changed to 0px 2013-01-27 looks better lined up on the left with everything else.  */
  margin: 0px 0px 10px 0px;
  overflow: auto;
  -moz-border-radius: 8px;
  -webkit-border-radius: 8px;
  -khtml-border-radius: 8px;
  border-radius: 8px;
  border-color: #CFCFCF;
  background-color: rgb(238,232,213);
}

.image_info {
/* debugging
	background-color: rgb(180,200,200);
*/
	height: 30px;
	weight: 30px;
	margin: 0 0 0 0;
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

paragraph "Produced on `date "+%A, %B %d %Y at %H:%m"` by $MY_NAME of $MY_GROUP"

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

paragraph "Capture File $CAPDIR"

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
list "item_uname"			"System identifcation (uname -a)"
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

###########################################################
# Linux Summary
###########################################################

section "section_linux_summary" "Linux Summary"

subtitle "item_hostname"	"System name (hostname)"
raw_open
hostname >> $HTML
raw_close

subtitle "item_date"		"System date/time (date)"
raw_open
date >> $HTML
raw_close

subtitle "item_uname"		"System identifcation (uname -a)"
raw_open
uname -a >> $HTML
raw_close

subtitle "item_lsb"			"Distribution,Release (lsb_release)"
raw_open
lsb_release -d >> $HTML
raw_close

###########################################################
# Hardware Summary
###########################################################

section "section_hw_summary" "Hardware Summary"

subtitle "item_product"		"Product Name (dmidecode -s system-product-name)"
raw_open
dmidecode -s system-product-name >> $HTML
raw_close

title "item_processor_line"	"Processor Summary"
raw_open
dmidecode -s processor-version | head -1 >> $HTML
raw_close

title "item_memsum"			"Memory (/proc/meminfo)" 
raw_open
cat /proc/meminfo | grep MemTotal >> $HTML
raw_close

title "item_bios_vendor"	"BIOS Vendor (dmidecode -s bios-vendor)"
raw_open
dmidecode -s bios-vendor >> $HTML
raw_close

title "item_bios_vers"		"BIOS Version (dmidecode -s bios-version)"
raw_open
dmidecode -s bios-version  >> $HTML
raw_close

title "item_bios_date"		"BIOS Release Date (dmidecode -s bios-release-date)"
raw_open
dmidecode -s bios-release-date  >> $HTML
raw_close

title "item_cmdline"		"Boot parameters (cat /proc/cmdline)"
raw_open
cat /proc/cmdline >> $HTML
raw_close

title "item_lsinitrd" 		"initrd information (lsinitrd)"
#lsinitrd >> $FILE_INITRD 2>&1

MY_KERNEL=`uname -a | cut --delimiter=" " -f 3`
MY_INITRD="/boot/initrd-$MY_KERNEL"

if [ -f $MY_INITRD ]
then
	lsinitrd /boot/initrd-$MY_KERNEL >> $FILE_INITRD 2>&1
fi

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_INITRD target=_file_initrd>separate lsinitrd file.</a>"

###########################################################
# processor information
###########################################################
echo "Processor/CPU information"

section "section_processor" "Processor Information"

title "item_proc_family"	"Processor Family (dmidecode -s processor-family)"
# first line only please
raw_open
dmidecode -s processor-family | head -1 >> $HTML
raw_close

title "item_proc_vers"		"Processor Version (dmidecode -s processor-version)"
# first line only please
raw_open
dmidecode -s processor-version | head -1 >> $HTML
raw_close

title "item_processor_lscpu" "Processor Summary (lscpu, lscpu -e)"
raw_open
lscpu >> $HTML
echo >> $HTML # blank line, seperator
lscpu -e >> $HTML
raw_close

title "item_processor_over"	"First Processor (cat proc/cpuinfo)"
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

title "item_numashow"		"NUMA Topology (numactl --show)"

raw_open
if [ -f /sbin/numactl ] || [ -f /usr/bin/numactl ]
then
	numactl --show >> $HTML
else
	paragraph "numactl is not installed."
fi
raw_close 

helpful_tip "<strong>Tip:</strong> 'numactl --show' describes the NUMA policies for the current process.  It can be useful to see how physical CPUs and memory are organized."

title "item_numahw"			"NUMA Hardware topology (numactl --hardware)"
raw_open
if [ -f /sbin/numactl ] || [ -f /usr/bin/numactl ]
then
	numactl --hardware >> $HTML
else
	paragraph "numactl is not installed."
fi
raw_close

helpful_tip "<p><strong>Tip:</strong> 'numactl --topology' lists each node in the NUMA domain and produces table showing the cost of memory access from one node to another node."

title "item_meminfo"		"Memory Info (cat /proc/meminfo)"
raw_open
cat /proc/meminfo >> $HTML
raw_close

title "item_freemem"		"Free Memory(free --giga)"
raw_open
if [ `free -V | grep procps-ng | wc -l` -gt 0 ]
then
	free --human >> $HTML
else
	free -m >> $HTML
fi
raw_close

title "item_mtrr"			"MTRR (cat /proc/mtrr)"
raw_open
cat /proc/mtrr >> $HTML
raw_close

###########################################################
# interrupts 
###########################################################
echo "Interrupts"

section "section_inter" "Interrupts (cat /proc/interrupts)"
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
 
title "item_cards"			"Expansion cards (sutl cards)"

if [ -f /usr/local/bin/sutl ]
then
	raw_open
	sutl cards >> $HTML
	raw_close
else
	line "'sutl' utility not installed, can't execute 'sutl cards'" 
fi

title "item_iomem"			"Peripheral IO memory (cat /proc/iomem)"
raw_open
cat /proc/iomem >> $HTML
raw_close

title "item_ioports"		"Peripheral IO ports (cat /proc/ioports)"
raw_open
cat /proc/ioports >> $HTML
raw_close

title "item_devices" 		"Devices (cat /proc/devices)"
raw_open
cat /proc/devices >> $HTML
raw_close

title "item_lspci"			"PCI devices (lspci)"
raw_open
lspci >> $HTML
raw_close

title "item_lspcivv"		"PCI Devices Detail (lspci -vv)"
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

title "item_lsusb"			"USB Devices (lsusb)"
raw_open
lsusb >> $HTML
raw_close

title "item_lsusbpy"		"USB Devices Speed & Power (lsusb.py)"
raw_open
if [ -f /usr/bin/lsusb.py ]
then
	/usr/bin/lsusb.py >> $HTML
else
	echo "/usr/bin/lsusb.py is not installed." >> $HTML
fi
raw_close

title "item_lsusbv"			"USB Devices Detail (lsusb -v)"
raw_open
lsusb -v >> $HTML
raw_close

title "item_lsusbt"			"USB Devices Tree (lsusb -t)"
# redirect stderr to stdout as some information is sent do stderr too, not sure why.
raw_open
lsusb -t >> $HTML 2>&1
raw_close

###########################################################
# dmidecode devices 
###########################################################
echo "Dmidecode"

section "section_dmidecode" "System Board Information"

title "item_dmidecode" "System Board information (dmidecode)"

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

title "item_sutlnics"		"Network cards (sutl nics)"
if [ -f /usr/local/bin/sutl ]
then
	raw_open
	sutl nics >> $HTML
	raw_close
else
	line "# not installed: sutl nics"
fi

title "item_nicinfo"		"Network port information (nic-info)"
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

title "item_nicports"		"Network port detail information (ifconfig, ethtool, ethtool -i)"
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
	#elif ( [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "18" ]] ) ||
	#	 ( [[ $MY_DIST="fedora" ]] && [[ $MY_RELEASE = "19" ]] )
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

title "item_netstat"		"Network routing table (netstat)"
raw_open
if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no routing information is included." >> $HTML
else
	netstat -nr >> $HTML
fi
raw_close

title "item_iproute"		"Network routing table (ip route)"
raw_open
if [ $PUBLIC_REPORT = "yes" ]
then
	echo "This is a public report and no routing information is included." >> $HTML
else
	ip route  >> $HTML
fi
raw_close

title "item_firewall"		"Firewall rules (iptables -L)"

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

title "item_sutlhbas"	"Host Bus Adapter information (sutl hbas)"
if [ -f /usr/local/bin/sutl ]
then
	raw_open
	sutl hbas >> $HTML
	raw_close
else
	echo "'sutl' utility not installed, can't execute 'sutl cards'" >> $HTML
fi

title "item_lsblk"		"Block Storage Devices (lsblk)"
if [[ -f /usr/bin/lsblk ]]
then
	raw_open
	lsblk >> $HTML
	raw_close
fi

title "item_lsscsi"		"SCSI Information (lsscsi)"
if [[ -f /usr/local/bin/lsscsi ]] || [[ -f /usr/bin/lsscsi ]]
then
	raw_open
	lsscsi >> $HTML
	raw_close
fi

title "item_mount"		"Mounted filesystems (mount)"
line "Current mount, may not reflect status when issue occured."
raw_open
mount >> $HTML
raw_close

title "item_procscsi" "SCSI Information via proc (cat /proc/scsi/scsi)"
raw_open
cat /proc/scsi/scsi >> $HTML
raw_close

# Enable by default (most RHEL and Fedora use LVM)
SHOW_LVM="yes"

if [ -f /usr/bin/pvscan ] || [ -f /sbin/pvscan ]
then

	PV_RESULTS=`pvscan | grep "  No matching physical volumes found" | wc -l`

	if [ $PV_RESULTS -ge 1 ]
	then
		SHOW_LVM="no"
	fi
fi
	
title "item_pvscan" "LVM2: Physical Volumes (pvscan)"
raw_open
# Regardless of whether physical volumes were found above, let pvscan
# report the status to the user.  Then use the SHOW_LVM variable set above
# to determine whether volume groups and logical volumes are processed.
# (Skip those commands if no physical volumes are present)
pvscan >> $HTML
raw_close

title "item_vgscan" "LVM2: Volume Groups (vgscan)"
raw_open
if [ $SHOW_LVM == "yes" ]
then
	vgscan >> $HTML
else
	line "No physical volumes present per pvscan"
fi
raw_close

title "item_lvscan" "LVM2: Logical Volumes (lvscan)"
raw_open
if [ $SHOW_LVM == "yes" ]
then
	lvscan >> $HTML
else
	line "No physical volumes present per pvscan"
fi
raw_close

title "item_fstab" "Filesystem mount table (fstab)"
raw_open
cat /etc/fstab >> $HTML
raw_close

###########################################################
# Peripherals
###########################################################
echo "Perpherals"

section "section_periphs" "Peripherals"

title "item_cdinfo" "DVD/CD Drive Info (cd-info)"
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

title "item_dmesg_notime"		"Linux boot messages without timestamps (dmesg --notime)"
raw_open
if [ $DMESG_NOTIME == "yes" ]
then
	dmesg --notime >> $HTML
	dmesg --notime >> $FILE_DMESG_NOTIME
else
	line "dmesg on this system does not support the --notime option."
fi
raw_close

title "item_dmesg"		"Linux boot messages with timestamps (dmesg)"
raw_open
dmesg >> $HTML
dmesg >> $FILE_DMESG
raw_close

helpful_tip "Detailed information is available in the <a href=file:$BASE_FILE_DMESG target=_file_dmesg>separate dmesg info file.</a>"

section "section_messages" "Console/System Messages"

title "item_messages"	"Linux system log (cat /var/log/messages | cat /var/log/syslog)"

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

title "item_lsmod"		"Kernel Modules (lsmod)"
raw_open
lsmod >> $HTML
raw_close

title "item_modinfo"	"Kernel Module Info (modinfo)"
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

title "item_udevconf"	"udev configuration (cat /etc/udev.conf)"
raw_open
if [ -f /etc/udev.conf ]
then
	cat /etc/udev.conf >> $HTML
elif [ -f /etc/udev/udev.conf ]
then
	cat /etc/udev/udev.conf >> $HTML
fi
raw_close

title "item_udevrules"	"udev rules (cat /etc/udev/rules.d/*)"
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

	title "item_virshvers"	"Virtualization version (virsh version)"
	# output stderr, problems seen that need to be captured -maxwell
	raw_open
	virsh version >> $HTML 2>&1
	raw_close

	title "item_virshnodeinfo"	"Virtualization nodes (virsh nodeinfo)"
	raw_open
	virsh nodeinfo >> $HTML
	raw_close

	title "item_virshnodecpu"	"Virtualization nodes (virsh nodeinfo)"
	raw_open
	virsh nodecpustats >> $HTML
	raw_close

	title "item_virshnodemem"	"Virtualization nodes (virsh nodeinfo)"
	raw_open
	virsh nodememstats >> $HTML
	raw_close

	title "item_virshnodedevlist"	"Virtualization nodes devices (virsh nodedev-list)"
	raw_open
	virsh nodedev-list>> $HTML
	raw_close

	title "item_virshnodedevxml"	"Virtualization nodes devices xml (virsh nodedev-dumpxml)"
	textarea_open 80 24
	for EACHDEV	in `virsh nodedev-list`
	do	
		virsh nodedev-dumpxml $EACHDEV >> $HTML
	done
	textarea_close

	title "item_kvminfo" "KVM Version (modinfo kvm)"
	raw_open
	modinfo kvm>> $HTML
	raw_close

	title "item_kvmhwinfo" "KVM Hardware Version (modinfo kvm_intel | modinfo kvm_amd)"
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

title "item_sysctl"	"System Control Parameters (sysctl)"

textarea_open 120 24
sysctl -a >> $HTML 2>&1
textarea_close

###########################################################
# X-Windows
###########################################################
echo "X-Windows"

section "section_xwindows" "X-Windows"

# Are we running X-Windows? How to check?

title "item_dpyinfo"	"X Display Info (xdpyinfo)"

raw_open
xrandr >> $HTML 2>&1
raw_close

title "item_dpyinfo"	"X Display Info (xdpyinfo)"

textarea_open 120 24
xdpyinfo >> $HTML 2>&1
textarea_close

title "item_xvinfo"	"Xvideo info (xvinfo)"

textarea_open 120 24
xvinfo >> $HTML 2>&1
textarea_close

title "item_glxinfo"	"GLX Info (glxinfo)"

textarea_open 120 24
glxinfo >> $HTML 2>&1
textarea_close

## - done - ####################################################

string "</body></html>" >> $HTML

# if we see an existing file, remove it so we can replace it.
if [ -f $CAPDIR.tar ]
then
	rm $CAPDIR.tar
fi
# if we see an existing file, remove it so we can replace it.
if [ -f $CAPDIR.tar.gz ]
then
	rm $CAPDIR.tar.gz
fi

echo -e "\nTaring up results."
tar cf $CAPDIR.tar $CAPDIR

echo "Compressing tar file."
gzip -9 $CAPDIR.tar

echo -e "Birdseye capture complete: $CAPDIR.tar.gz\n"
