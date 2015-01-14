export ARCHS = armv7 arm64
export TARGET = iphone:clang:7.0

include theos/makefiles/common.mk

TWEAK_NAME = UnlockEvents
UnlockEvents_FILES = Event.xm
UnlockEvents_FRAMEWORKS = UIKit
UnlockEvents_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard backboardd"
