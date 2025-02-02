/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl
-/
import Mathbin.Data.Multiset.Nodup

/-!
# The cartesian product of multisets
-/


namespace Multiset

section Pi

variable {α : Type _}

open Function

/-- Given `δ : α → Type*`, `pi.empty δ` is the trivial dependent function out of the empty
multiset. -/
def Pi.emptyₓ (δ : α → Type _) : ∀ a ∈ (0 : Multiset α), δ a :=
  fun.

variable [DecidableEq α] {δ : α → Type _}

/-- Given `δ : α → Type*`, a multiset `m` and a term `a`, as well as a term `b : δ a` and a
function `f` such that `f a' : δ a'` for all `a'` in `m`, `pi.cons m a b f` is a function `g` such
that `g a'' : δ a''` for all `a''` in `a ::ₘ m`. -/
def Pi.cons (m : Multiset α) (a : α) (b : δ a) (f : ∀ a ∈ m, δ a) : ∀ a' ∈ a ::ₘ m, δ a' := fun a' ha' =>
  if h : a' = a then Eq.ndrec b h.symm else f a' <| (mem_cons.1 ha').resolve_left h

theorem Pi.cons_same {m : Multiset α} {a : α} {b : δ a} {f : ∀ a ∈ m, δ a} (h : a ∈ a ::ₘ m) :
    Pi.cons m a b f a h = b :=
  dif_pos rfl

theorem Pi.cons_ne {m : Multiset α} {a a' : α} {b : δ a} {f : ∀ a ∈ m, δ a} (h' : a' ∈ a ::ₘ m) (h : a' ≠ a) :
    Pi.cons m a b f a' h' = f a' ((mem_cons.1 h').resolve_left h) :=
  dif_neg h

theorem Pi.cons_swap {a a' : α} {b : δ a} {b' : δ a'} {m : Multiset α} {f : ∀ a ∈ m, δ a} (h : a ≠ a') :
    HEq (Pi.cons (a' ::ₘ m) a b (Pi.cons m a' b' f)) (Pi.cons (a ::ₘ m) a' b' (Pi.cons m a b f)) := by
  apply hfunext rfl
  rintro a'' _ rfl
  refine'
    hfunext
      (by
        rw [cons_swap])
      fun ha₁ ha₂ _ => _
  rcases ne_or_eq a'' a with (h₁ | rfl)
  rcases eq_or_ne a'' a' with (rfl | h₂)
  all_goals
    simp [*, pi.cons_same, pi.cons_ne]

/-- `pi m t` constructs the Cartesian product over `t` indexed by `m`. -/
def pi (m : Multiset α) (t : ∀ a, Multiset (δ a)) : Multiset (∀ a ∈ m, δ a) :=
  m.recOn {Pi.emptyₓ δ} (fun a m (p : Multiset (∀ a ∈ m, δ a)) => (t a).bind fun b => p.map <| Pi.cons m a b)
    (by
      intro a a' m n
      by_cases' eq : a = a'
      · subst Eq
        
      · simp [map_bind, bind_bind (t a') (t a)]
        apply bind_hcongr
        · rw [cons_swap a a']
          
        intro b hb
        apply bind_hcongr
        · rw [cons_swap a a']
          
        intro b' hb'
        apply map_hcongr
        · rw [cons_swap a a']
          
        intro f hf
        exact pi.cons_swap Eq
        )

@[simp]
theorem pi_zero (t : ∀ a, Multiset (δ a)) : pi 0 t = {Pi.emptyₓ δ} :=
  rfl

@[simp]
theorem pi_cons (m : Multiset α) (t : ∀ a, Multiset (δ a)) (a : α) :
    pi (a ::ₘ m) t = (t a).bind fun b => (pi m t).map <| Pi.cons m a b :=
  rec_on_cons a m

theorem pi_cons_injective {a : α} {b : δ a} {s : Multiset α} (hs : a ∉ s) : Function.Injective (Pi.cons s a b) :=
  fun f₁ f₂ eq =>
  funext fun a' =>
    funext fun h' =>
      have ne : a ≠ a' := fun h => hs <| h.symm ▸ h'
      have : a' ∈ a ::ₘ s := mem_cons_of_mem h'
      calc
        f₁ a' h' = Pi.cons s a b f₁ a' this := by
          rw [pi.cons_ne this Ne.symm]
        _ = Pi.cons s a b f₂ a' this := by
          rw [Eq]
        _ = f₂ a' h' := by
          rw [pi.cons_ne this Ne.symm]
        

theorem card_pi (m : Multiset α) (t : ∀ a, Multiset (δ a)) : card (pi m t) = prod (m.map fun a => card (t a)) :=
  Multiset.induction_on m
    (by
      simp )
    (by
      simp (config := { contextual := true })[mul_comm])

protected theorem Nodup.pi {s : Multiset α} {t : ∀ a, Multiset (δ a)} :
    Nodup s → (∀ a ∈ s, Nodup (t a)) → Nodup (pi s t) :=
  Multiset.induction_on s (fun _ _ => nodup_singleton _)
    (by
      intro a s ih hs ht
      have has : a ∉ s := by
        simp at hs <;> exact hs.1
      have hs : nodup s := by
        simp at hs <;> exact hs.2
      simp
      refine' ⟨fun b hb => ((ih hs) fun a' h' => ht a' <| mem_cons_of_mem h').map (pi_cons_injective has), _⟩
      refine' (ht a <| mem_cons_self _ _).Pairwise _
      exact fun b₁ hb₁ b₂ hb₂ neb =>
        disjoint_map_map.2 fun f hf g hg eq =>
          have : pi.cons s a b₁ f a (mem_cons_self _ _) = pi.cons s a b₂ g a (mem_cons_self _ _) := by
            rw [Eq]
          neb <|
            show b₁ = b₂ by
              rwa [pi.cons_same, pi.cons_same] at this)

@[simp]
theorem pi.cons_ext {m : Multiset α} {a : α} (f : ∀ a' ∈ a ::ₘ m, δ a') :
    (Pi.cons m a (f _ (mem_cons_self _ _)) fun a' ha' => f a' (mem_cons_of_mem ha')) = f := by
  ext a' h'
  by_cases' a' = a
  · subst h
    rw [pi.cons_same]
    
  · rw [pi.cons_ne _ h]
    

theorem mem_pi (m : Multiset α) (t : ∀ a, Multiset (δ a)) :
    ∀ f : ∀ a ∈ m, δ a, f ∈ pi m t ↔ ∀ (a) (h : a ∈ m), f a h ∈ t a := by
  intro f
  induction' m using Multiset.induction_on with a m ih
  · simpa using
      show f = pi.empty δ by
        funext a ha <;> exact ha.elim
    
  simp_rw [pi_cons, mem_bind, mem_map, ih]
  constructor
  · rintro ⟨b, hb, f', hf', rfl⟩ a' ha'
    by_cases' a' = a
    · subst h
      rwa [pi.cons_same]
      
    · rw [pi.cons_ne _ h]
      apply hf'
      
    
  · intro hf
    refine' ⟨_, hf a (mem_cons_self _ _), _, fun a ha => hf a (mem_cons_of_mem ha), _⟩
    rw [pi.cons_ext]
    

end Pi

end Multiset

