import Mathbin.CategoryTheory.Functor

/-!
# Unbundled functors, as a typeclass decorating the object-level function.
-/


namespace CategoryTheory

universe v v₁ v₂ v₃ u u₁ u₂ u₃

variable {C : Type u₁} [Category.{v₁} C] {D : Type u₂} [Category.{v₂} D]

/-- A unbundled functor. -/
class functorial (F : C → D) : Type max v₁ v₂ u₁ u₂ where
  map : ∀ {X Y : C}, (X ⟶ Y) → (F X ⟶ F Y)
  map_id' : ∀ X : C, map (𝟙 X) = 𝟙 (F X) := by
    run_tac
      obviously
  map_comp' : ∀ {X Y Z : C} f : X ⟶ Y g : Y ⟶ Z, map (f ≫ g) = map f ≫ map g := by
    run_tac
      obviously

/-- If `F : C → D` (just a function) has `[functorial F]`,
we can write `map F f : F X ⟶ F Y` for the action of `F` on a morphism `f : X ⟶ Y`.
-/
def map (F : C → D) [Functorial.{v₁, v₂} F] {X Y : C} (f : X ⟶ Y) : F X ⟶ F Y :=
  Functorial.map.{v₁, v₂} f

@[simp]
theorem map_as_map {F : C → D} [Functorial.{v₁, v₂} F] {X Y : C} {f : X ⟶ Y} : Functorial.map.{v₁, v₂} f = map F f :=
  rfl

@[simp]
theorem functorial.map_id {F : C → D} [Functorial.{v₁, v₂} F] {X : C} : map F (𝟙 X) = 𝟙 (F X) :=
  Functorial.map_id' X

@[simp]
theorem functorial.map_comp {F : C → D} [Functorial.{v₁, v₂} F] {X Y Z : C} {f : X ⟶ Y} {g : Y ⟶ Z} :
    map F (f ≫ g) = map F f ≫ map F g :=
  Functorial.map_comp' f g

namespace Functor

/-- Bundle a functorial function as a functor.
-/
def of (F : C → D) [I : Functorial.{v₁, v₂} F] : C ⥤ D :=
  { I with obj := F }

end Functor

instance (F : C ⥤ D) : Functorial.{v₁, v₂} F.obj :=
  { F with }

@[simp]
theorem map_functorial_obj (F : C ⥤ D) {X Y : C} (f : X ⟶ Y) : map F.obj f = F.map f :=
  rfl

instance functorial_id : Functorial.{v₁, v₁} (id : C → C) where
  map := fun X Y f => f

section

variable {E : Type u₃} [Category.{v₃} E]

/-- `G ∘ F` is a functorial if both `F` and `G` are.
-/
def functorial_comp (F : C → D) [Functorial.{v₁, v₂} F] (G : D → E) [Functorial.{v₂, v₃} G] :
    Functorial.{v₁, v₃} (G ∘ F) :=
  { Functor.of F ⋙ Functor.of G with }

end

end CategoryTheory

