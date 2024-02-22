export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

THEOS_DEVICE_IP = 192.168.86.37

INSTALL_TARGET_PROCESSES = MobileSafari

ARCHS= arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariBlocker
SafariBlocker_FILES = Tweak.xm $(wildcard Bagel/*.m)
SafariBlocker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 MobileSafari"
SUBPROJECTS += SafariBlocker
include $(THEOS_MAKE_PATH)/aggregate.mk
