# evdev-keycode-remapper
 
A simple pair of scripts to remap keys of a specific keyboard, using evdev

## Install

Run `make install` as root to install

To install manually, copy `evdev-keycode-remapper.sh` and `apply_script_evdev-keycode-remapper.sh` into `/usr/bin` as `evdev-keycode-remapper` and `apply_script_evdev-keycode-remapper` respectively, then copy `keycodes` into `/usr/share/evdev-keycode-remapper/`

Note: A polkit authentication agent is required for applying profiles

### AUR Package

AUR package link to be added

## Usage

Simply run `evdev-keycode-remapper` and the script will prompt you for everything needed. Applying a profile to a device requires super user access, so polkit agent will prompt you when applying a profile

Note: For editing profiles within the command line, the script uses the following order to determine which cli editor to use:
1. The file `$HOME/.local/share/evdev-keycode-remapper/editor` containing the line `EDITOR=<COMMAND>` where `<COMMAND>` is the command to launch the desired editor, which will be followed by the path of the file to be edited when the script calls it
2. The script will check for nano installed and use that if found
3. The script will check for vim installed and use that if found
4. The script will prompt you for the command to execute. After prompting, your answer will be saved to the `editor` preference file for future use

Note: For displaying the keycodes list file, the script uses the following order to determine which gui editor to use:
1. The file located at `$HOME/.local/share/evdev-keycode-remapper/graphical_editor` containing the line `GRAPHICAL_EDITOR=<COMMAND>` where `<COMMAND>` is the command to display the keycodes file in a seperate window, which will be followed by the by the path of the file, followed by `</dev/null *>/dev/null &` in order to detach the process from the script
2. The script will check for mousepad installed and use that if found
3. The script will check for gedit installed and use that if found
4. the script will check for kate installed and use that if found
5. The script will prompt you for the command to execute. After prompting, your answer will be saved to the `graphical_editor` preference file for future use

## Changlog

- 1.0
	- Creation
