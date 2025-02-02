/-
Copyright (c) 2022 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathbin.Algebra.BigOperators.Finsupp
import Mathbin.Data.Finset.Pointwise
import Mathbin.Data.Finsupp.Indicator
import Mathbin.Data.Fintype.Card

/-!
# Finitely supported product of finsets

This file defines the finitely supported product of finsets as a `finset (ι →₀ α)`.

## Main declarations

* `finset.finsupp`: Finitely supported product of finsets. `s.finset t` is the product of the `t i`
  over all `i ∈ s`.
* `finsupp.pi`: `f.pi` is the finset of `finsupp`s whose `i`-th value lies in `f i`. This is the
  special case of `finset.finsupp` where we take the product of the `f i` over the support of `f`.

## Implementation notes

We make heavy use of the fact that `0 : finset α` is `{0}`. This scalar actions convention turns out
to be precisely what we want here too.
-/


noncomputable section

open Finsupp

open BigOperators Classical Pointwise

variable {ι α : Type _} [Zero α] {s : Finset ι} {f : ι →₀ α}

namespace Finset

/-- Finitely supported product of finsets. -/
protected def finsupp (s : Finset ι) (t : ι → Finset α) : Finset (ι →₀ α) :=
  (s.pi t).map ⟨indicator s, indicator_injective s⟩

theorem mem_finsupp_iff {t : ι → Finset α} : f ∈ s.Finsupp t ↔ f.Support ⊆ s ∧ ∀ i ∈ s, f i ∈ t i := by
  refine' mem_map.trans ⟨_, _⟩
  · rintro ⟨f, hf, rfl⟩
    refine' ⟨support_indicator_subset _ _, fun i hi => _⟩
    convert mem_pi.1 hf i hi
    exact indicator_of_mem hi _
    
  · refine' fun h => ⟨fun i _ => f i, mem_pi.2 h.2, _⟩
    ext i
    exact ite_eq_left_iff.2 fun hi => (not_mem_support_iff.1 fun H => hi <| h.1 H).symm
    

/-- When `t` is supported on `s`, `f ∈ s.finsupp t` precisely means that `f` is pointwise in `t`. -/
@[simp]
theorem mem_finsupp_iff_of_support_subset {t : ι →₀ Finset α} (ht : t.Support ⊆ s) : f ∈ s.Finsupp t ↔ ∀ i, f i ∈ t i :=
  by
  refine'
    mem_finsupp_iff.trans
      (forall_and_distrib.symm.trans <|
        forall_congrₓ fun i =>
          ⟨fun h => _, fun h => ⟨fun hi => ht <| mem_support_iff.2 fun H => mem_support_iff.1 hi _, fun _ => h⟩⟩)
  · by_cases' hi : i ∈ s
    · exact h.2 hi
      
    · rw [not_mem_support_iff.1 (mt h.1 hi), not_mem_support_iff.1 fun H => hi <| ht H]
      exact zero_mem_zero
      
    
  · rwa [H, mem_zero] at h
    

@[simp]
theorem card_finsupp (s : Finset ι) (t : ι → Finset α) : (s.Finsupp t).card = ∏ i in s, (t i).card :=
  (card_map _).trans <| card_pi _ _

end Finset

open Finset

namespace Finsupp

/-- Given a finitely supported function `f : ι →₀ finset α`, one can define the finset
`f.pi` of all finitely supported functions whose value at `i` is in `f i` for all `i`. -/
def pi (f : ι →₀ Finset α) : Finset (ι →₀ α) :=
  f.Support.Finsupp f

@[simp]
theorem mem_pi {f : ι →₀ Finset α} {g : ι →₀ α} : g ∈ f.pi ↔ ∀ i, g i ∈ f i :=
  mem_finsupp_iff_of_support_subset <| Subset.refl _

@[simp]
theorem card_pi (f : ι →₀ Finset α) : f.pi.card = f.Prod fun i => (f i).card := by
  rw [pi, card_finsupp]
  exact
    Finset.prod_congr rfl fun i _ => by
      simp only [Pi.nat_apply, Nat.cast_id]

end Finsupp

