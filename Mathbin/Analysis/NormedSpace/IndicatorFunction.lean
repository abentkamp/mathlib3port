import Mathbin.Analysis.Normed.Group.Basic 
import Mathbin.Algebra.IndicatorFunction

/-!
# Indicator function and norm

This file contains a few simple lemmas about `set.indicator` and `norm`.

## Tags
indicator, norm
-/


variable{α E : Type _}[NormedGroup E]{s t : Set α}(f : α → E)(a : α)

open Set

theorem norm_indicator_eq_indicator_norm : ∥indicator s f a∥ = indicator s (fun a => ∥f a∥) a :=
  flip congr_funₓ a (indicator_comp_of_zero norm_zero).symm

theorem nnnorm_indicator_eq_indicator_nnnorm : nnnorm (indicator s f a) = indicator s (fun a => nnnorm (f a)) a :=
  flip congr_funₓ a (indicator_comp_of_zero nnnorm_zero).symm

theorem norm_indicator_le_of_subset (h : s ⊆ t) (f : α → E) (a : α) : ∥indicator s f a∥ ≤ ∥indicator t f a∥ :=
  by 
    simp only [norm_indicator_eq_indicator_norm]
    exact indicator_le_indicator_of_subset ‹_› (fun _ => norm_nonneg _) _

theorem indicator_norm_le_norm_self : indicator s (fun a => ∥f a∥) a ≤ ∥f a∥ :=
  indicator_le_self' (fun _ _ => norm_nonneg _) a

theorem norm_indicator_le_norm_self : ∥indicator s f a∥ ≤ ∥f a∥ :=
  by 
    rw [norm_indicator_eq_indicator_norm]
    apply indicator_norm_le_norm_self

