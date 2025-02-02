/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl
-/
import Mathbin.Tactic.Basic
import Mathbin.Logic.Relator

/-!
# Relation closures

This file defines the reflexive, transitive, and reflexive transitive closures of relations.
It also proves some basic results on definitions in core, such as `eqv_gen`.

Note that this is about unbundled relations, that is terms of types of the form `α → β → Prop`. For
the bundled version, see `rel`.

## Definitions

* `relation.refl_gen`: Reflexive closure. `refl_gen r` relates everything `r` related, plus for all
  `a` it relates `a` with itself. So `refl_gen r a b ↔ r a b ∨ a = b`.
* `relation.trans_gen`: Transitive closure. `trans_gen r` relates everything `r` related
  transitively. So `trans_gen r a b ↔ ∃ x₀ ... xₙ, r a x₀ ∧ r x₀ x₁ ∧ ... ∧ r xₙ b`.
* `relation.refl_trans_gen`: Reflexive transitive closure. `refl_trans_gen r` relates everything
  `r` related transitively, plus for all `a` it relates `a` with itself. So
  `refl_trans_gen r a b ↔ (∃ x₀ ... xₙ, r a x₀ ∧ r x₀ x₁ ∧ ... ∧ r xₙ b) ∨ a = b`. It is the same as
  the reflexive closure of the transitive closure, or the transitive closure of the reflexive
  closure. In terms of rewriting systems, this means that `a` can be rewritten to `b` in a number of
  rewrites.
* `relation.comp`:  Relation composition. We provide notation `∘r`. For `r : α → β → Prop` and
  `s : β → γ → Prop`, `r ∘r s`relates `a : α` and `c : γ` iff there exists `b : β` that's related to
  both.
* `relation.map`: Image of a relation under a pair of maps. For `r : α → β → Prop`, `f : α → γ`,
  `g : β → δ`, `map r f g` is the relation `γ → δ → Prop` relating `f a` and `g b` for all `a`, `b`
  related by `r`.
* `relation.join`: Join of a relation. For `r : α → α → Prop`, `join r a b ↔ ∃ c, r a c ∧ r b c`. In
  terms of rewriting systems, this means that `a` and `b` can be rewritten to the same term.
-/


open Function

variable {α β γ δ : Type _}

section NeImp

variable {r : α → α → Prop}

theorem IsRefl.reflexive [IsRefl α r] : Reflexive r := fun x => IsRefl.refl x

/-- To show a reflexive relation `r : α → α → Prop` holds over `x y : α`,
it suffices to show it holds when `x ≠ y`. -/
theorem Reflexive.rel_of_ne_imp (h : Reflexive r) {x y : α} (hr : x ≠ y → r x y) : r x y := by
  by_cases' hxy : x = y
  · exact hxy ▸ h x
    
  · exact hr hxy
    

/-- If a reflexive relation `r : α → α → Prop` holds over `x y : α`,
then it holds whether or not `x ≠ y`. -/
theorem Reflexive.ne_imp_iff (h : Reflexive r) {x y : α} : x ≠ y → r x y ↔ r x y :=
  ⟨h.rel_of_ne_imp, fun hr _ => hr⟩

/-- If a reflexive relation `r : α → α → Prop` holds over `x y : α`,
then it holds whether or not `x ≠ y`. Unlike `reflexive.ne_imp_iff`, this uses `[is_refl α r]`. -/
theorem reflexive_ne_imp_iff [IsRefl α r] {x y : α} : x ≠ y → r x y ↔ r x y :=
  IsRefl.reflexive.ne_imp_iff

protected theorem Symmetric.iff (H : Symmetric r) (x y : α) : r x y ↔ r y x :=
  ⟨fun h => H h, fun h => H h⟩

theorem Symmetric.flip_eq (h : Symmetric r) : flip r = r :=
  funext₂ fun _ _ => propext <| h.Iff _ _

theorem Symmetric.swap_eq : Symmetric r → swap r = r :=
  Symmetric.flip_eq

theorem flip_eq_iff : flip r = r ↔ Symmetric r :=
  ⟨fun h x y => (congr_fun₂ h _ _).mp, Symmetric.flip_eq⟩

theorem swap_eq_iff : swap r = r ↔ Symmetric r :=
  flip_eq_iff

end NeImp

section Comap

variable {r : β → β → Prop}

theorem Reflexive.comap (h : Reflexive r) (f : α → β) : Reflexive (r on f) := fun a => h (f a)

theorem Symmetric.comap (h : Symmetric r) (f : α → β) : Symmetric (r on f) := fun a b hab => h hab

theorem Transitive.comap (h : Transitive r) (f : α → β) : Transitive (r on f) := fun a b c hab hbc => h hab hbc

theorem Equivalenceₓ.comap (h : Equivalenceₓ r) (f : α → β) : Equivalenceₓ (r on f) :=
  ⟨h.1.comap f, h.2.1.comap f, h.2.2.comap f⟩

end Comap

namespace Relation

section Comp

variable {r : α → β → Prop} {p : β → γ → Prop} {q : γ → δ → Prop}

/-- The composition of two relations, yielding a new relation.  The result
relates a term of `α` and a term of `γ` if there is an intermediate
term of `β` related to both.
-/
def Comp (r : α → β → Prop) (p : β → γ → Prop) (a : α) (c : γ) : Prop :=
  ∃ b, r a b ∧ p b c

-- mathport name: «expr ∘r »
local infixr:80 " ∘r " => Relation.Comp

theorem comp_eq : r ∘r (· = ·) = r :=
  funext fun a => funext fun b => propext <| Iff.intro (fun ⟨c, h, Eq⟩ => Eq ▸ h) fun h => ⟨b, h, rfl⟩

theorem eq_comp : (· = ·) ∘r r = r :=
  funext fun a => funext fun b => propext <| Iff.intro (fun ⟨c, Eq, h⟩ => Eq.symm ▸ h) fun h => ⟨a, rfl, h⟩

theorem iff_comp {r : Prop → α → Prop} : (· ↔ ·) ∘r r = r := by
  have : (· ↔ ·) = (· = ·) := by
    funext a b <;> exact iff_eq_eq
  rw [this, eq_comp]

theorem comp_iff {r : α → Prop → Prop} : r ∘r (· ↔ ·) = r := by
  have : (· ↔ ·) = (· = ·) := by
    funext a b <;> exact iff_eq_eq
  rw [this, comp_eq]

theorem comp_assoc : (r ∘r p) ∘r q = r ∘r p ∘r q := by
  funext a d
  apply propext
  constructor
  exact fun ⟨c, ⟨b, hab, hbc⟩, hcd⟩ => ⟨b, hab, c, hbc, hcd⟩
  exact fun ⟨b, hab, c, hbc, hcd⟩ => ⟨c, ⟨b, hab, hbc⟩, hcd⟩

theorem flip_comp : flip (r ∘r p) = flip p ∘r flip r := by
  funext c a
  apply propext
  constructor
  exact fun ⟨b, hab, hbc⟩ => ⟨b, hbc, hab⟩
  exact fun ⟨b, hbc, hab⟩ => ⟨b, hab, hbc⟩

end Comp

/-- The map of a relation `r` through a pair of functions pushes the
relation to the codomains of the functions.  The resulting relation is
defined by having pairs of terms related if they have preimages
related by `r`.
-/
protected def Map (r : α → β → Prop) (f : α → γ) (g : β → δ) : γ → δ → Prop := fun c d =>
  ∃ a b, r a b ∧ f a = c ∧ g b = d

variable {r : α → α → Prop} {a b c d : α}

/-- `refl_trans_gen r`: reflexive transitive closure of `r` -/
@[mk_iff Relation.ReflTransGen.cases_tail_iff]
inductive ReflTransGen (r : α → α → Prop) (a : α) : α → Prop
  | refl : refl_trans_gen a
  | tail {b c} : refl_trans_gen b → r b c → refl_trans_gen c

attribute [refl] refl_trans_gen.refl

/-- `refl_gen r`: reflexive closure of `r` -/
@[mk_iff]
inductive ReflGen (r : α → α → Prop) (a : α) : α → Prop
  | refl : refl_gen a
  | single {b} : r a b → refl_gen b

/-- `trans_gen r`: transitive closure of `r` -/
@[mk_iff]
inductive TransGen (r : α → α → Prop) (a : α) : α → Prop
  | single {b} : r a b → trans_gen b
  | tail {b c} : trans_gen b → r b c → trans_gen c

attribute [refl] refl_gen.refl

namespace ReflGen

theorem to_refl_trans_gen : ∀ {a b}, ReflGen r a b → ReflTransGen r a b
  | a, _, refl => by
    rfl
  | a, b, single h => ReflTransGen.tail ReflTransGen.refl h

theorem mono {p : α → α → Prop} (hp : ∀ a b, r a b → p a b) : ∀ {a b}, ReflGen r a b → ReflGen p a b
  | a, _, refl_gen.refl => by
    rfl
  | a, b, single h => single (hp a b h)

instance : IsRefl α (ReflGen r) :=
  ⟨@refl α r⟩

end ReflGen

namespace ReflTransGen

@[trans]
theorem trans (hab : ReflTransGen r a b) (hbc : ReflTransGen r b c) : ReflTransGen r a c := by
  induction hbc
  case refl_trans_gen.refl =>
    assumption
  case refl_trans_gen.tail c d hbc hcd hac =>
    exact hac.tail hcd

theorem single (hab : r a b) : ReflTransGen r a b :=
  refl.tail hab

theorem head (hab : r a b) (hbc : ReflTransGen r b c) : ReflTransGen r a c := by
  induction hbc
  case refl_trans_gen.refl =>
    exact refl.tail hab
  case refl_trans_gen.tail c d hbc hcd hac =>
    exact hac.tail hcd

theorem symmetric (h : Symmetric r) : Symmetric (ReflTransGen r) := by
  intro x y h
  induction' h with z w a b c
  · rfl
    
  · apply Relation.ReflTransGen.head (h b) c
    

theorem cases_tail : ReflTransGen r a b → b = a ∨ ∃ c, ReflTransGen r a c ∧ r c b :=
  (cases_tail_iff r a b).1

@[elabAsElim]
theorem head_induction_on {P : ∀ a : α, ReflTransGen r a b → Prop} {a : α} (h : ReflTransGen r a b) (refl : P b refl)
    (head : ∀ {a c} (h' : r a c) (h : ReflTransGen r c b), P c h → P a (h.head h')) : P a h := by
  induction h generalizing P
  case refl_trans_gen.refl =>
    exact refl
  case refl_trans_gen.tail b c hab hbc ih =>
    apply ih
    show P b _
    exact head hbc _ refl
    show ∀ a a', r a a' → refl_trans_gen r a' b → P a' _ → P a _
    exact fun a a' hab hbc => head hab _

@[elabAsElim]
theorem trans_induction_on {P : ∀ {a b : α}, ReflTransGen r a b → Prop} {a b : α} (h : ReflTransGen r a b)
    (ih₁ : ∀ a, @P a a refl) (ih₂ : ∀ {a b} (h : r a b), P (single h))
    (ih₃ : ∀ {a b c} (h₁ : ReflTransGen r a b) (h₂ : ReflTransGen r b c), P h₁ → P h₂ → P (h₁.trans h₂)) : P h := by
  induction h
  case refl_trans_gen.refl =>
    exact ih₁ a
  case refl_trans_gen.tail b c hab hbc ih =>
    exact ih₃ hab (single hbc) ih (ih₂ hbc)

theorem cases_head (h : ReflTransGen r a b) : a = b ∨ ∃ c, r a c ∧ ReflTransGen r c b := by
  induction h using Relation.ReflTransGen.head_induction_on
  · left
    rfl
    
  · right
    exists _
    constructor <;> assumption
    

theorem cases_head_iff : ReflTransGen r a b ↔ a = b ∨ ∃ c, r a c ∧ ReflTransGen r c b := by
  use cases_head
  rintro (rfl | ⟨c, hac, hcb⟩)
  · rfl
    
  · exact head hac hcb
    

theorem total_of_right_unique (U : Relator.RightUnique r) (ab : ReflTransGen r a b) (ac : ReflTransGen r a c) :
    ReflTransGen r b c ∨ ReflTransGen r c b := by
  induction' ab with b d ab bd IH
  · exact Or.inl ac
    
  · rcases IH with (IH | IH)
    · rcases cases_head IH with (rfl | ⟨e, be, ec⟩)
      · exact Or.inr (single bd)
        
      · cases U bd be
        exact Or.inl ec
        
      
    · exact Or.inr (IH.tail bd)
      
    

end ReflTransGen

namespace TransGen

theorem to_refl {a b} (h : TransGen r a b) : ReflTransGen r a b := by
  induction' h with b h b c _ bc ab
  exact refl_trans_gen.single h
  exact refl_trans_gen.tail ab bc

@[trans]
theorem trans_left (hab : TransGen r a b) (hbc : ReflTransGen r b c) : TransGen r a c := by
  induction hbc
  case refl_trans_gen.refl =>
    assumption
  case refl_trans_gen.tail c d hbc hcd hac =>
    exact hac.tail hcd

@[trans]
theorem trans (hab : TransGen r a b) (hbc : TransGen r b c) : TransGen r a c :=
  trans_left hab hbc.to_refl

theorem head' (hab : r a b) (hbc : ReflTransGen r b c) : TransGen r a c :=
  trans_left (single hab) hbc

theorem tail' (hab : ReflTransGen r a b) (hbc : r b c) : TransGen r a c := by
  induction hab generalizing c
  case refl_trans_gen.refl c hac =>
    exact single hac
  case refl_trans_gen.tail d b hab hdb IH =>
    exact tail (IH hdb) hbc

theorem head (hab : r a b) (hbc : TransGen r b c) : TransGen r a c :=
  head' hab hbc.to_refl

@[elabAsElim]
theorem head_induction_on {P : ∀ a : α, TransGen r a b → Prop} {a : α} (h : TransGen r a b)
    (base : ∀ {a} (h : r a b), P a (single h))
    (ih : ∀ {a c} (h' : r a c) (h : TransGen r c b), P c h → P a (h.head h')) : P a h := by
  induction h generalizing P
  case single a h =>
    exact base h
  case tail b c hab hbc h_ih =>
    apply h_ih
    show ∀ a, r a b → P a _
    exact fun a h => ih h (single hbc) (base hbc)
    show ∀ a a', r a a' → trans_gen r a' b → P a' _ → P a _
    exact fun a a' hab hbc => ih hab _

@[elabAsElim]
theorem trans_induction_on {P : ∀ {a b : α}, TransGen r a b → Prop} {a b : α} (h : TransGen r a b)
    (base : ∀ {a b} (h : r a b), P (single h))
    (ih : ∀ {a b c} (h₁ : TransGen r a b) (h₂ : TransGen r b c), P h₁ → P h₂ → P (h₁.trans h₂)) : P h := by
  induction h
  case single a h =>
    exact base h
  case tail b c hab hbc h_ih =>
    exact ih hab (single hbc) h_ih (base hbc)

@[trans]
theorem trans_right (hab : ReflTransGen r a b) (hbc : TransGen r b c) : TransGen r a c := by
  induction hbc
  case trans_gen.single c hbc =>
    exact tail' hab hbc
  case trans_gen.tail c d hbc hcd hac =>
    exact hac.tail hcd

theorem tail'_iff : TransGen r a c ↔ ∃ b, ReflTransGen r a b ∧ r b c := by
  refine' ⟨fun h => _, fun ⟨b, hab, hbc⟩ => tail' hab hbc⟩
  cases' h with _ hac b _ hab hbc
  · exact
      ⟨_, by
        rfl, hac⟩
    
  · exact ⟨_, hab.to_refl, hbc⟩
    

theorem head'_iff : TransGen r a c ↔ ∃ b, r a b ∧ ReflTransGen r b c := by
  refine' ⟨fun h => _, fun ⟨b, hab, hbc⟩ => head' hab hbc⟩
  induction h
  case trans_gen.single c hac =>
    exact
      ⟨_, hac, by
        rfl⟩
  case trans_gen.tail b c hab hbc IH =>
    rcases IH with ⟨d, had, hdb⟩
    exact ⟨_, had, hdb.tail hbc⟩

end TransGen

theorem _root_.acc.trans_gen {α} {r : α → α → Prop} {a : α} (h : Acc r a) : Acc (TransGen r) a := by
  induction' h with x _ H
  refine' Acc.intro x fun y hy => _
  cases' hy with _ hyx z _ hyz hzx
  exacts[H y hyx, (H z hzx).inv hyz]

theorem _root_.well_founded.trans_gen {α} {r : α → α → Prop} (h : WellFounded r) : WellFounded (TransGen r) :=
  ⟨fun a => (h.apply a).TransGen⟩

section TransGen

theorem trans_gen_eq_self (trans : Transitive r) : TransGen r = r :=
  funext fun a =>
    funext fun b =>
      propext <|
        ⟨fun h => by
          induction h
          case trans_gen.single c hc =>
            exact hc
          case trans_gen.tail c d hac hcd hac =>
            exact trans hac hcd,
          TransGen.single⟩

theorem transitive_trans_gen : Transitive (TransGen r) := fun a b c => TransGen.trans

instance : IsTrans α (TransGen r) :=
  ⟨@TransGen.trans α r⟩

theorem trans_gen_idem : TransGen (TransGen r) = TransGen r :=
  trans_gen_eq_self transitive_trans_gen

theorem TransGen.lift {p : β → β → Prop} {a b : α} (f : α → β) (h : ∀ a b, r a b → p (f a) (f b))
    (hab : TransGen r a b) : TransGen p (f a) (f b) := by
  induction hab
  case trans_gen.single c hac =>
    exact trans_gen.single (h a c hac)
  case trans_gen.tail c d hac hcd hac =>
    exact trans_gen.tail hac (h c d hcd)

theorem TransGen.lift' {p : β → β → Prop} {a b : α} (f : α → β) (h : ∀ a b, r a b → TransGen p (f a) (f b))
    (hab : TransGen r a b) : TransGen p (f a) (f b) := by
  simpa [trans_gen_idem] using hab.lift f h

theorem TransGen.closed {p : α → α → Prop} : (∀ a b, r a b → TransGen p a b) → TransGen r a b → TransGen p a b :=
  TransGen.lift' id

theorem TransGen.mono {p : α → α → Prop} : (∀ a b, r a b → p a b) → TransGen r a b → TransGen p a b :=
  TransGen.lift id

theorem TransGen.swap (h : TransGen r b a) : TransGen (swap r) a b := by
  induction' h with b h b c hab hbc ih
  · exact trans_gen.single h
    
  exact ih.head hbc

theorem trans_gen_swap : TransGen (swap r) a b ↔ TransGen r b a :=
  ⟨TransGen.swap, TransGen.swap⟩

end TransGen

section ReflTransGen

open ReflTransGen

theorem refl_trans_gen_iff_eq (h : ∀ b, ¬r a b) : ReflTransGen r a b ↔ b = a := by
  rw [cases_head_iff] <;> simp [h, eq_comm]

theorem refl_trans_gen_iff_eq_or_trans_gen : ReflTransGen r a b ↔ b = a ∨ TransGen r a b := by
  refine' ⟨fun h => _, fun h => _⟩
  · cases' h with c _ hac hcb
    · exact Or.inl rfl
      
    · exact Or.inr (trans_gen.tail' hac hcb)
      
    
  · rcases h with (rfl | h)
    · rfl
      
    · exact h.to_refl
      
    

theorem ReflTransGen.lift {p : β → β → Prop} {a b : α} (f : α → β) (h : ∀ a b, r a b → p (f a) (f b))
    (hab : ReflTransGen r a b) : ReflTransGen p (f a) (f b) :=
  ReflTransGen.trans_induction_on hab (fun a => refl) (fun a b => refl_trans_gen.single ∘ h _ _) fun a b c _ _ => trans

theorem ReflTransGen.mono {p : α → α → Prop} : (∀ a b, r a b → p a b) → ReflTransGen r a b → ReflTransGen p a b :=
  ReflTransGen.lift id

theorem refl_trans_gen_eq_self (refl : Reflexive r) (trans : Transitive r) : ReflTransGen r = r :=
  funext fun a =>
    funext fun b =>
      propext <|
        ⟨fun h => by
          induction' h with b c h₁ h₂ IH
          · apply refl
            
          exact trans IH h₂, single⟩

theorem reflexive_refl_trans_gen : Reflexive (ReflTransGen r) := fun a => refl

theorem transitive_refl_trans_gen : Transitive (ReflTransGen r) := fun a b c => trans

instance : IsRefl α (ReflTransGen r) :=
  ⟨@ReflTransGen.refl α r⟩

instance : IsTrans α (ReflTransGen r) :=
  ⟨@ReflTransGen.trans α r⟩

theorem refl_trans_gen_idem : ReflTransGen (ReflTransGen r) = ReflTransGen r :=
  refl_trans_gen_eq_self reflexive_refl_trans_gen transitive_refl_trans_gen

theorem ReflTransGen.lift' {p : β → β → Prop} {a b : α} (f : α → β) (h : ∀ a b, r a b → ReflTransGen p (f a) (f b))
    (hab : ReflTransGen r a b) : ReflTransGen p (f a) (f b) := by
  simpa [refl_trans_gen_idem] using hab.lift f h

theorem refl_trans_gen_closed {p : α → α → Prop} :
    (∀ a b, r a b → ReflTransGen p a b) → ReflTransGen r a b → ReflTransGen p a b :=
  ReflTransGen.lift' id

theorem ReflTransGen.swap (h : ReflTransGen r b a) : ReflTransGen (swap r) a b := by
  induction' h with b c hab hbc ih
  · rfl
    
  exact ih.head hbc

theorem refl_trans_gen_swap : ReflTransGen (swap r) a b ↔ ReflTransGen r b a :=
  ⟨ReflTransGen.swap, ReflTransGen.swap⟩

end ReflTransGen

/-- The join of a relation on a single type is a new relation for which
pairs of terms are related if there is a third term they are both
related to.  For example, if `r` is a relation representing rewrites
in a term rewriting system, then *confluence* is the property that if
`a` rewrites to both `b` and `c`, then `join r` relates `b` and `c`
(see `relation.church_rosser`).
-/
def Join (r : α → α → Prop) : α → α → Prop := fun a b => ∃ c, r a c ∧ r b c

section Join

open ReflTransGen ReflGen

/-- A sufficient condition for the Church-Rosser property. -/
theorem church_rosser (h : ∀ a b c, r a b → r a c → ∃ d, ReflGen r b d ∧ ReflTransGen r c d) (hab : ReflTransGen r a b)
    (hac : ReflTransGen r a c) : Join (ReflTransGen r) b c := by
  induction hab
  case refl_trans_gen.refl =>
    exact ⟨c, hac, refl⟩
  case refl_trans_gen.tail d e had hde ih =>
    clear hac had a
    rcases ih with ⟨b, hdb, hcb⟩
    have : ∃ a, refl_trans_gen r e a ∧ refl_gen r b a := by
      clear hcb
      induction hdb
      case refl_trans_gen.refl =>
        exact ⟨e, refl, refl_gen.single hde⟩
      case refl_trans_gen.tail f b hdf hfb ih =>
        rcases ih with ⟨a, hea, hfa⟩
        cases' hfa with _ hfa
        · exact ⟨b, hea.tail hfb, refl_gen.refl⟩
          
        · rcases h _ _ _ hfb hfa with ⟨c, hbc, hac⟩
          exact ⟨c, hea.trans hac, hbc⟩
          
    rcases this with ⟨a, hea, hba⟩
    cases' hba with _ hba
    · exact ⟨b, hea, hcb⟩
      
    · exact ⟨a, hea, hcb.tail hba⟩
      

theorem join_of_single (h : Reflexive r) (hab : r a b) : Join r a b :=
  ⟨b, hab, h b⟩

theorem symmetric_join : Symmetric (Join r) := fun a b ⟨c, hac, hcb⟩ => ⟨c, hcb, hac⟩

theorem reflexive_join (h : Reflexive r) : Reflexive (Join r) := fun a => ⟨a, h a, h a⟩

theorem transitive_join (ht : Transitive r) (h : ∀ a b c, r a b → r a c → Join r b c) : Transitive (Join r) :=
  fun a b c ⟨x, hax, hbx⟩ ⟨y, hby, hcy⟩ =>
  let ⟨z, hxz, hyz⟩ := h b x y hbx hby
  ⟨z, ht hax hxz, ht hcy hyz⟩

theorem equivalence_join (hr : Reflexive r) (ht : Transitive r) (h : ∀ a b c, r a b → r a c → Join r b c) :
    Equivalenceₓ (Join r) :=
  ⟨reflexive_join hr, symmetric_join, transitive_join ht h⟩

theorem equivalence_join_refl_trans_gen (h : ∀ a b c, r a b → r a c → ∃ d, ReflGen r b d ∧ ReflTransGen r c d) :
    Equivalenceₓ (Join (ReflTransGen r)) :=
  equivalence_join reflexive_refl_trans_gen transitive_refl_trans_gen fun a b c => church_rosser h

theorem join_of_equivalence {r' : α → α → Prop} (hr : Equivalenceₓ r) (h : ∀ a b, r' a b → r a b) : Join r' a b → r a b
  | ⟨c, hac, hbc⟩ => hr.2.2 (h _ _ hac) (hr.2.1 <| h _ _ hbc)

theorem refl_trans_gen_of_transitive_reflexive {r' : α → α → Prop} (hr : Reflexive r) (ht : Transitive r)
    (h : ∀ a b, r' a b → r a b) (h' : ReflTransGen r' a b) : r a b := by
  induction' h' with b c hab hbc ih
  · exact hr _
    
  · exact ht ih (h _ _ hbc)
    

theorem refl_trans_gen_of_equivalence {r' : α → α → Prop} (hr : Equivalenceₓ r) :
    (∀ a b, r' a b → r a b) → ReflTransGen r' a b → r a b :=
  refl_trans_gen_of_transitive_reflexive hr.1 hr.2.2

end Join

end Relation

section EqvGen

variable {r : α → α → Prop} {a b : α}

theorem Equivalenceₓ.eqv_gen_iff (h : Equivalenceₓ r) : EqvGen r a b ↔ r a b :=
  Iff.intro
    (by
      intro h
      induction h
      case eqv_gen.rel =>
        assumption
      case eqv_gen.refl =>
        exact h.1 _
      case eqv_gen.symm =>
        apply h.2.1
        assumption
      case eqv_gen.trans a b c _ _ hab hbc =>
        exact h.2.2 hab hbc)
    (EqvGen.rel a b)

theorem Equivalenceₓ.eqv_gen_eq (h : Equivalenceₓ r) : EqvGen r = r :=
  funext fun _ => funext fun _ => propext <| h.eqv_gen_iff

theorem EqvGen.mono {r p : α → α → Prop} (hrp : ∀ a b, r a b → p a b) (h : EqvGen r a b) : EqvGen p a b := by
  induction h
  case eqv_gen.rel a b h =>
    exact EqvGen.rel _ _ (hrp _ _ h)
  case eqv_gen.refl =>
    exact EqvGen.refl _
  case eqv_gen.symm a b h ih =>
    exact EqvGen.symm _ _ ih
  case eqv_gen.trans a b c ih1 ih2 hab hbc =>
    exact EqvGen.trans _ _ _ hab hbc

end EqvGen

