/-
Copyright (c) 2021 Alena Gusakov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alena Gusakov
-/
import Mathbin.Combinatorics.SimpleGraph.Basic
import Mathbin.Data.Set.Finite

/-!
# Strongly regular graphs

## Main definitions

* `G.is_SRG_with n k ℓ μ` (see `simple_graph.is_SRG_with`) is a structure for
  a `simple_graph` satisfying the following conditions:
  * The cardinality of the vertex set is `n`
  * `G` is a regular graph with degree `k`
  * The number of common neighbors between any two adjacent vertices in `G` is `ℓ`
  * The number of common neighbors between any two nonadjacent vertices in `G` is `μ`

## TODO
- Prove that the parameters of a strongly regular graph
  obey the relation `(n - k - 1) * μ = k * (k - ℓ - 1)`
- Prove that if `I` is the identity matrix and `J` is the all-one matrix,
  then the adj matrix `A` of SRG obeys relation `A^2 = kI + ℓA + μ(J - I - A)`
-/


open Finset

universe u

namespace SimpleGraph

variable {V : Type u}

variable [Fintype V] [DecidableEq V]

variable (G : SimpleGraph V) [DecidableRel G.Adj]

/-- A graph is strongly regular with parameters `n k ℓ μ` if
 * its vertex set has cardinality `n`
 * it is regular with degree `k`
 * every pair of adjacent vertices has `ℓ` common neighbors
 * every pair of nonadjacent vertices has `μ` common neighbors
-/
structure IsSRGWith (n k ℓ μ : ℕ) : Prop where
  card : Fintype.card V = n
  regular : G.IsRegularOfDegree k
  of_adj : ∀ v w : V, G.Adj v w → Fintype.card (G.CommonNeighbors v w) = ℓ
  of_not_adj : ∀ v w : V, v ≠ w → ¬G.Adj v w → Fintype.card (G.CommonNeighbors v w) = μ

variable {G} {n k ℓ μ : ℕ}

/-- Empty graphs are strongly regular. Note that `ℓ` can take any value
  for empty graphs, since there are no pairs of adjacent vertices. -/
theorem bot_strongly_regular : (⊥ : SimpleGraph V).IsSRGWith (Fintype.card V) 0 ℓ 0 :=
  { card := rfl, regular := bot_degree, of_adj := fun v w h => h.elim,
    of_not_adj := fun v w h => by
      simp only [card_eq_zero, filter_congr_decidable, Fintype.card_of_finset, forall_true_left, not_false_iff, bot_adj]
      ext
      simp [mem_common_neighbors] }

/-- Complete graphs are strongly regular. Note that `μ` can take any value
  for complete graphs, since there are no distinct pairs of non-adjacent vertices. -/
theorem IsSRGWith.top : (⊤ : SimpleGraph V).IsSRGWith (Fintype.card V) (Fintype.card V - 1) (Fintype.card V - 2) μ :=
  { card := rfl, regular := IsRegularOfDegree.top,
    of_adj := fun v w h => by
      rw [card_common_neighbors_top]
      exact h,
    of_not_adj := fun v w h h' =>
      False.elim <| by
        simpa using h }

theorem IsSRGWith.card_neighbor_finset_union_eq {v w : V} (h : G.IsSRGWith n k ℓ μ) :
    (G.neighborFinset v ∪ G.neighborFinset w).card = 2 * k - Fintype.card (G.CommonNeighbors v w) := by
  apply @Nat.add_right_cancel _ (Fintype.card (G.common_neighbors v w))
  rw [Nat.sub_add_cancelₓ, ← Set.to_finset_card]
  · simp [neighbor_finset, common_neighbors, Set.to_finset_inter, Finset.card_union_add_card_inter, h.regular.degree_eq,
      two_mul]
    
  · apply le_transₓ (card_common_neighbors_le_degree_left _ _ _)
    simp [h.regular.degree_eq, two_mul]
    

/-- Assuming `G` is strongly regular, `2*(k + 1) - m` in `G` is the number of vertices that are
  adjacent to either `v` or `w` when `¬G.adj v w`. So it's the cardinality of
  `G.neighbor_set v ∪ G.neighbor_set w`. -/
theorem IsSRGWith.card_neighbor_finset_union_of_not_adj {v w : V} (h : G.IsSRGWith n k ℓ μ) (hne : v ≠ w)
    (ha : ¬G.Adj v w) : (G.neighborFinset v ∪ G.neighborFinset w).card = 2 * k - μ := by
  rw [← h.of_not_adj v w hne ha]
  apply h.card_neighbor_finset_union_eq

theorem IsSRGWith.card_neighbor_finset_union_of_adj {v w : V} (h : G.IsSRGWith n k ℓ μ) (ha : G.Adj v w) :
    (G.neighborFinset v ∪ G.neighborFinset w).card = 2 * k - ℓ := by
  rw [← h.of_adj v w ha]
  apply h.card_neighbor_finset_union_eq

theorem compl_neighbor_finset_sdiff_inter_eq {v w : V} :
    G.neighborFinset vᶜ \ {v} ∩ (G.neighborFinset wᶜ \ {w}) =
      (G.neighborFinset vᶜ ∩ G.neighborFinset wᶜ) \ ({w} ∪ {v}) :=
  by
  ext
  rw [← not_iff_not]
  simp [imp_iff_not_or, or_assoc, or_comm, Or.left_comm]

theorem sdiff_compl_neighbor_finset_inter_eq {v w : V} (h : G.Adj v w) :
    (G.neighborFinset vᶜ ∩ G.neighborFinset wᶜ) \ ({w} ∪ {v}) = G.neighborFinset vᶜ ∩ G.neighborFinset wᶜ := by
  ext
  simp only [and_imp, mem_union, mem_sdiff, mem_compl, and_iff_left_iff_imp, mem_neighbor_finset, mem_inter,
    mem_singleton]
  rintro hnv hnw (rfl | rfl)
  · exact hnv h
    
  · apply hnw
    rwa [adj_comm]
    

theorem IsSRGWith.compl_is_regular (h : G.IsSRGWith n k ℓ μ) : Gᶜ.IsRegularOfDegree (n - k - 1) := by
  rw [← h.card, Nat.sub_sub, add_commₓ, ← Nat.sub_sub]
  exact h.regular.compl

theorem IsSRGWith.card_common_neighbors_eq_of_adj_compl (h : G.IsSRGWith n k ℓ μ) {v w : V} (ha : Gᶜ.Adj v w) :
    Fintype.card ↥(Gᶜ.CommonNeighbors v w) = n - (2 * k - μ) - 2 := by
  simp only [← Set.to_finset_card, common_neighbors, Set.to_finset_inter, neighbor_set_compl, Set.to_finset_diff,
    Set.to_finset_singleton, Set.to_finset_compl, ← neighbor_finset_def]
  simp_rw [compl_neighbor_finset_sdiff_inter_eq]
  have hne : v ≠ w := ne_of_adj _ ha
  rw [compl_adj] at ha
  rw [card_sdiff, ← insert_eq, card_insert_of_not_mem, card_singleton, ← Finset.compl_union]
  · change 1 + 1 with 2
    rw [card_compl, h.card_neighbor_finset_union_of_not_adj hne ha.2, ← h.card]
    
  · simp only [hne.symm, not_false_iff, mem_singleton]
    
  · intro u
    simp only [mem_union, mem_compl, mem_neighbor_finset, mem_inter, mem_singleton]
    rintro (rfl | rfl) <;> simpa [adj_comm] using ha.2
    

theorem IsSRGWith.card_common_neighbors_eq_of_not_adj_compl (h : G.IsSRGWith n k ℓ μ) {v w : V} (hn : v ≠ w)
    (hna : ¬Gᶜ.Adj v w) : Fintype.card ↥(Gᶜ.CommonNeighbors v w) = n - (2 * k - ℓ) := by
  simp only [← Set.to_finset_card, common_neighbors, Set.to_finset_inter, neighbor_set_compl, Set.to_finset_diff,
    Set.to_finset_singleton, Set.to_finset_compl, ← neighbor_finset_def]
  simp only [not_and, not_not, compl_adj] at hna
  have h2' := hna hn
  simp_rw [compl_neighbor_finset_sdiff_inter_eq, sdiff_compl_neighbor_finset_inter_eq h2']
  rwa [← Finset.compl_union, card_compl, h.card_neighbor_finset_union_of_adj, ← h.card]

/-- The complement of a strongly regular graph is strongly regular. -/
theorem IsSRGWith.compl (h : G.IsSRGWith n k ℓ μ) :
    Gᶜ.IsSRGWith n (n - k - 1) (n - (2 * k - μ) - 2) (n - (2 * k - ℓ)) :=
  { card := h.card, regular := h.compl_is_regular, of_adj := fun v w ha => h.card_common_neighbors_eq_of_adj_compl ha,
    of_not_adj := fun v w hn hna => h.card_common_neighbors_eq_of_not_adj_compl hn hna }

end SimpleGraph

