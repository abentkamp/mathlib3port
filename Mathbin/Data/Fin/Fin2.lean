/-
Copyright (c) 2017 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro
-/

/-!
# Inductive type variant of `fin`

`fin` is defined as a subtype of `ℕ`. This file defines an equivalent type, `fin2`, which is
defined inductively. This is useful for its induction principle and different definitional
equalities.

## Main declarations

* `fin2 n`: Inductive type variant of `fin n`. `fz` corresponds to `0` and `fs n` corresponds to
  `n`.
* `to_nat`, `opt_of_nat`, `of_nat'`: Conversions to and from `ℕ`. `of_nat' m` takes a proof that
  `m < n` through the class `is_lt`.
* `add k`: Takes `i : fin2 n` to `i + k : fin2 (n + k)`.
* `left`: Embeds `fin2 n` into `fin2 (n + k)`.
* `insert_perm a`: Permutation of `fin2 n` which cycles `0, ..., a - 1` and leaves `a, ..., n - 1`
  unchanged.
* `remap_left f`: Function `fin2 (m + k) → fin2 (n + k)` by applying `f : fin m → fin n` to
  `0, ..., m - 1` and sending `m + i` to `n + i`.
-/


open Nat

universe u

/-- An alternate definition of `fin n` defined as an inductive type instead of a subtype of `ℕ`. -/
inductive Fin2 : ℕ → Type
  | /-- `0` as a member of `fin (succ n)` (`fin 0` is empty) -/
  fz {n} : Fin2 (succ n)
  | /-- `n` as a member of `fin (succ n)` -/
  fs {n} : Fin2 n → Fin2 (succ n)

namespace Fin2

/-- Define a dependent function on `fin2 (succ n)` by giving its value at
zero (`H1`) and by giving a dependent function on the rest (`H2`). -/
@[elabAsElim]
protected def cases' {n} {C : Fin2 (succ n) → Sort u} (H1 : C fz) (H2 : ∀ n, C (fs n)) : ∀ i : Fin2 (succ n), C i
  | fz => H1
  | fs n => H2 n

/-- Ex falso. The dependent eliminator for the empty `fin2 0` type. -/
def elim0 {C : Fin2 0 → Sort u} : ∀ i : Fin2 0, C i :=
  fun.

/-- Converts a `fin2` into a natural. -/
def toNat : ∀ {n}, Fin2 n → ℕ
  | _, @fz n => 0
  | _, @fs n i => succ (to_nat i)

/-- Converts a natural into a `fin2` if it is in range -/
def optOfNat : ∀ {n} (k : ℕ), Option (Fin2 n)
  | 0, _ => none
  | succ n, 0 => some fz
  | succ n, succ k => fs <$> @opt_of_nat n k

/-- `i + k : fin2 (n + k)` when `i : fin2 n` and `k : ℕ` -/
def add {n} (i : Fin2 n) : ∀ k, Fin2 (n + k)
  | 0 => i
  | succ k => fs (add k)

/-- `left k` is the embedding `fin2 n → fin2 (k + n)` -/
def left (k) : ∀ {n}, Fin2 n → Fin2 (k + n)
  | _, @fz n => fz
  | _, @fs n i => fs (left i)

/-- `insert_perm a` is a permutation of `fin2 n` with the following properties:
  * `insert_perm a i = i+1` if `i < a`
  * `insert_perm a a = 0`
  * `insert_perm a i = i` if `i > a` -/
def insertPerm : ∀ {n}, Fin2 n → Fin2 n → Fin2 n
  | _, @fz n, @fz _ => fz
  | _, @fz n, @fs _ j => fs j
  | _, @fs (succ n) i, @fz _ => fs fz
  | _, @fs (succ n) i, @fs _ j =>
    match insert_perm i j with
    | fz => fz
    | fs k => fs (fs k)

/-- `remap_left f k : fin2 (m + k) → fin2 (n + k)` applies the function
  `f : fin2 m → fin2 n` to inputs less than `m`, and leaves the right part
  on the right (that is, `remap_left f k (m + i) = n + i`). -/
def remapLeft {m n} (f : Fin2 m → Fin2 n) : ∀ k, Fin2 (m + k) → Fin2 (n + k)
  | 0, i => f i
  | succ k, @fz _ => fz
  | succ k, @fs _ i => fs (remap_left _ i)

/-- This is a simple type class inference prover for proof obligations
  of the form `m < n` where `m n : ℕ`. -/
class IsLt (m n : ℕ) where
  h : m < n

instance IsLt.zero (n) : IsLt 0 (succ n) :=
  ⟨succ_posₓ _⟩

instance IsLt.succ (m n) [l : IsLt m n] : IsLt (succ m) (succ n) :=
  ⟨succ_lt_succₓ l.h⟩

/-- Use type class inference to infer the boundedness proof, so that we can directly convert a
`nat` into a `fin2 n`. This supports notation like `&1 : fin 3`. -/
def ofNat' : ∀ {n} (m) [IsLt m n], Fin2 n
  | 0, m, ⟨h⟩ => absurd h (Nat.not_lt_zeroₓ _)
  | succ n, 0, ⟨h⟩ => fz
  | succ n, succ m, ⟨h⟩ => fs (@of_nat' n m ⟨lt_of_succ_lt_succₓ h⟩)

-- mathport name: «expr& »
local prefix:arg "&" => ofNat'

instance : Inhabited (Fin2 1) :=
  ⟨fz⟩

end Fin2

