#!/bin/bash
# Make file names into consistent format
function str_to_file_name {
	# Characters accepted for file name
	ACCEPT_CHARS="-.0123456789_aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ"
	# Split input string to indivual characters
	arr=($(echo "$@" | grep -o .))
	for i in ${!arr[@]}; do
		if [[ "${ACCEPT_CHARS}" == *"${arr[$i]}"* ]]; then
			# Acceptable character, add to conv_out
			conv_out="${conv_out}${arr[$i]}"
		else
			# Unacceptable character, replace with underscore
			conv_out="${conv_out}_"
		fi
	done
	# Give converted string as output of funciton
	echo "$conv_out"
}
# Figure out which cli editor to use
function find_cli_editor {
	if [[ -f "${data_dir}/editor" ]]; then
		source "${data_dir}/editor"
	elif [[ ! -z "$(which nano)" ]]; then
		echo "Nano found and will be used for command line text editing. If you wish to change this, see readme Usage section"
		EDITOR="$(which nano)"
	elif [[ ! -z "$(which vim)" ]]; then
		echo "Vim found and will be used for command line text editing. If you wish to change this, see readme Usage section"
		EDITOR="$(which vim)"
	else
		read -p "Enter command to open command line text editor for editing profile files: " edit_ans
		EDITOR="$edit_ans"
		echo "EDITOR=$EDITOR" > "${data_dir}/editor"
	fi
}
# Figure out which gui editor to use
function find_gui_editor {
	if [[ -f "${data_dir}/graphical_editor" ]]; then
		source "${data_dir}/graphical_editor"
	elif [[ ! -z "$(which mousepad)" ]]; then
		# XFCE editor
		echo "Mousepad found and will be used for showing keycodes list file. If you wish to change this, see readme Usage section"
		GRAPHICAL_EDITOR="$(which mousepad)"
	elif [[ ! -z "$(which gedit)" ]]; then
		# GNOME editor
		echo "GEdit found and will be used for showing keycodes list file. If you wish to change this, see readme Usage section"
		GRAPHICAL_EDITOR="$(which gedit)"
	elif [[ ! -z "$(which kate)" ]]; then
		# KDE editor
		echo "Kate found and will be used for showing keycodes list file. If you wish to change this, see readme Usage section"
		GRAPHICAL_EDITOR="$(which kate)"
	else
		read -p "Enter command to open GUI text editor for displaying keycode list file: " gedit_ans
		GRAPHICAL_EDITOR="$gedit_ans"
		echo "GRAPHICAL_EDITOR=$GRAPHICAL_EDITOR" > "${data_dir}/graphical_editor"
	fi
}
# Stop execution upon non-zero exit code
set -e
# Check for keycode file missing
if [[ ! -e "/usr/share/evdev-keycode-remapper/keycodes" ]]; then
	echo "WARNING: Keycodes list file does not exist at path '/usr/share/evdev-keycode-remapper/keycodes' - Reinstall?"
fi
# Set directory for profile files and preference files
data_dir="$HOME/.local/share/evdev-keycode-remapper"
# Check data_dir exists
if [[ ! -e "$data_dir" ]]; then
	echo "Data directory doesn't exist at '${data_dir}', creating directory."
	mkdir "$data_dir"
fi
# Check EDITOR variable
if [[ -z "$EDITOR" ]]; then
	find_cli_editor
else
	echo "\$EDITOR is already set, will use that value for profile editing."
fi
# Check GRAPHICAL_EDITOR value
if [[ -z "$GRAPHICAL_EDITOR" ]]; then
	find_gui_editor
else
	echo "\$GRAPHICAL_EDITOR is already set, will use that value for showing keycodes list file."
fi
# Get events
evs=($(ls --color=never "/sys/class/input/" | grep "event"))
# Trim evs to just event numbers
for s in ${evs[@]}; do
	ev_nums=(${ev_nums[@]} ${s#"event"})
done
# Sort array of event numbers to normal numeric order
IFS=$'\n'
ev_nums_sorted=($(sort -n <<< "${ev_nums[*]}"))
unset IFS
# Display sorted events
for n in ${ev_nums_sorted[@]}; do
	echo "Event[${n}] - $(cat "/sys/class/input/event${n}/device/name")"
done
# Select input event
while true; do 
	read -p "Enter event number or cancel [#/C]: " num_ans
	case $num_ans in
		[Cc] ) echo "Canceled."; exit 1;;
		*)
			if [[ -h "/sys/class/input/event${num_ans}" ]]; then
				evnum="$num_ans"
				break
			else
				echo "Please enter a valid event number or 'c' to cancel."
			fi
	esac
done
# Get mod alias
alias="$(cat /sys/class/input/event${evnum}/device/modalias | cut -f1 -d'-')"
# Clean mod alias for use in file names
calias="$(str_to_file_name $alias)"
# Get profiles for device
if [[ ! -d "${data_dir}/profiles" ]]; then
	mkdir "${data_dir}/profiles"
fi
# Get list of profiles for selected device
if [[ ! -z "$(ls --color=never "${data_dir}/profiles/")" ]]; then
	set +e
	tarr=($(ls --color=never "${data_dir}/profiles/" | grep "$calias"))
	set -e
fi
# Trim modalias from file names of profile files
for i in ${!tarr[@]}; do
	profs=(${profs[@]} ${tarr[$i]#"${calias}\$"})
done
# Check for default profile of device
if [[ -z "${profs[@]}" ]] || [[ "${profs[@]}" != *"default"* ]]; then
	touch "${data_dir}/profiles/${calias}\$default"
	echo -e "# To create default profile, write the line 'KEYBOARD_KEY_<SCANCODE>=key_<KEYCODE>' for each key, where '<SCANCODE>' is the scan code given by 'evtest' or 'showkey --scancodes' when pressing a key and '<KEYCODE>' is the lowercase keycode for the pressed key.\n# Keycodes can be found in the file '/usr/share/evdev-keycode-remapper/keycodes' or online at https://hal.freedesktop.org/quirk/quirk-keymap-list.txt\n# evtest is to be used for USB keyboards. The scan code is the 'value' field of 'MSC_SCAN'.\n# NOTE: Comment lines starting with '#' are fine, but any empty lines may cause failure while applying a profile. I have attempted to mitigate that, but if it fails, quickly check for any empty lines in the profile file.\nKEYBOARD_KEY_<SCANCODE>=key_<KEYCODE>" > "${data_dir}/profiles/${calias}\$default"
	echo "Please create default profile for this device in file '${data_dir}/profiles/${calias}\$default' first."
	exit 1
fi
# List profiles
for i in ${!profs[@]}; do
	echo "[$i] ${profs[$i]}"
done
# Select profile
while true; do
	read -p "Enter profile number, 'n' for new, or 'c' for copy [#/N/C]: " prof_ans
	case $prof_ans in
		[Nn] )
			while true; do
				read -p "Enter name for new profile: " name_ans
				prof_name="$(str_to_file_name $name_ans)"
				if [[ -f "${data_dir}/profiles/${calias}\$${prof_name}" ]]; then
					echo "Profile name already taken."
				else
					prof=${#profs[@]}
					cp "${data_dir}/profiles/${calias}\$default" "${data_dir}/profiles/${calias}\$${prof_name}"
					profs=(${profs[@]} ${prof_name})
					break
				fi
			done;;
		[Cc] )
			while true; do
				read -p "Enter the number of profile to copy: " num_ans
				if [[ -f "${data_dir}/profiles/${calias}\$${profs[$num_ans]}" ]]; then
					cp_prof=$num_ans
					break
				else
					echo "Please enter a valid profile"
				fi
			done
			while true; do
				read -p "Enter the name for the new profile: " name_ans
				prof_name="$(str_to_file_name $name_ans)"
				if [[ -f "${data_dir}/profiles/${calias}\$${prof_name}" ]]; then
					echo "Profile name already taken."
				else
					prof=${#profs[@]}
					cp "${data_dir}/profiles/${calias}\$${profs[$cp_prof]}" "${data_dir}/profiles/${calias}\$${prof_name}"
					profs=(${profs[@]} ${prof_name})
					break
				fi
			done;;
		* )
			if [[ -f "${data_dir}/profiles/${calias}\$${profs[$prof_ans]}" ]]; then
				prof=$prof_ans
				break
			else
				echo "Please enter a valid profile number, 'n' for new, or 'c' for copy."
			fi
	esac
done
# Prompt to edit profile if not default profile
if [[ "x${profs[$prof]}" != "xdefault" ]]; then
	while true; do
		read -p "Edit profile? [Y/N]: " edit_yn
		case $edit_yn in
			[Yy] )
				while true; do
					read -p "Open keycodes file in separate window? [Y/N]: " code_yn
					case $code_yn in
						[Yy] )
							# Open keycode list file in selected graphical editor and detach process
							$GRAPHICAL_EDITOR /usr/share/evdev-keycode-remapper/keycodes &
							disown
							break;;
						[Nn] ) break;;
						* ) echo "Please answer yes or no"
					esac
				done
				# Open profile file in selected cli editor
				$EDITOR "${data_dir}/profiles/${calias}\$${profs[$prof]}"
				break;;
			[Nn] ) echo "Skipping editing."; break;;
			* ) echo "Please answer yes or no"
		esac
	done
else
	echo "Profile is device default, no editing"
fi
# Prompt to apply profile
while true; do
	read -p "Apply profile to device? [Y/N]: " apply_yn
	case $apply_yn in
		[Yy] )
			APPLY=$(which apply_script_evdev-keycode-remapper)
			# Check that apply-profile script exists
			if [[ -z "$APPLY" ]]; then
				echo "ERROR: Apply-profile script not found. If you wish to manually apply this profile, run the following commands as root:"
				echo "->  'echo -e \"evdev:${alias}*\n\$(cat \"${data_dir}/profiles/${calias}\$${profs[$prof]}\")\" > \"/etc/udev/hwdb.d/${calias}-keys.hwdb\" '"
				echo "->  'systemd-hwdb update'"
				echo "->  'udevadm trigger --verbose --sysname-match=\"event${evnum}\"'"
			else
				pkexec "$APPLY" "$alias" "$calias" "${data_dir}/profiles/${calias}\$${profs[$prof]}" "$evnum"
			fi
			break;;
		[Nn] ) break;;
		* ) echo "Please answer yes or no"
	esac
done
echo "Done"
