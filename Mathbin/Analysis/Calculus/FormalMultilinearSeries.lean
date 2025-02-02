/-
Copyright (c) 2019 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel
-/
import Mathbin.Analysis.NormedSpace.Multilinear

/-!
# Formal multilinear series

In this file we define `formal_multilinear_series 𝕜 E F` to be a family of `n`-multilinear maps for
all `n`, designed to model the sequence of derivatives of a function. In other files we use this
notion to define `C^n` functions (called `cont_diff` in `mathlib`) and analytic functions.

## Notations

We use the notation `E [×n]→L[𝕜] F` for the space of continuous multilinear maps on `E^n` with
values in `F`. This is the space in which the `n`-th derivative of a function from `E` to `F` lives.

## Tags

multilinear, formal series
-/


noncomputable section

open Set Finₓ

open TopologicalSpace

variable {𝕜 𝕜' E F G : Type _}

section

variable [CommRingₓ 𝕜] [AddCommGroupₓ E] [Module 𝕜 E] [TopologicalSpace E] [TopologicalAddGroup E]
  [HasContinuousConstSmul 𝕜 E] [AddCommGroupₓ F] [Module 𝕜 F] [TopologicalSpace F] [TopologicalAddGroup F]
  [HasContinuousConstSmul 𝕜 F] [AddCommGroupₓ G] [Module 𝕜 G] [TopologicalSpace G] [TopologicalAddGroup G]
  [HasContinuousConstSmul 𝕜 G]

/-- A formal multilinear series over a field `𝕜`, from `E` to `F`, is given by a family of
multilinear maps from `E^n` to `F` for all `n`. -/
@[nolint unused_arguments]
def FormalMultilinearSeries (𝕜 : Type _) (E : Type _) (F : Type _) [Ringₓ 𝕜] [AddCommGroupₓ E] [Module 𝕜 E]
    [TopologicalSpace E] [TopologicalAddGroup E] [HasContinuousConstSmul 𝕜 E] [AddCommGroupₓ F] [Module 𝕜 F]
    [TopologicalSpace F] [TopologicalAddGroup F] [HasContinuousConstSmul 𝕜 F] :=
  ∀ n : ℕ, E[×n]→L[𝕜] F deriving AddCommGroupₓ

instance : Inhabited (FormalMultilinearSeries 𝕜 E F) :=
  ⟨0⟩

section Module

/- `derive` is not able to find the module structure, probably because Lean is confused by the
dependent types. We register it explicitly. -/
instance : Module 𝕜 (FormalMultilinearSeries 𝕜 E F) := by
  letI : ∀ n, Module 𝕜 (ContinuousMultilinearMap 𝕜 (fun i : Finₓ n => E) F) := fun n => by
    infer_instance
  refine' Pi.module _ _ _

end Module

namespace FormalMultilinearSeries

protected theorem ext_iff {p q : FormalMultilinearSeries 𝕜 E F} : p = q ↔ ∀ n, p n = q n :=
  Function.funext_iff

protected theorem ne_iff {p q : FormalMultilinearSeries 𝕜 E F} : p ≠ q ↔ ∃ n, p n ≠ q n :=
  Function.ne_iff

/-- Killing the zeroth coefficient in a formal multilinear series -/
def removeZero (p : FormalMultilinearSeries 𝕜 E F) : FormalMultilinearSeries 𝕜 E F
  | 0 => 0
  | n + 1 => p (n + 1)

@[simp]
theorem remove_zero_coeff_zero (p : FormalMultilinearSeries 𝕜 E F) : p.removeZero 0 = 0 :=
  rfl

@[simp]
theorem remove_zero_coeff_succ (p : FormalMultilinearSeries 𝕜 E F) (n : ℕ) : p.removeZero (n + 1) = p (n + 1) :=
  rfl

theorem remove_zero_of_pos (p : FormalMultilinearSeries 𝕜 E F) {n : ℕ} (h : 0 < n) : p.removeZero n = p n := by
  rw [← Nat.succ_pred_eq_of_posₓ h]
  rfl

/-- Convenience congruence lemma stating in a dependent setting that, if the arguments to a formal
multilinear series are equal, then the values are also equal. -/
theorem congr (p : FormalMultilinearSeries 𝕜 E F) {m n : ℕ} {v : Finₓ m → E} {w : Finₓ n → E} (h1 : m = n)
    (h2 : ∀ (i : ℕ) (him : i < m) (hin : i < n), v ⟨i, him⟩ = w ⟨i, hin⟩) : p m v = p n w := by
  cases h1
  congr with ⟨i, hi⟩
  exact h2 i hi hi

/-- Composing each term `pₙ` in a formal multilinear series with `(u, ..., u)` where `u` is a fixed
continuous linear map, gives a new formal multilinear series `p.comp_continuous_linear_map u`. -/
def compContinuousLinearMap (p : FormalMultilinearSeries 𝕜 F G) (u : E →L[𝕜] F) : FormalMultilinearSeries 𝕜 E G :=
  fun n => (p n).compContinuousLinearMap fun i : Finₓ n => u

@[simp]
theorem comp_continuous_linear_map_apply (p : FormalMultilinearSeries 𝕜 F G) (u : E →L[𝕜] F) (n : ℕ) (v : Finₓ n → E) :
    (p.compContinuousLinearMap u) n v = p n (u ∘ v) :=
  rfl

variable (𝕜) [CommRingₓ 𝕜'] [HasSmul 𝕜 𝕜']

variable [Module 𝕜' E] [HasContinuousConstSmul 𝕜' E] [IsScalarTower 𝕜 𝕜' E]

variable [Module 𝕜' F] [HasContinuousConstSmul 𝕜' F] [IsScalarTower 𝕜 𝕜' F]

/-- Reinterpret a formal `𝕜'`-multilinear series as a formal `𝕜`-multilinear series. -/
@[simp]
protected def restrictScalars (p : FormalMultilinearSeries 𝕜' E F) : FormalMultilinearSeries 𝕜 E F := fun n =>
  (p n).restrictScalars 𝕜

end FormalMultilinearSeries

end

namespace FormalMultilinearSeries

variable [NontriviallyNormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E] [NormedAddCommGroup F] [NormedSpace 𝕜 F]
  [NormedAddCommGroup G] [NormedSpace 𝕜 G]

variable (p : FormalMultilinearSeries 𝕜 E F)

/-- Forgetting the zeroth term in a formal multilinear series, and interpreting the following terms
as multilinear maps into `E →L[𝕜] F`. If `p` corresponds to the Taylor series of a function, then
`p.shift` is the Taylor series of the derivative of the function. -/
def shift : FormalMultilinearSeries 𝕜 E (E →L[𝕜] F) := fun n => (p n.succ).curryRight

/-- Adding a zeroth term to a formal multilinear series taking values in `E →L[𝕜] F`. This
corresponds to starting from a Taylor series for the derivative of a function, and building a Taylor
series for the function itself. -/
def unshift (q : FormalMultilinearSeries 𝕜 E (E →L[𝕜] F)) (z : F) : FormalMultilinearSeries 𝕜 E F
  | 0 => (continuousMultilinearCurryFin0 𝕜 E F).symm z
  | n + 1 => continuousMultilinearCurryRightEquiv' 𝕜 n E F (q n)

end FormalMultilinearSeries

namespace ContinuousLinearMap

variable [CommRingₓ 𝕜] [AddCommGroupₓ E] [Module 𝕜 E] [TopologicalSpace E] [TopologicalAddGroup E]
  [HasContinuousConstSmul 𝕜 E] [AddCommGroupₓ F] [Module 𝕜 F] [TopologicalSpace F] [TopologicalAddGroup F]
  [HasContinuousConstSmul 𝕜 F] [AddCommGroupₓ G] [Module 𝕜 G] [TopologicalSpace G] [TopologicalAddGroup G]
  [HasContinuousConstSmul 𝕜 G]

/-- Composing each term `pₙ` in a formal multilinear series with a continuous linear map `f` on the
left gives a new formal multilinear series `f.comp_formal_multilinear_series p` whose general term
is `f ∘ pₙ`. -/
def compFormalMultilinearSeries (f : F →L[𝕜] G) (p : FormalMultilinearSeries 𝕜 E F) : FormalMultilinearSeries 𝕜 E G :=
  fun n => f.compContinuousMultilinearMap (p n)

@[simp]
theorem comp_formal_multilinear_series_apply (f : F →L[𝕜] G) (p : FormalMultilinearSeries 𝕜 E F) (n : ℕ) :
    (f.compFormalMultilinearSeries p) n = f.compContinuousMultilinearMap (p n) :=
  rfl

theorem comp_formal_multilinear_series_apply' (f : F →L[𝕜] G) (p : FormalMultilinearSeries 𝕜 E F) (n : ℕ)
    (v : Finₓ n → E) : (f.compFormalMultilinearSeries p) n v = f (p n v) :=
  rfl

end ContinuousLinearMap

namespace FormalMultilinearSeries

section Order

variable [CommRingₓ 𝕜] {n : ℕ} [AddCommGroupₓ E] [Module 𝕜 E] [TopologicalSpace E] [TopologicalAddGroup E]
  [HasContinuousConstSmul 𝕜 E] [AddCommGroupₓ F] [Module 𝕜 F] [TopologicalSpace F] [TopologicalAddGroup F]
  [HasContinuousConstSmul 𝕜 F] {p : FormalMultilinearSeries 𝕜 E F}

/-- The index of the first non-zero coefficient in `p` (or `0` if all coefficients are zero). This
  is the order of the isolated zero of an analytic function `f` at a point if `p` is the Taylor
  series of `f` at that point. -/
noncomputable def order (p : FormalMultilinearSeries 𝕜 E F) : ℕ :=
  inf { n | p n ≠ 0 }

@[simp]
theorem order_zero : (0 : FormalMultilinearSeries 𝕜 E F).order = 0 := by
  simp [order]

theorem ne_zero_of_order_ne_zero (hp : p.order ≠ 0) : p ≠ 0 := fun h => by
  simpa [h] using hp

theorem order_eq_find [DecidablePred fun n => p n ≠ 0] (hp : ∃ n, p n ≠ 0) : p.order = Nat.findₓ hp := by
  simp [order, Inf, hp]

theorem order_eq_find' [DecidablePred fun n => p n ≠ 0] (hp : p ≠ 0) :
    p.order = Nat.findₓ (FormalMultilinearSeries.ne_iff.mp hp) :=
  order_eq_find _

theorem order_eq_zero_iff (hp : p ≠ 0) : p.order = 0 ↔ p 0 ≠ 0 := by
  classical
  have : ∃ n, p n ≠ 0 := formal_multilinear_series.ne_iff.mp hp
  simp [order_eq_find this, hp]

theorem order_eq_zero_iff' : p.order = 0 ↔ p = 0 ∨ p 0 ≠ 0 := by
  by_cases' h : p = 0 <;> simp [h, order_eq_zero_iff]

theorem apply_order_ne_zero (hp : p ≠ 0) : p p.order ≠ 0 := by
  classical
  let h := formal_multilinear_series.ne_iff.mp hp
  exact (order_eq_find h).symm ▸ Nat.find_specₓ h

theorem apply_order_ne_zero' (hp : p.order ≠ 0) : p p.order ≠ 0 :=
  apply_order_ne_zero (ne_zero_of_order_ne_zero hp)

theorem apply_eq_zero_of_lt_order (hp : n < p.order) : p n = 0 := by
  by_cases' p = 0
  · simp [h]
    
  · classical
    rw [order_eq_find' h] at hp
    simpa using Nat.find_minₓ _ hp
    

end Order

section Coef

variable [NontriviallyNormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E] {s : E}
  {p : FormalMultilinearSeries 𝕜 𝕜 E} {f : 𝕜 → E} {n : ℕ} {z z₀ : 𝕜} {y : Finₓ n → 𝕜}

open BigOperators

/-- The `n`th coefficient of `p` when seen as a power series. -/
def coeff (p : FormalMultilinearSeries 𝕜 𝕜 E) (n : ℕ) : E :=
  p n 1

theorem mk_pi_field_coeff_eq (p : FormalMultilinearSeries 𝕜 𝕜 E) (n : ℕ) :
    ContinuousMultilinearMap.mkPiField 𝕜 (Finₓ n) (p.coeff n) = p n :=
  (p n).mk_pi_field_apply_one_eq_self

@[simp]
theorem apply_eq_prod_smul_coeff : p n y = (∏ i, y i) • p.coeff n := by
  convert (p n).toMultilinearMap.map_smul_univ y 1
  funext <;> simp only [Pi.one_apply, Algebra.id.smul_eq_mul, mul_oneₓ]

theorem coeff_eq_zero : p.coeff n = 0 ↔ p n = 0 := by
  rw [← mk_pi_field_coeff_eq p, ContinuousMultilinearMap.mk_pi_field_eq_zero_iff]

@[simp]
theorem apply_eq_pow_smul_coeff : (p n fun _ => z) = z ^ n • p.coeff n := by
  simp

@[simp]
theorem norm_apply_eq_norm_coef : ∥p n∥ = ∥coeff p n∥ := by
  rw [← mk_pi_field_coeff_eq p, ContinuousMultilinearMap.norm_mk_pi_field]

end Coef

section Fslope

variable [NontriviallyNormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E] {p : FormalMultilinearSeries 𝕜 𝕜 E}
  {n : ℕ}

/-- The formal counterpart of `dslope`, corresponding to the expansion of `(f z - f 0) / z`. If `f`
has `p` as a power series, then `dslope f` has `fslope p` as a power series. -/
noncomputable def fslope (p : FormalMultilinearSeries 𝕜 𝕜 E) : FormalMultilinearSeries 𝕜 𝕜 E := fun n =>
  (p (n + 1)).curryLeft 1

@[simp]
theorem coeff_fslope : p.fslope.coeff n = p.coeff (n + 1) := by
  have : @Finₓ.cons n (fun _ => 𝕜) 1 (1 : Finₓ n → 𝕜) = 1 := Finₓ.cons_self_tail 1
  simp only [fslope, coeff, ContinuousMultilinearMap.curry_left_apply, this]

@[simp]
theorem coeff_iterate_fslope (k n : ℕ) : ((fslope^[k]) p).coeff n = p.coeff (n + k) := by
  induction' k with k ih generalizing p <;>
    first |
      rfl|
      simpa [ih]

end Fslope

end FormalMultilinearSeries

