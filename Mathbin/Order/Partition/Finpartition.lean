/-
Copyright (c) 2022 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import Mathbin.Algebra.BigOperators.Basic
import Mathbin.Order.Atoms
import Mathbin.Order.LocallyFinite
import Mathbin.Order.SupIndep

/-!
# Finite partitions

In this file, we define finite partitions. A finpartition of `a : α` is a finite set of pairwise
disjoint parts `parts : finset α` which does not contain `⊥` and whose supremum is `a`.

Finpartitions of a finset are at the heart of Szemerédi's regularity lemma. They are also studied
purely order theoretically in Sperner theory.

## Constructions

We provide many ways to build finpartitions:
* `finpartition.of_erase`: Builds a finpartition by erasing `⊥` for you.
* `finpartition.of_subset`: Builds a finpartition from a subset of the parts of a previous
  finpartition.
* `finpartition.empty`: The empty finpartition of `⊥`.
* `finpartition.indiscrete`: The indiscrete, aka trivial, aka pure, finpartition made of a single
  part.
* `finpartition.discrete`: The discrete finpartition of `s : finset α` made of singletons.
* `finpartition.bind`: Puts together the finpartitions of the parts of a finpartition into a new
  finpartition.
* `finpartition.atomise`: Makes a finpartition of `s : finset α` by breaking `s` along all finsets
  in `F : finset (finset α)`. Two elements of `s` belong to the same part iff they belong to the
  same elements of `F`.

`finpartition.indiscrete` and `finpartition.bind` together form the monadic structure of
`finpartition`.

## Implementation notes

Forbidding `⊥` as a part follows mathematical tradition and is a pragmatic choice concerning
operations on `finpartition`. Not caring about `⊥` being a part or not breaks extensionality (it's
not because the parts of `P` and the parts of `Q` have the same elements that `P = Q`). Enforcing
`⊥` to be a part makes `finpartition.bind` uglier and doesn't rid us of the need of
`finpartition.of_erase`.

## TODO

Link `finpartition` and `setoid.is_partition`.

The order is the wrong way around to make `finpartition a` a graded order. Is it bad to depart from
the literature and turn the order around?
-/


open Finset Function

open BigOperators

variable {α : Type _}

/-- A finite partition of `a : α` is a pairwise disjoint finite set of elements whose supremum is
`a`. We forbid `⊥` as a part. -/
@[ext]
structure Finpartition [Lattice α] [OrderBot α] (a : α) where
  parts : Finset α
  SupIndep : parts.SupIndep id
  sup_parts : parts.sup id = a
  not_bot_mem : ⊥ ∉ parts
  deriving DecidableEq

attribute [protected] Finpartition.sup_indep

namespace Finpartition

section Lattice

variable [Lattice α] [OrderBot α]

/-- A `finpartition` constructor which does not insist on `⊥` not being a part. -/
@[simps]
def ofErase [DecidableEq α] {a : α} (parts : Finset α) (sup_indep : parts.SupIndep id) (sup_parts : parts.sup id = a) :
    Finpartition a where
  parts := parts.erase ⊥
  SupIndep := sup_indep.Subset (erase_subset _ _)
  sup_parts := (sup_erase_bot _).trans sup_parts
  not_bot_mem := not_mem_erase _ _

/-- A `finpartition` constructor from a bigger existing finpartition. -/
@[simps]
def ofSubset {a b : α} (P : Finpartition a) {parts : Finset α} (subset : parts ⊆ P.parts)
    (sup_parts : parts.sup id = b) : Finpartition b :=
  { parts, SupIndep := P.SupIndep.Subset subset, sup_parts, not_bot_mem := fun h => P.not_bot_mem (subset h) }

/-- Changes the type of a finpartition to an equal one. -/
@[simps]
def copy {a b : α} (P : Finpartition a) (h : a = b) : Finpartition b where
  parts := P.parts
  SupIndep := P.SupIndep
  sup_parts := h ▸ P.sup_parts
  not_bot_mem := P.not_bot_mem

variable (α)

/-- The empty finpartition. -/
@[simps]
protected def empty : Finpartition (⊥ : α) where
  parts := ∅
  SupIndep := sup_indep_empty _
  sup_parts := Finset.sup_empty
  not_bot_mem := not_mem_empty ⊥

instance : Inhabited (Finpartition (⊥ : α)) :=
  ⟨Finpartition.empty α⟩

@[simp]
theorem default_eq_empty : (default : Finpartition (⊥ : α)) = Finpartition.empty α :=
  rfl

variable {α} {a : α}

/-- The finpartition in one part, aka indiscrete finpartition. -/
@[simps]
def indiscrete (ha : a ≠ ⊥) : Finpartition a where
  parts := {a}
  SupIndep := sup_indep_singleton _ _
  sup_parts := Finset.sup_singleton
  not_bot_mem := fun h => ha (mem_singleton.1 h).symm

variable (P : Finpartition a)

protected theorem le {b : α} (hb : b ∈ P.parts) : b ≤ a :=
  (le_sup hb).trans P.sup_parts.le

theorem ne_bot {b : α} (hb : b ∈ P.parts) : b ≠ ⊥ := fun h => P.not_bot_mem <| h.subst hb

protected theorem disjoint : (P.parts : Set α).PairwiseDisjoint id :=
  P.SupIndep.PairwiseDisjoint

variable {P}

theorem parts_eq_empty_iff : P.parts = ∅ ↔ a = ⊥ := by
  simp_rw [← P.sup_parts]
  refine' ⟨fun h => _, fun h => eq_empty_iff_forall_not_mem.2 fun b hb => P.not_bot_mem _⟩
  · rw [h]
    exact Finset.sup_empty
    
  · rwa [← le_bot_iff.1 ((le_sup hb).trans h.le)]
    

theorem parts_nonempty_iff : P.parts.Nonempty ↔ a ≠ ⊥ := by
  rw [nonempty_iff_ne_empty, not_iff_not, parts_eq_empty_iff]

theorem parts_nonempty (P : Finpartition a) (ha : a ≠ ⊥) : P.parts.Nonempty :=
  parts_nonempty_iff.2 ha

instance : Unique (Finpartition (⊥ : α)) :=
  { Finpartition.inhabited α with
    uniq := fun P => by
      ext a
      exact iff_of_false (fun h => P.ne_bot h <| le_bot_iff.1 <| P.le h) (not_mem_empty a) }

-- See note [reducible non instances]
/-- There's a unique partition of an atom. -/
@[reducible]
def _root_.is_atom.unique_finpartition (ha : IsAtom a) : Unique (Finpartition a) where
  default := indiscrete ha.1
  uniq := fun P => by
    have h : ∀ b ∈ P.parts, b = a := fun b hb => (ha.le_iff.mp <| P.le hb).resolve_left (P.ne_bot hb)
    ext b
    refine' Iff.trans ⟨h b, _⟩ mem_singleton.symm
    rintro rfl
    obtain ⟨c, hc⟩ := P.parts_nonempty ha.1
    simp_rw [← h c hc]
    exact hc

instance [Fintype α] [DecidableEq α] (a : α) : Fintype (Finpartition a) :=
  @Fintype.ofSurjective { p : Finset α // p.SupIndep id ∧ p.sup id = a ∧ ⊥ ∉ p } (Finpartition a) _ (Subtype.fintype _)
    (fun i => ⟨i.1, i.2.1, i.2.2.1, i.2.2.2⟩) fun ⟨_, y, z, w⟩ => ⟨⟨_, y, z, w⟩, rfl⟩

/-! ### Refinement order -/


section Order

/-- We say that `P ≤ Q` if `P` refines `Q`: each part of `P` is less than some part of `Q`. -/
instance : LE (Finpartition a) :=
  ⟨fun P Q => ∀ ⦃b⦄, b ∈ P.parts → ∃ c ∈ Q.parts, b ≤ c⟩

instance : PartialOrderₓ (Finpartition a) :=
  { Finpartition.hasLe with le_refl := fun P b hb => ⟨b, hb, le_rflₓ⟩,
    le_trans := fun P Q R hPQ hQR b hb => by
      obtain ⟨c, hc, hbc⟩ := hPQ hb
      obtain ⟨d, hd, hcd⟩ := hQR hc
      exact ⟨d, hd, hbc.trans hcd⟩,
    le_antisymm := fun P Q hPQ hQP => by
      ext b
      refine' ⟨fun hb => _, fun hb => _⟩
      · obtain ⟨c, hc, hbc⟩ := hPQ hb
        obtain ⟨d, hd, hcd⟩ := hQP hc
        rwa [hbc.antisymm]
        rwa [P.disjoint.eq_of_le hb hd (P.ne_bot hb) (hbc.trans hcd)]
        
      · obtain ⟨c, hc, hbc⟩ := hQP hb
        obtain ⟨d, hd, hcd⟩ := hPQ hc
        rwa [hbc.antisymm]
        rwa [Q.disjoint.eq_of_le hb hd (Q.ne_bot hb) (hbc.trans hcd)]
         }

instance [Decidable (a = ⊥)] : OrderTop (Finpartition a) where
  top := if ha : a = ⊥ then (Finpartition.empty α).copy ha.symm else indiscrete ha
  le_top := fun P => by
    split_ifs
    · intro x hx
      simpa [h, P.ne_bot hx] using P.le hx
      
    · exact fun b hb => ⟨a, mem_singleton_self _, P.le hb⟩
      

theorem parts_top_subset (a : α) [Decidable (a = ⊥)] : (⊤ : Finpartition a).parts ⊆ {a} := by
  intro b hb
  change b ∈ Finpartition.parts (dite _ _ _) at hb
  split_ifs  at hb
  · simp only [copy_parts, empty_parts, not_mem_empty] at hb
    exact hb.elim
    
  · exact hb
    

theorem parts_top_subsingleton (a : α) [Decidable (a = ⊥)] : ((⊤ : Finpartition a).parts : Set α).Subsingleton :=
  Set.subsingleton_of_subset_singleton fun b hb => mem_singleton.1 <| parts_top_subset _ hb

end Order

end Lattice

section DistribLattice

variable [DistribLattice α] [OrderBot α]

section Inf

variable [DecidableEq α] {a b c : α}

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
instance : HasInf (Finpartition a) :=
  ⟨fun P Q =>
    ofErase ((P.parts ×ˢ Q.parts).Image fun bc => bc.1⊓bc.2)
      (by
        rw [sup_indep_iff_disjoint_erase]
        simp only [mem_image, and_imp, exists_prop, forall_exists_index, id.def, Prod.existsₓ, mem_product,
          Finset.disjoint_sup_right, mem_erase, Ne.def]
        rintro _ x₁ y₁ hx₁ hy₁ rfl _ h x₂ y₂ hx₂ hy₂ rfl
        rcases eq_or_ne x₁ x₂ with (rfl | xdiff)
        · refine' Disjoint.mono inf_le_right inf_le_right (Q.disjoint hy₁ hy₂ _)
          intro t
          simpa [t] using h
          
        exact Disjoint.mono inf_le_left inf_le_left (P.disjoint hx₁ hx₂ xdiff))
      (by
        rw [sup_image, comp.left_id, sup_product_left]
        trans P.parts.sup id⊓Q.parts.sup id
        · simp_rw [Finset.sup_inf_distrib_right, Finset.sup_inf_distrib_left]
          rfl
          
        · rw [P.sup_parts, Q.sup_parts, inf_idem]
          )⟩

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
@[simp]
theorem parts_inf (P Q : Finpartition a) :
    (P⊓Q).parts = ((P.parts ×ˢ Q.parts).Image fun bc : α × α => bc.1⊓bc.2).erase ⊥ :=
  rfl

instance : SemilatticeInf (Finpartition a) :=
  { Finpartition.partialOrder, Finpartition.hasInf with
    inf_le_left := fun P Q b hb => by
      obtain ⟨c, hc, rfl⟩ := mem_image.1 (mem_of_mem_erase hb)
      rw [mem_product] at hc
      exact ⟨c.1, hc.1, inf_le_left⟩,
    inf_le_right := fun P Q b hb => by
      obtain ⟨c, hc, rfl⟩ := mem_image.1 (mem_of_mem_erase hb)
      rw [mem_product] at hc
      exact ⟨c.2, hc.2, inf_le_right⟩,
    le_inf := fun P Q R hPQ hPR b hb => by
      obtain ⟨c, hc, hbc⟩ := hPQ hb
      obtain ⟨d, hd, hbd⟩ := hPR hb
      have h := _root_.le_inf hbc hbd
      refine'
        ⟨c⊓d,
          mem_erase_of_ne_of_mem (ne_bot_of_le_ne_bot (P.ne_bot hb) h)
            (mem_image.2 ⟨(c, d), mem_product.2 ⟨hc, hd⟩, rfl⟩),
          h⟩ }

end Inf

theorem exists_le_of_le {a b : α} {P Q : Finpartition a} (h : P ≤ Q) (hb : b ∈ Q.parts) : ∃ c ∈ P.parts, c ≤ b := by
  by_contra' H
  refine' Q.ne_bot hb (disjoint_self.1 <| Disjoint.mono_right (Q.le hb) _)
  rw [← P.sup_parts, Finset.disjoint_sup_right]
  rintro c hc
  obtain ⟨d, hd, hcd⟩ := h hc
  refine' (Q.disjoint hb hd _).mono_right hcd
  rintro rfl
  exact H _ hc hcd

theorem card_mono {a : α} {P Q : Finpartition a} (h : P ≤ Q) : Q.parts.card ≤ P.parts.card := by
  classical
  have : ∀ b ∈ Q.parts, ∃ c ∈ P.parts, c ≤ b := fun b => exists_le_of_le h
  choose f hP hf using this
  rw [← card_attach]
  refine' card_le_card_of_inj_on (fun b => f _ b.2) (fun b _ => hP _ b.2) fun b hb c hc h => _
  exact
    Subtype.coe_injective
      ((Q.disjoint.elim b.2 c.2) fun H =>
        P.ne_bot (hP _ b.2) <| disjoint_self.1 <| H.mono (hf _ b.2) <| h.le.trans <| hf _ c.2)

variable [DecidableEq α] {a b c : α}

section Bind

variable {P : Finpartition a} {Q : ∀ i ∈ P.parts, Finpartition i}

/-- Given a finpartition `P` of `a` and finpartitions of each part of `P`, this yields the
finpartition of `a` obtained by juxtaposing all the subpartitions. -/
@[simps]
def bind (P : Finpartition a) (Q : ∀ i ∈ P.parts, Finpartition i) : Finpartition a where
  parts := P.parts.attach.bUnion fun i => (Q i.1 i.2).parts
  SupIndep := by
    rw [sup_indep_iff_pairwise_disjoint]
    rintro a ha b hb h
    rw [Finset.mem_coe, Finset.mem_bUnion] at ha hb
    obtain ⟨⟨A, hA⟩, -, ha⟩ := ha
    obtain ⟨⟨B, hB⟩, -, hb⟩ := hb
    obtain rfl | hAB := eq_or_ne A B
    · exact (Q A hA).Disjoint ha hb h
      
    · exact (P.disjoint hA hB hAB).mono ((Q A hA).le ha) ((Q B hB).le hb)
      
  sup_parts := by
    simp_rw [sup_bUnion, ← P.sup_parts]
    rw [eq_comm, ← Finset.sup_attach]
    exact sup_congr rfl fun b hb => (Q b.1 b.2).sup_parts.symm
  not_bot_mem := fun h => by
    rw [Finset.mem_bUnion] at h
    obtain ⟨⟨A, hA⟩, -, h⟩ := h
    exact (Q A hA).not_bot_mem h

theorem mem_bind : b ∈ (P.bind Q).parts ↔ ∃ A hA, b ∈ (Q A hA).parts := by
  rw [bind, mem_bUnion]
  constructor
  · rintro ⟨⟨A, hA⟩, -, h⟩
    exact ⟨A, hA, h⟩
    
  · rintro ⟨A, hA, h⟩
    exact ⟨⟨A, hA⟩, mem_attach _ ⟨A, hA⟩, h⟩
    

theorem card_bind (Q : ∀ i ∈ P.parts, Finpartition i) :
    (P.bind Q).parts.card = ∑ A in P.parts.attach, (Q _ A.2).parts.card := by
  apply card_bUnion
  rintro ⟨b, hb⟩ - ⟨c, hc⟩ - hbc d
  rw [inf_eq_inter, mem_inter]
  rintro ⟨hdb, hdc⟩
  rw [Ne.def, Subtype.mk_eq_mk] at hbc
  exact
    (Q b hb).ne_bot hdb (eq_bot_iff.2 <| (le_inf ((Q b hb).le hdb) <| (Q c hc).le hdc).trans <| P.disjoint hb hc hbc)

end Bind

/-- Adds `b` to a finpartition of `a` to make a finpartition of `a ⊔ b`. -/
@[simps]
def extend (P : Finpartition a) (hb : b ≠ ⊥) (hab : Disjoint a b) (hc : a⊔b = c) : Finpartition c where
  parts := insert b P.parts
  SupIndep := by
    rw [sup_indep_iff_pairwise_disjoint, coe_insert]
    exact P.disjoint.insert fun d hd hbd => hab.symm.mono_right <| P.le hd
  sup_parts := by
    rwa [sup_insert, P.sup_parts, id, _root_.sup_comm]
  not_bot_mem := fun h => (mem_insert.1 h).elim hb.symm P.not_bot_mem

theorem card_extend (P : Finpartition a) (b c : α) {hb : b ≠ ⊥} {hab : Disjoint a b} {hc : a⊔b = c} :
    (P.extend hb hab hc).parts.card = P.parts.card + 1 :=
  card_insert_of_not_mem fun h => hb <| hab.symm.eq_bot_of_le <| P.le h

end DistribLattice

section GeneralizedBooleanAlgebra

variable [GeneralizedBooleanAlgebra α] [DecidableEq α] {a b c : α} (P : Finpartition a)

/-- Restricts a finpartition to avoid a given element. -/
@[simps]
def avoid (b : α) : Finpartition (a \ b) :=
  ofErase (P.parts.Image (· \ b)) (P.Disjoint.image_finset_of_le fun a => sdiff_le).SupIndep
    (by
      rw [sup_image, comp.left_id, Finset.sup_sdiff_right, ← id_def, P.sup_parts])

@[simp]
theorem mem_avoid : c ∈ (P.avoid b).parts ↔ ∃ d ∈ P.parts, ¬d ≤ b ∧ d \ b = c := by
  simp only [avoid, of_erase_parts, mem_erase, Ne.def, mem_image, exists_prop, ← exists_and_distrib_left,
    @And.left_comm (c ≠ ⊥)]
  refine' exists_congr fun d => and_congr_right' <| and_congr_left _
  rintro rfl
  rw [sdiff_eq_bot_iff]

end GeneralizedBooleanAlgebra

end Finpartition

/-! ### Finite partitions of finsets -/


namespace Finpartition

variable [DecidableEq α] {s t : Finset α} (P : Finpartition s)

theorem nonempty_of_mem_parts {a : Finset α} (ha : a ∈ P.parts) : a.Nonempty :=
  nonempty_iff_ne_empty.2 <| P.ne_bot ha

theorem exists_mem {a : α} (ha : a ∈ s) : ∃ t ∈ P.parts, a ∈ t := by
  simp_rw [← P.sup_parts] at ha
  exact mem_sup.1 ha

theorem bUnion_parts : P.parts.bUnion id = s :=
  (sup_eq_bUnion _ _).symm.trans P.sup_parts

theorem sum_card_parts : (∑ i in P.parts, i.card) = s.card := by
  convert congr_argₓ Finset.card P.bUnion_parts
  rw [card_bUnion P.sup_indep.pairwise_disjoint]
  rfl

/-- `⊥` is the partition in singletons, aka discrete partition. -/
instance (s : Finset α) : HasBot (Finpartition s) :=
  ⟨{ parts := s.map ⟨singleton, singleton_injective⟩,
      SupIndep :=
        Set.PairwiseDisjoint.sup_indep
          (by
            rw [Finset.coe_map]
            exact finset.pairwise_disjoint_range_singleton.subset (Set.image_subset_range _ _)),
      sup_parts := by
        rw [sup_map, comp.left_id, embedding.coe_fn_mk, Finset.sup_singleton'],
      not_bot_mem := by
        simp }⟩

@[simp]
theorem parts_bot (s : Finset α) : (⊥ : Finpartition s).parts = s.map ⟨singleton, singleton_injective⟩ :=
  rfl

theorem card_bot (s : Finset α) : (⊥ : Finpartition s).parts.card = s.card :=
  Finset.card_map _

theorem mem_bot_iff : t ∈ (⊥ : Finpartition s).parts ↔ ∃ a ∈ s, {a} = t :=
  mem_map

instance (s : Finset α) : OrderBot (Finpartition s) :=
  { Finpartition.hasBot s with
    bot_le := fun P t ht => by
      rw [mem_bot_iff] at ht
      obtain ⟨a, ha, rfl⟩ := ht
      obtain ⟨t, ht, hat⟩ := P.exists_mem ha
      exact ⟨t, ht, singleton_subset_iff.2 hat⟩ }

theorem card_parts_le_card (P : Finpartition s) : P.parts.card ≤ s.card := by
  rw [← card_bot s]
  exact card_mono bot_le

section Atomise

/-- Cuts `s` along the finsets in `F`: Two elements of `s` will be in the same part if they are
in the same finsets of `F`. -/
def atomise (s : Finset α) (F : Finset (Finset α)) : Finpartition s :=
  ofErase (F.Powerset.Image fun Q => s.filter fun i => ∀ t ∈ F, t ∈ Q ↔ i ∈ t)
    (Set.PairwiseDisjoint.sup_indep fun x hx y hy h z hz =>
      h
        (by
          rw [mem_coe, mem_image] at hx hy
          obtain ⟨Q, hQ, rfl⟩ := hx
          obtain ⟨R, hR, rfl⟩ := hy
          suffices h : Q = R
          · subst h
            
          rw [id, id, inf_eq_inter, mem_inter, mem_filter, mem_filter] at hz
          rw [mem_powerset] at hQ hR
          ext i
          refine' ⟨fun hi => _, fun hi => _⟩
          · rwa [hz.2.2 _ (hQ hi), ← hz.1.2 _ (hQ hi)]
            
          · rwa [hz.1.2 _ (hR hi), ← hz.2.2 _ (hR hi)]
            ))
    (by
      refine' (Finset.sup_le fun t ht => _).antisymm fun a ha => _
      · rw [mem_image] at ht
        obtain ⟨A, hA, rfl⟩ := ht
        exact s.filter_subset _
        
      · rw [mem_sup]
        refine'
          ⟨s.filter fun i => ∀ t, t ∈ F → ((t ∈ F.filter fun u => a ∈ u) ↔ i ∈ t),
            mem_image_of_mem _ (mem_powerset.2 <| filter_subset _ _), mem_filter.2 ⟨ha, fun t ht => _⟩⟩
        rw [mem_filter]
        exact and_iff_right ht
        )

variable {F : Finset (Finset α)}

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (Q «expr ⊆ » F)
theorem mem_atomise :
    t ∈ (atomise s F).parts ↔ t.Nonempty ∧ ∃ (Q : _)(_ : Q ⊆ F), (s.filter fun i => ∀ u ∈ F, u ∈ Q ↔ i ∈ u) = t := by
  simp only [atomise, of_erase, bot_eq_empty, mem_erase, mem_image, nonempty_iff_ne_empty, mem_singleton, and_comm,
    mem_powerset, exists_prop]

theorem atomise_empty (hs : s.Nonempty) : (atomise s ∅).parts = {s} := by
  simp only [atomise, powerset_empty, image_singleton, not_mem_empty, IsEmpty.forall_iff, implies_true_iff, filter_true]
  exact erase_eq_of_not_mem (not_mem_singleton.2 hs.ne_empty.symm)

theorem card_atomise_le : (atomise s F).parts.card ≤ 2 ^ F.card :=
  (card_le_of_subset <| erase_subset _ _).trans <| Finset.card_image_le.trans (card_powerset _).le

theorem bUnion_filter_atomise (ht : t ∈ F) (hts : t ⊆ s) :
    ((atomise s F).parts.filter fun u => u ⊆ t ∧ u.Nonempty).bUnion id = t := by
  ext a
  refine' mem_bUnion.trans ⟨fun ⟨u, hu, ha⟩ => (mem_filter.1 hu).2.1 ha, fun ha => _⟩
  obtain ⟨u, hu, hau⟩ := (atomise s F).exists_mem (hts ha)
  refine' ⟨u, mem_filter.2 ⟨hu, fun b hb => _, _, hau⟩, hau⟩
  obtain ⟨Q, hQ, rfl⟩ := (mem_atomise.1 hu).2
  rw [mem_filter] at hau hb
  rwa [← hb.2 _ ht, hau.2 _ ht]

theorem card_filter_atomise_le_two_pow (ht : t ∈ F) :
    ((atomise s F).parts.filter fun u => u ⊆ t ∧ u.Nonempty).card ≤ 2 ^ (F.card - 1) := by
  suffices h :
    ((atomise s F).parts.filter fun u => u ⊆ t ∧ u.Nonempty) ⊆
      (F.erase t).Powerset.Image fun P => s.filter fun i => ∀ x ∈ F, x ∈ insert t P ↔ i ∈ x
  · refine' (card_le_of_subset h).trans (card_image_le.trans _)
    rw [card_powerset, card_erase_of_mem ht]
    
  rw [subset_iff]
  simp only [mem_erase, mem_sdiff, mem_powerset, mem_image, exists_prop, mem_filter, and_assoc, Finset.Nonempty,
    exists_imp_distrib, and_imp, mem_atomise, forall_apply_eq_imp_iff₂]
  rintro P' i hi P PQ rfl hy₂ j hj
  refine' ⟨P.erase t, erase_subset_erase _ PQ, _⟩
  simp only [insert_erase (((mem_filter.1 hi).2 _ ht).2 <| hy₂ hi), filter_congr_decidable]

end Atomise

end Finpartition

