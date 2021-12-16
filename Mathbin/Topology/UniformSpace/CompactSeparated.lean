import Mathbin.Topology.UniformSpace.Separation 
import Mathbin.Topology.UniformSpace.UniformConvergence

/-!
# Compact separated uniform spaces

## Main statements

* `compact_space_uniformity`: On a separated compact uniform space, the topology determines the
  uniform structure, entourages are exactly the neighborhoods of the diagonal.
* `uniform_space_of_compact_t2`: every compact T2 topological structure is induced by a uniform
  structure. This uniform structure is described in the previous item.
* Heine-Cantor theorem: continuous functions on compact separated uniform spaces with values in
  uniform spaces are automatically uniformly continuous. There are several variations, the main one
  is `compact_space.uniform_continuous_of_continuous`.

## Implementation notes

The construction `uniform_space_of_compact_t2` is not declared as an instance, as it would badly
loop.

## tags

uniform space, uniform continuity, compact space
-/


open_locale Classical uniformity TopologicalSpace Filter

open Filter UniformSpace Set

variable {α β γ : Type _} [UniformSpace α] [UniformSpace β]

/-!
### Uniformity on compact separated spaces
-/


/-- On a separated compact uniform space, the topology determines the uniform structure, entourages
are exactly the neighborhoods of the diagonal. -/
theorem compact_space_uniformity [CompactSpace α] [SeparatedSpace α] : 𝓤 α = ⨆ x : α, 𝓝 (x, x) :=
  by 
    symm 
    refine' le_antisymmₓ supr_nhds_le_uniformity _ 
    byContra H 
    obtain ⟨V, hV, h⟩ : ∃ V : Set (α × α), (∀ x : α, V ∈ 𝓝 (x, x)) ∧ 𝓤 α⊓𝓟 (Vᶜ) ≠ ⊥
    ·
      simpa [le_iff_forall_inf_principal_compl] using H 
    let F := 𝓤 α⊓𝓟 (Vᶜ)
    have  : ne_bot F := ⟨h⟩
    obtain ⟨⟨x, y⟩, hx⟩ : ∃ p : α × α, ClusterPt p F := cluster_point_of_compact F 
    have  : ClusterPt (x, y) (𝓤 α) := hx.of_inf_left 
    have hxy : x = y := eq_of_uniformity_inf_nhds this 
    subst hxy 
    have  : ClusterPt (x, x) (𝓟 (Vᶜ)) := hx.of_inf_right 
    have  : (x, x) ∉ Interior V
    ·
      have  : (x, x) ∈ Closure (Vᶜ)
      ·
        rwa [mem_closure_iff_cluster_pt]
      rwa [closure_compl] at this 
    have  : (x, x) ∈ Interior V
    ·
      rw [mem_interior_iff_mem_nhds]
      exact hV x 
    contradiction

theorem unique_uniformity_of_compact_t2 [t : TopologicalSpace γ] [CompactSpace γ] [T2Space γ] {u u' : UniformSpace γ}
  (h : u.to_topological_space = t) (h' : u'.to_topological_space = t) : u = u' :=
  by 
    apply uniform_space_eq 
    change uniformity _ = uniformity _ 
    have  : @CompactSpace γ u.to_topological_space
    ·
      rw [h] <;> assumption 
    have  : @CompactSpace γ u'.to_topological_space
    ·
      rw [h'] <;> assumption 
    have  : @SeparatedSpace γ u
    ·
      rwa [separated_iff_t2, h]
    have  : @SeparatedSpace γ u'
    ·
      rwa [separated_iff_t2, h']
    rw [compact_space_uniformity, compact_space_uniformity, h, h']

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (U₁ V₁ «expr ∈ » expr𝓝() x)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (U₂ V₂ «expr ∈ » expr𝓝() y)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ≠ » x)
/-- The unique uniform structure inducing a given compact Hausdorff topological structure. -/
def uniformSpaceOfCompactT2 [TopologicalSpace γ] [CompactSpace γ] [T2Space γ] : UniformSpace γ :=
  { uniformity := ⨆ x, 𝓝 (x, x),
    refl :=
      by 
        simpRw [Filter.principal_le_iff, mem_supr]
        rintro V V_in ⟨x, _⟩ ⟨⟩
        exact mem_of_mem_nhds (V_in x),
    symm :=
      by 
        refine' le_of_eqₓ _ 
        rw [map_supr]
        congr with x : 1 
        erw [nhds_prod_eq, ←prod_comm],
    comp :=
      by 
        set 𝓝Δ := ⨆ x : γ, 𝓝 (x, x)
        set F := 𝓝Δ.lift' fun s : Set (γ × γ) => s ○ s 
        rw [le_iff_forall_inf_principal_compl]
        intro V V_in 
        byContra H 
        have  : ne_bot (F⊓𝓟 (Vᶜ)) := ⟨H⟩
        obtain ⟨⟨x, y⟩, hxy⟩ : ∃ p : γ × γ, ClusterPt p (F⊓𝓟 (Vᶜ)) := cluster_point_of_compact _ 
        have clV : ClusterPt (x, y) (𝓟$ Vᶜ) := hxy.of_inf_right 
        have  : (x, y) ∉ Interior V
        ·
          have  : (x, y) ∈ Closure (Vᶜ)
          ·
            rwa [mem_closure_iff_cluster_pt]
          rwa [closure_compl] at this 
        have diag_subset : diagonal γ ⊆ Interior V
        ·
          rw [subset_interior_iff_nhds]
          rintro ⟨x, x⟩ ⟨⟩
          exact (mem_supr.mp V_in : _) x 
        have x_ne_y : x ≠ y
        ·
          intro h 
          apply this 
          apply diag_subset 
          simp [h]
        have  : NormalSpace γ := normal_of_compact_t2 
        obtain ⟨U₁, V₁, U₁_in, V₁_in, U₂, V₂, U₂_in₂, V₂_in, V₁_cl, V₂_cl, U₁_op, U₂_op, VU₁, VU₂, hU₁₂⟩ :
          ∃ (U₁ V₁ : _)(_ : U₁ ∈ 𝓝 x)(_ : V₁ ∈ 𝓝 x)(U₂ V₂ : _)(_ : U₂ ∈ 𝓝 y)(_ : V₂ ∈ 𝓝 y),
            IsClosed V₁ ∧ IsClosed V₂ ∧ IsOpen U₁ ∧ IsOpen U₂ ∧ V₁ ⊆ U₁ ∧ V₂ ⊆ U₂ ∧ U₁ ∩ U₂ = ∅ :=
          disjoint_nested_nhds x_ne_y 
        let U₃ := (V₁ ∪ V₂)ᶜ
        have U₃_op : IsOpen U₃ := is_open_compl_iff.mpr (IsClosed.union V₁_cl V₂_cl)
        let W := U₁.prod U₁ ∪ U₂.prod U₂ ∪ U₃.prod U₃ 
        have W_in : W ∈ 𝓝Δ
        ·
          rw [mem_supr]
          intro x 
          apply IsOpen.mem_nhds (IsOpen.union (IsOpen.union _ _) _)
          ·
            byCases' hx : x ∈ V₁ ∪ V₂
            ·
              left 
              cases' hx with hx hx <;> [left, right] <;> constructor <;> tauto
            ·
              right 
              rw [mem_prod]
              tauto 
          all_goals 
            simp only [IsOpen.prod]
        have  : W ○ W ∈ F
        ·
          simpa only using mem_lift' W_in 
        have hV₁₂ : V₁.prod V₂ ∈ 𝓝 (x, y) := ProdIsOpen.mem_nhds V₁_in V₂_in 
        have clF : ClusterPt (x, y) F := hxy.of_inf_left 
        obtain ⟨p, p_in⟩ : ∃ p, p ∈ V₁.prod V₂ ∩ (W ○ W) := cluster_pt_iff.mp clF hV₁₂ this 
        have inter_empty : V₁.prod V₂ ∩ (W ○ W) = ∅
        ·
          rw [eq_empty_iff_forall_not_mem]
          rintro ⟨u, v⟩ ⟨⟨u_in, v_in⟩, w, huw, hwv⟩
          have uw_in : (u, w) ∈ U₁.prod U₁ :=
            Set.mem_prod.2
              ((huw.resolve_right fun h => h.1$ Or.inl u_in).resolve_right
                fun h =>
                  have  : u ∈ U₁ ∩ U₂ := ⟨VU₁ u_in, h.1⟩
                  by 
                    rwa [hU₁₂] at this)
          have wv_in : (w, v) ∈ U₂.prod U₂ :=
            Set.mem_prod.2
              ((hwv.resolve_right fun h => h.2$ Or.inr v_in).resolve_left
                fun h =>
                  have  : v ∈ U₁ ∩ U₂ := ⟨h.2, VU₂ v_in⟩
                  by 
                    rwa [hU₁₂] at this)
          have  : w ∈ U₁ ∩ U₂ := ⟨uw_in.2, wv_in.1⟩
          rwa [hU₁₂] at this 
        rwa [inter_empty] at p_in,
    is_open_uniformity :=
      by 
        suffices  : ∀ x : γ, Filter.comap (Prod.mk x) (⨆ y, 𝓝 (y, y)) = 𝓝 x
        ·
          intro s 
          change IsOpen s ↔ _ 
          simpRw [is_open_iff_mem_nhds, nhds_eq_comap_uniformity_aux, this]
        intro x 
        simpRw [comap_supr, nhds_prod_eq, comap_prod,
          show (Prod.fst ∘ Prod.mk x) = fun y : γ => x by 
            ext <;> simp ,
          show (Prod.snd ∘ Prod.mk x) = (id : γ → γ)by 
            ext <;> rfl,
          comap_id]
        rw [supr_split_single _ x, comap_const_of_mem fun V => mem_of_mem_nhds]
        suffices  : ∀ y _ : y ≠ x, comap (fun y : γ => x) (𝓝 y)⊓𝓝 y ≤ 𝓝 x
        ·
          simpa 
        intro y hxy 
        simp
          [comap_const_of_not_mem (compl_singleton_mem_nhds hxy)
            (by 
              simp )] }

/-!
### Heine-Cantor theorem
-/


/-- Heine-Cantor: a continuous function on a compact separated uniform space is uniformly
continuous. -/
theorem CompactSpace.uniform_continuous_of_continuous [CompactSpace α] [SeparatedSpace α] {f : α → β}
  (h : Continuous f) : UniformContinuous f :=
  calc map (Prod.map f f) (𝓤 α) = map (Prod.map f f) (⨆ x, 𝓝 (x, x)) :=
    by 
      rw [compact_space_uniformity]
    _ = ⨆ x, map (Prod.map f f) (𝓝 (x, x)) :=
    by 
      rw [map_supr]
    _ ≤ ⨆ x, 𝓝 (f x, f x) := supr_le_supr fun x => (h.prod_map h).ContinuousAt 
    _ ≤ ⨆ y, 𝓝 (y, y) := supr_comp_le (fun y => 𝓝 (y, y)) f 
    _ ≤ 𝓤 β := supr_nhds_le_uniformity
    

/-- Heine-Cantor: a continuous function on a compact separated set of a uniform space is
uniformly continuous. -/
theorem IsCompact.uniform_continuous_on_of_continuous' {s : Set α} {f : α → β} (hs : IsCompact s) (hs' : IsSeparated s)
  (hf : ContinuousOn f s) : UniformContinuousOn f s :=
  by 
    rw [uniform_continuous_on_iff_restrict]
    rw [is_separated_iff_induced] at hs' 
    rw [is_compact_iff_compact_space] at hs 
    rw [continuous_on_iff_continuous_restrict] at hf 
    skip 
    exact CompactSpace.uniform_continuous_of_continuous hf

/-- Heine-Cantor: a continuous function on a compact set of a separated uniform space
is uniformly continuous. -/
theorem IsCompact.uniform_continuous_on_of_continuous [SeparatedSpace α] {s : Set α} {f : α → β} (hs : IsCompact s)
  (hf : ContinuousOn f s) : UniformContinuousOn f s :=
  hs.uniform_continuous_on_of_continuous' (is_separated_of_separated_space s) hf

/-- A family of functions `α → β → γ` tends uniformly to its value at `x` if `α` is locally compact,
`β` is compact and separated and `f` is continuous on `U × (univ : set β)` for some separated
neighborhood `U` of `x`. -/
theorem ContinuousOn.tendsto_uniformly [LocallyCompactSpace α] [CompactSpace β] [SeparatedSpace β] [UniformSpace γ]
  {f : α → β → γ} {x : α} {U : Set α} (hxU : U ∈ 𝓝 x) (hU : IsSeparated U) (h : ContinuousOn (↿f) (U.prod univ)) :
  TendstoUniformly f (f x) (𝓝 x) :=
  by 
    rcases LocallyCompactSpace.local_compact_nhds _ _ hxU with ⟨K, hxK, hKU, hK⟩
    have  : UniformContinuousOn (↿f) (K.prod univ)
    ·
      refine' IsCompact.uniform_continuous_on_of_continuous' (hK.prod compact_univ) _ (h.mono$ prod_mono hKU subset.rfl)
      exact (hU.mono hKU).Prod (is_separated_of_separated_space _)
    exact this.tendsto_uniformly hxK

/-- A continuous family of functions `α → β → γ` tends uniformly to its value at `x` if `α` is
locally compact and `β` is compact and separated. -/
theorem Continuous.tendsto_uniformly [SeparatedSpace α] [LocallyCompactSpace α] [CompactSpace β] [SeparatedSpace β]
  [UniformSpace γ] (f : α → β → γ) (h : Continuous (↿f)) (x : α) : TendstoUniformly f (f x) (𝓝 x) :=
  h.continuous_on.tendsto_uniformly univ_mem$ is_separated_of_separated_space _

