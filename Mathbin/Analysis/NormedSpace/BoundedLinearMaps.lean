import Mathbin.Analysis.NormedSpace.Multilinear
import Mathbin.Analysis.NormedSpace.Units
import Mathbin.Analysis.Asymptotics.Asymptotics

/-!
# Bounded linear maps

This file defines a class stating that a map between normed vector spaces is (bi)linear and
continuous.
Instead of asking for continuity, the definition takes the equivalent condition (because the space
is normed) that `∥f x∥` is bounded by a multiple of `∥x∥`. Hence the "bounded" in the name refers to
`∥f x∥/∥x∥` rather than `∥f x∥` itself.

## Main definitions

* `is_bounded_linear_map`: Class stating that a map `f : E → F` is linear and has `∥f x∥` bounded
  by a multiple of `∥x∥`.
* `is_bounded_bilinear_map`: Class stating that a map `f : E × F → G` is bilinear and continuous,
  but through the simpler to provide statement that `∥f (x, y)∥` is bounded by a multiple of
  `∥x∥ * ∥y∥`
* `is_bounded_bilinear_map.linear_deriv`: Derivative of a continuous bilinear map as a linear map.
* `is_bounded_bilinear_map.deriv`: Derivative of a continuous bilinear map as a continuous linear
  map. The proof that it is indeed the derivative is `is_bounded_bilinear_map.has_fderiv_at` in
  `analysis.calculus.fderiv`.

## Main theorems

* `is_bounded_bilinear_map.continuous`: A bounded bilinear map is continuous.
* `continuous_linear_equiv.is_open`: The continuous linear equivalences are an open subset of the
  set of continuous linear maps between a pair of Banach spaces.  Placed in this file because its
  proof uses `is_bounded_bilinear_map.continuous`.

## Notes

The main use of this file is `is_bounded_bilinear_map`. The file `analysis.normed_space.multilinear`
already expounds the theory of multilinear maps, but the `2`-variables case is sufficiently simpler
to currently deserve its own treatment.

`is_bounded_linear_map` is effectively an unbundled version of `continuous_linear_map` (defined
in `topology.algebra.module`, theory over normed spaces developed in
`analysis.normed_space.operator_norm`), albeit the name disparity. A bundled
`continuous_linear_map` is to be preferred over a `is_bounded_linear_map` hypothesis. Historical
artifact, really.
-/


noncomputable section

open_locale Classical BigOperators TopologicalSpace

open filter (Tendsto)

open Metric

variable {𝕜 : Type _} [NondiscreteNormedField 𝕜] {E : Type _} [NormedGroup E] [NormedSpace 𝕜 E] {F : Type _}
  [NormedGroup F] [NormedSpace 𝕜 F] {G : Type _} [NormedGroup G] [NormedSpace 𝕜 G]

/--  A function `f` satisfies `is_bounded_linear_map 𝕜 f` if it is linear and satisfies the
inequality `∥f x∥ ≤ M * ∥x∥` for some positive constant `M`. -/
structure IsBoundedLinearMap (𝕜 : Type _) [NormedField 𝕜] {E : Type _} [NormedGroup E] [NormedSpace 𝕜 E] {F : Type _}
  [NormedGroup F] [NormedSpace 𝕜 F] (f : E → F) extends IsLinearMap 𝕜 f : Prop where
  bound : ∃ M, 0 < M ∧ ∀ x : E, ∥f x∥ ≤ M*∥x∥

theorem IsLinearMap.with_bound {f : E → F} (hf : IsLinearMap 𝕜 f) (M : ℝ) (h : ∀ x : E, ∥f x∥ ≤ M*∥x∥) :
    IsBoundedLinearMap 𝕜 f :=
  ⟨hf,
    Classical.by_cases
      (fun this : M ≤ 0 =>
        ⟨1, zero_lt_one, fun x => (h x).trans $ mul_le_mul_of_nonneg_right (this.trans zero_le_one) (norm_nonneg x)⟩)
      fun this : ¬M ≤ 0 => ⟨M, lt_of_not_geₓ this, h⟩⟩

/--  A continuous linear map satisfies `is_bounded_linear_map` -/
theorem ContinuousLinearMap.is_bounded_linear_map (f : E →L[𝕜] F) : IsBoundedLinearMap 𝕜 f :=
  { f.to_linear_map.is_linear with bound := f.bound }

namespace IsBoundedLinearMap

/--  Construct a linear map from a function `f` satisfying `is_bounded_linear_map 𝕜 f`. -/
def to_linear_map (f : E → F) (h : IsBoundedLinearMap 𝕜 f) : E →ₗ[𝕜] F :=
  IsLinearMap.mk' _ h.to_is_linear_map

/--  Construct a continuous linear map from is_bounded_linear_map -/
def to_continuous_linear_map {f : E → F} (hf : IsBoundedLinearMap 𝕜 f) : E →L[𝕜] F :=
  { to_linear_map f hf with
    cont :=
      let ⟨C, Cpos, hC⟩ := hf.bound
      (to_linear_map f hf).continuous_of_bound C hC }

theorem zero : IsBoundedLinearMap 𝕜 fun x : E => (0 : F) :=
  (0 : E →ₗ[𝕜] F).is_linear.with_bound 0 $ by
    simp [le_reflₓ]

theorem id : IsBoundedLinearMap 𝕜 fun x : E => x :=
  LinearMap.id.is_linear.with_bound 1 $ by
    simp [le_reflₓ]

theorem fst : IsBoundedLinearMap 𝕜 fun x : E × F => x.1 := by
  refine' (LinearMap.fst 𝕜 E F).is_linear.with_bound 1 fun x => _
  rw [one_mulₓ]
  exact le_max_leftₓ _ _

theorem snd : IsBoundedLinearMap 𝕜 fun x : E × F => x.2 := by
  refine' (LinearMap.snd 𝕜 E F).is_linear.with_bound 1 fun x => _
  rw [one_mulₓ]
  exact le_max_rightₓ _ _

variable {f g : E → F}

theorem smul (c : 𝕜) (hf : IsBoundedLinearMap 𝕜 f) : IsBoundedLinearMap 𝕜 (c • f) :=
  let ⟨hlf, M, hMp, hM⟩ := hf
  (c • hlf.mk' f).is_linear.with_bound (∥c∥*M) $ fun x =>
    calc ∥c • f x∥ = ∥c∥*∥f x∥ := norm_smul c (f x)
      _ ≤ ∥c∥*M*∥x∥ := mul_le_mul_of_nonneg_left (hM _) (norm_nonneg _)
      _ = (∥c∥*M)*∥x∥ := (mul_assocₓ _ _ _).symm
      

theorem neg (hf : IsBoundedLinearMap 𝕜 f) : IsBoundedLinearMap 𝕜 fun e => -f e := by
  rw
    [show (fun e => -f e) = fun e => (-1 : 𝕜) • f e by
      funext
      simp ]
  exact smul (-1) hf

theorem add (hf : IsBoundedLinearMap 𝕜 f) (hg : IsBoundedLinearMap 𝕜 g) : IsBoundedLinearMap 𝕜 fun e => f e+g e :=
  let ⟨hlf, Mf, hMfp, hMf⟩ := hf
  let ⟨hlg, Mg, hMgp, hMg⟩ := hg
  (hlf.mk' _+hlg.mk' _).is_linear.with_bound (Mf+Mg) $ fun x =>
    calc ∥f x+g x∥ ≤ (Mf*∥x∥)+Mg*∥x∥ := norm_add_le_of_le (hMf x) (hMg x)
      _ ≤ (Mf+Mg)*∥x∥ := by
      rw [add_mulₓ]
      

theorem sub (hf : IsBoundedLinearMap 𝕜 f) (hg : IsBoundedLinearMap 𝕜 g) : IsBoundedLinearMap 𝕜 fun e => f e - g e := by
  simpa [sub_eq_add_neg] using add hf (neg hg)

theorem comp {g : F → G} (hg : IsBoundedLinearMap 𝕜 g) (hf : IsBoundedLinearMap 𝕜 f) : IsBoundedLinearMap 𝕜 (g ∘ f) :=
  (hg.to_continuous_linear_map.comp hf.to_continuous_linear_map).IsBoundedLinearMap

protected theorem tendsto (x : E) (hf : IsBoundedLinearMap 𝕜 f) : tendsto f (𝓝 x) (𝓝 (f x)) :=
  let ⟨hf, M, hMp, hM⟩ := hf
  tendsto_iff_norm_tendsto_zero.2 $
    squeeze_zero (fun e => norm_nonneg _)
      (fun e =>
        calc ∥f e - f x∥ = ∥hf.mk' f (e - x)∥ := by
          rw [(hf.mk' _).map_sub e x] <;> rfl
          _ ≤ M*∥e - x∥ := hM (e - x)
          )
      (suffices tendsto (fun e : E => M*∥e - x∥) (𝓝 x) (𝓝 (M*0))by
        simpa
      tendsto_const_nhds.mul (tendsto_norm_sub_self _))

theorem Continuous (hf : IsBoundedLinearMap 𝕜 f) : Continuous f :=
  continuous_iff_continuous_at.2 $ fun _ => hf.tendsto _

theorem lim_zero_bounded_linear_map (hf : IsBoundedLinearMap 𝕜 f) : tendsto f (𝓝 0) (𝓝 0) :=
  (hf.1.mk' _).map_zero ▸ continuous_iff_continuous_at.1 hf.continuous 0

section

open Asymptotics Filter

theorem is_O_id {f : E → F} (h : IsBoundedLinearMap 𝕜 f) (l : Filter E) : is_O f (fun x => x) l :=
  let ⟨M, hMp, hM⟩ := h.bound
  is_O.of_bound _ (mem_of_superset univ_mem fun x _ => hM x)

theorem is_O_comp {E : Type _} {g : F → G} (hg : IsBoundedLinearMap 𝕜 g) {f : E → F} (l : Filter E) :
    is_O (fun x' => g (f x')) f l :=
  (hg.is_O_id ⊤).comp_tendsto le_top

theorem is_O_sub {f : E → F} (h : IsBoundedLinearMap 𝕜 f) (l : Filter E) (x : E) :
    is_O (fun x' => f (x' - x)) (fun x' => x' - x) l :=
  is_O_comp h l

end

end IsBoundedLinearMap

section

variable {ι : Type _} [DecidableEq ι] [Fintype ι]

/--  Taking the cartesian product of two continuous multilinear maps
is a bounded linear operation. -/
theorem is_bounded_linear_map_prod_multilinear {E : ι → Type _} [∀ i, NormedGroup (E i)] [∀ i, NormedSpace 𝕜 (E i)] :
    IsBoundedLinearMap 𝕜 fun p : ContinuousMultilinearMap 𝕜 E F × ContinuousMultilinearMap 𝕜 E G => p.1.Prod p.2 :=
  { map_add := fun p₁ p₂ => by
      ext1 m
      rfl,
    map_smul := fun c p => by
      ext1 m
      rfl,
    bound :=
      ⟨1, zero_lt_one, fun p => by
        rw [one_mulₓ]
        apply ContinuousMultilinearMap.op_norm_le_bound _ (norm_nonneg _) fun m => _
        rw [ContinuousMultilinearMap.prod_apply, norm_prod_le_iff]
        constructor
        ·
          exact
            (p.1.le_op_norm m).trans
              (mul_le_mul_of_nonneg_right (norm_fst_le p) (Finset.prod_nonneg fun i hi => norm_nonneg _))
        ·
          exact
            (p.2.le_op_norm m).trans
              (mul_le_mul_of_nonneg_right (norm_snd_le p) (Finset.prod_nonneg fun i hi => norm_nonneg _))⟩ }

/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize.input] (Command.declaration
 (Command.declModifiers
  [(Command.docComment
    "/--"
    " Given a fixed continuous linear map `g`, associating to a continuous multilinear map `f` the\ncontinuous multilinear map `f (g m₁, ..., g mₙ)` is a bounded linear operation. -/")]
  []
  []
  []
  []
  [])
 (Command.theorem
  "theorem"
  (Command.declId `is_bounded_linear_map_continuous_multilinear_map_comp_linear [])
  (Command.declSig
   [(Term.explicitBinder "(" [`g] [":" (Topology.Algebra.Module.«term_→L[_]_» `G " →L[" `𝕜 "] " `E)] [] ")")]
   (Term.typeSpec
    ":"
    (Term.app
     `IsBoundedLinearMap
     [`𝕜
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder
          [`f]
          [(Term.typeSpec
            ":"
            (Term.app
             `ContinuousMultilinearMap
             [`𝕜 (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`i] [(Term.typeSpec ":" `ι)])] "=>" `E)) `F]))])]
        "=>"
        (Term.app
         `f.comp_continuous_linear_map
         [(Term.fun "fun" (Term.basicFun [(Term.simpleBinder [(Term.hole "_")] [])] "=>" `g))])))])))
  (Command.declValSimple
   ":="
   (Term.byTactic
    "by"
    (Tactic.tacticSeq
     (Tactic.tacticSeq1Indented
      [(group
        (Tactic.refine'
         "refine'"
         (Term.app
          `IsLinearMap.with_bound
          [(Term.anonymousCtor
            "⟨"
            [(Term.fun
              "fun"
              (Term.basicFun
               [(Term.simpleBinder [`f₁ `f₂] [])]
               "=>"
               (Term.byTactic
                "by"
                (Tactic.tacticSeq
                 (Tactic.tacticSeq1Indented
                  [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
                   (group (Tactic.tacticRfl "rfl") [])])))))
             ","
             (Term.fun
              "fun"
              (Term.basicFun
               [(Term.simpleBinder [`c `f] [])]
               "=>"
               (Term.byTactic
                "by"
                (Tactic.tacticSeq
                 (Tactic.tacticSeq1Indented
                  [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
                   (group (Tactic.tacticRfl "rfl") [])])))))]
            "⟩")
           («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
           (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`f] [])] "=>" (Term.hole "_")))]))
        [])
       (group
        (Tactic.apply
         "apply"
         (Term.app
          `ContinuousMultilinearMap.op_norm_le_bound
          [(Term.hole "_")
           (Term.hole "_")
           (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
        [])
       (group
        (Tactic.«tactic·._»
         "·"
         (Tactic.tacticSeq
          (Tactic.tacticSeq1Indented
           [(group
             (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `pow_nonneg "," `norm_nonneg] "]" [])
             [])])))
        [])
       (group
        (tacticCalc_
         "calc"
         [(calcStep
           («term_≤_»
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [(Rel.Data.Rel.«term_∘_» `g " ∘ " `m)]) "∥")
            "≤"
            (Finset.Data.Finset.Fold.«term_*_»
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
             "*"
             (Algebra.BigOperators.Basic.«term∏_,_»
              "∏"
              (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
              ", "
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `m [`i])]) "∥"))))
           ":="
           (Term.app `f.le_op_norm [(Term.hole "_")]))
          (calcStep
           («term_≤_»
            (Term.hole "_")
            "≤"
            (Finset.Data.Finset.Fold.«term_*_»
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
             "*"
             (Algebra.BigOperators.Basic.«term∏_,_»
              "∏"
              (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
              ", "
              (Finset.Data.Finset.Fold.«term_*_»
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
               "*"
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
           ":="
           (Term.byTactic
            "by"
            (Tactic.tacticSeq
             (Tactic.tacticSeq1Indented
              [(group
                (Tactic.apply
                 "apply"
                 (Term.app `mul_le_mul_of_nonneg_left [(Term.hole "_") (Term.app `norm_nonneg [(Term.hole "_")])]))
                [])
               (group
                (Tactic.exact
                 "exact"
                 (Term.app
                  `Finset.prod_le_prod
                  [(Term.fun
                    "fun"
                    (Term.basicFun [(Term.simpleBinder [`i `hi] [])] "=>" (Term.app `norm_nonneg [(Term.hole "_")])))
                   (Term.fun
                    "fun"
                    (Term.basicFun
                     [(Term.simpleBinder [`i `hi] [])]
                     "=>"
                     (Term.app `g.le_op_norm [(Term.hole "_")])))]))
                [])]))))
          (calcStep
           («term_=_»
            (Term.hole "_")
            "="
            (Finset.Data.Finset.Fold.«term_*_»
             (Finset.Data.Finset.Fold.«term_*_»
              («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
              "*"
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
             "*"
             (Algebra.BigOperators.Basic.«term∏_,_»
              "∏"
              (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
              ", "
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
           ":="
           (Term.byTactic
            "by"
            (Tactic.tacticSeq
             (Tactic.tacticSeq1Indented
              [(group
                (Tactic.simp
                 "simp"
                 []
                 []
                 ["["
                  [(Tactic.simpLemma [] [] `Finset.prod_mul_distrib) "," (Tactic.simpLemma [] [] `Finset.card_univ)]
                  "]"]
                 [])
                [])
               (group (Tactic.Ring.tacticRing "ring") [])]))))])
        [])])))
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
       (Tactic.refine'
        "refine'"
        (Term.app
         `IsLinearMap.with_bound
         [(Term.anonymousCtor
           "⟨"
           [(Term.fun
             "fun"
             (Term.basicFun
              [(Term.simpleBinder [`f₁ `f₂] [])]
              "=>"
              (Term.byTactic
               "by"
               (Tactic.tacticSeq
                (Tactic.tacticSeq1Indented
                 [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) []) (group (Tactic.tacticRfl "rfl") [])])))))
            ","
            (Term.fun
             "fun"
             (Term.basicFun
              [(Term.simpleBinder [`c `f] [])]
              "=>"
              (Term.byTactic
               "by"
               (Tactic.tacticSeq
                (Tactic.tacticSeq1Indented
                 [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
                  (group (Tactic.tacticRfl "rfl") [])])))))]
           "⟩")
          («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
          (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`f] [])] "=>" (Term.hole "_")))]))
       [])
      (group
       (Tactic.apply
        "apply"
        (Term.app
         `ContinuousMultilinearMap.op_norm_le_bound
         [(Term.hole "_")
          (Term.hole "_")
          (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
       [])
      (group
       (Tactic.«tactic·._»
        "·"
        (Tactic.tacticSeq
         (Tactic.tacticSeq1Indented
          [(group (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `pow_nonneg "," `norm_nonneg] "]" []) [])])))
       [])
      (group
       (tacticCalc_
        "calc"
        [(calcStep
          («term_≤_»
           (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [(Rel.Data.Rel.«term_∘_» `g " ∘ " `m)]) "∥")
           "≤"
           (Finset.Data.Finset.Fold.«term_*_»
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
            "*"
            (Algebra.BigOperators.Basic.«term∏_,_»
             "∏"
             (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
             ", "
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `m [`i])]) "∥"))))
          ":="
          (Term.app `f.le_op_norm [(Term.hole "_")]))
         (calcStep
          («term_≤_»
           (Term.hole "_")
           "≤"
           (Finset.Data.Finset.Fold.«term_*_»
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
            "*"
            (Algebra.BigOperators.Basic.«term∏_,_»
             "∏"
             (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
             ", "
             (Finset.Data.Finset.Fold.«term_*_»
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
              "*"
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
          ":="
          (Term.byTactic
           "by"
           (Tactic.tacticSeq
            (Tactic.tacticSeq1Indented
             [(group
               (Tactic.apply
                "apply"
                (Term.app `mul_le_mul_of_nonneg_left [(Term.hole "_") (Term.app `norm_nonneg [(Term.hole "_")])]))
               [])
              (group
               (Tactic.exact
                "exact"
                (Term.app
                 `Finset.prod_le_prod
                 [(Term.fun
                   "fun"
                   (Term.basicFun [(Term.simpleBinder [`i `hi] [])] "=>" (Term.app `norm_nonneg [(Term.hole "_")])))
                  (Term.fun
                   "fun"
                   (Term.basicFun [(Term.simpleBinder [`i `hi] [])] "=>" (Term.app `g.le_op_norm [(Term.hole "_")])))]))
               [])]))))
         (calcStep
          («term_=_»
           (Term.hole "_")
           "="
           (Finset.Data.Finset.Fold.«term_*_»
            (Finset.Data.Finset.Fold.«term_*_»
             («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
             "*"
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
            "*"
            (Algebra.BigOperators.Basic.«term∏_,_»
             "∏"
             (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
             ", "
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
          ":="
          (Term.byTactic
           "by"
           (Tactic.tacticSeq
            (Tactic.tacticSeq1Indented
             [(group
               (Tactic.simp
                "simp"
                []
                []
                ["["
                 [(Tactic.simpLemma [] [] `Finset.prod_mul_distrib) "," (Tactic.simpLemma [] [] `Finset.card_univ)]
                 "]"]
                [])
               [])
              (group (Tactic.Ring.tacticRing "ring") [])]))))])
       [])])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'Lean.Parser.Term.byTactic.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq', expected 'Lean.Parser.Tactic.tacticSeq.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeq1Indented.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (tacticCalc_
   "calc"
   [(calcStep
     («term_≤_»
      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [(Rel.Data.Rel.«term_∘_» `g " ∘ " `m)]) "∥")
      "≤"
      (Finset.Data.Finset.Fold.«term_*_»
       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
       "*"
       (Algebra.BigOperators.Basic.«term∏_,_»
        "∏"
        (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
        ", "
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `m [`i])]) "∥"))))
     ":="
     (Term.app `f.le_op_norm [(Term.hole "_")]))
    (calcStep
     («term_≤_»
      (Term.hole "_")
      "≤"
      (Finset.Data.Finset.Fold.«term_*_»
       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
       "*"
       (Algebra.BigOperators.Basic.«term∏_,_»
        "∏"
        (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
        ", "
        (Finset.Data.Finset.Fold.«term_*_»
         (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
         "*"
         (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
     ":="
     (Term.byTactic
      "by"
      (Tactic.tacticSeq
       (Tactic.tacticSeq1Indented
        [(group
          (Tactic.apply
           "apply"
           (Term.app `mul_le_mul_of_nonneg_left [(Term.hole "_") (Term.app `norm_nonneg [(Term.hole "_")])]))
          [])
         (group
          (Tactic.exact
           "exact"
           (Term.app
            `Finset.prod_le_prod
            [(Term.fun
              "fun"
              (Term.basicFun [(Term.simpleBinder [`i `hi] [])] "=>" (Term.app `norm_nonneg [(Term.hole "_")])))
             (Term.fun
              "fun"
              (Term.basicFun [(Term.simpleBinder [`i `hi] [])] "=>" (Term.app `g.le_op_norm [(Term.hole "_")])))]))
          [])]))))
    (calcStep
     («term_=_»
      (Term.hole "_")
      "="
      (Finset.Data.Finset.Fold.«term_*_»
       (Finset.Data.Finset.Fold.«term_*_»
        («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
        "*"
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
       "*"
       (Algebra.BigOperators.Basic.«term∏_,_»
        "∏"
        (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
        ", "
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
     ":="
     (Term.byTactic
      "by"
      (Tactic.tacticSeq
       (Tactic.tacticSeq1Indented
        [(group
          (Tactic.simp
           "simp"
           []
           []
           ["[" [(Tactic.simpLemma [] [] `Finset.prod_mul_distrib) "," (Tactic.simpLemma [] [] `Finset.card_univ)] "]"]
           [])
          [])
         (group (Tactic.Ring.tacticRing "ring") [])]))))])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'tacticCalc_', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'calcStep', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.byTactic
   "by"
   (Tactic.tacticSeq
    (Tactic.tacticSeq1Indented
     [(group
       (Tactic.simp
        "simp"
        []
        []
        ["[" [(Tactic.simpLemma [] [] `Finset.prod_mul_distrib) "," (Tactic.simpLemma [] [] `Finset.card_univ)] "]"]
        [])
       [])
      (group (Tactic.Ring.tacticRing "ring") [])])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'Lean.Parser.Term.byTactic.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq', expected 'Lean.Parser.Tactic.tacticSeq.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeq1Indented.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Tactic.Ring.tacticRing "ring")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Tactic.Ring.tacticRing', expected 'antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1023, tactic))
  (Tactic.simp
   "simp"
   []
   []
   ["[" [(Tactic.simpLemma [] [] `Finset.prod_mul_distrib) "," (Tactic.simpLemma [] [] `Finset.card_univ)] "]"]
   [])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simp', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«]»', expected 'optional.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'sepBy.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'Lean.Parser.Tactic.simpStar'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'Lean.Parser.Tactic.simpErase'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `Finset.card_univ
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'sepBy.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'Lean.Parser.Tactic.simpStar'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.simpLemma', expected 'Lean.Parser.Tactic.simpErase'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `Finset.prod_mul_distrib
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 0, tactic) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  («term_=_»
   (Term.hole "_")
   "="
   (Finset.Data.Finset.Fold.«term_*_»
    (Finset.Data.Finset.Fold.«term_*_»
     («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
     "*"
     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
    "*"
    (Algebra.BigOperators.Basic.«term∏_,_»
     "∏"
     (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
     ", "
     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«term_=_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Finset.Data.Finset.Fold.«term_*_»
   (Finset.Data.Finset.Fold.«term_*_»
    («term_^_» (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥") "^" (Term.app `Fintype.card [`ι]))
    "*"
    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
   "*"
   (Algebra.BigOperators.Basic.«term∏_,_»
    "∏"
    (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
    ", "
    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Finset.Data.Finset.Fold.«term_*_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Algebra.BigOperators.Basic.«term∏_,_»
   "∏"
   (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
   ", "
   (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Algebra.BigOperators.Basic.«term∏_,_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Analysis.Normed.Group.Basic.«term∥_∥»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `m [`i])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `i
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `m
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.explicitBinders', expected 'Mathlib.ExtendedBinder.extBinders'
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
/--
    Given a fixed continuous linear map `g`, associating to a continuous multilinear map `f` the
    continuous multilinear map `f (g m₁, ..., g mₙ)` is a bounded linear operation. -/
  theorem
    is_bounded_linear_map_continuous_multilinear_map_comp_linear
    ( g : G →L[ 𝕜 ] E )
      :
        IsBoundedLinearMap
          𝕜 fun f : ContinuousMultilinearMap 𝕜 fun i : ι => E F => f.comp_continuous_linear_map fun _ => g
    :=
      by
        refine'
            IsLinearMap.with_bound
              ⟨ fun f₁ f₂ => by ext m rfl , fun c f => by ext m rfl ⟩ ∥ g ∥ ^ Fintype.card ι fun f => _
          apply ContinuousMultilinearMap.op_norm_le_bound _ _ fun m => _
          · apply_rules [ mul_nonneg , pow_nonneg , norm_nonneg ]
          calc
            ∥ f g ∘ m ∥ ≤ ∥ f ∥ * ∏ i , ∥ g m i ∥ := f.le_op_norm _
              _ ≤ ∥ f ∥ * ∏ i , ∥ g ∥ * ∥ m i ∥
                :=
                by
                  apply mul_le_mul_of_nonneg_left _ norm_nonneg _
                    exact Finset.prod_le_prod fun i hi => norm_nonneg _ fun i hi => g.le_op_norm _
              _ = ∥ g ∥ ^ Fintype.card ι * ∥ f ∥ * ∏ i , ∥ m i ∥
                :=
                by simp [ Finset.prod_mul_distrib , Finset.card_univ ] ring

end

section BilinearMap

variable (𝕜)

/--  A map `f : E × F → G` satisfies `is_bounded_bilinear_map 𝕜 f` if it is bilinear and
continuous. -/
structure IsBoundedBilinearMap (f : E × F → G) : Prop where
  add_left : ∀ x₁ x₂ : E y : F, f (x₁+x₂, y) = f (x₁, y)+f (x₂, y)
  smul_left : ∀ c : 𝕜 x : E y : F, f (c • x, y) = c • f (x, y)
  add_right : ∀ x : E y₁ y₂ : F, f (x, y₁+y₂) = f (x, y₁)+f (x, y₂)
  smulRight : ∀ c : 𝕜 x : E y : F, f (x, c • y) = c • f (x, y)
  bound : ∃ C > 0, ∀ x : E y : F, ∥f (x, y)∥ ≤ (C*∥x∥)*∥y∥

variable {𝕜}

variable {f : E × F → G}

theorem ContinuousLinearMap.is_bounded_bilinear_map (f : E →L[𝕜] F →L[𝕜] G) :
    IsBoundedBilinearMap 𝕜 fun x : E × F => f x.1 x.2 :=
  { add_left := fun x₁ x₂ y => by
      rw [f.map_add, ContinuousLinearMap.add_apply],
    smul_left := fun c x y => by
      rw [f.map_smul _, ContinuousLinearMap.smul_apply],
    add_right := fun x => (f x).map_add, smulRight := fun c x y => (f x).map_smul c y,
    bound :=
      ⟨max ∥f∥ 1, zero_lt_one.trans_le (le_max_rightₓ _ _), fun x y =>
        (f.le_op_norm₂ x y).trans $ by
          apply_rules [mul_le_mul_of_nonneg_right, norm_nonneg, le_max_leftₓ]⟩ }

protected theorem IsBoundedBilinearMap.is_O (h : IsBoundedBilinearMap 𝕜 f) :
    Asymptotics.IsO f (fun p : E × F => ∥p.1∥*∥p.2∥) ⊤ :=
  let ⟨C, Cpos, hC⟩ := h.bound
  Asymptotics.IsO.of_bound _ $
    Filter.eventually_of_forall $ fun ⟨x, y⟩ => by
      simpa [mul_assocₓ] using hC x y

theorem IsBoundedBilinearMap.is_O_comp {α : Type _} (H : IsBoundedBilinearMap 𝕜 f) {g : α → E} {h : α → F}
    {l : Filter α} : Asymptotics.IsO (fun x => f (g x, h x)) (fun x => ∥g x∥*∥h x∥) l :=
  H.is_O.comp_tendsto le_top

protected theorem IsBoundedBilinearMap.is_O' (h : IsBoundedBilinearMap 𝕜 f) :
    Asymptotics.IsO f (fun p : E × F => ∥p∥*∥p∥) ⊤ :=
  h.is_O.trans (Asymptotics.is_O_fst_prod'.norm_norm.mul Asymptotics.is_O_snd_prod'.norm_norm)

theorem IsBoundedBilinearMap.map_sub_left (h : IsBoundedBilinearMap 𝕜 f) {x y : E} {z : F} :
    f (x - y, z) = f (x, z) - f (y, z) :=
  calc f (x - y, z) = f (x+(-1 : 𝕜) • y, z) := by
    simp [sub_eq_add_neg]
    _ = f (x, z)+(-1 : 𝕜) • f (y, z) := by
    simp only [h.add_left, h.smul_left]
    _ = f (x, z) - f (y, z) := by
    simp [sub_eq_add_neg]
    

theorem IsBoundedBilinearMap.map_sub_right (h : IsBoundedBilinearMap 𝕜 f) {x : E} {y z : F} :
    f (x, y - z) = f (x, y) - f (x, z) :=
  calc f (x, y - z) = f (x, y+(-1 : 𝕜) • z) := by
    simp [sub_eq_add_neg]
    _ = f (x, y)+(-1 : 𝕜) • f (x, z) := by
    simp only [h.add_right, h.smul_right]
    _ = f (x, y) - f (x, z) := by
    simp [sub_eq_add_neg]
    

theorem IsBoundedBilinearMap.continuous (h : IsBoundedBilinearMap 𝕜 f) : Continuous f := by
  have one_ne : (1 : ℝ) ≠ 0 := by
    simp
  obtain ⟨C, Cpos : 0 < C, hC⟩ := h.bound
  rw [continuous_iff_continuous_at]
  intro x
  have H : ∀ a : E b : F, ∥f (a, b)∥ ≤ C*∥∥a∥*∥b∥∥ := by
    intro a b
    simpa [mul_assocₓ] using hC a b
  have h₁ : Asymptotics.IsOₓ (fun e : E × F => f (e.1 - x.1, e.2)) (fun e => (1 : ℝ)) (𝓝 x) := by
    refine' (Asymptotics.is_O_of_le' (𝓝 x) fun e => H (e.1 - x.1) e.2).trans_is_o _
    rw [Asymptotics.is_o_const_iff one_ne]
    convert ((continuous_fst.sub continuous_const).norm.mul continuous_snd.norm).ContinuousAt
    ·
      simp
    infer_instance
  have h₂ : Asymptotics.IsOₓ (fun e : E × F => f (x.1, e.2 - x.2)) (fun e => (1 : ℝ)) (𝓝 x) := by
    refine' (Asymptotics.is_O_of_le' (𝓝 x) fun e => H x.1 (e.2 - x.2)).trans_is_o _
    rw [Asymptotics.is_o_const_iff one_ne]
    convert (continuous_const.mul (continuous_snd.sub continuous_const).norm).ContinuousAt
    ·
      simp
    infer_instance
  have := h₁.add h₂
  rw [Asymptotics.is_o_const_iff one_ne] at this
  change tendsto _ _ _
  convert this.add_const (f x)
  ·
    ext e
    simp [h.map_sub_left, h.map_sub_right]
  ·
    simp

theorem IsBoundedBilinearMap.continuous_left (h : IsBoundedBilinearMap 𝕜 f) {e₂ : F} :
    Continuous fun e₁ => f (e₁, e₂) :=
  h.continuous.comp (continuous_id.prod_mk continuous_const)

theorem IsBoundedBilinearMap.continuous_right (h : IsBoundedBilinearMap 𝕜 f) {e₁ : E} :
    Continuous fun e₂ => f (e₁, e₂) :=
  h.continuous.comp (continuous_const.prod_mk continuous_id)

theorem IsBoundedBilinearMap.is_bounded_linear_map_left (h : IsBoundedBilinearMap 𝕜 f) (y : F) :
    IsBoundedLinearMap 𝕜 fun x => f (x, y) :=
  { map_add := fun x x' => h.add_left _ _ _, map_smul := fun c x => h.smul_left _ _ _,
    bound := by
      rcases h.bound with ⟨C, C_pos, hC⟩
      refine'
        ⟨C*∥y∥+1,
          mul_pos C_pos
            (lt_of_lt_of_leₓ zero_lt_one
              (by
                simp )),
          fun x => _⟩
      have : ∥y∥ ≤ ∥y∥+1 := by
        simp [zero_le_one]
      calc ∥f (x, y)∥ ≤ (C*∥x∥)*∥y∥ := hC x y _ ≤ (C*∥x∥)*∥y∥+1 := by
        apply_rules [norm_nonneg, mul_le_mul_of_nonneg_left, le_of_ltₓ C_pos, mul_nonneg]_ = (C*∥y∥+1)*∥x∥ := by
        ring }

theorem IsBoundedBilinearMap.is_bounded_linear_map_right (h : IsBoundedBilinearMap 𝕜 f) (x : E) :
    IsBoundedLinearMap 𝕜 fun y => f (x, y) :=
  { map_add := fun y y' => h.add_right _ _ _, map_smul := fun c y => h.smul_right _ _ _,
    bound := by
      rcases h.bound with ⟨C, C_pos, hC⟩
      refine'
        ⟨C*∥x∥+1,
          mul_pos C_pos
            (lt_of_lt_of_leₓ zero_lt_one
              (by
                simp )),
          fun y => _⟩
      have : ∥x∥ ≤ ∥x∥+1 := by
        simp [zero_le_one]
      calc ∥f (x, y)∥ ≤ (C*∥x∥)*∥y∥ := hC x y _ ≤ (C*∥x∥+1)*∥y∥ := by
        apply_rules [mul_le_mul_of_nonneg_right, norm_nonneg, mul_le_mul_of_nonneg_left, le_of_ltₓ C_pos] }

theorem is_bounded_bilinear_map_smul {𝕜' : Type _} [NormedField 𝕜'] [NormedAlgebra 𝕜 𝕜'] {E : Type _} [NormedGroup E]
    [NormedSpace 𝕜 E] [NormedSpace 𝕜' E] [IsScalarTower 𝕜 𝕜' E] : IsBoundedBilinearMap 𝕜 fun p : 𝕜' × E => p.1 • p.2 :=
  { add_left := add_smul,
    smul_left := fun c x y => by
      simp [smul_assoc],
    add_right := smul_add,
    smulRight := fun c x y => by
      simp [smul_assoc, smul_algebra_smul_comm],
    bound :=
      ⟨1, zero_lt_one, fun x y => by
        simp [norm_smul]⟩ }

theorem is_bounded_bilinear_map_mul : IsBoundedBilinearMap 𝕜 fun p : 𝕜 × 𝕜 => p.1*p.2 := by
  simp_rw [← smul_eq_mul] <;> exact is_bounded_bilinear_map_smul

theorem is_bounded_bilinear_map_comp : IsBoundedBilinearMap 𝕜 fun p : (E →L[𝕜] F) × (F →L[𝕜] G) => p.2.comp p.1 :=
  { add_left := fun x₁ x₂ y => by
      ext z
      change y (x₁ z+x₂ z) = y (x₁ z)+y (x₂ z)
      rw [y.map_add],
    smul_left := fun c x y => by
      ext z
      change y (c • x z) = c • y (x z)
      rw [ContinuousLinearMap.map_smul],
    add_right := fun x y₁ y₂ => rfl, smulRight := fun c x y => rfl,
    bound :=
      ⟨1, zero_lt_one, fun x y =>
        calc ∥ContinuousLinearMap.comp (x, y).snd (x, y).fst∥ ≤ ∥y∥*∥x∥ := ContinuousLinearMap.op_norm_comp_le _ _
          _ = (1*∥x∥)*∥y∥ := by
          ring
          ⟩ }

theorem ContinuousLinearMap.is_bounded_linear_map_comp_left (g : F →L[𝕜] G) :
    IsBoundedLinearMap 𝕜 fun f : E →L[𝕜] F => ContinuousLinearMap.comp g f :=
  is_bounded_bilinear_map_comp.is_bounded_linear_map_left _

theorem ContinuousLinearMap.is_bounded_linear_map_comp_right (f : E →L[𝕜] F) :
    IsBoundedLinearMap 𝕜 fun g : F →L[𝕜] G => ContinuousLinearMap.comp g f :=
  is_bounded_bilinear_map_comp.is_bounded_linear_map_right _

theorem is_bounded_bilinear_map_apply : IsBoundedBilinearMap 𝕜 fun p : (E →L[𝕜] F) × E => p.1 p.2 :=
  { add_left := by
      simp ,
    smul_left := by
      simp ,
    add_right := by
      simp ,
    smulRight := by
      simp ,
    bound :=
      ⟨1, zero_lt_one, by
        simp [ContinuousLinearMap.le_op_norm]⟩ }

/--  The function `continuous_linear_map.smul_right`, associating to a continuous linear map
`f : E → 𝕜` and a scalar `c : F` the tensor product `f ⊗ c` as a continuous linear map from `E` to
`F`, is a bounded bilinear map. -/
theorem is_bounded_bilinear_map_smul_right :
    IsBoundedBilinearMap 𝕜 fun p => (ContinuousLinearMap.smulRight : (E →L[𝕜] 𝕜) → F → E →L[𝕜] F) p.1 p.2 :=
  { add_left := fun m₁ m₂ f => by
      ext z
      simp [add_smul],
    smul_left := fun c m f => by
      ext z
      simp [mul_smul],
    add_right := fun m f₁ f₂ => by
      ext z
      simp [smul_add],
    smulRight := fun c m f => by
      ext z
      simp [smul_smul, mul_commₓ],
    bound :=
      ⟨1, zero_lt_one, fun m f => by
        simp ⟩ }

/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize.input] (Command.declaration
 (Command.declModifiers
  [(Command.docComment
    "/--"
    " The composition of a continuous linear map with a continuous multilinear map is a bounded\nbilinear operation. -/")]
  []
  []
  []
  []
  [])
 (Command.theorem
  "theorem"
  (Command.declId `is_bounded_bilinear_map_comp_multilinear [])
  (Command.declSig
   [(Term.implicitBinder "{" [`ι] [":" (Term.type "Type" [(Level.hole "_")])] "}")
    (Term.implicitBinder "{" [`E] [":" (Term.arrow `ι "→" (Term.type "Type" [(Level.hole "_")]))] "}")
    (Term.instBinder "[" [] (Term.app `DecidableEq [`ι]) "]")
    (Term.instBinder "[" [] (Term.app `Fintype [`ι]) "]")
    (Term.instBinder
     "["
     []
     (Term.forall "∀" [(Term.simpleBinder [`i] [])] "," (Term.app `NormedGroup [(Term.app `E [`i])]))
     "]")
    (Term.instBinder
     "["
     []
     (Term.forall "∀" [(Term.simpleBinder [`i] [])] "," (Term.app `NormedSpace [`𝕜 (Term.app `E [`i])]))
     "]")]
   (Term.typeSpec
    ":"
    (Term.app
     `IsBoundedBilinearMap
     [`𝕜
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder
          [`p]
          [(Term.typeSpec
            ":"
            («term_×_»
             (Topology.Algebra.Module.«term_→L[_]_» `F " →L[" `𝕜 "] " `G)
             "×"
             (Term.app `ContinuousMultilinearMap [`𝕜 `E `F])))])]
        "=>"
        (Term.app
         (Term.proj (Term.proj `p "." (fieldIdx "1")) "." `compContinuousMultilinearMap)
         [(Term.proj `p "." (fieldIdx "2"))])))])))
  (Command.declValSimple
   ":="
   (Term.structInst
    "{"
    []
    [(group
      (Term.structInstField
       (Term.structInstLVal `add_left [])
       ":="
       (Term.fun
        "fun"
        (Term.basicFun
         [(Term.simpleBinder [`g₁ `g₂ `f] [])]
         "=>"
         (Term.byTactic
          "by"
          (Tactic.tacticSeq
           (Tactic.tacticSeq1Indented
            [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) []) (group (Tactic.tacticRfl "rfl") [])]))))))
      [","])
     (group
      (Term.structInstField
       (Term.structInstLVal `smul_left [])
       ":="
       (Term.fun
        "fun"
        (Term.basicFun
         [(Term.simpleBinder [`c `g `f] [])]
         "=>"
         (Term.byTactic
          "by"
          (Tactic.tacticSeq
           (Tactic.tacticSeq1Indented
            [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) []) (group (Tactic.tacticRfl "rfl") [])]))))))
      [","])
     (group
      (Term.structInstField
       (Term.structInstLVal `add_right [])
       ":="
       (Term.fun
        "fun"
        (Term.basicFun
         [(Term.simpleBinder [`g `f₁ `f₂] [])]
         "=>"
         (Term.byTactic
          "by"
          (Tactic.tacticSeq
           (Tactic.tacticSeq1Indented
            [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
             (group (Tactic.simp "simp" [] [] [] []) [])]))))))
      [","])
     (group
      (Term.structInstField
       (Term.structInstLVal `smulRight [])
       ":="
       (Term.fun
        "fun"
        (Term.basicFun
         [(Term.simpleBinder [`c `g `f] [])]
         "=>"
         (Term.byTactic
          "by"
          (Tactic.tacticSeq
           (Tactic.tacticSeq1Indented
            [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
             (group (Tactic.simp "simp" [] [] [] []) [])]))))))
      [","])
     (group
      (Term.structInstField
       (Term.structInstLVal `bound [])
       ":="
       (Term.anonymousCtor
        "⟨"
        [(numLit "1")
         ","
         `zero_lt_one
         ","
         (Term.fun
          "fun"
          (Term.basicFun
           [(Term.simpleBinder [`g `f] [])]
           "=>"
           (Term.byTactic
            "by"
            (Tactic.tacticSeq
             (Tactic.tacticSeq1Indented
              [(group
                (Tactic.apply
                 "apply"
                 (Term.app
                  `ContinuousMultilinearMap.op_norm_le_bound
                  [(Term.hole "_")
                   (Term.hole "_")
                   (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
                [])
               (group
                (Tactic.«tactic·._»
                 "·"
                 (Tactic.tacticSeq
                  (Tactic.tacticSeq1Indented
                   [(group
                     (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `zero_le_one "," `norm_nonneg] "]" [])
                     [])])))
                [])
               (group
                (tacticCalc_
                 "calc"
                 [(calcStep
                   («term_≤_»
                    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
                    "≤"
                    (Finset.Data.Finset.Fold.«term_*_»
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                     "*"
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
                   ":="
                   (Term.app `g.le_op_norm [(Term.hole "_")]))
                  (calcStep
                   («term_≤_»
                    (Term.hole "_")
                    "≤"
                    (Finset.Data.Finset.Fold.«term_*_»
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                     "*"
                     (Finset.Data.Finset.Fold.«term_*_»
                      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
                      "*"
                      (Algebra.BigOperators.Basic.«term∏_,_»
                       "∏"
                       (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                       ", "
                       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
                   ":="
                   (Term.app
                    `mul_le_mul_of_nonneg_left
                    [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
                  (calcStep
                   («term_=_»
                    (Term.hole "_")
                    "="
                    (Finset.Data.Finset.Fold.«term_*_»
                     (Finset.Data.Finset.Fold.«term_*_»
                      (Finset.Data.Finset.Fold.«term_*_»
                       (numLit "1")
                       "*"
                       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
                      "*"
                      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
                     "*"
                     (Algebra.BigOperators.Basic.«term∏_,_»
                      "∏"
                      (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                      ", "
                      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
                   ":="
                   (Term.byTactic
                    "by"
                    (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
                [])])))))]
        "⟩"))
      [])]
    (Term.optEllipsis [])
    []
    "}")
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
  (Term.structInst
   "{"
   []
   [(group
     (Term.structInstField
      (Term.structInstLVal `add_left [])
      ":="
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder [`g₁ `g₂ `f] [])]
        "=>"
        (Term.byTactic
         "by"
         (Tactic.tacticSeq
          (Tactic.tacticSeq1Indented
           [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) []) (group (Tactic.tacticRfl "rfl") [])]))))))
     [","])
    (group
     (Term.structInstField
      (Term.structInstLVal `smul_left [])
      ":="
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder [`c `g `f] [])]
        "=>"
        (Term.byTactic
         "by"
         (Tactic.tacticSeq
          (Tactic.tacticSeq1Indented
           [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) []) (group (Tactic.tacticRfl "rfl") [])]))))))
     [","])
    (group
     (Term.structInstField
      (Term.structInstLVal `add_right [])
      ":="
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder [`g `f₁ `f₂] [])]
        "=>"
        (Term.byTactic
         "by"
         (Tactic.tacticSeq
          (Tactic.tacticSeq1Indented
           [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
            (group (Tactic.simp "simp" [] [] [] []) [])]))))))
     [","])
    (group
     (Term.structInstField
      (Term.structInstLVal `smulRight [])
      ":="
      (Term.fun
       "fun"
       (Term.basicFun
        [(Term.simpleBinder [`c `g `f] [])]
        "=>"
        (Term.byTactic
         "by"
         (Tactic.tacticSeq
          (Tactic.tacticSeq1Indented
           [(group (Tactic.ext "ext" [(Tactic.rcasesPat.one `m)] []) [])
            (group (Tactic.simp "simp" [] [] [] []) [])]))))))
     [","])
    (group
     (Term.structInstField
      (Term.structInstLVal `bound [])
      ":="
      (Term.anonymousCtor
       "⟨"
       [(numLit "1")
        ","
        `zero_lt_one
        ","
        (Term.fun
         "fun"
         (Term.basicFun
          [(Term.simpleBinder [`g `f] [])]
          "=>"
          (Term.byTactic
           "by"
           (Tactic.tacticSeq
            (Tactic.tacticSeq1Indented
             [(group
               (Tactic.apply
                "apply"
                (Term.app
                 `ContinuousMultilinearMap.op_norm_le_bound
                 [(Term.hole "_")
                  (Term.hole "_")
                  (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
               [])
              (group
               (Tactic.«tactic·._»
                "·"
                (Tactic.tacticSeq
                 (Tactic.tacticSeq1Indented
                  [(group
                    (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `zero_le_one "," `norm_nonneg] "]" [])
                    [])])))
               [])
              (group
               (tacticCalc_
                "calc"
                [(calcStep
                  («term_≤_»
                   (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
                   "≤"
                   (Finset.Data.Finset.Fold.«term_*_»
                    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                    "*"
                    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
                  ":="
                  (Term.app `g.le_op_norm [(Term.hole "_")]))
                 (calcStep
                  («term_≤_»
                   (Term.hole "_")
                   "≤"
                   (Finset.Data.Finset.Fold.«term_*_»
                    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                    "*"
                    (Finset.Data.Finset.Fold.«term_*_»
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
                     "*"
                     (Algebra.BigOperators.Basic.«term∏_,_»
                      "∏"
                      (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                      ", "
                      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
                  ":="
                  (Term.app
                   `mul_le_mul_of_nonneg_left
                   [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
                 (calcStep
                  («term_=_»
                   (Term.hole "_")
                   "="
                   (Finset.Data.Finset.Fold.«term_*_»
                    (Finset.Data.Finset.Fold.«term_*_»
                     (Finset.Data.Finset.Fold.«term_*_»
                      (numLit "1")
                      "*"
                      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
                     "*"
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
                    "*"
                    (Algebra.BigOperators.Basic.«term∏_,_»
                     "∏"
                     (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                     ", "
                     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
                  ":="
                  (Term.byTactic
                   "by"
                   (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
               [])])))))]
       "⟩"))
     [])]
   (Term.optEllipsis [])
   []
   "}")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.structInst', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.structInst', expected 'Lean.Parser.Term.structInst.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.optEllipsis', expected 'Lean.Parser.Term.optEllipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.structInstField', expected 'Lean.Parser.Term.structInstFieldAbbrev.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.structInstField', expected 'Lean.Parser.Term.structInstFieldAbbrev'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.structInstField', expected 'Lean.Parser.Term.structInstField.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.anonymousCtor
   "⟨"
   [(numLit "1")
    ","
    `zero_lt_one
    ","
    (Term.fun
     "fun"
     (Term.basicFun
      [(Term.simpleBinder [`g `f] [])]
      "=>"
      (Term.byTactic
       "by"
       (Tactic.tacticSeq
        (Tactic.tacticSeq1Indented
         [(group
           (Tactic.apply
            "apply"
            (Term.app
             `ContinuousMultilinearMap.op_norm_le_bound
             [(Term.hole "_")
              (Term.hole "_")
              (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
           [])
          (group
           (Tactic.«tactic·._»
            "·"
            (Tactic.tacticSeq
             (Tactic.tacticSeq1Indented
              [(group
                (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `zero_le_one "," `norm_nonneg] "]" [])
                [])])))
           [])
          (group
           (tacticCalc_
            "calc"
            [(calcStep
              («term_≤_»
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
               "≤"
               (Finset.Data.Finset.Fold.«term_*_»
                (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                "*"
                (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
              ":="
              (Term.app `g.le_op_norm [(Term.hole "_")]))
             (calcStep
              («term_≤_»
               (Term.hole "_")
               "≤"
               (Finset.Data.Finset.Fold.«term_*_»
                (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
                "*"
                (Finset.Data.Finset.Fold.«term_*_»
                 (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
                 "*"
                 (Algebra.BigOperators.Basic.«term∏_,_»
                  "∏"
                  (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                  ", "
                  (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
              ":="
              (Term.app
               `mul_le_mul_of_nonneg_left
               [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
             (calcStep
              («term_=_»
               (Term.hole "_")
               "="
               (Finset.Data.Finset.Fold.«term_*_»
                (Finset.Data.Finset.Fold.«term_*_»
                 (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
                 "*"
                 (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
                "*"
                (Algebra.BigOperators.Basic.«term∏_,_»
                 "∏"
                 (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                 ", "
                 (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
              ":="
              (Term.byTactic
               "by"
               (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
           [])])))))]
   "⟩")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.anonymousCtor', expected 'Lean.Parser.Term.anonymousCtor.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'sepBy.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.fun
   "fun"
   (Term.basicFun
    [(Term.simpleBinder [`g `f] [])]
    "=>"
    (Term.byTactic
     "by"
     (Tactic.tacticSeq
      (Tactic.tacticSeq1Indented
       [(group
         (Tactic.apply
          "apply"
          (Term.app
           `ContinuousMultilinearMap.op_norm_le_bound
           [(Term.hole "_")
            (Term.hole "_")
            (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
         [])
        (group
         (Tactic.«tactic·._»
          "·"
          (Tactic.tacticSeq
           (Tactic.tacticSeq1Indented
            [(group
              (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `zero_le_one "," `norm_nonneg] "]" [])
              [])])))
         [])
        (group
         (tacticCalc_
          "calc"
          [(calcStep
            («term_≤_»
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
             "≤"
             (Finset.Data.Finset.Fold.«term_*_»
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
              "*"
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
            ":="
            (Term.app `g.le_op_norm [(Term.hole "_")]))
           (calcStep
            («term_≤_»
             (Term.hole "_")
             "≤"
             (Finset.Data.Finset.Fold.«term_*_»
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
              "*"
              (Finset.Data.Finset.Fold.«term_*_»
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
               "*"
               (Algebra.BigOperators.Basic.«term∏_,_»
                "∏"
                (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
                ", "
                (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
            ":="
            (Term.app
             `mul_le_mul_of_nonneg_left
             [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
           (calcStep
            («term_=_»
             (Term.hole "_")
             "="
             (Finset.Data.Finset.Fold.«term_*_»
              (Finset.Data.Finset.Fold.«term_*_»
               (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
               "*"
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
              "*"
              (Algebra.BigOperators.Basic.«term∏_,_»
               "∏"
               (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
               ", "
               (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
            ":="
            (Term.byTactic
             "by"
             (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
         [])])))))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.fun', expected 'Lean.Parser.Term.fun.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.basicFun', expected 'Lean.Parser.Term.basicFun.antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.byTactic
   "by"
   (Tactic.tacticSeq
    (Tactic.tacticSeq1Indented
     [(group
       (Tactic.apply
        "apply"
        (Term.app
         `ContinuousMultilinearMap.op_norm_le_bound
         [(Term.hole "_")
          (Term.hole "_")
          (Term.fun "fun" (Term.basicFun [(Term.simpleBinder [`m] [])] "=>" (Term.hole "_")))]))
       [])
      (group
       (Tactic.«tactic·._»
        "·"
        (Tactic.tacticSeq
         (Tactic.tacticSeq1Indented
          [(group
            (Tactic.applyRules "apply_rules" [] "[" [`mul_nonneg "," `zero_le_one "," `norm_nonneg] "]" [])
            [])])))
       [])
      (group
       (tacticCalc_
        "calc"
        [(calcStep
          («term_≤_»
           (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
           "≤"
           (Finset.Data.Finset.Fold.«term_*_»
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
            "*"
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
          ":="
          (Term.app `g.le_op_norm [(Term.hole "_")]))
         (calcStep
          («term_≤_»
           (Term.hole "_")
           "≤"
           (Finset.Data.Finset.Fold.«term_*_»
            (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
            "*"
            (Finset.Data.Finset.Fold.«term_*_»
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
             "*"
             (Algebra.BigOperators.Basic.«term∏_,_»
              "∏"
              (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
              ", "
              (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
          ":="
          (Term.app
           `mul_le_mul_of_nonneg_left
           [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
         (calcStep
          («term_=_»
           (Term.hole "_")
           "="
           (Finset.Data.Finset.Fold.«term_*_»
            (Finset.Data.Finset.Fold.«term_*_»
             (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
             "*"
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
            "*"
            (Algebra.BigOperators.Basic.«term∏_,_»
             "∏"
             (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
             ", "
             (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
          ":="
          (Term.byTactic
           "by"
           (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
       [])])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'Lean.Parser.Term.byTactic.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq', expected 'Lean.Parser.Tactic.tacticSeq.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeq1Indented.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (tacticCalc_
   "calc"
   [(calcStep
     («term_≤_»
      (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `g [(Term.app `f [`m])]) "∥")
      "≤"
      (Finset.Data.Finset.Fold.«term_*_»
       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
       "*"
       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `f [`m]) "∥")))
     ":="
     (Term.app `g.le_op_norm [(Term.hole "_")]))
    (calcStep
     («term_≤_»
      (Term.hole "_")
      "≤"
      (Finset.Data.Finset.Fold.«term_*_»
       (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥")
       "*"
       (Finset.Data.Finset.Fold.«term_*_»
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥")
        "*"
        (Algebra.BigOperators.Basic.«term∏_,_»
         "∏"
         (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
         ", "
         (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))))
     ":="
     (Term.app
      `mul_le_mul_of_nonneg_left
      [(Term.app `f.le_op_norm [(Term.hole "_")]) (Term.app `norm_nonneg [(Term.hole "_")])]))
    (calcStep
     («term_=_»
      (Term.hole "_")
      "="
      (Finset.Data.Finset.Fold.«term_*_»
       (Finset.Data.Finset.Fold.«term_*_»
        (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
        "*"
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
       "*"
       (Algebra.BigOperators.Basic.«term∏_,_»
        "∏"
        (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
        ", "
        (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
     ":="
     (Term.byTactic "by" (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])]))))])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'tacticCalc_', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'calcStep', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.byTactic "by" (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.Ring.tacticRing "ring") [])])))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.byTactic', expected 'Lean.Parser.Term.byTactic.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq', expected 'Lean.Parser.Tactic.tacticSeq.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeqBracketed'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Tactic.tacticSeq1Indented', expected 'Lean.Parser.Tactic.tacticSeq1Indented.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'group', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Tactic.Ring.tacticRing "ring")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Tactic.Ring.tacticRing', expected 'antiquot'
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 0, tactic) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  («term_=_»
   (Term.hole "_")
   "="
   (Finset.Data.Finset.Fold.«term_*_»
    (Finset.Data.Finset.Fold.«term_*_»
     (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
     "*"
     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
    "*"
    (Algebra.BigOperators.Basic.«term∏_,_»
     "∏"
     (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
     ", "
     (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind '«term_=_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Finset.Data.Finset.Fold.«term_*_»
   (Finset.Data.Finset.Fold.«term_*_»
    (Finset.Data.Finset.Fold.«term_*_» (numLit "1") "*" (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `g "∥"))
    "*"
    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" `f "∥"))
   "*"
   (Algebra.BigOperators.Basic.«term∏_,_»
    "∏"
    (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
    ", "
    (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Finset.Data.Finset.Fold.«term_*_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Algebra.BigOperators.Basic.«term∏_,_»
   "∏"
   (Lean.explicitBinders (Lean.unbracketedExplicitBinders [(Lean.binderIdent `i)] []))
   ", "
   (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥"))
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Algebra.BigOperators.Basic.«term∏_,_»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Analysis.Normed.Group.Basic.«term∥_∥» "∥" (Term.app `m [`i]) "∥")
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Analysis.Normed.Group.Basic.«term∥_∥»', expected 'antiquot'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  (Term.app `m [`i])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.app', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'many.antiquot_scope'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.namedArgument'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'Lean.Parser.Term.ellipsis'
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
  `i
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1023 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, term))
  `m
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'ident', expected 'ident.antiquot'
[PrettyPrinter.parenthesize] ...precedences are 1024 >? 1024, (none, [anonymous]) <=? (some 1022, term)
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022, (some 1023, term) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.explicitBinders', expected 'Mathlib.ExtendedBinder.extBinders'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.basicFun', expected 'Lean.Parser.Term.matchAlts.antiquot'
[PrettyPrinter.parenthesize.backtrack] unexpected node kind 'Lean.Parser.Term.basicFun', expected 'Lean.Parser.Term.matchAlts'
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
/--
    The composition of a continuous linear map with a continuous multilinear map is a bounded
    bilinear operation. -/
  theorem
    is_bounded_bilinear_map_comp_multilinear
    { ι : Type _ }
        { E : ι → Type _ }
        [ DecidableEq ι ]
        [ Fintype ι ]
        [ ∀ i , NormedGroup E i ]
        [ ∀ i , NormedSpace 𝕜 E i ]
      :
        IsBoundedBilinearMap
          𝕜 fun p : F →L[ 𝕜 ] G × ContinuousMultilinearMap 𝕜 E F => p . 1 . compContinuousMultilinearMap p . 2
    :=
      {
        add_left := fun g₁ g₂ f => by ext m rfl ,
          smul_left := fun c g f => by ext m rfl ,
          add_right := fun g f₁ f₂ => by ext m simp ,
          smulRight := fun c g f => by ext m simp ,
          bound
            :=
            ⟨
              1
                ,
                zero_lt_one
                ,
                fun
                  g f
                    =>
                    by
                      apply ContinuousMultilinearMap.op_norm_le_bound _ _ fun m => _
                        · apply_rules [ mul_nonneg , zero_le_one , norm_nonneg ]
                        calc
                          ∥ g f m ∥ ≤ ∥ g ∥ * ∥ f m ∥ := g.le_op_norm _
                            _ ≤ ∥ g ∥ * ∥ f ∥ * ∏ i , ∥ m i ∥ := mul_le_mul_of_nonneg_left f.le_op_norm _ norm_nonneg _
                            _ = 1 * ∥ g ∥ * ∥ f ∥ * ∏ i , ∥ m i ∥ := by ring
              ⟩
        }

/--  Definition of the derivative of a bilinear map `f`, given at a point `p` by
`q ↦ f(p.1, q.2) + f(q.1, p.2)` as in the standard formula for the derivative of a product.
We define this function here as a linear map `E × F →ₗ[𝕜] G`, then `is_bounded_bilinear_map.deriv`
strengthens it to a continuous linear map `E × F →L[𝕜] G`.
``. -/
def IsBoundedBilinearMap.linearDeriv (h : IsBoundedBilinearMap 𝕜 f) (p : E × F) : E × F →ₗ[𝕜] G :=
  { toFun := fun q => f (p.1, q.2)+f (q.1, p.2),
    map_add' := fun q₁ q₂ => by
      change (f (p.1, q₁.2+q₂.2)+f (q₁.1+q₂.1, p.2)) = (f (p.1, q₁.2)+f (q₁.1, p.2))+f (p.1, q₂.2)+f (q₂.1, p.2)
      simp [h.add_left, h.add_right]
      abel,
    map_smul' := fun c q => by
      change (f (p.1, c • q.2)+f (c • q.1, p.2)) = c • f (p.1, q.2)+f (q.1, p.2)
      simp [h.smul_left, h.smul_right, smul_add] }

/--  The derivative of a bounded bilinear map at a point `p : E × F`, as a continuous linear map
from `E × F` to `G`. The statement that this is indeed the derivative of `f` is
`is_bounded_bilinear_map.has_fderiv_at` in `analysis.calculus.fderiv`. -/
def IsBoundedBilinearMap.deriv (h : IsBoundedBilinearMap 𝕜 f) (p : E × F) : E × F →L[𝕜] G :=
  (h.linear_deriv p).mkContinuousOfExistsBound $ by
    rcases h.bound with ⟨C, Cpos, hC⟩
    refine' ⟨(C*∥p.1∥)+C*∥p.2∥, fun q => _⟩
    calc ∥f (p.1, q.2)+f (q.1, p.2)∥ ≤ ((C*∥p.1∥)*∥q.2∥)+(C*∥q.1∥)*∥p.2∥ :=
      norm_add_le_of_le (hC _ _) (hC _ _)_ ≤ ((C*∥p.1∥)*∥q∥)+(C*∥q∥)*∥p.2∥ := by
      apply add_le_add
      exact mul_le_mul_of_nonneg_left (le_max_rightₓ _ _) (mul_nonneg (le_of_ltₓ Cpos) (norm_nonneg _))
      apply mul_le_mul_of_nonneg_right _ (norm_nonneg _)
      exact mul_le_mul_of_nonneg_left (le_max_leftₓ _ _) (le_of_ltₓ Cpos)_ = ((C*∥p.1∥)+C*∥p.2∥)*∥q∥ := by
      ring

@[simp]
theorem is_bounded_bilinear_map_deriv_coe (h : IsBoundedBilinearMap 𝕜 f) (p q : E × F) :
    h.deriv p q = f (p.1, q.2)+f (q.1, p.2) :=
  rfl

variable (𝕜)

/--  The function `lmul_left_right : 𝕜' × 𝕜' → (𝕜' →L[𝕜] 𝕜')` is a bounded bilinear map. -/
theorem ContinuousLinearMap.lmul_left_right_is_bounded_bilinear (𝕜' : Type _) [NormedRing 𝕜'] [NormedAlgebra 𝕜 𝕜'] :
    IsBoundedBilinearMap 𝕜 fun p : 𝕜' × 𝕜' => ContinuousLinearMap.lmulLeftRight 𝕜 𝕜' p.1 p.2 :=
  (ContinuousLinearMap.lmulLeftRight 𝕜 𝕜').IsBoundedBilinearMap

variable {𝕜}

/--  Given a bounded bilinear map `f`, the map associating to a point `p` the derivative of `f` at
`p` is itself a bounded linear map. -/
theorem IsBoundedBilinearMap.is_bounded_linear_map_deriv (h : IsBoundedBilinearMap 𝕜 f) :
    IsBoundedLinearMap 𝕜 fun p : E × F => h.deriv p := by
  rcases h.bound with ⟨C, Cpos : 0 < C, hC⟩
  refine' IsLinearMap.with_bound ⟨fun p₁ p₂ => _, fun c p => _⟩ (C+C) fun p => _
  ·
    ext <;> simp [h.add_left, h.add_right] <;> abel
  ·
    ext <;> simp [h.smul_left, h.smul_right, smul_add]
  ·
    refine' ContinuousLinearMap.op_norm_le_bound _ (mul_nonneg (add_nonneg Cpos.le Cpos.le) (norm_nonneg _)) fun q => _
    calc ∥f (p.1, q.2)+f (q.1, p.2)∥ ≤ ((C*∥p.1∥)*∥q.2∥)+(C*∥q.1∥)*∥p.2∥ :=
      norm_add_le_of_le (hC _ _) (hC _ _)_ ≤ ((C*∥p∥)*∥q∥)+(C*∥q∥)*∥p∥ := by
      apply_rules [add_le_add, mul_le_mul, norm_nonneg, Cpos.le, le_reflₓ, le_max_leftₓ, le_max_rightₓ,
        mul_nonneg]_ = ((C+C)*∥p∥)*∥q∥ :=
      by
      ring

end BilinearMap

namespace ContinuousLinearEquiv

open Set

/-!
### The set of continuous linear equivalences between two Banach spaces is open

In this section we establish that the set of continuous linear equivalences between two Banach
spaces is an open subset of the space of linear maps between them.
-/


protected theorem IsOpen [CompleteSpace E] : IsOpen (range (coeₓ : (E ≃L[𝕜] F) → E →L[𝕜] F)) := by
  rw [is_open_iff_mem_nhds, forall_range_iff]
  refine' fun e => IsOpen.mem_nhds _ (mem_range_self _)
  let O : (E →L[𝕜] F) → E →L[𝕜] E := fun f => (e.symm : F →L[𝕜] E).comp f
  have h_O : Continuous O := is_bounded_bilinear_map_comp.continuous_left
  convert units.is_open.preimage h_O using 1
  ext f'
  constructor
  ·
    rintro ⟨e', rfl⟩
    exact ⟨(e'.trans e.symm).toUnit, rfl⟩
  ·
    rintro ⟨w, hw⟩
    use (units_equiv 𝕜 E w).trans e
    ext x
    simp [coe_fn_coe_base' w, hw]

protected theorem nhds [CompleteSpace E] (e : E ≃L[𝕜] F) : range (coeₓ : (E ≃L[𝕜] F) → E →L[𝕜] F) ∈ 𝓝 (e : E →L[𝕜] F) :=
  IsOpen.mem_nhds ContinuousLinearEquiv.is_open
    (by
      simp )

end ContinuousLinearEquiv

