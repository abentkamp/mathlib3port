/-
Copyright (c) 2022 Michael Stoll. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Michael Stoll
-/
import Mathbin.Tactic.Basic
import Mathbin.Data.Int.Range
import Mathbin.Data.Zmod.Basic
import Mathbin.NumberTheory.LegendreSymbol.MulCharacter

/-!
# Quadratic characters on ℤ/nℤ

This file defines some quadratic characters on the rings ℤ/4ℤ and ℤ/8ℤ.

We set them up to be of type `mul_char (zmod n) ℤ`, where `n` is `4` or `8`.

## Tags

quadratic character, zmod
-/


/-!
### Quadratic characters mod 4 and 8

We define the primitive quadratic characters `χ₄`on `zmod 4`
and `χ₈`, `χ₈'` on `zmod 8`.
-/


namespace Zmod

section QuadCharModP

/-- Define the nontrivial quadratic character on `zmod 4`, `χ₄`.
It corresponds to the extension `ℚ(√-1)/ℚ`. -/
@[simps]
def χ₄ : MulChar (Zmod 4) ℤ where
  toFun := (![0, 1, 0, -1] : Zmod 4 → ℤ)
  map_one' := rfl
  map_mul' := by
    decide
  map_nonunit' := by
    decide

/-- `χ₄` takes values in `{0, 1, -1}` -/
theorem is_quadratic_χ₄ : χ₄.IsQuadratic := by
  intro a
  decide!

/-- The value of `χ₄ n`, for `n : ℕ`, depends only on `n % 4`. -/
theorem χ₄_nat_mod_four (n : ℕ) : χ₄ n = χ₄ (n % 4 : ℕ) := by
  rw [← Zmod.nat_cast_mod n 4]

/-- The value of `χ₄ n`, for `n : ℤ`, depends only on `n % 4`. -/
theorem χ₄_int_mod_four (n : ℤ) : χ₄ n = χ₄ (n % 4 : ℤ) := by
  rw [← Zmod.int_cast_mod n 4]
  norm_cast

/-- An explicit description of `χ₄` on integers / naturals -/
theorem χ₄_int_eq_if_mod_four (n : ℤ) : χ₄ n = if n % 2 = 0 then 0 else if n % 4 = 1 then 1 else -1 := by
  have help : ∀ m : ℤ, 0 ≤ m → m < 4 → χ₄ m = if m % 2 = 0 then 0 else if m = 1 then 1 else -1 := by
    decide
  rw [←
    Int.mod_mod_of_dvd n
      (by
        norm_num : (2 : ℤ) ∣ 4),
    ← Zmod.int_cast_mod n 4]
  exact
    help (n % 4)
      (Int.mod_nonneg n
        (by
          norm_num))
      (Int.mod_lt n
        (by
          norm_num))

theorem χ₄_nat_eq_if_mod_four (n : ℕ) : χ₄ n = if n % 2 = 0 then 0 else if n % 4 = 1 then 1 else -1 := by
  exact_mod_cast χ₄_int_eq_if_mod_four n

/-- Alternative description of `χ₄ n` for odd `n : ℕ` in terms of powers of `-1` -/
theorem χ₄_eq_neg_one_pow {n : ℕ} (hn : n % 2 = 1) : χ₄ n = -1 ^ (n / 2) := by
  rw [χ₄_nat_eq_if_mod_four]
  simp only [hn, Nat.one_ne_zero, if_false]
  nth_rw 0[← Nat.div_add_modₓ n 4]
  nth_rw
    0[(by
      norm_num : 4 = 2 * 2)]
  rw [mul_assoc, add_commₓ,
    Nat.add_mul_div_leftₓ _ _
      (by
        norm_num : 0 < 2),
    pow_addₓ, pow_mulₓ, neg_one_sq, one_pow, mul_oneₓ]
  have help : ∀ m : ℕ, m < 4 → m % 2 = 1 → ite (m = 1) (1 : ℤ) (-1) = -1 ^ (m / 2) := by
    decide
  exact
    help (n % 4)
      (Nat.mod_ltₓ n
        (by
          norm_num))
      ((Nat.mod_mod_of_dvd n
            (by
              norm_num : 2 ∣ 4)).trans
        hn)

/-- If `n % 4 = 1`, then `χ₄ n = 1`. -/
theorem χ₄_nat_one_mod_four {n : ℕ} (hn : n % 4 = 1) : χ₄ n = 1 := by
  rw [χ₄_nat_mod_four, hn]
  rfl

/-- If `n % 4 = 3`, then `χ₄ n = -1`. -/
theorem χ₄_nat_three_mod_four {n : ℕ} (hn : n % 4 = 3) : χ₄ n = -1 := by
  rw [χ₄_nat_mod_four, hn]
  rfl

/-- If `n % 4 = 1`, then `χ₄ n = 1`. -/
theorem χ₄_int_one_mod_four {n : ℤ} (hn : n % 4 = 1) : χ₄ n = 1 := by
  rw [χ₄_int_mod_four, hn]
  rfl

/-- If `n % 4 = 3`, then `χ₄ n = -1`. -/
theorem χ₄_int_three_mod_four {n : ℤ} (hn : n % 4 = 3) : χ₄ n = -1 := by
  rw [χ₄_int_mod_four, hn]
  rfl

/-- If `n % 4 = 1`, then `(-1)^(n/2) = 1`. -/
theorem _root_.neg_one_pow_div_two_of_one_mod_four {n : ℕ} (hn : n % 4 = 1) : (-1 : ℤ) ^ (n / 2) = 1 := by
  rw [← χ₄_eq_neg_one_pow (Nat.odd_of_mod_four_eq_one hn), ← nat_cast_mod, hn]
  rfl

/-- If `n % 4 = 3`, then `(-1)^(n/2) = -1`. -/
theorem _root_.neg_one_pow_div_two_of_three_mod_four {n : ℕ} (hn : n % 4 = 3) : (-1 : ℤ) ^ (n / 2) = -1 := by
  rw [← χ₄_eq_neg_one_pow (Nat.odd_of_mod_four_eq_three hn), ← nat_cast_mod, hn]
  rfl

/-- Define the first primitive quadratic character on `zmod 8`, `χ₈`.
It corresponds to the extension `ℚ(√2)/ℚ`. -/
@[simps]
def χ₈ : MulChar (Zmod 8) ℤ where
  toFun := (![0, 1, 0, -1, 0, -1, 0, 1] : Zmod 8 → ℤ)
  map_one' := rfl
  map_mul' := by
    decide
  map_nonunit' := by
    decide

/-- `χ₈` takes values in `{0, 1, -1}` -/
theorem is_quadratic_χ₈ : χ₈.IsQuadratic := by
  intro a
  decide!

/-- The value of `χ₈ n`, for `n : ℕ`, depends only on `n % 8`. -/
theorem χ₈_nat_mod_eight (n : ℕ) : χ₈ n = χ₈ (n % 8 : ℕ) := by
  rw [← Zmod.nat_cast_mod n 8]

/-- The value of `χ₈ n`, for `n : ℤ`, depends only on `n % 8`. -/
theorem χ₈_int_mod_eight (n : ℤ) : χ₈ n = χ₈ (n % 8 : ℤ) := by
  rw [← Zmod.int_cast_mod n 8]
  norm_cast

/-- An explicit description of `χ₈` on integers / naturals -/
theorem χ₈_int_eq_if_mod_eight (n : ℤ) : χ₈ n = if n % 2 = 0 then 0 else if n % 8 = 1 ∨ n % 8 = 7 then 1 else -1 := by
  have help : ∀ m : ℤ, 0 ≤ m → m < 8 → χ₈ m = if m % 2 = 0 then 0 else if m = 1 ∨ m = 7 then 1 else -1 := by
    decide
  rw [←
    Int.mod_mod_of_dvd n
      (by
        norm_num : (2 : ℤ) ∣ 8),
    ← Zmod.int_cast_mod n 8]
  exact
    help (n % 8)
      (Int.mod_nonneg n
        (by
          norm_num))
      (Int.mod_lt n
        (by
          norm_num))

theorem χ₈_nat_eq_if_mod_eight (n : ℕ) : χ₈ n = if n % 2 = 0 then 0 else if n % 8 = 1 ∨ n % 8 = 7 then 1 else -1 := by
  exact_mod_cast χ₈_int_eq_if_mod_eight n

/-- Define the second primitive quadratic character on `zmod 8`, `χ₈'`.
It corresponds to the extension `ℚ(√-2)/ℚ`. -/
@[simps]
def χ₈' : MulChar (Zmod 8) ℤ where
  toFun := (![0, 1, 0, 1, 0, -1, 0, -1] : Zmod 8 → ℤ)
  map_one' := rfl
  map_mul' := by
    decide
  map_nonunit' := by
    decide

/-- `χ₈'` takes values in `{0, 1, -1}` -/
theorem is_quadratic_χ₈' : χ₈'.IsQuadratic := by
  intro a
  decide!

/-- An explicit description of `χ₈'` on integers / naturals -/
theorem χ₈'_int_eq_if_mod_eight (n : ℤ) : χ₈' n = if n % 2 = 0 then 0 else if n % 8 = 1 ∨ n % 8 = 3 then 1 else -1 := by
  have help : ∀ m : ℤ, 0 ≤ m → m < 8 → χ₈' m = if m % 2 = 0 then 0 else if m = 1 ∨ m = 3 then 1 else -1 := by
    decide
  rw [←
    Int.mod_mod_of_dvd n
      (by
        norm_num : (2 : ℤ) ∣ 8),
    ← Zmod.int_cast_mod n 8]
  exact
    help (n % 8)
      (Int.mod_nonneg n
        (by
          norm_num))
      (Int.mod_lt n
        (by
          norm_num))

theorem χ₈'_nat_eq_if_mod_eight (n : ℕ) : χ₈' n = if n % 2 = 0 then 0 else if n % 8 = 1 ∨ n % 8 = 3 then 1 else -1 := by
  exact_mod_cast χ₈'_int_eq_if_mod_eight n

/-- The relation between `χ₄`, `χ₈` and `χ₈'` -/
theorem χ₈'_eq_χ₄_mul_χ₈ (a : Zmod 8) : χ₈' a = χ₄ a * χ₈ a := by
  decide!

theorem χ₈'_int_eq_χ₄_mul_χ₈ (a : ℤ) : χ₈' a = χ₄ a * χ₈ a := by
  rw [←
    @cast_int_cast 8 (Zmod 4) _ 4 _
      (by
        norm_num)
      a]
  exact χ₈'_eq_χ₄_mul_χ₈ a

end QuadCharModP

end Zmod

