import Mathbin.Topology.Category.Top.EpiMono
import Mathbin.CategoryTheory.Limits.Preserves.Limits
import Mathbin.CategoryTheory.Category.Ulift
import Mathbin.CategoryTheory.Limits.Shapes.Types
import Mathbin.CategoryTheory.Limits.ConcreteCategory

/-!
# The category of topological spaces has all limits and colimits

Further, these limits and colimits are preserved by the forgetful functor --- that is, the
underlying types are just the limits in the category of types.
-/


open TopologicalSpace

open CategoryTheory

open CategoryTheory.Limits

open Opposite

universe u v w

noncomputable section

namespace Top

variable {J : Type u} [small_category J]

local notation "forget" => forget Top

/-- A choice of limit cone for a functor `F : J ⥤ Top`.
Generally you should just use `limit.cone F`, unless you need the actual definition
(which is in terms of `types.limit_cone`).
-/
def limit_cone (F : J ⥤ Top.{u}) : cone F where
  x := Top.of { u : ∀ j : J, F.obj j | ∀ {i j : J} f : i ⟶ j, F.map f (u i) = u j }
  π :=
    { app := fun j =>
        { toFun := fun u => u.val j,
          continuous_to_fun :=
            show Continuous ((fun u : ∀ j : J, F.obj j => u j) ∘ Subtype.val) by
              continuity } }

/-- A choice of limit cone for a functor `F : J ⥤ Top` whose topology is defined as an
infimum of topologies infimum.
Generally you should just use `limit.cone F`, unless you need the actual definition
(which is in terms of `types.limit_cone`).
-/
def limit_cone_infi (F : J ⥤ Top.{u}) : cone F where
  x := ⟨(types.limit_cone (F ⋙ forget)).x, ⨅ j, (F.obj j).str.induced ((types.limit_cone (F ⋙ forget)).π.app j)⟩
  π :=
    { app := fun j => ⟨(types.limit_cone (F ⋙ forget)).π.app j, continuous_iff_le_induced.mpr (infi_le _ _)⟩,
      naturality' := fun j j' f => ContinuousMap.coe_inj ((types.limit_cone (F ⋙ forget)).π.naturality f) }

/-- The chosen cone `Top.limit_cone F` for a functor `F : J ⥤ Top` is a limit cone.
Generally you should just use `limit.is_limit F`, unless you need the actual definition
(which is in terms of `types.limit_cone_is_limit`).
-/
def limit_cone_is_limit (F : J ⥤ Top.{u}) : is_limit (limit_cone F) where
  lift := fun S =>
    { toFun := fun x =>
        ⟨fun j => S.π.app _ x, fun i j f => by
          dsimp
          erw [← S.w f]
          rfl⟩ }
  uniq' := fun S m h => by
    ext : 3
    simpa [← h]

/-- The chosen cone `Top.limit_cone_infi F` for a functor `F : J ⥤ Top` is a limit cone.
Generally you should just use `limit.is_limit F`, unless you need the actual definition
(which is in terms of `types.limit_cone_is_limit`).
-/
def limit_cone_infi_is_limit (F : J ⥤ Top.{u}) : is_limit (limit_cone_infi F) := by
  refine' is_limit.of_faithful forget (types.limit_cone_is_limit _) (fun s => ⟨_, _⟩) fun s => rfl
  exact
    continuous_iff_coinduced_le.mpr
      (le_infi $ fun j => coinduced_le_iff_le_induced.mp $ (continuous_iff_coinduced_le.mp (s.π.app j).Continuous : _))

instance Top_has_limits : has_limits.{u} Top.{u} where
  HasLimitsOfShape := fun J 𝒥 =>
    { HasLimit := fun F => has_limit.mk { Cone := limit_cone F, IsLimit := limit_cone_is_limit F } }

instance forget_preserves_limits : preserves_limits (forget : Top.{u} ⥤ Type u) where
  PreservesLimitsOfShape := fun J 𝒥 =>
    { PreservesLimit := fun F =>
        preserves_limit_of_preserves_limit_cone (limit_cone_is_limit F) (types.limit_cone_is_limit (F ⋙ forget)) }

/-- A choice of colimit cocone for a functor `F : J ⥤ Top`.
Generally you should just use `colimit.coone F`, unless you need the actual definition
(which is in terms of `types.colimit_cocone`).
-/
def colimit_cocone (F : J ⥤ Top.{u}) : cocone F where
  x :=
    ⟨(types.colimit_cocone (F ⋙ forget)).x, ⨆ j, (F.obj j).str.coinduced ((types.colimit_cocone (F ⋙ forget)).ι.app j)⟩
  ι :=
    { app := fun j => ⟨(types.colimit_cocone (F ⋙ forget)).ι.app j, continuous_iff_coinduced_le.mpr (le_supr _ j)⟩,
      naturality' := fun j j' f => ContinuousMap.coe_inj ((types.colimit_cocone (F ⋙ forget)).ι.naturality f) }

/-- The chosen cocone `Top.colimit_cocone F` for a functor `F : J ⥤ Top` is a colimit cocone.
Generally you should just use `colimit.is_colimit F`, unless you need the actual definition
(which is in terms of `types.colimit_cocone_is_colimit`).
-/
def colimit_cocone_is_colimit (F : J ⥤ Top.{u}) : is_colimit (colimit_cocone F) := by
  refine' is_colimit.of_faithful forget (types.colimit_cocone_is_colimit _) (fun s => ⟨_, _⟩) fun s => rfl
  exact
    continuous_iff_le_induced.mpr
      (supr_le $ fun j => coinduced_le_iff_le_induced.mp $ (continuous_iff_coinduced_le.mp (s.ι.app j).Continuous : _))

instance Top_has_colimits : has_colimits.{u} Top.{u} where
  HasColimitsOfShape := fun J 𝒥 =>
    { HasColimit := fun F => has_colimit.mk { Cocone := colimit_cocone F, IsColimit := colimit_cocone_is_colimit F } }

instance forget_preserves_colimits : preserves_colimits (forget : Top.{u} ⥤ Type u) where
  PreservesColimitsOfShape := fun J 𝒥 =>
    { PreservesColimit := fun F =>
        preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
          (types.colimit_cocone_is_colimit (F ⋙ forget)) }

/-- The projection from the product as a bundled continous map. -/
abbrev pi_π {ι : Type u} (α : ι → Top.{u}) (i : ι) : Top.of (∀ i, α i) ⟶ α i :=
  ⟨fun f => f i, continuous_apply i⟩

/-- The explicit fan of a family of topological spaces given by the pi type. -/
@[simps x π_app]
def pi_fan {ι : Type u} (α : ι → Top.{u}) : fan α :=
  fan.mk (Top.of (∀ i, α i)) (pi_π α)

/-- The constructed fan is indeed a limit -/
def pi_fan_is_limit {ι : Type u} (α : ι → Top.{u}) : is_limit (pi_fan α) where
  lift := fun S => { toFun := fun s i => S.π.app i s }
  uniq' := by
    intro S m h
    ext x i
    simp [← h i]

/-- The product is homeomorphic to the product of the underlying spaces,
equipped with the product topology.
-/
def pi_iso_pi {ι : Type u} (α : ι → Top.{u}) : ∏ α ≅ Top.of (∀ i, α i) :=
  (limit.is_limit _).conePointUniqueUpToIso (pi_fan_is_limit α)

@[simp, reassoc]
theorem pi_iso_pi_inv_π {ι : Type u} (α : ι → Top) (i : ι) : (pi_iso_pi α).inv ≫ pi.π α i = pi_π α i := by
  simp [pi_iso_pi]

@[simp]
theorem pi_iso_pi_inv_π_apply {ι : Type u} (α : ι → Top.{u}) (i : ι) (x : ∀ i, α i) :
    (pi.π α i : _) ((pi_iso_pi α).inv x) = x i :=
  concrete_category.congr_hom (pi_iso_pi_inv_π α i) x

@[simp]
theorem pi_iso_pi_hom_apply {ι : Type u} (α : ι → Top.{u}) (i : ι) (x : ∏ α) :
    (pi_iso_pi α).Hom x i = (pi.π α i : _) x := by
  have := pi_iso_pi_inv_π α i
  rw [iso.inv_comp_eq] at this
  exact concrete_category.congr_hom this x

/-- The inclusion to the coproduct as a bundled continous map. -/
abbrev sigma_ι {ι : Type u} (α : ι → Top.{u}) (i : ι) : α i ⟶ Top.of (Σ i, α i) :=
  ⟨Sigma.mk i⟩

/-- The explicit cofan of a family of topological spaces given by the sigma type. -/
@[simps x ι_app]
def sigma_cofan {ι : Type u} (α : ι → Top.{u}) : cofan α :=
  cofan.mk (Top.of (Σ i, α i)) (sigma_ι α)

/-- The constructed cofan is indeed a colimit -/
def sigma_cofan_is_colimit {ι : Type u} (α : ι → Top.{u}) : is_colimit (sigma_cofan α) where
  desc := fun S =>
    { toFun := fun s => S.ι.app s.1 s.2,
      continuous_to_fun := by
        continuity
        dsimp only
        continuity }
  uniq' := by
    intro S m h
    ext ⟨i, x⟩
    simp [← h i]

/-- The coproduct is homeomorphic to the disjoint union of the topological spaces.
-/
def sigma_iso_sigma {ι : Type u} (α : ι → Top.{u}) : ∐ α ≅ Top.of (Σ i, α i) :=
  (colimit.is_colimit _).coconePointUniqueUpToIso (sigma_cofan_is_colimit α)

@[simp, reassoc]
theorem sigma_iso_sigma_hom_ι {ι : Type u} (α : ι → Top) (i : ι) :
    sigma.ι α i ≫ (sigma_iso_sigma α).Hom = sigma_ι α i := by
  simp [sigma_iso_sigma]

@[simp]
theorem sigma_iso_sigma_hom_ι_apply {ι : Type u} (α : ι → Top) (i : ι) (x : α i) :
    (sigma_iso_sigma α).Hom ((sigma.ι α i : _) x) = Sigma.mk i x :=
  concrete_category.congr_hom (sigma_iso_sigma_hom_ι α i) x

@[simp]
theorem sigma_iso_sigma_inv_apply {ι : Type u} (α : ι → Top) (i : ι) (x : α i) :
    (sigma_iso_sigma α).inv ⟨i, x⟩ = (sigma.ι α i : _) x := by
  rw [← sigma_iso_sigma_hom_ι_apply, ← comp_app]
  simp

theorem induced_of_is_limit {F : J ⥤ Top.{u}} (C : cone F) (hC : is_limit C) :
    C.X.topological_space = ⨅ j, (F.obj j).TopologicalSpace.induced (C.π.app j) := by
  let homeo := homeo_of_iso (hC.cone_point_unique_up_to_iso (limit_cone_infi_is_limit F))
  refine' homeo.inducing.induced.trans _
  change induced homeo (⨅ j : J, _) = _
  simpa [induced_infi, induced_compose]

theorem limit_topology (F : J ⥤ Top.{u}) :
    (limit F).TopologicalSpace = ⨅ j, (F.obj j).TopologicalSpace.induced (limit.π F j) :=
  induced_of_is_limit _ (limit.is_limit F)

section Prod

/-- The first projection from the product. -/
abbrev prod_fst {X Y : Top.{u}} : Top.of (X × Y) ⟶ X :=
  ⟨Prod.fst⟩

/-- The second projection from the product. -/
abbrev prod_snd {X Y : Top.{u}} : Top.of (X × Y) ⟶ Y :=
  ⟨Prod.snd⟩

/-- The explicit binary cofan of `X, Y` given by `X × Y`. -/
def prod_binary_fan (X Y : Top.{u}) : binary_fan X Y :=
  binary_fan.mk prod_fst prod_snd

/-- The constructed binary fan is indeed a limit -/
def prod_binary_fan_is_limit (X Y : Top.{u}) : is_limit (prod_binary_fan X Y) where
  lift := fun S : binary_fan X Y => { toFun := fun s => (S.fst s, S.snd s) }
  fac' := by
    rintro S (_ | _)
    tidy
  uniq' := by
    intro S m h
    ext x
    · specialize h walking_pair.left
      apply_fun fun e => e x  at h
      exact h
      
    · specialize h walking_pair.right
      apply_fun fun e => e x  at h
      exact h
      

/-- The homeomorphism between `X ⨯ Y` and the set-theoretic product of `X` and `Y`,
equipped with the product topology.
-/
def prod_iso_prod (X Y : Top.{u}) : X ⨯ Y ≅ Top.of (X × Y) :=
  (limit.is_limit _).conePointUniqueUpToIso (prod_binary_fan_is_limit X Y)

@[simp, reassoc]
theorem prod_iso_prod_hom_fst (X Y : Top.{u}) : (prod_iso_prod X Y).Hom ≫ prod_fst = limits.prod.fst := by
  simpa [← iso.eq_inv_comp, prod_iso_prod]

@[simp, reassoc]
theorem prod_iso_prod_hom_snd (X Y : Top.{u}) : (prod_iso_prod X Y).Hom ≫ prod_snd = limits.prod.snd := by
  simpa [← iso.eq_inv_comp, prod_iso_prod]

@[simp]
theorem prod_iso_prod_hom_apply {X Y : Top.{u}} (x : X ⨯ Y) :
    (prod_iso_prod X Y).Hom x = ((limits.prod.fst : X ⨯ Y ⟶ _) x, (limits.prod.snd : X ⨯ Y ⟶ _) x) := by
  ext
  · exact concrete_category.congr_hom (prod_iso_prod_hom_fst X Y) x
    
  · exact concrete_category.congr_hom (prod_iso_prod_hom_snd X Y) x
    

@[simp, reassoc, elementwise]
theorem prod_iso_prod_inv_fst (X Y : Top.{u}) : (prod_iso_prod X Y).inv ≫ limits.prod.fst = prod_fst := by
  simp [iso.inv_comp_eq]

@[simp, reassoc, elementwise]
theorem prod_iso_prod_inv_snd (X Y : Top.{u}) : (prod_iso_prod X Y).inv ≫ limits.prod.snd = prod_snd := by
  simp [iso.inv_comp_eq]

theorem prod_topology {X Y : Top} :
    (X ⨯ Y).TopologicalSpace =
      induced (limits.prod.fst : X ⨯ Y ⟶ _)
          X.topological_space⊓induced (limits.prod.snd : X ⨯ Y ⟶ _) Y.topological_space :=
  by
  let homeo := homeo_of_iso (prod_iso_prod X Y)
  refine' homeo.inducing.induced.trans _
  change induced homeo (_⊓_) = _
  simpa [induced_compose]

theorem range_prod_map {W X Y Z : Top.{u}} (f : W ⟶ Y) (g : X ⟶ Z) :
    Set.Range (limits.prod.map f g) =
      (limits.prod.fst : Y ⨯ Z ⟶ _) ⁻¹' Set.Range f ∩ (limits.prod.snd : Y ⨯ Z ⟶ _) ⁻¹' Set.Range g :=
  by
  ext
  constructor
  · rintro ⟨y, rfl⟩
    simp only [Set.mem_preimage, Set.mem_range, Set.mem_inter_eq, ← comp_apply]
    simp only [limits.prod.map_fst, limits.prod.map_snd, exists_apply_eq_applyₓ, comp_apply, and_selfₓ]
    
  · rintro ⟨⟨x₁, hx₁⟩, ⟨x₂, hx₂⟩⟩
    use (prod_iso_prod W X).inv (x₁, x₂)
    apply concrete.limit_ext
    rintro ⟨⟩
    · simp only [← comp_apply, category.assoc]
      erw [limits.prod.map_fst]
      simp [hx₁]
      
    · simp only [← comp_apply, category.assoc]
      erw [limits.prod.map_snd]
      simp [hx₂]
      
    

theorem inducing_prod_map {W X Y Z : Top} {f : W ⟶ X} {g : Y ⟶ Z} (hf : Inducing f) (hg : Inducing g) :
    Inducing (limits.prod.map f g) := by
  constructor
  simp only [prod_topology, induced_compose, ← coe_comp, limits.prod.map_fst, limits.prod.map_snd, induced_inf]
  simp only [coe_comp]
  rw [← @induced_compose _ _ _ _ _ f, ← @induced_compose _ _ _ _ _ g, ← hf.induced, ← hg.induced]

theorem embedding_prod_map {W X Y Z : Top} {f : W ⟶ X} {g : Y ⟶ Z} (hf : Embedding f) (hg : Embedding g) :
    Embedding (limits.prod.map f g) :=
  ⟨inducing_prod_map hf.to_inducing hg.to_inducing, by
    have := (Top.mono_iff_injective _).mpr hf.inj
    have := (Top.mono_iff_injective _).mpr hg.inj
    exact (Top.mono_iff_injective _).mp inferInstance⟩

end Prod

section Pullback

variable {X Y Z : Top.{u}}

/-- The first projection from the pullback. -/
abbrev pullback_fst (f : X ⟶ Z) (g : Y ⟶ Z) : Top.of { p : X × Y // f p.1 = g p.2 } ⟶ X :=
  ⟨Prod.fst ∘ Subtype.val⟩

/-- The second projection from the pullback. -/
abbrev pullback_snd (f : X ⟶ Z) (g : Y ⟶ Z) : Top.of { p : X × Y // f p.1 = g p.2 } ⟶ Y :=
  ⟨Prod.snd ∘ Subtype.val⟩

/-- The explicit pullback cone of `X, Y` given by `{ p : X × Y // f p.1 = g p.2 }`. -/
def pullback_cone (f : X ⟶ Z) (g : Y ⟶ Z) : pullback_cone f g :=
  pullback_cone.mk (pullback_fst f g) (pullback_snd f g)
    (by
      ext ⟨x, h⟩
      simp [h])

/-- The constructed cone is a limit. -/
def pullback_cone_is_limit (f : X ⟶ Z) (g : Y ⟶ Z) : is_limit (pullback_cone f g) :=
  pullback_cone.is_limit_aux' _
    (by
      intro s
      constructor
      swap
      exact
        { toFun := fun x =>
            ⟨⟨s.fst x, s.snd x⟩, by
              simpa using concrete_category.congr_hom s.condition x⟩ }
      refine' ⟨_, _, _⟩
      · ext
        delta' pullback_cone
        simp
        
      · ext
        delta' pullback_cone
        simp
        
      · intro m h₁ h₂
        ext x
        · simpa using concrete_category.congr_hom h₁ x
          
        · simpa using concrete_category.congr_hom h₂ x
          
        )

/-- The pullback of two maps can be identified as a subspace of `X × Y`. -/
def pullback_iso_prod_subtype (f : X ⟶ Z) (g : Y ⟶ Z) : pullback f g ≅ Top.of { p : X × Y // f p.1 = g p.2 } :=
  (limit.is_limit _).conePointUniqueUpToIso (pullback_cone_is_limit f g)

@[simp, reassoc]
theorem pullback_iso_prod_subtype_inv_fst (f : X ⟶ Z) (g : Y ⟶ Z) :
    (pullback_iso_prod_subtype f g).inv ≫ pullback.fst = pullback_fst f g := by
  simpa [pullback_iso_prod_subtype]

@[simp]
theorem pullback_iso_prod_subtype_inv_fst_apply (f : X ⟶ Z) (g : Y ⟶ Z) (x : { p : X × Y // f p.1 = g p.2 }) :
    (pullback.fst : pullback f g ⟶ _) ((pullback_iso_prod_subtype f g).inv x) = (x : X × Y).fst :=
  concrete_category.congr_hom (pullback_iso_prod_subtype_inv_fst f g) x

@[simp, reassoc]
theorem pullback_iso_prod_subtype_inv_snd (f : X ⟶ Z) (g : Y ⟶ Z) :
    (pullback_iso_prod_subtype f g).inv ≫ pullback.snd = pullback_snd f g := by
  simpa [pullback_iso_prod_subtype]

@[simp]
theorem pullback_iso_prod_subtype_inv_snd_apply (f : X ⟶ Z) (g : Y ⟶ Z) (x : { p : X × Y // f p.1 = g p.2 }) :
    (pullback.snd : pullback f g ⟶ _) ((pullback_iso_prod_subtype f g).inv x) = (x : X × Y).snd :=
  concrete_category.congr_hom (pullback_iso_prod_subtype_inv_snd f g) x

theorem pullback_iso_prod_subtype_hom_fst (f : X ⟶ Z) (g : Y ⟶ Z) :
    (pullback_iso_prod_subtype f g).Hom ≫ pullback_fst f g = pullback.fst := by
  rw [← iso.eq_inv_comp, pullback_iso_prod_subtype_inv_fst]

theorem pullback_iso_prod_subtype_hom_snd (f : X ⟶ Z) (g : Y ⟶ Z) :
    (pullback_iso_prod_subtype f g).Hom ≫ pullback_snd f g = pullback.snd := by
  rw [← iso.eq_inv_comp, pullback_iso_prod_subtype_inv_snd]

@[simp]
theorem pullback_iso_prod_subtype_hom_apply {f : X ⟶ Z} {g : Y ⟶ Z} (x : pullback f g) :
    (pullback_iso_prod_subtype f g).Hom x =
      ⟨⟨(pullback.fst : pullback f g ⟶ _) x, (pullback.snd : pullback f g ⟶ _) x⟩, by
        simpa using concrete_category.congr_hom pullback.condition x⟩ :=
  by
  ext
  exacts[concrete_category.congr_hom (pullback_iso_prod_subtype_hom_fst f g) x,
    concrete_category.congr_hom (pullback_iso_prod_subtype_hom_snd f g) x]

theorem pullback_topology {X Y Z : Top.{u}} (f : X ⟶ Z) (g : Y ⟶ Z) :
    (pullback f g).TopologicalSpace =
      induced (pullback.fst : pullback f g ⟶ _)
          X.topological_space⊓induced (pullback.snd : pullback f g ⟶ _) Y.topological_space :=
  by
  let homeo := homeo_of_iso (pullback_iso_prod_subtype f g)
  refine' homeo.inducing.induced.trans _
  change induced homeo (induced _ (_⊓_)) = _
  simpa [induced_compose]

theorem range_pullback_to_prod {X Y Z : Top} (f : X ⟶ Z) (g : Y ⟶ Z) :
    Set.Range (prod.lift pullback.fst pullback.snd : pullback f g ⟶ X ⨯ Y) =
      { x | (limits.prod.fst ≫ f) x = (limits.prod.snd ≫ g) x } :=
  by
  ext x
  constructor
  · rintro ⟨y, rfl⟩
    simp only [← comp_apply, Set.mem_set_of_eq]
    congr 1
    simp [pullback.condition]
    
  · intro h
    use (pullback_iso_prod_subtype f g).inv ⟨⟨_, _⟩, h⟩
    apply concrete.limit_ext
    rintro ⟨⟩ <;> simp
    

theorem inducing_pullback_to_prod {X Y Z : Top} (f : X ⟶ Z) (g : Y ⟶ Z) :
    Inducing (⇑(prod.lift pullback.fst pullback.snd : pullback f g ⟶ X ⨯ Y)) :=
  ⟨by
    simp [prod_topology, pullback_topology, induced_compose, ← coe_comp]⟩

theorem embedding_pullback_to_prod {X Y Z : Top} (f : X ⟶ Z) (g : Y ⟶ Z) :
    Embedding (⇑(prod.lift pullback.fst pullback.snd : pullback f g ⟶ X ⨯ Y)) :=
  ⟨inducing_pullback_to_prod f g, (Top.mono_iff_injective _).mp inferInstance⟩

/-- If the map `S ⟶ T` is mono, then there is a description of the image of `W ×ₛ X ⟶ Y ×ₜ Z`. -/
theorem range_pullback_map {W X Y Z S T : Top} (f₁ : W ⟶ S) (f₂ : X ⟶ S) (g₁ : Y ⟶ T) (g₂ : Z ⟶ T) (i₁ : W ⟶ Y)
    (i₂ : X ⟶ Z) (i₃ : S ⟶ T) [H₃ : mono i₃] (eq₁ : f₁ ≫ i₃ = i₁ ≫ g₁) (eq₂ : f₂ ≫ i₃ = i₂ ≫ g₂) :
    Set.Range (pullback.map f₁ f₂ g₁ g₂ i₁ i₂ i₃ eq₁ eq₂) =
      (pullback.fst : pullback g₁ g₂ ⟶ _) ⁻¹' Set.Range i₁ ∩ (pullback.snd : pullback g₁ g₂ ⟶ _) ⁻¹' Set.Range i₂ :=
  by
  ext
  constructor
  · rintro ⟨y, rfl⟩
    simp
    
  rintro ⟨⟨x₁, hx₁⟩, ⟨x₂, hx₂⟩⟩
  have : f₁ x₁ = f₂ x₂ := by
    apply (Top.mono_iff_injective _).mp H₃
    simp only [← comp_apply, eq₁, eq₂]
    simp only [comp_apply, hx₁, hx₂]
    simp only [← comp_apply, pullback.condition]
  use (pullback_iso_prod_subtype f₁ f₂).inv ⟨⟨x₁, x₂⟩, this⟩
  apply concrete.limit_ext
  rintro (_ | _ | _)
  · simp only [Top.comp_app, limit.lift_π_apply, category.assoc, pullback_cone.mk_π_app_one, hx₁,
      pullback_iso_prod_subtype_inv_fst_apply, Subtype.coe_mk]
    simp only [← comp_apply]
    congr
    apply limit.w _ walking_cospan.hom.inl
    
  · simp [hx₁]
    
  · simp [hx₂]
    

theorem pullback_fst_range {X Y S : Top} (f : X ⟶ S) (g : Y ⟶ S) :
    Set.Range (pullback.fst : pullback f g ⟶ _) = { x : X | ∃ y : Y, f x = g y } := by
  ext x
  constructor
  · rintro ⟨y, rfl⟩
    use (pullback.snd : pullback f g ⟶ _) y
    exact concrete_category.congr_hom pullback.condition y
    
  · rintro ⟨y, eq⟩
    use (Top.pullbackIsoProdSubtype f g).inv ⟨⟨x, y⟩, Eq⟩
    simp
    

theorem pullback_snd_range {X Y S : Top} (f : X ⟶ S) (g : Y ⟶ S) :
    Set.Range (pullback.snd : pullback f g ⟶ _) = { y : Y | ∃ x : X, f x = g y } := by
  ext y
  constructor
  · rintro ⟨x, rfl⟩
    use (pullback.fst : pullback f g ⟶ _) x
    exact concrete_category.congr_hom pullback.condition x
    
  · rintro ⟨x, eq⟩
    use (Top.pullbackIsoProdSubtype f g).inv ⟨⟨x, y⟩, Eq⟩
    simp
    

/-- If there is a diagram where the morphisms `W ⟶ Y` and `X ⟶ Z` are embeddings,
then the induced morphism `W ×ₛ X ⟶ Y ×ₜ Z` is also an embedding.

  W  ⟶  Y
    ↘      ↘
      S  ⟶  T
    ↗      ↗
  X  ⟶  Z
-/
theorem pullback_map_embedding_of_embeddings {W X Y Z S T : Top} (f₁ : W ⟶ S) (f₂ : X ⟶ S) (g₁ : Y ⟶ T) (g₂ : Z ⟶ T)
    {i₁ : W ⟶ Y} {i₂ : X ⟶ Z} (H₁ : Embedding i₁) (H₂ : Embedding i₂) (i₃ : S ⟶ T) (eq₁ : f₁ ≫ i₃ = i₁ ≫ g₁)
    (eq₂ : f₂ ≫ i₃ = i₂ ≫ g₂) : Embedding (pullback.map f₁ f₂ g₁ g₂ i₁ i₂ i₃ eq₁ eq₂) := by
  refine'
    embedding_of_embedding_compose (ContinuousMap.continuous_to_fun _)
      (show Continuous (prod.lift pullback.fst pullback.snd : pullback g₁ g₂ ⟶ Y ⨯ Z) from
        ContinuousMap.continuous_to_fun _)
      _
  suffices Embedding (prod.lift pullback.fst pullback.snd ≫ limits.prod.map i₁ i₂ : pullback f₁ f₂ ⟶ _) by
    simpa [← coe_comp] using this
  rw [coe_comp]
  refine' Embedding.comp (embedding_prod_map H₁ H₂) (embedding_pullback_to_prod _ _)

/-- If there is a diagram where the morphisms `W ⟶ Y` and `X ⟶ Z` are open embeddings, and `S ⟶ T`
is mono, then the induced morphism `W ×ₛ X ⟶ Y ×ₜ Z` is also an open embedding.
  W  ⟶  Y
    ↘      ↘
      S  ⟶  T
    ↗       ↗
  X  ⟶  Z
-/
theorem pullback_map_open_embedding_of_open_embeddings {W X Y Z S T : Top} (f₁ : W ⟶ S) (f₂ : X ⟶ S) (g₁ : Y ⟶ T)
    (g₂ : Z ⟶ T) {i₁ : W ⟶ Y} {i₂ : X ⟶ Z} (H₁ : OpenEmbedding i₁) (H₂ : OpenEmbedding i₂) (i₃ : S ⟶ T) [H₃ : mono i₃]
    (eq₁ : f₁ ≫ i₃ = i₁ ≫ g₁) (eq₂ : f₂ ≫ i₃ = i₂ ≫ g₂) : OpenEmbedding (pullback.map f₁ f₂ g₁ g₂ i₁ i₂ i₃ eq₁ eq₂) :=
  by
  constructor
  · apply pullback_map_embedding_of_embeddings f₁ f₂ g₁ g₂ H₁.to_embedding H₂.to_embedding i₃ eq₁ eq₂
    
  · rw [range_pullback_map]
    apply IsOpen.inter <;> apply Continuous.is_open_preimage
    continuity
    exacts[H₁.open_range, H₂.open_range]
    

theorem snd_embedding_of_left_embedding {X Y S : Top} {f : X ⟶ S} (H : Embedding f) (g : Y ⟶ S) :
    Embedding (⇑(pullback.snd : pullback f g ⟶ Y)) := by
  convert
    (homeo_of_iso (as_iso (pullback.snd : pullback (𝟙 S) g ⟶ _))).Embedding.comp
      (pullback_map_embedding_of_embeddings f g (𝟙 _) g H (homeo_of_iso (iso.refl _)).Embedding (𝟙 _) rfl
        (by
          simp ))
  erw [← coe_comp]
  simp

theorem fst_embedding_of_right_embedding {X Y S : Top} (f : X ⟶ S) {g : Y ⟶ S} (H : Embedding g) :
    Embedding (⇑(pullback.fst : pullback f g ⟶ X)) := by
  convert
    (homeo_of_iso (as_iso (pullback.fst : pullback f (𝟙 S) ⟶ _))).Embedding.comp
      (pullback_map_embedding_of_embeddings f g f (𝟙 _) (homeo_of_iso (iso.refl _)).Embedding H (𝟙 _) rfl
        (by
          simp ))
  erw [← coe_comp]
  simp

theorem embedding_of_pullback_embeddings {X Y S : Top} {f : X ⟶ S} {g : Y ⟶ S} (H₁ : Embedding f) (H₂ : Embedding g) :
    Embedding (limit.π (cospan f g) walking_cospan.one) := by
  convert H₂.comp (snd_embedding_of_left_embedding H₁ g)
  erw [← coe_comp]
  congr
  exact (limit.w _ walking_cospan.hom.inr).symm

theorem snd_open_embedding_of_left_open_embedding {X Y S : Top} {f : X ⟶ S} (H : OpenEmbedding f) (g : Y ⟶ S) :
    OpenEmbedding (⇑(pullback.snd : pullback f g ⟶ Y)) := by
  convert
    (homeo_of_iso (as_iso (pullback.snd : pullback (𝟙 S) g ⟶ _))).OpenEmbedding.comp
      (pullback_map_open_embedding_of_open_embeddings f g (𝟙 _) g H (homeo_of_iso (iso.refl _)).OpenEmbedding (𝟙 _) rfl
        (by
          simp ))
  erw [← coe_comp]
  simp

theorem fst_open_embedding_of_right_open_embedding {X Y S : Top} (f : X ⟶ S) {g : Y ⟶ S} (H : OpenEmbedding g) :
    OpenEmbedding (⇑(pullback.fst : pullback f g ⟶ X)) := by
  convert
    (homeo_of_iso (as_iso (pullback.fst : pullback f (𝟙 S) ⟶ _))).OpenEmbedding.comp
      (pullback_map_open_embedding_of_open_embeddings f g f (𝟙 _) (homeo_of_iso (iso.refl _)).OpenEmbedding H (𝟙 _) rfl
        (by
          simp ))
  erw [← coe_comp]
  simp

/-- If `X ⟶ S`, `Y ⟶ S` are open embeddings, then so is `X ×ₛ Y ⟶ S`. -/
theorem open_embedding_of_pullback_open_embeddings {X Y S : Top} {f : X ⟶ S} {g : Y ⟶ S} (H₁ : OpenEmbedding f)
    (H₂ : OpenEmbedding g) : OpenEmbedding (limit.π (cospan f g) walking_cospan.one) := by
  convert H₂.comp (snd_open_embedding_of_left_open_embedding H₁ g)
  erw [← coe_comp]
  congr
  exact (limit.w _ walking_cospan.hom.inr).symm

theorem fst_iso_of_right_embedding_range_subset {X Y S : Top} (f : X ⟶ S) {g : Y ⟶ S} (hg : Embedding g)
    (H : Set.Range f ⊆ Set.Range g) : is_iso (pullback.fst : pullback f g ⟶ X) := by
  let this : (pullback f g : Top) ≃ₜ X :=
    (Homeomorph.ofEmbedding _ (fst_embedding_of_right_embedding f hg)).trans
      { toFun := coeₓ,
        invFun := fun x =>
          ⟨x, by
            rw [pullback_fst_range]
            exact ⟨_, (H (Set.mem_range_self x)).some_spec.symm⟩⟩,
        left_inv := fun ⟨_, _⟩ => rfl, right_inv := fun x => rfl }
  convert is_iso.of_iso (iso_of_homeo this)
  ext
  rfl

theorem snd_iso_of_left_embedding_range_subset {X Y S : Top} {f : X ⟶ S} (hf : Embedding f) (g : Y ⟶ S)
    (H : Set.Range g ⊆ Set.Range f) : is_iso (pullback.snd : pullback f g ⟶ Y) := by
  let this : (pullback f g : Top) ≃ₜ Y :=
    (Homeomorph.ofEmbedding _ (snd_embedding_of_left_embedding hf g)).trans
      { toFun := coeₓ,
        invFun := fun x =>
          ⟨x, by
            rw [pullback_snd_range]
            exact ⟨_, (H (Set.mem_range_self x)).some_spec⟩⟩,
        left_inv := fun ⟨_, _⟩ => rfl, right_inv := fun x => rfl }
  convert is_iso.of_iso (iso_of_homeo this)
  ext
  rfl

theorem pullback_snd_image_fst_preimage (f : X ⟶ Z) (g : Y ⟶ Z) (U : Set X) :
    (pullback.snd : pullback f g ⟶ _) '' ((pullback.fst : pullback f g ⟶ _) ⁻¹' U) = g ⁻¹' (f '' U) := by
  ext x
  constructor
  · rintro ⟨y, hy, rfl⟩
    exact ⟨(pullback.fst : pullback f g ⟶ _) y, hy, concrete_category.congr_hom pullback.condition y⟩
    
  · rintro ⟨y, hy, eq⟩
    exact
      ⟨(Top.pullbackIsoProdSubtype f g).inv ⟨⟨_, _⟩, Eq⟩, by
        simpa, by
        simp ⟩
    

theorem pullback_fst_image_snd_preimage (f : X ⟶ Z) (g : Y ⟶ Z) (U : Set Y) :
    (pullback.fst : pullback f g ⟶ _) '' ((pullback.snd : pullback f g ⟶ _) ⁻¹' U) = f ⁻¹' (g '' U) := by
  ext x
  constructor
  · rintro ⟨y, hy, rfl⟩
    exact ⟨(pullback.snd : pullback f g ⟶ _) y, hy, (concrete_category.congr_hom pullback.condition y).symm⟩
    
  · rintro ⟨y, hy, eq⟩
    exact
      ⟨(Top.pullbackIsoProdSubtype f g).inv ⟨⟨_, _⟩, Eq.symm⟩, by
        simpa, by
        simp ⟩
    

end Pullback

theorem coinduced_of_is_colimit {F : J ⥤ Top.{u}} (c : cocone F) (hc : is_colimit c) :
    c.X.topological_space = ⨆ j, (F.obj j).TopologicalSpace.coinduced (c.ι.app j) := by
  let homeo := homeo_of_iso (hc.cocone_point_unique_up_to_iso (colimit_cocone_is_colimit F))
  ext
  refine' homeo.symm.is_open_preimage.symm.trans (Iff.trans _ is_open_supr_iff.symm)
  exact is_open_supr_iff

theorem colimit_topology (F : J ⥤ Top.{u}) :
    (colimit F).TopologicalSpace = ⨆ j, (F.obj j).TopologicalSpace.coinduced (colimit.ι F j) :=
  coinduced_of_is_colimit _ (colimit.is_colimit F)

theorem colimit_is_open_iff (F : J ⥤ Top.{u}) (U : Set ((colimit F : _) : Type u)) :
    IsOpen U ↔ ∀ j, IsOpen (colimit.ι F j ⁻¹' U) := by
  conv_lhs => rw [colimit_topology F]
  exact is_open_supr_iff

theorem coequalizer_is_open_iff (F : walking_parallel_pair.{u} ⥤ Top.{u}) (U : Set ((colimit F : _) : Type u)) :
    IsOpen U ↔ IsOpen (colimit.ι F walking_parallel_pair.one ⁻¹' U) := by
  rw [colimit_is_open_iff]
  constructor
  · intro H
    exact H _
    
  · intro H j
    cases j
    · rw [← colimit.w F walking_parallel_pair_hom.left]
      exact (F.map walking_parallel_pair_hom.left).continuous_to_fun.is_open_preimage _ H
      
    · exact H
      
    

end Top

namespace Top

section CofilteredLimit

variable {J : Type u} [small_category J] [is_cofiltered J] (F : J ⥤ Top.{u}) (C : cone F) (hC : is_limit C)

include hC

/-- Given a *compatible* collection of topological bases for the factors in a cofiltered limit
which contain `set.univ` and are closed under intersections, the induced *naive* collection
of sets in the limit is, in fact, a topological basis.
-/
theorem is_topological_basis_cofiltered_limit (T : ∀ j, Set (Set (F.obj j))) (hT : ∀ j, is_topological_basis (T j))
    (univ : ∀ i : J, Set.Univ ∈ T i) (inter : ∀ i U1 U2 : Set (F.obj i), U1 ∈ T i → U2 ∈ T i → U1 ∩ U2 ∈ T i)
    (compat : ∀ i j : J f : i ⟶ j V : Set (F.obj j) hV : V ∈ T j, F.map f ⁻¹' V ∈ T i) :
    is_topological_basis { U : Set C.X | ∃ (j : _)(V : Set (F.obj j)), V ∈ T j ∧ U = C.π.app j ⁻¹' V } := by
  classical
  let D := limit_cone_infi F
  let E : C.X ≅ D.X := hC.cone_point_unique_up_to_iso (limit_cone_infi_is_limit _)
  have hE : Inducing E.hom := (Top.homeoOfIso E).Inducing
  suffices is_topological_basis { U : Set D.X | ∃ (j : _)(V : Set (F.obj j)), V ∈ T j ∧ U = D.π.app j ⁻¹' V } by
    convert this.inducing hE
    ext U0
    constructor
    · rintro ⟨j, V, hV, rfl⟩
      refine' ⟨D.π.app j ⁻¹' V, ⟨j, V, hV, rfl⟩, rfl⟩
      
    · rintro ⟨W, ⟨j, V, hV, rfl⟩, rfl⟩
      refine' ⟨j, V, hV, rfl⟩
      
  convert is_topological_basis_infi hT fun j x : D.X => D.π.app j x
  ext U0
  constructor
  · rintro ⟨j, V, hV, rfl⟩
    let U : ∀ i, Set (F.obj i) := fun i =>
      if h : i = j then by
        rw [h]
        exact V
      else Set.Univ
    refine' ⟨U, {j}, _, _⟩
    · rintro i h
      rw [Finset.mem_singleton] at h
      dsimp [U]
      rw [dif_pos h]
      subst h
      exact hV
      
    · dsimp [U]
      simp
      
    
  · rintro ⟨U, G, h1, h2⟩
    obtain ⟨j, hj⟩ := is_cofiltered.inf_objs_exists G
    let g : ∀ e he : e ∈ G, j ⟶ e := fun _ he => (hj he).some
    let Vs : J → Set (F.obj j) := fun e => if h : e ∈ G then F.map (g e h) ⁻¹' U e else Set.Univ
    let V : Set (F.obj j) := ⋂ (e : J) (he : e ∈ G), Vs e
    refine' ⟨j, V, _, _⟩
    · have :
        ∀ S : Set (Set (F.obj j)) E : Finset J P : J → Set (F.obj j) univ : Set.Univ ∈ S inter :
          ∀ A B : Set (F.obj j), A ∈ S → B ∈ S → A ∩ B ∈ S cond : ∀ e : J he : e ∈ E, P e ∈ S,
          (⋂ (e) (he : e ∈ E), P e) ∈ S :=
        by
        intro S E
        apply E.induction_on
        · intro P he hh
          simpa
          
        · intro a E ha hh1 hh2 hh3 hh4 hh5
          rw [Finset.set_bInter_insert]
          refine' hh4 _ _ (hh5 _ (Finset.mem_insert_self _ _)) (hh1 _ hh3 hh4 _)
          intro e he
          exact hh5 e (Finset.mem_insert_of_mem he)
          
      refine' this _ _ _ (univ _) (inter _) _
      intro e he
      dsimp [Vs]
      rw [dif_pos he]
      exact compat j e (g e he) (U e) (h1 e he)
      
    · rw [h2]
      dsimp [V]
      rw [Set.preimage_Inter]
      congr 1
      ext1 e
      rw [Set.preimage_Inter]
      congr 1
      ext1 he
      dsimp [Vs]
      rw [dif_pos he, ← Set.preimage_comp]
      congr 1
      change _ = ⇑(D.π.app j ≫ F.map (g e he))
      rw [D.w]
      
    

end CofilteredLimit

section TopologicalKonig

/-!
## Topological Kőnig's lemma

A topological version of Kőnig's lemma is that the inverse limit of nonempty compact Hausdorff
spaces is nonempty.  (Note: this can be generalized further to inverse limits of nonempty compact
T0 spaces, where all the maps are closed maps; see [Stone1979] --- however there is an erratum
for Theorem 4 that the element in the inverse limit can have cofinally many components that are
not closed points.)

We give this in a more general form, which is that cofiltered limits
of nonempty compact Hausdorff spaces are nonempty
(`nonempty_limit_cone_of_compact_t2_cofiltered_system`).

This also applies to inverse limits, where `{J : Type u} [preorder J] [is_directed J (≤)]` and
`F : Jᵒᵖ ⥤ Top`.

The theorem is specialized to nonempty finite types (which are compact Hausdorff with the
discrete topology) in `nonempty_sections_of_fintype_cofiltered_system` and
`nonempty_sections_of_fintype_inverse_system`.

(See https://stacks.math.columbia.edu/tag/086J for the Set version.)
-/


variable {J : Type u} [small_category J]

variable (F : J ⥤ Top.{u})

-- ././Mathport/Syntax/Translate/Basic.lean:626:6: warning: expanding binder group (X Y)
private abbrev finite_diagram_arrow {J : Type u} [small_category J] (G : Finset J) :=
  Σ' (X : J) (Y : J) (mX : X ∈ G) (mY : Y ∈ G), X ⟶ Y

private abbrev finite_diagram (J : Type u) [small_category J] :=
  Σ G : Finset J, Finset (finite_diagram_arrow G)

/-- Partial sections of a cofiltered limit are sections when restricted to
a finite subset of objects and morphisms of `J`.
-/
def partial_sections {J : Type u} [small_category J] (F : J ⥤ Top.{u}) {G : Finset J}
    (H : Finset (finite_diagram_arrow G)) : Set (∀ j, F.obj j) :=
  { u | ∀ {f : finite_diagram_arrow G} hf : f ∈ H, F.map f.2.2.2.2 (u f.1) = u f.2.1 }

theorem partial_sections.nonempty [is_cofiltered J] [h : ∀ j : J, Nonempty (F.obj j)] {G : Finset J}
    (H : Finset (finite_diagram_arrow G)) : (partial_sections F H).Nonempty := by
  classical
  use fun j : J =>
    if hj : j ∈ G then F.map (is_cofiltered.inf_to G H hj) (h (is_cofiltered.inf G H)).some else (h _).some
  rintro ⟨X, Y, hX, hY, f⟩ hf
  dsimp only
  rwa [dif_pos hX, dif_pos hY, ← comp_app, ← F.map_comp, @is_cofiltered.inf_to_commutes _ _ _ G H]

theorem partial_sections.directed : Directed Superset fun G : finite_diagram J => partial_sections F G.2 := by
  classical
  intro A B
  let ιA : finite_diagram_arrow A.1 → finite_diagram_arrow (A.1⊔B.1) := fun f =>
    ⟨f.1, f.2.1, Finset.mem_union_left _ f.2.2.1, Finset.mem_union_left _ f.2.2.2.1, f.2.2.2.2⟩
  let ιB : finite_diagram_arrow B.1 → finite_diagram_arrow (A.1⊔B.1) := fun f =>
    ⟨f.1, f.2.1, Finset.mem_union_right _ f.2.2.1, Finset.mem_union_right _ f.2.2.2.1, f.2.2.2.2⟩
  refine' ⟨⟨A.1⊔B.1, A.2.Image ιA⊔B.2.Image ιB⟩, _, _⟩
  · rintro u hu f hf
    have : ιA f ∈ A.2.Image ιA⊔B.2.Image ιB := by
      apply Finset.mem_union_left
      rw [Finset.mem_image]
      refine' ⟨f, hf, rfl⟩
    exact hu this
    
  · rintro u hu f hf
    have : ιB f ∈ A.2.Image ιA⊔B.2.Image ιB := by
      apply Finset.mem_union_right
      rw [Finset.mem_image]
      refine' ⟨f, hf, rfl⟩
    exact hu this
    

theorem partial_sections.closed [∀ j : J, T2Space (F.obj j)] {G : Finset J} (H : Finset (finite_diagram_arrow G)) :
    IsClosed (partial_sections F H) := by
  have :
    partial_sections F H = ⋂ (f : finite_diagram_arrow G) (hf : f ∈ H), { u | F.map f.2.2.2.2 (u f.1) = u f.2.1 } := by
    ext1
    simp only [Set.mem_Inter, Set.mem_set_of_eq]
    rfl
  rw [this]
  apply is_closed_bInter
  intro f hf
  apply is_closed_eq
  continuity

/-- Cofiltered limits of nonempty compact Hausdorff spaces are nonempty topological spaces.
--/
theorem nonempty_limit_cone_of_compact_t2_cofiltered_system [is_cofiltered J] [∀ j : J, Nonempty (F.obj j)]
    [∀ j : J, CompactSpace (F.obj j)] [∀ j : J, T2Space (F.obj j)] : Nonempty (Top.limitCone F).x := by
  classical
  obtain ⟨u, hu⟩ :=
    IsCompact.nonempty_Inter_of_directed_nonempty_compact_closed (fun G => partial_sections F _)
      (partial_sections.directed F) (fun G => partial_sections.nonempty F _)
      (fun G => IsClosed.is_compact (partial_sections.closed F _)) fun G => partial_sections.closed F _
  use u
  intro X Y f
  let G : finite_diagram J :=
    ⟨{X, Y},
      {⟨X, Y, by
          simp only [true_orₓ, eq_self_iff_true, Finset.mem_insert], by
          simp only [eq_self_iff_true, or_trueₓ, Finset.mem_insert, Finset.mem_singleton], f⟩}⟩
  exact hu _ ⟨G, rfl⟩ (Finset.mem_singleton_self _)

end TopologicalKonig

end Top

section FintypeKonig

/-- This bootstraps `nonempty_sections_of_fintype_inverse_system`. In this version,
the `F` functor is between categories of the same universe, and it is an easy
corollary to `Top.nonempty_limit_cone_of_compact_t2_inverse_system`. -/
theorem NonemptySectionsOfFintypeCofilteredSystem.init {J : Type u} [small_category J] [is_cofiltered J]
    (F : J ⥤ Type u) [hf : ∀ j : J, Fintype (F.obj j)] [hne : ∀ j : J, Nonempty (F.obj j)] : F.sections.nonempty := by
  let F' : J ⥤ Top := F ⋙ Top.discrete
  have : ∀ j : J, Fintype (F'.obj j) := hf
  have : ∀ j : J, Nonempty (F'.obj j) := hne
  obtain ⟨⟨u, hu⟩⟩ := Top.nonempty_limit_cone_of_compact_t2_cofiltered_system F'
  exact ⟨u, fun _ _ f => hu f⟩

/-- The cofiltered limit of nonempty finite types is nonempty.

See `nonempty_sections_of_fintype_inverse_system` for a specialization to inverse limits. -/
theorem nonempty_sections_of_fintype_cofiltered_system {J : Type u} [category.{w} J] [is_cofiltered J] (F : J ⥤ Type v)
    [∀ j : J, Fintype (F.obj j)] [∀ j : J, Nonempty (F.obj j)] : F.sections.nonempty := by
  let J' : Type max w v u := as_small.{max w v} J
  let down : J' ⥤ J := as_small.down
  let F' : J' ⥤ Type max u v w := down ⋙ F ⋙ ulift_functor.{max u w, v}
  have : ∀ i, Nonempty (F'.obj i) := fun i => ⟨⟨Classical.arbitrary (F.obj (down.obj i))⟩⟩
  have : ∀ i, Fintype (F'.obj i) := fun i => Fintype.ofEquiv (F.obj (down.obj i)) equiv.ulift.symm
  obtain ⟨u, hu⟩ := NonemptySectionsOfFintypeCofilteredSystem.init F'
  use fun j => (u ⟨j⟩).down
  intro j j' f
  have h := @hu (⟨j⟩ : J') (⟨j'⟩ : J') (Ulift.up f)
  simp only [as_small.down, functor.comp_map, ulift_functor_map, functor.op_map] at h
  simp_rw [← h]
  rfl

/-- The inverse limit of nonempty finite types is nonempty.

See `nonempty_sections_of_fintype_cofiltered_system` for a generalization to cofiltered limits.
That version applies in almost all cases, and the only difference is that this version
allows `J` to be empty.

This may be regarded as a generalization of Kőnig's lemma.
To specialize: given a locally finite connected graph, take `Jᵒᵖ` to be `ℕ` and
`F j` to be length-`j` paths that start from an arbitrary fixed vertex.
Elements of `F.sections` can be read off as infinite rays in the graph. -/
theorem nonempty_sections_of_fintype_inverse_system {J : Type u} [Preorderₓ J] [IsDirected J (· ≤ ·)] (F : Jᵒᵖ ⥤ Type v)
    [∀ j : Jᵒᵖ, Fintype (F.obj j)] [∀ j : Jᵒᵖ, Nonempty (F.obj j)] : F.sections.nonempty := by
  run_tac
    tactic.unfreeze_local_instances
  by_cases' h : Nonempty J
  · apply nonempty_sections_of_fintype_cofiltered_system
    
  · rw [not_nonempty_iff_imp_false] at h
    exact ⟨fun j => False.elim (h j.unop), fun j => False.elim (h j.unop)⟩
    

end FintypeKonig

