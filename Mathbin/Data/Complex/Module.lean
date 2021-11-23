import Mathbin.Algebra.Order.Smul 
import Mathbin.Data.Complex.Basic 
import Mathbin.Data.Fin.VecNotation 
import Mathbin.FieldTheory.Tower

/-!
# Complex number as a vector space over `ℝ`

This file contains the following instances:
* Any `•`-structure (`has_scalar`, `mul_action`, `distrib_mul_action`, `module`, `algebra`) on
  `ℝ` imbues a corresponding structure on `ℂ`. This includes the statement that `ℂ` is an `ℝ`
  algebra.
* any complex vector space is a real vector space;
* any finite dimensional complex vector space is a finite dimensional real vector space;
* the space of `ℝ`-linear maps from a real vector space to a complex vector space is a complex
  vector space.

It also defines bundled versions of four standard maps (respectively, the real part, the imaginary
part, the embedding of `ℝ` in `ℂ`, and the complex conjugate):

* `complex.re_lm` (`ℝ`-linear map);
* `complex.im_lm` (`ℝ`-linear map);
* `complex.of_real_am` (`ℝ`-algebra (homo)morphism);
* `complex.conj_ae` (`ℝ`-algebra equivalence).

It also provides a universal property of the complex numbers `complex.lift`, which constructs a
`ℂ →ₐ[ℝ] A` into any `ℝ`-algebra `A` given a square root of `-1`.

-/


namespace Complex

open_locale ComplexConjugate

variable{R : Type _}{S : Type _}

section 

variable[HasScalar R ℝ]

instance  : HasScalar R ℂ :=
  { smul := fun r x => ⟨r • x.re - 0*x.im, (r • x.im)+0*x.re⟩ }

theorem smul_re (r : R) (z : ℂ) : (r • z).re = r • z.re :=
  by 
    simp [· • ·]

theorem smul_im (r : R) (z : ℂ) : (r • z).im = r • z.im :=
  by 
    simp [· • ·]

@[simp]
theorem real_smul {x : ℝ} {z : ℂ} : x • z = x*z :=
  rfl

end 

instance  [HasScalar R ℝ] [HasScalar S ℝ] [SmulCommClass R S ℝ] : SmulCommClass R S ℂ :=
  { smul_comm :=
      fun r s x =>
        by 
          ext <;> simp [smul_re, smul_im, smul_comm] }

instance  [HasScalar R S] [HasScalar R ℝ] [HasScalar S ℝ] [IsScalarTower R S ℝ] : IsScalarTower R S ℂ :=
  { smul_assoc :=
      fun r s x =>
        by 
          ext <;> simp [smul_re, smul_im, smul_assoc] }

instance  [Monoidₓ R] [MulAction R ℝ] : MulAction R ℂ :=
  { one_smul :=
      fun x =>
        by 
          ext <;> simp [smul_re, smul_im, one_smul],
    mul_smul :=
      fun r s x =>
        by 
          ext <;> simp [smul_re, smul_im, mul_smul] }

instance  [Semiringₓ R] [DistribMulAction R ℝ] : DistribMulAction R ℂ :=
  { smul_add :=
      fun r x y =>
        by 
          ext <;> simp [smul_re, smul_im, smul_add],
    smul_zero :=
      fun r =>
        by 
          ext <;> simp [smul_re, smul_im, smul_zero] }

instance  [Semiringₓ R] [Module R ℝ] : Module R ℂ :=
  { add_smul :=
      fun r s x =>
        by 
          ext <;> simp [smul_re, smul_im, add_smul],
    zero_smul :=
      fun r =>
        by 
          ext <;> simp [smul_re, smul_im, zero_smul] }

instance  [CommSemiringₓ R] [Algebra R ℝ] : Algebra R ℂ :=
  { Complex.ofReal.comp (algebraMap R ℝ) with smul := · • ·,
    smul_def' :=
      fun r x =>
        by 
          ext <;> simp [smul_re, smul_im, Algebra.smul_def],
    commutes' :=
      fun r ⟨xr, xi⟩ =>
        by 
          ext <;> simp [smul_re, smul_im, Algebra.commutes] }

@[simp]
theorem coe_algebra_map : (algebraMap ℝ ℂ : ℝ → ℂ) = coeₓ :=
  rfl

section 

variable{A : Type _}[Semiringₓ A][Algebra ℝ A]

/-- We need this lemma since `complex.coe_algebra_map` diverts the simp-normal form away from
`alg_hom.commutes`. -/
@[simp]
theorem _root_.alg_hom.map_coe_real_complex (f : ℂ →ₐ[ℝ] A) (x : ℝ) : f x = algebraMap ℝ A x :=
  f.commutes x

/-- Two `ℝ`-algebra homomorphisms from ℂ are equal if they agree on `complex.I`. -/
@[ext]
theorem alg_hom_ext ⦃f g : ℂ →ₐ[ℝ] A⦄ (h : f I = g I) : f = g :=
  by 
    ext ⟨x, y⟩
    simp only [mk_eq_add_mul_I, AlgHom.map_add, AlgHom.map_coe_real_complex, AlgHom.map_mul, h]

end 

section 

open_locale ComplexOrder

protected theorem OrderedSmul : OrderedSmul ℝ ℂ :=
  OrderedSmul.mk'$
    fun a b r hab hr =>
      ⟨by 
          simp [hr, hab.1.le],
        by 
          simp [hab.2]⟩

localized [ComplexOrder] attribute [instance] Complex.ordered_smul

end 

open Submodule FiniteDimensional

-- error in Data.Complex.Module: ././Mathport/Syntax/Translate/Basic.lean:558:61: unsupported notation `«expr![ , ]»
/-- `ℂ` has a basis over `ℝ` given by `1` and `I`. -/ noncomputable def basis_one_I : basis (fin 2) exprℝ() exprℂ() :=
basis.of_equiv_fun { to_fun := λ z, «expr![ , ]»([z.re, z.im]),
  inv_fun := λ c, «expr + »(c 0, «expr • »(c 1, I)),
  left_inv := λ z, by simp [] [] [] [] [] [],
  right_inv := λ c, by { ext [] [ident i] [],
    fin_cases [ident i] []; simp [] [] [] [] [] [] },
  map_add' := λ z z', by simp [] [] [] [] [] [],
  map_smul' := λ c z, by simp [] [] [] [] [] [] }

-- error in Data.Complex.Module: ././Mathport/Syntax/Translate/Basic.lean:558:61: unsupported notation `«expr![ , ]»
@[simp]
theorem coe_basis_one_I_repr (z : exprℂ()) : «expr = »(«expr⇑ »(basis_one_I.repr z), «expr![ , ]»([z.re, z.im])) :=
rfl

-- error in Data.Complex.Module: ././Mathport/Syntax/Translate/Basic.lean:558:61: unsupported notation `«expr![ , ]»
@[simp] theorem coe_basis_one_I : «expr = »(«expr⇑ »(basis_one_I), «expr![ , ]»([1, I])) :=
«expr $ »(funext, λ
 i, «expr $ »(basis.apply_eq_iff.mpr, «expr $ »(finsupp.ext, λ
   j, by fin_cases [ident i] []; fin_cases [ident j] []; simp [] [] ["only"] ["[", expr coe_basis_one_I_repr, ",", expr finsupp.single_eq_same, ",", expr finsupp.single_eq_of_ne, ",", expr matrix.cons_val_zero, ",", expr matrix.cons_val_one, ",", expr matrix.head_cons, ",", expr nat.one_ne_zero, ",", expr fin.one_eq_zero_iff, ",", expr fin.zero_eq_one_iff, ",", expr ne.def, ",", expr not_false_iff, ",", expr one_re, ",", expr one_im, ",", expr I_re, ",", expr I_im, "]"] [] [])))

instance  : FiniteDimensional ℝ ℂ :=
  of_fintype_basis basis_one_I

@[simp]
theorem finrank_real_complex : FiniteDimensional.finrank ℝ ℂ = 2 :=
  by 
    rw [finrank_eq_card_basis basis_one_I, Fintype.card_fin]

@[simp]
theorem dim_real_complex : Module.rank ℝ ℂ = 2 :=
  by 
    simp [←finrank_eq_dim, finrank_real_complex]

theorem dim_real_complex'.{u} : Cardinal.lift.{u} (Module.rank ℝ ℂ) = 2 :=
  by 
    simp [←finrank_eq_dim, finrank_real_complex, bit0]

/-- `fact` version of the dimension of `ℂ` over `ℝ`, locally useful in the definition of the
circle. -/
theorem finrank_real_complex_fact : Fact (finrank ℝ ℂ = 2) :=
  ⟨finrank_real_complex⟩

end Complex

instance (priority := 900)Module.complexToReal (E : Type _) [AddCommGroupₓ E] [Module ℂ E] : Module ℝ E :=
  RestrictScalars.module ℝ ℂ E

instance Module.real_complex_tower (E : Type _) [AddCommGroupₓ E] [Module ℂ E] : IsScalarTower ℝ ℂ E :=
  RestrictScalars.is_scalar_tower ℝ ℂ E

@[simp, normCast]
theorem Complex.coe_smul {E : Type _} [AddCommGroupₓ E] [Module ℂ E] (x : ℝ) (y : E) : (x : ℂ) • y = x • y :=
  rfl

instance (priority := 100)FiniteDimensional.complex_to_real (E : Type _) [AddCommGroupₓ E] [Module ℂ E]
  [FiniteDimensional ℂ E] : FiniteDimensional ℝ E :=
  FiniteDimensional.trans ℝ ℂ E

theorem dim_real_of_complex (E : Type _) [AddCommGroupₓ E] [Module ℂ E] : Module.rank ℝ E = 2*Module.rank ℂ E :=
  Cardinal.lift_inj.1$
    by 
      rw [←dim_mul_dim' ℝ ℂ E, Complex.dim_real_complex]
      simp [bit0]

theorem finrank_real_of_complex (E : Type _) [AddCommGroupₓ E] [Module ℂ E] :
  FiniteDimensional.finrank ℝ E = 2*FiniteDimensional.finrank ℂ E :=
  by 
    rw [←FiniteDimensional.finrank_mul_finrank ℝ ℂ E, Complex.finrank_real_complex]

namespace Complex

open_locale ComplexConjugate

/-- Linear map version of the real part function, from `ℂ` to `ℝ`. -/
def re_lm : ℂ →ₗ[ℝ] ℝ :=
  { toFun := fun x => x.re, map_add' := add_re,
    map_smul' :=
      by 
        simp  }

@[simp]
theorem re_lm_coe : «expr⇑ » re_lm = re :=
  rfl

/-- Linear map version of the imaginary part function, from `ℂ` to `ℝ`. -/
def im_lm : ℂ →ₗ[ℝ] ℝ :=
  { toFun := fun x => x.im, map_add' := add_im,
    map_smul' :=
      by 
        simp  }

@[simp]
theorem im_lm_coe : «expr⇑ » im_lm = im :=
  rfl

/-- `ℝ`-algebra morphism version of the canonical embedding of `ℝ` in `ℂ`. -/
def of_real_am : ℝ →ₐ[ℝ] ℂ :=
  Algebra.ofId ℝ ℂ

@[simp]
theorem of_real_am_coe : «expr⇑ » of_real_am = coeₓ :=
  rfl

/-- `ℝ`-algebra isomorphism version of the complex conjugation function from `ℂ` to `ℂ` -/
def conj_ae : ℂ ≃ₐ[ℝ] ℂ :=
  { conj with invFun := conj, left_inv := star_star, right_inv := star_star, commutes' := conj_of_real }

@[simp]
theorem conj_ae_coe : «expr⇑ » conj_ae = conj :=
  rfl

section lift

variable{A : Type _}[Ringₓ A][Algebra ℝ A]

/-- There is an alg_hom from `ℂ` to any `ℝ`-algebra with an element that squares to `-1`.

See `complex.lift` for this as an equiv. -/
def lift_aux (I' : A) (hf : (I'*I') = -1) : ℂ →ₐ[ℝ] A :=
  AlgHom.ofLinearMap ((Algebra.ofId ℝ A).toLinearMap.comp re_lm+(LinearMap.toSpanSingleton _ _ I').comp im_lm)
    (show (algebraMap ℝ A 1+(0 : ℝ) • I') = 1by 
      rw [RingHom.map_one, zero_smul, add_zeroₓ])
    fun ⟨x₁, y₁⟩ ⟨x₂, y₂⟩ =>
      show
        (algebraMap ℝ A ((x₁*x₂) - y₁*y₂)+((x₁*y₂)+y₁*x₂) • I') =
          (algebraMap ℝ A x₁+y₁ • I')*algebraMap ℝ A x₂+y₂ • I' by
        
        rw [add_mulₓ, mul_addₓ, mul_addₓ, add_commₓ _ ((y₁ • I')*y₂ • I'), add_add_add_commₓ]
        congr 1
        ·
          rw [smul_mul_smul, hf, smul_neg, ←Algebra.algebra_map_eq_smul_one, ←sub_eq_add_neg, ←RingHom.map_mul,
            ←RingHom.map_sub]
        ·
          rw [Algebra.smul_def, Algebra.smul_def, Algebra.smul_def, ←Algebra.right_comm _ x₂, ←mul_assocₓ, ←add_mulₓ,
            ←RingHom.map_mul, ←RingHom.map_mul, ←RingHom.map_add]

@[simp]
theorem lift_aux_apply (I' : A) hI' (z : ℂ) : lift_aux I' hI' z = algebraMap ℝ A z.re+z.im • I' :=
  rfl

theorem lift_aux_apply_I (I' : A) hI' : lift_aux I' hI' I = I' :=
  by 
    simp 

/-- A universal property of the complex numbers, providing a unique `ℂ →ₐ[ℝ] A` for every element
of `A` which squares to `-1`.

This can be used to embed the complex numbers in the `quaternion`s.

This isomorphism is named to match the very similar `zsqrtd.lift`. -/
@[simps (config := { simpRhs := tt })]
def lift : { I' : A // (I'*I') = -1 } ≃ (ℂ →ₐ[ℝ] A) :=
  { toFun := fun I' => lift_aux I' I'.prop,
    invFun :=
      fun F =>
        ⟨F I,
          by 
            rw [←F.map_mul, I_mul_I, AlgHom.map_neg, AlgHom.map_one]⟩,
    left_inv := fun I' => Subtype.ext$ lift_aux_apply_I I' I'.prop,
    right_inv := fun F => alg_hom_ext$ lift_aux_apply_I _ _ }

@[simp]
theorem lift_aux_I : lift_aux I I_mul_I = AlgHom.id ℝ ℂ :=
  alg_hom_ext$ lift_aux_apply_I _ _

@[simp]
theorem lift_aux_neg_I : lift_aux (-I) ((neg_mul_neg _ _).trans I_mul_I) = conj_ae :=
  alg_hom_ext$ (lift_aux_apply_I _ _).trans conj_I.symm

end lift

end Complex

