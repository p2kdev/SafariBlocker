include $(THEOS)/makefiles/common.mk
ARCHS= arm64 arm64e
TARGET = iphone:clang:13.0:13.0
BUNDLE_NAME = SafariBlocker
SafariBlocker_FILES = SBRootListController.m
SafariBlocker_INSTALL_PATH = /Library/PreferenceBundles
SafariBlocker_FRAMEWORKS = UIKit
SafariBlocker_PRIVATE_FRAMEWORKS = Preferences
SafariBlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SafariBlocker.plist$(ECHO_END)
