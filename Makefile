include theos/makefiles/common.mk

TWEAK_NAME = UnlockEvents
UnlockEvents_FILES = Tweak.xm
UnlockEvents_FRAMEWORKS = UIKit
UnlockEvents_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard backboardd"