import Mathbin.Data.Equiv.Encodable.Basic 
import Mathbin.Algebra.EuclideanDomain 
import Mathbin.Data.Nat.Gcd 
import Mathbin.Data.Int.Cast

/-!
# Basics for the Rational Numbers

## Summary

We define a rational number `q` as a structure `{ num, denom, pos, cop }`, where
- `num` is the numerator of `q`,
- `denom` is the denominator of `q`,
- `pos` is a proof that `denom > 0`, and
- `cop` is a proof `num` and `denom` are coprime.

We then define the expected (discrete) field structure on `ℚ` and prove basic lemmas about it.
Moreoever, we provide the expected casts from `ℕ` and `ℤ` into `ℚ`, i.e. `(↑n : ℚ) = n / 1`.

## Main Definitions

- `rat` is the structure encoding `ℚ`.
- `rat.mk n d` constructs a rational number `q = n / d` from `n d : ℤ`.

## Notations

- `/.` is infix notation for `rat.mk`.

## Tags

rat, rationals, field, ℚ, numerator, denominator, num, denom
-/


/-- `rat`, or `ℚ`, is the type of rational numbers. It is defined
  as the set of pairs ⟨n, d⟩ of integers such that `d` is positive and `n` and
  `d` are coprime. This representation is preferred to the quotient
  because without periodic reduction, the numerator and denominator can grow
  exponentially (for example, adding 1/2 to itself repeatedly). -/
structure Rat where mk' :: 
  num : ℤ 
  denom : ℕ 
  Pos : 0 < denom 
  cop : num.nat_abs.coprime denom

notation "ℚ" => Rat

namespace Rat

/-- String representation of a rational numbers, used in `has_repr`, `has_to_string`, and
`has_to_format` instances. -/
protected def reprₓ : ℚ → Stringₓ
| ⟨n, d, _, _⟩ => if d = 1 then _root_.repr n else _root_.repr n ++ "/" ++ _root_.repr d

instance : HasRepr ℚ :=
  ⟨Rat.repr⟩

instance : HasToString ℚ :=
  ⟨Rat.repr⟩

unsafe instance : has_to_format ℚ :=
  ⟨coeₓ ∘ Rat.repr⟩

instance : Encodable ℚ :=
  Encodable.ofEquiv (Σ n : ℤ, { d : ℕ // 0 < d ∧ n.nat_abs.coprime d })
    ⟨fun ⟨a, b, c, d⟩ => ⟨a, b, c, d⟩, fun ⟨a, b, c, d⟩ => ⟨a, b, c, d⟩, fun ⟨a, b, c, d⟩ => rfl,
      fun ⟨a, b, c, d⟩ => rfl⟩

/-- Embed an integer as a rational number -/
def of_int (n : ℤ) : ℚ :=
  ⟨n, 1, Nat.one_posₓ, Nat.coprime_one_rightₓ _⟩

instance : HasZero ℚ :=
  ⟨of_int 0⟩

instance : HasOne ℚ :=
  ⟨of_int 1⟩

instance : Inhabited ℚ :=
  ⟨0⟩

/-- Form the quotient `n / d` where `n:ℤ` and `d:ℕ+` (not necessarily coprime) -/
def mk_pnat (n : ℤ) : ℕ+ → ℚ
| ⟨d, dpos⟩ =>
  let n' := n.nat_abs 
  let g := n'.gcd d
  ⟨n / g, d / g,
    by 
      apply (Nat.le_div_iff_mul_leₓ _ _ (Nat.gcd_pos_of_pos_rightₓ _ dpos)).2
      simp 
      exact Nat.le_of_dvdₓ dpos (Nat.gcd_dvd_rightₓ _ _),
    by 
      have  : Int.natAbs (n / ↑g) = n' / g
      ·
        cases' Int.nat_abs_eq n with e e <;> rw [e]
        ·
          rfl 
        rw [Int.neg_div_of_dvd, Int.nat_abs_neg]
        ·
          rfl 
        exact Int.coe_nat_dvd.2 (Nat.gcd_dvd_leftₓ _ _)
      rw [this]
      exact Nat.coprime_div_gcd_div_gcdₓ (Nat.gcd_pos_of_pos_rightₓ _ dpos)⟩

/-- Form the quotient `n / d` where `n:ℤ` and `d:ℕ`. In the case `d = 0`, we
  define `n / 0 = 0` by convention. -/
def mk_nat (n : ℤ) (d : ℕ) : ℚ :=
  if d0 : d = 0 then 0 else mk_pnat n ⟨d, Nat.pos_of_ne_zeroₓ d0⟩

/-- Form the quotient `n / d` where `n d : ℤ`. -/
def mk : ℤ → ℤ → ℚ
| n, (d : ℕ) => mk_nat n d
| n, -[1+ d] => mk_pnat (-n) d.succ_pnat

localized [Rat] infixl:70 " /. " => Rat.mk

theorem mk_pnat_eq n d h : mk_pnat n ⟨d, h⟩ = n /. d :=
  by 
    change n /. d with dite _ _ _ <;> simp [ne_of_gtₓ h]

theorem mk_nat_eq n d : mk_nat n d = n /. d :=
  rfl

@[simp]
theorem mk_zero n : n /. 0 = 0 :=
  rfl

@[simp]
theorem zero_mk_pnat n : mk_pnat 0 n = 0 :=
  by 
    cases n <;> simp [mk_pnat] <;> change Int.natAbs 0 with 0 <;> simp  <;> rfl

@[simp]
theorem zero_mk_nat n : mk_nat 0 n = 0 :=
  by 
    byCases' n = 0 <;> simp [mk_nat]

@[simp]
theorem zero_mk n : 0 /. n = 0 :=
  by 
    cases n <;> simp [mk]

private theorem gcd_abs_dvd_left {a b} : (Nat.gcdₓ (Int.natAbs a) b : ℤ) ∣ a :=
  Int.dvd_nat_abs.1$ Int.coe_nat_dvd.2$ Nat.gcd_dvd_leftₓ (Int.natAbs a) b

@[simp]
theorem mk_eq_zero {a b : ℤ} (b0 : b ≠ 0) : a /. b = 0 ↔ a = 0 :=
  by 
    constructor <;>
      intro h <;> [skip,
        ·
          subst a 
          simp ]
    have  : ∀ {a b}, mk_pnat a b = 0 → a = 0
    ·
      intro a b e 
      cases' b with b h 
      injection e with e 
      apply Int.eq_mul_of_div_eq_right gcd_abs_dvd_left e 
    cases' b with b <;> simp [mk, mk_nat] at h
    ·
      simp [mt (congr_argₓ Int.ofNat) b0] at h 
      exact this h
    ·
      apply neg_injective 
      simp [this h]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (b «expr > » 0)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (d «expr > » 0)
theorem mk_eq : ∀ {a b c d : ℤ} hb : b ≠ 0 hd : d ≠ 0, a /. b = c /. d ↔ (a*d) = c*b :=
  suffices ∀ a b c d hb hd, mk_pnat a ⟨b, hb⟩ = mk_pnat c ⟨d, hd⟩ ↔ (a*d) = c*b by 
    intros 
    cases' b with b b <;> simp [mk, mk_nat, Nat.succPnat]
    simp [mt (congr_argₓ Int.ofNat) hb]
    all_goals 
      cases' d with d d <;> simp [mk, mk_nat, Nat.succPnat]
      simp [mt (congr_argₓ Int.ofNat) hd]
      all_goals 
        rw [this]
        try 
          rfl
    ·
      change ((a*↑d.succ) = (-c)*↑b) ↔ (a*-d.succ) = c*b 
      constructor <;>
        intro h <;>
          apply neg_injective <;>
            simpa [left_distrib, neg_add_eq_iff_eq_add, eq_neg_iff_add_eq_zero, neg_eq_iff_add_eq_zero] using h
    ·
      change (((-a)*↑d) = c*b.succ) ↔ (a*d) = c*-b.succ 
      constructor <;> intro h <;> apply neg_injective <;> simpa [left_distrib, eq_comm] using h
    ·
      change (((-a)*d.succ) = (-c)*b.succ) ↔ (a*-d.succ) = c*-b.succ 
      simp [left_distrib, sub_eq_add_neg]
      cc 
  by 
    intros 
    simp [mk_pnat]
    constructor <;> intro h
    ·
      cases' h with ha hb 
      have ha
      ·
        have dv := @gcd_abs_dvd_left 
        have  := Int.eq_mul_of_div_eq_right dv ha 
        rw [←Int.mul_div_assoc _ dv] at this 
        exact Int.eq_mul_of_div_eq_left (dv.mul_left _) this.symm 
      have hb
      ·
        have dv := fun {a b} => Nat.gcd_dvd_rightₓ (Int.natAbs a) b 
        have  := Nat.eq_mul_of_div_eq_right dv hb 
        rw [←Nat.mul_div_assocₓ _ dv] at this 
        exact Nat.eq_mul_of_div_eq_left (dv.mul_left _) this.symm 
      have m0 : (a.nat_abs.gcd b*c.nat_abs.gcd d : ℤ) ≠ 0
      ·
        refine' Int.coe_nat_ne_zero.2 (ne_of_gtₓ _)
        apply mul_pos <;> apply Nat.gcd_pos_of_pos_rightₓ <;> assumption 
      apply mul_right_cancel₀ m0 
      simpa [mul_commₓ, mul_left_commₓ] using congr (congr_argₓ (·*·) ha.symm) (congr_argₓ coeₓ hb)
    ·
      suffices  : ∀ a c, ((a*d) = c*b) → a / a.gcd b = c / c.gcd d ∧ b / a.gcd b = d / c.gcd d
      ·
        cases'
          this a.nat_abs c.nat_abs
            (by 
              simpa [Int.nat_abs_mul] using congr_argₓ Int.natAbs h) with
          h₁ h₂ 
        have hs := congr_argₓ Int.sign h 
        simp [Int.sign_eq_one_of_pos (Int.coe_nat_lt.2 hb), Int.sign_eq_one_of_pos (Int.coe_nat_lt.2 hd)] at hs 
        conv  in a => rw [←Int.sign_mul_nat_abs a]
        conv  in c => rw [←Int.sign_mul_nat_abs c]
        rw [Int.mul_div_assoc, Int.mul_div_assoc]
        exact ⟨congr (congr_argₓ (·*·) hs) (congr_argₓ coeₓ h₁), h₂⟩
        all_goals 
          exact Int.coe_nat_dvd.2 (Nat.gcd_dvd_leftₓ _ _)
      intro a c h 
      suffices bd : b / a.gcd b = d / c.gcd d
      ·
        refine' ⟨_, bd⟩
        apply Nat.eq_of_mul_eq_mul_leftₓ hb 
        rw [←Nat.mul_div_assocₓ _ (Nat.gcd_dvd_leftₓ _ _), mul_commₓ, Nat.mul_div_assocₓ _ (Nat.gcd_dvd_rightₓ _ _), bd,
          ←Nat.mul_div_assocₓ _ (Nat.gcd_dvd_rightₓ _ _), h, mul_commₓ, Nat.mul_div_assocₓ _ (Nat.gcd_dvd_leftₓ _ _)]
      suffices  : ∀ {a c : ℕ} b _ : b > 0 d _ : d > 0, ((a*d) = c*b) → b / a.gcd b ≤ d / c.gcd d
      ·
        exact le_antisymmₓ (this _ hb _ hd h) (this _ hd _ hb h.symm)
      intro a c b hb d hd h 
      have gb0 := Nat.gcd_pos_of_pos_rightₓ a hb 
      have gd0 := Nat.gcd_pos_of_pos_rightₓ c hd 
      apply Nat.le_of_dvdₓ 
      apply (Nat.le_div_iff_mul_leₓ _ _ gd0).2
      simp 
      apply Nat.le_of_dvdₓ hd (Nat.gcd_dvd_rightₓ _ _)
      apply (Nat.coprime_div_gcd_div_gcdₓ gb0).symm.dvd_of_dvd_mul_left 
      refine' ⟨c / c.gcd d, _⟩
      rw [←Nat.mul_div_assocₓ _ (Nat.gcd_dvd_leftₓ _ _), ←Nat.mul_div_assocₓ _ (Nat.gcd_dvd_rightₓ _ _)]
      apply congr_argₓ (· / c.gcd d)
      rw [mul_commₓ, ←Nat.mul_div_assocₓ _ (Nat.gcd_dvd_leftₓ _ _), mul_commₓ, h,
        Nat.mul_div_assocₓ _ (Nat.gcd_dvd_rightₓ _ _), mul_commₓ]

@[simp]
theorem div_mk_div_cancel_left {a b c : ℤ} (c0 : c ≠ 0) : ((a*c) /. b*c) = a /. b :=
  by 
    byCases' b0 : b = 0
    ·
      subst b0 
      simp 
    apply (mk_eq (mul_ne_zero b0 c0) b0).2
    simp [mul_commₓ, mul_assocₓ]

@[simp]
theorem num_denom : ∀ {a : ℚ}, a.num /. a.denom = a
| ⟨n, d, h, (c : _ = 1)⟩ =>
  show mk_nat n d = _ by 
    simp [mk_nat, ne_of_gtₓ h, mk_pnat, c]

theorem num_denom' {n d h c} : (⟨n, d, h, c⟩ : ℚ) = n /. d :=
  num_denom.symm

theorem of_int_eq_mk (z : ℤ) : of_int z = z /. 1 :=
  num_denom'

/-- Define a (dependent) function or prove `∀ r : ℚ, p r` by dealing with rational
numbers of the form `n /. d` with `0 < d` and coprime `n`, `d`. -/
@[elab_as_eliminator]
def num_denom_cases_on.{u} {C : ℚ → Sort u} : ∀ a : ℚ H : ∀ n d, 0 < d → (Int.natAbs n).Coprime d → C (n /. d), C a
| ⟨n, d, h, c⟩, H =>
  by 
    rw [num_denom'] <;> exact H n d h c

/-- Define a (dependent) function or prove `∀ r : ℚ, p r` by dealing with rational
numbers of the form `n /. d` with `d ≠ 0`. -/
@[elab_as_eliminator]
def num_denom_cases_on'.{u} {C : ℚ → Sort u} (a : ℚ) (H : ∀ n : ℤ d : ℕ, d ≠ 0 → C (n /. d)) : C a :=
  num_denom_cases_on a$ fun n d h c => H n d h.ne'

theorem num_dvd a {b : ℤ} (b0 : b ≠ 0) : (a /. b).num ∣ a :=
  by 
    cases' e : a /. b with n d h c 
    rw [Rat.num_denom', Rat.mk_eq b0 (ne_of_gtₓ (Int.coe_nat_pos.2 h))] at e 
    refine' Int.nat_abs_dvd.1$ Int.dvd_nat_abs.1$ Int.coe_nat_dvd.2$ c.dvd_of_dvd_mul_right _ 
    have  := congr_argₓ Int.natAbs e 
    simp [Int.nat_abs_mul, Int.nat_abs_of_nat] at this 
    simp [this]

theorem denom_dvd (a b : ℤ) : ((a /. b).denom : ℤ) ∣ b :=
  by 
    byCases' b0 : b = 0
    ·
      simp [b0]
    cases' e : a /. b with n d h c 
    rw [num_denom', mk_eq b0 (ne_of_gtₓ (Int.coe_nat_pos.2 h))] at e 
    refine' Int.dvd_nat_abs.1$ Int.coe_nat_dvd.2$ c.symm.dvd_of_dvd_mul_left _ 
    rw [←Int.nat_abs_mul, ←Int.coe_nat_dvd, Int.dvd_nat_abs, ←e]
    simp 

/-- Addition of rational numbers. Use `(+)` instead. -/
protected def add : ℚ → ℚ → ℚ
| ⟨n₁, d₁, h₁, c₁⟩, ⟨n₂, d₂, h₂, c₂⟩ => mk_pnat ((n₁*d₂)+n₂*d₁) ⟨d₁*d₂, mul_pos h₁ h₂⟩

instance : Add ℚ :=
  ⟨Rat.add⟩

theorem lift_binop_eq (f : ℚ → ℚ → ℚ) (f₁ : ℤ → ℤ → ℤ → ℤ → ℤ) (f₂ : ℤ → ℤ → ℤ → ℤ → ℤ)
  (fv : ∀ {n₁ d₁ h₁ c₁ n₂ d₂ h₂ c₂}, f ⟨n₁, d₁, h₁, c₁⟩ ⟨n₂, d₂, h₂, c₂⟩ = f₁ n₁ d₁ n₂ d₂ /. f₂ n₁ d₁ n₂ d₂)
  (f0 : ∀ {n₁ d₁ n₂ d₂} d₁0 : d₁ ≠ 0 d₂0 : d₂ ≠ 0, f₂ n₁ d₁ n₂ d₂ ≠ 0) (a b c d : ℤ) (b0 : b ≠ 0) (d0 : d ≠ 0)
  (H : ∀ {n₁ d₁ n₂ d₂} h₁ : (a*d₁) = n₁*b h₂ : (c*d₂) = n₂*d, (f₁ n₁ d₁ n₂ d₂*f₂ a b c d) = f₁ a b c d*f₂ n₁ d₁ n₂ d₂) :
  f (a /. b) (c /. d) = f₁ a b c d /. f₂ a b c d :=
  by 
    generalize ha : a /. b = x 
    cases' x with n₁ d₁ h₁ c₁ 
    rw [num_denom'] at ha 
    generalize hc : c /. d = x 
    cases' x with n₂ d₂ h₂ c₂ 
    rw [num_denom'] at hc 
    rw [fv]
    have d₁0 := ne_of_gtₓ (Int.coe_nat_lt.2 h₁)
    have d₂0 := ne_of_gtₓ (Int.coe_nat_lt.2 h₂)
    exact (mk_eq (f0 d₁0 d₂0) (f0 b0 d0)).2 (H ((mk_eq b0 d₁0).1 ha) ((mk_eq d0 d₂0).1 hc))

@[simp]
theorem add_def {a b c d : ℤ} (b0 : b ≠ 0) (d0 : d ≠ 0) : ((a /. b)+c /. d) = ((a*d)+c*b) /. b*d :=
  by 
    apply lift_binop_eq Rat.add <;>
      intros  <;>
        try 
          assumption
    ·
      apply mk_pnat_eq
    ·
      apply mul_ne_zero d₁0 d₂0 
    calc (((n₁*d₂)+n₂*d₁)*b*d) = (((n₁*b)*d₂)*d)+(n₂*d)*d₁*b :=
      by 
        simp [mul_addₓ, mul_commₓ, mul_left_commₓ]_ = (((a*d₁)*d₂)*d)+(c*d₂)*d₁*b :=
      by 
        rw [h₁, h₂]_ = ((a*d)+c*b)*d₁*d₂ :=
      by 
        simp [mul_addₓ, mul_commₓ, mul_left_commₓ]

/-- Negation of rational numbers. Use `-r` instead. -/
protected def neg (r : ℚ) : ℚ :=
  ⟨-r.num, r.denom, r.pos,
    by 
      simp [r.cop]⟩

instance : Neg ℚ :=
  ⟨Rat.neg⟩

@[simp]
theorem neg_def {a b : ℤ} : -(a /. b) = -a /. b :=
  by 
    byCases' b0 : b = 0
    ·
      subst b0 
      simp 
      rfl 
    generalize ha : a /. b = x 
    cases' x with n₁ d₁ h₁ c₁ 
    rw [num_denom'] at ha 
    show Rat.mk' _ _ _ _ = _ 
    rw [num_denom']
    have d0 := ne_of_gtₓ (Int.coe_nat_lt.2 h₁)
    apply (mk_eq d0 b0).2
    have h₁ := (mk_eq b0 d0).1 ha 
    simp only [neg_mul_eq_neg_mul_symm, congr_argₓ Neg.neg h₁]

/-- Multiplication of rational numbers. Use `(*)` instead. -/
protected def mul : ℚ → ℚ → ℚ
| ⟨n₁, d₁, h₁, c₁⟩, ⟨n₂, d₂, h₂, c₂⟩ => mk_pnat (n₁*n₂) ⟨d₁*d₂, mul_pos h₁ h₂⟩

instance : Mul ℚ :=
  ⟨Rat.mul⟩

@[simp]
theorem mul_def {a b c d : ℤ} (b0 : b ≠ 0) (d0 : d ≠ 0) : ((a /. b)*c /. d) = (a*c) /. b*d :=
  by 
    apply lift_binop_eq Rat.mul <;>
      intros  <;>
        try 
          assumption
    ·
      apply mk_pnat_eq
    ·
      apply mul_ne_zero d₁0 d₂0 
    cc

/-- Inverse rational number. Use `r⁻¹` instead. -/
protected def inv : ℚ → ℚ
| ⟨(n+1 : ℕ), d, h, c⟩ => ⟨d, n+1, n.succ_pos, c.symm⟩
| ⟨0, d, h, c⟩ => 0
| ⟨-[1+ n], d, h, c⟩ =>
  ⟨-d, n+1, n.succ_pos,
    Nat.Coprime.symm$
      by 
        simp  <;> exact c⟩

instance : HasInv ℚ :=
  ⟨Rat.inv⟩

@[simp]
theorem inv_def {a b : ℤ} : (a /. b)⁻¹ = b /. a :=
  by 
    byCases' a0 : a = 0
    ·
      subst a0 
      simp 
      rfl 
    byCases' b0 : b = 0
    ·
      subst b0 
      simp 
      rfl 
    generalize ha : a /. b = x 
    cases' x with n d h c 
    rw [num_denom'] at ha 
    refine' Eq.trans (_ : Rat.inv ⟨n, d, h, c⟩ = d /. n) _
    ·
      cases' n with n <;> [cases' n with n, skip]
      ·
        rfl
      ·
        change Int.ofNat n.succ with (n+1 : ℕ)
        unfold Rat.inv 
        rw [num_denom']
      ·
        unfold Rat.inv 
        rw [num_denom']
        rfl 
    have n0 : n ≠ 0
    ·
      refine' mt (fun n0 : n = 0 => _) a0 
      subst n0 
      simp  at ha 
      exact (mk_eq_zero b0).1 ha 
    have d0 := ne_of_gtₓ (Int.coe_nat_lt.2 h)
    have ha := (mk_eq b0 d0).1 ha 
    apply (mk_eq n0 a0).2
    cc

variable (a b c : ℚ)

protected theorem add_zeroₓ : (a+0) = a :=
  num_denom_cases_on' a$
    fun n d h =>
      by 
        rw [←zero_mk d] <;> simp [h, -zero_mk]

protected theorem zero_addₓ : (0+a) = a :=
  num_denom_cases_on' a$
    fun n d h =>
      by 
        rw [←zero_mk d] <;> simp [h, -zero_mk]

protected theorem add_commₓ : (a+b) = b+a :=
  num_denom_cases_on' a$
    fun n₁ d₁ h₁ =>
      num_denom_cases_on' b$
        fun n₂ d₂ h₂ =>
          by 
            simp [h₁, h₂] <;> cc

protected theorem add_assocₓ : ((a+b)+c) = a+b+c :=
  num_denom_cases_on' a$
    fun n₁ d₁ h₁ =>
      num_denom_cases_on' b$
        fun n₂ d₂ h₂ =>
          num_denom_cases_on' c$
            fun n₃ d₃ h₃ =>
              by 
                simp [h₁, h₂, h₃, mul_ne_zero, mul_addₓ, mul_commₓ, mul_left_commₓ, add_left_commₓ, add_assocₓ]

protected theorem add_left_negₓ : ((-a)+a) = 0 :=
  num_denom_cases_on' a$
    fun n d h =>
      by 
        simp [h]

@[simp]
theorem mk_zero_one : 0 /. 1 = 0 :=
  show mk_pnat _ _ = _ by 
    rw [mk_pnat]
    simp 
    rfl

@[simp]
theorem mk_one_one : 1 /. 1 = 1 :=
  show mk_pnat _ _ = _ by 
    rw [mk_pnat]
    simp 
    rfl

@[simp]
theorem mk_neg_one_one : -1 /. 1 = -1 :=
  show mk_pnat _ _ = _ by 
    rw [mk_pnat]
    simp 
    rfl

protected theorem mul_oneₓ : (a*1) = a :=
  num_denom_cases_on' a$
    fun n d h =>
      by 
        rw [←mk_one_one]
        simp [h, -mk_one_one]

protected theorem one_mulₓ : (1*a) = a :=
  num_denom_cases_on' a$
    fun n d h =>
      by 
        rw [←mk_one_one]
        simp [h, -mk_one_one]

protected theorem mul_commₓ : (a*b) = b*a :=
  num_denom_cases_on' a$
    fun n₁ d₁ h₁ =>
      num_denom_cases_on' b$
        fun n₂ d₂ h₂ =>
          by 
            simp [h₁, h₂, mul_commₓ]

protected theorem mul_assocₓ : ((a*b)*c) = a*b*c :=
  num_denom_cases_on' a$
    fun n₁ d₁ h₁ =>
      num_denom_cases_on' b$
        fun n₂ d₂ h₂ =>
          num_denom_cases_on' c$
            fun n₃ d₃ h₃ =>
              by 
                simp [h₁, h₂, h₃, mul_ne_zero, mul_commₓ, mul_left_commₓ]

protected theorem add_mulₓ : ((a+b)*c) = (a*c)+b*c :=
  num_denom_cases_on' a$
    fun n₁ d₁ h₁ =>
      num_denom_cases_on' b$
        fun n₂ d₂ h₂ =>
          num_denom_cases_on' c$
            fun n₃ d₃ h₃ =>
              by 
                simp [h₁, h₂, h₃, mul_ne_zero] <;>
                  refine' (div_mk_div_cancel_left (Int.coe_nat_ne_zero.2 h₃)).symm.trans _ <;>
                    simp [mul_addₓ, mul_commₓ, mul_assocₓ, mul_left_commₓ]

protected theorem mul_addₓ : (a*b+c) = (a*b)+a*c :=
  by 
    rw [Rat.mul_comm, Rat.add_mul, Rat.mul_comm, Rat.mul_comm c a]

protected theorem zero_ne_one : 0 ≠ (1 : ℚ) :=
  suffices (1 : ℚ) = 0 → False by 
    cc 
  by 
    rw [←mk_one_one, mk_eq_zero one_ne_zero]
    exact one_ne_zero

protected theorem mul_inv_cancel : a ≠ 0 → (a*a⁻¹) = 1 :=
  num_denom_cases_on' a$
    fun n d h a0 =>
      have n0 : n ≠ 0 :=
        mt
          (by 
            intro e <;> subst e <;> simp )
          a0 
      by 
        simpa [h, n0, mul_commₓ] using @div_mk_div_cancel_left 1 1 _ n0

protected theorem inv_mul_cancel (h : a ≠ 0) : (a⁻¹*a) = 1 :=
  Eq.trans (Rat.mul_comm _ _) (Rat.mul_inv_cancel _ h)

instance : DecidableEq ℚ :=
  by 
    runTac 
      tactic.mk_dec_eq_instance

instance : Field ℚ :=
  { zero := 0, add := Rat.add, neg := Rat.neg, one := 1, mul := Rat.mul, inv := Rat.inv, zero_add := Rat.zero_add,
    add_zero := Rat.add_zero, add_comm := Rat.add_comm, add_assoc := Rat.add_assoc, add_left_neg := Rat.add_left_neg,
    mul_one := Rat.mul_one, one_mul := Rat.one_mul, mul_comm := Rat.mul_comm, mul_assoc := Rat.mul_assoc,
    left_distrib := Rat.mul_add, right_distrib := Rat.add_mul, exists_pair_ne := ⟨0, 1, Rat.zero_ne_one⟩,
    mul_inv_cancel := Rat.mul_inv_cancel, inv_zero := rfl }

instance : DivisionRing ℚ :=
  by 
    infer_instance

instance : IsDomain ℚ :=
  by 
    infer_instance

instance : Nontrivial ℚ :=
  by 
    infer_instance

instance : CommRingₓ ℚ :=
  by 
    infer_instance

instance : CommSemiringₓ ℚ :=
  by 
    infer_instance

instance : Semiringₓ ℚ :=
  by 
    infer_instance

instance : AddCommGroupₓ ℚ :=
  by 
    infer_instance

instance : AddGroupₓ ℚ :=
  by 
    infer_instance

instance : AddCommMonoidₓ ℚ :=
  by 
    infer_instance

instance : AddMonoidₓ ℚ :=
  by 
    infer_instance

instance : AddLeftCancelSemigroup ℚ :=
  by 
    infer_instance

instance : AddRightCancelSemigroup ℚ :=
  by 
    infer_instance

instance : AddCommSemigroupₓ ℚ :=
  by 
    infer_instance

instance : AddSemigroupₓ ℚ :=
  by 
    infer_instance

instance : CommMonoidₓ ℚ :=
  by 
    infer_instance

instance : Monoidₓ ℚ :=
  by 
    infer_instance

instance : CommSemigroupₓ ℚ :=
  by 
    infer_instance

instance : Semigroupₓ ℚ :=
  by 
    infer_instance

theorem sub_def {a b c d : ℤ} (b0 : b ≠ 0) (d0 : d ≠ 0) : a /. b - c /. d = ((a*d) - c*b) /. b*d :=
  by 
    simp [b0, d0, sub_eq_add_neg]

@[simp]
theorem denom_neg_eq_denom (q : ℚ) : (-q).denom = q.denom :=
  rfl

@[simp]
theorem num_neg_eq_neg_num (q : ℚ) : (-q).num = -q.num :=
  rfl

@[simp]
theorem num_zero : Rat.num 0 = 0 :=
  rfl

@[simp]
theorem denom_zero : Rat.denom 0 = 1 :=
  rfl

theorem zero_of_num_zero {q : ℚ} (hq : q.num = 0) : q = 0 :=
  have  : q = q.num /. q.denom := num_denom.symm 
  by 
    simpa [hq]

theorem zero_iff_num_zero {q : ℚ} : q = 0 ↔ q.num = 0 :=
  ⟨fun _ =>
      by 
        simp ,
    zero_of_num_zero⟩

theorem num_ne_zero_of_ne_zero {q : ℚ} (h : q ≠ 0) : q.num ≠ 0 :=
  fun this : q.num = 0 => h$ zero_of_num_zero this

@[simp]
theorem num_one : (1 : ℚ).num = 1 :=
  rfl

@[simp]
theorem denom_one : (1 : ℚ).denom = 1 :=
  rfl

theorem denom_ne_zero (q : ℚ) : q.denom ≠ 0 :=
  ne_of_gtₓ q.pos

theorem eq_iff_mul_eq_mul {p q : ℚ} : p = q ↔ (p.num*q.denom) = q.num*p.denom :=
  by 
    convLHS => rw [←@num_denom p, ←@num_denom q]
    apply Rat.mk_eq
    ·
      exactModCast p.denom_ne_zero
    ·
      exactModCast q.denom_ne_zero

theorem mk_num_ne_zero_of_ne_zero {q : ℚ} {n d : ℤ} (hq : q ≠ 0) (hqnd : q = n /. d) : n ≠ 0 :=
  fun this : n = 0 =>
    hq$
      by 
        simpa [this] using hqnd

theorem mk_denom_ne_zero_of_ne_zero {q : ℚ} {n d : ℤ} (hq : q ≠ 0) (hqnd : q = n /. d) : d ≠ 0 :=
  fun this : d = 0 =>
    hq$
      by 
        simpa [this] using hqnd

theorem mk_ne_zero_of_ne_zero {n d : ℤ} (h : n ≠ 0) (hd : d ≠ 0) : n /. d ≠ 0 :=
  fun this : n /. d = 0 => h$ (mk_eq_zero hd).1 this

theorem mul_num_denom (q r : ℚ) : (q*r) = (q.num*r.num) /. ↑q.denom*r.denom :=
  have hq' : (↑q.denom : ℤ) ≠ 0 :=
    by 
      have  := denom_ne_zero q <;> simpa 
  have hr' : (↑r.denom : ℤ) ≠ 0 :=
    by 
      have  := denom_ne_zero r <;> simpa 
  suffices ((q.num /. ↑q.denom)*r.num /. ↑r.denom) = (q.num*r.num) /. ↑q.denom*r.denom by 
    simpa using this 
  by 
    simp [mul_def hq' hr', -num_denom]

theorem div_num_denom (q r : ℚ) : q / r = (q.num*r.denom) /. q.denom*r.num :=
  if hr : r.num = 0 then
    have hr' : r = 0 := zero_of_num_zero hr 
    by 
      simp 
  else
    calc q / r = q*r⁻¹ := div_eq_mul_inv q r 
      _ = (q.num /. q.denom)*(r.num /. r.denom)⁻¹ :=
      by 
        simp 
      _ = (q.num /. q.denom)*r.denom /. r.num :=
      by 
        rw [inv_def]
      _ = (q.num*r.denom) /. q.denom*r.num :=
      mul_def
        (by 
          simpa using denom_ne_zero q)
        hr
      

theorem num_denom_mk {q : ℚ} {n d : ℤ} (hn : n ≠ 0) (hd : d ≠ 0) (qdf : q = n /. d) :
  ∃ c : ℤ, (n = c*q.num) ∧ d = c*q.denom :=
  have hq : q ≠ 0 :=
    fun this : q = 0 =>
      hn$
        (Rat.mk_eq_zero hd).1
          (by 
            cc)
  have  : q.num /. q.denom = n /. d :=
    by 
      rwa [num_denom]
  have  : (q.num*d) = n*↑q.denom :=
    (Rat.mk_eq
          (by 
            simp [Rat.denom_ne_zero])
          hd).1
      this 
  by 
    exists n / q.num 
    have hqdn : q.num ∣ n
    ·
      rw [qdf]
      apply Rat.num_dvd 
      assumption 
    constructor
    ·
      rw [Int.div_mul_cancel hqdn]
    ·
      apply Int.eq_mul_div_of_mul_eq_mul_of_dvd_left
      ·
        apply Rat.num_ne_zero_of_ne_zero hq 
      repeat' 
        assumption

theorem mk_pnat_num (n : ℤ) (d : ℕ+) : (mk_pnat n d).num = n / Nat.gcdₓ n.nat_abs d :=
  by 
    cases d <;> rfl

theorem mk_pnat_denom (n : ℤ) (d : ℕ+) : (mk_pnat n d).denom = d / Nat.gcdₓ n.nat_abs d :=
  by 
    cases d <;> rfl

theorem mk_pnat_denom_dvd (n : ℤ) (d : ℕ+) : (mk_pnat n d).denom ∣ d.1 :=
  by 
    rw [mk_pnat_denom]
    apply Nat.div_dvd_of_dvd 
    apply Nat.gcd_dvd_rightₓ

theorem add_denom_dvd (q₁ q₂ : ℚ) : (q₁+q₂).denom ∣ q₁.denom*q₂.denom :=
  by 
    cases q₁ 
    cases q₂ 
    apply mk_pnat_denom_dvd

theorem mul_denom_dvd (q₁ q₂ : ℚ) : (q₁*q₂).denom ∣ q₁.denom*q₂.denom :=
  by 
    cases q₁ 
    cases q₂ 
    apply mk_pnat_denom_dvd

theorem mul_num (q₁ q₂ : ℚ) : (q₁*q₂).num = (q₁.num*q₂.num) / Nat.gcdₓ (q₁.num*q₂.num).natAbs (q₁.denom*q₂.denom) :=
  by 
    cases q₁ <;> cases q₂ <;> rfl

theorem mul_denom (q₁ q₂ : ℚ) :
  (q₁*q₂).denom = (q₁.denom*q₂.denom) / Nat.gcdₓ (q₁.num*q₂.num).natAbs (q₁.denom*q₂.denom) :=
  by 
    cases q₁ <;> cases q₂ <;> rfl

theorem mul_self_num (q : ℚ) : (q*q).num = q.num*q.num :=
  by 
    rw [mul_num, Int.nat_abs_mul, Nat.Coprime.gcd_eq_one, Int.coe_nat_one, Int.div_one] <;>
      exact (q.cop.mul_right q.cop).mul (q.cop.mul_right q.cop)

theorem mul_self_denom (q : ℚ) : (q*q).denom = q.denom*q.denom :=
  by 
    rw [Rat.mul_denom, Int.nat_abs_mul, Nat.Coprime.gcd_eq_one, Nat.div_oneₓ] <;>
      exact (q.cop.mul_right q.cop).mul (q.cop.mul_right q.cop)

theorem add_num_denom (q r : ℚ) : (q+r) = ((q.num*r.denom)+q.denom*r.num : ℤ) /. ((↑q.denom)*↑r.denom : ℤ) :=
  have hqd : (q.denom : ℤ) ≠ 0 := Int.coe_nat_ne_zero_iff_pos.2 q.3
  have hrd : (r.denom : ℤ) ≠ 0 := Int.coe_nat_ne_zero_iff_pos.2 r.3
  by 
    convLHS => rw [←@num_denom q, ←@num_denom r, Rat.add_def hqd hrd] <;> simp [mul_commₓ]

section Casts

protected theorem add_mk (a b c : ℤ) : (a+b) /. c = (a /. c)+b /. c :=
  if h : c = 0 then
    by 
      simp [h]
  else
    by 
      rw [add_def h h, mk_eq h (mul_ne_zero h h)]
      simp [add_mulₓ, mul_assocₓ]

theorem coe_int_eq_mk : ∀ z : ℤ, ↑z = z /. 1
| (n : ℕ) =>
  show (n : ℚ) = n /. 1by 
    induction' n with n IH n <;> simp [Rat.add_mk]
| -[1+ n] =>
  show (-n+1 : ℚ) = -[1+ n] /. 1by 
    induction' n with n IH
    ·
      rw [←of_int_eq_mk]
      simp 
      rfl 
    show -((n+1)+1 : ℚ) = -[1+ n.succ] /. 1
    rw [neg_add, IH, ←mk_neg_one_one]
    simp [-mk_neg_one_one]

theorem mk_eq_div (n d : ℤ) : n /. d = (n : ℚ) / d :=
  by 
    byCases' d0 : d = 0
    ·
      simp [d0, div_zero]
    simp [division_def, coe_int_eq_mk, mul_def one_ne_zero d0]

@[simp]
theorem num_div_denom (r : ℚ) : (r.num / r.denom : ℚ) = r :=
  by 
    rw [←Int.cast_coe_nat, ←mk_eq_div, num_denom]

theorem exists_eq_mul_div_num_and_eq_mul_div_denom {n d : ℤ} (n_ne_zero : n ≠ 0) (d_ne_zero : d ≠ 0) :
  ∃ c : ℤ, (n = c*((n : ℚ) / d).num) ∧ (d : ℤ) = c*((n : ℚ) / d).denom :=
  by 
    have  : (n : ℚ) / d = Rat.mk n d
    ·
      rw [←Rat.mk_eq_div]
    exact Rat.num_denom_mk n_ne_zero d_ne_zero this

theorem coe_int_eq_of_int (z : ℤ) : ↑z = of_int z :=
  (coe_int_eq_mk z).trans (of_int_eq_mk z).symm

@[simp, normCast]
theorem coe_int_num (n : ℤ) : (n : ℚ).num = n :=
  by 
    rw [coe_int_eq_of_int] <;> rfl

@[simp, normCast]
theorem coe_int_denom (n : ℤ) : (n : ℚ).denom = 1 :=
  by 
    rw [coe_int_eq_of_int] <;> rfl

theorem coe_int_num_of_denom_eq_one {q : ℚ} (hq : q.denom = 1) : ↑q.num = q :=
  by 
    convRHS => rw [←@num_denom q, hq]
    rw [coe_int_eq_mk]
    rfl

theorem denom_eq_one_iff (r : ℚ) : r.denom = 1 ↔ ↑r.num = r :=
  ⟨Rat.coe_int_num_of_denom_eq_one, fun h => h ▸ Rat.coe_int_denom r.num⟩

instance : CanLift ℚ ℤ :=
  ⟨coeₓ, fun q => q.denom = 1, fun q hq => ⟨q.num, coe_int_num_of_denom_eq_one hq⟩⟩

theorem coe_nat_eq_mk (n : ℕ) : ↑n = n /. 1 :=
  by 
    rw [←Int.cast_coe_nat, coe_int_eq_mk]

@[simp, normCast]
theorem coe_nat_num (n : ℕ) : (n : ℚ).num = n :=
  by 
    rw [←Int.cast_coe_nat, coe_int_num]

@[simp, normCast]
theorem coe_nat_denom (n : ℕ) : (n : ℚ).denom = 1 :=
  by 
    rw [←Int.cast_coe_nat, coe_int_denom]

theorem coe_int_inj (m n : ℤ) : (m : ℚ) = n ↔ m = n :=
  ⟨fun h =>
      by 
        simpa using congr_argₓ num h,
    congr_argₓ _⟩

end Casts

theorem inv_def' {q : ℚ} : q⁻¹ = (q.denom : ℚ) / q.num :=
  by 
    convLHS => rw [←@num_denom q]
    cases q 
    simp [div_num_denom]

-- ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
@[simp]
theorem mul_denom_eq_num {q : ℚ} : (q*q.denom) = q.num :=
  by 
    suffices  : (mk q.num (↑q.denom)*mk (↑q.denom) 1) = mk q.num 1
    ·
      ·
        conv  =>
          for q [1] => 
            rw [←@num_denom q]
        rwa [coe_int_eq_mk, coe_nat_eq_mk]
    have  : (q.denom : ℤ) ≠ 0 
    exact
      ne_of_gtₓ
        (by 
          exactModCast q.pos)
    rw [Rat.mul_def this one_ne_zero, mul_commₓ (q.denom : ℤ) 1, div_mk_div_cancel_left this]

theorem denom_div_cast_eq_one_iff (m n : ℤ) (hn : n ≠ 0) : ((m : ℚ) / n).denom = 1 ↔ n ∣ m :=
  by 
    replace hn : (n : ℚ) ≠ 0
    ·
      rwa [Ne.def, ←Int.cast_zero, coe_int_inj]
    constructor
    ·
      intro h 
      lift (m : ℚ) / n to ℤ using h with k hk 
      use k 
      rwa [eq_div_iff_mul_eq hn, ←Int.cast_mul, mul_commₓ, eq_comm, coe_int_inj] at hk
    ·
      rintro ⟨d, rfl⟩
      rw [Int.cast_mul, mul_commₓ, mul_div_cancel _ hn, Rat.coe_int_denom]

theorem num_div_eq_of_coprime {a b : ℤ} (hb0 : 0 < b) (h : Nat.Coprime a.nat_abs b.nat_abs) : (a / b : ℚ).num = a :=
  by 
    lift b to ℕ using le_of_ltₓ hb0 
    normCast  at hb0 h 
    rw [←Rat.mk_eq_div, ←Rat.mk_pnat_eq a b hb0, Rat.mk_pnat_num, Pnat.mk_coe, h.gcd_eq_one, Int.coe_nat_one,
      Int.div_one]

theorem denom_div_eq_of_coprime {a b : ℤ} (hb0 : 0 < b) (h : Nat.Coprime a.nat_abs b.nat_abs) :
  ((a / b : ℚ).denom : ℤ) = b :=
  by 
    lift b to ℕ using le_of_ltₓ hb0 
    normCast  at hb0 h 
    rw [←Rat.mk_eq_div, ←Rat.mk_pnat_eq a b hb0, Rat.mk_pnat_denom, Pnat.mk_coe, h.gcd_eq_one, Nat.div_oneₓ]

theorem div_int_inj {a b c d : ℤ} (hb0 : 0 < b) (hd0 : 0 < d) (h1 : Nat.Coprime a.nat_abs b.nat_abs)
  (h2 : Nat.Coprime c.nat_abs d.nat_abs) (h : (a : ℚ) / b = (c : ℚ) / d) : a = c ∧ b = d :=
  by 
    apply And.intro
    ·
      rw [←num_div_eq_of_coprime hb0 h1, h, num_div_eq_of_coprime hd0 h2]
    ·
      rw [←denom_div_eq_of_coprime hb0 h1, h, denom_div_eq_of_coprime hd0 h2]

@[normCast]
theorem coe_int_div_self (n : ℤ) : ((n / n : ℤ) : ℚ) = n / n :=
  by 
    byCases' hn : n = 0
    ·
      subst hn 
      simp only [Int.cast_zero, EuclideanDomain.zero_div]
    ·
      have  : (n : ℚ) ≠ 0
      ·
        rwa [←coe_int_inj] at hn 
      simp only [Int.div_self hn, Int.cast_one, Ne.def, not_false_iff, div_self this]

@[normCast]
theorem coe_nat_div_self (n : ℕ) : ((n / n : ℕ) : ℚ) = n / n :=
  coe_int_div_self n

theorem coe_int_div (a b : ℤ) (h : b ∣ a) : ((a / b : ℤ) : ℚ) = a / b :=
  by 
    rcases h with ⟨c, rfl⟩
    simp only [mul_commₓ b, Int.mul_div_assoc c (dvd_refl b), Int.cast_mul, mul_div_assoc, coe_int_div_self]

theorem coe_nat_div (a b : ℕ) (h : b ∣ a) : ((a / b : ℕ) : ℚ) = a / b :=
  by 
    rcases h with ⟨c, rfl⟩
    simp only [mul_commₓ b, Nat.mul_div_assocₓ c (dvd_refl b), Nat.cast_mul, mul_div_assoc, coe_nat_div_self]

theorem inv_coe_int_num {a : ℤ} (ha0 : 0 < a) : (a : ℚ)⁻¹.num = 1 :=
  by 
    rw [Rat.inv_def', Rat.coe_int_num, Rat.coe_int_denom, Nat.cast_one, ←Int.cast_one]
    apply num_div_eq_of_coprime ha0 
    rw [Int.nat_abs_one]
    exact Nat.coprime_one_leftₓ _

theorem inv_coe_nat_num {a : ℕ} (ha0 : 0 < a) : (a : ℚ)⁻¹.num = 1 :=
  inv_coe_int_num
    (by 
      exactModCast ha0 :
    0 < (a : ℤ))

theorem inv_coe_int_denom {a : ℤ} (ha0 : 0 < a) : ((a : ℚ)⁻¹.denom : ℤ) = a :=
  by 
    rw [Rat.inv_def', Rat.coe_int_num, Rat.coe_int_denom, Nat.cast_one, ←Int.cast_one]
    apply denom_div_eq_of_coprime ha0 
    rw [Int.nat_abs_one]
    exact Nat.coprime_one_leftₓ _

theorem inv_coe_nat_denom {a : ℕ} (ha0 : 0 < a) : (a : ℚ)⁻¹.denom = a :=
  by 
    exactModCast
      inv_coe_int_denom
        (by 
          exactModCast ha0 :
        0 < (a : ℤ))

protected theorem forall {p : ℚ → Prop} : (∀ r, p r) ↔ ∀ a b : ℤ, p (a / b) :=
  ⟨fun h _ _ => h _,
    fun h q =>
      (show q = q.num / q.denom from
            by 
              simp [Rat.div_num_denom]).symm ▸
        h q.1 q.2⟩

protected theorem exists {p : ℚ → Prop} : (∃ r, p r) ↔ ∃ a b : ℤ, p (a / b) :=
  ⟨fun ⟨r, hr⟩ =>
      ⟨r.num, r.denom,
        by 
          rwa [←mk_eq_div, num_denom]⟩,
    fun ⟨a, b, h⟩ => ⟨_, h⟩⟩

end Rat

