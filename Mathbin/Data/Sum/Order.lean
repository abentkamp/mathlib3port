/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathbin.Order.Hom.Basic

/-!
# Orders on a sum type

This file defines the disjoint sum and the linear (aka lexicographic) sum of two orders and provides
relation instances for `sum.lift_rel` and `sum.lex`.

We declare the disjoint sum of orders as the default set of instances. The linear order goes on a
type synonym.

## Main declarations

* `sum.has_le`, `sum.has_lt`: Disjoint sum of orders.
* `sum.lex.has_le`, `sum.lex.has_lt`: Lexicographic/linear sum of orders.

## Notation

* `α ⊕ₗ β`:  The linear sum of `α` and `β`.
-/


variable {α β γ δ : Type _}

namespace Sum

/-! ### Unbundled relation classes -/


section LiftRel

variable (r : α → α → Prop) (s : β → β → Prop)

@[refl]
theorem LiftRel.refl [IsRefl α r] [IsRefl β s] : ∀ x, LiftRel r s x x
  | inl a => LiftRel.inl (refl _)
  | inr a => LiftRel.inr (refl _)

instance [IsRefl α r] [IsRefl β s] : IsRefl (Sum α β) (LiftRel r s) :=
  ⟨LiftRel.refl _ _⟩

instance [IsIrrefl α r] [IsIrrefl β s] : IsIrrefl (Sum α β) (LiftRel r s) :=
  ⟨by
    rintro _ (⟨a, _, h⟩ | ⟨a, _, h⟩) <;> exact irrefl _ h⟩

@[trans]
theorem LiftRel.trans [IsTrans α r] [IsTrans β s] : ∀ {a b c}, LiftRel r s a b → LiftRel r s b c → LiftRel r s a c
  | _, _, _, lift_rel.inl hab, lift_rel.inl hbc => lift_rel.inl <| trans hab hbc
  | _, _, _, lift_rel.inr hab, lift_rel.inr hbc => lift_rel.inr <| trans hab hbc

instance [IsTrans α r] [IsTrans β s] : IsTrans (Sum α β) (LiftRel r s) :=
  ⟨fun _ _ _ => LiftRel.trans _ _⟩

instance [IsAntisymm α r] [IsAntisymm β s] : IsAntisymm (Sum α β) (LiftRel r s) :=
  ⟨by
    rintro _ _ (⟨a, b, hab⟩ | ⟨a, b, hab⟩) (⟨_, _, hba⟩ | ⟨_, _, hba⟩) <;> rw [antisymm hab hba]⟩

end LiftRel

section Lex

variable (r : α → α → Prop) (s : β → β → Prop)

instance [IsRefl α r] [IsRefl β s] : IsRefl (Sum α β) (Lex r s) :=
  ⟨by
    rintro (a | a)
    exacts[lex.inl (refl _), lex.inr (refl _)]⟩

instance [IsIrrefl α r] [IsIrrefl β s] : IsIrrefl (Sum α β) (Lex r s) :=
  ⟨by
    rintro _ (⟨a, _, h⟩ | ⟨a, _, h⟩) <;> exact irrefl _ h⟩

instance [IsTrans α r] [IsTrans β s] : IsTrans (Sum α β) (Lex r s) :=
  ⟨by
    rintro _ _ _ (⟨a, b, hab⟩ | ⟨a, b, hab⟩) (⟨_, c, hbc⟩ | ⟨_, c, hbc⟩)
    exacts[lex.inl (trans hab hbc), lex.sep _ _, lex.inr (trans hab hbc), lex.sep _ _]⟩

instance [IsAntisymm α r] [IsAntisymm β s] : IsAntisymm (Sum α β) (Lex r s) :=
  ⟨by
    rintro _ _ (⟨a, b, hab⟩ | ⟨a, b, hab⟩) (⟨_, _, hba⟩ | ⟨_, _, hba⟩) <;> rw [antisymm hab hba]⟩

instance [IsTotal α r] [IsTotal β s] : IsTotal (Sum α β) (Lex r s) :=
  ⟨fun a b =>
    match a, b with
    | inl a, inl b => (total_of r a b).imp Lex.inl Lex.inl
    | inl a, inr b => Or.inl (Lex.sep _ _)
    | inr a, inl b => Or.inr (Lex.sep _ _)
    | inr a, inr b => (total_of s a b).imp Lex.inr Lex.inr⟩

instance [IsTrichotomous α r] [IsTrichotomous β s] : IsTrichotomous (Sum α β) (Lex r s) :=
  ⟨fun a b =>
    match a, b with
    | inl a, inl b => (trichotomous_of r a b).imp3 Lex.inl (congr_argₓ _) Lex.inl
    | inl a, inr b => Or.inl (Lex.sep _ _)
    | inr a, inl b => Or.inr (Or.inr <| Lex.sep _ _)
    | inr a, inr b => (trichotomous_of s a b).imp3 Lex.inr (congr_argₓ _) Lex.inr⟩

instance [IsWellOrder α r] [IsWellOrder β s] :
    IsWellOrder (Sum α β) (Sum.Lex r s) where wf := Sum.lex_wf IsWellFounded.wf IsWellFounded.wf

end Lex

/-! ### Disjoint sum of two orders -/


section Disjoint

instance [LE α] [LE β] : LE (Sum α β) :=
  ⟨LiftRel (· ≤ ·) (· ≤ ·)⟩

instance [LT α] [LT β] : LT (Sum α β) :=
  ⟨LiftRel (· < ·) (· < ·)⟩

theorem le_def [LE α] [LE β] {a b : Sum α β} : a ≤ b ↔ LiftRel (· ≤ ·) (· ≤ ·) a b :=
  Iff.rfl

theorem lt_def [LT α] [LT β] {a b : Sum α β} : a < b ↔ LiftRel (· < ·) (· < ·) a b :=
  Iff.rfl

@[simp]
theorem inl_le_inl_iff [LE α] [LE β] {a b : α} : (inl a : Sum α β) ≤ inl b ↔ a ≤ b :=
  lift_rel_inl_inl

@[simp]
theorem inr_le_inr_iff [LE α] [LE β] {a b : β} : (inr a : Sum α β) ≤ inr b ↔ a ≤ b :=
  lift_rel_inr_inr

@[simp]
theorem inl_lt_inl_iff [LT α] [LT β] {a b : α} : (inl a : Sum α β) < inl b ↔ a < b :=
  lift_rel_inl_inl

@[simp]
theorem inr_lt_inr_iff [LT α] [LT β] {a b : β} : (inr a : Sum α β) < inr b ↔ a < b :=
  lift_rel_inr_inr

@[simp]
theorem not_inl_le_inr [LE α] [LE β] {a : α} {b : β} : ¬inl b ≤ inr a :=
  not_lift_rel_inl_inr

@[simp]
theorem not_inl_lt_inr [LT α] [LT β] {a : α} {b : β} : ¬inl b < inr a :=
  not_lift_rel_inl_inr

@[simp]
theorem not_inr_le_inl [LE α] [LE β] {a : α} {b : β} : ¬inr b ≤ inl a :=
  not_lift_rel_inr_inl

@[simp]
theorem not_inr_lt_inl [LT α] [LT β] {a : α} {b : β} : ¬inr b < inl a :=
  not_lift_rel_inr_inl

section Preorderₓ

variable [Preorderₓ α] [Preorderₓ β]

instance : Preorderₓ (Sum α β) :=
  { Sum.hasLe, Sum.hasLt with le_refl := fun _ => refl _, le_trans := fun _ _ _ => trans,
    lt_iff_le_not_le := fun a b => by
      refine' ⟨fun hab => ⟨hab.mono (fun _ _ => le_of_ltₓ) fun _ _ => le_of_ltₓ, _⟩, _⟩
      · rintro (⟨b, a, hba⟩ | ⟨b, a, hba⟩)
        · exact hba.not_lt (inl_lt_inl_iff.1 hab)
          
        · exact hba.not_lt (inr_lt_inr_iff.1 hab)
          
        
      · rintro ⟨⟨a, b, hab⟩ | ⟨a, b, hab⟩, hba⟩
        · exact lift_rel.inl (hab.lt_of_not_le fun h => hba <| lift_rel.inl h)
          
        · exact lift_rel.inr (hab.lt_of_not_le fun h => hba <| lift_rel.inr h)
          
         }

theorem inl_mono : Monotone (inl : α → Sum α β) := fun a b => LiftRel.inl

theorem inr_mono : Monotone (inr : β → Sum α β) := fun a b => LiftRel.inr

theorem inl_strict_mono : StrictMono (inl : α → Sum α β) := fun a b => LiftRel.inl

theorem inr_strict_mono : StrictMono (inr : β → Sum α β) := fun a b => LiftRel.inr

end Preorderₓ

instance [PartialOrderₓ α] [PartialOrderₓ β] : PartialOrderₓ (Sum α β) :=
  { Sum.preorder with le_antisymm := fun _ _ => antisymm }

instance no_min_order [LT α] [LT β] [NoMinOrder α] [NoMinOrder β] : NoMinOrder (Sum α β) :=
  ⟨fun a =>
    match a with
    | inl a =>
      let ⟨b, h⟩ := exists_lt a
      ⟨inl b, inl_lt_inl_iff.2 h⟩
    | inr a =>
      let ⟨b, h⟩ := exists_lt a
      ⟨inr b, inr_lt_inr_iff.2 h⟩⟩

instance no_max_order [LT α] [LT β] [NoMaxOrder α] [NoMaxOrder β] : NoMaxOrder (Sum α β) :=
  ⟨fun a =>
    match a with
    | inl a =>
      let ⟨b, h⟩ := exists_gt a
      ⟨inl b, inl_lt_inl_iff.2 h⟩
    | inr a =>
      let ⟨b, h⟩ := exists_gt a
      ⟨inr b, inr_lt_inr_iff.2 h⟩⟩

@[simp]
theorem no_min_order_iff [LT α] [LT β] : NoMinOrder (Sum α β) ↔ NoMinOrder α ∧ NoMinOrder β :=
  ⟨fun _ =>
    ⟨⟨fun a => by
        obtain ⟨b | b, h⟩ := exists_lt (inl a : Sum α β)
        · exact ⟨b, inl_lt_inl_iff.1 h⟩
          
        · exact (not_inr_lt_inl h).elim
          ⟩,
      ⟨fun a => by
        obtain ⟨b | b, h⟩ := exists_lt (inr a : Sum α β)
        · exact (not_inl_lt_inr h).elim
          
        · exact ⟨b, inr_lt_inr_iff.1 h⟩
          ⟩⟩,
    fun h => @Sum.no_min_order _ _ _ _ h.1 h.2⟩

@[simp]
theorem no_max_order_iff [LT α] [LT β] : NoMaxOrder (Sum α β) ↔ NoMaxOrder α ∧ NoMaxOrder β :=
  ⟨fun _ =>
    ⟨⟨fun a => by
        obtain ⟨b | b, h⟩ := exists_gt (inl a : Sum α β)
        · exact ⟨b, inl_lt_inl_iff.1 h⟩
          
        · exact (not_inl_lt_inr h).elim
          ⟩,
      ⟨fun a => by
        obtain ⟨b | b, h⟩ := exists_gt (inr a : Sum α β)
        · exact (not_inr_lt_inl h).elim
          
        · exact ⟨b, inr_lt_inr_iff.1 h⟩
          ⟩⟩,
    fun h => @Sum.no_max_order _ _ _ _ h.1 h.2⟩

instance densely_ordered [LT α] [LT β] [DenselyOrdered α] [DenselyOrdered β] : DenselyOrdered (Sum α β) :=
  ⟨fun a b h =>
    match a, b, h with
    | inl a, inl b, lift_rel.inl h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inl c), LiftRel.inl ha, LiftRel.inl hb⟩
    | inr a, inr b, lift_rel.inr h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inr c), LiftRel.inr ha, LiftRel.inr hb⟩⟩

@[simp]
theorem densely_ordered_iff [LT α] [LT β] : DenselyOrdered (Sum α β) ↔ DenselyOrdered α ∧ DenselyOrdered β :=
  ⟨fun _ =>
    ⟨⟨fun a b h => by
        obtain ⟨c | c, ha, hb⟩ := @exists_between (Sum α β) _ _ _ _ (inl_lt_inl_iff.2 h)
        · exact ⟨c, inl_lt_inl_iff.1 ha, inl_lt_inl_iff.1 hb⟩
          
        · exact (not_inl_lt_inr ha).elim
          ⟩,
      ⟨fun a b h => by
        obtain ⟨c | c, ha, hb⟩ := @exists_between (Sum α β) _ _ _ _ (inr_lt_inr_iff.2 h)
        · exact (not_inl_lt_inr hb).elim
          
        · exact ⟨c, inr_lt_inr_iff.1 ha, inr_lt_inr_iff.1 hb⟩
          ⟩⟩,
    fun h => @Sum.densely_ordered _ _ _ _ h.1 h.2⟩

@[simp]
theorem swap_le_swap_iff [LE α] [LE β] {a b : Sum α β} : a.swap ≤ b.swap ↔ a ≤ b :=
  lift_rel_swap_iff

@[simp]
theorem swap_lt_swap_iff [LT α] [LT β] {a b : Sum α β} : a.swap < b.swap ↔ a < b :=
  lift_rel_swap_iff

end Disjoint

/-! ### Linear sum of two orders -/


namespace Lex

-- mathport name: «expr ⊕ₗ »
notation:30 α " ⊕ₗ " β:29 => Lex (Sum α β)

--TODO: Can we make `inlₗ`, `inrₗ` `local notation`?
/-- Lexicographical `sum.inl`. Only used for pattern matching. -/
@[matchPattern]
abbrev _root_.sum.inlₗ (x : α) : α ⊕ₗ β :=
  toLex (Sum.inl x)

/-- Lexicographical `sum.inr`. Only used for pattern matching. -/
@[matchPattern]
abbrev _root_.sum.inrₗ (x : β) : α ⊕ₗ β :=
  toLex (Sum.inr x)

/-- The linear/lexicographical `≤` on a sum. -/
instance hasLe [LE α] [LE β] : LE (α ⊕ₗ β) :=
  ⟨Lex (· ≤ ·) (· ≤ ·)⟩

/-- The linear/lexicographical `<` on a sum. -/
instance hasLt [LT α] [LT β] : LT (α ⊕ₗ β) :=
  ⟨Lex (· < ·) (· < ·)⟩

@[simp]
theorem to_lex_le_to_lex [LE α] [LE β] {a b : Sum α β} : toLex a ≤ toLex b ↔ Lex (· ≤ ·) (· ≤ ·) a b :=
  Iff.rfl

@[simp]
theorem to_lex_lt_to_lex [LT α] [LT β] {a b : Sum α β} : toLex a < toLex b ↔ Lex (· < ·) (· < ·) a b :=
  Iff.rfl

theorem le_def [LE α] [LE β] {a b : α ⊕ₗ β} : a ≤ b ↔ Lex (· ≤ ·) (· ≤ ·) (ofLex a) (ofLex b) :=
  Iff.rfl

theorem lt_def [LT α] [LT β] {a b : α ⊕ₗ β} : a < b ↔ Lex (· < ·) (· < ·) (ofLex a) (ofLex b) :=
  Iff.rfl

@[simp]
theorem inl_le_inl_iff [LE α] [LE β] {a b : α} : toLex (inl a : Sum α β) ≤ toLex (inl b) ↔ a ≤ b :=
  lex_inl_inl

@[simp]
theorem inr_le_inr_iff [LE α] [LE β] {a b : β} : toLex (inr a : Sum α β) ≤ toLex (inr b) ↔ a ≤ b :=
  lex_inr_inr

@[simp]
theorem inl_lt_inl_iff [LT α] [LT β] {a b : α} : toLex (inl a : Sum α β) < toLex (inl b) ↔ a < b :=
  lex_inl_inl

@[simp]
theorem inr_lt_inr_iff [LT α] [LT β] {a b : β} : toLex (inr a : α ⊕ₗ β) < toLex (inr b) ↔ a < b :=
  lex_inr_inr

@[simp]
theorem inl_le_inr [LE α] [LE β] (a : α) (b : β) : toLex (inl a) ≤ toLex (inr b) :=
  Lex.sep _ _

@[simp]
theorem inl_lt_inr [LT α] [LT β] (a : α) (b : β) : toLex (inl a) < toLex (inr b) :=
  Lex.sep _ _

@[simp]
theorem not_inr_le_inl [LE α] [LE β] {a : α} {b : β} : ¬toLex (inr b) ≤ toLex (inl a) :=
  lex_inr_inl

@[simp]
theorem not_inr_lt_inl [LT α] [LT β] {a : α} {b : β} : ¬toLex (inr b) < toLex (inl a) :=
  lex_inr_inl

section Preorderₓ

variable [Preorderₓ α] [Preorderₓ β]

instance preorder : Preorderₓ (α ⊕ₗ β) :=
  { Lex.hasLe, Lex.hasLt with le_refl := refl_of (Lex (· ≤ ·) (· ≤ ·)),
    le_trans := fun _ _ _ => trans_of (Lex (· ≤ ·) (· ≤ ·)),
    lt_iff_le_not_le := fun a b => by
      refine' ⟨fun hab => ⟨hab.mono (fun _ _ => le_of_ltₓ) fun _ _ => le_of_ltₓ, _⟩, _⟩
      · rintro (⟨b, a, hba⟩ | ⟨b, a, hba⟩ | ⟨b, a⟩)
        · exact hba.not_lt (inl_lt_inl_iff.1 hab)
          
        · exact hba.not_lt (inr_lt_inr_iff.1 hab)
          
        · exact not_inr_lt_inl hab
          
        
      · rintro ⟨⟨a, b, hab⟩ | ⟨a, b, hab⟩ | ⟨a, b⟩, hba⟩
        · exact lex.inl (hab.lt_of_not_le fun h => hba <| lex.inl h)
          
        · exact lex.inr (hab.lt_of_not_le fun h => hba <| lex.inr h)
          
        · exact lex.sep _ _
          
         }

theorem to_lex_mono : Monotone (@toLex (Sum α β)) := fun a b h => h.Lex

theorem to_lex_strict_mono : StrictMono (@toLex (Sum α β)) := fun a b h => h.Lex

theorem inl_mono : Monotone (toLex ∘ inl : α → α ⊕ₗ β) :=
  to_lex_mono.comp inl_mono

theorem inr_mono : Monotone (toLex ∘ inr : β → α ⊕ₗ β) :=
  to_lex_mono.comp inr_mono

theorem inl_strict_mono : StrictMono (toLex ∘ inl : α → α ⊕ₗ β) :=
  to_lex_strict_mono.comp inl_strict_mono

theorem inr_strict_mono : StrictMono (toLex ∘ inr : β → α ⊕ₗ β) :=
  to_lex_strict_mono.comp inr_strict_mono

end Preorderₓ

instance partialOrder [PartialOrderₓ α] [PartialOrderₓ β] : PartialOrderₓ (α ⊕ₗ β) :=
  { Lex.preorder with le_antisymm := fun _ _ => antisymm_of (Lex (· ≤ ·) (· ≤ ·)) }

instance linearOrder [LinearOrderₓ α] [LinearOrderₓ β] : LinearOrderₓ (α ⊕ₗ β) :=
  { Lex.partialOrder with le_total := total_of (Lex (· ≤ ·) (· ≤ ·)), decidableLe := Lex.decidableRel,
    DecidableEq := Sum.decidableEq _ _ }

/-- The lexicographical bottom of a sum is the bottom of the left component. -/
instance orderBot [LE α] [OrderBot α] [LE β] : OrderBot (α ⊕ₗ β) where
  bot := inl ⊥
  bot_le := by
    rintro (a | b)
    · exact lex.inl bot_le
      
    · exact lex.sep _ _
      

@[simp]
theorem inl_bot [LE α] [OrderBot α] [LE β] : toLex (inl ⊥ : Sum α β) = ⊥ :=
  rfl

/-- The lexicographical top of a sum is the top of the right component. -/
instance orderTop [LE α] [LE β] [OrderTop β] : OrderTop (α ⊕ₗ β) where
  top := inr ⊤
  le_top := by
    rintro (a | b)
    · exact lex.sep _ _
      
    · exact lex.inr le_top
      

@[simp]
theorem inr_top [LE α] [LE β] [OrderTop β] : toLex (inr ⊤ : Sum α β) = ⊤ :=
  rfl

instance boundedOrder [LE α] [LE β] [OrderBot α] [OrderTop β] : BoundedOrder (α ⊕ₗ β) :=
  { Lex.orderBot, Lex.orderTop with }

instance no_min_order [LT α] [LT β] [NoMinOrder α] [NoMinOrder β] : NoMinOrder (α ⊕ₗ β) :=
  ⟨fun a =>
    match a with
    | inl a =>
      let ⟨b, h⟩ := exists_lt a
      ⟨toLex (inl b), inl_lt_inl_iff.2 h⟩
    | inr a =>
      let ⟨b, h⟩ := exists_lt a
      ⟨toLex (inr b), inr_lt_inr_iff.2 h⟩⟩

instance no_max_order [LT α] [LT β] [NoMaxOrder α] [NoMaxOrder β] : NoMaxOrder (α ⊕ₗ β) :=
  ⟨fun a =>
    match a with
    | inl a =>
      let ⟨b, h⟩ := exists_gt a
      ⟨toLex (inl b), inl_lt_inl_iff.2 h⟩
    | inr a =>
      let ⟨b, h⟩ := exists_gt a
      ⟨toLex (inr b), inr_lt_inr_iff.2 h⟩⟩

instance no_min_order_of_nonempty [LT α] [LT β] [NoMinOrder α] [Nonempty α] : NoMinOrder (α ⊕ₗ β) :=
  ⟨fun a =>
    match a with
    | inl a =>
      let ⟨b, h⟩ := exists_lt a
      ⟨toLex (inl b), inl_lt_inl_iff.2 h⟩
    | inr a => ⟨toLex (inl <| Classical.arbitrary α), inl_lt_inr _ _⟩⟩

instance no_max_order_of_nonempty [LT α] [LT β] [NoMaxOrder β] [Nonempty β] : NoMaxOrder (α ⊕ₗ β) :=
  ⟨fun a =>
    match a with
    | inl a => ⟨toLex (inr <| Classical.arbitrary β), inl_lt_inr _ _⟩
    | inr a =>
      let ⟨b, h⟩ := exists_gt a
      ⟨toLex (inr b), inr_lt_inr_iff.2 h⟩⟩

instance densely_ordered_of_no_max_order [LT α] [LT β] [DenselyOrdered α] [DenselyOrdered β] [NoMaxOrder α] :
    DenselyOrdered (α ⊕ₗ β) :=
  ⟨fun a b h =>
    match a, b, h with
    | inl a, inl b, lex.inl h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inl c), inl_lt_inl_iff.2 ha, inl_lt_inl_iff.2 hb⟩
    | inl a, inr b, lex.sep _ _ =>
      let ⟨c, h⟩ := exists_gt a
      ⟨toLex (inl c), inl_lt_inl_iff.2 h, inl_lt_inr _ _⟩
    | inr a, inr b, lex.inr h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inr c), inr_lt_inr_iff.2 ha, inr_lt_inr_iff.2 hb⟩⟩

instance densely_ordered_of_no_min_order [LT α] [LT β] [DenselyOrdered α] [DenselyOrdered β] [NoMinOrder β] :
    DenselyOrdered (α ⊕ₗ β) :=
  ⟨fun a b h =>
    match a, b, h with
    | inl a, inl b, lex.inl h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inl c), inl_lt_inl_iff.2 ha, inl_lt_inl_iff.2 hb⟩
    | inl a, inr b, lex.sep _ _ =>
      let ⟨c, h⟩ := exists_lt b
      ⟨toLex (inr c), inl_lt_inr _ _, inr_lt_inr_iff.2 h⟩
    | inr a, inr b, lex.inr h =>
      let ⟨c, ha, hb⟩ := exists_between h
      ⟨toLex (inr c), inr_lt_inr_iff.2 ha, inr_lt_inr_iff.2 hb⟩⟩

end Lex

end Sum

/-! ### Order isomorphisms -/


open OrderDual Sum

namespace OrderIso

variable [LE α] [LE β] [LE γ] (a : α) (b : β) (c : γ)

/-- `equiv.sum_comm` promoted to an order isomorphism. -/
@[simps apply]
def sumComm (α β : Type _) [LE α] [LE β] : Sum α β ≃o Sum β α :=
  { Equivₓ.sumComm α β with map_rel_iff' := fun a b => swap_le_swap_iff }

@[simp]
theorem sum_comm_symm (α β : Type _) [LE α] [LE β] : (OrderIso.sumComm α β).symm = OrderIso.sumComm β α :=
  rfl

/-- `equiv.sum_assoc` promoted to an order isomorphism. -/
def sumAssoc (α β γ : Type _) [LE α] [LE β] [LE γ] : Sum (Sum α β) γ ≃o Sum α (Sum β γ) :=
  { Equivₓ.sumAssoc α β γ with
    map_rel_iff' := by
      rintro ((a | a) | a) ((b | b) | b) <;> simp }

@[simp]
theorem sum_assoc_apply_inl_inl : sumAssoc α β γ (inl (inl a)) = inl a :=
  rfl

@[simp]
theorem sum_assoc_apply_inl_inr : sumAssoc α β γ (inl (inr b)) = inr (inl b) :=
  rfl

@[simp]
theorem sum_assoc_apply_inr : sumAssoc α β γ (inr c) = inr (inr c) :=
  rfl

@[simp]
theorem sum_assoc_symm_apply_inl : (sumAssoc α β γ).symm (inl a) = inl (inl a) :=
  rfl

@[simp]
theorem sum_assoc_symm_apply_inr_inl : (sumAssoc α β γ).symm (inr (inl b)) = inl (inr b) :=
  rfl

@[simp]
theorem sum_assoc_symm_apply_inr_inr : (sumAssoc α β γ).symm (inr (inr c)) = inr c :=
  rfl

/-- `order_dual` is distributive over `⊕` up to an order isomorphism. -/
def sumDualDistrib (α β : Type _) [LE α] [LE β] : (Sum α β)ᵒᵈ ≃o Sum αᵒᵈ βᵒᵈ :=
  { Equivₓ.refl _ with
    map_rel_iff' := by
      rintro (a | a) (b | b)
      · change inl (to_dual a) ≤ inl (to_dual b) ↔ to_dual (inl a) ≤ to_dual (inl b)
        simp only [to_dual_le_to_dual, inl_le_inl_iff]
        
      · exact iff_of_false not_inl_le_inr not_inr_le_inl
        
      · exact iff_of_false not_inr_le_inl not_inl_le_inr
        
      · change inr (to_dual a) ≤ inr (to_dual b) ↔ to_dual (inr a) ≤ to_dual (inr b)
        simp only [to_dual_le_to_dual, inr_le_inr_iff]
         }

@[simp]
theorem sum_dual_distrib_inl : sumDualDistrib α β (toDual (inl a)) = inl (toDual a) :=
  rfl

@[simp]
theorem sum_dual_distrib_inr : sumDualDistrib α β (toDual (inr b)) = inr (toDual b) :=
  rfl

@[simp]
theorem sum_dual_distrib_symm_inl : (sumDualDistrib α β).symm (inl (toDual a)) = toDual (inl a) :=
  rfl

@[simp]
theorem sum_dual_distrib_symm_inr : (sumDualDistrib α β).symm (inr (toDual b)) = toDual (inr b) :=
  rfl

/-- `equiv.sum_assoc` promoted to an order isomorphism. -/
def sumLexAssoc (α β γ : Type _) [LE α] [LE β] [LE γ] : (α ⊕ₗ β) ⊕ₗ γ ≃o α ⊕ₗ β ⊕ₗ γ :=
  { Equivₓ.sumAssoc α β γ with
    map_rel_iff' := fun a b =>
      ⟨fun h =>
        match a, b, h with
        | inlₗ (inlₗ a), inlₗ (inlₗ b), lex.inl h => lex.inl <| Lex.inl h
        | inlₗ (inlₗ a), inlₗ (inrₗ b), lex.sep _ _ => lex.inl <| Lex.sep _ _
        | inlₗ (inlₗ a), inrₗ b, lex.sep _ _ => Lex.sep _ _
        | inlₗ (inrₗ a), inlₗ (inrₗ b), lex.inr (lex.inl h) => lex.inl <| Lex.inr h
        | inlₗ (inrₗ a), inrₗ b, lex.inr (lex.sep _ _) => Lex.sep _ _
        | inrₗ a, inrₗ b, lex.inr (lex.inr h) => Lex.inr h,
        fun h =>
        match a, b, h with
        | inlₗ (inlₗ a), inlₗ (inlₗ b), lex.inl (lex.inl h) => Lex.inl h
        | inlₗ (inlₗ a), inlₗ (inrₗ b), lex.inl (lex.sep _ _) => Lex.sep _ _
        | inlₗ (inlₗ a), inrₗ b, lex.sep _ _ => Lex.sep _ _
        | inlₗ (inrₗ a), inlₗ (inrₗ b), lex.inl (lex.inr h) => lex.inr <| Lex.inl h
        | inlₗ (inrₗ a), inrₗ b, lex.sep _ _ => lex.inr <| Lex.sep _ _
        | inrₗ a, inrₗ b, lex.inr h => lex.inr <| Lex.inr h⟩ }

@[simp]
theorem sum_lex_assoc_apply_inl_inl : sumLexAssoc α β γ (toLex <| inl <| toLex <| inl a) = toLex (inl a) :=
  rfl

@[simp]
theorem sum_lex_assoc_apply_inl_inr :
    sumLexAssoc α β γ (toLex <| inl <| toLex <| inr b) = toLex (inr <| toLex <| inl b) :=
  rfl

@[simp]
theorem sum_lex_assoc_apply_inr : sumLexAssoc α β γ (toLex <| inr c) = toLex (inr <| toLex <| inr c) :=
  rfl

@[simp]
theorem sum_lex_assoc_symm_apply_inl : (sumLexAssoc α β γ).symm (inl a) = inl (inl a) :=
  rfl

@[simp]
theorem sum_lex_assoc_symm_apply_inr_inl : (sumLexAssoc α β γ).symm (inr (inl b)) = inl (inr b) :=
  rfl

@[simp]
theorem sum_lex_assoc_symm_apply_inr_inr : (sumLexAssoc α β γ).symm (inr (inr c)) = inr c :=
  rfl

/-- `order_dual` is antidistributive over `⊕ₗ` up to an order isomorphism. -/
def sumLexDualAntidistrib (α β : Type _) [LE α] [LE β] : (α ⊕ₗ β)ᵒᵈ ≃o βᵒᵈ ⊕ₗ αᵒᵈ :=
  { Equivₓ.sumComm α β with
    map_rel_iff' := by
      rintro (a | a) (b | b)
      simp
      · change toLex (inr <| to_dual a) ≤ toLex (inr <| to_dual b) ↔ to_dual (toLex <| inl a) ≤ to_dual (toLex <| inl b)
        simp only [to_dual_le_to_dual, lex.inl_le_inl_iff, lex.inr_le_inr_iff]
        
      · exact iff_of_false lex.not_inr_le_inl lex.not_inr_le_inl
        
      · exact iff_of_true (lex.inl_le_inr _ _) (lex.inl_le_inr _ _)
        
      · change toLex (inl <| to_dual a) ≤ toLex (inl <| to_dual b) ↔ to_dual (toLex <| inr a) ≤ to_dual (toLex <| inr b)
        simp only [to_dual_le_to_dual, lex.inl_le_inl_iff, lex.inr_le_inr_iff]
         }

@[simp]
theorem sum_lex_dual_antidistrib_inl : sumLexDualAntidistrib α β (toDual (inl a)) = inr (toDual a) :=
  rfl

@[simp]
theorem sum_lex_dual_antidistrib_inr : sumLexDualAntidistrib α β (toDual (inr b)) = inl (toDual b) :=
  rfl

@[simp]
theorem sum_lex_dual_antidistrib_symm_inl : (sumLexDualAntidistrib α β).symm (inl (toDual b)) = toDual (inr b) :=
  rfl

@[simp]
theorem sum_lex_dual_antidistrib_symm_inr : (sumLexDualAntidistrib α β).symm (inr (toDual a)) = toDual (inl a) :=
  rfl

end OrderIso

variable [LE α]

namespace WithBot

/-- `with_bot α` is order-isomorphic to `punit ⊕ₗ α`, by sending `⊥` to `punit.star` and `↑a` to
`a`. -/
def orderIsoPunitSumLex : WithBot α ≃o PUnit ⊕ₗ α :=
  ⟨(Equivₓ.optionEquivSumPunit α).trans <| (Equivₓ.sumComm _ _).trans toLex, by
    rintro (a | _) (b | _) <;> simp <;> exact not_coe_le_bot _⟩

@[simp]
theorem order_iso_punit_sum_lex_bot : @orderIsoPunitSumLex α _ ⊥ = toLex (inl PUnit.unit) :=
  rfl

@[simp]
theorem order_iso_punit_sum_lex_coe (a : α) : orderIsoPunitSumLex ↑a = toLex (inr a) :=
  rfl

@[simp]
theorem order_iso_punit_sum_lex_symm_inl (x : PUnit) : (@orderIsoPunitSumLex α _).symm (toLex <| inl x) = ⊥ :=
  rfl

@[simp]
theorem order_iso_punit_sum_lex_symm_inr (a : α) : orderIsoPunitSumLex.symm (toLex <| inr a) = a :=
  rfl

end WithBot

namespace WithTop

/-- `with_top α` is order-isomorphic to `α ⊕ₗ punit`, by sending `⊤` to `punit.star` and `↑a` to
`a`. -/
def orderIsoSumLexPunit : WithTop α ≃o α ⊕ₗ PUnit :=
  ⟨(Equivₓ.optionEquivSumPunit α).trans toLex, by
    rintro (a | _) (b | _) <;> simp <;> exact not_top_le_coe _⟩

@[simp]
theorem order_iso_sum_lex_punit_top : @orderIsoSumLexPunit α _ ⊤ = toLex (inr PUnit.unit) :=
  rfl

@[simp]
theorem order_iso_sum_lex_punit_coe (a : α) : orderIsoSumLexPunit ↑a = toLex (inl a) :=
  rfl

@[simp]
theorem order_iso_sum_lex_punit_symm_inr (x : PUnit) : (@orderIsoSumLexPunit α _).symm (toLex <| inr x) = ⊤ :=
  rfl

@[simp]
theorem order_iso_sum_lex_punit_symm_inl (a : α) : orderIsoSumLexPunit.symm (toLex <| inl a) = a :=
  rfl

end WithTop

