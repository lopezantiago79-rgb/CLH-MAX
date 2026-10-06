import Lake
open Lake DSL

package «clh-max» where
  name := "clh-max"
  version := "1.0.0"
  description := "CLH MAX KEM — IND-CPA security proof in Lean 4 / Mathlib"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @
  "v4.14.0"

lean_lib «ClhMax» where
  roots := #[`ClhMaxSecurity]
  globs := #[.submodules `ClhMax
