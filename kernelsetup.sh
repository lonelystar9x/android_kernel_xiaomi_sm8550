#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the absolute path of the directory where this script is located.
# This makes the script runnable from any location.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
echo "--- Running script from: $SCRIPT_DIR"

# Define paths for clarity and easier maintenance
KSU_NEXT_DIR="$SCRIPT_DIR/KernelSU-Next"
KERNEL_DIR="$SCRIPT_DIR"
PATCH_FILE="$SCRIPT_DIR/patches/latest_ksu.patch"
SUSFS_PATCH_FILE="$SCRIPT_DIR/patches/susfs_1.5.12_kernel.patch"


# --- Function to patch the local kernel with susfs ---
patch_kernel() {
    echo "--- Option 1: Patching kernel with susfs..."
    cd "$KERNEL_DIR"
    
    if [ ! -f "$SUSFS_PATCH_FILE" ]; then
        echo "❌ ERROR: Susfs patch file not found at '$SUSFS_PATCH_FILE'. Aborting."
        exit 1
    fi
    
    echo "--- Applying 3-way patch: $SUSFS_PATCH_FILE"
    git apply --3way "$SUSFS_PATCH_FILE"
    
    echo ""
    echo "✅ Kernel patched with susfs successfully."
}

# --- Function to download and patch KernelSU-Next ---
setup_ksu_next() {
    echo "--- Option 2: Downloading and patching KernelSU-Next ---"

    # Step 1: Download and run the KernelSU-Next setup script
    echo "--- Downloading and setting up KernelSU-Next..."
    cd "$SCRIPT_DIR"
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
    echo "--- KernelSU-Next setup complete."

    # Step 2: Navigate into the KernelSU-Next git repository
    if [ ! -d "$KSU_NEXT_DIR" ]; then
        echo "❌ ERROR: The directory '$KSU_NEXT_DIR' was not created. Aborting."
        exit 1
    fi
    echo "--- Changing directory to $KSU_NEXT_DIR"
    cd "$KSU_NEXT_DIR"

    # Step 3: Apply the patch
    if [ ! -f "$PATCH_FILE" ]; then
        echo "❌ ERROR: KSU-Next patch file not found at '$PATCH_FILE'. Aborting."
        exit 1
    fi
    echo "--- Applying 3-way patch: $PATCH_FILE"
    git apply --3way "$PATCH_FILE"

    echo ""
    echo "✅ Patch applied successfully. KernelSU-Next is ready."
}


# --- Main script execution: Show menu and get user choice ---

echo ""
echo "Please choose an option:"
echo "1) Patch current kernel with susfs"
echo "2) Download and patch KernelSU-Next"
echo "3) Exit"
echo ""

read -p "Enter your choice [1-3]: " choice

case "$choice" in
  1)
    patch_kernel
    ;;
  2)
    setup_ksu_next
    ;;
  3)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "❌ Invalid option. Please run the script again and choose a number from 1 to 3."
    exit 1
    ;;
esac