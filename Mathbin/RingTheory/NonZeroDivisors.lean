import Mathbin.GroupTheory.Submonoid.Operations 
import Mathbin.GroupTheory.Submonoid.Membership

/-!
# Non-zero divisors

In this file we define the submonoid `non_zero_divisors` of a `monoid_with_zero`.

## Notations

This file declares the notation `R⁰` for the submonoid of non-zero-divisors of `R`,
in the locale `non_zero_divisors`. Use the statement `open_locale non_zero_divisors`
to access this notation in your own code.

-/


section nonZeroDivisors

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The submonoid of non-zero-divisors of a `monoid_with_zero` `R`. -/
  def
    nonZeroDivisors
    ( R : Type _ ) [ MonoidWithZeroₓ R ] : Submonoid R
    :=
      {
        Carrier := { x | ∀ z , z * x = 0 → z = 0 } ,
          one_mem' := fun z hz => by rwa [ mul_oneₓ ] at hz ,
          mul_mem' := fun x₁ x₂ hx₁ hx₂ z hz => have : z * x₁ * x₂ = 0 := by rwa [ mul_assocₓ ] hx₁ z $ hx₂ z * x₁ this
        }

localized [nonZeroDivisors] notation:9000 R "⁰" => nonZeroDivisors R

variable {M M' M₁ : Type _} [MonoidWithZeroₓ M] [MonoidWithZeroₓ M'] [CommMonoidWithZero M₁]

theorem nonZeroDivisors.ne_zero [Nontrivial M] {x} (hx : x ∈ M⁰) : x ≠ 0 :=
  fun h => one_ne_zero (hx _$ (one_mulₓ _).trans h)

theorem nonZeroDivisors.coe_ne_zero [Nontrivial M] (x : M⁰) : (x : M) ≠ 0 :=
  nonZeroDivisors.ne_zero x.2

theorem mul_mem_non_zero_divisors {a b : M₁} : (a*b) ∈ M₁⁰ ↔ a ∈ M₁⁰ ∧ b ∈ M₁⁰ :=
  by 
    constructor
    ·
      intro h 
      constructor <;> intro x h' <;> apply h
      ·
        rw [←mul_assocₓ, h', zero_mul]
      ·
        rw [mul_commₓ a b, ←mul_assocₓ, h', zero_mul]
    ·
      rintro ⟨ha, hb⟩ x hx 
      apply ha 
      apply hb 
      rw [mul_assocₓ, hx]

theorem eq_zero_of_ne_zero_of_mul_right_eq_zero [NoZeroDivisors M] {x y : M} (hnx : x ≠ 0) (hxy : (y*x) = 0) : y = 0 :=
  Or.resolve_right (eq_zero_or_eq_zero_of_mul_eq_zero hxy) hnx

theorem eq_zero_of_ne_zero_of_mul_left_eq_zero [NoZeroDivisors M] {x y : M} (hnx : x ≠ 0) (hxy : (x*y) = 0) : y = 0 :=
  Or.resolve_left (eq_zero_or_eq_zero_of_mul_eq_zero hxy) hnx

theorem mem_non_zero_divisors_iff_ne_zero [NoZeroDivisors M] [Nontrivial M] {x : M} : x ∈ M⁰ ↔ x ≠ 0 :=
  ⟨nonZeroDivisors.ne_zero, fun hnx z => eq_zero_of_ne_zero_of_mul_right_eq_zero hnx⟩

theorem MonoidWithZeroHom.map_ne_zero_of_mem_non_zero_divisors [Nontrivial M] (g : MonoidWithZeroHom M M')
  (hg : Function.Injective g) {x : M} (h : x ∈ M⁰) : g x ≠ 0 :=
  fun h0 => one_ne_zero (h 1 ((one_mulₓ x).symm ▸ hg (trans h0 g.map_zero.symm)))

theorem RingHom.map_ne_zero_of_mem_non_zero_divisors {R R' : Type _} [Semiringₓ R] [Semiringₓ R'] [Nontrivial R]
  (g : R →+* R') (hg : Function.Injective g) {x : R} (h : x ∈ R⁰) : g x ≠ 0 :=
  g.to_monoid_with_zero_hom.map_ne_zero_of_mem_non_zero_divisors hg h

theorem MonoidWithZeroHom.map_mem_non_zero_divisors [Nontrivial M] [NoZeroDivisors M'] (g : MonoidWithZeroHom M M')
  (hg : Function.Injective g) {x : M} (h : x ∈ M⁰) : g x ∈ M'⁰ :=
  fun z hz => eq_zero_of_ne_zero_of_mul_right_eq_zero (g.map_ne_zero_of_mem_non_zero_divisors hg h) hz

theorem RingHom.map_mem_non_zero_divisors {R R' : Type _} [Semiringₓ R] [Semiringₓ R'] [Nontrivial R]
  [NoZeroDivisors R'] (g : R →+* R') (hg : Function.Injective g) {x : R} (h : x ∈ R⁰) : g x ∈ R'⁰ :=
  g.to_monoid_with_zero_hom.map_mem_non_zero_divisors hg h

theorem le_non_zero_divisors_of_no_zero_divisors [NoZeroDivisors M] {S : Submonoid M} (hS : (0 : M) ∉ S) : S ≤ M⁰ :=
  fun x hx y hy =>
    Or.rec_on (eq_zero_or_eq_zero_of_mul_eq_zero hy) (fun h => h) fun h => absurd (h ▸ hx : (0 : M) ∈ S) hS

theorem powers_le_non_zero_divisors_of_no_zero_divisors [NoZeroDivisors M] {a : M} (ha : a ≠ 0) :
  Submonoid.powers a ≤ M⁰ :=
  le_non_zero_divisors_of_no_zero_divisors fun h => absurd (h.rec_on fun _ hn => pow_eq_zero hn) ha

theorem MonoidWithZeroHom.map_le_non_zero_divisors_of_injective [Nontrivial M] [NoZeroDivisors M']
  (f : MonoidWithZeroHom M M') (hf : Function.Injective f) {S : Submonoid M} (hS : S ≤ M⁰) : S.map (↑f) ≤ M'⁰ :=
  le_non_zero_divisors_of_no_zero_divisors
    fun h =>
      let ⟨x, hx, hx0⟩ := h 
      zero_ne_one (hS (hf (trans hx0 f.map_zero.symm) ▸ hx : 0 ∈ S) 1 (mul_zero 1)).symm

theorem RingHom.map_le_non_zero_divisors_of_injective {R R' : Type _} [Semiringₓ R] [Semiringₓ R'] [Nontrivial R]
  [NoZeroDivisors R'] (f : R →+* R') (hf : Function.Injective f) {S : Submonoid R} (hS : S ≤ R⁰) : S.map (↑f) ≤ R'⁰ :=
  f.to_monoid_with_zero_hom.map_le_non_zero_divisors_of_injective hf hS

theorem prod_zero_iff_exists_zero [NoZeroDivisors M₁] [Nontrivial M₁] {s : Multiset M₁} :
  s.prod = 0 ↔ ∃ (r : M₁)(hr : r ∈ s), r = 0 :=
  by 
    constructor 
    swap
    ·
      rintro ⟨r, hrs, rfl⟩
      exact Multiset.prod_eq_zero hrs 
    refine' Multiset.induction _ (fun a s ih => _) s
    ·
      intro habs 
      simpa using habs
    ·
      rw [Multiset.prod_cons]
      intro hprod 
      replace hprod := eq_zero_or_eq_zero_of_mul_eq_zero hprod 
      cases' hprod with ha
      ·
        exact ⟨a, Multiset.mem_cons_self a s, ha⟩
      ·
        apply (ih hprod).imp _ 
        rintro b ⟨hb₁, hb₂⟩
        exact ⟨Multiset.mem_cons_of_mem hb₁, hb₂⟩

end nonZeroDivisors

