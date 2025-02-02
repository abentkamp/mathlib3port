/-
Copyright (c) 2020 Thomas Browning. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning
-/
import Mathbin.Algebra.GcdMonoid.Multiset
import Mathbin.Combinatorics.Partition
import Mathbin.GroupTheory.Perm.Cycle.Basic
import Mathbin.RingTheory.Int.Basic
import Mathbin.Tactic.Linarith.Default

/-!
# Cycle Types

In this file we define the cycle type of a permutation.

## Main definitions

- `σ.cycle_type` where `σ` is a permutation of a `fintype`
- `σ.partition` where `σ` is a permutation of a `fintype`

## Main results

- `sum_cycle_type` : The sum of `σ.cycle_type` equals `σ.support.card`
- `lcm_cycle_type` : The lcm of `σ.cycle_type` equals `order_of σ`
- `is_conj_iff_cycle_type_eq` : Two permutations are conjugate if and only if they have the same
  cycle type.
- `exists_prime_order_of_dvd_card`: For every prime `p` dividing the order of a finite group `G`
  there exists an element of order `p` in `G`. This is known as Cauchy's theorem.
-/


namespace Equivₓ.Perm

open Equivₓ List Multiset

variable {α : Type _} [Fintype α]

section CycleType

variable [DecidableEq α]

/-- The cycle type of a permutation -/
def cycleType (σ : Perm α) : Multiset ℕ :=
  σ.cycleFactorsFinset.1.map (Finset.card ∘ support)

theorem cycle_type_def (σ : Perm α) : σ.cycleType = σ.cycleFactorsFinset.1.map (Finset.card ∘ support) :=
  rfl

theorem cycle_type_eq' {σ : Perm α} (s : Finset (Perm α)) (h1 : ∀ f : Perm α, f ∈ s → f.IsCycle)
    (h2 : ∀ a ∈ s, ∀ b ∈ s, a ≠ b → Disjoint a b)
    (h0 :
      (s.noncommProd id fun a ha b hb =>
          (em (a = b)).byCases (fun h => h ▸ Commute.refl a)
            (Set.Pairwise.mono' (fun _ _ => Disjoint.commute) h2 ha hb)) =
        σ) :
    σ.cycleType = s.1.map (Finset.card ∘ support) := by
  rw [cycle_type_def]
  congr
  rw [cycle_factors_finset_eq_finset]
  exact ⟨h1, h2, h0⟩

theorem cycle_type_eq {σ : Perm α} (l : List (Perm α)) (h0 : l.Prod = σ) (h1 : ∀ σ : Perm α, σ ∈ l → σ.IsCycle)
    (h2 : l.Pairwise Disjoint) : σ.cycleType = l.map (Finset.card ∘ support) := by
  have hl : l.nodup := nodup_of_pairwise_disjoint_cycles h1 h2
  rw [cycle_type_eq' l.to_finset]
  · simp [list.dedup_eq_self.mpr hl]
    
  · simpa using h1
    
  · simpa [hl] using h0
    
  · simpa [list.dedup_eq_self.mpr hl] using h2.forall disjoint.symmetric
    

theorem cycle_type_one : (1 : Perm α).cycleType = 0 :=
  cycle_type_eq [] rfl (fun _ => False.elim) Pairwiseₓ.nil

theorem cycle_type_eq_zero {σ : Perm α} : σ.cycleType = 0 ↔ σ = 1 := by
  simp [cycle_type_def, cycle_factors_finset_eq_empty_iff]

theorem card_cycle_type_eq_zero {σ : Perm α} : σ.cycleType.card = 0 ↔ σ = 1 := by
  rw [card_eq_zero, cycle_type_eq_zero]

theorem two_le_of_mem_cycle_type {σ : Perm α} {n : ℕ} (h : n ∈ σ.cycleType) : 2 ≤ n := by
  simp only [cycle_type_def, ← Finset.mem_def, Function.comp_app, Multiset.mem_map, mem_cycle_factors_finset_iff] at h
  obtain ⟨_, ⟨hc, -⟩, rfl⟩ := h
  exact hc.two_le_card_support

theorem one_lt_of_mem_cycle_type {σ : Perm α} {n : ℕ} (h : n ∈ σ.cycleType) : 1 < n :=
  two_le_of_mem_cycle_type h

theorem IsCycle.cycle_type {σ : Perm α} (hσ : IsCycle σ) : σ.cycleType = [σ.support.card] :=
  cycle_type_eq [σ] (mul_oneₓ σ) (fun τ hτ => (congr_argₓ IsCycle (List.mem_singletonₓ.mp hτ)).mpr hσ)
    (pairwise_singleton Disjoint σ)

theorem card_cycle_type_eq_one {σ : Perm α} : σ.cycleType.card = 1 ↔ σ.IsCycle := by
  rw [card_eq_one]
  simp_rw [cycle_type_def, Multiset.map_eq_singleton, ← Finset.singleton_val, Finset.val_inj,
    cycle_factors_finset_eq_singleton_iff]
  constructor
  · rintro ⟨_, _, ⟨h, -⟩, -⟩
    exact h
    
  · intro h
    use σ.support.card, σ
    simp [h]
    

theorem Disjoint.cycle_type {σ τ : Perm α} (h : Disjoint σ τ) : (σ * τ).cycleType = σ.cycleType + τ.cycleType := by
  rw [cycle_type_def, cycle_type_def, cycle_type_def, h.cycle_factors_finset_mul_eq_union, ← Multiset.map_add,
    Finset.union_val, multiset.add_eq_union_iff_disjoint.mpr _]
  rw [← Finset.disjoint_val]
  exact h.disjoint_cycle_factors_finset

theorem cycle_type_inv (σ : Perm α) : σ⁻¹.cycleType = σ.cycleType :=
  cycle_induction_on (fun τ : Perm α => τ⁻¹.cycleType = τ.cycleType) σ rfl
    (fun σ hσ => by
      rw [hσ.cycle_type, hσ.inv.cycle_type, support_inv])
    fun σ τ hστ hc hσ hτ => by
    rw [mul_inv_rev, hστ.cycle_type, ← hσ, ← hτ, add_commₓ,
      disjoint.cycle_type fun x =>
        Or.impₓ (fun h : τ x = x => inv_eq_iff_eq.mpr h.symm) (fun h : σ x = x => inv_eq_iff_eq.mpr h.symm)
          (hστ x).symm]

theorem cycle_type_conj {σ τ : Perm α} : (τ * σ * τ⁻¹).cycleType = σ.cycleType := by
  revert τ
  apply cycle_induction_on _ σ
  · intro
    simp
    
  · intro σ hσ τ
    rw [hσ.cycle_type, hσ.is_cycle_conj.cycle_type, card_support_conj]
    
  · intro σ τ hd hc hσ hτ π
    rw [← conj_mul, hd.cycle_type, disjoint.cycle_type, hσ, hτ]
    intro a
    apply (hd (π⁻¹ a)).imp _ _ <;>
      · intro h
        rw [perm.mul_apply, perm.mul_apply, h, apply_inv_self]
        
    

theorem sum_cycle_type (σ : Perm α) : σ.cycleType.Sum = σ.support.card :=
  cycle_induction_on (fun τ : Perm α => τ.cycleType.Sum = τ.support.card) σ
    (by
      rw [cycle_type_one, sum_zero, support_one, Finset.card_empty])
    (fun σ hσ => by
      rw [hσ.cycle_type, coe_sum, List.sum_singleton])
    fun σ τ hστ hc hσ hτ => by
    rw [hστ.cycle_type, sum_add, hσ, hτ, hστ.card_support_mul]

theorem sign_of_cycle_type' (σ : Perm α) : sign σ = (σ.cycleType.map fun n => -((-1 : ℤˣ) ^ n)).Prod :=
  cycle_induction_on (fun τ : Perm α => sign τ = (τ.cycleType.map fun n => -((-1 : ℤˣ) ^ n)).Prod) σ
    (by
      rw [sign_one, cycle_type_one, Multiset.map_zero, prod_zero])
    (fun σ hσ => by
      rw [hσ.sign, hσ.cycle_type, coe_map, coe_prod, List.map_singletonₓ, List.prod_singleton])
    fun σ τ hστ hc hσ hτ => by
    rw [sign_mul, hσ, hτ, hστ.cycle_type, Multiset.map_add, prod_add]

theorem sign_of_cycle_type (f : Perm α) : sign f = (-1 : ℤˣ) ^ (f.cycleType.Sum + f.cycleType.card) :=
  cycle_induction_on (fun f : Perm α => sign f = (-1 : ℤˣ) ^ (f.cycleType.Sum + f.cycleType.card)) f
    (-- base_one
    by
      rw [Equivₓ.Perm.cycle_type_one, sign_one, Multiset.sum_zero, Multiset.card_zero, pow_zeroₓ])
    (-- base_cycles
    fun f hf => by
      rw [Equivₓ.Perm.IsCycle.cycle_type hf, hf.sign, coe_sum, List.sum_cons, sum_nil, add_zeroₓ, coe_card,
        length_singleton, pow_addₓ, pow_oneₓ, mul_comm, neg_mul, one_mulₓ])-- induction_disjoint
  fun f g hfg hf Pf Pg => by
    rw [Equivₓ.Perm.Disjoint.cycle_type hfg, Multiset.sum_add, Multiset.card_add, ← add_assocₓ,
      add_commₓ f.cycle_type.sum g.cycle_type.sum, add_assocₓ g.cycle_type.sum _ _, add_commₓ g.cycle_type.sum _,
      add_assocₓ, pow_addₓ, ← Pf, ← Pg, Equivₓ.Perm.sign_mul]

theorem lcm_cycle_type (σ : Perm α) : σ.cycleType.lcm = orderOf σ :=
  cycle_induction_on (fun τ : Perm α => τ.cycleType.lcm = orderOf τ) σ
    (by
      rw [cycle_type_one, lcm_zero, order_of_one])
    (fun σ hσ => by
      rw [hσ.cycle_type, coe_singleton, lcm_singleton, order_of_is_cycle hσ, normalize_eq])
    fun σ τ hστ hc hσ hτ => by
    rw [hστ.cycle_type, lcm_add, lcm_eq_nat_lcm, hστ.order_of, hσ, hτ]

theorem dvd_of_mem_cycle_type {σ : Perm α} {n : ℕ} (h : n ∈ σ.cycleType) : n ∣ orderOf σ := by
  rw [← lcm_cycle_type]
  exact dvd_lcm h

theorem order_of_cycle_of_dvd_order_of (f : Perm α) (x : α) : orderOf (cycleOf f x) ∣ orderOf f := by
  by_cases' hx : f x = x
  · rw [← cycle_of_eq_one_iff] at hx
    simp [hx]
    
  · refine' dvd_of_mem_cycle_type _
    rw [cycle_type, Multiset.mem_map]
    refine' ⟨f.cycle_of x, _, _⟩
    · rwa [← Finset.mem_def, cycle_of_mem_cycle_factors_finset_iff, mem_support]
      
    · simp [order_of_is_cycle (is_cycle_cycle_of _ hx)]
      
    

theorem two_dvd_card_support {σ : Perm α} (hσ : σ ^ 2 = 1) : 2 ∣ σ.support.card :=
  (congr_argₓ (Dvd.Dvd 2) σ.sum_cycle_type).mp
    (Multiset.dvd_sum fun n hn => by
      rw
        [le_antisymmₓ (Nat.le_of_dvdₓ zero_lt_two <| (dvd_of_mem_cycle_type hn).trans <| order_of_dvd_of_pow_eq_one hσ)
          (two_le_of_mem_cycle_type hn)])

theorem cycle_type_prime_order {σ : Perm α} (hσ : (orderOf σ).Prime) :
    ∃ n : ℕ, σ.cycleType = repeat (orderOf σ) (n + 1) := by
  rw
    [eq_repeat_of_mem fun n hn =>
      or_iff_not_imp_left.mp (hσ.eq_one_or_self_of_dvd n (dvd_of_mem_cycle_type hn)) (one_lt_of_mem_cycle_type hn).ne']
  use σ.cycle_type.card - 1
  rw [tsub_add_cancel_of_le]
  rw [Nat.succ_le_iff, pos_iff_ne_zero, Ne, card_cycle_type_eq_zero]
  intro H
  rw [H, order_of_one] at hσ
  exact hσ.ne_one rfl

theorem is_cycle_of_prime_order {σ : Perm α} (h1 : (orderOf σ).Prime) (h2 : σ.support.card < 2 * orderOf σ) :
    σ.IsCycle := by
  obtain ⟨n, hn⟩ := cycle_type_prime_order h1
  rw [← σ.sum_cycle_type, hn, Multiset.sum_repeat, nsmul_eq_mul, Nat.cast_id, mul_lt_mul_right (order_of_pos σ),
    Nat.succ_lt_succ_iff, Nat.lt_succ_iffₓ, le_zero_iff] at h2
  rw [← card_cycle_type_eq_one, hn, card_repeat, h2]

theorem cycle_type_le_of_mem_cycle_factors_finset {f g : Perm α} (hf : f ∈ g.cycleFactorsFinset) :
    f.cycleType ≤ g.cycleType := by
  rw [mem_cycle_factors_finset_iff] at hf
  rw [cycle_type_def, cycle_type_def, hf.left.cycle_factors_finset_eq_singleton]
  refine' map_le_map _
  simpa [← Finset.mem_def, mem_cycle_factors_finset_iff] using hf

theorem cycle_type_mul_mem_cycle_factors_finset_eq_sub {f g : Perm α} (hf : f ∈ g.cycleFactorsFinset) :
    (g * f⁻¹).cycleType = g.cycleType - f.cycleType := by
  suffices (g * f⁻¹).cycleType + f.cycle_type = g.cycle_type - f.cycle_type + f.cycle_type by
    rw [tsub_add_cancel_of_le (cycle_type_le_of_mem_cycle_factors_finset hf)] at this
    simp [← this]
  simp [← (disjoint_mul_inv_of_mem_cycle_factors_finset hf).cycleType,
    tsub_add_cancel_of_le (cycle_type_le_of_mem_cycle_factors_finset hf)]

theorem is_conj_of_cycle_type_eq {σ τ : Perm α} (h : cycleType σ = cycleType τ) : IsConj σ τ := by
  revert τ
  apply cycle_induction_on _ σ
  · intro τ h
    rw [cycle_type_one, eq_comm, cycle_type_eq_zero] at h
    rw [h]
    
  · intro σ hσ τ hστ
    have hτ := card_cycle_type_eq_one.2 hσ
    rw [hστ, card_cycle_type_eq_one] at hτ
    apply hσ.is_conj hτ
    rw [hσ.cycle_type, hτ.cycle_type, coe_eq_coe, singleton_perm] at hστ
    simp only [and_trueₓ, eq_self_iff_true] at hστ
    exact hστ
    
  · intro σ τ hστ hσ h1 h2 π hπ
    rw [hστ.cycle_type] at hπ
    · have h : σ.support.card ∈ map (Finset.card ∘ perm.support) π.cycle_factors_finset.val := by
        simp [← cycle_type_def, ← hπ, hσ.cycle_type]
      obtain ⟨σ', hσ'l, hσ'⟩ := multiset.mem_map.mp h
      have key : IsConj (σ' * (π * σ'⁻¹)) π := by
        rw [is_conj_iff]
        use σ'⁻¹
        simp [mul_assoc]
      refine' IsConj.trans _ key
      have hs : σ.cycle_type = σ'.cycle_type := by
        rw [← Finset.mem_def, mem_cycle_factors_finset_iff] at hσ'l
        rw [hσ.cycle_type, ← hσ', hσ'l.left.cycle_type]
      refine' hστ.is_conj_mul (h1 hs) (h2 _) _
      · rw [cycle_type_mul_mem_cycle_factors_finset_eq_sub, ← hπ, add_commₓ, hs, add_tsub_cancel_right]
        rwa [Finset.mem_def]
        
      · exact (disjoint_mul_inv_of_mem_cycle_factors_finset hσ'l).symm
        
      
    

theorem is_conj_iff_cycle_type_eq {σ τ : Perm α} : IsConj σ τ ↔ σ.cycleType = τ.cycleType :=
  ⟨fun h => by
    obtain ⟨π, rfl⟩ := is_conj_iff.1 h
    rw [cycle_type_conj], is_conj_of_cycle_type_eq⟩

@[simp]
theorem cycle_type_extend_domain {β : Type _} [Fintype β] [DecidableEq β] {p : β → Prop} [DecidablePred p]
    (f : α ≃ Subtype p) {g : Perm α} : cycleType (g.extendDomain f) = cycleType g := by
  apply cycle_induction_on _ g
  · rw [extend_domain_one, cycle_type_one, cycle_type_one]
    
  · intro σ hσ
    rw [(hσ.extend_domain f).cycleType, hσ.cycle_type, card_support_extend_domain]
    
  · intro σ τ hd hc hσ hτ
    rw [hd.cycle_type, ← extend_domain_mul, (hd.extend_domain f).cycleType, hσ, hτ]
    

theorem mem_cycle_type_iff {n : ℕ} {σ : Perm α} :
    n ∈ cycleType σ ↔ ∃ c τ : Perm α, σ = c * τ ∧ Disjoint c τ ∧ IsCycle c ∧ c.support.card = n := by
  constructor
  · intro h
    obtain ⟨l, rfl, hlc, hld⟩ := trunc_cycle_factors σ
    rw [cycle_type_eq _ rfl hlc hld] at h
    obtain ⟨c, cl, rfl⟩ := List.exists_of_mem_mapₓ h
    rw [(List.perm_cons_erase cl).pairwise_iff fun _ _ hd => _] at hld
    swap
    · exact hd.symm
      
    refine' ⟨c, (l.erase c).Prod, _, _, hlc _ cl, rfl⟩
    · rw [← List.prod_cons, (List.perm_cons_erase cl).symm.prod_eq' (hld.imp fun _ _ => disjoint.commute)]
      
    · exact disjoint_prod_right _ fun g => List.rel_of_pairwise_cons hld
      
    
  · rintro ⟨c, t, rfl, hd, hc, rfl⟩
    simp [hd.cycle_type, hc.cycle_type]
    

theorem le_card_support_of_mem_cycle_type {n : ℕ} {σ : Perm α} (h : n ∈ cycleType σ) : n ≤ σ.support.card :=
  (le_sum_of_mem h).trans (le_of_eqₓ σ.sum_cycle_type)

theorem cycle_type_of_card_le_mem_cycle_type_add_two {n : ℕ} {g : Perm α} (hn2 : Fintype.card α < n + 2)
    (hng : n ∈ g.cycleType) : g.cycleType = {n} := by
  obtain ⟨c, g', rfl, hd, hc, rfl⟩ := mem_cycle_type_iff.1 hng
  by_cases' g'1 : g' = 1
  · rw [hd.cycle_type, hc.cycle_type, coe_singleton, g'1, cycle_type_one, add_zeroₓ]
    
  contrapose! hn2
  apply le_transₓ _ (c * g').support.card_le_univ
  rw [hd.card_support_mul]
  exact add_le_add_left (two_le_card_support_of_ne_one g'1) _

end CycleType

theorem card_compl_support_modeq [DecidableEq α] {p n : ℕ} [hp : Fact p.Prime] {σ : Perm α} (hσ : σ ^ p ^ n = 1) :
    σ.supportᶜ.card ≡ Fintype.card α [MOD p] := by
  rw [Nat.modeq_iff_dvd' σ.supportᶜ.card_le_univ, ← Finset.card_compl, compl_compl]
  refine' (congr_argₓ _ σ.sum_cycle_type).mp (Multiset.dvd_sum fun k hk => _)
  obtain ⟨m, -, hm⟩ := (Nat.dvd_prime_pow hp.out).mp (order_of_dvd_of_pow_eq_one hσ)
  obtain ⟨l, -, rfl⟩ := (Nat.dvd_prime_pow hp.out).mp ((congr_argₓ _ hm).mp (dvd_of_mem_cycle_type hk))
  exact
    dvd_pow_self _ fun h =>
      (one_lt_of_mem_cycle_type hk).Ne <| by
        rw [h, pow_zeroₓ]

theorem exists_fixed_point_of_prime {p n : ℕ} [hp : Fact p.Prime] (hα : ¬p ∣ Fintype.card α) {σ : Perm α}
    (hσ : σ ^ p ^ n = 1) : ∃ a : α, σ a = a := by
  classical
  contrapose! hα
  simp_rw [← mem_support] at hα
  exact
    nat.modeq_zero_iff_dvd.mp
      ((congr_argₓ _ (finset.card_eq_zero.mpr (compl_eq_bot.mpr (finset.eq_univ_iff_forall.mpr hα)))).mp
        (card_compl_support_modeq hσ).symm)

theorem exists_fixed_point_of_prime' {p n : ℕ} [hp : Fact p.Prime] (hα : p ∣ Fintype.card α) {σ : Perm α}
    (hσ : σ ^ p ^ n = 1) {a : α} (ha : σ a = a) : ∃ b : α, σ b = b ∧ b ≠ a := by
  classical
  have h : ∀ b : α, b ∈ σ.supportᶜ ↔ σ b = b := fun b => by
    rw [Finset.mem_compl, mem_support, not_not]
  obtain ⟨b, hb1, hb2⟩ :=
    Finset.exists_ne_of_one_lt_card
      (lt_of_lt_of_leₓ hp.out.one_lt
        (Nat.le_of_dvdₓ (finset.card_pos.mpr ⟨a, (h a).mpr ha⟩)
          (nat.modeq_zero_iff_dvd.mp ((card_compl_support_modeq hσ).trans (nat.modeq_zero_iff_dvd.mpr hα)))))
      a
  exact ⟨b, (h b).mp hb1, hb2⟩

theorem is_cycle_of_prime_order' {σ : Perm α} (h1 : (orderOf σ).Prime) (h2 : Fintype.card α < 2 * orderOf σ) :
    σ.IsCycle := by
  classical
  exact is_cycle_of_prime_order h1 (lt_of_le_of_ltₓ σ.support.card_le_univ h2)

theorem is_cycle_of_prime_order'' {σ : Perm α} (h1 : (Fintype.card α).Prime) (h2 : orderOf σ = Fintype.card α) :
    σ.IsCycle :=
  is_cycle_of_prime_order' ((congr_argₓ Nat.Prime h2).mpr h1)
    (by
      classical
      rw [← one_mulₓ (Fintype.card α), ← h2, mul_lt_mul_right (order_of_pos σ)]
      exact one_lt_two)

section Cauchy

variable (G : Type _) [Groupₓ G] (n : ℕ)

/-- The type of vectors with terms from `G`, length `n`, and product equal to `1:G`. -/
def VectorsProdEqOne : Set (Vector G n) :=
  { v | v.toList.Prod = 1 }

namespace VectorsProdEqOne

theorem mem_iff {n : ℕ} (v : Vector G n) : v ∈ VectorsProdEqOne G n ↔ v.toList.Prod = 1 :=
  Iff.rfl

theorem zero_eq : VectorsProdEqOne G 0 = {Vector.nil} :=
  Set.eq_singleton_iff_unique_mem.mpr ⟨Eq.refl (1 : G), fun v hv => v.eq_nil⟩

theorem one_eq : VectorsProdEqOne G 1 = {Vector.nil.cons 1} := by
  simp_rw [Set.eq_singleton_iff_unique_mem, mem_iff, Vector.to_list_singleton, List.prod_singleton, Vector.head_cons]
  exact ⟨rfl, fun v hv => v.cons_head_tail.symm.trans (congr_arg2ₓ Vector.cons hv v.tail.eq_nil)⟩

instance zeroUnique : Unique (VectorsProdEqOne G 0) := by
  rw [zero_eq]
  exact Set.uniqueSingleton Vector.nil

instance oneUnique : Unique (VectorsProdEqOne G 1) := by
  rw [one_eq]
  exact Set.uniqueSingleton (vector.nil.cons 1)

/-- Given a vector `v` of length `n`, make a vector of length `n + 1` whose product is `1`,
by appending the inverse of the product of `v`. -/
@[simps]
def vectorEquiv : Vector G n ≃ VectorsProdEqOne G (n + 1) where
  toFun := fun v =>
    ⟨v.toList.Prod⁻¹ ::ᵥ v, by
      rw [mem_iff, Vector.to_list_cons, List.prod_cons, inv_mul_selfₓ]⟩
  invFun := fun v => v.1.tail
  left_inv := fun v => v.tail_cons v.toList.Prod⁻¹
  right_inv := fun v =>
    Subtype.ext
      ((congr_arg2ₓ Vector.cons
            (eq_inv_of_mul_eq_one_left
                (by
                  rw [← List.prod_cons, ← Vector.to_list_cons, v.1.cons_head_tail]
                  exact v.2)).symm
            rfl).trans
        v.1.cons_head_tail)

/-- Given a vector `v` of length `n` whose product is 1, make a vector of length `n - 1`,
by deleting the last entry of `v`. -/
def equivVector : VectorsProdEqOne G n ≃ Vector G (n - 1) :=
  ((vectorEquiv G (n - 1)).trans
      (if hn : n = 0 then
        show VectorsProdEqOne G (n - 1 + 1) ≃ VectorsProdEqOne G n by
          rw [hn]
          apply equiv_of_unique
      else by
        rw [tsub_add_cancel_of_le (Nat.pos_of_ne_zeroₓ hn).nat_succ_le])).symm

instance [Fintype G] : Fintype (VectorsProdEqOne G n) :=
  Fintype.ofEquiv (Vector G (n - 1)) (equivVector G n).symm

theorem card [Fintype G] : Fintype.card (VectorsProdEqOne G n) = Fintype.card G ^ (n - 1) :=
  (Fintype.card_congr (equivVector G n)).trans (card_vector (n - 1))

variable {G n} {g : G} (v : VectorsProdEqOne G n) (j k : ℕ)

/-- Rotate a vector whose product is 1. -/
def rotate : VectorsProdEqOne G n :=
  ⟨⟨_, (v.1.1.length_rotate k).trans v.1.2⟩, List.prod_rotate_eq_one_of_prod_eq_one v.2 k⟩

theorem rotate_zero : rotate v 0 = v :=
  Subtype.ext (Subtype.ext v.1.1.rotate_zero)

theorem rotate_rotate : rotate (rotate v j) k = rotate v (j + k) :=
  Subtype.ext (Subtype.ext (v.1.1.rotate_rotate j k))

theorem rotate_length : rotate v n = v :=
  Subtype.ext (Subtype.ext ((congr_argₓ _ v.1.2.symm).trans v.1.1.rotate_length))

end VectorsProdEqOne

/-- For every prime `p` dividing the order of a finite group `G` there exists an element of order
`p` in `G`. This is known as Cauchy's theorem. -/
theorem _root_.exists_prime_order_of_dvd_card {G : Type _} [Groupₓ G] [Fintype G] (p : ℕ) [hp : Fact p.Prime]
    (hdvd : p ∣ Fintype.card G) : ∃ x : G, orderOf x = p := by
  have hp' : p - 1 ≠ 0 := mt tsub_eq_zero_iff_le.mp (not_le_of_ltₓ hp.out.one_lt)
  have Scard :=
    calc
      p ∣ Fintype.card G ^ (p - 1) := hdvd.trans (dvd_pow (dvd_refl _) hp')
      _ = Fintype.card (vectors_prod_eq_one G p) := (vectors_prod_eq_one.card G p).symm
      
  let f : ℕ → vectors_prod_eq_one G p → vectors_prod_eq_one G p := fun k v => vectors_prod_eq_one.rotate v k
  have hf1 : ∀ v, f 0 v = v := vectors_prod_eq_one.rotate_zero
  have hf2 : ∀ j k v, f k (f j v) = f (j + k) v := fun j k v => vectors_prod_eq_one.rotate_rotate v j k
  have hf3 : ∀ v, f p v = v := vectors_prod_eq_one.rotate_length
  let σ :=
    Equivₓ.mk (f 1) (f (p - 1))
      (fun s => by
        rw [hf2, add_tsub_cancel_of_le hp.out.one_lt.le, hf3])
      fun s => by
      rw [hf2, tsub_add_cancel_of_le hp.out.one_lt.le, hf3]
  have hσ : ∀ k v, (σ ^ k) v = f k v := fun k v =>
    Nat.rec (hf1 v).symm (fun k hk => Eq.trans (congr_argₓ σ hk) (hf2 k 1 v)) k
  replace hσ : σ ^ p ^ 1 = 1 :=
    perm.ext fun v => by
      rw [pow_oneₓ, hσ, hf3, one_apply]
  let v₀ : vectors_prod_eq_one G p := ⟨Vector.repeat 1 p, (List.prod_repeat 1 p).trans (one_pow p)⟩
  have hv₀ : σ v₀ = v₀ := Subtype.ext (Subtype.ext (List.rotate_repeat (1 : G) p 1))
  obtain ⟨v, hv1, hv2⟩ := exists_fixed_point_of_prime' Scard hσ hv₀
  refine'
    exists_imp_exists (fun g hg => order_of_eq_prime _ fun hg' => hv2 _)
      (list.rotate_one_eq_self_iff_eq_repeat.mp (subtype.ext_iff.mp (subtype.ext_iff.mp hv1)))
  · rw [← List.prod_repeat, ← v.1.2, ← hg, show v.val.val.prod = 1 from v.2]
    
  · rw [Subtype.ext_iff_val, Subtype.ext_iff_val, hg, hg', v.1.2]
    rfl
    

/-- For every prime `p` dividing the order of a finite additive group `G` there exists an element of
order `p` in `G`. This is the additive version of Cauchy's theorem. -/
theorem _root_.exists_prime_add_order_of_dvd_card {G : Type _} [AddGroupₓ G] [Fintype G] (p : ℕ) [hp : Fact p.Prime]
    (hdvd : p ∣ Fintype.card G) : ∃ x : G, addOrderOf x = p :=
  @exists_prime_order_of_dvd_card (Multiplicative G) _ _ _ _ hdvd

attribute [to_additive exists_prime_add_order_of_dvd_card] exists_prime_order_of_dvd_card

end Cauchy

theorem subgroup_eq_top_of_swap_mem [DecidableEq α] {H : Subgroup (Perm α)} [d : DecidablePred (· ∈ H)] {τ : Perm α}
    (h0 : (Fintype.card α).Prime) (h1 : Fintype.card α ∣ Fintype.card H) (h2 : τ ∈ H) (h3 : IsSwap τ) : H = ⊤ := by
  haveI : Fact (Fintype.card α).Prime := ⟨h0⟩
  obtain ⟨σ, hσ⟩ := exists_prime_order_of_dvd_card (Fintype.card α) h1
  have hσ1 : orderOf (σ : perm α) = Fintype.card α := (order_of_subgroup σ).trans hσ
  have hσ2 : is_cycle ↑σ := is_cycle_of_prime_order'' h0 hσ1
  have hσ3 : (σ : perm α).support = ⊤ :=
    Finset.eq_univ_of_card (σ : perm α).support ((order_of_is_cycle hσ2).symm.trans hσ1)
  have hσ4 : Subgroup.closure {↑σ, τ} = ⊤ := closure_prime_cycle_swap h0 hσ2 hσ3 h3
  rw [eq_top_iff, ← hσ4, Subgroup.closure_le, Set.insert_subset, Set.singleton_subset_iff]
  exact ⟨Subtype.mem σ, h2⟩

section Partition

variable [DecidableEq α]

/-- The partition corresponding to a permutation -/
def partition (σ : Perm α) : (Fintype.card α).partition where
  parts := σ.cycleType + repeat 1 (Fintype.card α - σ.support.card)
  parts_pos := fun n hn => by
    cases' mem_add.mp hn with hn hn
    · exact zero_lt_one.trans (one_lt_of_mem_cycle_type hn)
      
    · exact lt_of_lt_of_leₓ zero_lt_one (ge_of_eqₓ (Multiset.eq_of_mem_repeat hn))
      
  parts_sum := by
    rw [sum_add, sum_cycle_type, Multiset.sum_repeat, nsmul_eq_mul, Nat.cast_id, mul_oneₓ,
      add_tsub_cancel_of_le σ.support.card_le_univ]

theorem parts_partition {σ : Perm α} : σ.partition.parts = σ.cycleType + repeat 1 (Fintype.card α - σ.support.card) :=
  rfl

theorem filter_parts_partition_eq_cycle_type {σ : Perm α} : ((partition σ).parts.filter fun n => 2 ≤ n) = σ.cycleType :=
  by
  rw [parts_partition, filter_add, Multiset.filter_eq_self.2 fun _ => two_le_of_mem_cycle_type,
    Multiset.filter_eq_nil.2 fun a h => _, add_zeroₓ]
  rw [Multiset.eq_of_mem_repeat h]
  decide

theorem partition_eq_of_is_conj {σ τ : Perm α} : IsConj σ τ ↔ σ.partition = τ.partition := by
  rw [is_conj_iff_cycle_type_eq]
  refine' ⟨fun h => _, fun h => _⟩
  · rw [Nat.Partition.ext_iff, parts_partition, parts_partition, ← sum_cycle_type, ← sum_cycle_type, h]
    
  · rw [← filter_parts_partition_eq_cycle_type, ← filter_parts_partition_eq_cycle_type, h]
    

end Partition

/-!
### 3-cycles
-/


/-- A three-cycle is a cycle of length 3. -/
def IsThreeCycle [DecidableEq α] (σ : Perm α) : Prop :=
  σ.cycleType = {3}

namespace IsThreeCycle

variable [DecidableEq α] {σ : Perm α}

theorem cycle_type (h : IsThreeCycle σ) : σ.cycleType = {3} :=
  h

theorem card_support (h : IsThreeCycle σ) : σ.support.card = 3 := by
  rw [← sum_cycle_type, h.cycle_type, Multiset.sum_singleton]

theorem _root_.card_support_eq_three_iff : σ.support.card = 3 ↔ σ.IsThreeCycle := by
  refine' ⟨fun h => _, is_three_cycle.card_support⟩
  by_cases' h0 : σ.cycle_type = 0
  · rw [← sum_cycle_type, h0, sum_zero] at h
    exact (ne_of_ltₓ zero_lt_three h).elim
    
  obtain ⟨n, hn⟩ := exists_mem_of_ne_zero h0
  by_cases' h1 : σ.cycle_type.erase n = 0
  · rw [← sum_cycle_type, ← cons_erase hn, h1, cons_zero, Multiset.sum_singleton] at h
    rw [is_three_cycle, ← cons_erase hn, h1, h, ← cons_zero]
    
  obtain ⟨m, hm⟩ := exists_mem_of_ne_zero h1
  rw [← sum_cycle_type, ← cons_erase hn, ← cons_erase hm, Multiset.sum_cons, Multiset.sum_cons] at h
  -- TODO: linarith [...] should solve this directly
  have : ∀ {k}, 2 ≤ m → 2 ≤ n → n + (m + k) = 3 → False := by
    intros
    linarith
  cases this (two_le_of_mem_cycle_type (mem_of_mem_erase hm)) (two_le_of_mem_cycle_type hn) h

theorem is_cycle (h : IsThreeCycle σ) : IsCycle σ := by
  rw [← card_cycle_type_eq_one, h.cycle_type, card_singleton]

theorem sign (h : IsThreeCycle σ) : sign σ = 1 := by
  rw [Equivₓ.Perm.sign_of_cycle_type, h.cycle_type]
  rfl

theorem inv {f : Perm α} (h : IsThreeCycle f) : IsThreeCycle f⁻¹ := by
  rwa [is_three_cycle, cycle_type_inv]

@[simp]
theorem inv_iff {f : Perm α} : IsThreeCycle f⁻¹ ↔ IsThreeCycle f :=
  ⟨by
    rw [← inv_invₓ f]
    apply inv, inv⟩

theorem order_of {g : Perm α} (ht : IsThreeCycle g) : orderOf g = 3 := by
  rw [← lcm_cycle_type, ht.cycle_type, Multiset.lcm_singleton, normalize_eq]

theorem is_three_cycle_sq {g : Perm α} (ht : IsThreeCycle g) : IsThreeCycle (g * g) := by
  rw [← pow_two, ← card_support_eq_three_iff, support_pow_coprime, ht.card_support]
  rw [ht.order_of, Nat.coprime_iff_gcd_eq_oneₓ]
  norm_num

end IsThreeCycle

section

variable [DecidableEq α]

theorem is_three_cycle_swap_mul_swap_same {a b c : α} (ab : a ≠ b) (ac : a ≠ c) (bc : b ≠ c) :
    IsThreeCycle (swap a b * swap a c) := by
  suffices h : support (swap a b * swap a c) = {a, b, c}
  · rw [← card_support_eq_three_iff, h]
    simp [ab, ac, bc]
    
  apply le_antisymmₓ ((support_mul_le _ _).trans fun x => _) fun x hx => _
  · simp [ab, ac, bc]
    
  · simp only [Finset.mem_insert, Finset.mem_singleton] at hx
    rw [mem_support]
    simp only [perm.coe_mul, Function.comp_app, Ne.def]
    obtain rfl | rfl | rfl := hx
    · rw [swap_apply_left, swap_apply_of_ne_of_ne ac.symm bc.symm]
      exact ac.symm
      
    · rw [swap_apply_of_ne_of_ne ab.symm bc, swap_apply_right]
      exact ab
      
    · rw [swap_apply_right, swap_apply_left]
      exact bc
      
    

open Subgroup

theorem swap_mul_swap_same_mem_closure_three_cycles {a b c : α} (ab : a ≠ b) (ac : a ≠ c) :
    swap a b * swap a c ∈ closure { σ : Perm α | IsThreeCycle σ } := by
  by_cases' bc : b = c
  · subst bc
    simp [one_mem]
    
  exact subset_closure (is_three_cycle_swap_mul_swap_same ab ac bc)

theorem IsSwap.mul_mem_closure_three_cycles {σ τ : Perm α} (hσ : IsSwap σ) (hτ : IsSwap τ) :
    σ * τ ∈ closure { σ : Perm α | IsThreeCycle σ } := by
  obtain ⟨a, b, ab, rfl⟩ := hσ
  obtain ⟨c, d, cd, rfl⟩ := hτ
  by_cases' ac : a = c
  · subst ac
    exact swap_mul_swap_same_mem_closure_three_cycles ab cd
    
  have h' : swap a b * swap c d = swap a b * swap a c * (swap c a * swap c d) := by
    simp [swap_comm c a, mul_assoc]
  rw [h']
  exact
    mul_mem (swap_mul_swap_same_mem_closure_three_cycles ab ac)
      (swap_mul_swap_same_mem_closure_three_cycles (Ne.symm ac) cd)

end

end Equivₓ.Perm

