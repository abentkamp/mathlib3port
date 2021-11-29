import Mathbin.CategoryTheory.Category.Basic 
import Mathbin.CategoryTheory.Equivalence 
import Mathbin.CategoryTheory.Filtered

/-!
# Basic API for ulift

This file contains a very basic API for working with the categorical
instance on `ulift C` where `C` is a type with a category instance.

1. `category_theory.ulift.up` is the functorial version of the usual `ulift.up`.
2. `category_theory.ulift.down` is the functorial version of the usual `ulift.down`.
3. `category_theory.ulift.equivalence` is the categorical equivalence between
  `C` and `ulift C`.

# ulift_hom

Given a type `C : Type u`, `ulift_hom.{w} C` is just an alias for `C`.
If we have `category.{v} C`, then `ulift_hom.{w} C` is endowed with a category instance
whose morphisms are obtained by applying `ulift.{w}` to the morphisms from `C`.

This is a category equivalent to `C`. The forward direction of the equivalence is `ulift_hom.up`,
the backward direction is `ulift_hom.donw` and the equivalence is `ulift_hom.equiv`.

# as_small

This file also contains a construction which takes a type `C : Type u` with a
category instance `category.{v} C` and makes a small category
`as_small.{w} C : Type (max w v u)` equivalent to `C`.

The forward direction of the equivalence, `C ⥤ as_small C`, is denoted `as_small.up`
and the backward direction is `as_small.down`. The equivalence itself is `as_small.equiv`.
-/


universe w₁ v₁ v₂ u₁ u₂

namespace CategoryTheory

variable {C : Type u₁} [category.{v₁} C]

/-- The functorial version of `ulift.up`. -/
@[simps]
def ulift.up_functor : C ⥤ Ulift.{u₂} C :=
  { obj := Ulift.up, map := fun X Y f => f }

/-- The functorial version of `ulift.down`. -/
@[simps]
def ulift.down_functor : Ulift.{u₂} C ⥤ C :=
  { obj := Ulift.down, map := fun X Y f => f }

/-- The categorical equivalence between `C` and `ulift C`. -/
@[simps]
def ulift.equivalence : C ≌ Ulift.{u₂} C :=
  { Functor := ulift.up_functor, inverse := ulift.down_functor, unitIso := { Hom := 𝟙 _, inv := 𝟙 _ },
    counitIso :=
      { Hom :=
          { app := fun X => 𝟙 _,
            naturality' :=
              fun X Y f =>
                by 
                  change f ≫ 𝟙 _ = 𝟙 _ ≫ f 
                  simp  },
        inv :=
          { app := fun X => 𝟙 _,
            naturality' :=
              fun X Y f =>
                by 
                  change f ≫ 𝟙 _ = 𝟙 _ ≫ f 
                  simp  },
        hom_inv_id' :=
          by 
            ext 
            change 𝟙 _ ≫ 𝟙 _ = 𝟙 _ 
            simp ,
        inv_hom_id' :=
          by 
            ext 
            change 𝟙 _ ≫ 𝟙 _ = 𝟙 _ 
            simp  },
    functor_unit_iso_comp' :=
      fun X =>
        by 
          change 𝟙 X ≫ 𝟙 X = 𝟙 X 
          simp  }

instance [is_filtered C] : is_filtered (Ulift.{u₂} C) :=
  is_filtered.of_equivalence ulift.equivalence

instance [is_cofiltered C] : is_cofiltered (Ulift.{u₂} C) :=
  is_cofiltered.of_equivalence ulift.equivalence

section UliftHom

/-- `ulift_hom.{w} C` is an alias for `C`, which is endowed with a category instance
  whose morphisms are obtained by applying `ulift.{w}` to the morphisms from `C`.
-/
def ulift_hom.{w, u} (C : Type u) :=
  C

instance {C} [Inhabited C] : Inhabited (ulift_hom C) :=
  ⟨(arbitraryₓ C : C)⟩

/-- The obvious function `ulift_hom C → C`. -/
def ulift_hom.obj_down {C} (A : ulift_hom C) : C :=
  A

/-- The obvious function `C → ulift_hom C`. -/
def ulift_hom.obj_up {C} (A : C) : ulift_hom C :=
  A

@[simp]
theorem obj_down_obj_up {C} (A : C) : (ulift_hom.obj_up A).objDown = A :=
  rfl

@[simp]
theorem obj_up_obj_down {C} (A : ulift_hom C) : ulift_hom.obj_up A.obj_down = A :=
  rfl

instance : category.{max v₂ v₁} (ulift_hom.{v₂} C) :=
  { Hom := fun A B => Ulift.{v₂}$ A.obj_down ⟶ B.obj_down, id := fun A => ⟨𝟙 _⟩,
    comp := fun A B C f g => ⟨f.down ≫ g.down⟩ }

/-- One half of the quivalence between `C` and `ulift_hom C`. -/
@[simps]
def ulift_hom.up : C ⥤ ulift_hom C :=
  { obj := ulift_hom.obj_up, map := fun X Y f => ⟨f⟩ }

/-- One half of the quivalence between `C` and `ulift_hom C`. -/
@[simps]
def ulift_hom.down : ulift_hom C ⥤ C :=
  { obj := ulift_hom.obj_down, map := fun X Y f => f.down }

/-- The equivalence between `C` and `ulift_hom C`. -/
def ulift_hom.equiv : C ≌ ulift_hom C :=
  { Functor := ulift_hom.up, inverse := ulift_hom.down,
    unitIso :=
      nat_iso.of_components (fun A => eq_to_iso rfl)
        (by 
          tidy),
    counitIso :=
      nat_iso.of_components (fun A => eq_to_iso rfl)
        (by 
          tidy) }

instance [is_filtered C] : is_filtered (ulift_hom C) :=
  is_filtered.of_equivalence ulift_hom.equiv

instance [is_cofiltered C] : is_cofiltered (ulift_hom C) :=
  is_cofiltered.of_equivalence ulift_hom.equiv

end UliftHom

/-- `as_small C` is a small category equivalent to `C`.
  More specifically, if `C : Type u` is endowed with `category.{v} C`, then
  `as_small.{w} C : Type (max w v u)` is endowed with an instance of a small category.

  The objects and morphisms of `as_small C` are defined by applying `ulift` to the
  objects and morphisms of `C`.

  Note: We require a category instance for this definition in order to have direct
  access to the universe level `v`.
-/
@[nolint unused_arguments]
def as_small.{w, v, u} (C : Type u) [category.{v} C] :=
  Ulift.{max w v} C

instance : small_category (as_small.{w₁} C) :=
  { Hom := fun X Y => Ulift.{max w₁ u₁}$ X.down ⟶ Y.down, id := fun X => ⟨𝟙 _⟩,
    comp := fun X Y Z f g => ⟨f.down ≫ g.down⟩ }

/-- One half of the equivalence between `C` and `as_small C`. -/
@[simps]
def as_small.up : C ⥤ as_small C :=
  { obj := fun X => ⟨X⟩, map := fun X Y f => ⟨f⟩ }

/-- One half of the equivalence between `C` and `as_small C`. -/
@[simps]
def as_small.down : as_small C ⥤ C :=
  { obj := fun X => X.down, map := fun X Y f => f.down }

/-- The equivalence between `C` and `as_small C`. -/
@[simps]
def as_small.equiv : C ≌ as_small C :=
  { Functor := as_small.up, inverse := as_small.down,
    unitIso :=
      nat_iso.of_components (fun X => eq_to_iso rfl)
        (by 
          tidy),
    counitIso :=
      nat_iso.of_components
        (fun X =>
          eq_to_iso$
            by 
              ext 
              rfl)
        (by 
          tidy) }

instance [Inhabited C] : Inhabited (as_small C) :=
  ⟨⟨arbitraryₓ _⟩⟩

instance [is_filtered C] : is_filtered (as_small C) :=
  is_filtered.of_equivalence as_small.equiv

instance [is_cofiltered C] : is_cofiltered (as_small C) :=
  is_cofiltered.of_equivalence as_small.equiv

/-- The equivalence between `C` and `ulift_hom (ulift C)`. -/
def ulift_hom_ulift_category.equiv.{v', u', v, u} (C : Type u) [category.{v} C] : C ≌ ulift_hom.{v'} (Ulift.{u'} C) :=
  ulift.equivalence.trans ulift_hom.equiv

end CategoryTheory

