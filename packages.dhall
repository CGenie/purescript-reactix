{-
Welcome to Spacchetti local packages!

Below are instructions for how to edit this file for most use
cases, so that you don't need to know Dhall to use it.

## Warning: Don't Move This Top-Level Comment!

Due to how `dhall format` currently works, this comment's
instructions cannot appear near corresponding sections below
because `dhall format` will delete the comment. However,
it will not delete a top-level comment like this one.

## Use Cases

Most will want to do one or both of these options:
1. Override/Patch a package's dependency
2. Add a package not already in the default package set

This file will continue to work whether you use one or both options.
Instructions for each option are explained below.

### Overriding/Patching a package

Purpose:
- Change a package's dependency to a newer/older release than the
    default package set's release
- Use your own modified version of some dependency that may
    include new API, changed API, removed API by
    using your custom git repo of the library rather than
    the package set's repo

Syntax:
Replace the overrides' "{=}" (an empty record) with the following idea
The "//" or "⫽" means "merge these two records and
  when they have the same value, use the one on the right:"
-------------------------------
let override =
  { packageName =
      upstream.packageName ⫽ { updateEntity1 = "new value", updateEntity2 = "new value" }
  , packageName =
      upstream.packageName ⫽ { version = "v4.0.0" }
  , packageName =
      upstream.packageName // { repo = "https://www.example.com/path/to/new/repo.git" }
  }
-------------------------------

Example:
-------------------------------
let overrides =
  { halogen =
      upstream.halogen ⫽ { version = "master" }
  , halogen-vdom =
      upstream.halogen-vdom ⫽ { version = "v4.0.0" }
  }
-------------------------------

### Additions

Purpose:
- Add packages that aren't alread included in the default package set

Syntax:
Replace the additions' "{=}" (an empty record) with the following idea:
-------------------------------
let additions =
  { "package-name" =
       mkPackage
         [ "dependency1"
         , "dependency2"
         ]
         "https://example.com/path/to/git/repo.git"
         "tag ('v4.0.0') or branch ('master')"
  , "package-name" =
       mkPackage
         [ "dependency1"
         , "dependency2"
         ]
         "https://example.com/path/to/git/repo.git"
         "tag ('v4.0.0') or branch ('master')"
  , etc.
  }
-------------------------------

Example:
-------------------------------
let additions =
  { benchotron =
      mkPackage
        [ "arrays"
        , "exists"
        , "profunctor"
        , "strings"
        , "quickcheck"
        , "lcg"
        , "transformers"
        , "foldable-traversable"
        , "exceptions"
        , "node-fs"
        , "node-buffer"
        , "node-readline"
        , "datetime"
        , "now"
        ]
        "https://github.com/hdgarrood/purescript-benchotron.git"
        "v7.0.0"
  }
-------------------------------
-}

let mkPackage =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.0-20190614/src/mkPackage.dhall sha256:0b197efa1d397ace6eb46b243ff2d73a3da5638d8d0ac8473e8e4a8fc528cf57

let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.12.5-20190419/src/packages.dhall sha256:aee7258b1bf1b81ed5e22d1247e812a80ec2e879758562f33334512ed086c5ae

let overrides = 
    { contravariant =
        mkPackage
	    [ "newtype", "either", "prelude", "tuples" ]
	    "https://github.com/purescript/purescript-contravariant"
	    "v4.0.1"
    --    spec =
    --       mkPackage
    --       [ "aff"
    --       , "ansi"
    --       , "avar"
    --       , "console"
    --       , "exceptions"
    --       , "foldable-traversable"
    --       , "fork"
    --       , "generics-rep"
    --       , "now"
    --       , "pipes"
    --       , "prelude"
    --       , "strings"
    --       , "transformers"
    --       ]
    -- 	  "https://github.com/purescript-spec/purescript-spec.git"
   	-- 	  "v3.1.0"
    , ordered-collections =
        mkPackage
        [ "arrays"
        , "foldable-traversable"
        , "gen"
        , "lists"
        , "maybe"
        , "partial"
        , "prelude"
        , "st"
        , "tailrec"
        , "tuples"
        , "unfoldable"
        , "unsafe-coerce"
        ]
        "https://github.com/purescript/purescript-ordered-collections.git"
        "v1.6.1"
}

let additions =
      { dom-simple =
          mkPackage
          [ "console"
          , "effect"
          , "functions"
          , "nullable"
          , "prelude"
          , "spec"
          , "spec-mocha"
          , "unsafe-coerce"
          ]
          "https://github.com/irresponsible/purescript-dom-simple"
          "v0.2.1"
      , ffi-simple =
          mkPackage
          [ "prelude"
          , "effect"
          , "maybe"
          , "functions"
          , "nullable"
          , "unsafe-coerce"
          ]
          "https://github.com/irresponsible/purescript-ffi-simple"
          "v0.2.4"
      , inflection =
          mkPackage
          [ "functions" ]
          "https://github.com/athanclark/purescript-inflection"
          "v1.0.0"
      , spec-mocha =
          mkPackage
          [ "console", "foldable-traversable", "exceptions", "spec" ]
          "https://github.com/purescript-spec/purescript-spec-mocha"
          "v3.0.0"
      }

in  upstream // overrides // additions
