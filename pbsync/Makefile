export THEOS_DEVICE_IP = 192.168.31.227
export THEOS_DEVICE_PORT = 22 

TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = pbsync

pbsync_FILES = main.m
pbsync_FILES += $(wildcard ./src/*.m)
pbsync_FILES += $(wildcard ./GCDAsyncSocket/*.m)

pbsync_CFLAGS = -fobjc-arc
pbsync_CODESIGN_FLAGS = -Sentitlements.plist
pbsync_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

# before-package::
# 	cp postinst $(THEOS_STAGING_DIR)/DEBIAN/
# 	cp postrm $(THEOS_STAGING_DIR)/DEBIAN/

