# ==========================================
# Environment Variables & Modes
# ==========================================

# Editor definitions
set -gx VISUAL nvim
set -gx EDITOR nvim

# Set VI Mode
fish_vi_key_bindings

# Removes Greeting
set -g fish_greeting

function fish_user_key_bindings

    # --- deletion to system clipboard ---
	# not worth it
	#    bind -M visual y "fish_clipboard_copy; commandline -f end-selection repaint-mode"
	#    bind -M visual d "fish_clipboard_copy; commandline -f kill-selection end-selection repaint-mode"
	#    bind -M visual x "fish_clipboard_copy; commandline -f kill-selection end-selection repaint-mode"
	#    bind -M visual c "fish_clipboard_copy; commandline -f kill-selection end-selection; set fish_bind_mode insert; commandline -f repaint-mode"
	#    bind -M default dd "commandline -f kill-whole-line; commandline -t | fish_clipboard_copy"
	#    bind -M default D  "commandline -f kill-line; commandline -t | fish_clipboard_copy"
	#    bind -M default x  "commandline -f delete-char; commandline -t | fish_clipboard_copy"
	# bind -M default C "commandline -f kill-line; commandline -t | fish_clipboard_copy; set fish_bind_mode insert; commandline -f repaint-mode"
	# bind -M visual c "fish_clipboard_copy; commandline -f kill-selection end-selection; set fish_bind_mode insert; commandline -f repaint-mode"
	#    bind -M default c "commandline -f vi-set-mode-operator; set fish_bind_mode insert"
	#
	# TODO: remake this using special bidings to simulated the unnamed plus buffer



    # -------------------------------------------------------------
	# 'V' to open neovim for command editting
    # -------------------------------------------------------------

    bind -M default V edit_command_buffer
    bind -M visual V edit_command_buffer


    # -------------------------------------------------------------
	# Erase 's' and 'S' from normal (default) mode
    # -------------------------------------------------------------
    bind -e -M default s
    bind -e -M default S
    bind -e -M visual s
    bind -e -M visual S

    # -------------------------------------------------------------
    # Alt+Space (\e\x20) Universal Exit / Return to Normal Mode
    # -------------------------------------------------------------

    # Insert mode -> Switch to Normal (default) mode
    bind -M insert \e\x20 "set fish_bind_mode default; commandline -f repaint-mode"

    # Visual mode -> Cancel selection and return to Normal mode
	bind -M visual \e\x20 "commandline -f end-selection; set fish_bind_mode default; commandline -f repaint-mode"

    # Pager / Search mode -> Close pager and search prompt
    bind -M pager \e\x20 "commandline -f cancel"

    # Normal / Default mode -> Clear commandline / cancel background operations
    bind -M default \e\x20 "commandline -f cancel"

	# Replace mode to normal
	bind -M replace \e\x20 "set fish_bind_mode default; commandline -f repaint-mode"
	bind -M replace_one \e\x20 "set fish_bind_mode default; commandline -f repaint-mode"

end



# ==========================================
# Functions
# ==========================================

# Check Git Status Function
function check_git
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        return 0
    end

    set -l project_name (git rev-parse --show-toplevel 2>/dev/null | grep -Po '[^/]+$')
    
    # We call git status natively down the pipe because Fish splits command 
    # substitution output into lists automatically, which messes with grep parsing.
    set -l branch (git status | grep -Po '^On branch \K[^ ]+')
    set -l changes (git status | grep -Pc '(modified:)|(deleted:)|(new file:)')
    
    set -l untracked_raw (git status | grep -zPo "(Untracked files:)(\s.+)+" | wc -l)
    set -l untracked (math "$untracked_raw - 1")
    if test "$untracked" -eq -1
        set untracked 0
    end

    echo "~~ git::"$project_name" @ "$branch"  c:"$changes" u:"$untracked
end

# Replaces PROMPT_COMMAND by triggering on the fish_prompt event
function nvim_quit_cd --on-event fish_prompt
    set -l home (echo ~)

    if not test -f "$home/.file_nvim_quit"
        return
    end

    set -l file_contents (cat ~/.file_nvim_quit)
    cd "$file_contents"
    rm ~/.file_nvim_quit
end

# Paste to cd
function pg
    set -l clipboard_content (xclip -selection clipboard -o 2>/dev/null; or wl-paste 2>/dev/null)
    if test -n "$clipboard_content"
        cd "$clipboard_content"
    end
end

# Print working directory to clipboard
function pwc
    if command -v wl-copy >/dev/null 2>&1
        pwd | wl-copy >/dev/null 2>&1
    else if command -v xclip >/dev/null 2>&1
        pwd | xclip -selection clipboard >/dev/null 2>&1
    end
end

# Fuzzy find and execute commands in PATH
function fpath
    # Fish alternative to compgen -c
    set -l cmd (complete -C '' | awk '{print $1}' | sort -u | fzf --reverse)
    if test -n "$cmd"
        eval $cmd
    end
end

# Run silently in background
function quiet
    $argv &> /dev/null &
    disown
end


# ==========================================
# Prompt Definition (Replaces PS1)
# ==========================================

function fish_mode_prompt
    # Leave this completely empty
end


function fish_prompt
    # Print leading newline
    echo
    
    # Red bracket with User@Host
    set_color -o red
    printf "["
    printf "%s@%s " $USER (prompt_hostname)
    
    # White 24-hour time
	set_color -o white
    printf "%s" (date "+%H:%M:%S")
    
    # Close red bracket and newline
    set_color -o red
    printf "]"

	# Custom Vi Mode Indicator
    switch $fish_bind_mode
        case default
            set_color -o blue
            printf " N"
        case insert
            set_color -o green
            printf "  "
        case visual
            set_color -o yellow
            printf " V"
        case replace replace_one
            set_color -o magenta
            printf " R"
    end

    printf "\n"
    
    # White full working directory (Fish's prompt_pwd shortens paths, so we use string replace)
    set_color -o white
    printf "%s" (string replace -r "^$HOME" "~" $PWD)

    printf "\n"
    
    # Git status 
    set_color normal
	#printf "%s" (check_git)
	check_git
    
    # Final newline and prompt character
    set_color normal
    printf "\$ "
end


# TODO
# - exit search mode with alt+space

# ==========================================
# Aliases & Shortcuts
# ==========================================

# Keybindings
# Note: fish natively clears the screen with Ctrl+L in Vi insert mode. 
# We explicitly bind it for normal/default mode to be safe.
bind -M default \cl 'clear; commandline -f repaint'
bind -M insert \cl 'clear; commandline -f repaint'

# Basic aliases
alias lsa 'ls -a'
alias la 'ls -la'
alias ~~ 'cd ~/'

# App launchers
function new
    alacritty --working-directory (pwd) >/dev/null 2>&1 &
    disown
end

function ex
    dolphin . >/dev/null 2>&1 &
    disown
end

function pv
    dolphin . >/dev/null 2>&1 &
    disown
end

# Neovim aliases
alias term "nvim -c 'terminal' -c 'set rnu nu'"
alias nt "nvim +terminal"
alias nv "nvim ."
alias nvi "nvim"

# keeps environment variables after using sudo
alias sudo~ "sudo -E -s"


# ==========================================
# FZF Directory/File Navigation
# ==========================================

# Reusable base exclusion options for fd
set -g __fd_base_excludes \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    --exclude .npm \
    --exclude .mozilla \
    --exclude .meteor \
    --exclude .nv \
    --exclude .local/share/Trash \
	--exclude /proc \
    --exclude /sys \
    --exclude /dev \
    --exclude /run \
    --exclude /tmp \
    --exclude /var/tmp \
    --exclude /var/cache \
    --exclude /nix/store

# Fuzzy finds a directory in current path and cd into it
function fdir
    set -l tgt (fd --type d --hidden $__fd_base_excludes | fzf)
    if test -n "$tgt"
        cd "$tgt"
    end
end

# Fuzzy finds a file in current path and cd into its directory
function ffile
    set -l tgt (fd --type f --hidden $__fd_base_excludes | fzf)
    if test -n "$tgt"
        # Uses dirname to cleanly extract the directory path
        cd (path dirname "$tgt")
    end
end

# Fuzzy finds a directory from $HOME without changing directory on cancel
function hfdir
    set -l tgt (fd --type d --hidden $__fd_base_excludes . ~ | fzf)
    if test -n "$tgt"
        cd "$tgt"
    end
end

# Fuzzy finds a file from $HOME and cd into its directory without changing directory on cancel
function hffile
    set -l tgt (fd --type f --hidden $__fd_base_excludes . ~ | fzf)
    if test -n "$tgt"
        cd (path dirname "$tgt")
    end
end

# Fuzzy finds a directory from root (/) and cd into it without moving on cancel
function rfdir
    set -l tgt (fd --type d --hidden $__fd_base_excludes $__fd_root_excludes . / 2>/dev/null | fzf)
    if test -n "$tgt"
        cd "$tgt"
    end
end

# Fuzzy finds a file from root (/) and cd into its directory without moving on cancel
function rffile
    set -l tgt (fd --type f --hidden $__fd_base_excludes $__fd_root_excludes . / 2>/dev/null | fzf)
    if test -n "$tgt"
        cd (path dirname "$tgt")
    end
end
