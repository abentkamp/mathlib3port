import Mathbin.CategoryTheory.Limits.Shapes.Terminal
import Mathbin.CategoryTheory.DiscreteCategory
import Mathbin.CategoryTheory.EpiMono
import Mathbin.CategoryTheory.Over

/-!
# Binary (co)products

We define a category `walking_pair`, which is the index category
for a binary (co)product diagram. A convenience method `pair X Y`
constructs the functor from the walking pair, hitting the given objects.

We define `prod X Y` and `coprod X Y` as limits and colimits of such functors.

Typeclasses `has_binary_products` and `has_binary_coproducts` assert the existence
of (co)limits shaped as walking pairs.

We include lemmas for simplifying equations involving projections and coprojections, and define
braiding and associating isomorphisms, and the product comparison morphism.

## References
* [Stacks: Products of pairs](https://stacks.math.columbia.edu/tag/001R)
* [Stacks: coproducts of pairs](https://stacks.math.columbia.edu/tag/04AN)
-/


noncomputable section

universe v u u₂

open CategoryTheory

namespace CategoryTheory.Limits

-- ././Mathport/Syntax/Translate/Basic.lean:833:9: unsupported derive handler decidable_eq
-- ././Mathport/Syntax/Translate/Basic.lean:833:9: unsupported derive handler inhabited
/--  The type of objects for the diagram indexing a binary (co)product. -/
inductive walking_pair : Type v
  | left
  | right
  deriving [anonymous], [anonymous]

open WalkingPair

/-- 
The equivalence swapping left and right.
-/
def walking_pair.swap : walking_pair ≃ walking_pair :=
  { toFun := fun j => walking_pair.rec_on j right left, invFun := fun j => walking_pair.rec_on j right left,
    left_inv := fun j => by
      cases j <;> rfl,
    right_inv := fun j => by
      cases j <;> rfl }

@[simp]
theorem walking_pair.swap_apply_left : walking_pair.swap left = right :=
  rfl

@[simp]
theorem walking_pair.swap_apply_right : walking_pair.swap right = left :=
  rfl

@[simp]
theorem walking_pair.swap_symm_apply_tt : walking_pair.swap.symm left = right :=
  rfl

@[simp]
theorem walking_pair.swap_symm_apply_ff : walking_pair.swap.symm right = left :=
  rfl

/-- 
An equivalence from `walking_pair` to `bool`, sometimes useful when reindexing limits.
-/
def walking_pair.equiv_bool : walking_pair ≃ Bool :=
  { toFun := fun j => walking_pair.rec_on j tt ff, invFun := fun b => Bool.recOn b right left,
    left_inv := fun j => by
      cases j <;> rfl,
    right_inv := fun b => by
      cases b <;> rfl }

@[simp]
theorem walking_pair.equiv_bool_apply_left : walking_pair.equiv_bool left = tt :=
  rfl

@[simp]
theorem walking_pair.equiv_bool_apply_right : walking_pair.equiv_bool right = ff :=
  rfl

@[simp]
theorem walking_pair.equiv_bool_symm_apply_tt : walking_pair.equiv_bool.symm tt = left :=
  rfl

@[simp]
theorem walking_pair.equiv_bool_symm_apply_ff : walking_pair.equiv_bool.symm ff = right :=
  rfl

variable {C : Type u} [category.{v} C]

/--  The diagram on the walking pair, sending the two points to `X` and `Y`. -/
def pair (X Y : C) : discrete walking_pair.{v} ⥤ C :=
  discrete.functor fun j => walking_pair.cases_on j X Y

@[simp]
theorem pair_obj_left (X Y : C) : (pair X Y).obj left = X :=
  rfl

@[simp]
theorem pair_obj_right (X Y : C) : (pair X Y).obj right = Y :=
  rfl

section

variable {F G : discrete walking_pair.{v} ⥤ C} (f : F.obj left ⟶ G.obj left) (g : F.obj right ⟶ G.obj right)

/--  The natural transformation between two functors out of the walking pair, specified by its
components. -/
def map_pair : F ⟶ G :=
  { app := fun j => walking_pair.cases_on j f g }

@[simp]
theorem map_pair_left : (map_pair f g).app left = f :=
  rfl

@[simp]
theorem map_pair_right : (map_pair f g).app right = g :=
  rfl

/--  The natural isomorphism between two functors out of the walking pair, specified by its
components. -/
@[simps]
def map_pair_iso (f : F.obj left ≅ G.obj left) (g : F.obj right ≅ G.obj right) : F ≅ G :=
  nat_iso.of_components (fun j => walking_pair.cases_on j f g)
    (by
      tidy)

end

/--  Every functor out of the walking pair is naturally isomorphic (actually, equal) to a `pair` -/
@[simps]
def diagram_iso_pair (F : discrete walking_pair ⥤ C) : F ≅ pair (F.obj walking_pair.left) (F.obj walking_pair.right) :=
  map_pair_iso (iso.refl _) (iso.refl _)

section

variable {D : Type u} [category.{v} D]

/--  The natural isomorphism between `pair X Y ⋙ F` and `pair (F.obj X) (F.obj Y)`. -/
def pair_comp (X Y : C) (F : C ⥤ D) : pair X Y ⋙ F ≅ pair (F.obj X) (F.obj Y) :=
  diagram_iso_pair _

end

/--  A binary fan is just a cone on a diagram indexing a product. -/
abbrev binary_fan (X Y : C) :=
  cone (pair X Y)

/--  The first projection of a binary fan. -/
abbrev binary_fan.fst {X Y : C} (s : binary_fan X Y) :=
  s.π.app walking_pair.left

/--  The second projection of a binary fan. -/
abbrev binary_fan.snd {X Y : C} (s : binary_fan X Y) :=
  s.π.app walking_pair.right

@[simp]
theorem binary_fan.π_app_left {X Y : C} (s : binary_fan X Y) : s.π.app walking_pair.left = s.fst :=
  rfl

@[simp]
theorem binary_fan.π_app_right {X Y : C} (s : binary_fan X Y) : s.π.app walking_pair.right = s.snd :=
  rfl

theorem binary_fan.is_limit.hom_ext {W X Y : C} {s : binary_fan X Y} (h : is_limit s) {f g : W ⟶ s.X}
    (h₁ : f ≫ s.fst = g ≫ s.fst) (h₂ : f ≫ s.snd = g ≫ s.snd) : f = g :=
  h.hom_ext $ fun j => walking_pair.cases_on j h₁ h₂

/--  A binary cofan is just a cocone on a diagram indexing a coproduct. -/
abbrev binary_cofan (X Y : C) :=
  cocone (pair X Y)

/--  The first inclusion of a binary cofan. -/
abbrev binary_cofan.inl {X Y : C} (s : binary_cofan X Y) :=
  s.ι.app walking_pair.left

/--  The second inclusion of a binary cofan. -/
abbrev binary_cofan.inr {X Y : C} (s : binary_cofan X Y) :=
  s.ι.app walking_pair.right

@[simp]
theorem binary_cofan.ι_app_left {X Y : C} (s : binary_cofan X Y) : s.ι.app walking_pair.left = s.inl :=
  rfl

@[simp]
theorem binary_cofan.ι_app_right {X Y : C} (s : binary_cofan X Y) : s.ι.app walking_pair.right = s.inr :=
  rfl

theorem binary_cofan.is_colimit.hom_ext {W X Y : C} {s : binary_cofan X Y} (h : is_colimit s) {f g : s.X ⟶ W}
    (h₁ : s.inl ≫ f = s.inl ≫ g) (h₂ : s.inr ≫ f = s.inr ≫ g) : f = g :=
  h.hom_ext $ fun j => walking_pair.cases_on j h₁ h₂

variable {X Y : C}

/--  A binary fan with vertex `P` consists of the two projections `π₁ : P ⟶ X` and `π₂ : P ⟶ Y`. -/
@[simps x]
def binary_fan.mk {P : C} (π₁ : P ⟶ X) (π₂ : P ⟶ Y) : binary_fan X Y :=
  { x := P, π := { app := fun j => walking_pair.cases_on j π₁ π₂ } }

/--  A binary cofan with vertex `P` consists of the two inclusions `ι₁ : X ⟶ P` and `ι₂ : Y ⟶ P`. -/
@[simps x]
def binary_cofan.mk {P : C} (ι₁ : X ⟶ P) (ι₂ : Y ⟶ P) : binary_cofan X Y :=
  { x := P, ι := { app := fun j => walking_pair.cases_on j ι₁ ι₂ } }

@[simp]
theorem binary_fan.mk_π_app_left {P : C} (π₁ : P ⟶ X) (π₂ : P ⟶ Y) :
    (binary_fan.mk π₁ π₂).π.app walking_pair.left = π₁ :=
  rfl

@[simp]
theorem binary_fan.mk_π_app_right {P : C} (π₁ : P ⟶ X) (π₂ : P ⟶ Y) :
    (binary_fan.mk π₁ π₂).π.app walking_pair.right = π₂ :=
  rfl

@[simp]
theorem binary_cofan.mk_ι_app_left {P : C} (ι₁ : X ⟶ P) (ι₂ : Y ⟶ P) :
    (binary_cofan.mk ι₁ ι₂).ι.app walking_pair.left = ι₁ :=
  rfl

@[simp]
theorem binary_cofan.mk_ι_app_right {P : C} (ι₁ : X ⟶ P) (ι₂ : Y ⟶ P) :
    (binary_cofan.mk ι₁ ι₂).ι.app walking_pair.right = ι₂ :=
  rfl

/--  If `s` is a limit binary fan over `X` and `Y`, then every pair of morphisms `f : W ⟶ X` and
    `g : W ⟶ Y` induces a morphism `l : W ⟶ s.X` satisfying `l ≫ s.fst = f` and `l ≫ s.snd = g`.
    -/
@[simps]
def binary_fan.is_limit.lift' {W X Y : C} {s : binary_fan X Y} (h : is_limit s) (f : W ⟶ X) (g : W ⟶ Y) :
    { l : W ⟶ s.X // l ≫ s.fst = f ∧ l ≫ s.snd = g } :=
  ⟨h.lift $ binary_fan.mk f g, h.fac _ _, h.fac _ _⟩

/--  If `s` is a colimit binary cofan over `X` and `Y`,, then every pair of morphisms `f : X ⟶ W` and
    `g : Y ⟶ W` induces a morphism `l : s.X ⟶ W` satisfying `s.inl ≫ l = f` and `s.inr ≫ l = g`.
    -/
@[simps]
def binary_cofan.is_colimit.desc' {W X Y : C} {s : binary_cofan X Y} (h : is_colimit s) (f : X ⟶ W) (g : Y ⟶ W) :
    { l : s.X ⟶ W // s.inl ≫ l = f ∧ s.inr ≫ l = g } :=
  ⟨h.desc $ binary_cofan.mk f g, h.fac _ _, h.fac _ _⟩

/--  An abbreviation for `has_limit (pair X Y)`. -/
abbrev has_binary_product (X Y : C) :=
  has_limit (pair X Y)

/--  An abbreviation for `has_colimit (pair X Y)`. -/
abbrev has_binary_coproduct (X Y : C) :=
  has_colimit (pair X Y)

/--  If we have a product of `X` and `Y`, we can access it using `prod X Y` or
    `X ⨯ Y`. -/
abbrev Prod (X Y : C) [has_binary_product X Y] :=
  limit (pair X Y)

/--  If we have a coproduct of `X` and `Y`, we can access it using `coprod X Y ` or
    `X ⨿ Y`. -/
abbrev coprod (X Y : C) [has_binary_coproduct X Y] :=
  colimit (pair X Y)

notation:20 X " ⨯ " Y:20 => Prod X Y

notation:20 X " ⨿ " Y:20 => coprod X Y

/--  The projection map to the first component of the product. -/
abbrev Prod.fst {X Y : C} [has_binary_product X Y] : X ⨯ Y ⟶ X :=
  limit.π (pair X Y) walking_pair.left

/--  The projecton map to the second component of the product. -/
abbrev Prod.snd {X Y : C} [has_binary_product X Y] : X ⨯ Y ⟶ Y :=
  limit.π (pair X Y) walking_pair.right

/--  The inclusion map from the first component of the coproduct. -/
abbrev coprod.inl {X Y : C} [has_binary_coproduct X Y] : X ⟶ X ⨿ Y :=
  colimit.ι (pair X Y) walking_pair.left

/--  The inclusion map from the second component of the coproduct. -/
abbrev coprod.inr {X Y : C} [has_binary_coproduct X Y] : Y ⟶ X ⨿ Y :=
  colimit.ι (pair X Y) walking_pair.right

/--  The binary fan constructed from the projection maps is a limit. -/
def prod_is_prod (X Y : C) [has_binary_product X Y] : is_limit (binary_fan.mk (Prod.fst : X ⨯ Y ⟶ X) Prod.snd) :=
  (limit.is_limit _).ofIsoLimit
    (cones.ext (iso.refl _)
      (by
        rintro (_ | _)
        tidy))

/--  The binary cofan constructed from the coprojection maps is a colimit. -/
def coprod_is_coprod (X Y : C) [has_binary_coproduct X Y] :
    is_colimit (binary_cofan.mk (coprod.inl : X ⟶ X ⨿ Y) coprod.inr) :=
  (colimit.is_colimit _).ofIsoColimit
    (cocones.ext (iso.refl _)
      (by
        rintro (_ | _)
        tidy))

@[ext]
theorem prod.hom_ext {W X Y : C} [has_binary_product X Y] {f g : W ⟶ X ⨯ Y} (h₁ : f ≫ Prod.fst = g ≫ Prod.fst)
    (h₂ : f ≫ Prod.snd = g ≫ Prod.snd) : f = g :=
  binary_fan.is_limit.hom_ext (limit.is_limit _) h₁ h₂

@[ext]
theorem coprod.hom_ext {W X Y : C} [has_binary_coproduct X Y] {f g : X ⨿ Y ⟶ W} (h₁ : coprod.inl ≫ f = coprod.inl ≫ g)
    (h₂ : coprod.inr ≫ f = coprod.inr ≫ g) : f = g :=
  binary_cofan.is_colimit.hom_ext (colimit.is_colimit _) h₁ h₂

/--  If the product of `X` and `Y` exists, then every pair of morphisms `f : W ⟶ X` and `g : W ⟶ Y`
    induces a morphism `prod.lift f g : W ⟶ X ⨯ Y`. -/
abbrev prod.lift {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) : W ⟶ X ⨯ Y :=
  limit.lift _ (binary_fan.mk f g)

/--  diagonal arrow of the binary product in the category `fam I` -/
abbrev diag (X : C) [has_binary_product X X] : X ⟶ X ⨯ X :=
  prod.lift (𝟙 _) (𝟙 _)

/--  If the coproduct of `X` and `Y` exists, then every pair of morphisms `f : X ⟶ W` and
    `g : Y ⟶ W` induces a morphism `coprod.desc f g : X ⨿ Y ⟶ W`. -/
abbrev coprod.desc {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) : X ⨿ Y ⟶ W :=
  colimit.desc _ (binary_cofan.mk f g)

/--  codiagonal arrow of the binary coproduct -/
abbrev codiag (X : C) [has_binary_coproduct X X] : X ⨿ X ⟶ X :=
  coprod.desc (𝟙 _) (𝟙 _)

@[simp, reassoc]
theorem prod.lift_fst {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) : prod.lift f g ≫ Prod.fst = f :=
  limit.lift_π _ _

@[simp, reassoc]
theorem prod.lift_snd {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) : prod.lift f g ≫ Prod.snd = g :=
  limit.lift_π _ _

@[reassoc, simp]
theorem coprod.inl_desc {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) :
    coprod.inl ≫ coprod.desc f g = f :=
  colimit.ι_desc _ _

@[reassoc, simp]
theorem coprod.inr_desc {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) :
    coprod.inr ≫ coprod.desc f g = g :=
  colimit.ι_desc _ _

instance prod.mono_lift_of_mono_left {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) [mono f] :
    mono (prod.lift f g) :=
  mono_of_mono_fac $ prod.lift_fst _ _

instance prod.mono_lift_of_mono_right {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) [mono g] :
    mono (prod.lift f g) :=
  mono_of_mono_fac $ prod.lift_snd _ _

instance coprod.epi_desc_of_epi_left {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) [epi f] :
    epi (coprod.desc f g) :=
  epi_of_epi_fac $ coprod.inl_desc _ _

instance coprod.epi_desc_of_epi_right {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) [epi g] :
    epi (coprod.desc f g) :=
  epi_of_epi_fac $ coprod.inr_desc _ _

/--  If the product of `X` and `Y` exists, then every pair of morphisms `f : W ⟶ X` and `g : W ⟶ Y`
    induces a morphism `l : W ⟶ X ⨯ Y` satisfying `l ≫ prod.fst = f` and `l ≫ prod.snd = g`. -/
def prod.lift' {W X Y : C} [has_binary_product X Y] (f : W ⟶ X) (g : W ⟶ Y) :
    { l : W ⟶ X ⨯ Y // l ≫ Prod.fst = f ∧ l ≫ Prod.snd = g } :=
  ⟨prod.lift f g, prod.lift_fst _ _, prod.lift_snd _ _⟩

/--  If the coproduct of `X` and `Y` exists, then every pair of morphisms `f : X ⟶ W` and
    `g : Y ⟶ W` induces a morphism `l : X ⨿ Y ⟶ W` satisfying `coprod.inl ≫ l = f` and
    `coprod.inr ≫ l = g`. -/
def coprod.desc' {W X Y : C} [has_binary_coproduct X Y] (f : X ⟶ W) (g : Y ⟶ W) :
    { l : X ⨿ Y ⟶ W // coprod.inl ≫ l = f ∧ coprod.inr ≫ l = g } :=
  ⟨coprod.desc f g, coprod.inl_desc _ _, coprod.inr_desc _ _⟩

/--  If the products `W ⨯ X` and `Y ⨯ Z` exist, then every pair of morphisms `f : W ⟶ Y` and
    `g : X ⟶ Z` induces a morphism `prod.map f g : W ⨯ X ⟶ Y ⨯ Z`. -/
def Prod.map {W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : W ⟶ Y) (g : X ⟶ Z) : W ⨯ X ⟶ Y ⨯ Z :=
  lim_map (map_pair f g)

/--  If the coproducts `W ⨿ X` and `Y ⨿ Z` exist, then every pair of morphisms `f : W ⟶ Y` and
    `g : W ⟶ Z` induces a morphism `coprod.map f g : W ⨿ X ⟶ Y ⨿ Z`. -/
def coprod.map {W X Y Z : C} [has_binary_coproduct W X] [has_binary_coproduct Y Z] (f : W ⟶ Y) (g : X ⟶ Z) :
    W ⨿ X ⟶ Y ⨿ Z :=
  colim_map (map_pair f g)

section ProdLemmas

@[reassoc, simp]
theorem prod.comp_lift {V W X Y : C} [has_binary_product X Y] (f : V ⟶ W) (g : W ⟶ X) (h : W ⟶ Y) :
    f ≫ prod.lift g h = prod.lift (f ≫ g) (f ≫ h) := by
  ext <;> simp

theorem prod.comp_diag {X Y : C} [has_binary_product Y Y] (f : X ⟶ Y) : f ≫ diag Y = prod.lift f f := by
  simp

@[simp, reassoc]
theorem Prod.map_fst {W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : W ⟶ Y) (g : X ⟶ Z) :
    Prod.map f g ≫ Prod.fst = Prod.fst ≫ f :=
  lim_map_π _ _

@[simp, reassoc]
theorem Prod.map_sndₓ {W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : W ⟶ Y) (g : X ⟶ Z) :
    Prod.map f g ≫ Prod.snd = Prod.snd ≫ g :=
  lim_map_π _ _

@[simp]
theorem prod.map_id_id {X Y : C} [has_binary_product X Y] : Prod.map (𝟙 X) (𝟙 Y) = 𝟙 _ := by
  ext <;> simp

@[simp]
theorem prod.lift_fst_snd {X Y : C} [has_binary_product X Y] : prod.lift Prod.fst Prod.snd = 𝟙 (X ⨯ Y) := by
  ext <;> simp

@[simp, reassoc]
theorem prod.lift_map {V W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : V ⟶ W) (g : V ⟶ X)
    (h : W ⟶ Y) (k : X ⟶ Z) : prod.lift f g ≫ Prod.map h k = prod.lift (f ≫ h) (g ≫ k) := by
  ext <;> simp

@[simp]
theorem prod.lift_fst_comp_snd_comp {W X Y Z : C} [has_binary_product W Y] [has_binary_product X Z] (g : W ⟶ X)
    (g' : Y ⟶ Z) : prod.lift (Prod.fst ≫ g) (Prod.snd ≫ g') = Prod.map g g' := by
  rw [← prod.lift_map]
  simp

@[simp, reassoc]
theorem Prod.map_mapₓ {A₁ A₂ A₃ B₁ B₂ B₃ : C} [has_binary_product A₁ B₁] [has_binary_product A₂ B₂]
    [has_binary_product A₃ B₃] (f : A₁ ⟶ A₂) (g : B₁ ⟶ B₂) (h : A₂ ⟶ A₃) (k : B₂ ⟶ B₃) :
    Prod.map f g ≫ Prod.map h k = Prod.map (f ≫ h) (g ≫ k) := by
  ext <;> simp

@[reassoc]
theorem prod.map_swap {A B X Y : C} (f : A ⟶ B) (g : X ⟶ Y) [has_limits_of_shape (discrete walking_pair.{v}) C] :
    Prod.map (𝟙 X) f ≫ Prod.map g (𝟙 B) = Prod.map g (𝟙 A) ≫ Prod.map (𝟙 Y) f := by
  simp

@[reassoc]
theorem prod.map_comp_id {X Y Z W : C} (f : X ⟶ Y) (g : Y ⟶ Z) [has_binary_product X W] [has_binary_product Z W]
    [has_binary_product Y W] : Prod.map (f ≫ g) (𝟙 W) = Prod.map f (𝟙 W) ≫ Prod.map g (𝟙 W) := by
  simp

@[reassoc]
theorem prod.map_id_comp {X Y Z W : C} (f : X ⟶ Y) (g : Y ⟶ Z) [has_binary_product W X] [has_binary_product W Y]
    [has_binary_product W Z] : Prod.map (𝟙 W) (f ≫ g) = Prod.map (𝟙 W) f ≫ Prod.map (𝟙 W) g := by
  simp

/--  If the products `W ⨯ X` and `Y ⨯ Z` exist, then every pair of isomorphisms `f : W ≅ Y` and
    `g : X ≅ Z` induces an isomorphism `prod.map_iso f g : W ⨯ X ≅ Y ⨯ Z`. -/
@[simps]
def prod.map_iso {W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : W ≅ Y) (g : X ≅ Z) :
    W ⨯ X ≅ Y ⨯ Z :=
  { Hom := Prod.map f.hom g.hom, inv := Prod.map f.inv g.inv }

instance is_iso_prod {W X Y Z : C} [has_binary_product W X] [has_binary_product Y Z] (f : W ⟶ Y) (g : X ⟶ Z) [is_iso f]
    [is_iso g] : is_iso (Prod.map f g) :=
  is_iso.of_iso (prod.map_iso (as_iso f) (as_iso g))

instance prod.map_mono {C : Type _} [category C] {W X Y Z : C} (f : W ⟶ Y) (g : X ⟶ Z) [mono f] [mono g]
    [has_binary_product W X] [has_binary_product Y Z] : mono (Prod.map f g) :=
  ⟨fun A i₁ i₂ h => by
    ext
    ·
      rw [← cancel_mono f]
      simpa using congr_argₓ (fun f => f ≫ Prod.fst) h
    ·
      rw [← cancel_mono g]
      simpa using congr_argₓ (fun f => f ≫ Prod.snd) h⟩

@[simp, reassoc]
theorem prod.diag_map {X Y : C} (f : X ⟶ Y) [has_binary_product X X] [has_binary_product Y Y] :
    diag X ≫ Prod.map f f = f ≫ diag Y := by
  simp

@[simp, reassoc]
theorem prod.diag_map_fst_snd {X Y : C} [has_binary_product X Y] [has_binary_product (X ⨯ Y) (X ⨯ Y)] :
    diag (X ⨯ Y) ≫ Prod.map Prod.fst Prod.snd = 𝟙 (X ⨯ Y) := by
  simp

@[simp, reassoc]
theorem prod.diag_map_fst_snd_comp [has_limits_of_shape (discrete walking_pair.{v}) C] {X X' Y Y' : C} (g : X ⟶ Y)
    (g' : X' ⟶ Y') : diag (X ⨯ X') ≫ Prod.map (Prod.fst ≫ g) (Prod.snd ≫ g') = Prod.map g g' := by
  simp

instance {X : C} [has_binary_product X X] : split_mono (diag X) where
  retraction := Prod.fst

end ProdLemmas

section CoprodLemmas

@[simp, reassoc]
theorem coprod.desc_comp {V W X Y : C} [has_binary_coproduct X Y] (f : V ⟶ W) (g : X ⟶ V) (h : Y ⟶ V) :
    coprod.desc g h ≫ f = coprod.desc (g ≫ f) (h ≫ f) := by
  ext <;> simp

theorem coprod.diag_comp {X Y : C} [has_binary_coproduct X X] (f : X ⟶ Y) : codiag X ≫ f = coprod.desc f f := by
  simp

@[simp, reassoc]
theorem coprod.inl_map {W X Y Z : C} [has_binary_coproduct W X] [has_binary_coproduct Y Z] (f : W ⟶ Y) (g : X ⟶ Z) :
    coprod.inl ≫ coprod.map f g = f ≫ coprod.inl :=
  ι_colim_map _ _

@[simp, reassoc]
theorem coprod.inr_map {W X Y Z : C} [has_binary_coproduct W X] [has_binary_coproduct Y Z] (f : W ⟶ Y) (g : X ⟶ Z) :
    coprod.inr ≫ coprod.map f g = g ≫ coprod.inr :=
  ι_colim_map _ _

@[simp]
theorem coprod.map_id_id {X Y : C} [has_binary_coproduct X Y] : coprod.map (𝟙 X) (𝟙 Y) = 𝟙 _ := by
  ext <;> simp

@[simp]
theorem coprod.desc_inl_inr {X Y : C} [has_binary_coproduct X Y] : coprod.desc coprod.inl coprod.inr = 𝟙 (X ⨿ Y) := by
  ext <;> simp

@[reassoc, simp]
theorem coprod.map_desc {S T U V W : C} [has_binary_coproduct U W] [has_binary_coproduct T V] (f : U ⟶ S) (g : W ⟶ S)
    (h : T ⟶ U) (k : V ⟶ W) : coprod.map h k ≫ coprod.desc f g = coprod.desc (h ≫ f) (k ≫ g) := by
  ext <;> simp

@[simp]
theorem coprod.desc_comp_inl_comp_inr {W X Y Z : C} [has_binary_coproduct W Y] [has_binary_coproduct X Z] (g : W ⟶ X)
    (g' : Y ⟶ Z) : coprod.desc (g ≫ coprod.inl) (g' ≫ coprod.inr) = coprod.map g g' := by
  rw [← coprod.map_desc]
  simp

@[simp, reassoc]
theorem coprod.map_map {A₁ A₂ A₃ B₁ B₂ B₃ : C} [has_binary_coproduct A₁ B₁] [has_binary_coproduct A₂ B₂]
    [has_binary_coproduct A₃ B₃] (f : A₁ ⟶ A₂) (g : B₁ ⟶ B₂) (h : A₂ ⟶ A₃) (k : B₂ ⟶ B₃) :
    coprod.map f g ≫ coprod.map h k = coprod.map (f ≫ h) (g ≫ k) := by
  ext <;> simp

@[reassoc]
theorem coprod.map_swap {A B X Y : C} (f : A ⟶ B) (g : X ⟶ Y) [has_colimits_of_shape (discrete walking_pair.{v}) C] :
    coprod.map (𝟙 X) f ≫ coprod.map g (𝟙 B) = coprod.map g (𝟙 A) ≫ coprod.map (𝟙 Y) f := by
  simp

@[reassoc]
theorem coprod.map_comp_id {X Y Z W : C} (f : X ⟶ Y) (g : Y ⟶ Z) [has_binary_coproduct Z W] [has_binary_coproduct Y W]
    [has_binary_coproduct X W] : coprod.map (f ≫ g) (𝟙 W) = coprod.map f (𝟙 W) ≫ coprod.map g (𝟙 W) := by
  simp

@[reassoc]
theorem coprod.map_id_comp {X Y Z W : C} (f : X ⟶ Y) (g : Y ⟶ Z) [has_binary_coproduct W X] [has_binary_coproduct W Y]
    [has_binary_coproduct W Z] : coprod.map (𝟙 W) (f ≫ g) = coprod.map (𝟙 W) f ≫ coprod.map (𝟙 W) g := by
  simp

/--  If the coproducts `W ⨿ X` and `Y ⨿ Z` exist, then every pair of isomorphisms `f : W ≅ Y` and
    `g : W ≅ Z` induces a isomorphism `coprod.map_iso f g : W ⨿ X ≅ Y ⨿ Z`. -/
@[simps]
def coprod.map_iso {W X Y Z : C} [has_binary_coproduct W X] [has_binary_coproduct Y Z] (f : W ≅ Y) (g : X ≅ Z) :
    W ⨿ X ≅ Y ⨿ Z :=
  { Hom := coprod.map f.hom g.hom, inv := coprod.map f.inv g.inv }

instance is_iso_coprod {W X Y Z : C} [has_binary_coproduct W X] [has_binary_coproduct Y Z] (f : W ⟶ Y) (g : X ⟶ Z)
    [is_iso f] [is_iso g] : is_iso (coprod.map f g) :=
  is_iso.of_iso (coprod.map_iso (as_iso f) (as_iso g))

instance coprod.map_epi {C : Type _} [category C] {W X Y Z : C} (f : W ⟶ Y) (g : X ⟶ Z) [epi f] [epi g]
    [has_binary_coproduct W X] [has_binary_coproduct Y Z] : epi (coprod.map f g) :=
  ⟨fun A i₁ i₂ h => by
    ext
    ·
      rw [← cancel_epi f]
      simpa using congr_argₓ (fun f => coprod.inl ≫ f) h
    ·
      rw [← cancel_epi g]
      simpa using congr_argₓ (fun f => coprod.inr ≫ f) h⟩

@[reassoc, simp]
theorem coprod.map_codiag {X Y : C} (f : X ⟶ Y) [has_binary_coproduct X X] [has_binary_coproduct Y Y] :
    coprod.map f f ≫ codiag Y = codiag X ≫ f := by
  simp

@[reassoc, simp]
theorem coprod.map_inl_inr_codiag {X Y : C} [has_binary_coproduct X Y] [has_binary_coproduct (X ⨿ Y) (X ⨿ Y)] :
    coprod.map coprod.inl coprod.inr ≫ codiag (X ⨿ Y) = 𝟙 (X ⨿ Y) := by
  simp

@[reassoc, simp]
theorem coprod.map_comp_inl_inr_codiag [has_colimits_of_shape (discrete walking_pair.{v}) C] {X X' Y Y' : C} (g : X ⟶ Y)
    (g' : X' ⟶ Y') : coprod.map (g ≫ coprod.inl) (g' ≫ coprod.inr) ≫ codiag (Y ⨿ Y') = coprod.map g g' := by
  simp

end CoprodLemmas

variable (C)

/-- 
`has_binary_products` represents a choice of product for every pair of objects.

See https://stacks.math.columbia.edu/tag/001T.
-/
abbrev has_binary_products :=
  has_limits_of_shape (discrete walking_pair.{v}) C

/-- 
`has_binary_coproducts` represents a choice of coproduct for every pair of objects.

See https://stacks.math.columbia.edu/tag/04AP.
-/
abbrev has_binary_coproducts :=
  has_colimits_of_shape (discrete walking_pair.{v}) C

/--  If `C` has all limits of diagrams `pair X Y`, then it has all binary products -/
theorem has_binary_products_of_has_limit_pair [∀ {X Y : C}, has_limit (pair X Y)] : has_binary_products C :=
  { HasLimit := fun F => has_limit_of_iso (diagram_iso_pair F).symm }

/--  If `C` has all colimits of diagrams `pair X Y`, then it has all binary coproducts -/
theorem has_binary_coproducts_of_has_colimit_pair [∀ {X Y : C}, has_colimit (pair X Y)] : has_binary_coproducts C :=
  { HasColimit := fun F => has_colimit_of_iso (diagram_iso_pair F) }

section

variable {C}

/--  The braiding isomorphism which swaps a binary product. -/
@[simps]
def prod.braiding (P Q : C) [has_binary_product P Q] [has_binary_product Q P] : P ⨯ Q ≅ Q ⨯ P :=
  { Hom := prod.lift Prod.snd Prod.fst, inv := prod.lift Prod.snd Prod.fst }

/--  The braiding isomorphism can be passed through a map by swapping the order. -/
@[reassoc]
theorem braid_natural [has_binary_products C] {W X Y Z : C} (f : X ⟶ Y) (g : Z ⟶ W) :
    Prod.map f g ≫ (prod.braiding _ _).Hom = (prod.braiding _ _).Hom ≫ Prod.map g f := by
  simp

@[reassoc]
theorem prod.symmetry' (P Q : C) [has_binary_product P Q] [has_binary_product Q P] :
    prod.lift Prod.snd Prod.fst ≫ prod.lift Prod.snd Prod.fst = 𝟙 (P ⨯ Q) :=
  (prod.braiding _ _).hom_inv_id

/--  The braiding isomorphism is symmetric. -/
@[reassoc]
theorem prod.symmetry (P Q : C) [has_binary_product P Q] [has_binary_product Q P] :
    (prod.braiding P Q).Hom ≫ (prod.braiding Q P).Hom = 𝟙 _ :=
  (prod.braiding _ _).hom_inv_id

/--  The associator isomorphism for binary products. -/
@[simps]
def prod.associator [has_binary_products C] (P Q R : C) : (P ⨯ Q) ⨯ R ≅ P ⨯ Q ⨯ R :=
  { Hom := prod.lift (Prod.fst ≫ Prod.fst) (prod.lift (Prod.fst ≫ Prod.snd) Prod.snd),
    inv := prod.lift (prod.lift Prod.fst (Prod.snd ≫ Prod.fst)) (Prod.snd ≫ Prod.snd) }

@[reassoc]
theorem prod.pentagon [has_binary_products C] (W X Y Z : C) :
    Prod.map (prod.associator W X Y).Hom (𝟙 Z) ≫
        (prod.associator W (X ⨯ Y) Z).Hom ≫ Prod.map (𝟙 W) (prod.associator X Y Z).Hom =
      (prod.associator (W ⨯ X) Y Z).Hom ≫ (prod.associator W X (Y ⨯ Z)).Hom :=
  by
  simp

@[reassoc]
theorem prod.associator_naturality [has_binary_products C] {X₁ X₂ X₃ Y₁ Y₂ Y₃ : C} (f₁ : X₁ ⟶ Y₁) (f₂ : X₂ ⟶ Y₂)
    (f₃ : X₃ ⟶ Y₃) :
    Prod.map (Prod.map f₁ f₂) f₃ ≫ (prod.associator Y₁ Y₂ Y₃).Hom =
      (prod.associator X₁ X₂ X₃).Hom ≫ Prod.map f₁ (Prod.map f₂ f₃) :=
  by
  simp

variable [has_terminal C]

/--  The left unitor isomorphism for binary products with the terminal object. -/
@[simps]
def prod.left_unitor (P : C) [has_binary_product (⊤_ C) P] : (⊤_ C) ⨯ P ≅ P :=
  { Hom := Prod.snd, inv := prod.lift (terminal.from P) (𝟙 _) }

/--  The right unitor isomorphism for binary products with the terminal object. -/
@[simps]
def prod.right_unitor (P : C) [has_binary_product P (⊤_ C)] : P ⨯ ⊤_ C ≅ P :=
  { Hom := Prod.fst, inv := prod.lift (𝟙 _) (terminal.from P) }

@[reassoc]
theorem prod.left_unitor_hom_naturality [has_binary_products C] (f : X ⟶ Y) :
    Prod.map (𝟙 _) f ≫ (prod.left_unitor Y).Hom = (prod.left_unitor X).Hom ≫ f :=
  Prod.map_sndₓ _ _

@[reassoc]
theorem prod.left_unitor_inv_naturality [has_binary_products C] (f : X ⟶ Y) :
    (prod.left_unitor X).inv ≫ Prod.map (𝟙 _) f = f ≫ (prod.left_unitor Y).inv := by
  rw [iso.inv_comp_eq, ← category.assoc, iso.eq_comp_inv, prod.left_unitor_hom_naturality]

@[reassoc]
theorem prod.right_unitor_hom_naturality [has_binary_products C] (f : X ⟶ Y) :
    Prod.map f (𝟙 _) ≫ (prod.right_unitor Y).Hom = (prod.right_unitor X).Hom ≫ f :=
  Prod.map_fst _ _

@[reassoc]
theorem prod_right_unitor_inv_naturality [has_binary_products C] (f : X ⟶ Y) :
    (prod.right_unitor X).inv ≫ Prod.map f (𝟙 _) = f ≫ (prod.right_unitor Y).inv := by
  rw [iso.inv_comp_eq, ← category.assoc, iso.eq_comp_inv, prod.right_unitor_hom_naturality]

theorem prod.triangle [has_binary_products C] (X Y : C) :
    (prod.associator X (⊤_ C) Y).Hom ≫ Prod.map (𝟙 X) (prod.left_unitor Y).Hom =
      Prod.map (prod.right_unitor X).Hom (𝟙 Y) :=
  by
  tidy

end

section

variable {C} [has_binary_coproducts C]

/--  The braiding isomorphism which swaps a binary coproduct. -/
@[simps]
def coprod.braiding (P Q : C) : P ⨿ Q ≅ Q ⨿ P :=
  { Hom := coprod.desc coprod.inr coprod.inl, inv := coprod.desc coprod.inr coprod.inl }

@[reassoc]
theorem coprod.symmetry' (P Q : C) :
    coprod.desc coprod.inr coprod.inl ≫ coprod.desc coprod.inr coprod.inl = 𝟙 (P ⨿ Q) :=
  (coprod.braiding _ _).hom_inv_id

/--  The braiding isomorphism is symmetric. -/
theorem coprod.symmetry (P Q : C) : (coprod.braiding P Q).Hom ≫ (coprod.braiding Q P).Hom = 𝟙 _ :=
  coprod.symmetry' _ _

/--  The associator isomorphism for binary coproducts. -/
@[simps]
def coprod.associator (P Q R : C) : (P ⨿ Q) ⨿ R ≅ P ⨿ Q ⨿ R :=
  { Hom := coprod.desc (coprod.desc coprod.inl (coprod.inl ≫ coprod.inr)) (coprod.inr ≫ coprod.inr),
    inv := coprod.desc (coprod.inl ≫ coprod.inl) (coprod.desc (coprod.inr ≫ coprod.inl) coprod.inr) }

theorem coprod.pentagon (W X Y Z : C) :
    coprod.map (coprod.associator W X Y).Hom (𝟙 Z) ≫
        (coprod.associator W (X ⨿ Y) Z).Hom ≫ coprod.map (𝟙 W) (coprod.associator X Y Z).Hom =
      (coprod.associator (W ⨿ X) Y Z).Hom ≫ (coprod.associator W X (Y ⨿ Z)).Hom :=
  by
  simp

theorem coprod.associator_naturality {X₁ X₂ X₃ Y₁ Y₂ Y₃ : C} (f₁ : X₁ ⟶ Y₁) (f₂ : X₂ ⟶ Y₂) (f₃ : X₃ ⟶ Y₃) :
    coprod.map (coprod.map f₁ f₂) f₃ ≫ (coprod.associator Y₁ Y₂ Y₃).Hom =
      (coprod.associator X₁ X₂ X₃).Hom ≫ coprod.map f₁ (coprod.map f₂ f₃) :=
  by
  simp

variable [has_initial C]

/--  The left unitor isomorphism for binary coproducts with the initial object. -/
@[simps]
def coprod.left_unitor (P : C) : (⊥_ C) ⨿ P ≅ P :=
  { Hom := coprod.desc (initial.to P) (𝟙 _), inv := coprod.inr }

/--  The right unitor isomorphism for binary coproducts with the initial object. -/
@[simps]
def coprod.right_unitor (P : C) : P ⨿ ⊥_ C ≅ P :=
  { Hom := coprod.desc (𝟙 _) (initial.to P), inv := coprod.inl }

theorem coprod.triangle (X Y : C) :
    (coprod.associator X (⊥_ C) Y).Hom ≫ coprod.map (𝟙 X) (coprod.left_unitor Y).Hom =
      coprod.map (coprod.right_unitor X).Hom (𝟙 Y) :=
  by
  tidy

end

section ProdFunctor

variable {C} [has_binary_products C]

/--  The binary product functor. -/
@[simps]
def prod.functor : C ⥤ C ⥤ C :=
  { obj := fun X => { obj := fun Y => X ⨯ Y, map := fun Y Z => Prod.map (𝟙 X) },
    map := fun Y Z f => { app := fun T => Prod.map f (𝟙 T) } }

/--  The product functor can be decomposed. -/
def prod.functor_left_comp (X Y : C) : prod.functor.obj (X ⨯ Y) ≅ prod.functor.obj Y ⋙ prod.functor.obj X :=
  nat_iso.of_components (prod.associator _ _)
    (by
      tidy)

end ProdFunctor

section CoprodFunctor

variable {C} [has_binary_coproducts C]

/--  The binary coproduct functor. -/
@[simps]
def coprod.functor : C ⥤ C ⥤ C :=
  { obj := fun X => { obj := fun Y => X ⨿ Y, map := fun Y Z => coprod.map (𝟙 X) },
    map := fun Y Z f => { app := fun T => coprod.map f (𝟙 T) } }

/--  The coproduct functor can be decomposed. -/
def coprod.functor_left_comp (X Y : C) : coprod.functor.obj (X ⨿ Y) ≅ coprod.functor.obj Y ⋙ coprod.functor.obj X :=
  nat_iso.of_components (coprod.associator _ _)
    (by
      tidy)

end CoprodFunctor

section ProdComparison

variable {C} {D : Type u₂} [category.{v} D]

variable (F : C ⥤ D) {A A' B B' : C}

variable [has_binary_product A B] [has_binary_product A' B']

variable [has_binary_product (F.obj A) (F.obj B)] [has_binary_product (F.obj A') (F.obj B')]

/-- 
The product comparison morphism.

In `category_theory/limits/preserves` we show this is always an iso iff F preserves binary products.
-/
def prod_comparison (F : C ⥤ D) (A B : C) [has_binary_product A B] [has_binary_product (F.obj A) (F.obj B)] :
    F.obj (A ⨯ B) ⟶ F.obj A ⨯ F.obj B :=
  prod.lift (F.map Prod.fst) (F.map Prod.snd)

@[simp, reassoc]
theorem prod_comparison_fst : prod_comparison F A B ≫ Prod.fst = F.map Prod.fst :=
  prod.lift_fst _ _

@[simp, reassoc]
theorem prod_comparison_snd : prod_comparison F A B ≫ Prod.snd = F.map Prod.snd :=
  prod.lift_snd _ _

/--  Naturality of the prod_comparison morphism in both arguments. -/
@[reassoc]
theorem prod_comparison_natural (f : A ⟶ A') (g : B ⟶ B') :
    F.map (Prod.map f g) ≫ prod_comparison F A' B' = prod_comparison F A B ≫ Prod.map (F.map f) (F.map g) := by
  rw [prod_comparison, prod_comparison, prod.lift_map, ← F.map_comp, ← F.map_comp, prod.comp_lift, ← F.map_comp,
    Prod.map_fst, ← F.map_comp, Prod.map_sndₓ]

/-- 
The product comparison morphism from `F(A ⨯ -)` to `FA ⨯ F-`, whose components are given by
`prod_comparison`.
-/
@[simps]
def prod_comparison_nat_trans [has_binary_products C] [has_binary_products D] (F : C ⥤ D) (A : C) :
    prod.functor.obj A ⋙ F ⟶ F ⋙ prod.functor.obj (F.obj A) :=
  { app := fun B => prod_comparison F A B,
    naturality' := fun B B' f => by
      simp [prod_comparison_natural] }

@[reassoc]
theorem inv_prod_comparison_map_fst [is_iso (prod_comparison F A B)] :
    inv (prod_comparison F A B) ≫ F.map Prod.fst = Prod.fst := by
  simp [is_iso.inv_comp_eq]

@[reassoc]
theorem inv_prod_comparison_map_snd [is_iso (prod_comparison F A B)] :
    inv (prod_comparison F A B) ≫ F.map Prod.snd = Prod.snd := by
  simp [is_iso.inv_comp_eq]

/--  If the product comparison morphism is an iso, its inverse is natural. -/
@[reassoc]
theorem prod_comparison_inv_natural (f : A ⟶ A') (g : B ⟶ B') [is_iso (prod_comparison F A B)]
    [is_iso (prod_comparison F A' B')] :
    inv (prod_comparison F A B) ≫ F.map (Prod.map f g) = Prod.map (F.map f) (F.map g) ≫ inv (prod_comparison F A' B') :=
  by
  rw [is_iso.eq_comp_inv, category.assoc, is_iso.inv_comp_eq, prod_comparison_natural]

/-- 
The natural isomorphism `F(A ⨯ -) ≅ FA ⨯ F-`, provided each `prod_comparison F A B` is an
isomorphism (as `B` changes).
-/
@[simps (config := { rhsMd := semireducible })]
def prod_comparison_nat_iso [has_binary_products C] [has_binary_products D] (A : C)
    [∀ B, is_iso (prod_comparison F A B)] : prod.functor.obj A ⋙ F ≅ F ⋙ prod.functor.obj (F.obj A) :=
  { @as_iso _ _ _ _ _ (nat_iso.is_iso_of_is_iso_app ⟨_, _⟩) with Hom := prod_comparison_nat_trans F A }

end ProdComparison

section CoprodComparison

variable {C} {D : Type u₂} [category.{v} D]

variable (F : C ⥤ D) {A A' B B' : C}

variable [has_binary_coproduct A B] [has_binary_coproduct A' B']

variable [has_binary_coproduct (F.obj A) (F.obj B)] [has_binary_coproduct (F.obj A') (F.obj B')]

/-- 
The coproduct comparison morphism.

In `category_theory/limits/preserves` we show
this is always an iso iff F preserves binary coproducts.
-/
def coprod_comparison (F : C ⥤ D) (A B : C) [has_binary_coproduct A B] [has_binary_coproduct (F.obj A) (F.obj B)] :
    F.obj A ⨿ F.obj B ⟶ F.obj (A ⨿ B) :=
  coprod.desc (F.map coprod.inl) (F.map coprod.inr)

@[simp, reassoc]
theorem coprod_comparison_inl : coprod.inl ≫ coprod_comparison F A B = F.map coprod.inl :=
  coprod.inl_desc _ _

@[simp, reassoc]
theorem coprod_comparison_inr : coprod.inr ≫ coprod_comparison F A B = F.map coprod.inr :=
  coprod.inr_desc _ _

/--  Naturality of the coprod_comparison morphism in both arguments. -/
@[reassoc]
theorem coprod_comparison_natural (f : A ⟶ A') (g : B ⟶ B') :
    coprod_comparison F A B ≫ F.map (coprod.map f g) = coprod.map (F.map f) (F.map g) ≫ coprod_comparison F A' B' := by
  rw [coprod_comparison, coprod_comparison, coprod.map_desc, ← F.map_comp, ← F.map_comp, coprod.desc_comp, ← F.map_comp,
    coprod.inl_map, ← F.map_comp, coprod.inr_map]

/-- 
The coproduct comparison morphism from `FA ⨿ F-` to `F(A ⨿ -)`, whose components are given by
`coprod_comparison`.
-/
@[simps]
def coprod_comparison_nat_trans [has_binary_coproducts C] [has_binary_coproducts D] (F : C ⥤ D) (A : C) :
    F ⋙ coprod.functor.obj (F.obj A) ⟶ coprod.functor.obj A ⋙ F :=
  { app := fun B => coprod_comparison F A B,
    naturality' := fun B B' f => by
      simp [coprod_comparison_natural] }

@[reassoc]
theorem map_inl_inv_coprod_comparison [is_iso (coprod_comparison F A B)] :
    F.map coprod.inl ≫ inv (coprod_comparison F A B) = coprod.inl := by
  simp [is_iso.inv_comp_eq]

@[reassoc]
theorem map_inr_inv_coprod_comparison [is_iso (coprod_comparison F A B)] :
    F.map coprod.inr ≫ inv (coprod_comparison F A B) = coprod.inr := by
  simp [is_iso.inv_comp_eq]

/--  If the coproduct comparison morphism is an iso, its inverse is natural. -/
@[reassoc]
theorem coprod_comparison_inv_natural (f : A ⟶ A') (g : B ⟶ B') [is_iso (coprod_comparison F A B)]
    [is_iso (coprod_comparison F A' B')] :
    inv (coprod_comparison F A B) ≫ coprod.map (F.map f) (F.map g) =
      F.map (coprod.map f g) ≫ inv (coprod_comparison F A' B') :=
  by
  rw [is_iso.eq_comp_inv, category.assoc, is_iso.inv_comp_eq, coprod_comparison_natural]

/-- 
The natural isomorphism `FA ⨿ F- ≅ F(A ⨿ -)`, provided each `coprod_comparison F A B` is an
isomorphism (as `B` changes).
-/
@[simps (config := { rhsMd := semireducible })]
def coprod_comparison_nat_iso [has_binary_coproducts C] [has_binary_coproducts D] (A : C)
    [∀ B, is_iso (coprod_comparison F A B)] : F ⋙ coprod.functor.obj (F.obj A) ≅ coprod.functor.obj A ⋙ F :=
  { @as_iso _ _ _ _ _ (nat_iso.is_iso_of_is_iso_app ⟨_, _⟩) with Hom := coprod_comparison_nat_trans F A }

end CoprodComparison

end CategoryTheory.Limits

open CategoryTheory.Limits

namespace CategoryTheory

variable {C : Type u} [category.{v} C]

/--  Auxiliary definition for `over.coprod`. -/
@[simps]
def over.coprod_obj [has_binary_coproducts C] {A : C} : over A → over A ⥤ over A := fun f =>
  { obj := fun g => over.mk (coprod.desc f.hom g.hom), map := fun g₁ g₂ k => over.hom_mk (coprod.map (𝟙 _) k.left) }

/--  A category with binary coproducts has a functorial `sup` operation on over categories. -/
@[simps]
def over.coprod [has_binary_coproducts C] {A : C} : over A ⥤ over A ⥤ over A :=
  { obj := fun f => over.coprod_obj f,
    map := fun f₁ f₂ k =>
      { app := fun g =>
          over.hom_mk (coprod.map k.left (𝟙 _))
            (by
              dsimp
              rw [coprod.map_desc, category.id_comp, over.w k]),
        naturality' := fun f g k => by
          ext <;>
            ·
              dsimp
              simp },
    map_id' := fun X => by
      ext <;>
        ·
          dsimp
          simp ,
    map_comp' := fun X Y Z f g => by
      ext <;>
        ·
          dsimp
          simp }

end CategoryTheory

