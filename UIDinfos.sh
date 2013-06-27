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

usage() {
cat <<'EOF'
setallperms [OPTIONS] NAME [...]

Sets permissions for all users in the shared home folder directory.

 Options:
	-h, --help				display this help and exit

	-s, --silent			screen off, nothing displayed to terminal window

	-v, --verbose			verbose, displays commands and uses -v for all
							commands used by this script.

	-p, --path "/path/"		specify path for shared home folder directory

	-l, --log "/path/"		enables verbose logging, location is optional,
							default will be used if none is specified.

	-a, --admin 			set Client Administrator, (short name required)

	-t, --tempdir "/path/"	specify temp directory, otherwise you will be asked
							or defualts will be used.

EOF
}

sflag="default";
vflag="default";
lflag="default";
flaglogdir="default";
flagtempdir="default";
flagadmin="default";
flagpath="default";

optstring=svl

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

# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is on] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is on]
if [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "on" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "" 2>&1 | tee -a /Users/calcium/Scripts/logs/set_all_perms/log.log
	command statement 2>&1 | tee -a /Users/calcium/Scripts/logs/set_all_perms/log.log
# if  [verboseMENU is set(on) and verboseFLAGS is off and logging is off] or [verboseMENU is set(on) and verboseFLAGS is default(off) and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "silent" && "$flag3" = "off" ]] ||  [[ "$flag1" = "verbose" && "$flag2" = "default" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo ""
	command statement


# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is off]
elif [[ "$flag1" = "silent" && "$flag2" = "silent" && "$flag3" = "off" ]]; then
	# verbose logging off
	# no echo annoucement
	command statement -f
# if  [verboseMENU is set(off) and verboseFLAGS is off and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "silent" && "$flag3" = "on" ]]; then
	# error
	echo "error: logging is on when everything else is forced silent"
	exit


# if  verboseMENU is set(on) and verboseFLAGS is on and logging is on] or verboseMENU is default(on) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "on" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "on" ]]; then
	# verbose logging on
	echo "ANNOUCEMENT:		" 2>&1 | tee -a /Users/calcium/Scripts/logs/set_all_perms/log.log
	echo "COMMAND:		" 2>&1 | tee -a /Users/calcium/Scripts/logs/set_all_perms/log.log
	command statement -v 2>&1 | tee -a /Users/calcium/Scripts/logs/set_all_perms/log.log
# if  verboseMENU is set(on) and verboseFLAGS is on and logging is off] or verboseMENU is default(on) and verboseFLAGS is on and logging is off]
elif [[ "$flag1" = "verbose" && "$flag2" = "verbose" && "$flag3" = "off" ]] ||  [[ "$flag1" = "default" && "$flag2" = "vebose" && "$flag3" = "off" ]]; then
	# verbose logging off
	echo "ANNOUCEMENT:		"
	echo "COMMAND:		"
	command statement -v
	

# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is on]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "on" ]]; then
	#verbose logging on
	echo "ANNOUCEMENT:		" >> /Users/calcium/Scripts/logs/set_all_perms/log.log
	echo "COMMAND:		" >> /Users/calcium/Scripts/logs/set_all_perms/log.log
	command statement -v >> /Users/calcium/Scripts/logs/set_all_perms/log.log
# if  [verboseMENU is set(off) and verboseFLAGS is on and logging is of]
elif [[ "$flag1" = "silent" && "$flag2" = "verbose" && "$flag3" = "off" ]]; then
	# error
	echo "error: logging off when verbose flag is called but terminal screen is forced silent"
	exit

fi

dscl /LDAPv3/127.0.0.1 -list /Groups GeneratedUID
dscl /LDAPv3/127.0.0.1 -list /Groups PrimaryGroupID
dscl /LDAPv3/127.0.0.1 -list /Users GeneratedUID
dscl /LDAPv3/127.0.0.1 -list /Users UniqueID




postuserinfo ()
{
	userID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* UniqueID`
	userGUID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* GeneratedUID`
	echo "   User Name: 		$*"
	echo "    UniqueID: 		${userID:10}"
	echo "GeneratedUID: 		${userGUID:14}"
}

postgroupinfo ()
{
	groupID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$* PrimaryGroupID`
	groupGUID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$* GeneratedUID`
	echo "    Group Name: 		$*"
	echo "PrimaryGroupID: 		${groupID:16}"
	echo "  GeneratedUID: 		${groupGUID:14}"
}

postalluserinfo ()
{
	alluserlistGUID=`dscl /LDAPv3/127.0.0.1 -list /Groups GeneratedUID | cut -d\  -f2- | sed 's/^[ \t]*//;s/[ \t]*$//'`	
	alluserlistID=`dscl /LDAPv3/127.0.0.1 -list /Groups PrimaryGroupID`
	echo "   User Name: 		$*"
	echo "    UniqueID: 		${userID:10}"
	echo "GeneratedUID: 		${userGUID:14}"
}

postallgroupinfo ()
{
	groupID=`dscl /LDAPv3/127.0.0.1 -list /Groups/ PrimaryGroupID`
	groupGUID=`dscl /LDAPv3/127.0.0.1 -list /Groups/ GeneratedUID`
	echo "    Group Name: 		$*"
	echo "PrimaryGroupID: 		${groupID:16}"
	echo "  GeneratedUID: 		${groupGUID:14}"
}


array=( `(dscl /LDAPv3/127.0.0.1 -list /Groups)` );
for entry in "${array[@]}";
do
	groupName="$entry";
	groupID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$entry PrimaryGroupID`;
	groupGUID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$entry GeneratedUID`;
	# echo "$groupName" 	"${groupID:16}  "	"  ${groupGUID:14}"
	printf '\t%-25s %-25s %-25s\n' "$groupName" "${groupID:16}" "${groupGUID:14}"
done


array=( `(dscl /LDAPv3/127.0.0.1 -list /Groups)` );
for entry in "${array[@]}";
do
	groupName="$entry";
	echo "$groupName"
done