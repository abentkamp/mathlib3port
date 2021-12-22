import Mathbin.CategoryTheory.StructuredArrow
import Mathbin.CategoryTheory.Groupoid
import Mathbin.CategoryTheory.Punit

/-!
# The category of elements

This file defines the category of elements, also known as (a special case of) the Grothendieck
construction.

Given a functor `F : C ⥤ Type`, an object of `F.elements` is a pair `(X : C, x : F.obj X)`.
A morphism `(X, x) ⟶ (Y, y)` is a morphism `f : X ⟶ Y` in `C`, so `F.map f` takes `x` to `y`.

## Implementation notes

This construction is equivalent to a special case of a comma construction, so this is mostly just a
more convenient API. We prove the equivalence in
`category_theory.category_of_elements.structured_arrow_equivalence`.

## References
* [Emily Riehl, *Category Theory in Context*, Section 2.4][riehl2017]
* <https://en.wikipedia.org/wiki/Category_of_elements>
* <https://ncatlab.org/nlab/show/category+of+elements>

## Tags
category of elements, Grothendieck construction, comma category
-/


namespace CategoryTheory

universe w v u

variable {C : Type u} [category.{v} C]

/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize.input] (Command.declaration
 (Command.declModifiers
  [(Command.docComment
    "/--"
    "\nThe type of objects for the category of elements of a functor `F : C ⥤ Type`\nis a pair `(X : C, x : F.obj X)`.\n-/")]
  [(Term.attributes
    "@["
    [(Term.attrInstance (Term.attrKind []) (Mathlib.Tactic.Lint.nolint "nolint" [`has_inhabited_instance]))]
    "]")]
  []
  []
  []
  [])
 (Command.def
  "def"
  (Command.declId `functor.elements [])
  (Command.optDeclSig
   [(Term.explicitBinder
     "("
     [`F]
     [":" (CategoryTheory.CategoryTheory.Functor.«term_⥤_» `C " ⥤ " (Term.type "Type" [`w]))]
     []
     ")")]
   [])
  (Command.declValSimple
   ":="
   (Init.Data.Sigma.Basic.«termΣ_,_»
    "Σ"
    (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `c)] [":" `C]))
    ", "
    (Term.app `F.obj [`c]))
   [])
  []
  []
  []))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declaration', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declaration', expected 'Lean.Parser.Command.declaration.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.abbrev.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.abbrev'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.def.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValSimple.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Init.Data.Sigma.Basic.«termΣ_,_»
   "Σ"
   (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `c)] [":" `C]))
   ", "
   (Term.app `F.obj [`c]))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Init.Data.Sigma.Basic.«termΣ_,_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `F.obj [`c])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `c
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `F.obj
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.explicitBinders', expected 'Mathlib.ExtendedBinder.extBinders'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValEqns.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValEqns'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.whereStructInst.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.whereStructInst'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.theorem.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.theorem'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.constant.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.constant'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.instance.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.instance'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.axiom.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.axiom'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.example.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.example'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.inductive.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.inductive'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.classInductive.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.classInductive'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.structure.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.def', expected 'Lean.Parser.Command.structure'-/-- failed to format: format: uncaught backtrack exception
/--
      The type of objects for the category of elements of a functor `F : C ⥤ Type`
      is a pair `(X : C, x : F.obj X)`.
      -/
    @[ nolint has_inhabited_instance ]
  def functor.elements ( F : C ⥤ Type w ) := Σ c : C , F.obj c

-- failed to format: format: uncaught backtrack exception
/--
    The category structure on `F.elements`, for `F : C ⥤ Type`.
        A morphism `(X, x) ⟶ (Y, y)` is a morphism `f : X ⟶ Y` in `C`, so `F.map f` takes `x` to `y`.
     -/
  instance
    category_of_elements
    ( F : C ⥤ Type w ) : category .{ v } F.elements
    where
      Hom p q := { f : p . 1 ⟶ q . 1 // ( F.map f ) p . 2 = q . 2 }
        id p := ⟨ 𝟙 p . 1 , by run_tac obviously ⟩
        comp p q r f g := ⟨ f.val ≫ g.val , by run_tac obviously ⟩

namespace CategoryOfElements

@[ext]
theorem ext (F : C ⥤ Type w) {x y : F.elements} (f g : x ⟶ y) (w : f.val = g.val) : f = g :=
  Subtype.ext_val w

@[simp]
theorem comp_val {F : C ⥤ Type w} {p q r : F.elements} {f : p ⟶ q} {g : q ⟶ r} : (f ≫ g).val = f.val ≫ g.val :=
  rfl

@[simp]
theorem id_val {F : C ⥤ Type w} {p : F.elements} : (𝟙 p : p ⟶ p).val = 𝟙 p.1 :=
  rfl

end CategoryOfElements

-- failed to format: format: uncaught backtrack exception
noncomputable
  instance
    groupoid_of_elements
    { G : Type u } [ groupoid .{ v } G ] ( F : G ⥤ Type w ) : groupoid F.elements
    where
      inv
        p q f
        :=
        ⟨
          inv f.val
            ,
            calc
              F.map ( inv f.val ) q . 2 = F.map ( inv f.val ) ( F.map f.val p . 2 ) := by rw [ f . 2 ]
                _ = ( F.map f.val ≫ F.map ( inv f.val ) ) p . 2 := by simp
                _ = p . 2 := by rw [ ← functor.map_comp ] simp
          ⟩

namespace CategoryOfElements

variable (F : C ⥤ Type w)

/--  The functor out of the category of elements which forgets the element. -/
@[simps]
def π : F.elements ⥤ C :=
  { obj := fun X => X.1, map := fun X Y f => f.val }

/-- 
A natural transformation between functors induces a functor between the categories of elements.
-/
@[simps]
def map {F₁ F₂ : C ⥤ Type w} (α : F₁ ⟶ F₂) : F₁.elements ⥤ F₂.elements :=
  { obj := fun t => ⟨t.1, α.app t.1 t.2⟩,
    map := fun t₁ t₂ k =>
      ⟨k.1, by
        simpa [← k.2] using (functor_to_types.naturality _ _ α k.1 t₁.2).symm⟩ }

@[simp]
theorem map_π {F₁ F₂ : C ⥤ Type w} (α : F₁ ⟶ F₂) : map α ⋙ π F₂ = π F₁ :=
  rfl

/--  The forward direction of the equivalence `F.elements ≅ (*, F)`. -/
def to_structured_arrow : F.elements ⥤ structured_arrow PUnit F :=
  { obj := fun X => structured_arrow.mk fun _ => X.2,
    map := fun X Y f =>
      structured_arrow.hom_mk f.val
        (by
          tidy) }

@[simp]
theorem to_structured_arrow_obj X :
    (to_structured_arrow F).obj X = { left := PUnit.unit, right := X.1, Hom := fun _ => X.2 } :=
  rfl

@[simp]
theorem to_comma_map_right {X Y} (f : X ⟶ Y) : ((to_structured_arrow F).map f).right = f.val :=
  rfl

/--  The reverse direction of the equivalence `F.elements ≅ (*, F)`. -/
def from_structured_arrow : structured_arrow PUnit F ⥤ F.elements :=
  { obj := fun X => ⟨X.right, X.hom PUnit.unit⟩, map := fun X Y f => ⟨f.right, congr_funₓ f.w'.symm PUnit.unit⟩ }

@[simp]
theorem from_structured_arrow_obj X : (from_structured_arrow F).obj X = ⟨X.right, X.hom PUnit.unit⟩ :=
  rfl

@[simp]
theorem from_structured_arrow_map {X Y} (f : X ⟶ Y) :
    (from_structured_arrow F).map f = ⟨f.right, congr_funₓ f.w'.symm PUnit.unit⟩ :=
  rfl

/--  The equivalence between the category of elements `F.elements`
    and the comma category `(*, F)`. -/
@[simps]
def structured_arrow_equivalence : F.elements ≌ structured_arrow PUnit F :=
  equivalence.mk (to_structured_arrow F) (from_structured_arrow F)
    (nat_iso.of_components
      (fun X =>
        eq_to_iso
          (by
            tidy))
      (by
        tidy))
    (nat_iso.of_components (fun X => { Hom := { right := 𝟙 _ }, inv := { right := 𝟙 _ } })
      (by
        tidy))

open Opposite

/-- 
The forward direction of the equivalence `F.elementsᵒᵖ ≅ (yoneda, F)`,
given by `category_theory.yoneda_sections`.
-/
@[simps]
def to_costructured_arrow (F : Cᵒᵖ ⥤ Type v) : F.elementsᵒᵖ ⥤ costructured_arrow yoneda F :=
  { obj := fun X => costructured_arrow.mk ((yoneda_sections (unop (unop X).fst) F).inv (Ulift.up (unop X).2)),
    map := fun X Y f => by
      fapply costructured_arrow.hom_mk
      exact f.unop.val.unop
      ext y
      simp only [costructured_arrow.mk_hom_eq_self, yoneda_map_app, functor_to_types.comp, op_comp,
        yoneda_sections_inv_app, functor_to_types.map_comp_apply, Quiver.Hom.op_unop, Subtype.val_eq_coe]
      congr
      exact f.unop.2 }

/-- 
The reverse direction of the equivalence `F.elementsᵒᵖ ≅ (yoneda, F)`,
given by `category_theory.yoneda_equiv`.
-/
@[simps]
def from_costructured_arrow (F : Cᵒᵖ ⥤ Type v) : costructured_arrow yoneda Fᵒᵖ ⥤ F.elements :=
  { obj := fun X => ⟨op (unop X).1, yoneda_equiv.1 (unop X).3⟩,
    map := fun X Y f =>
      ⟨f.unop.1.op, by
        convert (congr_funₓ ((unop X).Hom.naturality f.unop.left.op) (𝟙 _)).symm
        simp only [Equivₓ.to_fun_as_coe, Quiver.Hom.unop_op, yoneda_equiv_apply, types_comp_apply, category.comp_id,
          yoneda_obj_map]
        have : yoneda.map f.unop.left ≫ (unop X).Hom = (unop Y).Hom := by
          convert f.unop.3
          erw [category.comp_id]
        erw [← this]
        simp only [yoneda_map_app, functor_to_types.comp]
        erw [category.id_comp]⟩ }

@[simp]
theorem from_costructured_arrow_obj_mk (F : Cᵒᵖ ⥤ Type v) {X : C} (f : yoneda.obj X ⟶ F) :
    (from_costructured_arrow F).obj (op (costructured_arrow.mk f)) = ⟨op X, yoneda_equiv.1 f⟩ :=
  rfl

/--  The unit of the equivalence `F.elementsᵒᵖ ≅ (yoneda, F)` is indeed iso. -/
theorem from_to_costructured_arrow_eq (F : Cᵒᵖ ⥤ Type v) :
    (to_costructured_arrow F).rightOp ⋙ from_costructured_arrow F = 𝟭 _ := by
  apply Functor.ext
  intro X Y f
  have :
    ∀ {a b : F.elements} H : a = b,
      ↑eq_to_hom H =
        eq_to_hom
          (show a.fst = b.fst by
            cases H
            rfl) :=
    fun _ _ H => by
    cases H
    rfl
  ext
  simp [this]
  tidy

/--  The counit of the equivalence `F.elementsᵒᵖ ≅ (yoneda, F)` is indeed iso. -/
theorem to_from_costructured_arrow_eq (F : Cᵒᵖ ⥤ Type v) :
    (from_costructured_arrow F).rightOp ⋙ to_costructured_arrow F = 𝟭 _ := by
  apply functor.hext
  ·
    intro X
    cases X
    cases X_right
    simp only [functor.id_obj, functor.right_op_obj, to_costructured_arrow_obj, functor.comp_obj, costructured_arrow.mk]
    congr
    ext x f
    convert congr_funₓ (X_hom.naturality f.op).symm (𝟙 X_left)
    simp only [Quiver.Hom.unop_op, yoneda_obj_map]
    erw [category.comp_id]
  intro X Y f
  cases X
  cases Y
  cases f
  cases X_right
  cases Y_right
  simp [costructured_arrow.hom_mk]
  delta' costructured_arrow.mk
  congr
  ·
    ext x f
    convert congr_funₓ (X_hom.naturality f.op).symm (𝟙 X_left)
    simp only [Quiver.Hom.unop_op, CategoryTheory.yoneda_obj_map]
    erw [category.comp_id]
  ·
    ext x f
    convert congr_funₓ (Y_hom.naturality f.op).symm (𝟙 Y_left)
    simp only [Quiver.Hom.unop_op, CategoryTheory.yoneda_obj_map]
    erw [category.comp_id]
  simp
  exact proof_irrel_heq _ _

/--  The equivalence `F.elementsᵒᵖ ≅ (yoneda, F)` given by yoneda lemma. -/
@[simps]
def costructured_arrow_yoneda_equivalence (F : Cᵒᵖ ⥤ Type v) : F.elementsᵒᵖ ≌ costructured_arrow yoneda F :=
  equivalence.mk (to_costructured_arrow F) (from_costructured_arrow F).rightOp
    (nat_iso.op (eq_to_iso (from_to_costructured_arrow_eq F))) (eq_to_iso $ to_from_costructured_arrow_eq F)

/-- 
The equivalence `(-.elements)ᵒᵖ ≅ (yoneda, -)` of is actually a natural isomorphism of functors.
-/
theorem costructured_arrow_yoneda_equivalence_naturality {F₁ F₂ : Cᵒᵖ ⥤ Type v} (α : F₁ ⟶ F₂) :
    (map α).op ⋙ to_costructured_arrow F₂ = to_costructured_arrow F₁ ⋙ costructured_arrow.map α := by
  fapply Functor.ext
  ·
    intro X
    simp only [costructured_arrow.map_mk, to_costructured_arrow_obj, functor.op_obj, functor.comp_obj]
    congr
    ext x f
    simpa using congr_funₓ (α.naturality f.op).symm (unop X).snd
  ·
    intro X Y f
    ext
    have :
      ∀ {F : Cᵒᵖ ⥤ Type v} {a b : costructured_arrow yoneda F} H : a = b,
        comma_morphism.left (eq_to_hom H) =
          eq_to_hom
            (show a.left = b.left by
              cases H
              rfl) :=
      fun _ _ _ H => by
      cases H
      rfl
    simp [this]

end CategoryOfElements

end CategoryTheory

