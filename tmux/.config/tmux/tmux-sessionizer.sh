#!/usr/bin/env bash

SEARCH_DIRS=(
    ~/Workspace/Work
    ~/Workspace/Personal
    ~/Workspace/Learning
    ~/.dotfiles/
)

source ~/.config/fzf/fzf.sh
export FZF_DEFAULT_OPTS="$FZF_BASE_OPTS
  --prompt='SESSIONIZER: '
  --tmux center,50%,40%"

# Build label->path map; handle basename collisions by appending parent dir
declare -A dir_map
declare -A seen_names
while IFS= read -r d; do
    base="${d##*/}"
    if [[ -n "${seen_names[$base]}" ]]; then
        # Collision: disambiguate both entries with parent dir
        existing_path="${dir_map[$base]}"
        existing_label="${existing_path%/*}/${base}"
        dir_map["$existing_label"]="$existing_path"
        unset 'dir_map[$base]'
        label="${d%/*}/${base}"
    else
        label="$base"
        seen_names["$base"]=1
    fi
    dir_map["$label"]="$d"
done < <(find "${SEARCH_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

# Convert display label to safe tmux session name ('.' -> '_', '/' -> '-')
to_session_name() {
    local n="$1"
    [[ "$n" == .* ]] && n="_${n:1}"
    echo "${n//\//-}"
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || true)

    declare -A session_set
    while IFS= read -r s; do [[ -n "$s" ]] && session_set["$s"]=1; done <<< "$sessions"

    # Dirs whose session name doesn't match any active session
    dir_names=""
    for label in "${!dir_map[@]}"; do
        sname=$(to_session_name "$label")
        [[ -z "${session_set[$sname]}" ]] && dir_names+="$label"$'\n'
    done

    # Active sessions marked with *
    session_lines=""
    while IFS= read -r s; do
        [[ -n "$s" ]] && session_lines+="* $s"$'\n'
    done <<< "$sessions"

    selected=$( (printf '%s' "$session_lines"; printf '%s' "$dir_names") | sort -u | fzf ) || exit 0
    selected="${selected#\* }"
fi

[[ -z "$selected" ]] && exit 0

session_name=$(to_session_name "$selected")

if tmux has-session -t="$session_name" 2>/dev/null; then
    tmux switch-client -t="$session_name"
else
    dir="${dir_map[$selected]:-}"
    if [[ -n "$dir" ]]; then
        tmux new-session -ds "$session_name" -c "$dir"
    else
        tmux new-session -ds "$session_name"
    fi
    tmux switch-client -t="$session_name"
fi
