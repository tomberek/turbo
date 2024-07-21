{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.tracelinks.url = "github:flox/tracelinks/tomberek.minimal";
  inputs.tracelinks.flake = false;

  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: rec {

      # grab the recipe for tracelinks directly
      tracelinks = pkgs.callPackage (_.tracelinks + "/pkgs/tracelinks") {self=_.tracelinks;};

      turbo = pkgs.runCommand "g" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        mkdir -p $out/bin
        substitute ${./g.sh} $out/bin/g \
          --subst-var-by locate ${pkgs.findutils.locate}/bin/locate \
          --subst-var-by updatedb ${pkgs.findutils.locate}/bin/updatedb \
          --subst-var-by nix-locate ${pkgs.nix-index}/bin/nix-locate \
          --subst-var-by tracelinks ${tracelinks}/bin/tracelinks \
          --subst-var-by docopts ${pkgs.docopts}/bin/docopts \
          --subst-var-by gum ${pkgs.gum}/bin/gum
        chmod +x $out/bin/g
        patchShebangs $out/bin/g
        ln -s $out/bin/g $out/bin/turbo
        ln -s $out/bin/g $out/bin/321
        ln -s $out/bin/g $out/bin/'$'
      '';
      default = turbo;
    }) _.nixpkgs.legacyPackages;
  };
}
