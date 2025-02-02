/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathbin.Data.Set.Basic

/-!
# Circular order hierarchy

This file defines circular preorders, circular partial orders and circular orders.

## Hierarchy

* A ternary "betweenness" relation `btw : α → α → α → Prop` forms a `circular_order` if it is
  - reflexive: `btw a a a`
  - cyclic: `btw a b c → btw b c a`
  - antisymmetric: `btw a b c → btw c b a → a = b ∨ b = c ∨ c = a`
  - total: `btw a b c ∨ btw c b a`
  along with a strict betweenness relation `sbtw : α → α → α → Prop` which respects
  `sbtw a b c ↔ btw a b c ∧ ¬ btw c b a`, analogously to how `<` and `≤` are related, and is
  - transitive: `sbtw a b c → sbtw b d c → sbtw a d c`.
* A `circular_partial_order` drops totality.
* A `circular_preorder` further drops antisymmetry.

The intuition is that a circular order is a circle and `btw a b c` means that going around
clockwise from `a` you reach `b` before `c` (`b` is between `a` and `c` is meaningless on an
unoriented circle). A circular partial order is several, potentially intersecting, circles. A
circular preorder is like a circular partial order, but several points can coexist.

Note that the relations between `circular_preorder`, `circular_partial_order` and `circular_order`
are subtler than between `preorder`, `partial_order`, `linear_order`. In particular, one cannot
simply extend the `btw` of a `circular_partial_order` to make it a `circular_order`.

One can translate from usual orders to circular ones by "closing the necklace at infinity". See
`has_le.to_has_btw` and `has_lt.to_has_sbtw`. Going the other way involves "cutting the necklace" or
"rolling the necklace open".

## Examples

Some concrete circular orders one encounters in the wild are `zmod n` for `0 < n`, `circle`,
`real.angle`...

## Main definitions

* `set.cIcc`: Closed-closed circular interval.
* `set.cIoo`: Open-open circular interval.

## Notes

There's an unsolved diamond on `order_dual α` here. The instances `has_le α → has_btw αᵒᵈ` and
`has_lt α → has_sbtw αᵒᵈ` can each be inferred in two ways:
* `has_le α` → `has_btw α` → `has_btw αᵒᵈ` vs
  `has_le α` → `has_le αᵒᵈ` → `has_btw αᵒᵈ`
* `has_lt α` → `has_sbtw α` → `has_sbtw αᵒᵈ` vs
  `has_lt α` → `has_lt αᵒᵈ` → `has_sbtw αᵒᵈ`
The fields are propeq, but not defeq. It is temporarily fixed by turning the circularizing instances
into definitions.

## TODO

Antisymmetry is quite weak in the sense that there's no way to discriminate which two points are
equal. This prevents defining closed-open intervals `cIco` and `cIoc` in the neat `=`-less way. We
currently haven't defined them at all.

What is the correct generality of "rolling the necklace" open? At least, this works for `α × β` and
`β × α` where `α` is a circular order and `β` is a linear order.

What's next is to define circular groups and provide instances for `zmod n`, the usual circle group
`circle`, `real.angle`, and `roots_of_unity M`. What conditions do we need on `M` for this last one
to work?

We should have circular order homomorphisms. The typical example is
`days_to_month : days_of_the_year →c months_of_the_year` which relates the circular order of days
and the circular order of months. Is `α →c β` a good notation?

## References

* https://en.wikipedia.org/wiki/Cyclic_order
* https://en.wikipedia.org/wiki/Partial_cyclic_order

## Tags

circular order, cyclic order, circularly ordered set, cyclically ordered set
-/


/-- Syntax typeclass for a betweenness relation. -/
class HasBtw (α : Type _) where
  Btw : α → α → α → Prop

export HasBtw (Btw)

/-- Syntax typeclass for a strict betweenness relation. -/
class HasSbtw (α : Type _) where
  Sbtw : α → α → α → Prop

export HasSbtw (Sbtw)

/-- A circular preorder is the analogue of a preorder where you can loop around. `≤` and `<` are
replaced by ternary relations `btw` and `sbtw`. `btw` is reflexive and cyclic. `sbtw` is transitive.
-/
class CircularPreorder (α : Type _) extends HasBtw α, HasSbtw α where
  btw_refl (a : α) : btw a a a
  btw_cyclic_left {a b c : α} : btw a b c → btw b c a
  Sbtw := fun a b c => btw a b c ∧ ¬btw c b a
  sbtw_iff_btw_not_btw {a b c : α} : sbtw a b c ↔ btw a b c ∧ ¬btw c b a := by
    run_tac
      order_laws_tac
  sbtw_trans_left {a b c d : α} : sbtw a b c → sbtw b d c → sbtw a d c

export CircularPreorder (btw_refl btw_cyclic_left sbtw_trans_left)

/-- A circular partial order is the analogue of a partial order where you can loop around. `≤` and
`<` are replaced by ternary relations `btw` and `sbtw`. `btw` is reflexive, cyclic and
antisymmetric. `sbtw` is transitive. -/
class CircularPartialOrder (α : Type _) extends CircularPreorder α where
  btw_antisymm {a b c : α} : btw a b c → btw c b a → a = b ∨ b = c ∨ c = a

export CircularPartialOrder (btw_antisymm)

/-- A circular order is the analogue of a linear order where you can loop around. `≤` and `<` are
replaced by ternary relations `btw` and `sbtw`. `btw` is reflexive, cyclic, antisymmetric and total.
`sbtw` is transitive. -/
class CircularOrder (α : Type _) extends CircularPartialOrder α where
  btw_total : ∀ a b c : α, btw a b c ∨ btw c b a

export CircularOrder (btw_total)

/-! ### Circular preorders -/


section CircularPreorder

variable {α : Type _} [CircularPreorder α]

theorem btw_rfl {a : α} : Btw a a a :=
  btw_refl _

-- TODO: `alias` creates a def instead of a lemma.
-- alias btw_cyclic_left        ← has_btw.btw.cyclic_left
theorem HasBtw.Btw.cyclic_left {a b c : α} (h : Btw a b c) : Btw b c a :=
  btw_cyclic_left h

theorem btw_cyclic_right {a b c : α} (h : Btw a b c) : Btw c a b :=
  h.cyclic_left.cyclic_left

alias btw_cyclic_right ← HasBtw.Btw.cyclic_right

/-- The order of the `↔` has been chosen so that `rw btw_cyclic` cycles to the right while
`rw ←btw_cyclic` cycles to the left (thus following the prepended arrow). -/
theorem btw_cyclic {a b c : α} : Btw a b c ↔ Btw c a b :=
  ⟨btw_cyclic_right, btw_cyclic_left⟩

theorem sbtw_iff_btw_not_btw {a b c : α} : Sbtw a b c ↔ Btw a b c ∧ ¬Btw c b a :=
  CircularPreorder.sbtw_iff_btw_not_btw

theorem btw_of_sbtw {a b c : α} (h : Sbtw a b c) : Btw a b c :=
  (sbtw_iff_btw_not_btw.1 h).1

alias btw_of_sbtw ← HasSbtw.Sbtw.btw

theorem not_btw_of_sbtw {a b c : α} (h : Sbtw a b c) : ¬Btw c b a :=
  (sbtw_iff_btw_not_btw.1 h).2

alias not_btw_of_sbtw ← HasSbtw.Sbtw.not_btw

theorem not_sbtw_of_btw {a b c : α} (h : Btw a b c) : ¬Sbtw c b a := fun h' => h'.not_btw h

alias not_sbtw_of_btw ← HasBtw.Btw.not_sbtw

theorem sbtw_of_btw_not_btw {a b c : α} (habc : Btw a b c) (hcba : ¬Btw c b a) : Sbtw a b c :=
  sbtw_iff_btw_not_btw.2 ⟨habc, hcba⟩

alias sbtw_of_btw_not_btw ← HasBtw.Btw.sbtw_of_not_btw

theorem sbtw_cyclic_left {a b c : α} (h : Sbtw a b c) : Sbtw b c a :=
  h.Btw.cyclic_left.sbtw_of_not_btw fun h' => h.not_btw h'.cyclic_left

alias sbtw_cyclic_left ← HasSbtw.Sbtw.cyclic_left

theorem sbtw_cyclic_right {a b c : α} (h : Sbtw a b c) : Sbtw c a b :=
  h.cyclic_left.cyclic_left

alias sbtw_cyclic_right ← HasSbtw.Sbtw.cyclic_right

/-- The order of the `↔` has been chosen so that `rw sbtw_cyclic` cycles to the right while
`rw ←sbtw_cyclic` cycles to the left (thus following the prepended arrow). -/
theorem sbtw_cyclic {a b c : α} : Sbtw a b c ↔ Sbtw c a b :=
  ⟨sbtw_cyclic_right, sbtw_cyclic_left⟩

-- TODO: `alias` creates a def instead of a lemma.
-- alias btw_trans_left        ← has_btw.btw.trans_left
theorem HasSbtw.Sbtw.trans_left {a b c d : α} (h : Sbtw a b c) : Sbtw b d c → Sbtw a d c :=
  sbtw_trans_left h

theorem sbtw_trans_right {a b c d : α} (hbc : Sbtw a b c) (hcd : Sbtw a c d) : Sbtw a b d :=
  (hbc.cyclic_left.trans_left hcd.cyclic_left).cyclic_right

alias sbtw_trans_right ← HasSbtw.Sbtw.trans_right

theorem sbtw_asymm {a b c : α} (h : Sbtw a b c) : ¬Sbtw c b a :=
  h.Btw.not_sbtw

alias sbtw_asymm ← HasSbtw.Sbtw.not_sbtw

theorem sbtw_irrefl_left_right {a b : α} : ¬Sbtw a b a := fun h => h.not_btw h.Btw

theorem sbtw_irrefl_left {a b : α} : ¬Sbtw a a b := fun h => sbtw_irrefl_left_right h.cyclic_left

theorem sbtw_irrefl_right {a b : α} : ¬Sbtw a b b := fun h => sbtw_irrefl_left_right h.cyclic_right

theorem sbtw_irrefl (a : α) : ¬Sbtw a a a :=
  sbtw_irrefl_left_right

end CircularPreorder

/-! ### Circular partial orders -/


section CircularPartialOrder

variable {α : Type _} [CircularPartialOrder α]

-- TODO: `alias` creates a def instead of a lemma.
-- alias btw_antisymm        ← has_btw.btw.antisymm
theorem HasBtw.Btw.antisymm {a b c : α} (h : Btw a b c) : Btw c b a → a = b ∨ b = c ∨ c = a :=
  btw_antisymm h

end CircularPartialOrder

/-! ### Circular orders -/


section CircularOrder

variable {α : Type _} [CircularOrder α]

theorem btw_refl_left_right (a b : α) : Btw a b a :=
  (or_selfₓ _).1 (btw_total a b a)

theorem btw_rfl_left_right {a b : α} : Btw a b a :=
  btw_refl_left_right _ _

theorem btw_refl_left (a b : α) : Btw a a b :=
  btw_rfl_left_right.cyclic_right

theorem btw_rfl_left {a b : α} : Btw a a b :=
  btw_refl_left _ _

theorem btw_refl_right (a b : α) : Btw a b b :=
  btw_rfl_left_right.cyclic_left

theorem btw_rfl_right {a b : α} : Btw a b b :=
  btw_refl_right _ _

theorem sbtw_iff_not_btw {a b c : α} : Sbtw a b c ↔ ¬Btw c b a := by
  rw [sbtw_iff_btw_not_btw]
  exact and_iff_right_of_imp (btw_total _ _ _).resolve_left

theorem btw_iff_not_sbtw {a b c : α} : Btw a b c ↔ ¬Sbtw c b a :=
  iff_not_comm.1 sbtw_iff_not_btw

end CircularOrder

/-! ### Circular intervals -/


namespace Set

section CircularPreorder

variable {α : Type _} [CircularPreorder α]

/-- Closed-closed circular interval -/
def CIcc (a b : α) : Set α :=
  { x | Btw a x b }

/-- Open-open circular interval -/
def CIoo (a b : α) : Set α :=
  { x | Sbtw a x b }

@[simp]
theorem mem_cIcc {a b x : α} : x ∈ CIcc a b ↔ Btw a x b :=
  Iff.rfl

@[simp]
theorem mem_cIoo {a b x : α} : x ∈ CIoo a b ↔ Sbtw a x b :=
  Iff.rfl

end CircularPreorder

section CircularOrder

variable {α : Type _} [CircularOrder α]

theorem left_mem_cIcc (a b : α) : a ∈ CIcc a b :=
  btw_rfl_left

theorem right_mem_cIcc (a b : α) : b ∈ CIcc a b :=
  btw_rfl_right

theorem compl_cIcc {a b : α} : CIcc a bᶜ = CIoo b a := by
  ext
  rw [Set.mem_cIoo, sbtw_iff_not_btw]
  rfl

theorem compl_cIoo {a b : α} : CIoo a bᶜ = CIcc b a := by
  ext
  rw [Set.mem_cIcc, btw_iff_not_sbtw]
  rfl

end CircularOrder

end Set

/-! ### Circularizing instances -/


/-- The betweenness relation obtained from "looping around" `≤`.
See note [reducible non-instances]. -/
@[reducible]
def LE.toHasBtw (α : Type _) [LE α] : HasBtw α where Btw := fun a b c => a ≤ b ∧ b ≤ c ∨ b ≤ c ∧ c ≤ a ∨ c ≤ a ∧ a ≤ b

/-- The strict betweenness relation obtained from "looping around" `<`.
See note [reducible non-instances]. -/
@[reducible]
def LT.toHasSbtw (α : Type _) [LT α] :
    HasSbtw α where Sbtw := fun a b c => a < b ∧ b < c ∨ b < c ∧ c < a ∨ c < a ∧ a < b

/-- The circular preorder obtained from "looping around" a preorder.
See note [reducible non-instances]. -/
@[reducible]
def Preorderₓ.toCircularPreorder (α : Type _) [Preorderₓ α] : CircularPreorder α where
  Btw := fun a b c => a ≤ b ∧ b ≤ c ∨ b ≤ c ∧ c ≤ a ∨ c ≤ a ∧ a ≤ b
  Sbtw := fun a b c => a < b ∧ b < c ∨ b < c ∧ c < a ∨ c < a ∧ a < b
  btw_refl := fun a => Or.inl ⟨le_rflₓ, le_rflₓ⟩
  btw_cyclic_left := fun a b c h => by
    unfold btw  at h⊢
    rwa [← Or.assoc, or_comm]
  sbtw_trans_left := fun a b c d => by
    rintro (⟨hab, hbc⟩ | ⟨hbc, hca⟩ | ⟨hca, hab⟩) (⟨hbd, hdc⟩ | ⟨hdc, hcb⟩ | ⟨hcb, hbd⟩)
    · exact Or.inl ⟨hab.trans hbd, hdc⟩
      
    · exact (hbc.not_lt hcb).elim
      
    · exact (hbc.not_lt hcb).elim
      
    · exact Or.inr (Or.inl ⟨hdc, hca⟩)
      
    · exact Or.inr (Or.inl ⟨hdc, hca⟩)
      
    · exact (hbc.not_lt hcb).elim
      
    · exact Or.inr (Or.inl ⟨hdc, hca⟩)
      
    · exact Or.inr (Or.inl ⟨hdc, hca⟩)
      
    · exact Or.inr (Or.inr ⟨hca, hab.trans hbd⟩)
      
  sbtw_iff_btw_not_btw := fun a b c => by
    simp_rw [lt_iff_le_not_leₓ]
    set x₀ := a ≤ b
    set x₁ := b ≤ c
    set x₂ := c ≤ a
    have : x₀ → x₁ → a ≤ c := le_transₓ
    have : x₁ → x₂ → b ≤ a := le_transₓ
    have : x₂ → x₀ → c ≤ b := le_transₓ
    clear_value x₀ x₁ x₂
    tauto!

/-- The circular partial order obtained from "looping around" a partial order.
See note [reducible non-instances]. -/
@[reducible]
def PartialOrderₓ.toCircularPartialOrder (α : Type _) [PartialOrderₓ α] : CircularPartialOrder α :=
  { Preorderₓ.toCircularPreorder α with
    btw_antisymm := fun a b c => by
      rintro (⟨hab, hbc⟩ | ⟨hbc, hca⟩ | ⟨hca, hab⟩) (⟨hcb, hba⟩ | ⟨hba, hac⟩ | ⟨hac, hcb⟩)
      · exact Or.inl (hab.antisymm hba)
        
      · exact Or.inl (hab.antisymm hba)
        
      · exact Or.inr (Or.inl <| hbc.antisymm hcb)
        
      · exact Or.inr (Or.inl <| hbc.antisymm hcb)
        
      · exact Or.inr (Or.inr <| hca.antisymm hac)
        
      · exact Or.inr (Or.inl <| hbc.antisymm hcb)
        
      · exact Or.inl (hab.antisymm hba)
        
      · exact Or.inl (hab.antisymm hba)
        
      · exact Or.inr (Or.inr <| hca.antisymm hac)
         }

/-- The circular order obtained from "looping around" a linear order.
See note [reducible non-instances]. -/
@[reducible]
def LinearOrderₓ.toCircularOrder (α : Type _) [LinearOrderₓ α] : CircularOrder α :=
  { PartialOrderₓ.toCircularPartialOrder α with
    btw_total := fun a b c => by
      cases' le_totalₓ a b with hab hba <;> cases' le_totalₓ b c with hbc hcb <;> cases' le_totalₓ c a with hca hac
      · exact Or.inl (Or.inl ⟨hab, hbc⟩)
        
      · exact Or.inl (Or.inl ⟨hab, hbc⟩)
        
      · exact Or.inl (Or.inr <| Or.inr ⟨hca, hab⟩)
        
      · exact Or.inr (Or.inr <| Or.inr ⟨hac, hcb⟩)
        
      · exact Or.inl (Or.inr <| Or.inl ⟨hbc, hca⟩)
        
      · exact Or.inr (Or.inr <| Or.inl ⟨hba, hac⟩)
        
      · exact Or.inr (Or.inl ⟨hcb, hba⟩)
        
      · exact Or.inr (Or.inr <| Or.inl ⟨hba, hac⟩)
         }

/-! ### Dual constructions -/


section OrderDual

instance (α : Type _) [HasBtw α] : HasBtw αᵒᵈ :=
  ⟨fun a b c : α => Btw c b a⟩

instance (α : Type _) [HasSbtw α] : HasSbtw αᵒᵈ :=
  ⟨fun a b c : α => Sbtw c b a⟩

instance (α : Type _) [h : CircularPreorder α] : CircularPreorder αᵒᵈ :=
  { OrderDual.hasBtw α, OrderDual.hasSbtw α with btw_refl := btw_refl, btw_cyclic_left := fun a b c => btw_cyclic_right,
    sbtw_trans_left := fun a b c d habc hbdc => hbdc.trans_right habc,
    sbtw_iff_btw_not_btw := fun a b c => @sbtw_iff_btw_not_btw α _ c b a }

instance (α : Type _) [CircularPartialOrder α] : CircularPartialOrder αᵒᵈ :=
  { OrderDual.circularPreorder α with btw_antisymm := fun a b c habc hcba => @btw_antisymm α _ _ _ _ hcba habc }

instance (α : Type _) [CircularOrder α] : CircularOrder αᵒᵈ :=
  { OrderDual.circularPartialOrder α with btw_total := fun a b c => btw_total c b a }

end OrderDual

