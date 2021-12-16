import Mathbin.Topology.UnitInterval 
import Mathbin.Topology.Algebra.Ordered.ProjIcc 
import Mathbin.Topology.ContinuousFunction.Basic

/-!
# Path connectedness

## Main definitions

In the file the unit interval `[0, 1]` in `ℝ` is denoted by `I`, and `X` is a topological space.

* `path (x y : X)` is the type of paths from `x` to `y`, i.e., continuous maps from `I` to `X`
  mapping `0` to `x` and `1` to `y`.
* `path.map` is the image of a path under a continuous map.
* `joined (x y : X)` means there is a path between `x` and `y`.
* `joined.some_path (h : joined x y)` selects some path between two points `x` and `y`.
* `path_component (x : X)` is the set of points joined to `x`.
* `path_connected_space X` is a predicate class asserting that `X` is non-empty and every two
  points of `X` are joined.

Then there are corresponding relative notions for `F : set X`.

* `joined_in F (x y : X)` means there is a path `γ` joining `x` to `y` with values in `F`.
* `joined_in.some_path (h : joined_in F x y)` selects a path from `x` to `y` inside `F`.
* `path_component_in F (x : X)` is the set of points joined to `x` in `F`.
* `is_path_connected F` asserts that `F` is non-empty and every two
  points of `F` are joined in `F`.
* `loc_path_connected_space X` is a predicate class asserting that `X` is locally path-connected:
  each point has a basis of path-connected neighborhoods (we do *not* ask these to be open).

## Main theorems

* `joined` and `joined_in F` are transitive relations.

One can link the absolute and relative version in two directions, using `(univ : set X)` or the
subtype `↥F`.

* `path_connected_space_iff_univ : path_connected_space X ↔ is_path_connected (univ : set X)`
* `is_path_connected_iff_path_connected_space : is_path_connected F ↔ path_connected_space ↥F`

For locally path connected spaces, we have
* `path_connected_space_iff_connected_space : path_connected_space X ↔ connected_space X`
* `is_connected_iff_is_path_connected (U_op : is_open U) : is_path_connected U ↔ is_connected U`

## Implementation notes

By default, all paths have `I` as their source and `X` as their target, but there is an
operation `set.Icc_extend` that will extend any continuous map `γ : I → X` into a continuous map
`Icc_extend zero_le_one γ : ℝ → X` that is constant before `0` and after `1`.

This is used to define `path.extend` that turns `γ : path x y` into a continuous map
`γ.extend : ℝ → X` whose restriction to `I` is the original `γ`, and is equal to `x`
on `(-∞, 0]` and to `y` on `[1, +∞)`.
-/


noncomputable section 

open_locale Classical TopologicalSpace Filter UnitInterval

open Filter Set Function UnitInterval

variable {X Y : Type _} [TopologicalSpace X] [TopologicalSpace Y] {x y z : X} {ι : Type _}

/-! ### Paths -/


/-- Continuous path connecting two points `x` and `y` in a topological space -/
@[nolint has_inhabited_instance]
structure Path (x y : X) extends C(I, X) where 
  source' : to_fun 0 = x 
  target' : to_fun 1 = y

instance : CoeFun (Path x y) fun _ => I → X :=
  ⟨fun p => p.to_fun⟩

@[ext]
protected theorem Path.ext : ∀ {γ₁ γ₂ : Path x y}, (γ₁ : I → X) = γ₂ → γ₁ = γ₂
| ⟨⟨x, h11⟩, h12, h13⟩, ⟨⟨x, h21⟩, h22, h23⟩, rfl => rfl

namespace Path

@[simp]
theorem coe_mk (f : I → X) h₁ h₂ h₃ : ⇑(mk ⟨f, h₁⟩ h₂ h₃ : Path x y) = f :=
  rfl

variable (γ : Path x y)

@[continuity]
protected theorem Continuous : Continuous γ :=
  γ.continuous_to_fun

@[simp]
protected theorem source : γ 0 = x :=
  γ.source'

@[simp]
protected theorem target : γ 1 = y :=
  γ.target'

/-- See Note [custom simps projection]. We need to specify this projection explicitly in this case,
because it is a composition of multiple projections. -/
def simps.apply : I → X :=
  γ

initialize_simps_projections Path (to_continuous_map_to_fun → simps.apply, -toContinuousMap)

@[simp]
theorem coe_to_continuous_map : ⇑γ.to_continuous_map = γ :=
  rfl

/-- Any function `φ : Π (a : α), path (x a) (y a)` can be seen as a function `α × I → X`. -/
instance has_uncurry_path {X α : Type _} [TopologicalSpace X] {x y : α → X} :
  has_uncurry (∀ a : α, Path (x a) (y a)) (α × I) X :=
  ⟨fun φ p => φ p.1 p.2⟩

/-- The constant path from a point to itself -/
@[refl, simps]
def refl (x : X) : Path x x :=
  { toFun := fun t => x, continuous_to_fun := continuous_const, source' := rfl, target' := rfl }

@[simp]
theorem refl_range {a : X} : range (Path.refl a) = {a} :=
  by 
    simp [Path.refl, CoeFun.coe, coeFn]

/-- The reverse of a path from `x` to `y`, as a path from `y` to `x` -/
@[symm, simps]
def symm (γ : Path x y) : Path y x :=
  { toFun := γ ∘ σ,
    continuous_to_fun :=
      by 
        continuity,
    source' :=
      by 
        simpa [-Path.target] using γ.target,
    target' :=
      by 
        simpa [-Path.source] using γ.source }

@[simp]
theorem symm_symm {γ : Path x y} : γ.symm.symm = γ :=
  by 
    ext 
    simp 

@[simp]
theorem refl_symm {a : X} : (Path.refl a).symm = Path.refl a :=
  by 
    ext 
    rfl

@[simp]
theorem symm_range {a b : X} (γ : Path a b) : range γ.symm = range γ :=
  by 
    ext x 
    simp only [mem_range, Path.symm, CoeFun.coe, coeFn, UnitInterval.symm, SetCoe.exists, comp_app, Subtype.coe_mk,
      Subtype.val_eq_coe]
    constructor <;> rintro ⟨y, hy, hxy⟩ <;> refine' ⟨1 - y, mem_iff_one_sub_mem.mp hy, _⟩ <;> convert hxy 
    simp 

/-- A continuous map extending a path to `ℝ`, constant before `0` and after `1`. -/
def extend : ℝ → X :=
  Icc_extend zero_le_one γ

/-- See Note [continuity lemma statement]. -/
theorem _root_.continuous.path_extend {γ : Y → Path x y} {f : Y → ℝ} (hγ : Continuous (↿γ)) (hf : Continuous f) :
  Continuous fun t => (γ t).extend (f t) :=
  Continuous.Icc_extend hγ hf

/-- A useful special case of `continuous.path_extend`. -/
@[continuity]
theorem continuous_extend : Continuous γ.extend :=
  γ.continuous.Icc_extend'

theorem _root_.filter.tendsto.path_extend {X Y : Type _} [TopologicalSpace X] [TopologicalSpace Y] {l r : Y → X} {y : Y}
  {l₁ : Filter ℝ} {l₂ : Filter X} {γ : ∀ y, Path (l y) (r y)}
  (hγ : tendsto (↿γ) (𝓝 y ×ᶠ l₁.map (proj_Icc 0 1 zero_le_one)) l₂) : tendsto (↿fun x => (γ x).extend) (𝓝 y ×ᶠ l₁) l₂ :=
  Filter.Tendsto.Icc_extend _ hγ

theorem _root_.continuous_at.path_extend {g : Y → ℝ} {l r : Y → X} (γ : ∀ y, Path (l y) (r y)) {y : Y}
  (hγ : ContinuousAt (↿γ) (y, proj_Icc 0 1 zero_le_one (g y))) (hg : ContinuousAt g y) :
  ContinuousAt (fun i => (γ i).extend (g i)) y :=
  hγ.Icc_extend (fun x => γ x) hg

@[simp]
theorem extend_extends {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) {t : ℝ} (ht : t ∈ (Icc 0 1 : Set ℝ)) :
  γ.extend t = γ ⟨t, ht⟩ :=
  Icc_extend_of_mem _ γ ht

theorem extend_zero : γ.extend 0 = x :=
  by 
    simp 

theorem extend_one : γ.extend 1 = y :=
  by 
    simp 

@[simp]
theorem extend_extends' {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) (t : (Icc 0 1 : Set ℝ)) :
  γ.extend t = γ t :=
  Icc_extend_coe _ γ t

@[simp]
theorem extend_range {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) : range γ.extend = range γ :=
  Icc_extend_range _ γ

theorem extend_of_le_zero {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) {t : ℝ} (ht : t ≤ 0) :
  γ.extend t = a :=
  (Icc_extend_of_le_left _ _ ht).trans γ.source

theorem extend_of_one_le {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) {t : ℝ} (ht : 1 ≤ t) :
  γ.extend t = b :=
  (Icc_extend_of_right_le _ _ ht).trans γ.target

@[simp]
theorem refl_extend {X : Type _} [TopologicalSpace X] {a : X} : (Path.refl a).extend = fun _ => a :=
  rfl

/-- The path obtained from a map defined on `ℝ` by restriction to the unit interval. -/
def of_line {f : ℝ → X} (hf : ContinuousOn f I) (h₀ : f 0 = x) (h₁ : f 1 = y) : Path x y :=
  { toFun := f ∘ coeₓ, continuous_to_fun := hf.comp_continuous continuous_subtype_coe Subtype.prop, source' := h₀,
    target' := h₁ }

theorem of_line_mem {f : ℝ → X} (hf : ContinuousOn f I) (h₀ : f 0 = x) (h₁ : f 1 = y) :
  ∀ t, of_line hf h₀ h₁ t ∈ f '' I :=
  fun ⟨t, t_in⟩ => ⟨t, t_in, rfl⟩

attribute [local simp] Iic_def

/-- Concatenation of two paths from `x` to `y` and from `y` to `z`, putting the first
path on `[0, 1/2]` and the second one on `[1/2, 1]`. -/
@[trans]
def trans (γ : Path x y) (γ' : Path y z) : Path x z :=
  { toFun := (fun t : ℝ => if t ≤ 1 / 2 then γ.extend (2*t) else γ'.extend ((2*t) - 1)) ∘ coeₓ,
    continuous_to_fun :=
      by 
        refine'
          (Continuous.if_le _ _ continuous_id continuous_const
                (by 
                  normNum)).comp
            continuous_subtype_coe 
        exacts[γ.continuous_extend.comp (continuous_const.mul continuous_id),
          γ'.continuous_extend.comp ((continuous_const.mul continuous_id).sub continuous_const)],
    source' :=
      by 
        normNum,
    target' :=
      by 
        normNum }

theorem trans_apply (γ : Path x y) (γ' : Path y z) (t : I) :
  (γ.trans γ') t =
    if h : (t : ℝ) ≤ 1 / 2 then γ ⟨2*t, (mul_pos_mem_iff zero_lt_two).2 ⟨t.2.1, h⟩⟩ else
      γ' ⟨(2*t) - 1, two_mul_sub_one_mem_iff.2 ⟨(not_leₓ.1 h).le, t.2.2⟩⟩ :=
  show ite _ _ _ = _ by 
    splitIfs <;> rw [extend_extends]

@[simp]
theorem trans_symm (γ : Path x y) (γ' : Path y z) : (γ.trans γ').symm = γ'.symm.trans γ.symm :=
  by 
    ext t 
    simp only [trans_apply, one_div, symm_apply, not_leₓ, comp_app]
    splitIfs with h h₁ h₂ h₃ h₄ <;> rw [coe_symm_eq] at h
    ·
      have ht : (t : ℝ) = 1 / 2
      ·
        linarith [UnitInterval.nonneg t, UnitInterval.le_one t]
      normNum [ht]
    ·
      refine' congr_argₓ _ (Subtype.ext _)
      normNum [sub_sub_assoc_swap, mul_sub]
    ·
      refine' congr_argₓ _ (Subtype.ext _)
      have h : (2 - 2*(t : ℝ)) - 1 = 1 - 2*t
      ·
        linarith 
      normNum [mul_sub, h]
    ·
      exfalso 
      linarith [UnitInterval.nonneg t, UnitInterval.le_one t]

@[simp]
theorem refl_trans_refl {X : Type _} [TopologicalSpace X] {a : X} : (Path.refl a).trans (Path.refl a) = Path.refl a :=
  by 
    ext 
    simp only [Path.trans, if_t_t, one_div, Path.refl_extend]
    rfl

theorem trans_range {X : Type _} [TopologicalSpace X] {a b c : X} (γ₁ : Path a b) (γ₂ : Path b c) :
  range (γ₁.trans γ₂) = range γ₁ ∪ range γ₂ :=
  by 
    rw [Path.trans]
    apply eq_of_subset_of_subset
    ·
      rintro x ⟨⟨t, ht0, ht1⟩, hxt⟩
      byCases' h : t ≤ 1 / 2
      ·
        left 
        use 2*t,
          ⟨by 
              linarith,
            by 
              linarith⟩
        rw [←γ₁.extend_extends]
        unfoldCoes  at hxt 
        simp only [h, comp_app, if_true] at hxt 
        exact hxt
      ·
        right 
        use (2*t) - 1,
          ⟨by 
              linarith,
            by 
              linarith⟩
        rw [←γ₂.extend_extends]
        unfoldCoes  at hxt 
        simp only [h, comp_app, if_false] at hxt 
        exact hxt
    ·
      rintro x (⟨⟨t, ht0, ht1⟩, hxt⟩ | ⟨⟨t, ht0, ht1⟩, hxt⟩)
      ·
        use
          ⟨t / 2,
            ⟨by 
                linarith,
              by 
                linarith⟩⟩
        unfoldCoes 
        have  : t / 2 ≤ 1 / 2 :=
          by 
            linarith 
        simp only [this, comp_app, if_true]
        ringNF 
        rwa [γ₁.extend_extends]
      ·
        byCases' h : t = 0
        ·
          use
            ⟨1 / 2,
              ⟨by 
                  linarith,
                by 
                  linarith⟩⟩
          unfoldCoes 
          simp only [h, comp_app, if_true, le_reflₓ, mul_one_div_cancel (@two_ne_zero ℝ _ _)]
          rw [γ₁.extend_one]
          rwa [←γ₂.extend_extends, h, γ₂.extend_zero] at hxt
        ·
          use
            ⟨(t+1) / 2,
              ⟨by 
                  linarith,
                by 
                  linarith⟩⟩
          unfoldCoes 
          change t ≠ 0 at h 
          have ht0 := lt_of_le_of_neₓ ht0 h.symm 
          have  : ¬(t+1) / 2 ≤ 1 / 2 :=
            by 
              rw [not_leₓ]
              linarith 
          simp only [comp_app, if_false, this]
          ringNF 
          rwa [γ₂.extend_extends]

/-- Image of a path from `x` to `y` by a continuous map -/
def map (γ : Path x y) {Y : Type _} [TopologicalSpace Y] {f : X → Y} (h : Continuous f) : Path (f x) (f y) :=
  { toFun := f ∘ γ,
    continuous_to_fun :=
      by 
        continuity,
    source' :=
      by 
        simp ,
    target' :=
      by 
        simp  }

@[simp]
theorem map_coe (γ : Path x y) {Y : Type _} [TopologicalSpace Y] {f : X → Y} (h : Continuous f) :
  (γ.map h : I → Y) = (f ∘ γ) :=
  by 
    ext t 
    rfl

@[simp]
theorem map_symm (γ : Path x y) {Y : Type _} [TopologicalSpace Y] {f : X → Y} (h : Continuous f) :
  (γ.map h).symm = γ.symm.map h :=
  rfl

@[simp]
theorem map_trans (γ : Path x y) (γ' : Path y z) {Y : Type _} [TopologicalSpace Y] {f : X → Y} (h : Continuous f) :
  (γ.trans γ').map h = (γ.map h).trans (γ'.map h) :=
  by 
    ext t 
    rw [trans_apply, map_coe, comp_app, trans_apply]
    splitIfs <;> rfl

@[simp]
theorem map_id (γ : Path x y) : γ.map continuous_id = γ :=
  by 
    ext 
    rfl

@[simp]
theorem map_map (γ : Path x y) {Y : Type _} [TopologicalSpace Y] {Z : Type _} [TopologicalSpace Z] {f : X → Y}
  (hf : Continuous f) {g : Y → Z} (hg : Continuous g) : (γ.map hf).map hg = γ.map (hg.comp hf) :=
  by 
    ext 
    rfl

/-- Casting a path from `x` to `y` to a path from `x'` to `y'` when `x' = x` and `y' = y` -/
def cast (γ : Path x y) {x' y'} (hx : x' = x) (hy : y' = y) : Path x' y' :=
  { toFun := γ, continuous_to_fun := γ.continuous,
    source' :=
      by 
        simp [hx],
    target' :=
      by 
        simp [hy] }

@[simp]
theorem symm_cast {X : Type _} [TopologicalSpace X] {a₁ a₂ b₁ b₂ : X} (γ : Path a₂ b₂) (ha : a₁ = a₂) (hb : b₁ = b₂) :
  (γ.cast ha hb).symm = γ.symm.cast hb ha :=
  rfl

@[simp]
theorem trans_cast {X : Type _} [TopologicalSpace X] {a₁ a₂ b₁ b₂ c₁ c₂ : X} (γ : Path a₂ b₂) (γ' : Path b₂ c₂)
  (ha : a₁ = a₂) (hb : b₁ = b₂) (hc : c₁ = c₂) : (γ.cast ha hb).trans (γ'.cast hb hc) = (γ.trans γ').cast ha hc :=
  rfl

@[simp]
theorem cast_coe (γ : Path x y) {x' y'} (hx : x' = x) (hy : y' = y) : (γ.cast hx hy : I → X) = γ :=
  rfl

@[continuity]
theorem symm_continuous_family {X ι : Type _} [TopologicalSpace X] [TopologicalSpace ι] {a b : ι → X}
  (γ : ∀ t : ι, Path (a t) (b t)) (h : Continuous (↿γ)) : Continuous (↿fun t => (γ t).symm) :=
  h.comp (continuous_id.prod_map continuous_symm)

@[continuity]
theorem continuous_uncurry_extend_of_continuous_family {X ι : Type _} [TopologicalSpace X] [TopologicalSpace ι]
  {a b : ι → X} (γ : ∀ t : ι, Path (a t) (b t)) (h : Continuous (↿γ)) : Continuous (↿fun t => (γ t).extend) :=
  h.comp (continuous_id.prod_map continuous_proj_Icc)

@[continuity]
theorem trans_continuous_family {X ι : Type _} [TopologicalSpace X] [TopologicalSpace ι] {a b c : ι → X}
  (γ₁ : ∀ t : ι, Path (a t) (b t)) (h₁ : Continuous (↿γ₁)) (γ₂ : ∀ t : ι, Path (b t) (c t)) (h₂ : Continuous (↿γ₂)) :
  Continuous (↿fun t => (γ₁ t).trans (γ₂ t)) :=
  by 
    have h₁' := Path.continuous_uncurry_extend_of_continuous_family γ₁ h₁ 
    have h₂' := Path.continuous_uncurry_extend_of_continuous_family γ₂ h₂ 
    simp only [has_uncurry.uncurry, CoeFun.coe, coeFn, Path.trans, · ∘ ·]
    refine' Continuous.if_le _ _ (continuous_subtype_coe.comp continuous_snd) continuous_const _
    ·
      change Continuous ((fun p : ι × ℝ => (γ₁ p.1).extend p.2) ∘ Prod.map id (fun x => 2*x : I → ℝ))
      exact h₁'.comp (continuous_id.prod_map$ continuous_const.mul continuous_subtype_coe)
    ·
      change Continuous ((fun p : ι × ℝ => (γ₂ p.1).extend p.2) ∘ Prod.map id (fun x => (2*x) - 1 : I → ℝ))
      exact h₂'.comp (continuous_id.prod_map$ (continuous_const.mul continuous_subtype_coe).sub continuous_const)
    ·
      rintro st hst 
      simp [hst, mul_inv_cancel (@two_ne_zero ℝ _ _)]

/-! #### Product of two paths -/


/-- Given a path in `X` and a path in `Y`, we can take their pointwise product to get a path in
`X × Y`. -/
protected def Prod {a₁ b₁ : X} {a₂ b₂ : Y} (γ₁ : Path a₁ b₁) (γ₂ : Path a₂ b₂) : Path (a₁, a₂) (b₁, b₂) :=
  { toContinuousMap := ContinuousMap.prodMk γ₁.to_continuous_map γ₂.to_continuous_map,
    source' :=
      by 
        dsimp [ContinuousMap.prodMk] <;> rwa [γ₁.source, γ₂.source],
    target' :=
      by 
        dsimp [ContinuousMap.prodMk] <;> rwa [γ₁.target, γ₂.target] }

/-! #### Pointwise multiplication/addition of two paths in a topological (additive) group -/


/-- Pointwise multiplication of paths in a topological group. The additive version is probably more
useful. -/
@[toAdditive "Pointwise addition of paths in a topological additive group. -/"]
protected def mul [Mul X] [HasContinuousMul X] {a₁ b₁ a₂ b₂ : X} (γ₁ : Path a₁ b₁) (γ₂ : Path a₂ b₂) :
  Path (a₁*a₂) (b₁*b₂) :=
  (γ₁.prod γ₂).map continuous_mul

@[toAdditive]
protected theorem mul_apply [Mul X] [HasContinuousMul X] {a₁ b₁ a₂ b₂ : X} (γ₁ : Path a₁ b₁) (γ₂ : Path a₂ b₂)
  (t : UnitInterval) : (γ₁.mul γ₂) t = γ₁ t*γ₂ t :=
  rfl

/-! #### Truncating a path -/


/-- `γ.truncate t₀ t₁` is the path which follows the path `γ` on the
  time interval `[t₀, t₁]` and stays still otherwise. -/
def truncate {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) (t₀ t₁ : ℝ) :
  Path (γ.extend$ min t₀ t₁) (γ.extend t₁) :=
  { toFun := fun s => γ.extend (min (max s t₀) t₁),
    continuous_to_fun := γ.continuous_extend.comp ((continuous_subtype_coe.max continuous_const).min continuous_const),
    source' :=
      by 
        simp only [min_def, max_def]
        normCast 
        splitIfs with h₁ h₂ h₃ h₄
        ·
          simp [γ.extend_of_le_zero h₁]
        ·
          congr 
          linarith
        ·
          have h₄ : t₁ ≤ 0 :=
            le_of_ltₓ
              (by 
                simpa using h₂)
          simp [γ.extend_of_le_zero h₄, γ.extend_of_le_zero h₁]
        all_goals 
          rfl,
    target' :=
      by 
        simp only [min_def, max_def]
        normCast 
        splitIfs with h₁ h₂ h₃
        ·
          simp [γ.extend_of_one_le h₂]
        ·
          rfl
        ·
          have h₄ : 1 ≤ t₀ :=
            le_of_ltₓ
              (by 
                simpa using h₁)
          simp [γ.extend_of_one_le h₄, γ.extend_of_one_le (h₄.trans h₃)]
        ·
          rfl }

/-- `γ.truncate_of_le t₀ t₁ h`, where `h : t₀ ≤ t₁` is `γ.truncate t₀ t₁`
  casted as a path from `γ.extend t₀` to `γ.extend t₁`. -/
def truncate_of_le {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) {t₀ t₁ : ℝ} (h : t₀ ≤ t₁) :
  Path (γ.extend t₀) (γ.extend t₁) :=
  (γ.truncate t₀ t₁).cast
    (by 
      rw [min_eq_leftₓ h])
    rfl

theorem truncate_range {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) {t₀ t₁ : ℝ} :
  range (γ.truncate t₀ t₁) ⊆ range γ :=
  by 
    rw [←γ.extend_range]
    simp only [range_subset_iff, SetCoe.exists, SetCoe.forall]
    intro x hx 
    simp only [CoeFun.coe, coeFn, Path.truncate, mem_range_self]

/-- For a path `γ`, `γ.truncate` gives a "continuous family of paths", by which we
  mean the uncurried function which maps `(t₀, t₁, s)` to `γ.truncate t₀ t₁ s` is continuous. -/
@[continuity]
theorem truncate_continuous_family {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) :
  Continuous (fun x => γ.truncate x.1 x.2.1 x.2.2 : ℝ × ℝ × I → X) :=
  γ.continuous_extend.comp
    (((continuous_subtype_coe.comp (continuous_snd.comp continuous_snd)).max continuous_fst).min
      (continuous_fst.comp continuous_snd))

@[continuity]
theorem truncate_const_continuous_family {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) (t : ℝ) :
  Continuous (↿γ.truncate t) :=
  have key : Continuous (fun x => (t, x) : ℝ × I → ℝ × ℝ × I) := continuous_const.prod_mk continuous_id 
  by 
    convert γ.truncate_continuous_family.comp key

@[simp]
theorem truncate_self {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) (t : ℝ) :
  γ.truncate t t =
    (Path.refl$ γ.extend t).cast
      (by 
        rw [min_selfₓ])
      rfl :=
  by 
    ext x 
    rw [cast_coe]
    simp only [truncate, CoeFun.coe, coeFn, refl, min_def, max_def]
    splitIfs with h₁ h₂ <;> congr 
    exact le_antisymmₓ ‹_› ‹_›

@[simp]
theorem truncate_zero_zero {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) :
  γ.truncate 0 0 =
    (Path.refl a).cast
      (by 
        rw [min_selfₓ, γ.extend_zero])
      γ.extend_zero :=
  by 
    convert γ.truncate_self 0 <;> exact γ.extend_zero.symm

@[simp]
theorem truncate_one_one {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) :
  γ.truncate 1 1 =
    (Path.refl b).cast
      (by 
        rw [min_selfₓ, γ.extend_one])
      γ.extend_one :=
  by 
    convert γ.truncate_self 1 <;> exact γ.extend_one.symm

@[simp]
theorem truncate_zero_one {X : Type _} [TopologicalSpace X] {a b : X} (γ : Path a b) :
  γ.truncate 0 1 =
    γ.cast
      (by 
        simp [zero_le_one, extend_zero])
      (by 
        simp ) :=
  by 
    ext x 
    rw [cast_coe]
    have  : ↑x ∈ (Icc 0 1 : Set ℝ) := x.2
    rw [truncate, coe_mk, max_eq_leftₓ this.1, min_eq_leftₓ this.2, extend_extends']

/-! #### Reparametrising a path -/


/--
Given a path `γ` and a function `f : I → I` where `f 0 = 0` and `f 1 = 1`, `γ.reparam f` is the
path defined by `γ ∘ f`.
-/
def reparam (γ : Path x y) (f : I → I) (hfcont : Continuous f) (hf₀ : f 0 = 0) (hf₁ : f 1 = 1) : Path x y :=
  { toFun := γ ∘ f,
    continuous_to_fun :=
      by 
        continuity,
    source' :=
      by 
        simp [hf₀],
    target' :=
      by 
        simp [hf₁] }

@[simp]
theorem coe_to_fun (γ : Path x y) {f : I → I} (hfcont : Continuous f) (hf₀ : f 0 = 0) (hf₁ : f 1 = 1) :
  ⇑γ.reparam f hfcont hf₀ hf₁ = (γ ∘ f) :=
  rfl

@[simp]
theorem reparam_id (γ : Path x y) : γ.reparam id continuous_id rfl rfl = γ :=
  by 
    ext 
    rfl

theorem range_reparam (γ : Path x y) {f : I → I} (hfcont : Continuous f) (hf₀ : f 0 = 0) (hf₁ : f 1 = 1) :
  range (⇑γ.reparam f hfcont hf₀ hf₁) = range γ :=
  by 
    change range (γ ∘ f) = range γ 
    have  : range f = univ
    ·
      rw [range_iff_surjective]
      intro t 
      have h₁ : Continuous (Icc_extend (@zero_le_one ℝ _) f)
      ·
        continuity 
      have  := intermediate_value_Icc (@zero_le_one ℝ _) h₁.continuous_on
      ·
        rw [Icc_extend_left, Icc_extend_right] at this 
        change Icc (f 0) (f 1) ⊆ _ at this 
        rw [hf₀, hf₁] at this 
        rcases this t.2 with ⟨w, hw₁, hw₂⟩
        rw [Icc_extend_of_mem _ _ hw₁] at hw₂ 
        use ⟨w, hw₁⟩, hw₂ 
    rw [range_comp, this, image_univ]

theorem refl_reparam {f : I → I} (hfcont : Continuous f) (hf₀ : f 0 = 0) (hf₁ : f 1 = 1) :
  (refl x).reparam f hfcont hf₀ hf₁ = refl x :=
  by 
    ext 
    simp 

end Path

/-! ### Being joined by a path -/


/-- The relation "being joined by a path". This is an equivalence relation. -/
def Joined (x y : X) : Prop :=
  Nonempty (Path x y)

@[refl]
theorem Joined.refl (x : X) : Joined x x :=
  ⟨Path.refl x⟩

/-- When two points are joined, choose some path from `x` to `y`. -/
def Joined.somePath (h : Joined x y) : Path x y :=
  Nonempty.some h

@[symm]
theorem Joined.symm {x y : X} (h : Joined x y) : Joined y x :=
  ⟨h.some_path.symm⟩

@[trans]
theorem Joined.trans {x y z : X} (hxy : Joined x y) (hyz : Joined y z) : Joined x z :=
  ⟨hxy.some_path.trans hyz.some_path⟩

variable (X)

/-- The setoid corresponding the equivalence relation of being joined by a continuous path. -/
def pathSetoid : Setoidₓ X :=
  { R := Joined, iseqv := mk_equivalence _ Joined.refl (fun x y => Joined.symm) fun x y z => Joined.trans }

/-- The quotient type of points of a topological space modulo being joined by a continuous path. -/
def ZerothHomotopy :=
  Quotientₓ (pathSetoid X)

instance : Inhabited (ZerothHomotopy ℝ) :=
  ⟨@Quotientₓ.mk ℝ (pathSetoid ℝ) 0⟩

variable {X}

/-! ### Being joined by a path inside a set -/


/-- The relation "being joined by a path in `F`". Not quite an equivalence relation since it's not
reflexive for points that do not belong to `F`. -/
def JoinedIn (F : Set X) (x y : X) : Prop :=
  ∃ γ : Path x y, ∀ t, γ t ∈ F

variable {F : Set X}

theorem JoinedIn.mem (h : JoinedIn F x y) : x ∈ F ∧ y ∈ F :=
  by 
    rcases h with ⟨γ, γ_in⟩
    have  : γ 0 ∈ F ∧ γ 1 ∈ F
    ·
      ·
        constructor <;> apply γ_in 
    simpa using this

theorem JoinedIn.source_mem (h : JoinedIn F x y) : x ∈ F :=
  h.mem.1

theorem JoinedIn.target_mem (h : JoinedIn F x y) : y ∈ F :=
  h.mem.2

/-- When `x` and `y` are joined in `F`, choose a path from `x` to `y` inside `F` -/
def JoinedIn.somePath (h : JoinedIn F x y) : Path x y :=
  Classical.some h

theorem JoinedIn.some_path_mem (h : JoinedIn F x y) (t : I) : h.some_path t ∈ F :=
  Classical.some_spec h t

/-- If `x` and `y` are joined in the set `F`, then they are joined in the subtype `F`. -/
theorem JoinedIn.joined_subtype (h : JoinedIn F x y) : Joined (⟨x, h.source_mem⟩ : F) (⟨y, h.target_mem⟩ : F) :=
  ⟨{ toFun := fun t => ⟨h.some_path t, h.some_path_mem t⟩,
      continuous_to_fun :=
        by 
          continuity,
      source' :=
        by 
          simp ,
      target' :=
        by 
          simp  }⟩

theorem JoinedIn.of_line {f : ℝ → X} (hf : ContinuousOn f I) (h₀ : f 0 = x) (h₁ : f 1 = y) (hF : f '' I ⊆ F) :
  JoinedIn F x y :=
  ⟨Path.ofLine hf h₀ h₁, fun t => hF$ Path.of_line_mem hf h₀ h₁ t⟩

theorem JoinedIn.joined (h : JoinedIn F x y) : Joined x y :=
  ⟨h.some_path⟩

theorem joined_in_iff_joined (x_in : x ∈ F) (y_in : y ∈ F) : JoinedIn F x y ↔ Joined (⟨x, x_in⟩ : F) (⟨y, y_in⟩ : F) :=
  ⟨fun h => h.joined_subtype,
    fun h =>
      ⟨h.some_path.map continuous_subtype_coe,
        by 
          simp ⟩⟩

@[simp]
theorem joined_in_univ : JoinedIn univ x y ↔ Joined x y :=
  by 
    simp [JoinedIn, Joined, exists_true_iff_nonempty]

theorem JoinedIn.mono {U V : Set X} (h : JoinedIn U x y) (hUV : U ⊆ V) : JoinedIn V x y :=
  ⟨h.some_path, fun t => hUV (h.some_path_mem t)⟩

theorem JoinedIn.refl (h : x ∈ F) : JoinedIn F x x :=
  ⟨Path.refl x, fun t => h⟩

@[symm]
theorem JoinedIn.symm (h : JoinedIn F x y) : JoinedIn F y x :=
  by 
    cases' h.mem with hx hy 
    simp_all [joined_in_iff_joined]
    exact h.symm

theorem JoinedIn.trans (hxy : JoinedIn F x y) (hyz : JoinedIn F y z) : JoinedIn F x z :=
  by 
    cases' hxy.mem with hx hy 
    cases' hyz.mem with hx hy 
    simp_all [joined_in_iff_joined]
    exact hxy.trans hyz

/-! ### Path component -/


-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The path component of `x` is the set of points that can be joined to `x`. -/
  def PathComponent ( x : X ) := { y | Joined x y }

@[simp]
theorem mem_path_component_self (x : X) : x ∈ PathComponent x :=
  Joined.refl x

@[simp]
theorem PathComponent.nonempty (x : X) : (PathComponent x).Nonempty :=
  ⟨x, mem_path_component_self x⟩

theorem mem_path_component_of_mem (h : x ∈ PathComponent y) : y ∈ PathComponent x :=
  Joined.symm h

theorem path_component_symm : x ∈ PathComponent y ↔ y ∈ PathComponent x :=
  ⟨fun h => mem_path_component_of_mem h, fun h => mem_path_component_of_mem h⟩

theorem path_component_congr (h : x ∈ PathComponent y) : PathComponent x = PathComponent y :=
  by 
    ext z 
    constructor
    ·
      intro h' 
      rw [path_component_symm]
      exact (h.trans h').symm
    ·
      intro h' 
      rw [path_component_symm] at h'⊢
      exact h'.trans h

theorem path_component_subset_component (x : X) : PathComponent x ⊆ ConnectedComponent x :=
  fun y h =>
    (is_connected_range h.some_path.continuous).subset_connected_component
      ⟨0,
        by 
          simp ⟩
      ⟨1,
        by 
          simp ⟩

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The path component of `x` in `F` is the set of points that can be joined to `x` in `F`. -/
  def PathComponentIn ( x : X ) ( F : Set X ) := { y | JoinedIn F x y }

@[simp]
theorem path_component_in_univ (x : X) : PathComponentIn x univ = PathComponent x :=
  by 
    simp [PathComponentIn, PathComponent, JoinedIn, Joined, exists_true_iff_nonempty]

theorem Joined.mem_path_component (hyz : Joined y z) (hxy : y ∈ PathComponent x) : z ∈ PathComponent x :=
  hxy.trans hyz

/-! ### Path connected sets -/


-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » F)
/-- A set `F` is path connected if it contains a point that can be joined to all other in `F`. -/
def IsPathConnected (F : Set X) : Prop :=
  ∃ (x : _)(_ : x ∈ F), ∀ {y}, y ∈ F → JoinedIn F x y

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » F)
theorem is_path_connected_iff_eq : IsPathConnected F ↔ ∃ (x : _)(_ : x ∈ F), PathComponentIn x F = F :=
  by 
    constructor <;> rintro ⟨x, x_in, h⟩ <;> use x, x_in
    ·
      ext y 
      exact ⟨fun hy => hy.mem.2, h⟩
    ·
      intro y y_in 
      rwa [←h] at y_in

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x y «expr ∈ » F)
theorem IsPathConnected.joined_in (h : IsPathConnected F) : ∀ x y _ : x ∈ F _ : y ∈ F, JoinedIn F x y :=
  fun x y x_in y_in =>
    let ⟨b, b_in, hb⟩ := h
    (hb x_in).symm.trans (hb y_in)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x y «expr ∈ » F)
theorem is_path_connected_iff : IsPathConnected F ↔ F.nonempty ∧ ∀ x y _ : x ∈ F _ : y ∈ F, JoinedIn F x y :=
  ⟨fun h =>
      ⟨let ⟨b, b_in, hb⟩ := h
        ⟨b, b_in⟩,
        h.joined_in⟩,
    fun ⟨⟨b, b_in⟩, h⟩ => ⟨b, b_in, fun x x_in => h b x b_in x_in⟩⟩

theorem IsPathConnected.image {Y : Type _} [TopologicalSpace Y] (hF : IsPathConnected F) {f : X → Y}
  (hf : Continuous f) : IsPathConnected (f '' F) :=
  by 
    rcases hF with ⟨x, x_in, hx⟩
    use f x, mem_image_of_mem f x_in 
    rintro _ ⟨y, y_in, rfl⟩
    exact ⟨(hx y_in).somePath.map hf, fun t => ⟨_, (hx y_in).some_path_mem t, rfl⟩⟩

theorem IsPathConnected.mem_path_component (h : IsPathConnected F) (x_in : x ∈ F) (y_in : y ∈ F) :
  y ∈ PathComponent x :=
  (h.joined_in x y x_in y_in).Joined

theorem IsPathConnected.subset_path_component (h : IsPathConnected F) (x_in : x ∈ F) : F ⊆ PathComponent x :=
  fun y y_in => h.mem_path_component x_in y_in

theorem IsPathConnected.union {U V : Set X} (hU : IsPathConnected U) (hV : IsPathConnected V) (hUV : (U ∩ V).Nonempty) :
  IsPathConnected (U ∪ V) :=
  by 
    rcases hUV with ⟨x, xU, xV⟩
    use x, Or.inl xU 
    rintro y (yU | yV)
    ·
      exact (hU.joined_in x y xU yU).mono (subset_union_left U V)
    ·
      exact (hV.joined_in x y xV yV).mono (subset_union_right U V)

/-- If a set `W` is path-connected, then it is also path-connected when seen as a set in a smaller
ambient type `U` (when `U` contains `W`). -/
theorem IsPathConnected.preimage_coe {U W : Set X} (hW : IsPathConnected W) (hWU : W ⊆ U) :
  IsPathConnected ((coeₓ : U → X) ⁻¹' W) :=
  by 
    rcases hW with ⟨x, x_in, hx⟩
    use ⟨x, hWU x_in⟩,
      by 
        simp [x_in]
    rintro ⟨y, hyU⟩ hyW 
    exact
      ⟨(hx hyW).joined_subtype.somePath.map (continuous_inclusion hWU),
        by 
          simp ⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ≤ » n)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ≤ » n)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
theorem IsPathConnected.exists_path_through_family {X : Type _} [TopologicalSpace X] {n : ℕ} {s : Set X}
  (h : IsPathConnected s) (p : Finₓ (n+1) → X) (hp : ∀ i, p i ∈ s) :
  ∃ γ : Path (p 0) (p n), range γ ⊆ s ∧ ∀ i, p i ∈ range γ :=
  by 
    let p' : ℕ → X := fun k => if h : k < n+1 then p ⟨k, h⟩ else p ⟨0, n.zero_lt_succ⟩
    obtain ⟨γ, hγ⟩ : ∃ γ : Path (p' 0) (p' n), (∀ i _ : i ≤ n, p' i ∈ range γ) ∧ range γ ⊆ s
    ·
      have hp' : ∀ i _ : i ≤ n, p' i ∈ s
      ·
        intro i hi 
        simp [p', Nat.lt_succ_of_leₓ hi, hp]
      clearValue p' 
      clear hp p 
      induction' n with n hn
      ·
        use Path.refl (p' 0)
        ·
          constructor
          ·
            rintro i hi 
            rw [nat.le_zero_iff.mp hi]
            exact ⟨0, rfl⟩
          ·
            rw [range_subset_iff]
            rintro x 
            exact hp' 0 (le_reflₓ _)
      ·
        rcases hn fun i hi => hp' i$ Nat.le_succ_of_leₓ hi with ⟨γ₀, hγ₀⟩
        rcases h.joined_in (p' n) (p'$ n+1) (hp' n n.le_succ) (hp' (n+1)$ le_reflₓ _) with ⟨γ₁, hγ₁⟩
        let γ : Path (p' 0) (p'$ n+1) := γ₀.trans γ₁ 
        use γ 
        have range_eq : range γ = range γ₀ ∪ range γ₁ := γ₀.trans_range γ₁ 
        constructor
        ·
          rintro i hi 
          byCases' hi' : i ≤ n
          ·
            rw [range_eq]
            left 
            exact hγ₀.1 i hi'
          ·
            rw [not_leₓ, ←Nat.succ_le_iff] at hi' 
            have  : i = n.succ :=
              by 
                linarith 
            rw [this]
            use 1 
            exact γ.target
        ·
          rw [range_eq]
          apply union_subset hγ₀.2
          rw [range_subset_iff]
          exact hγ₁ 
    have hpp' : ∀ k _ : k < n+1, p k = p' k
    ·
      intro k hk 
      simp only [p', hk, dif_pos]
      congr 
      ext 
      rw [Finₓ.coe_coe_of_lt hk]
      normCast 
    use γ.cast (hpp' 0 n.zero_lt_succ) (hpp' n n.lt_succ_self)
    simp only [γ.cast_coe]
    refine' And.intro hγ.2 _ 
    rintro ⟨i, hi⟩
    convert hγ.1 i (Nat.le_of_lt_succₓ hi)
    rw [←hpp' i hi]
    congr 
    ext 
    rw [Finₓ.coe_coe_of_lt hi]
    normCast

theorem IsPathConnected.exists_path_through_family' {X : Type _} [TopologicalSpace X] {n : ℕ} {s : Set X}
  (h : IsPathConnected s) (p : Finₓ (n+1) → X) (hp : ∀ i, p i ∈ s) :
  ∃ (γ : Path (p 0) (p n))(t : Finₓ (n+1) → I), (∀ t, γ t ∈ s) ∧ ∀ i, γ (t i) = p i :=
  by 
    rcases h.exists_path_through_family p hp with ⟨γ, hγ⟩
    rcases hγ with ⟨h₁, h₂⟩
    simp only [range, mem_set_of_eq] at h₂ 
    rw [range_subset_iff] at h₁ 
    choose! t ht using h₂ 
    exact ⟨γ, t, h₁, ht⟩

/-! ### Path connected spaces -/


/-- A topological space is path-connected if it is non-empty and every two points can be
joined by a continuous path. -/
class PathConnectedSpace (X : Type _) [TopologicalSpace X] : Prop where 
  Nonempty : Nonempty X 
  Joined : ∀ x y : X, Joined x y

attribute [instance] PathConnectedSpace.nonempty

theorem path_connected_space_iff_zeroth_homotopy :
  PathConnectedSpace X ↔ Nonempty (ZerothHomotopy X) ∧ Subsingleton (ZerothHomotopy X) :=
  by 
    let this' := pathSetoid X 
    constructor
    ·
      intro h 
      refine' ⟨(nonempty_quotient_iff _).mpr h.1, ⟨_⟩⟩
      rintro ⟨x⟩ ⟨y⟩
      exact Quotientₓ.sound (PathConnectedSpace.joined x y)
    ·
      unfold ZerothHomotopy 
      rintro ⟨h, h'⟩
      skip 
      exact ⟨(nonempty_quotient_iff _).mp h, fun x y => Quotientₓ.exact$ Subsingleton.elimₓ (⟦x⟧) (⟦y⟧)⟩

namespace PathConnectedSpace

variable [PathConnectedSpace X]

/-- Use path-connectedness to build a path between two points. -/
def some_path (x y : X) : Path x y :=
  Nonempty.some (Joined x y)

end PathConnectedSpace

theorem is_path_connected_iff_path_connected_space : IsPathConnected F ↔ PathConnectedSpace F :=
  by 
    rw [is_path_connected_iff]
    constructor
    ·
      rintro ⟨⟨x, x_in⟩, h⟩
      refine' ⟨⟨⟨x, x_in⟩⟩, _⟩
      rintro ⟨y, y_in⟩ ⟨z, z_in⟩
      have H := h y z y_in z_in 
      rwa [joined_in_iff_joined y_in z_in] at H
    ·
      rintro ⟨⟨x, x_in⟩, H⟩
      refine' ⟨⟨x, x_in⟩, fun y z y_in z_in => _⟩
      rw [joined_in_iff_joined y_in z_in]
      apply H

theorem path_connected_space_iff_univ : PathConnectedSpace X ↔ IsPathConnected (univ : Set X) :=
  by 
    constructor
    ·
      intro h 
      inhabit X 
      refine' ⟨default X, mem_univ _, _⟩
      simpa using PathConnectedSpace.joined (default X)
    ·
      intro h 
      have h' := h.joined_in 
      cases' h with x h 
      exact
        ⟨⟨x⟩,
          by 
            simpa using h'⟩

theorem path_connected_space_iff_eq : PathConnectedSpace X ↔ ∃ x : X, PathComponent x = univ :=
  by 
    simp [path_connected_space_iff_univ, is_path_connected_iff_eq]

instance (priority := 100) PathConnectedSpace.connected_space [PathConnectedSpace X] : ConnectedSpace X :=
  by 
    rw [connected_space_iff_connected_component]
    rcases is_path_connected_iff_eq.mp (path_connected_space_iff_univ.mp ‹_›) with ⟨x, x_in, hx⟩
    use x 
    rw [←univ_subset_iff]
    exact
      (by 
          simpa using hx :
        PathComponent x = univ) ▸
        path_component_subset_component x

namespace PathConnectedSpace

variable [PathConnectedSpace X]

theorem exists_path_through_family {n : ℕ} (p : Finₓ (n+1) → X) : ∃ γ : Path (p 0) (p n), ∀ i, p i ∈ range γ :=
  by 
    have  : IsPathConnected (univ : Set X) :=
      path_connected_space_iff_univ.mp
        (by 
          infer_instance)
    rcases this.exists_path_through_family p fun i => True.intro with ⟨γ, -, h⟩
    exact ⟨γ, h⟩

theorem exists_path_through_family' {n : ℕ} (p : Finₓ (n+1) → X) :
  ∃ (γ : Path (p 0) (p n))(t : Finₓ (n+1) → I), ∀ i, γ (t i) = p i :=
  by 
    have  : IsPathConnected (univ : Set X) :=
      path_connected_space_iff_univ.mp
        (by 
          infer_instance)
    rcases this.exists_path_through_family' p fun i => True.intro with ⟨γ, t, -, h⟩
    exact ⟨γ, t, h⟩

end PathConnectedSpace

/-! ### Locally path connected spaces -/


/-- A topological space is locally path connected, at every point, path connected
neighborhoods form a neighborhood basis. -/
class LocPathConnectedSpace (X : Type _) [TopologicalSpace X] : Prop where 
  path_connected_basis : ∀ x : X, (𝓝 x).HasBasis (fun s : Set X => s ∈ 𝓝 x ∧ IsPathConnected s) id

export LocPathConnectedSpace(path_connected_basis)

theorem loc_path_connected_of_bases {p : ι → Prop} {s : X → ι → Set X} (h : ∀ x, (𝓝 x).HasBasis p (s x))
  (h' : ∀ x i, p i → IsPathConnected (s x i)) : LocPathConnectedSpace X :=
  by 
    constructor 
    intro x 
    apply (h x).to_has_basis
    ·
      intro i pi 
      exact
        ⟨s x i, ⟨(h x).mem_of_mem pi, h' x i pi⟩,
          by 
            rfl⟩
    ·
      rintro U ⟨U_in, hU⟩
      rcases(h x).mem_iff.mp U_in with ⟨i, pi, hi⟩
      tauto

theorem path_connected_space_iff_connected_space [LocPathConnectedSpace X] : PathConnectedSpace X ↔ ConnectedSpace X :=
  by 
    constructor
    ·
      intro h 
      infer_instance
    ·
      intro hX 
      inhabit X 
      let x₀ := default X 
      rw [path_connected_space_iff_eq]
      use x₀ 
      refine'
        eq_univ_of_nonempty_clopen
          (by 
            simp )
          ⟨_, _⟩
      ·
        rw [is_open_iff_mem_nhds]
        intro y y_in 
        rcases(path_connected_basis y).ex_mem with ⟨U, ⟨U_in, hU⟩⟩
        apply mem_of_superset U_in 
        rw [←path_component_congr y_in]
        exact hU.subset_path_component (mem_of_mem_nhds U_in)
      ·
        rw [is_closed_iff_nhds]
        intro y H 
        rcases(path_connected_basis y).ex_mem with ⟨U, ⟨U_in, hU⟩⟩
        rcases H U U_in with ⟨z, hz, hz'⟩
        exact (hU.joined_in z y hz$ mem_of_mem_nhds U_in).Joined.mem_path_component hz'

theorem path_connected_subset_basis [LocPathConnectedSpace X] {U : Set X} (h : IsOpen U) (hx : x ∈ U) :
  (𝓝 x).HasBasis (fun s : Set X => s ∈ 𝓝 x ∧ IsPathConnected s ∧ s ⊆ U) id :=
  (path_connected_basis x).has_basis_self_subset (IsOpen.mem_nhds h hx)

theorem loc_path_connected_of_is_open [LocPathConnectedSpace X] {U : Set X} (h : IsOpen U) : LocPathConnectedSpace U :=
  ⟨by 
      rintro ⟨x, x_in⟩
      rw [nhds_subtype_eq_comap]
      constructor 
      intro V 
      rw [(has_basis.comap (coeₓ : U → X) (path_connected_subset_basis h x_in)).mem_iff]
      constructor
      ·
        rintro ⟨W, ⟨W_in, hW, hWU⟩, hWV⟩
        exact ⟨coeₓ ⁻¹' W, ⟨⟨preimage_mem_comap W_in, hW.preimage_coe hWU⟩, hWV⟩⟩
      ·
        rintro ⟨W, ⟨W_in, hW⟩, hWV⟩
        refine'
          ⟨coeₓ '' W,
            ⟨Filter.image_coe_mem_of_mem_comap (IsOpen.mem_nhds h x_in) W_in, hW.image continuous_subtype_coe,
              Subtype.coe_image_subset U W⟩,
            _⟩
        rintro x ⟨y, ⟨y_in, hy⟩⟩
        rw [←Subtype.coe_injective hy]
        tauto⟩

theorem IsOpen.is_connected_iff_is_path_connected [LocPathConnectedSpace X] {U : Set X} (U_op : IsOpen U) :
  IsPathConnected U ↔ IsConnected U :=
  by 
    rw [is_connected_iff_connected_space, is_path_connected_iff_path_connected_space]
    have  := loc_path_connected_of_is_open U_op 
    exact path_connected_space_iff_connected_space

