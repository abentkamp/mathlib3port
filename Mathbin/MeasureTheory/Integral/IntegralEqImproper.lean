import Mathbin.MeasureTheory.Integral.IntervalIntegral 
import Mathbin.Order.Filter.AtTopBot

/-!
# Links between an integral and its "improper" version

In its current state, mathlib only knows how to talk about definite ("proper") integrals,
in the sense that it treats integrals over `[x, +∞)` the same as it treats integrals over
`[y, z]`. For example, the integral over `[1, +∞)` is **not** defined to be the limit of
the integral over `[1, x]` as `x` tends to `+∞`, which is known as an **improper integral**.

Indeed, the "proper" definition is stronger than the "improper" one. The usual counterexample
is `x ↦ sin(x)/x`, which has an improper integral over `[1, +∞)` but no definite integral.

Although definite integrals have better properties, they are hardly usable when it comes to
computing integrals on unbounded sets, which is much easier using limits. Thus, in this file,
we prove various ways of studying the proper integral by studying the improper one.

## Definitions

The main definition of this file is `measure_theory.ae_cover`. It is a rather technical
definition whose sole purpose is generalizing and factoring proofs. Given an index type `ι`, a
countably generated filter `l` over `ι`, and an `ι`-indexed family `φ` of subsets of a measurable
space `α` equipped with a measure `μ`, one should think of a hypothesis `hφ : ae_cover μ l φ` as
a sufficient condition for being able to interpret `∫ x, f x ∂μ` (if it exists) as the limit
of `∫ x in φ i, f x ∂μ` as `i` tends to `l`.

When using this definition with a measure restricted to a set `s`, which happens fairly often,
one should not try too hard to use a `ae_cover` of subsets of `s`, as it often makes proofs
more complicated than necessary. See for example the proof of
`measure_theory.integrable_on_Iic_of_interval_integral_norm_tendsto` where we use `(λ x, Ioi x)`
as an `ae_cover` w.r.t. `μ.restrict (Iic b)`, instead of using `(λ x, Ioc x b)`.

## Main statements

- `measure_theory.ae_cover.lintegral_tendsto_of_countably_generated` : if `φ` is a `ae_cover μ l`,
  where `l` is a countably generated filter, and if `f` is a measurable `ennreal`-valued function,
  then `∫⁻ x in φ n, f x ∂μ` tends to `∫⁻ x, f x ∂μ` as `n` tends to `l`
- `measure_theory.ae_cover.integrable_of_integral_norm_tendsto` : if `φ` is a `ae_cover μ l`,
  where `l` is a countably generated filter, if `f` is measurable and integrable on each `φ n`,
  and if `∫ x in φ n, ∥f x∥ ∂μ` tends to some `I : ℝ` as n tends to `l`, then `f` is integrable
- `measure_theory.ae_cover.integral_tendsto_of_countably_generated` : if `φ` is a `ae_cover μ l`,
  where `l` is a countably generated filter, and if `f` is measurable and integrable (globally),
  then `∫ x in φ n, f x ∂μ` tends to `∫ x, f x ∂μ` as `n` tends to `+∞`.

We then specialize these lemmas to various use cases involving intervals, which are frequent
in analysis.
-/


open MeasureTheory Filter Set TopologicalSpace

open_locale Ennreal Nnreal TopologicalSpace

namespace MeasureTheory

section AeCover

variable {α ι : Type _} [MeasurableSpace α] (μ : Measureₓ α) (l : Filter ι)

/-- A sequence `φ` of subsets of `α` is a `ae_cover` w.r.t. a measure `μ` and a filter `l`
    if almost every point (w.r.t. `μ`) of `α` eventually belongs to `φ n` (w.r.t. `l`), and if
    each `φ n` is measurable.
    This definition is a technical way to avoid duplicating a lot of proofs.
    It should be thought of as a sufficient condition for being able to interpret
    `∫ x, f x ∂μ` (if it exists) as the limit of `∫ x in φ n, f x ∂μ` as `n` tends to `l`.

    See for example `measure_theory.ae_cover.lintegral_tendsto_of_countably_generated`,
    `measure_theory.ae_cover.integrable_of_integral_norm_tendsto` and
    `measure_theory.ae_cover.integral_tendsto_of_countably_generated`. -/
structure ae_cover (φ : ι → Set α) : Prop where 
  ae_eventually_mem : ∀ᵐ x ∂μ, ∀ᶠ i in l, x ∈ φ i 
  Measurable : ∀ i, MeasurableSet$ φ i

variable {μ} {l}

section Preorderα

variable [Preorderₓ α] [TopologicalSpace α] [OrderClosedTopology α] [OpensMeasurableSpace α] {a b : ι → α}
  (ha : tendsto a l at_bot) (hb : tendsto b l at_top)

theorem ae_cover_Icc : ae_cover μ l fun i => Icc (a i) (b i) :=
  { ae_eventually_mem :=
      ae_of_all μ
        fun x =>
          (ha.eventually$ eventually_le_at_bot x).mp$
            (hb.eventually$ eventually_ge_at_top x).mono$ fun i hbi hai => ⟨hai, hbi⟩,
    Measurable := fun i => measurable_set_Icc }

theorem ae_cover_Ici : ae_cover μ l fun i => Ici$ a i :=
  { ae_eventually_mem := ae_of_all μ fun x => (ha.eventually$ eventually_le_at_bot x).mono$ fun i hai => hai,
    Measurable := fun i => measurable_set_Ici }

theorem ae_cover_Iic : ae_cover μ l fun i => Iic$ b i :=
  { ae_eventually_mem := ae_of_all μ fun x => (hb.eventually$ eventually_ge_at_top x).mono$ fun i hbi => hbi,
    Measurable := fun i => measurable_set_Iic }

end Preorderα

section LinearOrderα

variable [LinearOrderₓ α] [TopologicalSpace α] [OrderClosedTopology α] [OpensMeasurableSpace α] {a b : ι → α}
  (ha : tendsto a l at_bot) (hb : tendsto b l at_top)

theorem ae_cover_Ioo [NoBotOrder α] [NoTopOrder α] : ae_cover μ l fun i => Ioo (a i) (b i) :=
  { ae_eventually_mem :=
      ae_of_all μ
        fun x =>
          (ha.eventually$ eventually_lt_at_bot x).mp$
            (hb.eventually$ eventually_gt_at_top x).mono$ fun i hbi hai => ⟨hai, hbi⟩,
    Measurable := fun i => measurable_set_Ioo }

theorem ae_cover_Ioc [NoBotOrder α] : ae_cover μ l fun i => Ioc (a i) (b i) :=
  { ae_eventually_mem :=
      ae_of_all μ
        fun x =>
          (ha.eventually$ eventually_lt_at_bot x).mp$
            (hb.eventually$ eventually_ge_at_top x).mono$ fun i hbi hai => ⟨hai, hbi⟩,
    Measurable := fun i => measurable_set_Ioc }

theorem ae_cover_Ico [NoTopOrder α] : ae_cover μ l fun i => Ico (a i) (b i) :=
  { ae_eventually_mem :=
      ae_of_all μ
        fun x =>
          (ha.eventually$ eventually_le_at_bot x).mp$
            (hb.eventually$ eventually_gt_at_top x).mono$ fun i hbi hai => ⟨hai, hbi⟩,
    Measurable := fun i => measurable_set_Ico }

theorem ae_cover_Ioi [NoBotOrder α] : ae_cover μ l fun i => Ioi$ a i :=
  { ae_eventually_mem := ae_of_all μ fun x => (ha.eventually$ eventually_lt_at_bot x).mono$ fun i hai => hai,
    Measurable := fun i => measurable_set_Ioi }

theorem ae_cover_Iio [NoTopOrder α] : ae_cover μ l fun i => Iio$ b i :=
  { ae_eventually_mem := ae_of_all μ fun x => (hb.eventually$ eventually_gt_at_top x).mono$ fun i hbi => hbi,
    Measurable := fun i => measurable_set_Iio }

end LinearOrderα

theorem ae_cover.restrict {φ : ι → Set α} (hφ : ae_cover μ l φ) {s : Set α} : ae_cover (μ.restrict s) l φ :=
  { ae_eventually_mem := ae_restrict_of_ae hφ.ae_eventually_mem, Measurable := hφ.measurable }

theorem ae_cover_restrict_of_ae_imp {s : Set α} {φ : ι → Set α} (hs : MeasurableSet s)
  (ae_eventually_mem : ∀ᵐ x ∂μ, x ∈ s → ∀ᶠ n in l, x ∈ φ n) (measurable : ∀ n, MeasurableSet$ φ n) :
  ae_cover (μ.restrict s) l φ :=
  { ae_eventually_mem :=
      by 
        rwa [ae_restrict_iff' hs],
    Measurable }

theorem ae_cover.inter_restrict {φ : ι → Set α} (hφ : ae_cover μ l φ) {s : Set α} (hs : MeasurableSet s) :
  ae_cover (μ.restrict s) l fun i => φ i ∩ s :=
  ae_cover_restrict_of_ae_imp hs (hφ.ae_eventually_mem.mono fun x hx hxs => hx.mono$ fun i hi => ⟨hi, hxs⟩)
    fun i => (hφ.measurable i).inter hs

theorem ae_cover.ae_tendsto_indicator {β : Type _} [HasZero β] [TopologicalSpace β] (f : α → β) {φ : ι → Set α}
  (hφ : ae_cover μ l φ) : ∀ᵐ x ∂μ, tendsto (fun i => (φ i).indicator f x) l (𝓝$ f x) :=
  hφ.ae_eventually_mem.mono fun x hx => tendsto_const_nhds.congr'$ hx.mono$ fun n hn => (indicator_of_mem hn _).symm

theorem ae_cover.ae_measurable {β : Type _} [MeasurableSpace β] [l.is_countably_generated] [l.ne_bot] {f : α → β}
  {φ : ι → Set α} (hφ : ae_cover μ l φ) (hfm : ∀ i, AeMeasurable f (μ.restrict$ φ i)) : AeMeasurable f μ :=
  by 
    obtain ⟨u, hu⟩ := l.exists_seq_tendsto 
    have  := ae_measurable_Union_iff.mpr fun n : ℕ => hfm (u n)
    rwa [measure.restrict_eq_self_of_ae_mem] at this 
    filterUpwards [hφ.ae_eventually_mem]
      fun x hx =>
        let ⟨i, hi⟩ := (hu.eventually hx).exists 
        mem_Union.mpr ⟨i, hi⟩

end AeCover

theorem ae_cover.comp_tendsto {α ι ι' : Type _} [MeasurableSpace α] {μ : Measureₓ α} {l : Filter ι} {l' : Filter ι'}
  {φ : ι → Set α} (hφ : ae_cover μ l φ) {u : ι' → ι} (hu : tendsto u l' l) : ae_cover μ l' (φ ∘ u) :=
  { ae_eventually_mem := hφ.ae_eventually_mem.mono fun x hx => hu.eventually hx,
    Measurable := fun i => hφ.measurable (u i) }

section AeCoverUnionInterEncodable

variable {α ι : Type _} [Encodable ι] [MeasurableSpace α] {μ : Measureₓ α}

theorem ae_cover.bUnion_Iic_ae_cover [Preorderₓ ι] {φ : ι → Set α} (hφ : ae_cover μ at_top φ) :
  ae_cover μ at_top fun n : ι => ⋃ (k : _)(h : k ∈ Iic n), φ k :=
  { ae_eventually_mem := hφ.ae_eventually_mem.mono fun x h => h.mono fun i hi => mem_bUnion right_mem_Iic hi,
    Measurable := fun i => MeasurableSet.bUnion (countable_encodable _) fun n _ => hφ.measurable n }

theorem ae_cover.bInter_Ici_ae_cover [SemilatticeSup ι] [Nonempty ι] {φ : ι → Set α} (hφ : ae_cover μ at_top φ) :
  ae_cover μ at_top fun n : ι => ⋂ (k : _)(h : k ∈ Ici n), φ k :=
  { ae_eventually_mem :=
      hφ.ae_eventually_mem.mono
        (by 
          intro x h 
          rw [eventually_at_top] at *
          rcases h with ⟨i, hi⟩
          use i 
          intro j hj 
          exact mem_bInter fun k hk => hi k (le_transₓ hj hk)),
    Measurable := fun i => MeasurableSet.bInter (countable_encodable _) fun n _ => hφ.measurable n }

end AeCoverUnionInterEncodable

section Lintegral

variable {α ι : Type _} [MeasurableSpace α] {μ : Measureₓ α} {l : Filter ι}

private theorem lintegral_tendsto_of_monotone_of_nat {φ : ℕ → Set α} (hφ : ae_cover μ at_top φ) (hmono : Monotone φ)
  {f : α → ℝ≥0∞} (hfm : AeMeasurable f μ) : tendsto (fun i => ∫⁻ x in φ i, f x ∂μ) at_top (𝓝$ ∫⁻ x, f x ∂μ) :=
  let F := fun n => (φ n).indicator f 
  have key₁ : ∀ n, AeMeasurable (F n) μ := fun n => hfm.indicator (hφ.measurable n)
  have key₂ : ∀ᵐ x : α ∂μ, Monotone fun n => F n x :=
    ae_of_all _ fun x i j hij => indicator_le_indicator_of_subset (hmono hij) (fun x => zero_le$ f x) x 
  have key₃ : ∀ᵐ x : α ∂μ, tendsto (fun n => F n x) at_top (𝓝 (f x)) := hφ.ae_tendsto_indicator f
  (lintegral_tendsto_of_tendsto_of_monotone key₁ key₂ key₃).congr fun n => lintegral_indicator f (hφ.measurable n)

theorem ae_cover.lintegral_tendsto_of_nat {φ : ℕ → Set α} (hφ : ae_cover μ at_top φ) {f : α → ℝ≥0∞}
  (hfm : AeMeasurable f μ) : tendsto (fun i => ∫⁻ x in φ i, f x ∂μ) at_top (𝓝$ ∫⁻ x, f x ∂μ) :=
  by 
    have lim₁ :=
      lintegral_tendsto_of_monotone_of_nat hφ.bInter_Ici_ae_cover
        (fun i j hij => bInter_subset_bInter_left (Ici_subset_Ici.mpr hij)) hfm 
    have lim₂ :=
      lintegral_tendsto_of_monotone_of_nat hφ.bUnion_Iic_ae_cover
        (fun i j hij => bUnion_subset_bUnion_left (Iic_subset_Iic.mpr hij)) hfm 
    have le₁ := fun n => lintegral_mono_set (bInter_subset_of_mem left_mem_Ici)
    have le₂ := fun n => lintegral_mono_set (subset_bUnion_of_mem right_mem_Iic)
    exact tendsto_of_tendsto_of_tendsto_of_le_of_le lim₁ lim₂ le₁ le₂

theorem ae_cover.lintegral_tendsto_of_countably_generated [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → ℝ≥0∞} (hfm : AeMeasurable f μ) :
  tendsto (fun i => ∫⁻ x in φ i, f x ∂μ) l (𝓝$ ∫⁻ x, f x ∂μ) :=
  tendsto_of_seq_tendsto fun u hu => (hφ.comp_tendsto hu).lintegral_tendsto_of_nat hfm

theorem ae_cover.lintegral_eq_of_tendsto [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α} (hφ : ae_cover μ l φ)
  {f : α → ℝ≥0∞} (I : ℝ≥0∞) (hfm : AeMeasurable f μ) (htendsto : tendsto (fun i => ∫⁻ x in φ i, f x ∂μ) l (𝓝 I)) :
  (∫⁻ x, f x ∂μ) = I :=
  tendsto_nhds_unique (hφ.lintegral_tendsto_of_countably_generated hfm) htendsto

theorem ae_cover.supr_lintegral_eq_of_countably_generated [Nonempty ι] [l.ne_bot] [l.is_countably_generated]
  {φ : ι → Set α} (hφ : ae_cover μ l φ) {f : α → ℝ≥0∞} (hfm : AeMeasurable f μ) :
  (⨆ i : ι, ∫⁻ x in φ i, f x ∂μ) = ∫⁻ x, f x ∂μ :=
  by 
    have  := hφ.lintegral_tendsto_of_countably_generated hfm 
    refine'
      csupr_eq_of_forall_le_of_forall_lt_exists_gt (fun i => lintegral_mono' measure.restrict_le_self (le_reflₓ _))
        fun w hw => _ 
    rcases exists_between hw with ⟨m, hm₁, hm₂⟩
    rcases(eventually_ge_of_tendsto_gt hm₂ this).exists with ⟨i, hi⟩
    exact ⟨i, lt_of_lt_of_leₓ hm₁ hi⟩

end Lintegral

section Integrable

variable {α ι E : Type _} [MeasurableSpace α] {μ : Measureₓ α} {l : Filter ι} [NormedGroup E] [MeasurableSpace E]
  [OpensMeasurableSpace E]

theorem ae_cover.integrable_of_lintegral_nnnorm_tendsto [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → E} (I : ℝ) (hfm : AeMeasurable f μ)
  (htendsto : tendsto (fun i => ∫⁻ x in φ i, nnnorm (f x) ∂μ) l (𝓝$ Ennreal.ofReal I)) : integrable f μ :=
  by 
    refine' ⟨hfm, _⟩
    unfold has_finite_integral 
    rw [hφ.lintegral_eq_of_tendsto _ (measurable_nnnorm.comp_ae_measurable hfm).coe_nnreal_ennreal htendsto]
    exact Ennreal.of_real_lt_top

theorem ae_cover.integrable_of_lintegral_nnnorm_tendsto' [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → E} (I :  ℝ≥0 ) (hfm : AeMeasurable f μ)
  (htendsto : tendsto (fun i => ∫⁻ x in φ i, nnnorm (f x) ∂μ) l (𝓝$ Ennreal.ofReal I)) : integrable f μ :=
  hφ.integrable_of_lintegral_nnnorm_tendsto I hfm htendsto

theorem ae_cover.integrable_of_integral_norm_tendsto [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → E} (I : ℝ) (hfi : ∀ i, integrable_on f (φ i) μ)
  (htendsto : tendsto (fun i => ∫ x in φ i, ∥f x∥ ∂μ) l (𝓝 I)) : integrable f μ :=
  by 
    have hfm : AeMeasurable f μ := hφ.ae_measurable fun i => (hfi i).AeMeasurable 
    refine' hφ.integrable_of_lintegral_nnnorm_tendsto I hfm _ 
    conv  at htendsto in integral _ _ =>
      rw [integral_eq_lintegral_of_nonneg_ae (ae_of_all _ fun x => @norm_nonneg E _ (f x)) hfm.norm.restrict]
    conv  at htendsto in Ennreal.ofReal _ => dsimp rw [←coe_nnnorm]rw [Ennreal.of_real_coe_nnreal]
    convert Ennreal.tendsto_of_real htendsto 
    ext i : 1
    rw [Ennreal.of_real_to_real _]
    exact ne_top_of_lt (hfi i).2

theorem ae_cover.integrable_of_integral_tendsto_of_nonneg_ae [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → ℝ} (I : ℝ) (hfi : ∀ i, integrable_on f (φ i) μ) (hnng : ∀ᵐ x ∂μ, 0 ≤ f x)
  (htendsto : tendsto (fun i => ∫ x in φ i, f x ∂μ) l (𝓝 I)) : integrable f μ :=
  hφ.integrable_of_integral_norm_tendsto I hfi
    (htendsto.congr$
      fun i => integral_congr_ae$ ae_restrict_of_ae$ hnng.mono$ fun x hx => (Real.norm_of_nonneg hx).symm)

end Integrable

section Integral

variable {α ι E : Type _} [MeasurableSpace α] {μ : Measureₓ α} {l : Filter ι} [NormedGroup E] [NormedSpace ℝ E]
  [MeasurableSpace E] [BorelSpace E] [CompleteSpace E] [second_countable_topology E]

theorem ae_cover.integral_tendsto_of_countably_generated [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → E} (hfi : integrable f μ) : tendsto (fun i => ∫ x in φ i, f x ∂μ) l (𝓝$ ∫ x, f x ∂μ) :=
  suffices h : tendsto (fun i => ∫ x : α, (φ i).indicator f x ∂μ) l (𝓝 (∫ x : α, f x ∂μ))by 
    convert h 
    ext n 
    rw [integral_indicator (hφ.measurable n)]
  tendsto_integral_filter_of_dominated_convergence (fun x => ∥f x∥)
    (eventually_of_forall$ fun i => hfi.ae_measurable.indicator$ hφ.measurable i)
    (eventually_of_forall$ fun i => ae_of_all _$ fun x => norm_indicator_le_norm_self _ _) hfi.norm
    (hφ.ae_tendsto_indicator f)

/-- Slight reformulation of
    `measure_theory.ae_cover.integral_tendsto_of_countably_generated`. -/
theorem ae_cover.integral_eq_of_tendsto [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α} (hφ : ae_cover μ l φ)
  {f : α → E} (I : E) (hfi : integrable f μ) (h : tendsto (fun n => ∫ x in φ n, f x ∂μ) l (𝓝 I)) : (∫ x, f x ∂μ) = I :=
  tendsto_nhds_unique (hφ.integral_tendsto_of_countably_generated hfi) h

theorem ae_cover.integral_eq_of_tendsto_of_nonneg_ae [l.ne_bot] [l.is_countably_generated] {φ : ι → Set α}
  (hφ : ae_cover μ l φ) {f : α → ℝ} (I : ℝ) (hnng : 0 ≤ᵐ[μ] f) (hfi : ∀ n, integrable_on f (φ n) μ)
  (htendsto : tendsto (fun n => ∫ x in φ n, f x ∂μ) l (𝓝 I)) : (∫ x, f x ∂μ) = I :=
  have hfi' : integrable f μ := hφ.integrable_of_integral_tendsto_of_nonneg_ae I hfi hnng htendsto 
  hφ.integral_eq_of_tendsto I hfi' htendsto

end Integral

section IntegrableOfIntervalIntegral

variable {α ι E : Type _} [TopologicalSpace α] [LinearOrderₓ α] [OrderClosedTopology α] [MeasurableSpace α]
  [OpensMeasurableSpace α] {μ : Measureₓ α} {l : Filter ι} [Filter.NeBot l] [is_countably_generated l]
  [MeasurableSpace E] [NormedGroup E] [BorelSpace E] {a b : ι → α} {f : α → E}

theorem integrable_of_interval_integral_norm_tendsto [NoBotOrder α] [Nonempty α] (I : ℝ)
  (hfi : ∀ i, integrable_on f (Ioc (a i) (b i)) μ) (ha : tendsto a l at_bot) (hb : tendsto b l at_top)
  (h : tendsto (fun i => ∫ x in a i..b i, ∥f x∥ ∂μ) l (𝓝$ I)) : integrable f μ :=
  by 
    let φ := fun n => Ioc (a n) (b n)
    let c : α := Classical.choice ‹_›
    have hφ : ae_cover μ l φ := ae_cover_Ioc ha hb 
    refine' hφ.integrable_of_integral_norm_tendsto _ hfi (h.congr' _)
    filterUpwards [ha.eventually (eventually_le_at_bot c), hb.eventually (eventually_ge_at_top c)]
    intro i hai hbi 
    exact intervalIntegral.integral_of_le (hai.trans hbi)

theorem integrable_on_Iic_of_interval_integral_norm_tendsto [NoBotOrder α] (I : ℝ) (b : α)
  (hfi : ∀ i, integrable_on f (Ioc (a i) b) μ) (ha : tendsto a l at_bot)
  (h : tendsto (fun i => ∫ x in a i..b, ∥f x∥ ∂μ) l (𝓝$ I)) : integrable_on f (Iic b) μ :=
  by 
    let φ := fun i => Ioi (a i)
    have hφ : ae_cover (μ.restrict$ Iic b) l φ := ae_cover_Ioi ha 
    have hfi : ∀ i, integrable_on f (φ i) (μ.restrict$ Iic b)
    ·
      intro i 
      rw [integrable_on, measure.restrict_restrict (hφ.measurable i)]
      exact hfi i 
    refine' hφ.integrable_of_integral_norm_tendsto _ hfi (h.congr' _)
    filterUpwards [ha.eventually (eventually_le_at_bot b)]
    intro i hai 
    rw [intervalIntegral.integral_of_le hai, measure.restrict_restrict (hφ.measurable i)]
    rfl

theorem integrable_on_Ioi_of_interval_integral_norm_tendsto (I : ℝ) (a : α) (hfi : ∀ i, integrable_on f (Ioc a (b i)) μ)
  (hb : tendsto b l at_top) (h : tendsto (fun i => ∫ x in a..b i, ∥f x∥ ∂μ) l (𝓝$ I)) : integrable_on f (Ioi a) μ :=
  by 
    let φ := fun i => Iic (b i)
    have hφ : ae_cover (μ.restrict$ Ioi a) l φ := ae_cover_Iic hb 
    have hfi : ∀ i, integrable_on f (φ i) (μ.restrict$ Ioi a)
    ·
      intro i 
      rw [integrable_on, measure.restrict_restrict (hφ.measurable i), inter_comm]
      exact hfi i 
    refine' hφ.integrable_of_integral_norm_tendsto _ hfi (h.congr' _)
    filterUpwards [hb.eventually (eventually_ge_at_top$ a)]
    intro i hbi 
    rw [intervalIntegral.integral_of_le hbi, measure.restrict_restrict (hφ.measurable i), inter_comm]
    rfl

end IntegrableOfIntervalIntegral

section IntegralOfIntervalIntegral

variable {α ι E : Type _} [TopologicalSpace α] [LinearOrderₓ α] [OrderClosedTopology α] [MeasurableSpace α]
  [OpensMeasurableSpace α] {μ : Measureₓ α} {l : Filter ι} [is_countably_generated l] [MeasurableSpace E]
  [NormedGroup E] [NormedSpace ℝ E] [BorelSpace E] [CompleteSpace E] [second_countable_topology E] {a b : ι → α}
  {f : α → E}

theorem interval_integral_tendsto_integral [NoBotOrder α] [Nonempty α] (hfi : integrable f μ) (ha : tendsto a l at_bot)
  (hb : tendsto b l at_top) : tendsto (fun i => ∫ x in a i..b i, f x ∂μ) l (𝓝$ ∫ x, f x ∂μ) :=
  by 
    let φ := fun i => Ioc (a i) (b i)
    let c : α := Classical.choice ‹_›
    have hφ : ae_cover μ l φ := ae_cover_Ioc ha hb 
    refine' (hφ.integral_tendsto_of_countably_generated hfi).congr' _ 
    filterUpwards [ha.eventually (eventually_le_at_bot c), hb.eventually (eventually_ge_at_top c)]
    intro i hai hbi 
    exact (intervalIntegral.integral_of_le (hai.trans hbi)).symm

theorem interval_integral_tendsto_integral_Iic [NoBotOrder α] (b : α) (hfi : integrable_on f (Iic b) μ)
  (ha : tendsto a l at_bot) : tendsto (fun i => ∫ x in a i..b, f x ∂μ) l (𝓝$ ∫ x in Iic b, f x ∂μ) :=
  by 
    let φ := fun i => Ioi (a i)
    have hφ : ae_cover (μ.restrict$ Iic b) l φ := ae_cover_Ioi ha 
    refine' (hφ.integral_tendsto_of_countably_generated hfi).congr' _ 
    filterUpwards [ha.eventually (eventually_le_at_bot$ b)]
    intro i hai 
    rw [intervalIntegral.integral_of_le hai, measure.restrict_restrict (hφ.measurable i)]
    rfl

theorem interval_integral_tendsto_integral_Ioi (a : α) (hfi : integrable_on f (Ioi a) μ) (hb : tendsto b l at_top) :
  tendsto (fun i => ∫ x in a..b i, f x ∂μ) l (𝓝$ ∫ x in Ioi a, f x ∂μ) :=
  by 
    let φ := fun i => Iic (b i)
    have hφ : ae_cover (μ.restrict$ Ioi a) l φ := ae_cover_Iic hb 
    refine' (hφ.integral_tendsto_of_countably_generated hfi).congr' _ 
    filterUpwards [hb.eventually (eventually_ge_at_top$ a)]
    intro i hbi 
    rw [intervalIntegral.integral_of_le hbi, measure.restrict_restrict (hφ.measurable i), inter_comm]
    rfl

end IntegralOfIntervalIntegral

end MeasureTheory

