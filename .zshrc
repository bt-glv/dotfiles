
# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi


if [[ -n $RUNTHIS ]] then
	$RUNTHIS
fi

# VI MODE
bindkey -v
export KEYTIMEOUT=1
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
