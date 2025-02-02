/-
Copyright (c) 2020 Kyle Miller All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller
-/
import Mathbin.Data.Sym.Basic
import Mathbin.Tactic.Linarith.Default

/-!
# The symmetric square

This file defines the symmetric square, which is `α × α` modulo
swapping.  This is also known as the type of unordered pairs.

More generally, the symmetric square is the second symmetric power
(see `data.sym.basic`). The equivalence is `sym2.equiv_sym`.

From the point of view that an unordered pair is equivalent to a
multiset of cardinality two (see `sym2.equiv_multiset`), there is a
`has_mem` instance `sym2.mem`, which is a `Prop`-valued membership
test.  Given `h : a ∈ z` for `z : sym2 α`, then `h.other` is the other
element of the pair, defined using `classical.choice`.  If `α` has
decidable equality, then `h.other'` computably gives the other element.

The universal property of `sym2` is provided as `sym2.lift`, which
states that functions from `sym2 α` are equivalent to symmetric
two-argument functions from `α`.

Recall that an undirected graph (allowing self loops, but no multiple
edges) is equivalent to a symmetric relation on the vertex type `α`.
Given a symmetric relation on `α`, the corresponding edge set is
constructed by `sym2.from_rel` which is a special case of `sym2.lift`.

## Notation

The symmetric square has a setoid instance, so `⟦(a, b)⟧` denotes a
term of the symmetric square.

## Tags

symmetric square, unordered pairs, symmetric powers
-/


open Finset Fintype Function Sym

universe u

variable {α β γ : Type _}

namespace Sym2

/-- This is the relation capturing the notion of pairs equivalent up to permutations.
-/
inductive Rel (α : Type u) : α × α → α × α → Prop
  | refl (x y : α) : rel (x, y) (x, y)
  | swap (x y : α) : rel (x, y) (y, x)

attribute [refl] rel.refl

@[symm]
theorem Rel.symm {x y : α × α} : Rel α x y → Rel α y x := by
  rintro ⟨_, _⟩ <;> constructor

@[trans]
theorem Rel.trans {x y z : α × α} (a : Rel α x y) (b : Rel α y z) : Rel α x z := by
  casesm* rel _ _ _ <;>
    first |
      apply rel.refl|
      apply rel.swap

theorem Rel.is_equivalence : Equivalenceₓ (Rel α) := by
  tidy <;> apply rel.trans <;> assumption

instance Rel.setoid (α : Type u) : Setoidₓ (α × α) :=
  ⟨Rel α, Rel.is_equivalence⟩

@[simp]
theorem rel_iff {x y z w : α} : (x, y) ≈ (z, w) ↔ x = z ∧ y = w ∨ x = w ∧ y = z := by
  constructor <;> intro h
  · cases h <;> simp
    
  · cases h <;> rw [h.1, h.2]
    constructor
    

end Sym2

/-- `sym2 α` is the symmetric square of `α`, which, in other words, is the
type of unordered pairs.

It is equivalent in a natural way to multisets of cardinality 2 (see
`sym2.equiv_multiset`).
-/
@[reducible]
def Sym2 (α : Type u) :=
  Quotientₓ (Sym2.Rel.setoid α)

namespace Sym2

@[elabAsElim]
protected theorem ind {f : Sym2 α → Prop} (h : ∀ x y, f ⟦(x, y)⟧) : ∀ i, f i :=
  Quotientₓ.ind <| Prod.rec <| h

@[elabAsElim]
protected theorem induction_on {f : Sym2 α → Prop} (i : Sym2 α) (hf : ∀ x y, f ⟦(x, y)⟧) : f i :=
  i.ind hf

@[elabAsElim]
protected theorem induction_on₂ {f : Sym2 α → Sym2 β → Prop} (i : Sym2 α) (j : Sym2 β)
    (hf : ∀ a₁ a₂ b₁ b₂, f ⟦(a₁, a₂)⟧ ⟦(b₁, b₂)⟧) : f i j :=
  Quotientₓ.induction_on₂ i j <| by
    rintro ⟨a₁, a₂⟩ ⟨b₁, b₂⟩
    exact hf _ _ _ _

protected theorem exists {α : Sort _} {f : Sym2 α → Prop} : (∃ x : Sym2 α, f x) ↔ ∃ x y, f ⟦(x, y)⟧ :=
  (surjective_quotient_mk _).exists.trans Prod.existsₓ

protected theorem forall {α : Sort _} {f : Sym2 α → Prop} : (∀ x : Sym2 α, f x) ↔ ∀ x y, f ⟦(x, y)⟧ :=
  (surjective_quotient_mk _).forall.trans Prod.forallₓ

theorem eq_swap {a b : α} : ⟦(a, b)⟧ = ⟦(b, a)⟧ := by
  rw [Quotientₓ.eq]
  apply rel.swap

@[simp]
theorem mk_prod_swap_eq {p : α × α} : ⟦p.swap⟧ = ⟦p⟧ := by
  cases p
  exact eq_swap

theorem congr_right {a b c : α} : ⟦(a, b)⟧ = ⟦(a, c)⟧ ↔ b = c := by
  constructor <;> intro h
  · rw [Quotientₓ.eq] at h
    cases h <;> rfl
    
  rw [h]

theorem congr_left {a b c : α} : ⟦(b, a)⟧ = ⟦(c, a)⟧ ↔ b = c := by
  constructor <;> intro h
  · rw [Quotientₓ.eq] at h
    cases h <;> rfl
    
  rw [h]

theorem eq_iff {x y z w : α} : ⟦(x, y)⟧ = ⟦(z, w)⟧ ↔ x = z ∧ y = w ∨ x = w ∧ y = z := by
  simp

theorem mk_eq_mk_iff {p q : α × α} : ⟦p⟧ = ⟦q⟧ ↔ p = q ∨ p = q.swap := by
  cases p
  cases q
  simp only [eq_iff, Prod.mk.inj_iffₓ, Prod.swap_prod_mkₓ]

/-- The universal property of `sym2`; symmetric functions of two arguments are equivalent to
functions from `sym2`. Note that when `β` is `Prop`, it can sometimes be more convenient to use
`sym2.from_rel` instead. -/
def lift : { f : α → α → β // ∀ a₁ a₂, f a₁ a₂ = f a₂ a₁ } ≃ (Sym2 α → β) where
  toFun := fun f =>
    Quotientₓ.lift (uncurry ↑f) <| by
      rintro _ _ ⟨⟩
      exacts[rfl, f.prop _ _]
  invFun := fun F => ⟨curry (F ∘ Quotientₓ.mk), fun a₁ a₂ => congr_argₓ F eq_swap⟩
  left_inv := fun f => Subtype.ext rfl
  right_inv := fun F => funext <| Sym2.ind fun x y => rfl

@[simp]
theorem lift_mk (f : { f : α → α → β // ∀ a₁ a₂, f a₁ a₂ = f a₂ a₁ }) (a₁ a₂ : α) :
    lift f ⟦(a₁, a₂)⟧ = (f : α → α → β) a₁ a₂ :=
  rfl

@[simp]
theorem coe_lift_symm_apply (F : Sym2 α → β) (a₁ a₂ : α) : (lift.symm F : α → α → β) a₁ a₂ = F ⟦(a₁, a₂)⟧ :=
  rfl

/-- A two-argument version of `sym2.lift`. -/
def lift₂ :
    { f : α → α → β → β → γ // ∀ a₁ a₂ b₁ b₂, f a₁ a₂ b₁ b₂ = f a₂ a₁ b₁ b₂ ∧ f a₁ a₂ b₁ b₂ = f a₁ a₂ b₂ b₁ } ≃
      (Sym2 α → Sym2 β → γ) where
  toFun := fun f =>
    Quotientₓ.lift₂ (fun (a : α × α) (b : β × β) => f.1 a.1 a.2 b.1 b.2)
      (by
        rintro _ _ _ _ ⟨⟩ ⟨⟩
        exacts[rfl, (f.2 _ _ _ _).2, (f.2 _ _ _ _).1, (f.2 _ _ _ _).1.trans (f.2 _ _ _ _).2])
  invFun := fun F =>
    ⟨fun a₁ a₂ b₁ b₂ => F ⟦(a₁, a₂)⟧ ⟦(b₁, b₂)⟧, fun a₁ a₂ b₁ b₂ => by
      constructor
      exacts[congr_arg2ₓ F eq_swap rfl, congr_arg2ₓ F rfl eq_swap]⟩
  left_inv := fun f => Subtype.ext rfl
  right_inv := fun F => funext₂ fun a b => (Sym2.induction_on₂ a b) fun _ _ _ _ => rfl

@[simp]
theorem lift₂_mk
    (f : { f : α → α → β → β → γ // ∀ a₁ a₂ b₁ b₂, f a₁ a₂ b₁ b₂ = f a₂ a₁ b₁ b₂ ∧ f a₁ a₂ b₁ b₂ = f a₁ a₂ b₂ b₁ })
    (a₁ a₂ : α) (b₁ b₂ : β) : lift₂ f ⟦(a₁, a₂)⟧ ⟦(b₁, b₂)⟧ = (f : α → α → β → β → γ) a₁ a₂ b₁ b₂ :=
  rfl

@[simp]
theorem coe_lift₂_symm_apply (F : Sym2 α → Sym2 β → γ) (a₁ a₂ : α) (b₁ b₂ : β) :
    (lift₂.symm F : α → α → β → β → γ) a₁ a₂ b₁ b₂ = F ⟦(a₁, a₂)⟧ ⟦(b₁, b₂)⟧ :=
  rfl

/-- The functor `sym2` is functorial, and this function constructs the induced maps.
-/
def map (f : α → β) : Sym2 α → Sym2 β :=
  Quotientₓ.map (Prod.map f f)
    (by
      rintro _ _ h
      cases h
      · rfl
        
      apply rel.swap)

@[simp]
theorem map_id : map (@id α) = id := by
  ext ⟨⟨x, y⟩⟩
  rfl

theorem map_comp {g : β → γ} {f : α → β} : Sym2.map (g ∘ f) = Sym2.map g ∘ Sym2.map f := by
  ext ⟨⟨x, y⟩⟩
  rfl

theorem map_map {g : β → γ} {f : α → β} (x : Sym2 α) : map g (map f x) = map (g ∘ f) x := by
  tidy

@[simp]
theorem map_pair_eq (f : α → β) (x y : α) : map f ⟦(x, y)⟧ = ⟦(f x, f y)⟧ :=
  rfl

theorem map.injective {f : α → β} (hinj : Injective f) : Injective (map f) := by
  intro z z'
  refine' Quotientₓ.ind₂ (fun z z' => _) z z'
  cases' z with x y
  cases' z' with x' y'
  repeat'
    rw [map_pair_eq, eq_iff]
  rintro (h | h) <;> simp [hinj h.1, hinj h.2]

section Membership

/-! ### Declarations about membership -/


/-- This is a predicate that determines whether a given term is a member of a term of the
symmetric square.  From this point of view, the symmetric square is the subtype of
cardinality-two multisets on `α`.
-/
def Mem (x : α) (z : Sym2 α) : Prop :=
  ∃ y : α, z = ⟦(x, y)⟧

instance : Membership α (Sym2 α) :=
  ⟨Mem⟩

theorem mem_mk_left (x y : α) : x ∈ ⟦(x, y)⟧ :=
  ⟨y, rfl⟩

theorem mem_mk_right (x y : α) : y ∈ ⟦(x, y)⟧ :=
  eq_swap.subst <| mem_mk_left y x

@[simp]
theorem mem_iff {a b c : α} : a ∈ ⟦(b, c)⟧ ↔ a = b ∨ a = c :=
  { mp := by
      rintro ⟨_, h⟩
      rw [eq_iff] at h
      tidy,
    mpr := by
      rintro ⟨_⟩ <;> subst a
      · apply mem_mk_left
        
      apply mem_mk_right }

theorem out_fst_mem (e : Sym2 α) : e.out.1 ∈ e :=
  ⟨e.out.2, by
    rw [Prod.mk.etaₓ, e.out_eq]⟩

theorem out_snd_mem (e : Sym2 α) : e.out.2 ∈ e :=
  ⟨e.out.1, by
    rw [eq_swap, Prod.mk.etaₓ, e.out_eq]⟩

theorem ball {p : α → Prop} {a b : α} : (∀ c ∈ ⟦(a, b)⟧, p c) ↔ p a ∧ p b := by
  refine' ⟨fun h => ⟨h _ <| mem_mk_left _ _, h _ <| mem_mk_right _ _⟩, fun h c hc => _⟩
  obtain rfl | rfl := Sym2.mem_iff.1 hc
  · exact h.1
    
  · exact h.2
    

/-- Given an element of the unordered pair, give the other element using `classical.some`.
See also `mem.other'` for the computable version.
-/
noncomputable def Mem.other {a : α} {z : Sym2 α} (h : a ∈ z) : α :=
  Classical.choose h

@[simp]
theorem other_spec {a : α} {z : Sym2 α} (h : a ∈ z) : ⟦(a, h.other)⟧ = z := by
  erw [← Classical.choose_spec h]

theorem other_mem {a : α} {z : Sym2 α} (h : a ∈ z) : h.other ∈ z := by
  convert mem_mk_right a h.other
  rw [other_spec h]

theorem mem_and_mem_iff {x y : α} {z : Sym2 α} (hne : x ≠ y) : x ∈ z ∧ y ∈ z ↔ z = ⟦(x, y)⟧ := by
  constructor
  · induction' z using Sym2.ind with x' y'
    rw [mem_iff, mem_iff]
    rintro ⟨rfl | rfl, rfl | rfl⟩ <;>
      try
          trivial <;>
        simp only [Sym2.eq_swap]
    
  · rintro rfl
    simp
    

theorem eq_of_ne_mem {x y : α} {z z' : Sym2 α} (h : x ≠ y) (h1 : x ∈ z) (h2 : y ∈ z) (h3 : x ∈ z') (h4 : y ∈ z') :
    z = z' :=
  ((mem_and_mem_iff h).mp ⟨h1, h2⟩).trans ((mem_and_mem_iff h).mp ⟨h3, h4⟩).symm

@[ext]
protected theorem ext (z z' : Sym2 α) (h : ∀ x, x ∈ z ↔ x ∈ z') : z = z' := by
  induction' z using Sym2.ind with x y
  induction' z' using Sym2.ind with x' y'
  have hx := h x
  have hy := h y
  have hx' := h x'
  have hy' := h y'
  simp only [mem_iff, eq_self_iff_true, or_trueₓ, iff_trueₓ, true_orₓ, true_iffₓ] at hx hy hx' hy'
  cases hx <;> cases hy <;> cases hx' <;> cases hy' <;> subst_vars
  simp only [Sym2.eq_swap]

instance Mem.decidable [DecidableEq α] (x : α) (z : Sym2 α) : Decidable (x ∈ z) :=
  Quotientₓ.recOnSubsingleton z fun ⟨y₁, y₂⟩ => decidableOfIff' _ mem_iff

end Membership

@[simp]
theorem mem_map {f : α → β} {b : β} {z : Sym2 α} : b ∈ Sym2.map f z ↔ ∃ a, a ∈ z ∧ f a = b := by
  induction' z using Sym2.ind with x y
  simp only [map, Quotientₓ.map_mk, Prod.map_mkₓ, mem_iff]
  constructor
  · rintro (rfl | rfl)
    · exact
        ⟨x, by
          simp ⟩
      
    · exact
        ⟨y, by
          simp ⟩
      
    
  · rintro ⟨w, rfl | rfl, rfl⟩ <;> simp
    

@[congr]
theorem map_congr {f g : α → β} {s : Sym2 α} (h : ∀ x ∈ s, f x = g x) : map f s = map g s := by
  ext y
  simp only [mem_map]
  constructor <;>
    · rintro ⟨w, hw, rfl⟩
      exact
        ⟨w, hw, by
          simp [hw, h]⟩
      

/-- Note: `sym2.map_id` will not simplify `sym2.map id z` due to `sym2.map_congr`. -/
@[simp]
theorem map_id' : (map fun x : α => x) = id :=
  map_id

/-! ### Diagonal -/


/-- A type `α` is naturally included in the diagonal of `α × α`, and this function gives the image
of this diagonal in `sym2 α`.
-/
def diag (x : α) : Sym2 α :=
  ⟦(x, x)⟧

theorem diag_injective : Function.Injective (Sym2.diag : α → Sym2 α) := fun x y h => by
  cases Quotientₓ.exact h <;> rfl

/-- A predicate for testing whether an element of `sym2 α` is on the diagonal.
-/
def IsDiag : Sym2 α → Prop :=
  lift ⟨Eq, fun _ _ => propext eq_comm⟩

theorem mk_is_diag_iff {x y : α} : IsDiag ⟦(x, y)⟧ ↔ x = y :=
  Iff.rfl

@[simp]
theorem is_diag_iff_proj_eq (z : α × α) : IsDiag ⟦z⟧ ↔ z.1 = z.2 :=
  (Prod.recOn z) fun _ _ => mk_is_diag_iff

@[simp]
theorem diag_is_diag (a : α) : IsDiag (diag a) :=
  Eq.refl a

theorem IsDiag.mem_range_diag {z : Sym2 α} : IsDiag z → z ∈ Set.Range (@diag α) := by
  induction' z using Sym2.ind with x y
  rintro (rfl : x = y)
  exact ⟨_, rfl⟩

theorem is_diag_iff_mem_range_diag (z : Sym2 α) : IsDiag z ↔ z ∈ Set.Range (@diag α) :=
  ⟨IsDiag.mem_range_diag, fun ⟨i, hi⟩ => hi ▸ diag_is_diag i⟩

instance IsDiag.decidablePred (α : Type u) [DecidableEq α] : DecidablePred (@IsDiag α) := by
  refine' fun z => Quotientₓ.recOnSubsingleton z fun a => _
  erw [is_diag_iff_proj_eq]
  infer_instance

theorem other_ne {a : α} {z : Sym2 α} (hd : ¬IsDiag z) (h : a ∈ z) : h.other ≠ a := by
  contrapose! hd
  have h' := Sym2.other_spec h
  rw [hd] at h'
  rw [← h']
  simp

section Relations

/-! ### Declarations about symmetric relations -/


variable {r : α → α → Prop}

/-- Symmetric relations define a set on `sym2 α` by taking all those pairs
of elements that are related.
-/
def FromRel (sym : Symmetric r) : Set (Sym2 α) :=
  SetOf (lift ⟨r, fun x y => propext ⟨fun h => Sym h, fun h => Sym h⟩⟩)

@[simp]
theorem from_rel_proj_prop {sym : Symmetric r} {z : α × α} : ⟦z⟧ ∈ FromRel Sym ↔ r z.1 z.2 :=
  Iff.rfl

@[simp]
theorem from_rel_prop {sym : Symmetric r} {a b : α} : ⟦(a, b)⟧ ∈ FromRel Sym ↔ r a b :=
  Iff.rfl

theorem from_rel_irreflexive {sym : Symmetric r} : Irreflexive r ↔ ∀ {z}, z ∈ FromRel Sym → ¬IsDiag z :=
  { mp := fun h =>
      Sym2.ind <| by
        rintro a b hr (rfl : a = b)
        exact h _ hr,
    mpr := fun h x hr => h (from_rel_prop.mpr hr) rfl }

theorem mem_from_rel_irrefl_other_ne {sym : Symmetric r} (irrefl : Irreflexive r) {a : α} {z : Sym2 α}
    (hz : z ∈ FromRel Sym) (h : a ∈ z) : h.other ≠ a :=
  other_ne (from_rel_irreflexive.mp irrefl hz) h

instance FromRel.decidablePred (sym : Symmetric r) [h : DecidableRel r] : DecidablePred (· ∈ Sym2.FromRel Sym) :=
  fun z => Quotientₓ.recOnSubsingleton z fun x => h _ _

/-- The inverse to `sym2.from_rel`. Given a set on `sym2 α`, give a symmetric relation on `α`
(see `sym2.to_rel_symmetric`). -/
def ToRel (s : Set (Sym2 α)) (x y : α) : Prop :=
  ⟦(x, y)⟧ ∈ s

@[simp]
theorem to_rel_prop (s : Set (Sym2 α)) (x y : α) : ToRel s x y ↔ ⟦(x, y)⟧ ∈ s :=
  Iff.rfl

theorem to_rel_symmetric (s : Set (Sym2 α)) : Symmetric (ToRel s) := fun x y => by
  simp [eq_swap]

theorem to_rel_from_rel (sym : Symmetric r) : ToRel (FromRel Sym) = r :=
  rfl

theorem from_rel_to_rel (s : Set (Sym2 α)) : FromRel (to_rel_symmetric s) = s :=
  Set.ext fun z => Sym2.ind (fun x y => Iff.rfl) z

end Relations

section SymEquiv

/-! ### Equivalence to the second symmetric power -/


attribute [local instance] Vector.Perm.isSetoid

private def from_vector : Vector α 2 → α × α
  | ⟨[a, b], h⟩ => (a, b)

private theorem perm_card_two_iff {a₁ b₁ a₂ b₂ : α} : [a₁, b₁].Perm [a₂, b₂] ↔ a₁ = a₂ ∧ b₁ = b₂ ∨ a₁ = b₂ ∧ b₁ = a₂ :=
  { mp := by
      simp [← Multiset.coe_eq_coe, ← Multiset.cons_coe, Multiset.cons_eq_cons]
      tidy,
    mpr := by
      intro h
      cases h <;> rw [h.1, h.2]
      apply List.Perm.swap'
      rfl }

/-- The symmetric square is equivalent to length-2 vectors up to permutations.
-/
def sym2EquivSym' : Equivₓ (Sym2 α) (Sym' α 2) where
  toFun :=
    Quotientₓ.map (fun x : α × α => ⟨[x.1, x.2], rfl⟩)
      (by
        rintro _ _ ⟨_⟩
        · rfl
          
        apply List.Perm.swap'
        rfl)
  invFun :=
    Quotientₓ.map fromVector
      (by
        rintro ⟨x, hx⟩ ⟨y, hy⟩ h
        cases' x with _ x
        · simpa using hx
          
        cases' x with _ x
        · simpa using hx
          
        cases' x with _ x
        swap
        · exfalso
          simp at hx
          linarith [hx]
          
        cases' y with _ y
        · simpa using hy
          
        cases' y with _ y
        · simpa using hy
          
        cases' y with _ y
        swap
        · exfalso
          simp at hy
          linarith [hy]
          
        rcases perm_card_two_iff.mp h with (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩)
        · rfl
          
        apply Sym2.Rel.swap)
  left_inv := by
    tidy
  right_inv := fun x => by
    refine' Quotientₓ.recOnSubsingleton x fun x => _
    · cases' x with x hx
      cases' x with _ x
      · simpa using hx
        
      cases' x with _ x
      · simpa using hx
        
      cases' x with _ x
      swap
      · exfalso
        simp at hx
        linarith [hx]
        
      rfl
      

/-- The symmetric square is equivalent to the second symmetric power.
-/
def equivSym (α : Type _) : Sym2 α ≃ Sym α 2 :=
  Equivₓ.trans sym2EquivSym' symEquivSym'.symm

/-- The symmetric square is equivalent to multisets of cardinality
two. (This is currently a synonym for `equiv_sym`, but it's provided
in case the definition for `sym` changes.)
-/
def equivMultiset (α : Type _) : Sym2 α ≃ { s : Multiset α // s.card = 2 } :=
  equivSym α

end SymEquiv

section Decidable

/-- An algorithm for computing `sym2.rel`.
-/
def relBool [DecidableEq α] (x y : α × α) : Bool :=
  if x.1 = y.1 then x.2 = y.2 else if x.1 = y.2 then x.2 = y.1 else false

theorem rel_bool_spec [DecidableEq α] (x y : α × α) : ↥(relBool x y) ↔ Rel α x y := by
  cases' x with x₁ x₂
  cases' y with y₁ y₂
  dsimp' [rel_bool]
  split_ifs <;> simp only [false_iffₓ, Bool.coe_sort_ff, Bool.of_to_bool_iff]
  rotate_left 2
  · contrapose! h
    cases h <;> cc
    
  all_goals
    subst x₁
    constructor <;> intro h1
    · subst h1 <;> apply Sym2.Rel.swap
      
    · cases h1 <;> cc
      

/-- Given `[decidable_eq α]` and `[fintype α]`, the following instance gives `fintype (sym2 α)`.
-/
instance (α : Type _) [DecidableEq α] : DecidableRel (Sym2.Rel α) := fun x y =>
  decidableOfBool (relBool x y) (rel_bool_spec x y)

/-! ### The other element of an element of the symmetric square -/


/-- A function that gives the other element of a pair given one of the elements.  Used in `mem.other'`.
-/
private def pair_other [DecidableEq α] (a : α) (z : α × α) : α :=
  if a = z.1 then z.2 else z.1

/-- Get the other element of the unordered pair using the decidable equality.
This is the computable version of `mem.other`.
-/
def Mem.other' [DecidableEq α] {a : α} {z : Sym2 α} (h : a ∈ z) : α :=
  Quot.rec (fun x h' => pairOther a x)
    (by
      clear h z
      intro x y h
      ext hy
      convert_to pair_other a x = _
      · have h' : ∀ {c e h}, @Eq.ndrec _ ⟦x⟧ (fun s => a ∈ s → α) (fun _ => pair_other a x) c e h = pair_other a x := by
          intro _ e _
          subst e
        apply h'
        
      have h' := (rel_bool_spec x y).mpr h
      cases' x with x₁ x₂
      cases' y with y₁ y₂
      cases' mem_iff.mp hy with hy' <;>
        subst a <;>
          dsimp' [rel_bool]  at h' <;>
            split_ifs  at h' <;>
              try
                  rw [Bool.of_to_bool_iff] at h'
                  subst x₁
                  subst x₂ <;>
                dsimp' [pair_other]
      simp only [Ne.symm h_1, if_true, eq_self_iff_true, if_false]
      exfalso
      exact Bool.not_ff h'
      simp only [h_1, if_true, eq_self_iff_true, if_false]
      exfalso
      exact Bool.not_ff h')
    z h

@[simp]
theorem other_spec' [DecidableEq α] {a : α} {z : Sym2 α} (h : a ∈ z) : ⟦(a, h.other')⟧ = z := by
  induction z
  cases' z with x y
  have h' := mem_iff.mp h
  dsimp' [mem.other', Quot.rec, pair_other]
  cases h' <;> subst a
  · simp only [if_true, eq_self_iff_true]
    rfl
    
  · split_ifs
    subst h_1
    rfl
    rw [eq_swap]
    rfl
    
  rfl

@[simp]
theorem other_eq_other' [DecidableEq α] {a : α} {z : Sym2 α} (h : a ∈ z) : h.other = h.other' := by
  rw [← congr_right, other_spec' h, other_spec]

theorem other_mem' [DecidableEq α] {a : α} {z : Sym2 α} (h : a ∈ z) : h.other' ∈ z := by
  rw [← other_eq_other']
  exact other_mem h

theorem other_invol' [DecidableEq α] {a : α} {z : Sym2 α} (ha : a ∈ z) (hb : ha.other' ∈ z) : hb.other' = a := by
  induction z
  cases' z with x y
  dsimp' [mem.other', Quot.rec, pair_other]  at hb
  split_ifs  at hb <;> dsimp' [mem.other', Quot.rec, pair_other]
  simp only [h, if_true, eq_self_iff_true]
  split_ifs
  assumption
  rfl
  simp only [h, if_false, if_true, eq_self_iff_true]
  exact ((mem_iff.mp ha).resolve_left h).symm
  rfl

theorem other_invol {a : α} {z : Sym2 α} (ha : a ∈ z) (hb : ha.other ∈ z) : hb.other = a := by
  classical
  rw [other_eq_other'] at hb⊢
  convert other_invol' ha hb
  rw [other_eq_other']

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem filter_image_quotient_mk_is_diag [DecidableEq α] (s : Finset α) :
    ((s ×ˢ s).Image Quotientₓ.mk).filter IsDiag = s.diag.Image Quotientₓ.mk := by
  ext z
  induction z using Quotientₓ.induction_on
  rcases z with ⟨x, y⟩
  simp only [mem_image, mem_diag, exists_prop, mem_filter, Prod.existsₓ, mem_product]
  constructor
  · rintro ⟨⟨a, b, ⟨ha, hb⟩, h⟩, hab⟩
    rw [← h, Sym2.mk_is_diag_iff] at hab
    exact ⟨a, b, ⟨ha, hab⟩, h⟩
    
  · rintro ⟨a, b, ⟨ha, rfl⟩, h⟩
    rw [← h]
    exact ⟨⟨a, a, ⟨ha, ha⟩, rfl⟩, rfl⟩
    

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
theorem filter_image_quotient_mk_not_is_diag [DecidableEq α] (s : Finset α) :
    (((s ×ˢ s).Image Quotientₓ.mk).filter fun a : Sym2 α => ¬a.IsDiag) = s.offDiag.Image Quotientₓ.mk := by
  ext z
  induction z using Quotientₓ.induction_on
  rcases z with ⟨x, y⟩
  simp only [mem_image, mem_off_diag, exists_prop, mem_filter, Prod.existsₓ, mem_product]
  constructor
  · rintro ⟨⟨a, b, ⟨ha, hb⟩, h⟩, hab⟩
    rw [← h, Sym2.mk_is_diag_iff] at hab
    exact ⟨a, b, ⟨ha, hb, hab⟩, h⟩
    
  · rintro ⟨a, b, ⟨ha, hb, hab⟩, h⟩
    rw [Ne.def, ← Sym2.mk_is_diag_iff, h] at hab
    exact ⟨⟨a, b, ⟨ha, hb⟩, h⟩, hab⟩
    

end Decidable

instance [Subsingleton α] : Subsingleton (Sym2 α) :=
  (equivSym α).Injective.Subsingleton

instance [Unique α] : Unique (Sym2 α) :=
  Unique.mk' _

instance [IsEmpty α] : IsEmpty (Sym2 α) :=
  (equivSym α).isEmpty

instance [Nontrivial α] : Nontrivial (Sym2 α) :=
  diag_injective.Nontrivial

end Sym2

