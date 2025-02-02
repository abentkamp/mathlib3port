/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Kenny Lau
-/
import Mathbin.Data.Finset.Basic

/-!
# Finsets of ordered types
-/


universe u v w

variable {α : Type u}

theorem Directed.finset_le {r : α → α → Prop} [IsTrans α r] {ι} [hι : Nonempty ι] {f : ι → α} (D : Directed r f)
    (s : Finset ι) : ∃ z, ∀ i ∈ s, r (f i) (f z) :=
  show ∃ z, ∀ i ∈ s.1, r (f i) (f z) from
    (Multiset.induction_on s.1
        (let ⟨z⟩ := hι
        ⟨z, fun _ => False.elim⟩))
      fun i s ⟨j, H⟩ =>
      let ⟨k, h₁, h₂⟩ := D i j
      ⟨k, fun a h => Or.cases_on (Multiset.mem_cons.1 h) (fun h => h.symm ▸ h₁) fun h => trans (H _ h) h₂⟩

theorem Finset.exists_le [Nonempty α] [Preorderₓ α] [IsDirected α (· ≤ ·)] (s : Finset α) : ∃ M, ∀ i ∈ s, i ≤ M :=
  directed_id.finset_le _

