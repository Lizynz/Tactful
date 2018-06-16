export ARCHS = armv7 armv7s arm64
DEBUG = 0
export TARGET = iphone:clang:9.3

PACKAGE_VERSION = 1.3-1

export SYSROOT = $(THEOS)/sdks/iPhoneOS9.3.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tactful
Tactful_FILES = Tweak.xm
Tactful_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Cydia SpringBoard"
