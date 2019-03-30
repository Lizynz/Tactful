export ARCHS = arm64 arm64e
DEBUG = 0
export TARGET = iphone:clang:12.1

PACKAGE_VERSION = 1.3-3

export SYSROOT = $(THEOS)/sdks/iPhoneOS12.1.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tactful
Tactful_FILES = Tweak.xm
Tactful_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Cydia SpringBoard"
