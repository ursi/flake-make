{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    psnp.url = "github:ursi/psnp";
  };

  outputs = { self, nixpkgs, flake-utils, psnp }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
          {
            # defaultPackage =
            #     (import ./psnp.nix { inherit pkgs; })
            #       .overrideAttrs (old: { buildInputs = [ git ] ++ old.buildInputs; });

            devShell = with pkgs;
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
