# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="bira"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=("bira" "bureau" "robbyrussell" "clean")

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting z vscode fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export http_proxy=http://127.0.0.1:10809
export https_proxy=http://127.0.0.1:10809

export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_BUILD_MIRROR_URL="https://registry.npmmirror.com/-/binary/python"

#主题、git、虚拟环境显示自定义

# Git相关配置
# 这个函数用于显示 git 的状态，即 √ 或 x
git_custom_status() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local STATUS="$(git status --porcelain 2> /dev/null)"
        if [[ -z $STATUS ]]; then
            echo "%{$fg_bold[green]%} ✔%{$reset_color%}"
        else
            echo "%{$fg_bold[red]%} ✘%{$reset_color%}"
        fi
    fi
}
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""

# 虚拟环境相关配置
export VIRTUAL_ENV_DISABLE_PROMPT=1

# 主题及提示符配置
PROMPT='╭─%{$fg_bold[green]%}%n%{$reset_color%}@%{$fg_bold[green]%}%m %{$fg_bold[red]%}%~ $(git_prompt_info)$(git_custom_status)  %{$fg_bold[blue]%}%*%{$reset_color%}
╰─$%{$fg[magenta]%}${VIRTUAL_ENV:+(`basename $VIRTUAL_ENV`)}%{$reset_color%} '



#windows terminal中选项卡的动态更新
# 在执行命令前捕获命令并更新标题
preexec() {
    local cmd="$1"
    # 如果命令是常见的简短命令，则直接显示
    if [[ "$cmd" == "ls" || "$cmd" == "cd" ]]; then
        echo -ne "\033]0;本地-$cmd\007"
        return
    fi
    # 对于激活虚拟环境的命令，只显示虚拟环境的名称
    if [[ "$cmd" =~ "source" && "$cmd" =~ "activate" ]]; then
        cmd="venv:${cmd##*/}"
        echo -ne "\033]0;本地-$cmd\007"
        return
    fi
    # 如果命令长度超过20个字符，只显示前17个字符并加上省略号
    if [[ ${#cmd} -gt 20 ]]; then
        cmd="${cmd:0:17}..."
    fi
    # 使用 ANSI escape codes 设置终端标题
    echo -ne "\033]0;本地-$cmd\007"
}



#自动激活与关闭虚拟环境
auto_venv() {
  local target_dir="$PWD"
  local venv_path=""
  local parent_dir

  while [[ "$target_dir" != "/" ]]; do
    # 搜索深度为2的Scripts目录，并忽略权限错误
    venv_path="$(find "$target_dir" -maxdepth 2 -type d -name 'Scripts' -exec test -f '{}/activate' \; -print -quit 2>/dev/null)"
    if [[ -n "$venv_path" ]]; then
      break
    fi
    parent_dir="$(dirname "$target_dir")"
    if [[ "$parent_dir" == "$target_dir" ]]; then
      break
    fi
    target_dir="$parent_dir"
  done

  if [[ -n "$venv_path" ]]; then
    local venv_dir="$(dirname "$venv_path")"
    if [[ -z "$VIRTUAL_ENV" || "$VIRTUAL_ENV" != "$venv_dir" ]]; then
      [[ -n "$VIRTUAL_ENV" ]] && deactivate
      echo "检测到以下 Python 虚拟环境：$venv_dir 已自动激活"
      source "$venv_path/activate"
    fi
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    if [[ "$PWD" != "$VIRTUAL_ENV" && "$PWD" != "$VIRTUAL_ENV"* ]]; then
      deactivate
      #echo "已关闭虚拟环境：$VIRTUAL_ENV"
    fi
  fi
}

# 将 auto_venv 函数挂钩至目录改变时的事件
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv
