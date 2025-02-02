/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Eric Wieser
-/
import Mathbin.Data.Matrix.Basis
import Mathbin.RingTheory.TensorProduct

/-!
We show `matrix n n A ≃ₐ[R] (A ⊗[R] matrix n n R)`.
-/


universe u v w

open TensorProduct

open BigOperators

open TensorProduct

open Algebra.TensorProduct

open Matrix

variable {R : Type u} [CommSemiringₓ R]

variable {A : Type v} [Semiringₓ A] [Algebra R A]

variable {n : Type w}

variable (R A n)

namespace matrixEquivTensor

/-- (Implementation detail).
The function underlying `(A ⊗[R] matrix n n R) →ₐ[R] matrix n n A`,
as an `R`-bilinear map.
-/
def toFunBilinear : A →ₗ[R] Matrix n n R →ₗ[R] Matrix n n A :=
  (Algebra.lsmul R (Matrix n n A)).toLinearMap.compl₂ (Algebra.linearMap R A).mapMatrix

@[simp]
theorem to_fun_bilinear_apply (a : A) (m : Matrix n n R) : toFunBilinear R A n a m = a • m.map (algebraMap R A) :=
  rfl

/-- (Implementation detail).
The function underlying `(A ⊗[R] matrix n n R) →ₐ[R] matrix n n A`,
as an `R`-linear map.
-/
def toFunLinear : A ⊗[R] Matrix n n R →ₗ[R] Matrix n n A :=
  TensorProduct.lift (toFunBilinear R A n)

variable [DecidableEq n] [Fintype n]

/-- The function `(A ⊗[R] matrix n n R) →ₐ[R] matrix n n A`, as an algebra homomorphism.
-/
def toFunAlgHom : A ⊗[R] Matrix n n R →ₐ[R] Matrix n n A :=
  algHomOfLinearMapTensorProduct (toFunLinear R A n)
    (by
      intros
      simp_rw [to_fun_linear, lift.tmul, to_fun_bilinear_apply, mul_eq_mul, Matrix.map_mul]
      ext
      dsimp'
      simp_rw [Matrix.mul_apply, Pi.smul_apply, Matrix.map_apply, smul_eq_mul, Finset.mul_sum, _root_.mul_assoc,
        Algebra.left_comm])
    (by
      intros
      simp_rw [to_fun_linear, lift.tmul, to_fun_bilinear_apply,
        Matrix.map_one (algebraMap R A) (map_zero _) (map_one _), algebra_map_smul, Algebra.algebra_map_eq_smul_one])

@[simp]
theorem to_fun_alg_hom_apply (a : A) (m : Matrix n n R) : toFunAlgHom R A n (a ⊗ₜ m) = a • m.map (algebraMap R A) := by
  simp [to_fun_alg_hom, alg_hom_of_linear_map_tensor_product, to_fun_linear]

/-- (Implementation detail.)

The bare function `matrix n n A → A ⊗[R] matrix n n R`.
(We don't need to show that it's an algebra map, thankfully --- just that it's an inverse.)
-/
def invFun (M : Matrix n n A) : A ⊗[R] Matrix n n R :=
  ∑ p : n × n, M p.1 p.2 ⊗ₜ stdBasisMatrix p.1 p.2 1

@[simp]
theorem inv_fun_zero : invFun R A n 0 = 0 := by
  simp [inv_fun]

@[simp]
theorem inv_fun_add (M N : Matrix n n A) : invFun R A n (M + N) = invFun R A n M + invFun R A n N := by
  simp [inv_fun, add_tmul, Finset.sum_add_distrib]

@[simp]
theorem inv_fun_smul (a : A) (M : Matrix n n A) : invFun R A n (a • M) = a ⊗ₜ 1 * invFun R A n M := by
  simp [inv_fun, Finset.mul_sum]

@[simp]
theorem inv_fun_algebra_map (M : Matrix n n R) : invFun R A n (M.map (algebraMap R A)) = 1 ⊗ₜ M := by
  dsimp' [inv_fun]
  simp only [Algebra.algebra_map_eq_smul_one, smul_tmul, ← tmul_sum, mul_boole]
  congr
  conv_rhs => rw [matrix_eq_sum_std_basis M]
  convert Finset.sum_product
  simp

theorem right_inv (M : Matrix n n A) : (toFunAlgHom R A n) (invFun R A n M) = M := by
  simp only [inv_fun, AlgHom.map_sum, std_basis_matrix, apply_iteₓ ⇑(algebraMap R A), smul_eq_mul, mul_boole,
    to_fun_alg_hom_apply, RingHom.map_zero, RingHom.map_one, Matrix.map_apply, Pi.smul_def]
  convert Finset.sum_product
  apply matrix_eq_sum_std_basis

theorem left_inv (M : A ⊗[R] Matrix n n R) : invFun R A n (toFunAlgHom R A n M) = M := by
  induction' M using TensorProduct.induction_on with a m x y hx hy
  · simp
    
  · simp
    
  · simp [AlgHom.map_sum, hx, hy]
    

/-- (Implementation detail)

The equivalence, ignoring the algebra structure, `(A ⊗[R] matrix n n R) ≃ matrix n n A`.
-/
def equiv : A ⊗[R] Matrix n n R ≃ Matrix n n A where
  toFun := toFunAlgHom R A n
  invFun := invFun R A n
  left_inv := left_inv R A n
  right_inv := right_inv R A n

end matrixEquivTensor

variable [Fintype n] [DecidableEq n]

/-- The `R`-algebra isomorphism `matrix n n A ≃ₐ[R] (A ⊗[R] matrix n n R)`.
-/
def matrixEquivTensor : Matrix n n A ≃ₐ[R] A ⊗[R] Matrix n n R :=
  AlgEquiv.symm { MatrixEquivTensor.toFunAlgHom R A n, MatrixEquivTensor.equiv R A n with }

open matrixEquivTensor

@[simp]
theorem matrix_equiv_tensor_apply (M : Matrix n n A) :
    matrixEquivTensor R A n M = ∑ p : n × n, M p.1 p.2 ⊗ₜ stdBasisMatrix p.1 p.2 1 :=
  rfl

@[simp]
theorem matrix_equiv_tensor_apply_std_basis (i j : n) (x : A) :
    matrixEquivTensor R A n (stdBasisMatrix i j x) = x ⊗ₜ stdBasisMatrix i j 1 := by
  have t : ∀ p : n × n, i = p.1 ∧ j = p.2 ↔ p = (i, j) := by
    tidy
  simp [ite_tmul, t, std_basis_matrix]

@[simp]
theorem matrix_equiv_tensor_apply_symm (a : A) (M : Matrix n n R) :
    (matrixEquivTensor R A n).symm (a ⊗ₜ M) = M.map fun x => a * algebraMap R A x := by
  simp [matrixEquivTensor, to_fun_alg_hom, alg_hom_of_linear_map_tensor_product, to_fun_linear]
  rfl

