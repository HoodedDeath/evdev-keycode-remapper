#!/bin/bash
if [[ -z "$4" ]] || [[ "$(id -u)" -ne 0 ]]; then
	echo "This script must be run as super user and should only be run by 'evdev-keycode-remapper'. Please don't run this yourself unless you know how to provide the arguments correctly."
	exit 1
fi
alias=$1
calias=$2
prof_file=$3
evnum=$4
mkdir -p /etc/udev/hwdb.d
if [[ -f "/etc/udev/hwdb.d/${calias}-keys.hwdb" ]]; then
	rm "/etc/udev/hwdb.d/${calias}-keys.hwdb"
fi
IFS=$'\n'
arr=($(cat "$prof_file"))
unset IFS
echo "evdev:${alias}*" > "/etc/udev/hwdb.d/${calias}-keys.hwdb"
for i in ${!arr[@]}; do
	if [[ ! -z "${arr[$i]}" ]] && [[ "${arr[$i]}" != "#"* ]]; then
		echo "  ${arr[$i]}" >> "/etc/udev/hwdb.d/${calias}-keys.hwdb"
		if [[ "$?" -ne 0 ]]; then
			echo "Failed to write mapping file."
			exit 1
		fi
	fi
done
systemd-hwdb update
if [[ "$?" -ne 0 ]]; then
	echo "Failed to update hwdb."
	exit 1
fi
udevadm trigger --verbose --sysname-match="event${evnum}"
if [[ "$?" -ne 0 ]]; then
	echo "Failed to trigger udevadm."
	exit 1
fi
exit 0
