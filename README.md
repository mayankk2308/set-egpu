![Header](https://raw.githubusercontent.com/mayankk2308/set-egpu/master/resources/header.png)

![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/set-egpu/total.svg?style=for-the-badge)
# Set-eGPU
Allows you to set graphics preferences for macOS applications, and force use of external GPUs, even on internal displays.

## Requirements
This script requires the following specifications:
* Mac running external GPU
* **macOS 10.13.4** or later

## Usage
Install set-eGPU.sh:
```bash
curl -s "https://api.github.com/repos/mayankk2308/set-egpu/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > set-eGPU.sh && chmod +x set-eGPU.sh && ./set-eGPU.sh && rm set-eGPU.sh
```

This will automatically install the latest version of **set-eGPU.sh**.

Alternatively, download [set-eGPU.sh](https://github.com/mayankk2308/set-egpu/releases). Then run the following in **Terminal**:
```bash
cd Downloads
chmod +x set-eGPU.sh
./set-eGPU.sh
```

On first-time use, the script will auto-install itself as a binary into `/usr/local/bin/`. This enables much simpler future use. To use the script again, just type the following in **Terminal**:
```bash
set-eGPU
```

## Options
The script provides users with a variety of options in an attempt to be as user-friendly as possible - as a numbered menu. Advanced users may pass arguments to bypass the menu.

#### 1. Set eGPU Preference for All Applications (`-sa|--set-all`)
Checks all available applications and sets their GPU preference to use eGPUs.

#### 2. Set eGPU Preference for Specified Application(s) (`-ss|--set-specified`)
Checks specified application(s) and sets its GPU preference to use eGPUs.

#### 3. Check Application eGPU Preference (`-c|--check`)
Reads specified application(s) GPU preferences.

#### 4. Reset GPU Preferences for All Applications (`-ra|--reset-all`)
Resets GPU preferences to system defaults for all applications.

#### 5. Reset GPU Preferences for Specified Application(s) (`-rs|--reset-specified`)
Recover original untouched macOS configuration prior to script modifications.

## Testing
Run your application and check **Activity Monitor** > Window > GPU History **(⌘ + 4)** for GPU statistics.

![Image](https://raw.githubusercontent.com/mayankk2308/set-egpu/master/resources/gpu-history.png)

## License
See the license file for more information.
