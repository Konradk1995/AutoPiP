APP_NAME    := AutoPiP
BUNDLE_ID   := com.konrad.AutoPiP
BUILD_DIR   := /tmp/$(APP_NAME)-build
APP_PATH    := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app
INSTALL_DIR := $(HOME)/Applications
DIST_DIR    := dist

VERSION     := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" AutoPiP/AutoPiP/Info.plist 2>/dev/null || echo "1.0")

.PHONY: build install clean release zip uninstall

build:
	@echo "Building $(APP_NAME) v$(VERSION)..."
	@xattr -cr AutoPiP/ extension-src/ 2>/dev/null || true
	@xcodebuild -project AutoPiP/$(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build 2>&1 | tail -3
	@echo "Built: $(APP_PATH)"

install: build
	@echo "Installing..."
	@osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null || true
	@sleep 1
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@cp -R $(APP_PATH) $(INSTALL_DIR)/$(APP_NAME).app
	@rm -rf $(BUILD_DIR)
	@/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister \
		-f -R -trusted $(INSTALL_DIR)/$(APP_NAME).app 2>/dev/null
	@open $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed $(APP_NAME) v$(VERSION)"

zip: build
	@mkdir -p $(DIST_DIR)
	@cd $(BUILD_DIR)/Build/Products/Release && zip -r -q \
		$(CURDIR)/$(DIST_DIR)/$(APP_NAME)-$(VERSION).zip $(APP_NAME).app
	@rm -rf $(BUILD_DIR)
	@echo "$(DIST_DIR)/$(APP_NAME)-$(VERSION).zip"

release: zip
	@shasum -a 256 $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip
	@echo ""
	@echo "Release v$(VERSION) ready. Next:"
	@echo "  git tag v$(VERSION)"
	@echo "  git push origin main --tags"
	@echo "  gh release create v$(VERSION) $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip --title 'v$(VERSION)'"

clean:
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "Clean."

uninstall:
	@osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null || true
	@sleep 1
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled."
