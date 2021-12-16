import Mathbin.MeasureTheory.Measure.Complex 
import Mathbin.MeasureTheory.Decomposition.Jordan 
import Mathbin.MeasureTheory.Measure.WithDensityVectorMeasure 
import Mathbin.MeasureTheory.Function.AeEqOfIntegral

/-!
# Lebesgue decomposition

This file proves the Lebesgue decomposition theorem. The Lebesgue decomposition theorem states that,
given two σ-finite measures `μ` and `ν`, there exists a σ-finite measure `ξ` and a measurable
function `f` such that `μ = ξ + fν` and `ξ` is mutually singular with respect to `ν`.

The Lebesgue decomposition provides the Radon-Nikodym theorem readily.

## Main definitions

* `measure_theory.measure.have_lebesgue_decomposition` : A pair of measures `μ` and `ν` is said
  to `have_lebesgue_decomposition` if there exist a measure `ξ` and a measurable function `f`,
  such that `ξ` is mutually singular with respect to `ν` and `μ = ξ + ν.with_density f`
* `measure_theory.measure.singular_part` : If a pair of measures `have_lebesgue_decomposition`,
  then `singular_part` chooses the measure from `have_lebesgue_decomposition`, otherwise it
  returns the zero measure.
* `measure_theory.measure.rn_deriv`: If a pair of measures
  `have_lebesgue_decomposition`, then `rn_deriv` chooses the measurable function from
  `have_lebesgue_decomposition`, otherwise it returns the zero function.
* `measure_theory.signed_measure.have_lebesgue_decomposition` : A signed measure `s` and a
  measure `μ` is said to `have_lebesgue_decomposition` if both the positive part and negative
  part of `s` `have_lebesgue_decomposition` with respect to `μ`.
* `measure_theory.signed_measure.singular_part` : The singular part between a signed measure `s`
  and a measure `μ` is simply the singular part of the positive part of `s` with respect to `μ`
  minus the singular part of the negative part of `s` with respect to `μ`.
* `measure_theory.signed_measure.rn_deriv` : The Radon-Nikodym derivative of a signed
  measure `s` with respect to a measure `μ` is the Radon-Nikodym derivative of the positive part of
  `s` with respect to `μ` minus the Radon-Nikodym derivative of the negative part of `s` with
  respect to `μ`.

## Main results

* `measure_theory.measure.have_lebesgue_decomposition_of_sigma_finite` :
  the Lebesgue decomposition theorem.
* `measure_theory.measure.eq_singular_part` : Given measures `μ` and `ν`, if `s` is a measure
  mutually singular to `ν` and `f` is a measurable function such that `μ = s + fν`, then
  `s = μ.singular_part ν`.
* `measure_theory.measure.eq_rn_deriv` : Given measures `μ` and `ν`, if `s` is a
  measure mutually singular to `ν` and `f` is a measurable function such that `μ = s + fν`,
  then `f = μ.rn_deriv ν`.
* `measure_theory.signed_measure.singular_part_add_with_density_rn_deriv_eq` :
  the Lebesgue decomposition theorem between a signed measure and a σ-finite positive measure.

# Tags

Lebesgue decomposition theorem
-/


noncomputable section 

open_locale Classical MeasureTheory Nnreal Ennreal

variable {α β : Type _} {m : MeasurableSpace α} {μ ν : MeasureTheory.Measure α}

include m

namespace MeasureTheory

namespace Measureₓ

/-- A pair of measures `μ` and `ν` is said to `have_lebesgue_decomposition` if there exists a
measure `ξ` and a measurable function `f`, such that `ξ` is mutually singular with respect to
`ν` and `μ = ξ + ν.with_density f`. -/
class have_lebesgue_decomposition (μ ν : Measureₓ α) : Prop where 
  lebesgue_decomposition : ∃ p : Measureₓ α × (α → ℝ≥0∞), Measurable p.2 ∧ p.1 ⊥ₘ ν ∧ μ = p.1+ν.with_density p.2

/-- If a pair of measures `have_lebesgue_decomposition`, then `singular_part` chooses the
measure from `have_lebesgue_decomposition`, otherwise it returns the zero measure. For sigma-finite
measures, `μ = μ.singular_part ν + ν.with_density (μ.rn_deriv ν)`. -/
irreducible_def singular_part (μ ν : Measureₓ α) : Measureₓ α :=
  if h : have_lebesgue_decomposition μ ν then (Classical.some h.lebesgue_decomposition).1 else 0

/-- If a pair of measures `have_lebesgue_decomposition`, then `rn_deriv` chooses the
measurable function from `have_lebesgue_decomposition`, otherwise it returns the zero function.
For sigma-finite measures, `μ = μ.singular_part ν + ν.with_density (μ.rn_deriv ν)`.-/
irreducible_def rn_deriv (μ ν : Measureₓ α) : α → ℝ≥0∞ :=
  if h : have_lebesgue_decomposition μ ν then (Classical.some h.lebesgue_decomposition).2 else 0

theorem have_lebesgue_decomposition_spec (μ ν : Measureₓ α) [h : have_lebesgue_decomposition μ ν] :
  Measurable (μ.rn_deriv ν) ∧ μ.singular_part ν ⊥ₘ ν ∧ μ = μ.singular_part ν+ν.with_density (μ.rn_deriv ν) :=
  by 
    rw [singular_part, rn_deriv, dif_pos h, dif_pos h]
    exact Classical.some_spec h.lebesgue_decomposition

theorem have_lebesgue_decomposition_add (μ ν : Measureₓ α) [have_lebesgue_decomposition μ ν] :
  μ = μ.singular_part ν+ν.with_density (μ.rn_deriv ν) :=
  (have_lebesgue_decomposition_spec μ ν).2.2

instance have_lebesgue_decomposition_smul (μ ν : Measureₓ α) [have_lebesgue_decomposition μ ν] (r :  ℝ≥0 ) :
  (r • μ).HaveLebesgueDecomposition ν :=
  { lebesgue_decomposition :=
      by 
        obtain ⟨hmeas, hsing, hadd⟩ := have_lebesgue_decomposition_spec μ ν 
        refine' ⟨⟨r • μ.singular_part ν, r • μ.rn_deriv ν⟩, _, hsing.smul _, _⟩
        ·
          change Measurable ((r : ℝ≥0∞) • _)
          exact hmeas.const_smul _
        ·
          change _ = ((r : ℝ≥0∞) • _)+ν.with_density ((r : ℝ≥0∞) • _)
          rw [with_density_smul _ hmeas, ←smul_add, ←hadd]
          rfl }

@[measurability]
theorem measurable_rn_deriv (μ ν : Measureₓ α) : Measurable$ μ.rn_deriv ν :=
  by 
    byCases' h : have_lebesgue_decomposition μ ν
    ·
      exact (have_lebesgue_decomposition_spec μ ν).1
    ·
      rw [rn_deriv, dif_neg h]
      exact measurable_zero

theorem mutually_singular_singular_part (μ ν : Measureₓ α) : μ.singular_part ν ⊥ₘ ν :=
  by 
    byCases' h : have_lebesgue_decomposition μ ν
    ·
      exact (have_lebesgue_decomposition_spec μ ν).2.1
    ·
      rw [singular_part, dif_neg h]
      exact mutually_singular.zero_left

theorem singular_part_le (μ ν : Measureₓ α) : μ.singular_part ν ≤ μ :=
  by 
    byCases' hl : have_lebesgue_decomposition μ ν
    ·
      cases' (have_lebesgue_decomposition_spec μ ν).2 with _ h 
      convRHS => rw [h]
      exact measure.le_add_right (le_reflₓ _)
    ·
      rw [singular_part, dif_neg hl]
      exact measure.zero_le μ

theorem with_density_rn_deriv_le (μ ν : Measureₓ α) : ν.with_density (μ.rn_deriv ν) ≤ μ :=
  by 
    byCases' hl : have_lebesgue_decomposition μ ν
    ·
      cases' (have_lebesgue_decomposition_spec μ ν).2 with _ h 
      convRHS => rw [h]
      exact measure.le_add_left (le_reflₓ _)
    ·
      rw [rn_deriv, dif_neg hl, with_density_zero]
      exact measure.zero_le μ

instance [is_finite_measure μ] : is_finite_measure (μ.singular_part ν) :=
  is_finite_measure_of_le μ$ singular_part_le μ ν

instance [sigma_finite μ] : sigma_finite (μ.singular_part ν) :=
  sigma_finite_of_le μ$ singular_part_le μ ν

instance [TopologicalSpace α] [is_locally_finite_measure μ] : is_locally_finite_measure (μ.singular_part ν) :=
  is_locally_finite_measure_of_le$ singular_part_le μ ν

instance [is_finite_measure μ] : is_finite_measure (ν.with_density$ μ.rn_deriv ν) :=
  is_finite_measure_of_le μ$ with_density_rn_deriv_le μ ν

instance [sigma_finite μ] : sigma_finite (ν.with_density$ μ.rn_deriv ν) :=
  sigma_finite_of_le μ$ with_density_rn_deriv_le μ ν

instance [TopologicalSpace α] [is_locally_finite_measure μ] :
  is_locally_finite_measure (ν.with_density$ μ.rn_deriv ν) :=
  is_locally_finite_measure_of_le$ with_density_rn_deriv_le μ ν

theorem lintegral_rn_deriv_lt_top_of_measure_ne_top {μ : Measureₓ α} (ν : Measureₓ α) {s : Set α} (hs : μ s ≠ ∞) :
  (∫⁻ x in s, μ.rn_deriv ν x ∂ν) < ∞ :=
  by 
    byCases' hl : have_lebesgue_decomposition μ ν
    ·
      have  := hl 
      obtain ⟨-, -, hadd⟩ := have_lebesgue_decomposition_spec μ ν 
      suffices  : (∫⁻ x in to_measurable μ s, μ.rn_deriv ν x ∂ν) < ∞
      exact lt_of_le_of_ltₓ (lintegral_mono_set (subset_to_measurable _ _)) this 
      rw [←with_density_apply _ (measurable_set_to_measurable _ _)]
      refine'
        lt_of_le_of_ltₓ
          (le_add_left (le_reflₓ _) :
          _ ≤ μ.singular_part ν (to_measurable μ s)+ν.with_density (μ.rn_deriv ν) (to_measurable μ s))
          _ 
      rw [←measure.add_apply, ←hadd, measure_to_measurable]
      exact hs.lt_top
    ·
      erw [measure.rn_deriv, dif_neg hl, lintegral_zero]
      exact WithTop.zero_lt_top

theorem lintegral_rn_deriv_lt_top (μ ν : Measureₓ α) [is_finite_measure μ] : (∫⁻ x, μ.rn_deriv ν x ∂ν) < ∞ :=
  by 
    rw [←set_lintegral_univ]
    exact lintegral_rn_deriv_lt_top_of_measure_ne_top _ (measure_lt_top _ _).Ne

/-- The Radon-Nikodym derivative of a sigma-finite measure `μ` with respect to another
measure `ν` is `ν`-almost everywhere finite. -/
theorem rn_deriv_lt_top (μ ν : Measureₓ α) [sigma_finite μ] : ∀ᵐ x ∂ν, μ.rn_deriv ν x < ∞ :=
  by 
    suffices  : ∀ n, ∀ᵐ x ∂ν, x ∈ spanning_sets μ n → μ.rn_deriv ν x < ∞
    ·
      filterUpwards [ae_all_iff.2 this]
      intro x hx 
      exact hx _ (mem_spanning_sets_index _ _)
    intro n 
    rw [←ae_restrict_iff' (measurable_spanning_sets _ _)]
    apply ae_lt_top (measurable_rn_deriv _ _)
    refine' (lintegral_rn_deriv_lt_top_of_measure_ne_top _ _).Ne 
    exact (measure_spanning_sets_lt_top _ _).Ne

/-- Given measures `μ` and `ν`, if `s` is a measure mutually singular to `ν` and `f` is a
measurable function such that `μ = s + fν`, then `s = μ.singular_part μ`.

This theorem provides the uniqueness of the `singular_part` in the Lebesgue decomposition theorem,
while `measure_theory.measure.eq_rn_deriv` provides the uniqueness of the
`rn_deriv`. -/
theorem eq_singular_part {s : Measureₓ α} {f : α → ℝ≥0∞} (hf : Measurable f) (hs : s ⊥ₘ ν)
  (hadd : μ = s+ν.with_density f) : s = μ.singular_part ν :=
  by 
    have  : have_lebesgue_decomposition μ ν := ⟨⟨⟨s, f⟩, hf, hs, hadd⟩⟩
    obtain ⟨hmeas, hsing, hadd'⟩ := have_lebesgue_decomposition_spec μ ν 
    obtain ⟨⟨S, hS₁, hS₂, hS₃⟩, ⟨T, hT₁, hT₂, hT₃⟩⟩ := hs, hsing 
    rw [hadd'] at hadd 
    have hνinter : ν ((S ∩ T)ᶜ) = 0
    ·
      rw [Set.compl_inter]
      refine' nonpos_iff_eq_zero.1 (le_transₓ (measure_union_le _ _) _)
      rw [hT₃, hS₃, add_zeroₓ]
      exact le_reflₓ _ 
    have heq : s.restrict ((S ∩ T)ᶜ) = (μ.singular_part ν).restrict ((S ∩ T)ᶜ)
    ·
      ext1 A hA 
      have hf : ν.with_density f (A ∩ (S ∩ T)ᶜ) = 0
      ·
        refine' with_density_absolutely_continuous ν _ _ 
        rw [←nonpos_iff_eq_zero]
        exact hνinter ▸ measure_mono (Set.inter_subset_right _ _)
      have hrn : ν.with_density (μ.rn_deriv ν) (A ∩ (S ∩ T)ᶜ) = 0
      ·
        refine' with_density_absolutely_continuous ν _ _ 
        rw [←nonpos_iff_eq_zero]
        exact hνinter ▸ measure_mono (Set.inter_subset_right _ _)
      rw [restrict_apply hA, restrict_apply hA, ←add_zeroₓ (s (A ∩ (S ∩ T)ᶜ)), ←hf, ←add_apply, ←hadd, add_apply, hrn,
        add_zeroₓ]
    have heq' : ∀ A : Set α, MeasurableSet A → s A = s.restrict ((S ∩ T)ᶜ) A
    ·
      intro A hA 
      have hsinter : s (A ∩ (S ∩ T)) = 0
      ·
        rw [←nonpos_iff_eq_zero]
        exact hS₂ ▸ measure_mono (Set.Subset.trans (Set.inter_subset_right _ _) (Set.inter_subset_left _ _))
      rw [restrict_apply hA, ←add_zeroₓ (s (A ∩ (S ∩ T)ᶜ)), ←hsinter, ←measure_union, ←Set.inter_union_distrib_left,
        Set.compl_union_self, Set.inter_univ]
      ·
        exact Disjoint.inter_left' _ (Disjoint.inter_right' _ disjoint_compl_left)
      ·
        measurability
      ·
        measurability 
    ext1 A hA 
    have hμinter : μ.singular_part ν (A ∩ (S ∩ T)) = 0
    ·
      rw [←nonpos_iff_eq_zero]
      exact hT₂ ▸ measure_mono (Set.Subset.trans (Set.inter_subset_right _ _) (Set.inter_subset_right _ _))
    rw [heq' A hA, HEq, ←add_zeroₓ ((μ.singular_part ν).restrict ((S ∩ T)ᶜ) A), ←hμinter, restrict_apply hA,
      ←measure_union, ←Set.inter_union_distrib_left, Set.compl_union_self, Set.inter_univ]
    ·
      exact Disjoint.inter_left' _ (Disjoint.inter_right' _ disjoint_compl_left)
    ·
      measurability
    ·
      measurability

theorem singular_part_zero (ν : Measureₓ α) : (0 : Measureₓ α).singularPart ν = 0 :=
  by 
    refine' (eq_singular_part measurable_zero mutually_singular.zero_left _).symm 
    rw [zero_addₓ, with_density_zero]

theorem singular_part_smul (μ ν : Measureₓ α) (r :  ℝ≥0 ) : (r • μ).singularPart ν = r • μ.singular_part ν :=
  by 
    byCases' hr : r = 0
    ·
      rw [hr, zero_smul, zero_smul, singular_part_zero]
    byCases' hl : have_lebesgue_decomposition μ ν
    ·
      have  := hl 
      refine'
        (eq_singular_part ((measurable_rn_deriv μ ν).const_smul (r : ℝ≥0∞))
            (mutually_singular.smul r (have_lebesgue_decomposition_spec _ _).2.1) _).symm
          
      rw [with_density_smul _ (measurable_rn_deriv _ _), ←smul_add, ←have_lebesgue_decomposition_add μ ν,
        Ennreal.smul_def]
    ·
      rw [singular_part, singular_part, dif_neg hl, dif_neg, smul_zero]
      refine' fun hl' => hl _ 
      rw [←inv_smul_smul₀ hr μ]
      exact @measure.have_lebesgue_decomposition_smul _ _ _ _ hl' _

theorem singular_part_add (μ₁ μ₂ ν : Measureₓ α) [have_lebesgue_decomposition μ₁ ν] [have_lebesgue_decomposition μ₂ ν] :
  (μ₁+μ₂).singularPart ν = μ₁.singular_part ν+μ₂.singular_part ν :=
  by 
    refine'
      (eq_singular_part ((measurable_rn_deriv μ₁ ν).add (measurable_rn_deriv μ₂ ν))
          ((have_lebesgue_decomposition_spec _ _).2.1.add_left (have_lebesgue_decomposition_spec _ _).2.1) _).symm
        
    erw [with_density_add (measurable_rn_deriv μ₁ ν) (measurable_rn_deriv μ₂ ν)]
    convRHS => rw [add_assocₓ, add_commₓ (μ₂.singular_part ν), ←add_assocₓ, ←add_assocₓ]
    rw [←have_lebesgue_decomposition_add μ₁ ν, add_assocₓ, add_commₓ (ν.with_density (μ₂.rn_deriv ν)),
      ←have_lebesgue_decomposition_add μ₂ ν]

theorem singular_part_with_density (ν : Measureₓ α) {f : α → ℝ≥0∞} (hf : Measurable f) :
  (ν.with_density f).singularPart ν = 0 :=
  by 
    have  : ν.with_density f = 0+ν.with_density f
    ·
      rw [zero_addₓ]
    exact (eq_singular_part hf mutually_singular.zero_left this).symm

/-- Given measures `μ` and `ν`, if `s` is a measure mutually singular to `ν` and `f` is a
measurable function such that `μ = s + fν`, then `f = μ.rn_deriv ν`.

This theorem provides the uniqueness of the `rn_deriv` in the Lebesgue decomposition
theorem, while `measure_theory.measure.eq_singular_part` provides the uniqueness of the
`singular_part`. Here, the uniqueness is given in terms of the measures, while the uniqueness in
terms of the functions is given in `eq_rn_deriv`. -/
theorem eq_with_density_rn_deriv {s : Measureₓ α} {f : α → ℝ≥0∞} (hf : Measurable f) (hs : s ⊥ₘ ν)
  (hadd : μ = s+ν.with_density f) : ν.with_density f = ν.with_density (μ.rn_deriv ν) :=
  by 
    have  : have_lebesgue_decomposition μ ν := ⟨⟨⟨s, f⟩, hf, hs, hadd⟩⟩
    obtain ⟨hmeas, hsing, hadd'⟩ := have_lebesgue_decomposition_spec μ ν 
    obtain ⟨⟨S, hS₁, hS₂, hS₃⟩, ⟨T, hT₁, hT₂, hT₃⟩⟩ := hs, hsing 
    rw [hadd'] at hadd 
    have hνinter : ν ((S ∩ T)ᶜ) = 0
    ·
      rw [Set.compl_inter]
      refine' nonpos_iff_eq_zero.1 (le_transₓ (measure_union_le _ _) _)
      rw [hT₃, hS₃, add_zeroₓ]
      exact le_reflₓ _ 
    have heq : (ν.with_density f).restrict (S ∩ T) = (ν.with_density (μ.rn_deriv ν)).restrict (S ∩ T)
    ·
      ext1 A hA 
      have hs : s (A ∩ (S ∩ T)) = 0
      ·
        rw [←nonpos_iff_eq_zero]
        exact hS₂ ▸ measure_mono (Set.Subset.trans (Set.inter_subset_right _ _) (Set.inter_subset_left _ _))
      have hsing : μ.singular_part ν (A ∩ (S ∩ T)) = 0
      ·
        rw [←nonpos_iff_eq_zero]
        exact hT₂ ▸ measure_mono (Set.Subset.trans (Set.inter_subset_right _ _) (Set.inter_subset_right _ _))
      rw [restrict_apply hA, restrict_apply hA, ←add_zeroₓ (ν.with_density f (A ∩ (S ∩ T))), ←hs, ←add_apply, add_commₓ,
        ←hadd, add_apply, hsing, zero_addₓ]
    have heq' : ∀ A : Set α, MeasurableSet A → ν.with_density f A = (ν.with_density f).restrict (S ∩ T) A
    ·
      intro A hA 
      have hνfinter : ν.with_density f (A ∩ (S ∩ T)ᶜ) = 0
      ·
        rw [←nonpos_iff_eq_zero]
        exact with_density_absolutely_continuous ν f hνinter ▸ measure_mono (Set.inter_subset_right _ _)
      rw [restrict_apply hA, ←add_zeroₓ (ν.with_density f (A ∩ (S ∩ T))), ←hνfinter, ←measure_union,
        ←Set.inter_union_distrib_left, Set.union_compl_self, Set.inter_univ]
      ·
        exact Disjoint.inter_left' _ (Disjoint.inter_right' _ disjoint_compl_right)
      ·
        measurability
      ·
        measurability 
    ext1 A hA 
    have hνrn : ν.with_density (μ.rn_deriv ν) (A ∩ (S ∩ T)ᶜ) = 0
    ·
      rw [←nonpos_iff_eq_zero]
      exact with_density_absolutely_continuous ν (μ.rn_deriv ν) hνinter ▸ measure_mono (Set.inter_subset_right _ _)
    rw [heq' A hA, HEq, ←add_zeroₓ ((ν.with_density (μ.rn_deriv ν)).restrict (S ∩ T) A), ←hνrn, restrict_apply hA,
      ←measure_union, ←Set.inter_union_distrib_left, Set.union_compl_self, Set.inter_univ]
    ·
      exact Disjoint.inter_left' _ (Disjoint.inter_right' _ disjoint_compl_right)
    ·
      measurability
    ·
      measurability

/-- Given measures `μ` and `ν`, if `s` is a measure mutually singular to `ν` and `f` is a
measurable function such that `μ = s + fν`, then `f = μ.rn_deriv ν`.

This theorem provides the uniqueness of the `rn_deriv` in the Lebesgue decomposition
theorem, while `measure_theory.measure.eq_singular_part` provides the uniqueness of the
`singular_part`. Here, the uniqueness is given in terms of the functions, while the uniqueness in
terms of the functions is given in `eq_with_density_rn_deriv`. -/
theorem eq_rn_deriv [sigma_finite ν] {s : Measureₓ α} {f : α → ℝ≥0∞} (hf : Measurable f) (hs : s ⊥ₘ ν)
  (hadd : μ = s+ν.with_density f) : f =ᵐ[ν] μ.rn_deriv ν :=
  by 
    refine' ae_eq_of_forall_set_lintegral_eq_of_sigma_finite hf (measurable_rn_deriv μ ν) _ 
    intro a ha h'a 
    calc (∫⁻ x : α in a, f x ∂ν) = ν.with_density f a :=
      (with_density_apply f ha).symm _ = ν.with_density (μ.rn_deriv ν) a :=
      by 
        rw [eq_with_density_rn_deriv hf hs hadd]_ = ∫⁻ x : α in a, μ.rn_deriv ν x ∂ν :=
      with_density_apply _ ha

/-- The Radon-Nikodym derivative of `f ν` with respect to `ν` is `f`. -/
theorem rn_deriv_with_density (ν : Measureₓ α) [sigma_finite ν] {f : α → ℝ≥0∞} (hf : Measurable f) :
  (ν.with_density f).rnDeriv ν =ᵐ[ν] f :=
  by 
    have  : ν.with_density f = 0+ν.with_density f
    ·
      rw [zero_addₓ]
    exact (eq_rn_deriv hf mutually_singular.zero_left this).symm

open VectorMeasure SignedMeasure

/-- If two finite measures `μ` and `ν` are not mutually singular, there exists some `ε > 0` and
a measurable set `E`, such that `ν(E) > 0` and `E` is positive with respect to `μ - εν`.

This lemma is useful for the Lebesgue decomposition theorem. -/
theorem exists_positive_of_not_mutually_singular (μ ν : Measureₓ α) [is_finite_measure μ] [is_finite_measure ν]
  (h : ¬μ ⊥ₘ ν) :
  ∃ ε :  ℝ≥0 , 0 < ε ∧ ∃ E : Set α, MeasurableSet E ∧ 0 < ν E ∧ 0 ≤[E] μ.to_signed_measure - (ε • ν).toSignedMeasure :=
  by 
    have  :
      ∀ n : ℕ,
        ∃ i : Set α,
          MeasurableSet i ∧
            0 ≤[i] μ.to_signed_measure - ((1 / n+1 :  ℝ≥0 ) • ν).toSignedMeasure ∧
              μ.to_signed_measure - ((1 / n+1 :  ℝ≥0 ) • ν).toSignedMeasure ≤[iᶜ] 0
    ·
      intro 
      exact exists_compl_positive_negative _ 
    choose f hf₁ hf₂ hf₃ using this 
    set A := ⋂ n, f nᶜ with hA₁ 
    have hAmeas : MeasurableSet A
    ·
      exact MeasurableSet.Inter fun n => (hf₁ n).Compl 
    have hA₂ : ∀ n : ℕ, μ.to_signed_measure - ((1 / n+1 :  ℝ≥0 ) • ν).toSignedMeasure ≤[A] 0
    ·
      intro n 
      exact restrict_le_restrict_subset _ _ (hf₁ n).Compl (hf₃ n) (Set.Inter_subset _ _)
    have hA₃ : ∀ n : ℕ, μ A ≤ (1 / n+1 :  ℝ≥0 )*ν A
    ·
      intro n 
      have  := nonpos_of_restrict_le_zero _ (hA₂ n)
      rwa [to_signed_measure_sub_apply hAmeas, sub_nonpos, Ennreal.to_real_le_to_real] at this 
      exacts[ne_of_ltₓ (measure_lt_top _ _), ne_of_ltₓ (measure_lt_top _ _)]
    have hμ : μ A = 0
    ·
      lift μ A to  ℝ≥0  using ne_of_ltₓ (measure_lt_top _ _) with μA 
      lift ν A to  ℝ≥0  using ne_of_ltₓ (measure_lt_top _ _) with νA 
      rw [Ennreal.coe_eq_zero]
      byCases' hb : 0 < νA
      ·
        suffices  : ∀ b, 0 < b → μA ≤ b
        ·
          byContra 
          have h' := this (μA / 2) (Nnreal.half_pos (zero_lt_iff.2 h))
          rw [←@not_not (μA ≤ μA / 2)] at h' 
          exact h' (not_leₓ.2 (Nnreal.half_lt_self h))
        intro c hc 
        have  : ∃ n : ℕ, 1 / (n+1 : ℝ) < c*νA⁻¹
        refine' exists_nat_one_div_lt _
        ·
          refine' mul_pos hc _ 
          rw [_root_.inv_pos]
          exact hb 
        rcases this with ⟨n, hn⟩
        have hb₁ : (0 : ℝ) < νA⁻¹
        ·
          rw [_root_.inv_pos]
          exact hb 
        have h' : ((1 / (↑n)+1)*νA) < c
        ·
          rw [←Nnreal.coe_lt_coe, ←mul_lt_mul_right hb₁, Nnreal.coe_mul, mul_assocₓ, ←Nnreal.coe_inv, ←Nnreal.coe_mul,
            _root_.mul_inv_cancel, ←Nnreal.coe_mul, mul_oneₓ, Nnreal.coe_inv]
          ·
            convert hn 
            simp 
          ·
            exact Ne.symm (ne_of_ltₓ hb)
        refine' le_transₓ _ (le_of_ltₓ h')
        rw [←Ennreal.coe_le_coe, Ennreal.coe_mul]
        exact hA₃ n
      ·
        rw [not_ltₓ, le_zero_iff] at hb 
        specialize hA₃ 0
        simp [hb, le_zero_iff] at hA₃ 
        assumption 
    rw [mutually_singular] at h 
    pushNeg  at h 
    have  := h _ hAmeas hμ 
    simpRw [hA₁, Set.compl_Inter, compl_compl]  at this 
    obtain ⟨n, hn⟩ := exists_measure_pos_of_not_measure_Union_null this 
    exact
      ⟨1 / n+1,
        by 
          simp ,
        f n, hf₁ n, hn, hf₂ n⟩

namespace LebesgueDecomposition

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    Given two measures `μ` and `ν`, `measurable_le μ ν` is the set of measurable
    functions `f`, such that, for all measurable sets `A`, `∫⁻ x in A, f x ∂μ ≤ ν A`.
    
    This is useful for the Lebesgue decomposition theorem. -/
  def
    measurable_le
    ( μ ν : Measureₓ α ) : Set α → ℝ≥0∞
    := { f | Measurable f ∧ ∀ A : Set α hA : MeasurableSet A , ∫⁻ x in A , f x ∂ μ ≤ ν A }

theorem zero_mem_measurable_le : (0 : α → ℝ≥0∞) ∈ measurable_le μ ν :=
  ⟨measurable_zero,
    fun A hA =>
      by 
        simp ⟩

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  max_measurable_le
  ( f g : α → ℝ≥0∞ )
      ( hf : f ∈ measurable_le μ ν )
      ( hg : g ∈ measurable_le μ ν )
      ( A : Set α )
      ( hA : MeasurableSet A )
    : ∫⁻ a in A , max f a g a ∂ μ ≤ ∫⁻ a in A ∩ { a | f a ≤ g a } , g a ∂ μ + ∫⁻ a in A ∩ { a | g a < f a } , f a ∂ μ
  :=
    by
      rw [ ← lintegral_indicator _ hA , ← lintegral_indicator f , ← lintegral_indicator g , ← lintegral_add ]
        ·
          refine' lintegral_mono fun a => _
            byCases' haA : a ∈ A
            ·
              byCases' f a ≤ g a
                ·
                  simp only
                    rw [ Set.indicator_of_mem haA , Set.indicator_of_mem , Set.indicator_of_not_mem , add_zeroₓ ]
                    simp only [ le_reflₓ , max_le_iff , and_trueₓ , h ]
                    · rintro ⟨ _ , hc ⟩ exact False.elim not_ltₓ . 2 h hc
                    · exact ⟨ haA , h ⟩
                ·
                  simp only
                    rw [ Set.indicator_of_mem haA , Set.indicator_of_mem _ f , Set.indicator_of_not_mem , zero_addₓ ]
                    simp only [ true_andₓ , le_reflₓ , max_le_iff , le_of_ltₓ not_leₓ . 1 h ]
                    · rintro ⟨ _ , hc ⟩ exact False.elim h hc
                    · exact ⟨ haA , not_leₓ . 1 h ⟩
            · simp [ Set.indicator_of_not_mem haA ]
        · exact Measurable.indicator hg . 1 hA.inter measurable_set_le hf . 1 hg . 1
        · exact Measurable.indicator hf . 1 hA.inter measurable_set_lt hg . 1 hf . 1
        · exact hA.inter measurable_set_le hf . 1 hg . 1
        · exact hA.inter measurable_set_lt hg . 1 hf . 1

theorem sup_mem_measurable_le {f g : α → ℝ≥0∞} (hf : f ∈ measurable_le μ ν) (hg : g ∈ measurable_le μ ν) :
  (fun a => f a⊔g a) ∈ measurable_le μ ν :=
  by 
    simpRw [Ennreal.sup_eq_max]
    refine' ⟨Measurable.max hf.1 hg.1, fun A hA => _⟩
    have h₁ := hA.inter (measurable_set_le hf.1 hg.1)
    have h₂ := hA.inter (measurable_set_lt hg.1 hf.1)
    refine' le_transₓ (max_measurable_le f g hf hg A hA) _ 
    refine' le_transₓ (add_le_add (hg.2 _ h₁) (hf.2 _ h₂)) _
    ·
      rw [←measure_union _ h₁ h₂]
      ·
        refine' le_of_eqₓ _ 
        congr 
        convert Set.inter_union_compl A _ 
        ext a 
        simpa 
      rintro x ⟨⟨-, hx₁⟩, -, hx₂⟩
      exact (not_leₓ.2 hx₂) hx₁

theorem supr_succ_eq_sup {α} (f : ℕ → α → ℝ≥0∞) (m : ℕ) (a : α) :
  (⨆ (k : ℕ)(hk : k ≤ m+1), f k a) = f m.succ a⊔⨆ (k : ℕ)(hk : k ≤ m), f k a :=
  by 
    ext x 
    simp only [Option.mem_def, Ennreal.some_eq_coe]
    constructor <;> intro h <;> rw [←h]
    symm 
    all_goals 
      set c := ⨆ (k : ℕ)(hk : k ≤ m+1), f k a with hc 
      set d := f m.succ a⊔⨆ (k : ℕ)(hk : k ≤ m), f k a with hd 
      suffices  : c ≤ d ∧ d ≤ c
      ·
        change c = d 
        exact le_antisymmₓ this.1 this.2
      rw [hc, hd]
      refine' ⟨_, _⟩
      ·
        refine' bsupr_le fun n hn => _ 
        rcases Nat.of_le_succ hn with (h | h)
        ·
          exact le_sup_of_le_right (le_bsupr n h)
        ·
          exact h ▸ le_sup_left
      ·
        refine' sup_le _ _
        ·
          convert @le_bsupr _ _ _ (fun i => i ≤ m+1) _ m.succ (le_reflₓ _)
          rfl
        ·
          refine' bsupr_le fun n hn => _ 
          have  := le_transₓ hn (Nat.le_succₓ m)
          exact le_bsupr n this

theorem supr_mem_measurable_le (f : ℕ → α → ℝ≥0∞) (hf : ∀ n, f n ∈ measurable_le μ ν) (n : ℕ) :
  (fun x => ⨆ (k : _)(hk : k ≤ n), f k x) ∈ measurable_le μ ν :=
  by 
    induction' n with m hm
    ·
      refine' ⟨_, _⟩
      ·
        simp [(hf 0).1]
      ·
        intro A hA 
        simp [(hf 0).2 A hA]
    ·
      have  : (fun a : α => ⨆ (k : ℕ)(hk : k ≤ m+1), f k a) = fun a => f m.succ a⊔⨆ (k : ℕ)(hk : k ≤ m), f k a
      ·
        exact funext fun _ => supr_succ_eq_sup _ _ _ 
      refine' ⟨measurable_supr fun n => Measurable.supr_Prop _ (hf n).1, fun A hA => _⟩
      rw [this]
      exact (sup_mem_measurable_le (hf m.succ) hm).2 A hA

theorem supr_mem_measurable_le' (f : ℕ → α → ℝ≥0∞) (hf : ∀ n, f n ∈ measurable_le μ ν) (n : ℕ) :
  (⨆ (k : _)(hk : k ≤ n), f k) ∈ measurable_le μ ν :=
  by 
    convert supr_mem_measurable_le f hf n 
    ext 
    simp 

section SuprLemmas

omit m

theorem supr_monotone {α : Type _} (f : ℕ → α → ℝ≥0∞) : Monotone fun n x => ⨆ (k : _)(hk : k ≤ n), f k x :=
  by 
    intro n m hnm x 
    simp only 
    refine' bsupr_le fun k hk => _ 
    have  : k ≤ m := le_transₓ hk hnm 
    exact le_bsupr k this

theorem supr_monotone' {α : Type _} (f : ℕ → α → ℝ≥0∞) (x : α) : Monotone fun n => ⨆ (k : _)(hk : k ≤ n), f k x :=
  fun n m hnm => supr_monotone f hnm x

theorem supr_le_le {α : Type _} (f : ℕ → α → ℝ≥0∞) (n k : ℕ) (hk : k ≤ n) :
  f k ≤ fun x => ⨆ (k : _)(hk : k ≤ n), f k x :=
  fun x => le_bsupr k hk

end SuprLemmas

/-- `measurable_le_eval μ ν` is the set of `∫⁻ x, f x ∂μ` for all `f ∈ measurable_le μ ν`. -/
def measurable_le_eval (μ ν : Measureₓ α) : Set ℝ≥0∞ :=
  (fun f : α → ℝ≥0∞ => ∫⁻ x, f x ∂μ) '' measurable_le μ ν

end LebesgueDecomposition

open LebesgueDecomposition

/-- Any pair of finite measures `μ` and `ν`, `have_lebesgue_decomposition`. That is to say,
there exist a measure `ξ` and a measurable function `f`, such that `ξ` is mutually singular
with respect to `ν` and `μ = ξ + ν.with_density f`.

This is not an instance since this is also shown for the more general σ-finite measures with
`measure_theory.measure.have_lebesgue_decomposition_of_sigma_finite`. -/
theorem have_lebesgue_decomposition_of_finite_measure [is_finite_measure μ] [is_finite_measure ν] :
  have_lebesgue_decomposition μ ν :=
  ⟨by 
      have h :=
        @exists_seq_tendsto_Sup _ _ _ _ _ (measurable_le_eval ν μ)
          ⟨0, 0, zero_mem_measurable_le,
            by 
              simp ⟩
          (OrderTop.bdd_above _)
      choose g hmono hg₂ f hf₁ hf₂ using h 
      set ξ := ⨆ (n k : _)(hk : k ≤ n), f k with hξ 
      have hξ₁ : Sup (measurable_le_eval ν μ) = ∫⁻ a, ξ a ∂ν
      ·
        have  :=
          @lintegral_tendsto_of_tendsto_of_monotone _ _ ν (fun n => ⨆ (k : _)(hk : k ≤ n), f k)
            (⨆ (n k : _)(hk : k ≤ n), f k) _ _ _
        ·
          refine' tendsto_nhds_unique _ this 
          refine' tendsto_of_tendsto_of_tendsto_of_le_of_le hg₂ tendsto_const_nhds _ _
          ·
            intro n 
            rw [←hf₂ n]
            apply lintegral_mono 
            simp only [supr_apply, supr_le_le f n n (le_reflₓ _)]
          ·
            intro n 
            exact le_Sup ⟨⨆ (k : ℕ)(hk : k ≤ n), f k, supr_mem_measurable_le' _ hf₁ _, rfl⟩
        ·
          intro n 
          refine' Measurable.ae_measurable _ 
          convert (supr_mem_measurable_le _ hf₁ n).1 
          ext 
          simp 
        ·
          refine' Filter.eventually_of_forall fun a => _ 
          simp [supr_monotone' f _]
        ·
          refine' Filter.eventually_of_forall fun a => _ 
          simp [tendsto_at_top_supr (supr_monotone' f a)]
      have hξm : Measurable ξ
      ·
        convert measurable_supr fun n => (supr_mem_measurable_le _ hf₁ n).1 
        ext 
        simp [hξ]
      set μ₁ := μ - ν.with_density ξ with hμ₁ 
      have hle : ν.with_density ξ ≤ μ
      ·
        intro B hB 
        rw [hξ, with_density_apply _ hB]
        simpRw [supr_apply]
        rw [lintegral_supr (fun i => (supr_mem_measurable_le _ hf₁ i).1) (supr_monotone _)]
        exact supr_le fun i => (supr_mem_measurable_le _ hf₁ i).2 B hB 
      have  : is_finite_measure (ν.with_density ξ)
      ·
        refine' is_finite_measure_with_density _ 
        have hle' := hle Set.Univ MeasurableSet.univ 
        rw [with_density_apply _ MeasurableSet.univ, measure.restrict_univ] at hle' 
        exact ne_top_of_le_ne_top (measure_ne_top _ _) hle' 
      refine' ⟨⟨μ₁, ξ⟩, hξm, _, _⟩
      ·
        byContra 
        obtain ⟨ε, hε₁, E, hE₁, hE₂, hE₃⟩ := exists_positive_of_not_mutually_singular μ₁ ν h 
        simpRw [hμ₁]  at hE₃ 
        have hξle : ∀ A, MeasurableSet A → (∫⁻ a in A, ξ a ∂ν) ≤ μ A
        ·
          intro A hA 
          rw [hξ]
          simpRw [supr_apply]
          rw [lintegral_supr (fun n => (supr_mem_measurable_le _ hf₁ n).1) (supr_monotone _)]
          exact supr_le fun n => (supr_mem_measurable_le _ hf₁ n).2 A hA 
        have hε₂ : ∀ A : Set α, MeasurableSet A → (∫⁻ a in A ∩ E, ε+ξ a ∂ν) ≤ μ (A ∩ E)
        ·
          intro A hA 
          have  := subset_le_of_restrict_le_restrict _ _ hE₁ hE₃ (Set.inter_subset_right A E)
          rwa [zero_apply, to_signed_measure_sub_apply (hA.inter hE₁), measure.sub_apply (hA.inter hE₁) hle,
            Ennreal.to_real_sub_of_le _ (ne_of_ltₓ (measure_lt_top _ _)), sub_nonneg, le_sub_iff_add_le,
            ←Ennreal.to_real_add, Ennreal.to_real_le_to_real, measure.coe_nnreal_smul, Pi.smul_apply,
            with_density_apply _ (hA.inter hE₁),
            show ε • ν (A ∩ E) = (ε : ℝ≥0∞)*ν (A ∩ E)by 
              rfl,
            ←set_lintegral_const, ←lintegral_add measurable_const hξm] at this
          ·
            rw [Ne.def, Ennreal.add_eq_top, not_or_distrib]
            exact ⟨ne_of_ltₓ (measure_lt_top _ _), ne_of_ltₓ (measure_lt_top _ _)⟩
          ·
            exact ne_of_ltₓ (measure_lt_top _ _)
          ·
            exact ne_of_ltₓ (measure_lt_top _ _)
          ·
            exact ne_of_ltₓ (measure_lt_top _ _)
          ·
            rw [with_density_apply _ (hA.inter hE₁)]
            exact hξle (A ∩ E) (hA.inter hE₁)
          ·
            infer_instance 
        have hξε : (ξ+E.indicator fun _ => ε) ∈ measurable_le ν μ
        ·
          refine' ⟨Measurable.add hξm (Measurable.indicator measurable_const hE₁), fun A hA => _⟩
          have  : (∫⁻ a in A, (ξ+E.indicator fun _ => ε) a ∂ν) = (∫⁻ a in A ∩ E, ε+ξ a ∂ν)+∫⁻ a in A ∩ Eᶜ, ξ a ∂ν
          ·
            rw [lintegral_add measurable_const hξm, add_assocₓ,
              ←lintegral_union (hA.inter hE₁) (hA.inter hE₁.compl)
                (Disjoint.mono (Set.inter_subset_right _ _) (Set.inter_subset_right _ _) disjoint_compl_right),
              Set.inter_union_compl]
            simpRw [Pi.add_apply]
            rw [lintegral_add hξm (Measurable.indicator measurable_const hE₁), add_commₓ]
            refine' congr_funₓ (congr_argₓ Add.add _) _ 
            rw [set_lintegral_const, lintegral_indicator _ hE₁, set_lintegral_const, measure.restrict_apply hE₁,
              Set.inter_comm]
          convRHS => rw [←Set.inter_union_compl A E]
          rw [this, measure_union _ (hA.inter hE₁) (hA.inter hE₁.compl)]
          ·
            exact add_le_add (hε₂ A hA) (hξle (A ∩ Eᶜ) (hA.inter hE₁.compl))
          ·
            exact Disjoint.mono (Set.inter_subset_right _ _) (Set.inter_subset_right _ _) disjoint_compl_right 
        have  : (∫⁻ a, ξ a+E.indicator (fun _ => ε) a ∂ν) ≤ Sup (measurable_le_eval ν μ) :=
          le_Sup ⟨ξ+E.indicator fun _ => ε, hξε, rfl⟩
        refine' not_ltₓ.2 this _ 
        rw [hξ₁, lintegral_add hξm (Measurable.indicator measurable_const hE₁), lintegral_indicator _ hE₁,
          set_lintegral_const]
        refine' Ennreal.lt_add_right _ (Ennreal.mul_pos_iff.2 ⟨Ennreal.coe_pos.2 hε₁, hE₂⟩).ne' 
        have  := measure_ne_top (ν.with_density ξ) Set.Univ 
        rwa [with_density_apply _ MeasurableSet.univ, measure.restrict_univ] at this
      ·
        rw [hμ₁]
        ext1 A hA 
        rw [measure.coe_add, Pi.add_apply, measure.sub_apply hA hle, add_commₓ, add_tsub_cancel_of_le (hle A hA)]⟩

attribute [local instance] have_lebesgue_decomposition_of_finite_measure

instance {S : μ.finite_spanning_sets_in { s : Set α | MeasurableSet s }} (n : ℕ) :
  is_finite_measure (μ.restrict$ S.set n) :=
  ⟨by 
      rw [restrict_apply MeasurableSet.univ, Set.univ_inter]
      exact S.finite _⟩

/-- **The Lebesgue decomposition theorem**: Any pair of σ-finite measures `μ` and `ν`
`have_lebesgue_decomposition`. That is to say, there exist a measure `ξ` and a measurable function
`f`, such that `ξ` is mutually singular with respect to `ν` and `μ = ξ + ν.with_density f` -/
instance (priority := 100) have_lebesgue_decomposition_of_sigma_finite (μ ν : Measureₓ α) [sigma_finite μ]
  [sigma_finite ν] : have_lebesgue_decomposition μ ν :=
  ⟨by 
      obtain ⟨S, T, h₁, h₂⟩ := exists_eq_disjoint_finite_spanning_sets_in μ ν 
      have h₃ : Pairwise (Disjoint on T.set) := h₁ ▸ h₂ 
      set μn : ℕ → Measureₓ α := fun n => μ.restrict (S.set n) with hμn 
      have hμ : μ = Sum μn
      ·
        rw [hμn, ←restrict_Union h₂ S.set_mem, S.spanning, restrict_univ]
      set νn : ℕ → Measureₓ α := fun n => ν.restrict (T.set n) with hνn 
      have hν : ν = Sum νn
      ·
        rw [hνn, ←restrict_Union h₃ T.set_mem, T.spanning, restrict_univ]
      set ξ := Sum fun n => singular_part (μn n) (νn n) with hξ 
      set f := ∑' n, (S.set n).indicator (rn_deriv (μn n) (νn n)) with hf 
      refine' ⟨⟨ξ, f⟩, _, _, _⟩
      ·
        exact Measurable.ennreal_tsum' fun n => Measurable.indicator (measurable_rn_deriv (μn n) (νn n)) (S.set_mem n)
      ·
        choose A hA₁ hA₂ hA₃ using fun n => mutually_singular_singular_part (μn n) (νn n)
        simp only [hξ]
        refine' ⟨⋃ j, S.set j ∩ A j, MeasurableSet.Union fun n => (S.set_mem n).inter (hA₁ n), _, _⟩
        ·
          rw [measure_Union]
          ·
            have  :
              ∀ i,
                (Sum fun n => (μn n).singularPart (νn n)) (S.set i ∩ A i) = (μn i).singularPart (νn i) (S.set i ∩ A i)
            ·
              intro i 
              rw [sum_apply _ ((S.set_mem i).inter (hA₁ i)), tsum_eq_single i]
              ·
                intro j hij 
                rw [hμn, ←nonpos_iff_eq_zero]
                refine' le_transₓ ((singular_part_le _ _) _ ((S.set_mem i).inter (hA₁ i))) (le_of_eqₓ _)
                rw [restrict_apply ((S.set_mem i).inter (hA₁ i)), Set.inter_comm, ←Set.inter_assoc]
                have  : Disjoint (S.set j) (S.set i) := h₂ j i hij 
                rw [Set.disjoint_iff_inter_eq_empty] at this 
                rw [this, Set.empty_inter, measure_empty]
              ·
                infer_instance 
            simpRw [this, tsum_eq_zero_iff Ennreal.summable]
            intro n 
            exact measure_mono_null (Set.inter_subset_right _ _) (hA₂ n)
          ·
            exact h₂.mono fun i j => Disjoint.mono inf_le_left inf_le_left
          ·
            exact fun n => (S.set_mem n).inter (hA₁ n)
        ·
          have hcompl : IsCompl (⋃ n, S.set n ∩ A n) (⋃ n, S.set n ∩ A nᶜ)
          ·
            constructor
            ·
              rintro x ⟨hx₁, hx₂⟩
              rw [Set.mem_Union] at hx₁ hx₂ 
              obtain ⟨⟨i, hi₁, hi₂⟩, ⟨j, hj₁, hj₂⟩⟩ := hx₁, hx₂ 
              have  : i = j
              ·
                byContra hij 
                exact h₂ i j hij ⟨hi₁, hj₁⟩
              exact hj₂ (this ▸ hi₂)
            ·
              intro x hx 
              simp only [Set.mem_Union, Set.sup_eq_union, Set.mem_inter_eq, Set.mem_union_eq, Set.mem_compl_eq,
                or_iff_not_imp_left]
              intro h 
              pushNeg  at h 
              rw [Set.top_eq_univ, ←S.spanning, Set.mem_Union] at hx 
              obtain ⟨i, hi⟩ := hx 
              exact ⟨i, hi, h i hi⟩
          rw [hcompl.compl_eq, measure_Union, tsum_eq_zero_iff Ennreal.summable]
          ·
            intro n 
            rw [Set.inter_comm, ←restrict_apply (hA₁ n).Compl, ←hA₃ n, hνn, h₁]
          ·
            exact h₂.mono fun i j => Disjoint.mono inf_le_left inf_le_left
          ·
            exact fun n => (S.set_mem n).inter (hA₁ n).Compl
      ·
        simp only [hξ, hf, hμ]
        rw [with_density_tsum _, sum_add_sum]
        ·
          refine' sum_congr fun n => _ 
          convLHS => rw [have_lebesgue_decomposition_add (μn n) (νn n)]
          suffices heq :
            (νn n).withDensity ((μn n).rnDeriv (νn n)) = ν.with_density ((S.set n).indicator ((μn n).rnDeriv (νn n)))
          ·
            rw [HEq]
          rw [hν, with_density_indicator (S.set_mem n), restrict_sum _ (S.set_mem n)]
          suffices hsumeq : (Sum fun i : ℕ => (νn i).restrict (S.set n)) = νn n
          ·
            rw [hsumeq]
          ext1 s hs 
          rw [sum_apply _ hs, tsum_eq_single n, hνn, h₁, restrict_restrict (T.set_mem n), Set.inter_self]
          ·
            intro m hm 
            rw [hνn, h₁, restrict_restrict (T.set_mem n), Set.inter_comm, Set.disjoint_iff_inter_eq_empty.1 (h₃ m n hm),
              restrict_empty, coe_zero, Pi.zero_apply]
          ·
            infer_instance
        ·
          exact fun n => Measurable.indicator (measurable_rn_deriv _ _) (S.set_mem n)⟩

end Measureₓ

namespace SignedMeasure

open Measureₓ

/-- A signed measure `s` is said to `have_lebesgue_decomposition` with respect to a measure `μ`
if the positive part and the negative part of `s` both `have_lebesgue_decomposition` with
respect to `μ`. -/
class have_lebesgue_decomposition (s : signed_measure α) (μ : Measureₓ α) : Prop where 
  posPart : s.to_jordan_decomposition.pos_part.have_lebesgue_decomposition μ 
  negPart : s.to_jordan_decomposition.neg_part.have_lebesgue_decomposition μ

attribute [instance] have_lebesgue_decomposition.pos_part

attribute [instance] have_lebesgue_decomposition.neg_part

theorem not_have_lebesgue_decomposition_iff (s : signed_measure α) (μ : Measureₓ α) :
  ¬s.have_lebesgue_decomposition μ ↔
    ¬s.to_jordan_decomposition.pos_part.have_lebesgue_decomposition μ ∨
      ¬s.to_jordan_decomposition.neg_part.have_lebesgue_decomposition μ :=
  ⟨fun h => not_or_of_imp fun hp hn => h ⟨hp, hn⟩, fun h hl => (not_and_distrib.2 h) ⟨hl.1, hl.2⟩⟩

instance (priority := 100) have_lebesgue_decomposition_of_sigma_finite (s : signed_measure α) (μ : Measureₓ α)
  [sigma_finite μ] : s.have_lebesgue_decomposition μ :=
  { posPart := inferInstance, negPart := inferInstance }

instance have_lebesgue_decomposition_neg (s : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ] :
  (-s).HaveLebesgueDecomposition μ :=
  { posPart :=
      by 
        rw [to_jordan_decomposition_neg, jordan_decomposition.neg_pos_part]
        infer_instance,
    negPart :=
      by 
        rw [to_jordan_decomposition_neg, jordan_decomposition.neg_neg_part]
        infer_instance }

instance have_lebesgue_decomposition_smul (s : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  (r :  ℝ≥0 ) : (r • s).HaveLebesgueDecomposition μ :=
  { posPart :=
      by 
        rw [to_jordan_decomposition_smul, jordan_decomposition.smul_pos_part]
        infer_instance,
    negPart :=
      by 
        rw [to_jordan_decomposition_smul, jordan_decomposition.smul_neg_part]
        infer_instance }

instance have_lebesgue_decomposition_smul_real (s : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  (r : ℝ) : (r • s).HaveLebesgueDecomposition μ :=
  by 
    byCases' hr : 0 ≤ r
    ·
      lift r to  ℝ≥0  using hr 
      exact s.have_lebesgue_decomposition_smul μ _
    ·
      rw [not_leₓ] at hr 
      refine'
        { posPart :=
            by 
              rw [to_jordan_decomposition_smul_real, jordan_decomposition.real_smul_pos_part_neg _ _ hr]
              infer_instance,
          negPart :=
            by 
              rw [to_jordan_decomposition_smul_real, jordan_decomposition.real_smul_neg_part_neg _ _ hr]
              infer_instance }

/-- Given a signed measure `s` and a measure `μ`, `s.singular_part μ` is the signed measure
such that `s.singular_part μ + μ.with_densityᵥ (s.rn_deriv μ) = s` and
`s.singular_part μ` is mutually singular with respect to `μ`. -/
def singular_part (s : signed_measure α) (μ : Measureₓ α) : signed_measure α :=
  (s.to_jordan_decomposition.pos_part.singular_part μ).toSignedMeasure -
    (s.to_jordan_decomposition.neg_part.singular_part μ).toSignedMeasure

section 

theorem singular_part_mutually_singular (s : signed_measure α) (μ : Measureₓ α) :
  s.to_jordan_decomposition.pos_part.singular_part μ ⊥ₘ s.to_jordan_decomposition.neg_part.singular_part μ :=
  by 
    byCases' hl : s.have_lebesgue_decomposition μ
    ·
      have  := hl 
      obtain ⟨i, hi, hpos, hneg⟩ := s.to_jordan_decomposition.mutually_singular 
      rw [s.to_jordan_decomposition.pos_part.have_lebesgue_decomposition_add μ] at hpos 
      rw [s.to_jordan_decomposition.neg_part.have_lebesgue_decomposition_add μ] at hneg 
      rw [add_apply, add_eq_zero_iff] at hpos hneg 
      exact ⟨i, hi, hpos.1, hneg.1⟩
    ·
      rw [not_have_lebesgue_decomposition_iff] at hl 
      cases' hl with hp hn
      ·
        rw [measure.singular_part, dif_neg hp]
        exact mutually_singular.zero_left
      ·
        rw [measure.singular_part, measure.singular_part, dif_neg hn]
        exact mutually_singular.zero_right

theorem singular_part_total_variation (s : signed_measure α) (μ : Measureₓ α) :
  (s.singular_part μ).totalVariation =
    s.to_jordan_decomposition.pos_part.singular_part μ+s.to_jordan_decomposition.neg_part.singular_part μ :=
  by 
    have  :
      (s.singular_part μ).toJordanDecomposition =
        ⟨s.to_jordan_decomposition.pos_part.singular_part μ, s.to_jordan_decomposition.neg_part.singular_part μ,
          singular_part_mutually_singular s μ⟩
    ·
      refine' jordan_decomposition.to_signed_measure_injective _ 
      rw [to_signed_measure_to_jordan_decomposition]
      rfl
    ·
      rw [total_variation, this]

theorem mutually_singular_singular_part (s : signed_measure α) (μ : Measureₓ α) :
  singular_part s μ ⊥ᵥ μ.to_ennreal_vector_measure :=
  by 
    rw [mutually_singular_ennreal_iff, singular_part_total_variation]
    change _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ)
    rw [vector_measure.equiv_measure.right_inv μ]
    exact (mutually_singular_singular_part _ _).add_left (mutually_singular_singular_part _ _)

end 

/-- The Radon-Nikodym derivative between a signed measure and a positive measure.

`rn_deriv s μ` satisfies `μ.with_densityᵥ (s.rn_deriv μ) = s`
if and only if `s` is absolutely continuous with respect to `μ` and this fact is known as
`measure_theory.signed_measure.absolutely_continuous_iff_with_density_rn_deriv_eq`
and can be found in `measure_theory.decomposition.radon_nikodym`. -/
def rn_deriv (s : signed_measure α) (μ : Measureₓ α) : α → ℝ :=
  fun x =>
    (s.to_jordan_decomposition.pos_part.rn_deriv μ x).toReal - (s.to_jordan_decomposition.neg_part.rn_deriv μ x).toReal

variable {s t : signed_measure α}

@[measurability]
theorem measurable_rn_deriv (s : signed_measure α) (μ : Measureₓ α) : Measurable (rn_deriv s μ) :=
  by 
    rw [rn_deriv]
    measurability

theorem integrable_rn_deriv (s : signed_measure α) (μ : Measureₓ α) : integrable (rn_deriv s μ) μ :=
  by 
    refine' integrable.sub _ _ <;>
      ·
        constructor 
        measurability 
        exact has_finite_integral_to_real_of_lintegral_ne_top (lintegral_rn_deriv_lt_top _ μ).Ne

/-- **The Lebesgue Decomposition theorem between a signed measure and a measure**:
Given a signed measure `s` and a σ-finite measure `μ`, there exist a signed measure `t` and a
measurable and integrable function `f`, such that `t` is mutually singular with respect to `μ`
and `s = t + μ.with_densityᵥ f`. In this case `t = s.singular_part μ` and
`f = s.rn_deriv μ`. -/
theorem singular_part_add_with_density_rn_deriv_eq [s.have_lebesgue_decomposition μ] :
  (s.singular_part μ+μ.with_densityᵥ (s.rn_deriv μ)) = s :=
  by 
    convRHS => rw [←to_signed_measure_to_jordan_decomposition s, jordan_decomposition.to_signed_measure]
    rw [singular_part, rn_deriv,
      with_densityᵥ_sub' (integrable_to_real_of_lintegral_ne_top _ _) (integrable_to_real_of_lintegral_ne_top _ _),
      with_densityᵥ_to_real, with_densityᵥ_to_real, sub_eq_add_neg, sub_eq_add_neg,
      add_commₓ (s.to_jordan_decomposition.pos_part.singular_part μ).toSignedMeasure, ←add_assocₓ,
      add_assocₓ (-(s.to_jordan_decomposition.neg_part.singular_part μ).toSignedMeasure), ←to_signed_measure_add,
      add_commₓ, ←add_assocₓ, ←neg_add, ←to_signed_measure_add, add_commₓ, ←sub_eq_add_neg]
    convert rfl
    ·
      exact s.to_jordan_decomposition.pos_part.have_lebesgue_decomposition_add μ
    ·
      rw [add_commₓ]
      exact s.to_jordan_decomposition.neg_part.have_lebesgue_decomposition_add μ 
    all_goals 
      first |
        exact (lintegral_rn_deriv_lt_top _ _).Ne|
        measurability

theorem jordan_decomposition_add_with_density_mutually_singular {f : α → ℝ} (hf : Measurable f)
  (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure) :
  (t.to_jordan_decomposition.pos_part+μ.with_density fun x : α => Ennreal.ofReal (f x)) ⊥ₘ
    t.to_jordan_decomposition.neg_part+μ.with_density fun x : α => Ennreal.ofReal (-f x) :=
  by 
    rw [mutually_singular_ennreal_iff, total_variation_mutually_singular_iff] at htμ 
    change
      _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ) ∧
        _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ) at
      htμ 
    rw [vector_measure.equiv_measure.right_inv] at htμ 
    exact
      ((jordan_decomposition.mutually_singular _).add_right
            (htμ.1.mono_ac (refl _) (with_density_absolutely_continuous _ _))).add_left
        ((htμ.2.symm.mono_ac (with_density_absolutely_continuous _ _) (refl _)).add_right
          (with_density_of_real_mutually_singular hf))

theorem to_jordan_decomposition_eq_of_eq_add_with_density {f : α → ℝ} (hf : Measurable f) (hfi : integrable f μ)
  (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure) (hadd : s = t+μ.with_densityᵥ f) :
  s.to_jordan_decomposition =
    @jordan_decomposition.mk α _ (t.to_jordan_decomposition.pos_part+μ.with_density fun x => Ennreal.ofReal (f x))
      (t.to_jordan_decomposition.neg_part+μ.with_density fun x => Ennreal.ofReal (-f x))
      (by 
        have  := is_finite_measure_with_density_of_real hfi.2
        infer_instance)
      (by 
        have  := is_finite_measure_with_density_of_real hfi.neg.2
        infer_instance)
      (jordan_decomposition_add_with_density_mutually_singular hf htμ) :=
  by 
    have  := is_finite_measure_with_density_of_real hfi.2
    have  := is_finite_measure_with_density_of_real hfi.neg.2
    refine' to_jordan_decomposition_eq _ 
    simpRw [jordan_decomposition.to_signed_measure, hadd]
    ext i hi 
    rw [vector_measure.sub_apply, to_signed_measure_apply_measurable hi, to_signed_measure_apply_measurable hi,
        add_apply, add_apply, Ennreal.to_real_add, Ennreal.to_real_add, add_sub_comm,
        ←to_signed_measure_apply_measurable hi, ←to_signed_measure_apply_measurable hi, ←vector_measure.sub_apply,
        ←jordan_decomposition.to_signed_measure, to_signed_measure_to_jordan_decomposition, vector_measure.add_apply,
        ←to_signed_measure_apply_measurable hi, ←to_signed_measure_apply_measurable hi,
        with_densityᵥ_eq_with_density_pos_part_sub_with_density_neg_part hfi, vector_measure.sub_apply] <;>
      exact (measure_lt_top _ _).Ne

private theorem have_lebesgue_decomposition_mk' (μ : Measureₓ α) {f : α → ℝ} (hf : Measurable f) (hfi : integrable f μ)
  (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure) (hadd : s = t+μ.with_densityᵥ f) : s.have_lebesgue_decomposition μ :=
  by 
    have htμ' := htμ 
    rw [mutually_singular_ennreal_iff] at htμ 
    change _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ) at htμ 
    rw [vector_measure.equiv_measure.right_inv, total_variation_mutually_singular_iff] at htμ 
    refine'
      { posPart :=
          by 
            use ⟨t.to_jordan_decomposition.pos_part, fun x => Ennreal.ofReal (f x)⟩
            refine' ⟨hf.ennreal_of_real, htμ.1, _⟩
            rw [to_jordan_decomposition_eq_of_eq_add_with_density hf hfi htμ' hadd],
        negPart :=
          by 
            use ⟨t.to_jordan_decomposition.neg_part, fun x => Ennreal.ofReal (-f x)⟩
            refine' ⟨hf.neg.ennreal_of_real, htμ.2, _⟩
            rw [to_jordan_decomposition_eq_of_eq_add_with_density hf hfi htμ' hadd] }

theorem have_lebesgue_decomposition_mk (μ : Measureₓ α) {f : α → ℝ} (hf : Measurable f)
  (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure) (hadd : s = t+μ.with_densityᵥ f) : s.have_lebesgue_decomposition μ :=
  by 
    byCases' hfi : integrable f μ
    ·
      exact have_lebesgue_decomposition_mk' μ hf hfi htμ hadd
    ·
      rw [with_densityᵥ, dif_neg hfi, add_zeroₓ] at hadd 
      refine' have_lebesgue_decomposition_mk' μ measurable_zero (integrable_zero _ _ μ) htμ _ 
      rwa [with_densityᵥ_zero, add_zeroₓ]

private theorem eq_singular_part' (t : signed_measure α) {f : α → ℝ} (hf : Measurable f) (hfi : integrable f μ)
  (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure) (hadd : s = t+μ.with_densityᵥ f) : t = s.singular_part μ :=
  by 
    have htμ' := htμ 
    rw [mutually_singular_ennreal_iff, total_variation_mutually_singular_iff] at htμ 
    change
      _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ) ∧
        _ ⊥ₘ vector_measure.equiv_measure.to_fun (vector_measure.equiv_measure.inv_fun μ) at
      htμ 
    rw [vector_measure.equiv_measure.right_inv] at htμ
    ·
      rw [singular_part, ←t.to_signed_measure_to_jordan_decomposition, jordan_decomposition.to_signed_measure]
      congr
      ·
        have hfpos : Measurable fun x => Ennreal.ofReal (f x)
        ·
          measurability 
        refine' eq_singular_part hfpos htμ.1 _ 
        rw [to_jordan_decomposition_eq_of_eq_add_with_density hf hfi htμ' hadd]
      ·
        have hfneg : Measurable fun x => Ennreal.ofReal (-f x)
        ·
          measurability 
        refine' eq_singular_part hfneg htμ.2 _ 
        rw [to_jordan_decomposition_eq_of_eq_add_with_density hf hfi htμ' hadd]

/-- Given a measure `μ`, signed measures `s` and `t`, and a function `f` such that `t` is
mutually singular with respect to `μ` and `s = t + μ.with_densityᵥ f`, we have
`t = singular_part s μ`, i.e. `t` is the singular part of the Lebesgue decomposition between
`s` and `μ`. -/
theorem eq_singular_part (t : signed_measure α) (f : α → ℝ) (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure)
  (hadd : s = t+μ.with_densityᵥ f) : t = s.singular_part μ :=
  by 
    byCases' hfi : integrable f μ
    ·
      refine' eq_singular_part' t hfi.1.measurable_mk (hfi.congr hfi.1.ae_eq_mk) htμ _ 
      convert hadd using 2 
      exact with_densityᵥ_eq.congr_ae hfi.1.ae_eq_mk.symm
    ·
      rw [with_densityᵥ, dif_neg hfi, add_zeroₓ] at hadd 
      refine' eq_singular_part' t measurable_zero (integrable_zero _ _ μ) htμ _ 
      rwa [with_densityᵥ_zero, add_zeroₓ]

theorem singular_part_zero (μ : Measureₓ α) : (0 : signed_measure α).singularPart μ = 0 :=
  by 
    refine' (eq_singular_part 0 0 vector_measure.mutually_singular.zero_left _).symm 
    rw [zero_addₓ, with_densityᵥ_zero]

theorem singular_part_neg (s : signed_measure α) (μ : Measureₓ α) : (-s).singularPart μ = -s.singular_part μ :=
  by 
    have h₁ :
      ((-s).toJordanDecomposition.posPart.singularPart μ).toSignedMeasure =
        (s.to_jordan_decomposition.neg_part.singular_part μ).toSignedMeasure
    ·
      refine' to_signed_measure_congr _ 
      rw [to_jordan_decomposition_neg, jordan_decomposition.neg_pos_part]
    have h₂ :
      ((-s).toJordanDecomposition.negPart.singularPart μ).toSignedMeasure =
        (s.to_jordan_decomposition.pos_part.singular_part μ).toSignedMeasure
    ·
      refine' to_signed_measure_congr _ 
      rw [to_jordan_decomposition_neg, jordan_decomposition.neg_neg_part]
    rw [singular_part, singular_part, neg_sub, h₁, h₂]

theorem singular_part_smul_nnreal (s : signed_measure α) (μ : Measureₓ α) (r :  ℝ≥0 ) :
  (r • s).singularPart μ = r • s.singular_part μ :=
  by 
    rw [singular_part, singular_part, smul_sub, ←to_signed_measure_smul, ←to_signed_measure_smul]
    convLHS =>
      congr
        congr
        rw [to_jordan_decomposition_smul, jordan_decomposition.smul_pos_part,
        singular_part_smul]skip
        congr rw [to_jordan_decomposition_smul, jordan_decomposition.smul_neg_part, singular_part_smul]

theorem singular_part_smul (s : signed_measure α) (μ : Measureₓ α) (r : ℝ) :
  (r • s).singularPart μ = r • s.singular_part μ :=
  by 
    byCases' hr : 0 ≤ r
    ·
      lift r to  ℝ≥0  using hr 
      exact singular_part_smul_nnreal s μ r
    ·
      rw [singular_part, singular_part]
      convLHS =>
        congr
          congr
          rw [to_jordan_decomposition_smul_real, jordan_decomposition.real_smul_pos_part_neg _ _ (not_leₓ.1 hr),
          singular_part_smul]skip
          congr
          rw [to_jordan_decomposition_smul_real, jordan_decomposition.real_smul_neg_part_neg _ _ (not_leₓ.1 hr),
          singular_part_smul]
      rw [to_signed_measure_smul, to_signed_measure_smul, ←neg_sub, ←smul_sub]
      change -(((-r).toNnreal : ℝ) • _) = _ 
      rw [←neg_smul, Real.coe_to_nnreal _ (le_of_ltₓ (neg_pos.mpr (not_leₓ.1 hr))), neg_negₓ]

theorem singular_part_add (s t : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  [t.have_lebesgue_decomposition μ] : (s+t).singularPart μ = s.singular_part μ+t.singular_part μ :=
  by 
    refine'
      (eq_singular_part _ (s.rn_deriv μ+t.rn_deriv μ)
          ((mutually_singular_singular_part s μ).add_left (mutually_singular_singular_part t μ)) _).symm
        
    erw [with_densityᵥ_add (integrable_rn_deriv s μ) (integrable_rn_deriv t μ)]
    rw [add_assocₓ, add_commₓ (t.singular_part μ), add_assocₓ, add_commₓ _ (t.singular_part μ),
      singular_part_add_with_density_rn_deriv_eq, ←add_assocₓ, singular_part_add_with_density_rn_deriv_eq]

theorem singular_part_sub (s t : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  [t.have_lebesgue_decomposition μ] : (s - t).singularPart μ = s.singular_part μ - t.singular_part μ :=
  by 
    rw [sub_eq_add_neg, sub_eq_add_neg, singular_part_add, singular_part_neg]

/-- Given a measure `μ`, signed measures `s` and `t`, and a function `f` such that `t` is
mutually singular with respect to `μ` and `s = t + μ.with_densityᵥ f`, we have
`f = rn_deriv s μ`, i.e. `f` is the Radon-Nikodym derivative of `s` and `μ`. -/
theorem eq_rn_deriv (t : signed_measure α) (f : α → ℝ) (hfi : integrable f μ) (htμ : t ⊥ᵥ μ.to_ennreal_vector_measure)
  (hadd : s = t+μ.with_densityᵥ f) : f =ᵐ[μ] s.rn_deriv μ :=
  by 
    set f' := hfi.1.mk f 
    have hadd' : s = t+μ.with_densityᵥ f'
    ·
      convert hadd using 2 
      exact with_densityᵥ_eq.congr_ae hfi.1.ae_eq_mk.symm 
    have  := have_lebesgue_decomposition_mk μ hfi.1.measurable_mk htμ hadd' 
    refine' (integrable.ae_eq_of_with_densityᵥ_eq (integrable_rn_deriv _ _) hfi _).symm 
    rw [←add_right_injₓ t, ←hadd, eq_singular_part _ f htμ hadd, singular_part_add_with_density_rn_deriv_eq]

theorem rn_deriv_neg (s : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ] :
  (-s).rnDeriv μ =ᵐ[μ] -s.rn_deriv μ :=
  by 
    refine' integrable.ae_eq_of_with_densityᵥ_eq (integrable_rn_deriv _ _) (integrable_rn_deriv _ _).neg _ 
    rw [with_densityᵥ_neg, ←add_right_injₓ ((-s).singularPart μ), singular_part_add_with_density_rn_deriv_eq,
      singular_part_neg, ←neg_add, singular_part_add_with_density_rn_deriv_eq]

theorem rn_deriv_smul (s : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ] (r : ℝ) :
  (r • s).rnDeriv μ =ᵐ[μ] r • s.rn_deriv μ :=
  by 
    refine' integrable.ae_eq_of_with_densityᵥ_eq (integrable_rn_deriv _ _) ((integrable_rn_deriv _ _).smul r) _ 
    change _ = μ.with_densityᵥ ((r : ℝ) • s.rn_deriv μ)
    rw [with_densityᵥ_smul (rn_deriv s μ) (r : ℝ), ←add_right_injₓ ((r • s).singularPart μ),
      singular_part_add_with_density_rn_deriv_eq, singular_part_smul]
    change _ = _+r • _ 
    rw [←smul_add, singular_part_add_with_density_rn_deriv_eq]

theorem rn_deriv_add (s t : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  [t.have_lebesgue_decomposition μ] [(s+t).HaveLebesgueDecomposition μ] :
  (s+t).rnDeriv μ =ᵐ[μ] s.rn_deriv μ+t.rn_deriv μ :=
  by 
    refine'
      integrable.ae_eq_of_with_densityᵥ_eq (integrable_rn_deriv _ _)
        ((integrable_rn_deriv _ _).add (integrable_rn_deriv _ _)) _ 
    rw [←add_right_injₓ ((s+t).singularPart μ), singular_part_add_with_density_rn_deriv_eq,
      with_densityᵥ_add (integrable_rn_deriv _ _) (integrable_rn_deriv _ _), singular_part_add, add_assocₓ,
      add_commₓ (t.singular_part μ), add_assocₓ, add_commₓ _ (t.singular_part μ),
      singular_part_add_with_density_rn_deriv_eq, ←add_assocₓ, singular_part_add_with_density_rn_deriv_eq]

theorem rn_deriv_sub (s t : signed_measure α) (μ : Measureₓ α) [s.have_lebesgue_decomposition μ]
  [t.have_lebesgue_decomposition μ] [hst : (s - t).HaveLebesgueDecomposition μ] :
  (s - t).rnDeriv μ =ᵐ[μ] s.rn_deriv μ - t.rn_deriv μ :=
  by 
    rw [sub_eq_add_neg] at hst 
    rw [sub_eq_add_neg, sub_eq_add_neg]
    exact ae_eq_trans (rn_deriv_add _ _ _) (Filter.EventuallyEq.add (ae_eq_refl _) (rn_deriv_neg _ _))

end SignedMeasure

namespace ComplexMeasure

/-- A complex measure is said to `have_lebesgue_decomposition` with respect to a positive measure
if both its real and imaginary part `have_lebesgue_decomposition` with respect to that measure. -/
class have_lebesgue_decomposition (c : complex_measure α) (μ : Measureₓ α) : Prop where 
  re_part : c.re.have_lebesgue_decomposition μ 
  im_part : c.im.have_lebesgue_decomposition μ

attribute [instance] have_lebesgue_decomposition.re_part

attribute [instance] have_lebesgue_decomposition.im_part

/-- The singular part between a complex measure `c` and a positive measure `μ` is the complex
measure satisfying `c.singular_part μ + μ.with_densityᵥ (c.rn_deriv μ) = c`. This property is given
by `measure_theory.complex_measure.singular_part_add_with_density_rn_deriv_eq`. -/
def singular_part (c : complex_measure α) (μ : Measureₓ α) : complex_measure α :=
  (c.re.singular_part μ).toComplexMeasure (c.im.singular_part μ)

/-- The Radon-Nikodym derivative between a complex measure and a positive measure. -/
def rn_deriv (c : complex_measure α) (μ : Measureₓ α) : α → ℂ :=
  fun x => ⟨c.re.rn_deriv μ x, c.im.rn_deriv μ x⟩

variable {c : complex_measure α}

theorem integrable_rn_deriv (c : complex_measure α) (μ : Measureₓ α) : integrable (c.rn_deriv μ) μ :=
  by 
    rw [←mem_ℒp_one_iff_integrable, ←mem_ℒp_re_im_iff]
    exact
      ⟨mem_ℒp_one_iff_integrable.2 (signed_measure.integrable_rn_deriv _ _),
        mem_ℒp_one_iff_integrable.2 (signed_measure.integrable_rn_deriv _ _)⟩

theorem singular_part_add_with_density_rn_deriv_eq [c.have_lebesgue_decomposition μ] :
  (c.singular_part μ+μ.with_densityᵥ (c.rn_deriv μ)) = c :=
  by 
    convRHS => rw [←c.to_complex_measure_to_signed_measure]
    ext i hi
    ·
      rw [vector_measure.add_apply, signed_measure.to_complex_measure_apply, Complex.add_re, re_apply,
        with_densityᵥ_apply (c.integrable_rn_deriv μ) hi,
        ←set_integral_re_add_im (c.integrable_rn_deriv μ).IntegrableOn]
      suffices  : ((c.singular_part μ i).re+∫ x in i, (c.rn_deriv μ x).re ∂μ) = (c i).re
      ·
        simpa 
      rw [←with_densityᵥ_apply _ hi]
      ·
        change (c.re.singular_part μ+μ.with_densityᵥ (c.re.rn_deriv μ)) i = _ 
        rw [@signed_measure.singular_part_add_with_density_rn_deriv_eq _ _ μ c.re _]
        rfl
      ·
        exact signed_measure.integrable_rn_deriv _ _
    ·
      rw [vector_measure.add_apply, signed_measure.to_complex_measure_apply, Complex.add_im, im_apply,
        with_densityᵥ_apply (c.integrable_rn_deriv μ) hi,
        ←set_integral_re_add_im (c.integrable_rn_deriv μ).IntegrableOn]
      suffices  : ((c.singular_part μ i).im+∫ x in i, (c.rn_deriv μ x).im ∂μ) = (c i).im
      ·
        simpa 
      rw [←with_densityᵥ_apply _ hi]
      ·
        change (c.im.singular_part μ+μ.with_densityᵥ (c.im.rn_deriv μ)) i = _ 
        rw [@signed_measure.singular_part_add_with_density_rn_deriv_eq _ _ μ c.im _]
        rfl
      ·
        exact signed_measure.integrable_rn_deriv _ _

end ComplexMeasure

end MeasureTheory

