/-
Copyright (c) 2022 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anatole Dedecker
-/
import Mathbin.Topology.UniformSpace.UniformConvergence
import Mathbin.Topology.UniformSpace.Pi
import Mathbin.Topology.UniformSpace.Equiv

/-!
# Topology and uniform structure of uniform convergence

This files endows `α → β` with the topologies / uniform structures of
- uniform convergence on `α` (in the `uniform_convergence` namespace)
- uniform convergence on a specified family `𝔖` of sets of `α`
  (in the `uniform_convergence_on` namespace), also called `𝔖`-convergence

Usual examples of the second construction include :
- the topology of compact convergence, when `𝔖` is the set of compacts of `α`
- the strong topology on the dual of a topological vector space (TVS) `E`, when `𝔖` is the set of
  Von Neuman bounded subsets of `E`
- the weak-* topology on the dual of a TVS `E`, when `𝔖` is the set of singletons of `E`.

This file contains a lot of technical facts, so it is heavily commented, proofs included!

## Main definitions

* `uniform_convergence.gen`: basis sets for the uniformity of uniform convergence. These are sets
  of the form `S(V) := {(f, g) | ∀ x : α, (f x, g x) ∈ V}` for some `V : set (β × β)`
* `uniform_convergence.uniform_space`: uniform structure of uniform convergence. This is the
  `uniform_space` on `α → β` whose uniformity is generated by the sets `S(V)` for `V ∈ 𝓤 β`.
  We will denote this uniform space as `𝒰(α, β, uβ)`, both in the comments and as a local notation
  in the Lean code, where `uβ` is the uniform space structure on `β`.
* `uniform_convergence_on.uniform_space`: uniform structure of 𝔖-convergence, where
  `𝔖 : set (set α)`. This is the infimum, for `S ∈ 𝔖`, of the pullback of `𝒰 S β` by the map of
  restriction to `S`. We will denote it `𝒱(α, β, 𝔖, uβ)`, where `uβ` is the uniform space structure
  on `β`.

## Main statements

### Basic properties

* `uniform_convergence.uniform_continuous_eval`: evaluation is uniformly continuous for `𝒰(α, uβ)`.
* `uniform_convergence.t2_space`: the topology of uniform convergence on `α → β` is T₂ if
  `β` is T₂.
* `uniform_convergence.tendsto_iff_tendsto_uniformly`: `𝒰(α, β, uβ)` is
  indeed the uniform structure of uniform convergence
* `uniform_convergence_on.uniform_continuous_eval_of_mem`: evaluation at a point contained in a
  set of `𝔖` is uniformly continuous for `𝒱(α, β, 𝔖 uβ)`
* `uniform_convergence.t2_space`: the topology of `𝔖`-convergence on `α → β` is T₂ if
  `β` is T₂ and `𝔖` covers `α`
* `uniform_convergence_on.tendsto_iff_tendsto_uniformly_on`:
  `𝒱(α, β, 𝔖 uβ)` is indeed the uniform structure of `𝔖`-convergence

### Functoriality and compatibility with product of uniform spaces

In order to avoid the need for filter bases as much as possible when using these definitions,
we develop an extensive API for manipulating these structures abstractly. As usual in the topology
section of mathlib, we first state results about the complete lattices of `uniform_space`s on
fixed types, and then we use these to deduce categorical-like results about maps between two
uniform spaces.

We only describe these in the harder case of `𝔖`-convergence, as the names of the corresponding
results for uniform convergence can easily be guessed.

#### Order statements

* `uniform_convergence_on.mono`: let `u₁`, `u₂` be two uniform structures on `γ` and
  `𝔖₁ 𝔖₂ : set (set α)`. If `u₁ ≤ u₂` and `𝔖₂ ⊆ 𝔖₁` then `𝒱(α, γ, 𝔖₁, u₁) ≤ 𝒱(α, γ, 𝔖₂, u₂)`.
* `uniform_convergence_on.infi_eq`: if `u` is a family of uniform structures on `γ`, then
  `𝒱(α, γ, 𝔖, (⨅ i, u i)) = ⨅ i, 𝒱(α, γ, 𝔖, u i)`.
* `uniform_convergence_on.comap_eq`: if `u` is a uniform structures on `β` and `f : γ → β`, then
  `𝒱(α, γ, 𝔖, comap f u) = comap (λ g, f ∘ g) 𝒱(α, γ, 𝔖, u₁)`.

An interesting note about these statements is that they are proved without ever unfolding the basis
definition of the uniform structure of uniform convergence! Instead, we build a
(not very interesting) Galois connection `uniform_convergence.gc` and then rely on the Galois
connection API to do most of the work.

#### Morphism statements (unbundled)

* `uniform_convergence_on.postcomp_uniform_continuous`: if `f : (γ, uγ) → (β, uβ)` is uniformly
  continuous, then `(λ g, f ∘ g) : (α → γ, 𝒱(α, γ, 𝔖, uγ)) → (α → β, 𝒱(α, β, 𝔖, uβ))` is
  uniformly continuous.
* `uniform_convergence_on.postcomp_uniform_inducing`: if `f : (γ, uγ) → (β, uβ)` is a uniform
  inducing, then `(λ g, f ∘ g) : (α → γ, 𝒱(α, γ, 𝔖, uγ)) → (α → β, 𝒱(α, β, 𝔖, uβ))` is a
  uniform inducing.
* `uniform_convergence_on.precomp_uniform_continuous`: let `f : γ → α`, `𝔖 : set (set α)`,
  `𝔗 : set (set γ)`, and assume that `∀ T ∈ 𝔗, f '' T ∈ 𝔖`. Then, the function
  `(λ g, g ∘ f) : (α → β, 𝒱(α, β, 𝔖, uβ)) → (γ → β, 𝒱(γ, β, 𝔗 uβ))` is uniformly continuous.

#### Isomorphism statements (bundled)

* `uniform_convergence_on.congr_right`: turn a uniform isomorphism `(γ, uγ) ≃ᵤ (β, uβ)` into a
  uniform isomorphism `(α → γ, 𝒱(α, γ, 𝔖, uγ)) ≃ᵤ (α → β, 𝒱(α, β, 𝔖, uβ))` by post-composing.
* `uniform_convergence_on.congr_left`: turn a bijection `e : γ ≃ α` such that we have both
  `∀ T ∈ 𝔗, e '' T ∈ 𝔖` and `∀ S ∈ 𝔖, e ⁻¹' S ∈ 𝔗` into a uniform isomorphism
  `(γ → β, 𝒰(γ, β, uβ)) ≃ᵤ (α → β, 𝒰(α, β, uβ))` by pre-composing.
* `uniform_convergence_on.uniform_equiv_Pi_comm`: the natural bijection between `α → Π i, δ i`
  and `Π i, α → δ i`, upgraded to a uniform isomorphism between
  `(α → (Π i, δ i), 𝒱(α, (Π i, δ i), 𝔖, (Π i, uδ i)))` and
  `((Π i, α → δ i), (Π i, 𝒱(α, δ i, 𝔖, uδ i)))`.

#### Important use cases

* If `(G, uG)` is a uniform group, then `(α → G, 𝒱(α, G, 𝔖, uG))` is a uniform group: since
  `(/) : G × G → G` is uniformly continuous, `uniform_convergence_on.postcomp_uniform_continuous`
  tells us that `((/) ∘ —) : (α → G × G) → (α → G)` is uniformly continuous. By precomposing with
  `uniform_convergence_on.uniform_equiv_prod_arrow`, this gives that
  `(/) : (α → G) × (α → G) → (α → G)` is also uniformly continuous
* The transpose of a continuous linear map is continuous for the strong topologies: since
  continuous linear maps are uniformly continuous and map bounded sets to bounded sets,
  this is just a special case of `uniform_convergence_on.precomp_uniform_continuous`.

## Implementation details

We do not declare these structures as instances, since they would conflict with `Pi.uniform_space`.

## TODO

* Show that the uniform structure of `𝔖`-convergence is exactly the structure of `𝔖'`-convergence,
  where `𝔖'` is the ***noncovering*** bornology (i.e ***not*** what `bornology` currently refers
  to in mathlib) generated by `𝔖`.
* Add a type synonym for `α → β` endowed with the structures of uniform convergence?

## References

* [N. Bourbaki, *General Topology, Chapter X*][bourbaki1966]

## Tags

uniform convergence
-/


noncomputable section

open TopologicalSpace Classical uniformity Filter

attribute [-instance] Pi.uniformSpace

attribute [-instance] Pi.topologicalSpace

open Set Filter

namespace UniformConvergence

variable (α β : Type _) {γ ι : Type _}

variable {F : ι → α → β} {f : α → β} {s s' : Set α} {x : α} {p : Filter ι} {g : ι → α}

/-- Basis sets for the uniformity of uniform convergence: `gen α β V` is the set of pairs `(f, g)`
of functions `α → β` such that `∀ x, (f x, g x) ∈ V`. -/
protected def Gen (V : Set (β × β)) : Set ((α → β) × (α → β)) :=
  { uv : (α → β) × (α → β) | ∀ x, (uv.1 x, uv.2 x) ∈ V }

/-- If `𝓕` is a filter on `β × β`, then the set of all `uniform_convergence.gen α β V` for
`V ∈ 𝓕` is too. This will only be applied to `𝓕 = 𝓤 β` when `β` is equipped with a `uniform_space`
structure, but it is useful to define it for any filter in order to be able to state that it
has a lower adjoint (see `uniform_convergence.gc`). -/
protected theorem is_basis_gen (𝓑 : Filter <| β × β) :
    IsBasis (fun V : Set (β × β) => V ∈ 𝓑) (UniformConvergence.Gen α β) :=
  ⟨⟨Univ, univ_mem⟩, fun U V hU hV =>
    ⟨U ∩ V, inter_mem hU hV, fun uv huv => ⟨fun x => (huv x).left, fun x => (huv x).right⟩⟩⟩

/-- For `𝓕 : filter (β × β)`, this is the set of all `uniform_convergence.gen α β V` for
`V ∈ 𝓕` is as a bundled `filter_basis`. This will only be applied to `𝓕 = 𝓤 β` when `β` is
equipped with a `uniform_space` structure, but it is useful to define it for any filter in order
to be able to state that it has a lower adjoint (see `uniform_convergence.gc`). -/
protected def basis (𝓕 : Filter <| β × β) : FilterBasis ((α → β) × (α → β)) :=
  (UniformConvergence.is_basis_gen α β 𝓕).FilterBasis

/-- For `𝓕 : filter (β × β)`, this is the filter generated by the filter basis
`uniform_convergence.basis α β 𝓕`. For `𝓕 = 𝓤 β`, this will be the uniformity of uniform
convergence on `α`. -/
protected def filter (𝓕 : Filter <| β × β) : Filter ((α → β) × (α → β)) :=
  (UniformConvergence.basis α β 𝓕).filter

-- mathport name: exprΦ
local notation "Φ" => fun (α β : Type _) (uvx : ((α → β) × (α → β)) × α) => (uvx.1.1 uvx.2, uvx.1.2 uvx.2)

-- mathport name: exprlower_adjoint
/- This is a lower adjoint to `uniform_convergence.filter` (see `uniform_convergence.gc`).
The exact definition of the lower adjoint `l` is not interesting; we will only use that it exists
(in `uniform_convergence.mono` and `uniform_convergence.infi_eq`) and that
`l (filter.map (prod.map f f) 𝓕) = filter.map (prod.map ((∘) f) ((∘) f)) (l 𝓕)` for each
`𝓕 : filter (γ × γ)` and `f : γ → α` (in `uniform_convergence.comap_eq`). -/
local notation "lower_adjoint" => fun 𝓐 => map (Φ α β) (𝓐 ×ᶠ ⊤)

/-- The function `uniform_convergence.filter α β : filter (β × β) → filter ((α → β) × (α → β))`
has a lower adjoint `l` (in the sense of `galois_connection`). The exact definition of `l` is not
interesting; we will only use that it exists (in `uniform_convergence.mono` and
`uniform_convergence.infi_eq`) and that
`l (filter.map (prod.map f f) 𝓕) = filter.map (prod.map ((∘) f) ((∘) f)) (l 𝓕)` for each
`𝓕 : filter (γ × γ)` and `f : γ → α` (in `uniform_convergence.comap_eq`). -/
protected theorem gc : GaloisConnection lower_adjoint fun 𝓕 => UniformConvergence.filter α β 𝓕 := by
  intro 𝓐 𝓕
  symm
  calc
    𝓐 ≤ UniformConvergence.filter α β 𝓕 ↔ (UniformConvergence.basis α β 𝓕).Sets ⊆ 𝓐.sets := by
      rw [UniformConvergence.filter, ← FilterBasis.generate, sets_iff_generate]
    _ ↔ ∀ U ∈ 𝓕, UniformConvergence.Gen α β U ∈ 𝓐 := image_subset_iff
    _ ↔ ∀ U ∈ 𝓕, { uv | ∀ x, (uv, x) ∈ { t : ((α → β) × (α → β)) × α | (t.1.1 t.2, t.1.2 t.2) ∈ U } } ∈ 𝓐 := Iff.rfl
    _ ↔ ∀ U ∈ 𝓕, { uvx : ((α → β) × (α → β)) × α | (uvx.1.1 uvx.2, uvx.1.2 uvx.2) ∈ U } ∈ 𝓐 ×ᶠ (⊤ : Filter α) :=
      forall₂_congrₓ fun U hU => mem_prod_top.symm
    _ ↔ lower_adjoint 𝓐 ≤ 𝓕 := Iff.rfl
    

variable [UniformSpace β]

/-- Core of the uniform structure of uniform convergence. -/
protected def uniformCore : UniformSpace.Core (α → β) :=
  UniformSpace.Core.mkOfBasis (UniformConvergence.basis α β (𝓤 β))
    (fun U ⟨V, hV, hVU⟩ f => hVU ▸ fun x => refl_mem_uniformity hV)
    (fun U ⟨V, hV, hVU⟩ =>
      hVU ▸
        ⟨UniformConvergence.Gen α β (Prod.swap ⁻¹' V), ⟨Prod.swap ⁻¹' V, tendsto_swap_uniformity hV, rfl⟩,
          fun uv huv x => huv x⟩)
    fun U ⟨V, hV, hVU⟩ =>
    hVU ▸
      let ⟨W, hW, hWV⟩ := comp_mem_uniformity_sets hV
      ⟨UniformConvergence.Gen α β W, ⟨W, hW, rfl⟩, fun uv ⟨w, huw, hwv⟩ x => hWV ⟨w x, ⟨huw x, hwv x⟩⟩⟩

/-- Uniform structure of uniform convergence. We will denote it `𝒰(α, β, uβ)`. -/
protected def uniformSpace : UniformSpace (α → β) :=
  UniformSpace.ofCore (UniformConvergence.uniformCore α β)

attribute [local instance] UniformConvergence.uniformSpace

-- mathport name: «expr𝒰( , , )»
local notation "𝒰(" α "," β "," u ")" => @UniformConvergence.uniformSpace α β u

/-- By definition, the uniformity of `α → β` endowed with the structure of uniform convergence on
`α` admits the family `{(f, g) | ∀ x, (f x, g x) ∈ V}` for `V ∈ 𝓤 β` as a filter basis. -/
protected theorem has_basis_uniformity : (𝓤 (α → β)).HasBasis (fun V => V ∈ 𝓤 β) (UniformConvergence.Gen α β) :=
  (UniformConvergence.is_basis_gen α β (𝓤 β)).HasBasis

/-- Topology of uniform convergence. -/
protected def topologicalSpace : TopologicalSpace (α → β) :=
  𝒰(α,β,inferInstance).toTopologicalSpace

/-- If `α → β` is endowed with the topology of uniform convergence, `𝓝 f` admits the family
`{g | ∀ x, (f x, g x) ∈ V}` for `V ∈ 𝓤 β` as a filter basis. -/
protected theorem has_basis_nhds :
    (𝓝 f).HasBasis (fun V => V ∈ 𝓤 β) fun V => { g | (f, g) ∈ UniformConvergence.Gen α β V } :=
  nhds_basis_uniformity' (UniformConvergence.has_basis_uniformity α β)

variable {α}

/-- Evaluation at a fixed point is uniformly continuous for `𝒰(α, β, uβ)`. -/
theorem uniform_continuous_eval (x : α) : UniformContinuous (Function.eval x : (α → β) → β) := by
  change _ ≤ _
  rw [map_le_iff_le_comap, (UniformConvergence.has_basis_uniformity α β).le_basis_iff ((𝓤 _).basis_sets.comap _)]
  exact fun U hU => ⟨U, hU, fun uv huv => huv x⟩

variable {β}

/-- If `u₁` and `u₂` are two uniform structures on `γ` and `u₁ ≤ u₂`, then
`𝒰(α, γ, u₁) ≤ 𝒰(α, γ, u₂)`. -/
protected theorem mono : Monotone (@UniformConvergence.uniformSpace α γ) := fun u₁ u₂ hu =>
  (UniformConvergence.gc α γ).monotone_u hu

/-- If `u` is a family of uniform structures on `γ`, then
`𝒰(α, γ, (⨅ i, u i)) = ⨅ i, 𝒰(α, γ, u i)`. -/
protected theorem infi_eq {u : ι → UniformSpace γ} : 𝒰(α,γ,⨅ i, u i) = ⨅ i, 𝒰(α,γ,u i) := by
  -- This follows directly from the fact that the upper adjoint in a Galois connection maps
  -- infimas to infimas.
  ext : 1
  change UniformConvergence.filter α γ (@uniformity _ (⨅ i, u i)) = @uniformity _ (⨅ i, 𝒰(α,γ,u i))
  rw [infi_uniformity', infi_uniformity']
  exact (UniformConvergence.gc α γ).u_infi

/-- If `u₁` and `u₂` are two uniform structures on `γ`, then
`𝒰(α, γ, u₁ ⊓ u₂) = 𝒰(α, γ, u₁) ⊓ 𝒰(α, γ, u₂)`. -/
protected theorem inf_eq {u₁ u₂ : UniformSpace γ} : 𝒰(α,γ,u₁⊓u₂) = 𝒰(α,γ,u₁)⊓𝒰(α,γ,u₂) := by
  -- This follows directly from the fact that the upper adjoint in a Galois connection maps
  -- infimas to infimas.
  rw [inf_eq_infi, inf_eq_infi, UniformConvergence.infi_eq]
  refine' infi_congr fun i => _
  cases i <;> rfl

/-- If `u` is a uniform structures on `β` and `f : γ → β`, then
`𝒰(α, γ, comap f u) = comap (λ g, f ∘ g) 𝒰(α, γ, u₁)`. -/
protected theorem comap_eq {f : γ → β} : 𝒰(α,γ,‹UniformSpace β›.comap f) = 𝒰(α,β,_).comap ((· ∘ ·) f) := by
  letI : UniformSpace γ := ‹UniformSpace β›.comap f
  ext : 1
  change UniformConvergence.filter α γ ((𝓤 β).comap _) = (UniformConvergence.filter α β (𝓤 β)).comap _
  -- We have the following four Galois connection which form a square diagram, and we want
  -- to show that the square of upper adjoints is commutative. The trick then is to use
  -- `galois_connection.u_comm_of_l_comm` to reduce it to commutativity of the lower adjoints,
  -- which is way easier to prove.
  have h₁ := Filter.gc_map_comap (Prod.map ((· ∘ ·) f) ((· ∘ ·) f))
  have h₂ := Filter.gc_map_comap (Prod.map f f)
  have h₃ := UniformConvergence.gc α β
  have h₄ := UniformConvergence.gc α γ
  refine' GaloisConnection.u_comm_of_l_comm h₁ h₂ h₃ h₄ fun 𝓐 => _
  have : Prod.map f f ∘ Φ α γ = Φ α β ∘ Prod.map (Prod.map ((· ∘ ·) f) ((· ∘ ·) f)) id := by
    ext <;> rfl
  rw [map_comm this, ← prod_map_map_eq']
  rfl

/-- Post-composition by a uniformly continuous function is uniformly continuous for the
uniform structures of uniform convergence.

More precisely, if `f : (γ, uγ) → (β, uβ)` is uniformly continuous, then
`(λ g, f ∘ g) : (α → γ, 𝒰(α, γ, uγ)) → (α → β, 𝒰(α, β, uβ))` is uniformly continuous. -/
protected theorem postcomp_uniform_continuous [UniformSpace γ] {f : γ → β} (hf : UniformContinuous f) :
    UniformContinuous ((· ∘ ·) f : (α → γ) → α → β) :=
  -- This is a direct consequence of `uniform_convergence.comap_eq`
      uniform_continuous_iff.mpr <|
    calc
      𝒰(α,γ,_) ≤ 𝒰(α,γ,‹UniformSpace β›.comap f) := UniformConvergence.mono (uniform_continuous_iff.mp hf)
      _ = 𝒰(α,β,_).comap ((· ∘ ·) f) := UniformConvergence.comap_eq
      

/-- Post-composition by a uniform inducing is a uniform inducing for the
uniform structures of uniform convergence.

More precisely, if `f : (γ, uγ) → (β, uβ)` is a uniform inducing, then
`(λ g, f ∘ g) : (α → γ, 𝒰(α, γ, uγ)) → (α → β, 𝒰(α, β, uβ))` is a uniform inducing. -/
protected theorem postcomp_uniform_inducing [UniformSpace γ] {f : γ → β} (hf : UniformInducing f) :
    UniformInducing ((· ∘ ·) f : (α → γ) → α → β) := by
  -- This is a direct consequence of `uniform_convergence.comap_eq`
  constructor
  replace hf : (𝓤 β).comap (Prod.map f f) = _ := hf.comap_uniformity
  change comap (Prod.map ((· ∘ ·) f) ((· ∘ ·) f)) _ = _
  rw [← uniformity_comap rfl] at hf⊢
  congr
  rw [← uniform_space_eq hf, UniformConvergence.comap_eq]

/-- Turn a uniform isomorphism `(γ, uγ) ≃ᵤ (β, uβ)` into a uniform isomorphism
`(α → γ, 𝒰(α, γ, uγ)) ≃ᵤ (α → β, 𝒰(α, β, uβ))` by post-composing. -/
protected def congrRight [UniformSpace γ] (e : γ ≃ᵤ β) : (α → γ) ≃ᵤ (α → β) :=
  { Equivₓ.piCongrRight fun a => e.toEquiv with
    uniform_continuous_to_fun := UniformConvergence.postcomp_uniform_continuous e.UniformContinuous,
    uniform_continuous_inv_fun := UniformConvergence.postcomp_uniform_continuous e.symm.UniformContinuous }

/-- Pre-composition by a any function is uniformly continuous for the uniform structures of
uniform convergence.

More precisely, for any `f : γ → α`, the function
`(λ g, g ∘ f) : (α → β, 𝒰(α, β, uβ)) → (γ → β, 𝒰(γ, β, uβ))` is uniformly continuous. -/
protected theorem precomp_uniform_continuous {f : γ → α} : UniformContinuous fun g : α → β => g ∘ f := by
  -- Here we simply go back to filter bases.
  rw [uniform_continuous_iff]
  change 𝓤 (α → β) ≤ (𝓤 (γ → β)).comap (Prod.map (fun g : α → β => g ∘ f) fun g : α → β => g ∘ f)
  rw
    [(UniformConvergence.has_basis_uniformity α β).le_basis_iff ((UniformConvergence.has_basis_uniformity γ β).comap _)]
  exact fun U hU => ⟨U, hU, fun uv huv x => huv (f x)⟩

/-- Turn a bijection `γ ≃ α` into a uniform isomorphism
`(γ → β, 𝒰(γ, β, uβ)) ≃ᵤ (α → β, 𝒰(α, β, uβ))` by pre-composing. -/
protected def congrLeft (e : γ ≃ α) : (γ → β) ≃ᵤ (α → β) :=
  { Equivₓ.arrowCongr e (Equivₓ.refl _) with uniform_continuous_to_fun := UniformConvergence.precomp_uniform_continuous,
    uniform_continuous_inv_fun := UniformConvergence.precomp_uniform_continuous }

/-- The topology of uniform convergence is T₂. -/
theorem t2_space [T2Space β] : T2Space (α → β) :=
  { t2 := by
      letI : UniformSpace (α → β) := 𝒰(α,β,_)
      letI : TopologicalSpace (α → β) := UniformConvergence.topologicalSpace α β
      intro f g h
      obtain ⟨x, hx⟩ := not_forall.mp (mt funext h)
      exact separated_by_continuous (uniform_continuous_eval β x).Continuous hx }

/-- The uniform structure of uniform convergence is finer than that of pointwise convergence,
aka the product uniform structure. -/
protected theorem le_Pi : 𝒰(α,β,_) ≤ Pi.uniformSpace fun _ => β := by
  -- By definition of the product uniform structure, this is just `uniform_continuous_eval`.
  rw [le_iff_uniform_continuous_id, uniform_continuous_pi]
  intro x
  exact uniform_continuous_eval β x

/-- The topology of uniform convergence indeed gives the same notion of convergence as
`tendsto_uniformly`. -/
protected theorem tendsto_iff_tendsto_uniformly : Tendsto F p (𝓝 f) ↔ TendstoUniformly F f p := by
  letI : UniformSpace (α → β) := 𝒰(α,β,_)
  rw [(UniformConvergence.has_basis_nhds α β).tendsto_right_iff, TendstoUniformly]
  exact Iff.rfl

/-- The natural bijection between `α → β × γ` and `(α → β) × (α → γ)`, upgraded to a uniform
isomorphism between `(α → β × γ, 𝒰(α, β × γ, uβ × uγ))` and
`((α → β) × (α → γ), 𝒰(α, β, uβ) × 𝒰(α, γ, uγ))`. -/
protected def uniformEquivProdArrow [UniformSpace γ] : (α → β × γ) ≃ᵤ (α → β) × (α → γ) :=
  (-- Denote `φ` this bijection. We want to show that
        -- `comap φ (𝒰(α, β, uβ) × 𝒰(α, γ, uγ)) = 𝒰(α, β × γ, uβ × uγ)`.
        -- But `uβ × uγ` is defined as `comap fst uβ ⊓ comap snd uγ`, so we just have to apply
        -- `uniform_convergence.inf_eq` and `uniform_convergence.comap_eq`, which leaves us to check
        -- that some square commutes.
        Equivₓ.arrowProdEquivProdArrow
        _ _ _).toUniformEquivOfUniformInducing
    (by
      constructor
      change comap (Prod.map (Equivₓ.arrowProdEquivProdArrow _ _ _) (Equivₓ.arrowProdEquivProdArrow _ _ _)) _ = _
      rw [← uniformity_comap rfl]
      congr
      rw [Prod.uniformSpace, Prod.uniformSpace, UniformSpace.comap_inf, UniformConvergence.inf_eq]
      congr <;> rw [← UniformSpace.comap_comap, UniformConvergence.comap_eq] <;> rfl)

-- the relevant diagram commutes by definition
variable (α) (δ : ι → Type _) [∀ i, UniformSpace (δ i)]

attribute [-instance] UniformConvergence.uniformSpace

/-- The natural bijection between `α → Π i, δ i` and `Π i, α → δ i`, upgraded to a uniform
isomorphism between `(α → (Π i, δ i), 𝒰(α, (Π i, δ i), (Π i, uδ i)))` and
`((Π i, α → δ i), (Π i, 𝒰(α, δ i, uδ i)))`. -/
protected def uniformEquivPiComm :
    @UniformEquiv (α → ∀ i, δ i) (∀ i, α → δ i) 𝒰(α,∀ i, δ i,Pi.uniformSpace δ)
      (@Pi.uniformSpace ι (fun i => α → δ i) fun i => 𝒰(α,δ i,_)) :=
  -- Denote `φ` this bijection. We want to show that
    -- `comap φ (Π i, 𝒰(α, δ i, uδ i)) = 𝒰(α, (Π i, δ i), (Π i, uδ i))`.
    -- But `Π i, uδ i` is defined as `⨅ i, comap (eval i) (uδ i)`, so we just have to apply
    -- `uniform_convergence.infi_eq` and `uniform_convergence.comap_eq`, which leaves us to check
    -- that some square commutes.
    @Equivₓ.toUniformEquivOfUniformInducing
    _ _ 𝒰(α,∀ i, δ i,Pi.uniformSpace δ) (@Pi.uniformSpace ι (fun i => α → δ i) fun i => 𝒰(α,δ i,_)) (Equivₓ.piComm _)
    (by
      constructor
      change comap (Prod.map Function.swap Function.swap) _ = _
      rw [← uniformity_comap rfl]
      congr
      rw [Pi.uniformSpace, UniformSpace.of_core_eq_to_core, Pi.uniformSpace, UniformSpace.of_core_eq_to_core,
        UniformSpace.comap_infi, UniformConvergence.infi_eq]
      refine' infi_congr fun i => _
      rw [← UniformSpace.comap_comap, UniformConvergence.comap_eq])

-- Like in the previous lemma, the diagram actually commutes by definition
end UniformConvergence

namespace UniformConvergenceOn

variable (α β : Type _) {γ ι : Type _} [UniformSpace β] (𝔖 : Set (Set α))

variable {F : ι → α → β} {f : α → β} {s s' : Set α} {x : α} {p : Filter ι} {g : ι → α}

-- mathport name: «expr𝒰( , , )»
local notation "𝒰(" α "," β "," u ")" => @UniformConvergence.uniformSpace α β u

/-- Uniform structure of `𝔖`-convergence, i.e uniform convergence on the elements of `𝔖`.
It is defined as the infimum, for `S ∈ 𝔖`, of the pullback of `𝒰 S β` by `S.restrict`, the
map of restriction to `S`. We will denote it `𝒱(α, β, 𝔖, uβ)`, where `uβ` is the uniform structure
on `β`. -/
protected def uniformSpace : UniformSpace (α → β) :=
  ⨅ (s : Set α) (hs : s ∈ 𝔖), UniformSpace.comap s.restrict 𝒰(s,β,_)

-- mathport name: «expr𝒱( , , , )»
local notation "𝒱(" α "," β "," 𝔖 "," u ")" => @UniformConvergenceOn.uniformSpace α β u 𝔖

/-- Topology of `𝔖`-convergence, i.e uniform convergence on the elements of `𝔖`. -/
protected def topologicalSpace : TopologicalSpace (α → β) :=
  𝒱(α,β,𝔖,_).toTopologicalSpace

/-- The topology of `𝔖`-convergence is the infimum, for `S ∈ 𝔖`, of topology induced by the map
of restriction to `S`, where `↥S → β` is endowed with the topology of uniform convergence. -/
protected theorem topological_space_eq :
    UniformConvergenceOn.topologicalSpace α β 𝔖 =
      ⨅ (s : Set α) (hs : s ∈ 𝔖), TopologicalSpace.induced s.restrict (UniformConvergence.topologicalSpace s β) :=
  by
  simp only [UniformConvergenceOn.topologicalSpace, to_topological_space_infi, to_topological_space_infi,
    to_topological_space_comap]
  rfl

/-- If `S ∈ 𝔖`, then the restriction to `S` is a uniformly continuous map from `𝒱(α, β, 𝔖, uβ)` to
`𝒰(↥S, β, uβ)`. -/
protected theorem uniform_continuous_restrict (h : s ∈ 𝔖) : @UniformContinuous _ _ 𝒱(α,β,𝔖,_) 𝒰(s,β,_) s.restrict := by
  change _ ≤ _
  rw [UniformConvergenceOn.uniformSpace, map_le_iff_le_comap, uniformity, infi_uniformity]
  refine' infi_le_of_le s _
  rw [infi_uniformity]
  exact infi_le _ h

variable {α}

/-- Let `u₁`, `u₂` be two uniform structures on `γ` and `𝔖₁ 𝔖₂ : set (set α)`. If `u₁ ≤ u₂` and
`𝔖₂ ⊆ 𝔖₁` then `𝒱(α, γ, 𝔖₁, u₁) ≤ 𝒱(α, γ, 𝔖₂, u₂)`. -/
protected theorem mono ⦃u₁ u₂ : UniformSpace γ⦄ (hu : u₁ ≤ u₂) ⦃𝔖₁ 𝔖₂ : Set (Set α)⦄ (h𝔖 : 𝔖₂ ⊆ 𝔖₁) :
    𝒱(α,γ,𝔖₁,u₁) ≤ 𝒱(α,γ,𝔖₂,u₂) :=
  calc
    𝒱(α,γ,𝔖₁,u₁) ≤ 𝒱(α,γ,𝔖₂,u₁) := infi_le_infi_of_subset h𝔖
    _ ≤ 𝒱(α,γ,𝔖₂,u₂) := infi₂_mono fun i hi => UniformSpace.comap_mono <| UniformConvergence.mono hu
    

/-- If `x : α` is in some `S ∈ 𝔖`, then evaluation at `x` is uniformly continuous for
`𝒱(α, β, 𝔖, uβ)`. -/
theorem uniform_continuous_eval_of_mem {x : α} (hxs : x ∈ s) (hs : s ∈ 𝔖) :
    @UniformContinuous _ _ 𝒱(α,β,𝔖,_) _ (Function.eval x) :=
  @UniformContinuous.comp (α → β) (s → β) β 𝒱(α,β,𝔖,_) 𝒰(s,β,_) _ _ _
    (UniformConvergence.uniform_continuous_eval β (⟨x, hxs⟩ : s))
    (UniformConvergenceOn.uniform_continuous_restrict α β 𝔖 hs)

variable {β} {𝔖}

/-- If `u` is a family of uniform structures on `γ`, then
`𝒱(α, γ, 𝔖, (⨅ i, u i)) = ⨅ i, 𝒱(α, γ, 𝔖, u i)`. -/
protected theorem infi_eq {u : ι → UniformSpace γ} : 𝒱(α,γ,𝔖,⨅ i, u i) = ⨅ i, 𝒱(α,γ,𝔖,u i) := by
  simp_rw [UniformConvergenceOn.uniformSpace, UniformConvergence.infi_eq, UniformSpace.comap_infi]
  rw [infi_comm]
  exact infi_congr fun s => infi_comm

/-- If `u₁` and `u₂` are two uniform structures on `γ`, then
`𝒱(α, γ, 𝔖, u₁ ⊓ u₂) = 𝒱(α, γ, 𝔖, u₁) ⊓ 𝒱(α, γ, 𝔖, u₂)`. -/
protected theorem inf_eq {u₁ u₂ : UniformSpace γ} : 𝒱(α,γ,𝔖,u₁⊓u₂) = 𝒱(α,γ,𝔖,u₁)⊓𝒱(α,γ,𝔖,u₂) := by
  rw [inf_eq_infi, inf_eq_infi, UniformConvergenceOn.infi_eq]
  refine' infi_congr fun i => _
  cases i <;> rfl

/-- If `u` is a uniform structures on `β` and `f : γ → β`, then
`𝒱(α, γ, 𝔖, comap f u) = comap (λ g, f ∘ g) 𝒱(α, γ, 𝔖, u₁)`. -/
protected theorem comap_eq {f : γ → β} : 𝒱(α,γ,𝔖,‹UniformSpace β›.comap f) = 𝒱(α,β,𝔖,_).comap ((· ∘ ·) f) := by
  -- We reduce this to `uniform_convergence.comap_eq` using the fact that `comap` distributes
  -- on `infi`.
  simp_rw [UniformConvergenceOn.uniformSpace, UniformSpace.comap_infi, UniformConvergence.comap_eq, ←
    UniformSpace.comap_comap]
  rfl

-- by definition, `∀ S ∈ 𝔖, (f ∘ —) ∘ S.restrict = S.restrict ∘ (f ∘ —)`.
/-- Post-composition by a uniformly continuous function is uniformly continuous for the
uniform structures of `𝔖`-convergence.

More precisely, if `f : (γ, uγ) → (β, uβ)` is uniformly continuous, then
`(λ g, f ∘ g) : (α → γ, 𝒱(α, γ, 𝔖, uγ)) → (α → β, 𝒱(α, β, 𝔖, uβ))` is uniformly continuous. -/
protected theorem postcomp_uniform_continuous [UniformSpace γ] {f : γ → β} (hf : UniformContinuous f) :
    @UniformContinuous (α → γ) (α → β) 𝒱(α,γ,𝔖,_) 𝒱(α,β,𝔖,_) ((· ∘ ·) f) := by
  -- This is a direct consequence of `uniform_convergence.comap_eq`
  rw [uniform_continuous_iff]
  calc
    𝒱(α,γ,𝔖,_) ≤ 𝒱(α,γ,𝔖,‹UniformSpace β›.comap f) :=
      UniformConvergenceOn.mono (uniform_continuous_iff.mp hf) subset_rfl
    _ = 𝒱(α,β,𝔖,_).comap ((· ∘ ·) f) := UniformConvergenceOn.comap_eq
    

/-- Post-composition by a uniform inducing is a uniform inducing for the
uniform structures of `𝔖`-convergence.

More precisely, if `f : (γ, uγ) → (β, uβ)` is a uniform inducing, then
`(λ g, f ∘ g) : (α → γ, 𝒱(α, γ, 𝔖, uγ)) → (α → β, 𝒱(α, β, 𝔖, uβ))` is a uniform inducing. -/
protected theorem postcomp_uniform_inducing [UniformSpace γ] {f : γ → β} (hf : UniformInducing f) :
    @UniformInducing (α → γ) (α → β) 𝒱(α,γ,𝔖,_) 𝒱(α,β,𝔖,_) ((· ∘ ·) f) := by
  -- This is a direct consequence of `uniform_convergence.comap_eq`
  constructor
  replace hf : (𝓤 β).comap (Prod.map f f) = _ := hf.comap_uniformity
  change comap (Prod.map ((· ∘ ·) f) ((· ∘ ·) f)) _ = _
  rw [← uniformity_comap rfl] at hf⊢
  congr
  rw [← uniform_space_eq hf, UniformConvergenceOn.comap_eq]

/-- Turn a uniform isomorphism `(γ, uγ) ≃ᵤ (β, uβ)` into a uniform isomorphism
`(α → γ, 𝒱(α, γ, 𝔖, uγ)) ≃ᵤ (α → β, 𝒱(α, β, 𝔖, uβ))` by post-composing. -/
protected def congrRight [UniformSpace γ] (e : γ ≃ᵤ β) : @UniformEquiv (α → γ) (α → β) 𝒱(α,γ,𝔖,_) 𝒱(α,β,𝔖,_) :=
  { Equivₓ.piCongrRight fun a => e.toEquiv with
    uniform_continuous_to_fun := UniformConvergenceOn.postcomp_uniform_continuous e.UniformContinuous,
    uniform_continuous_inv_fun := UniformConvergenceOn.postcomp_uniform_continuous e.symm.UniformContinuous }

/-- Let `f : γ → α`, `𝔖 : set (set α)`, `𝔗 : set (set γ)`, and assume that `∀ T ∈ 𝔗, f '' T ∈ 𝔖`.
Then, the function `(λ g, g ∘ f) : (α → β, 𝒱(α, β, 𝔖, uβ)) → (γ → β, 𝒱(γ, β, 𝔗 uβ))` is
uniformly continuous.

Note that one can easily see that assuming `∀ T ∈ 𝔗, ∃ S ∈ 𝔖, f '' T ⊆ S` would work too, but
we will get this for free when we prove that `𝒱(α, β, 𝔖, uβ) = 𝒱(α, β, 𝔖', uβ)` for `𝔖'` the
***noncovering*** bornology generated by `𝔖`. -/
protected theorem precomp_uniform_continuous {𝔗 : Set (Set γ)} {f : γ → α} (hf : 𝔗 ⊆ Image f ⁻¹' 𝔖) :
    @UniformContinuous (α → β) (γ → β) 𝒱(α,β,𝔖,_) 𝒱(γ,β,𝔗,_) fun g : α → β => g ∘ f := by
  -- Since `comap` distributes on `infi`, it suffices to prove that
  -- `⨅ s ∈ 𝔖, comap s.restrict 𝒰(↥s, β, uβ) ≤ ⨅ t ∈ 𝔗, comap (t.restrict ∘ (— ∘ f)) 𝒰(↥t, β, uβ)`.
  simp_rw [uniform_continuous_iff, UniformConvergenceOn.uniformSpace, UniformSpace.comap_infi, ←
    UniformSpace.comap_comap]
  -- For any `t ∈ 𝔗`, note `s := f '' t ∈ 𝔖`.
  -- We will show that `comap s.restrict 𝒰(↥s, β, uβ) ≤ comap (t.restrict ∘ (— ∘ f)) 𝒰(↥t, β, uβ)`.
  refine' le_infi₂ fun t ht => infi_le_of_le (f '' t) <| infi_le_of_le (hf ht) _
  -- Let `f'` be the map from `t` to `f '' t` induced by `f`.
  let f' : t → f '' t := (maps_to_image f t).restrict f t (f '' t)
  -- By definition `t.restrict ∘ (— ∘ f) = (— ∘ f') ∘ (f '' t).restrict`.
  have : (t.restrict ∘ fun g : α → β => g ∘ f) = (fun g : f '' t → β => g ∘ f') ∘ (f '' t).restrict := rfl
  -- Thus, we have to show `comap (f '' t).restrict 𝒰(↥(f '' t), β, uβ) ≤`
  -- `comap (f '' t).restrict (comap (— ∘ f') 𝒰(↥t, β, uβ))`.
  rw [this, @UniformSpace.comap_comap (α → β) (f '' t → β)]
  -- But this is exactly monotonicity of `comap` applied to
  -- `uniform_convergence.precomp_continuous`.
  refine' UniformSpace.comap_mono _
  rw [← uniform_continuous_iff]
  exact UniformConvergence.precomp_uniform_continuous

/-- Turn a bijection `e : γ ≃ α` such that we have both `∀ T ∈ 𝔗, e '' T ∈ 𝔖` and
`∀ S ∈ 𝔖, e ⁻¹' S ∈ 𝔗` into a uniform isomorphism `(γ → β, 𝒰(γ, β, uβ)) ≃ᵤ (α → β, 𝒰(α, β, uβ))`
by pre-composing. -/
protected def congrLeft {𝔗 : Set (Set γ)} (e : γ ≃ α) (he : 𝔗 ⊆ Image e ⁻¹' 𝔖) (he' : 𝔖 ⊆ Preimage e ⁻¹' 𝔗) :
    @UniformEquiv (γ → β) (α → β) 𝒱(γ,β,𝔗,_) 𝒱(α,β,𝔖,_) :=
  { Equivₓ.arrowCongr e (Equivₓ.refl _) with
    uniform_continuous_to_fun :=
      UniformConvergenceOn.precomp_uniform_continuous
        (by
          intro s hs
          change e.symm '' s ∈ 𝔗
          rw [← preimage_equiv_eq_image_symm]
          exact he' hs),
    uniform_continuous_inv_fun := UniformConvergenceOn.precomp_uniform_continuous he }

/-- If `𝔖` covers `α`, then the topology of `𝔖`-convergence is T₂. -/
theorem t2_space_of_covering [T2Space β] (h : ⋃₀𝔖 = univ) : @T2Space _ (UniformConvergenceOn.topologicalSpace α β 𝔖) :=
  { t2 := by
      letI : UniformSpace (α → β) := 𝒱(α,β,𝔖,_)
      letI : TopologicalSpace (α → β) := UniformConvergenceOn.topologicalSpace α β 𝔖
      intro f g hfg
      obtain ⟨x, hx⟩ := not_forall.mp (mt funext hfg)
      obtain ⟨s, hs, hxs⟩ : ∃ s ∈ 𝔖, x ∈ s := mem_sUnion.mp (h.symm ▸ True.intro)
      exact separated_by_continuous (uniform_continuous_eval_of_mem β 𝔖 hxs hs).Continuous hx }

/-- If `𝔖` covers `α`, then the uniform structure of `𝔖`-convergence is finer than that of
pointwise convergence. -/
protected theorem le_Pi_of_covering (h : ⋃₀𝔖 = univ) : 𝒱(α,β,𝔖,_) ≤ Pi.uniformSpace fun _ => β := by
  rw [le_iff_uniform_continuous_id, uniform_continuous_pi]
  intro x
  obtain ⟨s : Set α, hs : s ∈ 𝔖, hxs : x ∈ s⟩ := sUnion_eq_univ_iff.mp h x
  exact uniform_continuous_eval_of_mem β 𝔖 hxs hs

/-- Convergence in the topology of `𝔖`-convergence means uniform convergence on `S` (in the sense
of `tendsto_uniformly_on`) for all `S ∈ 𝔖`. -/
protected theorem tendsto_iff_tendsto_uniformly_on :
    Tendsto F p (@nhds _ (UniformConvergenceOn.topologicalSpace α β 𝔖) f) ↔ ∀ s ∈ 𝔖, TendstoUniformlyOn F f p s := by
  letI : UniformSpace (α → β) := 𝒱(α,β,𝔖,_)
  rw [UniformConvergenceOn.topological_space_eq, nhds_infi, tendsto_infi]
  refine' forall_congrₓ fun s => _
  rw [nhds_infi, tendsto_infi]
  refine' forall_congrₓ fun hs => _
  rw [nhds_induced, tendsto_comap_iff, tendsto_uniformly_on_iff_tendsto_uniformly_comp_coe,
    UniformConvergence.tendsto_iff_tendsto_uniformly]
  rfl

/-- The natural bijection between `α → β × γ` and `(α → β) × (α → γ)`, upgraded to a uniform
isomorphism between `(α → β × γ, 𝒱(α, β × γ, 𝔖, uβ × uγ))` and
`((α → β) × (α → γ), 𝒱(α, β, 𝔖, uβ) × 𝒰(α, γ, 𝔖, uγ))`. -/
protected def uniformEquivProdArrow [UniformSpace γ] :
    @UniformEquiv (α → β × γ) ((α → β) × (α → γ)) 𝒱(α,β × γ,𝔖,_) (@Prod.uniformSpace _ _ 𝒱(α,β,𝔖,_) 𝒱(α,γ,𝔖,_)) :=
  -- Denote `φ` this bijection. We want to show that
    -- `comap φ (𝒱(α, β, 𝔖, uβ) × 𝒱(α, γ, 𝔖, uγ)) = 𝒱(α, β × γ, 𝔖, uβ × uγ)`.
    -- But `uβ × uγ` is defined as `comap fst uβ ⊓ comap snd uγ`, so we just have to apply
    -- `uniform_convergence_on.inf_eq` and `uniform_convergence_on.comap_eq`, which leaves us to check
    -- that some square commutes.
    -- We could also deduce this from `uniform_convergence.uniform_equiv_prod_arrow`, but it turns out
    -- to be more annoying.
    @Equivₓ.toUniformEquivOfUniformInducing
    _ _ 𝒱(α,β × γ,𝔖,_) (@Prod.uniformSpace _ _ 𝒱(α,β,𝔖,_) 𝒱(α,γ,𝔖,_)) (Equivₓ.arrowProdEquivProdArrow _ _ _)
    (by
      constructor
      change comap (Prod.map (Equivₓ.arrowProdEquivProdArrow _ _ _) (Equivₓ.arrowProdEquivProdArrow _ _ _)) _ = _
      rw [← uniformity_comap rfl]
      congr
      rw [Prod.uniformSpace, Prod.uniformSpace, UniformSpace.comap_inf, UniformConvergenceOn.inf_eq]
      congr <;> rw [← UniformSpace.comap_comap, UniformConvergenceOn.comap_eq] <;> rfl)

-- the relevant diagram commutes by definition
variable (𝔖) (δ : ι → Type _) [∀ i, UniformSpace (δ i)]

/-- The natural bijection between `α → Π i, δ i` and `Π i, α → δ i`, upgraded to a uniform
isomorphism between `(α → (Π i, δ i), 𝒱(α, (Π i, δ i), 𝔖, (Π i, uδ i)))` and
`((Π i, α → δ i), (Π i, 𝒱(α, δ i, 𝔖, uδ i)))`. -/
protected def uniformEquivPiComm :
    @UniformEquiv (α → ∀ i, δ i) (∀ i, α → δ i) 𝒱(α,∀ i, δ i,𝔖,Pi.uniformSpace δ)
      (@Pi.uniformSpace ι (fun i => α → δ i) fun i => 𝒱(α,δ i,𝔖,_)) :=
  -- Denote `φ` this bijection. We want to show that
    -- `comap φ (Π i, 𝒱(α, δ i, 𝔖, uδ i)) = 𝒱(α, (Π i, δ i), 𝔖, (Π i, uδ i))`.
    -- But `Π i, uδ i` is defined as `⨅ i, comap (eval i) (uδ i)`, so we just have to apply
    -- `uniform_convergence_on.infi_eq` and `uniform_convergence_on.comap_eq`, which leaves us to check
    -- that some square commutes.
    -- We could also deduce this from `uniform_convergence.uniform_equiv_Pi_comm`, but it turns out
    -- to be more annoying.
    @Equivₓ.toUniformEquivOfUniformInducing
    _ _ 𝒱(α,∀ i, δ i,𝔖,Pi.uniformSpace δ) (@Pi.uniformSpace ι (fun i => α → δ i) fun i => 𝒱(α,δ i,𝔖,_))
    (Equivₓ.piComm _)
    (by
      constructor
      change comap (Prod.map Function.swap Function.swap) _ = _
      rw [← uniformity_comap rfl]
      congr
      rw [Pi.uniformSpace, UniformSpace.of_core_eq_to_core, Pi.uniformSpace, UniformSpace.of_core_eq_to_core,
        UniformSpace.comap_infi, UniformConvergenceOn.infi_eq]
      refine' infi_congr fun i => _
      rw [← UniformSpace.comap_comap, UniformConvergenceOn.comap_eq])

-- Like in the previous lemma, the diagram actually commutes by definition
end UniformConvergenceOn

