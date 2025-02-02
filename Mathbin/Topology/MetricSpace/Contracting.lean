/-
Copyright (c) 2019 Rohan Mitta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rohan Mitta, Kevin Buzzard, Alistair Tucker, Johannes Hölzl, Yury Kudryashov
-/
import Mathbin.Analysis.SpecificLimits.Basic
import Mathbin.Data.Setoid.Basic
import Mathbin.Dynamics.FixedPoints.Topology

/-!
# Contracting maps

A Lipschitz continuous self-map with Lipschitz constant `K < 1` is called a *contracting map*.
In this file we prove the Banach fixed point theorem, some explicit estimates on the rate
of convergence, and some properties of the map sending a contracting map to its fixed point.

## Main definitions

* `contracting_with K f` : a Lipschitz continuous self-map with `K < 1`;
* `efixed_point` : given a contracting map `f` on a complete emetric space and a point `x`
  such that `edist x (f x) ≠ ∞`, `efixed_point f hf x hx` is the unique fixed point of `f`
  in `emetric.ball x ∞`;
* `fixed_point` : the unique fixed point of a contracting map on a complete nonempty metric space.

## Tags

contracting map, fixed point, Banach fixed point theorem
-/


open Nnreal TopologicalSpace Classical Ennreal

open Filter Function

variable {α : Type _}

/-- A map is said to be `contracting_with K`, if `K < 1` and `f` is `lipschitz_with K`. -/
def ContractingWith [EmetricSpace α] (K : ℝ≥0 ) (f : α → α) :=
  K < 1 ∧ LipschitzWith K f

namespace ContractingWith

variable [EmetricSpace α] [cs : CompleteSpace α] {K : ℝ≥0 } {f : α → α}

open Emetric Set

theorem to_lipschitz_with (hf : ContractingWith K f) : LipschitzWith K f :=
  hf.2

theorem one_sub_K_pos' (hf : ContractingWith K f) : (0 : ℝ≥0∞) < 1 - K := by
  simp [hf.1]

theorem one_sub_K_ne_zero (hf : ContractingWith K f) : (1 : ℝ≥0∞) - K ≠ 0 :=
  ne_of_gtₓ hf.one_sub_K_pos'

theorem one_sub_K_ne_top : (1 : ℝ≥0∞) - K ≠ ∞ := by
  norm_cast
  exact Ennreal.coe_ne_top

theorem edist_inequality (hf : ContractingWith K f) {x y} (h : edist x y ≠ ∞) :
    edist x y ≤ (edist x (f x) + edist y (f y)) / (1 - K) :=
  suffices edist x y ≤ edist x (f x) + edist y (f y) + K * edist x y by
    rwa [Ennreal.le_div_iff_mul_le (Or.inl hf.one_sub_K_ne_zero) (Or.inl one_sub_K_ne_top), mul_comm,
      Ennreal.sub_mul fun _ _ => h, one_mulₓ, tsub_le_iff_right]
  calc
    edist x y ≤ edist x (f x) + edist (f x) (f y) + edist (f y) y := edist_triangle4 _ _ _ _
    _ = edist x (f x) + edist y (f y) + edist (f x) (f y) := by
      rw [edist_comm y, add_right_commₓ]
    _ ≤ edist x (f x) + edist y (f y) + K * edist x y := add_le_add le_rflₓ (hf.2 _ _)
    

theorem edist_le_of_fixed_point (hf : ContractingWith K f) {x y} (h : edist x y ≠ ∞) (hy : IsFixedPt f y) :
    edist x y ≤ edist x (f x) / (1 - K) := by
  simpa only [hy.eq, edist_self, add_zeroₓ] using hf.edist_inequality h

theorem eq_or_edist_eq_top_of_fixed_points (hf : ContractingWith K f) {x y} (hx : IsFixedPt f x) (hy : IsFixedPt f y) :
    x = y ∨ edist x y = ∞ := by
  refine' or_iff_not_imp_right.2 fun h => edist_le_zero.1 _
  simpa only [hx.eq, edist_self, add_zeroₓ, Ennreal.zero_div] using hf.edist_le_of_fixed_point h hy

/-- If a map `f` is `contracting_with K`, and `s` is a forward-invariant set, then
restriction of `f` to `s` is `contracting_with K` as well. -/
theorem restrict (hf : ContractingWith K f) {s : Set α} (hs : MapsTo f s s) : ContractingWith K (hs.restrict f s s) :=
  ⟨hf.1, fun x y => hf.2 x y⟩

include cs

/-- Banach fixed-point theorem, contraction mapping theorem, `emetric_space` version.
A contracting map on a complete metric space has a fixed point.
We include more conclusions in this theorem to avoid proving them again later.

The main API for this theorem are the functions `efixed_point` and `fixed_point`,
and lemmas about these functions. -/
theorem exists_fixed_point (hf : ContractingWith K f) (x : α) (hx : edist x (f x) ≠ ∞) :
    ∃ y,
      IsFixedPt f y ∧
        Tendsto (fun n => (f^[n]) x) atTop (𝓝 y) ∧ ∀ n : ℕ, edist ((f^[n]) x) y ≤ edist x (f x) * K ^ n / (1 - K) :=
  have : CauchySeq fun n => (f^[n]) x :=
    cauchy_seq_of_edist_le_geometric K (edist x (f x)) (Ennreal.coe_lt_one_iff.2 hf.1) hx
      (hf.to_lipschitz_with.edist_iterate_succ_le_geometric x)
  let ⟨y, hy⟩ := cauchy_seq_tendsto_of_complete this
  ⟨y, is_fixed_pt_of_tendsto_iterate hy hf.2.Continuous.ContinuousAt, hy,
    edist_le_of_edist_le_geometric_of_tendsto K (edist x (f x)) (hf.to_lipschitz_with.edist_iterate_succ_le_geometric x)
      hy⟩

variable (f)

-- avoid `efixed_point _` in pretty printer
/-- Let `x` be a point of a complete emetric space. Suppose that `f` is a contracting map,
and `edist x (f x) ≠ ∞`. Then `efixed_point` is the unique fixed point of `f`
in `emetric.ball x ∞`. -/
noncomputable def efixedPoint (hf : ContractingWith K f) (x : α) (hx : edist x (f x) ≠ ∞) : α :=
  Classical.choose <| hf.exists_fixed_point x hx

variable {f}

theorem efixed_point_is_fixed_pt (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) :
    IsFixedPt f (efixedPoint f hf x hx) :=
  (Classical.choose_spec <| hf.exists_fixed_point x hx).1

theorem tendsto_iterate_efixed_point (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) :
    Tendsto (fun n => (f^[n]) x) atTop (𝓝 <| efixedPoint f hf x hx) :=
  (Classical.choose_spec <| hf.exists_fixed_point x hx).2.1

theorem apriori_edist_iterate_efixed_point_le (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) (n : ℕ) :
    edist ((f^[n]) x) (efixedPoint f hf x hx) ≤ edist x (f x) * K ^ n / (1 - K) :=
  (Classical.choose_spec <| hf.exists_fixed_point x hx).2.2 n

theorem edist_efixed_point_le (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) :
    edist x (efixedPoint f hf x hx) ≤ edist x (f x) / (1 - K) := by
  convert hf.apriori_edist_iterate_efixed_point_le hx 0
  simp only [pow_zeroₓ, mul_oneₓ]

theorem edist_efixed_point_lt_top (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) :
    edist x (efixedPoint f hf x hx) < ∞ :=
  (hf.edist_efixed_point_le hx).trans_lt (Ennreal.mul_lt_top hx <| Ennreal.inv_ne_top.2 hf.one_sub_K_ne_zero)

theorem efixed_point_eq_of_edist_lt_top (hf : ContractingWith K f) {x : α} (hx : edist x (f x) ≠ ∞) {y : α}
    (hy : edist y (f y) ≠ ∞) (h : edist x y ≠ ∞) : efixedPoint f hf x hx = efixedPoint f hf y hy := by
  refine' (hf.eq_or_edist_eq_top_of_fixed_points _ _).elim id fun h' => False.elim (ne_of_ltₓ _ h') <;>
    try
      apply efixed_point_is_fixed_pt
  change edist_lt_top_setoid.rel _ _
  trans x
  · symm
    exact hf.edist_efixed_point_lt_top hx
    
  trans y
  exacts[lt_top_iff_ne_top.2 h, hf.edist_efixed_point_lt_top hy]

omit cs

/-- Banach fixed-point theorem for maps contracting on a complete subset. -/
theorem exists_fixed_point' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    ∃ y ∈ s,
      IsFixedPt f y ∧
        Tendsto (fun n => (f^[n]) x) atTop (𝓝 y) ∧ ∀ n : ℕ, edist ((f^[n]) x) y ≤ edist x (f x) * K ^ n / (1 - K) :=
  by
  haveI := hsc.complete_space_coe
  rcases hf.exists_fixed_point ⟨x, hxs⟩ hx with ⟨y, hfy, h_tendsto, hle⟩
  refine' ⟨y, y.2, Subtype.ext_iff_val.1 hfy, _, fun n => _⟩
  · convert (continuous_subtype_coe.tendsto _).comp h_tendsto
    ext n
    simp only [(· ∘ ·), maps_to.iterate_restrict, maps_to.coe_restrict_apply, Subtype.coe_mk]
    
  · convert hle n
    rw [maps_to.iterate_restrict, eq_comm, maps_to.coe_restrict_apply, Subtype.coe_mk]
    

variable (f)

-- avoid `efixed_point _` in pretty printer
/-- Let `s` be a complete forward-invariant set of a self-map `f`. If `f` contracts on `s`
and `x ∈ s` satisfies `edist x (f x) ≠ ∞`, then `efixed_point'` is the unique fixed point
of the restriction of `f` to `s ∩ emetric.ball x ∞`. -/
noncomputable def efixedPoint' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) (x : α) (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) : α :=
  Classical.choose <| hf.exists_fixed_point' hsc hsf hxs hx

variable {f}

theorem efixed_point_mem' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    efixedPoint' f hsc hsf hf x hxs hx ∈ s :=
  (Classical.choose_spec <| hf.exists_fixed_point' hsc hsf hxs hx).fst

theorem efixed_point_is_fixed_pt' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    IsFixedPt f (efixedPoint' f hsc hsf hf x hxs hx) :=
  (Classical.choose_spec <| hf.exists_fixed_point' hsc hsf hxs hx).snd.1

theorem tendsto_iterate_efixed_point' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    Tendsto (fun n => (f^[n]) x) atTop (𝓝 <| efixedPoint' f hsc hsf hf x hxs hx) :=
  (Classical.choose_spec <| hf.exists_fixed_point' hsc hsf hxs hx).snd.2.1

theorem apriori_edist_iterate_efixed_point_le' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) (n : ℕ) :
    edist ((f^[n]) x) (efixedPoint' f hsc hsf hf x hxs hx) ≤ edist x (f x) * K ^ n / (1 - K) :=
  (Classical.choose_spec <| hf.exists_fixed_point' hsc hsf hxs hx).snd.2.2 n

theorem edist_efixed_point_le' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    edist x (efixedPoint' f hsc hsf hf x hxs hx) ≤ edist x (f x) / (1 - K) := by
  convert hf.apriori_edist_iterate_efixed_point_le' hsc hsf hxs hx 0
  rw [pow_zeroₓ, mul_oneₓ]

theorem edist_efixed_point_lt_top' {s : Set α} (hsc : IsComplete s) (hsf : MapsTo f s s)
    (hf : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞) :
    edist x (efixedPoint' f hsc hsf hf x hxs hx) < ∞ :=
  (hf.edist_efixed_point_le' hsc hsf hxs hx).trans_lt
    (Ennreal.mul_lt_top hx <| Ennreal.inv_ne_top.2 hf.one_sub_K_ne_zero)

/-- If a globally contracting map `f` has two complete forward-invariant sets `s`, `t`,
and `x ∈ s` is at a finite distance from `y ∈ t`, then the `efixed_point'` constructed by `x`
is the same as the `efixed_point'` constructed by `y`.

This lemma takes additional arguments stating that `f` contracts on `s` and `t` because this way
it can be used to prove the desired equality with non-trivial proofs of these facts. -/
theorem efixed_point_eq_of_edist_lt_top' (hf : ContractingWith K f) {s : Set α} (hsc : IsComplete s)
    (hsf : MapsTo f s s) (hfs : ContractingWith K <| hsf.restrict f s s) {x : α} (hxs : x ∈ s) (hx : edist x (f x) ≠ ∞)
    {t : Set α} (htc : IsComplete t) (htf : MapsTo f t t) (hft : ContractingWith K <| htf.restrict f t t) {y : α}
    (hyt : y ∈ t) (hy : edist y (f y) ≠ ∞) (hxy : edist x y ≠ ∞) :
    efixedPoint' f hsc hsf hfs x hxs hx = efixedPoint' f htc htf hft y hyt hy := by
  refine' (hf.eq_or_edist_eq_top_of_fixed_points _ _).elim id fun h' => False.elim (ne_of_ltₓ _ h') <;>
    try
      apply efixed_point_is_fixed_pt'
  change edist_lt_top_setoid.rel _ _
  trans x
  · symm
    apply edist_efixed_point_lt_top'
    
  trans y
  exact lt_top_iff_ne_top.2 hxy
  apply edist_efixed_point_lt_top'

end ContractingWith

namespace ContractingWith

variable [MetricSpace α] {K : ℝ≥0 } {f : α → α} (hf : ContractingWith K f)

include hf

theorem one_sub_K_pos (hf : ContractingWith K f) : (0 : ℝ) < 1 - K :=
  sub_pos.2 hf.1

theorem dist_le_mul (x y : α) : dist (f x) (f y) ≤ K * dist x y :=
  hf.to_lipschitz_with.dist_le_mul x y

theorem dist_inequality (x y) : dist x y ≤ (dist x (f x) + dist y (f y)) / (1 - K) :=
  suffices dist x y ≤ dist x (f x) + dist y (f y) + K * dist x y by
    rwa [le_div_iff hf.one_sub_K_pos, mul_comm, sub_mul, one_mulₓ, sub_le_iff_le_add]
  calc
    dist x y ≤ dist x (f x) + dist y (f y) + dist (f x) (f y) := dist_triangle4_right _ _ _ _
    _ ≤ dist x (f x) + dist y (f y) + K * dist x y := add_le_add_left (hf.dist_le_mul _ _) _
    

theorem dist_le_of_fixed_point (x) {y} (hy : IsFixedPt f y) : dist x y ≤ dist x (f x) / (1 - K) := by
  simpa only [hy.eq, dist_self, add_zeroₓ] using hf.dist_inequality x y

theorem fixed_point_unique' {x y} (hx : IsFixedPt f x) (hy : IsFixedPt f y) : x = y :=
  (hf.eq_or_edist_eq_top_of_fixed_points hx hy).resolve_right (edist_ne_top _ _)

/-- Let `f` be a contracting map with constant `K`; let `g` be another map uniformly
`C`-close to `f`. If `x` and `y` are their fixed points, then `dist x y ≤ C / (1 - K)`. -/
theorem dist_fixed_point_fixed_point_of_dist_le' (g : α → α) {x y} (hx : IsFixedPt f x) (hy : IsFixedPt g y) {C}
    (hfg : ∀ z, dist (f z) (g z) ≤ C) : dist x y ≤ C / (1 - K) :=
  calc
    dist x y = dist y x := dist_comm x y
    _ ≤ dist y (f y) / (1 - K) := hf.dist_le_of_fixed_point y hx
    _ = dist (f y) (g y) / (1 - K) := by
      rw [hy.eq, dist_comm]
    _ ≤ C / (1 - K) := (div_le_div_right hf.one_sub_K_pos).2 (hfg y)
    

noncomputable section

variable [Nonempty α] [CompleteSpace α]

variable (f)

/-- The unique fixed point of a contracting map in a nonempty complete metric space. -/
def fixedPoint : α :=
  efixedPoint f hf _ (edist_ne_top (Classical.choice ‹Nonempty α›) _)

variable {f}

/-- The point provided by `contracting_with.fixed_point` is actually a fixed point. -/
theorem fixed_point_is_fixed_pt : IsFixedPt f (fixedPoint f hf) :=
  hf.efixed_point_is_fixed_pt _

theorem fixed_point_unique {x} (hx : IsFixedPt f x) : x = fixedPoint f hf :=
  hf.fixed_point_unique' hx hf.fixed_point_is_fixed_pt

theorem dist_fixed_point_le (x) : dist x (fixedPoint f hf) ≤ dist x (f x) / (1 - K) :=
  hf.dist_le_of_fixed_point x hf.fixed_point_is_fixed_pt

/-- Aposteriori estimates on the convergence of iterates to the fixed point. -/
theorem aposteriori_dist_iterate_fixed_point_le (x n) :
    dist ((f^[n]) x) (fixedPoint f hf) ≤ dist ((f^[n]) x) ((f^[n + 1]) x) / (1 - K) := by
  rw [iterate_succ']
  apply hf.dist_fixed_point_le

theorem apriori_dist_iterate_fixed_point_le (x n) :
    dist ((f^[n]) x) (fixedPoint f hf) ≤ dist x (f x) * K ^ n / (1 - K) :=
  le_transₓ (hf.aposteriori_dist_iterate_fixed_point_le x n) <|
    (div_le_div_right hf.one_sub_K_pos).2 <| hf.to_lipschitz_with.dist_iterate_succ_le_geometric x n

theorem tendsto_iterate_fixed_point (x) : Tendsto (fun n => (f^[n]) x) atTop (𝓝 <| fixedPoint f hf) := by
  convert tendsto_iterate_efixed_point hf (edist_ne_top x _)
  refine' (fixed_point_unique _ _).symm
  apply efixed_point_is_fixed_pt

theorem fixed_point_lipschitz_in_map {g : α → α} (hg : ContractingWith K g) {C} (hfg : ∀ z, dist (f z) (g z) ≤ C) :
    dist (fixedPoint f hf) (fixedPoint g hg) ≤ C / (1 - K) :=
  hf.dist_fixed_point_fixed_point_of_dist_le' g hf.fixed_point_is_fixed_pt hg.fixed_point_is_fixed_pt hfg

omit hf

/-- If a map `f` has a contracting iterate `f^[n]`, then the fixed point of `f^[n]` is also a fixed
point of `f`. -/
theorem is_fixed_pt_fixed_point_iterate {n : ℕ} (hf : ContractingWith K (f^[n])) :
    IsFixedPt f (hf.fixedPoint (f^[n])) := by
  set x := hf.fixed_point (f^[n])
  have hx : (f^[n]) x = x := hf.fixed_point_is_fixed_pt
  have := hf.to_lipschitz_with.dist_le_mul x (f x)
  rw [← iterate_succ_apply, iterate_succ_apply', hx] at this
  contrapose! this
  have := dist_pos.2 (Ne.symm this)
  simpa only [Nnreal.coe_one, one_mulₓ, Nnreal.val_eq_coe] using (mul_lt_mul_right this).mpr hf.left

end ContractingWith

