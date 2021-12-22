import Mathbin.Analysis.Complex.Basic
import Mathbin.Data.Complex.Exponential

/-!
# Complex and real exponential

In this file we prove continuity of `complex.exp` and `real.exp`. We also prove a few facts about
limits of `real.exp` at infinity.

## Tags

exp
-/


noncomputable section

open Finset Filter Metric Asymptotics Set Function

open_locale Classical TopologicalSpace

namespace Complex

variable {z y x : ℝ}

theorem exp_bound_sq (x z : ℂ) (hz : ∥z∥ ≤ 1) : ∥exp (x+z) - exp x - z • exp x∥ ≤ ∥exp x∥*∥z∥^2 :=
  calc ∥exp (x+z) - exp x - z*exp x∥ = ∥exp x*exp z - 1 - z∥ := by
    congr
    rw [exp_add]
    ring
    _ = ∥exp x∥*∥exp z - 1 - z∥ := NormedField.norm_mul _ _
    _ ≤ ∥exp x∥*∥z∥^2 := mul_le_mul_of_nonneg_left (abs_exp_sub_one_sub_id_le hz) (norm_nonneg _)
    

theorem locally_lipschitz_exp {r : ℝ} (hr_nonneg : 0 ≤ r) (hr_le : r ≤ 1) (x y : ℂ) (hyx : ∥y - x∥ < r) :
    ∥exp y - exp x∥ ≤ ((1+r)*∥exp x∥)*∥y - x∥ := by
  have hy_eq : y = x+y - x := by
    abel
  have hyx_sq_le : (∥y - x∥^2) ≤ r*∥y - x∥ := by
    rw [pow_two]
    exact mul_le_mul hyx.le le_rfl (norm_nonneg _) hr_nonneg
  have h_sq : ∀ z, ∥z∥ ≤ 1 → ∥exp (x+z) - exp x∥ ≤ (∥z∥*∥exp x∥)+∥exp x∥*∥z∥^2 := by
    intro z hz
    have : ∥exp (x+z) - exp x - z • exp x∥ ≤ ∥exp x∥*∥z∥^2
    exact exp_bound_sq x z hz
    rw [← sub_le_iff_le_add', ← norm_smul z]
    exact (norm_sub_norm_le _ _).trans this
  calc ∥exp y - exp x∥ = ∥exp (x+y - x) - exp x∥ := by
    nth_rw 0[hy_eq]_ ≤ (∥y - x∥*∥exp x∥)+∥exp x∥*∥y - x∥^2 :=
    h_sq (y - x) (hyx.le.trans hr_le)_ ≤ (∥y - x∥*∥exp x∥)+∥exp x∥*r*∥y - x∥ :=
    add_le_add_left (mul_le_mul le_rfl hyx_sq_le (sq_nonneg _) (norm_nonneg _)) _ _ = ((1+r)*∥exp x∥)*∥y - x∥ := by
    ring

@[continuity]
theorem continuous_exp : Continuous exp :=
  continuous_iff_continuous_at.mpr $ fun x =>
    continuous_at_of_locally_lipschitz zero_lt_one (2*∥exp x∥) (locally_lipschitz_exp zero_le_one le_rfl x)

theorem continuous_on_exp {s : Set ℂ} : ContinuousOn exp s :=
  continuous_exp.ContinuousOn

end Complex

section ComplexContinuousExpComp

variable {α : Type _}

open Complex

theorem Filter.Tendsto.cexp {l : Filter α} {f : α → ℂ} {z : ℂ} (hf : tendsto f l (𝓝 z)) :
    tendsto (fun x => exp (f x)) l (𝓝 (exp z)) :=
  (continuous_exp.Tendsto _).comp hf

variable [TopologicalSpace α] {f : α → ℂ} {s : Set α} {x : α}

theorem ContinuousWithinAt.cexp (h : ContinuousWithinAt f s x) : ContinuousWithinAt (fun y => exp (f y)) s x :=
  h.cexp

theorem ContinuousAt.cexp (h : ContinuousAt f x) : ContinuousAt (fun y => exp (f y)) x :=
  h.cexp

theorem ContinuousOn.cexp (h : ContinuousOn f s) : ContinuousOn (fun y => exp (f y)) s := fun x hx => (h x hx).cexp

theorem Continuous.cexp (h : Continuous f) : Continuous fun y => exp (f y) :=
  continuous_iff_continuous_at.2 $ fun x => h.continuous_at.cexp

end ComplexContinuousExpComp

namespace Real

@[continuity]
theorem continuous_exp : Continuous exp :=
  Complex.continuous_re.comp Complex.continuous_of_real.cexp

theorem continuous_on_exp {s : Set ℝ} : ContinuousOn exp s :=
  continuous_exp.ContinuousOn

end Real

section RealContinuousExpComp

variable {α : Type _}

open Real

theorem Filter.Tendsto.exp {l : Filter α} {f : α → ℝ} {z : ℝ} (hf : tendsto f l (𝓝 z)) :
    tendsto (fun x => exp (f x)) l (𝓝 (exp z)) :=
  (continuous_exp.Tendsto _).comp hf

variable [TopologicalSpace α] {f : α → ℝ} {s : Set α} {x : α}

theorem ContinuousWithinAt.exp (h : ContinuousWithinAt f s x) : ContinuousWithinAt (fun y => exp (f y)) s x :=
  h.exp

theorem ContinuousAt.exp (h : ContinuousAt f x) : ContinuousAt (fun y => exp (f y)) x :=
  h.exp

theorem ContinuousOn.exp (h : ContinuousOn f s) : ContinuousOn (fun y => exp (f y)) s := fun x hx => (h x hx).exp

theorem Continuous.exp (h : Continuous f) : Continuous fun y => exp (f y) :=
  continuous_iff_continuous_at.2 $ fun x => h.continuous_at.exp

end RealContinuousExpComp

namespace Real

variable {x y z : ℝ}

/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize.input] (Command.declaration
 (Command.declModifiers
  [(Command.docComment "/--" " The real exponential function tends to `+∞` at `+∞`. -/")]
  []
  []
  []
  []
  [])
 (Command.theorem
  "theorem"
  (Command.declId `tendsto_exp_at_top [])
  (Command.declSig [] (Term.typeSpec ":" (Term.app `tendsto [`exp `at_top `at_top])))
  (Command.declValSimple
   ":="
   (Term.byTactic
    "by"
    (Tactic.tacticSeq
     (Tactic.tacticSeq1Indented
      [(group
        (Tactic.tacticHave_
         "have"
         (Term.haveDecl
          (Term.haveIdDecl
           [`A []]
           [(Term.typeSpec
             ":"
             (Term.app
              `tendsto
              [(Term.fun
                "fun"
                (Term.basicFun
                 [(Term.simpleBinder [`x] [(Term.typeSpec ":" (Data.Real.Basic.termℝ "ℝ"))])]
                 "=>"
                 (Init.Logic.«term_+_» `x "+" (numLit "1"))))
               `at_top
               `at_top]))]
           ":="
           (Term.app `tendsto_at_top_add_const_right [`at_top (numLit "1") `tendsto_id]))))
        [])
       (group
        (Tactic.tacticHave_
         "have"
         (Term.haveDecl
          (Term.haveIdDecl
           [`B []]
           [(Term.typeSpec
             ":"
             (Filter.Order.Filter.Basic.«term∀ᶠ_in_,_»
              "∀ᶠ"
              (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `x)] []))
              " in "
              `at_top
              ", "
              («term_≤_» (Init.Logic.«term_+_» `x "+" (numLit "1")) "≤" (Term.app `exp [`x]))))]
           ":="
           (Term.app
            (Term.proj `eventually_at_top "." (fieldIdx "2"))
            [(Term.anonymousCtor
              "⟨"
              [(numLit "0")
               ","
               (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))]
              "⟩")]))))
        [])
       (group (Tactic.exact "exact" (Term.app `tendsto_at_top_mono' [`at_top `B `A])) [])])))
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
  (Term.byTactic
   "by"
   (Tactic.tacticSeq
    (Tactic.tacticSeq1Indented
     [(group
       (Tactic.tacticHave_
        "have"
        (Term.haveDecl
         (Term.haveIdDecl
          [`A []]
          [(Term.typeSpec
            ":"
            (Term.app
             `tendsto
             [(Term.fun
               "fun"
               (Term.basicFun
                [(Term.simpleBinder [`x] [(Term.typeSpec ":" (Data.Real.Basic.termℝ "ℝ"))])]
                "=>"
                (Init.Logic.«term_+_» `x "+" (numLit "1"))))
              `at_top
              `at_top]))]
          ":="
          (Term.app `tendsto_at_top_add_const_right [`at_top (numLit "1") `tendsto_id]))))
       [])
      (group
       (Tactic.tacticHave_
        "have"
        (Term.haveDecl
         (Term.haveIdDecl
          [`B []]
          [(Term.typeSpec
            ":"
            (Filter.Order.Filter.Basic.«term∀ᶠ_in_,_»
             "∀ᶠ"
             (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `x)] []))
             " in "
             `at_top
             ", "
             («term_≤_» (Init.Logic.«term_+_» `x "+" (numLit "1")) "≤" (Term.app `exp [`x]))))]
          ":="
          (Term.app
           (Term.proj `eventually_at_top "." (fieldIdx "2"))
           [(Term.anonymousCtor
             "⟨"
             [(numLit "0")
              ","
              (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))]
             "⟩")]))))
       [])
      (group (Tactic.exact "exact" (Term.app `tendsto_at_top_mono' [`at_top `B `A])) [])])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'Lean.Parser.Term.byTactic.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq', expected 'Lean.Parser.Tactic.tacticSeq.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeq1Indented.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Tactic.exact "exact" (Term.app `tendsto_at_top_mono' [`at_top `B `A]))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.exact', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `tendsto_at_top_mono' [`at_top `B `A])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `A
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1024, term))
  `B
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (some 1024, term)
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1024, term))
  `at_top
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (some 1024, term)
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `tendsto_at_top_mono'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, tactic))
  (Tactic.tacticHave_
   "have"
   (Term.haveDecl
    (Term.haveIdDecl
     [`B []]
     [(Term.typeSpec
       ":"
       (Filter.Order.Filter.Basic.«term∀ᶠ_in_,_»
        "∀ᶠ"
        (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `x)] []))
        " in "
        `at_top
        ", "
        («term_≤_» (Init.Logic.«term_+_» `x "+" (numLit "1")) "≤" (Term.app `exp [`x]))))]
     ":="
     (Term.app
      (Term.proj `eventually_at_top "." (fieldIdx "2"))
      [(Term.anonymousCtor
        "⟨"
        [(numLit "0")
         ","
         (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))]
        "⟩")]))))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticHave_', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveDecl', expected 'Lean.Parser.Term.haveDecl.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveIdDecl', expected 'Lean.Parser.Term.haveIdDecl.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app
   (Term.proj `eventually_at_top "." (fieldIdx "2"))
   [(Term.anonymousCtor
     "⟨"
     [(numLit "0")
      ","
      (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))]
     "⟩")])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.anonymousCtor
   "⟨"
   [(numLit "0")
    ","
    (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))]
   "⟩")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.anonymousCtor.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'sepBy.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`x `hx] [])] "=>" (Term.app `add_one_le_exp [`x])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'Lean.Parser.Term.fun.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.basicFun', expected 'Lean.Parser.Term.basicFun.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `add_one_le_exp [`x])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `x
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `add_one_le_exp
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.strictImplicitBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.strictImplicitBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.implicitBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.implicitBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.instBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.instBinder'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.simpleBinder', expected 'Lean.Parser.Term.simpleBinder.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (some 0, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'sepBy.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (numLit "0")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'numLit.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  (Term.proj `eventually_at_top "." (fieldIdx "2"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.proj', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1024, term))
  `eventually_at_top
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (some 1024, term)
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.typeSpec', expected 'optional.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.typeSpec', expected 'Lean.Parser.Term.typeSpec.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Filter.Order.Filter.Basic.«term∀ᶠ_in_,_»
   "∀ᶠ"
   (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `x)] []))
   " in "
   `at_top
   ", "
   («term_≤_» (Init.Logic.«term_+_» `x "+" (numLit "1")) "≤" (Term.app `exp [`x])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Filter.Order.Filter.Basic.«term∀ᶠ_in_,_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  («term_≤_» (Init.Logic.«term_+_» `x "+" (numLit "1")) "≤" (Term.app `exp [`x]))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«term_≤_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `exp [`x])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `x
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `exp
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 51 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 50, term))
  (Init.Logic.«term_+_» `x "+" (numLit "1"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Init.Logic.«term_+_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (numLit "1")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'numLit', expected 'numLit.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `x
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 51 >? 1022, (some 0, term) <=? (some 50, term)
[PrettyPrinter.parenthesize] parenthesized: (Term.paren "(" [(Init.Logic.«term_+_» `x "+" (numLit "1")) []] ")")
[PrettyPrinter.parenthesize] ...precedences are 0 >? 50, (some 51, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `at_top
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.explicitBinders', expected 'Mathlib.ExtendedBinder.extBinders'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveIdDecl', expected 'Lean.Parser.Term.letPatDecl.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveIdDecl', expected 'Lean.Parser.Term.letPatDecl'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveIdDecl', expected 'Lean.Parser.Term.haveEqnsDecl.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.haveIdDecl', expected 'Lean.Parser.Term.haveEqnsDecl'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValEqns.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.declValEqns'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.whereStructInst.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Command.declValSimple', expected 'Lean.Parser.Command.whereStructInst'
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
/-- The real exponential function tends to `+∞` at `+∞`. -/
  theorem
    tendsto_exp_at_top
    : tendsto exp at_top at_top
    :=
      by
        have A : tendsto fun x : ℝ => x + 1 at_top at_top := tendsto_at_top_add_const_right at_top 1 tendsto_id
          have B : ∀ᶠ x in at_top , x + 1 ≤ exp x := eventually_at_top . 2 ⟨ 0 , fun x hx => add_one_le_exp x ⟩
          exact tendsto_at_top_mono' at_top B A

/--  The real exponential function tends to `0` at `-∞` or, equivalently, `exp(-x)` tends to `0`
at `+∞` -/
theorem tendsto_exp_neg_at_top_nhds_0 : tendsto (fun x => exp (-x)) at_top (𝓝 0) :=
  (tendsto_inv_at_top_zero.comp tendsto_exp_at_top).congr fun x => (exp_neg x).symm

/--  The real exponential function tends to `1` at `0`. -/
theorem tendsto_exp_nhds_0_nhds_1 : tendsto exp (𝓝 0) (𝓝 1) := by
  convert continuous_exp.tendsto 0
  simp

theorem tendsto_exp_at_bot : tendsto exp at_bot (𝓝 0) :=
  (tendsto_exp_neg_at_top_nhds_0.comp tendsto_neg_at_bot_at_top).congr $ fun x => congr_argₓ exp $ neg_negₓ x

theorem tendsto_exp_at_bot_nhds_within : tendsto exp at_bot (𝓝[>] 0) :=
  tendsto_inf.2 ⟨tendsto_exp_at_bot, tendsto_principal.2 $ eventually_of_forall exp_pos⟩

/--  The function `exp(x)/x^n` tends to `+∞` at `+∞`, for any natural number `n` -/
theorem tendsto_exp_div_pow_at_top (n : ℕ) : tendsto (fun x => exp x / (x^n)) at_top at_top := by
  refine' (at_top_basis_Ioi.tendsto_iff (at_top_basis' 1)).2 fun C hC₁ => _
  have hC₀ : 0 < C
  exact zero_lt_one.trans_le hC₁
  have : 0 < (exp 1*C)⁻¹ := inv_pos.2 (mul_pos (exp_pos _) hC₀)
  obtain ⟨N, hN⟩ : ∃ N, ∀, ∀ k ≥ N, ∀, (↑k^n : ℝ) / (exp 1^k) < (exp 1*C)⁻¹ :=
    eventually_at_top.1
      ((tendsto_pow_const_div_const_pow_of_one_lt n (one_lt_exp_iff.2 zero_lt_one)).Eventually (gt_mem_nhds this))
  simp only [← exp_nat_mul, mul_oneₓ, div_lt_iff, exp_pos, ← div_eq_inv_mul] at hN
  refine' ⟨N, trivialₓ, fun x hx => _⟩
  rw [Set.mem_Ioi] at hx
  have hx₀ : 0 < x
  exact N.cast_nonneg.trans_lt hx
  rw [Set.mem_Ici, le_div_iff (pow_pos hx₀ _), ← le_div_iff' hC₀]
  calc (x^n) ≤ (⌈x⌉₊^n) := pow_le_pow_of_le_left hx₀.le (Nat.le_ceil _) _ _ ≤ exp ⌈x⌉₊ / exp 1*C :=
    (hN _ (Nat.lt_ceil.2 hx).le).le _ ≤ exp (x+1) / exp 1*C :=
    div_le_div_of_le (mul_pos (exp_pos _) hC₀).le (exp_le_exp.2 $ (Nat.ceil_lt_add_one hx₀.le).le)_ = exp x / C := by
    rw [add_commₓ, exp_add, mul_div_mul_left _ _ (exp_pos _).ne']

/--  The function `x^n * exp(-x)` tends to `0` at `+∞`, for any natural number `n`. -/
theorem tendsto_pow_mul_exp_neg_at_top_nhds_0 (n : ℕ) : tendsto (fun x => (x^n)*exp (-x)) at_top (𝓝 0) :=
  (tendsto_inv_at_top_zero.comp (tendsto_exp_div_pow_at_top n)).congr $ fun x => by
    rw [comp_app, inv_eq_one_div, div_div_eq_mul_div, one_mulₓ, div_eq_mul_inv, exp_neg]

/--  The function `(b * exp x + c) / (x ^ n)` tends to `+∞` at `+∞`, for any positive natural number
`n` and any real numbers `b` and `c` such that `b` is positive. -/
theorem tendsto_mul_exp_add_div_pow_at_top (b c : ℝ) (n : ℕ) (hb : 0 < b) (hn : 1 ≤ n) :
    tendsto (fun x => ((b*exp x)+c) / (x^n)) at_top at_top := by
  refine'
    tendsto.congr' (eventually_eq_of_mem (Ioi_mem_at_top 0) _)
      (((tendsto_exp_div_pow_at_top n).const_mul_at_top hb).at_top_add
        ((tendsto_pow_neg_at_top hn).mul (@tendsto_const_nhds _ _ _ c _)))
  intro x hx
  simp only [zpow_neg₀ x n]
  ring

/--  The function `(x ^ n) / (b * exp x + c)` tends to `0` at `+∞`, for any positive natural number
`n` and any real numbers `b` and `c` such that `b` is nonzero. -/
theorem tendsto_div_pow_mul_exp_add_at_top (b c : ℝ) (n : ℕ) (hb : 0 ≠ b) (hn : 1 ≤ n) :
    tendsto (fun x => (x^n) / (b*exp x)+c) at_top (𝓝 0) := by
  have H : ∀ d e, 0 < d → tendsto (fun x : ℝ => (x^n) / (d*exp x)+e) at_top (𝓝 0) := by
    intro b' c' h
    convert (tendsto_mul_exp_add_div_pow_at_top b' c' n h hn).inv_tendsto_at_top
    ext x
    simpa only [Pi.inv_apply] using inv_div.symm
  cases lt_or_gt_of_neₓ hb
  ·
    exact H b c h
  ·
    convert (H (-b) (-c) (neg_pos.mpr h)).neg
    ·
      ext x
      field_simp
      rw [← neg_add (b*exp x) c, neg_div_neg_eq]
    ·
      exact neg_zero.symm

/--  `real.exp` as an order isomorphism between `ℝ` and `(0, +∞)`. -/
def exp_order_iso : ℝ ≃o Ioi (0 : ℝ) :=
  StrictMono.orderIsoOfSurjective _ (exp_strict_mono.codRestrict exp_pos) $
    (continuous_subtype_mk _ continuous_exp).Surjective
      (by
        simp only [tendsto_Ioi_at_top, Subtype.coe_mk, tendsto_exp_at_top])
      (by
        simp [tendsto_exp_at_bot_nhds_within])

@[simp]
theorem coe_exp_order_iso_apply (x : ℝ) : (exp_order_iso x : ℝ) = exp x :=
  rfl

@[simp]
theorem coe_comp_exp_order_iso : (coeₓ ∘ exp_order_iso) = exp :=
  rfl

@[simp]
theorem range_exp : range exp = Ioi 0 := by
  rw [← coe_comp_exp_order_iso, range_comp, exp_order_iso.range_eq, image_univ, Subtype.range_coe]

@[simp]
theorem map_exp_at_top : map exp at_top = at_top := by
  rw [← coe_comp_exp_order_iso, ← Filter.map_map, OrderIso.map_at_top, map_coe_Ioi_at_top]

@[simp]
theorem comap_exp_at_top : comap exp at_top = at_top := by
  rw [← map_exp_at_top, comap_map exp_injective, map_exp_at_top]

@[simp]
theorem tendsto_exp_comp_at_top {α : Type _} {l : Filter α} {f : α → ℝ} :
    tendsto (fun x => exp (f x)) l at_top ↔ tendsto f l at_top := by
  rw [← tendsto_comap_iff, comap_exp_at_top]

theorem tendsto_comp_exp_at_top {α : Type _} {l : Filter α} {f : ℝ → α} :
    tendsto (fun x => f (exp x)) at_top l ↔ tendsto f at_top l := by
  rw [← tendsto_map'_iff, map_exp_at_top]

@[simp]
theorem map_exp_at_bot : map exp at_bot = 𝓝[>] 0 := by
  rw [← coe_comp_exp_order_iso, ← Filter.map_map, exp_order_iso.map_at_bot, ← map_coe_Ioi_at_bot]

theorem comap_exp_nhds_within_Ioi_zero : comap exp (𝓝[>] 0) = at_bot := by
  rw [← map_exp_at_bot, comap_map exp_injective]

theorem tendsto_comp_exp_at_bot {α : Type _} {l : Filter α} {f : ℝ → α} :
    tendsto (fun x => f (exp x)) at_bot l ↔ tendsto f (𝓝[>] 0) l := by
  rw [← map_exp_at_bot, tendsto_map'_iff]

end Real

