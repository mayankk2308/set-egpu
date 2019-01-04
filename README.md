![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/set-egpu.svg?style=for-the-badge) ![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/set-egpu/total.svg?style=for-the-badge) [![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20Set-eGPU&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

**set-eGPU.sh** allows you to set graphics preferences for macOS applications, and force use of external GPUs, even on internal displays. Please read through the entire documentation to familiarize yourself with the script, the community, and the resources available to you in case you find that you need help.

## Contents
A quick run-through of what's included in this document:
- [Pre-Requisites](https://github.com/mayankk2308/set-egpu#pre-requisites)
  - macOS requirements, pre-system configuration specifics, and more.
- [Installation](https://github.com/mayankk2308/set-egpu#installation)
  - Installing and running the script.
- [Script Options](https://github.com/mayankk2308/set-egpu#script-options)
  - Available capabilities and options in the script.
- [Post-Install](https://github.com/mayankk2308/set-egpu#post-install)
  - System configuration after script installation and some other things of note.
- [Troubleshooting](https://github.com/mayankk2308/set-egpu#troubleshooting)
  - Additional resources and guides for eGPUs.
- [Disclaimer](https://github.com/mayankk2308/set-egpu#disclaimer)
  - Please read the disclaimer before using this script.
- [License](https://github.com/mayankk2308/set-egpu#license)
  - By using this script, you consent to the license that the script comes bundled with.
- [Support](https://github.com/mayankk2308/set-egpu#support)
  - Support the developer if you'd like to.

## Pre Requisites
Please read [Apple](https://support.apple.com/en-us/HT208544)'s external GPU documentation first to see what is already supported on macOS. The following is a table that summarizes **system requirements** for using this script:

| Configuration | Requirement | Description |
| :-----------: | :---------: | :---------- |
| **macOS** | 10.13.4-6 | Script can be used without the presence of an external GPU and without any significant limitations. The algorithm used in previous versions of set-eGPU is still in place. |
| **macOS** | 10.14+ | External GPU **must be plugged in** to use the script. It is also recommended that you do not work with Finder while the script is updating preferences. |
| **Terminal Permissions** | Required | When prompted, please allow Terminal any permissions to control macOS, as this is necessary for setting eGPU preference on 10.14+. |

## Installation
**set-eGPU.sh** auto-manages itself and provides multiple installation and uninstallation options. Once the **pre-requisites** are satisfied, install the script by running the following in **Terminal**:
```bash
curl -s "https://api.github.com/repos/mayankk2308/set-egpu/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > set-eGPU.sh && chmod +x set-eGPU.sh && ./set-eGPU.sh && rm set-eGPU.sh
```

For future use, only the following will be required:
```bash
set-eGPU
```

In case the command above does not work, you can re-use the long installation command and fix the issue.

**Administrative privileges** are required *only for installation and software updates*. The script uses [sudo](https://support.apple.com/en-us/HT202035) to do so. All other script activity is performed in a *user-privileged* shell automatically.

The script includes a built-in uninstallation mechanism.

### Aside
Some applications, such as **Photos** do not have the option to "Prefer External GPU" in macOS 10.14+. Due to this, you may see a message saying that not all preferences were updated. This is not a big problem. A future update to set-eGPU will more appropriately handle such edge cases.

## Script Options
Set-eGPU makes it super-simple to automate eGPU preference management through a variety of options via an interactive menu. Providing no arguments defaults to the menu. The documentation represents **v2.0.0** or later.

| Argument | Menu | Description |
| :------: | :--: | :---------- |
| `-sa`, `--set-all` | Prefer eGPU - All Applications | Scans the typical system application directories for applications, opens their information window, sets "Prefer External GPU", and closes the window. |
| `-st`, `--set-target` | Prefer eGPU - All Applications At Target | Scans the path provided for applications, opens their information window, sets "Prefer External GPU", and closes the window. |
| `-ss`, `--set-specified` | Prefer eGPU - Specified Application(s) | Searches the typical system application directories for applications with given input, opens the information window, sets "Prefer External GPU", and closes the window. |
| `-ra`, `--reset-all` | Reset Preferences - All Applications | Scans the typical system application directories for applications, opens their information window, unselects "Prefer External GPU", and closes the window. |
| `-rt`, `--reset-target` | Reset Preferences - All Applications At Target | Scans the path provided for applications, opens their information window, unselects "Prefer External GPU", and closes the window. |
| `-rs`, `--reset-specified` | Reset Preferences - Specified Application(s) | Searches the typical system application directories for applications with given input, opens the information window, unselects "Prefer External GPU", and closes the window. |
| `-c`, `--check` | Check eGPU Preferences | Searches the typical system application directories for applications with given input, opens the information window, retrieves GPU preference, and closes the window. |
| `-u`, `--uninstall` | Uninstall Set-eGPU | Resets all preferences, and uninstalls set-eGPU from the system. Even if you set GPU preferences without using set-eGPU, they will be unselected. Preferences set at different targets are not restored. |


## Post-Install
After installing the script, you likely will not need it again unless you want to manage new apps. Most settings should be permanent. If you **upgraded from High Sierra to Mojave or later**, you will need to set preferences again, since the mechanism has significant changes after High Sierra.

## Troubleshooting
Check if your application is using the eGPU using [Activity Monitor](https://developer.apple.com/documentation/metal/tools_profiling_and_debugging/gpu_activity_monitors/monitoring_your_mac_s_gpu_activity/) before reading further. Troubleshooting plays an important role with eGPUs. New OSes and hardware tend to bring with them new problems and challenges. Even though eGPU support in macOS has become straightforward, not all applications may work as expected. The following is a list of additional resources rich in information:

| Resource | Description |
| :------: | :---------- |
| [eGPU.io Build Guides](https://egpu.io/build-guides/) | See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds. |
| [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/) | Learn about some basics of eGPUs in macOS and find out what means what. This guide does not cover any Windows/Bootcamp-related efforts. |
| [eGPU.io Community](https://egpu.io/forums/) | The eGPU.io forums are a great place to post concerns and doubts about your setup. Be sure to search the forum before posting as there might be high chance your doubt has already been answered. |
| [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/) | The reddit community is a wonderful place to request additional help for your new setup, and a good place to find fellow eGPU users. |

My username on both communities is [@mac_editor](https://egpu.io/forums/profile/mac_editor). Feel free to mention my username on eGPU.io posts - I get an email notifying me of the same. In any case, with thousands of members, the community is a welcoming place. Don't be shy!

## Disclaimer
This script does not make any dangerous/fatal system modifications and only automates some features in macOS. However, the developer is not liable for any damages to your system nonetheless.

## License
The bundled license allows commercial use and redistribution as advised under the MIT License. This software comes without any warranty or guaranteed support. By using the script, you **agree** to adhere to this license. For more information, please see the [LICENSE](./LICENSE.md).

## Support
If you loved **set-eGPU.sh**, consider **starring** the repository or if you would like to, donate via **PayPal**:

[![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20Set-eGPU&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **set-eGPU.sh**. This project is under *active* development at this time.
