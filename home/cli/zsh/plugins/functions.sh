#!/usr/bin/zsh

bindkey -s '^a' 'buku_fzf\n'
bindkey -s '^e' 'n\n'
bindkey -s '^k' '~/scripts/nova/fzf-nova\n'
bindkey -s '^f' 'fzf | xargs -I {} wtype linkhandler.sh "$(pwd)/{}"\n'
# Calculator
calc() { printf "%s\n" "$@" | bc -l; }
batdiff() { git diff --name-only --relative --diff-filter=d | xargs bat --diff; }
video() { nohup mpv $@ >/dev/null 2>&1 &; }
# Confirm
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

separator () {
	printf ${ORG}
	for ((done=0; done<$1; done++)); do printf "─"; done
	printf ${NC}
	printf "\n"
}

progress_bar () {
	if [ -z "$2" ]; then
		cols=$(($(tput cols) - 4))
	else
		cols=$(($(tput cols) * $2 / 10 -2))
	fi
	if [ -z "$3" ]; then
		progress_frac=$(echo "scale=2; $1/100" | bc)
	else
		progress_frac=$(echo "scale=2; $1/$3" | bc)
	fi
	progress=$(echo "scale=2; $progress_frac*$cols" | bc)
	progress=$(printf "%.0f" $progress)
	printf " "
	for ((done=0; done<$cols; done++)); do printf "\u2581"; done
	printf "\n"
	printf "▕"
	for ((done=0; done<$progress; done++)); do printf "▒"; done
	for ((remain=$progress; remain<$cols; remain++)); do printf "░"; done
	printf "▏"
	printf "\n"
	printf " "
	for ((done=0; done<$cols; done++)); do printf "▔"; done
	printf "\n"
}

progress_bar_fixed () {
	if [ -z "$3" ]; then
		progress_frac=$(echo "scale=2; $1/100" | bc)
	else
		progress_frac=$(echo "scale=2; $1/$3" | bc)
	fi
	cols=$(($2 - 2))
	progress=$(echo "scale=2; $progress_frac*$cols" | bc)
	progress=$(printf "%.0f" $progress)
	printf " "
	for ((done=0; done<$cols; done++)); do printf "\u2581"; done
	printf "\n"
	printf "▕"
	for ((done=0; done<$progress; done++)); do printf "▒"; done
	for ((remain=$progress; remain<$cols; remain++)); do printf "░"; done
	printf "▏"
	printf "\n"
	printf " "
	for ((done=0; done<$cols; done++)); do printf "▔"; done
	printf "\n"
}
heading () {
	if [ -n $FZF_PREVIEW_COLUMNS ]; then
		cols=$(($FZF_PREVIEW_COLUMNS + 7))
		#cols=$FZF_PREVIEW_COLUMNS
	else
		cols=$(($(tput cols) - 12))
	fi
	if [ -z "$2" ]; then
		title="${ORG}⢾⣿⡷ ${1} ⢾"
		reserved=${#title}
		printf $title
		printf '⣿%.0s' {1..$(($cols-$reserved))}
		printf "⡷\n${NC}"
	else
		printf "${ORG}⢾⣿⡷ ${1} ⢾⣿⡷ ${2} ⢾"
		subtitle_lines=$((${#2} + 4))
		printf '⣿%.0s' {1..$(($cols-$subtitle_lines))}
		printf "⡷\n${NC}"
	fi
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

