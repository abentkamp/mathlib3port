import Mathbin.Data.Multiset.Basic 
import Mathbin.Data.List.Range

/-! # `multiset.range n` gives `{0, 1, ..., n-1}` as a multiset. -/


open List Nat

namespace Multiset

/-- `range n` is the multiset lifted from the list `range n`,
  that is, the set `{0, 1, ..., n-1}`. -/
def range (n : ℕ) : Multiset ℕ :=
  range n

@[simp]
theorem range_zero : range 0 = 0 :=
  rfl

@[simp]
theorem range_succ (n : ℕ) : range (succ n) = n ::ₘ range n :=
  by 
    rw [range, range_succ, ←coe_add, add_commₓ] <;> rfl

@[simp]
theorem card_range (n : ℕ) : card (range n) = n :=
  length_range _

theorem range_subset {m n : ℕ} : range m ⊆ range n ↔ m ≤ n :=
  range_subset

@[simp]
theorem mem_range {m n : ℕ} : m ∈ range n ↔ m < n :=
  mem_range

@[simp]
theorem not_mem_range_self {n : ℕ} : n ∉ range n :=
  not_mem_range_self

theorem self_mem_range_succ (n : ℕ) : n ∈ range (n+1) :=
  List.self_mem_range_succ n

theorem range_add (a b : ℕ) : range (a+b) = range a+(range b).map fun x => a+x :=
  congr_argₓ coeₓ (List.range_add _ _)

theorem range_disjoint_map_add (a : ℕ) (m : Multiset ℕ) : (range a).Disjoint (m.map fun x => a+x) :=
  by 
    intro x hxa hxb 
    rw [range, mem_coe, List.mem_range] at hxa 
    obtain ⟨c, _, rfl⟩ := mem_map.1 hxb 
    exact (self_le_add_right _ _).not_lt hxa

theorem range_add_eq_union (a b : ℕ) : range (a+b) = range a ∪ (range b).map fun x => a+x :=
  by 
    rw [range_add, add_eq_union_iff_disjoint]
    apply range_disjoint_map_add

end Multiset

