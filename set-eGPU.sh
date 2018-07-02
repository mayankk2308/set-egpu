#!/usr/bin/env bash

# set-eGPU.sh
# Author(s): Mayank Kumar (@mac_editor, egpu.io / @mayankk2308, github.com)
# Version: 1.1.0

# ----- ENVIRONMENT

# Enable null dereferences
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
SCRIPT_MAJOR_VER="1" && SCRIPT_MINOR_VER="1" && SCRIPT_PATCH_VER="0"
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
GPU_EJECT_POLICY_KEY="GPUEjectPolicy"
GPU_EJECT_POLICY_VALUE="relaunch"
GPU_SELECTION_POLICY_KEY="GPUSelectionPolicy"
GPU_SELECTION_POLICY_VALUE="preferRemovable"

# Exempt App Location(s)
UTILITIES="/Applications/Utilities"

# Found application(s) history
APPS_LIST=()

# ----- SOFTWARE UPDATES & INSTALLATION

# Elevate privileges
elevate_privileges() {
  if [[ $(id -u) != 0 ]]
  then
    sudo bash "${SCRIPT}" "${OPTION}"
    exit
  fi
}

# Perform software update
perform_software_update() {
  echo -e "${BOLD}Downloading...${NORMAL}"
  curl -L -s "${LATEST_RELEASE_DWLD}" > "${TMP_SCRIPT}"
  echo -e "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo -e "Update complete. ${BOLD}Relaunching...${NORMAL}"
  su "${SUDO_USER}" "${SCRIPT}"
  exit
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
  LATEST_RELEASE_VER="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    elevate_privileges
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
  SCRIPT_FILE="$(pwd)/$(echo -e "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo -e "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA="$(shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  mkdir -p "${LOCAL_BIN}"
  elevate_privileges
  echo -e "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo -e "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
  su "${SUDO_USER}" "${SCRIPT}"
  exit
}

# Start installation
start_install() {
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
  MACOS_MAJOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo -e "\nOnly ${BOLD}macOS 10.13.4 or later${NORMAL} compatible.\n" && exit
  [[ "${MACOS_MAJOR_VER}" == 13 ]] && IS_HIGH_SIERRA=1
}

# ----- APPLICATION PREFERENCES MANAGER

# Generalized set mechanism
set_app_pref() {
  BUNDLE_ID="${1}"
  if [[ $IS_HIGH_SIERRA == 1 ]]
  then
    defaults write "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" "${GPU_SELECTION_POLICY_VALUE}" 2>&1
    defaults write "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" "${GPU_EJECT_POLICY_VALUE}" 2>&1
    return
  fi
  SafeEjectGPU SetPref "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" "${GPU_SELECTION_POLICY_VALUE}" 2>/dev/null 1>/dev/null
  SafeEjectGPU SetPref "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" "${GPU_EJECT_POLICY_VALUE}" 2>/dev/null 1>/dev/null
}

# Generalized reset mechanism
reset_app_pref() {
  BUNDLE_ID="${1}"
  if [[ $IS_HIGH_SIERRA == 1 ]]
  then
    CURRENT_GPU_PREF="$(defaults read "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 2>/dev/null)"
    CURRENT_EJECT_PREF="$(defaults read "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" 2>/dev/null)"
    [[ -z "${CURRENT_GPU_PREF}" && -z "${CURRENT_EJECT_PREF}" ]] && return
    defaults delete "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 1>/dev/null 2>&1
  else
    SafeEjectGPU RemovePref "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 1>/dev/null 2>&1
    SafeEjectGPU RemovePref "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" 1>/dev/null 2>&1
  fi
}

# Generic preference manageme for apps in given folder
manage_all_apps_prefs_in_folder() {
  [[ ! -d "${1}" ]] && return
  while read APP
  do
    [[ "${APP}" =~ "${UTILITIES}" ]] && continue
    BUNDLE_ID=$(osascript -e "id of app \"${APP}\"" 2>/dev/null)
    [[ -z "${BUNDLE_ID}" ]] && continue
    "${2}" "${BUNDLE_ID}"
  done < <(find "${1}" -name "*.app" -prune 2>/dev/null)
}

# Manage preferences for all applications
manage_all_apps_egpu() {
  echo -e "\n>> ${BOLD}${1} GPU Preferences for All Applications${NORMAL}\n\n${BOLD}${1}ting...${NORMAL}"
  MESSAGE="$(echo -e "${1}" | awk '{ print tolower($0) }')"
  if [[ $IS_HIGH_SIERRA == 0 ]]
  then
    [[ "${1}" == "Set" ]] && set_app_pref "-" 2>&1 && echo -e "Global preference ${MESSAGE}.\n" && return
    [[ "${1}" == "Reset" ]] && reset_app_pref "-" && echo -e "Global preference ${MESSAGE}.\n" && return
  fi
  manage_all_apps_prefs_in_folder "/Applications" "${2}"
  manage_all_apps_prefs_in_folder "${HOME}/Applications" "${2}"
  manage_all_apps_prefs_in_folder "${HOME}/Library" "${2}"
  echo -e "Preferences ${MESSAGE}.\n"
}

manage_pref_for_found_app() {
  local APP_PATH="${1}"
  local INTENT="${2}"
  MESSAGE="$(echo -e "${INTENT}" | awk '{ print tolower($0) }')"
  local FUNCTION="${3}"
  local APP_PRINT_NAME="${APP_PATH##*/}"
  local APP_PRINT_NAME="${APP_PRINT_NAME%.*}"
  BUNDLE_ID=$(osascript -e "id of app \"${APP_PATH}\"" 2>/dev/null)
  [[ -z "${BUNDLE_ID}" ]] && echo -e "\nTarget application does not exist. No action taken.\n" && return
  echo -e "\n${BOLD}${INTENT}ting preference for ${APP_PRINT_NAME}...${NORMAL}"
  "${FUNCTION}" "${BUNDLE_ID}"
  echo -e "Preferences ${MESSAGE}.\n"
}

# Ask for specific application
request_specific_app() {
  local INTENT="${1}"
  local FUNCTION="${2}"
  echo
  read -p "Which application? [1-${APP_COUNT} | Q]: " INPUT
  [[ "${INPUT}" == "Q" ]] && echo -e "\nNo preferences changed.\n" && return
  [[ ! "${INPUT}" =~ [0-9] ]] && echo -e "\nInvalid input. Try again." && request_specific_app "${APP_PATH}" "${INTENT}" "${FUNCTION}" && return
  (( INPUT-- ))
  (( $INPUT < 0 || $APP_COUNT <= $INPUT )) && echo -e "\nInvalid choice. Try again." && request_specific_app "${APP_PATH}" "${INTENT}" "${FUNCTION}" && return
  manage_pref_for_found_app "${APPS_LIST[$INPUT]}" "${INTENT}" "${FUNCTION}"
}

# Manage preferences for specified application
manage_specified_apps_egpu() {
  echo -e "\n>> ${BOLD}${1} GPU Preference for Specified Application(s)${NORMAL}\n"
  echo -e "Acronyms must be ${BOLD}all uppercase${NORMAL}.\nPartial names will return a list of possible applications.\nType ${BOLD}'QUIT'${NORMAL} to exit this submenu.\n"
  MESSAGE="$(echo -e "${1}" | awk '{ print tolower($0) }')"
  IFS= read -p "${BOLD}Application${NORMAL} Name or Acronym: " INPUT
  [[ -z "${INPUT}" ]] && echo -e "\nEmpty input provided. No action taken.\n" && return
  [[ "${INPUT}" == "quit" ]] && echo && return
  GENERALIZED_APP_NAME=""
  shopt -u nocasematch
  if [[ ! "${INPUT}" =~ [a-z] && ! "${INPUT}" =~ " " ]]
  then
    GENERALIZED_APP_NAME="$(echo -e "${INPUT}" | sed -e 's/\(.\)/\1*/g')"
  else
    GENERALIZED_APP_NAME="*${INPUT// /*}*"
  fi
  shopt -s nocasematch
  GENERALIZED_APP_NAME="${GENERALIZED_APP_NAME}.app"
  APP_COUNT=0
  while read APP
  do
    [[ "${APP}" =~ "${UTILITIES}" ]] && continue
    [[ $APP_COUNT == 0 ]] && echo -e "\n${BOLD}Possible Matches${NORMAL}:"
    APP_NAME="${APP##*/}"
    APP_NAME="${APP_NAME%.*}"
    APPS_LIST+=("${APP}")
    (( APP_COUNT++ ))
    printf "${BOLD}%-3d${NORMAL}:  %-s\n" "${APP_COUNT}" "${APP_NAME}"
  done < <(find "/Applications" "${HOME}/Applications" "${HOME}/Library" \( -iname "*.app" -prune \) -iname "${GENERALIZED_APP_NAME}")
  echo
  case $APP_COUNT in
    0)
    echo -e "No matches found for this application.\n";;
    1)
    manage_pref_for_found_app "${APPS_LIST[0]}" "${1}" "${2}";;
    *)
    request_specific_app "${1}" "${2}";;
  esac
  APPS_LIST=()
}

# Check preferences for specified application
check_app_preferences() {
  echo -e "\n>> ${BOLD}Check Application eGPU Preference${NORMAL}\n"
  IFS= read -p "${BOLD}Application${NORMAL} Name or Acronym: " INPUT
  [[ -z "${INPUT}" ]] && echo -e "\nPlease enter an application name.\n" && return
  GENERALIZED_APP_NAME=""
  shopt -u nocasematch
  if [[ ! "${INPUT}" =~ [a-z] && ! "${INPUT}" =~ " " ]]
  then
    GENERALIZED_APP_NAME="$(echo -e "${INPUT}" | sed -e 's/\(.\)/\1*/g')"
  else
    GENERALIZED_APP_NAME="*${INPUT// /*}*"
  fi
  shopt -s nocasematch
  GENERALIZED_APP_NAME="${GENERALIZED_APP_NAME}.app"
  APP_COUNT=0
  while read APP
  do
    [[ "${APP}" =~ "${UTILITIES}" ]] && continue
    [[ $APP_COUNT == 0 ]] && echo
    (( APP_COUNT++ ))
    BUNDLE_ID=$(osascript -e "id of app \"${APP}\"" 2>/dev/null)
    [[ -z "${BUNDLE_ID}" ]] && echo -e "\nTarget application does not exist. No action taken.\n" && return
    APP_NAME="${APP##*/}"
    APP_NAME="${APP_NAME%.*}"
    CURRENT_PREF=""
    [[ $IS_HIGH_SIERRA == 1 ]] && CURRENT_PREF="$(defaults read "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 2>/dev/null)" || CURRENT_PREF="$(SafeEjectGPU evalPref ${BUNDLE_ID} ${GPU_SELECTION_POLICY_KEY} 2>/dev/null)"
    [[ "${CURRENT_PREF}" == "${GPU_SELECTION_POLICY_KEY}=<not set>" || -z "${CURRENT_PREF}" ]] && CURRENT_PREF="does not prefer eGPUs."
    [[ "${CURRENT_PREF}" == "${GPU_SELECTION_POLICY_KEY}=${GPU_SELECTION_POLICY_VALUE}" || "${CURRENT_PREF}" == "${GPU_SELECTION_POLICY_VALUE}" ]] && CURRENT_PREF="prefers external GPUs."
    echo -e "${BOLD}${APP_NAME}${NORMAL} ${CURRENT_PREF}"
  done < <(find "/Applications" "${HOME}/Applications" "${HOME}/Library" \( -iname "*.app" -prune \) -iname "${GENERALIZED_APP_NAME}")
  echo
  (( APP_COUNT == 0 )) && echo -e "No matching applications found for your search.\n"
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
  echo -e "
   ${BOLD}1.${NORMAL}  Set eGPU Preference for All Applications
   ${BOLD}2.${NORMAL}  Set eGPU Preference for Specified Application(s)
   ${BOLD}3.${NORMAL}  Check Application eGPU Preference
   ${BOLD}4.${NORMAL}  Reset GPU Preferences for All Applications
   ${BOLD}5.${NORMAL}  Reset GPU Preferences for Specified Application(s)
   ${BOLD}6.${NORMAL}  Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-6]: " INPUT
  if [[ ! -z "${INPUT}" ]]
  then
    process_args "${INPUT}"
  else
    echo -e "\nNo input provided.\n"
  fi
  ask_menu
}

# Process arguments
process_args() {
  case "${1}" in
    -sa|--set-all|1)
    manage_all_apps_egpu "Set" "set_app_pref";;
    -ss|--set-specified|2)
    manage_specified_apps_egpu "Set" "set_app_pref";;
    -c|--check|3)
    check_app_preferences;;
    -ra|--reset-all|4)
    manage_all_apps_egpu "Reset" "reset_app_pref";;
    -rs|--reset-specified|5)
    manage_specified_apps_egpu "Reset" "reset_app_pref";;
    6)
    echo && exit;;
    "")
    start_install
    clear && echo -e ">> ${BOLD}Set-eGPU (${SCRIPT_VER})${NORMAL}"
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
