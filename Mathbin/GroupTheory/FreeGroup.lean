/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau
-/
import Mathbin.Data.Fintype.Basic
import Mathbin.GroupTheory.Subgroup.Basic

/-!
# Free groups

This file defines free groups over a type. Furthermore, it is shown that the free group construction
is an instance of a monad. For the result that `free_group` is the left adjoint to the forgetful
functor from groups to types, see `algebra/category/Group/adjunctions`.

## Main definitions

* `free_group`: the free group associated to a type `α` defined as the words over `a : α × bool`
  modulo the relation `a * x * x⁻¹ * b = a * b`.
* `free_group.mk`: the canonical quotient map `list (α × bool) → free_group α`.
* `free_group.of`: the canoical injection `α → free_group α`.
* `free_group.lift f`: the canonical group homomorphism `free_group α →* G`
  given a group `G` and a function `f : α → G`.

## Main statements

* `free_group.church_rosser`: The Church-Rosser theorem for word reduction
  (also known as Newman's diamond lemma).
* `free_group.free_group_unit_equiv_int`: The free group over the one-point type
  is isomorphic to the integers.
* The free group construction is an instance of a monad.

## Implementation details

First we introduce the one step reduction relation `free_group.red.step`:
`w * x * x⁻¹ * v   ~>   w * v`, its reflexive transitive closure `free_group.red.trans`
and prove that its join is an equivalence relation. Then we introduce `free_group α` as a quotient
over `free_group.red.step`.

## Tags

free group, Newman's diamond lemma, Church-Rosser theorem
-/


open Relation

universe u v w

variable {α : Type u}

attribute [local simp] List.append_eq_has_append

namespace FreeGroup

variable {L L₁ L₂ L₃ L₄ : List (α × Bool)}

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- Reduction step: `w * x * x⁻¹ * v ~> w * v` -/
inductive Red.Step : List (α × Bool) → List (α × Bool) → Prop
  | bnot {L₁ L₂ x b} : red.step (L₁ ++ (x, b)::(x, bnot b)::L₂) (L₁ ++ L₂)

attribute [simp] red.step.bnot

/-- Reflexive-transitive closure of red.step -/
def Red : List (α × Bool) → List (α × Bool) → Prop :=
  ReflTransGen Red.Step

@[refl]
theorem Red.refl : Red L L :=
  refl_trans_gen.refl

@[trans]
theorem Red.trans : Red L₁ L₂ → Red L₂ L₃ → Red L₁ L₃ :=
  refl_trans_gen.trans

namespace Red

/-- Predicate asserting that word `w₁` can be reduced to `w₂` in one step, i.e. there are words
`w₃ w₄` and letter `x` such that `w₁ = w₃xx⁻¹w₄` and `w₂ = w₃w₄`  -/
theorem Step.length : ∀ {L₁ L₂ : List (α × Bool)}, Step L₁ L₂ → L₂.length + 2 = L₁.length
  | _, _, @red.step.bnot _ L1 L2 x b => by
    rw [List.length_append, List.length_append] <;> rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem Step.bnot_rev {x b} : Step (L₁ ++ (x, bnot b)::(x, b)::L₂) (L₁ ++ L₂) := by
  cases b <;> exact step.bnot

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem Step.cons_bnot {x b} : Red.Step ((x, b)::(x, bnot b)::L) L :=
  @Step.bnot _ [] _ _ _

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem Step.cons_bnot_rev {x b} : Red.Step ((x, bnot b)::(x, b)::L) L :=
  @Red.Step.bnot_rev _ [] _ _ _

theorem Step.append_left : ∀ {L₁ L₂ L₃ : List (α × Bool)}, Step L₂ L₃ → Step (L₁ ++ L₂) (L₁ ++ L₃)
  | _, _, _, red.step.bnot => by
    rw [← List.append_assoc, ← List.append_assoc] <;> constructor

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Step.cons {x} (H : Red.Step L₁ L₂) : Red.Step (x::L₁) (x::L₂) :=
  @Step.append_left _ [x] _ _ H

theorem Step.append_right : ∀ {L₁ L₂ L₃ : List (α × Bool)}, Step L₁ L₂ → Step (L₁ ++ L₃) (L₂ ++ L₃)
  | _, _, _, red.step.bnot => by
    simp

theorem not_step_nil : ¬Step [] L := by
  generalize h' : [] = L'
  intro h
  cases' h with L₁ L₂
  simp [List.nil_eq_append_iff] at h'
  contradiction

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Step.cons_left_iff {a : α} {b : Bool} :
    Step ((a, b)::L₁) L₂ ↔ (∃ L, Step L₁ L ∧ L₂ = (a, b)::L) ∨ L₁ = (a, bnot b)::L₂ := by
  constructor
  · generalize hL : ((a, b)::L₁ : List _) = L
    intro h
    rcases h with ⟨_ | ⟨p, s'⟩, e, a', b'⟩
    · simp at hL
      simp [*]
      
    · simp at hL
      rcases hL with ⟨rfl, rfl⟩
      refine' Or.inl ⟨s' ++ e, step.bnot, _⟩
      simp
      
    
  · intro h
    rcases h with (⟨L, h, rfl⟩ | rfl)
    · exact step.cons h
      
    · exact step.cons_bnot
      
    

theorem not_step_singleton : ∀ {p : α × Bool}, ¬Step [p] L
  | (a, b) => by
    simp [step.cons_left_iff, not_step_nil]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Step.cons_cons_iff : ∀ {p : α × Bool}, Step (p::L₁) (p::L₂) ↔ Step L₁ L₂ := by
  simp (config := { contextual := true })[step.cons_left_iff, iff_def, or_imp_distrib]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem Step.append_left_iff : ∀ L, Step (L ++ L₁) (L ++ L₂) ↔ Step L₁ L₂
  | [] => by
    simp
  | p::l => by
    simp [step.append_left_iff l, step.cons_cons_iff]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
private theorem step.diamond_aux :
    ∀ {L₁ L₂ L₃ L₄ : List (α × Bool)} {x1 b1 x2 b2},
      ((L₁ ++ (x1, b1)::(x1, bnot b1)::L₂) = L₃ ++ (x2, b2)::(x2, bnot b2)::L₄) →
        L₁ ++ L₂ = L₃ ++ L₄ ∨ ∃ L₅, Red.Step (L₁ ++ L₂) L₅ ∧ Red.Step (L₃ ++ L₄) L₅
  | [], _, [], _, _, _, _, _, H => by
    injections <;> subst_vars <;> simp
  | [], _, [(x3, b3)], _, _, _, _, _, H => by
    injections <;> subst_vars <;> simp
  | [(x3, b3)], _, [], _, _, _, _, _, H => by
    injections <;> subst_vars <;> simp
  | [], _, (x3, b3)::(x4, b4)::tl, _, _, _, _, _, H => by
    injections <;> subst_vars <;> simp <;> right <;> exact ⟨_, red.step.bnot, red.step.cons_bnot⟩
  | (x3, b3)::(x4, b4)::tl, _, [], _, _, _, _, _, H => by
    injections <;> subst_vars <;> simp <;> right <;> exact ⟨_, red.step.cons_bnot, red.step.bnot⟩
  | (x3, b3)::tl, _, (x4, b4)::tl2, _, _, _, _, _, H =>
    let ⟨H1, H2⟩ := List.cons.injₓ H
    match step.diamond_aux H2 with
    | Or.inl H3 =>
      Or.inl <| by
        simp [H1, H3]
    | Or.inr ⟨L₅, H3, H4⟩ =>
      Or.inr
        ⟨_, Step.cons H3, by
          simpa [H1] using step.cons H4⟩

theorem Step.diamond :
    ∀ {L₁ L₂ L₃ L₄ : List (α × Bool)},
      Red.Step L₁ L₃ → Red.Step L₂ L₄ → L₁ = L₂ → L₃ = L₄ ∨ ∃ L₅, Red.Step L₃ L₅ ∧ Red.Step L₄ L₅
  | _, _, _, _, red.step.bnot, red.step.bnot, H => Step.diamond_aux H

theorem Step.to_red : Step L₁ L₂ → Red L₁ L₂ :=
  refl_trans_gen.single

/-- **Church-Rosser theorem** for word reduction: If `w1 w2 w3` are words such that `w1` reduces
to `w2` and `w3` respectively, then there is a word `w4` such that `w2` and `w3` reduce to `w4`
respectively. This is also known as Newman's diamond lemma. -/
theorem church_rosser : Red L₁ L₂ → Red L₁ L₃ → Join Red L₂ L₃ :=
  Relation.church_rosser fun a b c hab hac =>
    match b, c, Red.Step.diamond hab hac rfl with
    | b, _, Or.inl rfl =>
      ⟨b, by
        rfl, by
        rfl⟩
    | b, c, Or.inr ⟨d, hbd, hcd⟩ => ⟨d, ReflGen.single hbd, hcd.to_red⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem cons_cons {p} : Red L₁ L₂ → Red (p::L₁) (p::L₂) :=
  ReflTransGen.lift (List.cons p) fun a b => Step.cons

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem cons_cons_iff (p) : Red (p::L₁) (p::L₂) ↔ Red L₁ L₂ :=
  Iff.intro
    (by
      generalize eq₁ : (p::L₁ : List _) = LL₁
      generalize eq₂ : (p::L₂ : List _) = LL₂
      intro h
      induction' h using Relation.ReflTransGen.head_induction_on with L₁ L₂ h₁₂ h ih generalizing L₁ L₂
      · subst_vars
        cases eq₂
        constructor
        
      · subst_vars
        cases' p with a b
        rw [step.cons_left_iff] at h₁₂
        rcases h₁₂ with (⟨L, h₁₂, rfl⟩ | rfl)
        · exact (ih rfl rfl).head h₁₂
          
        · exact (cons_cons h).tail step.cons_bnot_rev
          
        )
    cons_cons

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_append_left_iff : ∀ L, Red (L ++ L₁) (L ++ L₂) ↔ Red L₁ L₂
  | [] => Iff.rfl
  | p::L => by
    simp [append_append_left_iff L, cons_cons_iff]

theorem append_append (h₁ : Red L₁ L₃) (h₂ : Red L₂ L₄) : Red (L₁ ++ L₂) (L₃ ++ L₄) :=
  (h₁.lift (fun L => L ++ L₂) fun a b => Step.append_right).trans ((append_append_left_iff _).2 h₂)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem to_append_iff : Red L (L₁ ++ L₂) ↔ ∃ L₃ L₄, L = L₃ ++ L₄ ∧ Red L₃ L₁ ∧ Red L₄ L₂ :=
  Iff.intro
    (by
      generalize eq : L₁ ++ L₂ = L₁₂
      intro h
      induction' h with L' L₁₂ hLL' h ih generalizing L₁ L₂
      · exact
          ⟨_, _, Eq.symm, by
            rfl, by
            rfl⟩
        
      · cases' h with s e a b
        rcases List.append_eq_append_iff.1 Eq with (⟨s', rfl, rfl⟩ | ⟨e', rfl, rfl⟩)
        · have : L₁ ++ (s' ++ (a, b)::(a, bnot b)::e) = L₁ ++ s' ++ (a, b)::(a, bnot b)::e := by
            simp
          rcases ih this with ⟨w₁, w₂, rfl, h₁, h₂⟩
          exact ⟨w₁, w₂, rfl, h₁, h₂.tail step.bnot⟩
          
        · have : (s ++ (a, b)::(a, bnot b)::e') ++ L₂ = s ++ (a, b)::(a, bnot b)::e' ++ L₂ := by
            simp
          rcases ih this with ⟨w₁, w₂, rfl, h₁, h₂⟩
          exact ⟨w₁, w₂, rfl, h₁.tail step.bnot, h₂⟩
          
        )
    fun ⟨L₃, L₄, Eq, h₃, h₄⟩ => Eq.symm ▸ append_append h₃ h₄

/-- The empty word `[]` only reduces to itself. -/
theorem nil_iff : Red [] L ↔ L = [] :=
  refl_trans_gen_iff_eq fun l => Red.not_step_nil

/-- A letter only reduces to itself. -/
theorem singleton_iff {x} : Red [x] L₁ ↔ L₁ = [x] :=
  refl_trans_gen_iff_eq fun l => not_step_singleton

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- If `x` is a letter and `w` is a word such that `xw` reduces to the empty word, then `w` reduces
to `x⁻¹` -/
theorem cons_nil_iff_singleton {x b} : Red ((x, b)::L) [] ↔ Red L [(x, bnot b)] :=
  Iff.intro
    (fun h => by
      have h₁ : Red ((x, bnot b)::(x, b)::L) [(x, bnot b)] := cons_cons h
      have h₂ : Red ((x, bnot b)::(x, b)::L) L := ReflTransGen.single Step.cons_bnot_rev
      let ⟨L', h₁, h₂⟩ := church_rosser h₁ h₂
      rw [singleton_iff] at h₁ <;> subst L' <;> assumption)
    fun h => (cons_cons h).tail Step.cons_bnot

theorem red_iff_irreducible {x1 b1 x2 b2} (h : (x1, b1) ≠ (x2, b2)) :
    Red [(x1, bnot b1), (x2, b2)] L ↔ L = [(x1, bnot b1), (x2, b2)] := by
  apply refl_trans_gen_iff_eq
  generalize eq : [(x1, bnot b1), (x2, b2)] = L'
  intro L h'
  cases h'
  simp [List.cons_eq_append_iff, List.nil_eq_append_iff] at eq
  rcases Eq with ⟨rfl, ⟨rfl, rfl⟩, ⟨rfl, rfl⟩, rfl⟩
  subst_vars
  simp at h
  contradiction

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- If `x` and `y` are distinct letters and `w₁ w₂` are words such that `xw₁` reduces to `yw₂`, then
`w₁` reduces to `x⁻¹yw₂`. -/
theorem inv_of_red_of_ne {x1 b1 x2 b2} (H1 : (x1, b1) ≠ (x2, b2)) (H2 : Red ((x1, b1)::L₁) ((x2, b2)::L₂)) :
    Red L₁ ((x1, bnot b1)::(x2, b2)::L₂) := by
  have : red ((x1, b1)::L₁) ([(x2, b2)] ++ L₂) := H2
  rcases to_append_iff.1 this with ⟨_ | ⟨p, L₃⟩, L₄, eq, h₁, h₂⟩
  · simp [nil_iff] at h₁
    contradiction
    
  · cases Eq
    show red (L₃ ++ L₄) ([(x1, bnot b1), (x2, b2)] ++ L₂)
    apply append_append _ h₂
    have h₁ : red ((x1, bnot b1)::(x1, b1)::L₃) [(x1, bnot b1), (x2, b2)] := cons_cons h₁
    have h₂ : red ((x1, bnot b1)::(x1, b1)::L₃) L₃ := step.cons_bnot_rev.to_red
    rcases church_rosser h₁ h₂ with ⟨L', h₁, h₂⟩
    rw [red_iff_irreducible H1] at h₁
    rwa [h₁] at h₂
    

theorem Step.sublist (H : Red.Step L₁ L₂) : L₂ <+ L₁ := by
  cases H <;> simp <;> constructor <;> constructor <;> rfl

/-- If `w₁ w₂` are words such that `w₁` reduces to `w₂`, then `w₂` is a sublist of `w₁`. -/
protected theorem sublist : Red L₁ L₂ → L₂ <+ L₁ :=
  refl_trans_gen_of_transitive_reflexive (fun l => List.Sublist.refl l)
    (fun a b c hab hbc => List.Sublist.trans hbc hab) fun a b => Red.Step.sublist

theorem length_le (h : Red L₁ L₂) : L₂.length ≤ L₁.length :=
  List.length_le_of_sublistₓ h.Sublist

theorem sizeof_of_step : ∀ {L₁ L₂ : List (α × Bool)}, Step L₁ L₂ → L₂.sizeof < L₁.sizeof
  | _, _, @step.bnot _ L1 L2 x b => by
    induction' L1 with hd tl ih
    case list.nil =>
      dsimp' [List.sizeof]
      have H :
        1 + sizeof (x, b) + (1 + sizeof (x, bnot b) + List.sizeof L2) =
          List.sizeof L2 + 1 + (sizeof (x, b) + sizeof (x, bnot b) + 1) :=
        by
        ac_rfl
      rw [H]
      exact Nat.le_add_rightₓ _ _
    case list.cons =>
      dsimp' [List.sizeof]
      exact Nat.add_lt_add_leftₓ ih _

theorem length (h : Red L₁ L₂) : ∃ n, L₁.length = L₂.length + 2 * n := by
  induction' h with L₂ L₃ h₁₂ h₂₃ ih
  · exact ⟨0, rfl⟩
    
  · rcases ih with ⟨n, eq⟩
    exists 1 + n
    simp [mul_addₓ, Eq, (step.length h₂₃).symm, add_assocₓ]
    

theorem antisymm (h₁₂ : Red L₁ L₂) (h₂₁ : Red L₂ L₁) : L₁ = L₂ :=
  h₂₁.Sublist.antisymm h₁₂.Sublist

end Red

theorem equivalence_join_red : Equivalenceₓ (Join (@Red α)) :=
  equivalence_join_refl_trans_gen fun a b c hab hac =>
    match b, c, Red.Step.diamond hab hac rfl with
    | b, _, Or.inl rfl =>
      ⟨b, by
        rfl, by
        rfl⟩
    | b, c, Or.inr ⟨d, hbd, hcd⟩ => ⟨d, ReflGen.single hbd, ReflTransGen.single hcd⟩

theorem join_red_of_step (h : Red.Step L₁ L₂) : Join Red L₁ L₂ :=
  join_of_single reflexive_refl_trans_gen h.to_red

theorem eqv_gen_step_iff_join_red : EqvGen Red.Step L₁ L₂ ↔ Join Red L₁ L₂ :=
  Iff.intro
    (fun h =>
      have : EqvGen (Join Red) L₁ L₂ := h.mono fun a b => join_red_of_step
      equivalence_join_red.eqv_gen_iff.1 this)
    ((join_of_equivalence (EqvGen.is_equivalence _)) fun a b =>
      refl_trans_gen_of_equivalence (EqvGen.is_equivalence _) EqvGen.rel)

end FreeGroup

/-- The free group over a type, i.e. the words formed by the elements of the type and their formal
inverses, quotient by one step reduction. -/
def FreeGroup (α : Type u) : Type u :=
  Quot <| @FreeGroup.Red.Step α

namespace FreeGroup

variable {α} {L L₁ L₂ L₃ L₄ : List (α × Bool)}

/-- The canonical map from `list (α × bool)` to the free group on `α`. -/
def mk (L) : FreeGroup α :=
  Quot.mk Red.Step L

@[simp]
theorem quot_mk_eq_mk : Quot.mk Red.Step L = mk L :=
  rfl

@[simp]
theorem quot_lift_mk (β : Type v) (f : List (α × Bool) → β) (H : ∀ L₁ L₂, Red.Step L₁ L₂ → f L₁ = f L₂) :
    Quot.lift f H (mk L) = f L :=
  rfl

@[simp]
theorem quot_lift_on_mk (β : Type v) (f : List (α × Bool) → β) (H : ∀ L₁ L₂, Red.Step L₁ L₂ → f L₁ = f L₂) :
    Quot.liftOn (mk L) f H = f L :=
  rfl

@[simp]
theorem quot_map_mk (β : Type v) (f : List (α × Bool) → List (β × Bool)) (H : (red.step⇒red.step) f f) :
    Quot.map f H (mk L) = mk (f L) :=
  rfl

instance : One (FreeGroup α) :=
  ⟨mk []⟩

theorem one_eq_mk : (1 : FreeGroup α) = mk [] :=
  rfl

instance : Inhabited (FreeGroup α) :=
  ⟨1⟩

instance : Mul (FreeGroup α) :=
  ⟨fun x y =>
    Quot.liftOn x
      (fun L₁ => Quot.liftOn y (fun L₂ => mk <| L₁ ++ L₂) fun L₂ L₃ H => Quot.sound <| Red.Step.append_left H)
      fun L₁ L₂ H => (Quot.induction_on y) fun L₃ => Quot.sound <| Red.Step.append_right H⟩

@[simp]
theorem mul_mk : mk L₁ * mk L₂ = mk (L₁ ++ L₂) :=
  rfl

/-- Transform a word representing a free group element into a word representing its inverse. --/
def invRev (w : List (α × Bool)) : List (α × Bool) :=
  (List.map (fun g : α × Bool => (g.1, bnot g.2)) w).reverse

@[simp]
theorem inv_rev_length : (invRev L₁).length = L₁.length := by
  simp [inv_rev]

@[simp]
theorem inv_rev_inv_rev : invRev (invRev L₁) = L₁ := by
  simp [inv_rev, (· ∘ ·)]

@[simp]
theorem inv_rev_empty : invRev ([] : List (α × Bool)) = [] :=
  rfl

theorem inv_rev_involutive : Function.Involutive (@invRev α) := fun _ => inv_rev_inv_rev

theorem inv_rev_injective : Function.Injective (@invRev α) :=
  inv_rev_involutive.Injective

theorem inv_rev_surjective : Function.Surjective (@invRev α) :=
  inv_rev_involutive.Surjective

theorem inv_rev_bijective : Function.Bijective (@invRev α) :=
  inv_rev_involutive.Bijective

instance : Inv (FreeGroup α) :=
  ⟨Quot.map invRev
      (by
        intro a b h
        cases h
        simp [inv_rev])⟩

@[simp]
theorem inv_mk : (mk L)⁻¹ = mk (invRev L) :=
  rfl

theorem Red.Step.inv_rev {L₁ L₂ : List (α × Bool)} (h : Red.Step L₁ L₂) : Red.Step (invRev L₁) (invRev L₂) := by
  cases' h with a b x y
  simp [inv_rev]

theorem Red.inv_rev {L₁ L₂ : List (α × Bool)} (h : Red L₁ L₂) : Red (invRev L₁) (invRev L₂) :=
  Relation.ReflTransGen.lift _ (fun a b => Red.Step.inv_rev) h

@[simp]
theorem Red.step_inv_rev_iff : Red.Step (invRev L₁) (invRev L₂) ↔ Red.Step L₁ L₂ :=
  ⟨fun h => by
    simpa only [inv_rev_inv_rev] using h.inv_rev, fun h => h.invRev⟩

@[simp]
theorem red_inv_rev_iff : Red (invRev L₁) (invRev L₂) ↔ Red L₁ L₂ :=
  ⟨fun h => by
    simpa only [inv_rev_inv_rev] using h.inv_rev, fun h => h.invRev⟩

instance : Groupₓ (FreeGroup α) where
  mul := (· * ·)
  one := 1
  inv := Inv.inv
  mul_assoc := by
    rintro ⟨L₁⟩ ⟨L₂⟩ ⟨L₃⟩ <;> simp
  one_mul := by
    rintro ⟨L⟩ <;> rfl
  mul_one := by
    rintro ⟨L⟩ <;> simp [one_eq_mk]
  mul_left_inv := by
    rintro ⟨L⟩ <;>
      exact
        (List.recOn L rfl) fun ⟨x, b⟩ tl ih =>
          Eq.trans
            (Quot.sound <| by
              simp [inv_rev, one_eq_mk])
            ih

/-- `of` is the canonical injection from the type to the free group over that type by sending each
element to the equivalence class of the letter that is the element. -/
def of (x : α) : FreeGroup α :=
  mk [(x, true)]

theorem Red.exact : mk L₁ = mk L₂ ↔ Join Red L₁ L₂ :=
  calc
    mk L₁ = mk L₂ ↔ EqvGen Red.Step L₁ L₂ := Iff.intro (Quot.exact _) Quot.eqv_gen_sound
    _ ↔ Join Red L₁ L₂ := eqv_gen_step_iff_join_red
    

/-- The canonical injection from the type to the free group is an injection. -/
theorem of_injective : Function.Injective (@of α) := fun _ _ H => by
  let ⟨L₁, hx, hy⟩ := Red.exact.1 H
  simp [red.singleton_iff] at hx hy <;> cc

section lift

variable {β : Type v} [Groupₓ β] (f : α → β) {x y : FreeGroup α}

/-- Given `f : α → β` with `β` a group, the canonical map `list (α × bool) → β` -/
def Lift.aux : List (α × Bool) → β := fun L => List.prod <| L.map fun x => cond x.2 (f x.1) (f x.1)⁻¹

theorem Red.Step.lift {f : α → β} (H : Red.Step L₁ L₂) : Lift.aux f L₁ = Lift.aux f L₂ := by
  cases' H with _ _ _ b <;> cases b <;> simp [lift.aux]

/-- If `β` is a group, then any function from `α` to `β`
extends uniquely to a group homomorphism from
the free group over `α` to `β` -/
@[simps symmApply]
def lift : (α → β) ≃ (FreeGroup α →* β) where
  toFun := fun f =>
    MonoidHom.mk' ((Quot.lift (Lift.aux f)) fun L₁ L₂ => Red.Step.lift) <| by
      rintro ⟨L₁⟩ ⟨L₂⟩
      simp [lift.aux]
  invFun := fun g => g ∘ of
  left_inv := fun f => one_mulₓ _
  right_inv := fun g =>
    MonoidHom.ext <| by
      rintro ⟨L⟩
      apply List.recOn L
      · exact g.map_one.symm
        
      · rintro ⟨x, _ | _⟩ t (ih : _ = g (mk t))
        · show _ = g ((of x)⁻¹ * mk t)
          simpa [lift.aux] using ih
          
        · show _ = g (of x * mk t)
          simpa [lift.aux] using ih
          
        

variable {f}

@[simp]
theorem lift.mk : lift f (mk L) = List.prod (L.map fun x => cond x.2 (f x.1) (f x.1)⁻¹) :=
  rfl

@[simp]
theorem lift.of {x} : lift f (of x) = f x :=
  one_mulₓ _

theorem lift.unique (g : FreeGroup α →* β) (hg : ∀ x, g (of x) = f x) : ∀ {x}, g x = lift f x :=
  MonoidHom.congr_fun <| lift.symm_apply_eq.mp (funext hg : g ∘ of = f)

/-- Two homomorphisms out of a free group are equal if they are equal on generators.

See note [partially-applied ext lemmas]. -/
@[ext]
theorem ext_hom {G : Type _} [Groupₓ G] (f g : FreeGroup α →* G) (h : ∀ a, f (of a) = g (of a)) : f = g :=
  lift.symm.Injective <| funext h

theorem lift.of_eq (x : FreeGroup α) : lift of x = x :=
  MonoidHom.congr_fun (lift.apply_symm_apply (MonoidHom.id _)) x

theorem lift.range_le {s : Subgroup β} (H : Set.Range f ⊆ s) : (lift f).range ≤ s := by
  rintro _ ⟨⟨L⟩, rfl⟩ <;>
    exact
      List.recOn L s.one_mem fun ⟨x, b⟩ tl ih =>
        Bool.recOn b
          (by
            simp at ih⊢ <;> exact s.mul_mem (s.inv_mem <| H ⟨x, rfl⟩) ih)
          (by
            simp at ih⊢ <;> exact s.mul_mem (H ⟨x, rfl⟩) ih)

theorem lift.range_eq_closure : (lift f).range = Subgroup.closure (Set.Range f) := by
  apply le_antisymmₓ (lift.range_le Subgroup.subset_closure)
  rw [Subgroup.closure_le]
  rintro _ ⟨a, rfl⟩
  exact
    ⟨of a, by
      simp only [lift.of]⟩

end lift

section Map

variable {β : Type v} (f : α → β) {x y : FreeGroup α}

/-- Any function from `α` to `β` extends uniquely
to a group homomorphism from the free group
ver `α` to the free group over `β`. -/
def map : FreeGroup α →* FreeGroup β :=
  MonoidHom.mk'
    ((Quot.map (List.map fun x => (f x.1, x.2))) fun L₁ L₂ H => by
      cases H <;> simp )
    (by
      rintro ⟨L₁⟩ ⟨L₂⟩
      simp )

variable {f}

@[simp]
theorem map.mk : map f (mk L) = mk (L.map fun x => (f x.1, x.2)) :=
  rfl

@[simp]
theorem map.id (x : FreeGroup α) : map id x = x := by
  rcases x with ⟨L⟩ <;> simp [List.map_id']

@[simp]
theorem map.id' (x : FreeGroup α) : map (fun z => z) x = x :=
  map.id x

theorem map.comp {γ : Type w} (f : α → β) (g : β → γ) (x) : map g (map f x) = map (g ∘ f) x := by
  rcases x with ⟨L⟩ <;> simp

@[simp]
theorem map.of {x} : map f (of x) = of (f x) :=
  rfl

theorem map.unique (g : FreeGroup α →* FreeGroup β) (hg : ∀ x, g (of x) = of (f x)) : ∀ {x}, g x = map f x := by
  rintro ⟨L⟩ <;>
    exact
      List.recOn L g.map_one fun ⟨x, b⟩ t (ih : g (mk t) = map f (mk t)) =>
        Bool.recOn b
          (show g ((of x)⁻¹ * mk t) = map f ((of x)⁻¹ * mk t) by
            simp [g.map_mul, g.map_inv, hg, ih])
          (show g (of x * mk t) = map f (of x * mk t) by
            simp [g.map_mul, hg, ih])

theorem map_eq_lift : map f x = lift (of ∘ f) x :=
  Eq.symm <|
    (map.unique _) fun x => by
      simp

/-- Equivalent types give rise to multiplicatively equivalent free groups.

The converse can be found in `group_theory.free_abelian_group_finsupp`,
as `equiv.of_free_group_equiv`
 -/
@[simps apply]
def freeGroupCongr {α β} (e : α ≃ β) : FreeGroup α ≃* FreeGroup β where
  toFun := map e
  invFun := map e.symm
  left_inv := fun x => by
    simp [Function.comp, map.comp]
  right_inv := fun x => by
    simp [Function.comp, map.comp]
  map_mul' := MonoidHom.map_mul _

@[simp]
theorem free_group_congr_refl : freeGroupCongr (Equivₓ.refl α) = MulEquiv.refl _ :=
  MulEquiv.ext map.id

@[simp]
theorem free_group_congr_symm {α β} (e : α ≃ β) : (freeGroupCongr e).symm = freeGroupCongr e.symm :=
  rfl

theorem free_group_congr_trans {α β γ} (e : α ≃ β) (f : β ≃ γ) :
    (freeGroupCongr e).trans (freeGroupCongr f) = freeGroupCongr (e.trans f) :=
  MulEquiv.ext <| map.comp _ _

end Map

section Prod

variable [Groupₓ α] (x y : FreeGroup α)

/-- If `α` is a group, then any function from `α` to `α`
extends uniquely to a homomorphism from the
free group over `α` to `α`. This is the multiplicative
version of `sum`. -/
def prod : FreeGroup α →* α :=
  lift id

variable {x y}

@[simp]
theorem prod_mk : prod (mk L) = List.prod (L.map fun x => cond x.2 x.1 x.1⁻¹) :=
  rfl

@[simp]
theorem prod.of {x : α} : prod (of x) = x :=
  lift.of

theorem prod.unique (g : FreeGroup α →* α) (hg : ∀ x, g (of x) = x) {x} : g x = prod x :=
  lift.unique g hg

end Prod

theorem lift_eq_prod_map {β : Type v} [Groupₓ β] {f : α → β} {x} : lift f x = prod (map f x) := by
  rw [← lift.unique (prod.comp (map f))]
  · rfl
    
  · simp
    

section Sum

variable [AddGroupₓ α] (x y : FreeGroup α)

/-- If `α` is a group, then any function from `α` to `α`
extends uniquely to a homomorphism from the
free group over `α` to `α`. This is the additive
version of `prod`. -/
def sum : α :=
  @prod (Multiplicative _) _ x

variable {x y}

@[simp]
theorem sum_mk : sum (mk L) = List.sum (L.map fun x => cond x.2 x.1 (-x.1)) :=
  rfl

@[simp]
theorem sum.of {x : α} : sum (of x) = x :=
  prod.of

-- note: there are no bundled homs with different notation in the domain and codomain, so we copy
-- these manually
@[simp]
theorem sum.map_mul : sum (x * y) = sum x + sum y :=
  (@prod (Multiplicative _) _).map_mul _ _

@[simp]
theorem sum.map_one : sum (1 : FreeGroup α) = 0 :=
  (@prod (Multiplicative _) _).map_one

@[simp]
theorem sum.map_inv : sum x⁻¹ = -sum x :=
  (prod : FreeGroup (Multiplicative α) →* Multiplicative α).map_inv _

end Sum

/-- The bijection between the free group on the empty type, and a type with one element. -/
def freeGroupEmptyEquivUnit : FreeGroup Empty ≃ Unit where
  toFun := fun _ => ()
  invFun := fun _ => 1
  left_inv := by
    rintro ⟨_ | ⟨⟨⟨⟩, _⟩, _⟩⟩ <;> rfl
  right_inv := fun ⟨⟩ => rfl

/-- The bijection between the free group on a singleton, and the integers. -/
def freeGroupUnitEquivInt : FreeGroup Unit ≃ ℤ where
  toFun := fun x =>
    sum
      (by
        revert x
        apply MonoidHom.toFun
        apply map fun _ => (1 : ℤ))
  invFun := fun x => of () ^ x
  left_inv := by
    rintro ⟨L⟩
    refine' List.recOn L rfl _
    exact fun ⟨⟨⟩, b⟩ tl ih => by
      cases b <;> simp [zpow_add] at ih⊢ <;> rw [ih] <;> rfl
  right_inv := fun x =>
    Int.induction_on x
      (by
        simp )
      (fun i ih => by
        simp at ih <;> simp [zpow_add, ih])
      fun i ih => by
      simp at ih <;> simp [zpow_add, ih, sub_eq_add_neg, -Int.add_neg_one]

section Category

variable {β : Type u}

instance : Monadₓ FreeGroup.{u} where
  pure := fun α => of
  map := fun α β f => map f
  bind := fun α β x f => lift f x

@[elabAsElim]
protected theorem induction_on {C : FreeGroup α → Prop} (z : FreeGroup α) (C1 : C 1) (Cp : ∀ x, C <| pure x)
    (Ci : ∀ x, C (pure x) → C (pure x)⁻¹) (Cm : ∀ x y, C x → C y → C (x * y)) : C z :=
  (Quot.induction_on z) fun L =>
    (List.recOn L C1) fun ⟨x, b⟩ tl ih => Bool.recOn b (Cm _ _ (Ci _ <| Cp x) ih) (Cm _ _ (Cp x) ih)

@[simp]
theorem map_pure (f : α → β) (x : α) : f <$> (pure x : FreeGroup α) = pure (f x) :=
  map.of

@[simp]
theorem map_one (f : α → β) : f <$> (1 : FreeGroup α) = 1 :=
  (map f).map_one

@[simp]
theorem map_mul (f : α → β) (x y : FreeGroup α) : f <$> (x * y) = f <$> x * f <$> y :=
  (map f).map_mul x y

@[simp]
theorem map_inv (f : α → β) (x : FreeGroup α) : f <$> x⁻¹ = (f <$> x)⁻¹ :=
  (map f).map_inv x

@[simp]
theorem pure_bind (f : α → FreeGroup β) (x) : pure x >>= f = f x :=
  lift.of

@[simp]
theorem one_bind (f : α → FreeGroup β) : 1 >>= f = 1 :=
  (lift f).map_one

@[simp]
theorem mul_bind (f : α → FreeGroup β) (x y : FreeGroup α) : x * y >>= f = (x >>= f) * (y >>= f) :=
  (lift f).map_mul _ _

@[simp]
theorem inv_bind (f : α → FreeGroup β) (x : FreeGroup α) : x⁻¹ >>= f = (x >>= f)⁻¹ :=
  (lift f).map_inv _

instance : IsLawfulMonad FreeGroup.{u} where
  id_map := fun α x =>
    FreeGroup.induction_on x (map_one id) (fun x => map_pure id x)
      (fun x ih => by
        rw [map_inv, ih])
      fun x y ihx ihy => by
      rw [map_mul, ihx, ihy]
  pure_bind := fun α β x f => pure_bind f x
  bind_assoc := fun α β γ x f g =>
    FreeGroup.induction_on x
      (by
        iterate 3 
          rw [one_bind])
      (fun x => by
        iterate 2 
          rw [pure_bind])
      (fun x ih => by
        iterate 3 
            rw [inv_bind] <;>
          rw [ih])
      fun x y ihx ihy => by
      iterate 3 
          rw [mul_bind] <;>
        rw [ihx, ihy]
  bind_pure_comp_eq_map := fun α β f x =>
    FreeGroup.induction_on x
      (by
        rw [one_bind, map_one])
      (fun x => by
        rw [pure_bind, map_pure])
      (fun x ih => by
        rw [inv_bind, map_inv, ih])
      fun x y ihx ihy => by
      rw [mul_bind, map_mul, ihx, ihy]

end Category

section Reduce

variable [DecidableEq α]

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- The maximal reduction of a word. It is computable
iff `α` has decidable equality. -/
def reduce (L : List (α × Bool)) : List (α × Bool) :=
  (List.recOn L []) fun hd1 tl1 ih =>
    (List.casesOn ih [hd1]) fun hd2 tl2 => if hd1.1 = hd2.1 ∧ hd1.2 = bnot hd2.2 then tl2 else hd1::hd2::tl2

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem reduce.cons (x) :
    reduce (x::L) = List.casesOn (reduce L) [x] fun hd tl => if x.1 = hd.1 ∧ x.2 = bnot hd.2 then tl else x::hd::tl :=
  rfl

/-- The first theorem that characterises the function
`reduce`: a word reduces to its maximal reduction. -/
theorem reduce.red : Red L (reduce L) := by
  induction' L with hd1 tl1 ih
  case list.nil =>
    constructor
  case list.cons =>
    dsimp'
    revert ih
    generalize htl : reduce tl1 = TL
    intro ih
    cases' TL with hd2 tl2
    case list.nil =>
      exact red.cons_cons ih
    case list.cons =>
      dsimp'
      by_cases' h : hd1.fst = hd2.fst ∧ hd1.snd = bnot hd2.snd
      · rw [if_pos h]
        trans
        · exact red.cons_cons ih
          
        · cases hd1
          cases hd2
          cases h
          dsimp'  at *
          subst_vars
          exact red.step.cons_bnot_rev.to_red
          
        
      · rw [if_neg h]
        exact red.cons_cons ih
        

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/- failed to parenthesize: parenthesize: uncaught backtrack exception
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
      (Term.byTactic
       "by"
       (Tactic.tacticSeq
        (Tactic.tacticSeq1Indented
         [(group (Tactic.dsimp' "dsimp'" [] [] [] [] []) [])
          (group (Tactic.cases "cases" [(Tactic.casesTarget [`r ":"] (Term.app `reduce [`L1]))] [] []) [])
          (group
           («tactic·.__;_»
            "·"
            [(group (Tactic.dsimp' "dsimp'" [] [] [] [] []) [])
             (group (Tactic.intro "intro" [`h]) [])
             (group
              (Tactic.tacticHave_
               "have"
               (Term.haveDecl (Term.haveIdDecl [] [] ":=" (Term.app `congr_argₓ [`List.length `h]))))
              [])
             (group
              (Tactic.simp
               "simp"
               []
               []
               []
               ["[" [(Tactic.simpErase "-" `add_commₓ)] "]"]
               [(Tactic.location "at" (Tactic.locationHyp [`this] []))])
              [])
             (group
              (Tactic.exact
               "exact"
               (Term.app
                `absurd
                [`this
                 (Term.byTactic
                  "by"
                  (Tactic.tacticSeq (Tactic.tacticSeq1Indented [(group (Tactic.decide "decide") [])])))]))
              [])])
           [])
          (group
           (Tactic.cases'
            "cases'"
            [(Tactic.casesTarget [] `hd)]
            []
            ["with" [(Lean.binderIdent `y) (Lean.binderIdent `c)]])
           [])
          (group
           (Tactic.«tactic_<;>_»
            (Tactic.byCases'
             "by_cases'"
             []
             («term_∧_» («term_=_» `x "=" `y) "∧" («term_=_» `b "=" (Term.app `bnot [`c]))))
            "<;>"
            (Tactic.«tactic_<;>_»
             (Tactic.simp "simp" [] [] [] ["[" [(Tactic.simpLemma [] [] `h)] "]"] [])
             "<;>"
             (Tactic.intro "intro" [`H])))
           [])
          (group
           («tactic·.__;_»
            "·"
            [(group
              (Tactic.rwSeq
               "rw"
               []
               (Tactic.rwRuleSeq "[" [(Tactic.rwRule [] `H)] "]")
               [(Tactic.location "at" (Tactic.locationHyp [`r] []))])
              [])
             (group
              (Tactic.exact
               "exact"
               (Term.app
                (Term.explicit "@" `reduce.not)
                [`L1
                 (Sym.Data.Sym.Basic.sym.cons' (Term.paren "(" [`y [(Term.tupleTail "," [`c])]] ")") "::" `L2)
                 `L3
                 `x'
                 `b'
                 `r]))
              [])])
           [])
          (group
           (Mathlib.Tactic.rcases
            "rcases"
            [(Tactic.casesTarget [] `L2)]
            ["with"
             (Tactic.rcasesPatLo
              (Tactic.rcasesPatMed
               [(Tactic.rcasesPat.paren
                 "("
                 (Tactic.rcasesPatLo
                  (Tactic.rcasesPatMed
                   [(Tactic.rcasesPat.ignore "_")
                    "|"
                    (Tactic.rcasesPat.tuple
                     "⟨"
                     [(Tactic.rcasesPatLo (Tactic.rcasesPatMed [(Tactic.rcasesPat.one `a)]) [])
                      ","
                      (Tactic.rcasesPatLo (Tactic.rcasesPatMed [(Tactic.rcasesPat.one `L2)]) [])]
                     "⟩")])
                  [])
                 ")")])
              [])])
           [])
          (group
           («tactic·.__;_»
            "·"
            [(group (Tactic.injections' "injections" []) [])
             (group (Tactic.substVars "subst_vars") [])
             (group (Tactic.simp "simp" [] [] [] [] [(Tactic.location "at" (Tactic.locationHyp [`h] []))]) [])
             (group (Tactic.cc "cc") [])])
           [])
          (group
           («tactic·.__;_»
            "·"
            [(group
              (Tactic.refine'
               "refine'"
               (Term.app (Term.explicit "@" `reduce.not) [`L1 `L2 `L3 `x' `b' (Term.hole "_")]))
              [])
             (group (Tactic.injection "injection" `H ["with" ["_" `H]]) [])
             (group
              (Tactic.rwSeq "rw" [] (Tactic.rwRuleSeq "[" [(Tactic.rwRule [] `r) "," (Tactic.rwRule [] `H)] "]") [])
              [])
             (group (Tactic.tacticRfl "rfl") [])])
           [])])))
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
      («tactic·.__;_»
       "·"
       [(group
         (Tactic.refine' "refine'" (Term.app (Term.explicit "@" `reduce.not) [`L1 `L2 `L3 `x' `b' (Term.hole "_")]))
         [])
        (group (Tactic.injection "injection" `H ["with" ["_" `H]]) [])
        (group
         (Tactic.rwSeq "rw" [] (Tactic.rwRuleSeq "[" [(Tactic.rwRule [] `r) "," (Tactic.rwRule [] `H)] "]") [])
         [])
        (group (Tactic.tacticRfl "rfl") [])])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
      (Tactic.tacticRfl "rfl")
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1023, tactic))
      (Tactic.rwSeq "rw" [] (Tactic.rwRuleSeq "[" [(Tactic.rwRule [] `r) "," (Tactic.rwRule [] `H)] "]") [])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
      `H
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] parenthesizing (cont := (none, [anonymous]))
      `r
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1024, (none, [anonymous]) <=? (none, [anonymous])
[PrettyPrinter.parenthesize] ...precedences are 0 >? 1022
[PrettyPrinter.parenthesize] parenthesizing (cont := (some 1022, tactic))
      (Tactic.injection "injection" `H ["with" ["_" `H]])-/-- failed to format: format: uncaught backtrack exception
theorem
  reduce.not
  { p : Prop } : ∀ { L₁ L₂ L₃ : List α × Bool } { x b } , reduce L₁ = L₂ ++ ( x , b ) :: ( x , bnot b ) :: L₃ → p
  | [ ] , L2 , L3 , _ , _ => fun h => by cases L2 <;> injections
    |
      ( x , b ) :: L1 , L2 , L3 , x' , b'
      =>
      by
        dsimp'
          cases r : reduce L1
          · dsimp' intro h have := congr_argₓ List.length h simp [ - add_commₓ ] at this exact absurd this by decide
          cases' hd with y c
          by_cases' x = y ∧ b = bnot c <;> simp [ h ] <;> intro H
          · rw [ H ] at r exact @ reduce.not L1 ( y , c ) :: L2 L3 x' b' r
          rcases L2 with ( _ | ⟨ a , L2 ⟩ )
          · injections subst_vars simp at h cc
          · refine' @ reduce.not L1 L2 L3 x' b' _ injection H with _ H rw [ r , H ] rfl

/-- The second theorem that characterises the
function `reduce`: the maximal reduction of a word
only reduces to itself. -/
theorem reduce.min (H : Red (reduce L₁) L₂) : reduce L₁ = L₂ := by
  induction' H with L1 L' L2 H1 H2 ih
  · rfl
    
  · cases' H1 with L4 L5 x b
    exact reduce.not H2
    

/-- `reduce` is idempotent, i.e. the maximal reduction
of the maximal reduction of a word is the maximal
reduction of the word. -/
@[simp]
theorem reduce.idem : reduce (reduce L) = reduce L :=
  Eq.symm <| reduce.min reduce.red

theorem reduce.Step.eq (H : Red.Step L₁ L₂) : reduce L₁ = reduce L₂ :=
  let ⟨L₃, HR13, HR23⟩ := Red.church_rosser reduce.red (reduce.red.head H)
  (reduce.min HR13).trans (reduce.min HR23).symm

/-- If a word reduces to another word, then they have
a common maximal reduction. -/
theorem reduce.eq_of_red (H : Red L₁ L₂) : reduce L₁ = reduce L₂ :=
  let ⟨L₃, HR13, HR23⟩ := Red.church_rosser reduce.red (Red.trans H reduce.red)
  (reduce.min HR13).trans (reduce.min HR23).symm

alias reduce.eq_of_red ← red.reduce_eq

theorem Red.reduce_right (h : Red L₁ L₂) : Red L₁ (reduce L₂) :=
  reduce.eq_of_red h ▸ reduce.red

theorem Red.reduce_left (h : Red L₁ L₂) : Red L₂ (reduce L₁) :=
  (reduce.eq_of_red h).symm ▸ reduce.red

/-- If two words correspond to the same element in
the free group, then they have a common maximal
reduction. This is the proof that the function that
sends an element of the free group to its maximal
reduction is well-defined. -/
theorem reduce.sound (H : mk L₁ = mk L₂) : reduce L₁ = reduce L₂ :=
  let ⟨L₃, H13, H23⟩ := Red.exact.1 H
  (reduce.eq_of_red H13).trans (reduce.eq_of_red H23).symm

/-- If two words have a common maximal reduction,
then they correspond to the same element in the free group. -/
theorem reduce.exact (H : reduce L₁ = reduce L₂) : mk L₁ = mk L₂ :=
  Red.exact.2 ⟨reduce L₂, H ▸ reduce.red, reduce.red⟩

/-- A word and its maximal reduction correspond to
the same element of the free group. -/
theorem reduce.self : mk (reduce L) = mk L :=
  reduce.exact reduce.idem

/-- If words `w₁ w₂` are such that `w₁` reduces to `w₂`,
then `w₂` reduces to the maximal reduction of `w₁`. -/
theorem reduce.rev (H : Red L₁ L₂) : Red L₂ (reduce L₁) :=
  (reduce.eq_of_red H).symm ▸ reduce.red

/-- The function that sends an element of the free
group to its maximal reduction. -/
def toWord : FreeGroup α → List (α × Bool) :=
  (Quot.lift reduce) fun L₁ L₂ H => reduce.Step.eq H

theorem mk_to_word : ∀ {x : FreeGroup α}, mk (toWord x) = x := by
  rintro ⟨L⟩ <;> exact reduce.self

theorem to_word_injective : Function.Injective (toWord : FreeGroup α → List (α × Bool)) := by
  rintro ⟨L₁⟩ ⟨L₂⟩ <;> exact reduce.exact

@[simp]
theorem to_word_inj {x y : FreeGroup α} : toWord x = toWord y ↔ x = y :=
  to_word_injective.eq_iff

@[simp]
theorem to_word_mk : (mk L₁).toWord = reduce L₁ :=
  rfl

@[simp]
theorem reduce_to_word : ∀ x : FreeGroup α, reduce (toWord x) = toWord x := by
  rintro ⟨L⟩
  exact reduce.idem

@[simp]
theorem to_word_one : (1 : FreeGroup α).toWord = [] :=
  rfl

@[simp]
theorem to_word_eq_nil_iff {x : FreeGroup α} : x.toWord = [] ↔ x = 1 :=
  to_word_injective.eq_iff' to_word_one

theorem reduce_inv_rev {w : List (α × Bool)} : reduce (invRev w) = invRev (reduce w) := by
  apply reduce.min
  rw [← red_inv_rev_iff, inv_rev_inv_rev]
  apply red.reduce_left
  have : red (inv_rev (inv_rev w)) (inv_rev (reduce (inv_rev w))) := reduce.red.inv_rev
  rwa [inv_rev_inv_rev] at this

theorem to_word_inv {x : FreeGroup α} : x⁻¹.toWord = invRev x.toWord := by
  rcases x with ⟨L⟩
  rw [quot_mk_eq_mk, inv_mk, to_word_mk, to_word_mk, reduce_inv_rev]

/-- Constructive Church-Rosser theorem (compare `church_rosser`). -/
def reduce.churchRosser (H12 : Red L₁ L₂) (H13 : Red L₁ L₃) : { L₄ // Red L₂ L₄ ∧ Red L₃ L₄ } :=
  ⟨reduce L₁, reduce.rev H12, reduce.rev H13⟩

instance : DecidableEq (FreeGroup α) :=
  to_word_injective.DecidableEq

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
instance Red.decidableRel : DecidableRel (@Red α)
  | [], [] => isTrue Red.refl
  | [], hd2::tl2 => is_false fun H => List.noConfusion (Red.nil_iff.1 H)
  | (x, b)::tl, [] =>
    match red.decidable_rel tl [(x, bnot b)] with
    | is_true H => is_true <| Red.trans (Red.cons_cons H) <| (@Red.Step.bnot _ [] [] _ _).to_red
    | is_false H => is_false fun H2 => H <| Red.cons_nil_iff_singleton.1 H2
  | (x1, b1)::tl1, (x2, b2)::tl2 =>
    if h : (x1, b1) = (x2, b2) then
      match red.decidable_rel tl1 tl2 with
      | is_true H => is_true <| h ▸ Red.cons_cons H
      | is_false H => is_false fun H2 => H <| h ▸ (Red.cons_cons_iff _).1 <| H2
    else
      match red.decidable_rel tl1 ((x1, bnot b1)::(x2, b2)::tl2) with
      | is_true H => is_true <| (Red.cons_cons H).tail Red.Step.cons_bnot
      | is_false H => is_false fun H2 => H <| Red.inv_of_red_of_ne h H2

/-- A list containing every word that `w₁` reduces to. -/
def Red.enum (L₁ : List (α × Bool)) : List (List (α × Bool)) :=
  List.filterₓ (fun L₂ => Red L₁ L₂) (List.sublists L₁)

theorem Red.enum.sound (H : L₂ ∈ Red.enum L₁) : Red L₁ L₂ :=
  List.of_mem_filter H

theorem Red.enum.complete (H : Red L₁ L₂) : L₂ ∈ Red.enum L₁ :=
  List.mem_filter_of_mem (List.mem_sublists.2 <| Red.sublist H) H

instance : Fintype { L₂ // Red L₁ L₂ } :=
  (Fintype.subtype (List.toFinset <| Red.enum L₁)) fun L₂ =>
    ⟨fun H => red.enum.sound <| List.mem_to_finset.1 H, fun H => List.mem_to_finset.2 <| Red.enum.complete H⟩

end Reduce

section Metric

variable [DecidableEq α]

/-- The length of reduced words provides a norm on a free group. --/
def norm (x : FreeGroup α) : ℕ :=
  x.toWord.length

@[simp]
theorem norm_inv_eq {x : FreeGroup α} : norm x⁻¹ = norm x := by
  simp only [norm, to_word_inv, inv_rev_length]

@[simp]
theorem norm_eq_zero {x : FreeGroup α} : norm x = 0 ↔ x = 1 := by
  simp only [norm, List.length_eq_zero, to_word_eq_nil_iff]

@[simp]
theorem norm_one : norm (1 : FreeGroup α) = 0 :=
  rfl

theorem norm_mk_le : norm (mk L₁) ≤ L₁.length :=
  reduce.red.length_le

theorem norm_mul_le (x y : FreeGroup α) : norm (x * y) ≤ norm x + norm y :=
  calc
    norm (x * y) = norm (mk (x.toWord ++ y.toWord)) := by
      rw [← mul_mk, mk_to_word, mk_to_word]
    _ ≤ (x.toWord ++ y.toWord).length := norm_mk_le
    _ = norm x + norm y := List.length_append _ _
    

end Metric

end FreeGroup

