import Mathbin.MeasureTheory.Integral.SetToL1 
import Mathbin.MeasureTheory.Group.Basic 
import Mathbin.Analysis.NormedSpace.BoundedLinearMaps 
import Mathbin.Topology.Sequences

/-!
# Bochner integral

The Bochner integral extends the definition of the Lebesgue integral to functions that map from a
measure space into a Banach space (complete normed vector space). It is constructed here by
extending the integral on simple functions.

## Main definitions

The Bochner integral is defined through the extension process described in the file `set_to_L1`,
which follows these steps:

1. Define the integral of the indicator of a set. This is `weighted_smul μ s x = (μ s).to_real * x`.
  `weighted_smul μ` is shown to be linear in the value `x` and `dominated_fin_meas_additive`
  (defined in the file `set_to_L1`) with respect to the set `s`.

2. Define the integral on simple functions of the type `simple_func α E` (notation : `α →ₛ E`)
  where `E` is a real normed space. (See `simple_func.integral` for details.)

3. Transfer this definition to define the integral on `L1.simple_func α E` (notation :
  `α →₁ₛ[μ] E`), see `L1.simple_func.integral`. Show that this integral is a continuous linear
  map from `α →₁ₛ[μ] E` to `E`.

4. Define the Bochner integral on L1 functions by extending the integral on integrable simple
  functions `α →₁ₛ[μ] E` using `continuous_linear_map.extend` and the fact that the embedding of
  `α →₁ₛ[μ] E` into `α →₁[μ] E` is dense.

5. Define the Bochner integral on functions as the Bochner integral of its equivalence class in L1
  space, if it is in L1, and 0 otherwise.

The result of that construction is `∫ a, f a ∂μ`, which is definitionally equal to
`set_to_fun (dominated_fin_meas_additive_weighted_smul μ) f`. Some basic properties of the integral
(like linearity) are particular cases of the properties of `set_to_fun` (which are described in the
file `set_to_L1`).

## Main statements

1. Basic properties of the Bochner integral on functions of type `α → E`, where `α` is a measure
   space and `E` is a real normed space.

  * `integral_zero`                  : `∫ 0 ∂μ = 0`
  * `integral_add`                   : `∫ x, f x + g x ∂μ = ∫ x, f ∂μ + ∫ x, g x ∂μ`
  * `integral_neg`                   : `∫ x, - f x ∂μ = - ∫ x, f x ∂μ`
  * `integral_sub`                   : `∫ x, f x - g x ∂μ = ∫ x, f x ∂μ - ∫ x, g x ∂μ`
  * `integral_smul`                  : `∫ x, r • f x ∂μ = r • ∫ x, f x ∂μ`
  * `integral_congr_ae`              : `f =ᵐ[μ] g → ∫ x, f x ∂μ = ∫ x, g x ∂μ`
  * `norm_integral_le_integral_norm` : `∥∫ x, f x ∂μ∥ ≤ ∫ x, ∥f x∥ ∂μ`

2. Basic properties of the Bochner integral on functions of type `α → ℝ`, where `α` is a measure
  space.

  * `integral_nonneg_of_ae` : `0 ≤ᵐ[μ] f → 0 ≤ ∫ x, f x ∂μ`
  * `integral_nonpos_of_ae` : `f ≤ᵐ[μ] 0 → ∫ x, f x ∂μ ≤ 0`
  * `integral_mono_ae`      : `f ≤ᵐ[μ] g → ∫ x, f x ∂μ ≤ ∫ x, g x ∂μ`
  * `integral_nonneg`       : `0 ≤ f → 0 ≤ ∫ x, f x ∂μ`
  * `integral_nonpos`       : `f ≤ 0 → ∫ x, f x ∂μ ≤ 0`
  * `integral_mono`         : `f ≤ᵐ[μ] g → ∫ x, f x ∂μ ≤ ∫ x, g x ∂μ`

3. Propositions connecting the Bochner integral with the integral on `ℝ≥0∞`-valued functions,
   which is called `lintegral` and has the notation `∫⁻`.

  * `integral_eq_lintegral_max_sub_lintegral_min` : `∫ x, f x ∂μ = ∫⁻ x, f⁺ x ∂μ - ∫⁻ x, f⁻ x ∂μ`,
    where `f⁺` is the positive part of `f` and `f⁻` is the negative part of `f`.
  * `integral_eq_lintegral_of_nonneg_ae`          : `0 ≤ᵐ[μ] f → ∫ x, f x ∂μ = ∫⁻ x, f x ∂μ`

4. `tendsto_integral_of_dominated_convergence` : the Lebesgue dominated convergence theorem

5. (In the file `set_integral`) integration commutes with continuous linear maps.

  * `continuous_linear_map.integral_comp_comm`
  * `linear_isometry.integral_comp_comm`


## Notes

Some tips on how to prove a proposition if the API for the Bochner integral is not enough so that
you need to unfold the definition of the Bochner integral and go back to simple functions.

One method is to use the theorem `integrable.induction` in the file `simple_func_dense` (or one of
the related results, like `Lp.induction` for functions in `Lp`), which allows you to prove something
for an arbitrary measurable + integrable function.

Another method is using the following steps.
See `integral_eq_lintegral_max_sub_lintegral_min` for a complicated example, which proves that
`∫ f = ∫⁻ f⁺ - ∫⁻ f⁻`, with the first integral sign being the Bochner integral of a real-valued
function `f : α → ℝ`, and second and third integral sign being the integral on `ℝ≥0∞`-valued
functions (called `lintegral`). The proof of `integral_eq_lintegral_max_sub_lintegral_min` is
scattered in sections with the name `pos_part`.

Here are the usual steps of proving that a property `p`, say `∫ f = ∫⁻ f⁺ - ∫⁻ f⁻`, holds for all
functions :

1. First go to the `L¹` space.

   For example, if you see `ennreal.to_real (∫⁻ a, ennreal.of_real $ ∥f a∥)`, that is the norm of
   `f` in `L¹` space. Rewrite using `L1.norm_of_fun_eq_lintegral_norm`.

2. Show that the set `{f ∈ L¹ | ∫ f = ∫⁻ f⁺ - ∫⁻ f⁻}` is closed in `L¹` using `is_closed_eq`.

3. Show that the property holds for all simple functions `s` in `L¹` space.

   Typically, you need to convert various notions to their `simple_func` counterpart, using lemmas
   like `L1.integral_coe_eq_integral`.

4. Since simple functions are dense in `L¹`,
```
univ = closure {s simple}
     = closure {s simple | ∫ s = ∫⁻ s⁺ - ∫⁻ s⁻} : the property holds for all simple functions
     ⊆ closure {f | ∫ f = ∫⁻ f⁺ - ∫⁻ f⁻}
     = {f | ∫ f = ∫⁻ f⁺ - ∫⁻ f⁻} : closure of a closed set is itself
```
Use `is_closed_property` or `dense_range.induction_on` for this argument.

## Notations

* `α →ₛ E`  : simple functions (defined in `measure_theory/integration`)
* `α →₁[μ] E` : functions in L1 space, i.e., equivalence classes of integrable functions (defined in
                `measure_theory/lp_space`)
* `α →₁ₛ[μ] E` : simple functions in L1 space, i.e., equivalence classes of integrable simple
                 functions (defined in `measure_theory/simple_func_dense`)
* `∫ a, f a ∂μ` : integral of `f` with respect to a measure `μ`
* `∫ a, f a` : integral of `f` with respect to `volume`, the default measure on the ambient type

We also define notations for integral on a set, which are described in the file
`measure_theory/set_integral`.

Note : `ₛ` is typed using `\_s`. Sometimes it shows as a box if the font is missing.

## Tags

Bochner integral, simple function, function space, Lebesgue dominated convergence theorem

-/


noncomputable theory

open_locale Classical TopologicalSpace BigOperators Nnreal Ennreal MeasureTheory

open Set Filter TopologicalSpace Ennreal Emetric

attribute [local instance] fact_one_le_one_ennreal

namespace MeasureTheory

variable{α E F 𝕜 : Type _}

section WeightedSmul

open ContinuousLinearMap

variable[NormedGroup F][NormedSpace ℝ F]{m : MeasurableSpace α}{μ : Measureₓ α}

/-- Given a set `s`, return the continuous linear map `λ x, (μ s).to_real • x`. The extension of
that set function through `set_to_L1` gives the Bochner integral of L1 functions. -/
def weighted_smul {m : MeasurableSpace α} (μ : Measureₓ α) (s : Set α) : F →L[ℝ] F :=
  (μ s).toReal • ContinuousLinearMap.id ℝ F

theorem weighted_smul_apply {m : MeasurableSpace α} (μ : Measureₓ α) (s : Set α) (x : F) :
  weighted_smul μ s x = (μ s).toReal • x :=
  by 
    simp [weighted_smul]

@[simp]
theorem weighted_smul_zero_measure {m : MeasurableSpace α} : weighted_smul (0 : Measureₓ α) = (0 : Set α → F →L[ℝ] F) :=
  by 
    ext1 
    simp [weighted_smul]

@[simp]
theorem weighted_smul_empty {m : MeasurableSpace α} (μ : Measureₓ α) : weighted_smul μ ∅ = (0 : F →L[ℝ] F) :=
  by 
    ext1 x 
    rw [weighted_smul_apply]
    simp 

theorem weighted_smul_add_measure {m : MeasurableSpace α} (μ ν : Measureₓ α) {s : Set α} (hμs : μ s ≠ ∞)
  (hνs : ν s ≠ ∞) : (weighted_smul (μ+ν) s : F →L[ℝ] F) = weighted_smul μ s+weighted_smul ν s :=
  by 
    ext1 x 
    pushCast 
    simpRw [Pi.add_apply, weighted_smul_apply]
    pushCast 
    rw [Pi.add_apply, Ennreal.to_real_add hμs hνs, add_smul]

theorem weighted_smul_congr (s t : Set α) (hst : μ s = μ t) : (weighted_smul μ s : F →L[ℝ] F) = weighted_smul μ t :=
  by 
    ext1 x 
    simpRw [weighted_smul_apply]
    congr 2

theorem weighted_smul_null {s : Set α} (h_zero : μ s = 0) : (weighted_smul μ s : F →L[ℝ] F) = 0 :=
  by 
    ext1 x 
    rw [weighted_smul_apply, h_zero]
    simp 

theorem weighted_smul_union (s t : Set α) (hs : MeasurableSet s) (ht : MeasurableSet t) (hs_finite : μ s ≠ ∞)
  (ht_finite : μ t ≠ ∞) (h_inter : s ∩ t = ∅) :
  (weighted_smul μ (s ∪ t) : F →L[ℝ] F) = weighted_smul μ s+weighted_smul μ t :=
  by 
    ext1 x 
    simpRw [add_apply, weighted_smul_apply, measure_union (set.disjoint_iff_inter_eq_empty.mpr h_inter) hs ht,
      Ennreal.to_real_add hs_finite ht_finite, add_smul]

theorem weighted_smul_smul [NormedField 𝕜] [NormedSpace 𝕜 F] [SmulCommClass ℝ 𝕜 F] (c : 𝕜) (s : Set α) (x : F) :
  weighted_smul μ s (c • x) = c • weighted_smul μ s x :=
  by 
    simpRw [weighted_smul_apply, smul_comm]

theorem norm_weighted_smul_le (s : Set α) : ∥(weighted_smul μ s : F →L[ℝ] F)∥ ≤ (μ s).toReal :=
  calc ∥(weighted_smul μ s : F →L[ℝ] F)∥ = ∥(μ s).toReal∥*∥ContinuousLinearMap.id ℝ F∥ := norm_smul _ _ 
    _ ≤ ∥(μ s).toReal∥ := (mul_le_mul_of_nonneg_left norm_id_le (norm_nonneg _)).trans (mul_oneₓ _).le 
    _ = abs (μ s).toReal := Real.norm_eq_abs _ 
    _ = (μ s).toReal := abs_eq_self.mpr Ennreal.to_real_nonneg
    

theorem dominated_fin_meas_additive_weighted_smul {m : MeasurableSpace α} (μ : Measureₓ α) :
  dominated_fin_meas_additive μ (weighted_smul μ : Set α → F →L[ℝ] F) 1 :=
  ⟨weighted_smul_union, fun s => (norm_weighted_smul_le s).trans (one_mulₓ _).symm.le⟩

end WeightedSmul

local infixr:25 " →ₛ " => simple_func

namespace SimpleFunc

section PosPart

variable[LinearOrderₓ E][HasZero E][MeasurableSpace α]

/-- Positive part of a simple function. -/
def pos_part (f : α →ₛ E) : α →ₛ E :=
  f.map fun b => max b 0

/-- Negative part of a simple function. -/
def neg_part [Neg E] (f : α →ₛ E) : α →ₛ E :=
  pos_part (-f)

theorem pos_part_map_norm (f : α →ₛ ℝ) : (pos_part f).map norm = pos_part f :=
  by 
    ext 
    rw [map_apply, Real.norm_eq_abs, abs_of_nonneg]
    exact le_max_rightₓ _ _

theorem neg_part_map_norm (f : α →ₛ ℝ) : (neg_part f).map norm = neg_part f :=
  by 
    rw [neg_part]
    exact pos_part_map_norm _

theorem pos_part_sub_neg_part (f : α →ₛ ℝ) : f.pos_part - f.neg_part = f :=
  by 
    simp only [pos_part, neg_part]
    ext a 
    rw [coe_sub]
    exact max_zero_sub_eq_self (f a)

end PosPart

section Integral

/-!
### The Bochner integral of simple functions

Define the Bochner integral of simple functions of the type `α →ₛ β` where `β` is a normed group,
and prove basic property of this integral.
-/


open Finset

variable[NormedGroup
      E][MeasurableSpace
      E][NormedGroup
      F][NormedSpace ℝ
      F]{p :
    ℝ≥0∞}{G F' : Type _}[NormedGroup G][NormedGroup F'][NormedSpace ℝ F']{m : MeasurableSpace α}{μ : Measureₓ α}

/-- Bochner integral of simple functions whose codomain is a real `normed_space`.
This is equal to `∑ x in f.range, (μ (f ⁻¹' {x})).to_real • x` (see `integral_eq`). -/
def integral {m : MeasurableSpace α} (μ : Measureₓ α) (f : α →ₛ F) : F :=
  f.set_to_simple_func (weighted_smul μ)

theorem integral_def {m : MeasurableSpace α} (μ : Measureₓ α) (f : α →ₛ F) :
  f.integral μ = f.set_to_simple_func (weighted_smul μ) :=
  rfl

theorem integral_eq {m : MeasurableSpace α} (μ : Measureₓ α) (f : α →ₛ F) :
  f.integral μ = ∑x in f.range, (μ (f ⁻¹' {x})).toReal • x :=
  by 
    simp [integral, set_to_simple_func, weighted_smul_apply]

theorem integral_eq_sum_filter {m : MeasurableSpace α} (f : α →ₛ F) (μ : Measureₓ α) :
  f.integral μ = ∑x in f.range.filter fun x => x ≠ 0, (μ (f ⁻¹' {x})).toReal • x :=
  by 
    rw [integral_def, set_to_simple_func_eq_sum_filter]
    simpRw [weighted_smul_apply]

/-- The Bochner integral is equal to a sum over any set that includes `f.range` (except `0`). -/
theorem integral_eq_sum_of_subset {f : α →ₛ F} {s : Finset F} (hs : (f.range.filter fun x => x ≠ 0) ⊆ s) :
  f.integral μ = ∑x in s, (μ (f ⁻¹' {x})).toReal • x :=
  by 
    rw [simple_func.integral_eq_sum_filter, Finset.sum_subset hs]
    rintro x - hx 
    rw [Finset.mem_filter, not_and_distrib, Ne.def, not_not] at hx 
    rcases hx with (hx | rfl) <;> [skip, simp ]
    rw [simple_func.mem_range] at hx 
    rw [preimage_eq_empty] <;> simp [Set.disjoint_singleton_left, hx]

@[simp]
theorem integral_const {m : MeasurableSpace α} (μ : Measureₓ α) (y : F) :
  (const α y).integral μ = (μ univ).toReal • y :=
  calc (const α y).integral μ = ∑z in {y}, (μ (const α y ⁻¹' {z})).toReal • z :=
    integral_eq_sum_of_subset$ (filter_subset _ _).trans (range_const_subset _ _)
    _ = (μ univ).toReal • y :=
    by 
      simp 
    

-- error in MeasureTheory.Integral.Bochner: ././Mathport/Syntax/Translate/Basic.lean:340:40: in exacts: ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
@[simp]
theorem integral_piecewise_zero
{m : measurable_space α}
(f : «expr →ₛ »(α, F))
(μ : measure α)
{s : set α}
(hs : measurable_set s) : «expr = »((piecewise s hs f 0).integral μ, f.integral (μ.restrict s)) :=
begin
  refine [expr (integral_eq_sum_of_subset _).trans («expr $ »(sum_congr rfl, λ
     y hy, _).trans (integral_eq_sum_filter _ _).symm)],
  { intros [ident y, ident hy],
    simp [] [] ["only"] ["[", expr mem_filter, ",", expr mem_range, ",", expr coe_piecewise, ",", expr coe_zero, ",", expr piecewise_eq_indicator, ",", expr mem_range_indicator, "]"] [] ["at", "*"],
    rcases [expr hy, "with", "⟨", "⟨", ident rfl, ",", "-", "⟩", "|", "⟨", ident x, ",", ident hxs, ",", ident rfl, "⟩", ",", ident h₀, "⟩"],
    exacts ["[", expr (h₀ rfl).elim, ",", expr ⟨set.mem_range_self _, h₀⟩, "]"] },
  { dsimp [] [] [] [],
    rw ["[", expr indicator_preimage_of_not_mem, ",", expr measure.restrict_apply (f.measurable_set_preimage _), "]"] [],
    exact [expr λ h₀, (mem_filter.1 hy).2 (eq.symm h₀)] }
end

/-- Calculate the integral of `g ∘ f : α →ₛ F`, where `f` is an integrable function from `α` to `E`
    and `g` is a function from `E` to `F`. We require `g 0 = 0` so that `g ∘ f` is integrable. -/
theorem map_integral (f : α →ₛ E) (g : E → F) (hf : integrable f μ) (hg : g 0 = 0) :
  (f.map g).integral μ = ∑x in f.range, Ennreal.toReal (μ (f ⁻¹' {x})) • g x :=
  map_set_to_simple_func _ weighted_smul_union hf hg

/-- `simple_func.integral` and `simple_func.lintegral` agree when the integrand has type
    `α →ₛ ℝ≥0∞`. But since `ℝ≥0∞` is not a `normed_space`, we need some form of coercion.
    See `integral_eq_lintegral` for a simpler version. -/
theorem integral_eq_lintegral' {f : α →ₛ E} {g : E → ℝ≥0∞} (hf : integrable f μ) (hg0 : g 0 = 0) (ht : ∀ b, g b ≠ ∞) :
  (f.map (Ennreal.toReal ∘ g)).integral μ = Ennreal.toReal (∫⁻a, g (f a) ∂μ) :=
  by 
    have hf' : f.fin_meas_supp μ := integrable_iff_fin_meas_supp.1 hf 
    simp only [←map_apply g f, lintegral_eq_lintegral]
    rw [map_integral f _ hf, map_lintegral, Ennreal.to_real_sum]
    ·
      refine' Finset.sum_congr rfl fun b hb => _ 
      rw [smul_eq_mul, to_real_mul, mul_commₓ]
    ·
      intro a ha 
      byCases' a0 : a = 0
      ·
        rw [a0, hg0, zero_mul]
        exact WithTop.zero_ne_top
      ·
        apply mul_ne_top (ht a) (hf'.meas_preimage_singleton_ne_zero a0).Ne
    ·
      simp [hg0]

variable[NormedField 𝕜][NormedSpace 𝕜 E][NormedSpace ℝ E][SmulCommClass ℝ 𝕜 E]

theorem integral_congr {f g : α →ₛ E} (hf : integrable f μ) (h : f =ᵐ[μ] g) : f.integral μ = g.integral μ :=
  set_to_simple_func_congr (weighted_smul μ) (fun s hs => weighted_smul_null) weighted_smul_union hf h

-- error in MeasureTheory.Integral.Bochner: ././Mathport/Syntax/Translate/Basic.lean:340:40: in exacts: ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
/-- `simple_func.bintegral` and `simple_func.integral` agree when the integrand has type
    `α →ₛ ℝ≥0∞`. But since `ℝ≥0∞` is not a `normed_space`, we need some form of coercion. -/
theorem integral_eq_lintegral
{f : «expr →ₛ »(α, exprℝ())}
(hf : integrable f μ)
(h_pos : «expr ≤ᵐ[ ] »(0, μ, f)) : «expr = »(f.integral μ, ennreal.to_real «expr∫⁻ , ∂ »((a), ennreal.of_real (f a), μ)) :=
begin
  have [] [":", expr «expr =ᵐ[ ] »(f, μ, f.map «expr ∘ »(ennreal.to_real, ennreal.of_real))] [":=", expr h_pos.mono (λ
    a h, (ennreal.to_real_of_real h).symm)],
  rw ["[", "<-", expr integral_eq_lintegral' hf, "]"] [],
  exacts ["[", expr integral_congr hf this, ",", expr ennreal.of_real_zero, ",", expr λ b, ennreal.of_real_ne_top, "]"]
end

theorem integral_add {f g : α →ₛ E} (hf : integrable f μ) (hg : integrable g μ) :
  integral μ (f+g) = integral μ f+integral μ g :=
  set_to_simple_func_add _ weighted_smul_union hf hg

theorem integral_neg {f : α →ₛ E} (hf : integrable f μ) : integral μ (-f) = -integral μ f :=
  set_to_simple_func_neg _ weighted_smul_union hf

theorem integral_sub {f g : α →ₛ E} (hf : integrable f μ) (hg : integrable g μ) :
  integral μ (f - g) = integral μ f - integral μ g :=
  set_to_simple_func_sub _ weighted_smul_union hf hg

theorem integral_smul (c : 𝕜) {f : α →ₛ E} (hf : integrable f μ) : integral μ (c • f) = c • integral μ f :=
  set_to_simple_func_smul _ weighted_smul_union weighted_smul_smul c hf

theorem norm_set_to_simple_func_le_integral_norm (T : Set α → E →L[ℝ] F) {C : ℝ} (hT_norm : ∀ s, ∥T s∥ ≤ C*(μ s).toReal)
  {f : α →ₛ E} (hf : integrable f μ) : ∥f.set_to_simple_func T∥ ≤ C*(f.map norm).integral μ :=
  calc ∥f.set_to_simple_func T∥ ≤ C*∑x in f.range, Ennreal.toReal (μ (f ⁻¹' {x}))*∥x∥ :=
    norm_set_to_simple_func_le_sum_mul_norm T hT_norm f 
    _ = C*(f.map norm).integral μ :=
    by 
      rw [map_integral f norm hf norm_zero]
      simpRw [smul_eq_mul]
    

theorem norm_integral_le_integral_norm (f : α →ₛ E) (hf : integrable f μ) : ∥f.integral μ∥ ≤ (f.map norm).integral μ :=
  by 
    refine' (norm_set_to_simple_func_le_integral_norm _ (fun s => _) hf).trans (one_mulₓ _).le 
    exact (norm_weighted_smul_le s).trans (one_mulₓ _).symm.le

theorem integral_add_measure {ν} (f : α →ₛ E) (hf : integrable f (μ+ν)) :
  f.integral (μ+ν) = f.integral μ+f.integral ν :=
  by 
    simpRw [integral_def]
    refine'
      set_to_simple_func_add_left' (weighted_smul μ) (weighted_smul ν) (weighted_smul (μ+ν)) (fun s hs hμνs => _) hf 
    rw [measure.coe_add, Pi.add_apply, Ennreal.add_ne_top] at hμνs 
    rw [weighted_smul_add_measure _ _ hμνs.1 hμνs.2]

end Integral

end SimpleFunc

namespace L1

open AeEqFun Lp.SimpleFunc Lp

variable[NormedGroup
      E][second_countable_topology
      E][MeasurableSpace
      E][BorelSpace
      E][NormedGroup
      F][second_countable_topology F][MeasurableSpace F][BorelSpace F]{m : MeasurableSpace α}{μ : Measureₓ α}

variable{α E μ}

namespace SimpleFunc

theorem norm_eq_integral (f : α →₁ₛ[μ] E) : ∥f∥ = ((to_simple_func f).map norm).integral μ :=
  by 
    rw [norm_eq_sum_mul f, (to_simple_func f).map_integral norm (simple_func.integrable f) norm_zero]
    simpRw [smul_eq_mul]

section PosPart

/-- Positive part of a simple function in L1 space.  -/
def pos_part (f : α →₁ₛ[μ] ℝ) : α →₁ₛ[μ] ℝ :=
  ⟨Lp.pos_part (f : α →₁[μ] ℝ),
    by 
      rcases f with ⟨f, s, hsf⟩
      use s.pos_part 
      simp only [Subtype.coe_mk, Lp.coe_pos_part, ←hsf, ae_eq_fun.pos_part_mk, simple_func.pos_part,
        simple_func.coe_map]⟩

/-- Negative part of a simple function in L1 space. -/
def neg_part (f : α →₁ₛ[μ] ℝ) : α →₁ₛ[μ] ℝ :=
  pos_part (-f)

@[normCast]
theorem coe_pos_part (f : α →₁ₛ[μ] ℝ) : (pos_part f : α →₁[μ] ℝ) = Lp.pos_part (f : α →₁[μ] ℝ) :=
  rfl

@[normCast]
theorem coe_neg_part (f : α →₁ₛ[μ] ℝ) : (neg_part f : α →₁[μ] ℝ) = Lp.neg_part (f : α →₁[μ] ℝ) :=
  rfl

end PosPart

section SimpleFuncIntegral

/-!
### The Bochner integral of `L1`

Define the Bochner integral on `α →₁ₛ[μ] E` by extension from the simple functions `α →₁ₛ[μ] E`,
and prove basic properties of this integral. -/


variable[NormedField
      𝕜][NormedSpace 𝕜 E][NormedSpace ℝ E][SmulCommClass ℝ 𝕜 E]{F' : Type _}[NormedGroup F'][NormedSpace ℝ F']

attribute [local instance] simple_func.normed_space

/-- The Bochner integral over simple functions in L1 space. -/
def integral (f : α →₁ₛ[μ] E) : E :=
  (to_simple_func f).integral μ

theorem integral_eq_integral (f : α →₁ₛ[μ] E) : integral f = (to_simple_func f).integral μ :=
  rfl

theorem integral_eq_lintegral {f : α →₁ₛ[μ] ℝ} (h_pos : 0 ≤ᵐ[μ] to_simple_func f) :
  integral f = Ennreal.toReal (∫⁻a, Ennreal.ofReal ((to_simple_func f) a) ∂μ) :=
  by 
    rw [integral, simple_func.integral_eq_lintegral (simple_func.integrable f) h_pos]

theorem integral_eq_set_to_L1s (f : α →₁ₛ[μ] E) : integral f = set_to_L1s (weighted_smul μ) f :=
  rfl

theorem integral_congr {f g : α →₁ₛ[μ] E} (h : to_simple_func f =ᵐ[μ] to_simple_func g) : integral f = integral g :=
  simple_func.integral_congr (simple_func.integrable f) h

theorem integral_add (f g : α →₁ₛ[μ] E) : integral (f+g) = integral f+integral g :=
  set_to_L1s_add _ (fun _ _ => weighted_smul_null) weighted_smul_union _ _

theorem integral_smul [MeasurableSpace 𝕜] [OpensMeasurableSpace 𝕜] (c : 𝕜) (f : α →₁ₛ[μ] E) :
  integral (c • f) = c • integral f :=
  set_to_L1s_smul _ (fun _ _ => weighted_smul_null) weighted_smul_union weighted_smul_smul c f

theorem norm_integral_le_norm (f : α →₁ₛ[μ] E) : ∥integral f∥ ≤ ∥f∥ :=
  by 
    rw [integral, norm_eq_integral]
    exact (to_simple_func f).norm_integral_le_integral_norm (simple_func.integrable f)

variable{E' :
    Type
      _}[NormedGroup
      E'][second_countable_topology
      E'][MeasurableSpace
      E'][BorelSpace E'][NormedSpace ℝ E'][NormedSpace 𝕜 E'][MeasurableSpace 𝕜][OpensMeasurableSpace 𝕜]

variable(α E μ 𝕜)

/-- The Bochner integral over simple functions in L1 space as a continuous linear map. -/
def integral_clm' : (α →₁ₛ[μ] E) →L[𝕜] E :=
  LinearMap.mkContinuous ⟨integral, integral_add, integral_smul⟩ 1
    fun f =>
      le_transₓ (norm_integral_le_norm _)$
        by 
          rw [one_mulₓ]

/-- The Bochner integral over simple functions in L1 space as a continuous linear map over ℝ. -/
def integral_clm : (α →₁ₛ[μ] E) →L[ℝ] E :=
  integral_clm' α E ℝ μ

variable{α E μ 𝕜}

local notation "Integral" => integral_clm α E μ

open ContinuousLinearMap

theorem norm_Integral_le_one : ∥Integral∥ ≤ 1 :=
  LinearMap.mk_continuous_norm_le _ zero_le_one _

section PosPart

theorem pos_part_to_simple_func (f : α →₁ₛ[μ] ℝ) : to_simple_func (pos_part f) =ᵐ[μ] (to_simple_func f).posPart :=
  by 
    have eq : ∀ a, (to_simple_func f).posPart a = max ((to_simple_func f) a) 0 := fun a => rfl 
    have ae_eq : ∀ᵐa ∂μ, to_simple_func (pos_part f) a = max ((to_simple_func f) a) 0
    ·
      filterUpwards [to_simple_func_eq_to_fun (pos_part f), Lp.coe_fn_pos_part (f : α →₁[μ] ℝ),
        to_simple_func_eq_to_fun f]
      intro a h₁ h₂ h₃ 
      convert h₂ 
    refine' ae_eq.mono fun a h => _ 
    rw [h, Eq]

theorem neg_part_to_simple_func (f : α →₁ₛ[μ] ℝ) : to_simple_func (neg_part f) =ᵐ[μ] (to_simple_func f).negPart :=
  by 
    rw [simple_func.neg_part, MeasureTheory.SimpleFunc.negPart]
    filterUpwards [pos_part_to_simple_func (-f), neg_to_simple_func f]
    intro a h₁ h₂ 
    rw [h₁]
    show max _ _ = max _ _ 
    rw [h₂]
    rfl

theorem integral_eq_norm_pos_part_sub (f : α →₁ₛ[μ] ℝ) : integral f = ∥pos_part f∥ - ∥neg_part f∥ :=
  by 
    have ae_eq₁ : (to_simple_func f).posPart =ᵐ[μ] (to_simple_func (pos_part f)).map norm
    ·
      filterUpwards [pos_part_to_simple_func f]
      intro a h 
      rw [simple_func.map_apply, h]
      convLHS => rw [←simple_func.pos_part_map_norm, simple_func.map_apply]
    have ae_eq₂ : (to_simple_func f).negPart =ᵐ[μ] (to_simple_func (neg_part f)).map norm
    ·
      filterUpwards [neg_part_to_simple_func f]
      intro a h 
      rw [simple_func.map_apply, h]
      convLHS => rw [←simple_func.neg_part_map_norm, simple_func.map_apply]
    have ae_eq :
      ∀ᵐa ∂μ,
        (to_simple_func f).posPart a - (to_simple_func f).negPart a =
          (to_simple_func (pos_part f)).map norm a - (to_simple_func (neg_part f)).map norm a
    ·
      filterUpwards [ae_eq₁, ae_eq₂]
      intro a h₁ h₂ 
      rw [h₁, h₂]
    rw [integral, norm_eq_integral, norm_eq_integral, ←simple_func.integral_sub]
    ·
      show
        (to_simple_func f).integral μ =
          ((to_simple_func (pos_part f)).map norm - (to_simple_func (neg_part f)).map norm).integral μ 
      apply MeasureTheory.SimpleFunc.integral_congr (simple_func.integrable f)
      filterUpwards [ae_eq₁, ae_eq₂]
      intro a h₁ h₂ 
      show _ = _ - _ 
      rw [←h₁, ←h₂]
      have  := (to_simple_func f).pos_part_sub_neg_part 
      convLHS => rw [←this]
      rfl
    ·
      exact (simple_func.integrable f).max_zero.congr ae_eq₁
    ·
      exact (simple_func.integrable f).neg.max_zero.congr ae_eq₂

end PosPart

end SimpleFuncIntegral

end SimpleFunc

open SimpleFunc

local notation "Integral" => @integral_clm α E _ _ _ _ _ μ _

variable[NormedSpace ℝ
      E][NondiscreteNormedField 𝕜][NormedSpace 𝕜 E][SmulCommClass ℝ 𝕜 E][NormedSpace ℝ F][CompleteSpace E]

section IntegrationInL1

attribute [local instance] simple_func.normed_space

open ContinuousLinearMap

variable(𝕜)[MeasurableSpace 𝕜][OpensMeasurableSpace 𝕜]

/-- The Bochner integral in L1 space as a continuous linear map. -/
def integral_clm' : (α →₁[μ] E) →L[𝕜] E :=
  (integral_clm' α E 𝕜 μ).extend (coe_to_Lp α E 𝕜) (simple_func.dense_range one_ne_top) simple_func.uniform_inducing

variable{𝕜}

/-- The Bochner integral in L1 space as a continuous linear map over ℝ. -/
def integral_clm : (α →₁[μ] E) →L[ℝ] E :=
  integral_clm' ℝ

/-- The Bochner integral in L1 space -/
def integral (f : α →₁[μ] E) : E :=
  integral_clm f

theorem integral_eq (f : α →₁[μ] E) : integral f = integral_clm f :=
  rfl

theorem integral_eq_set_to_L1 (f : α →₁[μ] E) :
  integral f = set_to_L1 (dominated_fin_meas_additive_weighted_smul μ) f :=
  rfl

@[normCast]
theorem simple_func.integral_L1_eq_integral (f : α →₁ₛ[μ] E) : integral (f : α →₁[μ] E) = simple_func.integral f :=
  set_to_L1_eq_set_to_L1s_clm (dominated_fin_meas_additive_weighted_smul μ) f

variable(α E)

@[simp]
theorem integral_zero : integral (0 : α →₁[μ] E) = 0 :=
  map_zero integral_clm

variable{α E}

theorem integral_add (f g : α →₁[μ] E) : integral (f+g) = integral f+integral g :=
  map_add integral_clm f g

theorem integral_neg (f : α →₁[μ] E) : integral (-f) = -integral f :=
  map_neg integral_clm f

theorem integral_sub (f g : α →₁[μ] E) : integral (f - g) = integral f - integral g :=
  map_sub integral_clm f g

theorem integral_smul (c : 𝕜) (f : α →₁[μ] E) : integral (c • f) = c • integral f :=
  map_smul (integral_clm' 𝕜) c f

local notation "Integral" => @integral_clm α E _ _ _ _ _ μ _ _

local notation "sIntegral" => @simple_func.integral_clm α E _ _ _ _ _ μ _

theorem norm_Integral_le_one : ∥Integral∥ ≤ 1 :=
  calc ∥Integral∥ ≤ (1 :  ℝ≥0 )*∥sIntegral∥ :=
    op_norm_extend_le _ _ _$
      fun s =>
        by 
          rw [Nnreal.coe_one, one_mulₓ]
          rfl 
    _ = ∥sIntegral∥ := one_mulₓ _ 
    _ ≤ 1 := norm_Integral_le_one
    

theorem norm_integral_le (f : α →₁[μ] E) : ∥integral f∥ ≤ ∥f∥ :=
  calc ∥integral f∥ = ∥Integral f∥ := rfl 
    _ ≤ ∥Integral∥*∥f∥ := le_op_norm _ _ 
    _ ≤ 1*∥f∥ := mul_le_mul_of_nonneg_right norm_Integral_le_one$ norm_nonneg _ 
    _ = ∥f∥ := one_mulₓ _
    

@[continuity]
theorem continuous_integral : Continuous fun f : α →₁[μ] E => integral f :=
  L1.integral_clm.Continuous

section PosPart

attribute [local instance] fact_one_le_one_ennreal

theorem integral_eq_norm_pos_part_sub (f : α →₁[μ] ℝ) : integral f = ∥Lp.pos_part f∥ - ∥Lp.neg_part f∥ :=
  by 
    refine'
      @is_closed_property _ _ _ (coeₓ : (α →₁ₛ[μ] ℝ) → α →₁[μ] ℝ)
        (fun f : α →₁[μ] ℝ => integral f = ∥Lp.pos_part f∥ - ∥Lp.neg_part f∥) (simple_func.dense_range one_ne_top)
        (is_closed_eq _ _) _ f
    ·
      exact cont _
    ·
      refine' Continuous.sub (continuous_norm.comp Lp.continuous_pos_part) (continuous_norm.comp Lp.continuous_neg_part)
    ·
      intro s 
      normCast 
      exact simple_func.integral_eq_norm_pos_part_sub _

end PosPart

end IntegrationInL1

end L1

/-!
### The Bochner integral on functions

Define the Bochner integral on functions generally to be the `L1` Bochner integral, for integrable
functions, and 0 otherwise; prove its basic properties.

-/


variable[NormedGroup
      E][second_countable_topology
      E][NormedSpace ℝ
      E][CompleteSpace
      E][MeasurableSpace
      E][BorelSpace
      E][NondiscreteNormedField
      𝕜][NormedSpace 𝕜
      E][SmulCommClass ℝ 𝕜
      E][NormedGroup F][second_countable_topology F][NormedSpace ℝ F][CompleteSpace F][MeasurableSpace F][BorelSpace F]

/-- The Bochner integral -/
def integral {m : MeasurableSpace α} (μ : Measureₓ α) (f : α → E) : E :=
  if hf : integrable f μ then L1.integral (hf.to_L1 f) else 0

/-! In the notation for integrals, an expression like `∫ x, g ∥x∥ ∂μ` will not be parsed correctly,
  and needs parentheses. We do not set the binding power of `r` to `0`, because then
  `∫ x, f x = 0` will be parsed incorrectly. -/


notation3  "∫" (...) ", " r:(scoped f => f) " ∂" μ => integral μ r

notation3  "∫" (...) ", " r:(scoped f => integral volume f) => r

notation3  "∫" (...) " in " s ", " r:(scoped f => f) " ∂" μ => integral (measure.restrict μ s) r

notation3  "∫" (...) " in " s ", " r:(scoped f => integral measure.restrict volume s f) => r

section Properties

open ContinuousLinearMap MeasureTheory.SimpleFunc

variable{f g : α → E}{m : MeasurableSpace α}{μ : Measureₓ α}

theorem integral_eq (f : α → E) (hf : integrable f μ) : (∫a, f a ∂μ) = L1.integral (hf.to_L1 f) :=
  dif_pos hf

theorem integral_eq_set_to_fun (f : α → E) :
  (∫a, f a ∂μ) = set_to_fun (dominated_fin_meas_additive_weighted_smul μ) f :=
  rfl

theorem L1.integral_eq_integral (f : α →₁[μ] E) : L1.integral f = ∫a, f a ∂μ :=
  (L1.set_to_fun_eq_set_to_L1 (dominated_fin_meas_additive_weighted_smul μ) f).symm

theorem integral_undef (h : ¬integrable f μ) : (∫a, f a ∂μ) = 0 :=
  dif_neg h

theorem integral_non_ae_measurable (h : ¬AeMeasurable f μ) : (∫a, f a ∂μ) = 0 :=
  integral_undef$ not_and_of_not_left _ h

variable(α E)

theorem integral_zero : (∫a : α, (0 : E) ∂μ) = 0 :=
  set_to_fun_zero (dominated_fin_meas_additive_weighted_smul μ)

@[simp]
theorem integral_zero' : integral μ (0 : α → E) = 0 :=
  integral_zero α E

variable{α E}

theorem integral_add (hf : integrable f μ) (hg : integrable g μ) : (∫a, f a+g a ∂μ) = (∫a, f a ∂μ)+∫a, g a ∂μ :=
  set_to_fun_add (dominated_fin_meas_additive_weighted_smul μ) hf hg

theorem integral_add' (hf : integrable f μ) (hg : integrable g μ) : (∫a, (f+g) a ∂μ) = (∫a, f a ∂μ)+∫a, g a ∂μ :=
  integral_add hf hg

theorem integral_neg (f : α → E) : (∫a, -f a ∂μ) = -∫a, f a ∂μ :=
  set_to_fun_neg (dominated_fin_meas_additive_weighted_smul μ) f

theorem integral_neg' (f : α → E) : (∫a, (-f) a ∂μ) = -∫a, f a ∂μ :=
  integral_neg f

theorem integral_sub (hf : integrable f μ) (hg : integrable g μ) : (∫a, f a - g a ∂μ) = (∫a, f a ∂μ) - ∫a, g a ∂μ :=
  set_to_fun_sub (dominated_fin_meas_additive_weighted_smul μ) hf hg

theorem integral_sub' (hf : integrable f μ) (hg : integrable g μ) : (∫a, (f - g) a ∂μ) = (∫a, f a ∂μ) - ∫a, g a ∂μ :=
  integral_sub hf hg

theorem integral_smul [MeasurableSpace 𝕜] [OpensMeasurableSpace 𝕜] (c : 𝕜) (f : α → E) :
  (∫a, c • f a ∂μ) = c • ∫a, f a ∂μ :=
  set_to_fun_smul (dominated_fin_meas_additive_weighted_smul μ) weighted_smul_smul c f

theorem integral_mul_left (r : ℝ) (f : α → ℝ) : (∫a, r*f a ∂μ) = r*∫a, f a ∂μ :=
  integral_smul r f

theorem integral_mul_right (r : ℝ) (f : α → ℝ) : (∫a, f a*r ∂μ) = (∫a, f a ∂μ)*r :=
  by 
    simp only [mul_commₓ]
    exact integral_mul_left r f

theorem integral_div (r : ℝ) (f : α → ℝ) : (∫a, f a / r ∂μ) = (∫a, f a ∂μ) / r :=
  integral_mul_right (r⁻¹) f

theorem integral_congr_ae (h : f =ᵐ[μ] g) : (∫a, f a ∂μ) = ∫a, g a ∂μ :=
  set_to_fun_congr_ae (dominated_fin_meas_additive_weighted_smul μ) h

@[simp]
theorem L1.integral_of_fun_eq_integral {f : α → E} (hf : integrable f μ) : (∫a, (hf.to_L1 f) a ∂μ) = ∫a, f a ∂μ :=
  integral_congr_ae$
    by 
      simp [integrable.coe_fn_to_L1]

@[continuity]
theorem continuous_integral : Continuous fun f : α →₁[μ] E => ∫a, f a ∂μ :=
  by 
    simp only [←L1.integral_eq_integral]
    exact L1.continuous_integral

theorem norm_integral_le_lintegral_norm (f : α → E) : ∥∫a, f a ∂μ∥ ≤ Ennreal.toReal (∫⁻a, Ennreal.ofReal ∥f a∥ ∂μ) :=
  by 
    byCases' hf : integrable f μ
    ·
      rw [integral_eq f hf, ←integrable.norm_to_L1_eq_lintegral_norm f hf]
      exact L1.norm_integral_le _
    ·
      rw [integral_undef hf, norm_zero]
      exact to_real_nonneg

theorem ennnorm_integral_le_lintegral_ennnorm (f : α → E) : (nnnorm (∫a, f a ∂μ) : ℝ≥0∞) ≤ ∫⁻a, nnnorm (f a) ∂μ :=
  by 
    simpRw [←of_real_norm_eq_coe_nnnorm]
    apply Ennreal.of_real_le_of_le_to_real 
    exact norm_integral_le_lintegral_norm f

theorem integral_eq_zero_of_ae {f : α → E} (hf : f =ᵐ[μ] 0) : (∫a, f a ∂μ) = 0 :=
  by 
    simp [integral_congr_ae hf, integral_zero]

/-- If `f` has finite integral, then `∫ x in s, f x ∂μ` is absolutely continuous in `s`: it tends
to zero as `μ s` tends to zero. -/
theorem has_finite_integral.tendsto_set_integral_nhds_zero {ι} {f : α → E} (hf : has_finite_integral f μ) {l : Filter ι}
  {s : ι → Set α} (hs : tendsto (μ ∘ s) l (𝓝 0)) : tendsto (fun i => ∫x in s i, f x ∂μ) l (𝓝 0) :=
  by 
    rw [tendsto_zero_iff_norm_tendsto_zero]
    simpRw [←coe_nnnorm, ←Nnreal.coe_zero, Nnreal.tendsto_coe, ←Ennreal.tendsto_coe, Ennreal.coe_zero]
    exact
      tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds (tendsto_set_lintegral_zero (ne_of_ltₓ hf) hs)
        (fun i => zero_le _) fun i => ennnorm_integral_le_lintegral_ennnorm _

/-- If `f` is integrable, then `∫ x in s, f x ∂μ` is absolutely continuous in `s`: it tends
to zero as `μ s` tends to zero. -/
theorem integrable.tendsto_set_integral_nhds_zero {ι} {f : α → E} (hf : integrable f μ) {l : Filter ι} {s : ι → Set α}
  (hs : tendsto (μ ∘ s) l (𝓝 0)) : tendsto (fun i => ∫x in s i, f x ∂μ) l (𝓝 0) :=
  hf.2.tendsto_set_integral_nhds_zero hs

/-- If `F i → f` in `L1`, then `∫ x, F i x ∂μ → ∫ x, f x∂μ`. -/
theorem tendsto_integral_of_L1 {ι} (f : α → E) (hfi : integrable f μ) {F : ι → α → E} {l : Filter ι}
  (hFi : ∀ᶠi in l, integrable (F i) μ) (hF : tendsto (fun i => ∫⁻x, ∥F i x - f x∥₊ ∂μ) l (𝓝 0)) :
  tendsto (fun i => ∫x, F i x ∂μ) l (𝓝$ ∫x, f x ∂μ) :=
  by 
    rw [tendsto_iff_norm_tendsto_zero]
    replace hF : tendsto (fun i => Ennreal.toReal$ ∫⁻x, ∥F i x - f x∥₊ ∂μ) l (𝓝 0) :=
      (Ennreal.tendsto_to_real zero_ne_top).comp hF 
    refine' squeeze_zero_norm' (hFi.mp$ hFi.mono$ fun i hFi hFm => _) hF 
    simp only [norm_norm, ←integral_sub hFi hfi]
    convert norm_integral_le_lintegral_norm fun x => F i x - f x 
    ext1 x 
    exact coe_nnreal_eq _

/-- Lebesgue dominated convergence theorem provides sufficient conditions under which almost
  everywhere convergence of a sequence of functions implies the convergence of their integrals.
  We could weaken the condition `bound_integrable` to require `has_finite_integral bound μ` instead
  (i.e. not requiring that `bound` is measurable), but in all applications proving integrability
  is easier. -/
theorem tendsto_integral_of_dominated_convergence {F : ℕ → α → E} {f : α → E} (bound : α → ℝ)
  (F_measurable : ∀ n, AeMeasurable (F n) μ) (bound_integrable : integrable bound μ)
  (h_bound : ∀ n, ∀ᵐa ∂μ, ∥F n a∥ ≤ bound a) (h_lim : ∀ᵐa ∂μ, tendsto (fun n => F n a) at_top (𝓝 (f a))) :
  tendsto (fun n => ∫a, F n a ∂μ) at_top (𝓝$ ∫a, f a ∂μ) :=
  by 
    have f_measurable : AeMeasurable f μ := ae_measurable_of_tendsto_metric_ae F_measurable h_lim 
    rw [tendsto_iff_norm_tendsto_zero]
    have lintegral_norm_tendsto_zero :
      tendsto (fun n => Ennreal.toReal$ ∫⁻a, Ennreal.ofReal ∥F n a - f a∥ ∂μ) at_top (𝓝 0) :=
      (tendsto_to_real zero_ne_top).comp
        (tendsto_lintegral_norm_of_dominated_convergence F_measurable bound_integrable.has_finite_integral h_bound
          h_lim)
    refine' squeeze_zero (fun n => norm_nonneg _) _ lintegral_norm_tendsto_zero
    ·
      intro n 
      have h₁ : integrable (F n) μ := bound_integrable.mono' (F_measurable n) (h_bound _)
      have h₂ : integrable f μ :=
        ⟨f_measurable, has_finite_integral_of_dominated_convergence bound_integrable.has_finite_integral h_bound h_lim⟩
      rw [←integral_sub h₁ h₂]
      exact norm_integral_le_lintegral_norm _

/-- Lebesgue dominated convergence theorem for filters with a countable basis -/
theorem tendsto_integral_filter_of_dominated_convergence {ι} {l : Filter ι} [l.is_countably_generated] {F : ι → α → E}
  {f : α → E} (bound : α → ℝ) (hF_meas : ∀ᶠn in l, AeMeasurable (F n) μ) (h_bound : ∀ᶠn in l, ∀ᵐa ∂μ, ∥F n a∥ ≤ bound a)
  (bound_integrable : integrable bound μ) (h_lim : ∀ᵐa ∂μ, tendsto (fun n => F n a) l (𝓝 (f a))) :
  tendsto (fun n => ∫a, F n a ∂μ) l (𝓝$ ∫a, f a ∂μ) :=
  by 
    rw [tendsto_iff_seq_tendsto]
    intro x xl 
    have hxl
    ·
      rw [tendsto_at_top'] at xl 
      exact xl 
    have h := inter_mem hF_meas h_bound 
    replace h := hxl _ h 
    rcases h with ⟨k, h⟩
    rw [←tendsto_add_at_top_iff_nat k]
    refine' tendsto_integral_of_dominated_convergence bound _ bound_integrable _ _
    ·
      intro 
      refine' (h _ _).1
      apply self_le_add_left
    ·
      intro 
      refine' (h _ _).2
      apply self_le_add_left
    ·
      filterUpwards [h_lim]
      intro a h_lim 
      apply @tendsto.comp _ _ _ (fun n => x (n+k)) fun n => F n a
      ·
        assumption 
      rw [tendsto_add_at_top_iff_nat]
      assumption

variable{X : Type _}[TopologicalSpace X][first_countable_topology X]

theorem continuous_at_of_dominated {F : X → α → E} {x₀ : X} {bound : α → ℝ}
  (hF_meas : ∀ᶠx in 𝓝 x₀, AeMeasurable (F x) μ) (h_bound : ∀ᶠx in 𝓝 x₀, ∀ᵐa ∂μ, ∥F x a∥ ≤ bound a)
  (bound_integrable : integrable bound μ) (h_cont : ∀ᵐa ∂μ, ContinuousAt (fun x => F x a) x₀) :
  ContinuousAt (fun x => ∫a, F x a ∂μ) x₀ :=
  tendsto_integral_filter_of_dominated_convergence bound ‹_› ‹_› ‹_› ‹_›

theorem continuous_of_dominated {F : X → α → E} {bound : α → ℝ} (hF_meas : ∀ x, AeMeasurable (F x) μ)
  (h_bound : ∀ x, ∀ᵐa ∂μ, ∥F x a∥ ≤ bound a) (bound_integrable : integrable bound μ)
  (h_cont : ∀ᵐa ∂μ, Continuous fun x => F x a) : Continuous fun x => ∫a, F x a ∂μ :=
  continuous_iff_continuous_at.mpr
    fun x₀ =>
      continuous_at_of_dominated (eventually_of_forall hF_meas) (eventually_of_forall h_bound) ‹_›$
        h_cont.mono$ fun _ => Continuous.continuous_at

/-- The Bochner integral of a real-valued function `f : α → ℝ` is the difference between the
  integral of the positive part of `f` and the integral of the negative part of `f`.  -/
theorem integral_eq_lintegral_pos_part_sub_lintegral_neg_part {f : α → ℝ} (hf : integrable f μ) :
  (∫a, f a ∂μ) = Ennreal.toReal (∫⁻a, Ennreal.ofReal$ f a ∂μ) - Ennreal.toReal (∫⁻a, Ennreal.ofReal$ -f a ∂μ) :=
  let f₁ := hf.to_L1 f 
  have eq₁ : Ennreal.toReal (∫⁻a, Ennreal.ofReal$ f a ∂μ) = ∥Lp.pos_part f₁∥ :=
    by 
      rw [L1.norm_def]
      congr 1
      apply lintegral_congr_ae 
      filterUpwards [Lp.coe_fn_pos_part f₁, hf.coe_fn_to_L1]
      intro a h₁ h₂ 
      rw [h₁, h₂, Ennreal.ofReal]
      congr 1
      apply Nnreal.eq 
      simp [Real.norm_of_nonneg, le_max_rightₓ, Real.coe_to_nnreal]
  have eq₂ : Ennreal.toReal (∫⁻a, Ennreal.ofReal$ -f a ∂μ) = ∥Lp.neg_part f₁∥ :=
    by 
      rw [L1.norm_def]
      congr 1
      apply lintegral_congr_ae 
      filterUpwards [Lp.coe_fn_neg_part f₁, hf.coe_fn_to_L1]
      intro a h₁ h₂ 
      rw [h₁, h₂, Ennreal.ofReal]
      congr 1
      apply Nnreal.eq 
      simp only [Real.norm_of_nonneg, min_le_rightₓ, neg_nonneg, Real.coe_to_nnreal', Subtype.coe_mk]
      rw [←max_neg_neg, coe_nnnorm, neg_zero, Real.norm_of_nonneg (le_max_rightₓ (-f a) 0)]
  by 
    rw [eq₁, eq₂, integral, dif_pos]
    exact L1.integral_eq_norm_pos_part_sub _

theorem integral_eq_lintegral_of_nonneg_ae {f : α → ℝ} (hf : 0 ≤ᵐ[μ] f) (hfm : AeMeasurable f μ) :
  (∫a, f a ∂μ) = Ennreal.toReal (∫⁻a, Ennreal.ofReal$ f a ∂μ) :=
  by 
    byCases' hfi : integrable f μ
    ·
      rw [integral_eq_lintegral_pos_part_sub_lintegral_neg_part hfi]
      have h_min : (∫⁻a, Ennreal.ofReal (-f a) ∂μ) = 0
      ·
        rw [lintegral_eq_zero_iff']
        ·
          refine' hf.mono _ 
          simp only [Pi.zero_apply]
          intro a h 
          simp only [h, neg_nonpos, of_real_eq_zero]
        ·
          exact measurable_of_real.comp_ae_measurable hfm.neg 
      rw [h_min, zero_to_real, _root_.sub_zero]
    ·
      rw [integral_undef hfi]
      simpRw [integrable, hfm, has_finite_integral_iff_norm, lt_top_iff_ne_top, Ne.def, true_andₓ, not_not]  at hfi 
      have  : (∫⁻a : α, Ennreal.ofReal (f a) ∂μ) = ∫⁻a, Ennreal.ofReal ∥f a∥ ∂μ
      ·
        refine' lintegral_congr_ae (hf.mono$ fun a h => _)
        rw [Real.norm_eq_abs, abs_of_nonneg h]
      rw [this, hfi]
      rfl

theorem of_real_integral_norm_eq_lintegral_nnnorm {G} [NormedGroup G] [MeasurableSpace G] [OpensMeasurableSpace G]
  {f : α → G} (hf : integrable f μ) : Ennreal.ofReal (∫x, ∥f x∥ ∂μ) = ∫⁻x, ∥f x∥₊ ∂μ :=
  by 
    rw [integral_eq_lintegral_of_nonneg_ae _ hf.1.norm]
    ·
      simpRw [of_real_norm_eq_coe_nnnorm, Ennreal.of_real_to_real (lt_top_iff_ne_top.mp hf.2)]
    ·
      refine' ae_of_all _ _ 
      simp 

theorem integral_eq_integral_pos_part_sub_integral_neg_part {f : α → ℝ} (hf : integrable f μ) :
  (∫a, f a ∂μ) = (∫a, Real.toNnreal (f a) ∂μ) - ∫a, Real.toNnreal (-f a) ∂μ :=
  by 
    rw [←integral_sub hf.real_to_nnreal]
    ·
      simp 
    ·
      exact hf.neg.real_to_nnreal

theorem integral_nonneg_of_ae {f : α → ℝ} (hf : 0 ≤ᵐ[μ] f) : 0 ≤ ∫a, f a ∂μ :=
  by 
    byCases' hfm : AeMeasurable f μ
    ·
      rw [integral_eq_lintegral_of_nonneg_ae hf hfm]
      exact to_real_nonneg
    ·
      rw [integral_non_ae_measurable hfm]

theorem lintegral_coe_eq_integral (f : α →  ℝ≥0 ) (hfi : integrable (fun x => (f x : ℝ)) μ) :
  (∫⁻a, f a ∂μ) = Ennreal.ofReal (∫a, f a ∂μ) :=
  by 
    simpRw [integral_eq_lintegral_of_nonneg_ae (eventually_of_forall fun x => (f x).coe_nonneg) hfi.ae_measurable,
      ←Ennreal.coe_nnreal_eq]
    rw [Ennreal.of_real_to_real]
    rw [←lt_top_iff_ne_top]
    convert hfi.has_finite_integral 
    ext1 x 
    rw [Nnreal.nnnorm_eq]

theorem integral_to_real {f : α → ℝ≥0∞} (hfm : AeMeasurable f μ) (hf : ∀ᵐx ∂μ, f x < ∞) :
  (∫a, (f a).toReal ∂μ) = (∫⁻a, f a ∂μ).toReal :=
  by 
    rw [integral_eq_lintegral_of_nonneg_ae _ hfm.ennreal_to_real]
    ·
      rw [lintegral_congr_ae]
      refine' hf.mp (eventually_of_forall _)
      intro x hx 
      rw [lt_top_iff_ne_top] at hx 
      simp [hx]
    ·
      exact eventually_of_forall$ fun x => Ennreal.to_real_nonneg

theorem lintegral_coe_le_coe_iff_integral_le {f : α →  ℝ≥0 } (hfi : integrable (fun x => (f x : ℝ)) μ) {b :  ℝ≥0 } :
  (∫⁻a, f a ∂μ) ≤ b ↔ (∫a, (f a : ℝ) ∂μ) ≤ b :=
  by 
    rw [lintegral_coe_eq_integral f hfi, Ennreal.ofReal, Ennreal.coe_le_coe, Real.to_nnreal_le_iff_le_coe]

theorem integral_coe_le_of_lintegral_coe_le {f : α →  ℝ≥0 } {b :  ℝ≥0 } (h : (∫⁻a, f a ∂μ) ≤ b) :
  (∫a, (f a : ℝ) ∂μ) ≤ b :=
  by 
    byCases' hf : integrable (fun a => (f a : ℝ)) μ
    ·
      exact (lintegral_coe_le_coe_iff_integral_le hf).1 h
    ·
      rw [integral_undef hf]
      exact b.2

theorem integral_nonneg {f : α → ℝ} (hf : 0 ≤ f) : 0 ≤ ∫a, f a ∂μ :=
  integral_nonneg_of_ae$ eventually_of_forall hf

theorem integral_nonpos_of_ae {f : α → ℝ} (hf : f ≤ᵐ[μ] 0) : (∫a, f a ∂μ) ≤ 0 :=
  by 
    have hf : 0 ≤ᵐ[μ] -f :=
      hf.mono
        fun a h =>
          by 
            rwa [Pi.neg_apply, Pi.zero_apply, neg_nonneg]
    have  : 0 ≤ ∫a, -f a ∂μ := integral_nonneg_of_ae hf 
    rwa [integral_neg, neg_nonneg] at this

theorem integral_nonpos {f : α → ℝ} (hf : f ≤ 0) : (∫a, f a ∂μ) ≤ 0 :=
  integral_nonpos_of_ae$ eventually_of_forall hf

theorem integral_eq_zero_iff_of_nonneg_ae {f : α → ℝ} (hf : 0 ≤ᵐ[μ] f) (hfi : integrable f μ) :
  (∫x, f x ∂μ) = 0 ↔ f =ᵐ[μ] 0 :=
  by 
    simpRw [integral_eq_lintegral_of_nonneg_ae hf hfi.1, Ennreal.to_real_eq_zero_iff,
      lintegral_eq_zero_iff' (ennreal.measurable_of_real.comp_ae_measurable hfi.1), ←Ennreal.not_lt_top,
      ←has_finite_integral_iff_of_real hf, hfi.2, not_true, or_falseₓ, ←hf.le_iff_eq, Filter.EventuallyEq,
      Filter.EventuallyLe, · ∘ ·, Pi.zero_apply, Ennreal.of_real_eq_zero]

theorem integral_eq_zero_iff_of_nonneg {f : α → ℝ} (hf : 0 ≤ f) (hfi : integrable f μ) : (∫x, f x ∂μ) = 0 ↔ f =ᵐ[μ] 0 :=
  integral_eq_zero_iff_of_nonneg_ae (eventually_of_forall hf) hfi

theorem integral_pos_iff_support_of_nonneg_ae {f : α → ℝ} (hf : 0 ≤ᵐ[μ] f) (hfi : integrable f μ) :
  (0 < ∫x, f x ∂μ) ↔ 0 < μ (Function.Support f) :=
  by 
    simpRw [(integral_nonneg_of_ae hf).lt_iff_ne, pos_iff_ne_zero, Ne.def, @eq_comm ℝ 0,
      integral_eq_zero_iff_of_nonneg_ae hf hfi, Filter.EventuallyEq, ae_iff, Pi.zero_apply, Function.Support]

theorem integral_pos_iff_support_of_nonneg {f : α → ℝ} (hf : 0 ≤ f) (hfi : integrable f μ) :
  (0 < ∫x, f x ∂μ) ↔ 0 < μ (Function.Support f) :=
  integral_pos_iff_support_of_nonneg_ae (eventually_of_forall hf) hfi

section NormedGroup

variable{H : Type _}[NormedGroup H][second_countable_topology H][MeasurableSpace H][BorelSpace H]

theorem L1.norm_eq_integral_norm (f : α →₁[μ] H) : ∥f∥ = ∫a, ∥f a∥ ∂μ :=
  by 
    simp only [snorm, snorm', Ennreal.one_to_real, Ennreal.rpow_one, Lp.norm_def, if_false, Ennreal.one_ne_top,
      one_ne_zero, _root_.div_one]
    rw
      [integral_eq_lintegral_of_nonneg_ae
        (eventually_of_forall
          (by 
            simp [norm_nonneg]))
        (continuous_norm.measurable.comp_ae_measurable (Lp.ae_measurable f))]
    simp [of_real_norm_eq_coe_nnnorm]

theorem L1.norm_of_fun_eq_integral_norm {f : α → H} (hf : integrable f μ) : ∥hf.to_L1 f∥ = ∫a, ∥f a∥ ∂μ :=
  by 
    rw [L1.norm_eq_integral_norm]
    refine' integral_congr_ae _ 
    apply hf.coe_fn_to_L1.mono 
    intro a ha 
    simp [ha]

end NormedGroup

theorem integral_mono_ae {f g : α → ℝ} (hf : integrable f μ) (hg : integrable g μ) (h : f ≤ᵐ[μ] g) :
  (∫a, f a ∂μ) ≤ ∫a, g a ∂μ :=
  le_of_sub_nonneg$ integral_sub hg hf ▸ integral_nonneg_of_ae$ h.mono fun a => sub_nonneg_of_le

@[mono]
theorem integral_mono {f g : α → ℝ} (hf : integrable f μ) (hg : integrable g μ) (h : f ≤ g) :
  (∫a, f a ∂μ) ≤ ∫a, g a ∂μ :=
  integral_mono_ae hf hg$ eventually_of_forall h

theorem integral_mono_of_nonneg {f g : α → ℝ} (hf : 0 ≤ᵐ[μ] f) (hgi : integrable g μ) (h : f ≤ᵐ[μ] g) :
  (∫a, f a ∂μ) ≤ ∫a, g a ∂μ :=
  by 
    byCases' hfm : AeMeasurable f μ
    ·
      refine' integral_mono_ae ⟨hfm, _⟩ hgi h 
      refine' hgi.has_finite_integral.mono$ h.mp$ hf.mono$ fun x hf hfg => _ 
      simpa [Real.norm_eq_abs, abs_of_nonneg hf, abs_of_nonneg (le_transₓ hf hfg)]
    ·
      rw [integral_non_ae_measurable hfm]
      exact integral_nonneg_of_ae (hf.trans h)

theorem norm_integral_le_integral_norm (f : α → E) : ∥∫a, f a ∂μ∥ ≤ ∫a, ∥f a∥ ∂μ :=
  have le_ae : ∀ᵐa ∂μ, 0 ≤ ∥f a∥ := eventually_of_forall fun a => norm_nonneg _ 
  Classical.by_cases
    (fun h : AeMeasurable f μ =>
      calc ∥∫a, f a ∂μ∥ ≤ Ennreal.toReal (∫⁻a, Ennreal.ofReal ∥f a∥ ∂μ) := norm_integral_le_lintegral_norm _ 
        _ = ∫a, ∥f a∥ ∂μ := (integral_eq_lintegral_of_nonneg_ae le_ae$ AeMeasurable.norm h).symm
        )
    fun h : ¬AeMeasurable f μ =>
      by 
        rw [integral_non_ae_measurable h, norm_zero]
        exact integral_nonneg_of_ae le_ae

theorem norm_integral_le_of_norm_le {f : α → E} {g : α → ℝ} (hg : integrable g μ) (h : ∀ᵐx ∂μ, ∥f x∥ ≤ g x) :
  ∥∫x, f x ∂μ∥ ≤ ∫x, g x ∂μ :=
  calc ∥∫x, f x ∂μ∥ ≤ ∫x, ∥f x∥ ∂μ := norm_integral_le_integral_norm f 
    _ ≤ ∫x, g x ∂μ := integral_mono_of_nonneg (eventually_of_forall$ fun x => norm_nonneg _) hg h
    

theorem integral_finset_sum {ι} (s : Finset ι) {f : ι → α → E} (hf : ∀ i, integrable (f i) μ) :
  (∫a, ∑i in s, f i a ∂μ) = ∑i in s, ∫a, f i a ∂μ :=
  by 
    refine' Finset.induction_on s _ _
    ·
      simp only [integral_zero, Finset.sum_empty]
    ·
      intro i s his ih 
      simp only [his, Finset.sum_insert, not_false_iff]
      rw [integral_add (hf _) (integrable_finset_sum s hf), ih]

theorem simple_func.integral_eq_integral (f : α →ₛ E) (hfi : integrable f μ) : f.integral μ = ∫x, f x ∂μ :=
  by 
    rw [integral_eq f hfi, ←L1.simple_func.to_Lp_one_eq_to_L1, L1.simple_func.integral_L1_eq_integral,
      L1.simple_func.integral_eq_integral]
    exact simple_func.integral_congr hfi (Lp.simple_func.to_simple_func_to_Lp _ _).symm

theorem simple_func.integral_eq_sum (f : α →ₛ E) (hfi : integrable f μ) :
  (∫x, f x ∂μ) = ∑x in f.range, Ennreal.toReal (μ (f ⁻¹' {x})) • x :=
  by 
    rw [←f.integral_eq_integral hfi, simple_func.integral, ←simple_func.integral_eq]
    rfl

@[simp]
theorem integral_const (c : E) : (∫x : α, c ∂μ) = (μ univ).toReal • c :=
  by 
    cases' (@le_top _ _ _ (μ univ)).lt_or_eq with hμ hμ
    ·
      haveI  : is_finite_measure μ := ⟨hμ⟩
      calc (∫x : α, c ∂μ) = (simple_func.const α c).integral μ :=
        ((simple_func.const α c).integral_eq_integral (integrable_const _)).symm _ = _ := simple_func.integral_const _ _
    ·
      byCases' hc : c = 0
      ·
        simp [hc, integral_zero]
      ·
        have  : ¬integrable (fun x : α => c) μ
        ·
          simp only [integrable_const_iff, not_or_distrib]
          exact ⟨hc, hμ.not_lt⟩
        simp [integral_undef]

theorem norm_integral_le_of_norm_le_const [is_finite_measure μ] {f : α → E} {C : ℝ} (h : ∀ᵐx ∂μ, ∥f x∥ ≤ C) :
  ∥∫x, f x ∂μ∥ ≤ C*(μ univ).toReal :=
  calc ∥∫x, f x ∂μ∥ ≤ ∫x, C ∂μ := norm_integral_le_of_norm_le (integrable_const C) h 
    _ = C*(μ univ).toReal :=
    by 
      rw [integral_const, smul_eq_mul, mul_commₓ]
    

theorem tendsto_integral_approx_on_univ_of_measurable {f : α → E} (fmeas : Measurable f) (hf : integrable f μ) :
  tendsto (fun n => (simple_func.approx_on f fmeas univ 0 trivialₓ n).integral μ) at_top (𝓝$ ∫x, f x ∂μ) :=
  by 
    have  : tendsto (fun n => ∫x, simple_func.approx_on f fmeas univ 0 trivialₓ n x ∂μ) at_top (𝓝$ ∫x, f x ∂μ) :=
      tendsto_integral_of_L1 _ hf (eventually_of_forall$ simple_func.integrable_approx_on_univ fmeas hf)
        (simple_func.tendsto_approx_on_univ_L1_nnnorm fmeas hf)
    simpa only [simple_func.integral_eq_integral, simple_func.integrable_approx_on_univ fmeas hf]

variable{ν : Measureₓ α}

private theorem integral_add_measure_of_measurable {f : α → E} (fmeas : Measurable f) (hμ : integrable f μ)
  (hν : integrable f ν) : (∫x, f x ∂μ+ν) = (∫x, f x ∂μ)+∫x, f x ∂ν :=
  by 
    have hfi := hμ.add_measure hν 
    refine' tendsto_nhds_unique (tendsto_integral_approx_on_univ_of_measurable fmeas hfi) _ 
    simpa only [simple_func.integral_add_measure _ (simple_func.integrable_approx_on_univ fmeas hfi _)] using
      (tendsto_integral_approx_on_univ_of_measurable fmeas hμ).add
        (tendsto_integral_approx_on_univ_of_measurable fmeas hν)

theorem integral_add_measure {f : α → E} (hμ : integrable f μ) (hν : integrable f ν) :
  (∫x, f x ∂μ+ν) = (∫x, f x ∂μ)+∫x, f x ∂ν :=
  by 
    have h : AeMeasurable f (μ+ν) := hμ.ae_measurable.add_measure hν.ae_measurable 
    let g := h.mk f 
    have A : f =ᵐ[μ+ν] g := h.ae_eq_mk 
    have B : f =ᵐ[μ] g := A.filter_mono (ae_mono (measure.le_add_right (le_reflₓ μ)))
    have C : f =ᵐ[ν] g := A.filter_mono (ae_mono (measure.le_add_left (le_reflₓ ν)))
    calc (∫x, f x ∂μ+ν) = ∫x, g x ∂μ+ν := integral_congr_ae A _ = (∫x, g x ∂μ)+∫x, g x ∂ν :=
      integral_add_measure_of_measurable h.measurable_mk ((integrable_congr B).1 hμ)
        ((integrable_congr C).1 hν)_ = (∫x, f x ∂μ)+∫x, f x ∂ν :=
      by 
        congr 1
        ·
          exact integral_congr_ae B.symm
        ·
          exact integral_congr_ae C.symm

@[simp]
theorem integral_zero_measure {m : MeasurableSpace α} (f : α → E) : (∫x, f x ∂(0 : Measureₓ α)) = 0 :=
  norm_le_zero_iff.1$
    le_transₓ (norm_integral_le_lintegral_norm f)$
      by 
        simp 

private theorem integral_smul_measure_aux {f : α → E} {c : ℝ≥0∞} (h0 : c ≠ 0) (hc : c ≠ ∞) (fmeas : Measurable f)
  (hfi : integrable f μ) : (∫x, f x ∂c • μ) = c.to_real • ∫x, f x ∂μ :=
  by 
    refine' tendsto_nhds_unique _ (tendsto_const_nhds.smul (tendsto_integral_approx_on_univ_of_measurable fmeas hfi))
    convert tendsto_integral_approx_on_univ_of_measurable fmeas (hfi.smul_measure hc)
    simp only [simple_func.integral_eq, measure.smul_apply, Finset.smul_sum, smul_smul, Ennreal.to_real_mul]

@[simp]
theorem integral_smul_measure (f : α → E) (c : ℝ≥0∞) : (∫x, f x ∂c • μ) = c.to_real • ∫x, f x ∂μ :=
  by 
    rcases eq_or_ne c 0 with (rfl | h0)
    ·
      simp 
    byCases' hfm : AeMeasurable f μ 
    swap
    ·
      have  : ¬AeMeasurable f (c • μ)
      ·
        simpa [h0] using hfm 
      simp [integral_non_ae_measurable, hfm, this]
    rcases eq_or_ne c ∞ with (rfl | hc)
    ·
      rw [Ennreal.top_to_real, zero_smul]
      byCases' hf : f =ᵐ[μ] 0
      ·
        have  : f =ᵐ[∞ • μ] 0 := ae_smul_measure hf ∞
        exact integral_eq_zero_of_ae this
      ·
        apply integral_undef 
        rw [integrable, has_finite_integral, iff_true_intro (hfm.smul_measure ∞), true_andₓ, lintegral_smul_measure,
          top_mul, if_neg]
        ·
          apply lt_irreflₓ
        ·
          rw [lintegral_eq_zero_iff' hfm.ennnorm]
          refine' fun h => hf (h.mono$ fun x => _)
          simp 
    byCases' hfi : integrable f μ 
    swap
    ·
      rw [integral_undef hfi, smul_zero]
      refine' integral_undef (mt (fun h => _) hfi)
      convert h.smul_measure (Ennreal.inv_ne_top.2 h0)
      rw [smul_smul, Ennreal.inv_mul_cancel h0 hc, one_smul]
    let g := hfm.mk f 
    calc (∫x, f x ∂c • μ) = ∫x, g x ∂c • μ :=
      integral_congr_ae$ ae_smul_measure hfm.ae_eq_mk c _ = c.to_real • ∫x, g x ∂μ :=
      integral_smul_measure_aux h0 hc hfm.measurable_mk$ hfi.congr hfm.ae_eq_mk _ = c.to_real • ∫x, f x ∂μ :=
      by 
        congr 1 
        exact integral_congr_ae hfm.ae_eq_mk.symm

theorem integral_map_of_measurable {β} [MeasurableSpace β] {φ : α → β} (hφ : Measurable φ) {f : β → E}
  (hfm : Measurable f) : (∫y, f y ∂measure.map φ μ) = ∫x, f (φ x) ∂μ :=
  by 
    byCases' hfi : integrable f (measure.map φ μ)
    swap
    ·
      rw [integral_undef hfi, integral_undef]
      rwa [←integrable_map_measure hfm.ae_measurable hφ]
    refine' tendsto_nhds_unique (tendsto_integral_approx_on_univ_of_measurable hfm hfi) _ 
    convert
      tendsto_integral_approx_on_univ_of_measurable (hfm.comp hφ) ((integrable_map_measure hfm.ae_measurable hφ).1 hfi)
    ext1 i 
    simp only [simple_func.approx_on_comp, simple_func.integral_eq, measure.map_apply, hφ,
      simple_func.measurable_set_preimage, ←preimage_comp, simple_func.coe_comp]
    refine' (Finset.sum_subset (simple_func.range_comp_subset_range _ hφ) fun y _ hy => _).symm 
    rw [simple_func.mem_range, ←Set.preimage_singleton_eq_empty, simple_func.coe_comp] at hy 
    simp [hy]

theorem integral_map {β} [MeasurableSpace β] {φ : α → β} (hφ : Measurable φ) {f : β → E}
  (hfm : AeMeasurable f (measure.map φ μ)) : (∫y, f y ∂measure.map φ μ) = ∫x, f (φ x) ∂μ :=
  let g := hfm.mk f 
  calc (∫y, f y ∂measure.map φ μ) = ∫y, g y ∂measure.map φ μ := integral_congr_ae hfm.ae_eq_mk 
    _ = ∫x, g (φ x) ∂μ := integral_map_of_measurable hφ hfm.measurable_mk 
    _ = ∫x, f (φ x) ∂μ := integral_congr_ae$ ae_eq_comp hφ hfm.ae_eq_mk.symm
    

theorem _root_.measurable_embedding.integral_map {β} {_ : MeasurableSpace β} {f : α → β} (hf : MeasurableEmbedding f)
  (g : β → E) : (∫y, g y ∂measure.map f μ) = ∫x, g (f x) ∂μ :=
  by 
    byCases' hgm : AeMeasurable g (measure.map f μ)
    ·
      exact integral_map hf.measurable hgm
    ·
      rw [integral_non_ae_measurable hgm, integral_non_ae_measurable]
      rwa [←hf.ae_measurable_map_iff]

theorem _root_.closed_embedding.integral_map {β} [TopologicalSpace α] [BorelSpace α] [TopologicalSpace β]
  [MeasurableSpace β] [BorelSpace β] {φ : α → β} (hφ : ClosedEmbedding φ) (f : β → E) :
  (∫y, f y ∂measure.map φ μ) = ∫x, f (φ x) ∂μ :=
  hφ.measurable_embedding.integral_map _

theorem integral_map_equiv {β} [MeasurableSpace β] (e : α ≃ᵐ β) (f : β → E) :
  (∫y, f y ∂measure.map e μ) = ∫x, f (e x) ∂μ :=
  e.measurable_embedding.integral_map f

@[simp]
theorem integral_dirac' [MeasurableSpace α] (f : α → E) (a : α) (hfm : Measurable f) :
  (∫x, f x ∂measure.dirac a) = f a :=
  calc (∫x, f x ∂measure.dirac a) = ∫x, f a ∂measure.dirac a := integral_congr_ae$ ae_eq_dirac' hfm 
    _ = f a :=
    by 
      simp [measure.dirac_apply_of_mem]
    

@[simp]
theorem integral_dirac [MeasurableSpace α] [MeasurableSingletonClass α] (f : α → E) (a : α) :
  (∫x, f x ∂measure.dirac a) = f a :=
  calc (∫x, f x ∂measure.dirac a) = ∫x, f a ∂measure.dirac a := integral_congr_ae$ ae_eq_dirac f 
    _ = f a :=
    by 
      simp [measure.dirac_apply_of_mem]
    

end Properties

section Groupₓ

variable{G : Type _}[MeasurableSpace G][TopologicalSpace G][Groupₓ G][HasContinuousMul G][BorelSpace G]

variable{μ : Measureₓ G}

open Measureₓ

/-- Translating a function by left-multiplication does not change its integral with respect to a
left-invariant measure. -/
@[toAdditive]
theorem integral_mul_left_eq_self (hμ : is_mul_left_invariant μ) {f : G → E} (g : G) : (∫x, f (g*x) ∂μ) = ∫x, f x ∂μ :=
  by 
    have hgμ : measure.map (Mul.mul g) μ = μ
    ·
      rw [←map_mul_left_eq_self] at hμ 
      exact hμ g 
    have h_mul : ClosedEmbedding fun x => g*x := (Homeomorph.mulLeft g).ClosedEmbedding 
    rw [←h_mul.integral_map, hgμ]
    infer_instance

/-- Translating a function by right-multiplication does not change its integral with respect to a
right-invariant measure. -/
@[toAdditive]
theorem integral_mul_right_eq_self (hμ : is_mul_right_invariant μ) {f : G → E} (g : G) :
  (∫x, f (x*g) ∂μ) = ∫x, f x ∂μ :=
  by 
    have hgμ : measure.map (fun x => x*g) μ = μ
    ·
      rw [←map_mul_right_eq_self] at hμ 
      exact hμ g 
    have h_mul : ClosedEmbedding fun x => x*g := (Homeomorph.mulRight g).ClosedEmbedding 
    rw [←h_mul.integral_map, hgμ]
    infer_instance

/-- If some left-translate of a function negates it, then the integral of the function with respect
to a left-invariant measure is 0. -/
@[toAdditive]
theorem integral_zero_of_mul_left_eq_neg (hμ : is_mul_left_invariant μ) {f : G → E} {g : G}
  (hf' : ∀ x, f (g*x) = -f x) : (∫x, f x ∂μ) = 0 :=
  by 
    refine' eq_zero_of_eq_neg ℝ (Eq.symm _)
    have  : (∫x, f (g*x) ∂μ) = ∫x, -f x ∂μ
    ·
      congr 
      ext x 
      exact hf' x 
    convert integral_mul_left_eq_self hμ g using 1
    rw [this, integral_neg]

/-- If some right-translate of a function negates it, then the integral of the function with respect
to a right-invariant measure is 0. -/
@[toAdditive]
theorem integral_zero_of_mul_right_eq_neg (hμ : is_mul_right_invariant μ) {f : G → E} {g : G}
  (hf' : ∀ x, f (x*g) = -f x) : (∫x, f x ∂μ) = 0 :=
  by 
    refine' eq_zero_of_eq_neg ℝ (Eq.symm _)
    have  : (∫x, f (x*g) ∂μ) = ∫x, -f x ∂μ
    ·
      congr 
      ext x 
      exact hf' x 
    convert integral_mul_right_eq_self hμ g using 1
    rw [this, integral_neg]

end Groupₓ

mk_simp_attribute integral_simps := "Simp set for integral rules."

attribute [integral_simps] integral_neg integral_smul L1.integral_add L1.integral_sub L1.integral_smul L1.integral_neg

attribute [irreducible] integral L1.integral

section IntegralTrim

variable{H β γ : Type _}[NormedGroup H][MeasurableSpace H]{m m0 : MeasurableSpace β}{μ : Measureₓ β}

/-- Simple function seen as simple function of a larger `measurable_space`. -/
def simple_func.to_larger_space (hm : m ≤ m0) (f : @simple_func β m γ) : simple_func β γ :=
  ⟨@simple_func.to_fun β m γ f, fun x => hm _ (@simple_func.measurable_set_fiber β γ m f x),
    @simple_func.finite_range β γ m f⟩

theorem simple_func.coe_to_larger_space_eq (hm : m ≤ m0) (f : @simple_func β m γ) :
  «expr⇑ » (f.to_larger_space hm) = f :=
  rfl

theorem integral_simple_func_larger_space (hm : m ≤ m0) (f : @simple_func β m F) (hf_int : integrable f μ) :
  (∫x, f x ∂μ) = ∑x in @simple_func.range β F m f, Ennreal.toReal (μ (f ⁻¹' {x})) • x :=
  by 
    simpRw [←f.coe_to_larger_space_eq hm]
    have hf_int : integrable (f.to_larger_space hm) μ
    ·
      rwa [simple_func.coe_to_larger_space_eq]
    rw [simple_func.integral_eq_sum _ hf_int]
    congr

theorem integral_trim_simple_func (hm : m ≤ m0) (f : @simple_func β m F) (hf_int : integrable f μ) :
  (∫x, f x ∂μ) = ∫x, f x ∂μ.trim hm :=
  by 
    have hf : @Measurable _ _ m _ f 
    exact @simple_func.measurable β F m _ f 
    have hf_int_m := hf_int.trim hm hf 
    rw [integral_simple_func_larger_space le_rfl f hf_int_m, integral_simple_func_larger_space hm f hf_int]
    congr 
    ext1 x 
    congr 
    exact (trim_measurable_set_eq hm (@simple_func.measurable_set_fiber β F m f x)).symm

theorem integral_trim (hm : m ≤ m0) {f : β → F} (hf : @Measurable β F m _ f) : (∫x, f x ∂μ) = ∫x, f x ∂μ.trim hm :=
  by 
    byCases' hf_int : integrable f μ 
    swap
    ·
      have hf_int_m : ¬integrable f (μ.trim hm)
      exact fun hf_int_m => hf_int (integrable_of_integrable_trim hm hf_int_m)
      rw [integral_undef hf_int, integral_undef hf_int_m]
    let f_seq := @simple_func.approx_on F β _ _ _ m _ hf Set.Univ 0 (Set.mem_univ 0) _ 
    have hf_seq_meas : ∀ n, @Measurable _ _ m _ (f_seq n)
    exact fun n => @simple_func.measurable β F m _ (f_seq n)
    have hf_seq_int : ∀ n, integrable (f_seq n) μ 
    exact simple_func.integrable_approx_on_univ (hf.mono hm le_rfl) hf_int 
    have hf_seq_int_m : ∀ n, integrable (f_seq n) (μ.trim hm)
    exact fun n => (hf_seq_int n).trim hm (hf_seq_meas n)
    have hf_seq_eq : ∀ n, (∫x, f_seq n x ∂μ) = ∫x, f_seq n x ∂μ.trim hm 
    exact fun n => integral_trim_simple_func hm (f_seq n) (hf_seq_int n)
    have h_lim_1 : at_top.tendsto (fun n => ∫x, f_seq n x ∂μ) (𝓝 (∫x, f x ∂μ))
    ·
      refine' tendsto_integral_of_L1 f hf_int (eventually_of_forall hf_seq_int) _ 
      exact simple_func.tendsto_approx_on_univ_L1_nnnorm (hf.mono hm le_rfl) hf_int 
    have h_lim_2 : at_top.tendsto (fun n => ∫x, f_seq n x ∂μ) (𝓝 (∫x, f x ∂μ.trim hm))
    ·
      simpRw [hf_seq_eq]
      refine'
        @tendsto_integral_of_L1 β F _ _ _ _ _ _ m (μ.trim hm) _ f (hf_int.trim hm hf) _ _
          (eventually_of_forall hf_seq_int_m) _ 
      exact @simple_func.tendsto_approx_on_univ_L1_nnnorm β F m _ _ _ _ f _ hf (hf_int.trim hm hf)
    exact tendsto_nhds_unique h_lim_1 h_lim_2

theorem integral_trim_ae (hm : m ≤ m0) {f : β → F} (hf : AeMeasurable f (μ.trim hm)) :
  (∫x, f x ∂μ) = ∫x, f x ∂μ.trim hm :=
  by 
    rw [integral_congr_ae (ae_eq_of_ae_eq_trim hf.ae_eq_mk), integral_congr_ae hf.ae_eq_mk]
    exact integral_trim hm hf.measurable_mk

theorem ae_eq_trim_of_measurable [MeasurableSpace γ] [AddGroupₓ γ] [MeasurableSingletonClass γ] [HasMeasurableSub₂ γ]
  (hm : m ≤ m0) {f g : β → γ} (hf : @Measurable _ _ m _ f) (hg : @Measurable _ _ m _ g) (hfg : f =ᵐ[μ] g) :
  f =ᵐ[μ.trim hm] g :=
  by 
    rwa [eventually_eq, ae_iff, trim_measurable_set_eq hm _]
    exact @MeasurableSet.compl β _ m (@measurable_set_eq_fun β m γ _ _ _ _ _ _ hf hg)

theorem ae_eq_trim_iff [MeasurableSpace γ] [AddGroupₓ γ] [MeasurableSingletonClass γ] [HasMeasurableSub₂ γ]
  (hm : m ≤ m0) {f g : β → γ} (hf : @Measurable _ _ m _ f) (hg : @Measurable _ _ m _ g) :
  f =ᵐ[μ.trim hm] g ↔ f =ᵐ[μ] g :=
  ⟨ae_eq_of_ae_eq_trim, ae_eq_trim_of_measurable hm hf hg⟩

end IntegralTrim

end MeasureTheory

