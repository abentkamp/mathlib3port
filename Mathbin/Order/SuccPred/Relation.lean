/-
Copyright (c) 2022 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn
-/
import Mathbin.Order.SuccPred.Basic

/-!
# Relations on types with a `succ_order`

This file contains properties about relations on types with a `succ_order`
and their closure operations (like the transitive closure).
-/


open Function Order Relation Set

section PartialSucc

variable {α : Type _} [PartialOrderₓ α] [SuccOrder α] [IsSuccArchimedean α]

/-- For `n ≤ m`, `(n, m)` is in the reflexive-transitive closure of `~` if `i ~ succ i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_succ_of_le (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ico n m, r i (succ i)) (hnm : n ≤ m) :
    ReflTransGen r n m := by
  revert h
  refine' Succ.rec _ _ hnm
  · intro h
    exact refl_trans_gen.refl
    
  · intro m hnm ih h
    have : refl_trans_gen r n m := ih fun i hi => h i ⟨hi.1, hi.2.trans_le <| le_succ m⟩
    cases' (le_succ m).eq_or_lt with hm hm
    · rwa [← hm]
      
    exact this.tail (h m ⟨hnm, hm⟩)
    

/-- For `m ≤ n`, `(n, m)` is in the reflexive-transitive closure of `~` if `succ i ~ i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_succ_of_ge (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ico m n, r (succ i) i) (hmn : m ≤ n) :
    ReflTransGen r n m := by
  rw [← refl_trans_gen_swap]
  exact refl_trans_gen_of_succ_of_le (swap r) h hmn

/-- For `n < m`, `(n, m)` is in the transitive closure of a relation `~` if `i ~ succ i`
  for all `i` between `n` and `m`. -/
theorem trans_gen_of_succ_of_lt (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ico n m, r i (succ i)) (hnm : n < m) :
    TransGen r n m :=
  (refl_trans_gen_iff_eq_or_trans_gen.mp <| refl_trans_gen_of_succ_of_le r h hnm.le).resolve_left hnm.ne'

/-- For `m < n`, `(n, m)` is in the transitive closure of a relation `~` if `succ i ~ i`
  for all `i` between `n` and `m`. -/
theorem trans_gen_of_succ_of_gt (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ico m n, r (succ i) i) (hmn : m < n) :
    TransGen r n m :=
  (refl_trans_gen_iff_eq_or_trans_gen.mp <| refl_trans_gen_of_succ_of_ge r h hmn.le).resolve_left hmn.Ne

end PartialSucc

section LinearSucc

variable {α : Type _} [LinearOrderₓ α] [SuccOrder α] [IsSuccArchimedean α]

/-- `(n, m)` is in the reflexive-transitive closure of `~` if `i ~ succ i` and `succ i ~ i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_succ (r : α → α → Prop) {n m : α} (h1 : ∀ i ∈ Ico n m, r i (succ i))
    (h2 : ∀ i ∈ Ico m n, r (succ i) i) : ReflTransGen r n m :=
  (le_totalₓ n m).elim (refl_trans_gen_of_succ_of_le r h1) <| refl_trans_gen_of_succ_of_ge r h2

/-- For `n ≠ m`,`(n, m)` is in the transitive closure of a relation `~` if `i ~ succ i` and
  `succ i ~ i` for all `i` between `n` and `m`. -/
theorem trans_gen_of_succ_of_ne (r : α → α → Prop) {n m : α} (h1 : ∀ i ∈ Ico n m, r i (succ i))
    (h2 : ∀ i ∈ Ico m n, r (succ i) i) (hnm : n ≠ m) : TransGen r n m :=
  (refl_trans_gen_iff_eq_or_trans_gen.mp (refl_trans_gen_of_succ r h1 h2)).resolve_left hnm.symm

/-- `(n, m)` is in the transitive closure of a reflexive relation `~` if `i ~ succ i` and
  `succ i ~ i` for all `i` between `n` and `m`. -/
theorem trans_gen_of_succ_of_reflexive (r : α → α → Prop) {n m : α} (hr : Reflexive r)
    (h1 : ∀ i ∈ Ico n m, r i (succ i)) (h2 : ∀ i ∈ Ico m n, r (succ i) i) : TransGen r n m := by
  rcases eq_or_ne m n with (rfl | hmn)
  · exact trans_gen.single (hr m)
    
  exact trans_gen_of_succ_of_ne r h1 h2 hmn.symm

end LinearSucc

section PartialPred

variable {α : Type _} [PartialOrderₓ α] [PredOrder α] [IsPredArchimedean α]

/-- For `m ≤ n`, `(n, m)` is in the reflexive-transitive closure of `~` if `i ~ pred i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_pred_of_ge (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ioc m n, r i (pred i)) (hnm : m ≤ n) :
    ReflTransGen r n m :=
  @refl_trans_gen_of_succ_of_le αᵒᵈ _ _ _ r n m (fun x hx => h x ⟨hx.2, hx.1⟩) hnm

/-- For `n ≤ m`, `(n, m)` is in the reflexive-transitive closure of `~` if `pred i ~ i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_pred_of_le (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ioc n m, r (pred i) i) (hmn : n ≤ m) :
    ReflTransGen r n m :=
  @refl_trans_gen_of_succ_of_ge αᵒᵈ _ _ _ r n m (fun x hx => h x ⟨hx.2, hx.1⟩) hmn

/-- For `m < n`, `(n, m)` is in the transitive closure of a relation `~` for `n ≠ m` if `i ~ pred i`
  for all `i` between `n` and `m`. -/
theorem trans_gen_of_pred_of_gt (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ioc m n, r i (pred i)) (hnm : m < n) :
    TransGen r n m :=
  @trans_gen_of_succ_of_lt αᵒᵈ _ _ _ r _ _ (fun x hx => h x ⟨hx.2, hx.1⟩) hnm

/-- For `n < m`, `(n, m)` is in the transitive closure of a relation `~` for `n ≠ m` if `pred i ~ i`
  for all `i` between `n` and `m`. -/
theorem trans_gen_of_pred_of_lt (r : α → α → Prop) {n m : α} (h : ∀ i ∈ Ioc n m, r (pred i) i) (hmn : n < m) :
    TransGen r n m :=
  @trans_gen_of_succ_of_gt αᵒᵈ _ _ _ r _ _ (fun x hx => h x ⟨hx.2, hx.1⟩) hmn

end PartialPred

section LinearPred

variable {α : Type _} [LinearOrderₓ α] [PredOrder α] [IsPredArchimedean α]

/-- `(n, m)` is in the reflexive-transitive closure of `~` if `i ~ pred i` and `pred i ~ i`
  for all `i` between `n` and `m`. -/
theorem refl_trans_gen_of_pred (r : α → α → Prop) {n m : α} (h1 : ∀ i ∈ Ioc m n, r i (pred i))
    (h2 : ∀ i ∈ Ioc n m, r (pred i) i) : ReflTransGen r n m :=
  @refl_trans_gen_of_succ αᵒᵈ _ _ _ r n m (fun x hx => h1 x ⟨hx.2, hx.1⟩) fun x hx => h2 x ⟨hx.2, hx.1⟩

/-- For `n ≠ m`, `(n, m)` is in the transitive closure of a relation `~` if `i ~ pred i` and
  `pred i ~ i` for all `i` between `n` and `m`. -/
theorem trans_gen_of_pred_of_ne (r : α → α → Prop) {n m : α} (h1 : ∀ i ∈ Ioc m n, r i (pred i))
    (h2 : ∀ i ∈ Ioc n m, r (pred i) i) (hnm : n ≠ m) : TransGen r n m :=
  @trans_gen_of_succ_of_ne αᵒᵈ _ _ _ r n m (fun x hx => h1 x ⟨hx.2, hx.1⟩) (fun x hx => h2 x ⟨hx.2, hx.1⟩) hnm

/-- `(n, m)` is in the transitive closure of a reflexive relation `~` if `i ~ pred i` and
  `pred i ~ i` for all `i` between `n` and `m`. -/
theorem trans_gen_of_pred_of_reflexive (r : α → α → Prop) {n m : α} (hr : Reflexive r)
    (h1 : ∀ i ∈ Ioc m n, r i (pred i)) (h2 : ∀ i ∈ Ioc n m, r (pred i) i) : TransGen r n m :=
  @trans_gen_of_succ_of_reflexive αᵒᵈ _ _ _ r n m hr (fun x hx => h1 x ⟨hx.2, hx.1⟩) fun x hx => h2 x ⟨hx.2, hx.1⟩

end LinearPred

