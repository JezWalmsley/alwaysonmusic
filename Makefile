THEOS_DEVICE_IP = 192.168.0.58
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AlwaysOnMusic

AlwaysOnMusic_FILES = Tweak.xm
AlwaysOnMusic_CFLAGS = -fobjc-arc
AlwaysOnMusic_PRIVATE_FRAMEWORKS = MediaRemote BackBoardServices GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk
