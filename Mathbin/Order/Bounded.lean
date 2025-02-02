/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
import Mathbin.Order.MinMax
import Mathbin.Order.RelClasses
import Mathbin.Data.Set.Intervals.Basic

/-!
# Bounded and unbounded sets

We prove miscellaneous lemmas about bounded and unbounded sets. Many of these are just variations on
the same ideas, or similar results with a few minor differences. The file is divided into these
different general ideas.
-/


namespace Set

variable {α : Type _} {r : α → α → Prop} {s t : Set α}

/-! ### Subsets of bounded and unbounded sets -/


theorem Bounded.mono (hst : s ⊆ t) (hs : Bounded r t) : Bounded r s :=
  hs.imp fun a ha b hb => ha b (hst hb)

theorem Unbounded.mono (hst : s ⊆ t) (hs : Unbounded r s) : Unbounded r t := fun a =>
  let ⟨b, hb, hb'⟩ := hs a
  ⟨b, hst hb, hb'⟩

/-! ### Alternate characterizations of unboundedness on orders -/


theorem unbounded_le_of_forall_exists_lt [Preorderₓ α] (h : ∀ a, ∃ b ∈ s, a < b) : Unbounded (· ≤ ·) s := fun a =>
  let ⟨b, hb, hb'⟩ := h a
  ⟨b, hb, fun hba => hba.not_lt hb'⟩

theorem unbounded_le_iff [LinearOrderₓ α] : Unbounded (· ≤ ·) s ↔ ∀ a, ∃ b ∈ s, a < b := by
  simp only [unbounded, not_leₓ]

theorem unbounded_lt_of_forall_exists_le [Preorderₓ α] (h : ∀ a, ∃ b ∈ s, a ≤ b) : Unbounded (· < ·) s := fun a =>
  let ⟨b, hb, hb'⟩ := h a
  ⟨b, hb, fun hba => hba.not_le hb'⟩

theorem unbounded_lt_iff [LinearOrderₓ α] : Unbounded (· < ·) s ↔ ∀ a, ∃ b ∈ s, a ≤ b := by
  simp only [unbounded, not_ltₓ]

theorem unbounded_ge_of_forall_exists_gt [Preorderₓ α] (h : ∀ a, ∃ b ∈ s, b < a) : Unbounded (· ≥ ·) s :=
  @unbounded_le_of_forall_exists_lt αᵒᵈ _ _ h

theorem unbounded_ge_iff [LinearOrderₓ α] : Unbounded (· ≥ ·) s ↔ ∀ a, ∃ b ∈ s, b < a :=
  ⟨fun h a =>
    let ⟨b, hb, hba⟩ := h a
    ⟨b, hb, lt_of_not_geₓ hba⟩,
    unbounded_ge_of_forall_exists_gt⟩

theorem unbounded_gt_of_forall_exists_ge [Preorderₓ α] (h : ∀ a, ∃ b ∈ s, b ≤ a) : Unbounded (· > ·) s := fun a =>
  let ⟨b, hb, hb'⟩ := h a
  ⟨b, hb, fun hba => not_le_of_gtₓ hba hb'⟩

theorem unbounded_gt_iff [LinearOrderₓ α] : Unbounded (· > ·) s ↔ ∀ a, ∃ b ∈ s, b ≤ a :=
  ⟨fun h a =>
    let ⟨b, hb, hba⟩ := h a
    ⟨b, hb, le_of_not_gtₓ hba⟩,
    unbounded_gt_of_forall_exists_ge⟩

/-! ### Relation between boundedness by strict and nonstrict orders. -/


/-! #### Less and less or equal -/


theorem Bounded.rel_mono {r' : α → α → Prop} (h : Bounded r s) (hrr' : r ≤ r') : Bounded r' s :=
  let ⟨a, ha⟩ := h
  ⟨a, fun b hb => hrr' b a (ha b hb)⟩

theorem bounded_le_of_bounded_lt [Preorderₓ α] (h : Bounded (· < ·) s) : Bounded (· ≤ ·) s :=
  h.rel_mono fun _ _ => le_of_ltₓ

theorem Unbounded.rel_mono {r' : α → α → Prop} (hr : r' ≤ r) (h : Unbounded r s) : Unbounded r' s := fun a =>
  let ⟨b, hb, hba⟩ := h a
  ⟨b, hb, fun hba' => hba (hr b a hba')⟩

theorem unbounded_lt_of_unbounded_le [Preorderₓ α] (h : Unbounded (· ≤ ·) s) : Unbounded (· < ·) s :=
  h.rel_mono fun _ _ => le_of_ltₓ

theorem bounded_le_iff_bounded_lt [Preorderₓ α] [NoMaxOrder α] : Bounded (· ≤ ·) s ↔ Bounded (· < ·) s := by
  refine' ⟨fun h => _, bounded_le_of_bounded_lt⟩
  cases' h with a ha
  cases' exists_gt a with b hb
  exact ⟨b, fun c hc => lt_of_le_of_ltₓ (ha c hc) hb⟩

theorem unbounded_lt_iff_unbounded_le [Preorderₓ α] [NoMaxOrder α] : Unbounded (· < ·) s ↔ Unbounded (· ≤ ·) s := by
  simp_rw [← not_bounded_iff, bounded_le_iff_bounded_lt]

/-! #### Greater and greater or equal -/


theorem bounded_ge_of_bounded_gt [Preorderₓ α] (h : Bounded (· > ·) s) : Bounded (· ≥ ·) s :=
  let ⟨a, ha⟩ := h
  ⟨a, fun b hb => le_of_ltₓ (ha b hb)⟩

theorem unbounded_gt_of_unbounded_ge [Preorderₓ α] (h : Unbounded (· ≥ ·) s) : Unbounded (· > ·) s := fun a =>
  let ⟨b, hb, hba⟩ := h a
  ⟨b, hb, fun hba' => hba (le_of_ltₓ hba')⟩

theorem bounded_ge_iff_bounded_gt [Preorderₓ α] [NoMinOrder α] : Bounded (· ≥ ·) s ↔ Bounded (· > ·) s :=
  @bounded_le_iff_bounded_lt αᵒᵈ _ _ _

theorem unbounded_gt_iff_unbounded_ge [Preorderₓ α] [NoMinOrder α] : Unbounded (· > ·) s ↔ Unbounded (· ≥ ·) s :=
  @unbounded_lt_iff_unbounded_le αᵒᵈ _ _ _

/-! ### The universal set -/


theorem unbounded_le_univ [LE α] [NoTopOrder α] : Unbounded (· ≤ ·) (@Set.Univ α) := fun a =>
  let ⟨b, hb⟩ := exists_not_le a
  ⟨b, ⟨⟩, hb⟩

theorem unbounded_lt_univ [Preorderₓ α] [NoTopOrder α] : Unbounded (· < ·) (@Set.Univ α) :=
  unbounded_lt_of_unbounded_le unbounded_le_univ

theorem unbounded_ge_univ [LE α] [NoBotOrder α] : Unbounded (· ≥ ·) (@Set.Univ α) := fun a =>
  let ⟨b, hb⟩ := exists_not_ge a
  ⟨b, ⟨⟩, hb⟩

theorem unbounded_gt_univ [Preorderₓ α] [NoBotOrder α] : Unbounded (· > ·) (@Set.Univ α) :=
  unbounded_gt_of_unbounded_ge unbounded_ge_univ

/-! ### Bounded and unbounded intervals -/


theorem bounded_self (a : α) : Bounded r { b | r b a } :=
  ⟨a, fun x => id⟩

/-! #### Half-open bounded intervals -/


theorem bounded_lt_Iio [Preorderₓ α] (a : α) : Bounded (· < ·) (Set.Iio a) :=
  bounded_self a

theorem bounded_le_Iio [Preorderₓ α] (a : α) : Bounded (· ≤ ·) (Set.Iio a) :=
  bounded_le_of_bounded_lt (bounded_lt_Iio a)

theorem bounded_le_Iic [Preorderₓ α] (a : α) : Bounded (· ≤ ·) (Set.Iic a) :=
  bounded_self a

theorem bounded_lt_Iic [Preorderₓ α] [NoMaxOrder α] (a : α) : Bounded (· < ·) (Set.Iic a) := by
  simp only [← bounded_le_iff_bounded_lt, bounded_le_Iic]

theorem bounded_gt_Ioi [Preorderₓ α] (a : α) : Bounded (· > ·) (Set.Ioi a) :=
  bounded_self a

theorem bounded_ge_Ioi [Preorderₓ α] (a : α) : Bounded (· ≥ ·) (Set.Ioi a) :=
  bounded_ge_of_bounded_gt (bounded_gt_Ioi a)

theorem bounded_ge_Ici [Preorderₓ α] (a : α) : Bounded (· ≥ ·) (Set.Ici a) :=
  bounded_self a

theorem bounded_gt_Ici [Preorderₓ α] [NoMinOrder α] (a : α) : Bounded (· > ·) (Set.Ici a) := by
  simp only [← bounded_ge_iff_bounded_gt, bounded_ge_Ici]

/-! #### Other bounded intervals -/


theorem bounded_lt_Ioo [Preorderₓ α] (a b : α) : Bounded (· < ·) (Set.Ioo a b) :=
  (bounded_lt_Iio b).mono Set.Ioo_subset_Iio_self

theorem bounded_lt_Ico [Preorderₓ α] (a b : α) : Bounded (· < ·) (Set.Ico a b) :=
  (bounded_lt_Iio b).mono Set.Ico_subset_Iio_self

theorem bounded_lt_Ioc [Preorderₓ α] [NoMaxOrder α] (a b : α) : Bounded (· < ·) (Set.Ioc a b) :=
  (bounded_lt_Iic b).mono Set.Ioc_subset_Iic_self

theorem bounded_lt_Icc [Preorderₓ α] [NoMaxOrder α] (a b : α) : Bounded (· < ·) (Set.Icc a b) :=
  (bounded_lt_Iic b).mono Set.Icc_subset_Iic_self

theorem bounded_le_Ioo [Preorderₓ α] (a b : α) : Bounded (· ≤ ·) (Set.Ioo a b) :=
  (bounded_le_Iio b).mono Set.Ioo_subset_Iio_self

theorem bounded_le_Ico [Preorderₓ α] (a b : α) : Bounded (· ≤ ·) (Set.Ico a b) :=
  (bounded_le_Iio b).mono Set.Ico_subset_Iio_self

theorem bounded_le_Ioc [Preorderₓ α] (a b : α) : Bounded (· ≤ ·) (Set.Ioc a b) :=
  (bounded_le_Iic b).mono Set.Ioc_subset_Iic_self

theorem bounded_le_Icc [Preorderₓ α] (a b : α) : Bounded (· ≤ ·) (Set.Icc a b) :=
  (bounded_le_Iic b).mono Set.Icc_subset_Iic_self

theorem bounded_gt_Ioo [Preorderₓ α] (a b : α) : Bounded (· > ·) (Set.Ioo a b) :=
  (bounded_gt_Ioi a).mono Set.Ioo_subset_Ioi_self

theorem bounded_gt_Ioc [Preorderₓ α] (a b : α) : Bounded (· > ·) (Set.Ioc a b) :=
  (bounded_gt_Ioi a).mono Set.Ioc_subset_Ioi_self

theorem bounded_gt_Ico [Preorderₓ α] [NoMinOrder α] (a b : α) : Bounded (· > ·) (Set.Ico a b) :=
  (bounded_gt_Ici a).mono Set.Ico_subset_Ici_self

theorem bounded_gt_Icc [Preorderₓ α] [NoMinOrder α] (a b : α) : Bounded (· > ·) (Set.Icc a b) :=
  (bounded_gt_Ici a).mono Set.Icc_subset_Ici_self

theorem bounded_ge_Ioo [Preorderₓ α] (a b : α) : Bounded (· ≥ ·) (Set.Ioo a b) :=
  (bounded_ge_Ioi a).mono Set.Ioo_subset_Ioi_self

theorem bounded_ge_Ioc [Preorderₓ α] (a b : α) : Bounded (· ≥ ·) (Set.Ioc a b) :=
  (bounded_ge_Ioi a).mono Set.Ioc_subset_Ioi_self

theorem bounded_ge_Ico [Preorderₓ α] (a b : α) : Bounded (· ≥ ·) (Set.Ico a b) :=
  (bounded_ge_Ici a).mono Set.Ico_subset_Ici_self

theorem bounded_ge_Icc [Preorderₓ α] (a b : α) : Bounded (· ≥ ·) (Set.Icc a b) :=
  (bounded_ge_Ici a).mono Set.Icc_subset_Ici_self

/-! #### Unbounded intervals -/


theorem unbounded_le_Ioi [SemilatticeSup α] [NoMaxOrder α] (a : α) : Unbounded (· ≤ ·) (Set.Ioi a) := fun b =>
  let ⟨c, hc⟩ := exists_gt (a⊔b)
  ⟨c, le_sup_left.trans_lt hc, (le_sup_right.trans_lt hc).not_le⟩

theorem unbounded_le_Ici [SemilatticeSup α] [NoMaxOrder α] (a : α) : Unbounded (· ≤ ·) (Set.Ici a) :=
  (unbounded_le_Ioi a).mono Set.Ioi_subset_Ici_self

theorem unbounded_lt_Ioi [SemilatticeSup α] [NoMaxOrder α] (a : α) : Unbounded (· < ·) (Set.Ioi a) :=
  unbounded_lt_of_unbounded_le (unbounded_le_Ioi a)

theorem unbounded_lt_Ici [SemilatticeSup α] (a : α) : Unbounded (· < ·) (Set.Ici a) := fun b =>
  ⟨a⊔b, le_sup_left, le_sup_right.not_lt⟩

/-! ### Bounded initial segments -/


theorem bounded_inter_not (H : ∀ a b, ∃ m, ∀ c, r c a ∨ r c b → r c m) (a : α) :
    Bounded r (s ∩ { b | ¬r b a }) ↔ Bounded r s := by
  refine' ⟨_, bounded.mono (Set.inter_subset_left s _)⟩
  rintro ⟨b, hb⟩
  cases' H a b with m hm
  exact ⟨m, fun c hc => hm c (or_iff_not_imp_left.2 fun hca => hb c ⟨hc, hca⟩)⟩

theorem unbounded_inter_not (H : ∀ a b, ∃ m, ∀ c, r c a ∨ r c b → r c m) (a : α) :
    Unbounded r (s ∩ { b | ¬r b a }) ↔ Unbounded r s := by
  simp_rw [← not_bounded_iff, bounded_inter_not H]

/-! #### Less or equal -/


theorem bounded_le_inter_not_le [SemilatticeSup α] (a : α) : Bounded (· ≤ ·) (s ∩ { b | ¬b ≤ a }) ↔ Bounded (· ≤ ·) s :=
  bounded_inter_not (fun x y => ⟨x⊔y, fun z h => h.elim le_sup_of_le_left le_sup_of_le_right⟩) a

theorem unbounded_le_inter_not_le [SemilatticeSup α] (a : α) :
    Unbounded (· ≤ ·) (s ∩ { b | ¬b ≤ a }) ↔ Unbounded (· ≤ ·) s := by
  rw [← not_bounded_iff, ← not_bounded_iff, not_iff_not]
  exact bounded_le_inter_not_le a

theorem bounded_le_inter_lt [LinearOrderₓ α] (a : α) : Bounded (· ≤ ·) (s ∩ { b | a < b }) ↔ Bounded (· ≤ ·) s := by
  simp_rw [← not_leₓ, bounded_le_inter_not_le]

theorem unbounded_le_inter_lt [LinearOrderₓ α] (a : α) : Unbounded (· ≤ ·) (s ∩ { b | a < b }) ↔ Unbounded (· ≤ ·) s :=
  by
  convert unbounded_le_inter_not_le a
  ext
  exact lt_iff_not_le

theorem bounded_le_inter_le [LinearOrderₓ α] (a : α) : Bounded (· ≤ ·) (s ∩ { b | a ≤ b }) ↔ Bounded (· ≤ ·) s := by
  refine' ⟨_, bounded.mono (Set.inter_subset_left s _)⟩
  rw [← @bounded_le_inter_lt _ s _ a]
  exact bounded.mono fun x ⟨hx, hx'⟩ => ⟨hx, le_of_ltₓ hx'⟩

theorem unbounded_le_inter_le [LinearOrderₓ α] (a : α) : Unbounded (· ≤ ·) (s ∩ { b | a ≤ b }) ↔ Unbounded (· ≤ ·) s :=
  by
  rw [← not_bounded_iff, ← not_bounded_iff, not_iff_not]
  exact bounded_le_inter_le a

/-! #### Less than -/


theorem bounded_lt_inter_not_lt [SemilatticeSup α] (a : α) : Bounded (· < ·) (s ∩ { b | ¬b < a }) ↔ Bounded (· < ·) s :=
  bounded_inter_not (fun x y => ⟨x⊔y, fun z h => h.elim lt_sup_of_lt_left lt_sup_of_lt_right⟩) a

theorem unbounded_lt_inter_not_lt [SemilatticeSup α] (a : α) :
    Unbounded (· < ·) (s ∩ { b | ¬b < a }) ↔ Unbounded (· < ·) s := by
  rw [← not_bounded_iff, ← not_bounded_iff, not_iff_not]
  exact bounded_lt_inter_not_lt a

theorem bounded_lt_inter_le [LinearOrderₓ α] (a : α) : Bounded (· < ·) (s ∩ { b | a ≤ b }) ↔ Bounded (· < ·) s := by
  convert bounded_lt_inter_not_lt a
  ext
  exact not_lt.symm

theorem unbounded_lt_inter_le [LinearOrderₓ α] (a : α) : Unbounded (· < ·) (s ∩ { b | a ≤ b }) ↔ Unbounded (· < ·) s :=
  by
  convert unbounded_lt_inter_not_lt a
  ext
  exact not_lt.symm

theorem bounded_lt_inter_lt [LinearOrderₓ α] [NoMaxOrder α] (a : α) :
    Bounded (· < ·) (s ∩ { b | a < b }) ↔ Bounded (· < ·) s := by
  rw [← bounded_le_iff_bounded_lt, ← bounded_le_iff_bounded_lt]
  exact bounded_le_inter_lt a

theorem unbounded_lt_inter_lt [LinearOrderₓ α] [NoMaxOrder α] (a : α) :
    Unbounded (· < ·) (s ∩ { b | a < b }) ↔ Unbounded (· < ·) s := by
  rw [← not_bounded_iff, ← not_bounded_iff, not_iff_not]
  exact bounded_lt_inter_lt a

/-! #### Greater or equal -/


theorem bounded_ge_inter_not_ge [SemilatticeInf α] (a : α) : Bounded (· ≥ ·) (s ∩ { b | ¬a ≤ b }) ↔ Bounded (· ≥ ·) s :=
  @bounded_le_inter_not_le αᵒᵈ s _ a

theorem unbounded_ge_inter_not_ge [SemilatticeInf α] (a : α) :
    Unbounded (· ≥ ·) (s ∩ { b | ¬a ≤ b }) ↔ Unbounded (· ≥ ·) s :=
  @unbounded_le_inter_not_le αᵒᵈ s _ a

theorem bounded_ge_inter_gt [LinearOrderₓ α] (a : α) : Bounded (· ≥ ·) (s ∩ { b | b < a }) ↔ Bounded (· ≥ ·) s :=
  @bounded_le_inter_lt αᵒᵈ s _ a

theorem unbounded_ge_inter_gt [LinearOrderₓ α] (a : α) : Unbounded (· ≥ ·) (s ∩ { b | b < a }) ↔ Unbounded (· ≥ ·) s :=
  @unbounded_le_inter_lt αᵒᵈ s _ a

theorem bounded_ge_inter_ge [LinearOrderₓ α] (a : α) : Bounded (· ≥ ·) (s ∩ { b | b ≤ a }) ↔ Bounded (· ≥ ·) s :=
  @bounded_le_inter_le αᵒᵈ s _ a

theorem unbounded_ge_iff_unbounded_inter_ge [LinearOrderₓ α] (a : α) :
    Unbounded (· ≥ ·) (s ∩ { b | b ≤ a }) ↔ Unbounded (· ≥ ·) s :=
  @unbounded_le_inter_le αᵒᵈ s _ a

/-! #### Greater than -/


theorem bounded_gt_inter_not_gt [SemilatticeInf α] (a : α) : Bounded (· > ·) (s ∩ { b | ¬a < b }) ↔ Bounded (· > ·) s :=
  @bounded_lt_inter_not_lt αᵒᵈ s _ a

theorem unbounded_gt_inter_not_gt [SemilatticeInf α] (a : α) :
    Unbounded (· > ·) (s ∩ { b | ¬a < b }) ↔ Unbounded (· > ·) s :=
  @unbounded_lt_inter_not_lt αᵒᵈ s _ a

theorem bounded_gt_inter_ge [LinearOrderₓ α] (a : α) : Bounded (· > ·) (s ∩ { b | b ≤ a }) ↔ Bounded (· > ·) s :=
  @bounded_lt_inter_le αᵒᵈ s _ a

theorem unbounded_inter_ge [LinearOrderₓ α] (a : α) : Unbounded (· > ·) (s ∩ { b | b ≤ a }) ↔ Unbounded (· > ·) s :=
  @unbounded_lt_inter_le αᵒᵈ s _ a

theorem bounded_gt_inter_gt [LinearOrderₓ α] [NoMinOrder α] (a : α) :
    Bounded (· > ·) (s ∩ { b | b < a }) ↔ Bounded (· > ·) s :=
  @bounded_lt_inter_lt αᵒᵈ s _ _ a

theorem unbounded_gt_inter_gt [LinearOrderₓ α] [NoMinOrder α] (a : α) :
    Unbounded (· > ·) (s ∩ { b | b < a }) ↔ Unbounded (· > ·) s :=
  @unbounded_lt_inter_lt αᵒᵈ s _ _ a

end Set

