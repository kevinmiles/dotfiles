# vim: foldmethod=marker

source ~/.profile

fpath=("$HOME/.zshrc.d/autocomplete" "$fpath[@]")

# Prompt {{{
PROMPT='$(/Users/burke/bin/shell-prompt "$?" "${__shadowenv_data%%:*}")'
setopt prompt_subst
# }}}
# GPG Agent {{{
gpg-agent --daemon >/dev/null 2>&1
function kick-gpg-agent {
  pid=$(ps xo pid,command | grep -E "^\d+ gpg-agent" | awk '{print $1}')
  export GPG_AGENT_INFO=$HOME/.gnupg/S.gpg-agent:${pid}:1
}
kick-gpg-agent
export GPG_TTY=$(tty)
# }}}
# Generic Configuration {{{
eval $(
  cat ~/.config/shell/aliases \
    | grep -v '^#' \
    | grep -vE '^\s*$' \
    | sed 's/\$/\\$/' \
    | sed 's/"/\\"/g' \
    | sed 's/^\([^ :]*\)[[:space:]]*:[[:space:]]*\(.*\)/alias \1="\2";/'
)

while read line; do
  eval "function ${line}() { cd \"\$(_${line} \"\$@\")\"; }"
done < ~/.config/shell/cd-wrappers

function ghs() {
  dev clone $1
}

if [[ "${TERM_BG}" == "light" ]]; then
  eval $(gdircolors -b ~/.config/shell/dircolors.ansi-light)
else
  eval $(gdircolors -b ~/.config/shell/LS_COLORS)
fi

# }}}
# ZSH options and features {{{
# If a command is issued that can’t be executed as a normal command, and the
# command is the name of a directory, perform the cd command to that directory.
setopt AUTO_CD

# Treat  the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename
# generation, etc.  (An initial unquoted ‘~’ always produces named directory
# expansion.)
setopt EXTENDED_GLOB

# If a pattern for filename generation has no matches, print an error, instead
# of leaving it unchanged in the argument  list. This also applies to file
# expansion of an initial ‘~’ or ‘=’.
setopt NOMATCH

# no Beep on error in ZLE.
setopt NO_BEEP

# Remove any right prompt from display when accepting a command line. This may
# be useful with terminals with other cut/paste methods.
setopt TRANSIENT_RPROMPT

# If unset, the cursor is set to the end of the word if completion is started.
# Otherwise it stays there and completion is done from both ends.
setopt COMPLETE_IN_WORD

setopt auto_pushd
setopt append_history

unsetopt MULTIOS

autoload -U compinit promptinit zcalc zsh-mime-setup
compinit
promptinit
zsh-mime-setup
autoload colors
colors
autoload -Uz zmv # move function
autoload -Uz zed # edit functions within zle
zle_highlight=(isearch:underline)

# Enable ..<TAB> -> ../
zstyle ':completion:*' special-dirs true

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,comm'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

typeset WORDCHARS="*?_-.~[]=&;!#$%^(){}<>"

HISTFILE=~/.zsh_history
SAVEHIST=50000
HISTSIZE=50000
# }}}
# Vim mode {{{
# Ensures that $terminfo values are valid and updates editor information when
# the keymap changes.
function zle-keymap-select zle-line-init zle-line-finish {
  # The terminal must be in application mode when ZLE is active for $terminfo
  # values to be valid.
  if (( ${+terminfo[smkx]} )); then
    printf '%s' ${terminfo[smkx]}
  fi
  if (( ${+terminfo[rmkx]} )); then
    printf '%s' ${terminfo[rmkx]}
  fi

  zle reset-prompt
  zle -R
}

TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

# These two don't really appear to be necessary.
#zle -N zle-line-init
#zle -N zle-line-finish
zle -N zle-keymap-select
zle -N edit-command-line

bindkey -v

# allow v to edit the command line (standard behaviour)
autoload -Uz edit-command-line
bindkey -M vicmd 'v' edit-command-line

# allow ctrl-p, ctrl-n for navigate history (standard behaviour)
bindkey '^P' up-history
bindkey '^N' down-history

# allow ctrl-h, ctrl-w, ctrl-? for char and word deletion (standard behaviour)
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

bindkey -s -M vicmd H '0'
bindkey -s -M vicmd L '$'
bindkey kj vi-cmd-mode

# slow enough for me to hit "kj", but fast enough that the delay on <esc> isn't jarring.
export KEYTIMEOUT=15

bindkey '^f' vi-forward-char
bindkey '^b' vi-backward-char
bindkey '^p' up-history
bindkey '^n' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey '^k' kill-line
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
# }}}

function git() {
  local toplevel=$(command git rev-parse --show-toplevel 2>/dev/null)
  if [[ "${toplevel}" == "${HOME}" ]] && [[ "$1" == "clean" ]]; then
    >&2 echo "Do NOT run git clean in this repository."
    return
  fi
  command git "$@"
}

function ]g() {
  dev cd "$@"
}

function ]gs() {
  dev cd "$@"
}

function ]gb() {
  dev cd "burke/$@"
}

function z() {
  local srcpath
  srcpath="$(
    awk -F ' *= *' '
      $1 == "[srcpath]" { sp = "yes" }
      sp && $1 == "default" { print $2; exit }
    ' < ~/.config/dev
  )"
  dev cd ${srcpath}/$(ls ${srcpath} | fzf --select-1 --query "$@")
}

function gogopr() {
  git add -A .
  git commit -a -m "$*"
  git push origin "$(git branch | grep '*' | awk '{print $2}')"
  dev open pr
}

zle-dev-open-pr() /opt/dev/bin/dev open pr
zle -N zle-dev-open-pr
bindkey 'ø' zle-dev-open-pr # Alt-O ABC Extended
bindkey 'ʼ' zle-dev-open-pr # Alt-O Canadian English

zle-dev-open-github() /opt/dev/bin/dev open github
zle -N zle-dev-open-github
bindkey '©' zle-dev-open-github # Alt-G ABC Extended & Canadian English

zle-dev-open-shipit() /opt/dev/bin/dev open shipit
zle -N zle-dev-open-shipit
bindkey 'ß' zle-dev-open-shipit # Alt-S ABC Extended & Canadian English

zle-dev-open-app() /opt/dev/bin/dev open app
zle -N zle-dev-open-app
bindkey '®' zle-dev-open-app # Alt-R ABC Extended & Canadian English

zle-dev-cd(){ dev cd ${${(z)BUFFER}}; zle .beginning-of-line; zle .kill-line; zle .accept-line }
zle -N zle-dev-cd
bindkey '∂' zle-dev-cd # Alt-D Canadian English

zle-dev-cd() {
  dev cd "${${(z)BUFFER}}"
  zle .beginning-of-line
  zle .kill-line
  zle .accept-line
}
zle -N zle-dev-cd
bindkey '∂' zle-dev-cd # Alt-D Canadian English

zle-checkout-branch() {
  local branch
  branch="$(git branch -l | fzf -f "${${(z)BUFFER}}" | awk '{print $1; exit}')" 
  git checkout "${branch}" >/dev/null 2>&1
  zle .beginning-of-line
  zle .kill-line
  zle .accept-line
}
zle -N zle-checkout-branch
bindkey '∫' zle-checkout-branch # Alt-B Canadian English

if [[ "${TERM_BG}" == "light" ]]; then
  export TASKRC=~/.config/task/taskrc-light
  export FZF_DEFAULT_OPTS="--color=light"
else
  export TASKRC=~/.config/task/taskrc-dark
fi

source ~/.zshrc.d/zsh-autosuggestions/zsh-autosuggestions.zsh
# if [[ "${TERM_BG}" == "light" ]]; then
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=3'
# fi


source ~/.zshrc.d/zk.zsh

source ~/.zshrc.d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/dev/dev.sh
