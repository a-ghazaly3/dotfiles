export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

export EDITOR=nvim
export VISUAL=nvim

export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"

export PATH="$HOME/fvm/default/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.14/libexec/bin:$PATH"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"

eval "$(zoxide init --cmd cd zsh)"

alias vim="nvim"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/abdelrahmanghazaly/.dart-cli-completion/zsh-config.zsh ]] && . /Users/abdelrahmanghazaly/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

export PATH="/opt/homebrew/opt/expat/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
