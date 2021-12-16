import Mathbin.Analysis.Calculus.IteratedDeriv 
import Mathbin.Analysis.InnerProductSpace.EuclideanDist

/-!
# Infinitely smooth bump function

In this file we construct several infinitely smooth functions with properties that an analytic
function cannot have:

* `exp_neg_inv_glue` is equal to zero for `x ≤ 0` and is strictly positive otherwise; it is given by
  `x ↦ exp (-1/x)` for `x > 0`;

* `real.smooth_transition` is equal to zero for `x ≤ 0` and is equal to one for `x ≥ 1`; it is given
  by `exp_neg_inv_glue x / (exp_neg_inv_glue x + exp_neg_inv_glue (1 - x))`;

* `f : times_cont_diff_bump_of_inner c`, where `c` is a point in an inner product space, is
  a bundled smooth function such that

  - `f` is equal to `1` in `metric.closed_ball c f.r`;
  - `support f = metric.ball c f.R`;
  - `0 ≤ f x ≤ 1` for all `x`.

  The structure `times_cont_diff_bump_of_inner` contains the data required to construct the
  function: real numbers `r`, `R`, and proofs of `0 < r < R`. The function itself is available
  through `coe_fn`.

* `f : times_cont_diff_bump c`, where `c` is a point in a finite dimensional real vector space, is a
  bundled smooth function such that

  - `f` is equal to `1` in `euclidean.closed_ball c f.r`;
  - `support f = euclidean.ball c f.R`;
  - `0 ≤ f x ≤ 1` for all `x`.

  The structure `times_cont_diff_bump` contains the data required to construct the function: real
  numbers `r`, `R`, and proofs of `0 < r < R`. The function itself is available through `coe_fn`.
-/


noncomputable section 

open_locale Classical TopologicalSpace

open Polynomial Real Filter Set Function

/-- `exp_neg_inv_glue` is the real function given by `x ↦ exp (-1/x)` for `x > 0` and `0`
for `x ≤ 0`. It is a basic building block to construct smooth partitions of unity. Its main property
is that it vanishes for `x ≤ 0`, it is positive for `x > 0`, and the junction between the two
behaviors is flat enough to retain smoothness. The fact that this function is `C^∞` is proved in
`exp_neg_inv_glue.smooth`. -/
def expNegInvGlue (x : ℝ) : ℝ :=
  if x ≤ 0 then 0 else exp (-x⁻¹)

namespace expNegInvGlue

/-- Our goal is to prove that `exp_neg_inv_glue` is `C^∞`. For this, we compute its successive
derivatives for `x > 0`. The `n`-th derivative is of the form `P_aux n (x) exp(-1/x) / x^(2 n)`,
where `P_aux n` is computed inductively. -/
noncomputable def P_aux : ℕ → Polynomial ℝ
| 0 => 1
| n+1 => ((X^2)*(P_aux n).derivative)+(1 - C (↑2*n)*X)*P_aux n

/-- Formula for the `n`-th derivative of `exp_neg_inv_glue`, as an auxiliary function `f_aux`. -/
def f_aux (n : ℕ) (x : ℝ) : ℝ :=
  if x ≤ 0 then 0 else ((P_aux n).eval x*exp (-x⁻¹)) / (x^2*n)

/-- The `0`-th auxiliary function `f_aux 0` coincides with `exp_neg_inv_glue`, by definition. -/
theorem f_aux_zero_eq : f_aux 0 = expNegInvGlue :=
  by 
    ext x 
    byCases' h : x ≤ 0
    ·
      simp [expNegInvGlue, f_aux, h]
    ·
      simp [h, expNegInvGlue, f_aux, ne_of_gtₓ (not_leₓ.1 h), P_aux]

/-- For positive values, the derivative of the `n`-th auxiliary function `f_aux n`
(given in this statement in unfolded form) is the `n+1`-th auxiliary function, since
the polynomial `P_aux (n+1)` was chosen precisely to ensure this. -/
theorem f_aux_deriv (n : ℕ) (x : ℝ) (hx : x ≠ 0) :
  HasDerivAt (fun x => ((P_aux n).eval x*exp (-x⁻¹)) / (x^2*n)) (((P_aux (n+1)).eval x*exp (-x⁻¹)) / (x^2*n+1)) x :=
  by 
    have A : ∀ k : ℕ, (2*k+1) - 1 = (2*k)+1
    ·
      intro k 
      rw [tsub_eq_iff_eq_add_of_le]
      ·
        ring
      ·
        simpa [mul_addₓ] using add_le_add (zero_le (2*k)) one_le_two 
    convert
      (((P_aux n).HasDerivAt x).mul ((has_deriv_at_exp _).comp x (has_deriv_at_inv hx).neg)).div
        (has_deriv_at_pow (2*n) x) (pow_ne_zero _ hx) using
      1
    fieldSimp [hx, P_aux]
    cases n <;> simp [Nat.succ_eq_add_one, A, -mul_eq_mul_right_iff] <;> ringExp

/-- For positive values, the derivative of the `n`-th auxiliary function `f_aux n`
is the `n+1`-th auxiliary function. -/
theorem f_aux_deriv_pos (n : ℕ) (x : ℝ) (hx : 0 < x) :
  HasDerivAt (f_aux n) (((P_aux (n+1)).eval x*exp (-x⁻¹)) / (x^2*n+1)) x :=
  by 
    apply (f_aux_deriv n x (ne_of_gtₓ hx)).congr_of_eventually_eq 
    filterUpwards [lt_mem_nhds hx]
    intro y hy 
    simp [f_aux, hy.not_le]

/-- To get differentiability at `0` of the auxiliary functions, we need to know that their limit
is `0`, to be able to apply general differentiability extension theorems. This limit is checked in
this lemma. -/
theorem f_aux_limit (n : ℕ) : tendsto (fun x => ((P_aux n).eval x*exp (-x⁻¹)) / (x^2*n)) (𝓝[Ioi 0] 0) (𝓝 0) :=
  by 
    have A : tendsto (fun x => (P_aux n).eval x) (𝓝[Ioi 0] 0) (𝓝 ((P_aux n).eval 0)) := (P_aux n).ContinuousWithinAt 
    have B : tendsto (fun x => exp (-x⁻¹) / (x^2*n)) (𝓝[Ioi 0] 0) (𝓝 0)
    ·
      convert (tendsto_pow_mul_exp_neg_at_top_nhds_0 (2*n)).comp tendsto_inv_zero_at_top 
      ext x 
      fieldSimp 
    convert A.mul B <;> simp [mul_div_assoc]

/-- Deduce from the limiting behavior at `0` of its derivative and general differentiability
extension theorems that the auxiliary function `f_aux n` is differentiable at `0`,
with derivative `0`. -/
theorem f_aux_deriv_zero (n : ℕ) : HasDerivAt (f_aux n) 0 0 :=
  by 
    have A : HasDerivWithinAt (f_aux n) (0 : ℝ) (Iic 0) 0
    ·
      apply (has_deriv_at_const (0 : ℝ) (0 : ℝ)).HasDerivWithinAt.congr
      ·
        intro y hy 
        simp  at hy 
        simp [f_aux, hy]
      ·
        simp [f_aux, le_reflₓ]
    have B : HasDerivWithinAt (f_aux n) (0 : ℝ) (Ici 0) 0
    ·
      have diff : DifferentiableOn ℝ (f_aux n) (Ioi 0) :=
        fun x hx => (f_aux_deriv_pos n x hx).DifferentiableAt.DifferentiableWithinAt 
      apply has_deriv_at_interval_left_endpoint_of_tendsto_deriv diff _ self_mem_nhds_within
      ·
        refine' (f_aux_limit (n+1)).congr' _ 
        apply mem_of_superset self_mem_nhds_within fun x hx => _ 
        simp [(f_aux_deriv_pos n x hx).deriv]
      ·
        have  : f_aux n 0 = 0
        ·
          simp [f_aux, le_reflₓ]
        simp only [ContinuousWithinAt, this]
        refine' (f_aux_limit n).congr' _ 
        apply mem_of_superset self_mem_nhds_within fun x hx => _ 
        have  : ¬x ≤ 0
        ·
          simpa using hx 
        simp [f_aux, this]
    simpa using A.union B

/-- At every point, the auxiliary function `f_aux n` has a derivative which is
equal to `f_aux (n+1)`. -/
theorem f_aux_has_deriv_at (n : ℕ) (x : ℝ) : HasDerivAt (f_aux n) (f_aux (n+1) x) x :=
  by 
    rcases lt_trichotomyₓ x 0 with (hx | hx | hx)
    ·
      have  : f_aux (n+1) x = 0
      ·
        simp [f_aux, le_of_ltₓ hx]
      rw [this]
      apply (has_deriv_at_const x (0 : ℝ)).congr_of_eventually_eq 
      filterUpwards [gt_mem_nhds hx]
      intro y hy 
      simp [f_aux, hy.le]
    ·
      have  : f_aux (n+1) 0 = 0
      ·
        simp [f_aux, le_reflₓ]
      rw [hx, this]
      exact f_aux_deriv_zero n
    ·
      have  : f_aux (n+1) x = ((P_aux (n+1)).eval x*exp (-x⁻¹)) / (x^2*n+1)
      ·
        simp [f_aux, not_le_of_gtₓ hx]
      rw [this]
      exact f_aux_deriv_pos n x hx

/-- The successive derivatives of the auxiliary function `f_aux 0` are the
functions `f_aux n`, by induction. -/
theorem f_aux_iterated_deriv (n : ℕ) : iteratedDeriv n (f_aux 0) = f_aux n :=
  by 
    induction' n with n IH
    ·
      simp 
    ·
      simp [iterated_deriv_succ, IH]
      ext x 
      exact (f_aux_has_deriv_at n x).deriv

/-- The function `exp_neg_inv_glue` is smooth. -/
protected theorem TimesContDiff {n} : TimesContDiff ℝ n expNegInvGlue :=
  by 
    rw [←f_aux_zero_eq]
    apply times_cont_diff_of_differentiable_iterated_deriv fun m hm => _ 
    rw [f_aux_iterated_deriv m]
    exact fun x => (f_aux_has_deriv_at m x).DifferentiableAt

/-- The function `exp_neg_inv_glue` vanishes on `(-∞, 0]`. -/
theorem zero_of_nonpos {x : ℝ} (hx : x ≤ 0) : expNegInvGlue x = 0 :=
  by 
    simp [expNegInvGlue, hx]

/-- The function `exp_neg_inv_glue` is positive on `(0, +∞)`. -/
theorem pos_of_pos {x : ℝ} (hx : 0 < x) : 0 < expNegInvGlue x :=
  by 
    simp [expNegInvGlue, not_leₓ.2 hx, exp_pos]

/-- The function exp_neg_inv_glue` is nonnegative. -/
theorem nonneg (x : ℝ) : 0 ≤ expNegInvGlue x :=
  by 
    cases le_or_gtₓ x 0
    ·
      exact ge_of_eq (zero_of_nonpos h)
    ·
      exact le_of_ltₓ (pos_of_pos h)

end expNegInvGlue

/-- An infinitely smooth function `f : ℝ → ℝ` such that `f x = 0` for `x ≤ 0`,
`f x = 1` for `1 ≤ x`, and `0 < f x < 1` for `0 < x < 1`. -/
def Real.smoothTransition (x : ℝ) : ℝ :=
  expNegInvGlue x / expNegInvGlue x+expNegInvGlue (1 - x)

namespace Real

namespace SmoothTransition

variable {x : ℝ}

open expNegInvGlue

theorem pos_denom x : 0 < expNegInvGlue x+expNegInvGlue (1 - x) :=
  ((@zero_lt_one ℝ _ _).lt_or_lt x).elim (fun hx => add_pos_of_pos_of_nonneg (pos_of_pos hx) (nonneg _))
    fun hx => add_pos_of_nonneg_of_pos (nonneg _) (pos_of_pos$ sub_pos.2 hx)

theorem one_of_one_le (h : 1 ≤ x) : smooth_transition x = 1 :=
  (div_eq_one_iff_eq$ (pos_denom x).ne').2$
    by 
      rw [zero_of_nonpos (sub_nonpos.2 h), add_zeroₓ]

theorem zero_of_nonpos (h : x ≤ 0) : smooth_transition x = 0 :=
  by 
    rw [smooth_transition, zero_of_nonpos h, zero_div]

theorem le_one (x : ℝ) : smooth_transition x ≤ 1 :=
  (div_le_one (pos_denom x)).2$ le_add_of_nonneg_right (nonneg _)

theorem nonneg (x : ℝ) : 0 ≤ smooth_transition x :=
  div_nonneg (expNegInvGlue.nonneg _) (pos_denom x).le

theorem lt_one_of_lt_one (h : x < 1) : smooth_transition x < 1 :=
  (div_lt_one$ pos_denom x).2$ lt_add_of_pos_right _$ pos_of_pos$ sub_pos.2 h

theorem pos_of_pos (h : 0 < x) : 0 < smooth_transition x :=
  div_pos (expNegInvGlue.pos_of_pos h) (pos_denom x)

protected theorem TimesContDiff {n} : TimesContDiff ℝ n smooth_transition :=
  expNegInvGlue.times_cont_diff.div
      (expNegInvGlue.times_cont_diff.add$
        expNegInvGlue.times_cont_diff.comp$ times_cont_diff_const.sub times_cont_diff_id)$
    fun x => (pos_denom x).ne'

protected theorem TimesContDiffAt {x n} : TimesContDiffAt ℝ n smooth_transition x :=
  smooth_transition.times_cont_diff.TimesContDiffAt

end SmoothTransition

end Real

variable {E : Type _}

/-- `f : times_cont_diff_bump_of_inner c`, where `c` is a point in an inner product space, is a
bundled smooth function such that

- `f` is equal to `1` in `metric.closed_ball c f.r`;
- `support f = metric.ball c f.R`;
- `0 ≤ f x ≤ 1` for all `x`.

The structure `times_cont_diff_bump_of_inner` contains the data required to construct the function:
real numbers `r`, `R`, and proofs of `0 < r < R`. The function itself is available through
`coe_fn`. -/
structure TimesContDiffBumpOfInner (c : E) where 
  (R r : ℝ)
  r_pos : 0 < r 
  r_lt_R : r < R

namespace TimesContDiffBumpOfInner

theorem R_pos {c : E} (f : TimesContDiffBumpOfInner c) : 0 < f.R :=
  f.r_pos.trans f.r_lt_R

instance (c : E) : Inhabited (TimesContDiffBumpOfInner c) :=
  ⟨⟨1, 2, zero_lt_one, one_lt_two⟩⟩

variable [InnerProductSpace ℝ E] {c : E} (f : TimesContDiffBumpOfInner c) {x : E}

/-- The function defined by `f : times_cont_diff_bump_of_inner c`. Use automatic coercion to
function instead. -/
def to_fun (f : TimesContDiffBumpOfInner c) : E → ℝ :=
  fun x => Real.smoothTransition ((f.R - dist x c) / (f.R - f.r))

instance : CoeFun (TimesContDiffBumpOfInner c) fun _ => E → ℝ :=
  ⟨to_fun⟩

open real(smoothTransition)

open Real.smoothTransition Metric

theorem one_of_mem_closed_ball (hx : x ∈ closed_ball c f.r) : f x = 1 :=
  one_of_one_le$ (one_le_div (sub_pos.2 f.r_lt_R)).2$ sub_le_sub_left hx _

theorem nonneg : 0 ≤ f x :=
  nonneg _

theorem le_one : f x ≤ 1 :=
  le_one _

theorem pos_of_mem_ball (hx : x ∈ ball c f.R) : 0 < f x :=
  pos_of_pos$ div_pos (sub_pos.2 hx) (sub_pos.2 f.r_lt_R)

theorem lt_one_of_lt_dist (h : f.r < dist x c) : f x < 1 :=
  lt_one_of_lt_one$ (div_lt_one (sub_pos.2 f.r_lt_R)).2$ sub_lt_sub_left h _

theorem zero_of_le_dist (hx : f.R ≤ dist x c) : f x = 0 :=
  zero_of_nonpos$ div_nonpos_of_nonpos_of_nonneg (sub_nonpos.2 hx) (sub_nonneg.2 f.r_lt_R.le)

theorem support_eq : support (f : E → ℝ) = Metric.Ball c f.R :=
  by 
    ext x 
    suffices  : f x ≠ 0 ↔ dist x c < f.R
    ·
      simpa [mem_support]
    cases' lt_or_leₓ (dist x c) f.R with hx hx
    ·
      simp [hx, (f.pos_of_mem_ball hx).ne']
    ·
      simp [hx.not_lt, f.zero_of_le_dist hx]

theorem eventually_eq_one_of_mem_ball (h : x ∈ ball c f.r) : f =ᶠ[𝓝 x] 1 :=
  ((is_open_lt (continuous_id.dist continuous_const) continuous_const).eventually_mem h).mono$
    fun z hz => f.one_of_mem_closed_ball (le_of_ltₓ hz)

theorem eventually_eq_one : f =ᶠ[𝓝 c] 1 :=
  f.eventually_eq_one_of_mem_ball (mem_ball_self f.r_pos)

protected theorem TimesContDiffAt {n} : TimesContDiffAt ℝ n f x :=
  by 
    rcases em (x = c) with (rfl | hx)
    ·
      refine' TimesContDiffAt.congr_of_eventually_eq _ f.eventually_eq_one 
      rw [Pi.one_def]
      exact times_cont_diff_at_const
    ·
      exact
        real.smooth_transition.times_cont_diff_at.comp x
          (TimesContDiffAt.div_const$
            times_cont_diff_at_const.sub$ times_cont_diff_at_id.dist times_cont_diff_at_const hx)

protected theorem TimesContDiff {n} : TimesContDiff ℝ n f :=
  times_cont_diff_iff_times_cont_diff_at.2$ fun y => f.times_cont_diff_at

protected theorem TimesContDiffWithinAt {s n} : TimesContDiffWithinAt ℝ n f s x :=
  f.times_cont_diff_at.times_cont_diff_within_at

end TimesContDiffBumpOfInner

/-- `f : times_cont_diff_bump c`, where `c` is a point in a finite dimensional real vector space, is
a bundled smooth function such that

  - `f` is equal to `1` in `euclidean.closed_ball c f.r`;
  - `support f = euclidean.ball c f.R`;
  - `0 ≤ f x ≤ 1` for all `x`.

The structure `times_cont_diff_bump` contains the data required to construct the function: real
numbers `r`, `R`, and proofs of `0 < r < R`. The function itself is available through `coe_fn`.-/
structure TimesContDiffBump [NormedGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] (c : E) extends
  TimesContDiffBumpOfInner (toEuclidean c)

namespace TimesContDiffBump

variable [NormedGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {c x : E} (f : TimesContDiffBump c)

/-- The function defined by `f : times_cont_diff_bump c`. Use automatic coercion to function
instead. -/
def to_fun (f : TimesContDiffBump c) : E → ℝ :=
  f.to_times_cont_diff_bump_of_inner ∘ toEuclidean

instance : CoeFun (TimesContDiffBump c) fun _ => E → ℝ :=
  ⟨to_fun⟩

instance (c : E) : Inhabited (TimesContDiffBump c) :=
  ⟨⟨default _⟩⟩

theorem R_pos : 0 < f.R :=
  f.to_times_cont_diff_bump_of_inner.R_pos

theorem coe_eq_comp : ⇑f = (f.to_times_cont_diff_bump_of_inner ∘ toEuclidean) :=
  rfl

theorem one_of_mem_closed_ball (hx : x ∈ Euclidean.ClosedBall c f.r) : f x = 1 :=
  f.to_times_cont_diff_bump_of_inner.one_of_mem_closed_ball hx

theorem nonneg : 0 ≤ f x :=
  f.to_times_cont_diff_bump_of_inner.nonneg

theorem le_one : f x ≤ 1 :=
  f.to_times_cont_diff_bump_of_inner.le_one

theorem pos_of_mem_ball (hx : x ∈ Euclidean.Ball c f.R) : 0 < f x :=
  f.to_times_cont_diff_bump_of_inner.pos_of_mem_ball hx

theorem lt_one_of_lt_dist (h : f.r < Euclidean.dist x c) : f x < 1 :=
  f.to_times_cont_diff_bump_of_inner.lt_one_of_lt_dist h

theorem zero_of_le_dist (hx : f.R ≤ Euclidean.dist x c) : f x = 0 :=
  f.to_times_cont_diff_bump_of_inner.zero_of_le_dist hx

theorem support_eq : support (f : E → ℝ) = Euclidean.Ball c f.R :=
  by 
    rw [Euclidean.ball_eq_preimage, ←f.to_times_cont_diff_bump_of_inner.support_eq, ←support_comp_eq_preimage,
      coe_eq_comp]

theorem closure_support_eq : Closure (support f) = Euclidean.ClosedBall c f.R :=
  by 
    rw [f.support_eq, Euclidean.closure_ball _ f.R_pos]

theorem compact_closure_support : IsCompact (Closure (support f)) :=
  by 
    rw [f.closure_support_eq]
    exact Euclidean.is_compact_closed_ball

theorem eventually_eq_one_of_mem_ball (h : x ∈ Euclidean.Ball c f.r) : f =ᶠ[𝓝 x] 1 :=
  toEuclidean.ContinuousAt (f.to_times_cont_diff_bump_of_inner.eventually_eq_one_of_mem_ball h)

theorem eventually_eq_one : f =ᶠ[𝓝 c] 1 :=
  f.eventually_eq_one_of_mem_ball$ Euclidean.mem_ball_self f.r_pos

protected theorem TimesContDiff {n} : TimesContDiff ℝ n f :=
  f.to_times_cont_diff_bump_of_inner.times_cont_diff.comp (toEuclidean : E ≃L[ℝ] _).TimesContDiff

protected theorem TimesContDiffAt {n} : TimesContDiffAt ℝ n f x :=
  f.times_cont_diff.times_cont_diff_at

protected theorem TimesContDiffWithinAt {s n} : TimesContDiffWithinAt ℝ n f s x :=
  f.times_cont_diff_at.times_cont_diff_within_at

theorem exists_closure_support_subset {s : Set E} (hs : s ∈ 𝓝 c) : ∃ f : TimesContDiffBump c, Closure (support f) ⊆ s :=
  let ⟨R, h0, hR⟩ := Euclidean.nhds_basis_closed_ball.mem_iff.1 hs
  ⟨⟨⟨R / 2, R, half_pos h0, half_lt_self h0⟩⟩,
    by 
      rwa [closure_support_eq]⟩

theorem exists_closure_subset {R : ℝ} (hR : 0 < R) {s : Set E} (hs : IsClosed s) (hsR : s ⊆ Euclidean.Ball c R) :
  ∃ f : TimesContDiffBump c, f.R = R ∧ s ⊆ Euclidean.Ball c f.r :=
  by 
    rcases Euclidean.exists_pos_lt_subset_ball hR hs hsR with ⟨r, hr, hsr⟩
    exact ⟨⟨⟨r, R, hr.1, hr.2⟩⟩, rfl, hsr⟩

end TimesContDiffBump

open FiniteDimensional Metric

/-- If `E` is a finite dimensional normed space over `ℝ`, then for any point `x : E` and its
neighborhood `s` there exists an infinitely smooth function with the following properties:

* `f y = 1` in a neighborhood of `x`;
* `f y = 0` outside of `s`;
*  moreover, `closure (support f) ⊆ s` and `closure (support f)` is a compact set;
* `f y ∈ [0, 1]` for all `y`.

This lemma is a simple wrapper around lemmas about bundled smooth bump functions, see
`times_cont_diff_bump`. -/
theorem exists_times_cont_diff_bump_function_of_mem_nhds [NormedGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  {x : E} {s : Set E} (hs : s ∈ 𝓝 x) :
  ∃ f : E → ℝ,
    f =ᶠ[𝓝 x] 1 ∧
      (∀ y, f y ∈ Icc (0 : ℝ) 1) ∧ TimesContDiff ℝ ⊤ f ∧ IsCompact (Closure$ support f) ∧ Closure (support f) ⊆ s :=
  let ⟨f, hf⟩ := TimesContDiffBump.exists_closure_support_subset hs
  ⟨f, f.eventually_eq_one, fun y => ⟨f.nonneg, f.le_one⟩, f.times_cont_diff, f.compact_closure_support, hf⟩

