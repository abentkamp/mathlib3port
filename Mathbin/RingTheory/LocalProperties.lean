/-
Copyright (c) 2021 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import Mathbin.GroupTheory.Submonoid.Pointwise
import Mathbin.Logic.Equiv.TransferInstance
import Mathbin.RingTheory.Finiteness
import Mathbin.RingTheory.Localization.AtPrime
import Mathbin.RingTheory.Localization.Away
import Mathbin.RingTheory.Localization.Integer
import Mathbin.RingTheory.Localization.Submodule
import Mathbin.RingTheory.Nilpotent
import Mathbin.RingTheory.RingHomProperties

/-!
# Local properties of commutative rings

In this file, we provide the proofs of various local properties.

## Naming Conventions

* `localization_P` : `P` holds for `S⁻¹R` if `P` holds for `R`.
* `P_of_localization_maximal` : `P` holds for `R` if `P` holds for `Rₘ` for all maximal `m`.
* `P_of_localization_prime` : `P` holds for `R` if `P` holds for `Rₘ` for all prime `m`.
* `P_of_localization_span` : `P` holds for `R` if given a spanning set `{fᵢ}`, `P` holds for all
  `R_{fᵢ}`.

## Main results

The following properties are covered:

* The triviality of an ideal or an element:
  `ideal_eq_zero_of_localization`, `eq_zero_of_localization`
* `is_reduced` : `localization_is_reduced`, `is_reduced_of_localization_maximal`.
* `finite`: `localization_finite`, `finite_of_localization_span`
* `finite_type`: `localization_finite_type`, `finite_type_of_localization_span`

-/


open Pointwise Classical BigOperators

universe u

variable {R S : Type u} [CommRingₓ R] [CommRingₓ S] (M : Submonoid R)

variable (N : Submonoid S) (R' S' : Type u) [CommRingₓ R'] [CommRingₓ S'] (f : R →+* S)

variable [Algebra R R'] [Algebra S S']

section Properties

section CommRingₓ

variable (P : ∀ (R : Type u) [CommRingₓ R], Prop)

include P

/-- A property `P` of comm rings is said to be preserved by localization
  if `P` holds for `M⁻¹R` whenever `P` holds for `R`. -/
def LocalizationPreserves : Prop :=
  ∀ {R : Type u} [hR : CommRingₓ R] (M : Submonoid R) (S : Type u) [hS : CommRingₓ S] [Algebra R S]
    [IsLocalization M S], @P R hR → @P S hS

/-- A property `P` of comm rings satisfies `of_localization_maximal` if
  if `P` holds for `R` whenever `P` holds for `Rₘ` for all maximal ideal `m`. -/
def OfLocalizationMaximal : Prop :=
  ∀ (R : Type u) [CommRingₓ R], (∀ (J : Ideal R) (hJ : J.IsMaximal), P (Localization.AtPrime J)) → P R

end CommRingₓ

section RingHom

variable (P : ∀ {R S : Type u} [CommRingₓ R] [CommRingₓ S] (f : R →+* S), Prop)

include P

/-- A property `P` of ring homs is said to be preserved by localization
 if `P` holds for `M⁻¹R →+* M⁻¹S` whenever `P` holds for `R →+* S`. -/
def RingHom.LocalizationPreserves :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S) (M : Submonoid R) (R' S' : Type u) [CommRingₓ R']
    [CommRingₓ S'] [Algebra R R'] [Algebra S S'] [IsLocalization M R'] [IsLocalization (M.map f) S'],
    P f → P (IsLocalization.map S' f (Submonoid.le_comap_map M) : R' →+* S')

/-- A property `P` of ring homs satisfies `ring_hom.of_localization_finite_span`
if `P` holds for `R →+* S` whenever there exists a finite set `{ r }` that spans `R` such that
`P` holds for `Rᵣ →+* Sᵣ`.

Note that this is equivalent to `ring_hom.of_localization_span` via
`ring_hom.of_localization_span_iff_finite`, but this is easier to prove. -/
def RingHom.OfLocalizationFiniteSpan :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S) (s : Finset R) (hs : Ideal.span (s : Set R) = ⊤)
    (H : ∀ r : s, P (Localization.awayMap f r)), P f

/-- A property `P` of ring homs satisfies `ring_hom.of_localization_finite_span`
if `P` holds for `R →+* S` whenever there exists a set `{ r }` that spans `R` such that
`P` holds for `Rᵣ →+* Sᵣ`.

Note that this is equivalent to `ring_hom.of_localization_finite_span` via
`ring_hom.of_localization_span_iff_finite`, but this has less restrictions when applying. -/
def RingHom.OfLocalizationSpan :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S) (s : Set R) (hs : Ideal.span s = ⊤)
    (H : ∀ r : s, P (Localization.awayMap f r)), P f

/-- A property `P` of ring homs satisfies `ring_hom.holds_for_localization_away`
 if `P` holds for each localization map `R →+* Rᵣ`. -/
def RingHom.HoldsForLocalizationAway : Prop :=
  ∀ ⦃R : Type u⦄ (S : Type u) [CommRingₓ R] [CommRingₓ S] [Algebra R S] (r : R) [IsLocalization.Away r S],
    P (algebraMap R S)

/-- A property `P` of ring homs satisfies `ring_hom.of_localization_finite_span_target`
if `P` holds for `R →+* S` whenever there exists a finite set `{ r }` that spans `S` such that
`P` holds for `R →+* Sᵣ`.

Note that this is equivalent to `ring_hom.of_localization_span_target` via
`ring_hom.of_localization_span_target_iff_finite`, but this is easier to prove. -/
def RingHom.OfLocalizationFiniteSpanTarget : Prop :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S) (s : Finset S) (hs : Ideal.span (s : Set S) = ⊤)
    (H : ∀ r : s, P ((algebraMap S (Localization.Away (r : S))).comp f)), P f

/-- A property `P` of ring homs satisfies `ring_hom.of_localization_span_target`
if `P` holds for `R →+* S` whenever there exists a set `{ r }` that spans `S` such that
`P` holds for `R →+* Sᵣ`.

Note that this is equivalent to `ring_hom.of_localization_finite_span_target` via
`ring_hom.of_localization_span_target_iff_finite`, but this has less restrictions when applying. -/
def RingHom.OfLocalizationSpanTarget : Prop :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S) (s : Set S) (hs : Ideal.span s = ⊤)
    (H : ∀ r : s, P ((algebraMap S (Localization.Away (r : S))).comp f)), P f

/-- A property `P` of ring homs satisfies `of_localization_prime` if
  if `P` holds for `R` whenever `P` holds for `Rₘ` for all prime ideals `p`. -/
def RingHom.OfLocalizationPrime : Prop :=
  ∀ ⦃R S : Type u⦄ [CommRingₓ R] [CommRingₓ S] (f : R →+* S),
    (∀ (J : Ideal S) (hJ : J.IsPrime), P (Localization.localRingHom _ J f rfl)) → P f

/-- A property of ring homs is local if it is preserved by localizations and compositions, and for
each `{ r }` that spans `S`, we have `P (R →+* S) ↔ ∀ r, P (R →+* Sᵣ)`. -/
structure RingHom.PropertyIsLocal : Prop where
  LocalizationPreserves : RingHom.LocalizationPreserves @P
  OfLocalizationSpanTarget : RingHom.OfLocalizationSpanTarget @P
  StableUnderComposition : RingHom.StableUnderComposition @P
  HoldsForLocalizationAway : RingHom.HoldsForLocalizationAway @P

theorem RingHom.of_localization_span_iff_finite : RingHom.OfLocalizationSpan @P ↔ RingHom.OfLocalizationFiniteSpan @P :=
  by
  delta' RingHom.OfLocalizationSpan RingHom.OfLocalizationFiniteSpan
  apply forall₅_congr
  -- TODO: Using `refine` here breaks `resetI`.
  intros
  constructor
  · intro h s
    exact h s
    
  · intro h s hs hs'
    obtain ⟨s', h₁, h₂⟩ := (Ideal.span_eq_top_iff_finite s).mp hs
    exact h s' h₂ fun x => hs' ⟨_, h₁ x.Prop⟩
    

theorem RingHom.of_localization_span_target_iff_finite :
    RingHom.OfLocalizationSpanTarget @P ↔ RingHom.OfLocalizationFiniteSpanTarget @P := by
  delta' RingHom.OfLocalizationSpanTarget RingHom.OfLocalizationFiniteSpanTarget
  apply forall₅_congr
  -- TODO: Using `refine` here breaks `resetI`.
  intros
  constructor
  · intro h s
    exact h s
    
  · intro h s hs hs'
    obtain ⟨s', h₁, h₂⟩ := (Ideal.span_eq_top_iff_finite s).mp hs
    exact h s' h₂ fun x => hs' ⟨_, h₁ x.Prop⟩
    

variable {P f R' S'}

theorem _root_.ring_hom.property_is_local.respects_iso (hP : RingHom.PropertyIsLocal @P) : RingHom.RespectsIso @P := by
  apply hP.stable_under_composition.respects_iso
  introv
  skip
  letI := e.to_ring_hom.to_algebra
  apply hP.holds_for_localization_away with { instances := false }
  apply IsLocalization.away_of_is_unit_of_bijective _ is_unit_one
  exact e.bijective

-- Almost all arguments are implicit since this is not intended to use mid-proof.
theorem RingHom.LocalizationPreserves.away (H : RingHom.LocalizationPreserves @P) (r : R) [IsLocalization.Away r R']
    [IsLocalization.Away (f r) S'] (hf : P f) : P (IsLocalization.Away.map R' S' f r) := by
  skip
  have : IsLocalization ((Submonoid.powers r).map f) S' := by
    rw [Submonoid.map_powers]
    assumption
  exact H f (Submonoid.powers r) R' S' hf

theorem RingHom.PropertyIsLocal.of_localization_span (hP : RingHom.PropertyIsLocal @P) :
    RingHom.OfLocalizationSpan @P := by
  introv R hs hs'
  skip
  apply_fun Ideal.map f  at hs
  rw [Ideal.map_span, Ideal.map_top] at hs
  apply hP.of_localization_span_target _ _ hs
  rintro ⟨_, r, hr, rfl⟩
  have := hs' ⟨r, hr⟩
  convert hP.stable_under_composition _ _ (hP.holds_for_localization_away (Localization.Away r) r) (hs' ⟨r, hr⟩) using 1
  exact (IsLocalization.map_comp _).symm

end RingHom

end Properties

section Ideal

-- This proof should work for all modules, but we do not know how to localize a module yet.
/-- An ideal is trivial if its localization at every maximal ideal is trivial. -/
theorem ideal_eq_zero_of_localization (I : Ideal R)
    (h : ∀ (J : Ideal R) (hJ : J.IsMaximal), IsLocalization.coeSubmodule (Localization.AtPrime J) I = 0) : I = 0 := by
  by_contra hI
  change I ≠ ⊥ at hI
  obtain ⟨x, hx, hx'⟩ := SetLike.exists_of_lt hI.bot_lt
  rw [Submodule.mem_bot] at hx'
  have H : (Ideal.span ({x} : Set R)).annihilator ≠ ⊤ := by
    rw [Ne.def, Submodule.annihilator_eq_top_iff]
    by_contra
    apply hx'
    rw [← Set.mem_singleton_iff, ← @Submodule.bot_coe R, ← h]
    exact Ideal.subset_span (Set.mem_singleton x)
  obtain ⟨p, hp₁, hp₂⟩ := Ideal.exists_le_maximal _ H
  skip
  specialize h p hp₁
  have : algebraMap R (Localization.AtPrime p) x = 0 := by
    rw [← Set.mem_singleton_iff]
    change algebraMap R (Localization.AtPrime p) x ∈ (0 : Submodule R (Localization.AtPrime p))
    rw [← h]
    exact Submodule.mem_map_of_mem hx
  rw [IsLocalization.map_eq_zero_iff p.prime_compl] at this
  obtain ⟨m, hm⟩ := this
  apply m.prop
  refine' hp₂ _
  erw [Submodule.mem_annihilator_span_singleton]
  rwa [mul_comm] at hm

theorem eq_zero_of_localization (r : R)
    (h : ∀ (J : Ideal R) (hJ : J.IsMaximal), algebraMap R (Localization.AtPrime J) r = 0) : r = 0 := by
  rw [← Ideal.span_singleton_eq_bot]
  apply ideal_eq_zero_of_localization
  intro J hJ
  delta' IsLocalization.coeSubmodule
  erw [Submodule.map_span, Submodule.span_eq_bot]
  rintro _ ⟨_, h', rfl⟩
  cases set.mem_singleton_iff.mpr h'
  exact h J hJ

end Ideal

section Reduced

theorem localization_is_reduced : LocalizationPreserves fun R hR => IsReduced R := by
  introv R _ _
  skip
  constructor
  rintro x ⟨_ | n, e⟩
  · simpa using congr_argₓ (· * x) e
    
  obtain ⟨⟨y, m⟩, hx⟩ := IsLocalization.surj M x
  dsimp' only  at hx
  let hx' := congr_argₓ (· ^ n.succ) hx
  simp only [mul_powₓ, e, zero_mul, ← RingHom.map_pow] at hx'
  rw [← (algebraMap R S).map_zero] at hx'
  obtain ⟨m', hm'⟩ := (IsLocalization.eq_iff_exists M S).mp hx'
  apply_fun (· * m' ^ n)  at hm'
  simp only [mul_assoc, zero_mul] at hm'
  rw [mul_comm, ← pow_succₓ, ← mul_powₓ] at hm'
  replace hm' := IsNilpotent.eq_zero ⟨_, hm'.symm⟩
  rw [← (IsLocalization.map_units S m).mul_left_inj, hx, zero_mul, IsLocalization.map_eq_zero_iff M]
  exact
    ⟨m', by
      rw [← hm', mul_comm]⟩

instance [IsReduced R] : IsReduced (Localization M) :=
  localization_is_reduced M _ inferInstance

theorem is_reduced_of_localization_maximal : OfLocalizationMaximal fun R hR => IsReduced R := by
  introv R h
  constructor
  intro x hx
  apply eq_zero_of_localization
  intro J hJ
  specialize h J hJ
  skip
  exact (hx.map <| algebraMap R <| Localization.AtPrime J).eq_zero

end Reduced

section Surjective

theorem localization_preserves_surjective : RingHom.LocalizationPreserves fun R S _ _ f => Function.Surjective f := by
  introv R H x
  skip
  obtain ⟨x, ⟨_, s, hs, rfl⟩, rfl⟩ := IsLocalization.mk'_surjective (M.map f) x
  obtain ⟨y, rfl⟩ := H x
  use IsLocalization.mk' R' y ⟨s, hs⟩
  rw [IsLocalization.map_mk']
  rfl

theorem surjective_of_localization_span : RingHom.OfLocalizationSpan fun R S _ _ f => Function.Surjective f := by
  introv R e H
  rw [← Set.range_iff_surjective, Set.eq_univ_iff_forall]
  skip
  letI := f.to_algebra
  intro x
  apply Submodule.mem_of_span_eq_top_of_smul_pow_mem (Algebra.ofId R S).toLinearMap.range s e
  intro r
  obtain ⟨a, e'⟩ := H r (algebraMap _ _ x)
  obtain ⟨b, ⟨_, n, rfl⟩, rfl⟩ := IsLocalization.mk'_surjective (Submonoid.powers (r : R)) a
  erw [IsLocalization.map_mk'] at e'
  rw [eq_comm, IsLocalization.eq_mk'_iff_mul_eq, Subtype.coe_mk, Subtype.coe_mk, ← map_mul] at e'
  obtain ⟨⟨_, n', rfl⟩, e''⟩ := (IsLocalization.eq_iff_exists (Submonoid.powers (f r)) _).mp e'
  rw [Subtype.coe_mk, mul_assoc, ← map_pow, ← map_mul, ← map_mul, ← pow_addₓ, mul_comm] at e''
  exact ⟨n + n', _, e''.symm⟩

end Surjective

section Finite

/-- If `S` is a finite `R`-algebra, then `S' = M⁻¹S` is a finite `R' = M⁻¹R`-algebra. -/
theorem localization_finite : RingHom.LocalizationPreserves @RingHom.Finite := by
  introv R hf
  -- Setting up the `algebra` and `is_scalar_tower` instances needed
  skip
  letI := f.to_algebra
  letI := ((algebraMap S S').comp f).toAlgebra
  let f' : R' →+* S' := IsLocalization.map S' f (Submonoid.le_comap_map M)
  letI := f'.to_algebra
  haveI : IsScalarTower R R' S' := IsScalarTower.of_algebra_map_eq' (IsLocalization.map_comp _).symm
  let fₐ : S →ₐ[R] S' := AlgHom.mk' (algebraMap S S') fun c x => RingHom.map_mul _ _ _
  -- We claim that if `S` is generated by `T` as an `R`-module,
  -- then `S'` is generated by `T` as an `R'`-module.
  obtain ⟨T, hT⟩ := hf
  use T.image (algebraMap S S')
  rw [eq_top_iff]
  rintro x -
  -- By the hypotheses, for each `x : S'`, we have `x = y / (f r)` for some `y : S` and `r : M`.
  -- Since `S` is generated by `T`, the image of `y` should fall in the span of the image of `T`.
  obtain ⟨y, ⟨_, ⟨r, hr, rfl⟩⟩, rfl⟩ := IsLocalization.mk'_surjective (M.map f) x
  rw [IsLocalization.mk'_eq_mul_mk'_one, mul_comm, Finset.coe_image]
  have hy : y ∈ Submodule.span R ↑T := by
    rw [hT]
    trivial
  replace hy : algebraMap S S' y ∈ Submodule.map fₐ.to_linear_map (Submodule.span R T) := Submodule.mem_map_of_mem hy
  rw [Submodule.map_span fₐ.to_linear_map T] at hy
  have H : Submodule.span R (algebraMap S S' '' T) ≤ (Submodule.span R' (algebraMap S S' '' T)).restrictScalars R := by
    rw [Submodule.span_le]
    exact Submodule.subset_span
  -- Now, since `y ∈ span T`, and `(f r)⁻¹ ∈ R'`, `x / (f r)` is in `span T` as well.
  convert (Submodule.span R' (algebraMap S S' '' T)).smul_mem (IsLocalization.mk' R' (1 : R) ⟨r, hr⟩) (H hy) using 1
  rw [Algebra.smul_def]
  erw [IsLocalization.map_mk']
  rw [map_one]
  rfl

theorem localization_away_map_finite (r : R) [IsLocalization.Away r R'] [IsLocalization.Away (f r) S'] (hf : f.Finite) :
    (IsLocalization.Away.map R' S' f r).Finite :=
  localization_finite.Away r hf

/-- Let `S` be an `R`-algebra, `M` an submonoid of `R`, and `S' = M⁻¹S`.
If the image of some `x : S` falls in the span of some finite `s ⊆ S'` over `R`,
then there exists some `m : M` such that `m • x` falls in the
span of `finset_integer_multiple _ s` over `R`.
-/
theorem IsLocalization.smul_mem_finset_integer_multiple_span [Algebra R S] [Algebra R S'] [IsScalarTower R S S']
    [IsLocalization (M.map (algebraMap R S : R →* S)) S'] (x : S) (s : Finset S')
    (hx : algebraMap S S' x ∈ Submodule.span R (s : Set S')) :
    ∃ m : M,
      m • x ∈ Submodule.span R (IsLocalization.finsetIntegerMultiple (M.map (algebraMap R S : R →* S)) s : Set S) :=
  by
  let g : S →ₐ[R] S' :=
    AlgHom.mk' (algebraMap S S') fun c x => by
      simp [Algebra.algebra_map_eq_smul_one]
  -- We first obtain the `y' ∈ M` such that `s' = y' • s` is falls in the image of `S` in `S'`.
  let y := IsLocalization.commonDenomOfFinset (M.map (algebraMap R S : R →* S)) s
  have hx₁ : (y : S) • ↑s = g '' _ := (IsLocalization.finset_integer_multiple_image _ s).symm
  obtain ⟨y', hy', e : algebraMap R S y' = y⟩ := y.prop
  have : algebraMap R S y' • (s : Set S') = y' • s := by
    simp_rw [Algebra.algebra_map_eq_smul_one, smul_assoc, one_smul]
  rw [← e, this] at hx₁
  replace hx₁ := congr_argₓ (Submodule.span R) hx₁
  rw [Submodule.span_smul_eq] at hx₁
  replace hx : _ ∈ y' • Submodule.span R (s : Set S') := Set.smul_mem_smul_set hx
  rw [hx₁] at hx
  erw [← g.map_smul, ← Submodule.map_span (g : S →ₗ[R] S')] at hx
  -- Since `x` falls in the span of `s` in `S'`, `y' • x : S` falls in the span of `s'` in `S'`.
  -- That is, there exists some `x' : S` in the span of `s'` in `S` and `x' = y' • x` in `S'`.
  -- Thus `a • (y' • x) = a • x' ∈ span s'` in `S` for some `a ∈ M`.
  obtain ⟨x', hx', hx'' : algebraMap _ _ _ = _⟩ := hx
  obtain ⟨⟨_, a, ha₁, rfl⟩, ha₂⟩ := (IsLocalization.eq_iff_exists (M.map (algebraMap R S : R →* S)) S').mp hx''
  use (⟨a, ha₁⟩ : M) * (⟨y', hy'⟩ : M)
  convert
    (Submodule.span R
          (IsLocalization.finsetIntegerMultiple (Submonoid.map (algebraMap R S : R →* S) M) s : Set S)).smul_mem
      a hx' using
    1
  convert ha₂.symm
  · rw [mul_comm (y' • x), Subtype.coe_mk, Submonoid.smul_def, Submonoid.coe_mul, ← smul_smul]
    exact Algebra.smul_def _ _
    
  · rw [mul_comm]
    exact Algebra.smul_def _ _
    

-- ./././Mathport/Syntax/Translate/Tactic/Builtin.lean:64:14: unsupported tactic `rsuffices #[["⟨", ident t, ",", ident ht, "⟩", ":", expr «expr∃ , »((t : M),
    «expr ∈ »(«expr • »(t, x), submodule.span R (s' : set S)))]]
/-- If `S` is an `R' = M⁻¹R` algebra, and `x ∈ span R' s`,
then `t • x ∈ span R s` for some `t : M`.-/
theorem multiple_mem_span_of_mem_localization_span [Algebra R' S] [Algebra R S] [IsScalarTower R R' S]
    [IsLocalization M R'] (s : Set S) (x : S) (hx : x ∈ Submodule.span R' s) : ∃ t : M, t • x ∈ Submodule.span R s := by
  classical
  obtain ⟨s', hss', hs'⟩ := Submodule.mem_span_finite_of_mem_span hx
  trace
    "./././Mathport/Syntax/Translate/Tactic/Builtin.lean:64:14: unsupported tactic `rsuffices #[[\"⟨\", ident t, \",\", ident ht, \"⟩\", \":\", expr «expr∃ , »((t : M),\n    «expr ∈ »(«expr • »(t, x), submodule.span R (s' : set S)))]]"
  · exact ⟨t, Submodule.span_mono hss' ht⟩
    
  clear hx hss' s
  revert x
  apply s'.induction_on
  · intro x hx
    use 1
    simpa using hx
    
  rintro a s ha hs x hx
  simp only [Finset.coe_insert, Finset.image_insert, Finset.coe_image, Subtype.coe_mk, Submodule.mem_span_insert] at hx⊢
  rcases hx with ⟨y, z, hz, rfl⟩
  rcases IsLocalization.surj M y with ⟨⟨y', s'⟩, e⟩
  replace e : _ * a = _ * a := (congr_argₓ (fun x => algebraMap R' S x * a) e : _)
  simp_rw [RingHom.map_mul, ← IsScalarTower.algebra_map_apply, mul_comm (algebraMap R' S y), mul_assoc, ←
    Algebra.smul_def] at e
  rcases hs _ hz with ⟨t, ht⟩
  refine' ⟨t * s', t * y', _, (Submodule.span R (s : Set S)).smul_mem s' ht, _⟩
  rw [smul_add, ← smul_smul, mul_comm, ← smul_smul, ← smul_smul, ← e]
  rfl

/-- If `S` is an `R' = M⁻¹R` algebra, and `x ∈ adjoin R' s`,
then `t • x ∈ adjoin R s` for some `t : M`.-/
theorem multiple_mem_adjoin_of_mem_localization_adjoin [Algebra R' S] [Algebra R S] [IsScalarTower R R' S]
    [IsLocalization M R'] (s : Set S) (x : S) (hx : x ∈ Algebra.adjoin R' s) : ∃ t : M, t • x ∈ Algebra.adjoin R s := by
  change ∃ t : M, t • x ∈ (Algebra.adjoin R s).toSubmodule
  change x ∈ (Algebra.adjoin R' s).toSubmodule at hx
  simp_rw [Algebra.adjoin_eq_span] at hx⊢
  exact multiple_mem_span_of_mem_localization_span M R' _ _ hx

theorem finite_of_localization_span : RingHom.OfLocalizationSpan @RingHom.Finite := by
  rw [RingHom.of_localization_span_iff_finite]
  introv R hs H
  -- We first setup the instances
  skip
  letI := f.to_algebra
  letI := fun r : s => (Localization.awayMap f r).toAlgebra
  have : ∀ r : s, IsLocalization ((Submonoid.powers (r : R)).map (algebraMap R S : R →* S)) (Localization.Away (f r)) :=
    by
    intro r
    rw [Submonoid.map_powers]
    exact Localization.is_localization
  haveI : ∀ r : s, IsScalarTower R (Localization.Away (r : R)) (Localization.Away (f r)) := fun r =>
    IsScalarTower.of_algebra_map_eq' (IsLocalization.map_comp _).symm
  -- By the hypothesis, we may find a finite generating set for each `Sᵣ`. This set can then be
  -- lifted into `R` by multiplying a sufficiently large power of `r`. I claim that the union of
  -- these generates `S`.
  constructor
  replace H := fun r => (H r).1
  choose s₁ s₂ using H
  let sf := fun x : s => IsLocalization.finsetIntegerMultiple (Submonoid.powers (f x)) (s₁ x)
  use s.attach.bUnion sf
  rw [Submodule.span_attach_bUnion, eq_top_iff]
  -- It suffices to show that `r ^ n • x ∈ span T` for each `r : s`, since `{ r ^ n }` spans `R`.
  -- This then follows from the fact that each `x : R` is a linear combination of the generating set
  -- of `Sᵣ`. By multiplying a sufficiently large power of `r`, we can cancel out the `r`s in the
  -- denominators of both the generating set and the coefficients.
  rintro x -
  apply Submodule.mem_of_span_eq_top_of_smul_pow_mem _ (s : Set R) hs _ _
  intro r
  obtain ⟨⟨_, n₁, rfl⟩, hn₁⟩ :=
    multiple_mem_span_of_mem_localization_span (Submonoid.powers (r : R)) (Localization.Away (r : R))
      (s₁ r : Set (Localization.Away (f r))) (algebraMap S _ x)
      (by
        rw [s₂ r]
        trivial)
  rw [Submonoid.smul_def, Algebra.smul_def, IsScalarTower.algebra_map_apply R S, Subtype.coe_mk, ← map_mul] at hn₁
  obtain ⟨⟨_, n₂, rfl⟩, hn₂⟩ :=
    IsLocalization.smul_mem_finset_integer_multiple_span (Submonoid.powers (r : R)) (Localization.Away (f r)) _ (s₁ r)
      hn₁
  rw [Submonoid.smul_def, ← Algebra.smul_def, smul_smul, Subtype.coe_mk, ← pow_addₓ] at hn₂
  use n₂ + n₁
  refine' le_supr (fun x : s => Submodule.span R (sf x : Set S)) r _
  change _ ∈ Submodule.span R ((IsLocalization.finsetIntegerMultiple _ (s₁ r) : Finset S) : Set S)
  convert hn₂
  rw [Submonoid.map_powers]
  rfl

end Finite

section FiniteType

theorem localization_finite_type : RingHom.LocalizationPreserves @RingHom.FiniteType := by
  introv R hf
  -- mirrors the proof of `localization_map_finite`
  skip
  letI := f.to_algebra
  letI := ((algebraMap S S').comp f).toAlgebra
  let f' : R' →+* S' := IsLocalization.map S' f (Submonoid.le_comap_map M)
  letI := f'.to_algebra
  haveI : IsScalarTower R R' S' := IsScalarTower.of_algebra_map_eq' (IsLocalization.map_comp _).symm
  let fₐ : S →ₐ[R] S' := AlgHom.mk' (algebraMap S S') fun c x => RingHom.map_mul _ _ _
  obtain ⟨T, hT⟩ := id hf
  use T.image (algebraMap S S')
  rw [eq_top_iff]
  rintro x -
  obtain ⟨y, ⟨_, ⟨r, hr, rfl⟩⟩, rfl⟩ := IsLocalization.mk'_surjective (M.map f) x
  rw [IsLocalization.mk'_eq_mul_mk'_one, mul_comm, Finset.coe_image]
  have hy : y ∈ Algebra.adjoin R (T : Set S) := by
    rw [hT]
    trivial
  replace hy : algebraMap S S' y ∈ (Algebra.adjoin R (T : Set S)).map fₐ := subalgebra.mem_map.mpr ⟨_, hy, rfl⟩
  rw [fₐ.map_adjoin T] at hy
  have H : Algebra.adjoin R (algebraMap S S' '' T) ≤ (Algebra.adjoin R' (algebraMap S S' '' T)).restrictScalars R := by
    rw [Algebra.adjoin_le_iff]
    exact Algebra.subset_adjoin
  convert (Algebra.adjoin R' (algebraMap S S' '' T)).smul_mem (H hy) (IsLocalization.mk' R' (1 : R) ⟨r, hr⟩) using 1
  rw [Algebra.smul_def]
  erw [IsLocalization.map_mk']
  rw [map_one]
  rfl

theorem localization_away_map_finite_type (r : R) [IsLocalization.Away r R'] [IsLocalization.Away (f r) S']
    (hf : f.FiniteType) : (IsLocalization.Away.map R' S' f r).FiniteType :=
  localization_finite_type.Away r hf

variable {S'}

/-- Let `S` be an `R`-algebra, `M` a submonoid of `S`, `S' = M⁻¹S`.
Suppose the image of some `x : S` falls in the adjoin of some finite `s ⊆ S'` over `R`,
and `A` is an `R`-subalgebra of `S` containing both `M` and the numerators of `s`.
Then, there exists some `m : M` such that `m • x` falls in `A`.
-/
theorem IsLocalization.exists_smul_mem_of_mem_adjoin [Algebra R S] [Algebra R S'] [IsScalarTower R S S']
    (M : Submonoid S) [IsLocalization M S'] (x : S) (s : Finset S') (A : Subalgebra R S)
    (hA₁ : (IsLocalization.finsetIntegerMultiple M s : Set S) ⊆ A) (hA₂ : M ≤ A.toSubmonoid)
    (hx : algebraMap S S' x ∈ Algebra.adjoin R (s : Set S')) : ∃ m : M, m • x ∈ A := by
  let g : S →ₐ[R] S' := IsScalarTower.toAlgHom R S S'
  let y := IsLocalization.commonDenomOfFinset M s
  have hx₁ : (y : S) • ↑s = g '' _ := (IsLocalization.finset_integer_multiple_image _ s).symm
  obtain ⟨n, hn⟩ :=
    Algebra.pow_smul_mem_of_smul_subset_of_mem_adjoin (y : S) (s : Set S') (A.map g)
      (by
        rw [hx₁]
        exact Set.image_subset _ hA₁)
      hx (Set.mem_image_of_mem _ (hA₂ y.2))
  obtain ⟨x', hx', hx''⟩ := hn n (le_of_eqₓ rfl)
  rw [Algebra.smul_def, ← _root_.map_mul] at hx''
  obtain ⟨a, ha₂⟩ := (IsLocalization.eq_iff_exists M S').mp hx''
  use a * y ^ n
  convert A.mul_mem hx' (hA₂ a.2)
  convert ha₂.symm
  simp only [Submonoid.smul_def, Submonoid.coe_pow, smul_eq_mul, Submonoid.coe_mul]
  ring

/-- Let `S` be an `R`-algebra, `M` an submonoid of `R`, and `S' = M⁻¹S`.
If the image of some `x : S` falls in the adjoin of some finite `s ⊆ S'` over `R`,
then there exists some `m : M` such that `m • x` falls in the
adjoin of `finset_integer_multiple _ s` over `R`.
-/
theorem IsLocalization.lift_mem_adjoin_finset_integer_multiple [Algebra R S] [Algebra R S'] [IsScalarTower R S S']
    [IsLocalization (M.map (algebraMap R S : R →* S)) S'] (x : S) (s : Finset S')
    (hx : algebraMap S S' x ∈ Algebra.adjoin R (s : Set S')) :
    ∃ m : M,
      m • x ∈ Algebra.adjoin R (IsLocalization.finsetIntegerMultiple (M.map (algebraMap R S : R →* S)) s : Set S) :=
  by
  obtain ⟨⟨_, a, ha, rfl⟩, e⟩ :=
    IsLocalization.exists_smul_mem_of_mem_adjoin (M.map (algebraMap R S : R →* S)) x s (Algebra.adjoin R _)
      Algebra.subset_adjoin _ hx
  · exact
      ⟨⟨a, ha⟩, by
        simpa [Submonoid.smul_def] using e⟩
    
  · rintro _ ⟨a, ha, rfl⟩
    exact Subalgebra.algebra_map_mem _ a
    

theorem finite_type_of_localization_span : RingHom.OfLocalizationSpan @RingHom.FiniteType := by
  rw [RingHom.of_localization_span_iff_finite]
  introv R hs H
  -- mirrors the proof of `finite_of_localization_span`
  skip
  letI := f.to_algebra
  letI := fun r : s => (Localization.awayMap f r).toAlgebra
  have : ∀ r : s, IsLocalization ((Submonoid.powers (r : R)).map (algebraMap R S : R →* S)) (Localization.Away (f r)) :=
    by
    intro r
    rw [Submonoid.map_powers]
    exact Localization.is_localization
  haveI : ∀ r : s, IsScalarTower R (Localization.Away (r : R)) (Localization.Away (f r)) := fun r =>
    IsScalarTower.of_algebra_map_eq' (IsLocalization.map_comp _).symm
  constructor
  replace H := fun r => (H r).1
  choose s₁ s₂ using H
  let sf := fun x : s => IsLocalization.finsetIntegerMultiple (Submonoid.powers (f x)) (s₁ x)
  use s.attach.bUnion sf
  convert (Algebra.adjoin_attach_bUnion sf).trans _
  rw [eq_top_iff]
  rintro x -
  apply (⨆ x : s, Algebra.adjoin R (sf x : Set S)).toSubmodule.mem_of_span_eq_top_of_smul_pow_mem _ hs _ _
  intro r
  obtain ⟨⟨_, n₁, rfl⟩, hn₁⟩ :=
    multiple_mem_adjoin_of_mem_localization_adjoin (Submonoid.powers (r : R)) (Localization.Away (r : R))
      (s₁ r : Set (Localization.Away (f r))) (algebraMap S (Localization.Away (f r)) x)
      (by
        rw [s₂ r]
        trivial)
  rw [Submonoid.smul_def, Algebra.smul_def, IsScalarTower.algebra_map_apply R S, Subtype.coe_mk, ← map_mul] at hn₁
  obtain ⟨⟨_, n₂, rfl⟩, hn₂⟩ :=
    IsLocalization.lift_mem_adjoin_finset_integer_multiple (Submonoid.powers (r : R)) _ (s₁ r) hn₁
  rw [Submonoid.smul_def, ← Algebra.smul_def, smul_smul, Subtype.coe_mk, ← pow_addₓ] at hn₂
  use n₂ + n₁
  refine' le_supr (fun x : s => Algebra.adjoin R (sf x : Set S)) r _
  change _ ∈ Algebra.adjoin R ((IsLocalization.finsetIntegerMultiple _ (s₁ r) : Finset S) : Set S)
  convert hn₂
  rw [Submonoid.map_powers]
  rfl

end FiniteType

