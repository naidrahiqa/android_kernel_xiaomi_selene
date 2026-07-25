### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# begin properties
properties() { '
kernel.string=Phrolova Kernel — by @Naidra
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=selene
device.name2=merlin
device.name3=lancelot
supported.versions=
supported.patchlevels=
'; } # end properties

### AnyKernel install
# begin attributes
attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes


## boot shell variables
BLOCK=auto;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# MTK-safe unpack_ramdisk
# - Retries with MTK header (512B) stripped if first cpio extraction fails
# - Never aborts on ramdisk failure — uses original ramdisk as fallback
unpack_ramdisk() {
  local comp vndrname retries;

  cd $SPLITIMG;
  if [ -f ramdisk.cpio.gz ]; then
    dd bs=512 skip=1 conv=notrunc if=ramdisk.cpio.gz of=ramdisk.cpio 2>/dev/null;
    mv -f ramdisk.cpio.gz ramdisk.cpio.gz.orig;
  fi;

  if [ -f ramdisk.cpio ]; then
    [ -d $RAMDISK ] && mv -f $RAMDISK $AKHOME/rdtmp;
    comp=$(magiskboot decompress ramdisk.cpio 2>&1 | grep -v 'raw' | sed -n 's;.*\[\(.*\)\];\1;p');
    if [ "$comp" ]; then
      mv -f ramdisk.cpio ramdisk.cpio.$comp;
      magiskboot decompress ramdisk.cpio.$comp ramdisk.cpio;
      if [ $? != 0 ] && $comp --help 2>/dev/null; then
        $comp -dc ramdisk.cpio.$comp > ramdisk.cpio;
      fi;
    fi;

    mkdir -p $RAMDISK; chmod 755 $RAMDISK;

    retries=0;
    while [ $retries -lt 2 ]; do
      cd $RAMDISK;
      EXTRACT_UNSAFE_SYMLINKS=1 cpio -d -F $SPLITIMG/ramdisk.cpio -i 2>/dev/null;
      if [ $? = 0 ] && [ "$(ls -A)" ]; then
        break;
      fi;
      cd $SPLITIMG;
      if [ $retries = 0 ]; then
        dd bs=512 skip=1 conv=notrunc if=ramdisk.cpio of=ramdisk.cpio.stripped 2>/dev/null;
        mv -f ramdisk.cpio.stripped ramdisk.cpio;
      fi;
      retries=$((retries + 1));
    done;

    cd $SPLITIMG;
    if [ $retries -ge 2 ]; then
      rm -rf $RAMDISK $AKHOME/rdtmp 2>/dev/null;
      ui_print " "; ui_print "Warning: ramdisk extraction failed, using original ramdisk...";
    fi;
    if [ -d "$AKHOME/rdtmp" ] && [ -d "$RAMDISK" ]; then
      cp -af $AKHOME/rdtmp/* $RAMDISK/ 2>/dev/null;
    fi;
  elif [ -d vendor_ramdisk ]; then
    [ -d $VENDORRD ] && mv -f $VENDORRD $AKHOME/vrdtmp;
    for vndrname in vendor_ramdisk/*.cpio; do
      comp=$(magiskboot decompress $vndrname 2>&1 | grep -v 'raw' | sed -n 's;.*\[\(.*\)\];\1;p');
      if [ "$comp" ]; then
        mv -f $vndrname $vndrname.$comp;
        magiskboot decompress $vndrname.$comp $vndrname;
        if [ $? != 0 ] && $comp --help 2>/dev/null; then
          $comp -dc $vndrname.$comp > $vndrname;
        fi;
      fi;
      vndrname=$(basename $vndrname .cpio);
      mkdir -p $VENDORRD/$vndrname; chmod 755 $VENDORRD/$vndrname;
      cd $VENDORRD/$vndrname;
      EXTRACT_UNSAFE_SYMLINKS=1 cpio -d -F $SPLITIMG/vendor_ramdisk/$vndrname.cpio -i 2>/dev/null;
      if [ $? != 0 -o ! "$(ls -A)" ]; then
        rm -rf $VENDORRD $AKHOME/vrdtmp 2>/dev/null;
        ui_print " "; ui_print "Warning: vendor ramdisk \"$vndrname\" extraction failed, using original...";
      fi;
      if [ -d "$AKHOME/vrdtmp/$vndrname" ]; then
        cp -af $AKHOME/vrdtmp/$vndrname/* $VENDORRD/$vndrname/ 2>/dev/null;
      fi;
    done;
    cd $VENDORRD;
  else
    ui_print " "; ui_print "Warning: no ramdisk found, continuing...";
  fi;
  cd $AKHOME;
}

# boot install
dump_boot;
attributes;
write_boot;
## end boot install