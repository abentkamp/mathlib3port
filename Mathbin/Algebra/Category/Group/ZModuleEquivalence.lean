import Mathbin.Algebra.Category.Module.Basic

/-!
The forgetful functor from ℤ-modules to additive commutative groups is
an equivalence of categories.

TODO:
either use this equivalence to transport the monoidal structure from `Module ℤ` to `Ab`,
or, having constructed that monoidal structure directly, show this functor is monoidal.
-/


open CategoryTheory

open CategoryTheory.Equivalence

universe u

namespace ModuleCat

/-- The forgetful functor from `ℤ` modules to `AddCommGroup` is full. -/
instance forget₂_AddCommGroup_full : Full (forget₂ (ModuleCat ℤ) AddCommGroupₓₓ.{u}) where
  Preimage := fun A B f =>
    { toFun := f, map_add' := AddMonoidHom.map_add f,
      map_smul' := fun n x => by
        simp [int_smul_eq_zsmul] }

/-- The forgetful functor from `ℤ` modules to `AddCommGroup` is essentially surjective. -/
instance forget₂_AddCommGroup_ess_surj : EssSurj (forget₂ (ModuleCat ℤ) AddCommGroupₓₓ.{u}) where
  mem_ess_image := fun A => ⟨ModuleCat.of ℤ A, ⟨{ Hom := 𝟙 A, inv := 𝟙 A }⟩⟩

noncomputable instance forget₂_AddCommGroup_is_equivalence : IsEquivalence (forget₂ (ModuleCat ℤ) AddCommGroupₓₓ.{u}) :=
  Equivalence.ofFullyFaithfullyEssSurj (forget₂ (ModuleCat ℤ) AddCommGroupₓₓ)

end ModuleCat

