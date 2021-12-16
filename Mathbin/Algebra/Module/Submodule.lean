import Mathbin.Algebra.Module.LinearMap 
import Mathbin.Data.Equiv.Module 
import Mathbin.GroupTheory.GroupAction.SubMulAction

/-!

# Submodules of a module

In this file we define

* `submodule R M` : a subset of a `module` `M` that contains zero and is closed with respect to
  addition and scalar multiplication.

* `subspace k M` : an abbreviation for `submodule` assuming that `k` is a `field`.

## Tags

submodule, subspace, linear map
-/


open Function

open_locale BigOperators

universe u'' u' u v w

variable {G : Type u''} {S : Type u'} {R : Type u} {M : Type v} {ι : Type w}

/-- A submodule of a module is one which is closed under vector operations.
  This is a sufficient condition for the subset of vectors in the submodule
  to themselves form a module. -/
structure Submodule (R : Type u) (M : Type v) [Semiringₓ R] [AddCommMonoidₓ M] [Module R M] extends AddSubmonoid M,
  SubMulAction R M : Type v

/-- Reinterpret a `submodule` as an `add_submonoid`. -/
add_decl_doc Submodule.toAddSubmonoid

/-- Reinterpret a `submodule` as an `sub_mul_action`. -/
add_decl_doc Submodule.toSubMulAction

namespace Submodule

variable [Semiringₓ R] [AddCommMonoidₓ M] [Module R M]

instance : SetLike (Submodule R M) M :=
  ⟨Submodule.Carrier,
    fun p q h =>
      by 
        cases p <;> cases q <;> congr⟩

@[simp]
theorem mem_to_add_submonoid (p : Submodule R M) (x : M) : x ∈ p.to_add_submonoid ↔ x ∈ p :=
  Iff.rfl

variable {p q : Submodule R M}

@[simp]
theorem mem_mk {S : Set M} {x : M} h₁ h₂ h₃ : x ∈ (⟨S, h₁, h₂, h₃⟩ : Submodule R M) ↔ x ∈ S :=
  Iff.rfl

@[simp]
theorem coe_set_mk (S : Set M) h₁ h₂ h₃ : ((⟨S, h₁, h₂, h₃⟩ : Submodule R M) : Set M) = S :=
  rfl

@[simp]
theorem mk_le_mk {S S' : Set M} h₁ h₂ h₃ h₁' h₂' h₃' :
  (⟨S, h₁, h₂, h₃⟩ : Submodule R M) ≤ (⟨S', h₁', h₂', h₃'⟩ : Submodule R M) ↔ S ⊆ S' :=
  Iff.rfl

@[ext]
theorem ext (h : ∀ x, x ∈ p ↔ x ∈ q) : p = q :=
  SetLike.ext h

/-- Copy of a submodule with a new `carrier` equal to the old one. Useful to fix definitional
equalities. -/
protected def copy (p : Submodule R M) (s : Set M) (hs : s = ↑p) : Submodule R M :=
  { Carrier := s, zero_mem' := hs.symm ▸ p.zero_mem', add_mem' := hs.symm ▸ p.add_mem',
    smul_mem' := hs.symm ▸ p.smul_mem' }

@[simp]
theorem coe_copy (S : Submodule R M) (s : Set M) (hs : s = ↑S) : (S.copy s hs : Set M) = s :=
  rfl

theorem copy_eq (S : Submodule R M) (s : Set M) (hs : s = ↑S) : S.copy s hs = S :=
  SetLike.coe_injective hs

theorem to_add_submonoid_injective : injective (to_add_submonoid : Submodule R M → AddSubmonoid M) :=
  fun p q h => SetLike.ext'_iff.2 (show _ from SetLike.ext'_iff.1 h)

@[simp]
theorem to_add_submonoid_eq : p.to_add_submonoid = q.to_add_submonoid ↔ p = q :=
  to_add_submonoid_injective.eq_iff

@[mono]
theorem to_add_submonoid_strict_mono : StrictMono (to_add_submonoid : Submodule R M → AddSubmonoid M) :=
  fun _ _ => id

@[mono]
theorem to_add_submonoid_mono : Monotone (to_add_submonoid : Submodule R M → AddSubmonoid M) :=
  to_add_submonoid_strict_mono.Monotone

@[simp]
theorem coe_to_add_submonoid (p : Submodule R M) : (p.to_add_submonoid : Set M) = p :=
  rfl

theorem to_sub_mul_action_injective : injective (to_sub_mul_action : Submodule R M → SubMulAction R M) :=
  fun p q h => SetLike.ext'_iff.2 (show _ from SetLike.ext'_iff.1 h)

@[simp]
theorem to_sub_mul_action_eq : p.to_sub_mul_action = q.to_sub_mul_action ↔ p = q :=
  to_sub_mul_action_injective.eq_iff

@[mono]
theorem to_sub_mul_action_strict_mono : StrictMono (to_sub_mul_action : Submodule R M → SubMulAction R M) :=
  fun _ _ => id

@[mono]
theorem to_sub_mul_action_mono : Monotone (to_sub_mul_action : Submodule R M → SubMulAction R M) :=
  to_sub_mul_action_strict_mono.Monotone

@[simp]
theorem coe_to_sub_mul_action (p : Submodule R M) : (p.to_sub_mul_action : Set M) = p :=
  rfl

end Submodule

namespace Submodule

section AddCommMonoidₓ

variable [Semiringₓ R] [AddCommMonoidₓ M]

variable {module_M : Module R M}

variable {p q : Submodule R M}

variable {r : R} {x y : M}

variable (p)

@[simp]
theorem mem_carrier : x ∈ p.carrier ↔ x ∈ (p : Set M) :=
  Iff.rfl

@[simp]
theorem zero_mem : (0 : M) ∈ p :=
  p.zero_mem'

theorem add_mem (h₁ : x ∈ p) (h₂ : y ∈ p) : (x+y) ∈ p :=
  p.add_mem' h₁ h₂

theorem smul_mem (r : R) (h : x ∈ p) : r • x ∈ p :=
  p.smul_mem' r h

theorem smul_of_tower_mem [HasScalar S R] [HasScalar S M] [IsScalarTower S R M] (r : S) (h : x ∈ p) : r • x ∈ p :=
  p.to_sub_mul_action.smul_of_tower_mem r h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » t)
theorem sum_mem {t : Finset ι} {f : ι → M} : (∀ c _ : c ∈ t, f c ∈ p) → (∑ i in t, f i) ∈ p :=
  p.to_add_submonoid.sum_mem

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » t)
theorem sum_smul_mem {t : Finset ι} {f : ι → M} (r : ι → R) (hyp : ∀ c _ : c ∈ t, f c ∈ p) :
  (∑ i in t, r i • f i) ∈ p :=
  Submodule.sum_mem _ fun i hi => Submodule.smul_mem _ _ (hyp i hi)

@[simp]
theorem smul_mem_iff' [Groupₓ G] [MulAction G M] [HasScalar G R] [IsScalarTower G R M] (g : G) : g • x ∈ p ↔ x ∈ p :=
  p.to_sub_mul_action.smul_mem_iff' g

instance : Add p :=
  ⟨fun x y => ⟨x.1+y.1, add_mem _ x.2 y.2⟩⟩

instance : HasZero p :=
  ⟨⟨0, zero_mem _⟩⟩

instance : Inhabited p :=
  ⟨0⟩

instance [HasScalar S R] [HasScalar S M] [IsScalarTower S R M] : HasScalar S p :=
  ⟨fun c x => ⟨c • x.1, smul_of_tower_mem _ c x.2⟩⟩

instance [HasScalar S R] [HasScalar S M] [IsScalarTower S R M] : IsScalarTower S R p :=
  p.to_sub_mul_action.is_scalar_tower

instance [HasScalar S R] [HasScalar S M] [IsScalarTower S R M] [HasScalar (Sᵐᵒᵖ) R] [HasScalar (Sᵐᵒᵖ) M]
  [IsScalarTower (Sᵐᵒᵖ) R M] [IsCentralScalar S M] : IsCentralScalar S p :=
  p.to_sub_mul_action.is_central_scalar

protected theorem Nonempty : (p : Set M).Nonempty :=
  ⟨0, p.zero_mem⟩

@[simp]
theorem mk_eq_zero {x} (h : x ∈ p) : (⟨x, h⟩ : p) = 0 ↔ x = 0 :=
  Subtype.ext_iff_val

variable {p}

@[simp, normCast]
theorem coe_eq_zero {x : p} : (x : M) = 0 ↔ x = 0 :=
  (SetLike.coe_eq_coe : (x : M) = (0 : p) ↔ x = 0)

@[simp, normCast]
theorem coe_add (x y : p) : (↑x+y : M) = (↑x)+↑y :=
  rfl

@[simp, normCast]
theorem coe_zero : ((0 : p) : M) = 0 :=
  rfl

@[normCast]
theorem coe_smul (r : R) (x : p) : ((r • x : p) : M) = r • ↑x :=
  rfl

@[simp, normCast]
theorem coe_smul_of_tower [HasScalar S R] [HasScalar S M] [IsScalarTower S R M] (r : S) (x : p) :
  ((r • x : p) : M) = r • ↑x :=
  rfl

@[simp, normCast]
theorem coe_mk (x : M) (hx : x ∈ p) : ((⟨x, hx⟩ : p) : M) = x :=
  rfl

@[simp]
theorem coe_mem (x : p) : (x : M) ∈ p :=
  x.2

variable (p)

instance : AddCommMonoidₓ p :=
  { p.to_add_submonoid.to_add_comm_monoid with add := ·+·, zero := 0 }

instance module' [Semiringₓ S] [HasScalar S R] [Module S M] [IsScalarTower S R M] : Module S p :=
  by 
    refine' { p.to_sub_mul_action.mul_action' with smul := · • ·, .. } <;>
      ·
        intros 
        apply SetCoe.ext 
        simp [smul_add, add_smul, mul_smul]

instance : Module R p :=
  p.module'

instance NoZeroSmulDivisors [NoZeroSmulDivisors R M] : NoZeroSmulDivisors R p :=
  ⟨fun c x h =>
      have  : c = 0 ∨ (x : M) = 0 := eq_zero_or_eq_zero_of_smul_eq_zero (congr_argₓ coeₓ h)
      this.imp_right (@Subtype.ext_iff _ _ x 0).mpr⟩

/-- Embedding of a submodule `p` to the ambient space `M`. -/
protected def Subtype : p →ₗ[R] M :=
  by 
    refine' { toFun := coeₓ, .. } <;> simp [coe_smul]

@[simp]
theorem subtype_apply (x : p) : p.subtype x = x :=
  rfl

theorem subtype_eq_val : (Submodule.subtype p : p → M) = Subtype.val :=
  rfl

/-- Note the `add_submonoid` version of this lemma is called `add_submonoid.coe_finset_sum`. -/
@[simp]
theorem coe_sum (x : ι → p) (s : Finset ι) : (↑∑ i in s, x i) = ∑ i in s, (x i : M) :=
  p.subtype.map_sum

section RestrictScalars

variable (S) [Semiringₓ S] [Module S M] [Module R M] [HasScalar S R] [IsScalarTower S R M]

/--
`V.restrict_scalars S` is the `S`-submodule of the `S`-module given by restriction of scalars,
corresponding to `V`, an `R`-submodule of the original `R`-module.
-/
def restrict_scalars (V : Submodule R M) : Submodule S M :=
  { Carrier := V, zero_mem' := V.zero_mem, smul_mem' := fun c m h => V.smul_of_tower_mem c h,
    add_mem' := fun x y hx hy => V.add_mem hx hy }

@[simp]
theorem coe_restrict_scalars (V : Submodule R M) : (V.restrict_scalars S : Set M) = V :=
  rfl

@[simp]
theorem restrict_scalars_mem (V : Submodule R M) (m : M) : m ∈ V.restrict_scalars S ↔ m ∈ V :=
  Iff.refl _

@[simp]
theorem restrict_scalars_self (V : Submodule R M) : V.restrict_scalars R = V :=
  SetLike.coe_injective rfl

variable (R S M)

theorem restrict_scalars_injective : Function.Injective (restrict_scalars S : Submodule R M → Submodule S M) :=
  fun V₁ V₂ h => ext$ Set.ext_iff.1 (SetLike.ext'_iff.1 h : _)

@[simp]
theorem restrict_scalars_inj {V₁ V₂ : Submodule R M} : restrict_scalars S V₁ = restrict_scalars S V₂ ↔ V₁ = V₂ :=
  (restrict_scalars_injective S _ _).eq_iff

/-- Even though `p.restrict_scalars S` has type `submodule S M`, it is still an `R`-module. -/
instance restrict_scalars.orig_module (p : Submodule R M) : Module R (p.restrict_scalars S) :=
  (by 
    infer_instance :
  Module R p)

instance (p : Submodule R M) : IsScalarTower S R (p.restrict_scalars S) :=
  { smul_assoc := fun r s x => Subtype.ext$ smul_assoc r s (x : M) }

/-- `restrict_scalars S` is an embedding of the lattice of `R`-submodules into
the lattice of `S`-submodules. -/
@[simps]
def restrict_scalars_embedding : Submodule R M ↪o Submodule S M :=
  { toFun := restrict_scalars S, inj' := restrict_scalars_injective S R M,
    map_rel_iff' :=
      fun p q =>
        by 
          simp [SetLike.le_def] }

/-- Turning `p : submodule R M` into an `S`-submodule gives the same module structure
as turning it into a type and adding a module structure. -/
@[simps (config := { simpRhs := tt })]
def restrict_scalars_equiv (p : Submodule R M) : p.restrict_scalars S ≃ₗ[R] p :=
  { AddEquiv.refl p with toFun := id, invFun := id, map_smul' := fun c x => rfl }

end RestrictScalars

end AddCommMonoidₓ

section AddCommGroupₓ

variable [Ringₓ R] [AddCommGroupₓ M]

variable {module_M : Module R M}

variable (p p' : Submodule R M)

variable {r : R} {x y : M}

theorem neg_mem (hx : x ∈ p) : -x ∈ p :=
  p.to_sub_mul_action.neg_mem hx

/-- Reinterpret a submodule as an additive subgroup. -/
def to_add_subgroup : AddSubgroup M :=
  { p.to_add_submonoid with neg_mem' := fun _ => p.neg_mem }

@[simp]
theorem coe_to_add_subgroup : (p.to_add_subgroup : Set M) = p :=
  rfl

@[simp]
theorem mem_to_add_subgroup : x ∈ p.to_add_subgroup ↔ x ∈ p :=
  Iff.rfl

include module_M

theorem to_add_subgroup_injective : injective (to_add_subgroup : Submodule R M → AddSubgroup M)
| p, q, h => SetLike.ext (SetLike.ext_iff.1 h : _)

@[simp]
theorem to_add_subgroup_eq : p.to_add_subgroup = p'.to_add_subgroup ↔ p = p' :=
  to_add_subgroup_injective.eq_iff

@[mono]
theorem to_add_subgroup_strict_mono : StrictMono (to_add_subgroup : Submodule R M → AddSubgroup M) :=
  fun _ _ => id

@[mono]
theorem to_add_subgroup_mono : Monotone (to_add_subgroup : Submodule R M → AddSubgroup M) :=
  to_add_subgroup_strict_mono.Monotone

omit module_M

theorem sub_mem : x ∈ p → y ∈ p → x - y ∈ p :=
  p.to_add_subgroup.sub_mem

@[simp]
theorem neg_mem_iff : -x ∈ p ↔ x ∈ p :=
  p.to_add_subgroup.neg_mem_iff

theorem add_mem_iff_left : y ∈ p → ((x+y) ∈ p ↔ x ∈ p) :=
  p.to_add_subgroup.add_mem_cancel_right

theorem add_mem_iff_right : x ∈ p → ((x+y) ∈ p ↔ y ∈ p) :=
  p.to_add_subgroup.add_mem_cancel_left

instance : Neg p :=
  ⟨fun x => ⟨-x.1, neg_mem _ x.2⟩⟩

@[simp, normCast]
theorem coe_neg (x : p) : ((-x : p) : M) = -x :=
  rfl

instance : AddCommGroupₓ p :=
  { p.to_add_subgroup.to_add_comm_group with add := ·+·, zero := 0, neg := Neg.neg }

@[simp, normCast]
theorem coe_sub (x y : p) : (↑(x - y) : M) = ↑x - ↑y :=
  rfl

end AddCommGroupₓ

section IsDomain

variable [Ringₓ R] [IsDomain R]

variable [AddCommGroupₓ M] [Module R M] {b : ι → M}

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » N)
theorem not_mem_of_ortho {x : M} {N : Submodule R M} (ortho : ∀ c : R y _ : y ∈ N, ((c • x)+y) = (0 : M) → c = 0) :
  x ∉ N :=
  by 
    intro hx 
    simpa using ortho (-1) x hx

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » N)
theorem ne_zero_of_ortho {x : M} {N : Submodule R M} (ortho : ∀ c : R y _ : y ∈ N, ((c • x)+y) = (0 : M) → c = 0) :
  x ≠ 0 :=
  mt (fun h => show x ∈ N from h.symm ▸ N.zero_mem) (not_mem_of_ortho ortho)

end IsDomain

section OrderedMonoid

variable [Semiringₓ R]

/-- A submodule of an `ordered_add_comm_monoid` is an `ordered_add_comm_monoid`. -/
instance to_ordered_add_comm_monoid {M} [OrderedAddCommMonoid M] [Module R M] (S : Submodule R M) :
  OrderedAddCommMonoid S :=
  Subtype.coe_injective.OrderedAddCommMonoid coeₓ rfl fun _ _ => rfl

/-- A submodule of a `linear_ordered_add_comm_monoid` is a `linear_ordered_add_comm_monoid`. -/
instance to_linear_ordered_add_comm_monoid {M} [LinearOrderedAddCommMonoid M] [Module R M] (S : Submodule R M) :
  LinearOrderedAddCommMonoid S :=
  Subtype.coe_injective.LinearOrderedAddCommMonoid coeₓ rfl fun _ _ => rfl

/-- A submodule of an `ordered_cancel_add_comm_monoid` is an `ordered_cancel_add_comm_monoid`. -/
instance to_ordered_cancel_add_comm_monoid {M} [OrderedCancelAddCommMonoid M] [Module R M] (S : Submodule R M) :
  OrderedCancelAddCommMonoid S :=
  Subtype.coe_injective.OrderedCancelAddCommMonoid coeₓ rfl fun _ _ => rfl

/-- A submodule of a `linear_ordered_cancel_add_comm_monoid` is a
`linear_ordered_cancel_add_comm_monoid`. -/
instance to_linear_ordered_cancel_add_comm_monoid {M} [LinearOrderedCancelAddCommMonoid M] [Module R M]
  (S : Submodule R M) : LinearOrderedCancelAddCommMonoid S :=
  Subtype.coe_injective.LinearOrderedCancelAddCommMonoid coeₓ rfl fun _ _ => rfl

end OrderedMonoid

section OrderedGroup

variable [Ringₓ R]

/-- A submodule of an `ordered_add_comm_group` is an `ordered_add_comm_group`. -/
instance to_ordered_add_comm_group {M} [OrderedAddCommGroup M] [Module R M] (S : Submodule R M) :
  OrderedAddCommGroup S :=
  Subtype.coe_injective.OrderedAddCommGroup coeₓ rfl (fun _ _ => rfl) (fun _ => rfl) fun _ _ => rfl

/-- A submodule of a `linear_ordered_add_comm_group` is a
`linear_ordered_add_comm_group`. -/
instance to_linear_ordered_add_comm_group {M} [LinearOrderedAddCommGroup M] [Module R M] (S : Submodule R M) :
  LinearOrderedAddCommGroup S :=
  Subtype.coe_injective.LinearOrderedAddCommGroup coeₓ rfl (fun _ _ => rfl) (fun _ => rfl) fun _ _ => rfl

end OrderedGroup

end Submodule

namespace Submodule

variable [DivisionRing S] [Semiringₓ R] [AddCommMonoidₓ M] [Module R M]

variable [HasScalar S R] [Module S M] [IsScalarTower S R M]

variable (p : Submodule R M) {s : S} {x y : M}

theorem smul_mem_iff (s0 : s ≠ 0) : s • x ∈ p ↔ x ∈ p :=
  p.to_sub_mul_action.smul_mem_iff s0

end Submodule

/-- Subspace of a vector space. Defined to equal `submodule`. -/
abbrev Subspace (R : Type u) (M : Type v) [Field R] [AddCommGroupₓ M] [Module R M] :=
  Submodule R M

