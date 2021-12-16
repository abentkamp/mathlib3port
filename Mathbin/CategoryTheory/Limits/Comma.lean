import Mathbin.CategoryTheory.Limits.Creates 
import Mathbin.CategoryTheory.Limits.Punit 
import Mathbin.CategoryTheory.Limits.Preserves.Basic 
import Mathbin.CategoryTheory.StructuredArrow 
import Mathbin.CategoryTheory.Arrow

/-!
# Limits and colimits in comma categories

We build limits in the comma category `comma L R` provided that the two source categories have
limits and `R` preserves them.
This is used to construct limits in the arrow category, structured arrow category and under
category, and show that the appropriate forgetful functors create limits.

The duals of all the above are also given.
-/


namespace CategoryTheory

open Category Limits

universe v u₁ u₂ u₃

variable {J : Type v} [small_category J]

variable {A : Type u₁} [category.{v} A]

variable {B : Type u₂} [category.{v} B]

variable {T : Type u₃} [category.{v} T]

namespace Comma

variable {L : A ⥤ T} {R : B ⥤ T}

variable (F : J ⥤ comma L R)

/-- (Implementation). An auxiliary cone which is useful in order to construct limits
in the comma category. -/
@[simps]
def limit_auxiliary_cone (c₁ : cone (F ⋙ fst L R)) : cone ((F ⋙ snd L R) ⋙ R) :=
  (cones.postcompose (whisker_left F (comma.nat_trans L R) : _)).obj (L.map_cone c₁)

/--
If `R` preserves the appropriate limit, then given a cone for `F ⋙ fst L R : J ⥤ L` and a
limit cone for `F ⋙ snd L R : J ⥤ R` we can build a cone for `F` which will turn out to be a limit
cone.
-/
@[simps]
def cone_of_preserves [preserves_limit (F ⋙ snd L R) R] (c₁ : cone (F ⋙ fst L R)) {c₂ : cone (F ⋙ snd L R)}
  (t₂ : is_limit c₂) : cone F :=
  { x := { left := c₁.X, right := c₂.X, Hom := (is_limit_of_preserves R t₂).lift (limit_auxiliary_cone _ c₁) },
    π :=
      { app :=
          fun j =>
            { left := c₁.π.app j, right := c₂.π.app j,
              w' := ((is_limit_of_preserves R t₂).fac (limit_auxiliary_cone F c₁) j).symm },
        naturality' :=
          fun j₁ j₂ t =>
            by 
              ext <;> dsimp <;> simp [←c₁.w t, ←c₂.w t] } }

/-- Provided that `R` preserves the appropriate limit, then the cone in `cone_of_preserves` is a
limit. -/
def cone_of_preserves_is_limit [preserves_limit (F ⋙ snd L R) R] {c₁ : cone (F ⋙ fst L R)} (t₁ : is_limit c₁)
  {c₂ : cone (F ⋙ snd L R)} (t₂ : is_limit c₂) : is_limit (cone_of_preserves F c₁ t₂) :=
  { lift :=
      fun s =>
        { left := t₁.lift ((fst L R).mapCone s), right := t₂.lift ((snd L R).mapCone s),
          w' :=
            (is_limit_of_preserves R t₂).hom_ext$
              fun j =>
                by 
                  rw [cone_of_preserves_X_hom, assoc, assoc, (is_limit_of_preserves R t₂).fac,
                    limit_auxiliary_cone_π_app, ←L.map_comp_assoc, t₁.fac, R.map_cone_π_app, ←R.map_comp, t₂.fac]
                  exact (s.π.app j).w },
    uniq' :=
      fun s m w =>
        comma_morphism.ext _ _
          (t₁.uniq ((fst L R).mapCone s) _
            fun j =>
              by 
                simp [←w])
          (t₂.uniq ((snd L R).mapCone s) _
            fun j =>
              by 
                simp [←w]) }

/-- (Implementation). An auxiliary cocone which is useful in order to construct colimits
in the comma category. -/
@[simps]
def colimit_auxiliary_cocone (c₂ : cocone (F ⋙ snd L R)) : cocone ((F ⋙ fst L R) ⋙ L) :=
  (cocones.precompose (whisker_left F (comma.nat_trans L R) : _)).obj (R.map_cocone c₂)

/--
If `L` preserves the appropriate colimit, then given a colimit cocone for `F ⋙ fst L R : J ⥤ L` and
a cocone for `F ⋙ snd L R : J ⥤ R` we can build a cocone for `F` which will turn out to be a
colimit cocone.
-/
@[simps]
def cocone_of_preserves [preserves_colimit (F ⋙ fst L R) L] {c₁ : cocone (F ⋙ fst L R)} (t₁ : is_colimit c₁)
  (c₂ : cocone (F ⋙ snd L R)) : cocone F :=
  { x := { left := c₁.X, right := c₂.X, Hom := (is_colimit_of_preserves L t₁).desc (colimit_auxiliary_cocone _ c₂) },
    ι :=
      { app :=
          fun j =>
            { left := c₁.ι.app j, right := c₂.ι.app j,
              w' := (is_colimit_of_preserves L t₁).fac (colimit_auxiliary_cocone _ c₂) j },
        naturality' :=
          fun j₁ j₂ t =>
            by 
              ext <;> dsimp <;> simp [←c₁.w t, ←c₂.w t] } }

/-- Provided that `L` preserves the appropriate colimit, then the cocone in `cocone_of_preserves` is
a colimit. -/
def cocone_of_preserves_is_colimit [preserves_colimit (F ⋙ fst L R) L] {c₁ : cocone (F ⋙ fst L R)} (t₁ : is_colimit c₁)
  {c₂ : cocone (F ⋙ snd L R)} (t₂ : is_colimit c₂) : is_colimit (cocone_of_preserves F t₁ c₂) :=
  { desc :=
      fun s =>
        { left := t₁.desc ((fst L R).mapCocone s), right := t₂.desc ((snd L R).mapCocone s),
          w' :=
            (is_colimit_of_preserves L t₁).hom_ext$
              fun j =>
                by 
                  rw [cocone_of_preserves_X_hom, (is_colimit_of_preserves L t₁).fac_assoc,
                    colimit_auxiliary_cocone_ι_app, assoc, ←R.map_comp, t₂.fac, L.map_cocone_ι_app, ←L.map_comp_assoc,
                    t₁.fac]
                  exact (s.ι.app j).w },
    uniq' :=
      fun s m w =>
        comma_morphism.ext _ _
          (t₁.uniq ((fst L R).mapCocone s) _
            (by 
              simp [←w]))
          (t₂.uniq ((snd L R).mapCocone s) _
            (by 
              simp [←w])) }

instance has_limit (F : J ⥤ comma L R) [has_limit (F ⋙ fst L R)] [has_limit (F ⋙ snd L R)]
  [preserves_limit (F ⋙ snd L R) R] : has_limit F :=
  has_limit.mk ⟨_, cone_of_preserves_is_limit _ (limit.is_limit _) (limit.is_limit _)⟩

instance has_limits_of_shape [has_limits_of_shape J A] [has_limits_of_shape J B] [preserves_limits_of_shape J R] :
  has_limits_of_shape J (comma L R) :=
  {  }

instance has_limits [has_limits A] [has_limits B] [preserves_limits R] : has_limits (comma L R) :=
  ⟨inferInstance⟩

instance has_colimit (F : J ⥤ comma L R) [has_colimit (F ⋙ fst L R)] [has_colimit (F ⋙ snd L R)]
  [preserves_colimit (F ⋙ fst L R) L] : has_colimit F :=
  has_colimit.mk ⟨_, cocone_of_preserves_is_colimit _ (colimit.is_colimit _) (colimit.is_colimit _)⟩

instance has_colimits_of_shape [has_colimits_of_shape J A] [has_colimits_of_shape J B]
  [preserves_colimits_of_shape J L] : has_colimits_of_shape J (comma L R) :=
  {  }

instance has_colimits [has_colimits A] [has_colimits B] [preserves_colimits L] : has_colimits (comma L R) :=
  ⟨inferInstance⟩

end Comma

namespace Arrow

instance has_limit (F : J ⥤ arrow T) [i₁ : has_limit (F ⋙ left_func)] [i₂ : has_limit (F ⋙ right_func)] : has_limit F :=
  @comma.has_limit _ _ _ _ _ i₁ i₂ _

instance has_limits_of_shape [has_limits_of_shape J T] : has_limits_of_shape J (arrow T) :=
  {  }

instance has_limits [has_limits T] : has_limits (arrow T) :=
  ⟨inferInstance⟩

instance has_colimit (F : J ⥤ arrow T) [i₁ : has_colimit (F ⋙ left_func)] [i₂ : has_colimit (F ⋙ right_func)] :
  has_colimit F :=
  @comma.has_colimit _ _ _ _ _ i₁ i₂ _

instance has_colimits_of_shape [has_colimits_of_shape J T] : has_colimits_of_shape J (arrow T) :=
  {  }

instance has_colimits [has_colimits T] : has_colimits (arrow T) :=
  ⟨inferInstance⟩

end Arrow

namespace StructuredArrow

variable {X : T} {G : A ⥤ T} (F : J ⥤ structured_arrow X G)

instance has_limit [i₁ : has_limit (F ⋙ proj X G)] [i₂ : preserves_limit (F ⋙ proj X G) G] : has_limit F :=
  @comma.has_limit _ _ _ _ _ _ i₁ i₂

instance has_limits_of_shape [has_limits_of_shape J A] [preserves_limits_of_shape J G] :
  has_limits_of_shape J (structured_arrow X G) :=
  {  }

instance has_limits [has_limits A] [preserves_limits G] : has_limits (structured_arrow X G) :=
  ⟨inferInstance⟩

noncomputable instance creates_limit [i : preserves_limit (F ⋙ proj X G) G] : creates_limit F (proj X G) :=
  creates_limit_of_reflects_iso$
    fun c t =>
      { liftedCone := @comma.cone_of_preserves _ _ _ _ _ i punit_cone t,
        makesLimit := comma.cone_of_preserves_is_limit _ punit_cone_is_limit _,
        validLift := cones.ext (iso.refl _)$ fun j => (id_comp _).symm }

noncomputable instance creates_limits_of_shape [preserves_limits_of_shape J G] : creates_limits_of_shape J (proj X G) :=
  {  }

noncomputable instance creates_limits [preserves_limits G] : creates_limits (proj X G : _) :=
  ⟨⟩

end StructuredArrow

namespace CostructuredArrow

variable {G : A ⥤ T} {X : T} (F : J ⥤ costructured_arrow G X)

instance has_colimit [i₁ : has_colimit (F ⋙ proj G X)] [i₂ : preserves_colimit (F ⋙ proj G X) G] : has_colimit F :=
  @comma.has_colimit _ _ _ _ _ i₁ _ i₂

instance has_colimits_of_shape [has_colimits_of_shape J A] [preserves_colimits_of_shape J G] :
  has_colimits_of_shape J (costructured_arrow G X) :=
  {  }

instance has_colimits [has_colimits A] [preserves_colimits G] : has_colimits (costructured_arrow G X) :=
  ⟨inferInstance⟩

noncomputable instance creates_colimit [i : preserves_colimit (F ⋙ proj G X) G] : creates_colimit F (proj G X) :=
  creates_colimit_of_reflects_iso$
    fun c t =>
      { liftedCocone := @comma.cocone_of_preserves _ _ _ _ _ i t punit_cocone,
        makesColimit := comma.cocone_of_preserves_is_colimit _ _ punit_cocone_is_colimit,
        validLift := cocones.ext (iso.refl _)$ fun j => comp_id _ }

noncomputable instance creates_colimits_of_shape [preserves_colimits_of_shape J G] :
  creates_colimits_of_shape J (proj G X) :=
  {  }

noncomputable instance creates_colimits [preserves_colimits G] : creates_colimits (proj G X : _) :=
  ⟨⟩

end CostructuredArrow

end CategoryTheory

