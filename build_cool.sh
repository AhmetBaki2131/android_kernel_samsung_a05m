#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO_DIR="/data/data/com.termux/files/home/android_kernel_samsung_a05m"
LOG_FILE="$REPO_DIR/build.log"
cd "$REPO_DIR"

export LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so

# Termux wake-lock alarak cihaz uykudayken Termux'un uyumasını engelle
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[INFO] termux-wake-lock aktif edildi."
fi

# Termal eşikler
CPU_ZONE="/sys/class/thermal/thermal_zone8/temp"   # mtktscpu
AP_ZONE="/sys/class/thermal/thermal_zone14/temp"   # mtktsAP
BAT_ZONE="/sys/class/thermal/thermal_zone7/temp"   # battery

MAX_CPU_TEMP=68000   # 68.0°C (mtktscpu)
RESUME_CPU_TEMP=57000 # 57.0°C

MAX_AP_TEMP=49000    # 49.0°C (Dış gövde/AP)
RESUME_AP_TEMP=44000 # 44.0°C

MAX_BAT_TEMP=41000   # 41.0°C (Batarya)
RESUME_BAT_TEMP=37000 # 37.0°C

echo "==================================================" | tee -a "$LOG_FILE"
echo " Galaxy A05 (a05m) Linux 6.6.144 Serin Derleme" | tee -a "$LOG_FILE"
echo " Başlangıç: $(date)" | tee -a "$LOG_FILE"
echo " - Çekirdekler: Sadece Cortex-A55 (cpu0-3)" | tee -a "$LOG_FILE"
echo " - Paralellik : -j2 (Düşük RAM & Isı)" | tee -a "$LOG_FILE"
echo " - Termal Koruma:" | tee -a "$LOG_FILE"
echo "   CPU:  >$((MAX_CPU_TEMP/1000))°C duraklat, <$((RESUME_CPU_TEMP/1000))°C devam et" | tee -a "$LOG_FILE"
echo "   AP :  >$((MAX_AP_TEMP/1000))°C duraklat, <$((RESUME_AP_TEMP/1000))°C devam et" | tee -a "$LOG_FILE"
echo "   BAT:  >$((MAX_BAT_TEMP/1000))°C duraklat, <$((RESUME_BAT_TEMP/1000))°C devam et" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

# Derlemeyi arka planda başlat
taskset -c 0-3 nice -n 19 make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 -j2 Image.gz >> "$LOG_FILE" 2>&1 &
MAKE_PID=$!

echo "[BUILD] Make PID: $MAKE_PID çalışıyor..." | tee -a "$LOG_FILE"

get_process_tree() {
    local pids=("$1")
    local new_pids
    while true; do
        new_pids=$(pgrep -P "$(IFS=,; echo "${pids[*]}")" 2>/dev/null || true)
        [ -z "$new_pids" ] && break
        pids+=($new_pids)
    done
    echo "${pids[@]}"
}

PAUSED=0

cleanup() {
    echo "[INFO] Çıkış yapılıyor, temizleniyor..." | tee -a "$LOG_FILE"
    if [ -n "$MAKE_PID" ] && kill -0 "$MAKE_PID" 2>/dev/null; then
        all_pids=($(get_process_tree "$MAKE_PID"))
        kill -CONT "${all_pids[@]}" 2>/dev/null || true
        kill -TERM "${all_pids[@]}" 2>/dev/null || true
    fi
    if command -v termux-wake-unlock >/dev/null 2>&1; then
        termux-wake-unlock
    fi
}
trap cleanup EXIT INT TERM

# Termal bekçi döngüsü
while kill -0 "$MAKE_PID" 2>/dev/null; do
    CPU_T=$(cat "$CPU_ZONE" 2>/dev/null || echo 0)
    AP_T=$(cat "$AP_ZONE" 2>/dev/null || echo 0)
    BAT_T=$(cat "$BAT_ZONE" 2>/dev/null || echo 0)

    SHOULD_PAUSE=0
    if [ "$CPU_T" -ge "$MAX_CPU_TEMP" ] || [ "$AP_T" -ge "$MAX_AP_TEMP" ] || [ "$BAT_T" -ge "$MAX_BAT_TEMP" ]; then
        SHOULD_PAUSE=1
    fi

    SHOULD_RESUME=0
    if [ "$CPU_T" -le "$RESUME_CPU_TEMP" ] && [ "$AP_T" -le "$RESUME_AP_TEMP" ] && [ "$BAT_T" -le "$RESUME_BAT_TEMP" ]; then
        SHOULD_RESUME=1
    fi

    if [ "$SHOULD_PAUSE" -eq 1 ] && [ "$PAUSED" -eq 0 ]; then
        echo "[TERMAL KORUMA] ($(date +%H:%M:%S)) Sıcaklık yüksek (CPU: $((CPU_T/1000))°C, AP: $((AP_T/1000))°C, BAT: $((BAT_T/1000))°C). Derleme soğuması için duraklatılıyor..." | tee -a "$LOG_FILE"
        all_pids=($(get_process_tree "$MAKE_PID"))
        kill -STOP "${all_pids[@]}" 2>/dev/null || true
        PAUSED=1
    elif [ "$SHOULD_RESUME" -eq 1 ] && [ "$PAUSED" -eq 1 ]; then
        echo "[TERMAL KORUMA] ($(date +%H:%M:%S)) Sıcaklık normale döndü (CPU: $((CPU_T/1000))°C, AP: $((AP_T/1000))°C, BAT: $((BAT_T/1000))°C). Derleme devam ediyor..." | tee -a "$LOG_FILE"
        all_pids=($(get_process_tree "$MAKE_PID"))
        kill -CONT "${all_pids[@]}" 2>/dev/null || true
        PAUSED=0
    fi

    sleep 5
done

wait "$MAKE_PID"
BUILD_STATUS=$?

if [ "$BUILD_STATUS" -eq 0 ]; then
    echo "==================================================" | tee -a "$LOG_FILE"
    echo " [BAŞARILI] Derleme tamamlandı!" | tee -a "$LOG_FILE"
    echo " Bitiş: $(date)" | tee -a "$LOG_FILE"
    echo " Çıktı dosyası: $REPO_DIR/out/arch/arm64/boot/Image.gz" | tee -a "$LOG_FILE"
    ls -lh "$REPO_DIR/out/arch/arm64/boot/Image.gz" | tee -a "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
else
    echo "==================================================" | tee -a "$LOG_FILE"
    echo " [HATA] Derleme hata kodu ($BUILD_STATUS) ile sonuçlandı." | tee -a "$LOG_FILE"
    echo " Son 30 satır günlük:" | tee -a "$LOG_FILE"
    tail -n 30 "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
    exit "$BUILD_STATUS"
fi
