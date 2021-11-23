import Mathbin.Data.Nat.Choose.Basic 
import Mathbin.Data.Nat.Factorial.Cast

/-!
# Cast of binomial coefficients

This file allows calculating the binomial coefficient `a.choose b` as an element of a division ring
of characteristic `0`.
-/


open_locale Nat

variable(K : Type _)[DivisionRing K][CharZero K]

namespace Nat

-- error in Data.Nat.Choose.Cast: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem cast_choose
{a b : exprℕ()}
(h : «expr ≤ »(a, b)) : «expr = »((b.choose a : K), «expr / »(«expr !»(b), «expr * »(«expr !»(a), «expr !»(«expr - »(b, a))))) :=
begin
  have [] [":", expr ∀
   {n : exprℕ()}, «expr ≠ »((«expr !»(n) : K), 0)] [":=", expr λ n, nat.cast_ne_zero.2 (factorial_ne_zero _)],
  rw [expr eq_div_iff_mul_eq (mul_ne_zero this this)] [],
  rw_mod_cast ["[", "<-", expr mul_assoc, ",", expr choose_mul_factorial_mul_factorial h, "]"] []
end

theorem cast_add_choose {a b : ℕ} : ((a+b).choose a : K) = (a+b)! / a !*b ! :=
  by 
    rw [cast_choose K (le_add_right le_rfl), add_tsub_cancel_left]

theorem cast_choose_eq_pochhammer_div (a b : ℕ) : (a.choose b : K) = (pochhammer K b).eval (a - (b - 1) : ℕ) / b ! :=
  by 
    rw [eq_div_iff_mul_eq (Nat.cast_ne_zero.2 b.factorial_ne_zero : (b ! : K) ≠ 0), ←Nat.cast_mul, mul_commₓ,
      ←Nat.desc_factorial_eq_factorial_mul_choose, ←cast_desc_factorial]

theorem cast_choose_two (a : ℕ) : (a.choose 2 : K) = (a*a - 1) / 2 :=
  by 
    rw [←cast_desc_factorial_two, desc_factorial_eq_factorial_mul_choose, factorial_two, mul_commₓ, cast_mul, cast_two,
      eq_div_iff_mul_eq (two_ne_zero' : (2 : K) ≠ 0)]

end Nat

