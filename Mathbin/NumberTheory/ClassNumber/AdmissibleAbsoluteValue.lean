import Mathbin.Algebra.Order.EuclideanAbsoluteValue 
import Mathbin.Analysis.SpecialFunctions.Pow 
import Mathbin.Combinatorics.Pigeonhole

/-!
# Admissible absolute values
This file defines a structure `absolute_value.is_admissible` which we use to show the class number
of the ring of integers of a global field is finite.

## Main definitions

 * `absolute_value.is_admissible abv` states the absolute value `abv : R → ℤ`
   respects the Euclidean domain structure on `R`, and that a large enough set
   of elements of `R^n` contains a pair of elements whose remainders are
   pointwise close together.

## Main results

 * `absolute_value.abs_is_admissible` shows the "standard" absolute value on `ℤ`,
   mapping negative `x` to `-x`, is admissible.
 * `polynomial.card_pow_degree_is_admissible` shows `card_pow_degree`,
   mapping `p : polynomial 𝔽_q` to `q ^ degree p`, is admissible
-/


local infixl:50 " ≺ " => EuclideanDomain.R

namespace AbsoluteValue

variable{R : Type _}[EuclideanDomain R]

variable(abv : AbsoluteValue R ℤ)

/-- An absolute value `R → ℤ` is admissible if it respects the Euclidean domain
structure and a large enough set of elements in `R^n` will contain a pair of
elements whose remainders are pointwise close together. -/
structure is_admissible extends is_euclidean abv where 
  card : ℝ → ℕ 
  exists_partition' :
  ∀ n : ℕ {ε : ℝ} hε : 0 < ε {b : R} hb : b ≠ 0 A : Finₓ n → R,
    ∃ t : Finₓ n → Finₓ (card ε), ∀ i₀ i₁, t i₀ = t i₁ → (abv (A i₁ % b - A i₀ % b) : ℝ) < abv b • ε

attribute [protected] is_admissible.card

namespace IsAdmissible

variable{abv}

/-- For all `ε > 0` and finite families `A`, we can partition the remainders of `A` mod `b`
into `abv.card ε` sets, such that all elements in each part of remainders are close together. -/
theorem exists_partition {ι : Type _} [Fintype ι] {ε : ℝ} (hε : 0 < ε) {b : R} (hb : b ≠ 0) (A : ι → R)
  (h : abv.is_admissible) :
  ∃ t : ι → Finₓ (h.card ε), ∀ i₀ i₁, t i₀ = t i₁ → (abv (A i₁ % b - A i₀ % b) : ℝ) < abv b • ε :=
  by 
    let e := Fintype.equivFin ι 
    obtain ⟨t, ht⟩ := h.exists_partition' (Fintype.card ι) hε hb (A ∘ e.symm)
    refine' ⟨t ∘ e, fun i₀ i₁ h => _⟩
    convert ht (e i₀) (e i₁) h <;> simp only [e.symm_apply_apply]

/-- Any large enough family of vectors in `R^n` has a pair of elements
whose remainders are close together, pointwise. -/
theorem exists_approx_aux (n : ℕ) (h : abv.is_admissible) :
  ∀ {ε : ℝ} hε : 0 < ε {b : R} hb : b ≠ 0 A : Finₓ (h.card ε^n).succ → Finₓ n → R,
    ∃ i₀ i₁, i₀ ≠ i₁ ∧ ∀ k, (abv (A i₁ k % b - A i₀ k % b) : ℝ) < abv b • ε :=
  by 
    haveI  := Classical.decEq R 
    induction' n with n ih
    ·
      intro ε hε b hb A 
      refine' ⟨0, 1, _, _⟩
      ·
        simp 
      rintro ⟨i, ⟨⟩⟩
    intro ε hε b hb A 
    set M := h.card ε with hM 
    obtain ⟨s, s_inj, hs⟩ :
      ∃ s : Finₓ (M^n).succ → Finₓ (M^n.succ).succ,
        Function.Injective s ∧ ∀ i₀ i₁, (abv (A (s i₁) 0 % b - A (s i₀) 0 % b) : ℝ) < abv b • ε
    ·
      obtain ⟨t, ht⟩ :
        ∃ t : Finₓ (M^n.succ).succ → Finₓ M, ∀ i₀ i₁, t i₀ = t i₁ → (abv (A i₁ 0 % b - A i₀ 0 % b) : ℝ) < abv b • ε :=
        h.exists_partition hε hb fun x => A x 0 
      obtain ⟨s, hs⟩ :=
        @Fintype.exists_lt_card_fiber_of_mul_lt_card _ _ _ _ _ t (M^n)
          (by 
            simpa only [Fintype.card_fin, pow_succₓ] using Nat.lt_succ_selfₓ (M^n.succ))
      refine' ⟨fun i => (finset.univ.filter fun x => t x = s).toList.nthLe i _, _, fun i₀ i₁ => ht _ _ _⟩
      ·
        refine' i.2.trans_le _ 
        rwa [Finset.length_to_list]
      ·
        intro i j h 
        ext 
        exact list.nodup_iff_nth_le_inj.mp (Finset.nodup_to_list _) _ _ _ _ h 
      have  : ∀ i h, (finset.univ.filter fun x => t x = s).toList.nthLe i h ∈ finset.univ.filter fun x => t x = s
      ·
        intro i h 
        exact (Finset.mem_to_list _).mp (List.nth_le_mem _ _ _)
      obtain ⟨_, h₀⟩ := finset.mem_filter.mp (this i₀ _)
      obtain ⟨_, h₁⟩ := finset.mem_filter.mp (this i₁ _)
      exact h₀.trans h₁.symm 
    obtain ⟨k₀, k₁, hk, h⟩ := ih hε hb fun x => Finₓ.tail (A (s x))
    refine' ⟨s k₀, s k₁, fun h => hk (s_inj h), fun i => Finₓ.cases _ (fun i => _) i⟩
    ·
      exact hs k₀ k₁
    ·
      exact h i

/-- Any large enough family of vectors in `R^ι` has a pair of elements
whose remainders are close together, pointwise. -/
theorem exists_approx {ι : Type _} [Fintype ι] {ε : ℝ} (hε : 0 < ε) {b : R} (hb : b ≠ 0) (h : abv.is_admissible)
  (A : Finₓ (h.card ε^Fintype.card ι).succ → ι → R) :
  ∃ i₀ i₁, i₀ ≠ i₁ ∧ ∀ k, (abv (A i₁ k % b - A i₀ k % b) : ℝ) < abv b • ε :=
  by 
    let e := Fintype.equivFin ι 
    obtain ⟨i₀, i₁, ne, h⟩ := h.exists_approx_aux (Fintype.card ι) hε hb fun x y => A x (e.symm y)
    refine' ⟨i₀, i₁, Ne, fun k => _⟩
    convert h (e k) <;> simp only [e.symm_apply_apply]

end IsAdmissible

end AbsoluteValue

