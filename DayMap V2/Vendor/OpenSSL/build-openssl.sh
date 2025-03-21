#!/bin/bash
 
# This script builds the iOS and Mac openSSL libraries
# Download openssl http://www.openssl.org/source/ and place the tarball next to this script
 
# Credits:
# https://github.com/st3fan/ios-openssl
# https://github.com/x2on/OpenSSL-for-iPhone/blob/master/build-libssl.sh
 
 
set -e
 
usage ()
{
	echo "usage: $0 [minimum iOS SDK version (default 8.3)]"
	exit 127
}
 
if [ $1 -e "-h" ]; then
	usage
fi
 
if [ -z $1 ]; then
	SDK_VERSION="8.3"
else
	SDK_VERSION=$1
fi
 
OPENSSL_VERSION="openssl-1.0.2a"
DEVELOPER=`xcode-select -print-path`
 
buildMac()
{
	ARCH=$1
 
	echo "Building ${OPENSSL_VERSION} for ${ARCH}"
 
	TARGET="darwin-i386-cc"
 
	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi
 
	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"
	./Configure ${TARGET} --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	make >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	make install >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null
}
 
buildIOS()
{
	ARCH=$1
 
	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
   
	echo "Building ${OPENSSL_VERSION} for ${PLATFORM} ${SDK_VERSION} ${ARCH}"
 
	if [[ "${ARCH}" == "x86_64" ]]; then
		./Configure darwin64-x86_64-cc --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	else
		./Configure iphoneos-cross --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	fi
	# add -isysroot to CC=
	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"
 
	make >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make install >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	popd > /dev/null
}
 
echo "***"
echo "*** ${OPENSSL_VERSION} ***"
echo "***"
echo
echo "Cleaning up"
rm -rf include/openssl/* lib/*
 
mkdir -p lib
mkdir -p include/openssl/
 
rm -rf "/tmp/${OPENSSL_VERSION}-*"
rm -rf "/tmp/${OPENSSL_VERSION}-*.log"
 
rm -rf "${OPENSSL_VERSION}"
 
if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo "Downloading ${OPENSSL_VERSION}.tar.gz"
	curl -O http://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
	echo "Using ${OPENSSL_VERSION}.tar.gz"
fi
 
echo "Unpacking openssl"
tar xfz "${OPENSSL_VERSION}.tar.gz"
 
buildMac "i386"
buildMac "x86_64"
 
echo "Copying headers"
cp /tmp/${OPENSSL_VERSION}-i386/include/openssl/* include/openssl/
 
echo "Building Mac libraries"
lipo \
	"/tmp/${OPENSSL_VERSION}-i386/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libcrypto.a" \
	-create -output lib/libcrypto_Mac.a
 
lipo \
	"/tmp/${OPENSSL_VERSION}-i386/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libssl.a" \
	-create -output lib/libssl_Mac.a
 
buildIOS "armv7"
buildIOS "armv7s"
# commented out if condition - we're always adding 64-bit now - kevin 20150423
# if [[ $SDK_VERSION == "8.0" ]]; then
buildIOS "arm64"
buildIOS "x86_64"
# fi
buildIOS "i386"
 
echo "Building iOS libraries"
lipo \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-i386/lib/libcrypto.a" \
	-create -output lib/libcrypto_iOS.a
 
lipo \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-i386/lib/libssl.a" \
	-create -output lib/libssl_iOS.a
 
# commented out if - we're always adding 64-bit now - kevin 20150423
# if [[ $SDK_VERSION == "8.0" ]]; then
echo "Adding 64-bit libraries"
lipo \
	"lib/libcrypto_iOS.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-x86_64/lib/libcrypto.a" \
	-create -output lib/libcrypto_iOS.a

lipo \
	"lib/libssl_iOS.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-x86_64/lib/libssl.a" \
	-create -output lib/libssl_iOS.a

# fi
 
echo "Cleaning up"
rm -rf /tmp/${OPENSSL_VERSION}-*
rm -rf ${OPENSSL_VERSION}
 
echo "Done"