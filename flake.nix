{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.tracelinks.url = "github:flox/tracelinks/tomberek.minimal";
  inputs.tracelinks.flake = false;

  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: rec {

      # grab the recipe for tracelinks directly
      tracelinks = pkgs.callPackage (_.tracelinks + "/pkgs/tracelinks") { self = _.tracelinks; };

      turbo =
        pkgs.runCommandNoCC "g"
          {
            buildInputs = [
              pkgs.docopts
              pkgs.findutils.locate
              pkgs.gum
              pkgs.gnused
              pkgs.nix-index
              tracelinks
            ];
            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.shfmt
              pkgs.shellcheck
            ];
          }
          ''
            mkdir -p $out/bin
            substitute ${./g.sh} $out/bin/g \
              --subst-var-by locate ${pkgs.findutils.locate}/bin/locate \
              --subst-var-by updatedb ${pkgs.findutils.locate}/bin/updatedb \
              --subst-var-by nix-locate ${pkgs.nix-index}/bin/nix-locate \
              --subst-var-by nix-index ${pkgs.nix-index}/bin/nix-index \
              --subst-var-by tracelinks ${tracelinks}/bin/tracelinks \
              --subst-var-by docopts ${pkgs.docopts}/bin/docopts \
              --subst-var-by sed ${pkgs.gnused}/bin/sed \
              --subst-var-by gum ${pkgs.gum}/bin/gum
            chmod +x $out/bin/g
            patchShebangs $out/bin/g
            ln -s $out/bin/g $out/bin/turbo
            ln -s $out/bin/g $out/bin/321
            ln -s $out/bin/g $out/bin/'$'
            set -eu
            shfmt -s -d -i 4 $out/bin/g
            shellcheck $out/bin/g
            $out/bin/g --version
          '';
      default = turbo;
    }) _.nixpkgs.legacyPackages;
  };
}
