/-
Copyright (c) 2020 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Wrenna Robson
-/
import Mathbin.Algebra.BigOperators.Basic
import Mathbin.LinearAlgebra.Vandermonde
import Mathbin.Logic.Lemmas
import Mathbin.RingTheory.Polynomial.Basic

/-!
# Lagrange interpolation

## Main definitions
* In everything that follows, `s : finset ι` is a finite set of indexes, with `v : ι → F` an
indexing of the field over some type. We call the image of v on s the interpolation nodes,
though strictly unique nodes are only defined when v is injective on s.
* `lagrange.basis_divisor x y`, with `x y : F`. These are the normalised irreducible factors of
the Lagrange basis polynomials. They evaluate to `1` at `x` and `0` at `y` when `x` and `y`
are distinct.
* `lagrange.basis v i` with `i : ι`: the Lagrange basis polynomial that evaluates to `1` at `v i`
and `0` at `v j` for `i ≠ j`.
* `lagrange.interpolate v r` where `r : ι → F` is a function from the fintype to the field: the
Lagrange interpolant that evaluates to `r i` at `x i` for all `i : ι`. The `r i` are the _values_
associated with the _nodes_`x i`.
* `lagrange.interpolate_at v f`, where `v : ι ↪ F` and `ι` is a fintype, and `f : F → F` is a
function from the field to itself: this is the Lagrange interpolant that evaluates to `f (x i)`
at `x i`, and so approximates the function `f`. This is just a special case of the general
interpolation, where the values are given by a known function `f`.
-/


open Polynomial BigOperators

section PolynomialDetermination

namespace Polynomial

variable {R : Type _} [CommRingₓ R] [IsDomain R] {f g : R[X]}

section Finset

open Function Fintype

variable (s : Finset R)

theorem eq_zero_of_degree_lt_of_eval_finset_eq_zero (degree_f_lt : f.degree < s.card) (eval_f : ∀ x ∈ s, f.eval x = 0) :
    f = 0 := by
  rw [← mem_degree_lt] at degree_f_lt
  simp_rw [eval_eq_sum_degree_lt_equiv degree_f_lt] at eval_f
  rw [← degree_lt_equiv_eq_zero_iff_eq_zero degree_f_lt]
  exact
    Matrix.eq_zero_of_forall_index_sum_mul_pow_eq_zero
      (injective.comp (embedding.subtype _).inj' (equiv_fin_of_card_eq (card_coe _)).symm.Injective) fun _ =>
      eval_f _ (Finset.coe_mem _)

theorem eq_of_degree_sub_lt_of_eval_finset_eq (degree_fg_lt : (f - g).degree < s.card)
    (eval_fg : ∀ x ∈ s, f.eval x = g.eval x) : f = g := by
  rw [← sub_eq_zero]
  refine' eq_zero_of_degree_lt_of_eval_finset_eq_zero _ degree_fg_lt _
  simp_rw [eval_sub, sub_eq_zero]
  exact eval_fg

theorem eq_of_degrees_lt_of_eval_finset_eq (degree_f_lt : f.degree < s.card) (degree_g_lt : g.degree < s.card)
    (eval_fg : ∀ x ∈ s, f.eval x = g.eval x) : f = g := by
  rw [← mem_degree_lt] at degree_f_lt degree_g_lt
  refine' eq_of_degree_sub_lt_of_eval_finset_eq _ _ eval_fg
  rw [← mem_degree_lt]
  exact Submodule.sub_mem _ degree_f_lt degree_g_lt

end Finset

section Indexed

open Finset

variable {ι : Type _} {v : ι → R} (s : Finset ι)

theorem eq_zero_of_degree_lt_of_eval_index_eq_zero (hvs : Set.InjOn v s) (degree_f_lt : f.degree < s.card)
    (eval_f : ∀ i ∈ s, f.eval (v i) = 0) : f = 0 := by
  classical
  rw [← card_image_of_inj_on hvs] at degree_f_lt
  refine' eq_zero_of_degree_lt_of_eval_finset_eq_zero _ degree_f_lt _
  intro x hx
  rcases mem_image.mp hx with ⟨_, hj, rfl⟩
  exact eval_f _ hj

theorem eq_of_degree_sub_lt_of_eval_index_eq (hvs : Set.InjOn v s) (degree_fg_lt : (f - g).degree < s.card)
    (eval_fg : ∀ i ∈ s, f.eval (v i) = g.eval (v i)) : f = g := by
  rw [← sub_eq_zero]
  refine' eq_zero_of_degree_lt_of_eval_index_eq_zero _ hvs degree_fg_lt _
  simp_rw [eval_sub, sub_eq_zero]
  exact eval_fg

theorem eq_of_degrees_lt_of_eval_index_eq (hvs : Set.InjOn v s) (degree_f_lt : f.degree < s.card)
    (degree_g_lt : g.degree < s.card) (eval_fg : ∀ i ∈ s, f.eval (v i) = g.eval (v i)) : f = g := by
  refine' eq_of_degree_sub_lt_of_eval_index_eq _ hvs _ eval_fg
  rw [← mem_degree_lt] at degree_f_lt degree_g_lt⊢
  exact Submodule.sub_mem _ degree_f_lt degree_g_lt

end Indexed

end Polynomial

end PolynomialDetermination

noncomputable section

namespace Lagrange

open Polynomial

variable {F : Type _} [Field F]

section BasisDivisor

variable {x y : F}

/-- `basis_divisor x y` is the unique linear or constant polynomial such that
when evaluated at `x` it gives `1` and `y` it gives `0` (where when `x = y` it is identically `0`).
Such polynomials are the building blocks for the Lagrange interpolants. -/
def basisDivisor (x y : F) : F[X] :=
  c (x - y)⁻¹ * (X - c y)

theorem basis_divisor_self : basisDivisor x x = 0 := by
  simp only [basis_divisor, sub_self, inv_zero, map_zero, zero_mul]

theorem basis_divisor_inj (hxy : basisDivisor x y = 0) : x = y := by
  simp_rw [basis_divisor, mul_eq_zero, X_sub_C_ne_zero, or_falseₓ, C_eq_zero, inv_eq_zero, sub_eq_zero] at hxy
  exact hxy

@[simp]
theorem basis_divisor_eq_zero_iff : basisDivisor x y = 0 ↔ x = y :=
  ⟨basis_divisor_inj, fun H => H ▸ basis_divisor_self⟩

theorem basis_divisor_ne_zero_iff : basisDivisor x y ≠ 0 ↔ x ≠ y := by
  rw [Ne.def, basis_divisor_eq_zero_iff]

theorem degree_basis_divisor_of_ne (hxy : x ≠ y) : (basisDivisor x y).degree = 1 := by
  rw [basis_divisor, degree_mul, degree_X_sub_C, degree_C, zero_addₓ]
  exact inv_ne_zero (sub_ne_zero_of_ne hxy)

@[simp]
theorem degree_basis_divisor_self : (basisDivisor x x).degree = ⊥ := by
  rw [basis_divisor_self, degree_zero]

theorem nat_degree_basis_divisor_self : (basisDivisor x x).natDegree = 0 := by
  rw [basis_divisor_self, nat_degree_zero]

theorem nat_degree_basis_divisor_of_ne (hxy : x ≠ y) : (basisDivisor x y).natDegree = 1 :=
  nat_degree_eq_of_degree_eq_some (degree_basis_divisor_of_ne hxy)

@[simp]
theorem eval_basis_divisor_right : eval y (basisDivisor x y) = 0 := by
  simp only [basis_divisor, eval_mul, eval_C, eval_sub, eval_X, sub_self, mul_zero]

theorem eval_basis_divisor_left_of_ne (hxy : x ≠ y) : eval x (basisDivisor x y) = 1 := by
  simp only [basis_divisor, eval_mul, eval_C, eval_sub, eval_X]
  exact inv_mul_cancel (sub_ne_zero_of_ne hxy)

end BasisDivisor

section Basis

open Finset

variable {ι : Type _} [DecidableEq ι] {s : Finset ι} {v : ι → F} {i j : ι}

/-- Lagrange basis polynomials indexed by `s : finset ι`, defined at nodes `v i` for a
map `v : ι → F`. For `i, j ∈ s`, `basis s v i` evaluates to 0 at `v j` for `i ≠ j`. When
`v` is injective on `s`, `basis s v i` evaluates to 1 at `v i`. -/
protected def basis (s : Finset ι) (v : ι → F) (i : ι) : F[X] :=
  ∏ j in s.erase i, basisDivisor (v i) (v j)

@[simp]
theorem basis_empty : Lagrange.basis ∅ v i = 1 :=
  rfl

@[simp]
theorem basis_singleton (i : ι) : Lagrange.basis {i} v i = 1 := by
  rw [Lagrange.basis, erase_singleton, prod_empty]

@[simp]
theorem basis_pair_left (hij : i ≠ j) : Lagrange.basis {i, j} v i = basisDivisor (v i) (v j) := by
  simp only [Lagrange.basis, hij, erase_insert_eq_erase, erase_eq_of_not_mem, mem_singleton, not_false_iff,
    prod_singleton]

@[simp]
theorem basis_pair_right (hij : i ≠ j) : Lagrange.basis {i, j} v j = basisDivisor (v j) (v i) := by
  rw [pair_comm]
  exact basis_pair_left hij.symm

theorem basis_ne_zero (hvs : Set.InjOn v s) (hi : i ∈ s) : Lagrange.basis s v i ≠ 0 := by
  simp_rw [Lagrange.basis, prod_ne_zero_iff, Ne.def, mem_erase]
  rintro j ⟨hij, hj⟩
  rw [basis_divisor_eq_zero_iff, hvs.eq_iff hi hj]
  exact hij.symm

@[simp]
theorem eval_basis_self (hvs : Set.InjOn v s) (hi : i ∈ s) : (Lagrange.basis s v i).eval (v i) = 1 := by
  rw [Lagrange.basis, eval_prod]
  refine' prod_eq_one fun j H => _
  rw [eval_basis_divisor_left_of_ne]
  rcases mem_erase.mp H with ⟨hij, hj⟩
  exact mt (hvs hi hj) hij.symm

@[simp]
theorem eval_basis_of_ne (hij : i ≠ j) (hj : j ∈ s) : (Lagrange.basis s v i).eval (v j) = 0 := by
  simp_rw [Lagrange.basis, eval_prod, prod_eq_zero_iff]
  exact ⟨j, ⟨mem_erase.mpr ⟨hij.symm, hj⟩, eval_basis_divisor_right⟩⟩

@[simp]
theorem nat_degree_basis (hvs : Set.InjOn v s) (hi : i ∈ s) : (Lagrange.basis s v i).natDegree = s.card - 1 := by
  have H : ∀ j, j ∈ s.erase i → basis_divisor (v i) (v j) ≠ 0 := by
    simp_rw [Ne.def, mem_erase, basis_divisor_eq_zero_iff]
    exact fun j ⟨hij₁, hj⟩ hij₂ => hij₁ (hvs hj hi hij₂.symm)
  rw [← card_erase_of_mem hi, card_eq_sum_ones]
  convert nat_degree_prod _ _ H using 1
  refine' sum_congr rfl fun j hj => (nat_degree_basis_divisor_of_ne _).symm
  rw [Ne.def, ← basis_divisor_eq_zero_iff]
  exact H _ hj

theorem degree_basis (hvs : Set.InjOn v s) (hi : i ∈ s) : (Lagrange.basis s v i).degree = ↑(s.card - 1) := by
  rw [degree_eq_nat_degree (basis_ne_zero hvs hi), nat_degree_basis hvs hi]

theorem sum_basis (hvs : Set.InjOn v s) (hs : s.Nonempty) : (∑ j in s, Lagrange.basis s v j) = 1 := by
  refine' eq_of_degrees_lt_of_eval_index_eq s hvs (lt_of_le_of_ltₓ (degree_sum_le _ _) _) _ _
  · rw [Finset.sup_lt_iff (WithBot.bot_lt_coe s.card)]
    intro i hi
    rw [degree_basis hvs hi, WithBot.coe_lt_coe]
    exact Nat.pred_ltₓ (card_ne_zero_of_mem hi)
    
  · rw [degree_one, ← WithBot.coe_zero, WithBot.coe_lt_coe]
    exact nonempty.card_pos hs
    
  · intro i hi
    rw [eval_finset_sum, eval_one, ← add_sum_erase _ _ hi, eval_basis_self hvs hi, add_right_eq_selfₓ]
    refine' sum_eq_zero fun j hj => _
    rcases mem_erase.mp hj with ⟨hij, hj⟩
    rw [eval_basis_of_ne hij hi]
    

theorem basis_divisor_add_symm {x y : F} (hxy : x ≠ y) : basisDivisor x y + basisDivisor y x = 1 := by
  classical
  rw [← sum_basis (Set.inj_on_of_injective Function.injective_id _) ⟨x, mem_insert_self _ {y}⟩,
    sum_insert (not_mem_singleton.mpr hxy), sum_singleton, basis_pair_left hxy, basis_pair_right hxy, id, id]

end Basis

section Interpolate

open Finset

variable {ι : Type _} [DecidableEq ι] {s t : Finset ι} {i j : ι} {v : ι → F} (r r' : ι → F)

/-- Lagrange interpolation: given a finset `s : finset ι`, a nodal map  `v : ι → F` injective on
`s` and a value function `r : ι → F`,  `interpolate s v r` is the unique
polynomial of degree `< s.card` that takes value `r i` on `v i` for all `i` in `s`. -/
@[simps]
def interpolate (s : Finset ι) (v : ι → F) : (ι → F) →ₗ[F] F[X] where
  toFun := fun r => ∑ i in s, c (r i) * Lagrange.basis s v i
  map_add' := fun f g => by
    simp_rw [← Finset.sum_add_distrib, ← add_mulₓ, ← C_add, Pi.add_apply]
  map_smul' := fun c f => by
    simp_rw [Finset.smul_sum, C_mul', smul_smul, Pi.smul_apply, RingHom.id_apply, smul_eq_mul]

@[simp]
theorem interpolate_empty : interpolate ∅ v r = 0 := by
  rw [interpolate_apply, sum_empty]

@[simp]
theorem interpolate_singleton : interpolate {i} v r = c (r i) := by
  rw [interpolate_apply, sum_singleton, basis_singleton, mul_oneₓ]

theorem interpolate_one (hvs : Set.InjOn v s) (hs : s.Nonempty) : interpolate s v 1 = 1 := by
  simp_rw [interpolate_apply, Pi.one_apply, map_one, one_mulₓ]
  exact sum_basis hvs hs

theorem eval_interpolate_at_node (hvs : Set.InjOn v s) (hi : i ∈ s) : eval (v i) (interpolate s v r) = r i := by
  rw [interpolate_apply, eval_finset_sum, ← add_sum_erase _ _ hi]
  simp_rw [eval_mul, eval_C, eval_basis_self hvs hi, mul_oneₓ, add_right_eq_selfₓ]
  refine' sum_eq_zero fun j H => _
  rw [eval_basis_of_ne (mem_erase.mp H).1 hi, mul_zero]

theorem degree_interpolate_le (hvs : Set.InjOn v s) : (interpolate s v r).degree ≤ ↑(s.card - 1) := by
  refine' (degree_sum_le _ _).trans _
  rw [Finset.sup_le_iff]
  intro i hi
  rw [degree_mul, degree_basis hvs hi]
  by_cases' hr : r i = 0
  · simpa only [hr, map_zero, degree_zero, WithBot.bot_add] using bot_le
    
  · rw [degree_C hr, zero_addₓ, WithBot.coe_le_coe]
    

theorem degree_interpolate_lt (hvs : Set.InjOn v s) : (interpolate s v r).degree < s.card := by
  rcases eq_empty_or_nonempty s with (rfl | h)
  · rw [interpolate_empty, degree_zero, card_empty]
    exact WithBot.bot_lt_coe _
    
  · refine' lt_of_le_of_ltₓ (degree_interpolate_le _ hvs) _
    rw [WithBot.coe_lt_coe]
    exact Nat.sub_ltₓ (nonempty.card_pos h) zero_lt_one
    

theorem degree_interpolate_erase_lt (hvs : Set.InjOn v s) (hi : i ∈ s) :
    (interpolate (s.erase i) v r).degree < ↑(s.card - 1) := by
  rw [← Finset.card_erase_of_mem hi]
  exact degree_interpolate_lt _ (Set.InjOn.mono (coe_subset.mpr (erase_subset _ _)) hvs)

theorem values_eq_on_of_interpolate_eq (hvs : Set.InjOn v s) (hrr' : interpolate s v r = interpolate s v r') :
    ∀ i ∈ s, r i = r' i := fun _ hi => by
  rw [← eval_interpolate_at_node r hvs hi, hrr', eval_interpolate_at_node r' hvs hi]

theorem interpolate_eq_of_values_eq_on (hrr' : ∀ i ∈ s, r i = r' i) : interpolate s v r = interpolate s v r' :=
  sum_congr rfl fun i hi => by
    rw [hrr' _ hi]

theorem interpolate_eq_iff_values_eq_on (hvs : Set.InjOn v s) :
    interpolate s v r = interpolate s v r' ↔ ∀ i ∈ s, r i = r' i :=
  ⟨values_eq_on_of_interpolate_eq _ _ hvs, interpolate_eq_of_values_eq_on _ _⟩

theorem eq_interpolate {f : F[X]} (hvs : Set.InjOn v s) (degree_f_lt : f.degree < s.card) :
    f = interpolate s v fun i => f.eval (v i) :=
  (eq_of_degrees_lt_of_eval_index_eq _ hvs degree_f_lt (degree_interpolate_lt _ hvs)) fun i hi =>
    (eval_interpolate_at_node _ hvs hi).symm

theorem eq_interpolate_of_eval_eq {f : F[X]} (hvs : Set.InjOn v s) (degree_f_lt : f.degree < s.card)
    (eval_f : ∀ i ∈ s, f.eval (v i) = r i) : f = interpolate s v r := by
  rw [eq_interpolate hvs degree_f_lt]
  exact interpolate_eq_of_values_eq_on _ _ eval_f

/-- This is the characteristic property of the interpolation: the interpolation is the
unique polynomial of `degree < fintype.card ι` which takes the value of the `r i` on the `v i`.
-/
theorem eq_interpolate_iff {f : F[X]} (hvs : Set.InjOn v s) :
    (f.degree < s.card ∧ ∀ i ∈ s, eval (v i) f = r i) ↔ f = interpolate s v r := by
  constructor <;> intro h
  · exact eq_interpolate_of_eval_eq _ hvs h.1 h.2
    
  · rw [h]
    exact ⟨degree_interpolate_lt _ hvs, fun _ hi => eval_interpolate_at_node _ hvs hi⟩
    

/-- Lagrange interpolation induces isomorphism between functions from `s`
and polynomials of degree less than `fintype.card ι`.-/
def funEquivDegreeLt (hvs : Set.InjOn v s) : degreeLt F s.card ≃ₗ[F] s → F where
  toFun := fun f i => f.1.eval (v i)
  map_add' := fun f g => funext fun v => eval_add
  map_smul' := fun c f =>
    funext <| by
      simp
  invFun := fun r =>
    ⟨interpolate s v fun x => if hx : x ∈ s then r ⟨x, hx⟩ else 0, mem_degree_lt.2 <| degree_interpolate_lt _ hvs⟩
  left_inv := by
    rintro ⟨f, hf⟩
    simp only [Subtype.mk_eq_mk, Subtype.coe_mk, dite_eq_ite]
    rw [mem_degree_lt] at hf
    nth_rw_rhs 0[eq_interpolate hvs hf]
    exact interpolate_eq_of_values_eq_on _ _ fun _ hi => if_pos hi
  right_inv := by
    intro f
    ext ⟨i, hi⟩
    simp only [Subtype.coe_mk, eval_interpolate_at_node _ hvs hi]
    exact dif_pos hi

theorem interpolate_eq_sum_interpolate_insert_sdiff (hvt : Set.InjOn v t) (hs : s.Nonempty) (hst : s ⊆ t) :
    interpolate t v r = ∑ i in s, interpolate (insert i (t \ s)) v r * Lagrange.basis s v i := by
  symm
  refine' eq_interpolate_of_eval_eq _ hvt (lt_of_le_of_ltₓ (degree_sum_le _ _) _) fun i hi => _
  · simp_rw [Finset.sup_lt_iff (WithBot.bot_lt_coe t.card), degree_mul]
    intro i hi
    have hs : 1 ≤ s.card := nonempty.card_pos ⟨_, hi⟩
    have hst' : s.card ≤ t.card := card_le_of_subset hst
    have H : t.card = 1 + (t.card - s.card) + (s.card - 1) := by
      rw [add_assocₓ, tsub_add_tsub_cancel hst' hs, ← add_tsub_assoc_of_le (hs.trans hst'), Nat.succ_add_sub_one,
        zero_addₓ]
    rw [degree_basis (Set.InjOn.mono hst hvt) hi, H, WithBot.coe_add,
      WithBot.add_lt_add_iff_right (@WithBot.coe_ne_bot _ (s.card - 1))]
    convert degree_interpolate_lt _ (hvt.mono (coe_subset.mpr (insert_subset.mpr ⟨hst hi, sdiff_subset _ _⟩)))
    rw [card_insert_of_not_mem (not_mem_sdiff_of_mem_right hi), card_sdiff hst, add_commₓ]
    
  · simp_rw [eval_finset_sum, eval_mul]
    by_cases' hi' : i ∈ s
    · rw [← add_sum_erase _ _ hi', eval_basis_self (hvt.mono hst) hi',
        eval_interpolate_at_node _ (hvt.mono (coe_subset.mpr (insert_subset.mpr ⟨hi, sdiff_subset _ _⟩)))
          (mem_insert_self _ _),
        mul_oneₓ, add_right_eq_selfₓ]
      refine' sum_eq_zero fun j hj => _
      rcases mem_erase.mp hj with ⟨hij, hj⟩
      rw [eval_basis_of_ne hij hi', mul_zero]
      
    · have H : (∑ j in s, eval (v i) (Lagrange.basis s v j)) = 1 := by
        rw [← eval_finset_sum, sum_basis (hvt.mono hst) hs, eval_one]
      rw [← mul_oneₓ (r i), ← H, mul_sum]
      refine' sum_congr rfl fun j hj => _
      congr
      exact
        eval_interpolate_at_node _ (hvt.mono (insert_subset.mpr ⟨hst hj, sdiff_subset _ _⟩))
          (mem_insert.mpr (Or.inr (mem_sdiff.mpr ⟨hi, hi'⟩)))
      
    

theorem interpolate_eq_add_interpolate_erase (hvs : Set.InjOn v s) (hi : i ∈ s) (hj : j ∈ s) (hij : i ≠ j) :
    interpolate s v r =
      interpolate (s.erase j) v r * basisDivisor (v i) (v j) + interpolate (s.erase i) v r * basisDivisor (v j) (v i) :=
  by
  rw [interpolate_eq_sum_interpolate_insert_sdiff _ hvs ⟨i, mem_insert_self i {j}⟩ _,
    sum_insert (not_mem_singleton.mpr hij), sum_singleton, basis_pair_left hij, basis_pair_right hij,
    sdiff_insert_insert_of_mem_of_not_mem hi (not_mem_singleton.mpr hij), sdiff_singleton_eq_erase, pair_comm,
    sdiff_insert_insert_of_mem_of_not_mem hj (not_mem_singleton.mpr hij.symm), sdiff_singleton_eq_erase]
  · exact insert_subset.mpr ⟨hi, singleton_subset_iff.mpr hj⟩
    

end Interpolate

section Nodal

open Finset Polynomial

variable {ι : Type _} {s : Finset ι} {v : ι → F} {i : ι} (r : ι → F) {x : F}

/-- `nodal s v` is the unique monic polynomial whose roots are the nodes defined by `v` and `s`.

That is, the roots of `nodal s v` are exactly the image of `v` on `s`,
with appropriate multiplicity.

We can use `nodal` to define the barycentric forms of the evaluated interpolant.
-/
def nodal (s : Finset ι) (v : ι → F) : F[X] :=
  ∏ i in s, X - c (v i)

theorem nodal_eq (s : Finset ι) (v : ι → F) : nodal s v = ∏ i in s, X - c (v i) :=
  rfl

@[simp]
theorem nodal_empty : nodal ∅ v = 1 :=
  rfl

theorem degree_nodal : (nodal s v).degree = s.card := by
  simp_rw [nodal, degree_prod, degree_X_sub_C, sum_const, Nat.smul_one_eq_coe]

theorem eval_nodal {x : F} : (nodal s v).eval x = ∏ i in s, x - v i := by
  simp_rw [nodal, eval_prod, eval_sub, eval_X, eval_C]

theorem eval_nodal_at_node (hi : i ∈ s) : eval (v i) (nodal s v) = 0 := by
  rw [eval_nodal, prod_eq_zero_iff]
  exact ⟨i, hi, sub_eq_zero_of_eq rfl⟩

theorem eval_nodal_not_at_node (hx : ∀ i ∈ s, x ≠ v i) : eval x (nodal s v) ≠ 0 := by
  simp_rw [nodal, eval_prod, prod_ne_zero_iff, eval_sub, eval_X, eval_C, sub_ne_zero]
  exact hx

theorem nodal_eq_mul_nodal_erase [DecidableEq ι] (hi : i ∈ s) : nodal s v = (X - c (v i)) * nodal (s.erase i) v := by
  simp_rw [nodal, mul_prod_erase _ _ hi]

theorem X_sub_C_dvd_nodal (v : ι → F) (hi : i ∈ s) : X - c (v i) ∣ nodal s v :=
  ⟨_, by
    classical
    exact nodal_eq_mul_nodal_erase hi⟩

variable [DecidableEq ι]

theorem nodal_erase_eq_nodal_div (hi : i ∈ s) : nodal (s.erase i) v = nodal s v / (X - c (v i)) := by
  rw [nodal_eq_mul_nodal_erase hi, EuclideanDomain.mul_div_cancel_left]
  exact X_sub_C_ne_zero _

theorem nodal_insert_eq_nodal (hi : i ∉ s) : nodal (insert i s) v = (X - c (v i)) * nodal s v := by
  simp_rw [nodal, prod_insert hi]

theorem derivative_nodal : (nodal s v).derivative = ∑ i in s, nodal (s.erase i) v := by
  refine' Finset.induction_on s _ fun _ _ hit IH => _
  · rw [nodal_empty, derivative_one, sum_empty]
    
  · rw [nodal_insert_eq_nodal hit, derivative_mul, IH, derivative_sub, derivative_X, derivative_C, sub_zero, one_mulₓ,
      sum_insert hit, mul_sum, erase_insert hit, add_right_injₓ]
    refine' sum_congr rfl fun j hjt => _
    rw [nodal_erase_eq_nodal_div (mem_insert_of_mem hjt), nodal_insert_eq_nodal hit,
      EuclideanDomain.mul_div_assoc _ (X_sub_C_dvd_nodal v hjt), nodal_erase_eq_nodal_div hjt]
    

theorem eval_nodal_derivative_eval_node_eq (hi : i ∈ s) :
    eval (v i) (nodal s v).derivative = eval (v i) (nodal (s.erase i) v) := by
  rw [derivative_nodal, eval_finset_sum, ← add_sum_erase _ _ hi, add_right_eq_selfₓ]
  refine' sum_eq_zero fun j hj => _
  simp_rw [nodal, eval_prod, eval_sub, eval_X, eval_C, prod_eq_zero_iff, mem_erase]
  exact ⟨i, ⟨(mem_erase.mp hj).1.symm, hi⟩, sub_eq_zero_of_eq rfl⟩

/-- This defines the nodal weight for a given set of node indexes and node mapping function `v`. -/
def nodalWeight (s : Finset ι) (v : ι → F) (i : ι) :=
  ∏ j in s.erase i, (v i - v j)⁻¹

theorem nodal_weight_eq_eval_nodal_erase_inv : nodalWeight s v i = (eval (v i) (nodal (s.erase i) v))⁻¹ := by
  rw [eval_nodal, nodal_weight, prod_inv_distrib]

theorem nodal_weight_eq_eval_nodal_derative (hi : i ∈ s) : nodalWeight s v i = (eval (v i) (nodal s v).derivative)⁻¹ :=
  by
  rw [eval_nodal_derivative_eval_node_eq hi, nodal_weight_eq_eval_nodal_erase_inv]

theorem nodal_weight_ne_zero (hvs : Set.InjOn v s) (hi : i ∈ s) : nodalWeight s v i ≠ 0 := by
  rw [nodal_weight, prod_ne_zero_iff]
  intro j hj
  rcases mem_erase.mp hj with ⟨hij, hj⟩
  refine' inv_ne_zero (sub_ne_zero_of_ne (mt (hvs.eq_iff hi hj).mp hij.symm))

theorem basis_eq_prod_sub_inv_mul_nodal_div (hi : i ∈ s) :
    Lagrange.basis s v i = c (nodalWeight s v i) * (nodal s v / (X - c (v i))) := by
  simp_rw [Lagrange.basis, basis_divisor, nodal_weight, prod_mul_distrib, map_prod, ← nodal_erase_eq_nodal_div hi,
    nodal]

theorem eval_basis_not_at_node (hi : i ∈ s) (hxi : x ≠ v i) :
    eval x (Lagrange.basis s v i) = eval x (nodal s v) * (nodalWeight s v i * (x - v i)⁻¹) := by
  rw [mul_comm, basis_eq_prod_sub_inv_mul_nodal_div hi, eval_mul, eval_C, ← nodal_erase_eq_nodal_div hi, eval_nodal,
    eval_nodal, mul_assoc, ← mul_prod_erase _ _ hi, ← mul_assoc (x - v i)⁻¹, inv_mul_cancel (sub_ne_zero_of_ne hxi),
    one_mulₓ]

theorem interpolate_eq_nodal_weight_mul_nodal_div_X_sub_C :
    interpolate s v r = ∑ i in s, c (nodalWeight s v i) * (nodal s v / (X - c (v i))) * c (r i) :=
  sum_congr rfl fun j hj => by
    rw [mul_comm, basis_eq_prod_sub_inv_mul_nodal_div hj]

/-- This is the first barycentric form of the Lagrange interpolant. -/
theorem eval_interpolate_not_at_node (hx : ∀ i ∈ s, x ≠ v i) :
    eval x (interpolate s v r) = eval x (nodal s v) * ∑ i in s, nodalWeight s v i * (x - v i)⁻¹ * r i := by
  simp_rw [interpolate_apply, mul_sum, eval_finset_sum, eval_mul, eval_C]
  refine' sum_congr rfl fun i hi => _
  rw [← mul_assoc, mul_comm, eval_basis_not_at_node hi (hx _ hi)]

theorem sum_nodal_weight_mul_inv_sub_ne_zero (hvs : Set.InjOn v s) (hx : ∀ i ∈ s, x ≠ v i) (hs : s.Nonempty) :
    (∑ i in s, nodalWeight s v i * (x - v i)⁻¹) ≠ 0 :=
  @right_ne_zero_of_mul_eq_one _ _ _ (eval x (nodal s v)) _ <| by
    simpa only [Pi.one_apply, interpolate_one hvs hs, eval_one, mul_oneₓ] using (eval_interpolate_not_at_node 1 hx).symm

/-- This is the second barycentric form of the Lagrange interpolant. -/
theorem eval_interpolate_not_at_node' (hvs : Set.InjOn v s) (hs : s.Nonempty) (hx : ∀ i ∈ s, x ≠ v i) :
    eval x (interpolate s v r) =
      (∑ i in s, nodalWeight s v i * (x - v i)⁻¹ * r i) / ∑ i in s, nodalWeight s v i * (x - v i)⁻¹ :=
  by
  rw [← div_one (eval x (interpolate s v r)), ← @eval_one _ _ x, ← interpolate_one hvs hs,
    eval_interpolate_not_at_node r hx, eval_interpolate_not_at_node 1 hx]
  simp only [mul_div_mul_left _ _ (eval_nodal_not_at_node hx), Pi.one_apply, mul_oneₓ]

end Nodal

end Lagrange

