/-
Copyright (c) 2019 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Yury Kudryashov
-/
import Mathbin.Algebra.Order.Archimedean
import Mathbin.Order.Filter.AtTopBot

/-!
# `at_top` filter and archimedean (semi)rings/fields

In this file we prove that for a linear ordered archimedean semiring `R` and a function `f : α → ℕ`,
the function `coe ∘ f : α → R` tends to `at_top` along a filter `l` if and only if so does `f`.
We also prove that `coe : ℕ → R` tends to `at_top` along `at_top`, as well as version of these
two results for `ℤ` (and a ring `R`) and `ℚ` (and a field `R`).
-/


variable {α R : Type _}

open Filter Set

@[simp]
theorem Nat.comap_coe_at_top [OrderedSemiring R] [Nontrivial R] [Archimedean R] : comap (coe : ℕ → R) atTop = at_top :=
  comap_embedding_at_top (fun _ _ => Nat.cast_le) exists_nat_ge

theorem tendsto_coe_nat_at_top_iff [OrderedSemiring R] [Nontrivial R] [Archimedean R] {f : α → ℕ} {l : Filter α} :
    Tendsto (fun n => (f n : R)) l atTop ↔ Tendsto f l atTop :=
  tendsto_at_top_embedding (fun a₁ a₂ => Nat.cast_le) exists_nat_ge

theorem tendsto_coe_nat_at_top_at_top [OrderedSemiring R] [Archimedean R] : Tendsto (coe : ℕ → R) atTop atTop :=
  Nat.mono_cast.tendsto_at_top_at_top exists_nat_ge

@[simp]
theorem Int.comap_coe_at_top [OrderedRing R] [Nontrivial R] [Archimedean R] : comap (coe : ℤ → R) atTop = at_top :=
  (comap_embedding_at_top fun _ _ => Int.cast_le) fun r =>
    let ⟨n, hn⟩ := exists_nat_ge r
    ⟨n, by
      exact_mod_cast hn⟩

@[simp]
theorem Int.comap_coe_at_bot [OrderedRing R] [Nontrivial R] [Archimedean R] : comap (coe : ℤ → R) atBot = at_bot :=
  (comap_embedding_at_bot fun _ _ => Int.cast_le) fun r =>
    let ⟨n, hn⟩ := exists_nat_ge (-r)
    ⟨-n, by
      simpa [neg_le] using hn⟩

theorem tendsto_coe_int_at_top_iff [OrderedRing R] [Nontrivial R] [Archimedean R] {f : α → ℤ} {l : Filter α} :
    Tendsto (fun n => (f n : R)) l atTop ↔ Tendsto f l atTop := by
  rw [← tendsto_comap_iff, Int.comap_coe_at_top]

theorem tendsto_coe_int_at_bot_iff [OrderedRing R] [Nontrivial R] [Archimedean R] {f : α → ℤ} {l : Filter α} :
    Tendsto (fun n => (f n : R)) l atBot ↔ Tendsto f l atBot := by
  rw [← tendsto_comap_iff, Int.comap_coe_at_bot]

theorem tendsto_coe_int_at_top_at_top [OrderedRing R] [Archimedean R] : Tendsto (coe : ℤ → R) atTop atTop :=
  Int.cast_mono.tendsto_at_top_at_top fun b =>
    let ⟨n, hn⟩ := exists_nat_ge b
    ⟨n, by
      exact_mod_cast hn⟩

@[simp]
theorem Rat.comap_coe_at_top [LinearOrderedField R] [Archimedean R] : comap (coe : ℚ → R) atTop = at_top :=
  (comap_embedding_at_top fun _ _ => Rat.cast_le) fun r =>
    let ⟨n, hn⟩ := exists_nat_ge r
    ⟨n, by
      simpa⟩

@[simp]
theorem Rat.comap_coe_at_bot [LinearOrderedField R] [Archimedean R] : comap (coe : ℚ → R) atBot = at_bot :=
  (comap_embedding_at_bot fun _ _ => Rat.cast_le) fun r =>
    let ⟨n, hn⟩ := exists_nat_ge (-r)
    ⟨-n, by
      simpa [neg_le] ⟩

theorem tendsto_coe_rat_at_top_iff [LinearOrderedField R] [Archimedean R] {f : α → ℚ} {l : Filter α} :
    Tendsto (fun n => (f n : R)) l atTop ↔ Tendsto f l atTop := by
  rw [← tendsto_comap_iff, Rat.comap_coe_at_top]

theorem tendsto_coe_rat_at_bot_iff [LinearOrderedField R] [Archimedean R] {f : α → ℚ} {l : Filter α} :
    Tendsto (fun n => (f n : R)) l atBot ↔ Tendsto f l atBot := by
  rw [← tendsto_comap_iff, Rat.comap_coe_at_bot]

theorem at_top_countable_basis_of_archimedean [LinearOrderedSemiring R] [Archimedean R] :
    (atTop : Filter R).HasCountableBasis (fun n : ℕ => True) fun n => Ici n :=
  { Countable := to_countable _,
    to_has_basis :=
      at_top_basis.to_has_basis
        (fun x hx =>
          let ⟨n, hn⟩ := exists_nat_ge x
          ⟨n, trivialₓ, Ici_subset_Ici.2 hn⟩)
        fun n hn => ⟨n, trivialₓ, Subset.rfl⟩ }

theorem at_bot_countable_basis_of_archimedean [LinearOrderedRing R] [Archimedean R] :
    (atBot : Filter R).HasCountableBasis (fun m : ℤ => True) fun m => Iic m :=
  { Countable := to_countable _,
    to_has_basis :=
      at_bot_basis.to_has_basis
        (fun x hx =>
          let ⟨m, hm⟩ := exists_int_lt x
          ⟨m, trivialₓ, Iic_subset_Iic.2 hm.le⟩)
        fun m hm => ⟨m, trivialₓ, Subset.rfl⟩ }

instance (priority := 100) at_top_countably_generated_of_archimedean [LinearOrderedSemiring R] [Archimedean R] :
    (atTop : Filter R).IsCountablyGenerated :=
  at_top_countable_basis_of_archimedean.IsCountablyGenerated

instance (priority := 100) at_bot_countably_generated_of_archimedean [LinearOrderedRing R] [Archimedean R] :
    (atBot : Filter R).IsCountablyGenerated :=
  at_bot_countable_basis_of_archimedean.IsCountablyGenerated

namespace Filter

variable {l : Filter α} {f : α → R} {r : R}

section LinearOrderedSemiring

variable [LinearOrderedSemiring R] [Archimedean R]

/-- If a function tends to infinity along a filter, then this function multiplied by a positive
constant (on the left) also tends to infinity. The archimedean assumption is convenient to get a
statement that works on `ℕ`, `ℤ` and `ℝ`, although not necessary (a version in ordered fields is
given in `filter.tendsto.const_mul_at_top`). -/
theorem Tendsto.const_mul_at_top' (hr : 0 < r) (hf : Tendsto f l atTop) : Tendsto (fun x => r * f x) l atTop := by
  apply tendsto_at_top.2 fun b => _
  obtain ⟨n : ℕ, hn : 1 ≤ n • r⟩ := Archimedean.arch 1 hr
  rw [nsmul_eq_mul'] at hn
  filter_upwards [tendsto_at_top.1 hf (n * max b 0)] with x hx
  calc
    b ≤ 1 * max b 0 := by
      rw [one_mulₓ]
      exact le_max_leftₓ _ _
    _ ≤ r * n * max b 0 := mul_le_mul_of_nonneg_right hn (le_max_rightₓ _ _)
    _ = r * (n * max b 0) := by
      rw [mul_assoc]
    _ ≤ r * f x := mul_le_mul_of_nonneg_left hx (le_of_ltₓ hr)
    

/-- If a function tends to infinity along a filter, then this function multiplied by a positive
constant (on the right) also tends to infinity. The archimedean assumption is convenient to get a
statement that works on `ℕ`, `ℤ` and `ℝ`, although not necessary (a version in ordered fields is
given in `filter.tendsto.at_top_mul_const`). -/
theorem Tendsto.at_top_mul_const' (hr : 0 < r) (hf : Tendsto f l atTop) : Tendsto (fun x => f x * r) l atTop := by
  apply tendsto_at_top.2 fun b => _
  obtain ⟨n : ℕ, hn : 1 ≤ n • r⟩ := Archimedean.arch 1 hr
  have hn' : 1 ≤ (n : R) * r := by
    rwa [nsmul_eq_mul] at hn
  filter_upwards [tendsto_at_top.1 hf (max b 0 * n)] with x hx
  calc
    b ≤ max b 0 * 1 := by
      rw [mul_oneₓ]
      exact le_max_leftₓ _ _
    _ ≤ max b 0 * (n * r) := mul_le_mul_of_nonneg_left hn' (le_max_rightₓ _ _)
    _ = max b 0 * n * r := by
      rw [mul_assoc]
    _ ≤ f x * r := mul_le_mul_of_nonneg_right hx (le_of_ltₓ hr)
    

end LinearOrderedSemiring

section LinearOrderedRing

variable [LinearOrderedRing R] [Archimedean R]

/-- See also `filter.tendsto.at_top_mul_neg_const` for a version of this lemma for
`linear_ordered_field`s which does not require the `archimedean` assumption. -/
theorem Tendsto.at_top_mul_neg_const' (hr : r < 0) (hf : Tendsto f l atTop) : Tendsto (fun x => f x * r) l atBot := by
  simpa only [tendsto_neg_at_top_iff, mul_neg] using hf.at_top_mul_const' (neg_pos.mpr hr)

/-- See also `filter.tendsto.at_bot_mul_const` for a version of this lemma for
`linear_ordered_field`s which does not require the `archimedean` assumption. -/
theorem Tendsto.at_bot_mul_const' (hr : 0 < r) (hf : Tendsto f l atBot) : Tendsto (fun x => f x * r) l atBot := by
  simp only [← tendsto_neg_at_top_iff, ← neg_mul] at hf⊢
  exact hf.at_top_mul_const' hr

/-- See also `filter.tendsto.at_bot_mul_neg_const` for a version of this lemma for
`linear_ordered_field`s which does not require the `archimedean` assumption. -/
theorem Tendsto.at_bot_mul_neg_const' (hr : r < 0) (hf : Tendsto f l atBot) : Tendsto (fun x => f x * r) l atTop := by
  simpa only [mul_neg, tendsto_neg_at_bot_iff] using hf.at_bot_mul_const' (neg_pos.2 hr)

end LinearOrderedRing

section LinearOrderedCancelAddCommMonoid

variable [LinearOrderedCancelAddCommMonoid R] [Archimedean R]

theorem Tendsto.at_top_nsmul_const {f : α → ℕ} (hr : 0 < r) (hf : Tendsto f l atTop) :
    Tendsto (fun x => f x • r) l atTop := by
  refine' tendsto_at_top.mpr fun s => _
  obtain ⟨n : ℕ, hn : s ≤ n • r⟩ := Archimedean.arch s hr
  exact (tendsto_at_top.mp hf n).mono fun a ha => hn.trans (nsmul_le_nsmul hr.le ha)

end LinearOrderedCancelAddCommMonoid

section LinearOrderedAddCommGroup

variable [LinearOrderedAddCommGroup R] [Archimedean R]

theorem Tendsto.at_top_nsmul_neg_const {f : α → ℕ} (hr : r < 0) (hf : Tendsto f l atTop) :
    Tendsto (fun x => f x • r) l atBot := by
  simpa using hf.at_top_nsmul_const (neg_pos.2 hr)

theorem Tendsto.at_top_zsmul_const {f : α → ℤ} (hr : 0 < r) (hf : Tendsto f l atTop) :
    Tendsto (fun x => f x • r) l atTop := by
  refine' tendsto_at_top.mpr fun s => _
  obtain ⟨n : ℕ, hn : s ≤ n • r⟩ := Archimedean.arch s hr
  replace hn : s ≤ (n : ℤ) • r
  · simpa
    
  exact (tendsto_at_top.mp hf n).mono fun a ha => hn.trans (zsmul_le_zsmul hr.le ha)

theorem Tendsto.at_top_zsmul_neg_const {f : α → ℤ} (hr : r < 0) (hf : Tendsto f l atTop) :
    Tendsto (fun x => f x • r) l atBot := by
  simpa using hf.at_top_zsmul_const (neg_pos.2 hr)

theorem Tendsto.at_bot_zsmul_const {f : α → ℤ} (hr : 0 < r) (hf : Tendsto f l atBot) :
    Tendsto (fun x => f x • r) l atBot := by
  simp only [← tendsto_neg_at_top_iff, ← neg_zsmul] at hf⊢
  exact hf.at_top_zsmul_const hr

theorem Tendsto.at_bot_zsmul_neg_const {f : α → ℤ} (hr : r < 0) (hf : Tendsto f l atBot) :
    Tendsto (fun x => f x • r) l atTop := by
  simpa using hf.at_bot_zsmul_const (neg_pos.2 hr)

end LinearOrderedAddCommGroup

end Filter

