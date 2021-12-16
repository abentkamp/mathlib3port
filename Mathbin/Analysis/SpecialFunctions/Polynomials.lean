import Mathbin.Analysis.Asymptotics.AsymptoticEquivalent 
import Mathbin.Analysis.Asymptotics.SpecificAsymptotics 
import Mathbin.Data.Polynomial.RingDivision

/-!
# Limits related to polynomial and rational functions

This file proves basic facts about limits of polynomial and rationals functions.
The main result is `eval_is_equivalent_at_top_eval_lead`, which states that for
any polynomial `P` of degree `n` with leading coefficient `a`, the corresponding
polynomial function is equivalent to `a * x^n` as `x` goes to +∞.

We can then use this result to prove various limits for polynomial and rational
functions, depending on the degrees and leading coefficients of the considered
polynomials.
-/


open Filter Finset Asymptotics

open_locale Asymptotics TopologicalSpace

namespace Polynomial

variable {𝕜 : Type _} [NormedLinearOrderedField 𝕜] (P Q : Polynomial 𝕜)

theorem eventually_no_roots (hP : P ≠ 0) : ∀ᶠ x in Filter.atTop, ¬P.is_root x :=
  by 
    obtain ⟨x₀, hx₀⟩ := exists_max_root P hP 
    refine' filter.eventually_at_top.mpr ⟨x₀+1, fun x hx h => _⟩
    exact absurd (hx₀ x h) (not_le.mpr (lt_of_lt_of_leₓ (lt_add_one x₀) hx))

variable [OrderTopology 𝕜]

section PolynomialAtTop

theorem is_equivalent_at_top_lead : (fun x => eval x P) ~[at_top] fun x => P.leading_coeff*x ^ P.nat_degree :=
  by 
    byCases' h : P = 0
    ·
      simp [h]
    ·
      convLHS => ext rw [Polynomial.eval_eq_finset_sum, sum_range_succ]
      exact
        is_equivalent.refl.add_is_o
          (is_o.sum$
            fun i hi =>
              is_o.const_mul_left
                ((is_o.const_mul_right fun hz => h$ leading_coeff_eq_zero.mp hz)$
                  is_o_pow_pow_at_top_of_lt (mem_range.mp hi))
                _)

theorem tendsto_at_top_of_leading_coeff_nonneg (hdeg : 1 ≤ P.degree) (hnng : 0 ≤ P.leading_coeff) :
  tendsto (fun x => eval x P) at_top at_top :=
  P.is_equivalent_at_top_lead.symm.tendsto_at_top
    (tendsto_const_mul_pow_at_top (le_nat_degree_of_coe_le_degree hdeg)
      (lt_of_le_of_neₓ hnng$ Ne.symm$ mt leading_coeff_eq_zero.mp$ ne_zero_of_coe_le_degree hdeg))

theorem tendsto_at_top_iff_leading_coeff_nonneg :
  tendsto (fun x => eval x P) at_top at_top ↔ 1 ≤ P.degree ∧ 0 ≤ P.leading_coeff :=
  by 
    refine' ⟨fun h => _, fun h => tendsto_at_top_of_leading_coeff_nonneg P h.1 h.2⟩
    have  : tendsto (fun x => P.leading_coeff*x ^ P.nat_degree) at_top at_top :=
      is_equivalent.tendsto_at_top (is_equivalent_at_top_lead P) h 
    rw [tendsto_const_mul_pow_at_top_iff P.leading_coeff P.nat_degree] at this 
    rw [degree_eq_nat_degree (leading_coeff_ne_zero.mp (ne_of_ltₓ this.2).symm), ←Nat.cast_one]
    refine' ⟨with_bot.coe_le_coe.mpr this.1, le_of_ltₓ this.2⟩

theorem tendsto_at_bot_of_leading_coeff_nonpos (hdeg : 1 ≤ P.degree) (hnps : P.leading_coeff ≤ 0) :
  tendsto (fun x => eval x P) at_top at_bot :=
  P.is_equivalent_at_top_lead.symm.tendsto_at_bot
    (tendsto_neg_const_mul_pow_at_top (le_nat_degree_of_coe_le_degree hdeg)
      (lt_of_le_of_neₓ hnps$ mt leading_coeff_eq_zero.mp$ ne_zero_of_coe_le_degree hdeg))

theorem tendsto_at_bot_iff_leading_coeff_nonpos :
  tendsto (fun x => eval x P) at_top at_bot ↔ 1 ≤ P.degree ∧ P.leading_coeff ≤ 0 :=
  by 
    refine' ⟨fun h => _, fun h => tendsto_at_bot_of_leading_coeff_nonpos P h.1 h.2⟩
    have  : tendsto (fun x => P.leading_coeff*x ^ P.nat_degree) at_top at_bot :=
      is_equivalent.tendsto_at_bot (is_equivalent_at_top_lead P) h 
    rw [tendsto_neg_const_mul_pow_at_top_iff P.leading_coeff P.nat_degree] at this 
    rw [degree_eq_nat_degree (leading_coeff_ne_zero.mp (ne_of_ltₓ this.2)), ←Nat.cast_one]
    refine' ⟨with_bot.coe_le_coe.mpr this.1, le_of_ltₓ this.2⟩

theorem abs_tendsto_at_top (hdeg : 1 ≤ P.degree) : tendsto (fun x => abs$ eval x P) at_top at_top :=
  by 
    byCases' hP : 0 ≤ P.leading_coeff
    ·
      exact tendsto_abs_at_top_at_top.comp (P.tendsto_at_top_of_leading_coeff_nonneg hdeg hP)
    ·
      pushNeg  at hP 
      exact tendsto_abs_at_bot_at_top.comp (P.tendsto_at_bot_of_leading_coeff_nonpos hdeg hP.le)

theorem abs_is_bounded_under_iff : (is_bounded_under (· ≤ ·) at_top fun x => |eval x P|) ↔ P.degree ≤ 0 :=
  by 
    refine'
      ⟨fun h => _,
        fun h =>
          ⟨|P.coeff 0|,
            eventually_map.mpr
              (eventually_of_forall
                (forall_imp (fun _ => le_of_eqₓ)
                  fun x => congr_argₓ abs$ trans (congr_argₓ (eval x) (eq_C_of_degree_le_zero h)) eval_C))⟩⟩
    contrapose! h 
    exact not_is_bounded_under_of_tendsto_at_top (abs_tendsto_at_top P (Nat.WithBot.one_le_iff_zero_lt.2 h))

theorem abs_tendsto_at_top_iff : tendsto (fun x => abs$ eval x P) at_top at_top ↔ 1 ≤ P.degree :=
  ⟨fun h =>
      Nat.WithBot.one_le_iff_zero_lt.2
        (not_leₓ.mp ((mt (abs_is_bounded_under_iff P).mpr) (not_is_bounded_under_of_tendsto_at_top h))),
    abs_tendsto_at_top P⟩

theorem tendsto_nhds_iff {c : 𝕜} : tendsto (fun x => eval x P) at_top (𝓝 c) ↔ P.leading_coeff = c ∧ P.degree ≤ 0 :=
  by 
    refine' ⟨fun h => _, fun h => _⟩
    ·
      have  := P.is_equivalent_at_top_lead.tendsto_nhds h 
      byCases' hP : P.leading_coeff = 0
      ·
        simp only [hP, zero_mul, tendsto_const_nhds_iff] at this 
        refine'
          ⟨trans hP this,
            by 
              simp [leading_coeff_eq_zero.1 hP]⟩
      ·
        rw [tendsto_const_mul_pow_nhds_iff hP, nat_degree_eq_zero_iff_degree_le_zero] at this 
        exact this.symm
    ·
      refine' P.is_equivalent_at_top_lead.symm.tendsto_nhds _ 
      have  : P.nat_degree = 0 := nat_degree_eq_zero_iff_degree_le_zero.2 h.2
      simp only [h.1, this, pow_zeroₓ, mul_oneₓ]
      exact tendsto_const_nhds

end PolynomialAtTop

section PolynomialDivAtTop

theorem is_equivalent_at_top_div :
  (fun x => eval x P / eval x Q) ~[at_top]
    fun x => (P.leading_coeff / Q.leading_coeff)*x ^ (P.nat_degree - Q.nat_degree : ℤ) :=
  by 
    byCases' hP : P = 0
    ·
      simp [hP]
    byCases' hQ : Q = 0
    ·
      simp [hQ]
    refine'
      (P.is_equivalent_at_top_lead.symm.div Q.is_equivalent_at_top_lead.symm).symm.trans
        (eventually_eq.is_equivalent ((eventually_gt_at_top 0).mono$ fun x hx => _))
    simp [←div_mul_div, hP, hQ, zpow_sub₀ hx.ne.symm]

theorem div_tendsto_zero_of_degree_lt (hdeg : P.degree < Q.degree) :
  tendsto (fun x => eval x P / eval x Q) at_top (𝓝 0) :=
  by 
    byCases' hP : P = 0
    ·
      simp [hP, tendsto_const_nhds]
    rw [←nat_degree_lt_nat_degree_iff hP] at hdeg 
    refine' (is_equivalent_at_top_div P Q).symm.tendsto_nhds _ 
    rw [←mul_zero]
    refine' (tendsto_zpow_at_top_zero _).const_mul _ 
    linarith

theorem div_tendsto_zero_iff_degree_lt (hQ : Q ≠ 0) :
  tendsto (fun x => eval x P / eval x Q) at_top (𝓝 0) ↔ P.degree < Q.degree :=
  by 
    refine' ⟨fun h => _, div_tendsto_zero_of_degree_lt P Q⟩
    byCases' hPQ : P.leading_coeff / Q.leading_coeff = 0
    ·
      simp only [div_eq_mul_inv, inv_eq_zero, mul_eq_zero] at hPQ 
      cases' hPQ with hP0 hQ0
      ·
        rw [leading_coeff_eq_zero.1 hP0, degree_zero]
        exact bot_lt_iff_ne_bot.2 fun hQ' => hQ (degree_eq_bot.1 hQ')
      ·
        exact absurd (leading_coeff_eq_zero.1 hQ0) hQ
    ·
      have  := (is_equivalent_at_top_div P Q).tendsto_nhds h 
      rw [tendsto_const_mul_zpow_at_top_zero_iff hPQ] at this 
      cases' this with h h
      ·
        exact absurd h.2 hPQ
      ·
        rw [sub_lt_iff_lt_add, zero_addₓ, Int.coe_nat_lt] at h 
        exact degree_lt_degree h.1

theorem div_tendsto_leading_coeff_div_of_degree_eq (hdeg : P.degree = Q.degree) :
  tendsto (fun x => eval x P / eval x Q) at_top (𝓝$ P.leading_coeff / Q.leading_coeff) :=
  by 
    refine' (is_equivalent_at_top_div P Q).symm.tendsto_nhds _ 
    rw
      [show (P.nat_degree : ℤ) = Q.nat_degree by 
        simp [hdeg, nat_degree]]
    simp [tendsto_const_nhds]

theorem div_tendsto_at_top_of_degree_gt' (hdeg : Q.degree < P.degree) (hpos : 0 < P.leading_coeff / Q.leading_coeff) :
  tendsto (fun x => eval x P / eval x Q) at_top at_top :=
  by 
    have hQ : Q ≠ 0 :=
      fun h =>
        by 
          simp only [h, div_zero, leading_coeff_zero] at hpos 
          linarith 
    rw [←nat_degree_lt_nat_degree_iff hQ] at hdeg 
    refine' (is_equivalent_at_top_div P Q).symm.tendsto_at_top _ 
    apply tendsto.const_mul_at_top hpos 
    apply tendsto_zpow_at_top_at_top 
    linarith

theorem div_tendsto_at_top_of_degree_gt (hdeg : Q.degree < P.degree) (hQ : Q ≠ 0)
  (hnng : 0 ≤ P.leading_coeff / Q.leading_coeff) : tendsto (fun x => eval x P / eval x Q) at_top at_top :=
  have ratio_pos : 0 < P.leading_coeff / Q.leading_coeff :=
    lt_of_le_of_neₓ hnng
      (div_ne_zero (fun h => ne_zero_of_degree_gt hdeg$ leading_coeff_eq_zero.mp h)
          fun h => hQ$ leading_coeff_eq_zero.mp h).symm
        
  div_tendsto_at_top_of_degree_gt' P Q hdeg ratio_pos

theorem div_tendsto_at_bot_of_degree_gt' (hdeg : Q.degree < P.degree) (hneg : P.leading_coeff / Q.leading_coeff < 0) :
  tendsto (fun x => eval x P / eval x Q) at_top at_bot :=
  by 
    have hQ : Q ≠ 0 :=
      fun h =>
        by 
          simp only [h, div_zero, leading_coeff_zero] at hneg 
          linarith 
    rw [←nat_degree_lt_nat_degree_iff hQ] at hdeg 
    refine' (is_equivalent_at_top_div P Q).symm.tendsto_at_bot _ 
    apply tendsto.neg_const_mul_at_top hneg 
    apply tendsto_zpow_at_top_at_top 
    linarith

theorem div_tendsto_at_bot_of_degree_gt (hdeg : Q.degree < P.degree) (hQ : Q ≠ 0)
  (hnps : P.leading_coeff / Q.leading_coeff ≤ 0) : tendsto (fun x => eval x P / eval x Q) at_top at_bot :=
  have ratio_neg : P.leading_coeff / Q.leading_coeff < 0 :=
    lt_of_le_of_neₓ hnps
      (div_ne_zero (fun h => ne_zero_of_degree_gt hdeg$ leading_coeff_eq_zero.mp h)
        fun h => hQ$ leading_coeff_eq_zero.mp h)
  div_tendsto_at_bot_of_degree_gt' P Q hdeg ratio_neg

theorem abs_div_tendsto_at_top_of_degree_gt (hdeg : Q.degree < P.degree) (hQ : Q ≠ 0) :
  tendsto (fun x => |eval x P / eval x Q|) at_top at_top :=
  by 
    byCases' h : 0 ≤ P.leading_coeff / Q.leading_coeff
    ·
      exact tendsto_abs_at_top_at_top.comp (P.div_tendsto_at_top_of_degree_gt Q hdeg hQ h)
    ·
      pushNeg  at h 
      exact tendsto_abs_at_bot_at_top.comp (P.div_tendsto_at_bot_of_degree_gt Q hdeg hQ h.le)

end PolynomialDivAtTop

theorem is_O_of_degree_le (h : P.degree ≤ Q.degree) : is_O (fun x => eval x P) (fun x => eval x Q) Filter.atTop :=
  by 
    byCases' hp : P = 0
    ·
      simpa [hp] using is_O_zero (fun x => eval x Q) Filter.atTop
    ·
      have hq : Q ≠ 0 := ne_zero_of_degree_ge_degree h hp 
      have hPQ : ∀ᶠ x : 𝕜 in at_top, eval x Q = 0 → eval x P = 0 :=
        Filter.mem_of_superset (Polynomial.eventually_no_roots Q hq) fun x h h' => absurd h' h 
      cases' le_iff_lt_or_eq.mp h with h h
      ·
        exact is_O_of_div_tendsto_nhds hPQ 0 (div_tendsto_zero_of_degree_lt P Q h)
      ·
        exact is_O_of_div_tendsto_nhds hPQ _ (div_tendsto_leading_coeff_div_of_degree_eq P Q h)

end Polynomial

