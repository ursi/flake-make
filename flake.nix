{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    psnp.url = "github:ursi/psnp";
  };

  outputs = { self, nixpkgs, flake-utils, psnp }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
          with pkgs;
          {
            defaultPackage =
                (import ./psnp.nix { inherit lib pkgs; })
                  .overrideAttrs (old: { buildInputs = [ git ] ++ old.buildInputs; });

            devShell =
              mkShell {
                buildInputs = [
                  dhall
                  nodejs
                  psnp.defaultPackage.${system}
                  purescript
                  spago
                ];
              };
          }
      );
}
