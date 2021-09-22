#THEOS_DEVICE_IP = 192.168.0.58 # bad, add to .bashrc or whatever like this export THEOS_DEVICE_IP=...
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:latest
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = AlwaysOnMusic

AlwaysOnMusic_FILES = Tweak.xm
AlwaysOnMusic_CFLAGS = -fobjc-arc
AlwaysOnMusic_PRIVATE_FRAMEWORKS = MediaRemote BackBoardServices GraphicsServices

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
