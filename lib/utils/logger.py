"""Cross-platform colored logger for Python scripts."""
import sys, platform

_WIN = platform.system() == "Windows"
_COLORS = not _WIN or "WT_SESSION" in __import__("os").environ

def _c(code):
    return f"\033[{code}m" if _COLORS else ""

RESET=_c("0"); BOLD=_c("1"); RED=_c("31"); GREEN=_c("32")
YELLOW=_c("33"); BLUE=_c("34"); CYAN=_c("36"); DIM=_c("2")

def info(msg):    print(f"{BLUE}ℹ{RESET}  {msg}")
def success(msg): print(f"{GREEN}✓{RESET}  {msg}")
def warn(msg):    print(f"{YELLOW}⚠{RESET}  {msg}")
def error(msg):   print(f"{RED}✗{RESET}  {msg}", file=sys.stderr)
def step(msg):    print(f"{BOLD}→{RESET}  {msg}")
def header(msg):  print(f"\n{BOLD}{CYAN}{'═'*60}{RESET}\n{BOLD}{CYAN}  {msg}{RESET}\n{BOLD}{CYAN}{'═'*60}{RESET}")
def dim(msg):     print(f"{DIM}{msg}{RESET}")
