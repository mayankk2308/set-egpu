#!/usr/bin/env bash

# set-eGPU.sh
# Author(s): Mayank Kumar (@mac_editor, egpu.io / @mayankk2308, github.com)
# Version: 2.0.4

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
SCRIPT_MAJOR_VER="2" && SCRIPT_MINOR_VER="0" && SCRIPT_PATCH_VER="4"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"
IS_HIGH_SIERRA=0
PREF_SET_ERROR=0
PREF_RETURN=0
MISSED_APP=0
NO_APPS=0

# User input
INPUT=""

# Text management
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

# System information
MACOS_VER="$(sw_vers -productVersion)"
MACOS_BUILD="$(sw_vers -buildVersion)"

# GPU Policy
GPU_SELECTION_POLICY_KEY="GPUSelectionPolicy"
GPU_SELECTION_POLICY_VALUE="preferRemovable"
GPU_EJECT_POLICY_KEY="GPUEjectPolicy"
GPU_EJECT_POLICY_VALUE="relaunch"

# PlistBuddy
PlistBuddy="/usr/libexec/PlistBuddy"

# Exempt App Location(s)
UTILITIES="/Applications/Utilities"

# Found application(s) history
APPS_LIST=()
SEARCH_PATHS=("/Applications/" "${HOME}/Applications/" "${HOME}/Library/Application Support/")
PlistBuddy="/usr/libexec/PlistBuddy"

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
  curl -q -L -s "${LATEST_RELEASE_DWLD}" > "${TMP_SCRIPT}"
  [[ "$(cat "${TMP_SCRIPT}")" == "Not Found" ]] && echo -e "Download failed.\n${BOLD}Continuing without updating...${NORMAL}" && sleep 1 && rm "${TMP_SCRIPT}" && return
  echo -e "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo -e "Update complete. ${BOLD}Relaunching...${NORMAL}"
  sleep 1
  "${SCRIPT}" "${OPTION}"
  exit
}

# Prompt for update
prompt_software_update() {
  echo
  read -n1 -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n\n${BOLD}Proceeding without updating...${NORMAL}" && sleep 1 && return
  echo -e "\nInvalid choice. Try again."
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -q -s "https://api.github.com/repos/mayankk2308/set-egpu/releases/latest")"
  LATEST_RELEASE_VER="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo -e "\n>> ${BOLD}Software Update${NORMAL}\n\nSoftware updates are available.\n\nOn Your System    ${BOLD}${SCRIPT_VER}${NORMAL}\nLatest Available  ${BOLD}${LATEST_RELEASE_VER}${NORMAL}\n\nFor the best experience, stick to the latest release."
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
  [[ "$1" == "bash" && ! "$2" ]] && echo -e "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit
  [[ "$1" != "$SCRIPT" ]] && OPTION="$3" || OPTION="$2"
  [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "set-eGPU" ]] && BIN_CALL=1
}

# Check eGPU presence for Mojave+
check_egpu_presence() {
  (( ${IS_HIGH_SIERRA} == 1 )) && return
  EGPU_VENDOR="$(ioreg -n display@0 | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4 | sed -E 's/^(.{2})(.{2}).*$/\2\1/')"
  [[ -z "${EGPU_VENDOR}" ]] && echo -e "\nExternal GPU must be plugged in for ${BOLD}set-eGPU${NORMAL} on macOS 10.14+.\n" && exit
}

# macOS Version check
check_compatibility() {
  MACOS_MAJOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo -e "\nOnly ${BOLD}macOS 10.13.4 or later${NORMAL} compatible.\n" && exit
  (( ${MACOS_MAJOR_VER} == 13 )) && IS_HIGH_SIERRA=1
}

# ----- APPLICATION PREFERENCES MANAGER

# Mojave+ preference toggle
toggle_gpu_pref() {
  local APP="${1}"
  local TOGGLE="${2}"
  PREF_SET_ERROR=$(osascript -e "
  set appFile to (POSIX file \"${APP}\") as alias
  try
    tell application \"Finder\" to open information window of appFile
    tell application \"System Events\" to tell process \"Finder\"
      set eGPUBox to checkbox \"Prefer External GPU\" of scroll area 1 of window 1
      set status to value of eGPUBox as boolean
      if status is ${TOGGLE} then click eGPUBox
      tell application \"Finder\" to close information window of appFile
      return 0
    end tell
  on error errMsg
    tell application \"Finder\" to close information window of appFile
    return 1
  end try
  ")
}

# Mojave+ preference retrieval
retrieve_gpu_pref() {
  local APP="${1}"
  PREF_RETURN=$(osascript -e "
  set appFile to (POSIX file \"${APP}\") as alias
  try
    tell application \"Finder\" to open information window of appFile
    tell application \"System Events\" to tell process \"Finder\"
      set eGPUBox to checkbox \"Prefer External GPU\" of scroll area 1 of window 1
      set status to value of eGPUBox as boolean
      tell application \"Finder\" to close information window of appFile
      return status
    end tell
  on error errMsg
    tell application \"Finder\" to close information window of appFile
    return 0
  end try
  ")
}

# Generalized set mechanism
set_app_pref() {
  local FULL_APP_PATH="${1}"
  if (( ${IS_HIGH_SIERRA} == 1 ))
  then
    BUNDLE_ID="$(osascript -e "id of app \"${FULL_APP_PATH}\"")"
    defaults write "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" "${GPU_SELECTION_POLICY_VALUE}" 1>/dev/null 2>&1
    defaults write "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" "${GPU_EJECT_POLICY_VALUE}" 1>/dev/null 2>&1
    return
  fi
  toggle_gpu_pref "${FULL_APP_PATH}" false
}

# Generalized reset mechanism
reset_app_pref() {
  local FULL_APP_PATH="${1}"
  if (( ${IS_HIGH_SIERRA} == 1 ))
  then
    BUNDLE_ID="$(osascript -e "id of app \"${FULL_APP_PATH}\"")"
    defaults delete "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 1>/dev/null 2>&1
    defaults delete "${BUNDLE_ID}" "${GPU_EJECT_POLICY_KEY}" 1>/dev/null 2>&1
    return
  fi
  toggle_gpu_pref "${FULL_APP_PATH}" true
}

# Generic preference management for apps in given folder
manage_all_apps_prefs_in_folder() {
  COUNT=0
  [[ ! -d "${1}" ]] && return
  while read APP
  do
    [[ -z "${APP}" || "${APP}" =~ "${UTILITIES}" ]] && continue
    "${2}" "${APP}"
    (( ${PREF_SET_ERROR} == 1 )) && MISSED_APP=1
    (( COUNT++ ))
    (( $COUNT % 5 == 0 )) && echo -en "◼"
  done < <(find "${1}" -type d -name "*.app" -prune 2>/dev/null)
  (( COUNT == 0 )) && NO_APPS=1
}

# Manage preferences for all applications at target
manage_all_apps_egpu_target() {
  MISSED_APP=0
  NO_APPS=0
  TARGET=""
  echo -e "\n>> ${BOLD}${1} GPU Preferences for All Applications At Target${NORMAL}\n\nProvide a full path to a directory to update preferences for all\napplications in that directory. Example: ${BOLD}/Volumes/MyExternalDrive${NORMAL}\n"
  read -p "${BOLD}Path${NORMAL}: " TARGET
  [[ ! -d "${TARGET}" ]] && echo -e "\nInvalid input or not a directory.\n" && return
  echo -e "\n${BOLD}${1}ting...${NORMAL}"
  MESSAGE="$(echo -e "${1}" | awk '{ print tolower($0) }')"
  manage_all_apps_prefs_in_folder "${TARGET}" "${2}"
  (( ${MISSED_APP} == 1 )) && echo -e "\r\033[KDone. Some preferences unchanged.\n\nPlease ensure ${BOLD}Terminal${NORMAL} was granted access to control macOS\nand your external GPU was plugged in. Additionally, some\napps such as ${BOLD}Photos${NORMAL} do not have this option.\n" && return
  (( ${NO_APPS} == 1 )) && echo -e "\r\033[KNo applications found.\n" && return
  echo -e "\r\033[KPreferences ${MESSAGE}.\n"
}

# Manage preferences for all applications
manage_all_apps_egpu() {
  MISSED_APP=0
  echo -e "\n>> ${BOLD}${1} GPU Preferences for All Applications${NORMAL}\n\n${BOLD}${1}ting...${NORMAL}"
  MESSAGE="$(echo -e "${1}" | awk '{ print tolower($0) }')"
  for SEARCH_PATH in "${SEARCH_PATHS[@]}"
  do
    manage_all_apps_prefs_in_folder "${SEARCH_PATH}" "${2}"
  done
  (( ${MISSED_APP} == 1 )) && echo -e "\r\033[KDone. Some preferences unchanged.\n\nPlease ensure ${BOLD}Terminal${NORMAL} was granted access to control macOS\nand your external GPU was plugged in. Additionally, some\napps such as ${BOLD}Photos${NORMAL} do not have this option.\n" || echo -e "\r\033[KPreferences ${MESSAGE}.\n"
}

manage_pref_for_found_app() {
  local APP_PATH="${1}"
  local INTENT="${2}"
  MESSAGE="$(echo -e "${INTENT}" | awk '{ print tolower($0) }')"
  local FUNCTION="${3}"
  local APP_PRINT_NAME="${APP_PATH##*/}"
  local APP_PRINT_NAME="${APP_PRINT_NAME%.*}"
  echo -e "\n${BOLD}${INTENT}ting preference for ${APP_PRINT_NAME}...${NORMAL}"
  "${FUNCTION}" "${1}"
  (( ${PREF_SET_ERROR} == 1 )) && echo -e "\r\033[KPreferences unchanged.\n\nPlease ensure ${BOLD}Terminal${NORMAL} was granted access to control macOS\nand your external GPU was plugged in. Additionally, some\napps such as ${BOLD}Photos${NORMAL} do not have this option.\n" || echo -e "Preferences ${MESSAGE}.\n"
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
  echo -e "Only ${BOLD}uppercase${NORMAL} input are treated as acronyms (ex. '${BOLD}FCP${NORMAL}').\nPartial names return a list of possible applications (ex. '${BOLD}adobe${NORMAL}').\nType ${BOLD}'QUIT'${NORMAL} to exit this submenu.\n"
  MESSAGE="$(echo -e "${1}" | awk '{ print tolower($0) }')"
  IFS= read -p "${BOLD}Application${NORMAL} Name or Acronym: " INPUT
  [[ -z "${INPUT}" ]] && echo -e "\nEmpty input provided. No action taken.\n" && return
  [[ "${INPUT}" == "quit" ]] && echo && return
  echo -e "\n${BOLD}Searching for possible matches...${NORMAL}"
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
  for SEARCH_PATH in "${SEARCH_PATHS[@]}"
  do
    while read APP
    do
      [[ "${APP}" =~ "${UTILITIES}" ]] && continue
      [[ $APP_COUNT == 0 ]] && echo -e "\n${BOLD}Possible Matches${NORMAL}:"
      APP_NAME="${APP##*/}"
      APP_NAME="${APP_NAME%.*}"
      APPS_LIST+=("${APP}")
      (( APP_COUNT++ ))
      printf "${BOLD}%-3d${NORMAL}:  %-s\n" "${APP_COUNT}" "${APP_NAME}"
    done < <(find "${SEARCH_PATH}" \( -iname "*.app" -prune \) -iname "${GENERALIZED_APP_NAME}" 2>/dev/null)
  done
  case ${APP_COUNT} in
    0)
    echo -e "No matches found for your search.\n";;
    1)
    echo -e "\nSearch complete."
    manage_pref_for_found_app "${APPS_LIST[0]}" "${1}" "${2}";;
    *)
    echo -e "\nSearch complete."
    request_specific_app "${1}" "${2}";;
  esac
  APPS_LIST=()
}

print_current_preferences() {
  PREF_RETURN=0
  local FULL_APP_PATH="${1}"
  local APP_NAME="${2}"
  local CURRENT_PREF="Not Supported/Undetermined"
  if (( ${IS_HIGH_SIERRA} == 1 ))
  then
    BUNDLE_ID="$(osascript -e "id of app \"${FULL_APP_PATH}\"")"
    local CURRENT_PREF="$(defaults read "${BUNDLE_ID}" "${GPU_SELECTION_POLICY_KEY}" 2>&1)"
    [[ "${CURRENT_PREF}" == "${GPU_SELECTION_POLICY_VALUE}" ]] && CURRENT_PREF="Prefers eGPU" || CURRENT_PREF="Not Set"
    echo -e "${BOLD}${APP_NAME}${NORMAL}: ${CURRENT_PREF}"
    return
  fi
  retrieve_gpu_pref "${FULL_APP_PATH}"
  [[ "${PREF_RETURN}" == "true" ]] && CURRENT_PREF="Prefers eGPU"
  [[ "${PREF_RETURN}" == "false" ]] && CURRENT_PREF="Not Set"
  echo -e "${BOLD}${APP_NAME}${NORMAL}: ${CURRENT_PREF}"
}

# Check preferences for specified application
check_app_preferences() {
  echo -e "\n>> ${BOLD}Check Application eGPU Preference${NORMAL}\n"
  echo -e "Only ${BOLD}uppercase${NORMAL} input are treated as acronyms (ex. '${BOLD}FCP${NORMAL}').\nPartial names return a list of possible applications (ex. '${BOLD}adobe${NORMAL}').\nType ${BOLD}'QUIT'${NORMAL} to exit this submenu.\n"
  IFS= read -p "${BOLD}Application${NORMAL} Name or Acronym: " INPUT
  [[ -z "${INPUT}" ]] && echo -e "\nPlease enter an application name.\n" && return
  [[ "${INPUT}" == "quit" ]] && echo && return
  GENERALIZED_APP_NAME=""
  echo -e "\n${BOLD}Searching for possible matches...${NORMAL}"
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
  for SEARCH_PATH in "${SEARCH_PATHS[@]}"
  do
    while read APP
    do
      [[ "${APP}" =~ "${UTILITIES}" ]] && continue
      [[ $APP_COUNT == 0 ]] && echo
      (( APP_COUNT++ ))
      APP_NAME="${APP##*/}"
      APP_NAME="${APP_NAME%.*}"
      print_current_preferences "${APP}" "${APP_NAME}"
    done < <(find "${SEARCH_PATH}" \( -iname "*.app" -prune \) -iname "${GENERALIZED_APP_NAME}" 2>/dev/null)
  done
  (( APP_COUNT == 0 )) && echo -e "No matches found for your search.\n" || echo -e "\nSearch complete.\n"
}

# Uninstall Set-eGPU
uninstall() {
  echo -e "\n>> ${BOLD}Uninstall Set-eGPU${NORMAL}\n"
  echo -e "This process will ${BOLD}reset preferences for all applications${NORMAL},\nand ${BOLD}remove set-eGPU${NORMAL} from your system if present.\n"
  read -n1 -p "${BOLD}Proceed?${NORMAL} [Y/N]: " INPUT
  if [[ ! -z "${INPUT}" ]]
  then
    echo
    manage_all_apps_egpu "Reset" "reset_app_pref"
    [[ -e "${SCRIPT_BIN}" ]] && rm "${SCRIPT_BIN}" && echo -e "Removal successful.\n" && exit
  else
    echo -e "\nAborting.\n"
  fi
}

# ----- DRIVER

# Request donation
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20Set-eGPU&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest"
  echo -e "\nSee your ${BOLD}web browser${NORMAL}.\n"
}

# Ask for main menu
ask_menu() {
  read -n1 -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && clear && echo -e "\n>> ${BOLD}Set-eGPU (${SCRIPT_VER})${NORMAL}" && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n" && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo -e "
  >> ${BOLD}Prefer eGPU${NORMAL}                 >> ${BOLD}Reset Preferences
  ${BOLD}1.${NORMAL} All Applications            ${BOLD}4.${NORMAL} All Applications
  ${BOLD}2.${NORMAL} All Applications At Target  ${BOLD}5.${NORMAL} All Applications At Target
  ${BOLD}3.${NORMAL} Specified Application(s)    ${BOLD}6.${NORMAL} Specified Application(s)

  ${BOLD}7.${NORMAL} Check eGPU Preferences
  ${BOLD}8.${NORMAL} Uninstall Set-eGPU
  ${BOLD}9.${NORMAL} Donate

  ${BOLD}0.${NORMAL} Quit
  "
  read -n1 -p "${BOLD}What next?${NORMAL} [0-8]: " INPUT
  echo
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
  PREF_SET_ERROR=0
  check_egpu_presence
  case "${1}" in
    -sa|--set-all|1)
    manage_all_apps_egpu "Set" "set_app_pref";;
    -st|--set-target|2)
    manage_all_apps_egpu_target "Set" "set_app_pref";;
    -ss|--set-specified|3)
    manage_specified_apps_egpu "Set" "set_app_pref";;
    -ra|--reset-all|4)
    manage_all_apps_egpu "Reset" "reset_app_pref";;
    -rt|--reset-target|5)
    manage_all_apps_egpu_target "Reset" "reset_app_pref";;
    -rs|--reset-specified|6)
    manage_specified_apps_egpu "Reset" "reset_app_pref";;
    -c|--check|7)
    check_app_preferences;;
    -u|--uninstall|8)
    uninstall;;
    -d|--donate|9)
    donate;;
    0)
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
  check_egpu_presence
  process_args "${2}"
}

begin "${0}" "${1}"
