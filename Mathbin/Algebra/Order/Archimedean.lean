import Mathbin.Algebra.FieldPower 
import Mathbin.Data.Int.LeastGreatest 
import Mathbin.Data.Rat.Floor

/-!
# Archimedean groups and fields.

This file defines the archimedean property for ordered groups and proves several results connected
to this notion. Being archimedean means that for all elements `x` and `y>0` there exists a natural
number `n` such that `x ≤ n • y`.

## Main definitions

* `archimedean` is a typeclass for an ordered additive commutative monoid to have the archimedean
  property.
* `archimedean.floor_ring` defines a floor function on an archimedean linearly ordered ring making
  it into a `floor_ring`.
* `round` defines a function rounding to the nearest integer for a linearly ordered field which is
  also a floor ring.

## Main statements

* `ℕ`, `ℤ`, and `ℚ` are archimedean.
-/


open Int Set

variable{α : Type _}

/-- An ordered additive commutative monoid is called `archimedean` if for any two elements `x`, `y`
such that `0 < y` there exists a natural number `n` such that `x ≤ n • y`. -/
class Archimedean(α)[OrderedAddCommMonoid α] : Prop where 
  arch : ∀ x : α {y}, 0 < y → ∃ n : ℕ, x ≤ n • y

instance OrderDual.archimedean [OrderedAddCommGroup α] [Archimedean α] : Archimedean (OrderDual α) :=
  ⟨fun x y hy =>
      let ⟨n, hn⟩ := Archimedean.arch (-x : α) (neg_pos.2 hy)
      ⟨n,
        by 
          rwa [neg_nsmul, neg_le_neg_iff] at hn⟩⟩

section LinearOrderedAddCommGroup

variable[LinearOrderedAddCommGroup α][Archimedean α]

-- error in Algebra.Order.Archimedean: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- An archimedean decidable linearly ordered `add_comm_group` has a version of the floor: for
`a > 0`, any `g` in the group lies between some two consecutive multiples of `a`. -/
theorem exists_unique_zsmul_near_of_pos
{a : α}
(ha : «expr < »(0, a))
(g : α) : «expr∃! , »((k : exprℤ()), «expr ∧ »(«expr ≤ »(«expr • »(k, a), g), «expr < »(g, «expr • »(«expr + »(k, 1), a)))) :=
begin
  let [ident s] [":", expr set exprℤ()] [":=", expr {n : exprℤ() | «expr ≤ »(«expr • »(n, a), g)}],
  obtain ["⟨", ident k, ",", ident hk, ":", expr «expr ≤ »(«expr- »(g), «expr • »(k, a)), "⟩", ":=", expr archimedean.arch «expr- »(g) ha],
  have [ident h_ne] [":", expr s.nonempty] [":=", expr ⟨«expr- »(k), by simpa [] [] [] [] [] ["using", expr neg_le_neg hk]⟩],
  obtain ["⟨", ident k, ",", ident hk, "⟩", ":=", expr archimedean.arch g ha],
  have [ident h_bdd] [":", expr ∀ n «expr ∈ » s, «expr ≤ »(n, (k : exprℤ()))] [],
  { assume [binders (n hn)],
    apply [expr (zsmul_le_zsmul_iff ha).mp],
    rw ["<-", expr coe_nat_zsmul] ["at", ident hk],
    exact [expr le_trans hn hk] },
  obtain ["⟨", ident m, ",", ident hm, ",", ident hm', "⟩", ":=", expr int.exists_greatest_of_bdd ⟨k, h_bdd⟩ h_ne],
  have [ident hm''] [":", expr «expr < »(g, «expr • »(«expr + »(m, 1), a))] [],
  { contrapose ["!"] [ident hm'],
    exact [expr ⟨«expr + »(m, 1), hm', lt_add_one _⟩] },
  refine [expr ⟨m, ⟨hm, hm''⟩, λ n hn, «expr $ »((hm' n hn.1).antisymm, int.le_of_lt_add_one _)⟩],
  rw ["<-", expr zsmul_lt_zsmul_iff ha] [],
  exact [expr lt_of_le_of_lt hm hn.2]
end

theorem exists_unique_zsmul_near_of_pos' {a : α} (ha : 0 < a) (g : α) : ∃!k : ℤ, 0 ≤ g - k • a ∧ g - k • a < a :=
  by 
    simpa only [sub_nonneg, add_zsmul, one_zsmul, sub_lt_iff_lt_add'] using exists_unique_zsmul_near_of_pos ha g

theorem exists_unique_add_zsmul_mem_Ico {a : α} (ha : 0 < a) (b c : α) : ∃!m : ℤ, (b+m • a) ∈ Set.Ico c (c+a) :=
  (Equiv.neg ℤ).Bijective.exists_unique_iff.2$
    by 
      simpa only [Equiv.neg_apply, mem_Ico, neg_zsmul, ←sub_eq_add_neg, le_sub_iff_add_le, zero_addₓ, add_commₓ c,
        sub_lt_iff_lt_add', add_assocₓ] using exists_unique_zsmul_near_of_pos' ha (b - c)

theorem exists_unique_add_zsmul_mem_Ioc {a : α} (ha : 0 < a) (b c : α) : ∃!m : ℤ, (b+m • a) ∈ Set.Ioc c (c+a) :=
  (Equiv.addRight (1 : ℤ)).Bijective.exists_unique_iff.2$
    by 
      simpa only [add_zsmul, sub_lt_iff_lt_add', le_sub_iff_add_le', ←add_assocₓ, And.comm, mem_Ioc,
        Equiv.coe_add_right, one_zsmul, add_le_add_iff_right] using exists_unique_zsmul_near_of_pos ha (c - b)

end LinearOrderedAddCommGroup

theorem exists_nat_gt [OrderedSemiring α] [Nontrivial α] [Archimedean α] (x : α) : ∃ n : ℕ, x < n :=
  let ⟨n, h⟩ := Archimedean.arch x zero_lt_one
  ⟨n+1,
    lt_of_le_of_ltₓ
      (by 
        rwa [←nsmul_one])
      (Nat.cast_lt.2 (Nat.lt_succ_selfₓ _))⟩

theorem exists_nat_ge [OrderedSemiring α] [Archimedean α] (x : α) : ∃ n : ℕ, x ≤ n :=
  by 
    nontriviality α 
    exact (exists_nat_gt x).imp fun n => le_of_ltₓ

theorem add_one_pow_unbounded_of_pos [OrderedSemiring α] [Nontrivial α] [Archimedean α] (x : α) {y : α} (hy : 0 < y) :
  ∃ n : ℕ, x < (y+1) ^ n :=
  have  : 0 ≤ 1+y := add_nonneg zero_le_one hy.le 
  let ⟨n, h⟩ := Archimedean.arch x hy
  ⟨n,
    calc x ≤ n • y := h 
      _ = n*y := nsmul_eq_mul _ _ 
      _ < 1+n*y := lt_one_add _ 
      _ ≤ (1+y) ^ n :=
      one_add_mul_le_pow' (mul_nonneg hy.le hy.le) (mul_nonneg this this) (add_nonneg zero_le_two hy.le) _ 
      _ = (y+1) ^ n :=
      by 
        rw [add_commₓ]
      ⟩

section LinearOrderedRing

variable[LinearOrderedRing α][Archimedean α]

theorem pow_unbounded_of_one_lt (x : α) {y : α} (hy1 : 1 < y) : ∃ n : ℕ, x < y ^ n :=
  sub_add_cancel y 1 ▸ add_one_pow_unbounded_of_pos _ (sub_pos.2 hy1)

/-- Every x greater than or equal to 1 is between two successive
natural-number powers of every y greater than one. -/
theorem exists_nat_pow_near {x : α} {y : α} (hx : 1 ≤ x) (hy : 1 < y) : ∃ n : ℕ, y ^ n ≤ x ∧ x < y ^ n+1 :=
  have h : ∃ n : ℕ, x < y ^ n := pow_unbounded_of_one_lt _ hy 
  by 
    classical <;>
      exact
        let n := Nat.findₓ h 
        have hn : x < y ^ n := Nat.find_specₓ h 
        have hnp : 0 < n :=
          pos_iff_ne_zero.2
            fun hn0 =>
              by 
                rw [hn0, pow_zeroₓ] at hn <;> exact not_le_of_gtₓ hn hx 
        have hnsp : (Nat.pred n+1) = n := Nat.succ_pred_eq_of_posₓ hnp 
        have hltn : Nat.pred n < n := Nat.pred_ltₓ (ne_of_gtₓ hnp)
        ⟨Nat.pred n, le_of_not_ltₓ (Nat.find_minₓ h hltn),
          by 
            rwa [hnsp]⟩

theorem exists_int_gt (x : α) : ∃ n : ℤ, x < n :=
  let ⟨n, h⟩ := exists_nat_gt x
  ⟨n,
    by 
      rwa [←coe_coe]⟩

theorem exists_int_lt (x : α) : ∃ n : ℤ, (n : α) < x :=
  let ⟨n, h⟩ := exists_int_gt (-x)
  ⟨-n,
    by 
      rw [Int.cast_neg] <;> exact neg_lt.1 h⟩

-- error in Algebra.Order.Archimedean: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem exists_floor
(x : α) : «expr∃ , »((fl : exprℤ()), ∀ z : exprℤ(), «expr ↔ »(«expr ≤ »(z, fl), «expr ≤ »((z : α), x))) :=
begin
  haveI [] [] [":=", expr classical.prop_decidable],
  have [] [":", expr «expr∃ , »((ub : exprℤ()), «expr ∧ »(«expr ≤ »((ub : α), x), ∀
     z : exprℤ(), «expr ≤ »((z : α), x) → «expr ≤ »(z, ub)))] [":=", expr int.exists_greatest_of_bdd (let ⟨n, hn⟩ := exists_int_gt x in
    ⟨n, λ
     z
     h', «expr $ »(int.cast_le.1, «expr $ »(le_trans h', le_of_lt hn))⟩) (let ⟨n, hn⟩ := exists_int_lt x in
    ⟨n, le_of_lt hn⟩)],
  refine [expr this.imp (λ fl h z, _)],
  cases [expr h] ["with", ident h₁, ident h₂],
  exact [expr ⟨λ h, le_trans (int.cast_le.2 h) h₁, h₂ z⟩]
end

end LinearOrderedRing

section LinearOrderedField

variable[LinearOrderedField α]

/-- Every positive `x` is between two successive integer powers of
another `y` greater than one. This is the same as `exists_mem_Ioc_zpow`,
but with ≤ and < the other way around. -/
theorem exists_mem_Ico_zpow [Archimedean α] {x : α} {y : α} (hx : 0 < x) (hy : 1 < y) :
  ∃ n : ℤ, x ∈ Set.Ico (y ^ n) (y ^ n+1) :=
  by 
    classical <;>
      exact
        let ⟨N, hN⟩ := pow_unbounded_of_one_lt (x⁻¹) hy 
        have he : ∃ m : ℤ, y ^ m ≤ x :=
          ⟨-N,
            le_of_ltₓ
              (by 
                rw [zpow_neg₀ y («expr↑ » N), zpow_coe_nat]
                exact (inv_lt hx (lt_transₓ (inv_pos.2 hx) hN)).1 hN)⟩
        let ⟨M, hM⟩ := pow_unbounded_of_one_lt x hy 
        have hb : ∃ b : ℤ, ∀ m, y ^ m ≤ x → m ≤ b :=
          ⟨M,
            fun m hm =>
              le_of_not_ltₓ
                fun hlt =>
                  not_lt_of_geₓ (zpow_le_of_le hy.le hlt.le)
                    (lt_of_le_of_ltₓ hm
                      (by 
                        rwa [←zpow_coe_nat] at hM))⟩
        let ⟨n, hn₁, hn₂⟩ := Int.exists_greatest_of_bdd hb he
        ⟨n, hn₁, lt_of_not_geₓ fun hge => not_le_of_gtₓ (Int.lt_succ _) (hn₂ _ hge)⟩

/-- Every positive `x` is between two successive integer powers of
another `y` greater than one. This is the same as `exists_mem_Ico_zpow`,
but with ≤ and < the other way around. -/
theorem exists_mem_Ioc_zpow [Archimedean α] {x : α} {y : α} (hx : 0 < x) (hy : 1 < y) :
  ∃ n : ℤ, x ∈ Set.Ioc (y ^ n) (y ^ n+1) :=
  let ⟨m, hle, hlt⟩ := exists_mem_Ico_zpow (inv_pos.2 hx) hy 
  have hyp : 0 < y := lt_transₓ zero_lt_one hy
  ⟨-m+1,
    by 
      rwa [zpow_neg₀, inv_lt (zpow_pos_of_pos hyp _) hx],
    by 
      rwa [neg_add, neg_add_cancel_right, zpow_neg₀, le_inv hx (zpow_pos_of_pos hyp _)]⟩

/-- For any `y < 1` and any positive `x`, there exists `n : ℕ` with `y ^ n < x`. -/
theorem exists_pow_lt_of_lt_one [Archimedean α] {x y : α} (hx : 0 < x) (hy : y < 1) : ∃ n : ℕ, y ^ n < x :=
  by 
    byCases' y_pos : y ≤ 0
    ·
      use 1
      simp only [pow_oneₓ]
      linarith 
    rw [not_leₓ] at y_pos 
    rcases pow_unbounded_of_one_lt (x⁻¹) (one_lt_inv y_pos hy) with ⟨q, hq⟩
    exact
      ⟨q,
        by 
          rwa [inv_pow₀, inv_lt_inv hx (pow_pos y_pos _)] at hq⟩

/-- Given `x` and `y` between `0` and `1`, `x` is between two successive powers of `y`.
This is the same as `exists_nat_pow_near`, but for elements between `0` and `1` -/
theorem exists_nat_pow_near_of_lt_one [Archimedean α] {x : α} {y : α} (xpos : 0 < x) (hx : x ≤ 1) (ypos : 0 < y)
  (hy : y < 1) : ∃ n : ℕ, (y ^ n+1) < x ∧ x ≤ y ^ n :=
  by 
    rcases exists_nat_pow_near (one_le_inv_iff.2 ⟨xpos, hx⟩) (one_lt_inv_iff.2 ⟨ypos, hy⟩) with ⟨n, hn, h'n⟩
    refine' ⟨n, _, _⟩
    ·
      rwa [inv_pow₀, inv_lt_inv xpos (pow_pos ypos _)] at h'n
    ·
      rwa [inv_pow₀, inv_le_inv (pow_pos ypos _) xpos] at hn

variable[FloorRing α]

theorem sub_floor_div_mul_nonneg (x : α) {y : α} (hy : 0 < y) : 0 ≤ x - ⌊x / y⌋*y :=
  by 
    conv  in x => rw [←div_mul_cancel x (ne_of_ltₓ hy).symm]
    rw [←sub_mul]
    exact mul_nonneg (sub_nonneg.2 (floor_le _)) (le_of_ltₓ hy)

theorem sub_floor_div_mul_lt (x : α) {y : α} (hy : 0 < y) : (x - ⌊x / y⌋*y) < y :=
  sub_lt_iff_lt_add.2
    (by 
      conv  in y => rw [←one_mulₓ y]
      conv  in x => rw [←div_mul_cancel x (ne_of_ltₓ hy).symm]
      rw [←add_mulₓ]
      exact
        (mul_lt_mul_right hy).2
          (by 
            rw [add_commₓ] <;> exact lt_floor_add_one _))

end LinearOrderedField

instance  : Archimedean ℕ :=
  ⟨fun n m m0 =>
      ⟨n,
        by 
          simpa only [mul_oneₓ, Nat.nsmul_eq_mul] using Nat.mul_le_mul_leftₓ n m0⟩⟩

instance  : Archimedean ℤ :=
  ⟨fun n m m0 =>
      ⟨n.to_nat,
        le_transₓ (Int.le_to_nat _)$
          by 
            simpa only [nsmul_eq_mul, Int.nat_cast_eq_coe_nat, zero_addₓ, mul_oneₓ] using
              mul_le_mul_of_nonneg_left (Int.add_one_le_iff.2 m0) (Int.coe_zero_le n.to_nat)⟩⟩

/-- A linear ordered archimedean ring is a floor ring. This is not an `instance` because in some
cases we have a computable `floor` function. -/
noncomputable def Archimedean.floorRing α [LinearOrderedRing α] [Archimedean α] : FloorRing α :=
  FloorRing.ofFloor α (fun a => Classical.some (exists_floor a))
    fun z a => (Classical.some_spec (exists_floor a) z).symm

section LinearOrderedField

variable[LinearOrderedField α]

theorem archimedean_iff_nat_lt : Archimedean α ↔ ∀ x : α, ∃ n : ℕ, x < n :=
  ⟨@exists_nat_gt α _ _,
    fun H =>
      ⟨fun x y y0 =>
          (H (x / y)).imp$
            fun n h =>
              le_of_ltₓ$
                by 
                  rwa [div_lt_iff y0, ←nsmul_eq_mul] at h⟩⟩

theorem archimedean_iff_nat_le : Archimedean α ↔ ∀ x : α, ∃ n : ℕ, x ≤ n :=
  archimedean_iff_nat_lt.trans
    ⟨fun H x => (H x).imp$ fun _ => le_of_ltₓ,
      fun H x =>
        let ⟨n, h⟩ := H x
        ⟨n+1, lt_of_le_of_ltₓ h (Nat.cast_lt.2 (lt_add_one _))⟩⟩

theorem exists_rat_gt [Archimedean α] (x : α) : ∃ q : ℚ, x < q :=
  let ⟨n, h⟩ := exists_nat_gt x
  ⟨n,
    by 
      rwa [Rat.cast_coe_nat]⟩

theorem archimedean_iff_rat_lt : Archimedean α ↔ ∀ x : α, ∃ q : ℚ, x < q :=
  ⟨@exists_rat_gt α _,
    fun H =>
      archimedean_iff_nat_lt.2$
        fun x =>
          let ⟨q, h⟩ := H x
          ⟨⌈q⌉₊,
            lt_of_lt_of_leₓ h$
              by 
                simpa only [Rat.cast_coe_nat] using (@Rat.cast_le α _ _ _).2 (Nat.le_ceil _)⟩⟩

theorem archimedean_iff_rat_le : Archimedean α ↔ ∀ x : α, ∃ q : ℚ, x ≤ q :=
  archimedean_iff_rat_lt.trans
    ⟨fun H x => (H x).imp$ fun _ => le_of_ltₓ,
      fun H x =>
        let ⟨n, h⟩ := H x
        ⟨n+1, lt_of_le_of_ltₓ h (Rat.cast_lt.2 (lt_add_one _))⟩⟩

variable[Archimedean α]

theorem exists_rat_lt (x : α) : ∃ q : ℚ, (q : α) < x :=
  let ⟨n, h⟩ := exists_int_lt x
  ⟨n,
    by 
      rwa [Rat.cast_coe_int]⟩

-- error in Algebra.Order.Archimedean: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem exists_rat_btwn
{x y : α}
(h : «expr < »(x, y)) : «expr∃ , »((q : exprℚ()), «expr ∧ »(«expr < »(x, q), «expr < »((q : α), y))) :=
begin
  cases [expr exists_nat_gt «expr ⁻¹»(«expr - »(y, x))] ["with", ident n, ident nh],
  cases [expr exists_floor «expr * »(x, n)] ["with", ident z, ident zh],
  refine [expr ⟨«expr / »((«expr + »(z, 1) : exprℤ()), n), _⟩],
  have [ident n0'] [] [":=", expr (inv_pos.2 (sub_pos.2 h)).trans nh],
  have [ident n0] [] [":=", expr nat.cast_pos.1 n0'],
  rw ["[", expr rat.cast_div_of_ne_zero, ",", expr rat.cast_coe_nat, ",", expr rat.cast_coe_int, ",", expr div_lt_iff n0', "]"] [],
  refine [expr ⟨«expr $ »((lt_div_iff n0').2, (lt_iff_lt_of_le_iff_le (zh _)).1 (lt_add_one _)), _⟩],
  rw ["[", expr int.cast_add, ",", expr int.cast_one, "]"] [],
  refine [expr lt_of_le_of_lt (add_le_add_right ((zh _).1 (le_refl _)) _) _],
  rwa ["[", "<-", expr lt_sub_iff_add_lt', ",", "<-", expr sub_mul, ",", "<-", expr div_lt_iff' (sub_pos.2 h), ",", expr one_div, "]"] [],
  { rw ["[", expr rat.coe_int_denom, ",", expr nat.cast_one, "]"] [],
    exact [expr one_ne_zero] },
  { intro [ident H],
    rw ["[", expr rat.coe_nat_num, ",", "<-", expr coe_coe, ",", expr nat.cast_eq_zero, "]"] ["at", ident H],
    subst [expr H],
    cases [expr n0] [] },
  { rw ["[", expr rat.coe_nat_denom, ",", expr nat.cast_one, "]"] [],
    exact [expr one_ne_zero] }
end

theorem exists_nat_one_div_lt {ε : α} (hε : 0 < ε) : ∃ n : ℕ, 1 / (n+1 : α) < ε :=
  by 
    cases' exists_nat_gt (1 / ε) with n hn 
    use n 
    rw [div_lt_iff, ←div_lt_iff' hε]
    ·
      apply hn.trans 
      simp [zero_lt_one]
    ·
      exact n.cast_add_one_pos

theorem exists_pos_rat_lt {x : α} (x0 : 0 < x) : ∃ q : ℚ, 0 < q ∧ (q : α) < x :=
  by 
    simpa only [Rat.cast_pos] using exists_rat_btwn x0

end LinearOrderedField

section 

variable[LinearOrderedField α][FloorRing α]

/-- `round` rounds a number to the nearest integer. `round (1 / 2) = 1` -/
def round (x : α) : ℤ :=
  ⌊x+1 / 2⌋

@[simp]
theorem round_zero : round (0 : α) = 0 :=
  floor_eq_iff.2
    (by 
      normNum)

@[simp]
theorem round_one : round (1 : α) = 1 :=
  floor_eq_iff.2
    (by 
      normNum)

-- error in Algebra.Order.Archimedean: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem abs_sub_round (x : α) : «expr ≤ »(«expr| |»(«expr - »(x, round x)), «expr / »(1, 2)) :=
begin
  rw ["[", expr round, ",", expr abs_sub_le_iff, "]"] [],
  have [] [] [":=", expr floor_le «expr + »(x, «expr / »(1, 2))],
  have [] [] [":=", expr lt_floor_add_one «expr + »(x, «expr / »(1, 2))],
  split; linarith [] [] []
end

@[simp, normCast]
theorem Rat.floor_cast (x : ℚ) : ⌊(x : α)⌋ = ⌊x⌋ :=
  floor_eq_iff.2
    (by 
      exactModCast floor_eq_iff.1 (Eq.refl ⌊x⌋))

@[simp, normCast]
theorem Rat.ceil_cast (x : ℚ) : ⌈(x : α)⌉ = ⌈x⌉ :=
  by 
    rw [←neg_inj, ←floor_neg, ←floor_neg, ←Rat.cast_neg, Rat.floor_cast]

@[simp, normCast]
theorem Rat.round_cast (x : ℚ) : round (x : α) = round x :=
  have  : ((x+1 / 2 : ℚ) : α) = x+1 / 2 :=
    by 
      simp 
  by 
    rw [round, round, ←this, Rat.floor_cast]

@[simp, normCast]
theorem Rat.cast_fract (x : ℚ) : («expr↑ » (fract x) : α) = fract x :=
  by 
    simp only [fract, Rat.cast_sub]
    simp 

end 

section 

variable[LinearOrderedField α][Archimedean α]

theorem exists_rat_near (x : α) {ε : α} (ε0 : 0 < ε) : ∃ q : ℚ, |x - q| < ε :=
  let ⟨q, h₁, h₂⟩ := exists_rat_btwn$ lt_transₓ ((sub_lt_self_iff x).2 ε0) ((lt_add_iff_pos_left x).2 ε0)
  ⟨q, abs_sub_lt_iff.2 ⟨sub_lt.1 h₁, sub_lt_iff_lt_add.2 h₂⟩⟩

instance  : Archimedean ℚ :=
  archimedean_iff_rat_le.2$
    fun q =>
      ⟨q,
        by 
          rw [Rat.cast_id]⟩

end 

