/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johannes Hölzl, Scott Morrison, Jens Wagemaker
-/
import Mathbin.Data.Polynomial.Inductions
import Mathbin.Data.Polynomial.Monic
import Mathbin.RingTheory.Multiplicity

/-!
# Division of univariate polynomials

The main defs are `div_by_monic` and `mod_by_monic`.
The compatibility between these is given by `mod_by_monic_add_div`.
We also define `root_multiplicity`.
-/


noncomputable section

open Classical BigOperators Polynomial

open Finset

namespace Polynomial

universe u v w z

variable {R : Type u} {S : Type v} {T : Type w} {A : Type z} {a b : R} {n : ℕ}

section CommSemiringₓ

variable [CommSemiringₓ R]

theorem X_dvd_iff {α : Type u} [CommSemiringₓ α] {f : α[X]} : X ∣ f ↔ f.coeff 0 = 0 :=
  ⟨fun ⟨g, hfg⟩ => by
    rw [hfg, mul_comm, coeff_mul_X_zero], fun hf =>
    ⟨f.divX, by
      rw [mul_comm, ← add_zeroₓ (f.div_X * X), ← C_0, ← hf, div_X_mul_X_add]⟩⟩

end CommSemiringₓ

section CommSemiringₓ

variable [CommSemiringₓ R] {p q : R[X]}

theorem multiplicity_finite_of_degree_pos_of_monic (hp : (0 : WithBot ℕ) < degree p) (hmp : Monic p) (hq : q ≠ 0) :
    multiplicity.Finite p q :=
  have zn0 : (0 : R) ≠ 1 :=
    haveI := nontrivial.of_polynomial_ne hq
    zero_ne_one
  ⟨natDegree q, fun ⟨r, hr⟩ => by
    have hp0 : p ≠ 0 := fun hp0 => by
      simp [hp0] at hp <;> contradiction
    have hr0 : r ≠ 0 := fun hr0 => by
      simp_all
    have hpn1 : leadingCoeff p ^ (natDegree q + 1) = 1 := by
      simp [show _ = _ from hmp]
    have hpn0' : leadingCoeff p ^ (natDegree q + 1) ≠ 0 := hpn1.symm ▸ zn0.symm
    have hpnr0 : leadingCoeff (p ^ (natDegree q + 1)) * leadingCoeff r ≠ 0 := by
      simp only [leading_coeff_pow' hpn0', leading_coeff_eq_zero, hpn1, one_pow, one_mulₓ, Ne.def, hr0] <;> simp
    have hnp : 0 < natDegree p := by
      rw [← WithBot.coe_lt_coe, ← degree_eq_nat_degree hp0] <;> exact hp
    have := congr_argₓ nat_degree hr
    rw [nat_degree_mul' hpnr0, nat_degree_pow' hpn0', add_mulₓ, add_assocₓ] at this
    exact
      ne_of_ltₓ
        (lt_add_of_le_of_pos (le_mul_of_one_le_right (Nat.zero_leₓ _) hnp)
          (add_pos_of_pos_of_nonneg
            (by
              rwa [one_mulₓ])
            (Nat.zero_leₓ _)))
        this⟩

end CommSemiringₓ

section Ringₓ

variable [Ringₓ R] {p q : R[X]}

theorem div_wf_lemma (h : degree q ≤ degree p ∧ p ≠ 0) (hq : Monic q) :
    degree (p - c (leadingCoeff p) * X ^ (natDegree p - natDegree q) * q) < degree p :=
  have hp : leadingCoeff p ≠ 0 := mt leading_coeff_eq_zero.1 h.2
  have hq0 : q ≠ 0 := hq.ne_zero_of_polynomial_ne h.2
  have hlt : natDegree q ≤ natDegree p :=
    WithBot.coe_le_coe.1
      (by
        rw [← degree_eq_nat_degree h.2, ← degree_eq_nat_degree hq0] <;> exact h.1)
  degree_sub_lt
    (by
      rw [hq.degree_mul, degree_C_mul_X_pow _ hp, degree_eq_nat_degree h.2, degree_eq_nat_degree hq0, ← WithBot.coe_add,
        tsub_add_cancel_of_le hlt])
    h.2
    (by
      rw [leading_coeff_mul_monic hq, leading_coeff_mul_X_pow, leading_coeff_C])

/-- See `div_by_monic`. -/
noncomputable def divModByMonicAux : ∀ (p : R[X]) {q : R[X]}, Monic q → R[X] × R[X]
  | p => fun q hq =>
    if h : degree q ≤ degree p ∧ p ≠ 0 then
      let z := c (leadingCoeff p) * X ^ (natDegree p - natDegree q)
      have wf := div_wf_lemma h hq
      let dm := div_mod_by_monic_aux (p - z * q) hq
      ⟨z + dm.1, dm.2⟩
    else ⟨0, p⟩

/-- `div_by_monic` gives the quotient of `p` by a monic polynomial `q`. -/
def divByMonic (p q : R[X]) : R[X] :=
  if hq : Monic q then (divModByMonicAux p hq).1 else 0

/-- `mod_by_monic` gives the remainder of `p` by a monic polynomial `q`. -/
def modByMonic (p q : R[X]) : R[X] :=
  if hq : Monic q then (divModByMonicAux p hq).2 else p

-- mathport name: «expr /ₘ »
infixl:70 " /ₘ " => divByMonic

-- mathport name: «expr %ₘ »
infixl:70 " %ₘ " => modByMonic

theorem degree_mod_by_monic_lt [Nontrivial R] : ∀ (p : R[X]) {q : R[X]} (hq : Monic q), degree (p %ₘ q) < degree q
  | p => fun q hq =>
    if h : degree q ≤ degree p ∧ p ≠ 0 then by
      have wf := div_wf_lemma ⟨h.1, h.2⟩ hq
      have : degree ((p - c (leadingCoeff p) * X ^ (natDegree p - natDegree q) * q) %ₘ q) < degree q :=
        degree_mod_by_monic_lt (p - c (leadingCoeff p) * X ^ (natDegree p - natDegree q) * q) hq
      unfold mod_by_monic  at this⊢
      unfold div_mod_by_monic_aux
      rw [dif_pos hq] at this⊢
      rw [if_pos h]
      exact this
    else
      Or.cases_on (not_and_distrib.1 h)
        (by
          unfold mod_by_monic div_mod_by_monic_aux
          rw [dif_pos hq, if_neg h]
          exact lt_of_not_geₓ)
        (by
          intro hp
          unfold mod_by_monic div_mod_by_monic_aux
          rw [dif_pos hq, if_neg h, not_not.1 hp]
          exact lt_of_le_of_neₓ bot_le (Ne.symm (mt degree_eq_bot.1 hq.ne_zero)))

@[simp]
theorem zero_mod_by_monic (p : R[X]) : 0 %ₘ p = 0 := by
  unfold mod_by_monic div_mod_by_monic_aux
  by_cases' hp : monic p
  · rw [dif_pos hp, if_neg (mt And.right (not_not_intro rfl))]
    
  · rw [dif_neg hp]
    

@[simp]
theorem zero_div_by_monic (p : R[X]) : 0 /ₘ p = 0 := by
  unfold div_by_monic div_mod_by_monic_aux
  by_cases' hp : monic p
  · rw [dif_pos hp, if_neg (mt And.right (not_not_intro rfl))]
    
  · rw [dif_neg hp]
    

@[simp]
theorem mod_by_monic_zero (p : R[X]) : p %ₘ 0 = p :=
  if h : Monic (0 : R[X]) then by
    haveI := monic_zero_iff_subsingleton.mp h
    simp
  else by
    unfold mod_by_monic div_mod_by_monic_aux <;> rw [dif_neg h]

@[simp]
theorem div_by_monic_zero (p : R[X]) : p /ₘ 0 = 0 :=
  if h : Monic (0 : R[X]) then by
    haveI := monic_zero_iff_subsingleton.mp h
    simp
  else by
    unfold div_by_monic div_mod_by_monic_aux <;> rw [dif_neg h]

theorem div_by_monic_eq_of_not_monic (p : R[X]) (hq : ¬Monic q) : p /ₘ q = 0 :=
  dif_neg hq

theorem mod_by_monic_eq_of_not_monic (p : R[X]) (hq : ¬Monic q) : p %ₘ q = p :=
  dif_neg hq

theorem mod_by_monic_eq_self_iff [Nontrivial R] (hq : Monic q) : p %ₘ q = p ↔ degree p < degree q :=
  ⟨fun h => h ▸ degree_mod_by_monic_lt _ hq, fun h => by
    have : ¬degree q ≤ degree p := not_le_of_gtₓ h
    unfold mod_by_monic div_mod_by_monic_aux <;> rw [dif_pos hq, if_neg (mt And.left this)]⟩

theorem degree_mod_by_monic_le (p : R[X]) {q : R[X]} (hq : Monic q) : degree (p %ₘ q) ≤ degree q := by
  nontriviality R
  exact (degree_mod_by_monic_lt _ hq).le

end Ringₓ

section CommRingₓ

variable [CommRingₓ R] {p q : R[X]}

theorem mod_by_monic_eq_sub_mul_div : ∀ (p : R[X]) {q : R[X]} (hq : Monic q), p %ₘ q = p - q * (p /ₘ q)
  | p => fun q hq =>
    if h : degree q ≤ degree p ∧ p ≠ 0 then by
      have wf := div_wf_lemma h hq
      have ih := mod_by_monic_eq_sub_mul_div (p - c (leadingCoeff p) * X ^ (natDegree p - natDegree q) * q) hq
      unfold mod_by_monic div_by_monic div_mod_by_monic_aux
      rw [dif_pos hq, if_pos h]
      rw [mod_by_monic, dif_pos hq] at ih
      refine' ih.trans _
      unfold div_by_monic
      rw [dif_pos hq, dif_pos hq, if_pos h, mul_addₓ, sub_add_eq_sub_sub, mul_comm]
    else by
      unfold mod_by_monic div_by_monic div_mod_by_monic_aux
      rw [dif_pos hq, if_neg h, dif_pos hq, if_neg h, mul_zero, sub_zero]

theorem mod_by_monic_add_div (p : R[X]) {q : R[X]} (hq : Monic q) : p %ₘ q + q * (p /ₘ q) = p :=
  eq_sub_iff_add_eq.1 (mod_by_monic_eq_sub_mul_div p hq)

theorem div_by_monic_eq_zero_iff [Nontrivial R] (hq : Monic q) : p /ₘ q = 0 ↔ degree p < degree q :=
  ⟨fun h => by
    have := mod_by_monic_add_div p hq <;> rwa [h, mul_zero, add_zeroₓ, mod_by_monic_eq_self_iff hq] at this, fun h => by
    have : ¬degree q ≤ degree p := not_le_of_gtₓ h
    unfold div_by_monic div_mod_by_monic_aux <;> rw [dif_pos hq, if_neg (mt And.left this)]⟩

theorem degree_add_div_by_monic (hq : Monic q) (h : degree q ≤ degree p) : degree q + degree (p /ₘ q) = degree p := by
  nontriviality R
  have hdiv0 : p /ₘ q ≠ 0 := by
    rwa [(· ≠ ·), div_by_monic_eq_zero_iff hq, not_ltₓ]
  have hlc : leading_coeff q * leading_coeff (p /ₘ q) ≠ 0 := by
    rwa [monic.def.1 hq, one_mulₓ, (· ≠ ·), leading_coeff_eq_zero]
  have hmod : degree (p %ₘ q) < degree (q * (p /ₘ q)) :=
    calc
      degree (p %ₘ q) < degree q := degree_mod_by_monic_lt _ hq
      _ ≤ _ := by
        rw [degree_mul' hlc, degree_eq_nat_degree hq.ne_zero, degree_eq_nat_degree hdiv0, ← WithBot.coe_add,
            WithBot.coe_le_coe] <;>
          exact Nat.le_add_rightₓ _ _
      
  calc
    degree q + degree (p /ₘ q) = degree (q * (p /ₘ q)) := Eq.symm (degree_mul' hlc)
    _ = degree (p %ₘ q + q * (p /ₘ q)) := (degree_add_eq_right_of_degree_lt hmod).symm
    _ = _ := congr_argₓ _ (mod_by_monic_add_div _ hq)
    

theorem degree_div_by_monic_le (p q : R[X]) : degree (p /ₘ q) ≤ degree p :=
  if hp0 : p = 0 then by
    simp only [hp0, zero_div_by_monic, le_reflₓ]
  else
    if hq : Monic q then
      if h : degree q ≤ degree p then by
        haveI := nontrivial.of_polynomial_ne hp0 <;>
          rw [← degree_add_div_by_monic hq h, degree_eq_nat_degree hq.ne_zero,
              degree_eq_nat_degree (mt (div_by_monic_eq_zero_iff hq).1 (not_ltₓ.2 h))] <;>
            exact WithBot.coe_le_coe.2 (Nat.le_add_leftₓ _ _)
      else by
        unfold div_by_monic div_mod_by_monic_aux <;>
          simp only [dif_pos hq, h, false_andₓ, if_false, degree_zero, bot_le]
    else (div_by_monic_eq_of_not_monic p hq).symm ▸ bot_le

theorem degree_div_by_monic_lt (p : R[X]) {q : R[X]} (hq : Monic q) (hp0 : p ≠ 0) (h0q : 0 < degree q) :
    degree (p /ₘ q) < degree p :=
  if hpq : degree p < degree q then by
    haveI := nontrivial.of_polynomial_ne hp0
    rw [(div_by_monic_eq_zero_iff hq).2 hpq, degree_eq_nat_degree hp0]
    exact WithBot.bot_lt_coe _
  else by
    haveI := nontrivial.of_polynomial_ne hp0
    rw [← degree_add_div_by_monic hq (not_ltₓ.1 hpq), degree_eq_nat_degree hq.ne_zero,
      degree_eq_nat_degree (mt (div_by_monic_eq_zero_iff hq).1 hpq)]
    exact WithBot.coe_lt_coe.2 (Nat.lt_add_of_pos_leftₓ (WithBot.coe_lt_coe.1 <| degree_eq_nat_degree hq.ne_zero ▸ h0q))

theorem nat_degree_div_by_monic {R : Type u} [CommRingₓ R] (f : R[X]) {g : R[X]} (hg : g.Monic) :
    natDegree (f /ₘ g) = natDegree f - natDegree g := by
  nontriviality R
  by_cases' hfg : f /ₘ g = 0
  · rw [hfg, nat_degree_zero]
    rw [div_by_monic_eq_zero_iff hg] at hfg
    rw [tsub_eq_zero_iff_le.mpr (nat_degree_le_nat_degree <| le_of_ltₓ hfg)]
    
  have hgf := hfg
  rw [div_by_monic_eq_zero_iff hg] at hgf
  push_neg  at hgf
  have := degree_add_div_by_monic hg hgf
  have hf : f ≠ 0 := by
    intro hf
    apply hfg
    rw [hf, zero_div_by_monic]
  rw [degree_eq_nat_degree hf, degree_eq_nat_degree hg.ne_zero, degree_eq_nat_degree hfg, ← WithBot.coe_add,
    WithBot.coe_eq_coe] at this
  rw [← this, add_tsub_cancel_left]

theorem div_mod_by_monic_unique {f g} (q r : R[X]) (hg : Monic g) (h : r + g * q = f ∧ degree r < degree g) :
    f /ₘ g = q ∧ f %ₘ g = r := by
  nontriviality R
  have h₁ : r - f %ₘ g = -g * (q - f /ₘ g) :=
    eq_of_sub_eq_zero
      (by
        rw [← sub_eq_zero_of_eq (h.1.trans (mod_by_monic_add_div f hg).symm)] <;>
          simp [mul_addₓ, mul_comm, sub_eq_add_neg, add_commₓ, add_left_commₓ, add_assocₓ])
  have h₂ : degree (r - f %ₘ g) = degree (g * (q - f /ₘ g)) := by
    simp [h₁]
  have h₄ : degree (r - f %ₘ g) < degree g :=
    calc
      degree (r - f %ₘ g) ≤ max (degree r) (degree (f %ₘ g)) := degree_sub_le _ _
      _ < degree g := max_lt_iff.2 ⟨h.2, degree_mod_by_monic_lt _ hg⟩
      
  have h₅ : q - f /ₘ g = 0 :=
    by_contradiction fun hqf =>
      not_le_of_gtₓ h₄ <|
        calc
          degree g ≤ degree g + degree (q - f /ₘ g) := by
            erw [degree_eq_nat_degree hg.ne_zero, degree_eq_nat_degree hqf, WithBot.coe_le_coe] <;>
              exact Nat.le_add_rightₓ _ _
          _ = degree (r - f %ₘ g) := by
            rw [h₂, degree_mul'] <;> simpa [monic.def.1 hg]
          
  exact
    ⟨Eq.symm <| eq_of_sub_eq_zero h₅,
      Eq.symm <|
        eq_of_sub_eq_zero <| by
          simpa [h₅] using h₁⟩

theorem map_mod_div_by_monic [CommRingₓ S] (f : R →+* S) (hq : Monic q) :
    (p /ₘ q).map f = p.map f /ₘ q.map f ∧ (p %ₘ q).map f = p.map f %ₘ q.map f := by
  nontriviality S
  haveI : Nontrivial R := f.domain_nontrivial
  have : map f p /ₘ map f q = map f (p /ₘ q) ∧ map f p %ₘ map f q = map f (p %ₘ q) :=
    div_mod_by_monic_unique ((p /ₘ q).map f) _ (hq.map f)
      ⟨Eq.symm <| by
          rw [← Polynomial.map_mul, ← Polynomial.map_add, mod_by_monic_add_div _ hq],
        calc
          _ ≤ degree (p %ₘ q) := degree_map_le _ _
          _ < degree q := degree_mod_by_monic_lt _ hq
          _ = _ :=
            Eq.symm <|
              degree_map_eq_of_leading_coeff_ne_zero _
                (by
                  rw [monic.def.1 hq, f.map_one] <;> exact one_ne_zero)
          ⟩
  exact ⟨this.1.symm, this.2.symm⟩

theorem map_div_by_monic [CommRingₓ S] (f : R →+* S) (hq : Monic q) : (p /ₘ q).map f = p.map f /ₘ q.map f :=
  (map_mod_div_by_monic f hq).1

theorem map_mod_by_monic [CommRingₓ S] (f : R →+* S) (hq : Monic q) : (p %ₘ q).map f = p.map f %ₘ q.map f :=
  (map_mod_div_by_monic f hq).2

theorem dvd_iff_mod_by_monic_eq_zero (hq : Monic q) : p %ₘ q = 0 ↔ q ∣ p :=
  ⟨fun h => by
    rw [← mod_by_monic_add_div p hq, h, zero_addₓ] <;> exact dvd_mul_right _ _, fun h => by
    nontriviality R
    obtain ⟨r, hr⟩ := exists_eq_mul_right_of_dvd h
    by_contra hpq0
    have hmod : p %ₘ q = q * (r - p /ₘ q) := by
      rw [mod_by_monic_eq_sub_mul_div _ hq, mul_sub, ← hr]
    have : degree (q * (r - p /ₘ q)) < degree q := hmod ▸ degree_mod_by_monic_lt _ hq
    have hrpq0 : leading_coeff (r - p /ₘ q) ≠ 0 := fun h =>
      hpq0 <|
        leading_coeff_eq_zero.1
          (by
            rw [hmod, leading_coeff_eq_zero.1 h, mul_zero, leading_coeff_zero])
    have hlc : leading_coeff q * leading_coeff (r - p /ₘ q) ≠ 0 := by
      rwa [monic.def.1 hq, one_mulₓ]
    rw [degree_mul' hlc, degree_eq_nat_degree hq.ne_zero, degree_eq_nat_degree (mt leading_coeff_eq_zero.2 hrpq0)] at
      this
    exact not_lt_of_geₓ (Nat.le_add_rightₓ _ _) (WithBot.some_lt_some.1 this)⟩

theorem map_dvd_map [CommRingₓ S] (f : R →+* S) (hf : Function.Injective f) {x y : R[X]} (hx : x.Monic) :
    x.map f ∣ y.map f ↔ x ∣ y := by
  rw [← dvd_iff_mod_by_monic_eq_zero hx, ← dvd_iff_mod_by_monic_eq_zero (hx.map f), ← map_mod_by_monic f hx]
  exact
    ⟨fun H =>
      map_injective f hf <| by
        rw [H, Polynomial.map_zero],
      fun H => by
      rw [H, Polynomial.map_zero]⟩

@[simp]
theorem mod_by_monic_one (p : R[X]) : p %ₘ 1 = 0 :=
  (dvd_iff_mod_by_monic_eq_zero
        (by
          convert monic_one)).2
    (one_dvd _)

@[simp]
theorem div_by_monic_one (p : R[X]) : p /ₘ 1 = p := by
  conv_rhs => rw [← mod_by_monic_add_div p monic_one] <;> simp

@[simp]
theorem mod_by_monic_X_sub_C_eq_C_eval (p : R[X]) (a : R) : p %ₘ (X - c a) = c (p.eval a) := by
  nontriviality R
  have h : (p %ₘ (X - C a)).eval a = p.eval a := by
    rw [mod_by_monic_eq_sub_mul_div _ (monic_X_sub_C a), eval_sub, eval_mul, eval_sub, eval_X, eval_C, sub_self,
      zero_mul, sub_zero]
  have : degree (p %ₘ (X - C a)) < 1 := degree_X_sub_C a ▸ degree_mod_by_monic_lt p (monic_X_sub_C a)
  have : degree (p %ₘ (X - C a)) ≤ 0 := by
    cases degree (p %ₘ (X - C a))
    · exact bot_le
      
    · exact WithBot.some_le_some.2 (Nat.le_of_lt_succₓ (WithBot.some_lt_some.1 this))
      
  rw [eq_C_of_degree_le_zero this, eval_C] at h
  rw [eq_C_of_degree_le_zero this, h]

theorem mul_div_by_monic_eq_iff_is_root : (X - c a) * (p /ₘ (X - c a)) = p ↔ IsRoot p a :=
  ⟨fun h => by
    rw [← h, is_root.def, eval_mul, eval_sub, eval_X, eval_C, sub_self, zero_mul], fun h : p.eval a = 0 => by
    conv => rhs rw [← mod_by_monic_add_div p (monic_X_sub_C a)] <;>
      rw [mod_by_monic_X_sub_C_eq_C_eval, h, C_0, zero_addₓ]⟩

theorem dvd_iff_is_root : X - c a ∣ p ↔ IsRoot p a :=
  ⟨fun h => by
    rwa [← dvd_iff_mod_by_monic_eq_zero (monic_X_sub_C _), mod_by_monic_X_sub_C_eq_C_eval, ← C_0, C_inj] at h, fun h =>
    ⟨p /ₘ (X - c a), by
      rw [mul_div_by_monic_eq_iff_is_root.2 h]⟩⟩

theorem mod_by_monic_X (p : R[X]) : p %ₘ X = c (p.eval 0) := by
  rw [← mod_by_monic_X_sub_C_eq_C_eval, C_0, sub_zero]

theorem eval₂_mod_by_monic_eq_self_of_root [CommRingₓ S] {f : R →+* S} {p q : R[X]} (hq : q.Monic) {x : S}
    (hx : q.eval₂ f x = 0) : (p %ₘ q).eval₂ f x = p.eval₂ f x := by
  rw [mod_by_monic_eq_sub_mul_div p hq, eval₂_sub, eval₂_mul, hx, zero_mul, sub_zero]

theorem sum_mod_by_monic_coeff (hq : q.Monic) {n : ℕ} (hn : q.degree ≤ n) :
    (∑ i : Finₓ n, monomial i ((p %ₘ q).coeff i)) = p %ₘ q := by
  nontriviality R
  exact
    (sum_fin (fun i c => monomial i c)
          (by
            simp )
          ((degree_mod_by_monic_lt _ hq).trans_le hn)).trans
      (sum_monomial_eq _)

theorem sub_dvd_eval_sub (a b : R) (p : R[X]) : a - b ∣ p.eval a - p.eval b := by
  suffices X - C b ∣ p - C (p.eval b) by
    simpa only [coe_eval_ring_hom, eval_sub, eval_X, eval_C] using (eval_ring_hom a).map_dvd this
  simp [dvd_iff_is_root]

variable (R)

theorem not_is_field : ¬IsField R[X] := by
  nontriviality R
  rw [Ringₓ.not_is_field_iff_exists_ideal_bot_lt_and_lt_top]
  use Ideal.span {Polynomial.x}
  constructor
  · rw [bot_lt_iff_ne_bot, Ne.def, Ideal.span_singleton_eq_bot]
    exact Polynomial.X_ne_zero
    
  · rw [lt_top_iff_ne_top, Ne.def, Ideal.eq_top_iff_one, Ideal.mem_span_singleton, Polynomial.X_dvd_iff,
      Polynomial.coeff_one_zero]
    exact one_ne_zero
    

variable {R}

section multiplicity

/-- An algorithm for deciding polynomial divisibility.
The algorithm is "compute `p %ₘ q` and compare to `0`".
See `polynomial.mod_by_monic` for the algorithm that computes `%ₘ`.
-/
def decidableDvdMonic (p : R[X]) (hq : Monic q) : Decidable (q ∣ p) :=
  decidableOfIff (p %ₘ q = 0) (dvd_iff_mod_by_monic_eq_zero hq)

open Classical

theorem multiplicity_X_sub_C_finite (a : R) (h0 : p ≠ 0) : multiplicity.Finite (X - c a) p := by
  haveI := nontrivial.of_polynomial_ne h0
  refine' multiplicity_finite_of_degree_pos_of_monic _ (monic_X_sub_C _) h0
  rw [degree_X_sub_C]
  decide

/-- The largest power of `X - C a` which divides `p`.
This is computable via the divisibility algorithm `polynomial.decidable_dvd_monic`. -/
def rootMultiplicity (a : R) (p : R[X]) : ℕ :=
  if h0 : p = 0 then 0
  else
    let I : DecidablePred fun n : ℕ => ¬(X - c a) ^ (n + 1) ∣ p := fun n =>
      @Not.decidable _ (decidableDvdMonic p ((monic_X_sub_C a).pow (n + 1)))
    Nat.findₓ (multiplicity_X_sub_C_finite a h0)

theorem root_multiplicity_eq_multiplicity (p : R[X]) (a : R) :
    rootMultiplicity a p =
      if h0 : p = 0 then 0 else (multiplicity (X - c a) p).get (multiplicity_X_sub_C_finite a h0) :=
  by
  simp [multiplicity, root_multiplicity, Part.Dom] <;> congr <;> funext <;> congr

@[simp]
theorem root_multiplicity_zero {x : R} : rootMultiplicity x 0 = 0 :=
  dif_pos rfl

theorem root_multiplicity_eq_zero {p : R[X]} {x : R} (h : ¬IsRoot p x) : rootMultiplicity x p = 0 := by
  rw [root_multiplicity_eq_multiplicity]
  split_ifs
  · rfl
    
  rw [← PartEnat.coe_inj, PartEnat.coe_get, multiplicity.multiplicity_eq_zero_of_not_dvd, Nat.cast_zeroₓ]
  intro hdvd
  exact h (dvd_iff_is_root.mp hdvd)

theorem root_multiplicity_pos {p : R[X]} (hp : p ≠ 0) {x : R} : 0 < rootMultiplicity x p ↔ IsRoot p x := by
  rw [← dvd_iff_is_root, root_multiplicity_eq_multiplicity, dif_neg hp, ← PartEnat.coe_lt_coe, PartEnat.coe_get]
  exact multiplicity.dvd_iff_multiplicity_pos

@[simp]
theorem root_multiplicity_C (r a : R) : rootMultiplicity a (c r) = 0 := by
  rcases eq_or_ne r 0 with (rfl | hr)
  · simp
    
  · exact root_multiplicity_eq_zero (not_is_root_C _ _ hr)
    

theorem pow_root_multiplicity_dvd (p : R[X]) (a : R) : (X - c a) ^ rootMultiplicity a p ∣ p :=
  if h : p = 0 then by
    simp [h]
  else by
    rw [root_multiplicity_eq_multiplicity, dif_neg h] <;> exact multiplicity.pow_multiplicity_dvd _

theorem div_by_monic_mul_pow_root_multiplicity_eq (p : R[X]) (a : R) :
    p /ₘ (X - c a) ^ rootMultiplicity a p * (X - c a) ^ rootMultiplicity a p = p := by
  have : Monic ((X - c a) ^ rootMultiplicity a p) := (monic_X_sub_C _).pow _
  conv_rhs =>
      rw [← mod_by_monic_add_div p this, (dvd_iff_mod_by_monic_eq_zero this).2 (pow_root_multiplicity_dvd _ _)] <;>
    simp [mul_comm]

theorem eval_div_by_monic_pow_root_multiplicity_ne_zero {p : R[X]} (a : R) (hp : p ≠ 0) :
    eval a (p /ₘ (X - c a) ^ rootMultiplicity a p) ≠ 0 := by
  haveI : Nontrivial R := nontrivial.of_polynomial_ne hp
  rw [Ne.def, ← is_root.def, ← dvd_iff_is_root]
  rintro ⟨q, hq⟩
  have := div_by_monic_mul_pow_root_multiplicity_eq p a
  rw [mul_comm, hq, ← mul_assoc, ← pow_succ'ₓ, root_multiplicity_eq_multiplicity, dif_neg hp] at this
  exact
    multiplicity.is_greatest'
      (multiplicity_finite_of_degree_pos_of_monic
        (show (0 : WithBot ℕ) < degree (X - C a) by
          rw [degree_X_sub_C] <;>
            exact by
              decide)
        (monic_X_sub_C _) hp)
      (Nat.lt_succ_selfₓ _) (dvd_of_mul_right_eq _ this)

end multiplicity

end CommRingₓ

end Polynomial

