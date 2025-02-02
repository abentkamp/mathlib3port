/-
Copyright (c) 2022 Michael Stoll. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Michael Stoll
-/
import Mathbin.NumberTheory.LegendreSymbol.ZmodChar
import Mathbin.FieldTheory.Finite.Basic
import Mathbin.NumberTheory.LegendreSymbol.GaussSum

/-!
# Quadratic characters of finite fields

This file defines the quadratic character on a finite field `F` and proves
some basic statements about it.

## Tags

quadratic character
-/


/-!
### Definition of the quadratic character

We define the quadratic character of a finite field `F` with values in ℤ.
-/


section Define

/-- Define the quadratic character with values in ℤ on a monoid with zero `α`.
It takes the value zero at zero; for non-zero argument `a : α`, it is `1`
if `a` is a square, otherwise it is `-1`.

This only deserves the name "character" when it is multiplicative,
e.g., when `α` is a finite field. See `quadratic_char_fun_mul`.

We will later define `quadratic_char` to be a multiplicative character
of type `mul_char F ℤ`, when the domain is a finite field `F`.
-/
def quadraticCharFun (α : Type _) [MonoidWithZeroₓ α] [DecidableEq α] [DecidablePred (IsSquare : α → Prop)] (a : α) :
    ℤ :=
  if a = 0 then 0 else if IsSquare a then 1 else -1

end Define

/-!
### Basic properties of the quadratic character

We prove some properties of the quadratic character.
We work with a finite field `F` here.
The interesting case is when the characteristic of `F` is odd.
-/


section quadraticChar

open MulChar

variable {F : Type _} [Field F] [Fintype F] [DecidableEq F]

/-- Some basic API lemmas -/
theorem quadratic_char_fun_eq_zero_iff {a : F} : quadraticCharFun F a = 0 ↔ a = 0 := by
  simp only [quadraticCharFun]
  by_cases' ha : a = 0
  · simp only [ha, eq_self_iff_true, if_true]
    
  · simp only [ha, if_false, iff_falseₓ]
    split_ifs <;> simp only [neg_eq_zero, one_ne_zero, not_false_iff]
    

@[simp]
theorem quadratic_char_fun_zero : quadraticCharFun F 0 = 0 := by
  simp only [quadraticCharFun, eq_self_iff_true, if_true, id.def]

@[simp]
theorem quadratic_char_fun_one : quadraticCharFun F 1 = 1 := by
  simp only [quadraticCharFun, one_ne_zero, is_square_one, if_true, if_false, id.def]

/-- If `ring_char F = 2`, then `quadratic_char_fun F` takes the value `1` on nonzero elements. -/
theorem quadratic_char_fun_eq_one_of_char_two (hF : ringChar F = 2) {a : F} (ha : a ≠ 0) : quadraticCharFun F a = 1 :=
  by
  simp only [quadraticCharFun, ha, if_false, ite_eq_left_iff]
  exact fun h => False.ndrec _ (h (FiniteField.is_square_of_char_two hF a))

/-- If `ring_char F` is odd, then `quadratic_char_fun F a` can be computed in
terms of `a ^ (fintype.card F / 2)`. -/
theorem quadratic_char_fun_eq_pow_of_char_ne_two (hF : ringChar F ≠ 2) {a : F} (ha : a ≠ 0) :
    quadraticCharFun F a = if a ^ (Fintype.card F / 2) = 1 then 1 else -1 := by
  simp only [quadraticCharFun, ha, if_false]
  simp_rw [FiniteField.is_square_iff hF ha]

/-- The quadratic character is multiplicative. -/
theorem quadratic_char_fun_mul (a b : F) : quadraticCharFun F (a * b) = quadraticCharFun F a * quadraticCharFun F b :=
  by
  by_cases' ha : a = 0
  · rw [ha, zero_mul, quadratic_char_fun_zero, zero_mul]
    
  -- now `a ≠ 0`
  by_cases' hb : b = 0
  · rw [hb, mul_zero, quadratic_char_fun_zero, mul_zero]
    
  -- now `a ≠ 0` and `b ≠ 0`
  have hab := mul_ne_zero ha hb
  by_cases' hF : ringChar F = 2
  · -- case `ring_char F = 2`
    rw [quadratic_char_fun_eq_one_of_char_two hF ha, quadratic_char_fun_eq_one_of_char_two hF hb,
      quadratic_char_fun_eq_one_of_char_two hF hab, mul_oneₓ]
    
  · -- case of odd characteristic
    rw [quadratic_char_fun_eq_pow_of_char_ne_two hF ha, quadratic_char_fun_eq_pow_of_char_ne_two hF hb,
      quadratic_char_fun_eq_pow_of_char_ne_two hF hab, mul_powₓ]
    cases' FiniteField.pow_dichotomy hF hb with hb' hb'
    · simp only [hb', mul_oneₓ, eq_self_iff_true, if_true]
      
    · have h := Ringₓ.neg_one_ne_one_of_char_ne_two hF
      -- `-1 ≠ 1`
      simp only [hb', h, mul_neg, mul_oneₓ, if_false, ite_mul, neg_mul]
      cases' FiniteField.pow_dichotomy hF ha with ha' ha' <;>
        simp only [ha', h, neg_negₓ, eq_self_iff_true, if_true, if_false]
      
    

variable (F)

/-- The quadratic character as a multiplicative character. -/
@[simps]
def quadraticChar : MulChar F ℤ where
  toFun := quadraticCharFun F
  map_one' := quadratic_char_fun_one
  map_mul' := quadratic_char_fun_mul
  map_nonunit' := fun a ha => by
    rw [of_not_not (mt Ne.is_unit ha)]
    exact quadratic_char_fun_zero

variable {F}

/-- The value of the quadratic character on `a` is zero iff `a = 0`. -/
theorem quadratic_char_eq_zero_iff {a : F} : quadraticChar F a = 0 ↔ a = 0 :=
  quadratic_char_fun_eq_zero_iff

@[simp]
theorem quadratic_char_zero : quadraticChar F 0 = 0 := by
  simp only [quadratic_char_apply, quadratic_char_fun_zero]

/-- For nonzero `a : F`, `quadratic_char F a = 1 ↔ is_square a`. -/
theorem quadratic_char_one_iff_is_square {a : F} (ha : a ≠ 0) : quadraticChar F a = 1 ↔ IsSquare a := by
  simp only [quadratic_char_apply, quadraticCharFun, ha,
    (by
      decide : (-1 : ℤ) ≠ 1),
    if_false, ite_eq_left_iff, imp_false, not_not]

/-- The quadratic character takes the value `1` on nonzero squares. -/
theorem quadratic_char_sq_one' {a : F} (ha : a ≠ 0) : quadraticChar F (a ^ 2) = 1 := by
  simp only [quadraticCharFun, ha, pow_eq_zero_iff, Nat.succ_pos', is_square_sq, if_true, if_false,
    quadratic_char_apply]

/-- The square of the quadratic character on nonzero arguments is `1`. -/
theorem quadratic_char_sq_one {a : F} (ha : a ≠ 0) : quadraticChar F a ^ 2 = 1 := by
  rwa [pow_two, ← map_mul, ← pow_two, quadratic_char_sq_one']

/-- The quadratic character is `1` or `-1` on nonzero arguments. -/
theorem quadratic_char_dichotomy {a : F} (ha : a ≠ 0) : quadraticChar F a = 1 ∨ quadraticChar F a = -1 :=
  sq_eq_one_iff.1 <| quadratic_char_sq_one ha

/-- The quadratic character is `1` or `-1` on nonzero arguments. -/
theorem quadratic_char_eq_neg_one_iff_not_one {a : F} (ha : a ≠ 0) : quadraticChar F a = -1 ↔ ¬quadraticChar F a = 1 :=
  by
  refine' ⟨fun h => _, fun h₂ => (or_iff_right h₂).mp (quadratic_char_dichotomy ha)⟩
  rw [h]
  norm_num

/-- For `a : F`, `quadratic_char F a = -1 ↔ ¬ is_square a`. -/
theorem quadratic_char_neg_one_iff_not_is_square {a : F} : quadraticChar F a = -1 ↔ ¬IsSquare a := by
  by_cases' ha : a = 0
  · simp only [ha, is_square_zero, MulChar.map_zero, zero_eq_neg, one_ne_zero, not_true]
    
  · rw [quadratic_char_eq_neg_one_iff_not_one ha, quadratic_char_one_iff_is_square ha]
    

/-- If `F` has odd characteristic, then `quadratic_char F` takes the value `-1`. -/
theorem quadratic_char_exists_neg_one (hF : ringChar F ≠ 2) : ∃ a, quadraticChar F a = -1 :=
  (FiniteField.exists_nonsquare hF).imp fun b h₁ => quadratic_char_neg_one_iff_not_is_square.mpr h₁

/-- If `ring_char F = 2`, then `quadratic_char F` takes the value `1` on nonzero elements. -/
theorem quadratic_char_eq_one_of_char_two (hF : ringChar F = 2) {a : F} (ha : a ≠ 0) : quadraticChar F a = 1 :=
  quadratic_char_fun_eq_one_of_char_two hF ha

/-- If `ring_char F` is odd, then `quadratic_char F a` can be computed in
terms of `a ^ (fintype.card F / 2)`. -/
theorem quadratic_char_eq_pow_of_char_ne_two (hF : ringChar F ≠ 2) {a : F} (ha : a ≠ 0) :
    quadraticChar F a = if a ^ (Fintype.card F / 2) = 1 then 1 else -1 :=
  quadratic_char_fun_eq_pow_of_char_ne_two hF ha

theorem quadratic_char_eq_pow_of_char_ne_two' (hF : ringChar F ≠ 2) (a : F) :
    (quadraticChar F a : F) = a ^ (Fintype.card F / 2) := by
  by_cases' ha : a = 0
  · have : 0 < Fintype.card F / 2 := Nat.div_pos Fintype.one_lt_card two_pos
    simp only [ha, zero_pow this, quadratic_char_apply, quadratic_char_zero, Int.cast_zeroₓ]
    
  · rw [quadratic_char_eq_pow_of_char_ne_two hF ha]
    by_cases' ha' : a ^ (Fintype.card F / 2) = 1
    · simp only [ha', eq_self_iff_true, if_true, Int.cast_oneₓ]
      
    · have ha'' := Or.resolve_left (FiniteField.pow_dichotomy hF ha) ha'
      simp only [ha'', Int.cast_ite, Int.cast_oneₓ, Int.cast_neg, ite_eq_right_iff]
      exact Eq.symm
      
    

variable (F)

/-- The quadratic character is quadratic as a multiplicative character. -/
theorem quadratic_char_is_quadratic : (quadraticChar F).IsQuadratic := by
  intro a
  by_cases' ha : a = 0
  · left
    rw [ha]
    exact quadratic_char_zero
    
  · right
    exact quadratic_char_dichotomy ha
    

variable {F}

/-- The quadratic character is nontrivial as a multiplicative character
when the domain has odd characteristic. -/
theorem quadratic_char_is_nontrivial (hF : ringChar F ≠ 2) : (quadraticChar F).IsNontrivial := by
  rcases quadratic_char_exists_neg_one hF with ⟨a, ha⟩
  have hu : IsUnit a := by
    by_contra hf
    rw [map_nonunit _ hf] at ha
    norm_num at ha
  refine' ⟨hu.unit, (_ : quadraticChar F a ≠ 1)⟩
  rw [ha]
  norm_num

/-- The number of solutions to `x^2 = a` is determined by the quadratic character. -/
theorem quadratic_char_card_sqrts (hF : ringChar F ≠ 2) (a : F) :
    ↑{ x : F | x ^ 2 = a }.toFinset.card = quadraticChar F a + 1 := by
  -- we consider the cases `a = 0`, `a` is a nonzero square and `a` is a nonsquare in turn
  by_cases' h₀ : a = 0
  · simp only [h₀, pow_eq_zero_iff, Nat.succ_pos', Int.coe_nat_succ, Int.coe_nat_zero, MulChar.map_zero,
      Set.set_of_eq_eq_singleton, Set.to_finset_card, Set.card_singleton]
    
  · set s := { x : F | x ^ 2 = a }.toFinset with hs
    by_cases' h : IsSquare a
    · rw [(quadratic_char_one_iff_is_square h₀).mpr h]
      rcases h with ⟨b, h⟩
      rw [h, mul_self_eq_zero] at h₀
      have h₁ : s = [b, -b].toFinset := by
        ext x
        simp only [Finset.mem_filter, Finset.mem_univ, true_andₓ, List.to_finset_cons, List.to_finset_nil,
          insert_emptyc_eq, Finset.mem_insert, Finset.mem_singleton]
        rw [← pow_two] at h
        simp only [hs, Set.mem_to_finset, Set.mem_set_of_eq, h]
        constructor
        · exact eq_or_eq_neg_of_sq_eq_sq _ _
          
        · rintro (h₂ | h₂) <;> rw [h₂]
          simp only [neg_sq]
          
      norm_cast
      rw [h₁, List.to_finset_cons, List.to_finset_cons, List.to_finset_nil]
      exact Finset.card_doubleton (Ne.symm (mt (Ringₓ.eq_self_iff_eq_zero_of_char_ne_two hF).mp h₀))
      
    · rw [quadratic_char_neg_one_iff_not_is_square.mpr h]
      simp only [Int.coe_nat_eq_zero, Finset.card_eq_zero, Set.to_finset_card, Fintype.card_of_finset,
        Set.mem_set_of_eq, add_left_negₓ]
      ext x
      simp only [iff_falseₓ, Finset.mem_filter, Finset.mem_univ, true_andₓ, Finset.not_mem_empty]
      rw [is_square_iff_exists_sq] at h
      exact fun h' => h ⟨_, h'.symm⟩
      
    

open BigOperators

/-- The sum over the values of the quadratic character is zero when the characteristic is odd. -/
theorem quadratic_char_sum_zero (hF : ringChar F ≠ 2) : (∑ a : F, quadraticChar F a) = 0 :=
  IsNontrivial.sum_eq_zero (quadratic_char_is_nontrivial hF)

end quadraticChar

/-!
### Special values of the quadratic character

We express `quadratic_char F (-1)` in terms of `χ₄`.
-/


section SpecialValues

open Zmod MulChar

variable {F : Type} [Field F] [Fintype F]

/-- The value of the quadratic character at `-1` -/
theorem quadratic_char_neg_one [DecidableEq F] (hF : ringChar F ≠ 2) : quadraticChar F (-1) = χ₄ (Fintype.card F) := by
  have h := quadratic_char_eq_pow_of_char_ne_two hF (neg_ne_zero.mpr one_ne_zero)
  rw [h, χ₄_eq_neg_one_pow (FiniteField.odd_card_of_char_ne_two hF)]
  set n := Fintype.card F / 2
  cases' Nat.even_or_odd n with h₂ h₂
  · simp only [Even.neg_one_pow h₂, eq_self_iff_true, if_true]
    
  · simp only [Odd.neg_one_pow h₂, ite_eq_right_iff]
    exact fun hf => False.ndrec (1 = -1) (Ringₓ.neg_one_ne_one_of_char_ne_two hF hf)
    

/-- `-1` is a square in `F` iff `#F` is not congruent to `3` mod `4`. -/
theorem FiniteField.is_square_neg_one_iff : IsSquare (-1 : F) ↔ Fintype.card F % 4 ≠ 3 := by
  classical
  -- suggested by the linter (instead of `[decidable_eq F]`)
  by_cases' hF : ringChar F = 2
  · simp only [FiniteField.is_square_of_char_two hF, Ne.def, true_iffₓ]
    exact fun hf => one_ne_zero <| (Nat.odd_of_mod_four_eq_three hf).symm.trans <| FiniteField.even_card_of_char_two hF
    
  · have h₁ := FiniteField.odd_card_of_char_ne_two hF
    rw [← quadratic_char_one_iff_is_square (neg_ne_zero.mpr (@one_ne_zero F _ _)), quadratic_char_neg_one hF,
      χ₄_nat_eq_if_mod_four, h₁]
    simp only [Nat.one_ne_zero, if_false, ite_eq_left_iff, Ne.def,
      (by
        decide : (-1 : ℤ) ≠ 1),
      imp_false, not_not]
    exact
      ⟨fun h =>
        ne_of_eq_of_ne h
          (by
            decide : 1 ≠ 3),
        Or.resolve_right (nat.odd_mod_four_iff.mp h₁)⟩
    

/-- The value of the quadratic character at `2` -/
theorem quadratic_char_two [DecidableEq F] (hF : ringChar F ≠ 2) : quadraticChar F 2 = χ₈ (Fintype.card F) :=
  IsQuadratic.eq_of_eq_coe (quadratic_char_is_quadratic F) is_quadratic_χ₈ hF
    ((quadratic_char_eq_pow_of_char_ne_two' hF 2).trans (FiniteField.two_pow_card hF))

/-- `2` is a square in `F` iff `#F` is not congruent to `3` or `5` mod `8`. -/
theorem FiniteField.is_square_two_iff : IsSquare (2 : F) ↔ Fintype.card F % 8 ≠ 3 ∧ Fintype.card F % 8 ≠ 5 := by
  classical
  by_cases' hF : ringChar F = 2
  focus
    have h := FiniteField.even_card_of_char_two hF
    simp only [FiniteField.is_square_of_char_two hF, true_iffₓ]
  rotate_left
  focus
    have h := FiniteField.odd_card_of_char_ne_two hF
    rw [← quadratic_char_one_iff_is_square (Ringₓ.two_ne_zero hF), quadratic_char_two hF, χ₈_nat_eq_if_mod_eight]
    simp only [h, Nat.one_ne_zero, if_false, ite_eq_left_iff, Ne.def,
      (by
        decide : (-1 : ℤ) ≠ 1),
      imp_false, not_not]
  all_goals
    rw [←
      Nat.mod_mod_of_dvd _
        (by
          norm_num : 2 ∣ 8)] at
      h
    have h₁ :=
      Nat.mod_ltₓ (Fintype.card F)
        (by
          decide : 0 < 8)
    revert h₁ h
    generalize Fintype.card F % 8 = n
    decide!

/-- The value of the quadratic character at `-2` -/
theorem quadratic_char_neg_two [DecidableEq F] (hF : ringChar F ≠ 2) : quadraticChar F (-2) = χ₈' (Fintype.card F) := by
  rw
    [(by
      norm_num : (-2 : F) = -1 * 2),
    map_mul, χ₈'_eq_χ₄_mul_χ₈, quadratic_char_neg_one hF, quadratic_char_two hF,
    @cast_nat_cast _ (Zmod 4) _ _ _
      (by
        norm_num : 4 ∣ 8)]

/-- `-2` is a square in `F` iff `#F` is not congruent to `5` or `7` mod `8`. -/
theorem FiniteField.is_square_neg_two_iff : IsSquare (-2 : F) ↔ Fintype.card F % 8 ≠ 5 ∧ Fintype.card F % 8 ≠ 7 := by
  classical
  by_cases' hF : ringChar F = 2
  focus
    have h := FiniteField.even_card_of_char_two hF
    simp only [FiniteField.is_square_of_char_two hF, true_iffₓ]
  rotate_left
  focus
    have h := FiniteField.odd_card_of_char_ne_two hF
    rw [← quadratic_char_one_iff_is_square (neg_ne_zero.mpr (Ringₓ.two_ne_zero hF)), quadratic_char_neg_two hF,
      χ₈'_nat_eq_if_mod_eight]
    simp only [h, Nat.one_ne_zero, if_false, ite_eq_left_iff, Ne.def,
      (by
        decide : (-1 : ℤ) ≠ 1),
      imp_false, not_not]
  all_goals
    rw [←
      Nat.mod_mod_of_dvd _
        (by
          norm_num : 2 ∣ 8)] at
      h
    have h₁ :=
      Nat.mod_ltₓ (Fintype.card F)
        (by
          decide : 0 < 8)
    revert h₁ h
    generalize Fintype.card F % 8 = n
    decide!

/-- The relation between the values of the quadratic character of one field `F` at the
cardinality of another field `F'` and of the quadratic character of `F'` at the cardinality
of `F`. -/
theorem quadratic_char_card_card [DecidableEq F] (hF : ringChar F ≠ 2) {F' : Type} [Field F'] [Fintype F']
    [DecidableEq F'] (hF' : ringChar F' ≠ 2) (h : ringChar F' ≠ ringChar F) :
    quadraticChar F (Fintype.card F') = quadraticChar F' (quadraticChar F (-1) * Fintype.card F) := by
  let χ := (quadraticChar F).ringHomComp (algebraMap ℤ F')
  have hχ₁ : χ.is_nontrivial := by
    obtain ⟨a, ha⟩ := quadratic_char_exists_neg_one hF
    have hu : IsUnit a := by
      contrapose ha
      exact ne_of_eq_of_ne (map_nonunit (quadraticChar F) ha) (mt zero_eq_neg.mp one_ne_zero)
    use hu.unit
    simp only [IsUnit.unit_spec, ring_hom_comp_apply, eq_int_cast, Ne.def, ha]
    rw [Int.cast_neg, Int.cast_oneₓ]
    exact Ringₓ.neg_one_ne_one_of_char_ne_two hF'
  have hχ₂ : χ.is_quadratic := is_quadratic.comp (quadratic_char_is_quadratic F) _
  have h := Charₓ.card_pow_card hχ₁ hχ₂ h hF'
  rw [← quadratic_char_eq_pow_of_char_ne_two' hF'] at h
  exact (is_quadratic.eq_of_eq_coe (quadratic_char_is_quadratic F') (quadratic_char_is_quadratic F) hF' h).symm

/-- The value of the quadratic character at an odd prime `p` different from `ring_char F`. -/
theorem quadratic_char_odd_prime [DecidableEq F] (hF : ringChar F ≠ 2) {p : ℕ} [Fact p.Prime] (hp₁ : p ≠ 2)
    (hp₂ : ringChar F ≠ p) : quadraticChar F p = quadraticChar (Zmod p) (χ₄ (Fintype.card F) * Fintype.card F) := by
  rw [← quadratic_char_neg_one hF]
  have h :=
    quadratic_char_card_card hF (ne_of_eq_of_ne (ring_char_zmod_n p) hp₁) (ne_of_eq_of_ne (ring_char_zmod_n p) hp₂.symm)
  rwa [card p] at h

/-- An odd prime `p` is a square in `F` iff the quadratic character of `zmod p` does not
take the value `-1` on `χ₄(#F) * #F`. -/
theorem FiniteField.is_square_odd_prime_iff (hF : ringChar F ≠ 2) {p : ℕ} [Fact p.Prime] (hp : p ≠ 2) :
    IsSquare (p : F) ↔ quadraticChar (Zmod p) (χ₄ (Fintype.card F) * Fintype.card F) ≠ -1 := by
  classical
  by_cases' hFp : ringChar F = p
  · rw
      [show (p : F) = 0 by
        rw [← hFp]
        exact ringChar.Nat.cast_ring_char]
    simp only [is_square_zero, Ne.def, true_iffₓ, map_mul]
    obtain ⟨n, _, hc⟩ := FiniteField.card F (ringChar F)
    have hchar : ringChar F = ringChar (Zmod p) := by
      rw [hFp]
      exact (ring_char_zmod_n p).symm
    conv => congr lhs congr skip rw [hc, Nat.cast_powₓ, map_pow, hchar, map_ring_char]
    simp only [zero_pow n.pos, mul_zero, zero_eq_neg, one_ne_zero, not_false_iff]
    
  · rw [← Iff.not_left (@quadratic_char_neg_one_iff_not_is_square F _ _ _ _), quadratic_char_odd_prime hF hp]
    exact hFp
    

end SpecialValues

