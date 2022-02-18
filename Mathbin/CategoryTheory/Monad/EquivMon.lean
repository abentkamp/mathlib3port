import Mathbin.CategoryTheory.Monad.Basic
import Mathbin.CategoryTheory.Monoidal.End
import Mathbin.CategoryTheory.Monoidal.Mon_
import Mathbin.CategoryTheory.Category.Cat

/-!

# The equivalence between `Monad C` and `Mon_ (C ⥤ C)`.

A monad "is just" a monoid in the category of endofunctors.

# Definitions/Theorems

1. `to_Mon` associates a monoid object in `C ⥤ C` to any monad on `C`.
2. `Monad_to_Mon` is the functorial version of `to_Mon`.
3. `of_Mon` associates a monad on `C` to any monoid object in `C ⥤ C`.
4. `Monad_Mon_equiv` is the equivalence between `Monad C` and `Mon_ (C ⥤ C)`.

-/


namespace CategoryTheory

open Category

universe v u

variable {C : Type u} [Category.{v} C]

namespace Monad

attribute [local instance, local reducible] endofunctor_monoidal_category

/-- To every `Monad C` we associated a monoid object in `C ⥤ C`.-/
@[simps]
def to_Mon : Monad C → Mon_ (C ⥤ C) := fun M =>
  { x := (M : C ⥤ C), one := M.η, mul := M.μ,
    one_mul' := by
      ext
      simp ,
    mul_one' := by
      ext
      simp ,
    mul_assoc' := by
      ext
      dsimp
      simp [M.assoc] }

variable (C)

/-- Passing from `Monad C` to `Mon_ (C ⥤ C)` is functorial. -/
@[simps]
def Monad_to_Mon : Monad C ⥤ Mon_ (C ⥤ C) where
  obj := toMon
  map := fun _ _ f => { Hom := f.toNatTrans }
  map_id' := by
    intro X
    rfl
  map_comp' := by
    intro X Y Z f g
    rfl

variable {C}

/-- To every monoid object in `C ⥤ C` we associate a `Monad C`. -/
@[simps]
def of_Mon : Mon_ (C ⥤ C) → Monad C := fun M =>
  { toFunctor := M.x, η' := M.one, μ' := M.mul,
    left_unit' := fun X => by
      rw [← M.one.id_hcomp_app, ← nat_trans.comp_app, M.mul_one]
      rfl,
    right_unit' := fun X => by
      rw [← M.one.hcomp_id_app, ← nat_trans.comp_app, M.one_mul]
      rfl,
    assoc' := fun X => by
      rw [← nat_trans.hcomp_id_app, ← nat_trans.comp_app]
      simp }

variable (C)

/-- Passing from `Mon_ (C ⥤ C)` to `Monad C` is functorial. -/
@[simps]
def Mon_to_Monad : Mon_ (C ⥤ C) ⥤ Monad C where
  obj := ofMon
  map := fun _ _ f =>
    { f.Hom with
      app_η' := by
        intro X
        erw [← nat_trans.comp_app, f.one_hom]
        rfl,
      app_μ' := by
        intro X
        erw [← nat_trans.comp_app, f.mul_hom]
        simpa only [nat_trans.naturality, nat_trans.hcomp_app, assoc, nat_trans.comp_app, of_Mon_μ] }

namespace MonadMonEquiv

variable {C}

/-- Isomorphism of functors used in `Monad_Mon_equiv` -/
@[simps (config := { rhsMd := semireducible })]
def counit_iso : monToMonad C ⋙ monadToMon C ≅ 𝟭 _ where
  Hom := { app := fun _ => { Hom := 𝟙 _ } }
  inv := { app := fun _ => { Hom := 𝟙 _ } }
  hom_inv_id' := by
    ext
    simp
  inv_hom_id' := by
    ext
    simp

/-- Auxiliary definition for `Monad_Mon_equiv` -/
@[simps]
def unit_iso_hom : 𝟭 _ ⟶ monadToMon C ⋙ monToMonad C where
  app := fun _ => { app := fun _ => 𝟙 _ }

/-- Auxiliary definition for `Monad_Mon_equiv` -/
@[simps]
def unit_iso_inv : monadToMon C ⋙ monToMonad C ⟶ 𝟭 _ where
  app := fun _ => { app := fun _ => 𝟙 _ }

/-- Isomorphism of functors used in `Monad_Mon_equiv` -/
@[simps]
def unit_iso : 𝟭 _ ≅ monadToMon C ⋙ monToMonad C where
  Hom := unitIsoHom
  inv := unitIsoInv
  hom_inv_id' := by
    ext
    simp
  inv_hom_id' := by
    ext
    simp

end MonadMonEquiv

open MonadMonEquiv

/-- Oh, monads are just monoids in the category of endofunctors (equivalence of categories). -/
@[simps]
def Monad_Mon_equiv : Monad C ≌ Mon_ (C ⥤ C) where
  Functor := monadToMon _
  inverse := monToMonad _
  unitIso := unitIso
  counitIso := counitIso
  functor_unit_iso_comp' := by
    intro X
    ext
    dsimp
    simp

example (A : Monad C) {X : C} : ((monadMonEquiv C).unitIso.app A).Hom.app X = 𝟙 _ :=
  rfl

end Monad

end CategoryTheory

