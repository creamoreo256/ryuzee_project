#!/usr/bin/env bash
set -e

# ==============================
# Kernel Version (SAFE)
# ==============================
KERNEL_NAME="UranusKernel"
KERNEL_CODENAME="Uranus ⚜️"
KERNEL_VERSION="$(date +%Y%m%d)"
ZIP_NAME="${KERNEL_NAME}-${KERNEL_VERSION}"

export KERNEL_NAME
export KERNEL_VERSION
export ZIP_NAME

# ==============================
# Build Identity
# ==============================
export KBUILD_BUILD_USER=ryuzee
export KBUILD_BUILD_HOST=project

# ==============================
# Arch & Path
# ==============================
export ARCH=arm64
export SUBARCH=arm64

WORK_DIR=$(pwd)
OUT_DIR=${WORK_DIR}/out
DEFCONFIG=surya_defconfig

export PATH=${WORK_DIR}/clang/bin:${PATH}

# ==============================
# Backup defconfig
# ==============================
BACKUP_DIR=${WORK_DIR}/defconfig_backup
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

mkdir -p ${BACKUP_DIR}

if [ -f arch/arm64/configs/${DEFCONFIG} ]; then
    cp arch/arm64/configs/${DEFCONFIG} \
       ${BACKUP_DIR}/${DEFCONFIG}.${TIMESTAMP}.bak
    echo "==> Defconfig backed up:"
    echo "    ${BACKUP_DIR}/${DEFCONFIG}.${TIMESTAMP}.bak"
else
    echo "!! Defconfig not found: ${DEFCONFIG}"
    exit 1
fi

# ==============================
# Output Image
# ==============================
KERN_IMG="${OUT_DIR}/arch/arm64/boot/Image.gz-dtb"
KERN_IMG2="${OUT_DIR}/arch/arm64/boot/Image.gz"

# ==============================
# Compile Function
# ==============================
compile() {
    mkdir -p ${OUT_DIR}

    echo "==> Using ${DEFCONFIG}"
    make O=${OUT_DIR} ARCH=arm64 ${DEFCONFIG}

    echo "==> Building kernel ${KERNEL_CODENAME}"
    make -j$(nproc) O=${OUT_DIR} ARCH=arm64 \
        CC=clang \
        LD=ld.lld \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

compile

# ==============================
# Result Check
# ==============================
echo "==> Build finished: ${ZIP_NAME}"
ls -lh ${OUT_DIR}/arch/arm64/boot || true
