import Mathbin.Analysis.SpecificLimits

/-!
# Hofer's lemma

This is an elementary lemma about complete metric spaces. It is motivated by an
application to the bubbling-off analysis for holomorphic curves in symplectic topology.
We are *very* far away from having these applications, but the proof here is a nice
example of a proof needing to construct a sequence by induction in the middle of the proof.

## References:

* H. Hofer and C. Viterbo, *The Weinstein conjecture in the presence of holomorphic spheres*
-/


open_locale Classical TopologicalSpace BigOperators

open Filter Finset

local notation "d" => dist

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (ε' «expr > » 0)
theorem hofer {X : Type _} [MetricSpace X] [CompleteSpace X] (x : X) (ε : ℝ) (ε_pos : 0 < ε) {ϕ : X → ℝ}
  (cont : Continuous ϕ) (nonneg : ∀ y, 0 ≤ ϕ y) :
  ∃ (ε' : _)(_ : ε' > 0)(x' : X), ε' ≤ ε ∧ (d x' x ≤ 2*ε) ∧ ((ε*ϕ x) ≤ ε'*ϕ x') ∧ ∀ y, d x' y ≤ ε' → ϕ y ≤ 2*ϕ x' :=
  by 
    byContra H 
    have reformulation : ∀ x' k : ℕ, ((ε*ϕ x) ≤ (ε / 2 ^ k)*ϕ x') ↔ ((2 ^ k)*ϕ x) ≤ ϕ x'
    ·
      intro x' k 
      rw [div_mul_eq_mul_div, le_div_iff, mul_assocₓ, mul_le_mul_left ε_pos, mul_commₓ]
      exact
        pow_pos
          (by 
            normNum)
          k 
    replace H : ∀ k : ℕ, ∀ x', (d x' x ≤ 2*ε) ∧ ((2 ^ k)*ϕ x) ≤ ϕ x' → ∃ y, d x' y ≤ ε / 2 ^ k ∧ (2*ϕ x') < ϕ y
    ·
      intro k x' 
      pushNeg  at H 
      simpa [reformulation] using
        H (ε / 2 ^ k)
          (by 
            simp [ε_pos, zero_lt_two])
          x'
          (by 
            simp [ε_pos, zero_lt_two, one_le_two])
    clear reformulation 
    have  : Nonempty X := ⟨x⟩
    choose! F hF using H 
    let u : ℕ → X := fun n => Nat.recOn n x F 
    have hu0 : u 0 = x := rfl 
    have hu : ∀ n, (d (u n) x ≤ 2*ε) ∧ ((2 ^ n)*ϕ x) ≤ ϕ (u n) → d (u n) (u$ n+1) ≤ ε / 2 ^ n ∧ (2*ϕ (u n)) < ϕ (u$ n+1)
    ·
      intro n 
      exact hF n (u n)
    clear hF 
    have key : ∀ n, d (u n) (u (n+1)) ≤ ε / 2 ^ n ∧ (2*ϕ (u n)) < ϕ (u (n+1))
    ·
      intro n 
      induction' n using Nat.case_strong_induction_onₓ with n IH
      ·
        specialize hu 0
        simpa [hu0, mul_nonneg_iff, zero_le_one, ε_pos.le, le_reflₓ] using hu 
      have A : d (u (n+1)) x ≤ 2*ε
      ·
        rw [dist_comm]
        let r := range (n+1)
        calc d (u 0) (u (n+1)) ≤ ∑ i in r, d (u i) (u$ i+1) := dist_le_range_sum_dist u (n+1)_ ≤ ∑ i in r, ε / 2 ^ i :=
          sum_le_sum
            fun i i_in => (IH i$ nat.lt_succ_iff.mp$ finset.mem_range.mp i_in).1_ = ∑ i in r, ((1 / 2) ^ i)*ε :=
          by 
            congr with i 
            fieldSimp _ = (∑ i in r, (1 / 2) ^ i)*ε :=
          finset.sum_mul.symm _ ≤ 2*ε := mul_le_mul_of_nonneg_right (sum_geometric_two_le _) (le_of_ltₓ ε_pos)
      have B : ((2 ^ n+1)*ϕ x) ≤ ϕ (u (n+1))
      ·
        refine' @geom_le (ϕ ∘ u) _ zero_le_two (n+1) fun m hm => _ 
        exact (IH _$ Nat.lt_add_one_iff.1 hm).2.le 
      exact hu (n+1) ⟨A, B⟩
    cases' forall_and_distrib.mp key with key₁ key₂ 
    clear hu key 
    have cauchy_u : CauchySeq u
    ·
      refine' cauchy_seq_of_le_geometric _ ε one_half_lt_one fun n => _ 
      simpa only [one_div, inv_pow₀] using key₁ n 
    obtain ⟨y, limy⟩ : ∃ y, tendsto u at_top (𝓝 y)
    exact CompleteSpace.complete cauchy_u 
    have lim_top : tendsto (ϕ ∘ u) at_top at_top
    ·
      let v := fun n => (ϕ ∘ u) (n+1)
      suffices  : tendsto v at_top at_top
      ·
        rwa [tendsto_add_at_top_iff_nat] at this 
      have hv₀ : 0 < v 0
      ·
        have  : 0 ≤ ϕ (u 0) := nonneg x 
        calc 0 ≤ 2*ϕ (u 0) :=
          by 
            linarith _ < ϕ (u (0+1)) :=
          key₂ 0
      apply tendsto_at_top_of_geom_le hv₀ one_lt_two 
      exact fun n => (key₂ (n+1)).le 
    have lim : tendsto (ϕ ∘ u) at_top (𝓝 (ϕ y))
    exact tendsto.comp cont.continuous_at limy 
    exact not_tendsto_at_top_of_tendsto_nhds limₓ lim_top

