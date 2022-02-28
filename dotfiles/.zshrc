# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/andreas/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
autoload -U promptinit 
promptinit
#prompt fade blue
PROMPT="%K{white}%B%F{blue}   %n@%m %K{254} %K{252} %K{250} %K{248} %K{246} %K{244} %K{242} %K{240} %k %D{%a %b %d} %*"$'\n'"%~/ %f%b"
#RPROMPT="%F{blue}%D{%a %b %d} %*%f"
setopt correctall
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
alias ls="ls -al --color"
