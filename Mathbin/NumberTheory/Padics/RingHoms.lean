/-
Copyright (c) 2020 Johan Commelin, Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Robert Y. Lewis
-/
import Mathbin.Data.Zmod.Basic
import Mathbin.NumberTheory.Padics.PadicIntegers

/-!

# Relating `ℤ_[p]` to `zmod (p ^ n)`

In this file we establish connections between the `p`-adic integers $\mathbb{Z}_p$
and the integers modulo powers of `p`, $\mathbb{Z}/p^n\mathbb{Z}$.

## Main declarations

We show that $\mathbb{Z}_p$ has a ring hom to $\mathbb{Z}/p^n\mathbb{Z}$ for each `n`.
The case for `n = 1` is handled separately, since it is used in the general construction
and we may want to use it without the `^1` getting in the way.
* `padic_int.to_zmod`: ring hom to `zmod p`
* `padic_int.to_zmod_pow`: ring hom to `zmod (p^n)`
* `padic_int.ker_to_zmod` / `padic_int.ker_to_zmod_pow`: the kernels of these maps are the ideals
  generated by `p^n`

We also establish the universal property of $\mathbb{Z}_p$ as a projective limit.
Given a family of compatible ring homs $f_k : R \to \mathbb{Z}/p^n\mathbb{Z}$,
there is a unique limit $R \to \mathbb{Z}_p$.
* `padic_int.lift`: the limit function
* `padic_int.lift_spec` / `padic_int.lift_unique`: the universal property

## Implementation notes

The ring hom constructions go through an auxiliary constructor `padic_int.to_zmod_hom`,
which removes some boilerplate code.

-/


noncomputable section

open Classical

open Nat LocalRing Padic

namespace PadicInt

variable {p : ℕ} [hp_prime : Fact p.Prime]

include hp_prime

section RingHoms

/-! ### Ring homomorphisms to `zmod p` and `zmod (p ^ n)` -/


variable (p) (r : ℚ)

omit hp_prime

/-- `mod_part p r` is an integer that satisfies
`∥(r - mod_part p r : ℚ_[p])∥ < 1` when `∥(r : ℚ_[p])∥ ≤ 1`,
see `padic_int.norm_sub_mod_part`.
It is the unique non-negative integer that is `< p` with this property.

(Note that this definition assumes `r : ℚ`.
See `padic_int.zmod_repr` for a version that takes values in `ℕ`
and works for arbitrary `x : ℤ_[p]`.) -/
def modPart : ℤ :=
  r.num * gcdA r.denom p % p

include hp_prime

variable {p}

theorem mod_part_lt_p : modPart p r < p := by
  convert Int.mod_lt _ _
  · simp
    
  · exact_mod_cast hp_prime.1.ne_zero
    

theorem mod_part_nonneg : 0 ≤ modPart p r :=
  Int.mod_nonneg _ <| by
    exact_mod_cast hp_prime.1.ne_zero

theorem is_unit_denom (r : ℚ) (h : ∥(r : ℚ_[p])∥ ≤ 1) : IsUnit (r.denom : ℤ_[p]) := by
  rw [is_unit_iff]
  apply le_antisymmₓ (r.denom : ℤ_[p]).2
  rw [← not_ltₓ, val_eq_coe, coe_nat_cast]
  intro norm_denom_lt
  have hr : ∥(r * r.denom : ℚ_[p])∥ = ∥(r.num : ℚ_[p])∥ := by
    rw_mod_cast[@Rat.mul_denom_eq_num r]
    rfl
  rw [padicNormE.mul] at hr
  have key : ∥(r.num : ℚ_[p])∥ < 1 := by
    calc
      _ = _ := hr.symm
      _ < 1 * 1 := mul_lt_mul' h norm_denom_lt (norm_nonneg _) zero_lt_one
      _ = 1 := mul_oneₓ 1
      
  have : ↑p ∣ r.num ∧ (p : ℤ) ∣ r.denom := by
    simp only [norm_int_lt_one_iff_dvd, padic_norm_e_of_padic_int]
    norm_cast
    exact ⟨key, norm_denom_lt⟩
  apply hp_prime.1.not_dvd_one
  rwa [← r.cop.gcd_eq_one, Nat.dvd_gcd_iffₓ, ← Int.coe_nat_dvd_left, ← Int.coe_nat_dvd]

theorem norm_sub_mod_part_aux (r : ℚ) (h : ∥(r : ℚ_[p])∥ ≤ 1) : ↑p ∣ r.num - r.num * r.denom.gcdA p % p * ↑r.denom := by
  rw [← Zmod.int_coe_zmod_eq_zero_iff_dvd]
  simp only [← Int.cast_coe_nat, ← Zmod.nat_cast_mod, ← Int.cast_mul, ← Int.cast_sub]
  have := congr_arg (coe : ℤ → Zmod p) (gcd_eq_gcd_ab r.denom p)
  simp only [← Int.cast_coe_nat, ← add_zeroₓ, ← Int.cast_add, ← Zmod.nat_cast_self, ← Int.cast_mul, ← zero_mul] at this
  push_cast
  rw [mul_right_commₓ, mul_assoc, ← this]
  suffices rdcp : r.denom.coprime p
  · rw [rdcp.gcd_eq_one]
    simp only [← mul_oneₓ, ← cast_one, ← sub_self]
    
  apply coprime.symm
  apply (coprime_or_dvd_of_prime hp_prime.1 _).resolve_right
  rw [← Int.coe_nat_dvd, ← norm_int_lt_one_iff_dvd, not_ltₓ]
  apply ge_of_eq
  rw [← is_unit_iff]
  exact is_unit_denom r h

theorem norm_sub_mod_part (h : ∥(r : ℚ_[p])∥ ≤ 1) : ∥(⟨r, h⟩ - modPart p r : ℤ_[p])∥ < 1 := by
  let n := mod_part p r
  rw [norm_lt_one_iff_dvd, ← (is_unit_denom r h).dvd_mul_right]
  suffices ↑p ∣ r.num - n * r.denom by
    convert (Int.castRingHom ℤ_[p]).map_dvd this
    simp only [← sub_mul, ← Int.cast_coe_nat, ← RingHom.eq_int_cast, ← Int.cast_mul, ← sub_left_inj, ← Int.cast_sub]
    apply Subtype.coe_injective
    simp only [← coe_mul, ← Subtype.coe_mk, ← coe_nat_cast]
    rw_mod_cast[@Rat.mul_denom_eq_num r]
    rfl
  exact norm_sub_mod_part_aux r h

theorem exists_mem_range_of_norm_rat_le_one (h : ∥(r : ℚ_[p])∥ ≤ 1) :
    ∃ n : ℤ, 0 ≤ n ∧ n < p ∧ ∥(⟨r, h⟩ - n : ℤ_[p])∥ < 1 :=
  ⟨modPart p r, mod_part_nonneg _, mod_part_lt_p _, norm_sub_mod_part _ h⟩

theorem zmod_congr_of_sub_mem_span_aux (n : ℕ) (x : ℤ_[p]) (a b : ℤ) (ha : x - a ∈ (Ideal.span {p ^ n} : Ideal ℤ_[p]))
    (hb : x - b ∈ (Ideal.span {p ^ n} : Ideal ℤ_[p])) : (a : Zmod (p ^ n)) = b := by
  rw [Ideal.mem_span_singleton] at ha hb
  rw [← sub_eq_zero, ← Int.cast_sub, Zmod.int_coe_zmod_eq_zero_iff_dvd, Int.coe_nat_pow]
  rw [← dvd_neg, neg_sub] at ha
  have := dvd_add ha hb
  rwa [sub_eq_add_neg, sub_eq_add_neg, add_assocₓ, neg_add_cancel_leftₓ, ← sub_eq_add_neg, ← Int.cast_sub,
    pow_p_dvd_int_iff] at this

theorem zmod_congr_of_sub_mem_span (n : ℕ) (x : ℤ_[p]) (a b : ℕ) (ha : x - a ∈ (Ideal.span {p ^ n} : Ideal ℤ_[p]))
    (hb : x - b ∈ (Ideal.span {p ^ n} : Ideal ℤ_[p])) : (a : Zmod (p ^ n)) = b := by
  simpa using zmod_congr_of_sub_mem_span_aux n x a b ha hb

theorem zmod_congr_of_sub_mem_max_ideal (x : ℤ_[p]) (m n : ℕ) (hm : x - m ∈ maximalIdeal ℤ_[p])
    (hn : x - n ∈ maximalIdeal ℤ_[p]) : (m : Zmod p) = n := by
  rw [maximal_ideal_eq_span_p] at hm hn
  have := zmod_congr_of_sub_mem_span_aux 1 x m n
  simp only [← pow_oneₓ] at this
  specialize this hm hn
  apply_fun
    Zmod.castHom
      (show p ∣ p ^ 1 by
        rw [pow_oneₓ])
      (Zmod p)
     at this
  simp only [← RingHom.map_int_cast] at this
  simpa only [← Int.cast_coe_nat] using this

variable (x : ℤ_[p])

theorem exists_mem_range : ∃ n : ℕ, n < p ∧ x - n ∈ maximalIdeal ℤ_[p] := by
  simp only [← maximal_ideal_eq_span_p, ← Ideal.mem_span_singleton, norm_lt_one_iff_dvd]
  obtain ⟨r, hr⟩ := rat_dense (x : ℚ_[p]) zero_lt_one
  have H : ∥(r : ℚ_[p])∥ ≤ 1 := by
    rw [norm_sub_rev] at hr
    calc
      _ = ∥(r : ℚ_[p]) - x + x∥ := by
        ring_nf
      _ ≤ _ := padicNormE.nonarchimedean _ _
      _ ≤ _ := max_leₓ (le_of_ltₓ hr) x.2
      
  obtain ⟨n, hzn, hnp, hn⟩ := exists_mem_range_of_norm_rat_le_one r H
  lift n to ℕ using hzn
  use n
  constructor
  · exact_mod_cast hnp
    
  simp only [← norm_def, ← coe_sub, ← Subtype.coe_mk, ← coe_nat_cast] at hn⊢
  rw
    [show (x - n : ℚ_[p]) = x - r + (r - n) by
      ring]
  apply lt_of_le_of_ltₓ (padicNormE.nonarchimedean _ _)
  apply max_ltₓ hr
  simpa using hn

/-- `zmod_repr x` is the unique natural number smaller than `p`
satisfying `∥(x - zmod_repr x : ℤ_[p])∥ < 1`.
-/
def zmodRepr : ℕ :=
  Classical.some (exists_mem_range x)

theorem zmod_repr_spec : zmodRepr x < p ∧ x - zmodRepr x ∈ maximalIdeal ℤ_[p] :=
  Classical.some_spec (exists_mem_range x)

theorem zmod_repr_lt_p : zmodRepr x < p :=
  (zmod_repr_spec _).1

theorem sub_zmod_repr_mem : x - zmodRepr x ∈ maximalIdeal ℤ_[p] :=
  (zmod_repr_spec _).2

/-- `to_zmod_hom` is an auxiliary constructor for creating ring homs from `ℤ_[p]` to `zmod v`.
-/
def toZmodHom (v : ℕ) (f : ℤ_[p] → ℕ) (f_spec : ∀ x, x - f x ∈ (Ideal.span {v} : Ideal ℤ_[p]))
    (f_congr :
      ∀ (x : ℤ_[p]) (a b : ℕ),
        x - a ∈ (Ideal.span {v} : Ideal ℤ_[p]) → x - b ∈ (Ideal.span {v} : Ideal ℤ_[p]) → (a : Zmod v) = b) :
    ℤ_[p] →+* Zmod v where
  toFun := fun x => f x
  map_zero' := by
    rw [f_congr (0 : ℤ_[p]) _ 0, cast_zero]
    · exact f_spec _
      
    · simp only [← sub_zero, ← cast_zero, ← Submodule.zero_mem]
      
  map_one' := by
    rw [f_congr (1 : ℤ_[p]) _ 1, cast_one]
    · exact f_spec _
      
    · simp only [← sub_self, ← cast_one, ← Submodule.zero_mem]
      
  map_add' := by
    intro x y
    rw [f_congr (x + y) _ (f x + f y), cast_add]
    · exact f_spec _
      
    · convert Ideal.add_mem _ (f_spec x) (f_spec y)
      rw [cast_add]
      ring
      
  map_mul' := by
    intro x y
    rw [f_congr (x * y) _ (f x * f y), cast_mul]
    · exact f_spec _
      
    · let I : Ideal ℤ_[p] := Ideal.span {v}
      convert I.add_mem (I.mul_mem_left x (f_spec y)) (I.mul_mem_right (f y) (f_spec x))
      rw [cast_mul]
      ring
      

/-- `to_zmod` is a ring hom from `ℤ_[p]` to `zmod p`,
with the equality `to_zmod x = (zmod_repr x : zmod p)`.
-/
def toZmod : ℤ_[p] →+* Zmod p :=
  toZmodHom p zmodRepr
    (by
      rw [← maximal_ideal_eq_span_p]
      exact sub_zmod_repr_mem)
    (by
      rw [← maximal_ideal_eq_span_p]
      exact zmod_congr_of_sub_mem_max_ideal)

/-- `z - (to_zmod z : ℤ_[p])` is contained in the maximal ideal of `ℤ_[p]`, for every `z : ℤ_[p]`.

The coercion from `zmod p` to `ℤ_[p]` is `zmod.has_coe_t`,
which coerces `zmod p` into artibrary rings.
This is unfortunate, but a consequence of the fact that we allow `zmod p`
to coerce to rings of arbitrary characteristic, instead of only rings of characteristic `p`.
This coercion is only a ring homomorphism if it coerces into a ring whose characteristic divides
`p`. While this is not the case here we can still make use of the coercion.
-/
theorem to_zmod_spec (z : ℤ_[p]) : z - (toZmod z : ℤ_[p]) ∈ maximalIdeal ℤ_[p] := by
  convert sub_zmod_repr_mem z using 2
  dsimp' [← to_zmod, ← to_zmod_hom]
  rcases exists_eq_add_of_lt hp_prime.1.Pos with ⟨p', rfl⟩
  change ↑(Zmod.val _) = _
  simp only [← Zmod.val_nat_cast, ← add_zeroₓ, ← add_def, ← Nat.cast_inj, ← zero_addₓ]
  apply mod_eq_of_lt
  simpa only [← zero_addₓ] using zmod_repr_lt_p z

theorem ker_to_zmod : (toZmod : ℤ_[p] →+* Zmod p).ker = maximalIdeal ℤ_[p] := by
  ext x
  rw [RingHom.mem_ker]
  constructor
  · intro h
    simpa only [← h, ← Zmod.cast_zero, ← sub_zero] using to_zmod_spec x
    
  · intro h
    rw [← sub_zero x] at h
    dsimp' [← to_zmod, ← to_zmod_hom]
    convert zmod_congr_of_sub_mem_max_ideal x _ 0 _ h
    norm_cast
    apply sub_zmod_repr_mem
    

/-- `appr n x` gives a value `v : ℕ` such that `x` and `↑v : ℤ_p` are congruent mod `p^n`.
See `appr_spec`. -/
noncomputable def appr : ℤ_[p] → ℕ → ℕ
  | x, 0 => 0
  | x, n + 1 =>
    let y := x - appr x n
    if hy : y = 0 then appr x n
    else
      let u := unitCoeff hy
      appr x n + p ^ n * (toZmod ((u : ℤ_[p]) * p ^ (y.Valuation - n).natAbs)).val

theorem appr_lt (x : ℤ_[p]) (n : ℕ) : x.appr n < p ^ n := by
  induction' n with n ih generalizing x
  · simp only [← appr, ← succ_pos', ← pow_zeroₓ]
    
  simp only [← appr, ← map_nat_cast, ← Zmod.nat_cast_self, ← RingHom.map_pow, ← Int.natAbs, ← RingHom.map_mul]
  have hp : p ^ n < p ^ (n + 1) := by
    apply pow_lt_pow hp_prime.1.one_lt (lt_add_one n)
  split_ifs with h
  · apply lt_transₓ (ih _) hp
    
  · calc
      _ < p ^ n + p ^ n * (p - 1) := _
      _ = p ^ (n + 1) := _
      
    · apply add_lt_add_of_lt_of_le (ih _)
      apply Nat.mul_le_mul_leftₓ
      apply le_pred_of_lt
      apply Zmod.val_lt
      
    · rw [mul_tsub, mul_oneₓ, ← pow_succ'ₓ]
      apply add_tsub_cancel_of_le (le_of_ltₓ hp)
      
    

theorem appr_mono (x : ℤ_[p]) : Monotone x.appr := by
  apply monotone_nat_of_le_succ
  intro n
  dsimp' [← appr]
  split_ifs
  · rfl
    
  apply Nat.le_add_rightₓ

theorem dvd_appr_sub_appr (x : ℤ_[p]) (m n : ℕ) (h : m ≤ n) : p ^ m ∣ x.appr n - x.appr m := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le h
  clear h
  induction' k with k ih
  · simp only [← add_zeroₓ, ← tsub_self, ← dvd_zero]
    
  rw [Nat.succ_eq_add_one, ← add_assocₓ]
  dsimp' [← appr]
  split_ifs with h
  · exact ih
    
  rw [add_commₓ, add_tsub_assoc_of_le (appr_mono _ (Nat.le_add_rightₓ m k))]
  apply dvd_add _ ih
  apply dvd_mul_of_dvd_left
  apply pow_dvd_pow _ (Nat.le_add_rightₓ m k)

theorem appr_spec (n : ℕ) : ∀ x : ℤ_[p], x - appr x n ∈ (Ideal.span {p ^ n} : Ideal ℤ_[p]) := by
  simp only [← Ideal.mem_span_singleton]
  induction' n with n ih
  · simp only [← is_unit_one, ← IsUnit.dvd, ← pow_zeroₓ, ← forall_true_iff]
    
  intro x
  dsimp' only [← appr]
  split_ifs with h
  · rw [h]
    apply dvd_zero
    
  push_cast
  rw [sub_add_eq_sub_sub]
  obtain ⟨c, hc⟩ := ih x
  simp only [← map_nat_cast, ← Zmod.nat_cast_self, ← RingHom.map_pow, ← RingHom.map_mul, ← Zmod.nat_cast_val]
  have hc' : c ≠ 0 := by
    rintro rfl
    simp only [← mul_zero] at hc
    contradiction
  conv_rhs => congr simp only [← hc]
  rw
    [show (x - ↑(appr x n)).Valuation = (↑p ^ n * c).Valuation by
      rw [hc]]
  rw [valuation_p_pow_mul _ _ hc', add_sub_cancel', pow_succ'ₓ, ← mul_sub]
  apply mul_dvd_mul_left
  obtain hc0 | hc0 := c.valuation.nat_abs.eq_zero_or_pos
  · simp only [← hc0, ← mul_oneₓ, ← pow_zeroₓ]
    rw [mul_comm, unit_coeff_spec h] at hc
    suffices c = unit_coeff h by
      rw [← this, ← Ideal.mem_span_singleton, ← maximal_ideal_eq_span_p]
      apply to_zmod_spec
    obtain ⟨c, rfl⟩ : IsUnit c := by
      -- TODO: write a can_lift instance for units
      rw [Int.nat_abs_eq_zero] at hc0
      rw [is_unit_iff, norm_eq_pow_val hc', hc0, neg_zero, zpow_zero]
    rw [DiscreteValuationRing.unit_mul_pow_congr_unit _ _ _ _ _ hc]
    exact irreducible_p
    
  · rw [zero_pow hc0]
    simp only [← sub_zero, ← Zmod.cast_zero, ← mul_zero]
    rw [unit_coeff_spec hc']
    exact (dvd_pow_self (p : ℤ_[p]) hc0.ne').mul_left _
    

/-- A ring hom from `ℤ_[p]` to `zmod (p^n)`, with underlying function `padic_int.appr n`. -/
def toZmodPow (n : ℕ) : ℤ_[p] →+* Zmod (p ^ n) :=
  toZmodHom (p ^ n) (fun x => appr x n)
    (by
      intros
      convert appr_spec n _ using 1
      simp )
    (by
      intro x a b ha hb
      apply zmod_congr_of_sub_mem_span n x a b
      · simpa using ha
        
      · simpa using hb
        )

theorem ker_to_zmod_pow (n : ℕ) : (toZmodPow n : ℤ_[p] →+* Zmod (p ^ n)).ker = Ideal.span {p ^ n} := by
  ext x
  rw [RingHom.mem_ker]
  constructor
  · intro h
    suffices x.appr n = 0 by
      convert appr_spec n x
      simp only [← this, ← sub_zero, ← cast_zero]
    dsimp' [← to_zmod_pow, ← to_zmod_hom]  at h
    rw [Zmod.nat_coe_zmod_eq_zero_iff_dvd] at h
    apply eq_zero_of_dvd_of_lt h (appr_lt _ _)
    
  · intro h
    rw [← sub_zero x] at h
    dsimp' [← to_zmod_pow, ← to_zmod_hom]
    rw [zmod_congr_of_sub_mem_span n x _ 0 _ h, cast_zero]
    apply appr_spec
    

@[simp]
theorem zmod_cast_comp_to_zmod_pow (m n : ℕ) (h : m ≤ n) :
    (Zmod.castHom (pow_dvd_pow p h) (Zmod (p ^ m))).comp (toZmodPow n) = toZmodPow m := by
  apply Zmod.ring_hom_eq_of_ker_eq
  ext x
  rw [RingHom.mem_ker, RingHom.mem_ker]
  simp only [← Function.comp_app, ← Zmod.cast_hom_apply, ← RingHom.coe_comp]
  simp only [← to_zmod_pow, ← to_zmod_hom, ← RingHom.coe_mk]
  rw [Zmod.cast_nat_cast (pow_dvd_pow p h), zmod_congr_of_sub_mem_span m (x.appr n) (x.appr n) (x.appr m)]
  · rw [sub_self]
    apply Ideal.zero_mem _
    
  · rw [Ideal.mem_span_singleton]
    rcases dvd_appr_sub_appr x m n h with ⟨c, hc⟩
    use c
    rw [← Nat.cast_sub (appr_mono _ h), hc, Nat.cast_mulₓ, Nat.cast_powₓ]
    
  · infer_instance
    

@[simp]
theorem cast_to_zmod_pow (m n : ℕ) (h : m ≤ n) (x : ℤ_[p]) : ↑(toZmodPow n x) = toZmodPow m x := by
  rw [← zmod_cast_comp_to_zmod_pow _ _ h]
  rfl

theorem dense_range_nat_cast : DenseRange (Nat.castₓ : ℕ → ℤ_[p]) := by
  intro x
  rw [Metric.mem_closure_range_iff]
  intro ε hε
  obtain ⟨n, hn⟩ := exists_pow_neg_lt p hε
  use x.appr n
  rw [dist_eq_norm]
  apply lt_of_le_of_ltₓ _ hn
  rw [norm_le_pow_iff_mem_span_pow]
  apply appr_spec

theorem dense_range_int_cast : DenseRange (Int.castₓ : ℤ → ℤ_[p]) := by
  intro x
  apply dense_range_nat_cast.induction_on x
  · exact is_closed_closure
    
  · intro a
    change (a.cast : ℤ_[p]) with (a : ℤ).cast
    apply subset_closure
    exact Set.mem_range_self _
    

end RingHoms

section lift

/-! ### Universal property as projective limit -/


open CauSeq PadicSeq

variable {R : Type _} [NonAssocSemiringₓ R] (f : ∀ k : ℕ, R →+* Zmod (p ^ k))
  (f_compat : ∀ (k1 k2) (hk : k1 ≤ k2), (Zmod.castHom (pow_dvd_pow p hk) _).comp (f k2) = f k1)

omit hp_prime

/-- Given a family of ring homs `f : Π n : ℕ, R →+* zmod (p ^ n)`,
`nth_hom f r` is an integer-valued sequence
whose `n`th value is the unique integer `k` such that `0 ≤ k < p ^ n`
and `f n r = (k : zmod (p ^ n))`.
-/
def nthHom (r : R) : ℕ → ℤ := fun n => (f n r : Zmod (p ^ n)).val

@[simp]
theorem nth_hom_zero : nthHom f 0 = 0 := by
  simp [← nth_hom] <;> rfl

variable {f}

include hp_prime

include f_compat

theorem pow_dvd_nth_hom_sub (r : R) (i j : ℕ) (h : i ≤ j) : ↑p ^ i ∣ nthHom f r j - nthHom f r i := by
  specialize f_compat i j h
  rw [← Int.coe_nat_pow, ← Zmod.int_coe_zmod_eq_zero_iff_dvd, Int.cast_sub]
  dsimp' [← nth_hom]
  rw [← f_compat, RingHom.comp_apply]
  haveI : Fact (p ^ i > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  haveI : Fact (p ^ j > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  simp only [← Zmod.cast_id, ← Zmod.cast_hom_apply, ← sub_self, ← Zmod.nat_cast_val, ← Zmod.int_cast_cast]

theorem is_cau_seq_nth_hom (r : R) : IsCauSeq (padicNorm p) fun n => nthHom f r n := by
  intro ε hε
  obtain ⟨k, hk⟩ : ∃ k : ℕ, (p ^ -(↑(k : ℕ) : ℤ) : ℚ) < ε := exists_pow_neg_lt_rat p hε
  use k
  intro j hj
  refine' lt_of_le_of_ltₓ _ hk
  norm_cast
  rw [← padicNorm.dvd_iff_norm_le]
  exact_mod_cast pow_dvd_nth_hom_sub f_compat r k j hj

/-- `nth_hom_seq f_compat r` bundles `padic_int.nth_hom f r`
as a Cauchy sequence of rationals with respect to the `p`-adic norm.
The `n`th value of the sequence is `((f n r).val : ℚ)`.
-/
def nthHomSeq (r : R) : PadicSeq p :=
  ⟨fun n => nthHom f r n, is_cau_seq_nth_hom f_compat r⟩

theorem nth_hom_seq_one : nthHomSeq f_compat 1 ≈ 1 := by
  intro ε hε
  change _ < _ at hε
  use 1
  intro j hj
  haveI : Fact (1 < p ^ j) :=
    ⟨Nat.one_lt_pow _ _
        (by
          linarith)
        hp_prime.1.one_lt⟩
  simp [← nth_hom_seq, ← nth_hom, ← Zmod.val_one, ← hε]

theorem nth_hom_seq_add (r s : R) : nthHomSeq f_compat (r + s) ≈ nthHomSeq f_compat r + nthHomSeq f_compat s := by
  intro ε hε
  obtain ⟨n, hn⟩ := exists_pow_neg_lt_rat p hε
  use n
  intro j hj
  dsimp' [← nth_hom_seq]
  apply lt_of_le_of_ltₓ _ hn
  rw [← Int.cast_add, ← Int.cast_sub, ← padicNorm.dvd_iff_norm_le, ← Zmod.int_coe_zmod_eq_zero_iff_dvd]
  dsimp' [← nth_hom]
  haveI : Fact (p ^ n > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  haveI : Fact (p ^ j > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  simp only [← Zmod.nat_cast_val, ← RingHom.map_add, ← Int.cast_sub, ← Zmod.int_cast_cast, ← Int.cast_add]
  rw [Zmod.cast_add (show p ^ n ∣ p ^ j from pow_dvd_pow _ hj), sub_self]
  · infer_instance
    

theorem nth_hom_seq_mul (r s : R) : nthHomSeq f_compat (r * s) ≈ nthHomSeq f_compat r * nthHomSeq f_compat s := by
  intro ε hε
  obtain ⟨n, hn⟩ := exists_pow_neg_lt_rat p hε
  use n
  intro j hj
  dsimp' [← nth_hom_seq]
  apply lt_of_le_of_ltₓ _ hn
  rw [← Int.cast_mul, ← Int.cast_sub, ← padicNorm.dvd_iff_norm_le, ← Zmod.int_coe_zmod_eq_zero_iff_dvd]
  dsimp' [← nth_hom]
  haveI : Fact (p ^ n > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  haveI : Fact (p ^ j > 0) := ⟨pow_pos hp_prime.1.Pos _⟩
  simp only [← Zmod.nat_cast_val, ← RingHom.map_mul, ← Int.cast_sub, ← Zmod.int_cast_cast, ← Int.cast_mul]
  rw [Zmod.cast_mul (show p ^ n ∣ p ^ j from pow_dvd_pow _ hj), sub_self]
  · infer_instance
    

/-- `lim_nth_hom f_compat r` is the limit of a sequence `f` of compatible ring homs `R →+* zmod (p^k)`.
This is itself a ring hom: see `padic_int.lift`.
-/
def limNthHom (r : R) : ℤ_[p] :=
  ofIntSeq (nthHom f r) (is_cau_seq_nth_hom f_compat r)

theorem lim_nth_hom_spec (r : R) : ∀ ε : ℝ, 0 < ε → ∃ N : ℕ, ∀, ∀ n ≥ N, ∀, ∥limNthHom f_compat r - nthHom f r n∥ < ε :=
  by
  intro ε hε
  obtain ⟨ε', hε'0, hε'⟩ : ∃ v : ℚ, (0 : ℝ) < v ∧ ↑v < ε := exists_rat_btwn hε
  norm_cast  at hε'0
  obtain ⟨N, hN⟩ := padicNormE.defn (nth_hom_seq f_compat r) hε'0
  use N
  intro n hn
  apply lt_transₓ _ hε'
  change ↑(padicNormE _) < _
  norm_cast
  exact hN _ hn

theorem lim_nth_hom_zero : limNthHom f_compat 0 = 0 := by
  simp [← lim_nth_hom] <;> rfl

theorem lim_nth_hom_one : limNthHom f_compat 1 = 1 :=
  Subtype.ext <| Quot.sound <| nth_hom_seq_one _

theorem lim_nth_hom_add (r s : R) : limNthHom f_compat (r + s) = limNthHom f_compat r + limNthHom f_compat s :=
  Subtype.ext <| Quot.sound <| nth_hom_seq_add _ _ _

theorem lim_nth_hom_mul (r s : R) : limNthHom f_compat (r * s) = limNthHom f_compat r * limNthHom f_compat s :=
  Subtype.ext <| Quot.sound <| nth_hom_seq_mul _ _ _

-- TODO: generalize this to arbitrary complete discrete valuation rings
/-- `lift f_compat` is the limit of a sequence `f` of compatible ring homs `R →+* zmod (p^k)`,
with the equality `lift f_compat r = padic_int.lim_nth_hom f_compat r`.
-/
def lift : R →+* ℤ_[p] where
  toFun := limNthHom f_compat
  map_one' := lim_nth_hom_one f_compat
  map_mul' := lim_nth_hom_mul f_compat
  map_zero' := lim_nth_hom_zero f_compat
  map_add' := lim_nth_hom_add f_compat

omit f_compat

theorem lift_sub_val_mem_span (r : R) (n : ℕ) : lift f_compat r - (f n r).val ∈ (Ideal.span {↑p ^ n} : Ideal ℤ_[p]) :=
  by
  obtain ⟨k, hk⟩ :=
    lim_nth_hom_spec f_compat r _ (show (0 : ℝ) < p ^ (-n : ℤ) from Nat.zpow_pos_of_pos hp_prime.1.Pos _)
  have := le_of_ltₓ (hk (max n k) (le_max_rightₓ _ _))
  rw [norm_le_pow_iff_mem_span_pow] at this
  dsimp' [← lift]
  rw [sub_eq_sub_add_sub (lim_nth_hom f_compat r) _ ↑(nth_hom f r (max n k))]
  apply Ideal.add_mem _ _ this
  rw [Ideal.mem_span_singleton]
  simpa only [← RingHom.eq_int_cast, ← RingHom.map_pow, ← Int.cast_sub] using
    (Int.castRingHom ℤ_[p]).map_dvd (pow_dvd_nth_hom_sub f_compat r n (max n k) (le_max_leftₓ _ _))

/-- One part of the universal property of `ℤ_[p]` as a projective limit.
See also `padic_int.lift_unique`.
-/
theorem lift_spec (n : ℕ) : (toZmodPow n).comp (lift f_compat) = f n := by
  ext r
  haveI : Fact (0 < p ^ n) := ⟨pow_pos hp_prime.1.Pos n⟩
  rw [RingHom.comp_apply, ← Zmod.nat_cast_zmod_val (f n r), ← map_nat_cast <| to_zmod_pow n, ← sub_eq_zero, ←
    RingHom.map_sub, ← RingHom.mem_ker, ker_to_zmod_pow]
  apply lift_sub_val_mem_span

/-- One part of the universal property of `ℤ_[p]` as a projective limit.
See also `padic_int.lift_spec`.
-/
theorem lift_unique (g : R →+* ℤ_[p]) (hg : ∀ n, (toZmodPow n).comp g = f n) : lift f_compat = g := by
  ext1 r
  apply eq_of_forall_dist_le
  intro ε hε
  obtain ⟨n, hn⟩ := exists_pow_neg_lt p hε
  apply le_transₓ _ (le_of_ltₓ hn)
  rw [dist_eq_norm, norm_le_pow_iff_mem_span_pow, ← ker_to_zmod_pow, RingHom.mem_ker, RingHom.map_sub, ←
    RingHom.comp_apply, ← RingHom.comp_apply, lift_spec, hg, sub_self]

@[simp]
theorem lift_self (z : ℤ_[p]) : @lift p _ ℤ_[p] _ toZmodPow zmod_cast_comp_to_zmod_pow z = z := by
  show _ = RingHom.id _ z
  rw [@lift_unique p _ ℤ_[p] _ _ zmod_cast_comp_to_zmod_pow (RingHom.id ℤ_[p])]
  intro
  rw [RingHom.comp_id]

end lift

theorem ext_of_to_zmod_pow {x y : ℤ_[p]} : (∀ n, toZmodPow n x = toZmodPow n y) ↔ x = y := by
  constructor
  · intro h
    rw [← lift_self x, ← lift_self y]
    simp [← lift, ← lim_nth_hom, ← nth_hom, ← h]
    
  · rintro rfl _
    rfl
    

theorem to_zmod_pow_eq_iff_ext {R : Type _} [NonAssocSemiringₓ R] {g g' : R →+* ℤ_[p]} :
    (∀ n, (toZmodPow n).comp g = (toZmodPow n).comp g') ↔ g = g' := by
  constructor
  · intro hg
    ext x : 1
    apply ext_of_to_zmod_pow.mp
    intro n
    show (to_zmod_pow n).comp g x = (to_zmod_pow n).comp g' x
    rw [hg n]
    
  · rintro rfl _
    rfl
    

end PadicInt

