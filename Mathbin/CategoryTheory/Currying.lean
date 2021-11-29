import Mathbin.CategoryTheory.Products.Bifunctor

/-!
# Curry and uncurry, as functors.

We define `curry : ((C × D) ⥤ E) ⥤ (C ⥤ (D ⥤ E))` and `uncurry : (C ⥤ (D ⥤ E)) ⥤ ((C × D) ⥤ E)`,
and verify that they provide an equivalence of categories
`currying : (C ⥤ (D ⥤ E)) ≌ ((C × D) ⥤ E)`.

-/


namespace CategoryTheory

universe v₁ v₂ v₃ u₁ u₂ u₃

variable {C : Type u₁} [category.{v₁} C] {D : Type u₂} [category.{v₂} D] {E : Type u₃} [category.{v₃} E]

/--
The uncurrying functor, taking a functor `C ⥤ (D ⥤ E)` and producing a functor `(C × D) ⥤ E`.
-/
def uncurry : (C ⥤ D ⥤ E) ⥤ C × D ⥤ E :=
  { obj :=
      fun F =>
        { obj := fun X => (F.obj X.1).obj X.2, map := fun X Y f => (F.map f.1).app X.2 ≫ (F.obj Y.1).map f.2,
          map_comp' :=
            fun X Y Z f g =>
              by 
                simp only [prod_comp_fst, prod_comp_snd, functor.map_comp, nat_trans.comp_app, category.assoc]
                sliceLHS 2 3 => rw [←nat_trans.naturality]
                rw [category.assoc] },
    map :=
      fun F G T =>
        { app := fun X => (T.app X.1).app X.2,
          naturality' :=
            fun X Y f =>
              by 
                simp only [prod_comp_fst, prod_comp_snd, category.comp_id, category.assoc, Functor.map_id,
                  functor.map_comp, nat_trans.id_app, nat_trans.comp_app]
                sliceLHS 2 3 => rw [nat_trans.naturality]
                sliceLHS 1 2 => rw [←nat_trans.comp_app, nat_trans.naturality, nat_trans.comp_app]
                rw [category.assoc] } }

/--
The object level part of the currying functor. (See `curry` for the functorial version.)
-/
def curry_obj (F : C × D ⥤ E) : C ⥤ D ⥤ E :=
  { obj := fun X => { obj := fun Y => F.obj (X, Y), map := fun Y Y' g => F.map (𝟙 X, g) },
    map := fun X X' f => { app := fun Y => F.map (f, 𝟙 Y) } }

/--
The currying functor, taking a functor `(C × D) ⥤ E` and producing a functor `C ⥤ (D ⥤ E)`.
-/
def curry : (C × D ⥤ E) ⥤ C ⥤ D ⥤ E :=
  { obj := fun F => curry_obj F,
    map :=
      fun F G T =>
        { app :=
            fun X =>
              { app := fun Y => T.app (X, Y),
                naturality' :=
                  fun Y Y' g =>
                    by 
                      dsimp [curry_obj]
                      rw [nat_trans.naturality] },
          naturality' :=
            fun X X' f =>
              by 
                ext 
                dsimp [curry_obj]
                rw [nat_trans.naturality] } }

@[simp]
theorem uncurry.obj_obj {F : C ⥤ D ⥤ E} {X : C × D} : (uncurry.obj F).obj X = (F.obj X.1).obj X.2 :=
  rfl

@[simp]
theorem uncurry.obj_map {F : C ⥤ D ⥤ E} {X Y : C × D} {f : X ⟶ Y} :
  (uncurry.obj F).map f = (F.map f.1).app X.2 ≫ (F.obj Y.1).map f.2 :=
  rfl

@[simp]
theorem uncurry.map_app {F G : C ⥤ D ⥤ E} {α : F ⟶ G} {X : C × D} : (uncurry.map α).app X = (α.app X.1).app X.2 :=
  rfl

@[simp]
theorem curry.obj_obj_obj {F : C × D ⥤ E} {X : C} {Y : D} : ((curry.obj F).obj X).obj Y = F.obj (X, Y) :=
  rfl

@[simp]
theorem curry.obj_obj_map {F : C × D ⥤ E} {X : C} {Y Y' : D} {g : Y ⟶ Y'} :
  ((curry.obj F).obj X).map g = F.map (𝟙 X, g) :=
  rfl

@[simp]
theorem curry.obj_map_app {F : C × D ⥤ E} {X X' : C} {f : X ⟶ X'} {Y} : ((curry.obj F).map f).app Y = F.map (f, 𝟙 Y) :=
  rfl

@[simp]
theorem curry.map_app_app {F G : C × D ⥤ E} {α : F ⟶ G} {X} {Y} : ((curry.map α).app X).app Y = α.app (X, Y) :=
  rfl

/--
The equivalence of functor categories given by currying/uncurrying.
-/
@[simps]
def currying : C ⥤ D ⥤ E ≌ C × D ⥤ E :=
  equivalence.mk uncurry curry
    (nat_iso.of_components
      (fun F =>
        nat_iso.of_components
          (fun X =>
            nat_iso.of_components (fun Y => iso.refl _)
              (by 
                tidy))
          (by 
            tidy))
      (by 
        tidy))
    (nat_iso.of_components
      (fun F =>
        nat_iso.of_components
          (fun X =>
            eq_to_iso
              (by 
                simp ))
          (by 
            tidy))
      (by 
        tidy))

end CategoryTheory

