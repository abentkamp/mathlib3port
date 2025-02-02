/-
Copyright (c) 2020 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import Mathbin.RingTheory.Prime
import Mathbin.RingTheory.Polynomial.Content

/-!
# Eisenstein's criterion

A proof of a slight generalisation of Eisenstein's criterion for the irreducibility of
a polynomial over an integral domain.
-/


open Polynomial Ideal.Quotient

variable {R : Type _} [CommRingₓ R]

namespace Polynomial

open Polynomial

namespace EisensteinCriterionAux

-- Section for auxiliary lemmas used in the proof of `irreducible_of_eisenstein_criterion`
theorem map_eq_C_mul_X_pow_of_forall_coeff_mem {f : R[X]} {P : Ideal R} (hfP : ∀ n : ℕ, ↑n < f.degree → f.coeff n ∈ P) :
    map (mk P) f = c ((mk P) f.leadingCoeff) * X ^ f.natDegree :=
  Polynomial.ext fun n => by
    by_cases' hf0 : f = 0
    · simp [hf0]
      
    rcases lt_trichotomyₓ (↑n) (degree f) with (h | h | h)
    · erw [coeff_map, eq_zero_iff_mem.2 (hfP n h), coeff_C_mul, coeff_X_pow, if_neg, mul_zero]
      rintro rfl
      exact not_lt_of_geₓ degree_le_nat_degree h
      
    · have : nat_degree f = n := nat_degree_eq_of_degree_eq_some h.symm
      rw [coeff_C_mul, coeff_X_pow, if_pos this.symm, mul_oneₓ, leading_coeff, this, coeff_map]
      
    · rw [coeff_eq_zero_of_degree_lt, coeff_eq_zero_of_degree_lt]
      · refine' lt_of_le_of_ltₓ (degree_C_mul_X_pow_le _ _) _
        rwa [← degree_eq_nat_degree hf0]
        
      · exact lt_of_le_of_ltₓ (degree_map_le _ _) h
        
      

theorem le_nat_degree_of_map_eq_mul_X_pow {n : ℕ} {P : Ideal R} (hP : P.IsPrime) {q : R[X]} {c : Polynomial (R ⧸ P)}
    (hq : map (mk P) q = c * X ^ n) (hc0 : c.degree = 0) : n ≤ q.natDegree :=
  WithBot.coe_le_coe.1
    (calc
      ↑n = degree (q.map (mk P)) := by
        rw [hq, degree_mul, hc0, zero_addₓ, degree_pow, degree_X, nsmul_one, Nat.cast_with_bot]
      _ ≤ degree q := degree_map_le _ _
      _ ≤ natDegree q := degree_le_nat_degree
      )

theorem eval_zero_mem_ideal_of_eq_mul_X_pow {n : ℕ} {P : Ideal R} {q : R[X]} {c : Polynomial (R ⧸ P)}
    (hq : map (mk P) q = c * X ^ n) (hn0 : 0 < n) : eval 0 q ∈ P := by
  rw [← coeff_zero_eq_eval_zero, ← eq_zero_iff_mem, ← coeff_map, coeff_zero_eq_eval_zero, hq, eval_mul, eval_pow,
    eval_X, zero_pow hn0, mul_zero]

theorem is_unit_of_nat_degree_eq_zero_of_forall_dvd_is_unit {p q : R[X]} (hu : ∀ x : R, c x ∣ p * q → IsUnit x)
    (hpm : p.natDegree = 0) : IsUnit p := by
  rw [eq_C_of_degree_le_zero (nat_degree_eq_zero_iff_degree_le_zero.1 hpm), is_unit_C]
  refine' hu _ _
  rw [← eq_C_of_degree_le_zero (nat_degree_eq_zero_iff_degree_le_zero.1 hpm)]
  exact dvd_mul_right _ _

end EisensteinCriterionAux

open EisensteinCriterionAux

variable [IsDomain R]

/-- If `f` is a non constant polynomial with coefficients in `R`, and `P` is a prime ideal in `R`,
then if every coefficient in `R` except the leading coefficient is in `P`, and
the trailing coefficient is not in `P^2` and no non units in `R` divide `f`, then `f` is
irreducible. -/
theorem irreducible_of_eisenstein_criterion {f : R[X]} {P : Ideal R} (hP : P.IsPrime) (hfl : f.leadingCoeff ∉ P)
    (hfP : ∀ n : ℕ, ↑n < degree f → f.coeff n ∈ P) (hfd0 : 0 < degree f) (h0 : f.coeff 0 ∉ P ^ 2) (hu : f.IsPrimitive) :
    Irreducible f :=
  have hf0 : f ≠ 0 := fun _ => by
    simp_all only [not_true, Submodule.zero_mem, coeff_zero]
  have hf : f.map (mk P) = c (mk P (leadingCoeff f)) * X ^ natDegree f := map_eq_C_mul_X_pow_of_forall_coeff_mem hfP
  have hfd0 : 0 < f.natDegree := WithBot.coe_lt_coe.1 (lt_of_lt_of_leₓ hfd0 degree_le_nat_degree)
  ⟨mt degree_eq_zero_of_is_unit fun h => by
      simp_all only [lt_irreflₓ],
    by
    rintro p q rfl
    rw [Polynomial.map_mul] at hf
    rcases mul_eq_mul_prime_pow (show Prime (X : Polynomial (R ⧸ P)) from monic_X.prime_of_degree_eq_one degree_X)
        hf with
      ⟨m, n, b, c, hmnd, hbc, hp, hq⟩
    have hmn : 0 < m → 0 < n → False := by
      intro hm0 hn0
      refine' h0 _
      rw [coeff_zero_eq_eval_zero, eval_mul, sq]
      exact Ideal.mul_mem_mul (eval_zero_mem_ideal_of_eq_mul_X_pow hp hm0) (eval_zero_mem_ideal_of_eq_mul_X_pow hq hn0)
    have hpql0 : (mk P) (p * q).leadingCoeff ≠ 0 := by
      rwa [Ne.def, eq_zero_iff_mem]
    have hp0 : p ≠ 0 := fun h => by
      simp_all only [zero_mul, eq_self_iff_true, not_true, Ne.def]
    have hq0 : q ≠ 0 := fun h => by
      simp_all only [eq_self_iff_true, not_true, Ne.def, mul_zero]
    have hbc0 : degree b = 0 ∧ degree c = 0 := by
      apply_fun degree  at hbc
      rwa [degree_C hpql0, degree_mul, eq_comm, Nat.WithBot.add_eq_zero_iff] at hbc
    have hmp : m ≤ nat_degree p := le_nat_degree_of_map_eq_mul_X_pow hP hp hbc0.1
    have hnq : n ≤ nat_degree q := le_nat_degree_of_map_eq_mul_X_pow hP hq hbc0.2
    have hpmqn : p.nat_degree = m ∧ q.nat_degree = n := by
      rw [nat_degree_mul hp0 hq0] at hmnd
      clear * - hmnd hmp hnq
      contrapose hmnd
      apply ne_of_ltₓ
      rw [not_and_distrib] at hmnd
      cases hmnd
      · exact add_lt_add_of_lt_of_le (lt_of_le_of_neₓ hmp (Ne.symm hmnd)) hnq
        
      · exact add_lt_add_of_le_of_lt hmp (lt_of_le_of_neₓ hnq (Ne.symm hmnd))
        
    obtain rfl | rfl : m = 0 ∨ n = 0 := by
      rwa [pos_iff_ne_zero, pos_iff_ne_zero, imp_false, not_not, ← or_iff_not_imp_left] at hmn
    · exact Or.inl (is_unit_of_nat_degree_eq_zero_of_forall_dvd_is_unit hu hpmqn.1)
      
    · exact
        Or.inr
          (is_unit_of_nat_degree_eq_zero_of_forall_dvd_is_unit
            (by
              simpa only [mul_comm] using hu)
            hpmqn.2)
      ⟩

end Polynomial

