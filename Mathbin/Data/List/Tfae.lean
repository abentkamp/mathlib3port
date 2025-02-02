/-
Copyright (c) 2018 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Simon Hudon
-/
import Mathbin.Data.List.Basic

/-!
# The Following Are Equivalent

This file allows to state that all propositions in a list are equivalent. It is used by
`tactic.tfae`.
`tfae l` means `∀ x ∈ l, ∀ y ∈ l, x ↔ y`. This is equivalent to `pairwise (↔) l`.
-/


namespace List

/-- tfae: The Following (propositions) Are Equivalent.

The `tfae_have` and `tfae_finish` tactics can be useful in proofs with `tfae` goals.
-/
def Tfae (l : List Prop) : Prop :=
  ∀ x ∈ l, ∀ y ∈ l, x ↔ y

theorem tfae_nil : Tfae [] :=
  forall_mem_nilₓ _

theorem tfae_singleton (p) : Tfae [p] := by
  simp [tfae, -eq_iff_iff]

theorem tfae_cons_of_mem {a b} {l : List Prop} (h : b ∈ l) : Tfae (a :: l) ↔ (a ↔ b) ∧ Tfae l :=
  ⟨fun H =>
    ⟨H a
        (by
          simp )
        b (Or.inr h),
      fun p hp q hq => H _ (Or.inr hp) _ (Or.inr hq)⟩,
    by
    rintro ⟨ab, H⟩ p (rfl | hp) q (rfl | hq)
    · rfl
      
    · exact ab.trans (H _ h _ hq)
      
    · exact (ab.trans (H _ h _ hp)).symm
      
    · exact H _ hp _ hq
      ⟩

theorem tfae_cons_cons {a b} {l : List Prop} : Tfae (a :: b :: l) ↔ (a ↔ b) ∧ Tfae (b :: l) :=
  tfae_cons_of_mem (Or.inl rfl)

theorem tfae_of_forall (b : Prop) (l : List Prop) (h : ∀ a ∈ l, a ↔ b) : Tfae l := fun a₁ h₁ a₂ h₂ =>
  (h _ h₁).trans (h _ h₂).symm

-- ./././Mathport/Syntax/Translate/Expr.lean:219:4: warning: unsupported binary notation `«->»
theorem tfae_of_cycle {a b} {l : List Prop} :
    List.Chain («->» · ·) a (b :: l) → (ilast' b l → a) → Tfae (a :: b :: l) := by
  induction' l with c l IH generalizing a b <;>
    simp only [tfae_cons_cons, tfae_singleton, and_trueₓ, chain_cons, chain.nil] at *
  · intro a b
    exact Iff.intro a b
    
  rintro ⟨ab, ⟨bc, ch⟩⟩ la
  have := IH ⟨bc, ch⟩ (ab ∘ la)
  exact ⟨⟨ab, la ∘ (this.2 c (Or.inl rfl) _ (ilast'_mem _ _)).1 ∘ bc⟩, this⟩

theorem Tfae.out {l} (h : Tfae l) (n₁ n₂) {a b}
    (h₁ : List.nth l n₁ = some a := by
      run_tac
        tactic.interactive.refl)
    (h₂ : List.nth l n₂ = some b := by
      run_tac
        tactic.interactive.refl) :
    a ↔ b :=
  h _ (List.nth_mem h₁) _ (List.nth_mem h₂)

end List

