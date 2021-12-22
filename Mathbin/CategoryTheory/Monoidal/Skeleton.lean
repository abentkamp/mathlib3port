import Mathbin.CategoryTheory.Monoidal.Functor
import Mathbin.CategoryTheory.Monoidal.Braided
import Mathbin.CategoryTheory.Monoidal.Transport
import Mathbin.CategoryTheory.Skeletal

/-!
# The monoid on the skeleton of a monoidal category

The skeleton of a monoidal category is a monoid.
-/


namespace CategoryTheory

open MonoidalCategory

universe v u

variable {C : Type u} [category.{v} C] [monoidal_category C]

/--  If `C` is monoidal and skeletal, it is a monoid.
See note [reducible non-instances]. -/
@[reducible]
def monoid_of_skeletal_monoidal (hC : skeletal C) : Monoidₓ C :=
  { mul := fun X Y => (X ⊗ Y : C), one := (𝟙_ C : C), one_mul := fun X => hC ⟨λ_ X⟩, mul_one := fun X => hC ⟨ρ_ X⟩,
    mul_assoc := fun X Y Z => hC ⟨α_ X Y Z⟩ }

/--  If `C` is braided and skeletal, it is a commutative monoid. -/
def comm_monoid_of_skeletal_braided [braided_category C] (hC : skeletal C) : CommMonoidₓ C :=
  { monoid_of_skeletal_monoidal hC with mul_comm := fun X Y => hC ⟨β_ X Y⟩ }

/-- 
The skeleton of a monoidal category has a monoidal structure itself, induced by the equivalence.
-/
noncomputable instance : monoidal_category (skeleton C) :=
  monoidal.transport (skeleton_equivalence C).symm

/-- 
The skeleton of a monoidal category can be viewed as a monoid, where the multiplication is given by
the tensor product, and satisfies the monoid axioms since it is a skeleton.
-/
noncomputable instance : Monoidₓ (skeleton C) :=
  monoid_of_skeletal_monoidal (skeleton_is_skeleton _).skel

end CategoryTheory

