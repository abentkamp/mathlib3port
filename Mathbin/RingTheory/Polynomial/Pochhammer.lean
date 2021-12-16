import Mathbin.Tactic.Abel 
import Mathbin.Data.Polynomial.Eval

/-!
# The Pochhammer polynomials

We define and prove some basic relations about
`pochhammer S n : polynomial S := X * (X + 1) * ... * (X + n - 1)`
which is also known as the rising factorial. A version of this definition
that is focused on `nat` can be found in `data.nat.factorial` as `asc_factorial`.

## Implementation

As with many other families of polynomials, even though the coefficients are always in `ℕ`,
we define the polynomial with coefficients in any `[semiring S]`.

## TODO

There is lots more in this direction:
* q-factorials, q-binomials, q-Pochhammer.
-/


universe u v

open Polynomial

section Semiringₓ

variable (S : Type u) [Semiringₓ S]

/--
`pochhammer S n` is the polynomial `X * (X+1) * ... * (X + n - 1)`,
with coefficients in the semiring `S`.
-/
noncomputable def pochhammer : ℕ → Polynomial S
| 0 => 1
| n+1 => X*(pochhammer n).comp (X+1)

@[simp]
theorem pochhammer_zero : pochhammer S 0 = 1 :=
  rfl

@[simp]
theorem pochhammer_one : pochhammer S 1 = X :=
  by 
    simp [pochhammer]

theorem pochhammer_succ_left (n : ℕ) : pochhammer S (n+1) = X*(pochhammer S n).comp (X+1) :=
  by 
    rw [pochhammer]

section 

variable {S} {T : Type v} [Semiringₓ T]

@[simp]
theorem pochhammer_map (f : S →+* T) (n : ℕ) : (pochhammer S n).map f = pochhammer T n :=
  by 
    induction' n with n ih
    ·
      simp 
    ·
      simp [ih, pochhammer_succ_left, map_comp]

end 

@[simp, normCast]
theorem pochhammer_eval_cast (n k : ℕ) : ((pochhammer ℕ n).eval k : S) = (pochhammer S n).eval k :=
  by 
    rw [←pochhammer_map (algebraMap ℕ S), eval_map, ←(algebraMap ℕ S).eq_nat_cast, eval₂_at_nat_cast, Nat.cast_id,
      RingHom.eq_nat_cast]

theorem pochhammer_eval_zero {n : ℕ} : (pochhammer S n).eval 0 = if n = 0 then 1 else 0 :=
  by 
    cases n
    ·
      simp 
    ·
      simp [X_mul, Nat.succ_ne_zero, pochhammer_succ_left]

theorem pochhammer_zero_eval_zero : (pochhammer S 0).eval 0 = 1 :=
  by 
    simp 

@[simp]
theorem pochhammer_ne_zero_eval_zero {n : ℕ} (h : n ≠ 0) : (pochhammer S n).eval 0 = 0 :=
  by 
    simp [pochhammer_eval_zero, h]

theorem pochhammer_succ_right (n : ℕ) : pochhammer S (n+1) = pochhammer S n*X+n :=
  by 
    suffices h : pochhammer ℕ (n+1) = pochhammer ℕ n*X+n
    ·
      applyFun Polynomial.map (algebraMap ℕ S)  at h 
      simpa only [pochhammer_map, Polynomial.map_mul, Polynomial.map_add, map_X, map_nat_cast] using h 
    induction' n with n ih
    ·
      simp 
    ·
      convLHS =>
        rw [pochhammer_succ_left, ih, mul_comp, ←mul_assocₓ, ←pochhammer_succ_left, add_comp, X_comp, nat_cast_comp,
          add_assocₓ, add_commₓ (1 : Polynomial ℕ)]
      rfl

theorem Polynomial.mul_X_add_nat_cast_comp {p q : Polynomial S} {n : ℕ} : (p*X+n).comp q = p.comp q*q+n :=
  by 
    rw [mul_addₓ, add_comp, mul_X_comp, ←Nat.cast_comm, nat_cast_mul_comp, Nat.cast_comm, mul_addₓ]

theorem pochhammer_mul (n m : ℕ) : (pochhammer S n*(pochhammer S m).comp (X+n)) = pochhammer S (n+m) :=
  by 
    induction' m with m ih
    ·
      simp 
    ·
      rw [pochhammer_succ_right, Polynomial.mul_X_add_nat_cast_comp, ←mul_assocₓ, ih, Nat.succ_eq_add_one, ←add_assocₓ,
        pochhammer_succ_right, Nat.cast_add, add_assocₓ]

theorem pochhammer_nat_eq_asc_factorial (n : ℕ) : ∀ k, (pochhammer ℕ k).eval (n+1) = n.asc_factorial k
| 0 =>
  by 
    erw [eval_one] <;> rfl
| t+1 =>
  by 
    rw [pochhammer_succ_right, eval_mul, pochhammer_nat_eq_asc_factorial t]
    suffices  : (n.asc_factorial t*(n+1)+t) = n.asc_factorial (t+1)
    ·
      simpa 
    rw [Nat.asc_factorial_succ, add_right_commₓ, mul_commₓ]

theorem pochhammer_nat_eq_desc_factorial (a b : ℕ) : (pochhammer ℕ b).eval a = ((a+b) - 1).descFactorial b :=
  by 
    cases b
    ·
      rw [Nat.desc_factorial_zero, pochhammer_zero, Polynomial.eval_one]
    rw [Nat.add_succ, Nat.succ_sub_succ, tsub_zero]
    cases a
    ·
      rw [pochhammer_ne_zero_eval_zero _ b.succ_ne_zero, zero_addₓ, Nat.desc_factorial_of_lt b.lt_succ_self]
    ·
      rw [Nat.succ_add, ←Nat.add_succ, Nat.add_desc_factorial_eq_asc_factorial, pochhammer_nat_eq_asc_factorial]

end Semiringₓ

section CommSemiringₓ

variable {S : Type _} [CommSemiringₓ S]

theorem pochhammer_succ_eval (n : ℕ) (k : S) : (pochhammer S n.succ).eval k = (pochhammer S n).eval k*k+↑n :=
  by 
    rw [pochhammer_succ_right, Polynomial.eval_mul, Polynomial.eval_add, Polynomial.eval_X, Polynomial.eval_nat_cast]

end CommSemiringₓ

section OrderedSemiring

variable {S : Type _} [OrderedSemiring S] [Nontrivial S]

theorem pochhammer_pos (n : ℕ) (s : S) (h : 0 < s) : 0 < (pochhammer S n).eval s :=
  by 
    induction' n with n ih
    ·
      simp only [Nat.nat_zero_eq_zero, pochhammer_zero, eval_one]
      exact zero_lt_one
    ·
      rw [pochhammer_succ_right, mul_addₓ, eval_add, ←Nat.cast_comm, eval_nat_cast_mul, eval_mul_X, Nat.cast_comm,
        ←mul_addₓ]
      exact mul_pos ih (lt_of_lt_of_leₓ h ((le_add_iff_nonneg_right _).mpr (Nat.cast_nonneg n)))

end OrderedSemiring

section Factorial

open_locale Nat

variable (S : Type _) [Semiringₓ S] (r n : ℕ)

@[simp]
theorem pochhammer_eval_one (S : Type _) [Semiringₓ S] (n : ℕ) : (pochhammer S n).eval (1 : S) = (n ! : S) :=
  by 
    rwModCast [pochhammer_nat_eq_asc_factorial, Nat.zero_asc_factorial]

theorem factorial_mul_pochhammer (S : Type _) [Semiringₓ S] (r n : ℕ) :
  ((r ! : S)*(pochhammer S n).eval (r+1)) = (r+n)! :=
  by 
    rwModCast [pochhammer_nat_eq_asc_factorial, Nat.factorial_mul_asc_factorial]

theorem pochhammer_nat_eval_succ (r : ℕ) : ∀ n : ℕ, (n*(pochhammer ℕ r).eval (n+1)) = (n+r)*(pochhammer ℕ r).eval n
| 0 =>
  by 
    byCases' h : r = 0
    ·
      simp only [h, zero_mul, zero_addₓ]
    ·
      simp only [pochhammer_eval_zero, zero_mul, if_neg h, mul_zero]
| k+1 =>
  by 
    simp only [pochhammer_nat_eq_asc_factorial, Nat.succ_asc_factorial, add_right_commₓ]

theorem pochhammer_eval_succ (r n : ℕ) : ((n : S)*(pochhammer S r).eval (n+1 : S)) = (n+r)*(pochhammer S r).eval n :=
  by 
    exactModCast congr_argₓ Nat.cast (pochhammer_nat_eval_succ r n)

end Factorial

