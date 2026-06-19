#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Check ZEPHYR_BIN
if [ -z "$ZEPHYR_BIN" ]; then
    echo -e "${RED}Error: ZEPHYR_BIN is not set!${NC}"
    echo -e "${GREEN}Example: export ZEPHYR_BIN=~/zephyrproject/zephyr${NC}"
    exit 1
fi

# If everything is set
echo -e "${GREEN}Environment variables are set correctly:${NC}"
echo "ZEPHYR_BIN = $ZEPHYR_BIN"

if [ "$(basename "$PWD")" != "build" ]; then
  echo -e "${RED}Error: This script must be run from the 'build' directory.${NC}" >&2
  exit 1
fi

if [[ "$1" == "-d" || "$1" == "--deploy" ]]; then
  cd ../ || { echo "Failed to cd ../"; exit 1; }
  simics_intelfpga_cli --deploy agilex5e-universal
  make
  cd build || { echo "Failed to cd build"; exit 1; }
  exit 0
fi

TOP_FOLDER=$PWD/..
REPO_DIR="$REPO_DIR"

# Clone only if not present
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository..."
    git clone -b QPDS24.3_REL_GSRD_PR \
        https://github.com/altera-opensource/arm-trusted-firmware "$REPO_DIR"
    git -C "$REPO_DIR" switch -c test 2>/dev/null || git -C "$REPO_DIR" switch test
    make -C "$REPO_DIR" realclean
else
    echo "Repository already exists. Skipping ATF clonning."
fi

if [ "$1" = "-b" ] || [ "$1" = "--build" ]; then
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    echo "Building ATF binary using $CROSS_COMPILE..."
    make -C "$REPO_DIR" PLAT=agilex5 SOCFPGA_BOOT_SOURCE_QSPI=1 DEBUG=1 bl2 bl31 PRELOADED_BL33_BASE=0x80100000 -j$(nproc)
else
    echo "Skipping ATF build"
fi

make -C "$REPO_DIR" fiptool
cp $REPO_DIR/tools/fiptool/fiptool $TOP_FOLDER/.

rm -rf zephyr.bin zephyr.elf
cp $ZEPHYR_BIN/build/zephyr/zephyr.bin .
cp $ZEPHYR_BIN/build/zephyr/zephyr.elf .
cp $REPO_DIR/build/agilex5/debug/bl2.bin .
cp $REPO_DIR/build/agilex5/debug/bl31.bin .
cp $REPO_DIR/build/agilex5/debug/bl2/bl2.elf .
cp $REPO_DIR/build/agilex5/debug/bl31/bl31.elf .

aarch64-linux-gnu-objcopy -v -I binary -O ihex --change-addresses 0x00000000 bl2.bin bl2.hex

$TOP_FOLDER/fiptool create --soc-fw bl31.bin --nt-fw zephyr.bin fip.bin

FILE="agilex5_factory.sof"
URL="https://releases.rocketboards.org/2024.11/gsrd/agilex5_dk_a5e065bb32aes1_gsrd/ghrd_a5ed065bb32ae6sr0_hps.sof"
TMP="ghrd_a5ed065bb32ae6sr0_hps.sof"

if [ ! -f "$FILE" ]; then
    echo "File not found. Downloading..."
    wget "$URL"
    mv "$TMP" "$FILE"
else
    echo "File already exists. Skipping download."
fi

DBG_FILE="qspi_hps_debug.sof"
DBG_URL="https://releases.rocketboards.org/2024.11/gsrd/agilex5_dk_a5e065bb32aes1_gsrd/ghrd_a5ed065bb32ae6sr0_hps_debug.sof"
DBG_TMP="ghrd_a5ed065bb32ae6sr0_hps_debug.sof"

if [ ! -f "$DBG_FILE" ]; then
    echo "File not found. Downloading..."
    wget "$DBG_URL"
    mv "$DBG_TMP" "$DBG_FILE"
else
    echo "File already exists. Skipping download."
fi

if [ ! -f qspi_flash_image_agilex5_boot.pfg ]; then
  tee qspi_flash_image_agilex5_boot.pfg << 'EOF'
<pfg version="1">
  <settings custom_db_dir="./" mode="ASX4"/>
  <output_files>
      <output_file name="flash_image" directory="." type="JIC">
          <file_options/>
          <secondary_file type="MAP" name="flash_image_jic">
              <file_options/>
          </secondary_file>
          <secondary_file type="SEC_RPD" name="flash_image_jic">
              <file_options bitswap="1"/>
          </secondary_file>
          <flash_device_id>Flash_Device_1</flash_device_id>
      </output_file>
  </output_files>
  <bitstreams>
      <bitstream id="Bitstream_1">
          <path hps_path="bl2.hex">agilex5_factory.sof</path>
      </bitstream>
  </bitstreams>
  <raw_files>
      <raw_file bitswap="1" type="RBF" id="Raw_File_1">bin/fip.bin</raw_file>
  </raw_files>
  <flash_devices>
      <flash_device type="MT25QU02G" id="Flash_Device_1">
          <partition reserved="1" fixed_s_addr="1" s_addr="0x00000000" e_addr="0x001FFFFF" fixed_e_addr="1" id="BOOT_INFO" size="0"/>
          <partition reserved="0" fixed_s_addr="0" s_addr="auto" e_addr="auto" fixed_e_addr="0" id="P1" size="0"/>
          <partition reserved="0" fixed_s_addr="0" s_addr="0x03C00000" e_addr="auto" fixed_e_addr="0" id="fip" size="0"/>
      </flash_device>
      <flash_loader>A5ED065BB32AE6SR0</flash_loader>
  </flash_devices>
  <assignments>
      <assignment page="0" partition_id="P1">
          <bitstream_id>Bitstream_1</bitstream_id>
      </assignment>
      <assignment page="0" partition_id="fip">
          <raw_file_id>Raw_File_1</raw_file_id>
      </assignment>
  </assignments>
</pfg>
EOF
fi

if [ "$1" = "-b" ] || [ "$1" = "--build" ]; then
    echo "Building QSPI binary using quartus_pfg..."
    quartus_pfg -c qspi_flash_image_agilex5_boot.pfg
else
    echo "Skipping quartus_pfg"
fi

pkill -9 -f simics

../simics ./zephyr_qspi.simics
