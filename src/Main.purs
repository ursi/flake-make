module Main where

import MasonPrelude
import Data.Array ((:), (!!))
import Data.Array as Array
import Node.Process (argv)
import Substitute (class Homogeneous, defaultOptions, makeSubstituter)
import Task as Task
import Task.File as File

substitute :: ∀ r. Homogeneous r String => String -> Record r -> String
substitute = makeSubstituter $ defaultOptions { marker = '%' }

main :: Effect Unit
main = do
  marg <- argv <#> (_ !! 2)
  (Task.run <. File.write "flake.nix")
    (marg
     # maybe
       emptyFlake
       \arg ->
         case arg of
           "elm" ->
             mkDefaultSystems
               { outerInputs: []
               , innerInputs:
                   [ GhUrl "elm-install" "ursi/elm-install"
                   , GhUrl "node-packages" "ursi/nix-node-packages"
                   ]
               , pkgs:
                   [ "elm-install"
                   , "elmPackages.elm"
                   , "elmPackages.elm-format"
                   , "elmPackages.elm-language-server"
                   , "node-packages.elm-git-install"
                   ]
               }

           "shell" ->
             mkDefaultSystems
               { outerInputs: []
               , innerInputs: []
               , pkgs: []
               }

           "spago" ->
              mkDefaultSystems
                { outerInputs: []
                , innerInputs: [ GhUrl "easy-ps" "ursi/easy-purescript-nix/flake" ]
                , pkgs:
                    [ "easy-ps.spago"
                    , "easy-ps.purescript"
                    , "nodejs"
                    , "nodePackages.purescript-language-server"
                    ]
                }
           package ->
             mkDefaultSystems
               { outerInputs: []
               , innerInputs: []
               , pkgs: [ package ]
               }
    )

makeInputs :: Array Input -> String
makeInputs inputs =
  substitute
    """
    inputs =
      { %{inputs}
      };
    """
    { inputs:
        inputs
        # Array.sortWith inputName
        <#> inputToString
        # intercalate "\n"
    }

data Input
  = Url String String
  | GhUrl String String
  | Set String (Array (String /\ String))

inputName :: Input -> String
inputName = case _ of
  Url name _ -> name
  GhUrl name _ -> name
  Set name _ -> name

inputToString :: Input -> String
inputToString = case _ of
  Url name url -> substitute """%{name}.url = "%{url}";""" { name, url }
  GhUrl name url -> substitute """%{name}.url = "github:%{url}";""" { name, url }
  Set name attributes ->
    substitute
      """

      %{name} =
        { %{attributes}
        };
      """
      { name
      , attributes:
        attributes
        # Array.sortWith fst
        <#> (\(attrName /\ value) -> attrName <> " = " <> value <> ";")
        # intercalate "\n"
      }

makeShell :: Input
makeShell = GhUrl "make-shell" "ursi/nix-make-shell/1"

nixpkgs :: Input
nixpkgs = GhUrl "nixpkgs" "NixOS/nixpkgs/nixpkgs-unstable"

utils :: Input
utils = GhUrl "utils" "ursi/flake-utils/8"

basicFrame ::
  { inputs :: Array Input
  , args :: Array String
  , body :: String
  , inputsName :: Maybe String
  } ->
  String
basicFrame { inputs, args, inputsName, body } =
      substitute
        """
        { %{inputs}

          outputs = { %{args}... }%{inputsName}:
            with builtins;
            %{body}
        }
        """
        { inputs: makeInputs inputs
        , args: foldMap (\arg -> arg <> ", ") args
        , inputsName:
            inputsName
            # maybe "" \str -> "@" <> str
        , body
        }

mkDefaultSystems ::
  { outerInputs :: Array Input
  , innerInputs :: Array Input
  , pkgs :: Array String
  }
  -> String
mkDefaultSystems { outerInputs, innerInputs, pkgs } =
  basicFrame
    { inputs: [ makeShell, nixpkgs, utils ] <> outerInputs <> innerInputs
    , args:
        (utils : outerInputs)
        <#> inputName
        # Array.sort
    , inputsName: Just "inputs"
    , body:
        substitute
          """
          utils.apply-systems { inherit inputs; }
            ({ %{args}... }:
               let l = p.lib; p = pkgs; in
               { devShell =
                   make-shell
                     { packages =
                         with pkgs;
                         [ %{pkgs}
                         ];
                     };
               }
            );
          """
          { args:
              [ "make-shell", "pkgs" ] <> (inputName <$> innerInputs)
              # Array.sort
              # foldMap (_ <> ", ")
          , pkgs: pkgs # Array.sort # intercalate "\n"
          }
    }

emptyFlake :: String
emptyFlake =
  basicFrame
    { inputs: [ nixpkgs, utils ]
    , args: [ inputName utils ]
    , inputsName: Just "inputs"
    , body:
        """
        utils.apply-systems { inherit inputs; }
          ({ pkgs, ... }:
             let l = p.lib; p = pkgs; in
             {
             }
          );
        """
    }
