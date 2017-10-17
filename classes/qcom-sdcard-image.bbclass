inherit image_types

DEPENDS = "linux-linaro-qcomlt lk-sdcard"

IMAGE_TYPEDEP_sdimg = "ext4"

# SD card image name
SDIMG = "${IMGDEPLOYDIR}/${IMAGE_NAME}.sdimg"
SDIMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.ext4"
SDIMG_BOOTIMG = "${DEPLOY_DIR_IMAGE}/boot-dragonboard-410c.img"

LT_IMAGES_DIR = "${DEPLOY_DIR_IMAGE}"

create_parted_image() {
    dd if=/dev/zero of=${SDIMG} bs=1M count=4096        
    sgdisk -a 1 -n1:131072:132095  -c 1:sbl1 -t 1:DEA0BA2C-CBDD-4805-B4F9-F428251C3E98 ${SDIMG}              
    sgdisk -a 1 -n2:132096:133119  -c 2:rpm -t 2:098DF793-D712-413D-9D4E-89D711772228 ${SDIMG}               
    sgdisk -a 1 -n3:133120:135167  -c 3:tz -t 3:A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4 ${SDIMG}                
    sgdisk -a 1 -n4:135168:136191  -c 4:hyp -t 4:E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A ${SDIMG}               
    sgdisk -a 1 -n5:262144:262175  -c 5:sec -t 5:303E6AC3-AF15-4C54-9E9B-D9A8FBECF401 ${SDIMG}               
    sgdisk -a 1 -n6:262176:264223  -c 6:aboot -t 6:400FFDCD-22E0-47E7-9A23-F16ED9382388 ${SDIMG}             
    sgdisk -a 1 -n7:264224:395295  -c 7:boot -t 7:20117F86-E985-4357-B9EE-374BC1D8487D ${SDIMG}              
    sgdisk -a 1 -n8:395296:397343  -c 8:devinfo -t 8:1B81E7E6-F50D-419B-A739-2AEEF8DA3335 ${SDIMG}           
    sgdisk -a 1 -n9:397344:8388574 -c 9:rootfs ${SDIMG} 
}

IMAGE_CMD_sdimg () {
    printenv > "${IMGDEPLOYDIR}/env.img"
    create_parted_image    

    dd if=${LT_IMAGES_DIR}/sbl1.mbn of=${SDIMG} conv=notrunc bs=512 seek=131072
    dd if=${LT_IMAGES_DIR}/rpm.mbn of=${SDIMG} conv=notrunc bs=512 seek=132096
    dd if=${LT_IMAGES_DIR}/tz.mbn of=${SDIMG} conv=notrunc bs=512 seek=133120
    dd if=${LT_IMAGES_DIR}/hyp.mbn of=${SDIMG} conv=notrunc bs=512 seek=135168
    dd if=${LT_IMAGES_DIR}/emmc_appsboot.mbn of=${SDIMG} conv=notrunc bs=512 seek=262176
    dd if=${SDIMG_BOOTIMG} of=${SDIMG} conv=notrunc bs=512 seek=264224
    dd if=${SDIMG_ROOTFS} of=${SDIMG} conv=notrunc bs=512 seek=397344
}

