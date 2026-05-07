# ALTERA Simics Agilex5 Zephyr — Setup & Run Guide

---

## 1. Prerequisites

Ensure the following software is installed and all required project files are present before proceeding.

### 1.0 Install apt Dependencies

Install the required system packages before proceeding with any other steps:

```bash
sudo apt update && sudo apt install -y \
    telnet \
    tmux \
    libgtk2.0-dev \
    libgtk-3-dev \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu
```

| Package | Purpose |
|---------|---------|
| `telnet` | Connect to Simics serial console |
| `tmux` | Manage multiple terminal sessions |
| `gcc-aarch64-linux-gnu` | AArch64 cross-compiler (C) |
| `binutils-aarch64-linux-gnu` | AArch64 assembler & linker tools |

---

### 1.1 Download Simics Simulator for Intel FPGA for Linux

Download the Simics Simulator for Intel FPGA (version 26.1) for Linux from the Altera download portal:

🔗 **Download URL:** https://www.altera.com/downloads/simulation-tools/altera-simics

---

### 1.2 Download Quartus Prime Pro Edition 24.3 for Linux

Download the Quartus Prime Pro Edition Programmer and Tools (version 24.3) for Linux from the Altera download portal:

🔗 **Download URL:** https://www.altera.com/downloads/fpga-development-tools/quartus-prime-pro-edition-design-software-version-24-3-linux

| File | Size | Purpose |
|------|------|---------|
| `qinst-linux-24.3-212.run` | 63.1 MB | Recommended installer (SFX launcher) |

> **⚠ Required:** Quartus Prime Pro Edition Programmer and Tools under Add-ons.

## 2. Environment Variables

Add the following exports to `~/.bashrc` (or source them manually before each session). These configure the workspace root, Zephyr build output, ARM toolchain, Simics, and Quartus Programmer paths.

```bash
# ── Workspace & Zephyr ───────────────────────────────────────────────
export ZEPHYR_BIN=~/zephyrproject/zephyr

# ── Intel Simics 24.3 ────────────────────────────────────────────────
export PATH=~/intelFPGA_pro/intel-fpga-ext_24.3/simics/bin:$PATH

# ── Quartus Prime Pro 24.3 Programmer (Linux) ────────────────────────
export PATH=~/intelFPGA_pro/24.3/qprogrammer/quartus/bin:$PATH
```

---

## 3. Project Structure

### Directory Layout

```
simics_agilex5_zephyr/
└── build/
    ├── run.sh
    └── zephyr_qspi.simics
```

### 3.1 Make `run.sh` executable

Run the following commands from the `simics_agilex5_zephyr` root:

```bash
cd ~/simics_agilex5_zephyr
chmod +x build/run.sh
```

---

## 4. Running the Simulation (First Time)

### 4.1 Launch Commands

```bash
cd ~/simics_agilex5_zephyr/build
./run.sh -d   # Deploy for only first time
./run.sh -b   # Build and run
```

| Flag | Action |
|------|--------|
| `-b` | Build the project |
| `-d` | Deploy to simulation |
