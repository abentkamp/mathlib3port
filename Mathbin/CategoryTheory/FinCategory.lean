import Mathbin.Data.Fintype.Basic
import Mathbin.CategoryTheory.DiscreteCategory
import Mathbin.CategoryTheory.Opposites

/-!
# Finite categories

A category is finite in this sense if it has finitely many objects, and finitely many morphisms.

## Implementation

We also ask for decidable equality of objects and morphisms, but it may be reasonable to just
go classical in future.
-/


universe v u

namespace CategoryTheory

instance discrete_fintype {α : Type _} [Fintype α] : Fintype (Discrete α) := by
  dsimp [discrete]
  infer_instance

instance discrete_hom_fintype {α : Type _} [DecidableEq α] (X Y : Discrete α) : Fintype (X ⟶ Y) := by
  apply Ulift.fintype

/-- A category with a `fintype` of objects, and a `fintype` for each morphism space. -/
class fin_category (J : Type v) [SmallCategory J] where
  decidableEqObj : DecidableEq J := by
    run_tac
      tactic.apply_instance
  fintypeObj : Fintype J := by
    run_tac
      tactic.apply_instance
  decidableEqHom : ∀ j j' : J, DecidableEq (j ⟶ j') := by
    run_tac
      tactic.apply_instance
  fintypeHom : ∀ j j' : J, Fintype (j ⟶ j') := by
    run_tac
      tactic.apply_instance

attribute [instance]
  fin_category.decidable_eq_obj fin_category.fintype_obj fin_category.decidable_eq_hom fin_category.fintype_hom

instance fin_category_discrete_of_decidable_fintype (J : Type v) [DecidableEq J] [Fintype J] :
    FinCategory (Discrete J) :=
  {  }

namespace FinCategory

variable (α : Type _) [Fintype α] [SmallCategory α] [FinCategory α]

/-- A fin_category `α` is equivalent to a category with objects in `Type`. -/
@[nolint unused_arguments]
abbrev obj_as_type : Type :=
  InducedCategory α (Fintype.equivFin α).symm

/-- The constructed category is indeed equivalent to `α`. -/
noncomputable def obj_as_type_equiv : ObjAsType α ≌ α :=
  (inducedFunctor (Fintype.equivFin α).symm).asEquivalence

/-- A fin_category `α` is equivalent to a fin_category with in `Type`. -/
@[nolint unused_arguments]
abbrev as_type : Type :=
  Finₓ (Fintype.card α)

@[simps (config := lemmasOnly) hom id comp]
noncomputable instance category_as_type : SmallCategory (AsType α) where
  hom := fun i j => Finₓ (Fintype.card (@Quiver.Hom (ObjAsType α) _ i j))
  id := fun i => Fintype.equivFin _ (𝟙 i)
  comp := fun i j k f g => Fintype.equivFin _ ((Fintype.equivFin _).symm f ≫ (Fintype.equivFin _).symm g)

attribute [local simp] category_as_type_hom category_as_type_id category_as_type_comp

/-- The constructed category (`as_type α`) is equivalent to `obj_as_type α`. -/
noncomputable def obj_as_type_equiv_as_type : AsType α ≌ ObjAsType α where
  Functor :=
    { obj := id, map := fun i j f => (Fintype.equivFin _).symm f,
      map_comp' := fun _ _ _ _ _ => by
        dsimp
        simp }
  inverse :=
    { obj := id, map := fun i j f => Fintype.equivFin _ f,
      map_comp' := fun _ _ _ _ _ => by
        dsimp
        simp }
  unitIso :=
    NatIso.ofComponents Iso.refl fun _ _ _ => by
      dsimp
      simp
  counitIso :=
    NatIso.ofComponents Iso.refl fun _ _ _ => by
      dsimp
      simp

noncomputable instance as_type_fin_category : FinCategory (AsType α) :=
  {  }

/-- The constructed category (`as_type α`) is indeed equivalent to `α`. -/
noncomputable def equiv_as_type : AsType α ≌ α :=
  (objAsTypeEquivAsType α).trans (objAsTypeEquiv α)

end FinCategory

open Opposite

/-- The opposite of a finite category is finite.
-/
def fin_category_opposite {J : Type v} [SmallCategory J] [FinCategory J] : FinCategory (Jᵒᵖ) where
  decidableEqObj := Equivₓ.decidableEq equivToOpposite.symm
  fintypeObj := Fintype.ofEquiv _ equivToOpposite
  decidableEqHom := fun j j' => Equivₓ.decidableEq (opEquiv j j')
  fintypeHom := fun j j' => Fintype.ofEquiv _ (opEquiv j j').symm

end CategoryTheory

