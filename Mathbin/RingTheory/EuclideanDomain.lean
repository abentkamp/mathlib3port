import Mathbin.Algebra.GcdMonoid.Basic 
import Mathbin.RingTheory.Coprime.Basic 
import Mathbin.RingTheory.Ideal.Basic 
import Mathbin.RingTheory.PrincipalIdealDomain

/-!
# Lemmas about Euclidean domains

Various about Euclidean domains are proved; all of them seem to be true
more generally for principal ideal domains, so these lemmas should
probably be reproved in more generality and this file perhaps removed?

## Tags

euclidean domain
-/


noncomputable section 

open_locale Classical

open EuclideanDomain Set Ideal

section GcdMonoid

variable {R : Type _} [EuclideanDomain R] [GcdMonoid R]

-- ././Mathport/Syntax/Translate/Tactic/Lean3.lean:98:4: warning: unsupported: rw with cfg: { occs := occurrences.pos «expr[ , ]»([1]) }
theorem left_div_gcd_ne_zero {p q : R} (hp : p ≠ 0) : p / GcdMonoid.gcd p q ≠ 0 :=
  by 
    obtain ⟨r, hr⟩ := GcdMonoid.gcd_dvd_left p q 
    obtain ⟨pq0, r0⟩ : GcdMonoid.gcd p q ≠ 0 ∧ r ≠ 0 := mul_ne_zero_iff.mp (hr ▸ hp)
    rw [hr, mul_commₓ, mul_div_cancel _ pq0]
    exact r0

-- ././Mathport/Syntax/Translate/Tactic/Lean3.lean:98:4: warning: unsupported: rw with cfg: { occs := occurrences.pos «expr[ , ]»([1]) }
theorem right_div_gcd_ne_zero {p q : R} (hq : q ≠ 0) : q / GcdMonoid.gcd p q ≠ 0 :=
  by 
    obtain ⟨r, hr⟩ := GcdMonoid.gcd_dvd_right p q 
    obtain ⟨pq0, r0⟩ : GcdMonoid.gcd p q ≠ 0 ∧ r ≠ 0 := mul_ne_zero_iff.mp (hr ▸ hq)
    rw [hr, mul_commₓ, mul_div_cancel _ pq0]
    exact r0

end GcdMonoid

namespace EuclideanDomain

/-- Create a `gcd_monoid` whose `gcd_monoid.gcd` matches `euclidean_domain.gcd`. -/
def GcdMonoid R [EuclideanDomain R] : GcdMonoid R :=
  { gcd := gcd, lcm := lcm, gcd_dvd_left := gcd_dvd_left, gcd_dvd_right := gcd_dvd_right,
    dvd_gcd := fun a b c => dvd_gcd,
    gcd_mul_lcm :=
      fun a b =>
        by 
          rw [EuclideanDomain.gcd_mul_lcm],
    lcm_zero_left := lcm_zero_left, lcm_zero_right := lcm_zero_right }

variable {α : Type _} [EuclideanDomain α] [DecidableEq α]

theorem span_gcd {α} [EuclideanDomain α] (x y : α) : span ({gcd x y} : Set α) = span ({x, y} : Set α) :=
  by 
    let this' := EuclideanDomain.gcdMonoid α 
    exact span_gcd x y

theorem gcd_is_unit_iff {α} [EuclideanDomain α] {x y : α} : IsUnit (gcd x y) ↔ IsCoprime x y :=
  by 
    let this' := EuclideanDomain.gcdMonoid α 
    exact gcd_is_unit_iff x y

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (z «expr ∈ » nonunits α)
theorem is_coprime_of_dvd {α} [EuclideanDomain α] {x y : α} (nonzero : ¬(x = 0 ∧ y = 0))
  (H : ∀ z _ : z ∈ Nonunits α, z ≠ 0 → z ∣ x → ¬z ∣ y) : IsCoprime x y :=
  by 
    let this' := EuclideanDomain.gcdMonoid α 
    exact is_coprime_of_dvd x y nonzero H

theorem dvd_or_coprime {α} [EuclideanDomain α] (x y : α) (h : Irreducible x) : x ∣ y ∨ IsCoprime x y :=
  by 
    let this' := EuclideanDomain.gcdMonoid α 
    exact dvd_or_coprime x y h

end EuclideanDomain

