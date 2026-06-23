#!/usr/bin/env bash
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"
BLUE="\033[0;34m"; CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"
info()    { echo -e "${BLUE}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}\n${BOLD}${CYAN}  $*${RESET}\n${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}"; }
step()    { echo -e "${BOLD}→${RESET}  $*"; }
