source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
function fish_greeting
    printf "\e[97m"
    cat ~/.config/ascii/arachne.txt
    printf "\e[0m"
    printf "\n"
end

# dotfiles bare repo alias
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME/.config'

# opencode
fish_add_path /home/max/.opencode/bin
