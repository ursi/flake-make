{ inputs =
    { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      purs-nix.url = "github:ursi/purs-nix";
      utils.url = "github:ursi/flake-utils";
    };

  outputs = { nixpkgs, utils, purs-nix, ... }:
    utils.defaultSystems
      ({ pkgs, system }:
         let
           inherit (purs-nix { inherit system; }) purs ps-pkgs ps-pkgs-ns;
           inherit
             (purs
                { dependencies =
                    with ps-pkgs-ns;
                    with ps-pkgs;
                    [ node-process
                      substitute
                      ursi.prelude
                      ursi.task-file
                      ursi.task-node-child-process
                    ];

                  src = ./src;
                }
             )
             modules
             shell;
         in
         { defaultPackage =
             (modules.Main.install
                { name = "flake-make";
                  command = "make-flake";
                }
             )
             .overrideAttrs (old: { buildInputs = [ pkgs.git ] ++ old.buildInputs; });

           devShell =
             with pkgs;
             mkShell
               { buildInputs =
                   [ nodejs
                     purescript
                     (shell {})
                   ];
               };
         }
      )
      nixpkgs;
}
