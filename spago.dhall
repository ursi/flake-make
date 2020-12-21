{ name = "make-flake"
, dependencies =
  [ "mason-prelude"
  , "node-process"
  , "substitute"
  , "task-file"
  , "task-node-child-process"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
, version = "0.1.0"
}
