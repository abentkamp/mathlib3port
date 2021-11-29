import Mathbin.CategoryTheory.Category.Cat 
import Mathbin.CategoryTheory.Elements

/-!
# The Grothendieck construction

Given a functor `F : C ⥤ Cat`, the objects of `grothendieck F`
consist of dependent pairs `(b, f)`, where `b : C` and `f : F.obj c`,
and a morphism `(b, f) ⟶ (b', f')` is a pair `β : b ⟶ b'` in `C`, and
`φ : (F.map β).obj f ⟶ f'`

Categories such as `PresheafedSpace` are in fact examples of this construction,
and it may be interesting to try to generalize some of the development there.

## Implementation notes

Really we should treat `Cat` as a 2-category, and allow `F` to be a 2-functor.

There is also a closely related construction starting with `G : Cᵒᵖ ⥤ Cat`,
where morphisms consists again of `β : b ⟶ b'` and `φ : f ⟶ (F.map (op β)).obj f'`.

## References

See also `category_theory.functor.elements` for the category of elements of functor `F : C ⥤ Type`.

* https://stacks.math.columbia.edu/tag/02XV
* https://ncatlab.org/nlab/show/Grothendieck+construction

-/


universe u

namespace CategoryTheory

variable {C D : Type _} [category C] [category D]

variable (F : C ⥤ Cat)

/--
The Grothendieck construction (often written as `∫ F` in mathematics) for a functor `F : C ⥤ Cat`
gives a category whose
* objects `X` consist of `X.base : C` and `X.fiber : F.obj base`
* morphisms `f : X ⟶ Y` consist of
  `base : X.base ⟶ Y.base` and
  `f.fiber : (F.map base).obj X.fiber ⟶ Y.fiber`
-/
@[nolint has_inhabited_instance]
structure grothendieck where 
  base : C 
  fiber : F.obj base

namespace Grothendieck

variable {F}

/--
A morphism in the Grothendieck category `F : C ⥤ Cat` consists of
`base : X.base ⟶ Y.base` and `f.fiber : (F.map base).obj X.fiber ⟶ Y.fiber`.
-/
structure hom (X Y : grothendieck F) where 
  base : X.base ⟶ Y.base 
  fiber : (F.map base).obj X.fiber ⟶ Y.fiber

@[ext]
theorem ext {X Y : grothendieck F} (f g : hom X Y) (w_base : f.base = g.base)
  (w_fiber :
    eq_to_hom
          (by 
            rw [w_base]) ≫
        f.fiber =
      g.fiber) :
  f = g :=
  by 
    cases f <;> cases g 
    congr 
    dsimp  at w_base 
    induction w_base 
    rfl 
    dsimp  at w_base 
    induction w_base 
    simpa using w_fiber

/--
The identity morphism in the Grothendieck category.
-/
@[simps]
def id (X : grothendieck F) : hom X X :=
  { base := 𝟙 X.base,
    fiber :=
      eq_to_hom
        (by 
          erw [CategoryTheory.Functor.map_id, functor.id_obj X.fiber]) }

instance (X : grothendieck F) : Inhabited (hom X X) :=
  ⟨id X⟩

/--
Composition of morphisms in the Grothendieck category.
-/
@[simps]
def comp {X Y Z : grothendieck F} (f : hom X Y) (g : hom Y Z) : hom X Z :=
  { base := f.base ≫ g.base,
    fiber :=
      eq_to_hom
          (by 
            erw [functor.map_comp, functor.comp_obj]) ≫
        (F.map g.base).map f.fiber ≫ g.fiber }

instance : category (grothendieck F) :=
  { Hom := fun X Y => grothendieck.hom X Y, id := fun X => grothendieck.id X,
    comp := fun X Y Z f g => grothendieck.comp f g,
    comp_id' :=
      fun X Y f =>
        by 
          ext
          ·
            dsimp 
            rw [←nat_iso.naturality_2 (eq_to_iso (F.map_id Y.base)) f.fiber]
            simp 
            rfl
          ·
            simp ,
    id_comp' :=
      fun X Y f =>
        by 
          ext <;> simp ,
    assoc' :=
      fun W X Y Z f g h =>
        by 
          ext 
          swap
          ·
            simp 
          ·
            dsimp 
            rw [←nat_iso.naturality_2 (eq_to_iso (F.map_comp _ _)) f.fiber]
            simp 
            rfl }

@[simp]
theorem id_fiber' (X : grothendieck F) :
  hom.fiber (𝟙 X) =
    eq_to_hom
      (by 
        erw [CategoryTheory.Functor.map_id, functor.id_obj X.fiber]) :=
  id_fiber X

theorem congr {X Y : grothendieck F} {f g : X ⟶ Y} (h : f = g) :
  f.fiber =
    eq_to_hom
        (by 
          subst h) ≫
      g.fiber :=
  by 
    subst h 
    dsimp 
    simp 

section 

variable (F)

/-- The forgetful functor from `grothendieck F` to the source category. -/
@[simps]
def forget : grothendieck F ⥤ C :=
  { obj := fun X => X.1, map := fun X Y f => f.1 }

end 

universe w

variable (G : C ⥤ Type w)

/-- Auxiliary definition for `grothendieck_Type_to_Cat`, to speed up elaboration. -/
@[simps]
def grothendieck_Type_to_Cat_functor : grothendieck (G ⋙ Type_to_Cat) ⥤ G.elements :=
  { obj := fun X => ⟨X.1, X.2⟩, map := fun X Y f => ⟨f.1, f.2.1.1⟩ }

/-- Auxiliary definition for `grothendieck_Type_to_Cat`, to speed up elaboration. -/
@[simps]
def grothendieck_Type_to_Cat_inverse : G.elements ⥤ grothendieck (G ⋙ Type_to_Cat) :=
  { obj := fun X => ⟨X.1, X.2⟩, map := fun X Y f => ⟨f.1, ⟨⟨f.2⟩⟩⟩ }

/--
The Grothendieck construction applied to a functor to `Type`
(thought of as a functor to `Cat` by realising a type as a discrete category)
is the same as the 'category of elements' construction.
-/
@[simps]
def grothendieck_Type_to_Cat : grothendieck (G ⋙ Type_to_Cat) ≌ G.elements :=
  { Functor := grothendieck_Type_to_Cat_functor G, inverse := grothendieck_Type_to_Cat_inverse G,
    unitIso :=
      nat_iso.of_components
        (fun X =>
          by 
            cases X 
            exact iso.refl _)
        (by 
          rintro ⟨⟩ ⟨⟩ ⟨base, ⟨⟨f⟩⟩⟩
          dsimp  at *
          subst f 
          ext 
          simp ),
    counitIso :=
      nat_iso.of_components
        (fun X =>
          by 
            cases X 
            exact iso.refl _)
        (by 
          rintro ⟨⟩ ⟨⟩ ⟨f, e⟩
          dsimp  at *
          subst e 
          ext 
          simp ),
    functor_unit_iso_comp' :=
      by 
        rintro ⟨⟩
        dsimp 
        simp 
        rfl }

end Grothendieck

end CategoryTheory

