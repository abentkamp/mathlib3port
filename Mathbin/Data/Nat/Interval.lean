import Mathbin.Data.Finset.LocallyFinite

/-!
# Finite intervals of naturals

This file proves that `ℕ` is a `locally_finite_order` and calculates the cardinality of its
intervals as finsets and fintypes.

## TODO

Some lemmas can be generalized using `ordered_group`, `canonically_ordered_monoid` or `succ_order`
and subsequently be moved upstream to `data.finset.locally_finite`.
-/


open Finset Nat

instance  : LocallyFiniteOrder ℕ :=
  { finsetIcc := fun a b => (List.range' a ((b+1) - a)).toFinset,
    finsetIco := fun a b => (List.range' a (b - a)).toFinset,
    finsetIoc := fun a b => (List.range' (a+1) (b - a)).toFinset,
    finsetIoo := fun a b => (List.range' (a+1) (b - a - 1)).toFinset,
    finset_mem_Icc :=
      fun a b x =>
        by 
          rw [List.mem_to_finset, List.mem_range']
          cases le_or_ltₓ a b
          ·
            rw [add_tsub_cancel_of_le (Nat.lt_succ_of_leₓ h).le, Nat.lt_succ_iff]
          ·
            rw [tsub_eq_zero_iff_le.2 (succ_le_of_lt h), add_zeroₓ]
            exact iff_of_false (fun hx => hx.2.not_le hx.1) fun hx => h.not_le (hx.1.trans hx.2),
    finset_mem_Ico :=
      fun a b x =>
        by 
          rw [List.mem_to_finset, List.mem_range']
          cases le_or_ltₓ a b
          ·
            rw [add_tsub_cancel_of_le h]
          ·
            rw [tsub_eq_zero_iff_le.2 h.le, add_zeroₓ]
            exact iff_of_false (fun hx => hx.2.not_le hx.1) fun hx => h.not_le (hx.1.trans hx.2.le),
    finset_mem_Ioc :=
      fun a b x =>
        by 
          rw [List.mem_to_finset, List.mem_range']
          cases le_or_ltₓ a b
          ·
            rw [←succ_sub_succ, add_tsub_cancel_of_le (succ_le_succ h), Nat.lt_succ_iff, Nat.succ_le_iff]
          ·
            rw [tsub_eq_zero_iff_le.2 h.le, add_zeroₓ]
            exact iff_of_false (fun hx => hx.2.not_le hx.1) fun hx => h.not_le (hx.1.le.trans hx.2),
    finset_mem_Ioo :=
      fun a b x =>
        by 
          rw [List.mem_to_finset, List.mem_range', ←tsub_add_eq_tsub_tsub]
          cases le_or_ltₓ (a+1) b
          ·
            rw [add_tsub_cancel_of_le h, Nat.succ_le_iff]
          ·
            rw [tsub_eq_zero_iff_le.2 h.le, add_zeroₓ]
            exact iff_of_false (fun hx => hx.2.not_le hx.1) fun hx => h.not_le (hx.1.trans hx.2) }

namespace Nat

variable(a b c : ℕ)

theorem Icc_eq_range' : Icc a b = (List.range' a ((b+1) - a)).toFinset :=
  rfl

theorem Ico_eq_range' : Ico a b = (List.range' a (b - a)).toFinset :=
  rfl

theorem Ioc_eq_range' : Ioc a b = (List.range' (a+1) (b - a)).toFinset :=
  rfl

theorem Ioo_eq_range' : Ioo a b = (List.range' (a+1) (b - a - 1)).toFinset :=
  rfl

theorem Iio_eq_range : Iio = range :=
  by 
    ext b x 
    rw [mem_Iio, mem_range]

@[simp]
theorem Ico_zero_eq_range : Ico 0 = range :=
  by 
    rw [←bot_eq_zero, ←Iio_eq_Ico, Iio_eq_range]

theorem _root_.finset.range_eq_Ico : range = Ico 0 :=
  Ico_zero_eq_range.symm

@[simp]
theorem card_Icc : (Icc a b).card = (b+1) - a :=
  by 
    rw [Icc_eq_range', List.card_to_finset, (List.nodup_range' _ _).eraseDup, List.length_range']

@[simp]
theorem card_Ico : (Ico a b).card = b - a :=
  by 
    rw [Ico_eq_range', List.card_to_finset, (List.nodup_range' _ _).eraseDup, List.length_range']

@[simp]
theorem card_Ioc : (Ioc a b).card = b - a :=
  by 
    rw [Ioc_eq_range', List.card_to_finset, (List.nodup_range' _ _).eraseDup, List.length_range']

@[simp]
theorem card_Ioo : (Ioo a b).card = b - a - 1 :=
  by 
    rw [Ioo_eq_range', List.card_to_finset, (List.nodup_range' _ _).eraseDup, List.length_range']

@[simp]
theorem card_Iic : (Iic b).card = b+1 :=
  by 
    rw [Iic, card_Icc, bot_eq_zero, tsub_zero]

@[simp]
theorem card_Iio : (Iio b).card = b :=
  by 
    rw [Iio, card_Ico, bot_eq_zero, tsub_zero]

@[simp]
theorem card_fintype_Icc : Fintype.card (Set.Icc a b) = (b+1) - a :=
  by 
    rw [Fintype.card_of_finset, card_Icc]

@[simp]
theorem card_fintype_Ico : Fintype.card (Set.Ico a b) = b - a :=
  by 
    rw [Fintype.card_of_finset, card_Ico]

@[simp]
theorem card_fintype_Ioc : Fintype.card (Set.Ioc a b) = b - a :=
  by 
    rw [Fintype.card_of_finset, card_Ioc]

@[simp]
theorem card_fintype_Ioo : Fintype.card (Set.Ioo a b) = b - a - 1 :=
  by 
    rw [Fintype.card_of_finset, card_Ioo]

@[simp]
theorem card_fintype_Iic : Fintype.card (Set.Iic b) = b+1 :=
  by 
    rw [Fintype.card_of_finset, card_Iic]

@[simp]
theorem card_fintype_Iio : Fintype.card (Set.Iio b) = b :=
  by 
    rw [Fintype.card_of_finset, card_Iio]

theorem Icc_succ_left : Icc a.succ b = Ioc a b :=
  by 
    ext x 
    rw [mem_Icc, mem_Ioc, succ_le_iff]

theorem Ico_succ_right : Ico a b.succ = Icc a b :=
  by 
    ext x 
    rw [mem_Ico, mem_Icc, lt_succ_iff]

theorem Ico_succ_left : Ico a.succ b = Ioo a b :=
  by 
    ext x 
    rw [mem_Ico, mem_Ioo, succ_le_iff]

theorem Icc_pred_right {b : ℕ} (h : 0 < b) : Icc a (b - 1) = Ico a b :=
  by 
    ext x 
    rw [mem_Icc, mem_Ico, lt_iff_le_pred h]

theorem Ico_succ_succ : Ico a.succ b.succ = Ioc a b :=
  by 
    ext x 
    rw [mem_Ico, mem_Ioc, succ_le_iff, lt_succ_iff]

@[simp]
theorem Ico_succ_singleton : Ico a (a+1) = {a} :=
  by 
    rw [Ico_succ_right, Icc_self]

@[simp]
theorem Ico_pred_singleton {a : ℕ} (h : 0 < a) : Ico (a - 1) a = {a - 1} :=
  by 
    rw [←Icc_pred_right _ h, Icc_self]

variable{a b c}

theorem Ico_succ_right_eq_insert_Ico (h : a ≤ b) : Ico a (b+1) = insert b (Ico a b) :=
  by 
    rw [Ico_succ_right, ←Ico_insert_right h]

theorem Ico_insert_succ_left (h : a < b) : insert a (Ico a.succ b) = Ico a b :=
  by 
    rw [Ico_succ_left, ←Ioo_insert_left h]

theorem image_sub_const_Ico (h : c ≤ a) : ((Ico a b).Image fun x => x - c) = Ico (a - c) (b - c) :=
  by 
    ext x 
    rw [mem_image]
    split 
    ·
      rintro ⟨x, hx, rfl⟩
      rw [mem_Ico] at hx⊢
      exact ⟨tsub_le_tsub_right hx.1 _, tsub_lt_tsub_right_of_le (h.trans hx.1) hx.2⟩
    ·
      rintro h 
      refine' ⟨x+c, _, add_tsub_cancel_right _ _⟩
      rw [mem_Ico] at h⊢
      exact ⟨tsub_le_iff_right.1 h.1, lt_tsub_iff_right.1 h.2⟩

-- error in Data.Nat.Interval: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem Ico_image_const_sub_eq_Ico
(hac : «expr ≤ »(a, c)) : «expr = »((Ico a b).image (λ
  x, «expr - »(c, x)), Ico «expr - »(«expr + »(c, 1), b) «expr - »(«expr + »(c, 1), a)) :=
begin
  ext [] [ident x] [],
  rw ["[", expr mem_image, ",", expr mem_Ico, "]"] [],
  split,
  { rintro ["⟨", ident x, ",", ident hx, ",", ident rfl, "⟩"],
    rw [expr mem_Ico] ["at", ident hx],
    refine [expr ⟨_, ((tsub_le_tsub_iff_left hac).2 hx.1).trans_lt ((tsub_lt_tsub_iff_right hac).2 (nat.lt_succ_self _))⟩],
    cases [expr lt_or_le c b] [],
    { rw [expr tsub_eq_zero_iff_le.mpr (succ_le_of_lt h)] [],
      exact [expr zero_le _] },
    { rw ["<-", expr succ_sub_succ c] [],
      exact [expr (tsub_le_tsub_iff_left «expr $ »(succ_le_succ, hx.2.le.trans h)).2 hx.2] } },
  { rintro ["⟨", ident hb, ",", ident ha, "⟩"],
    rw ["[", expr lt_tsub_iff_left, ",", expr lt_succ_iff, "]"] ["at", ident ha],
    have [ident hx] [":", expr «expr ≤ »(x, c)] [":=", expr (nat.le_add_left _ _).trans ha],
    refine [expr ⟨«expr - »(c, x), _, tsub_tsub_cancel_of_le hx⟩],
    { rw [expr mem_Ico] [],
      exact [expr ⟨le_tsub_of_add_le_right ha, «expr $ »((tsub_lt_iff_left hx).2, «expr $ »(succ_le_iff.1, tsub_le_iff_right.1 hb))⟩] } }
end

theorem Ico_succ_left_eq_erase_Ico : Ico a.succ b = erase (Ico a b) a :=
  by 
    ext x 
    rw [Ico_succ_left, mem_erase, mem_Ico, mem_Ioo, ←and_assoc, ne_comm, and_comm (a ≠ x), lt_iff_le_and_ne]

theorem range_image_pred_top_sub (n : ℕ) : ((Finset.range n).Image fun j => n - 1 - j) = Finset.range n :=
  by 
    cases n
    ·
      rw [range_zero, image_empty]
    ·
      rw [Finset.range_eq_Ico, Ico_image_const_sub_eq_Ico (zero_le _)]
      simpRw [succ_sub_succ, tsub_zero, tsub_self]

end Nat

