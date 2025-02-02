/-
Copyright (c) 2020 Oliver Nash. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Oliver Nash, Antoine Labelle
-/
import Mathbin.LinearAlgebra.Dual
import Mathbin.LinearAlgebra.Matrix.ToLin
import Mathbin.LinearAlgebra.TensorProductBasis
import Mathbin.LinearAlgebra.FreeModule.Finite.Rank

/-!
# Contractions

Given modules $M, N$ over a commutative ring $R$, this file defines the natural linear maps:
$M^* \otimes M \to R$, $M \otimes M^* \to R$, and $M^* \otimes N → Hom(M, N)$, as well as proving
some basic properties of these maps.

## Tags

contraction, dual module, tensor product
-/


variable {ι : Type _} (R M N P Q : Type _)

attribute [local ext] TensorProduct.ext

section Contraction

open TensorProduct LinearMap Matrix Module

open TensorProduct BigOperators

section CommSemiringₓ

variable [CommSemiringₓ R]

variable [AddCommMonoidₓ M] [AddCommMonoidₓ N] [AddCommMonoidₓ P] [AddCommMonoidₓ Q]

variable [Module R M] [Module R N] [Module R P] [Module R Q]

variable [DecidableEq ι] [Fintype ι] (b : Basis ι R M)

/-- The natural left-handed pairing between a module and its dual. -/
def contractLeft : Module.Dual R M ⊗ M →ₗ[R] R :=
  (uncurry _ _ _ _).toFun LinearMap.id

/-- The natural right-handed pairing between a module and its dual. -/
def contractRight : M ⊗ Module.Dual R M →ₗ[R] R :=
  (uncurry _ _ _ _).toFun (LinearMap.flip LinearMap.id)

/-- The natural map associating a linear map to the tensor product of two modules. -/
def dualTensorHom : Module.Dual R M ⊗ N →ₗ[R] M →ₗ[R] N :=
  let M' := Module.Dual R M
  (uncurry R M' N (M →ₗ[R] N) : _ → M' ⊗ N →ₗ[R] M →ₗ[R] N) LinearMap.smulRightₗ

variable {R M N P Q}

@[simp]
theorem contract_left_apply (f : Module.Dual R M) (m : M) : contractLeft R M (f ⊗ₜ m) = f m := by
  apply uncurry_apply

@[simp]
theorem contract_right_apply (f : Module.Dual R M) (m : M) : contractRight R M (m ⊗ₜ f) = f m := by
  apply uncurry_apply

@[simp]
theorem dual_tensor_hom_apply (f : Module.Dual R M) (m : M) (n : N) : dualTensorHom R M N (f ⊗ₜ n) m = f m • n := by
  dunfold dualTensorHom
  rw [uncurry_apply]
  rfl

@[simp]
theorem transpose_dual_tensor_hom (f : Module.Dual R M) (m : M) :
    Dual.transpose (dualTensorHom R M M (f ⊗ₜ m)) = dualTensorHom R _ _ (Dual.eval R M m ⊗ₜ f) := by
  ext f' m'
  simp only [dual.transpose_apply, coe_comp, Function.comp_app, dual_tensor_hom_apply, LinearMap.map_smulₛₗ,
    RingHom.id_apply, Algebra.id.smul_eq_mul, dual.eval_apply, smul_apply]
  exact mul_comm _ _

@[simp]
theorem dual_tensor_hom_prod_map_zero (f : Module.Dual R M) (p : P) :
    ((dualTensorHom R M P) (f ⊗ₜ[R] p)).prod_map (0 : N →ₗ[R] Q) =
      dualTensorHom R (M × N) (P × Q) ((f ∘ₗ fst R M N) ⊗ₜ inl R P Q p) :=
  by
  ext <;>
    simp only [coe_comp, coe_inl, Function.comp_app, prod_map_apply, dual_tensor_hom_apply, fst_apply, Prod.smul_mk,
      zero_apply, smul_zero]

@[simp]
theorem zero_prod_map_dual_tensor_hom (g : Module.Dual R N) (q : Q) :
    (0 : M →ₗ[R] P).prod_map ((dualTensorHom R N Q) (g ⊗ₜ[R] q)) =
      dualTensorHom R (M × N) (P × Q) ((g ∘ₗ snd R M N) ⊗ₜ inr R P Q q) :=
  by
  ext <;>
    simp only [coe_comp, coe_inr, Function.comp_app, prod_map_apply, dual_tensor_hom_apply, snd_apply, Prod.smul_mk,
      zero_apply, smul_zero]

theorem map_dual_tensor_hom (f : Module.Dual R M) (p : P) (g : Module.Dual R N) (q : Q) :
    TensorProduct.map (dualTensorHom R M P (f ⊗ₜ[R] p)) (dualTensorHom R N Q (g ⊗ₜ[R] q)) =
      dualTensorHom R (M ⊗[R] N) (P ⊗[R] Q) (dualDistrib R M N (f ⊗ₜ g) ⊗ₜ[R] p ⊗ₜ[R] q) :=
  by
  ext m n
  simp only [compr₂_apply, mk_apply, map_tmul, dual_tensor_hom_apply, dual_distrib_apply, ← smul_tmul_smul]

@[simp]
theorem comp_dual_tensor_hom (f : Module.Dual R M) (n : N) (g : Module.Dual R N) (p : P) :
    dualTensorHom R N P (g ⊗ₜ[R] p) ∘ₗ dualTensorHom R M N (f ⊗ₜ[R] n) = g n • dualTensorHom R M P (f ⊗ₜ p) := by
  ext m
  simp only [coe_comp, Function.comp_app, dual_tensor_hom_apply, LinearMap.map_smul, RingHom.id_apply, smul_apply]
  rw [smul_comm]

/-- As a matrix, `dual_tensor_hom` evaluated on a basis element of `M* ⊗ N` is a matrix with a
single one and zeros elsewhere -/
theorem to_matrix_dual_tensor_hom {m : Type _} {n : Type _} [Fintype m] [Fintype n] [DecidableEq m] [DecidableEq n]
    (bM : Basis m R M) (bN : Basis n R N) (j : m) (i : n) :
    toMatrix bM bN (dualTensorHom R M N (bM.Coord j ⊗ₜ bN i)) = stdBasisMatrix i j 1 := by
  ext i' j'
  by_cases' hij : i = i' ∧ j = j' <;> simp [LinearMap.to_matrix_apply, Finsupp.single_eq_pi_single, hij]
  rw [and_iff_not_or_not, not_not] at hij
  cases hij <;> simp [hij]

end CommSemiringₓ

section CommRingₓ

variable [CommRingₓ R]

variable [AddCommGroupₓ M] [AddCommGroupₓ N] [AddCommGroupₓ P] [AddCommGroupₓ Q]

variable [Module R M] [Module R N] [Module R P] [Module R Q]

variable [DecidableEq ι] [Fintype ι] (b : Basis ι R M)

variable {R M N P Q}

/-- If `M` is free, the natural linear map $M^* ⊗ N → Hom(M, N)$ is an equivalence. This function
provides this equivalence in return for a basis of `M`. -/
@[simps apply]
noncomputable def dualTensorHomEquivOfBasis : Module.Dual R M ⊗[R] N ≃ₗ[R] M →ₗ[R] N :=
  LinearEquiv.ofLinear (dualTensorHom R M N) (∑ i, TensorProduct.mk R _ N (b.dualBasis i) ∘ₗ LinearMap.applyₗ (b i))
    (by
      ext f m
      simp only [applyₗ_apply_apply, coe_fn_sum, dual_tensor_hom_apply, mk_apply, id_coe, id.def, Fintype.sum_apply,
        Function.comp_app, Basis.coe_dual_basis, coe_comp, Basis.coord_apply, ← f.map_smul,
        (dualTensorHom R M N).map_sum, ← f.map_sum, b.sum_repr])
    (by
      ext f m
      simp only [applyₗ_apply_apply, coe_fn_sum, dual_tensor_hom_apply, mk_apply, id_coe, id.def, Fintype.sum_apply,
        Function.comp_app, Basis.coe_dual_basis, coe_comp, compr₂_apply, tmul_smul, smul_tmul', ← sum_tmul,
        Basis.sum_dual_apply_smul_coord])

@[simp]
theorem dual_tensor_hom_equiv_of_basis_to_linear_map :
    (dualTensorHomEquivOfBasis b : Module.Dual R M ⊗[R] N ≃ₗ[R] M →ₗ[R] N).toLinearMap = dualTensorHom R M N :=
  rfl

@[simp]
theorem dual_tensor_hom_equiv_of_basis_symm_cancel_left (x : Module.Dual R M ⊗[R] N) :
    (dualTensorHomEquivOfBasis b).symm (dualTensorHom R M N x) = x := by
  rw [← dual_tensor_hom_equiv_of_basis_apply b, LinearEquiv.symm_apply_apply]

@[simp]
theorem dual_tensor_hom_equiv_of_basis_symm_cancel_right (x : M →ₗ[R] N) :
    dualTensorHom R M N ((dualTensorHomEquivOfBasis b).symm x) = x := by
  rw [← dual_tensor_hom_equiv_of_basis_apply b, LinearEquiv.apply_symm_apply]

variable (R M N P Q)

variable [Module.Free R M] [Module.Finite R M] [Nontrivial R]

open Classical

/-- If `M` is finite free, the natural map $M^* ⊗ N → Hom(M, N)$ is an
equivalence. -/
@[simp]
noncomputable def dualTensorHomEquiv : Module.Dual R M ⊗[R] N ≃ₗ[R] M →ₗ[R] N :=
  dualTensorHomEquivOfBasis (Module.Free.chooseBasis R M)

end CommRingₓ

end Contraction

section HomTensorHom

open TensorProduct

open Module TensorProduct LinearMap

section CommRingₓ

variable [CommRingₓ R]

variable [AddCommGroupₓ M] [AddCommGroupₓ N] [AddCommGroupₓ P] [AddCommGroupₓ Q]

variable [Module R M] [Module R N] [Module R P] [Module R Q]

variable [Free R M] [Finite R M] [Free R N] [Finite R N] [Nontrivial R]

/-- When `M` is a finite free module, the map `ltensor_hom_to_hom_ltensor` is an equivalence. Note
that `ltensor_hom_equiv_hom_ltensor` is not defined directly in terms of
`ltensor_hom_to_hom_ltensor`, but the equivalence between the two is given by
`ltensor_hom_equiv_hom_ltensor_to_linear_map` and `ltensor_hom_equiv_hom_ltensor_apply`. -/
noncomputable def ltensorHomEquivHomLtensor : P ⊗[R] (M →ₗ[R] Q) ≃ₗ[R] M →ₗ[R] P ⊗[R] Q :=
  congr (LinearEquiv.refl R P) (dualTensorHomEquiv R M Q).symm ≪≫ₗ TensorProduct.leftComm R P _ Q ≪≫ₗ
    dualTensorHomEquiv R M _

/-- When `M` is a finite free module, the map `rtensor_hom_to_hom_rtensor` is an equivalence. Note
that `rtensor_hom_equiv_hom_rtensor` is not defined directly in terms of
`rtensor_hom_to_hom_rtensor`, but the equivalence between the two is given by
`rtensor_hom_equiv_hom_rtensor_to_linear_map` and `rtensor_hom_equiv_hom_rtensor_apply`. -/
noncomputable def rtensorHomEquivHomRtensor : (M →ₗ[R] P) ⊗[R] Q ≃ₗ[R] M →ₗ[R] P ⊗[R] Q :=
  congr (dualTensorHomEquiv R M P).symm (LinearEquiv.refl R Q) ≪≫ₗ TensorProduct.assoc R _ P Q ≪≫ₗ
    dualTensorHomEquiv R M _

@[simp]
theorem ltensor_hom_equiv_hom_ltensor_to_linear_map :
    (ltensorHomEquivHomLtensor R M P Q).toLinearMap = ltensorHomToHomLtensor R M P Q := by
  let e := congr (LinearEquiv.refl R P) (dualTensorHomEquiv R M Q)
  have h : Function.Surjective e.to_linear_map := e.surjective
  refine' (cancel_right h).1 _
  ext p f q m
  simp only [ltensorHomEquivHomLtensor, dualTensorHomEquiv, compr₂_apply, mk_apply, coe_comp,
    LinearEquiv.coe_to_linear_map, Function.comp_app, map_tmul, LinearEquiv.coe_coe,
    dual_tensor_hom_equiv_of_basis_apply, LinearEquiv.trans_apply, congr_tmul, LinearEquiv.refl_apply,
    dual_tensor_hom_equiv_of_basis_symm_cancel_left, left_comm_tmul, dual_tensor_hom_apply,
    ltensor_hom_to_hom_ltensor_apply, tmul_smul]

@[simp]
theorem rtensor_hom_equiv_hom_rtensor_to_linear_map :
    (rtensorHomEquivHomRtensor R M P Q).toLinearMap = rtensorHomToHomRtensor R M P Q := by
  let e := congr (dualTensorHomEquiv R M P) (LinearEquiv.refl R Q)
  have h : Function.Surjective e.to_linear_map := e.surjective
  refine' (cancel_right h).1 _
  ext f p q m
  simp only [rtensorHomEquivHomRtensor, dualTensorHomEquiv, compr₂_apply, mk_apply, coe_comp,
    LinearEquiv.coe_to_linear_map, Function.comp_app, map_tmul, LinearEquiv.coe_coe,
    dual_tensor_hom_equiv_of_basis_apply, LinearEquiv.trans_apply, congr_tmul,
    dual_tensor_hom_equiv_of_basis_symm_cancel_left, LinearEquiv.refl_apply, assoc_tmul, dual_tensor_hom_apply,
    rtensor_hom_to_hom_rtensor_apply, smul_tmul']

variable {R M N P Q}

@[simp]
theorem ltensor_hom_equiv_hom_ltensor_apply (x : P ⊗[R] (M →ₗ[R] Q)) :
    ltensorHomEquivHomLtensor R M P Q x = ltensorHomToHomLtensor R M P Q x := by
  rw [← LinearEquiv.coe_to_linear_map, ltensor_hom_equiv_hom_ltensor_to_linear_map]

@[simp]
theorem rtensor_hom_equiv_hom_rtensor_apply (x : (M →ₗ[R] P) ⊗[R] Q) :
    rtensorHomEquivHomRtensor R M P Q x = rtensorHomToHomRtensor R M P Q x := by
  rw [← LinearEquiv.coe_to_linear_map, rtensor_hom_equiv_hom_rtensor_to_linear_map]

variable (R M N P Q)

/-- When `M` and `N` are free `R` modules, the map `hom_tensor_hom_map` is an equivalence. Note that
`hom_tensor_hom_equiv` is not defined directly in terms of `hom_tensor_hom_map`, but the equivalence
between the two is given by `hom_tensor_hom_equiv_to_linear_map` and `hom_tensor_hom_equiv_apply`.
-/
noncomputable def homTensorHomEquiv : (M →ₗ[R] P) ⊗[R] (N →ₗ[R] Q) ≃ₗ[R] M ⊗[R] N →ₗ[R] P ⊗[R] Q :=
  rtensorHomEquivHomRtensor R M P _ ≪≫ₗ (LinearEquiv.refl R M).arrowCongr (ltensorHomEquivHomLtensor R N _ Q) ≪≫ₗ
    lift.equiv R M N _

@[simp]
theorem hom_tensor_hom_equiv_to_linear_map : (homTensorHomEquiv R M N P Q).toLinearMap = homTensorHomMap R M N P Q := by
  ext f g m n
  simp only [homTensorHomEquiv, compr₂_apply, mk_apply, LinearEquiv.coe_to_linear_map, LinearEquiv.trans_apply,
    lift.equiv_apply, LinearEquiv.arrow_congr_apply, LinearEquiv.refl_symm, LinearEquiv.refl_apply,
    rtensor_hom_equiv_hom_rtensor_apply, ltensor_hom_equiv_hom_ltensor_apply, ltensor_hom_to_hom_ltensor_apply,
    rtensor_hom_to_hom_rtensor_apply, hom_tensor_hom_map_apply, map_tmul]

variable {R M N P Q}

@[simp]
theorem hom_tensor_hom_equiv_apply (x : (M →ₗ[R] P) ⊗[R] (N →ₗ[R] Q)) :
    homTensorHomEquiv R M N P Q x = homTensorHomMap R M N P Q x := by
  rw [← LinearEquiv.coe_to_linear_map, hom_tensor_hom_equiv_to_linear_map]

end CommRingₓ

end HomTensorHom

