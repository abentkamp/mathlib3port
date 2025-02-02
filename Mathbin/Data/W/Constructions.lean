/-
Copyright (c) 2015 Joseph Hua. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joseph Hua
-/
import Mathbin.Data.W.Basic

/-!
# Examples of W-types

We take the view of W types as inductive types.
Given `α : Type` and `β : α → Type`, the W type determined by this data, `W_type β`, is the
inductively with constructors from `α` and arities of each constructor `a : α` given by `β a`.

This file contains `nat` and `list` as examples of W types.

## Main results
* `W_type.equiv_nat`: the construction of the naturals as a W-type is equivalent
  to `nat`
* `W_type.equiv_list`: the construction of lists on a type `γ` as a W-type is equivalent to
  `list γ`
-/


universe u v

namespace WType

section Nat

/-- The constructors for the naturals -/
inductive Natα : Type
  | zero : nat_α
  | succ : nat_α

instance : Inhabited Natα :=
  ⟨Natα.zero⟩

/-- The arity of the constructors for the naturals, `zero` takes no arguments, `succ` takes one -/
def Natβ : Natα → Type
  | nat_α.zero => Empty
  | nat_α.succ => Unit

instance : Inhabited (Natβ Natα.succ) :=
  ⟨()⟩

/-- The isomorphism from the naturals to its corresponding `W_type` -/
@[simp]
def ofNat : ℕ → WType Natβ
  | Nat.zero => ⟨Natα.zero, Empty.elim⟩
  | Nat.succ n => ⟨Natα.succ, fun _ => of_nat n⟩

/-- The isomorphism from the `W_type` of the naturals to the naturals -/
@[simp]
def toNat : WType Natβ → ℕ
  | WType.mk nat_α.zero f => 0
  | WType.mk nat_α.succ f => (to_nat (f ())).succ

theorem left_inv_nat : Function.LeftInverse ofNat toNat
  | WType.mk nat_α.zero f => by
    simp
    tidy
  | WType.mk nat_α.succ f => by
    simp
    tidy

theorem right_inv_nat : Function.RightInverse ofNat toNat
  | Nat.zero => rfl
  | Nat.succ n => by
    rw [of_nat, to_nat, right_inv_nat n]

/-- The naturals are equivalent to their associated `W_type` -/
def equivNat : WType Natβ ≃ ℕ where
  toFun := toNat
  invFun := ofNat
  left_inv := left_inv_nat
  right_inv := right_inv_nat

open Sum PUnit

/-- `W_type.nat_α` is equivalent to `punit ⊕ punit`.
This is useful when considering the associated polynomial endofunctor.
-/
@[simps]
def natαEquivPunitSumPunit : nat_α ≃ Sum PUnit.{u + 1} PUnit where
  toFun := fun c =>
    match c with
    | nat_α.zero => inl unit
    | nat_α.succ => inr unit
  invFun := fun b =>
    match b with
    | inl x => Natα.zero
    | inr x => Natα.succ
  left_inv := fun c =>
    match c with
    | nat_α.zero => rfl
    | nat_α.succ => rfl
  right_inv := fun b =>
    match b with
    | inl star => rfl
    | inr star => rfl

end Nat

section List

variable (γ : Type u)

/-- The constructors for lists.
There is "one constructor `cons x` for each `x : γ`",
since we view `list γ` as
```
| nil : list γ
| cons x₀ : list γ → list γ
| cons x₁ : list γ → list γ
|   ⋮      γ many times
```
-/
inductive Listα : Type u
  | nil : list_α
  | cons : γ → list_α

instance : Inhabited (Listα γ) :=
  ⟨Listα.nil⟩

/-- The arities of each constructor for lists, `nil` takes no arguments, `cons hd` takes one -/
def Listβ : Listα γ → Type u
  | list_α.nil => Pempty
  | list_α.cons hd => PUnit

instance (hd : γ) : Inhabited (Listβ γ (Listα.cons hd)) :=
  ⟨PUnit.unit⟩

/-- The isomorphism from lists to the `W_type` construction of lists -/
@[simp]
def ofList : List γ → WType (Listβ γ)
  | List.nil => ⟨Listα.nil, Pempty.elimₓ⟩
  | List.cons hd tl => ⟨Listα.cons hd, fun _ => of_list tl⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- The isomorphism from the `W_type` construction of lists to lists -/
@[simp]
def toList : WType (Listβ γ) → List γ
  | WType.mk list_α.nil f => []
  | WType.mk (list_α.cons hd) f => hd::to_list (f PUnit.unit)

theorem left_inv_list : Function.LeftInverse (ofList γ) (toList _)
  | WType.mk list_α.nil f => by
    simp
    tidy
  | WType.mk (list_α.cons x) f => by
    simp
    tidy

theorem right_inv_list : Function.RightInverse (ofList γ) (toList _)
  | List.nil => rfl
  | List.cons hd tl => by
    simp [right_inv_list tl]

/-- Lists are equivalent to their associated `W_type` -/
def equivList : WType (Listβ γ) ≃ List γ where
  toFun := toList _
  invFun := ofList _
  left_inv := left_inv_list _
  right_inv := right_inv_list _

/-- `W_type.list_α` is equivalent to `γ` with an extra point.
This is useful when considering the associated polynomial endofunctor
-/
def listαEquivPunitSum : Listα γ ≃ Sum PUnit.{v + 1} γ where
  toFun := fun c =>
    match c with
    | list_α.nil => Sum.inl PUnit.unit
    | list_α.cons x => Sum.inr x
  invFun := Sum.elim (fun _ => Listα.nil) fun x => Listα.cons x
  left_inv := fun c =>
    match c with
    | list_α.nil => rfl
    | list_α.cons x => rfl
  right_inv := fun x =>
    match x with
    | Sum.inl PUnit.unit => rfl
    | Sum.inr x => rfl

end List

end WType

