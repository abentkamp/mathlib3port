import Mathbin.Algebra.Category.Group.FilteredColimits 
import Mathbin.Algebra.Category.Module.Basic

/-!
# The forgetful functor from `R`-modules preserves filtered colimits.

Forgetful functors from algebraic categories usually don't preserve colimits. However, they tend
to preserve _filtered_ colimits.

In this file, we start with a ring `R`, a small filtered category `J` and a functor
`F : J ⥤ Module R`. We show that the colimit of `F ⋙ forget₂ (Module R) AddCommGroup`
(in `AddCommGroup`) carries the structure of an `R`-module, thereby showing that the forgetful
functor `forget₂ (Module R) AddCommGroup` preserves filtered colimits. In particular, this implies
that `forget (Module R)` preserves filtered colimits.

-/


universe u v

noncomputable section 

open_locale Classical

open CategoryTheory

open CategoryTheory.Limits

open CategoryTheory.IsFiltered renaming max→max'

open AddMon.filtered_colimits(colimit_zero_eq colimit_add_mk_eq)

namespace ModuleCat.FilteredColimits

section 

parameter {R : Type u}[Ringₓ R]{J : Type v}[small_category J][is_filtered J]

parameter (F : J ⥤ ModuleCat.{v} R)

/--
The colimit of `F ⋙ forget₂ (Module R) AddCommGroup` in the category `AddCommGroup`.
In the following, we will show that this has the structure of an `R`-module.
-/
abbrev M : AddCommGroupₓₓ :=
  AddCommGroupₓₓ.FilteredColimits.colimit (F ⋙ forget₂ (ModuleCat R) AddCommGroupₓₓ)

/-- The canonical projection into the colimit, as a quotient type. -/
abbrev M.mk : (Σ j, F.obj j) → M :=
  Quot.mk (types.quot.rel (F ⋙ forget (ModuleCat R)))

theorem M.mk_eq (x y : Σ j, F.obj j) (h : ∃ (k : J)(f : x.1 ⟶ k)(g : y.1 ⟶ k), F.map f x.2 = F.map g y.2) :
  M.mk x = M.mk y :=
  Quot.eqv_gen_sound (types.filtered_colimit.eqv_gen_quot_rel_of_rel (F ⋙ forget (ModuleCat R)) x y h)

/-- The "unlifted" version of scalar multiplication in the colimit. -/
def colimit_smul_aux (r : R) (x : Σ j, F.obj j) : M :=
  M.mk ⟨x.1, r • x.2⟩

theorem colimit_smul_aux_eq_of_rel (r : R) (x y : Σ j, F.obj j)
  (h : types.filtered_colimit.rel (F ⋙ forget (ModuleCat R)) x y) : colimit_smul_aux r x = colimit_smul_aux r y :=
  by 
    apply M.mk_eq 
    obtain ⟨k, f, g, hfg⟩ := h 
    use k, f, g 
    simp only [CategoryTheory.Functor.comp_map, forget_map_eq_coe] at hfg 
    rw [LinearMap.map_smul, LinearMap.map_smul, hfg]

/-- Scalar multiplication in the colimit. See also `colimit_smul_aux`. -/
instance colimit_has_scalar : HasScalar R M :=
  { smul :=
      fun r x =>
        by 
          refine' Quot.lift (colimit_smul_aux F r) _ x 
          intro x y h 
          apply colimit_smul_aux_eq_of_rel 
          apply types.filtered_colimit.rel_of_quot_rel 
          exact h }

@[simp]
theorem colimit_smul_mk_eq (r : R) (x : Σ j, F.obj j) : r • M.mk x = M.mk ⟨x.1, r • x.2⟩ :=
  rfl

instance colimit_module : Module R M :=
  { one_smul :=
      fun x =>
        by 
          apply Quot.induction_on x 
          clear x 
          intro x 
          cases' x with j x 
          erw [colimit_smul_mk_eq F 1 ⟨j, x⟩, one_smul]
          rfl,
    mul_smul :=
      fun r s x =>
        by 
          apply Quot.induction_on x 
          clear x 
          intro x 
          cases' x with j x 
          erw [colimit_smul_mk_eq F (r*s) ⟨j, x⟩, colimit_smul_mk_eq F s ⟨j, x⟩, colimit_smul_mk_eq F r ⟨j, _⟩,
            mul_smul],
    smul_add :=
      fun r x y =>
        by 
          apply Quot.induction_on₂ x y 
          clear x y 
          intro x y 
          cases' x with i x 
          cases' y with j y 
          erw [colimit_add_mk_eq _ ⟨i, x⟩ ⟨j, y⟩ (max' i j) (left_to_max i j) (right_to_max i j), colimit_smul_mk_eq,
            smul_add, colimit_smul_mk_eq, colimit_smul_mk_eq,
            colimit_add_mk_eq _ ⟨i, _⟩ ⟨j, _⟩ (max' i j) (left_to_max i j) (right_to_max i j), LinearMap.map_smul,
            LinearMap.map_smul]
          rfl,
    smul_zero :=
      fun r =>
        by 
          erw [colimit_zero_eq _ (is_filtered.nonempty.some : J), colimit_smul_mk_eq, smul_zero]
          rfl,
    zero_smul :=
      fun x =>
        by 
          apply Quot.induction_on x 
          clear x 
          intro x 
          cases' x with j x 
          erw [colimit_smul_mk_eq, zero_smul, colimit_zero_eq _ j]
          rfl,
    add_smul :=
      fun r s x =>
        by 
          apply Quot.induction_on x 
          clear x 
          intro x 
          cases' x with j x 
          erw [colimit_smul_mk_eq, add_smul, colimit_smul_mk_eq, colimit_smul_mk_eq,
            colimit_add_mk_eq _ ⟨j, _⟩ ⟨j, _⟩ j (𝟙 j) (𝟙 j), CategoryTheory.Functor.map_id, id_apply, id_apply]
          rfl }

/-- The bundled `R`-module giving the filtered colimit of a diagram. -/
def colimit : ModuleCat R :=
  ModuleCat.of R M

/-- The linear map from a given `R`-module in the diagram to the colimit module. -/
def cocone_morphism (j : J) : F.obj j ⟶ colimit :=
  { (AddCommGroupₓₓ.FilteredColimits.colimitCocone (F ⋙ forget₂ (ModuleCat R) AddCommGroupₓₓ)).ι.app j with
    map_smul' :=
      fun r x =>
        by 
          erw [colimit_smul_mk_eq F r ⟨j, x⟩]
          rfl }

/-- The cocone over the proposed colimit module. -/
def colimit_cocone : cocone F :=
  { x := colimit,
    ι :=
      { app := cocone_morphism,
        naturality' :=
          fun j j' f => LinearMap.coe_injective ((types.colimit_cocone (F ⋙ forget (ModuleCat R))).ι.naturality f) } }

/--
Given a cocone `t` of `F`, the induced monoid linear map from the colimit to the cocone point.
We already know that this is a morphism between additive groups. The only thing left to see is that
it is a linear map, i.e. preserves scalar multiplication.
-/
def colimit_desc (t : cocone F) : colimit ⟶ t.X :=
  { (AddCommGroupₓₓ.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ (ModuleCat R) AddCommGroupₓₓ)).desc
      ((forget₂ (ModuleCat R) AddCommGroupₓₓ.{v}).mapCocone t) with
    map_smul' :=
      fun r x =>
        by 
          apply Quot.induction_on x 
          clear x 
          intro x 
          cases' x with j x 
          erw [colimit_smul_mk_eq]
          exact LinearMap.map_smul (t.ι.app j) r x }

/-- The proposed colimit cocone is a colimit in `Module R`. -/
def colimit_cocone_is_colimit : is_colimit colimit_cocone :=
  { desc := colimit_desc,
    fac' :=
      fun t j =>
        LinearMap.coe_injective$
          (types.colimit_cocone_is_colimit (F ⋙ forget (ModuleCat R))).fac ((forget (ModuleCat R)).mapCocone t) j,
    uniq' :=
      fun t m h =>
        LinearMap.coe_injective$
          (types.colimit_cocone_is_colimit (F ⋙ forget (ModuleCat R))).uniq ((forget (ModuleCat R)).mapCocone t) m
            fun j => funext$ fun x => LinearMap.congr_fun (h j) x }

instance forget₂_AddCommGroup_preserves_filtered_colimits :
  preserves_filtered_colimits (forget₂ (ModuleCat R) AddCommGroupₓₓ.{v}) :=
  { PreservesFilteredColimits :=
      fun J _ _ =>
        by 
          exact
            { PreservesColimit :=
                fun F =>
                  preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
                    (AddCommGroupₓₓ.FilteredColimits.colimitCoconeIsColimit
                      (F ⋙ forget₂ (ModuleCat R) AddCommGroupₓₓ.{v})) } }

instance forget_preserves_filtered_colimits : preserves_filtered_colimits (forget (ModuleCat R)) :=
  limits.comp_preserves_filtered_colimits (forget₂ (ModuleCat R) AddCommGroupₓₓ) (forget AddCommGroupₓₓ)

end 

end ModuleCat.FilteredColimits

