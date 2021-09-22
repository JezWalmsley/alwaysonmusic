ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:latest
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = AlwaysOnMusic

AlwaysOnMusic_FILES = Tweak.xm MarqueeLabel.m
AlwaysOnMusic_CFLAGS = -fobjc-arc
AlwaysOnMusic_PRIVATE_FRAMEWORKS = MediaRemote BackBoardServices GraphicsServices

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
