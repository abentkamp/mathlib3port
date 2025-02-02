/-
Copyright (c) 2021 Jakob von Raumer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jakob von Raumer
-/
import Mathbin.LinearAlgebra.Contraction
import Mathbin.LinearAlgebra.FiniteDimensional
import Mathbin.LinearAlgebra.Dual

/-!
# The coevaluation map on finite dimensional vector spaces

Given a finite dimensional vector space `V` over a field `K` this describes the canonical linear map
from `K` to `V ⊗ dual K V` which corresponds to the identity function on `V`.

## Tags

coevaluation, dual module, tensor product

## Future work

* Prove that this is independent of the choice of basis on `V`.
-/


noncomputable section

section coevaluation

open TensorProduct FiniteDimensional

open TensorProduct BigOperators

universe u v

variable (K : Type u) [Field K]

variable (V : Type v) [AddCommGroupₓ V] [Module K V] [FiniteDimensional K V]

/-- The coevaluation map is a linear map from a field `K` to a finite dimensional
  vector space `V`. -/
def coevaluation : K →ₗ[K] V ⊗[K] Module.Dual K V :=
  let bV := Basis.ofVectorSpace K V
  ((Basis.singleton Unit K).constr K) fun _ => ∑ i : Basis.OfVectorSpaceIndex K V, bV i ⊗ₜ[K] bV.Coord i

theorem coevaluation_apply_one :
    (coevaluation K V) (1 : K) =
      let bV := Basis.ofVectorSpace K V
      ∑ i : Basis.OfVectorSpaceIndex K V, bV i ⊗ₜ[K] bV.Coord i :=
  by
  simp only [coevaluation, id]
  rw [(Basis.singleton Unit K).constr_apply_fintype K]
  simp only [Fintype.univ_punit, Finset.sum_const, one_smul, Basis.singleton_repr, Basis.equiv_fun_apply,
    Basis.coe_of_vector_space, one_nsmul, Finset.card_singleton]

open TensorProduct

/-- This lemma corresponds to one of the coherence laws for duals in rigid categories, see
  `category_theory.monoidal.rigid`. -/
theorem contract_left_assoc_coevaluation :
    (contractLeft K V).rtensor _ ∘ₗ
        (TensorProduct.assoc K _ _ _).symm.toLinearMap ∘ₗ (coevaluation K V).ltensor (Module.Dual K V) =
      (TensorProduct.lid K _).symm.toLinearMap ∘ₗ (TensorProduct.rid K _).toLinearMap :=
  by
  letI := Classical.decEq (Basis.OfVectorSpaceIndex K V)
  apply TensorProduct.ext
  apply (Basis.ofVectorSpace K V).dualBasis.ext
  intro j
  apply LinearMap.ext_ring
  rw [LinearMap.compr₂_apply, LinearMap.compr₂_apply, TensorProduct.mk_apply]
  simp only [LinearMap.coe_comp, Function.comp_app, LinearEquiv.coe_to_linear_map]
  rw [rid_tmul, one_smul, lid_symm_apply]
  simp only [LinearEquiv.coe_to_linear_map, LinearMap.ltensor_tmul, coevaluation_apply_one]
  rw [TensorProduct.tmul_sum, LinearEquiv.map_sum]
  simp only [assoc_symm_tmul]
  rw [LinearMap.map_sum]
  simp only [LinearMap.rtensor_tmul, contract_left_apply]
  simp only [Basis.coe_dual_basis, Basis.coord_apply, Basis.repr_self_apply, TensorProduct.ite_tmul]
  rw [Finset.sum_ite_eq']
  simp only [Finset.mem_univ, if_true]

/-- This lemma corresponds to one of the coherence laws for duals in rigid categories, see
  `category_theory.monoidal.rigid`. -/
theorem contract_left_assoc_coevaluation' :
    (contractLeft K V).ltensor _ ∘ₗ (TensorProduct.assoc K _ _ _).toLinearMap ∘ₗ (coevaluation K V).rtensor V =
      (TensorProduct.rid K _).symm.toLinearMap ∘ₗ (TensorProduct.lid K _).toLinearMap :=
  by
  letI := Classical.decEq (Basis.OfVectorSpaceIndex K V)
  apply TensorProduct.ext
  apply LinearMap.ext_ring
  apply (Basis.ofVectorSpace K V).ext
  intro j
  rw [LinearMap.compr₂_apply, LinearMap.compr₂_apply, TensorProduct.mk_apply]
  simp only [LinearMap.coe_comp, Function.comp_app, LinearEquiv.coe_to_linear_map]
  rw [lid_tmul, one_smul, rid_symm_apply]
  simp only [LinearEquiv.coe_to_linear_map, LinearMap.rtensor_tmul, coevaluation_apply_one]
  rw [TensorProduct.sum_tmul, LinearEquiv.map_sum]
  simp only [assoc_tmul]
  rw [LinearMap.map_sum]
  simp only [LinearMap.ltensor_tmul, contract_left_apply]
  simp only [Basis.coord_apply, Basis.repr_self_apply, TensorProduct.tmul_ite]
  rw [Finset.sum_ite_eq]
  simp only [Finset.mem_univ, if_true]

end coevaluation

