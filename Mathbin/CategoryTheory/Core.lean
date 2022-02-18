import Mathbin.Control.EquivFunctor
import Mathbin.CategoryTheory.Groupoid
import Mathbin.CategoryTheory.Whiskering
import Mathbin.CategoryTheory.Types

/-!
# The core of a category

The core of a category `C` is the (non-full) subcategory of `C` consisting of all objects,
and all isomorphisms. We construct it as a `groupoid`.

`core.inclusion : core C ⥤ C` gives the faithful inclusion into the original category.

Any functor `F` from a groupoid `G` into `C` factors through `core C`,
but this is not functorial with respect to `F`.
-/


namespace CategoryTheory

universe v₁ v₂ u₁ u₂

/-- The core of a category C is the groupoid whose morphisms are all the
isomorphisms of C. -/
@[nolint has_inhabited_instance]
def core (C : Type u₁) :=
  C

variable {C : Type u₁} [Category.{v₁} C]

instance core_category : Groupoid.{v₁} (Core C) where
  Hom := fun X Y : C => X ≅ Y
  inv := fun X Y f => Iso.symm f
  id := fun X => Iso.refl X
  comp := fun X Y Z f g => Iso.trans f g

namespace Core

@[simp]
theorem id_hom (X : Core C) : Iso.hom (𝟙 X) = 𝟙 X :=
  rfl

@[simp]
theorem comp_hom {X Y Z : Core C} (f : X ⟶ Y) (g : Y ⟶ Z) : (f ≫ g).Hom = f.Hom ≫ g.Hom :=
  rfl

variable (C)

/-- The core of a category is naturally included in the category. -/
def inclusion : Core C ⥤ C where
  obj := id
  map := fun X Y f => f.Hom

instance : Faithful (inclusion C) :=
  {  }

variable {C} {G : Type u₂} [Groupoid.{v₂} G]

/-- A functor from a groupoid to a category C factors through the core of C. -/
noncomputable def functor_to_core (F : G ⥤ C) : G ⥤ Core C where
  obj := fun X => F.obj X
  map := fun X Y f => ⟨F.map f, F.map (inv f)⟩

/-- We can functorially associate to any functor from a groupoid to the core of a category `C`,
a functor from the groupoid to `C`, simply by composing with the embedding `core C ⥤ C`.
-/
def forget_functor_to_core : (G ⥤ Core C) ⥤ G ⥤ C :=
  (whiskeringRight _ _ _).obj (inclusion C)

end Core

/-- `of_equiv_functor m` lifts a type-level `equiv_functor`
to a categorical functor `core (Type u₁) ⥤ core (Type u₂)`.
-/
def of_equiv_functor (m : Type u₁ → Type u₂) [EquivFunctor m] : Core (Type u₁) ⥤ Core (Type u₂) where
  obj := m
  map := fun α β f => (EquivFunctor.mapEquiv m f.toEquiv).toIso
  map_id' := fun α => by
    ext
    exact congr_funₓ (EquivFunctor.map_refl _) x
  map_comp' := fun α β γ f g => by
    ext
    simp only [EquivFunctor.map_equiv_apply, Equivₓ.to_iso_hom, Function.comp_app, core.comp_hom, types_comp]
    erw [iso.to_equiv_comp, EquivFunctor.map_trans]

end CategoryTheory

