/-
Copyright (c) 2021 Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Heather Macbeth
-/
import Mathbin.Analysis.Complex.Circle
import Mathbin.Analysis.InnerProductSpace.L2Space
import Mathbin.MeasureTheory.Function.ContinuousMapDense
import Mathbin.MeasureTheory.Function.L2Space
import Mathbin.MeasureTheory.Measure.Haar
import Mathbin.MeasureTheory.Group.Integration
import Mathbin.Topology.MetricSpace.EmetricParacompact
import Mathbin.Topology.ContinuousFunction.StoneWeierstrass

/-!

# Fourier analysis on the circle

This file contains basic results on Fourier series.

## Main definitions

* `haar_circle`, Haar measure on the circle, normalized to have total measure `1`
* instances `measure_space`, `is_probability_measure` for the circle with respect to this measure
* for `n : ℤ`, `fourier n` is the monomial `λ z, z ^ n`, bundled as a continuous map from `circle`
  to `ℂ`
* for `n : ℤ` and `p : ℝ≥0∞`, `fourier_Lp p n` is an abbreviation for the monomial `fourier n`
  considered as an element of the Lᵖ-space `Lp ℂ p haar_circle`, via the embedding
  `continuous_map.to_Lp`
* `fourier_series` is the canonical isometric isomorphism from `Lp ℂ 2 haar_circle` to `ℓ²(ℤ, ℂ)`
  induced by taking Fourier series

## Main statements

The theorem `span_fourier_closure_eq_top` states that the span of the monomials `fourier n` is
dense in `C(circle, ℂ)`, i.e. that its `submodule.topological_closure` is `⊤`.  This follows from
the Stone-Weierstrass theorem after checking that it is a subalgebra, closed under conjugation, and
separates points.

The theorem `span_fourier_Lp_closure_eq_top` states that for `1 ≤ p < ∞` the span of the monomials
`fourier_Lp` is dense in `Lp ℂ p haar_circle`, i.e. that its `submodule.topological_closure` is
`⊤`.  This follows from the previous theorem using general theory on approximation of Lᵖ functions
by continuous functions.

The theorem `orthonormal_fourier` states that the monomials `fourier_Lp 2 n` form an orthonormal
set (in the L² space of the circle).

The last two results together provide that the functions `fourier_Lp 2 n` form a Hilbert basis for
L²; this is named as `fourier_series`.

Parseval's identity, `tsum_sq_fourier_series_repr`, is a direct consequence of the construction of
this Hilbert basis.
-/


noncomputable section

open Ennreal ComplexConjugate Classical

open TopologicalSpace ContinuousMap MeasureTheory MeasureTheory.Measure Algebra Submodule Set

/-! ### Choice of measure on the circle -/


section haarCircle

/-! We make the circle into a measure space, using the Haar measure normalized to have total
measure 1. -/


instance : MeasurableSpace circle :=
  borel circle

instance : BorelSpace circle :=
  ⟨rfl⟩

/-- Haar measure on the circle, normalized to have total measure 1. -/
def haarCircle : Measureₓ circle :=
  haarMeasure ⊤deriving IsHaarMeasure

instance : IsProbabilityMeasure haarCircle :=
  ⟨haar_measure_self⟩

instance : MeasureSpace circle :=
  { circle.measurableSpace with volume := haarCircle }

end haarCircle

/-! ### Monomials on the circle -/


section Monomials

/-- The family of monomials `λ z, z ^ n`, parametrized by `n : ℤ` and considered as bundled
continuous maps from `circle` to `ℂ`. -/
@[simps]
def fourier (n : ℤ) : C(circle, ℂ) where
  toFun := fun z => z ^ n
  continuous_to_fun := (continuous_subtype_coe.zpow₀ n) fun z => Or.inl (ne_zero_of_mem_circle z)

@[simp]
theorem fourier_zero {z : circle} : fourier 0 z = 1 :=
  rfl

@[simp]
theorem fourier_neg {n : ℤ} {z : circle} : fourier (-n) z = conj (fourier n z) := by
  simp [← coe_inv_circle_eq_conj z]

@[simp]
theorem fourier_add {m n : ℤ} {z : circle} : fourier (m + n) z = fourier m z * fourier n z := by
  simp [zpow_add₀ (ne_zero_of_mem_circle z)]

/-- The subalgebra of `C(circle, ℂ)` generated by `z ^ n` for `n ∈ ℤ`; equivalently, polynomials in
`z` and `conj z`. -/
def fourierSubalgebra : Subalgebra ℂ C(circle, ℂ) :=
  Algebra.adjoin ℂ (Range fourier)

/-- The subalgebra of `C(circle, ℂ)` generated by `z ^ n` for `n ∈ ℤ` is in fact the linear span of
these functions. -/
theorem fourier_subalgebra_coe : fourierSubalgebra.toSubmodule = span ℂ (Range fourier) := by
  apply adjoin_eq_span_of_subset
  refine' subset.trans _ Submodule.subset_span
  intro x hx
  apply Submonoid.closure_induction hx (fun _ => id) ⟨0, rfl⟩
  rintro _ _ ⟨m, rfl⟩ ⟨n, rfl⟩
  refine' ⟨m + n, _⟩
  ext1 z
  exact fourier_add

/-- The subalgebra of `C(circle, ℂ)` generated by `z ^ n` for `n ∈ ℤ` separates points. -/
theorem fourier_subalgebra_separates_points : fourierSubalgebra.SeparatesPoints := by
  intro x y hxy
  refine' ⟨_, ⟨fourier 1, _, rfl⟩, _⟩
  · exact subset_adjoin ⟨1, rfl⟩
    
  · simp [hxy]
    

/-- The subalgebra of `C(circle, ℂ)` generated by `z ^ n` for `n ∈ ℤ` is invariant under complex
conjugation. -/
theorem fourier_subalgebra_conj_invariant : ConjInvariantSubalgebra (fourierSubalgebra.restrictScalars ℝ) := by
  rintro _ ⟨f, hf, rfl⟩
  change _ ∈ fourierSubalgebra
  change _ ∈ fourierSubalgebra at hf
  apply adjoin_induction hf
  · rintro _ ⟨n, rfl⟩
    suffices fourier (-n) ∈ fourierSubalgebra by
      convert this
      ext1
      simp
    exact subset_adjoin ⟨-n, rfl⟩
    
  · intro c
    exact fourier_subalgebra.algebra_map_mem (conj c)
    
  · intro f g hf hg
    convert fourier_subalgebra.add_mem hf hg
    exact AlgHom.map_add _ f g
    
  · intro f g hf hg
    convert fourier_subalgebra.mul_mem hf hg
    exact AlgHom.map_mul _ f g
    

/-- The subalgebra of `C(circle, ℂ)` generated by `z ^ n` for `n ∈ ℤ` is dense. -/
theorem fourier_subalgebra_closure_eq_top : fourierSubalgebra.topologicalClosure = ⊤ :=
  ContinuousMap.subalgebra_is_R_or_C_topological_closure_eq_top_of_separates_points fourierSubalgebra
    fourier_subalgebra_separates_points fourier_subalgebra_conj_invariant

/-- The linear span of the monomials `z ^ n` is dense in `C(circle, ℂ)`. -/
theorem span_fourier_closure_eq_top : (span ℂ (Range fourier)).topologicalClosure = ⊤ := by
  rw [← fourier_subalgebra_coe]
  exact congr_argₓ Subalgebra.toSubmodule fourier_subalgebra_closure_eq_top

/-- The family of monomials `λ z, z ^ n`, parametrized by `n : ℤ` and considered as elements of
the `Lp` space of functions on `circle` taking values in `ℂ`. -/
abbrev fourierLp (p : ℝ≥0∞) [Fact (1 ≤ p)] (n : ℤ) : lp ℂ p haarCircle :=
  toLp p haarCircle ℂ (fourier n)

theorem coe_fn_fourier_Lp (p : ℝ≥0∞) [Fact (1 ≤ p)] (n : ℤ) : ⇑(fourierLp p n) =ᵐ[haarCircle] fourier n :=
  coe_fn_to_Lp haarCircle (fourier n)

/-- For each `1 ≤ p < ∞`, the linear span of the monomials `z ^ n` is dense in
`Lp ℂ p haar_circle`. -/
theorem span_fourier_Lp_closure_eq_top {p : ℝ≥0∞} [Fact (1 ≤ p)] (hp : p ≠ ∞) :
    (span ℂ (Range (fourierLp p))).topologicalClosure = ⊤ := by
  convert
    (ContinuousMap.to_Lp_dense_range ℂ hp haarCircle ℂ).topological_closure_map_submodule span_fourier_closure_eq_top
  rw [map_span, range_comp]
  simp

/-- For `n ≠ 0`, a rotation by `n⁻¹ * real.pi` negates the monomial `z ^ n`. -/
theorem fourier_add_half_inv_index {n : ℤ} (hn : n ≠ 0) (z : circle) :
    fourier n (expMapCircle (n⁻¹ * Real.pi) * z) = -fourier n z := by
  have : ↑n * ((↑n)⁻¹ * ↑Real.pi * Complex.i) = ↑Real.pi * Complex.i := by
    have : (n : ℂ) ≠ 0 := by
      exact_mod_cast hn
    field_simp
    ring
  simp [mul_zpow, ← Complex.exp_int_mul, Complex.exp_pi_mul_I, this]

/-- The monomials `z ^ n` are an orthonormal set with respect to Haar measure on the circle. -/
theorem orthonormal_fourier : Orthonormal ℂ (fourierLp 2) := by
  rw [orthonormal_iff_ite]
  intro i j
  rw [continuous_map.inner_to_Lp haarCircle (fourier i) (fourier j)]
  split_ifs
  · simp [h, is_probability_measure.measure_univ, ← fourier_neg, ← fourier_add, -fourier_apply]
    
  simp only [← fourier_add, ← fourier_neg]
  have hij : -i + j ≠ 0 := by
    rw [add_commₓ]
    exact sub_ne_zero.mpr (Ne.symm h)
  exact integral_eq_zero_of_mul_left_eq_neg (fourier_add_half_inv_index hij)

end Monomials

section fourier

/-- We define `fourier_series` to be a `ℤ`-indexed Hilbert basis for `Lp ℂ 2 haar_circle`, which by
definition is an isometric isomorphism from `Lp ℂ 2 haar_circle` to `ℓ²(ℤ, ℂ)`. -/
def fourierSeries : HilbertBasis ℤ ℂ (lp ℂ 2 haarCircle) :=
  HilbertBasis.mk orthonormal_fourier
    (span_fourier_Lp_closure_eq_top
        (by
          norm_num)).Ge

/-- The elements of the Hilbert basis `fourier_series` for `Lp ℂ 2 haar_circle` are the functions
`fourier_Lp 2`, the monomials `λ z, z ^ n` on the circle considered as elements of `L2`. -/
@[simp]
theorem coe_fourier_series : ⇑fourierSeries = fourierLp 2 :=
  HilbertBasis.coe_mk _ _

/-- Under the isometric isomorphism `fourier_series` from `Lp ℂ 2 haar_circle` to `ℓ²(ℤ, ℂ)`, the
`i`-th coefficient is the integral over the circle of `λ t, t ^ (-i) * f t`. -/
theorem fourier_series_repr (f : lp ℂ 2 haarCircle) (i : ℤ) :
    fourierSeries.repr f i = ∫ t : circle, t ^ -i * f t ∂haarCircle := by
  trans ∫ t : circle, conj ((fourierLp 2 i : circle → ℂ) t) * f t ∂haarCircle
  · simp [fourier_series.repr_apply_apply f i, MeasureTheory.L2.inner_def]
    
  apply integral_congr_ae
  filter_upwards [coe_fn_fourier_Lp 2 i] with _ ht
  rw [ht, ← fourier_neg]
  simp [-fourier_neg]

/-- The Fourier series of an `L2` function `f` sums to `f`, in the `L2` topology on the circle. -/
theorem has_sum_fourier_series (f : lp ℂ 2 haarCircle) : HasSum (fun i => fourierSeries.repr f i • fourierLp 2 i) f :=
  by
  simpa using HilbertBasis.has_sum_repr fourierSeries f

/-- **Parseval's identity**: the sum of the squared norms of the Fourier coefficients equals the
`L2` norm of the function. -/
theorem tsum_sq_fourier_series_repr (f : lp ℂ 2 haarCircle) :
    (∑' i : ℤ, ∥fourierSeries.repr f i∥ ^ 2) = ∫ t : circle, ∥f t∥ ^ 2 ∂haarCircle := by
  have H₁ : ∥fourier_series.repr f∥ ^ 2 = ∑' i, ∥fourier_series.repr f i∥ ^ 2 := by
    exact_mod_cast lp.norm_rpow_eq_tsum _ (fourier_series.repr f)
    norm_num
  have H₂ : ∥fourier_series.repr f∥ ^ 2 = ∥f∥ ^ 2 := by
    simp
  have H₃ := congr_argₓ IsROrC.re (@L2.inner_def circle ℂ ℂ _ _ _ _ f f)
  rw [← integral_re] at H₃
  · simp only [← norm_sq_eq_inner] at H₃
    rw [← H₁, H₂]
    exact H₃
    
  · exact L2.integrable_inner f f
    

end fourier

