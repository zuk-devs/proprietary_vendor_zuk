#!/system/bin/sh
if [ -f /system/etc/recovery-transform.sh ]; then
  exec sh /system/etc/recovery-transform.sh 51855360 16e4597dd73edc692efd495eee4c5c231e9a2dce 45649920 fc4ddadc7b871033472d8a8975f4d22f6f2f0c22
fi
if ! applypatch -c EMMC:/dev/block/bootdevice/by-name/recovery:51855360:16e4597dd73edc692efd495eee4c5c231e9a2dce; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/bootdevice/by-name/boot:45649920:fc4ddadc7b871033472d8a8975f4d22f6f2f0c22 EMMC:/dev/block/bootdevice/by-name/recovery 16e4597dd73edc692efd495eee4c5c231e9a2dce 51855360 fc4ddadc7b871033472d8a8975f4d22f6f2f0c22:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
