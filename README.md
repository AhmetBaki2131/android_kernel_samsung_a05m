# Samsung Galaxy A05 (a05m) Linux 6.6 Kernel Source

Official Linux 6.6 LTS kernel source tree for the **Samsung Galaxy A05** (`SM-A055F`, codename `a05m`), powered by the **MediaTek Helio G85 (MT6768)** chipset, featuring **KernelSU (UAPI 5)** and **SUSFS v1.5.5** stealth root subsystem.

---

## 📱 Device Specifications

| Attribute | Specification |
| :--- | :--- |
| **Device Model** | Samsung Galaxy A05 (`SM-A055F` / `SM-A055F/DS`) |
| **Codename** | `a05m` |
| **SoC / Chipset** | MediaTek Helio G85 (`MT6768` / `MT6769V/CZ`) |
| **Architecture** | ARM64 (`aarch64`) - 2x Cortex-A75 & 6x Cortex-A55 |
| **Kernel Version** | Linux `6.6.144` LTS (GKI Android 15 / 17 compatible) |
| **License** | **GNU General Public License v2 (GPL-2.0)** |

---

## ⚡ Features & Enhancements

* **Linux 6.6.144 LTS Base:** Generic Kernel Image (GKI) compliant with Android 15 and Android 17 (PixelOS / LineageOS 24).
* **Thermal & Power Management Optimizations (Helio G85 / MT6768):**
  * **CASS (Capacity Aware Superset Scheduler):** Enabled with Android vendor hook integration for energy-efficient big.LITTLE (2x Cortex-A75 + 6x Cortex-A55) load balancing and thermal pressure awareness.
  * **Asymmetric Schedutil Rate Limiting:** Separate `up_rate_limit_us` (4000µs big / 2000µs LITTLE) and `down_rate_limit_us` (500µs big / 1000µs LITTLE) with reduced frequency tipping margin (12.5%) and 50% capped I/O wait boost.
  * **PID Thermal Power Allocator & Proactive Step-Wise Throttling:** IPA (`power_allocator`) default thermal governor with MediaTek AUXADC/LVTS thermal drivers and non-oscillating step-wise mitigation.
  * **Faster Util_Est Decay & Lazy RCU / Power-Efficient Workqueues:** Rapid EWMA utilization decay after bursts, `CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y`, and Lazy RCU callbacks enabled by default.
* **KernelSU Integrated:** Native kernel-level root solution using modern UAPI 5 IOCTL interface.
* **SUSFS v1.5.5:** Advanced stealth subsystem for root and overlay cloaking (`CONFIG_KSU_SUSFS=y`).
* **eBPF & Modern Networking:** Full support for Android 15+ network policing and BPF cgroup filtering.
* **Dynamic Partitions:** Full dm-linear / device-mapper compatibility with Samsung dynamic partitions (`super.img`).
* **Display Pacing:** SurfaceFlinger 60Hz frame pacing enhancements for MediaTek DPU.

---

## 🛠️ Building the Kernel

This kernel uses Android's Bazel / Kleaf build system with hermetic Clang/LLVM toolchains:

```bash
# Set up toolchain and Kleaf environment
tools/bazel run //kernel_device_modules-6.6:mgk_64_k66_kernel_aarch64_dist

# Build boot image and vendor modules
tools/bazel run //kernel_device_modules-6.6:mgk_64_k66_modules_install
```

---

## 📄 License

This project is open-source software licensed under the terms of the **GNU General Public License version 2 (GPL-2.0)**, as specified in the [COPYING](COPYING) file.

```
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.
```
