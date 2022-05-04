export PATH=/usr/local/bin:/usr/local/sbin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

#random alias
alias PUBLICIP="dig +short myip.opendns.com @resolver1.opendns.com"
alias LOCALIP="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias histsearch='fc -l 0 | grep'
export HISTSIZE=10000
export HISTFILESIZE=10000

kill_by_port() {
  kill -9 $(lsof -i tcp:$1 -t)
}
alias kbp="kill_by_port"
alias kbpid="kill -9"

#TF alaises
alias ssh_add="ssh-add -k $HOME/.ssh/"
alias aws_env="aws-vault --debug exec jackcarpenter --no-session --"
alias tf='terraform-v$(cat main.tf | grep "required_version" | tr -d "required_version=\"~<> ")'
alias tfa="tf apply"
alias tfi="tf init"
alias tfd="tf destroy"
alias tfp="tf plan"
alias tfiu="tf init -upgrade"
alias tfiup="tfiu && tfp"

# git aliases
pr_info() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  userRepo=$(git remote -v | grep origin | grep fetch | awk '{print $2}' | grep "github.com" | cut -d':' -f2 | rev | cut -c5- | rev)
}
alias gt="git"
alias gtpr='pr_info && open "https://github.com/${userRepo}/compare/${branch}?expand=1"'
alias gtpl="gt pull"
alias gtpu="gt push"
alias gtput="gtpu --tags"
alias gtpup='gtpu --set-upstream origin $(git branch --show-current)'
alias gtm="gt merge"
alias gtc="gt checkout"
alias gtcl="gt clone"
alias gtcm="gt commit -m"
alias gtcb="gt checkout -b"
alias gtcp="gt cherry-pick"
alias gtst="gt status"
alias gts="gt stash"
alias gtsp="gts pop"
alias gtt="gt tag -a"
alias gtd="gt describe"
alias gtl1="gt log -1"
alias gtr="gt reset"
alias gtrho="gtr --hard origin"
alias gtau="gt remote add upstream"
alias gtf="gt fetch"
alias gtfr="gtf upstream && gt rebase upstream/master"
alias gtpt="gtpu --tags"
