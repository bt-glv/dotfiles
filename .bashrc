
# Attention!
# This bashrc requires: git, fzf, fd
#
set -o vi
function check_git() {

	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo ""
		return 0
	fi

	git_status=$(git status)
	project_name=$(git rev-parse --show-toplevel 2>/dev/null | grep -Po '[^/]+$')

	branch=$(echo "$git_status" | grep -Po '^On branch \K[^ ]+')
	changes=$(echo "$git_status" | grep -Pc '(modified:)|(deleted:)|(new file:)')
	untracked=$(git status | grep -zPo "(Untracked files:)(\s.+)+" | wc -l)
	untracked=$(($untracked-1))
	if [ $untracked -eq -1 ]; then 
		untracked=0
	fi

	# You cant define colors in a function's ""return"" value. They can only be defined at the shell level. 
	# The weird spacing here is necessary
	 echo "    
~~ git::${project_name} @ ${branch}  c:${changes} u:${untracked}"
}

function nvim_quit_cd() {
local home="$(eval echo ~)"
if [[ ! -f "$home/.file_nvim_quit" ]]; then return; fi

local file_contents="$(cat ~/.file_nvim_quit)"
cd "$file_contents"
rm ~/.file_nvim_quit
}

# PROMPT_COMMAND manipulation
PROMPT_COMMAND="nvim_quit_cd; $PROMPT_COMMAND"

## PS1 with colors ##
export PS1='\n\e[01;31m[\u@\H \e[01;37m\t\e[01;31m]\n\e[01;37m\w\e[m$(check_git)\e[m\n\\$ '

function goto_clipboard_path() {
	clipboard_content=$(xclip -selection clipboard -o 2>/dev/null || wl-paste 2>/dev/null)
	cd "$clipboard_content"
}

export VISUAL=nvim
export EDITOR=nvim

bind = '"\C-l":"clear\n"'

alias lsa='ls -a'
alias la='ls -la'

alias new='alacritty --working-directory "$(pwd)" >/dev/null 2>&1 & disown'
alias ex="dolphin . >/dev/null 2>&1 & disown"
alias pv="dolphin . >/dev/null 2>&1 & disown"
alias pg='goto_clipboard_path'
alias pwc='pwd | if command -v wl-copy >/dev/null 2>&1; then wl-copy; else xclip -selection clipboard; fi'
alias ~~='cd ~/'


# Opens neovim in terminal mode at current dir
alias term="nvim +terminal"
alias nt="nvim +terminal"
alias nv="nvim ."
alias nvi="nvim"

# keeps environment variables after using sudo
# use this to edit a file on neovim (or other editor) with sudo privileges with your config
alias sudo~="sudo -E -s"

# requires fd and fzf to work
## Fuzzy finds a directory and cd into it
alias fdir='cd "$(fd --type d --hidden --exclude .git --exclude node_module --exclude .cache --exclude .npm --exclude .mozilla --exclude .meteor --exclude .nv | fzf)"'

## Fuzzy finds a file and cd into its directory
alias ffile='cd "$(fd --hidden --exclude .git --exclude node_module --exclude .cache --exclude .npm --exclude .mozilla --exclude .meteor --exclude .nv | fzf | grep -Po "([^/]+[/])+")"'

# home fdir and ffile 
alias hfdir='cd ~/;fdir'
alias hffile='cd ~/;ffile'
# root fdir and ffile 
alias rfdir='cd /;fdir'
alias rffile='cd /;ffile'



#### Bashrc colors help ####
# For editing purposes:
#
# #ColorName#	#ColorCode#		#NameToCode Redgex#
# .				.				.			
# Green 	 	'\e[01;32m'		s/Green/\\e[01;32m/g
# White 	 	'\e[01;37m'		s/White/\\e[01;37m/g
# Red 	 		'\e[01;31m'		s/Red/\\e[01;31m/g
# Yellow 	 	'\e[01;33m'		s/Yellow/\\e[01;33m/g
# End			'\e[m'			s/End/\\e[m/g

#### OLD PS1 ####
#
# Previous more minimalistic PS1
# export PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
# export color0='\033[01;32m'
# export color1='\033[01;37m'
# export reset='\033[m'
# export PS1="\n${color0}[\u@\H ${color1}\t${color0}]${color1}\n\w\n${color0}\\$ $reset"
#
# This previous iteration has a bug. If you navigate through the command history (upwards) for too long, it will start printing random characters before the cursor.

