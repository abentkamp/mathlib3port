/-
Copyright (c) 2022 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import Mathbin.Algebra.BigOperators.Fin
import Mathbin.Data.Finset.NatAntidiagonal
import Mathbin.Data.Fin.VecNotation
import Mathbin.Logic.Equiv.Fin

/-!
# Collections of tuples of naturals with the same sum

This file generalizes `list.nat.antidiagonal n`, `multiset.nat.antidiagonal n`, and
`finset.nat.antidiagonal n` from the pair of elements `x : ℕ × ℕ` such that `n = x.1 + x.2`, to
the sequence of elements `x : fin k → ℕ` such that `n = ∑ i, x i`.

## Main definitions

* `list.nat.antidiagonal_tuple`
* `multiset.nat.antidiagonal_tuple`
* `finset.nat.antidiagonal_tuple`

## Main results

* `antidiagonal_tuple 2 n` is analogous to `antidiagonal n`:

  * `list.nat.antidiagonal_tuple_two`
  * `multiset.nat.antidiagonal_tuple_two`
  * `finset.nat.antidiagonal_tuple_two`

## Implementation notes

While we could implement this by filtering `(fintype.pi_finset $ λ _, range (n + 1))` or similar,
this implementation would be much slower.

In the future, we could consider generalizing `finset.nat.antidiagonal_tuple` further to
support finitely-supported functions, as is done with `cut` in
`archive/100-theorems-list/45_partition.lean`.
-/


open BigOperators

/-! ### Lists -/


namespace List.Nat

/-- `list.antidiagonal_tuple k n` is a list of all `k`-tuples which sum to `n`.

This list contains no duplicates (`list.nat.nodup_antidiagonal_tuple`), and is sorted
lexicographically (`list.nat.antidiagonal_tuple_pairwise_pi_lex`), starting with `![0, ..., n]`
and ending with `![n, ..., 0]`.

```
#eval antidiagonal_tuple 3 2
-- [![0, 0, 2], ![0, 1, 1], ![0, 2, 0], ![1, 0, 1], ![1, 1, 0], ![2, 0, 0]]
```
-/
def antidiagonalTuple : ∀ k, ℕ → List (Finₓ k → ℕ)
  | 0, 0 => [![]]
  | 0, n + 1 => []
  | k + 1, n => (List.Nat.antidiagonal n).bind fun ni => (antidiagonal_tuple k ni.2).map fun x => Finₓ.cons ni.1 x

@[simp]
theorem antidiagonal_tuple_zero_zero : antidiagonalTuple 0 0 = [![]] :=
  rfl

@[simp]
theorem antidiagonal_tuple_zero_succ (n : ℕ) : antidiagonalTuple 0 n.succ = [] :=
  rfl

theorem mem_antidiagonal_tuple {n : ℕ} {k : ℕ} {x : Finₓ k → ℕ} : x ∈ antidiagonalTuple k n ↔ (∑ i, x i) = n := by
  induction' k with k ih generalizing n
  · cases n
    · simp
      
    · simp [eq_comm]
      
    
  · refine' Finₓ.consInduction (fun x₀ x => _) x
    simp_rw [Finₓ.sum_cons, antidiagonal_tuple, List.mem_bindₓ, List.mem_mapₓ, List.Nat.mem_antidiagonal,
      Finₓ.cons_eq_cons, exists_eq_right_rightₓ, ih, Prod.existsₓ]
    constructor
    · rintro ⟨a, b, rfl, rfl, rfl⟩
      rfl
      
    · rintro rfl
      exact ⟨_, _, rfl, rfl, rfl⟩
      
    

/-- The antidiagonal of `n` does not contain duplicate entries. -/
theorem nodup_antidiagonal_tuple (k n : ℕ) : List.Nodupₓ (antidiagonalTuple k n) := by
  induction' k with k ih generalizing n
  · cases n
    · simp
      
    · simp [eq_comm]
      
    
  simp_rw [antidiagonal_tuple, List.nodup_bind]
  constructor
  · intro i hi
    exact (ih i.snd).map (Finₓ.cons_right_injective (i.fst : (fun _ => ℕ) 0))
    
  induction n
  · exact List.pairwise_singleton _ _
    
  · rw [List.Nat.antidiagonal_succ]
    refine' List.Pairwiseₓ.cons (fun a ha x hx₁ hx₂ => _) (n_ih.map _ fun a b h x hx₁ hx₂ => _)
    · rw [List.mem_mapₓ] at hx₁ hx₂ ha
      obtain ⟨⟨a, -, rfl⟩, ⟨x₁, -, rfl⟩, ⟨x₂, -, h⟩⟩ := ha, hx₁, hx₂
      rw [Finₓ.cons_eq_cons] at h
      injection h.1
      
    · rw [List.mem_mapₓ] at hx₁ hx₂
      obtain ⟨⟨x₁, hx₁, rfl⟩, ⟨x₂, hx₂, h₁₂⟩⟩ := hx₁, hx₂
      dsimp'  at h₁₂
      rw [Finₓ.cons_eq_cons, Nat.succ_inj'] at h₁₂
      obtain ⟨h₁₂, rfl⟩ := h₁₂
      rw [h₁₂] at h
      exact h (List.mem_map_of_memₓ _ hx₁) (List.mem_map_of_memₓ _ hx₂)
      
    

theorem antidiagonal_tuple_zero_right : ∀ k, antidiagonalTuple k 0 = [0]
  | 0 => (congr_argₓ fun x => [x]) <| Subsingleton.elim _ _
  | k + 1 => by
    rw [antidiagonal_tuple, antidiagonal_zero, List.bind_singleton, antidiagonal_tuple_zero_right k,
      List.map_singletonₓ]
    exact congr_argₓ (fun x => [x]) Matrix.cons_zero_zero

@[simp]
theorem antidiagonal_tuple_one (n : ℕ) : antidiagonalTuple 1 n = [![n]] := by
  simp_rw [antidiagonal_tuple, antidiagonal, List.range_succ, List.map_appendₓ, List.map_singletonₓ, tsub_self,
    List.bind_append, List.bind_singleton, antidiagonal_tuple_zero_zero, List.map_singletonₓ, List.map_bind]
  conv_rhs => rw [← List.nil_append [![n]]]
  congr 1
  simp_rw [List.bind_eq_nil, List.mem_range, List.map_eq_nilₓ]
  intro x hx
  obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_lt hx
  rw [add_assocₓ, add_tsub_cancel_left, antidiagonal_tuple_zero_succ]

theorem antidiagonal_tuple_two (n : ℕ) : antidiagonalTuple 2 n = (antidiagonal n).map fun i => ![i.1, i.2] := by
  rw [antidiagonal_tuple]
  simp_rw [antidiagonal_tuple_one, List.map_singletonₓ]
  rw [List.map_eq_bind]
  rfl

theorem antidiagonal_tuple_pairwise_pi_lex : ∀ k n, (antidiagonalTuple k n).Pairwise (Pi.Lex (· < ·) fun _ => (· < ·))
  | 0, 0 => List.pairwise_singleton _ _
  | 0, n + 1 => List.Pairwiseₓ.nil
  | k + 1, n => by
    simp_rw [antidiagonal_tuple, List.pairwise_bind, List.pairwise_map, List.mem_mapₓ, forall_exists_index, and_imp,
      forall_apply_eq_imp_iff₂]
    simp only [mem_antidiagonal, Prod.forallₓ, and_imp, forall_apply_eq_imp_iff₂]
    simp only [Finₓ.pi_lex_lt_cons_cons, eq_self_iff_true, true_andₓ, lt_self_iff_falseₓ, false_orₓ]
    refine' ⟨fun _ _ _ => antidiagonal_tuple_pairwise_pi_lex k _, _⟩
    induction n
    · rw [antidiagonal_zero]
      exact List.pairwise_singleton _ _
      
    · rw [antidiagonal_succ, List.pairwise_cons, List.pairwise_map]
      refine' ⟨fun p hp x hx y hy => _, _⟩
      · rw [List.mem_mapₓ, Prod.existsₓ] at hp
        obtain ⟨a, b, hab, rfl : (Nat.succ a, b) = p⟩ := hp
        exact Or.inl (Nat.zero_lt_succₓ _)
        
      dsimp'
      simp_rw [Nat.succ_inj', Nat.succ_lt_succ_iff]
      exact n_ih
      

end List.Nat

/-! ### Multisets -/


namespace Multiset.Nat

/-- `multiset.antidiagonal_tuple k n` is a multiset of `k`-tuples summing to `n` -/
def antidiagonalTuple (k n : ℕ) : Multiset (Finₓ k → ℕ) :=
  List.Nat.antidiagonalTuple k n

@[simp]
theorem antidiagonal_tuple_zero_zero : antidiagonalTuple 0 0 = {![]} :=
  rfl

@[simp]
theorem antidiagonal_tuple_zero_succ (n : ℕ) : antidiagonalTuple 0 n.succ = 0 :=
  rfl

theorem mem_antidiagonal_tuple {n : ℕ} {k : ℕ} {x : Finₓ k → ℕ} : x ∈ antidiagonalTuple k n ↔ (∑ i, x i) = n :=
  List.Nat.mem_antidiagonal_tuple

theorem nodup_antidiagonal_tuple (k n : ℕ) : (antidiagonalTuple k n).Nodup :=
  List.Nat.nodup_antidiagonal_tuple _ _

theorem antidiagonal_tuple_zero_right (k : ℕ) : antidiagonalTuple k 0 = {0} :=
  congr_argₓ _ (List.Nat.antidiagonal_tuple_zero_right k)

@[simp]
theorem antidiagonal_tuple_one (n : ℕ) : antidiagonalTuple 1 n = {![n]} :=
  congr_argₓ _ (List.Nat.antidiagonal_tuple_one n)

theorem antidiagonal_tuple_two (n : ℕ) : antidiagonalTuple 2 n = (antidiagonal n).map fun i => ![i.1, i.2] :=
  congr_argₓ _ (List.Nat.antidiagonal_tuple_two n)

end Multiset.Nat

/-! ### Finsets -/


namespace Finset.Nat

/-- `finset.antidiagonal_tuple k n` is a finset of `k`-tuples summing to `n` -/
def antidiagonalTuple (k n : ℕ) : Finset (Finₓ k → ℕ) :=
  ⟨Multiset.Nat.antidiagonalTuple k n, Multiset.Nat.nodup_antidiagonal_tuple k n⟩

@[simp]
theorem antidiagonal_tuple_zero_zero : antidiagonalTuple 0 0 = {![]} :=
  rfl

@[simp]
theorem antidiagonal_tuple_zero_succ (n : ℕ) : antidiagonalTuple 0 n.succ = ∅ :=
  rfl

theorem mem_antidiagonal_tuple {n : ℕ} {k : ℕ} {x : Finₓ k → ℕ} : x ∈ antidiagonalTuple k n ↔ (∑ i, x i) = n :=
  List.Nat.mem_antidiagonal_tuple

theorem antidiagonal_tuple_zero_right (k : ℕ) : antidiagonalTuple k 0 = {0} :=
  Finset.eq_of_veq (Multiset.Nat.antidiagonal_tuple_zero_right k)

@[simp]
theorem antidiagonal_tuple_one (n : ℕ) : antidiagonalTuple 1 n = {![n]} :=
  Finset.eq_of_veq (Multiset.Nat.antidiagonal_tuple_one n)

theorem antidiagonal_tuple_two (n : ℕ) :
    antidiagonalTuple 2 n = (antidiagonal n).map (piFinTwoEquiv fun _ => ℕ).symm.toEmbedding :=
  Finset.eq_of_veq (Multiset.Nat.antidiagonal_tuple_two n)

section EquivProd

/-- The disjoint union of antidiagonal tuples `Σ n, antidiagonal_tuple k n` is equivalent to the
`k`-tuple `fin k → ℕ`. This is such an equivalence, obtained by mapping `(n, x)` to `x`.

This is the tuple version of `finset.nat.sigma_antidiagonal_equiv_prod`. -/
@[simps]
def sigmaAntidiagonalTupleEquivTuple (k : ℕ) : (Σn, antidiagonalTuple k n) ≃ (Finₓ k → ℕ) where
  toFun := fun x => x.2
  invFun := fun x => ⟨∑ i, x i, x, mem_antidiagonal_tuple.mpr rfl⟩
  left_inv := fun ⟨n, t, h⟩ => Sigma.subtype_ext (mem_antidiagonal_tuple.mp h) rfl
  right_inv := fun x => rfl

end EquivProd

end Finset.Nat

