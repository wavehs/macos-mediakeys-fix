PREFIX ?= /opt/homebrew/bin
BIN = mediakeyd
SRC = src/mediakeyd.swift
LAUNCH_DIR = $(HOME)/Library/LaunchAgents

.PHONY: all build install uninstall status logs clean

all: build

build:
	swiftc -O $(SRC) -o $(BIN)

install: build
	mkdir -p $(PREFIX)
	cp $(BIN) $(PREFIX)/$(BIN)
	chmod +x $(PREFIX)/$(BIN)
	mkdir -p $(LAUNCH_DIR)
	cp launchd/com.user.mediakeyd.plist $(LAUNCH_DIR)/
	cp launchd/com.user.hidutilKeyMapping.plist $(LAUNCH_DIR)/
	launchctl unload $(LAUNCH_DIR)/com.user.mediakeyd.plist 2>/dev/null || true
	launchctl unload $(LAUNCH_DIR)/com.user.hidutilKeyMapping.plist 2>/dev/null || true
	launchctl load $(LAUNCH_DIR)/com.user.hidutilKeyMapping.plist
	launchctl load $(LAUNCH_DIR)/com.user.mediakeyd.plist
	@echo "Installation complete. mediakeyd is active."

uninstall:
	launchctl unload $(LAUNCH_DIR)/com.user.mediakeyd.plist 2>/dev/null || true
	launchctl unload $(LAUNCH_DIR)/com.user.hidutilKeyMapping.plist 2>/dev/null || true
	rm -f $(LAUNCH_DIR)/com.user.mediakeyd.plist
	rm -f $(LAUNCH_DIR)/com.user.hidutilKeyMapping.plist
	rm -f $(PREFIX)/$(BIN)
	hidutil property --set '{"UserKeyMapping":[]}'
	@echo "Uninstallation complete. Keymappings reset to macOS defaults."

status:
	@echo "=== Process ==="
	@ps aux | grep -i mediakeyd | grep -v grep || echo "mediakeyd not running"
	@echo "=== UserKeyMapping ==="
	@hidutil property --get "UserKeyMapping" | head -n 30

logs:
	tail -n 25 /tmp/mediakeyd.log

clean:
	rm -f $(BIN)
