COMPONENT_DEPENDS := mbedtls openssl
#COMPONENT_ADD_INCLUDEDIRS := ../../../../../../../../../../../../../../../../../../../../$(COMPONENT_BUILD_DIR)/include

COMPONENT_OWNBUILDTARGET := 1

CROSS_PATH1 := $(shell which xtensa-esp32-elf-gcc )
CROSS_PATH := $(shell dirname $(CROSS_PATH1) )/..

# detect MSYS2 environment and set generator flag if found
# also set executable extension to .exe so that tools can be properly found
# and disable bundled zlib
MSYS_VERSION = $(if $(findstring Msys, $(shell uname -o)),$(word 1, $(subst ., ,$(shell uname -r))),0)
ifneq ($(MSYS_VERSION),0)
	MSYS_FLAGS = -DLWS_WITH_BUNDLED_ZLIB=0 -DEXECUTABLE_EXT=.exe -G'MSYS Makefiles'
endif

# -DNDEBUG=1 after cflags stops debug etc being built
.PHONY: build
build: $(COMPONENT_BUILD_DIR)/liblibwebsockets.a 

${COMPONENT_BUILD_DIR}/liblibwebsockets.a : $(COMPONENT_BUILD_DIR)/lib/libwebsockets.a
	cp $< $@

${COMPONENT_BUILD_DIR}/lib/libwebsockets.a : $(COMPONENT_BUILD_DIR)/Makefile
	$(MAKE) -C $(COMPONENT_BUILD_DIR)

$(COMPONENT_BUILD_DIR)/Makefile : 
	echo "doing lws cmake"
	cd $(COMPONENT_BUILD_DIR) && \
	cmake $(COMPONENT_PATH)  -DLWS_C_FLAGS="$(CFLAGS) -DNDEBUG=1" \
		-DIDF_PATH=$(IDF_PATH) \
		-DCROSS_PATH=$(CROSS_PATH) \
		-DBUILD_DIR_BASE=$(BUILD_DIR_BASE) \
		-DCMAKE_TOOLCHAIN_FILE=$(COMPONENT_PATH)/contrib/cross-esp32.cmake \
		-DCMAKE_BUILD_TYPE=RELEASE \
		-DLWS_MBEDTLS_INCLUDE_DIRS="${IDF_PATH}/components/openssl/include;${IDF_PATH}/components/mbedtls/mbedtls/include;${IDF_PATH}/components/mbedtls/port/include" \
		-DLWS_WITH_STATS=0 \
		-DLWS_WITH_HTTP2=1 \
		-DLWS_WITH_RANGES=1 \
		-DLWS_WITH_ACME=1 \
		-DLWS_WITH_ZLIB=1 \
		-DLWS_WITH_ZIP_FOPS=1 \
		-DZLIB_LIBRARY=$(BUILD_DIR_BASE)/zlib/libzlib.a \
		-DZLIB_INCLUDE_DIR=$(COMPONENT_PATH)/../zlib \
		-DLWS_WITH_ESP32=1 -DLWS_WITH_ESP32_HELPER=1 \
		-DCMAKE_BUILD_TYPE=DEBUG \
		$(MSYS_FLAGS)
# HACK ALERT! -- fixes up a bogative semicolon, no time to determine root cause
	sed -i 's/\-O2\;\-O2/\-O2/' $(COMPONENT_BUILD_DIR)/CMakeFiles/websockets.dir/flags.make
# HACK ALERT! -- fixes up a bogative use of unsupported compiler option
	sed -i 's/\-Wno\-frame\-address//' $(COMPONENT_BUILD_DIR)/CMakeFiles/websockets.dir/flags.make

clean: myclean

myclean:
	rm -rf ./build
