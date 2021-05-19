{ inputs =
    { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      purs-nix.url = "github:ursi/purs-nix";
      utils.url = "github:ursi/flake-utils/1";
    };

  outputs = { nixpkgs, utils, ... }@inputs:
    utils.default-systems
      ({ make-shell, pkgs, purs-nix, ...}:
         let
           inherit (purs-nix) purs ps-pkgs ps-pkgs-ns;

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
             command;
         in
         { defaultPackage =
             (modules.Main.install
                { name = "flake-make";
                  command = "make-flake";
                }
             )
             .overrideAttrs (old: { buildInputs = [ pkgs.git ] ++ old.buildInputs; });

           devShell =
             make-shell
               { packages =
                   with pkgs;
                   [ nodejs
                     nodePackages.purescript-language-server
                     purs-nix.purescript
                     (command {})
                   ];
               };
         }
      )
      { inherit inputs nixpkgs; };
}
