inherit image_types

IMAGE_NAME_SUFFIX = ""
IMAGE_DEPENDS_sdimg = "linux-linaro-qcomlt lk-sdcard"
IMAGE_TYPES += "sdimg"
IMAGE_TYPEDEP_sdimg = "ext4"

# LittleKernel images
LT_IMAGES_DIR = "${DEPLOY_DIR_IMAGE}"

SDIMG = "${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.sdimg"
SDIMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.ext4"
SDIMG_BOOTIMG = "${DEPLOY_DIR_IMAGE}/boot-sd-dragonboard-410c.img"

# leave first 64M untouched
SDIMG_LAYOUT_OFFSET="131072"

# name,size[kb],align,type,,image
SDIMG_LAYOUT="sbl1,512,,DEA0BA2C-CBDD-4805-B4F9-F428251C3E98,,${LT_IMAGES_DIR}/sbl1.mbn \
              rpm,512,,098DF793-D712-413D-9D4E-89D711772228,,${LT_IMAGES_DIR}/rpm.mbn \
              tz,1024,,A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4,,${LT_IMAGES_DIR}/tz.mbn \
              hyp,512,,E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A,,${LT_IMAGES_DIR}/hyp.mbn \
              sec,16,65536,303E6AC3-AF15-4C54-9E9B-D9A8FBECF401,, \
              aboot,1024,,400FFDCD-22E0-47E7-9A23-F16ED9382388,,${LT_IMAGES_DIR}/emmc_appsboot.mbn \
              boot,65536,,20117F86-E985-4357-B9EE-374BC1D8487D,,${SDIMG_BOOTIMG} \
              devinfo,1024,,1B81E7E6-F50D-419B-A739-2AEEF8DA3335,, \
              rootfs,,,,,${SDIMG_ROOTFS}"

# expand human readable values
real_size() {
    local size=$1
    case $size in
        *G|*g)
            size=`expr ${size%?} \* 1024 \* 1024 \* 1024` ;;
        *M|*m)
            size=`expr ${size%?} \* 1024 \* 1024` ;;
        *K|*k)
            size=`expr ${size%?} \* 1024` ;;
    esac
    echo $size
}

fill_the_image() {
    local number=1
    local start=${SDIMG_LAYOUT_OFFSET}

    for row in ${SDIMG_LAYOUT}; do
        # doesn't work here: IFS=',', read -r name size align type skip1 file <<< "$row"
        local name=`echo $row | cut -d',' -f1`
        local size=`echo $row | cut -d',' -f2`
        local align=`echo $row | cut -d',' -f3`
        local type=`echo $row | cut -d',' -f4`
        local file=`echo $row | cut -d',' -f6`

        if [ -n "$align" ]; then
            align=`expr $align \* 2`
            start=`expr \( \( $start \+ $align \- 1 \) \/ $align \) \* $align`
        fi

        if [ -n "$size" ]; then
            local end=`expr $start \+ $size \* 2 \- 1`
        else
            local end=0
        fi

        # assemble partition creation command
        sgdisk_args="-a 1 -n$number:$start:$end -c $number:$name"
        if [ -n "$type" ]; then
            sgdisk_args="$sgdisk_args -t $number:$type"
        fi

        sgdisk $sgdisk_args ${SDIMG}

        # copy source image into sd card partition
        if [ -n "$file" ]; then
            dd if=$file of=${SDIMG} conv=notrunc bs=512 seek=$start
        fi

        number=`expr $number \+ 1`
        start=`expr $end \+ 1`
    done
}

create_empty_image() {
    rootfs_img_size=`stat -L -c '%s' ${SDIMG_ROOTFS}`
    head_fixed_size=`expr 397344 \* 512`
    total_size=`expr $head_fixed_size \+ $rootfs_img_size`
    sd_size=`real_size ${SD_QCOM_SIZE}`

    if [ $sd_size -lt $total_size ]; then
        bbfail "Declared SD card size is too small"
    fi

    seek=`expr $sd_size \/ 1024 \- 1`
    dd if=/dev/zero of=${SDIMG} bs=1024 seek=$seek count=1

}

IMAGE_CMD_sdimg () {
    create_empty_image
    fill_the_image
}

