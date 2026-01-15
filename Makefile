TARGET := iphone:clang:latest:7.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = airborne

airborne_FRAMEWORKS = Foundation UIKit
airborne_FILES = Tweak.xm
airborne_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
