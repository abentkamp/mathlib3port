import Mathbin.Analysis.NormedSpace.Dual 
import Mathbin.MeasureTheory.Function.StronglyMeasurable 
import Mathbin.MeasureTheory.Integral.SetIntegral

/-! # From equality of integrals to equality of functions

This file provides various statements of the general form "if two functions have the same integral
on all sets, then they are equal almost everywhere".
The different lemmas use various hypotheses on the class of functions, on the target space or on the
possible finiteness of the measure.

## Main statements

All results listed below apply to two functions `f, g`, together with two main hypotheses,
* `f` and `g` are integrable on all measurable sets with finite measure,
* for all measurable sets `s` with finite measure, `∫ x in s, f x ∂μ = ∫ x in s, g x ∂μ`.
The conclusion is then `f =ᵐ[μ] g`. The main lemmas are:
* `ae_eq_of_forall_set_integral_eq_of_sigma_finite`: case of a sigma-finite measure.
* `ae_fin_strongly_measurable.ae_eq_of_forall_set_integral_eq`: for functions which are
  `ae_fin_strongly_measurable`.
* `Lp.ae_eq_of_forall_set_integral_eq`: for elements of `Lp`, for `0 < p < ∞`.
* `integrable.ae_eq_of_forall_set_integral_eq`: for integrable functions.

For each of these results, we also provide a lemma about the equality of one function and 0. For
example, `Lp.ae_eq_zero_of_forall_set_integral_eq_zero`.

We also register the corresponding lemma for integrals of `ℝ≥0∞`-valued functions, in
`ae_eq_of_forall_set_lintegral_eq_of_sigma_finite`.

Generally useful lemmas which are not related to integrals:
* `ae_eq_zero_of_forall_inner`: if for all constants `c`, `λ x, inner c (f x) =ᵐ[μ] 0` then
  `f =ᵐ[μ] 0`.
* `ae_eq_zero_of_forall_dual`: if for all constants `c` in the dual space, `λ x, c (f x) =ᵐ[μ] 0`
  then `f =ᵐ[μ] 0`.

-/


open MeasureTheory TopologicalSpace NormedSpace Filter

open_locale Ennreal Nnreal MeasureTheory

namespace MeasureTheory

section AeEqOfForall

variable {α E 𝕜 : Type _} {m : MeasurableSpace α} {μ : Measureₓ α} [IsROrC 𝕜]

theorem ae_eq_zero_of_forall_inner [InnerProductSpace 𝕜 E] [second_countable_topology E] {f : α → E}
  (hf : ∀ c : E, (fun x => (inner c (f x) : 𝕜)) =ᵐ[μ] 0) : f =ᵐ[μ] 0 :=
  by 
    let s := dense_seq E 
    have hs : DenseRange s := dense_range_dense_seq E 
    have hf' : ∀ᵐ x ∂μ, ∀ n : ℕ, inner (s n) (f x) = (0 : 𝕜)
    exact ae_all_iff.mpr fun n => hf (s n)
    refine' hf'.mono fun x hx => _ 
    rw [Pi.zero_apply, ←inner_self_eq_zero]
    have h_closed : IsClosed { c : E | inner c (f x) = (0 : 𝕜) }
    exact is_closed_eq (continuous_id.inner continuous_const) continuous_const 
    exact @is_closed_property ℕ E _ s (fun c => inner c (f x) = (0 : 𝕜)) hs h_closed (fun n => hx n) _

local notation "⟪" x ", " y "⟫" => y x

variable (𝕜)

theorem ae_eq_zero_of_forall_dual [NormedGroup E] [NormedSpace 𝕜 E] [second_countable_topology E] {f : α → E}
  (hf : ∀ c : dual 𝕜 E, (fun x => ⟪f x, c⟫) =ᵐ[μ] 0) : f =ᵐ[μ] 0 :=
  by 
    let u := dense_seq E 
    have hu : DenseRange u := dense_range_dense_seq _ 
    have  : ∀ n, ∃ g : E →L[𝕜] 𝕜, ∥g∥ ≤ 1 ∧ g (u n) = ∥u n∥ := fun n => exists_dual_vector'' 𝕜 (u n)
    choose s hs using this 
    have A : ∀ a : E, (∀ n, ⟪a, s n⟫ = (0 : 𝕜)) → a = 0
    ·
      intro a ha 
      contrapose! ha 
      have a_pos : 0 < ∥a∥
      ·
        simp only [ha, norm_pos_iff, Ne.def, not_false_iff]
      have a_mem : a ∈ Closure (Set.Range u)
      ·
        simp [hu.closure_range]
      obtain ⟨n, hn⟩ : ∃ n : ℕ, dist a (u n) < ∥a∥ / 2 :=
        Metric.mem_closure_range_iff.1 a_mem (∥a∥ / 2) (half_pos a_pos)
      use n 
      have I : ∥a∥ / 2 < ∥u n∥
      ·
        have  : ∥a∥ ≤ ∥u n∥+∥a - u n∥ := norm_le_insert' _ _ 
        have  : ∥a - u n∥ < ∥a∥ / 2
        ·
          rwa [dist_eq_norm] at hn 
        linarith 
      intro h 
      apply lt_irreflₓ ∥s n (u n)∥
      calc ∥s n (u n)∥ = ∥s n (u n - a)∥ :=
        by 
          simp only [h, sub_zero, ContinuousLinearMap.map_sub]_ ≤ 1*∥u n - a∥ :=
        ContinuousLinearMap.le_of_op_norm_le _ (hs n).1 _ _ < ∥a∥ / 2 :=
        by 
          rw [one_mulₓ]
          rwa [dist_eq_norm'] at hn _ < ∥u n∥ :=
        I _ = ∥s n (u n)∥ :=
        by 
          rw [(hs n).2, IsROrC.norm_coe_norm]
    have hfs : ∀ n : ℕ, ∀ᵐ x ∂μ, ⟪f x, s n⟫ = (0 : 𝕜)
    exact fun n => hf (s n)
    have hf' : ∀ᵐ x ∂μ, ∀ n : ℕ, ⟪f x, s n⟫ = (0 : 𝕜)
    ·
      rwa [ae_all_iff]
    exact hf'.mono fun x hx => A (f x) hx

variable {𝕜}

end AeEqOfForall

variable {α E : Type _} {m m0 : MeasurableSpace α} {μ : Measureₓ α} {s t : Set α} [NormedGroup E] [NormedSpace ℝ E]
  [MeasurableSpace E] [BorelSpace E] [second_countable_topology E] [CompleteSpace E] {p : ℝ≥0∞}

section AeEqOfForallSetIntegralEq

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (b «expr < » c)
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  ae_const_le_iff_forall_lt_measure_zero
  { β }
      [ LinearOrderₓ β ]
      [ TopologicalSpace β ]
      [ OrderTopology β ]
      [ first_countable_topology β ]
      ( f : α → β )
      ( c : β )
    : ∀ᵐ x ∂ μ , c ≤ f x ↔ ∀ b _ : b < c , μ { x | f x ≤ b } = 0
  :=
    by
      rw [ ae_iff ]
        pushNeg
        constructor
        · intro h b hb exact measure_mono_null fun y hy => ( lt_of_le_of_ltₓ hy hb : _ ) h
        intro hc
        byCases' h : ∀ b , c ≤ b
        ·
          have : { a : α | f a < c } = ∅
            · apply Set.eq_empty_iff_forall_not_mem . 2 fun x hx => _ exact lt_irreflₓ _ lt_of_lt_of_leₓ hx h f x . elim
            simp [ this ]
        byCases' H : ¬ IsLub Set.Iio c c
        ·
          have : c ∈ UpperBounds Set.Iio c := fun y hy => le_of_ltₓ hy
            obtain ⟨ b , b_up , bc ⟩ : ∃ b : β , b ∈ UpperBounds Set.Iio c ∧ b < c
            · simpa [ IsLub , IsLeast , this , LowerBounds ] using H
            exact measure_mono_null fun x hx => b_up hx hc b bc
        pushNeg at H h
        obtain
          ⟨ u , u_mono , u_lt , u_lim , - ⟩
          : ∃ u : ℕ → β , StrictMono u ∧ ∀ n : ℕ , u n < c ∧ tendsto u at_top nhds c ∧ ∀ n : ℕ , u n ∈ Set.Iio c
          := H.exists_seq_strict_mono_tendsto_of_not_mem lt_irreflₓ c h
        have h_Union : { x | f x < c } = ⋃ n : ℕ , { x | f x ≤ u n }
        ·
          ext1 x
            simpRw [ Set.mem_Union , Set.mem_set_of_eq ]
            constructor <;> intro h
            · obtain ⟨ n , hn ⟩ := tendsto_order . 1 u_lim . 1 _ h . exists exact ⟨ n , hn.le ⟩
            · obtain ⟨ n , hn ⟩ := h exact hn.trans_lt u_lt _
        rw [ h_Union , measure_Union_null_iff ]
        intro n
        exact hc _ u_lt n

section Ennreal

open_locale TopologicalSpace

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  ae_le_of_forall_set_lintegral_le_of_sigma_finite
  [ sigma_finite μ ]
      { f g : α → ℝ≥0∞ }
      ( hf : Measurable f )
      ( hg : Measurable g )
      ( h : ∀ s , MeasurableSet s → μ s < ∞ → ∫⁻ x in s , f x ∂ μ ≤ ∫⁻ x in s , g x ∂ μ )
    : f ≤ᵐ[ μ ] g
  :=
    by
      have A : ∀ ε N : ℝ≥0 p : ℕ , 0 < ε → μ { x | g x + ε ≤ f x ∧ g x ≤ N } ∩ spanning_sets μ p = 0
        ·
          intro ε N p εpos
            let s := { x | g x + ε ≤ f x ∧ g x ≤ N } ∩ spanning_sets μ p
            have s_meas : MeasurableSet s
            ·
              have A : MeasurableSet { x | g x + ε ≤ f x } := measurable_set_le hg.add measurable_const hf
                have B : MeasurableSet { x | g x ≤ N } := measurable_set_le hg measurable_const
                exact A.inter B . inter measurable_spanning_sets μ p
            have
              s_lt_top : μ s < ∞ := measure_mono Set.inter_subset_right _ _ . trans_lt measure_spanning_sets_lt_top μ p
            have
              A
                : ∫⁻ x in s , g x ∂ μ + ε * μ s ≤ ∫⁻ x in s , g x ∂ μ + 0
                :=
                calc
                  ∫⁻ x in s , g x ∂ μ + ε * μ s = ∫⁻ x in s , g x ∂ μ + ∫⁻ x in s , ε ∂ μ
                      :=
                      by simp only [ lintegral_const , Set.univ_inter , MeasurableSet.univ , measure.restrict_apply ]
                    _ = ∫⁻ x in s , g x + ε ∂ μ := lintegral_add hg measurable_const . symm
                    _ ≤ ∫⁻ x in s , f x ∂ μ := set_lintegral_mono hg.add measurable_const hf fun x hx => hx . 1 . 1
                    _ ≤ ∫⁻ x in s , g x ∂ μ + 0 := by rw [ add_zeroₓ ] exact h s s_meas s_lt_top
            have B : ∫⁻ x in s , g x ∂ μ ≠ ∞
            ·
              apply ne_of_ltₓ
                calc
                  ∫⁻ x in s , g x ∂ μ ≤ ∫⁻ x in s , N ∂ μ
                      :=
                      set_lintegral_mono hg measurable_const fun x hx => hx . 1 . 2
                    _ = N * μ s
                      :=
                      by simp only [ lintegral_const , Set.univ_inter , MeasurableSet.univ , measure.restrict_apply ]
                    _ < ∞
                      :=
                      by
                        simp
                          only
                          [
                            lt_top_iff_ne_top
                              ,
                              s_lt_top.ne
                              ,
                              and_falseₓ
                              ,
                              Ennreal.coe_ne_top
                              ,
                              WithTop.mul_eq_top_iff
                              ,
                              Ne.def
                              ,
                              not_false_iff
                              ,
                              false_andₓ
                              ,
                              or_selfₓ
                            ]
            have : ( ε : ℝ≥0∞ ) * μ s ≤ 0 := Ennreal.le_of_add_le_add_left B A
            simpa only [ Ennreal.coe_eq_zero , nonpos_iff_eq_zero , mul_eq_zero , εpos.ne' , false_orₓ ]
        obtain
          ⟨ u , u_mono , u_pos , u_lim ⟩
          : ∃ u : ℕ → ℝ≥0 , StrictAnti u ∧ ∀ n , 0 < u n ∧ tendsto u at_top nhds 0
          := exists_seq_strict_anti_tendsto ( 0 : ℝ≥0 )
        let s := fun n : ℕ => { x | g x + u n ≤ f x ∧ g x ≤ ( n : ℝ≥0 ) } ∩ spanning_sets μ n
        have μs : ∀ n , μ s n = 0 := fun n => A _ _ _ u_pos n
        have B : { x | f x ≤ g x } ᶜ ⊆ ⋃ n , s n
        ·
          intro x hx
            simp at hx
            have L1 : ∀ᶠ n in at_top , g x + u n ≤ f x
            ·
              have
                  : tendsto fun n => g x + u n at_top 𝓝 g x + ( 0 : ℝ≥0 )
                    :=
                    tendsto_const_nhds.add Ennreal.tendsto_coe . 2 u_lim
                simp at this
                exact eventually_le_of_tendsto_lt hx this
            have L2 : ∀ᶠ n : ℕ in ( at_top : Filter ℕ ) , g x ≤ ( n : ℝ≥0 )
            ·
              have : tendsto fun n : ℕ => ( ( n : ℝ≥0 ) : ℝ≥0∞ ) at_top 𝓝 ∞
                · simp only [ Ennreal.coe_nat ] exact Ennreal.tendsto_nat_nhds_top
                exact eventually_ge_of_tendsto_gt hx.trans_le le_top this
            apply Set.mem_Union . 2
            exact L1.and L2 . And eventually_mem_spanning_sets μ x . exists
        refine' le_antisymmₓ _ bot_le
        calc
          μ { x : α | fun x : α => f x ≤ g x x } ᶜ ≤ μ ⋃ n , s n := measure_mono B
            _ ≤ ∑' n , μ s n := measure_Union_le _
            _ = 0 := by simp only [ μs , tsum_zero ]

theorem ae_eq_of_forall_set_lintegral_eq_of_sigma_finite [sigma_finite μ] {f g : α → ℝ≥0∞} (hf : Measurable f)
  (hg : Measurable g) (h : ∀ s, MeasurableSet s → μ s < ∞ → (∫⁻ x in s, f x ∂μ) = ∫⁻ x in s, g x ∂μ) : f =ᵐ[μ] g :=
  by 
    have A : f ≤ᵐ[μ] g := ae_le_of_forall_set_lintegral_le_of_sigma_finite hf hg fun s hs h's => le_of_eqₓ (h s hs h's)
    have B : g ≤ᵐ[μ] f := ae_le_of_forall_set_lintegral_le_of_sigma_finite hg hf fun s hs h's => ge_of_eq (h s hs h's)
    filterUpwards [A, B]
    exact fun x => le_antisymmₓ

end Ennreal

section Real

section RealFiniteMeasure

variable [is_finite_measure μ] {f : α → ℝ}

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- Don't use this lemma. Use `ae_nonneg_of_forall_set_integral_nonneg_of_finite_measure`. -/
  theorem
    ae_nonneg_of_forall_set_integral_nonneg_of_finite_measure_of_measurable
    ( hfm : Measurable f ) ( hf : integrable f μ ) ( hf_zero : ∀ s , MeasurableSet s → 0 ≤ ∫ x in s , f x ∂ μ )
      : 0 ≤ᵐ[ μ ] f
    :=
      by
        simpRw [ eventually_le , Pi.zero_apply ]
          rw [ ae_const_le_iff_forall_lt_measure_zero ]
          intro b hb_neg
          let s := { x | f x ≤ b }
          have hs : MeasurableSet s
          exact measurable_set_le hfm measurable_const
          have h_int_gt : ∫ x in s , f x ∂ μ ≤ b * μ s . toReal
          ·
            have h_const_le : ∫ x in s , f x ∂ μ ≤ ∫ x in s , b ∂ μ
              ·
                refine'
                    set_integral_mono_ae_restrict hf.integrable_on integrable_on_const.mpr Or.inr measure_lt_top μ s _
                  rw [ eventually_le , ae_restrict_iff hs ]
                  exact eventually_of_forall fun x hxs => hxs
              rwa [ set_integral_const , smul_eq_mul , mul_commₓ ] at h_const_le
          byContra
          refine' lt_self_iff_false ∫ x in s , f x ∂ μ . mp h_int_gt.trans_lt _
          refine' mul_neg_iff.mpr Or.inr ⟨ hb_neg , _ ⟩ . trans_le _
          swap
          · simpRw [ measure.restrict_restrict hs ] exact hf_zero s hs
          refine' Ennreal.to_real_nonneg . lt_of_ne fun h_eq => h _
          cases' Ennreal.to_real_eq_zero_iff _ . mp h_eq.symm with hμs_eq_zero hμs_eq_top
          · exact hμs_eq_zero
          · exact absurd hμs_eq_top measure_lt_top μ s . Ne

theorem ae_nonneg_of_forall_set_integral_nonneg_of_finite_measure (hf : integrable f μ)
  (hf_zero : ∀ s, MeasurableSet s → 0 ≤ ∫ x in s, f x ∂μ) : 0 ≤ᵐ[μ] f :=
  by 
    rcases hf.1 with ⟨f', hf'_meas, hf_ae⟩
    have hf'_integrable : integrable f' μ 
    exact integrable.congr hf hf_ae 
    have hf'_zero : ∀ s, MeasurableSet s → 0 ≤ ∫ x in s, f' x ∂μ
    ·
      intro s hs 
      rw [set_integral_congr_ae hs (hf_ae.mono fun x hx hxs => hx.symm)]
      exact hf_zero s hs 
    exact
      (ae_nonneg_of_forall_set_integral_nonneg_of_finite_measure_of_measurable hf'_meas hf'_integrable hf'_zero).trans
        hf_ae.symm.le

end RealFiniteMeasure

theorem ae_nonneg_restrict_of_forall_set_integral_nonneg_inter {f : α → ℝ} {t : Set α} (hμt : μ t ≠ ∞)
  (hf : integrable_on f t μ) (hf_zero : ∀ s, MeasurableSet s → 0 ≤ ∫ x in s ∩ t, f x ∂μ) : 0 ≤ᵐ[μ.restrict t] f :=
  by 
    have  : Fact (μ t < ∞) := ⟨lt_top_iff_ne_top.mpr hμt⟩
    refine' ae_nonneg_of_forall_set_integral_nonneg_of_finite_measure hf fun s hs => _ 
    simpRw [measure.restrict_restrict hs]
    exact hf_zero s hs

theorem ae_nonneg_of_forall_set_integral_nonneg_of_sigma_finite [sigma_finite μ] {f : α → ℝ}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → 0 ≤ ∫ x in s, f x ∂μ) : 0 ≤ᵐ[μ] f :=
  by 
    apply ae_of_forall_measure_lt_top_ae_restrict 
    intro t t_meas t_lt_top 
    apply ae_nonneg_restrict_of_forall_set_integral_nonneg_inter t_lt_top.ne (hf_int_finite t t_meas t_lt_top)
    intro s s_meas 
    exact hf_zero _ (s_meas.inter t_meas) (lt_of_le_of_ltₓ (measure_mono (Set.inter_subset_right _ _)) t_lt_top)

theorem ae_fin_strongly_measurable.ae_nonneg_of_forall_set_integral_nonneg {f : α → ℝ}
  (hf : ae_fin_strongly_measurable f μ) (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → 0 ≤ ∫ x in s, f x ∂μ) : 0 ≤ᵐ[μ] f :=
  by 
    let t := hf.sigma_finite_set 
    suffices  : 0 ≤ᵐ[μ.restrict t] f 
    exact ae_of_ae_restrict_of_ae_restrict_compl this hf.ae_eq_zero_compl.symm.le 
    have  : sigma_finite (μ.restrict t) := hf.sigma_finite_restrict 
    refine' ae_nonneg_of_forall_set_integral_nonneg_of_sigma_finite (fun s hs hμts => _) fun s hs hμts => _
    ·
      rw [integrable_on, measure.restrict_restrict hs]
      rw [measure.restrict_apply hs] at hμts 
      exact hf_int_finite (s ∩ t) (hs.inter hf.measurable_set) hμts
    ·
      rw [measure.restrict_restrict hs]
      rw [measure.restrict_apply hs] at hμts 
      exact hf_zero (s ∩ t) (hs.inter hf.measurable_set) hμts

theorem integrable.ae_nonneg_of_forall_set_integral_nonneg {f : α → ℝ} (hf : integrable f μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → 0 ≤ ∫ x in s, f x ∂μ) : 0 ≤ᵐ[μ] f :=
  ae_fin_strongly_measurable.ae_nonneg_of_forall_set_integral_nonneg hf.ae_fin_strongly_measurable
    (fun s hs hμs => hf.integrable_on) hf_zero

theorem ae_nonneg_restrict_of_forall_set_integral_nonneg {f : α → ℝ}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → 0 ≤ ∫ x in s, f x ∂μ) {t : Set α} (ht : MeasurableSet t) (hμt : μ t ≠ ∞) :
  0 ≤ᵐ[μ.restrict t] f :=
  by 
    refine'
      ae_nonneg_restrict_of_forall_set_integral_nonneg_inter hμt (hf_int_finite t ht (lt_top_iff_ne_top.mpr hμt))
        fun s hs => _ 
    refine' hf_zero (s ∩ t) (hs.inter ht) _ 
    exact (measure_mono (Set.inter_subset_right s t)).trans_lt (lt_top_iff_ne_top.mpr hμt)

theorem ae_eq_zero_restrict_of_forall_set_integral_eq_zero_real {f : α → ℝ}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) {t : Set α} (ht : MeasurableSet t)
  (hμt : μ t ≠ ∞) : f =ᵐ[μ.restrict t] 0 :=
  by 
    suffices h_and : f ≤ᵐ[μ.restrict t] 0 ∧ 0 ≤ᵐ[μ.restrict t] f 
    exact h_and.1.mp (h_and.2.mono fun x hx1 hx2 => le_antisymmₓ hx2 hx1)
    refine'
      ⟨_,
        ae_nonneg_restrict_of_forall_set_integral_nonneg hf_int_finite (fun s hs hμs => (hf_zero s hs hμs).symm.le) ht
          hμt⟩
    suffices h_neg : 0 ≤ᵐ[μ.restrict t] -f
    ·
      refine' h_neg.mono fun x hx => _ 
      rw [Pi.neg_apply] at hx 
      simpa using hx 
    refine'
      ae_nonneg_restrict_of_forall_set_integral_nonneg (fun s hs hμs => (hf_int_finite s hs hμs).neg)
        (fun s hs hμs => _) ht hμt 
    simpRw [Pi.neg_apply]
    rw [integral_neg, neg_nonneg]
    exact (hf_zero s hs hμs).le

end Real

theorem ae_eq_zero_restrict_of_forall_set_integral_eq_zero {f : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) {t : Set α} (ht : MeasurableSet t)
  (hμt : μ t ≠ ∞) : f =ᵐ[μ.restrict t] 0 :=
  by 
    refine' ae_eq_zero_of_forall_dual ℝ fun c => _ 
    refine' ae_eq_zero_restrict_of_forall_set_integral_eq_zero_real _ _ ht hμt
    ·
      intro s hs hμs 
      exact ContinuousLinearMap.integrable_comp c (hf_int_finite s hs hμs)
    ·
      intro s hs hμs 
      rw [ContinuousLinearMap.integral_comp_comm c (hf_int_finite s hs hμs), hf_zero s hs hμs]
      exact ContinuousLinearMap.map_zero _

theorem ae_eq_restrict_of_forall_set_integral_eq {f g : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hg_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on g s μ)
  (hfg_zero : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = ∫ x in s, g x ∂μ) {t : Set α}
  (ht : MeasurableSet t) (hμt : μ t ≠ ∞) : f =ᵐ[μ.restrict t] g :=
  by 
    rw [←sub_ae_eq_zero]
    have hfg' : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, (f - g) x ∂μ) = 0
    ·
      intro s hs hμs 
      rw [integral_sub' (hf_int_finite s hs hμs) (hg_int_finite s hs hμs)]
      exact sub_eq_zero.mpr (hfg_zero s hs hμs)
    have hfg_int : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on (f - g) s μ 
    exact fun s hs hμs => (hf_int_finite s hs hμs).sub (hg_int_finite s hs hμs)
    exact ae_eq_zero_restrict_of_forall_set_integral_eq_zero hfg_int hfg' ht hμt

theorem ae_eq_zero_of_forall_set_integral_eq_of_sigma_finite [sigma_finite μ] {f : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) : f =ᵐ[μ] 0 :=
  by 
    let S := spanning_sets μ 
    rw [←@measure.restrict_univ _ _ μ, ←Union_spanning_sets μ, eventually_eq, ae_iff,
      measure.restrict_apply' (MeasurableSet.Union (measurable_spanning_sets μ))]
    rw [Set.inter_Union, measure_Union_null_iff]
    intro n 
    have h_meas_n : MeasurableSet (S n)
    exact measurable_spanning_sets μ n 
    have hμn : μ (S n) < ∞
    exact measure_spanning_sets_lt_top μ n 
    rw [←measure.restrict_apply' h_meas_n]
    exact ae_eq_zero_restrict_of_forall_set_integral_eq_zero hf_int_finite hf_zero h_meas_n hμn.ne

theorem ae_eq_of_forall_set_integral_eq_of_sigma_finite [sigma_finite μ] {f g : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hg_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on g s μ)
  (hfg_eq : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = ∫ x in s, g x ∂μ) : f =ᵐ[μ] g :=
  by 
    rw [←sub_ae_eq_zero]
    have hfg : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, (f - g) x ∂μ) = 0
    ·
      intro s hs hμs 
      rw [integral_sub' (hf_int_finite s hs hμs) (hg_int_finite s hs hμs), sub_eq_zero.mpr (hfg_eq s hs hμs)]
    have hfg_int : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on (f - g) s μ 
    exact fun s hs hμs => (hf_int_finite s hs hμs).sub (hg_int_finite s hs hμs)
    exact ae_eq_zero_of_forall_set_integral_eq_of_sigma_finite hfg_int hfg

theorem ae_fin_strongly_measurable.ae_eq_zero_of_forall_set_integral_eq_zero {f : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) (hf : ae_fin_strongly_measurable f μ) :
  f =ᵐ[μ] 0 :=
  by 
    let t := hf.sigma_finite_set 
    suffices  : f =ᵐ[μ.restrict t] 0 
    exact ae_of_ae_restrict_of_ae_restrict_compl this hf.ae_eq_zero_compl 
    have  : sigma_finite (μ.restrict t) := hf.sigma_finite_restrict 
    refine' ae_eq_zero_of_forall_set_integral_eq_of_sigma_finite _ _
    ·
      intro s hs hμs 
      rw [integrable_on, measure.restrict_restrict hs]
      rw [measure.restrict_apply hs] at hμs 
      exact hf_int_finite _ (hs.inter hf.measurable_set) hμs
    ·
      intro s hs hμs 
      rw [measure.restrict_restrict hs]
      rw [measure.restrict_apply hs] at hμs 
      exact hf_zero _ (hs.inter hf.measurable_set) hμs

theorem ae_fin_strongly_measurable.ae_eq_of_forall_set_integral_eq {f g : α → E}
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hg_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on g s μ)
  (hfg_eq : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = ∫ x in s, g x ∂μ)
  (hf : ae_fin_strongly_measurable f μ) (hg : ae_fin_strongly_measurable g μ) : f =ᵐ[μ] g :=
  by 
    rw [←sub_ae_eq_zero]
    have hfg : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, (f - g) x ∂μ) = 0
    ·
      intro s hs hμs 
      rw [integral_sub' (hf_int_finite s hs hμs) (hg_int_finite s hs hμs), sub_eq_zero.mpr (hfg_eq s hs hμs)]
    have hfg_int : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on (f - g) s μ 
    exact fun s hs hμs => (hf_int_finite s hs hμs).sub (hg_int_finite s hs hμs)
    exact (hf.sub hg).ae_eq_zero_of_forall_set_integral_eq_zero hfg_int hfg

theorem Lp.ae_eq_zero_of_forall_set_integral_eq_zero (f : Lp E p μ) (hp_ne_zero : p ≠ 0) (hp_ne_top : p ≠ ∞)
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) : f =ᵐ[μ] 0 :=
  ae_fin_strongly_measurable.ae_eq_zero_of_forall_set_integral_eq_zero hf_int_finite hf_zero
    (Lp.fin_strongly_measurable _ hp_ne_zero hp_ne_top).AeFinStronglyMeasurable

theorem Lp.ae_eq_of_forall_set_integral_eq (f g : Lp E p μ) (hp_ne_zero : p ≠ 0) (hp_ne_top : p ≠ ∞)
  (hf_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on f s μ)
  (hg_int_finite : ∀ s, MeasurableSet s → μ s < ∞ → integrable_on g s μ)
  (hfg : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = ∫ x in s, g x ∂μ) : f =ᵐ[μ] g :=
  ae_fin_strongly_measurable.ae_eq_of_forall_set_integral_eq hf_int_finite hg_int_finite hfg
    (Lp.fin_strongly_measurable _ hp_ne_zero hp_ne_top).AeFinStronglyMeasurable
    (Lp.fin_strongly_measurable _ hp_ne_zero hp_ne_top).AeFinStronglyMeasurable

theorem ae_eq_zero_of_forall_set_integral_eq_of_fin_strongly_measurable_trim (hm : m ≤ m0) {f : α → E}
  (hf_int_finite : ∀ s, measurable_set[m] s → μ s < ∞ → integrable_on f s μ)
  (hf_zero : ∀ s : Set α, measurable_set[m] s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0)
  (hf : fin_strongly_measurable f (μ.trim hm)) : f =ᵐ[μ] 0 :=
  by 
    obtain ⟨t, ht_meas, htf_zero, htμ⟩ := hf.exists_set_sigma_finite 
    have  : sigma_finite ((μ.restrict t).trim hm) :=
      by 
        rwa [restrict_trim hm μ ht_meas] at htμ 
    have htf_zero : f =ᵐ[μ.restrict (tᶜ)] 0
    ·
      rw [eventually_eq, ae_restrict_iff' (MeasurableSet.compl (hm _ ht_meas))]
      exact eventually_of_forall htf_zero 
    have hf_meas_m : @Measurable _ _ m _ f 
    exact hf.measurable 
    suffices  : f =ᵐ[μ.restrict t] 0 
    exact ae_of_ae_restrict_of_ae_restrict_compl this htf_zero 
    refine' measure_eq_zero_of_trim_eq_zero hm _ 
    refine' ae_eq_zero_of_forall_set_integral_eq_of_sigma_finite _ _
    ·
      intro s hs hμs 
      rw [integrable_on, restrict_trim hm (μ.restrict t) hs, measure.restrict_restrict (hm s hs)]
      rw [←restrict_trim hm μ ht_meas, measure.restrict_apply hs,
        trim_measurable_set_eq hm (@MeasurableSet.inter _ m _ _ hs ht_meas)] at hμs 
      refine' integrable.trim hm _ hf_meas_m 
      exact hf_int_finite _ (@MeasurableSet.inter _ m _ _ hs ht_meas) hμs
    ·
      intro s hs hμs 
      rw [restrict_trim hm (μ.restrict t) hs, measure.restrict_restrict (hm s hs)]
      rw [←restrict_trim hm μ ht_meas, measure.restrict_apply hs,
        trim_measurable_set_eq hm (@MeasurableSet.inter _ m _ _ hs ht_meas)] at hμs 
      rw [←integral_trim hm hf_meas_m]
      exact hf_zero _ (@MeasurableSet.inter _ m _ _ hs ht_meas) hμs

theorem integrable.ae_eq_zero_of_forall_set_integral_eq_zero {f : α → E} (hf : integrable f μ)
  (hf_zero : ∀ s, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = 0) : f =ᵐ[μ] 0 :=
  by 
    have hf_Lp : mem_ℒp f 1 μ 
    exact mem_ℒp_one_iff_integrable.mpr hf 
    let f_Lp := hf_Lp.to_Lp f 
    have hf_f_Lp : f =ᵐ[μ] f_Lp 
    exact (mem_ℒp.coe_fn_to_Lp hf_Lp).symm 
    refine' hf_f_Lp.trans _ 
    refine' Lp.ae_eq_zero_of_forall_set_integral_eq_zero f_Lp one_ne_zero Ennreal.coe_ne_top _ _
    ·
      exact fun s hs hμs => integrable.integrable_on (L1.integrable_coe_fn _)
    ·
      intro s hs hμs 
      rw [integral_congr_ae (ae_restrict_of_ae hf_f_Lp.symm)]
      exact hf_zero s hs hμs

theorem integrable.ae_eq_of_forall_set_integral_eq (f g : α → E) (hf : integrable f μ) (hg : integrable g μ)
  (hfg : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, f x ∂μ) = ∫ x in s, g x ∂μ) : f =ᵐ[μ] g :=
  by 
    rw [←sub_ae_eq_zero]
    have hfg' : ∀ s : Set α, MeasurableSet s → μ s < ∞ → (∫ x in s, (f - g) x ∂μ) = 0
    ·
      intro s hs hμs 
      rw [integral_sub' hf.integrable_on hg.integrable_on]
      exact sub_eq_zero.mpr (hfg s hs hμs)
    exact integrable.ae_eq_zero_of_forall_set_integral_eq_zero (hf.sub hg) hfg'

end AeEqOfForallSetIntegralEq

section Lintegral

theorem ae_measurable.ae_eq_of_forall_set_lintegral_eq {f g : α → ℝ≥0∞} (hf : AeMeasurable f μ) (hg : AeMeasurable g μ)
  (hfi : (∫⁻ x, f x ∂μ) ≠ ∞) (hgi : (∫⁻ x, g x ∂μ) ≠ ∞)
  (hfg : ∀ ⦃s⦄, MeasurableSet s → μ s < ∞ → (∫⁻ x in s, f x ∂μ) = ∫⁻ x in s, g x ∂μ) : f =ᵐ[μ] g :=
  by 
    refine'
      Ennreal.eventually_eq_of_to_real_eventually_eq (ae_lt_top' hf hfi).ne_of_lt (ae_lt_top' hg hgi).ne_of_lt
        (integrable.ae_eq_of_forall_set_integral_eq _ _ (integrable_to_real_of_lintegral_ne_top hf hfi)
          (integrable_to_real_of_lintegral_ne_top hg hgi) fun s hs hs' => _)
    rw [integral_eq_lintegral_of_nonneg_ae, integral_eq_lintegral_of_nonneg_ae]
    ·
      congr 1
      rw [lintegral_congr_ae (of_real_to_real_ae_eq _), lintegral_congr_ae (of_real_to_real_ae_eq _)]
      ·
        exact hfg hs hs'
      ·
        refine' ae_lt_top' hg.restrict (ne_of_ltₓ (lt_of_le_of_ltₓ _ hgi.lt_top))
        exact @set_lintegral_univ α _ μ g ▸ lintegral_mono_set (Set.subset_univ _)
      ·
        refine' ae_lt_top' hf.restrict (ne_of_ltₓ (lt_of_le_of_ltₓ _ hfi.lt_top))
        exact @set_lintegral_univ α _ μ f ▸ lintegral_mono_set (Set.subset_univ _)
    exacts[ae_of_all _ fun x => Ennreal.to_real_nonneg, hg.ennreal_to_real.restrict,
      ae_of_all _ fun x => Ennreal.to_real_nonneg, hf.ennreal_to_real.restrict]

end Lintegral

end MeasureTheory

