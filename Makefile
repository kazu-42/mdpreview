APP_NAME = MDPreview
BUNDLE_ID = dev.kazu42.mdpreview
BUILD_DIR = $(shell swift build -c release --show-bin-path 2>/dev/null || echo .build/release)
APP_BUNDLE = build/$(APP_NAME).app

.PHONY: all build bundle clean install cli run dev test

all: build bundle

build:
	swift build -c release

dev:
	swift build
	.build/debug/MDPreview $(FILE)

test:
	swift test

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/MDPreview $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Supporting/Info.plist $(APP_BUNDLE)/Contents/
	@# Bundle CLI tool
	cp Supporting/mdpreview $(APP_BUNDLE)/Contents/Resources/mdpreview
	chmod +x $(APP_BUNDLE)/Contents/Resources/mdpreview
	@# Copy app icon if available
	@if [ -f "Assets/AppIcon.icns" ]; then \
		cp Assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns; \
	fi
	@# Copy SPM resource bundles (name depends on target structure)
	@for bundle in $(BUILD_DIR)/*.bundle; do \
		[ -d "$$bundle" ] && cp -R "$$bundle" $(APP_BUNDLE)/Contents/Resources/; \
	done
	@# Ad-hoc sign for local use
	codesign --force --sign - $(APP_BUNDLE)
	@echo "Built: $(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf build/

install: bundle
	cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

uninstall:
	rm -rf /Applications/$(APP_NAME).app
	rm -f /usr/local/bin/mdpreview
	@echo "Uninstalled $(APP_NAME)"

cli: install
	@mkdir -p /usr/local/bin
	@ln -sf /Applications/$(APP_NAME).app/Contents/Resources/mdpreview /usr/local/bin/mdpreview
	@echo "Installed CLI: /usr/local/bin/mdpreview -> /Applications/$(APP_NAME).app/Contents/Resources/mdpreview"

run: bundle
	open $(APP_BUNDLE)

dmg: bundle
	@rm -rf dmg-staging
	@mkdir -p dmg-staging
	@cp -R $(APP_BUNDLE) dmg-staging/
	@ln -s /Applications dmg-staging/Applications
	hdiutil create -volname "MDPreview" -srcfolder dmg-staging -ov -format UDZO build/MDPreview.dmg
	@rm -rf dmg-staging
	@echo "Built: build/MDPreview.dmg"
