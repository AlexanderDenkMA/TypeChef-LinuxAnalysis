#!/bin/bash
#!/bin/bash -vxe

#java -jar sbt-launch-0.7.4.jar  compile

. linuxFileList.inc

##################################################################
# Preprocessing flags
##################################################################
# Hack to change and remove options just for the partial preprocessor.
. jcpp.conf

# Note: this clears $partialPreprocFlags
#partialPreprocFlags="-c linux-redhat.properties -I $(gcc -print-file-name=include) -x CONFIG_ -U __INTEL_COMPILER \
partialPreprocFlags="-c linux-$system.properties -x CONFIG_ \
  --include completedConf.h --include partialConf.h --openFeat openFeaturesList.txt \
  --featureModelFExpr approx.fm \
  --parse --writePI --recordTiming --parserstatistics --lexdebug"
#  --include linux_defs.h --include $srcPath/include/generated/autoconf.h

# XXX: These options workaround bugs triggered by these macros.
#partialPreprocFlags="$partialPreprocFlags -U CONFIG_PARAVIRT -U CONFIG_TRACE_BRANCH_PROFILING"
# Encode missing dependencies caught by the typechecker! :-D. CONFIG_SYMBOL_PREFIX must be undefined or defined to be a string.
#partialPreprocFlags="$partialPreprocFlags -U CONFIG_PARAVIRT_SPINLOCKS -U CONFIG_64BIT -U CONFIG_SYMBOL_PREFIX"
# CONFIG_MACH_JAZZ is impossible in our config and causes inclusion of
# <asm/jazz.h>, not avilable for X86; it is not defined by X86, so it is not in
# the feature model. Similarly for CONFIG_SGI_HAS_I8042 and CONFIG_SNI_RM.
#partialPreprocFlags="$partialPreprocFlags -U CONFIG_MACH_JAZZ -U CONFIG_SGI_HAS_I8042 -U CONFIG_SNI_RM"

# Flags which I left out from Christian configuration - they are not useful.
# partialPreprocFlags="$partialPreprocFlags -D PAGETABLE_LEVELS=4"

gccOpts="$gccOpts -m32 -nostdinc -isystem $(gcc -print-file-name=include) -include $srcPath/include/generated/autoconf.h"

flags() {
  name="$1"
  base="$(basename "$1")"
  if grep -q "arch/x86/boot" <<< "$name"; then
    extraFlag="-D_SETUP"
  elif grep -q "arch/x86/kvm" <<< "$name"; then
    extraFlag="-I $srcPath/virt/kvm -I $srcPath/arch/x86/kvm -I $srcPath"
  elif [ "$name" = "net/mac80211/driver-trace" ]; then
    extraFlag="-I $srcPath/net/mac80211"
  elif grep -q "fs/gfs2/" <<< "$name"; then
    extraFlag="-I $srcPath/fs/gfs2"
  elif grep -q "fs/ocfs2/" <<< "$name"; then
    extraFlag="-I $srcPath/fs/ocfs2 -DCATCH_BH_JBD_RACES"
  elif grep -q "fs/xfs/" <<< "$name"; then
    extraFlag="-I $srcPath/fs/xfs -I $srcPath/fs/xfs/linux-2.6"
  elif grep -q "fs/ntfs/" <<< "$name"; then
    extraFlag="-DNTFS_VERSION=\"\\\"2.1.29\"\\\" --include ntfs.h"
  elif grep -q "drivers/gpu/drm/" <<< "$name"; then
    extraFlag="-I $srcPath/include/drm"
  elif egrep -q "drivers/scsi/pcmcia/|drivers/usb/storage/" <<< "$name"; then
    extraFlag="-I $srcPath/drivers/scsi"
  elif grep -q "drivers/scsi/cxgb3i/" <<< "$name"; then
    extraFlag="-I $srcPath/drivers/net/cxgb3"
  elif grep -q "drivers/infiniband/hw/cxgb3/" <<< "$name"; then
    extraFlag="-I $srcPath/drivers/net/cxgb3"
  elif grep -q "drivers/net/skfp/" <<< "$name"; then
    extraFlag="-I $srcPath/drivers/net/skfp -DPCI -DMEM_MAPPED_IO"
  elif grep -q "drivers/staging/rt2860/" <<< "$name"; then
    extraFlag="-DLINUX -DAGGREGATION_SUPPORT -DPIGGYBACK_SUPPORT -DWMM_SUPPORT -DRTMP_MAC_PCI -DRTMP_PCI_SUPPORT -DRT2860 -DRTMP_RF_RW_SUPPORT -DRTMP_EFUSE_SUPPORT -DRT30xx -DRT3090 -DDBG"
  elif grep -q "drivers/staging/rt2870/" <<< "$name"; then
    extraFlag="-DLINUX -DAGGREGATION_SUPPORT -DPIGGYBACK_SUPPORT -DWMM_SUPPORT -DRTMP_MAC_USB -DRTMP_USB_SUPPORT -DRT2870 -DRTMP_TIMER_TASK_SUPPORT -DRTMP_RF_RW_SUPPORT -DRTMP_EFUSE_SUPPORT -DRT30xx -DRT3070 -DDBG"
  elif grep -q "drivers/staging/rtl8192e/" <<< "$name"; then
    extraFlag="-DRTL8192E -DTHOMAS_TURBO -DENABLE_DOT11D"
  elif [ "$name" = "drivers/net/wireless/iwlwifi/iwl-devtrace" ]; then
    extraFlag="-I $srcPath/drivers/net/wireless/iwlwifi/"
  elif grep -q "drivers/scsi/bfa/" <<< "$name"; then
    extraFlag=""
    for path in drivers/scsi/bfa drivers/scsi/bfa/include drivers/scsi/bfa/include/cna; do
      extraFlag="$extraFlag -I $srcPath/$path"
    done
  elif egrep -q "drivers/media/common/tuners/|drivers/staging/go7007/" <<< "$name"; then
    extraFlag=""
    for path in drivers/media/dvb/dvb-core drivers/media/dvb/frontends; do
      extraFlag="$extraFlag -I $srcPath/$path"
    done
    if grep -q "drivers/staging/go7007/" <<< "$name"; then
      extraFlag="$extraFlag -I $srcPath/drivers/media/dvb/dvb-usb"
    fi
  elif egrep -q "drivers/media/video/gspca/(gl860|m5602|stv06xx)/" <<< "$name"; then
    extraFlag="-I $srcPath/drivers/media/video/gspca"
  elif egrep -q "drivers/media/(dvb|video)/|drivers/staging/cx25821/" <<< "$name"; then
    extraFlag=""
    for path in drivers/media/dvb/dvb-core drivers/media/dvb/frontends drivers/media/common/tuners \
      drivers/ieee1394 drivers/media/video/bt8xx drivers/media/video; do
      extraFlag="$extraFlag -I $srcPath/$path"
    done
  else
    extraFlag=""
  fi
  # XXX: again, I need to specify $PWD, for the same bug as above.
  # "-I linux-2.6.33.3/include -I linux-2.6.33.3/arch/x86/include"
  echo "$extraFlag -I $srcPath/include -I $srcPath/arch/x86/include -D __KERNEL__ -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -DKBUILD_BASENAME=\"\\\"$base\\\"\" -DKBUILD_MODNAME=\"\\\"$base\\\"\""
}

export outCSV=linux.csv
## Reset output
#echo -n > "$outCSV"

#echo $partialPreprocFlags
##################################################################
# Actually invoke the preprocessor and analyze result.
##################################################################
filesToProcess|while read i; do
  extraFlags="$(flags "$i")"
#  if [ ! -f "$srcPath/$i.i" ]; then
#    echo "=="
#    echo "==Preprocess source"
#    echo "=="
#    gcc -Wp,-P -U __weak $gccOpts -E $srcPath/$i.c $extraFlags > "$srcPath/$i.i" || true
#  fi
  if [ ! -f $srcPath/$i.dbg ]; then
    touch $srcPath/$i.dbg
    . ./jcpp.sh $srcPath/$i.c $extraFlags
#    . ./postProcess.sh $srcPath/$i.c $extraFlags
  else
    echo "Skipping $srcPath/$i.c"
  fi
done

# The original invocation of the compiler:
# gcc -Wp,-MD,kernel/.fork.o.d
# -nostdinc -isystem /usr/lib/gcc/x86_64-redhat-linux/4.4.4/include
# -I/app/home/pgiarrusso/TypeChef/linux-2.6.33.3/arch/x86/include -Iinclude
# -D__KERNEL__
# -include include/generated/autoconf.h -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -D"KBUILD_STR(s)=#s" -D"KBUILD_BASENAME=KBUILD_STR(fork)" -D"KBUILD_MODNAME=KBUILD_STR(fork)"
# -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Wno-format-security -fno-delete-null-pointer-checks -O2 -m64 -mtune=generic -mno-red-zone -mcmodel=kernel -funit-at-a-time -maccumulate-outgoing-args -pipe -Wno-sign-compare -fno-asynchronous-unwind-tables -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -Wframe-larger-than=2048 -fno-stack-protector -fomit-frame-pointer -Wdeclaration-after-statement -Wno-pointer-sign -fno-strict-overflow -fno-dwarf2-cfi-asm -fconserve-stack
# -c -o kernel/fork.o kernel/fork.c


# vim: set tw=0:
