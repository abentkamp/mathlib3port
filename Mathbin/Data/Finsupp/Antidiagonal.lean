import Mathbin.Data.Finsupp.Basic 
import Mathbin.Data.Multiset.Antidiagonal

/-!
# The `finsupp` counterpart of `multiset.antidiagonal`.

The antidiagonal of `s : α →₀ ℕ` consists of
all pairs `(t₁, t₂) : (α →₀ ℕ) × (α →₀ ℕ)` such that `t₁ + t₂ = s`.
-/


noncomputable section 

open_locale Classical BigOperators

namespace Finsupp

open Finset

variable {α : Type _}

/-- The `finsupp` counterpart of `multiset.antidiagonal`: the antidiagonal of
`s : α →₀ ℕ` consists of all pairs `(t₁, t₂) : (α →₀ ℕ) × (α →₀ ℕ)` such that `t₁ + t₂ = s`.
The finitely supported function `antidiagonal s` is equal to the multiplicities of these pairs. -/
def antidiagonal' (f : α →₀ ℕ) : (α →₀ ℕ) × (α →₀ ℕ) →₀ ℕ :=
  (f.to_multiset.antidiagonal.map (Prod.map Multiset.toFinsupp Multiset.toFinsupp)).toFinsupp

/-- The antidiagonal of `s : α →₀ ℕ` is the finset of all pairs `(t₁, t₂) : (α →₀ ℕ) × (α →₀ ℕ)`
such that `t₁ + t₂ = s`. -/
def antidiagonal (f : α →₀ ℕ) : Finset ((α →₀ ℕ) × (α →₀ ℕ)) :=
  f.antidiagonal'.support

@[simp]
theorem mem_antidiagonal {f : α →₀ ℕ} {p : (α →₀ ℕ) × (α →₀ ℕ)} : p ∈ antidiagonal f ↔ (p.1+p.2) = f :=
  by 
    rcases p with ⟨p₁, p₂⟩
    simp [antidiagonal, antidiagonal', ←And.assoc, ←finsupp.to_multiset.apply_eq_iff_eq]

theorem swap_mem_antidiagonal {n : α →₀ ℕ} {f : (α →₀ ℕ) × (α →₀ ℕ)} : f.swap ∈ antidiagonal n ↔ f ∈ antidiagonal n :=
  by 
    simp only [mem_antidiagonal, add_commₓ, Prod.swap]

theorem antidiagonal_filter_fst_eq (f g : α →₀ ℕ) [D : ∀ p : (α →₀ ℕ) × (α →₀ ℕ), Decidable (p.1 = g)] :
  ((antidiagonal f).filter fun p => p.1 = g) = if g ≤ f then {(g, f - g)} else ∅ :=
  by 
    ext ⟨a, b⟩
    suffices  : a = g → ((a+b) = f ↔ g ≤ f ∧ b = f - g)
    ·
      simpa [apply_ite ((· ∈ ·) (a, b)), ←And.assoc, @And.right_comm _ (a = _), And.congr_left_iff]
    (
      rintro rfl)
    constructor
    ·
      rintro rfl 
      exact ⟨le_add_right le_rfl, (add_tsub_cancel_left _ _).symm⟩
    ·
      rintro ⟨h, rfl⟩
      exact add_tsub_cancel_of_le h

theorem antidiagonal_filter_snd_eq (f g : α →₀ ℕ) [D : ∀ p : (α →₀ ℕ) × (α →₀ ℕ), Decidable (p.2 = g)] :
  ((antidiagonal f).filter fun p => p.2 = g) = if g ≤ f then {(f - g, g)} else ∅ :=
  by 
    ext ⟨a, b⟩
    suffices  : b = g → ((a+b) = f ↔ g ≤ f ∧ a = f - g)
    ·
      simpa [apply_ite ((· ∈ ·) (a, b)), ←And.assoc, And.congr_left_iff]
    (
      rintro rfl)
    constructor
    ·
      rintro rfl 
      exact ⟨le_add_left le_rfl, (add_tsub_cancel_right _ _).symm⟩
    ·
      rintro ⟨h, rfl⟩
      exact tsub_add_cancel_of_le h

@[simp]
theorem antidiagonal_zero : antidiagonal (0 : α →₀ ℕ) = singleton (0, 0) :=
  by 
    rw [antidiagonal, antidiagonal', Multiset.to_finsupp_support] <;> rfl

@[toAdditive]
theorem prod_antidiagonal_swap {M : Type _} [CommMonoidₓ M] (n : α →₀ ℕ) (f : (α →₀ ℕ) → (α →₀ ℕ) → M) :
  (∏ p in antidiagonal n, f p.1 p.2) = ∏ p in antidiagonal n, f p.2 p.1 :=
  Finset.prod_bij (fun p hp => p.swap) (fun p => swap_mem_antidiagonal.2) (fun p hp => rfl)
    (fun p₁ p₂ _ _ h => Prod.swap_injectiveₓ h) fun p hp => ⟨p.swap, swap_mem_antidiagonal.2 hp, p.swap_swap.symm⟩

/-- The set `{m : α →₀ ℕ | m ≤ n}` as a `finset`. -/
def Iic_finset (n : α →₀ ℕ) : Finset (α →₀ ℕ) :=
  (antidiagonal n).Image Prod.fst

@[simp]
theorem mem_Iic_finset {m n : α →₀ ℕ} : m ∈ Iic_finset n ↔ m ≤ n :=
  by 
    simp [Iic_finset, le_iff_exists_add, eq_comm]

@[simp]
theorem coe_Iic_finset (n : α →₀ ℕ) : ↑Iic_finset n = Set.Iic n :=
  by 
    ext 
    simp 

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    Let `n : α →₀ ℕ` be a finitely supported function.
    The set of `m : α →₀ ℕ` that are coordinatewise less than or equal to `n`,
    is a finite set. -/
  theorem finite_le_nat ( n : α →₀ ℕ ) : Set.Finite { m | m ≤ n } := by simpa using Iic_finset n . finite_to_set

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    Let `n : α →₀ ℕ` be a finitely supported function.
    The set of `m : α →₀ ℕ` that are coordinatewise less than or equal to `n`,
    but not equal to `n` everywhere, is a finite set. -/
  theorem finite_lt_nat ( n : α →₀ ℕ ) : Set.Finite { m | m < n } := finite_le_nat n . Subset $ fun m => le_of_ltₓ

end Finsupp

