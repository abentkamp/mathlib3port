/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathbin.Data.Sigma.Lex
import Mathbin.Order.BoundedOrder

/-!
# Orders on a sigma type

This file defines two orders on a sigma type:
* The disjoint sum of orders. `a` is less `b` iff `a` and `b` are in the same summand and `a` is
  less than `b` there.
* The lexicographical order. `a` is less than `b` if its summand is strictly less than the summand
  of `b` or they are in the same summand and `a` is less than `b` there.

We make the disjoint sum of orders the default set of instances. The lexicographic order goes on a
type synonym.

## Notation

* `Σₗ i, α i`: Sigma type equipped with the lexicographic order. Type synonym of `Σ i, α i`.

## See also

Related files are:
* `data.finset.colex`: Colexicographic order on finite sets.
* `data.list.lex`: Lexicographic order on lists.
* `data.pi.lex`: Lexicographic order on `Πₗ i, α i`.
* `data.psigma.order`: Lexicographic order on `Σₗ' i, α i`. Basically a twin of this file.
* `data.prod.lex`: Lexicographic order on `α × β`.

## TODO

Prove that a sigma type is a `no_max_order`, `no_min_order`, `densely_ordered` when its summands
are.

Upgrade `equiv.sigma_congr_left`, `equiv.sigma_congr`, `equiv.sigma_assoc`,
`equiv.sigma_prod_of_equiv`, `equiv.sigma_equiv_prod`, ... to order isomorphisms.
-/


namespace Sigma

variable {ι : Type _} {α : ι → Type _}

/-! ### Disjoint sum of orders on `sigma` -/


/-- Disjoint sum of orders. `⟨i, a⟩ ≤ ⟨j, b⟩` iff `i = j` and `a ≤ b`. -/
inductive Le [∀ i, LE (α i)] : ∀ a b : Σi, α i, Prop
  | fiber (i : ι) (a b : α i) : a ≤ b → le ⟨i, a⟩ ⟨i, b⟩

/-- Disjoint sum of orders. `⟨i, a⟩ < ⟨j, b⟩` iff `i = j` and `a < b`. -/
inductive Lt [∀ i, LT (α i)] : ∀ a b : Σi, α i, Prop
  | fiber (i : ι) (a b : α i) : a < b → lt ⟨i, a⟩ ⟨i, b⟩

instance [∀ i, LE (α i)] : LE (Σi, α i) :=
  ⟨Le⟩

instance [∀ i, LT (α i)] : LT (Σi, α i) :=
  ⟨Lt⟩

@[simp]
theorem mk_le_mk_iff [∀ i, LE (α i)] {i : ι} {a b : α i} : (⟨i, a⟩ : Sigma α) ≤ ⟨i, b⟩ ↔ a ≤ b :=
  ⟨fun ⟨_, _, _, h⟩ => h, Le.fiber _ _ _⟩

@[simp]
theorem mk_lt_mk_iff [∀ i, LT (α i)] {i : ι} {a b : α i} : (⟨i, a⟩ : Sigma α) < ⟨i, b⟩ ↔ a < b :=
  ⟨fun ⟨_, _, _, h⟩ => h, Lt.fiber _ _ _⟩

theorem le_def [∀ i, LE (α i)] {a b : Σi, α i} : a ≤ b ↔ ∃ h : a.1 = b.1, h.rec a.2 ≤ b.2 := by
  constructor
  · rintro ⟨i, a, b, h⟩
    exact ⟨rfl, h⟩
    
  · obtain ⟨i, a⟩ := a
    obtain ⟨j, b⟩ := b
    rintro ⟨rfl : i = j, h⟩
    exact le.fiber _ _ _ h
    

theorem lt_def [∀ i, LT (α i)] {a b : Σi, α i} : a < b ↔ ∃ h : a.1 = b.1, h.rec a.2 < b.2 := by
  constructor
  · rintro ⟨i, a, b, h⟩
    exact ⟨rfl, h⟩
    
  · obtain ⟨i, a⟩ := a
    obtain ⟨j, b⟩ := b
    rintro ⟨rfl : i = j, h⟩
    exact lt.fiber _ _ _ h
    

instance [∀ i, Preorderₓ (α i)] : Preorderₓ (Σi, α i) :=
  { Sigma.hasLe, Sigma.hasLt with le_refl := fun ⟨i, a⟩ => Le.fiber i a a le_rflₓ,
    le_trans := by
      rintro _ _ _ ⟨i, a, b, hab⟩ ⟨_, _, c, hbc⟩
      exact le.fiber i a c (hab.trans hbc),
    lt_iff_le_not_le := fun _ _ => by
      constructor
      · rintro ⟨i, a, b, hab⟩
        rwa [mk_le_mk_iff, mk_le_mk_iff, ← lt_iff_le_not_leₓ]
        
      · rintro ⟨⟨i, a, b, hab⟩, h⟩
        rw [mk_le_mk_iff] at h
        exact mk_lt_mk_iff.2 (hab.lt_of_not_le h)
         }

instance [∀ i, PartialOrderₓ (α i)] : PartialOrderₓ (Σi, α i) :=
  { Sigma.preorder with
    le_antisymm := by
      rintro _ _ ⟨i, a, b, hab⟩ ⟨_, _, _, hba⟩
      exact ext rfl (heq_of_eq <| hab.antisymm hba) }

/-! ### Lexicographical order on `sigma` -/


namespace Lex

-- mathport name: «exprΣₗ , »
notation3"Σₗ "(...)", "r:(scoped p => Lex Sigma p) => r

/-- The lexicographical `≤` on a sigma type. -/
instance hasLe [LT ι] [∀ i, LE (α i)] : LE (Σₗ i, α i) :=
  ⟨Lex (· < ·) fun i => (· ≤ ·)⟩

/-- The lexicographical `<` on a sigma type. -/
instance hasLt [LT ι] [∀ i, LT (α i)] : LT (Σₗ i, α i) :=
  ⟨Lex (· < ·) fun i => (· < ·)⟩

/-- The lexicographical preorder on a sigma type. -/
instance preorder [Preorderₓ ι] [∀ i, Preorderₓ (α i)] : Preorderₓ (Σₗ i, α i) :=
  { Lex.hasLe, Lex.hasLt with le_refl := fun ⟨i, a⟩ => Lex.right a a le_rflₓ,
    le_trans := fun _ _ _ => trans_of ((Lex (· < ·)) fun _ => (· ≤ ·)),
    lt_iff_le_not_le := by
      refine' fun a b => ⟨fun hab => ⟨hab.mono_right fun i a b => le_of_ltₓ, _⟩, _⟩
      · rintro (⟨j, i, b, a, hji⟩ | ⟨i, b, a, hba⟩) <;> obtain ⟨_, _, _, _, hij⟩ | ⟨_, _, _, hab⟩ := hab
        · exact hij.not_lt hji
          
        · exact lt_irreflₓ _ hji
          
        · exact lt_irreflₓ _ hij
          
        · exact hab.not_le hba
          
        
      · rintro ⟨⟨i, j, a, b, hij⟩ | ⟨i, a, b, hab⟩, hba⟩
        · exact lex.left _ _ hij
          
        · exact lex.right _ _ (hab.lt_of_not_le fun h => hba <| lex.right _ _ h)
          
         }

/-- The lexicographical partial order on a sigma type. -/
instance partialOrder [Preorderₓ ι] [∀ i, PartialOrderₓ (α i)] : PartialOrderₓ (Σₗ i, α i) :=
  { Lex.preorder with le_antisymm := fun _ _ => antisymm_of ((Lex (· < ·)) fun _ => (· ≤ ·)) }

/-- The lexicographical linear order on a sigma type. -/
instance linearOrder [LinearOrderₓ ι] [∀ i, LinearOrderₓ (α i)] : LinearOrderₓ (Σₗ i, α i) :=
  { Lex.partialOrder with le_total := total_of ((Lex (· < ·)) fun _ => (· ≤ ·)), DecidableEq := Sigma.decidableEq,
    decidableLe := Lex.decidable _ _ }

/-- The lexicographical linear order on a sigma type. -/
instance orderBot [PartialOrderₓ ι] [OrderBot ι] [∀ i, Preorderₓ (α i)] [OrderBot (α ⊥)] : OrderBot (Σₗ i, α i) where
  bot := ⟨⊥, ⊥⟩
  bot_le := fun ⟨a, b⟩ => by
    obtain rfl | ha := eq_bot_or_bot_lt a
    · exact lex.right _ _ bot_le
      
    · exact lex.left _ _ ha
      

/-- The lexicographical linear order on a sigma type. -/
instance orderTop [PartialOrderₓ ι] [OrderTop ι] [∀ i, Preorderₓ (α i)] [OrderTop (α ⊤)] : OrderTop (Σₗ i, α i) where
  top := ⟨⊤, ⊤⟩
  le_top := fun ⟨a, b⟩ => by
    obtain rfl | ha := eq_top_or_lt_top a
    · exact lex.right _ _ le_top
      
    · exact lex.left _ _ ha
      

/-- The lexicographical linear order on a sigma type. -/
instance boundedOrder [PartialOrderₓ ι] [BoundedOrder ι] [∀ i, Preorderₓ (α i)] [OrderBot (α ⊥)] [OrderTop (α ⊤)] :
    BoundedOrder (Σₗ i, α i) :=
  { Lex.orderBot, Lex.orderTop with }

end Lex

end Sigma

