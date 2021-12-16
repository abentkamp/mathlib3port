import Mathbin.Algebra.BigOperators.Order 
import Mathbin.Data.Nat.Interval 
import Mathbin.Data.Nat.Prime

/-!
# Divisor finsets

This file defines sets of divisors of a natural number. This is particularly useful as background
for defining Dirichlet convolution.

## Main Definitions
Let `n : ℕ`. All of the following definitions are in the `nat` namespace:
 * `divisors n` is the `finset` of natural numbers that divide `n`.
 * `proper_divisors n` is the `finset` of natural numbers that divide `n`, other than `n`.
 * `divisors_antidiagonal n` is the `finset` of pairs `(x,y)` such that `x * y = n`.
 * `perfect n` is true when `n` is positive and the sum of `proper_divisors n` is `n`.

## Implementation details
 * `divisors 0`, `proper_divisors 0`, and `divisors_antidiagonal 0` are defined to be `∅`.

## Tags
divisors, perfect numbers

-/


open_locale Classical

open_locale BigOperators

open Finset

namespace Nat

variable (n : ℕ)

/-- `divisors n` is the `finset` of divisors of `n`. As a special case, `divisors 0 = ∅`. -/
def divisors : Finset ℕ :=
  Finset.filter (fun x : ℕ => x ∣ n) (Finset.ico 1 (n+1))

/-- `proper_divisors n` is the `finset` of divisors of `n`, other than `n`.
  As a special case, `proper_divisors 0 = ∅`. -/
def proper_divisors : Finset ℕ :=
  Finset.filter (fun x : ℕ => x ∣ n) (Finset.ico 1 n)

/-- `divisors_antidiagonal n` is the `finset` of pairs `(x,y)` such that `x * y = n`.
  As a special case, `divisors_antidiagonal 0 = ∅`. -/
def divisors_antidiagonal : Finset (ℕ × ℕ) :=
  ((Finset.ico 1 (n+1)).product (Finset.ico 1 (n+1))).filter fun x => (x.fst*x.snd) = n

variable {n}

theorem proper_divisors.not_self_mem : ¬n ∈ proper_divisors n :=
  by 
    rw [proper_divisors]
    simp 

@[simp]
theorem mem_proper_divisors {m : ℕ} : n ∈ proper_divisors m ↔ n ∣ m ∧ n < m :=
  by 
    rw [proper_divisors, Finset.mem_filter, Finset.mem_Ico, and_comm]
    apply and_congr_right 
    rw [and_iff_right_iff_imp]
    intro hdvd hlt 
    apply Nat.pos_of_ne_zeroₓ _ 
    rintro rfl 
    rw [zero_dvd_iff.1 hdvd] at hlt 
    apply lt_irreflₓ 0 hlt

theorem divisors_eq_proper_divisors_insert_self_of_pos (h : 0 < n) :
  divisors n = HasInsert.insert n (proper_divisors n) :=
  by 
    rw [divisors, proper_divisors, Ico_succ_right_eq_insert_Ico h, Finset.filter_insert, if_pos (dvd_refl n)]

@[simp]
theorem mem_divisors {m : ℕ} : n ∈ divisors m ↔ n ∣ m ∧ m ≠ 0 :=
  by 
    cases m
    ·
      simp [divisors]
    simp only [divisors, Finset.mem_Ico, Ne.def, Finset.mem_filter, succ_ne_zero, and_trueₓ, and_iff_right_iff_imp,
      not_false_iff]
    intro hdvd 
    constructor
    ·
      apply Nat.pos_of_ne_zeroₓ 
      rintro rfl 
      apply Nat.succ_ne_zero 
      rwa [zero_dvd_iff] at hdvd
    ·
      rw [Nat.lt_succ_iff]
      apply Nat.le_of_dvdₓ (Nat.succ_posₓ m) hdvd

theorem mem_divisors_self (n : ℕ) (h : n ≠ 0) : n ∈ n.divisors :=
  mem_divisors.2 ⟨dvd_rfl, h⟩

theorem dvd_of_mem_divisors {m : ℕ} (h : n ∈ divisors m) : n ∣ m :=
  by 
    cases m
    ·
      apply dvd_zero
    ·
      simp [mem_divisors.1 h]

@[simp]
theorem mem_divisors_antidiagonal {x : ℕ × ℕ} : x ∈ divisors_antidiagonal n ↔ (x.fst*x.snd) = n ∧ n ≠ 0 :=
  by 
    simp only [divisors_antidiagonal, Finset.mem_Ico, Ne.def, Finset.mem_filter, Finset.mem_product]
    rw [and_comm]
    apply and_congr_right 
    rintro rfl 
    constructor <;> intro h
    ·
      contrapose! h 
      simp [h]
    ·
      rw [Nat.lt_add_one_iff, Nat.lt_add_one_iff]
      rw [mul_eq_zero, Decidable.not_or_iff_and_not] at h 
      simp only [succ_le_of_lt (Nat.pos_of_ne_zeroₓ h.1), succ_le_of_lt (Nat.pos_of_ne_zeroₓ h.2), true_andₓ]
      exact ⟨le_mul_of_pos_right (Nat.pos_of_ne_zeroₓ h.2), le_mul_of_pos_left (Nat.pos_of_ne_zeroₓ h.1)⟩

variable {n}

theorem divisor_le {m : ℕ} : n ∈ divisors m → n ≤ m :=
  by 
    cases m
    ·
      simp 
    simp only [mem_divisors, m.succ_ne_zero, and_trueₓ, Ne.def, not_false_iff]
    exact Nat.le_of_dvdₓ (Nat.succ_posₓ m)

theorem divisors_subset_of_dvd {m : ℕ} (hzero : n ≠ 0) (h : m ∣ n) : divisors m ⊆ divisors n :=
  Finset.subset_iff.2$ fun x hx => Nat.mem_divisors.mpr ⟨(Nat.mem_divisors.mp hx).1.trans h, hzero⟩

theorem divisors_subset_proper_divisors {m : ℕ} (hzero : n ≠ 0) (h : m ∣ n) (hdiff : m ≠ n) :
  divisors m ⊆ proper_divisors n :=
  by 
    apply Finset.subset_iff.2
    intro x hx 
    exact
      Nat.mem_proper_divisors.2
        ⟨(Nat.mem_divisors.1 hx).1.trans h,
          lt_of_le_of_ltₓ (divisor_le hx) (lt_of_le_of_neₓ (divisor_le (Nat.mem_divisors.2 ⟨h, hzero⟩)) hdiff)⟩

@[simp]
theorem divisors_zero : divisors 0 = ∅ :=
  by 
    ext 
    simp 

@[simp]
theorem proper_divisors_zero : proper_divisors 0 = ∅ :=
  by 
    ext 
    simp 

theorem proper_divisors_subset_divisors : proper_divisors n ⊆ divisors n :=
  by 
    cases n
    ·
      simp 
    rw [divisors_eq_proper_divisors_insert_self_of_pos (Nat.succ_posₓ _)]
    apply subset_insert

@[simp]
theorem divisors_one : divisors 1 = {1} :=
  by 
    ext 
    simp 

@[simp]
theorem proper_divisors_one : proper_divisors 1 = ∅ :=
  by 
    ext 
    simp only [Finset.not_mem_empty, Nat.dvd_one, not_and, not_ltₓ, mem_proper_divisors, iff_falseₓ]
    apply ge_of_eq

theorem pos_of_mem_divisors {m : ℕ} (h : m ∈ n.divisors) : 0 < m :=
  by 
    cases m
    ·
      rw [mem_divisors, zero_dvd_iff] at h 
      rcases h with ⟨rfl, h⟩
      exfalso 
      apply h rfl 
    apply Nat.succ_posₓ

theorem pos_of_mem_proper_divisors {m : ℕ} (h : m ∈ n.proper_divisors) : 0 < m :=
  pos_of_mem_divisors (proper_divisors_subset_divisors h)

theorem one_mem_proper_divisors_iff_one_lt : 1 ∈ n.proper_divisors ↔ 1 < n :=
  by 
    rw [mem_proper_divisors, and_iff_right (one_dvd _)]

@[simp]
theorem divisors_antidiagonal_zero : divisors_antidiagonal 0 = ∅ :=
  by 
    ext 
    simp 

@[simp]
theorem divisors_antidiagonal_one : divisors_antidiagonal 1 = {(1, 1)} :=
  by 
    ext 
    simp [Nat.mul_eq_one_iff, Prod.ext_iff]

theorem swap_mem_divisors_antidiagonal {x : ℕ × ℕ} (h : x ∈ divisors_antidiagonal n) :
  x.swap ∈ divisors_antidiagonal n :=
  by 
    rw [mem_divisors_antidiagonal, mul_commₓ] at h 
    simp [h.1, h.2]

theorem fst_mem_divisors_of_mem_antidiagonal {x : ℕ × ℕ} (h : x ∈ divisors_antidiagonal n) : x.fst ∈ divisors n :=
  by 
    rw [mem_divisors_antidiagonal] at h 
    simp [Dvd.intro _ h.1, h.2]

theorem snd_mem_divisors_of_mem_antidiagonal {x : ℕ × ℕ} (h : x ∈ divisors_antidiagonal n) : x.snd ∈ divisors n :=
  by 
    rw [mem_divisors_antidiagonal] at h 
    simp [Dvd.intro_left _ h.1, h.2]

@[simp]
theorem map_swap_divisors_antidiagonal :
  (divisors_antidiagonal n).map ⟨Prod.swap, Prod.swap_right_inverseₓ.Injective⟩ = divisors_antidiagonal n :=
  by 
    ext 
    simp only [exists_prop, mem_divisors_antidiagonal, Finset.mem_map, Function.Embedding.coe_fn_mk, Ne.def,
      Prod.swap_prod_mkₓ, Prod.exists]
    constructor
    ·
      rintro ⟨x, y, ⟨⟨rfl, h⟩, rfl⟩⟩
      simp [mul_commₓ, h]
    ·
      rintro ⟨rfl, h⟩
      use a.snd, a.fst 
      rw [mul_commₓ]
      simp [h]

theorem sum_divisors_eq_sum_proper_divisors_add_self : (∑ i in divisors n, i) = (∑ i in proper_divisors n, i)+n :=
  by 
    cases n
    ·
      simp 
    ·
      rw [divisors_eq_proper_divisors_insert_self_of_pos (Nat.succ_posₓ _),
        Finset.sum_insert proper_divisors.not_self_mem, add_commₓ]

/-- `n : ℕ` is perfect if and only the sum of the proper divisors of `n` is `n` and `n`
  is positive. -/
def perfect (n : ℕ) : Prop :=
  (∑ i in proper_divisors n, i) = n ∧ 0 < n

theorem perfect_iff_sum_proper_divisors (h : 0 < n) : perfect n ↔ (∑ i in proper_divisors n, i) = n :=
  and_iff_left h

theorem perfect_iff_sum_divisors_eq_two_mul (h : 0 < n) : perfect n ↔ (∑ i in divisors n, i) = 2*n :=
  by 
    rw [perfect_iff_sum_proper_divisors h, sum_divisors_eq_sum_proper_divisors_add_self, two_mul]
    constructor <;> intro h
    ·
      rw [h]
    ·
      apply add_right_cancelₓ h

theorem mem_divisors_prime_pow {p : ℕ} (pp : p.prime) (k : ℕ) {x : ℕ} :
  x ∈ divisors (p ^ k) ↔ ∃ (j : ℕ)(H : j ≤ k), x = p ^ j :=
  by 
    rw [mem_divisors, Nat.dvd_prime_pow pp, and_iff_left (ne_of_gtₓ (pow_pos pp.pos k))]

theorem prime.divisors {p : ℕ} (pp : p.prime) : divisors p = {1, p} :=
  by 
    ext 
    simp only [pp.ne_zero, and_trueₓ, Ne.def, not_false_iff, Finset.mem_insert, Finset.mem_singleton, mem_divisors]
    refine' ⟨pp.2 a, fun h => _⟩
    rcases h with ⟨⟩ <;> subst h 
    apply one_dvd

theorem prime.proper_divisors {p : ℕ} (pp : p.prime) : proper_divisors p = {1} :=
  by 
    rw [←erase_insert proper_divisors.not_self_mem, ←divisors_eq_proper_divisors_insert_self_of_pos pp.pos, pp.divisors,
      insert_singleton_comm, erase_insert fun con => pp.ne_one (mem_singleton.1 con)]

theorem divisors_prime_pow {p : ℕ} (pp : p.prime) (k : ℕ) :
  divisors (p ^ k) = (Finset.range (k+1)).map ⟨pow p, pow_right_injective pp.two_le⟩ :=
  by 
    ext 
    simp [mem_divisors_prime_pow, pp, Nat.lt_succ_iff, @eq_comm _ a]

theorem eq_proper_divisors_of_subset_of_sum_eq_sum {s : Finset ℕ} (hsub : s ⊆ n.proper_divisors) :
  ((∑ x in s, x) = ∑ x in n.proper_divisors, x) → s = n.proper_divisors :=
  by 
    cases n
    ·
      rw [proper_divisors_zero, subset_empty] at hsub 
      simp [hsub]
    classical 
    rw [←sum_sdiff hsub]
    intro h 
    apply subset.antisymm hsub 
    rw [←sdiff_eq_empty_iff_subset]
    contrapose h 
    rw [←Ne.def, ←nonempty_iff_ne_empty] at h 
    apply ne_of_ltₓ 
    rw [←zero_addₓ (∑ x in s, x), ←add_assocₓ, add_zeroₓ]
    apply add_lt_add_right 
    have hlt := sum_lt_sum_of_nonempty h fun x hx => pos_of_mem_proper_divisors (sdiff_subset _ _ hx)
    simp only [sum_const_zero] at hlt 
    apply hlt

theorem sum_proper_divisors_dvd (h : (∑ x in n.proper_divisors, x) ∣ n) :
  (∑ x in n.proper_divisors, x) = 1 ∨ (∑ x in n.proper_divisors, x) = n :=
  by 
    cases n
    ·
      simp 
    cases n
    ·
      contrapose! h 
      simp 
    rw [or_iff_not_imp_right]
    intro ne_n 
    have hlt : (∑ x in n.succ.succ.proper_divisors, x) < n.succ.succ :=
      lt_of_le_of_neₓ (Nat.le_of_dvdₓ (Nat.succ_posₓ _) h) ne_n 
    symm 
    rw [←mem_singleton,
      eq_proper_divisors_of_subset_of_sum_eq_sum (singleton_subset_iff.2 (mem_proper_divisors.2 ⟨h, hlt⟩))
        sum_singleton,
      mem_proper_divisors]
    refine' ⟨one_dvd _, Nat.succ_lt_succₓ (Nat.succ_posₓ _)⟩

@[simp, toAdditive]
theorem prime.prod_proper_divisors {α : Type _} [CommMonoidₓ α] {p : ℕ} {f : ℕ → α} (h : p.prime) :
  (∏ x in p.proper_divisors, f x) = f 1 :=
  by 
    simp [h.proper_divisors]

@[simp, toAdditive]
theorem prime.prod_divisors {α : Type _} [CommMonoidₓ α] {p : ℕ} {f : ℕ → α} (h : p.prime) :
  (∏ x in p.divisors, f x) = f p*f 1 :=
  by 
    rw [divisors_eq_proper_divisors_insert_self_of_pos h.pos, prod_insert proper_divisors.not_self_mem,
      h.prod_proper_divisors]

theorem proper_divisors_eq_singleton_one_iff_prime : n.proper_divisors = {1} ↔ n.prime :=
  ⟨fun h =>
      by 
        have h1 := mem_singleton.2 rfl 
        rw [←h, mem_proper_divisors] at h1 
        refine' ⟨h1.2, _⟩
        intro m hdvd 
        rw [←mem_singleton, ←h, mem_proper_divisors]
        cases lt_or_eq_of_leₓ (Nat.le_of_dvdₓ (lt_transₓ (Nat.succ_posₓ _) h1.2) hdvd)
        ·
          left 
          exact ⟨hdvd, h_1⟩
        ·
          right 
          exact h_1,
    prime.proper_divisors⟩

theorem sum_proper_divisors_eq_one_iff_prime : (∑ x in n.proper_divisors, x) = 1 ↔ n.prime :=
  by 
    cases n
    ·
      simp [Nat.not_prime_zero]
    cases n
    ·
      simp [Nat.not_prime_one]
    rw [←proper_divisors_eq_singleton_one_iff_prime]
    refine' ⟨fun h => _, fun h => h.symm ▸ sum_singleton⟩
    rw [@eq_comm (Finset ℕ) _ _]
    apply
      eq_proper_divisors_of_subset_of_sum_eq_sum
        (singleton_subset_iff.2 (one_mem_proper_divisors_iff_one_lt.2 (succ_lt_succ (Nat.succ_posₓ _))))
        (Eq.trans sum_singleton h.symm)

theorem mem_proper_divisors_prime_pow {p : ℕ} (pp : p.prime) (k : ℕ) {x : ℕ} :
  x ∈ proper_divisors (p ^ k) ↔ ∃ (j : ℕ)(H : j < k), x = p ^ j :=
  by 
    rw [mem_proper_divisors, Nat.dvd_prime_pow pp, ←exists_and_distrib_right]
    simp only [exists_prop, and_assoc]
    apply exists_congr 
    intro a 
    constructor <;> intro h
    ·
      rcases h with ⟨h_left, rfl, h_right⟩
      rwa [pow_lt_pow_iff pp.one_lt] at h_right 
      simpa
    ·
      rcases h with ⟨h_left, rfl⟩
      rwa [pow_lt_pow_iff pp.one_lt]
      simp [h_left, le_of_ltₓ]

theorem proper_divisors_prime_pow {p : ℕ} (pp : p.prime) (k : ℕ) :
  proper_divisors (p ^ k) = (Finset.range k).map ⟨pow p, pow_right_injective pp.two_le⟩ :=
  by 
    ext 
    simp [mem_proper_divisors_prime_pow, pp, Nat.lt_succ_iff, @eq_comm _ a]

@[simp, toAdditive]
theorem prod_proper_divisors_prime_pow {α : Type _} [CommMonoidₓ α] {k p : ℕ} {f : ℕ → α} (h : p.prime) :
  (∏ x in (p ^ k).properDivisors, f x) = ∏ x in range k, f (p ^ x) :=
  by 
    simp [h, proper_divisors_prime_pow]

@[simp, toAdditive]
theorem prod_divisors_prime_pow {α : Type _} [CommMonoidₓ α] {k p : ℕ} {f : ℕ → α} (h : p.prime) :
  (∏ x in (p ^ k).divisors, f x) = ∏ x in range (k+1), f (p ^ x) :=
  by 
    simp [h, divisors_prime_pow]

@[simp]
theorem filter_dvd_eq_divisors {n : ℕ} (h : n ≠ 0) :
  Finset.filter (fun x : ℕ => x ∣ n) (Finset.range (n : ℕ).succ) = (n : ℕ).divisors :=
  by 
    apply Finset.ext 
    simp only [h, mem_filter, and_trueₓ, and_iff_right_iff_imp, cast_id, mem_range, Ne.def, not_false_iff, mem_divisors]
    intro a ha 
    exact Nat.lt_succ_of_leₓ (Nat.divisor_le (Nat.mem_divisors.2 ⟨ha, h⟩))

/-- The factors of `n` are the prime divisors -/
theorem prime_divisors_eq_to_filter_divisors_prime (n : ℕ) : n.factors.to_finset = (divisors n).filter prime :=
  by 
    rcases n.eq_zero_or_pos with (rfl | hn)
    ·
      simp 
    ·
      ext q 
      simpa [hn, hn.ne', mem_factors] using and_comm (prime q) (q ∣ n)

end Nat

