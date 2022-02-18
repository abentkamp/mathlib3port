import Mathbin.CategoryTheory.Category.Basic

/-!
# The Kleisli construction on the Type category

Define the Kleisli category for (control) monads.
`category_theory/monad/kleisli` defines the general version for a monad on `C`, and demonstrates
the equivalence between the two.

## TODO

Generalise this to work with category_theory.monad
-/


universe u v

namespace CategoryTheory

/-- The Kleisli category on the (type-)monad `m`. Note that the monad is not assumed to be lawful
yet. -/
@[nolint unused_arguments]
def Kleisli (m : Type u → Type v) :=
  Type u

/-- Construct an object of the Kleisli category from a type. -/
def Kleisli.mk m (α : Type u) : KleisliCat m :=
  α

instance Kleisli.category_struct {m} [Monadₓ.{u, v} m] : CategoryStruct (KleisliCat m) where
  Hom := fun α β => α → m β
  id := fun α x => pure x
  comp := fun X Y Z f g => f >=> g

instance Kleisli.category {m} [Monadₓ.{u, v} m] [IsLawfulMonad m] : Category (KleisliCat m) := by
  refine' { id_comp' := _, comp_id' := _, assoc' := _ } <;>
    intros <;> ext <;> unfold_projs <;> simp' only [· >=> ·] with functor_norm

@[simp]
theorem Kleisli.id_def {m} [Monadₓ m] (α : KleisliCat m) : 𝟙 α = @pure m _ α :=
  rfl

theorem Kleisli.comp_def {m} [Monadₓ m] (α β γ : KleisliCat m) (xs : α ⟶ β) (ys : β ⟶ γ) (a : α) :
    (xs ≫ ys) a = xs a >>= ys :=
  rfl

instance : Inhabited (KleisliCat id) :=
  ⟨PUnit⟩

instance {α : Type u} [Inhabited α] : Inhabited (KleisliCat.mk id α) :=
  ⟨show α from default⟩

end CategoryTheory

