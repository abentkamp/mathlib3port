/-
Copyright (c) 2017 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Reid Barton
-/
import Mathbin.CategoryTheory.Functor.FullyFaithful

/-!
# Induced categories and full subcategories

Given a category `D` and a function `F : C → D `from a type `C` to the
objects of `D`, there is an essentially unique way to give `C` a
category structure such that `F` becomes a fully faithful functor,
namely by taking $$ Hom_C(X, Y) = Hom_D(FX, FY) $$. We call this the
category induced from `D` along `F`.

As a special case, if `C` is a subtype of `D`,
this produces the full subcategory of `D` on the objects belonging to `C`.
In general the induced category is equivalent to the full subcategory of `D` on the
image of `F`.

## Implementation notes

It looks odd to make `D` an explicit argument of `induced_category`,
when it is determined by the argument `F` anyways. The reason to make `D`
explicit is in order to control its syntactic form, so that instances
like `induced_category.has_forget₂` (elsewhere) refer to the correct
form of D. This is used to set up several algebraic categories like

  def CommMon : Type (u+1) := induced_category Mon (bundled.map @comm_monoid.to_monoid)
  -- not `induced_category (bundled monoid) (bundled.map @comm_monoid.to_monoid)`,
  -- even though `Mon = bundled monoid`!
-/


namespace CategoryTheory

universe v v₂ u₁ u₂

-- morphism levels before object levels. See note [category_theory universes].
section Induced

variable {C : Type u₁} (D : Type u₂) [Category.{v} D]

variable (F : C → D)

include F

/-- `induced_category D F`, where `F : C → D`, is a typeclass synonym for `C`,
which provides a category structure so that the morphisms `X ⟶ Y` are the morphisms
in `D` from `F X` to `F Y`.
-/
@[nolint has_nonempty_instance unused_arguments]
def InducedCategory : Type u₁ :=
  C

variable {D}

instance InducedCategory.hasCoeToSort {α : Sort _} [CoeSort D α] : CoeSort (InducedCategory D F) α :=
  ⟨fun c => ↥(F c)⟩

instance InducedCategory.category : Category.{v} (InducedCategory D F) where
  Hom := fun X Y => F X ⟶ F Y
  id := fun X => 𝟙 (F X)
  comp := fun _ _ _ f g => f ≫ g

/-- The forgetful functor from an induced category to the original category,
forgetting the extra data.
-/
@[simps]
def inducedFunctor : InducedCategory D F ⥤ D where
  obj := F
  map := fun x y f => f

instance InducedCategory.full : Full (inducedFunctor F) where preimage := fun x y f => f

instance InducedCategory.faithful : Faithful (inducedFunctor F) where

end Induced

section FullSubcategory

-- A full subcategory is the special case of an induced category with F = subtype.val.
variable {C : Type u₁} [Category.{v} C]

variable (Z : C → Prop)

/-- A subtype-like structure for full subcategories. Morphisms just ignore the property. We don't use
actual subtypes since the simp-normal form `↑X` of `X.val` does not work well for full
subcategories.

See <https://stacks.math.columbia.edu/tag/001D>. We do not define 'strictly full' subcategories.
-/
@[ext, nolint has_nonempty_instance]
structure FullSubcategory where
  obj : C
  property : Z obj

instance FullSubcategory.category : Category.{v} (FullSubcategory Z) :=
  InducedCategory.category FullSubcategory.obj

/-- The forgetful functor from a full subcategory into the original category
("forgetting" the condition).
-/
def fullSubcategoryInclusion : FullSubcategory Z ⥤ C :=
  inducedFunctor FullSubcategory.obj

@[simp]
theorem fullSubcategoryInclusion.obj {X} : (fullSubcategoryInclusion Z).obj X = X.obj :=
  rfl

@[simp]
theorem fullSubcategoryInclusion.map {X Y} {f : X ⟶ Y} : (fullSubcategoryInclusion Z).map f = f :=
  rfl

instance FullSubcategory.full : Full (fullSubcategoryInclusion Z) :=
  InducedCategory.full _

instance FullSubcategory.faithful : Faithful (fullSubcategoryInclusion Z) :=
  InducedCategory.faithful _

variable {Z} {Z' : C → Prop}

/-- An implication of predicates `Z → Z'` induces a functor between full subcategories. -/
@[simps]
def FullSubcategory.map (h : ∀ ⦃X⦄, Z X → Z' X) : FullSubcategory Z ⥤ FullSubcategory Z' where
  obj := fun X => ⟨X.1, h X.2⟩
  map := fun X Y f => f

instance (h : ∀ ⦃X⦄, Z X → Z' X) : Full (FullSubcategory.map h) where preimage := fun X Y f => f

instance (h : ∀ ⦃X⦄, Z X → Z' X) : Faithful (FullSubcategory.map h) where

@[simp]
theorem FullSubcategory.map_inclusion (h : ∀ ⦃X⦄, Z X → Z' X) :
    FullSubcategory.map h ⋙ fullSubcategoryInclusion Z' = fullSubcategoryInclusion Z :=
  rfl

section lift

variable {D : Type u₂} [Category.{v₂} D] (P Q : D → Prop)

/-- A functor which maps objects to objects satisfying a certain property induces a lift through
    the full subcategory of objects satisfying that property. -/
@[simps]
def FullSubcategory.lift (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) : C ⥤ FullSubcategory P where
  obj := fun X => ⟨F.obj X, hF X⟩
  map := fun X Y f => F.map f

/-- Composing the lift of a functor through a full subcategory with the inclusion yields the
    original functor. Unfortunately, this is not true by definition, so we only get a natural
    isomorphism, but it is pointwise definitionally true, see
    `full_subcategory.inclusion_obj_lift_obj` and `full_subcategory.inclusion_map_lift_map`. -/
def FullSubcategory.liftCompInclusion (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) :
    FullSubcategory.lift P F hF ⋙ fullSubcategoryInclusion P ≅ F :=
  NatIso.ofComponents (fun X => Iso.refl _)
    (by
      simp )

@[simp]
theorem FullSubcategory.inclusion_obj_lift_obj (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) {X : C} :
    (fullSubcategoryInclusion P).obj ((FullSubcategory.lift P F hF).obj X) = F.obj X :=
  rfl

theorem FullSubcategory.inclusion_map_lift_map (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) {X Y : C} (f : X ⟶ Y) :
    (fullSubcategoryInclusion P).map ((FullSubcategory.lift P F hF).map f) = F.map f :=
  rfl

instance (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) [Faithful F] : Faithful (FullSubcategory.lift P F hF) :=
  Faithful.of_comp_iso (FullSubcategory.liftCompInclusion P F hF)

instance (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) [Full F] : Full (FullSubcategory.lift P F hF) :=
  Full.ofCompFaithfulIso (FullSubcategory.liftCompInclusion P F hF)

@[simp]
theorem FullSubcategory.lift_comp_map (F : C ⥤ D) (hF : ∀ X, P (F.obj X)) (h : ∀ ⦃X⦄, P X → Q X) :
    FullSubcategory.lift P F hF ⋙ FullSubcategory.map h = FullSubcategory.lift Q F fun X => h (hF X) :=
  rfl

end lift

end FullSubcategory

end CategoryTheory

