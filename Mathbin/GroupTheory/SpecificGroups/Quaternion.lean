/-
Copyright (c) 2021 Julian Kuelshammer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Julian Kuelshammer
-/
import Mathbin.Data.Zmod.Basic
import Mathbin.Data.Nat.Basic
import Mathbin.Tactic.IntervalCases
import Mathbin.GroupTheory.SpecificGroups.Dihedral
import Mathbin.GroupTheory.SpecificGroups.Cyclic

/-!
# Quaternion Groups

We define the (generalised) quaternion groups `quaternion_group n` of order `4n`, also known as
dicyclic groups, with elements `a i` and `xa i` for `i : zmod n`. The (generalised) quaternion
groups can be defined by the presentation
$\langle a, x | a^{2n} = 1, x^2 = a^n, x^{-1}ax=a^{-1}\rangle$. We write `a i` for
$a^i$ and `xa i` for $x * a^i$. For `n=2` the quaternion group `quaternion_group 2` is isomorphic to
the unit integral quaternions `(quaternion ℤ)ˣ`.

## Main definition

`quaternion_group n`: The (generalised) quaternion group of order `4n`.

## Implementation notes

This file is heavily based on `dihedral_group` by Shing Tak Lam.

In mathematics, the name "quaternion group" is reserved for the cases `n ≥ 2`. Since it would be
inconvenient to carry around this condition we define `quaternion_group` also for `n = 0` and
`n = 1`. `quaternion_group 0` is isomorphic to the infinite dihedral group, while
`quaternion_group 1` is isomorphic to a cyclic group of order `4`.

## References

* https://en.wikipedia.org/wiki/Dicyclic_group
* https://en.wikipedia.org/wiki/Quaternion_group

## TODO

Show that `quaternion_group 2 ≃* (quaternion ℤ)ˣ`.

-/


/-- The (generalised) quaternion group `quaternion_group n` of order `4n`. It can be defined by the
presentation $\langle a, x | a^{2n} = 1, x^2 = a^n, x^{-1}ax=a^{-1}\rangle$. We write `a i` for
$a^i$ and `xa i` for $x * a^i$.
-/
inductive QuaternionGroup (n : ℕ) : Type
  | a : Zmod (2 * n) → QuaternionGroup
  | xa : Zmod (2 * n) → QuaternionGroup
  deriving DecidableEq

namespace QuaternionGroup

variable {n : ℕ}

/-- Multiplication of the dihedral group.
-/
private def mul : QuaternionGroup n → QuaternionGroup n → QuaternionGroup n
  | a i, a j => a (i + j)
  | a i, xa j => xa (j - i)
  | xa i, a j => xa (i + j)
  | xa i, xa j => a (n + j - i)

/-- The identity `1` is given by `aⁱ`.
-/
private def one : QuaternionGroup n :=
  a 0

instance : Inhabited (QuaternionGroup n) :=
  ⟨one⟩

/-- The inverse of an element of the quaternion group.
-/
private def inv : QuaternionGroup n → QuaternionGroup n
  | a i => a (-i)
  | xa i => xa (n + i)

/-- The group structure on `quaternion_group n`.
-/
instance : Groupₓ (QuaternionGroup n) where
  mul := mul
  mul_assoc := by
    rintro (i | i) (j | j) (k | k) <;> simp only [mul] <;> abel
    simp only [neg_mul, one_mulₓ, Int.cast_oneₓ, zsmul_eq_mul, Int.cast_neg, add_right_injₓ]
    calc
      -(n : Zmod (2 * n)) = 0 - n := by
        rw [zero_sub]
      _ = 2 * n - n := by
        norm_cast
        simp
      _ = n := by
        ring
      
  one := one
  one_mul := by
    rintro (i | i)
    · exact congr_argₓ a (zero_addₓ i)
      
    · exact congr_argₓ xa (sub_zero i)
      
  mul_one := by
    rintro (i | i)
    · exact congr_argₓ a (add_zeroₓ i)
      
    · exact congr_argₓ xa (add_zeroₓ i)
      
  inv := inv
  mul_left_inv := by
    rintro (i | i)
    · exact congr_argₓ a (neg_add_selfₓ i)
      
    · exact congr_argₓ a (sub_self (n + i))
      

variable {n}

@[simp]
theorem a_mul_a (i j : Zmod (2 * n)) : a i * a j = a (i + j) :=
  rfl

@[simp]
theorem a_mul_xa (i j : Zmod (2 * n)) : a i * xa j = xa (j - i) :=
  rfl

@[simp]
theorem xa_mul_a (i j : Zmod (2 * n)) : xa i * a j = xa (i + j) :=
  rfl

@[simp]
theorem xa_mul_xa (i j : Zmod (2 * n)) : xa i * xa j = a (n + j - i) :=
  rfl

theorem one_def : (1 : QuaternionGroup n) = a 0 :=
  rfl

private def fintype_helper : Sum (Zmod (2 * n)) (Zmod (2 * n)) ≃ QuaternionGroup n where
  invFun := fun i =>
    match i with
    | a j => Sum.inl j
    | xa j => Sum.inr j
  toFun := fun i =>
    match i with
    | Sum.inl j => a j
    | Sum.inr j => xa j
  left_inv := by
    rintro (x | x) <;> rfl
  right_inv := by
    rintro (x | x) <;> rfl

/-- The special case that more or less by definition `quaternion_group 0` is isomorphic to the
infinite dihedral group. -/
def quaternionGroupZeroEquivDihedralGroupZero : QuaternionGroup 0 ≃* DihedralGroup 0 where
  toFun := fun i => QuaternionGroup.recOn i DihedralGroup.r DihedralGroup.sr
  invFun := fun i =>
    match i with
    | DihedralGroup.r j => a j
    | DihedralGroup.sr j => xa j
  left_inv := by
    rintro (k | k) <;> rfl
  right_inv := by
    rintro (k | k) <;> rfl
  map_mul' := by
    rintro (k | k) (l | l) <;>
      · dsimp'
        simp
        

/-- If `0 < n`, then `quaternion_group n` is a finite group.
-/
instance [NeZero n] : Fintype (QuaternionGroup n) :=
  Fintype.ofEquiv _ fintypeHelper

instance : Nontrivial (QuaternionGroup n) :=
  ⟨⟨a 0, xa 0, by
      decide⟩⟩

/-- If `0 < n`, then `quaternion_group n` has `4n` elements.
-/
theorem card [NeZero n] : Fintype.card (QuaternionGroup n) = 4 * n := by
  rw [← fintype.card_eq.mpr ⟨fintype_helper⟩, Fintype.card_sum, Zmod.card, two_mul]
  ring

@[simp]
theorem a_one_pow (k : ℕ) : (a 1 : QuaternionGroup n) ^ k = a k := by
  induction' k with k IH
  · rw [Nat.cast_zeroₓ]
    rfl
    
  · rw [pow_succₓ, IH, a_mul_a]
    congr 1
    norm_cast
    rw [Nat.one_add]
    

@[simp]
theorem a_one_pow_n : (a 1 : QuaternionGroup n) ^ (2 * n) = 1 := by
  rw [a_one_pow, one_def]
  congr 1
  exact Zmod.nat_cast_self _

@[simp]
theorem xa_sq (i : Zmod (2 * n)) : xa i ^ 2 = a n := by
  simp [sq]

@[simp]
theorem xa_pow_four (i : Zmod (2 * n)) : xa i ^ 4 = 1 := by
  simp only [pow_succₓ, sq, xa_mul_xa, xa_mul_a, add_sub_cancel, add_sub_assoc, add_sub_cancel', sub_self, add_zeroₓ]
  norm_cast
  rw [← two_mul]
  simp [one_def]

/-- If `0 < n`, then `xa i` has order 4.
-/
@[simp]
theorem order_of_xa [NeZero n] (i : Zmod (2 * n)) : orderOf (xa i) = 4 := by
  change _ = 2 ^ 2
  haveI : Fact (Nat.Prime 2) := Fact.mk Nat.prime_two
  apply order_of_eq_prime_pow
  · intro h
    simp only [pow_oneₓ, xa_sq] at h
    injection h with h'
    apply_fun Zmod.val  at h'
    apply_fun (· / n)  at h'
    simp only [Zmod.val_nat_cast, Zmod.val_zero, Nat.zero_divₓ, Nat.mod_mul_left_div_self,
      Nat.div_selfₓ (NeZero.pos n)] at h'
    norm_num at h'
    
  · norm_num
    

/-- In the special case `n = 1`, `quaternion 1` is a cyclic group (of order `4`). -/
theorem quaternion_group_one_is_cyclic : IsCyclic (QuaternionGroup 1) := by
  apply is_cyclic_of_order_of_eq_card
  rw [card, mul_oneₓ]
  exact order_of_xa 0

/-- If `0 < n`, then `a 1` has order `2 * n`.
-/
@[simp]
theorem order_of_a_one : orderOf (a 1 : QuaternionGroup n) = 2 * n := by
  cases' eq_zero_or_ne_zero n with hn hn
  · subst hn
    simp_rw [mul_zero, order_of_eq_zero_iff']
    intro n h
    rw [one_def, a_one_pow]
    apply mt a.inj
    haveI : CharZero (Zmod (2 * 0)) := Zmod.char_zero
    simpa using h.ne'
    
  apply (Nat.le_of_dvdₓ (NeZero.pos _) (order_of_dvd_of_pow_eq_one (@a_one_pow_n n))).lt_or_eq.resolve_left
  intro h
  have h1 : (a 1 : QuaternionGroup n) ^ orderOf (a 1) = 1 := pow_order_of_eq_one _
  rw [a_one_pow] at h1
  injection h1 with h2
  rw [← Zmod.val_eq_zero, Zmod.val_nat_cast, Nat.mod_eq_of_ltₓ h] at h2
  exact absurd h2.symm (order_of_pos _).Ne

/-- If `0 < n`, then `a i` has order `(2 * n) / gcd (2 * n) i`.
-/
theorem order_of_a [NeZero n] (i : Zmod (2 * n)) : orderOf (a i) = 2 * n / Nat.gcdₓ (2 * n) i.val := by
  conv_lhs => rw [← Zmod.nat_cast_zmod_val i]
  rw [← a_one_pow, order_of_pow, order_of_a_one]

theorem exponent : Monoidₓ.exponent (QuaternionGroup n) = 2 * lcm n 2 := by
  rw [← normalize_eq 2, ← lcm_mul_left, normalize_eq]
  norm_num
  cases' eq_zero_or_ne_zero n with hn hn
  · subst hn
    simp only [lcm_zero_left, mul_zero]
    exact Monoidₓ.exponent_eq_zero_of_order_zero order_of_a_one
    
  apply Nat.dvd_antisymm
  · apply Monoidₓ.exponent_dvd_of_forall_pow_eq_one
    rintro (m | m)
    · rw [← order_of_dvd_iff_pow_eq_one, order_of_a]
      refine' Nat.dvd_trans ⟨gcd (2 * n) m.val, _⟩ (dvd_lcm_left (2 * n) 4)
      exact (Nat.div_mul_cancelₓ (Nat.gcd_dvd_leftₓ (2 * n) m.val)).symm
      
    · rw [← order_of_dvd_iff_pow_eq_one, order_of_xa]
      exact dvd_lcm_right (2 * n) 4
      
    
  · apply lcm_dvd
    · convert Monoidₓ.order_dvd_exponent (a 1)
      exact order_of_a_one.symm
      
    · convert Monoidₓ.order_dvd_exponent (xa 0)
      exact (order_of_xa 0).symm
      
    

end QuaternionGroup

