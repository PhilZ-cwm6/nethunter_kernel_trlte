#!/bin/bash

RDIR=$(pwd)
export ARCH=arm
export SUBARCH=arm
export TOOLCHAIN=$HOME/build/toolchain/gcc-linaro-4.9-2016.02-x86_64_arm-linux-gnueabihf
export CROSS_COMPILE=$TOOLCHAIN/bin/arm-linux-gnueabihf-

DEVICE="tblte"
CARRIERS="att can chnopen dcm eur kdi ktt ldu lgt skt spr tmo usc vzw"

abort() {
	echo "Error: $*"
	exit 1
}

cd "$RDIR"
rm -rf build/

for carrier in $CARRIERS; do
	mkdir build
	make O=build apq8084_sec_defconfig VARIANT_DEFCONFIG="apq8084_sec_${DEVICE}_${carrier}_defconfig" SELINUX_DEFCONFIG=selinux_defconfig TIMA_DEFCONFIG=tima_norkp_defconfig || abort "failed to make $carrier"
	sort < build/.config | uniq > "arch/arm/configs/variant_${DEVICE}_${carrier}_"
	rm -rf build/
done

cd arch/arm/configs

for carrier in $CARRIERS; do
	COMMCMD="cat variant_${DEVICE}_${carrier}_"
	for carrier2 in $CARRIERS; do
		[ "$carrier" = "$carrier2" ] && continue
		COMMCMD="$COMMCMD | comm -12 - variant_${DEVICE}_${carrier2}_"
	done
	eval "$COMMCMD" > common_${DEVICE}
done

for carrier in $CARRIERS; do
	comm -23 "variant_${DEVICE}_${carrier}_" "common_${DEVICE}" | grep '=' > "variant_${DEVICE}_${carrier}"
	rm "variant_${DEVICE}_${carrier}_"
done

