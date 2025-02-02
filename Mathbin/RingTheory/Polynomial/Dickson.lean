/-
Copyright (c) 2021 Julian Kuelshammer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Julian Kuelshammer
-/
import Mathbin.Algebra.CharP.Invertible
import Mathbin.Data.Zmod.Basic
import Mathbin.FieldTheory.Finite.Basic
import Mathbin.RingTheory.Localization.FractionRing
import Mathbin.RingTheory.Polynomial.Chebyshev

/-!
# Dickson polynomials

The (generalised) Dickson polynomials are a family of polynomials indexed by `ℕ × ℕ`,
with coefficients in a commutative ring `R` depending on an element `a∈R`. More precisely, the
they satisfy the recursion `dickson k a (n + 2) = X * (dickson k a n + 1) - a * (dickson k a n)`
with starting values `dickson k a 0 = 3 - k` and `dickson k a 1 = X`. In the literature,
`dickson k a n` is called the `n`-th Dickson polynomial of the `k`-th kind associated to the
parameter `a : R`. They are closely related to the Chebyshev polynomials in the case that `a=1`.
When `a=0` they are just the family of monomials `X ^ n`.

## Main definition

* `polynomial.dickson`: the generalised Dickson polynomials.

## Main statements

* `polynomial.dickson_one_one_mul`, the `(m * n)`-th Dickson polynomial of the first kind for
  parameter `1 : R` is the composition of the `m`-th and `n`-th Dickson polynomials of the first
  kind for `1 : R`.
* `polynomial.dickson_one_one_char_p`, for a prime number `p`, the `p`-th Dickson polynomial of the
  first kind associated to parameter `1 : R` is congruent to `X ^ p` modulo `p`.

## References

* [R. Lidl, G. L. Mullen and G. Turnwald, _Dickson polynomials_][MR1237403]

## TODO

* Redefine `dickson` in terms of `linear_recurrence`.
* Show that `dickson 2 1` is equal to the characteristic polynomial of the adjacency matrix of a
  type A Dynkin diagram.
* Prove that the adjacency matrices of simply laced Dynkin diagrams are precisely the adjacency
  matrices of simple connected graphs which annihilate `dickson 2 1`.
-/


noncomputable section

namespace Polynomial

open Polynomial

variable {R S : Type _} [CommRingₓ R] [CommRingₓ S] (k : ℕ) (a : R)

/-- `dickson` is the `n`the (generalised) Dickson polynomial of the `k`-th kind associated to the
element `a ∈ R`. -/
noncomputable def dickson : ℕ → R[X]
  | 0 => 3 - k
  | 1 => x
  | n + 2 => X * dickson (n + 1) - c a * dickson n

@[simp]
theorem dickson_zero : dickson k a 0 = 3 - k :=
  rfl

@[simp]
theorem dickson_one : dickson k a 1 = X :=
  rfl

theorem dickson_two : dickson k a 2 = X ^ 2 - c a * (3 - k) := by
  simp only [dickson, sq]

@[simp]
theorem dickson_add_two (n : ℕ) : dickson k a (n + 2) = X * dickson k a (n + 1) - c a * dickson k a n := by
  rw [dickson]

theorem dickson_of_two_le {n : ℕ} (h : 2 ≤ n) : dickson k a n = X * dickson k a (n - 1) - c a * dickson k a (n - 2) :=
  by
  obtain ⟨n, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [add_commₓ]
  exact dickson_add_two k a n

variable {R S k a}

theorem map_dickson (f : R →+* S) : ∀ n : ℕ, map f (dickson k a n) = dickson k (f a) n
  | 0 => by
    simp only [dickson_zero, Polynomial.map_sub, Polynomial.map_nat_cast, bit1, bit0, Polynomial.map_add,
      Polynomial.map_one]
  | 1 => by
    simp only [dickson_one, map_X]
  | n + 2 => by
    simp only [dickson_add_two, Polynomial.map_sub, Polynomial.map_mul, map_X, map_C]
    rw [map_dickson, map_dickson]

variable {R}

@[simp]
theorem dickson_two_zero : ∀ n : ℕ, dickson 2 (0 : R) n = X ^ n
  | 0 => by
    simp only [dickson_zero, pow_zeroₓ]
    norm_num
  | 1 => by
    simp only [dickson_one, pow_oneₓ]
  | n + 2 => by
    simp only [dickson_add_two, C_0, zero_mul, sub_zero]
    rw [dickson_two_zero, pow_addₓ X (n + 1) 1, mul_comm, pow_oneₓ]

section Dickson

/-!

### A Lambda structure on `polynomial ℤ`

Mathlib doesn't currently know what a Lambda ring is.
But once it does, we can endow `polynomial ℤ` with a Lambda structure
in terms of the `dickson 1 1` polynomials defined below.
There is exactly one other Lambda structure on `polynomial ℤ` in terms of binomial polynomials.

-/


variable {R}

theorem dickson_one_one_eval_add_inv (x y : R) (h : x * y = 1) : ∀ n, (dickson 1 (1 : R) n).eval (x + y) = x ^ n + y ^ n
  | 0 => by
    simp only [bit0, eval_one, eval_add, pow_zeroₓ, dickson_zero]
    norm_num
  | 1 => by
    simp only [eval_X, dickson_one, pow_oneₓ]
  | n + 2 => by
    simp only [eval_sub, eval_mul, dickson_one_one_eval_add_inv, eval_X, dickson_add_two, C_1, eval_one]
    conv_lhs => simp only [pow_succₓ, add_mulₓ, mul_addₓ, h, ← mul_assoc, mul_comm y x, one_mulₓ]
    ring_exp

variable (R)

theorem dickson_one_one_eq_chebyshev_T [Invertible (2 : R)] :
    ∀ n, dickson 1 (1 : R) n = 2 * (Chebyshev.t R n).comp (c (⅟ 2) * X)
  | 0 => by
    simp only [chebyshev.T_zero, mul_oneₓ, one_comp, dickson_zero]
    norm_num
  | 1 => by
    rw [dickson_one, chebyshev.T_one, X_comp, ← mul_assoc, ← C_1, ← C_bit0, ← C_mul, mul_inv_of_self, C_1, one_mulₓ]
  | n + 2 => by
    simp only [dickson_add_two, chebyshev.T_add_two, dickson_one_one_eq_chebyshev_T (n + 1),
      dickson_one_one_eq_chebyshev_T n, sub_comp, mul_comp, add_comp, X_comp, bit0_comp, one_comp]
    simp only [← C_1, ← C_bit0, ← mul_assoc, ← C_mul, mul_inv_of_self]
    rw [C_1, one_mulₓ]
    ring

theorem chebyshev_T_eq_dickson_one_one [Invertible (2 : R)] (n : ℕ) :
    Chebyshev.t R n = c (⅟ 2) * (dickson 1 1 n).comp (2 * X) := by
  rw [dickson_one_one_eq_chebyshev_T]
  simp only [comp_assoc, mul_comp, C_comp, X_comp, ← mul_assoc, ← C_1, ← C_bit0, ← C_mul]
  rw [inv_of_mul_self, C_1, one_mulₓ, one_mulₓ, comp_X]

/-- The `(m * n)`-th Dickson polynomial of the first kind is the composition of the `m`-th and
`n`-th. -/
theorem dickson_one_one_mul (m n : ℕ) : dickson 1 (1 : R) (m * n) = (dickson 1 1 m).comp (dickson 1 1 n) := by
  have h : (1 : R) = Int.castRingHom R 1
  simp only [eq_int_cast, Int.cast_oneₓ]
  rw [h]
  simp only [← map_dickson (Int.castRingHom R), ← map_comp]
  congr 1
  apply map_injective (Int.castRingHom ℚ) Int.cast_injective
  simp only [map_dickson, map_comp, eq_int_cast, Int.cast_oneₓ, dickson_one_one_eq_chebyshev_T, chebyshev.T_mul,
    two_mul, ← add_comp]
  simp only [← two_mul, ← comp_assoc]
  apply eval₂_congr rfl rfl
  rw [comp_assoc]
  apply eval₂_congr rfl _ rfl
  rw [mul_comp, C_comp, X_comp, ← mul_assoc, ← C_1, ← C_bit0, ← C_mul, inv_of_mul_self, C_1, one_mulₓ]

theorem dickson_one_one_comp_comm (m n : ℕ) :
    (dickson 1 (1 : R) m).comp (dickson 1 1 n) = (dickson 1 1 n).comp (dickson 1 1 m) := by
  rw [← dickson_one_one_mul, mul_comm, dickson_one_one_mul]

theorem dickson_one_one_zmod_p (p : ℕ) [Fact p.Prime] : dickson 1 (1 : Zmod p) p = X ^ p := by
  -- Recall that `dickson_eval_add_inv` characterises `dickson 1 1 p`
  -- as a polynomial that maps `x + x⁻¹` to `x ^ p + (x⁻¹) ^ p`.
  -- Since `X ^ p` also satisfies this property in characteristic `p`,
  -- we can use a variant on `polynomial.funext` to conclude that these polynomials are equal.
  -- For this argument, we need an arbitrary infinite field of characteristic `p`.
  obtain ⟨K, _, _, H⟩ : ∃ (K : Type)(_ : Field K), ∃ _ : CharP K p, Infinite K := by
    let K := FractionRing (Polynomial (Zmod p))
    let f : Zmod p →+* K := (algebraMap _ (FractionRing _)).comp C
    have : CharP K p := by
      rw [← f.char_p_iff_char_p]
      infer_instance
    haveI : Infinite K :=
      Infinite.of_injective (algebraMap (Polynomial (Zmod p)) (FractionRing (Polynomial (Zmod p))))
        (IsFractionRing.injective _ _)
    refine' ⟨K, _, _, _⟩ <;> infer_instance
  skip
  apply map_injective (Zmod.castHom (dvd_refl p) K) (RingHom.injective _)
  rw [map_dickson, Polynomial.map_pow, map_X]
  apply eq_of_infinite_eval_eq
  -- The two polynomials agree on all `x` of the form `x = y + y⁻¹`.
  apply @Set.Infinite.mono _ { x : K | ∃ y, x = y + y⁻¹ ∧ y ≠ 0 }
  · rintro _ ⟨x, rfl, hx⟩
    simp only [eval_X, eval_pow, Set.mem_set_of_eq, @add_pow_char K _ p,
      dickson_one_one_eval_add_inv _ _ (mul_inv_cancel hx), inv_pow, Zmod.cast_hom_apply, Zmod.cast_one']
    
  -- Now we need to show that the set of such `x` is infinite.
  -- If the set is finite, then we will show that `K` is also finite.
  · intro h
    rw [← Set.infinite_univ_iff] at H
    apply H
    -- To each `x` of the form `x = y + y⁻¹`
    -- we `bind` the set of `y` that solve the equation `x = y + y⁻¹`.
    -- For every `x`, that set is finite (since it is governed by a quadratic equation).
    -- For the moment, we claim that all these sets together cover `K`.
    suffices (Set.Univ : Set K) = { x : K | ∃ y : K, x = y + y⁻¹ ∧ y ≠ 0 } >>= fun x => { y | x = y + y⁻¹ ∨ y = 0 } by
      rw [this]
      clear this
      refine' h.bUnion fun x hx => _
      -- The following quadratic polynomial has as solutions the `y` for which `x = y + y⁻¹`.
      let φ : K[X] := X ^ 2 - C x * X + 1
      have hφ : φ ≠ 0 := by
        intro H
        have : φ.eval 0 = 0 := by
          rw [H, eval_zero]
        simpa [eval_X, eval_one, eval_pow, eval_sub, sub_zero, eval_add, eval_mul, mul_zero, sq, zero_addₓ, one_ne_zero]
      classical
      convert (φ.roots ∪ {0}).toFinset.finite_to_set using 1
      ext1 y
      simp only [Multiset.mem_to_finset, Set.mem_set_of_eq, Finset.mem_coe, Multiset.mem_union, mem_roots hφ, is_root,
        eval_add, eval_sub, eval_pow, eval_mul, eval_X, eval_C, eval_one, Multiset.mem_singleton]
      by_cases' hy : y = 0
      · simp only [hy, eq_self_iff_true, or_trueₓ]
        
      apply or_congr _ Iff.rfl
      rw [← mul_left_inj' hy, eq_comm, ← sub_eq_zero, add_mulₓ, inv_mul_cancel hy]
      apply eq_iff_eq_cancel_right.mpr
      ring
    -- Finally, we prove the claim that our finite union of finite sets covers all of `K`.
    · apply (Set.eq_univ_of_forall _).symm
      intro x
      simp only [exists_prop, Set.mem_Union, Set.bind_def, Ne.def, Set.mem_set_of_eq]
      by_cases' hx : x = 0
      · simp only [hx, and_trueₓ, eq_self_iff_true, inv_zero, or_trueₓ]
        exact ⟨_, 1, rfl, one_ne_zero⟩
        
      · simp only [hx, or_falseₓ, exists_eq_right]
        exact ⟨_, rfl, hx⟩
        
      
    

theorem dickson_one_one_char_p (p : ℕ) [Fact p.Prime] [CharP R p] : dickson 1 (1 : R) p = X ^ p := by
  have h : (1 : R) = Zmod.castHom (dvd_refl p) R 1
  simp only [Zmod.cast_hom_apply, Zmod.cast_one']
  rw [h, ← map_dickson (Zmod.castHom (dvd_refl p) R), dickson_one_one_zmod_p, Polynomial.map_pow, map_X]

end Dickson

end Polynomial

