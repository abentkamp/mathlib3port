/-
Copyright (c) 2022 Mantas Bakšys. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mantas Bakšys
-/
import Mathbin.Algebra.Order.Module
import Mathbin.Data.Prod.Lex
import Mathbin.GroupTheory.Perm.Support
import Mathbin.Order.Monovary
import Mathbin.Tactic.Abel

/-!
# Rearrangement inequality

This file proves the rearrangement inequality and deduces the conditions for equality and strict
inequality.

The rearrangement inequality tells you that for two functions `f g : ι → α`, the sum
`∑ i, f i * g (σ i)` is maximized over all `σ : perm ι` when `g ∘ σ` monovaries with `f` and
minimized when `g ∘ σ` antivaries with `f`.

The inequality also tells you that `∑ i, f i * g (σ i) = ∑ i, f i * g i` if and only if `g ∘ σ`
monovaries with `f` when `g` monovaries with `f`. The above equality also holds if and only if
`g ∘ σ` antivaries with `f` when `g` antivaries with `f`.

From the above two statements, we deduce that the inequality is strict if and only if `g ∘ σ` does
not monovary with `f` when `g` monovaries with `f`. Analogously, the inequality is strict if and
only if `g ∘ σ` does not antivary with `f` when `g` antivaries with `f`.

## Implementation notes

In fact, we don't need much compatibility between the addition and multiplication of `α`, so we can
actually decouple them by replacing multiplication with scalar multiplication and making `f` and `g`
land in different types.
As a bonus, this makes the dual statement trivial. The multiplication versions are provided for
convenience.

The case for `monotone`/`antitone` pairs of functions over a `linear_order` is not deduced in this
file because it is easily deducible from the `monovary` API.
-/


open Equivₓ Equivₓ.Perm Finset Function OrderDual

open BigOperators

variable {ι α β : Type _}

/-! ### Scalar multiplication versions -/


section Smul

variable [LinearOrderedRing α] [LinearOrderedAddCommGroup β] [Module α β] [OrderedSmul α β] {s : Finset ι} {σ : Perm ι}
  {f : ι → α} {g : ι → β}

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is maximized when
`f` and `g` monovary together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_smul_comp_perm_le_sum_smul (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i • g (σ i)) ≤ ∑ i in s, f i • g i := by
  classical
  revert hσ σ hfg
  apply Finset.induction_on_max_value (fun i => toLex (g i, f i)) s
  · simp only [le_rflₓ, Finset.sum_empty, implies_true_iff]
    
  intro a s has hamax hind σ hfg hσ
  set τ : perm ι := σ.trans (swap a (σ a)) with hτ
  have hτs : { x | τ x ≠ x } ⊆ s := by
    intro x hx
    simp only [Ne.def, Set.mem_set_of_eq, Equivₓ.coe_trans, Equivₓ.swap_comp_apply] at hx
    split_ifs  at hx with h₁ h₂ h₃
    · obtain rfl | hax := eq_or_ne x a
      · contradiction
        
      · exact mem_of_mem_insert_of_ne (hσ fun h => hax <| h.symm.trans h₁) hax
        
      
    · exact (hx <| σ.injective h₂.symm).elim
      
    · exact mem_of_mem_insert_of_ne (hσ hx) (ne_of_apply_ne _ h₂)
      
  specialize hind (hfg.subset <| subset_insert _ _) hτs
  simp_rw [sum_insert has]
  refine' le_transₓ _ (add_le_add_left hind _)
  obtain hσa | hσa := eq_or_ne a (σ a)
  · rw [hτ, ← hσa, swap_self, trans_refl]
    
  have h1s : σ⁻¹ a ∈ s := by
    rw [Ne.def, ← inv_eq_iff_eq] at hσa
    refine' mem_of_mem_insert_of_ne (hσ fun h => hσa _) hσa
    rwa [apply_inv_self, eq_comm] at h
  simp only [← s.sum_erase_add _ h1s, add_commₓ]
  rw [← add_assocₓ, ← add_assocₓ]
  simp only [hτ, swap_apply_left, Function.comp_app, Equivₓ.coe_trans, apply_inv_self]
  refine' add_le_add (smul_add_smul_le_smul_add_smul' _ _) ((sum_congr rfl) fun x hx => _).le
  · specialize hamax (σ⁻¹ a) h1s
    rw [Prod.Lex.le_iff] at hamax
    cases hamax
    · exact hfg (mem_insert_of_mem h1s) (mem_insert_self _ _) hamax
      
    · exact hamax.2
      
    
  · specialize hamax (σ a) (mem_of_mem_insert_of_ne (hσ <| σ.injective.ne hσa.symm) hσa.symm)
    rw [Prod.Lex.le_iff] at hamax
    cases hamax
    · exact hamax.le
      
    · exact hamax.1.le
      
    
  · rw [mem_erase, Ne.def, eq_inv_iff_eq] at hx
    rw [swap_apply_of_ne_of_ne hx.1 (σ.injective.ne _)]
    rintro rfl
    exact has hx.2
    

/-- **Equality case of Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` monovary
together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_smul_comp_perm_eq_sum_smul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g (σ i)) = ∑ i in s, f i • g i) ↔ MonovaryOn f (g ∘ σ) s := by
  classical
  refine' ⟨not_imp_not.1 fun h => _, fun h => (hfg.sum_smul_comp_perm_le_sum_smul hσ).antisymm _⟩
  · rw [MonovaryOn] at h
    push_neg  at h
    obtain ⟨x, hx, y, hy, hgxy, hfxy⟩ := h
    set τ : perm ι := (swap x y).trans σ
    have hτs : { x | τ x ≠ x } ⊆ s := by
      refine' (set_support_mul_subset σ <| swap x y).trans ((Set.union_subset hσ) fun z hz => _)
      obtain ⟨_, rfl | rfl⟩ := swap_apply_ne_self_iff.1 hz <;> assumption
    refine' ((hfg.sum_smul_comp_perm_le_sum_smul hτs).trans_lt' _).Ne
    obtain rfl | hxy := eq_or_ne x y
    · cases lt_irreflₓ _ hfxy
      
    simp only [← s.sum_erase_add _ hx, ← (s.erase x).sum_erase_add _ (mem_erase.2 ⟨hxy.symm, hy⟩), add_assocₓ,
      Equivₓ.coe_trans, Function.comp_app, swap_apply_right, swap_apply_left]
    refine' add_lt_add_of_le_of_lt ((Finset.sum_congr rfl) fun z hz => _).le (smul_add_smul_lt_smul_add_smul hfxy hgxy)
    simp_rw [mem_erase] at hz
    rw [swap_apply_of_ne_of_ne hz.2.1 hz.1]
    
  · convert h.sum_smul_comp_perm_le_sum_smul ((set_support_inv_eq _).Subset.trans hσ) using 1
    simp_rw [Function.comp_app, apply_inv_self]
    

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_smul_comp_perm_lt_sum_smul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g (σ i)) < ∑ i in s, f i • g i) ↔ ¬MonovaryOn f (g ∘ σ) s := by
  simp [← hfg.sum_smul_comp_perm_eq_sum_smul_iff hσ, lt_iff_le_and_neₓ, hfg.sum_smul_comp_perm_le_sum_smul hσ]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is maximized when
`f` and `g` monovary together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_smul_le_sum_smul (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f (σ i) • g i) ≤ ∑ i in s, f i • g i := by
  convert
    hfg.sum_smul_comp_perm_le_sum_smul
      (show { x | σ⁻¹ x ≠ x } ⊆ s by
        simp only [set_support_inv_eq, hσ]) using
    1
  exact σ.sum_comp' s (fun i j => f i • g j) hσ

/-- **Equality case of Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` monovary
together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_smul_eq_sum_smul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) • g i) = ∑ i in s, f i • g i) ↔ MonovaryOn (f ∘ σ) g s := by
  have hσinv : { x | σ⁻¹ x ≠ x } ⊆ s := (set_support_inv_eq _).Subset.trans hσ
  refine' (Iff.trans _ <| hfg.sum_smul_comp_perm_eq_sum_smul_iff hσinv).trans ⟨fun h => _, fun h => _⟩
  · simpa only [σ.sum_comp' s (fun i j => f i • g j) hσ]
    
  · convert h.comp_right σ
    · rw [comp.assoc, inv_def, symm_comp_self, comp.right_id]
      
    · rw [σ.eq_preimage_iff_image_eq, Set.image_perm hσ]
      
    
  · convert h.comp_right σ.symm
    · rw [comp.assoc, self_comp_symm, comp.right_id]
      
    · rw [σ.symm.eq_preimage_iff_image_eq]
      exact Set.image_perm hσinv
      
    

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not monovary together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_smul_lt_sum_smul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) • g i) < ∑ i in s, f i • g i) ↔ ¬MonovaryOn (f ∘ σ) g s := by
  simp [← hfg.sum_comp_perm_smul_eq_sum_smul_iff hσ, lt_iff_le_and_neₓ, hfg.sum_comp_perm_smul_le_sum_smul hσ]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is minimized when
`f` and `g` antivary together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_smul_le_sum_smul_comp_perm (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i • g i) ≤ ∑ i in s, f i • g (σ i) :=
  hfg.dual_right.sum_smul_comp_perm_le_sum_smul hσ

/-- **Equality case of the Rearrangement Inequality**: Pointwise scalar multiplication of `f` and
`g`, which antivary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` antivary
together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_smul_eq_sum_smul_comp_perm_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g (σ i)) = ∑ i in s, f i • g i) ↔ AntivaryOn f (g ∘ σ) s :=
  (hfg.dual_right.sum_smul_comp_perm_eq_sum_smul_iff hσ).trans monovary_on_to_dual_right

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not antivary together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_smul_lt_sum_smul_comp_perm_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g i) < ∑ i in s, f i • g (σ i)) ↔ ¬AntivaryOn f (g ∘ σ) s := by
  simp [← hfg.sum_smul_eq_sum_smul_comp_perm_iff hσ, lt_iff_le_and_neₓ, eq_comm, hfg.sum_smul_le_sum_smul_comp_perm hσ]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is minimized when
`f` and `g` antivary together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_smul_le_sum_comp_perm_smul (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i • g i) ≤ ∑ i in s, f (σ i) • g i :=
  hfg.dual_right.sum_comp_perm_smul_le_sum_smul hσ

/-- **Equality case of the Rearrangement Inequality**: Pointwise scalar multiplication of `f` and
`g`, which antivary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` antivary
together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_smul_eq_sum_comp_perm_smul_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) • g i) = ∑ i in s, f i • g i) ↔ AntivaryOn (f ∘ σ) g s :=
  (hfg.dual_right.sum_comp_perm_smul_eq_sum_smul_iff hσ).trans monovary_on_to_dual_right

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not antivary together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_smul_lt_sum_comp_perm_smul_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g i) < ∑ i in s, f (σ i) • g i) ↔ ¬AntivaryOn (f ∘ σ) g s := by
  simp [← hfg.sum_smul_eq_sum_comp_perm_smul_iff hσ, eq_comm, lt_iff_le_and_neₓ, hfg.sum_smul_le_sum_comp_perm_smul hσ]

variable [Fintype ι]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is maximized when
`f` and `g` monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_smul_comp_perm_le_sum_smul (hfg : Monovary f g) : (∑ i, f i • g (σ i)) ≤ ∑ i, f i • g i :=
  (hfg.MonovaryOn _).sum_smul_comp_perm_le_sum_smul fun i _ => mem_univ _

/-- **Equality case of Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` monovary
together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_smul_comp_perm_eq_sum_smul_iff (hfg : Monovary f g) :
    ((∑ i, f i • g (σ i)) = ∑ i, f i • g i) ↔ Monovary f (g ∘ σ) := by
  simp [(hfg.monovary_on _).sum_smul_comp_perm_eq_sum_smul_iff fun i _ => mem_univ _]

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_smul_comp_perm_lt_sum_smul_iff (hfg : Monovary f g) :
    ((∑ i, f i • g (σ i)) < ∑ i, f i • g i) ↔ ¬Monovary f (g ∘ σ) := by
  simp [(hfg.monovary_on _).sum_smul_comp_perm_lt_sum_smul_iff fun i _ => mem_univ _]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is maximized when
`f` and `g` monovary together. Stated by permuting the entries of `f`. -/
theorem Monovary.sum_comp_perm_smul_le_sum_smul (hfg : Monovary f g) : (∑ i, f (σ i) • g i) ≤ ∑ i, f i • g i :=
  (hfg.MonovaryOn _).sum_comp_perm_smul_le_sum_smul fun i _ => mem_univ _

/-- **Equality case of Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` monovary
together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_comp_perm_smul_eq_sum_smul_iff (hfg : Monovary f g) :
    ((∑ i, f (σ i) • g i) = ∑ i, f i • g i) ↔ Monovary (f ∘ σ) g := by
  simp [(hfg.monovary_on _).sum_comp_perm_smul_eq_sum_smul_iff fun i _ => mem_univ _]

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_comp_perm_smul_lt_sum_smul_iff (hfg : Monovary f g) :
    ((∑ i, f (σ i) • g i) < ∑ i, f i • g i) ↔ ¬Monovary (f ∘ σ) g := by
  simp [(hfg.monovary_on _).sum_comp_perm_smul_lt_sum_smul_iff fun i _ => mem_univ _]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is minimized when
`f` and `g` antivary together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_smul_le_sum_smul_comp_perm (hfg : Antivary f g) : (∑ i, f i • g i) ≤ ∑ i, f i • g (σ i) :=
  (hfg.AntivaryOn _).sum_smul_le_sum_smul_comp_perm fun i _ => mem_univ _

/-- **Equality case of the Rearrangement Inequality**: Pointwise scalar multiplication of `f` and
`g`, which antivary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` antivary
together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_smul_eq_sum_smul_comp_perm_iff (hfg : Antivary f g) :
    ((∑ i, f i • g (σ i)) = ∑ i, f i • g i) ↔ Antivary f (g ∘ σ) := by
  simp [(hfg.antivary_on _).sum_smul_eq_sum_smul_comp_perm_iff fun i _ => mem_univ _]

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not antivary together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_smul_lt_sum_smul_comp_perm_iff (hfg : Antivary f g) :
    ((∑ i, f i • g i) < ∑ i, f i • g (σ i)) ↔ ¬Antivary f (g ∘ σ) := by
  simp [(hfg.antivary_on _).sum_smul_lt_sum_smul_comp_perm_iff fun i _ => mem_univ _]

/-- **Rearrangement Inequality**: Pointwise scalar multiplication of `f` and `g` is minimized when
`f` and `g` antivary together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_smul_le_sum_comp_perm_smul (hfg : Antivary f g) : (∑ i, f i • g i) ≤ ∑ i, f (σ i) • g i :=
  (hfg.AntivaryOn _).sum_smul_le_sum_comp_perm_smul fun i _ => mem_univ _

/-- **Equality case of the Rearrangement Inequality**: Pointwise scalar multiplication of `f` and
`g`, which antivary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` antivary
together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_smul_eq_sum_comp_perm_smul_iff (hfg : Antivary f g) :
    ((∑ i, f (σ i) • g i) = ∑ i, f i • g i) ↔ Antivary (f ∘ σ) g := by
  simp [(hfg.antivary_on _).sum_smul_eq_sum_comp_perm_smul_iff fun i _ => mem_univ _]

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not antivary together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_smul_lt_sum_comp_perm_smul_iff (hfg : Antivary f g) :
    ((∑ i, f i • g i) < ∑ i, f (σ i) • g i) ↔ ¬Antivary (f ∘ σ) g := by
  simp [(hfg.antivary_on _).sum_smul_lt_sum_comp_perm_smul_iff fun i _ => mem_univ _]

end Smul

/-!
### Multiplication versions

Special cases of the above when scalar multiplication is actually multiplication.
-/


section Mul

variable [LinearOrderedRing α] {s : Finset ι} {σ : Perm ι} {f g : ι → α}

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is maximized when `f` and
`g` monovary together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_mul_comp_perm_le_sum_mul (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i * g (σ i)) ≤ ∑ i in s, f i * g i :=
  hfg.sum_smul_comp_perm_le_sum_smul hσ

/-- **Equality case of Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` monovary
together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_mul_comp_perm_eq_sum_mul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i * g (σ i)) = ∑ i in s, f i * g i) ↔ MonovaryOn f (g ∘ σ) s :=
  hfg.sum_smul_comp_perm_eq_sum_smul_iff hσ

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise scalar multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem MonovaryOn.sum_mul_comp_perm_lt_sum_mul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i • g (σ i)) < ∑ i in s, f i • g i) ↔ ¬MonovaryOn f (g ∘ σ) s :=
  hfg.sum_smul_comp_perm_lt_sum_smul_iff hσ

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is maximized when `f` and
`g` monovary together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_mul_le_sum_mul (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f (σ i) * g i) ≤ ∑ i in s, f i * g i :=
  hfg.sum_comp_perm_smul_le_sum_smul hσ

/-- **Equality case of Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` monovary
together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_mul_eq_sum_mul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) * g i) = ∑ i in s, f i * g i) ↔ MonovaryOn (f ∘ σ) g s :=
  hfg.sum_comp_perm_smul_eq_sum_smul_iff hσ

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not monovary together. Stated by permuting the entries of `f`. -/
theorem MonovaryOn.sum_comp_perm_mul_lt_sum_mul_iff (hfg : MonovaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) * g i) < ∑ i in s, f i * g i) ↔ ¬MonovaryOn (f ∘ σ) g s :=
  hfg.sum_comp_perm_smul_lt_sum_smul_iff hσ

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is minimized when `f` and
`g` antivary together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_mul_le_sum_mul_comp_perm (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i * g i) ≤ ∑ i in s, f i * g (σ i) :=
  hfg.sum_smul_le_sum_smul_comp_perm hσ

/-- **Equality case of the Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which antivary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` antivary
together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_mul_eq_sum_mul_comp_perm_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i * g (σ i)) = ∑ i in s, f i * g i) ↔ AntivaryOn f (g ∘ σ) s :=
  hfg.sum_smul_eq_sum_smul_comp_perm_iff hσ

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not antivary together. Stated by permuting the entries of `g`. -/
theorem AntivaryOn.sum_mul_lt_sum_mul_comp_perm_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i * g i) < ∑ i in s, f i * g (σ i)) ↔ ¬AntivaryOn f (g ∘ σ) s :=
  hfg.sum_smul_lt_sum_smul_comp_perm_iff hσ

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is minimized when `f` and
`g` antivary together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_mul_le_sum_comp_perm_mul (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    (∑ i in s, f i * g i) ≤ ∑ i in s, f (σ i) * g i :=
  hfg.sum_smul_le_sum_comp_perm_smul hσ

/-- **Equality case of the Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which antivary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` antivary
together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_mul_eq_sum_comp_perm_mul_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f (σ i) * g i) = ∑ i in s, f i * g i) ↔ AntivaryOn (f ∘ σ) g s :=
  hfg.sum_smul_eq_sum_comp_perm_smul_iff hσ

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not antivary together. Stated by permuting the entries of `f`. -/
theorem AntivaryOn.sum_mul_lt_sum_comp_perm_mul_iff (hfg : AntivaryOn f g s) (hσ : { x | σ x ≠ x } ⊆ s) :
    ((∑ i in s, f i * g i) < ∑ i in s, f (σ i) * g i) ↔ ¬AntivaryOn (f ∘ σ) g s :=
  hfg.sum_smul_lt_sum_comp_perm_smul_iff hσ

variable [Fintype ι]

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is maximized when `f` and
`g` monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_mul_comp_perm_le_sum_mul (hfg : Monovary f g) : (∑ i, f i * g (σ i)) ≤ ∑ i, f i * g i :=
  hfg.sum_smul_comp_perm_le_sum_smul

/-- **Equality case of Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` monovary
together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_mul_comp_perm_eq_sum_mul_iff (hfg : Monovary f g) :
    ((∑ i, f i * g (σ i)) = ∑ i, f i * g i) ↔ Monovary f (g ∘ σ) :=
  hfg.sum_smul_comp_perm_eq_sum_smul_iff

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_mul_comp_perm_lt_sum_mul_iff (hfg : Monovary f g) :
    ((∑ i, f i * g (σ i)) < ∑ i, f i * g i) ↔ ¬Monovary f (g ∘ σ) :=
  hfg.sum_smul_comp_perm_lt_sum_smul_iff

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is maximized when `f` and
`g` monovary together. Stated by permuting the entries of `f`. -/
theorem Monovary.sum_comp_perm_mul_le_sum_mul (hfg : Monovary f g) : (∑ i, f (σ i) * g i) ≤ ∑ i, f i * g i :=
  hfg.sum_comp_perm_smul_le_sum_smul

/-- **Equality case of Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which monovary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` monovary
together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_comp_perm_mul_eq_sum_mul_iff (hfg : Monovary f g) :
    ((∑ i, f (σ i) * g i) = ∑ i, f i * g i) ↔ Monovary (f ∘ σ) g :=
  hfg.sum_comp_perm_smul_eq_sum_smul_iff

/-- **Strict inequality case of Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which monovary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not monovary together. Stated by permuting the entries of `g`. -/
theorem Monovary.sum_comp_perm_mul_lt_sum_mul_iff (hfg : Monovary f g) :
    ((∑ i, f (σ i) * g i) < ∑ i, f i * g i) ↔ ¬Monovary (f ∘ σ) g :=
  hfg.sum_comp_perm_smul_lt_sum_smul_iff

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is minimized when `f` and
`g` antivary together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_mul_le_sum_mul_comp_perm (hfg : Antivary f g) : (∑ i, f i * g i) ≤ ∑ i, f i * g (σ i) :=
  hfg.sum_smul_le_sum_smul_comp_perm

/-- **Equality case of the Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which antivary together, is unchanged by a permutation if and only if `f` and `g ∘ σ` antivary
together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_mul_eq_sum_mul_comp_perm_iff (hfg : Antivary f g) :
    ((∑ i, f i * g (σ i)) = ∑ i, f i * g i) ↔ Antivary f (g ∘ σ) :=
  hfg.sum_smul_eq_sum_smul_comp_perm_iff

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f` and `g ∘ σ` do not antivary together. Stated by permuting the entries of `g`. -/
theorem Antivary.sum_mul_lt_sum_mul_comp_perm_iff (hfg : Antivary f g) :
    ((∑ i, f i • g i) < ∑ i, f i • g (σ i)) ↔ ¬Antivary f (g ∘ σ) :=
  hfg.sum_smul_lt_sum_smul_comp_perm_iff

/-- **Rearrangement Inequality**: Pointwise multiplication of `f` and `g` is minimized when `f` and
`g` antivary together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_mul_le_sum_comp_perm_mul (hfg : Antivary f g) : (∑ i, f i * g i) ≤ ∑ i, f (σ i) * g i :=
  hfg.sum_smul_le_sum_comp_perm_smul

/-- **Equality case of the Rearrangement Inequality**: Pointwise multiplication of `f` and `g`,
which antivary together, is unchanged by a permutation if and only if `f ∘ σ` and `g` antivary
together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_mul_eq_sum_comp_perm_mul_iff (hfg : Antivary f g) :
    ((∑ i, f (σ i) * g i) = ∑ i, f i * g i) ↔ Antivary (f ∘ σ) g :=
  hfg.sum_smul_eq_sum_comp_perm_smul_iff

/-- **Strict inequality case of the Rearrangement Inequality**: Pointwise multiplication of
`f` and `g`, which antivary together, is strictly decreased by a permutation if and only if
`f ∘ σ` and `g` do not antivary together. Stated by permuting the entries of `f`. -/
theorem Antivary.sum_mul_lt_sum_comp_perm_mul_iff (hfg : Antivary f g) :
    ((∑ i, f i * g i) < ∑ i, f (σ i) * g i) ↔ ¬Antivary (f ∘ σ) g :=
  hfg.sum_smul_lt_sum_comp_perm_smul_iff

end Mul

