/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro
-/
import Mathbin.Algebra.FieldPower
import Mathbin.Data.Int.LeastGreatest
import Mathbin.Data.Rat.Floor

/-!
# Archimedean groups and fields.

This file defines the archimedean property for ordered groups and proves several results connected
to this notion. Being archimedean means that for all elements `x` and `y>0` there exists a natural
number `n` such that `x ≤ n • y`.

## Main definitions

* `archimedean` is a typeclass for an ordered additive commutative monoid to have the archimedean
  property.
* `archimedean.floor_ring` defines a floor function on an archimedean linearly ordered ring making
  it into a `floor_ring`.

## Main statements

* `ℕ`, `ℤ`, and `ℚ` are archimedean.
-/


open Int Set

variable {α : Type _}

/-- An ordered additive commutative monoid is called `archimedean` if for any two elements `x`, `y`
such that `0 < y` there exists a natural number `n` such that `x ≤ n • y`. -/
class Archimedean (α) [OrderedAddCommMonoid α] : Prop where
  arch : ∀ (x : α) {y}, 0 < y → ∃ n : ℕ, x ≤ n • y

instance OrderDual.archimedean [OrderedAddCommGroup α] [Archimedean α] : Archimedean αᵒᵈ :=
  ⟨fun x y hy =>
    let ⟨n, hn⟩ := Archimedean.arch (-x : α) (neg_pos.2 hy)
    ⟨n, by
      rwa [neg_nsmul, neg_le_neg_iff] at hn⟩⟩

section LinearOrderedAddCommGroup

variable [LinearOrderedAddCommGroup α] [Archimedean α]

/-- An archimedean decidable linearly ordered `add_comm_group` has a version of the floor: for
`a > 0`, any `g` in the group lies between some two consecutive multiples of `a`. -/
theorem exists_unique_zsmul_near_of_pos {a : α} (ha : 0 < a) (g : α) : ∃! k : ℤ, k • a ≤ g ∧ g < (k + 1) • a := by
  let s : Set ℤ := { n : ℤ | n • a ≤ g }
  obtain ⟨k, hk : -g ≤ k • a⟩ := Archimedean.arch (-g) ha
  have h_ne : s.nonempty :=
    ⟨-k, by
      simpa using neg_le_neg hk⟩
  obtain ⟨k, hk⟩ := Archimedean.arch g ha
  have h_bdd : ∀ n ∈ s, n ≤ (k : ℤ) := by
    intro n hn
    apply (zsmul_le_zsmul_iff ha).mp
    rw [← coe_nat_zsmul] at hk
    exact le_transₓ hn hk
  obtain ⟨m, hm, hm'⟩ := Int.exists_greatest_of_bdd ⟨k, h_bdd⟩ h_ne
  have hm'' : g < (m + 1) • a := by
    contrapose! hm'
    exact ⟨m + 1, hm', lt_add_one _⟩
  refine' ⟨m, ⟨hm, hm''⟩, fun n hn => (hm' n hn.1).antisymm <| Int.le_of_lt_add_oneₓ _⟩
  rw [← zsmul_lt_zsmul_iff ha]
  exact lt_of_le_of_ltₓ hm hn.2

theorem exists_unique_zsmul_near_of_pos' {a : α} (ha : 0 < a) (g : α) : ∃! k : ℤ, 0 ≤ g - k • a ∧ g - k • a < a := by
  simpa only [sub_nonneg, add_zsmul, one_zsmul, sub_lt_iff_lt_add'] using exists_unique_zsmul_near_of_pos ha g

theorem exists_unique_add_zsmul_mem_Ico {a : α} (ha : 0 < a) (b c : α) : ∃! m : ℤ, b + m • a ∈ Set.Ico c (c + a) :=
  (Equivₓ.neg ℤ).Bijective.exists_unique_iff.2 <| by
    simpa only [Equivₓ.neg_apply, mem_Ico, neg_zsmul, ← sub_eq_add_neg, le_sub_iff_add_le, zero_addₓ, add_commₓ c,
      sub_lt_iff_lt_add', add_assocₓ] using exists_unique_zsmul_near_of_pos' ha (b - c)

theorem exists_unique_add_zsmul_mem_Ioc {a : α} (ha : 0 < a) (b c : α) : ∃! m : ℤ, b + m • a ∈ Set.Ioc c (c + a) :=
  (Equivₓ.addRight (1 : ℤ)).Bijective.exists_unique_iff.2 <| by
    simpa only [add_zsmul, sub_lt_iff_lt_add', le_sub_iff_add_le', ← add_assocₓ, And.comm, mem_Ioc,
      Equivₓ.coe_add_right, one_zsmul, add_le_add_iff_right] using exists_unique_zsmul_near_of_pos ha (c - b)

end LinearOrderedAddCommGroup

theorem exists_nat_gt [OrderedSemiring α] [Nontrivial α] [Archimedean α] (x : α) : ∃ n : ℕ, x < n :=
  let ⟨n, h⟩ := Archimedean.arch x zero_lt_one
  ⟨n + 1,
    lt_of_le_of_ltₓ
      (by
        rwa [← nsmul_one])
      (Nat.cast_lt.2 (Nat.lt_succ_selfₓ _))⟩

theorem exists_nat_ge [OrderedSemiring α] [Archimedean α] (x : α) : ∃ n : ℕ, x ≤ n := by
  nontriviality α
  exact (exists_nat_gt x).imp fun n => le_of_ltₓ

theorem add_one_pow_unbounded_of_pos [OrderedSemiring α] [Nontrivial α] [Archimedean α] (x : α) {y : α} (hy : 0 < y) :
    ∃ n : ℕ, x < (y + 1) ^ n :=
  have : 0 ≤ 1 + y := add_nonneg zero_le_one hy.le
  let ⟨n, h⟩ := Archimedean.arch x hy
  ⟨n,
    calc
      x ≤ n • y := h
      _ = n * y := nsmul_eq_mul _ _
      _ < 1 + n * y := lt_one_add _
      _ ≤ (1 + y) ^ n :=
        one_add_mul_le_pow' (mul_nonneg hy.le hy.le) (mul_nonneg this this) (add_nonneg zero_le_two hy.le) _
      _ = (y + 1) ^ n := by
        rw [add_commₓ]
      ⟩

section OrderedRing

variable [OrderedRing α] [Nontrivial α] [Archimedean α]

theorem pow_unbounded_of_one_lt (x : α) {y : α} (hy1 : 1 < y) : ∃ n : ℕ, x < y ^ n :=
  sub_add_cancel y 1 ▸ add_one_pow_unbounded_of_pos _ (sub_pos.2 hy1)

theorem exists_int_gt (x : α) : ∃ n : ℤ, x < n :=
  let ⟨n, h⟩ := exists_nat_gt x
  ⟨n, by
    rwa [Int.cast_coe_nat]⟩

theorem exists_int_lt (x : α) : ∃ n : ℤ, (n : α) < x :=
  let ⟨n, h⟩ := exists_int_gt (-x)
  ⟨-n, by
    rw [Int.cast_neg] <;> exact neg_lt.1 h⟩

theorem exists_floor (x : α) : ∃ fl : ℤ, ∀ z : ℤ, z ≤ fl ↔ (z : α) ≤ x := by
  haveI := Classical.propDecidable
  have : ∃ ub : ℤ, (ub : α) ≤ x ∧ ∀ z : ℤ, (z : α) ≤ x → z ≤ ub :=
    Int.exists_greatest_of_bdd
      (let ⟨n, hn⟩ := exists_int_gt x
      ⟨n, fun z h' => Int.cast_le.1 <| le_transₓ h' <| le_of_ltₓ hn⟩)
      (let ⟨n, hn⟩ := exists_int_lt x
      ⟨n, le_of_ltₓ hn⟩)
  refine' this.imp fun fl h z => _
  cases' h with h₁ h₂
  exact ⟨fun h => le_transₓ (Int.cast_le.2 h) h₁, h₂ z⟩

end OrderedRing

section LinearOrderedRing

variable [LinearOrderedRing α] [Archimedean α]

/-- Every x greater than or equal to 1 is between two successive
natural-number powers of every y greater than one. -/
theorem exists_nat_pow_near {x : α} {y : α} (hx : 1 ≤ x) (hy : 1 < y) : ∃ n : ℕ, y ^ n ≤ x ∧ x < y ^ (n + 1) := by
  have h : ∃ n : ℕ, x < y ^ n := pow_unbounded_of_one_lt _ hy
  classical <;>
    exact
      let n := Nat.findₓ h
      have hn : x < y ^ n := Nat.find_specₓ h
      have hnp : 0 < n :=
        pos_iff_ne_zero.2 fun hn0 => by
          rw [hn0, pow_zeroₓ] at hn <;> exact not_le_of_gtₓ hn hx
      have hnsp : Nat.pred n + 1 = n := Nat.succ_pred_eq_of_posₓ hnp
      have hltn : Nat.pred n < n := Nat.pred_ltₓ (ne_of_gtₓ hnp)
      ⟨Nat.pred n, le_of_not_ltₓ (Nat.find_minₓ h hltn), by
        rwa [hnsp]⟩

end LinearOrderedRing

section LinearOrderedField

variable [LinearOrderedField α] [Archimedean α] {x y ε : α}

/-- Every positive `x` is between two successive integer powers of
another `y` greater than one. This is the same as `exists_mem_Ioc_zpow`,
but with ≤ and < the other way around. -/
theorem exists_mem_Ico_zpow (hx : 0 < x) (hy : 1 < y) : ∃ n : ℤ, x ∈ Ico (y ^ n) (y ^ (n + 1)) := by
  classical <;>
    exact
      let ⟨N, hN⟩ := pow_unbounded_of_one_lt x⁻¹ hy
      have he : ∃ m : ℤ, y ^ m ≤ x :=
        ⟨-N,
          le_of_ltₓ
            (by
              rw [zpow_neg y ↑N, zpow_coe_nat]
              exact (inv_lt hx (lt_transₓ (inv_pos.2 hx) hN)).1 hN)⟩
      let ⟨M, hM⟩ := pow_unbounded_of_one_lt x hy
      have hb : ∃ b : ℤ, ∀ m, y ^ m ≤ x → m ≤ b :=
        ⟨M, fun m hm =>
          le_of_not_ltₓ fun hlt =>
            not_lt_of_geₓ (zpow_le_of_le hy.le hlt.le)
              (lt_of_le_of_ltₓ hm
                (by
                  rwa [← zpow_coe_nat] at hM))⟩
      let ⟨n, hn₁, hn₂⟩ := Int.exists_greatest_of_bdd hb he
      ⟨n, hn₁, lt_of_not_geₓ fun hge => not_le_of_gtₓ (Int.lt_succₓ _) (hn₂ _ hge)⟩

/-- Every positive `x` is between two successive integer powers of
another `y` greater than one. This is the same as `exists_mem_Ico_zpow`,
but with ≤ and < the other way around. -/
theorem exists_mem_Ioc_zpow (hx : 0 < x) (hy : 1 < y) : ∃ n : ℤ, x ∈ Ioc (y ^ n) (y ^ (n + 1)) :=
  let ⟨m, hle, hlt⟩ := exists_mem_Ico_zpow (inv_pos.2 hx) hy
  have hyp : 0 < y := lt_transₓ zero_lt_one hy
  ⟨-(m + 1), by
    rwa [zpow_neg, inv_lt (zpow_pos_of_pos hyp _) hx], by
    rwa [neg_add, neg_add_cancel_right, zpow_neg, le_inv hx (zpow_pos_of_pos hyp _)]⟩

/-- For any `y < 1` and any positive `x`, there exists `n : ℕ` with `y ^ n < x`. -/
theorem exists_pow_lt_of_lt_one (hx : 0 < x) (hy : y < 1) : ∃ n : ℕ, y ^ n < x := by
  by_cases' y_pos : y ≤ 0
  · use 1
    simp only [pow_oneₓ]
    linarith
    
  rw [not_leₓ] at y_pos
  rcases pow_unbounded_of_one_lt x⁻¹ (one_lt_inv y_pos hy) with ⟨q, hq⟩
  exact
    ⟨q, by
      rwa [inv_pow, inv_lt_inv hx (pow_pos y_pos _)] at hq⟩

/-- Given `x` and `y` between `0` and `1`, `x` is between two successive powers of `y`.
This is the same as `exists_nat_pow_near`, but for elements between `0` and `1` -/
theorem exists_nat_pow_near_of_lt_one (xpos : 0 < x) (hx : x ≤ 1) (ypos : 0 < y) (hy : y < 1) :
    ∃ n : ℕ, y ^ (n + 1) < x ∧ x ≤ y ^ n := by
  rcases exists_nat_pow_near (one_le_inv_iff.2 ⟨xpos, hx⟩) (one_lt_inv_iff.2 ⟨ypos, hy⟩) with ⟨n, hn, h'n⟩
  refine' ⟨n, _, _⟩
  · rwa [inv_pow, inv_lt_inv xpos (pow_pos ypos _)] at h'n
    
  · rwa [inv_pow, inv_le_inv (pow_pos ypos _) xpos] at hn
    

theorem exists_rat_gt (x : α) : ∃ q : ℚ, x < q :=
  let ⟨n, h⟩ := exists_nat_gt x
  ⟨n, by
    rwa [Rat.cast_coe_nat]⟩

theorem exists_rat_lt (x : α) : ∃ q : ℚ, (q : α) < x :=
  let ⟨n, h⟩ := exists_int_lt x
  ⟨n, by
    rwa [Rat.cast_coe_int]⟩

theorem exists_rat_btwn {x y : α} (h : x < y) : ∃ q : ℚ, x < q ∧ (q : α) < y := by
  cases' exists_nat_gt (y - x)⁻¹ with n nh
  cases' exists_floor (x * n) with z zh
  refine' ⟨(z + 1 : ℤ) / n, _⟩
  have n0' := (inv_pos.2 (sub_pos.2 h)).trans nh
  have n0 := Nat.cast_pos.1 n0'
  rw [Rat.cast_div_of_ne_zero, Rat.cast_coe_nat, Rat.cast_coe_int, div_lt_iff n0']
  refine' ⟨(lt_div_iff n0').2 <| (lt_iff_lt_of_le_iff_leₓ (zh _)).1 (lt_add_one _), _⟩
  rw [Int.cast_add, Int.cast_oneₓ]
  refine' lt_of_le_of_ltₓ (add_le_add_right ((zh _).1 le_rflₓ) _) _
  rwa [← lt_sub_iff_add_lt', ← sub_mul, ← div_lt_iff' (sub_pos.2 h), one_div]
  · rw [Rat.coe_int_denom, Nat.cast_oneₓ]
    exact one_ne_zero
    
  · intro H
    rw [Rat.coe_nat_num, Int.cast_coe_nat, Nat.cast_eq_zero] at H
    subst H
    cases n0
    
  · rw [Rat.coe_nat_denom, Nat.cast_oneₓ]
    exact one_ne_zero
    

theorem le_of_forall_rat_lt_imp_le (h : ∀ q : ℚ, (q : α) < x → (q : α) ≤ y) : x ≤ y :=
  le_of_not_ltₓ fun hyx =>
    let ⟨q, hy, hx⟩ := exists_rat_btwn hyx
    hy.not_le <| h _ hx

theorem le_of_forall_lt_rat_imp_le (h : ∀ q : ℚ, y < q → x ≤ q) : x ≤ y :=
  le_of_not_ltₓ fun hyx =>
    let ⟨q, hy, hx⟩ := exists_rat_btwn hyx
    hx.not_le <| h _ hy

theorem eq_of_forall_rat_lt_iff_lt (h : ∀ q : ℚ, (q : α) < x ↔ (q : α) < y) : x = y :=
  (le_of_forall_rat_lt_imp_le fun q hq => ((h q).1 hq).le).antisymm <|
    le_of_forall_rat_lt_imp_le fun q hq => ((h q).2 hq).le

theorem eq_of_forall_lt_rat_iff_lt (h : ∀ q : ℚ, x < q ↔ y < q) : x = y :=
  (le_of_forall_lt_rat_imp_le fun q hq => ((h q).2 hq).le).antisymm <|
    le_of_forall_lt_rat_imp_le fun q hq => ((h q).1 hq).le

theorem exists_nat_one_div_lt {ε : α} (hε : 0 < ε) : ∃ n : ℕ, 1 / (n + 1 : α) < ε := by
  cases' exists_nat_gt (1 / ε) with n hn
  use n
  rw [div_lt_iff, ← div_lt_iff' hε]
  · apply hn.trans
    simp [zero_lt_one]
    
  · exact n.cast_add_one_pos
    

theorem exists_pos_rat_lt {x : α} (x0 : 0 < x) : ∃ q : ℚ, 0 < q ∧ (q : α) < x := by
  simpa only [Rat.cast_pos] using exists_rat_btwn x0

theorem exists_rat_near (x : α) (ε0 : 0 < ε) : ∃ q : ℚ, abs (x - q) < ε :=
  let ⟨q, h₁, h₂⟩ := exists_rat_btwn <| ((sub_lt_self_iff x).2 ε0).trans ((lt_add_iff_pos_left x).2 ε0)
  ⟨q, abs_sub_lt_iff.2 ⟨sub_lt.1 h₁, sub_lt_iff_lt_add.2 h₂⟩⟩

end LinearOrderedField

section LinearOrderedField

variable [LinearOrderedField α]

theorem archimedean_iff_nat_lt : Archimedean α ↔ ∀ x : α, ∃ n : ℕ, x < n :=
  ⟨@exists_nat_gt α _ _, fun H =>
    ⟨fun x y y0 =>
      (H (x / y)).imp fun n h =>
        le_of_ltₓ <| by
          rwa [div_lt_iff y0, ← nsmul_eq_mul] at h⟩⟩

theorem archimedean_iff_nat_le : Archimedean α ↔ ∀ x : α, ∃ n : ℕ, x ≤ n :=
  archimedean_iff_nat_lt.trans
    ⟨fun H x => (H x).imp fun _ => le_of_ltₓ, fun H x =>
      let ⟨n, h⟩ := H x
      ⟨n + 1, lt_of_le_of_ltₓ h (Nat.cast_lt.2 (lt_add_one _))⟩⟩

theorem archimedean_iff_int_lt : Archimedean α ↔ ∀ x : α, ∃ n : ℤ, x < n :=
  ⟨@exists_int_gt α _ _, by
    rw [archimedean_iff_nat_lt]
    intro h x
    obtain ⟨n, h⟩ := h x
    refine' ⟨n.to_nat, h.trans_le _⟩
    exact_mod_cast Int.le_to_nat _⟩

theorem archimedean_iff_int_le : Archimedean α ↔ ∀ x : α, ∃ n : ℤ, x ≤ n :=
  archimedean_iff_int_lt.trans
    ⟨fun H x => (H x).imp fun _ => le_of_ltₓ, fun H x =>
      let ⟨n, h⟩ := H x
      ⟨n + 1, lt_of_le_of_ltₓ h (Int.cast_lt.2 (lt_add_one _))⟩⟩

theorem archimedean_iff_rat_lt : Archimedean α ↔ ∀ x : α, ∃ q : ℚ, x < q :=
  ⟨@exists_rat_gt α _, fun H =>
    archimedean_iff_nat_lt.2 fun x =>
      let ⟨q, h⟩ := H x
      ⟨⌈q⌉₊,
        lt_of_lt_of_leₓ h <| by
          simpa only [Rat.cast_coe_nat] using (@Rat.cast_le α _ _ _).2 (Nat.le_ceil _)⟩⟩

theorem archimedean_iff_rat_le : Archimedean α ↔ ∀ x : α, ∃ q : ℚ, x ≤ q :=
  archimedean_iff_rat_lt.trans
    ⟨fun H x => (H x).imp fun _ => le_of_ltₓ, fun H x =>
      let ⟨n, h⟩ := H x
      ⟨n + 1, lt_of_le_of_ltₓ h (Rat.cast_lt.2 (lt_add_one _))⟩⟩

end LinearOrderedField

instance : Archimedean ℕ :=
  ⟨fun n m m0 =>
    ⟨n, by
      simpa only [mul_oneₓ, Nat.nsmul_eq_mul] using Nat.mul_le_mul_leftₓ n m0⟩⟩

instance : Archimedean ℤ :=
  ⟨fun n m m0 =>
    ⟨n.toNat,
      le_transₓ (Int.le_to_nat _) <| by
        simpa only [nsmul_eq_mul, zero_addₓ, mul_oneₓ] using
          mul_le_mul_of_nonneg_left (Int.add_one_le_iff.2 m0) (Int.coe_zero_le n.to_nat)⟩⟩

instance : Archimedean ℚ :=
  archimedean_iff_rat_le.2 fun q =>
    ⟨q, by
      rw [Rat.cast_id]⟩

/-- A linear ordered archimedean ring is a floor ring. This is not an `instance` because in some
cases we have a computable `floor` function. -/
noncomputable def Archimedean.floorRing (α) [LinearOrderedRing α] [Archimedean α] : FloorRing α :=
  FloorRing.ofFloor α (fun a => Classical.choose (exists_floor a)) fun z a =>
    (Classical.choose_spec (exists_floor a) z).symm

/-- A linear ordered field that is a floor ring is archimedean. -/
theorem FloorRing.archimedean (α) [LinearOrderedField α] [FloorRing α] : Archimedean α := by
  rw [archimedean_iff_int_le]
  exact fun x => ⟨⌈x⌉, Int.le_ceil x⟩

