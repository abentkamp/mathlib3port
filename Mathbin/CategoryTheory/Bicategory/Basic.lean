import Mathbin.CategoryTheory.Isomorphism
import Mathbin.Tactic.Slice

/-!
# Bicategories

In this file we define typeclass for bicategories.

A bicategory `B` consists of
* objects `a : B`,
* 1-morphisms `f : a ⟶ b` between objects `a b : B`, and
* 2-morphisms `η : f ⟶ g` beween 1-morphisms `f g : a ⟶ b` between objects `a b : B`.

We use `u`, `v`, and `w` as the universe variables for objects, 1-morphisms, and 2-morphisms,
respectively.

A typeclass for bicategories extends `category_theory.category_struct` typeclass. This means that
we have
* a composition `f ≫ g : a ⟶ c` for each 1-morphisms `f : a ⟶ b` and `g : b ⟶ c`, and
* a identity `𝟙 a : a ⟶ a` for each object `a : B`.

For each object `a b : B`, the collection of 1-morphisms `a ⟶ b` has a category structure. The
2-morphisms in the bicategory are implemented as the morphisms in this family of categories.

The composition of 1-morphisms is in fact a object part of a functor
`(a ⟶ b) ⥤ (b ⟶ c) ⥤ (a ⟶ c)`. The definition of bicategories in this file does not
require this functor directly. Instead, it requires the whiskering functions. For a 1-morphism
`f : a ⟶ b` and a 2-morphism `η : g ⟶ h` between 1-morphisms `g h : b ⟶ c`, there is a
2-morphism `whisker_left f η : f ≫ g ⟶ f ≫ h`. Similarly, for a 2-morphism `η : f ⟶ g`
between 1-morphisms `f g : a ⟶ b` and a 1-morphism `f : b ⟶ c`, there is a 2-morphism
`whisker_right η h : f ≫ h ⟶ g ≫ h`. These satisfy the exchange law
`whisker_left f θ ≫ whisker_right η i = whisker_right η h ≫ whisker_left g θ`,
which is required as an axiom in the definition here.
-/


namespace CategoryTheory

universe w v u

open Category Iso

-- ././Mathport/Syntax/Translate/Basic.lean:1151:29: unsupported: (notation) in structure
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:1151:29: unsupported: (notation) in structure
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:1151:29: unsupported: (notation) in structure
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:1151:29: unsupported: (notation) in structure
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«exprλ_»
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«exprλ_»
-- ././Mathport/Syntax/Translate/Basic.lean:1151:29: unsupported: (notation) in structure
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprρ_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprρ_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprα_
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ◁ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«exprλ_»
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `«expr ▷ »
-- ././Mathport/Syntax/Translate/Basic.lean:707:4: warning: unsupported notation `exprρ_
/-- In a bicategory, we can compose the 1-morphisms `f : a ⟶ b` and `g : b ⟶ c` to obtain
a 1-morphism `f ≫ g : a ⟶ c`. This composition does not need to be strictly associative,
but there is a specified associator, `α_ f g h : (f ≫ g) ≫ h ≅ f ≫ (g ≫ h)`.
There is an identity 1-morphism `𝟙 a : a ⟶ a`, with specified left and right unitor
isomorphisms `λ_ f : 𝟙 a ≫ f ≅ f` and `ρ_ f : f ≫ 𝟙 a ≅ f`.
These associators and unitors satisfy the pentagon and triangle equations.

See https://ncatlab.org/nlab/show/bicategory.
-/
@[nolint check_univs]
class bicategory (B : Type u) extends CategoryStruct.{v} B where
  right_unitor_naturality' :
    ∀ {a b} {f f' : a ⟶ b} η : f ⟶ f', «expr ▷ » η (𝟙 b) ≫ ((exprρ_) f').Hom = ((exprρ_) f).Hom ≫ η := by
    run_tac
      obviously
  pentagon' :
    ∀ {a b c d e} f : a ⟶ b g : b ⟶ c h : c ⟶ d i : d ⟶ e,
      «expr ▷ » ((exprα_) f g h).Hom i ≫ ((exprα_) f (g ≫ h) i).Hom ≫ «expr ◁ » f ((exprα_) g h i).Hom =
        ((exprα_) (f ≫ g) h i).Hom ≫ ((exprα_) f g (h ≫ i)).Hom := by
    run_tac
      obviously
  triangle' :
    ∀ {a b c} f : a ⟶ b g : b ⟶ c,
      ((exprα_) f (𝟙 b) g).Hom ≫ «expr ◁ » f ((«exprλ_») g).Hom = «expr ▷ » ((exprρ_) f).Hom g := by
    run_tac
      obviously

restate_axiom bicategory.whisker_left_id'

restate_axiom bicategory.whisker_left_comp'

restate_axiom bicategory.whisker_right_id'

restate_axiom bicategory.whisker_right_comp'

restate_axiom bicategory.whisker_exchange'

restate_axiom bicategory.associator_naturality_left'

restate_axiom bicategory.associator_naturality_middle'

restate_axiom bicategory.associator_naturality_right'

restate_axiom bicategory.left_unitor_naturality'

restate_axiom bicategory.right_unitor_naturality'

restate_axiom bicategory.pentagon'

restate_axiom bicategory.triangle'

attribute [simp] bicategory.whisker_left_id bicategory.whisker_right_id bicategory.whisker_exchange bicategory.triangle

attribute [reassoc]
  bicategory.whisker_left_comp bicategory.whisker_right_comp bicategory.whisker_exchange bicategory.associator_naturality_left bicategory.associator_naturality_middle bicategory.associator_naturality_right bicategory.left_unitor_naturality bicategory.right_unitor_naturality bicategory.pentagon bicategory.triangle

attribute [simp] bicategory.whisker_left_comp bicategory.whisker_right_comp

attribute [instance] bicategory.hom_category

localized [Bicategory] infixr:70 " ◁ " => Bicategory.whiskerLeft

localized [Bicategory] infixr:70 " ▷ " => Bicategory.whiskerRight

localized [Bicategory] notation "α_" => Bicategory.associator

localized [Bicategory] notation "λ_" => Bicategory.leftUnitor

localized [Bicategory] notation "ρ_" => Bicategory.rightUnitor

namespace Bicategory

section

variable {B : Type u} [Bicategory.{w, v} B] {a b c d e : B}

@[simp, reassoc]
theorem hom_inv_whisker_left (f : a ⟶ b) {g h : b ⟶ c} (η : g ≅ h) : (f ◁ η.Hom) ≫ (f ◁ η.inv) = 𝟙 (f ≫ g) := by
  rw [← whisker_left_comp, hom_inv_id, whisker_left_id]

@[simp, reassoc]
theorem hom_inv_whisker_right {f g : a ⟶ b} (η : f ≅ g) (h : b ⟶ c) : (η.Hom ▷ h) ≫ (η.inv ▷ h) = 𝟙 (f ≫ h) := by
  rw [← whisker_right_comp, hom_inv_id, whisker_right_id]

@[simp, reassoc]
theorem inv_hom_whisker_left (f : a ⟶ b) {g h : b ⟶ c} (η : g ≅ h) : (f ◁ η.inv) ≫ (f ◁ η.Hom) = 𝟙 (f ≫ h) := by
  rw [← whisker_left_comp, inv_hom_id, whisker_left_id]

@[simp, reassoc]
theorem inv_hom_whisker_right {f g : a ⟶ b} (η : f ≅ g) (h : b ⟶ c) : (η.inv ▷ h) ≫ (η.Hom ▷ h) = 𝟙 (g ≫ h) := by
  rw [← whisker_right_comp, inv_hom_id, whisker_right_id]

/-- The left whiskering of a 2-isomorphism is a 2-isomorphism. -/
@[simps]
def whisker_left_iso (f : a ⟶ b) {g h : b ⟶ c} (η : g ≅ h) : f ≫ g ≅ f ≫ h where
  Hom := f ◁ η.Hom
  inv := f ◁ η.inv
  hom_inv_id' := by
    simp only [hom_inv_whisker_left]
  inv_hom_id' := by
    simp only [inv_hom_whisker_left]

instance whisker_left_is_iso (f : a ⟶ b) {g h : b ⟶ c} (η : g ⟶ h) [IsIso η] : IsIso (f ◁ η) :=
  IsIso.of_iso (whiskerLeftIso f (asIso η))

@[simp]
theorem inv_whisker_left (f : a ⟶ b) {g h : b ⟶ c} (η : g ⟶ h) [IsIso η] : inv (f ◁ η) = f ◁ inv η := by
  ext
  simp only [← whisker_left_comp, whisker_left_id, is_iso.hom_inv_id]

/-- The right whiskering of a 2-isomorphism is a 2-isomorphism. -/
@[simps]
def whisker_right_iso {f g : a ⟶ b} (η : f ≅ g) (h : b ⟶ c) : f ≫ h ≅ g ≫ h where
  Hom := η.Hom ▷ h
  inv := η.inv ▷ h
  hom_inv_id' := by
    simp only [hom_inv_whisker_right]
  inv_hom_id' := by
    simp only [inv_hom_whisker_right]

instance whisker_right_is_iso {f g : a ⟶ b} (η : f ⟶ g) (h : b ⟶ c) [IsIso η] : IsIso (η ▷ h) :=
  IsIso.of_iso (whiskerRightIso (asIso η) h)

@[simp]
theorem inv_whisker_right {f g : a ⟶ b} (η : f ⟶ g) (h : b ⟶ c) [IsIso η] : inv (η ▷ h) = inv η ▷ h := by
  ext
  simp only [← whisker_right_comp, whisker_right_id, is_iso.hom_inv_id]

@[reassoc]
theorem left_unitor_inv_naturality {f f' : a ⟶ b} (η : f ⟶ f') : η ≫ (λ_ f').inv = (λ_ f).inv ≫ (𝟙 a ◁ η) := by
  apply (cancel_mono (λ_ f').Hom).1
  simp only [assoc, comp_id, inv_hom_id, left_unitor_naturality, inv_hom_id_assoc]

@[reassoc]
theorem right_unitor_inv_naturality {f f' : a ⟶ b} (η : f ⟶ f') : η ≫ (ρ_ f').inv = (ρ_ f).inv ≫ (η ▷ 𝟙 b) := by
  apply (cancel_mono (ρ_ f').Hom).1
  simp only [assoc, comp_id, inv_hom_id, right_unitor_naturality, inv_hom_id_assoc]

@[simp]
theorem right_unitor_conjugation {f g : a ⟶ b} (η : f ⟶ g) : (ρ_ f).inv ≫ (η ▷ 𝟙 b) ≫ (ρ_ g).Hom = η := by
  rw [right_unitor_naturality, inv_hom_id_assoc]

@[simp]
theorem left_unitor_conjugation {f g : a ⟶ b} (η : f ⟶ g) : (λ_ f).inv ≫ (𝟙 a ◁ η) ≫ (λ_ g).Hom = η := by
  rw [left_unitor_naturality, inv_hom_id_assoc]

@[simp]
theorem whisker_left_iff {f g : a ⟶ b} (η θ : f ⟶ g) : 𝟙 a ◁ η = 𝟙 a ◁ θ ↔ η = θ := by
  rw [← cancel_mono (λ_ g).Hom, left_unitor_naturality, left_unitor_naturality, cancel_iso_hom_left]

@[simp]
theorem whisker_right_iff {f g : a ⟶ b} (η θ : f ⟶ g) : η ▷ 𝟙 b = θ ▷ 𝟙 b ↔ η = θ := by
  rw [← cancel_mono (ρ_ g).Hom, right_unitor_naturality, right_unitor_naturality, cancel_iso_hom_left]

@[reassoc]
theorem left_unitor_comp' (f : a ⟶ b) (g : b ⟶ c) : (α_ (𝟙 a) f g).Hom ≫ (λ_ (f ≫ g)).Hom = (λ_ f).Hom ▷ g := by
  rw [← whisker_left_iff, whisker_left_comp, ← cancel_epi (α_ (𝟙 a) (𝟙 a ≫ f) g).Hom, ←
    cancel_epi ((α_ (𝟙 a) (𝟙 a) f).Hom ▷ g), pentagon_assoc, triangle, ← associator_naturality_middle, ←
    whisker_right_comp_assoc, triangle, associator_naturality_left, cancel_iso_hom_left]

@[reassoc, simp]
theorem left_unitor_comp (f : a ⟶ b) (g : b ⟶ c) : (λ_ (f ≫ g)).Hom = (α_ (𝟙 a) f g).inv ≫ ((λ_ f).Hom ▷ g) := by
  rw [← left_unitor_comp', inv_hom_id_assoc]

theorem left_unitor_comp_inv' (f : a ⟶ b) (g : b ⟶ c) : (λ_ (f ≫ g)).inv ≫ (α_ (𝟙 a) f g).inv = (λ_ f).inv ▷ g :=
  eq_of_inv_eq_inv
    (by
      simp only [left_unitor_comp, inv_whisker_right, is_iso.iso.inv_inv, hom_inv_id_assoc, is_iso.inv_comp])

@[reassoc, simp]
theorem left_unitor_comp_inv (f : a ⟶ b) (g : b ⟶ c) : (λ_ (f ≫ g)).inv = ((λ_ f).inv ▷ g) ≫ (α_ (𝟙 a) f g).Hom := by
  rw [← left_unitor_comp_inv']
  simp only [inv_hom_id, assoc, comp_id]

@[reassoc, simp]
theorem right_unitor_comp (f : a ⟶ b) (g : b ⟶ c) : (ρ_ (f ≫ g)).Hom = (α_ f g (𝟙 c)).Hom ≫ (f ◁ (ρ_ g).Hom) := by
  rw [← whisker_right_iff, whisker_right_comp, ← cancel_mono (α_ f g (𝟙 c)).Hom, assoc, associator_naturality_middle, ←
    triangle_assoc, ← triangle, whisker_left_comp, pentagon_assoc, ← associator_naturality_right]

@[reassoc, simp]
theorem right_unitor_comp_inv (f : a ⟶ b) (g : b ⟶ c) : (ρ_ (f ≫ g)).inv = (f ◁ (ρ_ g).inv) ≫ (α_ f g (𝟙 c)).inv :=
  eq_of_inv_eq_inv
    (by
      simp only [inv_whisker_left, right_unitor_comp, is_iso.iso.inv_inv, is_iso.inv_comp])

@[reassoc]
theorem whisker_left_right_unitor_inv (f : a ⟶ b) (g : b ⟶ c) :
    f ◁ (ρ_ g).inv = (ρ_ (f ≫ g)).inv ≫ (α_ f g (𝟙 c)).Hom := by
  simp only [right_unitor_comp_inv, comp_id, inv_hom_id, assoc]

@[reassoc]
theorem whisker_left_right_unitor (f : a ⟶ b) (g : b ⟶ c) : f ◁ (ρ_ g).Hom = (α_ f g (𝟙 c)).inv ≫ (ρ_ (f ≫ g)).Hom := by
  simp only [right_unitor_comp, inv_hom_id_assoc]

@[reassoc]
theorem left_unitor_inv_whisker_right (f : a ⟶ b) (g : b ⟶ c) :
    (λ_ f).inv ▷ g = (λ_ (f ≫ g)).inv ≫ (α_ (𝟙 a) f g).inv := by
  simp only [left_unitor_comp_inv, assoc, comp_id, hom_inv_id]

@[reassoc]
theorem left_unitor_whisker_right (f : a ⟶ b) (g : b ⟶ c) : (λ_ f).Hom ▷ g = (α_ (𝟙 a) f g).Hom ≫ (λ_ (f ≫ g)).Hom := by
  simp only [left_unitor_comp, hom_inv_id_assoc]

@[reassoc]
theorem associator_inv_naturality_left {f f' : a ⟶ b} (η : f ⟶ f') (g : b ⟶ c) (h : c ⟶ d) :
    (η ▷ g ≫ h) ≫ (α_ f' g h).inv = (α_ f g h).inv ≫ ((η ▷ g) ▷ h) := by
  rw [comp_inv_eq, assoc, associator_naturality_left, inv_hom_id_assoc]

@[reassoc]
theorem associator_conjugation_left {f f' : a ⟶ b} (η : f ⟶ f') (g : b ⟶ c) (h : c ⟶ d) :
    (α_ f g h).Hom ≫ (η ▷ g ≫ h) ≫ (α_ f' g h).inv = (η ▷ g) ▷ h := by
  rw [associator_inv_naturality_left, hom_inv_id_assoc]

@[reassoc]
theorem associator_inv_conjugation_left {f f' : a ⟶ b} (η : f ⟶ f') (g : b ⟶ c) (h : c ⟶ d) :
    (α_ f g h).inv ≫ ((η ▷ g) ▷ h) ≫ (α_ f' g h).Hom = η ▷ g ≫ h := by
  rw [associator_naturality_left, inv_hom_id_assoc]

@[reassoc]
theorem associator_inv_naturality_middle (f : a ⟶ b) {g g' : b ⟶ c} (η : g ⟶ g') (h : c ⟶ d) :
    (f ◁ η ▷ h) ≫ (α_ f g' h).inv = (α_ f g h).inv ≫ ((f ◁ η) ▷ h) := by
  rw [comp_inv_eq, assoc, associator_naturality_middle, inv_hom_id_assoc]

@[reassoc]
theorem associator_conjugation_middle (f : a ⟶ b) {g g' : b ⟶ c} (η : g ⟶ g') (h : c ⟶ d) :
    (α_ f g h).Hom ≫ (f ◁ η ▷ h) ≫ (α_ f g' h).inv = (f ◁ η) ▷ h := by
  rw [associator_inv_naturality_middle, hom_inv_id_assoc]

@[reassoc]
theorem associator_inv_conjugation_middle (f : a ⟶ b) {g g' : b ⟶ c} (η : g ⟶ g') (h : c ⟶ d) :
    (α_ f g h).inv ≫ ((f ◁ η) ▷ h) ≫ (α_ f g' h).Hom = f ◁ η ▷ h := by
  rw [associator_naturality_middle, inv_hom_id_assoc]

@[reassoc]
theorem associator_inv_naturality_right (f : a ⟶ b) (g : b ⟶ c) {h h' : c ⟶ d} (η : h ⟶ h') :
    (f ◁ g ◁ η) ≫ (α_ f g h').inv = (α_ f g h).inv ≫ (f ≫ g ◁ η) := by
  rw [comp_inv_eq, assoc, associator_naturality_right, inv_hom_id_assoc]

@[reassoc]
theorem associator_conjugation_right (f : a ⟶ b) (g : b ⟶ c) {h h' : c ⟶ d} (η : h ⟶ h') :
    (α_ f g h).Hom ≫ (f ◁ g ◁ η) ≫ (α_ f g h').inv = f ≫ g ◁ η := by
  rw [associator_inv_naturality_right, hom_inv_id_assoc]

@[reassoc]
theorem associator_inv_conjugation_right (f : a ⟶ b) (g : b ⟶ c) {h h' : c ⟶ d} (η : h ⟶ h') :
    (α_ f g h).inv ≫ (f ≫ g ◁ η) ≫ (α_ f g h').Hom = f ◁ g ◁ η := by
  rw [associator_naturality_right, inv_hom_id_assoc]

@[reassoc]
theorem pentagon_inv (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (f ◁ (α_ g h i).inv) ≫ (α_ f (g ≫ h) i).inv ≫ ((α_ f g h).inv ▷ i) = (α_ f g (h ≫ i)).inv ≫ (α_ (f ≫ g) h i).inv :=
  eq_of_inv_eq_inv
    (by
      simp only [pentagon, inv_whisker_left, inv_whisker_right, is_iso.iso.inv_inv, is_iso.inv_comp, assoc])

@[reassoc]
theorem pentagon_inv_inv_hom_hom_inv (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ f (g ≫ h) i).inv ≫ ((α_ f g h).inv ▷ i) ≫ (α_ (f ≫ g) h i).Hom = (f ◁ (α_ g h i).Hom) ≫ (α_ f g (h ≫ i)).inv :=
  by
  rw [← (eq_comp_inv _).mp (pentagon_inv f g h i)]
  slice_rhs 1 2 => rw [← whisker_left_comp, hom_inv_id]
  simp only [assoc, id_comp, whisker_left_id]

@[reassoc]
theorem pentagon_inv_hom_hom_hom_inv (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ (f ≫ g) h i).inv ≫ ((α_ f g h).Hom ▷ i) ≫ (α_ f (g ≫ h) i).Hom = (α_ f g (h ≫ i)).Hom ≫ (f ◁ (α_ g h i).inv) :=
  eq_of_inv_eq_inv
    (by
      simp only [pentagon_inv_inv_hom_hom_inv, inv_whisker_left, is_iso.iso.inv_hom, inv_whisker_right,
        is_iso.iso.inv_inv, is_iso.inv_comp, assoc])

@[reassoc]
theorem pentagon_hom_inv_inv_inv_inv (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (f ◁ (α_ g h i).Hom) ≫ (α_ f g (h ≫ i)).inv ≫ (α_ (f ≫ g) h i).inv = (α_ f (g ≫ h) i).inv ≫ ((α_ f g h).inv ▷ i) :=
  by
  rw [← (eq_comp_inv _).mp (pentagon_inv f g h i)]
  slice_lhs 1 2 => rw [← whisker_left_comp, hom_inv_id]
  simp only [assoc, id_comp, whisker_left_id, comp_id, hom_inv_id]

@[reassoc]
theorem pentagon_hom_hom_inv_hom_hom (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ (f ≫ g) h i).Hom ≫ (α_ f g (h ≫ i)).Hom ≫ (f ◁ (α_ g h i).inv) = ((α_ f g h).Hom ▷ i) ≫ (α_ f (g ≫ h) i).Hom :=
  eq_of_inv_eq_inv
    (by
      simp only [pentagon_hom_inv_inv_inv_inv, inv_whisker_left, is_iso.iso.inv_hom, inv_whisker_right,
        is_iso.iso.inv_inv, is_iso.inv_comp, assoc])

@[reassoc]
theorem pentagon_hom_inv_inv_inv_hom (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ f g (h ≫ i)).Hom ≫ (f ◁ (α_ g h i).inv) ≫ (α_ f (g ≫ h) i).inv = (α_ (f ≫ g) h i).inv ≫ ((α_ f g h).Hom ▷ i) :=
  by
  have pent := pentagon f g h i
  rw [← inv_comp_eq] at pent
  rw [← pent]
  simp only [hom_inv_whisker_left_assoc, assoc, comp_id, hom_inv_id]

@[reassoc]
theorem pentagon_hom_hom_inv_inv_hom (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ f (g ≫ h) i).Hom ≫ (f ◁ (α_ g h i).Hom) ≫ (α_ f g (h ≫ i)).inv = ((α_ f g h).inv ▷ i) ≫ (α_ (f ≫ g) h i).Hom :=
  eq_of_inv_eq_inv
    (by
      simp only [pentagon_hom_inv_inv_inv_hom, inv_whisker_left, is_iso.iso.inv_hom, inv_whisker_right,
        is_iso.iso.inv_inv, is_iso.inv_comp, assoc])

@[reassoc]
theorem pentagon_inv_hom_hom_hom_hom (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    ((α_ f g h).inv ▷ i) ≫ (α_ (f ≫ g) h i).Hom ≫ (α_ f g (h ≫ i)).Hom = (α_ f (g ≫ h) i).Hom ≫ (f ◁ (α_ g h i).Hom) :=
  by
  rw [← pentagon f g h i]
  simp only [inv_hom_whisker_right_assoc]

@[reassoc]
theorem pentagon_inv_inv_hom_inv_inv (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) (i : d ⟶ e) :
    (α_ f g (h ≫ i)).inv ≫ (α_ (f ≫ g) h i).inv ≫ ((α_ f g h).Hom ▷ i) = (f ◁ (α_ g h i).inv) ≫ (α_ f (g ≫ h) i).inv :=
  eq_of_inv_eq_inv
    (by
      simp only [pentagon_inv_hom_hom_hom_hom, inv_whisker_left, is_iso.iso.inv_hom, inv_whisker_right,
        is_iso.iso.inv_inv, is_iso.inv_comp, assoc])

theorem triangle_assoc_comp_left (f : a ⟶ b) (g : b ⟶ c) : (α_ f (𝟙 b) g).Hom ≫ (f ◁ (λ_ g).Hom) = (ρ_ f).Hom ▷ g :=
  triangle f g

@[simp, reassoc]
theorem triangle_assoc_comp_right (f : a ⟶ b) (g : b ⟶ c) : (α_ f (𝟙 b) g).inv ≫ ((ρ_ f).Hom ▷ g) = f ◁ (λ_ g).Hom := by
  rw [← triangle, inv_hom_id_assoc]

@[simp, reassoc]
theorem triangle_assoc_comp_right_inv (f : a ⟶ b) (g : b ⟶ c) :
    ((ρ_ f).inv ▷ g) ≫ (α_ f (𝟙 b) g).Hom = f ◁ (λ_ g).inv := by
  apply (cancel_mono (f ◁ (λ_ g).Hom)).1
  simp only [inv_hom_whisker_left, inv_hom_whisker_right, assoc, triangle]

@[simp, reassoc]
theorem triangle_assoc_comp_left_inv (f : a ⟶ b) (g : b ⟶ c) : (f ◁ (λ_ g).inv) ≫ (α_ f (𝟙 b) g).inv = (ρ_ f).inv ▷ g :=
  by
  apply (cancel_mono ((ρ_ f).Hom ▷ g)).1
  simp only [triangle_assoc_comp_right, inv_hom_whisker_left, inv_hom_whisker_right, assoc]

theorem unitors_equal : (λ_ (𝟙 a)).Hom = (ρ_ (𝟙 a)).Hom := by
  rw [← whisker_left_iff, ← cancel_epi (α_ (𝟙 a) (𝟙 _) (𝟙 _)).Hom, ← cancel_mono (ρ_ (𝟙 a)).Hom, triangle, ←
    right_unitor_comp, right_unitor_naturality]

theorem unitors_inv_equal : (λ_ (𝟙 a)).inv = (ρ_ (𝟙 a)).inv := by
  ext
  rw [← unitors_equal]
  simp only [hom_inv_id]

end

end Bicategory

end CategoryTheory

