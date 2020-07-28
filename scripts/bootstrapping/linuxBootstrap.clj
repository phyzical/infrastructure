(use '[clojure.string :only (join)])

(defn runCommandWithArgs [command args]
  (debug (shell {:cmd (join " " [command (join " " args)])})))

(def password "CHANGETHIS")
(def aptApps ["make"
              "ack"
              "autoconf"
              "automake"
              "docker"
              "ffmpeg"
              "gettext"
              "git"
              "graphviz"
              "imagemagick"
              "jq"
              "markdown"
              "npm"
              "thunderbird"
              "firefox"
              "openssh-server"
              "pkg-config"
              "postgresql"
              "python3"
              "tmux"
              "tree"
              "vim"
              "wget"
              "nmap"
              "bash-completion"
              "unrar"
              "thefuck"
              "vagrant"
              "virtualbox"
              "net-tools"])
(def snapApps [ "rambox"
                "spotify"])
(def bashRcAdditions[
  "export ANDROID_HOME='~/Library/Android/sdk'"
  "export PATH='$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/opt/local/bin:/opt/local/sbin:$PATH'"
  "eval $(thefuck --alias)"
  "GITPS1='\\$(__git_ps1 \\\"(%s)\\\")'"
  "PS1='\\n${GITPS1}\\n[\\t][\\u@\\h:\\W] \\$'"
  "PUBLICIP='dig +short myip.opendns.com @resolver1.opendns.com'"
  "LOCALIP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p')"])
(def profileName "~/.bash_profile2")

(ssh {:username "user" 
      :hostname "localhost"} 
  (sudo-user {:username "root" :password password}
    (debug (apt :update))
    (debug (apt :install aptApps))
    (if (failed? (runCommandWithArgs "snap install" snapApps))
      (runCommandWithArgs "snap refresh" snapApps)))
  (when (failed? (shell {:cmd (join " " ["cat" profileName])})) 
    (for [bashRcAddition bashRcAdditions]
      (println (join " " ["echo" bashRcAddition ">>" profileName]))))
      ; (debug (shell {:cmd (join " " ["echo" bashRcAddition ">>" profileName])}))))
      ; (debug (shell {:cmd (join " " ["echo '." profileName "' >> ~/.bashrc"])})))
  ; (if (failed? (shell {:cmd "git config --list | grep -i 'user.name'"}))
    ; (debug (shell {:cmd "git config --global user.name s"}))
    ; (debug (shell {:cmd "git config --global user.email s@s.s'"})))
  (debug (mkdir {:path "~/Sites"})))