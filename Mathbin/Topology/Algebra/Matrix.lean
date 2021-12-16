import Mathbin.LinearAlgebra.Determinant 
import Mathbin.Topology.Algebra.Ring

/-!
# Topological properties of matrices

This file is a place to collect topological results about matrices.

## Main definitions:

 * `continuous_det`: the determinant is continuous over a topological ring.
-/


open Matrix

variable {ι k : Type _} [TopologicalSpace k]

instance : TopologicalSpace (Matrix ι ι k) :=
  Pi.topologicalSpace

variable [Fintype ι] [DecidableEq ι] [CommRingₓ k] [TopologicalRing k]

theorem continuous_det : Continuous (det : Matrix ι ι k → k) :=
  by 
    suffices  : ∀ n : ℕ, Continuous fun A : Matrix (Finₓ n) (Finₓ n) k => Matrix.det A
    ·
      have h : (det : Matrix ι ι k → k) = (det ∘ reindex (Fintype.equivFin ι) (Fintype.equivFin ι))
      ·
        ext 
        simp 
      rw [h]
      apply (this (Fintype.card ι)).comp 
      exact continuous_pi fun i => continuous_pi fun j => continuous_apply_apply _ _ 
    intro n 
    induction' n with n ih
    ·
      simpRw [coe_det_is_empty]
      exact continuous_const 
    simpRw [det_succ_column_zero]
    refine' continuous_finset_sum _ fun l _ => _ 
    refine' (continuous_const.mul (continuous_apply_apply _ _)).mul (ih.comp _)
    exact continuous_pi fun i => continuous_pi fun j => continuous_apply_apply _ _

