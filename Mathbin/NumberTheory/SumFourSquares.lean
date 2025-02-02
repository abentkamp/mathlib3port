/-
Copyright (c) 2019 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import Mathbin.Algebra.GroupPower.Identities
import Mathbin.Data.Zmod.Basic
import Mathbin.FieldTheory.Finite.Basic
import Mathbin.Data.Int.Parity
import Mathbin.Data.Fintype.Card

/-!
# Lagrange's four square theorem

The main result in this file is `sum_four_squares`,
a proof that every natural number is the sum of four square numbers.

## Implementation Notes

The proof used is close to Lagrange's original proof.
-/


open Finset Polynomial FiniteField Equivₓ

open BigOperators

namespace Int

theorem sq_add_sq_of_two_mul_sq_add_sq {m x y : ℤ} (h : 2 * m = x ^ 2 + y ^ 2) :
    m = ((x - y) / 2) ^ 2 + ((x + y) / 2) ^ 2 :=
  have : Even (x ^ 2 + y ^ 2) := by
    simp [h.symm, even_mul]
  have hxaddy : Even (x + y) := by
    simpa [sq] with parity_simps
  have hxsuby : Even (x - y) := by
    simpa [sq] with parity_simps
  (mul_right_inj'
        (show (2 * 2 : ℤ) ≠ 0 by
          decide)).1 <|
    calc
      2 * 2 * m = (x - y) ^ 2 + (x + y) ^ 2 := by
        rw [mul_assoc, h] <;> ring
      _ = (2 * ((x - y) / 2)) ^ 2 + (2 * ((x + y) / 2)) ^ 2 := by
        rw [even_iff_two_dvd] at hxsuby hxaddy
        rw [Int.mul_div_cancel' hxsuby, Int.mul_div_cancel' hxaddy]
      _ = 2 * 2 * (((x - y) / 2) ^ 2 + ((x + y) / 2) ^ 2) := by
        simp [mul_addₓ, pow_succₓ, mul_comm, mul_assoc, mul_left_commₓ]
      

theorem exists_sq_add_sq_add_one_eq_k (p : ℕ) [hp : Fact p.Prime] :
    ∃ (a b : ℤ)(k : ℕ), a ^ 2 + b ^ 2 + 1 = k * p ∧ k < p :=
  (hp.1.eq_two_or_odd.elim fun hp2 =>
      hp2.symm ▸
        ⟨1, 0, 1, rfl, by
          decide⟩)
    fun hp1 =>
    let ⟨a, b, hab⟩ := Zmod.sq_add_sq p (-1)
    have hab' : (p : ℤ) ∣ a.valMinAbs ^ 2 + b.valMinAbs ^ 2 + 1 :=
      (CharP.int_cast_eq_zero_iff (Zmod p) p _).1 <| by
        simpa [eq_neg_iff_add_eq_zero] using hab
    let ⟨k, hk⟩ := hab'
    have hk0 : 0 ≤ k :=
      nonneg_of_mul_nonneg_right
        (by
          rw [← hk] <;> exact add_nonneg (add_nonneg (sq_nonneg _) (sq_nonneg _)) zero_le_one)
        (Int.coe_nat_pos.2 hp.1.Pos)
    ⟨a.valMinAbs, b.valMinAbs, k.natAbs, by
      rw [hk, Int.nat_abs_of_nonneg hk0, mul_comm],
      lt_of_mul_lt_mul_left
        (calc
          p * k.natAbs = a.valMinAbs.natAbs ^ 2 + b.valMinAbs.natAbs ^ 2 + 1 := by
            rw [← Int.coe_nat_inj', Int.coe_nat_add, Int.coe_nat_add, Int.coe_nat_pow, Int.coe_nat_pow, Int.nat_abs_sq,
              Int.nat_abs_sq, Int.coe_nat_one, hk, Int.coe_nat_mul, Int.nat_abs_of_nonneg hk0]
          _ ≤ (p / 2) ^ 2 + (p / 2) ^ 2 + 1 :=
            add_le_add
              (add_le_add (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _)
                (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _))
              le_rflₓ
          _ < (p / 2) ^ 2 + (p / 2) ^ 2 + (p % 2) ^ 2 + (2 * (p / 2) ^ 2 + 4 * (p / 2) * (p % 2)) := by
            rw [hp1, one_pow, mul_oneₓ] <;>
              exact
                (lt_add_iff_pos_right _).2
                  (add_pos_of_nonneg_of_pos (Nat.zero_leₓ _)
                    (mul_pos
                      (by
                        decide)
                      (Nat.div_pos hp.1.two_le
                        (by
                          decide))))
          _ = p * p := by
            conv_rhs => rw [← Nat.mod_add_divₓ p 2]
            ring
          )
        (show 0 ≤ p from Nat.zero_leₓ _)⟩

end Int

namespace Nat

open Int

open Classical

private theorem sum_four_squares_of_two_mul_sum_four_squares {m a b c d : ℤ}
    (h : a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = 2 * m) : ∃ w x y z : ℤ, w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 = m :=
  have :
    ∀ f : Finₓ 4 → Zmod 2,
      f 0 ^ 2 + f 1 ^ 2 + f 2 ^ 2 + f 3 ^ 2 = 0 →
        ∃ i : Finₓ 4, f i ^ 2 + f (swap i 0 1) ^ 2 = 0 ∧ f (swap i 0 2) ^ 2 + f (swap i 0 3) ^ 2 = 0 :=
    by
    decide
  let f : Finₓ 4 → ℤ := Vector.nth (a ::ᵥ b ::ᵥ c ::ᵥ d ::ᵥ Vector.nil)
  let ⟨i, hσ⟩ :=
    this (coe ∘ f)
      (by
        rw [← @zero_mul (Zmod 2) _ m, ← show ((2 : ℤ) : Zmod 2) = 0 from rfl, ← Int.cast_mul, ← h] <;>
          simp only [Int.cast_add, Int.cast_pow] <;> rfl)
  let σ := swap i 0
  have h01 : 2 ∣ f (σ 0) ^ 2 + f (σ 1) ^ 2 :=
    (CharP.int_cast_eq_zero_iff (Zmod 2) 2 _).1 <| by
      simpa [σ] using hσ.1
  have h23 : 2 ∣ f (σ 2) ^ 2 + f (σ 3) ^ 2 :=
    (CharP.int_cast_eq_zero_iff (Zmod 2) 2 _).1 <| by
      simpa using hσ.2
  let ⟨x, hx⟩ := h01
  let ⟨y, hy⟩ := h23
  ⟨(f (σ 0) - f (σ 1)) / 2, (f (σ 0) + f (σ 1)) / 2, (f (σ 2) - f (σ 3)) / 2, (f (σ 2) + f (σ 3)) / 2, by
    rw [← Int.sq_add_sq_of_two_mul_sq_add_sq hx.symm, add_assocₓ, ← Int.sq_add_sq_of_two_mul_sq_add_sq hy.symm, ←
      mul_right_inj'
        (show (2 : ℤ) ≠ 0 by
          decide),
      ← h, mul_addₓ, ← hx, ← hy]
    have : (∑ x, f (σ x) ^ 2) = ∑ x, f x ^ 2 := by
      conv_rhs => rw [← Equivₓ.sum_comp σ]
    have fin4univ : (univ : Finset (Finₓ 4)).1 = 0 ::ₘ 1 ::ₘ 2 ::ₘ 3 ::ₘ 0 := by
      decide
    simpa [Finset.sum_eq_multiset_sum, fin4univ, Multiset.sum_cons, f, add_assocₓ] ⟩

private theorem prime_sum_four_squares (p : ℕ) [hp : Fact p.Prime] : ∃ a b c d : ℤ, a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = p :=
  have hm : ∃ m < p, 0 < m ∧ ∃ a b c d : ℤ, a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = m * p :=
    let ⟨a, b, k, hk⟩ := exists_sq_add_sq_add_one_eq_k p
    ⟨k, hk.2,
      Nat.pos_of_ne_zeroₓ fun hk0 => by
        rw [hk0, Int.coe_nat_zero, zero_mul] at hk
        exact
          ne_of_gtₓ
            (show a ^ 2 + b ^ 2 + 1 > 0 from
              add_pos_of_nonneg_of_pos (add_nonneg (sq_nonneg _) (sq_nonneg _)) zero_lt_one)
            hk.1,
      a, b, 1, 0, by
      simpa [sq] using hk.1⟩
  let m := Nat.findₓ hm
  let ⟨a, b, c, d, (habcd : a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = m * p)⟩ := (Nat.find_specₓ hm).snd.2
  haveI hm0 : NeZero m := NeZero.of_pos (Nat.find_specₓ hm).snd.1
  have hmp : m < p := (Nat.find_specₓ hm).fst
  m.mod_two_eq_zero_or_one.elim
    (fun hm2 : m % 2 = 0 =>
      let ⟨k, hk⟩ := Nat.dvd_iff_mod_eq_zeroₓ.2 hm2
      have hk0 : 0 < k :=
        Nat.pos_of_ne_zeroₓ fun _ => by
          simp_all [lt_irreflₓ]
      have hkm : k < m := by
        rw [hk, two_mul]
        exact (lt_add_iff_pos_left _).2 hk0
      False.elim <|
        Nat.find_minₓ hm hkm
          ⟨lt_transₓ hkm hmp, hk0,
            sum_four_squares_of_two_mul_sum_four_squares
              (show a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = 2 * (k * p) by
                rw [habcd, hk, Int.coe_nat_mul, mul_assoc]
                norm_num)⟩)
    fun hm2 : m % 2 = 1 =>
    if hm1 : m = 1 then
      ⟨a, b, c, d, by
        simp only [hm1, habcd, Int.coe_nat_one, one_mulₓ]⟩
    else
      let w := (a : Zmod m).valMinAbs
      let x := (b : Zmod m).valMinAbs
      let y := (c : Zmod m).valMinAbs
      let z := (d : Zmod m).valMinAbs
      have hnat_abs : w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 = (w.natAbs ^ 2 + x.natAbs ^ 2 + y.natAbs ^ 2 + z.natAbs ^ 2 : ℕ) :=
        by
        simp [sq]
      have hwxyzlt : w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 < m ^ 2 :=
        calc
          w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 = (w.natAbs ^ 2 + x.natAbs ^ 2 + y.natAbs ^ 2 + z.natAbs ^ 2 : ℕ) := hnat_abs
          _ ≤ ((m / 2) ^ 2 + (m / 2) ^ 2 + (m / 2) ^ 2 + (m / 2) ^ 2 : ℕ) :=
            Int.coe_nat_leₓ.2 <|
              add_le_add
                (add_le_add
                  (add_le_add (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _)
                    (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _))
                  (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _))
                (Nat.pow_le_pow_of_le_leftₓ (Zmod.nat_abs_val_min_abs_le _) _)
          _ = 4 * (m / 2 : ℕ) ^ 2 := by
            simp [sq, bit0, bit1, mul_addₓ, add_mulₓ, add_assocₓ]
          _ < 4 * (m / 2 : ℕ) ^ 2 + ((4 * (m / 2) : ℕ) * (m % 2 : ℕ) + (m % 2 : ℕ) ^ 2) :=
            (lt_add_iff_pos_right _).2
              (by
                rw [hm2, Int.coe_nat_one, one_pow, mul_oneₓ]
                exact add_pos_of_nonneg_of_pos (Int.coe_nat_nonneg _) zero_lt_one)
          _ = m ^ 2 := by
            conv_rhs => rw [← Nat.mod_add_divₓ m 2]
            simp [-Nat.mod_add_divₓ, mul_addₓ, add_mulₓ, bit0, bit1, mul_comm, mul_assoc, mul_left_commₓ, pow_addₓ,
              add_commₓ, add_left_commₓ]
          
      have hwxyzabcd :
        ((w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 : ℤ) : Zmod m) = ((a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 : ℤ) : Zmod m) := by
        simp [w, x, y, z, sq]
      have hwxyz0 : ((w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2 : ℤ) : Zmod m) = 0 := by
        rw [hwxyzabcd, habcd, Int.cast_mul, cast_coe_nat, Zmod.nat_cast_self, zero_mul]
      let ⟨n, hn⟩ := (CharP.int_cast_eq_zero_iff _ m _).1 hwxyz0
      have hn0 : 0 < n.natAbs :=
        Int.nat_abs_pos_of_ne_zero fun hn0 =>
          have hwxyz0 : (w.natAbs ^ 2 + x.natAbs ^ 2 + y.natAbs ^ 2 + z.natAbs ^ 2 : ℕ) = 0 := by
            rw [← Int.coe_nat_eq_zero, ← hnat_abs]
            rwa [hn0, mul_zero] at hn
          have habcd0 : (m : ℤ) ∣ a ∧ (m : ℤ) ∣ b ∧ (m : ℤ) ∣ c ∧ (m : ℤ) ∣ d := by
            simpa [add_eq_zero_iff' (sq_nonneg (_ : ℤ)) (sq_nonneg _), pow_two, w, x, y, z,
              CharP.int_cast_eq_zero_iff _ m _, And.assoc] using hwxyz0
          let ⟨ma, hma⟩ := habcd0.1
          let ⟨mb, hmb⟩ := habcd0.2.1
          let ⟨mc, hmc⟩ := habcd0.2.2.1
          let ⟨md, hmd⟩ := habcd0.2.2.2
          have hmdvdp : m ∣ p :=
            Int.coe_nat_dvd.1
              ⟨ma ^ 2 + mb ^ 2 + mc ^ 2 + md ^ 2,
                (mul_right_inj' (show (m : ℤ) ≠ 0 from Int.coe_nat_ne_zero.2 hm0.1)).1 <| by
                  rw [← habcd, hma, hmb, hmc, hmd]
                  ring⟩
          (hp.1.eq_one_or_self_of_dvd _ hmdvdp).elim hm1 fun hmeqp => by
            simpa [lt_irreflₓ, hmeqp] using hmp
      have hawbxcydz : ((m : ℕ) : ℤ) ∣ a * w + b * x + c * y + d * z :=
        (CharP.int_cast_eq_zero_iff (Zmod m) m _).1 <| by
          rw [← hwxyz0]
          simp
          ring
      have haxbwczdy : ((m : ℕ) : ℤ) ∣ a * x - b * w - c * z + d * y :=
        (CharP.int_cast_eq_zero_iff (Zmod m) m _).1 <| by
          simp [sub_eq_add_neg]
          ring
      have haybzcwdx : ((m : ℕ) : ℤ) ∣ a * y + b * z - c * w - d * x :=
        (CharP.int_cast_eq_zero_iff (Zmod m) m _).1 <| by
          simp [sub_eq_add_neg]
          ring
      have hazbycxdw : ((m : ℕ) : ℤ) ∣ a * z - b * y + c * x - d * w :=
        (CharP.int_cast_eq_zero_iff (Zmod m) m _).1 <| by
          simp [sub_eq_add_neg]
          ring
      let ⟨s, hs⟩ := hawbxcydz
      let ⟨t, ht⟩ := haxbwczdy
      let ⟨u, hu⟩ := haybzcwdx
      let ⟨v, hv⟩ := hazbycxdw
      have hn_nonneg : 0 ≤ n :=
        nonneg_of_mul_nonneg_right
          (by
            erw [← hn]
            repeat'
              try
                refine' add_nonneg _ _
              try
                exact sq_nonneg _)
          (Int.coe_nat_pos.2 <| NeZero.pos m)
      have hnm : n.natAbs < m :=
        Int.coe_nat_ltₓ.1
          (lt_of_mul_lt_mul_left
            (by
              rw [Int.nat_abs_of_nonneg hn_nonneg, ← hn, ← sq]
              exact hwxyzlt)
            (Int.coe_nat_nonneg m))
      have hstuv : s ^ 2 + t ^ 2 + u ^ 2 + v ^ 2 = n.natAbs * p :=
        (mul_right_inj' (show (m ^ 2 : ℤ) ≠ 0 from pow_ne_zero 2 (Int.coe_nat_ne_zero.2 hm0.1))).1 <|
          calc
            (m : ℤ) ^ 2 * (s ^ 2 + t ^ 2 + u ^ 2 + v ^ 2) =
                ((m : ℕ) * s) ^ 2 + ((m : ℕ) * t) ^ 2 + ((m : ℕ) * u) ^ 2 + ((m : ℕ) * v) ^ 2 :=
              by
              simp [mul_powₓ]
              ring
            _ = (w ^ 2 + x ^ 2 + y ^ 2 + z ^ 2) * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2) := by
              simp only [hs.symm, ht.symm, hu.symm, hv.symm]
              ring
            _ = _ := by
              rw [hn, habcd, Int.nat_abs_of_nonneg hn_nonneg]
              dsimp' [m]
              ring
            
      False.elim <| Nat.find_minₓ hm hnm ⟨lt_transₓ hnm hmp, hn0, s, t, u, v, hstuv⟩

/-- **Four squares theorem** -/
theorem sum_four_squares : ∀ n : ℕ, ∃ a b c d : ℕ, a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = n
  | 0 => ⟨0, 0, 0, 0, rfl⟩
  | 1 => ⟨1, 0, 0, 0, rfl⟩
  | n@(k + 2) =>
    have hm : Fact (minFac (k + 2)).Prime :=
      ⟨min_fac_prime
          (by
            decide)⟩
    have : n / minFac n < n := factors_lemma
    let ⟨a, b, c, d, h₁⟩ :=
      show ∃ a b c d : ℤ, a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 = minFac n from prime_sum_four_squares (min_fac (k + 2))
    let ⟨w, x, y, z, h₂⟩ := sum_four_squares (n / minFac n)
    ⟨(a * w - b * x - c * y - d * z).natAbs, (a * x + b * w + c * z - d * y).natAbs,
      (a * y - b * z + c * w + d * x).natAbs, (a * z + b * y - c * x + d * w).natAbs, by
      rw [← Int.coe_nat_inj', ← Nat.mul_div_cancel'ₓ (min_fac_dvd (k + 2)), Int.coe_nat_mul, ← h₁, ← h₂]
      simp [sum_four_sq_mul_sum_four_sq]⟩

end Nat

