import Mathbin.AlgebraicGeometry.PresheafedSpace 
import Mathbin.CategoryTheory.Limits.Final 
import Mathbin.Topology.Sheaves.Stalks

/-!
# Stalks for presheaved spaces

This file lifts constructions of stalks and pushforwards of stalks to work with
the category of presheafed spaces. Additionally, we prove that restriction of
presheafed spaces does not change the stalks.
-/


noncomputable theory

universe v u v' u'

open CategoryTheory

open CategoryTheory.Limits CategoryTheory.Category CategoryTheory.Functor

open AlgebraicGeometry

open TopologicalSpace

open Opposite

variable{C : Type u}[category.{v} C][has_colimits C]

attribute [local tidy] tactic.op_induction'

open Top.Presheaf

namespace AlgebraicGeometry.PresheafedSpace

/--
The stalk at `x` of a `PresheafedSpace`.
-/
def stalk (X : PresheafedSpace C) (x : X) : C :=
  X.presheaf.stalk x

/--
A morphism of presheafed spaces induces a morphism of stalks.
-/
def stalk_map {X Y : PresheafedSpace C} (α : X ⟶ Y) (x : X) : Y.stalk (α.base x) ⟶ X.stalk x :=
  (stalk_functor C (α.base x)).map α.c ≫ X.presheaf.stalk_pushforward C α.base x

@[simp, elementwise, reassoc]
theorem stalk_map_germ {X Y : PresheafedSpace C} (α : X ⟶ Y) (U : opens Y.carrier) (x : (opens.map α.base).obj U) :
  Y.presheaf.germ ⟨α.base x, x.2⟩ ≫ stalk_map α («expr↑ » x) = α.c.app (op U) ≫ X.presheaf.germ x :=
  by 
    rw [stalk_map, stalk_functor_map_germ_assoc, stalk_pushforward_germ]

section Restrict

-- error in AlgebraicGeometry.Stalks: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/--
For an open embedding `f : U ⟶ X` and a point `x : U`, we get an isomorphism between the stalk
of `X` at `f x` and the stalk of the restriction of `X` along `f` at t `x`.
-/
def restrict_stalk_iso
{U : Top}
(X : PresheafedSpace C)
{f : «expr ⟶ »(U, (X : Top.{v}))}
(h : open_embedding f)
(x : U) : «expr ≅ »((X.restrict h).stalk x, X.stalk (f x)) :=
begin
  haveI [] [] [":=", expr initial_of_adjunction (h.is_open_map.adjunction_nhds x)],
  exact [expr final.colimit_iso (h.is_open_map.functor_nhds x).op «expr ⋙ »((open_nhds.inclusion (f x)).op, X.presheaf)]
end

@[simp, elementwise, reassoc]
theorem restrict_stalk_iso_hom_eq_germ {U : Top} (X : PresheafedSpace C) {f : U ⟶ (X : Top.{v})} (h : OpenEmbedding f)
  (V : opens U) (x : U) (hx : x ∈ V) :
  (X.restrict h).Presheaf.germ ⟨x, hx⟩ ≫ (restrict_stalk_iso X h x).Hom =
    X.presheaf.germ ⟨f x, show f x ∈ h.is_open_map.functor.obj V from ⟨x, hx, rfl⟩⟩ :=
  colimit.ι_pre ((open_nhds.inclusion (f x)).op ⋙ X.presheaf) (h.is_open_map.functor_nhds x).op (op ⟨V, hx⟩)

@[simp, elementwise, reassoc]
theorem restrict_stalk_iso_inv_eq_germ {U : Top} (X : PresheafedSpace C) {f : U ⟶ (X : Top.{v})} (h : OpenEmbedding f)
  (V : opens U) (x : U) (hx : x ∈ V) :
  X.presheaf.germ ⟨f x, show f x ∈ h.is_open_map.functor.obj V from ⟨x, hx, rfl⟩⟩ ≫ (restrict_stalk_iso X h x).inv =
    (X.restrict h).Presheaf.germ ⟨x, hx⟩ :=
  by 
    rw [←restrict_stalk_iso_hom_eq_germ, category.assoc, iso.hom_inv_id, category.comp_id]

end Restrict

namespace StalkMap

@[simp]
theorem id (X : PresheafedSpace C) (x : X) : stalk_map (𝟙 X) x = 𝟙 (X.stalk x) :=
  by 
    dsimp [stalk_map]
    simp only [stalk_pushforward.id]
    rw [←map_comp]
    convert (stalk_functor C x).map_id X.presheaf 
    tidy

@[simp]
theorem comp {X Y Z : PresheafedSpace C} (α : X ⟶ Y) (β : Y ⟶ Z) (x : X) :
  stalk_map (α ≫ β) x =
    (stalk_map β (α.base x) : Z.stalk (β.base (α.base x)) ⟶ Y.stalk (α.base x)) ≫
      (stalk_map α x : Y.stalk (α.base x) ⟶ X.stalk x) :=
  by 
    dsimp [stalk_map, stalk_functor, stalk_pushforward]
    ext U 
    induction U using Opposite.rec 
    cases U 
    simp only [colimit.ι_map_assoc, colimit.ι_pre_assoc, colimit.ι_pre, whisker_left_app, whisker_right_app, assoc,
      id_comp, map_id, map_comp]
    dsimp 
    simp only [map_id, assoc, pushforward.comp_inv_app]
    erw [CategoryTheory.Functor.map_id]
    erw [CategoryTheory.Functor.map_id]
    erw [id_comp, id_comp]

/--
If `α = β` and `x = x'`, we would like to say that `stalk_map α x = stalk_map β x'`.
Unfortunately, this equality is not well-formed, as their types are not _definitionally_ the same.
To get a proper congruence lemma, we therefore have to introduce these `eq_to_hom` arrows on
either side of the equality.
-/
theorem congr {X Y : PresheafedSpace C} (α β : X ⟶ Y) (h₁ : α = β) (x x' : X) (h₂ : x = x') :
  stalk_map α x ≫
      eq_to_hom
        (show X.stalk x = X.stalk x' by 
          rw [h₂]) =
    eq_to_hom
        (show Y.stalk (α.base x) = Y.stalk (β.base x')by 
          rw [h₁, h₂]) ≫
      stalk_map β x' :=
  stalk_hom_ext _$
    fun U hx =>
      by 
        subst h₁ 
        subst h₂ 
        simp 

theorem congr_hom {X Y : PresheafedSpace C} (α β : X ⟶ Y) (h : α = β) (x : X) :
  stalk_map α x =
    eq_to_hom
        (show Y.stalk (α.base x) = Y.stalk (β.base x)by 
          rw [h]) ≫
      stalk_map β x :=
  by 
    rw [←stalk_map.congr α β h x x rfl, eq_to_hom_refl, category.comp_id]

theorem congr_point {X Y : PresheafedSpace C} (α : X ⟶ Y) (x x' : X) (h : x = x') :
  stalk_map α x ≫
      eq_to_hom
        (show X.stalk x = X.stalk x' by 
          rw [h]) =
    eq_to_hom
        (show Y.stalk (α.base x) = Y.stalk (α.base x')by 
          rw [h]) ≫
      stalk_map α x' :=
  by 
    rw [stalk_map.congr α α rfl x x' h]

-- error in AlgebraicGeometry.Stalks: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
instance is_iso {X Y : PresheafedSpace C} (α : «expr ⟶ »(X, Y)) [is_iso α] (x : X) : is_iso (stalk_map α x) :=
{ out := begin
    let [ident β] [":", expr «expr ⟶ »(Y, X)] [":=", expr category_theory.inv α],
    have [ident h_eq] [":", expr «expr = »(«expr ≫ »(α, β).base x, x)] [],
    { rw ["[", expr is_iso.hom_inv_id α, ",", expr id_base, ",", expr Top.id_app, "]"] [] },
    refine [expr ⟨«expr ≫ »(eq_to_hom (show «expr = »(X.stalk x, X.stalk («expr ≫ »(α, β).base x)), by rw [expr h_eq] []), (stalk_map β (α.base x) : _)), _, _⟩],
    { rw ["[", "<-", expr category.assoc, ",", expr congr_point α x («expr ≫ »(α, β).base x) h_eq.symm, ",", expr category.assoc, "]"] [],
      erw ["<-", expr stalk_map.comp β α (α.base x)] [],
      rw ["[", expr congr_hom _ _ (is_iso.inv_hom_id α), ",", expr stalk_map.id, ",", expr eq_to_hom_trans_assoc, ",", expr eq_to_hom_refl, ",", expr category.id_comp, "]"] [] },
    { rw ["[", expr category.assoc, ",", "<-", expr stalk_map.comp, ",", expr congr_hom _ _ (is_iso.hom_inv_id α), ",", expr stalk_map.id, ",", expr eq_to_hom_trans_assoc, ",", expr eq_to_hom_refl, ",", expr category.id_comp, "]"] [] }
  end }

/--
An isomorphism between presheafed spaces induces an isomorphism of stalks.
-/
def stalk_iso {X Y : PresheafedSpace C} (α : X ≅ Y) (x : X) : Y.stalk (α.hom.base x) ≅ X.stalk x :=
  as_iso (stalk_map α.hom x)

end StalkMap

end AlgebraicGeometry.PresheafedSpace

