import Mathbin.Tactic.NthRewrite.Default

/-!
# Types used in rewrite search.
-/


initialize 
  registerTraceClass.1 `rewrite_search

namespace Tactic.RewriteSearch

-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler decidable_eq
-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler inhabited
/--
`side` represents the side of an equation, either the left or the right.
-/
inductive side
  | L
  | R deriving [anonymous], [anonymous]

/-- Convert a side to a human-readable string. -/
unsafe def side.to_string : side → format
| side.L => "L"
| side.R => "R"

/-- Convert a side to the string "lhs" or "rhs", for use in tactic name generation. -/
def side.to_xhs : side → Stringₓ
| side.L => "lhs"
| side.R => "rhs"

unsafe instance side.has_to_format : has_to_format side :=
  ⟨side.to_string⟩

/--
A `how` contains information needed by the explainer to generate code for a rewrite.
`rule_index` denotes which rule in the static list of rules is used.
`location` describes which match of that rule was used, to work with `nth_rewrite`.
`addr` is a list of "left" and "right" describing which subexpression is rewritten.
-/
unsafe structure how where 
  rule_index : ℕ 
  location : ℕ 
  addr : Option (List ExprLens.Dir)

/-- Convert a `how` to a human-readable string. -/
unsafe def how.to_string : how → format
| h => f! "rewrite {h.rule_index } {h.location } {h.addr.iget.to_string}"

unsafe instance how.has_to_format : has_to_format how :=
  ⟨how.to_string⟩

/-- `rewrite` represents a single step of rewriting, that proves `exp` using `proof`. -/
unsafe structure rewrite where 
  exp : expr 
  proof : tactic expr 
  how : how

/--
`proof_unit` represents a sequence of steps that can be applied to one side of the
equation to prove a particular expression.
-/
unsafe structure proof_unit where 
  proof : expr 
  Side : side 
  steps : List how

/--
Configuration options for a rewrite search.
`max_iterations` controls how many vertices are expanded in the graph search.
`explain` generates Lean code to replace the call to `rewrite_search`.
`explain_using_conv` changes the nature of the explanation.
-/
unsafe structure config extends tactic.nth_rewrite.cfg where 
  max_iterations : ℕ := 5000 
  explain_using_conv : Bool := tt

end Tactic.RewriteSearch

