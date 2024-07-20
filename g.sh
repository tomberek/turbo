#!/usr/bin/env bash
mkdir -p "$HOME"/.cache/turbo

_locate=${_locate:-@locate@}
_nix_index=${_nix_index:-@nix-index@}
_tracelinks=${_tracelinks:-@tracelinks@}
_gum=${_gum:-@gum@}

save_and_run(){
  dir=$(dirname "$found_PATH")
  dir=$(dirname "$dir")
  nix --extra-experimental-features 'nix-command' \
    build "$dir" --no-link --profile "$HOME"/.cache/turbo/"$1"
  while IFS= read -r line; do
    "$_gum"/bin/gum log --level info -- "$line"
  done < <("$_tracelinks"/bin/tracelinks -m "$found_PATH")
  shift
  exec "$found_PATH" "$@"
}

if found_PATH=$(command -v "$1"); then
  save_and_run "$@"
fi

if found_PATH=$(PATH="$HOME"/.cache/turbo/"$1"/bin:$PATH command -v "$1"); then
  save_and_run "$@"
fi

if [ -e "$HOME"/.cache/turbo/locate.db ] && found_PATH=$("$_locate"/bin/locate \
		-d "$HOME"/.cache/turbo/locate.db \
		--follow --existing --wholename '/nix/*/bin/'"$1" --limit 1); then
	save_and_run "$@"
else
  "$_gum"/bin/gum spin --show-output --spinner dot --title "Searching in gcroots and profiles" -- \
  "$_locate"/bin/updatedb \
    --localpaths="/nix/var/nix/profiles/* /nix/var/nix/gcroots/*" \
    --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' \
    --output="$HOME"/.cache/turbo/locate.db &> /dev/null
fi

if found_PATH=$("$_locate"/bin/locate \
	  -d "$HOME"/.cache/turbo/locate.db \
	  --follow --existing --wholename '/nix/*/bin/'"$1" --limit 1); then
  save_and_run "$@"
fi

# TODO: also add rest of store
# ${pkgs.findutils.locate}/bin/updatedb --localpaths="/nix/store" --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' --output=$HOME/.cache/turbo/locate.db &

#if [ -e "$found_PATH" ]; then
  #save_and_run "$@"
#fi

"$_gum"/bin/gum log --level info -- "cannot find: $1"
"$_gum"/bin/gum log --level info -- "let's run nix-locate for you"

SELECTION=$("$_nix_index"/bin/nix-locate /bin/"$1"  --whole-name  --at-root | $_gum/bin/gum choose | cut -d' ' -f1 )
found_PATH=$("$_gum"/bin/gum spin \
	--show-output --spinner dot --title "Fetching '$SELECTION' from nixpkgs" \
	-- nix --extra-experimental-features 'nix-command flakes' \
	build --no-link nixpkgs\#"$SELECTION" --print-out-paths | head -n1)/bin/"$1"
save_and_run "$@"

exit 42
