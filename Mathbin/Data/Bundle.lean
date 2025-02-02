/-
Copyright © 2021 Nicolò Cavalleri. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Nicolò Cavalleri
-/
import Mathbin.Tactic.Basic
import Mathbin.Algebra.Module.Basic

/-!
# Bundle
Basic data structure to implement fiber bundles, vector bundles (maybe fibrations?), etc. This file
should contain all possible results that do not involve any topology.

We represent a bundle `E` over a base space `B` as a dependent type `E : B → Type*`.

We provide a type synonym of `Σ x, E x` as `bundle.total_space E`, to be able to endow it with
a topology which is not the disjoint union topology `sigma.topological_space`. In general, the
constructions of fiber bundles we will make will be of this form.

## Main Definitions

* `bundle.total_space` the total space of a bundle.
* `bundle.total_space.proj` the projection from the total space to the base space.
* `bundle.total_space_mk` the constructor for the total space.

## References
- https://en.wikipedia.org/wiki/Bundle_(mathematics)
-/


namespace Bundle

variable {B : Type _} (E : B → Type _)

/-- `bundle.total_space E` is the total space of the bundle `Σ x, E x`.
This type synonym is used to avoid conflicts with general sigma types.
-/
def TotalSpace :=
  Σx, E x

instance [Inhabited B] [Inhabited (E default)] : Inhabited (TotalSpace E) :=
  ⟨⟨default, default⟩⟩

variable {E}

/-- `bundle.total_space.proj` is the canonical projection `bundle.total_space E → B` from the
total space to the base space. -/
@[simp, reducible]
def TotalSpace.proj : TotalSpace E → B :=
  Sigma.fst

/-- Constructor for the total space of a bundle. -/
@[simp, reducible]
def totalSpaceMk (b : B) (a : E b) : Bundle.TotalSpace E :=
  ⟨b, a⟩

theorem TotalSpace.proj_mk {x : B} {y : E x} : (totalSpaceMk x y).proj = x :=
  rfl

theorem sigma_mk_eq_total_space_mk {x : B} {y : E x} : Sigma.mk x y = totalSpaceMk x y :=
  rfl

theorem TotalSpace.mk_cast {x x' : B} (h : x = x') (b : E x) :
    totalSpaceMk x' (cast (congr_argₓ E h) b) = totalSpaceMk x b := by
  subst h
  rfl

theorem TotalSpace.eta (z : TotalSpace E) : totalSpaceMk z.proj z.2 = z :=
  Sigma.eta z

instance {x : B} : CoeTₓ (E x) (TotalSpace E) :=
  ⟨totalSpaceMk x⟩

@[simp]
theorem coe_fst (x : B) (v : E x) : (v : TotalSpace E).fst = x :=
  rfl

@[simp]
theorem coe_snd {x : B} {y : E x} : (y : TotalSpace E).snd = y :=
  rfl

theorem to_total_space_coe {x : B} (v : E x) : (v : TotalSpace E) = totalSpaceMk x v :=
  rfl

-- mathport name: «expr ×ᵇ »
notation:100 -- notation for the direct sum of two bundles over the same base
E₁ "×ᵇ" E₂ => fun x => E₁ x × E₂ x

/-- `bundle.trivial B F` is the trivial bundle over `B` of fiber `F`. -/
def Trivial (B : Type _) (F : Type _) : B → Type _ :=
  Function.const B F

instance {F : Type _} [Inhabited F] {b : B} : Inhabited (Bundle.Trivial B F b) :=
  ⟨(default : F)⟩

/-- The trivial bundle, unlike other bundles, has a canonical projection on the fiber. -/
def Trivial.projSnd (B : Type _) (F : Type _) : TotalSpace (Bundle.Trivial B F) → F :=
  Sigma.snd

section Pullback

variable {B' : Type _}

/-- The pullback of a bundle `E` over a base `B` under a map `f : B' → B`, denoted by `pullback f E`
or `f *ᵖ E`,  is the bundle over `B'` whose fiber over `b'` is `E (f b')`. -/
@[nolint has_nonempty_instance]
def Pullback (f : B' → B) (E : B → Type _) := fun x => E (f x)

-- mathport name: «expr *ᵖ »
notation f " *ᵖ " E => Pullback f E

/-- Natural embedding of the total space of `f *ᵖ E` into `B' × total_space E`. -/
@[simp]
def pullbackTotalSpaceEmbedding (f : B' → B) : TotalSpace (f *ᵖ E) → B' × TotalSpace E := fun z =>
  (z.proj, totalSpaceMk (f z.proj) z.2)

/-- The base map `f : B' → B` lifts to a canonical map on the total spaces. -/
def Pullback.lift (f : B' → B) : TotalSpace (f *ᵖ E) → TotalSpace E := fun z => totalSpaceMk (f z.proj) z.2

@[simp]
theorem Pullback.proj_lift (f : B' → B) (x : TotalSpace (f *ᵖ E)) : (Pullback.lift f x).proj = f x.1 :=
  rfl

@[simp]
theorem Pullback.lift_mk (f : B' → B) (x : B') (y : E (f x)) :
    Pullback.lift f (totalSpaceMk x y) = totalSpaceMk (f x) y :=
  rfl

theorem pullback_total_space_embedding_snd (f : B' → B) (x : TotalSpace (f *ᵖ E)) :
    (pullbackTotalSpaceEmbedding f x).2 = Pullback.lift f x :=
  rfl

end Pullback

section FiberStructures

variable [∀ x, AddCommMonoidₓ (E x)]

@[simp]
theorem coe_snd_map_apply (x : B) (v w : E x) :
    (↑(v + w) : TotalSpace E).snd = (v : TotalSpace E).snd + (w : TotalSpace E).snd :=
  rfl

variable (R : Type _) [Semiringₓ R] [∀ x, Module R (E x)]

@[simp]
theorem coe_snd_map_smul (x : B) (r : R) (v : E x) : (↑(r • v) : TotalSpace E).snd = r • (v : TotalSpace E).snd :=
  rfl

end FiberStructures

section TrivialInstances

variable {F : Type _} {R : Type _} [Semiringₓ R] (b : B)

instance [AddCommMonoidₓ F] : AddCommMonoidₓ (Bundle.Trivial B F b) :=
  ‹AddCommMonoidₓ F›

instance [AddCommGroupₓ F] : AddCommGroupₓ (Bundle.Trivial B F b) :=
  ‹AddCommGroupₓ F›

instance [AddCommMonoidₓ F] [Module R F] : Module R (Bundle.Trivial B F b) :=
  ‹Module R F›

end TrivialInstances

end Bundle

