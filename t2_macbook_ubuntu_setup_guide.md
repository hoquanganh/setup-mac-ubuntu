# Ubuntu 26.04 Setup Guide for T2 MacBook Pro

This guide outlines the steps required to get all hardware fully functional on a 2018-2020 MacBook Pro with the Apple T2 Security Chip after a fresh installation of Ubuntu 26.04 (Resolute). 

Standard Linux kernels lack the drivers to interact directly with the T2 chip, which handles the internal keyboard, trackpad, Wi-Fi, Bluetooth, and audio. Therefore, you must install a custom kernel (from the **T2Linux** project) and extract proprietary firmware.

## Prerequisites

Before beginning, ensure your MacBook has an active internet connection. Since the internal Wi-Fi will not work initially, you will need to use one of the following:
- A USB Wi-Fi adapter (dongle).
- USB Ethernet adapter.
- USB Tethering via a smartphone.

---

## Step 1: Add the T2Linux Repository

First, you need to add the third-party repositories that host the customized drivers and kernels.

1. Open your terminal.
2. Update your package manager and install necessary utilities (`curl` and `gpg`):
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   ```
3. Add the **Common** T2 repository key and list:
   ```bash
   curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
   
   sudo curl -s --compressed -o /etc/apt/sources.list.d/t2.list "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
   ```
4. Add the **Release-specific** repository for Ubuntu 26.04 (`resolute`):
   ```bash
   echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/resolute ./" | sudo tee /etc/apt/sources.list.d/t2-release.list
   ```

---

## Step 2: Install the Custom Kernel and Drivers

Now that the repositories are configured, install the custom T2 kernel and utility scripts.

1. Update your package list with the newly added repositories:
   ```bash
   sudo apt update
   ```
2. Install the necessary packages:
   ```bash
   sudo apt install -y linux-t2 apple-t2-audio-config apple-firmware-script
   ```
   * **`linux-t2`**: The custom Linux kernel that adds support for the keyboard, trackpad, and internal components connected to the T2 chip.
   * **`apple-t2-audio-config`**: Configuration files to map the internal speakers and microphones properly.
   * **`apple-firmware-script`**: A utility script required in Step 4 to fetch the proprietary Wi-Fi and Bluetooth drivers.

---

## Step 3: Reboot

You must reboot your machine to start using the new `linux-t2` kernel. 

```bash
sudo reboot
```

> [!IMPORTANT]
> Once you reboot, your internal keyboard and trackpad will be functional. However, your internal Wi-Fi will still not work until you complete Step 4.

---

## Step 4: Extract Wi-Fi and Bluetooth Firmware

Because Apple's Wi-Fi and Bluetooth firmware blobs are proprietary, they cannot be legally distributed directly through Linux packages. The `apple-firmware-script` you installed earlier fetches a macOS Recovery image from Apple's servers, extracts the specific Wi-Fi/Bluetooth firmware files required for your exact Mac model, and places them in the correct Linux directories.

1. Ensure your external USB internet connection is still active.
2. Run the firmware extraction script non-interactively to download it from the internet:
   ```bash
   sudo get-apple-firmware get_from_online
   ```
   *(Note: This process may take a few minutes as it downloads a 500MB+ recovery image from Apple and unpacks it.)*

Once the script completes, it will automatically load the extracted firmware, and your internal Wi-Fi and Bluetooth should immediately become active and available in your network settings! You can safely disconnect your USB Wi-Fi dongle or tether.
