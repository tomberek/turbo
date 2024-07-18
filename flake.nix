{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: rec {
      script = pkgs.runCommand "g" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        mkdir -p $out/bin
        substitute ${./g.sh} $out/bin/g \
          --subst-var-by locate ${pkgs.findutils.locate} \
          --subst-var-by nix-index ${pkgs.nix-index}
        chmod +x $out/bin/g
        patchShebangs $out/bin/g
      '';
      default = script; #pkgs.writeShellScriptBin "g" (script + "/bin/g");
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
