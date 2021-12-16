import Mathbin.Data.Equiv.Fin 
import Mathbin.Data.Equiv.Fintype 
import Mathbin.GroupTheory.Perm.Option 
import Mathbin.GroupTheory.Perm.CycleType

/-!
# Permutations of `fin n`
-/


open Equivₓ

/-- Permutations of `fin (n + 1)` are equivalent to fixing a single
`fin (n + 1)` and permuting the remaining with a `perm (fin n)`.
The fixed `fin (n + 1)` is swapped with `0`. -/
def Equivₓ.Perm.decomposeFin {n : ℕ} : perm (Finₓ n.succ) ≃ Finₓ n.succ × perm (Finₓ n) :=
  ((Equivₓ.permCongr$ finSuccEquiv n).trans Equivₓ.Perm.decomposeOption).trans
    (Equivₓ.prodCongr (finSuccEquiv n).symm (Equivₓ.refl _))

@[simp]
theorem Equivₓ.Perm.decompose_fin_symm_of_refl {n : ℕ} (p : Finₓ (n+1)) :
  Equivₓ.Perm.decomposeFin.symm (p, Equivₓ.refl _) = swap 0 p :=
  by 
    simp [Equivₓ.Perm.decomposeFin, Equivₓ.perm_congr_def]

@[simp]
theorem Equivₓ.Perm.decompose_fin_symm_of_one {n : ℕ} (p : Finₓ (n+1)) :
  Equivₓ.Perm.decomposeFin.symm (p, 1) = swap 0 p :=
  Equivₓ.Perm.decompose_fin_symm_of_refl p

@[simp]
theorem Equivₓ.Perm.decompose_fin_symm_apply_zero {n : ℕ} (p : Finₓ (n+1)) (e : perm (Finₓ n)) :
  Equivₓ.Perm.decomposeFin.symm (p, e) 0 = p :=
  by 
    simp [Equivₓ.Perm.decomposeFin]

@[simp]
theorem Equivₓ.Perm.decompose_fin_symm_apply_succ {n : ℕ} (e : perm (Finₓ n)) (p : Finₓ (n+1)) (x : Finₓ n) :
  Equivₓ.Perm.decomposeFin.symm (p, e) x.succ = swap 0 p (e x).succ :=
  by 
    refine' Finₓ.cases _ _ p
    ·
      simp [Equivₓ.Perm.decomposeFin, EquivFunctor.map]
    ·
      intro i 
      byCases' h : i = e x
      ·
        simp [h, Equivₓ.Perm.decomposeFin, EquivFunctor.map]
      ·
        have h' : some (e x) ≠ some i := fun H => h (Option.some_injective _ H).symm 
        have h'' : (e x).succ ≠ i.succ := fun H => h (Finₓ.succ_injective _ H).symm 
        simp [h, h'', Finₓ.succ_ne_zero, Equivₓ.Perm.decomposeFin, EquivFunctor.map, swap_apply_of_ne_of_ne,
          swap_apply_of_ne_of_ne (Option.some_ne_none (e x)) h']

@[simp]
theorem Equivₓ.Perm.decompose_fin_symm_apply_one {n : ℕ} (e : perm (Finₓ (n+1))) (p : Finₓ (n+2)) :
  Equivₓ.Perm.decomposeFin.symm (p, e) 1 = swap 0 p (e 0).succ :=
  by 
    rw [←Finₓ.succ_zero_eq_one, Equivₓ.Perm.decompose_fin_symm_apply_succ e p 0]

@[simp]
theorem Equivₓ.Perm.decomposeFin.symm_sign {n : ℕ} (p : Finₓ (n+1)) (e : perm (Finₓ n)) :
  perm.sign (Equivₓ.Perm.decomposeFin.symm (p, e)) = ite (p = 0) 1 (-1)*perm.sign e :=
  by 
    refine' Finₓ.cases _ _ p <;> simp [Equivₓ.Perm.decomposeFin, Finₓ.succ_ne_zero]

/-- The set of all permutations of `fin (n + 1)` can be constructed by augmenting the set of
permutations of `fin n` by each element of `fin (n + 1)` in turn. -/
theorem Finset.univ_perm_fin_succ {n : ℕ} :
  @Finset.univ (perm$ Finₓ n.succ) _ =
    (Finset.univ : Finset$ Finₓ n.succ × perm (Finₓ n)).map Equivₓ.Perm.decomposeFin.symm.toEmbedding :=
  (Finset.univ_map_equiv_to_embedding _).symm

section CycleRange

/-! ### `cycle_range` section

Define the permutations `fin.cycle_range i`, the cycle `(0 1 2 ... i)`.
-/


open Equivₓ.Perm

theorem fin_rotate_succ {n : ℕ} : finRotate n.succ = decompose_fin.symm (1, finRotate n) :=
  by 
    ext i 
    cases n
    ·
      simp 
    refine' Finₓ.cases _ (fun i => _) i
    ·
      simp 
    rw [coe_fin_rotate, decompose_fin_symm_apply_succ, if_congr i.succ_eq_last_succ rfl rfl]
    splitIfs with h
    ·
      simp [h]
    ·
      rw [Finₓ.coe_succ, Function.Injective.map_swap Finₓ.coe_injective, Finₓ.coe_succ, coe_fin_rotate, if_neg h,
        Finₓ.coe_zero, Finₓ.coe_one, swap_apply_of_ne_of_ne (Nat.succ_ne_zero _) (Nat.succ_succ_ne_one _)]

@[simp]
theorem sign_fin_rotate (n : ℕ) : perm.sign (finRotate (n+1)) = (-1^n) :=
  by 
    induction' n with n ih
    ·
      simp 
    ·
      rw [fin_rotate_succ]
      simp [ih, pow_succₓ]

@[simp]
theorem support_fin_rotate {n : ℕ} : support (finRotate (n+2)) = Finset.univ :=
  by 
    ext 
    simp 

theorem support_fin_rotate_of_le {n : ℕ} (h : 2 ≤ n) : support (finRotate n) = Finset.univ :=
  by 
    obtain ⟨m, rfl⟩ := exists_add_of_le h 
    rw [add_commₓ, support_fin_rotate]

theorem is_cycle_fin_rotate {n : ℕ} : is_cycle (finRotate (n+2)) :=
  by 
    refine'
      ⟨0,
        by 
          decide,
        fun x hx' => ⟨x, _⟩⟩
    clear hx' 
    cases' x with x hx 
    rw [coe_coe, zpow_coe_nat, Finₓ.ext_iff, Finₓ.coe_mk]
    induction' x with x ih
    ·
      rfl 
    rw [pow_succₓ, perm.mul_apply, coe_fin_rotate_of_ne_last, ih (lt_transₓ x.lt_succ_self hx)]
    rw [Ne.def, Finₓ.ext_iff, ih (lt_transₓ x.lt_succ_self hx), Finₓ.coe_last]
    exact ne_of_ltₓ (Nat.lt_of_succ_lt_succₓ hx)

theorem is_cycle_fin_rotate_of_le {n : ℕ} (h : 2 ≤ n) : is_cycle (finRotate n) :=
  by 
    obtain ⟨m, rfl⟩ := exists_add_of_le h 
    rw [add_commₓ]
    exact is_cycle_fin_rotate

@[simp]
theorem cycle_type_fin_rotate {n : ℕ} : cycle_type (finRotate (n+2)) = {n+2} :=
  by 
    rw [is_cycle_fin_rotate.cycle_type, support_fin_rotate, ←Fintype.card, Fintype.card_fin]
    rfl

theorem cycle_type_fin_rotate_of_le {n : ℕ} (h : 2 ≤ n) : cycle_type (finRotate n) = {n} :=
  by 
    obtain ⟨m, rfl⟩ := exists_add_of_le h 
    rw [add_commₓ, cycle_type_fin_rotate]

namespace Finₓ

/-- `fin.cycle_range i` is the cycle `(0 1 2 ... i)` leaving `(i+1 ... (n-1))` unchanged. -/
def cycle_range {n : ℕ} (i : Finₓ n) : perm (Finₓ n) :=
  (finRotate (i+1)).extendDomain
    (Equivₓ.ofLeftInverse' (Finₓ.castLe (Nat.succ_le_of_ltₓ i.is_lt)).toEmbedding coeₓ
      (by 
        intro x 
        ext 
        simp ))

theorem cycle_range_of_gt {n : ℕ} {i j : Finₓ n.succ} (h : i < j) : cycle_range i j = j :=
  by 
    rw [cycle_range, of_left_inverse'_eq_of_injective, ←Function.Embedding.to_equiv_range_eq_of_injective,
      ←via_fintype_embedding, via_fintype_embedding_apply_not_mem_range]
    simpa

theorem cycle_range_of_le {n : ℕ} {i j : Finₓ n.succ} (h : j ≤ i) : cycle_range i j = if j = i then 0 else j+1 :=
  by 
    cases n
    ·
      simp 
    have  : j = (Finₓ.castLe (Nat.succ_le_of_ltₓ i.is_lt)).toEmbedding ⟨j, lt_of_le_of_ltₓ h (Nat.lt_succ_selfₓ i)⟩
    ·
      simp 
    ext 
    rw [this, cycle_range, of_left_inverse'_eq_of_injective, ←Function.Embedding.to_equiv_range_eq_of_injective,
      ←via_fintype_embedding, via_fintype_embedding_apply_image, RelEmbedding.coe_fn_to_embedding, coe_cast_le,
      coe_fin_rotate]
    simp only [Finₓ.ext_iff, coe_last, coe_mk, coe_zero, Finₓ.eta, apply_ite coeₓ, cast_le_mk]
    splitIfs with heq
    ·
      rfl
    ·
      rw [Finₓ.coe_add_one_of_lt]
      exact lt_of_lt_of_leₓ (lt_of_le_of_neₓ h (mt (congr_argₓ coeₓ) HEq)) (le_last i)

theorem coe_cycle_range_of_le {n : ℕ} {i j : Finₓ n.succ} (h : j ≤ i) :
  (cycle_range i j : ℕ) = if j = i then 0 else j+1 :=
  by 
    rw [cycle_range_of_le h]
    splitIfs with h'
    ·
      rfl 
    exact
      coe_add_one_of_lt
        (calc (j : ℕ) < i := fin.lt_iff_coe_lt_coe.mp (lt_of_le_of_neₓ h h')
          _ ≤ n := nat.lt_succ_iff.mp i.2
          )

theorem cycle_range_of_lt {n : ℕ} {i j : Finₓ n.succ} (h : j < i) : cycle_range i j = j+1 :=
  by 
    rw [cycle_range_of_le h.le, if_neg h.ne]

theorem coe_cycle_range_of_lt {n : ℕ} {i j : Finₓ n.succ} (h : j < i) : (cycle_range i j : ℕ) = j+1 :=
  by 
    rw [coe_cycle_range_of_le h.le, if_neg h.ne]

theorem cycle_range_of_eq {n : ℕ} {i j : Finₓ n.succ} (h : j = i) : cycle_range i j = 0 :=
  by 
    rw [cycle_range_of_le h.le, if_pos h]

@[simp]
theorem cycle_range_self {n : ℕ} (i : Finₓ n.succ) : cycle_range i i = 0 :=
  cycle_range_of_eq rfl

theorem cycle_range_apply {n : ℕ} (i j : Finₓ n.succ) :
  cycle_range i j = if j < i then j+1 else if j = i then 0 else j :=
  by 
    splitIfs with h₁ h₂
    ·
      exact cycle_range_of_lt h₁
    ·
      exact cycle_range_of_eq h₂
    ·
      exact cycle_range_of_gt (lt_of_le_of_neₓ (le_of_not_gtₓ h₁) (Ne.symm h₂))

@[simp]
theorem cycle_range_zero (n : ℕ) : cycle_range (0 : Finₓ n.succ) = 1 :=
  by 
    ext j 
    refine' Finₓ.cases _ (fun j => _) j
    ·
      simp 
    ·
      rw [cycle_range_of_gt (Finₓ.succ_pos j), one_apply]

@[simp]
theorem cycle_range_last (n : ℕ) : cycle_range (last n) = finRotate (n+1) :=
  by 
    ext i 
    rw [coe_cycle_range_of_le (le_last _), coe_fin_rotate]

@[simp]
theorem cycle_range_zero' {n : ℕ} (h : 0 < n) : cycle_range ⟨0, h⟩ = 1 :=
  by 
    cases' n with n
    ·
      cases h 
    exact cycle_range_zero n

@[simp]
theorem sign_cycle_range {n : ℕ} (i : Finₓ n) : perm.sign (cycle_range i) = (-1^(i : ℕ)) :=
  by 
    simp [cycle_range]

@[simp]
theorem succ_above_cycle_range {n : ℕ} (i j : Finₓ n) : i.succ.succ_above (i.cycle_range j) = swap 0 i.succ j.succ :=
  by 
    cases n
    ·
      rcases j with ⟨_, ⟨⟩⟩
    rcases lt_trichotomyₓ j i with (hlt | heq | hgt)
    ·
      have  : (j+1).cast_succ = j.succ
      ·
        ext 
        rw [coe_cast_succ, coe_succ, Finₓ.coe_add_one_of_lt (lt_of_lt_of_leₓ hlt i.le_last)]
      rw [Finₓ.cycle_range_of_lt hlt, Finₓ.succ_above_below, this, swap_apply_of_ne_of_ne]
      ·
        apply Finₓ.succ_ne_zero
      ·
        exact (Finₓ.succ_injective _).Ne hlt.ne
      ·
        rw [Finₓ.lt_iff_coe_lt_coe]
        simpa [this] using hlt
    ·
      rw [HEq, Finₓ.cycle_range_self, Finₓ.succ_above_below, swap_apply_right, Finₓ.cast_succ_zero]
      ·
        rw [Finₓ.cast_succ_zero]
        apply Finₓ.succ_pos
    ·
      rw [Finₓ.cycle_range_of_gt hgt, Finₓ.succ_above_above, swap_apply_of_ne_of_ne]
      ·
        apply Finₓ.succ_ne_zero
      ·
        apply (Finₓ.succ_injective _).Ne hgt.ne.symm
      ·
        simpa [Finₓ.le_iff_coe_le_coe] using hgt

@[simp]
theorem cycle_range_succ_above {n : ℕ} (i : Finₓ (n+1)) (j : Finₓ n) : i.cycle_range (i.succ_above j) = j.succ :=
  by 
    cases' lt_or_geₓ j.cast_succ i with h h
    ·
      rw [Finₓ.succ_above_below _ _ h, Finₓ.cycle_range_of_lt h, Finₓ.coe_succ_eq_succ]
    ·
      rw [Finₓ.succ_above_above _ _ h, Finₓ.cycle_range_of_gt (fin.le_cast_succ_iff.mp h)]

@[simp]
theorem cycle_range_symm_zero {n : ℕ} (i : Finₓ (n+1)) : i.cycle_range.symm 0 = i :=
  i.cycle_range.injective
    (by 
      simp )

@[simp]
theorem cycle_range_symm_succ {n : ℕ} (i : Finₓ (n+1)) (j : Finₓ n) : i.cycle_range.symm j.succ = i.succ_above j :=
  i.cycle_range.injective
    (by 
      simp )

theorem is_cycle_cycle_range {n : ℕ} {i : Finₓ (n+1)} (h0 : i ≠ 0) : is_cycle (cycle_range i) :=
  by 
    cases' i with i hi 
    cases i
    ·
      exact (h0 rfl).elim 
    exact is_cycle_fin_rotate.extend_domain _

@[simp]
theorem cycle_type_cycle_range {n : ℕ} {i : Finₓ (n+1)} (h0 : i ≠ 0) : cycle_type (cycle_range i) = {i+1} :=
  by 
    cases' i with i hi 
    cases i
    ·
      exact (h0 rfl).elim 
    rw [cycle_range, cycle_type_extend_domain]
    exact cycle_type_fin_rotate

theorem is_three_cycle_cycle_range_two {n : ℕ} : is_three_cycle (cycle_range 2 : perm (Finₓ (n+3))) :=
  by 
    rw [is_three_cycle, cycle_type_cycle_range] <;> decide

end Finₓ

end CycleRange

