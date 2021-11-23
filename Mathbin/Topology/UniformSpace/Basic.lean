import Mathbin.Order.Filter.Lift 
import Mathbin.Topology.SubsetProperties

/-!
# Uniform spaces

Uniform spaces are a generalization of metric spaces and topological groups. Many concepts directly
generalize to uniform spaces, e.g.

* uniform continuity (in this file)
* completeness (in `cauchy.lean`)
* extension of uniform continuous functions to complete spaces (in `uniform_embedding.lean`)
* totally bounded sets (in `cauchy.lean`)
* totally bounded complete sets are compact (in `cauchy.lean`)

A uniform structure on a type `X` is a filter `𝓤 X` on `X × X` satisfying some conditions
which makes it reasonable to say that `∀ᶠ (p : X × X) in 𝓤 X, ...` means
"for all p.1 and p.2 in X close enough, ...". Elements of this filter are called entourages
of `X`. The two main examples are:

* If `X` is a metric space, `V ∈ 𝓤 X ↔ ∃ ε > 0, { p | dist p.1 p.2 < ε } ⊆ V`
* If `G` is an additive topological group, `V ∈ 𝓤 G ↔ ∃ U ∈ 𝓝 (0 : G), {p | p.2 - p.1 ∈ U} ⊆ V`

Those examples are generalizations in two different directions of the elementary example where
`X = ℝ` and `V ∈ 𝓤 ℝ ↔ ∃ ε > 0, { p | |p.2 - p.1| < ε } ⊆ V` which features both the topological
group structure on `ℝ` and its metric space structure.

Each uniform structure on `X` induces a topology on `X` characterized by

> `nhds_eq_comap_uniformity : ∀ {x : X}, 𝓝 x = comap (prod.mk x) (𝓤 X)`

where `prod.mk x : X → X × X := (λ y, (x, y))` is the partial evaluation of the product
constructor.

The dictionary with metric spaces includes:
* an upper bound for `dist x y` translates into `(x, y) ∈ V` for some `V ∈ 𝓤 X`
* a ball `ball x r` roughly corresponds to `uniform_space.ball x V := {y | (x, y) ∈ V}`
  for some `V ∈ 𝓤 X`, but the later is more general (it includes in
  particular both open and closed balls for suitable `V`).
  In particular we have:
  `is_open_iff_ball_subset {s : set X} : is_open s ↔ ∀ x ∈ s, ∃ V ∈ 𝓤 X, ball x V ⊆ s`

The triangle inequality is abstracted to a statement involving the composition of relations in `X`.
First note that the triangle inequality in a metric space is equivalent to
`∀ (x y z : X) (r r' : ℝ), dist x y ≤ r → dist y z ≤ r' → dist x z ≤ r + r'`.
Then, for any `V` and `W` with type `set (X × X)`, the composition `V ○ W : set (X × X)` is
defined as `{ p : X × X | ∃ z, (p.1, z) ∈ V ∧ (z, p.2) ∈ W }`.
In the metric space case, if `V = { p | dist p.1 p.2 ≤ r }` and `W = { p | dist p.1 p.2 ≤ r' }`
then the triangle inequality, as reformulated above, says `V ○ W` is contained in
`{p | dist p.1 p.2 ≤ r + r'}` which is the entourage associated to the radius `r + r'`.
In general we have `mem_ball_comp (h : y ∈ ball x V) (h' : z ∈ ball y W) : z ∈ ball x (V ○ W)`.
Note that this discussion does not depend on any axiom imposed on the uniformity filter,
it is simply captured by the definition of composition.

The uniform space axioms ask the filter `𝓤 X` to satisfy the following:
* every `V ∈ 𝓤 X` contains the diagonal `id_rel = { p | p.1 = p.2 }`. This abstracts the fact
  that `dist x x ≤ r` for every non-negative radius `r` in the metric space case and also that
  `x - x` belongs to every neighborhood of zero in the topological group case.
* `V ∈ 𝓤 X → prod.swap '' V ∈ 𝓤 X`. This is tightly related the fact that `dist x y = dist y x`
  in a metric space, and to continuity of negation in the topological group case.
* `∀ V ∈ 𝓤 X, ∃ W ∈ 𝓤 X, W ○ W ⊆ V`. In the metric space case, it corresponds
  to cutting the radius of a ball in half and applying the triangle inequality.
  In the topological group case, it comes from continuity of addition at `(0, 0)`.

These three axioms are stated more abstractly in the definition below, in terms of
operations on filters, without directly manipulating entourages.

## Main definitions

* `uniform_space X` is a uniform space structure on a type `X`
* `uniform_continuous f` is a predicate saying a function `f : α → β` between uniform spaces
  is uniformly continuous : `∀ r ∈ 𝓤 β, ∀ᶠ (x : α × α) in 𝓤 α, (f x.1, f x.2) ∈ r`

In this file we also define a complete lattice structure on the type `uniform_space X`
of uniform structures on `X`, as well as the pullback (`uniform_space.comap`) of uniform structures
coming from the pullback of filters.
Like distance functions, uniform structures cannot be pushed forward in general.

## Notations

Localized in `uniformity`, we have the notation `𝓤 X` for the uniformity on a uniform space `X`,
and `○` for composition of relations, seen as terms with type `set (X × X)`.

## Implementation notes

There is already a theory of relations in `data/rel.lean` where the main definition is
`def rel (α β : Type*) := α → β → Prop`.
The relations used in the current file involve only one type, but this is not the reason why
we don't reuse `data/rel.lean`. We use `set (α × α)`
instead of `rel α α` because we really need sets to use the filter library, and elements
of filters on `α × α` have type `set (α × α)`.

The structure `uniform_space X` bundles a uniform structure on `X`, a topology on `X` and
an assumption saying those are compatible. This may not seem mathematically reasonable at first,
but is in fact an instance of the forgetful inheritance pattern. See Note [forgetful inheritance]
below.

## References

The formalization uses the books:

* [N. Bourbaki, *General Topology*][bourbaki1966]
* [I. M. James, *Topologies and Uniformities*][james1999]

But it makes a more systematic use of the filter library.
-/


open Set Filter Classical

open_locale Classical TopologicalSpace Filter

set_option eqn_compiler.zeta true

universe u

/-!
### Relations, seen as `set (α × α)`
-/


variable{α : Type _}{β : Type _}{γ : Type _}{δ : Type _}{ι : Sort _}

/-- The identity relation, or the graph of the identity function -/
def IdRel {α : Type _} :=
  { p:α × α | p.1 = p.2 }

@[simp]
theorem mem_id_rel {a b : α} : (a, b) ∈ @IdRel α ↔ a = b :=
  Iff.rfl

@[simp]
theorem id_rel_subset {s : Set (α × α)} : IdRel ⊆ s ↔ ∀ a, (a, a) ∈ s :=
  by 
    simp [subset_def] <;>
      exact
        forall_congrₓ
          fun a =>
            by 
              simp 

/-- The composition of relations -/
def CompRel {α : Type u} (r₁ r₂ : Set (α × α)) :=
  { p:α × α | ∃ z : α, (p.1, z) ∈ r₁ ∧ (z, p.2) ∈ r₂ }

localized [uniformity] infixl:55 " ○ " => CompRel

@[simp]
theorem mem_comp_rel {r₁ r₂ : Set (α × α)} {x y : α} : (x, y) ∈ r₁ ○ r₂ ↔ ∃ z, (x, z) ∈ r₁ ∧ (z, y) ∈ r₂ :=
  Iff.rfl

@[simp]
theorem swap_id_rel : Prod.swap '' IdRel = @IdRel α :=
  Set.ext$
    fun ⟨a, b⟩ =>
      by 
        simp [image_swap_eq_preimage_swap] <;> exact eq_comm

theorem monotone_comp_rel [Preorderₓ β] {f g : β → Set (α × α)} (hf : Monotone f) (hg : Monotone g) :
  Monotone fun x => f x ○ g x :=
  fun a b h p ⟨z, h₁, h₂⟩ => ⟨z, hf h h₁, hg h h₂⟩

@[mono]
theorem comp_rel_mono {f g h k : Set (α × α)} (h₁ : f ⊆ h) (h₂ : g ⊆ k) : f ○ g ⊆ h ○ k :=
  fun ⟨x, y⟩ ⟨z, h, h'⟩ => ⟨z, h₁ h, h₂ h'⟩

theorem prod_mk_mem_comp_rel {a b c : α} {s t : Set (α × α)} (h₁ : (a, c) ∈ s) (h₂ : (c, b) ∈ t) : (a, b) ∈ s ○ t :=
  ⟨c, h₁, h₂⟩

@[simp]
theorem id_comp_rel {r : Set (α × α)} : IdRel ○ r = r :=
  Set.ext$
    fun ⟨a, b⟩ =>
      by 
        simp 

theorem comp_rel_assoc {r s t : Set (α × α)} : r ○ s ○ t = r ○ (s ○ t) :=
  by 
    ext p <;> cases p <;> simp only [mem_comp_rel] <;> tauto

theorem subset_comp_self {α : Type _} {s : Set (α × α)} (h : IdRel ⊆ s) : s ⊆ s ○ s :=
  fun ⟨x, y⟩ xy_in =>
    ⟨x,
      h
        (by 
          rw [mem_id_rel]),
      xy_in⟩

/-- The relation is invariant under swapping factors. -/
def SymmetricRel (V : Set (α × α)) : Prop :=
  Prod.swap ⁻¹' V = V

/-- The maximal symmetric relation contained in a given relation. -/
def SymmetrizeRel (V : Set (α × α)) : Set (α × α) :=
  V ∩ Prod.swap ⁻¹' V

theorem symmetric_symmetrize_rel (V : Set (α × α)) : SymmetricRel (SymmetrizeRel V) :=
  by 
    simp [SymmetricRel, SymmetrizeRel, preimage_inter, inter_comm, ←preimage_comp]

theorem symmetrize_rel_subset_self (V : Set (α × α)) : SymmetrizeRel V ⊆ V :=
  sep_subset _ _

@[mono]
theorem symmetrize_mono {V W : Set (α × α)} (h : V ⊆ W) : SymmetrizeRel V ⊆ SymmetrizeRel W :=
  inter_subset_inter h$ preimage_mono h

theorem symmetric_rel_inter {U V : Set (α × α)} (hU : SymmetricRel U) (hV : SymmetricRel V) : SymmetricRel (U ∩ V) :=
  by 
    unfold SymmetricRel  at *
    rw [preimage_inter, hU, hV]

/-- This core description of a uniform space is outside of the type class hierarchy. It is useful
  for constructions of uniform spaces, when the topology is derived from the uniform space. -/
structure UniformSpace.Core(α : Type u) where 
  uniformity : Filter (α × α)
  refl : 𝓟 IdRel ≤ uniformity 
  symm : tendsto Prod.swap uniformity uniformity 
  comp : (uniformity.lift' fun s => s ○ s) ≤ uniformity

/-- An alternative constructor for `uniform_space.core`. This version unfolds various
`filter`-related definitions. -/
def UniformSpace.Core.mk' {α : Type u} (U : Filter (α × α)) (refl : ∀ r _ : r ∈ U x, (x, x) ∈ r)
  (symm : ∀ r _ : r ∈ U, Prod.swap ⁻¹' r ∈ U) (comp : ∀ r _ : r ∈ U, ∃ (t : _)(_ : t ∈ U), t ○ t ⊆ r) :
  UniformSpace.Core α :=
  ⟨U, fun r ru => id_rel_subset.2 (refl _ ru), symm,
    by 
      intro r ru 
      rw [mem_lift'_sets]
      exact comp _ ru 
      apply monotone_comp_rel <;> exact monotone_id⟩

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- A uniform space generates a topological space -/
def uniform_space.core.to_topological_space {α : Type u} (u : uniform_space.core α) : topological_space α :=
{ is_open := λ
  s, ∀ x «expr ∈ » s, «expr ∈ »({p : «expr × »(α, α) | «expr = »(p.1, x) → «expr ∈ »(p.2, s)}, u.uniformity),
  is_open_univ := by simp [] [] [] [] [] []; intro []; exact [expr univ_mem],
  is_open_inter := assume
  (s t hs ht x)
  ⟨xs, xt⟩, by filter_upwards ["[", expr hs x xs, ",", expr ht x xt, "]"] []; simp [] [] [] [] [] [] { contextual := tt },
  is_open_sUnion := assume
  (s hs x)
  ⟨t, ts, xt⟩, by filter_upwards ["[", expr hs t ts x xt, "]"] [expr assume p ph h, ⟨t, ts, ph h⟩] }

theorem UniformSpace.core_eq : ∀ {u₁ u₂ : UniformSpace.Core α}, u₁.uniformity = u₂.uniformity → u₁ = u₂
| ⟨u₁, _, _, _⟩, ⟨u₂, _, _, _⟩, h =>
  by 
    congr 
    exact h

/-- A uniform space is a generalization of the "uniform" topological aspects of a
  metric space. It consists of a filter on `α × α` called the "uniformity", which
  satisfies properties analogous to the reflexivity, symmetry, and triangle properties
  of a metric.

  A metric space has a natural uniformity, and a uniform space has a natural topology.
  A topological group also has a natural uniformity, even when it is not metrizable. -/
class UniformSpace(α : Type u) extends TopologicalSpace α, UniformSpace.Core α where 
  is_open_uniformity : ∀ s, IsOpen s ↔ ∀ x _ : x ∈ s, { p:α × α | p.1 = x → p.2 ∈ s } ∈ uniformity

/-- Alternative constructor for `uniform_space α` when a topology is already given. -/
@[matchPattern]
def UniformSpace.mk' {α} (t : TopologicalSpace α) (c : UniformSpace.Core α)
  (is_open_uniformity : ∀ s : Set α, t.is_open s ↔ ∀ x _ : x ∈ s, { p:α × α | p.1 = x → p.2 ∈ s } ∈ c.uniformity) :
  UniformSpace α :=
  ⟨c, is_open_uniformity⟩

/-- Construct a `uniform_space` from a `uniform_space.core`. -/
def UniformSpace.ofCore {α : Type u} (u : UniformSpace.Core α) : UniformSpace α :=
  { toCore := u, toTopologicalSpace := u.to_topological_space, is_open_uniformity := fun a => Iff.rfl }

/-- Construct a `uniform_space` from a `u : uniform_space.core` and a `topological_space` structure
that is equal to `u.to_topological_space`. -/
def UniformSpace.ofCoreEq {α : Type u} (u : UniformSpace.Core α) (t : TopologicalSpace α)
  (h : t = u.to_topological_space) : UniformSpace α :=
  { toCore := u, toTopologicalSpace := t, is_open_uniformity := fun a => h.symm ▸ Iff.rfl }

theorem UniformSpace.to_core_to_topological_space (u : UniformSpace α) :
  u.to_core.to_topological_space = u.to_topological_space :=
  topological_space_eq$
    funext$
      fun s =>
        by 
          rw [UniformSpace.Core.toTopologicalSpace, UniformSpace.is_open_uniformity]

@[ext]
theorem uniform_space_eq : ∀ {u₁ u₂ : UniformSpace α}, u₁.uniformity = u₂.uniformity → u₁ = u₂
| UniformSpace.mk' t₁ u₁ o₁, UniformSpace.mk' t₂ u₂ o₂, h =>
  have  : u₁ = u₂ := UniformSpace.core_eq h 
  have  : t₁ = t₂ :=
    topological_space_eq$
      funext$
        fun s =>
          by 
            rw [o₁, o₂] <;> simp [this]
  by 
    simp 

theorem UniformSpace.of_core_eq_to_core (u : UniformSpace α) (t : TopologicalSpace α)
  (h : t = u.to_core.to_topological_space) : UniformSpace.ofCoreEq u.to_core t h = u :=
  uniform_space_eq rfl

section UniformSpace

variable[UniformSpace α]

/-- The uniformity is a filter on α × α (inferred from an ambient uniform space
  structure on α). -/
def uniformity (α : Type u) [UniformSpace α] : Filter (α × α) :=
  (@UniformSpace.toCore α _).uniformity

localized [uniformity] notation "𝓤" => uniformity

theorem is_open_uniformity {s : Set α} : IsOpen s ↔ ∀ x _ : x ∈ s, { p:α × α | p.1 = x → p.2 ∈ s } ∈ 𝓤 α :=
  UniformSpace.is_open_uniformity s

theorem refl_le_uniformity : 𝓟 IdRel ≤ 𝓤 α :=
  (@UniformSpace.toCore α _).refl

theorem refl_mem_uniformity {x : α} {s : Set (α × α)} (h : s ∈ 𝓤 α) : (x, x) ∈ s :=
  refl_le_uniformity h rfl

theorem mem_uniformity_of_eq {x y : α} {s : Set (α × α)} (h : s ∈ 𝓤 α) (hx : x = y) : (x, y) ∈ s :=
  hx ▸ refl_mem_uniformity h

theorem symm_le_uniformity : map (@Prod.swap α α) (𝓤 _) ≤ 𝓤 _ :=
  (@UniformSpace.toCore α _).symm

theorem comp_le_uniformity : ((𝓤 α).lift' fun s : Set (α × α) => s ○ s) ≤ 𝓤 α :=
  (@UniformSpace.toCore α _).comp

theorem tendsto_swap_uniformity : tendsto (@Prod.swap α α) (𝓤 α) (𝓤 α) :=
  symm_le_uniformity

theorem comp_mem_uniformity_sets {s : Set (α × α)} (hs : s ∈ 𝓤 α) : ∃ (t : _)(_ : t ∈ 𝓤 α), t ○ t ⊆ s :=
  have  : s ∈ (𝓤 α).lift' fun t : Set (α × α) => t ○ t := comp_le_uniformity hs
  (mem_lift'_sets$ monotone_comp_rel monotone_id monotone_id).mp this

/-- Relation `λ f g, tendsto (λ x, (f x, g x)) l (𝓤 α)` is transitive. -/
theorem Filter.Tendsto.uniformity_trans {l : Filter β} {f₁ f₂ f₃ : β → α}
  (h₁₂ : tendsto (fun x => (f₁ x, f₂ x)) l (𝓤 α)) (h₂₃ : tendsto (fun x => (f₂ x, f₃ x)) l (𝓤 α)) :
  tendsto (fun x => (f₁ x, f₃ x)) l (𝓤 α) :=
  by 
    refine' le_transₓ (le_lift'$ fun s hs => mem_map.2 _) comp_le_uniformity 
    filterUpwards [h₁₂ hs, h₂₃ hs]
    exact fun x hx₁₂ hx₂₃ => ⟨_, hx₁₂, hx₂₃⟩

/-- Relation `λ f g, tendsto (λ x, (f x, g x)) l (𝓤 α)` is symmetric -/
theorem Filter.Tendsto.uniformity_symm {l : Filter β} {f : β → α × α} (h : tendsto f l (𝓤 α)) :
  tendsto (fun x => ((f x).2, (f x).1)) l (𝓤 α) :=
  tendsto_swap_uniformity.comp h

/-- Relation `λ f g, tendsto (λ x, (f x, g x)) l (𝓤 α)` is reflexive. -/
theorem tendsto_diag_uniformity (f : β → α) (l : Filter β) : tendsto (fun x => (f x, f x)) l (𝓤 α) :=
  fun s hs => mem_map.2$ univ_mem'$ fun x => refl_mem_uniformity hs

theorem tendsto_const_uniformity {a : α} {f : Filter β} : tendsto (fun _ => (a, a)) f (𝓤 α) :=
  tendsto_diag_uniformity (fun _ => a) f

theorem symm_of_uniformity {s : Set (α × α)} (hs : s ∈ 𝓤 α) :
  ∃ (t : _)(_ : t ∈ 𝓤 α), (∀ a b, (a, b) ∈ t → (b, a) ∈ t) ∧ t ⊆ s :=
  have  : preimage Prod.swap s ∈ 𝓤 α := symm_le_uniformity hs
  ⟨s ∩ preimage Prod.swap s, inter_mem hs this, fun a b ⟨h₁, h₂⟩ => ⟨h₂, h₁⟩, inter_subset_left _ _⟩

theorem comp_symm_of_uniformity {s : Set (α × α)} (hs : s ∈ 𝓤 α) :
  ∃ (t : _)(_ : t ∈ 𝓤 α), (∀ {a b}, (a, b) ∈ t → (b, a) ∈ t) ∧ t ○ t ⊆ s :=
  let ⟨t, ht₁, ht₂⟩ := comp_mem_uniformity_sets hs 
  let ⟨t', ht', ht'₁, ht'₂⟩ := symm_of_uniformity ht₁
  ⟨t', ht', ht'₁, subset.trans (monotone_comp_rel monotone_id monotone_id ht'₂) ht₂⟩

theorem uniformity_le_symm : 𝓤 α ≤ @Prod.swap α α <$> 𝓤 α :=
  by 
    rw [map_swap_eq_comap_swap] <;> exact map_le_iff_le_comap.1 tendsto_swap_uniformity

theorem uniformity_eq_symm : 𝓤 α = @Prod.swap α α <$> 𝓤 α :=
  le_antisymmₓ uniformity_le_symm symm_le_uniformity

theorem symmetrize_mem_uniformity {V : Set (α × α)} (h : V ∈ 𝓤 α) : SymmetrizeRel V ∈ 𝓤 α :=
  by 
    apply (𝓤 α).inter_sets h 
    rw [←image_swap_eq_preimage_swap, uniformity_eq_symm]
    exact image_mem_map h

theorem uniformity_lift_le_swap {g : Set (α × α) → Filter β} {f : Filter β} (hg : Monotone g)
  (h : ((𝓤 α).lift fun s => g (preimage Prod.swap s)) ≤ f) : (𝓤 α).lift g ≤ f :=
  calc (𝓤 α).lift g ≤ (Filter.map (@Prod.swap α α)$ 𝓤 α).lift g := lift_mono uniformity_le_symm (le_reflₓ _)
    _ ≤ _ :=
    by 
      rw [map_lift_eq2 hg, image_swap_eq_preimage_swap] <;> exact h
    

theorem uniformity_lift_le_comp {f : Set (α × α) → Filter β} (h : Monotone f) :
  ((𝓤 α).lift fun s => f (s ○ s)) ≤ (𝓤 α).lift f :=
  calc ((𝓤 α).lift fun s => f (s ○ s)) = ((𝓤 α).lift' fun s : Set (α × α) => s ○ s).lift f :=
    by 
      rw [lift_lift'_assoc]
      exact monotone_comp_rel monotone_id monotone_id 
      exact h 
    _ ≤ (𝓤 α).lift f := lift_mono comp_le_uniformity (le_reflₓ _)
    

theorem comp_le_uniformity3 : ((𝓤 α).lift' fun s : Set (α × α) => s ○ (s ○ s)) ≤ 𝓤 α :=
  calc ((𝓤 α).lift' fun d => d ○ (d ○ d)) = (𝓤 α).lift fun s => (𝓤 α).lift' fun t : Set (α × α) => s ○ (t ○ t) :=
    by 
      rw [lift_lift'_same_eq_lift']
      exact fun x => monotone_comp_rel monotone_const$ monotone_comp_rel monotone_id monotone_id 
      exact fun x => monotone_comp_rel monotone_id monotone_const 
    _ ≤ (𝓤 α).lift fun s => (𝓤 α).lift' fun t : Set (α × α) => s ○ t :=
    lift_mono'$
      fun s hs =>
        @uniformity_lift_le_comp α _ _ (𝓟 ∘ (· ○ ·) s)$
          monotone_principal.comp (monotone_comp_rel monotone_const monotone_id)
    _ = (𝓤 α).lift' fun s : Set (α × α) => s ○ s :=
    lift_lift'_same_eq_lift' (fun s => monotone_comp_rel monotone_const monotone_id)
      fun s => monotone_comp_rel monotone_id monotone_const 
    _ ≤ 𝓤 α := comp_le_uniformity
    

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- See also `comp_open_symm_mem_uniformity_sets`. -/
theorem comp_symm_mem_uniformity_sets
{s : set «expr × »(α, α)}
(hs : «expr ∈ »(s, expr𝓤() α)) : «expr∃ , »((t «expr ∈ » expr𝓤() α), «expr ∧ »(symmetric_rel t, «expr ⊆ »(«expr ○ »(t, t), s))) :=
begin
  obtain ["⟨", ident w, ",", ident w_in, ",", ident w_sub, "⟩", ":", expr «expr∃ , »((w «expr ∈ » expr𝓤() α), «expr ⊆ »(«expr ○ »(w, w), s)), ":=", expr comp_mem_uniformity_sets hs],
  use ["[", expr symmetrize_rel w, ",", expr symmetrize_mem_uniformity w_in, ",", expr symmetric_symmetrize_rel w, "]"],
  have [] [":", expr «expr ⊆ »(symmetrize_rel w, w)] [":=", expr symmetrize_rel_subset_self w],
  calc
    «expr ⊆ »(«expr ○ »(symmetrize_rel w, symmetrize_rel w), «expr ○ »(w, w)) : by mono [] [] [] []
    «expr ⊆ »(..., s) : w_sub
end

theorem subset_comp_self_of_mem_uniformity {s : Set (α × α)} (h : s ∈ 𝓤 α) : s ⊆ s ○ s :=
  subset_comp_self (refl_le_uniformity h)

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem comp_comp_symm_mem_uniformity_sets
{s : set «expr × »(α, α)}
(hs : «expr ∈ »(s, expr𝓤() α)) : «expr∃ , »((t «expr ∈ » expr𝓤() α), «expr ∧ »(symmetric_rel t, «expr ⊆ »(«expr ○ »(«expr ○ »(t, t), t), s))) :=
begin
  rcases [expr comp_symm_mem_uniformity_sets hs, "with", "⟨", ident w, ",", ident w_in, ",", ident w_symm, ",", ident w_sub, "⟩"],
  rcases [expr comp_symm_mem_uniformity_sets w_in, "with", "⟨", ident t, ",", ident t_in, ",", ident t_symm, ",", ident t_sub, "⟩"],
  use ["[", expr t, ",", expr t_in, ",", expr t_symm, "]"],
  have [] [":", expr «expr ⊆ »(t, «expr ○ »(t, t))] [":=", expr subset_comp_self_of_mem_uniformity t_in],
  calc
    «expr ⊆ »(«expr ○ »(«expr ○ »(t, t), t), «expr ○ »(w, t)) : by mono [] [] [] []
    «expr ⊆ »(..., «expr ○ »(w, «expr ○ »(t, t))) : by mono [] [] [] []
    «expr ⊆ »(..., «expr ○ »(w, w)) : by mono [] [] [] []
    «expr ⊆ »(..., s) : w_sub
end

/-!
### Balls in uniform spaces
-/


/-- The ball around `(x : β)` with respect to `(V : set (β × β))`. Intended to be
used for `V ∈ 𝓤 β`, but this is not needed for the definition. Recovers the
notions of metric space ball when `V = {p | dist p.1 p.2 < r }`.  -/
def UniformSpace.Ball (x : β) (V : Set (β × β)) : Set β :=
  Prod.mk x ⁻¹' V

open uniform_space(Ball)

theorem UniformSpace.mem_ball_self (x : α) {V : Set (α × α)} (hV : V ∈ 𝓤 α) : x ∈ ball x V :=
  refl_mem_uniformity hV

/-- The triangle inequality for `uniform_space.ball` -/
theorem mem_ball_comp {V W : Set (β × β)} {x y z} (h : y ∈ ball x V) (h' : z ∈ ball y W) : z ∈ ball x (V ○ W) :=
  prod_mk_mem_comp_rel h h'

theorem ball_subset_of_comp_subset {V W : Set (β × β)} {x y} (h : x ∈ ball y W) (h' : W ○ W ⊆ V) :
  ball x W ⊆ ball y V :=
  fun z z_in => h' (mem_ball_comp h z_in)

theorem ball_mono {V W : Set (β × β)} (h : V ⊆ W) (x : β) : ball x V ⊆ ball x W :=
  by 
    tauto

theorem ball_inter_left (x : β) (V W : Set (β × β)) : ball x (V ∩ W) ⊆ ball x V :=
  ball_mono (inter_subset_left V W) x

theorem ball_inter_right (x : β) (V W : Set (β × β)) : ball x (V ∩ W) ⊆ ball x W :=
  ball_mono (inter_subset_right V W) x

theorem mem_ball_symmetry {V : Set (β × β)} (hV : SymmetricRel V) {x y} : x ∈ ball y V ↔ y ∈ ball x V :=
  show (x, y) ∈ Prod.swap ⁻¹' V ↔ (x, y) ∈ V by 
    unfold SymmetricRel  at hV 
    rw [hV]

theorem ball_eq_of_symmetry {V : Set (β × β)} (hV : SymmetricRel V) {x} : ball x V = { y | (y, x) ∈ V } :=
  by 
    ext y 
    rw [mem_ball_symmetry hV]
    exact Iff.rfl

theorem mem_comp_of_mem_ball {V W : Set (β × β)} {x y z : β} (hV : SymmetricRel V) (hx : x ∈ ball z V)
  (hy : y ∈ ball z W) : (x, y) ∈ V ○ W :=
  by 
    rw [mem_ball_symmetry hV] at hx 
    exact ⟨z, hx, hy⟩

theorem UniformSpace.is_open_ball (x : α) {V : Set (α × α)} (hV : IsOpen V) : IsOpen (ball x V) :=
  hV.preimage$ continuous_const.prod_mk continuous_id

theorem mem_comp_comp {V W M : Set (β × β)} (hW' : SymmetricRel W) {p : β × β} :
  p ∈ V ○ M ○ W ↔ ((ball p.1 V).Prod (ball p.2 W) ∩ M).Nonempty :=
  by 
    cases' p with x y 
    split 
    ·
      rintro ⟨z, ⟨w, hpw, hwz⟩, hzy⟩
      exact
        ⟨(w, z),
          ⟨hpw,
            by 
              rwa [mem_ball_symmetry hW']⟩,
          hwz⟩
    ·
      rintro ⟨⟨w, z⟩, ⟨w_in, z_in⟩, hwz⟩
      rwa [mem_ball_symmetry hW'] at z_in 
      use z, w <;> tauto

/-!
### Neighborhoods in uniform spaces
-/


theorem mem_nhds_uniformity_iff_right {x : α} {s : Set α} : s ∈ 𝓝 x ↔ { p:α × α | p.1 = x → p.2 ∈ s } ∈ 𝓤 α :=
  ⟨by 
      simp only [mem_nhds_iff, is_open_uniformity, and_imp, exists_imp_distrib]
      exact
        fun t ts ht xt =>
          by 
            filterUpwards [ht x xt] fun ⟨x', y⟩ h eq => ts$ h Eq,
    fun hs =>
      mem_nhds_iff.mpr
        ⟨{ x | { p:α × α | p.1 = x → p.2 ∈ s } ∈ 𝓤 α }, fun x' hx' => refl_mem_uniformity hx' rfl,
          is_open_uniformity.mpr$
            fun x' hx' =>
              let ⟨t, ht, tr⟩ := comp_mem_uniformity_sets hx' 
              by 
                filterUpwards [ht]
                  fun ⟨a, b⟩ hp' hax' : a = x' =>
                    by 
                      filterUpwards [ht]
                        fun ⟨a, b'⟩ hp'' hab : a = b =>
                          have hp : (x', b) ∈ t := hax' ▸ hp' 
                          have  : (b, b') ∈ t := hab ▸ hp'' 
                          have  : (x', b') ∈ t ○ t := ⟨b, hp, this⟩
                          show b' ∈ s from tr this rfl,
          hs⟩⟩

theorem mem_nhds_uniformity_iff_left {x : α} {s : Set α} : s ∈ 𝓝 x ↔ { p:α × α | p.2 = x → p.1 ∈ s } ∈ 𝓤 α :=
  by 
    rw [uniformity_eq_symm, mem_nhds_uniformity_iff_right]
    rfl

theorem nhds_eq_comap_uniformity_aux {α : Type u} {x : α} {s : Set α} {F : Filter (α × α)} :
  { p:α × α | p.fst = x → p.snd ∈ s } ∈ F ↔ s ∈ comap (Prod.mk x) F :=
  by 
    rw [mem_comap] <;>
      exact
        Iff.intro (fun hs => ⟨_, hs, fun x hx => hx rfl⟩)
          fun ⟨t, h, ht⟩ =>
            F.sets_of_superset h$
              fun ⟨p₁, p₂⟩ hp h : p₁ = x =>
                ht$
                  by 
                    simp [h.symm, hp]

theorem nhds_eq_comap_uniformity {x : α} : 𝓝 x = (𝓤 α).comap (Prod.mk x) :=
  by 
    ext s 
    rw [mem_nhds_uniformity_iff_right]
    exact nhds_eq_comap_uniformity_aux

/-- See also `is_open_iff_open_ball_subset`. -/
theorem is_open_iff_ball_subset {s : Set α} : IsOpen s ↔ ∀ x _ : x ∈ s, ∃ (V : _)(_ : V ∈ 𝓤 α), ball x V ⊆ s :=
  by 
    simpRw [is_open_iff_mem_nhds, nhds_eq_comap_uniformity]
    exact Iff.rfl

theorem nhds_basis_uniformity' {p : ι → Prop} {s : ι → Set (α × α)} (h : (𝓤 α).HasBasis p s) {x : α} :
  (𝓝 x).HasBasis p fun i => ball x (s i) :=
  by 
    rw [nhds_eq_comap_uniformity]
    exact h.comap (Prod.mk x)

theorem nhds_basis_uniformity {p : ι → Prop} {s : ι → Set (α × α)} (h : (𝓤 α).HasBasis p s) {x : α} :
  (𝓝 x).HasBasis p fun i => { y | (y, x) ∈ s i } :=
  by 
    replace h := h.comap Prod.swap 
    rw [←map_swap_eq_comap_swap, ←uniformity_eq_symm] at h 
    exact nhds_basis_uniformity' h

theorem UniformSpace.mem_nhds_iff {x : α} {s : Set α} : s ∈ 𝓝 x ↔ ∃ (V : _)(_ : V ∈ 𝓤 α), ball x V ⊆ s :=
  by 
    rw [nhds_eq_comap_uniformity, mem_comap]
    exact Iff.rfl

theorem UniformSpace.ball_mem_nhds (x : α) ⦃V : Set (α × α)⦄ (V_in : V ∈ 𝓤 α) : ball x V ∈ 𝓝 x :=
  by 
    rw [UniformSpace.mem_nhds_iff]
    exact ⟨V, V_in, subset.refl _⟩

theorem UniformSpace.mem_nhds_iff_symm {x : α} {s : Set α} :
  s ∈ 𝓝 x ↔ ∃ (V : _)(_ : V ∈ 𝓤 α), SymmetricRel V ∧ ball x V ⊆ s :=
  by 
    rw [UniformSpace.mem_nhds_iff]
    split 
    ·
      rintro ⟨V, V_in, V_sub⟩
      use SymmetrizeRel V, symmetrize_mem_uniformity V_in, symmetric_symmetrize_rel V 
      exact subset.trans (ball_mono (symmetrize_rel_subset_self V) x) V_sub
    ·
      rintro ⟨V, V_in, V_symm, V_sub⟩
      exact ⟨V, V_in, V_sub⟩

theorem UniformSpace.has_basis_nhds (x : α) :
  has_basis (𝓝 x) (fun s : Set (α × α) => s ∈ 𝓤 α ∧ SymmetricRel s) fun s => ball x s :=
  ⟨fun t =>
      by 
        simp [UniformSpace.mem_nhds_iff_symm, and_assoc]⟩

open UniformSpace

theorem UniformSpace.mem_closure_iff_symm_ball {s : Set α} {x} :
  x ∈ Closure s ↔ ∀ {V}, V ∈ 𝓤 α → SymmetricRel V → (s ∩ ball x V).Nonempty :=
  by 
    simp [mem_closure_iff_nhds_basis (has_basis_nhds x), Set.Nonempty]

theorem UniformSpace.mem_closure_iff_ball {s : Set α} {x} : x ∈ Closure s ↔ ∀ {V}, V ∈ 𝓤 α → (ball x V ∩ s).Nonempty :=
  by 
    simp [mem_closure_iff_nhds_basis' (nhds_basis_uniformity' (𝓤 α).basis_sets)]

theorem UniformSpace.has_basis_nhds_prod (x y : α) :
  (has_basis (𝓝 (x, y)) fun s => s ∈ 𝓤 α ∧ SymmetricRel s)$ fun s => (ball x s).Prod (ball y s) :=
  by 
    rw [nhds_prod_eq]
    apply (has_basis_nhds x).prod' (has_basis_nhds y)
    rintro U V ⟨U_in, U_symm⟩ ⟨V_in, V_symm⟩
    exact
      ⟨U ∩ V, ⟨(𝓤 α).inter_sets U_in V_in, symmetric_rel_inter U_symm V_symm⟩, ball_inter_left x U V,
        ball_inter_right y U V⟩

theorem nhds_eq_uniformity {x : α} : 𝓝 x = (𝓤 α).lift' (ball x) :=
  (nhds_basis_uniformity' (𝓤 α).basis_sets).eq_binfi

theorem mem_nhds_left (x : α) {s : Set (α × α)} (h : s ∈ 𝓤 α) : { y:α | (x, y) ∈ s } ∈ 𝓝 x :=
  ball_mem_nhds x h

theorem mem_nhds_right (y : α) {s : Set (α × α)} (h : s ∈ 𝓤 α) : { x:α | (x, y) ∈ s } ∈ 𝓝 y :=
  mem_nhds_left _ (symm_le_uniformity h)

theorem tendsto_right_nhds_uniformity {a : α} : tendsto (fun a' => (a', a)) (𝓝 a) (𝓤 α) :=
  fun s => mem_nhds_right a

theorem tendsto_left_nhds_uniformity {a : α} : tendsto (fun a' => (a, a')) (𝓝 a) (𝓤 α) :=
  fun s => mem_nhds_left a

theorem lift_nhds_left {x : α} {g : Set α → Filter β} (hg : Monotone g) :
  (𝓝 x).lift g = (𝓤 α).lift fun s : Set (α × α) => g { y | (x, y) ∈ s } :=
  Eq.trans
    (by 
      rw [nhds_eq_uniformity]
      exact Filter.lift_assoc$ monotone_principal.comp$ monotone_preimage.comp monotone_preimage)
    (congr_argₓ _$ funext$ fun s => Filter.lift_principal hg)

theorem lift_nhds_right {x : α} {g : Set α → Filter β} (hg : Monotone g) :
  (𝓝 x).lift g = (𝓤 α).lift fun s : Set (α × α) => g { y | (y, x) ∈ s } :=
  calc (𝓝 x).lift g = (𝓤 α).lift fun s : Set (α × α) => g { y | (x, y) ∈ s } := lift_nhds_left hg 
    _ = (@Prod.swap α α <$> 𝓤 α).lift fun s : Set (α × α) => g { y | (x, y) ∈ s } :=
    by 
      rw [←uniformity_eq_symm]
    _ = (𝓤 α).lift fun s : Set (α × α) => g { y | (x, y) ∈ image Prod.swap s } :=
    map_lift_eq2$ hg.comp monotone_preimage 
    _ = _ :=
    by 
      simp [image_swap_eq_preimage_swap]
    

theorem nhds_nhds_eq_uniformity_uniformity_prod {a b : α} :
  𝓝 a ×ᶠ 𝓝 b =
    (𝓤 α).lift
      fun s : Set (α × α) => (𝓤 α).lift' fun t : Set (α × α) => Set.Prod { y:α | (y, a) ∈ s } { y:α | (b, y) ∈ t } :=
  by 
    rw [prod_def]
    show ((𝓝 a).lift fun s : Set α => (𝓝 b).lift fun t : Set α => 𝓟 (Set.Prod s t)) = _ 
    rw [lift_nhds_right]
    apply congr_argₓ 
    funext s 
    rw [lift_nhds_left]
    rfl 
    exact monotone_principal.comp (monotone_prod monotone_const monotone_id)
    exact monotone_lift' monotone_const$ monotone_lam$ fun x => monotone_prod monotone_id monotone_const

theorem nhds_eq_uniformity_prod {a b : α} :
  𝓝 (a, b) = (𝓤 α).lift' fun s : Set (α × α) => Set.Prod { y:α | (y, a) ∈ s } { y:α | (b, y) ∈ s } :=
  by 
    rw [nhds_prod_eq, nhds_nhds_eq_uniformity_uniformity_prod, lift_lift'_same_eq_lift']
    ·
      intro s 
      exact monotone_prod monotone_const monotone_preimage
    ·
      intro t 
      exact monotone_prod monotone_preimage monotone_const

theorem nhdset_of_mem_uniformity {d : Set (α × α)} (s : Set (α × α)) (hd : d ∈ 𝓤 α) :
  ∃ t : Set (α × α), IsOpen t ∧ s ⊆ t ∧ t ⊆ { p | ∃ x y, (p.1, x) ∈ d ∧ (x, y) ∈ s ∧ (y, p.2) ∈ d } :=
  let cl_d := { p:α × α | ∃ x y, (p.1, x) ∈ d ∧ (x, y) ∈ s ∧ (y, p.2) ∈ d }
  have  : ∀ p _ : p ∈ s, ∃ (t : _)(_ : t ⊆ cl_d), IsOpen t ∧ p ∈ t :=
    fun ⟨x, y⟩ hp =>
      _root_.mem_nhds_iff.mp$
        show cl_d ∈ 𝓝 (x, y)by 
          rw [nhds_eq_uniformity_prod, mem_lift'_sets]
          exact ⟨d, hd, fun ⟨a, b⟩ ⟨ha, hb⟩ => ⟨x, y, ha, hp, hb⟩⟩
          exact monotone_prod monotone_preimage monotone_preimage 
  have  : ∃ t : ∀ p : α × α h : p ∈ s, Set (α × α), ∀ p, ∀ h : p ∈ s, t p h ⊆ cl_d ∧ IsOpen (t p h) ∧ p ∈ t p h :=
    by 
      simp [Classical.skolem] at this <;> simp  <;> assumption 
  match this with 
  | ⟨t, ht⟩ =>
    ⟨(⋃p : α × α, ⋃h : p ∈ s, t p h : Set (α × α)),
      is_open_Union$ fun p : α × α => is_open_Union$ fun hp => (ht p hp).right.left,
      fun ⟨a, b⟩ hp =>
        by 
          simp  <;> exact ⟨a, b, hp, (ht (a, b) hp).right.right⟩,
      Union_subset$ fun p => Union_subset$ fun hp => (ht p hp).left⟩

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- Entourages are neighborhoods of the diagonal. -/
theorem nhds_le_uniformity (x : α) : «expr ≤ »(expr𝓝() (x, x), expr𝓤() α) :=
begin
  intros [ident V, ident V_in],
  rcases [expr comp_symm_mem_uniformity_sets V_in, "with", "⟨", ident w, ",", ident w_in, ",", ident w_symm, ",", ident w_sub, "⟩"],
  have [] [":", expr «expr ∈ »((ball x w).prod (ball x w), expr𝓝() (x, x))] [],
  { rw [expr nhds_prod_eq] [],
    exact [expr prod_mem_prod (ball_mem_nhds x w_in) (ball_mem_nhds x w_in)] },
  apply [expr mem_of_superset this],
  rintros ["⟨", ident u, ",", ident v, "⟩", "⟨", ident u_in, ",", ident v_in, "⟩"],
  exact [expr w_sub (mem_comp_of_mem_ball w_symm u_in v_in)]
end

/-- Entourages are neighborhoods of the diagonal. -/
theorem supr_nhds_le_uniformity : (⨆x : α, 𝓝 (x, x)) ≤ 𝓤 α :=
  supr_le nhds_le_uniformity

/-!
### Closure and interior in uniform spaces
-/


theorem closure_eq_uniformity (s : Set$ α × α) :
  Closure s = ⋂(V : _)(_ : V ∈ { V | V ∈ 𝓤 α ∧ SymmetricRel V }), V ○ s ○ V :=
  by 
    ext ⟨x, y⟩
    simpRw [mem_closure_iff_nhds_basis (UniformSpace.has_basis_nhds_prod x y), mem_Inter, mem_set_of_eq]
    apply forall_congrₓ 
    intro V 
    apply forall_congrₓ 
    rintro ⟨V_in, V_symm⟩
    simpRw [mem_comp_comp V_symm, inter_comm, exists_prop]
    exact Iff.rfl

theorem uniformity_has_basis_closed : has_basis (𝓤 α) (fun V : Set (α × α) => V ∈ 𝓤 α ∧ IsClosed V) id :=
  by 
    refine' Filter.has_basis_self.2 fun t h => _ 
    rcases comp_comp_symm_mem_uniformity_sets h with ⟨w, w_in, w_symm, r⟩
    refine' ⟨Closure w, mem_of_superset w_in subset_closure, is_closed_closure, _⟩
    refine' subset.trans _ r 
    rw [closure_eq_uniformity]
    apply Inter_subset_of_subset 
    apply Inter_subset 
    exact ⟨w_in, w_symm⟩

/-- Closed entourages form a basis of the uniformity filter. -/
theorem uniformity_has_basis_closure : has_basis (𝓤 α) (fun V : Set (α × α) => V ∈ 𝓤 α) Closure :=
  ⟨by 
      intro t 
      rw [uniformity_has_basis_closed.mem_iff]
      split 
      ·
        rintro ⟨r, ⟨r_in, r_closed⟩, r_sub⟩
        use r, r_in 
        convert r_sub 
        rw [r_closed.closure_eq]
        rfl
      ·
        rintro ⟨r, r_in, r_sub⟩
        exact ⟨Closure r, ⟨mem_of_superset r_in subset_closure, is_closed_closure⟩, r_sub⟩⟩

theorem closure_eq_inter_uniformity {t : Set (α × α)} : Closure t = ⋂(d : _)(_ : d ∈ 𝓤 α), d ○ (t ○ d) :=
  Set.ext$
    fun ⟨a, b⟩ =>
      calc (a, b) ∈ Closure t ↔ 𝓝 (a, b)⊓𝓟 t ≠ ⊥ := mem_closure_iff_nhds_ne_bot 
        _ ↔
          ((@Prod.swap α α <$> 𝓤 α).lift'
                fun s : Set (α × α) => Set.Prod { x:α | (x, a) ∈ s } { y:α | (b, y) ∈ s })⊓𝓟 t ≠
            ⊥ :=
        by 
          rw [←uniformity_eq_symm, nhds_eq_uniformity_prod]
        _ ↔
          ((map (@Prod.swap α α) (𝓤 α)).lift'
                fun s : Set (α × α) => Set.Prod { x:α | (x, a) ∈ s } { y:α | (b, y) ∈ s })⊓𝓟 t ≠
            ⊥ :=
        by 
          rfl 
        _ ↔ ((𝓤 α).lift' fun s : Set (α × α) => Set.Prod { y:α | (a, y) ∈ s } { x:α | (x, b) ∈ s })⊓𝓟 t ≠ ⊥ :=
        by 
          rw [map_lift'_eq2]
          simp [image_swap_eq_preimage_swap, Function.comp]
          exact monotone_prod monotone_preimage monotone_preimage 
        _ ↔ ∀ s _ : s ∈ 𝓤 α, (Set.Prod { y:α | (a, y) ∈ s } { x:α | (x, b) ∈ s } ∩ t).Nonempty :=
        by 
          rw [lift'_inf_principal_eq, ←ne_bot_iff, lift'_ne_bot_iff]
          exact monotone_inter (monotone_prod monotone_preimage monotone_preimage) monotone_const 
        _ ↔ ∀ s _ : s ∈ 𝓤 α, (a, b) ∈ s ○ (t ○ s) :=
        forall_congrₓ$
          fun s =>
            forall_congrₓ$
              fun hs =>
                ⟨fun ⟨⟨x, y⟩, ⟨⟨hx, hy⟩, hxyt⟩⟩ => ⟨x, hx, y, hxyt, hy⟩,
                  fun ⟨x, hx, y, hxyt, hy⟩ => ⟨⟨x, y⟩, ⟨⟨hx, hy⟩, hxyt⟩⟩⟩
        _ ↔ _ :=
        by 
          simp 
        

theorem uniformity_eq_uniformity_closure : 𝓤 α = (𝓤 α).lift' Closure :=
  le_antisymmₓ
    (le_infi$
      fun s =>
        le_infi$
          fun hs =>
            by 
              simp  <;> filterUpwards [hs] subset_closure)
    (calc (𝓤 α).lift' Closure ≤ (𝓤 α).lift' fun d => d ○ (d ○ d) :=
      lift'_mono'
        (by 
          intro s hs <;> rw [closure_eq_inter_uniformity] <;> exact bInter_subset_of_mem hs)
      _ ≤ 𝓤 α := comp_le_uniformity3
      )

theorem uniformity_eq_uniformity_interior : 𝓤 α = (𝓤 α).lift' Interior :=
  le_antisymmₓ
    (le_infi$
      fun d =>
        le_infi$
          fun hd =>
            let ⟨s, hs, hs_comp⟩ :=
              (mem_lift'_sets$ monotone_comp_rel monotone_id$ monotone_comp_rel monotone_id monotone_id).mp
                (comp_le_uniformity3 hd)
            let ⟨t, ht, hst, ht_comp⟩ := nhdset_of_mem_uniformity s hs 
            have  : s ⊆ Interior d :=
              calc s ⊆ t := hst 
                _ ⊆ Interior d :=
                (subset_interior_iff_subset_of_open ht).mpr$
                  fun x hx : x ∈ t =>
                    let ⟨x, y, h₁, h₂, h₃⟩ := ht_comp hx 
                    hs_comp ⟨x, h₁, y, h₂, h₃⟩
                
            have  : Interior d ∈ 𝓤 α :=
              by 
                filterUpwards [hs] this 
            by 
              simp [this])
    fun s hs => ((𝓤 α).lift' Interior).sets_of_superset (mem_lift' hs) interior_subset

theorem interior_mem_uniformity {s : Set (α × α)} (hs : s ∈ 𝓤 α) : Interior s ∈ 𝓤 α :=
  by 
    rw [uniformity_eq_uniformity_interior] <;> exact mem_lift' hs

theorem mem_uniformity_is_closed {s : Set (α × α)} (h : s ∈ 𝓤 α) : ∃ (t : _)(_ : t ∈ 𝓤 α), IsClosed t ∧ t ⊆ s :=
  let ⟨t, ⟨ht_mem, htc⟩, hts⟩ := uniformity_has_basis_closed.mem_iff.1 h
  ⟨t, ht_mem, htc, hts⟩

theorem is_open_iff_open_ball_subset {s : Set α} :
  IsOpen s ↔ ∀ x _ : x ∈ s, ∃ (V : _)(_ : V ∈ 𝓤 α), IsOpen V ∧ ball x V ⊆ s :=
  by 
    rw [is_open_iff_ball_subset]
    split  <;> intro h x hx
    ·
      obtain ⟨V, hV, hV'⟩ := h x hx 
      exact ⟨Interior V, interior_mem_uniformity hV, is_open_interior, (ball_mono interior_subset x).trans hV'⟩
    ·
      obtain ⟨V, hV, -, hV'⟩ := h x hx 
      exact ⟨V, hV, hV'⟩

/-- The uniform neighborhoods of all points of a dense set cover the whole space. -/
theorem Dense.bUnion_uniformity_ball {s : Set α} {U : Set (α × α)} (hs : Dense s) (hU : U ∈ 𝓤 α) :
  (⋃(x : _)(_ : x ∈ s), ball x U) = univ :=
  by 
    refine' bUnion_eq_univ_iff.2 fun y => _ 
    rcases hs.inter_nhds_nonempty (mem_nhds_right y hU) with ⟨x, hxs, hxy : (x, y) ∈ U⟩
    exact ⟨x, hxs, hxy⟩

/-!
### Uniformity bases
-/


/-- Open elements of `𝓤 α` form a basis of `𝓤 α`. -/
theorem uniformity_has_basis_open : has_basis (𝓤 α) (fun V : Set (α × α) => V ∈ 𝓤 α ∧ IsOpen V) id :=
  has_basis_self.2$ fun s hs => ⟨Interior s, interior_mem_uniformity hs, is_open_interior, interior_subset⟩

theorem Filter.HasBasis.mem_uniformity_iff {p : β → Prop} {s : β → Set (α × α)} (h : (𝓤 α).HasBasis p s)
  {t : Set (α × α)} : t ∈ 𝓤 α ↔ ∃ (i : _)(hi : p i), ∀ a b, (a, b) ∈ s i → (a, b) ∈ t :=
  h.mem_iff.trans$
    by 
      simp only [Prod.forall, subset_def]

/-- Symmetric entourages form a basis of `𝓤 α` -/
theorem UniformSpace.has_basis_symmetric : (𝓤 α).HasBasis (fun s : Set (α × α) => s ∈ 𝓤 α ∧ SymmetricRel s) id :=
  has_basis_self.2$
    fun t t_in =>
      ⟨SymmetrizeRel t, symmetrize_mem_uniformity t_in, symmetric_symmetrize_rel t, symmetrize_rel_subset_self t⟩

/-- Open elements `s : set (α × α)` of `𝓤 α` such that `(x, y) ∈ s ↔ (y, x) ∈ s` form a basis
of `𝓤 α`. -/
theorem uniformity_has_basis_open_symmetric :
  has_basis (𝓤 α) (fun V : Set (α × α) => V ∈ 𝓤 α ∧ IsOpen V ∧ SymmetricRel V) id :=
  by 
    simp only [←and_assoc]
    refine' uniformity_has_basis_open.restrict fun s hs => ⟨SymmetrizeRel s, _⟩
    exact
      ⟨⟨symmetrize_mem_uniformity hs.1, IsOpen.inter hs.2 (hs.2.Preimage continuous_swap)⟩, symmetric_symmetrize_rel s,
        symmetrize_rel_subset_self s⟩

theorem comp_open_symm_mem_uniformity_sets {s : Set (α × α)} (hs : s ∈ 𝓤 α) :
  ∃ (t : _)(_ : t ∈ 𝓤 α), IsOpen t ∧ SymmetricRel t ∧ t ○ t ⊆ s :=
  by 
    obtain ⟨t, ht₁, ht₂⟩ := comp_mem_uniformity_sets hs 
    obtain ⟨u, ⟨hu₁, hu₂, hu₃⟩, hu₄ : u ⊆ t⟩ := uniformity_has_basis_open_symmetric.mem_iff.mp ht₁ 
    exact ⟨u, hu₁, hu₂, hu₃, (comp_rel_mono hu₄ hu₄).trans ht₂⟩

section 

variable(α)

theorem UniformSpace.has_seq_basis [is_countably_generated$ 𝓤 α] :
  ∃ V : ℕ → Set (α × α), has_antitone_basis (𝓤 α) (fun _ => True) V ∧ ∀ n, SymmetricRel (V n) :=
  let ⟨U, hsym, hbasis⟩ := UniformSpace.has_basis_symmetric.exists_antitone_subbasis
  ⟨U, hbasis, fun n => (hsym n).2⟩

end 

theorem Filter.HasBasis.bInter_bUnion_ball {p : ι → Prop} {U : ι → Set (α × α)} (h : has_basis (𝓤 α) p U) (s : Set α) :
  (⋂(i : _)(hi : p i), ⋃(x : _)(_ : x ∈ s), ball x (U i)) = Closure s :=
  by 
    ext x 
    simp [mem_closure_iff_nhds_basis (nhds_basis_uniformity h), ball]

/-! ### Uniform continuity -/


/-- A function `f : α → β` is *uniformly continuous* if `(f x, f y)` tends to the diagonal
as `(x, y)` tends to the diagonal. In other words, if `x` is sufficiently close to `y`, then
`f x` is close to `f y` no matter where `x` and `y` are located in `α`. -/
def UniformContinuous [UniformSpace β] (f : α → β) :=
  tendsto (fun x : α × α => (f x.1, f x.2)) (𝓤 α) (𝓤 β)

/-- A function `f : α → β` is *uniformly continuous* on `s : set α` if `(f x, f y)` tends to
the diagonal as `(x, y)` tends to the diagonal while remaining in `s.prod s`.
In other words, if `x` is sufficiently close to `y`, then `f x` is close to
`f y` no matter where `x` and `y` are located in `s`.-/
def UniformContinuousOn [UniformSpace β] (f : α → β) (s : Set α) : Prop :=
  tendsto (fun x : α × α => (f x.1, f x.2)) (𝓤 α⊓principal (s.prod s)) (𝓤 β)

theorem uniform_continuous_def [UniformSpace β] {f : α → β} :
  UniformContinuous f ↔ ∀ r _ : r ∈ 𝓤 β, { x:α × α | (f x.1, f x.2) ∈ r } ∈ 𝓤 α :=
  Iff.rfl

theorem uniform_continuous_iff_eventually [UniformSpace β] {f : α → β} :
  UniformContinuous f ↔ ∀ r _ : r ∈ 𝓤 β, ∀ᶠx : α × α in 𝓤 α, (f x.1, f x.2) ∈ r :=
  Iff.rfl

theorem uniform_continuous_on_univ [UniformSpace β] {f : α → β} : UniformContinuousOn f univ ↔ UniformContinuous f :=
  by 
    rw [UniformContinuousOn, UniformContinuous, univ_prod_univ, principal_univ, inf_top_eq]

theorem uniform_continuous_of_const [UniformSpace β] {c : α → β} (h : ∀ a b, c a = c b) : UniformContinuous c :=
  have  : (fun x : α × α => (c x.fst, c x.snd)) ⁻¹' IdRel = univ := eq_univ_iff_forall.2$ fun ⟨a, b⟩ => h a b 
  le_transₓ
    (map_le_iff_le_comap.2$
      by 
        simp [comap_principal, this, univ_mem])
    refl_le_uniformity

theorem uniform_continuous_id : UniformContinuous (@id α) :=
  by 
    simp [UniformContinuous] <;> exact tendsto_id

theorem uniform_continuous_const [UniformSpace β] {b : β} : UniformContinuous fun a : α => b :=
  uniform_continuous_of_const$ fun _ _ => rfl

theorem UniformContinuous.comp [UniformSpace β] [UniformSpace γ] {g : β → γ} {f : α → β} (hg : UniformContinuous g)
  (hf : UniformContinuous f) : UniformContinuous (g ∘ f) :=
  hg.comp hf

theorem Filter.HasBasis.uniform_continuous_iff [UniformSpace β] {p : γ → Prop} {s : γ → Set (α × α)}
  (ha : (𝓤 α).HasBasis p s) {q : δ → Prop} {t : δ → Set (β × β)} (hb : (𝓤 β).HasBasis q t) {f : α → β} :
  UniformContinuous f ↔ ∀ i hi : q i, ∃ (j : _)(hj : p j), ∀ x y, (x, y) ∈ s j → (f x, f y) ∈ t i :=
  (ha.tendsto_iff hb).trans$
    by 
      simp only [Prod.forall]

theorem Filter.HasBasis.uniform_continuous_on_iff [UniformSpace β] {p : γ → Prop} {s : γ → Set (α × α)}
  (ha : (𝓤 α).HasBasis p s) {q : δ → Prop} {t : δ → Set (β × β)} (hb : (𝓤 β).HasBasis q t) {f : α → β} {S : Set α} :
  UniformContinuousOn f S ↔
    ∀ i hi : q i, ∃ (j : _)(hj : p j), ∀ x y _ : x ∈ S _ : y ∈ S, (x, y) ∈ s j → (f x, f y) ∈ t i :=
  ((ha.inf_principal (S.prod S)).tendsto_iff hb).trans$
    by 
      finish [Prod.forall]

end UniformSpace

open_locale uniformity

section Constructions

instance  : PartialOrderₓ (UniformSpace α) :=
  { le := fun t s => t.uniformity ≤ s.uniformity, le_antisymm := fun t s h₁ h₂ => uniform_space_eq$ le_antisymmₓ h₁ h₂,
    le_refl := fun t => le_reflₓ _, le_trans := fun a b c h₁ h₂ => le_transₓ h₁ h₂ }

instance  : HasInfₓ (UniformSpace α) :=
  ⟨fun s =>
      UniformSpace.ofCore
        { uniformity := ⨅(u : _)(_ : u ∈ s), @uniformity α u, refl := le_infi$ fun u => le_infi$ fun hu => u.refl,
          symm := le_infi$ fun u => le_infi$ fun hu => le_transₓ (map_mono$ infi_le_of_le _$ infi_le _ hu) u.symm,
          comp :=
            le_infi$
              fun u => le_infi$ fun hu => le_transₓ (lift'_mono (infi_le_of_le _$ infi_le _ hu)$ le_reflₓ _) u.comp }⟩

private theorem Inf_le {tt : Set (UniformSpace α)} {t : UniformSpace α} (h : t ∈ tt) : Inf tt ≤ t :=
  show (⨅(u : _)(_ : u ∈ tt), @uniformity α u) ≤ t.uniformity from infi_le_of_le t$ infi_le _ h

private theorem le_Inf {tt : Set (UniformSpace α)} {t : UniformSpace α} (h : ∀ t' _ : t' ∈ tt, t ≤ t') : t ≤ Inf tt :=
  show t.uniformity ≤ ⨅(u : _)(_ : u ∈ tt), @uniformity α u from le_infi$ fun t' => le_infi$ fun ht' => h t' ht'

instance  : HasTop (UniformSpace α) :=
  ⟨UniformSpace.ofCore { uniformity := ⊤, refl := le_top, symm := le_top, comp := le_top }⟩

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
instance : has_bot (uniform_space α) :=
⟨{ to_topological_space := «expr⊥»(),
   uniformity := expr𝓟() id_rel,
   refl := le_refl _,
   symm := by simp [] [] [] ["[", expr tendsto, "]"] [] []; apply [expr subset.refl],
   comp := begin
     rw ["[", expr lift'_principal, "]"] [],
     { simp [] [] [] [] [] [] },
     exact [expr monotone_comp_rel monotone_id monotone_id]
   end,
   is_open_uniformity := assume
   s, by simp [] [] [] ["[", expr is_open_fold, ",", expr subset_def, ",", expr id_rel, "]"] [] [] { contextual := tt } }⟩

instance  : CompleteLattice (UniformSpace α) :=
  { UniformSpace.partialOrder with sup := fun a b => Inf { x | a ≤ x ∧ b ≤ x },
    le_sup_left := fun a b => le_Inf fun _ ⟨h, _⟩ => h, le_sup_right := fun a b => le_Inf fun _ ⟨_, h⟩ => h,
    sup_le := fun a b c h₁ h₂ => Inf_le ⟨h₁, h₂⟩, inf := fun a b => Inf {a, b},
    le_inf :=
      fun a b c h₁ h₂ =>
        le_Inf
          fun u h =>
            by 
              cases h 
              exact h.symm ▸ h₁ 
              exact (mem_singleton_iff.1 h).symm ▸ h₂,
    inf_le_left :=
      fun a b =>
        Inf_le
          (by 
            simp ),
    inf_le_right :=
      fun a b =>
        Inf_le
          (by 
            simp ),
    top := ⊤, le_top := fun a => show a.uniformity ≤ ⊤ from le_top, bot := ⊥, bot_le := fun u => u.refl,
    sup := fun tt => Inf { t | ∀ t' _ : t' ∈ tt, t' ≤ t }, le_Sup := fun s u h => le_Inf fun u' h' => h' u h,
    Sup_le := fun s u h => Inf_le h, inf := Inf, le_Inf := fun s a hs => le_Inf hs, Inf_le := fun s a ha => Inf_le ha }

theorem infi_uniformity {ι : Sort _} {u : ι → UniformSpace α} : (infi u).uniformity = ⨅i, (u i).uniformity :=
  show (⨅(a : _)(h : ∃ i : ι, u i = a), a.uniformity) = _ from
    le_antisymmₓ (le_infi$ fun i => infi_le_of_le (u i)$ infi_le _ ⟨i, rfl⟩)
      (le_infi$ fun a => le_infi$ fun ⟨i, (ha : u i = a)⟩ => ha ▸ infi_le _ _)

theorem inf_uniformity {u v : UniformSpace α} : (u⊓v).uniformity = u.uniformity⊓v.uniformity :=
  have  : u⊓v = ⨅(i : _)(h : i = u ∨ i = v), i :=
    by 
      simp [infi_or, infi_inf_eq]
  calc (u⊓v).uniformity = (⨅(i : _)(h : i = u ∨ i = v), i : UniformSpace α).uniformity :=
    by 
      rw [this]
    _ = _ :=
    by 
      simp [infi_uniformity, infi_or, infi_inf_eq]
    

instance inhabitedUniformSpace : Inhabited (UniformSpace α) :=
  ⟨⊥⟩

instance inhabitedUniformSpaceCore : Inhabited (UniformSpace.Core α) :=
  ⟨@UniformSpace.toCore _ (default _)⟩

/-- Given `f : α → β` and a uniformity `u` on `β`, the inverse image of `u` under `f`
  is the inverse image in the filter sense of the induced function `α × α → β × β`. -/
def UniformSpace.comap (f : α → β) (u : UniformSpace β) : UniformSpace α :=
  { uniformity := u.uniformity.comap fun p : α × α => (f p.1, f p.2),
    toTopologicalSpace := u.to_topological_space.induced f,
    refl :=
      le_transₓ
        (by 
          simp  <;> exact fun ⟨a, b⟩ h : a = b => h ▸ rfl)
        (comap_mono u.refl),
    symm :=
      by 
        simp [tendsto_comap_iff, Prod.swap, · ∘ ·] <;> exact tendsto_swap_uniformity.comp tendsto_comap,
    comp :=
      le_transₓ
        (by 
          rw [comap_lift'_eq, comap_lift'_eq2]
          exact lift'_mono'$ fun s hs ⟨a₁, a₂⟩ ⟨x, h₁, h₂⟩ => ⟨f x, h₁, h₂⟩
          repeat' 
            exact monotone_comp_rel monotone_id monotone_id)
        (comap_mono u.comp),
    is_open_uniformity :=
      fun s =>
        by 
          change @IsOpen α (u.to_topological_space.induced f) s ↔ _ 
          simp [is_open_iff_nhds, nhds_induced, mem_nhds_uniformity_iff_right, Filter.comap, and_comm]
          refine' ball_congr fun x hx => ⟨_, _⟩
          ·
            rintro ⟨t, hts, ht⟩
            refine' ⟨_, ht, _⟩
            rintro ⟨x₁, x₂⟩ h rfl 
            exact hts (h rfl)
          ·
            rintro ⟨t, ht, hts⟩
            exact
              ⟨{ y | (f x, y) ∈ t }, fun y hy => @hts (x, y) hy rfl,
                mem_nhds_uniformity_iff_right.1$ mem_nhds_left _ ht⟩ }

theorem uniformity_comap [UniformSpace α] [UniformSpace β] {f : α → β}
  (h : ‹UniformSpace α› = UniformSpace.comap f ‹UniformSpace β›) : 𝓤 α = comap (Prod.mapₓ f f) (𝓤 β) :=
  by 
    rw [h]
    rfl

theorem uniform_space_comap_id {α : Type _} : UniformSpace.comap (id : α → α) = id :=
  by 
    ext u <;> dsimp [UniformSpace.comap] <;> rw [Prod.id_prod, Filter.comap_id]

theorem UniformSpace.comap_comap {α β γ} [uγ : UniformSpace γ] {f : α → β} {g : β → γ} :
  UniformSpace.comap (g ∘ f) uγ = UniformSpace.comap f (UniformSpace.comap g uγ) :=
  by 
    ext <;> dsimp [UniformSpace.comap] <;> rw [Filter.comap_comap]

theorem uniform_continuous_iff {α β} [uα : UniformSpace α] [uβ : UniformSpace β] {f : α → β} :
  UniformContinuous f ↔ uα ≤ uβ.comap f :=
  Filter.map_le_iff_le_comap

theorem uniform_continuous_comap {f : α → β} [u : UniformSpace β] :
  @UniformContinuous α β (UniformSpace.comap f u) u f :=
  tendsto_comap

theorem to_topological_space_comap {f : α → β} {u : UniformSpace β} :
  @UniformSpace.toTopologicalSpace _ (UniformSpace.comap f u) =
    TopologicalSpace.induced f (@UniformSpace.toTopologicalSpace β u) :=
  rfl

theorem uniform_continuous_comap' {f : γ → β} {g : α → γ} [v : UniformSpace β] [u : UniformSpace α]
  (h : UniformContinuous (f ∘ g)) : @UniformContinuous α γ u (UniformSpace.comap f v) g :=
  tendsto_comap_iff.2 h

theorem to_nhds_mono {u₁ u₂ : UniformSpace α} (h : u₁ ≤ u₂) (a : α) :
  @nhds _ (@UniformSpace.toTopologicalSpace _ u₁) a ≤ @nhds _ (@UniformSpace.toTopologicalSpace _ u₂) a :=
  by 
    rw [@nhds_eq_uniformity α u₁ a, @nhds_eq_uniformity α u₂ a] <;> exact lift'_mono h le_rfl

theorem to_topological_space_mono {u₁ u₂ : UniformSpace α} (h : u₁ ≤ u₂) :
  @UniformSpace.toTopologicalSpace _ u₁ ≤ @UniformSpace.toTopologicalSpace _ u₂ :=
  le_of_nhds_le_nhds$ to_nhds_mono h

theorem UniformContinuous.continuous [UniformSpace α] [UniformSpace β] {f : α → β} (hf : UniformContinuous f) :
  Continuous f :=
  continuous_iff_le_induced.mpr$ to_topological_space_mono$ uniform_continuous_iff.1 hf

theorem to_topological_space_bot : @UniformSpace.toTopologicalSpace α ⊥ = ⊥ :=
  rfl

theorem to_topological_space_top : @UniformSpace.toTopologicalSpace α ⊤ = ⊤ :=
  top_unique$
    fun s hs =>
      s.eq_empty_or_nonempty.elim (fun this : s = ∅ => this.symm ▸ @is_open_empty _ ⊤)
        fun ⟨x, hx⟩ =>
          have  : s = univ := top_unique$ fun y hy => hs x hx (x, y) rfl 
          this.symm ▸ @is_open_univ _ ⊤

theorem to_topological_space_infi {ι : Sort _} {u : ι → UniformSpace α} :
  (infi u).toTopologicalSpace = ⨅i, (u i).toTopologicalSpace :=
  by 
    cases' is_empty_or_nonempty ι
    ·
      rw [infi_of_empty, infi_of_empty, to_topological_space_top]
    ·
      refine' eq_of_nhds_eq_nhds$ fun a => _ 
      rw [nhds_infi, nhds_eq_uniformity]
      change (infi u).uniformity.lift' (preimage$ Prod.mk a) = _ 
      rw [infi_uniformity, lift'_infi]
      ·
        simp only [nhds_eq_uniformity]
        rfl
      ·
        exact fun a b => rfl

theorem to_topological_space_Inf {s : Set (UniformSpace α)} :
  (Inf s).toTopologicalSpace = ⨅(i : _)(_ : i ∈ s), @UniformSpace.toTopologicalSpace α i :=
  by 
    rw [Inf_eq_infi]
    simp only [←to_topological_space_infi]

theorem to_topological_space_inf {u v : UniformSpace α} :
  (u⊓v).toTopologicalSpace = u.to_topological_space⊓v.to_topological_space :=
  by 
    rw [to_topological_space_Inf, infi_pair]

instance  : UniformSpace Empty :=
  ⊥

instance  : UniformSpace PUnit :=
  ⊥

instance  : UniformSpace Bool :=
  ⊥

instance  : UniformSpace ℕ :=
  ⊥

instance  : UniformSpace ℤ :=
  ⊥

instance  {p : α → Prop} [t : UniformSpace α] : UniformSpace (Subtype p) :=
  UniformSpace.comap Subtype.val t

theorem uniformity_subtype {p : α → Prop} [t : UniformSpace α] :
  𝓤 (Subtype p) = comap (fun q : Subtype p × Subtype p => (q.1.1, q.2.1)) (𝓤 α) :=
  rfl

theorem uniform_continuous_subtype_val {p : α → Prop} [UniformSpace α] :
  UniformContinuous (Subtype.val : { a : α // p a } → α) :=
  uniform_continuous_comap

theorem uniform_continuous_subtype_mk {p : α → Prop} [UniformSpace α] [UniformSpace β] {f : β → α}
  (hf : UniformContinuous f) (h : ∀ x, p (f x)) : UniformContinuous (fun x => ⟨f x, h x⟩ : β → Subtype p) :=
  uniform_continuous_comap' hf

theorem uniform_continuous_on_iff_restrict [UniformSpace α] [UniformSpace β] {f : α → β} {s : Set α} :
  UniformContinuousOn f s ↔ UniformContinuous (s.restrict f) :=
  by 
    unfold UniformContinuousOn Set.restrict UniformContinuous tendsto 
    rw
      [show (fun x : s × s => (f x.1, f x.2)) = (Prod.mapₓ f f ∘ coeₓ)by 
        ext x <;> cases x <;> rfl,
      uniformity_comap rfl,
      show Prod.mapₓ Subtype.val Subtype.val = (coeₓ : s × s → α × α)by 
        ext x <;> cases x <;> rfl]
    conv  in map _ (comap _ _) => rw [←Filter.map_map]
    rw [subtype_coe_map_comap_prod]
    rfl

theorem tendsto_of_uniform_continuous_subtype [UniformSpace α] [UniformSpace β] {f : α → β} {s : Set α} {a : α}
  (hf : UniformContinuous fun x : s => f x.val) (ha : s ∈ 𝓝 a) : tendsto f (𝓝 a) (𝓝 (f a)) :=
  by 
    rw [(@map_nhds_subtype_coe_eq α _ s a (mem_of_mem_nhds ha) ha).symm] <;>
      exact tendsto_map' (continuous_iff_continuous_at.mp hf.continuous _)

theorem UniformContinuousOn.continuous_on [UniformSpace α] [UniformSpace β] {f : α → β} {s : Set α}
  (h : UniformContinuousOn f s) : ContinuousOn f s :=
  by 
    rw [uniform_continuous_on_iff_restrict] at h 
    rw [continuous_on_iff_continuous_restrict]
    exact h.continuous

section Prod

instance  [u₁ : UniformSpace α] [u₂ : UniformSpace β] : UniformSpace (α × β) :=
  UniformSpace.ofCoreEq (u₁.comap Prod.fst⊓u₂.comap Prod.snd).toCore Prod.topologicalSpace
    (calc Prod.topologicalSpace = (u₁.comap Prod.fst⊓u₂.comap Prod.snd).toTopologicalSpace :=
      by 
        rw [to_topological_space_inf, to_topological_space_comap, to_topological_space_comap] <;> rfl 
      _ = _ :=
      by 
        rw [UniformSpace.to_core_to_topological_space]
      )

theorem uniformity_prod [UniformSpace α] [UniformSpace β] :
  𝓤 (α × β) =
    ((𝓤 α).comap fun p : (α × β) × α × β => (p.1.1, p.2.1))⊓(𝓤 β).comap fun p : (α × β) × α × β => (p.1.2, p.2.2) :=
  inf_uniformity

theorem uniformity_prod_eq_prod [UniformSpace α] [UniformSpace β] :
  𝓤 (α × β) = map (fun p : (α × α) × β × β => ((p.1.1, p.2.1), (p.1.2, p.2.2))) (𝓤 α ×ᶠ 𝓤 β) :=
  have  :
    (map fun p : (α × α) × β × β => ((p.1.1, p.2.1), (p.1.2, p.2.2))) =
      comap fun p : (α × β) × α × β => ((p.1.1, p.2.1), (p.1.2, p.2.2)) :=
    funext$ fun f => map_eq_comap_of_inverse (funext$ fun ⟨⟨_, _⟩, ⟨_, _⟩⟩ => rfl) (funext$ fun ⟨⟨_, _⟩, ⟨_, _⟩⟩ => rfl)
  by 
    rw [this, uniformity_prod, Filter.prod, comap_inf, comap_comap, comap_comap]

theorem mem_map_iff_exists_image' {α : Type _} {β : Type _} {f : Filter α} {m : α → β} {t : Set β} :
  t ∈ (map m f).Sets ↔ ∃ (s : _)(_ : s ∈ f), m '' s ⊆ t :=
  mem_map_iff_exists_image

theorem mem_uniformity_of_uniform_continuous_invariant [UniformSpace α] {s : Set (α × α)} {f : α → α → α}
  (hf : UniformContinuous fun p : α × α => f p.1 p.2) (hs : s ∈ 𝓤 α) :
  ∃ (u : _)(_ : u ∈ 𝓤 α), ∀ a b c, (a, b) ∈ u → (f a c, f b c) ∈ s :=
  by 
    rw [UniformContinuous, uniformity_prod_eq_prod, tendsto_map'_iff, · ∘ ·] at hf 
    rcases mem_map_iff_exists_image'.1 (hf hs) with ⟨t, ht, hts⟩
    clear hf 
    rcases mem_prod_iff.1 ht with ⟨u, hu, v, hv, huvt⟩
    clear ht 
    refine' ⟨u, hu, fun a b c hab => hts$ (mem_image _ _ _).2 ⟨⟨⟨a, b⟩, ⟨c, c⟩⟩, huvt ⟨_, _⟩, _⟩⟩
    exact hab 
    exact refl_mem_uniformity hv 
    rfl

theorem mem_uniform_prod [t₁ : UniformSpace α] [t₂ : UniformSpace β] {a : Set (α × α)} {b : Set (β × β)} (ha : a ∈ 𝓤 α)
  (hb : b ∈ 𝓤 β) : { p:(α × β) × α × β | (p.1.1, p.2.1) ∈ a ∧ (p.1.2, p.2.2) ∈ b } ∈ @uniformity (α × β) _ :=
  by 
    rw [uniformity_prod] <;> exact inter_mem_inf (preimage_mem_comap ha) (preimage_mem_comap hb)

theorem tendsto_prod_uniformity_fst [UniformSpace α] [UniformSpace β] :
  tendsto (fun p : (α × β) × α × β => (p.1.1, p.2.1)) (𝓤 (α × β)) (𝓤 α) :=
  le_transₓ (map_mono (@inf_le_left (UniformSpace (α × β)) _ _ _)) map_comap_le

theorem tendsto_prod_uniformity_snd [UniformSpace α] [UniformSpace β] :
  tendsto (fun p : (α × β) × α × β => (p.1.2, p.2.2)) (𝓤 (α × β)) (𝓤 β) :=
  le_transₓ (map_mono (@inf_le_right (UniformSpace (α × β)) _ _ _)) map_comap_le

theorem uniform_continuous_fst [UniformSpace α] [UniformSpace β] : UniformContinuous fun p : α × β => p.1 :=
  tendsto_prod_uniformity_fst

theorem uniform_continuous_snd [UniformSpace α] [UniformSpace β] : UniformContinuous fun p : α × β => p.2 :=
  tendsto_prod_uniformity_snd

variable[UniformSpace α][UniformSpace β][UniformSpace γ]

theorem UniformContinuous.prod_mk {f₁ : α → β} {f₂ : α → γ} (h₁ : UniformContinuous f₁) (h₂ : UniformContinuous f₂) :
  UniformContinuous fun a => (f₁ a, f₂ a) :=
  by 
    rw [UniformContinuous, uniformity_prod] <;> exact tendsto_inf.2 ⟨tendsto_comap_iff.2 h₁, tendsto_comap_iff.2 h₂⟩

theorem UniformContinuous.prod_mk_left {f : α × β → γ} (h : UniformContinuous f) b :
  UniformContinuous fun a => f (a, b) :=
  h.comp (uniform_continuous_id.prod_mk uniform_continuous_const)

theorem UniformContinuous.prod_mk_right {f : α × β → γ} (h : UniformContinuous f) a :
  UniformContinuous fun b => f (a, b) :=
  h.comp (uniform_continuous_const.prod_mk uniform_continuous_id)

theorem UniformContinuous.prod_map [UniformSpace δ] {f : α → γ} {g : β → δ} (hf : UniformContinuous f)
  (hg : UniformContinuous g) : UniformContinuous (Prod.mapₓ f g) :=
  (hf.comp uniform_continuous_fst).prod_mk (hg.comp uniform_continuous_snd)

theorem to_topological_space_prod {α} {β} [u : UniformSpace α] [v : UniformSpace β] :
  @UniformSpace.toTopologicalSpace (α × β) Prod.uniformSpace =
    @Prod.topologicalSpace α β u.to_topological_space v.to_topological_space :=
  rfl

end Prod

section 

open UniformSpace Function

variable{δ' : Type _}[UniformSpace α][UniformSpace β][UniformSpace γ][UniformSpace δ][UniformSpace δ']

local notation f "∘₂" g => Function.bicompr f g

/-- Uniform continuity for functions of two variables. -/
def UniformContinuous₂ (f : α → β → γ) :=
  UniformContinuous (uncurry f)

theorem uniform_continuous₂_def (f : α → β → γ) : UniformContinuous₂ f ↔ UniformContinuous (uncurry f) :=
  Iff.rfl

theorem UniformContinuous₂.uniform_continuous {f : α → β → γ} (h : UniformContinuous₂ f) :
  UniformContinuous (uncurry f) :=
  h

theorem uniform_continuous₂_curry (f : α × β → γ) : UniformContinuous₂ (Function.curry f) ↔ UniformContinuous f :=
  by 
    rw [UniformContinuous₂, uncurry_curry]

theorem UniformContinuous₂.comp {f : α → β → γ} {g : γ → δ} (hg : UniformContinuous g) (hf : UniformContinuous₂ f) :
  UniformContinuous₂ (g∘₂f) :=
  hg.comp hf

theorem UniformContinuous₂.bicompl {f : α → β → γ} {ga : δ → α} {gb : δ' → β} (hf : UniformContinuous₂ f)
  (hga : UniformContinuous ga) (hgb : UniformContinuous gb) : UniformContinuous₂ (bicompl f ga gb) :=
  hf.uniform_continuous.comp (hga.prod_map hgb)

end 

theorem to_topological_space_subtype [u : UniformSpace α] {p : α → Prop} :
  @UniformSpace.toTopologicalSpace (Subtype p) Subtype.uniformSpace =
    @Subtype.topologicalSpace α p u.to_topological_space :=
  rfl

section Sum

variable[UniformSpace α][UniformSpace β]

open Sum

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- Uniformity on a disjoint union. Entourages of the diagonal in the union are obtained
by taking independently an entourage of the diagonal in the first part, and an entourage of
the diagonal in the second part. -/ def uniform_space.core.sum : uniform_space.core «expr ⊕ »(α, β) :=
uniform_space.core.mk' «expr ⊔ »(map (λ
  p : «expr × »(α, α), (inl p.1, inl p.2)) (expr𝓤() α), map (λ
  p : «expr × »(β, β), (inr p.1, inr p.2)) (expr𝓤() β)) (λ
 (r)
 ⟨H₁, H₂⟩
 (x), by cases [expr x] []; [apply [expr refl_mem_uniformity H₁], apply [expr refl_mem_uniformity H₂]]) (λ
 (r)
 ⟨H₁, H₂⟩, ⟨symm_le_uniformity H₁, symm_le_uniformity H₂⟩) (λ (r) ⟨Hrα, Hrβ⟩, begin
   rcases [expr comp_mem_uniformity_sets Hrα, "with", "⟨", ident tα, ",", ident htα, ",", ident Htα, "⟩"],
   rcases [expr comp_mem_uniformity_sets Hrβ, "with", "⟨", ident tβ, ",", ident htβ, ",", ident Htβ, "⟩"],
   refine [expr ⟨_, ⟨mem_map_iff_exists_image.2 ⟨tα, htα, subset_union_left _ _⟩, mem_map_iff_exists_image.2 ⟨tβ, htβ, subset_union_right _ _⟩⟩, _⟩],
   rintros ["⟨", "_", ",", "_", "⟩", "⟨", ident z, ",", "⟨", "⟨", ident a, ",", ident b, "⟩", ",", ident hab, ",", "⟨", "⟩", "⟩", "|", "⟨", "⟨", ident a, ",", ident b, "⟩", ",", ident hab, ",", "⟨", "⟩", "⟩", ",", "⟨", "⟨", "_", ",", ident c, "⟩", ",", ident hbc, ",", "⟨", "⟩", "⟩", "|", "⟨", "⟨", "_", ",", ident c, "⟩", ",", ident hbc, ",", "⟨", "⟩", "⟩", "⟩"],
   { have [ident A] [":", expr «expr ∈ »((a, c), «expr ○ »(tα, tα))] [":=", expr ⟨b, hab, hbc⟩],
     exact [expr Htα A] },
   { have [ident A] [":", expr «expr ∈ »((a, c), «expr ○ »(tβ, tβ))] [":=", expr ⟨b, hab, hbc⟩],
     exact [expr Htβ A] }
 end)

/-- The union of an entourage of the diagonal in each set of a disjoint union is again an entourage
of the diagonal. -/
theorem union_mem_uniformity_sum {a : Set (α × α)} (ha : a ∈ 𝓤 α) {b : Set (β × β)} (hb : b ∈ 𝓤 β) :
  (fun p : α × α => (inl p.1, inl p.2)) '' a ∪ (fun p : β × β => (inr p.1, inr p.2)) '' b ∈
    (@UniformSpace.Core.sum α β _ _).uniformity :=
  ⟨mem_map_iff_exists_image.2 ⟨_, ha, subset_union_left _ _⟩,
    mem_map_iff_exists_image.2 ⟨_, hb, subset_union_right _ _⟩⟩

theorem uniformity_sum_of_open_aux {s : Set (Sum α β)} (hs : IsOpen s) {x : Sum α β} (xs : x ∈ s) :
  { p:Sum α β × Sum α β | p.1 = x → p.2 ∈ s } ∈ (@UniformSpace.Core.sum α β _ _).uniformity :=
  by 
    cases x
    ·
      refine'
          mem_of_superset
            (union_mem_uniformity_sum (mem_nhds_uniformity_iff_right.1 (IsOpen.mem_nhds hs.1 xs)) univ_mem)
            (union_subset _ _) <;>
        rintro _ ⟨⟨_, b⟩, h, ⟨⟩⟩ ⟨⟩
      exact h rfl
    ·
      refine'
          mem_of_superset
            (union_mem_uniformity_sum univ_mem (mem_nhds_uniformity_iff_right.1 (IsOpen.mem_nhds hs.2 xs)))
            (union_subset _ _) <;>
        rintro _ ⟨⟨a, _⟩, h, ⟨⟩⟩ ⟨⟩
      exact h rfl

theorem open_of_uniformity_sum_aux {s : Set (Sum α β)}
  (hs : ∀ x _ : x ∈ s, { p:Sum α β × Sum α β | p.1 = x → p.2 ∈ s } ∈ (@UniformSpace.Core.sum α β _ _).uniformity) :
  IsOpen s :=
  by 
    split 
    ·
      refine' (@is_open_iff_mem_nhds α _ _).2 fun a ha => mem_nhds_uniformity_iff_right.2 _ 
      rcases mem_map_iff_exists_image.1 (hs _ ha).1 with ⟨t, ht, st⟩
      refine' mem_of_superset ht _ 
      rintro p pt rfl 
      exact st ⟨_, pt, rfl⟩ rfl
    ·
      refine' (@is_open_iff_mem_nhds β _ _).2 fun b hb => mem_nhds_uniformity_iff_right.2 _ 
      rcases mem_map_iff_exists_image.1 (hs _ hb).2 with ⟨t, ht, st⟩
      refine' mem_of_superset ht _ 
      rintro p pt rfl 
      exact st ⟨_, pt, rfl⟩ rfl

instance Sum.uniformSpace : UniformSpace (Sum α β) :=
  { toCore := UniformSpace.Core.sum,
    is_open_uniformity := fun s => ⟨uniformity_sum_of_open_aux, open_of_uniformity_sum_aux⟩ }

theorem Sum.uniformity :
  𝓤 (Sum α β) = map (fun p : α × α => (inl p.1, inl p.2)) (𝓤 α)⊔map (fun p : β × β => (inr p.1, inr p.2)) (𝓤 β) :=
  rfl

end Sum

end Constructions

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- Let `c : ι → set α` be an open cover of a compact set `s`. Then there exists an entourage
`n` such that for each `x ∈ s` its `n`-neighborhood is contained in some `c i`. -/
theorem lebesgue_number_lemma
{α : Type u}
[uniform_space α]
{s : set α}
{ι}
{c : ι → set α}
(hs : is_compact s)
(hc₁ : ∀ i, is_open (c i))
(hc₂ : «expr ⊆ »(s, «expr⋃ , »((i), c i))) : «expr∃ , »((n «expr ∈ » expr𝓤() α), ∀
 x «expr ∈ » s, «expr∃ , »((i), «expr ⊆ »({y | «expr ∈ »((x, y), n)}, c i))) :=
begin
  let [ident u] [] [":=", expr λ
   n, {x | «expr∃ , »((i) (m «expr ∈ » expr𝓤() α), «expr ⊆ »({y | «expr ∈ »((x, y), «expr ○ »(m, n))}, c i))}],
  have [ident hu₁] [":", expr ∀ n «expr ∈ » expr𝓤() α, is_open (u n)] [],
  { refine [expr λ n hn, is_open_uniformity.2 _],
    rintro [ident x, "⟨", ident i, ",", ident m, ",", ident hm, ",", ident h, "⟩"],
    rcases [expr comp_mem_uniformity_sets hm, "with", "⟨", ident m', ",", ident hm', ",", ident mm', "⟩"],
    apply [expr (expr𝓤() α).sets_of_superset hm'],
    rintros ["⟨", ident x, ",", ident y, "⟩", ident hp, ident rfl],
    refine [expr ⟨i, m', hm', λ z hz, h (monotone_comp_rel monotone_id monotone_const mm' _)⟩],
    dsimp [] [] [] ["at", ident hz, "⊢"],
    rw [expr comp_rel_assoc] [],
    exact [expr ⟨y, hp, hz⟩] },
  have [ident hu₂] [":", expr «expr ⊆ »(s, «expr⋃ , »((n «expr ∈ » expr𝓤() α), u n))] [],
  { intros [ident x, ident hx],
    rcases [expr mem_Union.1 (hc₂ hx), "with", "⟨", ident i, ",", ident h, "⟩"],
    rcases [expr comp_mem_uniformity_sets (is_open_uniformity.1 (hc₁ i) x h), "with", "⟨", ident m', ",", ident hm', ",", ident mm', "⟩"],
    exact [expr mem_bUnion hm' ⟨i, _, hm', λ y hy, mm' hy rfl⟩] },
  rcases [expr hs.elim_finite_subcover_image hu₁ hu₂, "with", "⟨", ident b, ",", ident bu, ",", ident b_fin, ",", ident b_cover, "⟩"],
  refine [expr ⟨_, (bInter_mem b_fin).2 bu, λ x hx, _⟩],
  rcases [expr mem_bUnion_iff.1 (b_cover hx), "with", "⟨", ident n, ",", ident bn, ",", ident i, ",", ident m, ",", ident hm, ",", ident h, "⟩"],
  refine [expr ⟨i, λ y hy, h _⟩],
  exact [expr prod_mk_mem_comp_rel (refl_mem_uniformity hm) (bInter_subset_of_mem bn hy)]
end

/-- Let `c : set (set α)` be an open cover of a compact set `s`. Then there exists an entourage
`n` such that for each `x ∈ s` its `n`-neighborhood is contained in some `t ∈ c`. -/
theorem lebesgue_number_lemma_sUnion {α : Type u} [UniformSpace α] {s : Set α} {c : Set (Set α)} (hs : IsCompact s)
  (hc₁ : ∀ t _ : t ∈ c, IsOpen t) (hc₂ : s ⊆ ⋃₀c) :
  ∃ (n : _)(_ : n ∈ 𝓤 α), ∀ x _ : x ∈ s, ∃ (t : _)(_ : t ∈ c), ∀ y, (x, y) ∈ n → y ∈ t :=
  by 
    rw [sUnion_eq_Union] at hc₂ <;>
      simpa using
        lebesgue_number_lemma hs
          (by 
            simpa)
          hc₂

-- error in Topology.UniformSpace.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- A useful consequence of the Lebesgue number lemma: given any compact set `K` contained in an
open set `U`, we can find an (open) entourage `V` such that the ball of size `V` about any point of
`K` is contained in `U`. -/
theorem lebesgue_number_of_compact_open
[uniform_space α]
{K U : set α}
(hK : is_compact K)
(hU : is_open U)
(hKU : «expr ⊆ »(K, U)) : «expr∃ , »((V «expr ∈ » expr𝓤() α), «expr ∧ »(is_open V, ∀
  x «expr ∈ » K, «expr ⊆ »(uniform_space.ball x V, U))) :=
begin
  let [ident W] [":", expr K → set «expr × »(α, α)] [":=", expr λ
   k, «expr $ »(classical.some, «expr $ »(is_open_iff_open_ball_subset.mp hU k.1, hKU k.2))],
  have [ident hW] [":", expr ∀
   k, «expr ∧ »(«expr ∈ »(W k, expr𝓤() α), «expr ∧ »(is_open (W k), «expr ⊆ »(uniform_space.ball k.1 (W k), U)))] [],
  { intros [ident k],
    obtain ["⟨", ident h₁, ",", ident h₂, ",", ident h₃, "⟩", ":=", expr classical.some_spec (is_open_iff_open_ball_subset.mp hU k.1 (hKU k.2))],
    exact [expr ⟨h₁, h₂, h₃⟩] },
  let [ident c] [":", expr K → set α] [":=", expr λ k, uniform_space.ball k.1 (W k)],
  have [ident hc₁] [":", expr ∀ k, is_open (c k)] [],
  { exact [expr λ k, uniform_space.is_open_ball k.1 (hW k).2.1] },
  have [ident hc₂] [":", expr «expr ⊆ »(K, «expr⋃ , »((i), c i))] [],
  { intros [ident k, ident hk],
    simp [] [] ["only"] ["[", expr mem_Union, ",", expr set_coe.exists, "]"] [] [],
    exact [expr ⟨k, hk, uniform_space.mem_ball_self k (hW ⟨k, hk⟩).1⟩] },
  have [ident hc₃] [":", expr ∀ k, «expr ⊆ »(c k, U)] [],
  { exact [expr λ k, (hW k).2.2] },
  obtain ["⟨", ident V, ",", ident hV, ",", ident hV', "⟩", ":=", expr lebesgue_number_lemma hK hc₁ hc₂],
  refine [expr ⟨interior V, interior_mem_uniformity hV, is_open_interior, _⟩],
  intros [ident k, ident hk],
  obtain ["⟨", ident k', ",", ident hk', "⟩", ":=", expr hV' k hk],
  exact [expr ((ball_mono interior_subset k).trans hk').trans (hc₃ k')]
end

/-!
### Expressing continuity properties in uniform spaces

We reformulate the various continuity properties of functions taking values in a uniform space
in terms of the uniformity in the target. Since the same lemmas (essentially with the same names)
also exist for metric spaces and emetric spaces (reformulating things in terms of the distance or
the edistance in the target), we put them in a namespace `uniform` here.

In the metric and emetric space setting, there are also similar lemmas where one assumes that
both the source and the target are metric spaces, reformulating things in terms of the distance
on both sides. These lemmas are generally written without primes, and the versions where only
the target is a metric space is primed. We follow the same convention here, thus giving lemmas
with primes.
-/


namespace Uniform

variable[UniformSpace α]

theorem tendsto_nhds_right {f : Filter β} {u : β → α} {a : α} :
  tendsto u f (𝓝 a) ↔ tendsto (fun x => (a, u x)) f (𝓤 α) :=
  ⟨fun H => tendsto_left_nhds_uniformity.comp H,
    fun H s hs =>
      by 
        simpa [mem_of_mem_nhds hs] using H (mem_nhds_uniformity_iff_right.1 hs)⟩

theorem tendsto_nhds_left {f : Filter β} {u : β → α} {a : α} :
  tendsto u f (𝓝 a) ↔ tendsto (fun x => (u x, a)) f (𝓤 α) :=
  ⟨fun H => tendsto_right_nhds_uniformity.comp H,
    fun H s hs =>
      by 
        simpa [mem_of_mem_nhds hs] using H (mem_nhds_uniformity_iff_left.1 hs)⟩

theorem continuous_at_iff'_right [TopologicalSpace β] {f : β → α} {b : β} :
  ContinuousAt f b ↔ tendsto (fun x => (f b, f x)) (𝓝 b) (𝓤 α) :=
  by 
    rw [ContinuousAt, tendsto_nhds_right]

theorem continuous_at_iff'_left [TopologicalSpace β] {f : β → α} {b : β} :
  ContinuousAt f b ↔ tendsto (fun x => (f x, f b)) (𝓝 b) (𝓤 α) :=
  by 
    rw [ContinuousAt, tendsto_nhds_left]

theorem continuous_at_iff_prod [TopologicalSpace β] {f : β → α} {b : β} :
  ContinuousAt f b ↔ tendsto (fun x : β × β => (f x.1, f x.2)) (𝓝 (b, b)) (𝓤 α) :=
  ⟨fun H => le_transₓ (H.prod_map' H) (nhds_le_uniformity _),
    fun H => continuous_at_iff'_left.2$ H.comp$ tendsto_id.prod_mk_nhds tendsto_const_nhds⟩

theorem continuous_within_at_iff'_right [TopologicalSpace β] {f : β → α} {b : β} {s : Set β} :
  ContinuousWithinAt f s b ↔ tendsto (fun x => (f b, f x)) (𝓝[s] b) (𝓤 α) :=
  by 
    rw [ContinuousWithinAt, tendsto_nhds_right]

theorem continuous_within_at_iff'_left [TopologicalSpace β] {f : β → α} {b : β} {s : Set β} :
  ContinuousWithinAt f s b ↔ tendsto (fun x => (f x, f b)) (𝓝[s] b) (𝓤 α) :=
  by 
    rw [ContinuousWithinAt, tendsto_nhds_left]

theorem continuous_on_iff'_right [TopologicalSpace β] {f : β → α} {s : Set β} :
  ContinuousOn f s ↔ ∀ b _ : b ∈ s, tendsto (fun x => (f b, f x)) (𝓝[s] b) (𝓤 α) :=
  by 
    simp [ContinuousOn, continuous_within_at_iff'_right]

theorem continuous_on_iff'_left [TopologicalSpace β] {f : β → α} {s : Set β} :
  ContinuousOn f s ↔ ∀ b _ : b ∈ s, tendsto (fun x => (f x, f b)) (𝓝[s] b) (𝓤 α) :=
  by 
    simp [ContinuousOn, continuous_within_at_iff'_left]

theorem continuous_iff'_right [TopologicalSpace β] {f : β → α} :
  Continuous f ↔ ∀ b, tendsto (fun x => (f b, f x)) (𝓝 b) (𝓤 α) :=
  continuous_iff_continuous_at.trans$ forall_congrₓ$ fun b => tendsto_nhds_right

theorem continuous_iff'_left [TopologicalSpace β] {f : β → α} :
  Continuous f ↔ ∀ b, tendsto (fun x => (f x, f b)) (𝓝 b) (𝓤 α) :=
  continuous_iff_continuous_at.trans$ forall_congrₓ$ fun b => tendsto_nhds_left

end Uniform

theorem Filter.Tendsto.congr_uniformity {α β} [UniformSpace β] {f g : α → β} {l : Filter α} {b : β}
  (hf : tendsto f l (𝓝 b)) (hg : tendsto (fun x => (f x, g x)) l (𝓤 β)) : tendsto g l (𝓝 b) :=
  Uniform.tendsto_nhds_right.2$ (Uniform.tendsto_nhds_right.1 hf).uniformity_trans hg

theorem Uniform.tendsto_congr {α β} [UniformSpace β] {f g : α → β} {l : Filter α} {b : β}
  (hfg : tendsto (fun x => (f x, g x)) l (𝓤 β)) : tendsto f l (𝓝 b) ↔ tendsto g l (𝓝 b) :=
  ⟨fun h => h.congr_uniformity hfg, fun h => h.congr_uniformity hfg.uniformity_symm⟩

