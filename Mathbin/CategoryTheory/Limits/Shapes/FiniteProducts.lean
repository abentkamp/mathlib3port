import Mathbin.CategoryTheory.Limits.Shapes.BinaryProducts 
import Mathbin.CategoryTheory.Limits.Shapes.FiniteLimits 
import Mathbin.CategoryTheory.Limits.Shapes.Products 
import Mathbin.CategoryTheory.Limits.Shapes.Terminal

/-!
# Categories with finite (co)products

Typeclasses representing categories with (co)products over finite indexing types.
-/


universe v u

open CategoryTheory

namespace CategoryTheory.Limits

variable(C : Type u)[category.{v} C]

/--
A category has finite products if there is a chosen limit for every diagram
with shape `discrete J`, where we have `[decidable_eq J]` and `[fintype J]`.
-/
class has_finite_products : Prop where 
  out (J : Type v) [DecidableEq J] [Fintype J] : has_limits_of_shape (discrete J) C

-- error in CategoryTheory.Limits.Shapes.FiniteProducts: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
instance has_limits_of_shape_discrete
(J : Type v)
[fintype J]
[has_finite_products C] : has_limits_of_shape (discrete J) C :=
by { haveI [] [] [":=", expr @has_finite_products.out C _ _ J (classical.dec_eq _)],
  apply_instance }

/-- If `C` has finite limits then it has finite products. -/
instance (priority := 10)has_finite_products_of_has_finite_limits [has_finite_limits C] : has_finite_products C :=
  ⟨fun J 𝒥₁ 𝒥₂ =>
      by 
        skip 
        infer_instance⟩

/--
If a category has all products then in particular it has finite products.
-/
theorem has_finite_products_of_has_products [has_products C] : has_finite_products C :=
  ⟨by 
      infer_instance⟩

/--
A category has finite coproducts if there is a chosen colimit for every diagram
with shape `discrete J`, where we have `[decidable_eq J]` and `[fintype J]`.
-/
class has_finite_coproducts : Prop where 
  out (J : Type v) [DecidableEq J] [Fintype J] : has_colimits_of_shape (discrete J) C

attribute [class] has_finite_coproducts

-- error in CategoryTheory.Limits.Shapes.FiniteProducts: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
instance has_colimits_of_shape_discrete
(J : Type v)
[fintype J]
[has_finite_coproducts C] : has_colimits_of_shape (discrete J) C :=
by { haveI [] [] [":=", expr @has_finite_coproducts.out C _ _ J (classical.dec_eq _)],
  apply_instance }

/-- If `C` has finite colimits then it has finite coproducts. -/
instance (priority := 10)has_finite_coproducts_of_has_finite_colimits [has_finite_colimits C] :
  has_finite_coproducts C :=
  ⟨fun J 𝒥₁ 𝒥₂ =>
      by 
        skip 
        infer_instance⟩

/--
If a category has all coproducts then in particular it has finite coproducts.
-/
theorem has_finite_coproducts_of_has_coproducts [has_coproducts C] : has_finite_coproducts C :=
  ⟨by 
      infer_instance⟩

end CategoryTheory.Limits

