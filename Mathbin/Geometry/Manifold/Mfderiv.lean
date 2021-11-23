import Mathbin.Geometry.Manifold.BasicSmoothBundle

/-!
# The derivative of functions between smooth manifolds

Let `M` and `M'` be two smooth manifolds with corners over a field `𝕜` (with respective models with
corners `I` on `(E, H)` and `I'` on `(E', H')`), and let `f : M → M'`. We define the
derivative of the function at a point, within a set or along the whole space, mimicking the API
for (Fréchet) derivatives. It is denoted by `mfderiv I I' f x`, where "m" stands for "manifold" and
"f" for "Fréchet" (as in the usual derivative `fderiv 𝕜 f x`).

## Main definitions

* `unique_mdiff_on I s` : predicate saying that, at each point of the set `s`, a function can have
  at most one derivative. This technical condition is important when we define
  `mfderiv_within` below, as otherwise there is an arbitrary choice in the derivative,
  and many properties will fail (for instance the chain rule). This is analogous to
  `unique_diff_on 𝕜 s` in a vector space.

Let `f` be a map between smooth manifolds. The following definitions follow the `fderiv` API.

* `mfderiv I I' f x` : the derivative of `f` at `x`, as a continuous linear map from the tangent
  space at `x` to the tangent space at `f x`. If the map is not differentiable, this is `0`.
* `mfderiv_within I I' f s x` : the derivative of `f` at `x` within `s`, as a continuous linear map
  from the tangent space at `x` to the tangent space at `f x`. If the map is not differentiable
  within `s`, this is `0`.
* `mdifferentiable_at I I' f x` : Prop expressing whether `f` is differentiable at `x`.
* `mdifferentiable_within_at 𝕜 f s x` : Prop expressing whether `f` is differentiable within `s`
  at `x`.
* `has_mfderiv_at I I' f s x f'` : Prop expressing whether `f` has `f'` as a derivative at `x`.
* `has_mfderiv_within_at I I' f s x f'` : Prop expressing whether `f` has `f'` as a derivative
  within `s` at `x`.
* `mdifferentiable_on I I' f s` : Prop expressing that `f` is differentiable on the set `s`.
* `mdifferentiable I I' f` : Prop expressing that `f` is differentiable everywhere.
* `tangent_map I I' f` : the derivative of `f`, as a map from the tangent bundle of `M` to the
  tangent bundle of `M'`.

We also establish results on the differential of the identity, constant functions, charts, extended
charts. For functions between vector spaces, we show that the usual notions and the manifold notions
coincide.

## Implementation notes

The tangent bundle is constructed using the machinery of topological fiber bundles, for which one
can define bundled morphisms and construct canonically maps from the total space of one bundle to
the total space of another one. One could use this mechanism to construct directly the derivative
of a smooth map. However, we want to define the derivative of any map (and let it be zero if the map
is not differentiable) to avoid proof arguments everywhere. This means we have to go back to the
details of the definition of the total space of a fiber bundle constructed from core, to cook up a
suitable definition of the derivative. It is the following: at each point, we have a preferred chart
(used to identify the fiber above the point with the model vector space in fiber bundles). Then one
should read the function using these preferred charts at `x` and `f x`, and take the derivative
of `f` in these charts.

Due to the fact that we are working in a model with corners, with an additional embedding `I` of the
model space `H` in the model vector space `E`, the charts taking values in `E` are not the original
charts of the manifold, but those ones composed with `I`, called extended charts. We define
`written_in_ext_chart I I' x f` for the function `f` written in the preferred extended charts.  Then
the manifold derivative of `f`, at `x`, is just the usual derivative of `written_in_ext_chart I I' x
f`, at the point `(ext_chart_at I x) x`.

There is a subtelty with respect to continuity: if the function is not continuous, then the image
of a small open set around `x` will not be contained in the source of the preferred chart around
`f x`, which means that when reading `f` in the chart one is losing some information. To avoid this,
we include continuity in the definition of differentiablity (which is reasonable since with any
definition, differentiability implies continuity).

*Warning*: the derivative (even within a subset) is a linear map on the whole tangent space. Suppose
that one is given a smooth submanifold `N`, and a function which is smooth on `N` (i.e., its
restriction to the subtype  `N` is smooth). Then, in the whole manifold `M`, the property
`mdifferentiable_on I I' f N` holds. However, `mfderiv_within I I' f N` is not uniquely defined
(what values would one choose for vectors that are transverse to `N`?), which can create issues down
the road. The problem here is that knowing the value of `f` along `N` does not determine the
differential of `f` in all directions. This is in contrast to the case where `N` would be an open
subset, or a submanifold with boundary of maximal dimension, where this issue does not appear.
The predicate `unique_mdiff_on I N` indicates that the derivative along `N` is unique if it exists,
and is an assumption in most statements requiring a form of uniqueness.

On a vector space, the manifold derivative and the usual derivative are equal. This means in
particular that they live on the same space, i.e., the tangent space is defeq to the original vector
space. To get this property is a motivation for our definition of the tangent space as a single
copy of the vector space, instead of more usual definitions such as the space of derivations, or
the space of equivalence classes of smooth curves in the manifold.

## Tags
Derivative, manifold
-/


noncomputable theory

open_locale Classical TopologicalSpace Manifold

open Set

universe u

section DerivativesDefinitions

/-!
### Derivative of maps between manifolds

The derivative of a smooth map `f` between smooth manifold `M` and `M'` at `x` is a bounded linear
map from the tangent space to `M` at `x`, to the tangent space to `M'` at `f x`. Since we defined
the tangent space using one specific chart, the formula for the derivative is written in terms of
this specific chart.

We use the names `mdifferentiable` and `mfderiv`, where the prefix letter `m` means "manifold".
-/


variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H](I :
    ModelWithCorners 𝕜 E
      H){M :
    Type
      _}[TopologicalSpace
      M][ChartedSpace H
      M]{E' :
    Type
      _}[NormedGroup
      E'][NormedSpace 𝕜
      E']{H' :
    Type _}[TopologicalSpace H'](I' : ModelWithCorners 𝕜 E' H'){M' : Type _}[TopologicalSpace M'][ChartedSpace H' M']

/-- Predicate ensuring that, at a point and within a set, a function can have at most one
derivative. This is expressed using the preferred chart at the considered point. -/
def UniqueMdiffWithinAt (s : Set M) (x : M) :=
  UniqueDiffWithinAt 𝕜 ((extChartAt I x).symm ⁻¹' s ∩ range I) ((extChartAt I x) x)

/-- Predicate ensuring that, at all points of a set, a function can have at most one derivative. -/
def UniqueMdiffOn (s : Set M) :=
  ∀ x _ : x ∈ s, UniqueMdiffWithinAt I s x

/-- Conjugating a function to write it in the preferred charts around `x`. The manifold derivative
of `f` will just be the derivative of this conjugated function. -/
@[simp, mfld_simps]
def writtenInExtChartAt (x : M) (f : M → M') : E → E' :=
  extChartAt I' (f x) ∘ f ∘ (extChartAt I x).symm

/-- `mdifferentiable_within_at I I' f s x` indicates that the function `f` between manifolds
has a derivative at the point `x` within the set `s`.
This is a generalization of `differentiable_within_at` to manifolds.

We require continuity in the definition, as otherwise points close to `x` in `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def MdifferentiableWithinAt (f : M → M') (s : Set M) (x : M) :=
  ContinuousWithinAt f s x ∧
    DifferentiableWithinAt 𝕜 (writtenInExtChartAt I I' x f) ((extChartAt I x).symm ⁻¹' s ∩ range I) ((extChartAt I x) x)

/-- `mdifferentiable_at I I' f x` indicates that the function `f` between manifolds
has a derivative at the point `x`.
This is a generalization of `differentiable_at` to manifolds.

We require continuity in the definition, as otherwise points close to `x` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def MdifferentiableAt (f : M → M') (x : M) :=
  ContinuousAt f x ∧ DifferentiableWithinAt 𝕜 (writtenInExtChartAt I I' x f) (range I) ((extChartAt I x) x)

/-- `mdifferentiable_on I I' f s` indicates that the function `f` between manifolds
has a derivative within `s` at all points of `s`.
This is a generalization of `differentiable_on` to manifolds. -/
def MdifferentiableOn (f : M → M') (s : Set M) :=
  ∀ x _ : x ∈ s, MdifferentiableWithinAt I I' f s x

/-- `mdifferentiable I I' f` indicates that the function `f` between manifolds
has a derivative everywhere.
This is a generalization of `differentiable` to manifolds. -/
def Mdifferentiable (f : M → M') :=
  ∀ x, MdifferentiableAt I I' f x

/-- Prop registering if a local homeomorphism is a local diffeomorphism on its source -/
def LocalHomeomorph.Mdifferentiable (f : LocalHomeomorph M M') :=
  MdifferentiableOn I I' f f.source ∧ MdifferentiableOn I' I f.symm f.target

variable[SmoothManifoldWithCorners I M][SmoothManifoldWithCorners I' M']

/-- `has_mfderiv_within_at I I' f s x f'` indicates that the function `f` between manifolds
has, at the point `x` and within the set `s`, the derivative `f'`. Here, `f'` is a continuous linear
map from the tangent space at `x` to the tangent space at `f x`.

This is a generalization of `has_fderiv_within_at` to manifolds (as indicated by the prefix `m`).
The order of arguments is changed as the type of the derivative `f'` depends on the choice of `x`.

We require continuity in the definition, as otherwise points close to `x` in `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def HasMfderivWithinAt (f : M → M') (s : Set M) (x : M) (f' : TangentSpace I x →L[𝕜] TangentSpace I' (f x)) :=
  ContinuousWithinAt f s x ∧
    HasFderivWithinAt (writtenInExtChartAt I I' x f : E → E') f' ((extChartAt I x).symm ⁻¹' s ∩ range I)
      ((extChartAt I x) x)

/-- `has_mfderiv_at I I' f x f'` indicates that the function `f` between manifolds
has, at the point `x`, the derivative `f'`. Here, `f'` is a continuous linear
map from the tangent space at `x` to the tangent space at `f x`.

We require continuity in the definition, as otherwise points close to `x` `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def HasMfderivAt (f : M → M') (x : M) (f' : TangentSpace I x →L[𝕜] TangentSpace I' (f x)) :=
  ContinuousAt f x ∧ HasFderivWithinAt (writtenInExtChartAt I I' x f : E → E') f' (range I) ((extChartAt I x) x)

/-- Let `f` be a function between two smooth manifolds. Then `mfderiv_within I I' f s x` is the
derivative of `f` at `x` within `s`, as a continuous linear map from the tangent space at `x` to the
tangent space at `f x`. -/
def mfderivWithin (f : M → M') (s : Set M) (x : M) : TangentSpace I x →L[𝕜] TangentSpace I' (f x) :=
  if h : MdifferentiableWithinAt I I' f s x then
    (fderivWithin 𝕜 (writtenInExtChartAt I I' x f) ((extChartAt I x).symm ⁻¹' s ∩ range I) ((extChartAt I x) x) : _)
  else 0

/-- Let `f` be a function between two smooth manifolds. Then `mfderiv I I' f x` is the derivative of
`f` at `x`, as a continuous linear map from the tangent space at `x` to the tangent space at
`f x`. -/
def mfderiv (f : M → M') (x : M) : TangentSpace I x →L[𝕜] TangentSpace I' (f x) :=
  if h : MdifferentiableAt I I' f x then
    (fderivWithin 𝕜 (writtenInExtChartAt I I' x f : E → E') (range I) ((extChartAt I x) x) : _) else 0

/-- The derivative within a set, as a map between the tangent bundles -/
def tangentMapWithin (f : M → M') (s : Set M) : TangentBundle I M → TangentBundle I' M' :=
  fun p => ⟨f p.1, (mfderivWithin I I' f s p.1 : TangentSpace I p.1 → TangentSpace I' (f p.1)) p.2⟩

/-- The derivative, as a map between the tangent bundles -/
def tangentMap (f : M → M') : TangentBundle I M → TangentBundle I' M' :=
  fun p => ⟨f p.1, (mfderiv I I' f p.1 : TangentSpace I p.1 → TangentSpace I' (f p.1)) p.2⟩

end DerivativesDefinitions

section DerivativesProperties

/-! ### Unique differentiability sets in manifolds -/


variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H](I :
    ModelWithCorners 𝕜 E
      H){M :
    Type
      _}[TopologicalSpace
      M][ChartedSpace H
      M]{E' :
    Type
      _}[NormedGroup
      E'][NormedSpace 𝕜
      E']{H' :
    Type
      _}[TopologicalSpace
      H']{I' :
    ModelWithCorners 𝕜 E'
      H'}{M' :
    Type
      _}[TopologicalSpace
      M'][ChartedSpace H'
      M']{E'' :
    Type
      _}[NormedGroup
      E''][NormedSpace 𝕜
      E'']{H'' :
    Type
      _}[TopologicalSpace
      H'']{I'' :
    ModelWithCorners 𝕜 E''
      H''}{M'' :
    Type _}[TopologicalSpace M''][ChartedSpace H'' M'']{f f₀ f₁ : M → M'}{x : M}{s t : Set M}{g : M' → M''}{u : Set M'}

theorem unique_mdiff_within_at_univ : UniqueMdiffWithinAt I univ x :=
  by 
    unfold UniqueMdiffWithinAt 
    simp only [preimage_univ, univ_inter]
    exact I.unique_diff _ (mem_range_self _)

variable{I}

theorem unique_mdiff_within_at_iff {s : Set M} {x : M} :
  UniqueMdiffWithinAt I s x ↔
    UniqueDiffWithinAt 𝕜 ((extChartAt I x).symm ⁻¹' s ∩ (extChartAt I x).Target) ((extChartAt I x) x) :=
  by 
    apply unique_diff_within_at_congr 
    rw [nhds_within_inter, nhds_within_inter, nhds_within_ext_chart_target_eq]

theorem UniqueMdiffWithinAt.mono (h : UniqueMdiffWithinAt I s x) (st : s ⊆ t) : UniqueMdiffWithinAt I t x :=
  UniqueDiffWithinAt.mono h$ inter_subset_inter (preimage_mono st) (subset.refl _)

theorem UniqueMdiffWithinAt.inter' (hs : UniqueMdiffWithinAt I s x) (ht : t ∈ 𝓝[s] x) :
  UniqueMdiffWithinAt I (s ∩ t) x :=
  by 
    rw [UniqueMdiffWithinAt, ext_chart_preimage_inter_eq]
    exact UniqueDiffWithinAt.inter' hs (ext_chart_preimage_mem_nhds_within I x ht)

theorem UniqueMdiffWithinAt.inter (hs : UniqueMdiffWithinAt I s x) (ht : t ∈ 𝓝 x) : UniqueMdiffWithinAt I (s ∩ t) x :=
  by 
    rw [UniqueMdiffWithinAt, ext_chart_preimage_inter_eq]
    exact UniqueDiffWithinAt.inter hs (ext_chart_preimage_mem_nhds I x ht)

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem is_open.unique_mdiff_within_at (xs : «expr ∈ »(x, s)) (hs : is_open s) : unique_mdiff_within_at I s x :=
begin
  have [] [] [":=", expr unique_mdiff_within_at.inter (unique_mdiff_within_at_univ I) (is_open.mem_nhds hs xs)],
  rwa [expr univ_inter] ["at", ident this]
end

theorem UniqueMdiffOn.inter (hs : UniqueMdiffOn I s) (ht : IsOpen t) : UniqueMdiffOn I (s ∩ t) :=
  fun x hx => UniqueMdiffWithinAt.inter (hs _ hx.1) (IsOpen.mem_nhds ht hx.2)

theorem IsOpen.unique_mdiff_on (hs : IsOpen s) : UniqueMdiffOn I s :=
  fun x hx => IsOpen.unique_mdiff_within_at hx hs

theorem unique_mdiff_on_univ : UniqueMdiffOn I (univ : Set M) :=
  is_open_univ.UniqueMdiffOn

variable[Is :
    SmoothManifoldWithCorners I
      M][I's :
    SmoothManifoldWithCorners I'
      M'][I''s :
    SmoothManifoldWithCorners I''
      M'']{f' f₀' f₁' :
    TangentSpace I x →L[𝕜] TangentSpace I' (f x)}{g' : TangentSpace I' (f x) →L[𝕜] TangentSpace I'' (g (f x))}

/-- `unique_mdiff_within_at` achieves its goal: it implies the uniqueness of the derivative. -/
theorem UniqueMdiffWithinAt.eq (U : UniqueMdiffWithinAt I s x) (h : HasMfderivWithinAt I I' f s x f')
  (h₁ : HasMfderivWithinAt I I' f s x f₁') : f' = f₁' :=
  U.eq h.2 h₁.2

theorem UniqueMdiffOn.eq (U : UniqueMdiffOn I s) (hx : x ∈ s) (h : HasMfderivWithinAt I I' f s x f')
  (h₁ : HasMfderivWithinAt I I' f s x f₁') : f' = f₁' :=
  UniqueMdiffWithinAt.eq (U _ hx) h h₁

/-!
### General lemmas on derivatives of functions between manifolds

We mimick the API for functions between vector spaces
-/


theorem mdifferentiable_within_at_iff {f : M → M'} {s : Set M} {x : M} :
  MdifferentiableWithinAt I I' f s x ↔
    ContinuousWithinAt f s x ∧
      DifferentiableWithinAt 𝕜 (writtenInExtChartAt I I' x f) ((extChartAt I x).Target ∩ (extChartAt I x).symm ⁻¹' s)
        ((extChartAt I x) x) :=
  by 
    refine' and_congr Iff.rfl (exists_congr$ fun f' => _)
    rw [inter_comm]
    simp only [HasFderivWithinAt, nhds_within_inter, nhds_within_ext_chart_target_eq]

include Is I's

theorem mfderiv_within_zero_of_not_mdifferentiable_within_at (h : ¬MdifferentiableWithinAt I I' f s x) :
  mfderivWithin I I' f s x = 0 :=
  by 
    simp only [mfderivWithin, h, dif_neg, not_false_iff]

theorem mfderiv_zero_of_not_mdifferentiable_at (h : ¬MdifferentiableAt I I' f x) : mfderiv I I' f x = 0 :=
  by 
    simp only [mfderiv, h, dif_neg, not_false_iff]

theorem HasMfderivWithinAt.mono (h : HasMfderivWithinAt I I' f t x f') (hst : s ⊆ t) :
  HasMfderivWithinAt I I' f s x f' :=
  ⟨ContinuousWithinAt.mono h.1 hst, HasFderivWithinAt.mono h.2 (inter_subset_inter (preimage_mono hst) (subset.refl _))⟩

theorem HasMfderivAt.has_mfderiv_within_at (h : HasMfderivAt I I' f x f') : HasMfderivWithinAt I I' f s x f' :=
  ⟨ContinuousAt.continuous_within_at h.1, HasFderivWithinAt.mono h.2 (inter_subset_right _ _)⟩

theorem HasMfderivWithinAt.mdifferentiable_within_at (h : HasMfderivWithinAt I I' f s x f') :
  MdifferentiableWithinAt I I' f s x :=
  ⟨h.1, ⟨f', h.2⟩⟩

theorem HasMfderivAt.mdifferentiable_at (h : HasMfderivAt I I' f x f') : MdifferentiableAt I I' f x :=
  ⟨h.1, ⟨f', h.2⟩⟩

@[simp, mfld_simps]
theorem has_mfderiv_within_at_univ : HasMfderivWithinAt I I' f univ x f' ↔ HasMfderivAt I I' f x f' :=
  by 
    simp' only [HasMfderivWithinAt, HasMfderivAt, continuous_within_at_univ] with mfld_simps

theorem has_mfderiv_at_unique (h₀ : HasMfderivAt I I' f x f₀') (h₁ : HasMfderivAt I I' f x f₁') : f₀' = f₁' :=
  by 
    rw [←has_mfderiv_within_at_univ] at h₀ h₁ 
    exact (unique_mdiff_within_at_univ I).Eq h₀ h₁

theorem has_mfderiv_within_at_inter' (h : t ∈ 𝓝[s] x) :
  HasMfderivWithinAt I I' f (s ∩ t) x f' ↔ HasMfderivWithinAt I I' f s x f' :=
  by 
    rw [HasMfderivWithinAt, HasMfderivWithinAt, ext_chart_preimage_inter_eq, has_fderiv_within_at_inter',
      continuous_within_at_inter' h]
    exact ext_chart_preimage_mem_nhds_within I x h

theorem has_mfderiv_within_at_inter (h : t ∈ 𝓝 x) :
  HasMfderivWithinAt I I' f (s ∩ t) x f' ↔ HasMfderivWithinAt I I' f s x f' :=
  by 
    rw [HasMfderivWithinAt, HasMfderivWithinAt, ext_chart_preimage_inter_eq, has_fderiv_within_at_inter,
      continuous_within_at_inter h]
    exact ext_chart_preimage_mem_nhds I x h

theorem HasMfderivWithinAt.union (hs : HasMfderivWithinAt I I' f s x f') (ht : HasMfderivWithinAt I I' f t x f') :
  HasMfderivWithinAt I I' f (s ∪ t) x f' :=
  by 
    split 
    ·
      exact ContinuousWithinAt.union hs.1 ht.1
    ·
      convert HasFderivWithinAt.union hs.2 ht.2
      simp only [union_inter_distrib_right, preimage_union]

theorem HasMfderivWithinAt.nhds_within (h : HasMfderivWithinAt I I' f s x f') (ht : s ∈ 𝓝[t] x) :
  HasMfderivWithinAt I I' f t x f' :=
  (has_mfderiv_within_at_inter' ht).1 (h.mono (inter_subset_right _ _))

theorem HasMfderivWithinAt.has_mfderiv_at (h : HasMfderivWithinAt I I' f s x f') (hs : s ∈ 𝓝 x) :
  HasMfderivAt I I' f x f' :=
  by 
    rwa [←univ_inter s, has_mfderiv_within_at_inter hs, has_mfderiv_within_at_univ] at h

theorem MdifferentiableWithinAt.has_mfderiv_within_at (h : MdifferentiableWithinAt I I' f s x) :
  HasMfderivWithinAt I I' f s x (mfderivWithin I I' f s x) :=
  by 
    refine' ⟨h.1, _⟩
    simp' only [mfderivWithin, h, dif_pos] with mfld_simps 
    exact DifferentiableWithinAt.has_fderiv_within_at h.2

theorem MdifferentiableWithinAt.mfderiv_within (h : MdifferentiableWithinAt I I' f s x) :
  mfderivWithin I I' f s x =
    fderivWithin 𝕜 (writtenInExtChartAt I I' x f : _) ((extChartAt I x).symm ⁻¹' s ∩ range I) ((extChartAt I x) x) :=
  by 
    simp only [mfderivWithin, h, dif_pos]

theorem MdifferentiableAt.has_mfderiv_at (h : MdifferentiableAt I I' f x) : HasMfderivAt I I' f x (mfderiv I I' f x) :=
  by 
    refine' ⟨h.1, _⟩
    simp' only [mfderiv, h, dif_pos] with mfld_simps 
    exact DifferentiableWithinAt.has_fderiv_within_at h.2

theorem MdifferentiableAt.mfderiv (h : MdifferentiableAt I I' f x) :
  mfderiv I I' f x = fderivWithin 𝕜 (writtenInExtChartAt I I' x f : _) (range I) ((extChartAt I x) x) :=
  by 
    simp only [mfderiv, h, dif_pos]

theorem HasMfderivAt.mfderiv (h : HasMfderivAt I I' f x f') : mfderiv I I' f x = f' :=
  (has_mfderiv_at_unique h h.mdifferentiable_at.has_mfderiv_at).symm

theorem HasMfderivWithinAt.mfderiv_within (h : HasMfderivWithinAt I I' f s x f') (hxs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I' f s x = f' :=
  by 
    ext 
    rw [hxs.eq h h.mdifferentiable_within_at.has_mfderiv_within_at]

theorem Mdifferentiable.mfderiv_within (h : MdifferentiableAt I I' f x) (hxs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I' f s x = mfderiv I I' f x :=
  by 
    apply HasMfderivWithinAt.mfderiv_within _ hxs 
    exact h.has_mfderiv_at.has_mfderiv_within_at

theorem mfderiv_within_subset (st : s ⊆ t) (hs : UniqueMdiffWithinAt I s x) (h : MdifferentiableWithinAt I I' f t x) :
  mfderivWithin I I' f s x = mfderivWithin I I' f t x :=
  ((MdifferentiableWithinAt.has_mfderiv_within_at h).mono st).mfderivWithin hs

omit Is I's

theorem MdifferentiableWithinAt.mono (hst : s ⊆ t) (h : MdifferentiableWithinAt I I' f t x) :
  MdifferentiableWithinAt I I' f s x :=
  ⟨ContinuousWithinAt.mono h.1 hst,
    DifferentiableWithinAt.mono h.2 (inter_subset_inter (preimage_mono hst) (subset.refl _))⟩

theorem mdifferentiable_within_at_univ : MdifferentiableWithinAt I I' f univ x ↔ MdifferentiableAt I I' f x :=
  by 
    simp' only [MdifferentiableWithinAt, MdifferentiableAt, continuous_within_at_univ] with mfld_simps

theorem mdifferentiable_within_at_inter (ht : t ∈ 𝓝 x) :
  MdifferentiableWithinAt I I' f (s ∩ t) x ↔ MdifferentiableWithinAt I I' f s x :=
  by 
    rw [MdifferentiableWithinAt, MdifferentiableWithinAt, ext_chart_preimage_inter_eq, differentiable_within_at_inter,
      continuous_within_at_inter ht]
    exact ext_chart_preimage_mem_nhds I x ht

theorem mdifferentiable_within_at_inter' (ht : t ∈ 𝓝[s] x) :
  MdifferentiableWithinAt I I' f (s ∩ t) x ↔ MdifferentiableWithinAt I I' f s x :=
  by 
    rw [MdifferentiableWithinAt, MdifferentiableWithinAt, ext_chart_preimage_inter_eq, differentiable_within_at_inter',
      continuous_within_at_inter' ht]
    exact ext_chart_preimage_mem_nhds_within I x ht

theorem MdifferentiableAt.mdifferentiable_within_at (h : MdifferentiableAt I I' f x) :
  MdifferentiableWithinAt I I' f s x :=
  MdifferentiableWithinAt.mono (subset_univ _) (mdifferentiable_within_at_univ.2 h)

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem mdifferentiable_within_at.mdifferentiable_at
(h : mdifferentiable_within_at I I' f s x)
(hs : «expr ∈ »(s, expr𝓝() x)) : mdifferentiable_at I I' f x :=
begin
  have [] [":", expr «expr = »(s, «expr ∩ »(univ, s))] [],
  by rw [expr univ_inter] [],
  rwa ["[", expr this, ",", expr mdifferentiable_within_at_inter hs, ",", expr mdifferentiable_within_at_univ, "]"] ["at", ident h]
end

theorem MdifferentiableOn.mono (h : MdifferentiableOn I I' f t) (st : s ⊆ t) : MdifferentiableOn I I' f s :=
  fun x hx => (h x (st hx)).mono st

theorem mdifferentiable_on_univ : MdifferentiableOn I I' f univ ↔ Mdifferentiable I I' f :=
  by 
    simp' only [MdifferentiableOn, mdifferentiable_within_at_univ] with mfld_simps 
    rfl

theorem Mdifferentiable.mdifferentiable_on (h : Mdifferentiable I I' f) : MdifferentiableOn I I' f s :=
  (mdifferentiable_on_univ.2 h).mono (subset_univ _)

theorem mdifferentiable_on_of_locally_mdifferentiable_on
  (h : ∀ x _ : x ∈ s, ∃ u, IsOpen u ∧ x ∈ u ∧ MdifferentiableOn I I' f (s ∩ u)) : MdifferentiableOn I I' f s :=
  by 
    intro x xs 
    rcases h x xs with ⟨t, t_open, xt, ht⟩
    exact (mdifferentiable_within_at_inter (IsOpen.mem_nhds t_open xt)).1 (ht x ⟨xs, xt⟩)

include Is I's

@[simp, mfld_simps]
theorem mfderiv_within_univ : mfderivWithin I I' f univ = mfderiv I I' f :=
  by 
    ext x : 1
    simp' only [mfderivWithin, mfderiv] with mfld_simps 
    rw [mdifferentiable_within_at_univ]

theorem mfderiv_within_inter (ht : t ∈ 𝓝 x) (hs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I' f (s ∩ t) x = mfderivWithin I I' f s x :=
  by 
    rw [mfderivWithin, mfderivWithin, ext_chart_preimage_inter_eq, mdifferentiable_within_at_inter ht,
      fderiv_within_inter (ext_chart_preimage_mem_nhds I x ht) hs]

omit Is I's

/-! ### Deriving continuity from differentiability on manifolds -/


theorem HasMfderivWithinAt.continuous_within_at (h : HasMfderivWithinAt I I' f s x f') : ContinuousWithinAt f s x :=
  h.1

theorem HasMfderivAt.continuous_at (h : HasMfderivAt I I' f x f') : ContinuousAt f x :=
  h.1

theorem MdifferentiableWithinAt.continuous_within_at (h : MdifferentiableWithinAt I I' f s x) :
  ContinuousWithinAt f s x :=
  h.1

theorem MdifferentiableAt.continuous_at (h : MdifferentiableAt I I' f x) : ContinuousAt f x :=
  h.1

theorem MdifferentiableOn.continuous_on (h : MdifferentiableOn I I' f s) : ContinuousOn f s :=
  fun x hx => (h x hx).ContinuousWithinAt

theorem Mdifferentiable.continuous (h : Mdifferentiable I I' f) : Continuous f :=
  continuous_iff_continuous_at.2$ fun x => (h x).ContinuousAt

include Is I's

theorem tangent_map_within_subset {p : TangentBundle I M} (st : s ⊆ t) (hs : UniqueMdiffWithinAt I s p.1)
  (h : MdifferentiableWithinAt I I' f t p.1) : tangentMapWithin I I' f s p = tangentMapWithin I I' f t p :=
  by 
    simp' only [tangentMapWithin] with mfld_simps 
    rw [mfderiv_within_subset st hs h]

theorem tangent_map_within_univ : tangentMapWithin I I' f univ = tangentMap I I' f :=
  by 
    ext p : 1
    simp' only [tangentMapWithin, tangentMap] with mfld_simps

theorem tangent_map_within_eq_tangent_map {p : TangentBundle I M} (hs : UniqueMdiffWithinAt I s p.1)
  (h : MdifferentiableAt I I' f p.1) : tangentMapWithin I I' f s p = tangentMap I I' f p :=
  by 
    rw [←mdifferentiable_within_at_univ] at h 
    rw [←tangent_map_within_univ]
    exact tangent_map_within_subset (subset_univ _) hs h

@[simp, mfld_simps]
theorem tangent_map_within_tangent_bundle_proj {p : TangentBundle I M} :
  TangentBundle.proj I' M' (tangentMapWithin I I' f s p) = f (TangentBundle.proj I M p) :=
  rfl

@[simp, mfld_simps]
theorem tangent_map_within_proj {p : TangentBundle I M} : (tangentMapWithin I I' f s p).1 = f p.1 :=
  rfl

@[simp, mfld_simps]
theorem tangent_map_tangent_bundle_proj {p : TangentBundle I M} :
  TangentBundle.proj I' M' (tangentMap I I' f p) = f (TangentBundle.proj I M p) :=
  rfl

@[simp, mfld_simps]
theorem tangent_map_proj {p : TangentBundle I M} : (tangentMap I I' f p).1 = f p.1 :=
  rfl

omit Is I's

/-! ### Congruence lemmas for derivatives on manifolds -/


-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem has_mfderiv_within_at.congr_of_eventually_eq
(h : has_mfderiv_within_at I I' f s x f')
(h₁ : «expr =ᶠ[ ] »(f₁, «expr𝓝[ ] »(s, x), f))
(hx : «expr = »(f₁ x, f x)) : has_mfderiv_within_at I I' f₁ s x f' :=
begin
  refine [expr ⟨continuous_within_at.congr_of_eventually_eq h.1 h₁ hx, _⟩],
  apply [expr has_fderiv_within_at.congr_of_eventually_eq h.2],
  { have [] [":", expr «expr ∈ »(«expr ⁻¹' »((ext_chart_at I x).symm, {y | «expr = »(f₁ y, f y)}), «expr𝓝[ ] »(«expr ∩ »(«expr ⁻¹' »((ext_chart_at I x).symm, s), range I), ext_chart_at I x x))] [":=", expr ext_chart_preimage_mem_nhds_within I x h₁],
    apply [expr filter.mem_of_superset this (λ y, _)],
    simp [] [] ["only"] ["[", expr hx, "]"] ["with", ident mfld_simps] [] { contextual := tt } },
  { simp [] [] ["only"] ["[", expr hx, "]"] ["with", ident mfld_simps] [] }
end

theorem HasMfderivWithinAt.congr_mono (h : HasMfderivWithinAt I I' f s x f') (ht : ∀ x _ : x ∈ t, f₁ x = f x)
  (hx : f₁ x = f x) (h₁ : t ⊆ s) : HasMfderivWithinAt I I' f₁ t x f' :=
  (h.mono h₁).congr_of_eventually_eq (Filter.mem_inf_of_right ht) hx

theorem HasMfderivAt.congr_of_eventually_eq (h : HasMfderivAt I I' f x f') (h₁ : f₁ =ᶠ[𝓝 x] f) :
  HasMfderivAt I I' f₁ x f' :=
  by 
    rw [←has_mfderiv_within_at_univ] at h⊢
    apply h.congr_of_eventually_eq _ (mem_of_mem_nhds h₁ : _)
    rwa [nhds_within_univ]

include Is I's

theorem MdifferentiableWithinAt.congr_of_eventually_eq (h : MdifferentiableWithinAt I I' f s x) (h₁ : f₁ =ᶠ[𝓝[s] x] f)
  (hx : f₁ x = f x) : MdifferentiableWithinAt I I' f₁ s x :=
  (h.has_mfderiv_within_at.congr_of_eventually_eq h₁ hx).MdifferentiableWithinAt

variable(I I')

theorem Filter.EventuallyEq.mdifferentiable_within_at_iff (h₁ : f₁ =ᶠ[𝓝[s] x] f) (hx : f₁ x = f x) :
  MdifferentiableWithinAt I I' f s x ↔ MdifferentiableWithinAt I I' f₁ s x :=
  by 
    split 
    ·
      intro h 
      apply h.congr_of_eventually_eq h₁ hx
    ·
      intro h 
      apply h.congr_of_eventually_eq _ hx.symm 
      apply h₁.mono 
      intro y 
      apply Eq.symm

variable{I I'}

theorem MdifferentiableWithinAt.congr_mono (h : MdifferentiableWithinAt I I' f s x) (ht : ∀ x _ : x ∈ t, f₁ x = f x)
  (hx : f₁ x = f x) (h₁ : t ⊆ s) : MdifferentiableWithinAt I I' f₁ t x :=
  (HasMfderivWithinAt.congr_mono h.has_mfderiv_within_at ht hx h₁).MdifferentiableWithinAt

theorem MdifferentiableWithinAt.congr (h : MdifferentiableWithinAt I I' f s x) (ht : ∀ x _ : x ∈ s, f₁ x = f x)
  (hx : f₁ x = f x) : MdifferentiableWithinAt I I' f₁ s x :=
  (HasMfderivWithinAt.congr_mono h.has_mfderiv_within_at ht hx (subset.refl _)).MdifferentiableWithinAt

theorem MdifferentiableOn.congr_mono (h : MdifferentiableOn I I' f s) (h' : ∀ x _ : x ∈ t, f₁ x = f x) (h₁ : t ⊆ s) :
  MdifferentiableOn I I' f₁ t :=
  fun x hx => (h x (h₁ hx)).congr_mono h' (h' x hx) h₁

theorem MdifferentiableAt.congr_of_eventually_eq (h : MdifferentiableAt I I' f x) (hL : f₁ =ᶠ[𝓝 x] f) :
  MdifferentiableAt I I' f₁ x :=
  (h.has_mfderiv_at.congr_of_eventually_eq hL).MdifferentiableAt

theorem MdifferentiableWithinAt.mfderiv_within_congr_mono (h : MdifferentiableWithinAt I I' f s x)
  (hs : ∀ x _ : x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (hxt : UniqueMdiffWithinAt I t x) (h₁ : t ⊆ s) :
  mfderivWithin I I' f₁ t x = (mfderivWithin I I' f s x : _) :=
  (HasMfderivWithinAt.congr_mono h.has_mfderiv_within_at hs hx h₁).mfderivWithin hxt

theorem Filter.EventuallyEq.mfderiv_within_eq (hs : UniqueMdiffWithinAt I s x) (hL : f₁ =ᶠ[𝓝[s] x] f)
  (hx : f₁ x = f x) : mfderivWithin I I' f₁ s x = (mfderivWithin I I' f s x : _) :=
  by 
    byCases' h : MdifferentiableWithinAt I I' f s x
    ·
      exact (h.has_mfderiv_within_at.congr_of_eventually_eq hL hx).mfderivWithin hs
    ·
      unfold mfderivWithin 
      rw [dif_neg h, dif_neg]
      rwa [←hL.mdifferentiable_within_at_iff I I' hx]

theorem mfderiv_within_congr (hs : UniqueMdiffWithinAt I s x) (hL : ∀ x _ : x ∈ s, f₁ x = f x) (hx : f₁ x = f x) :
  mfderivWithin I I' f₁ s x = (mfderivWithin I I' f s x : _) :=
  Filter.EventuallyEq.mfderiv_within_eq hs (Filter.eventually_eq_of_mem self_mem_nhds_within hL) hx

theorem tangent_map_within_congr (h : ∀ x _ : x ∈ s, f x = f₁ x) (p : TangentBundle I M) (hp : p.1 ∈ s)
  (hs : UniqueMdiffWithinAt I s p.1) : tangentMapWithin I I' f s p = tangentMapWithin I I' f₁ s p :=
  by 
    simp only [tangentMapWithin, h p.fst hp, true_andₓ, eq_self_iff_true, heq_iff_eq, Sigma.mk.inj_iff]
    congr 1 
    exact mfderiv_within_congr hs h (h _ hp)

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem filter.eventually_eq.mfderiv_eq
(hL : «expr =ᶠ[ ] »(f₁, expr𝓝() x, f)) : «expr = »(mfderiv I I' f₁ x, (mfderiv I I' f x : _)) :=
begin
  have [ident A] [":", expr «expr = »(f₁ x, f x)] [":=", expr (mem_of_mem_nhds hL : _)],
  rw ["[", "<-", expr mfderiv_within_univ, ",", "<-", expr mfderiv_within_univ, "]"] [],
  rw ["<-", expr nhds_within_univ] ["at", ident hL],
  exact [expr hL.mfderiv_within_eq (unique_mdiff_within_at_univ I) A]
end

/-! ### Composition lemmas -/


omit Is I's

theorem written_in_ext_chart_comp (h : ContinuousWithinAt f s x) :
  { y |
      writtenInExtChartAt I I'' x (g ∘ f) y = (writtenInExtChartAt I' I'' (f x) g ∘ writtenInExtChartAt I I' x f) y } ∈
    𝓝[(extChartAt I x).symm ⁻¹' s ∩ range I] (extChartAt I x) x :=
  by 
    apply
      @Filter.mem_of_superset _ _ ((f ∘ (extChartAt I x).symm) ⁻¹' (extChartAt I' (f x)).Source) _
        (ext_chart_preimage_mem_nhds_within I x (h.preimage_mem_nhds_within (ext_chart_at_source_mem_nhds _ _)))
    mfldSetTac

variable(x)

include Is I's I''s

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem has_mfderiv_within_at.comp
(hg : has_mfderiv_within_at I' I'' g u (f x) g')
(hf : has_mfderiv_within_at I I' f s x f')
(hst : «expr ⊆ »(s, «expr ⁻¹' »(f, u))) : has_mfderiv_within_at I I'' «expr ∘ »(g, f) s x (g'.comp f') :=
begin
  refine [expr ⟨continuous_within_at.comp hg.1 hf.1 hst, _⟩],
  have [ident A] [":", expr has_fderiv_within_at «expr ∘ »(written_in_ext_chart_at I' I'' (f x) g, written_in_ext_chart_at I I' x f) (continuous_linear_map.comp g' f' : «expr →L[ ] »(E, 𝕜, E'')) «expr ∩ »(«expr ⁻¹' »((ext_chart_at I x).symm, s), range I) (ext_chart_at I x x)] [],
  { have [] [":", expr «expr ∈ »(«expr ⁻¹' »((ext_chart_at I x).symm, «expr ⁻¹' »(f, (ext_chart_at I' (f x)).source)), «expr𝓝[ ] »(«expr ∩ »(«expr ⁻¹' »((ext_chart_at I x).symm, s), range I), ext_chart_at I x x))] [":=", expr ext_chart_preimage_mem_nhds_within I x (hf.1.preimage_mem_nhds_within (ext_chart_at_source_mem_nhds _ _))],
    unfold [ident has_mfderiv_within_at] ["at", "*"],
    rw ["[", "<-", expr has_fderiv_within_at_inter' this, ",", "<-", expr ext_chart_preimage_inter_eq, "]"] ["at", ident hf, "⊢"],
    have [] [":", expr «expr = »(written_in_ext_chart_at I I' x f (ext_chart_at I x x), ext_chart_at I' (f x) (f x))] [],
    by simp [] [] ["only"] [] ["with", ident mfld_simps] [],
    rw ["<-", expr this] ["at", ident hg],
    apply [expr has_fderiv_within_at.comp (ext_chart_at I x x) hg.2 hf.2 _],
    assume [binders (y hy)],
    simp [] [] ["only"] [] ["with", ident mfld_simps] ["at", ident hy],
    have [] [":", expr «expr ∈ »(f (((chart_at H x).symm : H → M) (I.symm y)), u)] [":=", expr hst hy.1.1],
    simp [] [] ["only"] ["[", expr hy, ",", expr this, "]"] ["with", ident mfld_simps] [] },
  apply [expr A.congr_of_eventually_eq (written_in_ext_chart_comp hf.1)],
  simp [] [] ["only"] [] ["with", ident mfld_simps] []
end

/-- The chain rule. -/
theorem HasMfderivAt.comp (hg : HasMfderivAt I' I'' g (f x) g') (hf : HasMfderivAt I I' f x f') :
  HasMfderivAt I I'' (g ∘ f) x (g'.comp f') :=
  by 
    rw [←has_mfderiv_within_at_univ] at *
    exact HasMfderivWithinAt.comp x (hg.mono (subset_univ _)) hf subset_preimage_univ

theorem HasMfderivAt.comp_has_mfderiv_within_at (hg : HasMfderivAt I' I'' g (f x) g')
  (hf : HasMfderivWithinAt I I' f s x f') : HasMfderivWithinAt I I'' (g ∘ f) s x (g'.comp f') :=
  by 
    rw [←has_mfderiv_within_at_univ] at *
    exact HasMfderivWithinAt.comp x (hg.mono (subset_univ _)) hf subset_preimage_univ

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem mdifferentiable_within_at.comp
(hg : mdifferentiable_within_at I' I'' g u (f x))
(hf : mdifferentiable_within_at I I' f s x)
(h : «expr ⊆ »(s, «expr ⁻¹' »(f, u))) : mdifferentiable_within_at I I'' «expr ∘ »(g, f) s x :=
begin
  rcases [expr hf.2, "with", "⟨", ident f', ",", ident hf', "⟩"],
  have [ident F] [":", expr has_mfderiv_within_at I I' f s x f'] [":=", expr ⟨hf.1, hf'⟩],
  rcases [expr hg.2, "with", "⟨", ident g', ",", ident hg', "⟩"],
  have [ident G] [":", expr has_mfderiv_within_at I' I'' g u (f x) g'] [":=", expr ⟨hg.1, hg'⟩],
  exact [expr (has_mfderiv_within_at.comp x G F h).mdifferentiable_within_at]
end

theorem MdifferentiableAt.comp (hg : MdifferentiableAt I' I'' g (f x)) (hf : MdifferentiableAt I I' f x) :
  MdifferentiableAt I I'' (g ∘ f) x :=
  (hg.has_mfderiv_at.comp x hf.has_mfderiv_at).MdifferentiableAt

theorem mfderiv_within_comp (hg : MdifferentiableWithinAt I' I'' g u (f x)) (hf : MdifferentiableWithinAt I I' f s x)
  (h : s ⊆ f ⁻¹' u) (hxs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I'' (g ∘ f) s x = (mfderivWithin I' I'' g u (f x)).comp (mfderivWithin I I' f s x) :=
  by 
    apply HasMfderivWithinAt.mfderiv_within _ hxs 
    exact HasMfderivWithinAt.comp x hg.has_mfderiv_within_at hf.has_mfderiv_within_at h

theorem mfderiv_comp (hg : MdifferentiableAt I' I'' g (f x)) (hf : MdifferentiableAt I I' f x) :
  mfderiv I I'' (g ∘ f) x = (mfderiv I' I'' g (f x)).comp (mfderiv I I' f x) :=
  by 
    apply HasMfderivAt.mfderiv 
    exact HasMfderivAt.comp x hg.has_mfderiv_at hf.has_mfderiv_at

theorem MdifferentiableOn.comp (hg : MdifferentiableOn I' I'' g u) (hf : MdifferentiableOn I I' f s)
  (st : s ⊆ f ⁻¹' u) : MdifferentiableOn I I'' (g ∘ f) s :=
  fun x hx => MdifferentiableWithinAt.comp x (hg (f x) (st hx)) (hf x hx) st

theorem Mdifferentiable.comp (hg : Mdifferentiable I' I'' g) (hf : Mdifferentiable I I' f) :
  Mdifferentiable I I'' (g ∘ f) :=
  fun x => MdifferentiableAt.comp x (hg (f x)) (hf x)

theorem tangent_map_within_comp_at (p : TangentBundle I M) (hg : MdifferentiableWithinAt I' I'' g u (f p.1))
  (hf : MdifferentiableWithinAt I I' f s p.1) (h : s ⊆ f ⁻¹' u) (hps : UniqueMdiffWithinAt I s p.1) :
  tangentMapWithin I I'' (g ∘ f) s p = tangentMapWithin I' I'' g u (tangentMapWithin I I' f s p) :=
  by 
    simp' only [tangentMapWithin] with mfld_simps 
    rw [mfderiv_within_comp p.1 hg hf h hps]
    rfl

theorem tangent_map_comp_at (p : TangentBundle I M) (hg : MdifferentiableAt I' I'' g (f p.1))
  (hf : MdifferentiableAt I I' f p.1) : tangentMap I I'' (g ∘ f) p = tangentMap I' I'' g (tangentMap I I' f p) :=
  by 
    simp' only [tangentMap] with mfld_simps 
    rw [mfderiv_comp p.1 hg hf]
    rfl

theorem tangent_map_comp (hg : Mdifferentiable I' I'' g) (hf : Mdifferentiable I I' f) :
  tangentMap I I'' (g ∘ f) = (tangentMap I' I'' g ∘ tangentMap I I' f) :=
  by 
    ext p : 1 
    exact tangent_map_comp_at _ (hg _) (hf _)

end DerivativesProperties

section MfderivFderiv

/-!
### Relations between vector space derivative and manifold derivative

The manifold derivative `mfderiv`, when considered on the model vector space with its trivial
manifold structure, coincides with the usual Frechet derivative `fderiv`. In this section, we prove
this and related statements.
-/


variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type _}[NormedGroup E][NormedSpace 𝕜 E]{E' : Type _}[NormedGroup E'][NormedSpace 𝕜 E']{f : E → E'}{s : Set E}{x : E}

theorem unique_mdiff_within_at_iff_unique_diff_within_at : UniqueMdiffWithinAt 𝓘(𝕜, E) s x ↔ UniqueDiffWithinAt 𝕜 s x :=
  by 
    simp' only [UniqueMdiffWithinAt] with mfld_simps

alias unique_mdiff_within_at_iff_unique_diff_within_at ↔ UniqueMdiffWithinAt.unique_diff_within_at
  UniqueDiffWithinAt.unique_mdiff_within_at

theorem unique_mdiff_on_iff_unique_diff_on : UniqueMdiffOn 𝓘(𝕜, E) s ↔ UniqueDiffOn 𝕜 s :=
  by 
    simp [UniqueMdiffOn, UniqueDiffOn, unique_mdiff_within_at_iff_unique_diff_within_at]

alias unique_mdiff_on_iff_unique_diff_on ↔ UniqueMdiffOn.unique_diff_on UniqueDiffOn.unique_mdiff_on

@[simp, mfld_simps]
theorem written_in_ext_chart_model_space : writtenInExtChartAt 𝓘(𝕜, E) 𝓘(𝕜, E') x f = f :=
  rfl

theorem has_mfderiv_within_at_iff_has_fderiv_within_at {f'} :
  HasMfderivWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x f' ↔ HasFderivWithinAt f f' s x :=
  by 
    simpa only [HasMfderivWithinAt, and_iff_right_iff_imp] with mfld_simps using HasFderivWithinAt.continuous_within_at

alias has_mfderiv_within_at_iff_has_fderiv_within_at ↔ HasMfderivWithinAt.has_fderiv_within_at
  HasFderivWithinAt.has_mfderiv_within_at

theorem has_mfderiv_at_iff_has_fderiv_at {f'} : HasMfderivAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x f' ↔ HasFderivAt f f' x :=
  by 
    rw [←has_mfderiv_within_at_univ, has_mfderiv_within_at_iff_has_fderiv_within_at, has_fderiv_within_at_univ]

alias has_mfderiv_at_iff_has_fderiv_at ↔ HasMfderivAt.has_fderiv_at HasFderivAt.has_mfderiv_at

/-- For maps between vector spaces, `mdifferentiable_within_at` and `fdifferentiable_within_at`
coincide -/
theorem mdifferentiable_within_at_iff_differentiable_within_at :
  MdifferentiableWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x ↔ DifferentiableWithinAt 𝕜 f s x :=
  by 
    simp' only [MdifferentiableWithinAt] with mfld_simps 
    exact ⟨fun H => H.2, fun H => ⟨H.continuous_within_at, H⟩⟩

alias mdifferentiable_within_at_iff_differentiable_within_at ↔ MdifferentiableWithinAt.differentiable_within_at
  DifferentiableWithinAt.mdifferentiable_within_at

/-- For maps between vector spaces, `mdifferentiable_at` and `differentiable_at` coincide -/
theorem mdifferentiable_at_iff_differentiable_at : MdifferentiableAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x ↔ DifferentiableAt 𝕜 f x :=
  by 
    simp' only [MdifferentiableAt, differentiable_within_at_univ] with mfld_simps 
    exact ⟨fun H => H.2, fun H => ⟨H.continuous_at, H⟩⟩

alias mdifferentiable_at_iff_differentiable_at ↔ MdifferentiableAt.differentiable_at DifferentiableAt.mdifferentiable_at

/-- For maps between vector spaces, `mdifferentiable_on` and `differentiable_on` coincide -/
theorem mdifferentiable_on_iff_differentiable_on : MdifferentiableOn 𝓘(𝕜, E) 𝓘(𝕜, E') f s ↔ DifferentiableOn 𝕜 f s :=
  by 
    simp only [MdifferentiableOn, DifferentiableOn, mdifferentiable_within_at_iff_differentiable_within_at]

alias mdifferentiable_on_iff_differentiable_on ↔ MdifferentiableOn.differentiable_on DifferentiableOn.mdifferentiable_on

/-- For maps between vector spaces, `mdifferentiable` and `differentiable` coincide -/
theorem mdifferentiable_iff_differentiable : Mdifferentiable 𝓘(𝕜, E) 𝓘(𝕜, E') f ↔ Differentiable 𝕜 f :=
  by 
    simp only [Mdifferentiable, Differentiable, mdifferentiable_at_iff_differentiable_at]

alias mdifferentiable_iff_differentiable ↔ Mdifferentiable.differentiable Differentiable.mdifferentiable

/-- For maps between vector spaces, `mfderiv_within` and `fderiv_within` coincide -/
@[simp]
theorem mfderiv_within_eq_fderiv_within : mfderivWithin 𝓘(𝕜, E) 𝓘(𝕜, E') f s x = fderivWithin 𝕜 f s x :=
  by 
    byCases' h : MdifferentiableWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x
    ·
      simp' only [mfderivWithin, h, dif_pos] with mfld_simps
    ·
      simp only [mfderivWithin, h, dif_neg, not_false_iff]
      rw [mdifferentiable_within_at_iff_differentiable_within_at] at h 
      exact (fderiv_within_zero_of_not_differentiable_within_at h).symm

/-- For maps between vector spaces, `mfderiv` and `fderiv` coincide -/
@[simp]
theorem mfderiv_eq_fderiv : mfderiv 𝓘(𝕜, E) 𝓘(𝕜, E') f x = fderiv 𝕜 f x :=
  by 
    rw [←mfderiv_within_univ, ←fderiv_within_univ]
    exact mfderiv_within_eq_fderiv_within

end MfderivFderiv

section SpecificFunctions

/-! ### Differentiability of specific functions -/


variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H](I :
    ModelWithCorners 𝕜 E
      H){M :
    Type
      _}[TopologicalSpace
      M][ChartedSpace H
      M][SmoothManifoldWithCorners I
      M]{E' :
    Type
      _}[NormedGroup
      E'][NormedSpace 𝕜
      E']{H' :
    Type
      _}[TopologicalSpace
      H'](I' :
    ModelWithCorners 𝕜 E' H'){M' : Type _}[TopologicalSpace M'][ChartedSpace H' M'][SmoothManifoldWithCorners I' M']

namespace ContinuousLinearMap

variable(f : E →L[𝕜] E'){s : Set E}{x : E}

protected theorem HasMfderivWithinAt : HasMfderivWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x f :=
  f.has_fderiv_within_at.has_mfderiv_within_at

protected theorem HasMfderivAt : HasMfderivAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x f :=
  f.has_fderiv_at.has_mfderiv_at

protected theorem MdifferentiableWithinAt : MdifferentiableWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x :=
  f.differentiable_within_at.mdifferentiable_within_at

protected theorem MdifferentiableOn : MdifferentiableOn 𝓘(𝕜, E) 𝓘(𝕜, E') f s :=
  f.differentiable_on.mdifferentiable_on

protected theorem MdifferentiableAt : MdifferentiableAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x :=
  f.differentiable_at.mdifferentiable_at

protected theorem Mdifferentiable : Mdifferentiable 𝓘(𝕜, E) 𝓘(𝕜, E') f :=
  f.differentiable.mdifferentiable

theorem mfderiv_eq : mfderiv 𝓘(𝕜, E) 𝓘(𝕜, E') f x = f :=
  f.has_mfderiv_at.mfderiv

theorem mfderiv_within_eq (hs : UniqueMdiffWithinAt 𝓘(𝕜, E) s x) : mfderivWithin 𝓘(𝕜, E) 𝓘(𝕜, E') f s x = f :=
  f.has_mfderiv_within_at.mfderiv_within hs

end ContinuousLinearMap

namespace ContinuousLinearEquiv

variable(f : E ≃L[𝕜] E'){s : Set E}{x : E}

protected theorem HasMfderivWithinAt : HasMfderivWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x (f : E →L[𝕜] E') :=
  f.has_fderiv_within_at.has_mfderiv_within_at

protected theorem HasMfderivAt : HasMfderivAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x (f : E →L[𝕜] E') :=
  f.has_fderiv_at.has_mfderiv_at

protected theorem MdifferentiableWithinAt : MdifferentiableWithinAt 𝓘(𝕜, E) 𝓘(𝕜, E') f s x :=
  f.differentiable_within_at.mdifferentiable_within_at

protected theorem MdifferentiableOn : MdifferentiableOn 𝓘(𝕜, E) 𝓘(𝕜, E') f s :=
  f.differentiable_on.mdifferentiable_on

protected theorem MdifferentiableAt : MdifferentiableAt 𝓘(𝕜, E) 𝓘(𝕜, E') f x :=
  f.differentiable_at.mdifferentiable_at

protected theorem Mdifferentiable : Mdifferentiable 𝓘(𝕜, E) 𝓘(𝕜, E') f :=
  f.differentiable.mdifferentiable

theorem mfderiv_eq : mfderiv 𝓘(𝕜, E) 𝓘(𝕜, E') f x = (f : E →L[𝕜] E') :=
  f.has_mfderiv_at.mfderiv

theorem mfderiv_within_eq (hs : UniqueMdiffWithinAt 𝓘(𝕜, E) s x) :
  mfderivWithin 𝓘(𝕜, E) 𝓘(𝕜, E') f s x = (f : E →L[𝕜] E') :=
  f.has_mfderiv_within_at.mfderiv_within hs

end ContinuousLinearEquiv

variable{s : Set M}{x : M}

section id

/-! #### Identity -/


-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem has_mfderiv_at_id
(x : M) : has_mfderiv_at I I (@_root_.id M) x (continuous_linear_map.id 𝕜 (tangent_space I x)) :=
begin
  refine [expr ⟨continuous_id.continuous_at, _⟩],
  have [] [":", expr «expr∀ᶠ in , »((y), «expr𝓝[ ] »(range I, ext_chart_at I x x), «expr = »(«expr ∘ »(ext_chart_at I x, (ext_chart_at I x).symm) y, id y))] [],
  { apply [expr filter.mem_of_superset (ext_chart_at_target_mem_nhds_within I x)],
    mfld_set_tac },
  apply [expr has_fderiv_within_at.congr_of_eventually_eq (has_fderiv_within_at_id _ _) this],
  simp [] [] ["only"] [] ["with", ident mfld_simps] []
end

theorem has_mfderiv_within_at_id (s : Set M) (x : M) :
  HasMfderivWithinAt I I (@_root_.id M) s x (ContinuousLinearMap.id 𝕜 (TangentSpace I x)) :=
  (has_mfderiv_at_id I x).HasMfderivWithinAt

theorem mdifferentiable_at_id : MdifferentiableAt I I (@_root_.id M) x :=
  (has_mfderiv_at_id I x).MdifferentiableAt

theorem mdifferentiable_within_at_id : MdifferentiableWithinAt I I (@_root_.id M) s x :=
  (mdifferentiable_at_id I).MdifferentiableWithinAt

theorem mdifferentiable_id : Mdifferentiable I I (@_root_.id M) :=
  fun x => mdifferentiable_at_id I

theorem mdifferentiable_on_id : MdifferentiableOn I I (@_root_.id M) s :=
  (mdifferentiable_id I).MdifferentiableOn

@[simp, mfld_simps]
theorem mfderiv_id : mfderiv I I (@_root_.id M) x = ContinuousLinearMap.id 𝕜 (TangentSpace I x) :=
  HasMfderivAt.mfderiv (has_mfderiv_at_id I x)

theorem mfderiv_within_id (hxs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I (@_root_.id M) s x = ContinuousLinearMap.id 𝕜 (TangentSpace I x) :=
  by 
    rw [Mdifferentiable.mfderiv_within (mdifferentiable_at_id I) hxs]
    exact mfderiv_id I

@[simp, mfld_simps]
theorem tangent_map_id : tangentMap I I (id : M → M) = id :=
  by 
    ext1 ⟨x, v⟩
    simp [tangentMap]

theorem tangent_map_within_id {p : TangentBundle I M} (hs : UniqueMdiffWithinAt I s (TangentBundle.proj I M p)) :
  tangentMapWithin I I (id : M → M) s p = p :=
  by 
    simp only [tangentMapWithin, id.def]
    rw [mfderiv_within_id]
    ·
      rcases p with ⟨⟩
      rfl
    ·
      exact hs

end id

section Const

/-! #### Constants -/


variable{c : M'}

theorem has_mfderiv_at_const (c : M') (x : M) :
  HasMfderivAt I I' (fun y : M => c) x (0 : TangentSpace I x →L[𝕜] TangentSpace I' c) :=
  by 
    refine' ⟨continuous_const.continuous_at, _⟩
    simp only [writtenInExtChartAt, · ∘ ·, has_fderiv_within_at_const]

theorem has_mfderiv_within_at_const (c : M') (s : Set M) (x : M) :
  HasMfderivWithinAt I I' (fun y : M => c) s x (0 : TangentSpace I x →L[𝕜] TangentSpace I' c) :=
  (has_mfderiv_at_const I I' c x).HasMfderivWithinAt

theorem mdifferentiable_at_const : MdifferentiableAt I I' (fun y : M => c) x :=
  (has_mfderiv_at_const I I' c x).MdifferentiableAt

theorem mdifferentiable_within_at_const : MdifferentiableWithinAt I I' (fun y : M => c) s x :=
  (mdifferentiable_at_const I I').MdifferentiableWithinAt

theorem mdifferentiable_const : Mdifferentiable I I' fun y : M => c :=
  fun x => mdifferentiable_at_const I I'

theorem mdifferentiable_on_const : MdifferentiableOn I I' (fun y : M => c) s :=
  (mdifferentiable_const I I').MdifferentiableOn

@[simp, mfld_simps]
theorem mfderiv_const : mfderiv I I' (fun y : M => c) x = (0 : TangentSpace I x →L[𝕜] TangentSpace I' c) :=
  HasMfderivAt.mfderiv (has_mfderiv_at_const I I' c x)

theorem mfderiv_within_const (hxs : UniqueMdiffWithinAt I s x) :
  mfderivWithin I I' (fun y : M => c) s x = (0 : TangentSpace I x →L[𝕜] TangentSpace I' c) :=
  (has_mfderiv_within_at_const _ _ _ _ _).mfderivWithin hxs

end Const

namespace ModelWithCorners

/-! #### Model with corners -/


protected theorem HasMfderivAt {x} : HasMfderivAt I 𝓘(𝕜, E) I x (ContinuousLinearMap.id _ _) :=
  ⟨I.continuous_at, (has_fderiv_within_at_id _ _).congr' I.right_inv_on (mem_range_self _)⟩

protected theorem HasMfderivWithinAt {s x} : HasMfderivWithinAt I 𝓘(𝕜, E) I s x (ContinuousLinearMap.id _ _) :=
  I.has_mfderiv_at.has_mfderiv_within_at

protected theorem MdifferentiableWithinAt {s x} : MdifferentiableWithinAt I 𝓘(𝕜, E) I s x :=
  I.has_mfderiv_within_at.mdifferentiable_within_at

protected theorem MdifferentiableAt {x} : MdifferentiableAt I 𝓘(𝕜, E) I x :=
  I.has_mfderiv_at.mdifferentiable_at

protected theorem MdifferentiableOn {s} : MdifferentiableOn I 𝓘(𝕜, E) I s :=
  fun x hx => I.mdifferentiable_within_at

protected theorem Mdifferentiable : Mdifferentiable I 𝓘(𝕜, E) I :=
  fun x => I.mdifferentiable_at

theorem has_mfderiv_within_at_symm {x} (hx : x ∈ range I) :
  HasMfderivWithinAt 𝓘(𝕜, E) I I.symm (range I) x (ContinuousLinearMap.id _ _) :=
  ⟨I.continuous_within_at_symm,
    (has_fderiv_within_at_id _ _).congr' (fun y hy => I.right_inv_on hy.1) ⟨hx, mem_range_self _⟩⟩

theorem mdifferentiable_on_symm : MdifferentiableOn 𝓘(𝕜, E) I I.symm (range I) :=
  fun x hx => (I.has_mfderiv_within_at_symm hx).MdifferentiableWithinAt

end ModelWithCorners

section Charts

variable{e : LocalHomeomorph M H}

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem mdifferentiable_at_atlas
(h : «expr ∈ »(e, atlas H M))
{x : M}
(hx : «expr ∈ »(x, e.source)) : mdifferentiable_at I I e x :=
begin
  refine [expr ⟨(e.continuous_on x hx).continuous_at (is_open.mem_nhds e.open_source hx), _⟩],
  have [ident mem] [":", expr «expr ∈ »(I ((chart_at H x : M → H) x), «expr ∩ »(«expr ⁻¹' »(I.symm, «expr ≫ₕ »((chart_at H x).symm, e).source), range I))] [],
  by simp [] [] ["only"] ["[", expr hx, "]"] ["with", ident mfld_simps] [],
  have [] [":", expr «expr ∈ »((chart_at H x).symm.trans e, times_cont_diff_groupoid «expr∞»() I)] [":=", expr has_groupoid.compatible _ (chart_mem_atlas H x) h],
  have [ident A] [":", expr times_cont_diff_on 𝕜 «expr∞»() «expr ∘ »(I, «expr ∘ »((chart_at H x).symm.trans e, I.symm)) «expr ∩ »(«expr ⁻¹' »(I.symm, ((chart_at H x).symm.trans e).source), range I)] [":=", expr this.1],
  have [ident B] [] [":=", expr A.differentiable_on le_top (I ((chart_at H x : M → H) x)) mem],
  simp [] [] ["only"] [] ["with", ident mfld_simps] ["at", ident B],
  rw ["[", expr inter_comm, ",", expr differentiable_within_at_inter, "]"] ["at", ident B],
  { simpa [] [] ["only"] [] ["with", ident mfld_simps] [] },
  { apply [expr is_open.mem_nhds ((local_homeomorph.open_source _).preimage I.continuous_symm) mem.1] }
end

theorem mdifferentiable_on_atlas (h : e ∈ atlas H M) : MdifferentiableOn I I e e.source :=
  fun x hx => (mdifferentiable_at_atlas I h hx).MdifferentiableWithinAt

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem mdifferentiable_at_atlas_symm
(h : «expr ∈ »(e, atlas H M))
{x : H}
(hx : «expr ∈ »(x, e.target)) : mdifferentiable_at I I e.symm x :=
begin
  refine [expr ⟨(e.continuous_on_symm x hx).continuous_at (is_open.mem_nhds e.open_target hx), _⟩],
  have [ident mem] [":", expr «expr ∈ »(I x, «expr ∩ »(«expr ⁻¹' »(I.symm, «expr ≫ₕ »(e.symm, chart_at H (e.symm x)).source), range I))] [],
  by simp [] [] ["only"] ["[", expr hx, "]"] ["with", ident mfld_simps] [],
  have [] [":", expr «expr ∈ »(e.symm.trans (chart_at H (e.symm x)), times_cont_diff_groupoid «expr∞»() I)] [":=", expr has_groupoid.compatible _ h (chart_mem_atlas H _)],
  have [ident A] [":", expr times_cont_diff_on 𝕜 «expr∞»() «expr ∘ »(I, «expr ∘ »(e.symm.trans (chart_at H (e.symm x)), I.symm)) «expr ∩ »(«expr ⁻¹' »(I.symm, (e.symm.trans (chart_at H (e.symm x))).source), range I)] [":=", expr this.1],
  have [ident B] [] [":=", expr A.differentiable_on le_top (I x) mem],
  simp [] [] ["only"] [] ["with", ident mfld_simps] ["at", ident B],
  rw ["[", expr inter_comm, ",", expr differentiable_within_at_inter, "]"] ["at", ident B],
  { simpa [] [] ["only"] [] ["with", ident mfld_simps] [] },
  { apply [expr is_open.mem_nhds ((local_homeomorph.open_source _).preimage I.continuous_symm) mem.1] }
end

theorem mdifferentiable_on_atlas_symm (h : e ∈ atlas H M) : MdifferentiableOn I I e.symm e.target :=
  fun x hx => (mdifferentiable_at_atlas_symm I h hx).MdifferentiableWithinAt

theorem mdifferentiable_of_mem_atlas (h : e ∈ atlas H M) : e.mdifferentiable I I :=
  ⟨mdifferentiable_on_atlas I h, mdifferentiable_on_atlas_symm I h⟩

theorem mdifferentiable_chart (x : M) : (chart_at H x).Mdifferentiable I I :=
  mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)

/-- The derivative of the chart at a base point is the chart of the tangent bundle, composed with
the identification between the tangent bundle of the model space and the product space. -/
theorem tangent_map_chart {p q : TangentBundle I M} (h : q.1 ∈ (chart_at H p.1).Source) :
  tangentMap I I (chart_at H p.1) q =
    (Equiv.sigmaEquivProd _ _).symm ((chart_at (ModelProd H E) p : TangentBundle I M → ModelProd H E) q) :=
  by 
    dsimp [tangentMap]
    rw [MdifferentiableAt.mfderiv]
    ·
      rfl
    ·
      exact mdifferentiable_at_atlas _ (chart_mem_atlas _ _) h

/-- The derivative of the inverse of the chart at a base point is the inverse of the chart of the
tangent bundle, composed with the identification between the tangent bundle of the model space and
the product space. -/
theorem tangent_map_chart_symm {p : TangentBundle I M} {q : TangentBundle I H} (h : q.1 ∈ (chart_at H p.1).Target) :
  tangentMap I I (chart_at H p.1).symm q =
    ((chart_at (ModelProd H E) p).symm : ModelProd H E → TangentBundle I M) ((Equiv.sigmaEquivProd H E) q) :=
  by 
    dsimp only [tangentMap]
    rw [MdifferentiableAt.mfderiv (mdifferentiable_at_atlas_symm _ (chart_mem_atlas _ _) h)]
    rotate
    ·
      infer_instance 
    simp' only [chart_at, BasicSmoothBundleCore.chart, Subtype.coe_mk, tangentBundleCore, h,
      BasicSmoothBundleCore.toTopologicalFiberBundleCore, Equiv.sigma_equiv_prod_apply] with mfld_simps

end Charts

end SpecificFunctions

/-! ### Differentiable local homeomorphisms -/


namespace LocalHomeomorph.Mdifferentiable

variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H]{I :
    ModelWithCorners 𝕜 E
      H}{M :
    Type
      _}[TopologicalSpace
      M][ChartedSpace H
      M]{E' :
    Type
      _}[NormedGroup
      E'][NormedSpace 𝕜
      E']{H' :
    Type
      _}[TopologicalSpace
      H']{I' :
    ModelWithCorners 𝕜 E'
      H'}{M' :
    Type
      _}[TopologicalSpace
      M'][ChartedSpace H'
      M']{E'' :
    Type
      _}[NormedGroup
      E''][NormedSpace 𝕜
      E'']{H'' :
    Type
      _}[TopologicalSpace
      H'']{I'' :
    ModelWithCorners 𝕜 E''
      H''}{M'' :
    Type
      _}[TopologicalSpace
      M''][ChartedSpace H'' M'']{e : LocalHomeomorph M M'}(he : e.mdifferentiable I I'){e' : LocalHomeomorph M' M''}

include he

theorem symm : e.symm.mdifferentiable I' I :=
  ⟨he.2, he.1⟩

protected theorem MdifferentiableAt {x : M} (hx : x ∈ e.source) : MdifferentiableAt I I' e x :=
  (he.1 x hx).MdifferentiableAt (IsOpen.mem_nhds e.open_source hx)

theorem mdifferentiable_at_symm {x : M'} (hx : x ∈ e.target) : MdifferentiableAt I' I e.symm x :=
  (he.2 x hx).MdifferentiableAt (IsOpen.mem_nhds e.open_target hx)

variable[SmoothManifoldWithCorners I M][SmoothManifoldWithCorners I' M'][SmoothManifoldWithCorners I'' M'']

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem symm_comp_deriv
{x : M}
(hx : «expr ∈ »(x, e.source)) : «expr = »((mfderiv I' I e.symm (e x)).comp (mfderiv I I' e x), continuous_linear_map.id 𝕜 (tangent_space I x)) :=
begin
  have [] [":", expr «expr = »(mfderiv I I «expr ∘ »(e.symm, e) x, (mfderiv I' I e.symm (e x)).comp (mfderiv I I' e x))] [":=", expr mfderiv_comp x (he.mdifferentiable_at_symm (e.map_source hx)) (he.mdifferentiable_at hx)],
  rw ["<-", expr this] [],
  have [] [":", expr «expr = »(mfderiv I I (_root_.id : M → M) x, continuous_linear_map.id _ _)] [":=", expr mfderiv_id I],
  rw ["<-", expr this] [],
  apply [expr filter.eventually_eq.mfderiv_eq],
  have [] [":", expr «expr ∈ »(e.source, expr𝓝() x)] [":=", expr is_open.mem_nhds e.open_source hx],
  exact [expr filter.mem_of_superset this (by mfld_set_tac)]
end

theorem comp_symm_deriv {x : M'} (hx : x ∈ e.target) :
  (mfderiv I I' e (e.symm x)).comp (mfderiv I' I e.symm x) = ContinuousLinearMap.id 𝕜 (TangentSpace I' x) :=
  he.symm.symm_comp_deriv hx

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- The derivative of a differentiable local homeomorphism, as a continuous linear equivalence
between the tangent spaces at `x` and `e x`. -/
protected
def mfderiv {x : M} (hx : «expr ∈ »(x, e.source)) : «expr ≃L[ ] »(tangent_space I x, 𝕜, tangent_space I' (e x)) :=
{ inv_fun := mfderiv I' I e.symm (e x),
  continuous_to_fun := (mfderiv I I' e x).cont,
  continuous_inv_fun := (mfderiv I' I e.symm (e x)).cont,
  left_inv := λ y, begin
    have [] [":", expr «expr = »((continuous_linear_map.id _ _ : «expr →L[ ] »(tangent_space I x, 𝕜, tangent_space I x)) y, y)] [":=", expr rfl],
    conv_rhs [] [] { rw ["[", "<-", expr this, ",", "<-", expr he.symm_comp_deriv hx, "]"] },
    refl
  end,
  right_inv := λ y, begin
    have [] [":", expr «expr = »((continuous_linear_map.id 𝕜 _ : «expr →L[ ] »(tangent_space I' (e x), 𝕜, tangent_space I' (e x))) y, y)] [":=", expr rfl],
    conv_rhs [] [] { rw ["[", "<-", expr this, ",", "<-", expr he.comp_symm_deriv (e.map_source hx), "]"] },
    rw [expr e.left_inv hx] [],
    refl
  end,
  ..mfderiv I I' e x }

theorem mfderiv_bijective {x : M} (hx : x ∈ e.source) : Function.Bijective (mfderiv I I' e x) :=
  (he.mfderiv hx).Bijective

theorem mfderiv_injective {x : M} (hx : x ∈ e.source) : Function.Injective (mfderiv I I' e x) :=
  (he.mfderiv hx).Injective

theorem mfderiv_surjective {x : M} (hx : x ∈ e.source) : Function.Surjective (mfderiv I I' e x) :=
  (he.mfderiv hx).Surjective

theorem ker_mfderiv_eq_bot {x : M} (hx : x ∈ e.source) : (mfderiv I I' e x).ker = ⊥ :=
  (he.mfderiv hx).toLinearEquiv.ker

theorem range_mfderiv_eq_top {x : M} (hx : x ∈ e.source) : (mfderiv I I' e x).range = ⊤ :=
  (he.mfderiv hx).toLinearEquiv.range

theorem range_mfderiv_eq_univ {x : M} (hx : x ∈ e.source) : range (mfderiv I I' e x) = univ :=
  (he.mfderiv_surjective hx).range_eq

theorem trans (he' : e'.mdifferentiable I' I'') : (e.trans e').Mdifferentiable I I'' :=
  by 
    split 
    ·
      intro x hx 
      simp' only with mfld_simps  at hx 
      exact ((he'.mdifferentiable_at hx.2).comp _ (he.mdifferentiable_at hx.1)).MdifferentiableWithinAt
    ·
      intro x hx 
      simp' only with mfld_simps  at hx 
      exact ((he.symm.mdifferentiable_at hx.2).comp _ (he'.symm.mdifferentiable_at hx.1)).MdifferentiableWithinAt

end LocalHomeomorph.Mdifferentiable

/-! ### Differentiability of `ext_chart_at` -/


section extChartAt

variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H](I :
    ModelWithCorners 𝕜 E
      H){M : Type _}[TopologicalSpace M][ChartedSpace H M][SmoothManifoldWithCorners I M]{s : Set M}{x y : M}

theorem has_mfderiv_at_ext_chart_at (h : y ∈ (chart_at H x).Source) :
  HasMfderivAt I 𝓘(𝕜, E) (extChartAt I x) y (mfderiv I I (chart_at H x) y : _) :=
  I.has_mfderiv_at.comp y ((mdifferentiable_chart I x).MdifferentiableAt h).HasMfderivAt

theorem has_mfderiv_within_at_ext_chart_at (h : y ∈ (chart_at H x).Source) :
  HasMfderivWithinAt I 𝓘(𝕜, E) (extChartAt I x) s y (mfderiv I I (chart_at H x) y : _) :=
  (has_mfderiv_at_ext_chart_at I h).HasMfderivWithinAt

theorem mdifferentiable_at_ext_chart_at (h : y ∈ (chart_at H x).Source) :
  MdifferentiableAt I 𝓘(𝕜, E) (extChartAt I x) y :=
  (has_mfderiv_at_ext_chart_at I h).MdifferentiableAt

theorem mdifferentiable_on_ext_chart_at : MdifferentiableOn I 𝓘(𝕜, E) (extChartAt I x) (chart_at H x).Source :=
  fun y hy => (has_mfderiv_within_at_ext_chart_at I hy).MdifferentiableWithinAt

end extChartAt

/-! ### Unique derivative sets in manifolds -/


section UniqueMdiff

variable{𝕜 :
    Type
      _}[NondiscreteNormedField
      𝕜]{E :
    Type
      _}[NormedGroup
      E][NormedSpace 𝕜
      E]{H :
    Type
      _}[TopologicalSpace
      H]{I :
    ModelWithCorners 𝕜 E
      H}{M :
    Type
      _}[TopologicalSpace
      M][ChartedSpace H
      M][SmoothManifoldWithCorners I
      M]{E' :
    Type
      _}[NormedGroup
      E'][NormedSpace 𝕜
      E']{H' :
    Type
      _}[TopologicalSpace
      H']{I' : ModelWithCorners 𝕜 E' H'}{M' : Type _}[TopologicalSpace M'][ChartedSpace H' M']{s : Set M}

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- If a set has the unique differential property, then its image under a local
diffeomorphism also has the unique differential property. -/
theorem unique_mdiff_on.unique_mdiff_on_preimage
[smooth_manifold_with_corners I' M']
(hs : unique_mdiff_on I s)
{e : local_homeomorph M M'}
(he : e.mdifferentiable I I') : unique_mdiff_on I' «expr ∩ »(e.target, «expr ⁻¹' »(e.symm, s)) :=
begin
  assume [binders (x hx)],
  let [ident z] [] [":=", expr e.symm x],
  have [ident z_source] [":", expr «expr ∈ »(z, e.source)] [],
  by simp [] [] ["only"] ["[", expr hx.1, "]"] ["with", ident mfld_simps] [],
  have [ident zx] [":", expr «expr = »(e z, x)] [],
  by simp [] [] ["only"] ["[", expr z, ",", expr hx.1, "]"] ["with", ident mfld_simps] [],
  let [ident F] [] [":=", expr ext_chart_at I z],
  have [ident B] [":", expr unique_diff_within_at 𝕜 «expr ∩ »(«expr ⁻¹' »(F.symm, «expr ∩ »(s, «expr ∩ »(e.source, «expr ⁻¹' »(e, (ext_chart_at I' x).source)))), F.target) (F z)] [],
  { have [] [":", expr unique_mdiff_within_at I s z] [":=", expr hs _ hx.2],
    have [ident S] [":", expr «expr ∈ »(«expr ∩ »(e.source, «expr ⁻¹' »(e, (ext_chart_at I' x).source)), expr𝓝() z)] [],
    { apply [expr is_open.mem_nhds],
      apply [expr e.continuous_on.preimage_open_of_open e.open_source (ext_chart_at_open_source I' x)],
      simp [] [] ["only"] ["[", expr z_source, ",", expr zx, "]"] ["with", ident mfld_simps] [] },
    have [] [] [":=", expr this.inter S],
    rw ["[", expr unique_mdiff_within_at_iff, "]"] ["at", ident this],
    exact [expr this] },
  let [ident G] [] [":=", expr «expr ≫ »(F.symm, «expr ≫ »(e.to_local_equiv, ext_chart_at I' x))],
  have [ident Diff] [":", expr «expr ≫ₕ »((chart_at H z).symm, «expr ≫ₕ »(e, chart_at H' x)).mdifferentiable I I'] [],
  { have [ident A] [] [":=", expr mdifferentiable_of_mem_atlas I (chart_mem_atlas H z)],
    have [ident B] [] [":=", expr mdifferentiable_of_mem_atlas I' (chart_mem_atlas H' x)],
    exact [expr A.symm.trans (he.trans B)] },
  have [ident Mmem] [":", expr «expr ∈ »((chart_at H z : M → H) z, «expr ≫ₕ »((chart_at H z).symm, «expr ≫ₕ »(e, chart_at H' x)).source)] [],
  by simp [] [] ["only"] ["[", expr z_source, ",", expr zx, "]"] ["with", ident mfld_simps] [],
  have [ident A] [":", expr differentiable_within_at 𝕜 G (range I) (F z)] [],
  { refine [expr (Diff.mdifferentiable_at Mmem).2.congr (λ
      p hp, _) _]; simp [] [] ["only"] ["[", expr G, ",", expr F, "]"] ["with", ident mfld_simps] [] },
  let [ident G'] [] [":=", expr fderiv_within 𝕜 G (range I) (F z)],
  have [ident D₁] [":", expr has_fderiv_within_at G G' (range I) (F z)] [":=", expr A.has_fderiv_within_at],
  have [ident D₂] [":", expr has_fderiv_within_at G G' «expr ∩ »(«expr ⁻¹' »(F.symm, «expr ∩ »(s, «expr ∩ »(e.source, «expr ⁻¹' »(e, (ext_chart_at I' x).source)))), F.target) (F z)] [":=", expr D₁.mono (by mfld_set_tac)],
  have [ident C] [":", expr dense_range (G' : E → E')] [],
  { have [] [":", expr «expr = »(G', mfderiv I I' «expr ≫ₕ »((chart_at H z).symm, «expr ≫ₕ »(e, chart_at H' x)) ((chart_at H z : M → H) z))] [],
    by { rw [expr (Diff.mdifferentiable_at Mmem).mfderiv] [],
      refl },
    rw [expr this] [],
    exact [expr (Diff.mfderiv_surjective Mmem).dense_range] },
  have [ident key] [":", expr unique_diff_within_at 𝕜 «expr '' »(G, «expr ∩ »(«expr ⁻¹' »(F.symm, «expr ∩ »(s, «expr ∩ »(e.source, «expr ⁻¹' »(e, (ext_chart_at I' x).source)))), F.target)) (G (F z))] [":=", expr D₂.unique_diff_within_at B C],
  have [] [":", expr «expr = »(G (F z), ext_chart_at I' x x)] [],
  by { dsimp [] ["[", expr G, ",", expr F, "]"] [] [],
    simp [] [] ["only"] ["[", expr hx.1, "]"] ["with", ident mfld_simps] [] },
  rw [expr this] ["at", ident key],
  apply [expr key.mono],
  show [expr «expr ⊆ »(«expr '' »(G, «expr ∩ »(«expr ⁻¹' »(F.symm, «expr ∩ »(s, «expr ∩ »(e.source, «expr ⁻¹' »(e, (ext_chart_at I' x).source)))), F.target)), «expr ∩ »(«expr ∩ »(«expr ⁻¹' »((ext_chart_at I' x).symm, e.target), «expr ⁻¹' »((ext_chart_at I' x).symm, «expr ⁻¹' »(e.symm, s))), range I'))],
  rw [expr image_subset_iff] [],
  mfld_set_tac
end

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- If a set in a manifold has the unique derivative property, then its pullback by any extended
chart, in the vector space, also has the unique derivative property. -/
theorem unique_mdiff_on.unique_diff_on_target_inter
(hs : unique_mdiff_on I s)
(x : M) : unique_diff_on 𝕜 «expr ∩ »((ext_chart_at I x).target, «expr ⁻¹' »((ext_chart_at I x).symm, s)) :=
begin
  assume [binders (z hz)],
  simp [] [] ["only"] [] ["with", ident mfld_simps] ["at", ident hz],
  have [] [":", expr (chart_at H x).mdifferentiable I I] [":=", expr mdifferentiable_chart _ _],
  have [ident T] [] [":=", expr hs.unique_mdiff_on_preimage this (I.symm z)],
  simp [] [] ["only"] ["[", expr hz.left.left, ",", expr hz.left.right, ",", expr hz.right, ",", expr unique_mdiff_within_at, "]"] ["with", ident mfld_simps] ["at", "⊢", ident T],
  convert [] [expr T] ["using", 1],
  rw [expr @preimage_comp _ _ _ _ (chart_at H x).symm] [],
  mfld_set_tac
end

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- When considering functions between manifolds, this statement shows up often. It entails
the unique differential of the pullback in extended charts of the set where the function can
be read in the charts. -/
theorem unique_mdiff_on.unique_diff_on_inter_preimage
(hs : unique_mdiff_on I s)
(x : M)
(y : M')
{f : M → M'}
(hf : continuous_on f s) : unique_diff_on 𝕜 «expr ∩ »((ext_chart_at I x).target, «expr ⁻¹' »((ext_chart_at I x).symm, «expr ∩ »(s, «expr ⁻¹' »(f, (ext_chart_at I' y).source)))) :=
begin
  have [] [":", expr unique_mdiff_on I «expr ∩ »(s, «expr ⁻¹' »(f, (ext_chart_at I' y).source))] [],
  { assume [binders (z hz)],
    apply [expr (hs z hz.1).inter'],
    apply [expr (hf z hz.1).preimage_mem_nhds_within],
    exact [expr is_open.mem_nhds (ext_chart_at_open_source I' y) hz.2] },
  exact [expr this.unique_diff_on_target_inter _]
end

variable{F : Type _}[NormedGroup F][NormedSpace 𝕜 F](Z : BasicSmoothBundleCore I M F)

-- error in Geometry.Manifold.Mfderiv: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- In a smooth fiber bundle constructed from core, the preimage under the projection of a set with
unique differential in the basis also has unique differential. -/
theorem unique_mdiff_on.smooth_bundle_preimage
(hs : unique_mdiff_on I s) : unique_mdiff_on (I.prod «expr𝓘( , )»(𝕜, F)) «expr ⁻¹' »(Z.to_topological_fiber_bundle_core.proj, s) :=
begin
  assume [binders (p hp)],
  replace [ident hp] [":", expr «expr ∈ »(p.fst, s)] [],
  by simpa [] [] ["only"] [] ["with", ident mfld_simps] ["using", expr hp],
  let [ident e₀] [] [":=", expr chart_at H p.1],
  let [ident e] [] [":=", expr chart_at (model_prod H F) p],
  suffices [ident h] [":", expr unique_mdiff_on (I.prod «expr𝓘( , )»(𝕜, F)) «expr ∩ »(e.target, «expr ⁻¹' »(e.symm, «expr ⁻¹' »(Z.to_topological_fiber_bundle_core.proj, s)))],
  { have [ident A] [":", expr unique_mdiff_on (I.prod «expr𝓘( , )»(𝕜, F)) «expr ∩ »(e.symm.target, «expr ⁻¹' »(e.symm.symm, «expr ∩ »(e.target, «expr ⁻¹' »(e.symm, «expr ⁻¹' »(Z.to_topological_fiber_bundle_core.proj, s)))))] [],
    { apply [expr h.unique_mdiff_on_preimage],
      exact [expr (mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)).symm],
      apply_instance },
    have [] [":", expr «expr ∈ »(p, «expr ∩ »(e.symm.target, «expr ⁻¹' »(e.symm.symm, «expr ∩ »(e.target, «expr ⁻¹' »(e.symm, «expr ⁻¹' »(Z.to_topological_fiber_bundle_core.proj, s))))))] [],
    by simp [] [] ["only"] ["[", expr e, ",", expr hp, "]"] ["with", ident mfld_simps] [],
    apply [expr (A _ this).mono],
    assume [binders (q hq)],
    simp [] [] ["only"] ["[", expr e, ",", expr local_homeomorph.left_inv _ hq.1, "]"] ["with", ident mfld_simps] ["at", ident hq],
    simp [] [] ["only"] ["[", expr hq, "]"] ["with", ident mfld_simps] [] },
  have [] [":", expr «expr = »(«expr ∩ »(«expr ∩ »(«expr ⁻¹' »(λ
       p : «expr × »(E, F), (I.symm p.1, p.snd), e.target), «expr ⁻¹' »(λ
       p : «expr × »(E, F), (I.symm p.1, p.snd), «expr ⁻¹' »(e.symm, «expr ⁻¹' »(sigma.fst, s)))), (range I).prod univ), set.prod «expr ∩ »(«expr ⁻¹' »(I.symm, «expr ∩ »(e₀.target, «expr ⁻¹' »(e₀.symm, s))), range I) univ)] [],
  by mfld_set_tac,
  assume [binders (q hq)],
  replace [ident hq] [":", expr «expr ∧ »(«expr ∈ »(q.1, (chart_at H p.1).target), «expr ∈ »(((chart_at H p.1).symm : H → M) q.1, s))] [],
  by simpa [] [] ["only"] [] ["with", ident mfld_simps] ["using", expr hq],
  simp [] [] ["only"] ["[", expr unique_mdiff_within_at, ",", expr model_with_corners.prod, ",", expr preimage_inter, ",", expr this, "]"] ["with", ident mfld_simps] [],
  apply [expr unique_diff_on.prod _ unique_diff_on_univ],
  { simp [] [] ["only"] ["[", expr hq, "]"] ["with", ident mfld_simps] [] },
  { assume [binders (x hx)],
    have [ident A] [":", expr unique_mdiff_on I «expr ∩ »(e₀.target, «expr ⁻¹' »(e₀.symm, s))] [],
    { apply [expr hs.unique_mdiff_on_preimage],
      exact [expr mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)],
      apply_instance },
    simp [] [] ["only"] ["[", expr unique_mdiff_on, ",", expr unique_mdiff_within_at, ",", expr preimage_inter, "]"] ["with", ident mfld_simps] ["at", ident A],
    have [ident B] [] [":=", expr A (I.symm x) hx.1.1 hx.1.2],
    rwa ["[", "<-", expr preimage_inter, ",", expr model_with_corners.right_inv _ hx.2, "]"] ["at", ident B] }
end

theorem UniqueMdiffOn.tangent_bundle_proj_preimage (hs : UniqueMdiffOn I s) :
  UniqueMdiffOn I.tangent (TangentBundle.proj I M ⁻¹' s) :=
  hs.smooth_bundle_preimage _

end UniqueMdiff

