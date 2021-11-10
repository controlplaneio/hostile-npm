#!/usr/bin/env bash
#
# Steal everything
#
# Andrew Martin, 2021-09-02 07:00:39
# sublimino@gmail.com
#
## Usage: %SCRIPT_NAME% [options] filename
##
## Options:
##   -d, --description [string]  Description
##
##   --config=file               Configuration file to override flags, formatted as options without prefixed hyphens
##   --debug                     Enable debug mode
##   -v, --version               Print version
##   -h, --help                  Display this message
##

# exit on error or pipe failure
set -eo pipefail
# propagate ERR traps to subshells
set -o errtrace
# error on unset variable
if test "${BASH}" = "" || "${BASH}" -uc 'a=();true "${a[@]}"' 2>/dev/null; then
  set -o nounset
fi
# error on clobber
set -o noclobber
# disable passglob
shopt -s nullglob globstar

_error_handler() {
  local ERR=$?
  set +o xtrace
  echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: '${BASH_COMMAND}' exited with status ${ERR} in ${FUNCNAME[1]}()"
  if [ ${#FUNCNAME[@]} -gt 2 ]; then
    echo "Call tree:"
    for ((i = 1; i < ${#FUNCNAME[@]} - 1; i++)); do
      echo " $i: ${BASH_SOURCE[$i + 1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
    done
  fi
  exit "${ERR}"
}
trap _error_handler ERR

# resolved directory and self
declare -r DIR=$(cd "$(dirname "${0}")" && pwd)
declare -r THIS_SCRIPT="${DIR}/$(basename "${0}")"

# user defaults
DESCRIPTION="Templating with Yeoman"
CONFIG_FILE=""
DEBUG=0
DRY_RUN=0

# required defaults
declare -a ARGUMENTS
EXPECTED_NUM_ARGUMENTS=0
ARGUMENTS=()
FILENAME=''
TEMP_FILE=

main() {
  handle_arguments "$@"

  trap cleanup EXIT

  success "Installing magiclatern keylogger -- ignored by some AV..."
  sleep 1.4
  success "done"

  success "Installing monero miner -- denial of wallet..."
  sleep 3.9
  success "done"


  success "Hoisting yo' credentials up the mainstay -- data exfiltration"
  for DIRECTORY in  ~/.ssh ~/.gnupg ~/.aws ~/.gconf; do
    echo "${DIRECTORY}"
    ls -lasp ${DIRECTORY} | head -n 10 | sed -E 's/(.{55}).*/\1.../g'
    echo
  done


  warning "So long and thanks for all the 🐠"

  exit 0
}

cleanup() {
  [[ -f "${TEMP_FILE}" ]] && rm -rf "${TEMP_FILE}"
  true
}

handle_arguments() {
  parse_arguments "${@:-}"
  parse_config_file "${@:-}"
  validate_arguments "${@:-}"
}

parse_arguments() {
  local CURRENT_ARG
  local NEXT_ARG
  local SPLIT_ARG
  local COUNT=0

  if [[ "${#}" == 1 && "${1:-}" == "" ]]; then
    return 0
  fi

  while [[ "${#}" -gt 0 ]]; do
    CURRENT_ARG="${1}"

    COUNT=$((COUNT + 1))
    if [[ "${COUNT}" -gt 100 ]]; then
      error "Too many arguments or '${CURRENT_ARG}' is unknown"
    fi

    IFS='=' read -ra SPLIT_ARG <<<"${CURRENT_ARG}"
    if [[ ${#SPLIT_ARG[@]} -gt 1 ]]; then
      CURRENT_ARG="${SPLIT_ARG[0]}"
      unset 'SPLIT_ARG[0]'
      NEXT_ARG="$(printf "%s=" "${SPLIT_ARG[@]}")"
      NEXT_ARG="${NEXT_ARG%?}"
    else
      shift
      NEXT_ARG="${1:-}"
    fi

    case ${CURRENT_ARG} in
    --description)
      not_empty_or_usage "${NEXT_ARG:-}"
      DESCRIPTION="${NEXT_ARG}"
      shift
      ;;
    # ---
    --config)
      not_empty_or_usage "${NEXT_ARG:-}"
      CONFIG_FILE="${NEXT_ARG}"
      shift
      ;;
    -h | --help) usage ;;
    -v | --version)
      get_version
      exit 0
      ;;
    --debug)
      DEBUG=1
      set -xe
      ;;
    --dry-run) DRY_RUN=1 ;;
    --)
      EXTENDED_ARGS="${@}"
      break
      ;;
    -*) usage "${CURRENT_ARG}: unknown option" ;;
    *) ARGUMENTS+=("${CURRENT_ARG}") ;;
    esac
  done
}

parse_config_file() {
  if [[ -n ${CONFIG_FILE:-} && -r ${CONFIG_FILE} ]]; then
    local PREVIOUS_ARGUMENTS="${@}"
    local ARGS_FROM_FILE
    local SPLIT_ARG
    local LINE

    while read -r LINE; do
      LINE="--${LINE}"
      IFS='=' read -ra SPLIT_ARG <<<"${LINE}"
      if ! grep -q -- "${SPLIT_ARG[0]}" <<<"${PREVIOUS_ARGUMENTS}" >/dev/null; then
        set -- "${LINE}"
        parse_arguments "${@}"
      fi
    done < <(cat "${CONFIG_FILE}")
  fi
}

validate_arguments() {
  FILENAME="${ARGUMENTS[0]:-}" || true

  #  [[ -z "${FILENAME:-}" ]] && usage "Filename required"

  check_number_of_expected_arguments
}

# helper functions

usage() {
  [ "${*}" ] && echo "${THIS_SCRIPT}: ${COLOUR_RED}${*}${COLOUR_RESET}" && echo
  sed -n '/^##/,/^$/s/^## \{0,1\}//p' "${THIS_SCRIPT}" | sed "s/%SCRIPT_NAME%/$(basename "${THIS_SCRIPT}")/g"
  exit 2
} 2>/dev/null

success() {
  [ "${*:-}" ] && RESPONSE="${*}" || RESPONSE="Unknown Success"
  printf "%s\\n" "$(log_message_prefix)${COLOUR_GREEN}${RESPONSE}${COLOUR_RESET}"
} 1>&2

info() {
  [ "${*:-}" ] && INFO="${*}" || INFO="Unknown Info"
  printf "%s\\n" "$(log_message_prefix)${COLOUR_WHITE}${INFO}${COLOUR_RESET}"
} 1>&2

warning() {
  [ "${*:-}" ] && ERROR="${*}" || ERROR="Unknown Warning"
  printf "%s\\n" "$(log_message_prefix)${COLOUR_RED}${ERROR}${COLOUR_RESET}"
} 1>&2

error() {
  [ "${*:-}" ] && ERROR="${*}" || ERROR="Unknown Error"
  printf "%s\\n" "$(log_message_prefix)${COLOUR_RED}${ERROR}${COLOUR_RESET}"
  exit 3
} 1>&2

error_env_var() {
  error "${1} environment variable required"
}

log_message_prefix() {
  local TIMESTAMP
  local THIS_SCRIPT_SHORT=${THIS_SCRIPT/${DIR}/.}
  TIMESTAMP="[$(date +'%Y-%m-%dT%H:%M:%S%z')]"
  tput bold 2>/dev/null
  echo -n "${TIMESTAMP} ${THIS_SCRIPT_SHORT}: "
}

is_empty() {
  [[ -z ${1-} ]] && return 0 || return 1
}

not_empty_or_error() {
  if is_empty "${1-}"; then
    warning "${2:-Non-empty value required}"
    if [[ "${3:-}" =~ ^[0-9]+$ ]]; then
      exit "${3}"
    fi
    exit 1
  fi
  return 0
}

not_empty_or_usage() {
  if is_empty "${1-}"; then
    shift
    usage "Non-empty value required ${@:-}"
  fi
  return 0
}

check_number_of_expected_arguments() {
  [[ "${EXPECTED_NUM_ARGUMENTS}" != "${#ARGUMENTS[@]}" ]] && {
    ARGUMENTS_STRING="argument"
    [[ "${EXPECTED_NUM_ARGUMENTS}" -gt 1 ]] && ARGUMENTS_STRING="${ARGUMENTS_STRING}"s
    usage "${EXPECTED_NUM_ARGUMENTS} ${ARGUMENTS_STRING} expected, ${#ARGUMENTS[@]} found"
  }
  return 0
}

hr() {
  printf '=%.0s' "$(seq "$(tput cols)")"
  echo
}

wait_safe() {
  local PIDS="${1}"
  for JOB in ${PIDS}; do
    wait "${JOB}"
  done
}

try() {
  try-limit 0 "${@}"
}

try-limit() {
  local LIMIT=$1
  local COUNT=1
  local RETURN_CODE
  shift
  local COMMAND="${@:-}"
  if [[ "${COMMAND}" == "" ]]; then
    echo "At least two arguments required (limit, command)" 1>&2
    return 1
  fi
  function _try-limit-output() {
    printf "\n$(date) (${COUNT}): %s - " "${COMMAND}" 1>&2
  }
  echo "Limit: ${LIMIT}. Trying command: ${COMMAND}"
  _try-limit-output
  local oldopt=$-
  set +E
  until echo "${COMMAND}" | source /dev/stdin; do
    RETURN_CODE=$?
    echo "Return code: ${RETURN_CODE}"
    if [[ "${LIMIT}" -gt 0 && "${COUNT}" -ge "${LIMIT}" ]]; then
      printf "\nFailed \`${COMMAND}\` after ${COUNT} iterations\n" 1>&2
      return 1
    fi
    COUNT=$((COUNT + 1))
    _try-limit-output
    if [[ "${_TRY_LIMIT_BACKOFF:-}" != "" ]]; then
      sleep $(((COUNT * _TRY_LIMIT_BACKOFF) / 10))
    else
      sleep ${_TRY_LIMIT_SLEEP:-0.3}
    fi
  done
  RETURN_CODE=$?
  if [[ "${COUNT}" == 1 ]]; then
    echo
  fi
  echo "Completed \`${COMMAND}\` after ${COUNT} iterations" 1>&2
  unset _TRY_LIMIT_SLEEP _TRY_LIMIT_BACKOFF
  set -$oldopt
  return ${RETURN_CODE}
}

export CLICOLOR=1
export TERM="xterm-color"
export COLOUR_BLACK=$(tput setaf 0 :-"" 2>/dev/null)
export COLOUR_RED=$(tput setaf 1 :-"" 2>/dev/null)
export COLOUR_GREEN=$(tput setaf 2 :-"" 2>/dev/null)
export COLOUR_YELLOW=$(tput setaf 3 :-"" 2>/dev/null)
export COLOUR_BLUE=$(tput setaf 4 :-"" 2>/dev/null)
export COLOUR_MAGENTA=$(tput setaf 5 :-"" 2>/dev/null)
export COLOUR_CYAN=$(tput setaf 6 :-"" 2>/dev/null)
export COLOUR_WHITE=$(tput setaf 7 :-"" 2>/dev/null)
export COLOUR_RESET=$(tput sgr0 :-"" 2>/dev/null)

main "${@}"
