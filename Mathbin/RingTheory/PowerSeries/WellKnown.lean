import Mathbin.RingTheory.PowerSeries.Basic 
import Mathbin.Data.Nat.Parity 
import Mathbin.Algebra.BigOperators.NatAntidiagonal

/-!
# Definition of well-known power series

In this file we define the following power series:

* `power_series.inv_units_sub`: given `u : units R`, this is the series for `1 / (u - x)`.
  It is given by `∑ n, x ^ n /ₚ u ^ (n + 1)`.

* `power_series.sin`, `power_series.cos`, `power_series.exp` : power series for sin, cosine, and
  exponential functions.
-/


namespace PowerSeries

section Ringₓ

variable {R S : Type _} [Ringₓ R] [Ringₓ S]

/-- The power series for `1 / (u - x)`. -/
def inv_units_sub (u : Units R) : PowerSeries R :=
  mk$ fun n => 1 /ₚ (u^n+1)

@[simp]
theorem coeff_inv_units_sub (u : Units R) (n : ℕ) : coeff R n (inv_units_sub u) = 1 /ₚ (u^n+1) :=
  coeff_mk _ _

@[simp]
theorem constant_coeff_inv_units_sub (u : Units R) : constant_coeff R (inv_units_sub u) = 1 /ₚ u :=
  by 
    rw [←coeff_zero_eq_constant_coeff_apply, coeff_inv_units_sub, zero_addₓ, pow_oneₓ]

@[simp]
theorem inv_units_sub_mul_X (u : Units R) : (inv_units_sub u*X) = (inv_units_sub u*C R u) - 1 :=
  by 
    ext (_ | n)
    ·
      simp 
    ·
      simp [n.succ_ne_zero, pow_succₓ]

@[simp]
theorem inv_units_sub_mul_sub (u : Units R) : (inv_units_sub u*C R u - X) = 1 :=
  by 
    simp [mul_sub, sub_sub_cancel]

theorem map_inv_units_sub (f : R →+* S) (u : Units R) :
  map f (inv_units_sub u) = inv_units_sub (Units.map (f : R →* S) u) :=
  by 
    ext 
    simp [←map_pow]

end Ringₓ

section Field

variable (A A' : Type _) [Ringₓ A] [Ringₓ A'] [Algebra ℚ A] [Algebra ℚ A']

open_locale Nat

/-- Power series for the exponential function at zero. -/
def exp : PowerSeries A :=
  mk$ fun n => algebraMap ℚ A (1 / n !)

/-- Power series for the sine function at zero. -/
def sin : PowerSeries A :=
  mk$ fun n => if Even n then 0 else algebraMap ℚ A ((-1^n / 2) / n !)

/-- Power series for the cosine function at zero. -/
def cos : PowerSeries A :=
  mk$ fun n => if Even n then algebraMap ℚ A ((-1^n / 2) / n !) else 0

variable {A A'} (n : ℕ) (f : A →+* A')

@[simp]
theorem coeff_exp : coeff A n (exp A) = algebraMap ℚ A (1 / n !) :=
  coeff_mk _ _

@[simp]
theorem constant_coeff_exp : constant_coeff A (exp A) = 1 :=
  by 
    rw [←coeff_zero_eq_constant_coeff_apply, coeff_exp]
    simp 

@[simp]
theorem map_exp : map (f : A →+* A') (exp A) = exp A' :=
  by 
    ext 
    simp 

@[simp]
theorem map_sin : map f (sin A) = sin A' :=
  by 
    ext 
    simp [sin, apply_ite f]

@[simp]
theorem map_cos : map f (cos A) = cos A' :=
  by 
    ext 
    simp [cos, apply_ite f]

end Field

open RingHom

open Finset Nat

variable {A : Type _} [CommRingₓ A]

/-- Shows that $e^{aX} * e^{bX} = e^{(a + b)X}$ -/
theorem exp_mul_exp_eq_exp_add [Algebra ℚ A] (a b : A) :
  (rescale a (exp A)*rescale b (exp A)) = rescale (a+b) (exp A) :=
  by 
    ext 
    simp only [coeff_mul, exp, rescale, coeff_mk, coe_mk, factorial, nat.sum_antidiagonal_eq_sum_range_succ_mk, add_pow,
      sum_mul]
    apply sum_congr rfl 
    rintro x hx 
    suffices  :
      (((a^x)*b^n - x)*algebraMap ℚ A (1 / ↑x.factorial)*algebraMap ℚ A (1 / ↑(n - x).factorial)) =
        ((a^x)*b^n - x)*(↑n.choose x)*(algebraMap ℚ A) (1 / ↑n.factorial)
    ·
      convert this using 1 <;> ring 
    congr 1
    rw [←map_nat_cast (algebraMap ℚ A) (n.choose x), ←map_mul, ←map_mul]
    refine' RingHom.congr_arg _ _ 
    rw [mul_one_div (↑n.choose x) _, one_div_mul_one_div]
    symm 
    rw [div_eq_iff, div_mul_eq_mul_div, one_mulₓ, choose_eq_factorial_div_factorial]
    normCast 
    rw [cast_dvd_char_zero]
    ·
      apply factorial_mul_factorial_dvd_factorial (mem_range_succ_iff.1 hx)
    ·
      apply mem_range_succ_iff.1 hx
    ·
      rintro h 
      apply factorial_ne_zero n 
      rw [cast_eq_zero.1 h]

/-- Shows that $e^{x} * e^{-x} = 1$ -/
theorem exp_mul_exp_neg_eq_one [Algebra ℚ A] : (exp A*eval_neg_hom (exp A)) = 1 :=
  by 
    convert exp_mul_exp_eq_exp_add (1 : A) (-1) <;> simp 

/-- Shows that $(e^{X})^k = e^{kX}$. -/
theorem exp_pow_eq_rescale_exp [Algebra ℚ A] (k : ℕ) : (exp A^k) = rescale (k : A) (exp A) :=
  by 
    induction' k with k h
    ·
      simp only [rescale_zero, constant_coeff_exp, Function.comp_app, map_one, cast_zero, pow_zeroₓ, coe_comp]
    simpa only [succ_eq_add_one, cast_add, ←exp_mul_exp_eq_exp_add (k : A), ←h, cast_one, id_apply, rescale_one] using
      pow_succ'ₓ (exp A) k

/-- Shows that
$\sum_{k = 0}^{n - 1} (e^{X})^k = \sum_{p = 0}^{\infty} \sum_{k = 0}^{n - 1} \frac{k^p}{p!}X^p$. -/
theorem exp_pow_sum [Algebra ℚ A] (n : ℕ) :
  ((Finset.range n).Sum fun k => exp A^k) =
    PowerSeries.mk fun p => (Finset.range n).Sum fun k => (k^p)*algebraMap ℚ A (p.factorial⁻¹) :=
  by 
    simp only [exp_pow_eq_rescale_exp, rescale]
    ext 
    simp only [one_div, coeff_mk, coe_mk, coeff_exp, factorial, LinearMap.map_sum]

end PowerSeries

