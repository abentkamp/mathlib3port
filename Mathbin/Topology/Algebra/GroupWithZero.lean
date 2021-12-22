import Mathbin.Topology.Algebra.Monoid
import Mathbin.Algebra.Group.Pi
import Mathbin.Topology.Homeomorph

/-!
# Topological group with zero

In this file we define `has_continuous_inv'` to be a mixin typeclass a type with `has_inv` and
`has_zero` (e.g., a `group_with_zero`) such that `λ x, x⁻¹` is continuous at all nonzero points. Any
normed (semi)field has this property. Currently the only example of `has_continuous_inv'` in
`mathlib` which is not a normed field is the type `nnnreal` (a.k.a. `ℝ≥0`) of nonnegative real
numbers.

Then we prove lemmas about continuity of `x ↦ x⁻¹` and `f / g` providing dot-style `*.inv'` and
`*.div` operations on `filter.tendsto`, `continuous_at`, `continuous_within_at`, `continuous_on`,
and `continuous`. As a special case, we provide `*.div_const` operations that require only
`group_with_zero` and `has_continuous_mul` instances.

All lemmas about `(⁻¹)` use `inv'` in their names because lemmas without `'` are used for
`topological_group`s. We also use `'` in the typeclass name `has_continuous_inv'` for the sake of
consistency of notation.

On a `group_with_zero` with continuous multiplication, we also define left and right multiplication
as homeomorphisms.
-/


open_locale TopologicalSpace Filter

open Filter Function

/-!
### A group with zero with continuous multiplication

If `G₀` is a group with zero with continuous `(*)`, then `(/y)` is continuous for any `y`. In this
section we prove lemmas that immediately follow from this fact providing `*.div_const` dot-style
operations on `filter.tendsto`, `continuous_at`, `continuous_within_at`, `continuous_on`, and
`continuous`.
-/


variable {α β G₀ : Type _}

section DivConst

variable [GroupWithZeroₓ G₀] [TopologicalSpace G₀] [HasContinuousMul G₀] {f : α → G₀} {s : Set α} {l : Filter α}

theorem Filter.Tendsto.div_const {x y : G₀} (hf : tendsto f l (𝓝 x)) : tendsto (fun a => f a / y) l (𝓝 (x / y)) := by
  simpa only [div_eq_mul_inv] using hf.mul tendsto_const_nhds

variable [TopologicalSpace α]

theorem ContinuousAt.div_const {a : α} (hf : ContinuousAt f a) {y : G₀} : ContinuousAt (fun x => f x / y) a := by
  simpa only [div_eq_mul_inv] using hf.mul continuous_at_const

theorem ContinuousWithinAt.div_const {a} (hf : ContinuousWithinAt f s a) {y : G₀} :
    ContinuousWithinAt (fun x => f x / y) s a :=
  hf.div_const

theorem ContinuousOn.div_const (hf : ContinuousOn f s) {y : G₀} : ContinuousOn (fun x => f x / y) s := by
  simpa only [div_eq_mul_inv] using hf.mul continuous_on_const

@[continuity]
theorem Continuous.div_const (hf : Continuous f) {y : G₀} : Continuous fun x => f x / y := by
  simpa only [div_eq_mul_inv] using hf.mul continuous_const

end DivConst

/--  A type with `0` and `has_inv` such that `λ x, x⁻¹` is continuous at all nonzero points. Any
normed (semi)field has this property. -/
class HasContinuousInv₀ (G₀ : Type _) [HasZero G₀] [HasInv G₀] [TopologicalSpace G₀] where
  continuous_at_inv₀ : ∀ ⦃x : G₀⦄, x ≠ 0 → ContinuousAt HasInv.inv x

export HasContinuousInv₀ (continuous_at_inv₀)

section Inv₀

variable [HasZero G₀] [HasInv G₀] [TopologicalSpace G₀] [HasContinuousInv₀ G₀] {l : Filter α} {f : α → G₀} {s : Set α}
  {a : α}

/-!
### Continuity of `λ x, x⁻¹` at a non-zero point

We define `topological_group_with_zero` to be a `group_with_zero` such that the operation `x ↦ x⁻¹`
is continuous at all nonzero points. In this section we prove dot-style `*.inv'` lemmas for
`filter.tendsto`, `continuous_at`, `continuous_within_at`, `continuous_on`, and `continuous`.
-/


theorem tendsto_inv₀ {x : G₀} (hx : x ≠ 0) : tendsto HasInv.inv (𝓝 x) (𝓝 (x⁻¹)) :=
  continuous_at_inv₀ hx

theorem continuous_on_inv₀ : ContinuousOn (HasInv.inv : G₀ → G₀) ({0}ᶜ) := fun x hx =>
  (continuous_at_inv₀ hx).ContinuousWithinAt

/--  If a function converges to a nonzero value, its inverse converges to the inverse of this value.
We use the name `tendsto.inv₀` as `tendsto.inv` is already used in multiplicative topological
groups. -/
theorem Filter.Tendsto.inv₀ {a : G₀} (hf : tendsto f l (𝓝 a)) (ha : a ≠ 0) : tendsto (fun x => f x⁻¹) l (𝓝 (a⁻¹)) :=
  (tendsto_inv₀ ha).comp hf

variable [TopologicalSpace α]

theorem ContinuousWithinAt.inv₀ (hf : ContinuousWithinAt f s a) (ha : f a ≠ 0) :
    ContinuousWithinAt (fun x => f x⁻¹) s a :=
  hf.inv₀ ha

theorem ContinuousAt.inv₀ (hf : ContinuousAt f a) (ha : f a ≠ 0) : ContinuousAt (fun x => f x⁻¹) a :=
  hf.inv₀ ha

@[continuity]
theorem Continuous.inv₀ (hf : Continuous f) (h0 : ∀ x, f x ≠ 0) : Continuous fun x => f x⁻¹ :=
  continuous_iff_continuous_at.2 $ fun x => (hf.tendsto x).inv₀ (h0 x)

theorem ContinuousOn.inv₀ (hf : ContinuousOn f s) (h0 : ∀, ∀ x ∈ s, ∀, f x ≠ 0) : ContinuousOn (fun x => f x⁻¹) s :=
  fun x hx => (hf x hx).inv₀ (h0 x hx)

end Inv₀

/-!
### Continuity of division

If `G₀` is a `group_with_zero` with `x ↦ x⁻¹` continuous at all nonzero points and `(*)`, then
division `(/)` is continuous at any point where the denominator is continuous.
-/


section Div

variable [GroupWithZeroₓ G₀] [TopologicalSpace G₀] [HasContinuousInv₀ G₀] [HasContinuousMul G₀] {f g : α → G₀}

theorem Filter.Tendsto.div {l : Filter α} {a b : G₀} (hf : tendsto f l (𝓝 a)) (hg : tendsto g l (𝓝 b)) (hy : b ≠ 0) :
    tendsto (f / g) l (𝓝 (a / b)) := by
  simpa only [div_eq_mul_inv] using hf.mul (hg.inv₀ hy)

variable [TopologicalSpace α] [TopologicalSpace β] {s : Set α} {a : α}

theorem ContinuousWithinAt.div (hf : ContinuousWithinAt f s a) (hg : ContinuousWithinAt g s a) (h₀ : g a ≠ 0) :
    ContinuousWithinAt (f / g) s a :=
  hf.div hg h₀

theorem ContinuousOn.div (hf : ContinuousOn f s) (hg : ContinuousOn g s) (h₀ : ∀, ∀ x ∈ s, ∀, g x ≠ 0) :
    ContinuousOn (f / g) s := fun x hx => (hf x hx).div (hg x hx) (h₀ x hx)

/--  Continuity at a point of the result of dividing two functions continuous at that point, where
the denominator is nonzero. -/
theorem ContinuousAt.div (hf : ContinuousAt f a) (hg : ContinuousAt g a) (h₀ : g a ≠ 0) : ContinuousAt (f / g) a :=
  hf.div hg h₀

@[continuity]
theorem Continuous.div (hf : Continuous f) (hg : Continuous g) (h₀ : ∀ x, g x ≠ 0) : Continuous (f / g) := by
  simpa only [div_eq_mul_inv] using hf.mul (hg.inv₀ h₀)

/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize.input] (Command.declaration
 (Command.declModifiers [] [] [] [] [] [])
 (Command.theorem
  "theorem"
  (Command.declId `continuous_on_div [])
  (Command.declSig
   []
   (Term.typeSpec
    ":"
    (Term.app
     `ContinuousOn
     [(Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder [`p] [(Term.typeSpec ":" («term_×_» `G₀ "×" `G₀))])]
        "=>"
        («term_/_» (Term.proj `p "." (fieldIdx "1")) "/" (Term.proj `p "." (fieldIdx "2")))))
      (Set.«term{_|_}» "{" `p "|" («term_≠_» (Term.proj `p "." (fieldIdx "2")) "≠" (numLit "0")) "}")])))
  (Command.declValSimple
   ":="
   («term_$__»
    (Term.app (Term.proj `continuous_on_fst "." `div) [`continuous_on_snd])
    "$"
    (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [(Term.hole "_")] [])] "=>" `id)))
   [])
  []
  []))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declaration', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declaration', expected 'Lean.Parser.Command.declaration.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.abbrev.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.abbrev'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.def.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.def'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.theorem.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValSimple.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  («term_$__»
   (Term.app (Term.proj `continuous_on_fst "." `div) [`continuous_on_snd])
   "$"
   (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [(Term.hole "_")] [])] "=>" `id)))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«term_$__»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [(Term.hole "_")] [])] "=>" `id))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'Lean.Parser.Term.fun.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.basicFun', expected 'Lean.Parser.Term.basicFun.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `id
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.strictImplicitBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.strictImplicitBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.implicitBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.implicitBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.instBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.instBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.simpleBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.hole', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.hole', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 10 >? 1024, (some 0, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 10, term))
  (Term.app (Term.proj `continuous_on_fst "." `div) [`continuous_on_snd])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `continuous_on_snd
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  (Term.proj `continuous_on_fst "." `div)
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.proj', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1024, term))
  `continuous_on_fst
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (some 1024, term)
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (some 10, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 10, (some 0, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declSig', expected 'Lean.Parser.Command.declSig.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.typeSpec', expected 'Lean.Parser.Term.typeSpec.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1023, [anonymous]))
  (Term.app
   `ContinuousOn
   [(Term.fun
     "fun"
     (Term.basicFun
      [(Term.simpleBinder [`p] [(Term.typeSpec ":" («term_×_» `G₀ "×" `G₀))])]
      "=>"
      («term_/_» (Term.proj `p "." (fieldIdx "1")) "/" (Term.proj `p "." (fieldIdx "2")))))
    (Set.«term{_|_}» "{" `p "|" («term_≠_» (Term.proj `p "." (fieldIdx "2")) "≠" (numLit "0")) "}")])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Set.«term{_|_}» "{" `p "|" («term_≠_» (Term.proj `p "." (fieldIdx "2")) "≠" (numLit "0")) "}")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Set.«term{_|_}»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  («term_≠_» (Term.proj `p "." (fieldIdx "2")) "≠" (numLit "0"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«term_≠_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (numLit "0")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'numLit.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 51 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 50, term))
  (Term.proj `p "." (fieldIdx "2"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.proj', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1024, term))
  `p
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (some 1024, term)
[PrettyPrinter.parenthesize] ...precedences are 51 >? 1024, (none, [anonymous]) <=? (some 50, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 50, (some 51, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Mathlib.ExtendedBinder.extBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.constant.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.constant'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.instance.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.instance'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.axiom.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.axiom'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.example.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.example'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.inductive.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.inductive'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.classInductive.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.classInductive'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.structure.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.theorem', expected 'Lean.Parser.Command.structure'-/-- failed to format: format: uncaught backtrack exception
theorem
  continuous_on_div
  : ContinuousOn fun p : G₀ × G₀ => p . 1 / p . 2 { p | p . 2 ≠ 0 }
  := continuous_on_fst . div continuous_on_snd $ fun _ => id

/--  The function `f x / g x` is discontinuous when `g x = 0`.
However, under appropriate conditions, `h x (f x / g x)` is still continuous.
The condition is that if `g a = 0` then `h x y` must tend to `h a 0` when `x` tends to `a`,
with no information about `y`. This is represented by the `⊤` filter.
Note: `filter.tendsto_prod_top_iff` characterizes this convergence in uniform spaces.
See also `filter.prod_top` and `filter.mem_prod_top`. -/
theorem ContinuousAt.comp_div_cases {f g : α → G₀} (h : α → G₀ → β) (hf : ContinuousAt f a) (hg : ContinuousAt g a)
    (hh : g a ≠ 0 → ContinuousAt (↿h) (a, f a / g a)) (h2h : g a = 0 → tendsto (↿h) (𝓝 a ×ᶠ ⊤) (𝓝 (h a 0))) :
    ContinuousAt (fun x => h x (f x / g x)) a := by
  show ContinuousAt (↿h ∘ fun x => (x, f x / g x)) a
  by_cases' hga : g a = 0
  ·
    rw [ContinuousAt]
    simp_rw [comp_app, hga, div_zero]
    exact (h2h hga).comp (continuous_at_id.prod_mk tendsto_top)
  ·
    exact ContinuousAt.comp (hh hga) (continuous_at_id.prod (hf.div hg hga))

/--  `h x (f x / g x)` is continuous under certain conditions, even if the denominator is sometimes
  `0`. See docstring of `continuous_at.comp_div_cases`. -/
theorem Continuous.comp_div_cases {f g : α → G₀} (h : α → G₀ → β) (hf : Continuous f) (hg : Continuous g)
    (hh : ∀ a, g a ≠ 0 → ContinuousAt (↿h) (a, f a / g a)) (h2h : ∀ a, g a = 0 → tendsto (↿h) (𝓝 a ×ᶠ ⊤) (𝓝 (h a 0))) :
    Continuous fun x => h x (f x / g x) :=
  continuous_iff_continuous_at.mpr $ fun a => hf.continuous_at.comp_div_cases _ hg.continuous_at (hh a) (h2h a)

end Div

/-! ### Left and right multiplication as homeomorphisms -/


namespace Homeomorph

variable [TopologicalSpace α] [GroupWithZeroₓ α] [HasContinuousMul α]

/--  Left multiplication by a nonzero element in a `group_with_zero` with continuous multiplication
is a homeomorphism of the underlying type. -/
protected def mul_left₀ (c : α) (hc : c ≠ 0) : α ≃ₜ α :=
  { Equivₓ.mulLeft₀ c hc with continuous_to_fun := continuous_mul_left _, continuous_inv_fun := continuous_mul_left _ }

/--  Right multiplication by a nonzero element in a `group_with_zero` with continuous multiplication
is a homeomorphism of the underlying type. -/
protected def mul_right₀ (c : α) (hc : c ≠ 0) : α ≃ₜ α :=
  { Equivₓ.mulRight₀ c hc with continuous_to_fun := continuous_mul_right _,
    continuous_inv_fun := continuous_mul_right _ }

@[simp]
theorem coe_mul_left₀ (c : α) (hc : c ≠ 0) : ⇑Homeomorph.mulLeft₀ c hc = (·*·) c :=
  rfl

@[simp]
theorem mul_left₀_symm_apply (c : α) (hc : c ≠ 0) : ((Homeomorph.mulLeft₀ c hc).symm : α → α) = (·*·) (c⁻¹) :=
  rfl

@[simp]
theorem coe_mul_right₀ (c : α) (hc : c ≠ 0) : ⇑Homeomorph.mulRight₀ c hc = fun x => x*c :=
  rfl

@[simp]
theorem mul_right₀_symm_apply (c : α) (hc : c ≠ 0) : ((Homeomorph.mulRight₀ c hc).symm : α → α) = fun x => x*c⁻¹ :=
  rfl

end Homeomorph

section Zpow

variable [GroupWithZeroₓ G₀] [TopologicalSpace G₀] [HasContinuousInv₀ G₀] [HasContinuousMul G₀]

theorem continuous_at_zpow (x : G₀) (m : ℤ) (h : x ≠ 0 ∨ 0 ≤ m) : ContinuousAt (fun x => x ^ m) x := by
  cases m
  ·
    simpa only [zpow_of_nat] using continuous_at_pow x m
  ·
    simp only [zpow_neg_succ_of_nat]
    have hx : x ≠ 0
    exact h.resolve_right (Int.neg_succ_of_nat_lt_zero m).not_le
    exact (continuous_at_pow x (m+1)).inv₀ (pow_ne_zero _ hx)

theorem continuous_on_zpow (m : ℤ) : ContinuousOn (fun x : G₀ => x ^ m) ({0}ᶜ) := fun x hx =>
  (continuous_at_zpow _ _ (Or.inl hx)).ContinuousWithinAt

theorem Filter.Tendsto.zpow {f : α → G₀} {l : Filter α} {a : G₀} (hf : tendsto f l (𝓝 a)) (m : ℤ) (h : a ≠ 0 ∨ 0 ≤ m) :
    tendsto (fun x => f x ^ m) l (𝓝 (a ^ m)) :=
  (continuous_at_zpow _ m h).Tendsto.comp hf

variable {X : Type _} [TopologicalSpace X] {a : X} {s : Set X} {f : X → G₀}

theorem ContinuousAt.zpow (hf : ContinuousAt f a) (m : ℤ) (h : f a ≠ 0 ∨ 0 ≤ m) : ContinuousAt (fun x => f x ^ m) a :=
  hf.zpow m h

theorem ContinuousWithinAt.zpow (hf : ContinuousWithinAt f s a) (m : ℤ) (h : f a ≠ 0 ∨ 0 ≤ m) :
    ContinuousWithinAt (fun x => f x ^ m) s a :=
  hf.zpow m h

theorem ContinuousOn.zpow (hf : ContinuousOn f s) (m : ℤ) (h : ∀, ∀ a ∈ s, ∀, f a ≠ 0 ∨ 0 ≤ m) :
    ContinuousOn (fun x => f x ^ m) s := fun a ha => (hf a ha).zpow m (h a ha)

@[continuity]
theorem Continuous.zpow (hf : Continuous f) (m : ℤ) (h0 : ∀ a, f a ≠ 0 ∨ 0 ≤ m) : Continuous fun x => f x ^ m :=
  continuous_iff_continuous_at.2 $ fun x => (hf.tendsto x).zpow m (h0 x)

end Zpow

