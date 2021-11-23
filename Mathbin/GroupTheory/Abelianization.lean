import Mathbin.GroupTheory.QuotientGroup 
import Mathbin.Tactic.Group

/-!
# The abelianization of a group

This file defines the commutator and the abelianization of a group. It furthermore prepares for the
result that the abelianization is left adjoint to the forgetful functor from abelian groups to
groups, which can be found in `algebra/category/Group/adjunctions`.

## Main definitions

* `commutator`: defines the commutator of a group `G` as a subgroup of `G`.
* `abelianization`: defines the abelianization of a group `G` as the quotient of a group by its
  commutator subgroup.
-/


universe u v

variable(G : Type u)[Groupₓ G]

-- error in GroupTheory.Abelianization: ././Mathport/Syntax/Translate/Basic.lean:704:9: unsupported derive handler subgroup.normal
/-- The commutator subgroup of a group G is the normal subgroup
  generated by the commutators [p,q]=`p*q*p⁻¹*q⁻¹`. -/ @[derive #[expr subgroup.normal]] def commutator : subgroup G :=
subgroup.normal_closure {x | «expr∃ , »((p
  q), «expr = »(«expr * »(«expr * »(«expr * »(p, q), «expr ⁻¹»(p)), «expr ⁻¹»(q)), x))}

/-- The abelianization of G is the quotient of G by its commutator subgroup. -/
def Abelianization : Type u :=
  QuotientGroup.Quotient (commutator G)

namespace Abelianization

attribute [local instance] QuotientGroup.leftRel

instance  : CommGroupₓ (Abelianization G) :=
  { QuotientGroup.Quotient.group _ with
    mul_comm :=
      fun x y =>
        Quotientₓ.induction_on₂' x y$
          fun a b =>
            by 
              apply Quotientₓ.sound 
              apply Subgroup.subset_normal_closure 
              use b⁻¹
              use a⁻¹
              group }

instance  : Inhabited (Abelianization G) :=
  ⟨1⟩

variable{G}

/-- `of` is the canonical projection from G to its abelianization. -/
def of : G →* Abelianization G :=
  { toFun := QuotientGroup.mk, map_one' := rfl, map_mul' := fun x y => rfl }

section lift

variable{A : Type v}[CommGroupₓ A](f : G →* A)

theorem commutator_subset_ker : commutator G ≤ f.ker :=
  by 
    apply Subgroup.normal_closure_le_normal 
    rintro x ⟨p, q, rfl⟩
    simp [MonoidHom.mem_ker, mul_right_commₓ (f p) (f q)]

/-- If `f : G → A` is a group homomorphism to an abelian group, then `lift f` is the unique map from
  the abelianization of a `G` to `A` that factors through `f`. -/
def lift : (G →* A) ≃ (Abelianization G →* A) :=
  { toFun := fun f => QuotientGroup.lift _ f fun x h => f.mem_ker.2$ commutator_subset_ker _ h,
    invFun := fun F => F.comp of, left_inv := fun f => MonoidHom.ext$ fun x => rfl,
    right_inv := fun F => MonoidHom.ext$ fun x => QuotientGroup.induction_on x$ fun z => rfl }

@[simp]
theorem lift.of (x : G) : lift f (of x) = f x :=
  rfl

theorem lift.unique (φ : Abelianization G →* A) (hφ : ∀ x : G, φ (of x) = f x) {x : Abelianization G} :
  φ x = lift f x :=
  QuotientGroup.induction_on x hφ

end lift

variable{A : Type v}[Monoidₓ A]

/-- See note [partially-applied ext lemmas]. -/
@[ext]
theorem hom_ext (φ ψ : Abelianization G →* A) (h : φ.comp of = ψ.comp of) : φ = ψ :=
  MonoidHom.ext$ fun x => QuotientGroup.induction_on x$ MonoidHom.congr_fun h

end Abelianization

