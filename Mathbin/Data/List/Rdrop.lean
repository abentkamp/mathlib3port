/-
Copyright (c) 2022 Yakov Pechersky. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yakov Pechersky
-/
import Mathbin.Data.List.Basic
import Mathbin.Data.List.Infix

/-!

# Dropping or taking from lists on the right

Taking or removing element from the tail end of a list

## Main defintions

- `rdrop n`: drop `n : ℕ` elements from the tail
- `rtake n`: take `n : ℕ` elements from the tail
- `drop_while p`: remove all the elements that satisfy a decidable `p : α → Prop` from the tail of
  a list until hitting the first non-satisfying element
- `take_while p`: take all the elements that satisfy a decidable `p : α → Prop` from the tail of
  a list until hitting the first non-satisfying element

## Implementation detail

The two predicate-based methods operate by performing the regular "from-left" operation on
`list.reverse`, followed by another `list.reverse`, so they are not the most performant.
The other two rely on `list.length l` so they still traverse the list twice. One could construct
another function that takes a `L : ℕ` and use `L - n`. Under a proof condition that
`L = l.length`, the function would do the right thing.

-/


variable {α : Type _} (p : α → Prop) [DecidablePred p] (l : List α) (n : ℕ)

namespace List

/-- Drop `n` elements from the tail end of a list. -/
def rdrop : List α :=
  l.take (l.length - n)

@[simp]
theorem rdrop_nil : rdrop ([] : List α) n = [] := by
  simp [rdrop]

@[simp]
theorem rdrop_zero : rdrop l 0 = l := by
  simp [rdrop]

theorem rdrop_eq_reverse_drop_reverse : l.rdrop n = reverse (l.reverse.drop n) := by
  rw [rdrop]
  induction' l using List.reverseRecOn with xs x IH generalizing n
  · simp
    
  · cases n
    · simp [take_append]
      
    · simp [take_append_eq_append_take, IH]
      
    

@[simp]
theorem rdrop_concat_succ (x : α) : rdrop (l ++ [x]) (n + 1) = rdrop l n := by
  simp [rdrop_eq_reverse_drop_reverse]

/-- Take `n` elements from the tail end of a list. -/
def rtake : List α :=
  l.drop (l.length - n)

@[simp]
theorem rtake_nil : rtake ([] : List α) n = [] := by
  simp [rtake]

@[simp]
theorem rtake_zero : rtake l 0 = [] := by
  simp [rtake]

theorem rtake_eq_reverse_take_reverse : l.rtake n = reverse (l.reverse.take n) := by
  rw [rtake]
  induction' l using List.reverseRecOn with xs x IH generalizing n
  · simp
    
  · cases n
    · simp
      
    · simp [drop_append_eq_append_drop, IH]
      
    

@[simp]
theorem rtake_concat_succ (x : α) : rtake (l ++ [x]) (n + 1) = rtake l n ++ [x] := by
  simp [rtake_eq_reverse_take_reverse]

/-- Drop elements from the tail end of a list that satisfy `p : α → Prop`.
Implemented naively via `list.reverse` -/
def rdropWhile : List α :=
  reverse (l.reverse.dropWhile p)

@[simp]
theorem rdrop_while_nil : rdropWhile p ([] : List α) = [] := by
  simp [rdrop_while, drop_while]

theorem rdrop_while_concat (x : α) : rdropWhile p (l ++ [x]) = if p x then rdropWhile p l else l ++ [x] := by
  simp only [rdrop_while, drop_while, reverse_append, reverse_singleton, singleton_append]
  split_ifs with h h <;> simp [h]

@[simp]
theorem rdrop_while_concat_pos (x : α) (h : p x) : rdropWhile p (l ++ [x]) = rdropWhile p l := by
  rw [rdrop_while_concat, if_pos h]

@[simp]
theorem rdrop_while_concat_neg (x : α) (h : ¬p x) : rdropWhile p (l ++ [x]) = l ++ [x] := by
  rw [rdrop_while_concat, if_neg h]

theorem rdrop_while_singleton (x : α) : rdropWhile p [x] = if p x then [] else [x] := by
  rw [← nil_append [x], rdrop_while_concat, rdrop_while_nil]

theorem rdrop_while_last_not (hl : l.rdropWhile p ≠ []) : ¬p ((rdropWhile p l).last hl) := by
  simp_rw [rdrop_while]
  rw [last_reverse]
  exact drop_while_nth_le_zero_not _ _ _

theorem rdrop_while_prefix : l.rdropWhile p <+: l := by
  rw [← reverse_suffix, rdrop_while, reverse_reverse]
  exact drop_while_suffix _

variable {p} {l}

@[simp]
theorem rdrop_while_eq_nil_iff : rdropWhile p l = [] ↔ ∀ x ∈ l, p x := by
  simp [rdrop_while]

-- it is in this file because it requires `list.infix`
@[simp]
theorem drop_while_eq_self_iff : dropWhileₓ p l = l ↔ ∀ hl : 0 < l.length, ¬p (l.nthLe 0 hl) := by
  induction' l with hd tl IH
  · simp
    
  · rw [drop_while]
    split_ifs
    · simp only [h, length, nth_le, Nat.succ_pos', not_true, forall_true_left, iff_falseₓ]
      intro H
      refine' (cons_ne_self hd tl) (sublist.antisymm _ (sublist_cons _ _))
      rw [← H]
      exact (drop_while_suffix _).Sublist
      
    · simp [h]
      
    

@[simp]
theorem rdrop_while_eq_self_iff : rdropWhile p l = l ↔ ∀ hl : l ≠ [], ¬p (l.last hl) := by
  simp only [rdrop_while, reverse_eq_iff, length_reverse, Ne.def, drop_while_eq_self_iff, last_eq_nth_le, ←
    length_eq_zero, pos_iff_ne_zero]
  refine' forall_congrₓ _
  intro h
  rw [nth_le_reverse']
  · simp
    
  · rw [← Ne.def, ← pos_iff_ne_zero] at h
    simp [tsub_lt_iff_right (Nat.succ_le_of_ltₓ h)]
    

variable (p) (l)

theorem drop_while_idempotent : dropWhileₓ p (dropWhileₓ p l) = dropWhileₓ p l :=
  drop_while_eq_self_iff.mpr (drop_while_nth_le_zero_not _ _)

theorem rdrop_while_idempotent : rdropWhile p (rdropWhile p l) = rdropWhile p l :=
  rdrop_while_eq_self_iff.mpr (rdrop_while_last_not _ _)

/-- Take elements from the tail end of a list that satisfy `p : α → Prop`.
Implemented naively via `list.reverse` -/
def rtakeWhile : List α :=
  reverse (l.reverse.takeWhile p)

@[simp]
theorem rtake_while_nil : rtakeWhile p ([] : List α) = [] := by
  simp [rtake_while, take_while]

theorem rtake_while_concat (x : α) : rtakeWhile p (l ++ [x]) = if p x then rtakeWhile p l ++ [x] else [] := by
  simp only [rtake_while, take_while, reverse_append, reverse_singleton, singleton_append]
  split_ifs with h h <;> simp [h]

@[simp]
theorem rtake_while_concat_pos (x : α) (h : p x) : rtakeWhile p (l ++ [x]) = rtakeWhile p l ++ [x] := by
  rw [rtake_while_concat, if_pos h]

@[simp]
theorem rtake_while_concat_neg (x : α) (h : ¬p x) : rtakeWhile p (l ++ [x]) = [] := by
  rw [rtake_while_concat, if_neg h]

theorem rtake_while_suffix : l.rtakeWhile p <:+ l := by
  rw [← reverse_prefix, rtake_while, reverse_reverse]
  exact take_while_prefix _

variable {p} {l}

@[simp]
theorem rtake_while_eq_self_iff : rtakeWhile p l = l ↔ ∀ x ∈ l, p x := by
  simp [rtake_while, reverse_eq_iff]

@[simp]
theorem rtake_while_eq_nil_iff : rtakeWhile p l = [] ↔ ∀ hl : l ≠ [], ¬p (l.last hl) := by
  induction l using List.reverseRecOn <;> simp [rtake_while]

theorem mem_rtake_while_imp {x : α} (hx : x ∈ rtakeWhile p l) : p x := by
  suffices x ∈ take_while p l.reverse by
    exact mem_take_while_imp this
  rwa [← mem_reverse, ← rtake_while]

variable (p) (l)

theorem rtake_while_idempotent : rtakeWhile p (rtakeWhile p l) = rtakeWhile p l :=
  rtake_while_eq_self_iff.mpr fun _ => mem_rtake_while_imp

end List

