/-
Copyright (c) 2021 Yury Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury Kudryashov
-/
import Mathbin.Data.Fintype.Basic

/-!
# Induction principles for `Π i, finset (α i)`

In this file we prove a few induction principles for functions `Π i : ι, finset (α i)` defined on a
finite type.

* `finset.induction_on_pi` is a generic lemma that requires only `[finite ι]`, `[decidable_eq ι]`,
  and `[Π i, decidable_eq (α i)]`; this version can be seen as a direct generalization of
  `finset.induction_on`.

* `finset.induction_on_pi_max` and `finset.induction_on_pi_min`: generalizations of
  `finset.induction_on_max`; these versions require `Π i, linear_order (α i)` but assume
  `∀ y ∈ g i, y < x` and `∀ y ∈ g i, x < y` respectively in the induction step.

## Tags
finite set, finite type, induction, function
-/


open Function

variable {ι : Type _} {α : ι → Type _} [Finite ι] [DecidableEq ι] [∀ i, DecidableEq (α i)]

namespace Finset

/-- General theorem for `finset.induction_on_pi`-style induction principles. -/
theorem induction_on_pi_of_choice (r : ∀ i, α i → Finset (α i) → Prop)
    (H_ex : ∀ (i) (s : Finset (α i)) (hs : s.Nonempty), ∃ x ∈ s, r i x (s.erase x)) {p : (∀ i, Finset (α i)) → Prop}
    (f : ∀ i, Finset (α i)) (h0 : p fun _ => ∅)
    (step : ∀ (g : ∀ i, Finset (α i)) (i : ι) (x : α i), r i x (g i) → p g → p (update g i (insert x (g i)))) : p f :=
  by
  cases nonempty_fintype ι
  induction' hs : univ.sigma f using Finset.strongInductionOn with s ihs generalizing f
  subst s
  cases' eq_empty_or_nonempty (univ.sigma f) with he hne
  · convert h0
    simpa [funext_iff] using he
    
  · rcases sigma_nonempty.1 hne with ⟨i, -, hi⟩
    rcases H_ex i (f i) hi with ⟨x, x_mem, hr⟩
    set g := update f i ((f i).erase x) with hg
    clear_value g
    have hx' : x ∉ g i := by
      rw [hg, update_same]
      apply not_mem_erase
    obtain rfl : f = update g i (insert x (g i)) := by
      rw [hg, update_idem, update_same, insert_erase x_mem, update_eq_self]
    clear hg
    rw [update_same, erase_insert hx'] at hr
    refine' step _ _ _ hr (ihs (univ.sigma g) _ _ rfl)
    rw [ssubset_iff_of_subset (sigma_mono (subset.refl _) _)]
    exacts[⟨⟨i, x⟩,
        mem_sigma.2
          ⟨mem_univ _, by
            simp ⟩,
        by
        simp [hx']⟩,
      (@le_update_iffₓ _ _ _ _ g g i _).2 ⟨subset_insert _ _, fun _ _ => le_rflₓ⟩]
    

/-- Given a predicate on functions `Π i, finset (α i)` defined on a finite type, it is true on all
maps provided that it is true on `λ _, ∅` and for any function `g : Π i, finset (α i)`, an index
`i : ι`, and `x ∉ g i`, `p g` implies `p (update g i (insert x (g i)))`.

See also `finset.induction_on_pi_max` and `finset.induction_on_pi_min` for specialized versions
that require `Π i, linear_order (α i)`.  -/
theorem induction_on_pi {p : (∀ i, Finset (α i)) → Prop} (f : ∀ i, Finset (α i)) (h0 : p fun _ => ∅)
    (step : ∀ (g : ∀ i, Finset (α i)) (i : ι) (x : α i) (hx : x ∉ g i), p g → p (update g i (insert x (g i)))) : p f :=
  induction_on_pi_of_choice (fun i x s => x ∉ s) (fun i s ⟨x, hx⟩ => ⟨x, hx, not_mem_erase x s⟩) f h0 step

/-- Given a predicate on functions `Π i, finset (α i)` defined on a finite type, it is true on all
maps provided that it is true on `λ _, ∅` and for any function `g : Π i, finset (α i)`, an index
`i : ι`, and an element`x : α i` that is strictly greater than all elements of `g i`, `p g` implies
`p (update g i (insert x (g i)))`.

This lemma requires `linear_order` instances on all `α i`. See also `finset.induction_on_pi` for a
version that `x ∉ g i` instead of ` does not need `Π i, linear_order (α i)`. -/
theorem induction_on_pi_max [∀ i, LinearOrderₓ (α i)] {p : (∀ i, Finset (α i)) → Prop} (f : ∀ i, Finset (α i))
    (h0 : p fun _ => ∅)
    (step : ∀ (g : ∀ i, Finset (α i)) (i : ι) (x : α i), (∀ y ∈ g i, y < x) → p g → p (update g i (insert x (g i)))) :
    p f :=
  induction_on_pi_of_choice (fun i x s => ∀ y ∈ s, y < x)
    (fun i s hs => ⟨s.max' hs, s.max'_mem hs, fun y => s.lt_max'_of_mem_erase_max' _⟩) f h0 step

/-- Given a predicate on functions `Π i, finset (α i)` defined on a finite type, it is true on all
maps provided that it is true on `λ _, ∅` and for any function `g : Π i, finset (α i)`, an index
`i : ι`, and an element`x : α i` that is strictly less than all elements of `g i`, `p g` implies
`p (update g i (insert x (g i)))`.

This lemma requires `linear_order` instances on all `α i`. See also `finset.induction_on_pi` for a
version that `x ∉ g i` instead of ` does not need `Π i, linear_order (α i)`. -/
theorem induction_on_pi_min [∀ i, LinearOrderₓ (α i)] {p : (∀ i, Finset (α i)) → Prop} (f : ∀ i, Finset (α i))
    (h0 : p fun _ => ∅)
    (step : ∀ (g : ∀ i, Finset (α i)) (i : ι) (x : α i), (∀ y ∈ g i, x < y) → p g → p (update g i (insert x (g i)))) :
    p f :=
  @induction_on_pi_max ι (fun i => (α i)ᵒᵈ) _ _ _ _ _ _ h0 step

end Finset

