/-
Copyright (c) 2019 Kevin Kappelmann. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Kappelmann, Kyle Miller, Mario Carneiro
-/
import Mathbin.Data.Nat.Gcd
import Mathbin.Logic.Function.Iterate
import Mathbin.Data.Finset.NatAntidiagonal
import Mathbin.Algebra.BigOperators.Basic
import Mathbin.Tactic.Ring
import Mathbin.Tactic.Zify

/-!
# The Fibonacci Sequence

## Summary

Definition of the Fibonacci sequence `F₀ = 0, F₁ = 1, Fₙ₊₂ = Fₙ + Fₙ₊₁`.

## Main Definitions

- `nat.fib` returns the stream of Fibonacci numbers.

## Main Statements

- `nat.fib_add_two`: shows that `fib` indeed satisfies the Fibonacci recurrence `Fₙ₊₂ = Fₙ + Fₙ₊₁.`.
- `nat.fib_gcd`: `fib n` is a strong divisibility sequence.
- `nat.fib_succ_eq_sum_choose`: `fib` is given by the sum of `nat.choose` along an antidiagonal.
- `nat.fib_succ_eq_succ_sum`: shows that `F₀ + F₁ + ⋯ + Fₙ = Fₙ₊₂ - 1`.
- `nat.fib_two_mul` and `nat.fib_two_mul_add_one` are the basis for an efficient algorithm to
  compute `fib` (see `nat.fast_fib`). There are `bit0`/`bit1` variants of these can be used to
  simplify `fib` expressions: `simp only [nat.fib_bit0, nat.fib_bit1, nat.fib_bit0_succ,
  nat.fib_bit1_succ, nat.fib_one, nat.fib_two]`.

## Implementation Notes

For efficiency purposes, the sequence is defined using `stream.iterate`.

## Tags

fib, fibonacci
-/


open BigOperators

namespace Nat

/-- Implementation of the fibonacci sequence satisfying
`fib 0 = 0, fib 1 = 1, fib (n + 2) = fib n + fib (n + 1)`.

*Note:* We use a stream iterator for better performance when compared to the naive recursive
implementation.
-/
@[pp_nodot]
def fib (n : ℕ) : ℕ :=
  (((fun p : ℕ × ℕ => (p.snd, p.fst + p.snd))^[n]) (0, 1)).fst

@[simp]
theorem fib_zero : fib 0 = 0 :=
  rfl

@[simp]
theorem fib_one : fib 1 = 1 :=
  rfl

@[simp]
theorem fib_two : fib 2 = 1 :=
  rfl

/-- Shows that `fib` indeed satisfies the Fibonacci recurrence `Fₙ₊₂ = Fₙ + Fₙ₊₁.` -/
theorem fib_add_two {n : ℕ} : fib (n + 2) = fib n + fib (n + 1) := by
  simp only [fib, Function.iterate_succ']

theorem fib_le_fib_succ {n : ℕ} : fib n ≤ fib (n + 1) := by
  cases n <;> simp [fib_add_two]

@[mono]
theorem fib_mono : Monotone fib :=
  monotone_nat_of_le_succ fun _ => fib_le_fib_succ

theorem fib_pos {n : ℕ} (n_pos : 0 < n) : 0 < fib n :=
  calc
    0 < fib 1 := by
      decide
    _ ≤ fib n := fib_mono n_pos
    

theorem fib_add_two_sub_fib_add_one {n : ℕ} : fib (n + 2) - fib (n + 1) = fib n := by
  rw [fib_add_two, add_tsub_cancel_right]

theorem fib_lt_fib_succ {n : ℕ} (hn : 2 ≤ n) : fib n < fib (n + 1) := by
  rcases exists_add_of_le hn with ⟨n, rfl⟩
  rw [← tsub_pos_iff_lt, add_commₓ 2, fib_add_two_sub_fib_add_one]
  apply fib_pos (succ_pos n)

/-- `fib (n + 2)` is strictly monotone. -/
theorem fib_add_two_strict_mono : StrictMono fun n => fib (n + 2) := by
  refine' strict_mono_nat_of_lt_succ fun n => _
  rw [add_right_commₓ]
  exact fib_lt_fib_succ (self_le_add_left _ _)

theorem le_fib_self {n : ℕ} (five_le_n : 5 ≤ n) : n ≤ fib n := by
  induction' five_le_n with n five_le_n IH
  · -- 5 ≤ fib 5
    rfl
    
  · -- n + 1 ≤ fib (n + 1) for 5 ≤ n
    rw [succ_le_iff]
    calc
      n ≤ fib n := IH
      _ < fib (n + 1) :=
        fib_lt_fib_succ
          (le_transₓ
            (by
              decide)
            five_le_n)
      
    

/-- Subsequent Fibonacci numbers are coprime,
  see https://proofwiki.org/wiki/Consecutive_Fibonacci_Numbers_are_Coprime -/
theorem fib_coprime_fib_succ (n : ℕ) : Nat.Coprime (fib n) (fib (n + 1)) := by
  induction' n with n ih
  · simp
    
  · rw [fib_add_two, coprime_add_self_right]
    exact ih.symm
    

/-- See https://proofwiki.org/wiki/Fibonacci_Number_in_terms_of_Smaller_Fibonacci_Numbers -/
theorem fib_add (m n : ℕ) : fib (m + n + 1) = fib m * fib n + fib (m + 1) * fib (n + 1) := by
  induction' n with n ih generalizing m
  · simp
    
  · intros
    specialize ih (m + 1)
    rw [add_assocₓ m 1 n, add_commₓ 1 n] at ih
    simp only [fib_add_two, ih]
    ring
    

theorem fib_two_mul (n : ℕ) : fib (2 * n) = fib n * (2 * fib (n + 1) - fib n) := by
  cases n
  · simp
    
  · rw [Nat.succ_eq_add_one, two_mul, ← add_assocₓ, fib_add, fib_add_two, two_mul]
    simp only [← add_assocₓ, add_tsub_cancel_right]
    ring
    

theorem fib_two_mul_add_one (n : ℕ) : fib (2 * n + 1) = fib (n + 1) ^ 2 + fib n ^ 2 := by
  rw [two_mul, fib_add]
  ring

theorem fib_bit0 (n : ℕ) : fib (bit0 n) = fib n * (2 * fib (n + 1) - fib n) := by
  rw [bit0_eq_two_mul, fib_two_mul]

theorem fib_bit1 (n : ℕ) : fib (bit1 n) = fib (n + 1) ^ 2 + fib n ^ 2 := by
  rw [Nat.bit1_eq_succ_bit0, bit0_eq_two_mul, fib_two_mul_add_one]

theorem fib_bit0_succ (n : ℕ) : fib (bit0 n + 1) = fib (n + 1) ^ 2 + fib n ^ 2 :=
  fib_bit1 n

theorem fib_bit1_succ (n : ℕ) : fib (bit1 n + 1) = fib (n + 1) * (2 * fib n + fib (n + 1)) := by
  rw [Nat.bit1_eq_succ_bit0, fib_add_two, fib_bit0, fib_bit0_succ]
  have : fib n ≤ 2 * fib (n + 1) := by
    rw [two_mul]
    exact le_add_left fib_le_fib_succ
  zify
  ring

/-- Computes `(nat.fib n, nat.fib (n + 1))` using the binary representation of `n`.
Supports `nat.fast_fib`. -/
def fastFibAux : ℕ → ℕ × ℕ :=
  Nat.binaryRec (fib 0, fib 1) fun b n p =>
    if b then (p.2 ^ 2 + p.1 ^ 2, p.2 * (2 * p.1 + p.2)) else (p.1 * (2 * p.2 - p.1), p.2 ^ 2 + p.1 ^ 2)

/-- Computes `nat.fib n` using the binary representation of `n`.
Proved to be equal to `nat.fib` in `nat.fast_fib_eq`. -/
def fastFib (n : ℕ) : ℕ :=
  (fastFibAux n).1

theorem fast_fib_aux_bit_ff (n : ℕ) :
    fastFibAux (bit false n) =
      let p := fastFibAux n
      (p.1 * (2 * p.2 - p.1), p.2 ^ 2 + p.1 ^ 2) :=
  by
  rw [fast_fib_aux, binary_rec_eq]
  · rfl
    
  · simp
    

theorem fast_fib_aux_bit_tt (n : ℕ) :
    fastFibAux (bit true n) =
      let p := fastFibAux n
      (p.2 ^ 2 + p.1 ^ 2, p.2 * (2 * p.1 + p.2)) :=
  by
  rw [fast_fib_aux, binary_rec_eq]
  · rfl
    
  · simp
    

theorem fast_fib_aux_eq (n : ℕ) : fastFibAux n = (fib n, fib (n + 1)) := by
  apply Nat.binaryRec _ (fun b n' ih => _) n
  · simp [fast_fib_aux]
    
  · cases b <;>
      simp only [fast_fib_aux_bit_ff, fast_fib_aux_bit_tt, congr_argₓ Prod.fst ih, congr_argₓ Prod.snd ih,
          Prod.mk.inj_iffₓ] <;>
        constructor <;> simp [bit, fib_bit0, fib_bit1, fib_bit0_succ, fib_bit1_succ]
    

theorem fast_fib_eq (n : ℕ) : fastFib n = fib n := by
  rw [fast_fib, fast_fib_aux_eq]

theorem gcd_fib_add_self (m n : ℕ) : gcdₓ (fib m) (fib (n + m)) = gcdₓ (fib m) (fib n) := by
  cases Nat.eq_zero_or_posₓ n
  · rw [h]
    simp
    
  replace h := Nat.succ_pred_eq_of_posₓ h
  rw [← h, succ_eq_add_one]
  calc
    gcd (fib m) (fib (n.pred + 1 + m)) = gcd (fib m) (fib n.pred * fib m + fib (n.pred + 1) * fib (m + 1)) := by
      rw [← fib_add n.pred _]
      ring_nf
    _ = gcd (fib m) (fib (n.pred + 1) * fib (m + 1)) := by
      rw [add_commₓ, gcd_add_mul_right_right (fib m) _ (fib n.pred)]
    _ = gcd (fib m) (fib (n.pred + 1)) :=
      coprime.gcd_mul_right_cancel_right (fib (n.pred + 1)) (coprime.symm (fib_coprime_fib_succ m))
    

theorem gcd_fib_add_mul_self (m n : ℕ) : ∀ k, gcdₓ (fib m) (fib (n + k * m)) = gcdₓ (fib m) (fib n)
  | 0 => by
    simp
  | k + 1 => by
    rw [← gcd_fib_add_mul_self k, add_mulₓ, ← add_assocₓ, one_mulₓ, gcd_fib_add_self _ _]

/-- `fib n` is a strong divisibility sequence,
  see https://proofwiki.org/wiki/GCD_of_Fibonacci_Numbers -/
theorem fib_gcd (m n : ℕ) : fib (gcdₓ m n) = gcdₓ (fib m) (fib n) := by
  wlog h : m ≤ n using n m, m n
  exact le_totalₓ m n
  · apply gcd.induction m n
    · simp
      
    intro m n mpos h
    rw [← gcd_rec m n] at h
    conv_rhs => rw [← mod_add_div' n m]
    rwa [gcd_fib_add_mul_self m (n % m) (n / m), gcd_comm (fib m) _]
    
  rwa [gcd_comm, gcd_comm (fib m)]

theorem fib_dvd (m n : ℕ) (h : m ∣ n) : fib m ∣ fib n := by
  rwa [gcd_eq_left_iff_dvd, ← fib_gcd, gcd_eq_left_iff_dvd.mp]

theorem fib_succ_eq_sum_choose : ∀ n : ℕ, fib (n + 1) = ∑ p in Finset.Nat.antidiagonal n, choose p.1 p.2 :=
  twoStepInduction rfl rfl fun n h1 h2 => by
    rw [fib_add_two, h1, h2, Finset.Nat.antidiagonal_succ_succ', Finset.Nat.antidiagonal_succ']
    simp [choose_succ_succ, Finset.sum_add_distrib, add_left_commₓ]

theorem fib_succ_eq_succ_sum (n : ℕ) : fib (n + 1) = (∑ k in Finset.range n, fib k) + 1 := by
  induction' n with n ih
  · simp
    
  · calc
      fib (n + 2) = fib n + fib (n + 1) := fib_add_two
      _ = (fib n + ∑ k in Finset.range n, fib k) + 1 := by
        rw [ih, add_assocₓ]
      _ = (∑ k in Finset.range (n + 1), fib k) + 1 := by
        simp [Finset.range_add_one]
      
    

end Nat

namespace NormNum

open Tactic Nat

/-! ### `norm_num` plugin for `fib`

The `norm_num` plugin uses a strategy parallel to that of `nat.fast_fib`, but it instead
produces proofs of what `nat.fib` evaluates to.
-/


/-- Auxiliary definition for `prove_fib` plugin. -/
def IsFibAux (n a b : ℕ) :=
  fib n = a ∧ fib (n + 1) = b

theorem is_fib_aux_one : IsFibAux 1 1 1 :=
  ⟨fib_one, fib_two⟩

theorem is_fib_aux_bit0 {n a b c a2 b2 a' b' : ℕ} (H : IsFibAux n a b) (h1 : a + c = bit0 b) (h2 : a * c = a')
    (h3 : a * a = a2) (h4 : b * b = b2) (h5 : a2 + b2 = b') : IsFibAux (bit0 n) a' b' :=
  ⟨by
    rw [fib_bit0, H.1, H.2, ← bit0_eq_two_mul,
      show bit0 b - a = c by
        rw [← h1, Nat.add_sub_cancel_left],
      h2],
    by
    rw [fib_bit0_succ, H.1, H.2, pow_two, pow_two, h3, h4, add_commₓ, h5]⟩

theorem is_fib_aux_bit1 {n a b c a2 b2 a' b' : ℕ} (H : IsFibAux n a b) (h1 : a * a = a2) (h2 : b * b = b2)
    (h3 : a2 + b2 = a') (h4 : bit0 a + b = c) (h5 : b * c = b') : IsFibAux (bit1 n) a' b' :=
  ⟨by
    rw [fib_bit1, H.1, H.2, pow_two, pow_two, h1, h2, add_commₓ, h3], by
    rw [fib_bit1_succ, H.1, H.2, ← bit0_eq_two_mul, h4, h5]⟩

theorem is_fib_aux_bit0_done {n a b c a' : ℕ} (H : IsFibAux n a b) (h1 : a + c = bit0 b) (h2 : a * c = a') :
    fib (bit0 n) = a' :=
  (is_fib_aux_bit0 H h1 h2 rfl rfl rfl).1

theorem is_fib_aux_bit1_done {n a b a2 b2 a' : ℕ} (H : IsFibAux n a b) (h1 : a * a = a2) (h2 : b * b = b2)
    (h3 : a2 + b2 = a') : fib (bit1 n) = a' :=
  (is_fib_aux_bit1 H h1 h2 h3 rfl rfl).1

/-- `prove_fib_aux ic n` returns `(ic', a, b, ⊢ is_fib_aux n a b)`, where `n` is a numeral. -/
unsafe def prove_fib_aux (ic : instance_cache) : expr → tactic (instance_cache × expr × expr × expr)
  | e =>
    match match_numeral e with
    | match_numeral_result.one => pure (ic, quote.1 (1 : ℕ), quote.1 (1 : ℕ), quote.1 is_fib_aux_one)
    | match_numeral_result.bit0 e => do
      let (ic, a, b, H) ← prove_fib_aux e
      let na ← a.toNat
      let nb ← b.toNat
      let (ic, c) ← ic.ofNat (2 * nb - na)
      let (ic, h1) ← prove_add_nat ic a c ((quote.1 (bit0 : ℕ → ℕ)).mk_app [b])
      let (ic, a', h2) ← prove_mul_nat ic a c
      let (ic, a2, h3) ← prove_mul_nat ic a a
      let (ic, b2, h4) ← prove_mul_nat ic b b
      let (ic, b', h5) ← prove_add_nat' ic a2 b2
      pure (ic, a', b', (quote.1 @is_fib_aux_bit0).mk_app [e, a, b, c, a2, b2, a', b', H, h1, h2, h3, h4, h5])
    | match_numeral_result.bit1 e => do
      let (ic, a, b, H) ← prove_fib_aux e
      let na ← a.toNat
      let nb ← b.toNat
      let (ic, c) ← ic.ofNat (2 * na + nb)
      let (ic, a2, h1) ← prove_mul_nat ic a a
      let (ic, b2, h2) ← prove_mul_nat ic b b
      let (ic, a', h3) ← prove_add_nat' ic a2 b2
      let (ic, h4) ← prove_add_nat ic ((quote.1 (bit0 : ℕ → ℕ)).mk_app [a]) b c
      let (ic, b', h5) ← prove_mul_nat ic b c
      pure (ic, a', b', (quote.1 @is_fib_aux_bit1).mk_app [e, a, b, c, a2, b2, a', b', H, h1, h2, h3, h4, h5])
    | _ => failed

/-- A `norm_num` plugin for `fib n` when `n` is a numeral.
Uses the binary representation of `n` like `nat.fast_fib`. -/
unsafe def prove_fib (ic : instance_cache) (e : expr) : tactic (instance_cache × expr × expr) :=
  match match_numeral e with
  | match_numeral_result.zero => pure (ic, quote.1 (0 : ℕ), quote.1 fib_zero)
  | match_numeral_result.one => pure (ic, quote.1 (1 : ℕ), quote.1 fib_one)
  | match_numeral_result.bit0 e => do
    let (ic, a, b, H) ← prove_fib_aux ic e
    let na ← a.toNat
    let nb ← b.toNat
    let (ic, c) ← ic.ofNat (2 * nb - na)
    let (ic, h1) ← prove_add_nat ic a c ((quote.1 (bit0 : ℕ → ℕ)).mk_app [b])
    let (ic, a', h2) ← prove_mul_nat ic a c
    pure (ic, a', (quote.1 @is_fib_aux_bit0_done).mk_app [e, a, b, c, a', H, h1, h2])
  | match_numeral_result.bit1 e => do
    let (ic, a, b, H) ← prove_fib_aux ic e
    let (ic, a2, h1) ← prove_mul_nat ic a a
    let (ic, b2, h2) ← prove_mul_nat ic b b
    let (ic, a', h3) ← prove_add_nat' ic a2 b2
    pure (ic, a', (quote.1 @is_fib_aux_bit1_done).mk_app [e, a, b, a2, b2, a', H, h1, h2, h3])
  | _ => failed

/-- A `norm_num` plugin for `fib n` when `n` is a numeral.
Uses the binary representation of `n` like `nat.fast_fib`. -/
@[norm_num]
unsafe def eval_fib : expr → tactic (expr × expr)
  | quote.1 (fib (%%ₓen)) => do
    let n ← en.toNat
    match n with
      | 0 => pure (quote.1 (0 : ℕ), quote.1 fib_zero)
      | 1 => pure (quote.1 (1 : ℕ), quote.1 fib_one)
      | 2 => pure (quote.1 (1 : ℕ), quote.1 fib_two)
      | _ => do
        let c ← mk_instance_cache (quote.1 ℕ)
        Prod.snd <$> prove_fib c en
  | _ => failed

end NormNum

