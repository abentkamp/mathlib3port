/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import Mathbin.RingTheory.Algebraic
import Mathbin.RingTheory.Localization.AtPrime
import Mathbin.RingTheory.Localization.Integral

/-!
# Ideals over/under ideals

This file concerns ideals lying over other ideals.
Let `f : R →+* S` be a ring homomorphism (typically a ring extension), `I` an ideal of `R` and
`J` an ideal of `S`. We say `J` lies over `I` (and `I` under `J`) if `I` is the `f`-preimage of `J`.
This is expressed here by writing `I = J.comap f`.

## Implementation notes

The proofs of the `comap_ne_bot` and `comap_lt_comap` families use an approach
specific for their situation: we construct an element in `I.comap f` from the
coefficients of a minimal polynomial.
Once mathlib has more material on the localization at a prime ideal, the results
can be proven using more general going-up/going-down theory.
-/


variable {R : Type _} [CommRingₓ R]

namespace Ideal

open Polynomial

open Polynomial

open Submodule

section CommRingₓ

variable {S : Type _} [CommRingₓ S] {f : R →+* S} {I J : Ideal S}

theorem coeff_zero_mem_comap_of_root_mem_of_eval_mem {r : S} (hr : r ∈ I) {p : R[X]} (hp : p.eval₂ f r ∈ I) :
    p.coeff 0 ∈ I.comap f := by
  rw [← p.div_X_mul_X_add, eval₂_add, eval₂_C, eval₂_mul, eval₂_X] at hp
  refine' mem_comap.mpr ((I.add_mem_iff_right _).mp hp)
  exact I.mul_mem_left _ hr

theorem coeff_zero_mem_comap_of_root_mem {r : S} (hr : r ∈ I) {p : R[X]} (hp : p.eval₂ f r = 0) :
    p.coeff 0 ∈ I.comap f :=
  coeff_zero_mem_comap_of_root_mem_of_eval_mem hr (hp.symm ▸ I.zero_mem)

theorem exists_coeff_ne_zero_mem_comap_of_non_zero_divisor_root_mem {r : S}
    (r_non_zero_divisor : ∀ {x}, x * r = 0 → x = 0) (hr : r ∈ I) {p : R[X]} :
    ∀ (p_ne_zero : p ≠ 0) (hp : p.eval₂ f r = 0), ∃ i, p.coeff i ≠ 0 ∧ p.coeff i ∈ I.comap f := by
  refine' p.rec_on_horner _ _ _
  · intro h
    contradiction
    
  · intro p a coeff_eq_zero a_ne_zero ih p_ne_zero hp
    refine' ⟨0, _, coeff_zero_mem_comap_of_root_mem hr hp⟩
    simp [coeff_eq_zero, a_ne_zero]
    
  · intro p p_nonzero ih mul_nonzero hp
    rw [eval₂_mul, eval₂_X] at hp
    obtain ⟨i, hi, mem⟩ := ih p_nonzero (r_non_zero_divisor hp)
    refine' ⟨i + 1, _, _⟩ <;> simp [hi, mem]
    

/-- Let `P` be an ideal in `R[x]`.  The map
`R[x]/P → (R / (P ∩ R))[x] / (P / (P ∩ R))`
is injective.
-/
theorem injective_quotient_le_comap_map (P : Ideal R[X]) :
    Function.Injective
      ((map (mapRingHom (Quotient.mk (P.comap (c : R →+* R[X])))) P).quotientMap
        (mapRingHom (Quotient.mk (P.comap (c : R →+* R[X])))) le_comap_map) :=
  by
  refine' quotient_map_injective' (le_of_eqₓ _)
  rw
    [comap_map_of_surjective (map_ring_hom (Quotientₓ.mk (P.comap (C : R →+* R[X]))))
      (map_surjective (Quotientₓ.mk (P.comap (C : R →+* R[X]))) quotient.mk_surjective)]
  refine' le_antisymmₓ (sup_le le_rflₓ _) (le_sup_of_le_left le_rflₓ)
  refine' fun p hp => polynomial_mem_ideal_of_coeff_mem_ideal P p fun n => quotient.eq_zero_iff_mem.mp _
  simpa only [coeff_map, coe_map_ring_hom] using ext_iff.mp (ideal.mem_bot.mp (mem_comap.mp hp)) n

/-- The identity in this lemma asserts that the "obvious" square
```
    R    → (R / (P ∩ R))
    ↓          ↓
R[x] / P → (R / (P ∩ R))[x] / (P / (P ∩ R))
```
commutes.  It is used, for instance, in the proof of `quotient_mk_comp_C_is_integral_of_jacobson`,
in the file `ring_theory/jacobson`.
-/
theorem quotient_mk_maps_eq (P : Ideal R[X]) :
    ((Quotient.mk (map (mapRingHom (Quotient.mk (P.comap (c : R →+* R[X])))) P)).comp c).comp
        (Quotient.mk (P.comap (c : R →+* R[X]))) =
      ((map (mapRingHom (Quotient.mk (P.comap (c : R →+* R[X])))) P).quotientMap
            (mapRingHom (Quotient.mk (P.comap (c : R →+* R[X])))) le_comap_map).comp
        ((Quotient.mk P).comp c) :=
  by
  refine' RingHom.ext fun x => _
  repeat'
    rw [RingHom.coe_comp, Function.comp_app]
  rw [quotient_map_mk, coe_map_ring_hom, map_C]

/-- This technical lemma asserts the existence of a polynomial `p` in an ideal `P ⊂ R[x]`
that is non-zero in the quotient `R / (P ∩ R) [x]`.  The assumptions are equivalent to
`P ≠ 0` and `P ∩ R = (0)`.
-/
theorem exists_nonzero_mem_of_ne_bot {P : Ideal R[X]} (Pb : P ≠ ⊥) (hP : ∀ x : R, c x ∈ P → x = 0) :
    ∃ p : R[X], p ∈ P ∧ Polynomial.map (Quotient.mk (P.comap (c : R →+* R[X]))) p ≠ 0 := by
  obtain ⟨m, hm⟩ := Submodule.nonzero_mem_of_bot_lt (bot_lt_iff_ne_bot.mpr Pb)
  refine' ⟨m, Submodule.coe_mem m, fun pp0 => hm (submodule.coe_eq_zero.mp _)⟩
  refine' (injective_iff_map_eq_zero (Polynomial.mapRingHom (Quotientₓ.mk (P.comap (C : R →+* R[X]))))).mp _ _ pp0
  refine' map_injective _ ((Quotientₓ.mk (P.comap C)).injective_iff_ker_eq_bot.mpr _)
  rw [mk_ker]
  exact (Submodule.eq_bot_iff _).mpr fun x hx => hP x (mem_comap.mp hx)

variable {p : Ideal R} {P : Ideal S}

/-- If there is an injective map `R/p → S/P` such that following diagram commutes:
```
R   → S
↓     ↓
R/p → S/P
```
then `P` lies over `p`.
-/
theorem comap_eq_of_scalar_tower_quotient [Algebra R S] [Algebra (R ⧸ p) (S ⧸ P)] [IsScalarTower R (R ⧸ p) (S ⧸ P)]
    (h : Function.Injective (algebraMap (R ⧸ p) (S ⧸ P))) : comap (algebraMap R S) P = p := by
  ext x
  constructor <;>
    rw [mem_comap, ← quotient.eq_zero_iff_mem, ← quotient.eq_zero_iff_mem, quotient.mk_algebra_map,
      IsScalarTower.algebra_map_apply _ (R ⧸ p), quotient.algebra_map_eq]
  · intro hx
    exact (injective_iff_map_eq_zero (algebraMap (R ⧸ p) (S ⧸ P))).mp h _ hx
    
  · intro hx
    rw [hx, RingHom.map_zero]
    

/-- If `P` lies over `p`, then `R / p` has a canonical map to `S / P`. -/
def Quotient.algebraQuotientOfLeComap (h : p ≤ comap f P) : Algebra (R ⧸ p) (S ⧸ P) :=
  RingHom.toAlgebra <| quotientMap _ f h

/-- `R / p` has a canonical map to `S / pS`. -/
instance Quotient.algebraQuotientMapQuotient : Algebra (R ⧸ p) (S ⧸ map f p) :=
  quotient.algebra_quotient_of_le_comap le_comap_map

@[simp]
theorem Quotient.algebra_map_quotient_map_quotient (x : R) :
    algebraMap (R ⧸ p) (S ⧸ map f p) (Quotient.mk p x) = Quotient.mk _ (f x) :=
  rfl

@[simp]
theorem Quotient.mk_smul_mk_quotient_map_quotient (x : R) (y : S) :
    Quotient.mk p x • Quotient.mk (map f p) y = Quotient.mk _ (f x * y) :=
  rfl

instance Quotient.tower_quotient_map_quotient [Algebra R S] : IsScalarTower R (R ⧸ p) (S ⧸ map (algebraMap R S) p) :=
  IsScalarTower.of_algebra_map_eq fun x => by
    rw [quotient.algebra_map_eq, quotient.algebra_map_quotient_map_quotient, quotient.mk_algebra_map]

instance QuotientMapQuotient.is_noetherian [Algebra R S] [IsNoetherian R S] (I : Ideal R) :
    IsNoetherian (R ⧸ I) (S ⧸ Ideal.map (algebraMap R S) I) :=
  is_noetherian_of_tower R <|
    is_noetherian_of_surjective S (Ideal.Quotient.mkₐ R _).toLinearMap <|
      LinearMap.range_eq_top.mpr Ideal.Quotient.mk_surjective

end CommRingₓ

section IsDomain

variable {S : Type _} [CommRingₓ S] {f : R →+* S} {I J : Ideal S}

theorem exists_coeff_ne_zero_mem_comap_of_root_mem [IsDomain S] {r : S} (r_ne_zero : r ≠ 0) (hr : r ∈ I) {p : R[X]} :
    ∀ (p_ne_zero : p ≠ 0) (hp : p.eval₂ f r = 0), ∃ i, p.coeff i ≠ 0 ∧ p.coeff i ∈ I.comap f :=
  exists_coeff_ne_zero_mem_comap_of_non_zero_divisor_root_mem (fun _ h => Or.resolve_right (mul_eq_zero.mp h) r_ne_zero)
    hr

theorem exists_coeff_mem_comap_sdiff_comap_of_root_mem_sdiff [IsPrime I] (hIJ : I ≤ J) {r : S}
    (hr : r ∈ (J : Set S) \ I) {p : R[X]} (p_ne_zero : p.map (Quotient.mk (I.comap f)) ≠ 0) (hpI : p.eval₂ f r ∈ I) :
    ∃ i, p.coeff i ∈ (J.comap f : Set R) \ I.comap f := by
  obtain ⟨hrJ, hrI⟩ := hr
  have rbar_ne_zero : Quotientₓ.mk I r ≠ 0 := mt (quotient.mk_eq_zero I).mp hrI
  have rbar_mem_J : Quotientₓ.mk I r ∈ J.map (Quotientₓ.mk I) := mem_map_of_mem _ hrJ
  have quotient_f : ∀ x ∈ I.comap f, (Quotientₓ.mk I).comp f x = 0 := by
    simp [quotient.eq_zero_iff_mem]
  have rbar_root :
    (p.map (Quotientₓ.mk (I.comap f))).eval₂ (Quotientₓ.lift (I.comap f) _ quotient_f) (Quotientₓ.mk I r) = 0 := by
    convert quotient.eq_zero_iff_mem.mpr hpI
    exact trans (eval₂_map _ _ _) (hom_eval₂ p f (Quotientₓ.mk I) r).symm
  obtain ⟨i, ne_zero, mem⟩ := exists_coeff_ne_zero_mem_comap_of_root_mem rbar_ne_zero rbar_mem_J p_ne_zero rbar_root
  rw [coeff_map] at ne_zero mem
  refine' ⟨i, (mem_quotient_iff_mem hIJ).mp _, mt _ NeZero⟩
  · simpa using mem
    
  simp [quotient.eq_zero_iff_mem]

theorem comap_lt_comap_of_root_mem_sdiff [I.IsPrime] (hIJ : I ≤ J) {r : S} (hr : r ∈ (J : Set S) \ I) {p : R[X]}
    (p_ne_zero : p.map (Quotient.mk (I.comap f)) ≠ 0) (hp : p.eval₂ f r ∈ I) : I.comap f < J.comap f :=
  let ⟨i, hJ, hI⟩ := exists_coeff_mem_comap_sdiff_comap_of_root_mem_sdiff hIJ hr p_ne_zero hp
  SetLike.lt_iff_le_and_exists.mpr ⟨comap_mono hIJ, p.coeff i, hJ, hI⟩

theorem mem_of_one_mem (h : (1 : S) ∈ I) (x) : x ∈ I :=
  (I.eq_top_iff_one.mpr h).symm ▸ mem_top

theorem comap_lt_comap_of_integral_mem_sdiff [Algebra R S] [hI : I.IsPrime] (hIJ : I ≤ J) {x : S}
    (mem : x ∈ (J : Set S) \ I) (integral : IsIntegral R x) : I.comap (algebraMap R S) < J.comap (algebraMap R S) := by
  obtain ⟨p, p_monic, hpx⟩ := integral
  refine' comap_lt_comap_of_root_mem_sdiff hIJ mem _ _
  swap
  · apply map_monic_ne_zero p_monic
    apply quotient.nontrivial
    apply mt comap_eq_top_iff.mp
    apply hI.1
    
  convert I.zero_mem

theorem comap_ne_bot_of_root_mem [IsDomain S] {r : S} (r_ne_zero : r ≠ 0) (hr : r ∈ I) {p : R[X]} (p_ne_zero : p ≠ 0)
    (hp : p.eval₂ f r = 0) : I.comap f ≠ ⊥ := fun h =>
  let ⟨i, hi, mem⟩ := exists_coeff_ne_zero_mem_comap_of_root_mem r_ne_zero hr p_ne_zero hp
  absurd (mem_bot.mp (eq_bot_iff.mp h mem)) hi

theorem is_maximal_of_is_integral_of_is_maximal_comap [Algebra R S] (hRS : Algebra.IsIntegral R S) (I : Ideal S)
    [I.IsPrime] (hI : IsMaximal (I.comap (algebraMap R S))) : IsMaximal I :=
  ⟨⟨mt comap_eq_top_iff.mpr hI.1.1, fun J I_lt_J =>
      let ⟨I_le_J, x, hxJ, hxI⟩ := SetLike.lt_iff_le_and_exists.mp I_lt_J
      comap_eq_top_iff.1 <| hI.1.2 _ (comap_lt_comap_of_integral_mem_sdiff I_le_J ⟨hxJ, hxI⟩ (hRS x))⟩⟩

theorem is_maximal_of_is_integral_of_is_maximal_comap' (f : R →+* S) (hf : f.IsIntegral) (I : Ideal S) [hI' : I.IsPrime]
    (hI : IsMaximal (I.comap f)) : IsMaximal I :=
  @is_maximal_of_is_integral_of_is_maximal_comap R _ S _ f.toAlgebra hf I hI' hI

variable [Algebra R S]

theorem comap_ne_bot_of_algebraic_mem [IsDomain S] {x : S} (x_ne_zero : x ≠ 0) (x_mem : x ∈ I) (hx : IsAlgebraic R x) :
    I.comap (algebraMap R S) ≠ ⊥ :=
  let ⟨p, p_ne_zero, hp⟩ := hx
  comap_ne_bot_of_root_mem x_ne_zero x_mem p_ne_zero hp

theorem comap_ne_bot_of_integral_mem [Nontrivial R] [IsDomain S] {x : S} (x_ne_zero : x ≠ 0) (x_mem : x ∈ I)
    (hx : IsIntegral R x) : I.comap (algebraMap R S) ≠ ⊥ :=
  comap_ne_bot_of_algebraic_mem x_ne_zero x_mem (hx.IsAlgebraic R)

theorem eq_bot_of_comap_eq_bot [Nontrivial R] [IsDomain S] (hRS : Algebra.IsIntegral R S)
    (hI : I.comap (algebraMap R S) = ⊥) : I = ⊥ := by
  refine' eq_bot_iff.2 fun x hx => _
  by_cases' hx0 : x = 0
  · exact hx0.symm ▸ Ideal.zero_mem ⊥
    
  · exact absurd hI (comap_ne_bot_of_integral_mem hx0 hx (hRS x))
    

theorem is_maximal_comap_of_is_integral_of_is_maximal (hRS : Algebra.IsIntegral R S) (I : Ideal S) [hI : I.IsMaximal] :
    IsMaximal (I.comap (algebraMap R S)) := by
  refine' quotient.maximal_of_is_field _ _
  haveI : is_prime (I.comap (algebraMap R S)) := comap_is_prime _ _
  exact
    is_field_of_is_integral_of_is_field (is_integral_quotient_of_is_integral hRS) algebra_map_quotient_injective
      (by
        rwa [← quotient.maximal_ideal_iff_is_field_quotient])

theorem is_maximal_comap_of_is_integral_of_is_maximal' {R S : Type _} [CommRingₓ R] [CommRingₓ S] (f : R →+* S)
    (hf : f.IsIntegral) (I : Ideal S) (hI : I.IsMaximal) : IsMaximal (I.comap f) :=
  @is_maximal_comap_of_is_integral_of_is_maximal R _ S _ f.toAlgebra hf I hI

section IsIntegralClosure

variable (S) {A : Type _} [CommRingₓ A]

variable [Algebra R A] [Algebra A S] [IsScalarTower R A S] [IsIntegralClosure A R S]

theorem IsIntegralClosure.comap_lt_comap {I J : Ideal A} [I.IsPrime] (I_lt_J : I < J) :
    I.comap (algebraMap R A) < J.comap (algebraMap R A) :=
  let ⟨I_le_J, x, hxJ, hxI⟩ := SetLike.lt_iff_le_and_exists.mp I_lt_J
  comap_lt_comap_of_integral_mem_sdiff I_le_J ⟨hxJ, hxI⟩ (IsIntegralClosure.is_integral R S x)

theorem IsIntegralClosure.is_maximal_of_is_maximal_comap (I : Ideal A) [I.IsPrime]
    (hI : IsMaximal (I.comap (algebraMap R A))) : IsMaximal I :=
  is_maximal_of_is_integral_of_is_maximal_comap (fun x => IsIntegralClosure.is_integral R S x) I hI

variable [IsDomain A]

theorem IsIntegralClosure.comap_ne_bot [Nontrivial R] {I : Ideal A} (I_ne_bot : I ≠ ⊥) : I.comap (algebraMap R A) ≠ ⊥ :=
  let ⟨x, x_mem, x_ne_zero⟩ := I.ne_bot_iff.mp I_ne_bot
  comap_ne_bot_of_integral_mem x_ne_zero x_mem (IsIntegralClosure.is_integral R S x)

theorem IsIntegralClosure.eq_bot_of_comap_eq_bot [Nontrivial R] {I : Ideal A} : I.comap (algebraMap R A) = ⊥ → I = ⊥ :=
  imp_of_not_imp_not _ _ (IsIntegralClosure.comap_ne_bot S)

end IsIntegralClosure

theorem IntegralClosure.comap_lt_comap {I J : Ideal (integralClosure R S)} [I.IsPrime] (I_lt_J : I < J) :
    I.comap (algebraMap R (integralClosure R S)) < J.comap (algebraMap R (integralClosure R S)) :=
  IsIntegralClosure.comap_lt_comap S I_lt_J

theorem IntegralClosure.is_maximal_of_is_maximal_comap (I : Ideal (integralClosure R S)) [I.IsPrime]
    (hI : IsMaximal (I.comap (algebraMap R (integralClosure R S)))) : IsMaximal I :=
  IsIntegralClosure.is_maximal_of_is_maximal_comap S I hI

section

variable [IsDomain S]

theorem IntegralClosure.comap_ne_bot [Nontrivial R] {I : Ideal (integralClosure R S)} (I_ne_bot : I ≠ ⊥) :
    I.comap (algebraMap R (integralClosure R S)) ≠ ⊥ :=
  IsIntegralClosure.comap_ne_bot S I_ne_bot

theorem IntegralClosure.eq_bot_of_comap_eq_bot [Nontrivial R] {I : Ideal (integralClosure R S)} :
    I.comap (algebraMap R (integralClosure R S)) = ⊥ → I = ⊥ :=
  IsIntegralClosure.eq_bot_of_comap_eq_bot S

/-- `comap (algebra_map R S)` is a surjection from the prime spec of `R` to prime spec of `S`.
`hP : (algebra_map R S).ker ≤ P` is a slight generalization of the extension being injective -/
theorem exists_ideal_over_prime_of_is_integral' (H : Algebra.IsIntegral R S) (P : Ideal R) [IsPrime P]
    (hP : (algebraMap R S).ker ≤ P) : ∃ Q : Ideal S, IsPrime Q ∧ Q.comap (algebraMap R S) = P := by
  have hP0 : (0 : S) ∉ Algebra.algebraMapSubmonoid S P.prime_compl := by
    rintro ⟨x, ⟨hx, x0⟩⟩
    exact absurd (hP x0) hx
  let Rₚ := Localization P.prime_compl
  let Sₚ := Localization (Algebra.algebraMapSubmonoid S P.prime_compl)
  letI : IsDomain (Localization (Algebra.algebraMapSubmonoid S P.prime_compl)) :=
    IsLocalization.is_domain_localization (le_non_zero_divisors_of_no_zero_divisors hP0)
  obtain ⟨Qₚ : Ideal Sₚ, Qₚ_maximal⟩ := exists_maximal Sₚ
  haveI Qₚ_max : is_maximal (comap _ Qₚ) :=
    @is_maximal_comap_of_is_integral_of_is_maximal Rₚ _ Sₚ _ (localizationAlgebra P.prime_compl S)
      (is_integral_localization H) _ Qₚ_maximal
  refine' ⟨comap (algebraMap S Sₚ) Qₚ, ⟨comap_is_prime _ Qₚ, _⟩⟩
  convert Localization.AtPrime.comap_maximal_ideal
  rw [comap_comap, ← LocalRing.eq_maximal_ideal Qₚ_max, ← IsLocalization.map_comp _]
  rfl

end

/-- More general going-up theorem than `exists_ideal_over_prime_of_is_integral'`.
TODO: Version of going-up theorem with arbitrary length chains (by induction on this)?
  Not sure how best to write an ascending chain in Lean -/
theorem exists_ideal_over_prime_of_is_integral (H : Algebra.IsIntegral R S) (P : Ideal R) [IsPrime P] (I : Ideal S)
    [IsPrime I] (hIP : I.comap (algebraMap R S) ≤ P) : ∃ Q ≥ I, IsPrime Q ∧ Q.comap (algebraMap R S) = P := by
  let quot := R ⧸ I.comap (algebraMap R S)
  obtain ⟨Q' : Ideal (S ⧸ I), ⟨Q'_prime, hQ'⟩⟩ :=
    @exists_ideal_over_prime_of_is_integral' Quot _ (S ⧸ I) _ Ideal.quotientAlgebra _
      (is_integral_quotient_of_is_integral H) (map (Quotientₓ.mk (I.comap (algebraMap R S))) P)
      (map_is_prime_of_surjective quotient.mk_surjective
        (by
          simp [hIP]))
      (le_transₓ (le_of_eqₓ ((RingHom.injective_iff_ker_eq_bot _).1 algebra_map_quotient_injective)) bot_le)
  haveI := Q'_prime
  refine' ⟨Q'.comap _, le_transₓ (le_of_eqₓ mk_ker.symm) (ker_le_comap _), ⟨comap_is_prime _ Q', _⟩⟩
  rw [comap_comap]
  refine' trans _ (trans (congr_argₓ (comap (Quotientₓ.mk (comap (algebraMap R S) I))) hQ') _)
  · simpa [comap_comap]
    
  · refine' trans (comap_map_of_surjective _ quotient.mk_surjective _) (sup_eq_left.2 _)
    simpa [← RingHom.ker_eq_comap_bot] using hIP
    

/-- `comap (algebra_map R S)` is a surjection from the max spec of `S` to max spec of `R`.
`hP : (algebra_map R S).ker ≤ P` is a slight generalization of the extension being injective -/
theorem exists_ideal_over_maximal_of_is_integral [IsDomain S] (H : Algebra.IsIntegral R S) (P : Ideal R)
    [P_max : IsMaximal P] (hP : (algebraMap R S).ker ≤ P) : ∃ Q : Ideal S, IsMaximal Q ∧ Q.comap (algebraMap R S) = P :=
  by
  obtain ⟨Q, ⟨Q_prime, hQ⟩⟩ := exists_ideal_over_prime_of_is_integral' H P hP
  haveI : Q.is_prime := Q_prime
  exact ⟨Q, is_maximal_of_is_integral_of_is_maximal_comap H _ (hQ.symm ▸ P_max), hQ⟩

end IsDomain

end Ideal

