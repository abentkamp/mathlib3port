/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import Mathbin.Algebra.Algebra.Basic
import Mathbin.NumberTheory.ClassNumber.AdmissibleAbsoluteValue

/-!
# Admissible absolute value on the integers
This file defines an admissible absolute value `absolute_value.abs_is_admissible`
which we use to show the class number of the ring of integers of a number field
is finite.

## Main results

 * `absolute_value.abs_is_admissible` shows the "standard" absolute value on `ℤ`,
   mapping negative `x` to `-x`, is admissible.
-/


namespace AbsoluteValue

open Int

/-- We can partition a finite family into `partition_card ε` sets, such that the remainders
in each set are close together. -/
theorem exists_partition_int (n : ℕ) {ε : ℝ} (hε : 0 < ε) {b : ℤ} (hb : b ≠ 0) (A : Finₓ n → ℤ) :
    ∃ t : Finₓ n → Finₓ ⌈1 / ε⌉₊, ∀ i₀ i₁, t i₀ = t i₁ → ↑(abs (A i₁ % b - A i₀ % b)) < abs b • ε := by
  have hb' : (0 : ℝ) < ↑(abs b) := int.cast_pos.mpr (abs_pos.mpr hb)
  have hbε : 0 < abs b • ε := by
    rw [Algebra.smul_def]
    exact mul_pos hb' hε
  have hfloor : ∀ i, 0 ≤ floor ((A i % b : ℤ) / abs b • ε : ℝ) := by
    intro i
    exact floor_nonneg.mpr (div_nonneg (cast_nonneg.mpr (mod_nonneg _ hb)) hbε.le)
  refine' ⟨fun i => ⟨nat_abs (floor ((A i % b : ℤ) / abs b • ε : ℝ)), _⟩, _⟩
  · rw [← coe_nat_lt, nat_abs_of_nonneg (hfloor i), floor_lt]
    apply lt_of_lt_of_leₓ _ (Nat.le_ceil _)
    rw [Algebra.smul_def, eq_int_cast, ← div_div, div_lt_div_right hε, div_lt_iff hb', one_mulₓ, cast_lt]
    exact Int.mod_lt _ hb
    
  intro i₀ i₁ hi
  have hi : (⌊↑(A i₀ % b) / abs b • ε⌋.natAbs : ℤ) = ⌊↑(A i₁ % b) / abs b • ε⌋.natAbs :=
    congr_argₓ (coe : ℕ → ℤ) (fin.mk_eq_mk.mp hi)
  rw [nat_abs_of_nonneg (hfloor i₀), nat_abs_of_nonneg (hfloor i₁)] at hi
  have hi := abs_sub_lt_one_of_floor_eq_floor hi
  rw [abs_sub_comm, ← sub_div, abs_div, abs_of_nonneg hbε.le, div_lt_iff hbε, one_mulₓ] at hi
  rwa [Int.cast_abs, Int.cast_sub]

/-- `abs : ℤ → ℤ` is an admissible absolute value -/
noncomputable def absIsAdmissible : IsAdmissible AbsoluteValue.abs :=
  { AbsoluteValue.abs_is_euclidean with card := fun ε => ⌈1 / ε⌉₊,
    exists_partition' := fun n ε hε b hb => exists_partition_int n hε hb }

noncomputable instance : Inhabited (IsAdmissible AbsoluteValue.abs) :=
  ⟨absIsAdmissible⟩

end AbsoluteValue

