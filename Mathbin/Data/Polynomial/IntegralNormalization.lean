/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johannes Hölzl, Scott Morrison, Jens Wagemaker
-/
import Mathbin.Data.Polynomial.AlgebraMap
import Mathbin.Data.Polynomial.Degree.Lemmas
import Mathbin.Data.Polynomial.Monic

/-!
# Theory of monic polynomials

We define `integral_normalization`, which relate arbitrary polynomials to monic ones.
-/


open BigOperators Polynomial

namespace Polynomial

universe u v y

variable {R : Type u} {S : Type v} {a b : R} {m n : ℕ} {ι : Type y}

section IntegralNormalization

section Semiringₓ

variable [Semiringₓ R]

/-- If `f : R[X]` is a nonzero polynomial with root `z`, `integral_normalization f` is
a monic polynomial with root `leading_coeff f * z`.

Moreover, `integral_normalization 0 = 0`.
-/
noncomputable def integralNormalization (f : R[X]) : R[X] :=
  ∑ i in f.support, monomial i (if f.degree = i then 1 else coeff f i * f.leadingCoeff ^ (f.natDegree - 1 - i))

@[simp]
theorem integral_normalization_zero : integralNormalization (0 : R[X]) = 0 := by
  simp [integral_normalization]

theorem integral_normalization_coeff {f : R[X]} {i : ℕ} :
    (integralNormalization f).coeff i =
      if f.degree = i then 1 else coeff f i * f.leadingCoeff ^ (f.natDegree - 1 - i) :=
  by
  have : f.coeff i = 0 → f.degree ≠ i := fun hc hd => coeff_ne_zero_of_eq_degree hd hc
  simp (config := { contextual := true })[integral_normalization, coeff_monomial, this, mem_support_iff]

theorem integral_normalization_support {f : R[X]} : (integralNormalization f).support ⊆ f.support := by
  intro
  simp (config := { contextual := true })[integral_normalization, coeff_monomial, mem_support_iff]

theorem integral_normalization_coeff_degree {f : R[X]} {i : ℕ} (hi : f.degree = i) :
    (integralNormalization f).coeff i = 1 := by
  rw [integral_normalization_coeff, if_pos hi]

theorem integral_normalization_coeff_nat_degree {f : R[X]} (hf : f ≠ 0) :
    (integralNormalization f).coeff (natDegree f) = 1 :=
  integral_normalization_coeff_degree (degree_eq_nat_degree hf)

theorem integral_normalization_coeff_ne_degree {f : R[X]} {i : ℕ} (hi : f.degree ≠ i) :
    coeff (integralNormalization f) i = coeff f i * f.leadingCoeff ^ (f.natDegree - 1 - i) := by
  rw [integral_normalization_coeff, if_neg hi]

theorem integral_normalization_coeff_ne_nat_degree {f : R[X]} {i : ℕ} (hi : i ≠ natDegree f) :
    coeff (integralNormalization f) i = coeff f i * f.leadingCoeff ^ (f.natDegree - 1 - i) :=
  integral_normalization_coeff_ne_degree (degree_ne_of_nat_degree_ne hi.symm)

theorem monic_integral_normalization {f : R[X]} (hf : f ≠ 0) : Monic (integralNormalization f) :=
  monic_of_degree_le f.natDegree
    (Finset.sup_le fun i h => WithBot.coe_le_coe.2 <| le_nat_degree_of_mem_supp i <| integral_normalization_support h)
    (integral_normalization_coeff_nat_degree hf)

end Semiringₓ

section IsDomain

variable [Ringₓ R] [IsDomain R]

@[simp]
theorem support_integral_normalization {f : R[X]} : (integralNormalization f).support = f.support := by
  by_cases' hf : f = 0
  · simp [hf]
    
  ext i
  refine' ⟨fun h => integral_normalization_support h, _⟩
  simp only [integral_normalization_coeff, mem_support_iff]
  intro hfi
  split_ifs with hi <;> simp [hfi, hi, pow_ne_zero _ (leading_coeff_ne_zero.mpr hf)]

end IsDomain

section IsDomain

variable [CommRingₓ R] [IsDomain R]

variable [CommSemiringₓ S]

theorem integral_normalization_eval₂_eq_zero {p : R[X]} (f : R →+* S) {z : S} (hz : eval₂ f z p = 0)
    (inj : ∀ x : R, f x = 0 → x = 0) : eval₂ f (z * f p.leadingCoeff) (integralNormalization p) = 0 :=
  calc
    eval₂ f (z * f p.leadingCoeff) (integralNormalization p) =
        p.support.attach.Sum fun i => f (coeff (integralNormalization p) i.1 * p.leadingCoeff ^ i.1) * z ^ i.1 :=
      by
      rw [eval₂, sum_def, support_integral_normalization]
      simp only [mul_comm z, mul_powₓ, mul_assoc, RingHom.map_pow, RingHom.map_mul]
      exact finset.sum_attach.symm
    _ = p.support.attach.Sum fun i => f (coeff p i.1 * p.leadingCoeff ^ (natDegree p - 1)) * z ^ i.1 := by
      by_cases' hp : p = 0
      · simp [hp]
        
      have one_le_deg : 1 ≤ nat_degree p := Nat.succ_le_of_ltₓ (nat_degree_pos_of_eval₂_root hp f hz inj)
      congr with i
      congr 2
      by_cases' hi : i.1 = nat_degree p
      · rw [hi, integral_normalization_coeff_degree, one_mulₓ, leading_coeff, ← pow_succₓ,
          tsub_add_cancel_of_le one_le_deg]
        exact degree_eq_nat_degree hp
        
      · have : i.1 ≤ p.nat_degree - 1 :=
          Nat.le_pred_of_ltₓ (lt_of_le_of_neₓ (le_nat_degree_of_ne_zero (mem_support_iff.mp i.2)) hi)
        rw [integral_normalization_coeff_ne_nat_degree hi, mul_assoc, ← pow_addₓ, tsub_add_cancel_of_le this]
        
    _ = f p.leadingCoeff ^ (natDegree p - 1) * eval₂ f z p := by
      simp_rw [eval₂, sum_def, fun i => mul_comm (coeff p i), RingHom.map_mul, RingHom.map_pow, mul_assoc, ←
        Finset.mul_sum]
      congr 1
      exact @Finset.sum_attach _ _ p.support _ fun i => f (p.coeff i) * z ^ i
    _ = 0 := by
      rw [hz, _root_.mul_zero]
    

theorem integral_normalization_aeval_eq_zero [Algebra R S] {f : R[X]} {z : S} (hz : aeval z f = 0)
    (inj : ∀ x : R, algebraMap R S x = 0 → x = 0) :
    aeval (z * algebraMap R S f.leadingCoeff) (integralNormalization f) = 0 :=
  integral_normalization_eval₂_eq_zero (algebraMap R S) hz inj

end IsDomain

end IntegralNormalization

end Polynomial

