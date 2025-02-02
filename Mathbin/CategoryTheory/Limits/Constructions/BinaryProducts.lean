/-
Copyright (c) 2020 Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta, Andrew Yang
-/
import Mathbin.CategoryTheory.Limits.Shapes.Terminal
import Mathbin.CategoryTheory.Limits.Shapes.Pullbacks
import Mathbin.CategoryTheory.Limits.Shapes.BinaryProducts
import Mathbin.CategoryTheory.Limits.Preserves.Shapes.Pullbacks
import Mathbin.CategoryTheory.Limits.Preserves.Shapes.Terminal

/-!
# Constructing binary product from pullbacks and terminal object.

The product is the pullback over the terminal objects. In particular, if a category
has pullbacks and a terminal object, then it has binary products.

We also provide the dual.
-/


universe v v' u u'

open CategoryTheory CategoryTheory.Category CategoryTheory.Limits

variable {C : Type u} [Category.{v} C] {D : Type u'} [Category.{v'} D] (F : C ⥤ D)

/-- If a span is the pullback span over the terminal object, then it is a binary product. -/
def isBinaryProductOfIsTerminalIsPullback (F : Discrete WalkingPair ⥤ C) (c : Cone F) {X : C} (hX : IsTerminal X)
    (f : F.obj ⟨WalkingPair.left⟩ ⟶ X) (g : F.obj ⟨WalkingPair.right⟩ ⟶ X)
    (hc :
      IsLimit
        (PullbackCone.mk (c.π.app ⟨WalkingPair.left⟩) (c.π.app ⟨WalkingPair.right⟩ : _) <|
          hX.hom_ext (_ ≫ f) (_ ≫ g))) :
    IsLimit c where
  lift := fun s => hc.lift (PullbackCone.mk (s.π.app ⟨WalkingPair.left⟩) (s.π.app ⟨WalkingPair.right⟩) (hX.hom_ext _ _))
  fac' := fun s j =>
    Discrete.casesOn j fun j => WalkingPair.casesOn j (hc.fac _ WalkingCospan.left) (hc.fac _ WalkingCospan.right)
  uniq' := fun s m J => by
    let c' :=
      pullback_cone.mk (m ≫ c.π.app ⟨walking_pair.left⟩) (m ≫ c.π.app ⟨walking_pair.right⟩ : _)
        (hX.hom_ext (_ ≫ f) (_ ≫ g))
    rw [← J, ← J]
    apply hc.hom_ext
    rintro (_ | (_ | _)) <;> simp only [pullback_cone.mk_π_app_one, pullback_cone.mk_π_app]
    exacts[(category.assoc _ _ _).symm.trans (hc.fac_assoc c' walking_cospan.left f).symm,
      (hc.fac c' walking_cospan.left).symm, (hc.fac c' walking_cospan.right).symm]

/-- The pullback over the terminal object is the product -/
def isProductOfIsTerminalIsPullback {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (h : W ⟶ X) (k : W ⟶ Y) (H₁ : IsTerminal Z)
    (H₂ : IsLimit (PullbackCone.mk _ _ (show h ≫ f = k ≫ g from H₁.hom_ext _ _))) : IsLimit (BinaryFan.mk h k) := by
  apply isBinaryProductOfIsTerminalIsPullback _ _ H₁
  exact H₂

/-- The product is the pullback over the terminal object. -/
def isPullbackOfIsTerminalIsProduct {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (h : W ⟶ X) (k : W ⟶ Y) (H₁ : IsTerminal Z)
    (H₂ : IsLimit (BinaryFan.mk h k)) : IsLimit (PullbackCone.mk _ _ (show h ≫ f = k ≫ g from H₁.hom_ext _ _)) := by
  apply pullback_cone.is_limit_aux'
  intro s
  use H₂.lift (binary_fan.mk s.fst s.snd)
  use H₂.fac (binary_fan.mk s.fst s.snd) ⟨walking_pair.left⟩
  use H₂.fac (binary_fan.mk s.fst s.snd) ⟨walking_pair.right⟩
  intro m h₁ h₂
  apply H₂.hom_ext
  rintro ⟨⟨⟩⟩
  · exact h₁.trans (H₂.fac (binary_fan.mk s.fst s.snd) ⟨walking_pair.left⟩).symm
    
  · exact h₂.trans (H₂.fac (binary_fan.mk s.fst s.snd) ⟨walking_pair.right⟩).symm
    

/-- Any category with pullbacks and a terminal object has a limit cone for each walking pair. -/
noncomputable def limitConeOfTerminalAndPullbacks [HasTerminal C] [HasPullbacks C] (F : Discrete WalkingPair ⥤ C) :
    LimitCone F where
  Cone :=
    { x := pullback (terminal.from (F.obj ⟨WalkingPair.left⟩)) (terminal.from (F.obj ⟨WalkingPair.right⟩)),
      π := Discrete.natTrans fun x => Discrete.casesOn x fun x => WalkingPair.casesOn x pullback.fst pullback.snd }
  IsLimit := isBinaryProductOfIsTerminalIsPullback F _ terminalIsTerminal _ _ (pullbackIsPullback _ _)

variable (C)

-- This is not an instance, as it is not always how one wants to construct binary products!
/-- Any category with pullbacks and terminal object has binary products. -/
theorem has_binary_products_of_has_terminal_and_pullbacks [HasTerminal C] [HasPullbacks C] : HasBinaryProducts C :=
  { HasLimit := fun F => HasLimit.mk (limitConeOfTerminalAndPullbacks F) }

variable {C}

/-- A functor that preserves terminal objects and pullbacks preserves binary products. -/
noncomputable def preservesBinaryProductsOfPreservesTerminalAndPullbacks [HasTerminal C] [HasPullbacks C]
    [PreservesLimitsOfShape (Discrete.{0} Pempty) F] [PreservesLimitsOfShape WalkingCospan F] :
    PreservesLimitsOfShape (Discrete WalkingPair) F :=
  ⟨fun K =>
    preservesLimitOfPreservesLimitCone (limitConeOfTerminalAndPullbacks K).2
      (by
        apply isBinaryProductOfIsTerminalIsPullback _ _ (is_limit_of_has_terminal_of_preserves_limit F)
        apply is_limit_of_has_pullback_of_preserves_limit)⟩

/-- In a category with a terminal object and pullbacks,
a product of objects `X` and `Y` is isomorphic to a pullback. -/
noncomputable def prodIsoPullback [HasTerminal C] [HasPullbacks C] (X Y : C) [HasBinaryProduct X Y] :
    X ⨯ Y ≅ pullback (terminal.from X) (terminal.from Y) :=
  limit.isoLimitCone (limitConeOfTerminalAndPullbacks _)

/-- If a cospan is the pushout cospan under the initial object, then it is a binary coproduct. -/
def isBinaryCoproductOfIsInitialIsPushout (F : Discrete WalkingPair ⥤ C) (c : Cocone F) {X : C} (hX : IsInitial X)
    (f : X ⟶ F.obj ⟨WalkingPair.left⟩) (g : X ⟶ F.obj ⟨WalkingPair.right⟩)
    (hc :
      IsColimit
        (PushoutCocone.mk (c.ι.app ⟨WalkingPair.left⟩) (c.ι.app ⟨WalkingPair.right⟩ : _) <|
          hX.hom_ext (f ≫ _) (g ≫ _))) :
    IsColimit c where
  desc := fun s =>
    hc.desc (PushoutCocone.mk (s.ι.app ⟨WalkingPair.left⟩) (s.ι.app ⟨WalkingPair.right⟩) (hX.hom_ext _ _))
  fac' := fun s j =>
    Discrete.casesOn j fun j => WalkingPair.casesOn j (hc.fac _ WalkingSpan.left) (hc.fac _ WalkingSpan.right)
  uniq' := fun s m J => by
    let c' :=
      pushout_cocone.mk (c.ι.app ⟨walking_pair.left⟩ ≫ m) (c.ι.app ⟨walking_pair.right⟩ ≫ m)
        (hX.hom_ext (f ≫ _) (g ≫ _))
    rw [← J, ← J]
    apply hc.hom_ext
    rintro (_ | (_ | _)) <;> simp only [pushout_cocone.mk_ι_app_zero, pushout_cocone.mk_ι_app, category.assoc]
    congr 1
    exacts[(hc.fac c' walking_span.left).symm, (hc.fac c' walking_span.left).symm, (hc.fac c' walking_span.right).symm]

/-- The pushout under the initial object is the coproduct -/
def isCoproductOfIsInitialIsPushout {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (h : W ⟶ X) (k : W ⟶ Y) (H₁ : IsInitial W)
    (H₂ : IsColimit (PushoutCocone.mk _ _ (show h ≫ f = k ≫ g from H₁.hom_ext _ _))) : IsColimit (BinaryCofan.mk f g) :=
  by
  apply isBinaryCoproductOfIsInitialIsPushout _ _ H₁
  exact H₂

/-- The coproduct is the pushout under the initial object. -/
def isPushoutOfIsInitialIsCoproduct {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (h : W ⟶ X) (k : W ⟶ Y) (H₁ : IsInitial W)
    (H₂ : IsColimit (BinaryCofan.mk f g)) : IsColimit (PushoutCocone.mk _ _ (show h ≫ f = k ≫ g from H₁.hom_ext _ _)) :=
  by
  apply pushout_cocone.is_colimit_aux'
  intro s
  use H₂.desc (binary_cofan.mk s.inl s.inr)
  use H₂.fac (binary_cofan.mk s.inl s.inr) ⟨walking_pair.left⟩
  use H₂.fac (binary_cofan.mk s.inl s.inr) ⟨walking_pair.right⟩
  intro m h₁ h₂
  apply H₂.hom_ext
  rintro ⟨⟨⟩⟩
  · exact h₁.trans (H₂.fac (binary_cofan.mk s.inl s.inr) ⟨walking_pair.left⟩).symm
    
  · exact h₂.trans (H₂.fac (binary_cofan.mk s.inl s.inr) ⟨walking_pair.right⟩).symm
    

/-- Any category with pushouts and an initial object has a colimit cocone for each walking pair. -/
noncomputable def colimitCoconeOfInitialAndPushouts [HasInitial C] [HasPushouts C] (F : Discrete WalkingPair ⥤ C) :
    ColimitCocone F where
  Cocone :=
    { x := pushout (initial.to (F.obj ⟨WalkingPair.left⟩)) (initial.to (F.obj ⟨WalkingPair.right⟩)),
      ι := Discrete.natTrans fun x => Discrete.casesOn x fun x => WalkingPair.casesOn x pushout.inl pushout.inr }
  IsColimit := isBinaryCoproductOfIsInitialIsPushout F _ initialIsInitial _ _ (pushoutIsPushout _ _)

variable (C)

-- This is not an instance, as it is not always how one wants to construct binary coproducts!
/-- Any category with pushouts and initial object has binary coproducts. -/
theorem has_binary_coproducts_of_has_initial_and_pushouts [HasInitial C] [HasPushouts C] : HasBinaryCoproducts C :=
  { HasColimit := fun F => HasColimit.mk (colimitCoconeOfInitialAndPushouts F) }

variable {C}

/-- A functor that preserves initial objects and pushouts preserves binary coproducts. -/
noncomputable def preservesBinaryCoproductsOfPreservesInitialAndPushouts [HasInitial C] [HasPushouts C]
    [PreservesColimitsOfShape (Discrete.{0} Pempty) F] [PreservesColimitsOfShape WalkingSpan F] :
    PreservesColimitsOfShape (Discrete WalkingPair) F :=
  ⟨fun K =>
    preservesColimitOfPreservesColimitCocone (colimitCoconeOfInitialAndPushouts K).2
      (by
        apply isBinaryCoproductOfIsInitialIsPushout _ _ (is_colimit_of_has_initial_of_preserves_colimit F)
        apply is_colimit_of_has_pushout_of_preserves_colimit)⟩

/-- In a category with an initial object and pushouts,
a coproduct of objects `X` and `Y` is isomorphic to a pushout. -/
noncomputable def coprodIsoPushout [HasInitial C] [HasPushouts C] (X Y : C) [HasBinaryCoproduct X Y] :
    X ⨿ Y ≅ pushout (initial.to X) (initial.to Y) :=
  colimit.isoColimitCocone (colimitCoconeOfInitialAndPushouts _)

