/-
Copyright (c) 2017 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Stephen Morgan, Scott Morrison, Floris van Doorn
-/
import Mathbin.CategoryTheory.Functor.Const
import Mathbin.CategoryTheory.DiscreteCategory
import Mathbin.CategoryTheory.Yoneda
import Mathbin.CategoryTheory.Functor.ReflectsIsomorphisms

/-!
# Cones and cocones

We define `cone F`, a cone over a functor `F`,
and `F.cones : Cᵒᵖ ⥤ Type`, the functor associating to `X` the cones over `F` with cone point `X`.

A cone `c` is defined by specifying its cone point `c.X` and a natural transformation `c.π`
from the constant `c.X` valued functor to `F`.

We provide `c.w f : c.π.app j ≫ F.map f = c.π.app j'` for any `f : j ⟶ j'`
as a wrapper for `c.π.naturality f` avoiding unneeded identity morphisms.

We define `c.extend f`, where `c : cone F` and `f : Y ⟶ c.X` for some other `Y`,
which replaces the cone point by `Y` and inserts `f` into each of the components of the cone.
Similarly we have `c.whisker F` producing a `cone (E ⋙ F)`

We define morphisms of cones, and the category of cones.

We define `cone.postcompose α : cone F ⥤ cone G` for `α` a natural transformation `F ⟶ G`.

And, of course, we dualise all this to cocones as well.

For more results about the category of cones, see `cone_category.lean`.
-/


-- morphism levels before object levels. See note [category_theory universes].
universe v₁ v₂ v₃ v₄ u₁ u₂ u₃ u₄

open CategoryTheory

variable {J : Type u₁} [Category.{v₁} J]

variable {K : Type u₂} [Category.{v₂} K]

variable {C : Type u₃} [Category.{v₃} C]

variable {D : Type u₄} [Category.{v₄} D]

open CategoryTheory

open CategoryTheory.Category

open CategoryTheory.Functor

open Opposite

namespace CategoryTheory

namespace Functor

variable {J C} (F : J ⥤ C)

/-- `F.cones` is the functor assigning to an object `X` the type of
natural transformations from the constant functor with value `X` to `F`.
An object representing this functor is a limit of `F`.
-/
@[simps]
def cones : Cᵒᵖ ⥤ Type max u₁ v₃ :=
  (const J).op ⋙ yoneda.obj F

/-- `F.cocones` is the functor assigning to an object `X` the type of
natural transformations from `F` to the constant functor with value `X`.
An object corepresenting this functor is a colimit of `F`.
-/
@[simps]
def cocones : C ⥤ Type max u₁ v₃ :=
  const J ⋙ coyoneda.obj (op F)

end Functor

section

variable (J C)

/-- Functorially associated to each functor `J ⥤ C`, we have the `C`-presheaf consisting of
cones with a given cone point.
-/
@[simps]
def cones : (J ⥤ C) ⥤ Cᵒᵖ ⥤ Type max u₁ v₃ where
  obj := Functor.cones
  map := fun F G f => whiskerLeft (const J).op (yoneda.map f)

/-- Contravariantly associated to each functor `J ⥤ C`, we have the `C`-copresheaf consisting of
cocones with a given cocone point.
-/
@[simps]
def cocones : (J ⥤ C)ᵒᵖ ⥤ C ⥤ Type max u₁ v₃ where
  obj := fun F => Functor.cocones (unop F)
  map := fun F G f => whiskerLeft (const J) (coyoneda.map f)

end

namespace Limits

section

attribute [local tidy] tactic.discrete_cases

/-- A `c : cone F` is:
* an object `c.X` and
* a natural transformation `c.π : c.X ⟶ F` from the constant `c.X` functor to `F`.

`cone F` is equivalent, via `cone.equiv` below, to `Σ X, F.cones.obj X`.
-/
structure Cone (F : J ⥤ C) where
  x : C
  π : (const J).obj X ⟶ F

instance inhabitedCone (F : Discrete PUnit ⥤ C) : Inhabited (Cone F) :=
  ⟨{ x := F.obj ⟨⟨⟩⟩, π := { app := fun ⟨⟨⟩⟩ => 𝟙 _ } }⟩

@[simp, reassoc]
theorem Cone.w {F : J ⥤ C} (c : Cone F) {j j' : J} (f : j ⟶ j') : c.π.app j ≫ F.map f = c.π.app j' := by
  rw [← c.π.naturality f]
  apply id_comp

/-- A `c : cocone F` is
* an object `c.X` and
* a natural transformation `c.ι : F ⟶ c.X` from `F` to the constant `c.X` functor.

`cocone F` is equivalent, via `cone.equiv` below, to `Σ X, F.cocones.obj X`.
-/
structure Cocone (F : J ⥤ C) where
  x : C
  ι : F ⟶ (const J).obj X

instance inhabitedCocone (F : Discrete PUnit ⥤ C) : Inhabited (Cocone F) :=
  ⟨{ x := F.obj ⟨⟨⟩⟩, ι := { app := fun ⟨⟨⟩⟩ => 𝟙 _ } }⟩

@[simp, reassoc]
theorem Cocone.w {F : J ⥤ C} (c : Cocone F) {j j' : J} (f : j ⟶ j') : F.map f ≫ c.ι.app j' = c.ι.app j := by
  rw [c.ι.naturality f]
  apply comp_id

end

variable {F : J ⥤ C}

namespace Cone

/-- The isomorphism between a cone on `F` and an element of the functor `F.cones`. -/
@[simps]
def equiv (F : J ⥤ C) : Cone F ≅ ΣX, F.cones.obj X where
  Hom := fun c => ⟨op c.x, c.π⟩
  inv := fun c => { x := c.1.unop, π := c.2 }
  hom_inv_id' := by
    ext1
    cases x
    rfl
  inv_hom_id' := by
    ext1
    cases x
    rfl

/-- A map to the vertex of a cone naturally induces a cone by composition. -/
@[simps]
def extensions (c : Cone F) :
    yoneda.obj c.x ⋙ ulift_functor.{u₁} ⟶ F.cones where app := fun X f => (const J).map f.down ≫ c.π

/-- A map to the vertex of a cone induces a cone by composition. -/
@[simps]
def extend (c : Cone F) {X : C} (f : X ⟶ c.x) : Cone F :=
  { x, π := c.extensions.app (op X) ⟨f⟩ }

/-- Whisker a cone by precomposition of a functor. -/
@[simps]
def whisker (E : K ⥤ J) (c : Cone F) : Cone (E ⋙ F) where
  x := c.x
  π := whiskerLeft E c.π

end Cone

namespace Cocone

/-- The isomorphism between a cocone on `F` and an element of the functor `F.cocones`. -/
def equiv (F : J ⥤ C) : Cocone F ≅ ΣX, F.cocones.obj X where
  Hom := fun c => ⟨c.x, c.ι⟩
  inv := fun c => { x := c.1, ι := c.2 }
  hom_inv_id' := by
    ext1
    cases x
    rfl
  inv_hom_id' := by
    ext1
    cases x
    rfl

/-- A map from the vertex of a cocone naturally induces a cocone by composition. -/
@[simps]
def extensions (c : Cocone F) :
    coyoneda.obj (op c.x) ⋙ ulift_functor.{u₁} ⟶ F.cocones where app := fun X f => c.ι ≫ (const J).map f.down

/-- A map from the vertex of a cocone induces a cocone by composition. -/
@[simps]
def extend (c : Cocone F) {X : C} (f : c.x ⟶ X) : Cocone F :=
  { x, ι := c.extensions.app X ⟨f⟩ }

/-- Whisker a cocone by precomposition of a functor. See `whiskering` for a functorial
version.
-/
@[simps]
def whisker (E : K ⥤ J) (c : Cocone F) : Cocone (E ⋙ F) where
  x := c.x
  ι := whiskerLeft E c.ι

end Cocone

/-- A cone morphism between two cones for the same diagram is a morphism of the cone points which
commutes with the cone legs. -/
@[ext]
structure ConeMorphism (A B : Cone F) where
  Hom : A.x ⟶ B.x
  w' : ∀ j : J, hom ≫ B.π.app j = A.π.app j := by
    run_tac
      obviously

restate_axiom cone_morphism.w'

attribute [simp, reassoc] cone_morphism.w

instance inhabitedConeMorphism (A : Cone F) : Inhabited (ConeMorphism A A) :=
  ⟨{ Hom := 𝟙 _ }⟩

/-- The category of cones on a given diagram. -/
@[simps]
instance Cone.category : Category (Cone F) where
  Hom := fun A B => ConeMorphism A B
  comp := fun X Y Z f g => { Hom := f.Hom ≫ g.Hom }
  id := fun B => { Hom := 𝟙 B.x }

namespace Cones

/-- To give an isomorphism between cones, it suffices to give an
  isomorphism between their vertices which commutes with the cone
  maps. -/
@[ext, simps]
def ext {c c' : Cone F} (φ : c.x ≅ c'.x) (w : ∀ j, c.π.app j = φ.Hom ≫ c'.π.app j) : c ≅ c' where
  Hom := { Hom := φ.Hom }
  inv := { Hom := φ.inv, w' := fun j => φ.inv_comp_eq.mpr (w j) }

/-- Eta rule for cones. -/
@[simps]
def eta (c : Cone F) : c ≅ ⟨c.x, c.π⟩ :=
  Cones.ext (Iso.refl _)
    (by
      tidy)

/-- Given a cone morphism whose object part is an isomorphism, produce an
isomorphism of cones.
-/
theorem cone_iso_of_hom_iso {K : J ⥤ C} {c d : Cone K} (f : c ⟶ d) [i : IsIso f.Hom] : IsIso f :=
  ⟨⟨{ Hom := inv f.Hom, w' := fun j => (asIso f.Hom).inv_comp_eq.2 (f.w j).symm }, by
      tidy⟩⟩

/-- Functorially postcompose a cone for `F` by a natural transformation `F ⟶ G` to give a cone for `G`.
-/
@[simps]
def postcompose {G : J ⥤ C} (α : F ⟶ G) : Cone F ⥤ Cone G where
  obj := fun c => { x := c.x, π := c.π ≫ α }
  map := fun c₁ c₂ f => { Hom := f.Hom }

/-- Postcomposing a cone by the composite natural transformation `α ≫ β` is the same as
postcomposing by `α` and then by `β`. -/
@[simps]
def postcomposeComp {G H : J ⥤ C} (α : F ⟶ G) (β : G ⟶ H) : postcompose (α ≫ β) ≅ postcompose α ⋙ postcompose β :=
  NatIso.ofComponents
    (fun s =>
      Cones.ext (Iso.refl _)
        (by
          tidy))
    (by
      tidy)

/-- Postcomposing by the identity does not change the cone up to isomorphism. -/
@[simps]
def postcomposeId : postcompose (𝟙 F) ≅ 𝟭 (Cone F) :=
  NatIso.ofComponents
    (fun s =>
      Cones.ext (Iso.refl _)
        (by
          tidy))
    (by
      tidy)

/-- If `F` and `G` are naturally isomorphic functors, then they have equivalent categories of
cones.
-/
@[simps]
def postcomposeEquivalence {G : J ⥤ C} (α : F ≅ G) : Cone F ≌ Cone G where
  Functor := postcompose α.Hom
  inverse := postcompose α.inv
  unitIso :=
    NatIso.ofComponents
      (fun s =>
        Cones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)
  counitIso :=
    NatIso.ofComponents
      (fun s =>
        Cones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)

/-- Whiskering on the left by `E : K ⥤ J` gives a functor from `cone F` to `cone (E ⋙ F)`.
-/
@[simps]
def whiskering (E : K ⥤ J) : Cone F ⥤ Cone (E ⋙ F) where
  obj := fun c => c.whisker E
  map := fun c c' f => { Hom := f.Hom }

/-- Whiskering by an equivalence gives an equivalence between categories of cones.
-/
@[simps]
def whiskeringEquivalence (e : K ≌ J) : Cone F ≌ Cone (e.Functor ⋙ F) where
  Functor := whiskering e.Functor
  inverse := whiskering e.inverse ⋙ postcompose (e.invFunIdAssoc F).Hom
  unitIso :=
    NatIso.ofComponents
      (fun s =>
        Cones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)
  counitIso :=
    NatIso.ofComponents
      (fun s =>
        Cones.ext (Iso.refl _)
          (by
            intro k
            dsimp'
            -- See library note [dsimp, simp]
            simpa [e.counit_app_functor] using s.w (e.unit_inv.app k)))
      (by
        tidy)

/-- The categories of cones over `F` and `G` are equivalent if `F` and `G` are naturally isomorphic
(possibly after changing the indexing category by an equivalence).
-/
@[simps Functor inverse unitIso counitIso]
def equivalenceOfReindexing {G : K ⥤ C} (e : K ≌ J) (α : e.Functor ⋙ F ≅ G) : Cone F ≌ Cone G :=
  (whiskeringEquivalence e).trans (postcomposeEquivalence α)

section

variable (F)

/-- Forget the cone structure and obtain just the cone point. -/
@[simps]
def forget : Cone F ⥤ C where
  obj := fun t => t.x
  map := fun s t f => f.Hom

variable (G : C ⥤ D)

/-- A functor `G : C ⥤ D` sends cones over `F` to cones over `F ⋙ G` functorially. -/
@[simps]
def functoriality : Cone F ⥤ Cone (F ⋙ G) where
  obj := fun A =>
    { x := G.obj A.x,
      π :=
        { app := fun j => G.map (A.π.app j),
          naturality' := by
            intros <;> erw [← G.map_comp] <;> tidy } }
  map := fun X Y f =>
    { Hom := G.map f.Hom,
      w' := fun j => by
        simp [-cone_morphism.w, ← f.w j] }

instance functorialityFull [Full G] [Faithful G] :
    Full
      (functoriality F G) where preimage := fun X Y t =>
    { Hom := G.preimage t.Hom,
      w' := fun j =>
        G.map_injective
          (by
            simpa using t.w j) }

instance functoriality_faithful [Faithful G] :
    Faithful (Cones.functoriality F G) where map_injective' := fun X Y f g e => by
    ext1
    injection e
    apply G.map_injective h_1

/-- If `e : C ≌ D` is an equivalence of categories, then `functoriality F e.functor` induces an
equivalence between cones over `F` and cones over `F ⋙ e.functor`.
-/
@[simps]
def functorialityEquivalence (e : C ≌ D) : Cone F ≌ Cone (F ⋙ e.Functor) :=
  let f : (F ⋙ e.Functor) ⋙ e.inverse ≅ F :=
    Functor.associator _ _ _ ≪≫ isoWhiskerLeft _ e.unitIso.symm ≪≫ Functor.rightUnitor _
  { Functor := functoriality F e.Functor,
    inverse := functoriality (F ⋙ e.Functor) e.inverse ⋙ (postcomposeEquivalence f).Functor,
    unitIso :=
      NatIso.ofComponents
        (fun c =>
          Cones.ext (e.unitIso.app _)
            (by
              tidy))
        (by
          tidy),
    counitIso :=
      NatIso.ofComponents
        (fun c =>
          Cones.ext (e.counitIso.app _)
            (by
              tidy))
        (by
          tidy) }

/-- If `F` reflects isomorphisms, then `cones.functoriality F` reflects isomorphisms
as well.
-/
instance reflects_cone_isomorphism (F : C ⥤ D) [ReflectsIsomorphisms F] (K : J ⥤ C) :
    ReflectsIsomorphisms (Cones.functoriality K F) := by
  constructor
  intros
  haveI : is_iso (F.map f.hom) := (cones.forget (K ⋙ F)).map_is_iso ((cones.functoriality K F).map f)
  haveI := reflects_isomorphisms.reflects F f.hom
  apply cone_iso_of_hom_iso

end

end Cones

/-- A cocone morphism between two cocones for the same diagram is a morphism of the cocone points
which commutes with the cocone legs. -/
@[ext]
structure CoconeMorphism (A B : Cocone F) where
  Hom : A.x ⟶ B.x
  w' : ∀ j : J, A.ι.app j ≫ hom = B.ι.app j := by
    run_tac
      obviously

instance inhabitedCoconeMorphism (A : Cocone F) : Inhabited (CoconeMorphism A A) :=
  ⟨{ Hom := 𝟙 _ }⟩

restate_axiom cocone_morphism.w'

attribute [simp, reassoc] cocone_morphism.w

@[simps]
instance Cocone.category : Category (Cocone F) where
  Hom := fun A B => CoconeMorphism A B
  comp := fun _ _ _ f g => { Hom := f.Hom ≫ g.Hom }
  id := fun B => { Hom := 𝟙 B.x }

namespace Cocones

/-- To give an isomorphism between cocones, it suffices to give an
  isomorphism between their vertices which commutes with the cocone
  maps. -/
@[ext, simps]
def ext {c c' : Cocone F} (φ : c.x ≅ c'.x) (w : ∀ j, c.ι.app j ≫ φ.Hom = c'.ι.app j) : c ≅ c' where
  Hom := { Hom := φ.Hom }
  inv := { Hom := φ.inv, w' := fun j => φ.comp_inv_eq.mpr (w j).symm }

/-- Eta rule for cocones. -/
@[simps]
def eta (c : Cocone F) : c ≅ ⟨c.x, c.ι⟩ :=
  Cocones.ext (Iso.refl _)
    (by
      tidy)

/-- Given a cocone morphism whose object part is an isomorphism, produce an
isomorphism of cocones.
-/
theorem cocone_iso_of_hom_iso {K : J ⥤ C} {c d : Cocone K} (f : c ⟶ d) [i : IsIso f.Hom] : IsIso f :=
  ⟨⟨{ Hom := inv f.Hom, w' := fun j => (asIso f.Hom).comp_inv_eq.2 (f.w j).symm }, by
      tidy⟩⟩

/-- Functorially precompose a cocone for `F` by a natural transformation `G ⟶ F` to give a cocone
for `G`. -/
@[simps]
def precompose {G : J ⥤ C} (α : G ⟶ F) : Cocone F ⥤ Cocone G where
  obj := fun c => { x := c.x, ι := α ≫ c.ι }
  map := fun c₁ c₂ f => { Hom := f.Hom }

/-- Precomposing a cocone by the composite natural transformation `α ≫ β` is the same as
precomposing by `β` and then by `α`. -/
def precomposeComp {G H : J ⥤ C} (α : F ⟶ G) (β : G ⟶ H) : precompose (α ≫ β) ≅ precompose β ⋙ precompose α :=
  NatIso.ofComponents
    (fun s =>
      Cocones.ext (Iso.refl _)
        (by
          tidy))
    (by
      tidy)

/-- Precomposing by the identity does not change the cocone up to isomorphism. -/
def precomposeId : precompose (𝟙 F) ≅ 𝟭 (Cocone F) :=
  NatIso.ofComponents
    (fun s =>
      Cocones.ext (Iso.refl _)
        (by
          tidy))
    (by
      tidy)

/-- If `F` and `G` are naturally isomorphic functors, then they have equivalent categories of
cocones.
-/
@[simps]
def precomposeEquivalence {G : J ⥤ C} (α : G ≅ F) : Cocone F ≌ Cocone G where
  Functor := precompose α.Hom
  inverse := precompose α.inv
  unitIso :=
    NatIso.ofComponents
      (fun s =>
        Cocones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)
  counitIso :=
    NatIso.ofComponents
      (fun s =>
        Cocones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)

/-- Whiskering on the left by `E : K ⥤ J` gives a functor from `cocone F` to `cocone (E ⋙ F)`.
-/
@[simps]
def whiskering (E : K ⥤ J) : Cocone F ⥤ Cocone (E ⋙ F) where
  obj := fun c => c.whisker E
  map := fun c c' f => { Hom := f.Hom }

/-- Whiskering by an equivalence gives an equivalence between categories of cones.
-/
@[simps]
def whiskeringEquivalence (e : K ≌ J) : Cocone F ≌ Cocone (e.Functor ⋙ F) where
  Functor := whiskering e.Functor
  inverse :=
    whiskering e.inverse ⋙
      precompose ((Functor.leftUnitor F).inv ≫ whiskerRight e.counitIso.inv F ≫ (Functor.associator _ _ _).inv)
  unitIso :=
    NatIso.ofComponents
      (fun s =>
        Cocones.ext (Iso.refl _)
          (by
            tidy))
      (by
        tidy)
  counitIso :=
    NatIso.ofComponents
      (fun s =>
        Cocones.ext (Iso.refl _)
          (by
            intro k
            dsimp'
            simpa [e.counit_inv_app_functor k] using s.w (e.unit.app k)))
      (by
        tidy)

/-- The categories of cocones over `F` and `G` are equivalent if `F` and `G` are naturally isomorphic
(possibly after changing the indexing category by an equivalence).
-/
@[simps functor_obj]
def equivalenceOfReindexing {G : K ⥤ C} (e : K ≌ J) (α : e.Functor ⋙ F ≅ G) : Cocone F ≌ Cocone G :=
  (whiskeringEquivalence e).trans (precomposeEquivalence α.symm)

section

variable (F)

/-- Forget the cocone structure and obtain just the cocone point. -/
@[simps]
def forget : Cocone F ⥤ C where
  obj := fun t => t.x
  map := fun s t f => f.Hom

variable (G : C ⥤ D)

/-- A functor `G : C ⥤ D` sends cocones over `F` to cocones over `F ⋙ G` functorially. -/
@[simps]
def functoriality : Cocone F ⥤ Cocone (F ⋙ G) where
  obj := fun A =>
    { x := G.obj A.x,
      ι :=
        { app := fun j => G.map (A.ι.app j),
          naturality' := by
            intros <;> erw [← G.map_comp] <;> tidy } }
  map := fun _ _ f =>
    { Hom := G.map f.Hom,
      w' := by
        intros <;> rw [← functor.map_comp, cocone_morphism.w] }

instance functorialityFull [Full G] [Faithful G] :
    Full
      (functoriality F G) where preimage := fun X Y t =>
    { Hom := G.preimage t.Hom,
      w' := fun j =>
        G.map_injective
          (by
            simpa using t.w j) }

instance functoriality_faithful [Faithful G] :
    Faithful (functoriality F G) where map_injective' := fun X Y f g e => by
    ext1
    injection e
    apply G.map_injective h_1

/-- If `e : C ≌ D` is an equivalence of categories, then `functoriality F e.functor` induces an
equivalence between cocones over `F` and cocones over `F ⋙ e.functor`.
-/
@[simps]
def functorialityEquivalence (e : C ≌ D) : Cocone F ≌ Cocone (F ⋙ e.Functor) :=
  let f : (F ⋙ e.Functor) ⋙ e.inverse ≅ F :=
    Functor.associator _ _ _ ≪≫ isoWhiskerLeft _ e.unitIso.symm ≪≫ Functor.rightUnitor _
  { Functor := functoriality F e.Functor,
    inverse := functoriality (F ⋙ e.Functor) e.inverse ⋙ (precomposeEquivalence f.symm).Functor,
    unitIso :=
      NatIso.ofComponents
        (fun c =>
          Cocones.ext (e.unitIso.app _)
            (by
              tidy))
        (by
          tidy),
    counitIso :=
      NatIso.ofComponents
        (fun c =>
          Cocones.ext (e.counitIso.app _)
            (by
              -- Unfortunately this doesn't work by `tidy`.
              -- In this configuration `simp` reaches a dead-end and needs help.
              intro j
              dsimp'
              simp only [← equivalence.counit_inv_app_functor, iso.inv_hom_id_app, map_comp, equivalence.fun_inv_map,
                assoc, id_comp, iso.inv_hom_id_app_assoc]
              dsimp'
              simp ))-- See note [dsimp, simp].
      fun c c' f => by
        ext
        dsimp'
        simp
        dsimp'
        simp }

/-- If `F` reflects isomorphisms, then `cocones.functoriality F` reflects isomorphisms
as well.
-/
instance reflects_cocone_isomorphism (F : C ⥤ D) [ReflectsIsomorphisms F] (K : J ⥤ C) :
    ReflectsIsomorphisms (Cocones.functoriality K F) := by
  constructor
  intros
  haveI : is_iso (F.map f.hom) := (cocones.forget (K ⋙ F)).map_is_iso ((cocones.functoriality K F).map f)
  haveI := reflects_isomorphisms.reflects F f.hom
  apply cocone_iso_of_hom_iso

end

end Cocones

end Limits

namespace Functor

variable {F : J ⥤ C} {G : J ⥤ C} (H : C ⥤ D)

open CategoryTheory.Limits

/-- The image of a cone in C under a functor G : C ⥤ D is a cone in D. -/
@[simps]
def mapCone (c : Cone F) : Cone (F ⋙ H) :=
  (Cones.functoriality F H).obj c

/-- The image of a cocone in C under a functor G : C ⥤ D is a cocone in D. -/
@[simps]
def mapCocone (c : Cocone F) : Cocone (F ⋙ H) :=
  (Cocones.functoriality F H).obj c

/-- Given a cone morphism `c ⟶ c'`, construct a cone morphism on the mapped cones functorially.  -/
def mapConeMorphism {c c' : Cone F} (f : c ⟶ c') : H.mapCone c ⟶ H.mapCone c' :=
  (Cones.functoriality F H).map f

/-- Given a cocone morphism `c ⟶ c'`, construct a cocone morphism on the mapped cocones
functorially. -/
def mapCoconeMorphism {c c' : Cocone F} (f : c ⟶ c') : H.mapCocone c ⟶ H.mapCocone c' :=
  (Cocones.functoriality F H).map f

/-- If `H` is an equivalence, we invert `H.map_cone` and get a cone for `F` from a cone
for `F ⋙ H`.-/
def mapConeInv [IsEquivalence H] (c : Cone (F ⋙ H)) : Cone F :=
  (Limits.Cones.functorialityEquivalence F (asEquivalence H)).inverse.obj c

/-- `map_cone` is the left inverse to `map_cone_inv`. -/
def mapConeMapConeInv {F : J ⥤ D} (H : D ⥤ C) [IsEquivalence H] (c : Cone (F ⋙ H)) : mapCone H (mapConeInv H c) ≅ c :=
  (Limits.Cones.functorialityEquivalence F (asEquivalence H)).counitIso.app c

/-- `map_cone` is the right inverse to `map_cone_inv`. -/
def mapConeInvMapCone {F : J ⥤ D} (H : D ⥤ C) [IsEquivalence H] (c : Cone F) : mapConeInv H (mapCone H c) ≅ c :=
  (Limits.Cones.functorialityEquivalence F (asEquivalence H)).unitIso.symm.app c

/-- If `H` is an equivalence, we invert `H.map_cone` and get a cone for `F` from a cone
for `F ⋙ H`.-/
def mapCoconeInv [IsEquivalence H] (c : Cocone (F ⋙ H)) : Cocone F :=
  (Limits.Cocones.functorialityEquivalence F (asEquivalence H)).inverse.obj c

/-- `map_cocone` is the left inverse to `map_cocone_inv`. -/
def mapCoconeMapCoconeInv {F : J ⥤ D} (H : D ⥤ C) [IsEquivalence H] (c : Cocone (F ⋙ H)) :
    mapCocone H (mapCoconeInv H c) ≅ c :=
  (Limits.Cocones.functorialityEquivalence F (asEquivalence H)).counitIso.app c

/-- `map_cocone` is the right inverse to `map_cocone_inv`. -/
def mapCoconeInvMapCocone {F : J ⥤ D} (H : D ⥤ C) [IsEquivalence H] (c : Cocone F) :
    mapCoconeInv H (mapCocone H c) ≅ c :=
  (Limits.Cocones.functorialityEquivalence F (asEquivalence H)).unitIso.symm.app c

/-- `functoriality F _ ⋙ postcompose (whisker_left F _)` simplifies to `functoriality F _`. -/
@[simps]
def functorialityCompPostcompose {H H' : C ⥤ D} (α : H ≅ H') :
    Cones.functoriality F H ⋙ Cones.postcompose (whiskerLeft F α.Hom) ≅ Cones.functoriality F H' :=
  NatIso.ofComponents
    (fun c =>
      Cones.ext (α.app _)
        (by
          tidy))
    (by
      tidy)

/-- For `F : J ⥤ C`, given a cone `c : cone F`, and a natural isomorphism `α : H ≅ H'` for functors
`H H' : C ⥤ D`, the postcomposition of the cone `H.map_cone` using the isomorphism `α` is
isomorphic to the cone `H'.map_cone`.
-/
@[simps]
def postcomposeWhiskerLeftMapCone {H H' : C ⥤ D} (α : H ≅ H') (c : Cone F) :
    (Cones.postcompose (whiskerLeft F α.Hom : _)).obj (H.mapCone c) ≅ H'.mapCone c :=
  (functorialityCompPostcompose α).app c

/-- `map_cone` commutes with `postcompose`. In particular, for `F : J ⥤ C`, given a cone `c : cone F`, a
natural transformation `α : F ⟶ G` and a functor `H : C ⥤ D`, we have two obvious ways of producing
a cone over `G ⋙ H`, and they are both isomorphic.
-/
@[simps]
def mapConePostcompose {α : F ⟶ G} {c} :
    H.mapCone ((Cones.postcompose α).obj c) ≅ (Cones.postcompose (whiskerRight α H : _)).obj (H.mapCone c) :=
  Cones.ext (Iso.refl _)
    (by
      tidy)

/-- `map_cone` commutes with `postcompose_equivalence`
-/
@[simps]
def mapConePostcomposeEquivalenceFunctor {α : F ≅ G} {c} :
    H.mapCone ((Cones.postcomposeEquivalence α).Functor.obj c) ≅
      (Cones.postcomposeEquivalence (isoWhiskerRight α H : _)).Functor.obj (H.mapCone c) :=
  Cones.ext (Iso.refl _)
    (by
      tidy)

/-- `functoriality F _ ⋙ precompose (whisker_left F _)` simplifies to `functoriality F _`. -/
@[simps]
def functorialityCompPrecompose {H H' : C ⥤ D} (α : H ≅ H') :
    Cocones.functoriality F H ⋙ Cocones.precompose (whiskerLeft F α.inv) ≅ Cocones.functoriality F H' :=
  NatIso.ofComponents
    (fun c =>
      Cocones.ext (α.app _)
        (by
          tidy))
    (by
      tidy)

/-- For `F : J ⥤ C`, given a cocone `c : cocone F`, and a natural isomorphism `α : H ≅ H'` for functors
`H H' : C ⥤ D`, the precomposition of the cocone `H.map_cocone` using the isomorphism `α` is
isomorphic to the cocone `H'.map_cocone`.
-/
@[simps]
def precomposeWhiskerLeftMapCocone {H H' : C ⥤ D} (α : H ≅ H') (c : Cocone F) :
    (Cocones.precompose (whiskerLeft F α.inv : _)).obj (H.mapCocone c) ≅ H'.mapCocone c :=
  (functorialityCompPrecompose α).app c

/-- `map_cocone` commutes with `precompose`. In particular, for `F : J ⥤ C`, given a cocone
`c : cocone F`, a natural transformation `α : F ⟶ G` and a functor `H : C ⥤ D`, we have two obvious
ways of producing a cocone over `G ⋙ H`, and they are both isomorphic.
-/
@[simps]
def mapCoconePrecompose {α : F ⟶ G} {c} :
    H.mapCocone ((Cocones.precompose α).obj c) ≅ (Cocones.precompose (whiskerRight α H : _)).obj (H.mapCocone c) :=
  Cocones.ext (Iso.refl _)
    (by
      tidy)

/-- `map_cocone` commutes with `precompose_equivalence`
-/
@[simps]
def mapCoconePrecomposeEquivalenceFunctor {α : F ≅ G} {c} :
    H.mapCocone ((Cocones.precomposeEquivalence α).Functor.obj c) ≅
      (Cocones.precomposeEquivalence (isoWhiskerRight α H : _)).Functor.obj (H.mapCocone c) :=
  Cocones.ext (Iso.refl _)
    (by
      tidy)

/-- `map_cone` commutes with `whisker`
-/
@[simps]
def mapConeWhisker {E : K ⥤ J} {c : Cone F} : H.mapCone (c.whisker E) ≅ (H.mapCone c).whisker E :=
  Cones.ext (Iso.refl _)
    (by
      tidy)

/-- `map_cocone` commutes with `whisker`
-/
@[simps]
def mapCoconeWhisker {E : K ⥤ J} {c : Cocone F} : H.mapCocone (c.whisker E) ≅ (H.mapCocone c).whisker E :=
  Cocones.ext (Iso.refl _)
    (by
      tidy)

end Functor

end CategoryTheory

namespace CategoryTheory.Limits

section

variable {F : J ⥤ C}

/-- Change a `cocone F` into a `cone F.op`. -/
@[simps]
def Cocone.op (c : Cocone F) : Cone F.op where
  x := op c.x
  π := NatTrans.op c.ι

/-- Change a `cone F` into a `cocone F.op`. -/
@[simps]
def Cone.op (c : Cone F) : Cocone F.op where
  x := op c.x
  ι := NatTrans.op c.π

/-- Change a `cocone F.op` into a `cone F`. -/
@[simps]
def Cocone.unop (c : Cocone F.op) : Cone F where
  x := unop c.x
  π := NatTrans.removeOp c.ι

/-- Change a `cone F.op` into a `cocone F`. -/
@[simps]
def Cone.unop (c : Cone F.op) : Cocone F where
  x := unop c.x
  ι := NatTrans.removeOp c.π

variable (F)

/-- The category of cocones on `F`
is equivalent to the opposite category of
the category of cones on the opposite of `F`.
-/
def coconeEquivalenceOpConeOp : Cocone F ≌ (Cone F.op)ᵒᵖ where
  Functor :=
    { obj := fun c => op (Cocone.op c),
      map := fun X Y f =>
        Quiver.Hom.op
          { Hom := f.Hom.op,
            w' := fun j => by
              apply Quiver.Hom.unop_inj
              dsimp'
              apply cocone_morphism.w } }
  inverse :=
    { obj := fun c => Cone.unop (unop c),
      map := fun X Y f =>
        { Hom := f.unop.Hom.unop,
          w' := fun j => by
            apply Quiver.Hom.op_inj
            dsimp'
            apply cone_morphism.w } }
  unitIso :=
    NatIso.ofComponents
      (fun c =>
        Cocones.ext (Iso.refl _)
          (by
            dsimp'
            simp ))
      fun X Y f => by
      ext
      simp
  counitIso :=
    NatIso.ofComponents
      (fun c => by
        induction c using Opposite.rec
        dsimp'
        apply iso.op
        exact
          cones.ext (iso.refl _)
            (by
              dsimp'
              simp ))
      fun X Y f =>
      Quiver.Hom.unop_inj
        (ConeMorphism.ext _ _
          (by
            dsimp'
            simp ))
  functor_unit_iso_comp' := fun c => by
    apply Quiver.Hom.unop_inj
    ext
    dsimp'
    apply comp_id

attribute [simps] cocone_equivalence_op_cone_op

end

section

variable {F : J ⥤ Cᵒᵖ}

-- Here and below we only automatically generate the `@[simp]` lemma for the `X` field,
-- as we can write a simpler `rfl` lemma for the components of the natural transformation by hand.
/-- Change a cocone on `F.left_op : Jᵒᵖ ⥤ C` to a cocone on `F : J ⥤ Cᵒᵖ`. -/
@[simps (config := { rhsMd := semireducible, simpRhs := true })]
def coneOfCoconeLeftOp (c : Cocone F.leftOp) : Cone F where
  x := op c.x
  π := NatTrans.removeLeftOp c.ι

/-- Change a cone on `F : J ⥤ Cᵒᵖ` to a cocone on `F.left_op : Jᵒᵖ ⥤ C`. -/
@[simps (config := { rhsMd := semireducible, simpRhs := true })]
def coconeLeftOpOfCone (c : Cone F) : Cocone F.leftOp where
  x := unop c.x
  ι := NatTrans.leftOp c.π

/- When trying use `@[simps]` to generate the `ι_app` field of this definition, `@[simps]` tries to
  reduce the RHS using `expr.dsimp` and `expr.simp`, but for some reason the expression is not
  being simplified properly. -/
/-- Change a cone on `F.left_op : Jᵒᵖ ⥤ C` to a cocone on `F : J ⥤ Cᵒᵖ`. -/
@[simps x]
def coconeOfConeLeftOp (c : Cone F.leftOp) : Cocone F where
  x := op c.x
  ι := NatTrans.removeLeftOp c.π

@[simp]
theorem cocone_of_cone_left_op_ι_app (c : Cone F.leftOp) (j) : (coconeOfConeLeftOp c).ι.app j = (c.π.app (op j)).op :=
  by
  dsimp' only [cocone_of_cone_left_op]
  simp

/-- Change a cocone on `F : J ⥤ Cᵒᵖ` to a cone on `F.left_op : Jᵒᵖ ⥤ C`. -/
@[simps (config := { rhsMd := semireducible, simpRhs := true })]
def coneLeftOpOfCocone (c : Cocone F) : Cone F.leftOp where
  x := unop c.x
  π := NatTrans.leftOp c.ι

end

section

variable {F : Jᵒᵖ ⥤ C}

/-- Change a cocone on `F.right_op : J ⥤ Cᵒᵖ` to a cone on `F : Jᵒᵖ ⥤ C`. -/
@[simps]
def coneOfCoconeRightOp (c : Cocone F.rightOp) : Cone F where
  x := unop c.x
  π := NatTrans.removeRightOp c.ι

/-- Change a cone on `F : Jᵒᵖ ⥤ C` to a cocone on `F.right_op : Jᵒᵖ ⥤ C`. -/
@[simps]
def coconeRightOpOfCone (c : Cone F) : Cocone F.rightOp where
  x := op c.x
  ι := NatTrans.rightOp c.π

/-- Change a cone on `F.right_op : J ⥤ Cᵒᵖ` to a cocone on `F : Jᵒᵖ ⥤ C`. -/
@[simps]
def coconeOfConeRightOp (c : Cone F.rightOp) : Cocone F where
  x := unop c.x
  ι := NatTrans.removeRightOp c.π

/-- Change a cocone on `F : Jᵒᵖ ⥤ C` to a cone on `F.right_op : J ⥤ Cᵒᵖ`. -/
@[simps]
def coneRightOpOfCocone (c : Cocone F) : Cone F.rightOp where
  x := op c.x
  π := NatTrans.rightOp c.ι

end

section

variable {F : Jᵒᵖ ⥤ Cᵒᵖ}

/-- Change a cocone on `F.unop : J ⥤ C` into a cone on `F : Jᵒᵖ ⥤ Cᵒᵖ`. -/
@[simps]
def coneOfCoconeUnop (c : Cocone F.unop) : Cone F where
  x := op c.x
  π := NatTrans.removeUnop c.ι

/-- Change a cone on `F : Jᵒᵖ ⥤ Cᵒᵖ` into a cocone on `F.unop : J ⥤ C`. -/
@[simps]
def coconeUnopOfCone (c : Cone F) : Cocone F.unop where
  x := unop c.x
  ι := NatTrans.unop c.π

/-- Change a cone on `F.unop : J ⥤ C` into a cocone on `F : Jᵒᵖ ⥤ Cᵒᵖ`. -/
@[simps]
def coconeOfConeUnop (c : Cone F.unop) : Cocone F where
  x := op c.x
  ι := NatTrans.removeUnop c.π

/-- Change a cocone on `F : Jᵒᵖ ⥤ Cᵒᵖ` into a cone on `F.unop : J ⥤ C`. -/
@[simps]
def coneUnopOfCocone (c : Cocone F) : Cone F.unop where
  x := unop c.x
  π := NatTrans.unop c.ι

end

end CategoryTheory.Limits

namespace CategoryTheory.Functor

open CategoryTheory.Limits

variable {F : J ⥤ C}

section

variable (G : C ⥤ D)

/-- The opposite cocone of the image of a cone is the image of the opposite cocone. -/
@[simps (config := { rhsMd := semireducible })]
def mapConeOp (t : Cone F) : (G.mapCone t).op ≅ G.op.mapCocone t.op :=
  Cocones.ext (Iso.refl _)
    (by
      tidy)

/-- The opposite cone of the image of a cocone is the image of the opposite cone. -/
@[simps (config := { rhsMd := semireducible })]
def mapCoconeOp {t : Cocone F} : (G.mapCocone t).op ≅ G.op.mapCone t.op :=
  Cones.ext (Iso.refl _)
    (by
      tidy)

end

end CategoryTheory.Functor

