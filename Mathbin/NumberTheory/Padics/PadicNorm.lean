/-
Copyright (c) 2018 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Robert Y. Lewis
-/
import Mathbin.NumberTheory.Padics.PadicVal

/-!
# p-adic norm

This file defines the p-adic norm on ℚ.

The p-adic valuation on ℚ is the difference of the multiplicities of `p` in the numerator and
denominator of `q`. This function obeys the standard properties of a valuation, with the appropriate
assumptions on p.

The valuation induces a norm on ℚ. This norm is a nonarchimedean absolute value.
It takes values in {0} ∪ {1/p^k | k ∈ ℤ}.

## Notations

This file uses the local notation `/.` for `rat.mk`.

## Implementation notes

Much, but not all, of this file assumes that `p` is prime. This assumption is inferred automatically
by taking `[fact (prime p)]` as a type class argument.

## References

* [F. Q. Gouvêa, *p-adic numbers*][gouvea1997]
* [R. Y. Lewis, *A formal proof of Hensel's lemma over the p-adic integers*][lewis2019]
* <https://en.wikipedia.org/wiki/P-adic_number>

## Tags

p-adic, p adic, padic, norm, valuation
-/


/-- If `q ≠ 0`, the p-adic norm of a rational `q` is `p ^ (-(padic_val_rat p q))`.
If `q = 0`, the p-adic norm of `q` is 0.
-/
def padicNorm (p : ℕ) (q : ℚ) : ℚ :=
  if q = 0 then 0 else (↑p : ℚ) ^ -padicValRat p q

namespace padicNorm

open padicValRat

variable (p : ℕ)

/-- Unfolds the definition of the p-adic norm of `q` when `q ≠ 0`. -/
@[simp]
protected theorem eq_zpow_of_nonzero {q : ℚ} (hq : q ≠ 0) : padicNorm p q = p ^ -padicValRat p q := by
  simp [hq, padicNorm]

/-- The p-adic norm is nonnegative. -/
protected theorem nonneg (q : ℚ) : 0 ≤ padicNorm p q :=
  if hq : q = 0 then by
    simp [hq, padicNorm]
  else by
    unfold padicNorm <;> split_ifs
    apply zpow_nonneg
    exact_mod_cast Nat.zero_leₓ _

/-- The p-adic norm of 0 is 0. -/
@[simp]
protected theorem zero : padicNorm p 0 = 0 := by
  simp [padicNorm]

/-- The p-adic norm of 1 is 1. -/
@[simp]
protected theorem one : padicNorm p 1 = 1 := by
  simp [padicNorm]

/-- The p-adic norm of `p` is `1/p` if `p > 1`.

See also `padic_norm.padic_norm_p_of_prime` for a version that assumes `p` is prime.
-/
theorem padic_norm_p {p : ℕ} (hp : 1 < p) : padicNorm p p = 1 / p := by
  simp [padicNorm, (pos_of_gt hp).ne', padicValNat.self hp]

/-- The p-adic norm of `p` is `1/p` if `p` is prime.

See also `padic_norm.padic_norm_p` for a version that assumes `1 < p`.
-/
@[simp]
theorem padic_norm_p_of_prime (p : ℕ) [Fact p.Prime] : padicNorm p p = 1 / p :=
  padic_norm_p <| Nat.Prime.one_lt (Fact.out _)

/-- The p-adic norm of `q` is `1` if `q` is prime and not equal to `p`. -/
theorem padic_norm_of_prime_of_ne {p q : ℕ} [p_prime : Fact p.Prime] [q_prime : Fact q.Prime] (neq : p ≠ q) :
    padicNorm p q = 1 := by
  have p : padicValRat p q = 0 := by
    exact_mod_cast @padic_val_nat_primes p q p_prime q_prime neq
  simp [padicNorm, p, q_prime.1.1, q_prime.1.ne_zero]

/-- The p-adic norm of `p` is less than 1 if `1 < p`.

See also `padic_norm.padic_norm_p_lt_one_of_prime` for a version assuming `prime p`.
-/
theorem padic_norm_p_lt_one {p : ℕ} (hp : 1 < p) : padicNorm p p < 1 := by
  rw [padic_norm_p hp, div_lt_iff, one_mulₓ]
  · exact_mod_cast hp
    
  · exact_mod_cast zero_lt_one.trans hp
    

/-- The p-adic norm of `p` is less than 1 if `p` is prime.

See also `padic_norm.padic_norm_p_lt_one` for a version assuming `1 < p`.
-/
theorem padic_norm_p_lt_one_of_prime (p : ℕ) [Fact p.Prime] : padicNorm p p < 1 :=
  padic_norm_p_lt_one <| Nat.Prime.one_lt (Fact.out _)

/-- `padic_norm p q` takes discrete values `p ^ -z` for `z : ℤ`. -/
protected theorem values_discrete {q : ℚ} (hq : q ≠ 0) : ∃ z : ℤ, padicNorm p q = p ^ -z :=
  ⟨padicValRat p q, by
    simp [padicNorm, hq]⟩

/-- `padic_norm p` is symmetric. -/
@[simp]
protected theorem neg (q : ℚ) : padicNorm p (-q) = padicNorm p q :=
  if hq : q = 0 then by
    simp [hq]
  else by
    simp [padicNorm, hq]

variable [hp : Fact p.Prime]

include hp

/-- If `q ≠ 0`, then `padic_norm p q ≠ 0`. -/
protected theorem nonzero {q : ℚ} (hq : q ≠ 0) : padicNorm p q ≠ 0 := by
  rw [padicNorm.eq_zpow_of_nonzero p hq]
  apply zpow_ne_zero_of_ne_zero
  exact_mod_cast ne_of_gtₓ hp.1.Pos

/-- If the p-adic norm of `q` is 0, then `q` is 0. -/
theorem zero_of_padic_norm_eq_zero {q : ℚ} (h : padicNorm p q = 0) : q = 0 := by
  apply by_contradiction
  intro hq
  unfold padicNorm  at h
  rw [if_neg hq] at h
  apply absurd h
  apply zpow_ne_zero_of_ne_zero
  exact_mod_cast hp.1.ne_zero

/-- The p-adic norm is multiplicative. -/
@[simp]
protected theorem mul (q r : ℚ) : padicNorm p (q * r) = padicNorm p q * padicNorm p r :=
  if hq : q = 0 then by
    simp [hq]
  else
    if hr : r = 0 then by
      simp [hr]
    else by
      have : q * r ≠ 0 := mul_ne_zero hq hr
      have : (↑p : ℚ) ≠ 0 := by
        simp [hp.1.ne_zero]
      simp [padicNorm, *, padicValRat.mul, zpow_add₀ this, mul_comm]

/-- The p-adic norm respects division. -/
@[simp]
protected theorem div (q r : ℚ) : padicNorm p (q / r) = padicNorm p q / padicNorm p r :=
  if hr : r = 0 then by
    simp [hr]
  else
    eq_div_of_mul_eq (padicNorm.nonzero _ hr)
      (by
        rw [← padicNorm.mul, div_mul_cancel _ hr])

/-- The p-adic norm of an integer is at most 1. -/
protected theorem of_int (z : ℤ) : padicNorm p ↑z ≤ 1 :=
  if hz : z = 0 then by
    simp [hz, zero_le_one]
  else by
    unfold padicNorm
    rw [if_neg _]
    · refine' zpow_le_one_of_nonpos _ _
      · exact_mod_cast le_of_ltₓ hp.1.one_lt
        
      · rw [padicValRat.of_int, neg_nonpos]
        norm_cast
        simp
        
      
    exact_mod_cast hz

private theorem nonarchimedean_aux {q r : ℚ} (h : padicValRat p q ≤ padicValRat p r) :
    padicNorm p (q + r) ≤ max (padicNorm p q) (padicNorm p r) :=
  have hnqp : padicNorm p q ≥ 0 := padicNorm.nonneg _ _
  have hnrp : padicNorm p r ≥ 0 := padicNorm.nonneg _ _
  if hq : q = 0 then by
    simp [hq, max_eq_rightₓ hnrp, le_max_rightₓ]
  else
    if hr : r = 0 then by
      simp [hr, max_eq_leftₓ hnqp, le_max_leftₓ]
    else
      if hqr : q + r = 0 then
        le_transₓ
          (by
            simpa [hqr] using hnqp)
          (le_max_leftₓ _ _)
      else by
        unfold padicNorm
        split_ifs
        apply le_max_iff.2
        left
        apply zpow_le_of_le
        · exact_mod_cast le_of_ltₓ hp.1.one_lt
          
        · apply neg_le_neg
          have : padicValRat p q = min (padicValRat p q) (padicValRat p r) := (min_eq_leftₓ h).symm
          rw [this]
          apply min_le_padic_val_rat_add <;> assumption
          

/-- The p-adic norm is nonarchimedean: the norm of `p + q` is at most the max of the norm of `p` and
the norm of `q`.
-/
protected theorem nonarchimedean {q r : ℚ} : padicNorm p (q + r) ≤ max (padicNorm p q) (padicNorm p r) := by
  wlog hle := le_totalₓ (padicValRat p q) (padicValRat p r) using q r
  exact nonarchimedean_aux p hle

/-- The p-adic norm respects the triangle inequality: the norm of `p + q` is at most the norm of `p`
plus the norm of `q`.
-/
theorem triangle_ineq (q r : ℚ) : padicNorm p (q + r) ≤ padicNorm p q + padicNorm p r :=
  calc
    padicNorm p (q + r) ≤ max (padicNorm p q) (padicNorm p r) := padicNorm.nonarchimedean p
    _ ≤ padicNorm p q + padicNorm p r := max_le_add_of_nonneg (padicNorm.nonneg p _) (padicNorm.nonneg p _)
    

/-- The p-adic norm of a difference is at most the max of each component. Restates the archimedean
property of the p-adic norm.
-/
protected theorem sub {q r : ℚ} : padicNorm p (q - r) ≤ max (padicNorm p q) (padicNorm p r) := by
  rw [sub_eq_add_neg, ← padicNorm.neg p r] <;> apply padicNorm.nonarchimedean

/-- If the p-adic norms of `q` and `r` are different, then the norm of `q + r` is equal to the max of
the norms of `q` and `r`.
-/
theorem add_eq_max_of_ne {q r : ℚ} (hne : padicNorm p q ≠ padicNorm p r) :
    padicNorm p (q + r) = max (padicNorm p q) (padicNorm p r) := by
  wlog hle := le_totalₓ (padicNorm p r) (padicNorm p q) using q r
  have hlt : padicNorm p r < padicNorm p q := lt_of_le_of_neₓ hle hne.symm
  have : padicNorm p q ≤ max (padicNorm p (q + r)) (padicNorm p r) :=
    calc
      padicNorm p q = padicNorm p (q + r - r) := by
        congr <;> ring
      _ ≤ max (padicNorm p (q + r)) (padicNorm p (-r)) := padicNorm.nonarchimedean p
      _ = max (padicNorm p (q + r)) (padicNorm p r) := by
        simp
      
  have hnge : padicNorm p r ≤ padicNorm p (q + r) := by
    apply le_of_not_gtₓ
    intro hgt
    rw [max_eq_right_of_ltₓ hgt] at this
    apply not_lt_of_geₓ this
    assumption
  have : padicNorm p q ≤ padicNorm p (q + r) := by
    rwa [max_eq_leftₓ hnge] at this
  apply _root_.le_antisymm
  · apply padicNorm.nonarchimedean p
    
  · rw [max_eq_left_of_ltₓ hlt]
    assumption
    

/-- The p-adic norm is an absolute value: positive-definite and multiplicative, satisfying the triangle
inequality.
-/
instance : IsAbsoluteValue (padicNorm p) where
  abv_nonneg := padicNorm.nonneg p
  abv_eq_zero := by
    intros
    constructor <;> intro
    · apply zero_of_padic_norm_eq_zero p
      assumption
      
    · simp [*]
      
  abv_add := padicNorm.triangle_ineq p
  abv_mul := padicNorm.mul p

variable {p}

theorem dvd_iff_norm_le {n : ℕ} {z : ℤ} : ↑(p ^ n) ∣ z ↔ padicNorm p z ≤ ↑p ^ (-n : ℤ) := by
  unfold padicNorm
  split_ifs with hz
  · norm_cast  at hz
    have : 0 ≤ (p ^ n : ℚ) := by
      apply pow_nonneg
      exact_mod_cast le_of_ltₓ hp.1.Pos
    simp [hz, this]
    
  · rw [zpow_le_iff_le, neg_le_neg_iff, padicValRat.of_int, padicValInt.of_ne_one_ne_zero hp.1.ne_one _]
    · norm_cast
      rw [← PartEnat.coe_le_coe, PartEnat.coe_get, ← multiplicity.pow_dvd_iff_le_multiplicity]
      simp
      
    · exact_mod_cast hz
      
    · exact_mod_cast hp.1.one_lt
      
    

/-- The `p`-adic norm of an integer `m` is one iff `p` doesn't divide `m`. -/
theorem int_eq_one_iff (m : ℤ) : padicNorm p m = 1 ↔ ¬(p : ℤ) ∣ m := by
  nth_rw 1[← pow_oneₓ p]
  simp only [dvd_iff_norm_le, Int.cast_coe_nat, Nat.cast_oneₓ, zpow_neg, zpow_one, not_leₓ]
  constructor
  · intro h
    rw [h, inv_lt_one_iff_of_pos] <;> norm_cast
    · exact Nat.Prime.one_lt (Fact.out _)
      
    · exact Nat.Prime.pos (Fact.out _)
      
    
  · simp only [padicNorm]
    split_ifs
    · rw [inv_lt_zero, ← Nat.cast_zeroₓ, Nat.cast_lt]
      intro h
      exact (Nat.not_lt_zeroₓ p h).elim
      
    · have : 1 < (p : ℚ) := by
        norm_cast <;> exact Nat.Prime.one_lt (Fact.out _ : Nat.Prime p)
      rw [← zpow_neg_one, zpow_lt_iff_lt this]
      have : 0 ≤ padicValRat p m
      simp only [of_int, Nat.cast_nonneg]
      intro h
      rw [← zpow_zero (p : ℚ), zpow_inj] <;> linarith
      
    

theorem int_lt_one_iff (m : ℤ) : padicNorm p m < 1 ↔ (p : ℤ) ∣ m := by
  rw [← not_iff_not, ← int_eq_one_iff, eq_iff_le_not_ltₓ]
  simp only [padicNorm.of_int, true_andₓ]

theorem of_nat (m : ℕ) : padicNorm p m ≤ 1 :=
  padicNorm.of_int p (m : ℤ)

/-- The `p`-adic norm of a natural `m` is one iff `p` doesn't divide `m`. -/
theorem nat_eq_one_iff (m : ℕ) : padicNorm p m = 1 ↔ ¬p ∣ m := by
  simp only [← Int.coe_nat_dvd, ← int_eq_one_iff, Int.cast_coe_nat]

theorem nat_lt_one_iff (m : ℕ) : padicNorm p m < 1 ↔ p ∣ m := by
  simp only [← Int.coe_nat_dvd, ← int_lt_one_iff, Int.cast_coe_nat]

open BigOperators

theorem sum_lt {α : Type _} {F : α → ℚ} {t : ℚ} {s : Finset α} :
    s.Nonempty → (∀ i ∈ s, padicNorm p (F i) < t) → padicNorm p (∑ i in s, F i) < t := by
  classical
  refine'
    s.induction_on
      (by
        rintro ⟨-, ⟨⟩⟩)
      _
  rintro a S haS IH - ht
  by_cases' hs : S.nonempty
  · rw [Finset.sum_insert haS]
    exact
      lt_of_le_of_ltₓ (padicNorm.nonarchimedean p)
        (max_ltₓ (ht a (Finset.mem_insert_self a S)) (IH hs fun b hb => ht b (Finset.mem_insert_of_mem hb)))
    
  · simp_all
    

theorem sum_le {α : Type _} {F : α → ℚ} {t : ℚ} {s : Finset α} :
    s.Nonempty → (∀ i ∈ s, padicNorm p (F i) ≤ t) → padicNorm p (∑ i in s, F i) ≤ t := by
  classical
  refine'
    s.induction_on
      (by
        rintro ⟨-, ⟨⟩⟩)
      _
  rintro a S haS IH - ht
  by_cases' hs : S.nonempty
  · rw [Finset.sum_insert haS]
    exact
      (padicNorm.nonarchimedean p).trans
        (max_leₓ (ht a (Finset.mem_insert_self a S)) (IH hs fun b hb => ht b (Finset.mem_insert_of_mem hb)))
    
  · simp_all
    

theorem sum_lt' {α : Type _} {F : α → ℚ} {t : ℚ} {s : Finset α} (hF : ∀ i ∈ s, padicNorm p (F i) < t) (ht : 0 < t) :
    padicNorm p (∑ i in s, F i) < t := by
  obtain rfl | hs := Finset.eq_empty_or_nonempty s
  · simp [ht]
    
  · exact sum_lt hs hF
    

theorem sum_le' {α : Type _} {F : α → ℚ} {t : ℚ} {s : Finset α} (hF : ∀ i ∈ s, padicNorm p (F i) ≤ t) (ht : 0 ≤ t) :
    padicNorm p (∑ i in s, F i) ≤ t := by
  obtain rfl | hs := Finset.eq_empty_or_nonempty s
  · simp [ht]
    
  · exact sum_le hs hF
    

end padicNorm

