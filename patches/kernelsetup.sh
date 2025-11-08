#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Resolve the ROOT directory (one level above the patches/ folder) ---
# This makes the script work even when placed inside patches/
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"  # patches/
ROOT_DIR="$(cd "$SCRIPT_DIR/.." &> /dev/null && pwd)"                         # kernel root
echo "--- Running script from: $SCRIPT_DIR"
echo "--- Kernel root directory: $ROOT_DIR"

# Define paths relative to the root (one level up)
KSU_NEXT_DIR="$ROOT_DIR/KernelSU-Next"
KERNEL_DIR="$ROOT_DIR"
PATCH_FILE="$SCRIPT_DIR/latest_ksu.patch"           # inside patches/
SUSFS_PATCH_FILE="$SCRIPT_DIR/susfs_1.5.12_kernel.patch"


# --- Function to patch the local kernel with susfs ---
patch_kernel() {
    echo "--- Option 1: Patching kernel with susfs..."
    cd "$KERNEL_DIR"
    
    if [ ! -f "$SUSFS_PATCH_FILE" ]; then
        echo "ERROR: Susfs patch file not found at '$SUSFS_PATCH_FILE'. Aborting."
        exit 1
    fi
    
    echo "--- Applying 3-way patch: $SUSFS_PATCH_FILE"
    git apply --3way "$SUSFS_PATCH_FILE"
    
    echo ""
    echo "Kernel patched with susfs successfully."
}

# --- Function to download, sync next branch, and patch KernelSU-Next ---
setup_ksu_next() {
    echo "--- Option 2: Downloading and patching KernelSU-Next (next branch) ---"

    # Step 1: Download and run the KernelSU-Next setup script
    echo "--- Downloading and setting up KernelSU-Next..."
    cd "$ROOT_DIR"
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
    echo "--- KernelSU-Next setup complete."

    # Step 2: Verify repo directory
    if [ ! -d "$KSU_NEXT_DIR" ]; then
        echo "ERROR: The directory '$KSU_NEXT_DIR' was not created. Aborting."
        exit 1
    fi
    echo "--- Entering $KSU_NEXT_DIR"
    cd "$KSU_NEXT_DIR"

    # Step 3: Switch to 'next' branch and sync latest
    echo "--- Switching to branch 'next' and pulling latest commits..."
    git checkout next || { echo "ERROR: Failed to checkout branch 'next'."; exit 1; }
    git fetch origin
    git reset --hard origin/next
    echo "--- Repository is now up-to-date on branch 'next'."

    # Step 4: Apply custom patch from patches/ folder
    if [ ! -f "$PATCH_FILE" ]; then
        echo "ERROR: KSU-Next patch file not found at '$PATCH_FILE'. Aborting."
        exit 1
    fi
    echo "--- Applying 3-way patch: $PATCH_FILE"
    git apply "$PATCH_FILE"

    echo ""
    echo "Patch applied successfully. KernelSU-Next (next branch) is ready."
}


# --- Main menu ---
echo ""
echo "Please choose an option:"
echo "1) Patch current kernel with susfs"
echo "2) Download and patch KernelSU-Next (next branch, latest commits)"
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
    echo "Invalid option. Please run the script again and choose a number from 1 to 3."
    exit 1
    ;;
esac