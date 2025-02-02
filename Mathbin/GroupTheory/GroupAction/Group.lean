/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import Mathbin.Algebra.Hom.Aut
import Mathbin.GroupTheory.GroupAction.Units

/-!
# Group actions applied to various types of group

This file contains lemmas about `smul` on `group_with_zero`, and `group`.
-/


universe u v w

variable {α : Type u} {β : Type v} {γ : Type w}

section MulAction

/-- `monoid.to_mul_action` is faithful on cancellative monoids. -/
@[to_additive " `add_monoid.to_add_action` is faithful on additive cancellative monoids. "]
instance RightCancelMonoid.to_has_faithful_smul [RightCancelMonoid α] : HasFaithfulSmul α α :=
  ⟨fun x y h => mul_right_cancelₓ (h 1)⟩

section Groupₓ

variable [Groupₓ α] [MulAction α β]

@[simp, to_additive]
theorem inv_smul_smul (c : α) (x : β) : c⁻¹ • c • x = x := by
  rw [smul_smul, mul_left_invₓ, one_smul]

@[simp, to_additive]
theorem smul_inv_smul (c : α) (x : β) : c • c⁻¹ • x = x := by
  rw [smul_smul, mul_right_invₓ, one_smul]

/-- Given an action of a group `α` on `β`, each `g : α` defines a permutation of `β`. -/
@[to_additive, simps]
def MulAction.toPerm (a : α) : Equivₓ.Perm β :=
  ⟨fun x => a • x, fun x => a⁻¹ • x, inv_smul_smul a, smul_inv_smul a⟩

-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:51:50: missing argument
-- ./././Mathport/Syntax/Translate/Command.lean:665:43: in add_decl_doc #[[ident add_action.to_perm]]: ./././Mathport/Syntax/Translate/Tactic/Basic.lean:54:35: expecting parse arg
/-- `mul_action.to_perm` is injective on faithful actions. -/
@[to_additive "`add_action.to_perm` is injective on faithful actions."]
theorem MulAction.to_perm_injective [HasFaithfulSmul α β] : Function.Injective (MulAction.toPerm : α → Equivₓ.Perm β) :=
  (show Function.Injective (Equivₓ.toFun ∘ MulAction.toPerm) from smul_left_injective').of_comp

variable (α) (β)

/-- Given an action of a group `α` on a set `β`, each `g : α` defines a permutation of `β`. -/
@[simps]
def MulAction.toPermHom : α →* Equivₓ.Perm β where
  toFun := MulAction.toPerm
  map_one' := Equivₓ.ext <| one_smul α
  map_mul' := fun u₁ u₂ => Equivₓ.ext <| mul_smul (u₁ : α) u₂

/-- Given an action of a additive group `α` on a set `β`, each `g : α` defines a permutation of
`β`. -/
@[simps]
def AddAction.toPermHom (α : Type _) [AddGroupₓ α] [AddAction α β] : α →+ Additive (Equivₓ.Perm β) where
  toFun := fun a => Additive.ofMul <| AddAction.toPerm a
  map_zero' := Equivₓ.ext <| zero_vadd α
  map_add' := fun a₁ a₂ => Equivₓ.ext <| add_vadd a₁ a₂

/-- The tautological action by `equiv.perm α` on `α`.

This generalizes `function.End.apply_mul_action`.-/
instance Equivₓ.Perm.applyMulAction (α : Type _) : MulAction (Equivₓ.Perm α) α where
  smul := fun f a => f a
  one_smul := fun _ => rfl
  mul_smul := fun _ _ _ => rfl

@[simp]
protected theorem Equivₓ.Perm.smul_def {α : Type _} (f : Equivₓ.Perm α) (a : α) : f • a = f a :=
  rfl

/-- `equiv.perm.apply_mul_action` is faithful. -/
instance Equivₓ.Perm.apply_has_faithful_smul (α : Type _) : HasFaithfulSmul (Equivₓ.Perm α) α :=
  ⟨fun x y => Equivₓ.ext⟩

variable {α} {β}

@[to_additive]
theorem inv_smul_eq_iff {a : α} {x y : β} : a⁻¹ • x = y ↔ x = a • y :=
  (MulAction.toPerm a).symm_apply_eq

@[to_additive]
theorem eq_inv_smul_iff {a : α} {x y : β} : x = a⁻¹ • y ↔ a • x = y :=
  (MulAction.toPerm a).eq_symm_apply

theorem smul_inv [Groupₓ β] [SmulCommClass α β β] [IsScalarTower α β β] (c : α) (x : β) : (c • x)⁻¹ = c⁻¹ • x⁻¹ := by
  rw [inv_eq_iff_mul_eq_one, smul_mul_smul, mul_right_invₓ, mul_right_invₓ, one_smul]

theorem smul_zpow [Groupₓ β] [SmulCommClass α β β] [IsScalarTower α β β] (c : α) (x : β) (p : ℤ) :
    (c • x) ^ p = c ^ p • x ^ p := by
  cases p <;> simp [smul_pow, smul_inv]

@[simp]
theorem Commute.smul_right_iff [Mul β] [SmulCommClass α β β] [IsScalarTower α β β] {a b : β} (r : α) :
    Commute a (r • b) ↔ Commute a b :=
  ⟨fun h => inv_smul_smul r b ▸ h.smul_right r⁻¹, fun h => h.smul_right r⟩

@[simp]
theorem Commute.smul_left_iff [Mul β] [SmulCommClass α β β] [IsScalarTower α β β] {a b : β} (r : α) :
    Commute (r • a) b ↔ Commute a b := by
  rw [Commute.symm_iff, Commute.smul_right_iff, Commute.symm_iff]

@[to_additive]
protected theorem MulAction.bijective (g : α) : Function.Bijective fun b : β => g • b :=
  (MulAction.toPerm g).Bijective

@[to_additive]
protected theorem MulAction.injective (g : α) : Function.Injective fun b : β => g • b :=
  (MulAction.bijective g).Injective

@[to_additive]
theorem smul_left_cancel (g : α) {x y : β} (h : g • x = g • y) : x = y :=
  MulAction.injective g h

@[simp, to_additive]
theorem smul_left_cancel_iff (g : α) {x y : β} : g • x = g • y ↔ x = y :=
  (MulAction.injective g).eq_iff

@[to_additive]
theorem smul_eq_iff_eq_inv_smul (g : α) {x y : β} : g • x = y ↔ x = g⁻¹ • y :=
  (MulAction.toPerm g).apply_eq_iff_eq_symm_apply

end Groupₓ

/-- `monoid.to_mul_action` is faithful on nontrivial cancellative monoids with zero. -/
instance CancelMonoidWithZero.to_has_faithful_smul [CancelMonoidWithZero α] [Nontrivial α] : HasFaithfulSmul α α :=
  ⟨fun x y h => mul_left_injective₀ one_ne_zero (h 1)⟩

section Gwz

variable [GroupWithZeroₓ α] [MulAction α β]

@[simp]
theorem inv_smul_smul₀ {c : α} (hc : c ≠ 0) (x : β) : c⁻¹ • c • x = x :=
  inv_smul_smul (Units.mk0 c hc) x

@[simp]
theorem smul_inv_smul₀ {c : α} (hc : c ≠ 0) (x : β) : c • c⁻¹ • x = x :=
  smul_inv_smul (Units.mk0 c hc) x

theorem inv_smul_eq_iff₀ {a : α} (ha : a ≠ 0) {x y : β} : a⁻¹ • x = y ↔ x = a • y :=
  (MulAction.toPerm (Units.mk0 a ha)).symm_apply_eq

theorem eq_inv_smul_iff₀ {a : α} (ha : a ≠ 0) {x y : β} : x = a⁻¹ • y ↔ a • x = y :=
  (MulAction.toPerm (Units.mk0 a ha)).eq_symm_apply

@[simp]
theorem Commute.smul_right_iff₀ [Mul β] [SmulCommClass α β β] [IsScalarTower α β β] {a b : β} {c : α} (hc : c ≠ 0) :
    Commute a (c • b) ↔ Commute a b :=
  Commute.smul_right_iff (Units.mk0 c hc)

@[simp]
theorem Commute.smul_left_iff₀ [Mul β] [SmulCommClass α β β] [IsScalarTower α β β] {a b : β} {c : α} (hc : c ≠ 0) :
    Commute (c • a) b ↔ Commute a b :=
  Commute.smul_left_iff (Units.mk0 c hc)

end Gwz

end MulAction

section DistribMulAction

section Groupₓ

variable [Groupₓ α] [AddMonoidₓ β] [DistribMulAction α β]

variable (β)

/-- Each element of the group defines an additive monoid isomorphism.

This is a stronger version of `mul_action.to_perm`. -/
@[simps (config := { simpRhs := true })]
def DistribMulAction.toAddEquiv (x : α) : β ≃+ β :=
  { DistribMulAction.toAddMonoidHom β x, MulAction.toPermHom α β x with }

variable (α β)

/-- Each element of the group defines an additive monoid isomorphism.

This is a stronger version of `mul_action.to_perm_hom`. -/
@[simps]
def DistribMulAction.toAddAut : α →* AddAut β where
  toFun := DistribMulAction.toAddEquiv β
  map_one' := AddEquiv.ext (one_smul _)
  map_mul' := fun a₁ a₂ => AddEquiv.ext (mul_smul _ _)

variable {α β}

theorem smul_eq_zero_iff_eq (a : α) {x : β} : a • x = 0 ↔ x = 0 :=
  ⟨fun h => by
    rw [← inv_smul_smul a x, h, smul_zero], fun h => h.symm ▸ smul_zero _⟩

theorem smul_ne_zero_iff_ne (a : α) {x : β} : a • x ≠ 0 ↔ x ≠ 0 :=
  not_congr <| smul_eq_zero_iff_eq a

end Groupₓ

section Gwz

variable [GroupWithZeroₓ α] [AddMonoidₓ β] [DistribMulAction α β]

theorem smul_eq_zero_iff_eq' {a : α} (ha : a ≠ 0) {x : β} : a • x = 0 ↔ x = 0 :=
  smul_eq_zero_iff_eq (Units.mk0 a ha)

theorem smul_ne_zero_iff_ne' {a : α} (ha : a ≠ 0) {x : β} : a • x ≠ 0 ↔ x ≠ 0 :=
  smul_ne_zero_iff_ne (Units.mk0 a ha)

end Gwz

end DistribMulAction

section MulDistribMulAction

variable [Groupₓ α] [Monoidₓ β] [MulDistribMulAction α β]

variable (β)

/-- Each element of the group defines a multiplicative monoid isomorphism.

This is a stronger version of `mul_action.to_perm`. -/
@[simps (config := { simpRhs := true })]
def MulDistribMulAction.toMulEquiv (x : α) : β ≃* β :=
  { MulDistribMulAction.toMonoidHom β x, MulAction.toPermHom α β x with }

variable (α β)

/-- Each element of the group defines an multiplicative monoid isomorphism.

This is a stronger version of `mul_action.to_perm_hom`. -/
@[simps]
def MulDistribMulAction.toMulAut : α →* MulAut β where
  toFun := MulDistribMulAction.toMulEquiv β
  map_one' := MulEquiv.ext (one_smul _)
  map_mul' := fun a₁ a₂ => MulEquiv.ext (mul_smul _ _)

variable {α β}

end MulDistribMulAction

section Arrow

/-- If `G` acts on `A`, then it acts also on `A → B`, by `(g • F) a = F (g⁻¹ • a)`. -/
@[to_additive arrowAddAction "If `G` acts on `A`, then it acts also on `A → B`, by\n`(g +ᵥ F) a = F (g⁻¹ +ᵥ a)`", simps]
def arrowAction {G A B : Type _} [DivisionMonoid G] [MulAction G A] : MulAction G (A → B) where
  smul := fun g F a => F (g⁻¹ • a)
  one_smul := by
    intro
    simp only [inv_one, one_smul]
  mul_smul := by
    intros
    simp only [mul_smul, mul_inv_rev]

attribute [local instance] arrowAction

/-- When `B` is a monoid, `arrow_action` is additionally a `mul_distrib_mul_action`. -/
def arrowMulDistribMulAction {G A B : Type _} [Groupₓ G] [MulAction G A] [Monoidₓ B] :
    MulDistribMulAction G (A → B) where
  smul_one := fun g => rfl
  smul_mul := fun g f₁ f₂ => rfl

attribute [local instance] arrowMulDistribMulAction

/-- Given groups `G H` with `G` acting on `A`, `G` acts by
  multiplicative automorphisms on `A → H`. -/
@[simps]
def mulAutArrow {G A H} [Groupₓ G] [MulAction G A] [Monoidₓ H] : G →* MulAut (A → H) :=
  MulDistribMulAction.toMulAut _ _

end Arrow

namespace IsUnit

section MulAction

variable [Monoidₓ α] [MulAction α β]

@[to_additive]
theorem smul_left_cancel {a : α} (ha : IsUnit a) {x y : β} : a • x = a • y ↔ x = y :=
  let ⟨u, hu⟩ := ha
  hu ▸ smul_left_cancel_iff u

end MulAction

section DistribMulAction

variable [Monoidₓ α] [AddMonoidₓ β] [DistribMulAction α β]

@[simp]
theorem smul_eq_zero {u : α} (hu : IsUnit u) {x : β} : u • x = 0 ↔ x = 0 :=
  (Exists.elim hu) fun u hu => hu ▸ smul_eq_zero_iff_eq u

end DistribMulAction

end IsUnit

section Smul

variable [Groupₓ α] [Monoidₓ β]

@[simp]
theorem is_unit_smul_iff [MulAction α β] [SmulCommClass α β β] [IsScalarTower α β β] (g : α) (m : β) :
    IsUnit (g • m) ↔ IsUnit m :=
  ⟨fun h => inv_smul_smul g m ▸ h.smul g⁻¹, IsUnit.smul g⟩

theorem IsUnit.smul_sub_iff_sub_inv_smul [AddGroupₓ β] [DistribMulAction α β] [IsScalarTower α β β]
    [SmulCommClass α β β] (r : α) (a : β) : IsUnit (r • 1 - a) ↔ IsUnit (1 - r⁻¹ • a) := by
  rw [← is_unit_smul_iff r (1 - r⁻¹ • a), smul_sub, smul_inv_smul]

end Smul

