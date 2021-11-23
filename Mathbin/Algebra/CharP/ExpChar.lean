import Mathbin.Algebra.CharP.Basic 
import Mathbin.Algebra.CharZero 
import Mathbin.Data.Nat.Prime

/-!
# Exponential characteristic

This file defines the exponential characteristic and establishes a few basic results relating
it to the (ordinary characteristic).
The definition is stated for a semiring, but the actual results are for nontrivial rings
(as far as exponential characteristic one is concerned), respectively a ring without zero-divisors
(for prime characteristic).

## Main results
- `exp_char`: the definition of exponential characteristic
- `exp_char_is_prime_or_one`: the exponential characteristic is a prime or one
- `char_eq_exp_char_iff`: the characteristic equals the exponential characteristic iff the
  characteristic is prime

## Tags
exponential characteristic, characteristic
-/


universe u

variable(R : Type u)

section Semiringₓ

variable[Semiringₓ R]

/-- The definition of the exponential characteristic of a semiring. -/
class inductive ExpChar (R : Type u) [Semiringₓ R] : ℕ → Prop
  | zero [CharZero R] : ExpChar 1
  | prime {q : ℕ} (hprime : q.prime) [hchar : CharP R q] : ExpChar q

/-- The exponential characteristic is one if the characteristic is zero. -/
theorem exp_char_one_of_char_zero (q : ℕ) [hp : CharP R 0] [hq : ExpChar R q] : q = 1 :=
  by 
    cases' hq with q hq_one hq_prime
    ·
      rfl
    ·
      exact False.elim (lt_irreflₓ _ ((hp.eq R hq_hchar).symm ▸ hq_prime : (0 : ℕ).Prime).Pos)

/-- The characteristic equals the exponential characteristic iff the former is prime. -/
theorem char_eq_exp_char_iff (p q : ℕ) [hp : CharP R p] [hq : ExpChar R q] : p = q ↔ p.prime :=
  by 
    cases' hq with q hq_one hq_prime
    ·
      split 
      ·
        (
          rintro rfl)
        exact False.elim (one_ne_zero (hp.eq R (CharP.of_char_zero R)))
      ·
        intro pprime 
        rw [(CharP.eq R hp inferInstance : p = 0)] at pprime 
        exact False.elim (Nat.not_prime_zero pprime)
    ·
      split 
      ·
        intro hpq 
        rw [hpq]
        exact hq_prime
      ·
        intro 
        exact CharP.eq R hp hq_hchar

section Nontrivial

variable[Nontrivial R]

/-- The exponential characteristic is one if the characteristic is zero. -/
theorem char_zero_of_exp_char_one (p : ℕ) [hp : CharP R p] [hq : ExpChar R 1] : p = 0 :=
  by 
    cases' hq
    ·
      exact CharP.eq R hp inferInstance
    ·
      exact False.elim (CharP.char_ne_one R 1 rfl)

/-- The exponential characteristic is one if the characteristic is zero. -/
instance (priority := 100)char_zero_of_exp_char_one' [hq : ExpChar R 1] : CharZero R :=
  by 
    cases' hq
    ·
      assumption
    ·
      exact False.elim (CharP.char_ne_one R 1 rfl)

/-- The exponential characteristic is one iff the characteristic is zero. -/
theorem exp_char_one_iff_char_zero (p q : ℕ) [CharP R p] [ExpChar R q] : q = 1 ↔ p = 0 :=
  by 
    split 
    ·
      (
        rintro rfl)
      exact char_zero_of_exp_char_one R p
    ·
      (
        rintro rfl)
      exact exp_char_one_of_char_zero R q

section NoZeroDivisors

variable[NoZeroDivisors R]

/-- A helper lemma: the characteristic is prime if it is non-zero. -/
theorem char_prime_of_ne_zero {p : ℕ} [hp : CharP R p] (p_ne_zero : p ≠ 0) : Nat.Prime p :=
  by 
    cases' CharP.char_is_prime_or_zero R p with h h
    ·
      exact h
    ·
      contradiction

-- error in Algebra.CharP.ExpChar: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- The exponential characteristic is a prime number or one. -/
theorem exp_char_is_prime_or_one (q : exprℕ()) [hq : exp_char R q] : «expr ∨ »(nat.prime q, «expr = »(q, 1)) :=
«expr $ »(or_iff_not_imp_right.mpr, λ h, begin
   casesI [expr char_p.exists R] ["with", ident p, ident hp],
   have [ident p_ne_zero] [":", expr «expr ≠ »(p, 0)] [],
   { intro [ident p_zero],
     haveI [] [":", expr char_p R 0] [],
     { rwa ["<-", expr p_zero] [] },
     have [] [":", expr «expr = »(q, 1)] [":=", expr exp_char_one_of_char_zero R q],
     contradiction },
   have [ident p_eq_q] [":", expr «expr = »(p, q)] [":=", expr (char_eq_exp_char_iff R p q).mpr (char_prime_of_ne_zero R p_ne_zero)],
   cases [expr char_p.char_is_prime_or_zero R p] ["with", ident pprime],
   { rwa [expr p_eq_q] ["at", ident pprime] },
   { contradiction }
 end)

end NoZeroDivisors

end Nontrivial

end Semiringₓ

