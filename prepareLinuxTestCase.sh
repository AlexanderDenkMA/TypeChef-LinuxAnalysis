#!/bin/sh -v
version=linux-2.6.33.3

#tarball=$version.tar.bz2
#if [ ! -f $tarball ]; then
#  wget http://www.kernel.org/pub/linux/kernel/v2.6/$tarball
#fi
#tar xjf $tarball

cd $version
patchesPath=../linux-2.6.33.3-patches
while read i; do
  patch -p1 -i $patchesPath/$i
done < $patchesPath/series

make allnoconfig ARCH=x86
make prepare ARCH=x86
# Creates include/generated/compile.h needed for init/version.o; the command
# will give an error which we want to ignore.
make SUBDIRS=init ARCH=x86 &> /dev/null


sbt compile 
./run.sh de.fosd.typechef.linux.ProcessFileList linux_2.6.33.3_pcs.txt --workingDir l/ --openFeatureList=openFeaturesList.txt
