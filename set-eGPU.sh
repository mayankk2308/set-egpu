#!/usr/bin/env bash

# set-eGPU.sh
# Author(s): Mayank Kumar (@mac_editor, egpu.io / @mayankk2308, github.com)
# Version: 1.0.0

# ----- ENVIRONMENT

# Enable case-insensitive matching & null dereferences
shopt -s nocasematch
shopt -s nullglob

# Setup command args + data
SCRIPT="${BASH_SOURCE}"
OPTION=""
LATEST_SCRIPT_INFO=""
LATEST_RELEASE_DWLD=""

# Script binary
LOCAL_BIN="/usr/local/bin"
SCRIPT_BIN="${LOCAL_BIN}/set-eGPU"
TMP_SCRIPT="${LOCAL_BIN}/set-eGPU-new"
BIN_CALL=0
SCRIPT_FILE=""

# Script version
SCRIPT_MAJOR_VER="1" && SCRIPT_MINOR_VER="0" && SCRIPT_PATCH_VER="0"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"

# User input
INPUT=""

# Text management
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

# System information
MACOS_VER="$(sw_vers -productVersion)"
MACOS_BUILD="$(sw_vers -buildVersion)"
IS_HIGH_SIERRA=0

# GPU Policy
POLICY_KEY="GPUSelectionPolicy"
POLICY_VALUE="preferRemovable"

# ----- SOFTWARE UPDATES & INSTALLATION

# Perform software update
perform_software_update() {
  echo "${BOLD}Downloading...${NORMAL}"
  curl -L -s "${LATEST_RELEASE_DWLD}" > "${TMP_SCRIPT}"
  echo "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo "Update complete. ${BOLD}Relaunching...${NORMAL}"
  "${SCRIPT}"
  exit 0
}

# Prompt for update
prompt_software_update() {
  read -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n${BOLD}Proceeding without updating...${NORMAL}" && return
  echo -e "\nInvalid choice. Try again.\n"
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -s "https://api.github.com/repos/mayankk2308/set-egpu/releases/latest")"
  LATEST_RELEASE_VER="$(echo "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo -e "\n>> ${BOLD}Software Update${NORMAL}\n\nA script update (${BOLD}${LATEST_RELEASE_VER}${NORMAL}) is available.\nYou are currently on ${BOLD}${SCRIPT_VER}${NORMAL}."
    prompt_software_update
  fi
}

# Bin management procedure
install_bin() {
  rsync "${SCRIPT_FILE}" "${SCRIPT_BIN}"
  chown "${SUDO_USER}" "${SCRIPT_BIN}"
  chmod 700 "${SCRIPT_BIN}" && chmod a+x "${SCRIPT_BIN}"
}

# Bin first-time setup
first_time_setup() {
  [[ $BIN_CALL == 1 ]] && return
  SCRIPT_FILE="$(pwd)/$(echo "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA="$(shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo -e "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo -e "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
}

# Start installation
start_install() {
  CREATE_BIN_DIR="$(mkdir -p "${LOCAL_BIN}" 2>&1)"
  [[ ! -z "${CREATE_BIN_DIR}" ]] && echo "Failed to generate bin directory. ${BOLD}Continuing...${NORMAL}" && sleep 1 && return
  first_time_setup
  fetch_latest_release
}

# ----- SYSTEM CONFIGURATION MANAGER

# Check caller
validate_caller() {
  [[ "$1" == "sh" && ! "$2" ]] && echo -e "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit
  [[ "$1" != "$SCRIPT" ]] && OPTION="$3" || OPTION="$2"
  [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "set-eGPU" ]] && BIN_CALL=1
}

# macOS Version check
check_compatibility() {
  MACOS_MAJOR_VER="$(echo "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo -e "\nOnly ${BOLD}macOS 10.13.4 or later${NORMAL} compatible.\n" && exit
  [[ "${MACOS_MAJOR_VER}" == 13 ]] && IS_HIGH_SIERRA=1
}

# ----- APPLICATION PREFERENCES MANAGER

# Generalized set mechanism
set_app_pref() {
  TARGET_APP="${1}"
  [[ $IS_HIGH_SIERRA == 1 ]] && defaults write -app "${TARGET_APP}" "${POLICY_KEY}" "${POLICY_VALUE}" 2>&1 && return
  BUNDLE_ID=$(osascript -e "id of app \"${INPUT}\"")
  SafeEjectGPU SetPref "${BUNDLE_ID}" "${POLICY_KEY}" "${POLICY_VALUE}" 2>/dev/null 1>/dev/null
}

# Generalized reset mechanism
reset_app_pref() {
  TARGET_APP="${1}"
  if [[ $IS_HIGH_SIERRA == 1 ]]
  then
    CURRENT_PREF="$(defaults read -app "${TARGET_APP}" "${POLICY_KEY}" 2>/dev/null)"
    [[ -z "${CURRENT_PREF}" ]] && return
    defaults delete -app "${TARGET_APP}" "${POLICY_KEY}" 1>/dev/null 2>&1
  else
    BUNDLE_ID=$(osascript -e "id of app \"${INPUT}\"")
    SafeEjectGPU RemovePref "${BUNDLE_ID}" "${POLICY_KEY}" 1>/dev/null 2>&1
  fi
}

# Generic preference manageme for apps in given folder
manage_all_apps_prefs_in_folder() {
  [[ ! -e "${1}" ]] && echo "Incorrect folder path." && return
  while read APP
  do
    APP_NAME="${APP##*/}"
    APP_NAME="${APP_NAME%.*}"
    ${2} "${APP_NAME}"
  done < <(find "${1}" -maxdepth 1 -name "*.app")
}

# Set preferences for all applications
set_all_apps_egpu() {
  echo -e "\n>> ${BOLD}Set GPU Preferences for All Applications${NORMAL}\n\n${BOLD}Setting...${NORMAL}"
  [[ $IS_HIGH_SIERRA == 0 ]] && SafeEjectGPU SetPref - "${POLICY_KEY}" "${POLICY_VALUE}" 1>/dev/null 2>&1 && echo -e "Global preference set.\n" && return
  manage_all_apps_prefs_in_folder "/Applications" "set_app_pref"
  manage_all_apps_prefs_in_folder "${HOME}/Applications" "set_app_pref"
  echo -e "Preferences set.\n"
}

# Set preferences for specified application
set_specified_apps_egpu() {
  echo -e "\n>> ${BOLD}Reset GPU Preferences for Specified Application(s)${NORMAL}\n"
  echo "Please use the ${BOLD}exact${NORMAL} application name as seen in Launchpad."
  IFS= read -p "Enter application name: " INPUT
  echo -e "\n${BOLD}Setting...${NORMAL}"
  [[ ! -e "/Applications/${INPUT}.app" && ! -e "${HOME}/Applications/${INPUT}.app" ]] && echo -e "Target application does not exist. No action taken.\n" && return
  set_app_pref "${INPUT}"
  echo -e "Preferences set.\n"
}

# Reset preferences for all applications
reset_all_apps_prefs() {
  echo -e "\n>> ${BOLD}Reset GPU Preferences for All Applications${NORMAL}\n\n${BOLD}Resetting...${NORMAL}"
  if [[ $IS_HIGH_SIERRA == 0 ]]
  then
    RESET_PREF="$(SafeEjectGPU ResetPrefs 1>/dev/null 2>&1)"
    [[ ! -z "${RESET_PREF}" ]] && echo -e "An unknown error occurred while resetting preferences." && return
  else
    manage_all_apps_prefs_in_folder "/Applications" "reset_app_pref"
    manage_all_apps_prefs_in_folder "${HOME}/Applications" "reset_app_pref"
  fi
  echo -e "Reset complete.\n"
}

# Reset preferences for specified application
reset_specified_apps_prefs() {
  echo -e "\n>> ${BOLD}Reset GPU Preferences for Specified Application(s)${NORMAL}\n"
  echo "Please use the ${BOLD}exact${NORMAL} application name as seen in Launchpad."
  IFS= read -p "Enter application name: " INPUT
  echo -e "\n${BOLD}Resetting...${NORMAL}"
  [[ ! -e "/Applications/${INPUT}.app" && ! -e "${HOME}/Applications/${INPUT}.app" ]] && echo -e "Target application does not exist. No action taken.\n" && return
  reset_app_pref "${INPUT}"
  echo -e "Reset complete.\n"
}

# Check preferences for specified application
check_app_preferences() {
  echo -e "\n>> ${BOLD}Check Application eGPU Preference${NORMAL}\n"
  echo "Please use the ${BOLD}exact${NORMAL} application name as seen in Launchpad."
  IFS= read -p "Enter application name: " INPUT
  CURRENT_PREF=""
  [[ ! -e "/Applications/${INPUT}.app" && ! -e "${HOME}/Applications/${INPUT}.app" ]] && echo -e "\nTarget application does not exist. No action taken.\n" && return
  BUNDLE_ID=$(osascript -e "id of app \"${INPUT}\"")
  [[ $IS_HIGH_SIERRA == 1 ]] && CURRENT_PREF="$(defaults read -app "${INPUT}" "${POLICY_KEY}" 2>/dev/null)" || CURRENT_PREF="$(SafeEjectGPU evalPref ${BUNDLE_ID} ${POLICY_KEY} 2>/dev/null)"
  [[ "${CURRENT_PREF}" == "${POLICY_KEY}=<not set>" || -z "${CURRENT_PREF}" ]] && CURRENT_PREF="No preference set."
  [[ "${CURRENT_PREF}" == "${POLICY_KEY}=${POLICY_VALUE}" || "${CURRENT_PREF}" == "${POLICY_VALUE}" ]] && CURRENT_PREF="Prefers external GPUs."
  echo -e "${BOLD}Status${NORMAL}: ${CURRENT_PREF}\n"
}

# ----- DRIVER

# Ask for main menu
ask_menu() {
  read -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && clear && echo -e "\n>> ${BOLD}Set-eGPU (${SCRIPT_VER})${NORMAL}" && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo "
   ${BOLD}1.${NORMAL}  Set eGPU Preference for All Applications
   ${BOLD}2.${NORMAL}  Set eGPU Preference for Specified Application(s)
   ${BOLD}3.${NORMAL}  Check Application eGPU Preference
   ${BOLD}4.${NORMAL}  Reset GPU Preferences for All Applications
   ${BOLD}5.${NORMAL}  Reset GPU Preferences for Specified Application(s)
   ${BOLD}6.${NORMAL}  Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-6]: " INPUT
  [[ ! -z "${INPUT}" ]] && process_args "${INPUT}" || echo -e "\nNo input provided.\n"
  ask_menu
}

process_args() {
  case "${1}" in
    -sa|--set-all|1)
    set_all_apps_egpu;;
    -ss|--set-specified|2)
    set_specified_apps_egpu;;
    -c|--check|3)
    check_app_preferences;;
    -ra|--reset-all|4)
    reset_all_apps_prefs;;
    -rs|--reset-specified|5)
    reset_specified_apps_prefs;;
    6)
    echo && exit;;
    "")
    start_install
    clear && echo ">> ${BOLD}Set-eGPU (${SCRIPT_VER})${NORMAL}"
    provide_menu_selection;;
    *)
    echo -e "\nInvalid option.\n";;
  esac
}

# Primary execution routine
begin() {
  validate_caller "${1}" "${2}"
  check_compatibility
  process_args "${2}"
}

begin "${0}" "${1}"
