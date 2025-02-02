/-
Copyright (c) 2018 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Bhavik Mehta
-/
import Mathbin.CategoryTheory.Functor.Const
import Mathbin.CategoryTheory.DiscreteCategory

/-!
# The category `discrete punit`

We define `star : C ⥤ discrete punit` sending everything to `punit.star`,
show that any two functors to `discrete punit` are naturally isomorphic,
and construct the equivalence `(discrete punit ⥤ C) ≌ C`.
-/


universe v u

-- morphism levels before object levels. See note [category_theory universes].
namespace CategoryTheory

variable (C : Type u) [Category.{v} C]

namespace Functor

/-- The constant functor sending everything to `punit.star`. -/
@[simps]
def star : C ⥤ Discrete PUnit :=
  (Functor.const _).obj ⟨⟨⟩⟩

variable {C}

/-- Any two functors to `discrete punit` are isomorphic. -/
@[simps]
def punitExt (F G : C ⥤ Discrete PUnit) : F ≅ G :=
  NatIso.ofComponents
    (fun _ =>
      eqToIso
        (by
          decide))
    fun _ _ _ => by
    decide

/-- Any two functors to `discrete punit` are *equal*.
You probably want to use `punit_ext` instead of this.
-/
theorem punit_ext' (F G : C ⥤ Discrete PUnit) : F = G :=
  Functor.ext
    (fun _ => by
      decide)
    fun _ _ _ => by
    decide

/-- The functor from `discrete punit` sending everything to the given object. -/
abbrev fromPunit (X : C) : Discrete PUnit.{v + 1} ⥤ C :=
  (Functor.const _).obj X

/-- Functors from `discrete punit` are equivalent to the category itself. -/
@[simps]
def equiv : Discrete PUnit ⥤ C ≌ C where
  Functor := { obj := fun F => F.obj ⟨⟨⟩⟩, map := fun F G θ => θ.app ⟨⟨⟩⟩ }
  inverse := Functor.const _
  unitIso := by
    apply nat_iso.of_components _ _
    intro X
    apply discrete.nat_iso
    rintro ⟨⟨⟩⟩
    apply iso.refl _
    intros
    ext ⟨⟨⟩⟩
    simp
  counitIso := by
    refine' nat_iso.of_components iso.refl _
    intro X Y f
    dsimp'
    simp

-- See note [dsimp, simp].
end Functor

/-- A category being equivalent to `punit` is equivalent to it having a unique morphism between
  any two objects. (In fact, such a category is also a groupoid; see `groupoid.of_hom_unique`) -/
theorem equiv_punit_iff_unique : Nonempty (C ≌ Discrete PUnit) ↔ Nonempty C ∧ ∀ x y : C, Nonempty <| Unique (x ⟶ y) :=
  by
  constructor
  · rintro ⟨h⟩
    refine' ⟨⟨h.inverse.obj ⟨⟨⟩⟩⟩, fun x y => Nonempty.intro _⟩
    apply uniqueOfSubsingleton _
    swap
    · have hx : x ⟶ h.inverse.obj ⟨⟨⟩⟩ := by
        convert h.unit.app x
      have hy : h.inverse.obj ⟨⟨⟩⟩ ⟶ y := by
        convert h.unit_inv.app y
      exact hx ≫ hy
      
    have : ∀ z, z = h.unit.app x ≫ (h.functor ⋙ h.inverse).map z ≫ h.unit_inv.app y := by
      intro z
      simpa using congr_argₓ (· ≫ h.unit_inv.app y) (h.unit.naturality z)
    apply Subsingleton.intro
    intro a b
    rw [this a, this b]
    simp only [functor.comp_map]
    congr
    
  · rintro ⟨⟨p⟩, h⟩
    haveI := fun x y => (h x y).some
    refine'
      Nonempty.intro
        (CategoryTheory.Equivalence.mk ((Functor.Const _).obj ⟨⟨⟩⟩) ((Functor.Const _).obj p) _
          (by
            apply functor.punit_ext))
    exact
      nat_iso.of_components (fun _ => { Hom := default, inv := default }) fun _ _ _ => by
        tidy
    

end CategoryTheory

