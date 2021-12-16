import Mathbin.Algebra.Group.Defs 
import Mathbin.Logic.Nontrivial

/-!
# Typeclasses for groups with an adjoined zero element

This file provides just the typeclass definitions, and the projection lemmas that expose their
members.

## Main definitions

* `group_with_zero`
* `comm_group_with_zero`
-/


universe u

variable {G₀ : Type u} {M₀ M₀' G₀' : Type _}

section 

/-- Typeclass for expressing that a type `M₀` with multiplication and a zero satisfies
`0 * a = 0` and `a * 0 = 0` for all `a : M₀`. -/
@[protectProj, ancestor Mul HasZero]
class MulZeroClass (M₀ : Type _) extends Mul M₀, HasZero M₀ where 
  zero_mul : ∀ a : M₀, (0*a) = 0
  mul_zero : ∀ a : M₀, (a*0) = 0

section MulZeroClass

variable [MulZeroClass M₀] {a b : M₀}

@[ematch, simp]
theorem zero_mul (a : M₀) : (0*a) = 0 :=
  MulZeroClass.zero_mul a

@[ematch, simp]
theorem mul_zero (a : M₀) : (a*0) = 0 :=
  MulZeroClass.mul_zero a

end MulZeroClass

/-- Predicate typeclass for expressing that `a * b = 0` implies `a = 0` or `b = 0`
for all `a` and `b` of type `G₀`. -/
class NoZeroDivisors (M₀ : Type _) [Mul M₀] [HasZero M₀] : Prop where 
  eq_zero_or_eq_zero_of_mul_eq_zero : ∀ {a b : M₀}, (a*b) = 0 → a = 0 ∨ b = 0

export NoZeroDivisors(eq_zero_or_eq_zero_of_mul_eq_zero)

/-- A type `S₀` is a "semigroup with zero” if it is a semigroup with zero element, and `0` is left
and right absorbing. -/
@[protectProj]
class SemigroupWithZero (S₀ : Type _) extends Semigroupₓ S₀, MulZeroClass S₀

/-- A typeclass for non-associative monoids with zero elements. -/
@[protectProj]
class MulZeroOneClass (M₀ : Type _) extends MulOneClass M₀, MulZeroClass M₀

/-- A type `M₀` is a “monoid with zero” if it is a monoid with zero element, and `0` is left
and right absorbing. -/
@[protectProj]
class MonoidWithZeroₓ (M₀ : Type _) extends Monoidₓ M₀, MulZeroOneClass M₀

instance (priority := 100) MonoidWithZeroₓ.toSemigroupWithZero (M₀ : Type _) [MonoidWithZeroₓ M₀] :
  SemigroupWithZero M₀ :=
  { ‹MonoidWithZeroₓ M₀› with  }

/-- A type `M` is a `cancel_monoid_with_zero` if it is a monoid with zero element, `0` is left
and right absorbing, and left/right multiplication by a non-zero element is injective. -/
@[protectProj]
class CancelMonoidWithZero (M₀ : Type _) extends MonoidWithZeroₓ M₀ where 
  mul_left_cancel_of_ne_zero : ∀ {a b c : M₀}, a ≠ 0 → ((a*b) = a*c) → b = c 
  mul_right_cancel_of_ne_zero : ∀ {a b c : M₀}, b ≠ 0 → ((a*b) = c*b) → a = c

section CancelMonoidWithZero

variable [CancelMonoidWithZero M₀] {a b c : M₀}

theorem mul_left_cancel₀ (ha : a ≠ 0) (h : (a*b) = a*c) : b = c :=
  CancelMonoidWithZero.mul_left_cancel_of_ne_zero ha h

theorem mul_right_cancel₀ (hb : b ≠ 0) (h : (a*b) = c*b) : a = c :=
  CancelMonoidWithZero.mul_right_cancel_of_ne_zero hb h

theorem mul_right_injective₀ (ha : a ≠ 0) : Function.Injective ((·*·) a) :=
  fun b c => mul_left_cancel₀ ha

theorem mul_left_injective₀ (hb : b ≠ 0) : Function.Injective fun a => a*b :=
  fun a c => mul_right_cancel₀ hb

end CancelMonoidWithZero

/-- A type `M` is a commutative “monoid with zero” if it is a commutative monoid with zero
element, and `0` is left and right absorbing. -/
@[protectProj]
class CommMonoidWithZero (M₀ : Type _) extends CommMonoidₓ M₀, MonoidWithZeroₓ M₀

/-- A type `M` is a `cancel_comm_monoid_with_zero` if it is a commutative monoid with zero element,
 `0` is left and right absorbing,
  and left/right multiplication by a non-zero element is injective. -/
@[protectProj]
class CancelCommMonoidWithZero (M₀ : Type _) extends CommMonoidWithZero M₀, CancelMonoidWithZero M₀

/-- A type `G₀` is a “group with zero” if it is a monoid with zero element (distinct from `1`)
such that every nonzero element is invertible.
The type is required to come with an “inverse” function, and the inverse of `0` must be `0`.

Examples include division rings and the ordered monoids that are the
target of valuations in general valuation theory.-/
class GroupWithZeroₓ (G₀ : Type u) extends MonoidWithZeroₓ G₀, DivInvMonoidₓ G₀, Nontrivial G₀ where 
  inv_zero : (0 : G₀)⁻¹ = 0
  mul_inv_cancel : ∀ a : G₀, a ≠ 0 → (a*a⁻¹) = 1

section GroupWithZeroₓ

variable [GroupWithZeroₓ G₀]

@[simp]
theorem inv_zero : (0 : G₀)⁻¹ = 0 :=
  GroupWithZeroₓ.inv_zero

@[simp]
theorem mul_inv_cancel {a : G₀} (h : a ≠ 0) : (a*a⁻¹) = 1 :=
  GroupWithZeroₓ.mul_inv_cancel a h

end GroupWithZeroₓ

/-- A type `G₀` is a commutative “group with zero”
if it is a commutative monoid with zero element (distinct from `1`)
such that every nonzero element is invertible.
The type is required to come with an “inverse” function, and the inverse of `0` must be `0`. -/
class CommGroupWithZero (G₀ : Type _) extends CommMonoidWithZero G₀, GroupWithZeroₓ G₀

end 

