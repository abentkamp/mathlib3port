import Mathbin.Algebra.BigOperators.Basic
import Mathbin.Data.Nat.Interval
import Mathbin.Order.Antichain

/-!
# `r`-sets and slice

This file defines the `r`-th slice of a set family and provides a way to say that a set family is
made of `r`-sets.

An `r`-set is a finset of cardinality `r` (aka of *size* `r`). The `r`-th slice of a set family is
the set family made of its `r`-sets.

## Main declarations

* `set.sized`: `A.sized r` means that `A` only contains `r`-sets.
* `finset.slice`: `A.slice r` is the set of `r`-sets in `A`.

## Notation

`A # r` is notation for `A.slice r` in locale `finset_family`.
-/


open Finset Nat

open_locale BigOperators

variable {α : Type _} {ι : Sort _} {κ : ι → Sort _}

namespace Set

variable {A B : Set (Finset α)} {r : ℕ}

/-! ### Families of `r`-sets -/


/-- `sized r A` means that every finset in `A` has size `r`. -/
def sized (r : ℕ) (A : Set (Finset α)) : Prop :=
  ∀ ⦃x⦄, x ∈ A → card x = r

theorem sized.mono (h : A ⊆ B) (hB : B.sized r) : A.sized r := fun x hx => hB <| h hx

theorem sized_union : (A ∪ B).Sized r ↔ A.sized r ∧ B.sized r :=
  ⟨fun hA => ⟨hA.mono <| subset_union_left _ _, hA.mono <| subset_union_right _ _⟩, fun hA x hx =>
    (hx.elim fun h => hA.1 h) fun h => hA.2 h⟩

alias sized_union ↔ _ Set.Sized.union

@[simp]
theorem sized_Union {f : ι → Set (Finset α)} : (⋃ i, f i).Sized r ↔ ∀ i, (f i).Sized r := by
  simp_rw [Set.Sized, Set.mem_Union, forall_exists_index]
  exact forall_swap

-- ././Mathport/Syntax/Translate/Basic.lean:626:6: warning: expanding binder group (i j)
@[simp]
theorem sized_Union₂ {f : ∀ i, κ i → Set (Finset α)} : (⋃ (i) (j), f i j).Sized r ↔ ∀ i j, (f i j).Sized r := by
  simp_rw [sized_Union]

protected theorem sized.is_antichain (hA : A.sized r) : IsAntichain (· ⊆ ·) A := fun s hs t ht h hst =>
  h <| Finset.eq_of_subset_of_card_le hst ((hA ht).trans (hA hs).symm).le

protected theorem sized.subsingleton (hA : A.sized 0) : A.subsingleton :=
  (subsingleton_of_forall_eq ∅) fun s hs => card_eq_zero.1 <| hA hs

theorem sized.subsingleton' [Fintype α] (hA : A.sized (Fintype.card α)) : A.subsingleton :=
  (subsingleton_of_forall_eq Finset.univ) fun s hs => s.card_eq_iff_eq_univ.1 <| hA hs

theorem sized.empty_mem_iff (hA : A.sized r) : ∅ ∈ A ↔ A = {∅} :=
  hA.is_antichain.bot_mem_iff

theorem sized.univ_mem_iff [Fintype α] (hA : A.sized r) : Finset.univ ∈ A ↔ A = {Finset.univ} :=
  hA.is_antichain.top_mem_iff

theorem sized_powerset_len (s : Finset α) (r : ℕ) : (powerset_len r s : Set (Finset α)).Sized r := fun t ht =>
  (mem_powerset_len.1 ht).2

end Set

namespace Finset

section Sized

variable [Fintype α] {𝒜 : Finset (Finset α)} {s : Finset α} {r : ℕ}

theorem subset_powerset_len_univ_iff : 𝒜 ⊆ powerset_len r univ ↔ (𝒜 : Set (Finset α)).Sized r :=
  forall_congrₓ fun A => by
    rw [mem_powerset_len_univ_iff, mem_coe]

alias subset_powerset_len_univ_iff ↔ _ Set.Sized.subset_powerset_len_univ

theorem _root_.set.sized.card_le (h𝒜 : (𝒜 : Set (Finset α)).Sized r) : card 𝒜 ≤ (Fintype.card α).choose r := by
  rw [Fintype.card, ← card_powerset_len]
  exact card_le_of_subset h𝒜.subset_powerset_len_univ

end Sized

/-! ### Slices -/


section Slice

variable {𝒜 : Finset (Finset α)} {A A₁ A₂ : Finset α} {r r₁ r₂ : ℕ}

/-- The `r`-th slice of a set family is the subset of its elements which have cardinality `r`. -/
def slice (𝒜 : Finset (Finset α)) (r : ℕ) : Finset (Finset α) :=
  𝒜.filter fun i => i.card = r

localized [FinsetFamily] infixl:90 " # " => Finset.slice

/-- `A` is in the `r`-th slice of `𝒜` iff it's in `𝒜` and has cardinality `r`. -/
theorem mem_slice : A ∈ 𝒜 # r ↔ A ∈ 𝒜 ∧ A.card = r :=
  mem_filter

/-- The `r`-th slice of `𝒜` is a subset of `𝒜`. -/
theorem slice_subset : 𝒜 # r ⊆ 𝒜 :=
  filter_subset _ _

/-- Everything in the `r`-th slice of `𝒜` has size `r`. -/
theorem sized_slice : (𝒜 # r : Set (Finset α)).Sized r := fun _ => And.right ∘ mem_slice.mp

theorem eq_of_mem_slice (h₁ : A ∈ 𝒜 # r₁) (h₂ : A ∈ 𝒜 # r₂) : r₁ = r₂ :=
  (sized_slice h₁).symm.trans <| sized_slice h₂

/-- Elements in distinct slices must be distinct. -/
theorem ne_of_mem_slice (h₁ : A₁ ∈ 𝒜 # r₁) (h₂ : A₂ ∈ 𝒜 # r₂) : r₁ ≠ r₂ → A₁ ≠ A₂ :=
  mt fun h => (sized_slice h₁).symm.trans ((congr_argₓ card h).trans (sized_slice h₂))

theorem pairwise_disjoint_slice [DecidableEq α] : (Set.Univ : Set ℕ).PairwiseDisjoint (slice 𝒜) := fun m _ n _ hmn =>
  disjoint_filter.2 fun s hs hm hn => hmn <| hm.symm.trans hn

variable [Fintype α] (𝒜)

@[simp]
theorem bUnion_slice [DecidableEq α] : (Iic <| Fintype.card α).bUnion 𝒜.slice = 𝒜 :=
  (subset.antisymm (bUnion_subset.2 fun r _ => slice_subset)) fun s hs =>
    mem_bUnion.2 ⟨s.card, mem_Iic.2 <| s.card_le_univ, mem_slice.2 <| ⟨hs, rfl⟩⟩

@[simp]
theorem sum_card_slice : (∑ r in Iic (Fintype.card α), (𝒜 # r).card) = 𝒜.card := by
  rw [← card_bUnion (finset.pairwise_disjoint_slice.subset (Set.subset_univ _)), bUnion_slice]
  exact Classical.decEq _

end Slice

end Finset

