module Main where

import MasonPrelude
import Data.Array ((!!))
import Data.String (Pattern(..))
import Data.String as String
import Node.Process (argv)
import Substitute (class Homogeneous, defaultOptions, normalize, makeSubstituter)
import Task as Task
import Task.File as File

substitute :: ∀ r. Homogeneous r String => String -> Record r -> String
substitute = makeSubstituter $ defaultOptions { marker = '@' }

main :: Effect Unit
main = do
  argv
    <#> (_ !! 2)
    >>= maybe (log "You need to supply one argument.") \arg ->
        Task.run do
          File.write "flake.nix" case arg of
            "purescript" ->
              makeSimpleShell
                """
                dhall
                nodejs
                nodePackages.pulp
                nodePackages.bower
                purescript
                spago
                """
            "psnp" ->
              basicFrame
                { inputs:
                    Just
                      """
                      inputs.psnp.url = "github:ursi/psnp";
                      """
                , args: [ "utils", "psnp" ]
                , body:
                    """
                    utils.defaultSystems
                      ({ pkgs, system }: with pkgs;
                         { # defaultPackage =
                           #   (import ./psnp.nix { inherit lib pkgs; })
                           #     .overrideAttrs (old: { buildInputs = [] ++ old.buildInputs; });

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
                    """
                }
            "shell" ->
              basicFrame
                { inputs: Nothing
                , args: [ "utils" ]
                , body:
                    """
                    utils.mkShell
                      ({ pkgs, ... }: with pkgs;
                         { buildInputs = [];

                           shellHook = '''';
                         }
                      )
                      nixpkgs;
                    """
                }
            package -> makeSimpleShell package

quote :: String -> String
quote s = "\"" <> s <> "\""

basicFrame ::
  { inputs :: Maybe String
  , args :: Array String
  , body :: String
  } ->
  String
basicFrame { inputs, args, body } =
  case inputs of
    Just i ->
      substitute
        """
        { @{inputs}

        """
        { inputs: i }
    Nothing ->
      ( substitute
          """
          { outputs = { nixpkgs@{args}, ... }:
              @{body}
          }
          """
          { args: foldMap (\arg -> ", " <> arg) args
          , body
          }
      )

makeSimpleShell :: String -> String
makeSimpleShell buildInputs =
  basicFrame
    { inputs: Nothing
    , args: [ "utils" ]
    , body:
        substitute
          """
          utils.simpleShell
            [ @{buildInputs}
            ]
            nixpkgs;
          """
          { buildInputs: mapLines quote $ normalize buildInputs }
    }

mapLines :: (String -> String) -> String -> String
mapLines f =
  String.split (Pattern "\n")
    .> foldMap
        ( \line ->
            ( if line == "" then
                ""
              else
                f line <> "\n"
            )
        )
