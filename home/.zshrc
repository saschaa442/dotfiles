# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Personal shell configuration, managed from ~/.dotfiles.
# Add shared defaults here as this setup grows.
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# Use Bitwarden's SSH agent rather than the empty macOS launchd agent. The
# Bitwarden desktop app creates this socket when its SSH agent is enabled.
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

# eza uses the managed Catppuccin Mocha theme, including in fzf-tab previews.
export EZA_CONFIG_DIR="$HOME/.config/eza"
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza --long --header --git --icons=auto --group-directories-first'
  alias la='eza --long --all --header --git --icons=auto --group-directories-first'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Shared, duplicate-free shell history. Ctrl-R below opens it in fzf.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history share_history hist_ignore_dups hist_save_no_dups

# Official Catppuccin Mocha palette for fzf, with a readable framed layout.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
  --height=40% --layout=reverse --border=rounded \
  --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:#45475A,border:#6C7086,label:#CDD6F4"

# A larger framed Ctrl-R picker; works with fzf's standard history binding.
export FZF_CTRL_R_OPTS="--height=50% --layout=reverse --border=rounded --border-label=' History ' --prompt='󰋚  '"

# Completion settings must be in place before compinit. `fzf-tab` replaces the
# normal menu with a searchable picker when multiple matches exist.
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no
autoload -Uz compinit
compinit

# Homebrew-installed fzf bindings: Ctrl-R searches history; Tab completes paths.
for fzf_bindings in \
  /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
  /usr/local/opt/fzf/shell/key-bindings.zsh; do
  [[ -r "$fzf_bindings" ]] && source "$fzf_bindings" && break
done

# fzf-tab turns `cd <Tab><Tab>` into a Catppuccin-styled picker. The preview
# shows the selected folder as a two-level tree; `/` continues into a path.
zstyle ':fzf-tab:*' fzf-flags \
  --border=rounded \
  --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:#45475A,border:#6C7086,label:#CDD6F4
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --icons=always --color=always $realpath'
for fzf_tab in \
  /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh \
  /usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh; do
  [[ -r "$fzf_tab" ]] && source "$fzf_tab" && break
done

# Enable mise so its globally configured Node.js version is available in every
# interactive shell. Project-local mise.toml files can override it.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Suggestions are sourced before highlighting; syntax-highlighting must remain
# the final plugin loaded by zsh.
for autosuggestions in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -r "$autosuggestions" ]] && source "$autosuggestions" && break
done

for syntax_highlighting in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "$syntax_highlighting" ]] && source "$syntax_highlighting" && break
done
