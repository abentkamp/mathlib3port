import Mathbin.Algebra.BigOperators.Basic
import Mathbin.Algebra.BigOperators.Pi
import Mathbin.CategoryTheory.Limits.Shapes.Biproducts
import Mathbin.CategoryTheory.Preadditive.Default
import Mathbin.CategoryTheory.Preadditive.AdditiveFunctor
import Mathbin.Data.Matrix.Dmatrix

/-!
# Matrices over a category.

When `C` is a preadditive category, `Mat_ C` is the preadditive category
whose objects are finite tuples of objects in `C`, and
whose morphisms are matrices of morphisms from `C`.

There is a functor `Mat_.embedding : C ⥤ Mat_ C` sending morphisms to one-by-one matrices.

`Mat_ C` has finite biproducts.

## The additive envelope

We show that this construction is the "additive envelope" of `C`,
in the sense that any additive functor `F : C ⥤ D` to a category `D` with biproducts
lifts to a functor `Mat_.lift F : Mat_ C ⥤ D`,
Moreover, this functor is unique (up to natural isomorphisms) amongst functors `L : Mat_ C ⥤ D`
such that `embedding C ⋙ L ≅ F`.
(As we don't have 2-category theory, we can't explicitly state that `Mat_ C` is
the initial object in the 2-category of categories under `C` which have biproducts.)

As a consequence, when `C` already has finite biproducts we have `Mat_ C ≌ C`.

## Future work

We should provide a more convenient `Mat R`, when `R` is a ring,
as a category with objects `n : FinType`,
and whose morphisms are matrices with components in `R`.

Ideally this would conveniently interact with both `Mat_` and `matrix`.

-/


open CategoryTheory CategoryTheory.Preadditive

open_locale BigOperators

noncomputable section

namespace CategoryTheory

universe w v₁ v₂ u₁ u₂

variable (C : Type u₁) [category.{v₁} C] [preadditive C]

/-- An object in `Mat_ C` is a finite tuple of objects in `C`.
-/
structure Mat_ : Type max (v₁ + 1) u₁ where
  ι : Type v₁
  [f : Fintype ι]
  [d : DecidableEq ι]
  x : ι → C

attribute [instance] Mat_.F Mat_.D

namespace Mat_

variable {C}

/-- A morphism in `Mat_ C` is a dependently typed matrix of morphisms. -/
@[nolint has_inhabited_instance]
def hom (M N : Mat_ C) : Type v₁ :=
  Dmatrix M.ι N.ι fun i j => M.X i ⟶ N.X j

namespace Hom

/-- The identity matrix consists of identity morphisms on the diagonal, and zeros elsewhere. -/
def id (M : Mat_ C) : hom M M := fun i j => if h : i = j then eq_to_hom (congr_argₓ M.X h) else 0

/-- Composition of matrices using matrix multiplication. -/
def comp {M N K : Mat_ C} (f : hom M N) (g : hom N K) : hom M K := fun i k => ∑ j : N.ι, f i j ≫ g j k

end Hom

section

attribute [local simp] hom.id hom.comp

instance : category.{v₁} (Mat_ C) where
  hom := hom
  id := hom.id
  comp := fun M N K f g => f.comp g
  id_comp' := fun M N f => by
    simp [dite_comp]
  comp_id' := fun M N f => by
    simp [comp_dite]
  assoc' := fun M N K L f g h => by
    ext i k
    simp_rw [hom.comp, sum_comp, comp_sum, category.assoc]
    rw [Finset.sum_comm]

theorem id_def (M : Mat_ C) : (𝟙 M : hom M M) = fun i j => if h : i = j then eq_to_hom (congr_argₓ M.X h) else 0 :=
  rfl

theorem id_apply (M : Mat_ C) (i j : M.ι) :
    (𝟙 M : hom M M) i j = if h : i = j then eq_to_hom (congr_argₓ M.X h) else 0 :=
  rfl

@[simp]
theorem id_apply_self (M : Mat_ C) (i : M.ι) : (𝟙 M : hom M M) i i = 𝟙 _ := by
  simp [id_apply]

@[simp]
theorem id_apply_of_ne (M : Mat_ C) (i j : M.ι) (h : i ≠ j) : (𝟙 M : hom M M) i j = 0 := by
  simp [id_apply, h]

theorem comp_def {M N K : Mat_ C} (f : M ⟶ N) (g : N ⟶ K) : f ≫ g = fun i k => ∑ j : N.ι, f i j ≫ g j k :=
  rfl

@[simp]
theorem comp_apply {M N K : Mat_ C} (f : M ⟶ N) (g : N ⟶ K) i k : (f ≫ g) i k = ∑ j : N.ι, f i j ≫ g j k :=
  rfl

instance (M N : Mat_ C) : Inhabited (M ⟶ N) :=
  ⟨fun i j => (0 : M.X i ⟶ N.X j)⟩

end

instance : preadditive (Mat_ C) where
  homGroup := fun M N => by
    change AddCommGroupₓ (Dmatrix M.ι N.ι _)
    infer_instance
  add_comp' := fun M N K f f' g => by
    ext
    simp [Finset.sum_add_distrib]
  comp_add' := fun M N K f g g' => by
    ext
    simp [Finset.sum_add_distrib]

@[simp]
theorem add_apply {M N : Mat_ C} (f g : M ⟶ N) i j : (f + g) i j = f i j + g i j :=
  rfl

open CategoryTheory.Limits

/-- We now prove that `Mat_ C` has finite biproducts.

Be warned, however, that `Mat_ C` is not necessarily Krull-Schmidt,
and so the internal indexing of a biproduct may have nothing to do with the external indexing,
even though the construction we give uses a sigma type.
See however `iso_biproduct_embedding`.
-/
instance has_finite_biproducts : has_finite_biproducts (Mat_ C) where
  HasBiproductsOfShape := fun J 𝒟 ℱ =>
    { HasBiproduct := fun f =>
        has_biproduct_of_total
          { x := ⟨Σ j : J, (f j).ι, fun p => (f p.1).x p.2⟩,
            π := fun j x y => by
              dsimp  at x⊢
              refine' if h : x.1 = j then _ else 0
              refine' if h' : @Eq.ndrec J x.1 (fun j => (f j).ι) x.2 _ h = y then _ else 0
              apply eq_to_hom
              substs h h',
            ι := fun j x y => by
              dsimp  at y⊢
              refine' if h : y.1 = j then _ else 0
              refine' if h' : @Eq.ndrec J y.1 (fun j => (f j).ι) y.2 _ h = x then _ else 0
              apply eq_to_hom
              substs h h',
            ι_π := fun j j' => by
              ext x y
              dsimp
              simp_rw [dite_comp, comp_dite]
              simp only [if_t_t, dite_eq_ite, dif_ctx_congr, limits.comp_zero, limits.zero_comp, eq_to_hom_trans,
                Finset.sum_congr]
              erw [Finset.sum_sigma]
              dsimp
              simp only [if_congr, if_true, dif_ctx_congr, Finset.sum_dite_irrel, Finset.mem_univ,
                Finset.sum_const_zero, Finset.sum_congr, Finset.sum_dite_eq']
              split_ifs with h h'
              · substs h h'
                simp only [CategoryTheory.eq_to_hom_refl, CategoryTheory.Mat_.id_apply_self]
                
              · subst h
                simp only [id_apply_of_ne _ _ _ h', CategoryTheory.eq_to_hom_refl]
                
              · rfl
                 }
          (by
            dsimp
            funext i₁
            dsimp  at i₁⊢
            rcases i₁ with ⟨j₁, i₁⟩
            convert Finset.sum_apply _ _ _ using 1
            · rfl
              
            · apply heq_of_eq
              symm
              funext i₂
              rcases i₂ with ⟨j₂, i₂⟩
              simp only [comp_apply, dite_comp, comp_dite, if_t_t, dite_eq_ite, if_congr, if_true, dif_ctx_congr,
                Finset.sum_dite_irrel, Finset.sum_dite_eq, Finset.mem_univ, Finset.sum_const_zero, Finset.sum_congr,
                Finset.sum_dite_eq, Finset.sum_apply, limits.comp_zero, limits.zero_comp, eq_to_hom_trans,
                Mat_.id_apply]
              by_cases' h : j₁ = j₂
              · subst h
                simp
                
              · simp [h]
                
              ) }

end Mat_

namespace Functor

variable {C} {D : Type _} [category.{v₁} D] [preadditive D]

attribute [local simp] Mat_.id_apply

/-- A functor induces a functor of matrix categories.
-/
@[simps]
def map_Mat_ (F : C ⥤ D) [functor.additive F] : Mat_ C ⥤ Mat_ D where
  obj := fun M => ⟨M.ι, fun i => F.obj (M.X i)⟩
  map := fun M N f i j => F.map (f i j)
  map_comp' := fun M N K f g => by
    ext i k
    simp

/-- The identity functor induces the identity functor on matrix categories.
-/
@[simps]
def map_Mat_id : (𝟭 C).mapMat_ ≅ 𝟭 (Mat_ C) :=
  nat_iso.of_components
    (fun M =>
      eq_to_iso
        (by
          cases M
          rfl))
    fun M N f => by
    ext i j
    cases M
    cases N
    simp [comp_dite, dite_comp]

/-- Composite functors induce composite functors on matrix categories.
-/
@[simps]
def map_Mat_comp {E : Type _} [category.{v₁} E] [preadditive E] (F : C ⥤ D) [functor.additive F] (G : D ⥤ E)
    [functor.additive G] : (F ⋙ G).mapMat_ ≅ F.map_Mat_ ⋙ G.map_Mat_ :=
  nat_iso.of_components
    (fun M =>
      eq_to_iso
        (by
          cases M
          rfl))
    fun M N f => by
    ext i j
    cases M
    cases N
    simp [comp_dite, dite_comp]

end Functor

namespace Mat_

variable (C)

/-- The embedding of `C` into `Mat_ C` as one-by-one matrices.
(We index the summands by `punit`.) -/
@[simps]
def embedding : C ⥤ Mat_ C where
  obj := fun X => ⟨PUnit, fun _ => X⟩
  map := fun X Y f => fun _ _ => f
  map_id' := fun X => by
    ext ⟨⟩ ⟨⟩
    simp
  map_comp' := fun X Y Z f g => by
    ext ⟨⟩ ⟨⟩
    simp

namespace Embedding

instance : faithful (embedding C) where
  map_injective' := fun X Y f g h => congr_funₓ (congr_funₓ h PUnit.unit) PUnit.unit

instance : full (embedding C) where
  Preimage := fun X Y f => f PUnit.unit PUnit.unit

instance : functor.additive (embedding C) :=
  {  }

end Embedding

instance [Inhabited C] : Inhabited (Mat_ C) :=
  ⟨(embedding C).obj (default C)⟩

open CategoryTheory.Limits

variable {C}

/-- Every object in `Mat_ C` is isomorphic to the biproduct of its summands.
-/
@[simps]
def iso_biproduct_embedding (M : Mat_ C) : M ≅ ⨁ fun i => (embedding C).obj (M.X i) where
  hom := biproduct.lift fun i j k => if h : j = i then eq_to_hom (congr_argₓ M.X h) else 0
  inv := biproduct.desc fun i j k => if h : i = k then eq_to_hom (congr_argₓ M.X h) else 0
  hom_inv_id' := by
    simp only [biproduct.lift_desc]
    funext i
    dsimp
    convert Finset.sum_apply _ _ _
    · dsimp
      rfl
      
    · apply heq_of_eq
      symm
      funext j
      simp only [Finset.sum_apply]
      dsimp
      simp [dite_comp, comp_dite, Mat_.id_apply]
      
  inv_hom_id' := by
    apply biproduct.hom_ext
    intro i
    apply biproduct.hom_ext'
    intro j
    simp only [category.id_comp, category.assoc, biproduct.lift_π, biproduct.ι_desc_assoc, biproduct.ι_π]
    ext ⟨⟩ ⟨⟩
    simp [dite_comp, comp_dite]
    split_ifs
    · subst h
      simp
      
    · simp [h]
      

variable {D : Type u₁} [category.{v₁} D] [preadditive D]

/-- Every `M` is a direct sum of objects from `C`, and `F` preserves biproducts. -/
@[simps]
def additive_obj_iso_biproduct (F : Mat_ C ⥤ D) [functor.additive F] (M : Mat_ C) :
    F.obj M ≅ ⨁ fun i => F.obj ((embedding C).obj (M.X i)) :=
  F.map_iso (iso_biproduct_embedding M) ≪≫ F.map_biproduct _

variable [has_finite_biproducts D]

@[reassoc]
theorem additive_obj_iso_biproduct_naturality (F : Mat_ C ⥤ D) [functor.additive F] {M N : Mat_ C} (f : M ⟶ N) :
    F.map f ≫ (additive_obj_iso_biproduct F N).hom =
      (additive_obj_iso_biproduct F M).hom ≫ biproduct.matrix fun i j => F.map ((embedding C).map (f i j)) :=
  by
  ext
  dsimp [embedding]
  simp only [← F.map_comp, biproduct.lift_π, biproduct.matrix_π, category.assoc]
  simp only [← F.map_comp, ← F.map_sum, biproduct.lift_desc, biproduct.lift_π_assoc, comp_sum]
  simp only [comp_def, comp_dite, comp_zero, Finset.sum_dite_eq', Finset.mem_univ, if_true]
  dsimp
  simp only [Finset.sum_singleton, dite_comp, zero_comp]
  congr
  symm
  convert Finset.sum_fn _ _
  simp only [Finset.sum_fn, Finset.sum_dite_eq]
  ext
  simp

@[reassoc]
theorem additive_obj_iso_biproduct_naturality' (F : Mat_ C ⥤ D) [functor.additive F] {M N : Mat_ C} (f : M ⟶ N) :
    (additive_obj_iso_biproduct F M).inv ≫ F.map f =
      biproduct.matrix (fun i j => F.map ((embedding C).map (f i j)) : _) ≫ (additive_obj_iso_biproduct F N).inv :=
  by
  rw [iso.inv_comp_eq, ← category.assoc, iso.eq_comp_inv, additive_obj_iso_biproduct_naturality]

/-- Any additive functor `C ⥤ D` to a category `D` with finite biproducts extends to
a functor `Mat_ C ⥤ D`. -/
@[simps]
def lift (F : C ⥤ D) [functor.additive F] : Mat_ C ⥤ D where
  obj := fun X => ⨁ fun i => F.obj (X.X i)
  map := fun X Y f => biproduct.matrix fun i j => F.map (f i j)
  map_id' := fun X => by
    ext i j
    by_cases' h : i = j
    · subst h
      simp
      
    · simp [h, Mat_.id_apply]
      
  map_comp' := fun X Y Z f g => by
    ext i j
    simp

instance lift_additive (F : C ⥤ D) [functor.additive F] : functor.additive (lift F) :=
  {  }

/-- An additive functor `C ⥤ D` factors through its lift to `Mat_ C ⥤ D`. -/
@[simps]
def embedding_lift_iso (F : C ⥤ D) [functor.additive F] : embedding C ⋙ lift F ≅ F :=
  nat_iso.of_components
    (fun X => { hom := biproduct.desc fun P => 𝟙 (F.obj X), inv := biproduct.lift fun P => 𝟙 (F.obj X) }) fun X Y f =>
    by
    dsimp
    ext
    simp only [category.id_comp, biproduct.ι_desc_assoc]
    erw [biproduct.ι_matrix_assoc]
    simp

/-- `Mat_.lift F` is the unique additive functor `L : Mat_ C ⥤ D` such that `F ≅ embedding C ⋙ L`.
-/
def lift_unique (F : C ⥤ D) [functor.additive F] (L : Mat_ C ⥤ D) [functor.additive L] (α : embedding C ⋙ L ≅ F) :
    L ≅ lift F :=
  nat_iso.of_components
    (fun M =>
      additive_obj_iso_biproduct L M ≪≫
        (biproduct.map_iso fun i => α.app (M.X i)) ≪≫
          (biproduct.map_iso fun i => (embedding_lift_iso F).symm.app (M.X i)) ≪≫
            (additive_obj_iso_biproduct (lift F) M).symm)
    fun M N f => by
    dsimp only [iso.trans_hom, iso.symm_hom, biproduct.map_iso_hom]
    simp only [additive_obj_iso_biproduct_naturality_assoc]
    simp only [biproduct.matrix_map_assoc, category.assoc]
    simp only [additive_obj_iso_biproduct_naturality']
    simp only [biproduct.map_matrix_assoc, category.assoc]
    congr
    ext j k ⟨⟩
    dsimp
    simp
    convert α.hom.naturality (f j k)
    erw [biproduct.matrix_π]
    simp

/-- Two additive functors `Mat_ C ⥤ D` are naturally isomorphic if
their precompositions with `embedding C` are naturally isomorphic as functors `C ⥤ D`. -/
@[ext]
def ext {F G : Mat_ C ⥤ D} [functor.additive F] [functor.additive G] (α : embedding C ⋙ F ≅ embedding C ⋙ G) : F ≅ G :=
  lift_unique (embedding C ⋙ G) _ α ≪≫ (lift_unique _ _ (iso.refl _)).symm

/-- Natural isomorphism needed in the construction of `equivalence_self_of_has_finite_biproducts`.
-/
def equivalence_self_of_has_finite_biproducts_aux [has_finite_biproducts C] :
    embedding C ⋙ 𝟭 (Mat_ C) ≅ embedding C ⋙ lift (𝟭 C) ⋙ embedding C :=
  functor.right_unitor _ ≪≫
    (functor.left_unitor _).symm ≪≫ iso_whisker_right (embedding_lift_iso _).symm _ ≪≫ functor.associator _ _ _

/-- A preadditive category that already has finite biproducts is equivalent to its additive envelope.

Note that we only prove this for a large category;
otherwise there are universe issues that I haven't attempted to sort out.
-/
def equivalence_self_of_has_finite_biproducts (C : Type (u₁ + 1)) [large_category C] [preadditive C]
    [has_finite_biproducts C] : Mat_ C ≌ C :=
  equivalence.mk (lift (𝟭 C)) (embedding C) (ext equivalence_self_of_has_finite_biproducts_aux)
    (embedding_lift_iso (𝟭 C))

@[simp]
theorem equivalence_self_of_has_finite_biproducts_functor {C : Type (u₁ + 1)} [large_category C] [preadditive C]
    [has_finite_biproducts C] : (equivalence_self_of_has_finite_biproducts C).Functor = lift (𝟭 C) :=
  rfl

@[simp]
theorem equivalence_self_of_has_finite_biproducts_inverse {C : Type (u₁ + 1)} [large_category C] [preadditive C]
    [has_finite_biproducts C] : (equivalence_self_of_has_finite_biproducts C).inverse = embedding C :=
  rfl

end Mat_

end CategoryTheory

