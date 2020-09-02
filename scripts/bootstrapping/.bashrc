[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
GITPS1="\$(__git_ps1 \"(%s)\")"
if [[ "$AWS_VAULT" != "" ]]
then
  AWSPS1="\naws=$AWS_VAULT\n"
fi

EXTRAPS1="${AWSPS1}"

PS1="\n${GITPS1}\n[\t][\u@\h:\w]${EXTRASPS1}\n\$ "
SHELL=/bin/bash

source ~/.profile