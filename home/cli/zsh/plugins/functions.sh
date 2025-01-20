#!/usr/bin/env zsh

bindkey -s '^a' 'buku_fzf\n'
bindkey -s '^e' 'n\n'
bindkey -s '^k' '~/scripts/nova/fzf-nova\n'
bindkey -s '^f' 'fzf | xargs -I {} wtype linkhandler.sh "$(pwd)/{}"\n'
calc() { printf "%s\n" "$@" | bc -l; }
batdiff() { git diff --name-only --relative --diff-filter=d | xargs bat --diff; }

function confirm() {
  read -sk 1 "response?${1:-Are you sure} (y/[n])? " || echo
  if [[ "$response" =~ ^(yes|y)$ ]]; then
	  true
  else
	  false
  fi
}

# tab: like "bat" but in reverse
function tab() {
	tmp=$(bat "$1")
	title=$(echo $tmp | head -n1)
	file=$(echo $tmp | tac | head -n -1)
	echo $title
	echo $file
}

fif() {
	zparseopts -D -E -A opts -filter: -dir: -print:
	if [ -z "$1" ]; then echo "Need a string to search for!"; return 1; fi
	filter="${opts[--filter]+-g $opts[--filter]}"
	dir="${opts[--dir]+$opts[--dir]}"
	selection=$(rg --files-with-matches --no-messages -g !rehoboam/ ${filter} $1 $dir | fzf --preview-window "down,70%" --preview ~/scripts/previewers/fif_preview.sh\ '{}'\ "$1")
	[ "${opts[--print]+abc}" ] && ~/scripts/previewers/fif_preview.sh "$selection" "$1" || echo $selection | ~/scripts/file-ops/linkhandler.sh
}

n () {
    # Block nesting of nnn in subshells
    if [[ "${NNNLVL:-0}" -ge 1 ]]; then
        echo "nnn is already running"
        return
    fi
    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The backslash allows one to alias n to nnn if desired without making an
    # infinitely recursive alias
    \nnn -P p -c -a "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

