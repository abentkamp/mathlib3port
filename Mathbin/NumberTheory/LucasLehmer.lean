import Mathbin.Data.Nat.Parity 
import Mathbin.Data.Pnat.Interval 
import Mathbin.Data.Zmod.Basic 
import Mathbin.GroupTheory.OrderOfElement 
import Mathbin.RingTheory.Fintype 
import Mathbin.Tactic.IntervalCases 
import Mathbin.Tactic.RingExp

/-!
# The Lucas-Lehmer test for Mersenne primes.

We define `lucas_lehmer_residue : Π p : ℕ, zmod (2^p - 1)`, and
prove `lucas_lehmer_residue p = 0 → prime (mersenne p)`.

We construct a tactic `lucas_lehmer.run_test`, which iteratively certifies the arithmetic
required to calculate the residue, and enables us to prove

```
example : prime (mersenne 127) :=
lucas_lehmer_sufficiency _ (by norm_num) (by lucas_lehmer.run_test)
```

## TODO

- Show reverse implication.
- Speed up the calculations using `n ≡ (n % 2^p) + (n / 2^p) [MOD 2^p - 1]`.
- Find some bigger primes!

## History

This development began as a student project by Ainsley Pahljina,
and was then cleaned up for mathlib by Scott Morrison.
The tactic for certified computation of Lucas-Lehmer residues was provided by Mario Carneiro.
-/


/-- The Mersenne numbers, 2^p - 1. -/
def mersenne (p : ℕ) : ℕ :=
  2 ^ p - 1

theorem mersenne_pos {p : ℕ} (h : 0 < p) : 0 < mersenne p :=
  by 
    dsimp [mersenne]
    calc 0 < 2 ^ 1 - 1 :=
      by 
        normNum _ ≤ 2 ^ p - 1 :=
      Nat.pred_le_predₓ (Nat.pow_le_pow_of_le_rightₓ (Nat.succ_posₓ 1) h)

@[simp]
theorem succ_mersenne (k : ℕ) : (mersenne k+1) = 2 ^ k :=
  by 
    rw [mersenne, tsub_add_cancel_of_le]
    exact
      one_le_pow_of_one_le
        (by 
          normNum)
        k

namespace LucasLehmer

open Nat

/-!
We now define three(!) different versions of the recurrence
`s (i+1) = (s i)^2 - 2`.

These versions take values either in `ℤ`, in `zmod (2^p - 1)`, or
in `ℤ` but applying `% (2^p - 1)` at each step.

They are each useful at different points in the proof,
so we take a moment setting up the lemmas relating them.
-/


/-- The recurrence `s (i+1) = (s i)^2 - 2` in `ℤ`. -/
def s : ℕ → ℤ
| 0 => 4
| i+1 => s i ^ 2 - 2

/-- The recurrence `s (i+1) = (s i)^2 - 2` in `zmod (2^p - 1)`. -/
def s_zmod (p : ℕ) : ℕ → Zmod (2 ^ p - 1)
| 0 => 4
| i+1 => s_zmod i ^ 2 - 2

/-- The recurrence `s (i+1) = ((s i)^2 - 2) % (2^p - 1)` in `ℤ`. -/
def s_mod (p : ℕ) : ℕ → ℤ
| 0 => 4 % (2 ^ p - 1)
| i+1 => (s_mod i ^ 2 - 2) % (2 ^ p - 1)

theorem mersenne_int_ne_zero (p : ℕ) (w : 0 < p) : (2 ^ p - 1 : ℤ) ≠ 0 :=
  by 
    apply ne_of_gtₓ 
    simp only [gt_iff_lt, sub_pos]
    exactModCast Nat.one_lt_two_pow p w

theorem s_mod_nonneg (p : ℕ) (w : 0 < p) (i : ℕ) : 0 ≤ s_mod p i :=
  by 
    cases i <;> dsimp [s_mod]
    ·
      exact sup_eq_left.mp rfl
    ·
      apply Int.mod_nonneg 
      exact mersenne_int_ne_zero p w

theorem s_mod_mod (p i : ℕ) : s_mod p i % (2 ^ p - 1) = s_mod p i :=
  by 
    cases i <;> simp [s_mod]

theorem s_mod_lt (p : ℕ) (w : 0 < p) (i : ℕ) : s_mod p i < 2 ^ p - 1 :=
  by 
    rw [←s_mod_mod]
    convert Int.mod_lt _ _
    ·
      refine' (abs_of_nonneg _).symm 
      simp only [sub_nonneg, ge_iff_le]
      exactModCast Nat.one_le_two_pow p
    ·
      exact mersenne_int_ne_zero p w

theorem s_zmod_eq_s (p' : ℕ) (i : ℕ) : s_zmod (p'+2) i = (s i : Zmod ((2 ^ p'+2) - 1)) :=
  by 
    induction' i with i ih
    ·
      dsimp [s, s_zmod]
      normNum
    ·
      pushCast [s, s_zmod, ih]

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem int.coe_nat_pow_pred
(b p : exprℕ())
(w : «expr < »(0, b)) : «expr = »(((«expr - »(«expr ^ »(b, p), 1) : exprℕ()) : exprℤ()), («expr - »(«expr ^ »(b, p), 1) : exprℤ())) :=
begin
  have [] [":", expr «expr ≤ »(1, «expr ^ »(b, p))] [":=", expr nat.one_le_pow p b w],
  push_cast ["[", expr this, "]"] []
end

theorem int.coe_nat_two_pow_pred (p : ℕ) : ((2 ^ p - 1 : ℕ) : ℤ) = (2 ^ p - 1 : ℤ) :=
  int.coe_nat_pow_pred 2 p
    (by 
      decide)

theorem s_zmod_eq_s_mod (p : ℕ) (i : ℕ) : s_zmod p i = (s_mod p i : Zmod (2 ^ p - 1)) :=
  by 
    induction i <;> pushCast [←int.coe_nat_two_pow_pred p, s_mod, s_zmod, *]

/-- The Lucas-Lehmer residue is `s p (p-2)` in `zmod (2^p - 1)`. -/
def lucas_lehmer_residue (p : ℕ) : Zmod (2 ^ p - 1) :=
  s_zmod p (p - 2)

theorem residue_eq_zero_iff_s_mod_eq_zero (p : ℕ) (w : 1 < p) : lucas_lehmer_residue p = 0 ↔ s_mod p (p - 2) = 0 :=
  by 
    dsimp [lucas_lehmer_residue]
    rw [s_zmod_eq_s_mod p]
    split 
    ·
      intro h 
      simp [Zmod.int_coe_zmod_eq_zero_iff_dvd] at h 
      apply Int.eq_zero_of_dvd_of_nonneg_of_lt _ _ h <;> clear h 
      apply s_mod_nonneg _ (Nat.lt_of_succ_ltₓ w)
      convert s_mod_lt _ (Nat.lt_of_succ_ltₓ w) (p - 2)
      pushCast [Nat.one_le_two_pow p]
      rfl
    ·
      intro h 
      rw [h]
      simp 

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:704:9: unsupported derive handler decidable_pred
/--
A Mersenne number `2^p-1` is prime if and only if
the Lucas-Lehmer residue `s p (p-2) % (2^p - 1)` is zero.
-/ @[derive #[expr decidable_pred]] def lucas_lehmer_test (p : exprℕ()) : exprProp() :=
«expr = »(lucas_lehmer_residue p, 0)

/-- `q` is defined as the minimum factor of `mersenne p`, bundled as an `ℕ+`. -/
def q (p : ℕ) : ℕ+ :=
  ⟨Nat.minFac (mersenne p), Nat.min_fac_pos (mersenne p)⟩

@[local instance]
theorem fact_pnat_pos (q : ℕ+) : Fact (0 < (q : ℕ)) :=
  ⟨q.2⟩

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:704:9: unsupported derive handler add_comm_group
/-- We construct the ring `X q` as ℤ/qℤ + √3 ℤ/qℤ. -/
@[derive #["[", expr add_comm_group, ",", expr decidable_eq, ",", expr fintype, ",", expr inhabited, "]"]]
def X (q : «exprℕ+»()) : Type :=
«expr × »(zmod q, zmod q)

namespace X

variable{q : ℕ+}

@[ext]
theorem ext {x y : X q} (h₁ : x.1 = y.1) (h₂ : x.2 = y.2) : x = y :=
  by 
    cases x 
    cases y 
    congr <;> assumption

@[simp]
theorem add_fst (x y : X q) : (x+y).1 = x.1+y.1 :=
  rfl

@[simp]
theorem add_snd (x y : X q) : (x+y).2 = x.2+y.2 :=
  rfl

@[simp]
theorem neg_fst (x : X q) : (-x).1 = -x.1 :=
  rfl

@[simp]
theorem neg_snd (x : X q) : (-x).2 = -x.2 :=
  rfl

instance  : Mul (X q) :=
  { mul := fun x y => ((x.1*y.1)+(3*x.2)*y.2, (x.1*y.2)+x.2*y.1) }

@[simp]
theorem mul_fst (x y : X q) : (x*y).1 = (x.1*y.1)+(3*x.2)*y.2 :=
  rfl

@[simp]
theorem mul_snd (x y : X q) : (x*y).2 = (x.1*y.2)+x.2*y.1 :=
  rfl

instance  : HasOne (X q) :=
  { one := ⟨1, 0⟩ }

@[simp]
theorem one_fst : (1 : X q).1 = 1 :=
  rfl

@[simp]
theorem one_snd : (1 : X q).2 = 0 :=
  rfl

@[simp]
theorem bit0_fst (x : X q) : (bit0 x).1 = bit0 x.1 :=
  rfl

@[simp]
theorem bit0_snd (x : X q) : (bit0 x).2 = bit0 x.2 :=
  rfl

@[simp]
theorem bit1_fst (x : X q) : (bit1 x).1 = bit1 x.1 :=
  rfl

@[simp]
theorem bit1_snd (x : X q) : (bit1 x).2 = bit0 x.2 :=
  by 
    dsimp [bit1]
    simp 

instance  : Monoidₓ (X q) :=
  { (inferInstance : Mul (X q)) with
    mul_assoc :=
      fun x y z =>
        by 
          ext <;>
            ·
              dsimp 
              ring,
    one := ⟨1, 0⟩,
    one_mul :=
      fun x =>
        by 
          ext <;> simp ,
    mul_one :=
      fun x =>
        by 
          ext <;> simp  }

theorem left_distrib (x y z : X q) : (x*y+z) = (x*y)+x*z :=
  by 
    ext <;>
      ·
        dsimp 
        ring

theorem right_distrib (x y z : X q) : ((x+y)*z) = (x*z)+y*z :=
  by 
    ext <;>
      ·
        dsimp 
        ring

instance  : Ringₓ (X q) :=
  { (inferInstance : AddCommGroupₓ (X q)), (inferInstance : Monoidₓ (X q)) with left_distrib := left_distrib,
    right_distrib := right_distrib }

instance  : CommRingₓ (X q) :=
  { (inferInstance : Ringₓ (X q)) with
    mul_comm :=
      fun x y =>
        by 
          ext <;>
            ·
              dsimp 
              ring }

instance  [Fact (1 < (q : ℕ))] : Nontrivial (X q) :=
  ⟨⟨0, 1,
      fun h =>
        by 
          injection h with h1 _ 
          exact zero_ne_one h1⟩⟩

@[simp]
theorem nat_coe_fst (n : ℕ) : (n : X q).fst = (n : Zmod q) :=
  by 
    induction n
    ·
      rfl
    ·
      dsimp 
      simp only [add_left_injₓ]
      exact n_ih

@[simp]
theorem nat_coe_snd (n : ℕ) : (n : X q).snd = (0 : Zmod q) :=
  by 
    induction n
    ·
      rfl
    ·
      dsimp 
      simp only [add_zeroₓ]
      exact n_ih

@[simp]
theorem int_coe_fst (n : ℤ) : (n : X q).fst = (n : Zmod q) :=
  by 
    induction n <;> simp 

@[simp]
theorem int_coe_snd (n : ℤ) : (n : X q).snd = (0 : Zmod q) :=
  by 
    induction n <;> simp 

@[normCast]
theorem coe_mul (n m : ℤ) : ((n*m : ℤ) : X q) = (n : X q)*(m : X q) :=
  by 
    ext <;> simp  <;> ring

@[normCast]
theorem coe_nat (n : ℕ) : ((n : ℤ) : X q) = (n : X q) :=
  by 
    ext <;> simp 

/-- The cardinality of `X` is `q^2`. -/
theorem X_card : Fintype.card (X q) = q ^ 2 :=
  by 
    dsimp [X]
    rw [Fintype.card_prod, Zmod.card q]
    ring

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- There are strictly fewer than `q^2` units, since `0` is not a unit. -/
theorem units_card (w : «expr < »(1, q)) : «expr < »(fintype.card (units (X q)), «expr ^ »(q, 2)) :=
begin
  haveI [] [":", expr fact «expr < »(1, (q : exprℕ()))] [":=", expr ⟨w⟩],
  convert [] [expr card_units_lt (X q)] [],
  rw [expr X_card] []
end

/-- We define `ω = 2 + √3`. -/
def ω : X q :=
  (2, 1)

/-- We define `ωb = 2 - √3`, which is the inverse of `ω`. -/
def ωb : X q :=
  (2, -1)

theorem ω_mul_ωb (q : ℕ+) : ((ω : X q)*ωb) = 1 :=
  by 
    dsimp [ω, ωb]
    ext <;> simp  <;> ring

theorem ωb_mul_ω (q : ℕ+) : ((ωb : X q)*ω) = 1 :=
  by 
    dsimp [ω, ωb]
    ext <;> simp  <;> ring

/-- A closed form for the recurrence relation. -/
theorem closed_form (i : ℕ) : (s i : X q) = ((ω : X q) ^ 2 ^ i)+(ωb : X q) ^ 2 ^ i :=
  by 
    induction' i with i ih
    ·
      dsimp [s, ω, ωb]
      ext <;>
        ·
          simp  <;> rfl
    ·
      calc (s (i+1) : X q) = (s i ^ 2 - 2 : ℤ) := rfl _ = (s i : X q) ^ 2 - 2 :=
        by 
          pushCast _ = ((ω ^ 2 ^ i)+ωb ^ 2 ^ i) ^ 2 - 2 :=
        by 
          rw [ih]_ = ((((ω ^ 2 ^ i) ^ 2)+(ωb ^ 2 ^ i) ^ 2)+2*(ωb ^ 2 ^ i)*ω ^ 2 ^ i) - 2 :=
        by 
          ring _ = ((ω ^ 2 ^ i) ^ 2)+(ωb ^ 2 ^ i) ^ 2 :=
        by 
          rw [←mul_powₓ ωb ω, ωb_mul_ω, one_pow, mul_oneₓ, add_sub_cancel]_ = (ω ^ 2 ^ i+1)+ωb ^ 2 ^ i+1 :=
        by 
          rw [←pow_mulₓ, ←pow_mulₓ, pow_succ'ₓ]

end X

open X

/-!
Here and below, we introduce `p' = p - 2`, in order to avoid using subtraction in `ℕ`.
-/


/-- If `1 < p`, then `q p`, the smallest prime factor of `mersenne p`, is more than 2. -/
theorem two_lt_q (p' : ℕ) : 2 < q (p'+2) :=
  by 
    byContra H 
    simp  at H 
    intervalCases q (p'+2) <;> clear H
    ·
      dsimp [q]  at h 
      injection h with h' 
      clear h 
      simp [mersenne] at h' 
      exact
        lt_irreflₓ 2
          (calc 2 ≤ p'+2 := Nat.le_add_leftₓ _ _ 
            _ < 2 ^ p'+2 := Nat.lt_two_pow _ 
            _ = 2 :=
            Nat.pred_injₓ (Nat.one_le_two_pow _)
              (by 
                decide)
              h'
            )
    ·
      dsimp [q]  at h 
      injection h with h' 
      clear h 
      rw [mersenne, Pnat.one_coe, Nat.min_fac_eq_two_iff, pow_succₓ] at h' 
      exact Nat.two_not_dvd_two_mul_sub_one (Nat.one_le_two_pow _) h'

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem ω_pow_formula
(p' : exprℕ())
(h : «expr = »(lucas_lehmer_residue «expr + »(p', 2), 0)) : «expr∃ , »((k : exprℤ()), «expr = »(«expr ^ »((ω : X (q «expr + »(p', 2))), «expr ^ »(2, «expr + »(p', 1))), «expr - »(«expr * »(«expr * »(k, mersenne «expr + »(p', 2)), «expr ^ »((ω : X (q «expr + »(p', 2))), «expr ^ »(2, p'))), 1))) :=
begin
  dsimp [] ["[", expr lucas_lehmer_residue, "]"] [] ["at", ident h],
  rw [expr s_zmod_eq_s p'] ["at", ident h],
  simp [] [] [] ["[", expr zmod.int_coe_zmod_eq_zero_iff_dvd, "]"] [] ["at", ident h],
  cases [expr h] ["with", ident k, ident h],
  use [expr k],
  replace [ident h] [] [":=", expr congr_arg (λ n : exprℤ(), (n : X (q «expr + »(p', 2)))) h],
  dsimp [] [] [] ["at", ident h],
  rw [expr closed_form] ["at", ident h],
  replace [ident h] [] [":=", expr congr_arg (λ x, «expr * »(«expr ^ »(ω, «expr ^ »(2, p')), x)) h],
  dsimp [] [] [] ["at", ident h],
  have [ident t] [":", expr «expr = »(«expr + »(«expr ^ »(2, p'), «expr ^ »(2, p')), «expr ^ »(2, «expr + »(p', 1)))] [":=", expr by ring_exp [] []],
  rw ["[", expr mul_add, ",", "<-", expr pow_add ω, ",", expr t, ",", "<-", expr mul_pow ω ωb «expr ^ »(2, p'), ",", expr ω_mul_ωb, ",", expr one_pow, "]"] ["at", ident h],
  rw ["[", expr mul_comm, ",", expr coe_mul, "]"] ["at", ident h],
  rw ["[", expr mul_comm _ (k : X (q «expr + »(p', 2))), "]"] ["at", ident h],
  replace [ident h] [] [":=", expr eq_sub_of_add_eq h],
  exact_mod_cast [expr h]
end

/-- `q` is the minimum factor of `mersenne p`, so `M p = 0` in `X q`. -/
theorem mersenne_coe_X (p : ℕ) : (mersenne p : X (q p)) = 0 :=
  by 
    ext <;> simp [mersenne, q, Zmod.nat_coe_zmod_eq_zero_iff_dvd, -pow_pos]
    apply Nat.min_fac_dvd

theorem ω_pow_eq_neg_one (p' : ℕ) (h : lucas_lehmer_residue (p'+2) = 0) : ((ω : X (q (p'+2))) ^ 2 ^ p'+1) = -1 :=
  by 
    cases' ω_pow_formula p' h with k w 
    rw [mersenne_coe_X] at w 
    simpa using w

theorem ω_pow_eq_one (p' : ℕ) (h : lucas_lehmer_residue (p'+2) = 0) : ((ω : X (q (p'+2))) ^ 2 ^ p'+2) = 1 :=
  calc ((ω : X (q (p'+2))) ^ 2 ^ p'+2) = (ω ^ 2 ^ p'+1) ^ 2 :=
    by 
      rw [←pow_mulₓ, ←pow_succ'ₓ]
    _ = -1 ^ 2 :=
    by 
      rw [ω_pow_eq_neg_one p' h]
    _ = 1 :=
    by 
      simp 
    

/-- `ω` as an element of the group of units. -/
def ω_unit (p : ℕ) : Units (X (q p)) :=
  { val := ω, inv := ωb,
    val_inv :=
      by 
        simp [ω_mul_ωb],
    inv_val :=
      by 
        simp [ωb_mul_ω] }

@[simp]
theorem ω_unit_coe (p : ℕ) : (ω_unit p : X (q p)) = ω :=
  rfl

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- The order of `ω` in the unit group is exactly `2^p`. -/
theorem order_ω
(p' : exprℕ())
(h : «expr = »(lucas_lehmer_residue «expr + »(p', 2), 0)) : «expr = »(order_of (ω_unit «expr + »(p', 2)), «expr ^ »(2, «expr + »(p', 2))) :=
begin
  apply [expr nat.eq_prime_pow_of_dvd_least_prime_pow],
  { norm_num [] [] },
  { intro [ident o],
    have [ident ω_pow] [] [":=", expr order_of_dvd_iff_pow_eq_one.1 o],
    replace [ident ω_pow] [] [":=", expr congr_arg (units.coe_hom (X (q «expr + »(p', 2))) : units (X (q «expr + »(p', 2))) → X (q «expr + »(p', 2))) ω_pow],
    simp [] [] [] [] [] ["at", ident ω_pow],
    have [ident h] [":", expr «expr = »((1 : zmod (q «expr + »(p', 2))), «expr- »(1))] [":=", expr congr_arg prod.fst (ω_pow.symm.trans (ω_pow_eq_neg_one p' h))],
    haveI [] [":", expr fact «expr < »(2, (q «expr + »(p', 2) : exprℕ()))] [":=", expr ⟨two_lt_q _⟩],
    apply [expr zmod.neg_one_ne_one h.symm] },
  { apply [expr order_of_dvd_iff_pow_eq_one.2],
    apply [expr units.ext],
    push_cast [] [],
    exact [expr ω_pow_eq_one p' h] }
end

theorem order_ineq (p' : ℕ) (h : lucas_lehmer_residue (p'+2) = 0) : (2 ^ p'+2) < (q (p'+2) : ℕ) ^ 2 :=
  calc (2 ^ p'+2) = orderOf (ω_unit (p'+2)) := (order_ω p' h).symm 
    _ ≤ Fintype.card (Units (X _)) := order_of_le_card_univ 
    _ < (q (p'+2) : ℕ) ^ 2 := units_card (Nat.lt_of_succ_ltₓ (two_lt_q _))
    

end LucasLehmer

export LucasLehmer(LucasLehmerTest lucasLehmerResidue)

open LucasLehmer

-- error in NumberTheory.LucasLehmer: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem lucas_lehmer_sufficiency (p : exprℕ()) (w : «expr < »(1, p)) : lucas_lehmer_test p → (mersenne p).prime :=
begin
  let [ident p'] [] [":=", expr «expr - »(p, 2)],
  have [ident z] [":", expr «expr = »(p, «expr + »(p', 2))] [":=", expr (tsub_eq_iff_eq_add_of_le w.nat_succ_le).mp rfl],
  have [ident w] [":", expr «expr < »(1, «expr + »(p', 2))] [":=", expr nat.lt_of_sub_eq_succ rfl],
  contrapose [] [],
  intros [ident a, ident t],
  rw [expr z] ["at", ident a],
  rw [expr z] ["at", ident t],
  have [ident h₁] [] [":=", expr order_ineq p' t],
  have [ident h₂] [] [":=", expr nat.min_fac_sq_le_self (mersenne_pos (nat.lt_of_succ_lt w)) a],
  have [ident h] [] [":=", expr lt_of_lt_of_le h₁ h₂],
  exact [expr not_lt_of_ge (nat.sub_le _ _) h]
end

example  : (mersenne 5).Prime :=
  lucas_lehmer_sufficiency 5
    (by 
      normNum)
    (by 
      decide)

namespace LucasLehmer

open Tactic

unsafe instance nat_pexpr : has_to_pexpr ℕ :=
  ⟨pexpr.of_expr ∘ fun n => reflect n⟩

unsafe instance int_pexpr : has_to_pexpr ℤ :=
  ⟨pexpr.of_expr ∘ fun n => reflect n⟩

theorem s_mod_succ {p a i b c} (h1 : (2 ^ p - 1 : ℤ) = a) (h2 : s_mod p i = b) (h3 : ((b*b) - 2) % a = c) :
  s_mod p (i+1) = c :=
  by 
    dsimp [s_mod, mersenne]
    rw [h1, h2, sq, h3]

/--
Given a goal of the form `lucas_lehmer_test p`,
attempt to do the calculation using `norm_num` to certify each step.
-/
unsafe def run_test : tactic Unit :=
  do 
    let quote.1 (lucas_lehmer_test (%%ₓp)) ← target 
    sorry 
    sorry 
    let p ← eval_expr ℕ p 
    let M : ℤ := 2 ^ p - 1
    let t ← to_expr (pquote.1 ((2 ^ %%ₓp) - 1 = %%ₓM))
    let v ←
      to_expr
          (pquote.1
            (by 
              normNum :
            (2 ^ %%ₓp) - 1 = %%ₓM))
    let w ← assertv `w t v 
    sorry 
    let t ← to_expr (pquote.1 (s_mod (%%ₓp) 0 = 4))
    let v ←
      to_expr
          (pquote.1
            (by 
              normNum [LucasLehmer.sMod] :
            s_mod (%%ₓp) 0 = 4))
    let h ← assertv `h t v 
    iterate_exactly (p - 2) sorry 
    let h ← get_local `h 
    exact h

end LucasLehmer

/-- We verify that the tactic works to prove `127.prime`. -/
example  : (mersenne 7).Prime :=
  lucas_lehmer_sufficiency _
    (by 
      normNum)
    (by 
      runTac 
        lucas_lehmer.run_test)

/-!
This implementation works successfully to prove `(2^127 - 1).prime`,
and all the Mersenne primes up to this point appear in [archive/examples/mersenne_primes.lean].

`(2^127 - 1).prime` takes about 5 minutes to run (depending on your CPU!),
and unfortunately the next Mersenne prime `(2^521 - 1)`,
which was the first "computer era" prime,
is out of reach with the current implementation.

There's still low hanging fruit available to do faster computations
based on the formula
  n ≡ (n % 2^p) + (n / 2^p) [MOD 2^p - 1]
and the fact that `% 2^p` and `/ 2^p` can be very efficient on the binary representation.
Someone should do this, too!
-/


theorem modeq_mersenne (n k : ℕ) : k ≡ (k / 2 ^ n)+k % 2 ^ n [MOD 2 ^ n - 1] :=
  by 
    conv  in k => rw [←Nat.div_add_mod k (2 ^ n)]
    refine' Nat.Modeq.add_right _ _ 
    conv  => congr skip skip rw [←one_mulₓ (k / 2 ^ n)]
    exact
      (Nat.modeq_sub$
            pow_pos
              (by 
                normNum :
              0 < 2)
              _).mul_right
        _

