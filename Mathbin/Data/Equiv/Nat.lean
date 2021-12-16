import Mathbin.Data.Nat.Pairing 
import Mathbin.Data.Pnat.Basic

/-!
# Equivalences involving `ℕ`

This file defines some additional constructive equivalences using `encodable` and the pairing
function on `ℕ`.
-/


open Nat

namespace Equivₓ

variable {α : Type _}

/--
An equivalence between `ℕ × ℕ` and `ℕ`, using the `mkpair` and `unpair` functions in
`data.nat.pairing`.
-/
@[simp]
def nat_prod_nat_equiv_nat : ℕ × ℕ ≃ ℕ :=
  ⟨fun p => Nat.mkpair p.1 p.2, Nat.unpair,
    fun p =>
      by 
        cases p 
        apply Nat.unpair_mkpair,
    Nat.mkpair_unpair⟩

/--
An equivalence between `bool × ℕ` and `ℕ`, by mapping `(tt, x)` to `2 * x + 1` and `(ff, x)` to
`2 * x`.
-/
@[simp]
def bool_prod_nat_equiv_nat : Bool × ℕ ≃ ℕ :=
  ⟨fun ⟨b, n⟩ => bit b n, bodd_div2,
    fun ⟨b, n⟩ =>
      by 
        simp [bool_prod_nat_equiv_nat._match_1, bodd_bit, div2_bit],
    fun n =>
      by 
        simp [bool_prod_nat_equiv_nat._match_1, bit_decomp]⟩

/--
An equivalence between `ℕ ⊕ ℕ` and `ℕ`, by mapping `(sum.inl x)` to `2 * x` and `(sum.inr x)` to
`2 * x + 1`.
-/
@[simp]
def nat_sum_nat_equiv_nat : Sum ℕ ℕ ≃ ℕ :=
  (bool_prod_equiv_sum ℕ).symm.trans bool_prod_nat_equiv_nat

/--
An equivalence between `ℤ` and `ℕ`, through `ℤ ≃ ℕ ⊕ ℕ` and `ℕ ⊕ ℕ ≃ ℕ`.
-/
def int_equiv_nat : ℤ ≃ ℕ :=
  int_equiv_nat_sum_nat.trans nat_sum_nat_equiv_nat

/--
An equivalence between `α × α` and `α`, given that there is an equivalence between `α` and `ℕ`.
-/
def prod_equiv_of_equiv_nat (e : α ≃ ℕ) : α × α ≃ α :=
  calc α × α ≃ ℕ × ℕ := prod_congr e e 
    _ ≃ ℕ := nat_prod_nat_equiv_nat 
    _ ≃ α := e.symm
    

/--
An equivalence between `ℕ+` and `ℕ`, by mapping `x` in `ℕ+` to `x - 1` in `ℕ`.
-/
def pnat_equiv_nat : ℕ+ ≃ ℕ :=
  ⟨fun n => pred n.1, succ_pnat,
    fun ⟨n, h⟩ =>
      by 
        cases n 
        cases h 
        simp [succ_pnat, h],
    fun n =>
      by 
        simp [succ_pnat]⟩

end Equivₓ

