import Mathbin.Algebra.Category.CommRing.Basic
import Mathbin.Algebra.Category.Group.FilteredColimits

/-!
# The forgetful functor from (commutative) (semi-) rings preserves filtered colimits.

Forgetful functors from algebraic categories usually don't preserve colimits. However, they tend
to preserve _filtered_ colimits.

In this file, we start with a small filtered category `J` and a functor `F : J ⥤ SemiRing`.
We show that the colimit of `F ⋙ forget₂ SemiRing Mon` (in `Mon`) carries the structure of a
semiring, thereby showing that the forgetful functor `forget₂ SemiRing Mon` preserves filtered
colimits. In particular, this implies that `forget SemiRing` preserves filtered colimits.
Similarly for `CommSemiRing`, `Ring` and `CommRing`.

-/


universe v

noncomputable section

open_locale Classical

open CategoryTheory

open CategoryTheory.Limits

open CategoryTheory.IsFiltered renaming max → max'

open AddMon.filtered_colimits (colimit_zero_eq colimit_add_mk_eq)

open Mon.filtered_colimits (colimit_one_eq colimit_mul_mk_eq)

namespace SemiRing.FilteredColimits

section

parameter {J : Type v}[small_category J](F : J ⥤ SemiRing.{v})

instance semiring_obj (j : J) : Semiringₓ (((F ⋙ forget₂ SemiRing Mon.{v}) ⋙ forget Mon).obj j) :=
  show Semiringₓ (F.obj j) by
    infer_instance

variable [is_filtered J]

/-- The colimit of `F ⋙ forget₂ SemiRing Mon` in the category `Mon`.
In the following, we will show that this has the structure of a semiring.
-/
abbrev R : Mon :=
  Mon.FilteredColimits.colimit (F ⋙ forget₂ SemiRing Mon)

instance colimit_semiring : Semiringₓ R :=
  { R.monoid, AddCommMon.FilteredColimits.colimitAddCommMonoid (F ⋙ forget₂ SemiRing AddCommMon) with
    mul_zero := fun x => by
      apply Quot.induction_on x
      clear x
      intro x
      cases' x with j x
      erw [colimit_zero_eq _ j, colimit_mul_mk_eq _ ⟨j, _⟩ ⟨j, _⟩ j (𝟙 j) (𝟙 j)]
      rw [CategoryTheory.Functor.map_id, id_apply, id_apply, mul_zero x]
      rfl,
    zero_mul := fun x => by
      apply Quot.induction_on x
      clear x
      intro x
      cases' x with j x
      erw [colimit_zero_eq _ j, colimit_mul_mk_eq _ ⟨j, _⟩ ⟨j, _⟩ j (𝟙 j) (𝟙 j)]
      rw [CategoryTheory.Functor.map_id, id_apply, id_apply, zero_mul x]
      rfl,
    left_distrib := fun x y z => by
      apply Quot.induction_on₃ x y z
      clear x y z
      intro x y z
      cases' x with j₁ x
      cases' y with j₂ y
      cases' z with j₃ z
      let k := max₃ j₁ j₂ j₃
      let f := first_to_max₃ j₁ j₂ j₃
      let g := second_to_max₃ j₁ j₂ j₃
      let h := third_to_max₃ j₁ j₂ j₃
      erw [colimit_add_mk_eq _ ⟨j₂, _⟩ ⟨j₃, _⟩ k g h, colimit_mul_mk_eq _ ⟨j₁, _⟩ ⟨k, _⟩ k f (𝟙 k),
        colimit_mul_mk_eq _ ⟨j₁, _⟩ ⟨j₂, _⟩ k f g, colimit_mul_mk_eq _ ⟨j₁, _⟩ ⟨j₃, _⟩ k f h,
        colimit_add_mk_eq _ ⟨k, _⟩ ⟨k, _⟩ k (𝟙 k) (𝟙 k)]
      simp only [CategoryTheory.Functor.map_id, id_apply]
      erw [left_distrib (F.map f x) (F.map g y) (F.map h z)]
      rfl,
    right_distrib := fun x y z => by
      apply Quot.induction_on₃ x y z
      clear x y z
      intro x y z
      cases' x with j₁ x
      cases' y with j₂ y
      cases' z with j₃ z
      let k := max₃ j₁ j₂ j₃
      let f := first_to_max₃ j₁ j₂ j₃
      let g := second_to_max₃ j₁ j₂ j₃
      let h := third_to_max₃ j₁ j₂ j₃
      erw [colimit_add_mk_eq _ ⟨j₁, _⟩ ⟨j₂, _⟩ k f g, colimit_mul_mk_eq _ ⟨k, _⟩ ⟨j₃, _⟩ k (𝟙 k) h,
        colimit_mul_mk_eq _ ⟨j₁, _⟩ ⟨j₃, _⟩ k f h, colimit_mul_mk_eq _ ⟨j₂, _⟩ ⟨j₃, _⟩ k g h,
        colimit_add_mk_eq _ ⟨k, _⟩ ⟨k, _⟩ k (𝟙 k) (𝟙 k)]
      simp only [CategoryTheory.Functor.map_id, id_apply]
      erw [right_distrib (F.map f x) (F.map g y) (F.map h z)]
      rfl }

/-- The bundled semiring giving the filtered colimit of a diagram. -/
def colimit : SemiRing :=
  SemiRing.of R

/-- The cocone over the proposed colimit semiring. -/
def colimit_cocone : cocone F where
  x := colimit
  ι :=
    { app := fun j =>
        { (Mon.FilteredColimits.colimitCocone (F ⋙ forget₂ SemiRing Mon)).ι.app j,
          (AddCommMon.FilteredColimits.colimitCocone (F ⋙ forget₂ SemiRing AddCommMon)).ι.app j with },
      naturality' := fun j j' f => RingHom.coe_inj ((types.colimit_cocone (F ⋙ forget SemiRing)).ι.naturality f) }

/-- The proposed colimit cocone is a colimit in `SemiRing`. -/
def colimit_cocone_is_colimit : is_colimit colimit_cocone where
  desc := fun t =>
    { (Mon.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ SemiRing Mon)).desc
        ((forget₂ SemiRing Mon).mapCocone t),
      (AddCommMon.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ SemiRing AddCommMon)).desc
        ((forget₂ SemiRing AddCommMon).mapCocone t) with }
  fac' := fun t j =>
    RingHom.coe_inj <| (types.colimit_cocone_is_colimit (F ⋙ forget SemiRing)).fac ((forget SemiRing).mapCocone t) j
  uniq' := fun t m h =>
    RingHom.coe_inj <|
      (types.colimit_cocone_is_colimit (F ⋙ forget SemiRing)).uniq ((forget SemiRing).mapCocone t) m fun j =>
        funext fun x => RingHom.congr_fun (h j) x

instance forget₂_Mon_preserves_filtered_colimits : preserves_filtered_colimits (forget₂ SemiRing Mon.{v}) where
  PreservesFilteredColimits := fun J _ _ =>
    { PreservesColimit := fun F =>
        preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
          (Mon.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ SemiRing Mon.{v})) }

instance forget_preserves_filtered_colimits : preserves_filtered_colimits (forget SemiRing) :=
  limits.comp_preserves_filtered_colimits (forget₂ SemiRing Mon) (forget Mon)

end

end SemiRing.FilteredColimits

namespace CommSemiRing.FilteredColimits

section

parameter {J : Type v}[small_category J][is_filtered J](F : J ⥤ CommSemiRing.{v})

/-- The colimit of `F ⋙ forget₂ CommSemiRing SemiRing` in the category `SemiRing`.
In the following, we will show that this has the structure of a _commutative_ semiring.
-/
abbrev R : SemiRing :=
  SemiRing.FilteredColimits.colimit (F ⋙ forget₂ CommSemiRing SemiRing)

instance colimit_comm_semiring : CommSemiringₓ R :=
  { R.semiring, CommMon.FilteredColimits.colimitCommMonoid (F ⋙ forget₂ CommSemiRing CommMon) with }

/-- The bundled commutative semiring giving the filtered colimit of a diagram. -/
def colimit : CommSemiRing :=
  CommSemiRing.of R

/-- The cocone over the proposed colimit commutative semiring. -/
def colimit_cocone : cocone F where
  x := colimit
  ι := { (SemiRing.FilteredColimits.colimitCocone (F ⋙ forget₂ CommSemiRing SemiRing)).ι with }

/-- The proposed colimit cocone is a colimit in `CommSemiRing`. -/
def colimit_cocone_is_colimit : is_colimit colimit_cocone where
  desc := fun t =>
    (SemiRing.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ CommSemiRing SemiRing)).desc
      ((forget₂ CommSemiRing SemiRing).mapCocone t)
  fac' := fun t j =>
    RingHom.coe_inj <|
      (types.colimit_cocone_is_colimit (F ⋙ forget CommSemiRing)).fac ((forget CommSemiRing).mapCocone t) j
  uniq' := fun t m h =>
    RingHom.coe_inj <|
      (types.colimit_cocone_is_colimit (F ⋙ forget CommSemiRing)).uniq ((forget CommSemiRing).mapCocone t) m fun j =>
        funext fun x => RingHom.congr_fun (h j) x

instance forget₂_SemiRing_preserves_filtered_colimits :
    preserves_filtered_colimits (forget₂ CommSemiRing SemiRing.{v}) where
  PreservesFilteredColimits := fun J _ _ =>
    { PreservesColimit := fun F =>
        preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
          (SemiRing.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ CommSemiRing SemiRing.{v})) }

instance forget_preserves_filtered_colimits : preserves_filtered_colimits (forget CommSemiRing) :=
  limits.comp_preserves_filtered_colimits (forget₂ CommSemiRing SemiRing) (forget SemiRing)

end

end CommSemiRing.FilteredColimits

namespace Ringₓₓ.FilteredColimits

section

parameter {J : Type v}[small_category J][is_filtered J](F : J ⥤ Ringₓₓ.{v})

/-- The colimit of `F ⋙ forget₂ Ring SemiRing` in the category `SemiRing`.
In the following, we will show that this has the structure of a ring.
-/
abbrev R : SemiRing :=
  SemiRing.FilteredColimits.colimit (F ⋙ forget₂ Ringₓₓ SemiRing)

instance colimit_ring : Ringₓ R :=
  { R.semiring, AddCommGroupₓₓ.FilteredColimits.colimitAddCommGroup (F ⋙ forget₂ Ringₓₓ AddCommGroupₓₓ) with }

/-- The bundled ring giving the filtered colimit of a diagram. -/
def colimit : Ringₓₓ :=
  Ringₓₓ.of R

/-- The cocone over the proposed colimit ring. -/
def colimit_cocone : cocone F where
  x := colimit
  ι := { (SemiRing.FilteredColimits.colimitCocone (F ⋙ forget₂ Ringₓₓ SemiRing)).ι with }

/-- The proposed colimit cocone is a colimit in `Ring`. -/
def colimit_cocone_is_colimit : is_colimit colimit_cocone where
  desc := fun t =>
    (SemiRing.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ Ringₓₓ SemiRing)).desc
      ((forget₂ Ringₓₓ SemiRing).mapCocone t)
  fac' := fun t j =>
    RingHom.coe_inj <| (types.colimit_cocone_is_colimit (F ⋙ forget Ringₓₓ)).fac ((forget Ringₓₓ).mapCocone t) j
  uniq' := fun t m h =>
    RingHom.coe_inj <|
      (types.colimit_cocone_is_colimit (F ⋙ forget Ringₓₓ)).uniq ((forget Ringₓₓ).mapCocone t) m fun j =>
        funext fun x => RingHom.congr_fun (h j) x

instance forget₂_SemiRing_preserves_filtered_colimits : preserves_filtered_colimits (forget₂ Ringₓₓ SemiRing.{v}) where
  PreservesFilteredColimits := fun J _ _ =>
    { PreservesColimit := fun F =>
        preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
          (SemiRing.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ Ringₓₓ SemiRing.{v})) }

instance forget_preserves_filtered_colimits : preserves_filtered_colimits (forget Ringₓₓ) :=
  limits.comp_preserves_filtered_colimits (forget₂ Ringₓₓ SemiRing) (forget SemiRing)

end

end Ringₓₓ.FilteredColimits

namespace CommRingₓₓ.FilteredColimits

section

parameter {J : Type v}[small_category J][is_filtered J](F : J ⥤ CommRingₓₓ.{v})

/-- The colimit of `F ⋙ forget₂ CommRing Ring` in the category `Ring`.
In the following, we will show that this has the structure of a _commutative_ ring.
-/
abbrev R : Ringₓₓ :=
  Ringₓₓ.FilteredColimits.colimit (F ⋙ forget₂ CommRingₓₓ Ringₓₓ)

instance colimit_comm_ring : CommRingₓ R :=
  { R.ring, CommSemiRing.FilteredColimits.colimitCommSemiring (F ⋙ forget₂ CommRingₓₓ CommSemiRing) with }

/-- The bundled commutative ring giving the filtered colimit of a diagram. -/
def colimit : CommRingₓₓ :=
  CommRingₓₓ.of R

/-- The cocone over the proposed colimit commutative ring. -/
def colimit_cocone : cocone F where
  x := colimit
  ι := { (Ringₓₓ.FilteredColimits.colimitCocone (F ⋙ forget₂ CommRingₓₓ Ringₓₓ)).ι with }

/-- The proposed colimit cocone is a colimit in `CommRing`. -/
def colimit_cocone_is_colimit : is_colimit colimit_cocone where
  desc := fun t =>
    (Ringₓₓ.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ CommRingₓₓ Ringₓₓ)).desc
      ((forget₂ CommRingₓₓ Ringₓₓ).mapCocone t)
  fac' := fun t j =>
    RingHom.coe_inj <| (types.colimit_cocone_is_colimit (F ⋙ forget CommRingₓₓ)).fac ((forget CommRingₓₓ).mapCocone t) j
  uniq' := fun t m h =>
    RingHom.coe_inj <|
      (types.colimit_cocone_is_colimit (F ⋙ forget CommRingₓₓ)).uniq ((forget CommRingₓₓ).mapCocone t) m fun j =>
        funext fun x => RingHom.congr_fun (h j) x

instance forget₂_Ring_preserves_filtered_colimits : preserves_filtered_colimits (forget₂ CommRingₓₓ Ringₓₓ.{v}) where
  PreservesFilteredColimits := fun J _ _ =>
    { PreservesColimit := fun F =>
        preserves_colimit_of_preserves_colimit_cocone (colimit_cocone_is_colimit F)
          (Ringₓₓ.FilteredColimits.colimitCoconeIsColimit (F ⋙ forget₂ CommRingₓₓ Ringₓₓ.{v})) }

instance forget_preserves_filtered_colimits : preserves_filtered_colimits (forget CommRingₓₓ) :=
  limits.comp_preserves_filtered_colimits (forget₂ CommRingₓₓ Ringₓₓ) (forget Ringₓₓ)

end

end CommRingₓₓ.FilteredColimits

