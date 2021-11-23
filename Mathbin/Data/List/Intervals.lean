import Mathbin.Data.List.Lattice 
import Mathbin.Data.List.Range

/-!
# Intervals in ℕ

This file defines intervals of naturals. `list.Ico m n` is the list of integers greater than `m`
and strictly less than `n`.

## TODO
- Define `Ioo` and `Icc`, state basic lemmas about them.
- Also do the versions for integers?
- One could generalise even further, defining 'locally finite partial orders', for which
  `set.Ico a b` is `[finite]`, and 'locally finite total orders', for which there is a list model.
- Once the above is done, get rid of `data.int.range` (and maybe `list.range'`?).
-/


open Nat

namespace List

/--
`Ico n m` is the list of natural numbers `n ≤ x < m`.
(Ico stands for "interval, closed-open".)

See also `data/set/intervals.lean` for `set.Ico`, modelling intervals in general preorders, and
`multiset.Ico` and `finset.Ico` for `n ≤ x < m` as a multiset or as a finset.
 -/
def Ico (n m : ℕ) : List ℕ :=
  range' n (m - n)

namespace Ico

theorem zero_bot (n : ℕ) : Ico 0 n = range n :=
  by 
    rw [Ico, tsub_zero, range_eq_range']

@[simp]
theorem length (n m : ℕ) : length (Ico n m) = m - n :=
  by 
    dsimp [Ico]
    simp only [length_range']

theorem pairwise_lt (n m : ℕ) : Pairwise (· < ·) (Ico n m) :=
  by 
    dsimp [Ico]
    simp only [pairwise_lt_range']

theorem nodup (n m : ℕ) : nodup (Ico n m) :=
  by 
    dsimp [Ico]
    simp only [nodup_range']

@[simp]
theorem mem {n m l : ℕ} : l ∈ Ico n m ↔ n ≤ l ∧ l < m :=
  suffices (n ≤ l ∧ l < n+m - n) ↔ n ≤ l ∧ l < m by 
    simp [Ico, this]
  by 
    cases' le_totalₓ n m with hnm hmn
    ·
      rw [add_tsub_cancel_of_le hnm]
    ·
      rw [tsub_eq_zero_iff_le.mpr hmn, add_zeroₓ]
      exact
        and_congr_right
          fun hnl => Iff.intro (fun hln => (not_le_of_gtₓ hln hnl).elim) fun hlm => lt_of_lt_of_leₓ hlm hmn

theorem eq_nil_of_le {n m : ℕ} (h : m ≤ n) : Ico n m = [] :=
  by 
    simp [Ico, tsub_eq_zero_iff_le.mpr h]

theorem map_add (n m k : ℕ) : (Ico n m).map ((·+·) k) = Ico (n+k) (m+k) :=
  by 
    rw [Ico, Ico, map_add_range', add_tsub_add_eq_tsub_right, add_commₓ n k]

theorem map_sub (n m k : ℕ) (h₁ : k ≤ n) : ((Ico n m).map fun x => x - k) = Ico (n - k) (m - k) :=
  by 
    byCases' h₂ : n < m
    ·
      rw [Ico, Ico]
      rw [tsub_tsub_tsub_cancel_right h₁]
      rw [map_sub_range' _ _ _ h₁]
    ·
      simp  at h₂ 
      rw [eq_nil_of_le h₂]
      rw [eq_nil_of_le (tsub_le_tsub_right h₂ _)]
      rfl

@[simp]
theorem self_empty {n : ℕ} : Ico n n = [] :=
  eq_nil_of_le (le_reflₓ n)

@[simp]
theorem eq_empty_iff {n m : ℕ} : Ico n m = [] ↔ m ≤ n :=
  Iff.intro
    (fun h =>
      tsub_eq_zero_iff_le.mp$
        by 
          rw [←length, h, List.length])
    eq_nil_of_le

theorem append_consecutive {n m l : ℕ} (hnm : n ≤ m) (hml : m ≤ l) : Ico n m ++ Ico m l = Ico n l :=
  by 
    dunfold Ico 
    convert range'_append _ _ _
    ·
      exact (add_tsub_cancel_of_le hnm).symm
    ·
      rwa [←add_tsub_assoc_of_le hnm, tsub_add_cancel_of_le]

@[simp]
theorem inter_consecutive (n m l : ℕ) : Ico n m ∩ Ico m l = [] :=
  by 
    apply eq_nil_iff_forall_not_mem.2
    intro a 
    simp only [and_imp, not_and, not_ltₓ, List.mem_inter, List.ico.mem]
    intro h₁ h₂ h₃ 
    exfalso 
    exact not_lt_of_geₓ h₃ h₂

@[simp]
theorem bag_inter_consecutive (n m l : ℕ) : List.bagInter (Ico n m) (Ico m l) = [] :=
  (bag_inter_nil_iff_inter_nil _ _).2 (inter_consecutive n m l)

@[simp]
theorem succ_singleton {n : ℕ} : Ico n (n+1) = [n] :=
  by 
    dsimp [Ico]
    simp [add_tsub_cancel_left]

theorem succ_top {n m : ℕ} (h : n ≤ m) : Ico n (m+1) = Ico n m ++ [m] :=
  by 
    rwa [←succ_singleton, append_consecutive]
    exact Nat.le_succₓ _

theorem eq_cons {n m : ℕ} (h : n < m) : Ico n m = n :: Ico (n+1) m :=
  by 
    rw [←append_consecutive (Nat.le_succₓ n) h, succ_singleton]
    rfl

@[simp]
theorem pred_singleton {m : ℕ} (h : 0 < m) : Ico (m - 1) m = [m - 1] :=
  by 
    dsimp [Ico]
    rw [tsub_tsub_cancel_of_le (succ_le_of_lt h)]
    simp 

theorem chain'_succ (n m : ℕ) : chain' (fun a b => b = succ a) (Ico n m) :=
  by 
    byCases' n < m
    ·
      rw [eq_cons h]
      exact chain_succ_range' _ _
    ·
      rw [eq_nil_of_le (le_of_not_gtₓ h)]
      trivial

@[simp]
theorem not_mem_top {n m : ℕ} : m ∉ Ico n m :=
  by 
    simp 

theorem filter_lt_of_top_le {n m l : ℕ} (hml : m ≤ l) : ((Ico n m).filter fun x => x < l) = Ico n m :=
  filter_eq_self.2$ fun k hk => lt_of_lt_of_leₓ (mem.1 hk).2 hml

theorem filter_lt_of_le_bot {n m l : ℕ} (hln : l ≤ n) : ((Ico n m).filter fun x => x < l) = [] :=
  filter_eq_nil.2$ fun k hk => not_lt_of_le$ le_transₓ hln$ (mem.1 hk).1

theorem filter_lt_of_ge {n m l : ℕ} (hlm : l ≤ m) : ((Ico n m).filter fun x => x < l) = Ico n l :=
  by 
    cases' le_totalₓ n l with hnl hln
    ·
      rw [←append_consecutive hnl hlm, filter_append, filter_lt_of_top_le (le_reflₓ l),
        filter_lt_of_le_bot (le_reflₓ l), append_nil]
    ·
      rw [eq_nil_of_le hln, filter_lt_of_le_bot hln]

@[simp]
theorem filter_lt (n m l : ℕ) : ((Ico n m).filter fun x => x < l) = Ico n (min m l) :=
  by 
    cases' le_totalₓ m l with hml hlm
    ·
      rw [min_eq_leftₓ hml, filter_lt_of_top_le hml]
    ·
      rw [min_eq_rightₓ hlm, filter_lt_of_ge hlm]

theorem filter_le_of_le_bot {n m l : ℕ} (hln : l ≤ n) : ((Ico n m).filter fun x => l ≤ x) = Ico n m :=
  filter_eq_self.2$ fun k hk => le_transₓ hln (mem.1 hk).1

theorem filter_le_of_top_le {n m l : ℕ} (hml : m ≤ l) : ((Ico n m).filter fun x => l ≤ x) = [] :=
  filter_eq_nil.2$ fun k hk => not_le_of_gtₓ (lt_of_lt_of_leₓ (mem.1 hk).2 hml)

theorem filter_le_of_le {n m l : ℕ} (hnl : n ≤ l) : ((Ico n m).filter fun x => l ≤ x) = Ico l m :=
  by 
    cases' le_totalₓ l m with hlm hml
    ·
      rw [←append_consecutive hnl hlm, filter_append, filter_le_of_top_le (le_reflₓ l),
        filter_le_of_le_bot (le_reflₓ l), nil_append]
    ·
      rw [eq_nil_of_le hml, filter_le_of_top_le hml]

@[simp]
theorem filter_le (n m l : ℕ) : ((Ico n m).filter fun x => l ≤ x) = Ico (max n l) m :=
  by 
    cases' le_totalₓ n l with hnl hln
    ·
      rw [max_eq_rightₓ hnl, filter_le_of_le hnl]
    ·
      rw [max_eq_leftₓ hln, filter_le_of_le_bot hln]

-- error in Data.List.Intervals: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem filter_lt_of_succ_bot
{n m : exprℕ()}
(hnm : «expr < »(n, m)) : «expr = »((Ico n m).filter (λ x, «expr < »(x, «expr + »(n, 1))), «expr[ , ]»([n])) :=
begin
  have [ident r] [":", expr «expr = »(min m «expr + »(n, 1), «expr + »(n, 1))] [":=", expr (@inf_eq_right _ _ m «expr + »(n, 1)).mpr hnm],
  simp [] [] [] ["[", expr filter_lt n m «expr + »(n, 1), ",", expr r, "]"] [] []
end

@[simp]
theorem filter_le_of_bot {n m : ℕ} (hnm : n < m) : ((Ico n m).filter fun x => x ≤ n) = [n] :=
  by 
    rw [←filter_lt_of_succ_bot hnm]
    exact filter_congr fun _ _ => lt_succ_iff.symm

/--
For any natural numbers n, a, and b, one of the following holds:
1. n < a
2. n ≥ b
3. n ∈ Ico a b
-/
theorem trichotomy (n a b : ℕ) : n < a ∨ b ≤ n ∨ n ∈ Ico a b :=
  by 
    byCases' h₁ : n < a
    ·
      left 
      exact h₁
    ·
      right 
      byCases' h₂ : n ∈ Ico a b
      ·
        right 
        exact h₂
      ·
        left 
        simp only [Ico.mem, not_and, not_ltₓ] at *
        exact h₂ h₁

end Ico

end List

