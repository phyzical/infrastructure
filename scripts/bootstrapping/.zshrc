source ~/.profile
export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
NEWLINE=$'\n'

setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats \
    '%F{5}[%F{183}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}[%F{183}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'

zstyle ':vcs_info:*' enable git cvs svn

vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}
DIRPS1="%~"
if [[ "$AWS_VAULT" != "" ]]
then
  AWSPS1="%F{red}aws=$AWS_VAULT%f"
fi
EXTRASPS1="${NEWLINE}${AWSPS1}${NEWLINE}"
PROMPTPS1="%(!.%F{red}.)%#%f"
USERPS1="%n@%m"
DATEPS1="%* - %D"
GITPS1=$'$(vcs_info_wrapper)'

PS1="${NEWLINE}%F{yellow}${DATEPS1}%f %F{green}${USERPS1}%f${NEWLINE}%F{cyan}${DIRPS1}%f ${GITPS1}${EXTRASPS1}${PROMPTPS1} "
# completion
autoload -U compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
compinit
zstyle ':completion:*:*:make:*' tag-order 'targets'

COMPOSE_HTTP_TIMEOUT=300
eval "$(rbenv init - zsh)"
eval "$(direnv hook zsh)"
ulimit -Sn 10240
