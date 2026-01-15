TARGET := iphone:clang:latest:16.4:14.0
export ARCHS = arm64


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = airborne

airborne_FRAMEWORKS = Foundation UIKit
airborne_FILES = Tweak.xm
airborne_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
