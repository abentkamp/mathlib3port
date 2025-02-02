/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Mario Carneiro
-/
import Mathbin.GroupTheory.Congruence
import Mathbin.Algebra.Module.Submodule.Bilinear

/-!
# Tensor product of modules over commutative semirings.

This file constructs the tensor product of modules over commutative semirings. Given a semiring
`R` and modules over it `M` and `N`, the standard construction of the tensor product is
`tensor_product R M N`. It is also a module over `R`.

It comes with a canonical bilinear map `M → N → tensor_product R M N`.

Given any bilinear map `M → N → P`, there is a unique linear map `tensor_product R M N → P` whose
composition with the canonical bilinear map `M → N → tensor_product R M N` is the given bilinear
map `M → N → P`.

We start by proving basic lemmas about bilinear maps.

## Notations

This file uses the localized notation `M ⊗ N` and `M ⊗[R] N` for `tensor_product R M N`, as well
as `m ⊗ₜ n` and `m ⊗ₜ[R] n` for `tensor_product.tmul R m n`.

## Tags

bilinear, tensor, tensor product
-/


section Semiringₓ

variable {R : Type _} [CommSemiringₓ R]

variable {R' : Type _} [Monoidₓ R']

variable {R'' : Type _} [Semiringₓ R'']

variable {M : Type _} {N : Type _} {P : Type _} {Q : Type _} {S : Type _}

variable [AddCommMonoidₓ M] [AddCommMonoidₓ N] [AddCommMonoidₓ P] [AddCommMonoidₓ Q] [AddCommMonoidₓ S]

variable [Module R M] [Module R N] [Module R P] [Module R Q] [Module R S]

variable [DistribMulAction R' M]

variable [Module R'' M]

include R

variable (M N)

namespace TensorProduct

section

-- open free_add_monoid
variable (R)

/-- The relation on `free_add_monoid (M × N)` that generates a congruence whose quotient is
the tensor product. -/
inductive Eqv : FreeAddMonoid (M × N) → FreeAddMonoid (M × N) → Prop
  | of_zero_left : ∀ n : N, eqv (FreeAddMonoid.of (0, n)) 0
  | of_zero_right : ∀ m : M, eqv (FreeAddMonoid.of (m, 0)) 0
  | of_add_left :
    ∀ (m₁ m₂ : M) (n : N), eqv (FreeAddMonoid.of (m₁, n) + FreeAddMonoid.of (m₂, n)) (FreeAddMonoid.of (m₁ + m₂, n))
  | of_add_right :
    ∀ (m : M) (n₁ n₂ : N), eqv (FreeAddMonoid.of (m, n₁) + FreeAddMonoid.of (m, n₂)) (FreeAddMonoid.of (m, n₁ + n₂))
  | of_smul : ∀ (r : R) (m : M) (n : N), eqv (FreeAddMonoid.of (r • m, n)) (FreeAddMonoid.of (m, r • n))
  | add_commₓ : ∀ x y, eqv (x + y) (y + x)

end

end TensorProduct

variable (R)

/-- The tensor product of two modules `M` and `N` over the same commutative semiring `R`.
The localized notations are `M ⊗ N` and `M ⊗[R] N`, accessed by `open_locale tensor_product`. -/
def TensorProduct : Type _ :=
  (addConGen (TensorProduct.Eqv R M N)).Quotient

variable {R}

-- mathport name: tensor_product.infer
localized [TensorProduct] infixl:100 " ⊗ " => TensorProduct hole!

-- mathport name: tensor_product
localized [TensorProduct] notation:100 M " ⊗[" R "] " N:100 => TensorProduct R M N

namespace TensorProduct

section Module

instance : AddZeroClassₓ (M ⊗[R] N) :=
  { (addConGen (TensorProduct.Eqv R M N)).AddMonoid with }

instance : AddCommSemigroupₓ (M ⊗[R] N) :=
  { (addConGen (TensorProduct.Eqv R M N)).AddMonoid with
    add_comm := fun x y =>
      (AddCon.induction_on₂ x y) fun x y => Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| Eqv.add_comm _ _ }

instance : Inhabited (M ⊗[R] N) :=
  ⟨0⟩

variable (R) {M N}

/-- The canonical function `M → N → M ⊗ N`. The localized notations are `m ⊗ₜ n` and `m ⊗ₜ[R] n`,
accessed by `open_locale tensor_product`. -/
def tmul (m : M) (n : N) : M ⊗[R] N :=
  AddCon.mk' _ <| FreeAddMonoid.of (m, n)

variable {R}

-- mathport name: «expr ⊗ₜ »
infixl:100 " ⊗ₜ " => tmul _

-- mathport name: «expr ⊗ₜ[ ] »
notation:100 x " ⊗ₜ[" R "] " y:100 => tmul R x y

@[elabAsElim]
protected theorem induction_on {C : M ⊗[R] N → Prop} (z : M ⊗[R] N) (C0 : C 0) (C1 : ∀ {x y}, C <| x ⊗ₜ[R] y)
    (Cp : ∀ {x y}, C x → C y → C (x + y)) : C z :=
  (AddCon.induction_on z) fun x =>
    (FreeAddMonoid.recOn x C0) fun ⟨m, n⟩ y ih => by
      rw [AddCon.coe_add]
      exact Cp C1 ih

variable (M)

@[simp]
theorem zero_tmul (n : N) : (0 : M) ⊗ₜ[R] n = 0 :=
  Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| Eqv.of_zero_left _

variable {M}

theorem add_tmul (m₁ m₂ : M) (n : N) : (m₁ + m₂) ⊗ₜ n = m₁ ⊗ₜ n + m₂ ⊗ₜ[R] n :=
  Eq.symm <| Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| Eqv.of_add_left _ _ _

variable (N)

@[simp]
theorem tmul_zero (m : M) : m ⊗ₜ[R] (0 : N) = 0 :=
  Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| Eqv.of_zero_right _

variable {N}

theorem tmul_add (m : M) (n₁ n₂ : N) : m ⊗ₜ (n₁ + n₂) = m ⊗ₜ n₁ + m ⊗ₜ[R] n₂ :=
  Eq.symm <| Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| Eqv.of_add_right _ _ _

section

variable (R R' M N)

/-- A typeclass for `has_smul` structures which can be moved across a tensor product.

This typeclass is generated automatically from a `is_scalar_tower` instance, but exists so that
we can also add an instance for `add_comm_group.int_module`, allowing `z •` to be moved even if
`R` does not support negation.

Note that `module R' (M ⊗[R] N)` is available even without this typeclass on `R'`; it's only
needed if `tensor_product.smul_tmul`, `tensor_product.smul_tmul'`, or `tensor_product.tmul_smul` is
used.
-/
class CompatibleSmul [DistribMulAction R' N] where
  smul_tmul : ∀ (r : R') (m : M) (n : N), (r • m) ⊗ₜ n = m ⊗ₜ[R] (r • n)

end

/-- Note that this provides the default `compatible_smul R R M N` instance through
`mul_action.is_scalar_tower.left`. -/
instance (priority := 100) CompatibleSmul.isScalarTower [HasSmul R' R] [IsScalarTower R' R M] [DistribMulAction R' N]
    [IsScalarTower R' R N] : CompatibleSmul R R' M N :=
  ⟨fun r m n => by
    conv_lhs => rw [← one_smul R m]
    conv_rhs => rw [← one_smul R n]
    rw [← smul_assoc, ← smul_assoc]
    exact Quotientₓ.sound' <| AddConGen.Rel.of _ _ <| eqv.of_smul _ _ _⟩

/-- `smul` can be moved from one side of the product to the other .-/
theorem smul_tmul [DistribMulAction R' N] [CompatibleSmul R R' M N] (r : R') (m : M) (n : N) :
    (r • m) ⊗ₜ n = m ⊗ₜ[R] (r • n) :=
  CompatibleSmul.smul_tmul _ _ _

/-- Auxiliary function to defining scalar multiplication on tensor product. -/
def Smul.aux {R' : Type _} [HasSmul R' M] (r : R') : FreeAddMonoid (M × N) →+ M ⊗[R] N :=
  FreeAddMonoid.lift fun p : M × N => (r • p.1) ⊗ₜ p.2

theorem Smul.aux_of {R' : Type _} [HasSmul R' M] (r : R') (m : M) (n : N) :
    Smul.aux r (FreeAddMonoid.of (m, n)) = (r • m) ⊗ₜ[R] n :=
  rfl

variable [SmulCommClass R R' M]

variable [SmulCommClass R R'' M]

/-- Given two modules over a commutative semiring `R`, if one of the factors carries a
(distributive) action of a second type of scalars `R'`, which commutes with the action of `R`, then
the tensor product (over `R`) carries an action of `R'`.

This instance defines this `R'` action in the case that it is the left module which has the `R'`
action. Two natural ways in which this situation arises are:
 * Extension of scalars
 * A tensor product of a group representation with a module not carrying an action

Note that in the special case that `R = R'`, since `R` is commutative, we just get the usual scalar
action on a tensor product of two modules. This special case is important enough that, for
performance reasons, we define it explicitly below. -/
instance leftHasSmul : HasSmul R' (M ⊗[R] N) :=
  ⟨fun r =>
    (addConGen (TensorProduct.Eqv R M N)).lift (Smul.aux r : _ →+ M ⊗[R] N) <|
      AddCon.add_con_gen_le fun x y hxy =>
        match x, y, hxy with
        | _, _, eqv.of_zero_left n =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_zero, smul.aux_of, smul_zero, zero_tmul]
        | _, _, eqv.of_zero_right m =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_zero, smul.aux_of, tmul_zero]
        | _, _, eqv.of_add_left m₁ m₂ n =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, smul.aux_of, smul_add, add_tmul]
        | _, _, eqv.of_add_right m n₁ n₂ =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, smul.aux_of, tmul_add]
        | _, _, eqv.of_smul s m n =>
          (AddCon.ker_rel _).2 <| by
            rw [smul.aux_of, smul.aux_of, ← smul_comm, smul_tmul]
        | _, _, eqv.add_comm x y =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, add_commₓ]⟩

instance : HasSmul R (M ⊗[R] N) :=
  TensorProduct.leftHasSmul

protected theorem smul_zero (r : R') : (r • 0 : M ⊗[R] N) = 0 :=
  AddMonoidHom.map_zero _

protected theorem smul_add (r : R') (x y : M ⊗[R] N) : r • (x + y) = r • x + r • y :=
  AddMonoidHom.map_add _ _ _

protected theorem zero_smul (x : M ⊗[R] N) : (0 : R'') • x = 0 :=
  have : ∀ (r : R'') (m : M) (n : N), r • m ⊗ₜ[R] n = (r • m) ⊗ₜ n := fun _ _ _ => rfl
  TensorProduct.induction_on x
    (by
      rw [TensorProduct.smul_zero])
    (fun m n => by
      rw [this, zero_smul, zero_tmul])
    fun x y ihx ihy => by
    rw [TensorProduct.smul_add, ihx, ihy, add_zeroₓ]

protected theorem one_smul (x : M ⊗[R] N) : (1 : R') • x = x :=
  have : ∀ (r : R') (m : M) (n : N), r • m ⊗ₜ[R] n = (r • m) ⊗ₜ n := fun _ _ _ => rfl
  TensorProduct.induction_on x
    (by
      rw [TensorProduct.smul_zero])
    (fun m n => by
      rw [this, one_smul])
    fun x y ihx ihy => by
    rw [TensorProduct.smul_add, ihx, ihy]

protected theorem add_smul (r s : R'') (x : M ⊗[R] N) : (r + s) • x = r • x + s • x :=
  have : ∀ (r : R'') (m : M) (n : N), r • m ⊗ₜ[R] n = (r • m) ⊗ₜ n := fun _ _ _ => rfl
  TensorProduct.induction_on x
    (by
      simp_rw [TensorProduct.smul_zero, add_zeroₓ])
    (fun m n => by
      simp_rw [this, add_smul, add_tmul])
    fun x y ihx ihy => by
    simp_rw [TensorProduct.smul_add]
    rw [ihx, ihy, add_add_add_commₓ]

instance : AddCommMonoidₓ (M ⊗[R] N) :=
  { TensorProduct.addCommSemigroup _ _, TensorProduct.addZeroClass _ _ with nsmul := fun n v => n • v,
    nsmul_zero' := by
      simp [TensorProduct.zero_smul],
    nsmul_succ' := by
      simp [Nat.succ_eq_one_add, TensorProduct.one_smul, TensorProduct.add_smul] }

instance leftDistribMulAction : DistribMulAction R' (M ⊗[R] N) :=
  have : ∀ (r : R') (m : M) (n : N), r • m ⊗ₜ[R] n = (r • m) ⊗ₜ n := fun _ _ _ => rfl
  { smul := (· • ·), smul_add := fun r x y => TensorProduct.smul_add r x y,
    mul_smul := fun r s x =>
      TensorProduct.induction_on x
        (by
          simp_rw [TensorProduct.smul_zero])
        (fun m n => by
          simp_rw [this, mul_smul])
        fun x y ihx ihy => by
        simp_rw [TensorProduct.smul_add]
        rw [ihx, ihy],
    one_smul := TensorProduct.one_smul, smul_zero := TensorProduct.smul_zero }

instance : DistribMulAction R (M ⊗[R] N) :=
  TensorProduct.leftDistribMulAction

theorem smul_tmul' (r : R') (m : M) (n : N) : r • m ⊗ₜ[R] n = (r • m) ⊗ₜ n :=
  rfl

@[simp]
theorem tmul_smul [DistribMulAction R' N] [CompatibleSmul R R' M N] (r : R') (x : M) (y : N) :
    x ⊗ₜ (r • y) = r • x ⊗ₜ[R] y :=
  (smul_tmul _ _ _).symm

theorem smul_tmul_smul (r s : R) (m : M) (n : N) : (r • m) ⊗ₜ[R] (s • n) = (r * s) • m ⊗ₜ[R] n := by
  simp only [tmul_smul, smul_tmul, mul_smul]

instance leftModule : Module R'' (M ⊗[R] N) :=
  { TensorProduct.leftDistribMulAction with smul := (· • ·), add_smul := TensorProduct.add_smul,
    zero_smul := TensorProduct.zero_smul }

instance : Module R (M ⊗[R] N) :=
  TensorProduct.leftModule

instance [Module R''ᵐᵒᵖ M] [IsCentralScalar R'' M] :
    IsCentralScalar R'' (M ⊗[R] N) where op_smul_eq_smul := fun r x =>
    TensorProduct.induction_on x
      (by
        rw [smul_zero, smul_zero])
      (fun x y => by
        rw [smul_tmul', smul_tmul', op_smul_eq_smul])
      fun x y hx hy => by
      rw [smul_add, smul_add, hx, hy]

section

-- Like `R'`, `R'₂` provides a `distrib_mul_action R'₂ (M ⊗[R] N)`
variable {R'₂ : Type _} [Monoidₓ R'₂] [DistribMulAction R'₂ M]

variable [SmulCommClass R R'₂ M] [HasSmul R'₂ R']

/-- `is_scalar_tower R'₂ R' M` implies `is_scalar_tower R'₂ R' (M ⊗[R] N)` -/
instance is_scalar_tower_left [IsScalarTower R'₂ R' M] : IsScalarTower R'₂ R' (M ⊗[R] N) :=
  ⟨fun s r x =>
    TensorProduct.induction_on x
      (by
        simp )
      (fun m n => by
        rw [smul_tmul', smul_tmul', smul_tmul', smul_assoc])
      fun x y ihx ihy => by
      rw [smul_add, smul_add, smul_add, ihx, ihy]⟩

variable [DistribMulAction R'₂ N] [DistribMulAction R' N]

variable [CompatibleSmul R R'₂ M N] [CompatibleSmul R R' M N]

/-- `is_scalar_tower R'₂ R' N` implies `is_scalar_tower R'₂ R' (M ⊗[R] N)` -/
instance is_scalar_tower_right [IsScalarTower R'₂ R' N] : IsScalarTower R'₂ R' (M ⊗[R] N) :=
  ⟨fun s r x =>
    TensorProduct.induction_on x
      (by
        simp )
      (fun m n => by
        rw [← tmul_smul, ← tmul_smul, ← tmul_smul, smul_assoc])
      fun x y ihx ihy => by
      rw [smul_add, smul_add, smul_add, ihx, ihy]⟩

end

/-- A short-cut instance for the common case, where the requirements for the `compatible_smul`
instances are sufficient. -/
instance is_scalar_tower [HasSmul R' R] [IsScalarTower R' R M] : IsScalarTower R' R (M ⊗[R] N) :=
  TensorProduct.is_scalar_tower_left

-- or right
variable (R M N)

/-- The canonical bilinear map `M → N → M ⊗[R] N`. -/
def mk : M →ₗ[R] N →ₗ[R] M ⊗[R] N :=
  LinearMap.mk₂ R (· ⊗ₜ ·) add_tmul
    (fun c m n => by
      rw [smul_tmul, tmul_smul])
    tmul_add tmul_smul

variable {R M N}

@[simp]
theorem mk_apply (m : M) (n : N) : mk R M N m n = m ⊗ₜ n :=
  rfl

theorem ite_tmul (x₁ : M) (x₂ : N) (P : Prop) [Decidable P] :
    (if P then x₁ else 0) ⊗ₜ[R] x₂ = if P then x₁ ⊗ₜ x₂ else 0 := by
  split_ifs <;> simp

theorem tmul_ite (x₁ : M) (x₂ : N) (P : Prop) [Decidable P] :
    (x₁ ⊗ₜ[R] if P then x₂ else 0) = if P then x₁ ⊗ₜ x₂ else 0 := by
  split_ifs <;> simp

section

open BigOperators

theorem sum_tmul {α : Type _} (s : Finset α) (m : α → M) (n : N) : (∑ a in s, m a) ⊗ₜ[R] n = ∑ a in s, m a ⊗ₜ[R] n := by
  classical
  induction' s using Finset.induction with a s has ih h
  · simp
    
  · simp [Finset.sum_insert has, add_tmul, ih]
    

theorem tmul_sum (m : M) {α : Type _} (s : Finset α) (n : α → N) : (m ⊗ₜ[R] ∑ a in s, n a) = ∑ a in s, m ⊗ₜ[R] n a := by
  classical
  induction' s using Finset.induction with a s has ih h
  · simp
    
  · simp [Finset.sum_insert has, tmul_add, ih]
    

end

variable (R M N)

/-- The simple (aka pure) elements span the tensor product. -/
theorem span_tmul_eq_top : Submodule.span R { t : M ⊗[R] N | ∃ m n, m ⊗ₜ n = t } = ⊤ := by
  ext t
  simp only [Submodule.mem_top, iff_trueₓ]
  apply t.induction_on
  · exact Submodule.zero_mem _
    
  · intro m n
    apply Submodule.subset_span
    use m, n
    
  · intro t₁ t₂ ht₁ ht₂
    exact Submodule.add_mem _ ht₁ ht₂
    

@[simp]
theorem map₂_mk_top_top_eq_top : Submodule.map₂ (mk R M N) ⊤ ⊤ = ⊤ := by
  rw [← top_le_iff, ← span_tmul_eq_top, Submodule.map₂_eq_span_image2]
  exact Submodule.span_mono fun _ ⟨m, n, h⟩ => ⟨m, n, trivialₓ, trivialₓ, h⟩

end Module

section UMP

variable {M N P Q}

variable (f : M →ₗ[R] N →ₗ[R] P)

/-- Auxiliary function to constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def liftAux : M ⊗[R] N →+ P :=
  (addConGen (TensorProduct.Eqv R M N)).lift (FreeAddMonoid.lift fun p : M × N => f p.1 p.2) <|
    AddCon.add_con_gen_le fun x y hxy =>
      match x, y, hxy with
      | _, _, eqv.of_zero_left n =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [AddMonoidHom.map_zero, FreeAddMonoid.lift_eval_of, f.map_zero₂]
      | _, _, eqv.of_zero_right m =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [AddMonoidHom.map_zero, FreeAddMonoid.lift_eval_of, (f m).map_zero]
      | _, _, eqv.of_add_left m₁ m₂ n =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [AddMonoidHom.map_add, FreeAddMonoid.lift_eval_of, f.map_add₂]
      | _, _, eqv.of_add_right m n₁ n₂ =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [AddMonoidHom.map_add, FreeAddMonoid.lift_eval_of, (f m).map_add]
      | _, _, eqv.of_smul r m n =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [FreeAddMonoid.lift_eval_of, f.map_smul₂, (f m).map_smul]
      | _, _, eqv.add_comm x y =>
        (AddCon.ker_rel _).2 <| by
          simp_rw [AddMonoidHom.map_add, add_commₓ]

theorem lift_aux_tmul (m n) : liftAux f (m ⊗ₜ n) = f m n :=
  zero_addₓ _

variable {f}

@[simp]
theorem liftAux.smul (r : R) (x) : liftAux f (r • x) = r • liftAux f x :=
  TensorProduct.induction_on x (smul_zero _).symm
    (fun p q => by
      rw [← tmul_smul, lift_aux_tmul, lift_aux_tmul, (f p).map_smul])
    fun p q ih1 ih2 => by
    rw [smul_add, (lift_aux f).map_add, ih1, ih2, (lift_aux f).map_add, smul_add]

variable (f)

/-- Constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P` with the property that
its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def lift : M ⊗ N →ₗ[R] P :=
  { liftAux f with map_smul' := liftAux.smul }

variable {f}

@[simp]
theorem lift.tmul (x y) : lift f (x ⊗ₜ y) = f x y :=
  zero_addₓ _

@[simp]
theorem lift.tmul' (x y) : (lift f).1 (x ⊗ₜ y) = f x y :=
  lift.tmul _ _

theorem ext' {g h : M ⊗[R] N →ₗ[R] P} (H : ∀ x y, g (x ⊗ₜ y) = h (x ⊗ₜ y)) : g = h :=
  LinearMap.ext fun z =>
    (TensorProduct.induction_on z
        (by
          simp_rw [LinearMap.map_zero])
        H)
      fun x y ihx ihy => by
      rw [g.map_add, h.map_add, ihx, ihy]

theorem lift.unique {g : M ⊗[R] N →ₗ[R] P} (H : ∀ x y, g (x ⊗ₜ y) = f x y) : g = lift f :=
  ext' fun m n => by
    rw [H, lift.tmul]

theorem lift_mk : lift (mk R M N) = LinearMap.id :=
  Eq.symm <| lift.unique fun x y => rfl

theorem lift_compr₂ (g : P →ₗ[R] Q) : lift (f.compr₂ g) = g.comp (lift f) :=
  Eq.symm <|
    lift.unique fun x y => by
      simp

theorem lift_mk_compr₂ (f : M ⊗ N →ₗ[R] P) : lift ((mk R M N).compr₂ f) = f := by
  rw [lift_compr₂ f, lift_mk, LinearMap.comp_id]

/-- This used to be an `@[ext]` lemma, but it fails very slowly when the `ext` tactic tries to apply
it in some cases, notably when one wants to show equality of two linear maps. The `@[ext]`
attribute is now added locally where it is needed. Using this as the `@[ext]` lemma instead of
`tensor_product.ext'` allows `ext` to apply lemmas specific to `M →ₗ _` and `N →ₗ _`.

See note [partially-applied ext lemmas]. -/
theorem ext {g h : M ⊗ N →ₗ[R] P} (H : (mk R M N).compr₂ g = (mk R M N).compr₂ h) : g = h := by
  rw [← lift_mk_compr₂ g, H, lift_mk_compr₂]

attribute [local ext] ext

example : M → N → (M → N → P) → P := fun m => flip fun f => f m

variable (R M N P)

/-- Linearly constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def uncurry : (M →ₗ[R] N →ₗ[R] P) →ₗ[R] M ⊗[R] N →ₗ[R] P :=
  LinearMap.flip <| lift <| (LinearMap.lflip _ _ _ _).comp (LinearMap.flip LinearMap.id)

variable {R M N P}

@[simp]
theorem uncurry_apply (f : M →ₗ[R] N →ₗ[R] P) (m : M) (n : N) : uncurry R M N P f (m ⊗ₜ n) = f m n := by
  rw [uncurry, LinearMap.flip_apply, lift.tmul] <;> rfl

variable (R M N P)

/-- A linear equivalence constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def lift.equiv : (M →ₗ[R] N →ₗ[R] P) ≃ₗ[R] M ⊗ N →ₗ[R] P :=
  { uncurry R M N P with invFun := fun f => (mk R M N).compr₂ f,
    left_inv := fun f => LinearMap.ext₂ fun m n => lift.tmul _ _, right_inv := fun f => ext' fun m n => lift.tmul _ _ }

@[simp]
theorem lift.equiv_apply (f : M →ₗ[R] N →ₗ[R] P) (m : M) (n : N) : lift.equiv R M N P f (m ⊗ₜ n) = f m n :=
  uncurry_apply f m n

@[simp]
theorem lift.equiv_symm_apply (f : M ⊗[R] N →ₗ[R] P) (m : M) (n : N) : (lift.equiv R M N P).symm f m n = f (m ⊗ₜ n) :=
  rfl

/-- Given a linear map `M ⊗ N → P`, compose it with the canonical bilinear map `M → N → M ⊗ N` to
form a bilinear map `M → N → P`. -/
def lcurry : (M ⊗[R] N →ₗ[R] P) →ₗ[R] M →ₗ[R] N →ₗ[R] P :=
  (lift.equiv R M N P).symm

variable {R M N P}

@[simp]
theorem lcurry_apply (f : M ⊗[R] N →ₗ[R] P) (m : M) (n : N) : lcurry R M N P f m n = f (m ⊗ₜ n) :=
  rfl

/-- Given a linear map `M ⊗ N → P`, compose it with the canonical bilinear map `M → N → M ⊗ N` to
form a bilinear map `M → N → P`. -/
def curry (f : M ⊗ N →ₗ[R] P) : M →ₗ[R] N →ₗ[R] P :=
  lcurry R M N P f

@[simp]
theorem curry_apply (f : M ⊗ N →ₗ[R] P) (m : M) (n : N) : curry f m n = f (m ⊗ₜ n) :=
  rfl

theorem curry_injective : Function.Injective (curry : (M ⊗[R] N →ₗ[R] P) → M →ₗ[R] N →ₗ[R] P) := fun g h H => ext H

theorem ext_threefold {g h : (M ⊗[R] N) ⊗[R] P →ₗ[R] Q} (H : ∀ x y z, g (x ⊗ₜ y ⊗ₜ z) = h (x ⊗ₜ y ⊗ₜ z)) : g = h := by
  ext x y z
  exact H x y z

-- We'll need this one for checking the pentagon identity!
theorem ext_fourfold {g h : ((M ⊗[R] N) ⊗[R] P) ⊗[R] Q →ₗ[R] S}
    (H : ∀ w x y z, g (w ⊗ₜ x ⊗ₜ y ⊗ₜ z) = h (w ⊗ₜ x ⊗ₜ y ⊗ₜ z)) : g = h := by
  ext w x y z
  exact H w x y z

end UMP

variable {M N}

section

variable (R M)

/-- The base ring is a left identity for the tensor product of modules, up to linear equivalence.
-/
protected def lid : R ⊗ M ≃ₗ[R] M :=
  LinearEquiv.ofLinear (lift <| LinearMap.lsmul R M) (mk R R M 1)
    (LinearMap.ext fun _ => by
      simp )
    (ext' fun r m => by
      simp <;> rw [← tmul_smul, ← smul_tmul, smul_eq_mul, mul_oneₓ])

end

@[simp]
theorem lid_tmul (m : M) (r : R) : (TensorProduct.lid R M : R ⊗ M → M) (r ⊗ₜ m) = r • m := by
  dsimp' [TensorProduct.lid]
  simp

@[simp]
theorem lid_symm_apply (m : M) : (TensorProduct.lid R M).symm m = 1 ⊗ₜ m :=
  rfl

section

variable (R M N)

/-- The tensor product of modules is commutative, up to linear equivalence.
-/
protected def comm : M ⊗ N ≃ₗ[R] N ⊗ M :=
  LinearEquiv.ofLinear (lift (mk R N M).flip) (lift (mk R M N).flip) (ext' fun m n => rfl) (ext' fun m n => rfl)

@[simp]
theorem comm_tmul (m : M) (n : N) : (TensorProduct.comm R M N) (m ⊗ₜ n) = n ⊗ₜ m :=
  rfl

@[simp]
theorem comm_symm_tmul (m : M) (n : N) : (TensorProduct.comm R M N).symm (n ⊗ₜ m) = m ⊗ₜ n :=
  rfl

end

section

variable (R M)

/-- The base ring is a right identity for the tensor product of modules, up to linear equivalence.
-/
protected def rid : M ⊗[R] R ≃ₗ[R] M :=
  LinearEquiv.trans (TensorProduct.comm R M R) (TensorProduct.lid R M)

end

@[simp]
theorem rid_tmul (m : M) (r : R) : (TensorProduct.rid R M) (m ⊗ₜ r) = r • m := by
  dsimp' [TensorProduct.rid, TensorProduct.comm, TensorProduct.lid]
  simp

@[simp]
theorem rid_symm_apply (m : M) : (TensorProduct.rid R M).symm m = m ⊗ₜ 1 :=
  rfl

open LinearMap

section

variable (R M N P)

/-- The associator for tensor product of R-modules, as a linear equivalence. -/
protected def assoc : (M ⊗[R] N) ⊗[R] P ≃ₗ[R] M ⊗[R] N ⊗[R] P := by
  refine'
      LinearEquiv.ofLinear (lift <| lift <| comp (lcurry R _ _ _) <| mk _ _ _)
        (lift <| comp (uncurry R _ _ _) <| curry <| mk _ _ _) (ext <| LinearMap.ext fun m => ext' fun n p => _)
        (ext <| flip_inj <| LinearMap.ext fun p => ext' fun m n => _) <;>
    repeat'
      first |
        rw [lift.tmul]|
        rw [compr₂_apply]|
        rw [comp_apply]|
        rw [mk_apply]|
        rw [flip_apply]|
        rw [lcurry_apply]|
        rw [uncurry_apply]|
        rw [curry_apply]|
        rw [id_apply]

end

@[simp]
theorem assoc_tmul (m : M) (n : N) (p : P) : (TensorProduct.assoc R M N P) (m ⊗ₜ n ⊗ₜ p) = m ⊗ₜ (n ⊗ₜ p) :=
  rfl

@[simp]
theorem assoc_symm_tmul (m : M) (n : N) (p : P) : (TensorProduct.assoc R M N P).symm (m ⊗ₜ (n ⊗ₜ p)) = m ⊗ₜ n ⊗ₜ p :=
  rfl

/-- The tensor product of a pair of linear maps between modules. -/
def map (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : M ⊗ N →ₗ[R] P ⊗ Q :=
  lift <| comp (compl₂ (mk _ _ _) g) f

@[simp]
theorem map_tmul (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (m : M) (n : N) : map f g (m ⊗ₜ n) = f m ⊗ₜ g n :=
  rfl

theorem map_range_eq_span_tmul (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
    (map f g).range = Submodule.span R { t | ∃ m n, f m ⊗ₜ g n = t } := by
  simp only [← Submodule.map_top, ← span_tmul_eq_top, Submodule.map_span, Set.mem_image, Set.mem_set_of_eq]
  congr
  ext t
  constructor
  · rintro ⟨_, ⟨⟨m, n, rfl⟩, rfl⟩⟩
    use m, n
    simp only [map_tmul]
    
  · rintro ⟨m, n, rfl⟩
    use m ⊗ₜ n, m, n
    simp only [map_tmul]
    

/-- Given submodules `p ⊆ P` and `q ⊆ Q`, this is the natural map: `p ⊗ q → P ⊗ Q`. -/
@[simp]
def mapIncl (p : Submodule R P) (q : Submodule R Q) : p ⊗[R] q →ₗ[R] P ⊗[R] Q :=
  map p.Subtype q.Subtype

section

variable {P' Q' : Type _}

variable [AddCommMonoidₓ P'] [Module R P']

variable [AddCommMonoidₓ Q'] [Module R Q']

theorem map_comp (f₂ : P →ₗ[R] P') (f₁ : M →ₗ[R] P) (g₂ : Q →ₗ[R] Q') (g₁ : N →ₗ[R] Q) :
    map (f₂.comp f₁) (g₂.comp g₁) = (map f₂ g₂).comp (map f₁ g₁) :=
  ext' fun _ _ => by
    simp only [LinearMap.comp_apply, map_tmul]

theorem lift_comp_map (i : P →ₗ[R] Q →ₗ[R] Q') (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
    (lift i).comp (map f g) = lift ((i.comp f).compl₂ g) :=
  ext' fun _ _ => by
    simp only [lift.tmul, map_tmul, LinearMap.compl₂_apply, LinearMap.comp_apply]

attribute [local ext] ext

@[simp]
theorem map_id : map (id : M →ₗ[R] M) (id : N →ₗ[R] N) = id := by
  ext
  simp only [mk_apply, id_coe, compr₂_apply, id.def, map_tmul]

@[simp]
theorem map_one : map (1 : M →ₗ[R] M) (1 : N →ₗ[R] N) = 1 :=
  map_id

theorem map_mul (f₁ f₂ : M →ₗ[R] M) (g₁ g₂ : N →ₗ[R] N) : map (f₁ * f₂) (g₁ * g₂) = map f₁ g₁ * map f₂ g₂ :=
  map_comp f₁ f₂ g₁ g₂

@[simp]
protected theorem map_pow (f : M →ₗ[R] M) (g : N →ₗ[R] N) (n : ℕ) : map f g ^ n = map (f ^ n) (g ^ n) := by
  induction' n with n ih
  · simp only [pow_zeroₓ, map_one]
    
  · simp only [pow_succ'ₓ, ih, map_mul]
    

theorem map_add_left (f₁ f₂ : M →ₗ[R] P) (g : N →ₗ[R] Q) : map (f₁ + f₂) g = map f₁ g + map f₂ g := by
  ext
  simp only [add_tmul, compr₂_apply, mk_apply, map_tmul, add_apply]

theorem map_add_right (f : M →ₗ[R] P) (g₁ g₂ : N →ₗ[R] Q) : map f (g₁ + g₂) = map f g₁ + map f g₂ := by
  ext
  simp only [tmul_add, compr₂_apply, mk_apply, map_tmul, add_apply]

theorem map_smul_left (r : R) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : map (r • f) g = r • map f g := by
  ext
  simp only [smul_tmul, compr₂_apply, mk_apply, map_tmul, smul_apply, tmul_smul]

theorem map_smul_right (r : R) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : map f (r • g) = r • map f g := by
  ext
  simp only [smul_tmul, compr₂_apply, mk_apply, map_tmul, smul_apply, tmul_smul]

variable (R M N P Q)

/-- The tensor product of a pair of linear maps between modules, bilinear in both maps. -/
def mapBilinear : (M →ₗ[R] P) →ₗ[R] (N →ₗ[R] Q) →ₗ[R] M ⊗[R] N →ₗ[R] P ⊗[R] Q :=
  LinearMap.mk₂ R map map_add_left map_smul_left map_add_right map_smul_right

/-- The canonical linear map from `P ⊗[R] (M →ₗ[R] Q)` to `(M →ₗ[R] P ⊗[R] Q)` -/
def ltensorHomToHomLtensor : P ⊗[R] (M →ₗ[R] Q) →ₗ[R] M →ₗ[R] P ⊗[R] Q :=
  TensorProduct.lift (llcomp R M Q _ ∘ₗ mk R P Q)

/-- The canonical linear map from `(M →ₗ[R] P) ⊗[R] Q` to `(M →ₗ[R] P ⊗[R] Q)` -/
def rtensorHomToHomRtensor : (M →ₗ[R] P) ⊗[R] Q →ₗ[R] M →ₗ[R] P ⊗[R] Q :=
  TensorProduct.lift (llcomp R M P _ ∘ₗ (mk R P Q).flip).flip

/-- The linear map from `(M →ₗ P) ⊗ (N →ₗ Q)` to `(M ⊗ N →ₗ P ⊗ Q)` sending `f ⊗ₜ g` to
the `tensor_product.map f g`, the tensor product of the two maps. -/
def homTensorHomMap : (M →ₗ[R] P) ⊗[R] (N →ₗ[R] Q) →ₗ[R] M ⊗[R] N →ₗ[R] P ⊗[R] Q :=
  lift (mapBilinear R M N P Q)

variable {R M N P Q}

@[simp]
theorem map_bilinear_apply (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : mapBilinear R M N P Q f g = map f g :=
  rfl

@[simp]
theorem ltensor_hom_to_hom_ltensor_apply (p : P) (f : M →ₗ[R] Q) (m : M) :
    ltensorHomToHomLtensor R M P Q (p ⊗ₜ f) m = p ⊗ₜ f m :=
  rfl

@[simp]
theorem rtensor_hom_to_hom_rtensor_apply (f : M →ₗ[R] P) (q : Q) (m : M) :
    rtensorHomToHomRtensor R M P Q (f ⊗ₜ q) m = f m ⊗ₜ q :=
  rfl

@[simp]
theorem hom_tensor_hom_map_apply (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : homTensorHomMap R M N P Q (f ⊗ₜ g) = map f g := by
  simp only [hom_tensor_hom_map, lift.tmul, map_bilinear_apply]

end

/-- If `M` and `P` are linearly equivalent and `N` and `Q` are linearly equivalent
then `M ⊗ N` and `P ⊗ Q` are linearly equivalent. -/
def congr (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) : M ⊗ N ≃ₗ[R] P ⊗ Q :=
  LinearEquiv.ofLinear (map f g) (map f.symm g.symm)
    (ext' fun m n => by
      simp <;> simp only [LinearEquiv.apply_symm_apply])
    (ext' fun m n => by
      simp <;> simp only [LinearEquiv.symm_apply_apply])

@[simp]
theorem congr_tmul (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) (m : M) (n : N) : congr f g (m ⊗ₜ n) = f m ⊗ₜ g n :=
  rfl

@[simp]
theorem congr_symm_tmul (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) (p : P) (q : Q) :
    (congr f g).symm (p ⊗ₜ q) = f.symm p ⊗ₜ g.symm q :=
  rfl

variable (R M N P Q)

/-- A tensor product analogue of `mul_left_comm`. -/
def leftComm : M ⊗[R] N ⊗[R] P ≃ₗ[R] N ⊗[R] M ⊗[R] P :=
  let e₁ := (TensorProduct.assoc R M N P).symm
  let e₂ := congr (TensorProduct.comm R M N) (1 : P ≃ₗ[R] P)
  let e₃ := TensorProduct.assoc R N M P
  e₁ ≪≫ₗ (e₂ ≪≫ₗ e₃)

variable {M N P Q}

@[simp]
theorem left_comm_tmul (m : M) (n : N) (p : P) : leftComm R M N P (m ⊗ₜ (n ⊗ₜ p)) = n ⊗ₜ (m ⊗ₜ p) :=
  rfl

@[simp]
theorem left_comm_symm_tmul (m : M) (n : N) (p : P) : (leftComm R M N P).symm (n ⊗ₜ (m ⊗ₜ p)) = m ⊗ₜ (n ⊗ₜ p) :=
  rfl

variable (M N P Q)

/-- This special case is worth defining explicitly since it is useful for defining multiplication
on tensor products of modules carrying multiplications (e.g., associative rings, Lie rings, ...).

E.g., suppose `M = P` and `N = Q` and that `M` and `N` carry bilinear multiplications:
`M ⊗ M → M` and `N ⊗ N → N`. Using `map`, we can define `(M ⊗ M) ⊗ (N ⊗ N) → M ⊗ N` which, when
combined with this definition, yields a bilinear multiplication on `M ⊗ N`:
`(M ⊗ N) ⊗ (M ⊗ N) → M ⊗ N`. In particular we could use this to define the multiplication in
the `tensor_product.semiring` instance (currently defined "by hand" using `tensor_product.mul`).

See also `mul_mul_mul_comm`. -/
def tensorTensorTensorComm : (M ⊗[R] N) ⊗[R] P ⊗[R] Q ≃ₗ[R] (M ⊗[R] P) ⊗[R] N ⊗[R] Q :=
  let e₁ := TensorProduct.assoc R M N (P ⊗[R] Q)
  let e₂ := congr (1 : M ≃ₗ[R] M) (leftComm R N P Q)
  let e₃ := (TensorProduct.assoc R M P (N ⊗[R] Q)).symm
  e₁ ≪≫ₗ (e₂ ≪≫ₗ e₃)

variable {M N P Q}

@[simp]
theorem tensor_tensor_tensor_comm_tmul (m : M) (n : N) (p : P) (q : Q) :
    tensorTensorTensorComm R M N P Q (m ⊗ₜ n ⊗ₜ (p ⊗ₜ q)) = m ⊗ₜ p ⊗ₜ (n ⊗ₜ q) :=
  rfl

@[simp]
theorem tensor_tensor_tensor_comm_symm_tmul (m : M) (n : N) (p : P) (q : Q) :
    (tensorTensorTensorComm R M N P Q).symm (m ⊗ₜ p ⊗ₜ (n ⊗ₜ q)) = m ⊗ₜ n ⊗ₜ (p ⊗ₜ q) :=
  rfl

variable (M N P Q)

/-- This special case is useful for describing the interplay between `dual_tensor_hom_equiv` and
composition of linear maps.

E.g., composition of linear maps gives a map `(M → N) ⊗ (N → P) → (M → P)`, and applying
`dual_tensor_hom_equiv.symm` to the three hom-modules gives a map
`(M.dual ⊗ N) ⊗ (N.dual ⊗ P) → (M.dual ⊗ P)`, which agrees with the application of `contract_right`
on `N ⊗ N.dual` after the suitable rebracketting.
-/
def tensorTensorTensorAssoc : (M ⊗[R] N) ⊗[R] P ⊗[R] Q ≃ₗ[R] (M ⊗[R] N ⊗[R] P) ⊗[R] Q :=
  (TensorProduct.assoc R (M ⊗[R] N) P Q).symm ≪≫ₗ congr (TensorProduct.assoc R M N P) (1 : Q ≃ₗ[R] Q)

variable {M N P Q}

@[simp]
theorem tensor_tensor_tensor_assoc_tmul (m : M) (n : N) (p : P) (q : Q) :
    tensorTensorTensorAssoc R M N P Q (m ⊗ₜ n ⊗ₜ (p ⊗ₜ q)) = m ⊗ₜ (n ⊗ₜ p) ⊗ₜ q :=
  rfl

@[simp]
theorem tensor_tensor_tensor_assoc_symm_tmul (m : M) (n : N) (p : P) (q : Q) :
    (tensorTensorTensorAssoc R M N P Q).symm (m ⊗ₜ (n ⊗ₜ p) ⊗ₜ q) = m ⊗ₜ n ⊗ₜ (p ⊗ₜ q) :=
  rfl

end TensorProduct

namespace LinearMap

variable {R} (M) {N P Q}

/-- `ltensor M f : M ⊗ N →ₗ M ⊗ P` is the natural linear map induced by `f : N →ₗ P`. -/
def ltensor (f : N →ₗ[R] P) : M ⊗ N →ₗ[R] M ⊗ P :=
  TensorProduct.map id f

/-- `rtensor f M : N₁ ⊗ M →ₗ N₂ ⊗ M` is the natural linear map induced by `f : N₁ →ₗ N₂`. -/
def rtensor (f : N →ₗ[R] P) : N ⊗ M →ₗ[R] P ⊗ M :=
  TensorProduct.map f id

variable (g : P →ₗ[R] Q) (f : N →ₗ[R] P)

@[simp]
theorem ltensor_tmul (m : M) (n : N) : f.ltensor M (m ⊗ₜ n) = m ⊗ₜ f n :=
  rfl

@[simp]
theorem rtensor_tmul (m : M) (n : N) : f.rtensor M (n ⊗ₜ m) = f n ⊗ₜ m :=
  rfl

open TensorProduct

attribute [local ext] TensorProduct.ext

/-- `ltensor_hom M` is the natural linear map that sends a linear map `f : N →ₗ P` to `M ⊗ f`. -/
def ltensorHom : (N →ₗ[R] P) →ₗ[R] M ⊗[R] N →ₗ[R] M ⊗[R] P where
  toFun := ltensor M
  map_add' := fun f g => by
    ext x y
    simp only [compr₂_apply, mk_apply, add_apply, ltensor_tmul, tmul_add]
  map_smul' := fun r f => by
    dsimp'
    ext x y
    simp only [compr₂_apply, mk_apply, tmul_smul, smul_apply, ltensor_tmul]

/-- `rtensor_hom M` is the natural linear map that sends a linear map `f : N →ₗ P` to `M ⊗ f`. -/
def rtensorHom : (N →ₗ[R] P) →ₗ[R] N ⊗[R] M →ₗ[R] P ⊗[R] M where
  toFun := fun f => f.rtensor M
  map_add' := fun f g => by
    ext x y
    simp only [compr₂_apply, mk_apply, add_apply, rtensor_tmul, add_tmul]
  map_smul' := fun r f => by
    dsimp'
    ext x y
    simp only [compr₂_apply, mk_apply, smul_tmul, tmul_smul, smul_apply, rtensor_tmul]

@[simp]
theorem coe_ltensor_hom : (ltensorHom M : (N →ₗ[R] P) → M ⊗[R] N →ₗ[R] M ⊗[R] P) = ltensor M :=
  rfl

@[simp]
theorem coe_rtensor_hom : (rtensorHom M : (N →ₗ[R] P) → N ⊗[R] M →ₗ[R] P ⊗[R] M) = rtensor M :=
  rfl

@[simp]
theorem ltensor_add (f g : N →ₗ[R] P) : (f + g).ltensor M = f.ltensor M + g.ltensor M :=
  (ltensorHom M).map_add f g

@[simp]
theorem rtensor_add (f g : N →ₗ[R] P) : (f + g).rtensor M = f.rtensor M + g.rtensor M :=
  (rtensorHom M).map_add f g

@[simp]
theorem ltensor_zero : ltensor M (0 : N →ₗ[R] P) = 0 :=
  (ltensorHom M).map_zero

@[simp]
theorem rtensor_zero : rtensor M (0 : N →ₗ[R] P) = 0 :=
  (rtensorHom M).map_zero

@[simp]
theorem ltensor_smul (r : R) (f : N →ₗ[R] P) : (r • f).ltensor M = r • f.ltensor M :=
  (ltensorHom M).map_smul r f

@[simp]
theorem rtensor_smul (r : R) (f : N →ₗ[R] P) : (r • f).rtensor M = r • f.rtensor M :=
  (rtensorHom M).map_smul r f

theorem ltensor_comp : (g.comp f).ltensor M = (g.ltensor M).comp (f.ltensor M) := by
  ext m n
  simp only [compr₂_apply, mk_apply, comp_apply, ltensor_tmul]

theorem ltensor_comp_apply (x : M ⊗[R] N) : (g.comp f).ltensor M x = (g.ltensor M) ((f.ltensor M) x) := by
  rw [ltensor_comp, coe_comp]

theorem rtensor_comp : (g.comp f).rtensor M = (g.rtensor M).comp (f.rtensor M) := by
  ext m n
  simp only [compr₂_apply, mk_apply, comp_apply, rtensor_tmul]

theorem rtensor_comp_apply (x : N ⊗[R] M) : (g.comp f).rtensor M x = (g.rtensor M) ((f.rtensor M) x) := by
  rw [rtensor_comp, coe_comp]

theorem ltensor_mul (f g : Module.End R N) : (f * g).ltensor M = f.ltensor M * g.ltensor M :=
  ltensor_comp M f g

theorem rtensor_mul (f g : Module.End R N) : (f * g).rtensor M = f.rtensor M * g.rtensor M :=
  rtensor_comp M f g

variable (N)

@[simp]
theorem ltensor_id : (id : N →ₗ[R] N).ltensor M = id :=
  map_id

-- `simp` can prove this.
theorem ltensor_id_apply (x : M ⊗[R] N) : (LinearMap.id : N →ₗ[R] N).ltensor M x = x := by
  rw [ltensor_id, id_coe, id.def]

@[simp]
theorem rtensor_id : (id : N →ₗ[R] N).rtensor M = id :=
  map_id

-- `simp` can prove this.
theorem rtensor_id_apply (x : N ⊗[R] M) : (LinearMap.id : N →ₗ[R] N).rtensor M x = x := by
  rw [rtensor_id, id_coe, id.def]

variable {N}

@[simp]
theorem ltensor_comp_rtensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : (g.ltensor P).comp (f.rtensor N) = map f g := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp]
theorem rtensor_comp_ltensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : (f.rtensor Q).comp (g.ltensor M) = map f g := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp]
theorem map_comp_rtensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (f' : S →ₗ[R] M) :
    (map f g).comp (f'.rtensor _) = map (f.comp f') g := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp]
theorem map_comp_ltensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (g' : S →ₗ[R] N) :
    (map f g).comp (g'.ltensor _) = map f (g.comp g') := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp]
theorem rtensor_comp_map (f' : P →ₗ[R] S) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
    (f'.rtensor _).comp (map f g) = map (f'.comp f) g := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp]
theorem ltensor_comp_map (g' : Q →ₗ[R] S) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
    (g'.ltensor _).comp (map f g) = map f (g'.comp g) := by
  simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

variable {M}

@[simp]
theorem rtensor_pow (f : M →ₗ[R] M) (n : ℕ) : f.rtensor N ^ n = (f ^ n).rtensor N := by
  have h := TensorProduct.map_pow f (id : N →ₗ[R] N) n
  rwa [id_pow] at h

@[simp]
theorem ltensor_pow (f : N →ₗ[R] N) (n : ℕ) : f.ltensor M ^ n = (f ^ n).ltensor M := by
  have h := TensorProduct.map_pow (id : M →ₗ[R] M) f n
  rwa [id_pow] at h

end LinearMap

end Semiringₓ

section Ringₓ

variable {R : Type _} [CommSemiringₓ R]

variable {M : Type _} {N : Type _} {P : Type _} {Q : Type _} {S : Type _}

variable [AddCommGroupₓ M] [AddCommGroupₓ N] [AddCommGroupₓ P] [AddCommGroupₓ Q] [AddCommGroupₓ S]

variable [Module R M] [Module R N] [Module R P] [Module R Q] [Module R S]

namespace TensorProduct

open TensorProduct

open LinearMap

variable (R)

/-- Auxiliary function to defining negation multiplication on tensor product. -/
def Neg.aux : FreeAddMonoid (M × N) →+ M ⊗[R] N :=
  FreeAddMonoid.lift fun p : M × N => (-p.1) ⊗ₜ p.2

variable {R}

theorem Neg.aux_of (m : M) (n : N) : Neg.aux R (FreeAddMonoid.of (m, n)) = (-m) ⊗ₜ[R] n :=
  rfl

instance :
    Neg
      (M ⊗[R]
        N) where neg :=
    (addConGen (TensorProduct.Eqv R M N)).lift (Neg.aux R) <|
      AddCon.add_con_gen_le fun x y hxy =>
        match x, y, hxy with
        | _, _, eqv.of_zero_left n =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_zero, neg.aux_of, neg_zero, zero_tmul]
        | _, _, eqv.of_zero_right m =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_zero, neg.aux_of, tmul_zero]
        | _, _, eqv.of_add_left m₁ m₂ n =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, neg.aux_of, neg_add, add_tmul]
        | _, _, eqv.of_add_right m n₁ n₂ =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, neg.aux_of, tmul_add]
        | _, _, eqv.of_smul s m n =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [neg.aux_of, tmul_smul s, smul_tmul', smul_neg]
        | _, _, eqv.add_comm x y =>
          (AddCon.ker_rel _).2 <| by
            simp_rw [AddMonoidHom.map_add, add_commₓ]

protected theorem add_left_neg (x : M ⊗[R] N) : -x + x = 0 :=
  TensorProduct.induction_on x
    (by
      rw [add_zeroₓ]
      apply (neg.aux R).map_zero)
    (fun x y => by
      convert (add_tmul (-x) x y).symm
      rw [add_left_negₓ, zero_tmul])
    fun x y hx hy => by
    unfold Neg.neg SubNegMonoidₓ.neg
    rw [AddMonoidHom.map_add]
    ac_change -x + x + (-y + y) = 0
    rw [hx, hy, add_zeroₓ]

instance : AddCommGroupₓ (M ⊗[R] N) :=
  { TensorProduct.addCommMonoid with neg := Neg.neg, sub := _, sub_eq_add_neg := fun _ _ => rfl,
    add_left_neg := fun x => TensorProduct.add_left_neg x, zsmul := fun n v => n • v,
    zsmul_zero' := by
      simp [TensorProduct.zero_smul],
    zsmul_succ' := by
      simp [Nat.succ_eq_one_add, TensorProduct.one_smul, TensorProduct.add_smul],
    zsmul_neg' := fun n x => by
      change (-n.succ : ℤ) • x = -(((n : ℤ) + 1) • x)
      rw [← zero_addₓ (-↑n.succ • x), ← TensorProduct.add_left_neg (↑n.succ • x), add_assocₓ, ← add_smul, ←
        sub_eq_add_neg, sub_self, zero_smul, add_zeroₓ]
      rfl }

theorem neg_tmul (m : M) (n : N) : (-m) ⊗ₜ n = -m ⊗ₜ[R] n :=
  rfl

theorem tmul_neg (m : M) (n : N) : m ⊗ₜ (-n) = -m ⊗ₜ[R] n :=
  (mk R M N _).map_neg _

theorem tmul_sub (m : M) (n₁ n₂ : N) : m ⊗ₜ (n₁ - n₂) = m ⊗ₜ[R] n₁ - m ⊗ₜ[R] n₂ :=
  (mk R M N _).map_sub _ _

theorem sub_tmul (m₁ m₂ : M) (n : N) : (m₁ - m₂) ⊗ₜ n = m₁ ⊗ₜ[R] n - m₂ ⊗ₜ[R] n :=
  (mk R M N).map_sub₂ _ _ _

/-- While the tensor product will automatically inherit a ℤ-module structure from
`add_comm_group.int_module`, that structure won't be compatible with lemmas like `tmul_smul` unless
we use a `ℤ-module` instance provided by `tensor_product.left_module`.

When `R` is a `ring` we get the required `tensor_product.compatible_smul` instance through
`is_scalar_tower`, but when it is only a `semiring` we need to build it from scratch.
The instance diamond in `compatible_smul` doesn't matter because it's in `Prop`.
-/
instance CompatibleSmul.int : CompatibleSmul R ℤ M N :=
  ⟨fun r m n =>
    Int.induction_on r
      (by
        simp )
      (fun r ih => by
        simpa [add_smul, tmul_add, add_tmul] using ih)
      fun r ih => by
      simpa [sub_smul, tmul_sub, sub_tmul] using ih⟩

instance CompatibleSmul.unit {S} [Monoidₓ S] [DistribMulAction S M] [DistribMulAction S N] [CompatibleSmul R S M N] :
    CompatibleSmul R Sˣ M N :=
  ⟨fun s m n => (CompatibleSmul.smul_tmul (s : S) m n : _)⟩

end TensorProduct

namespace LinearMap

@[simp]
theorem ltensor_sub (f g : N →ₗ[R] P) : (f - g).ltensor M = f.ltensor M - g.ltensor M := by
  simp only [← coe_ltensor_hom, map_sub]

@[simp]
theorem rtensor_sub (f g : N →ₗ[R] P) : (f - g).rtensor M = f.rtensor M - g.rtensor M := by
  simp only [← coe_rtensor_hom, map_sub]

@[simp]
theorem ltensor_neg (f : N →ₗ[R] P) : (-f).ltensor M = -f.ltensor M := by
  simp only [← coe_ltensor_hom, map_neg]

@[simp]
theorem rtensor_neg (f : N →ₗ[R] P) : (-f).rtensor M = -f.rtensor M := by
  simp only [← coe_rtensor_hom, map_neg]

end LinearMap

end Ringₓ

