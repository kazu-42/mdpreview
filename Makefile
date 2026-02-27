APP_NAME = MDPreview
BUNDLE_ID = dev.kazu42.mdpreview
BUILD_DIR = $(shell swift build -c release --show-bin-path 2>/dev/null || echo .build/release)
APP_BUNDLE = build/$(APP_NAME).app

# Version from git tag or default
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.2.1")

.PHONY: all build bundle clean install cli run dev test dmg release universal

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
	cp Supporting/mdpreview $(APP_BUNDLE)/Contents/Resources/mdpreview
	chmod +x $(APP_BUNDLE)/Contents/Resources/mdpreview
	@if [ -f "Assets/AppIcon.icns" ]; then \
		cp Assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns; \
	fi
	@for bundle in $(BUILD_DIR)/*.bundle; do \
		[ -d "$$bundle" ] && cp -R "$$bundle" $(APP_BUNDLE)/Contents/Resources/; \
	done
	@# Update version in Info.plist
	@sed -i '' "s/<string>1.0.0</<string>$(VERSION)</g" $(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' "s/<string>1.0</<string>$(VERSION)</g" $(APP_BUNDLE)/Contents/Info.plist
	@codesign --force --sign - $(APP_BUNDLE)
	@echo "Built: $(APP_BUNDLE) (v$(VERSION))"

# Universal binary (arm64 + x86_64)
universal:
	@echo "Building universal binary..."
	@rm -rf .build/arm64 .build/x86_64
	swift build -c release --arch arm64
	mv .build/apple/Products/Release .build/arm64 || mv .build/release .build/arm64-backup 2>/dev/null || true
	swift build -c release --arch x86_64 || true
	@# Create universal binary using lipo
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@if [ -f ".build/arm64/MDPreview" ] && [ -f ".build/x86_64/MDPreview" ]; then \
		lipo -create .build/arm64/MDPreview .build/x86_64/MDPreview -output $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME); \
	else \
		echo "Warning: Building single architecture"; \
		cp .build/release/MDPreview $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME); \
	fi
	cp Supporting/Info.plist $(APP_BUNDLE)/Contents/
	cp Supporting/mdpreview $(APP_BUNDLE)/Contents/Resources/mdpreview
	chmod +x $(APP_BUNDLE)/Contents/Resources/mdpreview
	@if [ -f "Assets/AppIcon.icns" ]; then \
		cp Assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns; \
	fi
	@# Copy resource bundles from arm64 build output (same resources as x86_64)
	@for bundle in .build/arm64-apple-macosx/release/*.bundle; do \
		[ -d "$$bundle" ] && cp -R "$$bundle" $(APP_BUNDLE)/Contents/Resources/; \
	done
	@sed -i '' "s/<string>1.0.0</<string>$(VERSION)</g" $(APP_BUNDLE)/Contents/Info.plist
	@codesign --force --sign - $(APP_BUNDLE)
	@echo "Built universal: $(APP_BUNDLE)"

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
	@echo "Installed CLI: /usr/local/bin/mdpreview"

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

# Full release with notarization (requires APPLE_ID, TEAM_ID, APP_PASSWORD env vars)
release: dmg
	@echo "Signing with Developer ID..."
	codesign --sign "Developer ID Application: Takami Kazuihro (6RQMKB9NL7)" \
		--deep --force --timestamp --options runtime \
		--entitlements Supporting/MDPreview.entitlements \
		$(APP_BUNDLE)
	codesign --sign "Developer ID Application: Takami Kazuihro (6RQMKB9NL7)" \
		--timestamp build/MDPreview.dmg
	@echo "Notarizing..."
	@xcrun notarytool submit build/MDPreview.dmg \
		--apple-id "$${APPLE_ID}" \
		--team-id "$${TEAM_ID}" \
		--password "$${APP_PASSWORD}" \
		--wait
	xcrun stapler staple build/MDPreview.dmg
	@echo "Release ready: build/MDPreview.dmg"
