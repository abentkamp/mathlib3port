/-
Copyright (c) 2021 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne, Kexing Ying
-/
import Mathbin.Probability.Notation
import Mathbin.Probability.HittingTime

/-!
# Martingales

A family of functions `f : ι → Ω → E` is a martingale with respect to a filtration `ℱ` if every
`f i` is integrable, `f` is adapted with respect to `ℱ` and for all `i ≤ j`,
`μ[f j | ℱ i] =ᵐ[μ] f i`. On the other hand, `f : ι → Ω → E` is said to be a supermartingale
with respect to the filtration `ℱ` if `f i` is integrable, `f` is adapted with resepct to `ℱ`
and for all `i ≤ j`, `μ[f j | ℱ i] ≤ᵐ[μ] f i`. Finally, `f : ι → Ω → E` is said to be a
submartingale with respect to the filtration `ℱ` if `f i` is integrable, `f` is adapted with
resepct to `ℱ` and for all `i ≤ j`, `f i ≤ᵐ[μ] μ[f j | ℱ i]`.

The definitions of filtration and adapted can be found in `probability.stopping`.

### Definitions

* `measure_theory.martingale f ℱ μ`: `f` is a martingale with respect to filtration `ℱ` and
  measure `μ`.
* `measure_theory.supermartingale f ℱ μ`: `f` is a supermartingale with respect to
  filtration `ℱ` and measure `μ`.
* `measure_theory.submartingale f ℱ μ`: `f` is a submartingale with respect to filtration `ℱ` and
  measure `μ`.

### Results

* `measure_theory.martingale_condexp f ℱ μ`: the sequence `λ i, μ[f | ℱ i, ℱ.le i])` is a
  martingale with respect to `ℱ` and `μ`.

-/


open TopologicalSpace Filter

open Nnreal Ennreal MeasureTheory ProbabilityTheory BigOperators

namespace MeasureTheory

variable {Ω E ι : Type _} [Preorderₓ ι] {m0 : MeasurableSpace Ω} {μ : Measure Ω} [NormedAddCommGroup E]
  [NormedSpace ℝ E] [CompleteSpace E] {f g : ι → Ω → E} {ℱ : Filtration ι m0}

/-- A family of functions `f : ι → Ω → E` is a martingale with respect to a filtration `ℱ` if `f`
is adapted with respect to `ℱ` and for all `i ≤ j`, `μ[f j | ℱ i] =ᵐ[μ] f i`. -/
def Martingale (f : ι → Ω → E) (ℱ : Filtration ι m0) (μ : Measure Ω) : Prop :=
  Adapted ℱ f ∧ ∀ i j, i ≤ j → μ[f j|ℱ i] =ᵐ[μ] f i

/-- A family of integrable functions `f : ι → Ω → E` is a supermartingale with respect to a
filtration `ℱ` if `f` is adapted with respect to `ℱ` and for all `i ≤ j`,
`μ[f j | ℱ.le i] ≤ᵐ[μ] f i`. -/
def Supermartingale [LE E] (f : ι → Ω → E) (ℱ : Filtration ι m0) (μ : Measure Ω) : Prop :=
  Adapted ℱ f ∧ (∀ i j, i ≤ j → μ[f j|ℱ i] ≤ᵐ[μ] f i) ∧ ∀ i, Integrable (f i) μ

/-- A family of integrable functions `f : ι → Ω → E` is a submartingale with respect to a
filtration `ℱ` if `f` is adapted with respect to `ℱ` and for all `i ≤ j`,
`f i ≤ᵐ[μ] μ[f j | ℱ.le i]`. -/
def Submartingale [LE E] (f : ι → Ω → E) (ℱ : Filtration ι m0) (μ : Measure Ω) : Prop :=
  Adapted ℱ f ∧ (∀ i j, i ≤ j → f i ≤ᵐ[μ] μ[f j|ℱ i]) ∧ ∀ i, Integrable (f i) μ

theorem martingale_const (ℱ : Filtration ι m0) (μ : Measure Ω) [IsFiniteMeasure μ] (x : E) :
    Martingale (fun _ _ => x) ℱ μ :=
  ⟨adapted_const ℱ _, fun i j hij => by
    rw [condexp_const (ℱ.le _)]⟩

variable (E)

theorem martingale_zero (ℱ : Filtration ι m0) (μ : Measure Ω) : Martingale (0 : ι → Ω → E) ℱ μ :=
  ⟨adapted_zero E ℱ, fun i j hij => by
    rw [Pi.zero_apply, condexp_zero]
    simp ⟩

variable {E}

namespace Martingale

@[protected]
theorem adapted (hf : Martingale f ℱ μ) : Adapted ℱ f :=
  hf.1

@[protected]
theorem strongly_measurable (hf : Martingale f ℱ μ) (i : ι) : strongly_measurable[ℱ i] (f i) :=
  hf.Adapted i

theorem condexp_ae_eq (hf : Martingale f ℱ μ) {i j : ι} (hij : i ≤ j) : μ[f j|ℱ i] =ᵐ[μ] f i :=
  hf.2 i j hij

@[protected]
theorem integrable (hf : Martingale f ℱ μ) (i : ι) : Integrable (f i) μ :=
  integrable_condexp.congr (hf.condexp_ae_eq (le_reflₓ i))

theorem set_integral_eq [SigmaFiniteFiltration μ ℱ] (hf : Martingale f ℱ μ) {i j : ι} (hij : i ≤ j) {s : Set Ω}
    (hs : measurable_set[ℱ i] s) : (∫ x in s, f i x ∂μ) = ∫ x in s, f j x ∂μ := by
  rw [← @set_integral_condexp _ _ _ _ _ (ℱ i) m0 _ _ _ (ℱ.le i) _ (hf.integrable j) hs]
  refine' set_integral_congr_ae (ℱ.le i s hs) _
  filter_upwards [hf.2 i j hij] with _ heq _ using HEq.symm

theorem add (hf : Martingale f ℱ μ) (hg : Martingale g ℱ μ) : Martingale (f + g) ℱ μ := by
  refine' ⟨hf.adapted.add hg.adapted, fun i j hij => _⟩
  exact (condexp_add (hf.integrable j) (hg.integrable j)).trans ((hf.2 i j hij).add (hg.2 i j hij))

theorem neg (hf : Martingale f ℱ μ) : Martingale (-f) ℱ μ :=
  ⟨hf.Adapted.neg, fun i j hij => (condexp_neg (f j)).trans (hf.2 i j hij).neg⟩

theorem sub (hf : Martingale f ℱ μ) (hg : Martingale g ℱ μ) : Martingale (f - g) ℱ μ := by
  rw [sub_eq_add_neg]
  exact hf.add hg.neg

theorem smul (c : ℝ) (hf : Martingale f ℱ μ) : Martingale (c • f) ℱ μ := by
  refine' ⟨hf.adapted.smul c, fun i j hij => _⟩
  refine' (condexp_smul c (f j)).trans ((hf.2 i j hij).mono fun x hx => _)
  rw [Pi.smul_apply, hx, Pi.smul_apply, Pi.smul_apply]

theorem supermartingale [Preorderₓ E] (hf : Martingale f ℱ μ) : Supermartingale f ℱ μ :=
  ⟨hf.1, fun i j hij => (hf.2 i j hij).le, fun i => hf.Integrable i⟩

theorem submartingale [Preorderₓ E] (hf : Martingale f ℱ μ) : Submartingale f ℱ μ :=
  ⟨hf.1, fun i j hij => (hf.2 i j hij).symm.le, fun i => hf.Integrable i⟩

end Martingale

theorem martingale_iff [PartialOrderₓ E] : Martingale f ℱ μ ↔ Supermartingale f ℱ μ ∧ Submartingale f ℱ μ :=
  ⟨fun hf => ⟨hf.Supermartingale, hf.Submartingale⟩, fun ⟨hf₁, hf₂⟩ =>
    ⟨hf₁.1, fun i j hij => (hf₁.2.1 i j hij).antisymm (hf₂.2.1 i j hij)⟩⟩

theorem martingale_condexp (f : Ω → E) (ℱ : Filtration ι m0) (μ : Measure Ω) [SigmaFiniteFiltration μ ℱ] :
    Martingale (fun i => μ[f|ℱ i]) ℱ μ :=
  ⟨fun i => strongly_measurable_condexp, fun i j hij => condexp_condexp_of_le (ℱ.mono hij) (ℱ.le j)⟩

namespace Supermartingale

@[protected]
theorem adapted [LE E] (hf : Supermartingale f ℱ μ) : Adapted ℱ f :=
  hf.1

@[protected]
theorem strongly_measurable [LE E] (hf : Supermartingale f ℱ μ) (i : ι) : strongly_measurable[ℱ i] (f i) :=
  hf.Adapted i

@[protected]
theorem integrable [LE E] (hf : Supermartingale f ℱ μ) (i : ι) : Integrable (f i) μ :=
  hf.2.2 i

theorem condexp_ae_le [LE E] (hf : Supermartingale f ℱ μ) {i j : ι} (hij : i ≤ j) : μ[f j|ℱ i] ≤ᵐ[μ] f i :=
  hf.2.1 i j hij

theorem set_integral_le [SigmaFiniteFiltration μ ℱ] {f : ι → Ω → ℝ} (hf : Supermartingale f ℱ μ) {i j : ι} (hij : i ≤ j)
    {s : Set Ω} (hs : measurable_set[ℱ i] s) : (∫ x in s, f j x ∂μ) ≤ ∫ x in s, f i x ∂μ := by
  rw [← set_integral_condexp (ℱ.le i) (hf.integrable j) hs]
  refine' set_integral_mono_ae integrable_condexp.integrable_on (hf.integrable i).IntegrableOn _
  filter_upwards [hf.2.1 i j hij] with _ heq using HEq

theorem add [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Supermartingale f ℱ μ)
    (hg : Supermartingale g ℱ μ) : Supermartingale (f + g) ℱ μ := by
  refine' ⟨hf.1.add hg.1, fun i j hij => _, fun i => (hf.2.2 i).add (hg.2.2 i)⟩
  refine' (condexp_add (hf.integrable j) (hg.integrable j)).le.trans _
  filter_upwards [hf.2.1 i j hij, hg.2.1 i j hij]
  intros
  refine' add_le_add _ _ <;> assumption

theorem add_martingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Supermartingale f ℱ μ)
    (hg : Martingale g ℱ μ) : Supermartingale (f + g) ℱ μ :=
  hf.add hg.Supermartingale

theorem neg [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Supermartingale f ℱ μ) : Submartingale (-f) ℱ μ :=
  by
  refine' ⟨hf.1.neg, fun i j hij => _, fun i => (hf.2.2 i).neg⟩
  refine' eventually_le.trans _ (condexp_neg (f j)).symm.le
  filter_upwards [hf.2.1 i j hij] with _ _
  simpa

end Supermartingale

namespace Submartingale

@[protected]
theorem adapted [LE E] (hf : Submartingale f ℱ μ) : Adapted ℱ f :=
  hf.1

@[protected]
theorem strongly_measurable [LE E] (hf : Submartingale f ℱ μ) (i : ι) : strongly_measurable[ℱ i] (f i) :=
  hf.Adapted i

@[protected]
theorem integrable [LE E] (hf : Submartingale f ℱ μ) (i : ι) : Integrable (f i) μ :=
  hf.2.2 i

theorem ae_le_condexp [LE E] (hf : Submartingale f ℱ μ) {i j : ι} (hij : i ≤ j) : f i ≤ᵐ[μ] μ[f j|ℱ i] :=
  hf.2.1 i j hij

theorem add [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Submartingale f ℱ μ) (hg : Submartingale g ℱ μ) :
    Submartingale (f + g) ℱ μ := by
  refine' ⟨hf.1.add hg.1, fun i j hij => _, fun i => (hf.2.2 i).add (hg.2.2 i)⟩
  refine' eventually_le.trans _ (condexp_add (hf.integrable j) (hg.integrable j)).symm.le
  filter_upwards [hf.2.1 i j hij, hg.2.1 i j hij]
  intros
  refine' add_le_add _ _ <;> assumption

theorem add_martingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Submartingale f ℱ μ)
    (hg : Martingale g ℱ μ) : Submartingale (f + g) ℱ μ :=
  hf.add hg.Submartingale

theorem neg [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Submartingale f ℱ μ) : Supermartingale (-f) ℱ μ :=
  by
  refine' ⟨hf.1.neg, fun i j hij => (condexp_neg (f j)).le.trans _, fun i => (hf.2.2 i).neg⟩
  filter_upwards [hf.2.1 i j hij] with _ _
  simpa

/-- The converse of this lemma is `measure_theory.submartingale_of_set_integral_le`. -/
theorem set_integral_le [SigmaFiniteFiltration μ ℱ] {f : ι → Ω → ℝ} (hf : Submartingale f ℱ μ) {i j : ι} (hij : i ≤ j)
    {s : Set Ω} (hs : measurable_set[ℱ i] s) : (∫ x in s, f i x ∂μ) ≤ ∫ x in s, f j x ∂μ := by
  rw [← neg_le_neg_iff, ← integral_neg, ← integral_neg]
  exact supermartingale.set_integral_le hf.neg hij hs

theorem sub_supermartingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Submartingale f ℱ μ)
    (hg : Supermartingale g ℱ μ) : Submartingale (f - g) ℱ μ := by
  rw [sub_eq_add_neg]
  exact hf.add hg.neg

theorem sub_martingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Submartingale f ℱ μ)
    (hg : Martingale g ℱ μ) : Submartingale (f - g) ℱ μ :=
  hf.sub_supermartingale hg.Supermartingale

protected theorem sup {f g : ι → Ω → ℝ} (hf : Submartingale f ℱ μ) (hg : Submartingale g ℱ μ) :
    Submartingale (f⊔g) ℱ μ := by
  refine'
    ⟨fun i => @strongly_measurable.sup _ _ _ _ (ℱ i) _ _ _ (hf.adapted i) (hg.adapted i), fun i j hij => _, fun i =>
      integrable.sup (hf.integrable _) (hg.integrable _)⟩
  refine' eventually_le.sup_le _ _
  · exact
      eventually_le.trans (hf.2.1 i j hij)
        (condexp_mono (hf.integrable _) (integrable.sup (hf.integrable j) (hg.integrable j))
          (eventually_of_forall fun x => le_max_leftₓ _ _))
    
  · exact
      eventually_le.trans (hg.2.1 i j hij)
        (condexp_mono (hg.integrable _) (integrable.sup (hf.integrable j) (hg.integrable j))
          (eventually_of_forall fun x => le_max_rightₓ _ _))
    

protected theorem pos {f : ι → Ω → ℝ} (hf : Submartingale f ℱ μ) : Submartingale (f⁺) ℱ μ :=
  hf.sup (martingale_zero _ _ _).Submartingale

end Submartingale

section Submartingale

theorem submartingale_of_set_integral_le [IsFiniteMeasure μ] {f : ι → Ω → ℝ} (hadp : Adapted ℱ f)
    (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i j : ι, i ≤ j → ∀ s : Set Ω, measurable_set[ℱ i] s → (∫ x in s, f i x ∂μ) ≤ ∫ x in s, f j x ∂μ) :
    Submartingale f ℱ μ := by
  refine' ⟨hadp, fun i j hij => _, hint⟩
  suffices f i ≤ᵐ[μ.trim (ℱ.le i)] μ[f j|ℱ i] by
    exact ae_le_of_ae_le_trim this
  suffices 0 ≤ᵐ[μ.trim (ℱ.le i)] μ[f j|ℱ i] - f i by
    filter_upwards [this] with x hx
    rwa [← sub_nonneg]
  refine'
    ae_nonneg_of_forall_set_integral_nonneg
      ((integrable_condexp.sub (hint i)).trim _ (strongly_measurable_condexp.sub <| hadp i)) fun s hs h's => _
  specialize hf i j hij s hs
  rwa [← set_integral_trim _ (strongly_measurable_condexp.sub <| hadp i) hs,
    integral_sub' integrable_condexp.integrable_on (hint i).IntegrableOn, sub_nonneg,
    set_integral_condexp (ℱ.le i) (hint j) hs]

theorem submartingale_of_condexp_sub_nonneg [IsFiniteMeasure μ] {f : ι → Ω → ℝ} (hadp : Adapted ℱ f)
    (hint : ∀ i, Integrable (f i) μ) (hf : ∀ i j, i ≤ j → 0 ≤ᵐ[μ] μ[f j - f i|ℱ i]) : Submartingale f ℱ μ := by
  refine' ⟨hadp, fun i j hij => _, hint⟩
  rw [← condexp_of_strongly_measurable (ℱ.le _) (hadp _) (hint _), ← eventually_sub_nonneg]
  exact eventually_le.trans (hf i j hij) (condexp_sub (hint _) (hint _)).le
  infer_instance

theorem Submartingale.condexp_sub_nonneg {f : ι → Ω → ℝ} (hf : Submartingale f ℱ μ) {i j : ι} (hij : i ≤ j) :
    0 ≤ᵐ[μ] μ[f j - f i|ℱ i] := by
  by_cases' h : sigma_finite (μ.trim (ℱ.le i))
  swap
  · rw [condexp_of_not_sigma_finite (ℱ.le i) h]
    
  refine' eventually_le.trans _ (condexp_sub (hf.integrable _) (hf.integrable _)).symm.le
  rw [eventually_sub_nonneg, condexp_of_strongly_measurable (ℱ.le _) (hf.adapted _) (hf.integrable _)]
  · exact hf.2.1 i j hij
    
  · exact h
    

theorem submartingale_iff_condexp_sub_nonneg [IsFiniteMeasure μ] {f : ι → Ω → ℝ} :
    Submartingale f ℱ μ ↔ Adapted ℱ f ∧ (∀ i, Integrable (f i) μ) ∧ ∀ i j, i ≤ j → 0 ≤ᵐ[μ] μ[f j - f i|ℱ i] :=
  ⟨fun h => ⟨h.Adapted, h.Integrable, fun i j => h.condexp_sub_nonneg⟩, fun ⟨hadp, hint, h⟩ =>
    submartingale_of_condexp_sub_nonneg hadp hint h⟩

end Submartingale

namespace Supermartingale

theorem sub_submartingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Supermartingale f ℱ μ)
    (hg : Submartingale g ℱ μ) : Supermartingale (f - g) ℱ μ := by
  rw [sub_eq_add_neg]
  exact hf.add hg.neg

theorem sub_martingale [Preorderₓ E] [CovariantClass E E (· + ·) (· ≤ ·)] (hf : Supermartingale f ℱ μ)
    (hg : Martingale g ℱ μ) : Supermartingale (f - g) ℱ μ :=
  hf.sub_submartingale hg.Submartingale

section

variable {F : Type _} [NormedLatticeAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F] [OrderedSmul ℝ F]

theorem smul_nonneg {f : ι → Ω → F} {c : ℝ} (hc : 0 ≤ c) (hf : Supermartingale f ℱ μ) : Supermartingale (c • f) ℱ μ :=
  by
  refine' ⟨hf.1.smul c, fun i j hij => _, fun i => (hf.2.2 i).smul c⟩
  refine' (condexp_smul c (f j)).le.trans _
  filter_upwards [hf.2.1 i j hij] with _ hle
  simp
  exact smul_le_smul_of_nonneg hle hc

theorem smul_nonpos {f : ι → Ω → F} {c : ℝ} (hc : c ≤ 0) (hf : Supermartingale f ℱ μ) : Submartingale (c • f) ℱ μ := by
  rw [← neg_negₓ c,
    (by
      ext i x
      simp : - -c • f = -(-c • f))]
  exact (hf.smul_nonneg <| neg_nonneg.2 hc).neg

end

end Supermartingale

namespace Submartingale

section

variable {F : Type _} [NormedLatticeAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F] [OrderedSmul ℝ F]

theorem smul_nonneg {f : ι → Ω → F} {c : ℝ} (hc : 0 ≤ c) (hf : Submartingale f ℱ μ) : Submartingale (c • f) ℱ μ := by
  rw [← neg_negₓ c,
    (by
      ext i x
      simp : - -c • f = -(c • -f))]
  exact supermartingale.neg (hf.neg.smul_nonneg hc)

theorem smul_nonpos {f : ι → Ω → F} {c : ℝ} (hc : c ≤ 0) (hf : Submartingale f ℱ μ) : Supermartingale (c • f) ℱ μ := by
  rw [← neg_negₓ c,
    (by
      ext i x
      simp : - -c • f = -(-c • f))]
  exact (hf.smul_nonneg <| neg_nonneg.2 hc).neg

end

end Submartingale

section Nat

variable {𝒢 : Filtration ℕ m0}

theorem submartingale_of_set_integral_le_succ [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, ∀ s : Set Ω, measurable_set[𝒢 i] s → (∫ x in s, f i x ∂μ) ≤ ∫ x in s, f (i + 1) x ∂μ) :
    Submartingale f 𝒢 μ := by
  refine' submartingale_of_set_integral_le hadp hint fun i j hij s hs => _
  induction' hij with k hk₁ hk₂
  · exact le_rflₓ
    
  · exact le_transₓ hk₂ (hf k s (𝒢.mono hk₁ _ hs))
    

theorem supermartingale_of_set_integral_succ_le [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, ∀ s : Set Ω, measurable_set[𝒢 i] s → (∫ x in s, f (i + 1) x ∂μ) ≤ ∫ x in s, f i x ∂μ) :
    Supermartingale f 𝒢 μ := by
  rw [← neg_negₓ f]
  refine' (submartingale_of_set_integral_le_succ hadp.neg (fun i => (hint i).neg) _).neg
  simpa only [integral_neg, Pi.neg_apply, neg_le_neg_iff]

theorem martingale_of_set_integral_eq_succ [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, ∀ s : Set Ω, measurable_set[𝒢 i] s → (∫ x in s, f i x ∂μ) = ∫ x in s, f (i + 1) x ∂μ) :
    Martingale f 𝒢 μ :=
  martingale_iff.2
    ⟨(supermartingale_of_set_integral_succ_le hadp hint) fun i s hs => (hf i s hs).Ge,
      (submartingale_of_set_integral_le_succ hadp hint) fun i s hs => (hf i s hs).le⟩

theorem submartingale_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f) (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, f i ≤ᵐ[μ] μ[f (i + 1)|𝒢 i]) : Submartingale f 𝒢 μ := by
  refine' submartingale_of_set_integral_le_succ hadp hint fun i s hs => _
  have : (∫ x in s, f (i + 1) x ∂μ) = ∫ x in s, (μ[f (i + 1)|𝒢 i]) x ∂μ :=
    (set_integral_condexp (𝒢.le i) (hint _) hs).symm
  rw [this]
  exact set_integral_mono_ae (hint i).IntegrableOn integrable_condexp.integrable_on (hf i)

theorem supermartingale_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f) (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, μ[f (i + 1)|𝒢 i] ≤ᵐ[μ] f i) : Supermartingale f 𝒢 μ := by
  rw [← neg_negₓ f]
  refine'
    ((submartingale_nat hadp.neg fun i => (hint i).neg) fun i => eventually_le.trans _ (condexp_neg _).symm.le).neg
  filter_upwards [hf i] with x hx using neg_le_neg hx

theorem martingale_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f) (hint : ∀ i, Integrable (f i) μ)
    (hf : ∀ i, f i =ᵐ[μ] μ[f (i + 1)|𝒢 i]) : Martingale f 𝒢 μ :=
  martingale_iff.2
    ⟨(supermartingale_nat hadp hint) fun i => (hf i).symm.le, (submartingale_nat hadp hint) fun i => (hf i).le⟩

theorem submartingale_of_condexp_sub_nonneg_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ) (hf : ∀ i, 0 ≤ᵐ[μ] μ[f (i + 1) - f i|𝒢 i]) : Submartingale f 𝒢 μ := by
  refine' submartingale_nat hadp hint fun i => _
  rw [← condexp_of_strongly_measurable (𝒢.le _) (hadp _) (hint _), ← eventually_sub_nonneg]
  exact eventually_le.trans (hf i) (condexp_sub (hint _) (hint _)).le
  infer_instance

theorem supermartingale_of_condexp_sub_nonneg_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ) (hf : ∀ i, 0 ≤ᵐ[μ] μ[f i - f (i + 1)|𝒢 i]) : Supermartingale f 𝒢 μ := by
  rw [← neg_negₓ f]
  refine' (submartingale_of_condexp_sub_nonneg_nat hadp.neg (fun i => (hint i).neg) _).neg
  simpa only [Pi.zero_apply, Pi.neg_apply, neg_sub_neg]

theorem martingale_of_condexp_sub_eq_zero_nat [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ) (hf : ∀ i, μ[f (i + 1) - f i|𝒢 i] =ᵐ[μ] 0) : Martingale f 𝒢 μ := by
  refine'
    martingale_iff.2
      ⟨(supermartingale_of_condexp_sub_nonneg_nat hadp hint) fun i => _,
        (submartingale_of_condexp_sub_nonneg_nat hadp hint) fun i => (hf i).symm.le⟩
  rw [← neg_sub]
  refine' (eventually_eq.trans _ (condexp_neg _).symm).le
  filter_upwards [hf i] with x hx
  simpa only [Pi.zero_apply, Pi.neg_apply, zero_eq_neg]

namespace Submartingale

theorem integrable_stopped_value [LE E] {f : ℕ → Ω → E} (hf : Submartingale f 𝒢 μ) {τ : Ω → ℕ} (hτ : IsStoppingTime 𝒢 τ)
    {N : ℕ} (hbdd : ∀ x, τ x ≤ N) : Integrable (stoppedValue f τ) μ :=
  integrable_stopped_value hτ hf.Integrable hbdd

-- We may generalize the below lemma to functions taking value in a `normed_lattice_add_comm_group`.
-- Similarly, generalize `(super/)submartingale.set_integral_le`.
/-- Given a submartingale `f` and bounded stopping times `τ` and `π` such that `τ ≤ π`, the
expectation of `stopped_value f τ` is less than or equal to the expectation of `stopped_value f π`.
This is the forward direction of the optional stopping theorem. -/
theorem expected_stopped_value_mono [SigmaFiniteFiltration μ 𝒢] {f : ℕ → Ω → ℝ} (hf : Submartingale f 𝒢 μ) {τ π : Ω → ℕ}
    (hτ : IsStoppingTime 𝒢 τ) (hπ : IsStoppingTime 𝒢 π) (hle : τ ≤ π) {N : ℕ} (hbdd : ∀ x, π x ≤ N) :
    μ[stoppedValue f τ] ≤ μ[stoppedValue f π] := by
  rw [← sub_nonneg, ← integral_sub', stopped_value_sub_eq_sum' hle hbdd]
  · simp only [Finset.sum_apply]
    have : ∀ i, measurable_set[𝒢 i] { ω : Ω | τ ω ≤ i ∧ i < π ω } := by
      intro i
      refine' (hτ i).inter _
      convert (hπ i).compl
      ext x
      simpa
    rw [integral_finset_sum]
    · refine' Finset.sum_nonneg fun i hi => _
      rw [integral_indicator (𝒢.le _ _ (this _)), integral_sub', sub_nonneg]
      · exact hf.set_integral_le (Nat.le_succₓ i) (this _)
        
      · exact (hf.integrable _).IntegrableOn
        
      · exact (hf.integrable _).IntegrableOn
        
      
    intro i hi
    exact integrable.indicator (integrable.sub (hf.integrable _) (hf.integrable _)) (𝒢.le _ _ (this _))
    
  · exact hf.integrable_stopped_value hπ hbdd
    
  · exact hf.integrable_stopped_value hτ fun x => le_transₓ (hle x) (hbdd x)
    

end Submartingale

/-- The converse direction of the optional stopping theorem, i.e. an adapted integrable process `f`
is a submartingale if for all bounded stopping times `τ` and `π` such that `τ ≤ π`, the
stopped value of `f` at `τ` has expectation smaller than its stopped value at `π`. -/
theorem submartingale_of_expected_stopped_value_mono [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ)
    (hf :
      ∀ τ π : Ω → ℕ,
        IsStoppingTime 𝒢 τ →
          IsStoppingTime 𝒢 π → τ ≤ π → (∃ N, ∀ x, π x ≤ N) → μ[stoppedValue f τ] ≤ μ[stoppedValue f π]) :
    Submartingale f 𝒢 μ := by
  refine' submartingale_of_set_integral_le hadp hint fun i j hij s hs => _
  classical
  specialize
    hf (s.piecewise (fun _ => i) fun _ => j) _ (is_stopping_time_piecewise_const hij hs) (is_stopping_time_const 𝒢 j)
      (fun x => (ite_le_sup _ _ _).trans (max_eq_rightₓ hij).le) ⟨j, fun x => le_rflₓ⟩
  rwa [stopped_value_const, stopped_value_piecewise_const,
    integral_piecewise (𝒢.le _ _ hs) (hint _).IntegrableOn (hint _).IntegrableOn, ←
    integral_add_compl (𝒢.le _ _ hs) (hint j), add_le_add_iff_right] at hf

/-- **The optional stopping theorem** (fair game theorem): an adapted integrable process `f`
is a submartingale if and only if for all bounded stopping times `τ` and `π` such that `τ ≤ π`, the
stopped value of `f` at `τ` has expectation smaller than its stopped value at `π`. -/
theorem submartingale_iff_expected_stopped_value_mono [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hadp : Adapted 𝒢 f)
    (hint : ∀ i, Integrable (f i) μ) :
    Submartingale f 𝒢 μ ↔
      ∀ τ π : Ω → ℕ,
        IsStoppingTime 𝒢 τ →
          IsStoppingTime 𝒢 π → τ ≤ π → (∃ N, ∀ x, π x ≤ N) → μ[stoppedValue f τ] ≤ μ[stoppedValue f π] :=
  ⟨fun hf _ _ hτ hπ hle ⟨N, hN⟩ => hf.expected_stopped_value_mono hτ hπ hle hN,
    submartingale_of_expected_stopped_value_mono hadp hint⟩

/-- The stopped process of a submartingale with respect to a stopping time is a submartingale. -/
@[protected]
theorem Submartingale.stopped_process [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (h : Submartingale f 𝒢 μ) {τ : Ω → ℕ}
    (hτ : IsStoppingTime 𝒢 τ) : Submartingale (stoppedProcess f τ) 𝒢 μ := by
  rw [submartingale_iff_expected_stopped_value_mono]
  · intro σ π hσ hπ hσ_le_π hπ_bdd
    simp_rw [stopped_value_stopped_process]
    obtain ⟨n, hπ_le_n⟩ := hπ_bdd
    exact
      h.expected_stopped_value_mono (hσ.min hτ) (hπ.min hτ) (fun ω => min_le_min (hσ_le_π ω) le_rflₓ) fun ω =>
        (min_le_leftₓ _ _).trans (hπ_le_n ω)
    
  · exact adapted.stopped_process_of_nat h.adapted hτ
    
  · exact fun i => integrable_stopped_value ((is_stopping_time_const _ i).min hτ) h.integrable fun ω => min_le_leftₓ _ _
    

section Maximal

open Finset

theorem smul_le_stopped_value_hitting [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hsub : Submartingale f 𝒢 μ) {ε : ℝ≥0 }
    (n : ℕ) :
    ε • μ { x | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x } ≤
      Ennreal.ofReal
        (∫ x in { x | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x },
          stoppedValue f (hitting f { y : ℝ | ↑ε ≤ y } 0 n) x ∂μ) :=
  by
  have hn : Set.Icc 0 n = { k | k ≤ n } := by
    ext x
    simp
  have :
    ∀ x,
      ((ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x) →
        (ε : ℝ) ≤ stopped_value f (hitting f { y : ℝ | ↑ε ≤ y } 0 n) x :=
    by
    intro x hx
    simp_rw [le_sup'_iff, mem_range, Nat.lt_succ_iffₓ] at hx
    refine' stopped_value_hitting_mem _
    simp only [Set.mem_set_of_eq, exists_prop, hn]
    exact
      let ⟨j, hj₁, hj₂⟩ := hx
      ⟨j, hj₁, hj₂⟩
  have h :=
    set_integral_ge_of_const_le
      (measurable_set_le measurable_const
        (Finset.measurable_range_sup'' fun n _ => (hsub.strongly_measurable n).Measurable.le (𝒢.le n)))
      (measure_ne_top _ _) this
      (integrable.integrable_on
        (integrable_stopped_value (hitting_is_stopping_time hsub.adapted measurable_set_Ici) hsub.integrable
          hitting_le))
  rw [Ennreal.le_of_real_iff_to_real_le, Ennreal.to_real_smul]
  · exact h
    
  · exact
      Ennreal.mul_ne_top
        (by
          simp )
        (measure_ne_top _ _)
    
  · exact le_transₓ (mul_nonneg ε.coe_nonneg Ennreal.to_real_nonneg) h
    

/-- **Doob's maximal inequality**: Given a non-negative submartingale `f`, for all `ε : ℝ≥0`,
we have `ε • μ {ε ≤ f* n} ≤ ∫ x in {ε ≤ f* n}, f n` where `f* n x = max_{k ≤ n}, f k x`.

In some literature, the Doob's maximal inequality refers to what we call Doob's Lp inequality
(which is a corollary of this lemma and will be proved in an upcomming PR). -/
theorem maximal_ineq [IsFiniteMeasure μ] {f : ℕ → Ω → ℝ} (hsub : Submartingale f 𝒢 μ) (hnonneg : 0 ≤ f) {ε : ℝ≥0 }
    (n : ℕ) :
    ε • μ { x | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x } ≤
      Ennreal.ofReal (∫ x in { x | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x }, f n x ∂μ) :=
  by
  suffices
    ε • μ { x | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k x } +
        Ennreal.ofReal (∫ x in { x | ((range (n + 1)).sup' nonempty_range_succ fun k => f k x) < ε }, f n x ∂μ) ≤
      Ennreal.ofReal (μ[f n])
    by
    have hadd :
      Ennreal.ofReal (∫ ω, f n ω ∂μ) =
        Ennreal.ofReal (∫ ω in { ω | ↑ε ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k ω }, f n ω ∂μ) +
          Ennreal.ofReal (∫ ω in { ω | ((range (n + 1)).sup' nonempty_range_succ fun k => f k ω) < ↑ε }, f n ω ∂μ) :=
      by
      rw [← Ennreal.of_real_add, ← integral_union]
      · conv_lhs => rw [← integral_univ]
        convert rfl
        ext ω
        change (ε : ℝ) ≤ _ ∨ _ < (ε : ℝ) ↔ _
        simp only [le_or_ltₓ, true_iffₓ]
        
      · rintro ω ⟨hω₁ : _ ≤ _, hω₂ : _ < _⟩
        exact (not_leₓ.2 hω₂) hω₁
        
      · exact
          measurable_set_lt
            (Finset.measurable_range_sup'' fun n _ => (hsub.strongly_measurable n).Measurable.le (𝒢.le n))
            measurable_const
        
      exacts[(hsub.integrable _).IntegrableOn, (hsub.integrable _).IntegrableOn, integral_nonneg (hnonneg _),
        integral_nonneg (hnonneg _)]
    rwa [hadd, Ennreal.add_le_add_iff_right Ennreal.of_real_ne_top] at this
  calc
    ε • μ { ω | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k ω } +
          Ennreal.ofReal (∫ ω in { ω | ((range (n + 1)).sup' nonempty_range_succ fun k => f k ω) < ε }, f n ω ∂μ) ≤
        Ennreal.ofReal
            (∫ ω in { ω | (ε : ℝ) ≤ (range (n + 1)).sup' nonempty_range_succ fun k => f k ω },
              stopped_value f (hitting f { y : ℝ | ↑ε ≤ y } 0 n) ω ∂μ) +
          Ennreal.ofReal
            (∫ ω in { ω | ((range (n + 1)).sup' nonempty_range_succ fun k => f k ω) < ε },
              stopped_value f (hitting f { y : ℝ | ↑ε ≤ y } 0 n) ω ∂μ) :=
      by
      refine'
        add_le_add (smul_le_stopped_value_hitting hsub _)
          (Ennreal.of_real_le_of_real
            (set_integral_mono_on (hsub.integrable n).IntegrableOn
              (integrable.integrable_on
                (integrable_stopped_value (hitting_is_stopping_time hsub.adapted measurable_set_Ici) hsub.integrable
                  hitting_le))
              (measurable_set_lt
                (Finset.measurable_range_sup'' fun n _ => (hsub.strongly_measurable n).Measurable.le (𝒢.le n))
                measurable_const)
              _))
      intro ω hω
      rw [Set.mem_set_of_eq] at hω
      have : hitting f { y : ℝ | ↑ε ≤ y } 0 n ω = n := by
        simp only [hitting, Set.mem_set_of_eq, exists_prop, Pi.coe_nat, Nat.cast_id, ite_eq_right_iff,
          forall_exists_index, and_imp]
        intro m hm hεm
        exact False.elim ((not_leₓ.2 hω) ((le_sup'_iff _).2 ⟨m, mem_range.2 (Nat.lt_succ_of_leₓ hm.2), hεm⟩))
      simp_rw [stopped_value, this]
    _ = Ennreal.ofReal (∫ ω, stopped_value f (hitting f { y : ℝ | ↑ε ≤ y } 0 n) ω ∂μ) := by
      rw [← Ennreal.of_real_add, ← integral_union]
      · conv_rhs => rw [← integral_univ]
        convert rfl
        ext ω
        change _ ↔ (ε : ℝ) ≤ _ ∨ _ < (ε : ℝ)
        simp only [le_or_ltₓ, iff_trueₓ]
        
      · rintro ω ⟨hω₁ : _ ≤ _, hω₂ : _ < _⟩
        exact (not_leₓ.2 hω₂) hω₁
        
      · exact
          measurable_set_lt
            (Finset.measurable_range_sup'' fun n _ => (hsub.strongly_measurable n).Measurable.le (𝒢.le n))
            measurable_const
        
      · exact
          integrable.integrable_on
            (integrable_stopped_value (hitting_is_stopping_time hsub.adapted measurable_set_Ici) hsub.integrable
              hitting_le)
        
      · exact
          integrable.integrable_on
            (integrable_stopped_value (hitting_is_stopping_time hsub.adapted measurable_set_Ici) hsub.integrable
              hitting_le)
        
      exacts[integral_nonneg fun x => hnonneg _ _, integral_nonneg fun x => hnonneg _ _]
    _ ≤ Ennreal.ofReal (μ[f n]) := by
      refine' Ennreal.of_real_le_of_real _
      rw [← stopped_value_const f n]
      exact
        hsub.expected_stopped_value_mono (hitting_is_stopping_time hsub.adapted measurable_set_Ici)
          (is_stopping_time_const _ _) (fun ω => hitting_le ω) (fun ω => le_rflₓ : ∀ ω, n ≤ n)
    

end Maximal

theorem Submartingale.sum_mul_sub [IsFiniteMeasure μ] {R : ℝ} {ξ f : ℕ → Ω → ℝ} (hf : Submartingale f 𝒢 μ)
    (hξ : Adapted 𝒢 ξ) (hbdd : ∀ n ω, ξ n ω ≤ R) (hnonneg : ∀ n ω, 0 ≤ ξ n ω) :
    Submartingale (fun n => ∑ k in Finset.range n, ξ k * (f (k + 1) - f k)) 𝒢 μ := by
  have hξbdd : ∀ i, ∃ C, ∀ ω, abs (ξ i ω) ≤ C := fun i =>
    ⟨R, fun ω => (abs_of_nonneg (hnonneg i ω)).trans_le (hbdd i ω)⟩
  have hint : ∀ m, integrable (∑ k in Finset.range m, ξ k * (f (k + 1) - f k)) μ := fun m =>
    integrable_finset_sum' _ fun i hi =>
      integrable.bdd_mul ((hf.integrable _).sub (hf.integrable _)) hξ.strongly_measurable.ae_strongly_measurable
        (hξbdd _)
  have hadp : adapted 𝒢 fun n => ∑ k in Finset.range n, ξ k * (f (k + 1) - f k) := by
    intro m
    refine' Finset.strongly_measurable_sum' _ fun i hi => _
    rw [Finset.mem_range] at hi
    exact
      (hξ.strongly_measurable_le hi.le).mul
        ((hf.adapted.strongly_measurable_le (Nat.succ_le_of_ltₓ hi)).sub (hf.adapted.strongly_measurable_le hi.le))
  refine' submartingale_of_condexp_sub_nonneg_nat hadp hint fun i => _
  simp only [← Finset.sum_Ico_eq_sub _ (Nat.le_succₓ _), Finset.sum_apply, Pi.mul_apply, Pi.sub_apply,
    Nat.Ico_succ_singleton, Finset.sum_singleton]
  exact
    eventually_le.trans
      (eventually_le.mul_nonneg (eventually_of_forall (hnonneg _)) (hf.condexp_sub_nonneg (Nat.le_succₓ _)))
      (condexp_strongly_measurable_mul (hξ _)
            (((hf.integrable _).sub (hf.integrable _)).bdd_mul hξ.strongly_measurable.ae_strongly_measurable (hξbdd _))
            ((hf.integrable _).sub (hf.integrable _))).symm.le

/-- Given a discrete submartingale `f` and a predictable process `ξ` (i.e. `ξ (n + 1)` is adapted)
the process defined by `λ n, ∑ k in finset.range n, ξ (k + 1) * (f (k + 1) - f k)` is also a
submartingale. -/
theorem Submartingale.sum_mul_sub' [IsFiniteMeasure μ] {R : ℝ} {ξ f : ℕ → Ω → ℝ} (hf : Submartingale f 𝒢 μ)
    (hξ : Adapted 𝒢 fun n => ξ (n + 1)) (hbdd : ∀ n ω, ξ n ω ≤ R) (hnonneg : ∀ n ω, 0 ≤ ξ n ω) :
    Submartingale (fun n => ∑ k in Finset.range n, ξ (k + 1) * (f (k + 1) - f k)) 𝒢 μ :=
  hf.sum_mul_sub hξ (fun n => hbdd _) fun n => hnonneg _

end Nat

end MeasureTheory

