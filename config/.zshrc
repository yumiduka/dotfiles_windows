## 少し凝った zshrc (via https://gist.github.com/mollifier/4979906)
ZSHRC_USEFUL="${HOME}/zshrc_useful.sh"
test -f "${ZSHRC_USEFUL}" && source ${ZSHRC_USEFUL}

## プロンプト
PROMPT="%{${fg[yellow]}%}[%D{%Y/%m/%d} %*]%{${reset_color}%} %{${fg[cyan]}%}%~%{${reset_color}%}
%# "

## PATH
export PATH="${PATH}:${HOME}/.composer/vendor/bin"
export PATH="/usr/local/sbin:${PATH}"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
export PATH="/usr/local/opt/findutils/libexec/gnubin:${PATH}"
export MANPATH="/usr/local/opt/coreutils/libexec/gnubin:${MANPATH}"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:${MANPATH}"

## エイリアス
alias sed='gsed'
alias ls='exa'
alias ll='exa -lah --git --time-style full-iso'
alias g='cd $(/usr/bin/find $(ghq root --all) -depth 3 -type d | peco)'
alias localstack='cd $(ghq list -p | grep localstack); TMPDIR=/private$TMPDIR docker-compose up'
