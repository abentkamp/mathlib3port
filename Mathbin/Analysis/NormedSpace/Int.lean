/-
Copyright (c) 2021 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import Mathbin.Analysis.NormedSpace.Basic

/-!
# The integers as normed ring

This file contains basic facts about the integers as normed ring.

Recall that `∥n∥` denotes the norm of `n` as real number.
This norm is always nonnegative, so we can bundle the norm together with this fact,
to obtain a term of type `nnreal` (the nonnegative real numbers).
The resulting nonnegative real number is denoted by `∥n∥₊`.
-/


open BigOperators

namespace Int

theorem nnnorm_coe_units (e : ℤˣ) : ∥(e : ℤ)∥₊ = 1 := by
  obtain rfl | rfl := Int.units_eq_one_or e <;> simp only [Units.coe_neg_one, Units.coe_one, nnnorm_neg, nnnorm_one]

theorem norm_coe_units (e : ℤˣ) : ∥(e : ℤ)∥ = 1 := by
  rw [← coe_nnnorm, Int.nnnorm_coe_units, Nnreal.coe_one]

@[simp]
theorem nnnorm_coe_nat (n : ℕ) : ∥(n : ℤ)∥₊ = n :=
  Real.nnnorm_coe_nat _

@[simp]
theorem norm_coe_nat (n : ℕ) : ∥(n : ℤ)∥ = n :=
  Real.norm_coe_nat _

@[simp]
theorem to_nat_add_to_nat_neg_eq_nnnorm (n : ℤ) : ↑n.toNat + ↑(-n).toNat = ∥n∥₊ := by
  rw [← Nat.cast_addₓ, to_nat_add_to_nat_neg_eq_nat_abs, Nnreal.coe_nat_abs]

@[simp]
theorem to_nat_add_to_nat_neg_eq_norm (n : ℤ) : ↑n.toNat + ↑(-n).toNat = ∥n∥ := by
  simpa only [Nnreal.coe_nat_cast, Nnreal.coe_add] using congr_argₓ (coe : _ → ℝ) (to_nat_add_to_nat_neg_eq_nnnorm n)

end Int

