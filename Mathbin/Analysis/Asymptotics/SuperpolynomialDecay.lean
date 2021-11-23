import Mathbin.Analysis.NormedSpace.Ordered 
import Mathbin.Analysis.Asymptotics.Asymptotics 
import Mathbin.Data.Polynomial.Eval

/-!
# Super-Polynomial Function Decay

This file defines a predicate `asymptotics.superpolynomial_decay f` for a function satisfying
  one of following equivalent definitions (The definition is in terms of the first condition):

* `f` is `O(x ^ c)` for all (or sufficiently small) integers `c`
* `x ^ c * f` is bounded for all (or sufficiently large) integers `c`
* `x ^ c * f` tends to `𝓝 0` for all (or sufficiently large) integers `c`
* `f` is `o(x ^ c)` for all (or sufficiently small) integers `c`

The equivalence between the first two is given by in `superpolynomial_decay_iff_is_bounded_under`.
The equivalence between the first and third is given in `superpolynomial_decay_iff_tendsto_zero`.
The equivalence between the first and fourth is given in `superpolynomial_decay_iff_is_o`.

These conditions are all equivalent to conditions in terms of polynomials, replacing `x ^ c` with
  `p(x)` or `p(x)⁻¹` as appropriate, since asymptotically `p(x)` behaves like `X ^ p.nat_degree`.
These further equivalences are not proven in mathlib but would be good future projects.

The definition of superpolynomial decay for a function `f : α → 𝕜`
  is made relative to an algebra structure `[algebra α 𝕜]`.
Super-polynomial decay then means the function `f x` decays faster than
  `(p.eval (algebra_map α 𝕜 x))⁻¹` for all polynomials `p : polynomial 𝕜`.

When the algebra structure is given by `n ↦ ↑n : ℕ → ℝ` this defines negligible functions:
https://en.wikipedia.org/wiki/Negligible_function

When the algebra structure is given by `(r₁,...,rₙ) ↦ r₁*...*rₙ : ℝⁿ → ℝ` this is equivalent
  to the definition of rapidly decreasing functions given here:
https://ncatlab.org/nlab/show/rapidly+decreasing+function

# Main Theorems

* `superpolynomial_decay.polynomial_mul` says that if `f(x)` is negligible,
    then so is `p(x) * f(x)` for any polynomial `p`.
* `superpolynomial_decay_iff_is_bounded_under` says that `f` is negligible iff
    `p(x) * f(x)` has bounded norm for all polynomials `p(x)`.
* `superpolynomial_decay_of_eventually_is_O` says that it suffices to check `f(x)` is `O(x ^ c)`
    for only sufficiently small `c`, rather than all integers `c`.
-/


namespace Asymptotics

open_locale TopologicalSpace

open Filter

/-- A function `f` from an `ordered_comm_semiring` to a `normed_field` has superpolynomial decay
  iff `f(x)` is `O(x ^ c)` for all integers `c`. -/
def superpolynomial_decay {α 𝕜 : Type _} [OrderedCommSemiring α] [NormedField 𝕜] [Algebra α 𝕜] (f : α → 𝕜) :=
  ∀ c : ℤ, is_O f (fun x => algebraMap α 𝕜 x ^ c) Filter.atTop

section NormedField

variable{α 𝕜 : Type _}[OrderedCommSemiring α][NormedField 𝕜][Algebra α 𝕜]

variable{f g : α → 𝕜}

theorem superpolynomial_decay_iff_is_bounded_under (f : α → 𝕜) (hα : ∀ᶠx : α in at_top, algebraMap α 𝕜 x ≠ 0) :
  superpolynomial_decay f ↔ ∀ c : ℤ, is_bounded_under LE.le at_top fun x => ∥f x*algebraMap α 𝕜 x ^ c∥ :=
  by 
    split  <;> intro h c <;> specialize h (-c)
    ·
      simpa [div_eq_mul_inv] using div_is_bounded_under_of_is_O h
    ·
      refine' (is_O_iff_div_is_bounded_under _).2 _
      ·
        exact hα.mono fun x hx hx' => absurd (zpow_eq_zero hx') hx
      ·
        simpa [div_eq_mul_inv] using h

-- error in Analysis.Asymptotics.SuperpolynomialDecay: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem superpolynomial_decay_iff_is_o
(f : α → 𝕜)
(hα : tendsto (λ
  x, «expr∥ ∥»(algebra_map α 𝕜 x)) at_top at_top) : «expr ↔ »(superpolynomial_decay f, ∀
 c : exprℤ(), is_o f (λ x, «expr ^ »(algebra_map α 𝕜 x, c)) at_top) :=
begin
  refine [expr ⟨λ h c, _, λ h c, (h c).is_O⟩],
  have [ident hα'] [":", expr «expr∀ᶠ in , »((x : α), at_top, «expr ≠ »(algebra_map α 𝕜 x, 0))] [],
  from [expr (eventually_ne_of_tendsto_norm_at_top hα 0).mono (λ x hx hx', absurd hx' hx)],
  have [] [":", expr is_o (λ x, 1 : α → 𝕜) (λ x, algebra_map α 𝕜 x) at_top] [],
  { refine [expr is_o_of_tendsto' «expr $ »(hα'.mono, λ
      x hx hx', absurd hx' hx) (tendsto_zero_iff_norm_tendsto_zero.2 _)],
    simp [] [] ["only"] ["[", expr one_div, ",", expr normed_field.norm_inv, "]"] [] [],
    exact [expr tendsto.comp tendsto_inv_at_top_zero hα] },
  have [] [] [":=", expr this.mul_is_O «expr $ »(h, «expr - »(c, 1))],
  simp [] [] ["only"] ["[", expr one_mul, "]"] [] ["at", ident this],
  refine [expr this.trans_is_O (is_O.of_bound 1 (hα'.mono (λ x hx, le_of_eq _)))],
  rw ["[", expr zpow_sub_one₀ hx, ",", expr mul_comm, ",", expr mul_assoc, ",", expr inv_mul_cancel hx, ",", expr one_mul, ",", expr mul_one, "]"] []
end

-- error in Analysis.Asymptotics.SuperpolynomialDecay: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem superpolynomial_decay_iff_norm_tendsto_zero
(f : α → 𝕜)
(hα : tendsto (λ
  x, «expr∥ ∥»(algebra_map α 𝕜 x)) at_top at_top) : «expr ↔ »(superpolynomial_decay f, ∀
 c : exprℤ(), tendsto (λ x, «expr∥ ∥»(«expr * »(f x, «expr ^ »(algebra_map α 𝕜 x, c)))) at_top (expr𝓝() 0)) :=
begin
  refine [expr ⟨λ h c, _, λ h, _⟩],
  { refine [expr tendsto_zero_iff_norm_tendsto_zero.1 _],
    rw [expr superpolynomial_decay_iff_is_o f hα] ["at", ident h],
    simpa [] [] [] ["[", expr div_eq_mul_inv, "]"] [] ["using", expr «expr $ »(h, «expr- »(c)).tendsto_0] },
  { have [ident hα'] [":", expr «expr∀ᶠ in , »((x : α), at_top, «expr ≠ »(algebra_map α 𝕜 x, 0))] [],
    from [expr (eventually_ne_of_tendsto_norm_at_top hα 0).mono (λ x hx hx', absurd hx' hx)],
    exact [expr (superpolynomial_decay_iff_is_bounded_under f hα').2 (λ
      c, is_bounded_under_of_tendsto «expr $ »(tendsto_zero_iff_norm_tendsto_zero.2, h c))] }
end

theorem superpolynomial_decay_iff_tendsto_zero (f : α → 𝕜) (hα : tendsto (fun x => ∥algebraMap α 𝕜 x∥) at_top at_top) :
  superpolynomial_decay f ↔ ∀ c : ℤ, tendsto (fun x => f x*algebraMap α 𝕜 x ^ c) at_top (𝓝 0) :=
  (superpolynomial_decay_iff_norm_tendsto_zero f hα).trans
    (by 
      simp [tendsto_zero_iff_norm_tendsto_zero])

theorem is_O.trans_superpolynomial_decay (h : is_O f g at_top) (hg : superpolynomial_decay g) :
  superpolynomial_decay f :=
  fun c => h.trans$ hg c

alias is_O.trans_superpolynomial_decay ← SuperpolynomialDecay.is_O_mono

theorem superpolynomial_decay.mono (hf : superpolynomial_decay f) (h : ∀ n, ∥g n∥ ≤ ∥f n∥) : superpolynomial_decay g :=
  (is_O_of_le at_top h).trans_superpolynomial_decay hf

theorem superpolynomial_decay.eventually_mono (hf : superpolynomial_decay f) (h : ∀ᶠn in at_top, ∥g n∥ ≤ ∥f n∥) :
  superpolynomial_decay g :=
  (is_O_iff.2
        ⟨1,
          by 
            simpa only [one_mulₓ] using h⟩).trans_superpolynomial_decay
    hf

@[simp]
theorem superpolynomial_decay_zero : superpolynomial_decay (0 : α → 𝕜) :=
  fun c => is_O_zero _ _

@[simp]
theorem superpolynomial_decay_zero' : superpolynomial_decay fun x : α => (0 : 𝕜) :=
  superpolynomial_decay_zero

theorem superpolynomial_decay.add (hf : superpolynomial_decay f) (hg : superpolynomial_decay g) :
  superpolynomial_decay (f+g) :=
  fun c => is_O.add (hf c) (hg c)

theorem superpolynomial_decay.const_mul (hf : superpolynomial_decay f) (c : 𝕜) : superpolynomial_decay fun n => c*f n :=
  (is_O_const_mul_self c f at_top).trans_superpolynomial_decay hf

theorem superpolynomial_decay.mul_const (hf : superpolynomial_decay f) (c : 𝕜) : superpolynomial_decay fun n => f n*c :=
  by 
    simpa [mul_commₓ _ c] using superpolynomial_decay.const_mul hf c

theorem superpolynomial_decay_const_mul_iff_of_ne_zero {c : 𝕜} (hc : c ≠ 0) :
  (superpolynomial_decay fun n => c*f n) ↔ superpolynomial_decay f :=
  ⟨fun h => (is_O_self_const_mul c hc f at_top).trans_superpolynomial_decay h, fun h => h.const_mul c⟩

theorem superpolynomial_decay_mul_const_iff_of_ne_zero {c : 𝕜} (hc : c ≠ 0) :
  (superpolynomial_decay fun n => f n*c) ↔ superpolynomial_decay f :=
  by 
    simpa [mul_commₓ _ c] using superpolynomial_decay_const_mul_iff_of_ne_zero hc

@[simp]
theorem superpolynomial_decay_const_mul_iff (c : 𝕜) :
  (superpolynomial_decay fun n => c*f n) ↔ c = 0 ∨ superpolynomial_decay f :=
  by 
    byCases' hc0 : c = 0
    ·
      simp [hc0]
    ·
      exact
        (superpolynomial_decay_const_mul_iff_of_ne_zero hc0).trans ⟨Or.inr, Or.ndrec (fun hc0' => absurd hc0' hc0) id⟩

@[simp]
theorem superpolynomial_decay_mul_const_iff (c : 𝕜) :
  (superpolynomial_decay fun n => f n*c) ↔ c = 0 ∨ superpolynomial_decay f :=
  by 
    simp [mul_commₓ _ c]

section NoZeroSmulDivisors

variable[NoZeroSmulDivisors α 𝕜]

-- error in Analysis.Asymptotics.SuperpolynomialDecay: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem superpolynomial_decay.algebra_map_mul
(hf : superpolynomial_decay f) : superpolynomial_decay (λ n, «expr * »(algebra_map α 𝕜 n, f n)) :=
begin
  haveI [] [":", expr nontrivial α] [":=", expr (algebra_map α 𝕜).domain_nontrivial],
  refine [expr λ c, (is_O.mul (is_O_refl (algebra_map α 𝕜) at_top) (hf «expr - »(c, 1))).trans _],
  refine [expr is_O_of_div_tendsto_nhds (eventually_of_forall (λ
     x hx, mul_eq_zero_of_left (zpow_eq_zero hx) _)) 1 (tendsto_nhds.2 _)],
  refine [expr λ s hs hs', at_top.sets_of_superset (mem_at_top 1) (λ x hx, set.mem_preimage.2 _)],
  have [ident hx'] [":", expr «expr ≠ »(algebra_map α 𝕜 x, 0)] [":=", expr λ
   hx', «expr $ »(ne_of_lt, lt_of_lt_of_le zero_lt_one hx).symm (by simpa [] [] [] ["[", expr algebra.algebra_map_eq_smul_one, ",", expr smul_eq_zero, "]"] [] ["using", expr hx'])],
  convert [] [expr hs'] [],
  rw ["[", expr pi.div_apply, ",", expr div_eq_one_iff_eq (zpow_ne_zero c hx'), ",", expr zpow_sub_one₀ hx' c, ",", expr mul_comm (algebra_map α 𝕜 x), ",", expr mul_assoc, ",", expr inv_mul_cancel hx', ",", expr mul_one, "]"] []
end

theorem superpolynomial_decay.algebra_map_pow_mul (hf : superpolynomial_decay f) (p : ℕ) :
  superpolynomial_decay fun n => (algebraMap α 𝕜 n ^ p)*f n :=
  by 
    induction' p with p hp
    ·
      simpRw [pow_zeroₓ, one_mulₓ]
      exact hf
    ·
      simpRw [pow_succₓ, mul_assocₓ]
      exact hp.algebra_map_mul

theorem superpolynomial_decay.polynomial_mul (hf : superpolynomial_decay f) (p : Polynomial 𝕜) :
  superpolynomial_decay fun n => p.eval (algebraMap α 𝕜 n)*f n :=
  by 
    refine' Polynomial.induction_on' p (fun p q hp hq => _) fun m x => _
    ·
      simpRw [Polynomial.eval_add, add_mulₓ]
      exact hp.add hq
    ·
      simpRw [Polynomial.eval_monomial, mul_assocₓ]
      exact (hf.algebra_map_pow_mul m).const_mul x

/-- If `f` has superpolynomial decay, and `g` is `O(p)` for some polynomial `p`,
  then `f * g` has superpolynomial decay -/
theorem superpolynomial_decay.mul_is_O_polynomial (hf : superpolynomial_decay f) (p : Polynomial 𝕜)
  (hg : is_O g (fun n => p.eval (algebraMap α 𝕜 n)) Filter.atTop) : superpolynomial_decay (f*g) :=
  (is_O.mul (is_O_refl f at_top) hg).trans_superpolynomial_decay
    ((hf.polynomial_mul p).mono$ fun x => le_of_eqₓ (congr_argₓ _$ mul_commₓ _ _))

/-- If `f` has superpolynomial decay, and `g` is `O(n ^ c)` for some integer `c`,
  then `f * g` has has superpolynomial decay-/
theorem superpolynomial_decay.mul_is_O (hf : superpolynomial_decay f) (c : ℕ)
  (hg : is_O g (fun n => algebraMap α 𝕜 n ^ c) at_top) : superpolynomial_decay (f*g) :=
  (is_O.mul (is_O_refl f at_top) hg).trans_superpolynomial_decay
    ((hf.algebra_map_pow_mul c).mono$ fun x => le_of_eqₓ (congr_argₓ _$ mul_commₓ _ _))

theorem superpolynomial_decay.mul (hf : superpolynomial_decay f) (hg : superpolynomial_decay g) :
  superpolynomial_decay (f*g) :=
  hf.mul_is_O 0
    (by 
      simpa using hg 0)

end NoZeroSmulDivisors

end NormedField

section NormedLinearOrderedField

variable{α 𝕜 : Type _}[OrderedCommSemiring α][NormedLinearOrderedField 𝕜][Algebra α 𝕜]

variable{f g : α → 𝕜}

/-- It suffices to check the decay condition for only sufficiently small exponents `c`,
  assuing algebra_map eventually has norm at least `1` -/
theorem superpolynomial_decay_of_eventually_is_O (hα : ∀ᶠx : α in at_top, 1 ≤ ∥algebraMap α 𝕜 x∥)
  (h : ∀ᶠc : ℤ in at_bot, is_O f (fun x => algebraMap α 𝕜 x ^ c) at_top) : superpolynomial_decay f :=
  by 
    obtain ⟨C, hC⟩ := eventually_at_bot.mp h 
    intro c 
    byCases' hc : c ≤ C
    ·
      exact hC c hc
    ·
      refine' (hC C le_rfl).trans (is_O.of_bound 1 _)
      refine' at_top.sets_of_superset hα fun x hx => _ 
      simp only [one_mulₓ, NormedField.norm_zpow, Set.mem_set_of_eq]
      exact zpow_le_of_le hx (le_of_not_leₓ hc)

theorem superpolynomial_decay_of_is_O_zpow_le (hα : ∀ᶠx : α in at_top, 1 ≤ ∥algebraMap α 𝕜 x∥) (C : ℤ)
  (h : ∀ c _ : c ≤ C, is_O f (fun n => algebraMap α 𝕜 n ^ c) at_top) : superpolynomial_decay f :=
  superpolynomial_decay_of_eventually_is_O hα (eventually_at_bot.2 ⟨C, h⟩)

theorem superpolynomial_decay_of_is_O_zpow_lt (hα : ∀ᶠx : α in at_top, 1 ≤ ∥algebraMap α 𝕜 x∥) (C : ℤ)
  (h : ∀ c _ : c < C, is_O f (fun n => algebraMap α 𝕜 n ^ c) at_top) : superpolynomial_decay f :=
  superpolynomial_decay_of_is_O_zpow_le hα C.pred fun c hc => h c (lt_of_le_of_ltₓ hc (Int.pred_self_lt C))

section OrderTopology

variable[OrderTopology 𝕜]

-- error in Analysis.Asymptotics.SuperpolynomialDecay: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- A function with superpolynomial decay must tend to zero in the base ring (not just in norm),
  assuming `algebra_map α 𝕜` tends to `at_top` -/
theorem superpolynomial_decay.tendsto_zero
(hα : tendsto (algebra_map α 𝕜) at_top at_top)
(hf : superpolynomial_decay f) : tendsto f at_top (expr𝓝() 0) :=
begin
  refine [expr is_O.trans_tendsto (hf «expr- »(1)) _],
  have [] [":", expr «expr = »(«expr ∘ »((has_inv.inv : 𝕜 → 𝕜), (algebra_map α 𝕜 : α → 𝕜)), λ
    n : α, «expr ^ »(algebra_map α 𝕜 n, («expr- »(1) : exprℤ())))] [],
  by simp [] [] ["only"] ["[", expr zpow_one, ",", expr zpow_neg₀, "]"] [] [],
  exact [expr «expr ▸ »(this, tendsto_inv_at_top_zero.comp hα)]
end

/-- A function with superpolynomial decay eventually has norm less than any positive bound,
  assuming the algebra map tendsto to `at_top` -/
theorem superpolynomial_decay.eventually_le (hα : tendsto (algebraMap α 𝕜) at_top at_top) (hf : superpolynomial_decay f)
  (ε : ℝ) (hε : 0 < ε) : ∀ᶠn : α in at_top, ∥f n∥ ≤ ε :=
  by 
    simpa only [dist_zero_right] using (hf.tendsto_zero hα).Eventually (Metric.closed_ball_mem_nhds (0 : 𝕜) hε)

-- error in Analysis.Asymptotics.SuperpolynomialDecay: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem superpolynomial_decay_const_iff
[(at_top : filter α).ne_bot]
(hα : tendsto (algebra_map α 𝕜) at_top at_top)
(x : 𝕜) : «expr ↔ »(superpolynomial_decay (function.const α x), «expr = »(x, 0)) :=
begin
  refine [expr ⟨λ h, not_not.1 (λ hx, _), λ h, by simp [] [] [] ["[", expr h, "]"] [] []⟩],
  have [] [":", expr «expr ∈ »(«expr ⁻¹' »(function.const α x, «expr ᶜ»({x})), at_top)] [":=", expr «expr $ »(tendsto_nhds.1, h.tendsto_zero hα) «expr ᶜ»({x}) is_open_ne (ne.symm hx)],
  rw ["[", expr set.preimage_const_of_not_mem (by simp [] [] [] [] [] [] : «expr ∉ »(x, «expr ᶜ»(({x} : set 𝕜)))), "]"] ["at", ident this],
  exact [expr at_top.empty_not_mem this]
end

end OrderTopology

end NormedLinearOrderedField

end Asymptotics

