APP_NAME    := AutoPiP
BUNDLE_ID   := com.konrad.AutoPiP
BUILD_DIR   := /tmp/$(APP_NAME)-build
APP_PATH    := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app
INSTALL_DIR := $(HOME)/Applications
DIST_DIR    := dist

VERSION     := $(shell python3 -c "import json; print(json.load(open('extension-src/manifest.json'))['version'])" 2>/dev/null || echo "1.0")

# Pass TEAM_ID=XXXXXXXXXX to build a signed extension that survives restarts.
# Without TEAM_ID the extension is ad-hoc signed (requires "Allow Unsigned Extensions").
ifdef TEAM_ID
SIGN_ARGS := DEVELOPMENT_TEAM=$(TEAM_ID)
else
SIGN_ARGS :=
endif

.PHONY: build install clean release zip uninstall userscript

# ---------------------------------------------------------------------------
# Userscript (primary distribution — works everywhere, no Xcode needed)
# ---------------------------------------------------------------------------

userscript:
	@echo "// ==UserScript==" > autopip.user.js
	@echo "// @name         Auto PiP" >> autopip.user.js
	@echo "// @namespace    https://github.com/Konradk1995/AutoPiP" >> autopip.user.js
	@echo "// @version      $(VERSION)" >> autopip.user.js
	@echo "// @description  Automatically enters Picture-in-Picture when you switch tabs or leave the browser." >> autopip.user.js
	@echo "// @author       Konrad Klonowski" >> autopip.user.js
	@echo "// @match        *://*/*" >> autopip.user.js
	@echo "// @run-at       document-idle" >> autopip.user.js
	@echo "// @grant        none" >> autopip.user.js
	@echo "// @inject-into  page" >> autopip.user.js
	@echo "// @homepageURL  https://github.com/Konradk1995/AutoPiP" >> autopip.user.js
	@echo "// @supportURL   https://github.com/Konradk1995/AutoPiP/issues" >> autopip.user.js
	@echo "// @license      MIT" >> autopip.user.js
	@echo "// ==/UserScript==" >> autopip.user.js
	@echo "" >> autopip.user.js
	@cat extension-src/content.js >> autopip.user.js
	@echo "Generated autopip.user.js v$(VERSION)"

# ---------------------------------------------------------------------------
# Native Safari extension (requires Xcode, optionally TEAM_ID for signing)
# ---------------------------------------------------------------------------

build:
	@echo "Building $(APP_NAME) v$(VERSION)..."
ifdef TEAM_ID
	@echo "Signing with TEAM_ID=$(TEAM_ID)"
endif
	@xattr -cr AutoPiP/ extension-src/ 2>/dev/null || true
	@xcodebuild -project AutoPiP/$(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		ARCHS="arm64 x86_64" \
		ONLY_ACTIVE_ARCH=NO \
		$(SIGN_ARGS) \
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

release: userscript zip
	@shasum -a 256 $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip
	@echo ""
	@echo "Release v$(VERSION) ready. Next:"
	@echo "  git tag v$(VERSION)"
	@echo "  git push origin main --tags"
	@echo "  gh release create v$(VERSION) $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip autopip.user.js --title 'v$(VERSION)'"

clean:
	@rm -rf $(BUILD_DIR) $(DIST_DIR) autopip.user.js
	@echo "Clean."

uninstall:
	@osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null || true
	@sleep 1
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled."
