#!/usr/bin/env bash
set -e

# ==============================
# Kernel Version
# ==============================
KERNEL_NAME="UranusKernel"
KERNEL_CODENAME="Uranus ⚜️"
KERNEL_VERSION="$(date +%Y%m%d)"
ZIP_NAME="${KERNEL_NAME}-${KERNEL_VERSION}"

export KERNEL_NAME KERNEL_VERSION ZIP_NAME

# Kirim ZIP_NAME ke GitHub Actions
if [ -n "${GITHUB_ENV}" ]; then
    echo "ZIP_NAME=${ZIP_NAME}" >> "${GITHUB_ENV}"
fi

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
# Kernel local version (uname -r)
# ==============================
export LOCALVERSION="-Uranus"

# ==============================
# Backup defconfig
# ==============================
BACKUP_DIR=${WORK_DIR}/defconfig_backup
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
mkdir -p ${BACKUP_DIR}

cp arch/arm64/configs/${DEFCONFIG} \
   ${BACKUP_DIR}/${DEFCONFIG}.${TIMESTAMP}.bak

# ==============================
# Compile
# ==============================
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

# ==============================
# Create dtb.img (gabungan)
# ==============================
DTB_DIR="${OUT_DIR}/arch/arm64/boot/dts/qcom"
DTB_IMG="${OUT_DIR}/arch/arm64/boot/dtb.img"

if ls ${DTB_DIR}/*.dtb 1> /dev/null 2>&1; then
    echo "==> Creating dtb.img"
    cat ${DTB_DIR}/*.dtb > ${DTB_IMG}
fi

# ==============================
# Result Check
# ==============================
echo "==> Build finished: ${ZIP_NAME}"
ls -lh ${OUT_DIR}/arch/arm64/boot || true
