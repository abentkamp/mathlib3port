/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Abhimanyu Pallavi Sudhir
-/
import Mathbin.Algebra.GeomSum
import Mathbin.Data.Complex.Basic
import Mathbin.Data.Nat.Choose.Sum

/-!
# Exponential, trigonometric and hyperbolic trigonometric functions

This file contains the definitions of the real and complex exponential, sine, cosine, tangent,
hyperbolic sine, hyperbolic cosine, and hyperbolic tangent functions.

-/


-- mathport name: exprabs'
local notation "abs'" => HasAbs.abs

open IsAbsoluteValue

open Classical BigOperators Nat ComplexConjugate

section

open Real IsAbsoluteValue Finset

section

variable {α : Type _} {β : Type _} [Ringₓ β] [LinearOrderedField α] [Archimedean α] {abv : β → α} [IsAbsoluteValue abv]

theorem is_cau_of_decreasing_bounded (f : ℕ → α) {a : α} {m : ℕ} (ham : ∀ n ≥ m, abs (f n) ≤ a)
    (hnm : ∀ n ≥ m, f n.succ ≤ f n) : IsCauSeq abs f := fun ε ε0 => by
  let ⟨k, hk⟩ := Archimedean.arch a ε0
  have h : ∃ l, ∀ n ≥ m, a - l • ε < f n :=
    ⟨k + k + 1, fun n hnm =>
      lt_of_lt_of_leₓ
        (show a - (k + (k + 1)) • ε < -abs (f n) from
          lt_neg.1 <|
            lt_of_le_of_ltₓ (ham n hnm)
              (by
                rw [neg_sub, lt_sub_iff_add_lt, add_nsmul, add_nsmul, one_nsmul]
                exact add_lt_add_of_le_of_lt hk (lt_of_le_of_ltₓ hk (lt_add_of_pos_right _ ε0))))
        (neg_le.2 <| abs_neg (f n) ▸ le_abs_self _)⟩
  let l := Nat.findₓ h
  have hl : ∀ n : ℕ, n ≥ m → f n > a - l • ε := Nat.find_specₓ h
  have hl0 : l ≠ 0 := fun hl0 =>
    not_lt_of_geₓ (ham m le_rflₓ)
      (lt_of_lt_of_leₓ
        (by
          have := hl m (le_reflₓ m) <;> simpa [hl0] using this)
        (le_abs_self (f m)))
  cases' not_forall.1 (Nat.find_minₓ h (Nat.pred_ltₓ hl0)) with i hi
  rw [not_imp, not_ltₓ] at hi
  exists i
  intro j hj
  have hfij : f j ≤ f i := (Nat.rel_of_forall_rel_succ_of_le_of_le (· ≥ ·) hnm hi.1 hj).le
  rw [abs_of_nonpos (sub_nonpos.2 hfij), neg_sub, sub_lt_iff_lt_add']
  calc
    f i ≤ a - Nat.pred l • ε := hi.2
    _ = a - l • ε + ε := by
      conv => rhs rw [← Nat.succ_pred_eq_of_posₓ (Nat.pos_of_ne_zeroₓ hl0), succ_nsmul', sub_add, add_sub_cancel]
    _ < f j + ε := add_lt_add_right (hl j (le_transₓ hi.1 hj)) _
    

theorem is_cau_of_mono_bounded (f : ℕ → α) {a : α} {m : ℕ} (ham : ∀ n ≥ m, abs (f n) ≤ a)
    (hnm : ∀ n ≥ m, f n ≤ f n.succ) : IsCauSeq abs f := by
  refine'
    @Eq.recOnₓ (ℕ → α) _ (IsCauSeq abs) _ _
      (-⟨_,
            @is_cau_of_decreasing_bounded _ _ _ (fun n => -f n) a m
              (by
                simpa)
              (by
                simpa)⟩ :
          CauSeq α abs).2
  ext
  exact neg_negₓ _

end

section NoArchimedean

variable {α : Type _} {β : Type _} [Ringₓ β] [LinearOrderedField α] {abv : β → α} [IsAbsoluteValue abv]

theorem is_cau_series_of_abv_le_cau {f : ℕ → β} {g : ℕ → α} (n : ℕ) :
    (∀ m, n ≤ m → abv (f m) ≤ g m) →
      (IsCauSeq abs fun n => ∑ i in range n, g i) → IsCauSeq abv fun n => ∑ i in range n, f i :=
  by
  intro hm hg ε ε0
  cases'
    hg (ε / 2)
      (div_pos ε0
        (by
          norm_num)) with
    i hi
  exists max n i
  intro j ji
  have hi₁ := hi j (le_transₓ (le_max_rightₓ n i) ji)
  have hi₂ := hi (max n i) (le_max_rightₓ n i)
  have sub_le := abs_sub_le (∑ k in range j, g k) (∑ k in range i, g k) (∑ k in range (max n i), g k)
  have := add_lt_add hi₁ hi₂
  rw [abs_sub_comm (∑ k in range (max n i), g k), add_halves ε] at this
  refine' lt_of_le_of_ltₓ (le_transₓ (le_transₓ _ (le_abs_self _)) sub_le) this
  generalize hk : j - max n i = k
  clear this hi₂ hi₁ hi ε0 ε hg sub_le
  rw [tsub_eq_iff_eq_add_of_le ji] at hk
  rw [hk]
  clear hk ji j
  induction' k with k' hi
  · simp [abv_zero abv]
    
  · simp only [Nat.succ_add, sum_range_succ_comm, sub_eq_add_neg, add_assocₓ]
    refine' le_transₓ (abv_add _ _ _) _
    simp only [sub_eq_add_neg] at hi
    exact add_le_add (hm _ (le_add_of_nonneg_of_le (Nat.zero_leₓ _) (le_max_leftₓ _ _))) hi
    

theorem is_cau_series_of_abv_cau {f : ℕ → β} :
    (IsCauSeq abs fun m => ∑ n in range m, abv (f n)) → IsCauSeq abv fun m => ∑ n in range m, f n :=
  is_cau_series_of_abv_le_cau 0 fun n h => le_rflₓ

end NoArchimedean

section

variable {α : Type _} [LinearOrderedField α] [Archimedean α]

theorem is_cau_geo_series {β : Type _} [Ringₓ β] [Nontrivial β] {abv : β → α} [IsAbsoluteValue abv] (x : β)
    (hx1 : abv x < 1) : IsCauSeq abv fun n => ∑ m in range n, x ^ m :=
  have hx1' : abv x ≠ 1 := fun h => by
    simpa [h, lt_irreflₓ] using hx1
  is_cau_series_of_abv_cau
    (by
      simp only [abv_pow abv, geom_sum_eq hx1']
      conv in _ / _ => rw [← neg_div_neg_eq, neg_sub, neg_sub]
      refine' @is_cau_of_mono_bounded _ _ _ _ ((1 : α) / (1 - abv x)) 0 _ _
      · intro n hn
        rw [abs_of_nonneg]
        refine' div_le_div_of_le (le_of_ltₓ <| sub_pos.2 hx1) (sub_le_self _ (abv_pow abv x n ▸ abv_nonneg _ _))
        refine' div_nonneg (sub_nonneg.2 _) (sub_nonneg.2 <| le_of_ltₓ hx1)
        clear hn
        induction' n with n ih
        · simp
          
        · rw [pow_succₓ, ← one_mulₓ (1 : α)]
          refine'
            mul_le_mul (le_of_ltₓ hx1) ih (abv_pow abv x n ▸ abv_nonneg _ _)
              (by
                norm_num)
          
        
      · intro n hn
        refine' div_le_div_of_le (le_of_ltₓ <| sub_pos.2 hx1) (sub_le_sub_left _ _)
        rw [← one_mulₓ (_ ^ n), pow_succₓ]
        exact mul_le_mul_of_nonneg_right (le_of_ltₓ hx1) (pow_nonneg (abv_nonneg _ _) _)
        )

theorem is_cau_geo_series_const (a : α) {x : α} (hx1 : abs x < 1) : IsCauSeq abs fun m => ∑ n in range m, a * x ^ n :=
  by
  have : IsCauSeq abs fun m => a * ∑ n in range m, x ^ n := (CauSeq.const abs a * ⟨_, is_cau_geo_series x hx1⟩).2
  simpa only [mul_sum]

variable {β : Type _} [Ringₓ β] {abv : β → α} [IsAbsoluteValue abv]

theorem series_ratio_test {f : ℕ → β} (n : ℕ) (r : α) (hr0 : 0 ≤ r) (hr1 : r < 1)
    (h : ∀ m, n ≤ m → abv (f m.succ) ≤ r * abv (f m)) : IsCauSeq abv fun m => ∑ n in range m, f n := by
  have har1 : abs r < 1 := by
    rwa [abs_of_nonneg hr0]
  refine' is_cau_series_of_abv_le_cau n.succ _ (is_cau_geo_series_const (abv (f n.succ) * r⁻¹ ^ n.succ) har1)
  intro m hmn
  cases' Classical.em (r = 0) with r_zero r_ne_zero
  · have m_pos := lt_of_lt_of_leₓ (Nat.succ_posₓ n) hmn
    have :=
      h m.pred
        (Nat.le_of_succ_le_succₓ
          (by
            rwa [Nat.succ_pred_eq_of_posₓ m_pos]))
    simpa [r_zero, Nat.succ_pred_eq_of_posₓ m_pos, pow_succₓ]
    
  generalize hk : m - n.succ = k
  have r_pos : 0 < r := lt_of_le_of_neₓ hr0 (Ne.symm r_ne_zero)
  replace hk : m = k + n.succ := (tsub_eq_iff_eq_add_of_le hmn).1 hk
  induction' k with k ih generalizing m n
  · rw [hk, zero_addₓ, mul_right_commₓ, inv_pow _ _, ← div_eq_mul_inv, mul_div_cancel]
    exact (ne_of_ltₓ (pow_pos r_pos _)).symm
    
  · have kn : k + n.succ ≥ n.succ := by
      rw [← zero_addₓ n.succ] <;>
        exact
          add_le_add (zero_le _)
            (by
              simp )
    rw [hk, Nat.succ_add, pow_succ'ₓ r, ← mul_assoc]
    exact
      le_transₓ
        (by
          rw [mul_comm] <;> exact h _ (Nat.le_of_succ_leₓ kn))
        (mul_le_mul_of_nonneg_right (ih (k + n.succ) n h kn rfl) hr0)
    

theorem sum_range_diag_flip {α : Type _} [AddCommMonoidₓ α] (n : ℕ) (f : ℕ → ℕ → α) :
    (∑ m in range n, ∑ k in range (m + 1), f k (m - k)) = ∑ m in range n, ∑ k in range (n - m), f m k := by
  rw [sum_sigma', sum_sigma'] <;>
    exact
      sum_bij (fun a _ => ⟨a.2, a.1 - a.2⟩)
        (fun a ha =>
          have h₁ : a.1 < n := mem_range.1 (mem_sigma.1 ha).1
          have h₂ : a.2 < Nat.succ a.1 := mem_range.1 (mem_sigma.1 ha).2
          mem_sigma.2
            ⟨mem_range.2 (lt_of_lt_of_leₓ h₂ h₁), mem_range.2 ((tsub_lt_tsub_iff_right (Nat.le_of_lt_succₓ h₂)).2 h₁)⟩)
        (fun _ _ => rfl)
        (fun ⟨a₁, a₂⟩ ⟨b₁, b₂⟩ ha hb h =>
          have ha : a₁ < n ∧ a₂ ≤ a₁ :=
            ⟨mem_range.1 (mem_sigma.1 ha).1, Nat.le_of_lt_succₓ (mem_range.1 (mem_sigma.1 ha).2)⟩
          have hb : b₁ < n ∧ b₂ ≤ b₁ :=
            ⟨mem_range.1 (mem_sigma.1 hb).1, Nat.le_of_lt_succₓ (mem_range.1 (mem_sigma.1 hb).2)⟩
          have h : a₂ = b₂ ∧ _ := Sigma.mk.inj h
          have h' : a₁ = b₁ - b₂ + a₂ := (tsub_eq_iff_eq_add_of_le ha.2).1 (eq_of_heq h.2)
          Sigma.mk.inj_iff.2 ⟨tsub_add_cancel_of_le hb.2 ▸ h'.symm ▸ h.1 ▸ rfl, heq_of_eq h.1⟩)
        fun ⟨a₁, a₂⟩ ha =>
        have ha : a₁ < n ∧ a₂ < n - a₁ := ⟨mem_range.1 (mem_sigma.1 ha).1, mem_range.1 (mem_sigma.1 ha).2⟩
        ⟨⟨a₂ + a₁, a₁⟩,
          ⟨mem_sigma.2
              ⟨mem_range.2 (lt_tsub_iff_right.1 ha.2), mem_range.2 (Nat.lt_succ_of_leₓ (Nat.le_add_leftₓ _ _))⟩,
            Sigma.mk.inj_iff.2 ⟨rfl, heq_of_eq (add_tsub_cancel_right _ _).symm⟩⟩⟩

end

section NoArchimedean

variable {α : Type _} {β : Type _} [LinearOrderedField α] {abv : β → α}

section

variable [Semiringₓ β] [IsAbsoluteValue abv]

theorem abv_sum_le_sum_abv {γ : Type _} (f : γ → β) (s : Finset γ) : abv (∑ k in s, f k) ≤ ∑ k in s, abv (f k) :=
  haveI := Classical.decEq γ
  Finset.induction_on s
    (by
      simp [abv_zero abv])
    fun a s has ih => by
    rw [sum_insert has, sum_insert has] <;> exact le_transₓ (abv_add abv _ _) (add_le_add_left ih _)

end

section

variable [Ringₓ β] [IsAbsoluteValue abv]

theorem cauchy_product {a b : ℕ → β} (ha : IsCauSeq abs fun m => ∑ n in range m, abv (a n))
    (hb : IsCauSeq abv fun m => ∑ n in range m, b n) (ε : α) (ε0 : 0 < ε) :
    ∃ i : ℕ,
      ∀ j ≥ i,
        abv (((∑ k in range j, a k) * ∑ k in range j, b k) - ∑ n in range j, ∑ m in range (n + 1), a m * b (n - m)) <
          ε :=
  let ⟨Q, hQ⟩ := CauSeq.bounded ⟨_, hb⟩
  let ⟨P, hP⟩ := CauSeq.bounded ⟨_, ha⟩
  have hP0 : 0 < P := lt_of_le_of_ltₓ (abs_nonneg _) (hP 0)
  have hPε0 : 0 < ε / (2 * P) :=
    div_pos ε0
      (mul_pos
        (show (2 : α) > 0 by
          norm_num)
        hP0)
  let ⟨N, hN⟩ := CauSeq.cauchy₂ ⟨_, hb⟩ hPε0
  have hQε0 : 0 < ε / (4 * Q) :=
    div_pos ε0
      (mul_pos
        (show (0 : α) < 4 by
          norm_num)
        (lt_of_le_of_ltₓ (abv_nonneg _ _) (hQ 0)))
  let ⟨M, hM⟩ := CauSeq.cauchy₂ ⟨_, ha⟩ hQε0
  ⟨2 * (max N M + 1), fun K hK => by
    have h₁ :
      (∑ m in range K, ∑ k in range (m + 1), a k * b (m - k)) = ∑ m in range K, ∑ n in range (K - m), a m * b n := by
      simpa using sum_range_diag_flip K fun m n => a m * b n
    have h₂ : (fun i => ∑ k in range (K - i), a i * b k) = fun i => a i * ∑ k in range (K - i), b k := by
      simp [Finset.mul_sum]
    have h₃ :
      (∑ i in range K, a i * ∑ k in range (K - i), b k) =
        (∑ i in range K, a i * ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) +
          ∑ i in range K, a i * ∑ k in range K, b k :=
      by
      rw [← sum_add_distrib] <;> simp [(mul_addₓ _ _ _).symm]
    have two_mul_two : (4 : α) = 2 * 2 := by
      norm_num
    have hQ0 : Q ≠ 0 := fun h => by
      simpa [h, lt_irreflₓ] using hQε0
    have h2Q0 : 2 * Q ≠ 0 := mul_ne_zero two_ne_zero hQ0
    have hε : ε / (2 * P) * P + ε / (4 * Q) * (2 * Q) = ε := by
      rw [← div_div, div_mul_cancel _ (Ne.symm (ne_of_ltₓ hP0)), two_mul_two, mul_assoc, ← div_div,
        div_mul_cancel _ h2Q0, add_halves]
    have hNMK : max N M + 1 < K :=
      lt_of_lt_of_leₓ
        (by
          rw [two_mul] <;> exact lt_add_of_pos_left _ (Nat.succ_posₓ _))
        hK
    have hKN : N < K :=
      calc
        N ≤ max N M := le_max_leftₓ _ _
        _ < max N M + 1 := Nat.lt_succ_selfₓ _
        _ < K := hNMK
        
    have hsumlesum :
      (∑ i in range (max N M + 1), abv (a i) * abv ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) ≤
        ∑ i in range (max N M + 1), abv (a i) * (ε / (2 * P)) :=
      sum_le_sum fun m hmJ =>
        mul_le_mul_of_nonneg_left
          (le_of_ltₓ
            (hN (K - m)
              (le_tsub_of_add_le_left
                (le_transₓ
                  (by
                    rw [two_mul] <;>
                      exact
                        add_le_add (le_of_ltₓ (mem_range.1 hmJ))
                          (le_transₓ (le_max_leftₓ _ _) (le_of_ltₓ (lt_add_one _))))
                  hK))
              K (le_of_ltₓ hKN)))
          (abv_nonneg abv _)
    have hsumltP : (∑ n in range (max N M + 1), abv (a n)) < P :=
      calc
        (∑ n in range (max N M + 1), abv (a n)) = abs (∑ n in range (max N M + 1), abv (a n)) :=
          Eq.symm (abs_of_nonneg (sum_nonneg fun x h => abv_nonneg abv (a x)))
        _ < P := hP (max N M + 1)
        
    rw [h₁, h₂, h₃, sum_mul, ← sub_sub, sub_right_comm, sub_self, zero_sub, abv_neg abv]
    refine' lt_of_le_of_ltₓ (abv_sum_le_sum_abv _ _) _
    suffices
      (∑ i in range (max N M + 1), abv (a i) * abv ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) +
          ((∑ i in range K, abv (a i) * abv ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) -
            ∑ i in range (max N M + 1), abv (a i) * abv ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) <
        ε / (2 * P) * P + ε / (4 * Q) * (2 * Q)
      by
      rw [hε] at this
      simpa [abv_mul abv]
    refine'
      add_lt_add
        (lt_of_le_of_ltₓ hsumlesum
          (by
            rw [← sum_mul, mul_comm] <;> exact (mul_lt_mul_left hPε0).mpr hsumltP))
        _
    rw [sum_range_sub_sum_range (le_of_ltₓ hNMK)]
    calc
      (∑ i in (range K).filter fun k => max N M + 1 ≤ k,
            abv (a i) * abv ((∑ k in range (K - i), b k) - ∑ k in range K, b k)) ≤
          ∑ i in (range K).filter fun k => max N M + 1 ≤ k, abv (a i) * (2 * Q) :=
        sum_le_sum fun n hn => by
          refine' mul_le_mul_of_nonneg_left _ (abv_nonneg _ _)
          rw [sub_eq_add_neg]
          refine' le_transₓ (abv_add _ _ _) _
          rw [two_mul, abv_neg abv]
          exact add_le_add (le_of_ltₓ (hQ _)) (le_of_ltₓ (hQ _))
      _ < ε / (4 * Q) * (2 * Q) := by
        rw [← sum_mul, ← sum_range_sub_sum_range (le_of_ltₓ hNMK)] <;>
          refine'
            (mul_lt_mul_right <| by
                  rw [two_mul] <;>
                    exact add_pos (lt_of_le_of_ltₓ (abv_nonneg _ _) (hQ 0)) (lt_of_le_of_ltₓ (abv_nonneg _ _) (hQ 0))).2
              (lt_of_le_of_ltₓ (le_abs_self _)
                (hM _ (le_transₓ (Nat.le_succ_of_leₓ (le_max_rightₓ _ _)) (le_of_ltₓ hNMK)) _
                  (Nat.le_succ_of_leₓ (le_max_rightₓ _ _))))
      ⟩

end

end NoArchimedean

end

open Finset

open CauSeq

namespace Complex

theorem is_cau_abs_exp (z : ℂ) : IsCauSeq HasAbs.abs fun n => ∑ m in range n, abs (z ^ m / m !) :=
  let ⟨n, hn⟩ := exists_nat_gt (abs z)
  have hn0 : (0 : ℝ) < n := lt_of_le_of_ltₓ (abs_nonneg _) hn
  series_ratio_test n (Complex.abs z / n) (div_nonneg (Complex.abs_nonneg _) (le_of_ltₓ hn0))
    (by
      rwa [div_lt_iff hn0, one_mulₓ])
    fun m hm => by
    rw [abs_abs, abs_abs, Nat.factorial_succ, pow_succₓ, mul_comm m.succ, Nat.cast_mulₓ, ← div_div, mul_div_assoc,
        mul_div_right_comm, abs_mul, abs_div, abs_cast_nat] <;>
      exact
        mul_le_mul_of_nonneg_right
          (div_le_div_of_le_left (abs_nonneg _) hn0 (Nat.cast_le.2 (le_transₓ hm (Nat.le_succₓ _)))) (abs_nonneg _)

noncomputable section

theorem is_cau_exp (z : ℂ) : IsCauSeq abs fun n => ∑ m in range n, z ^ m / m ! :=
  is_cau_series_of_abv_cau (is_cau_abs_exp z)

/-- The Cauchy sequence consisting of partial sums of the Taylor series of
the complex exponential function -/
@[pp_nodot]
def exp' (z : ℂ) : CauSeq ℂ Complex.abs :=
  ⟨fun n => ∑ m in range n, z ^ m / m !, is_cau_exp z⟩

/-- The complex exponential function, defined via its Taylor series -/
@[pp_nodot]
def exp (z : ℂ) : ℂ :=
  limₓ (exp' z)

/-- The complex sine function, defined via `exp` -/
@[pp_nodot]
def sin (z : ℂ) : ℂ :=
  (exp (-z * I) - exp (z * I)) * I / 2

/-- The complex cosine function, defined via `exp` -/
@[pp_nodot]
def cos (z : ℂ) : ℂ :=
  (exp (z * I) + exp (-z * I)) / 2

/-- The complex tangent function, defined as `sin z / cos z` -/
@[pp_nodot]
def tan (z : ℂ) : ℂ :=
  sin z / cos z

/-- The complex hyperbolic sine function, defined via `exp` -/
@[pp_nodot]
def sinh (z : ℂ) : ℂ :=
  (exp z - exp (-z)) / 2

/-- The complex hyperbolic cosine function, defined via `exp` -/
@[pp_nodot]
def cosh (z : ℂ) : ℂ :=
  (exp z + exp (-z)) / 2

/-- The complex hyperbolic tangent function, defined as `sinh z / cosh z` -/
@[pp_nodot]
def tanh (z : ℂ) : ℂ :=
  sinh z / cosh z

end Complex

namespace Real

open Complex

/-- The real exponential function, defined as the real part of the complex exponential -/
@[pp_nodot]
def exp (x : ℝ) : ℝ :=
  (exp x).re

/-- The real sine function, defined as the real part of the complex sine -/
@[pp_nodot]
def sin (x : ℝ) : ℝ :=
  (sin x).re

/-- The real cosine function, defined as the real part of the complex cosine -/
@[pp_nodot]
def cos (x : ℝ) : ℝ :=
  (cos x).re

/-- The real tangent function, defined as the real part of the complex tangent -/
@[pp_nodot]
def tan (x : ℝ) : ℝ :=
  (tan x).re

/-- The real hypebolic sine function, defined as the real part of the complex hyperbolic sine -/
@[pp_nodot]
def sinh (x : ℝ) : ℝ :=
  (sinh x).re

/-- The real hypebolic cosine function, defined as the real part of the complex hyperbolic cosine -/
@[pp_nodot]
def cosh (x : ℝ) : ℝ :=
  (cosh x).re

/-- The real hypebolic tangent function, defined as the real part of
the complex hyperbolic tangent -/
@[pp_nodot]
def tanh (x : ℝ) : ℝ :=
  (tanh x).re

end Real

namespace Complex

variable (x y : ℂ)

@[simp]
theorem exp_zero : exp 0 = 1 :=
  lim_eq_of_equiv_const fun ε ε0 =>
    ⟨1, fun j hj => by
      convert ε0
      cases j
      · exact absurd hj (not_le_of_gtₓ zero_lt_one)
        
      · dsimp' [exp']
        induction' j with j ih
        · dsimp' [exp'] <;> simp
          
        · rw [←
            ih
              (by
                decide)]
          simp only [sum_range_succ, pow_succₓ]
          simp
          
        ⟩

theorem exp_add : exp (x + y) = exp x * exp y :=
  show
    limₓ (⟨_, is_cau_exp (x + y)⟩ : CauSeq ℂ abs) =
      limₓ (show CauSeq ℂ abs from ⟨_, is_cau_exp x⟩) * limₓ (show CauSeq ℂ abs from ⟨_, is_cau_exp y⟩)
    by
    have hj :
      ∀ j : ℕ,
        (∑ m in range j, (x + y) ^ m / m !) =
          ∑ i in range j, ∑ k in range (i + 1), x ^ k / k ! * (y ^ (i - k) / (i - k)!) :=
      fun j =>
      Finset.sum_congr rfl fun m hm => by
        rw [add_pow, div_eq_mul_inv, sum_mul]
        refine' Finset.sum_congr rfl fun i hi => _
        have h₁ : (m.choose i : ℂ) ≠ 0 :=
          Nat.cast_ne_zero.2 (pos_iff_ne_zero.1 (Nat.choose_pos (Nat.le_of_lt_succₓ (mem_range.1 hi))))
        have h₂ := Nat.choose_mul_factorial_mul_factorial (Nat.le_of_lt_succₓ <| Finset.mem_range.1 hi)
        rw [← h₂, Nat.cast_mulₓ, Nat.cast_mulₓ, mul_inv, mul_inv]
        simp only [mul_left_commₓ (m.choose i : ℂ), mul_assoc, mul_left_commₓ (m.choose i : ℂ)⁻¹,
          mul_comm (m.choose i : ℂ)]
        rw [inv_mul_cancel h₁]
        simp [div_eq_mul_inv, mul_comm, mul_assoc, mul_left_commₓ]
    rw [lim_mul_lim] <;>
      exact
        Eq.symm
          (lim_eq_lim_of_equiv
            (by
              dsimp' <;> simp only [hj] <;> exact cauchy_product (is_cau_abs_exp x) (is_cau_exp y)))

theorem exp_list_sum (l : List ℂ) : exp l.Sum = (l.map exp).Prod :=
  @MonoidHom.map_list_prod (Multiplicative ℂ) ℂ _ _ ⟨exp, exp_zero, exp_add⟩ l

theorem exp_multiset_sum (s : Multiset ℂ) : exp s.Sum = (s.map exp).Prod :=
  @MonoidHom.map_multiset_prod (Multiplicative ℂ) ℂ _ _ ⟨exp, exp_zero, exp_add⟩ s

theorem exp_sum {α : Type _} (s : Finset α) (f : α → ℂ) : exp (∑ x in s, f x) = ∏ x in s, exp (f x) :=
  @MonoidHom.map_prod (Multiplicative ℂ) α ℂ _ _ ⟨exp, exp_zero, exp_add⟩ f s

theorem exp_nat_mul (x : ℂ) : ∀ n : ℕ, exp (n * x) = exp x ^ n
  | 0 => by
    rw [Nat.cast_zeroₓ, zero_mul, exp_zero, pow_zeroₓ]
  | Nat.succ n => by
    rw [pow_succ'ₓ, Nat.cast_add_one, add_mulₓ, exp_add, ← exp_nat_mul, one_mulₓ]

theorem exp_ne_zero : exp x ≠ 0 := fun h =>
  zero_ne_one <| by
    rw [← exp_zero, ← add_neg_selfₓ x, exp_add, h] <;> simp

theorem exp_neg : exp (-x) = (exp x)⁻¹ := by
  rw [← mul_right_inj' (exp_ne_zero x), ← exp_add] <;> simp [mul_inv_cancel (exp_ne_zero x)]

theorem exp_sub : exp (x - y) = exp x / exp y := by
  simp [sub_eq_add_neg, exp_add, exp_neg, div_eq_mul_inv]

theorem exp_int_mul (z : ℂ) (n : ℤ) : Complex.exp (n * z) = Complex.exp z ^ n := by
  cases n
  · apply Complex.exp_nat_mul
    
  · simpa [Complex.exp_neg, add_commₓ, ← neg_mul] using Complex.exp_nat_mul (-z) (1 + n)
    

@[simp]
theorem exp_conj : exp (conj x) = conj (exp x) := by
  dsimp' [exp]
  rw [← lim_conj]
  refine' congr_argₓ limₓ (CauSeq.ext fun _ => _)
  dsimp' [exp', Function.comp, cau_seq_conj]
  rw [(starRingEnd _).map_sum]
  refine' sum_congr rfl fun n hn => _
  rw [map_div₀, map_pow, ← of_real_nat_cast, conj_of_real]

@[simp]
theorem of_real_exp_of_real_re (x : ℝ) : ((exp x).re : ℂ) = exp x :=
  eq_conj_iff_re.1 <| by
    rw [← exp_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_exp (x : ℝ) : (Real.exp x : ℂ) = exp x :=
  of_real_exp_of_real_re _

@[simp]
theorem exp_of_real_im (x : ℝ) : (exp x).im = 0 := by
  rw [← of_real_exp_of_real_re, of_real_im]

theorem exp_of_real_re (x : ℝ) : (exp x).re = Real.exp x :=
  rfl

theorem two_sinh : 2 * sinh x = exp x - exp (-x) :=
  mul_div_cancel' _ two_ne_zero'

theorem two_cosh : 2 * cosh x = exp x + exp (-x) :=
  mul_div_cancel' _ two_ne_zero'

@[simp]
theorem sinh_zero : sinh 0 = 0 := by
  simp [sinh]

@[simp]
theorem sinh_neg : sinh (-x) = -sinh x := by
  simp [sinh, exp_neg, (neg_div _ _).symm, add_mulₓ]

private theorem sinh_add_aux {a b c d : ℂ} : (a - b) * (c + d) + (a + b) * (c - d) = 2 * (a * c - b * d) := by
  ring

theorem sinh_add : sinh (x + y) = sinh x * cosh y + cosh x * sinh y := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), two_sinh, exp_add, neg_add, exp_add, eq_comm, mul_addₓ, ← mul_assoc,
    two_sinh, mul_left_commₓ, two_sinh, ← mul_right_inj' (@two_ne_zero' ℂ _ _), mul_addₓ, mul_left_commₓ, two_cosh, ←
    mul_assoc, two_cosh]
  exact sinh_add_aux

@[simp]
theorem cosh_zero : cosh 0 = 1 := by
  simp [cosh]

@[simp]
theorem cosh_neg : cosh (-x) = cosh x := by
  simp [add_commₓ, cosh, exp_neg]

private theorem cosh_add_aux {a b c d : ℂ} : (a + b) * (c + d) + (a - b) * (c - d) = 2 * (a * c + b * d) := by
  ring

theorem cosh_add : cosh (x + y) = cosh x * cosh y + sinh x * sinh y := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), two_cosh, exp_add, neg_add, exp_add, eq_comm, mul_addₓ, ← mul_assoc,
    two_cosh, ← mul_assoc, two_sinh, ← mul_right_inj' (@two_ne_zero' ℂ _ _), mul_addₓ, mul_left_commₓ, two_cosh,
    mul_left_commₓ, two_sinh]
  exact cosh_add_aux

theorem sinh_sub : sinh (x - y) = sinh x * cosh y - cosh x * sinh y := by
  simp [sub_eq_add_neg, sinh_add, sinh_neg, cosh_neg]

theorem cosh_sub : cosh (x - y) = cosh x * cosh y - sinh x * sinh y := by
  simp [sub_eq_add_neg, cosh_add, sinh_neg, cosh_neg]

theorem sinh_conj : sinh (conj x) = conj (sinh x) := by
  rw [sinh, ← RingHom.map_neg, exp_conj, exp_conj, ← RingHom.map_sub, sinh, map_div₀, conj_bit0, RingHom.map_one]

@[simp]
theorem of_real_sinh_of_real_re (x : ℝ) : ((sinh x).re : ℂ) = sinh x :=
  eq_conj_iff_re.1 <| by
    rw [← sinh_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_sinh (x : ℝ) : (Real.sinh x : ℂ) = sinh x :=
  of_real_sinh_of_real_re _

@[simp]
theorem sinh_of_real_im (x : ℝ) : (sinh x).im = 0 := by
  rw [← of_real_sinh_of_real_re, of_real_im]

theorem sinh_of_real_re (x : ℝ) : (sinh x).re = Real.sinh x :=
  rfl

theorem cosh_conj : cosh (conj x) = conj (cosh x) := by
  rw [cosh, ← RingHom.map_neg, exp_conj, exp_conj, ← RingHom.map_add, cosh, map_div₀, conj_bit0, RingHom.map_one]

theorem of_real_cosh_of_real_re (x : ℝ) : ((cosh x).re : ℂ) = cosh x :=
  eq_conj_iff_re.1 <| by
    rw [← cosh_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_cosh (x : ℝ) : (Real.cosh x : ℂ) = cosh x :=
  of_real_cosh_of_real_re _

@[simp]
theorem cosh_of_real_im (x : ℝ) : (cosh x).im = 0 := by
  rw [← of_real_cosh_of_real_re, of_real_im]

@[simp]
theorem cosh_of_real_re (x : ℝ) : (cosh x).re = Real.cosh x :=
  rfl

theorem tanh_eq_sinh_div_cosh : tanh x = sinh x / cosh x :=
  rfl

@[simp]
theorem tanh_zero : tanh 0 = 0 := by
  simp [tanh]

@[simp]
theorem tanh_neg : tanh (-x) = -tanh x := by
  simp [tanh, neg_div]

theorem tanh_conj : tanh (conj x) = conj (tanh x) := by
  rw [tanh, sinh_conj, cosh_conj, ← map_div₀, tanh]

@[simp]
theorem of_real_tanh_of_real_re (x : ℝ) : ((tanh x).re : ℂ) = tanh x :=
  eq_conj_iff_re.1 <| by
    rw [← tanh_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_tanh (x : ℝ) : (Real.tanh x : ℂ) = tanh x :=
  of_real_tanh_of_real_re _

@[simp]
theorem tanh_of_real_im (x : ℝ) : (tanh x).im = 0 := by
  rw [← of_real_tanh_of_real_re, of_real_im]

theorem tanh_of_real_re (x : ℝ) : (tanh x).re = Real.tanh x :=
  rfl

@[simp]
theorem cosh_add_sinh : cosh x + sinh x = exp x := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), mul_addₓ, two_cosh, two_sinh, add_add_sub_cancel, two_mul]

@[simp]
theorem sinh_add_cosh : sinh x + cosh x = exp x := by
  rw [add_commₓ, cosh_add_sinh]

@[simp]
theorem exp_sub_cosh : exp x - cosh x = sinh x :=
  sub_eq_iff_eq_add.2 (sinh_add_cosh x).symm

@[simp]
theorem exp_sub_sinh : exp x - sinh x = cosh x :=
  sub_eq_iff_eq_add.2 (cosh_add_sinh x).symm

@[simp]
theorem cosh_sub_sinh : cosh x - sinh x = exp (-x) := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), mul_sub, two_cosh, two_sinh, add_sub_sub_cancel, two_mul]

@[simp]
theorem sinh_sub_cosh : sinh x - cosh x = -exp (-x) := by
  rw [← neg_sub, cosh_sub_sinh]

@[simp]
theorem cosh_sq_sub_sinh_sq : cosh x ^ 2 - sinh x ^ 2 = 1 := by
  rw [sq_sub_sq, cosh_add_sinh, cosh_sub_sinh, ← exp_add, add_neg_selfₓ, exp_zero]

theorem cosh_sq : cosh x ^ 2 = sinh x ^ 2 + 1 := by
  rw [← cosh_sq_sub_sinh_sq x]
  ring

theorem sinh_sq : sinh x ^ 2 = cosh x ^ 2 - 1 := by
  rw [← cosh_sq_sub_sinh_sq x]
  ring

theorem cosh_two_mul : cosh (2 * x) = cosh x ^ 2 + sinh x ^ 2 := by
  rw [two_mul, cosh_add, sq, sq]

theorem sinh_two_mul : sinh (2 * x) = 2 * sinh x * cosh x := by
  rw [two_mul, sinh_add]
  ring

theorem cosh_three_mul : cosh (3 * x) = 4 * cosh x ^ 3 - 3 * cosh x := by
  have h1 : x + 2 * x = 3 * x := by
    ring
  rw [← h1, cosh_add x (2 * x)]
  simp only [cosh_two_mul, sinh_two_mul]
  have h2 : sinh x * (2 * sinh x * cosh x) = 2 * cosh x * sinh x ^ 2 := by
    ring
  rw [h2, sinh_sq]
  ring

theorem sinh_three_mul : sinh (3 * x) = 4 * sinh x ^ 3 + 3 * sinh x := by
  have h1 : x + 2 * x = 3 * x := by
    ring
  rw [← h1, sinh_add x (2 * x)]
  simp only [cosh_two_mul, sinh_two_mul]
  have h2 : cosh x * (2 * sinh x * cosh x) = 2 * sinh x * cosh x ^ 2 := by
    ring
  rw [h2, cosh_sq]
  ring

@[simp]
theorem sin_zero : sin 0 = 0 := by
  simp [sin]

@[simp]
theorem sin_neg : sin (-x) = -sin x := by
  simp [sin, sub_eq_add_neg, exp_neg, (neg_div _ _).symm, add_mulₓ]

theorem two_sin : 2 * sin x = (exp (-x * I) - exp (x * I)) * I :=
  mul_div_cancel' _ two_ne_zero'

theorem two_cos : 2 * cos x = exp (x * I) + exp (-x * I) :=
  mul_div_cancel' _ two_ne_zero'

theorem sinh_mul_I : sinh (x * I) = sin x * I := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), two_sinh, ← mul_assoc, two_sin, mul_assoc, I_mul_I, mul_neg_one, neg_sub,
    neg_mul_eq_neg_mulₓ]

theorem cosh_mul_I : cosh (x * I) = cos x := by
  rw [← mul_right_inj' (@two_ne_zero' ℂ _ _), two_cosh, two_cos, neg_mul_eq_neg_mulₓ]

theorem tanh_mul_I : tanh (x * I) = tan x * I := by
  rw [tanh_eq_sinh_div_cosh, cosh_mul_I, sinh_mul_I, mul_div_right_comm, tan]

theorem cos_mul_I : cos (x * I) = cosh x := by
  rw [← cosh_mul_I] <;> ring_nf <;> simp

theorem sin_mul_I : sin (x * I) = sinh x * I := by
  have h : I * sin (x * I) = -sinh x := by
    rw [mul_comm, ← sinh_mul_I]
    ring_nf
    simp
  simpa only [neg_mul, div_I, neg_negₓ] using CancelFactors.cancel_factors_eq_div h I_ne_zero

theorem tan_mul_I : tan (x * I) = tanh x * I := by
  rw [tan, sin_mul_I, cos_mul_I, mul_div_right_comm, tanh_eq_sinh_div_cosh]

theorem sin_add : sin (x + y) = sin x * cos y + cos x * sin y := by
  rw [← mul_left_inj' I_ne_zero, ← sinh_mul_I, add_mulₓ, add_mulₓ, mul_right_commₓ, ← sinh_mul_I, mul_assoc, ←
    sinh_mul_I, ← cosh_mul_I, ← cosh_mul_I, sinh_add]

@[simp]
theorem cos_zero : cos 0 = 1 := by
  simp [cos]

@[simp]
theorem cos_neg : cos (-x) = cos x := by
  simp [cos, sub_eq_add_neg, exp_neg, add_commₓ]

private theorem cos_add_aux {a b c d : ℂ} : (a + b) * (c + d) - (b - a) * (d - c) * -1 = 2 * (a * c + b * d) := by
  ring

theorem cos_add : cos (x + y) = cos x * cos y - sin x * sin y := by
  rw [← cosh_mul_I, add_mulₓ, cosh_add, cosh_mul_I, cosh_mul_I, sinh_mul_I, sinh_mul_I, mul_mul_mul_commₓ, I_mul_I,
    mul_neg_one, sub_eq_add_neg]

theorem sin_sub : sin (x - y) = sin x * cos y - cos x * sin y := by
  simp [sub_eq_add_neg, sin_add, sin_neg, cos_neg]

theorem cos_sub : cos (x - y) = cos x * cos y + sin x * sin y := by
  simp [sub_eq_add_neg, cos_add, sin_neg, cos_neg]

theorem sin_add_mul_I (x y : ℂ) : sin (x + y * I) = sin x * cosh y + cos x * sinh y * I := by
  rw [sin_add, cos_mul_I, sin_mul_I, mul_assoc]

theorem sin_eq (z : ℂ) : sin z = sin z.re * cosh z.im + cos z.re * sinh z.im * I := by
  convert sin_add_mul_I z.re z.im <;> exact (re_add_im z).symm

theorem cos_add_mul_I (x y : ℂ) : cos (x + y * I) = cos x * cosh y - sin x * sinh y * I := by
  rw [cos_add, cos_mul_I, sin_mul_I, mul_assoc]

theorem cos_eq (z : ℂ) : cos z = cos z.re * cosh z.im - sin z.re * sinh z.im * I := by
  convert cos_add_mul_I z.re z.im <;> exact (re_add_im z).symm

theorem sin_sub_sin : sin x - sin y = 2 * sin ((x - y) / 2) * cos ((x + y) / 2) := by
  have s1 := sin_add ((x + y) / 2) ((x - y) / 2)
  have s2 := sin_sub ((x + y) / 2) ((x - y) / 2)
  rw [div_add_div_same, add_sub, add_right_commₓ, add_sub_cancel, half_add_self] at s1
  rw [div_sub_div_same, ← sub_add, add_sub_cancel', half_add_self] at s2
  rw [s1, s2]
  ring

theorem cos_sub_cos : cos x - cos y = -2 * sin ((x + y) / 2) * sin ((x - y) / 2) := by
  have s1 := cos_add ((x + y) / 2) ((x - y) / 2)
  have s2 := cos_sub ((x + y) / 2) ((x - y) / 2)
  rw [div_add_div_same, add_sub, add_right_commₓ, add_sub_cancel, half_add_self] at s1
  rw [div_sub_div_same, ← sub_add, add_sub_cancel', half_add_self] at s2
  rw [s1, s2]
  ring

theorem cos_add_cos : cos x + cos y = 2 * cos ((x + y) / 2) * cos ((x - y) / 2) := by
  have h2 : (2 : ℂ) ≠ 0 := by
    norm_num
  calc
    cos x + cos y = cos ((x + y) / 2 + (x - y) / 2) + cos ((x + y) / 2 - (x - y) / 2) := _
    _ =
        cos ((x + y) / 2) * cos ((x - y) / 2) - sin ((x + y) / 2) * sin ((x - y) / 2) +
          (cos ((x + y) / 2) * cos ((x - y) / 2) + sin ((x + y) / 2) * sin ((x - y) / 2)) :=
      _
    _ = 2 * cos ((x + y) / 2) * cos ((x - y) / 2) := _
    
  · congr <;> field_simp [h2] <;> ring
    
  · rw [cos_add, cos_sub]
    
  ring

theorem sin_conj : sin (conj x) = conj (sin x) := by
  rw [← mul_left_inj' I_ne_zero, ← sinh_mul_I, ← conj_neg_I, ← RingHom.map_mul, ← RingHom.map_mul, sinh_conj, mul_neg,
    sinh_neg, sinh_mul_I, mul_neg]

@[simp]
theorem of_real_sin_of_real_re (x : ℝ) : ((sin x).re : ℂ) = sin x :=
  eq_conj_iff_re.1 <| by
    rw [← sin_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_sin (x : ℝ) : (Real.sin x : ℂ) = sin x :=
  of_real_sin_of_real_re _

@[simp]
theorem sin_of_real_im (x : ℝ) : (sin x).im = 0 := by
  rw [← of_real_sin_of_real_re, of_real_im]

theorem sin_of_real_re (x : ℝ) : (sin x).re = Real.sin x :=
  rfl

theorem cos_conj : cos (conj x) = conj (cos x) := by
  rw [← cosh_mul_I, ← conj_neg_I, ← RingHom.map_mul, ← cosh_mul_I, cosh_conj, mul_neg, cosh_neg]

@[simp]
theorem of_real_cos_of_real_re (x : ℝ) : ((cos x).re : ℂ) = cos x :=
  eq_conj_iff_re.1 <| by
    rw [← cos_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_cos (x : ℝ) : (Real.cos x : ℂ) = cos x :=
  of_real_cos_of_real_re _

@[simp]
theorem cos_of_real_im (x : ℝ) : (cos x).im = 0 := by
  rw [← of_real_cos_of_real_re, of_real_im]

theorem cos_of_real_re (x : ℝ) : (cos x).re = Real.cos x :=
  rfl

@[simp]
theorem tan_zero : tan 0 = 0 := by
  simp [tan]

theorem tan_eq_sin_div_cos : tan x = sin x / cos x :=
  rfl

theorem tan_mul_cos {x : ℂ} (hx : cos x ≠ 0) : tan x * cos x = sin x := by
  rw [tan_eq_sin_div_cos, div_mul_cancel _ hx]

@[simp]
theorem tan_neg : tan (-x) = -tan x := by
  simp [tan, neg_div]

theorem tan_conj : tan (conj x) = conj (tan x) := by
  rw [tan, sin_conj, cos_conj, ← map_div₀, tan]

@[simp]
theorem of_real_tan_of_real_re (x : ℝ) : ((tan x).re : ℂ) = tan x :=
  eq_conj_iff_re.1 <| by
    rw [← tan_conj, conj_of_real]

@[simp, norm_cast]
theorem of_real_tan (x : ℝ) : (Real.tan x : ℂ) = tan x :=
  of_real_tan_of_real_re _

@[simp]
theorem tan_of_real_im (x : ℝ) : (tan x).im = 0 := by
  rw [← of_real_tan_of_real_re, of_real_im]

theorem tan_of_real_re (x : ℝ) : (tan x).re = Real.tan x :=
  rfl

theorem cos_add_sin_I : cos x + sin x * I = exp (x * I) := by
  rw [← cosh_add_sinh, sinh_mul_I, cosh_mul_I]

theorem cos_sub_sin_I : cos x - sin x * I = exp (-x * I) := by
  rw [neg_mul, ← cosh_sub_sinh, sinh_mul_I, cosh_mul_I]

@[simp]
theorem sin_sq_add_cos_sq : sin x ^ 2 + cos x ^ 2 = 1 :=
  Eq.trans
    (by
      rw [cosh_mul_I, sinh_mul_I, mul_powₓ, I_sq, mul_neg_one, sub_neg_eq_add, add_commₓ])
    (cosh_sq_sub_sinh_sq (x * I))

@[simp]
theorem cos_sq_add_sin_sq : cos x ^ 2 + sin x ^ 2 = 1 := by
  rw [add_commₓ, sin_sq_add_cos_sq]

theorem cos_two_mul' : cos (2 * x) = cos x ^ 2 - sin x ^ 2 := by
  rw [two_mul, cos_add, ← sq, ← sq]

theorem cos_two_mul : cos (2 * x) = 2 * cos x ^ 2 - 1 := by
  rw [cos_two_mul', eq_sub_iff_add_eq.2 (sin_sq_add_cos_sq x), ← sub_add, sub_add_eq_add_sub, two_mul]

theorem sin_two_mul : sin (2 * x) = 2 * sin x * cos x := by
  rw [two_mul, sin_add, two_mul, add_mulₓ, mul_comm]

theorem cos_sq : cos x ^ 2 = 1 / 2 + cos (2 * x) / 2 := by
  simp [cos_two_mul, div_add_div_same, mul_div_cancel_left, two_ne_zero', -one_div]

theorem cos_sq' : cos x ^ 2 = 1 - sin x ^ 2 := by
  rw [← sin_sq_add_cos_sq x, add_sub_cancel']

theorem sin_sq : sin x ^ 2 = 1 - cos x ^ 2 := by
  rw [← sin_sq_add_cos_sq x, add_sub_cancel]

theorem inv_one_add_tan_sq {x : ℂ} (hx : cos x ≠ 0) : (1 + tan x ^ 2)⁻¹ = cos x ^ 2 := by
  have : cos x ^ 2 ≠ 0 := pow_ne_zero 2 hx
  rw [tan_eq_sin_div_cos, div_pow]
  field_simp [this]

theorem tan_sq_div_one_add_tan_sq {x : ℂ} (hx : cos x ≠ 0) : tan x ^ 2 / (1 + tan x ^ 2) = sin x ^ 2 := by
  simp only [← tan_mul_cos hx, mul_powₓ, ← inv_one_add_tan_sq hx, div_eq_mul_inv, one_mulₓ]

theorem cos_three_mul : cos (3 * x) = 4 * cos x ^ 3 - 3 * cos x := by
  have h1 : x + 2 * x = 3 * x := by
    ring
  rw [← h1, cos_add x (2 * x)]
  simp only [cos_two_mul, sin_two_mul, mul_addₓ, mul_sub, mul_oneₓ, sq]
  have h2 : 4 * cos x ^ 3 = 2 * cos x * cos x * cos x + 2 * cos x * cos x ^ 2 := by
    ring
  rw [h2, cos_sq']
  ring

theorem sin_three_mul : sin (3 * x) = 3 * sin x - 4 * sin x ^ 3 := by
  have h1 : x + 2 * x = 3 * x := by
    ring
  rw [← h1, sin_add x (2 * x)]
  simp only [cos_two_mul, sin_two_mul, cos_sq']
  have h2 : cos x * (2 * sin x * cos x) = 2 * sin x * cos x ^ 2 := by
    ring
  rw [h2, cos_sq']
  ring

theorem exp_mul_I : exp (x * I) = cos x + sin x * I :=
  (cos_add_sin_I _).symm

theorem exp_add_mul_I : exp (x + y * I) = exp x * (cos y + sin y * I) := by
  rw [exp_add, exp_mul_I]

theorem exp_eq_exp_re_mul_sin_add_cos : exp x = exp x.re * (cos x.im + sin x.im * I) := by
  rw [← exp_add_mul_I, re_add_im]

theorem exp_re : (exp x).re = Real.exp x.re * Real.cos x.im := by
  rw [exp_eq_exp_re_mul_sin_add_cos]
  simp [exp_of_real_re, cos_of_real_re]

theorem exp_im : (exp x).im = Real.exp x.re * Real.sin x.im := by
  rw [exp_eq_exp_re_mul_sin_add_cos]
  simp [exp_of_real_re, sin_of_real_re]

@[simp]
theorem exp_of_real_mul_I_re (x : ℝ) : (exp (x * I)).re = Real.cos x := by
  simp [exp_mul_I, cos_of_real_re]

@[simp]
theorem exp_of_real_mul_I_im (x : ℝ) : (exp (x * I)).im = Real.sin x := by
  simp [exp_mul_I, sin_of_real_re]

/-- **De Moivre's formula** -/
theorem cos_add_sin_mul_I_pow (n : ℕ) (z : ℂ) : (cos z + sin z * I) ^ n = cos (↑n * z) + sin (↑n * z) * I := by
  rw [← exp_mul_I, ← exp_mul_I]
  induction' n with n ih
  · rw [pow_zeroₓ, Nat.cast_zeroₓ, zero_mul, zero_mul, exp_zero]
    
  · rw [pow_succ'ₓ, ih, Nat.cast_succₓ, add_mulₓ, add_mulₓ, one_mulₓ, exp_add]
    

end Complex

namespace Real

open Complex

variable (x y : ℝ)

@[simp]
theorem exp_zero : exp 0 = 1 := by
  simp [Real.exp]

theorem exp_add : exp (x + y) = exp x * exp y := by
  simp [exp_add, exp]

theorem exp_list_sum (l : List ℝ) : exp l.Sum = (l.map exp).Prod :=
  @MonoidHom.map_list_prod (Multiplicative ℝ) ℝ _ _ ⟨exp, exp_zero, exp_add⟩ l

theorem exp_multiset_sum (s : Multiset ℝ) : exp s.Sum = (s.map exp).Prod :=
  @MonoidHom.map_multiset_prod (Multiplicative ℝ) ℝ _ _ ⟨exp, exp_zero, exp_add⟩ s

theorem exp_sum {α : Type _} (s : Finset α) (f : α → ℝ) : exp (∑ x in s, f x) = ∏ x in s, exp (f x) :=
  @MonoidHom.map_prod (Multiplicative ℝ) α ℝ _ _ ⟨exp, exp_zero, exp_add⟩ f s

theorem exp_nat_mul (x : ℝ) : ∀ n : ℕ, exp (n * x) = exp x ^ n
  | 0 => by
    rw [Nat.cast_zeroₓ, zero_mul, exp_zero, pow_zeroₓ]
  | Nat.succ n => by
    rw [pow_succ'ₓ, Nat.cast_add_one, add_mulₓ, exp_add, ← exp_nat_mul, one_mulₓ]

theorem exp_ne_zero : exp x ≠ 0 := fun h =>
  exp_ne_zero x <| by
    rw [exp, ← of_real_inj] at h <;> simp_all

theorem exp_neg : exp (-x) = (exp x)⁻¹ := by
  rw [← of_real_inj, exp, of_real_exp_of_real_re, of_real_neg, exp_neg, of_real_inv, of_real_exp]

theorem exp_sub : exp (x - y) = exp x / exp y := by
  simp [sub_eq_add_neg, exp_add, exp_neg, div_eq_mul_inv]

@[simp]
theorem sin_zero : sin 0 = 0 := by
  simp [sin]

@[simp]
theorem sin_neg : sin (-x) = -sin x := by
  simp [sin, exp_neg, (neg_div _ _).symm, add_mulₓ]

theorem sin_add : sin (x + y) = sin x * cos y + cos x * sin y := by
  rw [← of_real_inj] <;> simp [sin, sin_add]

@[simp]
theorem cos_zero : cos 0 = 1 := by
  simp [cos]

@[simp]
theorem cos_neg : cos (-x) = cos x := by
  simp [cos, exp_neg]

@[simp]
theorem cos_abs : cos (abs x) = cos x := by
  cases le_totalₓ x 0 <;> simp only [*, _root_.abs_of_nonneg, abs_of_nonpos, cos_neg]

theorem cos_add : cos (x + y) = cos x * cos y - sin x * sin y := by
  rw [← of_real_inj] <;> simp [cos, cos_add]

theorem sin_sub : sin (x - y) = sin x * cos y - cos x * sin y := by
  simp [sub_eq_add_neg, sin_add, sin_neg, cos_neg]

theorem cos_sub : cos (x - y) = cos x * cos y + sin x * sin y := by
  simp [sub_eq_add_neg, cos_add, sin_neg, cos_neg]

theorem sin_sub_sin : sin x - sin y = 2 * sin ((x - y) / 2) * cos ((x + y) / 2) := by
  rw [← of_real_inj]
  simp only [sin, cos, of_real_sin_of_real_re, of_real_sub, of_real_add, of_real_div, of_real_mul, of_real_one,
    of_real_bit0]
  convert sin_sub_sin _ _ <;> norm_cast

theorem cos_sub_cos : cos x - cos y = -2 * sin ((x + y) / 2) * sin ((x - y) / 2) := by
  rw [← of_real_inj]
  simp only [cos, neg_mul, of_real_sin, of_real_sub, of_real_add, of_real_cos_of_real_re, of_real_div, of_real_mul,
    of_real_one, of_real_neg, of_real_bit0]
  convert cos_sub_cos _ _
  ring

theorem cos_add_cos : cos x + cos y = 2 * cos ((x + y) / 2) * cos ((x - y) / 2) := by
  rw [← of_real_inj]
  simp only [cos, of_real_sub, of_real_add, of_real_cos_of_real_re, of_real_div, of_real_mul, of_real_one, of_real_bit0]
  convert cos_add_cos _ _ <;> norm_cast

theorem tan_eq_sin_div_cos : tan x = sin x / cos x := by
  rw [← of_real_inj, of_real_tan, tan_eq_sin_div_cos, of_real_div, of_real_sin, of_real_cos]

theorem tan_mul_cos {x : ℝ} (hx : cos x ≠ 0) : tan x * cos x = sin x := by
  rw [tan_eq_sin_div_cos, div_mul_cancel _ hx]

@[simp]
theorem tan_zero : tan 0 = 0 := by
  simp [tan]

@[simp]
theorem tan_neg : tan (-x) = -tan x := by
  simp [tan, neg_div]

@[simp]
theorem sin_sq_add_cos_sq : sin x ^ 2 + cos x ^ 2 = 1 :=
  of_real_inj.1 <| by
    simp

@[simp]
theorem cos_sq_add_sin_sq : cos x ^ 2 + sin x ^ 2 = 1 := by
  rw [add_commₓ, sin_sq_add_cos_sq]

theorem sin_sq_le_one : sin x ^ 2 ≤ 1 := by
  rw [← sin_sq_add_cos_sq x] <;> exact le_add_of_nonneg_right (sq_nonneg _)

theorem cos_sq_le_one : cos x ^ 2 ≤ 1 := by
  rw [← sin_sq_add_cos_sq x] <;> exact le_add_of_nonneg_left (sq_nonneg _)

theorem abs_sin_le_one : abs (sin x) ≤ 1 :=
  abs_le_one_iff_mul_self_le_one.2 <| by
    simp only [← sq, sin_sq_le_one]

theorem abs_cos_le_one : abs (cos x) ≤ 1 :=
  abs_le_one_iff_mul_self_le_one.2 <| by
    simp only [← sq, cos_sq_le_one]

theorem sin_le_one : sin x ≤ 1 :=
  (abs_le.1 (abs_sin_le_one _)).2

theorem cos_le_one : cos x ≤ 1 :=
  (abs_le.1 (abs_cos_le_one _)).2

theorem neg_one_le_sin : -1 ≤ sin x :=
  (abs_le.1 (abs_sin_le_one _)).1

theorem neg_one_le_cos : -1 ≤ cos x :=
  (abs_le.1 (abs_cos_le_one _)).1

theorem cos_two_mul : cos (2 * x) = 2 * cos x ^ 2 - 1 := by
  rw [← of_real_inj] <;> simp [cos_two_mul]

theorem cos_two_mul' : cos (2 * x) = cos x ^ 2 - sin x ^ 2 := by
  rw [← of_real_inj] <;> simp [cos_two_mul']

theorem sin_two_mul : sin (2 * x) = 2 * sin x * cos x := by
  rw [← of_real_inj] <;> simp [sin_two_mul]

theorem cos_sq : cos x ^ 2 = 1 / 2 + cos (2 * x) / 2 :=
  of_real_inj.1 <| by
    simpa using cos_sq x

theorem cos_sq' : cos x ^ 2 = 1 - sin x ^ 2 := by
  rw [← sin_sq_add_cos_sq x, add_sub_cancel']

theorem sin_sq : sin x ^ 2 = 1 - cos x ^ 2 :=
  eq_sub_iff_add_eq.2 <| sin_sq_add_cos_sq _

theorem abs_sin_eq_sqrt_one_sub_cos_sq (x : ℝ) : abs (sin x) = sqrt (1 - cos x ^ 2) := by
  rw [← sin_sq, sqrt_sq_eq_abs]

theorem abs_cos_eq_sqrt_one_sub_sin_sq (x : ℝ) : abs (cos x) = sqrt (1 - sin x ^ 2) := by
  rw [← cos_sq', sqrt_sq_eq_abs]

theorem inv_one_add_tan_sq {x : ℝ} (hx : cos x ≠ 0) : (1 + tan x ^ 2)⁻¹ = cos x ^ 2 :=
  have : Complex.cos x ≠ 0 := mt (congr_argₓ re) hx
  of_real_inj.1 <| by
    simpa using Complex.inv_one_add_tan_sq this

theorem tan_sq_div_one_add_tan_sq {x : ℝ} (hx : cos x ≠ 0) : tan x ^ 2 / (1 + tan x ^ 2) = sin x ^ 2 := by
  simp only [← tan_mul_cos hx, mul_powₓ, ← inv_one_add_tan_sq hx, div_eq_mul_inv, one_mulₓ]

theorem inv_sqrt_one_add_tan_sq {x : ℝ} (hx : 0 < cos x) : (sqrt (1 + tan x ^ 2))⁻¹ = cos x := by
  rw [← sqrt_sq hx.le, ← sqrt_inv, inv_one_add_tan_sq hx.ne']

theorem tan_div_sqrt_one_add_tan_sq {x : ℝ} (hx : 0 < cos x) : tan x / sqrt (1 + tan x ^ 2) = sin x := by
  rw [← tan_mul_cos hx.ne', ← inv_sqrt_one_add_tan_sq hx, div_eq_mul_inv]

theorem cos_three_mul : cos (3 * x) = 4 * cos x ^ 3 - 3 * cos x := by
  rw [← of_real_inj] <;> simp [cos_three_mul]

theorem sin_three_mul : sin (3 * x) = 3 * sin x - 4 * sin x ^ 3 := by
  rw [← of_real_inj] <;> simp [sin_three_mul]

/-- The definition of `sinh` in terms of `exp`. -/
theorem sinh_eq (x : ℝ) : sinh x = (exp x - exp (-x)) / 2 :=
  eq_div_of_mul_eq two_ne_zero <| by
    rw [sinh, exp, exp, Complex.of_real_neg, Complex.sinh, mul_two, ← Complex.add_re, ← mul_two,
      div_mul_cancel _ (two_ne_zero' : (2 : ℂ) ≠ 0), Complex.sub_re]

@[simp]
theorem sinh_zero : sinh 0 = 0 := by
  simp [sinh]

@[simp]
theorem sinh_neg : sinh (-x) = -sinh x := by
  simp [sinh, exp_neg, (neg_div _ _).symm, add_mulₓ]

theorem sinh_add : sinh (x + y) = sinh x * cosh y + cosh x * sinh y := by
  rw [← of_real_inj] <;> simp [sinh_add]

/-- The definition of `cosh` in terms of `exp`. -/
theorem cosh_eq (x : ℝ) : cosh x = (exp x + exp (-x)) / 2 :=
  eq_div_of_mul_eq two_ne_zero <| by
    rw [cosh, exp, exp, Complex.of_real_neg, Complex.cosh, mul_two, ← Complex.add_re, ← mul_two,
      div_mul_cancel _ (two_ne_zero' : (2 : ℂ) ≠ 0), Complex.add_re]

@[simp]
theorem cosh_zero : cosh 0 = 1 := by
  simp [cosh]

@[simp]
theorem cosh_neg : cosh (-x) = cosh x :=
  of_real_inj.1 <| by
    simp

@[simp]
theorem cosh_abs : cosh (abs x) = cosh x := by
  cases le_totalₓ x 0 <;> simp [*, _root_.abs_of_nonneg, abs_of_nonpos]

theorem cosh_add : cosh (x + y) = cosh x * cosh y + sinh x * sinh y := by
  rw [← of_real_inj] <;> simp [cosh_add]

theorem sinh_sub : sinh (x - y) = sinh x * cosh y - cosh x * sinh y := by
  simp [sub_eq_add_neg, sinh_add, sinh_neg, cosh_neg]

theorem cosh_sub : cosh (x - y) = cosh x * cosh y - sinh x * sinh y := by
  simp [sub_eq_add_neg, cosh_add, sinh_neg, cosh_neg]

theorem tanh_eq_sinh_div_cosh : tanh x = sinh x / cosh x :=
  of_real_inj.1 <| by
    simp [tanh_eq_sinh_div_cosh]

@[simp]
theorem tanh_zero : tanh 0 = 0 := by
  simp [tanh]

@[simp]
theorem tanh_neg : tanh (-x) = -tanh x := by
  simp [tanh, neg_div]

@[simp]
theorem cosh_add_sinh : cosh x + sinh x = exp x := by
  rw [← of_real_inj] <;> simp

@[simp]
theorem sinh_add_cosh : sinh x + cosh x = exp x := by
  rw [add_commₓ, cosh_add_sinh]

@[simp]
theorem exp_sub_cosh : exp x - cosh x = sinh x :=
  sub_eq_iff_eq_add.2 (sinh_add_cosh x).symm

@[simp]
theorem exp_sub_sinh : exp x - sinh x = cosh x :=
  sub_eq_iff_eq_add.2 (cosh_add_sinh x).symm

@[simp]
theorem cosh_sub_sinh : cosh x - sinh x = exp (-x) := by
  rw [← of_real_inj]
  simp

@[simp]
theorem sinh_sub_cosh : sinh x - cosh x = -exp (-x) := by
  rw [← neg_sub, cosh_sub_sinh]

@[simp]
theorem cosh_sq_sub_sinh_sq (x : ℝ) : cosh x ^ 2 - sinh x ^ 2 = 1 := by
  rw [← of_real_inj] <;> simp

theorem cosh_sq : cosh x ^ 2 = sinh x ^ 2 + 1 := by
  rw [← of_real_inj] <;> simp [cosh_sq]

theorem cosh_sq' : cosh x ^ 2 = 1 + sinh x ^ 2 :=
  (cosh_sq x).trans (add_commₓ _ _)

theorem sinh_sq : sinh x ^ 2 = cosh x ^ 2 - 1 := by
  rw [← of_real_inj] <;> simp [sinh_sq]

theorem cosh_two_mul : cosh (2 * x) = cosh x ^ 2 + sinh x ^ 2 := by
  rw [← of_real_inj] <;> simp [cosh_two_mul]

theorem sinh_two_mul : sinh (2 * x) = 2 * sinh x * cosh x := by
  rw [← of_real_inj] <;> simp [sinh_two_mul]

theorem cosh_three_mul : cosh (3 * x) = 4 * cosh x ^ 3 - 3 * cosh x := by
  rw [← of_real_inj] <;> simp [cosh_three_mul]

theorem sinh_three_mul : sinh (3 * x) = 4 * sinh x ^ 3 + 3 * sinh x := by
  rw [← of_real_inj] <;> simp [sinh_three_mul]

open IsAbsoluteValue

/-- This is an intermediate result that is later replaced by `real.add_one_le_exp`; use that lemma
instead. -/
theorem add_one_le_exp_of_nonneg {x : ℝ} (hx : 0 ≤ x) : x + 1 ≤ exp x :=
  calc
    x + 1 ≤ limₓ (⟨fun n : ℕ => ((exp' x) n).re, is_cau_seq_re (exp' x)⟩ : CauSeq ℝ HasAbs.abs) :=
      le_lim
        (CauSeq.le_of_exists
          ⟨2, fun j hj =>
            show x + (1 : ℝ) ≤ (∑ m in range j, (x ^ m / m ! : ℂ)).re by
              have h₁ : (((fun m : ℕ => (x ^ m / m ! : ℂ)) ∘ Nat.succ) 0).re = x := by
                simp
              have h₂ : ((x : ℂ) ^ 0 / 0!).re = 1 := by
                simp
              rw [← tsub_add_cancel_of_le hj, sum_range_succ', sum_range_succ', add_re, add_re, h₁, h₂, add_assocₓ, ←
                coe_re_add_group_hom, re_add_group_hom.map_sum, coe_re_add_group_hom]
              refine' le_add_of_nonneg_of_le (sum_nonneg fun m hm => _) le_rflₓ
              rw [← of_real_pow, ← of_real_nat_cast, ← of_real_div, of_real_re]
              exact div_nonneg (pow_nonneg hx _) (Nat.cast_nonneg _)⟩)
    _ = exp x := by
      rw [exp, Complex.exp, ← cau_seq_re, lim_re]
    

theorem one_le_exp {x : ℝ} (hx : 0 ≤ x) : 1 ≤ exp x := by
  linarith [add_one_le_exp_of_nonneg hx]

theorem exp_pos (x : ℝ) : 0 < exp x :=
  (le_totalₓ 0 x).elim (lt_of_lt_of_leₓ zero_lt_one ∘ one_le_exp) fun h => by
    rw [← neg_negₓ x, Real.exp_neg] <;> exact inv_pos.2 (lt_of_lt_of_leₓ zero_lt_one (one_le_exp (neg_nonneg.2 h)))

@[simp]
theorem abs_exp (x : ℝ) : abs (exp x) = exp x :=
  abs_of_pos (exp_pos _)

@[mono]
theorem exp_strict_mono : StrictMono exp := fun x y h => by
  rw [← sub_add_cancel y x, Real.exp_add] <;>
    exact
      (lt_mul_iff_one_lt_left (exp_pos _)).2
        (lt_of_lt_of_leₓ
          (by
            linarith)
          (add_one_le_exp_of_nonneg
            (by
              linarith)))

@[mono]
theorem exp_monotone : Monotone exp :=
  exp_strict_mono.Monotone

@[simp]
theorem exp_lt_exp {x y : ℝ} : exp x < exp y ↔ x < y :=
  exp_strict_mono.lt_iff_lt

@[simp]
theorem exp_le_exp {x y : ℝ} : exp x ≤ exp y ↔ x ≤ y :=
  exp_strict_mono.le_iff_le

theorem exp_injective : Function.Injective exp :=
  exp_strict_mono.Injective

@[simp]
theorem exp_eq_exp {x y : ℝ} : exp x = exp y ↔ x = y :=
  exp_injective.eq_iff

@[simp]
theorem exp_eq_one_iff : exp x = 1 ↔ x = 0 :=
  exp_injective.eq_iff' exp_zero

@[simp]
theorem one_lt_exp_iff {x : ℝ} : 1 < exp x ↔ 0 < x := by
  rw [← exp_zero, exp_lt_exp]

@[simp]
theorem exp_lt_one_iff {x : ℝ} : exp x < 1 ↔ x < 0 := by
  rw [← exp_zero, exp_lt_exp]

@[simp]
theorem exp_le_one_iff {x : ℝ} : exp x ≤ 1 ↔ x ≤ 0 :=
  exp_zero ▸ exp_le_exp

@[simp]
theorem one_le_exp_iff {x : ℝ} : 1 ≤ exp x ↔ 0 ≤ x :=
  exp_zero ▸ exp_le_exp

/-- `real.cosh` is always positive -/
theorem cosh_pos (x : ℝ) : 0 < Real.cosh x :=
  (cosh_eq x).symm ▸ half_pos (add_pos (exp_pos x) (exp_pos (-x)))

theorem sinh_lt_cosh : sinh x < cosh x :=
  lt_of_pow_lt_pow 2 (cosh_pos _).le <| (cosh_sq x).symm ▸ lt_add_one _

end Real

namespace Complex

theorem sum_div_factorial_le {α : Type _} [LinearOrderedField α] (n j : ℕ) (hn : 0 < n) :
    (∑ m in Filter (fun k => n ≤ k) (range j), (1 / m ! : α)) ≤ n.succ / (n ! * n) :=
  calc
    (∑ m in Filter (fun k => n ≤ k) (range j), (1 / m ! : α)) = ∑ m in range (j - n), 1 / (m + n)! :=
      sum_bij (fun m _ => m - n)
        (fun m hm =>
          mem_range.2 <|
            (tsub_lt_tsub_iff_right
                  (by
                    simp at hm <;> tauto)).2
              (by
                simp at hm <;> tauto))
        (fun m hm => by
          rw [tsub_add_cancel_of_le] <;> simp at * <;> tauto)
        (fun a₁ a₂ ha₁ ha₂ h => by
          rwa [tsub_eq_iff_eq_add_of_le, tsub_add_eq_add_tsub, eq_comm, tsub_eq_iff_eq_add_of_le, add_left_injₓ,
              eq_comm] at h <;>
            simp at * <;> tauto)
        fun b hb =>
        ⟨b + n, mem_filter.2 ⟨mem_range.2 <| lt_tsub_iff_right.mp (mem_range.1 hb), Nat.le_add_leftₓ _ _⟩, by
          rw [add_tsub_cancel_right]⟩
    _ ≤ ∑ m in range (j - n), (n ! * n.succ ^ m)⁻¹ := by
      refine' sum_le_sum fun m n => _
      rw [one_div, inv_le_inv]
      · rw [← Nat.cast_powₓ, ← Nat.cast_mulₓ, Nat.cast_le, add_commₓ]
        exact Nat.factorial_mul_pow_le_factorial
        
      · exact Nat.cast_pos.2 (Nat.factorial_pos _)
        
      · exact mul_pos (Nat.cast_pos.2 (Nat.factorial_pos _)) (pow_pos (Nat.cast_pos.2 (Nat.succ_posₓ _)) _)
        
    _ = n !⁻¹ * ∑ m in range (j - n), n.succ⁻¹ ^ m := by
      simp [mul_inv, mul_sum.symm, sum_mul.symm, -Nat.factorial_succ, mul_comm, inv_pow]
    _ = (n.succ - n.succ * n.succ⁻¹ ^ (j - n)) / (n ! * n) := by
      have h₁ : (n.succ : α) ≠ 1 := @Nat.cast_oneₓ α _ ▸ mt Nat.cast_inj.1 (mt Nat.succ.injₓ (pos_iff_ne_zero.1 hn))
      have h₂ : (n.succ : α) ≠ 0 := Nat.cast_ne_zero.2 (Nat.succ_ne_zero _)
      have h₃ : (n ! * n : α) ≠ 0 :=
        mul_ne_zero (Nat.cast_ne_zero.2 (pos_iff_ne_zero.1 (Nat.factorial_pos _)))
          (Nat.cast_ne_zero.2 (pos_iff_ne_zero.1 hn))
      have h₄ : (n.succ - 1 : α) = n := by
        simp
      rw [geom_sum_inv h₁ h₂, eq_div_iff_mul_eq h₃, mul_comm _ (n ! * n : α), ← mul_assoc (n !⁻¹ : α), ← mul_inv_rev,
          h₄, ← mul_assoc (n ! * n : α), mul_comm (n : α) n !, mul_inv_cancel h₃] <;>
        simp [mul_addₓ, add_mulₓ, mul_assoc, mul_comm]
    _ ≤ n.succ / (n ! * n) := by
      refine' Iff.mpr (div_le_div_right (mul_pos _ _)) _
      exact Nat.cast_pos.2 (Nat.factorial_pos _)
      exact Nat.cast_pos.2 hn
      exact sub_le_self _ (mul_nonneg (Nat.cast_nonneg _) (pow_nonneg (inv_nonneg.2 (Nat.cast_nonneg _)) _))
    

theorem exp_bound {x : ℂ} (hx : abs x ≤ 1) {n : ℕ} (hn : 0 < n) :
    abs (exp x - ∑ m in range n, x ^ m / m !) ≤ abs x ^ n * (n.succ * (n ! * n)⁻¹) := by
  rw [← lim_const (∑ m in range n, _), exp, sub_eq_add_neg, ← lim_neg, lim_add, ← lim_abs]
  refine' lim_le (CauSeq.le_of_exists ⟨n, fun j hj => _⟩)
  simp_rw [← sub_eq_add_neg]
  show abs ((∑ m in range j, x ^ m / m !) - ∑ m in range n, x ^ m / m !) ≤ abs x ^ n * (n.succ * (n ! * n)⁻¹)
  rw [sum_range_sub_sum_range hj]
  calc
    abs (∑ m in (range j).filter fun k => n ≤ k, (x ^ m / m ! : ℂ)) =
        abs (∑ m in (range j).filter fun k => n ≤ k, (x ^ n * (x ^ (m - n) / m !) : ℂ)) :=
      by
      refine' congr_argₓ abs (sum_congr rfl fun m hm => _)
      rw [mem_filter, mem_range] at hm
      rw [← mul_div_assoc, ← pow_addₓ, add_tsub_cancel_of_le hm.2]
    _ ≤ ∑ m in Filter (fun k => n ≤ k) (range j), abs (x ^ n * (_ / m !)) := abv_sum_le_sum_abv _ _
    _ ≤ ∑ m in Filter (fun k => n ≤ k) (range j), abs x ^ n * (1 / m !) := by
      refine' sum_le_sum fun m hm => _
      rw [abs_mul, abv_pow abs, abs_div, abs_cast_nat]
      refine' mul_le_mul_of_nonneg_left ((div_le_div_right _).2 _) _
      · exact Nat.cast_pos.2 (Nat.factorial_pos _)
        
      · rw [abv_pow abs]
        exact pow_le_one _ (abs_nonneg _) hx
        
      · exact pow_nonneg (abs_nonneg _) _
        
    _ = abs x ^ n * ∑ m in (range j).filter fun k => n ≤ k, (1 / m ! : ℝ) := by
      simp [abs_mul, abv_pow abs, abs_div, mul_sum.symm]
    _ ≤ abs x ^ n * (n.succ * (n ! * n)⁻¹) :=
      mul_le_mul_of_nonneg_left (sum_div_factorial_le _ _ hn) (pow_nonneg (abs_nonneg _) _)
    

theorem exp_bound' {x : ℂ} {n : ℕ} (hx : abs x / n.succ ≤ 1 / 2) :
    abs (exp x - ∑ m in range n, x ^ m / m !) ≤ abs x ^ n / n ! * 2 := by
  rw [← lim_const (∑ m in range n, _), exp, sub_eq_add_neg, ← lim_neg, lim_add, ← lim_abs]
  refine' lim_le (CauSeq.le_of_exists ⟨n, fun j hj => _⟩)
  simp_rw [← sub_eq_add_neg]
  show abs ((∑ m in range j, x ^ m / m !) - ∑ m in range n, x ^ m / m !) ≤ abs x ^ n / n ! * 2
  let k := j - n
  have hj : j = n + k := (add_tsub_cancel_of_le hj).symm
  rw [hj, sum_range_add_sub_sum_range]
  calc
    abs (∑ i : ℕ in range k, x ^ (n + i) / ((n + i)! : ℂ)) ≤ ∑ i : ℕ in range k, abs (x ^ (n + i) / ((n + i)! : ℂ)) :=
      abv_sum_le_sum_abv _ _
    _ ≤ ∑ i : ℕ in range k, abs x ^ (n + i) / (n + i)! := by
      simp only [Complex.abs_cast_nat, Complex.abs_div, abv_pow abs]
    _ ≤ ∑ i : ℕ in range k, abs x ^ (n + i) / (n ! * n.succ ^ i) := _
    _ = ∑ i : ℕ in range k, abs x ^ n / n ! * (abs x ^ i / n.succ ^ i) := _
    _ ≤ abs x ^ n / ↑n ! * 2 := _
    
  · refine' sum_le_sum fun m hm => div_le_div (pow_nonneg (abs_nonneg x) (n + m)) le_rflₓ _ _
    · exact_mod_cast mul_pos n.factorial_pos (pow_pos n.succ_pos _)
      
    · exact_mod_cast Nat.factorial_mul_pow_le_factorial
      
    
  · refine' Finset.sum_congr rfl fun _ _ => _
    simp only [pow_addₓ, div_eq_inv_mul, mul_inv, mul_left_commₓ, mul_assoc]
    
  · rw [← mul_sum]
    apply mul_le_mul_of_nonneg_left
    · simp_rw [← div_pow]
      rw [geom_sum_eq, div_le_iff_of_neg]
      · trans (-1 : ℝ)
        · linarith
          
        · simp only [neg_le_sub_iff_le_add, div_pow, Nat.cast_succₓ, le_add_iff_nonneg_left]
          exact div_nonneg (pow_nonneg (abs_nonneg x) k) (pow_nonneg (add_nonneg n.cast_nonneg zero_le_one) k)
          
        
      · linarith
        
      · linarith
        
      
    · exact div_nonneg (pow_nonneg (abs_nonneg x) n) (Nat.cast_nonneg n !)
      
    

theorem abs_exp_sub_one_le {x : ℂ} (hx : abs x ≤ 1) : abs (exp x - 1) ≤ 2 * abs x :=
  calc
    abs (exp x - 1) = abs (exp x - ∑ m in range 1, x ^ m / m !) := by
      simp [sum_range_succ]
    _ ≤ abs x ^ 1 * (Nat.succ 1 * (1! * (1 : ℕ))⁻¹) :=
      exp_bound hx
        (by
          decide)
    _ = 2 * abs x := by
      simp [two_mul, mul_two, mul_addₓ, mul_comm]
    

theorem abs_exp_sub_one_sub_id_le {x : ℂ} (hx : abs x ≤ 1) : abs (exp x - 1 - x) ≤ abs x ^ 2 :=
  calc
    abs (exp x - 1 - x) = abs (exp x - ∑ m in range 2, x ^ m / m !) := by
      simp [sub_eq_add_neg, sum_range_succ_comm, add_assocₓ]
    _ ≤ abs x ^ 2 * (Nat.succ 2 * (2! * (2 : ℕ))⁻¹) :=
      exp_bound hx
        (by
          decide)
    _ ≤ abs x ^ 2 * 1 :=
      mul_le_mul_of_nonneg_left
        (by
          norm_num)
        (sq_nonneg (abs x))
    _ = abs x ^ 2 := by
      rw [mul_oneₓ]
    

end Complex

namespace Real

open Complex Finset

theorem exp_bound {x : ℝ} (hx : abs x ≤ 1) {n : ℕ} (hn : 0 < n) :
    abs (exp x - ∑ m in range n, x ^ m / m !) ≤ abs x ^ n * (n.succ / (n ! * n)) := by
  have hxc : Complex.abs x ≤ 1 := by
    exact_mod_cast hx
  convert exp_bound hxc hn <;> norm_cast

theorem exp_bound' {x : ℝ} (h1 : 0 ≤ x) (h2 : x ≤ 1) {n : ℕ} (hn : 0 < n) :
    Real.exp x ≤ (∑ m in Finset.range n, x ^ m / m !) + x ^ n * (n + 1) / (n ! * n) := by
  have h3 : abs x = x := by
    simpa
  have h4 : abs x ≤ 1 := by
    rwa [h3]
  have h' := Real.exp_bound h4 hn
  rw [h3] at h'
  have h'' := (abs_sub_le_iff.1 h').1
  have t := sub_le_iff_le_add'.1 h''
  simpa [mul_div_assoc] using t

theorem abs_exp_sub_one_le {x : ℝ} (hx : abs x ≤ 1) : abs (exp x - 1) ≤ 2 * abs x := by
  have : Complex.abs x ≤ 1 := by
    exact_mod_cast hx
  exact_mod_cast Complex.abs_exp_sub_one_le this

theorem abs_exp_sub_one_sub_id_le {x : ℝ} (hx : abs x ≤ 1) : abs (exp x - 1 - x) ≤ x ^ 2 := by
  rw [← _root_.sq_abs]
  have : Complex.abs x ≤ 1 := by
    exact_mod_cast hx
  exact_mod_cast Complex.abs_exp_sub_one_sub_id_le this

/-- A finite initial segment of the exponential series, followed by an arbitrary tail.
For fixed `n` this is just a linear map wrt `r`, and each map is a simple linear function
of the previous (see `exp_near_succ`), with `exp_near n x r ⟶ exp x` as `n ⟶ ∞`,
for any `r`. -/
def expNear (n : ℕ) (x r : ℝ) : ℝ :=
  (∑ m in range n, x ^ m / m !) + x ^ n / n ! * r

@[simp]
theorem exp_near_zero (x r) : expNear 0 x r = r := by
  simp [exp_near]

@[simp]
theorem exp_near_succ (n x r) : expNear (n + 1) x r = expNear n x (1 + x / (n + 1) * r) := by
  simp [exp_near, range_succ, mul_addₓ, add_left_commₓ, add_assocₓ, pow_succₓ, div_eq_mul_inv, mul_inv] <;> ac_rfl

theorem exp_near_sub (n x r₁ r₂) : expNear n x r₁ - expNear n x r₂ = x ^ n / n ! * (r₁ - r₂) := by
  simp [exp_near, mul_sub]

theorem exp_approx_end (n m : ℕ) (x : ℝ) (e₁ : n + 1 = m) (h : abs x ≤ 1) :
    abs (exp x - expNear m x 0) ≤ abs x ^ m / m ! * ((m + 1) / m) := by
  simp [exp_near]
  convert exp_bound h _ using 1
  field_simp [mul_comm]
  linarith

theorem exp_approx_succ {n} {x a₁ b₁ : ℝ} (m : ℕ) (e₁ : n + 1 = m) (a₂ b₂ : ℝ)
    (e : abs (1 + x / m * a₂ - a₁) ≤ b₁ - abs x / m * b₂) (h : abs (exp x - expNear m x a₂) ≤ abs x ^ m / m ! * b₂) :
    abs (exp x - expNear n x a₁) ≤ abs x ^ n / n ! * b₁ := by
  refine' (_root_.abs_sub_le _ _ _).trans ((add_le_add_right h _).trans _)
  subst e₁
  rw [exp_near_succ, exp_near_sub, _root_.abs_mul]
  convert mul_le_mul_of_nonneg_left (le_sub_iff_add_le'.1 e) _
  · simp [mul_addₓ, pow_succ'ₓ, div_eq_mul_inv, _root_.abs_mul, _root_.abs_inv, ← pow_abs, mul_inv]
    ac_rfl
    
  · simp [_root_.div_nonneg, _root_.abs_nonneg]
    

theorem exp_approx_end' {n} {x a b : ℝ} (m : ℕ) (e₁ : n + 1 = m) (rm : ℝ) (er : ↑m = rm) (h : abs x ≤ 1)
    (e : abs (1 - a) ≤ b - abs x / rm * ((rm + 1) / rm)) : abs (exp x - expNear n x a) ≤ abs x ^ n / n ! * b := by
  subst er <;>
    exact
      exp_approx_succ _ e₁ _ _
        (by
          simpa using e)
        (exp_approx_end _ _ _ e₁ h)

theorem exp_1_approx_succ_eq {n} {a₁ b₁ : ℝ} {m : ℕ} (en : n + 1 = m) {rm : ℝ} (er : ↑m = rm)
    (h : abs (exp 1 - expNear m 1 ((a₁ - 1) * rm)) ≤ abs 1 ^ m / m ! * (b₁ * rm)) :
    abs (exp 1 - expNear n 1 a₁) ≤ abs 1 ^ n / n ! * b₁ := by
  subst er
  refine' exp_approx_succ _ en _ _ _ h
  field_simp [show (m : ℝ) ≠ 0 by
      norm_cast <;> linarith]

theorem exp_approx_start (x a b : ℝ) (h : abs (exp x - expNear 0 x a) ≤ abs x ^ 0 / 0! * b) : abs (exp x - a) ≤ b := by
  simpa using h

theorem cos_bound {x : ℝ} (hx : abs x ≤ 1) : abs (cos x - (1 - x ^ 2 / 2)) ≤ abs x ^ 4 * (5 / 96) :=
  calc
    abs (cos x - (1 - x ^ 2 / 2)) = abs (Complex.cos x - (1 - x ^ 2 / 2)) := by
      rw [← abs_of_real] <;> simp [of_real_bit0, of_real_one, of_real_inv]
    _ = abs ((Complex.exp (x * I) + Complex.exp (-x * I) - (2 - x ^ 2)) / 2) := by
      simp [Complex.cos, sub_div, add_div, neg_div, div_self (@two_ne_zero' ℂ _ _)]
    _ =
        abs
          (((Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !) +
              (Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !)) /
            2) :=
      congr_argₓ abs
        (congr_argₓ (fun x : ℂ => x / 2)
          (by
            simp only [sum_range_succ]
            simp [pow_succₓ]
            apply Complex.ext <;> simp [div_eq_mul_inv, norm_sq] <;> ring))
    _ ≤
        abs ((Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !) / 2) +
          abs ((Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !) / 2) :=
      by
      rw [add_div] <;> exact abs_add _ _
    _ =
        abs (Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !) / 2 +
          abs (Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !) / 2 :=
      by
      simp [Complex.abs_div]
    _ ≤
        Complex.abs (x * I) ^ 4 * (Nat.succ 4 * (4! * (4 : ℕ))⁻¹) / 2 +
          Complex.abs (-x * I) ^ 4 * (Nat.succ 4 * (4! * (4 : ℕ))⁻¹) / 2 :=
      add_le_add
        ((div_le_div_right
              (by
                norm_num)).2
          (Complex.exp_bound
            (by
              simpa)
            (by
              decide)))
        ((div_le_div_right
              (by
                norm_num)).2
          (Complex.exp_bound
            (by
              simpa)
            (by
              decide)))
    _ ≤ abs x ^ 4 * (5 / 96) := by
      norm_num <;> simp [mul_assoc, mul_comm, mul_left_commₓ, mul_div_assoc]
    

theorem sin_bound {x : ℝ} (hx : abs x ≤ 1) : abs (sin x - (x - x ^ 3 / 6)) ≤ abs x ^ 4 * (5 / 96) :=
  calc
    abs (sin x - (x - x ^ 3 / 6)) = abs (Complex.sin x - (x - x ^ 3 / 6)) := by
      rw [← abs_of_real] <;> simp [of_real_bit0, of_real_one, of_real_inv]
    _ = abs (((Complex.exp (-x * I) - Complex.exp (x * I)) * I - (2 * x - x ^ 3 / 3)) / 2) := by
      simp [Complex.sin, sub_div, add_div, neg_div, mul_div_cancel_left _ (@two_ne_zero' ℂ _ _), div_div,
        show (3 : ℂ) * 2 = 6 by
          norm_num]
    _ =
        abs
          (((Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !) -
                (Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !)) *
              I /
            2) :=
      congr_argₓ abs
        (congr_argₓ (fun x : ℂ => x / 2)
          (by
            simp only [sum_range_succ]
            simp [pow_succₓ]
            apply Complex.ext <;> simp [div_eq_mul_inv, norm_sq] <;> ring))
    _ ≤
        abs ((Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !) * I / 2) +
          abs (-((Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !) * I) / 2) :=
      by
      rw [sub_mul, sub_eq_add_neg, add_div] <;> exact abs_add _ _
    _ =
        abs (Complex.exp (x * I) - ∑ m in range 4, (x * I) ^ m / m !) / 2 +
          abs (Complex.exp (-x * I) - ∑ m in range 4, (-x * I) ^ m / m !) / 2 :=
      by
      simp [add_commₓ, Complex.abs_div, Complex.abs_mul]
    _ ≤
        Complex.abs (x * I) ^ 4 * (Nat.succ 4 * (4! * (4 : ℕ))⁻¹) / 2 +
          Complex.abs (-x * I) ^ 4 * (Nat.succ 4 * (4! * (4 : ℕ))⁻¹) / 2 :=
      add_le_add
        ((div_le_div_right
              (by
                norm_num)).2
          (Complex.exp_bound
            (by
              simpa)
            (by
              decide)))
        ((div_le_div_right
              (by
                norm_num)).2
          (Complex.exp_bound
            (by
              simpa)
            (by
              decide)))
    _ ≤ abs x ^ 4 * (5 / 96) := by
      norm_num <;> simp [mul_assoc, mul_comm, mul_left_commₓ, mul_div_assoc]
    

theorem cos_pos_of_le_one {x : ℝ} (hx : abs x ≤ 1) : 0 < cos x :=
  calc
    0 < 1 - x ^ 2 / 2 - abs x ^ 4 * (5 / 96) :=
      sub_pos.2 <|
        lt_sub_iff_add_lt.2
          (calc
            abs x ^ 4 * (5 / 96) + x ^ 2 / 2 ≤ 1 * (5 / 96) + 1 / 2 :=
              add_le_add
                (mul_le_mul_of_nonneg_right (pow_le_one _ (abs_nonneg _) hx)
                  (by
                    norm_num))
                ((div_le_div_right
                      (by
                        norm_num)).2
                  (by
                    rw [sq, ← abs_mul_self, _root_.abs_mul] <;> exact mul_le_one hx (abs_nonneg _) hx))
            _ < 1 := by
              norm_num
            )
    _ ≤ cos x := sub_le.1 (abs_sub_le_iff.1 (cos_bound hx)).2
    

theorem sin_pos_of_pos_of_le_one {x : ℝ} (hx0 : 0 < x) (hx : x ≤ 1) : 0 < sin x :=
  calc
    0 < x - x ^ 3 / 6 - abs x ^ 4 * (5 / 96) :=
      sub_pos.2 <|
        lt_sub_iff_add_lt.2
          (calc
            abs x ^ 4 * (5 / 96) + x ^ 3 / 6 ≤ x * (5 / 96) + x / 6 :=
              add_le_add
                (mul_le_mul_of_nonneg_right
                  (calc
                    abs x ^ 4 ≤ abs x ^ 1 :=
                      pow_le_pow_of_le_one (abs_nonneg _)
                        (by
                          rwa [_root_.abs_of_nonneg (le_of_ltₓ hx0)])
                        (by
                          decide)
                    _ = x := by
                      simp [_root_.abs_of_nonneg (le_of_ltₓ hx0)]
                    )
                  (by
                    norm_num))
                ((div_le_div_right
                      (by
                        norm_num)).2
                  (calc
                    x ^ 3 ≤ x ^ 1 :=
                      pow_le_pow_of_le_one (le_of_ltₓ hx0) hx
                        (by
                          decide)
                    _ = x := pow_oneₓ _
                    ))
            _ < x := by
              linarith
            )
    _ ≤ sin x :=
      sub_le.1
        (abs_sub_le_iff.1
            (sin_bound
              (by
                rwa [_root_.abs_of_nonneg (le_of_ltₓ hx0)]))).2
    

theorem sin_pos_of_pos_of_le_two {x : ℝ} (hx0 : 0 < x) (hx : x ≤ 2) : 0 < sin x :=
  have : x / 2 ≤ 1 :=
    (div_le_iff
          (by
            norm_num)).mpr
      (by
        simpa)
  calc
    0 < 2 * sin (x / 2) * cos (x / 2) :=
      mul_pos
        (mul_pos
          (by
            norm_num)
          (sin_pos_of_pos_of_le_one (half_pos hx0) this))
        (cos_pos_of_le_one
          (by
            rwa [_root_.abs_of_nonneg (le_of_ltₓ (half_pos hx0))]))
    _ = sin x := by
      rw [← sin_two_mul, two_mul, add_halves]
    

theorem cos_one_le : cos 1 ≤ 2 / 3 :=
  calc
    cos 1 ≤ abs (1 : ℝ) ^ 4 * (5 / 96) + (1 - 1 ^ 2 / 2) :=
      sub_le_iff_le_add.1
        (abs_sub_le_iff.1
            (cos_bound
              (by
                simp ))).1
    _ ≤ 2 / 3 := by
      norm_num
    

theorem cos_one_pos : 0 < cos 1 :=
  cos_pos_of_le_one (le_of_eqₓ abs_one)

theorem cos_two_neg : cos 2 < 0 :=
  calc
    cos 2 = cos (2 * 1) := congr_argₓ cos (mul_oneₓ _).symm
    _ = _ := Real.cos_two_mul 1
    _ ≤ 2 * (2 / 3) ^ 2 - 1 :=
      sub_le_sub_right
        (mul_le_mul_of_nonneg_left
          (by
            rw [sq, sq]
            exact mul_self_le_mul_self (le_of_ltₓ cos_one_pos) cos_one_le)
          zero_le_two)
        _
    _ < 0 := by
      norm_num
    

theorem exp_bound_div_one_sub_of_interval_approx {x : ℝ} (h1 : 0 ≤ x) (h2 : x ≤ 1) :
    (∑ j : ℕ in Finset.range 3, x ^ j / j.factorial) + x ^ 3 * ((3 : ℕ) + 1) / ((3 : ℕ).factorial * (3 : ℕ)) ≤
      ∑ j in Finset.range 3, x ^ j :=
  by
  norm_num[Finset.sum]
  rw [add_assocₓ, add_commₓ (x + 1) (x ^ 3 * 4 / 18), ← add_assocₓ, add_le_add_iff_right, ←
    add_le_add_iff_left (-(x ^ 2 / 2)), ← add_assocₓ, CommRingₓ.add_left_neg (x ^ 2 / 2), zero_addₓ, neg_add_eq_sub,
    sub_half, sq, pow_succₓ, sq]
  have i1 : x * 4 / 18 ≤ 1 / 2 := by
    linarith
  have i2 : 0 ≤ x * 4 / 18 := by
    linarith
  have i3 := mul_le_mul h1 h1 le_rflₓ h1
  rw [zero_mul] at i3
  have t := mul_le_mul le_rflₓ i1 i2 i3
  rw [← mul_assoc]
  rwa [mul_one_div, ← mul_div_assoc, ← mul_assoc] at t

theorem exp_bound_div_one_sub_of_interval {x : ℝ} (h1 : 0 ≤ x) (h2 : x < 1) : Real.exp x ≤ 1 / (1 - x) := by
  have h : (∑ j in Finset.range 3, x ^ j) ≤ 1 / (1 - x) := by
    norm_num[Finset.sum]
    have h1x : 0 < 1 - x := by
      simpa
    rw [le_div_iff h1x]
    norm_num[← add_assocₓ, mul_sub_left_distrib, mul_oneₓ, add_mulₓ, sub_add_eq_sub_sub, pow_succ'ₓ x 2]
    have hx3 : 0 ≤ x ^ 3 := by
      norm_num
      exact h1
    linarith
  exact
    (exp_bound' h1 h2.le <| by
          linarith).trans
      ((exp_bound_div_one_sub_of_interval_approx h1 h2.le).trans h)

theorem one_sub_le_exp_minus_of_pos {y : ℝ} (h : 0 ≤ y) : 1 - y ≤ Real.exp (-y) := by
  rw [Real.exp_neg]
  have r1 : (1 - y) * Real.exp y ≤ 1 := by
    cases le_or_ltₓ (1 - y) 0
    · have h'' : (1 - y) * y.exp ≤ 0 := by
        rw [mul_nonpos_iff]
        right
        exact ⟨h_1, y.exp_pos.le⟩
      linarith
      
    have hy1 : y < 1 := by
      linarith
    rw [← le_div_iff' h_1]
    exact exp_bound_div_one_sub_of_interval h hy1
  rw [inv_eq_one_div]
  rw [le_div_iff' y.exp_pos]
  rwa [mul_comm] at r1

theorem add_one_le_exp_of_nonpos {x : ℝ} (h : x ≤ 0) : x + 1 ≤ Real.exp x := by
  rw [add_commₓ]
  have h1 : 0 ≤ -x := by
    linarith
  simpa using one_sub_le_exp_minus_of_pos h1

theorem add_one_le_exp (x : ℝ) : x + 1 ≤ Real.exp x := by
  cases le_or_ltₓ 0 x
  · exact Real.add_one_le_exp_of_nonneg h
    
  exact add_one_le_exp_of_nonpos h.le

end Real

namespace Complex

@[simp]
theorem abs_cos_add_sin_mul_I (x : ℝ) : abs (cos x + sin x * I) = 1 := by
  have := Real.sin_sq_add_cos_sq x
  simp_all [add_commₓ, abs, norm_sq, sq, sin_of_real_re, cos_of_real_re, mul_re]

@[simp]
theorem abs_exp_of_real (x : ℝ) : abs (exp x) = Real.exp x := by
  rw [← of_real_exp] <;> exact abs_of_nonneg (le_of_ltₓ (Real.exp_pos _))

@[simp]
theorem abs_exp_of_real_mul_I (x : ℝ) : abs (exp (x * I)) = 1 := by
  rw [exp_mul_I, abs_cos_add_sin_mul_I]

theorem abs_exp (z : ℂ) : abs (exp z) = Real.exp z.re := by
  rw [exp_eq_exp_re_mul_sin_add_cos, abs_mul, abs_exp_of_real, abs_cos_add_sin_mul_I, mul_oneₓ]

theorem abs_exp_eq_iff_re_eq {x y : ℂ} : abs (exp x) = abs (exp y) ↔ x.re = y.re := by
  rw [abs_exp, abs_exp, Real.exp_eq_exp]

end Complex

