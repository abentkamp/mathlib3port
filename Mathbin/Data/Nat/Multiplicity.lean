import Mathbin.Algebra.BigOperators.Intervals 
import Mathbin.Algebra.GeomSum 
import Mathbin.Data.Nat.Bitwise 
import Mathbin.Data.Nat.Log 
import Mathbin.Data.Nat.Parity 
import Mathbin.RingTheory.Int.Basic

/-!
# Natural number multiplicity

This file contains lemmas about the multiplicity function (the maximum prime power dividing a
number) when applied to naturals, in particular calculating it for factorials and binomial
coefficients.

## Multiplicity calculations

* `nat.multiplicity_factorial`: Legendre's Theorem. The multiplicity of `p` in `n!` is
  `n/p + ... + n/p^b` for any `b` such that `n/p^(b + 1) = 0`.
* `nat.multiplicity_factorial_mul`: The multiplicity of `p` in `(p * n)!` is `n` more than that of
  `n!`.
* `nat.multiplicity_choose`: The multiplicity of `p` in `n.choose k` is the number of carries when
  `k` and`n - k` are added in base `p`.

## Other declarations

* `nat.multiplicity_eq_card_pow_dvd`: The multiplicity of `m` in `n` is the number of positive
  natural numbers `i` such that `m ^ i` divides `n`.
* `nat.multiplicity_two_factorial_lt`: The multiplicity of `2` in `n!` is strictly less than `n`.
* `nat.prime.multiplicity_something`: Specialization of `multiplicity.something` to a prime in the
  naturals. Avoids having to provide `p ≠ 1` and other trivialities, along with translating between
  `prime` and `nat.prime`.

## Tags

Legendre, p-adic
-/


open Finset Nat multiplicity

open_locale BigOperators Nat

namespace Nat

/-- The multiplicity of `m` in `n` is the number of positive natural numbers `i` such that `m ^ i`
divides `n`. This set is expressed by filtering `Ico 1 b` where `b` is any bound greater than
`log m n`. -/
theorem multiplicity_eq_card_pow_dvd {m n b : ℕ} (hm : m ≠ 1) (hn : 0 < n) (hb : log m n < b) :
  multiplicity m n = «expr↑ » ((Finset.ico 1 b).filter fun i => (m^i) ∣ n).card :=
  calc multiplicity m n = «expr↑ » (Ico 1$ (multiplicity m n).get (finite_nat_iff.2 ⟨hm, hn⟩)+1).card :=
    by 
      simp 
    _ = «expr↑ » ((Finset.ico 1 b).filter fun i => (m^i) ∣ n).card :=
    congr_argₓ coeₓ$
      congr_argₓ card$
        Finset.ext$
          fun i =>
            by 
              rw [mem_filter, mem_Ico, mem_Ico, lt_succ_iff, ←@Enat.coe_le_coe i, Enat.coe_get,
                ←pow_dvd_iff_le_multiplicity, And.right_comm]
              refine' (and_iff_left_of_imp fun h => _).symm 
              cases m
              ·
                rw [zero_pow, zero_dvd_iff] at h 
                exact (hn.ne' h.2).elim
                ·
                  exact h.1 
              exact
                ((pow_le_iff_le_log (succ_lt_succ$ Nat.pos_of_ne_zeroₓ$ succ_ne_succ.1 hm) hn).1$
                      le_of_dvd hn h.2).trans_lt
                  hb
    

namespace Prime

theorem multiplicity_one {p : ℕ} (hp : p.prime) : multiplicity p 1 = 0 :=
  multiplicity.one_right (prime_iff.mp hp).not_unit

theorem multiplicity_mul {p m n : ℕ} (hp : p.prime) : multiplicity p (m*n) = multiplicity p m+multiplicity p n :=
  multiplicity.mul$ prime_iff.mp hp

theorem multiplicity_pow {p m n : ℕ} (hp : p.prime) : multiplicity p (m^n) = n • multiplicity p m :=
  multiplicity.pow$ prime_iff.mp hp

theorem multiplicity_self {p : ℕ} (hp : p.prime) : multiplicity p p = 1 :=
  multiplicity_self (prime_iff.mp hp).not_unit hp.ne_zero

theorem multiplicity_pow_self {p n : ℕ} (hp : p.prime) : multiplicity p (p^n) = n :=
  multiplicity_pow_self hp.ne_zero (prime_iff.mp hp).not_unit n

/-- **Legendre's Theorem**

The multiplicity of a prime in `n!` is the sum of the quotients `n / p ^ i`. This sum is expressed
over the finset `Ico 1 b` where `b` is any bound greater than `log p n`. -/
theorem multiplicity_factorial {p : ℕ} (hp : p.prime) :
  ∀ {n b : ℕ}, log p n < b → multiplicity p n ! = (∑i in Ico 1 b, n / (p^i) : ℕ)
| 0, b, hb =>
  by 
    simp [Ico, hp.multiplicity_one]
| n+1, b, hb =>
  calc multiplicity p (n+1)! = multiplicity p n !+multiplicity p (n+1) :=
    by 
      rw [factorial_succ, hp.multiplicity_mul, add_commₓ]
    _ = (∑i in Ico 1 b, n / (p^i) : ℕ)+((Finset.ico 1 b).filter fun i => (p^i) ∣ n+1).card :=
    by 
      rw [multiplicity_factorial ((log_le_log_of_le$ le_succ _).trans_lt hb),
        ←multiplicity_eq_card_pow_dvd hp.ne_one (succ_pos _) hb]
    _ = (∑i in Ico 1 b, (n / (p^i))+if (p^i) ∣ n+1 then 1 else 0 : ℕ) :=
    by 
      rw [sum_add_distrib, sum_boole]
      simp 
    _ = (∑i in Ico 1 b, (n+1) / (p^i) : ℕ) := congr_argₓ coeₓ$ Finset.sum_congr rfl$ fun _ _ => (succ_div _ _).symm
    

-- error in Data.Nat.Multiplicity: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- The multiplicity of `p` in `(p * (n + 1))!` is one more than the sum
  of the multiplicities of `p` in `(p * n)!` and `n + 1`. -/
theorem multiplicity_factorial_mul_succ
{n p : exprℕ()}
(hp : p.prime) : «expr = »(multiplicity p «expr !»(«expr * »(p, «expr + »(n, 1))), «expr + »(«expr + »(multiplicity p «expr !»(«expr * »(p, n)), multiplicity p «expr + »(n, 1)), 1)) :=
begin
  have [ident hp'] [] [":=", expr prime_iff.mp hp],
  have [ident h0] [":", expr «expr ≤ »(2, p)] [":=", expr hp.two_le],
  have [ident h1] [":", expr «expr ≤ »(1, «expr + »(«expr * »(p, n), 1))] [":=", expr nat.le_add_left _ _],
  have [ident h2] [":", expr «expr ≤ »(«expr + »(«expr * »(p, n), 1), «expr * »(p, «expr + »(n, 1)))] [],
  linarith [] [] [],
  have [ident h3] [":", expr «expr ≤ »(«expr + »(«expr * »(p, n), 1), «expr + »(«expr * »(p, «expr + »(n, 1)), 1))] [],
  linarith [] [] [],
  have [ident hm] [":", expr «expr ≠ »(multiplicity p «expr !»(«expr * »(p, n)), «expr⊤»())] [],
  { rw ["[", expr ne.def, ",", expr eq_top_iff_not_finite, ",", expr not_not, ",", expr finite_nat_iff, "]"] [],
    exact [expr ⟨hp.ne_one, factorial_pos _⟩] },
  revert [ident hm],
  have [ident h4] [":", expr ∀
   m «expr ∈ » Ico «expr + »(«expr * »(p, n), 1) «expr * »(p, «expr + »(n, 1)), «expr = »(multiplicity p m, 0)] [],
  { intros [ident m, ident hm],
    apply [expr multiplicity_eq_zero_of_not_dvd],
    rw ["[", "<-", expr exists_lt_and_lt_iff_not_dvd _ (pos_iff_ne_zero.mpr hp.ne_zero), "]"] [],
    rw ["[", expr mem_Ico, "]"] ["at", ident hm],
    exact [expr ⟨n, lt_of_succ_le hm.1, hm.2⟩] },
  simp_rw ["[", "<-", expr prod_Ico_id_eq_factorial, ",", expr multiplicity.finset.prod hp', ",", "<-", expr sum_Ico_consecutive _ h1 h3, ",", expr add_assoc, "]"] [],
  intro [ident h],
  rw ["[", expr enat.add_left_cancel_iff h, ",", expr sum_Ico_succ_top h2, ",", expr multiplicity.mul hp', ",", expr hp.multiplicity_self, ",", expr sum_congr rfl h4, ",", expr sum_const_zero, ",", expr zero_add, ",", expr add_comm (1 : enat), "]"] []
end

/-- The multiplicity of `p` in `(p * n)!` is `n` more than that of `n!`. -/
theorem multiplicity_factorial_mul {n p : ℕ} (hp : p.prime) : multiplicity p (p*n)! = multiplicity p n !+n :=
  by 
    induction' n with n ih
    ·
      simp 
    ·
      simp only [succ_eq_add_one, multiplicity.mul, hp, prime_iff.mp hp, ih, multiplicity_factorial_mul_succ,
        ←add_assocₓ, Nat.cast_one, Nat.cast_add, factorial_succ]
      congr 1
      rw [add_commₓ, add_assocₓ]

/-- A prime power divides `n!` iff it is at most the sum of the quotients `n / p ^ i`.
  This sum is expressed over the set `Ico 1 b` where `b` is any bound greater than `log p n` -/
theorem pow_dvd_factorial_iff {p : ℕ} {n r b : ℕ} (hp : p.prime) (hbn : log p n < b) :
  (p^r) ∣ n ! ↔ r ≤ ∑i in Ico 1 b, n / (p^i) :=
  by 
    rw [←Enat.coe_le_coe, ←hp.multiplicity_factorial hbn, ←pow_dvd_iff_le_multiplicity]

theorem multiplicity_factorial_le_div_pred {p : ℕ} (hp : p.prime) (n : ℕ) : multiplicity p n ! ≤ (n / (p - 1) : ℕ) :=
  by 
    rw [hp.multiplicity_factorial (lt_succ_self _), Enat.coe_le_coe]
    exact Nat.geom_sum_Ico_le hp.two_le _ _

theorem multiplicity_choose_aux {p n b k : ℕ} (hp : p.prime) (hkn : k ≤ n) :
  (∑i in Finset.ico 1 b, n / (p^i)) =
    ((∑i in Finset.ico 1 b,
          k /
            (p^i))+∑i in Finset.ico 1 b,
          (n - k) / (p^i))+((Finset.ico 1 b).filter fun i => (p^i) ≤ (k % (p^i))+(n - k) % (p^i)).card :=
  calc (∑i in Finset.ico 1 b, n / (p^i)) = ∑i in Finset.ico 1 b, (k+n - k) / (p^i) :=
    by 
      simp only [add_tsub_cancel_of_le hkn]
    _ = ∑i in Finset.ico 1 b, ((k / (p^i))+(n - k) / (p^i))+if (p^i) ≤ (k % (p^i))+(n - k) % (p^i) then 1 else 0 :=
    by 
      simp only [Nat.add_div (pow_pos hp.pos _)]
    _ = _ :=
    by 
      simp [sum_add_distrib, sum_boole]
    

/-- The multiplicity of `p` in `choose n k` is the number of carries when `k` and `n - k`
  are added in base `p`. The set is expressed by filtering `Ico 1 b` where `b`
  is any bound greater than `log p n`. -/
theorem multiplicity_choose {p n k b : ℕ} (hp : p.prime) (hkn : k ≤ n) (hnb : log p n < b) :
  multiplicity p (choose n k) = ((Ico 1 b).filter fun i => (p^i) ≤ (k % (p^i))+(n - k) % (p^i)).card :=
  have h₁ :
    (multiplicity p (choose n k)+multiplicity p (k !*(n - k)!)) =
      ((Finset.ico 1 b).filter fun i => (p^i) ≤ (k % (p^i))+(n - k) % (p^i)).card+multiplicity p (k !*(n - k)!) :=
    by 
      rw [←hp.multiplicity_mul, ←mul_assocₓ, choose_mul_factorial_mul_factorial hkn, hp.multiplicity_factorial hnb,
        hp.multiplicity_mul, hp.multiplicity_factorial ((log_le_log_of_le hkn).trans_lt hnb),
        hp.multiplicity_factorial (lt_of_le_of_ltₓ (log_le_log_of_le tsub_le_self) hnb), multiplicity_choose_aux hp hkn]
      simp [add_commₓ]
  (Enat.add_right_cancel_iff
        (Enat.ne_top_iff_dom.2$
          by 
            exact finite_nat_iff.2 ⟨ne_of_gtₓ hp.one_lt, mul_pos (factorial_pos k) (factorial_pos (n - k))⟩)).1
    h₁

-- error in Data.Nat.Multiplicity: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- A lower bound on the multiplicity of `p` in `choose n k`. -/
theorem multiplicity_le_multiplicity_choose_add
{p : exprℕ()}
(hp : p.prime)
(n k : exprℕ()) : «expr ≤ »(multiplicity p n, «expr + »(multiplicity p (choose n k), multiplicity p k)) :=
if hkn : «expr < »(n, k) then by simp [] [] [] ["[", expr choose_eq_zero_of_lt hkn, "]"] [] [] else if hk0 : «expr = »(k, 0) then by simp [] [] [] ["[", expr hk0, "]"] [] [] else if hn0 : «expr = »(n, 0) then by cases [expr k] []; simp [] [] [] ["[", expr hn0, ",", "*", "]"] [] ["at", "*"] else begin
  rw ["[", expr multiplicity_choose hp (le_of_not_gt hkn) (lt_succ_self _), ",", expr multiplicity_eq_card_pow_dvd (ne_of_gt hp.one_lt) (nat.pos_of_ne_zero hk0) (lt_succ_of_le (log_le_log_of_le (le_of_not_gt hkn))), ",", expr multiplicity_eq_card_pow_dvd (ne_of_gt hp.one_lt) (nat.pos_of_ne_zero hn0) (lt_succ_self _), ",", "<-", expr nat.cast_add, ",", expr enat.coe_le_coe, "]"] [],
  calc
    «expr ≤ »(((Ico 1 (log p n).succ).filter (λ
       i, «expr ∣ »(«expr ^ »(p, i), n))).card, «expr ∪ »((Ico 1 (log p n).succ).filter (λ
       i, «expr ≤ »(«expr ^ »(p, i), «expr + »(«expr % »(k, «expr ^ »(p, i)), «expr % »(«expr - »(n, k), «expr ^ »(p, i))))), (Ico 1 (log p n).succ).filter (λ
       i, «expr ∣ »(«expr ^ »(p, i), k))).card) : «expr $ »(card_le_of_subset, λ i, begin
       have [] [] [":=", expr @le_mod_add_mod_of_dvd_add_of_not_dvd k «expr - »(n, k) «expr ^ »(p, i)],
       simp [] [] [] ["[", expr add_tsub_cancel_of_le (le_of_not_gt hkn), "]"] [] ["at", "*"] { contextual := tt },
       tauto []
     end)
    «expr ≤ »(..., «expr + »(((Ico 1 (log p n).succ).filter (λ
        i, «expr ≤ »(«expr ^ »(p, i), «expr + »(«expr % »(k, «expr ^ »(p, i)), «expr % »(«expr - »(n, k), «expr ^ »(p, i)))))).card, ((Ico 1 (log p n).succ).filter (λ
        i, «expr ∣ »(«expr ^ »(p, i), k))).card)) : card_union_le _ _
end

-- error in Data.Nat.Multiplicity: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem multiplicity_choose_prime_pow
{p n k : exprℕ()}
(hp : p.prime)
(hkn : «expr ≤ »(k, «expr ^ »(p, n)))
(hk0 : «expr < »(0, k)) : «expr = »(«expr + »(multiplicity p (choose «expr ^ »(p, n) k), multiplicity p k), n) :=
le_antisymm (have hdisj : disjoint ((Ico 1 n.succ).filter (λ
   i, «expr ≤ »(«expr ^ »(p, i), «expr + »(«expr % »(k, «expr ^ »(p, i)), «expr % »(«expr - »(«expr ^ »(p, n), k), «expr ^ »(p, i)))))) ((Ico 1 n.succ).filter (λ
   i, «expr ∣ »(«expr ^ »(p, i), k))), by simp [] [] [] ["[", expr disjoint_right, ",", "*", ",", expr dvd_iff_mod_eq_zero, ",", expr nat.mod_lt _ (pow_pos hp.pos _), "]"] [] [] { contextual := tt },
 begin
   rw ["[", expr multiplicity_choose hp hkn (lt_succ_self _), ",", expr multiplicity_eq_card_pow_dvd (ne_of_gt hp.one_lt) hk0 (lt_succ_of_le (log_le_log_of_le hkn)), ",", "<-", expr nat.cast_add, ",", expr enat.coe_le_coe, ",", expr log_pow hp.one_lt, ",", "<-", expr card_disjoint_union hdisj, ",", expr filter_union_right, "]"] [],
   have [ident filter_le_Ico] [] [":=", expr (Ico 1 n.succ).card_filter_le _],
   rwa [expr card_Ico 1 n.succ] ["at", ident filter_le_Ico]
 end) (by rw ["[", "<-", expr hp.multiplicity_pow_self, "]"] []; exact [expr multiplicity_le_multiplicity_choose_add hp _ _])

end Prime

-- error in Data.Nat.Multiplicity: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem multiplicity_two_factorial_lt : ∀
{n : exprℕ()}
(h : «expr ≠ »(n, 0)), «expr < »(multiplicity 2 «expr !»(n), n) :=
begin
  have [ident h2] [] [":=", expr prime_iff.mp prime_two],
  refine [expr binary_rec _ _],
  { contradiction },
  { intros [ident b, ident n, ident ih, ident h],
    by_cases [expr hn, ":", expr «expr = »(n, 0)],
    { subst [expr hn],
      simp [] [] [] [] [] ["at", ident h],
      simp [] [] [] ["[", expr h, ",", expr one_right h2.not_unit, ",", expr enat.zero_lt_one, "]"] [] [] },
    have [] [":", expr «expr < »(multiplicity 2 «expr !»(«expr * »(2, n)), («expr * »(2, n) : exprℕ()))] [],
    { rw ["[", expr prime_two.multiplicity_factorial_mul, "]"] [],
      refine [expr (enat.add_lt_add_right (ih hn) (enat.coe_ne_top _)).trans_le _],
      rw ["[", expr two_mul, "]"] [],
      norm_cast [] },
    cases [expr b] [],
    { simpa [] [] [] ["[", expr bit0_eq_two_mul n, "]"] [] [] },
    { suffices [] [":", expr «expr < »(«expr + »(multiplicity 2 «expr + »(«expr * »(2, n), 1), multiplicity 2 «expr !»(«expr * »(2, n))), «expr + »(«expr↑ »(«expr * »(2, n)), 1))],
      { simpa [] [] [] ["[", expr succ_eq_add_one, ",", expr multiplicity.mul, ",", expr h2, ",", expr prime_two, ",", expr nat.bit1_eq_succ_bit0, ",", expr bit0_eq_two_mul n, "]"] [] [] },
      rw ["[", expr multiplicity_eq_zero_of_not_dvd (two_not_dvd_two_mul_add_one n), ",", expr zero_add, "]"] [],
      refine [expr this.trans _],
      exact_mod_cast [expr lt_succ_self _] } }
end

end Nat

