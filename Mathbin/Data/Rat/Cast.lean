/-
Copyright (c) 2019 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro
-/
import Mathbin.Data.Rat.Order
import Mathbin.Data.Int.CharZero
import Mathbin.Algebra.Field.Opposite

/-!
# Casts for Rational Numbers

## Summary

We define the canonical injection from ℚ into an arbitrary division ring and prove various
casting lemmas showing the well-behavedness of this injection.

## Notations

- `/.` is infix notation for `rat.mk`.

## Tags

rat, rationals, field, ℚ, numerator, denominator, num, denom, cast, coercion, casting
-/


open BigOperators

variable {F ι α β : Type _}

namespace Rat

open Rat

section WithDivRing

variable [DivisionRing α]

@[simp]
theorem cast_of_int (n : ℤ) : (ofInt n : α) = n :=
  (cast_def _).trans <|
    show (n / (1 : ℕ) : α) = n by
      rw [Nat.cast_oneₓ, div_one]

@[simp, norm_cast]
theorem cast_coe_int (n : ℤ) : ((n : ℚ) : α) = n := by
  rw [coe_int_eq_of_int, cast_of_int]

@[simp, norm_cast]
theorem cast_coe_nat (n : ℕ) : ((n : ℚ) : α) = n := by
  rw [← Int.cast_coe_nat, cast_coe_int, Int.cast_coe_nat]

@[simp, norm_cast]
theorem cast_zero : ((0 : ℚ) : α) = 0 :=
  (cast_of_int _).trans Int.cast_zeroₓ

@[simp, norm_cast]
theorem cast_one : ((1 : ℚ) : α) = 1 :=
  (cast_of_int _).trans Int.cast_oneₓ

theorem cast_commute (r : ℚ) (a : α) : Commute (↑r) a := by
  simpa only [cast_def] using (r.1.cast_commute a).div_left (r.2.cast_commute a)

theorem cast_comm (r : ℚ) (a : α) : (r : α) * a = a * r :=
  (cast_commute r a).Eq

theorem commute_cast (a : α) (r : ℚ) : Commute a r :=
  (r.cast_commute a).symm

@[norm_cast]
theorem cast_mk_of_ne_zero (a b : ℤ) (b0 : (b : α) ≠ 0) : (a /. b : α) = a / b := by
  have b0' : b ≠ 0 := by
    refine' mt _ b0
    simp (config := { contextual := true })
  cases' e : a /. b with n d h c
  have d0 : (d : α) ≠ 0 := by
    intro d0
    have dd := denom_dvd a b
    cases'
      show (d : ℤ) ∣ b by
        rwa [e] at dd with
      k ke
    have : (b : α) = (d : α) * (k : α) := by
      rw [ke, Int.cast_mul, Int.cast_coe_nat]
    rw [d0, zero_mul] at this
    contradiction
  rw [num_denom'] at e
  have := congr_argₓ (coe : ℤ → α) ((mk_eq b0' <| ne_of_gtₓ <| Int.coe_nat_pos.2 h).1 e)
  rw [Int.cast_mul, Int.cast_mul, Int.cast_coe_nat] at this
  symm
  rw [cast_def, div_eq_mul_inv, eq_div_iff_mul_eq d0, mul_assoc, (d.commute_cast _).Eq, ← mul_assoc, this, mul_assoc,
    mul_inv_cancel b0, mul_oneₓ]

@[norm_cast]
theorem cast_add_of_ne_zero : ∀ {m n : ℚ}, (m.denom : α) ≠ 0 → (n.denom : α) ≠ 0 → ((m + n : ℚ) : α) = m + n
  | ⟨n₁, d₁, h₁, c₁⟩, ⟨n₂, d₂, h₂, c₂⟩ => fun (d₁0 : (d₁ : α) ≠ 0) (d₂0 : (d₂ : α) ≠ 0) => by
    have d₁0' : (d₁ : ℤ) ≠ 0 :=
      Int.coe_nat_ne_zero.2 fun e => by
        rw [e] at d₁0 <;> exact d₁0 Nat.cast_zeroₓ
    have d₂0' : (d₂ : ℤ) ≠ 0 :=
      Int.coe_nat_ne_zero.2 fun e => by
        rw [e] at d₂0 <;> exact d₂0 Nat.cast_zeroₓ
    rw [num_denom', num_denom', add_def d₁0' d₂0']
    suffices (n₁ * (d₂ * (d₂⁻¹ * d₁⁻¹)) + n₂ * (d₁ * d₂⁻¹) * d₁⁻¹ : α) = n₁ * d₁⁻¹ + n₂ * d₂⁻¹ by
      rw [cast_mk_of_ne_zero, cast_mk_of_ne_zero, cast_mk_of_ne_zero]
      · simpa [division_def, left_distrib, right_distrib, mul_inv_rev, d₁0, d₂0, mul_assoc]
        
      all_goals
        simp [d₁0, d₂0]
    rw [← mul_assoc (d₂ : α), mul_inv_cancel d₂0, one_mulₓ, (Nat.cast_commute _ _).Eq]
    simp [d₁0, mul_assoc]

@[simp, norm_cast]
theorem cast_neg : ∀ n, ((-n : ℚ) : α) = -n
  | ⟨n, d, h, c⟩ => by
    simpa only [cast_def] using
      show (↑(-n) / d : α) = -(n / d) by
        rw [div_eq_mul_inv, div_eq_mul_inv, Int.cast_neg, neg_mul_eq_neg_mulₓ]

@[norm_cast]
theorem cast_sub_of_ne_zero {m n : ℚ} (m0 : (m.denom : α) ≠ 0) (n0 : (n.denom : α) ≠ 0) : ((m - n : ℚ) : α) = m - n :=
  by
  have : ((-n).denom : α) ≠ 0 := by
    cases n <;> exact n0
  simp [sub_eq_add_neg, cast_add_of_ne_zero m0 this]

@[norm_cast]
theorem cast_mul_of_ne_zero : ∀ {m n : ℚ}, (m.denom : α) ≠ 0 → (n.denom : α) ≠ 0 → ((m * n : ℚ) : α) = m * n
  | ⟨n₁, d₁, h₁, c₁⟩, ⟨n₂, d₂, h₂, c₂⟩ => fun (d₁0 : (d₁ : α) ≠ 0) (d₂0 : (d₂ : α) ≠ 0) => by
    have d₁0' : (d₁ : ℤ) ≠ 0 :=
      Int.coe_nat_ne_zero.2 fun e => by
        rw [e] at d₁0 <;> exact d₁0 Nat.cast_zeroₓ
    have d₂0' : (d₂ : ℤ) ≠ 0 :=
      Int.coe_nat_ne_zero.2 fun e => by
        rw [e] at d₂0 <;> exact d₂0 Nat.cast_zeroₓ
    rw [num_denom', num_denom', mul_def d₁0' d₂0']
    suffices (n₁ * (n₂ * d₂⁻¹ * d₁⁻¹) : α) = n₁ * (d₁⁻¹ * (n₂ * d₂⁻¹)) by
      rw [cast_mk_of_ne_zero, cast_mk_of_ne_zero, cast_mk_of_ne_zero]
      · simpa [division_def, mul_inv_rev, d₁0, d₂0, mul_assoc]
        
      all_goals
        simp [d₁0, d₂0]
    rw [(d₁.commute_cast (_ : α)).inv_right₀.Eq]

@[simp]
theorem cast_inv_nat (n : ℕ) : ((n⁻¹ : ℚ) : α) = n⁻¹ := by
  cases n
  · simp
    
  simp_rw [coe_nat_eq_mk, inv_def, mk, mk_nat, dif_neg n.succ_ne_zero, mk_pnat]
  simp [cast_def]

@[simp]
theorem cast_inv_int (n : ℤ) : ((n⁻¹ : ℚ) : α) = n⁻¹ := by
  cases n
  · simp [cast_inv_nat]
    
  · simp only [Int.cast_neg_succ_of_nat, ← Nat.cast_succₓ, cast_neg, inv_neg, cast_inv_nat]
    

@[norm_cast]
theorem cast_inv_of_ne_zero : ∀ {n : ℚ}, (n.num : α) ≠ 0 → (n.denom : α) ≠ 0 → ((n⁻¹ : ℚ) : α) = n⁻¹
  | ⟨n, d, h, c⟩ => fun (n0 : (n : α) ≠ 0) (d0 : (d : α) ≠ 0) => by
    have n0' : (n : ℤ) ≠ 0 := fun e => by
      rw [e] at n0 <;> exact n0 Int.cast_zeroₓ
    have d0' : (d : ℤ) ≠ 0 :=
      Int.coe_nat_ne_zero.2 fun e => by
        rw [e] at d0 <;> exact d0 Nat.cast_zeroₓ
    rw [num_denom', inv_def]
    rw [cast_mk_of_ne_zero, cast_mk_of_ne_zero, inv_div] <;> simp [n0, d0]

@[norm_cast]
theorem cast_div_of_ne_zero {m n : ℚ} (md : (m.denom : α) ≠ 0) (nn : (n.num : α) ≠ 0) (nd : (n.denom : α) ≠ 0) :
    ((m / n : ℚ) : α) = m / n := by
  have : (n⁻¹.denom : ℤ) ∣ n.num := by
    conv in n⁻¹.denom => rw [← @num_denom n, inv_def] <;> apply denom_dvd
  have : (n⁻¹.denom : α) = 0 → (n.num : α) = 0 := fun h => by
    let ⟨k, e⟩ := this
    have := congr_argₓ (coe : ℤ → α) e <;> rwa [Int.cast_mul, Int.cast_coe_nat, h, zero_mul] at this
  rw [division_def, cast_mul_of_ne_zero md (mt this nn), cast_inv_of_ne_zero nn nd, division_def]

@[simp, norm_cast]
theorem cast_inj [CharZero α] : ∀ {m n : ℚ}, (m : α) = n ↔ m = n
  | ⟨n₁, d₁, h₁, c₁⟩, ⟨n₂, d₂, h₂, c₂⟩ => by
    refine' ⟨fun h => _, congr_argₓ _⟩
    have d₁0 : d₁ ≠ 0 := ne_of_gtₓ h₁
    have d₂0 : d₂ ≠ 0 := ne_of_gtₓ h₂
    have d₁a : (d₁ : α) ≠ 0 := Nat.cast_ne_zero.2 d₁0
    have d₂a : (d₂ : α) ≠ 0 := Nat.cast_ne_zero.2 d₂0
    rw [num_denom', num_denom'] at h⊢
    rw [cast_mk_of_ne_zero, cast_mk_of_ne_zero] at h <;> simp [d₁0, d₂0] at h⊢
    rwa [eq_div_iff_mul_eq d₂a, division_def, mul_assoc, (d₁.cast_commute (d₂ : α)).inv_left₀.Eq, ← mul_assoc, ←
      division_def, eq_comm, eq_div_iff_mul_eq d₁a, eq_comm, ← Int.cast_coe_nat d₁, ← Int.cast_mul, ←
      Int.cast_coe_nat d₂, ← Int.cast_mul, Int.cast_inj, ←
      mk_eq (Int.coe_nat_ne_zero.2 d₁0) (Int.coe_nat_ne_zero.2 d₂0)] at h

theorem cast_injective [CharZero α] : Function.Injective (coe : ℚ → α)
  | m, n => cast_inj.1

@[simp]
theorem cast_eq_zero [CharZero α] {n : ℚ} : (n : α) = 0 ↔ n = 0 := by
  rw [← cast_zero, cast_inj]

theorem cast_ne_zero [CharZero α] {n : ℚ} : (n : α) ≠ 0 ↔ n ≠ 0 :=
  not_congr cast_eq_zero

@[simp, norm_cast]
theorem cast_add [CharZero α] (m n) : ((m + n : ℚ) : α) = m + n :=
  cast_add_of_ne_zero (Nat.cast_ne_zero.2 <| ne_of_gtₓ m.Pos) (Nat.cast_ne_zero.2 <| ne_of_gtₓ n.Pos)

@[simp, norm_cast]
theorem cast_sub [CharZero α] (m n) : ((m - n : ℚ) : α) = m - n :=
  cast_sub_of_ne_zero (Nat.cast_ne_zero.2 <| ne_of_gtₓ m.Pos) (Nat.cast_ne_zero.2 <| ne_of_gtₓ n.Pos)

@[simp, norm_cast]
theorem cast_mul [CharZero α] (m n) : ((m * n : ℚ) : α) = m * n :=
  cast_mul_of_ne_zero (Nat.cast_ne_zero.2 <| ne_of_gtₓ m.Pos) (Nat.cast_ne_zero.2 <| ne_of_gtₓ n.Pos)

@[simp, norm_cast]
theorem cast_bit0 [CharZero α] (n : ℚ) : ((bit0 n : ℚ) : α) = bit0 n :=
  cast_add _ _

@[simp, norm_cast]
theorem cast_bit1 [CharZero α] (n : ℚ) : ((bit1 n : ℚ) : α) = bit1 n := by
  rw [bit1, cast_add, cast_one, cast_bit0] <;> rfl

variable (α) [CharZero α]

/-- Coercion `ℚ → α` as a `ring_hom`. -/
def castHom : ℚ →+* α :=
  ⟨coe, cast_one, cast_mul, cast_zero, cast_add⟩

variable {α}

@[simp]
theorem coe_cast_hom : ⇑(castHom α) = coe :=
  rfl

@[simp, norm_cast]
theorem cast_inv (n) : ((n⁻¹ : ℚ) : α) = n⁻¹ :=
  map_inv₀ (castHom α) _

@[simp, norm_cast]
theorem cast_div (m n) : ((m / n : ℚ) : α) = m / n :=
  map_div₀ (castHom α) _ _

@[norm_cast]
theorem cast_mk (a b : ℤ) : (a /. b : α) = a / b := by
  simp only [mk_eq_div, cast_div, cast_coe_int]

@[simp, norm_cast]
theorem cast_pow (q) (k : ℕ) : ((q ^ k : ℚ) : α) = q ^ k :=
  (castHom α).map_pow q k

@[simp, norm_cast]
theorem cast_list_sum (s : List ℚ) : (↑s.Sum : α) = (s.map coe).Sum :=
  map_list_sum (Rat.castHom α) _

@[simp, norm_cast]
theorem cast_multiset_sum (s : Multiset ℚ) : (↑s.Sum : α) = (s.map coe).Sum :=
  map_multiset_sum (Rat.castHom α) _

@[simp, norm_cast]
theorem cast_sum (s : Finset ι) (f : ι → ℚ) : (↑(∑ i in s, f i) : α) = ∑ i in s, f i :=
  map_sum (Rat.castHom α) _ _

@[simp, norm_cast]
theorem cast_list_prod (s : List ℚ) : (↑s.Prod : α) = (s.map coe).Prod :=
  map_list_prod (Rat.castHom α) _

end WithDivRing

section Field

variable [Field α] [CharZero α]

@[simp, norm_cast]
theorem cast_multiset_prod (s : Multiset ℚ) : (↑s.Prod : α) = (s.map coe).Prod :=
  map_multiset_prod (Rat.castHom α) _

@[simp, norm_cast]
theorem cast_prod (s : Finset ι) (f : ι → ℚ) : (↑(∏ i in s, f i) : α) = ∏ i in s, f i :=
  map_prod (Rat.castHom α) _ _

end Field

section LinearOrderedField

variable {K : Type _} [LinearOrderedField K]

theorem cast_pos_of_pos {r : ℚ} (hr : 0 < r) : (0 : K) < r := by
  rw [Rat.cast_def]
  exact div_pos (Int.cast_pos.2 <| num_pos_iff_pos.2 hr) (Nat.cast_pos.2 r.pos)

@[mono]
theorem cast_strict_mono : StrictMono (coe : ℚ → K) := fun m n => by
  simpa only [sub_pos, cast_sub] using @cast_pos_of_pos K _ (n - m)

@[mono]
theorem cast_mono : Monotone (coe : ℚ → K) :=
  cast_strict_mono.Monotone

/-- Coercion from `ℚ` as an order embedding. -/
@[simps]
def castOrderEmbedding : ℚ ↪o K :=
  OrderEmbedding.ofStrictMono coe cast_strict_mono

@[simp, norm_cast]
theorem cast_le {m n : ℚ} : (m : K) ≤ n ↔ m ≤ n :=
  castOrderEmbedding.le_iff_le

@[simp, norm_cast]
theorem cast_lt {m n : ℚ} : (m : K) < n ↔ m < n :=
  cast_strict_mono.lt_iff_lt

@[simp]
theorem cast_nonneg {n : ℚ} : 0 ≤ (n : K) ↔ 0 ≤ n := by
  norm_cast

@[simp]
theorem cast_nonpos {n : ℚ} : (n : K) ≤ 0 ↔ n ≤ 0 := by
  norm_cast

@[simp]
theorem cast_pos {n : ℚ} : (0 : K) < n ↔ 0 < n := by
  norm_cast

@[simp]
theorem cast_lt_zero {n : ℚ} : (n : K) < 0 ↔ n < 0 := by
  norm_cast

@[simp, norm_cast]
theorem cast_min {a b : ℚ} : (↑(min a b) : K) = min a b :=
  (@cast_mono K _).map_min

@[simp, norm_cast]
theorem cast_max {a b : ℚ} : (↑(max a b) : K) = max a b :=
  (@cast_mono K _).map_max

@[simp, norm_cast]
theorem cast_abs {q : ℚ} : ((abs q : ℚ) : K) = abs q := by
  simp [abs_eq_max_neg]

open Set

@[simp]
theorem preimage_cast_Icc (a b : ℚ) : coe ⁻¹' Icc (a : K) b = Icc a b := by
  ext x
  simp

@[simp]
theorem preimage_cast_Ico (a b : ℚ) : coe ⁻¹' Ico (a : K) b = Ico a b := by
  ext x
  simp

@[simp]
theorem preimage_cast_Ioc (a b : ℚ) : coe ⁻¹' Ioc (a : K) b = Ioc a b := by
  ext x
  simp

@[simp]
theorem preimage_cast_Ioo (a b : ℚ) : coe ⁻¹' Ioo (a : K) b = Ioo a b := by
  ext x
  simp

@[simp]
theorem preimage_cast_Ici (a : ℚ) : coe ⁻¹' Ici (a : K) = Ici a := by
  ext x
  simp

@[simp]
theorem preimage_cast_Iic (a : ℚ) : coe ⁻¹' Iic (a : K) = Iic a := by
  ext x
  simp

@[simp]
theorem preimage_cast_Ioi (a : ℚ) : coe ⁻¹' Ioi (a : K) = Ioi a := by
  ext x
  simp

@[simp]
theorem preimage_cast_Iio (a : ℚ) : coe ⁻¹' Iio (a : K) = Iio a := by
  ext x
  simp

end LinearOrderedField

@[norm_cast]
theorem cast_id (n : ℚ) : (↑n : ℚ) = n := by
  rw [cast_def, num_div_denom]

@[simp]
theorem cast_eq_id : (coe : ℚ → ℚ) = id :=
  funext cast_id

@[simp]
theorem cast_hom_rat : castHom ℚ = RingHom.id ℚ :=
  RingHom.ext cast_id

end Rat

open Rat

@[simp]
theorem map_rat_cast [DivisionRing α] [DivisionRing β] [RingHomClass F α β] (f : F) (q : ℚ) : f q = q := by
  rw [cast_def, map_div₀, map_int_cast, map_nat_cast, cast_def]

@[simp]
theorem eq_rat_cast {k} [DivisionRing k] [RingHomClass F ℚ k] (f : F) (r : ℚ) : f r = r := by
  rw [← map_rat_cast f, Rat.cast_id]

namespace MonoidWithZeroHom

variable {M₀ : Type _} [MonoidWithZeroₓ M₀] [MonoidWithZeroHomClass F ℚ M₀] {f g : F}

include M₀

/-- If `f` and `g` agree on the integers then they are equal `φ`. -/
theorem ext_rat' (h : ∀ m : ℤ, f m = g m) : f = g :=
  (FunLike.ext f g) fun r => by
    rw [← r.num_div_denom, div_eq_mul_inv, map_mul, map_mul, h, ← Int.cast_coe_nat, eq_on_inv₀ f g (h _)]

/-- If `f` and `g` agree on the integers then they are equal `φ`.

See note [partially-applied ext lemmas] for why `comp` is used here. -/
@[ext]
theorem ext_rat {f g : ℚ →*₀ M₀} (h : f.comp (Int.castRingHom ℚ : ℤ →*₀ ℚ) = g.comp (Int.castRingHom ℚ)) : f = g :=
  ext_rat' <| congr_fun h

/-- Positive integer values of a morphism `φ` and its value on `-1` completely determine `φ`. -/
theorem ext_rat_on_pnat (same_on_neg_one : f (-1) = g (-1)) (same_on_pnat : ∀ n : ℕ, 0 < n → f n = g n) : f = g :=
  ext_rat' <|
    FunLike.congr_fun <|
      show (f : ℚ →*₀ M₀).comp (Int.castRingHom ℚ : ℤ →*₀ ℚ) = (g : ℚ →*₀ M₀).comp (Int.castRingHom ℚ : ℤ →*₀ ℚ) from
        ext_int'
          (by
            simpa)
          (by
            simpa)

end MonoidWithZeroHom

/-- Any two ring homomorphisms from `ℚ` to a semiring are equal. If the codomain is a division ring,
then this lemma follows from `eq_rat_cast`. -/
theorem RingHom.ext_rat {R : Type _} [Semiringₓ R] [RingHomClass F ℚ R] (f g : F) : f = g :=
  MonoidWithZeroHom.ext_rat' <|
    RingHom.congr_fun <| ((f : ℚ →+* R).comp (Int.castRingHom ℚ)).ext_int ((g : ℚ →+* R).comp (Int.castRingHom ℚ))

instance Rat.subsingleton_ring_hom {R : Type _} [Semiringₓ R] : Subsingleton (ℚ →+* R) :=
  ⟨RingHom.ext_rat⟩

namespace MulOpposite

variable [DivisionRing α]

@[simp, norm_cast]
theorem op_rat_cast (r : ℚ) : op (r : α) = (↑r : αᵐᵒᵖ) := by
  rw [cast_def, div_eq_mul_inv, op_mul, op_inv, op_nat_cast, op_int_cast, (Commute.cast_int_right _ r.num).Eq, cast_def,
    div_eq_mul_inv]

@[simp, norm_cast]
theorem unop_rat_cast (r : ℚ) : unop (r : αᵐᵒᵖ) = r := by
  rw [cast_def, div_eq_mul_inv, unop_mul, unop_inv, unop_nat_cast, unop_int_cast, (Commute.cast_int_right _ r.num).Eq,
    cast_def, div_eq_mul_inv]

end MulOpposite

