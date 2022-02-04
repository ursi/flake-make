{ inputs =
    { make-shell.url = "github:ursi/nix-make-shell/1";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      purs-nix.url = "github:ursi/purs-nix";
      utils.url = "github:ursi/flake-utils/7";
    };

  outputs = { utils, ... }@inputs:
    utils.make-flake { inherit inputs; }
      ({ make-shell, pkgs, purs-nix, ...}:
         let
           inherit (purs-nix) purs ps-pkgs ps-pkgs-ns;

           inherit
             (purs
                { dependencies =
                    with ps-pkgs;
                    let inherit (ps-pkgs-ns) ursi; in
                    [ node-process
                      substitute
                      ursi.prelude
                      ursi.task-file
                    ];

                  srcs = [ ./src ];
                }
             )
             modules
             command;
         in
         { defaultPackage =
             modules.Main.install
                { name = "flake-make";
                  command = "make-flake";
                };

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
      );
}
