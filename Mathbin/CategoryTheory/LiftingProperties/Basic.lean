/-
Copyright (c) 2021 Jakob Scholbach. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jakob Scholbach, Joël Riou
-/
import Mathbin.CategoryTheory.CommSq

/-!
# Lifting properties

This file defines the lifting property of two morphisms in a category and
shows basic properties of this notion.

## Main results
- `has_lifting_property`: the definition of the lifting property

## Tags
lifting property

@TODO :
1) define llp/rlp with respect to a `morphism_property`
2) retracts, direct/inverse images, (co)products, adjunctions

-/


universe v

namespace CategoryTheory

open Category

variable {C : Type _} [Category C] {A B B' X Y Y' : C} (i : A ⟶ B) (i' : B ⟶ B') (p : X ⟶ Y) (p' : Y ⟶ Y')

/-- `has_lifting_property i p` means that `i` has the left lifting
property with respect to `p`, or equivalently that `p` has
the right lifting property with respect to `i`. -/
class HasLiftingProperty : Prop where
  sq_has_lift : ∀ {f : A ⟶ X} {g : B ⟶ Y} (sq : CommSq f i p g), sq.HasLift

instance (priority := 100) sq_has_lift_of_has_lifting_property {f : A ⟶ X} {g : B ⟶ Y} (sq : CommSq f i p g)
    [hip : HasLiftingProperty i p] : sq.HasLift := by
  apply hip.sq_has_lift

namespace HasLiftingProperty

variable {i p}

theorem op (h : HasLiftingProperty i p) : HasLiftingProperty p.op i.op :=
  ⟨fun f g sq => by
    simp only [comm_sq.has_lift.iff_unop, Quiver.Hom.unop_op]
    infer_instance⟩

theorem unop {A B X Y : Cᵒᵖ} {i : A ⟶ B} {p : X ⟶ Y} (h : HasLiftingProperty i p) : HasLiftingProperty p.unop i.unop :=
  ⟨fun f g sq => by
    rw [comm_sq.has_lift.iff_op]
    simp only [Quiver.Hom.op_unop]
    infer_instance⟩

theorem iff_op : HasLiftingProperty i p ↔ HasLiftingProperty p.op i.op :=
  ⟨op, unop⟩

theorem iff_unop {A B X Y : Cᵒᵖ} (i : A ⟶ B) (p : X ⟶ Y) : HasLiftingProperty i p ↔ HasLiftingProperty p.unop i.unop :=
  ⟨unop, op⟩

variable (i p)

instance (priority := 100) of_left_iso [IsIso i] : HasLiftingProperty i p :=
  ⟨fun f g sq =>
    CommSq.HasLift.mk'
      { l := inv i ≫ f,
        fac_left' := by
          simp only [is_iso.hom_inv_id_assoc],
        fac_right' := by
          simp only [sq.w, assoc, is_iso.inv_hom_id_assoc] }⟩

instance (priority := 100) of_right_iso [IsIso p] : HasLiftingProperty i p :=
  ⟨fun f g sq =>
    CommSq.HasLift.mk'
      { l := g ≫ inv p,
        fac_left' := by
          simp only [← sq.w_assoc, is_iso.hom_inv_id, comp_id],
        fac_right' := by
          simp only [assoc, is_iso.inv_hom_id, comp_id] }⟩

instance of_comp_left [HasLiftingProperty i p] [HasLiftingProperty i' p] : HasLiftingProperty (i ≫ i') p :=
  ⟨fun f g sq => by
    have fac := sq.w
    rw [assoc] at fac
    exact
      comm_sq.has_lift.mk'
        { l := (comm_sq.mk (comm_sq.mk fac).fac_right).lift,
          fac_left' := by
            simp only [assoc, comm_sq.fac_left],
          fac_right' := by
            simp only [comm_sq.fac_right] }⟩

instance of_comp_right [HasLiftingProperty i p] [HasLiftingProperty i p'] : HasLiftingProperty i (p ≫ p') :=
  ⟨fun f g sq => by
    have fac := sq.w
    rw [← assoc] at fac
    let sq₂ := (comm_sq.mk (comm_sq.mk fac).fac_left.symm).lift
    exact
      comm_sq.has_lift.mk'
        { l := (comm_sq.mk (comm_sq.mk fac).fac_left.symm).lift,
          fac_left' := by
            simp only [comm_sq.fac_left],
          fac_right' := by
            simp only [comm_sq.fac_right_assoc, comm_sq.fac_right] }⟩

theorem of_arrow_iso_left {A B A' B' X Y : C} {i : A ⟶ B} {i' : A' ⟶ B'} (e : Arrow.mk i ≅ Arrow.mk i') (p : X ⟶ Y)
    [hip : HasLiftingProperty i p] : HasLiftingProperty i' p := by
  rw [arrow.iso_w' e]
  infer_instance

theorem of_arrow_iso_right {A B X Y X' Y' : C} (i : A ⟶ B) {p : X ⟶ Y} {p' : X' ⟶ Y'} (e : Arrow.mk p ≅ Arrow.mk p')
    [hip : HasLiftingProperty i p] : HasLiftingProperty i p' := by
  rw [arrow.iso_w' e]
  infer_instance

theorem iff_of_arrow_iso_left {A B A' B' X Y : C} {i : A ⟶ B} {i' : A' ⟶ B'} (e : Arrow.mk i ≅ Arrow.mk i')
    (p : X ⟶ Y) : HasLiftingProperty i p ↔ HasLiftingProperty i' p := by
  constructor <;> intro
  exacts[of_arrow_iso_left e p, of_arrow_iso_left e.symm p]

theorem iff_of_arrow_iso_right {A B X Y X' Y' : C} (i : A ⟶ B) {p : X ⟶ Y} {p' : X' ⟶ Y'}
    (e : Arrow.mk p ≅ Arrow.mk p') : HasLiftingProperty i p ↔ HasLiftingProperty i p' := by
  constructor <;> intro
  exacts[of_arrow_iso_right i e, of_arrow_iso_right i e.symm]

end HasLiftingProperty

end CategoryTheory

