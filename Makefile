export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

INSTALL_TARGET_PROCESSES = MobileSafari

TARGET = iphone:clang:13.0:13.0
ARCHS= arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariBlocker
SafariBlocker_FILES = Tweak.xm $(wildcard Bagel/*.m)
SafariBlocker_LIBRARIES = undirect
SafariBlocker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 MobileSafari"
SUBPROJECTS += SafariBlocker
include $(THEOS_MAKE_PATH)/aggregate.mk
