/-
Copyright (c) 2019 Amelia Livingston. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Amelia Livingston, Bryan Gin-ge Chen, Patrick Massot
-/
import Mathbin.Data.Fintype.Basic
import Mathbin.Data.Set.Finite
import Mathbin.Data.Setoid.Basic
import Mathbin.Order.Partition.Finpartition

/-!
# Equivalence relations: partitions

This file comprises properties of equivalence relations viewed as partitions.
There are two implementations of partitions here:
* A collection `c : set (set α)` of sets is a partition of `α` if `∅ ∉ c` and each element `a : α`
  belongs to a unique set `b ∈ c`. This is expressed as `is_partition c`
* An indexed partition is a map `s : ι → α` whose image is a partition. This is
  expressed as `indexed_partition s`.

Of course both implementations are related to `quotient` and `setoid`.

`setoid.is_partition.partition` and `finpartition.is_partition_parts` furnish
a link between `setoid.is_partition` and `finpartition`.

## TODO

Could the design of `finpartition` inform the one of `setoid.is_partition`? Maybe bundling it and
changing it from `set (set α)` to `set α` where `[lattice α] [order_bot α]` would make it more
usable.

## Tags

setoid, equivalence, iseqv, relation, equivalence relation, partition, equivalence class
-/


namespace Setoidₓ

variable {α : Type _}

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- If x ∈ α is in 2 elements of a set of sets partitioning α, those 2 sets are equal. -/
theorem eq_of_mem_eqv_class {c : Set (Set α)} (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) {x b b'} (hc : b ∈ c) (hb : x ∈ b)
    (hc' : b' ∈ c) (hb' : x ∈ b') : b = b' :=
  (H x).unique2 hc hb hc' hb'

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- Makes an equivalence relation from a set of sets partitioning α. -/
def mkClasses (c : Set (Set α)) (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) : Setoidₓ α :=
  ⟨fun x y => ∀ s ∈ c, x ∈ s → y ∈ s,
    ⟨fun _ _ _ hx => hx, fun x y h s hs hy =>
      (H x).elim2 fun t ht hx _ =>
        have : s = t := eq_of_mem_eqv_class H hs hy ht (h t ht hx)
        this.symm ▸ hx,
      fun x y z h1 h2 s hs hx =>
      (H y).elim2 fun t ht hy _ =>
        (H z).elim2 fun t' ht' hz _ =>
          have hst : s = t := eq_of_mem_eqv_class H hs (h1 _ hs hx) ht hy
          have htt' : t = t' := eq_of_mem_eqv_class H ht (h2 _ ht hy) ht' hz
          (hst.trans htt').symm ▸ hz⟩⟩

/-- Makes the equivalence classes of an equivalence relation. -/
def Classes (r : Setoidₓ α) : Set (Set α) :=
  { s | ∃ y, s = { x | r.Rel x y } }

theorem mem_classes (r : Setoidₓ α) (y) : { x | r.Rel x y } ∈ r.Classes :=
  ⟨y, rfl⟩

theorem classes_ker_subset_fiber_set {β : Type _} (f : α → β) :
    (Setoidₓ.ker f).Classes ⊆ Set.Range fun y => { x | f x = y } := by
  rintro s ⟨x, rfl⟩
  rw [Set.mem_range]
  exact ⟨f x, rfl⟩

theorem finite_classes_ker {α β : Type _} [Finite β] (f : α → β) : Finite (Setoidₓ.ker f).Classes := by
  classical
  exact Finite.Set.subset _ (classes_ker_subset_fiber_set f)

theorem card_classes_ker_le {α β : Type _} [Fintype β] (f : α → β) [Fintype (Setoidₓ.ker f).Classes] :
    Fintype.card (Setoidₓ.ker f).Classes ≤ Fintype.card β := by
  classical
  exact le_transₓ (Set.card_le_of_subset (classes_ker_subset_fiber_set f)) (Fintype.card_range_le _)

/-- Two equivalence relations are equal iff all their equivalence classes are equal. -/
theorem eq_iff_classes_eq {r₁ r₂ : Setoidₓ α} : r₁ = r₂ ↔ ∀ x, { y | r₁.Rel x y } = { y | r₂.Rel x y } :=
  ⟨fun h x => h ▸ rfl, fun h => ext' fun x => Set.ext_iff.1 <| h x⟩

theorem rel_iff_exists_classes (r : Setoidₓ α) {x y} : r.Rel x y ↔ ∃ c ∈ r.Classes, x ∈ c ∧ y ∈ c :=
  ⟨fun h => ⟨_, r.mem_classes y, h, r.refl' y⟩, fun ⟨c, ⟨z, hz⟩, hx, hy⟩ => by
    subst c
    exact r.trans' hx (r.symm' hy)⟩

/-- Two equivalence relations are equal iff their equivalence classes are equal. -/
theorem classes_inj {r₁ r₂ : Setoidₓ α} : r₁ = r₂ ↔ r₁.Classes = r₂.Classes :=
  ⟨fun h => h ▸ rfl, fun h =>
    ext' fun a b => by
      simp only [rel_iff_exists_classes, exists_prop, h]⟩

/-- The empty set is not an equivalence class. -/
theorem empty_not_mem_classes {r : Setoidₓ α} : ∅ ∉ r.Classes := fun ⟨y, hy⟩ =>
  Set.not_mem_empty y <| hy.symm ▸ r.refl' y

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » r.classes)
/-- Equivalence classes partition the type. -/
theorem classes_eqv_classes {r : Setoidₓ α} (a) : ∃! (b : _)(_ : b ∈ r.Classes), a ∈ b :=
  ExistsUnique.intro2 { x | r.Rel x a } (r.mem_classes a) (r.refl' _) <| by
    rintro _ ⟨y, rfl⟩ ha
    ext x
    exact ⟨fun hx => r.trans' hx (r.symm' ha), fun hx => r.trans' hx ha⟩

/-- If x ∈ α is in 2 equivalence classes, the equivalence classes are equal. -/
theorem eq_of_mem_classes {r : Setoidₓ α} {x b} (hc : b ∈ r.Classes) (hb : x ∈ b) {b'} (hc' : b' ∈ r.Classes)
    (hb' : x ∈ b') : b = b' :=
  eq_of_mem_eqv_class classes_eqv_classes hc hb hc' hb'

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- The elements of a set of sets partitioning α are the equivalence classes of the
    equivalence relation defined by the set of sets. -/
theorem eq_eqv_class_of_mem {c : Set (Set α)} (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) {s y} (hs : s ∈ c) (hy : y ∈ s) :
    s = { x | (mkClasses c H).Rel x y } :=
  Set.ext fun x =>
    ⟨fun hs' => (symm' (mkClasses c H)) fun b' hb' h' => eq_of_mem_eqv_class H hs hy hb' h' ▸ hs', fun hx =>
      (H x).elim2 fun b' hc' hb' h' => (eq_of_mem_eqv_class H hs hy hc' <| hx b' hc' hb').symm ▸ hb'⟩

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- The equivalence classes of the equivalence relation defined by a set of sets
    partitioning α are elements of the set of sets. -/
theorem eqv_class_mem {c : Set (Set α)} (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) {y} :
    { x | (mkClasses c H).Rel x y } ∈ c :=
  (H y).elim2 fun b hc hy hb => eq_eqv_class_of_mem H hc hy ▸ hc

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
theorem eqv_class_mem' {c : Set (Set α)} (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) {x} :
    { y : α | (mkClasses c H).Rel x y } ∈ c := by
  convert Setoidₓ.eqv_class_mem H
  ext
  rw [Setoidₓ.comm']

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- Distinct elements of a set of sets partitioning α are disjoint. -/
theorem eqv_classes_disjoint {c : Set (Set α)} (H : ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b) : c.PairwiseDisjoint id :=
  fun b₁ h₁ b₂ h₂ h =>
  Set.disjoint_left.2 fun x hx1 hx2 => (H x).elim2 fun b hc hx hb => h <| eq_of_mem_eqv_class H h₁ hx1 h₂ hx2

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- A set of disjoint sets covering α partition α (classical). -/
theorem eqv_classes_of_disjoint_union {c : Set (Set α)} (hu : Set.SUnion c = @Set.Univ α) (H : c.PairwiseDisjoint id)
    (a) : ∃! (b : _)(_ : b ∈ c), a ∈ b :=
  let ⟨b, hc, ha⟩ :=
    Set.mem_sUnion.1 <|
      show a ∈ _ by
        rw [hu] <;> exact Set.mem_univ a
  (ExistsUnique.intro2 b hc ha) fun b' hc' ha' => H.elim_set hc' hc a ha' ha

/-- Makes an equivalence relation from a set of disjoints sets covering α. -/
def setoidOfDisjointUnion {c : Set (Set α)} (hu : Set.SUnion c = @Set.Univ α) (H : c.PairwiseDisjoint id) : Setoidₓ α :=
  Setoidₓ.mkClasses c <| eqv_classes_of_disjoint_union hu H

/-- The equivalence relation made from the equivalence classes of an equivalence
    relation r equals r. -/
theorem mk_classes_classes (r : Setoidₓ α) : mkClasses r.Classes classes_eqv_classes = r :=
  ext' fun x y =>
    ⟨fun h => r.symm' (h { z | r.Rel z x } (r.mem_classes x) <| r.refl' x), fun h b hb hx =>
      eq_of_mem_classes (r.mem_classes x) (r.refl' x) hb hx ▸ r.symm' h⟩

@[simp]
theorem sUnion_classes (r : Setoidₓ α) : ⋃₀r.Classes = Set.Univ :=
  Set.eq_univ_of_forall fun x => Set.mem_sUnion.2 ⟨{ y | r.Rel y x }, ⟨x, rfl⟩, Setoidₓ.refl _⟩

section Partition

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (b «expr ∈ » c)
/-- A collection `c : set (set α)` of sets is a partition of `α` into pairwise
disjoint sets if `∅ ∉ c` and each element `a : α` belongs to a unique set `b ∈ c`. -/
def IsPartition (c : Set (Set α)) :=
  ∅ ∉ c ∧ ∀ a, ∃! (b : _)(_ : b ∈ c), a ∈ b

/-- A partition of `α` does not contain the empty set. -/
theorem nonempty_of_mem_partition {c : Set (Set α)} (hc : IsPartition c) {s} (h : s ∈ c) : s.Nonempty :=
  Set.ne_empty_iff_nonempty.1 fun hs0 => hc.1 <| hs0 ▸ h

theorem is_partition_classes (r : Setoidₓ α) : IsPartition r.Classes :=
  ⟨empty_not_mem_classes, classes_eqv_classes⟩

theorem IsPartition.pairwise_disjoint {c : Set (Set α)} (hc : IsPartition c) : c.PairwiseDisjoint id :=
  eqv_classes_disjoint hc.2

theorem IsPartition.sUnion_eq_univ {c : Set (Set α)} (hc : IsPartition c) : ⋃₀c = Set.Univ :=
  Set.eq_univ_of_forall fun x =>
    Set.mem_sUnion.2 <|
      let ⟨t, ht⟩ := hc.2 x
      ⟨t, by
        simp only [exists_unique_iff_exists] at ht
        tauto⟩

/-- All elements of a partition of α are the equivalence class of some y ∈ α. -/
theorem exists_of_mem_partition {c : Set (Set α)} (hc : IsPartition c) {s} (hs : s ∈ c) :
    ∃ y, s = { x | (mkClasses c hc.2).Rel x y } :=
  let ⟨y, hy⟩ := nonempty_of_mem_partition hc hs
  ⟨y, eq_eqv_class_of_mem hc.2 hs hy⟩

/-- The equivalence classes of the equivalence relation defined by a partition of α equal
    the original partition. -/
theorem classes_mk_classes (c : Set (Set α)) (hc : IsPartition c) : (mkClasses c hc.2).Classes = c :=
  Set.ext fun s =>
    ⟨fun ⟨y, hs⟩ =>
      (hc.2 y).elim2 fun b hm hb hy => by
        rwa
          [show s = b from
            hs.symm ▸
              Set.ext fun x =>
                ⟨fun hx => symm' (mk_classes c hc.2) hx b hm hb, fun hx b' hc' hx' =>
                  eq_of_mem_eqv_class hc.2 hm hx hc' hx' ▸ hb⟩],
      exists_of_mem_partition hc⟩

/-- Defining `≤` on partitions as the `≤` defined on their induced equivalence relations. -/
instance Partition.le : LE (Subtype (@IsPartition α)) :=
  ⟨fun x y => mkClasses x.1 x.2.2 ≤ mkClasses y.1 y.2.2⟩

/-- Defining a partial order on partitions as the partial order on their induced
    equivalence relations. -/
instance Partition.partialOrder : PartialOrderₓ (Subtype (@IsPartition α)) where
  le := (· ≤ ·)
  lt := fun x y => x ≤ y ∧ ¬y ≤ x
  le_refl := fun _ => @le_reflₓ (Setoidₓ α) _ _
  le_trans := fun _ _ _ => @le_transₓ (Setoidₓ α) _ _ _ _
  lt_iff_le_not_le := fun _ _ => Iff.rfl
  le_antisymm := fun x y hx hy => by
    let h := @le_antisymmₓ (Setoidₓ α) _ _ _ hx hy
    rw [Subtype.ext_iff_val, ← classes_mk_classes x.1 x.2, ← classes_mk_classes y.1 y.2, h]

variable (α)

/-- The order-preserving bijection between equivalence relations on a type `α`, and
  partitions of `α` into subsets. -/
protected def Partition.orderIso : Setoidₓ α ≃o { C : Set (Set α) // IsPartition C } where
  toFun := fun r => ⟨r.Classes, empty_not_mem_classes, classes_eqv_classes⟩
  invFun := fun C => mkClasses C.1 C.2.2
  left_inv := mk_classes_classes
  right_inv := fun C => by
    rw [Subtype.ext_iff_val, ← classes_mk_classes C.1 C.2]
  map_rel_iff' := fun r s => by
    conv_rhs => rw [← mk_classes_classes r, ← mk_classes_classes s]
    rfl

variable {α}

/-- A complete lattice instance for partitions; there is more infrastructure for the
    equivalent complete lattice on equivalence relations. -/
instance Partition.completeLattice : CompleteLattice (Subtype (@IsPartition α)) :=
  GaloisInsertion.liftCompleteLattice <|
    @OrderIso.toGaloisInsertion _ (Subtype (@IsPartition α)) _ (PartialOrderₓ.toPreorder _) <| Partition.orderIso α

end Partition

/-- A finite setoid partition furnishes a finpartition -/
@[simps]
def IsPartition.finpartition {c : Finset (Set α)} (hc : Setoidₓ.IsPartition (c : Set (Set α))) :
    Finpartition (Set.Univ : Set α) where
  parts := c
  SupIndep := Finset.sup_indep_iff_pairwise_disjoint.mpr <| eqv_classes_disjoint hc.2
  sup_parts := c.sup_id_set_eq_sUnion.trans hc.sUnion_eq_univ
  not_bot_mem := hc.left

end Setoidₓ

/-- A finpartition gives rise to a setoid partition -/
theorem Finpartition.is_partition_parts {α} (f : Finpartition (Set.Univ : Set α)) :
    Setoidₓ.IsPartition (f.parts : Set (Set α)) :=
  ⟨f.not_bot_mem,
    Setoidₓ.eqv_classes_of_disjoint_union (f.parts.sup_id_set_eq_sUnion.symm.trans f.sup_parts)
      f.SupIndep.PairwiseDisjoint⟩

/-- Constructive information associated with a partition of a type `α` indexed by another type `ι`,
`s : ι → set α`.

`indexed_partition.index` sends an element to its index, while `indexed_partition.some` sends
an index to an element of the corresponding set.

This type is primarily useful for definitional control of `s` - if this is not needed, then
`setoid.ker index` by itself may be sufficient. -/
structure IndexedPartition {ι α : Type _} (s : ι → Set α) where
  eq_of_mem : ∀ {x i j}, x ∈ s i → x ∈ s j → i = j
  some : ι → α
  some_mem : ∀ i, some i ∈ s i
  index : α → ι
  mem_index : ∀ x, x ∈ s (index x)

/-- The non-constructive constructor for `indexed_partition`. -/
noncomputable def IndexedPartition.mk' {ι α : Type _} (s : ι → Set α) (dis : ∀ i j, i ≠ j → Disjoint (s i) (s j))
    (nonempty : ∀ i, (s i).Nonempty) (ex : ∀ x, ∃ i, x ∈ s i) : IndexedPartition s where
  eq_of_mem := fun x i j hxi hxj => Classical.by_contradiction fun h => dis _ _ h ⟨hxi, hxj⟩
  some := fun i => (Nonempty i).some
  some_mem := fun i => (Nonempty i).some_spec
  index := fun x => (ex x).some
  mem_index := fun x => (ex x).some_spec

namespace IndexedPartition

open Set

variable {ι α : Type _} {s : ι → Set α} (hs : IndexedPartition s)

/-- On a unique index set there is the obvious trivial partition -/
instance [Unique ι] [Inhabited α] : Inhabited (IndexedPartition fun i : ι => (Set.Univ : Set α)) :=
  ⟨{ eq_of_mem := fun x i j hi hj => Subsingleton.elim _ _, some := default, some_mem := Set.mem_univ, index := default,
      mem_index := Set.mem_univ }⟩

attribute [simp] some_mem mem_index

include hs

theorem exists_mem (x : α) : ∃ i, x ∈ s i :=
  ⟨hs.index x, hs.mem_index x⟩

theorem Union : (⋃ i, s i) = univ := by
  ext x
  simp [hs.exists_mem x]

theorem disjoint : ∀ {i j}, i ≠ j → Disjoint (s i) (s j) := fun i j h x ⟨hxi, hxj⟩ => h (hs.eq_of_mem hxi hxj)

theorem mem_iff_index_eq {x i} : x ∈ s i ↔ hs.index x = i :=
  ⟨fun hxi => (hs.eq_of_mem hxi (hs.mem_index x)).symm, fun h => h ▸ hs.mem_index _⟩

theorem eq (i) : s i = { x | hs.index x = i } :=
  Set.ext fun _ => hs.mem_iff_index_eq

/-- The equivalence relation associated to an indexed partition. Two
elements are equivalent if they belong to the same set of the partition. -/
protected abbrev setoid (hs : IndexedPartition s) : Setoidₓ α :=
  Setoidₓ.ker hs.index

@[simp]
theorem index_some (i : ι) : hs.index (hs.some i) = i :=
  (mem_iff_index_eq _).1 <| hs.some_mem i

theorem some_index (x : α) : hs.Setoid.Rel (hs.some (hs.index x)) x :=
  hs.index_some (hs.index x)

/-- The quotient associated to an indexed partition. -/
protected def Quotient :=
  Quotientₓ hs.Setoid

/-- The projection onto the quotient associated to an indexed partition. -/
def proj : α → hs.Quotient :=
  Quotientₓ.mk'

instance [Inhabited α] : Inhabited hs.Quotient :=
  ⟨hs.proj default⟩

theorem proj_eq_iff {x y : α} : hs.proj x = hs.proj y ↔ hs.index x = hs.index y :=
  Quotientₓ.eq_rel

@[simp]
theorem proj_some_index (x : α) : hs.proj (hs.some (hs.index x)) = hs.proj x :=
  Quotientₓ.eq'.2 (hs.some_index x)

/-- The obvious equivalence between the quotient associated to an indexed partition and
the indexing type. -/
def equivQuotient : ι ≃ hs.Quotient :=
  (Setoidₓ.quotientKerEquivOfRightInverse hs.index hs.some <| hs.index_some).symm

@[simp]
theorem equiv_quotient_index_apply (x : α) : hs.equivQuotient (hs.index x) = hs.proj x :=
  hs.proj_eq_iff.mpr (some_index hs x)

@[simp]
theorem equiv_quotient_symm_proj_apply (x : α) : hs.equivQuotient.symm (hs.proj x) = hs.index x :=
  rfl

theorem equiv_quotient_index : hs.equivQuotient ∘ hs.index = hs.proj :=
  funext hs.equiv_quotient_index_apply

/-- A map choosing a representative for each element of the quotient associated to an indexed
partition. This is a computable version of `quotient.out'` using `indexed_partition.some`. -/
def out : hs.Quotient ↪ α :=
  hs.equivQuotient.symm.toEmbedding.trans ⟨hs.some, Function.LeftInverse.injective hs.index_some⟩

/-- This lemma is analogous to `quotient.mk_out'`. -/
@[simp]
theorem out_proj (x : α) : hs.out (hs.proj x) = hs.some (hs.index x) :=
  rfl

/-- The indices of `quotient.out'` and `indexed_partition.out` are equal. -/
theorem index_out' (x : hs.Quotient) : hs.index x.out' = hs.index (hs.out x) :=
  (Quotientₓ.induction_on' x) fun x => (Setoidₓ.ker_apply_mk_out' x).trans (hs.index_some _).symm

/-- This lemma is analogous to `quotient.out_eq'`. -/
@[simp]
theorem proj_out (x : hs.Quotient) : hs.proj (hs.out x) = x :=
  (Quotientₓ.induction_on' x) fun x => Quotientₓ.sound' <| hs.some_index x

theorem class_of {x : α} : SetOf (hs.Setoid.Rel x) = s (hs.index x) :=
  Set.ext fun y => eq_comm.trans hs.mem_iff_index_eq.symm

theorem proj_fiber (x : hs.Quotient) : hs.proj ⁻¹' {x} = s (hs.equivQuotient.symm x) :=
  (Quotientₓ.induction_on' x) fun x => by
    ext y
    simp only [Set.mem_preimage, Set.mem_singleton_iff, hs.mem_iff_index_eq]
    exact Quotientₓ.eq'

end IndexedPartition

