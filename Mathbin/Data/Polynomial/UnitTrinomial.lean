/-
Copyright (c) 2022 Thomas Browning. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning
-/
import Mathbin.Analysis.Complex.Polynomial
import Mathbin.Data.Polynomial.Mirror

/-!
# Unit Trinomials

This file defines irreducible trinomials and proves an irreducibility criterion.

## Main definitions

- `polynomial.is_unit_trinomial`

## Main results

- `polynomial.irreducible_of_coprime`: An irreducibility criterion for unit trinomials.

-/


namespace Polynomial

open Polynomial

open Finset

section Semiringₓ

variable {R : Type _} [Semiringₓ R] (k m n : ℕ) (u v w : R)

/-- Shorthand for a trinomial -/
noncomputable def trinomial :=
  c u * X ^ k + c v * X ^ m + c w * X ^ n

theorem trinomial_def : trinomial k m n u v w = c u * X ^ k + c v * X ^ m + c w * X ^ n :=
  rfl

variable {k m n u v w}

theorem trinomial_leading_coeff' (hkm : k < m) (hmn : m < n) : (trinomial k m n u v w).coeff n = w := by
  rw [trinomial_def, coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow,
    if_neg (hkm.trans hmn).ne', if_neg hmn.ne', if_pos rfl, zero_addₓ, zero_addₓ]

theorem trinomial_middle_coeff (hkm : k < m) (hmn : m < n) : (trinomial k m n u v w).coeff m = v := by
  rw [trinomial_def, coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow, if_neg hkm.ne',
    if_pos rfl, if_neg hmn.ne, zero_addₓ, add_zeroₓ]

theorem trinomial_trailing_coeff' (hkm : k < m) (hmn : m < n) : (trinomial k m n u v w).coeff k = u := by
  rw [trinomial_def, coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow, if_pos rfl,
    if_neg hkm.ne, if_neg (hkm.trans hmn).Ne, add_zeroₓ, add_zeroₓ]

theorem trinomial_nat_degree (hkm : k < m) (hmn : m < n) (hw : w ≠ 0) : (trinomial k m n u v w).natDegree = n := by
  refine'
    nat_degree_eq_of_degree_eq_some
      (le_antisymmₓ (sup_le fun i h => _)
        (le_degree_of_ne_zero
          (by
            rwa [trinomial_leading_coeff' hkm hmn])))
  replace h := support_trinomial' k m n u v w h
  rw [mem_insert, mem_insert, mem_singleton] at h
  rcases h with (rfl | rfl | rfl)
  · exact with_bot.coe_le_coe.mpr (hkm.trans hmn).le
    
  · exact with_bot.coe_le_coe.mpr hmn.le
    
  · exact le_rflₓ
    

theorem trinomial_nat_trailing_degree (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) :
    (trinomial k m n u v w).natTrailingDegree = k := by
  refine'
    nat_trailing_degree_eq_of_trailing_degree_eq_some
      (le_antisymmₓ (le_inf fun i h => _)
          (le_trailing_degree_of_ne_zero
            (by
              rwa [trinomial_trailing_coeff' hkm hmn]))).symm
  replace h := support_trinomial' k m n u v w h
  rw [mem_insert, mem_insert, mem_singleton] at h
  rcases h with (rfl | rfl | rfl)
  · exact le_rflₓ
    
  · exact with_top.coe_le_coe.mpr hkm.le
    
  · exact with_top.coe_le_coe.mpr (hkm.trans hmn).le
    

theorem trinomial_leading_coeff (hkm : k < m) (hmn : m < n) (hw : w ≠ 0) : (trinomial k m n u v w).leadingCoeff = w :=
  by
  rw [leading_coeff, trinomial_nat_degree hkm hmn hw, trinomial_leading_coeff' hkm hmn]

theorem trinomial_trailing_coeff (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) : (trinomial k m n u v w).trailingCoeff = u :=
  by
  rw [trailing_coeff, trinomial_nat_trailing_degree hkm hmn hu, trinomial_trailing_coeff' hkm hmn]

theorem trinomial_monic (hkm : k < m) (hmn : m < n) : (trinomial k m n u v 1).Monic := by
  cases' subsingleton_or_nontrivial R with h h
  · apply Subsingleton.elim
    
  · exact trinomial_leading_coeff hkm hmn one_ne_zero
    

theorem trinomial_mirror (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) (hw : w ≠ 0) :
    (trinomial k m n u v w).mirror = trinomial k (n - m + k) n w v u := by
  rw [mirror, trinomial_nat_trailing_degree hkm hmn hu, reverse, trinomial_nat_degree hkm hmn hw, trinomial_def,
    reflect_add, reflect_add, reflect_C_mul_X_pow, reflect_C_mul_X_pow, reflect_C_mul_X_pow,
    rev_at_le (hkm.trans hmn).le, rev_at_le hmn.le, rev_at_le le_rflₓ, add_mulₓ, add_mulₓ, mul_assoc, mul_assoc,
    mul_assoc, ← pow_addₓ, ← pow_addₓ, ← pow_addₓ, Nat.sub_add_cancelₓ (hkm.trans hmn).le, Nat.sub_self, zero_addₓ,
    add_commₓ, add_commₓ (C u * X ^ n), ← add_assocₓ, ← trinomial_def]

theorem trinomial_support (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) (hv : v ≠ 0) (hw : w ≠ 0) :
    (trinomial k m n u v w).support = {k, m, n} :=
  support_trinomial hkm hmn hu hv hw

end Semiringₓ

variable (p q : ℤ[X])

/-- A unit trinomial is a trinomial with unit coefficients. -/
def IsUnitTrinomial :=
  ∃ (k m n : ℕ)(hkm : k < m)(hmn : m < n)(u v w : Units ℤ), p = trinomial k m n u v w

variable {p q}

namespace IsUnitTrinomial

theorem not_is_unit (hp : p.IsUnitTrinomial) : ¬IsUnit p := by
  obtain ⟨k, m, n, hkm, hmn, u, v, w, rfl⟩ := hp
  exact fun h =>
    ne_zero_of_lt hmn
      ((trinomial_nat_degree hkm hmn w.ne_zero).symm.trans
        (nat_degree_eq_of_degree_eq_some (degree_eq_zero_of_is_unit h)))

theorem card_support_eq_three (hp : p.IsUnitTrinomial) : p.support.card = 3 := by
  obtain ⟨k, m, n, hkm, hmn, u, v, w, rfl⟩ := hp
  exact card_support_trinomial hkm hmn u.ne_zero v.ne_zero w.ne_zero

theorem ne_zero (hp : p.IsUnitTrinomial) : p ≠ 0 := by
  rintro rfl
  exact Nat.zero_ne_bit1 1 hp.card_support_eq_three

theorem coeff_is_unit (hp : p.IsUnitTrinomial) {k : ℕ} (hk : k ∈ p.support) : IsUnit (p.coeff k) := by
  obtain ⟨k, m, n, hkm, hmn, u, v, w, rfl⟩ := hp
  have := support_trinomial' k m n (↑u) (↑v) (↑w) hk
  rw [mem_insert, mem_insert, mem_singleton] at this
  rcases this with (rfl | rfl | rfl)
  · refine'
      ⟨u, by
        rw [trinomial_trailing_coeff' hkm hmn]⟩
    
  · refine'
      ⟨v, by
        rw [trinomial_middle_coeff hkm hmn]⟩
    
  · refine'
      ⟨w, by
        rw [trinomial_leading_coeff' hkm hmn]⟩
    

theorem leading_coeff_is_unit (hp : p.IsUnitTrinomial) : IsUnit p.leadingCoeff :=
  hp.coeff_is_unit (nat_degree_mem_support_of_nonzero hp.ne_zero)

theorem trailing_coeff_is_unit (hp : p.IsUnitTrinomial) : IsUnit p.trailingCoeff :=
  hp.coeff_is_unit (nat_trailing_degree_mem_support_of_nonzero hp.ne_zero)

end IsUnitTrinomial

theorem is_unit_trinomial_iff : p.IsUnitTrinomial ↔ p.support.card = 3 ∧ ∀ k ∈ p.support, IsUnit (p.coeff k) := by
  refine' ⟨fun hp => ⟨hp.card_support_eq_three, fun k => hp.coeff_is_unit⟩, fun hp => _⟩
  obtain ⟨k, m, n, hkm, hmn, x, y, z, hx, hy, hz, rfl⟩ := card_support_eq_three.mp hp.1
  rw [support_trinomial hkm hmn hx hy hz] at hp
  replace hx := hp.2 k (mem_insert_self k {m, n})
  replace hy := hp.2 m (mem_insert_of_mem (mem_insert_self m {n}))
  replace hz := hp.2 n (mem_insert_of_mem (mem_insert_of_mem (mem_singleton_self n)))
  simp_rw [coeff_add, coeff_C_mul, coeff_X_pow_self, mul_oneₓ, coeff_X_pow] at hx hy hz
  rw [if_neg hkm.ne, if_neg (hkm.trans hmn).Ne] at hx
  rw [if_neg hkm.ne', if_neg hmn.ne] at hy
  rw [if_neg (hkm.trans hmn).ne', if_neg hmn.ne'] at hz
  simp_rw [mul_zero, zero_addₓ, add_zeroₓ] at hx hy hz
  exact ⟨k, m, n, hkm, hmn, hx.unit, hy.unit, hz.unit, rfl⟩

theorem is_unit_trinomial_iff' :
    p.IsUnitTrinomial ↔ (p * p.mirror).coeff (((p * p.mirror).natDegree + (p * p.mirror).natTrailingDegree) / 2) = 3 :=
  by
  rw [nat_degree_mul_mirror, nat_trailing_degree_mul_mirror, ← mul_addₓ, Nat.mul_div_rightₓ _ zero_lt_two,
    coeff_mul_mirror]
  refine' ⟨_, fun hp => _⟩
  · rintro ⟨k, m, n, hkm, hmn, u, v, w, rfl⟩
    rw [sum_def, trinomial_support hkm hmn u.ne_zero v.ne_zero w.ne_zero,
      sum_insert (mt mem_insert.mp (not_orₓ hkm.ne (mt mem_singleton.mp (hkm.trans hmn).Ne))),
      sum_insert (mt mem_singleton.mp hmn.ne), sum_singleton, trinomial_leading_coeff' hkm hmn,
      trinomial_middle_coeff hkm hmn, trinomial_trailing_coeff' hkm hmn]
    simp_rw [← Units.coe_pow, Int.units_sq, Units.coe_one, ← add_assocₓ, bit1, bit0]
    
  · have key : ∀ k ∈ p.support, p.coeff k ^ 2 = 1 := fun k hk =>
      Int.sq_eq_one_of_sq_le_three ((single_le_sum (fun k hk => sq_nonneg (p.coeff k)) hk).trans hp.le)
        (mem_support_iff.mp hk)
    refine' is_unit_trinomial_iff.mpr ⟨_, fun k hk => is_unit_of_pow_eq_one _ 2 (key k hk) zero_lt_two⟩
    rw [sum_def, sum_congr rfl key, sum_const, Nat.smul_one_eq_coe] at hp
    exact Nat.cast_injective hp
    

theorem is_unit_trinomial_iff'' (h : p * p.mirror = q * q.mirror) : p.IsUnitTrinomial ↔ q.IsUnitTrinomial := by
  rw [is_unit_trinomial_iff', is_unit_trinomial_iff', h]

namespace IsUnitTrinomial

theorem irreducible_aux1 {k m n : ℕ} (hkm : k < m) (hmn : m < n) (u v w : Units ℤ) (hp : p = trinomial k m n u v w) :
    c ↑v * (c ↑u * X ^ (m + n) + c ↑w * X ^ (n - m + k + n)) =
      ⟨Finsupp.filter (Set.Ioo (k + n) (n + n)) (p * p.mirror).toFinsupp⟩ :=
  by
  have key : n - m + k < n := by
    rwa [← lt_tsub_iff_right, tsub_lt_tsub_iff_left_of_le hmn.le]
  rw [hp, trinomial_mirror hkm hmn u.ne_zero w.ne_zero]
  simp_rw [trinomial_def, ← monomial_eq_C_mul_X, add_mulₓ, mul_addₓ, monomial_mul_monomial, to_finsupp_add,
    to_finsupp_monomial, Finsupp.filter_add]
  rw [Finsupp.filter_single_of_neg, Finsupp.filter_single_of_neg, Finsupp.filter_single_of_neg,
    Finsupp.filter_single_of_neg, Finsupp.filter_single_of_neg, Finsupp.filter_single_of_pos,
    Finsupp.filter_single_of_neg, Finsupp.filter_single_of_pos, Finsupp.filter_single_of_neg]
  · simp only [add_zeroₓ, zero_addₓ, of_finsupp_add, of_finsupp_single]
    rw [C_mul_monomial, C_mul_monomial, mul_comm ↑v ↑w, add_commₓ (n - m + k) n]
    
  · exact fun h => h.2.Ne rfl
    
  · refine' ⟨_, add_lt_add_left key n⟩
    rwa [add_commₓ, add_lt_add_iff_left, lt_add_iff_pos_left, tsub_pos_iff_lt]
    
  · exact fun h => h.1.Ne (add_commₓ k n)
    
  · exact ⟨add_lt_add_right hkm n, add_lt_add_right hmn n⟩
    
  · rw [← add_assocₓ, add_tsub_cancel_of_le hmn.le, add_commₓ]
    exact fun h => h.1.Ne rfl
    
  · intro h
    have := h.1
    rw [add_commₓ, add_lt_add_iff_right] at this
    exact asymm this hmn
    
  · exact fun h => h.1.Ne rfl
    
  · exact fun h => asymm ((add_lt_add_iff_left k).mp h.1) key
    
  · exact fun h => asymm ((add_lt_add_iff_left k).mp h.1) (hkm.trans hmn)
    

theorem irreducible_aux2 {k m m' n : ℕ} (hkm : k < m) (hmn : m < n) (hkm' : k < m') (hmn' : m' < n) (u v w : Units ℤ)
    (hp : p = trinomial k m n u v w) (hq : q = trinomial k m' n u v w) (h : p * p.mirror = q * q.mirror) :
    q = p ∨ q = p.mirror := by
  let f : ℤ[X] → ℤ[X] := fun p => ⟨Finsupp.filter (Set.Ioo (k + n) (n + n)) p.toFinsupp⟩
  replace h := congr_argₓ f h
  replace h := (irreducible_aux1 hkm hmn u v w hp).trans h
  replace h := h.trans (irreducible_aux1 hkm' hmn' u v w hq).symm
  rw [(is_unit_C.mpr v.is_unit).mul_right_inj] at h
  rw [binomial_eq_binomial u.ne_zero w.ne_zero] at h
  simp only [add_left_injₓ, Units.eq_iff] at h
  rcases h with (⟨rfl, -⟩ | ⟨rfl, rfl, h⟩ | ⟨-, hm, hm'⟩)
  · exact Or.inl (hq.trans hp.symm)
    
  · refine' Or.inr _
    rw [← trinomial_mirror hkm' hmn' u.ne_zero u.ne_zero, eq_comm, mirror_eq_iff] at hp
    exact hq.trans hp
    
  · suffices m = m' by
      rw [this] at hp
      exact Or.inl (hq.trans hp.symm)
    rw [tsub_add_eq_add_tsub hmn.le, eq_tsub_iff_add_eq_of_le, ← two_mul] at hm
    rw [tsub_add_eq_add_tsub hmn'.le, eq_tsub_iff_add_eq_of_le, ← two_mul] at hm'
    exact mul_left_cancel₀ two_ne_zero (hm.trans hm'.symm)
    exact hmn'.le.trans (Nat.le_add_rightₓ n k)
    exact hmn.le.trans (Nat.le_add_rightₓ n k)
    

theorem irreducible_aux3 {k m m' n : ℕ} (hkm : k < m) (hmn : m < n) (hkm' : k < m') (hmn' : m' < n)
    (u v w x z : Units ℤ) (hp : p = trinomial k m n u v w) (hq : q = trinomial k m' n x v z)
    (h : p * p.mirror = q * q.mirror) : q = p ∨ q = p.mirror := by
  have hmul := congr_argₓ leading_coeff h
  rw [leading_coeff_mul, leading_coeff_mul, mirror_leading_coeff, mirror_leading_coeff, hp, hq,
    trinomial_leading_coeff hkm hmn w.ne_zero, trinomial_leading_coeff hkm' hmn' z.ne_zero,
    trinomial_trailing_coeff hkm hmn u.ne_zero, trinomial_trailing_coeff hkm' hmn' x.ne_zero] at hmul
  have hadd := congr_argₓ (eval 1) h
  rw [eval_mul, eval_mul, mirror_eval_one, mirror_eval_one, ← sq, ← sq, hp, hq] at hadd
  simp only [eval_add, eval_C_mul, eval_pow, eval_X, one_pow, mul_oneₓ, trinomial_def] at hadd
  rw [add_assocₓ, add_assocₓ, add_commₓ ↑u, add_commₓ ↑x, add_assocₓ, add_assocₓ] at hadd
  simp only [add_sq', add_assocₓ, add_right_injₓ, ← Units.coe_pow, Int.units_sq] at hadd
  rw [mul_assoc, hmul, ← mul_assoc, add_right_injₓ,
    mul_right_inj' (show 2 * (v : ℤ) ≠ 0 from mul_ne_zero two_ne_zero v.ne_zero)] at hadd
  replace hadd := (Int.is_unit_add_is_unit_eq_is_unit_add_is_unit w.is_unit u.is_unit z.is_unit x.is_unit).mp hadd
  simp only [Units.eq_iff] at hadd
  rcases hadd with (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩)
  · exact irreducible_aux2 hkm hmn hkm' hmn' u v w hp hq h
    
  · rw [← mirror_inj, trinomial_mirror hkm' hmn' w.ne_zero u.ne_zero] at hq
    rw [mul_comm q, ← q.mirror_mirror, q.mirror.mirror_mirror] at h
    rw [← mirror_inj, or_comm, ← mirror_eq_iff]
    exact
      irreducible_aux2 hkm hmn (lt_add_of_pos_left k (tsub_pos_of_lt hmn'))
        (lt_tsub_iff_right.mp ((tsub_lt_tsub_iff_left_of_le hmn'.le).mpr hkm')) u v w hp hq h
    

theorem irreducible_of_coprime (hp : p.IsUnitTrinomial) (h : ∀ q : ℤ[X], q ∣ p → q ∣ p.mirror → IsUnit q) :
    Irreducible p := by
  refine' irreducible_of_mirror hp.not_is_unit (fun q hpq => _) h
  have hq : is_unit_trinomial q := (is_unit_trinomial_iff'' hpq).mp hp
  obtain ⟨k, m, n, hkm, hmn, u, v, w, hp⟩ := hp
  obtain ⟨k', m', n', hkm', hmn', x, y, z, hq⟩ := hq
  have hk : k = k' := by
    rw [← mul_right_inj' (show 2 ≠ 0 from two_ne_zero), ← trinomial_nat_trailing_degree hkm hmn u.ne_zero, ← hp, ←
      nat_trailing_degree_mul_mirror, hpq, nat_trailing_degree_mul_mirror, hq,
      trinomial_nat_trailing_degree hkm' hmn' x.ne_zero]
  have hn : n = n' := by
    rw [← mul_right_inj' (show 2 ≠ 0 from two_ne_zero), ← trinomial_nat_degree hkm hmn w.ne_zero, ← hp, ←
      nat_degree_mul_mirror, hpq, nat_degree_mul_mirror, hq, trinomial_nat_degree hkm' hmn' z.ne_zero]
  subst hk
  subst hn
  rcases eq_or_eq_neg_of_sq_eq_sq (↑y) (↑v) ((Int.is_unit_sq y.is_unit).trans (Int.is_unit_sq v.is_unit).symm) with
    (h1 | h1)
  · rw [h1] at *
    rcases irreducible_aux3 hkm hmn hkm' hmn' u v w x z hp hq hpq with (h2 | h2)
    · exact Or.inl h2
      
    · exact Or.inr (Or.inr (Or.inl h2))
      
    
  · rw [h1] at *
    rw [trinomial_def] at hp
    rw [← neg_inj, neg_add, neg_add, ← neg_mul, ← neg_mul, ← neg_mul, ← C_neg, ← C_neg, ← C_neg] at hp
    rw [← neg_mul_neg, ← mirror_neg] at hpq
    rcases irreducible_aux3 hkm hmn hkm' hmn' (-u) (-v) (-w) x z hp hq hpq with (rfl | rfl)
    · exact Or.inr (Or.inl rfl)
      
    · exact Or.inr (Or.inr (Or.inr p.mirror_neg))
      
    

/-- A unit trinomial is irreducible if it is coprime with its mirror -/
theorem irreducible_of_is_coprime (hp : p.IsUnitTrinomial) (h : IsCoprime p p.mirror) : Irreducible p :=
  irreducible_of_coprime hp fun q => h.is_unit_of_dvd'

/-- A unit trinomial is irreducible if it has no complex roots in common with its mirror -/
theorem irreducible_of_coprime' (hp : IsUnitTrinomial p) (h : ∀ z : ℂ, ¬(aeval z p = 0 ∧ aeval z (mirror p) = 0)) :
    Irreducible p := by
  refine' hp.irreducible_of_coprime fun q hq hq' => _
  suffices ¬0 < q.nat_degree by
    rcases hq with ⟨p, rfl⟩
    replace hp := hp.leading_coeff_is_unit
    rw [leading_coeff_mul] at hp
    replace hp := is_unit_of_mul_is_unit_left hp
    rw [not_ltₓ, le_zero_iff] at this
    rwa [eq_C_of_nat_degree_eq_zero this, is_unit_C, ← this]
  intro hq''
  rw [nat_degree_pos_iff_degree_pos] at hq''
  rw [← degree_map_eq_of_injective (algebraMap ℤ ℂ).injective_int] at hq''
  cases' Complex.exists_root hq'' with z hz
  rw [is_root, eval_map, ← aeval_def] at hz
  refine' h z ⟨_, _⟩
  · cases' hq with g' hg'
    rw [hg', aeval_mul, hz, zero_mul]
    
  · cases' hq' with g' hg'
    rw [hg', aeval_mul, hz, zero_mul]
    

-- TODO: Develop more theory (e.g., it suffices to check that `aeval z p ≠ 0` for `z = 0`
-- and `z` a root of unity)
end IsUnitTrinomial

end Polynomial

