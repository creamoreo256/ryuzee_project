#!/bin/bash
# Script sederhana untuk inject hook sound_control ke wcd937x.c

TARGET="techpack/audio/asoc/codecs/wcd937x/wcd937x.c"

# Backup dulu file asli
cp $TARGET ${TARGET}.bak

# Tambahkan include untuk sound_control.h jika belum ada
grep -q "sound_control.h" $TARGET || \
sed -i '1i #include "sound_control.h"' $TARGET

# Tambahkan hook ke dalam probe
sed -i '/static int wcd937x_probe(struct snd_soc_component \*component)/a \
    struct wcd937x_priv *wcd = snd_soc_component_get_drvdata(component);\n\
    sound_control_register_hw(wcd);' $TARGET

# Tambahkan hook ke remove (optional, biar rapi)
sed -i '/static void wcd937x_remove(struct snd_soc_component \*component)/a \
    sound_control_unregister_hw();' $TARGET

echo "✅ Patch berhasil diterapkan ke $TARGET"
echo "Backup ada di ${TARGET}.bak"
