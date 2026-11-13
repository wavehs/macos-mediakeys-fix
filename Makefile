APP_NAME = MediaKeysFix
APP_BUNDLE = $(APP_NAME).app
SRC_FILES = $(wildcard src/*.swift)

.PHONY: all build app icon dmg release install uninstall status logs clean

all: app

build:
	@echo "==> Compiling $(APP_NAME)..."
	swiftc -O $(SRC_FILES) -o $(APP_NAME)

icon:
	@if [ ! -f resources/AppIcon.icns ]; then \
		echo "==> Generating AppIcon.icns..."; \
		mkdir -p resources; \
		swift scripts/generate_icon.swift; \
		mv AppIcon.icns resources/AppIcon.icns; \
	fi

app: build icon
	@echo "==> Assembling $(APP_BUNDLE)..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp src/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@codesign --force --deep --sign - $(APP_BUNDLE) >/dev/null 2>&1 || true
	@echo "==> $(APP_BUNDLE) created successfully."

dmg: app
	@./scripts/create_dmg.sh

release: dmg

install:
	@./install.sh

uninstall:
	@./uninstall.sh

status:
	@if [ -f ./$(APP_NAME) ]; then \
		./$(APP_NAME) --status; \
	elif [ -f /Applications/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) ]; then \
		/Applications/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) --status; \
	else \
		echo "MediaKeysFix binary not found. Run 'make build' or 'make install'."; \
	fi
	@echo "\n=== Running Processes ==="
	@ps aux | grep -i MediaKeysFix | grep -v grep || echo "No MediaKeysFix process running."

logs:
	@if [ -f /tmp/mediakeyd.log ]; then \
		tail -n 30 /tmp/mediakeyd.log; \
	else \
		echo "No log file found at /tmp/mediakeyd.log"; \
	fi

clean:
	@rm -rf $(APP_NAME) $(APP_BUNDLE)
	@echo "==> Cleaned build artifacts."
