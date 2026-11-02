set --global fish_greeting

alias .. "cd ../"
alias n nvim
alias ls "eza -l"
alias l "eza -l"
alias ll "eza -al"
alias tree "eza --tree"
alias gg lazygit
alias ze "zed ."

if status is-interactive
    starship init fish | source
    enable_transience
    zoxide init fish | source
    atuin init fish --disable-up-arrow | source
    direnv hook fish | source
end
