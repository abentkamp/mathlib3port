/-
Copyright (c) 2022 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathbin.Data.Sum.Basic
import Mathbin.Logic.Nontrivial

/-!
# Two-pointings

This file defines `two_pointing α`, the type of two pointings of `α`. A two-pointing is the data of
two distinct terms.

This is morally a Type-valued `nontrivial`. Another type which is quite close in essence is `sym2`.
Categorically speaking, `prod` is a cospan in the category of types. This forms the category of
bipointed types. Two-pointed types form a full subcategory of those.

## References

* [nLab, *Coalgebra of the real interval*]
  (https://ncatlab.org/nlab/show/coalgebra+of+the+real+interval)
-/


open Function

variable {α β : Type _}

/-- Two-pointing of a type. This is a Type-valued termed `nontrivial`. -/
@[ext]
structure TwoPointing (α : Type _) extends α × α where
  fst_ne_snd : fst ≠ snd
  deriving DecidableEq

namespace TwoPointing

variable (p : TwoPointing α) (q : TwoPointing β)

theorem snd_ne_fst : p.snd ≠ p.fst :=
  p.fst_ne_snd.symm

/-- Swaps the two pointed elements. -/
@[simps]
def swap : TwoPointing α :=
  ⟨(p.snd, p.fst), p.snd_ne_fst⟩

theorem swap_fst : p.swap.fst = p.snd :=
  rfl

theorem swap_snd : p.swap.snd = p.fst :=
  rfl

@[simp]
theorem swap_swap : p.swap.swap = p := by
  ext <;> rfl

-- See note [reducible non instances]
@[reducible]
theorem to_nontrivial : Nontrivial α :=
  ⟨⟨p.fst, p.snd, p.fst_ne_snd⟩⟩

instance [Nontrivial α] : Nonempty (TwoPointing α) :=
  let ⟨a, b, h⟩ := exists_pair_ne α
  ⟨⟨(a, b), h⟩⟩

@[simp]
theorem nonempty_two_pointing_iff : Nonempty (TwoPointing α) ↔ Nontrivial α :=
  ⟨fun ⟨p⟩ => p.to_nontrivial, @TwoPointing.nonempty _⟩

section Pi

variable (α) [Nonempty α]

/-- The two-pointing of constant functions. -/
def pi : TwoPointing (α → β) where
  fst := fun _ => q.fst
  snd := fun _ => q.snd
  fst_ne_snd := fun h =>
    q.fst_ne_snd <| by
      convert congr_funₓ h (Classical.arbitrary α)

@[simp]
theorem pi_fst : (q.pi α).fst = const α q.fst :=
  rfl

@[simp]
theorem pi_snd : (q.pi α).snd = const α q.snd :=
  rfl

end Pi

/-- The product of two two-pointings. -/
def prod : TwoPointing (α × β) where
  fst := (p.fst, q.fst)
  snd := (p.snd, q.snd)
  fst_ne_snd := fun h => p.fst_ne_snd (congr_argₓ Prod.fst h)

@[simp]
theorem prod_fst : (p.Prod q).fst = (p.fst, q.fst) :=
  rfl

@[simp]
theorem prod_snd : (p.Prod q).snd = (p.snd, q.snd) :=
  rfl

/-- The sum of two pointings. Keeps the first point from the left and the second point from the
right. -/
protected def sum : TwoPointing (Sum α β) :=
  ⟨(Sum.inl p.fst, Sum.inr q.snd), Sum.inl_ne_inr⟩

@[simp]
theorem sum_fst : (p.Sum q).fst = Sum.inl p.fst :=
  rfl

@[simp]
theorem sum_snd : (p.Sum q).snd = Sum.inr q.snd :=
  rfl

/-- The `ff`, `tt` two-pointing of `bool`. -/
protected def bool : TwoPointing Bool :=
  ⟨(false, true), Bool.ff_ne_tt⟩

@[simp]
theorem bool_fst : TwoPointing.bool.fst = ff :=
  rfl

@[simp]
theorem bool_snd : TwoPointing.bool.snd = tt :=
  rfl

instance : Inhabited (TwoPointing Bool) :=
  ⟨TwoPointing.bool⟩

/-- The `false`, `true` two-pointing of `Prop`. -/
protected def prop : TwoPointing Prop :=
  ⟨(False, True), false_ne_true⟩

@[simp]
theorem Prop_fst : TwoPointing.prop.fst = False :=
  rfl

@[simp]
theorem Prop_snd : TwoPointing.prop.snd = True :=
  rfl

end TwoPointing

