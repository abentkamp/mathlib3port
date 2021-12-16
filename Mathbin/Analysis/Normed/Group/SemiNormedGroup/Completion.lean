import Mathbin.Analysis.Normed.Group.SemiNormedGroup 
import Mathbin.CategoryTheory.Preadditive.AdditiveFunctor 
import Mathbin.Analysis.Normed.Group.HomCompletion

/-!
# Completions of normed groups

This file contains an API for completions of seminormed groups (basic facts about
objects and morphisms).

## Main definitions

- `SemiNormedGroup.Completion : SemiNormedGroup ⥤ SemiNormedGroup` : the completion of a
  seminormed group (defined as a functor on `SemiNormedGroup` to itself).
- `SemiNormedGroup.Completion.lift (f : V ⟶ W) : (Completion.obj V ⟶ W)` : a normed group hom
  from `V` to complete `W` extends ("lifts") to a seminormed group hom from the completion of
  `V` to `W`.

## Projects

1. Construct the category of complete seminormed groups, say `CompleteSemiNormedGroup`
  and promote the `Completion` functor below to a functor landing in this category.
2. Prove that the functor `Completion : SemiNormedGroup ⥤ CompleteSemiNormedGroup`
  is left adjoint to the forgetful functor.

-/


noncomputable section 

universe u

open UniformSpace MulOpposite CategoryTheory NormedGroupHom

namespace SemiNormedGroupₓ

/-- The completion of a seminormed group, as an endofunctor on `SemiNormedGroup`. -/
@[simps]
def Completion : SemiNormedGroupₓ.{u} ⥤ SemiNormedGroupₓ.{u} :=
  { obj := fun V => SemiNormedGroupₓ.of (completion V), map := fun V W f => f.completion,
    map_id' := fun V => completion_id, map_comp' := fun U V W f g => (completion_comp f g).symm }

instance Completion_complete_space {V : SemiNormedGroupₓ} : CompleteSpace (Completion.obj V) :=
  completion.complete_space _

/-- The canonical morphism from a seminormed group `V` to its completion. -/
@[simps]
def Completion.incl {V : SemiNormedGroupₓ} : V ⟶ Completion.obj V :=
  { toFun := fun v => (v : completion V), map_add' := completion.coe_add,
    bound' :=
      ⟨1,
        fun v =>
          by 
            simp ⟩ }

theorem Completion.norm_incl_eq {V : SemiNormedGroupₓ} {v : V} : ∥Completion.incl v∥ = ∥v∥ :=
  by 
    simp 

theorem Completion.map_norm_noninc {V W : SemiNormedGroupₓ} {f : V ⟶ W} (hf : f.norm_noninc) :
  (Completion.map f).NormNoninc :=
  NormedGroupHom.NormNoninc.norm_noninc_iff_norm_le_one.2$
    (NormedGroupHom.norm_completion f).le.trans$ NormedGroupHom.NormNoninc.norm_noninc_iff_norm_le_one.1 hf

/-- Given a normed group hom `V ⟶ W`, this defines the associated morphism
from the completion of `V` to the completion of `W`.
The difference from the definition obtained from the functoriality of completion is in that the
map sending a morphism `f` to the associated morphism of completions is itself additive. -/
def Completion.map_hom (V W : SemiNormedGroupₓ.{u}) : (V ⟶ W) →+ Completion.obj V ⟶ Completion.obj W :=
  AddMonoidHom.mk' (CategoryTheory.Functor.map Completion)$ fun f g => f.completion_add g

@[simp]
theorem Completion.map_zero (V W : SemiNormedGroupₓ) : Completion.map (0 : V ⟶ W) = 0 :=
  (Completion.map_hom V W).map_zero

instance : preadditive SemiNormedGroupₓ.{u} :=
  { homGroup := fun P Q => inferInstance,
    add_comp' :=
      by 
        intros 
        ext 
        simp only [NormedGroupHom.add_apply, CategoryTheory.comp_apply, NormedGroupHom.map_add],
    comp_add' :=
      by 
        intros 
        ext 
        simp only [NormedGroupHom.add_apply, CategoryTheory.comp_apply, NormedGroupHom.map_add] }

instance : functor.additive Completion :=
  { map_add' := fun X Y => (Completion.map_hom _ _).map_add }

/-- Given a normed group hom `f : V → W` with `W` complete, this provides a lift of `f` to
the completion of `V`. The lemmas `lift_unique` and `lift_comp_incl` provide the api for the
universal property of the completion. -/
def Completion.lift {V W : SemiNormedGroupₓ} [CompleteSpace W] [SeparatedSpace W] (f : V ⟶ W) : Completion.obj V ⟶ W :=
  { toFun := f.extension, map_add' := f.extension.to_add_monoid_hom.map_add', bound' := f.extension.bound' }

theorem Completion.lift_comp_incl {V W : SemiNormedGroupₓ} [CompleteSpace W] [SeparatedSpace W] (f : V ⟶ W) :
  Completion.incl ≫ Completion.lift f = f :=
  by 
    ext 
    apply NormedGroupHom.extension_coe

theorem Completion.lift_unique {V W : SemiNormedGroupₓ} [CompleteSpace W] [SeparatedSpace W] (f : V ⟶ W)
  (g : Completion.obj V ⟶ W) : Completion.incl ≫ g = f → g = Completion.lift f :=
  fun h => (NormedGroupHom.extension_unique _ fun v => ((ext_iff.1 h) v).symm).symm

end SemiNormedGroupₓ

