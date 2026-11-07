#!/data/data/com.termux/files/usr/bin/bash

REPO_DIR="/data/data/com.termux/files/home/android_kernel_samsung_a05m"
LOG_FILE="$REPO_DIR/build.log"
TARGET_IMAGE="$REPO_DIR/out/arch/arm64/boot/Image.gz"

echo "[AUTO-SHUTDOWN] Otomatik kapanma izleyicisi devrede." >> "$LOG_FILE"

while true; do
    # Eğer build_cool.sh veya make çalışmaya devam ediyorsa bekle
    if pgrep -f "build_cool.sh|Image.gz" >/dev/null 2>&1; then
        sleep 10
        continue
    fi

    # Derleme süreci bitti, sonucu kontrol et
    if [ -f "$TARGET_IMAGE" ] && [ -s "$TARGET_IMAGE" ] && grep -q "\[BAŞARILI\] Derleme tamamlandı!" "$LOG_FILE" 2>/dev/null; then
        echo "[AUTO-SHUTDOWN] Derleme başarıyla tamamlandı!" >> "$LOG_FILE"
        echo "[AUTO-SHUTDOWN] Diskler senkronize ediliyor..." >> "$LOG_FILE"
        sync
        sleep 5
        echo "[AUTO-SHUTDOWN] Cihaz güvenli şekilde kapatılıyor..." >> "$LOG_FILE"
        su -c "svc power shutdown || reboot -p"
        break
    else
        echo "[AUTO-SHUTDOWN] Derleme tamamlanamadı veya hata oluştu; telefon kapatılmıyor (inceleme için açık tutuluyor)." >> "$LOG_FILE"
        break
    fi
done
