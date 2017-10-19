SUMMARY = "Prebuilt bootlader images for Dragonboard 410c"

inherit deploy

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4d087ee0965cb059f1b2f9429e166f64"

SRC_URI = "https://builds.96boards.org/releases/dragonboard410c/linaro/rescue/17.04/dragonboard410c_bootloader_sd_linux-79.zip"
SRC_URI[md5sum] = "72e568ed77b6769634166180bed4adce"
SRC_URI[sha256sum] = "7ad477273c61d9f6c726495248ba8fba7f2e46bff2a7632098bb876a93e58540"

do_configure[noexec] = "1"

S =  "${WORKDIR}"

python do_unpack() {
    eula = d.getVar('ACCEPT_EULA_'+d.getVar('MACHINE', True), True)
    eula_file = d.getVar('QCOM_EULA_FILE', True)
    pkg = d.getVar('PN', True)
    if eula == None:
        bb.fatal("To use '%s' you need to accept the EULA at '%s'. "
                 "Please read it and in case you accept it, write: "
                 "ACCEPT_EULA_dragonboard-410c = \"1\" in your local.conf." % (pkg, eula_file))
    elif eula == '0':
        bb.fatal("To use '%s' you need to accept the EULA." % pkg)
    else:
        bb.note("EULA has been accepted for '%s'" % pkg)

    try:
        bb.build.exec_func('base_do_unpack', d)
    except:
        raise
}

do_deploy() {
    cp -a ${S}/*.mbn ${DEPLOYDIR}
}

addtask deploy before do_build after do_compile

BBCLASSEXTEND = "native"
