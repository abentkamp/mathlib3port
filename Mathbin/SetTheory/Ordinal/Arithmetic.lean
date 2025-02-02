/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Floris van Doorn, Violeta Hernández Palacios
-/
import Mathbin.SetTheory.Ordinal.Basic
import Mathbin.Tactic.ByContra

/-!
# Ordinal arithmetic

Ordinals have an addition (corresponding to disjoint union) that turns them into an additive
monoid, and a multiplication (corresponding to the lexicographic order on the product) that turns
them into a monoid. One can also define correspondingly a subtraction, a division, a successor
function, a power function and a logarithm function.

We also define limit ordinals and prove the basic induction principle on ordinals separating
successor ordinals and limit ordinals, in `limit_rec_on`.

## Main definitions and results

* `o₁ + o₂` is the order on the disjoint union of `o₁` and `o₂` obtained by declaring that
  every element of `o₁` is smaller than every element of `o₂`.
* `o₁ - o₂` is the unique ordinal `o` such that `o₂ + o = o₁`, when `o₂ ≤ o₁`.
* `o₁ * o₂` is the lexicographic order on `o₂ × o₁`.
* `o₁ / o₂` is the ordinal `o` such that `o₁ = o₂ * o + o'` with `o' < o₂`. We also define the
  divisibility predicate, and a modulo operation.
* `order.succ o = o + 1` is the successor of `o`.
* `pred o` if the predecessor of `o`. If `o` is not a successor, we set `pred o = o`.

We also define the power function and the logarithm function on ordinals, and discuss the properties
of casts of natural numbers of and of `ω` with respect to these operations.

Some properties of the operations are also used to discuss general tools on ordinals:

* `is_limit o`: an ordinal is a limit ordinal if it is neither `0` nor a successor.
* `limit_rec_on` is the main induction principle of ordinals: if one can prove a property by
  induction at successor ordinals and at limit ordinals, then it holds for all ordinals.
* `is_normal`: a function `f : ordinal → ordinal` satisfies `is_normal` if it is strictly increasing
  and order-continuous, i.e., the image `f o` of a limit ordinal `o` is the sup of `f a` for
  `a < o`.
* `enum_ord`: enumerates an unbounded set of ordinals by the ordinals themselves.
* `sup`, `lsub`: the supremum / least strict upper bound of an indexed family of ordinals in
  `Type u`, as an ordinal in `Type u`.
* `bsup`, `blsub`: the supremum / least strict upper bound of a set of ordinals indexed by ordinals
  less than a given ordinal `o`.

Various other basic arithmetic results are given in `principal.lean` instead.
-/


noncomputable section

open Function Cardinal Set Equivₓ Order

open Classical Cardinal Ordinal

universe u v w

variable {α : Type _} {β : Type _} {γ : Type _} {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

namespace Ordinal

/-! ### Further properties of addition on ordinals -/


@[simp]
theorem lift_add (a b) : lift (a + b) = lift a + lift b :=
  (Quotientₓ.induction_on₂ a b) fun ⟨α, r, _⟩ ⟨β, s, _⟩ =>
    Quotientₓ.sound
      ⟨(RelIso.preimage Equivₓ.ulift _).trans
          (RelIso.sumLexCongr (RelIso.preimage Equivₓ.ulift _) (RelIso.preimage Equivₓ.ulift _)).symm⟩

@[simp]
theorem lift_succ (a) : lift (succ a) = succ (lift a) := by
  rw [← add_one_eq_succ, lift_add, lift_one]
  rfl

instance add_contravariant_class_le : ContravariantClass Ordinal.{u} Ordinal.{u} (· + ·) (· ≤ ·) :=
  ⟨fun a b c =>
    (induction_on a) fun α r hr =>
      (induction_on b) fun β₁ s₁ hs₁ =>
        (induction_on c) fun β₂ s₂ hs₂ ⟨f⟩ =>
          ⟨have fl : ∀ a, f (Sum.inl a) = Sum.inl a := fun a => by
              simpa only [InitialSeg.trans_apply, InitialSeg.le_add_apply] using
                @InitialSeg.eq _ _ _ _ (@Sum.Lex.is_well_order _ _ _ _ hr hs₂) ((InitialSeg.leAdd r s₁).trans f)
                  (InitialSeg.leAdd r s₂) a
            have : ∀ b, { b' // f (Sum.inr b) = Sum.inr b' } := by
              intro b
              cases e : f (Sum.inr b)
              · rw [← fl] at e
                have := f.inj' e
                contradiction
                
              · exact ⟨_, rfl⟩
                
            let g (b) := (this b).1
            have fr : ∀ b, f (Sum.inr b) = Sum.inr (g b) := fun b => (this b).2
            ⟨⟨⟨g, fun x y h => by
                  injection
                    f.inj'
                      (by
                        rw [fr, fr, h] : f (Sum.inr x) = f (Sum.inr y))⟩,
                fun a b => by
                simpa only [Sum.lex_inr_inr, fr, RelEmbedding.coe_fn_to_embedding, InitialSeg.coe_fn_to_rel_embedding,
                  embedding.coe_fn_mk] using
                  @RelEmbedding.map_rel_iff _ _ _ _ f.to_rel_embedding (Sum.inr a) (Sum.inr b)⟩,
              fun a b H => by
              rcases f.init'
                  (by
                    rw [fr] <;> exact Sum.lex_inr_inr.2 H) with
                ⟨a' | a', h⟩
              · rw [fl] at h
                cases h
                
              · rw [fr] at h
                exact ⟨a', Sum.inr.injₓ h⟩
                ⟩⟩⟩

theorem add_succ (o₁ o₂ : Ordinal) : o₁ + succ o₂ = succ (o₁ + o₂) :=
  (add_assocₓ _ _ _).symm

@[simp]
theorem succ_zero : succ (0 : Ordinal) = 1 :=
  zero_addₓ 1

@[simp]
theorem succ_one : succ (1 : Ordinal) = 2 :=
  rfl

theorem one_le_iff_pos {o : Ordinal} : 1 ≤ o ↔ 0 < o := by
  rw [← succ_zero, succ_le_iff]

theorem one_le_iff_ne_zero {o : Ordinal} : 1 ≤ o ↔ o ≠ 0 := by
  rw [one_le_iff_pos, Ordinal.pos_iff_ne_zero]

theorem succ_pos (o : Ordinal) : 0 < succ o :=
  (Ordinal.zero_le o).trans_lt (lt_succ o)

theorem succ_ne_zero (o : Ordinal) : succ o ≠ 0 :=
  ne_of_gtₓ <| succ_pos o

@[simp]
theorem card_succ (o : Ordinal) : card (succ o) = card o + 1 := by
  simp only [← add_one_eq_succ, card_add, card_one]

theorem nat_cast_succ (n : ℕ) : ↑n.succ = succ (n : Ordinal) :=
  rfl

theorem add_left_cancel (a) {b c : Ordinal} : a + b = a + c ↔ b = c := by
  simp only [le_antisymm_iffₓ, add_le_add_iff_left]

theorem lt_one_iff_zero {a : Ordinal} : a < 1 ↔ a = 0 := by
  simpa using @lt_succ_bot_iff _ _ _ a _ _

private theorem add_lt_add_iff_left' (a) {b c : Ordinal} : a + b < a + c ↔ b < c := by
  rw [← not_leₓ, ← not_leₓ, add_le_add_iff_left]

instance add_covariant_class_lt : CovariantClass Ordinal.{u} Ordinal.{u} (· + ·) (· < ·) :=
  ⟨fun a b c => (add_lt_add_iff_left' a).2⟩

instance add_contravariant_class_lt : ContravariantClass Ordinal.{u} Ordinal.{u} (· + ·) (· < ·) :=
  ⟨fun a b c => (add_lt_add_iff_left' a).1⟩

instance add_swap_contravariant_class_lt : ContravariantClass Ordinal.{u} Ordinal.{u} (swap (· + ·)) (· < ·) :=
  ⟨fun a b c => lt_imp_lt_of_le_imp_leₓ fun h => add_le_add_right h _⟩

theorem add_le_add_iff_right {a b : Ordinal} : ∀ n : ℕ, a + n ≤ b + n ↔ a ≤ b
  | 0 => by
    simp
  | n + 1 => by
    rw [nat_cast_succ, add_succ, add_succ, succ_le_succ_iff, add_le_add_iff_right]

theorem add_right_cancel {a b : Ordinal} (n : ℕ) : a + n = b + n ↔ a = b := by
  simp only [le_antisymm_iffₓ, add_le_add_iff_right]

/-! ### The zero ordinal -/


@[simp]
theorem card_eq_zero {o} : card o = 0 ↔ o = 0 :=
  ⟨(induction_on o) fun α r _ h => by
      refine' le_antisymmₓ (le_of_not_ltₓ fun hn => mk_ne_zero_iff.2 _ h) (Ordinal.zero_le _)
      rw [← succ_le_iff, succ_zero] at hn
      cases' hn with f
      exact ⟨f PUnit.unit⟩,
    fun e => by
    simp only [e, card_zero]⟩

protected theorem one_ne_zero : (1 : Ordinal) ≠ 0 :=
  type_ne_zero_of_nonempty _

instance : Nontrivial Ordinal.{u} :=
  ⟨⟨1, 0, Ordinal.one_ne_zero⟩⟩

@[simp]
theorem zero_lt_one : (0 : Ordinal) < 1 :=
  lt_iff_le_and_neₓ.2 ⟨Ordinal.zero_le _, Ordinal.one_ne_zero.symm⟩

instance uniqueIioOne : Unique (Iio (1 : Ordinal)) where
  default := ⟨0, zero_lt_one⟩
  uniq := fun a => Subtype.ext <| lt_one_iff_zero.1 a.Prop

instance : ZeroLeOneClass Ordinal :=
  ⟨zero_lt_one.le⟩

instance uniqueOutOne : Unique (1 : Ordinal).out.α where
  default :=
    enum (· < ·) 0
      (by
        simp )
  uniq := fun a => by
    rw [← enum_typein (· < ·) a]
    unfold default
    congr
    rw [← lt_one_iff_zero]
    apply typein_lt_self

theorem one_out_eq (x : (1 : Ordinal).out.α) :
    x =
      enum (· < ·) 0
        (by
          simp ) :=
  Unique.eq_default x

@[simp]
theorem typein_one_out (x : (1 : Ordinal).out.α) : typein (· < ·) x = 0 := by
  rw [one_out_eq x, typein_enum]

theorem le_one_iff {a : Ordinal} : a ≤ 1 ↔ a = 0 ∨ a = 1 := by
  simpa using @le_succ_bot_iff _ _ _ a _

theorem add_eq_zero_iff {a b : Ordinal} : a + b = 0 ↔ a = 0 ∧ b = 0 :=
  (induction_on a) fun α r _ =>
    (induction_on b) fun β s _ => by
      simp_rw [← type_sum_lex, type_eq_zero_iff_is_empty]
      exact is_empty_sum

theorem left_eq_zero_of_add_eq_zero {a b : Ordinal} (h : a + b = 0) : a = 0 :=
  (add_eq_zero_iff.1 h).1

theorem right_eq_zero_of_add_eq_zero {a b : Ordinal} (h : a + b = 0) : b = 0 :=
  (add_eq_zero_iff.1 h).2

/-! ### The predecessor of an ordinal -/


/-- The ordinal predecessor of `o` is `o'` if `o = succ o'`,
  and `o` otherwise. -/
def pred (o : Ordinal) : Ordinal :=
  if h : ∃ a, o = succ a then Classical.choose h else o

@[simp]
theorem pred_succ (o) : pred (succ o) = o := by
  have h : ∃ a, succ o = succ a := ⟨_, rfl⟩ <;>
    simpa only [pred, dif_pos h] using (succ_injective <| Classical.choose_spec h).symm

theorem pred_le_self (o) : pred o ≤ o :=
  if h : ∃ a, o = succ a then by
    let ⟨a, e⟩ := h
    rw [e, pred_succ] <;> exact le_succ a
  else by
    rw [pred, dif_neg h]

theorem pred_eq_iff_not_succ {o} : pred o = o ↔ ¬∃ a, o = succ a :=
  ⟨fun e ⟨a, e'⟩ => by
    rw [e', pred_succ] at e <;> exact (lt_succ a).Ne e, fun h => dif_neg h⟩

theorem pred_eq_iff_not_succ' {o} : pred o = o ↔ ∀ a, o ≠ succ a := by
  simpa using pred_eq_iff_not_succ

theorem pred_lt_iff_is_succ {o} : pred o < o ↔ ∃ a, o = succ a :=
  Iff.trans
    (by
      simp only [le_antisymm_iffₓ, pred_le_self, true_andₓ, not_leₓ])
    (iff_not_comm.1 pred_eq_iff_not_succ).symm

@[simp]
theorem pred_zero : pred 0 = 0 :=
  pred_eq_iff_not_succ'.2 fun a => (succ_ne_zero a).symm

theorem succ_pred_iff_is_succ {o} : succ (pred o) = o ↔ ∃ a, o = succ a :=
  ⟨fun e => ⟨_, e.symm⟩, fun ⟨a, e⟩ => by
    simp only [e, pred_succ]⟩

theorem succ_lt_of_not_succ {o b : Ordinal} (h : ¬∃ a, o = succ a) : succ b < o ↔ b < o :=
  ⟨(lt_succ b).trans, fun l => lt_of_le_of_neₓ (succ_le_of_lt l) fun e => h ⟨_, e.symm⟩⟩

theorem lt_pred {a b} : a < pred b ↔ succ a < b :=
  if h : ∃ a, b = succ a then by
    let ⟨c, e⟩ := h
    rw [e, pred_succ, succ_lt_succ_iff]
  else by
    simp only [pred, dif_neg h, succ_lt_of_not_succ h]

theorem pred_le {a b} : pred a ≤ b ↔ a ≤ succ b :=
  le_iff_le_iff_lt_iff_ltₓ.2 lt_pred

@[simp]
theorem lift_is_succ {o} : (∃ a, lift o = succ a) ↔ ∃ a, o = succ a :=
  ⟨fun ⟨a, h⟩ =>
    let ⟨b, e⟩ := lift_down <| show a ≤ lift o from le_of_ltₓ <| h.symm ▸ lt_succ a
    ⟨b,
      lift_inj.1 <| by
        rw [h, ← e, lift_succ]⟩,
    fun ⟨a, h⟩ =>
    ⟨lift a, by
      simp only [h, lift_succ]⟩⟩

@[simp]
theorem lift_pred (o) : lift (pred o) = pred (lift o) :=
  if h : ∃ a, o = succ a then by
    cases' h with a e <;> simp only [e, pred_succ, lift_succ]
  else by
    rw [pred_eq_iff_not_succ.2 h, pred_eq_iff_not_succ.2 (mt lift_is_succ.1 h)]

/-! ### Limit ordinals -/


/-- A limit ordinal is an ordinal which is not zero and not a successor. -/
def IsLimit (o : Ordinal) : Prop :=
  o ≠ 0 ∧ ∀ a < o, succ a < o

theorem IsLimit.succ_lt {o a : Ordinal} (h : IsLimit o) : a < o → succ a < o :=
  h.2 a

theorem not_zero_is_limit : ¬IsLimit 0
  | ⟨h, _⟩ => h rfl

theorem not_succ_is_limit (o) : ¬IsLimit (succ o)
  | ⟨_, h⟩ => lt_irreflₓ _ (h _ (lt_succ o))

theorem not_succ_of_is_limit {o} (h : IsLimit o) : ¬∃ a, o = succ a
  | ⟨a, e⟩ => not_succ_is_limit a (e ▸ h)

theorem succ_lt_of_is_limit {o a : Ordinal} (h : IsLimit o) : succ a < o ↔ a < o :=
  ⟨(lt_succ a).trans, h.2 _⟩

theorem le_succ_of_is_limit {o} (h : IsLimit o) {a} : o ≤ succ a ↔ o ≤ a :=
  le_iff_le_iff_lt_iff_ltₓ.2 <| succ_lt_of_is_limit h

theorem limit_le {o} (h : IsLimit o) {a} : o ≤ a ↔ ∀ x < o, x ≤ a :=
  ⟨fun h x l => l.le.trans h, fun H =>
    (le_succ_of_is_limit h).1 <| le_of_not_ltₓ fun hn => not_lt_of_leₓ (H _ hn) (lt_succ a)⟩

theorem lt_limit {o} (h : IsLimit o) {a} : a < o ↔ ∃ x < o, a < x := by
  simpa only [not_ball, not_leₓ] using not_congr (@limit_le _ h a)

@[simp]
theorem lift_is_limit (o) : IsLimit (lift o) ↔ IsLimit o :=
  and_congr
    (not_congr <| by
      simpa only [lift_zero] using @lift_inj o 0)
    ⟨fun H a h =>
      lift_lt.1 <| by
        simpa only [lift_succ] using H _ (lift_lt.2 h),
      fun H a h => by
      obtain ⟨a', rfl⟩ := lift_down h.le
      rw [← lift_succ, lift_lt]
      exact H a' (lift_lt.1 h)⟩

theorem IsLimit.pos {o : Ordinal} (h : IsLimit o) : 0 < o :=
  lt_of_le_of_neₓ (Ordinal.zero_le _) h.1.symm

theorem IsLimit.one_lt {o : Ordinal} (h : IsLimit o) : 1 < o := by
  simpa only [succ_zero] using h.2 _ h.pos

theorem IsLimit.nat_lt {o : Ordinal} (h : IsLimit o) : ∀ n : ℕ, (n : Ordinal) < o
  | 0 => h.Pos
  | n + 1 => h.2 _ (is_limit.nat_lt n)

theorem zero_or_succ_or_limit (o : Ordinal) : o = 0 ∨ (∃ a, o = succ a) ∨ IsLimit o :=
  if o0 : o = 0 then Or.inl o0
  else if h : ∃ a, o = succ a then Or.inr (Or.inl h) else Or.inr <| Or.inr ⟨o0, fun a => (succ_lt_of_not_succ h).2⟩

/-- Main induction principle of ordinals: if one can prove a property by
  induction at successor ordinals and at limit ordinals, then it holds for all ordinals. -/
@[elabAsElim]
def limitRecOn {C : Ordinal → Sort _} (o : Ordinal) (H₁ : C 0) (H₂ : ∀ o, C o → C (succ o))
    (H₃ : ∀ o, IsLimit o → (∀ o' < o, C o') → C o) : C o :=
  lt_wf.fix
    (fun o IH =>
      if o0 : o = 0 then by
        rw [o0] <;> exact H₁
      else
        if h : ∃ a, o = succ a then by
          rw [← succ_pred_iff_is_succ.2 h] <;> exact H₂ _ (IH _ <| pred_lt_iff_is_succ.2 h)
        else H₃ _ ⟨o0, fun a => (succ_lt_of_not_succ h).2⟩ IH)
    o

@[simp]
theorem limit_rec_on_zero {C} (H₁ H₂ H₃) : @limitRecOn C 0 H₁ H₂ H₃ = H₁ := by
  rw [limit_rec_on, lt_wf.fix_eq, dif_pos rfl] <;> rfl

@[simp]
theorem limit_rec_on_succ {C} (o H₁ H₂ H₃) : @limitRecOn C (succ o) H₁ H₂ H₃ = H₂ o (@limitRecOn C o H₁ H₂ H₃) := by
  have h : ∃ a, succ o = succ a := ⟨_, rfl⟩
  rw [limit_rec_on, lt_wf.fix_eq, dif_neg (succ_ne_zero o), dif_pos h]
  generalize limit_rec_on._proof_2 (succ o) h = h₂
  generalize limit_rec_on._proof_3 (succ o) h = h₃
  revert h₂ h₃
  generalize e : pred (succ o) = o'
  intros
  rw [pred_succ] at e
  subst o'
  rfl

@[simp]
theorem limit_rec_on_limit {C} (o H₁ H₂ H₃ h) : @limitRecOn C o H₁ H₂ H₃ = H₃ o h fun x h => @limitRecOn C x H₁ H₂ H₃ :=
  by
  rw [limit_rec_on, lt_wf.fix_eq, dif_neg h.1, dif_neg (not_succ_of_is_limit h)] <;> rfl

instance orderTopOutSucc (o : Ordinal) : OrderTop (succ o).out.α :=
  ⟨_, le_enum_succ⟩

theorem enum_succ_eq_top {o : Ordinal} :
    enum (· < ·) o
        (by
          rw [type_lt]
          exact lt_succ o) =
      (⊤ : (succ o).out.α) :=
  rfl

theorem has_succ_of_type_succ_lt {α} {r : α → α → Prop} [wo : IsWellOrder α r] (h : ∀ a < type r, succ a < type r)
    (x : α) : ∃ y, r x y := by
  use enum r (succ (typein r x)) (h _ (typein_lt_type r x))
  convert (enum_lt_enum (typein_lt_type r x) _).mpr (lt_succ _)
  rw [enum_typein]

theorem out_no_max_of_succ_lt {o : Ordinal} (ho : ∀ a < o, succ a < o) : NoMaxOrder o.out.α :=
  ⟨has_succ_of_type_succ_lt
      (by
        rwa [type_lt])⟩

theorem bounded_singleton {r : α → α → Prop} [IsWellOrder α r] (hr : (type r).IsLimit) (x) : Bounded r {x} := by
  refine' ⟨enum r (succ (typein r x)) (hr.2 _ (typein_lt_type r x)), _⟩
  intro b hb
  rw [mem_singleton_iff.1 hb]
  nth_rw 0[← enum_typein r x]
  rw [@enum_lt_enum _ r]
  apply lt_succ

theorem type_subrel_lt (o : Ordinal.{u}) : type (Subrel (· < ·) { o' : Ordinal | o' < o }) = Ordinal.lift.{u + 1} o :=
  by
  refine' Quotientₓ.induction_on o _
  rintro ⟨α, r, wo⟩
  skip
  apply Quotientₓ.sound
  constructor
  symm
  refine' (RelIso.preimage Equivₓ.ulift r).trans (enum_iso r).symm

theorem mk_initial_seg (o : Ordinal.{u}) : # { o' : Ordinal | o' < o } = Cardinal.lift.{u + 1} o.card := by
  rw [lift_card, ← type_subrel_lt, card_type]

/-! ### Normal ordinal functions -/


/-- A normal ordinal function is a strictly increasing function which is
  order-continuous, i.e., the image `f o` of a limit ordinal `o` is the sup of `f a` for
  `a < o`.  -/
def IsNormal (f : Ordinal → Ordinal) : Prop :=
  (∀ o, f o < f (succ o)) ∧ ∀ o, IsLimit o → ∀ a, f o ≤ a ↔ ∀ b < o, f b ≤ a

theorem IsNormal.limit_le {f} (H : IsNormal f) : ∀ {o}, IsLimit o → ∀ {a}, f o ≤ a ↔ ∀ b < o, f b ≤ a :=
  H.2

theorem IsNormal.limit_lt {f} (H : IsNormal f) {o} (h : IsLimit o) {a} : a < f o ↔ ∃ b < o, a < f b :=
  not_iff_not.1 <| by
    simpa only [exists_prop, not_exists, not_and, not_ltₓ] using H.2 _ h a

theorem IsNormal.strict_mono {f} (H : IsNormal f) : StrictMono f := fun a b =>
  limitRecOn b (Not.elim (not_lt_of_leₓ <| Ordinal.zero_le _))
    (fun b IH h => (lt_or_eq_of_leₓ (le_of_lt_succ h)).elim (fun h => (IH h).trans (H.1 _)) fun e => e ▸ H.1 _)
    fun b l IH h => lt_of_lt_of_leₓ (H.1 a) ((H.2 _ l _).1 le_rflₓ _ (l.2 _ h))

theorem IsNormal.monotone {f} (H : IsNormal f) : Monotone f :=
  H.StrictMono.Monotone

theorem is_normal_iff_strict_mono_limit (f : Ordinal → Ordinal) :
    IsNormal f ↔ StrictMono f ∧ ∀ o, IsLimit o → ∀ a, (∀ b < o, f b ≤ a) → f o ≤ a :=
  ⟨fun hf => ⟨hf.StrictMono, fun a ha c => (hf.2 a ha c).2⟩, fun ⟨hs, hl⟩ =>
    ⟨fun a => hs (lt_succ a), fun a ha c => ⟨fun hac b hba => ((hs hba).trans_le hac).le, hl a ha c⟩⟩⟩

theorem IsNormal.lt_iff {f} (H : IsNormal f) {a b} : f a < f b ↔ a < b :=
  StrictMono.lt_iff_lt <| H.StrictMono

theorem IsNormal.le_iff {f} (H : IsNormal f) {a b} : f a ≤ f b ↔ a ≤ b :=
  le_iff_le_iff_lt_iff_ltₓ.2 H.lt_iff

theorem IsNormal.inj {f} (H : IsNormal f) {a b} : f a = f b ↔ a = b := by
  simp only [le_antisymm_iffₓ, H.le_iff]

theorem IsNormal.self_le {f} (H : IsNormal f) (a) : a ≤ f a :=
  lt_wf.self_le_of_strict_mono H.StrictMono a

theorem IsNormal.le_set {f o} (H : IsNormal f) (p : Set Ordinal) (p0 : p.Nonempty) (b)
    (H₂ : ∀ o, b ≤ o ↔ ∀ a ∈ p, a ≤ o) : f b ≤ o ↔ ∀ a ∈ p, f a ≤ o :=
  ⟨fun h a pa => (H.le_iff.2 ((H₂ _).1 le_rflₓ _ pa)).trans h, fun h => by
    revert H₂
    refine' limit_rec_on b (fun H₂ => _) (fun S _ H₂ => _) fun S L _ H₂ => (H.2 _ L _).2 fun a h' => _
    · cases' p0 with x px
      have := Ordinal.le_zero.1 ((H₂ _).1 (Ordinal.zero_le _) _ px)
      rw [this] at px
      exact h _ px
      
    · rcases not_ball.1 (mt (H₂ S).2 <| (lt_succ S).not_le) with ⟨a, h₁, h₂⟩
      exact (H.le_iff.2 <| succ_le_of_lt <| not_leₓ.1 h₂).trans (h _ h₁)
      
    · rcases not_ball.1 (mt (H₂ a).2 h'.not_le) with ⟨b, h₁, h₂⟩
      exact (H.le_iff.2 <| (not_leₓ.1 h₂).le).trans (h _ h₁)
      ⟩

theorem IsNormal.le_set' {f o} (H : IsNormal f) (p : Set α) (p0 : p.Nonempty) (g : α → Ordinal) (b)
    (H₂ : ∀ o, b ≤ o ↔ ∀ a ∈ p, g a ≤ o) : f b ≤ o ↔ ∀ a ∈ p, f (g a) ≤ o := by
  simpa [H₂] using H.le_set (g '' p) (p0.image g) b

theorem IsNormal.refl : IsNormal id :=
  ⟨lt_succ, fun o l a => limit_le l⟩

theorem IsNormal.trans {f g} (H₁ : IsNormal f) (H₂ : IsNormal g) : IsNormal (f ∘ g) :=
  ⟨fun x => H₁.lt_iff.2 (H₂.1 _), fun o l a => H₁.le_set' (· < o) ⟨_, l.Pos⟩ g _ fun c => H₂.2 _ l _⟩

theorem IsNormal.is_limit {f} (H : IsNormal f) {o} (l : IsLimit o) : IsLimit (f o) :=
  ⟨ne_of_gtₓ <| (Ordinal.zero_le _).trans_lt <| H.lt_iff.2 l.Pos, fun a h =>
    let ⟨b, h₁, h₂⟩ := (H.limit_lt l).1 h
    (succ_le_of_lt h₂).trans_lt (H.lt_iff.2 h₁)⟩

theorem IsNormal.le_iff_eq {f} (H : IsNormal f) {a} : f a ≤ a ↔ f a = a :=
  (H.self_le a).le_iff_eq

theorem add_le_of_limit {a b c : Ordinal} (h : IsLimit b) : a + b ≤ c ↔ ∀ b' < b, a + b' ≤ c :=
  ⟨fun h b' l => (add_le_add_left l.le _).trans h, fun H =>
    le_of_not_ltₓ <|
      induction_on a
        (fun α r _ =>
          (induction_on b) fun β s _ h H l => by
            skip
            suffices ∀ x : β, Sum.Lex r s (Sum.inr x) (enum _ _ l) by
              cases' enum _ _ l with x x
              · cases this (enum s 0 h.pos)
                
              · exact irrefl _ (this _)
                
            intro x
            rw [← typein_lt_typein (Sum.Lex r s), typein_enum]
            have := H _ (h.2 _ (typein_lt_type s x))
            rw [add_succ, succ_le_iff] at this
            refine' (RelEmbedding.ofMonotone (fun a => _) fun a b => _).ordinal_type_le.trans_lt this
            · rcases a with ⟨a | b, h⟩
              · exact Sum.inl a
                
              · exact
                  Sum.inr
                    ⟨b, by
                      cases h <;> assumption⟩
                
              
            · rcases a with ⟨a | a, h₁⟩ <;>
                rcases b with ⟨b | b, h₂⟩ <;> cases h₁ <;> cases h₂ <;> rintro ⟨⟩ <;> constructor <;> assumption
              )
        h H⟩

theorem add_is_normal (a : Ordinal) : IsNormal ((· + ·) a) :=
  ⟨fun b => (add_lt_add_iff_left a).2 (lt_succ b), fun b l c => add_le_of_limit l⟩

theorem add_is_limit (a) {b} : IsLimit b → IsLimit (a + b) :=
  (add_is_normal a).IsLimit

alias add_is_limit ← is_limit.add

/-! ### Subtraction on ordinals-/


/-- The set in the definition of subtraction is nonempty. -/
theorem sub_nonempty {a b : Ordinal} : { o | a ≤ b + o }.Nonempty :=
  ⟨a, le_add_left _ _⟩

/-- `a - b` is the unique ordinal satisfying `b + (a - b) = a` when `b ≤ a`. -/
instance : Sub Ordinal :=
  ⟨fun a b => inf { o | a ≤ b + o }⟩

theorem le_add_sub (a b : Ordinal) : a ≤ b + (a - b) :=
  Inf_mem sub_nonempty

theorem sub_le {a b c : Ordinal} : a - b ≤ c ↔ a ≤ b + c :=
  ⟨fun h => (le_add_sub a b).trans (add_le_add_left h _), fun h => cInf_le' h⟩

theorem lt_sub {a b c : Ordinal} : a < b - c ↔ c + a < b :=
  lt_iff_lt_of_le_iff_leₓ sub_le

theorem add_sub_cancel (a b : Ordinal) : a + b - a = b :=
  le_antisymmₓ (sub_le.2 <| le_rflₓ) ((add_le_add_iff_left a).1 <| le_add_sub _ _)

theorem sub_eq_of_add_eq {a b c : Ordinal} (h : a + b = c) : c - a = b :=
  h ▸ add_sub_cancel _ _

theorem sub_le_self (a b : Ordinal) : a - b ≤ a :=
  sub_le.2 <| le_add_left _ _

protected theorem add_sub_cancel_of_le {a b : Ordinal} (h : b ≤ a) : b + (a - b) = a :=
  (le_add_sub a b).antisymm'
    (by
      rcases zero_or_succ_or_limit (a - b) with (e | ⟨c, e⟩ | l)
      · simp only [e, add_zeroₓ, h]
        
      · rw [e, add_succ, succ_le_iff, ← lt_sub, e]
        exact lt_succ c
        
      · exact (add_le_of_limit l).2 fun c l => (lt_sub.1 l).le
        )

theorem le_sub_of_le {a b c : Ordinal} (h : b ≤ a) : c ≤ a - b ↔ b + c ≤ a := by
  rw [← add_le_add_iff_left b, Ordinal.add_sub_cancel_of_le h]

theorem sub_lt_of_le {a b c : Ordinal} (h : b ≤ a) : a - b < c ↔ a < b + c :=
  lt_iff_lt_of_le_iff_leₓ (le_sub_of_le h)

instance : HasExistsAddOfLe Ordinal :=
  ⟨fun a b h => ⟨_, (Ordinal.add_sub_cancel_of_le h).symm⟩⟩

@[simp]
theorem sub_zero (a : Ordinal) : a - 0 = a := by
  simpa only [zero_addₓ] using add_sub_cancel 0 a

@[simp]
theorem zero_sub (a : Ordinal) : 0 - a = 0 := by
  rw [← Ordinal.le_zero] <;> apply sub_le_self

@[simp]
theorem sub_self (a : Ordinal) : a - a = 0 := by
  simpa only [add_zeroₓ] using add_sub_cancel a 0

protected theorem sub_eq_zero_iff_le {a b : Ordinal} : a - b = 0 ↔ a ≤ b :=
  ⟨fun h => by
    simpa only [h, add_zeroₓ] using le_add_sub a b, fun h => by
    rwa [← Ordinal.le_zero, sub_le, add_zeroₓ]⟩

theorem sub_sub (a b c : Ordinal) : a - b - c = a - (b + c) :=
  eq_of_forall_ge_iffₓ fun d => by
    rw [sub_le, sub_le, sub_le, add_assocₓ]

theorem add_sub_add_cancel (a b c : Ordinal) : a + b - (a + c) = b - c := by
  rw [← sub_sub, add_sub_cancel]

theorem sub_is_limit {a b} (l : IsLimit a) (h : b < a) : IsLimit (a - b) :=
  ⟨ne_of_gtₓ <|
      lt_sub.2 <| by
        rwa [add_zeroₓ],
    fun c h => by
    rw [lt_sub, add_succ] <;> exact l.2 _ (lt_sub.1 h)⟩

@[simp]
theorem one_add_omega : 1 + ω = ω := by
  refine' le_antisymmₓ _ (le_add_left _ _)
  rw [omega, ← lift_one.{0}, ← lift_add, lift_le, ← type_unit, ← type_sum_lex]
  refine' ⟨RelEmbedding.collapse (RelEmbedding.ofMonotone _ _)⟩
  · apply Sum.rec
    exact fun _ => 0
    exact Nat.succ
    
  · intro a b
    cases a <;>
      cases b <;> intro H <;> cases' H with _ _ H _ _ H <;> [cases H, exact Nat.succ_posₓ _, exact Nat.succ_lt_succₓ H]
    

@[simp]
theorem one_add_of_omega_le {o} (h : ω ≤ o) : 1 + o = o := by
  rw [← Ordinal.add_sub_cancel_of_le h, ← add_assocₓ, one_add_omega]

/-! ### Multiplication of ordinals-/


/-- The multiplication of ordinals `o₁` and `o₂` is the (well founded) lexicographic order on
`o₂ × o₁`. -/
instance : Monoidₓ Ordinal.{u} where
  mul := fun a b =>
    (Quotientₓ.liftOn₂ a b
        (fun ⟨α, r, wo⟩ ⟨β, s, wo'⟩ => ⟦⟨β × α, Prod.Lex s r, Prod.Lex.is_well_order⟩⟧ :
          WellOrder → WellOrder → Ordinal))
      fun ⟨α₁, r₁, o₁⟩ ⟨α₂, r₂, o₂⟩ ⟨β₁, s₁, p₁⟩ ⟨β₂, s₂, p₂⟩ ⟨f⟩ ⟨g⟩ => Quot.sound ⟨RelIso.prodLexCongr g f⟩
  one := 1
  mul_assoc := fun a b c =>
    (Quotientₓ.induction_on₃ a b c) fun ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ =>
      Eq.symm <|
        Quotientₓ.sound
          ⟨⟨prodAssoc _ _ _, fun a b => by
              rcases a with ⟨⟨a₁, a₂⟩, a₃⟩
              rcases b with ⟨⟨b₁, b₂⟩, b₃⟩
              simp [Prod.lex_defₓ, and_or_distrib_left, or_assoc, and_assoc]⟩⟩
  mul_one := fun a =>
    (induction_on a) fun α r _ =>
      Quotientₓ.sound
        ⟨⟨punitProd _, fun a b => by
            rcases a with ⟨⟨⟨⟩⟩, a⟩ <;>
              rcases b with ⟨⟨⟨⟩⟩, b⟩ <;>
                simp only [Prod.lex_defₓ, EmptyRelation, false_orₓ] <;>
                  simp only [eq_self_iff_true, true_andₓ] <;> rfl⟩⟩
  one_mul := fun a =>
    (induction_on a) fun α r _ =>
      Quotientₓ.sound
        ⟨⟨prodPunit _, fun a b => by
            rcases a with ⟨a, ⟨⟨⟩⟩⟩ <;>
              rcases b with ⟨b, ⟨⟨⟩⟩⟩ <;> simp only [Prod.lex_defₓ, EmptyRelation, and_falseₓ, or_falseₓ] <;> rfl⟩⟩

@[simp]
theorem type_prod_lex {α β : Type u} (r : α → α → Prop) (s : β → β → Prop) [IsWellOrder α r] [IsWellOrder β s] :
    type (Prod.Lex s r) = type r * type s :=
  rfl

private theorem mul_eq_zero' {a b : Ordinal} : a * b = 0 ↔ a = 0 ∨ b = 0 :=
  (induction_on a) fun α _ _ =>
    (induction_on b) fun β _ _ => by
      simp_rw [← type_prod_lex, type_eq_zero_iff_is_empty]
      rw [or_comm]
      exact is_empty_prod

instance : MonoidWithZeroₓ Ordinal :=
  { Ordinal.monoid with zero := 0, mul_zero := fun a => mul_eq_zero'.2 <| Or.inr rfl,
    zero_mul := fun a => mul_eq_zero'.2 <| Or.inl rfl }

instance : NoZeroDivisors Ordinal :=
  ⟨fun a b => mul_eq_zero'.1⟩

@[simp]
theorem lift_mul (a b) : lift (a * b) = lift a * lift b :=
  (Quotientₓ.induction_on₂ a b) fun ⟨α, r, _⟩ ⟨β, s, _⟩ =>
    Quotientₓ.sound
      ⟨(RelIso.preimage Equivₓ.ulift _).trans
          (RelIso.prodLexCongr (RelIso.preimage Equivₓ.ulift _) (RelIso.preimage Equivₓ.ulift _)).symm⟩

@[simp]
theorem card_mul (a b) : card (a * b) = card a * card b :=
  (Quotientₓ.induction_on₂ a b) fun ⟨α, r, _⟩ ⟨β, s, _⟩ => mul_comm (mk β) (mk α)

instance : LeftDistribClass Ordinal.{u} :=
  ⟨fun a b c =>
    (Quotientₓ.induction_on₃ a b c) fun ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ =>
      Quotientₓ.sound
        ⟨⟨sumProdDistrib _ _ _, by
            rintro ⟨a₁ | a₁, a₂⟩ ⟨b₁ | b₁, b₂⟩ <;>
              simp only [Prod.lex_defₓ, Sum.lex_inl_inl, Sum.Lex.sep, Sum.lex_inr_inl, Sum.lex_inr_inr,
                  sum_prod_distrib_apply_left, sum_prod_distrib_apply_right] <;>
                simp only [Sum.inl.inj_iff, true_orₓ, false_andₓ, false_orₓ]⟩⟩⟩

theorem mul_succ (a b : Ordinal) : a * succ b = a * b + a :=
  mul_add_one a b

instance mul_covariant_class_le : CovariantClass Ordinal.{u} Ordinal.{u} (· * ·) (· ≤ ·) :=
  ⟨fun c a b =>
    (Quotientₓ.induction_on₃ a b c) fun ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨f⟩ => by
      skip
      refine' (RelEmbedding.ofMonotone (fun a : α × γ => (f a.1, a.2)) fun a b h => _).ordinal_type_le
      clear_
      cases' h with a₁ b₁ a₂ b₂ h' a b₁ b₂ h'
      · exact Prod.Lex.left _ _ (f.to_rel_embedding.map_rel_iff.2 h')
        
      · exact Prod.Lex.right _ h'
        ⟩

instance mul_swap_covariant_class_le : CovariantClass Ordinal.{u} Ordinal.{u} (swap (· * ·)) (· ≤ ·) :=
  ⟨fun c a b =>
    (Quotientₓ.induction_on₃ a b c) fun ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨f⟩ => by
      skip
      refine' (RelEmbedding.ofMonotone (fun a : γ × α => (a.1, f a.2)) fun a b h => _).ordinal_type_le
      cases' h with a₁ b₁ a₂ b₂ h' a b₁ b₂ h'
      · exact Prod.Lex.left _ _ h'
        
      · exact Prod.Lex.right _ (f.to_rel_embedding.map_rel_iff.2 h')
        ⟩

theorem le_mul_left (a : Ordinal) {b : Ordinal} (hb : 0 < b) : a ≤ a * b := by
  convert mul_le_mul_left' (one_le_iff_pos.2 hb) a
  rw [mul_oneₓ a]

theorem le_mul_right (a : Ordinal) {b : Ordinal} (hb : 0 < b) : a ≤ b * a := by
  convert mul_le_mul_right' (one_le_iff_pos.2 hb) a
  rw [one_mulₓ a]

private theorem mul_le_of_limit_aux {α β r s} [IsWellOrder α r] [IsWellOrder β s] {c} (h : IsLimit (type s))
    (H : ∀ b' < type s, type r * b' ≤ c) (l : c < type r * type s) : False := by
  suffices ∀ a b, Prod.Lex s r (b, a) (enum _ _ l) by
    cases' enum _ _ l with b a
    exact irrefl _ (this _ _)
  intro a b
  rw [← typein_lt_typein (Prod.Lex s r), typein_enum]
  have := H _ (h.2 _ (typein_lt_type s b))
  rw [mul_succ] at this
  have := ((add_lt_add_iff_left _).2 (typein_lt_type _ a)).trans_le this
  refine' (RelEmbedding.ofMonotone (fun a => _) fun a b => _).ordinal_type_le.trans_lt this
  · rcases a with ⟨⟨b', a'⟩, h⟩
    by_cases' e : b = b'
    · refine' Sum.inr ⟨a', _⟩
      subst e
      cases' h with _ _ _ _ h _ _ _ h
      · exact (irrefl _ h).elim
        
      · exact h
        
      
    · refine' Sum.inl (⟨b', _⟩, a')
      cases' h with _ _ _ _ h _ _ _ h
      · exact h
        
      · exact (e rfl).elim
        
      
    
  · rcases a with ⟨⟨b₁, a₁⟩, h₁⟩
    rcases b with ⟨⟨b₂, a₂⟩, h₂⟩
    intro h
    by_cases' e₁ : b = b₁ <;> by_cases' e₂ : b = b₂
    · substs b₁ b₂
      simpa only [subrel_val, Prod.lex_defₓ, @irrefl _ s _ b, true_andₓ, false_orₓ, eq_self_iff_true, dif_pos,
        Sum.lex_inr_inr] using h
      
    · subst b₁
      simp only [subrel_val, Prod.lex_defₓ, e₂, Prod.lex_defₓ, dif_pos, subrel_val, eq_self_iff_true, or_falseₓ,
        dif_neg, not_false_iff, Sum.lex_inr_inl, false_andₓ] at h⊢
      cases h₂ <;> [exact asymm h h₂_h, exact e₂ rfl]
      
    · simp [e₂, dif_neg e₁,
        show b₂ ≠ b₁ by
          cc]
      
    · simpa only [dif_neg e₁, dif_neg e₂, Prod.lex_defₓ, subrel_val, Subtype.mk_eq_mk, Sum.lex_inl_inl] using h
      
    

theorem mul_le_of_limit {a b c : Ordinal} (h : IsLimit b) : a * b ≤ c ↔ ∀ b' < b, a * b' ≤ c :=
  ⟨fun h b' l => (mul_le_mul_left' l.le _).trans h, fun H =>
    le_of_not_ltₓ <| induction_on a (fun α r _ => (induction_on b) fun β s _ => mul_le_of_limit_aux) h H⟩

theorem mul_is_normal {a : Ordinal} (h : 0 < a) : IsNormal ((· * ·) a) :=
  ⟨fun b => by
    rw [mul_succ] <;> simpa only [add_zeroₓ] using (add_lt_add_iff_left (a * b)).2 h, fun b l c => mul_le_of_limit l⟩

theorem lt_mul_of_limit {a b c : Ordinal} (h : IsLimit c) : a < b * c ↔ ∃ c' < c, a < b * c' := by
  simpa only [not_ball, not_leₓ] using not_congr (@mul_le_of_limit b c a h)

theorem mul_lt_mul_iff_left {a b c : Ordinal} (a0 : 0 < a) : a * b < a * c ↔ b < c :=
  (mul_is_normal a0).lt_iff

theorem mul_le_mul_iff_left {a b c : Ordinal} (a0 : 0 < a) : a * b ≤ a * c ↔ b ≤ c :=
  (mul_is_normal a0).le_iff

theorem mul_lt_mul_of_pos_left {a b c : Ordinal} (h : a < b) (c0 : 0 < c) : c * a < c * b :=
  (mul_lt_mul_iff_left c0).2 h

theorem mul_pos {a b : Ordinal} (h₁ : 0 < a) (h₂ : 0 < b) : 0 < a * b := by
  simpa only [mul_zero] using mul_lt_mul_of_pos_left h₂ h₁

theorem mul_ne_zero {a b : Ordinal} : a ≠ 0 → b ≠ 0 → a * b ≠ 0 := by
  simpa only [Ordinal.pos_iff_ne_zero] using mul_pos

theorem le_of_mul_le_mul_left {a b c : Ordinal} (h : c * a ≤ c * b) (h0 : 0 < c) : a ≤ b :=
  le_imp_le_of_lt_imp_ltₓ (fun h' => mul_lt_mul_of_pos_left h' h0) h

theorem mul_right_inj {a b c : Ordinal} (a0 : 0 < a) : a * b = a * c ↔ b = c :=
  (mul_is_normal a0).inj

theorem mul_is_limit {a b : Ordinal} (a0 : 0 < a) : IsLimit b → IsLimit (a * b) :=
  (mul_is_normal a0).IsLimit

theorem mul_is_limit_left {a b : Ordinal} (l : IsLimit a) (b0 : 0 < b) : IsLimit (a * b) := by
  rcases zero_or_succ_or_limit b with (rfl | ⟨b, rfl⟩ | lb)
  · exact b0.false.elim
    
  · rw [mul_succ]
    exact add_is_limit _ l
    
  · exact mul_is_limit l.pos lb
    

theorem smul_eq_mul : ∀ (n : ℕ) (a : Ordinal), n • a = a * n
  | 0, a => by
    rw [zero_smul, Nat.cast_zeroₓ, mul_zero]
  | n + 1, a => by
    rw [succ_nsmul', Nat.cast_addₓ, mul_addₓ, Nat.cast_oneₓ, mul_oneₓ, smul_eq_mul]

/-! ### Division on ordinals -/


/-- The set in the definition of division is nonempty. -/
theorem div_nonempty {a b : Ordinal} (h : b ≠ 0) : { o | a < b * succ o }.Nonempty :=
  ⟨a,
    succ_le_iff.1 <| by
      simpa only [succ_zero, one_mulₓ] using mul_le_mul_right' (succ_le_of_lt (Ordinal.pos_iff_ne_zero.2 h)) (succ a)⟩

/-- `a / b` is the unique ordinal `o` satisfying `a = b * o + o'` with `o' < b`. -/
instance : Div Ordinal :=
  ⟨fun a b => if h : b = 0 then 0 else inf { o | a < b * succ o }⟩

@[simp]
theorem div_zero (a : Ordinal) : a / 0 = 0 :=
  dif_pos rfl

theorem div_def (a) {b : Ordinal} (h : b ≠ 0) : a / b = inf { o | a < b * succ o } :=
  dif_neg h

theorem lt_mul_succ_div (a) {b : Ordinal} (h : b ≠ 0) : a < b * succ (a / b) := by
  rw [div_def a h] <;> exact Inf_mem (div_nonempty h)

theorem lt_mul_div_add (a) {b : Ordinal} (h : b ≠ 0) : a < b * (a / b) + b := by
  simpa only [mul_succ] using lt_mul_succ_div a h

theorem div_le {a b c : Ordinal} (b0 : b ≠ 0) : a / b ≤ c ↔ a < b * succ c :=
  ⟨fun h => (lt_mul_succ_div a b0).trans_le (mul_le_mul_left' (succ_le_succ_iff.2 h) _), fun h => by
    rw [div_def a b0] <;> exact cInf_le' h⟩

theorem lt_div {a b c : Ordinal} (h : c ≠ 0) : a < b / c ↔ c * succ a ≤ b := by
  rw [← not_leₓ, div_le h, not_ltₓ]

theorem div_pos {b c : Ordinal} (h : c ≠ 0) : 0 < b / c ↔ c ≤ b := by
  simp [lt_div h]

theorem le_div {a b c : Ordinal} (c0 : c ≠ 0) : a ≤ b / c ↔ c * a ≤ b := by
  apply limit_rec_on a
  · simp only [mul_zero, Ordinal.zero_le]
    
  · intros
    rw [succ_le_iff, lt_div c0]
    
  · simp (config := { contextual := true })only [mul_le_of_limit, limit_le, iff_selfₓ, forall_true_iff]
    

theorem div_lt {a b c : Ordinal} (b0 : b ≠ 0) : a / b < c ↔ a < b * c :=
  lt_iff_lt_of_le_iff_leₓ <| le_div b0

theorem div_le_of_le_mul {a b c : Ordinal} (h : a ≤ b * c) : a / b ≤ c :=
  if b0 : b = 0 then by
    simp only [b0, div_zero, Ordinal.zero_le]
  else (div_le b0).2 <| h.trans_lt <| mul_lt_mul_of_pos_left (lt_succ c) (Ordinal.pos_iff_ne_zero.2 b0)

theorem mul_lt_of_lt_div {a b c : Ordinal} : a < b / c → c * a < b :=
  lt_imp_lt_of_le_imp_leₓ div_le_of_le_mul

@[simp]
theorem zero_div (a : Ordinal) : 0 / a = 0 :=
  Ordinal.le_zero.1 <| div_le_of_le_mul <| Ordinal.zero_le _

theorem mul_div_le (a b : Ordinal) : b * (a / b) ≤ a :=
  if b0 : b = 0 then by
    simp only [b0, zero_mul, Ordinal.zero_le]
  else (le_div b0).1 le_rflₓ

theorem mul_add_div (a) {b : Ordinal} (b0 : b ≠ 0) (c) : (b * a + c) / b = a + c / b := by
  apply le_antisymmₓ
  · apply (div_le b0).2
    rw [mul_succ, mul_addₓ, add_assocₓ, add_lt_add_iff_left]
    apply lt_mul_div_add _ b0
    
  · rw [le_div b0, mul_addₓ, add_le_add_iff_left]
    apply mul_div_le
    

theorem div_eq_zero_of_lt {a b : Ordinal} (h : a < b) : a / b = 0 := by
  rw [← Ordinal.le_zero, div_le <| Ordinal.pos_iff_ne_zero.1 <| (Ordinal.zero_le _).trans_lt h]
  simpa only [succ_zero, mul_oneₓ] using h

@[simp]
theorem mul_div_cancel (a) {b : Ordinal} (b0 : b ≠ 0) : b * a / b = a := by
  simpa only [add_zeroₓ, zero_div] using mul_add_div a b0 0

@[simp]
theorem div_one (a : Ordinal) : a / 1 = a := by
  simpa only [one_mulₓ] using mul_div_cancel a Ordinal.one_ne_zero

@[simp]
theorem div_self {a : Ordinal} (h : a ≠ 0) : a / a = 1 := by
  simpa only [mul_oneₓ] using mul_div_cancel 1 h

theorem mul_sub (a b c : Ordinal) : a * (b - c) = a * b - a * c :=
  if a0 : a = 0 then by
    simp only [a0, zero_mul, sub_self]
  else
    eq_of_forall_ge_iffₓ fun d => by
      rw [sub_le, ← le_div a0, sub_le, ← le_div a0, mul_add_div _ a0]

theorem is_limit_add_iff {a b} : IsLimit (a + b) ↔ IsLimit b ∨ b = 0 ∧ IsLimit a := by
  constructor <;> intro h
  · by_cases' h' : b = 0
    · rw [h', add_zeroₓ] at h
      right
      exact ⟨h', h⟩
      
    left
    rw [← add_sub_cancel a b]
    apply sub_is_limit h
    suffices : a + 0 < a + b
    simpa only [add_zeroₓ]
    rwa [add_lt_add_iff_left, Ordinal.pos_iff_ne_zero]
    
  rcases h with (h | ⟨rfl, h⟩)
  exact add_is_limit a h
  simpa only [add_zeroₓ]

theorem dvd_add_iff : ∀ {a b c : Ordinal}, a ∣ b → (a ∣ b + c ↔ a ∣ c)
  | a, _, c, ⟨b, rfl⟩ =>
    ⟨fun ⟨d, e⟩ =>
      ⟨d - b, by
        rw [mul_sub, ← e, add_sub_cancel]⟩,
      fun ⟨d, e⟩ => by
      rw [e, ← mul_addₓ]
      apply dvd_mul_right⟩

theorem div_mul_cancel : ∀ {a b : Ordinal}, a ≠ 0 → a ∣ b → a * (b / a) = b
  | a, _, a0, ⟨b, rfl⟩ => by
    rw [mul_div_cancel _ a0]

theorem le_of_dvd : ∀ {a b : Ordinal}, b ≠ 0 → a ∣ b → a ≤ b
  | a, _, b0, ⟨b, rfl⟩ => by
    simpa only [mul_oneₓ] using
      mul_le_mul_left'
        (one_le_iff_ne_zero.2 fun h : b = 0 => by
          simpa only [h, mul_zero] using b0)
        a

theorem dvd_antisymm {a b : Ordinal} (h₁ : a ∣ b) (h₂ : b ∣ a) : a = b :=
  if a0 : a = 0 then by
    subst a <;> exact (eq_zero_of_zero_dvd h₁).symm
  else
    if b0 : b = 0 then by
      subst b <;> exact eq_zero_of_zero_dvd h₂
    else (le_of_dvd b0 h₁).antisymm (le_of_dvd a0 h₂)

instance : IsAntisymm Ordinal (· ∣ ·) :=
  ⟨@dvd_antisymm⟩

/-- `a % b` is the unique ordinal `o'` satisfying
  `a = b * o + o'` with `o' < b`. -/
instance : Mod Ordinal :=
  ⟨fun a b => a - b * (a / b)⟩

theorem mod_def (a b : Ordinal) : a % b = a - b * (a / b) :=
  rfl

@[simp]
theorem mod_zero (a : Ordinal) : a % 0 = a := by
  simp only [mod_def, div_zero, zero_mul, sub_zero]

theorem mod_eq_of_lt {a b : Ordinal} (h : a < b) : a % b = a := by
  simp only [mod_def, div_eq_zero_of_lt h, mul_zero, sub_zero]

@[simp]
theorem zero_mod (b : Ordinal) : 0 % b = 0 := by
  simp only [mod_def, zero_div, mul_zero, sub_self]

theorem div_add_mod (a b : Ordinal) : b * (a / b) + a % b = a :=
  Ordinal.add_sub_cancel_of_le <| mul_div_le _ _

theorem mod_lt (a) {b : Ordinal} (h : b ≠ 0) : a % b < b :=
  (add_lt_add_iff_left (b * (a / b))).1 <| by
    rw [div_add_mod] <;> exact lt_mul_div_add a h

@[simp]
theorem mod_self (a : Ordinal) : a % a = 0 :=
  if a0 : a = 0 then by
    simp only [a0, zero_mod]
  else by
    simp only [mod_def, div_self a0, mul_oneₓ, sub_self]

@[simp]
theorem mod_one (a : Ordinal) : a % 1 = 0 := by
  simp only [mod_def, div_one, one_mulₓ, sub_self]

theorem dvd_of_mod_eq_zero {a b : Ordinal} (H : a % b = 0) : b ∣ a :=
  ⟨a / b, by
    simpa [H] using (div_add_mod a b).symm⟩

theorem mod_eq_zero_of_dvd {a b : Ordinal} (H : b ∣ a) : a % b = 0 := by
  rcases H with ⟨c, rfl⟩
  rcases eq_or_ne b 0 with (rfl | hb)
  · simp
    
  · simp [mod_def, hb]
    

theorem dvd_iff_mod_eq_zero {a b : Ordinal} : b ∣ a ↔ a % b = 0 :=
  ⟨mod_eq_zero_of_dvd, dvd_of_mod_eq_zero⟩

/-! ### Families of ordinals

There are two kinds of indexed families that naturally arise when dealing with ordinals: those
indexed by some type in the appropriate universe, and those indexed by ordinals less than another.
The following API allows one to convert from one kind of family to the other.

In many cases, this makes it easy to prove claims about one kind of family via the corresponding
claim on the other. -/


/-- Converts a family indexed by a `Type u` to one indexed by an `ordinal.{u}` using a specified
well-ordering. -/
def bfamilyOfFamily' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → α) : ∀ a < type r, α := fun a ha =>
  f (enum r a ha)

/-- Converts a family indexed by a `Type u` to one indexed by an `ordinal.{u}` using a well-ordering
given by the axiom of choice. -/
def bfamilyOfFamily {ι : Type u} : (ι → α) → ∀ a < type (@WellOrderingRel ι), α :=
  bfamilyOfFamily' WellOrderingRel

/-- Converts a family indexed by an `ordinal.{u}` to one indexed by an `Type u` using a specified
well-ordering. -/
def familyOfBfamily' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] {o} (ho : type r = o) (f : ∀ a < o, α) : ι → α :=
  fun i =>
  f (typein r i)
    (by
      rw [← ho]
      exact typein_lt_type r i)

/-- Converts a family indexed by an `ordinal.{u}` to one indexed by a `Type u` using a well-ordering
given by the axiom of choice. -/
def familyOfBfamily (o : Ordinal) (f : ∀ a < o, α) : o.out.α → α :=
  familyOfBfamily' (· < ·) (type_lt o) f

@[simp]
theorem bfamily_of_family'_typein {ι} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → α) (i) :
    bfamilyOfFamily' r f (typein r i) (typein_lt_type r i) = f i := by
  simp only [bfamily_of_family', enum_typein]

@[simp]
theorem bfamily_of_family_typein {ι} (f : ι → α) (i) : bfamilyOfFamily f (typein _ i) (typein_lt_type _ i) = f i :=
  bfamily_of_family'_typein _ f i

@[simp]
theorem family_of_bfamily'_enum {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] {o} (ho : type r = o) (f : ∀ a < o, α)
    (i hi) :
    familyOfBfamily' r ho f
        (enum r i
          (by
            rwa [ho])) =
      f i hi :=
  by
  simp only [family_of_bfamily', typein_enum]

@[simp]
theorem family_of_bfamily_enum (o : Ordinal) (f : ∀ a < o, α) (i hi) :
    familyOfBfamily o f
        (enum (· < ·) i
          (by
            convert hi
            exact type_lt _)) =
      f i hi :=
  family_of_bfamily'_enum _ (type_lt o) f _ _

/-- The range of a family indexed by ordinals. -/
def Brange (o : Ordinal) (f : ∀ a < o, α) : Set α :=
  { a | ∃ i hi, f i hi = a }

theorem mem_brange {o : Ordinal} {f : ∀ a < o, α} {a} : a ∈ Brange o f ↔ ∃ i hi, f i hi = a :=
  Iff.rfl

theorem mem_brange_self {o} (f : ∀ a < o, α) (i hi) : f i hi ∈ Brange o f :=
  ⟨i, hi, rfl⟩

@[simp]
theorem range_family_of_bfamily' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] {o} (ho : type r = o)
    (f : ∀ a < o, α) : Range (familyOfBfamily' r ho f) = Brange o f := by
  refine' Set.ext fun a => ⟨_, _⟩
  · rintro ⟨b, rfl⟩
    apply mem_brange_self
    
  · rintro ⟨i, hi, rfl⟩
    exact ⟨_, family_of_bfamily'_enum _ _ _ _ _⟩
    

@[simp]
theorem range_family_of_bfamily {o} (f : ∀ a < o, α) : Range (familyOfBfamily o f) = Brange o f :=
  range_family_of_bfamily' _ _ f

@[simp]
theorem brange_bfamily_of_family' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → α) :
    Brange _ (bfamilyOfFamily' r f) = Range f := by
  refine' Set.ext fun a => ⟨_, _⟩
  · rintro ⟨i, hi, rfl⟩
    apply mem_range_self
    
  · rintro ⟨b, rfl⟩
    exact ⟨_, _, bfamily_of_family'_typein _ _ _⟩
    

@[simp]
theorem brange_bfamily_of_family {ι : Type u} (f : ι → α) : Brange _ (bfamilyOfFamily f) = Range f :=
  brange_bfamily_of_family' _ _

@[simp]
theorem brange_const {o : Ordinal} (ho : o ≠ 0) {c : α} : (Brange o fun _ _ => c) = {c} := by
  rw [← range_family_of_bfamily]
  exact @Set.range_const _ o.out.α (out_nonempty_iff_ne_zero.2 ho) c

theorem comp_bfamily_of_family' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → α) (g : α → β) :
    (fun i hi => g (bfamilyOfFamily' r f i hi)) = bfamilyOfFamily' r (g ∘ f) :=
  rfl

theorem comp_bfamily_of_family {ι : Type u} (f : ι → α) (g : α → β) :
    (fun i hi => g (bfamilyOfFamily f i hi)) = bfamilyOfFamily (g ∘ f) :=
  rfl

theorem comp_family_of_bfamily' {ι : Type u} (r : ι → ι → Prop) [IsWellOrder ι r] {o} (ho : type r = o) (f : ∀ a < o, α)
    (g : α → β) : g ∘ familyOfBfamily' r ho f = familyOfBfamily' r ho fun i hi => g (f i hi) :=
  rfl

theorem comp_family_of_bfamily {o} (f : ∀ a < o, α) (g : α → β) :
    g ∘ familyOfBfamily o f = familyOfBfamily o fun i hi => g (f i hi) :=
  rfl

/-! ### Supremum of a family of ordinals -/


/-- The supremum of a family of ordinals -/
def sup {ι : Type u} (f : ι → Ordinal.{max u v}) : Ordinal.{max u v} :=
  supr f

@[simp]
theorem Sup_eq_sup {ι : Type u} (f : ι → Ordinal.{max u v}) : sup (Set.Range f) = sup f :=
  rfl

/-- The range of an indexed ordinal function, whose outputs live in a higher universe than the
    inputs, is always bounded above. See `ordinal.lsub` for an explicit bound. -/
theorem bdd_above_range {ι : Type u} (f : ι → Ordinal.{max u v}) : BddAbove (Set.Range f) :=
  ⟨(supr (succ ∘ card ∘ f)).ord, by
    rintro a ⟨i, rfl⟩
    exact le_of_ltₓ (Cardinal.lt_ord.2 ((lt_succ _).trans_le (le_csupr (bdd_above_range _) _)))⟩

theorem le_sup {ι} (f : ι → Ordinal) : ∀ i, f i ≤ sup f := fun i => le_cSup (bdd_above_range f) (mem_range_self i)

theorem sup_le_iff {ι} {f : ι → Ordinal} {a} : sup f ≤ a ↔ ∀ i, f i ≤ a :=
  (cSup_le_iff' (bdd_above_range f)).trans
    (by
      simp )

theorem sup_le {ι} {f : ι → Ordinal} {a} : (∀ i, f i ≤ a) → sup f ≤ a :=
  sup_le_iff.2

theorem lt_sup {ι} {f : ι → Ordinal} {a} : a < sup f ↔ ∃ i, a < f i := by
  simpa only [not_forall, not_leₓ] using not_congr (@sup_le_iff _ f a)

theorem ne_sup_iff_lt_sup {ι} {f : ι → Ordinal} : (∀ i, f i ≠ sup f) ↔ ∀ i, f i < sup f :=
  ⟨fun hf _ => lt_of_le_of_neₓ (le_sup _ _) (hf _), fun hf _ => ne_of_ltₓ (hf _)⟩

theorem sup_not_succ_of_ne_sup {ι} {f : ι → Ordinal} (hf : ∀ i, f i ≠ sup f) {a} (hao : a < sup f) : succ a < sup f :=
  by
  by_contra' hoa
  exact hao.not_le (sup_le fun i => le_of_lt_succ <| (lt_of_le_of_neₓ (le_sup _ _) (hf i)).trans_le hoa)

@[simp]
theorem sup_eq_zero_iff {ι} {f : ι → Ordinal} : sup f = 0 ↔ ∀ i, f i = 0 := by
  refine' ⟨fun h i => _, fun h => le_antisymmₓ (sup_le fun i => Ordinal.le_zero.2 (h i)) (Ordinal.zero_le _)⟩
  rw [← Ordinal.le_zero, ← h]
  exact le_sup f i

theorem IsNormal.sup {f} (H : IsNormal f) {ι} (g : ι → Ordinal) [Nonempty ι] : f (sup g) = sup (f ∘ g) :=
  eq_of_forall_ge_iffₓ fun a => by
    rw [sup_le_iff, comp, H.le_set' Set.Univ Set.univ_nonempty g] <;> simp [sup_le_iff]

@[simp]
theorem sup_empty {ι} [IsEmpty ι] (f : ι → Ordinal) : sup f = 0 :=
  csupr_of_empty f

@[simp]
theorem sup_const {ι} [hι : Nonempty ι] (o : Ordinal) : (sup fun _ : ι => o) = o :=
  csupr_const

@[simp]
theorem sup_unique {ι} [Unique ι] (f : ι → Ordinal) : sup f = f default :=
  supr_unique

theorem sup_le_of_range_subset {ι ι'} {f : ι → Ordinal} {g : ι' → Ordinal} (h : Set.Range f ⊆ Set.Range g) :
    sup.{u, max v w} f ≤ sup.{v, max u w} g :=
  sup_le fun i =>
    match h (mem_range_self i) with
    | ⟨j, hj⟩ => hj ▸ le_sup _ _

theorem sup_eq_of_range_eq {ι ι'} {f : ι → Ordinal} {g : ι' → Ordinal} (h : Set.Range f = Set.Range g) :
    sup.{u, max v w} f = sup.{v, max u w} g :=
  (sup_le_of_range_subset h.le).antisymm (sup_le_of_range_subset.{v, u, w} h.Ge)

theorem unbounded_range_of_sup_ge {α β : Type u} (r : α → α → Prop) [IsWellOrder α r] (f : β → α)
    (h : type r ≤ sup.{u, u} (typein r ∘ f)) : Unbounded r (Range f) :=
  (not_bounded_iff _).1 fun ⟨x, hx⟩ =>
    not_lt_of_leₓ h <|
      lt_of_le_of_ltₓ (sup_le fun y => le_of_ltₓ <| (typein_lt_typein r).2 <| hx _ <| mem_range_self y)
        (typein_lt_type r x)

theorem le_sup_shrink_equiv {s : Set Ordinal.{u}} (hs : Small.{u} s) (a) (ha : a ∈ s) :
    a ≤ sup.{u, u} fun x => ((@equivShrink s hs).symm x).val := by
  convert le_sup.{u, u} _ ((@equivShrink s hs) ⟨a, ha⟩)
  rw [symm_apply_apply]

instance small_Iio (o : Ordinal.{u}) : Small.{u} (Set.Iio o) :=
  let f : o.out.α → Set.Iio o := fun x => ⟨typein (· < ·) x, typein_lt_self x⟩
  let hf : Surjective f := fun b =>
    ⟨enum (· < ·) b.val
        (by
          rw [type_lt]
          exact b.prop),
      Subtype.ext (typein_enum _ _)⟩
  small_of_surjective hf

instance small_Iic (o : Ordinal.{u}) : Small.{u} (Set.Iic o) := by
  rw [← Iio_succ]
  infer_instance

theorem bdd_above_iff_small {s : Set Ordinal.{u}} : BddAbove s ↔ Small.{u} s :=
  ⟨fun ⟨a, h⟩ => small_subset <| show s ⊆ Iic a from fun x hx => h hx, fun h =>
    ⟨sup.{u, u} fun x => ((@equivShrink s h).symm x).val, le_sup_shrink_equiv h⟩⟩

theorem bdd_above_of_small (s : Set Ordinal.{u}) [h : Small.{u} s] : BddAbove s :=
  bdd_above_iff_small.2 h

theorem sup_eq_Sup {s : Set Ordinal.{u}} (hs : Small.{u} s) :
    (sup.{u, u} fun x => (@equivShrink s hs).symm x) = sup s :=
  let hs' := bdd_above_iff_small.2 hs
  ((cSup_le_iff' hs').2 (le_sup_shrink_equiv hs)).antisymm' (sup_le fun x => le_cSup hs' (Subtype.mem _))

theorem Sup_ord {s : Set Cardinal.{u}} (hs : BddAbove s) : (sup s).ord = sup (ord '' s) :=
  eq_of_forall_ge_iffₓ fun a => by
    rw [cSup_le_iff' (bdd_above_iff_small.2 (@small_image _ _ _ s (Cardinal.bdd_above_iff_small.1 hs))), ord_le,
      cSup_le_iff' hs]
    simp [ord_le]

theorem supr_ord {ι} {f : ι → Cardinal} (hf : BddAbove (Range f)) : (supr f).ord = ⨆ i, (f i).ord := by
  unfold supr
  convert Sup_ord hf
  rw [range_comp]

private theorem sup_le_sup {ι ι' : Type u} (r : ι → ι → Prop) (r' : ι' → ι' → Prop) [IsWellOrder ι r]
    [IsWellOrder ι' r'] {o} (ho : type r = o) (ho' : type r' = o) (f : ∀ a < o, Ordinal) :
    sup (familyOfBfamily' r ho f) ≤ sup (familyOfBfamily' r' ho' f) :=
  sup_le fun i => by
    cases'
      typein_surj r'
        (by
          rw [ho', ← ho]
          exact typein_lt_type r i) with
      j hj
    simp_rw [family_of_bfamily', ← hj]
    apply le_sup

theorem sup_eq_sup {ι ι' : Type u} (r : ι → ι → Prop) (r' : ι' → ι' → Prop) [IsWellOrder ι r] [IsWellOrder ι' r']
    {o : Ordinal.{u}} (ho : type r = o) (ho' : type r' = o) (f : ∀ a < o, Ordinal.{max u v}) :
    sup (familyOfBfamily' r ho f) = sup (familyOfBfamily' r' ho' f) :=
  sup_eq_of_range_eq.{u, u, v}
    (by
      simp )

/-- The supremum of a family of ordinals indexed by the set of ordinals less than some
    `o : ordinal.{u}`. This is a special case of `sup` over the family provided by
    `family_of_bfamily`. -/
def bsup (o : Ordinal.{u}) (f : ∀ a < o, Ordinal.{max u v}) : Ordinal.{max u v} :=
  sup (familyOfBfamily o f)

@[simp]
theorem sup_eq_bsup {o} (f : ∀ a < o, Ordinal) : sup (familyOfBfamily o f) = bsup o f :=
  rfl

@[simp]
theorem sup_eq_bsup' {o ι} (r : ι → ι → Prop) [IsWellOrder ι r] (ho : type r = o) (f) :
    sup (familyOfBfamily' r ho f) = bsup o f :=
  sup_eq_sup r _ ho _ f

@[simp]
theorem Sup_eq_bsup {o} (f : ∀ a < o, Ordinal) : sup (Brange o f) = bsup o f := by
  congr
  rw [range_family_of_bfamily]

@[simp]
theorem bsup_eq_sup' {ι} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → Ordinal) :
    bsup _ (bfamilyOfFamily' r f) = sup f := by
  simp only [← sup_eq_bsup' r, enum_typein, family_of_bfamily', bfamily_of_family']

theorem bsup_eq_bsup {ι : Type u} (r r' : ι → ι → Prop) [IsWellOrder ι r] [IsWellOrder ι r'] (f : ι → Ordinal) :
    bsup _ (bfamilyOfFamily' r f) = bsup _ (bfamilyOfFamily' r' f) := by
  rw [bsup_eq_sup', bsup_eq_sup']

@[simp]
theorem bsup_eq_sup {ι} (f : ι → Ordinal) : bsup _ (bfamilyOfFamily f) = sup f :=
  bsup_eq_sup' _ f

@[congr]
theorem bsup_congr {o₁ o₂ : Ordinal} (f : ∀ a < o₁, Ordinal) (ho : o₁ = o₂) :
    bsup o₁ f = bsup o₂ fun a h => f a (h.trans_eq ho.symm) := by
  subst ho

theorem bsup_le_iff {o f a} : bsup.{u, v} o f ≤ a ↔ ∀ i h, f i h ≤ a :=
  sup_le_iff.trans
    ⟨fun h i hi => by
      rw [← family_of_bfamily_enum o f]
      exact h _, fun h i => h _ _⟩

theorem bsup_le {o : Ordinal} {f : ∀ b < o, Ordinal} {a} : (∀ i h, f i h ≤ a) → bsup.{u, v} o f ≤ a :=
  bsup_le_iff.2

theorem le_bsup {o} (f : ∀ a < o, Ordinal) (i h) : f i h ≤ bsup o f :=
  bsup_le_iff.1 le_rflₓ _ _

theorem lt_bsup {o} (f : ∀ a < o, Ordinal) {a} : a < bsup o f ↔ ∃ i hi, a < f i hi := by
  simpa only [not_forall, not_leₓ] using not_congr (@bsup_le_iff _ f a)

theorem IsNormal.bsup {f} (H : IsNormal f) {o} :
    ∀ (g : ∀ a < o, Ordinal) (h : o ≠ 0), f (bsup o g) = bsup o fun a h => f (g a h) :=
  (induction_on o) fun α r _ g h => by
    skip
    haveI := type_ne_zero_iff_nonempty.1 h
    rw [← sup_eq_bsup' r, H.sup, ← sup_eq_bsup' r] <;> rfl

theorem lt_bsup_of_ne_bsup {o : Ordinal} {f : ∀ a < o, Ordinal} : (∀ i h, f i h ≠ o.bsup f) ↔ ∀ i h, f i h < o.bsup f :=
  ⟨fun hf _ _ => lt_of_le_of_neₓ (le_bsup _ _ _) (hf _ _), fun hf _ _ => ne_of_ltₓ (hf _ _)⟩

theorem bsup_not_succ_of_ne_bsup {o} {f : ∀ a < o, Ordinal} (hf : ∀ {i : Ordinal} (h : i < o), f i h ≠ o.bsup f) (a) :
    a < bsup o f → succ a < bsup o f := by
  rw [← sup_eq_bsup] at *
  exact sup_not_succ_of_ne_sup fun i => hf _

@[simp]
theorem bsup_eq_zero_iff {o} {f : ∀ a < o, Ordinal} : bsup o f = 0 ↔ ∀ i hi, f i hi = 0 := by
  refine' ⟨fun h i hi => _, fun h => le_antisymmₓ (bsup_le fun i hi => Ordinal.le_zero.2 (h i hi)) (Ordinal.zero_le _)⟩
  rw [← Ordinal.le_zero, ← h]
  exact le_bsup f i hi

theorem lt_bsup_of_limit {o : Ordinal} {f : ∀ a < o, Ordinal}
    (hf : ∀ {a a'} (ha : a < o) (ha' : a' < o), a < a' → f a ha < f a' ha') (ho : ∀ a < o, succ a < o) (i h) :
    f i h < bsup o f :=
  (hf _ _ <| lt_succ i).trans_le (le_bsup f (succ i) <| ho _ h)

theorem bsup_succ_of_mono {o : Ordinal} {f : ∀ a < succ o, Ordinal} (hf : ∀ {i j} (hi hj), i ≤ j → f i hi ≤ f j hj) :
    bsup _ f = f o (lt_succ o) :=
  le_antisymmₓ (bsup_le fun i hi => hf _ _ <| le_of_lt_succ hi) (le_bsup _ _ _)

@[simp]
theorem bsup_zero (f : ∀ a < (0 : Ordinal), Ordinal) : bsup 0 f = 0 :=
  bsup_eq_zero_iff.2 fun i hi => (Ordinal.not_lt_zero i hi).elim

theorem bsup_const {o : Ordinal} (ho : o ≠ 0) (a : Ordinal) : (bsup o fun _ _ => a) = a :=
  le_antisymmₓ (bsup_le fun _ _ => le_rflₓ) (le_bsup _ 0 (Ordinal.pos_iff_ne_zero.2 ho))

@[simp]
theorem bsup_one (f : ∀ a < (1 : Ordinal), Ordinal) : bsup 1 f = f 0 zero_lt_one := by
  simp_rw [← sup_eq_bsup, sup_unique, family_of_bfamily, family_of_bfamily', typein_one_out]

theorem bsup_le_of_brange_subset {o o'} {f : ∀ a < o, Ordinal} {g : ∀ a < o', Ordinal} (h : Brange o f ⊆ Brange o' g) :
    bsup.{u, max v w} o f ≤ bsup.{v, max u w} o' g :=
  bsup_le fun i hi => by
    obtain ⟨j, hj, hj'⟩ := h ⟨i, hi, rfl⟩
    rw [← hj']
    apply le_bsup

theorem bsup_eq_of_brange_eq {o o'} {f : ∀ a < o, Ordinal} {g : ∀ a < o', Ordinal} (h : Brange o f = Brange o' g) :
    bsup.{u, max v w} o f = bsup.{v, max u w} o' g :=
  (bsup_le_of_brange_subset h.le).antisymm (bsup_le_of_brange_subset.{v, u, w} h.Ge)

/-- The least strict upper bound of a family of ordinals. -/
def lsub {ι} (f : ι → Ordinal) : Ordinal :=
  sup (succ ∘ f)

@[simp]
theorem sup_eq_lsub {ι} (f : ι → Ordinal) : sup (succ ∘ f) = lsub f :=
  rfl

theorem lsub_le_iff {ι} {f : ι → Ordinal} {a} : lsub f ≤ a ↔ ∀ i, f i < a := by
  convert sup_le_iff
  simp only [succ_le_iff]

theorem lsub_le {ι} {f : ι → Ordinal} {a} : (∀ i, f i < a) → lsub f ≤ a :=
  lsub_le_iff.2

theorem lt_lsub {ι} (f : ι → Ordinal) (i) : f i < lsub f :=
  succ_le_iff.1 (le_sup _ i)

theorem lt_lsub_iff {ι} {f : ι → Ordinal} {a} : a < lsub f ↔ ∃ i, a ≤ f i := by
  simpa only [not_forall, not_ltₓ, not_leₓ] using not_congr (@lsub_le_iff _ f a)

theorem sup_le_lsub {ι} (f : ι → Ordinal) : sup f ≤ lsub f :=
  sup_le fun i => (lt_lsub f i).le

theorem lsub_le_sup_succ {ι} (f : ι → Ordinal) : lsub f ≤ succ (sup f) :=
  lsub_le fun i => lt_succ_iff.2 (le_sup f i)

theorem sup_eq_lsub_or_sup_succ_eq_lsub {ι} (f : ι → Ordinal) : sup f = lsub f ∨ succ (sup f) = lsub f := by
  cases eq_or_lt_of_leₓ (sup_le_lsub f)
  · exact Or.inl h
    
  · exact Or.inr ((succ_le_of_lt h).antisymm (lsub_le_sup_succ f))
    

theorem sup_succ_le_lsub {ι} (f : ι → Ordinal) : succ (sup f) ≤ lsub f ↔ ∃ i, f i = sup f := by
  refine' ⟨fun h => _, _⟩
  · by_contra' hf
    exact (succ_le_iff.1 h).Ne ((sup_le_lsub f).antisymm (lsub_le (ne_sup_iff_lt_sup.1 hf)))
    
  rintro ⟨_, hf⟩
  rw [succ_le_iff, ← hf]
  exact lt_lsub _ _

theorem sup_succ_eq_lsub {ι} (f : ι → Ordinal) : succ (sup f) = lsub f ↔ ∃ i, f i = sup f :=
  (lsub_le_sup_succ f).le_iff_eq.symm.trans (sup_succ_le_lsub f)

theorem sup_eq_lsub_iff_succ {ι} (f : ι → Ordinal) : sup f = lsub f ↔ ∀ a < lsub f, succ a < lsub f := by
  refine' ⟨fun h => _, fun hf => le_antisymmₓ (sup_le_lsub f) (lsub_le fun i => _)⟩
  · rw [← h]
    exact fun a => sup_not_succ_of_ne_sup fun i => (lsub_le_iff.1 (le_of_eqₓ h.symm) i).Ne
    
  by_contra' hle
  have heq := (sup_succ_eq_lsub f).2 ⟨i, le_antisymmₓ (le_sup _ _) hle⟩
  have :=
    hf _
      (by
        rw [← HEq]
        exact lt_succ (sup f))
  rw [HEq] at this
  exact this.false

theorem sup_eq_lsub_iff_lt_sup {ι} (f : ι → Ordinal) : sup f = lsub f ↔ ∀ i, f i < sup f :=
  ⟨fun h i => by
    rw [h]
    apply lt_lsub, fun h => le_antisymmₓ (sup_le_lsub f) (lsub_le h)⟩

@[simp]
theorem lsub_empty {ι} [h : IsEmpty ι] (f : ι → Ordinal) : lsub f = 0 := by
  rw [← Ordinal.le_zero, lsub_le_iff]
  exact h.elim

theorem lsub_pos {ι} [h : Nonempty ι] (f : ι → Ordinal) : 0 < lsub f :=
  h.elim fun i => (Ordinal.zero_le _).trans_lt (lt_lsub f i)

@[simp]
theorem lsub_eq_zero_iff {ι} {f : ι → Ordinal} : lsub f = 0 ↔ IsEmpty ι := by
  refine' ⟨fun h => ⟨fun i => _⟩, fun h => @lsub_empty _ h _⟩
  have := @lsub_pos _ ⟨i⟩ f
  rw [h] at this
  exact this.false

@[simp]
theorem lsub_const {ι} [hι : Nonempty ι] (o : Ordinal) : (lsub fun _ : ι => o) = succ o :=
  sup_const (succ o)

@[simp]
theorem lsub_unique {ι} [hι : Unique ι] (f : ι → Ordinal) : lsub f = succ (f default) :=
  sup_unique _

theorem lsub_le_of_range_subset {ι ι'} {f : ι → Ordinal} {g : ι' → Ordinal} (h : Set.Range f ⊆ Set.Range g) :
    lsub.{u, max v w} f ≤ lsub.{v, max u w} g :=
  sup_le_of_range_subset
    (by
      convert Set.image_subset _ h <;> apply Set.range_comp)

theorem lsub_eq_of_range_eq {ι ι'} {f : ι → Ordinal} {g : ι' → Ordinal} (h : Set.Range f = Set.Range g) :
    lsub.{u, max v w} f = lsub.{v, max u w} g :=
  (lsub_le_of_range_subset h.le).antisymm (lsub_le_of_range_subset.{v, u, w} h.Ge)

theorem lsub_not_mem_range {ι} (f : ι → Ordinal) : lsub f ∉ Set.Range f := fun ⟨i, h⟩ => h.not_lt (lt_lsub f i)

theorem nonempty_compl_range {ι : Type u} (f : ι → Ordinal.{max u v}) : Set.Range fᶜ.Nonempty :=
  ⟨_, lsub_not_mem_range f⟩

@[simp]
theorem lsub_typein (o : Ordinal) : lsub.{u, u} (typein ((· < ·) : o.out.α → o.out.α → Prop)) = o :=
  (lsub_le.{u, u} typein_lt_self).antisymm
    (by
      by_contra' h
      nth_rw 0[← type_lt o]  at h
      simpa [typein_enum] using lt_lsub.{u, u} (typein (· < ·)) (enum (· < ·) _ h))

theorem sup_typein_limit {o : Ordinal} (ho : ∀ a, a < o → succ a < o) :
    sup.{u, u} (typein ((· < ·) : o.out.α → o.out.α → Prop)) = o := by
  rw [(sup_eq_lsub_iff_succ.{u, u} (typein (· < ·))).2] <;> rwa [lsub_typein o]

@[simp]
theorem sup_typein_succ {o : Ordinal} : sup.{u, u} (typein ((· < ·) : (succ o).out.α → (succ o).out.α → Prop)) = o := by
  cases' sup_eq_lsub_or_sup_succ_eq_lsub.{u, u} (typein ((· < ·) : (succ o).out.α → (succ o).out.α → Prop)) with h h
  · rw [sup_eq_lsub_iff_succ] at h
    simp only [lsub_typein] at h
    exact (h o (lt_succ o)).False.elim
    
  rw [← succ_eq_succ_iff, h]
  apply lsub_typein

/-- The least strict upper bound of a family of ordinals indexed by the set of ordinals less than
    some `o : ordinal.{u}`.

    This is to `lsub` as `bsup` is to `sup`. -/
def blsub (o : Ordinal.{u}) (f : ∀ a < o, Ordinal.{max u v}) : Ordinal.{max u v} :=
  o.bsup fun a ha => succ (f a ha)

@[simp]
theorem bsup_eq_blsub (o : Ordinal) (f : ∀ a < o, Ordinal) : (bsup o fun a ha => succ (f a ha)) = blsub o f :=
  rfl

theorem lsub_eq_blsub' {ι} (r : ι → ι → Prop) [IsWellOrder ι r] {o} (ho : type r = o) (f) :
    lsub (familyOfBfamily' r ho f) = blsub o f :=
  sup_eq_bsup' r ho fun a ha => succ (f a ha)

theorem lsub_eq_lsub {ι ι' : Type u} (r : ι → ι → Prop) (r' : ι' → ι' → Prop) [IsWellOrder ι r] [IsWellOrder ι' r'] {o}
    (ho : type r = o) (ho' : type r' = o) (f : ∀ a < o, Ordinal) :
    lsub (familyOfBfamily' r ho f) = lsub (familyOfBfamily' r' ho' f) := by
  rw [lsub_eq_blsub', lsub_eq_blsub']

@[simp]
theorem lsub_eq_blsub {o} (f : ∀ a < o, Ordinal) : lsub (familyOfBfamily o f) = blsub o f :=
  lsub_eq_blsub' _ _ _

@[simp]
theorem blsub_eq_lsub' {ι} (r : ι → ι → Prop) [IsWellOrder ι r] (f : ι → Ordinal) :
    blsub _ (bfamilyOfFamily' r f) = lsub f :=
  bsup_eq_sup' r (succ ∘ f)

theorem blsub_eq_blsub {ι : Type u} (r r' : ι → ι → Prop) [IsWellOrder ι r] [IsWellOrder ι r'] (f : ι → Ordinal) :
    blsub _ (bfamilyOfFamily' r f) = blsub _ (bfamilyOfFamily' r' f) := by
  rw [blsub_eq_lsub', blsub_eq_lsub']

@[simp]
theorem blsub_eq_lsub {ι} (f : ι → Ordinal) : blsub _ (bfamilyOfFamily f) = lsub f :=
  blsub_eq_lsub' _ _

@[congr]
theorem blsub_congr {o₁ o₂ : Ordinal} (f : ∀ a < o₁, Ordinal) (ho : o₁ = o₂) :
    blsub o₁ f = blsub o₂ fun a h => f a (h.trans_eq ho.symm) := by
  subst ho

theorem blsub_le_iff {o f a} : blsub o f ≤ a ↔ ∀ i h, f i h < a := by
  convert bsup_le_iff
  simp [succ_le_iff]

theorem blsub_le {o : Ordinal} {f : ∀ b < o, Ordinal} {a} : (∀ i h, f i h < a) → blsub o f ≤ a :=
  blsub_le_iff.2

theorem lt_blsub {o} (f : ∀ a < o, Ordinal) (i h) : f i h < blsub o f :=
  blsub_le_iff.1 le_rflₓ _ _

theorem lt_blsub_iff {o f a} : a < blsub o f ↔ ∃ i hi, a ≤ f i hi := by
  simpa only [not_forall, not_ltₓ, not_leₓ] using not_congr (@blsub_le_iff _ f a)

theorem bsup_le_blsub {o} (f : ∀ a < o, Ordinal) : bsup o f ≤ blsub o f :=
  bsup_le fun i h => (lt_blsub f i h).le

theorem blsub_le_bsup_succ {o} (f : ∀ a < o, Ordinal) : blsub o f ≤ succ (bsup o f) :=
  blsub_le fun i h => lt_succ_iff.2 (le_bsup f i h)

theorem bsup_eq_blsub_or_succ_bsup_eq_blsub {o} (f : ∀ a < o, Ordinal) :
    bsup o f = blsub o f ∨ succ (bsup o f) = blsub o f := by
  rw [← sup_eq_bsup, ← lsub_eq_blsub]
  exact sup_eq_lsub_or_sup_succ_eq_lsub _

theorem bsup_succ_le_blsub {o} (f : ∀ a < o, Ordinal) : succ (bsup o f) ≤ blsub o f ↔ ∃ i hi, f i hi = bsup o f := by
  refine' ⟨fun h => _, _⟩
  · by_contra' hf
    exact ne_of_ltₓ (succ_le_iff.1 h) (le_antisymmₓ (bsup_le_blsub f) (blsub_le (lt_bsup_of_ne_bsup.1 hf)))
    
  rintro ⟨_, _, hf⟩
  rw [succ_le_iff, ← hf]
  exact lt_blsub _ _ _

theorem bsup_succ_eq_blsub {o} (f : ∀ a < o, Ordinal) : succ (bsup o f) = blsub o f ↔ ∃ i hi, f i hi = bsup o f :=
  (blsub_le_bsup_succ f).le_iff_eq.symm.trans (bsup_succ_le_blsub f)

theorem bsup_eq_blsub_iff_succ {o} (f : ∀ a < o, Ordinal) :
    bsup o f = blsub o f ↔ ∀ a < blsub o f, succ a < blsub o f := by
  rw [← sup_eq_bsup, ← lsub_eq_blsub]
  apply sup_eq_lsub_iff_succ

theorem bsup_eq_blsub_iff_lt_bsup {o} (f : ∀ a < o, Ordinal) : bsup o f = blsub o f ↔ ∀ i hi, f i hi < bsup o f :=
  ⟨fun h i => by
    rw [h]
    apply lt_blsub, fun h => le_antisymmₓ (bsup_le_blsub f) (blsub_le h)⟩

theorem bsup_eq_blsub_of_lt_succ_limit {o} (ho : IsLimit o) {f : ∀ a < o, Ordinal}
    (hf : ∀ a ha, f a ha < f (succ a) (ho.2 a ha)) : bsup o f = blsub o f := by
  rw [bsup_eq_blsub_iff_lt_bsup]
  exact fun i hi => (hf i hi).trans_le (le_bsup f _ _)

theorem blsub_succ_of_mono {o : Ordinal} {f : ∀ a < succ o, Ordinal} (hf : ∀ {i j} (hi hj), i ≤ j → f i hi ≤ f j hj) :
    blsub _ f = succ (f o (lt_succ o)) :=
  bsup_succ_of_mono fun i j hi hj h => succ_le_succ (hf hi hj h)

@[simp]
theorem blsub_eq_zero_iff {o} {f : ∀ a < o, Ordinal} : blsub o f = 0 ↔ o = 0 := by
  rw [← lsub_eq_blsub, lsub_eq_zero_iff]
  exact out_empty_iff_eq_zero

@[simp]
theorem blsub_zero (f : ∀ a < (0 : Ordinal), Ordinal) : blsub 0 f = 0 := by
  rwa [blsub_eq_zero_iff]

theorem blsub_pos {o : Ordinal} (ho : 0 < o) (f : ∀ a < o, Ordinal) : 0 < blsub o f :=
  (Ordinal.zero_le _).trans_lt (lt_blsub f 0 ho)

theorem blsub_type (r : α → α → Prop) [IsWellOrder α r] (f) :
    blsub (type r) f = lsub fun a => f (typein r a) (typein_lt_type _ _) :=
  eq_of_forall_ge_iffₓ fun o => by
    rw [blsub_le_iff, lsub_le_iff] <;>
      exact
        ⟨fun H b => H _ _, fun H i h => by
          simpa only [typein_enum] using H (enum r i h)⟩

theorem blsub_const {o : Ordinal} (ho : o ≠ 0) (a : Ordinal) : (blsub.{u, v} o fun _ _ => a) = succ a :=
  bsup_const.{u, v} ho (succ a)

@[simp]
theorem blsub_one (f : ∀ a < (1 : Ordinal), Ordinal) : blsub 1 f = succ (f 0 zero_lt_one) :=
  bsup_one _

@[simp]
theorem blsub_id : ∀ o, (blsub.{u, u} o fun x _ => x) = o :=
  lsub_typein

theorem bsup_id_limit {o : Ordinal} : (∀ a < o, succ a < o) → (bsup.{u, u} o fun x _ => x) = o :=
  sup_typein_limit

@[simp]
theorem bsup_id_succ (o) : (bsup.{u, u} (succ o) fun x _ => x) = o :=
  sup_typein_succ

theorem blsub_le_of_brange_subset {o o'} {f : ∀ a < o, Ordinal} {g : ∀ a < o', Ordinal} (h : Brange o f ⊆ Brange o' g) :
    blsub.{u, max v w} o f ≤ blsub.{v, max u w} o' g :=
  bsup_le_of_brange_subset fun a ⟨b, hb, hb'⟩ => by
    obtain ⟨c, hc, hc'⟩ := h ⟨b, hb, rfl⟩
    simp_rw [← hc'] at hb'
    exact ⟨c, hc, hb'⟩

theorem blsub_eq_of_brange_eq {o o'} {f : ∀ a < o, Ordinal} {g : ∀ a < o', Ordinal}
    (h : { o | ∃ i hi, f i hi = o } = { o | ∃ i hi, g i hi = o }) : blsub.{u, max v w} o f = blsub.{v, max u w} o' g :=
  (blsub_le_of_brange_subset h.le).antisymm (blsub_le_of_brange_subset.{v, u, w} h.Ge)

theorem bsup_comp {o o' : Ordinal} {f : ∀ a < o, Ordinal} (hf : ∀ {i j} (hi) (hj), i ≤ j → f i hi ≤ f j hj)
    {g : ∀ a < o', Ordinal} (hg : blsub o' g = o) :
    (bsup o' fun a ha =>
        f (g a ha)
          (by
            rw [← hg]
            apply lt_blsub)) =
      bsup o f :=
  by
  apply le_antisymmₓ <;> refine' bsup_le fun i hi => _
  · apply le_bsup
    
  · rw [← hg, lt_blsub_iff] at hi
    rcases hi with ⟨j, hj, hj'⟩
    exact (hf _ _ hj').trans (le_bsup _ _ _)
    

theorem blsub_comp {o o' : Ordinal} {f : ∀ a < o, Ordinal} (hf : ∀ {i j} (hi) (hj), i ≤ j → f i hi ≤ f j hj)
    {g : ∀ a < o', Ordinal} (hg : blsub o' g = o) :
    (blsub o' fun a ha =>
        f (g a ha)
          (by
            rw [← hg]
            apply lt_blsub)) =
      blsub o f :=
  @bsup_comp o _ (fun a ha => succ (f a ha)) (fun i j _ _ h => succ_le_succ_iff.2 (hf _ _ h)) g hg

theorem IsNormal.bsup_eq {f} (H : IsNormal f) {o : Ordinal} (h : IsLimit o) : (bsup.{u} o fun x _ => f x) = f o := by
  rw [← IsNormal.bsup.{u, u} H (fun x _ => x) h.1, bsup_id_limit h.2]

theorem IsNormal.blsub_eq {f} (H : IsNormal f) {o : Ordinal} (h : IsLimit o) : (blsub.{u} o fun x _ => f x) = f o := by
  rw [← H.bsup_eq h, bsup_eq_blsub_of_lt_succ_limit h]
  exact fun a _ => H.1 a

theorem is_normal_iff_lt_succ_and_bsup_eq {f} :
    IsNormal f ↔ (∀ a, f a < f (succ a)) ∧ ∀ o, IsLimit o → (bsup o fun x _ => f x) = f o :=
  ⟨fun h => ⟨h.1, @IsNormal.bsup_eq f h⟩, fun ⟨h₁, h₂⟩ =>
    ⟨h₁, fun o ho a => by
      rw [← h₂ o ho]
      exact bsup_le_iff⟩⟩

theorem is_normal_iff_lt_succ_and_blsub_eq {f} :
    IsNormal f ↔ (∀ a, f a < f (succ a)) ∧ ∀ o, IsLimit o → (blsub o fun x _ => f x) = f o := by
  rw [is_normal_iff_lt_succ_and_bsup_eq, And.congr_right_iff]
  intro h
  constructor <;> intro H o ho <;> have := H o ho <;> rwa [← bsup_eq_blsub_of_lt_succ_limit ho fun a _ => h a] at *

theorem IsNormal.eq_iff_zero_and_succ {f g : Ordinal.{u} → Ordinal.{u}} (hf : IsNormal f) (hg : IsNormal g) :
    f = g ↔ f 0 = g 0 ∧ ∀ a, f a = g a → f (succ a) = g (succ a) :=
  ⟨fun h => by
    simp [h], fun ⟨h₁, h₂⟩ =>
    funext fun a => by
      apply a.limit_rec_on
      assumption'
      intro o ho H
      rw [← IsNormal.bsup_eq.{u, u} hf ho, ← IsNormal.bsup_eq.{u, u} hg ho]
      congr
      ext b hb
      exact H b hb⟩

/-! ### Minimum excluded ordinals -/


/-- The minimum excluded ordinal in a family of ordinals. -/
def mex {ι : Type u} (f : ι → Ordinal.{max u v}) : Ordinal :=
  inf (Set.Range fᶜ)

theorem mex_not_mem_range {ι : Type u} (f : ι → Ordinal.{max u v}) : mex f ∉ Set.Range f :=
  Inf_mem (nonempty_compl_range f)

theorem ne_mex {ι} (f : ι → Ordinal) : ∀ i, f i ≠ mex f := by
  simpa using mex_not_mem_range f

theorem mex_le_of_ne {ι} {f : ι → Ordinal} {a} (ha : ∀ i, f i ≠ a) : mex f ≤ a :=
  cInf_le'
    (by
      simp [ha])

theorem exists_of_lt_mex {ι} {f : ι → Ordinal} {a} (ha : a < mex f) : ∃ i, f i = a := by
  by_contra' ha'
  exact ha.not_le (mex_le_of_ne ha')

theorem mex_le_lsub {ι} (f : ι → Ordinal) : mex f ≤ lsub f :=
  cInf_le' (lsub_not_mem_range f)

theorem mex_monotone {α β} {f : α → Ordinal} {g : β → Ordinal} (h : Set.Range f ⊆ Set.Range g) : mex f ≤ mex g := by
  refine' mex_le_of_ne fun i hi => _
  cases' h ⟨i, rfl⟩ with j hj
  rw [← hj] at hi
  exact ne_mex g j hi

theorem mex_lt_ord_succ_mk {ι} (f : ι → Ordinal) : mex f < (succ (# ι)).ord := by
  by_contra' h
  apply (lt_succ (# ι)).not_le
  have H := fun a => exists_of_lt_mex ((typein_lt_self a).trans_le h)
  let g : (succ (# ι)).ord.out.α → ι := fun a => Classical.choose (H a)
  have hg : injective g := fun a b h' => by
    have Hf : ∀ x, f (g x) = typein (· < ·) x := fun a => Classical.choose_spec (H a)
    apply_fun f  at h'
    rwa [Hf, Hf, typein_inj] at h'
  convert Cardinal.mk_le_of_injective hg
  rw [Cardinal.mk_ord_out]

/-- The minimum excluded ordinal of a family of ordinals indexed by the set of ordinals less than
    some `o : ordinal.{u}`. This is a special case of `mex` over the family provided by
    `family_of_bfamily`.

    This is to `mex` as `bsup` is to `sup`. -/
def bmex (o : Ordinal) (f : ∀ a < o, Ordinal) : Ordinal :=
  mex (familyOfBfamily o f)

theorem bmex_not_mem_brange {o : Ordinal} (f : ∀ a < o, Ordinal) : bmex o f ∉ Brange o f := by
  rw [← range_family_of_bfamily]
  apply mex_not_mem_range

theorem ne_bmex {o : Ordinal} (f : ∀ a < o, Ordinal) {i} (hi) : f i hi ≠ bmex o f := by
  convert
    ne_mex _
      (enum (· < ·) i
        (by
          rwa [type_lt]))
  rw [family_of_bfamily_enum]

theorem bmex_le_of_ne {o : Ordinal} {f : ∀ a < o, Ordinal} {a} (ha : ∀ i hi, f i hi ≠ a) : bmex o f ≤ a :=
  mex_le_of_ne fun i => ha _ _

theorem exists_of_lt_bmex {o : Ordinal} {f : ∀ a < o, Ordinal} {a} (ha : a < bmex o f) : ∃ i hi, f i hi = a := by
  cases' exists_of_lt_mex ha with i hi
  exact ⟨_, typein_lt_self i, hi⟩

theorem bmex_le_blsub {o : Ordinal} (f : ∀ a < o, Ordinal) : bmex o f ≤ blsub o f :=
  mex_le_lsub _

theorem bmex_monotone {o o' : Ordinal} {f : ∀ a < o, Ordinal} {g : ∀ a < o', Ordinal} (h : Brange o f ⊆ Brange o' g) :
    bmex o f ≤ bmex o' g :=
  mex_monotone
    (by
      rwa [range_family_of_bfamily, range_family_of_bfamily])

theorem bmex_lt_ord_succ_card {o : Ordinal} (f : ∀ a < o, Ordinal) : bmex o f < (succ o.card).ord := by
  rw [← mk_ordinal_out]
  exact mex_lt_ord_succ_mk (family_of_bfamily o f)

end Ordinal

/-! ### Results about injectivity and surjectivity -/


theorem not_surjective_of_ordinal {α : Type u} (f : α → Ordinal.{u}) : ¬Surjective f := fun h =>
  Ordinal.lsub_not_mem_range.{u, u} f (h _)

theorem not_injective_of_ordinal {α : Type u} (f : Ordinal.{u} → α) : ¬Injective f := fun h =>
  not_surjective_of_ordinal _ (inv_fun_surjectiveₓ h)

theorem not_surjective_of_ordinal_of_small {α : Type v} [Small.{u} α] (f : α → Ordinal.{u}) : ¬Surjective f := fun h =>
  not_surjective_of_ordinal _ (h.comp (equivShrink _).symm.Surjective)

theorem not_injective_of_ordinal_of_small {α : Type v} [Small.{u} α] (f : Ordinal.{u} → α) : ¬Injective f := fun h =>
  not_injective_of_ordinal _ ((equivShrink _).Injective.comp h)

/-- The type of ordinals in universe `u` is not `small.{u}`. This is the type-theoretic analog of
the Burali-Forti paradox. -/
theorem not_small_ordinal : ¬Small.{u} Ordinal.{max u v} := fun h =>
  @not_injective_of_ordinal_of_small _ h _ fun a b => Ordinal.lift_inj.1

/-! ### Enumerating unbounded sets of ordinals with ordinals -/


namespace Ordinal

section

/-- Enumerator function for an unbounded set of ordinals. -/
def enumOrd (S : Set Ordinal.{u}) : Ordinal → Ordinal :=
  lt_wf.fix fun o f => inf (S ∩ Set.Ici (blsub.{u, u} o f))

variable {S : Set Ordinal.{u}}

/-- The equation that characterizes `enum_ord` definitionally. This isn't the nicest expression to
    work with, so consider using `enum_ord_def` instead. -/
theorem enum_ord_def' (o) : enumOrd S o = inf (S ∩ Set.Ici (blsub.{u, u} o fun a _ => enumOrd S a)) :=
  lt_wf.fix_eq _ _

/-- The set in `enum_ord_def'` is nonempty. -/
theorem enum_ord_def'_nonempty (hS : Unbounded (· < ·) S) (a) : (S ∩ Set.Ici a).Nonempty :=
  let ⟨b, hb, hb'⟩ := hS a
  ⟨b, hb, le_of_not_gtₓ hb'⟩

private theorem enum_ord_mem_aux (hS : Unbounded (· < ·) S) (o) :
    enumOrd S o ∈ S ∩ Set.Ici (blsub.{u, u} o fun c _ => enumOrd S c) := by
  rw [enum_ord_def']
  exact Inf_mem (enum_ord_def'_nonempty hS _)

theorem enum_ord_mem (hS : Unbounded (· < ·) S) (o) : enumOrd S o ∈ S :=
  (enum_ord_mem_aux hS o).left

theorem blsub_le_enum_ord (hS : Unbounded (· < ·) S) (o) : (blsub.{u, u} o fun c _ => enumOrd S c) ≤ enumOrd S o :=
  (enum_ord_mem_aux hS o).right

theorem enum_ord_strict_mono (hS : Unbounded (· < ·) S) : StrictMono (enumOrd S) := fun _ _ h =>
  (lt_blsub.{u, u} _ _ h).trans_le (blsub_le_enum_ord hS _)

/-- A more workable definition for `enum_ord`. -/
theorem enum_ord_def (o) : enumOrd S o = inf (S ∩ { b | ∀ c, c < o → enumOrd S c < b }) := by
  rw [enum_ord_def']
  congr
  ext
  exact ⟨fun h a hao => (lt_blsub.{u, u} _ _ hao).trans_le h, blsub_le⟩

/-- The set in `enum_ord_def` is nonempty. -/
theorem enum_ord_def_nonempty (hS : Unbounded (· < ·) S) {o} : { x | x ∈ S ∧ ∀ c, c < o → enumOrd S c < x }.Nonempty :=
  ⟨_, enum_ord_mem hS o, fun _ b => enum_ord_strict_mono hS b⟩

@[simp]
theorem enum_ord_range {f : Ordinal → Ordinal} (hf : StrictMono f) : enumOrd (Range f) = f :=
  funext fun o => by
    apply Ordinal.induction o
    intro a H
    rw [enum_ord_def a]
    have Hfa : f a ∈ range f ∩ { b | ∀ c, c < a → enum_ord (range f) c < b } :=
      ⟨mem_range_self a, fun b hb => by
        rw [H b hb]
        exact hf hb⟩
    refine' (cInf_le' Hfa).antisymm ((le_cInf_iff'' ⟨_, Hfa⟩).2 _)
    rintro _ ⟨⟨c, rfl⟩, hc : ∀ b < a, enum_ord (range f) b < f c⟩
    rw [hf.le_iff_le]
    contrapose! hc
    exact ⟨c, hc, (H c hc).Ge⟩

@[simp]
theorem enum_ord_univ : enumOrd Set.Univ = id := by
  rw [← range_id]
  exact enum_ord_range strict_mono_id

@[simp]
theorem enum_ord_zero : enumOrd S 0 = inf S := by
  rw [enum_ord_def]
  simp [Ordinal.not_lt_zero]

theorem enum_ord_succ_le {a b} (hS : Unbounded (· < ·) S) (ha : a ∈ S) (hb : enumOrd S b < a) :
    enumOrd S (succ b) ≤ a := by
  rw [enum_ord_def]
  exact cInf_le' ⟨ha, fun c hc => ((enum_ord_strict_mono hS).Monotone (le_of_lt_succ hc)).trans_lt hb⟩

theorem enum_ord_le_of_subset {S T : Set Ordinal} (hS : Unbounded (· < ·) S) (hST : S ⊆ T) (a) :
    enumOrd T a ≤ enumOrd S a := by
  apply Ordinal.induction a
  intro b H
  rw [enum_ord_def]
  exact cInf_le' ⟨hST (enum_ord_mem hS b), fun c h => (H c h).trans_lt (enum_ord_strict_mono hS h)⟩

theorem enum_ord_surjective (hS : Unbounded (· < ·) S) : ∀ s ∈ S, ∃ a, enumOrd S a = s := fun s hs =>
  ⟨sup { a | enumOrd S a ≤ s }, by
    apply le_antisymmₓ
    · rw [enum_ord_def]
      refine' cInf_le' ⟨hs, fun a ha => _⟩
      have : enum_ord S 0 ≤ s := by
        rw [enum_ord_zero]
        exact cInf_le' hs
      rcases exists_lt_of_lt_cSup ⟨0, this⟩ ha with ⟨b, hb, hab⟩
      exact (enum_ord_strict_mono hS hab).trans_le hb
      
    · by_contra' h
      exact
        (le_cSup ⟨s, fun a => (lt_wf.self_le_of_strict_mono (enum_ord_strict_mono hS) a).trans⟩
              (enum_ord_succ_le hS hs h)).not_lt
          (lt_succ _)
      ⟩

/-- An order isomorphism between an unbounded set of ordinals and the ordinals. -/
def enumOrdOrderIso (hS : Unbounded (· < ·) S) : Ordinal ≃o S :=
  StrictMono.orderIsoOfSurjective (fun o => ⟨_, enum_ord_mem hS o⟩) (enum_ord_strict_mono hS) fun s =>
    let ⟨a, ha⟩ := enum_ord_surjective hS s s.Prop
    ⟨a, Subtype.eq ha⟩

theorem range_enum_ord (hS : Unbounded (· < ·) S) : Range (enumOrd S) = S := by
  rw [range_eq_iff]
  exact ⟨enum_ord_mem hS, enum_ord_surjective hS⟩

/-- A characterization of `enum_ord`: it is the unique strict monotonic function with range `S`. -/
theorem eq_enum_ord (f : Ordinal → Ordinal) (hS : Unbounded (· < ·) S) : StrictMono f ∧ Range f = S ↔ f = enumOrd S :=
  by
  constructor
  · rintro ⟨h₁, h₂⟩
    rwa [← lt_wf.eq_strict_mono_iff_eq_range h₁ (enum_ord_strict_mono hS), range_enum_ord hS]
    
  · rintro rfl
    exact ⟨enum_ord_strict_mono hS, range_enum_ord hS⟩
    

end

/-! ### Ordinal exponential -/


/-- The ordinal exponential, defined by transfinite recursion. -/
instance : Pow Ordinal Ordinal :=
  ⟨fun a b => if a = 0 then 1 - b else limitRecOn b 1 (fun _ IH => IH * a) fun b _ => bsup.{u, u} b⟩

-- mathport name: ordinal.pow
local infixr:0 "^" => @pow Ordinal Ordinal Ordinal.hasPow

theorem opow_def (a b : Ordinal) :
    (a^b) = if a = 0 then 1 - b else limitRecOn b 1 (fun _ IH => IH * a) fun b _ => bsup.{u, u} b :=
  rfl

theorem zero_opow' (a : Ordinal) : (0^a) = 1 - a := by
  simp only [opow_def, if_pos rfl]

@[simp]
theorem zero_opow {a : Ordinal} (a0 : a ≠ 0) : (0^a) = 0 := by
  rwa [zero_opow', Ordinal.sub_eq_zero_iff_le, one_le_iff_ne_zero]

@[simp]
theorem opow_zero (a : Ordinal) : (a^0) = 1 := by
  by_cases' a = 0 <;> [simp only [opow_def, if_pos h, sub_zero], simp only [opow_def, if_neg h, limit_rec_on_zero]]

@[simp]
theorem opow_succ (a b : Ordinal) : (a^succ b) = (a^b) * a :=
  if h : a = 0 then by
    subst a <;> simp only [zero_opow (succ_ne_zero _), mul_zero]
  else by
    simp only [opow_def, limit_rec_on_succ, if_neg h]

theorem opow_limit {a b : Ordinal} (a0 : a ≠ 0) (h : IsLimit b) : (a^b) = bsup.{u, u} b fun c _ => a^c := by
  simp only [opow_def, if_neg a0] <;> rw [limit_rec_on_limit _ _ _ _ h] <;> rfl

theorem opow_le_of_limit {a b c : Ordinal} (a0 : a ≠ 0) (h : IsLimit b) : (a^b) ≤ c ↔ ∀ b' < b, (a^b') ≤ c := by
  rw [opow_limit a0 h, bsup_le_iff]

theorem lt_opow_of_limit {a b c : Ordinal} (b0 : b ≠ 0) (h : IsLimit c) : a < (b^c) ↔ ∃ c' < c, a < (b^c') := by
  rw [← not_iff_not, not_exists] <;> simp only [not_ltₓ, opow_le_of_limit b0 h, exists_prop, not_and]

@[simp]
theorem opow_one (a : Ordinal) : (a^1) = a := by
  rw [← succ_zero, opow_succ] <;> simp only [opow_zero, one_mulₓ]

@[simp]
theorem one_opow (a : Ordinal) : (1^a) = 1 := by
  apply limit_rec_on a
  · simp only [opow_zero]
    
  · intro _ ih
    simp only [opow_succ, ih, mul_oneₓ]
    
  refine' fun b l IH => eq_of_forall_ge_iffₓ fun c => _
  rw [opow_le_of_limit Ordinal.one_ne_zero l]
  exact
    ⟨fun H => by
      simpa only [opow_zero] using H 0 l.pos, fun H b' h => by
      rwa [IH _ h]⟩

theorem opow_pos {a : Ordinal} (b) (a0 : 0 < a) : 0 < (a^b) := by
  have h0 : 0 < (a^0) := by
    simp only [opow_zero, zero_lt_one]
  apply limit_rec_on b
  · exact h0
    
  · intro b IH
    rw [opow_succ]
    exact mul_pos IH a0
    
  · exact fun b l _ => (lt_opow_of_limit (Ordinal.pos_iff_ne_zero.1 a0) l).2 ⟨0, l.Pos, h0⟩
    

theorem opow_ne_zero {a : Ordinal} (b) (a0 : a ≠ 0) : (a^b) ≠ 0 :=
  Ordinal.pos_iff_ne_zero.1 <| opow_pos b <| Ordinal.pos_iff_ne_zero.2 a0

theorem opow_is_normal {a : Ordinal} (h : 1 < a) : IsNormal ((·^·) a) :=
  have a0 : 0 < a := zero_lt_one.trans h
  ⟨fun b => by
    simpa only [mul_oneₓ, opow_succ] using (mul_lt_mul_iff_left (opow_pos b a0)).2 h, fun b l c =>
    opow_le_of_limit (ne_of_gtₓ a0) l⟩

theorem opow_lt_opow_iff_right {a b c : Ordinal} (a1 : 1 < a) : (a^b) < (a^c) ↔ b < c :=
  (opow_is_normal a1).lt_iff

theorem opow_le_opow_iff_right {a b c : Ordinal} (a1 : 1 < a) : (a^b) ≤ (a^c) ↔ b ≤ c :=
  (opow_is_normal a1).le_iff

theorem opow_right_inj {a b c : Ordinal} (a1 : 1 < a) : (a^b) = (a^c) ↔ b = c :=
  (opow_is_normal a1).inj

theorem opow_is_limit {a b : Ordinal} (a1 : 1 < a) : IsLimit b → IsLimit (a^b) :=
  (opow_is_normal a1).IsLimit

theorem opow_is_limit_left {a b : Ordinal} (l : IsLimit a) (hb : b ≠ 0) : IsLimit (a^b) := by
  rcases zero_or_succ_or_limit b with (e | ⟨b, rfl⟩ | l')
  · exact absurd e hb
    
  · rw [opow_succ]
    exact mul_is_limit (opow_pos _ l.pos) l
    
  · exact opow_is_limit l.one_lt l'
    

theorem opow_le_opow_right {a b c : Ordinal} (h₁ : 0 < a) (h₂ : b ≤ c) : (a^b) ≤ (a^c) := by
  cases' lt_or_eq_of_leₓ (one_le_iff_pos.2 h₁) with h₁ h₁
  · exact (opow_le_opow_iff_right h₁).2 h₂
    
  · subst a
    simp only [one_opow]
    

theorem opow_le_opow_left {a b : Ordinal} (c) (ab : a ≤ b) : (a^c) ≤ (b^c) := by
  by_cases' a0 : a = 0
  · subst a
    by_cases' c0 : c = 0
    · subst c
      simp only [opow_zero]
      
    · simp only [zero_opow c0, Ordinal.zero_le]
      
    
  · apply limit_rec_on c
    · simp only [opow_zero]
      
    · intro c IH
      simpa only [opow_succ] using mul_le_mul' IH ab
      
    · exact fun c l IH =>
        (opow_le_of_limit a0 l).2 fun b' h =>
          (IH _ h).trans (opow_le_opow_right ((Ordinal.pos_iff_ne_zero.2 a0).trans_le ab) h.le)
      
    

theorem left_le_opow (a : Ordinal) {b : Ordinal} (b1 : 0 < b) : a ≤ (a^b) := by
  nth_rw 0[← opow_one a]
  cases' le_or_gtₓ a 1 with a1 a1
  · cases' lt_or_eq_of_leₓ a1 with a0 a1
    · rw [lt_one_iff_zero] at a0
      rw [a0, zero_opow Ordinal.one_ne_zero]
      exact Ordinal.zero_le _
      
    rw [a1, one_opow, one_opow]
    
  rwa [opow_le_opow_iff_right a1, one_le_iff_pos]

theorem right_le_opow {a : Ordinal} (b) (a1 : 1 < a) : b ≤ (a^b) :=
  (opow_is_normal a1).self_le _

theorem opow_lt_opow_left_of_succ {a b c : Ordinal} (ab : a < b) : (a^succ c) < (b^succ c) := by
  rw [opow_succ, opow_succ]
  exact
    (mul_le_mul_right' (opow_le_opow_left c ab.le) a).trans_lt
      (mul_lt_mul_of_pos_left ab (opow_pos c ((Ordinal.zero_le a).trans_lt ab)))

theorem opow_add (a b c : Ordinal) : (a^b + c) = (a^b) * (a^c) := by
  rcases eq_or_ne a 0 with (rfl | a0)
  · rcases eq_or_ne c 0 with (rfl | c0)
    · simp
      
    have : b + c ≠ 0 := ((Ordinal.pos_iff_ne_zero.2 c0).trans_le (le_add_left _ _)).ne'
    simp only [zero_opow c0, zero_opow this, mul_zero]
    
  rcases eq_or_lt_of_leₓ (one_le_iff_ne_zero.2 a0) with (rfl | a1)
  · simp only [one_opow, mul_oneₓ]
    
  apply limit_rec_on c
  · simp
    
  · intro c IH
    rw [add_succ, opow_succ, IH, opow_succ, mul_assoc]
    
  · intro c l IH
    refine' eq_of_forall_ge_iffₓ fun d => (((opow_is_normal a1).trans (add_is_normal b)).limit_le l).trans _
    dsimp' only [Function.comp]
    simp (config := { contextual := true })only [IH]
    exact (((mul_is_normal <| opow_pos b (Ordinal.pos_iff_ne_zero.2 a0)).trans (opow_is_normal a1)).limit_le l).symm
    

theorem opow_one_add (a b : Ordinal) : (a^1 + b) = a * (a^b) := by
  rw [opow_add, opow_one]

theorem opow_dvd_opow (a) {b c : Ordinal} (h : b ≤ c) : (a^b) ∣ (a^c) := by
  rw [← Ordinal.add_sub_cancel_of_le h, opow_add]
  apply dvd_mul_right

theorem opow_dvd_opow_iff {a b c : Ordinal} (a1 : 1 < a) : (a^b) ∣ (a^c) ↔ b ≤ c :=
  ⟨fun h =>
    le_of_not_ltₓ fun hn =>
      not_le_of_ltₓ ((opow_lt_opow_iff_right a1).2 hn) <| le_of_dvd (opow_ne_zero _ <| one_le_iff_ne_zero.1 <| a1.le) h,
    opow_dvd_opow _⟩

theorem opow_mul (a b c : Ordinal) : (a^b * c) = ((a^b)^c) := by
  by_cases' b0 : b = 0
  · simp only [b0, zero_mul, opow_zero, one_opow]
    
  by_cases' a0 : a = 0
  · subst a
    by_cases' c0 : c = 0
    · simp only [c0, mul_zero, opow_zero]
      
    simp only [zero_opow b0, zero_opow c0, zero_opow (mul_ne_zero b0 c0)]
    
  cases' eq_or_lt_of_leₓ (one_le_iff_ne_zero.2 a0) with a1 a1
  · subst a1
    simp only [one_opow]
    
  apply limit_rec_on c
  · simp only [mul_zero, opow_zero]
    
  · intro c IH
    rw [mul_succ, opow_add, IH, opow_succ]
    
  · intro c l IH
    refine'
      eq_of_forall_ge_iffₓ fun d =>
        (((opow_is_normal a1).trans (mul_is_normal (Ordinal.pos_iff_ne_zero.2 b0))).limit_le l).trans _
    dsimp' only [Function.comp]
    simp (config := { contextual := true })only [IH]
    exact (opow_le_of_limit (opow_ne_zero _ a0) l).symm
    

/-! ### Ordinal logarithm -/


/-- The ordinal logarithm is the solution `u` to the equation `x = b ^ u * v + w` where `v < b` and
    `w < b ^ u`. -/
@[pp_nodot]
def log (b : Ordinal) (x : Ordinal) : Ordinal :=
  if h : 1 < b then pred (inf { o | x < (b^o) }) else 0

/-- The set in the definition of `log` is nonempty. -/
theorem log_nonempty {b x : Ordinal} (h : 1 < b) : { o | x < (b^o) }.Nonempty :=
  ⟨_, succ_le_iff.1 (right_le_opow _ h)⟩

theorem log_def {b : Ordinal} (h : 1 < b) (x : Ordinal) : log b x = pred (inf { o | x < (b^o) }) := by
  simp only [log, dif_pos h]

theorem log_of_not_one_lt_left {b : Ordinal} (h : ¬1 < b) (x : Ordinal) : log b x = 0 := by
  simp only [log, dif_neg h]

theorem log_of_left_le_one {b : Ordinal} (h : b ≤ 1) : ∀ x, log b x = 0 :=
  log_of_not_one_lt_left h.not_lt

@[simp]
theorem log_zero_left : ∀ b, log 0 b = 0 :=
  log_of_left_le_one zero_le_one

@[simp]
theorem log_zero_right (b : Ordinal) : log b 0 = 0 :=
  if b1 : 1 < b then by
    rw [log_def b1, ← Ordinal.le_zero, pred_le]
    apply cInf_le'
    dsimp'
    rw [succ_zero, opow_one]
    exact zero_lt_one.trans b1
  else by
    simp only [log_of_not_one_lt_left b1]

@[simp]
theorem log_one_left : ∀ b, log 1 b = 0 :=
  log_of_left_le_one le_rflₓ

theorem succ_log_def {b x : Ordinal} (hb : 1 < b) (hx : x ≠ 0) : succ (log b x) = inf { o | x < (b^o) } := by
  let t := Inf { o | x < (b^o) }
  have : x < (b^t) := Inf_mem (log_nonempty hb)
  rcases zero_or_succ_or_limit t with (h | h | h)
  · refine' ((one_le_iff_ne_zero.2 hx).not_lt _).elim
    simpa only [h, opow_zero]
    
  · rw [show log b x = pred t from log_def hb x, succ_pred_iff_is_succ.2 h]
    
  · rcases(lt_opow_of_limit (zero_lt_one.trans hb).ne' h).1 this with ⟨a, h₁, h₂⟩
    exact h₁.not_le.elim ((le_cInf_iff'' (log_nonempty hb)).1 le_rflₓ a h₂)
    

theorem lt_opow_succ_log_self {b : Ordinal} (hb : 1 < b) (x : Ordinal) : x < (b^succ (log b x)) := by
  rcases eq_or_ne x 0 with (rfl | hx)
  · apply opow_pos _ (zero_lt_one.trans hb)
    
  · rw [succ_log_def hb hx]
    exact Inf_mem (log_nonempty hb)
    

theorem opow_log_le_self (b) {x : Ordinal} (hx : x ≠ 0) : (b^log b x) ≤ x := by
  rcases eq_or_ne b 0 with (rfl | b0)
  · rw [zero_opow']
    refine' (sub_le_self _ _).trans (one_le_iff_ne_zero.2 hx)
    
  rcases lt_or_eq_of_leₓ (one_le_iff_ne_zero.2 b0) with (hb | rfl)
  · refine' le_of_not_ltₓ fun h => (lt_succ (log b x)).not_le _
    have := @cInf_le' _ _ { o | x < (b^o) } _ h
    rwa [← succ_log_def hb hx] at this
    
  · rwa [one_opow, one_le_iff_ne_zero]
    

/-- `opow b` and `log b` (almost) form a Galois connection. -/
theorem opow_le_iff_le_log {b x c : Ordinal} (hb : 1 < b) (hx : x ≠ 0) : (b^c) ≤ x ↔ c ≤ log b x :=
  ⟨fun h =>
    le_of_not_ltₓ fun hn =>
      (lt_opow_succ_log_self hb x).not_le <| ((opow_le_opow_iff_right hb).2 (succ_le_of_lt hn)).trans h,
    fun h => ((opow_le_opow_iff_right hb).2 h).trans (opow_log_le_self b hx)⟩

theorem lt_opow_iff_log_lt {b x c : Ordinal} (hb : 1 < b) (hx : x ≠ 0) : x < (b^c) ↔ log b x < c :=
  lt_iff_lt_of_le_iff_leₓ (opow_le_iff_le_log hb hx)

theorem log_pos {b o : Ordinal} (hb : 1 < b) (ho : o ≠ 0) (hbo : b ≤ o) : 0 < log b o := by
  rwa [← succ_le_iff, succ_zero, ← opow_le_iff_le_log hb ho, opow_one]

theorem log_eq_zero {b o : Ordinal} (hbo : o < b) : log b o = 0 := by
  rcases eq_or_ne o 0 with (rfl | ho)
  · exact log_zero_right b
    
  cases' le_or_ltₓ b 1 with hb hb
  · rcases le_one_iff.1 hb with (rfl | rfl)
    · exact log_zero_left o
      
    · exact log_one_left o
      
    
  · rwa [← Ordinal.le_zero, ← lt_succ_iff, succ_zero, ← lt_opow_iff_log_lt hb ho, opow_one]
    

@[mono]
theorem log_mono_right (b) {x y : Ordinal} (xy : x ≤ y) : log b x ≤ log b y :=
  if hx : x = 0 then by
    simp only [hx, log_zero_right, Ordinal.zero_le]
  else
    if hb : 1 < b then
      (opow_le_iff_le_log hb (lt_of_lt_of_leₓ (Ordinal.pos_iff_ne_zero.2 hx) xy).ne').1 <|
        (opow_log_le_self _ hx).trans xy
    else by
      simp only [log_of_not_one_lt_left hb, Ordinal.zero_le]

theorem log_le_self (b x : Ordinal) : log b x ≤ x :=
  if hx : x = 0 then by
    simp only [hx, log_zero_right, Ordinal.zero_le]
  else
    if hb : 1 < b then (right_le_opow _ hb).trans (opow_log_le_self b hx)
    else by
      simp only [log_of_not_one_lt_left hb, Ordinal.zero_le]

@[simp]
theorem log_one_right (b : Ordinal) : log b 1 = 0 :=
  if hb : 1 < b then log_eq_zero hb else log_of_not_one_lt_left hb 1

theorem mod_opow_log_lt_self (b : Ordinal) {o : Ordinal} (ho : o ≠ 0) : o % (b^log b o) < o := by
  rcases eq_or_ne b 0 with (rfl | hb)
  · simpa using Ordinal.pos_iff_ne_zero.2 ho
    
  · exact (mod_lt _ <| opow_ne_zero _ hb).trans_le (opow_log_le_self _ ho)
    

theorem log_mod_opow_log_lt_log_self {b o : Ordinal} (hb : 1 < b) (ho : o ≠ 0) (hbo : b ≤ o) :
    log b (o % (b^log b o)) < log b o := by
  cases eq_or_ne (o % (b^log b o)) 0
  · rw [h, log_zero_right]
    apply log_pos hb ho hbo
    
  · rw [← succ_le_iff, succ_log_def hb h]
    apply cInf_le'
    apply mod_lt
    rw [← Ordinal.pos_iff_ne_zero]
    exact opow_pos _ (zero_lt_one.trans hb)
    

theorem opow_mul_add_pos {b v : Ordinal} (hb : b ≠ 0) (u) (hv : v ≠ 0) (w) : 0 < (b^u) * v + w :=
  (opow_pos u <| Ordinal.pos_iff_ne_zero.2 hb).trans_le <|
    (le_mul_left _ <| Ordinal.pos_iff_ne_zero.2 hv).trans <| le_add_right _ _

theorem opow_mul_add_lt_opow_mul_succ {b u w : Ordinal} (v : Ordinal) (hw : w < (b^u)) :
    (b^u) * v + w < (b^u) * succ v := by
  rwa [mul_succ, add_lt_add_iff_left]

theorem opow_mul_add_lt_opow_succ {b u v w : Ordinal} (hvb : v < b) (hw : w < (b^u)) : (b^u) * v + w < (b^succ u) := by
  convert (opow_mul_add_lt_opow_mul_succ v hw).trans_le (mul_le_mul_left' (succ_le_of_lt hvb) _)
  exact opow_succ b u

theorem log_opow_mul_add {b u v w : Ordinal} (hb : 1 < b) (hv : v ≠ 0) (hvb : v < b) (hw : w < (b^u)) :
    log b ((b^u) * v + w) = u := by
  have hne' := (opow_mul_add_pos (zero_lt_one.trans hb).ne' u hv w).ne'
  by_contra' hne
  cases' lt_or_gt_of_neₓ hne with h h
  · rw [← lt_opow_iff_log_lt hb hne'] at h
    exact h.not_le ((le_mul_left _ (Ordinal.pos_iff_ne_zero.2 hv)).trans (le_add_right _ _))
    
  · change _ < _ at h
    rw [← succ_le_iff, ← opow_le_iff_le_log hb hne'] at h
    exact (not_lt_of_leₓ h) (opow_mul_add_lt_opow_succ hvb hw)
    

theorem log_opow {b : Ordinal} (hb : 1 < b) (x : Ordinal) : log b (b^x) = x := by
  convert log_opow_mul_add hb zero_ne_one.symm hb (opow_pos x (zero_lt_one.trans hb))
  rw [add_zeroₓ, mul_oneₓ]

theorem div_opow_log_lt {b : Ordinal} (o : Ordinal) (hb : 1 < b) : o / (b^log b o) < b := by
  rw [div_lt (opow_pos _ (zero_lt_one.trans hb)).ne', ← opow_succ]
  exact lt_opow_succ_log_self hb o

theorem add_log_le_log_mul {x y : Ordinal} (b : Ordinal) (hx : x ≠ 0) (hy : y ≠ 0) :
    log b x + log b y ≤ log b (x * y) := by
  by_cases' hb : 1 < b
  · rw [← opow_le_iff_le_log hb (mul_ne_zero hx hy), opow_add]
    exact mul_le_mul' (opow_log_le_self b hx) (opow_log_le_self b hy)
    
  simp only [log_of_not_one_lt_left hb, zero_addₓ]

/-! ### Casting naturals into ordinals, compatibility with operations -/


@[simp, norm_cast]
theorem nat_cast_mul (m : ℕ) : ∀ n : ℕ, ((m * n : ℕ) : Ordinal) = m * n
  | 0 => by
    simp
  | n + 1 => by
    rw [Nat.mul_succ, Nat.cast_addₓ, nat_cast_mul, Nat.cast_succₓ, mul_add_one]

@[simp, norm_cast]
theorem nat_cast_opow (m : ℕ) : ∀ n : ℕ, ((pow m n : ℕ) : Ordinal) = (m^n)
  | 0 => by
    simp
  | n + 1 => by
    rw [pow_succ'ₓ, nat_cast_mul, nat_cast_opow, Nat.cast_succₓ, add_one_eq_succ, opow_succ]

@[simp, norm_cast]
theorem nat_cast_le {m n : ℕ} : (m : Ordinal) ≤ n ↔ m ≤ n := by
  rw [← Cardinal.ord_nat, ← Cardinal.ord_nat, Cardinal.ord_le_ord, Cardinal.nat_cast_le]

@[simp, norm_cast]
theorem nat_cast_lt {m n : ℕ} : (m : Ordinal) < n ↔ m < n := by
  simp only [lt_iff_le_not_leₓ, nat_cast_le]

@[simp, norm_cast]
theorem nat_cast_inj {m n : ℕ} : (m : Ordinal) = n ↔ m = n := by
  simp only [le_antisymm_iffₓ, nat_cast_le]

@[simp, norm_cast]
theorem nat_cast_eq_zero {n : ℕ} : (n : Ordinal) = 0 ↔ n = 0 :=
  @nat_cast_inj n 0

theorem nat_cast_ne_zero {n : ℕ} : (n : Ordinal) ≠ 0 ↔ n ≠ 0 :=
  not_congr nat_cast_eq_zero

@[simp, norm_cast]
theorem nat_cast_pos {n : ℕ} : (0 : Ordinal) < n ↔ 0 < n :=
  @nat_cast_lt 0 n

@[simp, norm_cast]
theorem nat_cast_sub (m n : ℕ) : ((m - n : ℕ) : Ordinal) = m - n := by
  cases' le_totalₓ m n with h h
  · rw [tsub_eq_zero_iff_le.2 h, Ordinal.sub_eq_zero_iff_le.2 (nat_cast_le.2 h)]
    rfl
    
  · apply (add_left_cancelₓ n).1
    rw [← Nat.cast_addₓ, add_tsub_cancel_of_le h, Ordinal.add_sub_cancel_of_le (nat_cast_le.2 h)]
    

@[simp, norm_cast]
theorem nat_cast_div (m n : ℕ) : ((m / n : ℕ) : Ordinal) = m / n := by
  rcases eq_or_ne n 0 with (rfl | hn)
  · simp
    
  · have hn' := nat_cast_ne_zero.2 hn
    apply le_antisymmₓ
    · rw [le_div hn', ← nat_cast_mul, nat_cast_le, mul_comm]
      apply Nat.div_mul_le_selfₓ
      
    · rw [div_le hn', ← add_one_eq_succ, ← Nat.cast_succₓ, ← nat_cast_mul, nat_cast_lt, mul_comm, ←
        Nat.div_lt_iff_lt_mulₓ (Nat.pos_of_ne_zeroₓ hn)]
      apply Nat.lt_succ_selfₓ
      
    

@[simp, norm_cast]
theorem nat_cast_mod (m n : ℕ) : ((m % n : ℕ) : Ordinal) = m % n := by
  rw [← add_left_cancelₓ, div_add_mod, ← nat_cast_div, ← nat_cast_mul, ← Nat.cast_addₓ, Nat.div_add_modₓ]

@[simp]
theorem lift_nat_cast : ∀ n : ℕ, lift.{u, v} n = n
  | 0 => by
    simp
  | n + 1 => by
    simp [lift_nat_cast n]

end Ordinal

/-! ### Properties of `omega` -/


namespace Cardinal

open Ordinal

@[simp]
theorem ord_aleph_0 : ord.{u} ℵ₀ = ω :=
  le_antisymmₓ (ord_le.2 <| le_rflₓ) <|
    le_of_forall_ltₓ fun o h => by
      rcases Ordinal.lt_lift_iff.1 h with ⟨o, rfl, h'⟩
      rw [lt_ord, ← lift_card, ← lift_aleph_0.{0, u}, lift_lt, ← typein_enum (· < ·) h']
      exact lt_aleph_0_iff_fintype.2 ⟨Set.fintypeLtNat _⟩

@[simp]
theorem add_one_of_aleph_0_le {c} (h : ℵ₀ ≤ c) : c + 1 = c := by
  rw [add_commₓ, ← card_ord c, ← card_one, ← card_add, one_add_of_omega_le]
  rwa [← ord_aleph_0, ord_le_ord]

end Cardinal

namespace Ordinal

theorem lt_add_of_limit {a b c : Ordinal.{u}} (h : IsLimit c) : a < b + c ↔ ∃ c' < c, a < b + c' := by
  rw [← IsNormal.bsup_eq.{u, u} (add_is_normal b) h, lt_bsup]

theorem lt_omega {o : Ordinal} : o < ω ↔ ∃ n : ℕ, o = n := by
  simp_rw [← Cardinal.ord_aleph_0, Cardinal.lt_ord, lt_aleph_0, card_eq_nat]

theorem nat_lt_omega (n : ℕ) : ↑n < ω :=
  lt_omega.2 ⟨_, rfl⟩

theorem omega_pos : 0 < ω :=
  nat_lt_omega 0

theorem omega_ne_zero : ω ≠ 0 :=
  omega_pos.ne'

theorem one_lt_omega : 1 < ω := by
  simpa only [Nat.cast_oneₓ] using nat_lt_omega 1

theorem omega_is_limit : IsLimit ω :=
  ⟨omega_ne_zero, fun o h => by
    let ⟨n, e⟩ := lt_omega.1 h
    rw [e] <;> exact nat_lt_omega (n + 1)⟩

theorem omega_le {o : Ordinal} : ω ≤ o ↔ ∀ n : ℕ, ↑n ≤ o :=
  ⟨fun h n => (nat_lt_omega _).le.trans h, fun H =>
    le_of_forall_ltₓ fun a h => by
      let ⟨n, e⟩ := lt_omega.1 h
      rw [e, ← succ_le_iff] <;> exact H (n + 1)⟩

@[simp]
theorem sup_nat_cast : sup Nat.castₓ = ω :=
  (sup_le fun n => (nat_lt_omega n).le).antisymm <| omega_le.2 <| le_sup _

theorem nat_lt_limit {o} (h : IsLimit o) : ∀ n : ℕ, ↑n < o
  | 0 => lt_of_le_of_neₓ (Ordinal.zero_le o) h.1.symm
  | n + 1 => h.2 _ (nat_lt_limit n)

theorem omega_le_of_is_limit {o} (h : IsLimit o) : ω ≤ o :=
  omega_le.2 fun n => le_of_ltₓ <| nat_lt_limit h n

theorem is_limit_iff_omega_dvd {a : Ordinal} : IsLimit a ↔ a ≠ 0 ∧ ω ∣ a := by
  refine' ⟨fun l => ⟨l.1, ⟨a / ω, le_antisymmₓ _ (mul_div_le _ _)⟩⟩, fun h => _⟩
  · refine' (limit_le l).2 fun x hx => le_of_ltₓ _
    rw [← div_lt omega_ne_zero, ← succ_le_iff, le_div omega_ne_zero, mul_succ, add_le_of_limit omega_is_limit]
    intro b hb
    rcases lt_omega.1 hb with ⟨n, rfl⟩
    exact (add_le_add_right (mul_div_le _ _) _).trans (lt_sub.1 <| nat_lt_limit (sub_is_limit l hx) _).le
    
  · rcases h with ⟨a0, b, rfl⟩
    refine' mul_is_limit_left omega_is_limit (Ordinal.pos_iff_ne_zero.2 <| mt _ a0)
    intro e
    simp only [e, mul_zero]
    

theorem add_mul_limit_aux {a b c : Ordinal} (ba : b + a = a) (l : IsLimit c)
    (IH : ∀ c' < c, (a + b) * succ c' = a * succ c' + b) : (a + b) * c = a * c :=
  le_antisymmₓ
    ((mul_le_of_limit l).2 fun c' h => by
      apply (mul_le_mul_left' (le_succ c') _).trans
      rw [IH _ h]
      apply (add_le_add_left _ _).trans
      · rw [← mul_succ]
        exact mul_le_mul_left' (succ_le_of_lt <| l.2 _ h) _
        
      · infer_instance
        
      · rw [← ba]
        exact le_add_right _ _
        )
    (mul_le_mul_right' (le_add_right _ _) _)

theorem add_mul_succ {a b : Ordinal} (c) (ba : b + a = a) : (a + b) * succ c = a * succ c + b := by
  apply limit_rec_on c
  · simp only [succ_zero, mul_oneₓ]
    
  · intro c IH
    rw [mul_succ, IH, ← add_assocₓ, add_assocₓ _ b, ba, ← mul_succ]
    
  · intro c l IH
    have := add_mul_limit_aux ba l IH
    rw [mul_succ, add_mul_limit_aux ba l IH, mul_succ, add_assocₓ]
    

theorem add_mul_limit {a b c : Ordinal} (ba : b + a = a) (l : IsLimit c) : (a + b) * c = a * c :=
  add_mul_limit_aux ba l fun c' _ => add_mul_succ c' ba

theorem add_le_of_forall_add_lt {a b c : Ordinal} (hb : 0 < b) (h : ∀ d < b, a + d < c) : a + b ≤ c := by
  have H : a + (c - a) = c :=
    Ordinal.add_sub_cancel_of_le
      (by
        rw [← add_zeroₓ a]
        exact (h _ hb).le)
  rw [← H]
  apply add_le_add_left _ a
  by_contra' hb
  exact (h _ hb).Ne H

theorem IsNormal.apply_omega {f : Ordinal.{u} → Ordinal.{u}} (hf : IsNormal f) : sup.{0, u} (f ∘ Nat.castₓ) = f ω := by
  rw [← sup_nat_cast, IsNormal.sup.{0, u, u} hf]

@[simp]
theorem sup_add_nat (o : Ordinal) : (sup fun n : ℕ => o + n) = o + ω :=
  (add_is_normal o).apply_omega

@[simp]
theorem sup_mul_nat (o : Ordinal) : (sup fun n : ℕ => o * n) = o * ω := by
  rcases eq_zero_or_pos o with (rfl | ho)
  · rw [zero_mul]
    exact sup_eq_zero_iff.2 fun n => zero_mul n
    
  · exact (mul_is_normal ho).apply_omega
    

-- mathport name: ordinal.pow
local infixr:0 "^" => @pow Ordinal Ordinal Ordinal.hasPow

theorem sup_opow_nat {o : Ordinal} (ho : 0 < o) : (sup fun n : ℕ => o^n) = (o^ω) := by
  rcases lt_or_eq_of_leₓ (one_le_iff_pos.2 ho) with (ho₁ | rfl)
  · exact (opow_is_normal ho₁).apply_omega
    
  · rw [one_opow]
    refine'
      le_antisymmₓ
        (sup_le fun n => by
          rw [one_opow])
        _
    convert le_sup _ 0
    rw [Nat.cast_zeroₓ, opow_zero]
    

end Ordinal

