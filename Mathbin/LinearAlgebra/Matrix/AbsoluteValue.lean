/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import Mathbin.Data.Int.AbsoluteValue
import Mathbin.LinearAlgebra.Matrix.Determinant

/-!
# Absolute values and matrices

This file proves some bounds on matrices involving absolute values.

## Main results

 * `matrix.det_le`: if the entries of an `n × n` matrix are bounded by `x`,
   then the determinant is bounded by `n! x^n`
 * `matrix.det_sum_le`: if we have `s` `n × n` matrices and the entries of each
   matrix are bounded by `x`, then the determinant of their sum is bounded by `n! (s * x)^n`
 * `matrix.det_sum_smul_le`: if we have `s` `n × n` matrices each multiplied by
   a constant bounded by `y`, and the entries of each matrix are bounded by `x`,
   then the determinant of the linear combination is bounded by `n! (s * y * x)^n`
-/


open BigOperators

open Matrix

namespace Matrix

open Equivₓ Finset

variable {R S : Type _} [CommRingₓ R] [Nontrivial R] [LinearOrderedCommRing S]

variable {n : Type _} [Fintype n] [DecidableEq n]

theorem det_le {A : Matrix n n R} {abv : AbsoluteValue R S} {x : S} (hx : ∀ i j, abv (A i j) ≤ x) :
    abv A.det ≤ Nat.factorial (Fintype.card n) • x ^ Fintype.card n :=
  calc
    abv A.det = abv (∑ σ : Perm n, _) := congr_argₓ abv (det_apply _)
    _ ≤ ∑ σ : Perm n, abv _ := abv.sum_le _ _
    _ = ∑ σ : Perm n, ∏ i, abv (A (σ i) i) :=
      sum_congr rfl fun σ hσ => by
        rw [abv.map_units_int_smul, abv.map_prod]
    _ ≤ ∑ σ : Perm n, ∏ i : n, x := sum_le_sum fun _ _ => prod_le_prod (fun _ _ => abv.Nonneg _) fun _ _ => hx _ _
    _ = ∑ σ : Perm n, x ^ Fintype.card n :=
      sum_congr rfl fun _ _ => by
        rw [prod_const, Finset.card_univ]
    _ = Nat.factorial (Fintype.card n) • x ^ Fintype.card n := by
      rw [sum_const, Finset.card_univ, Fintype.card_perm]
    

theorem det_sum_le {ι : Type _} (s : Finset ι) {A : ι → Matrix n n R} {abv : AbsoluteValue R S} {x : S}
    (hx : ∀ k i j, abv (A k i j) ≤ x) :
    abv (det (∑ k in s, A k)) ≤ Nat.factorial (Fintype.card n) • (Finset.card s • x) ^ Fintype.card n :=
  det_le fun i j =>
    calc
      abv ((∑ k in s, A k) i j) = abv (∑ k in s, A k i j) := by
        simp only [sum_apply]
      _ ≤ ∑ k in s, abv (A k i j) := abv.sum_le _ _
      _ ≤ ∑ k in s, x := sum_le_sum fun k _ => hx k i j
      _ = s.card • x := sum_const _
      

theorem det_sum_smul_le {ι : Type _} (s : Finset ι) {c : ι → R} {A : ι → Matrix n n R} {abv : AbsoluteValue R S} {x : S}
    (hx : ∀ k i j, abv (A k i j) ≤ x) {y : S} (hy : ∀ k, abv (c k) ≤ y) :
    abv (det (∑ k in s, c k • A k)) ≤ Nat.factorial (Fintype.card n) • (Finset.card s • y * x) ^ Fintype.card n := by
  simpa only [smul_mul_assoc] using
    det_sum_le s fun k i j =>
      calc
        abv (c k * A k i j) = abv (c k) * abv (A k i j) := abv.map_mul _ _
        _ ≤ y * x := mul_le_mul (hy k) (hx k i j) (abv.nonneg _) ((abv.nonneg _).trans (hy k))
        

end Matrix

