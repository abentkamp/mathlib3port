import Mathbin.Topology.Category.CompHaus.Default
import Mathbin.Topology.StoneCech
import Mathbin.CategoryTheory.Preadditive.Projective

/-!
# CompHaus has enough projectives

In this file we show that `CompHaus` has enough projectives.

## Main results

Let `X` be a compact Hausdorff space.

* `CompHaus.projective_ultrafilter`: the space `ultrafilter X` is a projective object
* `CompHaus.projective_presentation`: the natural map `ultrafilter X → X`
  is a projective presentation

## Reference

See [miraglia2006introduction] Chapter 21 for a proof that `CompHaus` has enough projectives.

-/


noncomputable section

open CategoryTheory Function

namespace CompHaus

instance projective_ultrafilter (X : Type _) : projective (of $ Ultrafilter X) where
  factors := fun Y Z f g hg => by
    rw [epi_iff_surjective] at hg
    obtain ⟨g', hg'⟩ := hg.has_right_inverse
    let t : X → Y := g' ∘ f ∘ (pure : X → Ultrafilter X)
    let h : Ultrafilter X → Y := Ultrafilter.extend t
    have hh : Continuous h := continuous_ultrafilter_extend _
    use ⟨h, hh⟩
    apply faithful.map_injective (forget CompHaus)
    simp only [forget_map_eq_coe, ContinuousMap.coe_mk, coe_comp]
    convert dense_range_pure.equalizer (g.continuous.comp hh) f.continuous _
    rw [comp.assoc, ultrafilter_extend_extends, ← comp.assoc, hg'.comp_eq_id, comp.left_id]

/-- For any compact Hausdorff space `X`,
  the natural map `ultrafilter X → X` is a projective presentation. -/
def projective_presentation (X : CompHaus) : projective_presentation X where
  P := of $ Ultrafilter X
  f := ⟨_, continuous_ultrafilter_extend id⟩
  Projective := CompHaus.projective_ultrafilter X
  Epi :=
    concrete_category.epi_of_surjective _ $ fun x =>
      ⟨(pure x : Ultrafilter X), congr_funₓ (ultrafilter_extend_extends (𝟙 X)) x⟩

instance : enough_projectives CompHaus where
  presentation := fun X => ⟨projective_presentation X⟩

end CompHaus

