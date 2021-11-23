import Mathbin.CategoryTheory.Monoidal.OfChosenFiniteProducts 
import Mathbin.CategoryTheory.Limits.Shapes.Types

/-!
# The category of types is a symmetric monoidal category
-/


open CategoryTheory

open CategoryTheory.Limits

open Tactic

universe v u

namespace CategoryTheory

instance types_monoidal : monoidal_category.{u} (Type u) :=
  monoidal_of_chosen_finite_products types.terminal_limit_cone types.binary_product_limit_cone

instance types_symmetric : symmetric_category.{u} (Type u) :=
  symmetric_of_chosen_finite_products types.terminal_limit_cone types.binary_product_limit_cone

@[simp]
theorem tensor_apply {W X Y Z : Type u} (f : W ⟶ X) (g : Y ⟶ Z) (p : W ⊗ Y) : (f ⊗ g) p = (f p.1, g p.2) :=
  rfl

@[simp]
theorem left_unitor_hom_apply {X : Type u} {x : X} {p : PUnit} : ((λ_ X).Hom : 𝟙_ (Type u) ⊗ X → X) (p, x) = x :=
  rfl

@[simp]
theorem left_unitor_inv_apply {X : Type u} {x : X} : ((λ_ X).inv : X ⟶ 𝟙_ (Type u) ⊗ X) x = (PUnit.unit, x) :=
  rfl

@[simp]
theorem right_unitor_hom_apply {X : Type u} {x : X} {p : PUnit} : ((ρ_ X).Hom : X ⊗ 𝟙_ (Type u) → X) (x, p) = x :=
  rfl

@[simp]
theorem right_unitor_inv_apply {X : Type u} {x : X} : ((ρ_ X).inv : X ⟶ X ⊗ 𝟙_ (Type u)) x = (x, PUnit.unit) :=
  rfl

@[simp]
theorem associator_hom_apply {X Y Z : Type u} {x : X} {y : Y} {z : Z} :
  ((α_ X Y Z).Hom : (X ⊗ Y) ⊗ Z → X ⊗ Y ⊗ Z) ((x, y), z) = (x, (y, z)) :=
  rfl

@[simp]
theorem associator_inv_apply {X Y Z : Type u} {x : X} {y : Y} {z : Z} :
  ((α_ X Y Z).inv : X ⊗ Y ⊗ Z → (X ⊗ Y) ⊗ Z) (x, (y, z)) = ((x, y), z) :=
  rfl

@[simp]
theorem braiding_hom_apply {X Y : Type u} {x : X} {y : Y} : ((β_ X Y).Hom : X ⊗ Y → Y ⊗ X) (x, y) = (y, x) :=
  rfl

@[simp]
theorem braiding_inv_apply {X Y : Type u} {x : X} {y : Y} : ((β_ X Y).inv : Y ⊗ X → X ⊗ Y) (y, x) = (x, y) :=
  rfl

open Opposite

open MonoidalCategory

/-- `(𝟙_ C ⟶ -)` is a lax monoidal functor to `Type`. -/
def coyoneda_tensor_unit (C : Type u) [category.{v} C] [monoidal_category C] : lax_monoidal_functor C (Type v) :=
  { coyoneda.obj (op (𝟙_ C)) with ε := fun p => 𝟙 _, μ := fun X Y p => (λ_ (𝟙_ C)).inv ≫ (p.1 ⊗ p.2),
    μ_natural' :=
      by 
        tidy,
    associativity' :=
      fun X Y Z =>
        by 
          ext ⟨⟨f, g⟩, h⟩
          dsimp  at f g h 
          dsimp 
          simp only [iso.cancel_iso_inv_left, category.assoc]
          convLHS =>
            rw [←category.id_comp h, tensor_comp, category.assoc, associator_naturality, ←category.assoc,
              unitors_inv_equal, triangle_assoc_comp_right_inv]
          convRHS => rw [←category.id_comp f, tensor_comp],
    left_unitality' :=
      by 
        tidy,
    right_unitality' :=
      fun X =>
        by 
          ext ⟨f, ⟨⟩⟩
          dsimp  at f 
          dsimp 
          simp only [category.assoc]
          rw [right_unitor_naturality, unitors_inv_equal, iso.inv_hom_id_assoc] }

end CategoryTheory

