/-
Copyright (c) 2022 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import Mathbin.Algebra.CharZero
import Mathbin.GroupTheory.QuotientGroup

/-!
# Lemmas about quotients in characteristic zero
-/


variable {R : Type _} [DivisionRing R] [CharZero R] {p : R}

namespace AddSubgroup

/-- `z • r` is a multiple of `p` iff `r` is `pk/z` above a multiple of `p`, where `0 ≤ k < |z|`. -/
theorem zsmul_mem_zmultiples_iff_exists_sub_div {r : R} {z : ℤ} (hz : z ≠ 0) :
    z • r ∈ AddSubgroup.zmultiples p ↔ ∃ k : Finₓ z.natAbs, r - (k : ℕ) • (p / z : R) ∈ AddSubgroup.zmultiples p := by
  rw [AddSubgroup.mem_zmultiples_iff]
  simp_rw [AddSubgroup.mem_zmultiples_iff, div_eq_mul_inv, ← smul_mul_assoc, eq_sub_iff_add_eq]
  have hz' : (z : R) ≠ 0 := int.cast_ne_zero.mpr hz
  conv_rhs => simp (config := { singlePass := true })only [← (mul_right_injective₀ hz').eq_iff]
  simp_rw [← zsmul_eq_mul, smul_add, ← mul_smul_comm, zsmul_eq_mul (z : R)⁻¹, mul_inv_cancel hz', mul_oneₓ, ←
    coe_nat_zsmul, smul_smul, ← add_smul]
  constructor
  · rintro ⟨k, h⟩
    simp_rw [← h]
    refine' ⟨⟨(k % z).toNat, _⟩, k / z, _⟩
    · rw [← Int.coe_nat_ltₓ, Int.to_nat_of_nonneg (Int.mod_nonneg _ hz)]
      exact (Int.mod_lt _ hz).trans_eq (Int.abs_eq_nat_abs _)
      
    rw [Finₓ.coe_mk, Int.to_nat_of_nonneg (Int.mod_nonneg _ hz), Int.div_add_mod]
    
  · rintro ⟨k, n, h⟩
    exact ⟨_, h⟩
    

theorem nsmul_mem_zmultiples_iff_exists_sub_div {r : R} {n : ℕ} (hn : n ≠ 0) :
    n • r ∈ AddSubgroup.zmultiples p ↔ ∃ k : Finₓ n, r - (k : ℕ) • (p / n : R) ∈ AddSubgroup.zmultiples p := by
  simp_rw [← coe_nat_zsmul r, zsmul_mem_zmultiples_iff_exists_sub_div (int.coe_nat_ne_zero.mpr hn), Int.cast_coe_nat]
  rfl

end AddSubgroup

namespace QuotientAddGroup

theorem zmultiples_zsmul_eq_zsmul_iff {ψ θ : R ⧸ AddSubgroup.zmultiples p} {z : ℤ} (hz : z ≠ 0) :
    z • ψ = z • θ ↔ ∃ k : Finₓ z.natAbs, ψ = θ + (k : ℕ) • (p / z : R) := by
  induction ψ using Quotientₓ.induction_on'
  induction θ using Quotientₓ.induction_on'
  have : (Quotientₓ.mk' : R → R ⧸ AddSubgroup.zmultiples p) = coe := rfl
  simp only [this]
  simp_rw [← coe_zsmul, ← coe_nsmul, ← coe_add, QuotientAddGroup.eq_iff_sub_mem, ← smul_sub, ← sub_sub,
    AddSubgroup.zsmul_mem_zmultiples_iff_exists_sub_div hz]

theorem zmultiples_nsmul_eq_nsmul_iff {ψ θ : R ⧸ AddSubgroup.zmultiples p} {n : ℕ} (hz : n ≠ 0) :
    n • ψ = n • θ ↔ ∃ k : Finₓ n, ψ = θ + (k : ℕ) • (p / n : R) := by
  simp_rw [← coe_nat_zsmul ψ, ← coe_nat_zsmul θ, zmultiples_zsmul_eq_zsmul_iff (int.coe_nat_ne_zero.mpr hz),
    Int.cast_coe_nat]
  rfl

end QuotientAddGroup

