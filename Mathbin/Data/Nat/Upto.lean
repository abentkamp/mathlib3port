/-
Copyright (c) 2020 Simon Hudon. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Simon Hudon
-/
import Mathbin.Data.Nat.Basic

/-!
# `nat.upto`

`nat.upto p`, with `p` a predicate on `ℕ`, is a subtype of elements `n : ℕ` such that no value
(strictly) below `n` satisfies `p`.

This type has the property that `>` is well-founded when `∃ i, p i`, which allows us to implement
searches on `ℕ`, starting at `0` and with an unknown upper-bound.

It is similar to the well founded relation constructed to define `nat.find` with
the difference that, in `nat.upto p`, `p` does not need to be decidable. In fact,
`nat.find` could be slightly altered to factor decidability out of its
well founded relation and would then fulfill the same purpose as this file.
-/


namespace Nat

/-- The subtype of natural numbers `i` which have the property that
no `j` less than `i` satisfies `p`. This is an initial segment of the
natural numbers, up to and including the first value satisfying `p`.

We will be particularly interested in the case where there exists a value
satisfying `p`, because in this case the `>` relation is well-founded.  -/
@[reducible]
def Upto (p : ℕ → Prop) : Type :=
  { i : ℕ // ∀ j < i, ¬p j }

namespace Upto

variable {p : ℕ → Prop}

/-- Lift the "greater than" relation on natural numbers to `nat.upto`. -/
protected def Gt (p) (x y : Upto p) : Prop :=
  x.1 > y.1

instance : LT (Upto p) :=
  ⟨fun x y => x.1 < y.1⟩

/-- The "greater than" relation on `upto p` is well founded if (and only if) there exists a value
satisfying `p`. -/
protected theorem wf : (∃ x, p x) → WellFounded (Upto.Gt p)
  | ⟨x, h⟩ => by
    suffices upto.gt p = Measureₓ fun y : Nat.Upto p => x - y.val by
      rw [this]
      apply measure_wf
    ext ⟨a, ha⟩ ⟨b, _⟩
    dsimp' [Measureₓ, InvImage, upto.gt]
    rw [tsub_lt_tsub_iff_left_of_le]
    exact le_of_not_ltₓ fun h' => ha _ h' h

/-- Zero is always a member of `nat.upto p` because it has no predecessors. -/
def zero : Nat.Upto p :=
  ⟨0, fun j h => False.elim (Nat.not_lt_zeroₓ _ h)⟩

/-- The successor of `n` is in `nat.upto p` provided that `n` doesn't satisfy `p`. -/
def succ (x : Nat.Upto p) (h : ¬p x.val) : Nat.Upto p :=
  ⟨x.val.succ, fun j h' => by
    rcases Nat.lt_succ_iff_lt_or_eq.1 h' with (h' | rfl) <;> [exact x.2 _ h', exact h]⟩

end Upto

end Nat

