/-
Copyright (c) 2022 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import Mathbin.CategoryTheory.Subobject.Lattice
import Mathbin.CategoryTheory.EssentiallySmall
import Mathbin.CategoryTheory.Simple

/-!
# Artinian and noetherian categories

An artinian category is a category in which objects do not
have infinite decreasing sequences of subobjects.

A noetherian category is a category in which objects do not
have infinite increasing sequences of subobjects.

We show that any nonzero artinian object has a simple subobject.

## Future work
The Jordan-Hölder theorem, following https://stacks.math.columbia.edu/tag/0FCK.
-/


namespace CategoryTheory

open CategoryTheory.Limits

variable {C : Type _} [Category C]

/-- A noetherian object is an object
which does not have infinite increasing sequences of subobjects.

See https://stacks.math.columbia.edu/tag/0FCG
-/
class NoetherianObject (X : C) : Prop where
  subobject_gt_well_founded : WellFounded ((· > ·) : Subobject X → Subobject X → Prop)

-- ./././Mathport/Syntax/Translate/Command.lean:324:30: infer kinds are unsupported in Lean 4: #[`subobject_lt_well_founded] []
/-- An artinian object is an object
which does not have infinite decreasing sequences of subobjects.

See https://stacks.math.columbia.edu/tag/0FCF
-/
class ArtinianObject (X : C) : Prop where
  subobject_lt_well_founded : WellFounded ((· < ·) : Subobject X → Subobject X → Prop)

variable (C)

/-- A category is noetherian if it is essentially small and all objects are noetherian. -/
class Noetherian extends EssentiallySmall C where
  NoetherianObject : ∀ X : C, NoetherianObject X

attribute [instance] noetherian.noetherian_object

/-- A category is artinian if it is essentially small and all objects are artinian. -/
class Artinian extends EssentiallySmall C where
  ArtinianObject : ∀ X : C, ArtinianObject X

attribute [instance] artinian.artinian_object

variable {C}

open Subobject

variable [HasZeroMorphisms C] [HasZeroObject C]

theorem exists_simple_subobject {X : C} [ArtinianObject X] (h : ¬IsZero X) : ∃ Y : Subobject X, Simple (Y : C) := by
  haveI : Nontrivial (subobject X) := nontrivial_of_not_is_zero h
  haveI := is_atomic_of_order_bot_well_founded_lt (artinian_object.subobject_lt_well_founded X)
  have := IsAtomic.eq_bot_or_exists_atom_le (⊤ : subobject X)
  obtain ⟨Y, s⟩ := (IsAtomic.eq_bot_or_exists_atom_le (⊤ : subobject X)).resolve_left top_ne_bot
  exact ⟨Y, (subobject_simple_iff_is_atom _).mpr s.1⟩

/-- Choose an arbitrary simple subobject of a non-zero artinian object. -/
noncomputable def simpleSubobject {X : C} [ArtinianObject X] (h : ¬IsZero X) : C :=
  (exists_simple_subobject h).some

/-- The monomorphism from the arbitrary simple subobject of a non-zero artinian object. -/
noncomputable def simpleSubobjectArrow {X : C} [ArtinianObject X] (h : ¬IsZero X) : simpleSubobject h ⟶ X :=
  (exists_simple_subobject h).some.arrow deriving Mono

instance {X : C} [ArtinianObject X] (h : ¬IsZero X) : Simple (simpleSubobject h) :=
  (exists_simple_subobject h).some_spec

end CategoryTheory

