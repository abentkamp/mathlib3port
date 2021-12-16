import Mathbin.Algebra.FreeAlgebra 
import Mathbin.Algebra.RingQuot 
import Mathbin.Algebra.TrivSqZeroExt

/-!
# Tensor Algebras

Given a commutative semiring `R`, and an `R`-module `M`, we construct the tensor algebra of `M`.
This is the free `R`-algebra generated (`R`-linearly) by the module `M`.

## Notation

1. `tensor_algebra R M` is the tensor algebra itself. It is endowed with an R-algebra structure.
2. `tensor_algebra.ι R` is the canonical R-linear map `M → tensor_algebra R M`.
3. Given a linear map `f : M → A` to an R-algebra `A`, `lift R f` is the lift of `f` to an
  `R`-algebra morphism `tensor_algebra R M → A`.

## Theorems

1. `ι_comp_lift` states that the composition `(lift R f) ∘ (ι R)` is identical to `f`.
2. `lift_unique` states that whenever an R-algebra morphism `g : tensor_algebra R M → A` is
  given whose composition with `ι R` is `f`, then one has `g = lift R f`.
3. `hom_ext` is a variant of `lift_unique` in the form of an extensionality theorem.
4. `lift_comp_ι` is a combination of `ι_comp_lift` and `lift_unique`. It states that the lift
  of the composition of an algebra morphism with `ι` is the algebra morphism itself.

## Implementation details

As noted above, the tensor algebra of `M` is constructed as the free `R`-algebra generated by `M`,
modulo the additional relations making the inclusion of `M` into an `R`-linear map.
-/


variable (R : Type _) [CommSemiringₓ R]

variable (M : Type _) [AddCommMonoidₓ M] [Module R M]

namespace TensorAlgebra

/--
An inductively defined relation on `pre R M` used to force the initial algebra structure on
the associated quotient.
-/
inductive rel : FreeAlgebra R M → FreeAlgebra R M → Prop
  | add {a b : M} : rel (FreeAlgebra.ι R (a+b)) (FreeAlgebra.ι R a+FreeAlgebra.ι R b)
  | smul {r : R} {a : M} : rel (FreeAlgebra.ι R (r • a)) (algebraMap R (FreeAlgebra R M) r*FreeAlgebra.ι R a)

end TensorAlgebra

-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler inhabited
-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler semiring
-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler algebra R
/--
The tensor algebra of the module `M` over the commutative semiring `R`.
-/
def TensorAlgebra :=
  RingQuot (TensorAlgebra.Rel R M)deriving [anonymous], [anonymous], [anonymous]

namespace TensorAlgebra

instance {S : Type _} [CommRingₓ S] [Module S M] : Ringₓ (TensorAlgebra S M) :=
  RingQuot.ring (rel S M)

variable {M}

/--
The canonical linear map `M →ₗ[R] tensor_algebra R M`.
-/
def ι : M →ₗ[R] TensorAlgebra R M :=
  { toFun := fun m => RingQuot.mkAlgHom R _ (FreeAlgebra.ι R m),
    map_add' :=
      fun x y =>
        by 
          rw [←AlgHom.map_add]
          exact RingQuot.mk_alg_hom_rel R rel.add,
    map_smul' :=
      fun r x =>
        by 
          rw [←AlgHom.map_smul]
          exact RingQuot.mk_alg_hom_rel R rel.smul }

theorem ring_quot_mk_alg_hom_free_algebra_ι_eq_ι (m : M) : RingQuot.mkAlgHom R (rel R M) (FreeAlgebra.ι R m) = ι R m :=
  rfl

/--
Given a linear map `f : M → A` where `A` is an `R`-algebra, `lift R f` is the unique lift
of `f` to a morphism of `R`-algebras `tensor_algebra R M → A`.
-/
@[simps symmApply]
def lift {A : Type _} [Semiringₓ A] [Algebra R A] : (M →ₗ[R] A) ≃ (TensorAlgebra R M →ₐ[R] A) :=
  { toFun :=
      RingQuot.liftAlgHom R ∘
        fun f =>
          ⟨FreeAlgebra.lift R (⇑f),
            fun x y h : rel R M x y =>
              by 
                induction h <;> simp [Algebra.smul_def]⟩,
    invFun := fun F => F.to_linear_map.comp (ι R),
    left_inv :=
      fun f =>
        by 
          ext 
          simp [ι],
    right_inv :=
      fun F =>
        by 
          ext 
          simp [ι] }

variable {R}

@[simp]
theorem ι_comp_lift {A : Type _} [Semiringₓ A] [Algebra R A] (f : M →ₗ[R] A) : (lift R f).toLinearMap.comp (ι R) = f :=
  (lift R).symm_apply_apply f

@[simp]
theorem lift_ι_apply {A : Type _} [Semiringₓ A] [Algebra R A] (f : M →ₗ[R] A) x : lift R f (ι R x) = f x :=
  by 
    dsimp [lift, ι]
    rfl

@[simp]
theorem lift_unique {A : Type _} [Semiringₓ A] [Algebra R A] (f : M →ₗ[R] A) (g : TensorAlgebra R M →ₐ[R] A) :
  g.to_linear_map.comp (ι R) = f ↔ g = lift R f :=
  (lift R).symm_apply_eq

@[simp]
theorem lift_comp_ι {A : Type _} [Semiringₓ A] [Algebra R A] (g : TensorAlgebra R M →ₐ[R] A) :
  lift R (g.to_linear_map.comp (ι R)) = g :=
  by 
    rw [←lift_symm_apply]
    exact (lift R).apply_symm_apply g

/-- See note [partially-applied ext lemmas]. -/
@[ext]
theorem hom_ext {A : Type _} [Semiringₓ A] [Algebra R A] {f g : TensorAlgebra R M →ₐ[R] A}
  (w : f.to_linear_map.comp (ι R) = g.to_linear_map.comp (ι R)) : f = g :=
  by 
    rw [←lift_symm_apply, ←lift_symm_apply] at w 
    exact (lift R).symm.Injective w

/-- If `C` holds for the `algebra_map` of `r : R` into `tensor_algebra R M`, the `ι` of `x : M`,
and is preserved under addition and muliplication, then it holds for all of `tensor_algebra R M`.
-/
@[elab_as_eliminator]
theorem induction {C : TensorAlgebra R M → Prop} (h_grade0 : ∀ r, C (algebraMap R (TensorAlgebra R M) r))
  (h_grade1 : ∀ x, C (ι R x)) (h_mul : ∀ a b, C a → C b → C (a*b)) (h_add : ∀ a b, C a → C b → C (a+b))
  (a : TensorAlgebra R M) : C a :=
  by 
    let s : Subalgebra R (TensorAlgebra R M) :=
      { Carrier := C, mul_mem' := h_mul, add_mem' := h_add, algebra_map_mem' := h_grade0 }
    let of : M →ₗ[R] s := (ι R).codRestrict s.to_submodule h_grade1 
    have of_id : AlgHom.id R (TensorAlgebra R M) = s.val.comp (lift R of)
    ·
      ext 
      simp [of]
    convert Subtype.prop (lift R of a)
    exact AlgHom.congr_fun of_id a

/-- The left-inverse of `algebra_map`. -/
def algebra_map_inv : TensorAlgebra R M →ₐ[R] R :=
  lift R (0 : M →ₗ[R] R)

variable (M)

theorem algebra_map_left_inverse : Function.LeftInverse algebra_map_inv (algebraMap R$ TensorAlgebra R M) :=
  fun x =>
    by 
      simp [algebra_map_inv]

@[simp]
theorem algebra_map_inj (x y : R) : algebraMap R (TensorAlgebra R M) x = algebraMap R (TensorAlgebra R M) y ↔ x = y :=
  (algebra_map_left_inverse M).Injective.eq_iff

@[simp]
theorem algebra_map_eq_zero_iff (x : R) : algebraMap R (TensorAlgebra R M) x = 0 ↔ x = 0 :=
  by 
    rw [←algebra_map_inj M x 0, RingHom.map_zero]

@[simp]
theorem algebra_map_eq_one_iff (x : R) : algebraMap R (TensorAlgebra R M) x = 1 ↔ x = 1 :=
  by 
    rw [←algebra_map_inj M x 1, RingHom.map_one]

variable {M}

/-- The canonical map from `tensor_algebra R M` into `triv_sq_zero_ext R M` that sends
`tensor_algebra.ι` to `triv_sq_zero_ext.inr`. -/
def to_triv_sq_zero_ext : TensorAlgebra R M →ₐ[R] TrivSqZeroExt R M :=
  lift R (TrivSqZeroExt.inrHom R M)

@[simp]
theorem to_triv_sq_zero_ext_ι (x : M) : to_triv_sq_zero_ext (ι R x) = TrivSqZeroExt.inr x :=
  lift_ι_apply _ _

/-- The left-inverse of `ι`.

As an implementation detail, we implement this using `triv_sq_zero_ext` which has a suitable
algebra structure. -/
def ι_inv : TensorAlgebra R M →ₗ[R] M :=
  (TrivSqZeroExt.sndHom R M).comp to_triv_sq_zero_ext.toLinearMap

theorem ι_left_inverse : Function.LeftInverse ι_inv (ι R : M → TensorAlgebra R M) :=
  fun x =>
    by 
      simp [ι_inv]

variable (R)

@[simp]
theorem ι_inj (x y : M) : ι R x = ι R y ↔ x = y :=
  ι_left_inverse.Injective.eq_iff

@[simp]
theorem ι_eq_zero_iff (x : M) : ι R x = 0 ↔ x = 0 :=
  by 
    rw [←ι_inj R x 0, LinearMap.map_zero]

variable {R}

@[simp]
theorem ι_eq_algebra_map_iff (x : M) (r : R) : ι R x = algebraMap R _ r ↔ x = 0 ∧ r = 0 :=
  by 
    refine' ⟨fun h => _, _⟩
    ·
      have hf0 : to_triv_sq_zero_ext (ι R x) = (0, x)
      exact lift_ι_apply _ _ 
      rw [h, AlgHom.commutes] at hf0 
      have  : r = 0 ∧ 0 = x := Prod.ext_iff.1 hf0 
      exact this.symm.imp_left Eq.symm
    ·
      rintro ⟨rfl, rfl⟩
      rw [LinearMap.map_zero, RingHom.map_zero]

@[simp]
theorem ι_ne_one [Nontrivial R] (x : M) : ι R x ≠ 1 :=
  by 
    rw [←(algebraMap R (TensorAlgebra R M)).map_one, Ne.def, ι_eq_algebra_map_iff]
    exact one_ne_zero ∘ And.right

/-- The generators of the tensor algebra are disjoint from its scalars. -/
theorem ι_range_disjoint_one : Disjoint (ι R).range (1 : Submodule R (TensorAlgebra R M)) :=
  by 
    rw [Submodule.disjoint_def]
    rintro _ ⟨x, hx⟩ ⟨r, rfl : algebraMap _ _ _ = _⟩
    rw [ι_eq_algebra_map_iff x] at hx 
    rw [hx.2, RingHom.map_zero]

end TensorAlgebra

namespace FreeAlgebra

variable {R M}

/-- The canonical image of the `free_algebra` in the `tensor_algebra`, which maps
`free_algebra.ι R x` to `tensor_algebra.ι R x`. -/
def to_tensor : FreeAlgebra R M →ₐ[R] TensorAlgebra R M :=
  FreeAlgebra.lift R (TensorAlgebra.ι R)

@[simp]
theorem to_tensor_ι (m : M) : (FreeAlgebra.ι R m).toTensor = TensorAlgebra.ι R m :=
  by 
    simp [to_tensor]

end FreeAlgebra

