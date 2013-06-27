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



postuserinfo ()
{
	userID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* UniqueID`; #calls external open directory program
	#reads user data into var
	userGUID=`dscl /LDAPv3/127.0.0.1 -read /Users/$* GeneratedUID`; #calls external open directory program
	echo "   User Name: 		$*";
	echo "    UniqueID: 		${userID:10}";
	echo "GeneratedUID: 		${userGUID:14}";
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
	echo "    Group Name: 		$*";
	echo "PrimaryGroupID: 		${groupID:16}";
	echo "  GeneratedUID: 		${groupGUID:14}";
}

postallgroupinfo ()
{
	grouplistall=( `(dscl /LDAPv3/127.0.0.1 -list /Groups)` ); #calls external open directory program
	#External program grabs group list and puts into an array
	 for var in "${grouplistall[@]}";
	 do
	 	if [[ "$var" = com.* ]]; then #ignoring anything that starts with: com.
	 		echo "do nothing" >> /dev/null
	 	else
	 		postgroupinfo "$var"; #iterates each entry in the array
	 		echo "";
	 		echo "";
	 	fi
	 done
}


postallgroupinfo
exit

