import Mathbin.Data.Int.Basic

/-!
# Square root of natural numbers

This file defines an efficient binary implementation of the square root function that returns the
unique `r` such that `r * r ≤ n < (r + 1) * (r + 1)`. It takes advantage of the binary
representation by replacing the multiplication by 2 appearing in
`(a + b)^2 = a^2 + 2 * a * b + b^2` by a bitmask manipulation.

## Reference

See [Wikipedia, *Methods of computing square roots*]
[https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_(base_2)].
-/


namespace Nat

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem sqrt_aux_dec {b} (h : «expr ≠ »(b, 0)) : «expr < »(shiftr b 2, b) :=
begin
  simp [] [] ["only"] ["[", expr shiftr_eq_div_pow, "]"] [] [],
  apply [expr (nat.div_lt_iff_lt_mul' (exprdec_trivial() : «expr < »(0, 4))).2],
  have [] [] [":=", expr nat.mul_lt_mul_of_pos_left (exprdec_trivial() : «expr < »(1, 4)) (nat.pos_of_ne_zero h)],
  rwa [expr mul_one] ["at", ident this]
end

/-- Auxiliary function for `nat.sqrt`. See e.g.
<https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_(base_2)> -/
def sqrt_aux : ℕ → ℕ → ℕ → ℕ
| b, r, n =>
  if b0 : b = 0 then r else
    let b' := shiftr b 2
    have  : b' < b := sqrt_aux_dec b0 
    match (n - (r+b : ℕ) : ℤ) with 
    | (n' : ℕ) => sqrt_aux b' (div2 r+b) n'
    | _ => sqrt_aux b' (div2 r) n

/-- `sqrt n` is the square root of a natural number `n`. If `n` is not a
  perfect square, it returns the largest `k:ℕ` such that `k*k ≤ n`. -/
@[pp_nodot]
def sqrt (n : ℕ) : ℕ :=
  match size n with 
  | 0 => 0
  | succ s => sqrt_aux (shiftl 1 (bit0 (div2 s))) 0 n

theorem sqrt_aux_0 r n : sqrt_aux 0 r n = r :=
  by 
    rw [sqrt_aux] <;> simp 

attribute [local simp] sqrt_aux_0

theorem sqrt_aux_1 {r n b} (h : b ≠ 0) {n'} (h₂ : ((r+b)+n') = n) :
  sqrt_aux b r n = sqrt_aux (shiftr b 2) (div2 r+b) n' :=
  by 
    rw [sqrt_aux] <;>
      simp only [h, h₂.symm, Int.coe_nat_add, if_false] <;> rw [add_commₓ _ (n' : ℤ), add_sub_cancel, sqrt_aux._match_1]

theorem sqrt_aux_2 {r n b} (h : b ≠ 0) (h₂ : n < r+b) : sqrt_aux b r n = sqrt_aux (shiftr b 2) (div2 r) n :=
  by 
    rw [sqrt_aux] <;> simp only [h, h₂, if_false]
    cases' Int.eq_neg_succ_of_lt_zero (sub_lt_zero.2 (Int.coe_nat_lt_coe_nat_of_lt h₂)) with k e 
    rw [e, sqrt_aux._match_1]

private def is_sqrt (n q : ℕ) : Prop :=
  (q*q) ≤ n ∧ n < (q+1)*q+1

attribute [-simp] mul_eq_mul_left_iff mul_eq_mul_right_iff

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
private
theorem sqrt_aux_is_sqrt_lemma
(m r n : exprℕ())
(h₁ : «expr ≤ »(«expr * »(r, r), n))
(m')
(hm : «expr = »(shiftr «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)) 2, m'))
(H1 : «expr < »(n, «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m)))) → is_sqrt n (sqrt_aux m' «expr * »(r, «expr ^ »(2, m)) «expr - »(n, «expr * »(r, r))))
(H2 : «expr ≤ »(«expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m))), n) → is_sqrt n (sqrt_aux m' «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr ^ »(2, m)) «expr - »(n, «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m)))))) : is_sqrt n (sqrt_aux «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)) «expr * »(«expr * »(2, r), «expr ^ »(2, m)) «expr - »(n, «expr * »(r, r))) :=
begin
  have [ident b0] [] [":=", expr have b0 : _, from ne_of_gt (pow_pos (show «expr < »(0, 2), from exprdec_trivial()) m),
   nat.mul_ne_zero b0 b0],
  have [ident lb] [":", expr «expr ↔ »(«expr < »(«expr - »(n, «expr * »(r, r)), «expr + »(«expr * »(«expr * »(2, r), «expr ^ »(2, m)), «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)))), «expr < »(n, «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m)))))] [],
  { rw ["[", expr tsub_lt_iff_right h₁, "]"] [],
    simp [] [] [] ["[", expr left_distrib, ",", expr right_distrib, ",", expr two_mul, ",", expr mul_comm, ",", expr mul_assoc, ",", expr add_comm, ",", expr add_assoc, ",", expr add_left_comm, "]"] [] [] },
  have [ident re] [":", expr «expr = »(div2 «expr * »(«expr * »(2, r), «expr ^ »(2, m)), «expr * »(r, «expr ^ »(2, m)))] [],
  { rw ["[", expr div2_val, ",", expr mul_assoc, ",", expr nat.mul_div_cancel_left _ (exprdec_trivial() : «expr > »(2, 0)), "]"] [] },
  cases [expr lt_or_ge n «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m)))] ["with", ident hl, ident hl],
  { rw ["[", expr sqrt_aux_2 b0 (lb.2 hl), ",", expr hm, ",", expr re, "]"] [],
    apply [expr H1 hl] },
  { cases [expr le.dest hl] ["with", ident n', ident e],
    rw ["[", expr @sqrt_aux_1 «expr * »(«expr * »(2, r), «expr ^ »(2, m)) «expr - »(n, «expr * »(r, r)) «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)) b0 «expr - »(n, «expr * »(«expr + »(r, «expr ^ »(2, m)), «expr + »(r, «expr ^ »(2, m)))), ",", expr hm, ",", expr re, ",", "<-", expr right_distrib, "]"] [],
    { apply [expr H2 hl] },
    apply [expr eq.symm],
    apply [expr tsub_eq_of_eq_add_rev],
    rw ["[", "<-", expr add_assoc, ",", expr (_ : «expr = »(«expr + »(«expr * »(r, r), _), _)), "]"] [],
    exact [expr (add_tsub_cancel_of_le hl).symm],
    simp [] [] [] ["[", expr left_distrib, ",", expr right_distrib, ",", expr two_mul, ",", expr mul_comm, ",", expr mul_assoc, ",", expr add_assoc, "]"] [] [] }
end

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
private
theorem sqrt_aux_is_sqrt
(n) : ∀
m
r, «expr ≤ »(«expr * »(r, r), n) → «expr < »(n, «expr * »(«expr + »(r, «expr ^ »(2, «expr + »(m, 1))), «expr + »(r, «expr ^ »(2, «expr + »(m, 1))))) → is_sqrt n (sqrt_aux «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)) «expr * »(«expr * »(2, r), «expr ^ »(2, m)) «expr - »(n, «expr * »(r, r)))
| 0, r, h₁, h₂ := by apply [expr sqrt_aux_is_sqrt_lemma 0 r n h₁ 0 rfl]; intro [ident h]; simp [] [] [] [] [] []; [exact [expr ⟨h₁, h⟩], exact [expr ⟨h, h₂⟩]]
| «expr + »(m, 1), r, h₁, h₂ := begin
  apply [expr sqrt_aux_is_sqrt_lemma «expr + »(m, 1) r n h₁ «expr * »(«expr ^ »(2, m), «expr ^ »(2, m)) (by simp [] [] [] ["[", expr shiftr, ",", expr pow_succ, ",", expr div2_val, ",", expr mul_comm, ",", expr mul_left_comm, "]"] [] []; repeat { rw [expr @nat.mul_div_cancel_left _ 2 exprdec_trivial()] [] })]; intro [ident h],
  { have [] [] [":=", expr sqrt_aux_is_sqrt m r h₁ h],
    simpa [] [] [] ["[", expr pow_succ, ",", expr mul_comm, ",", expr mul_assoc, "]"] [] [] },
  { rw ["[", expr pow_succ', ",", expr mul_two, ",", "<-", expr add_assoc, "]"] ["at", ident h₂],
    have [] [] [":=", expr sqrt_aux_is_sqrt m «expr + »(r, «expr ^ »(2, «expr + »(m, 1))) h h₂],
    rwa [expr show «expr = »(«expr * »(«expr + »(r, «expr ^ »(2, «expr + »(m, 1))), «expr ^ »(2, «expr + »(m, 1))), «expr * »(«expr * »(2, «expr + »(r, «expr ^ »(2, «expr + »(m, 1)))), «expr ^ »(2, m))), by simp [] [] [] ["[", expr pow_succ, ",", expr mul_comm, ",", expr mul_left_comm, "]"] [] []] [] }
end

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
private theorem sqrt_is_sqrt (n : exprℕ()) : is_sqrt n (sqrt n) :=
begin
  generalize [ident e] [":"] [expr «expr = »(size n, s)],
  cases [expr s] ["with", ident s]; simp [] [] [] ["[", expr e, ",", expr sqrt, "]"] [] [],
  { rw ["[", expr size_eq_zero.1 e, ",", expr is_sqrt, "]"] [],
    exact [expr exprdec_trivial()] },
  { have [] [] [":=", expr sqrt_aux_is_sqrt n (div2 s) 0 (zero_le _)],
    simp [] [] [] ["[", expr show «expr = »(«expr * »(«expr ^ »(2, div2 s), «expr ^ »(2, div2 s)), shiftl 1 (bit0 (div2 s))), by { generalize [] [":"] [expr «expr = »(div2 s, x)],
       change [expr bit0 x] ["with", expr «expr + »(x, x)] [],
       rw ["[", expr one_shiftl, ",", expr pow_add, "]"] [] }, "]"] [] ["at", ident this],
    apply [expr this],
    rw ["[", "<-", expr pow_add, ",", "<-", expr mul_two, "]"] [],
    apply [expr size_le.1],
    rw [expr e] [],
    apply [expr (@div_lt_iff_lt_mul _ _ 2 exprdec_trivial()).1],
    rw ["[", expr div2_val, "]"] [],
    apply [expr lt_succ_self] }
end

theorem sqrt_le (n : ℕ) : (sqrt n*sqrt n) ≤ n :=
  (sqrt_is_sqrt n).left

theorem sqrt_le' (n : ℕ) : sqrt n ^ 2 ≤ n :=
  Eq.trans_le (sq (sqrt n)) (sqrt_le n)

theorem lt_succ_sqrt (n : ℕ) : n < succ (sqrt n)*succ (sqrt n) :=
  (sqrt_is_sqrt n).right

theorem lt_succ_sqrt' (n : ℕ) : n < succ (sqrt n) ^ 2 :=
  trans_rel_left (fun i j => i < j) (lt_succ_sqrt n) (sq (succ (sqrt n))).symm

theorem sqrt_le_add (n : ℕ) : n ≤ ((sqrt n*sqrt n)+sqrt n)+sqrt n :=
  by 
    rw [←succ_mul] <;> exact le_of_lt_succ (lt_succ_sqrt n)

theorem le_sqrt {m n : ℕ} : m ≤ sqrt n ↔ (m*m) ≤ n :=
  ⟨fun h => le_transₓ (mul_self_le_mul_self h) (sqrt_le n),
    fun h => le_of_lt_succ$ mul_self_lt_mul_self_iff.2$ lt_of_le_of_ltₓ h (lt_succ_sqrt n)⟩

theorem le_sqrt' {m n : ℕ} : m ≤ sqrt n ↔ m ^ 2 ≤ n :=
  by 
    simpa only [pow_two] using le_sqrt

theorem sqrt_lt {m n : ℕ} : sqrt m < n ↔ m < n*n :=
  lt_iff_lt_of_le_iff_le le_sqrt

theorem sqrt_lt' {m n : ℕ} : sqrt m < n ↔ m < n ^ 2 :=
  lt_iff_lt_of_le_iff_le le_sqrt'

theorem sqrt_le_self (n : ℕ) : sqrt n ≤ n :=
  le_transₓ (le_mul_self _) (sqrt_le n)

theorem sqrt_le_sqrt {m n : ℕ} (h : m ≤ n) : sqrt m ≤ sqrt n :=
  le_sqrt.2 (le_transₓ (sqrt_le _) h)

@[simp]
theorem sqrt_zero : sqrt 0 = 0 :=
  by 
    rw [sqrt, size_zero, sqrt._match_1]

theorem sqrt_eq_zero {n : ℕ} : sqrt n = 0 ↔ n = 0 :=
  ⟨fun h =>
      Nat.eq_zero_of_le_zeroₓ$
        le_of_lt_succ$
          (@sqrt_lt n 1).1$
            by 
              rw [h] <;>
                exact
                  by 
                    decide,
    by 
      rintro rfl 
      simp ⟩

theorem eq_sqrt {n q} : q = sqrt n ↔ (q*q) ≤ n ∧ n < (q+1)*q+1 :=
  ⟨fun e => e.symm ▸ sqrt_is_sqrt n, fun ⟨h₁, h₂⟩ => le_antisymmₓ (le_sqrt.2 h₁) (le_of_lt_succ$ sqrt_lt.2 h₂)⟩

theorem eq_sqrt' {n q} : q = sqrt n ↔ q ^ 2 ≤ n ∧ n < (q+1) ^ 2 :=
  by 
    simpa only [pow_two] using eq_sqrt

theorem le_three_of_sqrt_eq_one {n : ℕ} (h : sqrt n = 1) : n ≤ 3 :=
  le_of_lt_succ$
    (@sqrt_lt n 2).1$
      by 
        rw [h] <;>
          exact
            by 
              decide

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem sqrt_lt_self {n : exprℕ()} (h : «expr < »(1, n)) : «expr < »(sqrt n, n) :=
«expr $ »(sqrt_lt.2, by have [] [] [":=", expr nat.mul_lt_mul_of_pos_left h (lt_of_succ_lt h)]; rwa ["[", expr mul_one, "]"] ["at", ident this])

theorem sqrt_pos {n : ℕ} : 0 < sqrt n ↔ 0 < n :=
  le_sqrt

theorem sqrt_add_eq (n : ℕ) {a : ℕ} (h : a ≤ n+n) : sqrt ((n*n)+a) = n :=
  le_antisymmₓ
    (le_of_lt_succ$
      sqrt_lt.2$
        by 
          rw [succ_mul, mul_succ, add_succ, add_assocₓ] <;> exact lt_succ_of_le (Nat.add_le_add_leftₓ h _))
    (le_sqrt.2$ Nat.le_add_rightₓ _ _)

theorem sqrt_add_eq' (n : ℕ) {a : ℕ} (h : a ≤ n+n) : sqrt ((n ^ 2)+a) = n :=
  (congr_argₓ (fun i => sqrt (i+a)) (sq n)).trans (sqrt_add_eq n h)

theorem sqrt_eq (n : ℕ) : sqrt (n*n) = n :=
  sqrt_add_eq n (zero_le _)

theorem sqrt_eq' (n : ℕ) : sqrt (n ^ 2) = n :=
  sqrt_add_eq' n (zero_le _)

theorem sqrt_succ_le_succ_sqrt (n : ℕ) : sqrt n.succ ≤ n.sqrt.succ :=
  le_of_lt_succ$
    sqrt_lt.2$
      lt_succ_of_le$
        succ_le_succ$
          le_transₓ (sqrt_le_add n)$
            add_le_add_right
              (by 
                refine' add_le_add (Nat.mul_le_mul_rightₓ _ _) _ <;> exact Nat.le_add_rightₓ _ 2)
              _

theorem exists_mul_self (x : ℕ) : (∃ n, (n*n) = x) ↔ (sqrt x*sqrt x) = x :=
  ⟨fun ⟨n, hn⟩ =>
      by 
        rw [←hn, sqrt_eq],
    fun h => ⟨sqrt x, h⟩⟩

theorem exists_mul_self' (x : ℕ) : (∃ n, n ^ 2 = x) ↔ sqrt x ^ 2 = x :=
  by 
    simpa only [pow_two] using exists_mul_self x

theorem sqrt_mul_sqrt_lt_succ (n : ℕ) : (sqrt n*sqrt n) < n+1 :=
  lt_succ_iff.mpr (sqrt_le _)

theorem sqrt_mul_sqrt_lt_succ' (n : ℕ) : sqrt n ^ 2 < n+1 :=
  lt_succ_iff.mpr (sqrt_le' _)

theorem succ_le_succ_sqrt (n : ℕ) : (n+1) ≤ (sqrt n+1)*sqrt n+1 :=
  le_of_pred_lt (lt_succ_sqrt _)

theorem succ_le_succ_sqrt' (n : ℕ) : (n+1) ≤ (sqrt n+1) ^ 2 :=
  le_of_pred_lt (lt_succ_sqrt' _)

-- error in Data.Nat.Sqrt: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- There are no perfect squares strictly between m² and (m+1)² -/
theorem not_exists_sq
{n m : exprℕ()}
(hl : «expr < »(«expr * »(m, m), n))
(hr : «expr < »(n, «expr * »(«expr + »(m, 1), «expr + »(m, 1)))) : «expr¬ »(«expr∃ , »((t), «expr = »(«expr * »(t, t), n))) :=
begin
  rintro ["⟨", ident t, ",", ident rfl, "⟩"],
  have [ident h1] [":", expr «expr < »(m, t)] [],
  from [expr nat.mul_self_lt_mul_self_iff.mpr hl],
  have [ident h2] [":", expr «expr < »(t, «expr + »(m, 1))] [],
  from [expr nat.mul_self_lt_mul_self_iff.mpr hr],
  exact [expr «expr $ »(not_lt_of_ge, le_of_lt_succ h2) h1]
end

theorem not_exists_sq' {n m : ℕ} (hl : m ^ 2 < n) (hr : n < (m+1) ^ 2) : ¬∃ t, t ^ 2 = n :=
  by 
    simpa only [pow_two] using
      not_exists_sq
        (by 
          simpa only [pow_two] using hl)
        (by 
          simpa only [pow_two] using hr)

end Nat

