#!/bin/bash

rm -rf data
mkdir data
CT=$(docker create ghcr.io/drosocode/installer:v1.4.4-nvidia)
docker export $CT | tar -xC data
cd data
cp usr/install/amd64/initramfs.xz ./
xz -d initramfs.xz
cpio -idvm < initramfs
mkdir rootfs
unsquashfs -f -d rootfs rootfs.sqsh
docker rm $CT
tree rootfs/lib/modules/
