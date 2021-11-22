import Mathbin.CategoryTheory.Limits.Preserves.Shapes.BinaryProducts 
import Mathbin.CategoryTheory.Limits.Constructions.FiniteProductsOfBinaryProducts 
import Mathbin.CategoryTheory.Monad.Limits 
import Mathbin.CategoryTheory.Adjunction.FullyFaithful 
import Mathbin.CategoryTheory.Adjunction.Reflective 
import Mathbin.CategoryTheory.Closed.Cartesian 
import Mathbin.CategoryTheory.Subterminal

/-!
# Exponential ideals

An exponential ideal of a cartesian closed category `C` is a subcategory `D ⊆ C` such that for any
`B : D` and `A : C`, the exponential `A ⟹ B` is in `D`: resembling ring theoretic ideals. We
define the notion here for inclusion functors `i : D ⥤ C` rather than explicit subcategories to
preserve the principle of equivalence.

We additionally show that if `C` is cartesian closed and `i : D ⥤ C` is a reflective functor, the
following are equivalent.
* The left adjoint to `i` preserves binary (equivalently, finite) products.
* `i` is an exponential ideal.
-/


universe v₁ v₂ u₁ u₂

noncomputable theory

namespace CategoryTheory

open Limits Category

section Ideal

variable{C : Type u₁}{D : Type u₂}[category.{v₁} C][category.{v₁} D]{i : D ⥤ C}

variable(i)[has_finite_products C][cartesian_closed C]

/--
The subcategory `D` of `C` expressed as an inclusion functor is an *exponential ideal* if
`B ∈ D` implies `A ⟹ B ∈ D` for all `A`.
-/
class exponential_ideal : Prop where 
  exp_closed : ∀ {B}, B ∈ i.ess_image → ∀ A, (A ⟹ B) ∈ i.ess_image

/--
To show `i` is an exponential ideal it suffices to show that `A ⟹ iB` is "in" `D` for any `A` in
`C` and `B` in `D`.
-/
theorem exponential_ideal.mk' (h : ∀ B : D A : C, (A ⟹ i.obj B) ∈ i.ess_image) : exponential_ideal i :=
  ⟨fun B hB A =>
      by 
        rcases hB with ⟨B', ⟨iB'⟩⟩
        exact functor.ess_image.of_iso ((exp A).mapIso iB') (h B' A)⟩

/-- The entire category viewed as a subcategory is an exponential ideal. -/
instance  : exponential_ideal (𝟭 C) :=
  exponential_ideal.mk' _ fun B A => ⟨_, ⟨iso.refl _⟩⟩

open CartesianClosed

/-- The subcategory of subterminal objects is an exponential ideal. -/
instance  : exponential_ideal (subterminal_inclusion C) :=
  by 
    apply exponential_ideal.mk' 
    intro B A 
    refine' ⟨⟨A ⟹ B.1, fun Z g h => _⟩, ⟨iso.refl _⟩⟩
    exact uncurry_injective (B.2 (cartesian_closed.uncurry g) (cartesian_closed.uncurry h))

/--
If `D` is a reflective subcategory, the property of being an exponential ideal is equivalent to
the presence of a natural isomorphism `i ⋙ exp A ⋙ left_adjoint i ⋙ i ≅ i ⋙ exp A`, that is:
`(A ⟹ iB) ≅ i L (A ⟹ iB)`, naturally in `B`.
The converse is given in `exponential_ideal.mk_of_iso`.
-/
def exponential_ideal_reflective (A : C) [reflective i] [exponential_ideal i] :
  i ⋙ exp A ⋙ left_adjoint i ⋙ i ≅ i ⋙ exp A :=
  by 
    symm 
    apply nat_iso.of_components _ _
    ·
      intro X 
      haveI  := (exponential_ideal.exp_closed (i.obj_mem_ess_image X) A).unit_is_iso 
      apply as_iso ((adjunction.of_right_adjoint i).Unit.app (A ⟹ i.obj X))
    ·
      simp 

/--
Given a natural isomorphism `i ⋙ exp A ⋙ left_adjoint i ⋙ i ≅ i ⋙ exp A`, we can show `i`
is an exponential ideal.
-/
theorem exponential_ideal.mk_of_iso [reflective i] (h : ∀ A : C, i ⋙ exp A ⋙ left_adjoint i ⋙ i ≅ i ⋙ exp A) :
  exponential_ideal i :=
  by 
    apply exponential_ideal.mk' 
    intro B A 
    exact ⟨_, ⟨(h A).app B⟩⟩

end Ideal

section 

variable{C : Type u₁}{D : Type u₂}[category.{v₁} C][category.{v₁} D]

variable(i : D ⥤ C)

theorem reflective_products [has_finite_products C] [reflective i] : has_finite_products D :=
  ⟨fun J 𝒥₁ 𝒥₂ =>
      by 
        exactI has_limits_of_shape_of_reflective i⟩

attribute [local instance] reflective_products

open CartesianClosed

variable[has_finite_products C][reflective i][cartesian_closed C]

/--
If the reflector preserves binary products, the subcategory is an exponential ideal.
This is the converse of `preserves_binary_products_of_exponential_ideal`.
-/
instance (priority := 10)exponential_ideal_of_preserves_binary_products
  [preserves_limits_of_shape (discrete walking_pair) (left_adjoint i)] : exponential_ideal i :=
  by 
    let ir := adjunction.of_right_adjoint i 
    let L : C ⥤ D := left_adjoint i 
    let η : 𝟭 C ⟶ L ⋙ i := ir.unit 
    let ε : i ⋙ L ⟶ 𝟭 D := ir.counit 
    apply exponential_ideal.mk' 
    intro B A 
    let q : i.obj (L.obj (A ⟹ i.obj B)) ⟶ A ⟹ i.obj B 
    apply cartesian_closed.curry (ir.hom_equiv _ _ _)
    apply _ ≫ (ir.hom_equiv _ _).symm ((ev A).app (i.obj B))
    refine' prod_comparison L A _ ≫ limits.prod.map (𝟙 _) (ε.app _) ≫ inv (prod_comparison _ _ _)
    have  : η.app (A ⟹ i.obj B) ≫ q = 𝟙 (A ⟹ i.obj B)
    ·
      dsimp 
      rw [←curry_natural_left, curry_eq_iff, uncurry_id_eq_ev, ←ir.hom_equiv_naturality_left, ir.hom_equiv_apply_eq,
        assoc, assoc, prod_comparison_natural_assoc, L.map_id, ←prod.map_id_comp_assoc, ir.left_triangle_components,
        prod.map_id_id, id_comp]
      apply is_iso.hom_inv_id_assoc 
    haveI  : split_mono (η.app (A ⟹ i.obj B)) := ⟨_, this⟩
    apply mem_ess_image_of_unit_split_mono

variable[exponential_ideal i]

/--
If `i` witnesses that `D` is a reflective subcategory and an exponential ideal, then `D` is
itself cartesian closed.
-/
def cartesian_closed_of_reflective : cartesian_closed D :=
  { closed :=
      fun B =>
        { isAdj :=
            { right := i ⋙ exp (i.obj B) ⋙ left_adjoint i,
              adj :=
                by 
                  apply adjunction.restrict_fully_faithful i i (exp.adjunction (i.obj B))
                  ·
                    symm 
                    apply nat_iso.of_components _ _
                    ·
                      intro X 
                      haveI  := adjunction.right_adjoint_preserves_limits (adjunction.of_right_adjoint i)
                      apply as_iso (prod_comparison i B X)
                    ·
                      intro X Y f 
                      dsimp 
                      rw [prod_comparison_natural]
                      simp 
                  ·
                    apply (exponential_ideal_reflective i _).symm } } }

attribute [-instance] CategoryTheory.preservesLimitOfCreatesLimitAndHasLimit
  CategoryTheory.preservesLimitOfShapeOfCreatesLimitsOfShapeAndHasLimitsOfShape

/--
We construct a bijection between morphisms `L(A ⨯ B) ⟶ X` and morphisms `LA ⨯ LB ⟶ X`.
This bijection has two key properties:
* It is natural in `X`: See `bijection_natural`.
* When `X = LA ⨯ LB`, then the backwards direction sends the identity morphism to the product
  comparison morphism: See `bijection_symm_apply_id`.

Together these help show that `L` preserves binary products. This should be considered
*internal implementation* towards `preserves_binary_products_of_exponential_ideal`.
-/
noncomputable def bijection (A B : C) (X : D) :
  ((left_adjoint i).obj (A ⨯ B) ⟶ X) ≃ ((left_adjoint i).obj A ⨯ (left_adjoint i).obj B ⟶ X) :=
  calc _ ≃ (A ⨯ B ⟶ i.obj X) := (adjunction.of_right_adjoint i).homEquiv _ _ 
    _ ≃ (B ⨯ A ⟶ i.obj X) := (limits.prod.braiding _ _).homCongr (iso.refl _)
    _ ≃ (A ⟶ B ⟹ i.obj X) := (exp.adjunction _).homEquiv _ _ 
    _ ≃ (i.obj ((left_adjoint i).obj A) ⟶ B ⟹ i.obj X) :=
    unit_comp_partial_bijective _ (exponential_ideal.exp_closed (i.obj_mem_ess_image _) _)
    _ ≃ (B ⨯ i.obj ((left_adjoint i).obj A) ⟶ i.obj X) := ((exp.adjunction _).homEquiv _ _).symm 
    _ ≃ (i.obj ((left_adjoint i).obj A) ⨯ B ⟶ i.obj X) := (limits.prod.braiding _ _).homCongr (iso.refl _)
    _ ≃ (B ⟶ i.obj ((left_adjoint i).obj A) ⟹ i.obj X) := (exp.adjunction _).homEquiv _ _ 
    _ ≃ (i.obj ((left_adjoint i).obj B) ⟶ i.obj ((left_adjoint i).obj A) ⟹ i.obj X) :=
    unit_comp_partial_bijective _ (exponential_ideal.exp_closed (i.obj_mem_ess_image _) _)
    _ ≃ (i.obj ((left_adjoint i).obj A) ⨯ i.obj ((left_adjoint i).obj B) ⟶ i.obj X) :=
    ((exp.adjunction _).homEquiv _ _).symm 
    _ ≃ (i.obj ((left_adjoint i).obj A ⨯ (left_adjoint i).obj B) ⟶ i.obj X) :=
    by 
      apply iso.hom_congr _ (iso.refl _)
      haveI  : preserves_limits i := (adjunction.of_right_adjoint i).rightAdjointPreservesLimits 
      exact (preserves_limit_pair.iso _ _ _).symm 
    _ ≃ ((left_adjoint i).obj A ⨯ (left_adjoint i).obj B ⟶ X) := (equiv_of_fully_faithful _).symm
    

theorem bijection_symm_apply_id (A B : C) : (bijection i A B _).symm (𝟙 _) = prod_comparison _ _ _ :=
  by 
    dsimp [bijection]
    rw [comp_id, comp_id, comp_id, i.map_id, comp_id, unit_comp_partial_bijective_symm_apply,
      unit_comp_partial_bijective_symm_apply, uncurry_natural_left, uncurry_curry, uncurry_natural_left, uncurry_curry,
      prod.lift_map_assoc, comp_id, prod.lift_map_assoc, comp_id, prod.comp_lift_assoc, prod.lift_snd,
      prod.lift_fst_assoc, prod.lift_fst_comp_snd_comp, ←adjunction.eq_hom_equiv_apply, adjunction.hom_equiv_unit,
      iso.comp_inv_eq, assoc, preserves_limit_pair.iso_hom]
    apply prod.hom_ext
    ·
      rw [limits.prod.map_fst, assoc, assoc, prod_comparison_fst, ←i.map_comp, prod_comparison_fst]
      apply (adjunction.of_right_adjoint i).Unit.naturality
    ·
      rw [limits.prod.map_snd, assoc, assoc, prod_comparison_snd, ←i.map_comp, prod_comparison_snd]
      apply (adjunction.of_right_adjoint i).Unit.naturality

theorem bijection_natural (A B : C) (X X' : D) (f : (left_adjoint i).obj (A ⨯ B) ⟶ X) (g : X ⟶ X') :
  bijection i _ _ _ (f ≫ g) = bijection i _ _ _ f ≫ g :=
  by 
    dsimp [bijection]
    apply i.map_injective 
    rw [i.image_preimage, i.map_comp, i.image_preimage, comp_id, comp_id, comp_id, comp_id, comp_id, comp_id,
      adjunction.hom_equiv_naturality_right, ←assoc, curry_natural_right _ (i.map g),
      unit_comp_partial_bijective_natural, uncurry_natural_right, ←assoc, curry_natural_right,
      unit_comp_partial_bijective_natural, uncurry_natural_right, assoc]

/--
The bijection allows us to show that `prod_comparison L A B` is an isomorphism, where the inverse
is the forward map of the identity morphism.
-/
theorem prod_comparison_iso (A B : C) : is_iso (prod_comparison (left_adjoint i) A B) :=
  ⟨⟨bijection i _ _ _ (𝟙 _),
      by 
        rw [←(bijection i _ _ _).Injective.eq_iff, bijection_natural, ←bijection_symm_apply_id, Equiv.apply_symm_apply,
          id_comp],
      by 
        rw [←bijection_natural, id_comp, ←bijection_symm_apply_id, Equiv.apply_symm_apply]⟩⟩

attribute [local instance] prod_comparison_iso

/--
If a reflective subcategory is an exponential ideal, then the reflector preserves binary products.
This is the converse of `exponential_ideal_of_preserves_binary_products`.
-/
noncomputable def preserves_binary_products_of_exponential_ideal :
  preserves_limits_of_shape (discrete walking_pair) (left_adjoint i) :=
  { PreservesLimit :=
      fun K =>
        by 
          apply limits.preserves_limit_of_iso_diagram _ (diagram_iso_pair K).symm 
          apply preserves_limit_pair.of_iso_prod_comparison }

/--
If a reflective subcategory is an exponential ideal, then the reflector preserves finite products.
-/
noncomputable def preserves_finite_products_of_exponential_ideal (J : Type _) [Fintype J] :
  preserves_limits_of_shape (discrete J) (left_adjoint i) :=
  by 
    letI this := preserves_binary_products_of_exponential_ideal i 
    letI this := left_adjoint_preserves_terminal_of_reflective i 
    apply preserves_finite_products_of_preserves_binary_and_terminal (left_adjoint i) J

end 

end CategoryTheory

