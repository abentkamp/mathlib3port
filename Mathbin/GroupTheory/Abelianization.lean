/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Michael Howes
-/
import Mathbin.GroupTheory.Commutator
import Mathbin.GroupTheory.QuotientGroup

/-!
# The abelianization of a group

This file defines the commutator and the abelianization of a group. It furthermore prepares for the
result that the abelianization is left adjoint to the forgetful functor from abelian groups to
groups, which can be found in `algebra/category/Group/adjunctions`.

## Main definitions

* `commutator`: defines the commutator of a group `G` as a subgroup of `G`.
* `abelianization`: defines the abelianization of a group `G` as the quotient of a group by its
  commutator subgroup.
* `abelianization.map`: lifts a group homomorphism to a homomorphism between the abelianizations
* `mul_equiv.abelianization_congr`: Equivalent groups have equivalent abelianizations

-/


universe u v w

-- Let G be a group.
variable (G : Type u) [Groupₓ G]

/-- The commutator subgroup of a group G is the normal subgroup
  generated by the commutators [p,q]=`p*q*p⁻¹*q⁻¹`. -/
def commutator : Subgroup G :=
  ⁅(⊤ : Subgroup G),⊤⁆deriving Subgroup.Normal

theorem commutator_def : commutator G = ⁅(⊤ : Subgroup G),⊤⁆ :=
  rfl

theorem commutator_eq_closure : commutator G = Subgroup.closure { g | ∃ g₁ g₂ : G, ⁅g₁,g₂⁆ = g } := by
  simp_rw [commutator, Subgroup.commutator_def, Subgroup.mem_top, exists_true_left]

theorem commutator_eq_normal_closure : commutator G = Subgroup.normalClosure { g | ∃ g₁ g₂ : G, ⁅g₁,g₂⁆ = g } := by
  simp_rw [commutator, Subgroup.commutator_def', Subgroup.mem_top, exists_true_left]

instance commutator_characteristic : (commutator G).Characteristic :=
  Subgroup.commutator_characteristic ⊤ ⊤

theorem commutator_centralizer_commutator_le_center :
    ⁅(commutator G).Centralizer,(commutator G).Centralizer⁆ ≤ Subgroup.center G := by
  rw [← Subgroup.centralizer_top, ← Subgroup.commutator_eq_bot_iff_le_centralizer]
  suffices ⁅⁅⊤,(commutator G).Centralizer⁆,(commutator G).Centralizer⁆ = ⊥ by
    refine' Subgroup.commutator_commutator_eq_bot_of_rotate _ this
    rwa [Subgroup.commutator_comm (commutator G).Centralizer]
  rw [Subgroup.commutator_comm, Subgroup.commutator_eq_bot_iff_le_centralizer]
  exact Set.centralizer_subset (Subgroup.commutator_mono le_top le_top)

/-- The abelianization of G is the quotient of G by its commutator subgroup. -/
def Abelianization : Type u :=
  G ⧸ commutator G

namespace Abelianization

attribute [local instance] QuotientGroup.leftRel

instance : CommGroupₓ (Abelianization G) :=
  { QuotientGroup.Quotient.group _ with
    mul_comm := fun x y =>
      (Quotientₓ.induction_on₂' x y) fun a b =>
        Quotientₓ.sound' <|
          QuotientGroup.left_rel_apply.mpr <|
            Subgroup.subset_closure
              ⟨b⁻¹, Subgroup.mem_top b⁻¹, a⁻¹, Subgroup.mem_top a⁻¹, by
                group⟩ }

instance : Inhabited (Abelianization G) :=
  ⟨1⟩

instance [Fintype G] [DecidablePred (· ∈ commutator G)] : Fintype (Abelianization G) :=
  QuotientGroup.fintype (commutator G)

variable {G}

/-- `of` is the canonical projection from G to its abelianization. -/
def of : G →* Abelianization G where
  toFun := QuotientGroup.mk
  map_one' := rfl
  map_mul' := fun x y => rfl

@[simp]
theorem mk_eq_of (a : G) : Quot.mk _ a = of a :=
  rfl

section lift

-- So far we have built Gᵃᵇ and proved it's an abelian group.
-- Furthremore we defined the canonical projection `of : G → Gᵃᵇ`
-- Let `A` be an abelian group and let `f` be a group homomorphism from `G` to `A`.
variable {A : Type v} [CommGroupₓ A] (f : G →* A)

theorem commutator_subset_ker : commutator G ≤ f.ker := by
  rw [commutator_eq_closure, Subgroup.closure_le]
  rintro x ⟨p, q, rfl⟩
  simp [MonoidHom.mem_ker, mul_right_commₓ (f p) (f q), commutator_element_def]

/-- If `f : G → A` is a group homomorphism to an abelian group, then `lift f` is the unique map from
  the abelianization of a `G` to `A` that factors through `f`. -/
def lift : (G →* A) ≃ (Abelianization G →* A) where
  toFun := fun f => QuotientGroup.lift _ f fun x h => f.mem_ker.2 <| commutator_subset_ker _ h
  invFun := fun F => F.comp of
  left_inv := fun f => MonoidHom.ext fun x => rfl
  right_inv := fun F => MonoidHom.ext fun x => (QuotientGroup.induction_on x) fun z => rfl

@[simp]
theorem lift.of (x : G) : lift f (of x) = f x :=
  rfl

theorem lift.unique (φ : Abelianization G →* A)
    -- hφ : φ agrees with f on the image of G in Gᵃᵇ
    (hφ : ∀ x : G, φ (of x) = f x)
    {x : Abelianization G} : φ x = lift f x :=
  QuotientGroup.induction_on x hφ

@[simp]
theorem lift_of : lift of = MonoidHom.id (Abelianization G) :=
  lift.apply_symm_apply <| MonoidHom.id _

end lift

variable {A : Type v} [Monoidₓ A]

/-- See note [partially-applied ext lemmas]. -/
@[ext]
theorem hom_ext (φ ψ : Abelianization G →* A) (h : φ.comp of = ψ.comp of) : φ = ψ :=
  MonoidHom.ext fun x => QuotientGroup.induction_on x <| MonoidHom.congr_fun h

section Map

variable {H : Type v} [Groupₓ H] (f : G →* H)

/-- The map operation of the `abelianization` functor -/
def map : Abelianization G →* Abelianization H :=
  lift (of.comp f)

@[simp]
theorem map_of (x : G) : map f (of x) = of (f x) :=
  rfl

@[simp]
theorem map_id : map (MonoidHom.id G) = MonoidHom.id (Abelianization G) :=
  hom_ext _ _ rfl

@[simp]
theorem map_comp {I : Type w} [Groupₓ I] (g : H →* I) : (map g).comp (map f) = map (g.comp f) :=
  hom_ext _ _ rfl

@[simp]
theorem map_map_apply {I : Type w} [Groupₓ I] {g : H →* I} {x : Abelianization G} :
    map g (map f x) = map (g.comp f) x :=
  MonoidHom.congr_fun (map_comp _ _) x

end Map

end Abelianization

section AbelianizationCongr

variable {G} {H : Type v} [Groupₓ H] (e : G ≃* H)

/-- Equivalent groups have equivalent abelianizations -/
def MulEquiv.abelianizationCongr : Abelianization G ≃* Abelianization H where
  toFun := Abelianization.map e.toMonoidHom
  invFun := Abelianization.map e.symm.toMonoidHom
  left_inv := by
    rintro ⟨a⟩
    simp
  right_inv := by
    rintro ⟨a⟩
    simp
  map_mul' := MonoidHom.map_mul _

@[simp]
theorem abelianization_congr_of (x : G) : e.abelianizationCongr (Abelianization.of x) = Abelianization.of (e x) :=
  rfl

@[simp]
theorem abelianization_congr_refl : (MulEquiv.refl G).abelianizationCongr = MulEquiv.refl (Abelianization G) :=
  MulEquiv.to_monoid_hom_injective Abelianization.lift_of

@[simp]
theorem abelianization_congr_symm : e.abelianizationCongr.symm = e.symm.abelianizationCongr :=
  rfl

@[simp]
theorem abelianization_congr_trans {I : Type v} [Groupₓ I] (e₂ : H ≃* I) :
    e.abelianizationCongr.trans e₂.abelianizationCongr = (e.trans e₂).abelianizationCongr :=
  MulEquiv.to_monoid_hom_injective (Abelianization.hom_ext _ _ rfl)

end AbelianizationCongr

/-- An Abelian group is equivalent to its own abelianization. -/
@[simps]
def Abelianization.equivOfComm {H : Type _} [CommGroupₓ H] : H ≃* Abelianization H :=
  { Abelianization.of with toFun := Abelianization.of, invFun := Abelianization.lift (MonoidHom.id H),
    left_inv := fun a => rfl,
    right_inv := by
      rintro ⟨a⟩
      rfl }

