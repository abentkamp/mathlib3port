/-
Copyright (c) 2022 Alexander Bentkamp. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alexander Bentkamp
-/
import Mathbin.LinearAlgebra.Matrix.Spectrum
import Mathbin.LinearAlgebra.QuadraticForm.Basic

/-! # Positive Definite Matrices

This file defines positive definite matrices and connects this notion to positive definiteness of
quadratic forms.

## Main definition

 * `matrix.pos_def` : a matrix `M : matrix n n R` is positive definite if it is hermitian
   and `xᴴMx` is greater than zero for all nonzero `x`.

-/


namespace Matrix

variable {𝕜 : Type _} [IsROrC 𝕜] {n : Type _} [Fintype n]

open Matrix

/-- A matrix `M : matrix n n R` is positive definite if it is hermitian
   and `xᴴMx` is greater than zero for all nonzero `x`. -/
def PosDef (M : Matrix n n 𝕜) :=
  M.IsHermitian ∧ ∀ x : n → 𝕜, x ≠ 0 → 0 < IsROrC.re (dotProduct (star x) (M.mulVec x))

theorem PosDef.is_hermitian {M : Matrix n n 𝕜} (hM : M.PosDef) : M.IsHermitian :=
  hM.1

theorem PosDef.transpose {M : Matrix n n 𝕜} (hM : M.PosDef) : Mᵀ.PosDef := by
  refine' ⟨is_hermitian.transpose hM.1, fun x hx => _⟩
  convert hM.2 (star x) (star_ne_zero.2 hx) using 2
  rw [mul_vec_transpose, Matrix.dot_product_mul_vec, star_star, dot_product_comm]

theorem pos_def_of_to_quadratic_form' [DecidableEq n] {M : Matrix n n ℝ} (hM : M.IsSymm)
    (hMq : M.toQuadraticForm'.PosDef) : M.PosDef := by
  refine' ⟨hM, fun x hx => _⟩
  simp only [to_quadratic_form', QuadraticForm.PosDef, BilinForm.to_quadratic_form_apply, Matrix.to_bilin'_apply'] at
    hMq
  apply hMq x hx

theorem pos_def_to_quadratic_form' [DecidableEq n] {M : Matrix n n ℝ} (hM : M.PosDef) : M.toQuadraticForm'.PosDef := by
  intro x hx
  simp only [to_quadratic_form', BilinForm.to_quadratic_form_apply, Matrix.to_bilin'_apply']
  apply hM.2 x hx

namespace PosDef

variable {M : Matrix n n ℝ} (hM : M.PosDef)

include hM

theorem det_pos [DecidableEq n] : 0 < det M := by
  rw [hM.is_hermitian.det_eq_prod_eigenvalues]
  apply Finset.prod_pos
  intro i _
  rw [hM.is_hermitian.eigenvalues_eq]
  apply hM.2 _ fun h => _
  have h_det : hM.is_hermitian.eigenvector_matrixᵀ.det = 0 :=
    Matrix.det_eq_zero_of_row_eq_zero i fun j => congr_funₓ h j
  simpa only [h_det, not_is_unit_zero] using is_unit_det_of_invertible hM.is_hermitian.eigenvector_matrixᵀ

end PosDef

end Matrix

namespace QuadraticForm

variable {n : Type _} [Fintype n]

theorem pos_def_of_to_matrix' [DecidableEq n] {Q : QuadraticForm ℝ (n → ℝ)} (hQ : Q.toMatrix'.PosDef) : Q.PosDef := by
  rw [← to_quadratic_form_associated ℝ Q, ← bilin_form.to_matrix'.left_inv ((associated_hom _) Q)]
  apply Matrix.pos_def_to_quadratic_form' hQ

theorem pos_def_to_matrix' [DecidableEq n] {Q : QuadraticForm ℝ (n → ℝ)} (hQ : Q.PosDef) : Q.toMatrix'.PosDef := by
  rw [← to_quadratic_form_associated ℝ Q, ← bilin_form.to_matrix'.left_inv ((associated_hom _) Q)] at hQ
  apply Matrix.pos_def_of_to_quadratic_form' (is_symm_to_matrix' Q) hQ

end QuadraticForm

namespace Matrix

variable {𝕜 : Type _} [IsROrC 𝕜] {n : Type _} [Fintype n]

/-- A positive definite matrix `M` induces an inner product `⟪x, y⟫ = xᴴMy`. -/
noncomputable def InnerProductSpace.ofMatrix {M : Matrix n n 𝕜} (hM : M.PosDef) : InnerProductSpace 𝕜 (n → 𝕜) :=
  InnerProductSpace.ofCore
    { inner := fun x y => dotProduct (star x) (M.mulVec y),
      conj_sym := fun x y => by
        rw [star_dot_product, star_ring_end_apply, star_star, star_mul_vec, dot_product_mul_vec, hM.is_hermitian.eq],
      nonneg_re := fun x => by
        by_cases' h : x = 0
        · simp [h]
          
        · exact le_of_ltₓ (hM.2 x h)
          ,
      definite := fun x hx => by
        by_contra' h
        simpa [hx, lt_self_iff_falseₓ] using hM.2 x h,
      add_left := by
        simp only [star_add, add_dot_product, eq_self_iff_true, forall_const],
      smul_left := fun x y r => by
        rw [← smul_eq_mul, ← smul_dot_product, star_ring_end_apply, ← star_smul] }

end Matrix

