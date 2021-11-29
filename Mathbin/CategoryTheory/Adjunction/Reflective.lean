import Mathbin.CategoryTheory.Adjunction.FullyFaithful 
import Mathbin.CategoryTheory.EpiMono

/-!
# Reflective functors

Basic properties of reflective functors, especially those relating to their essential image.

Note properties of reflective functors relating to limits and colimits are included in
`category_theory.monad.limits`.
-/


universe v₁ v₂ v₃ u₁ u₂ u₃

noncomputable theory

namespace CategoryTheory

open Category Adjunction

variable {C : Type u₁} {D : Type u₂} {E : Type u₃}

variable [category.{v₁} C] [category.{v₂} D] [category.{v₃} E]

/--
A functor is *reflective*, or *a reflective inclusion*, if it is fully faithful and right adjoint.
-/
class reflective (R : D ⥤ C) extends is_right_adjoint R, full R, faithful R

variable {i : D ⥤ C}

/--
For a reflective functor `i` (with left adjoint `L`), with unit `η`, we have `η_iL = iL η`.
-/
theorem unit_obj_eq_map_unit [reflective i] (X : C) :
  (of_right_adjoint i).Unit.app (i.obj ((left_adjoint i).obj X)) =
    i.map ((left_adjoint i).map ((of_right_adjoint i).Unit.app X)) :=
  by 
    rw [←cancel_mono (i.map ((of_right_adjoint i).counit.app ((left_adjoint i).obj X))), ←i.map_comp]
    simp 

-- error in CategoryTheory.Adjunction.Reflective: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/--
When restricted to objects in `D` given by `i : D ⥤ C`, the unit is an isomorphism. In other words,
`η_iX` is an isomorphism for any `X` in `D`.
More generally this applies to objects essentially in the reflective subcategory, see
`functor.ess_image.unit_iso`.
-/ instance is_iso_unit_obj [reflective i] {B : D} : is_iso ((of_right_adjoint i).unit.app (i.obj B)) :=
begin
  have [] [":", expr «expr = »((of_right_adjoint i).unit.app (i.obj B), inv (i.map ((of_right_adjoint i).counit.app B)))] [],
  { rw ["<-", expr comp_hom_eq_id] [],
    apply [expr (of_right_adjoint i).right_triangle_components] },
  rw [expr this] [],
  exact [expr is_iso.inv_is_iso]
end

/--
If `A` is essentially in the image of a reflective functor `i`, then `η_A` is an isomorphism.
This gives that the "witness" for `A` being in the essential image can instead be given as the
reflection of `A`, with the isomorphism as `η_A`.

(For any `B` in the reflective subcategory, we automatically have that `ε_B` is an iso.)
-/
theorem functor.ess_image.unit_is_iso [reflective i] {A : C} (h : A ∈ i.ess_image) :
  is_iso ((of_right_adjoint i).Unit.app A) :=
  by 
    suffices  :
      (of_right_adjoint i).Unit.app A =
        h.get_iso.inv ≫ (of_right_adjoint i).Unit.app (i.obj h.witness) ≫ (left_adjoint i ⋙ i).map h.get_iso.hom
    ·
      rw [this]
      infer_instance 
    rw [←nat_trans.naturality]
    simp 

/-- If `η_A` is an isomorphism, then `A` is in the essential image of `i`. -/
theorem mem_ess_image_of_unit_is_iso [is_right_adjoint i] (A : C) [is_iso ((of_right_adjoint i).Unit.app A)] :
  A ∈ i.ess_image :=
  ⟨(left_adjoint i).obj A, ⟨(as_iso ((of_right_adjoint i).Unit.app A)).symm⟩⟩

-- error in CategoryTheory.Adjunction.Reflective: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- If `η_A` is a split monomorphism, then `A` is in the reflective subcategory. -/
theorem mem_ess_image_of_unit_split_mono
[reflective i]
{A : C}
[split_mono ((of_right_adjoint i).unit.app A)] : «expr ∈ »(A, i.ess_image) :=
begin
  let [ident η] [":", expr «expr ⟶ »(«expr𝟭»() C, «expr ⋙ »(left_adjoint i, i))] [":=", expr (of_right_adjoint i).unit],
  haveI [] [":", expr is_iso (η.app (i.obj ((left_adjoint i).obj A)))] [":=", expr (i.obj_mem_ess_image _).unit_is_iso],
  have [] [":", expr epi (η.app A)] [],
  { apply [expr epi_of_epi (retraction (η.app A)) _],
    rw [expr show «expr = »(«expr ≫ »(retraction _, η.app A), _), from η.naturality (retraction (η.app A))] [],
    apply [expr epi_comp (η.app (i.obj ((left_adjoint i).obj A)))] },
  resetI,
  haveI [] [] [":=", expr is_iso_of_epi_of_split_mono (η.app A)],
  exact [expr mem_ess_image_of_unit_is_iso A]
end

/-- Composition of reflective functors. -/
instance reflective.comp (F : C ⥤ D) (G : D ⥤ E) [Fr : reflective F] [Gr : reflective G] : reflective (F ⋙ G) :=
  { to_faithful := faithful.comp F G }

/-- (Implementation) Auxiliary definition for `unit_comp_partial_bijective`. -/
def unit_comp_partial_bijective_aux [reflective i] (A : C) (B : D) :
  (A ⟶ i.obj B) ≃ (i.obj ((left_adjoint i).obj A) ⟶ i.obj B) :=
  ((adjunction.of_right_adjoint i).homEquiv _ _).symm.trans (equiv_of_fully_faithful i)

/-- The description of the inverse of the bijection `unit_comp_partial_bijective_aux`. -/
theorem unit_comp_partial_bijective_aux_symm_apply [reflective i] {A : C} {B : D}
  (f : i.obj ((left_adjoint i).obj A) ⟶ i.obj B) :
  (unit_comp_partial_bijective_aux _ _).symm f = (of_right_adjoint i).Unit.app A ≫ f :=
  by 
    simp [unit_comp_partial_bijective_aux]

/--
If `i` has a reflector `L`, then the function `(i.obj (L.obj A) ⟶ B) → (A ⟶ B)` given by
precomposing with `η.app A` is a bijection provided `B` is in the essential image of `i`.
That is, the function `λ (f : i.obj (L.obj A) ⟶ B), η.app A ≫ f` is bijective, as long as `B` is in
the essential image of `i`.
This definition gives an equivalence: the key property that the inverse can be described
nicely is shown in `unit_comp_partial_bijective_symm_apply`.

This establishes there is a natural bijection `(A ⟶ B) ≃ (i.obj (L.obj A) ⟶ B)`. In other words,
from the point of view of objects in `D`, `A` and `i.obj (L.obj A)` look the same: specifically
that `η.app A` is an isomorphism.
-/
def unit_comp_partial_bijective [reflective i] (A : C) {B : C} (hB : B ∈ i.ess_image) :
  (A ⟶ B) ≃ (i.obj ((left_adjoint i).obj A) ⟶ B) :=
  calc (A ⟶ B) ≃ (A ⟶ i.obj hB.witness) := iso.hom_congr (iso.refl _) hB.get_iso.symm 
    _ ≃ (i.obj _ ⟶ i.obj hB.witness) := unit_comp_partial_bijective_aux _ _ 
    _ ≃ (i.obj ((left_adjoint i).obj A) ⟶ B) := iso.hom_congr (iso.refl _) hB.get_iso
    

@[simp]
theorem unit_comp_partial_bijective_symm_apply [reflective i] (A : C) {B : C} (hB : B ∈ i.ess_image) f :
  (unit_comp_partial_bijective A hB).symm f = (of_right_adjoint i).Unit.app A ≫ f :=
  by 
    simp [unit_comp_partial_bijective, unit_comp_partial_bijective_aux_symm_apply]

theorem unit_comp_partial_bijective_symm_natural [reflective i] (A : C) {B B' : C} (h : B ⟶ B') (hB : B ∈ i.ess_image)
  (hB' : B' ∈ i.ess_image) (f : i.obj ((left_adjoint i).obj A) ⟶ B) :
  (unit_comp_partial_bijective A hB').symm (f ≫ h) = (unit_comp_partial_bijective A hB).symm f ≫ h :=
  by 
    simp 

theorem unit_comp_partial_bijective_natural [reflective i] (A : C) {B B' : C} (h : B ⟶ B') (hB : B ∈ i.ess_image)
  (hB' : B' ∈ i.ess_image) (f : A ⟶ B) :
  (unit_comp_partial_bijective A hB') (f ≫ h) = unit_comp_partial_bijective A hB f ≫ h :=
  by 
    rw [←Equiv.eq_symm_apply, unit_comp_partial_bijective_symm_natural A h, Equiv.symm_apply_apply]

end CategoryTheory

