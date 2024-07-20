{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.tracelinks.url = "github:flox/tracelinks";
  inputs.tracelinks.flake = false;

  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: rec {
      tracelinks = pkgs.callPackage (_.tracelinks + "/pkgs/tracelinks") {self=_.tracelinks;};
      script = pkgs.runCommand "g" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        mkdir -p $out/bin
        substitute ${./g.sh} $out/bin/g \
          --subst-var-by locate ${pkgs.findutils.locate} \
          --subst-var-by nix-index ${pkgs.nix-index} \
          --subst-var-by tracelinks ${tracelinks} \
          --subst-var-by gum ${pkgs.gum}
        chmod +x $out/bin/g
        patchShebangs $out/bin/g
        ln -s $out/bin/g $out/bin/turbo
        ln -s $out/bin/g $out/bin/321
        ln -s $out/bin/g $out/bin/'$'
      '';
      default = script;
    }) _.nixpkgs.legacyPackages;
  };
}
