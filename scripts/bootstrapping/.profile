export PATH=/opt/local/bin:/opt/local/sbin:$PATH
export PATH="$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH=~/Library/Python/2.7/bin/:$PATH
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
export PATH="$PATH:/Applications/MAMP/Library/bin"

eval $(thefuck --alias)

#random alias
alias PUBLICIP="dig +short myip.opendns.com @resolver1.opendns.com"
alias LOCALIP="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias vim="nvim"

#TF alaises
alias aws_env="aws-vault --debug exec jackcarpenter --no-session --"
alias ssh_add_me="ssh-add -k $HOME/.ssh/id_rsa"
alias tfa="terraform apply"
alias tfi="terraform init"
alias tfd="terraform destroy"
alias tfp="terraform plan"

# git aliases
branch=$(git rev-parse --abbrev-ref HEAD)
userRepo=$(git remote -v | grep fetch | awk '{print $2}' | grep "github.com" | cut -d':' -f2 | rev | cut -c5- | rev)
alias gtpr="echo \"Create PR at: https://github.com/$userRepo/compare/$branch?expand=1\""
alias gtpl="git pull"
alias gtpu="git push"
alias gtpup='git push --set-upstream origin $(git branch --show-current)'
alias gtm="git merge"
alias gtc="git checkout"
alias gtcb="git checkout -b"
alias gtcp="git cherry-pick"
alias gts="git stash"
alias gtsp="git stash pop"
alias gtd="git describe"
alias gtl1="git log -1"