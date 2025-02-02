/-
Copyright (c) 2021 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import Mathbin.CategoryTheory.Subobject.WellPowered
import Mathbin.CategoryTheory.Types

/-!
# `Type u` is well-powered

By building a categorical equivalence `mono_over α ≌ set α` for any `α : Type u`,
we deduce that `subobject α ≃o set α` and that `Type u` is well-powered.

One would hope that for a particular concrete category `C` (`AddCommGroup`, etc)
it's viable to prove `[well_powered C]` without explicitly aligning `subobject X`
with the "hand-rolled" definition of subobjects.

This may be possible using Lawvere theories,
but it remains to be seen whether this just pushes lumps around in the carpet.
-/


universe u

open CategoryTheory

open CategoryTheory.Subobject

open CategoryTheory.Type

theorem subtype_val_mono {α : Type u} (s : Set α) : Mono (↾(Subtype.val : s → α)) :=
  (mono_iff_injective _).mpr Subtype.val_injective

attribute [local instance] subtype_val_mono

/-- The category of `mono_over α`, for `α : Type u`, is equivalent to the partial order `set α`.
-/
@[simps]
noncomputable def Types.monoOverEquivalenceSet (α : Type u) : MonoOver α ≌ Set α where
  Functor :=
    { obj := fun f => Set.Range f.1.Hom,
      map := fun f g t =>
        homOfLe
          (by
            rintro a ⟨x, rfl⟩
            exact ⟨t.1 x, congr_funₓ t.w x⟩) }
  inverse :=
    { obj := fun s => MonoOver.mk' (Subtype.val : s → α),
      map := fun s t b =>
        MonoOver.homMk (fun w => ⟨w.1, Set.mem_of_mem_of_subset w.2 b.le⟩)
          (by
            ext
            simp ) }
  unitIso :=
    NatIso.ofComponents
      (fun f =>
        MonoOver.isoMk (Equivₓ.ofInjective f.1.Hom ((mono_iff_injective _).mp f.2)).toIso
          (by
            tidy))
      (by
        tidy)
  counitIso :=
    NatIso.ofComponents (fun s => eqToIso Subtype.range_val)
      (by
        tidy)

instance : WellPowered (Type u) :=
  well_powered_of_essentially_small_mono_over fun α => EssentiallySmall.mk' (Types.monoOverEquivalenceSet α)

/-- For `α : Type u`, `subobject α` is order isomorphic to `set α`.
-/
noncomputable def Types.subobjectEquivSet (α : Type u) : Subobject α ≃o Set α :=
  (Types.monoOverEquivalenceSet α).thinSkeletonOrderIso

