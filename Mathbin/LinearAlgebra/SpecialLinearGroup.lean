import Mathbin.LinearAlgebra.Matrix.Adjugate 
import Mathbin.LinearAlgebra.Matrix.ToLin

/-!
# The Special Linear group $SL(n, R)$

This file defines the elements of the Special Linear group `special_linear_group n R`, consisting
of all square `R`-matrices with determinant `1` on the fintype `n` by `n`.  In addition, we define
the group structure on `special_linear_group n R` and the embedding into the general linear group
`general_linear_group R (n → R)`.

## Main definitions

 * `matrix.special_linear_group` is the type of matrices with determinant 1
 * `matrix.special_linear_group.group` gives the group structure (under multiplication)
 * `matrix.special_linear_group.to_GL` is the embedding `SLₙ(R) → GLₙ(R)`

## Notation

For `m : ℕ`, we introduce the notation `SL(m,R)` for the special linear group on the fintype
`n = fin m`, in the locale `matrix_groups`.

## Implementation notes
The inverse operation in the `special_linear_group` is defined to be the adjugate
matrix, so that `special_linear_group n R` has a group structure for all `comm_ring R`.

We define the elements of `special_linear_group` to be matrices, since we need to
compute their determinant. This is in contrast with `general_linear_group R M`,
which consists of invertible `R`-linear maps on `M`.

We provide `matrix.special_linear_group.has_coe_to_fun` for convenience, but do not state any
lemmas about it, and use `matrix.special_linear_group.coe_fn_eq_coe` to eliminate it `⇑` in favor
of a regular `↑` coercion.

## References

 * https://en.wikipedia.org/wiki/Special_linear_group

## Tags

matrix group, group, matrix inverse
-/


namespace Matrix

universe u v

open_locale Matrix

open LinearMap

section 

variable(n : Type u)[DecidableEq n][Fintype n](R : Type v)[CommRingₓ R]

/-- `special_linear_group n R` is the group of `n` by `n` `R`-matrices with determinant equal to 1.
-/
def special_linear_group :=
  { A : Matrix n n R // A.det = 1 }

end 

localized [MatrixGroups] notation "SL(" n "," R ")" => special_linear_group (Finₓ n) R

namespace SpecialLinearGroup

variable{n : Type u}[DecidableEq n][Fintype n]{R : Type v}[CommRingₓ R]

instance has_coe_to_matrix : Coe (special_linear_group n R) (Matrix n n R) :=
  ⟨fun A => A.val⟩

local prefix:1024 "↑ₘ" => @coeₓ _ (Matrix n n R) _

theorem ext_iff (A B : special_linear_group n R) : A = B ↔ ∀ i j, ↑ₘA i j = ↑ₘB i j :=
  Subtype.ext_iff.trans Matrix.ext_iff.symm

@[ext]
theorem ext (A B : special_linear_group n R) : (∀ i j, ↑ₘA i j = ↑ₘB i j) → A = B :=
  (special_linear_group.ext_iff A B).mpr

instance HasInv : HasInv (special_linear_group n R) :=
  ⟨fun A =>
      ⟨adjugate A,
        by 
          rw [det_adjugate, A.prop, one_pow]⟩⟩

instance Mul : Mul (special_linear_group n R) :=
  ⟨fun A B =>
      ⟨A.1 ⬝ B.1,
        by 
          erw [det_mul, A.2, B.2, one_mulₓ]⟩⟩

instance HasOne : HasOne (special_linear_group n R) :=
  ⟨⟨1, det_one⟩⟩

instance  : Inhabited (special_linear_group n R) :=
  ⟨1⟩

section CoeLemmas

variable(A B : special_linear_group n R)

@[simp]
theorem coe_inv : ↑ₘ(A⁻¹) = adjugate A :=
  rfl

@[simp]
theorem coe_mul : ↑ₘ(A*B) = ↑ₘA ⬝ ↑ₘB :=
  rfl

@[simp]
theorem coe_one : ↑ₘ(1 : special_linear_group n R) = (1 : Matrix n n R) :=
  rfl

@[simp]
theorem det_coe : det ↑ₘA = 1 :=
  A.2

theorem det_ne_zero [Nontrivial R] (g : special_linear_group n R) : det ↑ₘg ≠ 0 :=
  by 
    rw [g.det_coe]
    normNum

theorem row_ne_zero [Nontrivial R] (g : special_linear_group n R) (i : n) : ↑ₘg i ≠ 0 :=
  fun h =>
    g.det_ne_zero$
      det_eq_zero_of_row_eq_zero i$
        by 
          simp [h]

end CoeLemmas

instance  : Monoidₓ (special_linear_group n R) :=
  Function.Injective.monoid coeₓ Subtype.coe_injective coe_one coe_mul

instance  : Groupₓ (special_linear_group n R) :=
  { special_linear_group.monoid, special_linear_group.has_inv with
    mul_left_inv :=
      fun A =>
        by 
          ext1 
          simp [adjugate_mul] }

/-- A version of `matrix.to_lin' A` that produces linear equivalences. -/
def to_lin' : special_linear_group n R →* (n → R) ≃ₗ[R] n → R :=
  { toFun :=
      fun A =>
        LinearEquiv.ofLinear (Matrix.toLin' ↑ₘA) (Matrix.toLin' ↑ₘ(A⁻¹))
          (by 
            rw [←to_lin'_mul, ←coe_mul, mul_right_invₓ, coe_one, to_lin'_one])
          (by 
            rw [←to_lin'_mul, ←coe_mul, mul_left_invₓ, coe_one, to_lin'_one]),
    map_one' := LinearEquiv.to_linear_map_injective Matrix.to_lin'_one,
    map_mul' := fun A B => LinearEquiv.to_linear_map_injective$ Matrix.to_lin'_mul A B }

theorem to_lin'_apply (A : special_linear_group n R) (v : n → R) :
  special_linear_group.to_lin' A v = Matrix.toLin' (↑ₘA) v :=
  rfl

theorem to_lin'_to_linear_map (A : special_linear_group n R) :
  «expr↑ » (special_linear_group.to_lin' A) = Matrix.toLin' ↑ₘA :=
  rfl

theorem to_lin'_symm_apply (A : special_linear_group n R) (v : n → R) : A.to_lin'.symm v = Matrix.toLin' (↑ₘ(A⁻¹)) v :=
  rfl

theorem to_lin'_symm_to_linear_map (A : special_linear_group n R) : «expr↑ » A.to_lin'.symm = Matrix.toLin' ↑ₘ(A⁻¹) :=
  rfl

theorem to_lin'_injective : Function.Injective («expr⇑ » (to_lin' : special_linear_group n R →* (n → R) ≃ₗ[R] n → R)) :=
  fun A B h => Subtype.coe_injective$ Matrix.toLin'.Injective$ LinearEquiv.to_linear_map_injective.eq_iff.mpr h

/-- `to_GL` is the map from the special linear group to the general linear group -/
def to_GL : special_linear_group n R →* general_linear_group R (n → R) :=
  (general_linear_group.general_linear_equiv _ _).symm.toMonoidHom.comp to_lin'

theorem coe_to_GL (A : special_linear_group n R) : «expr↑ » A.to_GL = A.to_lin'.to_linear_map :=
  rfl

section Neg

variable[Fact (Even (Fintype.card n))]

/-- Formal operation of negation on special linear group on even cardinality `n` given by negating
each element. -/
instance  : Neg (special_linear_group n R) :=
  ⟨fun g =>
      ⟨-g,
        by 
          simpa [Nat.neg_one_pow_of_even (Fact.out (Even (Fintype.card n))), g.det_coe] using det_smul (↑ₘg) (-1)⟩⟩

@[simp]
theorem coe_neg (g : special_linear_group n R) : «expr↑ » (-g) = -(«expr↑ » g : Matrix n n R) :=
  rfl

end Neg

section CoeFnInstance

/-- This instance is here for convenience, but is not the simp-normal form. -/
instance  : CoeFun (special_linear_group n R) fun _ => n → n → R :=
  { coe := fun A => A.val }

@[simp]
theorem coe_fn_eq_coe (s : special_linear_group n R) : «expr⇑ » s = ↑ₘs :=
  rfl

end CoeFnInstance

end SpecialLinearGroup

end Matrix

