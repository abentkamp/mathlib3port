/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro, Oliver Nash
-/
import Mathbin.Data.Finset.Card

/-!
# Finsets in product types

This file defines finset constructions on the product type `α × β`. Beware not to confuse with the
`finset.prod` operation which computes the multiplicative product.

## Main declarations

* `finset.product`: Turns `s : finset α`, `t : finset β` into their product in `finset (α × β)`.
* `finset.diag`: For `s : finset α`, `s.diag` is the `finset (α × α)` of pairs `(a, a)` with
  `a ∈ s`.
* `finset.off_diag`: For `s : finset α`, `s.off_diag` is the `finset (α × α)` of pairs `(a, b)` with
  `a, b ∈ s` and `a ≠ b`.
-/


open Multiset

variable {α β γ : Type _}

namespace Finset

/-! ### prod -/


section Prod

variable {s s' : Finset α} {t t' : Finset β} {a : α} {b : β}

/-- `product s t` is the set of pairs `(a, b)` such that `a ∈ s` and `b ∈ t`. -/
protected def product (s : Finset α) (t : Finset β) : Finset (α × β) :=
  ⟨_, s.Nodup.product t.Nodup⟩

-- mathport name: finset.product
infixr:82
  " ×ˢ " =>-- This notation binds more strongly than (pre)images, unions and intersections.
  Finset.product

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem product_val : (s ×ˢ t).1 = s.1 ×ˢ t.1 :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem mem_product {p : α × β} : p ∈ s ×ˢ t ↔ p.1 ∈ s ∧ p.2 ∈ t :=
  mem_product

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem mk_mem_product (ha : a ∈ s) (hb : b ∈ t) : (a, b) ∈ s ×ˢ t :=
  mem_product.2 ⟨ha, hb⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp, norm_cast]
theorem coe_product (s : Finset α) (t : Finset β) : (↑(s ×ˢ t) : Set (α × β)) = s ×ˢ t :=
  Set.ext fun x => Finset.mem_product

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem subset_product [DecidableEq α] [DecidableEq β] {s : Finset (α × β)} :
    s ⊆ s.Image Prod.fst ×ˢ s.Image Prod.snd := fun p hp => mem_product.2 ⟨mem_image_of_mem _ hp, mem_image_of_mem _ hp⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_subset_product (hs : s ⊆ s') (ht : t ⊆ t') : s ×ˢ t ⊆ s' ×ˢ t' := fun ⟨x, y⟩ h =>
  mem_product.2 ⟨hs (mem_product.1 h).1, ht (mem_product.1 h).2⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_subset_product_left (hs : s ⊆ s') : s ×ˢ t ⊆ s' ×ˢ t :=
  product_subset_product hs (Subset.refl _)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_subset_product_right (ht : t ⊆ t') : s ×ˢ t ⊆ s ×ˢ t' :=
  product_subset_product (Subset.refl _) ht

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_eq_bUnion [DecidableEq α] [DecidableEq β] (s : Finset α) (t : Finset β) :
    s ×ˢ t = s.bUnion fun a => t.Image fun b => (a, b) :=
  ext fun ⟨x, y⟩ => by
    simp only [mem_product, mem_bUnion, mem_image, exists_prop, Prod.mk.inj_iffₓ, And.left_comm,
      exists_and_distrib_left, exists_eq_right, exists_eq_left]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_eq_bUnion_right [DecidableEq α] [DecidableEq β] (s : Finset α) (t : Finset β) :
    s ×ˢ t = t.bUnion fun b => s.Image fun a => (a, b) :=
  ext fun ⟨x, y⟩ => by
    simp only [mem_product, mem_bUnion, mem_image, exists_prop, Prod.mk.inj_iffₓ, And.left_comm,
      exists_and_distrib_left, exists_eq_right, exists_eq_left]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- See also `finset.sup_product_left`. -/
@[simp]
theorem product_bUnion [DecidableEq γ] (s : Finset α) (t : Finset β) (f : α × β → Finset γ) :
    (s ×ˢ t).bUnion f = s.bUnion fun a => t.bUnion fun b => f (a, b) := by
  classical
  simp_rw [product_eq_bUnion, bUnion_bUnion, image_bUnion]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem card_product (s : Finset α) (t : Finset β) : card (s ×ˢ t) = card s * card t :=
  Multiset.card_product _ _

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem filter_product (p : α → Prop) (q : β → Prop) [DecidablePred p] [DecidablePred q] :
    ((s ×ˢ t).filter fun x : α × β => p x.1 ∧ q x.2) = s.filter p ×ˢ t.filter q := by
  ext ⟨a, b⟩
  simp only [mem_filter, mem_product]
  exact and_and_and_comm (a ∈ s) (b ∈ t) (p a) (q b)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem filter_product_card (s : Finset α) (t : Finset β) (p : α → Prop) (q : β → Prop) [DecidablePred p]
    [DecidablePred q] :
    ((s ×ˢ t).filter fun x : α × β => p x.1 ↔ q x.2).card =
      (s.filter p).card * (t.filter q).card + (s.filter (Not ∘ p)).card * (t.filter (Not ∘ q)).card :=
  by
  classical
  rw [← card_product, ← card_product, ← filter_product, ← filter_product, ← card_union_eq]
  · apply congr_argₓ
    ext ⟨a, b⟩
    simp only [filter_union_right, mem_filter, mem_product]
    constructor <;> intro h <;> use h.1
    simp only [Function.comp_app, and_selfₓ, h.2, em (q b)]
    cases h.2 <;>
      · try
          simp at h_1
        simp [h_1]
        
    
  · rw [disjoint_iff]
    change _ ∩ _ = ∅
    ext ⟨a, b⟩
    rw [mem_inter]
    simp only [and_imp, mem_filter, not_and, not_not, Function.comp_app, iff_falseₓ, mem_product, not_mem_empty]
    intros
    assumption
    

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem empty_product (t : Finset β) : (∅ : Finset α) ×ˢ t = ∅ :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_empty (s : Finset α) : s ×ˢ (∅ : Finset β) = ∅ :=
  eq_empty_of_forall_not_mem fun x h => (Finset.mem_product.1 h).2

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Nonempty.product (hs : s.Nonempty) (ht : t.Nonempty) : (s ×ˢ t).Nonempty :=
  let ⟨x, hx⟩ := hs
  let ⟨y, hy⟩ := ht
  ⟨(x, y), mem_product.2 ⟨hx, hy⟩⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Nonempty.fst (h : (s ×ˢ t).Nonempty) : s.Nonempty :=
  let ⟨xy, hxy⟩ := h
  ⟨xy.1, (mem_product.1 hxy).1⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Nonempty.snd (h : (s ×ˢ t).Nonempty) : t.Nonempty :=
  let ⟨xy, hxy⟩ := h
  ⟨xy.2, (mem_product.1 hxy).2⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem nonempty_product : (s ×ˢ t).Nonempty ↔ s.Nonempty ∧ t.Nonempty :=
  ⟨fun h => ⟨h.fst, h.snd⟩, fun h => h.1.product h.2⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem product_eq_empty {s : Finset α} {t : Finset β} : s ×ˢ t = ∅ ↔ s = ∅ ∨ t = ∅ := by
  rw [← not_nonempty_iff_eq_empty, nonempty_product, not_and_distrib, not_nonempty_iff_eq_empty,
    not_nonempty_iff_eq_empty]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem singleton_product {a : α} : ({a} : Finset α) ×ˢ t = t.map ⟨Prod.mk a, Prod.mk.inj_leftₓ _⟩ := by
  ext ⟨x, y⟩
  simp [And.left_comm, eq_comm]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem product_singleton {b : β} : s ×ˢ {b} = s.map ⟨fun i => (i, b), Prod.mk.inj_rightₓ _⟩ := by
  ext ⟨x, y⟩
  simp [And.left_comm, eq_comm]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem singleton_product_singleton {a : α} {b : β} : ({a} : Finset α) ×ˢ ({b} : Finset β) = {(a, b)} := by
  simp only [product_singleton, Function.Embedding.coe_fn_mk, map_singleton]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem union_product [DecidableEq α] [DecidableEq β] : (s ∪ s') ×ˢ t = s ×ˢ t ∪ s' ×ˢ t := by
  ext ⟨x, y⟩
  simp only [or_and_distrib_right, mem_union, mem_product]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem product_union [DecidableEq α] [DecidableEq β] : s ×ˢ (t ∪ t') = s ×ˢ t ∪ s ×ˢ t' := by
  ext ⟨x, y⟩
  simp only [and_or_distrib_left, mem_union, mem_product]

end Prod

section Diag

variable (s t : Finset α) [DecidableEq α]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- Given a finite set `s`, the diagonal, `s.diag` is the set of pairs of the form `(a, a)` for
`a ∈ s`. -/
def diag :=
  (s ×ˢ s).filter fun a : α × α => a.fst = a.snd

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- Given a finite set `s`, the off-diagonal, `s.off_diag` is the set of pairs `(a, b)` with `a ≠ b`
for `a, b ∈ s`. -/
def offDiag :=
  (s ×ˢ s).filter fun a : α × α => a.fst ≠ a.snd

@[simp]
theorem mem_diag (x : α × α) : x ∈ s.diag ↔ x.1 ∈ s ∧ x.1 = x.2 := by
  simp only [diag, mem_filter, mem_product]
  constructor <;> intro h <;> simp only [h, and_trueₓ, eq_self_iff_true, and_selfₓ]
  rw [← h.2]
  exact h.1

@[simp]
theorem mem_off_diag (x : α × α) : x ∈ s.offDiag ↔ x.1 ∈ s ∧ x.2 ∈ s ∧ x.1 ≠ x.2 := by
  simp only [off_diag, mem_filter, mem_product]
  constructor <;> intro h <;> simp only [h, Ne.def, not_false_iff, and_selfₓ]

@[simp]
theorem diag_card : (diag s).card = s.card := by
  suffices diag s = s.image fun a => (a, a) by
    rw [this]
    apply card_image_of_inj_on
    exact fun x1 h1 x2 h2 h3 => (Prod.mk.inj h3).1
  ext ⟨a₁, a₂⟩
  rw [mem_diag]
  constructor <;> intro h <;> rw [Finset.mem_image] at *
  · use a₁, h.1, prod.mk.inj_iff.mpr ⟨rfl, h.2⟩
    
  · rcases h with ⟨a, h1, h2⟩
    have h := Prod.mk.inj h2
    rw [← h.1, ← h.2]
    use h1
    

@[simp]
theorem off_diag_card : (offDiag s).card = s.card * s.card - s.card := by
  suffices (diag s).card + (off_diag s).card = s.card * s.card by
    nth_rw 2[← s.diag_card]
    simp only [diag_card] at *
    rw [tsub_eq_of_eq_add_rev]
    rw [this]
  rw [← card_product]
  apply filter_card_add_filter_neg_card_eq_card

@[simp]
theorem diag_empty : (∅ : Finset α).diag = ∅ :=
  rfl

@[simp]
theorem off_diag_empty : (∅ : Finset α).offDiag = ∅ :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem diag_union_off_diag : s.diag ∪ s.offDiag = s ×ˢ s :=
  filter_union_filter_neg_eq _ _

@[simp]
theorem disjoint_diag_off_diag : Disjoint s.diag s.offDiag :=
  disjoint_filter_filter_neg _ _

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_sdiff_diag : s ×ˢ s \ s.diag = s.offDiag := by
  rw [← diag_union_off_diag, union_comm, union_sdiff_self, sdiff_eq_self_of_disjoint (disjoint_diag_off_diag _).symm]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem product_sdiff_off_diag : s ×ˢ s \ s.offDiag = s.diag := by
  rw [← diag_union_off_diag, union_sdiff_self, sdiff_eq_self_of_disjoint (disjoint_diag_off_diag _)]

theorem diag_union : (s ∪ t).diag = s.diag ∪ t.diag := by
  ext ⟨i, j⟩
  simp only [mem_diag, mem_union, or_and_distrib_right]

variable {s t}

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem off_diag_union (h : Disjoint s t) : (s ∪ t).offDiag = s.offDiag ∪ t.offDiag ∪ s ×ˢ t ∪ t ×ˢ s := by
  rw [off_diag, union_product, product_union, product_union, union_comm _ (t ×ˢ t), union_assoc,
    union_left_comm (s ×ˢ t), ← union_assoc, filter_union, filter_union, ← off_diag, ← off_diag, filter_true_of_mem, ←
    union_assoc]
  simp only [mem_union, mem_product, Ne.def, Prod.forallₓ]
  rintro i j (⟨hi, hj⟩ | ⟨hi, hj⟩)
  · exact h.forall_ne_finset hi hj
    
  · exact h.symm.forall_ne_finset hi hj
    

variable (a : α)

@[simp]
theorem off_diag_singleton : ({a} : Finset α).offDiag = ∅ := by
  simp [← Finset.card_eq_zero]

theorem diag_singleton : ({a} : Finset α).diag = {(a, a)} := by
  rw [← product_sdiff_off_diag, off_diag_singleton, sdiff_empty, singleton_product_singleton]

theorem diag_insert : (insert a s).diag = insert (a, a) s.diag := by
  rw [insert_eq, insert_eq, diag_union, diag_singleton]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem off_diag_insert (has : a ∉ s) : (insert a s).offDiag = s.offDiag ∪ {a} ×ˢ s ∪ s ×ˢ {a} := by
  rw [insert_eq, union_comm, off_diag_union (disjoint_singleton_right.2 has), off_diag_singleton, union_empty,
    union_right_comm]

end Diag

end Finset

