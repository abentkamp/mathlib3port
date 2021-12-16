import Mathbin.Data.Nat.Choose.Basic 
import Mathbin.Tactic.Linarith.Default 
import Mathbin.Algebra.BigOperators.Ring 
import Mathbin.Algebra.BigOperators.Intervals 
import Mathbin.Algebra.BigOperators.Order 
import Mathbin.Algebra.BigOperators.NatAntidiagonal

/-!
# Sums of binomial coefficients

This file includes variants of the binomial theorem and other results on sums of binomial
coefficients. Theorems whose proofs depend on such sums may also go in this file for import
reasons.

-/


open Nat

open Finset

open_locale BigOperators

variable {R : Type _}

namespace Commute

variable [Semiringₓ R] {x y : R} (h : Commute x y) (n : ℕ)

include h

/-- A version of the **binomial theorem** for noncommutative semirings. -/
theorem add_pow : (x+y) ^ n = ∑ m in range (n+1), ((x ^ m)*y ^ (n - m))*choose n m :=
  by 
    let t : ℕ → ℕ → R := fun n m => ((x ^ m)*y ^ (n - m))*choose n m 
    change (x+y) ^ n = ∑ m in range (n+1), t n m 
    have h_first : ∀ n, t n 0 = y ^ n :=
      fun n =>
        by 
          dsimp [t]
          rw [choose_zero_right, pow_zeroₓ, Nat.cast_one, mul_oneₓ, one_mulₓ]
    have h_last : ∀ n, t n n.succ = 0 :=
      fun n =>
        by 
          dsimp [t]
          rw [choose_succ_self, Nat.cast_zero, mul_zero]
    have h_middle : ∀ n i : ℕ, i ∈ range n.succ → (t n.succ ∘ Nat.succ) i = (x*t n i)+y*t n i.succ :=
      by 
        intro n i h_mem 
        have h_le : i ≤ n := Nat.le_of_lt_succₓ (mem_range.mp h_mem)
        dsimp [t]
        rw [choose_succ_succ, Nat.cast_add, mul_addₓ]
        congr 1
        ·
          rw [pow_succₓ x, succ_sub_succ, mul_assocₓ, mul_assocₓ, mul_assocₓ]
        ·
          rw [←mul_assocₓ y, ←mul_assocₓ y, (h.symm.pow_right i.succ).Eq]
          byCases' h_eq : i = n
          ·
            rw [h_eq, choose_succ_self, Nat.cast_zero, mul_zero, mul_zero]
          ·
            rw [succ_sub (lt_of_le_of_neₓ h_le h_eq)]
            rw [pow_succₓ y, mul_assocₓ, mul_assocₓ, mul_assocₓ, mul_assocₓ]
    induction' n with n ih
    ·
      rw [pow_zeroₓ, sum_range_succ, range_zero, sum_empty, zero_addₓ]
      dsimp [t]
      rw [pow_zeroₓ, pow_zeroₓ, choose_self, Nat.cast_one, mul_oneₓ, mul_oneₓ]
    ·
      rw [sum_range_succ', h_first]
      rw [sum_congr rfl (h_middle n), sum_add_distrib, add_assocₓ]
      rw [pow_succₓ (x+y), ih, add_mulₓ, mul_sum, mul_sum]
      congr 1
      rw [sum_range_succ', sum_range_succ, h_first, h_last, mul_zero, add_zeroₓ, pow_succₓ]

/-- A version of `commute.add_pow` that avoids ℕ-subtraction by summing over the antidiagonal and
also with the binomial coefficient applied via scalar action of ℕ. -/
theorem add_pow' : (x+y) ^ n = ∑ m in nat.antidiagonal n, choose n m.fst • (x ^ m.fst)*y ^ m.snd :=
  by 
    simpRw [Finset.Nat.sum_antidiagonal_eq_sum_range_succ fun m p => choose n m • (x ^ m)*y ^ p, _root_.nsmul_eq_mul,
      cast_comm, h.add_pow]

end Commute

/-- The **binomial theorem** -/
theorem add_pow [CommSemiringₓ R] (x y : R) (n : ℕ) :
  (x+y) ^ n = ∑ m in range (n+1), ((x ^ m)*y ^ (n - m))*choose n m :=
  (Commute.all x y).add_pow n

namespace Nat

/-- The sum of entries in a row of Pascal's triangle -/
theorem sum_range_choose (n : ℕ) : (∑ m in range (n+1), choose n m) = 2 ^ n :=
  by 
    simpa using (add_pow 1 1 n).symm

theorem sum_range_choose_halfway (m : Nat) : (∑ i in range (m+1), choose ((2*m)+1) i) = 4 ^ m :=
  have  : (∑ i in range (m+1), choose ((2*m)+1) (((2*m)+1) - i)) = ∑ i in range (m+1), choose ((2*m)+1) i :=
    sum_congr rfl$
      fun i hi =>
        choose_symm$
          by 
            linarith [mem_range.1 hi]
  (Nat.mul_right_inj zero_lt_two).1$
    calc
      (2*∑ i in range (m+1), choose ((2*m)+1) i) =
        (∑ i in range (m+1), choose ((2*m)+1) i)+∑ i in range (m+1), choose ((2*m)+1) (((2*m)+1) - i) :=
      by 
        rw [two_mul, this]
      _ = (∑ i in range (m+1), choose ((2*m)+1) i)+∑ i in Ico (m+1) ((2*m)+2), choose ((2*m)+1) i :=
      by 
        rw [range_eq_Ico, sum_Ico_reflect]
        ·
          congr 
          have A : (m+1) ≤ (2*m)+1
          ·
            linarith 
          rw [add_commₓ, add_tsub_assoc_of_le A, ←add_commₓ]
          congr 
          rw [tsub_eq_iff_eq_add_of_le A]
          ring
        ·
          linarith 
      _ = ∑ i in range ((2*m)+2), choose ((2*m)+1) i :=
      sum_range_add_sum_Ico _
        (by 
          linarith)
      _ = 2 ^ (2*m)+1 := sum_range_choose ((2*m)+1)
      _ = 2*4 ^ m :=
      by 
        rw [pow_succₓ, pow_mulₓ]
        rfl
      

theorem choose_middle_le_pow (n : ℕ) : choose ((2*n)+1) n ≤ 4 ^ n :=
  by 
    have t : choose ((2*n)+1) n ≤ ∑ i in range (n+1), choose ((2*n)+1) i :=
      single_le_sum
        (fun x _ =>
          by 
            linarith)
        (self_mem_range_succ n)
    simpa [sum_range_choose_halfway n] using t

theorem four_pow_le_two_mul_add_one_mul_central_binom (n : ℕ) : 4 ^ n ≤ ((2*n)+1)*choose (2*n) n :=
  calc 4 ^ n = (1+1) ^ 2*n :=
    by 
      normNum [pow_mulₓ]
    _ = ∑ m in range ((2*n)+1), choose (2*n) m :=
    by 
      simp [add_pow]
    _ ≤ ∑ m in range ((2*n)+1), choose (2*n) ((2*n) / 2) := sum_le_sum fun i hi => choose_le_middle i (2*n)
    _ = ((2*n)+1)*choose (2*n) n :=
    by 
      simp 
    

end Nat

theorem Int.alternating_sum_range_choose {n : ℕ} :
  (∑ m in range (n+1), ((-1 ^ m)*↑choose n m : ℤ)) = if n = 0 then 1 else 0 :=
  by 
    cases n
    ·
      simp 
    have h := add_pow (-1 : ℤ) 1 n.succ 
    simp only [one_pow, mul_oneₓ, add_left_negₓ, Int.nat_cast_eq_coe_nat] at h 
    rw [←h, zero_pow (Nat.succ_posₓ n), if_neg (Nat.succ_ne_zero n)]

theorem Int.alternating_sum_range_choose_of_ne {n : ℕ} (h0 : n ≠ 0) :
  (∑ m in range (n+1), ((-1 ^ m)*↑choose n m : ℤ)) = 0 :=
  by 
    rw [Int.alternating_sum_range_choose, if_neg h0]

namespace Finset

theorem sum_powerset_apply_card {α β : Type _} [AddCommMonoidₓ α] (f : ℕ → α) {x : Finset β} :
  (∑ m in x.powerset, f m.card) = ∑ m in range (x.card+1), x.card.choose m • f m :=
  by 
    trans ∑ m in range (x.card+1), ∑ j in x.powerset.filter fun z => z.card = m, f j.card
    ·
      refine' (sum_fiberwise_of_maps_to _ _).symm 
      intro y hy 
      rw [mem_range, Nat.lt_succ_iff]
      rw [mem_powerset] at hy 
      exact card_le_of_subset hy
    ·
      refine' sum_congr rfl fun y hy => _ 
      rw [←card_powerset_len, ←sum_const]
      refine' sum_congr powerset_len_eq_filter.symm fun z hz => _ 
      rw [(mem_powerset_len.1 hz).2]

theorem sum_powerset_neg_one_pow_card {α : Type _} [DecidableEq α] {x : Finset α} :
  (∑ m in x.powerset, (-1 : ℤ) ^ m.card) = if x = ∅ then 1 else 0 :=
  by 
    rw [sum_powerset_apply_card]
    simp only [nsmul_eq_mul', ←card_eq_zero]
    convert Int.alternating_sum_range_choose 
    ext 
    simp 

theorem sum_powerset_neg_one_pow_card_of_nonempty {α : Type _} {x : Finset α} (h0 : x.nonempty) :
  (∑ m in x.powerset, (-1 : ℤ) ^ m.card) = 0 :=
  by 
    classical 
    rw [sum_powerset_neg_one_pow_card, if_neg]
    rw [←Ne.def, ←nonempty_iff_ne_empty]
    apply h0

end Finset

