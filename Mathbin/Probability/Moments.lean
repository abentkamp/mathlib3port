/-
Copyright (c) 2022 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Mathbin.Probability.Variance

/-!
# Moments and moment generating function

## Main definitions

* `probability_theory.moment X p μ`: `p`th moment of a real random variable `X` with respect to
  measure `μ`, `μ[X^p]`
* `probability_theory.central_moment X p μ`:`p`th central moment of `X` with respect to measure `μ`,
  `μ[(X - μ[X])^p]`
* `probability_theory.mgf X μ t`: moment generating function of `X` with respect to measure `μ`,
  `μ[exp(t*X)]`
* `probability_theory.cgf X μ t`: cumulant generating function, logarithm of the moment generating
  function

## Main results

* `probability_theory.indep_fun.mgf_add`: if two real random variables `X` and `Y` are independent
  and their mgf are defined at `t`, then `mgf (X + Y) μ t = mgf X μ t * mgf Y μ t`
* `probability_theory.indep_fun.cgf_add`: if two real random variables `X` and `Y` are independent
  and their mgf are defined at `t`, then `cgf (X + Y) μ t = cgf X μ t + cgf Y μ t`
* `probability_theory.measure_ge_le_exp_cgf` and `probability_theory.measure_le_le_exp_cgf`:
  Chernoff bound on the upper (resp. lower) tail of a random variable. For `t` nonnegative such that
  the cgf exists, `ℙ(ε ≤ X) ≤ exp(- t*ε + cgf X ℙ t)`. See also
  `probability_theory.measure_ge_le_exp_mul_mgf` and
  `probability_theory.measure_le_le_exp_mul_mgf` for versions of these results using `mgf` instead
  of `cgf`.

-/


open MeasureTheory Filter Finset Real

noncomputable section

open BigOperators MeasureTheory ProbabilityTheory Ennreal Nnreal

namespace ProbabilityTheory

variable {Ω ι : Type _} {m : MeasurableSpace Ω} {X : Ω → ℝ} {p : ℕ} {μ : Measureₓ Ω}

include m

/-- Moment of a real random variable, `μ[X ^ p]`. -/
def moment (X : Ω → ℝ) (p : ℕ) (μ : Measureₓ Ω) : ℝ :=
  μ[X ^ p]

/-- Central moment of a real random variable, `μ[(X - μ[X]) ^ p]`. -/
def centralMoment (X : Ω → ℝ) (p : ℕ) (μ : Measureₓ Ω) : ℝ :=
  μ[(X - fun x => μ[X]) ^ p]

@[simp]
theorem moment_zero (hp : p ≠ 0) : moment 0 p μ = 0 := by
  simp only [moment, hp, zero_pow', Ne.def, not_false_iff, Pi.zero_apply, integral_const, Algebra.id.smul_eq_mul,
    mul_zero]

@[simp]
theorem central_moment_zero (hp : p ≠ 0) : centralMoment 0 p μ = 0 := by
  simp only [central_moment, hp, Pi.zero_apply, integral_const, Algebra.id.smul_eq_mul, mul_zero, zero_sub,
    Pi.pow_apply, Pi.neg_apply, neg_zero', zero_pow', Ne.def, not_false_iff]

theorem central_moment_one' [IsFiniteMeasure μ] (h_int : Integrable X μ) :
    centralMoment X 1 μ = (1 - (μ Set.Univ).toReal) * μ[X] := by
  simp only [central_moment, Pi.sub_apply, pow_oneₓ]
  rw [integral_sub h_int (integrable_const _)]
  simp only [sub_mul, integral_const, Algebra.id.smul_eq_mul, one_mulₓ]

@[simp]
theorem central_moment_one [IsProbabilityMeasure μ] : centralMoment X 1 μ = 0 := by
  by_cases' h_int : integrable X μ
  · rw [central_moment_one' h_int]
    simp only [measure_univ, Ennreal.one_to_real, sub_self, zero_mul]
    
  · simp only [central_moment, Pi.sub_apply, pow_oneₓ]
    have : ¬integrable (fun x => X x - integral μ X) μ := by
      refine' fun h_sub => h_int _
      have h_add : X = (fun x => X x - integral μ X) + fun x => integral μ X := by
        ext1 x
        simp
      rw [h_add]
      exact h_sub.add (integrable_const _)
    rw [integral_undef this]
    

@[simp]
theorem central_moment_two_eq_variance : centralMoment X 2 μ = variance X μ :=
  rfl

section MomentGeneratingFunction

variable {t : ℝ}

/-- Moment generating function of a real random variable `X`: `λ t, μ[exp(t*X)]`. -/
def mgf (X : Ω → ℝ) (μ : Measureₓ Ω) (t : ℝ) : ℝ :=
  μ[fun ω => exp (t * X ω)]

/-- Cumulant generating function of a real random variable `X`: `λ t, log μ[exp(t*X)]`. -/
def cgf (X : Ω → ℝ) (μ : Measureₓ Ω) (t : ℝ) : ℝ :=
  log (mgf X μ t)

@[simp]
theorem mgf_zero_fun : mgf 0 μ t = (μ Set.Univ).toReal := by
  simp only [mgf, Pi.zero_apply, mul_zero, exp_zero, integral_const, Algebra.id.smul_eq_mul, mul_oneₓ]

@[simp]
theorem cgf_zero_fun : cgf 0 μ t = log (μ Set.Univ).toReal := by
  simp only [cgf, mgf_zero_fun]

@[simp]
theorem mgf_zero_measure : mgf X (0 : Measureₓ Ω) t = 0 := by
  simp only [mgf, integral_zero_measure]

@[simp]
theorem cgf_zero_measure : cgf X (0 : Measureₓ Ω) t = 0 := by
  simp only [cgf, log_zero, mgf_zero_measure]

@[simp]
theorem mgf_const' (c : ℝ) : mgf (fun _ => c) μ t = (μ Set.Univ).toReal * exp (t * c) := by
  simp only [mgf, integral_const, Algebra.id.smul_eq_mul]

@[simp]
theorem mgf_const (c : ℝ) [IsProbabilityMeasure μ] : mgf (fun _ => c) μ t = exp (t * c) := by
  simp only [mgf_const', measure_univ, Ennreal.one_to_real, one_mulₓ]

@[simp]
theorem cgf_const' [IsFiniteMeasure μ] (hμ : μ ≠ 0) (c : ℝ) : cgf (fun _ => c) μ t = log (μ Set.Univ).toReal + t * c :=
  by
  simp only [cgf, mgf_const']
  rw [log_mul _ (exp_pos _).ne']
  · rw [log_exp _]
    
  · rw [Ne.def, Ennreal.to_real_eq_zero_iff, measure.measure_univ_eq_zero]
    simp only [hμ, measure_ne_top μ Set.Univ, or_selfₓ, not_false_iff]
    

@[simp]
theorem cgf_const [IsProbabilityMeasure μ] (c : ℝ) : cgf (fun _ => c) μ t = t * c := by
  simp only [cgf, mgf_const, log_exp]

@[simp]
theorem mgf_zero' : mgf X μ 0 = (μ Set.Univ).toReal := by
  simp only [mgf, zero_mul, exp_zero, integral_const, Algebra.id.smul_eq_mul, mul_oneₓ]

@[simp]
theorem mgf_zero [IsProbabilityMeasure μ] : mgf X μ 0 = 1 := by
  simp only [mgf_zero', measure_univ, Ennreal.one_to_real]

@[simp]
theorem cgf_zero' : cgf X μ 0 = log (μ Set.Univ).toReal := by
  simp only [cgf, mgf_zero']

@[simp]
theorem cgf_zero [IsProbabilityMeasure μ] : cgf X μ 0 = 0 := by
  simp only [cgf_zero', measure_univ, Ennreal.one_to_real, log_one]

theorem mgf_undef (hX : ¬Integrable (fun ω => exp (t * X ω)) μ) : mgf X μ t = 0 := by
  simp only [mgf, integral_undef hX]

theorem cgf_undef (hX : ¬Integrable (fun ω => exp (t * X ω)) μ) : cgf X μ t = 0 := by
  simp only [cgf, mgf_undef hX, log_zero]

theorem mgf_nonneg : 0 ≤ mgf X μ t := by
  refine' integral_nonneg _
  intro ω
  simp only [Pi.zero_apply]
  exact (exp_pos _).le

theorem mgf_pos' (hμ : μ ≠ 0) (h_int_X : Integrable (fun ω => exp (t * X ω)) μ) : 0 < mgf X μ t := by
  simp_rw [mgf]
  have : (∫ x : Ω, exp (t * X x) ∂μ) = ∫ x : Ω in Set.Univ, exp (t * X x) ∂μ := by
    simp only [measure.restrict_univ]
  rw [this, set_integral_pos_iff_support_of_nonneg_ae _ _]
  · have h_eq_univ : (Function.Support fun x : Ω => exp (t * X x)) = Set.Univ := by
      ext1 x
      simp only [Function.mem_support, Set.mem_univ, iff_trueₓ]
      exact (exp_pos _).ne'
    rw [h_eq_univ, Set.inter_univ _]
    refine' Ne.bot_lt _
    simp only [hμ, Ennreal.bot_eq_zero, Ne.def, measure.measure_univ_eq_zero, not_false_iff]
    
  · refine' eventually_of_forall fun x => _
    rw [Pi.zero_apply]
    exact (exp_pos _).le
    
  · rwa [integrable_on_univ]
    

theorem mgf_pos [IsProbabilityMeasure μ] (h_int_X : Integrable (fun ω => exp (t * X ω)) μ) : 0 < mgf X μ t :=
  mgf_pos' (IsProbabilityMeasure.ne_zero μ) h_int_X

theorem mgf_neg : mgf (-X) μ t = mgf X μ (-t) := by
  simp_rw [mgf, Pi.neg_apply, mul_neg, neg_mul]

theorem cgf_neg : cgf (-X) μ t = cgf X μ (-t) := by
  simp_rw [cgf, mgf_neg]

/-- This is a trivial application of `indep_fun.comp` but it will come up frequently. -/
theorem IndepFunₓ.exp_mul {X Y : Ω → ℝ} (h_indep : IndepFunₓ X Y μ) (s t : ℝ) :
    IndepFunₓ (fun ω => exp (s * X ω)) (fun ω => exp (t * Y ω)) μ := by
  have h_meas : ∀ t, Measurable fun x => exp (t * x) := fun t => (measurable_id'.const_mul t).exp
  change indep_fun ((fun x => exp (s * x)) ∘ X) ((fun x => exp (t * x)) ∘ Y) μ
  exact indep_fun.comp h_indep (h_meas s) (h_meas t)

theorem IndepFunₓ.mgf_add {X Y : Ω → ℝ} (h_indep : IndepFunₓ X Y μ)
    (hX : AeStronglyMeasurable (fun ω => exp (t * X ω)) μ) (hY : AeStronglyMeasurable (fun ω => exp (t * Y ω)) μ) :
    mgf (X + Y) μ t = mgf X μ t * mgf Y μ t := by
  simp_rw [mgf, Pi.add_apply, mul_addₓ, exp_add]
  exact (h_indep.exp_mul t t).integral_mul hX hY

theorem IndepFunₓ.mgf_add' {X Y : Ω → ℝ} (h_indep : IndepFunₓ X Y μ) (hX : AeStronglyMeasurable X μ)
    (hY : AeStronglyMeasurable Y μ) : mgf (X + Y) μ t = mgf X μ t * mgf Y μ t := by
  have A : Continuous fun x : ℝ => exp (t * x) := by
    continuity
  have h'X : ae_strongly_measurable (fun ω => exp (t * X ω)) μ :=
    A.ae_strongly_measurable.comp_ae_measurable hX.ae_measurable
  have h'Y : ae_strongly_measurable (fun ω => exp (t * Y ω)) μ :=
    A.ae_strongly_measurable.comp_ae_measurable hY.ae_measurable
  exact h_indep.mgf_add h'X h'Y

theorem IndepFunₓ.cgf_add {X Y : Ω → ℝ} (h_indep : IndepFunₓ X Y μ) (h_int_X : Integrable (fun ω => exp (t * X ω)) μ)
    (h_int_Y : Integrable (fun ω => exp (t * Y ω)) μ) : cgf (X + Y) μ t = cgf X μ t + cgf Y μ t := by
  by_cases' hμ : μ = 0
  · simp [hμ]
    
  simp only [cgf, h_indep.mgf_add h_int_X.ae_strongly_measurable h_int_Y.ae_strongly_measurable]
  exact log_mul (mgf_pos' hμ h_int_X).ne' (mgf_pos' hμ h_int_Y).ne'

theorem ae_strongly_measurable_exp_mul_add {X Y : Ω → ℝ} (h_int_X : AeStronglyMeasurable (fun ω => exp (t * X ω)) μ)
    (h_int_Y : AeStronglyMeasurable (fun ω => exp (t * Y ω)) μ) :
    AeStronglyMeasurable (fun ω => exp (t * (X + Y) ω)) μ := by
  simp_rw [Pi.add_apply, mul_addₓ, exp_add]
  exact ae_strongly_measurable.mul h_int_X h_int_Y

theorem ae_strongly_measurable_exp_mul_sum {X : ι → Ω → ℝ} {s : Finset ι}
    (h_int : ∀ i ∈ s, AeStronglyMeasurable (fun ω => exp (t * X i ω)) μ) :
    AeStronglyMeasurable (fun ω => exp (t * (∑ i in s, X i) ω)) μ := by
  classical
  induction' s using Finset.induction_on with i s hi_notin_s h_rec h_int
  · simp only [Pi.zero_apply, sum_apply, sum_empty, mul_zero, exp_zero]
    exact ae_strongly_measurable_const
    
  · have : ∀ i : ι, i ∈ s → ae_strongly_measurable (fun ω : Ω => exp (t * X i ω)) μ := fun i hi =>
      h_int i (mem_insert_of_mem hi)
    specialize h_rec this
    rw [sum_insert hi_notin_s]
    apply ae_strongly_measurable_exp_mul_add (h_int i (mem_insert_self _ _)) h_rec
    

theorem IndepFunₓ.integrable_exp_mul_add {X Y : Ω → ℝ} (h_indep : IndepFunₓ X Y μ)
    (h_int_X : Integrable (fun ω => exp (t * X ω)) μ) (h_int_Y : Integrable (fun ω => exp (t * Y ω)) μ) :
    Integrable (fun ω => exp (t * (X + Y) ω)) μ := by
  simp_rw [Pi.add_apply, mul_addₓ, exp_add]
  exact (h_indep.exp_mul t t).integrable_mul h_int_X h_int_Y

theorem IndepFun.integrable_exp_mul_sum [IsProbabilityMeasure μ] {X : ι → Ω → ℝ}
    (h_indep : IndepFun (fun i => inferInstance) X μ) (h_meas : ∀ i, Measurable (X i)) {s : Finset ι}
    (h_int : ∀ i ∈ s, Integrable (fun ω => exp (t * X i ω)) μ) : Integrable (fun ω => exp (t * (∑ i in s, X i) ω)) μ :=
  by
  classical
  induction' s using Finset.induction_on with i s hi_notin_s h_rec h_int
  · simp only [Pi.zero_apply, sum_apply, sum_empty, mul_zero, exp_zero]
    exact integrable_const _
    
  · have : ∀ i : ι, i ∈ s → integrable (fun ω : Ω => exp (t * X i ω)) μ := fun i hi => h_int i (mem_insert_of_mem hi)
    specialize h_rec this
    rw [sum_insert hi_notin_s]
    refine' indep_fun.integrable_exp_mul_add _ (h_int i (mem_insert_self _ _)) h_rec
    exact (h_indep.indep_fun_finset_sum_of_not_mem h_meas hi_notin_s).symm
    

theorem IndepFun.mgf_sum [IsProbabilityMeasure μ] {X : ι → Ω → ℝ} (h_indep : IndepFun (fun i => inferInstance) X μ)
    (h_meas : ∀ i, Measurable (X i)) (s : Finset ι) : mgf (∑ i in s, X i) μ t = ∏ i in s, mgf (X i) μ t := by
  classical
  induction' s using Finset.induction_on with i s hi_notin_s h_rec h_int
  · simp only [sum_empty, mgf_zero_fun, measure_univ, Ennreal.one_to_real, prod_empty]
    
  · have h_int' : ∀ i : ι, ae_strongly_measurable (fun ω : Ω => exp (t * X i ω)) μ := fun i =>
      ((h_meas i).const_mul t).exp.AeStronglyMeasurable
    rw [sum_insert hi_notin_s,
      indep_fun.mgf_add (h_indep.indep_fun_finset_sum_of_not_mem h_meas hi_notin_s).symm (h_int' i)
        (ae_strongly_measurable_exp_mul_sum fun i hi => h_int' i),
      h_rec, prod_insert hi_notin_s]
    

theorem IndepFun.cgf_sum [IsProbabilityMeasure μ] {X : ι → Ω → ℝ} (h_indep : IndepFun (fun i => inferInstance) X μ)
    (h_meas : ∀ i, Measurable (X i)) {s : Finset ι} (h_int : ∀ i ∈ s, Integrable (fun ω => exp (t * X i ω)) μ) :
    cgf (∑ i in s, X i) μ t = ∑ i in s, cgf (X i) μ t := by
  simp_rw [cgf]
  rw [← log_prod _ _ fun j hj => _]
  · rw [h_indep.mgf_sum h_meas]
    
  · exact (mgf_pos (h_int j hj)).ne'
    

/-- **Chernoff bound** on the upper tail of a real random variable. -/
theorem measure_ge_le_exp_mul_mgf [IsFiniteMeasure μ] (ε : ℝ) (ht : 0 ≤ t)
    (h_int : Integrable (fun ω => exp (t * X ω)) μ) : (μ { ω | ε ≤ X ω }).toReal ≤ exp (-t * ε) * mgf X μ t := by
  cases' ht.eq_or_lt with ht_zero_eq ht_pos
  · rw [ht_zero_eq.symm]
    simp only [neg_zero', zero_mul, exp_zero, mgf_zero', one_mulₓ]
    rw [Ennreal.to_real_le_to_real (measure_ne_top μ _) (measure_ne_top μ _)]
    exact measure_mono (Set.subset_univ _)
    
  calc
    (μ { ω | ε ≤ X ω }).toReal = (μ { ω | exp (t * ε) ≤ exp (t * X ω) }).toReal := by
      congr with ω
      simp only [exp_le_exp, eq_iff_iff]
      exact ⟨fun h => mul_le_mul_of_nonneg_left h ht_pos.le, fun h => le_of_mul_le_mul_left h ht_pos⟩
    _ ≤ (exp (t * ε))⁻¹ * μ[fun ω => exp (t * X ω)] := by
      have : exp (t * ε) * (μ { ω | exp (t * ε) ≤ exp (t * X ω) }).toReal ≤ μ[fun ω => exp (t * X ω)] :=
        mul_meas_ge_le_integral_of_nonneg (fun x => (exp_pos _).le) h_int _
      rwa [mul_comm (exp (t * ε))⁻¹, ← div_eq_mul_inv, le_div_iff' (exp_pos _)]
    _ = exp (-t * ε) * mgf X μ t := by
      rw [neg_mul, exp_neg]
      rfl
    

/-- **Chernoff bound** on the lower tail of a real random variable. -/
theorem measure_le_le_exp_mul_mgf [IsFiniteMeasure μ] (ε : ℝ) (ht : t ≤ 0)
    (h_int : Integrable (fun ω => exp (t * X ω)) μ) : (μ { ω | X ω ≤ ε }).toReal ≤ exp (-t * ε) * mgf X μ t := by
  rw [← neg_negₓ t, ← mgf_neg, neg_negₓ, ← neg_mul_neg (-t)]
  refine' Eq.trans_leₓ _ (measure_ge_le_exp_mul_mgf (-ε) (neg_nonneg.mpr ht) _)
  · congr with ω
    simp only [Pi.neg_apply, neg_le_neg_iff]
    
  · simp_rw [Pi.neg_apply, neg_mul_neg]
    exact h_int
    

/-- **Chernoff bound** on the upper tail of a real random variable. -/
theorem measure_ge_le_exp_cgf [IsFiniteMeasure μ] (ε : ℝ) (ht : 0 ≤ t) (h_int : Integrable (fun ω => exp (t * X ω)) μ) :
    (μ { ω | ε ≤ X ω }).toReal ≤ exp (-t * ε + cgf X μ t) := by
  refine' (measure_ge_le_exp_mul_mgf ε ht h_int).trans _
  rw [exp_add]
  exact mul_le_mul le_rflₓ (le_exp_log _) mgf_nonneg (exp_pos _).le

/-- **Chernoff bound** on the lower tail of a real random variable. -/
theorem measure_le_le_exp_cgf [IsFiniteMeasure μ] (ε : ℝ) (ht : t ≤ 0) (h_int : Integrable (fun ω => exp (t * X ω)) μ) :
    (μ { ω | X ω ≤ ε }).toReal ≤ exp (-t * ε + cgf X μ t) := by
  refine' (measure_le_le_exp_mul_mgf ε ht h_int).trans _
  rw [exp_add]
  exact mul_le_mul le_rflₓ (le_exp_log _) mgf_nonneg (exp_pos _).le

end MomentGeneratingFunction

end ProbabilityTheory

