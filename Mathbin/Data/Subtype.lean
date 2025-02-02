/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl
-/
import Mathbin.Logic.Function.Basic
import Mathbin.Tactic.Ext
import Mathbin.Tactic.Lint.Default
import Mathbin.Tactic.Simps

/-!
# Subtypes

This file provides basic API for subtypes, which are defined in core.

A subtype is a type made from restricting another type, say `α`, to its elements that satisfy some
predicate, say `p : α → Prop`. Specifically, it is the type of pairs `⟨val, property⟩` where
`val : α` and `property : p val`. It is denoted `subtype p` and notation `{val : α // p val}` is
available.

A subtype has a natural coercion to the parent type, by coercing `⟨val, property⟩` to `val`. As
such, subtypes can be thought of as bundled sets, the difference being that elements of a set are
still of type `α` while elements of a subtype aren't.
-/


open Function

namespace Subtype

variable {α β γ : Sort _} {p q : α → Prop}

/-- See Note [custom simps projection] -/
def Simps.coe (x : Subtype p) : α :=
  x

initialize_simps_projections Subtype (val → coe)

/-- A version of `x.property` or `x.2` where `p` is syntactically applied to the coercion of `x`
  instead of `x.1`. A similar result is `subtype.mem` in `data.set.basic`. -/
theorem prop (x : Subtype p) : p x :=
  x.2

@[simp]
theorem val_eq_coe {x : Subtype p} : x.1 = ↑x :=
  rfl

@[simp]
protected theorem forall {q : { a // p a } → Prop} : (∀ x, q x) ↔ ∀ a b, q ⟨a, b⟩ :=
  ⟨fun h a b => h ⟨a, b⟩, fun h ⟨a, b⟩ => h a b⟩

/-- An alternative version of `subtype.forall`. This one is useful if Lean cannot figure out `q`
  when using `subtype.forall` from right to left. -/
protected theorem forall' {q : ∀ x, p x → Prop} : (∀ x h, q x h) ↔ ∀ x : { a // p a }, q x x.2 :=
  (@Subtype.forall _ _ fun x => q x.1 x.2).symm

@[simp]
protected theorem exists {q : { a // p a } → Prop} : (∃ x, q x) ↔ ∃ a b, q ⟨a, b⟩ :=
  ⟨fun ⟨⟨a, b⟩, h⟩ => ⟨a, b, h⟩, fun ⟨a, b, h⟩ => ⟨⟨a, b⟩, h⟩⟩

/-- An alternative version of `subtype.exists`. This one is useful if Lean cannot figure out `q`
  when using `subtype.exists` from right to left. -/
protected theorem exists' {q : ∀ x, p x → Prop} : (∃ x h, q x h) ↔ ∃ x : { a // p a }, q x x.2 :=
  (@Subtype.exists _ _ fun x => q x.1 x.2).symm

@[ext]
protected theorem ext : ∀ {a1 a2 : { x // p x }}, (a1 : α) = (a2 : α) → a1 = a2
  | ⟨x, h1⟩, ⟨x, h2⟩, rfl => rfl

theorem ext_iff {a1 a2 : { x // p x }} : a1 = a2 ↔ (a1 : α) = (a2 : α) :=
  ⟨congr_argₓ _, Subtype.ext⟩

theorem heq_iff_coe_eq (h : ∀ x, p x ↔ q x) {a1 : { x // p x }} {a2 : { x // q x }} : HEq a1 a2 ↔ (a1 : α) = (a2 : α) :=
  Eq.ndrec (fun a2' => heq_iff_eq.trans ext_iff) (funext fun x => propext (h x)) a2

theorem heq_iff_coe_heq {α β : Sort _} {p : α → Prop} {q : β → Prop} {a : { x // p x }} {b : { y // q y }} (h : α = β)
    (h' : HEq p q) : HEq a b ↔ HEq (a : α) (b : β) := by
  subst h
  subst h'
  rw [heq_iff_eq, heq_iff_eq, ext_iff]

theorem ext_val {a1 a2 : { x // p x }} : a1.1 = a2.1 → a1 = a2 :=
  Subtype.ext

theorem ext_iff_val {a1 a2 : { x // p x }} : a1 = a2 ↔ a1.1 = a2.1 :=
  ext_iff

@[simp]
theorem coe_eta (a : { a // p a }) (h : p a) : mk (↑a) h = a :=
  Subtype.ext rfl

@[simp]
theorem coe_mk (a h) : (@mk α p a h : α) = a :=
  rfl

-- built-in reduction doesn't always work
@[simp, nolint simp_nf]
theorem mk_eq_mk {a h a' h'} : @mk α p a h = @mk α p a' h' ↔ a = a' :=
  ext_iff

theorem coe_eq_of_eq_mk {a : { a // p a }} {b : α} (h : ↑a = b) : a = ⟨b, h ▸ a.2⟩ :=
  Subtype.ext h

theorem coe_eq_iff {a : { a // p a }} {b : α} : ↑a = b ↔ ∃ h, a = ⟨b, h⟩ :=
  ⟨fun h => h ▸ ⟨a.2, (coe_eta _ _).symm⟩, fun ⟨hb, ha⟩ => ha.symm ▸ rfl⟩

theorem coe_injective : Injective (coe : Subtype p → α) := fun a b => Subtype.ext

theorem val_injective : Injective (@val _ p) :=
  coe_injective

theorem coe_inj {a b : Subtype p} : (a : α) = b ↔ a = b :=
  coe_injective.eq_iff

theorem val_inj {a b : Subtype p} : a.val = b.val ↔ a = b :=
  coe_inj

@[simp]
theorem _root_.exists_eq_subtype_mk_iff {a : Subtype p} {b : α} : (∃ h : p b, a = Subtype.mk b h) ↔ ↑a = b :=
  coe_eq_iff.symm

@[simp]
theorem _root_.exists_subtype_mk_eq_iff {a : Subtype p} {b : α} : (∃ h : p b, Subtype.mk b h = a) ↔ b = a := by
  simp only [@eq_comm _ b, exists_eq_subtype_mk_iff, @eq_comm _ _ a]

/-- Restrict a (dependent) function to a subtype -/
def restrictₓ {α} {β : α → Type _} (p : α → Prop) (f : ∀ x, β x) (x : Subtype p) : β x.1 :=
  f x

theorem restrict_applyₓ {α} {β : α → Type _} (f : ∀ x, β x) (p : α → Prop) (x : Subtype p) : restrictₓ p f x = f x.1 :=
  by
  rfl

theorem restrict_defₓ {α β} (f : α → β) (p : α → Prop) : restrictₓ p f = f ∘ coe := by
  rfl

theorem restrict_injectiveₓ {α β} {f : α → β} (p : α → Prop) (h : Injective f) : Injective (restrictₓ p f) :=
  h.comp coe_injective

theorem surjective_restrict {α} {β : α → Type _} [ne : ∀ a, Nonempty (β a)] (p : α → Prop) :
    Surjective fun f : ∀ x, β x => restrictₓ p f := by
  letI := Classical.decPred p
  refine' fun f => ⟨fun x => if h : p x then f ⟨x, h⟩ else Nonempty.some (Ne x), funext <| _⟩
  rintro ⟨x, hx⟩
  exact dif_pos hx

/-- Defining a map into a subtype, this can be seen as an "coinduction principle" of `subtype`-/
@[simps]
def coind {α β} (f : α → β) {p : β → Prop} (h : ∀ a, p (f a)) : α → Subtype p := fun a => ⟨f a, h a⟩

theorem coind_injectiveₓ {α β} {f : α → β} {p : β → Prop} (h : ∀ a, p (f a)) (hf : Injective f) :
    Injective (coind f h) := fun x y hxy =>
  hf <| by
    apply congr_argₓ Subtype.val hxy

theorem coind_surjectiveₓ {α β} {f : α → β} {p : β → Prop} (h : ∀ a, p (f a)) (hf : Surjective f) :
    Surjective (coind f h) := fun x =>
  let ⟨a, ha⟩ := hf x
  ⟨a, coe_injective ha⟩

theorem coind_bijectiveₓ {α β} {f : α → β} {p : β → Prop} (h : ∀ a, p (f a)) (hf : Bijective f) :
    Bijective (coind f h) :=
  ⟨coind_injectiveₓ h hf.1, coind_surjectiveₓ h hf.2⟩

/-- Restriction of a function to a function on subtypes. -/
@[simps]
def map {p : α → Prop} {q : β → Prop} (f : α → β) (h : ∀ a, p a → q (f a)) : Subtype p → Subtype q := fun x =>
  ⟨f x, h x x.prop⟩

theorem map_compₓ {p : α → Prop} {q : β → Prop} {r : γ → Prop} {x : Subtype p} (f : α → β) (h : ∀ a, p a → q (f a))
    (g : β → γ) (l : ∀ a, q a → r (g a)) : map g l (map f h x) = map (g ∘ f) (fun a ha => l (f a) <| h a ha) x :=
  rfl

theorem map_id {p : α → Prop} {h : ∀ a, p a → p (id a)} : map (@id α) h = id :=
  funext fun ⟨v, h⟩ => rfl

theorem map_injectiveₓ {p : α → Prop} {q : β → Prop} {f : α → β} (h : ∀ a, p a → q (f a)) (hf : Injective f) :
    Injective (map f h) :=
  coind_injectiveₓ _ <| hf.comp coe_injective

theorem map_involutive {p : α → Prop} {f : α → α} (h : ∀ a, p a → p (f a)) (hf : Involutive f) : Involutive (map f h) :=
  fun x => Subtype.ext (hf x)

instance [HasEquivₓ α] (p : α → Prop) : HasEquivₓ (Subtype p) :=
  ⟨fun s t => (s : α) ≈ (t : α)⟩

theorem equiv_iffₓ [HasEquivₓ α] {p : α → Prop} {s t : Subtype p} : s ≈ t ↔ (s : α) ≈ (t : α) :=
  Iff.rfl

variable [Setoidₓ α]

protected theorem reflₓ (s : Subtype p) : s ≈ s :=
  Setoidₓ.refl ↑s

protected theorem symmₓ {s t : Subtype p} (h : s ≈ t) : t ≈ s :=
  Setoidₓ.symm h

protected theorem transₓ {s t u : Subtype p} (h₁ : s ≈ t) (h₂ : t ≈ u) : s ≈ u :=
  Setoidₓ.trans h₁ h₂

theorem equivalenceₓ (p : α → Prop) : Equivalenceₓ (@HasEquivₓ.Equiv (Subtype p) _) :=
  mk_equivalence _ Subtype.reflₓ (@Subtype.symmₓ _ p _) (@Subtype.transₓ _ p _)

instance (p : α → Prop) : Setoidₓ (Subtype p) :=
  Setoidₓ.mk (· ≈ ·) (equivalenceₓ p)

end Subtype

namespace Subtype

/-! Some facts about sets, which require that `α` is a type. -/


variable {α β γ : Type _} {p : α → Prop}

@[simp]
theorem coe_prop {S : Set α} (a : { a // a ∈ S }) : ↑a ∈ S :=
  a.prop

theorem val_prop {S : Set α} (a : { a // a ∈ S }) : a.val ∈ S :=
  a.property

end Subtype

