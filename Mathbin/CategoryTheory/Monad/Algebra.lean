import Mathbin.CategoryTheory.Monad.Basic 
import Mathbin.CategoryTheory.Adjunction.Basic 
import Mathbin.CategoryTheory.ReflectsIsomorphisms

/-!
# Eilenberg-Moore (co)algebras for a (co)monad

This file defines Eilenberg-Moore (co)algebras for a (co)monad,
and provides the category instance for them.

Further it defines the adjoint pair of free and forgetful functors, respectively
from and to the original category, as well as the adjoint pair of forgetful and
cofree functors, respectively from and to the original category.

## References
* [Riehl, *Category theory in context*, Section 5.2.4][riehl2017]
-/


namespace CategoryTheory

open Category

universe v₁ u₁

variable{C : Type u₁}[category.{v₁} C]

namespace Monadₓ

/-- An Eilenberg-Moore algebra for a monad `T`.
    cf Definition 5.2.3 in [Riehl][riehl2017]. -/
structure algebra(T : Monadₓ C) : Type max u₁ v₁ where 
  a : C 
  a : (T : C ⥤ C).obj A ⟶ A 
  unit' : T.η.app A ≫ a = 𝟙 A :=  by 
  runTac 
    obviously 
  assoc' : T.μ.app A ≫ a = (T : C ⥤ C).map a ≫ a :=  by 
  runTac 
    obviously

restate_axiom algebra.unit'

restate_axiom algebra.assoc'

attribute [reassoc] algebra.unit algebra.assoc

namespace Algebra

variable{T : Monadₓ C}

/-- A morphism of Eilenberg–Moore algebras for the monad `T`. -/
@[ext]
structure hom(A B : algebra T) where 
  f : A.A ⟶ B.A 
  h' : (T : C ⥤ C).map f ≫ B.a = A.a ≫ f :=  by 
  runTac 
    obviously

restate_axiom hom.h'

attribute [simp, reassoc] hom.h

namespace Hom

/-- The identity homomorphism for an Eilenberg–Moore algebra. -/
def id (A : algebra T) : hom A A :=
  { f := 𝟙 A.A }

instance  (A : algebra T) : Inhabited (hom A A) :=
  ⟨{ f := 𝟙 _ }⟩

/-- Composition of Eilenberg–Moore algebra homomorphisms. -/
def comp {P Q R : algebra T} (f : hom P Q) (g : hom Q R) : hom P R :=
  { f := f.f ≫ g.f }

end Hom

instance  : category_struct (algebra T) :=
  { Hom := hom, id := hom.id, comp := @hom.comp _ _ _ }

@[simp]
theorem comp_eq_comp {A A' A'' : algebra T} (f : A ⟶ A') (g : A' ⟶ A'') : algebra.hom.comp f g = f ≫ g :=
  rfl

@[simp]
theorem id_eq_id (A : algebra T) : algebra.hom.id A = 𝟙 A :=
  rfl

@[simp]
theorem id_f (A : algebra T) : (𝟙 A : A ⟶ A).f = 𝟙 A.A :=
  rfl

@[simp]
theorem comp_f {A A' A'' : algebra T} (f : A ⟶ A') (g : A' ⟶ A'') : (f ≫ g).f = f.f ≫ g.f :=
  rfl

/-- The category of Eilenberg-Moore algebras for a monad.
    cf Definition 5.2.4 in [Riehl][riehl2017]. -/
instance EilenbergMoore : category (algebra T) :=
  {  }

/--
To construct an isomorphism of algebras, it suffices to give an isomorphism of the carriers which
commutes with the structure morphisms.
-/
@[simps]
def iso_mk {A B : algebra T} (h : A.A ≅ B.A) (w : (T : C ⥤ C).map h.hom ≫ B.a = A.a ≫ h.hom) : A ≅ B :=
  { Hom := { f := h.hom },
    inv :=
      { f := h.inv,
        h' :=
          by 
            rw [h.eq_comp_inv, category.assoc, ←w, ←functor.map_comp_assoc]
            simp  } }

end Algebra

variable(T : Monadₓ C)

/-- The forgetful functor from the Eilenberg-Moore category, forgetting the algebraic structure. -/
@[simps]
def forget : algebra T ⥤ C :=
  { obj := fun A => A.A, map := fun A B f => f.f }

/-- The free functor from the Eilenberg-Moore category, constructing an algebra for any object. -/
@[simps]
def free : C ⥤ algebra T :=
  { obj := fun X => { a := T.obj X, a := T.μ.app X, assoc' := (T.assoc _).symm },
    map := fun X Y f => { f := T.map f, h' := T.μ.naturality _ } }

instance  [Inhabited C] : Inhabited (algebra T) :=
  ⟨(free T).obj (default C)⟩

/-- The adjunction between the free and forgetful constructions for Eilenberg-Moore algebras for
  a monad. cf Lemma 5.2.8 of [Riehl][riehl2017]. -/
@[simps Unit counit]
def adj : T.free ⊣ T.forget :=
  adjunction.mk_of_hom_equiv
    { homEquiv :=
        fun X Y =>
          { toFun := fun f => T.η.app X ≫ f.f,
            invFun :=
              fun f =>
                { f := T.map f ≫ Y.a,
                  h' :=
                    by 
                      dsimp 
                      simp [←Y.assoc, ←T.μ.naturality_assoc] },
            left_inv :=
              fun f =>
                by 
                  ext 
                  dsimp 
                  simp ,
            right_inv :=
              fun f =>
                by 
                  dsimp only [forget_obj, monad_to_functor_eq_coe]
                  rw [←T.η.naturality_assoc, Y.unit]
                  apply category.comp_id } }

/--
Given an algebra morphism whose carrier part is an isomorphism, we get an algebra isomorphism.
-/
theorem algebra_iso_of_iso {A B : algebra T} (f : A ⟶ B) [is_iso f.f] : is_iso f :=
  ⟨⟨{ f := inv f.f,
        h' :=
          by 
            rw [is_iso.eq_comp_inv f.f, category.assoc, ←f.h]
            simp  },
      by 
        tidy⟩⟩

instance forget_reflects_iso : reflects_isomorphisms T.forget :=
  { reflects := fun A B => algebra_iso_of_iso T }

instance forget_faithful : faithful T.forget :=
  {  }

instance  : is_right_adjoint T.forget :=
  ⟨T.free, T.adj⟩

@[simp]
theorem left_adjoint_forget : left_adjoint T.forget = T.free :=
  rfl

@[simp]
theorem of_right_adjoint_forget : adjunction.of_right_adjoint T.forget = T.adj :=
  rfl

/--
Given a monad morphism from `T₂` to `T₁`, we get a functor from the algebras of `T₁` to algebras of
`T₂`.
-/
@[simps]
def algebra_functor_of_monad_hom {T₁ T₂ : Monadₓ C} (h : T₂ ⟶ T₁) : algebra T₁ ⥤ algebra T₂ :=
  { obj :=
      fun A =>
        { a := A.A, a := h.app A.A ≫ A.a,
          unit' :=
            by 
              dsimp 
              simp [A.unit],
          assoc' :=
            by 
              dsimp 
              simp [A.assoc] },
    map := fun A₁ A₂ f => { f := f.f } }

/--
The identity monad morphism induces the identity functor from the category of algebras to itself.
-/
@[simps (config := { rhsMd := semireducible })]
def algebra_functor_of_monad_hom_id {T₁ : Monadₓ C} : algebra_functor_of_monad_hom (𝟙 T₁) ≅ 𝟭 _ :=
  nat_iso.of_components
    (fun X =>
      algebra.iso_mk (iso.refl _)
        (by 
          dsimp 
          simp ))
    fun X Y f =>
      by 
        ext 
        dsimp 
        simp 

/--
A composition of monad morphisms gives the composition of corresponding functors.
-/
@[simps (config := { rhsMd := semireducible })]
def algebra_functor_of_monad_hom_comp {T₁ T₂ T₃ : Monadₓ C} (f : T₁ ⟶ T₂) (g : T₂ ⟶ T₃) :
  algebra_functor_of_monad_hom (f ≫ g) ≅ algebra_functor_of_monad_hom g ⋙ algebra_functor_of_monad_hom f :=
  nat_iso.of_components
    (fun X =>
      algebra.iso_mk (iso.refl _)
        (by 
          dsimp 
          simp ))
    fun X Y f =>
      by 
        ext 
        dsimp 
        simp 

/--
If `f` and `g` are two equal morphisms of monads, then the functors of algebras induced by them
are isomorphic.
We define it like this as opposed to using `eq_to_iso` so that the components are nicer to prove
lemmas about.
-/
@[simps (config := { rhsMd := semireducible })]
def algebra_functor_of_monad_hom_eq {T₁ T₂ : Monadₓ C} {f g : T₁ ⟶ T₂} (h : f = g) :
  algebra_functor_of_monad_hom f ≅ algebra_functor_of_monad_hom g :=
  nat_iso.of_components
    (fun X =>
      algebra.iso_mk (iso.refl _)
        (by 
          dsimp 
          simp [h]))
    fun X Y f =>
      by 
        ext 
        dsimp 
        simp 

/--
Isomorphic monads give equivalent categories of algebras. Furthermore, they are equivalent as
categories over `C`, that is, we have `algebra_equiv_of_iso_monads h ⋙ forget = forget`.
-/
@[simps]
def algebra_equiv_of_iso_monads {T₁ T₂ : Monadₓ C} (h : T₁ ≅ T₂) : algebra T₁ ≌ algebra T₂ :=
  { Functor := algebra_functor_of_monad_hom h.inv, inverse := algebra_functor_of_monad_hom h.hom,
    unitIso :=
      algebra_functor_of_monad_hom_id.symm ≪≫
        algebra_functor_of_monad_hom_eq
            (by 
              simp ) ≪≫
          algebra_functor_of_monad_hom_comp _ _,
    counitIso :=
      (algebra_functor_of_monad_hom_comp _ _).symm ≪≫
        algebra_functor_of_monad_hom_eq
            (by 
              simp ) ≪≫
          algebra_functor_of_monad_hom_id }

@[simp]
theorem algebra_equiv_of_iso_monads_comp_forget {T₁ T₂ : Monadₓ C} (h : T₁ ⟶ T₂) :
  algebra_functor_of_monad_hom h ⋙ forget _ = forget _ :=
  rfl

end Monadₓ

namespace Comonad

/-- An Eilenberg-Moore coalgebra for a comonad `T`. -/
@[nolint has_inhabited_instance]
structure coalgebra(G : comonad C) : Type max u₁ v₁ where 
  a : C 
  a : A ⟶ (G : C ⥤ C).obj A 
  counit' : a ≫ G.ε.app A = 𝟙 A :=  by 
  runTac 
    obviously 
  coassoc' : a ≫ G.δ.app A = a ≫ G.map a :=  by 
  runTac 
    obviously

restate_axiom coalgebra.counit'

restate_axiom coalgebra.coassoc'

attribute [reassoc] coalgebra.counit coalgebra.coassoc

namespace Coalgebra

variable{G : comonad C}

/-- A morphism of Eilenberg-Moore coalgebras for the comonad `G`. -/
@[ext, nolint has_inhabited_instance]
structure hom(A B : coalgebra G) where 
  f : A.A ⟶ B.A 
  h' : A.a ≫ (G : C ⥤ C).map f = f ≫ B.a :=  by 
  runTac 
    obviously

restate_axiom hom.h'

attribute [simp, reassoc] hom.h

namespace Hom

/-- The identity homomorphism for an Eilenberg–Moore coalgebra. -/
def id (A : coalgebra G) : hom A A :=
  { f := 𝟙 A.A }

/-- Composition of Eilenberg–Moore coalgebra homomorphisms. -/
def comp {P Q R : coalgebra G} (f : hom P Q) (g : hom Q R) : hom P R :=
  { f := f.f ≫ g.f }

end Hom

/-- The category of Eilenberg-Moore coalgebras for a comonad. -/
instance  : category_struct (coalgebra G) :=
  { Hom := hom, id := hom.id, comp := @hom.comp _ _ _ }

@[simp]
theorem comp_eq_comp {A A' A'' : coalgebra G} (f : A ⟶ A') (g : A' ⟶ A'') : coalgebra.hom.comp f g = f ≫ g :=
  rfl

@[simp]
theorem id_eq_id (A : coalgebra G) : coalgebra.hom.id A = 𝟙 A :=
  rfl

@[simp]
theorem id_f (A : coalgebra G) : (𝟙 A : A ⟶ A).f = 𝟙 A.A :=
  rfl

@[simp]
theorem comp_f {A A' A'' : coalgebra G} (f : A ⟶ A') (g : A' ⟶ A'') : (f ≫ g).f = f.f ≫ g.f :=
  rfl

/-- The category of Eilenberg-Moore coalgebras for a comonad. -/
instance EilenbergMoore : category (coalgebra G) :=
  {  }

/--
To construct an isomorphism of coalgebras, it suffices to give an isomorphism of the carriers which
commutes with the structure morphisms.
-/
@[simps]
def iso_mk {A B : coalgebra G} (h : A.A ≅ B.A) (w : A.a ≫ (G : C ⥤ C).map h.hom = h.hom ≫ B.a) : A ≅ B :=
  { Hom := { f := h.hom },
    inv :=
      { f := h.inv,
        h' :=
          by 
            rw [h.eq_inv_comp, ←reassoc_of w, ←functor.map_comp]
            simp  } }

end Coalgebra

variable(G : comonad C)

/-- The forgetful functor from the Eilenberg-Moore category, forgetting the coalgebraic
structure. -/
@[simps]
def forget : coalgebra G ⥤ C :=
  { obj := fun A => A.A, map := fun A B f => f.f }

/-- The cofree functor from the Eilenberg-Moore category, constructing a coalgebra for any
object. -/
@[simps]
def cofree : C ⥤ coalgebra G :=
  { obj := fun X => { a := G.obj X, a := G.δ.app X, coassoc' := (G.coassoc _).symm },
    map := fun X Y f => { f := G.map f, h' := (G.δ.naturality _).symm } }

/--
The adjunction between the cofree and forgetful constructions for Eilenberg-Moore coalgebras
for a comonad.
-/
@[simps Unit counit]
def adj : G.forget ⊣ G.cofree :=
  adjunction.mk_of_hom_equiv
    { homEquiv :=
        fun X Y =>
          { toFun :=
              fun f =>
                { f := X.a ≫ G.map f,
                  h' :=
                    by 
                      dsimp 
                      simp [←coalgebra.coassoc_assoc] },
            invFun := fun g => g.f ≫ G.ε.app Y,
            left_inv :=
              fun f =>
                by 
                  dsimp 
                  rw [category.assoc, G.ε.naturality, functor.id_map, X.counit_assoc],
            right_inv :=
              fun g =>
                by 
                  ext1 
                  dsimp 
                  rw [functor.map_comp, g.h_assoc, cofree_obj_a, comonad.right_counit]
                  apply comp_id } }

/--
Given a coalgebra morphism whose carrier part is an isomorphism, we get a coalgebra isomorphism.
-/
theorem coalgebra_iso_of_iso {A B : coalgebra G} (f : A ⟶ B) [is_iso f.f] : is_iso f :=
  ⟨⟨{ f := inv f.f,
        h' :=
          by 
            rw [is_iso.eq_inv_comp f.f, ←f.h_assoc]
            simp  },
      by 
        tidy⟩⟩

instance forget_reflects_iso : reflects_isomorphisms G.forget :=
  { reflects := fun A B => coalgebra_iso_of_iso G }

instance forget_faithful : faithful (forget G) :=
  {  }

instance  : is_left_adjoint G.forget :=
  ⟨_, G.adj⟩

@[simp]
theorem right_adjoint_forget : right_adjoint G.forget = G.cofree :=
  rfl

@[simp]
theorem of_left_adjoint_forget : adjunction.of_left_adjoint G.forget = G.adj :=
  rfl

end Comonad

end CategoryTheory

