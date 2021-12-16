import Mathbin.Algebra.Algebra.Subalgebra

/-!
# Towers of algebras

In this file we prove basic facts about towers of algebra.

An algebra tower A/S/R is expressed by having instances of `algebra A S`,
`algebra R S`, `algebra R A` and `is_scalar_tower R S A`, the later asserting the
compatibility condition `(r • s) • a = r • (s • a)`.

An important definition is `to_alg_hom R S A`, the canonical `R`-algebra homomorphism `S →ₐ[R] A`.

-/


open_locale Pointwise

universe u v w u₁ v₁

variable (R : Type u) (S : Type v) (A : Type w) (B : Type u₁) (M : Type v₁)

namespace Algebra

variable [CommSemiringₓ R] [Semiringₓ A] [Algebra R A]

variable [AddCommMonoidₓ M] [Module R M] [Module A M] [IsScalarTower R A M]

variable {A}

/-- The `R`-algebra morphism `A → End (M)` corresponding to the representation of the algebra `A`
on the `R`-module `M`.

This is a stronger version of `distrib_mul_action.to_linear_map`, and could also have been
called `algebra.to_module_End`. -/
def lsmul : A →ₐ[R] Module.End R M :=
  { toFun := DistribMulAction.toLinearMap R M, map_one' := LinearMap.ext$ fun _ => one_smul A _,
    map_mul' := fun a b => LinearMap.ext$ smul_assoc a b, map_zero' := LinearMap.ext$ fun _ => zero_smul A _,
    map_add' := fun a b => LinearMap.ext$ fun _ => add_smul _ _ _,
    commutes' := fun r => LinearMap.ext$ algebra_map_smul A r }

@[simp]
theorem lsmul_coe (a : A) : (lsmul R M a : M → M) = (· • ·) a :=
  rfl

theorem lmul_algebra_map (x : R) : lmul R A (algebraMap R A x) = Algebra.lsmul R A x :=
  Eq.symm$ LinearMap.ext$ smul_def x

end Algebra

namespace IsScalarTower

section Module

variable [CommSemiringₓ R] [Semiringₓ A] [Algebra R A]

variable [AddCommMonoidₓ M] [Module R M] [Module A M] [IsScalarTower R A M]

variable {R} (A) {M}

theorem algebra_map_smul (r : R) (x : M) : algebraMap R A r • x = r • x :=
  by 
    rw [Algebra.algebra_map_eq_smul_one, smul_assoc, one_smul]

end Module

section Semiringₓ

variable [CommSemiringₓ R] [CommSemiringₓ S] [Semiringₓ A] [Semiringₓ B]

variable [Algebra R S] [Algebra S A] [Algebra S B]

variable {R S A}

theorem of_algebra_map_eq [Algebra R A] (h : ∀ x, algebraMap R A x = algebraMap S A (algebraMap R S x)) :
  IsScalarTower R S A :=
  ⟨fun x y z =>
      by 
        simpRw [Algebra.smul_def, RingHom.map_mul, mul_assocₓ, h]⟩

/-- See note [partially-applied ext lemmas]. -/
theorem of_algebra_map_eq' [Algebra R A] (h : algebraMap R A = (algebraMap S A).comp (algebraMap R S)) :
  IsScalarTower R S A :=
  of_algebra_map_eq$ RingHom.ext_iff.1 h

variable (R S A)

instance Subalgebra (S₀ : Subalgebra R S) : IsScalarTower S₀ S A :=
  of_algebra_map_eq$ fun x => rfl

variable [Algebra R A] [Algebra R B]

variable [IsScalarTower R S A] [IsScalarTower R S B]

theorem algebra_map_eq : algebraMap R A = (algebraMap S A).comp (algebraMap R S) :=
  RingHom.ext$
    fun x =>
      by 
        simpRw [RingHom.comp_apply, Algebra.algebra_map_eq_smul_one, smul_assoc, one_smul]

theorem algebra_map_apply (x : R) : algebraMap R A x = algebraMap S A (algebraMap R S x) :=
  by 
    rw [algebra_map_eq R S A, RingHom.comp_apply]

instance subalgebra' (S₀ : Subalgebra R S) : IsScalarTower R S₀ A :=
  @IsScalarTower.of_algebra_map_eq R S₀ A _ _ _ _ _ _$ fun _ => (IsScalarTower.algebra_map_apply R S A _ : _)

@[ext]
theorem algebra.ext {S : Type u} {A : Type v} [CommSemiringₓ S] [Semiringₓ A] (h1 h2 : Algebra S A)
  (h :
    ∀ r : S x : A,
      by 
          have  := h1 <;> exact r • x =
        r • x) :
  h1 = h2 :=
  Algebra.algebra_ext _ _$
    fun r =>
      by 
        simpa only [@Algebra.smul_def _ _ _ _ h1, @Algebra.smul_def _ _ _ _ h2, mul_oneₓ] using h r 1

/-- In a tower, the canonical map from the middle element to the top element is an
algebra homomorphism over the bottom element. -/
def to_alg_hom : S →ₐ[R] A :=
  { algebraMap S A with commutes' := fun _ => (algebra_map_apply _ _ _ _).symm }

theorem to_alg_hom_apply (y : S) : to_alg_hom R S A y = algebraMap S A y :=
  rfl

@[simp]
theorem coe_to_alg_hom : ↑to_alg_hom R S A = algebraMap S A :=
  RingHom.ext$ fun _ => rfl

@[simp]
theorem coe_to_alg_hom' : (to_alg_hom R S A : S → A) = algebraMap S A :=
  rfl

variable {R S A B}

@[simp]
theorem _root_.alg_hom.map_algebra_map (f : A →ₐ[S] B) (r : R) : f (algebraMap R A r) = algebraMap R B r :=
  by 
    rw [algebra_map_apply R S A r, f.commutes, ←algebra_map_apply R S B]

variable (R)

@[simp]
theorem _root_.alg_hom.comp_algebra_map_of_tower (f : A →ₐ[S] B) :
  (f : A →+* B).comp (algebraMap R A) = algebraMap R B :=
  RingHom.ext f.map_algebra_map

variable (R) {S A B}

instance (priority := 999) Subsemiring (U : Subsemiring S) : IsScalarTower U S A :=
  of_algebra_map_eq$ fun x => rfl

@[nolint instance_priority]
instance of_ring_hom {R A B : Type _} [CommSemiringₓ R] [CommSemiringₓ A] [CommSemiringₓ B] [Algebra R A] [Algebra R B]
  (f : A →ₐ[R] B) : @IsScalarTower R A B _ f.to_ring_hom.to_algebra.to_has_scalar _ :=
  by 
    let this' := (f : A →+* B).toAlgebra 
    exact of_algebra_map_eq fun x => (f.commutes x).symm

end Semiringₓ

end IsScalarTower

section Homs

variable [CommSemiringₓ R] [CommSemiringₓ S] [Semiringₓ A] [Semiringₓ B]

variable [Algebra R S] [Algebra S A] [Algebra S B]

variable [Algebra R A] [Algebra R B]

variable [IsScalarTower R S A] [IsScalarTower R S B]

variable (R) {A S B}

open IsScalarTower

namespace AlgHom

/-- R ⟶ S induces S-Alg ⥤ R-Alg -/
def restrict_scalars (f : A →ₐ[S] B) : A →ₐ[R] B :=
  { (f : A →+* B) with
    commutes' :=
      fun r =>
        by 
          rw [algebra_map_apply R S A, algebra_map_apply R S B]
          exact f.commutes (algebraMap R S r) }

theorem restrict_scalars_apply (f : A →ₐ[S] B) (x : A) : f.restrict_scalars R x = f x :=
  rfl

@[simp]
theorem coe_restrict_scalars (f : A →ₐ[S] B) : (f.restrict_scalars R : A →+* B) = f :=
  rfl

@[simp]
theorem coe_restrict_scalars' (f : A →ₐ[S] B) : (restrict_scalars R f : A → B) = f :=
  rfl

theorem restrict_scalars_injective : Function.Injective (restrict_scalars R : (A →ₐ[S] B) → A →ₐ[R] B) :=
  fun f g h => AlgHom.ext (AlgHom.congr_fun h : _)

end AlgHom

namespace AlgEquiv

/-- R ⟶ S induces S-Alg ⥤ R-Alg -/
def restrict_scalars (f : A ≃ₐ[S] B) : A ≃ₐ[R] B :=
  { (f : A ≃+* B) with
    commutes' :=
      fun r =>
        by 
          rw [algebra_map_apply R S A, algebra_map_apply R S B]
          exact f.commutes (algebraMap R S r) }

theorem restrict_scalars_apply (f : A ≃ₐ[S] B) (x : A) : f.restrict_scalars R x = f x :=
  rfl

@[simp]
theorem coe_restrict_scalars (f : A ≃ₐ[S] B) : (f.restrict_scalars R : A ≃+* B) = f :=
  rfl

@[simp]
theorem coe_restrict_scalars' (f : A ≃ₐ[S] B) : (restrict_scalars R f : A → B) = f :=
  rfl

theorem restrict_scalars_injective : Function.Injective (restrict_scalars R : (A ≃ₐ[S] B) → A ≃ₐ[R] B) :=
  fun f g h => AlgEquiv.ext (AlgEquiv.congr_fun h : _)

end AlgEquiv

end Homs

namespace Subalgebra

open IsScalarTower

section Semiringₓ

variable (R) {S A B} [CommSemiringₓ R] [CommSemiringₓ S] [Semiringₓ A] [Semiringₓ B]

variable [Algebra R S] [Algebra S A] [Algebra R A] [Algebra S B] [Algebra R B]

variable [IsScalarTower R S A] [IsScalarTower R S B]

/-- Given a scalar tower `R`, `S`, `A` of algebras, reinterpret an `S`-subalgebra of `A` an as an
`R`-subalgebra. -/
def restrict_scalars (U : Subalgebra S A) : Subalgebra R A :=
  { U with
    algebra_map_mem' :=
      fun x =>
        by 
          rw [algebra_map_apply R S A]
          exact U.algebra_map_mem _ }

@[simp]
theorem coe_restrict_scalars {U : Subalgebra S A} : (restrict_scalars R U : Set A) = (U : Set A) :=
  rfl

@[simp]
theorem restrict_scalars_top : restrict_scalars R (⊤ : Subalgebra S A) = ⊤ :=
  SetLike.coe_injective rfl

@[simp]
theorem restrict_scalars_to_submodule {U : Subalgebra S A} :
  (U.restrict_scalars R).toSubmodule = U.to_submodule.restrict_scalars R :=
  SetLike.coe_injective rfl

@[simp]
theorem mem_restrict_scalars {U : Subalgebra S A} {x : A} : x ∈ restrict_scalars R U ↔ x ∈ U :=
  Iff.rfl

theorem restrict_scalars_injective : Function.Injective (restrict_scalars R : Subalgebra S A → Subalgebra R A) :=
  fun U V H =>
    ext$
      fun x =>
        by 
          rw [←mem_restrict_scalars R, H, mem_restrict_scalars]

/-- Produces an `R`-algebra map from `U.restrict_scalars R` given an `S`-algebra map from `U`.

This is a special case of `alg_hom.restrict_scalars` that can be helpful in elaboration. -/
@[simp]
def of_restrict_scalars (U : Subalgebra S A) (f : U →ₐ[S] B) : U.restrict_scalars R →ₐ[R] B :=
  f.restrict_scalars R

end Semiringₓ

end Subalgebra

namespace IsScalarTower

open Subalgebra

variable [CommSemiringₓ R] [CommSemiringₓ S] [CommSemiringₓ A]

variable [Algebra R S] [Algebra S A] [Algebra R A] [IsScalarTower R S A]

theorem adjoin_range_to_alg_hom (t : Set A) :
  (Algebra.adjoin (to_alg_hom R S A).range t).restrictScalars R = (Algebra.adjoin S t).restrictScalars R :=
  Subalgebra.ext$
    fun z =>
      show
        z ∈ Subsemiring.closure (Set.Range (algebraMap (to_alg_hom R S A).range A) ∪ t : Set A) ↔
          z ∈ Subsemiring.closure (Set.Range (algebraMap S A) ∪ t : Set A) from
        suffices Set.Range (algebraMap (to_alg_hom R S A).range A) = Set.Range (algebraMap S A)by 
          rw [this]
        by 
          ext z 
          exact ⟨fun ⟨⟨x, y, h1⟩, h2⟩ => ⟨y, h2 ▸ h1⟩, fun ⟨y, hy⟩ => ⟨⟨z, y, hy⟩, rfl⟩⟩

end IsScalarTower

section Semiringₓ

variable {R S A}

variable [CommSemiringₓ R] [Semiringₓ S] [AddCommMonoidₓ A]

variable [Algebra R S] [Module S A] [Module R A] [IsScalarTower R S A]

namespace Submodule

open IsScalarTower

theorem smul_mem_span_smul_of_mem {s : Set S} {t : Set A} {k : S} (hks : k ∈ span R s) {x : A} (hx : x ∈ t) :
  k • x ∈ span R (s • t) :=
  span_induction hks (fun c hc => subset_span$ Set.mem_smul.2 ⟨c, x, hc, hx, rfl⟩)
    (by 
      rw [zero_smul]
      exact zero_mem _)
    (fun c₁ c₂ ih₁ ih₂ =>
      by 
        rw [add_smul]
        exact add_mem _ ih₁ ih₂)
    fun b c hc =>
      by 
        rw [IsScalarTower.smul_assoc]
        exact smul_mem _ _ hc

theorem smul_mem_span_smul {s : Set S} (hs : span R s = ⊤) {t : Set A} {k : S} {x : A} (hx : x ∈ span R t) :
  k • x ∈ span R (s • t) :=
  span_induction hx (fun x hx => smul_mem_span_smul_of_mem (hs.symm ▸ mem_top) hx)
    (by 
      rw [smul_zero]
      exact zero_mem _)
    (fun x y ihx ihy =>
      by 
        rw [smul_add]
        exact add_mem _ ihx ihy)
    fun c x hx => smul_comm c k x ▸ smul_mem _ _ hx

theorem smul_mem_span_smul' {s : Set S} (hs : span R s = ⊤) {t : Set A} {k : S} {x : A} (hx : x ∈ span R (s • t)) :
  k • x ∈ span R (s • t) :=
  span_induction hx
    (fun x hx =>
      let ⟨p, q, hp, hq, hpq⟩ := Set.mem_smul.1 hx 
      by 
        rw [←hpq, smul_smul]
        exact smul_mem_span_smul_of_mem (hs.symm ▸ mem_top) hq)
    (by 
      rw [smul_zero]
      exact zero_mem _)
    (fun x y ihx ihy =>
      by 
        rw [smul_add]
        exact add_mem _ ihx ihy)
    fun c x hx => smul_comm c k x ▸ smul_mem _ _ hx

theorem span_smul {s : Set S} (hs : span R s = ⊤) (t : Set A) : span R (s • t) = (span S t).restrictScalars R :=
  le_antisymmₓ
      (span_le.2$
        fun x hx =>
          let ⟨p, q, hps, hqt, hpqx⟩ := Set.mem_smul.1 hx 
          hpqx ▸ (span S t).smul_mem p (subset_span hqt))$
    fun p hp =>
      span_induction hp (fun x hx => one_smul S x ▸ smul_mem_span_smul hs (subset_span hx)) (zero_mem _)
        (fun _ _ => add_mem _) fun k x hx => smul_mem_span_smul' hs hx

end Submodule

end Semiringₓ

section Ringₓ

namespace Algebra

variable [CommSemiringₓ R] [Ringₓ A] [Algebra R A]

variable [AddCommGroupₓ M] [Module A M] [Module R M] [IsScalarTower R A M]

theorem lsmul_injective [NoZeroSmulDivisors A M] {x : A} (hx : x ≠ 0) : Function.Injective (lsmul R M x) :=
  smul_right_injective _ hx

end Algebra

end Ringₓ

