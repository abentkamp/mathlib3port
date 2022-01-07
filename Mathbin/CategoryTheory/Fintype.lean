import Mathbin.CategoryTheory.ConcreteCategory.Bundled
import Mathbin.CategoryTheory.FullSubcategory
import Mathbin.CategoryTheory.Skeletal
import Mathbin.Data.Fin.Basic
import Mathbin.Data.Fintype.Basic

/-!
# The category of finite types.

We define the category of finite types, denoted `Fintype` as
(bundled) types with a `fintype` instance.

We also define `Fintype.skeleton`, the standard skeleton of `Fintype` whose objects are `fin n`
for `n : ℕ`. We prove that the obvious inclusion functor `Fintype.skeleton ⥤ Fintype` is an
equivalence of categories in `Fintype.skeleton.equivalence`.
We prove that `Fintype.skeleton` is a skeleton of `Fintype` in `Fintype.is_skeleton`.
-/


open_locale Classical

open CategoryTheory

/-- The category of finite types. -/
def Fintypeₓ :=
  bundled Fintype

namespace Fintypeₓ

instance : CoeSort Fintypeₓ (Type _) :=
  bundled.has_coe_to_sort

/-- Construct a bundled `Fintype` from the underlying type and typeclass. -/
def of (X : Type _) [Fintype X] : Fintypeₓ :=
  bundled.of X

instance : Inhabited Fintypeₓ :=
  ⟨⟨Pempty⟩⟩

instance {X : Fintypeₓ} : Fintype X :=
  X.2

instance : category Fintypeₓ :=
  induced_category.category bundled.α

/-- The fully faithful embedding of `Fintype` into the category of types. -/
@[simps]
def incl : Fintypeₓ ⥤ Type _ :=
  induced_functor _ deriving full, faithful

instance : concrete_category Fintypeₓ :=
  ⟨incl⟩

@[simp]
theorem id_apply (X : Fintypeₓ) (x : X) : (𝟙 X : X → X) x = x :=
  rfl

@[simp]
theorem comp_apply {X Y Z : Fintypeₓ} (f : X ⟶ Y) (g : Y ⟶ Z) (x : X) : (f ≫ g) x = g (f x) :=
  rfl

universe u

/-- The "standard" skeleton for `Fintype`. This is the full subcategory of `Fintype` spanned by objects
of the form `ulift (fin n)` for `n : ℕ`. We parameterize the objects of `Fintype.skeleton`
directly as `ulift ℕ`, as the type `ulift (fin m) ≃ ulift (fin n)` is
nonempty if and only if `n = m`. Specifying universes, `skeleton : Type u` is a small
skeletal category equivalent to `Fintype.{u}`.
-/
def skeleton : Type u :=
  Ulift ℕ

namespace Skeleton

/-- Given any natural number `n`, this creates the associated object of `Fintype.skeleton`. -/
def mk : ℕ → skeleton :=
  Ulift.up

instance : Inhabited skeleton :=
  ⟨mk 0⟩

/-- Given any object of `Fintype.skeleton`, this returns the associated natural number. -/
def len : skeleton → ℕ :=
  Ulift.down

@[ext]
theorem ext (X Y : skeleton) : X.len = Y.len → X = Y :=
  Ulift.ext _ _

instance : small_category skeleton.{u} where
  Hom := fun X Y => Ulift.{u} (Finₓ X.len) → Ulift.{u} (Finₓ Y.len)
  id := fun _ => id
  comp := fun _ _ _ f g => g ∘ f

theorem is_skeletal : skeletal skeleton.{u} := fun X Y ⟨h⟩ =>
  ext _ _ $
    Finₓ.equiv_iff_eq.mp $
      Nonempty.intro $
        { toFun := fun x => (h.hom ⟨x⟩).down, invFun := fun x => (h.inv ⟨x⟩).down,
          left_inv := by
            intro a
            change Ulift.down _ = _
            rw [Ulift.up_down]
            change ((h.hom ≫ h.inv) _).down = _
            simpa,
          right_inv := by
            intro a
            change Ulift.down _ = _
            rw [Ulift.up_down]
            change ((h.inv ≫ h.hom) _).down = _
            simpa }

/-- The canonical fully faithful embedding of `Fintype.skeleton` into `Fintype`. -/
def incl : skeleton.{u} ⥤ Fintypeₓ.{u} where
  obj := fun X => Fintypeₓ.of (Ulift (Finₓ X.len))
  map := fun _ _ f => f

instance : full incl where
  Preimage := fun _ _ f => f

instance : faithful incl :=
  {  }

instance : ess_surj incl :=
  ess_surj.mk $ fun X =>
    let F := Fintype.equivFin X
    ⟨mk (Fintype.card X), Nonempty.intro { Hom := F.symm ∘ Ulift.down, inv := Ulift.up ∘ F }⟩

noncomputable instance : is_equivalence incl :=
  equivalence.of_fully_faithfully_ess_surj _

/-- The equivalence between `Fintype.skeleton` and `Fintype`. -/
noncomputable def Equivalenceₓ : skeleton ≌ Fintypeₓ :=
  incl.asEquivalence

@[simp]
theorem incl_mk_nat_card (n : ℕ) : Fintype.card (incl.obj (mk n)) = n := by
  convert Finset.card_fin n
  apply Fintype.of_equiv_card

end Skeleton

/-- `Fintype.skeleton` is a skeleton of `Fintype`. -/
noncomputable def is_skeleton : is_skeleton_of Fintypeₓ skeleton skeleton.incl where
  skel := skeleton.is_skeletal
  eqv := by
    infer_instance

end Fintypeₓ

