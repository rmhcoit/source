#!/bin/bash
# Copyright (c) 2013, Chris Waian All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# 	1) Redistributions of source code must retain the above copyright
# 	notice, this list of conditions and the following disclaimer.
# 
# 	2) Redistributions in binary form must reproduce the above copyright
# 	notice, this list of conditions and the following disclaimer in the
# 	documentation and/or other materials provided with the distribution.
# 
# 	3) Neither the name of the Robert M Hadley Company nor the names of its
# 	contributors may be used to endorse or promote products derived from
# 	this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



#---------------------------- Default Variables --------------------------------
# Set Default Path for the directory holding all users home folders
DEFAULTPATH=""
# Set the place to hold logs
DefaultLogDir=""
# and the name of the folder inside the logs directory
LogFolder="setperms"
# Set Default Client Administrators shortusername
DefaultAdmin=""
# Set Default path for temporary folder used by the script
DefaultTEMPDIR=""
# Temp folder name
TempFolder="unknownuserfix"
# User Group - OSX default= staff
usergroup="staff"
#---------------------------- Default Variables --------------------------------

usage() {
cat <<'EOF'
setperms [OPTIONS] NAME [...]

Sets permissions for all/one user(s) in the shared home folder directory.

 Options:
	-h, --help			display this help and exit

	-s, --silent			screen off, nothing displayed to terminal window

	-v, --verbose			verbose, displays commands and uses -v for all
					commands used by this script.

	-u, --user 			set user to target
							
	-p, --path "/path/"		specify path for shared home folder directory

	-l, --log "/path/"		enables verbose logging, location is optional,
					default will be used if none is specified.

	-a, --admin 			set Client Administrator, (short name required)

	-t, --tempdir "/path/"		specify temp directory, otherwise you
					will be asked or defualts will be used.

EOF
}


#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv OPTIONS vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
sflag="default";
vflag="default";
lflag="default";
uflag="default";
flaglogdir="default";
flagtempdir="default";
flagadmin="default";
flagpath="default";


optstring=svlhp:a:t:u:

unset options
while (($#)); do
  case $1 in
    -[!-]?*)
      for ((i=1; i<${#1}; i++)); do
        c=${1:i:1}
        options+=("-$c")
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;
    --?*=*) options+=("${1%%=*}" "${1#*=}");;
    --)
      options+=(--endopts)
      shift
      options+=("$@")
      break
      ;;
    *) options+=("$1");;
  esac

  shift
done

set -- "${options[@]}"
unset options

while [[ $1 = -?* ]]; do
  case $1 in
    -s|--silent)
      sflag="on"
      echo "s=$sflag"
      ;;
    -v|--verbose)
      vflag="on"
      echo "v=$vflag"
      ;;
    -l|--log)
        lflag="on"
        echo "l=$lflag"
        if [[ "$2" = "" ]]; then
          flaglogdir="null"
        elif [[ "$2" != "" ]]; then
          flaglogdir="$2"
        else
          echo "arg or flag error"
        fi
        shift
        ;;
    -t|--tempdir)
        if [[ "$2" = "" ]]; then
          flagtempdir="null"
        elif [[ "$2" != "" ]]; then
          flagtempdir="$2"
        else
          echo "arg or flag error"
        fi
        shift
        ;;
    -a|--admin)
        if [[ "$2" = "" ]]; then
          flagadmin="null"
        elif [[ "$2" != "" ]]; then
          flagadmin="$2"
        else
          echo "arg or flag error"
        fi
        shift
        ;;
    -p|--path)
        if [[ "$2" = "" ]]; then
          flagpath="null"
        elif [[ "$2" != "" ]]; then
          flagpath="$2"
        else
          echo "arg or flag error"
        fi
        shift
        ;;
    -u|--user)
		uflag="on"
        if [[ "$2" = "" ]]; then
          flaguser="null"
        elif [[ "$2" != "" ]]; then
          flaguser="$2"
        else
          echo "arg or flag error"
        fi
        shift
        ;;
    -h|--help) usage >&2; exit 0;;
    --endopts) shift; break;;
    *) die "invalid option: $1";;
  esac

  shift
done

if [[ "$sflag" = "default" ]] && [[ "$vflag" = "default" ]] && [[ "$lflag" = "default" ]]; then
  flag1="verbose";
  flag2="silent";
  flag3="off";
elif [[ "$sflag" = "on" ]] && [[ "$vflag" = "default" ]] && [[ "$lflag" = "default" ]]; then
  flag1="silent";
  flag2="silent";
  flag3="off";
elif [[ "$sflag" = "default" ]] && [[ "$vflag" = "on" ]] && [[ "$lflag" = "default" ]]; then
  flag1="verbose";
  flag2="verbose";
  flag3="off";
elif [[ "$sflag" = "default" ]] && [[ "$vflag" = "default" ]] && [[ "$lflag" = "on" ]]; then
  flag1="verbose";
  flag2="silent";
  flag3="on";
elif [[ "$sflag" = "on" ]] && [[ "$vflag" = "on" ]] && [[ "$lflag" = "default" ]]; then
  flag1="silent";
  flag2="verbose";
  #flag3 is exception
  flag3="on";
elif [[ "$sflag" = "default" ]] && [[ "$vflag" = "on" ]] && [[ "$lflag" = "on" ]]; then
  flag1="verbose";
  flag2="verbose";
  flag3="on";
elif [[ "$sflag" = "on" ]] && [[ "$vflag" = "default" ]] && [[ "$lflag" = "on" ]]; then
  flag1="silent";
  flag2="silent";
  flag3="on";
  echo "can't log anything if there is not text to write down"
elif [[ "$sflag" = "on" ]] && [[ "$vflag" = "on" ]] && [[ "$lflag" = "on" ]]; then
  flag1="silent";
  flag2="verbose";
  flag3="on";
else
  echo "options error"
fi

mode1=$flag1;
mode2=$flag2;
mode3=$flag3;
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Options ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Pre-Var Assigment vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
#
#---------------------------- Parsing Arguments --------------------------------
#
# If --log has argument then it sets it in logpath if not then it uses DefaultLogDir
case $DefaultLogDir in
     */) DefaultLog_Dir=${DefaultLogDir%?};;
     *) DefaultLog_Dir=$DefaultLogDir;;
esac
case $flaglogdir in
     */) flaglog_dir=${flaglogdir%?};;
     *) flaglog_dir=$flaglogdir;;
esac

if [[ "$flaglogdir" = "null" ]]; then
	log_path=$DefaultLog_Dir/$LogFolder
elif [[ "$flaglogdir" = "default" ]]; then
	log_path=$DefaultLog_Dir/$LogFolder
else
	log_path=$flaglog_dir/$LogFolder
	if [[ "$flaglog_dir" = "" ]]; then
		echo "error: flag: arg"
		exit
	fi
fi

case $log_path in
     */) logpath=${log_path%?};;
     *) logpath=$log_path;;
esac

# If --path has arugment the it sets it in DefaultPath if not then it uses DEFAULTPATH
if [[ "$flagpath" = "null" ]]; then
	DefaultPath="$DEFAULTPATH"
elif [[ "$flagpath" = "default" ]]; then
	DefaultPath="$DEFAULTPATH"
else
	DefaultPath="$flagpath"
	if [[ "$flagpath" = "" ]]; then
		echo "error: flag: arg"
		exit
	fi
fi
# If --admin has arugment the it sets it in Defaultcadmin if not then it uses DefaultAdmin
if [[ "$flagadmin" = "null" ]]; then
	Defaultcadmin="$DefaultAdmin"
elif [[ "$flagadmin" = "default" ]]; then
	Defaultcadmin="$DefaultAdmin"
else
	Defaultcadmin="$DefaultAdmin"
	if [[ "$flagadmin" = "" ]]; then
		echo "error: flag: arg"
		exit
	fi
fi
# If --tempdir has arugment the it sets it in Defaultcadmin if not then it uses DefaultAdmin
if [[ "$flagtempdir" = "null" ]]; then
	DefaultTempdir="$DefaultTEMPDIR"
elif [[ "$flagtempdir" = "default" ]]; then
	DefaultTempdir="$DefaultTEMPDIR"
else
	DefaultTempdir="$flagtempdir"
	if [[ "$flagtempdir" = "" ]]; then
		echo "error: flag: arg"
		exit
	fi
fi

case $DefaultTempdir in
     */) DefaultTempDir=${DefaultTempdir%?};;
     *) DefaultTempDir=$DefaultTempdir;;
esac
#---------------------------- Parsing Arguments --------------------------------

# Makes sure logpath exists and creates if nessisary
mkdir $logpath >> /dev/null 2>&1
mkdir $logpath/old/ >> /dev/null 2>&1

# start verbose log file
date > $logpath/setperms.log
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Pre-Var Assigment ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
setalluserperms()
{
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Variable Assigment vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# if  [verboseMENU is set(on) and verboseFLAGS is any and logging is on] or [verboseMENU is default(on) and verboseFLAGS is any and logging is on]
# if  [verboseMENU is set(on) and verboseFLAGS is any and logging is on] or [verboseMENU is default(on) and verboseFLAGS is any and logging is on]
if [[ "$mode1" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "Set All User Permissions Script  by  Chris Waian, Robert M Hadley Company  2013" 2>&1 | tee -a $logpath/setperms.log;
	echo "-----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;
	echo "Leave answers blank for defaults." 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Set path of the folder holding all user home folders.
	echo "Where is the users homefolders located?	         (Default = $DefaultPath)" 2>&1 | tee -a $logpath/setperms.log;
	read path;
	if  [[ "$path" == "" ]]; then
		Path=$DefaultPath
	else
		Path=$path
	fi
	# Finds if there is a slash a the end of the string and strips it if there is
	case $Path in
	     */) homefolderdir=${Path%?};;
	     *) homefolderdir=$Path;;
	esac
	echo "CHOICE:		$homefolderdir" >> $logpath/setperms.log 2>&1;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Asks for cliend admin name to set top level folder owner/perms
	echo "What is the short username for the Local Client Administrator?  (Default = $Defaultcadmin)" 2>&1 | tee -a $logpath/setperms.log;
	read localclientadmin;
	if  [[ "$localclientadmin" == "" ]]; then
		cadmin=$Defaultcadmin
	else
		cadmin=$localclientadmin
	fi
	echo "CHOICE:		$cadmin" >> $logpath/setperms.log 2>&1;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Asks temporary folder to hold files created by the script
	echo "Temporary Folder?  (Default = $DefaultTempDir)" 2>&1 | tee -a $logpath/setperms.log;
	read Temporaryfolder;
	case $Temporaryfolder in
	     */) temporaryfolder=${Temporaryfolder%?};;
	     *) temporaryfolder=$Temporaryfolder;;
	esac
	if  [[ "$temporaryfolder" == "" ]]; then
		TempDir=$DefaultTempDir
	else
		TempDir=$temporaryfolder
	fi
	echo "CHOICE:		$TempDir" >> $logpath/setperms.log 2>&1;
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: ALL  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempPath=$TempDir/$TempFolder
	echo "TEMPFOLDER:		$TempPath" >> $logpath/setperms.log 2>&1;
	cd "$TempDir/"
	mkdir $TempFolder >> $logpath/setperms.log 2>&1;
	#-------------Logging-----------------------------------
# if  [verboseMENU is set(on) and verboseFLAGS is any and logging is off] or [verboseMENU is default(on) and verboseFLAGS is any and logging is off]
elif [[ "$mode1" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "Set All User Permissions Script  by  Chris Waian, Robert M Hadley Company  2013";
	echo "-----------------------------------------------------------------------------------";
	echo "Leave answers blank for defaults."
	echo ""
	# Set path of the folder holding all user home folders.
	echo "Where is the users homefolders located?	         (Default = $DefaultPath)";
	read path;
	if  [[ "$path" == "" ]]; then
		Path=$DefaultPath
	else
		Path=$path
	fi
	# Finds if there is a slash a the end of the string and strips it if there is
	case $Path in
	     */) homefolderdir=${Path%?};;
	     *) homefolderdir=$Path;;
	esac
	echo ""
	echo ""
	echo ""
	# Asks for cliend admin name to set top level folder owner/perms
	echo "What is the short username for the Local Client Administrator?  (Default = $Defaultcadmin)";
	read localclientadmin;
	if  [[ "$localclientadmin" == "" ]]; then
		cadmin=$Defaultcadmin
	else
		cadmin=$localclientadmin
	fi
	echo ""
	echo ""
	echo ""
	# Asks temporary folder to hold files created by the script
	echo "Temporary Folder?  (Default = $DefaultTempDir)";
	read Temporaryfolder;
	case $Temporaryfolder in
	     */) temporaryfolder=${Temporaryfolder%?};;
	     *) temporaryfolder=$Temporaryfolder;;
	esac
	if  [[ "$temporaryfolder" == "" ]]; then
		TempDir=$DefaultTempDir
	else
		TempDir=$temporaryfolder
	fi
	sleep 1;
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: ALL  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempPath=$TempDir/$TempFolder
	cd "$TempDir/"
	mkdir $TempFolder
	#-------------Logging-----------------------------------
# if  [verboseMENU is set(off) and verboseFLAGS is any and logging is on]
elif [[ "$mode1" = "silent" ]]; then
	# Finds if there is a slash a the end of the string and strips it if there is
	case $DefaultPath in
	     */) homefolderdir=${DefaultPath%?};;
	     *) homefolderdir=$DefaultPath;;
	esac
	# set client admin name to set top level folder owner/perms
	cadmin=$Defaultcadmin
	# sets complete path to temporary folder that is created
	TempPath=$TempDir/$TempFolder
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: ALL  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempFolder="unknownuserfix"
	TempPath=$TempDir/$TempFolder
	cd "$TempDir/"
	mkdir $TempFolder >> /dev/null 2>&1
	#-------------Logging-----------------------------------
else
	echo "missing flag perams"
fi
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Variable Assigment ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
starttime=`date +%s`
# Define Array (UserList) with List all files located in the folder holding user home folders 
UserList=( `(ls $homefolderdir)` );
# Find total number of entries in the array (UserList)
UserTotal=${#UserList[*]};
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Set Perms from Array vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "Set ownership, sets owner permssions to rwx------" 2>&1 | tee -a $logpath/setperms.log;
	echo "Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" 2>&1 | tee -a $logpath/setperms.log;
	echo "Found $UserTotal folders in directory =  $homefolderdir" 2>&1 | tee -a $logpath/setperms.log;
	echo "----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;
	echo "Prepping...." 2>&1 | tee -a $logpath/setperms.log;
	chflags -R -L nouchg $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
	chflags -R -L nohidden $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
	chflags -R -L nouappnd $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "Set ownership, sets owner permssions to rwx------";
	echo "Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx";
	echo "Found $UserTotal folders in directory =  $homefolderdir";
	echo "----------------------------------------------------------------------------------";
	echo "Prepping....";
	chflags -R -L nouchg $homefolderdir/;
	chflags -R -L nohidden $homefolderdir/;
	chflags -R -L nouappnd $homefolderdir/;
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "TITLE:		Set ownership, sets owner permssions to rwx------" 2>&1 | tee -a $logpath/setperms.log;
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" 2>&1 | tee -a $logpath/setperms.log;
	echo "TITLE:		Found $UserTotal folders in directory =  $homefolderdir" 2>&1 | tee -a $logpath/setperms.log;
	echo "LINEBREAK:		----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;
	echo "ANNOUCEMENT:		Prepping...." 2>&1 | tee -a $logpath/setperms.log;
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/" 2>&1 | tee -a $logpath/setperms.log;
	chflags -v -R -L nouchg $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/" 2>&1 | tee -a $logpath/setperms.log;
	chflags -v -R -L nohidden $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/" 2>&1 | tee -a $logpath/setperms.log;
	chflags -v -R -L nouappnd $homefolderdir/ 2>&1 | tee -a $logpath/setperms.log;
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "TITLE:		Set ownership, sets owner permssions to rwx------";
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx";
	echo "TITLE:		Found $UserTotal folders in directory =  $homefolderdir";
	echo "LINEBREAK:	----------------------------------------------------------------------------------";
	echo "ANNOUCEMENT:		Prepping....";
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/";
	chflags -v -R -L nouchg $homefolderdir/;
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/";
	chflags -v -R -L nohidden $homefolderdir/;
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/";
	chflags -v -R -L nouappnd $homefolderdir/;
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
	#verbose logging on
	echo "" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Set ownership, sets owner permssions to rwx------" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Found $UserTotal folders in directory =  $homefolderdir" >> $logpath/setperms.log 2>&1;
	echo "LINEBREAK:	----------------------------------------------------------------------------------" >> $logpath/setperms.log 2>&1;
	echo "ANNOUCEMENT:		Prepping...." >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nouchg $homefolderdir/ >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nohidden $homefolderdir/ >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nouappnd $homefolderdir/ >> $logpath/setperms.log 2>&1;
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
	# verbose logging off
	# no echo annoucement
	chflags -f -R -L nouchg $homefolderdir/ >> /dev/null 2>&1;
	chflags -f -R -L nohidden $homefolderdir/ >> /dev/null 2>&1;
	chflags -f -R -L nouappnd $homefolderdir/ >> /dev/null 2>&1;
fi
#------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------
# For loop the entires in array (UserList)
for userfolder in "${UserList[@]}"
do
# If entry from array contains a period (.) then mark as skipped
	if  [[ "$userfolder" == .* || "$userfolder" == "Shared" ]]; then
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
		if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
			# verbose logging on
			echo "Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "Skipping $userfolder."
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
			# error
			echo "error: logging is on when everything else is forced silent"
			exit
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
			# verbose logging on
			echo "ANNOUCEMENT:		Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "ANNOUCEMENT:		Skipping $userfolder."
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
			#verbose logging on
			echo "ANNOUCEMENT:		Skipping $userfolder." >> $logpath/setperms.log 2>&1;

		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
			# error
			echo "error: logging off when verbose flag is called but terminal screen is forced silent"
			exit
		fi
	# Everything else, (the good usernames) get sent through these commands
	else
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
		if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
			# verbose logging on
			# Wipe ACL
			echo "Wiping and setting ACL for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			chflags -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			chflags -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			chflags -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			chmod -RN $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "ACL for $userfolder complete." 2>&1 | tee -a $logpath/setperms.log
			# Set Users folder ownership			
			echo "Setting $userfolder as owner of $homefolderdir/$userfolder/." 2>&1 | tee -a $logpath/setperms.log
			chown -R $userfolder:$usergroup $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "Completed ownership for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			sleep 1;
			# Set permissions for the Users files
			echo "Setting permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			chmod -R 700 $homefolderdir/$userfolder/;
			echo "Completed permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			sleep 1;
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
			# verbose logging off
			# Wipe ACL
			echo "Wiping and setting ACL for $userfolder.";
			chflags -R -L nouchg $homefolderdir/$userfolder/;
			chflags -R -L nohidden $homefolderdir/$userfolder/;
			chflags -R -L nouappnd $homefolderdir/$userfolder/;
			chmod -RN $homefolderdir/$userfolder/;
			echo "ACL for $userfolder complete.";
			# Set Users folder ownership			
			echo "Setting $userfolder as owner of $homefolderdir/$userfolder/.";
			chown -R $userfolder:$usergroup $homefolderdir/$userfolder/;
			echo "Completed ownership for $userfolder.";
			sleep 1;
			# Set permissions for the Users files
			echo "Setting permissions for $userfolder.";
			chmod -R 700 $homefolderdir/$userfolder/;
			echo "Completed permissions for $userfolder.";
			sleep 1;
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
			# verbose logging off
			# no echo annoucement
			# Wipe ACL
			chflags -f -R -L nouchg $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			chflags -f -R -L nohidden $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			chflags -f -R -L nouappnd $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			chmod -f -RN $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			# Set Users folder ownership			
			chown -f -R $userfolder:$usergroup $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			sleep 1;
			# Set permissions for the Users files
			chmod -f -R 700 $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			sleep 1;
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
			# error
			echo "error: logging is on when everything else is forced silent"
			exit
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
			# verbose logging on
			# Wipe ACL
			echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chmod -v -RN $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "ANNOUCEMENT:		ACL for $userfolder complete." 2>&1 | tee -a $logpath/setperms.log
			sleep 1;
			# Set Users folder ownership			
			echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/." 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "ANNOUCEMENT:		Completed ownership for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			sleep 1;
			# Set permissions for the Users files
			echo "ANNOUCEMENT:		Setting permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chmod -v -R 700 $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "ANNOUCEMENT:		Completed permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
			sleep 1;
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder.";
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/";
			chflags -v -R -L nouchg $homefolderdir/$userfolder/;
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/";
			chflags -v -R -L nohidden $homefolderdir/$userfolder/;
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/";
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/;
			echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/";
			chmod -v -RN $homefolderdir/$userfolder/;
			echo "ANNOUCEMENT:		ACL for $userfolder complete.";
			sleep 1;
			# Set Users folder ownership			
			echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/.";
			echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/";
			chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/;
			echo "ANNOUCEMENT:		Completed ownership for $userfolder.";
			sleep 1;
			# Set permissions for the Users files
			echo "ANNOUCEMENT:		Setting permissions for $userfolder.";
			echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/";
			chmod -v -R 700 $homefolderdir/$userfolder/;
			echo "ANNOUCEMENT:		Completed permissions for $userfolder.";
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
			#verbose logging on
			echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder." >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nouchg $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nohidden $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chmod -v -RN $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "ANNOUCEMENT:		ACL for $userfolder complete." >> $logpath/setperms.log 2>&1;
			sleep 1;
			# Set Users folder ownership			
			echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/." >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "ANNOUCEMENT:		Completed ownership for $userfolder." >> $logpath/setperms.log 2>&1;
			sleep 1;
			# Set permissions for the Users files
			echo "ANNOUCEMENT:		Setting permissions for $userfolder." >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chmod -v -R 700 $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "ANNOUCEMENT:		Completed permissions for $userfolder." >> $logpath/setperms.log 2>&1;
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
			# error
			echo "error: logging off when verbose flag is called but terminal screen is forced silent"
			exit
		fi
	fi
done
sleep 3;
# For loop close
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  Set Perms from Array ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Unknown User Fix vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# For loop the entires in array (UserList)
for userfolder in "${UserList[@]}"; do
	# If entry from array contains a period (.) then mark as skipped
	if  [[ "$userfolder" == .* || "$userfolder" == "Shared" ]]; then
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
		if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
			# verbose logging on
			echo "Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "Skipping $userfolder."
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
			# error
			echo "error: logging is on when everything else is forced silent"
			exit
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
			# verbose logging on
			echo "ANNOUCEMENT:		Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "ANNOUCEMENT:		Skipping $userfolder."
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
			#verbose logging on
			echo "ANNOUCEMENT:		Skipping $userfolder." >> $logpath/setperms.log 2>&1;
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
			# error
			echo "error: logging off when verbose flag is called but terminal screen is forced silent"
			exit
		fi
	# Everything else, (the good usernames) get sent through these commands
	else
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
		if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
			# verbose logging on
			chflags -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			chflags -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			chflags -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			# Write the unknown-files found to a file in /Scripts/temp/
			echo "Scanning $userfolder for files owned by _unknown user" 2>&1 | tee -a $logpath/setperms.log
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
			# iterate by reading each line of the temp file
			count=`(wc -l < $TempPath/$userfolder)`;
			echo "Found"'' $count "files owned by unknown user in $userfolder's directory." 2>&1 | tee -a $logpath/setperms.log
			# If zero files owned by unknown user are found then skip
			if  [ $count == 0 ]; then
				echo "No Files to fix, moving to next." 2>&1 | tee -a $logpath/setperms.log
			# If any files are found then pass to while loop to set permissions
			else			
				while read line; do
						# Wiping ACL & Perms
						chflags nouchg "$line" 2>&1 | tee -a $logpath/setperms.log
						chflags nohidden "$line" 2>&1 | tee -a $logpath/setperms.log
						chflags nouappnd "$line" 2>&1 | tee -a $logpath/setperms.log
						# Set permissions rwxrwxrwx for each file
						chmod 777 "$line" 2>&1 | tee -a $logpath/setperms.log
				done < "$TempPath/$userfolder";
				echo "Fixed files, done." 2>&1 | tee -a $logpath/setperms.log
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder";
			fi
		# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
			# verbose logging off
			chflags -R -L nouchg $homefolderdir/$userfolder/;
			chflags -R -L nohidden $homefolderdir/$userfolder/;
			chflags -R -L nouappnd $homefolderdir/$userfolder/;
			# Write the unknown-files found to a file in /Scripts/temp/
			echo "Scanning $userfolder for files owned by _unknown user";
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
			# iterate by reading each line of the temp file
			count=`(wc -l < $TempPath/$userfolder)`;
			echo "Found"'' $count "files owned by unknown user in $userfolder's directory.";
			# If zero files owned by unknown user are found then skip
			if  [ $count == 0 ]; then
				echo "No Files to fix, moving to next.";
			# If any files are found then pass to while loop to set permissions
			else			
				while read line; do
						# Wiping ACL & Perms
						chflags nouchg "$line";
						chflags nohidden "$line";
						chflags nouappnd "$line";
						# Set permissions rwxrwxrwx for each file
						chmod 777 "$line";
				done < "$TempPath/$userfolder";
				echo "Fixed files, done."
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder";
			fi
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
			# verbose logging off
			# no echo annoucement
			chflags -f -R -L nouchg $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			chflags -f -R -L nohidden $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			chflags -f -R -L nouappnd $homefolderdir/$userfolder/ >> /dev/null 2>&1;
			# Write the unknown-files found to a file in /Scripts/temp/
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder >> /dev/null 2>&1;
			# iterate by reading each line of the temp file
			count=`(wc -l < $TempPath/$userfolder)` >> /dev/null 2>&1;
			# If its not zero files found, they are passed to while loop
			if  [ $count != 0 ]; then
			# If any files are found, then pass to while loop to set permissions		
				while read line; do
					# Wiping ACL & Perms
					chflags -f nouchg "$line" >> /dev/null 2>&1;
					chflags -f nohidden "$line" >> /dev/null 2>&1;
					chflags -f nouappnd "$line" >> /dev/null 2>&1;
					# Set permissions rwxrwxrwx for each file
					chmod 777 "$line" >> /dev/null 2>&1;
				done < "$TempPath/$userfolder";
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder" >> /dev/null 2>&1;
			fi
		# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
			# error
			echo "error: logging is on when everything else is forced silent"
			exit
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
			# verbose logging on
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
			# Write the unknown-files found to a file in /Scripts/temp/
			echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user" 2>&1 | tee -a $logpath/setperms.log
			echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder" 2>&1 | tee -a $logpath/setperms.log
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
			# iterate by reading each line of the temp file
			echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`" 2>&1 | tee -a $logpath/setperms.log
			count=`(wc -l < $TempPath/$userfolder)`;
			echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory." 2>&1 | tee -a $logpath/setperms.log
			# If zero files owned by unknown user are found then skip
			if  [ $count == 0 ]; then
				echo "ANNOUCEMENT:		No Files to fix, moving to next." 2>&1 | tee -a $logpath/setperms.log
			# If any files are found then pass to while loop to set permissions
			else			
				while read line; do
						# Wiping ACL & Perms
						echo "COMMAND:		chflags -v nouchg $line" 2>&1 | tee -a $logpath/setperms.log
						chflags -v nouchg "$line" 2>&1 | tee -a $logpath/setperms.log
						echo "COMMAND:		chflags -v nohidden $line" 2>&1 | tee -a $logpath/setperms.log
						chflags -v nohidden "$line" 2>&1 | tee -a $logpath/setperms.log
						echo "COMMAND:		chflags -v nouappnd $line" 2>&1 | tee -a $logpath/setperms.log
						chflags -v nouappnd "$line" 2>&1 | tee -a $logpath/setperms.log
						# Set permissions rwxrwxrwx for each file
						echo "COMMAND:		chmod -v 777 $line" 2>&1 | tee -a $logpath/setperms.log
						chmod -v 777 "$line" 2>&1 | tee -a $logpath/setperms.log
				done < "$TempPath/$userfolder";
				echo "ANNOUCEMENT:		Fixed files, done." 2>&1 | tee -a $logpath/setperms.log
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder";
			fi
		# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
		elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
			# verbose logging off
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/";
			chflags -v -R -L nouchg $homefolderdir/$userfolder/;
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/";
			chflags -v -R -L nohidden $homefolderdir/$userfolder/;
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/";
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/;
			# Write the unknown-files found to a file in /Scripts/temp/
			echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user";
			echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder";
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
			# iterate by reading each line of the temp file
			echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`";
			count=`(wc -l < $TempPath/$userfolder)`;
			echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory.";
			# If zero files owned by unknown use are found then skip
			if  [ $count == 0 ]; then
				echo "ANNOUCEMENT:		No Files to fix, moving to next.";
			# If any files are found then pass to while loop to set permissions
			else			
				while read line; do
						# Wiping ACL & Perms
						echo "COMMAND:		chflags -v nouchg $line";
						chflags -v nouchg "$line";
						echo "COMMAND:		chflags -v nohidden $line";
						chflags -v nohidden "$line";
						echo "COMMAND:		chflags -v nouappnd $line";
						chflags -v nouappnd "$line";
						# Set permissions rwxrwxrwx for each file
						echo "COMMAND:		chmod -v 777 $line";
						chmod -v 777 "$line";
				done < "$TempPath/$userfolder";
				echo "ANNOUCEMENT:		Fixed files, done.";
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder";
			fi
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
			#verbose logging on
			echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nouchg $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nohidden $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
			chflags -v -R -L nouappnd $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
			# Write the unknown-files found to a file in /Scripts/temp/
			echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user" >> $logpath/setperms.log 2>&1;
			echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder" >> $logpath/setperms.log 2>&1;
			find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
			# iterate by reading each line of the temp file
			echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`" >> $logpath/setperms.log 2>&1;
			count=`(wc -l < $TempPath/$userfolder)`;
			echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory." >> $logpath/setperms.log 2>&1;
			# If zero files owned by unknown user are found then skip
			if  [ $count == 0 ]; then
				echo "ANNOUCEMENT:		No Files to fix, moving to next." >> $logpath/setperms.log 2>&1;
			# If any files are found then pass to while loop to set permissions
			else			
				while read line;
					do
						# Wiping ACL & Perms
						echo "COMMAND:		chflags -v nouchg $line" >> $logpath/setperms.log 2>&1;
						chflags -v nouchg "$line" >> $logpath/setperms.log 2>&1;
						echo "COMMAND:		chflags -v nohidden $line" >> $logpath/setperms.log 2>&1;
						chflags -v nohidden "$line" >> $logpath/setperms.log 2>&1;
						echo "COMMAND:		chflags -v nouappnd $line" >> $logpath/setperms.log 2>&1;
						chflags -v nouappnd "$line" >> $logpath/setperms.log 2>&1;
						# Set permissions rwxrwxrwx for each file
						echo "COMMAND:		chmod -v 777 $line" >> $logpath/setperms.log 2>&1;
						chmod -v 777 "$line" >> $logpath/setperms.log 2>&1;
				done < "$TempPath/$userfolder";
				echo "ANNOUCEMENT:		Fixed files, done." >> $logpath/setperms.log 2>&1;
				sleep 3;
				# Removes temp file created
				rm "$TempPath/$userfolder";
			fi
		# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
		elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
			# error
			echo "error: logging off when verbose flag is called but terminal screen is forced silent"
			exit
		fi
	fi
done
# For loop close
# Removes temp folder created
rm -r "$TempPath"
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unknown User Fix ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Shared Folder Fix vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Fix Shared folder perms
chown -R $cadmin $homefolderdir/Shared/ >> /dev/null 2>&1;
chmod -R 771 $homefolderdir/Shared/ >> /dev/null 2>&1;
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Shared Folder Fix ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Logging vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Comment/Uncomment this section if you wish to enable/disbale record logging
echo $logentry >> $logpath/setpermsHISTORY.log
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Logging ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Close vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
sleep 1;
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "on" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "Done." 2>&1 | tee -a $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "Elapsed Time: $timeelapse" 2>&1 | tee -a $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "off" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo "Done."
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "Elapsed Time: $timeelapse"

# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "silent" && "$flag3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "on" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "ANNOUCEMENT:		Done." 2>&1 | tee -a $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse" 2>&1 | tee -a $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "off" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo "ANNOUCEMENT:		Done."
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse"
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "on" ]]; then
	#verbose logging on
	echo "ANNOUCEMENT:		Done." >> $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse" >> $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit
fi
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Close ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
}






setoneuserperms()
{
if [[ "$userfolder" == "null" ]]; then
	echo "error: no user specified"
	exit
fi

#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Variable Assigment vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# if  [verboseMENU is set(on) and verboseFLAGS is any and logging is on] or [verboseMENU is default(on) and verboseFLAGS is any and logging is on]
if [[ "$mode1" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "Set User Permissions Script  by  Chris Waian, Robert M Hadley Company  2013" 2>&1 | tee -a $logpath/setperms.log;
	echo "-----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;
	echo "Leave answers blank for defaults." 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Set username
	echo "What user?" 2>&1 | tee -a $logpath/setperms.log;
	read User;
	if  [[ "$User" == "" ]]; then
		userfolder=$UserFolder
	else
		userfolder=$User
	fi
	echo "CHOICE:		$userfolder" >> $logpath/setperms.log 2>&1;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Set path of the folder holding all user home folders.
	echo "Where is the users homefolders located?	         (Default = $DefaultPath)" 2>&1 | tee -a $logpath/setperms.log;
	read path;
	if  [[ "$path" == "" ]]; then
		Path=$DefaultPath
	else
		Path=$path
	fi
	# Finds if there is a slash a the end of the string and strips it if there is
	case $Path in
	     */) homefolderdir=${Path%?};;
	     *) homefolderdir=$Path;;
	esac
	echo "CHOICE:		$homefolderdir" >> $logpath/setperms.log 2>&1;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	echo "" 2>&1 | tee -a $logpath/setperms.log;
	# Asks temporary folder to hold files created by the script
	echo "Temporary Folder?  (Default = $DefaultTempDir)" 2>&1 | tee -a $logpath/setperms.log;
	read Temporaryfolder;
	case $Temporaryfolder in
	     */) temporaryfolder=${Temporaryfolder%?};;
	     *) temporaryfolder=$Temporaryfolder;;
	esac
	if  [[ "$temporaryfolder" == "" ]]; then
		TempDir=$DefaultTempDir
	else
		TempDir=$temporaryfolder
	fi
	echo "CHOICE:		$TempDir" >> $logpath/setperms.log 2>&1;
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: $userfolder  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempPath=$TempDir/$TempFolder
	echo "TEMPFOLDER:		$TempPath" >> $logpath/setperms.log 2>&1;
	cd "$TempDir/"
	mkdir $TempFolder >> $logpath/setperms.log 2>&1;
	#-------------Logging-----------------------------------
# if  [verboseMENU is set(on) and verboseFLAGS is any and logging is off] or [verboseMENU is default(on) and verboseFLAGS is any and logging is off]
elif [[ "$mode1" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "Set User Permissions Script  by  Chris Waian, Robert M Hadley Company  2013";
	echo "-----------------------------------------------------------------------------------";
	echo "Leave answers blank for defaults."
	echo ""
	# Set username
	echo "What user?"
	read User;
	if  [[ "$User" == "" ]]; then
		userfolder=$UserFolder
	else
		userfolder=$User
	fi
	echo ""
	echo ""
	echo ""
	# Set path of the folder holding all user home folders.
	echo "Where is the users homefolders located?	         (Default = $DefaultPath)";
	read path;
	if  [[ "$path" == "" ]]; then
		Path=$DefaultPath
	else
		Path=$path
	fi
	# Finds if there is a slash a the end of the string and strips it if there is
	case $Path in
	     */) homefolderdir=${Path%?};;
	     *) homefolderdir=$Path;;
	esac
	echo ""
	echo ""
	echo ""
	# Asks temporary folder to hold files created by the script
	echo "Temporary Folder?  (Default = $DefaultTempDir)";
	read Temporaryfolder;
	case $Temporaryfolder in
	     */) temporaryfolder=${Temporaryfolder%?};;
	     *) temporaryfolder=$Temporaryfolder;;
	esac
	if  [[ "$temporaryfolder" == "" ]]; then
		TempDir=$DefaultTempDir
	else
		TempDir=$temporaryfolder
	fi
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: $userfolder  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempPath=$TempDir/$TempFolder
	cd "$TempDir/"
	mkdir $TempFolder
	#-------------Logging-----------------------------------
# if  [verboseMENU is set(off) and verboseFLAGS is any and logging is on]
elif [[ "$mode1" = "silent" ]]; then
	if  [[ "$UserFolder" != "" ]]; then
		userfolder=$UserFolder
	else
		exit
	fi
	# Finds if there is a slash a the end of the string and strips it if there is
	case $DefaultPath in
	     */) homefolderdir=${DefaultPath%?};;
	     *) homefolderdir=$DefaultPath;;
	esac
	# sets complete path to temporary folder that is created
	TempPath=$TempDir/$TempFolder
	#-------------Logging-----------------------------------
	# Specificy script name
	scriptname="   User: $userfolder  screen=$mode1 cmdflags=$mode2 logging=$mode3"
	#
	date=`date`
	logentry="$date  $scriptname completed."
	# Creating temporary folder for files made by the script
	TempFolder="unknownuserfix"
	TempPath=$TempDir/$TempFolder
	cd "$TempDir/"
	mkdir $TempFolder >> /dev/null 2>&1
	#-------------Logging-----------------------------------
else
	echo "missing flag perams"
fi
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Variable Assigment ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


if [[ "$userfolder" == "null" ]]; then
	echo "error: no user specified"
	exit
fi

starttime=`date +%s`


#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Set Perms from Array vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "Set ownership, sets owner permssions to rwx------" 2>&1 | tee -a $logpath/setperms.log;
	echo "Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" 2>&1 | tee -a $logpath/setperms.log;
	echo "Targeting \"$userfolder\" located in $homefolderdir" 2>&1 | tee -a $logpath/setperms.log;
	echo "----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;

# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "Set ownership, sets owner permssions to rwx------";
	echo "Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx";
	echo "Targeting \"$userfolder\" located in $homefolderdir";
	echo "----------------------------------------------------------------------------------";

# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
	# verbose logging on
	clear
	echo "TITLE:		Set ownership, sets owner permssions to rwx------" 2>&1 | tee -a $logpath/setperms.log;
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" 2>&1 | tee -a $logpath/setperms.log;
	echo "TITLE:		Targeting \"$userfolder\" located in $homefolderdir" 2>&1 | tee -a $logpath/setperms.log;
	echo "LINEBREAK:		----------------------------------------------------------------------------------" 2>&1 | tee -a $logpath/setperms.log;

# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
	# verbose logging off
	clear
	echo "TITLE:		Set ownership, sets owner permssions to rwx------";
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx";
	echo "TITLE:		Targeting \"$userfolder\" located in $homefolderdir";
	echo "LINEBREAK:	----------------------------------------------------------------------------------";

# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
	#verbose logging on
	echo "" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Set ownership, sets owner permssions to rwx------" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Finds and sets files owned by 'unknown user' to permssions rwxrwxrwx" >> $logpath/setperms.log 2>&1;
	echo "TITLE:		Targeting \"$userfolder\" located in $homefolderdir" >> $logpath/setperms.log 2>&1;
	echo "LINEBREAK:	----------------------------------------------------------------------------------" >> $logpath/setperms.log 2>&1;

# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
	# verbose logging off
	# no echo annoucement
	chflags -f -R -L nouchg $homefolderdir/$userfolder/ >> /dev/null 2>&1;
	chflags -f -R -L nohidden $homefolderdir/$userfolder/ >> /dev/null 2>&1;
	chflags -f -R -L nouappnd $homefolderdir/$userfolder/ >> /dev/null 2>&1;
fi
# If entry from array contains a period (.) then mark as skipped
if  [[ "$userfolder" == .* || "$userfolder" == "Shared" ]]; then
	# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
	if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
		# verbose logging on
		echo "Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
	# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
	elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
		# verbose logging off
		echo "Skipping $userfolder."
	# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
	elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
		# error
		echo "error: logging is on when everything else is forced silent"
		exit
	# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
	elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
		# verbose logging on
		echo "ANNOUCEMENT:		Skipping $userfolder." 2>&1 | tee -a $logpath/setperms.log
	# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
	elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
		# verbose logging off
		echo "ANNOUCEMENT:		Skipping $userfolder."
	# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
	elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
		#verbose logging on
		echo "ANNOUCEMENT:		Skipping $userfolder." >> $logpath/setperms.log 2>&1;

	# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
	elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
		# error
		echo "error: logging off when verbose flag is called but terminal screen is forced silent"
		exit
	fi
# Everything else, (the good usernames) get sent through these commands
else
	# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
	if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
		# verbose logging on
		# Wipe ACL
		echo "Wiping and setting ACL for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		chflags -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		chflags -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		chflags -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		chmod -RN $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "ACL for $userfolder complete." 2>&1 | tee -a $logpath/setperms.log
		# Set Users folder ownership			
		echo "Setting $userfolder as owner of $homefolderdir/$userfolder/." 2>&1 | tee -a $logpath/setperms.log
		chown -R $userfolder:$usergroup $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "Completed ownership for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		sleep 1;
		# Set permissions for the Users files
		echo "Setting permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		chmod -R 700 $homefolderdir/$userfolder/;
		echo "Completed permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		sleep 1;
	# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
	elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
		# verbose logging off
		# Wipe ACL
		echo "Wiping and setting ACL for $userfolder.";
		chflags -R -L nouchg $homefolderdir/$userfolder/;
		chflags -R -L nohidden $homefolderdir/$userfolder/;
		chflags -R -L nouappnd $homefolderdir/$userfolder/;
		chmod -RN $homefolderdir/$userfolder/;
		echo "ACL for $userfolder complete.";
		# Set Users folder ownership			
		echo "Setting $userfolder as owner of $homefolderdir/$userfolder/.";
		chown -R $userfolder:$usergroup $homefolderdir/$userfolder/;
		echo "Completed ownership for $userfolder.";
		sleep 1;
		# Set permissions for the Users files
		echo "Setting permissions for $userfolder.";
		chmod -R 700 $homefolderdir/$userfolder/;
		echo "Completed permissions for $userfolder.";
		sleep 1;
	# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
	elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
		# verbose logging off
		# no echo annoucement
		# Wipe ACL
		chflags -f -R -L nouchg $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		chflags -f -R -L nohidden $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		chflags -f -R -L nouappnd $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		chmod -f -RN $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		# Set Users folder ownership			
		chown -f -R $userfolder:$usergroup $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		sleep 1;
		# Set permissions for the Users files
		chmod -f -R 700 $homefolderdir/$userfolder/ >> /dev/null 2>&1;
		sleep 1;
	# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
	elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
		# error
		echo "error: logging is on when everything else is forced silent"
		exit
	# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
	elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
		# verbose logging on
		# Wipe ACL
		echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chflags -v -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chflags -v -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chflags -v -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chmod -v -RN $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "ANNOUCEMENT:		ACL for $userfolder complete." 2>&1 | tee -a $logpath/setperms.log
		sleep 1;
		# Set Users folder ownership			
		echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/." 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "ANNOUCEMENT:		Completed ownership for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		sleep 1;
		# Set permissions for the Users files
		echo "ANNOUCEMENT:		Setting permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
		chmod -v -R 700 $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
		echo "ANNOUCEMENT:		Completed permissions for $userfolder." 2>&1 | tee -a $logpath/setperms.log
		sleep 1;
	# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
	elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
		# verbose logging off
		echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder.";
		echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/";
		chflags -v -R -L nouchg $homefolderdir/$userfolder/;
		echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/";
		chflags -v -R -L nohidden $homefolderdir/$userfolder/;
		echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/";
		chflags -v -R -L nouappnd $homefolderdir/$userfolder/;
		echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/";
		chmod -v -RN $homefolderdir/$userfolder/;
		echo "ANNOUCEMENT:		ACL for $userfolder complete.";
		sleep 1;
		# Set Users folder ownership			
		echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/.";
		echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/";
		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/;
		echo "ANNOUCEMENT:		Completed ownership for $userfolder.";
		sleep 1;
		# Set permissions for the Users files
		echo "ANNOUCEMENT:		Setting permissions for $userfolder.";
		echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/";
		chmod -v -R 700 $homefolderdir/$userfolder/;
		echo "ANNOUCEMENT:		Completed permissions for $userfolder.";
	# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
	elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
		#verbose logging on
		echo "ANNOUCEMENT:		Wiping and setting ACL for $userfolder." >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chflags -v -R -L nouchg $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chflags -v -R -L nohidden $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chflags -v -R -L nouappnd $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chmod -v -RN $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chmod -v -RN $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "ANNOUCEMENT:		ACL for $userfolder complete." >> $logpath/setperms.log 2>&1;
		sleep 1;
		# Set Users folder ownership			
		echo "ANNOUCEMENT:		Setting $userfolder as owner of $homefolderdir/$userfolder/." >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chown -v -R $userfolder:$usergroup $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "ANNOUCEMENT:		Completed ownership for $userfolder." >> $logpath/setperms.log 2>&1;
		sleep 1;
		# Set permissions for the Users files
		echo "ANNOUCEMENT:		Setting permissions for $userfolder." >> $logpath/setperms.log 2>&1;
		echo "COMMAND:		chmod -v -R 700 $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
		chmod -v -R 700 $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
		echo "ANNOUCEMENT:		Completed permissions for $userfolder." >> $logpath/setperms.log 2>&1;
	# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
	elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
		# error
		echo "error: logging off when verbose flag is called but terminal screen is forced silent"
		exit
	fi
fi

sleep 3;
# For loop close
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  Set Perms from Array ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Unknown User Fix vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "on" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "on" ]]; then
	# verbose logging on
	chflags -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	chflags -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	chflags -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	# Write the unknown-files found to a file in /Scripts/temp/
	echo "Scanning $userfolder for files owned by _unknown user" 2>&1 | tee -a $logpath/setperms.log
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
	# iterate by reading each line of the temp file
	count=`(wc -l < $TempPath/$userfolder)`;
	echo "Found"'' $count "files owned by unknown user in $userfolder's directory." 2>&1 | tee -a $logpath/setperms.log
	# If zero files owned by unknown user are found then skip
	if  [ $count == 0 ]; then
		echo "No Files to fix, moving to next." 2>&1 | tee -a $logpath/setperms.log
	# If any files are found then pass to while loop to set permissions
	else			
		while read line; do
				# Wiping ACL & Perms
				chflags nouchg "$line" 2>&1 | tee -a $logpath/setperms.log
				chflags nohidden "$line" 2>&1 | tee -a $logpath/setperms.log
				chflags nouappnd "$line" 2>&1 | tee -a $logpath/setperms.log
				# Set permissions rwxrwxrwx for each file
				chmod 777 "$line" 2>&1 | tee -a $logpath/setperms.log
		done < "$TempPath/$userfolder";
		echo "Fixed files, done." 2>&1 | tee -a $logpath/setperms.log
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder";
	fi
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "silent" && "$mode3" = "off" ]] ||  [[ "$mode1" = "verbose" && "$mode2" = "default" && "$mode3" = "off" ]]; then
	# verbose logging off
	chflags -R -L nouchg $homefolderdir/$userfolder/;
	chflags -R -L nohidden $homefolderdir/$userfolder/;
	chflags -R -L nouappnd $homefolderdir/$userfolder/;
	# Write the unknown-files found to a file in /Scripts/temp/
	echo "Scanning $userfolder for files owned by _unknown user";
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
	# iterate by reading each line of the temp file
	count=`(wc -l < $TempPath/$userfolder)`;
	echo "Found"'' $count "files owned by unknown user in $userfolder's directory.";
	# If zero files owned by unknown user are found then skip
	if  [ $count == 0 ]; then
		echo "No Files to fix, moving to next.";
	# If any files are found then pass to while loop to set permissions
	else			
		while read line; do
				# Wiping ACL & Perms
				chflags nouchg "$line";
				chflags nohidden "$line";
				chflags nouappnd "$line";
				# Set permissions rwxrwxrwx for each file
				chmod 777 "$line";
		done < "$TempPath/$userfolder";
		echo "Fixed files, done."
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder";
	fi
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "off" ]]; then
	# verbose logging off
	# no echo annoucement
	chflags -f -R -L nouchg $homefolderdir/$userfolder/ >> /dev/null 2>&1;
	chflags -f -R -L nohidden $homefolderdir/$userfolder/ >> /dev/null 2>&1;
	chflags -f -R -L nouappnd $homefolderdir/$userfolder/ >> /dev/null 2>&1;
	# Write the unknown-files found to a file in /Scripts/temp/
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder >> /dev/null 2>&1;
	# iterate by reading each line of the temp file
	count=`(wc -l < $TempPath/$userfolder)` >> /dev/null 2>&1;
	# If its not zero files found, they are passed to while loop
	if  [ $count != 0 ]; then
	# If any files are found, then pass to while loop to set permissions		
		while read line; do
			# Wiping ACL & Perms
			chflags -f nouchg "$line" >> /dev/null 2>&1;
			chflags -f nohidden "$line" >> /dev/null 2>&1;
			chflags -f nouappnd "$line" >> /dev/null 2>&1;
			# Set permissions rwxrwxrwx for each file
			chmod 777 "$line" >> /dev/null 2>&1;
		done < "$TempPath/$userfolder";
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder" >> /dev/null 2>&1;
	fi
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "silent" && "$mode3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "on" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "on" ]]; then
	# verbose logging on
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
	chflags -v -R -L nouchg $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
	chflags -v -R -L nohidden $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" 2>&1 | tee -a $logpath/setperms.log
	chflags -v -R -L nouappnd $homefolderdir/$userfolder/ 2>&1 | tee -a $logpath/setperms.log
	# Write the unknown-files found to a file in /Scripts/temp/
	echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user" 2>&1 | tee -a $logpath/setperms.log
	echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder" 2>&1 | tee -a $logpath/setperms.log
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
	# iterate by reading each line of the temp file
	echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`" 2>&1 | tee -a $logpath/setperms.log
	count=`(wc -l < $TempPath/$userfolder)`;
	echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory." 2>&1 | tee -a $logpath/setperms.log
	# If zero files owned by unknown user are found then skip
	if  [ $count == 0 ]; then
		echo "ANNOUCEMENT:		No Files to fix, moving to next." 2>&1 | tee -a $logpath/setperms.log
	# If any files are found then pass to while loop to set permissions
	else			
		while read line; do
				# Wiping ACL & Perms
				echo "COMMAND:		chflags -v nouchg $line" 2>&1 | tee -a $logpath/setperms.log
				chflags -v nouchg "$line" 2>&1 | tee -a $logpath/setperms.log
				echo "COMMAND:		chflags -v nohidden $line" 2>&1 | tee -a $logpath/setperms.log
				chflags -v nohidden "$line" 2>&1 | tee -a $logpath/setperms.log
				echo "COMMAND:		chflags -v nouappnd $line" 2>&1 | tee -a $logpath/setperms.log
				chflags -v nouappnd "$line" 2>&1 | tee -a $logpath/setperms.log
				# Set permissions rwxrwxrwx for each file
				echo "COMMAND:		chmod -v 777 $line" 2>&1 | tee -a $logpath/setperms.log
				chmod -v 777 "$line" 2>&1 | tee -a $logpath/setperms.log
		done < "$TempPath/$userfolder";
		echo "ANNOUCEMENT:		Fixed files, done." 2>&1 | tee -a $logpath/setperms.log
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder";
	fi
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$mode1" = "verbose" && "$mode2" = "verbose" && "$mode3" = "off" ]] ||  [[ "$mode1" = "default" && "$mode2" = "vebose" && "$mode3" = "off" ]]; then
	# verbose logging off
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/";
	chflags -v -R -L nouchg $homefolderdir/$userfolder/;
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/";
	chflags -v -R -L nohidden $homefolderdir/$userfolder/;
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/";
	chflags -v -R -L nouappnd $homefolderdir/$userfolder/;
	# Write the unknown-files found to a file in /Scripts/temp/
	echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user";
	echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder";
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
	# iterate by reading each line of the temp file
	echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`";
	count=`(wc -l < $TempPath/$userfolder)`;
	echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory.";
	# If zero files owned by unknown use are found then skip
	if  [ $count == 0 ]; then
		echo "ANNOUCEMENT:		No Files to fix, moving to next.";
	# If any files are found then pass to while loop to set permissions
	else			
		while read line; do
				# Wiping ACL & Perms
				echo "COMMAND:		chflags -v nouchg $line";
				chflags -v nouchg "$line";
				echo "COMMAND:		chflags -v nohidden $line";
				chflags -v nohidden "$line";
				echo "COMMAND:		chflags -v nouappnd $line";
				chflags -v nouappnd "$line";
				# Set permissions rwxrwxrwx for each file
				echo "COMMAND:		chmod -v 777 $line";
				chmod -v 777 "$line";
		done < "$TempPath/$userfolder";
		echo "ANNOUCEMENT:		Fixed files, done.";
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder";
	fi
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "on" ]]; then
	#verbose logging on
	echo "COMMAND:		chflags -v -R -L nouchg $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nouchg $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		chflags -v -R -L nohidden $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nohidden $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		chflags -v -R -L nouappnd $homefolderdir/$userfolder/" >> $logpath/setperms.log 2>&1;
	chflags -v -R -L nouappnd $homefolderdir/$userfolder/ >> $logpath/setperms.log 2>&1;
	# Write the unknown-files found to a file in /Scripts/temp/
	echo "ANNOUCEMENT:		Scanning $userfolder for files owned by _unknown user" >> $logpath/setperms.log 2>&1;
	echo "COMMAND:		find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder" >> $logpath/setperms.log 2>&1;
	find $homefolderdir/$userfolder/ -uid 99 > $TempPath/$userfolder;
	# iterate by reading each line of the temp file
	echo "COMMAND:		count=`(wc -l < $TempPath/$userfolder)`" >> $logpath/setperms.log 2>&1;
	count=`(wc -l < $TempPath/$userfolder)`;
	echo "ANNOUCEMENT:		Found"'' $count "files owned by unknown user in $userfolder's directory." >> $logpath/setperms.log 2>&1;
	# If zero files owned by unknown user are found then skip
	if  [ $count == 0 ]; then
		echo "ANNOUCEMENT:		No Files to fix, moving to next." >> $logpath/setperms.log 2>&1;
	# If any files are found then pass to while loop to set permissions
	else			
		while read line;
			do
				# Wiping ACL & Perms
				echo "COMMAND:		chflags -v nouchg $line" >> $logpath/setperms.log 2>&1;
				chflags -v nouchg "$line" >> $logpath/setperms.log 2>&1;
				echo "COMMAND:		chflags -v nohidden $line" >> $logpath/setperms.log 2>&1;
				chflags -v nohidden "$line" >> $logpath/setperms.log 2>&1;
				echo "COMMAND:		chflags -v nouappnd $line" >> $logpath/setperms.log 2>&1;
				chflags -v nouappnd "$line" >> $logpath/setperms.log 2>&1;
				# Set permissions rwxrwxrwx for each file
				echo "COMMAND:		chmod -v 777 $line" >> $logpath/setperms.log 2>&1;
				chmod -v 777 "$line" >> $logpath/setperms.log 2>&1;
		done < "$TempPath/$userfolder";
		echo "ANNOUCEMENT:		Fixed files, done." >> $logpath/setperms.log 2>&1;
		sleep 3;
		# Removes temp file created
		rm "$TempPath/$userfolder";
	fi
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$mode1" = "silent" && "$mode2" = "verbose" && "$mode3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit
fi


# Removes temp folder created
rm -r "$TempPath"
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unknown User Fix ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Logging vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Comment/Uncomment this section if you wish to enable/disbale record logging
echo $logentry >> $logpath/setpermsHISTORY.log
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Logging ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Close vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
sleep 1;
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "on" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "Done." 2>&1 | tee -a $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "Elapsed Time: $timeelapse" 2>&1 | tee -a $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "off" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo "Done."
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "Elapsed Time: $timeelapse"

# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "silent" && "$flag3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "on" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "ANNOUCEMENT:		Done." 2>&1 | tee -a $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse" 2>&1 | tee -a $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "off" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo "ANNOUCEMENT:		Done."
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse"
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "on" ]]; then
	#verbose logging on
	echo "ANNOUCEMENT:		Done." >> $logpath/setperms.log
	stoptime=`date +%s`
	timesec=$(( ${stoptime}-${starttime} ))
	timemin=$(( ${timesec}/60 ))
	if [[ "$timesec" -gt "60" ]]; then
		timeelapse="$timemin min"
	elif [[ "$timesec" -lt "60" ]]; then
		timeelapse="$timesec sec"
	fi
	echo "ANNOUCEMENT:		Elapsed Time: $timeelapse" >> $logpath/setperms.log
	dateMDY=`date +"%m_%d_%Y-%Hhr%Mmin"`
	cp $logpath/setperms.log $logpath/setpermsRECENTlog.log;
	mv $logpath/setperms.log $logpath/old/"$dateMDY".log;
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit
fi
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Close ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
}

if [[ "$uflag" == "on" ]];
	then
		setoneuserperms
	# need to pass variable $flaguser to $userfolder:     userfolder=$flaguser??
elif [[ "$uflag" == "default" ]];
	then
		setalluserperms
else
	echo "could not determine single user mode or all users mode"
	exit
fi