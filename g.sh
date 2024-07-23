#!/usr/bin/env bash
set -euo pipefail

_locate=${_locate:-@locate@}
_locate=${_locate//@/}
_updatedb=${_updatedb:-@updatedb@}
_updatedb=${_updatedb//@/}
_nix_locate=${_nix_locate:-@nix-locate@}
_nix_locate=${_nix_locate//@/}
_nix_index=${_nix_index:-@nix-index@}
_nix_index=${_nix_index//@/}
_tracelinks=${_tracelinks:-@tracelinks@}
_tracelinks=${_tracelinks//@/}
_gum=${_gum:-@gum@}
_gum=${_gum//@/}
_docopts=${_docopts:-@docopts@}
_docopts=${_docopts//@/}
_sed=${_sed:-@sed@}
_sed=${_sed//@/}

: "${l=} ${r=} ${i=} ${c=}"
: "${local=} ${remote=} ${index=} ${clear=} ${minimal=}"
: "${debug=} ${command=} ${args=}"

_basename="${0##*/}"
_d="$(
    "$_docopts" -O -V - -h - : "$@" <<EOF || true
Search for and run a binary

Command:
  <command>   Run <command> with <args>

Usage:
  $_basename [options] ( local  | l ) [<args>]...
  $_basename [options] ( remote | r ) [<args>]...
  $_basename [options] ( index  | i ) [<args>]...
  $_basename ( clear | c )
  $_basename [options] <command> [<args>]...

Subcommands:
  local       Find file in local db
  remote      Find file using nix-locate
  index       Index paths (/nix/store, /nix/var/nix/profiles/*)
  clear       Clear cache at ~/.cache/turbo

Options:
  -m, --minimal        Minimal output
  -d, --debug          Debug output
  -h, --help           Show this screen
  -v, --version        Print version

----
g 0.1.0
Copyright (C) 2024 Thomas Bereknyei
EOF
)"
eval "$_d"
if [[ $debug == "true" ]]; then
    echo "$_d"
    set -x
fi

if [[ $local == "true" || $l == "true" ]]; then
    "$_locate" \
        -d "$HOME"/.cache/turbo/locate.db \
        --follow --existing "${args[@]}" |
        { if [[ ${minimal} == "true" ]]; then
            $_sed 's#/nix/store/.*[0-9a-z]\{32\}[^-]*-*##g'
        else
            cat
        fi; }
    exit $?
fi

if [[ $remote == "true" || $r == "true" ]]; then
    if [[ $minimal == "true" ]]; then
        args=("--minimal" "${args[@]}")
    fi
    "$_nix_locate" "${args[@]}"
    exit $?
fi

if [[ $index == "true" || $i == "true" ]]; then
    : "${args:="/nix/store"}"
    mkdir -p "$HOME"/.cache/turbo
    "$_gum" spin \
        --show-error --spinner dot --title "Indexing '${args}'" -- \
        "$_updatedb" \
        --localpaths="${args}" \
        --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' \
        --output="$HOME"/.cache/turbo/locate.db
    exit $?
fi

if [[ $clear == "true" || $c == "true" ]]; then
    rm -rf "$HOME"/.cache/turbo
    exit 0
fi

save_and_run() {
    dir=$(dirname "$found_PATH")
    dir=$(dirname "$dir")
    mkdir -p "$HOME"/.cache/turbo
    nix --offline \
        --extra-experimental-features 'nix-command' \
        build "$dir" --no-link --profile "$HOME"/.cache/turbo/"$command"
    run
}
run() {
    if [[ $minimal == "false" ]]; then
        while IFS= read -r line; do
            "$_gum" log --level info -- "$line"
        done < <("$_tracelinks" -m "$found_PATH")
    fi
    exec "$found_PATH" "${args[@]}"
}

if found_PATH=$(PATH="$HOME"/.cache/turbo/"$command"/bin command -v "$command"); then
    run
fi

_locate_run() {
    found_PATH=$("$_locate" \
        -d "$HOME"/.cache/turbo/locate.db \
        --follow --existing --wholename '/nix/*/bin/'"$command" --limit 1) && [ -n "$found_PATH" ]
    return $?
}
if [[ -e "$HOME"/.cache/turbo/locate.db ]] && _locate_run; then
    save_and_run
else
    "$_gum" spin --spinner dot --title "Searching in gcroots and profiles" -- \
        "$_updatedb" \
        --localpaths="/nix/var/nix/profiles/* /nix/var/nix/gcroots/*" \
        --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' \
        --output="$HOME"/.cache/turbo/locate.db
fi

if _locate_run "$@"; then
    save_and_run "$@"
fi

"$_gum" log --level info -- "cannot find: $command"
"$_gum" log --level info -- "let's run nix-locate for you"
if [ ! -e "$HOME"/.cache/nix-index/files ]; then
    "$_gum" spin --show-output --show-error --spinner dot --title "Indexing" -- "$_nix_index"
fi

SELECTION=$("$_nix_locate" /bin/"$command" --whole-name --at-root | "$_gum" choose | cut -d' ' -f1)
if [ -n "$SELECTION" ] && [ "$SELECTION" != "no" ]; then
    found_PATH=$("$_gum" spin \
        --show-output --show-error --spinner dot --title "Fetching '$SELECTION' from nixpkgs" \
        -- nix -L --extra-experimental-features 'nix-command flakes' \
        build --no-link nixpkgs\#"$SELECTION" --print-out-paths | head -n1)/bin/"$command"
    save_and_run "$@"
fi

"$_gum" log --level error -- "cannot find: $command"
exit 1
