import Mathbin.Order.Filter.Ultrafilter 
import Mathbin.Order.Filter.Germ

/-!
# Ultraproducts

If `φ` is an ultrafilter, then the space of germs of functions `f : α → β` at `φ` is called
the *ultraproduct*. In this file we prove properties of ultraproducts that rely on `φ` being an
ultrafilter. Definitions and properties that work for any filter should go to `order.filter.germ`.

## Tags

ultrafilter, ultraproduct
-/


universe u v

variable {α : Type u} {β : Type v} {φ : Ultrafilter α}

open_locale Classical

namespace Filter

local notation3 "∀* " (...) ", " r:(scoped p => Filter.Eventually p φ) => r

namespace Germ

open Ultrafilter

local notation "β*" => germ (φ : Filter α) β

/-- If `φ` is an ultrafilter then the ultraproduct is a division ring. -/
instance [DivisionRing β] : DivisionRing β* :=
  { germ.ring, germ.div_inv_monoid, germ.nontrivial with
    mul_inv_cancel :=
      fun f =>
        induction_on f$
          fun f hf =>
            coe_eq.2$
              (φ.em fun y => f y = 0).elim (fun H => (hf$ coe_eq.2 H).elim) fun H => H.mono$ fun x => mul_inv_cancel,
    inv_zero :=
      coe_eq.2$
        by 
          simp only [· ∘ ·, inv_zero] }

/-- If `φ` is an ultrafilter then the ultraproduct is a field. -/
instance [Field β] : Field β* :=
  { germ.comm_ring, germ.division_ring with  }

/-- If `φ` is an ultrafilter then the ultraproduct is a linear order. -/
noncomputable instance [LinearOrderₓ β] : LinearOrderₓ β* :=
  { germ.partial_order with
    le_total := fun f g => induction_on₂ f g$ fun f g => eventually_or.1$ eventually_of_forall$ fun x => le_totalₓ _ _,
    decidableLe :=
      by 
        infer_instance }

@[simp, normCast]
theorem const_div [DivisionRing β] (x y : β) : (↑(x / y) : β*) = ↑x / ↑y :=
  rfl

theorem coe_lt [Preorderₓ β] {f g : α → β} : (f : β*) < g ↔ ∀* x, f x < g x :=
  by 
    simp only [lt_iff_le_not_leₓ, eventually_and, coe_le, eventually_not, eventually_le]

theorem coe_pos [Preorderₓ β] [HasZero β] {f : α → β} : 0 < (f : β*) ↔ ∀* x, 0 < f x :=
  coe_lt

theorem const_lt [Preorderₓ β] {x y : β} : (↑x : β*) < ↑y ↔ x < y :=
  coe_lt.trans lift_rel_const_iff

theorem lt_def [Preorderₓ β] : (· < · : β* → β* → Prop) = lift_rel (· < ·) :=
  by 
    ext ⟨f⟩ ⟨g⟩
    exact coe_lt

/-- If `φ` is an ultrafilter then the ultraproduct is an ordered ring. -/
instance [OrderedRing β] : OrderedRing β* :=
  { germ.ring, germ.ordered_add_comm_group, germ.nontrivial with zero_le_one := const_le zero_le_one,
    mul_pos :=
      fun x y =>
        induction_on₂ x y$ fun f g hf hg => coe_pos.2$ (coe_pos.1 hg).mp$ (coe_pos.1 hf).mono$ fun x => mul_pos }

/-- If `φ` is an ultrafilter then the ultraproduct is a linear ordered ring. -/
noncomputable instance [LinearOrderedRing β] : LinearOrderedRing β* :=
  { germ.ordered_ring, germ.linear_order, germ.nontrivial with  }

/-- If `φ` is an ultrafilter then the ultraproduct is a linear ordered field. -/
noncomputable instance [LinearOrderedField β] : LinearOrderedField β* :=
  { germ.linear_ordered_ring, germ.field with  }

/-- If `φ` is an ultrafilter then the ultraproduct is a linear ordered commutative ring. -/
noncomputable instance [LinearOrderedCommRing β] : LinearOrderedCommRing β* :=
  { germ.linear_ordered_ring, germ.comm_monoid with  }

/-- If `φ` is an ultrafilter then the ultraproduct is a decidable linear ordered commutative
group. -/
noncomputable instance [LinearOrderedAddCommGroup β] : LinearOrderedAddCommGroup β* :=
  { germ.ordered_add_comm_group, germ.linear_order with  }

theorem max_def [LinearOrderₓ β] (x y : β*) : max x y = map₂ max x y :=
  induction_on₂ x y$
    fun a b =>
      by 
        cases le_totalₓ (a : β*) b
        ·
          rw [max_eq_rightₓ h, map₂_coe, coe_eq]
          exact h.mono fun i hi => (max_eq_rightₓ hi).symm
        ·
          rw [max_eq_leftₓ h, map₂_coe, coe_eq]
          exact h.mono fun i hi => (max_eq_leftₓ hi).symm

theorem min_def [K : LinearOrderₓ β] (x y : β*) : min x y = map₂ min x y :=
  induction_on₂ x y$
    fun a b =>
      by 
        cases le_totalₓ (a : β*) b
        ·
          rw [min_eq_leftₓ h, map₂_coe, coe_eq]
          exact h.mono fun i hi => (min_eq_leftₓ hi).symm
        ·
          rw [min_eq_rightₓ h, map₂_coe, coe_eq]
          exact h.mono fun i hi => (min_eq_rightₓ hi).symm

theorem abs_def [LinearOrderedAddCommGroup β] (x : β*) : |x| = map abs x :=
  induction_on x$
    fun a =>
      by 
        exact rfl

@[simp]
theorem const_max [LinearOrderₓ β] (x y : β) : (↑(max x y : β) : β*) = max (↑x) (↑y) :=
  by 
    rw [max_def, map₂_const]

@[simp]
theorem const_min [LinearOrderₓ β] (x y : β) : (↑(min x y : β) : β*) = min (↑x) (↑y) :=
  by 
    rw [min_def, map₂_const]

@[simp]
theorem const_abs [LinearOrderedAddCommGroup β] (x : β) : (↑|x| : β*) = |↑x| :=
  by 
    rw [abs_def, map_const]

theorem lattice_of_linear_order_eq_filter_germ_lattice [LinearOrderₓ β] :
  @latticeOfLinearOrder (Filter.Germ (↑φ) β) Filter.Germ.linearOrder = Filter.Germ.lattice :=
  Lattice.ext fun x y => Iff.rfl

end Germ

end Filter

