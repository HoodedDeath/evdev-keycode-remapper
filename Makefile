.DEFAULT = install

PREFIX ?= /

.PHONY: install
install:
	mkdir -p $(PREFIX)/usr/share/evdev-keycode-remapper
	install -D -m0644 src/keycodes $(PREFIX)/usr/share/evdev-keycode-remapper/keycodes
	install -D -m0755 src/evdev-keycode-remapper.sh $(PREFIX)/usr/bin/evdev-keycode-remapper
	install -D -m0755 src/apply_script_evdev-keycode-remapper.sh $(PREFIX)/usr/bin/apply_script_evdev-keycode-remapper

.PHONY: uninstall
uninstall:
	rm src/keycodes $(PREFIX)/usr/share/evdev-keycode-remapper/keycodes
	rm src/evdev-keycode-remapper.sh $(PREFIX)/usr/bin/evdev-keycode-remapper
	rm src/apply_script_evdev-keycode-remapper.sh $(PREFIX)/usr/bin/apply_script_evdev-keycode-remapper
