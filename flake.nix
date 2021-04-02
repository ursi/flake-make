{ inputs.psnp.url = "github:ursi/psnp";

  outputs = { nixpkgs, utils, psnp, ... }:
    utils.defaultSystems
      ({ pkgs, system }: with pkgs;
         { defaultPackage =
             (import ./psnp.nix pkgs)
               .overrideAttrs (old: { buildInputs = [ git ] ++ old.buildInputs; });

           devShell =
             mkShell
               { buildInputs =
                   [ dhall
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
