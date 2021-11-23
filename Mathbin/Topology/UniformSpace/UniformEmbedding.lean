import Mathbin.Topology.UniformSpace.Cauchy 
import Mathbin.Topology.UniformSpace.Separation 
import Mathbin.Topology.DenseEmbedding

/-!
# Uniform embeddings of uniform spaces.

Extension of uniform continuous functions.
-/


open Filter TopologicalSpace Set Classical

open_locale Classical uniformity TopologicalSpace Filter

section 

variable{α : Type _}{β : Type _}{γ : Type _}[UniformSpace α][UniformSpace β][UniformSpace γ]

universe u

/-- A map `f : α → β` between uniform spaces is called *uniform inducing* if the uniformity filter
on `α` is the pullback of the uniformity filter on `β` under `prod.map f f`. If `α` is a separated
space, then this implies that `f` is injective, hence it is a `uniform_embedding`. -/
structure UniformInducing(f : α → β) : Prop where 
  comap_uniformity : comap (fun x : α × α => (f x.1, f x.2)) (𝓤 β) = 𝓤 α

theorem UniformInducing.mk' {f : α → β}
  (h : ∀ s, s ∈ 𝓤 α ↔ ∃ (t : _)(_ : t ∈ 𝓤 β), ∀ x y : α, (f x, f y) ∈ t → (x, y) ∈ s) : UniformInducing f :=
  ⟨by 
      simp [eq_comm, Filter.ext_iff, subset_def, h]⟩

theorem UniformInducing.comp {g : β → γ} (hg : UniformInducing g) {f : α → β} (hf : UniformInducing f) :
  UniformInducing (g ∘ f) :=
  ⟨by 
      rw
        [show
          (fun x : α × α => ((g ∘ f) x.1, (g ∘ f) x.2)) =
            ((fun y : β × β => (g y.1, g y.2)) ∘ fun x : α × α => (f x.1, f x.2))by
          
          ext <;> simp ,
        ←Filter.comap_comap, hg.1, hf.1]⟩

theorem UniformInducing.basis_uniformity {f : α → β} (hf : UniformInducing f) {ι : Sort _} {p : ι → Prop}
  {s : ι → Set (β × β)} (H : (𝓤 β).HasBasis p s) : (𝓤 α).HasBasis p fun i => Prod.mapₓ f f ⁻¹' s i :=
  hf.1 ▸ H.comap _

/-- A map `f : α → β` between uniform spaces is a *uniform embedding* if it is uniform inducing and
injective. If `α` is a separated space, then the latter assumption follows from the former. -/
structure UniformEmbedding(f : α → β) extends UniformInducing f : Prop where 
  inj : Function.Injective f

theorem uniform_embedding_subtype_val {p : α → Prop} : UniformEmbedding (Subtype.val : Subtype p → α) :=
  { comap_uniformity := rfl, inj := Subtype.val_injective }

theorem uniform_embedding_subtype_coe {p : α → Prop} : UniformEmbedding (coeₓ : Subtype p → α) :=
  uniform_embedding_subtype_val

theorem uniform_embedding_set_inclusion {s t : Set α} (hst : s ⊆ t) : UniformEmbedding (inclusion hst) :=
  { comap_uniformity :=
      by 
        erw [uniformity_subtype, uniformity_subtype, comap_comap]
        congr,
    inj := inclusion_injective hst }

theorem UniformEmbedding.comp {g : β → γ} (hg : UniformEmbedding g) {f : α → β} (hf : UniformEmbedding f) :
  UniformEmbedding (g ∘ f) :=
  { hg.to_uniform_inducing.comp hf.to_uniform_inducing with inj := hg.inj.comp hf.inj }

theorem uniform_embedding_def {f : α → β} :
  UniformEmbedding f ↔
    Function.Injective f ∧ ∀ s, s ∈ 𝓤 α ↔ ∃ (t : _)(_ : t ∈ 𝓤 β), ∀ x y : α, (f x, f y) ∈ t → (x, y) ∈ s :=
  by 
    split 
    ·
      rintro ⟨⟨h⟩, h'⟩
      rw [eq_comm, Filter.ext_iff] at h 
      simp [subset_def]
    ·
      rintro ⟨h, h'⟩
      refine' UniformEmbedding.mk ⟨_⟩ h 
      rw [eq_comm, Filter.ext_iff]
      simp [subset_def]

theorem uniform_embedding_def' {f : α → β} :
  UniformEmbedding f ↔
    Function.Injective f ∧
      UniformContinuous f ∧ ∀ s, s ∈ 𝓤 α → ∃ (t : _)(_ : t ∈ 𝓤 β), ∀ x y : α, (f x, f y) ∈ t → (x, y) ∈ s :=
  by 
    simp only [uniform_embedding_def, uniform_continuous_def] <;>
      exact
        ⟨fun ⟨I, H⟩ => ⟨I, fun s su => (H _).2 ⟨s, su, fun x y => id⟩, fun s => (H s).1⟩,
          fun ⟨I, H₁, H₂⟩ => ⟨I, fun s => ⟨H₂ s, fun ⟨t, tu, h⟩ => mem_of_superset (H₁ t tu) fun ⟨a, b⟩ => h a b⟩⟩⟩

/-- If the domain of a `uniform_inducing` map `f` is a `separated_space`, then `f` is injective,
hence it is a `uniform_embedding`. -/
protected theorem UniformInducing.uniform_embedding [SeparatedSpace α] {f : α → β} (hf : UniformInducing f) :
  UniformEmbedding f :=
  ⟨hf,
    fun x y h =>
      eq_of_uniformity_basis (hf.basis_uniformity (𝓤 β).basis_sets)$
        fun s hs => mem_preimage.2$ mem_uniformity_of_eq hs h⟩

/-- If a map `f : α → β` sends any two distinct points to point that are **not** related by a fixed
`s ∈ 𝓤 β`, then `f` is uniform inducing with respect to the discrete uniformity on `α`:
the preimage of `𝓤 β` under `prod.map f f` is the principal filter generated by the diagonal in
`α × α`. -/
theorem comap_uniformity_of_spaced_out {α} {f : α → β} {s : Set (β × β)} (hs : s ∈ 𝓤 β)
  (hf : Pairwise fun x y => (f x, f y) ∉ s) : comap (Prod.mapₓ f f) (𝓤 β) = 𝓟 IdRel :=
  by 
    refine' le_antisymmₓ _ (@refl_le_uniformity α (UniformSpace.comap f ‹_›))
    calc comap (Prod.mapₓ f f) (𝓤 β) ≤ comap (Prod.mapₓ f f) (𝓟 s) :=
      comap_mono (le_principal_iff.2 hs)_ = 𝓟 (Prod.mapₓ f f ⁻¹' s) := comap_principal _ ≤ 𝓟 IdRel :=
      principal_mono.2 _ 
    rintro ⟨x, y⟩
    simpa [not_imp_not] using hf x y

-- error in Topology.UniformSpace.UniformEmbedding: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- If a map `f : α → β` sends any two distinct points to point that are **not** related by a fixed
`s ∈ 𝓤 β`, then `f` is a uniform embedding with respect to the discrete uniformity on `α`. -/
theorem uniform_embedding_of_spaced_out
{α}
{f : α → β}
{s : set «expr × »(β, β)}
(hs : «expr ∈ »(s, expr𝓤() β))
(hf : pairwise (λ x y, «expr ∉ »((f x, f y), s))) : @uniform_embedding α β «expr⊥»() «expr‹ ›»(_) f :=
begin
  letI [] [":", expr uniform_space α] [":=", expr «expr⊥»()],
  haveI [] [":", expr separated_space α] [":=", expr separated_iff_t2.2 infer_instance],
  exact [expr uniform_inducing.uniform_embedding ⟨comap_uniformity_of_spaced_out hs hf⟩]
end

theorem UniformInducing.uniform_continuous {f : α → β} (hf : UniformInducing f) : UniformContinuous f :=
  by 
    simp [UniformContinuous, hf.comap_uniformity.symm, tendsto_comap]

theorem UniformInducing.uniform_continuous_iff {f : α → β} {g : β → γ} (hg : UniformInducing g) :
  UniformContinuous f ↔ UniformContinuous (g ∘ f) :=
  by 
    dsimp only [UniformContinuous, tendsto]
    rw [←hg.comap_uniformity, ←map_le_iff_le_comap, Filter.map_map]

theorem UniformInducing.inducing {f : α → β} (h : UniformInducing f) : Inducing f :=
  by 
    refine' ⟨eq_of_nhds_eq_nhds$ fun a => _⟩
    rw [nhds_induced, nhds_eq_uniformity, nhds_eq_uniformity, ←h.comap_uniformity, comap_lift'_eq, comap_lift'_eq2] <;>
      ·
        first |
          rfl|
          exact monotone_preimage

theorem UniformInducing.prod {α' : Type _} {β' : Type _} [UniformSpace α'] [UniformSpace β'] {e₁ : α → α'} {e₂ : β → β'}
  (h₁ : UniformInducing e₁) (h₂ : UniformInducing e₂) : UniformInducing fun p : α × β => (e₁ p.1, e₂ p.2) :=
  ⟨by 
      simp [· ∘ ·, uniformity_prod, h₁.comap_uniformity.symm, h₂.comap_uniformity.symm, comap_inf, comap_comap]⟩

theorem UniformInducing.dense_inducing {f : α → β} (h : UniformInducing f) (hd : DenseRange f) : DenseInducing f :=
  { dense := hd, induced := h.inducing.induced }

theorem UniformEmbedding.embedding {f : α → β} (h : UniformEmbedding f) : Embedding f :=
  { induced := h.to_uniform_inducing.inducing.induced, inj := h.inj }

theorem UniformEmbedding.dense_embedding {f : α → β} (h : UniformEmbedding f) (hd : DenseRange f) : DenseEmbedding f :=
  { dense := hd, inj := h.inj, induced := h.embedding.induced }

-- error in Topology.UniformSpace.UniformEmbedding: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem closed_embedding_of_spaced_out
{α}
[topological_space α]
[discrete_topology α]
[separated_space β]
{f : α → β}
{s : set «expr × »(β, β)}
(hs : «expr ∈ »(s, expr𝓤() β))
(hf : pairwise (λ x y, «expr ∉ »((f x, f y), s))) : closed_embedding f :=
begin
  unfreezingI { rcases [expr discrete_topology.eq_bot α, "with", ident rfl] },
  letI [] [":", expr uniform_space α] [":=", expr «expr⊥»()],
  exact [expr { closed_range := is_closed_range_of_spaced_out hs hf,
     ..(uniform_embedding_of_spaced_out hs hf).embedding }]
end

theorem closure_image_mem_nhds_of_uniform_inducing {s : Set (α × α)} {e : α → β} (b : β) (he₁ : UniformInducing e)
  (he₂ : DenseInducing e) (hs : s ∈ 𝓤 α) : ∃ a, Closure (e '' { a' | (a, a') ∈ s }) ∈ 𝓝 b :=
  have  : s ∈ comap (fun p : α × α => (e p.1, e p.2)) (𝓤 β) := he₁.comap_uniformity.symm ▸ hs 
  let ⟨t₁, ht₁u, ht₁⟩ := this 
  have ht₁ : ∀ p : α × α, (e p.1, e p.2) ∈ t₁ → p ∈ s := ht₁ 
  let ⟨t₂, ht₂u, ht₂s, ht₂c⟩ := comp_symm_of_uniformity ht₁u 
  let ⟨t, htu, hts, htc⟩ := comp_symm_of_uniformity ht₂u 
  have  : preimage e { b' | (b, b') ∈ t₂ } ∈ comap e (𝓝 b) := preimage_mem_comap$ mem_nhds_left b ht₂u 
  let ⟨a, (ha : (b, e a) ∈ t₂)⟩ := (he₂.comap_nhds_ne_bot _).nonempty_of_mem this 
  have  :
    ∀ b' s' : Set (β × β), (b, b') ∈ t → s' ∈ 𝓤 β → ({ y:β | (b', y) ∈ s' } ∩ e '' { a':α | (a, a') ∈ s }).Nonempty :=
    fun b' s' hb' hs' =>
      have  : preimage e { b'' | (b', b'') ∈ s' ∩ t } ∈ comap e (𝓝 b') :=
        preimage_mem_comap$ mem_nhds_left b'$ inter_mem hs' htu 
      let ⟨a₂, ha₂s', ha₂t⟩ := (he₂.comap_nhds_ne_bot _).nonempty_of_mem this 
      have  : (e a, e a₂) ∈ t₁ := ht₂c$ prod_mk_mem_comp_rel (ht₂s ha)$ htc$ prod_mk_mem_comp_rel hb' ha₂t 
      have  : e a₂ ∈ { b'':β | (b', b'') ∈ s' } ∩ e '' { a' | (a, a') ∈ s } :=
        ⟨ha₂s', mem_image_of_mem _$ ht₁ (a, a₂) this⟩
      ⟨_, this⟩
  have  : ∀ b', (b, b') ∈ t → ne_bot (𝓝 b'⊓𝓟 (e '' { a' | (a, a') ∈ s })) :=
    by 
      intro b' hb' 
      rw [nhds_eq_uniformity, lift'_inf_principal_eq, lift'_ne_bot_iff]
      exact fun s => this b' s hb' 
      exact monotone_inter monotone_preimage monotone_const 
  have  : ∀ b', (b, b') ∈ t → b' ∈ Closure (e '' { a' | (a, a') ∈ s }) :=
    fun b' hb' =>
      by 
        rw [closure_eq_cluster_pts] <;> exact this b' hb'
  ⟨a, (𝓝 b).sets_of_superset (mem_nhds_left b htu) this⟩

theorem uniform_embedding_subtype_emb (p : α → Prop) {e : α → β} (ue : UniformEmbedding e) (de : DenseEmbedding e) :
  UniformEmbedding (DenseEmbedding.subtypeEmb p e) :=
  { comap_uniformity :=
      by 
        simp [comap_comap, · ∘ ·, DenseEmbedding.subtypeEmb, uniformity_subtype, ue.comap_uniformity.symm],
    inj := (de.subtype p).inj }

theorem UniformEmbedding.prod {α' : Type _} {β' : Type _} [UniformSpace α'] [UniformSpace β'] {e₁ : α → α'}
  {e₂ : β → β'} (h₁ : UniformEmbedding e₁) (h₂ : UniformEmbedding e₂) :
  UniformEmbedding fun p : α × β => (e₁ p.1, e₂ p.2) :=
  { h₁.to_uniform_inducing.prod h₂.to_uniform_inducing with inj := h₁.inj.prod_map h₂.inj }

theorem is_complete_of_complete_image {m : α → β} {s : Set α} (hm : UniformInducing m) (hs : IsComplete (m '' s)) :
  IsComplete s :=
  by 
    intro f hf hfs 
    rw [le_principal_iff] at hfs 
    obtain ⟨_, ⟨x, hx, rfl⟩, hyf⟩ : ∃ (y : _)(_ : y ∈ m '' s), map m f ≤ 𝓝 y 
    exact hs (f.map m) (hf.map hm.uniform_continuous) (le_principal_iff.2 (image_mem_map hfs))
    rw [map_le_iff_le_comap, ←nhds_induced, ←hm.inducing.induced] at hyf 
    exact ⟨x, hx, hyf⟩

theorem IsComplete.complete_space_coe {s : Set α} (hs : IsComplete s) : CompleteSpace s :=
  complete_space_iff_is_complete_univ.2$
    is_complete_of_complete_image uniform_embedding_subtype_coe.to_uniform_inducing$
      by 
        simp [hs]

-- error in Topology.UniformSpace.UniformEmbedding: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- A set is complete iff its image under a uniform inducing map is complete. -/
theorem is_complete_image_iff
{m : α → β}
{s : set α}
(hm : uniform_inducing m) : «expr ↔ »(is_complete «expr '' »(m, s), is_complete s) :=
begin
  refine [expr ⟨is_complete_of_complete_image hm, λ c, _⟩],
  haveI [] [":", expr complete_space s] [":=", expr c.complete_space_coe],
  set [] [ident m'] [":", expr s → β] [":="] [expr «expr ∘ »(m, coe)] [],
  suffices [] [":", expr is_complete (range m')],
  by rwa ["[", expr range_comp, ",", expr subtype.range_coe, "]"] ["at", ident this],
  have [ident hm'] [":", expr uniform_inducing m'] [":=", expr hm.comp uniform_embedding_subtype_coe.to_uniform_inducing],
  intros [ident f, ident hf, ident hfm],
  rw [expr filter.le_principal_iff] ["at", ident hfm],
  have [ident cf'] [":", expr cauchy (comap m' f)] [":=", expr hf.comap' hm'.comap_uniformity.le (ne_bot.comap_of_range_mem hf.1 hfm)],
  rcases [expr complete_space.complete cf', "with", "⟨", ident x, ",", ident hx, "⟩"],
  rw ["[", expr hm'.inducing.nhds_eq_comap, ",", expr comap_le_comap_iff hfm, "]"] ["at", ident hx],
  use ["[", expr m' x, ",", expr mem_range_self _, ",", expr hx, "]"]
end

theorem complete_space_iff_is_complete_range {f : α → β} (hf : UniformInducing f) :
  CompleteSpace α ↔ IsComplete (range f) :=
  by 
    rw [complete_space_iff_is_complete_univ, ←is_complete_image_iff hf, image_univ]

theorem UniformInducing.is_complete_range [CompleteSpace α] {f : α → β} (hf : UniformInducing f) :
  IsComplete (range f) :=
  (complete_space_iff_is_complete_range hf).1 ‹_›

theorem complete_space_congr {e : α ≃ β} (he : UniformEmbedding e) : CompleteSpace α ↔ CompleteSpace β :=
  by 
    rw [complete_space_iff_is_complete_range he.to_uniform_inducing, e.range_eq_univ,
      complete_space_iff_is_complete_univ]

theorem complete_space_coe_iff_is_complete {s : Set α} : CompleteSpace s ↔ IsComplete s :=
  (complete_space_iff_is_complete_range uniform_embedding_subtype_coe.to_uniform_inducing).trans$
    by 
      rw [Subtype.range_coe]

theorem IsClosed.complete_space_coe [CompleteSpace α] {s : Set α} (hs : IsClosed s) : CompleteSpace s :=
  hs.is_complete.complete_space_coe

theorem complete_space_extension {m : β → α} (hm : UniformInducing m) (dense : DenseRange m)
  (h : ∀ f : Filter β, Cauchy f → ∃ x : α, map m f ≤ 𝓝 x) : CompleteSpace α :=
  ⟨fun f : Filter α =>
      fun hf : Cauchy f =>
        let p : Set (α × α) → Set α → Set α := fun s t => { y:α | ∃ x : α, x ∈ t ∧ (x, y) ∈ s }
        let g := (𝓤 α).lift fun s => f.lift' (p s)
        have mp₀ : Monotone p := fun a b h t s ⟨x, xs, xa⟩ => ⟨x, xs, h xa⟩
        have mp₁ : ∀ {s}, Monotone (p s) := fun s a b h x ⟨y, ya, yxs⟩ => ⟨y, h ya, yxs⟩
        have  : f ≤ g :=
          le_infi$
            fun s =>
              le_infi$
                fun hs =>
                  le_infi$
                    fun t =>
                      le_infi$
                        fun ht => le_principal_iff.mpr$ mem_of_superset ht$ fun x hx => ⟨x, hx, refl_mem_uniformity hs⟩
        have  : ne_bot g := hf.left.mono this 
        have  : ne_bot (comap m g) :=
          comap_ne_bot$
            fun t ht =>
              let ⟨t', ht', ht_mem⟩ := (mem_lift_sets$ monotone_lift' monotone_const mp₀).mp ht 
              let ⟨t'', ht'', ht'_sub⟩ := (mem_lift'_sets mp₁).mp ht_mem 
              let ⟨x, (hx : x ∈ t'')⟩ := hf.left.nonempty_of_mem ht'' 
              have h₀ : ne_bot (𝓝[range m] x) := dense.nhds_within_ne_bot x 
              have h₁ : { y | (x, y) ∈ t' } ∈ 𝓝[range m] x :=
                @mem_inf_of_left α (𝓝 x) (𝓟 (range m)) _$ mem_nhds_left x ht' 
              have h₂ : range m ∈ 𝓝[range m] x := @mem_inf_of_right α (𝓝 x) (𝓟 (range m)) _$ subset.refl _ 
              have  : { y | (x, y) ∈ t' } ∩ range m ∈ 𝓝[range m] x := @inter_mem α (𝓝[range m] x) _ _ h₁ h₂ 
              let ⟨y, xyt', b, b_eq⟩ := h₀.nonempty_of_mem this
              ⟨b, b_eq.symm ▸ ht'_sub ⟨x, hx, xyt'⟩⟩
        have  : Cauchy g :=
          ⟨‹ne_bot g›,
            fun s hs =>
              let ⟨s₁, hs₁, (comp_s₁ : CompRel s₁ s₁ ⊆ s)⟩ := comp_mem_uniformity_sets hs 
              let ⟨s₂, hs₂, (comp_s₂ : CompRel s₂ s₂ ⊆ s₁)⟩ := comp_mem_uniformity_sets hs₁ 
              let ⟨t, ht, (prod_t : Set.Prod t t ⊆ s₂)⟩ := mem_prod_same_iff.mp (hf.right hs₂)
              have hg₁ : p (preimage Prod.swap s₁) t ∈ g := mem_lift (symm_le_uniformity hs₁)$ @mem_lift' α α f _ t ht 
              have hg₂ : p s₂ t ∈ g := mem_lift hs₂$ @mem_lift' α α f _ t ht 
              have hg : Set.Prod (p (preimage Prod.swap s₁) t) (p s₂ t) ∈ g ×ᶠ g := @prod_mem_prod α α _ _ g g hg₁ hg₂
              (g ×ᶠ g).sets_of_superset hg
                fun ⟨a, b⟩ ⟨⟨c₁, c₁t, hc₁⟩, ⟨c₂, c₂t, hc₂⟩⟩ =>
                  have  : (c₁, c₂) ∈ Set.Prod t t := ⟨c₁t, c₂t⟩
                  comp_s₁$ prod_mk_mem_comp_rel hc₁$ comp_s₂$ prod_mk_mem_comp_rel (prod_t this) hc₂⟩
        have  : Cauchy (Filter.comap m g) := ‹Cauchy g›.comap' (le_of_eqₓ hm.comap_uniformity) ‹_›
        let ⟨x, (hx : map m (Filter.comap m g) ≤ 𝓝 x)⟩ := h _ this 
        have  : ClusterPt x (map m (Filter.comap m g)) :=
          (le_nhds_iff_adhp_of_cauchy (this.map hm.uniform_continuous)).mp hx 
        have  : ClusterPt x g := this.mono map_comap_le
        ⟨x,
          calc f ≤ g :=
            by 
              assumption 
            _ ≤ 𝓝 x := le_nhds_of_cauchy_adhp ‹Cauchy g› this
            ⟩⟩

-- error in Topology.UniformSpace.UniformEmbedding: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem totally_bounded_preimage
{f : α → β}
{s : set β}
(hf : uniform_embedding f)
(hs : totally_bounded s) : totally_bounded «expr ⁻¹' »(f, s) :=
λ t ht, begin
  rw ["<-", expr hf.comap_uniformity] ["at", ident ht],
  rcases [expr mem_comap.2 ht, "with", "⟨", ident t', ",", ident ht', ",", ident ts, "⟩"],
  rcases [expr totally_bounded_iff_subset.1 (totally_bounded_subset (image_preimage_subset f s) hs) _ ht', "with", "⟨", ident c, ",", ident cs, ",", ident hfc, ",", ident hct, "⟩"],
  refine [expr ⟨«expr ⁻¹' »(f, c), hfc.preimage (hf.inj.inj_on _), λ x h, _⟩],
  have [] [] [":=", expr hct (mem_image_of_mem f h)],
  simp [] [] [] [] [] ["at", ident this, "⊢"],
  rcases [expr this, "with", "⟨", ident z, ",", ident zc, ",", ident zt, "⟩"],
  rcases [expr cs zc, "with", "⟨", ident y, ",", ident yc, ",", ident rfl, "⟩"],
  exact [expr ⟨y, zc, ts (by exact [expr zt])⟩]
end

end 

theorem uniform_embedding_comap {α : Type _} {β : Type _} {f : α → β} [u : UniformSpace β] (hf : Function.Injective f) :
  @UniformEmbedding α β (UniformSpace.comap f u) u f :=
  @UniformEmbedding.mk _ _ (UniformSpace.comap f u) _ _ (@UniformInducing.mk _ _ (UniformSpace.comap f u) _ _ rfl) hf

section UniformExtension

variable{α :
    Type
      _}{β :
    Type
      _}{γ :
    Type
      _}[UniformSpace
      α][UniformSpace
      β][UniformSpace
      γ]{e : β → α}(h_e : UniformInducing e)(h_dense : DenseRange e){f : β → γ}(h_f : UniformContinuous f)

local notation "ψ" => (h_e.dense_inducing h_dense).extend f

theorem uniformly_extend_exists [CompleteSpace γ] (a : α) : ∃ c, tendsto f (comap e (𝓝 a)) (𝓝 c) :=
  let de := h_e.dense_inducing h_dense 
  have  : Cauchy (𝓝 a) := cauchy_nhds 
  have  : Cauchy (comap e (𝓝 a)) := this.comap' (le_of_eqₓ h_e.comap_uniformity) (de.comap_nhds_ne_bot _)
  have  : Cauchy (map f (comap e (𝓝 a))) := this.map h_f 
  CompleteSpace.complete this

theorem uniform_extend_subtype [CompleteSpace γ] {p : α → Prop} {e : α → β} {f : α → γ} {b : β} {s : Set α}
  (hf : UniformContinuous fun x : Subtype p => f x.val) (he : UniformEmbedding e) (hd : ∀ x : β, x ∈ Closure (range e))
  (hb : Closure (e '' s) ∈ 𝓝 b) (hs : IsClosed s) (hp : ∀ x _ : x ∈ s, p x) : ∃ c, tendsto f (comap e (𝓝 b)) (𝓝 c) :=
  have de : DenseEmbedding e := he.dense_embedding hd 
  have de' : DenseEmbedding (DenseEmbedding.subtypeEmb p e) :=
    by 
      exact de.subtype p 
  have ue' : UniformEmbedding (DenseEmbedding.subtypeEmb p e) := uniform_embedding_subtype_emb _ he de 
  have  : b ∈ Closure (e '' { x | p x }) := (closure_mono$ monotone_image$ hp) (mem_of_mem_nhds hb)
  let ⟨c, (hc : tendsto (f ∘ Subtype.val) (comap (DenseEmbedding.subtypeEmb p e) (𝓝 ⟨b, this⟩)) (𝓝 c))⟩ :=
    uniformly_extend_exists ue'.to_uniform_inducing de'.dense hf _ 
  by 
    rw [nhds_subtype_eq_comap] at hc 
    simp [comap_comap] at hc 
    change tendsto (f ∘ @Subtype.val α p) (comap (e ∘ @Subtype.val α p) (𝓝 b)) (𝓝 c) at hc 
    rw [←comap_comap, tendsto_comap'_iff] at hc 
    exact ⟨c, hc⟩
    exact
      ⟨_, hb,
        fun x =>
          by 
            change e x ∈ Closure (e '' s) → x ∈ range Subtype.val 
            rw [←closure_induced, mem_closure_iff_cluster_pt, ClusterPt, ne_bot_iff, nhds_induced,
              ←de.to_dense_inducing.nhds_eq_comap, ←mem_closure_iff_nhds_ne_bot, hs.closure_eq]
            exact fun hxs => ⟨⟨x, hp x hxs⟩, rfl⟩⟩

variable[SeparatedSpace γ]

theorem uniformly_extend_of_ind (b : β) : ψ (e b) = f b :=
  DenseInducing.extend_eq_at _ h_f.continuous.continuous_at

theorem uniformly_extend_unique {g : α → γ} (hg : ∀ b, g (e b) = f b) (hc : Continuous g) : ψ = g :=
  DenseInducing.extend_unique _ hg hc

include h_f

theorem uniformly_extend_spec [CompleteSpace γ] (a : α) : tendsto f (comap e (𝓝 a)) (𝓝 (ψ a)) :=
  let de := h_e.dense_inducing h_dense 
  by 
    byCases' ha : a ∈ range e
    ·
      rcases ha with ⟨b, rfl⟩
      rw [uniformly_extend_of_ind _ _ h_f, ←de.nhds_eq_comap]
      exact h_f.continuous.tendsto _
    ·
      simp only [DenseInducing.extend, dif_neg ha]
      exact tendsto_nhds_lim (uniformly_extend_exists h_e h_dense h_f _)

theorem uniform_continuous_uniformly_extend [cγ : CompleteSpace γ] : UniformContinuous ψ :=
  fun d hd =>
    let ⟨s, hs, hs_comp⟩ :=
      (mem_lift'_sets$ monotone_comp_rel monotone_id$ monotone_comp_rel monotone_id monotone_id).mp
        (comp_le_uniformity3 hd)
    have h_pnt : ∀ {a m}, m ∈ 𝓝 a → ∃ c, c ∈ f '' preimage e m ∧ (c, ψ a) ∈ s ∧ (ψ a, c) ∈ s :=
      fun a m hm =>
        have nb : ne_bot (map f (comap e (𝓝 a))) := ((h_e.dense_inducing h_dense).comap_nhds_ne_bot _).map _ 
        have  : f '' preimage e m ∩ ({ c | (c, ψ a) ∈ s } ∩ { c | (ψ a, c) ∈ s }) ∈ map f (comap e (𝓝 a)) :=
          inter_mem (image_mem_map$ preimage_mem_comap$ hm)
            (uniformly_extend_spec h_e h_dense h_f _ (inter_mem (mem_nhds_right _ hs) (mem_nhds_left _ hs)))
        nb.nonempty_of_mem this 
    have  : preimage (fun p : β × β => (f p.1, f p.2)) s ∈ 𝓤 β := h_f hs 
    have  : preimage (fun p : β × β => (f p.1, f p.2)) s ∈ comap (fun x : β × β => (e x.1, e x.2)) (𝓤 α) :=
      by 
        rwa [h_e.comap_uniformity.symm] at this 
    let ⟨t, ht, ts⟩ := this 
    show preimage (fun p : α × α => (ψ p.1, ψ p.2)) d ∈ 𝓤 α from
      (𝓤 α).sets_of_superset (interior_mem_uniformity ht)$
        fun ⟨x₁, x₂⟩ hx_t =>
          have  : 𝓝 (x₁, x₂) ≤ 𝓟 (Interior t) := is_open_iff_nhds.mp is_open_interior (x₁, x₂) hx_t 
          have  : Interior t ∈ 𝓝 x₁ ×ᶠ 𝓝 x₂ :=
            by 
              rwa [nhds_prod_eq, le_principal_iff] at this 
          let ⟨m₁, hm₁, m₂, hm₂, (hm : Set.Prod m₁ m₂ ⊆ Interior t)⟩ := mem_prod_iff.mp this 
          let ⟨a, ha₁, _, ha₂⟩ := h_pnt hm₁ 
          let ⟨b, hb₁, hb₂, _⟩ := h_pnt hm₂ 
          have  : Set.Prod (preimage e m₁) (preimage e m₂) ⊆ preimage (fun p : β × β => (f p.1, f p.2)) s :=
            calc _ ⊆ preimage (fun p : β × β => (e p.1, e p.2)) (Interior t) := preimage_mono hm 
              _ ⊆ preimage (fun p : β × β => (e p.1, e p.2)) t := preimage_mono interior_subset 
              _ ⊆ preimage (fun p : β × β => (f p.1, f p.2)) s := ts 
              
          have  : Set.Prod (f '' preimage e m₁) (f '' preimage e m₂) ⊆ s :=
            calc
              Set.Prod (f '' preimage e m₁) (f '' preimage e m₂) =
                (fun p : β × β => (f p.1, f p.2)) '' Set.Prod (preimage e m₁) (preimage e m₂) :=
              prod_image_image_eq 
              _ ⊆ (fun p : β × β => (f p.1, f p.2)) '' preimage (fun p : β × β => (f p.1, f p.2)) s :=
              monotone_image this 
              _ ⊆ s := image_subset_iff.mpr$ subset.refl _ 
              
          have  : (a, b) ∈ s := @this (a, b) ⟨ha₁, hb₁⟩
          hs_comp$ show (ψ x₁, ψ x₂) ∈ CompRel s (CompRel s s) from ⟨a, ha₂, ⟨b, this, hb₂⟩⟩

end UniformExtension

