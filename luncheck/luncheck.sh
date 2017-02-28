#!/usr/bin/env bash
# author: @allansan
# description: count LUNs using 'cvlabel' until we have the correct numbber for the SANvol
#              when all LUNs are present, mount all  SANvols listed by 'xsanctl'
# assumptions: - mount all Xsan volumes available
#              - will be run as 'root' via LaunchDaemon
#              - xsand is configured and running
#              - all target Xsan nodes running on same OS version
################ CUSTOMISE THESE #####################
declare -r LOGIDENT="com.10dot1.luncheck"
declare -ri ALLLUNS=44
declare -ri MAXWAIT=6
declare -ri SLEEP=10
######################################################
# 
# declare -ri OS_VER=$(sw_vers -productVersion | cut -d . -f 2)
# 
declare -ra SANLIST=($(xsanctl list | awk -F " " '{ print $1 }'))
declare -i WAIT=0
# 
# 
if [[ -z "${SANLIST[@]}" ]]; then
	# something went wrong with getting a list of all SANvols, bail
	logger -t ${LOGIDENT} "********************************************************************************"
	logger -t ${LOGIDENT} "**** LUNCheck::  PANIC  ::Unable to generate list of SANvols, exiting(1)... ****"
	logger -t ${LOGIDENT} "********************************************************************************"
	exit 1
else
	# we got a list, go ahead with creating a count of all SANvols
	declare -ri SANCOUNT=${#SANLIST[@]}	
fi
# 
# 
function count_luns()
{
	echo ${FUNCNAME}
	while [[ ${WAIT} -lt ${MAXWAIT} ]]; do
		# re-check and re-set var LUNCOUNT on each loop
		LUNCOUNT=$(cvlabel -l 2>/dev/null | egrep -c acfs-EFI)
		# test how many we're seeing vs how many are necessary to mount all SANvols
		if [[ ${LUNCOUNT} -lt ${ALLLUNS} ]]; then
			# we don't have all LUNs, tell someone and bump WAIT int up 1
			logger -t ${LOGIDENT} "** Waiting for LUNs, count is at: ${LUNCOUNT} **"
			sleep ${SLEEP}
			export WAIT=$(( ${WAIT} + 1 ))
		else
			# we have all LUNs, tell somoene and exit loop
			logger -t ${LOGIDENT} "All LUNs accounted for, count is at: ${LUNCOUNT}"
			# make WAIT greater than MAXWAIT so we can test on it
			export WAIT=$(( ${MAXWAIT} + 1 ))
			break
		fi
	done
}
# 
function mount_vols()
{
	echo ${FUNCNAME}
	for i in ${SANLIST[@]}; do
		if [[ -n "$(xsanctl list | egrep $i | egrep 'not mounted')" ]]; then
			xsanctl mount $i
			if [[ -z "$(xsanctl list | egrep $i | egrep 'not mounted')" ]]; then
				logger -t ${LOGIDENT} "** Xsan Volume: $i has been mounted **"
			else
				logger -t ${LOGIDENT} "--- Xsan Volume: $i failed to mount --"
			fi
		else
			logger -t ${LOGIDENT} "Xsan Volume: $i is already mounted"
		fi
	done
}
# 
function main()
{
	echo ${FUNCNAME}
	# check we haven't already got all SANvols mounted
	if [[ $(mount | egrep -c acfs) -ne ${SANCOUNT} ]]; then
		# loop whilst we don't have all SANvols mounted
		count_luns
		# execute function to mount SANvols
		if [[ ${WAIT} -gt ${MAXWAIT} ]]; then
			mount_vols
		else
			logger -t ${LOGIDENT} "LUNCHECK unable to account for all LUNs, exiting(2) for now..."
			exit 2
		fi
	else
		logger -t ${LOGIDENT} "LUNCHECK found all Xsan volumes mounted, exiting..."
		exit 0
	fi
}
# 
# run script
main "$@"
