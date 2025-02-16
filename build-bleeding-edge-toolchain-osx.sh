#!/bin/sh

# file: build-bleeding-edge-toolchain-osx.sh
#
# Original author: Copyright (C) 2016-2019 Freddie Chopin http://www.freddiechopin.info http://www.distortec.com
# Modified for OS X support by Phillip Johnston
#
# For notes on OS X compilation of GCC: https://solarianprogrammer.com/2017/05/21/compiling-gcc-macos/
#
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
# distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -e
set -u

# TODO:
# - Check for homebrew?
# - Install homebrew?
# - Why the hell is my terminal trying to print when I'm compiling?

binutilsVersion="2.32"
expatVersion="2.2.6"
gccVersion="9.1.0"
#gccVersionSuffix="-9.1"
gdbVersion="8.2.1"
gmpVersion="6.1.2"
islVersion="0.21"
mpcVersion="1.1.0"
mpfrVersion="4.0.2"
newlibVersion="3.1.0"
pythonVersion="2.7.16"
zlibVersion="1.2.11"

top="$(pwd)"
buildNative="buildNative"
installNative="installNative"
nanoLibraries="nanoLibraries"
prerequisites="prerequisites"
sources="sources"

binutils="binutils-${binutilsVersion}"
binutilsArchive="${binutils}.tar.xz"
expat="expat-${expatVersion}"
expatArchive="${expat}.tar.bz2"
gcc="gcc-${gccVersion}"
gccArchive="${gcc}.tar.xz"
gdb="gdb-${gdbVersion}"
gdbArchive="${gdb}.tar.xz"
gmp="gmp-${gmpVersion}"
gmpArchive="${gmp}.tar.xz"
isl="isl-${islVersion}"
islArchive="${isl}.tar.xz"
mpc="mpc-${mpcVersion}"
mpcArchive="${mpc}.tar.gz"
mpfr="mpfr-${mpfrVersion}"
mpfrArchive="${mpfr}.tar.xz"
newlib="newlib-${newlibVersion}"
newlibArchive="${newlib}.tar.gz"
zlib="zlib-${zlibVersion}"
zlibArchive="${zlib}.tar.gz"

pkgversion="bleeding-edge-toolchain"
target="arm-none-eabi"
package="${target}-${gcc}-$(date +'%y%m%d')"
packageArchiveNative="${package}.tar.xz"

bold="$(tput bold)"
normal="$(tput sgr0)"

keepBuildFolders="n"
skipNanoLibraries="n"
buildDocumentation="n"
while [ ${#} -gt 0 ]; do
	case ${1} in
		--keep-build-folders)
			keepBuildFolders="y"
			;;
		--with-documentation)
			buildDocumentation="y"
			;;
		--skip-nano-libraries)
			skipNanoLibraries="y"
			;;

		*)
			echo "Usage: $0 [--keep-build-folders] [--with-documentation] [--skip-nano-libraries]" >&2
			exit 1
	esac
	shift
done

documentationTypes=""
if [ ${buildDocumentation} = "y" ]; then
	documentationTypes="html pdf"
fi

BASE_CPPFLAGS="-pipe"
BASE_LDFLAGS=
BASE_CFLAGS_FOR_TARGET="-pipe -ffunction-sections -fdata-sections"
BASE_CXXFLAGS_FOR_TARGET="-pipe -ffunction-sections -fdata-sections -fno-exceptions"

buildZlib() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local makeOptions="${3}"
	local makeInstallOptions="${4}"
	echo "${bold}********** ${bannerPrefix}${zlib}${normal}"
	cp -R ${sources}/${zlib} ${buildFolder}
	cd ${buildFolder}/${zlib}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${zlib} configure${normal}"
	./configure --static --prefix=${top}/${buildFolder}/${prerequisites}/${zlib}
	echo "${bold}---------- ${bannerPrefix}${zlib} make${normal}"
	eval "make ${makeOptions} -j$(nproc)"
	echo "${bold}---------- ${bannerPrefix}${zlib} make install${normal}"
	eval "make ${makeInstallOptions} install"
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${zlib} remove build folder${normal}"
		rm -rf ${buildFolder}/${zlib}
	fi
	)
}


buildGmp() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${gmp}${normal}"
	mkdir -p ${buildFolder}/${gmp}
	cd ${buildFolder}/${gmp}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${gmp} configure${normal}"
	eval "${top}/${sources}/${gmp}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--enable-cxx \
		--disable-shared \
		--disable-nls"
	echo "${bold}---------- ${bannerPrefix}${gmp} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${gmp} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gmp} remove build folder${normal}"
		rm -rf ${buildFolder}/${gmp}
	fi
	)
}

buildMpfr() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${mpfr}${normal}"
	mkdir -p ${buildFolder}/${mpfr}
	cd ${buildFolder}/${mpfr}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${mpfr} configure${normal}"
	eval "${top}/${sources}/${mpfr}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${mpfr} \
		--disable-shared \
		--disable-nls \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp}"
	echo "${bold}---------- ${bannerPrefix}${mpfr} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${mpfr} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${mpfr} remove build folder${normal}"
		rm -rf ${buildFolder}/${mpfr}
	fi
	)
}

buildMpc() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${mpc}${normal}"
	mkdir -p ${buildFolder}/${mpc}
	cd ${buildFolder}/${mpc}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${mpc} configure${normal}"
	eval "${top}/${sources}/${mpc}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${mpc} \
		--disable-shared \
		--disable-nls \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildFolder}/${prerequisites}/${mpfr}"
	echo "${bold}---------- ${bannerPrefix}${mpc} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${mpc} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${mpc} remove build folder${normal}"
		rm -rf ${buildFolder}/${mpc}
	fi
	)
}

buildIsl() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${isl}${normal}"
	mkdir -p ${buildFolder}/${isl}
	cd ${buildFolder}/${isl}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${isl} configure${normal}"
	eval "${top}/${sources}/${isl}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${isl} \
		--disable-shared \
		--disable-nls \
		--with-gmp-prefix=${top}/${buildFolder}/${prerequisites}/${gmp}"
	echo "${bold}---------- ${bannerPrefix}${isl} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${isl} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${isl} remove build folder${normal}"
		rm -rf ${buildFolder}/${isl}
	fi
	)
}

buildExpat() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${expat}${normal}"
	mkdir -p ${buildFolder}/${expat}
	cd ${buildFolder}/${expat}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${expat} configure${normal}"
	eval "${top}/${sources}/${expat}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${expat} \
		--disable-shared \
		--disable-nls"
	echo "${bold}---------- ${bannerPrefix}${expat} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${expat} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${expat} remove build folder${normal}"
		rm -rf ${buildFolder}/${expat}
	fi
	)
}

buildBinutils() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	local documentations="${5}"
	echo "${bold}********** ${bannerPrefix}${binutils}${normal}"
	mkdir -p ${buildFolder}/${binutils}
	cd ${buildFolder}/${binutils}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${binutils} configure${normal}"
	eval "${top}/${sources}/${binutils}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--disable-nls \
		--enable-interwork \
		--enable-multilib \
		--enable-plugins \
		--with-system-zlib \
		\"--with-pkgversion=${pkgversion}\""
	echo "${bold}---------- ${bannerPrefix}${binutils} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${binutils} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${bannerPrefix}${binutils} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${binutils} remove build folder${normal}"
		rm -rf ${buildFolder}/${binutils}
	fi
	)
}


# TODO: add suffix to configure command?
# --program-suffix=${gccVersionSuffix} \
buildGcc() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	echo "${bold}********** ${bannerPrefix}${gcc}${normal}"
	mkdir -p ${buildFolder}/${gcc}
	cd ${buildFolder}/${gcc}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${gcc} configure${normal}"
	eval "${top}/${sources}/${gcc}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--libexecdir=${top}/${installFolder}/lib \
		--disable-decimal-float \
		--disable-libffi \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--disable-tls \
		--with-newlib \
		--with-gnu-as \
		--with-gnu-ld \
		--with-sysroot=${top}/${installFolder}/${target} \
		--with-system-zlib \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildFolder}/${prerequisites}/${mpfr} \
		--with-mpc=${top}/${buildFolder}/${prerequisites}/${mpc} \
		--with-isl=${top}/${buildFolder}/${prerequisites}/${isl} \
		\"--with-pkgversion=${pkgversion}\" \
		--with-multilib-list=rmprofile"
	echo "${bold}---------- ${bannerPrefix}${gcc} make all-gcc${normal}"
	make -j$(nproc) all-gcc
	echo "${bold}---------- ${bannerPrefix}${gcc} make install-gcc${normal}"
	make install-gcc
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gcc} remove build folder${normal}"
		rm -rf ${buildFolder}/${gcc}
	fi
	)
}

buildNewlib() {
	(
	local suffix="${1}"
	local optimization="${2}"
	local configureOptions="${3}"
	local documentations="${4}"
	echo "${bold}********** ${newlib}${suffix}${normal}"
	mkdir -p ${buildNative}/${newlib}${suffix}
	cd ${buildNative}/${newlib}${suffix}
	export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
	export PATH="${top}/${installNative}/bin:${PATH-}"
	export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
	echo "${bold}---------- ${newlib}${suffix} configure${normal}"
	eval "${top}/${sources}/${newlib}/configure \
		${configureOptions} \
		--target=${target} \
		--disable-newlib-supplied-syscalls \
		--enable-newlib-reent-small \
		--disable-newlib-fvwrite-in-streamio \
		--disable-newlib-fseek-optimization \
		--disable-newlib-wide-orient \
		--disable-newlib-unbuf-stream-opt \
		--enable-newlib-global-atexit \
		--enable-newlib-retargetable-locking \
		--enable-newlib-global-stdio-streams \
		--disable-nls"
	echo "${bold}---------- ${newlib}${suffix} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${newlib}${suffix} make install${normal}"
	make install
	for documentation in ${documentations}; do
		cd ${target}/newlib/libc
		echo "${bold}---------- ${newlib}${suffix} libc make install-${documentation}${normal}"
		make install-${documentation}
		cd ../../..
		cd ${target}/newlib/libm
		echo "${bold}---------- ${newlib}${suffix} libm make install-${documentation}${normal}"
		make install-${documentation}
		cd ../../..
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${newlib}${suffix} remove build folder${normal}"
		rm -rf ${buildNative}/${newlib}${suffix}
	fi
	)
}

buildGccFinal() {
	(
	local suffix="${1}"
	local optimization="${2}"
	local installFolder="${3}"
	local documentations="${4}"
	echo "${bold}********** ${gcc}${suffix}${normal}"
	mkdir -p ${buildNative}/${gcc}${suffix}
	cd ${buildNative}/${gcc}${suffix}
	export CPPFLAGS="-I${top}/${buildNative}/${prerequisites}/${zlib}/include ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildNative}/${prerequisites}/${zlib}/lib ${BASE_LDFLAGS-} ${LDFLAGS-}"
	export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
	export CXXFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CXXFLAGS_FOR_TARGET-} ${CXXFLAGS_FOR_TARGET-}"
	echo "${bold}---------- ${gcc}${suffix} configure${normal}"
	${top}/${sources}/${gcc}/configure \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--libexecdir=${top}/${installFolder}/lib \
		--enable-languages=c,c++ \
		--disable-libstdcxx-verbose \
		--enable-plugins \
		--disable-decimal-float \
		--disable-libffi \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--disable-tls \
		--with-gnu-as \
		--with-gnu-ld \
		--with-newlib \
		--with-headers=yes \
		--with-sysroot=${top}/${installFolder}/${target} \
		--with-system-zlib \
		--with-gmp=${top}/${buildNative}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildNative}/${prerequisites}/${mpfr} \
		--with-mpc=${top}/${buildNative}/${prerequisites}/${mpc} \
		--with-isl=${top}/${buildNative}/${prerequisites}/${isl} \
		"--with-pkgversion=${pkgversion}" \
		--with-multilib-list=rmprofile
	echo "${bold}---------- ${gcc}${suffix} make${normal}"
	make -j$(nproc) INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
	echo "${bold}---------- ${gcc}${suffix} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${gcc}${suffix} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${gcc}${suffix} remove build folder${normal}"
		rm -rf ${buildNative}/${gcc}${suffix}
	fi
	)
}

copyNanoLibraries() {
	local source="${1}"
	local destination="${2}"
	echo "${bold}********** \"nano\" libraries copy${normal}"
	local multilibs="$(${destination}/bin/${target}-gcc -print-multi-lib)"
	local sourcePrefix="${source}/${target}/lib"
	local destinationPrefix="${destination}/${target}/lib"
	local sourceDirectory
	local destinationDirectory
	for multilib in ${multilibs}; do
		multilib="${multilib%%;*}"
		sourceDirectory="${sourcePrefix}/${multilib}"
		destinationDirectory="${destinationPrefix}/${multilib}"
		mkdir -p "${destinationDirectory}"
		cp "${sourceDirectory}/libc.a" "${destinationDirectory}/libc_nano.a"
		cp "${sourceDirectory}/libg.a" "${destinationDirectory}/libg_nano.a"
		cp "${sourceDirectory}/librdimon.a" "${destinationDirectory}/librdimon_nano.a"
		cp "${sourceDirectory}/libstdc++.a" "${destinationDirectory}/libstdc++_nano.a"
		cp "${sourceDirectory}/libsupc++.a" "${destinationDirectory}/libsupc++_nano.a"
	done

	mkdir -p "${destination}/arm-none-eabi/include/newlib-nano"
	cp "${source}/arm-none-eabi/include/newlib.h" "${destination}/arm-none-eabi/include/newlib-nano"

	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- \"nano\" libraries remove install folder${normal}"
		rm -rf ${top}/${buildNative}/${nanoLibraries}
	fi
}

buildGdb() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	local documentations="${5}"
	echo "${bold}********** ${bannerPrefix}${gdb}${normal}"
	mkdir -p ${buildFolder}/${gdb}
	cd ${buildFolder}/${gdb}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${BASE_LDFLAGS-} ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${gdb} configure${normal}"
	eval "${top}/${sources}/${gdb}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--disable-nls \
		--disable-sim \
		--with-lzma=no \
		--with-guile=no \
		--with-system-gdbinit=${top}/${installFolder}/${target}/lib/gdbinit \
		--with-system-zlib \
		--with-expat=yes \
		--with-libexpat-prefix=${top}/${buildFolder}/${prerequisites}/${expat} \
		--with-mpfr=yes \
		--with-libmpfr-prefix=${top}/${buildFolder}/${prerequisites}/${mpfr} \
		\"--with-gdb-datadir='\\\${prefix}'/${target}/share/gdb\" \
		\"--with-pkgversion=${pkgversion}\""
	echo "${bold}---------- ${bannerPrefix}${gdb} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${gdb} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${bannerPrefix}${gdb} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gdb} remove build folder${normal}"
		rm -rf ${buildFolder}/${gdb}
	fi
	)
}

postCleanup() {
	local installFolder="${1}"
	local bannerPrefix="${2}"
	local hostSystem="${3}"
	local extraComponents="${4}"
	echo "${bold}********** ${bannerPrefix}Post-cleanup${normal}"
	rm -rf ${installFolder}/include
	find ${installFolder} -name '*.la' -exec rm -rf {} +
	cat > ${installFolder}/info.txt <<- EOF
	${pkgversion}
	build date: $(date +'%Y-%m-%d')
	build system: $(uname -srvm)
	host system: ${hostSystem}
	target system: ${target}
	compiler: ${CC-gcc} $(${CC-gcc} --version | grep -o '[0-9]\.[0-9]\.[0-9]')

	Toolchain components:
	- ${gcc}
	- ${newlib}
	- ${binutils}
	- ${gdb}
	$(echo -en "- ${expat}\n- ${gmp}\n- ${isl}\n- ${mpc}\n- ${mpfr}\n- ${zlib}\n${extraComponents}" | sort)

	This package and info about it can be found on Freddie Chopin's website:
	http://www.freddiechopin.info/
	EOF
	cp ${0} ${installFolder}
}

echo "${bold}********** Cleanup${normal}"
rm -rf ${buildNative}
rm -rf ${installNative}
mkdir -p ${buildNative}
mkdir -p ${installNative}
mkdir -p ${sources}
find ${sources} -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
find ${sources} -mindepth 1 -maxdepth 1 -type f ! -name "${binutilsArchive}" \
	! -name "${expatArchive}" \
	! -name "${gccArchive}" \
	! -name "${gdbArchive}" \
	! -name "${gmpArchive}" \
	! -name "${islArchive}" \
	! -name "${mpcArchive}" \
	! -name "${mpfrArchive}" \
	! -name "${newlibArchive}" \
	! -name "${zlibArchive}" \
	-exec rm -rf {} +

echo "${bold}********** Download${normal}"
mkdir -p ${sources}
cd ${sources}
download() {
	local ret=0
	echo "${bold}---------- Downloading ${1}${normal}"
	curl -L -o ${1} -C - --connect-timeout 30 -Y 1024 -y 30 ${2} || ret=$?
	if [ $ret -eq 33 ]; then
		echo 'This happens if the file is complete, continuing...'
	elif [ $ret -ne 0 ]; then
		exit $ret
	fi
}

download ${binutilsArchive} http://ftp.gnu.org/gnu/binutils/${binutilsArchive}
download ${expatArchive} https://github.com/libexpat/libexpat/releases/download/$(echo "R_${expatVersion}" | sed 's/\./_/g')/${expatArchive}
if [ ${gccVersion#*-} = ${gccVersion} ]; then
	download ${gccArchive} http://ftp.gnu.org/gnu/gcc/${gcc}/${gccArchive}
else
	download ${gccArchive} https://gcc.gnu.org/pub/gcc/snapshots/${gccVersion}/${gccArchive}
fi
download ${gdbArchive} http://ftp.gnu.org/gnu/gdb/${gdbArchive}
download ${gmpArchive} http://ftp.gnu.org/gnu/gmp/${gmpArchive}
download ${islArchive} http://isl.gforge.inria.fr/${islArchive}
download ${mpcArchive} http://ftp.gnu.org/gnu/mpc/${mpcArchive}
download ${mpfrArchive} http://ftp.gnu.org/gnu/mpfr/${mpfrArchive}
download ${newlibArchive} http://sourceware.org/pub/newlib/${newlibArchive}
download ${zlibArchive} https://www.zlib.net/fossils/${zlibArchive}
cd ${top}

echo "${bold}********** Extract${normal}"
cd ${sources}
echo "${bold}---------- Extracting ${binutilsArchive}${normal}"
tar -xf ${binutilsArchive}
echo "${bold}---------- Extracting ${expatArchive}${normal}"
tar -xf ${expatArchive}
echo "${bold}---------- Extracting ${gccArchive}${normal}"
tar -xf ${gccArchive}
echo "${bold}---------- Extracting ${gdbArchive}${normal}"
tar -xf ${gdbArchive}
echo "${bold}---------- Extracting ${gmpArchive}${normal}"
tar -xf ${gmpArchive}
echo "${bold}---------- Extracting ${islArchive}${normal}"
tar -xf ${islArchive}
echo "${bold}---------- Extracting ${mpcArchive}${normal}"
tar -xf ${mpcArchive}
echo "${bold}---------- Extracting ${mpfrArchive}${normal}"
tar -xf ${mpfrArchive}
echo "${bold}---------- Extracting ${newlibArchive}${normal}"
tar -xf ${newlibArchive}
echo "${bold}---------- Extracting ${zlibArchive}${normal}"
tar -xf ${zlibArchive}
cd ${top}

hostTriplet=$(${sources}/${newlib}/config.guess)

buildZlib ${buildNative} "" "" ""

buildGmp ${buildNative} "" "--build=${hostTriplet} --host=${hostTriplet}"

buildMpfr ${buildNative} "" "--build=${hostTriplet} --host=${hostTriplet}"

buildMpc ${buildNative} "" "--build=${hostTriplet} --host=${hostTriplet}"

buildIsl ${buildNative} "" "--build=${hostTriplet} --host=${hostTriplet}"

buildExpat ${buildNative} "" "--build=${hostTriplet} --host=${hostTriplet}"

buildBinutils ${buildNative} ${installNative} "" "--build=${hostTriplet} --host=${hostTriplet}" "${documentationTypes}"

buildGcc ${buildNative} ${installNative} "" "--enable-languages=c,c++ --without-headers"

if [ "${skipNanoLibraries}" = "n" ]; then
	(
	export PATH="${top}/${installNative}/bin:${PATH-}"

	buildNewlib \
		"-nano" \
		"-Os" \
		"--prefix=${top}/${buildNative}/${nanoLibraries} \
			--enable-newlib-nano-malloc \
			--enable-lite-exit \
			--enable-newlib-nano-formatted-io" \
		""

	buildGccFinal "-nano" "-Os" "${buildNative}/${nanoLibraries}" ""
	)

	copyNanoLibraries "${top}/${buildNative}/${nanoLibraries}" "${top}/${installNative}"
fi

buildNewlib \
	"" \
	"-O2" \
	"--prefix=${top}/${installNative} \
		--docdir=${top}/${installNative}/share/doc \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--disable-newlib-atexit-dynamic-alloc" \
	"${documentationTypes}"

buildGccFinal "-final" "-O2" "${installNative}" "${documentationTypes}"

buildGdb \
	${buildNative} \
	${installNative} \
	"" \
	"--build=${hostTriplet} --host=${hostTriplet} --with-python=yes" \
	"${documentationTypes}"

postCleanup ${installNative} "" "$(uname -ms)" ""
find ${installNative} -type f -perm +0111 -exec strip {} \; || true
find ${installNative} -type f -exec chmod a-w {} +
if [ ${buildDocumentation} = "y" ]; then
	find ${installNative}/share/doc -mindepth 2 -name '*.pdf' -exec mv {} ${installNative}/share/doc \;
fi

echo "${bold}********** Package${normal}"
rm -rf ${package}
ln -s ${installNative} ${package}
rm -rf ${packageArchiveNative}
XZ_OPT=${XZ_OPT-"-9e -v"} tar -cJf ${packageArchiveNative} --numeric-owner $(find ${package}/ -mindepth 1 -maxdepth 1)
rm -rf ${package}

echo "${bold}********** Done${normal}"
