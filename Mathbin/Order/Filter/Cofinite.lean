/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Jeremy Avigad, Yury Kudryashov
-/
import Mathbin.Order.Filter.AtTopBot
import Mathbin.Order.Filter.Pi

/-!
# The cofinite filter

In this file we define

`cofinite`: the filter of sets with finite complement

and prove its basic properties. In particular, we prove that for `ℕ` it is equal to `at_top`.

## TODO

Define filters for other cardinalities of the complement.
-/


open Set Function

open Classical

variable {ι α β : Type _}

namespace Filter

/-- The cofinite filter is the filter of subsets whose complements are finite. -/
def cofinite : Filter α where
  Sets := { s | sᶜ.Finite }
  univ_sets := by
    simp only [compl_univ, finite_empty, mem_set_of_eq]
  sets_of_superset := fun s t (hs : sᶜ.Finite) (st : s ⊆ t) => hs.Subset <| compl_subset_compl.2 st
  inter_sets := fun s t (hs : sᶜ.Finite) (ht : tᶜ.Finite) => by
    simp only [compl_inter, finite.union, ht, hs, mem_set_of_eq]

@[simp]
theorem mem_cofinite {s : Set α} : s ∈ @cofinite α ↔ sᶜ.Finite :=
  Iff.rfl

@[simp]
theorem eventually_cofinite {p : α → Prop} : (∀ᶠ x in cofinite, p x) ↔ { x | ¬p x }.Finite :=
  Iff.rfl

theorem has_basis_cofinite : HasBasis cofinite (fun s : Set α => s.Finite) compl :=
  ⟨fun s => ⟨fun h => ⟨sᶜ, h, (compl_compl s).Subset⟩, fun ⟨t, htf, hts⟩ => htf.Subset <| compl_subset_comm.2 hts⟩⟩

instance cofinite_ne_bot [Infinite α] : NeBot (@cofinite α) :=
  has_basis_cofinite.ne_bot_iff.2 fun s hs => hs.infinite_compl.Nonempty

theorem frequently_cofinite_iff_infinite {p : α → Prop} : (∃ᶠ x in cofinite, p x) ↔ Set.Infinite { x | p x } := by
  simp only [Filter.Frequently, Filter.Eventually, mem_cofinite, compl_set_of, not_not, Set.Infinite]

theorem _root_.set.finite.compl_mem_cofinite {s : Set α} (hs : s.Finite) : sᶜ ∈ @cofinite α :=
  mem_cofinite.2 <| (compl_compl s).symm ▸ hs

theorem _root_.set.finite.eventually_cofinite_nmem {s : Set α} (hs : s.Finite) : ∀ᶠ x in cofinite, x ∉ s :=
  hs.compl_mem_cofinite

theorem _root_.finset.eventually_cofinite_nmem (s : Finset α) : ∀ᶠ x in cofinite, x ∉ s :=
  s.finite_to_set.eventually_cofinite_nmem

theorem _root_.set.infinite_iff_frequently_cofinite {s : Set α} : Set.Infinite s ↔ ∃ᶠ x in cofinite, x ∈ s :=
  frequently_cofinite_iff_infinite.symm

theorem eventually_cofinite_ne (x : α) : ∀ᶠ a in cofinite, a ≠ x :=
  (Set.finite_singleton x).eventually_cofinite_nmem

theorem le_cofinite_iff_compl_singleton_mem {l : Filter α} : l ≤ cofinite ↔ ∀ x, {x}ᶜ ∈ l := by
  refine' ⟨fun h x => h (finite_singleton x).compl_mem_cofinite, fun h s (hs : sᶜ.Finite) => _⟩
  rw [← compl_compl s, ← bUnion_of_singleton (sᶜ), compl_Union₂, Filter.bInter_mem hs]
  exact fun x _ => h x

theorem le_cofinite_iff_eventually_ne {l : Filter α} : l ≤ cofinite ↔ ∀ x, ∀ᶠ y in l, y ≠ x :=
  le_cofinite_iff_compl_singleton_mem

/-- If `α` is a preorder with no maximal element, then `at_top ≤ cofinite`. -/
theorem at_top_le_cofinite [Preorderₓ α] [NoMaxOrder α] : (atTop : Filter α) ≤ cofinite :=
  le_cofinite_iff_eventually_ne.mpr eventually_ne_at_top

theorem comap_cofinite_le (f : α → β) : comap f cofinite ≤ cofinite :=
  le_cofinite_iff_eventually_ne.mpr fun x =>
    mem_comap.2 ⟨{f x}ᶜ, (finite_singleton _).compl_mem_cofinite, fun y => ne_of_apply_ne f⟩

/-- The coproduct of the cofinite filters on two types is the cofinite filter on their product. -/
theorem coprod_cofinite : (cofinite : Filter α).coprod (cofinite : Filter β) = cofinite :=
  Filter.coext fun s => by
    simp only [compl_mem_coprod, mem_cofinite, compl_compl, finite_image_fst_and_snd_iff]

/-- Finite product of finite sets is finite -/
theorem Coprod_cofinite {α : ι → Type _} [Finite ι] : (Filter.coprodₓ fun i => (cofinite : Filter (α i))) = cofinite :=
  Filter.coext fun s => by
    simp only [compl_mem_Coprod, mem_cofinite, compl_compl, forall_finite_image_eval_iff]

end Filter

open Filter

/-- For natural numbers the filters `cofinite` and `at_top` coincide. -/
theorem Nat.cofinite_eq_at_top : @cofinite ℕ = at_top := by
  refine' le_antisymmₓ _ at_top_le_cofinite
  refine' at_top_basis.ge_iff.2 fun N hN => _
  simpa only [mem_cofinite, compl_Ici] using finite_lt_nat N

theorem Nat.frequently_at_top_iff_infinite {p : ℕ → Prop} : (∃ᶠ n in at_top, p n) ↔ Set.Infinite { n | p n } := by
  rw [← Nat.cofinite_eq_at_top, frequently_cofinite_iff_infinite]

theorem Filter.Tendsto.exists_within_forall_le {α β : Type _} [LinearOrderₓ β] {s : Set α} (hs : s.Nonempty) {f : α → β}
    (hf : Filter.Tendsto f Filter.cofinite Filter.atTop) : ∃ a₀ ∈ s, ∀ a ∈ s, f a₀ ≤ f a := by
  rcases em (∃ y ∈ s, ∃ x, f y < x) with (⟨y, hys, x, hx⟩ | not_all_top)
  · -- the set of points `{y | f y < x}` is nonempty and finite, so we take `min` over this set
    have : { y | ¬x ≤ f y }.Finite := filter.eventually_cofinite.mp (tendsto_at_top.1 hf x)
    simp only [not_leₓ] at this
    obtain ⟨a₀, ⟨ha₀ : f a₀ < x, ha₀s⟩, others_bigger⟩ := exists_min_image _ f (this.inter_of_left s) ⟨y, hx, hys⟩
    refine' ⟨a₀, ha₀s, fun a has => (lt_or_leₓ (f a) x).elim _ (le_transₓ ha₀.le)⟩
    exact fun h => others_bigger a ⟨h, has⟩
    
  · -- in this case, f is constant because all values are at top
    push_neg  at not_all_top
    obtain ⟨a₀, ha₀s⟩ := hs
    exact ⟨a₀, ha₀s, fun a ha => not_all_top a ha (f a₀)⟩
    

theorem Filter.Tendsto.exists_forall_le [Nonempty α] [LinearOrderₓ β] {f : α → β} (hf : Tendsto f cofinite atTop) :
    ∃ a₀, ∀ a, f a₀ ≤ f a :=
  let ⟨a₀, _, ha₀⟩ := hf.exists_within_forall_le univ_nonempty
  ⟨a₀, fun a => ha₀ a (mem_univ _)⟩

theorem Filter.Tendsto.exists_within_forall_ge [LinearOrderₓ β] {s : Set α} (hs : s.Nonempty) {f : α → β}
    (hf : Filter.Tendsto f Filter.cofinite Filter.atBot) : ∃ a₀ ∈ s, ∀ a ∈ s, f a ≤ f a₀ :=
  @Filter.Tendsto.exists_within_forall_le _ βᵒᵈ _ _ hs _ hf

theorem Filter.Tendsto.exists_forall_ge [Nonempty α] [LinearOrderₓ β] {f : α → β} (hf : Tendsto f cofinite atBot) :
    ∃ a₀, ∀ a, f a ≤ f a₀ :=
  @Filter.Tendsto.exists_forall_le _ βᵒᵈ _ _ _ hf

/-- For an injective function `f`, inverse images of finite sets are finite. See also
`filter.comap_cofinite_le` and `function.injective.comap_cofinite_eq`. -/
theorem Function.Injective.tendsto_cofinite {f : α → β} (hf : Injective f) : Tendsto f cofinite cofinite := fun s h =>
  h.Preimage (hf.InjOn _)

/-- The pullback of the `filter.cofinite` under an injective function is equal to `filter.cofinite`.
See also `filter.comap_cofinite_le` and `function.injective.tendsto_cofinite`. -/
theorem Function.Injective.comap_cofinite_eq {f : α → β} (hf : Injective f) : comap f cofinite = cofinite :=
  (comap_cofinite_le f).antisymm hf.tendsto_cofinite.le_comap

/-- An injective sequence `f : ℕ → ℕ` tends to infinity at infinity. -/
theorem Function.Injective.nat_tendsto_at_top {f : ℕ → ℕ} (hf : Injective f) : Tendsto f atTop atTop :=
  Nat.cofinite_eq_at_top ▸ hf.tendsto_cofinite

