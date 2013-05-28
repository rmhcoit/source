#!/bin/bash
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