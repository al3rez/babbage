# Minimal, fast bash prompt (no external tools needed).
#   ~/c/project  main*  venv  ✘1  4s
#   ❯
__p_c() { printf '\[\e[%sm\]' "$1"; }
__P_RESET=$(__p_c 0) __P_DIR=$(__p_c '1;34') __P_GIT=$(__p_c '35') __P_DIM=$(__p_c '2')
__P_OK=$(__p_c '1;32') __P_ERR=$(__p_c '1;31') __P_HOST=$(__p_c '33') __P_VENV=$(__p_c '36')

__p_git() {  # branch from .git/HEAD by walking up; dirty marker only if git exists
  local d=$PWD head
  while [ -n "$d" ]; do
    if [ -f "$d/.git/HEAD" ]; then head=$(<"$d/.git/HEAD"); break
    elif [ -f "$d/.git" ]; then local g; g=$(<"$d/.git"); g=${g#gitdir: }
      [[ $g != /* ]] && g="$d/$g"; [ -f "$g/HEAD" ] && head=$(<"$g/HEAD"); break
    fi
    d=${d%/*}
  done
  [ -z "$head" ] && return
  local b=${head#ref: refs/heads/}; [ "$b" = "$head" ] && b=${head:0:7}
  local dirty=""
  command -v git >/dev/null && [ -n "$(git status --porcelain -uno 2>/dev/null | head -1)" ] && dirty="*"
  printf '  %s%s%s%s' "$__P_GIT" "$b" "$dirty" "$__P_RESET"
}

__p_dir() {
  local p=${PWD/#$HOME/\~}
  IFS=/ read -ra parts <<<"$p"
  if [ ${#parts[@]} -gt 4 ]; then p="…/${parts[-3]}/${parts[-2]}/${parts[-1]}"; fi
  printf '%s' "$p"
}

__p_timer_start() { : "${__P_T0:=$SECONDS}"; }
trap '__p_timer_start' DEBUG

__p_build() {
  local code=$? dur=$(( SECONDS - ${__P_T0:-$SECONDS} )); unset __P_T0
  local line="" host=""
  [ -n "$SSH_CONNECTION" ] && host="${__P_HOST}\u@\h${__P_RESET} "
  line+="${host}${__P_DIR}$(__p_dir)${__P_RESET}$(__p_git)"
  [ -n "$VIRTUAL_ENV" ] && line+="  ${__P_VENV}${VIRTUAL_ENV##*/}${__P_RESET}"
  [ $code -ne 0 ] && line+="  ${__P_ERR}✘${code}${__P_RESET}"
  [ $dur -ge 3 ] && line+="  ${__P_DIM}${dur}s${__P_RESET}"
  local arrow=$__P_OK; [ $code -ne 0 ] && arrow=$__P_ERR
  PS1="\[\e]0;\W\a\]\n${line}\n${arrow}❯${__P_RESET} "
}
VIRTUAL_ENV_DISABLE_PROMPT=1
PROMPT_COMMAND="__p_build${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
