/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau
-/
import Mathbin.Algebra.DirectSum.Basic
import Mathbin.LinearAlgebra.Dfinsupp

/-!
# Direct sum of modules

The first part of the file provides constructors for direct sums of modules. It provides a
construction of the direct sum using the universal property and proves its uniqueness
(`direct_sum.to_module.unique`).

The second part of the file covers the special case of direct sums of submodules of a fixed module
`M`.  There is a canonical linear map from this direct sum to `M`, and the construction is
of particular importance when this linear map is an equivalence; that is, when the submodules
provide an internal decomposition of `M`.  The property is defined as
`direct_sum.submodule_is_internal`, and its basic consequences are established.

-/


universe u v w u₁

namespace DirectSum

open_locale DirectSum

section General

variable {R : Type u} [Semiringₓ R]

variable {ι : Type v} [dec_ι : DecidableEq ι]

include R

variable {M : ι → Type w} [∀ i, AddCommMonoidₓ (M i)] [∀ i, Module R (M i)]

instance : Module R (⨁ i, M i) :=
  Dfinsupp.module

instance {S : Type _} [Semiringₓ S] [∀ i, Module S (M i)] [∀ i, SmulCommClass R S (M i)] :
    SmulCommClass R S (⨁ i, M i) :=
  Dfinsupp.smul_comm_class

instance {S : Type _} [Semiringₓ S] [HasScalar R S] [∀ i, Module S (M i)] [∀ i, IsScalarTower R S (M i)] :
    IsScalarTower R S (⨁ i, M i) :=
  Dfinsupp.is_scalar_tower

instance [∀ i, Module Rᵐᵒᵖ (M i)] [∀ i, IsCentralScalar R (M i)] : IsCentralScalar R (⨁ i, M i) :=
  Dfinsupp.is_central_scalar

theorem smul_apply (b : R) (v : ⨁ i, M i) (i : ι) : (b • v) i = b • v i :=
  Dfinsupp.smul_apply _ _ _

include dec_ι

variable (R ι M)

/-- Create the direct sum given a family `M` of `R` modules indexed over `ι`. -/
def lmk : ∀ s : Finset ι, (∀ i : (↑s : Set ι), M i.val) →ₗ[R] ⨁ i, M i :=
  Dfinsupp.lmk

/-- Inclusion of each component into the direct sum. -/
def lof : ∀ i : ι, M i →ₗ[R] ⨁ i, M i :=
  Dfinsupp.lsingle

theorem lof_eq_of (i : ι) (b : M i) : lof R ι M i b = of M i b :=
  rfl

variable {ι M}

theorem single_eq_lof (i : ι) (b : M i) : Dfinsupp.single i b = lof R ι M i b :=
  rfl

/-- Scalar multiplication commutes with direct sums. -/
theorem mk_smul (s : Finset ι) (c : R) x : mk M s (c • x) = c • mk M s x :=
  (lmk R ι M s).map_smul c x

/-- Scalar multiplication commutes with the inclusion of each component into the direct sum. -/
theorem of_smul (i : ι) (c : R) x : of M i (c • x) = c • of M i x :=
  (lof R ι M i).map_smul c x

variable {R}

theorem support_smul [∀ i : ι x : M i, Decidable (x ≠ 0)] (c : R) (v : ⨁ i, M i) : (c • v).support ⊆ v.support :=
  Dfinsupp.support_smul _ _

variable {N : Type u₁} [AddCommMonoidₓ N] [Module R N]

variable (φ : ∀ i, M i →ₗ[R] N)

variable (R ι N φ)

/-- The linear map constructed using the universal property of the coproduct. -/
def toModule : (⨁ i, M i) →ₗ[R] N :=
  Dfinsupp.lsum ℕ φ

/-- Coproducts in the categories of modules and additive monoids commute with the forgetful functor
from modules to additive monoids. -/
theorem coe_to_module_eq_coe_to_add_monoid :
    (toModule R ι N φ : (⨁ i, M i) → N) = toAddMonoid fun i => (φ i).toAddMonoidHom :=
  rfl

variable {ι N φ}

/-- The map constructed using the universal property gives back the original maps when
restricted to each component. -/
@[simp]
theorem to_module_lof i (x : M i) : toModule R ι N φ (lof R ι M i x) = φ i x :=
  to_add_monoid_of (fun i => (φ i).toAddMonoidHom) i x

variable (ψ : (⨁ i, M i) →ₗ[R] N)

/-- Every linear map from a direct sum agrees with the one obtained by applying
the universal property to each of its components. -/
theorem toModule.unique (f : ⨁ i, M i) : ψ f = toModule R ι N (fun i => ψ.comp <| lof R ι M i) f :=
  toAddMonoid.unique ψ.toAddMonoidHom f

variable {ψ} {ψ' : (⨁ i, M i) →ₗ[R] N}

/-- Two `linear_map`s out of a direct sum are equal if they agree on the generators.

See note [partially-applied ext lemmas]. -/
@[ext]
theorem linear_map_ext ⦃ψ ψ' : (⨁ i, M i) →ₗ[R] N⦄ (H : ∀ i, ψ.comp (lof R ι M i) = ψ'.comp (lof R ι M i)) : ψ = ψ' :=
  Dfinsupp.lhom_ext' H

/-- The inclusion of a subset of the direct summands
into a larger subset of the direct summands, as a linear map.
-/
def lsetToSet (S T : Set ι) (H : S ⊆ T) : (⨁ i : S, M i) →ₗ[R] ⨁ i : T, M i :=
  (toModule R _ _) fun i => lof R T (fun i : Subtype T => M i) ⟨i, H i.Prop⟩

omit dec_ι

variable (ι M)

/-- Given `fintype α`, `linear_equiv_fun_on_fintype R` is the natural `R`-linear equivalence
between `⨁ i, M i` and `Π i, M i`. -/
@[simps apply]
def linearEquivFunOnFintype [Fintype ι] : (⨁ i, M i) ≃ₗ[R] ∀ i, M i :=
  { Dfinsupp.equivFunOnFintype with toFun := coeFn,
    map_add' := fun f g => by
      ext
      simp only [add_apply, Pi.add_apply],
    map_smul' := fun c f => by
      ext
      simp only [Dfinsupp.coe_smul, RingHom.id_apply] }

variable {ι M}

@[simp]
theorem linear_equiv_fun_on_fintype_lof [Fintype ι] [DecidableEq ι] (i : ι) (m : M i) :
    (linearEquivFunOnFintype R ι M) (lof R ι M i m) = Pi.single i m := by
  ext a
  change (Dfinsupp.equivFunOnFintype (lof R ι M i m)) a = _
  convert _root_.congr_fun (Dfinsupp.equiv_fun_on_fintype_single i m) a

@[simp]
theorem linear_equiv_fun_on_fintype_symm_single [Fintype ι] [DecidableEq ι] (i : ι) (m : M i) :
    (linearEquivFunOnFintype R ι M).symm (Pi.single i m) = lof R ι M i m := by
  ext a
  change (dfinsupp.equiv_fun_on_fintype.symm (Pi.single i m)) a = _
  rw [Dfinsupp.equiv_fun_on_fintype_symm_single i m]
  rfl

@[simp]
theorem linear_equiv_fun_on_fintype_symm_coe [Fintype ι] (f : ⨁ i, M i) : (linearEquivFunOnFintype R ι M).symm f = f :=
  by
  ext
  simp [linear_equiv_fun_on_fintype]

/-- The natural linear equivalence between `⨁ _ : ι, M` and `M` when `unique ι`. -/
protected def lid (M : Type v) (ι : Type _ := PUnit) [AddCommMonoidₓ M] [Module R M] [Unique ι] :
    (⨁ _ : ι, M) ≃ₗ[R] M :=
  { DirectSum.id M ι, toModule R ι M fun i => LinearMap.id with }

variable (ι M)

/-- The projection map onto one component, as a linear map. -/
def component (i : ι) : (⨁ i, M i) →ₗ[R] M i :=
  Dfinsupp.lapply i

variable {ι M}

theorem apply_eq_component (f : ⨁ i, M i) (i : ι) : f i = component R ι M i f :=
  rfl

@[ext]
theorem ext {f g : ⨁ i, M i} (h : ∀ i, component R ι M i f = component R ι M i g) : f = g :=
  Dfinsupp.ext h

theorem ext_iff {f g : ⨁ i, M i} : f = g ↔ ∀ i, component R ι M i f = component R ι M i g :=
  ⟨fun h _ => by
    rw [h], ext R⟩

include dec_ι

@[simp]
theorem lof_apply (i : ι) (b : M i) : ((lof R ι M i) b) i = b :=
  Dfinsupp.single_eq_same

@[simp]
theorem component.lof_self (i : ι) (b : M i) : component R ι M i ((lof R ι M i) b) = b :=
  lof_apply R i b

theorem component.of (i j : ι) (b : M j) :
    component R ι M i ((lof R ι M j) b) = if h : j = i then Eq.recOnₓ h b else 0 :=
  Dfinsupp.single_apply

end General

section Submodule

section Semiringₓ

variable {R : Type u} [Semiringₓ R]

variable {ι : Type v} [dec_ι : DecidableEq ι]

include dec_ι

variable {M : Type _} [AddCommMonoidₓ M] [Module R M]

variable (A : ι → Submodule R M)

/-- The canonical embedding from `⨁ i, A i` to `M`  where `A` is a collection of `submodule R M`
indexed by `ι`-/
def submoduleCoe : (⨁ i, A i) →ₗ[R] M :=
  toModule R ι M fun i => (A i).Subtype

@[simp]
theorem submodule_coe_of (i : ι) (x : A i) : submoduleCoe A (of (fun i => A i) i x) = x :=
  to_add_monoid_of _ _ _

theorem coe_of_submodule_apply (i j : ι) (x : A i) : (DirectSum.of _ i x j : M) = if i = j then x else 0 := by
  obtain rfl | h := Decidable.eq_or_ne i j
  · rw [DirectSum.of_eq_same, if_pos rfl]
    
  · rw [DirectSum.of_eq_of_ne _ _ _ _ h, if_neg h, Submodule.coe_zero]
    

/-- The `direct_sum` formed by a collection of `submodule`s of `M` is said to be internal if the
canonical map `(⨁ i, A i) →ₗ[R] M` is bijective.

For the alternate statement in terms of independence and spanning, see
`direct_sum.submodule_is_internal_iff_independent_and_supr_eq_top`. -/
def SubmoduleIsInternal : Prop :=
  Function.Bijective (submoduleCoe A)

theorem SubmoduleIsInternal.to_add_submonoid :
    SubmoduleIsInternal A ↔ AddSubmonoidIsInternal fun i => (A i).toAddSubmonoid :=
  Iff.rfl

variable {A}

/-- If a direct sum of submodules is internal then the submodules span the module. -/
theorem SubmoduleIsInternal.supr_eq_top (h : SubmoduleIsInternal A) : supr A = ⊤ := by
  rw [Submodule.supr_eq_range_dfinsupp_lsum, LinearMap.range_eq_top]
  exact Function.Bijective.surjective h

/-- If a direct sum of submodules is internal then the submodules are independent. -/
theorem SubmoduleIsInternal.independent (h : SubmoduleIsInternal A) : CompleteLattice.Independent A :=
  CompleteLattice.independent_of_dfinsupp_lsum_injective _ h.Injective

/-- Given an internal direct sum decomposition of a module `M`, and a basis for each of the
components of the direct sum, the disjoint union of these bases is a basis for `M`. -/
noncomputable def SubmoduleIsInternal.collectedBasis (h : SubmoduleIsInternal A) {α : ι → Type _}
    (v : ∀ i, Basis (α i) R (A i)) : Basis (Σ i, α i) R M where
  repr :=
    ((LinearEquiv.ofBijective _ h.Injective h.Surjective).symm ≪≫ₗ
        Dfinsupp.mapRange.linearEquiv fun i => (v i).repr) ≪≫ₗ
      (sigmaFinsuppLequivDfinsupp R).symm

@[simp]
theorem SubmoduleIsInternal.collected_basis_coe (h : SubmoduleIsInternal A) {α : ι → Type _}
    (v : ∀ i, Basis (α i) R (A i)) : ⇑h.collectedBasis v = fun a : Σ i, α i => ↑(v a.1 a.2) := by
  funext a
  simp only [submodule_is_internal.collected_basis, to_module, submodule_coe, AddEquiv.to_fun_eq_coe, Basis.coe_of_repr,
    Basis.repr_symm_apply, Dfinsupp.lsum_apply_apply, Dfinsupp.mapRange.linear_equiv_apply,
    Dfinsupp.mapRange.linear_equiv_symm, Dfinsupp.map_range_single, Finsupp.total_single,
    LinearEquiv.of_bijective_apply, LinearEquiv.symm_symm, LinearEquiv.symm_trans_apply, one_smul,
    sigma_finsupp_add_equiv_dfinsupp_apply, sigma_finsupp_equiv_dfinsupp_single, sigma_finsupp_lequiv_dfinsupp_apply]
  convert Dfinsupp.sum_add_hom_single (fun i => (A i).Subtype.toAddMonoidHom) a.1 (v a.1 a.2)

theorem SubmoduleIsInternal.collected_basis_mem (h : SubmoduleIsInternal A) {α : ι → Type _}
    (v : ∀ i, Basis (α i) R (A i)) (a : Σ i, α i) : h.collectedBasis v a ∈ A a.1 := by
  simp

end Semiringₓ

section Ringₓ

variable {R : Type u} [Ringₓ R]

variable {ι : Type v} [dec_ι : DecidableEq ι]

include dec_ι

variable {M : Type _} [AddCommGroupₓ M] [Module R M]

theorem SubmoduleIsInternal.to_add_subgroup (A : ι → Submodule R M) :
    SubmoduleIsInternal A ↔ AddSubgroupIsInternal fun i => (A i).toAddSubgroup :=
  Iff.rfl

/-- Note that this is not generally true for `[semiring R]`; see
`complete_lattice.independent.dfinsupp_lsum_injective` for details. -/
theorem submodule_is_internal_of_independent_of_supr_eq_top {A : ι → Submodule R M} (hi : CompleteLattice.Independent A)
    (hs : supr A = ⊤) : SubmoduleIsInternal A :=
  ⟨hi.dfinsupp_lsum_injective, LinearMap.range_eq_top.1 <| (Submodule.supr_eq_range_dfinsupp_lsum _).symm.trans hs⟩

/-- `iff` version of `direct_sum.submodule_is_internal_of_independent_of_supr_eq_top`,
`direct_sum.submodule_is_internal.independent`, and `direct_sum.submodule_is_internal.supr_eq_top`.
-/
theorem submodule_is_internal_iff_independent_and_supr_eq_top (A : ι → Submodule R M) :
    SubmoduleIsInternal A ↔ CompleteLattice.Independent A ∧ supr A = ⊤ :=
  ⟨fun i => ⟨i.Independent, i.supr_eq_top⟩, And.ndrec submodule_is_internal_of_independent_of_supr_eq_top⟩

/-! Now copy the lemmas for subgroup and submonoids. -/


theorem AddSubmonoidIsInternal.independent {M : Type _} [AddCommMonoidₓ M] {A : ι → AddSubmonoid M}
    (h : AddSubmonoidIsInternal A) : CompleteLattice.Independent A :=
  CompleteLattice.independent_of_dfinsupp_sum_add_hom_injective _ h.Injective

theorem AddSubgroupIsInternal.independent {M : Type _} [AddCommGroupₓ M] {A : ι → AddSubgroup M}
    (h : AddSubgroupIsInternal A) : CompleteLattice.Independent A :=
  CompleteLattice.independent_of_dfinsupp_sum_add_hom_injective' _ h.Injective

end Ringₓ

end Submodule

end DirectSum

