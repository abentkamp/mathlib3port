import Mathbin.Topology.Category.Profinite.Default 
import Mathbin.Topology.StoneCech 
import Mathbin.CategoryTheory.Preadditive.Projective

/-!
# Profinite sets have enough projectives

In this file we show that `Profinite` has enough projectives.

## Main results

Let `X` be a profinite set.

* `Profinite.projective_ultrafilter`: the space `ultrafilter X` is a projective object
* `Profinite.projective_presentation`: the natural map `ultrafilter X → X`
  is a projective presentation

-/


noncomputable section 

universe u v w

open CategoryTheory Function

namespace Profinite

instance projective_ultrafilter (X : Type u) : projective (of$ Ultrafilter X) :=
  { factors :=
      fun Y Z f g hg =>
        by 
          rw [epi_iff_surjective] at hg 
          obtain ⟨g', hg'⟩ := hg.has_right_inverse 
          let t : X → Y := g' ∘ f ∘ (pure : X → Ultrafilter X)
          let h : Ultrafilter X → Y := Ultrafilter.extend t 
          have hh : Continuous h := continuous_ultrafilter_extend _ 
          use ⟨h, hh⟩
          apply faithful.map_injective (forget Profinite)
          simp only [forget_map_eq_coe, ContinuousMap.coe_mk, coe_comp]
          refine' dense_range_pure.equalizer (g.continuous.comp hh) f.continuous _ 
          rw [comp.assoc, ultrafilter_extend_extends, ←comp.assoc, hg'.comp_eq_id, comp.left_id] }

/-- For any profinite `X`, the natural map `ultrafilter X → X` is a projective presentation. -/
def projective_presentation (X : Profinite.{u}) : projective_presentation X :=
  { P := of$ Ultrafilter X, f := ⟨_, continuous_ultrafilter_extend id⟩,
    Projective := Profinite.projective_ultrafilter X,
    Epi :=
      concrete_category.epi_of_surjective _$
        fun x => ⟨(pure x : Ultrafilter X), congr_funₓ (ultrafilter_extend_extends (𝟙 X)) x⟩ }

instance : enough_projectives Profinite.{u} :=
  { presentation := fun X => ⟨projective_presentation X⟩ }

end Profinite

