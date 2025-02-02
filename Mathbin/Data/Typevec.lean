/-
Copyright (c) 2018 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Mario Carneiro, Simon Hudon
-/
import Mathbin.Data.Fin.Fin2
import Mathbin.Logic.Function.Basic
import Mathbin.Tactic.Basic

/-!

# Tuples of types, and their categorical structure.

## Features

* `typevec n` - n-tuples of types
* `α ⟹ β`    - n-tuples of maps
* `f ⊚ g`     - composition

Also, support functions for operating with n-tuples of types, such as:

* `append1 α β`    - append type `β` to n-tuple `α` to obtain an (n+1)-tuple
* `drop α`         - drops the last element of an (n+1)-tuple
* `last α`         - returns the last element of an (n+1)-tuple
* `append_fun f g` - appends a function g to an n-tuple of functions
* `drop_fun f`     - drops the last function from an n+1-tuple
* `last_fun f`     - returns the last function of a tuple.

Since e.g. `append1 α.drop α.last` is propositionally equal to `α` but not definitionally equal
to it, we need support functions and lemmas to mediate between constructions.
-/


universe u v w

/-- n-tuples of types, as a category
-/
def Typevec (n : ℕ) :=
  Fin2 n → Type _

instance {n} : Inhabited (Typevec.{u} n) :=
  ⟨fun _ => PUnit⟩

namespace Typevec

variable {n : ℕ}

/-- arrow in the category of `typevec` -/
def Arrow (α β : Typevec n) :=
  ∀ i : Fin2 n, α i → β i

-- mathport name: typevec.arrow
localized [Mvfunctor] infixl:40 " ⟹ " => Typevec.Arrow

instance Arrow.inhabited (α β : Typevec n) [∀ i, Inhabited (β i)] : Inhabited (α ⟹ β) :=
  ⟨fun _ _ => default⟩

/-- identity of arrow composition -/
def id {α : Typevec n} : α ⟹ α := fun i x => x

/-- arrow composition in the category of `typevec` -/
def comp {α β γ : Typevec n} (g : β ⟹ γ) (f : α ⟹ β) : α ⟹ γ := fun i x => g i (f i x)

-- mathport name: typevec.comp
localized [Mvfunctor] infixr:80 " ⊚ " => Typevec.comp

-- type as \oo
@[simp]
theorem id_comp {α β : Typevec n} (f : α ⟹ β) : id ⊚ f = f :=
  rfl

@[simp]
theorem comp_id {α β : Typevec n} (f : α ⟹ β) : f ⊚ id = f :=
  rfl

theorem comp_assoc {α β γ δ : Typevec n} (h : γ ⟹ δ) (g : β ⟹ γ) (f : α ⟹ β) : (h ⊚ g) ⊚ f = h ⊚ g ⊚ f :=
  rfl

/-- Support for extending a typevec by one element.
-/
def Append1 (α : Typevec n) (β : Type _) : Typevec (n + 1)
  | Fin2.fs i => α i
  | Fin2.fz => β

-- mathport name: typevec.append1
infixl:67 " ::: " => Append1

/-- retain only a `n-length` prefix of the argument -/
def Drop (α : Typevec.{u} (n + 1)) : Typevec n := fun i => α i.fs

/-- take the last value of a `(n+1)-length` vector -/
def Last (α : Typevec.{u} (n + 1)) : Type _ :=
  α Fin2.fz

instance Last.inhabited (α : Typevec (n + 1)) [Inhabited (α Fin2.fz)] : Inhabited (Last α) :=
  ⟨show α Fin2.fz from default⟩

theorem drop_append1 {α : Typevec n} {β : Type _} {i : Fin2 n} : Drop (Append1 α β) i = α i :=
  rfl

theorem drop_append1' {α : Typevec n} {β : Type _} : Drop (Append1 α β) = α := by
  ext <;> apply drop_append1

theorem last_append1 {α : Typevec n} {β : Type _} : Last (Append1 α β) = β :=
  rfl

@[simp]
theorem append1_drop_last (α : Typevec (n + 1)) : Append1 (Drop α) (Last α) = α :=
  funext fun i => by
    cases i <;> rfl

/-- cases on `(n+1)-length` vectors -/
@[elabAsElim]
def append1Cases {C : Typevec (n + 1) → Sort u} (H : ∀ α β, C (Append1 α β)) (γ) : C γ := by
  rw [← @append1_drop_last _ γ] <;> apply H

@[simp]
theorem append1_cases_append1 {C : Typevec (n + 1) → Sort u} (H : ∀ α β, C (Append1 α β)) (α β) :
    @append1Cases _ C H (Append1 α β) = H α β :=
  rfl

/-- append an arrow and a function for arbitrary source and target
type vectors -/
def splitFun {α α' : Typevec (n + 1)} (f : Drop α ⟹ Drop α') (g : Last α → Last α') : α ⟹ α'
  | Fin2.fs i => f i
  | Fin2.fz => g

/-- append an arrow and a function as well as their respective source
and target types / typevecs -/
def appendFun {α α' : Typevec n} {β β' : Type _} (f : α ⟹ α') (g : β → β') : Append1 α β ⟹ Append1 α' β' :=
  splitFun f g

-- mathport name: typevec.append_fun
infixl:0 " ::: " => appendFun

/-- split off the prefix of an arrow -/
def dropFun {α β : Typevec (n + 1)} (f : α ⟹ β) : Drop α ⟹ Drop β := fun i => f i.fs

/-- split off the last function of an arrow -/
def lastFun {α β : Typevec (n + 1)} (f : α ⟹ β) : Last α → Last β :=
  f Fin2.fz

/-- arrow in the category of `0-length` vectors -/
def nilFun {α : Typevec 0} {β : Typevec 0} : α ⟹ β := fun i => Fin2.elim0 i

-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:63:9: parse error
theorem eq_of_drop_last_eq {α β : Typevec (n + 1)} {f g : α ⟹ β} (h₀ : dropFun f = dropFun g)
    (h₁ : lastFun f = lastFun g) : f = g := by
  replace h₀ := congr_funₓ h₀ <;> ext1 (ieq | ⟨j, ieq⟩) <;> apply_assumption

@[simp]
theorem drop_fun_split_fun {α α' : Typevec (n + 1)} (f : Drop α ⟹ Drop α') (g : Last α → Last α') :
    dropFun (splitFun f g) = f :=
  rfl

/-- turn an equality into an arrow -/
def Arrow.mp {α β : Typevec n} (h : α = β) : α ⟹ β
  | i => Eq.mp (congr_funₓ h _)

/-- turn an equality into an arrow, with reverse direction -/
def Arrow.mpr {α β : Typevec n} (h : α = β) : β ⟹ α
  | i => Eq.mpr (congr_funₓ h _)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- decompose a vector into its prefix appended with its last element -/
def toAppend1DropLast {α : Typevec (n + 1)} : α ⟹ (Drop α ::: Last α) :=
  Arrow.mpr (append1_drop_last _)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- stitch two bits of a vector back together -/
def fromAppend1DropLast {α : Typevec (n + 1)} : (Drop α ::: Last α) ⟹ α :=
  Arrow.mp (append1_drop_last _)

@[simp]
theorem last_fun_split_fun {α α' : Typevec (n + 1)} (f : Drop α ⟹ Drop α') (g : Last α → Last α') :
    lastFun (splitFun f g) = g :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem drop_fun_append_fun {α α' : Typevec n} {β β' : Type _} (f : α ⟹ α') (g : β → β') : dropFun (f ::: g) = f :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem last_fun_append_fun {α α' : Typevec n} {β β' : Type _} (f : α ⟹ α') (g : β → β') : lastFun (f ::: g) = g :=
  rfl

theorem split_drop_fun_last_fun {α α' : Typevec (n + 1)} (f : α ⟹ α') : splitFun (dropFun f) (lastFun f) = f :=
  eq_of_drop_last_eq rfl rfl

theorem split_fun_inj {α α' : Typevec (n + 1)} {f f' : Drop α ⟹ Drop α'} {g g' : Last α → Last α'}
    (H : splitFun f g = splitFun f' g') : f = f' ∧ g = g' := by
  rw [← drop_fun_split_fun f g, H, ← last_fun_split_fun f g, H] <;> simp

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_inj {α α' : Typevec n} {β β' : Type _} {f f' : α ⟹ α'} {g g' : β → β'} :
    (f ::: g) = (f' ::: g') → f = f' ∧ g = g' :=
  split_fun_inj

theorem split_fun_comp {α₀ α₁ α₂ : Typevec (n + 1)} (f₀ : Drop α₀ ⟹ Drop α₁) (f₁ : Drop α₁ ⟹ Drop α₂)
    (g₀ : Last α₀ → Last α₁) (g₁ : Last α₁ → Last α₂) :
    splitFun (f₁ ⊚ f₀) (g₁ ∘ g₀) = splitFun f₁ g₁ ⊚ splitFun f₀ g₀ :=
  eq_of_drop_last_eq rfl rfl

theorem append_fun_comp_split_fun {α γ : Typevec n} {β δ : Type _} {ε : Typevec (n + 1)} (f₀ : Drop ε ⟹ α) (f₁ : α ⟹ γ)
    (g₀ : Last ε → β) (g₁ : β → δ) : appendFun f₁ g₁ ⊚ splitFun f₀ g₀ = splitFun (f₁ ⊚ f₀) (g₁ ∘ g₀) :=
  (split_fun_comp _ _ _ _).symm

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_comp {α₀ α₁ α₂ : Typevec n} {β₀ β₁ β₂ : Type _} (f₀ : α₀ ⟹ α₁) (f₁ : α₁ ⟹ α₂) (g₀ : β₀ → β₁)
    (g₁ : β₁ → β₂) : (f₁ ⊚ f₀ ::: g₁ ∘ g₀) = (f₁ ::: g₁) ⊚ (f₀ ::: g₀) :=
  eq_of_drop_last_eq rfl rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_comp' {α₀ α₁ α₂ : Typevec n} {β₀ β₁ β₂ : Type _} (f₀ : α₀ ⟹ α₁) (f₁ : α₁ ⟹ α₂) (g₀ : β₀ → β₁)
    (g₁ : β₁ → β₂) : (f₁ ::: g₁) ⊚ (f₀ ::: g₀) = (f₁ ⊚ f₀ ::: g₁ ∘ g₀) :=
  eq_of_drop_last_eq rfl rfl

theorem nil_fun_comp {α₀ : Typevec 0} (f₀ : α₀ ⟹ Fin2.elim0) : nil_fun ⊚ f₀ = f₀ :=
  funext fun x => Fin2.elim0 x

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_comp_id {α : Typevec n} {β₀ β₁ β₂ : Type _} (g₀ : β₀ → β₁) (g₁ : β₁ → β₂) :
    (@id _ α ::: g₁ ∘ g₀) = (id ::: g₁) ⊚ (id ::: g₀) :=
  eq_of_drop_last_eq rfl rfl

@[simp]
theorem drop_fun_comp {α₀ α₁ α₂ : Typevec (n + 1)} (f₀ : α₀ ⟹ α₁) (f₁ : α₁ ⟹ α₂) :
    dropFun (f₁ ⊚ f₀) = dropFun f₁ ⊚ dropFun f₀ :=
  rfl

@[simp]
theorem last_fun_comp {α₀ α₁ α₂ : Typevec (n + 1)} (f₀ : α₀ ⟹ α₁) (f₁ : α₁ ⟹ α₂) :
    lastFun (f₁ ⊚ f₀) = lastFun f₁ ∘ lastFun f₀ :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_aux {α α' : Typevec n} {β β' : Type _} (f : (α ::: β) ⟹ (α' ::: β')) :
    (dropFun f ::: lastFun f) = f :=
  eq_of_drop_last_eq rfl rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_fun_id_id {α : Typevec n} {β : Type _} : (@Typevec.id n α ::: @id β) = Typevec.id :=
  eq_of_drop_last_eq rfl rfl

instance subsingleton0 : Subsingleton (Typevec 0) :=
  ⟨fun a b => funext fun a => Fin2.elim0 a⟩

run_cmd
  do
    mk_simp_attr `typevec
    tactic.add_doc_string `simp_attr.typevec "simp set for the manipulation of typevec and arrow expressions"

-- mathport name: «expr♯ »
local prefix:0 "♯" =>
  cast
    (by
      try
          simp <;>
        congr 1 <;>
          try
            simp )

/-- cases distinction for 0-length type vector -/
protected def casesNil {β : Typevec 0 → Sort _} (f : β Fin2.elim0) : ∀ v, β v := fun v => ♯f

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- cases distinction for (n+1)-length type vector -/
protected def casesCons (n : ℕ) {β : Typevec (n + 1) → Sort _} (f : ∀ (t) (v : Typevec n), β (v ::: t)) : ∀ v, β v :=
  fun v : Typevec (n + 1) => ♯f v.last v.drop

protected theorem cases_nil_append1 {β : Typevec 0 → Sort _} (f : β Fin2.elim0) : Typevec.casesNil f Fin2.elim0 = f :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
protected theorem cases_cons_append1 (n : ℕ) {β : Typevec (n + 1) → Sort _} (f : ∀ (t) (v : Typevec n), β (v ::: t))
    (v : Typevec n) (α) : Typevec.casesCons n f (v ::: α) = f α v :=
  rfl

/-- cases distinction for an arrow in the category of 0-length type vectors -/
def typevecCasesNil₃ {β : ∀ v v' : Typevec 0, v ⟹ v' → Sort _} (f : β Fin2.elim0 Fin2.elim0 nilFun) :
    ∀ v v' fs, β v v' fs := fun v v' fs => by
  refine' cast _ f <;>
    congr 1 <;>
      ext <;>
        try
          intros <;> casesm Fin2 0
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- cases distinction for an arrow in the category of (n+1)-length type vectors -/
def typevecCasesCons₃ (n : ℕ) {β : ∀ v v' : Typevec (n + 1), v ⟹ v' → Sort _}
    (F : ∀ (t t') (f : t → t') (v v' : Typevec n) (fs : v ⟹ v'), β (v ::: t) (v' ::: t') (fs ::: f)) :
    ∀ v v' fs, β v v' fs := by
  intro v v'
  rw [← append1_drop_last v, ← append1_drop_last v']
  intro fs
  rw [← split_drop_fun_last_fun fs]
  apply F

/-- specialized cases distinction for an arrow in the category of 0-length type vectors -/
def typevecCasesNil₂ {β : Fin2.elim0 ⟹ Fin2.elim0 → Sort _} (f : β nilFun) : ∀ f, β f := by
  intro g
  have : g = nil_fun
  ext ⟨⟩
  rw [this]
  exact f

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- specialized cases distinction for an arrow in the category of (n+1)-length type vectors -/
def typevecCasesCons₂ (n : ℕ) (t t' : Type _) (v v' : Typevec n) {β : (v ::: t) ⟹ (v' ::: t') → Sort _}
    (F : ∀ (f : t → t') (fs : v ⟹ v'), β (fs ::: f)) : ∀ fs, β fs := by
  intro fs
  rw [← split_drop_fun_last_fun fs]
  apply F

theorem typevec_cases_nil₂_append_fun {β : Fin2.elim0 ⟹ Fin2.elim0 → Sort _} (f : β nilFun) :
    typevecCasesNil₂ f nilFun = f :=
  rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem typevec_cases_cons₂_append_fun (n : ℕ) (t t' : Type _) (v v' : Typevec n) {β : (v ::: t) ⟹ (v' ::: t') → Sort _}
    (F : ∀ (f : t → t') (fs : v ⟹ v'), β (fs ::: f)) (f fs) : typevecCasesCons₂ n t t' v v' F (fs ::: f) = F f fs :=
  rfl

-- for lifting predicates and relations
/-- `pred_last α p x` predicates `p` of the last element of `x : α.append1 β`. -/
def PredLast (α : Typevec n) {β : Type _} (p : β → Prop) : ∀ ⦃i⦄, (α.Append1 β) i → Prop
  | Fin2.fs i => fun x => True
  | Fin2.fz => p

/-- `rel_last α r x y` says that `p` the last elements of `x y : α.append1 β` are related by `r` and
all the other elements are equal. -/
def RelLast (α : Typevec n) {β γ : Type _} (r : β → γ → Prop) : ∀ ⦃i⦄, (α.Append1 β) i → (α.Append1 γ) i → Prop
  | Fin2.fs i => Eq
  | Fin2.fz => r

section Liftp'

open Nat

/-- `repeat n t` is a `n-length` type vector that contains `n` occurences of `t` -/
def Repeat : ∀ (n : ℕ) (t : Sort _), Typevec n
  | 0, t => Fin2.elim0
  | Nat.succ i, t => Append1 (repeat i t) t

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- `prod α β` is the pointwise product of the components of `α` and `β` -/
def Prod : ∀ {n} (α β : Typevec.{u} n), Typevec n
  | 0, α, β => Fin2.elim0
  | n + 1, α, β => Prod (Drop α) (Drop β) ::: Last α × Last β

-- mathport name: typevec.prod
localized [Mvfunctor] infixl:45 " ⊗ " => Typevec.Prod

/-- `const x α` is an arrow that ignores its source and constructs a `typevec` that
contains nothing but `x` -/
protected def constₓ {β} (x : β) : ∀ {n} (α : Typevec n), α ⟹ Repeat _ β
  | succ n, α, Fin2.fs i => const (Drop α) _
  | succ n, α, Fin2.fz => fun _ => x

open Function (uncurry)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- vector of equality on a product of vectors -/
def repeatEq : ∀ {n} (α : Typevec n), α ⊗ α ⟹ Repeat _ Prop
  | 0, α => nilFun
  | succ n, α => repeat_eq (Drop α) ::: uncurry Eq

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem const_append1 {β γ} (x : γ) {n} (α : Typevec n) :
    Typevec.constₓ x (α ::: β) = appendFun (Typevec.constₓ x α) fun _ => x := by
  ext i : 1 <;> cases i <;> rfl

theorem eq_nil_fun {α β : Typevec 0} (f : α ⟹ β) : f = nil_fun := by
  ext x <;> cases x

theorem id_eq_nil_fun {α : Typevec 0} : @id _ α = nil_fun := by
  ext x <;> cases x

theorem const_nil {β} (x : β) (α : Typevec 0) : Typevec.constₓ x α = nil_fun := by
  ext i : 1 <;> cases i <;> rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[typevec]
theorem repeat_eq_append1 {β} {n} (α : Typevec n) : repeatEq (α ::: β) = splitFun (repeatEq α) (uncurry Eq) := by
  induction n <;> rfl

@[typevec]
theorem repeat_eq_nil (α : Typevec 0) : repeatEq α = nil_fun := by
  ext i : 1 <;> cases i <;> rfl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- predicate on a type vector to constrain only the last object -/
def predLast' (α : Typevec n) {β : Type _} (p : β → Prop) : (α ::: β) ⟹ Repeat (n + 1) Prop :=
  splitFun (Typevec.constₓ True α) p

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- predicate on the product of two type vectors to constrain only their last object -/
def relLast' (α : Typevec n) {β : Type _} (p : β → β → Prop) : (α ::: β) ⊗ (α ::: β) ⟹ Repeat (n + 1) Prop :=
  splitFun (repeatEq α) (uncurry p)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- given `F : typevec.{u} (n+1) → Type u`, `curry F : Type u → typevec.{u} → Type u`,
i.e. its first argument can be fed in separately from the rest of the vector of arguments -/
def Curry (F : Typevec.{u} (n + 1) → Type _) (α : Type u) (β : Typevec.{u} n) : Type _ :=
  F (β ::: α)

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
instance Curry.inhabited (F : Typevec.{u} (n + 1) → Type _) (α : Type u) (β : Typevec.{u} n)
    [I : Inhabited (F <| (β ::: α))] : Inhabited (Curry F α β) :=
  I

/-- arrow to remove one element of a `repeat` vector -/
def dropRepeat (α : Type _) : ∀ {n}, Drop (Repeat (succ n) α) ⟹ Repeat n α
  | succ n, Fin2.fs i => drop_repeat i
  | succ n, Fin2.fz => id

/-- projection for a repeat vector -/
def ofRepeat {α : Sort _} : ∀ {n i}, Repeat n α i → α
  | _, Fin2.fz => id
  | _, Fin2.fs i => @of_repeat _ i

theorem const_iff_true {α : Typevec n} {i x p} : ofRepeat (Typevec.constₓ p α i x) ↔ p := by
  induction i <;> [rfl, erw [Typevec.constₓ, @i_ih (drop α) x]]

-- variables  {F : typevec.{u} n → Type*} [mvfunctor F]
variable {α β γ : Typevec.{u} n}

variable (p : α ⟹ Repeat n Prop) (r : α ⊗ α ⟹ Repeat n Prop)

/-- left projection of a `prod` vector -/
def Prod.fst : ∀ {n} {α β : Typevec.{u} n}, α ⊗ β ⟹ α
  | succ n, α, β, Fin2.fs i => @Prod.fst _ (Drop α) (Drop β) i
  | succ n, α, β, Fin2.fz => Prod.fst

/-- right projection of a `prod` vector -/
def Prod.snd : ∀ {n} {α β : Typevec.{u} n}, α ⊗ β ⟹ β
  | succ n, α, β, Fin2.fs i => @Prod.snd _ (Drop α) (Drop β) i
  | succ n, α, β, Fin2.fz => Prod.snd

/-- introduce a product where both components are the same -/
def Prod.diag : ∀ {n} {α : Typevec.{u} n}, α ⟹ α ⊗ α
  | succ n, α, Fin2.fs i, x => @prod.diag _ (Drop α) _ x
  | succ n, α, Fin2.fz, x => (x, x)

/-- constructor for `prod` -/
def Prod.mk : ∀ {n} {α β : Typevec.{u} n} (i : Fin2 n), α i → β i → (α ⊗ β) i
  | succ n, α, β, Fin2.fs i => Prod.mk i
  | succ n, α, β, Fin2.fz => Prod.mk

@[simp]
theorem prod_fst_mk {α β : Typevec n} (i : Fin2 n) (a : α i) (b : β i) : Typevec.Prod.fst i (Prod.mk i a b) = a := by
  induction i <;> simp_all [Prod.fst, Prod.mk]

@[simp]
theorem prod_snd_mk {α β : Typevec n} (i : Fin2 n) (a : α i) (b : β i) : Typevec.Prod.snd i (Prod.mk i a b) = b := by
  induction i <;> simp_all [Prod.snd, Prod.mk]

/-- `prod` is functorial -/
protected def Prod.map : ∀ {n} {α α' β β' : Typevec.{u} n}, α ⟹ β → α' ⟹ β' → α ⊗ α' ⟹ β ⊗ β'
  | succ n, α, α', β, β', x, y, Fin2.fs i, a =>
    @Prod.map _ (Drop α) (Drop α') (Drop β) (Drop β') (dropFun x) (dropFun y) _ a
  | succ n, α, α', β, β', x, y, Fin2.fz, a => (x _ a.1, y _ a.2)

-- mathport name: typevec.prod.map
localized [Mvfunctor] infixl:45 " ⊗' " => Typevec.Prod.map

theorem fst_prod_mk {α α' β β' : Typevec n} (f : α ⟹ β) (g : α' ⟹ β') :
    Typevec.Prod.fst ⊚ (f ⊗' g) = f ⊚ Typevec.Prod.fst := by
  ext i <;> induction i <;> [rfl, apply i_ih]

theorem snd_prod_mk {α α' β β' : Typevec n} (f : α ⟹ β) (g : α' ⟹ β') :
    Typevec.Prod.snd ⊚ (f ⊗' g) = g ⊚ Typevec.Prod.snd := by
  ext i <;> induction i <;> [rfl, apply i_ih]

theorem fst_diag {α : Typevec n} : Typevec.Prod.fst ⊚ (Prod.diag : α ⟹ _) = id := by
  ext i <;> induction i <;> [rfl, apply i_ih]

theorem snd_diag {α : Typevec n} : Typevec.Prod.snd ⊚ (Prod.diag : α ⟹ _) = id := by
  ext i <;> induction i <;> [rfl, apply i_ih]

theorem repeat_eq_iff_eq {α : Typevec n} {i x y} : ofRepeat (repeatEq α i (Prod.mk _ x y)) ↔ x = y := by
  induction i <;> [rfl, erw [repeat_eq, @i_ih (drop α) x y]]

/-- given a predicate vector `p` over vector `α`, `subtype_ p` is the type of vectors
that contain an `α` that satisfies `p` -/
def Subtype_ : ∀ {n} {α : Typevec.{u} n} (p : α ⟹ Repeat n Prop), Typevec n
  | _, α, p, Fin2.fz => Subtype fun x => p Fin2.fz x
  | _, α, p, Fin2.fs i => subtype_ (dropFun p) i

/-- projection on `subtype_` -/
def subtypeVal : ∀ {n} {α : Typevec.{u} n} (p : α ⟹ Repeat n Prop), Subtype_ p ⟹ α
  | succ n, α, p, Fin2.fs i => @subtype_val n _ _ i
  | succ n, α, p, Fin2.fz => Subtype.val

/-- arrow that rearranges the type of `subtype_` to turn a subtype of vector into
a vector of subtypes -/
def toSubtype :
    ∀ {n} {α : Typevec.{u} n} (p : α ⟹ Repeat n Prop), (fun i : Fin2 n => { x // of_repeat <| p i x }) ⟹ Subtype_ p
  | succ n, α, p, Fin2.fs i, x => to_subtype (dropFun p) i x
  | succ n, α, p, Fin2.fz, x => x

/-- arrow that rearranges the type of `subtype_` to turn a vector of subtypes
into a subtype of vector -/
def ofSubtype :
    ∀ {n} {α : Typevec.{u} n} (p : α ⟹ Repeat n Prop), Subtype_ p ⟹ fun i : Fin2 n => { x // of_repeat <| p i x }
  | succ n, α, p, Fin2.fs i, x => of_subtype _ i x
  | succ n, α, p, Fin2.fz, x => x

/-- similar to `to_subtype` adapted to relations (i.e. predicate on product) -/
def toSubtype' :
    ∀ {n} {α : Typevec.{u} n} (p : α ⊗ α ⟹ Repeat n Prop),
      (fun i : Fin2 n => { x : α i × α i // of_repeat <| p i (Prod.mk _ x.1 x.2) }) ⟹ Subtype_ p
  | succ n, α, p, Fin2.fs i, x => to_subtype' (dropFun p) i x
  | succ n, α, p, Fin2.fz, x =>
    ⟨x.val,
      cast
        (by
          congr <;> simp [Prod.mk])
        x.property⟩

/-- similar to `of_subtype` adapted to relations (i.e. predicate on product) -/
def ofSubtype' :
    ∀ {n} {α : Typevec.{u} n} (p : α ⊗ α ⟹ Repeat n Prop),
      Subtype_ p ⟹ fun i : Fin2 n => { x : α i × α i // of_repeat <| p i (Prod.mk _ x.1 x.2) }
  | _, α, p, Fin2.fs i, x => of_subtype' _ i x
  | _, α, p, Fin2.fz, x =>
    ⟨x.val,
      cast
        (by
          congr <;> simp [Prod.mk])
        x.property⟩

/-- similar to `diag` but the target vector is a `subtype_`
guaranteeing the equality of the components -/
def diagSub : ∀ {n} {α : Typevec.{u} n}, α ⟹ Subtype_ (repeatEq α)
  | succ n, α, Fin2.fs i, x => @diag_sub _ (Drop α) _ x
  | succ n, α, Fin2.fz, x => ⟨(x, x), rfl⟩

theorem subtype_val_nil {α : Typevec.{u} 0} (ps : α ⟹ Repeat 0 Prop) : Typevec.subtypeVal ps = nil_fun :=
  funext <| by
    rintro ⟨⟩ <;> rfl

theorem diag_sub_val {n} {α : Typevec.{u} n} : subtypeVal (repeatEq α) ⊚ diag_sub = prod.diag := by
  ext i <;> induction i <;> [rfl, apply i_ih]

theorem prod_id : ∀ {n} {α β : Typevec.{u} n}, (id ⊗' id) = (id : α ⊗ β ⟹ _) := by
  intros
  ext i a
  induction i
  · cases a
    rfl
    
  · apply i_ih
    

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem append_prod_append_fun {n} {α α' β β' : Typevec.{u} n} {φ φ' ψ ψ' : Type u} {f₀ : α ⟹ α'} {g₀ : β ⟹ β'}
    {f₁ : φ → φ'} {g₁ : ψ → ψ'} : (f₀ ⊗' g₀ ::: Prod.map f₁ g₁) = ((f₀ ::: f₁) ⊗' (g₀ ::: g₁)) := by
  ext i a <;> cases i <;> [cases a, skip] <;> rfl

end Liftp'

@[simp]
theorem drop_fun_diag {α} : dropFun (@Prod.diag (n + 1) α) = prod.diag := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem drop_fun_subtype_val {α} (p : α ⟹ Repeat (n + 1) Prop) : dropFun (subtypeVal p) = subtypeVal _ :=
  rfl

@[simp]
theorem last_fun_subtype_val {α} (p : α ⟹ Repeat (n + 1) Prop) : lastFun (subtypeVal p) = Subtype.val :=
  rfl

@[simp]
theorem drop_fun_to_subtype {α} (p : α ⟹ Repeat (n + 1) Prop) : dropFun (toSubtype p) = toSubtype _ := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem last_fun_to_subtype {α} (p : α ⟹ Repeat (n + 1) Prop) : lastFun (toSubtype p) = _root_.id := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem drop_fun_of_subtype {α} (p : α ⟹ Repeat (n + 1) Prop) : dropFun (ofSubtype p) = ofSubtype _ := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem last_fun_of_subtype {α} (p : α ⟹ Repeat (n + 1) Prop) : lastFun (ofSubtype p) = _root_.id := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem drop_fun_rel_last {α : Typevec n} {β} (R : β → β → Prop) : dropFun (relLast' α R) = repeatEq α :=
  rfl

attribute [simp] drop_append1'

open Mvfunctor

@[simp]
theorem drop_fun_prod {α α' β β' : Typevec (n + 1)} (f : α ⟹ β) (f' : α' ⟹ β') :
    dropFun (f ⊗' f') = (dropFun f ⊗' dropFun f') := by
  ext i : 2
  induction i <;> simp [drop_fun, *] <;> rfl

@[simp]
theorem last_fun_prod {α α' β β' : Typevec (n + 1)} (f : α ⟹ β) (f' : α' ⟹ β') :
    lastFun (f ⊗' f') = Prod.map (lastFun f) (lastFun f') := by
  ext i : 1
  induction i <;> simp [last_fun, *] <;> rfl

@[simp]
theorem drop_fun_from_append1_drop_last {α : Typevec (n + 1)} : dropFun (@fromAppend1DropLast _ α) = id :=
  rfl

@[simp]
theorem last_fun_from_append1_drop_last {α : Typevec (n + 1)} : lastFun (@fromAppend1DropLast _ α) = _root_.id :=
  rfl

@[simp]
theorem drop_fun_id {α : Typevec (n + 1)} : dropFun (@Typevec.id _ α) = id :=
  rfl

@[simp]
theorem prod_map_id {α β : Typevec n} : (@Typevec.id _ α ⊗' @Typevec.id _ β) = id := by
  ext i : 2
  induction i <;> simp only [Typevec.Prod.map, *, drop_fun_id]
  cases x
  rfl
  rfl

@[simp]
theorem subtype_val_diag_sub {α : Typevec n} : subtypeVal (repeatEq α) ⊚ diag_sub = prod.diag := by
  clear * -
  ext i
  induction i <;> [rfl, apply i_ih]

@[simp]
theorem to_subtype_of_subtype {α : Typevec n} (p : α ⟹ Repeat n Prop) : toSubtype p ⊚ ofSubtype p = id := by
  ext i x <;> induction i <;> dsimp' only [id, to_subtype, comp, of_subtype]  at * <;> simp [*]

@[simp]
theorem subtype_val_to_subtype {α : Typevec n} (p : α ⟹ Repeat n Prop) :
    subtypeVal p ⊚ toSubtype p = fun _ => Subtype.val := by
  ext i x <;> induction i <;> dsimp' only [to_subtype, comp, subtype_val]  at * <;> simp [*]

@[simp]
theorem to_subtype_of_subtype_assoc {α β : Typevec n} (p : α ⟹ Repeat n Prop) (f : β ⟹ Subtype_ p) :
    @toSubtype n _ p ⊚ ofSubtype _ ⊚ f = f := by
  rw [← comp_assoc, to_subtype_of_subtype] <;> simp

@[simp]
theorem to_subtype'_of_subtype' {α : Typevec n} (r : α ⊗ α ⟹ Repeat n Prop) : toSubtype' r ⊚ ofSubtype' r = id := by
  ext i x <;> induction i <;> dsimp' only [id, to_subtype', comp, of_subtype']  at * <;> simp [Subtype.eta, *]

theorem subtype_val_to_subtype' {α : Typevec n} (r : α ⊗ α ⟹ Repeat n Prop) :
    subtypeVal r ⊚ toSubtype' r = fun i x => Prod.mk i x.1.fst x.1.snd := by
  ext i x <;> induction i <;> dsimp' only [id, to_subtype', comp, subtype_val, Prod.mk]  at * <;> simp [*]

end Typevec

