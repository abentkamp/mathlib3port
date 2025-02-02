/-
Copyright (c) 2018 Sean Leather. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sean Leather, Mario Carneiro
-/
import Mathbin.Data.List.Alist
import Mathbin.Data.Finset.Basic
import Mathbin.Data.Part

/-!
# Finite maps over `multiset`
-/


universe u v w

open List

variable {α : Type u} {β : α → Type v}

/-! ### multisets of sigma types-/


namespace Multiset

/-- Multiset of keys of an association multiset. -/
def keys (s : Multiset (Sigma β)) : Multiset α :=
  s.map Sigma.fst

@[simp]
theorem coe_keys {l : List (Sigma β)} : keys (l : Multiset (Sigma β)) = (l.keys : Multiset α) :=
  rfl

/-- `nodupkeys s` means that `s` has no duplicate keys. -/
def Nodupkeys (s : Multiset (Sigma β)) : Prop :=
  Quot.liftOn s List.Nodupkeys fun s t p => propext <| perm_nodupkeys p

@[simp]
theorem coe_nodupkeys {l : List (Sigma β)} : @Nodupkeys α β l ↔ l.Nodupkeys :=
  Iff.rfl

end Multiset

/-! ### finmap -/


/-- `finmap β` is the type of finite maps over a multiset. It is effectively
  a quotient of `alist β` by permutation of the underlying list. -/
structure Finmap (β : α → Type v) : Type max u v where
  entries : Multiset (Sigma β)
  Nodupkeys : entries.Nodupkeys

/-- The quotient map from `alist` to `finmap`. -/
def Alist.toFinmap (s : Alist β) : Finmap β :=
  ⟨s.entries, s.Nodupkeys⟩

-- mathport name: to_finmap
local notation:arg "⟦" a "⟧" => Alist.toFinmap a

theorem Alist.to_finmap_eq {s₁ s₂ : Alist β} : ⟦s₁⟧ = ⟦s₂⟧ ↔ s₁.entries ~ s₂.entries := by
  cases s₁ <;> cases s₂ <;> simp [Alist.toFinmap]

@[simp]
theorem Alist.to_finmap_entries (s : Alist β) : ⟦s⟧.entries = s.entries :=
  rfl

/-- Given `l : list (sigma β)`, create a term of type `finmap β` by removing
entries with duplicate keys. -/
def List.toFinmap [DecidableEq α] (s : List (Sigma β)) : Finmap β :=
  s.toAlist.toFinmap

namespace Finmap

open Alist

/-! ### lifting from alist -/


/-- Lift a permutation-respecting function on `alist` to `finmap`. -/
@[elabAsElim]
def liftOn {γ} (s : Finmap β) (f : Alist β → γ) (H : ∀ a b : Alist β, a.entries ~ b.entries → f a = f b) : γ := by
  refine'
    (Quotientₓ.liftOn s.1 (fun l => (⟨_, fun nd => f ⟨l, nd⟩⟩ : Part γ)) fun l₁ l₂ p => Part.ext' (perm_nodupkeys p) _ :
          Part γ).get
      _
  · exact fun h₁ h₂ => H _ _ p
    
  · have := s.nodupkeys
    rcases s.entries with ⟨l⟩
    exact id
    

@[simp]
theorem lift_on_to_finmap {γ} (s : Alist β) (f : Alist β → γ) (H) : liftOn ⟦s⟧ f H = f s := by
  cases s <;> rfl

/-- Lift a permutation-respecting function on 2 `alist`s to 2 `finmap`s. -/
@[elabAsElim]
def liftOn₂ {γ} (s₁ s₂ : Finmap β) (f : Alist β → Alist β → γ)
    (H : ∀ a₁ b₁ a₂ b₂ : Alist β, a₁.entries ~ a₂.entries → b₁.entries ~ b₂.entries → f a₁ b₁ = f a₂ b₂) : γ :=
  liftOn s₁ (fun l₁ => liftOn s₂ (f l₁) fun b₁ b₂ p => H _ _ _ _ (Perm.refl _) p) fun a₁ a₂ p => by
    have H' : f a₁ = f a₂ := funext fun _ => H _ _ _ _ p (Perm.refl _)
    simp only [H']

@[simp]
theorem lift_on₂_to_finmap {γ} (s₁ s₂ : Alist β) (f : Alist β → Alist β → γ) (H) : liftOn₂ ⟦s₁⟧ ⟦s₂⟧ f H = f s₁ s₂ := by
  cases s₁ <;> cases s₂ <;> rfl

/-! ### induction -/


@[elabAsElim]
theorem induction_on {C : Finmap β → Prop} (s : Finmap β) (H : ∀ a : Alist β, C ⟦a⟧) : C s := by
  rcases s with ⟨⟨a⟩, h⟩ <;> exact H ⟨a, h⟩

@[elabAsElim]
theorem induction_on₂ {C : Finmap β → Finmap β → Prop} (s₁ s₂ : Finmap β) (H : ∀ a₁ a₂ : Alist β, C ⟦a₁⟧ ⟦a₂⟧) :
    C s₁ s₂ :=
  (induction_on s₁) fun l₁ => (induction_on s₂) fun l₂ => H l₁ l₂

@[elabAsElim]
theorem induction_on₃ {C : Finmap β → Finmap β → Finmap β → Prop} (s₁ s₂ s₃ : Finmap β)
    (H : ∀ a₁ a₂ a₃ : Alist β, C ⟦a₁⟧ ⟦a₂⟧ ⟦a₃⟧) : C s₁ s₂ s₃ :=
  (induction_on₂ s₁ s₂) fun l₁ l₂ => (induction_on s₃) fun l₃ => H l₁ l₂ l₃

/-! ### extensionality -/


@[ext]
theorem ext : ∀ {s t : Finmap β}, s.entries = t.entries → s = t
  | ⟨l₁, h₁⟩, ⟨l₂, h₂⟩, H => by
    congr

@[simp]
theorem ext_iff {s t : Finmap β} : s.entries = t.entries ↔ s = t :=
  ⟨ext, congr_argₓ _⟩

/-! ### mem -/


/-- The predicate `a ∈ s` means that `s` has a value associated to the key `a`. -/
instance : Membership α (Finmap β) :=
  ⟨fun a s => a ∈ s.entries.keys⟩

theorem mem_def {a : α} {s : Finmap β} : a ∈ s ↔ a ∈ s.entries.keys :=
  Iff.rfl

@[simp]
theorem mem_to_finmap {a : α} {s : Alist β} : a ∈ ⟦s⟧ ↔ a ∈ s :=
  Iff.rfl

/-! ### keys -/


/-- The set of keys of a finite map. -/
def keys (s : Finmap β) : Finset α :=
  ⟨s.entries.keys, induction_on s keys_nodup⟩

@[simp]
theorem keys_val (s : Alist β) : (keys ⟦s⟧).val = s.keys :=
  rfl

@[simp]
theorem keys_ext {s₁ s₂ : Alist β} : keys ⟦s₁⟧ = keys ⟦s₂⟧ ↔ s₁.keys ~ s₂.keys := by
  simp [keys, Alist.keys]

theorem mem_keys {a : α} {s : Finmap β} : a ∈ s.keys ↔ a ∈ s :=
  (induction_on s) fun s => Alist.mem_keys

/-! ### empty -/


/-- The empty map. -/
instance : EmptyCollection (Finmap β) :=
  ⟨⟨0, nodupkeys_nil⟩⟩

instance : Inhabited (Finmap β) :=
  ⟨∅⟩

@[simp]
theorem empty_to_finmap : (⟦∅⟧ : Finmap β) = ∅ :=
  rfl

@[simp]
theorem to_finmap_nil [DecidableEq α] : ([].toFinmap : Finmap β) = ∅ :=
  rfl

theorem not_mem_empty {a : α} : a ∉ (∅ : Finmap β) :=
  Multiset.not_mem_zero a

@[simp]
theorem keys_empty : (∅ : Finmap β).keys = ∅ :=
  rfl

/-! ### singleton -/


/-- The singleton map. -/
def singleton (a : α) (b : β a) : Finmap β :=
  ⟦Alist.singleton a b⟧

@[simp]
theorem keys_singleton (a : α) (b : β a) : (singleton a b).keys = {a} :=
  rfl

@[simp]
theorem mem_singleton (x y : α) (b : β y) : x ∈ singleton y b ↔ x = y := by
  simp only [singleton] <;> erw [mem_cons_eq, mem_nil_iff, or_falseₓ]

section

variable [DecidableEq α]

instance hasDecidableEq [∀ a, DecidableEq (β a)] : DecidableEq (Finmap β)
  | s₁, s₂ => decidableOfIff _ ext_iff

/-! ### lookup -/


/-- Look up the value associated to a key in a map. -/
def lookup (a : α) (s : Finmap β) : Option (β a) :=
  liftOn s (lookup a) fun s t => perm_lookup

@[simp]
theorem lookup_to_finmap (a : α) (s : Alist β) : lookup a ⟦s⟧ = s.lookup a :=
  rfl

@[simp]
theorem lookup_list_to_finmap (a : α) (s : List (Sigma β)) : lookup a s.toFinmap = s.lookup a := by
  rw [List.toFinmap, lookup_to_finmap, lookup_to_alist]

@[simp]
theorem lookup_empty (a) : lookup a (∅ : Finmap β) = none :=
  rfl

theorem lookup_is_some {a : α} {s : Finmap β} : (s.lookup a).isSome ↔ a ∈ s :=
  (induction_on s) fun s => Alist.lookup_is_some

theorem lookup_eq_none {a} {s : Finmap β} : lookup a s = none ↔ a ∉ s :=
  (induction_on s) fun s => Alist.lookup_eq_none

@[simp]
theorem lookup_singleton_eq {a : α} {b : β a} : (singleton a b).lookup a = some b := by
  rw [singleton, lookup_to_finmap, Alist.singleton, Alist.lookup, lookup_cons_eq]

instance (a : α) (s : Finmap β) : Decidable (a ∈ s) :=
  decidableOfIff _ lookup_is_some

theorem mem_iff {a : α} {s : Finmap β} : a ∈ s ↔ ∃ b, s.lookup a = some b :=
  (induction_on s) fun s => Iff.trans List.mem_keys <| exists_congr fun b => (mem_lookup_iff s.Nodupkeys).symm

theorem mem_of_lookup_eq_some {a : α} {b : β a} {s : Finmap β} (h : s.lookup a = some b) : a ∈ s :=
  mem_iff.mpr ⟨_, h⟩

theorem ext_lookup {s₁ s₂ : Finmap β} : (∀ x, s₁.lookup x = s₂.lookup x) → s₁ = s₂ :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ h => by
    simp only [Alist.lookup, lookup_to_finmap] at h
    rw [Alist.to_finmap_eq]
    apply lookup_ext s₁.nodupkeys s₂.nodupkeys
    intro x y
    rw [h]

/-! ### replace -/


/-- Replace a key with a given value in a finite map.
  If the key is not present it does nothing. -/
def replace (a : α) (b : β a) (s : Finmap β) : Finmap β :=
  (liftOn s fun t => ⟦replace a b t⟧) fun s₁ s₂ p => to_finmap_eq.2 <| perm_replace p

@[simp]
theorem replace_to_finmap (a : α) (b : β a) (s : Alist β) : replace a b ⟦s⟧ = ⟦s.replace a b⟧ := by
  simp [replace]

@[simp]
theorem keys_replace (a : α) (b : β a) (s : Finmap β) : (replace a b s).keys = s.keys :=
  (induction_on s) fun s => by
    simp

@[simp]
theorem mem_replace {a a' : α} {b : β a} {s : Finmap β} : a' ∈ replace a b s ↔ a' ∈ s :=
  (induction_on s) fun s => by
    simp

end

/-! ### foldl -/


/-- Fold a commutative function over the key-value pairs in the map -/
def foldl {δ : Type w} (f : δ → ∀ a, β a → δ) (H : ∀ d a₁ b₁ a₂ b₂, f (f d a₁ b₁) a₂ b₂ = f (f d a₂ b₂) a₁ b₁) (d : δ)
    (m : Finmap β) : δ :=
  m.entries.foldl (fun d s => f d s.1 s.2) (fun d s t => H _ _ _ _ _) d

/-- `any f s` returns `tt` iff there exists a value `v` in `s` such that `f v = tt`. -/
def any (f : ∀ x, β x → Bool) (s : Finmap β) : Bool :=
  s.foldl (fun x y z => x ∨ f y z)
    (by
      intros
      simp [Or.right_comm])
    false

/-- `all f s` returns `tt` iff `f v = tt` for all values `v` in `s`. -/
def all (f : ∀ x, β x → Bool) (s : Finmap β) : Bool :=
  s.foldl (fun x y z => x ∧ f y z)
    (by
      intros
      simp [And.right_comm])
    false

/-! ### erase -/


section

variable [DecidableEq α]

/-- Erase a key from the map. If the key is not present it does nothing. -/
def erase (a : α) (s : Finmap β) : Finmap β :=
  (liftOn s fun t => ⟦erase a t⟧) fun s₁ s₂ p => to_finmap_eq.2 <| perm_erase p

@[simp]
theorem erase_to_finmap (a : α) (s : Alist β) : erase a ⟦s⟧ = ⟦s.erase a⟧ := by
  simp [erase]

@[simp]
theorem keys_erase_to_finset (a : α) (s : Alist β) : keys ⟦s.erase a⟧ = (keys ⟦s⟧).erase a := by
  simp [Finset.erase, keys, Alist.erase, keys_kerase]

@[simp]
theorem keys_erase (a : α) (s : Finmap β) : (erase a s).keys = s.keys.erase a :=
  (induction_on s) fun s => by
    simp

@[simp]
theorem mem_erase {a a' : α} {s : Finmap β} : a' ∈ erase a s ↔ a' ≠ a ∧ a' ∈ s :=
  (induction_on s) fun s => by
    simp

theorem not_mem_erase_self {a : α} {s : Finmap β} : ¬a ∈ erase a s := by
  rw [mem_erase, not_and_distrib, not_not] <;> left <;> rfl

@[simp]
theorem lookup_erase (a) (s : Finmap β) : lookup a (erase a s) = none :=
  induction_on s <| lookup_erase a

@[simp]
theorem lookup_erase_ne {a a'} {s : Finmap β} (h : a ≠ a') : lookup a (erase a' s) = lookup a s :=
  (induction_on s) fun s => lookup_erase_ne h

theorem erase_erase {a a' : α} {s : Finmap β} : erase a (erase a' s) = erase a' (erase a s) :=
  (induction_on s) fun s =>
    ext
      (by
        simp only [erase_erase, erase_to_finmap])

/-! ### sdiff -/


/-- `sdiff s s'` consists of all key-value pairs from `s` and `s'` where the keys are in `s` or
`s'` but not both. -/
def sdiff (s s' : Finmap β) : Finmap β :=
  s'.foldl (fun s x _ => s.erase x) (fun a₀ a₁ _ a₂ _ => erase_erase) s

instance : Sdiff (Finmap β) :=
  ⟨sdiff⟩

/-! ### insert -/


/-- Insert a key-value pair into a finite map, replacing any existing pair with
  the same key. -/
def insert (a : α) (b : β a) (s : Finmap β) : Finmap β :=
  (liftOn s fun t => ⟦insert a b t⟧) fun s₁ s₂ p => to_finmap_eq.2 <| perm_insert p

@[simp]
theorem insert_to_finmap (a : α) (b : β a) (s : Alist β) : insert a b ⟦s⟧ = ⟦s.insert a b⟧ := by
  simp [insert]

theorem insert_entries_of_neg {a : α} {b : β a} {s : Finmap β} :
    a ∉ s → (insert a b s).entries = ⟨a, b⟩ ::ₘ s.entries :=
  (induction_on s) fun s h => by
    simp [insert_entries_of_neg (mt mem_to_finmap.1 h)]

@[simp]
theorem mem_insert {a a' : α} {b' : β a'} {s : Finmap β} : a ∈ insert a' b' s ↔ a = a' ∨ a ∈ s :=
  induction_on s mem_insert

@[simp]
theorem lookup_insert {a} {b : β a} (s : Finmap β) : lookup a (insert a b s) = some b :=
  (induction_on s) fun s => by
    simp only [insert_to_finmap, lookup_to_finmap, lookup_insert]

@[simp]
theorem lookup_insert_of_ne {a a'} {b : β a} (s : Finmap β) (h : a' ≠ a) : lookup a' (insert a b s) = lookup a' s :=
  (induction_on s) fun s => by
    simp only [insert_to_finmap, lookup_to_finmap, lookup_insert_ne h]

@[simp]
theorem insert_insert {a} {b b' : β a} (s : Finmap β) : (s.insert a b).insert a b' = s.insert a b' :=
  (induction_on s) fun s => by
    simp only [insert_to_finmap, insert_insert]

theorem insert_insert_of_ne {a a'} {b : β a} {b' : β a'} (s : Finmap β) (h : a ≠ a') :
    (s.insert a b).insert a' b' = (s.insert a' b').insert a b :=
  (induction_on s) fun s => by
    simp only [insert_to_finmap, Alist.to_finmap_eq, insert_insert_of_ne _ h]

theorem to_finmap_cons (a : α) (b : β a) (xs : List (Sigma β)) :
    List.toFinmap (⟨a, b⟩ :: xs) = insert a b xs.toFinmap :=
  rfl

theorem mem_list_to_finmap (a : α) (xs : List (Sigma β)) : a ∈ xs.toFinmap ↔ ∃ b : β a, Sigma.mk a b ∈ xs := by
  induction' xs with x xs <;> [skip, cases x] <;>
    simp only [to_finmap_cons, *, not_mem_empty, exists_or_distrib, not_mem_nil, to_finmap_nil, exists_false,
        mem_cons_iff, mem_insert, exists_and_distrib_left] <;>
      apply or_congr _ Iff.rfl
  conv => lhs rw [← and_trueₓ (a = x_fst)]
  apply and_congr_right
  rintro ⟨⟩
  simp only [exists_eq, iff_selfₓ, heq_iff_eq]

@[simp]
theorem insert_singleton_eq {a : α} {b b' : β a} : insert a b (singleton a b') = singleton a b := by
  simp only [singleton, Finmap.insert_to_finmap, Alist.insert_singleton_eq]

/-! ### extract -/


/-- Erase a key from the map, and return the corresponding value, if found. -/
def extract (a : α) (s : Finmap β) : Option (β a) × Finmap β :=
  (liftOn s fun t => Prod.map id toFinmap (extract a t)) fun s₁ s₂ p => by
    simp [perm_lookup p, to_finmap_eq, perm_erase p]

@[simp]
theorem extract_eq_lookup_erase (a : α) (s : Finmap β) : extract a s = (lookup a s, erase a s) :=
  (induction_on s) fun s => by
    simp [extract]

/-! ### union -/


/-- `s₁ ∪ s₂` is the key-based union of two finite maps. It is left-biased: if
there exists an `a ∈ s₁`, `lookup a (s₁ ∪ s₂) = lookup a s₁`. -/
def union (s₁ s₂ : Finmap β) : Finmap β :=
  (liftOn₂ s₁ s₂ fun s₁ s₂ => ⟦s₁ ∪ s₂⟧) fun s₁ s₂ s₃ s₄ p₁₃ p₂₄ => to_finmap_eq.mpr <| perm_union p₁₃ p₂₄

instance : Union (Finmap β) :=
  ⟨union⟩

@[simp]
theorem mem_union {a} {s₁ s₂ : Finmap β} : a ∈ s₁ ∪ s₂ ↔ a ∈ s₁ ∨ a ∈ s₂ :=
  (induction_on₂ s₁ s₂) fun _ _ => mem_union

@[simp]
theorem union_to_finmap (s₁ s₂ : Alist β) : ⟦s₁⟧ ∪ ⟦s₂⟧ = ⟦s₁ ∪ s₂⟧ := by
  simp [(· ∪ ·), union]

theorem keys_union {s₁ s₂ : Finmap β} : (s₁ ∪ s₂).keys = s₁.keys ∪ s₂.keys :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ =>
    Finset.ext <| by
      simp [keys]

@[simp]
theorem lookup_union_left {a} {s₁ s₂ : Finmap β} : a ∈ s₁ → lookup a (s₁ ∪ s₂) = lookup a s₁ :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ => lookup_union_left

@[simp]
theorem lookup_union_right {a} {s₁ s₂ : Finmap β} : a ∉ s₁ → lookup a (s₁ ∪ s₂) = lookup a s₂ :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ => lookup_union_right

theorem lookup_union_left_of_not_in {a} {s₁ s₂ : Finmap β} (h : a ∉ s₂) : lookup a (s₁ ∪ s₂) = lookup a s₁ := by
  by_cases' h' : a ∈ s₁
  · rw [lookup_union_left h']
    
  · rw [lookup_union_right h', lookup_eq_none.mpr h, lookup_eq_none.mpr h']
    

@[simp]
theorem mem_lookup_union {a} {b : β a} {s₁ s₂ : Finmap β} :
    b ∈ lookup a (s₁ ∪ s₂) ↔ b ∈ lookup a s₁ ∨ a ∉ s₁ ∧ b ∈ lookup a s₂ :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ => mem_lookup_union

theorem mem_lookup_union_middle {a} {b : β a} {s₁ s₂ s₃ : Finmap β} :
    b ∈ lookup a (s₁ ∪ s₃) → a ∉ s₂ → b ∈ lookup a (s₁ ∪ s₂ ∪ s₃) :=
  (induction_on₃ s₁ s₂ s₃) fun s₁ s₂ s₃ => mem_lookup_union_middle

theorem insert_union {a} {b : β a} {s₁ s₂ : Finmap β} : insert a b (s₁ ∪ s₂) = insert a b s₁ ∪ s₂ :=
  (induction_on₂ s₁ s₂) fun a₁ a₂ => by
    simp [insert_union]

theorem union_assoc {s₁ s₂ s₃ : Finmap β} : s₁ ∪ s₂ ∪ s₃ = s₁ ∪ (s₂ ∪ s₃) :=
  (induction_on₃ s₁ s₂ s₃) fun s₁ s₂ s₃ => by
    simp only [Alist.to_finmap_eq, union_to_finmap, Alist.union_assoc]

@[simp]
theorem empty_union {s₁ : Finmap β} : ∅ ∪ s₁ = s₁ :=
  (induction_on s₁) fun s₁ => by
    rw [← empty_to_finmap] <;> simp [-empty_to_finmap, Alist.to_finmap_eq, union_to_finmap, Alist.union_assoc]

@[simp]
theorem union_empty {s₁ : Finmap β} : s₁ ∪ ∅ = s₁ :=
  (induction_on s₁) fun s₁ => by
    rw [← empty_to_finmap] <;> simp [-empty_to_finmap, Alist.to_finmap_eq, union_to_finmap, Alist.union_assoc]

theorem erase_union_singleton (a : α) (b : β a) (s : Finmap β) (h : s.lookup a = some b) :
    s.erase a ∪ singleton a b = s :=
  ext_lookup fun x => by
    by_cases' h' : x = a
    · subst a
      rw [lookup_union_right not_mem_erase_self, lookup_singleton_eq, h]
      
    · have : x ∉ singleton a b := by
        rwa [mem_singleton]
      rw [lookup_union_left_of_not_in this, lookup_erase_ne h']
      

end

/-! ### disjoint -/


/-- `disjoint s₁ s₂` holds if `s₁` and `s₂` have no keys in common. -/
def Disjoint (s₁ s₂ : Finmap β) : Prop :=
  ∀ x ∈ s₁, ¬x ∈ s₂

theorem disjoint_empty (x : Finmap β) : Disjoint ∅ x :=
  fun.

@[symm]
theorem Disjoint.symm (x y : Finmap β) (h : Disjoint x y) : Disjoint y x := fun p hy hx => h p hx hy

theorem Disjoint.symm_iff (x y : Finmap β) : Disjoint x y ↔ Disjoint y x :=
  ⟨Disjoint.symm x y, Disjoint.symm y x⟩

section

variable [DecidableEq α]

instance : DecidableRel (@Disjoint α β) := fun x y => by
  dsimp' only [Disjoint] <;> infer_instance

theorem disjoint_union_left (x y z : Finmap β) : Disjoint (x ∪ y) z ↔ Disjoint x z ∧ Disjoint y z := by
  simp [Disjoint, Finmap.mem_union, or_imp_distrib, forall_and_distrib]

theorem disjoint_union_right (x y z : Finmap β) : Disjoint x (y ∪ z) ↔ Disjoint x y ∧ Disjoint x z := by
  rw [disjoint.symm_iff, disjoint_union_left, disjoint.symm_iff _ x, disjoint.symm_iff _ x]

theorem union_comm_of_disjoint {s₁ s₂ : Finmap β} : Disjoint s₁ s₂ → s₁ ∪ s₂ = s₂ ∪ s₁ :=
  (induction_on₂ s₁ s₂) fun s₁ s₂ => by
    intro h
    simp only [Alist.to_finmap_eq, union_to_finmap, Alist.union_comm_of_disjoint h]

theorem union_cancel {s₁ s₂ s₃ : Finmap β} (h : Disjoint s₁ s₃) (h' : Disjoint s₂ s₃) : s₁ ∪ s₃ = s₂ ∪ s₃ ↔ s₁ = s₂ :=
  ⟨fun h'' => by
    apply ext_lookup
    intro x
    have : (s₁ ∪ s₃).lookup x = (s₂ ∪ s₃).lookup x := h'' ▸ rfl
    by_cases' hs₁ : x ∈ s₁
    · rwa [lookup_union_left hs₁, lookup_union_left_of_not_in (h _ hs₁)] at this
      
    · by_cases' hs₂ : x ∈ s₂
      · rwa [lookup_union_left_of_not_in (h' _ hs₂), lookup_union_left hs₂] at this
        
      · rw [lookup_eq_none.mpr hs₁, lookup_eq_none.mpr hs₂]
        
      ,
    fun h => h ▸ rfl⟩

end

end Finmap

