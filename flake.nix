{
  inputs.psnp.url = "github:ursi/psnp";

  outputs = { self, nixpkgs, utils, psnp }:
    utils.defaultSystems
      ({ pkgs, system }: with pkgs;
        {
          defaultPackage =
              (import ./psnp.nix { inherit lib pkgs; })
                .overrideAttrs (old: { buildInputs = [ git ] ++ old.buildInputs; });

          devShell = mkShell {
            buildInputs = [
              dhall
              nodejs
              psnp.defaultPackage.${system}
              purescript
              spago
            ];
          };
        }
      )
      nixpkgs;
}
