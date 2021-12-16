import Mathbin.LinearAlgebra.Matrix.ToLin

/-!
# Diagonal matrices

This file contains some results on the linear map corresponding to a
diagonal matrix (`range`, `ker` and `rank`).

## Tags

matrix, diagonal, linear_map
-/


noncomputable section 

open LinearMap Matrix Set Submodule

open_locale BigOperators

open_locale Matrix

universe u v w

namespace Matrix

section CommRingₓ

variable {n : Type _} [Fintype n] [DecidableEq n] {R : Type v} [CommRingₓ R]

theorem proj_diagonal (i : n) (w : n → R) : (proj i).comp (to_lin' (diagonal w)) = w i • proj i :=
  by 
    ext j <;> simp [mul_vec_diagonal]

theorem diagonal_comp_std_basis (w : n → R) (i : n) :
  (diagonal w).toLin'.comp (LinearMap.stdBasis R (fun _ : n => R) i) = w i • LinearMap.stdBasis R (fun _ : n => R) i :=
  by 
    ext j 
    simpRw [LinearMap.comp_apply, to_lin'_apply, mul_vec_diagonal, LinearMap.smul_apply, Pi.smul_apply,
      Algebra.id.smul_eq_mul]
    byCases' i = j
    ·
      subst h
    ·
      rw [std_basis_ne R (fun _ : n => R) _ _ (Ne.symm h), _root_.mul_zero, _root_.mul_zero]

theorem diagonal_to_lin' (w : n → R) : (diagonal w).toLin' = LinearMap.pi fun i => w i • LinearMap.proj i :=
  by 
    ext v j <;> simp [mul_vec_diagonal]

end CommRingₓ

section Field

variable {m n : Type _} [Fintype m] [Fintype n]

variable {K : Type u} [Field K]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » {i | «expr = »(w i, 0)})
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  ker_diagonal_to_lin'
  [ DecidableEq m ] ( w : m → K )
    : ker diagonal w . toLin' = ⨆ ( i : _ ) ( _ : i ∈ { i | w i = 0 } ) , range LinearMap.stdBasis K fun i => K i
  :=
    by
      rw [ ← comap_bot , ← infi_ker_proj , comap_infi ]
        have := fun i : m => ker_comp to_lin' diagonal w proj i
        simp only [ comap_infi , ← this , proj_diagonal , ker_smul' ]
        have : univ ⊆ { i : m | w i = 0 } ∪ { i : m | w i = 0 } ᶜ
        · rw [ Set.union_compl_self ]
        exact
          supr_range_std_basis_eq_infi_ker_proj K fun i : m => K disjoint_compl_right this finite.of_fintype _ . symm

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » {i | «expr ≠ »(w i, 0)})
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  range_diagonal
  [ DecidableEq m ] ( w : m → K )
    : diagonal w . toLin' . range = ⨆ ( i : _ ) ( _ : i ∈ { i | w i ≠ 0 } ) , LinearMap.stdBasis K fun i => K i . range
  :=
    by
      dsimp only [ mem_set_of_eq ]
        rw [ ← map_top , ← supr_range_std_basis , map_supr ]
        congr
        funext i
        rw [ ← LinearMap.range_comp , diagonal_comp_std_basis , ← range_smul' ]

theorem rank_diagonal [DecidableEq m] [DecidableEq K] (w : m → K) :
  rank (diagonal w).toLin' = Fintype.card { i // w i ≠ 0 } :=
  by 
    have hu : univ ⊆ { i : m | w i = 0 }ᶜ ∪ { i : m | w i = 0 }
    ·
      rw [Set.compl_union_self]
    have hd : Disjoint { i : m | w i ≠ 0 } { i : m | w i = 0 } := disjoint_compl_left 
    have B₁ := supr_range_std_basis_eq_infi_ker_proj K (fun i : m => K) hd hu (finite.of_fintype _)
    have B₂ :=
      @infi_ker_proj_equiv K _ _ (fun i : m => K) _ _ _ _
        (by 
          simp  <;> infer_instance)
        hd hu 
    rw [rank, range_diagonal, B₁, ←@dim_fun' K]
    apply LinearEquiv.dim_eq 
    apply B₂

end Field

end Matrix

