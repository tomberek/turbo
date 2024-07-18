#!/usr/bin/env bash
mkdir -p ~/.cache/turbo

_locate=${_locate:-@locate@}
_nix_index=${_nix_index:-@nix-index@}

save_and_run(){
  dir=$(dirname "$found_PATH")
  dir=$(dirname "$dir")
  nix --extra-experimental-features 'nix-command' \
    build "$dir" --no-link --profile "$HOME"/.cache/turbo/"$1"
  shift
  echo "running: $found_PATH" >&2
  exec "$found_PATH" "$@"
}

if found_PATH=$(command -v "$1"); then
  save_and_run "$@"
fi

if found_PATH=$(PATH="$HOME"/.cache/turbo/"$1"/bin:$PATH command -v "$1"); then
  save_and_run "$@"
fi

if [ -e "$HOME"/.cache/turbo/locate.db ] && found_PATH=$("$_locate"/bin/locate \
		-d ~/.cache/turbo/locate.db \
		--follow --existing --wholename '/nix/*/bin/'"$1" --limit 1); then
	save_and_run "$@"
else
  "$_locate"/bin/updatedb \
    --localpaths="/nix/var/nix/profiles/* /nix/var/nix/gcroots/*" \
    --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' \
    --output="$HOME"/.cache/turbo/locate.db &> /dev/null
fi

if found_PATH=$("$_locate"/bin/locate \
	  -d ~/.cache/turbo/locate.db \
	  --follow --existing --wholename '/nix/*/bin/'"$1" --limit 1); then
  save_and_run "$@"
fi

# TODO: also add rest of store
# ${pkgs.findutils.locate}/bin/updatedb --localpaths="/nix/store" --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' --output=$HOME/.cache/turbo/locate.db &

#if [ -e "$found_PATH" ]; then
  #save_and_run "$@"
#fi

echo "cannot find: $1" >&2
echo "let's run nix-locate for you" >&2

# TODO: suggest a package to install
"$_nix_index"/bin/nix-locate /bin/"$1"  --whole-name  --at-root
	#| awk '{print $4}' | awk -F'[/-]' '{print $5}')"
exit 42
