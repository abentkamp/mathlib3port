/-
Copyright (c) 2022 Julian Kuelshammer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Julian Kuelshammer
-/
import Mathbin.CategoryTheory.Preadditive.Default
import Mathbin.CategoryTheory.Monad.Algebra
import Mathbin.CategoryTheory.Preadditive.AdditiveFunctor

/-!
# Preadditive structure on algebras over a monad

If `C` is a preadditive categories and `T` is an additive monad on `C` then `algebra T` is also
preadditive. Dually, if `U` is an additive comonad on `C` then `coalgebra U` is preadditive as well.

-/


universe v₁ u₁

-- morphism levels before object levels. See note [category_theory universes].
namespace CategoryTheory

variable (C : Type u₁) [Category.{v₁} C] [Preadditive C] (T : Monad C) [Functor.Additive (T : C ⥤ C)]

open CategoryTheory.Limits Preadditive

/-- The category of algebras over an additive monad on a preadditive category is preadditive. -/
@[simps]
instance Monad.algebraPreadditive : Preadditive (Monad.Algebra T) where
  homGroup := fun F G =>
    { add := fun α β =>
        { f := α.f + β.f,
          h' := by
            simp only [functor.map_add, add_comp, monad.algebra.hom.h, comp_add] },
      zero :=
        { f := 0,
          h' := by
            simp only [functor.map_zero, zero_comp, comp_zero] },
      nsmul := fun n α =>
        { f := n • α.f,
          h' := by
            rw [functor.map_nsmul, nsmul_comp, monad.algebra.hom.h, comp_nsmul] },
      neg := fun α =>
        { f := -α.f,
          h' := by
            simp only [functor.map_neg, neg_comp, monad.algebra.hom.h, comp_neg] },
      sub := fun α β =>
        { f := α.f - β.f,
          h' := by
            simp only [functor.map_sub, sub_comp, monad.algebra.hom.h, comp_sub] },
      zsmul := fun r α =>
        { f := r • α.f,
          h' := by
            rw [functor.map_zsmul, zsmul_comp, monad.algebra.hom.h, comp_zsmul] },
      add_assoc := by
        intros
        ext
        apply add_assocₓ,
      zero_add := by
        intros
        ext
        apply zero_addₓ,
      add_zero := by
        intros
        ext
        apply add_zeroₓ,
      nsmul_zero' := by
        intros
        ext
        apply zero_smul,
      nsmul_succ' := by
        intros
        ext
        apply succ_nsmul,
      sub_eq_add_neg := by
        intros
        ext
        apply sub_eq_add_neg,
      zsmul_zero' := by
        intros
        ext
        apply zero_smul,
      zsmul_succ' := by
        intros
        ext
        dsimp'
        simp only [coe_nat_zsmul, succ_nsmul]
        rfl,
      zsmul_neg' := by
        intros
        ext
        simp only [zsmul_neg_succ_of_nat, neg_inj, nsmul_eq_smul_cast ℤ],
      add_left_neg := by
        intros
        ext
        apply add_left_negₓ,
      add_comm := by
        intros
        ext
        apply add_commₓ }
  add_comp' := by
    intros
    ext
    apply add_comp
  comp_add' := by
    intros
    ext
    apply comp_add

instance Monad.forget_additive : (Monad.forget T).Additive where

variable (U : Comonad C) [Functor.Additive (U : C ⥤ C)]

/-- The category of coalgebras over an additive comonad on a preadditive category is preadditive. -/
@[simps]
instance Comonad.coalgebraPreadditive : Preadditive (Comonad.Coalgebra U) where
  homGroup := fun F G =>
    { add := fun α β =>
        { f := α.f + β.f,
          h' := by
            simp only [functor.map_add, comp_add, comonad.coalgebra.hom.h, add_comp] },
      zero :=
        { f := 0,
          h' := by
            simp only [functor.map_zero, comp_zero, zero_comp] },
      nsmul := fun n α =>
        { f := n • α.f,
          h' := by
            rw [functor.map_nsmul, comp_nsmul, comonad.coalgebra.hom.h, nsmul_comp] },
      neg := fun α =>
        { f := -α.f,
          h' := by
            simp only [functor.map_neg, comp_neg, comonad.coalgebra.hom.h, neg_comp] },
      sub := fun α β =>
        { f := α.f - β.f,
          h' := by
            simp only [functor.map_sub, comp_sub, comonad.coalgebra.hom.h, sub_comp] },
      zsmul := fun r α =>
        { f := r • α.f,
          h' := by
            rw [functor.map_zsmul, comp_zsmul, comonad.coalgebra.hom.h, zsmul_comp] },
      add_assoc := by
        intros
        ext
        apply add_assocₓ,
      zero_add := by
        intros
        ext
        apply zero_addₓ,
      add_zero := by
        intros
        ext
        apply add_zeroₓ,
      nsmul_zero' := by
        intros
        ext
        apply zero_smul,
      nsmul_succ' := by
        intros
        ext
        apply succ_nsmul,
      sub_eq_add_neg := by
        intros
        ext
        apply sub_eq_add_neg,
      zsmul_zero' := by
        intros
        ext
        apply zero_smul,
      zsmul_succ' := by
        intros
        ext
        dsimp'
        simp only [coe_nat_zsmul, succ_nsmul]
        rfl,
      zsmul_neg' := by
        intros
        ext
        simp only [zsmul_neg_succ_of_nat, neg_inj, nsmul_eq_smul_cast ℤ],
      add_left_neg := by
        intros
        ext
        apply add_left_negₓ,
      add_comm := by
        intros
        ext
        apply add_commₓ }
  add_comp' := by
    intros
    ext
    apply add_comp
  comp_add' := by
    intros
    ext
    apply comp_add

instance Comonad.forget_additive : (Comonad.forget U).Additive where

end CategoryTheory

