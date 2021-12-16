import Mathbin.Data.Set.Lattice 
import Mathbin.Order.Zorn

/-!
# Extend a partial order to a linear order

This file constructs a linear order which is an extension of the given partial order, using Zorn's
lemma.
-/


universe u

open Set Classical

open_locale Classical

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » c)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (ub «expr ∈ » S)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (z «expr ∈ » c)
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    Any partial order can be extended to a linear order.
    -/
  theorem
    extend_partial_order
    { α : Type u } ( r : α → α → Prop ) [ IsPartialOrder α r ]
      : ∃ ( s : α → α → Prop ) ( _ : IsLinearOrder α s ) , r ≤ s
    :=
      by
        let S := { s | IsPartialOrder α s }
          have
            hS
            : ∀ c , c ⊆ S → Zorn.Chain · ≤ · c → ∀ y _ : y ∈ c , ∃ ( ub : _ ) ( _ : ub ∈ S ) , ∀ z _ : z ∈ c , z ≤ ub
          ·
            rintro c hc₁ hc₂ s hs
              have := hc₁ hs . 1
              refine' ⟨ Sup c , _ , fun z hz => le_Sup hz ⟩
              refine' { refl := _ , trans := _ , antisymm := _ } <;> simpRw [ binary_relation_Sup_iff ]
              · intro x exact ⟨ s , hs , refl x ⟩
              ·
                rintro x y z ⟨ s₁ , h₁s₁ , h₂s₁ ⟩ ⟨ s₂ , h₁s₂ , h₂s₂ ⟩
                  have : IsPartialOrder _ _ := hc₁ h₁s₁
                  have : IsPartialOrder _ _ := hc₁ h₁s₂
                  cases hc₂.total_of_refl h₁s₁ h₁s₂
                  · exact ⟨ s₂ , h₁s₂ , trans h _ _ h₂s₁ h₂s₂ ⟩
                  · exact ⟨ s₁ , h₁s₁ , trans h₂s₁ h _ _ h₂s₂ ⟩
              ·
                rintro x y ⟨ s₁ , h₁s₁ , h₂s₁ ⟩ ⟨ s₂ , h₁s₂ , h₂s₂ ⟩
                  have : IsPartialOrder _ _ := hc₁ h₁s₁
                  have : IsPartialOrder _ _ := hc₁ h₁s₂
                  cases hc₂.total_of_refl h₁s₁ h₁s₂
                  · exact antisymm h _ _ h₂s₁ h₂s₂
                  · apply antisymm h₂s₁ h _ _ h₂s₂
          obtain ⟨ s , hs₁ : IsPartialOrder _ _ , rs , hs₂ ⟩ := Zorn.zorn_nonempty_partial_order₀ S hS r ‹ _ ›
          skip
          refine' ⟨ s , { Total := _ } , rs ⟩
          intro x y
          byContra h
          pushNeg at h
          let s' := fun x' y' => s x' y' ∨ s x' x ∧ s y y'
          rw [ ← hs₂ s' _ fun _ _ => Or.inl ] at h
          · apply h . 1 Or.inr ⟨ refl _ , refl _ ⟩
          ·
            refine' { refl := fun x => Or.inl refl _ , trans := _ , antisymm := _ }
              ·
                rintro a b c ( ab | ⟨ ax : s a x , yb : s y b ⟩ ) ( bc | ⟨ bx : s b x , yc : s y c ⟩ )
                  · exact Or.inl trans ab bc
                  · exact Or.inr ⟨ trans ab bx , yc ⟩
                  · exact Or.inr ⟨ ax , trans yb bc ⟩
                  · exact Or.inr ⟨ ax , yc ⟩
              ·
                rintro a b ( ab | ⟨ ax : s a x , yb : s y b ⟩ ) ( ba | ⟨ bx : s b x , ya : s y a ⟩ )
                  · exact antisymm ab ba
                  · exact h . 2 trans ya trans ab bx . elim
                  · exact h . 2 trans yb trans ba ax . elim
                  · exact h . 2 trans yb bx . elim

/-- A type alias for `α`, intended to extend a partial order on `α` to a linear order. -/
def LinearExtension (α : Type u) : Type u :=
  α

noncomputable instance {α : Type u} [PartialOrderₓ α] : LinearOrderₓ (LinearExtension α) :=
  { le := (extend_partial_order (· ≤ · : α → α → Prop)).some,
    le_refl := (extend_partial_order (· ≤ · : α → α → Prop)).some_spec.some.1.1.1.1,
    le_trans := (extend_partial_order (· ≤ · : α → α → Prop)).some_spec.some.1.1.2.1,
    le_antisymm := (extend_partial_order (· ≤ · : α → α → Prop)).some_spec.some.1.2.1,
    le_total := (extend_partial_order (· ≤ · : α → α → Prop)).some_spec.some.2.1, decidableLe := Classical.decRel _ }

/-- The embedding of `α` into `linear_extension α` as a relation homomorphism. -/
def toLinearExtension {α : Type u} [PartialOrderₓ α] :
  (· ≤ · : α → α → Prop) →r (· ≤ · : LinearExtension α → LinearExtension α → Prop) :=
  { toFun := fun x => x, map_rel' := fun a b => (extend_partial_order (· ≤ · : α → α → Prop)).some_spec.some_spec _ _ }

instance {α : Type u} [Inhabited α] : Inhabited (LinearExtension α) :=
  ⟨(default _ : α)⟩

