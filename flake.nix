{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: {
      script = pkgs.runCommand "g-script" {
        _locate = pkgs.findutils.locate;
        _nix_index = pkgs.nix-index;
      } ''
        substituteAll ${./g.sh} $out/bin/g
        patchShebang $out/bin/g
      '';
      default = pkgs.writeShellScriptBin "g" ''
        mkdir -p ~/.cache/turbo

        save_and_run(){
          nix --extra-experimental-features 'nix-command' \
            profile install "$found_PATH" --profile ~/.cache/turbo/"$1"
          shift
          echo "in path: $found_PATH" >&2
          exec "$found_PATH" "$@"
        }

        if found_PATH=$(command -v "$1"); then
          save_and_run "$@"
        fi

        PATH=~/.cache/turbo/"$1"/bin:$PATH
        if found_PATH=$(command -v "$1"); then
          save_and_run "$@"
        fi

        if found_PATH=$(${pkgs.findutils.locate}/bin/locate -d ~/.cache/turbo/locate.db --follow --existing --wholename '/nix/*/bin/'"$1" --limit 1); then
         :
        else
          ${pkgs.findutils.locate}/bin/updatedb \
            --localpaths="/nix/var/nix/profiles/* /nix/var/nix/gcroots/* /nix/store" \
            --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' \
            --output=$HOME/.cache/turbo/locate.db &> /dev/null

          found_PATH=$(${pkgs.findutils.locate}/bin/locate \
            -d $HOME/.cache/turbo/locate.db \
            --follow --existing --wholename '/nix/*/bin/'"$1" --limit 1)
        fi

        # TODO: also add rest of store
        # ${pkgs.findutils.locate}/bin/updatedb --localpaths="/nix/store" --findoptions='-mindepth 3 -maxdepth 3 -name .links -prune -o -follow -path "/nix/*/bin/*"' --output=$HOME/.cache/turbo/locate.db &

        if [ -f "$found_PATH" ]; then
          save_and_run "$@"
        fi

        echo "cannot find: $1" >&2
        echo "let's run nix-locate for you" >&2
        ${pkgs.nix-index}/bin/nix-locate /bin/"$1"  --whole-name  --at-root

        # TODO: suggest a package to install
        #found_NAME="$(nix-locate /bin/"$1"  --whole-name  --at-root | awk '{print $4}' | awk -F'[/-]' '{print $5}')"
        exit 42
      '';
    }) _.nixpkgs.legacyPackages;
  };
}
/*
        found_NAME="$(nix-locate /bin/"$1"  --whole-name  --at-root | awk '{print $4}' | awk -F'[/-]' '{print $5}')"

        echo "locate: $found_NAME" >&2

        found_PATH="$(${pkgs.sqlite}/bin/sqlite3 ~/.cache/turbo/db <<EOF | awk -v local="$1" -F'|' '{if (system("test -f " $2 "/bin/" local)==0){ print $2 "/bin/";exit } }'
        ATTACH DATABASE 'file:/nix/var/nix/db/db.sqlite?immutable=1' AS db;
        CREATE TABLE IF NOT EXISTS cached (search TEXT, path TEXT, PRIMARY KEY(search, path));
        DELETE FROM cached WHERE search = '$1';

        PRAGMA temp_store = MEMORY;

        WITH LIST AS MATERIALIZED (
          SELECT *
          FROM db.DerivationOutputs AS d JOIN db.ValidPaths as v ON d.drv = v.id
          WHERE d.path GLOB '/nix/store/*-$found_NAME-*' AND d.path NOT GLOB '*.drv' AND (d.id = 'out' OR d.id = 'bin')
          LIMIT 10
          ) SELECT '$1', path FROM LIST ORDER BY length(path),registrationTime LIMIT 10;
        EOF
        )"

        ${pkgs.sqlite}/bin/sqlite3 ~/.cache/turbo/db <<EOF
          INSERT OR IGNORE INTO cached VALUES( '$1', '$found_PATH' );
        EOF
        echo "running: $found_PATH""$@" >&2
        exec "$found_PATH""$@"






        found_PATH="$(${pkgs.sqlite}/bin/sqlite3 ~/.cache/turbo/db <<EOF | awk -v local="$1" -F'|' '{if (system("test -f " $2 "/bin/" local)==0){ print $2 "/bin/";exit } }'
        ATTACH DATABASE 'file:/nix/var/nix/db/db.sqlite?immutable=1' AS db;
        CREATE TABLE IF NOT EXISTS cached (search TEXT, path TEXT, PRIMARY KEY(search, path));
        DELETE FROM cached WHERE search = '$1';

        PRAGMA temp_store = MEMORY;

        WITH LIST AS MATERIALIZED (
          SELECT *
          FROM db.DerivationOutputs AS d JOIN db.ValidPaths as v ON d.drv = v.id
          WHERE d.path GLOB '/nix/store/*-$found_NAME-*' AND d.path NOT GLOB '*.drv' AND (d.id = 'out' OR d.id = 'bin')
          LIMIT 10
          ) SELECT '$1', path FROM LIST ORDER BY length(path),registrationTime LIMIT 10;
        EOF
        )"
*/
