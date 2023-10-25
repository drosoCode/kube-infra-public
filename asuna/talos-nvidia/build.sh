#!/bin/bash

export TAG="v1.5.0-alpha.1"
DRIVER_VERSION="530.41.03"
TOOLKIT_VERSION="v1.12.1"
# container toolkit tag = driver version-toolkit version (ex: 530.41.03-v1.12.1)
export REGISTRY=ghcr.io
export USERNAME=drosocode
IMAGE=talos-installer-nvidia
ARCH=amd64

# ======================== nvidia driver ========================

# https://www.talos.dev/v1.5/talos-guides/configuration/nvidia-gpu-proprietary/

# start clean
rm -rf ./pkgs
rm -rf ./out

# make kernel and nvidia kernel module
git clone --depth=1 https://github.com/siderolabs/pkgs
cd pkgs
make kernel nonfree-kmod-nvidia PLATFORM=linux/$ARCH PUSH=1
cd .. && rm -rf ./pkgs

# create dockerfile to inject kernel and nvidia module
echo -e "FROM scratch as customization\n\
COPY --from=$REGISTRY/$USERNAME/nonfree-kmod-nvidia:$TAG /lib/modules /lib/modules\n\
COPY --from=$REGISTRY/$USERNAME/kernel:$TAG /lib/modules /kernel/lib/modules\n\
COPY ./dummy /dummy\n\
FROM ghcr.io/siderolabs/installer:$TAG\n\
COPY --from=customization /dummy /dummy\n\
COPY --from=$REGISTRY/$USERNAME/kernel:$TAG /boot/vmlinuz /usr/install/\${TARGETARCH}/vmlinuz"\
 > Dockerfile

# build installer image from dockerfile
docker build --squash --no-cache --build-arg RM="/lib/modules" -t $REGISTRY/$USERNAME/$IMAGE:$TAG .
docker push $REGISTRY/$USERNAME/$IMAGE:$TAG

# ======================== nvidia container toolkit ========================

# apply nvenc patch to siderolabs/nvidia-container-toolkit
# https://github.com/keylase/nvidia-patch/blob/master/patch.sh

echo -e "FROM debian:stable-slim AS builder\n\
COPY --from=ghcr.io/siderolabs/nvidia-container-toolkit:$DRIVER_VERSION-$TOOLKIT_VERSION / /data\n\
ADD https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh /patch.sh\n\
RUN ln -s /bin/true /bin/nvidia-smi && mkdir /usr/lib/x86_64-linux-gnu/nvidia && ln -s /data/rootfs/usr/local/lib /usr/lib/x86_64-linux-gnu/nvidia/current && chmod +x /patch.sh && bash /patch.sh -d "$DRIVER_VERSION"\n\
FROM scratch\n\
COPY --from=builder /data /"\
 > Dockerfile

docker build --no-cache -t $REGISTRY/$USERNAME/nvidia-container-toolkit:$DRIVER_VERSION-$TOOLKIT_VERSION .
docker push $REGISTRY/$USERNAME/nvidia-container-toolkit:$DRIVER_VERSION-$TOOLKIT_VERSION

# ======================== build image ========================

# build disk image from installer
mkdir -p ./out/extensions/nvidia
crane export --platform="linux/$ARCH" "$REGISTRY/$USERNAME/nvidia-container-toolkit:$DRIVER_VERSION-$TOOLKIT_VERSION" - | tar x -C "./out/extensions/nvidia"
docker run -v /dev:/dev -v "./out/extensions:/system/extensions" --rm --privileged $REGISTRY/$USERNAME/$IMAGE:$TAG image --platform nocloud --arch $ARCH --tar-to-stdout | tar xz -C out/
