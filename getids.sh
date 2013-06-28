#!/bin/bash
# Copyright (c) 2013, Chris Waian & Tim Waian All rights reserved.
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

# reused file / semi-perm log
temppath="/Users/calcium/Scripts/logs/getids"
path="$temppath/getids.log"
starttime=`date +%s`
date=`date`

usage() {
cat <<'EOF'
getids [OPTIONS] NAME [...]

Grabs group name, PrimaryGroupID, UniqueID, & GeneratedUID data.

 Options:
	-h, --help				display this help and exit

	-u, --user				Single User Mode: requires argument

	-g, --group				Single Group Mode: requires argument

	-y, --userall				Lists All User	

	-f, --groupall				Lists All Groups
EOF
}

gflag="default";
uflag="default";
fflag="default";
yflag="default";

optstring=gufy

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
    -g|--group)
      gflag="on";
      arggroup=$2;
      shift;
      ;;
    -u|--user)
      uflag="on";
      arguser=$2;
      shift;
      ;;
    -f|--groupall)
      fflag="on";
      ;;
    -y|--userall)
      yflag="on";
      ;;
    -h|--help) usage >&2; exit 0;;
    --endopts) shift; break;;
    *) die "invalid option: $1";;
  esac

  shift
done



postuserinfo ()
{
	userID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* UniqueID`; #calls external open directory program
	#reads user data into var
	userGUID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* GeneratedUID`; #calls external open directory program
	echo "   User Name:	$*";
	echo "    UniqueID:	${userID:10}";
	echo "GeneratedUID:	${userGUID:14}";
}

postalluserinfo ()
{
	userlist=( `(dscl /LDAPv3/127.0.0.1 -list /Users)` ); #calls external open directory program
	#External program grabs user list and puts into an array
	for user in "${userlist[@]}"; 
	do
		if [[ "$user" = _* ]] || [[ "$user" = "vpn_cff87b032787" ]]; #ignoring anything that starts with: underscore and one user
		then 
			echo "do nothing" >> /dev/null;
		else 
			postuserinfo "$user"; #iterates each entry in the array
			echo "";
			echo "";
		fi
	done
}



postgroupinfo ()
{
	groupID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$* PrimaryGroupID`; #calls external open directory program
	#reads group data into var
	groupGUID=`dscl /LDAPv3/127.0.0.1 -read /Groups/$* GeneratedUID`; #calls external open directory program
	echo "    Group Name:	$*";
	echo "PrimaryGroupID:	${groupID:16}";
	echo "  GeneratedUID:	${groupGUID:14}";
}

postallgroupinfo ()
{
	grouplistall=( `(dscl /LDAPv3/127.0.0.1 -list /Groups)` ); #calls external open directory program
	#External program grabs group list and puts into an array
	 for var in "${grouplistall[@]}";
	 do
	 	if [[ "$var" = com.* ]]; then #ignoring anything that starts with: com.
	 		echo "do nothing" >> /dev/null;
	 	else
	 		postgroupinfo "$var"; #iterates each entry in the array
	 		echo "";
	 		echo "";
	 	fi
	 done
}




main ()
{

if [[ "$gflag" = "on" ]] && [[ "$uflag" = "default" ]] && [[ "$fflag" = "default" ]] && [[ "$yflag" = "default" ]]; then
	if [[ "$arggroup" = "" ]]; then
		echo "error: arguments required";
		exit;
	else
		postgroupinfo  $arggroup;
	fi
elif [[ "$gflag" = "default" ]] && [[ "$uflag" = "on" ]] && [[ "$fflag" = "default" ]] && [[ "$yflag" = "default" ]]; then
	if [[ "$arguser" = "" ]]; then
		echo "error: arguments required";
		exit;
	else
		postuserinfo $arguser;
	fi
elif [[ "$gflag" = "default" ]] && [[ "$uflag" = "default" ]] && [[ "$fflag" = "on" ]] && [[ "$yflag" = "default" ]]; then
postallgroupinfo;
elif [[ "$gflag" = "default" ]] && [[ "$uflag" = "default" ]] && [[ "$fflag" = "default" ]] && [[ "$yflag" = "on" ]]; then
postalluserinfo;
else
	echo "error: too many options";
	exit;
fi
}


echo "$date" > $path;
echo "" >> $path
main | tee -a $path;
open -t $path;


endtime=`date +%s`;
timesec=$(( ${endtime}-${starttime} ));
timemin=$(( ${timesec}/60 ));
if [[ "$timesec" -gt "60" ]]; then
	timeelapse="$timemin min";
elif [[ "$timesec" -lt "60" ]]; then
	timeelapse="$timesec sec";
fi
echo "$timeelapse time has elapsed.";


exit;
