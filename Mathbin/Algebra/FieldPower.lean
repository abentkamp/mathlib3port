import Mathbin.Algebra.GroupWithZero.Power 
import Mathbin.Tactic.Linarith.Default 
import Mathbin.Data.Equiv.Ring

/-!
# Integer power operation on fields and division rings

This file collects basic facts about the operation of raising an element of a `division_ring` to an
integer power. More specialised results are provided in the case of a linearly ordered field.
-/


universe u

@[simp]
theorem RingHom.map_zpow {K L : Type _} [DivisionRing K] [DivisionRing L] (f : K →+* L) :
  ∀ a : K n : ℤ, f (a ^ n) = f a ^ n :=
  f.to_monoid_with_zero_hom.map_zpow

@[simp]
theorem RingEquiv.map_zpow {K L : Type _} [DivisionRing K] [DivisionRing L] (f : K ≃+* L) :
  ∀ a : K n : ℤ, f (a ^ n) = f a ^ n :=
  f.to_ring_hom.map_zpow

@[simp]
theorem zpow_bit0_neg {K : Type _} [DivisionRing K] (x : K) (n : ℤ) : -x ^ bit0 n = x ^ bit0 n :=
  by 
    rw [zpow_bit0', zpow_bit0', neg_mul_neg]

theorem Even.zpow_neg {K : Type _} [DivisionRing K] {n : ℤ} (h : Even n) (a : K) : -a ^ n = a ^ n :=
  by 
    obtain ⟨k, rfl⟩ := h 
    rw [←bit0_eq_two_mul, zpow_bit0_neg]

@[simp]
theorem zpow_bit1_neg {K : Type _} [DivisionRing K] (x : K) (n : ℤ) : -x ^ bit1 n = -(x ^ bit1 n) :=
  by 
    rw [zpow_bit1', zpow_bit1', neg_mul_neg, neg_mul_eq_mul_neg]

section OrderedFieldPower

open Int

variable {K : Type u} [LinearOrderedField K] {a : K} {n : ℤ}

theorem zpow_eq_zero_iff (hn : 0 < n) : a ^ n = 0 ↔ a = 0 :=
  by 
    refine' ⟨zpow_eq_zero, _⟩
    rintro rfl 
    exact zero_zpow _ hn.ne'

theorem zpow_nonneg {a : K} (ha : 0 ≤ a) : ∀ z : ℤ, 0 ≤ a ^ z
| (n : ℕ) =>
  by 
    rw [zpow_coe_nat]
    exact pow_nonneg ha _
| -[1+ n] =>
  by 
    rw [zpow_neg_succ_of_nat]
    exact inv_nonneg.2 (pow_nonneg ha _)

theorem zpow_pos_of_pos {a : K} (ha : 0 < a) : ∀ z : ℤ, 0 < a ^ z
| (n : ℕ) =>
  by 
    rw [zpow_coe_nat]
    exact pow_pos ha _
| -[1+ n] =>
  by 
    rw [zpow_neg_succ_of_nat]
    exact inv_pos.2 (pow_pos ha _)

theorem zpow_le_of_le {x : K} (hx : 1 ≤ x) {a b : ℤ} (h : a ≤ b) : x ^ a ≤ x ^ b :=
  by 
    induction' a with a a <;> induction' b with b b
    ·
      simp only [of_nat_eq_coe, zpow_coe_nat]
      apply pow_le_pow hx 
      apply le_of_coe_nat_le_coe_nat h
    ·
      apply absurd h 
      apply not_le_of_gtₓ 
      exact lt_of_lt_of_leₓ (neg_succ_lt_zero _) (of_nat_nonneg _)
    ·
      simp only [zpow_neg_succ_of_nat, one_div, of_nat_eq_coe, zpow_coe_nat]
      apply le_transₓ (inv_le_one _) <;> apply one_le_pow_of_one_le hx
    ·
      simp only [zpow_neg_succ_of_nat]
      apply (inv_le_inv _ _).2
      ·
        apply pow_le_pow hx 
        have  : -(↑a+1 : ℤ) ≤ -(↑b+1 : ℤ)
        exact h 
        have h' := le_of_neg_le_neg this 
        apply le_of_coe_nat_le_coe_nat h' 
      repeat' 
        apply pow_pos (lt_of_lt_of_leₓ zero_lt_one hx)

theorem pow_le_max_of_min_le {x : K} (hx : 1 ≤ x) {a b c : ℤ} (h : min a b ≤ c) : x ^ -c ≤ max (x ^ -a) (x ^ -b) :=
  by 
    wlog hle : a ≤ b 
    have hnle : -b ≤ -a 
    exact neg_le_neg hle 
    have hfle : x ^ -b ≤ x ^ -a 
    exact zpow_le_of_le hx hnle 
    have  : x ^ -c ≤ x ^ -a
    ·
      apply zpow_le_of_le hx 
      simpa only [min_eq_leftₓ hle, neg_le_neg_iff] using h 
    simpa only [max_eq_leftₓ hfle]

theorem zpow_le_one_of_nonpos {p : K} (hp : 1 ≤ p) {z : ℤ} (hz : z ≤ 0) : p ^ z ≤ 1 :=
  calc p ^ z ≤ p ^ 0 := zpow_le_of_le hp hz 
    _ = 1 :=
    by 
      simp 
    

theorem one_le_zpow_of_nonneg {p : K} (hp : 1 ≤ p) {z : ℤ} (hz : 0 ≤ z) : 1 ≤ p ^ z :=
  calc p ^ z ≥ p ^ 0 := zpow_le_of_le hp hz 
    _ = 1 :=
    by 
      simp 
    

theorem zpow_bit0_nonneg (a : K) (n : ℤ) : 0 ≤ a ^ bit0 n :=
  by 
    rw [zpow_bit0₀]
    exact mul_self_nonneg _

theorem zpow_two_nonneg (a : K) : 0 ≤ a ^ 2 :=
  pow_bit0_nonneg a 1

theorem zpow_bit0_pos {a : K} (h : a ≠ 0) (n : ℤ) : 0 < a ^ bit0 n :=
  (zpow_bit0_nonneg a n).lt_of_ne (zpow_ne_zero _ h).symm

theorem zpow_two_pos_of_ne_zero (a : K) (h : a ≠ 0) : 0 < a ^ 2 :=
  pow_bit0_pos h 1

@[simp]
theorem zpow_bit1_neg_iff : a ^ bit1 n < 0 ↔ a < 0 :=
  ⟨fun h => not_leₓ.1$ fun h' => not_leₓ.2 h$ zpow_nonneg h' _,
    fun h =>
      by 
        rw [bit1, zpow_add_one₀ h.ne] <;> exact mul_neg_of_pos_of_neg (zpow_bit0_pos h.ne _) h⟩

@[simp]
theorem zpow_bit1_nonneg_iff : 0 ≤ a ^ bit1 n ↔ 0 ≤ a :=
  le_iff_le_iff_lt_iff_lt.2 zpow_bit1_neg_iff

@[simp]
theorem zpow_bit1_nonpos_iff : a ^ bit1 n ≤ 0 ↔ a ≤ 0 :=
  by 
    rw [le_iff_lt_or_eqₓ, zpow_bit1_neg_iff]
    constructor
    ·
      rintro (h | h)
      ·
        exact h.le
      ·
        exact (zpow_eq_zero h).le
    ·
      intro h 
      rcases eq_or_lt_of_le h with (rfl | h)
      ·
        exact Or.inr (zero_zpow _ (bit1_ne_zero n))
      ·
        exact Or.inl h

@[simp]
theorem zpow_bit1_pos_iff : 0 < a ^ bit1 n ↔ 0 < a :=
  lt_iff_lt_of_le_iff_le zpow_bit1_nonpos_iff

theorem Even.zpow_nonneg {n : ℤ} (hn : Even n) (a : K) : 0 ≤ a ^ n :=
  by 
    cases' le_or_ltₓ 0 a with h h
    ·
      exact zpow_nonneg h _
    ·
      exact (hn.zpow_neg a).subst (zpow_nonneg (neg_nonneg_of_nonpos h.le) _)

theorem Even.zpow_pos (hn : Even n) (ha : a ≠ 0) : 0 < a ^ n :=
  by 
    cases' hn with k hk <;> simpa only [hk, two_mul] using zpow_bit0_pos ha k

theorem Odd.zpow_nonneg (hn : Odd n) (ha : 0 ≤ a) : 0 ≤ a ^ n :=
  by 
    cases' hn with k hk <;> simpa only [hk, two_mul] using zpow_bit1_nonneg_iff.mpr ha

theorem Odd.zpow_pos (hn : Odd n) (ha : 0 < a) : 0 < a ^ n :=
  by 
    cases' hn with k hk <;> simpa only [hk, two_mul] using zpow_bit1_pos_iff.mpr ha

theorem Odd.zpow_nonpos (hn : Odd n) (ha : a ≤ 0) : a ^ n ≤ 0 :=
  by 
    cases' hn with k hk <;> simpa only [hk, two_mul] using zpow_bit1_nonpos_iff.mpr ha

theorem Odd.zpow_neg (hn : Odd n) (ha : a < 0) : a ^ n < 0 :=
  by 
    cases' hn with k hk <;> simpa only [hk, two_mul] using zpow_bit1_neg_iff.mpr ha

theorem Even.zpow_abs {p : ℤ} (hp : Even p) (a : K) : |a| ^ p = a ^ p :=
  by 
    cases' abs_choice a with h h <;> simp only [h, hp.zpow_neg _]

@[simp]
theorem zpow_bit0_abs (a : K) (p : ℤ) : |a| ^ bit0 p = a ^ bit0 p :=
  (even_bit0 _).zpow_abs _

theorem Even.abs_zpow {p : ℤ} (hp : Even p) (a : K) : |a ^ p| = a ^ p :=
  by 
    rw [abs_eq_self]
    exact hp.zpow_nonneg _

@[simp]
theorem abs_zpow_bit0 (a : K) (p : ℤ) : |a ^ bit0 p| = a ^ bit0 p :=
  (even_bit0 _).abs_zpow _

end OrderedFieldPower

theorem one_lt_zpow {K} [LinearOrderedField K] {p : K} (hp : 1 < p) : ∀ z : ℤ, 0 < z → 1 < p ^ z
| (n : ℕ), h => (zpow_coe_nat p n).symm.subst (one_lt_pow hp$ Int.coe_nat_ne_zero.mp h.ne')
| -[1+ n], h => ((Int.neg_succ_not_pos _).mp h).elim

section Ordered

variable {K : Type _} [LinearOrderedField K]

theorem Nat.zpow_pos_of_pos {p : ℕ} (h : 0 < p) (n : ℤ) : 0 < (p : K) ^ n :=
  by 
    apply zpow_pos_of_pos 
    exactModCast h

theorem Nat.zpow_ne_zero_of_pos {p : ℕ} (h : 0 < p) (n : ℤ) : (p : K) ^ n ≠ 0 :=
  ne_of_gtₓ (Nat.zpow_pos_of_pos h n)

theorem zpow_strict_mono {x : K} (hx : 1 < x) : StrictMono fun n : ℤ => x ^ n :=
  fun m n h =>
    show x ^ m < x ^ n by 
      have xpos : 0 < x := zero_lt_one.trans hx 
      have h₀ : x ≠ 0 := xpos.ne' 
      have hxm : 0 < x ^ m := zpow_pos_of_pos xpos m 
      have h : 1 < x ^ (n - m) := one_lt_zpow hx _ (sub_pos_of_lt h)
      replace h := mul_lt_mul_of_pos_right h hxm 
      rwa [sub_eq_add_neg, zpow_add₀ h₀, mul_assocₓ, zpow_neg_mul_zpow_self _ h₀, one_mulₓ, mul_oneₓ] at h

@[simp]
theorem zpow_lt_iff_lt {x : K} (hx : 1 < x) {m n : ℤ} : x ^ m < x ^ n ↔ m < n :=
  (zpow_strict_mono hx).lt_iff_lt

@[simp]
theorem zpow_le_iff_le {x : K} (hx : 1 < x) {m n : ℤ} : x ^ m ≤ x ^ n ↔ m ≤ n :=
  (zpow_strict_mono hx).le_iff_le

@[simp]
theorem pos_div_pow_pos {a b : K} (ha : 0 < a) (hb : 0 < b) (k : ℕ) : 0 < a / b ^ k :=
  div_pos ha (pow_pos hb k)

@[simp]
theorem div_pow_le {a b : K} (ha : 0 < a) (hb : 1 ≤ b) (k : ℕ) : a / b ^ k ≤ a :=
  (div_le_iff$ pow_pos (lt_of_lt_of_leₓ zero_lt_one hb) k).mpr
    (calc a = a*1 := (mul_oneₓ a).symm 
      _ ≤ a*b ^ k := (mul_le_mul_left ha).mpr$ one_le_pow_of_one_le hb _
      )

theorem zpow_injective {x : K} (h₀ : 0 < x) (h₁ : x ≠ 1) : Function.Injective ((· ^ ·) x : ℤ → K) :=
  by 
    intro m n h 
    rcases h₁.lt_or_lt with (H | H)
    ·
      apply (zpow_strict_mono (one_lt_inv h₀ H)).Injective 
      show x⁻¹ ^ m = x⁻¹ ^ n 
      rw [←zpow_neg_one₀, ←zpow_mul₀, ←zpow_mul₀, mul_commₓ _ m, mul_commₓ _ n, zpow_mul₀, zpow_mul₀, h]
    ·
      exact (zpow_strict_mono H).Injective h

@[simp]
theorem zpow_inj {x : K} (h₀ : 0 < x) (h₁ : x ≠ 1) {m n : ℤ} : x ^ m = x ^ n ↔ m = n :=
  (zpow_injective h₀ h₁).eq_iff

end Ordered

section 

variable {K : Type _} [Field K]

@[simp, normCast]
theorem Rat.cast_zpow [CharZero K] (q : ℚ) (n : ℤ) : ((q ^ n : ℚ) : K) = q ^ n :=
  (Rat.castHom K).map_zpow q n

end 

