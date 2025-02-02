/-
Copyright (c) 2020 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau
-/
import Mathbin.RingTheory.Polynomial.Basic
import Mathbin.RingTheory.Ideal.LocalRing
import Mathbin.Tactic.RingExp

/-!
# Expand a polynomial by a factor of p, so `∑ aₙ xⁿ` becomes `∑ aₙ xⁿᵖ`.

## Main definitions

* `polynomial.expand R p f`: expand the polynomial `f` with coefficients in a
  commutative semiring `R` by a factor of p, so `expand R p (∑ aₙ xⁿ)` is `∑ aₙ xⁿᵖ`.
* `polynomial.contract p f`: the opposite of `expand`, so it sends `∑ aₙ xⁿᵖ` to `∑ aₙ xⁿ`.

-/


universe u v w

open Classical BigOperators Polynomial

open Finset

namespace Polynomial

section CommSemiringₓ

variable (R : Type u) [CommSemiringₓ R] {S : Type v} [CommSemiringₓ S] (p q : ℕ)

/-- Expand the polynomial by a factor of p, so `∑ aₙ xⁿ` becomes `∑ aₙ xⁿᵖ`. -/
noncomputable def expand : R[X] →ₐ[R] R[X] :=
  { (eval₂RingHom c (X ^ p) : R[X] →+* R[X]) with commutes' := fun r => eval₂_C _ _ }

theorem coe_expand : (expand R p : R[X] → R[X]) = eval₂ c (X ^ p) :=
  rfl

variable {R}

theorem expand_eq_sum {f : R[X]} : expand R p f = f.Sum fun e a => c a * (X ^ p) ^ e := by
  dsimp' [expand, eval₂]
  rfl

@[simp]
theorem expand_C (r : R) : expand R p (c r) = c r :=
  eval₂_C _ _

@[simp]
theorem expand_X : expand R p x = X ^ p :=
  eval₂_X _ _

@[simp]
theorem expand_monomial (r : R) : expand R p (monomial q r) = monomial (q * p) r := by
  simp_rw [monomial_eq_smul_X, AlgHom.map_smul, AlgHom.map_pow, expand_X, mul_comm, pow_mulₓ]

theorem expand_expand (f : R[X]) : expand R p (expand R q f) = expand R (p * q) f :=
  Polynomial.induction_on f
    (fun r => by
      simp_rw [expand_C])
    (fun f g ihf ihg => by
      simp_rw [AlgHom.map_add, ihf, ihg])
    fun n r ih => by
    simp_rw [AlgHom.map_mul, expand_C, AlgHom.map_pow, expand_X, AlgHom.map_pow, expand_X, pow_mulₓ]

theorem expand_mul (f : R[X]) : expand R (p * q) f = expand R p (expand R q f) :=
  (expand_expand p q f).symm

@[simp]
theorem expand_zero (f : R[X]) : expand R 0 f = c (eval 1 f) := by
  simp [expand]

@[simp]
theorem expand_one (f : R[X]) : expand R 1 f = f :=
  Polynomial.induction_on f
    (fun r => by
      rw [expand_C])
    (fun f g ihf ihg => by
      rw [AlgHom.map_add, ihf, ihg])
    fun n r ih => by
    rw [AlgHom.map_mul, expand_C, AlgHom.map_pow, expand_X, pow_oneₓ]

theorem expand_pow (f : R[X]) : expand R (p ^ q) f = (expand R p^[q]) f :=
  (Nat.recOn q
      (by
        rw [pow_zeroₓ, expand_one, Function.iterate_zero, id]))
    fun n ih => by
    rw [Function.iterate_succ_apply', pow_succₓ, expand_mul, ih]

theorem derivative_expand (f : R[X]) : (expand R p f).derivative = expand R p f.derivative * (p * X ^ (p - 1)) := by
  rw [coe_expand, derivative_eval₂_C, derivative_pow, derivative_X, mul_oneₓ]

theorem coeff_expand {p : ℕ} (hp : 0 < p) (f : R[X]) (n : ℕ) :
    (expand R p f).coeff n = if p ∣ n then f.coeff (n / p) else 0 := by
  simp only [expand_eq_sum]
  simp_rw [coeff_sum, ← pow_mulₓ, C_mul_X_pow_eq_monomial, coeff_monomial, Sum]
  split_ifs with h
  · rw [Finset.sum_eq_single (n / p), Nat.mul_div_cancel'ₓ h, if_pos rfl]
    · intro b hb1 hb2
      rw [if_neg]
      intro hb3
      apply hb2
      rw [← hb3, Nat.mul_div_cancel_leftₓ b hp]
      
    · intro hn
      rw [not_mem_support_iff.1 hn]
      split_ifs <;> rfl
      
    
  · rw [Finset.sum_eq_zero]
    intro k hk
    rw [if_neg]
    exact fun hkn => h ⟨k, hkn.symm⟩
    

@[simp]
theorem coeff_expand_mul {p : ℕ} (hp : 0 < p) (f : R[X]) (n : ℕ) : (expand R p f).coeff (n * p) = f.coeff n := by
  rw [coeff_expand hp, if_pos (dvd_mul_left _ _), Nat.mul_div_cancelₓ _ hp]

@[simp]
theorem coeff_expand_mul' {p : ℕ} (hp : 0 < p) (f : R[X]) (n : ℕ) : (expand R p f).coeff (p * n) = f.coeff n := by
  rw [mul_comm, coeff_expand_mul hp]

theorem expand_inj {p : ℕ} (hp : 0 < p) {f g : R[X]} : expand R p f = expand R p g ↔ f = g :=
  ⟨fun H =>
    ext fun n => by
      rw [← coeff_expand_mul hp, H, coeff_expand_mul hp],
    congr_argₓ _⟩

theorem expand_eq_zero {p : ℕ} (hp : 0 < p) {f : R[X]} : expand R p f = 0 ↔ f = 0 := by
  rw [← (expand R p).map_zero, expand_inj hp, AlgHom.map_zero]

theorem expand_ne_zero {p : ℕ} (hp : 0 < p) {f : R[X]} : expand R p f ≠ 0 ↔ f ≠ 0 :=
  (expand_eq_zero hp).Not

theorem expand_eq_C {p : ℕ} (hp : 0 < p) {f : R[X]} {r : R} : expand R p f = c r ↔ f = c r := by
  rw [← expand_C, expand_inj hp, expand_C]

theorem nat_degree_expand (p : ℕ) (f : R[X]) : (expand R p f).natDegree = f.natDegree * p := by
  cases' p.eq_zero_or_pos with hp hp
  · rw [hp, coe_expand, pow_zeroₓ, mul_zero, ← C_1, eval₂_hom, nat_degree_C]
    
  by_cases' hf : f = 0
  · rw [hf, AlgHom.map_zero, nat_degree_zero, zero_mul]
    
  have hf1 : expand R p f ≠ 0 := mt (expand_eq_zero hp).1 hf
  rw [← WithBot.coe_eq_coe, ← degree_eq_nat_degree hf1]
  refine' le_antisymmₓ ((degree_le_iff_coeff_zero _ _).2 fun n hn => _) _
  · rw [coeff_expand hp]
    split_ifs with hpn
    · rw [coeff_eq_zero_of_nat_degree_lt]
      contrapose! hn
      rw [WithBot.coe_le_coe, ← Nat.div_mul_cancelₓ hpn]
      exact Nat.mul_le_mul_rightₓ p hn
      
    · rfl
      
    
  · refine' le_degree_of_ne_zero _
    rw [coeff_expand_mul hp, ← leading_coeff]
    exact mt leading_coeff_eq_zero.1 hf
    

theorem Monic.expand {p : ℕ} {f : R[X]} (hp : 0 < p) (h : f.Monic) : (expand R p f).Monic := by
  rw [monic.def, leading_coeff, nat_degree_expand, coeff_expand hp]
  simp [hp, h]

theorem map_expand {p : ℕ} {f : R →+* S} {q : R[X]} : map f (expand R p q) = expand S p (map f q) := by
  by_cases' hp : p = 0
  · simp [hp]
    
  ext
  rw [coeff_map, coeff_expand (Nat.pos_of_ne_zeroₓ hp), coeff_expand (Nat.pos_of_ne_zeroₓ hp)]
  split_ifs <;> simp

/-- Expansion is injective. -/
theorem expand_injective {n : ℕ} (hn : 0 < n) : Function.Injective (expand R n) := fun g g' h => by
  ext
  have h' : (expand R n g).coeff (n * n_1) = (expand R n g').coeff (n * n_1) := by
    apply Polynomial.ext_iff.1
    exact h
  rw [Polynomial.coeff_expand hn g (n * n_1), Polynomial.coeff_expand hn g' (n * n_1)] at h'
  simp only [if_true, dvd_mul_right] at h'
  rw [Nat.mul_div_rightₓ n_1 hn] at h'
  exact h'

@[simp]
theorem expand_eval (p : ℕ) (P : R[X]) (r : R) : eval r (expand R p P) = eval (r ^ p) P := by
  refine'
    Polynomial.induction_on P
      (fun a => by
        simp )
      (fun f g hf hg => _) fun n a h => by
      simp
  rw [AlgHom.map_add, eval_add, eval_add, hf, hg]

@[simp]
theorem expand_aeval {A : Type _} [Semiringₓ A] [Algebra R A] (p : ℕ) (P : R[X]) (r : A) :
    aeval r (expand R p P) = aeval (r ^ p) P := by
  refine'
    Polynomial.induction_on P
      (fun a => by
        simp )
      (fun f g hf hg => _) fun n a h => by
      simp
  rw [AlgHom.map_add, aeval_add, aeval_add, hf, hg]

/-- The opposite of `expand`: sends `∑ aₙ xⁿᵖ` to `∑ aₙ xⁿ`. -/
noncomputable def contract (p : ℕ) (f : R[X]) : R[X] :=
  ∑ n in range (f.natDegree + 1), monomial n (f.coeff (n * p))

theorem coeff_contract {p : ℕ} (hp : p ≠ 0) (f : R[X]) (n : ℕ) : (contract p f).coeff n = f.coeff (n * p) := by
  simp only [contract, coeff_monomial, sum_ite_eq', finset_sum_coeff, mem_range, not_ltₓ, ite_eq_left_iff]
  intro hn
  apply (coeff_eq_zero_of_nat_degree_lt _).symm
  calc
    f.nat_degree < f.nat_degree + 1 := Nat.lt_succ_selfₓ _
    _ ≤ n * 1 := by
      simpa only [mul_oneₓ] using hn
    _ ≤ n * p := mul_le_mul_of_nonneg_left (show 1 ≤ p from hp.bot_lt) (zero_le n)
    

theorem contract_expand {f : R[X]} (hp : p ≠ 0) : contract p (expand R p f) = f := by
  ext
  simp [coeff_contract hp, coeff_expand hp.bot_lt, Nat.mul_div_cancelₓ _ hp.bot_lt]

section CharP

variable [CharP R p]

theorem expand_contract [NoZeroDivisors R] {f : R[X]} (hf : f.derivative = 0) (hp : p ≠ 0) :
    expand R p (contract p f) = f := by
  ext n
  rw [coeff_expand hp.bot_lt, coeff_contract hp]
  split_ifs with h
  · rw [Nat.div_mul_cancelₓ h]
    
  · cases n
    · exact absurd (dvd_zero p) h
      
    have := coeff_derivative f n
    rw [hf, coeff_zero, zero_eq_mul] at this
    cases this
    · rw [this]
      
    rw [← Nat.cast_succₓ, CharP.cast_eq_zero_iff R p] at this
    exact absurd this h
    

variable [hp : Fact p.Prime]

include hp

theorem expand_char (f : R[X]) : map (frobenius R p) (expand R p f) = f ^ p := by
  refine' f.induction_on' (fun a b ha hb => _) fun n a => _
  · rw [AlgHom.map_add, Polynomial.map_add, ha, hb, add_pow_char]
    
  · rw [expand_monomial, map_monomial, monomial_eq_C_mul_X, monomial_eq_C_mul_X, mul_powₓ, ← C.map_pow, frobenius_def]
    ring_exp
    

theorem map_expand_pow_char (f : R[X]) (n : ℕ) : map (frobenius R p ^ n) (expand R (p ^ n) f) = f ^ p ^ n := by
  induction n
  · simp [RingHom.one_def]
    
  symm
  rw [pow_succ'ₓ, pow_mulₓ, ← n_ih, ← expand_char, pow_succₓ, RingHom.mul_def, ← map_map, mul_comm, expand_mul, ←
    map_expand]

end CharP

end CommSemiringₓ

section IsDomain

variable (R : Type u) [CommRingₓ R] [IsDomain R]

theorem is_local_ring_hom_expand {p : ℕ} (hp : 0 < p) : IsLocalRingHom (↑(expand R p) : R[X] →+* R[X]) := by
  refine' ⟨fun f hf1 => _⟩
  rw [← coe_fn_coe_base] at hf1
  have hf2 := eq_C_of_degree_eq_zero (degree_eq_zero_of_is_unit hf1)
  rw [coeff_expand hp, if_pos (dvd_zero _), p.zero_div] at hf2
  rw [hf2, is_unit_C] at hf1
  rw [expand_eq_C hp] at hf2
  rwa [hf2, is_unit_C]

variable {R}

theorem of_irreducible_expand {p : ℕ} (hp : p ≠ 0) {f : R[X]} (hf : Irreducible (expand R p f)) : Irreducible f :=
  let _ := is_local_ring_hom_expand R hp.bot_lt
  of_irreducible_map (↑(expand R p)) hf

theorem of_irreducible_expand_pow {p : ℕ} (hp : p ≠ 0) {f : R[X]} {n : ℕ} :
    Irreducible (expand R (p ^ n) f) → Irreducible f :=
  (Nat.recOn n fun hf => by
      rwa [pow_zeroₓ, expand_one] at hf)
    fun n ih hf =>
    ih <|
      of_irreducible_expand hp <| by
        rw [pow_succₓ] at hf
        rwa [expand_expand]

end IsDomain

end Polynomial

