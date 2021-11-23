import Mathbin.Algebra.GcdMonoid.Basic 
import Mathbin.Data.Multiset.Lattice

/-!
# GCD and LCM operations on multisets

## Main definitions

- `multiset.gcd` - the greatest common denominator of a `multiset` of elements of a `gcd_monoid`
- `multiset.lcm` - the least common multiple of a `multiset` of elements of a `gcd_monoid`

## Implementation notes

TODO: simplify with a tactic and `data.multiset.lattice`

## Tags

multiset, gcd
-/


namespace Multiset

variable{α : Type _}[CommCancelMonoidWithZero α][NormalizedGcdMonoid α]

/-! ### lcm -/


section Lcm

/-- Least common multiple of a multiset -/
def lcm (s : Multiset α) : α :=
  s.fold GcdMonoid.lcm 1

@[simp]
theorem lcm_zero : (0 : Multiset α).lcm = 1 :=
  fold_zero _ _

@[simp]
theorem lcm_cons (a : α) (s : Multiset α) : (a ::ₘ s).lcm = GcdMonoid.lcm a s.lcm :=
  fold_cons_left _ _ _ _

@[simp]
theorem lcm_singleton {a : α} : ({a} : Multiset α).lcm = normalize a :=
  (fold_singleton _ _ _).trans$ lcm_one_right _

@[simp]
theorem lcm_add (s₁ s₂ : Multiset α) : (s₁+s₂).lcm = GcdMonoid.lcm s₁.lcm s₂.lcm :=
  Eq.trans
    (by 
      simp [lcm])
    (fold_add _ _ _ _ _)

-- error in Algebra.GcdMonoid.Multiset: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem lcm_dvd {s : multiset α} {a : α} : «expr ↔ »(«expr ∣ »(s.lcm, a), ∀ b «expr ∈ » s, «expr ∣ »(b, a)) :=
multiset.induction_on s (by simp [] [] [] [] [] []) (by simp [] [] [] ["[", expr or_imp_distrib, ",", expr forall_and_distrib, ",", expr lcm_dvd_iff, "]"] [] [] { contextual := tt })

theorem dvd_lcm {s : Multiset α} {a : α} (h : a ∈ s) : a ∣ s.lcm :=
  lcm_dvd.1 dvd_rfl _ h

theorem lcm_mono {s₁ s₂ : Multiset α} (h : s₁ ⊆ s₂) : s₁.lcm ∣ s₂.lcm :=
  lcm_dvd.2$ fun b hb => dvd_lcm (h hb)

@[simp]
theorem normalize_lcm (s : Multiset α) : normalize s.lcm = s.lcm :=
  Multiset.induction_on s
      (by 
        simp )$
    fun a s IH =>
      by 
        simp 

variable[DecidableEq α]

@[simp]
theorem lcm_erase_dup (s : Multiset α) : (erase_dup s).lcm = s.lcm :=
  Multiset.induction_on s
      (by 
        simp )$
    fun a s IH =>
      by 
        byCases' a ∈ s <;> simp [IH, h]
        unfold lcm 
        rw [←cons_erase h, fold_cons_left, ←lcm_assoc, lcm_same]
        apply lcm_eq_of_associated_left (associated_normalize _)

@[simp]
theorem lcm_ndunion (s₁ s₂ : Multiset α) : (ndunion s₁ s₂).lcm = GcdMonoid.lcm s₁.lcm s₂.lcm :=
  by 
    rw [←lcm_erase_dup, erase_dup_ext.2, lcm_erase_dup, lcm_add]
    simp 

@[simp]
theorem lcm_union (s₁ s₂ : Multiset α) : (s₁ ∪ s₂).lcm = GcdMonoid.lcm s₁.lcm s₂.lcm :=
  by 
    rw [←lcm_erase_dup, erase_dup_ext.2, lcm_erase_dup, lcm_add]
    simp 

@[simp]
theorem lcm_ndinsert (a : α) (s : Multiset α) : (ndinsert a s).lcm = GcdMonoid.lcm a s.lcm :=
  by 
    rw [←lcm_erase_dup, erase_dup_ext.2, lcm_erase_dup, lcm_cons]
    simp 

end Lcm

/-! ### gcd -/


section Gcd

/-- Greatest common divisor of a multiset -/
def gcd (s : Multiset α) : α :=
  s.fold GcdMonoid.gcd 0

@[simp]
theorem gcd_zero : (0 : Multiset α).gcd = 0 :=
  fold_zero _ _

@[simp]
theorem gcd_cons (a : α) (s : Multiset α) : (a ::ₘ s).gcd = GcdMonoid.gcd a s.gcd :=
  fold_cons_left _ _ _ _

@[simp]
theorem gcd_singleton {a : α} : ({a} : Multiset α).gcd = normalize a :=
  (fold_singleton _ _ _).trans$ gcd_zero_right _

@[simp]
theorem gcd_add (s₁ s₂ : Multiset α) : (s₁+s₂).gcd = GcdMonoid.gcd s₁.gcd s₂.gcd :=
  Eq.trans
    (by 
      simp [gcd])
    (fold_add _ _ _ _ _)

-- error in Algebra.GcdMonoid.Multiset: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem dvd_gcd {s : multiset α} {a : α} : «expr ↔ »(«expr ∣ »(a, s.gcd), ∀ b «expr ∈ » s, «expr ∣ »(a, b)) :=
multiset.induction_on s (by simp [] [] [] [] [] []) (by simp [] [] [] ["[", expr or_imp_distrib, ",", expr forall_and_distrib, ",", expr dvd_gcd_iff, "]"] [] [] { contextual := tt })

theorem gcd_dvd {s : Multiset α} {a : α} (h : a ∈ s) : s.gcd ∣ a :=
  dvd_gcd.1 dvd_rfl _ h

theorem gcd_mono {s₁ s₂ : Multiset α} (h : s₁ ⊆ s₂) : s₂.gcd ∣ s₁.gcd :=
  dvd_gcd.2$ fun b hb => gcd_dvd (h hb)

@[simp]
theorem normalize_gcd (s : Multiset α) : normalize s.gcd = s.gcd :=
  Multiset.induction_on s
      (by 
        simp )$
    fun a s IH =>
      by 
        simp 

theorem gcd_eq_zero_iff (s : Multiset α) : s.gcd = 0 ↔ ∀ x : α, x ∈ s → x = 0 :=
  by 
    split 
    ·
      intro h x hx 
      apply eq_zero_of_zero_dvd 
      rw [←h]
      apply gcd_dvd hx
    ·
      apply s.induction_on
      ·
        simp 
      intro a s sgcd h 
      simp [h a (mem_cons_self a s), sgcd fun x hx => h x (mem_cons_of_mem hx)]

variable[DecidableEq α]

@[simp]
theorem gcd_erase_dup (s : Multiset α) : (erase_dup s).gcd = s.gcd :=
  Multiset.induction_on s
      (by 
        simp )$
    fun a s IH =>
      by 
        byCases' a ∈ s <;> simp [IH, h]
        unfold gcd 
        rw [←cons_erase h, fold_cons_left, ←gcd_assoc, gcd_same]
        apply (associated_normalize _).gcd_eq_left

@[simp]
theorem gcd_ndunion (s₁ s₂ : Multiset α) : (ndunion s₁ s₂).gcd = GcdMonoid.gcd s₁.gcd s₂.gcd :=
  by 
    rw [←gcd_erase_dup, erase_dup_ext.2, gcd_erase_dup, gcd_add]
    simp 

@[simp]
theorem gcd_union (s₁ s₂ : Multiset α) : (s₁ ∪ s₂).gcd = GcdMonoid.gcd s₁.gcd s₂.gcd :=
  by 
    rw [←gcd_erase_dup, erase_dup_ext.2, gcd_erase_dup, gcd_add]
    simp 

@[simp]
theorem gcd_ndinsert (a : α) (s : Multiset α) : (ndinsert a s).gcd = GcdMonoid.gcd a s.gcd :=
  by 
    rw [←gcd_erase_dup, erase_dup_ext.2, gcd_erase_dup, gcd_cons]
    simp 

end Gcd

end Multiset

