/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Floris van Doorn
-/
import Mathbin.Order.RelIso
import Mathbin.Order.WellFounded

/-!
# Initial and principal segments

This file defines initial and principal segments.

## Main definitions

* `initial_seg r s`: type of order embeddings of `r` into `s` for which the range is an initial
  segment (i.e., if `b` belongs to the range, then any `b' < b` also belongs to the range).
  It is denoted by `r ≼i s`.
* `principal_seg r s`: Type of order embeddings of `r` into `s` for which the range is a principal
  segment, i.e., an interval of the form `(-∞, top)` for some element `top`. It is denoted by
  `r ≺i s`.

## Notations

These notations belong to the `initial_seg` locale.

* `r ≼i s`: the type of initial segment embeddings of `r` into `s`.
* `r ≺i s`: the type of principal segment embeddings of `r` into `s`.
-/


/-!
### Initial segments

Order embeddings whose range is an initial segment of `s` (i.e., if `b` belongs to the range, then
any `b' < b` also belongs to the range). The type of these embeddings from `r` to `s` is called
`initial_seg r s`, and denoted by `r ≼i s`.
-/


variable {α : Type _} {β : Type _} {γ : Type _} {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

open Function

/-- If `r` is a relation on `α` and `s` in a relation on `β`, then `f : r ≼i s` is an order
embedding whose range is an initial segment. That is, whenever `b < f a` in `β` then `b` is in the
range of `f`. -/
structure InitialSeg {α β : Type _} (r : α → α → Prop) (s : β → β → Prop) extends r ↪r s where
  init : ∀ a b, s b (to_rel_embedding a) → ∃ a', to_rel_embedding a' = b

-- mathport name: initial_seg
localized [InitialSeg] infixl:25 " ≼i " => InitialSeg

namespace InitialSeg

instance : Coe (r ≼i s) (r ↪r s) :=
  ⟨InitialSeg.toRelEmbedding⟩

instance : CoeFun (r ≼i s) fun _ => α → β :=
  ⟨fun f x => (f : r ↪r s) x⟩

@[simp]
theorem coe_fn_mk (f : r ↪r s) (o) : (@InitialSeg.mk _ _ r s f o : α → β) = f :=
  rfl

@[simp]
theorem coe_fn_to_rel_embedding (f : r ≼i s) : (f.toRelEmbedding : α → β) = f :=
  rfl

@[simp]
theorem coe_coe_fn (f : r ≼i s) : ((f : r ↪r s) : α → β) = f :=
  rfl

theorem init' (f : r ≼i s) {a : α} {b : β} : s b (f a) → ∃ a', f a' = b :=
  f.init _ _

theorem init_iff (f : r ≼i s) {a : α} {b : β} : s b (f a) ↔ ∃ a', f a' = b ∧ r a' a :=
  ⟨fun h =>
    let ⟨a', e⟩ := f.init' h
    ⟨a', e, (f : r ↪r s).map_rel_iff.1 (e.symm ▸ h)⟩,
    fun ⟨a', e, h⟩ => e ▸ (f : r ↪r s).map_rel_iff.2 h⟩

/-- An order isomorphism is an initial segment -/
def ofIso (f : r ≃r s) : r ≼i s :=
  ⟨f, fun a b h => ⟨f.symm b, RelIso.apply_symm_apply f _⟩⟩

/-- The identity function shows that `≼i` is reflexive -/
@[refl]
protected def refl (r : α → α → Prop) : r ≼i r :=
  ⟨RelEmbedding.refl _, fun a b h => ⟨_, rfl⟩⟩

instance (r : α → α → Prop) : Inhabited (r ≼i r) :=
  ⟨InitialSeg.refl r⟩

/-- Composition of functions shows that `≼i` is transitive -/
@[trans]
protected def trans (f : r ≼i s) (g : s ≼i t) : r ≼i t :=
  ⟨f.1.trans g.1, fun a c h => by
    simp at h⊢
    rcases g.2 _ _ h with ⟨b, rfl⟩
    have h := g.1.map_rel_iff.1 h
    rcases f.2 _ _ h with ⟨a', rfl⟩
    exact ⟨a', rfl⟩⟩

@[simp]
theorem refl_apply (x : α) : InitialSeg.refl r x = x :=
  rfl

@[simp]
theorem trans_apply (f : r ≼i s) (g : s ≼i t) (a : α) : (f.trans g) a = g (f a) :=
  rfl

theorem unique_of_trichotomous_of_irrefl [IsTrichotomous β s] [IsIrrefl β s] : WellFounded r → Subsingleton (r ≼i s)
  | ⟨h⟩ =>
    ⟨fun f g => by
      suffices (f : α → β) = g by
        cases f
        cases g
        congr
        exact RelEmbedding.coe_fn_injective this
      funext a
      have := h a
      induction' this with a H IH
      refine' extensional_of_trichotomous_of_irrefl s fun x => ⟨fun h => _, fun h => _⟩
      · rcases f.init_iff.1 h with ⟨y, rfl, h'⟩
        rw [IH _ h']
        exact (g : r ↪r s).map_rel_iff.2 h'
        
      · rcases g.init_iff.1 h with ⟨y, rfl, h'⟩
        rw [← IH _ h']
        exact (f : r ↪r s).map_rel_iff.2 h'
        ⟩

instance [IsWellOrder β s] : Subsingleton (r ≼i s) :=
  ⟨fun a =>
    @Subsingleton.elim _ (unique_of_trichotomous_of_irrefl (@RelEmbedding.well_founded _ _ r s a IsWellFounded.wf)) a⟩

protected theorem eq [IsWellOrder β s] (f g : r ≼i s) (a) : f a = g a := by
  rw [Subsingleton.elim f g]

theorem Antisymm.aux [IsWellOrder α r] (f : r ≼i s) (g : s ≼i r) : LeftInverse g f :=
  InitialSeg.eq (f.trans g) (InitialSeg.refl _)

/-- If we have order embeddings between `α` and `β` whose images are initial segments, and `β`
is a well-order then `α` and `β` are order-isomorphic. -/
def antisymm [IsWellOrder β s] (f : r ≼i s) (g : s ≼i r) : r ≃r s :=
  haveI := f.to_rel_embedding.is_well_order
  ⟨⟨f, g, antisymm.aux f g, antisymm.aux g f⟩, fun _ _ => f.map_rel_iff'⟩

@[simp]
theorem antisymm_to_fun [IsWellOrder β s] (f : r ≼i s) (g : s ≼i r) : (antisymm f g : α → β) = f :=
  rfl

@[simp]
theorem antisymm_symm [IsWellOrder α r] [IsWellOrder β s] (f : r ≼i s) (g : s ≼i r) :
    (antisymm f g).symm = antisymm g f :=
  RelIso.coe_fn_injective rfl

theorem eq_or_principal [IsWellOrder β s] (f : r ≼i s) : Surjective f ∨ ∃ b, ∀ x, s x b ↔ ∃ y, f y = x :=
  or_iff_not_imp_right.2 fun h b =>
    (Acc.recOnₓ (IsWellFounded.wf.apply b : Acc s b)) fun x H IH =>
      not_forall_not.1 fun hn =>
        h
          ⟨x, fun y =>
            ⟨IH _, fun ⟨a, e⟩ => by
              rw [← e] <;>
                exact (trichotomous _ _).resolve_right (not_orₓ (hn a) fun hl => not_exists.2 hn (f.init' hl))⟩⟩

/-- Restrict the codomain of an initial segment -/
def codRestrict (p : Set β) (f : r ≼i s) (H : ∀ a, f a ∈ p) : r ≼i Subrel s p :=
  ⟨RelEmbedding.codRestrict p f H, fun a ⟨b, m⟩ (h : s b (f a)) =>
    let ⟨a', e⟩ := f.init' h
    ⟨a', by
      clear _let_match <;> subst e <;> rfl⟩⟩

@[simp]
theorem cod_restrict_apply (p) (f : r ≼i s) (H a) : codRestrict p f H a = ⟨f a, H a⟩ :=
  rfl

/-- Initial segment from an empty type. -/
def ofIsEmpty (r : α → α → Prop) (s : β → β → Prop) [IsEmpty α] : r ≼i s :=
  ⟨RelEmbedding.ofIsEmpty r s, isEmptyElim⟩

/-- Initial segment embedding of an order `r` into the disjoint union of `r` and `s`. -/
def leAdd (r : α → α → Prop) (s : β → β → Prop) : r ≼i Sum.Lex r s :=
  ⟨⟨⟨Sum.inl, fun _ _ => Sum.inl.injₓ⟩, fun a b => Sum.lex_inl_inl⟩, fun a b => by
    cases b <;> [exact fun _ => ⟨_, rfl⟩, exact False.elim ∘ Sum.lex_inr_inl]⟩

@[simp]
theorem le_add_apply (r : α → α → Prop) (s : β → β → Prop) (a) : leAdd r s a = Sum.inl a :=
  rfl

end InitialSeg

/-!
### Principal segments

Order embeddings whose range is a principal segment of `s` (i.e., an interval of the form
`(-∞, top)` for some element `top` of `β`). The type of these embeddings from `r` to `s` is called
`principal_seg r s`, and denoted by `r ≺i s`. Principal segments are in particular initial
segments.
-/


/-- If `r` is a relation on `α` and `s` in a relation on `β`, then `f : r ≺i s` is an order
embedding whose range is an open interval `(-∞, top)` for some element `top` of `β`. Such order
embeddings are called principal segments -/
@[nolint has_nonempty_instance]
structure PrincipalSeg {α β : Type _} (r : α → α → Prop) (s : β → β → Prop) extends r ↪r s where
  top : β
  down' : ∀ b, s b top ↔ ∃ a, to_rel_embedding a = b

-- mathport name: principal_seg
localized [InitialSeg] infixl:25 " ≺i " => PrincipalSeg

namespace PrincipalSeg

instance : Coe (r ≺i s) (r ↪r s) :=
  ⟨PrincipalSeg.toRelEmbedding⟩

instance : CoeFun (r ≺i s) fun _ => α → β :=
  ⟨fun f => f⟩

@[simp]
theorem coe_fn_mk (f : r ↪r s) (t o) : (@PrincipalSeg.mk _ _ r s f t o : α → β) = f :=
  rfl

@[simp]
theorem coe_fn_to_rel_embedding (f : r ≺i s) : (f.toRelEmbedding : α → β) = f :=
  rfl

@[simp]
theorem coe_coe_fn (f : r ≺i s) : ((f : r ↪r s) : α → β) = f :=
  rfl

theorem down (f : r ≺i s) : ∀ {b : β}, s b f.top ↔ ∃ a, f a = b :=
  f.down'

theorem lt_top (f : r ≺i s) (a : α) : s (f a) f.top :=
  f.down.2 ⟨_, rfl⟩

theorem init [IsTrans β s] (f : r ≺i s) {a : α} {b : β} (h : s b (f a)) : ∃ a', f a' = b :=
  f.down.1 <| trans h <| f.lt_top _

/-- A principal segment is in particular an initial segment. -/
instance hasCoeInitialSeg [IsTrans β s] : Coe (r ≺i s) (r ≼i s) :=
  ⟨fun f => ⟨f.toRelEmbedding, fun a b => f.init⟩⟩

theorem coe_coe_fn' [IsTrans β s] (f : r ≺i s) : ((f : r ≼i s) : α → β) = f :=
  rfl

theorem init_iff [IsTrans β s] (f : r ≺i s) {a : α} {b : β} : s b (f a) ↔ ∃ a', f a' = b ∧ r a' a :=
  @InitialSeg.init_iff α β r s f a b

theorem irrefl {r : α → α → Prop} [IsWellOrder α r] (f : r ≺i r) : False := by
  have := f.lt_top f.top
  rw [show f f.top = f.top from InitialSeg.eq (↑f) (InitialSeg.refl r) f.top] at this
  exact irrefl _ this

instance (r : α → α → Prop) [IsWellOrder α r] : IsEmpty (r ≺i r) :=
  ⟨fun f => f.irrefl⟩

/-- Composition of a principal segment with an initial segment, as a principal segment -/
def ltLe (f : r ≺i s) (g : s ≼i t) : r ≺i t :=
  ⟨@RelEmbedding.trans _ _ _ r s t f g, g f.top, fun a => by
    simp only [g.init_iff, f.down', exists_and_distrib_left.symm, exists_swap, RelEmbedding.trans_apply,
        exists_eq_right'] <;>
      rfl⟩

@[simp]
theorem lt_le_apply (f : r ≺i s) (g : s ≼i t) (a : α) : (f.ltLe g) a = g (f a) :=
  RelEmbedding.trans_apply _ _ _

@[simp]
theorem lt_le_top (f : r ≺i s) (g : s ≼i t) : (f.ltLe g).top = g f.top :=
  rfl

/-- Composition of two principal segments as a principal segment -/
@[trans]
protected def trans [IsTrans γ t] (f : r ≺i s) (g : s ≺i t) : r ≺i t :=
  ltLe f g

@[simp]
theorem trans_apply [IsTrans γ t] (f : r ≺i s) (g : s ≺i t) (a : α) : (f.trans g) a = g (f a) :=
  lt_le_apply _ _ _

@[simp]
theorem trans_top [IsTrans γ t] (f : r ≺i s) (g : s ≺i t) : (f.trans g).top = g f.top :=
  rfl

/-- Composition of an order isomorphism with a principal segment, as a principal segment -/
def equivLt (f : r ≃r s) (g : s ≺i t) : r ≺i t :=
  ⟨@RelEmbedding.trans _ _ _ r s t f g, g.top, fun c =>
    suffices (∃ a : β, g a = c) ↔ ∃ a : α, g (f a) = c by
      simpa [g.down]
    ⟨fun ⟨b, h⟩ =>
      ⟨f.symm b, by
        simp only [h, RelIso.apply_symm_apply, RelIso.coe_coe_fn]⟩,
      fun ⟨a, h⟩ => ⟨f a, h⟩⟩⟩

/-- Composition of a principal segment with an order isomorphism, as a principal segment -/
def ltEquiv {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop} (f : PrincipalSeg r s) (g : s ≃r t) :
    PrincipalSeg r t :=
  ⟨@RelEmbedding.trans _ _ _ r s t f g, g f.top, by
    intro x
    rw [← g.apply_symm_apply x, g.map_rel_iff, f.down', exists_congr]
    intro y
    exact ⟨congr_argₓ g, fun h => g.to_equiv.bijective.1 h⟩⟩

@[simp]
theorem equiv_lt_apply (f : r ≃r s) (g : s ≺i t) (a : α) : (equivLt f g) a = g (f a) :=
  RelEmbedding.trans_apply _ _ _

@[simp]
theorem equiv_lt_top (f : r ≃r s) (g : s ≺i t) : (equivLt f g).top = g.top :=
  rfl

/-- Given a well order `s`, there is a most one principal segment embedding of `r` into `s`. -/
instance [IsWellOrder β s] : Subsingleton (r ≺i s) :=
  ⟨fun f g => by
    have ef : (f : α → β) = g := by
      show ((f : r ≼i s) : α → β) = g
      rw [@Subsingleton.elim _ _ (f : r ≼i s) g]
      rfl
    have et : f.top = g.top := by
      refine' extensional_of_trichotomous_of_irrefl s fun x => _
      simp only [f.down, g.down, ef, coe_fn_to_rel_embedding]
    cases f
    cases g
    have := RelEmbedding.coe_fn_injective ef <;> congr⟩

theorem top_eq [IsWellOrder γ t] (e : r ≃r s) (f : r ≺i t) (g : s ≺i t) : f.top = g.top := by
  rw [Subsingleton.elim f (PrincipalSeg.equivLt e g)] <;> rfl

theorem top_lt_top {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop} [IsWellOrder γ t] (f : PrincipalSeg r s)
    (g : PrincipalSeg s t) (h : PrincipalSeg r t) : t h.top g.top := by
  rw [Subsingleton.elim h (f.trans g)]
  apply PrincipalSeg.lt_top

/-- Any element of a well order yields a principal segment -/
def ofElement {α : Type _} (r : α → α → Prop) (a : α) : Subrel r { b | r b a } ≺i r :=
  ⟨Subrel.relEmbedding _ _, a, fun b => ⟨fun h => ⟨⟨_, h⟩, rfl⟩, fun ⟨⟨_, h⟩, rfl⟩ => h⟩⟩

@[simp]
theorem of_element_apply {α : Type _} (r : α → α → Prop) (a : α) (b) : ofElement r a b = b.1 :=
  rfl

@[simp]
theorem of_element_top {α : Type _} (r : α → α → Prop) (a : α) : (ofElement r a).top = a :=
  rfl

/-- Restrict the codomain of a principal segment -/
def codRestrict (p : Set β) (f : r ≺i s) (H : ∀ a, f a ∈ p) (H₂ : f.top ∈ p) : r ≺i Subrel s p :=
  ⟨RelEmbedding.codRestrict p f H, ⟨f.top, H₂⟩, fun ⟨b, h⟩ =>
    f.down.trans <| exists_congr fun a => show (⟨f a, H a⟩ : p).1 = _ ↔ _ from ⟨Subtype.eq, congr_argₓ _⟩⟩

@[simp]
theorem cod_restrict_apply (p) (f : r ≺i s) (H H₂ a) : codRestrict p f H H₂ a = ⟨f a, H a⟩ :=
  rfl

@[simp]
theorem cod_restrict_top (p) (f : r ≺i s) (H H₂) : (codRestrict p f H H₂).top = ⟨f.top, H₂⟩ :=
  rfl

/-- Principal segment from an empty type into a type with a minimal element. -/
def ofIsEmpty (r : α → α → Prop) [IsEmpty α] {b : β} (H : ∀ b', ¬s b' b) : r ≺i s :=
  { RelEmbedding.ofIsEmpty r s with top := b,
    down' := by
      simp [H] }

@[simp]
theorem of_is_empty_top (r : α → α → Prop) [IsEmpty α] {b : β} (H : ∀ b', ¬s b' b) : (ofIsEmpty r H).top = b :=
  rfl

/-- Principal segment from the empty relation on `pempty` to the empty relation on `punit`. -/
@[reducible]
def pemptyToPunit : @EmptyRelation Pempty ≺i @EmptyRelation PUnit :=
  (@ofIsEmpty _ _ EmptyRelation _ _ PUnit.unit) fun x => not_false

end PrincipalSeg

/-! ### Properties of initial and principal segments -/


/-- To an initial segment taking values in a well order, one can associate either a principal
segment (if the range is not everything, hence one can take as top the minimum of the complement
of the range) or an order isomorphism (if the range is everything). -/
noncomputable def InitialSeg.ltOrEq [IsWellOrder β s] (f : r ≼i s) : Sum (r ≺i s) (r ≃r s) := by
  by_cases' h : surjective f
  · exact Sum.inr (RelIso.ofSurjective f h)
    
  · have h' : _ := (InitialSeg.eq_or_principal f).resolve_left h
    exact Sum.inl ⟨f, Classical.choose h', Classical.choose_spec h'⟩
    

theorem InitialSeg.lt_or_eq_apply_left [IsWellOrder β s] (f : r ≼i s) (g : r ≺i s) (a : α) : g a = f a :=
  @InitialSeg.eq α β r s _ g f a

theorem InitialSeg.lt_or_eq_apply_right [IsWellOrder β s] (f : r ≼i s) (g : r ≃r s) (a : α) : g a = f a :=
  InitialSeg.eq (InitialSeg.ofIso g) f a

/-- Composition of an initial segment taking values in a well order and a principal segment. -/
noncomputable def InitialSeg.leLt [IsWellOrder β s] [IsTrans γ t] (f : r ≼i s) (g : s ≺i t) : r ≺i t :=
  match f.lt_or_eq with
  | Sum.inl f' => f'.trans g
  | Sum.inr f' => PrincipalSeg.equivLt f' g

@[simp]
theorem InitialSeg.le_lt_apply [IsWellOrder β s] [IsTrans γ t] (f : r ≼i s) (g : s ≺i t) (a : α) :
    (f.leLt g) a = g (f a) := by
  delta' InitialSeg.leLt
  cases' h : f.lt_or_eq with f' f'
  · simp only [PrincipalSeg.trans_apply, f.lt_or_eq_apply_left]
    
  · simp only [PrincipalSeg.equiv_lt_apply, f.lt_or_eq_apply_right]
    

namespace RelEmbedding

/-- Given an order embedding into a well order, collapse the order embedding by filling the
gaps, to obtain an initial segment. Here, we construct the collapsed order embedding pointwise,
but the proof of the fact that it is an initial segment will be given in `collapse`. -/
noncomputable def collapseF [IsWellOrder β s] (f : r ↪r s) : ∀ a, { b // ¬s (f a) b } :=
  (RelEmbedding.well_founded f <| IsWellFounded.wf).fix fun a IH => by
    let S := { b | ∀ a h, s (IH a h).1 b }
    have : f a ∈ S := fun a' h =>
      ((trichotomous _ _).resolve_left fun h' => (IH a' h).2 <| trans (f.map_rel_iff.2 h) h').resolve_left fun h' =>
        (IH a' h).2 <| h' ▸ f.map_rel_iff.2 h
    exact ⟨is_well_founded.wf.min S ⟨_, this⟩, is_well_founded.wf.not_lt_min _ _ this⟩

theorem collapseF.lt [IsWellOrder β s] (f : r ↪r s) {a : α} : ∀ {a'}, r a' a → s (collapseF f a').1 (collapseF f a).1 :=
  show (collapseF f a).1 ∈ { b | ∀ (a') (h : r a' a), s (collapseF f a').1 b } by
    unfold collapse_F
    rw [WellFounded.fix_eq]
    apply WellFounded.min_mem _ _

theorem collapseF.not_lt [IsWellOrder β s] (f : r ↪r s) (a : α) {b} (h : ∀ (a') (h : r a' a), s (collapseF f a').1 b) :
    ¬s b (collapseF f a).1 := by
  unfold collapse_F
  rw [WellFounded.fix_eq]
  exact WellFounded.not_lt_min _ _ _ (show b ∈ { b | ∀ (a') (h : r a' a), s (collapse_F f a').1 b } from h)

/-- Construct an initial segment from an order embedding into a well order, by collapsing it
to fill the gaps. -/
noncomputable def collapse [IsWellOrder β s] (f : r ↪r s) : r ≼i s :=
  haveI := RelEmbedding.is_well_order f
  ⟨RelEmbedding.ofMonotone (fun a => (collapse_F f a).1) fun a b => collapse_F.lt f, fun a b =>
    Acc.recOnₓ (is_well_founded.wf.apply b : Acc s b)
      (fun b H IH a h => by
        let S := { a | ¬s (collapse_F f a).1 b }
        have : S.nonempty := ⟨_, asymm h⟩
        exists (IsWellFounded.wf : WellFounded r).min S this
        refine' ((@trichotomous _ s _ _ _).resolve_left _).resolve_right _
        · exact (IsWellFounded.wf : WellFounded r).min_mem S this
          
        · refine' collapse_F.not_lt f _ fun a' h' => _
          by_contra hn
          exact is_well_founded.wf.not_lt_min S this hn h'
          )
      a⟩

theorem collapse_apply [IsWellOrder β s] (f : r ↪r s) (a) : collapse f a = (collapseF f a).1 :=
  rfl

end RelEmbedding

