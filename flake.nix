{
  description = "momo-typst — Typst templates + reproducible dev/CI environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            typst
            python3
            git
            cacert
          ];

          shellHook = ''
            echo "momo-typst dev shell"
            echo "- typst:  $(typst --version 2>/dev/null || true)"
            echo "- python: $(python3 --version 2>/dev/null || true)"
          '';
        };
      });
}
