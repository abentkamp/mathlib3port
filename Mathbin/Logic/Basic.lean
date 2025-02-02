/-
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Leonardo de Moura
-/
import Mathbin.Tactic.DocCommands
import Mathbin.Tactic.ReservedNotation

/-!
# Basic logic properties

This file is one of the earliest imports in mathlib.

## Implementation notes

Theorems that require decidability hypotheses are in the namespace "decidable".
Classical versions are in the namespace "classical".

In the presence of automation, this whole file may be unnecessary. On the other hand,
maybe it is useful for writing automation.
-/


open Function

attribute [local instance] Classical.propDecidable

section Miscellany

/- We add the `inline` attribute to optimize VM computation using these declarations. For example,
  `if p ∧ q then ... else ...` will not evaluate the decidability of `q` if `p` is false. -/
attribute [inline]
  And.decidable Or.decidable Decidable.false Xorₓ.decidable Iff.decidable Decidable.true Implies.decidable Not.decidable Ne.decidable Bool.decidableEq Decidable.toBool

attribute [simp] cast_eq cast_heq

variable {α : Type _} {β : Type _}

/-- An identity function with its main argument implicit. This will be printed as `hidden` even
if it is applied to a large term, so it can be used for elision,
as done in the `elide` and `unelide` tactics. -/
@[reducible]
def hidden {α : Sort _} {a : α} :=
  a

/-- Ex falso, the nondependent eliminator for the `empty` type. -/
def Empty.elim {C : Sort _} : Empty → C :=
  fun.

instance : Subsingleton Empty :=
  ⟨fun a => a.elim⟩

instance Subsingleton.prod {α β : Type _} [Subsingleton α] [Subsingleton β] : Subsingleton (α × β) :=
  ⟨by
    intro a b
    cases a
    cases b
    congr ⟩

instance : DecidableEq Empty := fun a => a.elim

instance Sort.inhabited : Inhabited (Sort _) :=
  ⟨PUnit⟩

instance Sort.inhabited' : Inhabited default :=
  ⟨PUnit.unit⟩

instance PSum.inhabitedLeft {α β} [Inhabited α] : Inhabited (PSum α β) :=
  ⟨PSum.inl default⟩

instance PSum.inhabitedRight {α β} [Inhabited β] : Inhabited (PSum α β) :=
  ⟨PSum.inr default⟩

instance (priority := 10) decidableEqOfSubsingleton {α} [Subsingleton α] : DecidableEq α
  | a, b => isTrue (Subsingleton.elim a b)

@[simp]
theorem eq_iff_true_of_subsingleton {α : Sort _} [Subsingleton α] (x y : α) : x = y ↔ True := by
  cc

/-- If all points are equal to a given point `x`, then `α` is a subsingleton. -/
theorem subsingleton_of_forall_eq {α : Sort _} (x : α) (h : ∀ y, y = x) : Subsingleton α :=
  ⟨fun a b => (h a).symm ▸ (h b).symm ▸ rfl⟩

theorem subsingleton_iff_forall_eq {α : Sort _} (x : α) : Subsingleton α ↔ ∀ y, y = x :=
  ⟨fun h y => @Subsingleton.elim _ h y x, subsingleton_of_forall_eq x⟩

instance Subtype.subsingleton (α : Sort _) [Subsingleton α] (p : α → Prop) : Subsingleton (Subtype p) :=
  ⟨fun ⟨x, _⟩ ⟨y, _⟩ => by
    have : x = y := Subsingleton.elim _ _
    cases this
    rfl⟩

/-- Add an instance to "undo" coercion transitivity into a chain of coercions, because
   most simp lemmas are stated with respect to simple coercions and will not match when
   part of a chain. -/
@[simp]
theorem coe_coe {α β γ} [Coe α β] [CoeTₓ β γ] (a : α) : (a : γ) = (a : β) :=
  rfl

theorem coe_fn_coe_trans {α β γ δ} [Coe α β] [HasCoeTAux β γ] [CoeFun γ δ] (x : α) : @coeFn α _ _ x = @coeFn β _ _ x :=
  rfl

/-- Non-dependent version of `coe_fn_coe_trans`, helps `rw` figure out the argument. -/
theorem coe_fn_coe_trans' {α β γ} {δ : outParam <| _} [Coe α β] [HasCoeTAux β γ] [CoeFun γ fun _ => δ] (x : α) :
    @coeFn α _ _ x = @coeFn β _ _ x :=
  rfl

@[simp]
theorem coe_fn_coe_base {α β γ} [Coe α β] [CoeFun β γ] (x : α) : @coeFn α _ _ x = @coeFn β _ _ x :=
  rfl

/-- Non-dependent version of `coe_fn_coe_base`, helps `rw` figure out the argument. -/
theorem coe_fn_coe_base' {α β} {γ : outParam <| _} [Coe α β] [CoeFun β fun _ => γ] (x : α) :
    @coeFn α _ _ x = @coeFn β _ _ x :=
  rfl

-- This instance should have low priority, to ensure we follow the chain
-- `set_like → has_coe_to_sort`
attribute [instance] coeSortTrans

theorem coe_sort_coe_trans {α β γ δ} [Coe α β] [HasCoeTAux β γ] [CoeSort γ δ] (x : α) :
    @coeSort α _ _ x = @coeSort β _ _ x :=
  rfl

library_note "function coercion"/-- Many structures such as bundled morphisms coerce to functions so that you can
transparently apply them to arguments. For example, if `e : α ≃ β` and `a : α`
then you can write `e a` and this is elaborated as `⇑e a`. This type of
coercion is implemented using the `has_coe_to_fun` type class. There is one
important consideration:

If a type coerces to another type which in turn coerces to a function,
then it **must** implement `has_coe_to_fun` directly:
```lean
structure sparkling_equiv (α β) extends α ≃ β

-- if we add a `has_coe` instance,
instance {α β} : has_coe (sparkling_equiv α β) (α ≃ β) :=
⟨sparkling_equiv.to_equiv⟩

-- then a `has_coe_to_fun` instance **must** be added as well:
instance {α β} : has_coe_to_fun (sparkling_equiv α β) :=
⟨λ _, α → β, λ f, f.to_equiv.to_fun⟩
```

(Rationale: if we do not declare the direct coercion, then `⇑e a` is not in
simp-normal form. The lemma `coe_fn_coe_base` will unfold it to `⇑↑e a`. This
often causes loops in the simplifier.)
-/


@[simp]
theorem coe_sort_coe_base {α β γ} [Coe α β] [CoeSort β γ] (x : α) : @coeSort α _ _ x = @coeSort β _ _ x :=
  rfl

/-- `pempty` is the universe-polymorphic analogue of `empty`. -/
inductive Pempty.{u} : Sort u
  deriving DecidableEq

/-- Ex falso, the nondependent eliminator for the `pempty` type. -/
def Pempty.elimₓ {C : Sort _} : Pempty → C :=
  fun.

instance subsingleton_pempty : Subsingleton Pempty :=
  ⟨fun a => a.elim⟩

@[simp]
theorem not_nonempty_pempty : ¬Nonempty Pempty := fun ⟨h⟩ => h.elim

theorem congr_heq {α β γ : Sort _} {f : α → γ} {g : β → γ} {x : α} {y : β} (h₁ : HEq f g) (h₂ : HEq x y) : f x = g y :=
  by
  cases h₂
  cases h₁
  rfl

theorem congr_arg_heq {α} {β : α → Sort _} (f : ∀ a, β a) : ∀ {a₁ a₂ : α}, a₁ = a₂ → HEq (f a₁) (f a₂)
  | a, _, rfl => HEq.rfl

theorem ULift.down_injective {α : Sort _} : Function.Injective (@ULift.down α)
  | ⟨a⟩, ⟨b⟩, rfl => rfl

@[simp]
theorem ULift.down_inj {α : Sort _} {a b : ULift α} : a.down = b.down ↔ a = b :=
  ⟨fun h => ULift.down_injective h, fun h => by
    rw [h]⟩

theorem Plift.down_injective {α : Sort _} : Function.Injective (@Plift.down α)
  | ⟨a⟩, ⟨b⟩, rfl => rfl

@[simp]
theorem Plift.down_inj {α : Sort _} {a b : Plift α} : a.down = b.down ↔ a = b :=
  ⟨fun h => Plift.down_injective h, fun h => by
    rw [h]⟩

-- missing [symm] attribute for ne in core.
attribute [symm] Ne.symm

theorem ne_comm {α} {a b : α} : a ≠ b ↔ b ≠ a :=
  ⟨Ne.symm, Ne.symm⟩

@[simp]
theorem eq_iff_eq_cancel_left {b c : α} : (∀ {a}, a = b ↔ a = c) ↔ b = c :=
  ⟨fun h => by
    rw [← h], fun h a => by
    rw [h]⟩

@[simp]
theorem eq_iff_eq_cancel_right {a b : α} : (∀ {c}, a = c ↔ b = c) ↔ a = b :=
  ⟨fun h => by
    rw [h], fun h a => by
    rw [h]⟩

-- ./././Mathport/Syntax/Translate/Command.lean:324:30: infer kinds are unsupported in Lean 4: #[`out] []
/-- Wrapper for adding elementary propositions to the type class systems.
Warning: this can easily be abused. See the rest of this docstring for details.

Certain propositions should not be treated as a class globally,
but sometimes it is very convenient to be able to use the type class system
in specific circumstances.

For example, `zmod p` is a field if and only if `p` is a prime number.
In order to be able to find this field instance automatically by type class search,
we have to turn `p.prime` into an instance implicit assumption.

On the other hand, making `nat.prime` a class would require a major refactoring of the library,
and it is questionable whether making `nat.prime` a class is desirable at all.
The compromise is to add the assumption `[fact p.prime]` to `zmod.field`.

In particular, this class is not intended for turning the type class system
into an automated theorem prover for first order logic. -/
class Fact (p : Prop) : Prop where
  out : p

library_note "fact non-instances"/--
In most cases, we should not have global instances of `fact`; typeclass search only reads the head
symbol and then tries any instances, which means that adding any such instance will cause slowdowns
everywhere. We instead make them as lemmata and make them local instances as required.
-/


theorem Fact.elim {p : Prop} (h : Fact p) : p :=
  h.1

theorem fact_iff {p : Prop} : Fact p ↔ p :=
  ⟨fun h => h.1, fun h => ⟨h⟩⟩

/-- Swaps two pairs of arguments to a function. -/
@[reducible]
def Function.swap₂ {ι₁ ι₂ : Sort _} {κ₁ : ι₁ → Sort _} {κ₂ : ι₂ → Sort _} {φ : ∀ i₁, κ₁ i₁ → ∀ i₂, κ₂ i₂ → Sort _}
    (f : ∀ i₁ j₁ i₂ j₂, φ i₁ j₁ i₂ j₂) : ∀ i₂ j₂ i₁ j₁, φ i₁ j₁ i₂ j₂ := fun i₂ j₂ i₁ j₁ => f i₁ j₁ i₂ j₂

/-- If `x : α . tac_name` then `x.out : α`. These are definitionally equal, but this can
nevertheless be useful for various reasons, e.g. to apply further projection notation or in an
argument to `simp`. -/
def AutoParam.out {α : Sort _} {n : Name} (x : AutoParam α n) : α :=
  x

/-- If `x : α := d` then `x.out : α`. These are definitionally equal, but this can
nevertheless be useful for various reasons, e.g. to apply further projection notation or in an
argument to `simp`. -/
def optParam.out {α : Sort _} {d : α} (x : α := d) : α :=
  x

end Miscellany

open Function

/-!
### Declarations about propositional connectives
-/


theorem false_ne_true : False ≠ True
  | h => h.symm ▸ trivialₓ

section Propositional

variable {a b c d e f : Prop}

/-! ### Declarations about `implies` -/


instance : IsRefl Prop Iff :=
  ⟨Iff.refl⟩

instance : IsTrans Prop Iff :=
  ⟨fun _ _ _ => Iff.trans⟩

theorem iff_of_eq (e : a = b) : a ↔ b :=
  e ▸ Iff.rfl

theorem iff_iff_eq : (a ↔ b) ↔ a = b :=
  ⟨propext, iff_of_eq⟩

@[simp]
theorem eq_iff_iff {p q : Prop} : p = q ↔ (p ↔ q) :=
  iff_iff_eq.symm

@[simp]
theorem imp_self : a → a ↔ True :=
  iff_true_intro id

theorem Iff.imp (h₁ : a ↔ b) (h₂ : c ↔ d) : a → c ↔ b → d :=
  imp_congr h₁ h₂

@[simp]
theorem eq_true_eq_id : Eq True = id := by
  funext
  simp only [true_iffₓ, id.def, iff_selfₓ, eq_iff_iff]

theorem imp_intro {α β : Prop} (h : α) : β → α := fun _ => h

theorem imp_false : a → False ↔ ¬a :=
  Iff.rfl

theorem imp_and_distrib {α} : α → b ∧ c ↔ (α → b) ∧ (α → c) :=
  ⟨fun h => ⟨fun ha => (h ha).left, fun ha => (h ha).right⟩, fun h ha => ⟨h.left ha, h.right ha⟩⟩

@[simp]
theorem and_imp : a ∧ b → c ↔ a → b → c :=
  Iff.intro (fun h ha hb => h ⟨ha, hb⟩) fun h ⟨ha, hb⟩ => h ha hb

theorem iff_def : (a ↔ b) ↔ (a → b) ∧ (b → a) :=
  iff_iff_implies_and_implies _ _

theorem iff_def' : (a ↔ b) ↔ (b → a) ∧ (a → b) :=
  iff_def.trans And.comm

theorem imp_true_iff {α : Sort _} : α → True ↔ True :=
  iff_true_intro fun _ => trivialₓ

theorem imp_iff_right (ha : a) : a → b ↔ b :=
  ⟨fun f => f ha, imp_intro⟩

theorem imp_iff_not (hb : ¬b) : a → b ↔ ¬a :=
  imp_congr_right fun _ => iff_false_intro hb

theorem Decidable.imp_iff_right_iff [Decidable a] : (a → b ↔ b) ↔ a ∨ b :=
  ⟨fun H => (Decidable.em a).imp_right fun ha' => H.1 fun ha => (ha' ha).elim, fun H =>
    (H.elim imp_iff_right) fun hb => ⟨fun hab => hb, fun _ _ => hb⟩⟩

@[simp]
theorem imp_iff_right_iff : (a → b ↔ b) ↔ a ∨ b :=
  Decidable.imp_iff_right_iff

theorem Decidable.and_or_imp [Decidable a] : a ∧ b ∨ (a → c) ↔ a → b ∨ c :=
  if ha : a then by
    simp only [ha, true_andₓ, true_implies_iff]
  else by
    simp only [ha, false_orₓ, false_andₓ, false_implies_iff]

@[simp]
theorem and_or_imp : a ∧ b ∨ (a → c) ↔ a → b ∨ c :=
  Decidable.and_or_imp

/-- Provide modus tollens (`mt`) as dot notation for implications. -/
protected theorem Function.mt : (a → b) → ¬b → ¬a :=
  mt

/-! ### Declarations about `not` -/


/-- Ex falso for negation. From `¬ a` and `a` anything follows. This is the same as `absurd` with
the arguments flipped, but it is in the `not` namespace so that projection notation can be used. -/
def Not.elim {α : Sort _} (H1 : ¬a) (H2 : a) : α :=
  absurd H2 H1

@[reducible]
theorem Not.imp {a b : Prop} (H2 : ¬b) (H1 : a → b) : ¬a :=
  mt H1 H2

theorem not_not_of_not_imp : ¬(a → b) → ¬¬a :=
  mt Not.elim

theorem not_of_not_imp {a : Prop} : ¬(a → b) → ¬b :=
  mt imp_intro

theorem dec_em (p : Prop) [Decidable p] : p ∨ ¬p :=
  Decidable.em p

theorem dec_em' (p : Prop) [Decidable p] : ¬p ∨ p :=
  (dec_em p).swap

theorem em (p : Prop) : p ∨ ¬p :=
  Classical.em _

theorem em' (p : Prop) : ¬p ∨ p :=
  (em p).swap

theorem or_not {p : Prop} : p ∨ ¬p :=
  em _

section eq_or_ne

variable {α : Sort _} (x y : α)

theorem Decidable.eq_or_ne [Decidable (x = y)] : x = y ∨ x ≠ y :=
  dec_em <| x = y

theorem Decidable.ne_or_eq [Decidable (x = y)] : x ≠ y ∨ x = y :=
  dec_em' <| x = y

theorem eq_or_ne : x = y ∨ x ≠ y :=
  em <| x = y

theorem ne_or_eq : x ≠ y ∨ x = y :=
  em' <| x = y

end eq_or_ne

theorem by_contradiction {p} : (¬p → False) → p :=
  Decidable.by_contradiction

-- alias by_contradiction ← by_contra
theorem by_contra {p} : (¬p → False) → p :=
  Decidable.by_contradiction

library_note "decidable namespace"/--
In most of mathlib, we use the law of excluded middle (LEM) and the axiom of choice (AC) freely.
The `decidable` namespace contains versions of lemmas from the root namespace that explicitly
attempt to avoid the axiom of choice, usually by adding decidability assumptions on the inputs.

You can check if a lemma uses the axiom of choice by using `#print axioms foo` and seeing if
`classical.choice` appears in the list.
-/


library_note "decidable arguments"/-- As mathlib is primarily classical,
if the type signature of a `def` or `lemma` does not require any `decidable` instances to state,
it is preferable not to introduce any `decidable` instances that are needed in the proof
as arguments, but rather to use the `classical` tactic as needed.

In the other direction, when `decidable` instances do appear in the type signature,
it is better to use explicitly introduced ones rather than allowing Lean to automatically infer
classical ones, as these may cause instance mismatch errors later.
-/


-- See Note [decidable namespace]
protected theorem Decidable.not_not [Decidable a] : ¬¬a ↔ a :=
  Iff.intro Decidable.by_contradiction not_not_intro

/-- The Double Negation Theorem: `¬ ¬ P` is equivalent to `P`.
The left-to-right direction, double negation elimination (DNE),
is classically true but not constructively. -/
@[simp]
theorem not_not : ¬¬a ↔ a :=
  Decidable.not_not

theorem of_not_not : ¬¬a → a :=
  by_contra

theorem not_ne_iff {α : Sort _} {a b : α} : ¬a ≠ b ↔ a = b :=
  not_not

-- See Note [decidable namespace]
protected theorem Decidable.of_not_imp [Decidable a] (h : ¬(a → b)) : a :=
  Decidable.by_contradiction (not_not_of_not_imp h)

theorem of_not_imp : ¬(a → b) → a :=
  Decidable.of_not_imp

-- See Note [decidable namespace]
protected theorem Decidable.not_imp_symm [Decidable a] (h : ¬a → b) (hb : ¬b) : a :=
  Decidable.by_contradiction <| hb ∘ h

theorem Not.decidable_imp_symm [Decidable a] : (¬a → b) → ¬b → a :=
  Decidable.not_imp_symm

theorem Not.imp_symm : (¬a → b) → ¬b → a :=
  Not.decidable_imp_symm

-- See Note [decidable namespace]
protected theorem Decidable.not_imp_comm [Decidable a] [Decidable b] : ¬a → b ↔ ¬b → a :=
  ⟨Not.decidable_imp_symm, Not.decidable_imp_symm⟩

theorem not_imp_comm : ¬a → b ↔ ¬b → a :=
  Decidable.not_imp_comm

@[simp]
theorem imp_not_self : a → ¬a ↔ ¬a :=
  ⟨fun h ha => h ha ha, fun h _ => h⟩

theorem Decidable.not_imp_self [Decidable a] : ¬a → a ↔ a := by
  have := @imp_not_self ¬a
  rwa [Decidable.not_not] at this

@[simp]
theorem not_imp_self : ¬a → a ↔ a :=
  Decidable.not_imp_self

theorem Imp.swap : a → b → c ↔ b → a → c :=
  ⟨swap, swap⟩

theorem imp_not_comm : a → ¬b ↔ b → ¬a :=
  Imp.swap

theorem Iff.not (h : a ↔ b) : ¬a ↔ ¬b :=
  not_congr h

theorem Iff.not_left (h : a ↔ ¬b) : ¬a ↔ b :=
  h.Not.trans not_not

theorem Iff.not_right (h : ¬a ↔ b) : a ↔ ¬b :=
  not_not.symm.trans h.Not

/-! ### Declarations about `xor` -/


@[simp]
theorem xor_true : Xorₓ True = Not :=
  funext fun a => by
    simp [Xorₓ]

@[simp]
theorem xor_false : Xorₓ False = id :=
  funext fun a => by
    simp [Xorₓ]

theorem xor_comm (a b) : Xorₓ a b = Xorₓ b a := by
  simp [Xorₓ, and_comm, or_comm]

instance : IsCommutative Prop Xorₓ :=
  ⟨xor_comm⟩

@[simp]
theorem xor_self (a : Prop) : Xorₓ a a = False := by
  simp [Xorₓ]

/-! ### Declarations about `and` -/


theorem Iff.and (h₁ : a ↔ b) (h₂ : c ↔ d) : a ∧ c ↔ b ∧ d :=
  and_congr h₁ h₂

theorem and_congr_left (h : c → (a ↔ b)) : a ∧ c ↔ b ∧ c :=
  And.comm.trans <| (and_congr_right h).trans And.comm

theorem and_congr_left' (h : a ↔ b) : a ∧ c ↔ b ∧ c :=
  h.And Iff.rfl

theorem and_congr_right' (h : b ↔ c) : a ∧ b ↔ a ∧ c :=
  Iff.rfl.And h

theorem not_and_of_not_left (b : Prop) : ¬a → ¬(a ∧ b) :=
  mt And.left

theorem not_and_of_not_right (a : Prop) {b : Prop} : ¬b → ¬(a ∧ b) :=
  mt And.right

theorem And.imp_left (h : a → b) : a ∧ c → b ∧ c :=
  And.imp h id

theorem And.imp_right (h : a → b) : c ∧ a → c ∧ b :=
  And.imp id h

theorem And.right_comm : (a ∧ b) ∧ c ↔ (a ∧ c) ∧ b := by
  simp only [And.left_comm, And.comm]

theorem and_and_and_comm (a b c d : Prop) : (a ∧ b) ∧ c ∧ d ↔ (a ∧ c) ∧ b ∧ d := by
  rw [← and_assoc, @And.right_comm a, and_assoc]

theorem and_and_distrib_left (a b c : Prop) : a ∧ b ∧ c ↔ (a ∧ b) ∧ a ∧ c := by
  rw [and_and_and_comm, and_selfₓ]

theorem and_and_distrib_right (a b c : Prop) : (a ∧ b) ∧ c ↔ (a ∧ c) ∧ b ∧ c := by
  rw [and_and_and_comm, and_selfₓ]

theorem and_rotate : a ∧ b ∧ c ↔ b ∧ c ∧ a := by
  simp only [And.left_comm, And.comm]

theorem And.rotateₓ : a ∧ b ∧ c → b ∧ c ∧ a :=
  and_rotate.1

theorem and_not_self_iff (a : Prop) : a ∧ ¬a ↔ False :=
  Iff.intro (fun h => h.right h.left) fun h => h.elim

theorem not_and_self_iff (a : Prop) : ¬a ∧ a ↔ False :=
  Iff.intro (fun ⟨hna, ha⟩ => hna ha) False.elim

theorem and_iff_left_of_imp {a b : Prop} (h : a → b) : a ∧ b ↔ a :=
  Iff.intro And.left fun ha => ⟨ha, h ha⟩

theorem and_iff_right_of_imp {a b : Prop} (h : b → a) : a ∧ b ↔ b :=
  Iff.intro And.right fun hb => ⟨h hb, hb⟩

@[simp]
theorem and_iff_left_iff_imp {a b : Prop} : (a ∧ b ↔ a) ↔ a → b :=
  ⟨fun h ha => (h.2 ha).2, and_iff_left_of_imp⟩

@[simp]
theorem and_iff_right_iff_imp {a b : Prop} : (a ∧ b ↔ b) ↔ b → a :=
  ⟨fun h ha => (h.2 ha).1, and_iff_right_of_imp⟩

@[simp]
theorem iff_self_and {p q : Prop} : (p ↔ p ∧ q) ↔ p → q := by
  rw [@Iff.comm p, and_iff_left_iff_imp]

@[simp]
theorem iff_and_self {p q : Prop} : (p ↔ q ∧ p) ↔ p → q := by
  rw [and_comm, iff_self_and]

@[simp]
theorem And.congr_right_iff : (a ∧ b ↔ a ∧ c) ↔ a → (b ↔ c) :=
  ⟨fun h ha => by
    simp [ha] at h <;> exact h, and_congr_right⟩

@[simp]
theorem And.congr_left_iff : (a ∧ c ↔ b ∧ c) ↔ c → (a ↔ b) := by
  simp only [And.comm, ← And.congr_right_iff]

@[simp]
theorem and_self_left : a ∧ a ∧ b ↔ a ∧ b :=
  ⟨fun h => ⟨h.1, h.2.2⟩, fun h => ⟨h.1, h.1, h.2⟩⟩

@[simp]
theorem and_self_right : (a ∧ b) ∧ b ↔ a ∧ b :=
  ⟨fun h => ⟨h.1.1, h.2⟩, fun h => ⟨⟨h.1, h.2⟩, h.2⟩⟩

/-! ### Declarations about `or` -/


theorem Iff.or (h₁ : a ↔ b) (h₂ : c ↔ d) : a ∨ c ↔ b ∨ d :=
  or_congr h₁ h₂

theorem or_congr_left' (h : a ↔ b) : a ∨ c ↔ b ∨ c :=
  h.Or Iff.rfl

theorem or_congr_right' (h : b ↔ c) : a ∨ b ↔ a ∨ c :=
  Iff.rfl.Or h

theorem Or.right_comm : (a ∨ b) ∨ c ↔ (a ∨ c) ∨ b := by
  rw [or_assoc, or_assoc, or_comm b]

theorem or_or_or_comm (a b c d : Prop) : (a ∨ b) ∨ c ∨ d ↔ (a ∨ c) ∨ b ∨ d := by
  rw [← or_assoc, @Or.right_comm a, or_assoc]

theorem or_or_distrib_left (a b c : Prop) : a ∨ b ∨ c ↔ (a ∨ b) ∨ a ∨ c := by
  rw [or_or_or_comm, or_selfₓ]

theorem or_or_distrib_right (a b c : Prop) : (a ∨ b) ∨ c ↔ (a ∨ c) ∨ b ∨ c := by
  rw [or_or_or_comm, or_selfₓ]

theorem or_rotate : a ∨ b ∨ c ↔ b ∨ c ∨ a := by
  simp only [Or.left_comm, Or.comm]

theorem Or.rotate : a ∨ b ∨ c → b ∨ c ∨ a :=
  or_rotate.1

theorem or_of_or_of_imp_of_imp (h₁ : a ∨ b) (h₂ : a → c) (h₃ : b → d) : c ∨ d :=
  Or.impₓ h₂ h₃ h₁

theorem or_of_or_of_imp_left (h₁ : a ∨ c) (h : a → b) : b ∨ c :=
  Or.imp_left h h₁

theorem or_of_or_of_imp_right (h₁ : c ∨ a) (h : a → b) : c ∨ b :=
  Or.imp_right h h₁

theorem Or.elim3 (h : a ∨ b ∨ c) (ha : a → d) (hb : b → d) (hc : c → d) : d :=
  Or.elim h ha fun h₂ => Or.elim h₂ hb hc

theorem Or.imp3 (had : a → d) (hbe : b → e) (hcf : c → f) : a ∨ b ∨ c → d ∨ e ∨ f :=
  Or.impₓ had <| Or.impₓ hbe hcf

theorem or_imp_distrib : a ∨ b → c ↔ (a → c) ∧ (b → c) :=
  ⟨fun h => ⟨fun ha => h (Or.inl ha), fun hb => h (Or.inr hb)⟩, fun ⟨ha, hb⟩ => Or.ndrec ha hb⟩

-- See Note [decidable namespace]
protected theorem Decidable.or_iff_not_imp_left [Decidable a] : a ∨ b ↔ ¬a → b :=
  ⟨Or.resolve_left, fun h => dite _ Or.inl (Or.inr ∘ h)⟩

theorem or_iff_not_imp_left : a ∨ b ↔ ¬a → b :=
  Decidable.or_iff_not_imp_left

-- See Note [decidable namespace]
protected theorem Decidable.or_iff_not_imp_right [Decidable b] : a ∨ b ↔ ¬b → a :=
  Or.comm.trans Decidable.or_iff_not_imp_left

theorem or_iff_not_imp_right : a ∨ b ↔ ¬b → a :=
  Decidable.or_iff_not_imp_right

-- See Note [decidable namespace]
protected theorem Decidable.not_or_of_imp [Decidable a] (h : a → b) : ¬a ∨ b :=
  dite _ (Or.inr ∘ h) Or.inl

theorem not_or_of_imp : (a → b) → ¬a ∨ b :=
  Decidable.not_or_of_imp

-- See Note [decidable namespace]
protected theorem Decidable.or_not_of_imp [Decidable a] (h : a → b) : b ∨ ¬a :=
  dite _ (Or.inl ∘ h) Or.inr

theorem or_not_of_imp : (a → b) → b ∨ ¬a :=
  Decidable.or_not_of_imp

-- See Note [decidable namespace]
protected theorem Decidable.imp_iff_not_or [Decidable a] : a → b ↔ ¬a ∨ b :=
  ⟨Decidable.not_or_of_imp, Or.neg_resolve_left⟩

theorem imp_iff_not_or : a → b ↔ ¬a ∨ b :=
  Decidable.imp_iff_not_or

-- See Note [decidable namespace]
protected theorem Decidable.imp_iff_or_not [Decidable b] : b → a ↔ a ∨ ¬b :=
  Decidable.imp_iff_not_or.trans Or.comm

theorem imp_iff_or_not : b → a ↔ a ∨ ¬b :=
  Decidable.imp_iff_or_not

-- See Note [decidable namespace]
protected theorem Decidable.not_imp_not [Decidable a] : ¬a → ¬b ↔ b → a :=
  ⟨fun h hb => Decidable.by_contradiction fun na => h na hb, mt⟩

theorem not_imp_not : ¬a → ¬b ↔ b → a :=
  Decidable.not_imp_not

/-- Provide the reverse of modus tollens (`mt`) as dot notation for implications. -/
protected theorem Function.mtr : (¬a → ¬b) → b → a :=
  not_imp_not.mp

-- See Note [decidable namespace]
protected theorem Decidable.or_congr_left [Decidable c] (h : ¬c → (a ↔ b)) : a ∨ c ↔ b ∨ c := by
  rw [Decidable.or_iff_not_imp_right, Decidable.or_iff_not_imp_right]
  exact imp_congr_right h

theorem or_congr_leftₓ (h : ¬c → (a ↔ b)) : a ∨ c ↔ b ∨ c :=
  Decidable.or_congr_left h

-- See Note [decidable namespace]
protected theorem Decidable.or_congr_right [Decidable a] (h : ¬a → (b ↔ c)) : a ∨ b ↔ a ∨ c := by
  rw [Decidable.or_iff_not_imp_left, Decidable.or_iff_not_imp_left]
  exact imp_congr_right h

theorem or_congr_rightₓ (h : ¬a → (b ↔ c)) : a ∨ b ↔ a ∨ c :=
  Decidable.or_congr_right h

@[simp]
theorem or_iff_left_iff_imp : (a ∨ b ↔ a) ↔ b → a :=
  ⟨fun h hb => h.1 (Or.inr hb), or_iff_left_of_imp⟩

@[simp]
theorem or_iff_right_iff_imp : (a ∨ b ↔ b) ↔ a → b := by
  rw [or_comm, or_iff_left_iff_imp]

theorem or_iff_left (hb : ¬b) : a ∨ b ↔ a :=
  ⟨fun h => h.resolve_right hb, Or.inl⟩

theorem or_iff_right (ha : ¬a) : a ∨ b ↔ b :=
  ⟨fun h => h.resolve_left ha, Or.inr⟩

/-! ### Declarations about distributivity -/


/-- `∧` distributes over `∨` (on the left). -/
theorem and_or_distrib_left : a ∧ (b ∨ c) ↔ a ∧ b ∨ a ∧ c :=
  ⟨fun ⟨ha, hbc⟩ => hbc.imp (And.intro ha) (And.intro ha), Or.ndrec (And.imp_right Or.inl) (And.imp_right Or.inr)⟩

/-- `∧` distributes over `∨` (on the right). -/
theorem or_and_distrib_right : (a ∨ b) ∧ c ↔ a ∧ c ∨ b ∧ c :=
  (And.comm.trans and_or_distrib_left).trans (And.comm.Or And.comm)

/-- `∨` distributes over `∧` (on the left). -/
theorem or_and_distrib_left : a ∨ b ∧ c ↔ (a ∨ b) ∧ (a ∨ c) :=
  ⟨Or.ndrec (fun ha => And.intro (Or.inl ha) (Or.inl ha)) (And.imp Or.inr Or.inr),
    And.ndrec <| Or.ndrec (imp_intro ∘ Or.inl) (Or.imp_right ∘ And.intro)⟩

/-- `∨` distributes over `∧` (on the right). -/
theorem and_or_distrib_right : a ∧ b ∨ c ↔ (a ∨ c) ∧ (b ∨ c) :=
  (Or.comm.trans or_and_distrib_left).trans (Or.comm.And Or.comm)

@[simp]
theorem or_self_left : a ∨ a ∨ b ↔ a ∨ b :=
  ⟨fun h => h.elim Or.inl id, fun h => h.elim Or.inl (Or.inr ∘ Or.inr)⟩

@[simp]
theorem or_self_right : (a ∨ b) ∨ b ↔ a ∨ b :=
  ⟨fun h => h.elim id Or.inr, fun h => h.elim (Or.inl ∘ Or.inl) Or.inr⟩

/-! Declarations about `iff` -/


theorem Iff.iff (h₁ : a ↔ b) (h₂ : c ↔ d) : (a ↔ c) ↔ (b ↔ d) :=
  iff_congr h₁ h₂

theorem iff_of_true (ha : a) (hb : b) : a ↔ b :=
  ⟨fun _ => hb, fun _ => ha⟩

theorem iff_of_false (ha : ¬a) (hb : ¬b) : a ↔ b :=
  ⟨ha.elim, hb.elim⟩

theorem iff_true_left (ha : a) : (a ↔ b) ↔ b :=
  ⟨fun h => h.1 ha, iff_of_true ha⟩

theorem iff_true_right (ha : a) : (b ↔ a) ↔ b :=
  Iff.comm.trans (iff_true_left ha)

theorem iff_false_left (ha : ¬a) : (a ↔ b) ↔ ¬b :=
  ⟨fun h => mt h.2 ha, iff_of_false ha⟩

theorem iff_false_right (ha : ¬a) : (b ↔ a) ↔ ¬b :=
  Iff.comm.trans (iff_false_left ha)

@[simp]
theorem iff_mpr_iff_true_intro {P : Prop} (h : P) : Iff.mpr (iff_true_intro h) True.intro = h :=
  rfl

-- See Note [decidable namespace]
protected theorem Decidable.imp_or_distrib [Decidable a] : a → b ∨ c ↔ (a → b) ∨ (a → c) := by
  simp [Decidable.imp_iff_not_or, Or.comm, Or.left_comm]

theorem imp_or_distrib : a → b ∨ c ↔ (a → b) ∨ (a → c) :=
  Decidable.imp_or_distrib

-- See Note [decidable namespace]
protected theorem Decidable.imp_or_distrib' [Decidable b] : a → b ∨ c ↔ (a → b) ∨ (a → c) := by
  by_cases' b <;> simp [h, or_iff_right_of_imp ((· ∘ ·) False.elim)]

theorem imp_or_distrib' : a → b ∨ c ↔ (a → b) ∨ (a → c) :=
  Decidable.imp_or_distrib'

theorem not_imp_of_and_not : a ∧ ¬b → ¬(a → b)
  | ⟨ha, hb⟩, h => hb <| h ha

-- See Note [decidable namespace]
protected theorem Decidable.not_imp [Decidable a] : ¬(a → b) ↔ a ∧ ¬b :=
  ⟨fun h => ⟨Decidable.of_not_imp h, not_of_not_imp h⟩, not_imp_of_and_not⟩

theorem not_imp : ¬(a → b) ↔ a ∧ ¬b :=
  Decidable.not_imp

-- for monotonicity
theorem imp_imp_imp (h₀ : c → a) (h₁ : b → d) : (a → b) → c → d := fun h₂ : a → b => h₁ ∘ h₂ ∘ h₀

-- See Note [decidable namespace]
protected theorem Decidable.peirce (a b : Prop) [Decidable a] : ((a → b) → a) → a :=
  if ha : a then fun h => ha else fun h => h ha.elim

theorem peirce (a b : Prop) : ((a → b) → a) → a :=
  Decidable.peirce _ _

theorem peirce' {a : Prop} (H : ∀ b : Prop, (a → b) → a) : a :=
  H _ id

-- See Note [decidable namespace]
protected theorem Decidable.not_iff_not [Decidable a] [Decidable b] : (¬a ↔ ¬b) ↔ (a ↔ b) := by
  rw [@iff_def ¬a, @iff_def' a] <;> exact decidable.not_imp_not.and Decidable.not_imp_not

theorem not_iff_not : (¬a ↔ ¬b) ↔ (a ↔ b) :=
  Decidable.not_iff_not

-- See Note [decidable namespace]
protected theorem Decidable.not_iff_comm [Decidable a] [Decidable b] : (¬a ↔ b) ↔ (¬b ↔ a) := by
  rw [@iff_def ¬a, @iff_def ¬b] <;> exact decidable.not_imp_comm.and imp_not_comm

theorem not_iff_comm : (¬a ↔ b) ↔ (¬b ↔ a) :=
  Decidable.not_iff_comm

-- See Note [decidable namespace]
protected theorem Decidable.not_iff : ∀ [Decidable b], ¬(a ↔ b) ↔ (¬a ↔ b) := by
  intro h <;> cases h <;> simp only [h, iff_trueₓ, iff_falseₓ]

theorem not_iff : ¬(a ↔ b) ↔ (¬a ↔ b) :=
  Decidable.not_iff

-- See Note [decidable namespace]
protected theorem Decidable.iff_not_comm [Decidable a] [Decidable b] : (a ↔ ¬b) ↔ (b ↔ ¬a) := by
  rw [@iff_def a, @iff_def b] <;> exact imp_not_comm.and Decidable.not_imp_comm

theorem iff_not_comm : (a ↔ ¬b) ↔ (b ↔ ¬a) :=
  Decidable.iff_not_comm

-- See Note [decidable namespace]
protected theorem Decidable.iff_iff_and_or_not_and_not [Decidable b] : (a ↔ b) ↔ a ∧ b ∨ ¬a ∧ ¬b := by
  constructor <;> intro h
  · rw [h] <;> by_cases' b <;> [left, right] <;> constructor <;> assumption
    
  · cases' h with h h <;>
      cases h <;>
        constructor <;>
          intro <;>
            · first |
                contradiction|
                assumption
              
    

theorem iff_iff_and_or_not_and_not : (a ↔ b) ↔ a ∧ b ∨ ¬a ∧ ¬b :=
  Decidable.iff_iff_and_or_not_and_not

theorem Decidable.iff_iff_not_or_and_or_not [Decidable a] [Decidable b] : (a ↔ b) ↔ (¬a ∨ b) ∧ (a ∨ ¬b) := by
  rw [iff_iff_implies_and_implies a b]
  simp only [Decidable.imp_iff_not_or, Or.comm]

theorem iff_iff_not_or_and_or_not : (a ↔ b) ↔ (¬a ∨ b) ∧ (a ∨ ¬b) :=
  Decidable.iff_iff_not_or_and_or_not

-- See Note [decidable namespace]
protected theorem Decidable.not_and_not_right [Decidable b] : ¬(a ∧ ¬b) ↔ a → b :=
  ⟨fun h ha => h.decidable_imp_symm <| And.intro ha, fun h ⟨ha, hb⟩ => hb <| h ha⟩

theorem not_and_not_right : ¬(a ∧ ¬b) ↔ a → b :=
  Decidable.not_and_not_right

/-- Transfer decidability of `a` to decidability of `b`, if the propositions are equivalent.
**Important**: this function should be used instead of `rw` on `decidable b`, because the
kernel will get stuck reducing the usage of `propext` otherwise,
and `dec_trivial` will not work. -/
@[inline]
def decidableOfIff (a : Prop) (h : a ↔ b) [D : Decidable a] : Decidable b :=
  decidableOfDecidableOfIff D h

/-- Transfer decidability of `b` to decidability of `a`, if the propositions are equivalent.
This is the same as `decidable_of_iff` but the iff is flipped. -/
@[inline]
def decidableOfIff' (b : Prop) (h : a ↔ b) [D : Decidable b] : Decidable a :=
  decidableOfDecidableOfIff D h.symm

/-- Prove that `a` is decidable by constructing a boolean `b` and a proof that `b ↔ a`.
(This is sometimes taken as an alternate definition of decidability.) -/
def decidableOfBool : ∀ (b : Bool) (h : b ↔ a), Decidable a
  | tt, h => isTrue (h.1 rfl)
  | ff, h => isFalse (mt h.2 Bool.ff_ne_tt)

/-! ### De Morgan's laws -/


theorem not_and_of_not_or_not (h : ¬a ∨ ¬b) : ¬(a ∧ b)
  | ⟨ha, hb⟩ => Or.elim h (absurd ha) (absurd hb)

-- See Note [decidable namespace]
protected theorem Decidable.not_and_distrib [Decidable a] : ¬(a ∧ b) ↔ ¬a ∨ ¬b :=
  ⟨fun h => if ha : a then Or.inr fun hb => h ⟨ha, hb⟩ else Or.inl ha, not_and_of_not_or_not⟩

-- See Note [decidable namespace]
protected theorem Decidable.not_and_distrib' [Decidable b] : ¬(a ∧ b) ↔ ¬a ∨ ¬b :=
  ⟨fun h => if hb : b then Or.inl fun ha => h ⟨ha, hb⟩ else Or.inr hb, not_and_of_not_or_not⟩

/-- One of de Morgan's laws: the negation of a conjunction is logically equivalent to the
disjunction of the negations. -/
theorem not_and_distrib : ¬(a ∧ b) ↔ ¬a ∨ ¬b :=
  Decidable.not_and_distrib

@[simp]
theorem not_and : ¬(a ∧ b) ↔ a → ¬b :=
  and_imp

theorem not_and' : ¬(a ∧ b) ↔ b → ¬a :=
  not_and.trans imp_not_comm

/-- One of de Morgan's laws: the negation of a disjunction is logically equivalent to the
conjunction of the negations. -/
theorem not_or_distrib : ¬(a ∨ b) ↔ ¬a ∧ ¬b :=
  ⟨fun h => ⟨fun ha => h (Or.inl ha), fun hb => h (Or.inr hb)⟩, fun ⟨h₁, h₂⟩ h => Or.elim h h₁ h₂⟩

-- See Note [decidable namespace]
protected theorem Decidable.or_iff_not_and_not [Decidable a] [Decidable b] : a ∨ b ↔ ¬(¬a ∧ ¬b) := by
  rw [← not_or_distrib, Decidable.not_not]

theorem or_iff_not_and_not : a ∨ b ↔ ¬(¬a ∧ ¬b) :=
  Decidable.or_iff_not_and_not

-- See Note [decidable namespace]
protected theorem Decidable.and_iff_not_or_not [Decidable a] [Decidable b] : a ∧ b ↔ ¬(¬a ∨ ¬b) := by
  rw [← Decidable.not_and_distrib, Decidable.not_not]

theorem and_iff_not_or_not : a ∧ b ↔ ¬(¬a ∨ ¬b) :=
  Decidable.and_iff_not_or_not

@[simp]
theorem not_xor (P Q : Prop) : ¬Xorₓ P Q ↔ (P ↔ Q) := by
  simp only [not_and, Xorₓ, not_or_distrib, not_not, ← iff_iff_implies_and_implies]

theorem xor_iff_not_iff (P Q : Prop) : Xorₓ P Q ↔ ¬(P ↔ Q) := by
  rw [iff_not_comm, not_xor]

end Propositional

/-! ### Declarations about equality -/


section Mem

variable {α β : Type _} [Membership α β] {s t : β} {a b : α}

theorem ne_of_mem_of_not_mem (h : a ∈ s) : b ∉ s → a ≠ b :=
  mt fun e => e ▸ h

theorem ne_of_mem_of_not_mem' (h : a ∈ s) : a ∉ t → s ≠ t :=
  mt fun e => e ▸ h

/-- **Alias** of `ne_of_mem_of_not_mem`. -/
theorem Membership.Mem.ne_of_not_mem : a ∈ s → b ∉ s → a ≠ b :=
  ne_of_mem_of_not_mem

/-- **Alias** of `ne_of_mem_of_not_mem'`. -/
theorem Membership.Mem.ne_of_not_mem' : a ∈ s → a ∉ t → s ≠ t :=
  ne_of_mem_of_not_mem'

end Mem

section Equality

variable {α : Sort _} {a b : α}

@[simp]
theorem heq_iff_eq : HEq a b ↔ a = b :=
  ⟨eq_of_heq, heq_of_eq⟩

theorem proof_irrel_heq {p q : Prop} (hp : p) (hq : q) : HEq hp hq := by
  have : p = q := propext ⟨fun _ => hq, fun _ => hp⟩
  subst q <;> rfl

-- todo: change name
theorem ball_cond_comm {α} {s : α → Prop} {p : α → α → Prop} :
    (∀ a, s a → ∀ b, s b → p a b) ↔ ∀ a b, s a → s b → p a b :=
  ⟨fun h a b ha hb => h a ha b hb, fun h a ha b hb => h a b ha hb⟩

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (a b «expr ∈ » s)
theorem ball_mem_comm {α β} [Membership α β] {s : β} {p : α → α → Prop} :
    (∀ (a b) (_ : a ∈ s) (_ : b ∈ s), p a b) ↔ ∀ a b, a ∈ s → b ∈ s → p a b :=
  ball_cond_comm

theorem ne_of_apply_ne {α β : Sort _} (f : α → β) {x y : α} (h : f x ≠ f y) : x ≠ y := fun w : x = y =>
  h (congr_argₓ f w)

theorem eq_equivalence : Equivalenceₓ (@Eq α) :=
  ⟨Eq.refl, @Eq.symm _, @Eq.trans _⟩

/-- Transport through trivial families is the identity. -/
@[simp]
theorem eq_rec_constantₓ {α : Sort _} {a a' : α} {β : Sort _} (y : β) (h : a = a') :
    @Eq.ndrec α a (fun a => β) y a' h = y := by
  cases h
  rfl

@[simp]
theorem eq_mp_eq_cast {α β : Sort _} (h : α = β) : Eq.mp h = cast h :=
  rfl

@[simp]
theorem eq_mpr_eq_cast {α β : Sort _} (h : α = β) : Eq.mpr h = cast h.symm :=
  rfl

@[simp]
theorem cast_cast : ∀ {α β γ : Sort _} (ha : α = β) (hb : β = γ) (a : α), cast hb (cast ha a) = cast (ha.trans hb) a
  | _, _, _, rfl, rfl, a => rfl

@[simp]
theorem congr_refl_left {α β : Sort _} (f : α → β) {a b : α} (h : a = b) : congr (Eq.refl f) h = congr_argₓ f h :=
  rfl

@[simp]
theorem congr_refl_right {α β : Sort _} {f g : α → β} (h : f = g) (a : α) : congr h (Eq.refl a) = congr_funₓ h a :=
  rfl

@[simp]
theorem congr_arg_refl {α β : Sort _} (f : α → β) (a : α) : congr_argₓ f (Eq.refl a) = Eq.refl (f a) :=
  rfl

@[simp]
theorem congr_fun_rfl {α β : Sort _} (f : α → β) (a : α) : congr_funₓ (Eq.refl f) a = Eq.refl (f a) :=
  rfl

@[simp]
theorem congr_fun_congr_arg {α β γ : Sort _} (f : α → β → γ) {a a' : α} (p : a = a') (b : β) :
    congr_funₓ (congr_argₓ f p) b = congr_argₓ (fun a => f a b) p :=
  rfl

theorem heq_of_cast_eq : ∀ {α β : Sort _} {a : α} {a' : β} (e : α = β) (h₂ : cast e a = a'), HEq a a'
  | α, _, a, a', rfl, h => Eq.recOnₓ h (HEq.refl _)

theorem cast_eq_iff_heq {α β : Sort _} {a : α} {a' : β} {e : α = β} : cast e a = a' ↔ HEq a a' :=
  ⟨heq_of_cast_eq _, fun h => by
    cases h <;> rfl⟩

theorem rec_heq_of_heq {β} {C : α → Sort _} {x : C a} {y : β} (eq : a = b) (h : HEq x y) :
    HEq (@Eq.ndrec α a C x b Eq) y := by
  subst Eq <;> exact h

protected theorem Eq.congr {x₁ x₂ y₁ y₂ : α} (h₁ : x₁ = y₁) (h₂ : x₂ = y₂) : x₁ = x₂ ↔ y₁ = y₂ := by
  subst h₁
  subst h₂

theorem Eq.congr_left {x y z : α} (h : x = y) : x = z ↔ y = z := by
  rw [h]

theorem Eq.congr_right {x y z : α} (h : x = y) : z = x ↔ z = y := by
  rw [h]

theorem congr_arg2ₓ {α β γ : Sort _} (f : α → β → γ) {x x' : α} {y y' : β} (hx : x = x') (hy : y = y') :
    f x y = f x' y' := by
  subst hx
  subst hy

variable {β : α → Sort _} {γ : ∀ a, β a → Sort _} {δ : ∀ a b, γ a b → Sort _}

theorem congr_fun₂ {f g : ∀ a b, γ a b} (h : f = g) (a : α) (b : β a) : f a b = g a b :=
  congr_funₓ (congr_funₓ h _) _

theorem congr_fun₃ {f g : ∀ a b c, δ a b c} (h : f = g) (a : α) (b : β a) (c : γ a b) : f a b c = g a b c :=
  congr_fun₂ (congr_funₓ h _) _ _

theorem funext₂ {f g : ∀ a b, γ a b} (h : ∀ a b, f a b = g a b) : f = g :=
  funext fun _ => funext <| h _

theorem funext₃ {f g : ∀ a b c, δ a b c} (h : ∀ a b c, f a b c = g a b c) : f = g :=
  funext fun _ => funext₂ <| h _

end Equality

/-! ### Declarations about quantifiers -/


section Quantifiers

variable {α : Sort _}

section Dependent

variable {β : α → Sort _} {γ : ∀ a, β a → Sort _} {δ : ∀ a b, γ a b → Sort _} {ε : ∀ a b c, δ a b c → Sort _}

theorem pi_congr {β' : α → Sort _} (h : ∀ a, β a = β' a) : (∀ a, β a) = ∀ a, β' a :=
  (funext h : β = β') ▸ rfl

theorem forall₂_congrₓ {p q : ∀ a, β a → Prop} (h : ∀ a b, p a b ↔ q a b) : (∀ a b, p a b) ↔ ∀ a b, q a b :=
  forall_congrₓ fun a => forall_congrₓ <| h a

theorem forall₃_congrₓ {p q : ∀ a b, γ a b → Prop} (h : ∀ a b c, p a b c ↔ q a b c) :
    (∀ a b c, p a b c) ↔ ∀ a b c, q a b c :=
  forall_congrₓ fun a => forall₂_congrₓ <| h a

theorem forall₄_congrₓ {p q : ∀ a b c, δ a b c → Prop} (h : ∀ a b c d, p a b c d ↔ q a b c d) :
    (∀ a b c d, p a b c d) ↔ ∀ a b c d, q a b c d :=
  forall_congrₓ fun a => forall₃_congrₓ <| h a

theorem forall₅_congr {p q : ∀ a b c d, ε a b c d → Prop} (h : ∀ a b c d e, p a b c d e ↔ q a b c d e) :
    (∀ a b c d e, p a b c d e) ↔ ∀ a b c d e, q a b c d e :=
  forall_congrₓ fun a => forall₄_congrₓ <| h a

theorem exists₂_congrₓ {p q : ∀ a, β a → Prop} (h : ∀ a b, p a b ↔ q a b) : (∃ a b, p a b) ↔ ∃ a b, q a b :=
  exists_congr fun a => exists_congr <| h a

theorem exists₃_congrₓ {p q : ∀ a b, γ a b → Prop} (h : ∀ a b c, p a b c ↔ q a b c) :
    (∃ a b c, p a b c) ↔ ∃ a b c, q a b c :=
  exists_congr fun a => exists₂_congrₓ <| h a

theorem exists₄_congrₓ {p q : ∀ a b c, δ a b c → Prop} (h : ∀ a b c d, p a b c d ↔ q a b c d) :
    (∃ a b c d, p a b c d) ↔ ∃ a b c d, q a b c d :=
  exists_congr fun a => exists₃_congrₓ <| h a

theorem exists₅_congr {p q : ∀ a b c d, ε a b c d → Prop} (h : ∀ a b c d e, p a b c d e ↔ q a b c d e) :
    (∃ a b c d e, p a b c d e) ↔ ∃ a b c d e, q a b c d e :=
  exists_congr fun a => exists₄_congrₓ <| h a

theorem forall_imp {p q : α → Prop} (h : ∀ a, p a → q a) : (∀ a, p a) → ∀ a, q a := fun h' a => h a (h' a)

theorem forall₂_imp {p q : ∀ a, β a → Prop} (h : ∀ a b, p a b → q a b) : (∀ a b, p a b) → ∀ a b, q a b :=
  forall_imp fun i => forall_imp <| h i

theorem forall₃_imp {p q : ∀ a b, γ a b → Prop} (h : ∀ a b c, p a b c → q a b c) :
    (∀ a b c, p a b c) → ∀ a b c, q a b c :=
  forall_imp fun a => forall₂_imp <| h a

theorem Exists.imp {p q : α → Prop} (h : ∀ a, p a → q a) : (∃ a, p a) → ∃ a, q a :=
  exists_imp_exists h

theorem Exists₂.imp {p q : ∀ a, β a → Prop} (h : ∀ a b, p a b → q a b) : (∃ a b, p a b) → ∃ a b, q a b :=
  Exists.imp fun a => Exists.imp <| h a

theorem Exists₃.imp {p q : ∀ a b, γ a b → Prop} (h : ∀ a b c, p a b c → q a b c) :
    (∃ a b c, p a b c) → ∃ a b c, q a b c :=
  Exists.imp fun a => Exists₂.imp <| h a

end Dependent

variable {ι β : Sort _} {κ : ι → Sort _} {p q : α → Prop} {b : Prop}

theorem exists_imp_exists'ₓ {p : α → Prop} {q : β → Prop} (f : α → β) (hpq : ∀ a, p a → q (f a)) (hp : ∃ a, p a) :
    ∃ b, q b :=
  Exists.elim hp fun a hp' => ⟨_, hpq _ hp'⟩

theorem forall_swap {p : α → β → Prop} : (∀ x y, p x y) ↔ ∀ y x, p x y :=
  ⟨swap, swap⟩

theorem forall₂_swap {ι₁ ι₂ : Sort _} {κ₁ : ι₁ → Sort _} {κ₂ : ι₂ → Sort _} {p : ∀ i₁, κ₁ i₁ → ∀ i₂, κ₂ i₂ → Prop} :
    (∀ i₁ j₁ i₂ j₂, p i₁ j₁ i₂ j₂) ↔ ∀ i₂ j₂ i₁ j₁, p i₁ j₁ i₂ j₂ :=
  ⟨swap₂, swap₂⟩

/-- We intentionally restrict the type of `α` in this lemma so that this is a safer to use in simp
than `forall_swap`. -/
theorem imp_forall_iff {α : Type _} {p : Prop} {q : α → Prop} : (p → ∀ x, q x) ↔ ∀ x, p → q x :=
  forall_swap

theorem exists_swap {p : α → β → Prop} : (∃ x y, p x y) ↔ ∃ y x, p x y :=
  ⟨fun ⟨x, y, h⟩ => ⟨y, x, h⟩, fun ⟨y, x, h⟩ => ⟨x, y, h⟩⟩

@[simp]
theorem forall_exists_index {q : (∃ x, p x) → Prop} : (∀ h, q h) ↔ ∀ (x) (h : p x), q ⟨x, h⟩ :=
  ⟨fun h x hpx => h ⟨x, hpx⟩, fun h ⟨x, hpx⟩ => h x hpx⟩

theorem exists_imp_distrib : (∃ x, p x) → b ↔ ∀ x, p x → b :=
  forall_exists_index

-- This enables projection notation.
/-- Extract an element from a existential statement, using `classical.some`.
-/
@[reducible]
noncomputable def Exists.some {p : α → Prop} (P : ∃ a, p a) : α :=
  Classical.choose P

/-- Show that an element extracted from `P : ∃ a, p a` using `P.some` satisfies `p`.
-/
theorem Exists.some_spec {p : α → Prop} (P : ∃ a, p a) : p P.some :=
  Classical.choose_spec P

--theorem forall_not_of_not_exists (h : ¬ ∃ x, p x) : ∀ x, ¬ p x :=
--forall_imp_of_exists_imp h
theorem not_exists_of_forall_not (h : ∀ x, ¬p x) : ¬∃ x, p x :=
  exists_imp_distrib.2 h

@[simp]
theorem not_exists : (¬∃ x, p x) ↔ ∀ x, ¬p x :=
  exists_imp_distrib

theorem not_forall_of_exists_not : (∃ x, ¬p x) → ¬∀ x, p x
  | ⟨x, hn⟩, h => hn (h x)

-- See Note [decidable namespace]
protected theorem Decidable.not_forall {p : α → Prop} [Decidable (∃ x, ¬p x)] [∀ x, Decidable (p x)] :
    (¬∀ x, p x) ↔ ∃ x, ¬p x :=
  ⟨Not.decidable_imp_symm fun nx x => nx.decidable_imp_symm fun h => ⟨x, h⟩, not_forall_of_exists_not⟩

@[simp]
theorem not_forall {p : α → Prop} : (¬∀ x, p x) ↔ ∃ x, ¬p x :=
  Decidable.not_forall

-- See Note [decidable namespace]
protected theorem Decidable.not_forall_not [Decidable (∃ x, p x)] : (¬∀ x, ¬p x) ↔ ∃ x, p x :=
  (@Decidable.not_iff_comm _ _ _ (decidableOfIff (¬∃ x, p x) not_exists)).1 not_exists

theorem not_forall_not : (¬∀ x, ¬p x) ↔ ∃ x, p x :=
  Decidable.not_forall_not

-- See Note [decidable namespace]
protected theorem Decidable.not_exists_not [∀ x, Decidable (p x)] : (¬∃ x, ¬p x) ↔ ∀ x, p x := by
  simp [Decidable.not_not]

@[simp]
theorem not_exists_not : (¬∃ x, ¬p x) ↔ ∀ x, p x :=
  Decidable.not_exists_not

theorem forall_imp_iff_exists_imp [ha : Nonempty α] : (∀ x, p x) → b ↔ ∃ x, p x → b :=
  let ⟨a⟩ := ha
  ⟨fun h =>
    not_forall_not.1 fun h' =>
      Classical.by_cases (fun hb : b => (h' a) fun _ => hb) fun hb => hb <| h fun x => (not_imp.1 (h' x)).1,
    fun ⟨x, hx⟩ h => hx (h x)⟩

-- TODO: duplicate of a lemma in core
theorem forall_true_iff : α → True ↔ True :=
  implies_true_iff α

-- Unfortunately this causes simp to loop sometimes, so we
-- add the 2 and 3 cases as simp lemmas instead
theorem forall_true_iff' (h : ∀ a, p a ↔ True) : (∀ a, p a) ↔ True :=
  iff_true_intro fun _ => of_iff_true (h _)

@[simp]
theorem forall_2_true_iff {β : α → Sort _} : (∀ a, β a → True) ↔ True :=
  forall_true_iff' fun _ => forall_true_iff

@[simp]
theorem forall_3_true_iff {β : α → Sort _} {γ : ∀ a, β a → Sort _} : (∀ (a) (b : β a), γ a b → True) ↔ True :=
  forall_true_iff' fun _ => forall_2_true_iff

theorem ExistsUnique.exists {α : Sort _} {p : α → Prop} (h : ∃! x, p x) : ∃ x, p x :=
  Exists.elim h fun x hx => ⟨x, And.left hx⟩

@[simp]
theorem exists_unique_iff_exists {α : Sort _} [Subsingleton α] {p : α → Prop} : (∃! x, p x) ↔ ∃ x, p x :=
  ⟨fun h => h.exists, Exists.imp fun x hx => ⟨hx, fun y _ => Subsingleton.elim y x⟩⟩

@[simp]
theorem forall_const (α : Sort _) [i : Nonempty α] : α → b ↔ b :=
  ⟨i.elim, fun hb x => hb⟩

/-- For some reason simp doesn't use `forall_const` to simplify in this case. -/
@[simp]
theorem forall_forall_const {α β : Type _} (p : β → Prop) [Nonempty α] : (∀ x, α → p x) ↔ ∀ x, p x :=
  forall_congrₓ fun x => forall_const α

@[simp]
theorem exists_const (α : Sort _) [i : Nonempty α] : (∃ x : α, b) ↔ b :=
  ⟨fun ⟨x, h⟩ => h, i.elim Exists.introₓ⟩

theorem exists_unique_const (α : Sort _) [i : Nonempty α] [Subsingleton α] : (∃! x : α, b) ↔ b := by
  simp

theorem forall_and_distrib : (∀ x, p x ∧ q x) ↔ (∀ x, p x) ∧ ∀ x, q x :=
  ⟨fun h => ⟨fun x => (h x).left, fun x => (h x).right⟩, fun ⟨h₁, h₂⟩ x => ⟨h₁ x, h₂ x⟩⟩

theorem exists_or_distrib : (∃ x, p x ∨ q x) ↔ (∃ x, p x) ∨ ∃ x, q x :=
  ⟨fun ⟨x, hpq⟩ => hpq.elim (fun hpx => Or.inl ⟨x, hpx⟩) fun hqx => Or.inr ⟨x, hqx⟩, fun hepq =>
    hepq.elim (fun ⟨x, hpx⟩ => ⟨x, Or.inl hpx⟩) fun ⟨x, hqx⟩ => ⟨x, Or.inr hqx⟩⟩

@[simp]
theorem exists_and_distrib_left {q : Prop} {p : α → Prop} : (∃ x, q ∧ p x) ↔ q ∧ ∃ x, p x :=
  ⟨fun ⟨x, hq, hp⟩ => ⟨hq, x, hp⟩, fun ⟨hq, x, hp⟩ => ⟨x, hq, hp⟩⟩

@[simp]
theorem exists_and_distrib_right {q : Prop} {p : α → Prop} : (∃ x, p x ∧ q) ↔ (∃ x, p x) ∧ q := by
  simp [and_comm]

@[simp]
theorem forall_eq {a' : α} : (∀ a, a = a' → p a) ↔ p a' :=
  ⟨fun h => h a' rfl, fun h a e => e.symm ▸ h⟩

@[simp]
theorem forall_eq' {a' : α} : (∀ a, a' = a → p a) ↔ p a' := by
  simp [@eq_comm _ a']

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ≠ » a)
theorem and_forall_ne (a : α) : (p a ∧ ∀ (b) (_ : b ≠ a), p b) ↔ ∀ b, p b := by
  simp only [← @forall_eq _ p a, ← forall_and_distrib, ← or_imp_distrib, Classical.em, forall_const]

-- this lemma is needed to simplify the output of `list.mem_cons_iff`
@[simp]
theorem forall_eq_or_imp {a' : α} : (∀ a, a = a' ∨ q a → p a) ↔ p a' ∧ ∀ a, q a → p a := by
  simp only [or_imp_distrib, forall_and_distrib, forall_eq]

theorem Ne.ne_or_ne {x y : α} (z : α) (h : x ≠ y) : x ≠ z ∨ y ≠ z :=
  not_and_distrib.1 <| mt (and_imp.2 Eq.substr) h.symm

theorem exists_eq {a' : α} : ∃ a, a = a' :=
  ⟨_, rfl⟩

@[simp]
theorem exists_eq' {a' : α} : ∃ a, a' = a :=
  ⟨_, rfl⟩

@[simp]
theorem exists_unique_eq {a' : α} : ∃! a, a = a' := by
  simp only [eq_comm, ExistsUnique, and_selfₓ, forall_eq', exists_eq']

@[simp]
theorem exists_unique_eq' {a' : α} : ∃! a, a' = a := by
  simp only [ExistsUnique, and_selfₓ, forall_eq', exists_eq']

@[simp]
theorem exists_eq_left {a' : α} : (∃ a, a = a' ∧ p a) ↔ p a' :=
  ⟨fun ⟨a, e, h⟩ => e ▸ h, fun h => ⟨_, rfl, h⟩⟩

@[simp]
theorem exists_eq_right {a' : α} : (∃ a, p a ∧ a = a') ↔ p a' :=
  (exists_congr fun a => And.comm).trans exists_eq_left

@[simp]
theorem exists_eq_right_rightₓ {a' : α} : (∃ a : α, p a ∧ q a ∧ a = a') ↔ p a' ∧ q a' :=
  ⟨fun ⟨_, hp, hq, rfl⟩ => ⟨hp, hq⟩, fun ⟨hp, hq⟩ => ⟨a', hp, hq, rfl⟩⟩

@[simp]
theorem exists_eq_right_right'ₓ {a' : α} : (∃ a : α, p a ∧ q a ∧ a' = a) ↔ p a' ∧ q a' :=
  ⟨fun ⟨_, hp, hq, rfl⟩ => ⟨hp, hq⟩, fun ⟨hp, hq⟩ => ⟨a', hp, hq, rfl⟩⟩

@[simp]
theorem exists_apply_eq_applyₓ (f : α → β) (a' : α) : ∃ a, f a = f a' :=
  ⟨a', rfl⟩

@[simp]
theorem exists_apply_eq_apply' (f : α → β) (a' : α) : ∃ a, f a' = f a :=
  ⟨a', rfl⟩

@[simp]
theorem exists_exists_and_eq_and {f : α → β} {p : α → Prop} {q : β → Prop} :
    (∃ b, (∃ a, p a ∧ f a = b) ∧ q b) ↔ ∃ a, p a ∧ q (f a) :=
  ⟨fun ⟨b, ⟨a, ha, hab⟩, hb⟩ => ⟨a, ha, hab.symm ▸ hb⟩, fun ⟨a, hp, hq⟩ => ⟨f a, ⟨a, hp, rfl⟩, hq⟩⟩

@[simp]
theorem exists_exists_eq_and {f : α → β} {p : β → Prop} : (∃ b, (∃ a, f a = b) ∧ p b) ↔ ∃ a, p (f a) :=
  ⟨fun ⟨b, ⟨a, ha⟩, hb⟩ => ⟨a, ha.symm ▸ hb⟩, fun ⟨a, ha⟩ => ⟨f a, ⟨a, rfl⟩, ha⟩⟩

@[simp]
theorem exists_or_eq_left (y : α) (p : α → Prop) : ∃ x : α, x = y ∨ p x :=
  ⟨y, Or.inl rfl⟩

@[simp]
theorem exists_or_eq_right (y : α) (p : α → Prop) : ∃ x : α, p x ∨ x = y :=
  ⟨y, Or.inr rfl⟩

@[simp]
theorem exists_or_eq_left' (y : α) (p : α → Prop) : ∃ x : α, y = x ∨ p x :=
  ⟨y, Or.inl rfl⟩

@[simp]
theorem exists_or_eq_right' (y : α) (p : α → Prop) : ∃ x : α, p x ∨ y = x :=
  ⟨y, Or.inr rfl⟩

@[simp]
theorem forall_apply_eq_imp_iff {f : α → β} {p : β → Prop} : (∀ a, ∀ b, f a = b → p b) ↔ ∀ a, p (f a) :=
  ⟨fun h a => h a (f a) rfl, fun h a b hab => hab ▸ h a⟩

@[simp]
theorem forall_apply_eq_imp_iff' {f : α → β} {p : β → Prop} : (∀ b, ∀ a, f a = b → p b) ↔ ∀ a, p (f a) := by
  rw [forall_swap]
  simp

@[simp]
theorem forall_eq_apply_imp_iff {f : α → β} {p : β → Prop} : (∀ a, ∀ b, b = f a → p b) ↔ ∀ a, p (f a) := by
  simp [@eq_comm _ _ (f _)]

@[simp]
theorem forall_eq_apply_imp_iff' {f : α → β} {p : β → Prop} : (∀ b, ∀ a, b = f a → p b) ↔ ∀ a, p (f a) := by
  rw [forall_swap]
  simp

@[simp]
theorem forall_apply_eq_imp_iff₂ {f : α → β} {p : α → Prop} {q : β → Prop} :
    (∀ b, ∀ a, p a → f a = b → q b) ↔ ∀ a, p a → q (f a) :=
  ⟨fun h a ha => h (f a) a ha rfl, fun h b a ha hb => hb ▸ h a ha⟩

@[simp]
theorem exists_eq_left' {a' : α} : (∃ a, a' = a ∧ p a) ↔ p a' := by
  simp [@eq_comm _ a']

@[simp]
theorem exists_eq_right' {a' : α} : (∃ a, p a ∧ a' = a) ↔ p a' := by
  simp [@eq_comm _ a']

theorem exists_comm {p : α → β → Prop} : (∃ a b, p a b) ↔ ∃ b a, p a b :=
  ⟨fun ⟨a, b, h⟩ => ⟨b, a, h⟩, fun ⟨b, a, h⟩ => ⟨a, b, h⟩⟩

theorem exists₂_comm {ι₁ ι₂ : Sort _} {κ₁ : ι₁ → Sort _} {κ₂ : ι₂ → Sort _} {p : ∀ i₁, κ₁ i₁ → ∀ i₂, κ₂ i₂ → Prop} :
    (∃ i₁ j₁ i₂ j₂, p i₁ j₁ i₂ j₂) ↔ ∃ i₂ j₂ i₁ j₁, p i₁ j₁ i₂ j₂ := by
  simp only [@exists_comm (κ₁ _), @exists_comm ι₁]

theorem And.exists {p q : Prop} {f : p ∧ q → Prop} : (∃ h, f h) ↔ ∃ hp hq, f ⟨hp, hq⟩ :=
  ⟨fun ⟨h, H⟩ => ⟨h.1, h.2, H⟩, fun ⟨hp, hq, H⟩ => ⟨⟨hp, hq⟩, H⟩⟩

theorem forall_or_of_or_forall (h : b ∨ ∀ x, p x) (x) : b ∨ p x :=
  h.imp_right fun h₂ => h₂ x

-- See Note [decidable namespace]
protected theorem Decidable.forall_or_distrib_left {q : Prop} {p : α → Prop} [Decidable q] :
    (∀ x, q ∨ p x) ↔ q ∨ ∀ x, p x :=
  ⟨fun h => if hq : q then Or.inl hq else Or.inr fun x => (h x).resolve_left hq, forall_or_of_or_forall⟩

theorem forall_or_distrib_left {q : Prop} {p : α → Prop} : (∀ x, q ∨ p x) ↔ q ∨ ∀ x, p x :=
  Decidable.forall_or_distrib_left

-- See Note [decidable namespace]
protected theorem Decidable.forall_or_distrib_right {q : Prop} {p : α → Prop} [Decidable q] :
    (∀ x, p x ∨ q) ↔ (∀ x, p x) ∨ q := by
  simp [or_comm, Decidable.forall_or_distrib_left]

theorem forall_or_distrib_right {q : Prop} {p : α → Prop} : (∀ x, p x ∨ q) ↔ (∀ x, p x) ∨ q :=
  Decidable.forall_or_distrib_right

@[simp]
theorem exists_prop {p q : Prop} : (∃ h : p, q) ↔ p ∧ q :=
  ⟨fun ⟨h₁, h₂⟩ => ⟨h₁, h₂⟩, fun ⟨h₁, h₂⟩ => ⟨h₁, h₂⟩⟩

theorem exists_unique_prop {p q : Prop} : (∃! h : p, q) ↔ p ∧ q := by
  simp

@[simp]
theorem exists_false : ¬∃ a : α, False := fun ⟨a, h⟩ => h

@[simp]
theorem exists_unique_false : ¬∃! a : α, False := fun ⟨a, h, h'⟩ => h

theorem Exists.fst {p : b → Prop} : Exists p → b
  | ⟨h, _⟩ => h

theorem Exists.snd {p : b → Prop} : ∀ h : Exists p, p h.fst
  | ⟨_, h⟩ => h

theorem forall_prop_of_true {p : Prop} {q : p → Prop} (h : p) : (∀ h' : p, q h') ↔ q h :=
  @forall_const (q h) p ⟨h⟩

theorem exists_prop_of_true {p : Prop} {q : p → Prop} (h : p) : (∃ h' : p, q h') ↔ q h :=
  @exists_const (q h) p ⟨h⟩

theorem exists_iff_of_forall {p : Prop} {q : p → Prop} (h : ∀ h, q h) : (∃ h, q h) ↔ p :=
  ⟨Exists.fst, fun H => ⟨H, h H⟩⟩

theorem exists_unique_prop_of_true {p : Prop} {q : p → Prop} (h : p) : (∃! h' : p, q h') ↔ q h :=
  @exists_unique_const (q h) p ⟨h⟩ _

theorem forall_prop_of_false {p : Prop} {q : p → Prop} (hn : ¬p) : (∀ h' : p, q h') ↔ True :=
  iff_true_intro fun h => hn.elim h

theorem exists_prop_of_false {p : Prop} {q : p → Prop} : ¬p → ¬∃ h' : p, q h' :=
  mt Exists.fst

@[congr]
theorem exists_prop_congr {p p' : Prop} {q q' : p → Prop} (hq : ∀ h, q h ↔ q' h) (hp : p ↔ p') :
    Exists q ↔ ∃ h : p', q' (hp.2 h) :=
  ⟨fun ⟨_, _⟩ => ⟨hp.1 ‹_›, (hq _).1 ‹_›⟩, fun ⟨_, _⟩ => ⟨_, (hq _).2 ‹_›⟩⟩

@[congr]
theorem exists_prop_congr' {p p' : Prop} {q q' : p → Prop} (hq : ∀ h, q h ↔ q' h) (hp : p ↔ p') :
    Exists q = ∃ h : p', q' (hp.2 h) :=
  propext (exists_prop_congr hq _)

/-- See `is_empty.exists_iff` for the `false` version. -/
@[simp]
theorem exists_true_left (p : True → Prop) : (∃ x, p x) ↔ p True.intro :=
  exists_prop_of_true _

theorem ExistsUnique.unique {α : Sort _} {p : α → Prop} (h : ∃! x, p x) {y₁ y₂ : α} (py₁ : p y₁) (py₂ : p y₂) :
    y₁ = y₂ :=
  unique_of_exists_unique h py₁ py₂

@[congr]
theorem forall_prop_congr {p p' : Prop} {q q' : p → Prop} (hq : ∀ h, q h ↔ q' h) (hp : p ↔ p') :
    (∀ h, q h) ↔ ∀ h : p', q' (hp.2 h) :=
  ⟨fun h1 h2 => (hq _).1 (h1 (hp.2 _)), fun h1 h2 => (hq _).2 (h1 (hp.1 h2))⟩

@[congr]
theorem forall_prop_congr' {p p' : Prop} {q q' : p → Prop} (hq : ∀ h, q h ↔ q' h) (hp : p ↔ p') :
    (∀ h, q h) = ∀ h : p', q' (hp.2 h) :=
  propext (forall_prop_congr hq _)

/-- See `is_empty.forall_iff` for the `false` version. -/
@[simp]
theorem forall_true_left (p : True → Prop) : (∀ x, p x) ↔ p True.intro :=
  forall_prop_of_true _

theorem ExistsUnique.elim2 {α : Sort _} {p : α → Sort _} [∀ x, Subsingleton (p x)] {q : ∀ (x) (h : p x), Prop}
    {b : Prop} (h₂ : ∃! (x : _)(h : p x), q x h)
    (h₁ : ∀ (x) (h : p x), q x h → (∀ (y) (hy : p y), q y hy → y = x) → b) : b := by
  simp only [exists_unique_iff_exists] at h₂
  apply h₂.elim
  exact fun x ⟨hxp, hxq⟩ H => h₁ x hxp hxq fun y hyp hyq => H y ⟨hyp, hyq⟩

theorem ExistsUnique.intro2 {α : Sort _} {p : α → Sort _} [∀ x, Subsingleton (p x)] {q : ∀ (x : α) (h : p x), Prop}
    (w : α) (hp : p w) (hq : q w hp) (H : ∀ (y) (hy : p y), q y hy → y = w) : ∃! (x : _)(hx : p x), q x hx := by
  simp only [exists_unique_iff_exists]
  exact ExistsUnique.intro w ⟨hp, hq⟩ fun y ⟨hyp, hyq⟩ => H y hyp hyq

theorem ExistsUnique.exists2 {α : Sort _} {p : α → Sort _} {q : ∀ (x : α) (h : p x), Prop}
    (h : ∃! (x : _)(hx : p x), q x hx) : ∃ (x : _)(hx : p x), q x hx :=
  h.exists.imp fun x hx => hx.exists

theorem ExistsUnique.unique2 {α : Sort _} {p : α → Sort _} [∀ x, Subsingleton (p x)] {q : ∀ (x : α) (hx : p x), Prop}
    (h : ∃! (x : _)(hx : p x), q x hx) {y₁ y₂ : α} (hpy₁ : p y₁) (hqy₁ : q y₁ hpy₁) (hpy₂ : p y₂) (hqy₂ : q y₂ hpy₂) :
    y₁ = y₂ := by
  simp only [exists_unique_iff_exists] at h
  exact h.unique ⟨hpy₁, hqy₁⟩ ⟨hpy₂, hqy₂⟩

end Quantifiers

/-! ### Classical lemmas -/


namespace Classical

variable {α : Sort _} {p : α → Prop}

theorem cases {p : Prop → Prop} (h1 : p True) (h2 : p False) : ∀ a, p a := fun a => cases_on a h1 h2

-- use shortened names to avoid conflict when classical namespace is open.
/-- Any prop `p` is decidable classically. A shorthand for `classical.prop_decidable`. -/
noncomputable def dec (p : Prop) : Decidable p := by
  infer_instance

/-- Any predicate `p` is decidable classically. -/
noncomputable def decPred (p : α → Prop) : DecidablePred p := by
  infer_instance

/-- Any relation `p` is decidable classically. -/
noncomputable def decRel (p : α → α → Prop) : DecidableRel p := by
  infer_instance

/-- Any type `α` has decidable equality classically. -/
noncomputable def decEq (α : Sort _) : DecidableEq α := by
  infer_instance

/-- Construct a function from a default value `H0`, and a function to use if there exists a value
satisfying the predicate. -/
@[elabAsElim]
noncomputable def existsCases.{u} {C : Sort u} (H0 : C) (H : ∀ a, p a → C) : C :=
  if h : ∃ a, p a then H (Classical.choose h) (Classical.choose_spec h) else H0

theorem some_spec2 {α : Sort _} {p : α → Prop} {h : ∃ a, p a} (q : α → Prop) (hpq : ∀ a, p a → q a) : q (choose h) :=
  hpq _ <| choose_spec _

/-- A version of classical.indefinite_description which is definitionally equal to a pair -/
noncomputable def subtypeOfExists {α : Type _} {P : α → Prop} (h : ∃ x, P x) : { x // P x } :=
  ⟨Classical.choose h, Classical.choose_spec h⟩

/-- A version of `by_contradiction` that uses types instead of propositions. -/
protected noncomputable def byContradiction' {α : Sort _} (H : ¬(α → False)) : α :=
  Classical.choice <| (peirce _ False) fun h => (H fun a => h ⟨a⟩).elim

/-- `classical.by_contradiction'` is equivalent to lean's axiom `classical.choice`. -/
def choiceOfByContradiction' {α : Sort _} (contra : ¬(α → False) → α) : Nonempty α → α := fun H => contra H.elim

end Classical

/-- This function has the same type as `exists.rec_on`, and can be used to case on an equality,
but `exists.rec_on` can only eliminate into Prop, while this version eliminates into any universe
using the axiom of choice. -/
@[elabAsElim]
noncomputable def Exists.classicalRecOn.{u} {α} {p : α → Prop} (h : ∃ a, p a) {C : Sort u} (H : ∀ a, p a → C) : C :=
  H (Classical.choose h) (Classical.choose_spec h)

/-! ### Declarations about bounded quantifiers -/


section BoundedQuantifiers

variable {α : Sort _} {r p q : α → Prop} {P Q : ∀ x, p x → Prop} {b : Prop}

theorem bex_def : (∃ (x : _)(h : p x), q x) ↔ ∃ x, p x ∧ q x :=
  ⟨fun ⟨x, px, qx⟩ => ⟨x, px, qx⟩, fun ⟨x, px, qx⟩ => ⟨x, px, qx⟩⟩

theorem Bex.elim {b : Prop} : (∃ x h, P x h) → (∀ a h, P a h → b) → b
  | ⟨a, h₁, h₂⟩, h' => h' a h₁ h₂

theorem Bex.intro (a : α) (h₁ : p a) (h₂ : P a h₁) : ∃ (x : _)(h : p x), P x h :=
  ⟨a, h₁, h₂⟩

theorem ball_congr (H : ∀ x h, P x h ↔ Q x h) : (∀ x h, P x h) ↔ ∀ x h, Q x h :=
  forall_congrₓ fun x => forall_congrₓ (H x)

theorem bex_congr (H : ∀ x h, P x h ↔ Q x h) : (∃ x h, P x h) ↔ ∃ x h, Q x h :=
  exists_congr fun x => exists_congr (H x)

theorem bex_eq_left {a : α} : (∃ (x : _)(_ : x = a), p x) ↔ p a := by
  simp only [exists_prop, exists_eq_left]

theorem Ball.imp_right (H : ∀ x h, P x h → Q x h) (h₁ : ∀ x h, P x h) (x h) : Q x h :=
  H _ _ <| h₁ _ _

theorem Bex.imp_right (H : ∀ x h, P x h → Q x h) : (∃ x h, P x h) → ∃ x h, Q x h
  | ⟨x, h, h'⟩ => ⟨_, _, H _ _ h'⟩

theorem Ball.imp_left (H : ∀ x, p x → q x) (h₁ : ∀ x, q x → r x) (x) (h : p x) : r x :=
  h₁ _ <| H _ h

theorem Bex.imp_left (H : ∀ x, p x → q x) : (∃ (x : _)(_ : p x), r x) → ∃ (x : _)(_ : q x), r x
  | ⟨x, hp, hr⟩ => ⟨x, H _ hp, hr⟩

theorem ball_of_forall (h : ∀ x, p x) (x) : p x :=
  h x

theorem forall_of_ball (H : ∀ x, p x) (h : ∀ x, p x → q x) (x) : q x :=
  h x <| H x

theorem bex_of_exists (H : ∀ x, p x) : (∃ x, q x) → ∃ (x : _)(_ : p x), q x
  | ⟨x, hq⟩ => ⟨x, H x, hq⟩

theorem exists_of_bex : (∃ (x : _)(_ : p x), q x) → ∃ x, q x
  | ⟨x, _, hq⟩ => ⟨x, hq⟩

@[simp]
theorem bex_imp_distrib : (∃ x h, P x h) → b ↔ ∀ x h, P x h → b := by
  simp

theorem not_bex : (¬∃ x h, P x h) ↔ ∀ x h, ¬P x h :=
  bex_imp_distrib

theorem not_ball_of_bex_not : (∃ x h, ¬P x h) → ¬∀ x h, P x h
  | ⟨x, h, hp⟩, al => hp <| al x h

-- See Note [decidable namespace]
protected theorem Decidable.not_ball [Decidable (∃ x h, ¬P x h)] [∀ x h, Decidable (P x h)] :
    (¬∀ x h, P x h) ↔ ∃ x h, ¬P x h :=
  ⟨Not.decidable_imp_symm fun nx x h => nx.decidable_imp_symm fun h' => ⟨x, h, h'⟩, not_ball_of_bex_not⟩

theorem not_ball : (¬∀ x h, P x h) ↔ ∃ x h, ¬P x h :=
  Decidable.not_ball

theorem ball_true_iff (p : α → Prop) : (∀ x, p x → True) ↔ True :=
  iff_true_intro fun h hrx => trivialₓ

theorem ball_and_distrib : (∀ x h, P x h ∧ Q x h) ↔ (∀ x h, P x h) ∧ ∀ x h, Q x h :=
  Iff.trans (forall_congrₓ fun x => forall_and_distrib) forall_and_distrib

theorem bex_or_distrib : (∃ x h, P x h ∨ Q x h) ↔ (∃ x h, P x h) ∨ ∃ x h, Q x h :=
  Iff.trans (exists_congr fun x => exists_or_distrib) exists_or_distrib

theorem ball_or_left_distrib : (∀ x, p x ∨ q x → r x) ↔ (∀ x, p x → r x) ∧ ∀ x, q x → r x :=
  Iff.trans (forall_congrₓ fun x => or_imp_distrib) forall_and_distrib

theorem bex_or_left_distrib : (∃ (x : _)(_ : p x ∨ q x), r x) ↔ (∃ (x : _)(_ : p x), r x) ∨ ∃ (x : _)(_ : q x), r x :=
  by
  simp only [exists_prop] <;> exact Iff.trans (exists_congr fun x => or_and_distrib_right) exists_or_distrib

end BoundedQuantifiers

namespace Classical

attribute [local instance] prop_decidable

theorem not_ball {α : Sort _} {p : α → Prop} {P : ∀ x : α, p x → Prop} : (¬∀ x h, P x h) ↔ ∃ x h, ¬P x h :=
  _root_.not_ball

end Classical

section ite

variable {α β γ : Sort _} {σ : α → Sort _} (f : α → β) {P Q : Prop} [Decidable P] [Decidable Q] {a b c : α} {A : P → α}
  {B : ¬P → α}

theorem dite_eq_iff : dite P A B = c ↔ (∃ h, A h = c) ∨ ∃ h, B h = c := by
  by_cases' P <;> simp [*, exists_prop_of_false not_false]

theorem ite_eq_iff : ite P a b = c ↔ P ∧ a = c ∨ ¬P ∧ b = c :=
  dite_eq_iff.trans <| by
    rw [exists_prop, exists_prop]

@[simp]
theorem dite_eq_left_iff : dite P (fun _ => a) B = a ↔ ∀ h, B h = a := by
  by_cases' P <;> simp [*, forall_prop_of_false not_false]

@[simp]
theorem dite_eq_right_iff : (dite P A fun _ => b) = b ↔ ∀ h, A h = b := by
  by_cases' P <;> simp [*, forall_prop_of_false not_false]

@[simp]
theorem ite_eq_left_iff : ite P a b = a ↔ ¬P → b = a :=
  dite_eq_left_iff

@[simp]
theorem ite_eq_right_iff : ite P a b = b ↔ P → a = b :=
  dite_eq_right_iff

theorem dite_ne_left_iff : dite P (fun _ => a) B ≠ a ↔ ∃ h, a ≠ B h := by
  rw [Ne.def, dite_eq_left_iff, not_forall]
  exact
    exists_congr fun h => by
      rw [ne_comm]

theorem dite_ne_right_iff : (dite P A fun _ => b) ≠ b ↔ ∃ h, A h ≠ b := by
  simp only [Ne.def, dite_eq_right_iff, not_forall]

theorem ite_ne_left_iff : ite P a b ≠ a ↔ ¬P ∧ a ≠ b :=
  dite_ne_left_iff.trans <| by
    rw [exists_prop]

theorem ite_ne_right_iff : ite P a b ≠ b ↔ P ∧ a ≠ b :=
  dite_ne_right_iff.trans <| by
    rw [exists_prop]

protected theorem Ne.dite_eq_left_iff (h : ∀ h, a ≠ B h) : dite P (fun _ => a) B = a ↔ P :=
  dite_eq_left_iff.trans <| ⟨fun H => of_not_not fun h' => h h' (H h').symm, fun h H => (H h).elim⟩

protected theorem Ne.dite_eq_right_iff (h : ∀ h, A h ≠ b) : (dite P A fun _ => b) = b ↔ ¬P :=
  dite_eq_right_iff.trans <| ⟨fun H h' => h h' (H h'), fun h' H => (h' H).elim⟩

protected theorem Ne.ite_eq_left_iff (h : a ≠ b) : ite P a b = a ↔ P :=
  Ne.dite_eq_left_iff fun _ => h

protected theorem Ne.ite_eq_right_iff (h : a ≠ b) : ite P a b = b ↔ ¬P :=
  Ne.dite_eq_right_iff fun _ => h

protected theorem Ne.dite_ne_left_iff (h : ∀ h, a ≠ B h) : dite P (fun _ => a) B ≠ a ↔ ¬P :=
  dite_ne_left_iff.trans <| exists_iff_of_forall h

protected theorem Ne.dite_ne_right_iff (h : ∀ h, A h ≠ b) : (dite P A fun _ => b) ≠ b ↔ P :=
  dite_ne_right_iff.trans <| exists_iff_of_forall h

protected theorem Ne.ite_ne_left_iff (h : a ≠ b) : ite P a b ≠ a ↔ ¬P :=
  Ne.dite_ne_left_iff fun _ => h

protected theorem Ne.ite_ne_right_iff (h : a ≠ b) : ite P a b ≠ b ↔ P :=
  Ne.dite_ne_right_iff fun _ => h

variable (P Q) (a b)

/-- A `dite` whose results do not actually depend on the condition may be reduced to an `ite`. -/
@[simp]
theorem dite_eq_ite : (dite P (fun h => a) fun h => b) = ite P a b :=
  rfl

theorem dite_eq_or_eq : (∃ h, dite P A B = A h) ∨ ∃ h, dite P A B = B h :=
  Decidable.byCases (fun h => Or.inl ⟨h, dif_pos h⟩) fun h => Or.inr ⟨h, dif_neg h⟩

theorem ite_eq_or_eq : ite P a b = a ∨ ite P a b = b :=
  Decidable.byCases (fun h => Or.inl (if_pos h)) fun h => Or.inr (if_neg h)

/-- A function applied to a `dite` is a `dite` of that function applied to each of the branches. -/
theorem apply_diteₓ (x : P → α) (y : ¬P → α) : f (dite P x y) = dite P (fun h => f (x h)) fun h => f (y h) := by
  by_cases' h : P <;> simp [h]

/-- A function applied to a `ite` is a `ite` of that function applied to each of the branches. -/
theorem apply_iteₓ : f (ite P a b) = ite P (f a) (f b) :=
  apply_diteₓ f P (fun _ => a) fun _ => b

/-- A two-argument function applied to two `dite`s is a `dite` of that two-argument function
applied to each of the branches. -/
theorem apply_dite2 (f : α → β → γ) (P : Prop) [Decidable P] (a : P → α) (b : ¬P → α) (c : P → β) (d : ¬P → β) :
    f (dite P a b) (dite P c d) = dite P (fun h => f (a h) (c h)) fun h => f (b h) (d h) := by
  by_cases' h : P <;> simp [h]

/-- A two-argument function applied to two `ite`s is a `ite` of that two-argument function
applied to each of the branches. -/
theorem apply_ite2 (f : α → β → γ) (P : Prop) [Decidable P] (a b : α) (c d : β) :
    f (ite P a b) (ite P c d) = ite P (f a c) (f b d) :=
  apply_dite2 f P (fun _ => a) (fun _ => b) (fun _ => c) fun _ => d

/-- A 'dite' producing a `Pi` type `Π a, σ a`, applied to a value `a : α` is a `dite` that applies
either branch to `a`. -/
theorem dite_apply (f : P → ∀ a, σ a) (g : ¬P → ∀ a, σ a) (a : α) :
    (dite P f g) a = dite P (fun h => f h a) fun h => g h a := by
  by_cases' h : P <;> simp [h]

/-- A 'ite' producing a `Pi` type `Π a, σ a`, applied to a value `a : α` is a `ite` that applies
either branch to `a`. -/
theorem ite_apply (f g : ∀ a, σ a) (a : α) : (ite P f g) a = ite P (f a) (g a) :=
  dite_apply P (fun _ => f) (fun _ => g) a

/-- Negation of the condition `P : Prop` in a `dite` is the same as swapping the branches. -/
@[simp]
theorem dite_not (x : ¬P → α) (y : ¬¬P → α) : dite (¬P) x y = dite P (fun h => y (not_not_intro h)) x := by
  by_cases' h : P <;> simp [h]

/-- Negation of the condition `P : Prop` in a `ite` is the same as swapping the branches. -/
@[simp]
theorem ite_not : ite (¬P) a b = ite P b a :=
  dite_not P (fun _ => a) fun _ => b

theorem ite_and : ite (P ∧ Q) a b = ite P (ite Q a b) b := by
  by_cases' hp : P <;> by_cases' hq : Q <;> simp [hp, hq]

end ite

