/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kexing Ying, Eric Wieser
-/
import Mathbin.LinearAlgebra.QuadraticForm.Basic

/-!
# Isometries with respect to quadratic forms

## Main definitions

* `quadratic_form.isometry`: `linear_equiv`s which map between two different quadratic forms
* `quadratic_form.equvialent`: propositional version of the above

## Main results

* `equivalent_weighted_sum_squares`: in finite dimensions, any quadratic form is equivalent to a
  parametrization of `quadratic_form.weighted_sum_squares`.
-/


variable {ι R K M M₁ M₂ M₃ V : Type _}

namespace QuadraticForm

variable [Semiringₓ R]

variable [AddCommMonoidₓ M] [AddCommMonoidₓ M₁] [AddCommMonoidₓ M₂] [AddCommMonoidₓ M₃]

variable [Module R M] [Module R M₁] [Module R M₂] [Module R M₃]

/-- An isometry between two quadratic spaces `M₁, Q₁` and `M₂, Q₂` over a ring `R`,
is a linear equivalence between `M₁` and `M₂` that commutes with the quadratic forms. -/
@[nolint has_nonempty_instance]
structure Isometry (Q₁ : QuadraticForm R M₁) (Q₂ : QuadraticForm R M₂) extends M₁ ≃ₗ[R] M₂ where
  map_app' : ∀ m, Q₂ (to_fun m) = Q₁ m

/-- Two quadratic forms over a ring `R` are equivalent
if there exists an isometry between them:
a linear equivalence that transforms one quadratic form into the other. -/
def Equivalent (Q₁ : QuadraticForm R M₁) (Q₂ : QuadraticForm R M₂) :=
  Nonempty (Q₁.Isometry Q₂)

namespace Isometry

variable {Q₁ : QuadraticForm R M₁} {Q₂ : QuadraticForm R M₂} {Q₃ : QuadraticForm R M₃}

instance : Coe (Q₁.Isometry Q₂) (M₁ ≃ₗ[R] M₂) :=
  ⟨Isometry.toLinearEquiv⟩

@[simp]
theorem to_linear_equiv_eq_coe (f : Q₁.Isometry Q₂) : f.toLinearEquiv = f :=
  rfl

instance : CoeFun (Q₁.Isometry Q₂) fun _ => M₁ → M₂ :=
  ⟨fun f => ⇑(f : M₁ ≃ₗ[R] M₂)⟩

@[simp]
theorem coe_to_linear_equiv (f : Q₁.Isometry Q₂) : ⇑(f : M₁ ≃ₗ[R] M₂) = f :=
  rfl

@[simp]
theorem map_app (f : Q₁.Isometry Q₂) (m : M₁) : Q₂ (f m) = Q₁ m :=
  f.map_app' m

/-- The identity isometry from a quadratic form to itself. -/
@[refl]
def refl (Q : QuadraticForm R M) : Q.Isometry Q :=
  { LinearEquiv.refl R M with map_app' := fun m => rfl }

/-- The inverse isometry of an isometry between two quadratic forms. -/
@[symm]
def symm (f : Q₁.Isometry Q₂) : Q₂.Isometry Q₁ :=
  { (f : M₁ ≃ₗ[R] M₂).symm with
    map_app' := by
      intro m
      rw [← f.map_app]
      congr
      exact f.to_linear_equiv.apply_symm_apply m }

/-- The composition of two isometries between quadratic forms. -/
@[trans]
def trans (f : Q₁.Isometry Q₂) (g : Q₂.Isometry Q₃) : Q₁.Isometry Q₃ :=
  { (f : M₁ ≃ₗ[R] M₂).trans (g : M₂ ≃ₗ[R] M₃) with
    map_app' := by
      intro m
      rw [← f.map_app, ← g.map_app]
      rfl }

end Isometry

namespace Equivalent

variable {Q₁ : QuadraticForm R M₁} {Q₂ : QuadraticForm R M₂} {Q₃ : QuadraticForm R M₃}

@[refl]
theorem refl (Q : QuadraticForm R M) : Q.Equivalent Q :=
  ⟨Isometry.refl Q⟩

@[symm]
theorem symm (h : Q₁.Equivalent Q₂) : Q₂.Equivalent Q₁ :=
  h.elim fun f => ⟨f.symm⟩

@[trans]
theorem trans (h : Q₁.Equivalent Q₂) (h' : Q₂.Equivalent Q₃) : Q₁.Equivalent Q₃ :=
  h'.elim <| h.elim fun f g => ⟨f.trans g⟩

end Equivalent

variable [Fintype ι] {v : Basis ι R M}

/-- A quadratic form composed with a `linear_equiv` is isometric to itself. -/
def isometryOfCompLinearEquiv (Q : QuadraticForm R M) (f : M₁ ≃ₗ[R] M) : Q.Isometry (Q.comp (f : M₁ →ₗ[R] M)) :=
  { f.symm with
    map_app' := by
      intro
      simp only [comp_apply, LinearEquiv.coe_coe, LinearEquiv.to_fun_eq_coe, LinearEquiv.apply_symm_apply,
        f.apply_symm_apply] }

/-- A quadratic form is isometric to its bases representations. -/
noncomputable def isometryBasisRepr (Q : QuadraticForm R M) (v : Basis ι R M) : Isometry Q (Q.basis_repr v) :=
  isometryOfCompLinearEquiv Q v.equivFun.symm

variable [Field K] [Invertible (2 : K)] [AddCommGroupₓ V] [Module K V]

/-- Given an orthogonal basis, a quadratic form is isometric with a weighted sum of squares. -/
noncomputable def isometryWeightedSumSquares (Q : QuadraticForm K V)
    (v : Basis (Finₓ (FiniteDimensional.finrank K V)) K V) (hv₁ : (associated Q).IsOrtho v) :
    Q.Isometry (weightedSumSquares K fun i => Q (v i)) := by
  let iso := Q.isometry_basis_repr v
  refine' ⟨iso, fun m => _⟩
  convert iso.map_app m
  rw [basis_repr_eq_of_is_Ortho _ _ hv₁]

variable [FiniteDimensional K V]

open BilinForm

theorem equivalent_weighted_sum_squares (Q : QuadraticForm K V) :
    ∃ w : Finₓ (FiniteDimensional.finrank K V) → K, Equivalent Q (weightedSumSquares K w) :=
  let ⟨v, hv₁⟩ := exists_orthogonal_basis (associated_is_symm _ Q)
  ⟨_, ⟨Q.isometryWeightedSumSquares v hv₁⟩⟩

theorem equivalent_weighted_sum_squares_units_of_nondegenerate' (Q : QuadraticForm K V)
    (hQ : (associated Q).Nondegenerate) :
    ∃ w : Finₓ (FiniteDimensional.finrank K V) → Kˣ, Equivalent Q (weightedSumSquares K w) := by
  obtain ⟨v, hv₁⟩ := exists_orthogonal_basis (associated_is_symm _ Q)
  have hv₂ := hv₁.not_is_ortho_basis_self_of_nondegenerate hQ
  simp_rw [is_ortho, associated_eq_self_apply] at hv₂
  exact ⟨fun i => Units.mk0 _ (hv₂ i), ⟨Q.isometry_weighted_sum_squares v hv₁⟩⟩

end QuadraticForm

