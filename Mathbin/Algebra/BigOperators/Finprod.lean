import Mathbin.Algebra.BigOperators.Order 
import Mathbin.Algebra.IndicatorFunction

/-!
# Finite products and sums over types and sets

We define products and sums over types and subsets of types, with no finiteness hypotheses.
All infinite products and sums are defined to be junk values (i.e. one or zero).
This approach is sometimes easier to use than `finset.sum`,
when issues arise with `finset` and `fintype` being data.

## Main definitions

We use the following variables:

* `α`, `β` - types with no structure;
* `s`, `t` - sets
* `M`, `N` - additive or multiplicative commutative monoids
* `f`, `g` - functions

Definitions in this file:

* `finsum f : M` : the sum of `f x` as `x` ranges over the support of `f`, if it's finite.
   Zero otherwise.

* `finprod f : M` : the product of `f x` as `x` ranges over the multiplicative support of `f`, if
   it's finite. One otherwise.

## Notation

* `∑ᶠ i, f i` and `∑ᶠ i : α, f i` for `finsum f`

* `∏ᶠ i, f i` and `∏ᶠ i : α, f i` for `finprod f`

This notation works for functions `f : p → M`, where `p : Prop`, so the following works:

* `∑ᶠ i ∈ s, f i`, where `f : α → M`, `s : set α` : sum over the set `s`;
* `∑ᶠ n < 5, f n`, where `f : ℕ → M` : same as `f 0 + f 1 + f 2 + f 3 + f 4`;
* `∏ᶠ (n >= -2) (hn : n < 3), f n`, where `f : ℤ → M` : same as `f (-2) * f (-1) * f 0 * f 1 * f 2`.

## Implementation notes

`finsum` and `finprod` is "yet another way of doing finite sums and products in Lean". However
experiments in the wild (e.g. with matroids) indicate that it is a helpful approach in settings
where the user is not interested in computability and wants to do reasoning without running into
typeclass diamonds caused by the constructive finiteness used in definitions such as `finset` and
`fintype`. By sticking solely to `set.finite` we avoid these problems. We are aware that there are
other solutions but for beginner mathematicians this approach is easier in practice.

Another application is the construction of a partition of unity from a collection of “bump”
function. In this case the finite set depends on the point and it's convenient to have a definition
that does not mention the set explicitly.

The first arguments in all definitions and lemmas is the codomain of the function of the big
operator. This is necessary for the heuristic in `@[to_additive]`.
See the documentation of `to_additive.attr` for more information.

We did not add `is_finite (X : Type) : Prop`, because it is simply `nonempty (fintype X)`.

## Tags

finsum, finprod, finite sum, finite product
-/


open Function Set

/-!
### Definition and relation to `finset.sum` and `finset.prod`
-/


section Sort

variable {M N : Type _} {α β ι : Sort _} [CommMonoidₓ M] [CommMonoidₓ N]

open_locale BigOperators

section 

open_locale Classical

/-- Sum of `f x` as `x` ranges over the elements of the support of `f`, if it's finite. Zero
otherwise. -/
noncomputable irreducible_def finsum {M α} [AddCommMonoidₓ M] (f : α → M) : M :=
  if h : finite (support (f ∘ Plift.down)) then ∑ i in h.to_finset, f i.down else 0

/-- Product of `f x` as `x` ranges over the elements of the multiplicative support of `f`, if it's
finite. One otherwise. -/
@[toAdditive]
noncomputable irreducible_def finprod (f : α → M) : M :=
  if h : finite (mul_support (f ∘ Plift.down)) then ∏ i in h.to_finset, f i.down else 1

end 

localized [BigOperators] notation3 "∑ᶠ " (...) ", " r:(scoped f => finsum f) => r

localized [BigOperators] notation3 "∏ᶠ " (...) ", " r:(scoped f => finprod f) => r

@[toAdditive]
theorem finprod_eq_prod_plift_of_mul_support_to_finset_subset {f : α → M} (hf : finite (mul_support (f ∘ Plift.down)))
  {s : Finset (Plift α)} (hs : hf.to_finset ⊆ s) : (∏ᶠ i, f i) = ∏ i in s, f i.down :=
  by 
    rw [finprod, dif_pos]
    refine' Finset.prod_subset hs fun x hx hxf => _ 
    rwa [hf.mem_to_finset, nmem_mul_support] at hxf

@[toAdditive]
theorem finprod_eq_prod_plift_of_mul_support_subset {f : α → M} {s : Finset (Plift α)}
  (hs : mul_support (f ∘ Plift.down) ⊆ s) : (∏ᶠ i, f i) = ∏ i in s, f i.down :=
  finprod_eq_prod_plift_of_mul_support_to_finset_subset (s.finite_to_set.subset hs)$
    fun x hx =>
      by 
        rw [finite.mem_to_finset] at hx 
        exact hs hx

@[simp, toAdditive]
theorem finprod_one : (∏ᶠ i : α, (1 : M)) = 1 :=
  by 
    have  : (mul_support fun x : Plift α => (fun _ => 1 : α → M) x.down) ⊆ (∅ : Finset (Plift α))
    exact fun x h => h rfl 
    rw [finprod_eq_prod_plift_of_mul_support_subset this, Finset.prod_empty]

@[toAdditive]
theorem finprod_of_is_empty [IsEmpty α] (f : α → M) : (∏ᶠ i, f i) = 1 :=
  by 
    rw [←finprod_one]
    congr

@[simp, toAdditive]
theorem finprod_false (f : False → M) : (∏ᶠ i, f i) = 1 :=
  finprod_of_is_empty _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ≠ » a)
@[toAdditive]
theorem finprod_eq_single (f : α → M) (a : α) (ha : ∀ x _ : x ≠ a, f x = 1) : (∏ᶠ x, f x) = f a :=
  by 
    have  : mul_support (f ∘ Plift.down) ⊆ ({Plift.up a} : Finset (Plift α))
    ·
      intro x 
      contrapose 
      simpa [Plift.eq_up_iff_down_eq] using ha x.down 
    rw [finprod_eq_prod_plift_of_mul_support_subset this, Finset.prod_singleton]

@[toAdditive]
theorem finprod_unique [Unique α] (f : α → M) : (∏ᶠ i, f i) = f (default α) :=
  finprod_eq_single f (default α)$ fun x hx => (hx$ Unique.eq_default _).elim

@[simp, toAdditive]
theorem finprod_true (f : True → M) : (∏ᶠ i, f i) = f trivialₓ :=
  @finprod_unique M True _ ⟨⟨trivialₓ⟩, fun _ => rfl⟩ f

@[toAdditive]
theorem finprod_eq_dif {p : Prop} [Decidable p] (f : p → M) : (∏ᶠ i, f i) = if h : p then f h else 1 :=
  by 
    splitIfs
    ·
      have  : Unique p := ⟨⟨h⟩, fun _ => rfl⟩
      exact finprod_unique f
    ·
      have  : IsEmpty p := ⟨h⟩
      exact finprod_of_is_empty f

@[toAdditive]
theorem finprod_eq_if {p : Prop} [Decidable p] {x : M} : (∏ᶠ i : p, x) = if p then x else 1 :=
  finprod_eq_dif fun _ => x

@[toAdditive]
theorem finprod_congr {f g : α → M} (h : ∀ x, f x = g x) : finprod f = finprod g :=
  congr_argₓ _$ funext h

@[congr, toAdditive]
theorem finprod_congr_Prop {p q : Prop} {f : p → M} {g : q → M} (hpq : p = q) (hfg : ∀ h : q, f (hpq.mpr h) = g h) :
  finprod f = finprod g :=
  by 
    subst q 
    exact finprod_congr hfg

attribute [congr] finsum_congr_Prop

/-- To prove a property of a finite product, it suffices to prove that the property is
multiplicative and holds on multipliers. -/
@[toAdditive]
theorem finprod_induction {f : α → M} (p : M → Prop) (hp₀ : p 1) (hp₁ : ∀ x y, p x → p y → p (x*y))
  (hp₂ : ∀ i, p (f i)) : p (∏ᶠ i, f i) :=
  by 
    rw [finprod]
    splitIfs 
    exacts[Finset.prod_induction _ _ hp₁ hp₀ fun i hi => hp₂ _, hp₀]

/-- To prove a property of a finite sum, it suffices to prove that the property is
additive and holds on summands. -/
add_decl_doc finsum_induction

theorem finprod_nonneg {R : Type _} [OrderedCommSemiring R] {f : α → R} (hf : ∀ x, 0 ≤ f x) : 0 ≤ ∏ᶠ x, f x :=
  finprod_induction (fun x => 0 ≤ x) zero_le_one (fun x y => mul_nonneg) hf

@[toAdditive finsum_nonneg]
theorem one_le_finprod' {M : Type _} [OrderedCommMonoid M] {f : α → M} (hf : ∀ i, 1 ≤ f i) : 1 ≤ ∏ᶠ i, f i :=
  finprod_induction _ le_rfl (fun _ _ => one_le_mul) hf

@[toAdditive]
theorem MonoidHom.map_finprod_plift (f : M →* N) (g : α → M) (h : finite (mul_support$ g ∘ Plift.down)) :
  f (∏ᶠ x, g x) = ∏ᶠ x, f (g x) :=
  by 
    rw [finprod_eq_prod_plift_of_mul_support_subset h.coe_to_finset.ge, finprod_eq_prod_plift_of_mul_support_subset,
      f.map_prod]
    rw [h.coe_to_finset]
    exact mul_support_comp_subset f.map_one (g ∘ Plift.down)

@[toAdditive]
theorem MonoidHom.map_finprod_Prop {p : Prop} (f : M →* N) (g : p → M) : f (∏ᶠ x, g x) = ∏ᶠ x, f (g x) :=
  f.map_finprod_plift g (finite.of_fintype _)

@[toAdditive]
theorem MonoidHom.map_finprod_of_preimage_one (f : M →* N) (hf : ∀ x, f x = 1 → x = 1) (g : α → M) :
  f (∏ᶠ i, g i) = ∏ᶠ i, f (g i) :=
  by 
    byCases' hg : (mul_support$ g ∘ Plift.down).Finite
    ·
      exact f.map_finprod_plift g hg 
    rw [finprod, dif_neg, f.map_one, finprod, dif_neg]
    exacts[infinite.mono (fun x hx => mt (hf (g x.down)) hx) hg, hg]

@[toAdditive]
theorem MonoidHom.map_finprod_of_injective (g : M →* N) (hg : injective g) (f : α → M) :
  g (∏ᶠ i, f i) = ∏ᶠ i, g (f i) :=
  g.map_finprod_of_preimage_one (fun x => (hg.eq_iff' g.map_one).mp) f

@[toAdditive]
theorem MulEquiv.map_finprod (g : M ≃* N) (f : α → M) : g (∏ᶠ i, f i) = ∏ᶠ i, g (f i) :=
  g.to_monoid_hom.map_finprod_of_injective g.injective f

theorem finsum_smul {R M : Type _} [Ringₓ R] [AddCommGroupₓ M] [Module R M] [NoZeroSmulDivisors R M] (f : ι → R)
  (x : M) : (∑ᶠ i, f i) • x = ∑ᶠ i, f i • x :=
  by 
    rcases eq_or_ne x 0 with (rfl | hx)
    ·
      simp 
    exact ((smulAddHom R M).flip x).map_finsum_of_injective (smul_left_injective R hx) _

theorem smul_finsum {R M : Type _} [Ringₓ R] [AddCommGroupₓ M] [Module R M] [NoZeroSmulDivisors R M] (c : R)
  (f : ι → M) : (c • ∑ᶠ i, f i) = ∑ᶠ i, c • f i :=
  by 
    rcases eq_or_ne c 0 with (rfl | hc)
    ·
      simp 
    exact (smulAddHom R M c).map_finsum_of_injective (smul_right_injective M hc) _

@[toAdditive]
theorem finprod_inv_distrib {G : Type _} [CommGroupₓ G] (f : α → G) : (∏ᶠ x, f x⁻¹) = (∏ᶠ x, f x)⁻¹ :=
  ((MulEquiv.inv G).map_finprod f).symm

theorem finprod_inv_distrib₀ {G : Type _} [CommGroupWithZero G] (f : α → G) : (∏ᶠ x, f x⁻¹) = (∏ᶠ x, f x)⁻¹ :=
  ((MulEquiv.inv₀ G).map_finprod f).symm

end Sort

section Type

variable {α β ι M N : Type _} [CommMonoidₓ M] [CommMonoidₓ N]

open_locale BigOperators

@[toAdditive]
theorem finprod_eq_mul_indicator_apply (s : Set α) (f : α → M) (a : α) : (∏ᶠ h : a ∈ s, f a) = mul_indicator s f a :=
  by 
    convert finprod_eq_if

@[simp, toAdditive]
theorem finprod_mem_mul_support (f : α → M) (a : α) : (∏ᶠ h : f a ≠ 1, f a) = f a :=
  by 
    rw [←mem_mul_support, finprod_eq_mul_indicator_apply, mul_indicator_mul_support]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_def (s : Set α) (f : α → M) : (∏ᶠ (a : _)(_ : a ∈ s), f a) = ∏ᶠ a, mul_indicator s f a :=
  finprod_congr$ finprod_eq_mul_indicator_apply s f

@[toAdditive]
theorem finprod_eq_prod_of_mul_support_subset (f : α → M) {s : Finset α} (h : mul_support f ⊆ s) :
  (∏ᶠ i, f i) = ∏ i in s, f i :=
  by 
    have A : mul_support (f ∘ Plift.down) = equiv.plift.symm '' mul_support f
    ·
      rw [mul_support_comp_eq_preimage]
      exact (equiv.plift.symm.image_eq_preimage _).symm 
    have  : mul_support (f ∘ Plift.down) ⊆ s.map equiv.plift.symm.to_embedding
    ·
      rw [A, Finset.coe_map]
      exact image_subset _ h 
    rw [finprod_eq_prod_plift_of_mul_support_subset this]
    simp 

@[toAdditive]
theorem finprod_eq_prod_of_mul_support_to_finset_subset (f : α → M) (hf : finite (mul_support f)) {s : Finset α}
  (h : hf.to_finset ⊆ s) : (∏ᶠ i, f i) = ∏ i in s, f i :=
  finprod_eq_prod_of_mul_support_subset _$ fun x hx => h$ hf.mem_to_finset.2 hx

@[toAdditive]
theorem finprod_def (f : α → M) [Decidable (mul_support f).Finite] :
  (∏ᶠ i : α, f i) = if h : (mul_support f).Finite then ∏ i in h.to_finset, f i else 1 :=
  by 
    splitIfs
    ·
      exact finprod_eq_prod_of_mul_support_to_finset_subset _ h (Finset.Subset.refl _)
    ·
      rw [finprod, dif_neg]
      rw [mul_support_comp_eq_preimage]
      exact mt (fun hf => hf.of_preimage equiv.plift.surjective) h

@[toAdditive]
theorem finprod_of_infinite_mul_support {f : α → M} (hf : (mul_support f).Infinite) : (∏ᶠ i, f i) = 1 :=
  by 
    classical 
    rw [finprod_def, dif_neg hf]

@[toAdditive]
theorem finprod_eq_prod (f : α → M) (hf : (mul_support f).Finite) : (∏ᶠ i : α, f i) = ∏ i in hf.to_finset, f i :=
  by 
    classical 
    rw [finprod_def, dif_pos hf]

@[toAdditive]
theorem finprod_eq_prod_of_fintype [Fintype α] (f : α → M) : (∏ᶠ i : α, f i) = ∏ i, f i :=
  finprod_eq_prod_of_mul_support_to_finset_subset _ (finite.of_fintype _)$ Finset.subset_univ _

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
@[ toAdditive ]
  theorem
    finprod_cond_eq_prod_of_cond_iff
    ( f : α → M ) { p : α → Prop } { t : Finset α } ( h : ∀ { x } , f x ≠ 1 → p x ↔ x ∈ t )
      : ∏ᶠ ( i : _ ) ( hi : p i ) , f i = ∏ i in t , f i
    :=
      by
        set s := { x | p x }
          have : mul_support s.mul_indicator f ⊆ t
          · rw [ Set.mul_support_mul_indicator ] intro x hx exact h hx . 2 . 1 hx . 1
          erw [ finprod_mem_def , finprod_eq_prod_of_mul_support_subset _ this ]
          refine' Finset.prod_congr rfl fun x hx => mul_indicator_apply_eq_self . 2 $ fun hxs => _
          contrapose! hxs
          exact h hxs . 2 hx

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ≠ » a)
@[toAdditive]
theorem finprod_cond_ne (f : α → M) (a : α) [DecidableEq α] (hf : finite (mul_support f)) :
  (∏ᶠ (i : _)(_ : i ≠ a), f i) = ∏ i in hf.to_finset.erase a, f i :=
  by 
    apply finprod_cond_eq_prod_of_cond_iff 
    intro x hx 
    rw [Finset.mem_erase, finite.mem_to_finset, mem_mul_support]
    exact ⟨fun h => And.intro h hx, fun h => h.1⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_prod_of_inter_mul_support_eq (f : α → M) {s : Set α} {t : Finset α}
  (h : s ∩ mul_support f = t ∩ mul_support f) : (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in t, f i :=
  finprod_cond_eq_prod_of_cond_iff _$
    by 
      simpa [Set.ext_iff] using h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_prod_of_subset (f : α → M) {s : Set α} {t : Finset α} (h₁ : s ∩ mul_support f ⊆ t)
  (h₂ : ↑t ⊆ s) : (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in t, f i :=
  finprod_cond_eq_prod_of_cond_iff _$ fun x hx => ⟨fun h => h₁ ⟨h, hx⟩, fun h => h₂ h⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_prod (f : α → M) {s : Set α} (hf : (s ∩ mul_support f).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in hf.to_finset, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _$
    by 
      simp [inter_assoc]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_prod_filter (f : α → M) (s : Set α) [DecidablePred (· ∈ s)] (hf : (mul_support f).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in Finset.filter (· ∈ s) hf.to_finset, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _$
    by 
      simp [inter_comm, inter_left_comm]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_to_finset_prod (f : α → M) (s : Set α) [Fintype s] :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in s.to_finset, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _$
    by 
      rw [coe_to_finset]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_finite_to_finset_prod (f : α → M) {s : Set α} (hs : s.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in hs.to_finset, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _$
    by 
      rw [hs.coe_to_finset]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_finset_eq_prod (f : α → M) (s : Finset α) : (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ i in s, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _ rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » (s : set α))
@[toAdditive]
theorem finprod_mem_coe_finset (f : α → M) (s : Finset α) : (∏ᶠ (i : _)(_ : i ∈ (s : Set α)), f i) = ∏ i in s, f i :=
  finprod_mem_eq_prod_of_inter_mul_support_eq _ rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_eq_one_of_infinite {f : α → M} {s : Set α} (hs : (s ∩ mul_support f).Infinite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = 1 :=
  by 
    rw [finprod_mem_def]
    apply finprod_of_infinite_mul_support 
    rwa [←mul_support_mul_indicator] at hs

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∩ »(s, mul_support f))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_inter_mul_support (f : α → M) (s : Set α) :
  (∏ᶠ (i : _)(_ : i ∈ s ∩ mul_support f), f i) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  by 
    rw [finprod_mem_def, finprod_mem_def, mul_indicator_inter_mul_support]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
@[toAdditive]
theorem finprod_mem_inter_mul_support_eq (f : α → M) (s t : Set α) (h : s ∩ mul_support f = t ∩ mul_support f) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    rw [←finprod_mem_inter_mul_support, h, finprod_mem_inter_mul_support]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » mul_support f)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
@[toAdditive]
theorem finprod_mem_inter_mul_support_eq' (f : α → M) (s t : Set α) (h : ∀ x _ : x ∈ mul_support f, x ∈ s ↔ x ∈ t) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    apply finprod_mem_inter_mul_support_eq 
    ext x 
    exact and_congr_left (h x)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » @set.univ α)
@[toAdditive]
theorem finprod_mem_univ (f : α → M) : (∏ᶠ (i : _)(_ : i ∈ @Set.Univ α), f i) = ∏ᶠ i : α, f i :=
  finprod_congr$ fun i => finprod_true _

variable {f g : α → M} {a b : α} {s t : Set α}

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
@[toAdditive]
theorem finprod_mem_congr (h₀ : s = t) (h₁ : ∀ x _ : x ∈ t, f x = g x) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ᶠ (i : _)(_ : i ∈ t), g i :=
  h₀.symm ▸ (finprod_congr$ fun i => finprod_congr_Prop rfl (h₁ i))

/-!
### Distributivity w.r.t. addition, subtraction, and (scalar) multiplication
-/


/-- If the multiplicative supports of `f` and `g` are finite, then the product of `f i * g i` equals
the product of `f i` multiplied by the product over `g i`. -/
@[toAdditive]
theorem finprod_mul_distrib (hf : (mul_support f).Finite) (hg : (mul_support g).Finite) :
  (∏ᶠ i, f i*g i) = (∏ᶠ i, f i)*∏ᶠ i, g i :=
  by 
    classical 
    rw [finprod_eq_prod_of_mul_support_to_finset_subset _ hf (Finset.subset_union_left _ _),
      finprod_eq_prod_of_mul_support_to_finset_subset _ hg (Finset.subset_union_right _ _), ←Finset.prod_mul_distrib]
    refine' finprod_eq_prod_of_mul_support_subset _ _ 
    simp [mul_support_mul]

/-- If the multiplicative supports of `f` and `g` are finite, then the product of `f i / g i`
equals the product of `f i` divided by the product over `g i`. -/
@[toAdditive]
theorem finprod_div_distrib {G : Type _} [CommGroupₓ G] {f g : α → G} (hf : (mul_support f).Finite)
  (hg : (mul_support g).Finite) : (∏ᶠ i, f i / g i) = (∏ᶠ i, f i) / ∏ᶠ i, g i :=
  by 
    simp only [div_eq_mul_inv, finprod_mul_distrib hf ((mul_support_inv g).symm.rec hg), finprod_inv_distrib]

theorem finprod_div_distrib₀ {G : Type _} [CommGroupWithZero G] {f g : α → G} (hf : (mul_support f).Finite)
  (hg : (mul_support g).Finite) : (∏ᶠ i, f i / g i) = (∏ᶠ i, f i) / ∏ᶠ i, g i :=
  by 
    simp only [div_eq_mul_inv, finprod_mul_distrib hf ((mul_support_inv₀ g).symm.rec hg), finprod_inv_distrib₀]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- A more general version of `finprod_mem_mul_distrib` that requires `s ∩ mul_support f` and
`s ∩ mul_support g` instead of `s` to be finite. -/
@[toAdditive]
theorem finprod_mem_mul_distrib' (hf : (s ∩ mul_support f).Finite) (hg : (s ∩ mul_support g).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i*g i) = (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ s), g i :=
  by 
    rw [←mul_support_mul_indicator] at hf hg 
    simp only [finprod_mem_def, mul_indicator_mul, finprod_mul_distrib hf hg]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- The product of constant one over any set equals one. -/
@[toAdditive]
theorem finprod_mem_one (s : Set α) : (∏ᶠ (i : _)(_ : i ∈ s), (1 : M)) = 1 :=
  by 
    simp 

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- If a function `f` equals one on a set `s`, then the product of `f i` over `i ∈ s` equals one. -/
@[toAdditive]
theorem finprod_mem_of_eq_on_one (hf : eq_on f 1 s) : (∏ᶠ (i : _)(_ : i ∈ s), f i) = 1 :=
  by 
    rw [←finprod_mem_one s]
    exact finprod_mem_congr rfl hf

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
/-- If the product of `f i` over `i ∈ s` is not equal to one, then there is some `x ∈ s`
such that `f x ≠ 1`. -/
@[toAdditive]
theorem exists_ne_one_of_finprod_mem_ne_one (h : (∏ᶠ (i : _)(_ : i ∈ s), f i) ≠ 1) : ∃ (x : _)(_ : x ∈ s), f x ≠ 1 :=
  by 
    byContra h' 
    pushNeg  at h' 
    exact h (finprod_mem_of_eq_on_one h')

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- Given a finite set `s`, the product of `f i * g i` over `i ∈ s` equals the product of `f i`
over `i ∈ s` times the product of `g i` over `i ∈ s`. -/
@[toAdditive]
theorem finprod_mem_mul_distrib (hs : s.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i*g i) = (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ s), g i :=
  finprod_mem_mul_distrib' (hs.inter_of_left _) (hs.inter_of_left _)

@[toAdditive]
theorem MonoidHom.map_finprod {f : α → M} (g : M →* N) (hf : (mul_support f).Finite) : g (∏ᶠ i, f i) = ∏ᶠ i, g (f i) :=
  g.map_finprod_plift f$ hf.preimage$ Equivₓ.plift.Injective.InjOn _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- A more general version of `monoid_hom.map_finprod_mem` that requires `s ∩ mul_support f` and
  instead of `s` to be finite. -/
@[toAdditive]
theorem MonoidHom.map_finprod_mem' {f : α → M} (g : M →* N) (h₀ : (s ∩ mul_support f).Finite) :
  g (∏ᶠ (j : _)(_ : j ∈ s), f j) = ∏ᶠ (i : _)(_ : i ∈ s), g (f i) :=
  by 
    rw [g.map_finprod]
    ·
      simp only [g.map_finprod_Prop]
    ·
      simpa only [finprod_eq_mul_indicator_apply, mul_support_mul_indicator]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- Given a monoid homomorphism `g : M →* N`, and a function `f : α → M`, the value of `g` at the
product of `f i` over `i ∈ s` equals the product of `(g ∘ f) i` over `s`. -/
@[toAdditive]
theorem MonoidHom.map_finprod_mem (f : α → M) (g : M →* N) (hs : s.finite) :
  g (∏ᶠ (j : _)(_ : j ∈ s), f j) = ∏ᶠ (i : _)(_ : i ∈ s), g (f i) :=
  g.map_finprod_mem' (hs.inter_of_left _)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem MulEquiv.map_finprod_mem (g : M ≃* N) (f : α → M) {s : Set α} (hs : s.finite) :
  g (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ᶠ (i : _)(_ : i ∈ s), g (f i) :=
  g.to_monoid_hom.map_finprod_mem f hs

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_inv_distrib {G : Type _} [CommGroupₓ G] (f : α → G) (hs : s.finite) :
  (∏ᶠ (x : _)(_ : x ∈ s), f x⁻¹) = (∏ᶠ (x : _)(_ : x ∈ s), f x)⁻¹ :=
  ((MulEquiv.inv G).map_finprod_mem f hs).symm

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem finprod_mem_inv_distrib₀ {G : Type _} [CommGroupWithZero G] (f : α → G) (hs : s.finite) :
  (∏ᶠ (x : _)(_ : x ∈ s), f x⁻¹) = (∏ᶠ (x : _)(_ : x ∈ s), f x)⁻¹ :=
  ((MulEquiv.inv₀ G).map_finprod_mem f hs).symm

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- Given a finite set `s`, the product of `f i / g i` over `i ∈ s` equals the product of `f i`
over `i ∈ s` divided by the product of `g i` over `i ∈ s`. -/
@[toAdditive]
theorem finprod_mem_div_distrib {G : Type _} [CommGroupₓ G] (f g : α → G) (hs : s.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i / g i) = (∏ᶠ (i : _)(_ : i ∈ s), f i) / ∏ᶠ (i : _)(_ : i ∈ s), g i :=
  by 
    simp only [div_eq_mul_inv, finprod_mem_mul_distrib hs, finprod_mem_inv_distrib g hs]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
theorem finprod_mem_div_distrib₀ {G : Type _} [CommGroupWithZero G] (f g : α → G) (hs : s.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), f i / g i) = (∏ᶠ (i : _)(_ : i ∈ s), f i) / ∏ᶠ (i : _)(_ : i ∈ s), g i :=
  by 
    simp only [div_eq_mul_inv, finprod_mem_mul_distrib hs, finprod_mem_inv_distrib₀ g hs]

/-!
### `∏ᶠ x ∈ s, f x` and set operations
-/


-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » («expr∅»() : set α))
/-- The product of any function over an empty set is one. -/
@[toAdditive]
theorem finprod_mem_empty : (∏ᶠ (i : _)(_ : i ∈ (∅ : Set α)), f i) = 1 :=
  by 
    simp 

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- A set `s` is not empty if the product of some function over `s` is not equal to one. -/
@[toAdditive]
theorem nonempty_of_finprod_mem_ne_one (h : (∏ᶠ (i : _)(_ : i ∈ s), f i) ≠ 1) : s.nonempty :=
  ne_empty_iff_nonempty.1$ fun h' => h$ h'.symm ▸ finprod_mem_empty

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∪ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∩ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- Given finite sets `s` and `t`, the product of `f i` over `i ∈ s ∪ t` times the product of
`f i` over `i ∈ s ∩ t` equals the product of `f i` over `i ∈ s` times the product of `f i`
over `i ∈ t`. -/
@[toAdditive]
theorem finprod_mem_union_inter (hs : s.finite) (ht : t.finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s ∪ t), f i)*∏ᶠ (i : _)(_ : i ∈ s ∩ t), f i) =
    (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    lift s to Finset α using hs 
    lift t to Finset α using ht 
    classical 
    rw [←Finset.coe_union, ←Finset.coe_inter]
    simp only [finprod_mem_coe_finset, Finset.prod_union_inter]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∪ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∩ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- A more general version of `finprod_mem_union_inter` that requires `s ∩ mul_support f` and
`t ∩ mul_support f` instead of `s` and `t` to be finite. -/
@[toAdditive]
theorem finprod_mem_union_inter' (hs : (s ∩ mul_support f).Finite) (ht : (t ∩ mul_support f).Finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s ∪ t), f i)*∏ᶠ (i : _)(_ : i ∈ s ∩ t), f i) =
    (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    rw [←finprod_mem_inter_mul_support f s, ←finprod_mem_inter_mul_support f t, ←finprod_mem_union_inter hs ht,
      ←union_inter_distrib_right, finprod_mem_inter_mul_support, ←finprod_mem_inter_mul_support f (s ∩ t)]
    congr 2
    rw [inter_left_comm, inter_assoc, inter_assoc, inter_self, inter_left_comm]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∪ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- A more general version of `finprod_mem_union` that requires `s ∩ mul_support f` and
`t ∩ mul_support f` instead of `s` and `t` to be finite. -/
@[toAdditive]
theorem finprod_mem_union' (hst : Disjoint s t) (hs : (s ∩ mul_support f).Finite) (ht : (t ∩ mul_support f).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ s ∪ t), f i) = (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    rw [←finprod_mem_union_inter' hs ht, disjoint_iff_inter_eq_empty.1 hst, finprod_mem_empty, mul_oneₓ]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∪ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- Given two finite disjoint sets `s` and `t`, the product of `f i` over `i ∈ s ∪ t` equals the
product of `f i` over `i ∈ s` times the product of `f i` over `i ∈ t`. -/
@[toAdditive]
theorem finprod_mem_union (hst : Disjoint s t) (hs : s.finite) (ht : t.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s ∪ t), f i) = (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t), f i :=
  finprod_mem_union' hst (hs.inter_of_left _) (ht.inter_of_left _)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∪ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- A more general version of `finprod_mem_union'` that requires `s ∩ mul_support f` and
`t ∩ mul_support f` instead of `s` and `t` to be disjoint -/
@[toAdditive]
theorem finprod_mem_union'' (hst : Disjoint (s ∩ mul_support f) (t ∩ mul_support f)) (hs : (s ∩ mul_support f).Finite)
  (ht : (t ∩ mul_support f).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ s ∪ t), f i) = (∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    rw [←finprod_mem_inter_mul_support f s, ←finprod_mem_inter_mul_support f t, ←finprod_mem_union hst hs ht,
      ←union_inter_distrib_right, finprod_mem_inter_mul_support]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » ({a} : set α))
/-- The product of `f i` over `i ∈ {a}` equals `f a`. -/
@[toAdditive]
theorem finprod_mem_singleton : (∏ᶠ (i : _)(_ : i ∈ ({a} : Set α)), f i) = f a :=
  by 
    rw [←Finset.coe_singleton, finprod_mem_coe_finset, Finset.prod_singleton]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr = » a)
@[simp, toAdditive]
theorem finprod_cond_eq_left : (∏ᶠ (i : _)(_ : i = a), f i) = f a :=
  finprod_mem_singleton

@[simp, toAdditive]
theorem finprod_cond_eq_right : (∏ᶠ (i : _)(hi : a = i), f i) = f a :=
  by 
    simp [@eq_comm _ a]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » insert a s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- A more general version of `finprod_mem_insert` that requires `s ∩ mul_support f` instead of
`s` to be finite. -/
@[toAdditive]
theorem finprod_mem_insert' (f : α → M) (h : a ∉ s) (hs : (s ∩ mul_support f).Finite) :
  (∏ᶠ (i : _)(_ : i ∈ insert a s), f i) = f a*∏ᶠ (i : _)(_ : i ∈ s), f i :=
  by 
    rw [insert_eq, finprod_mem_union' _ _ hs, finprod_mem_singleton]
    ·
      rwa [disjoint_singleton_left]
    ·
      exact (finite_singleton a).inter_of_left _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » insert a s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- Given a finite set `s` and an element `a ∉ s`, the product of `f i` over `i ∈ insert a s` equals
`f a` times the product of `f i` over `i ∈ s`. -/
@[toAdditive]
theorem finprod_mem_insert (f : α → M) (h : a ∉ s) (hs : s.finite) :
  (∏ᶠ (i : _)(_ : i ∈ insert a s), f i) = f a*∏ᶠ (i : _)(_ : i ∈ s), f i :=
  finprod_mem_insert' f h$ hs.inter_of_left _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » insert a s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- If `f a = 1` for all `a ∉ s`, then the product of `f i` over `i ∈ insert a s` equals the
product of `f i` over `i ∈ s`. -/
@[toAdditive]
theorem finprod_mem_insert_of_eq_one_if_not_mem (h : a ∉ s → f a = 1) :
  (∏ᶠ (i : _)(_ : i ∈ insert a s), f i) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  by 
    refine' finprod_mem_inter_mul_support_eq' _ _ _ fun x hx => ⟨_, Or.inr⟩
    rintro (rfl | hxs)
    exacts[not_imp_comm.1 h hx, hxs]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » insert a s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- If `f a = 1`, then the product of `f i` over `i ∈ insert a s` equals the product of `f i` over
`i ∈ s`. -/
@[toAdditive]
theorem finprod_mem_insert_one (h : f a = 1) : (∏ᶠ (i : _)(_ : i ∈ insert a s), f i) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  finprod_mem_insert_of_eq_one_if_not_mem fun _ => h

/-- If the multiplicative support of `f` is finite, then for every `x` in the domain of `f`,
`f x` divides `finprod f`.  -/
theorem finprod_mem_dvd {f : α → N} (a : α) (hf : finite (mul_support f)) : f a ∣ finprod f :=
  by 
    byCases' ha : a ∈ mul_support f
    ·
      rw [finprod_eq_prod_of_mul_support_to_finset_subset f hf (Set.Subset.refl _)]
      exact Finset.dvd_prod_of_mem f ((finite.mem_to_finset hf).mpr ha)
    ·
      rw [nmem_mul_support.mp ha]
      exact one_dvd (finprod f)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » ({a, b} : set α))
/-- The product of `f i` over `i ∈ {a, b}`, `a ≠ b`, is equal to `f a * f b`. -/
@[toAdditive]
theorem finprod_mem_pair (h : a ≠ b) : (∏ᶠ (i : _)(_ : i ∈ ({a, b} : Set α)), f i) = f a*f b :=
  by 
    rw [finprod_mem_insert, finprod_mem_singleton]
    exacts[h, finite_singleton b]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » hs.to_finset)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » hs.to_finset)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr '' »(g, s))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » s)
/-- The product of `f y` over `y ∈ g '' s` equals the product of `f (g i)` over `s`
provided that `g` is injective on `s ∩ mul_support (f ∘ g)`. -/
@[toAdditive]
theorem finprod_mem_image' {s : Set β} {g : β → α} (hg : Set.InjOn g (s ∩ mul_support (f ∘ g))) :
  (∏ᶠ (i : _)(_ : i ∈ g '' s), f i) = ∏ᶠ (j : _)(_ : j ∈ s), f (g j) :=
  by 
    classical 
    byCases' hs : finite (s ∩ mul_support (f ∘ g))
    ·
      have hg : ∀ x _ : x ∈ hs.to_finset y _ : y ∈ hs.to_finset, g x = g y → x = y
      ·
        simpa only [hs.mem_to_finset]
      rw [finprod_mem_eq_prod _ hs, ←Finset.prod_image hg]
      refine' finprod_mem_eq_prod_of_inter_mul_support_eq f _ 
      rw [Finset.coe_image, hs.coe_to_finset, ←image_inter_mul_support_eq, inter_assoc, inter_self]
    ·
      rw [finprod_mem_eq_one_of_infinite hs, finprod_mem_eq_one_of_infinite]
      rwa [image_inter_mul_support_eq, infinite_image_iff hg]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr '' »(g, s))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » s)
/-- The product of `f y` over `y ∈ g '' s` equals the product of `f (g i)` over `s`
provided that `g` is injective on `s`. -/
@[toAdditive]
theorem finprod_mem_image {β} {s : Set β} {g : β → α} (hg : Set.InjOn g s) :
  (∏ᶠ (i : _)(_ : i ∈ g '' s), f i) = ∏ᶠ (j : _)(_ : j ∈ s), f (g j) :=
  finprod_mem_image'$ hg.mono$ inter_subset_left _ _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » range g)
/-- The product of `f y` over `y ∈ set.range g` equals the product of `f (g i)` over all `i`
provided that `g` is injective on `mul_support (f ∘ g)`. -/
@[toAdditive]
theorem finprod_mem_range' {g : β → α} (hg : Set.InjOn g (mul_support (f ∘ g))) :
  (∏ᶠ (i : _)(_ : i ∈ range g), f i) = ∏ᶠ j, f (g j) :=
  by 
    rw [←image_univ, finprod_mem_image', finprod_mem_univ]
    rwa [univ_inter]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » range g)
/-- The product of `f y` over `y ∈ set.range g` equals the product of `f (g i)` over all `i`
provided that `g` is injective. -/
@[toAdditive]
theorem finprod_mem_range {g : β → α} (hg : injective g) : (∏ᶠ (i : _)(_ : i ∈ range g), f i) = ∏ᶠ j, f (g j) :=
  finprod_mem_range' (hg.inj_on _)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » t)
/-- The product of `f i` over `s : set α` is equal to the product of `g j` over `t : set β`
if there exists a function `e : α → β` such that `e` is bijective from `s` to `t` and for all
`x` in `s` we have `f x = g (e x)`.
See also `finset.prod_bij`. -/
@[toAdditive]
theorem finprod_mem_eq_of_bij_on {s : Set α} {t : Set β} {f : α → M} {g : β → M} (e : α → β) (he₀ : Set.BijOn e s t)
  (he₁ : ∀ x _ : x ∈ s, f x = g (e x)) : (∏ᶠ (i : _)(_ : i ∈ s), f i) = ∏ᶠ (j : _)(_ : j ∈ t), g j :=
  by 
    rw [←Set.BijOn.image_eq he₀, finprod_mem_image he₀.2.1]
    exact finprod_mem_congr rfl he₁

/-- The product of `f i` is equal to the product of `g j` if there exists a bijective function
`e : α → β` such that for all `x` we have `f x = g (e x)`.
See `finprod_comp`, `fintype.prod_bijective` and `finset.prod_bij` -/
@[toAdditive]
theorem finprod_eq_of_bijective {f : α → M} {g : β → M} (e : α → β) (he₀ : Function.Bijective e)
  (he₁ : ∀ x, f x = g (e x)) : (∏ᶠ i, f i) = ∏ᶠ j, g j :=
  by 
    rw [←finprod_mem_univ f, ←finprod_mem_univ g]
    exact finprod_mem_eq_of_bij_on _ (bijective_iff_bij_on_univ.mp he₀) fun x _ => he₁ x

/-- Given a bijective function `e` the product of `g i` is equal to the product of `g (e i)`.
See also `finprod_eq_of_bijective`, `fintype.prod_bijective` and `finset.prod_bij` -/
@[toAdditive]
theorem finprod_comp {g : β → M} (e : α → β) (he₀ : Function.Bijective e) : (∏ᶠ i, g (e i)) = ∏ᶠ j, g j :=
  finprod_eq_of_bijective e he₀ fun x => rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_set_coe_eq_finprod_mem (s : Set α) : (∏ᶠ j : s, f j) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  by 
    rw [←finprod_mem_range, Subtype.range_coe]
    exact Subtype.coe_injective

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
@[ toAdditive ]
  theorem
    finprod_subtype_eq_finprod_cond
    ( p : α → Prop ) : ∏ᶠ j : Subtype p , f j = ∏ᶠ ( i : _ ) ( hi : p i ) , f i
    := finprod_set_coe_eq_finprod_mem { i | p i }

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∩ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr \ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_inter_mul_diff' (t : Set α) (h : (s ∩ mul_support f).Finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s ∩ t), f i)*∏ᶠ (i : _)(_ : i ∈ s \ t), f i) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  by 
    rw [←finprod_mem_union', inter_union_diff]
    exacts[fun x hx => hx.2.2 hx.1.2, h.subset fun x hx => ⟨hx.1.1, hx.2⟩, h.subset fun x hx => ⟨hx.1.1, hx.2⟩]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr ∩ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr \ »(s, t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
@[toAdditive]
theorem finprod_mem_inter_mul_diff (t : Set α) (h : s.finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s ∩ t), f i)*∏ᶠ (i : _)(_ : i ∈ s \ t), f i) = ∏ᶠ (i : _)(_ : i ∈ s), f i :=
  finprod_mem_inter_mul_diff' _$ h.inter_of_left _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr \ »(t, s))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- A more general version of `finprod_mem_mul_diff` that requires `t ∩ mul_support f` instead of
  `t` to be finite. -/
@[toAdditive]
theorem finprod_mem_mul_diff' (hst : s ⊆ t) (ht : (t ∩ mul_support f).Finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t \ s), f i) = ∏ᶠ (i : _)(_ : i ∈ t), f i :=
  by 
    rw [←finprod_mem_inter_mul_diff' _ ht, inter_eq_self_of_subset_right hst]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » «expr \ »(t, s))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » t)
/-- Given a finite set `t` and a subset `s` of `t`, the product of `f i` over `i ∈ s`
times the product of `f i` over `t \ s` equals the product of `f i` over `i ∈ t`. -/
@[toAdditive]
theorem finprod_mem_mul_diff (hst : s ⊆ t) (ht : t.finite) :
  ((∏ᶠ (i : _)(_ : i ∈ s), f i)*∏ᶠ (i : _)(_ : i ∈ t \ s), f i) = ∏ᶠ (i : _)(_ : i ∈ t), f i :=
  finprod_mem_mul_diff' hst (ht.inter_of_left _)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » «expr⋃ , »((i : ι), t i))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » t i)
/-- Given a family of pairwise disjoint finite sets `t i` indexed by a finite type,
the product of `f a` over the union `⋃ i, t i` is equal to the product over all indexes `i`
of the products of `f a` over `a ∈ t i`. -/
@[toAdditive]
theorem finprod_mem_Union [Fintype ι] {t : ι → Set α} (h : Pairwise (Disjoint on t)) (ht : ∀ i, (t i).Finite) :
  (∏ᶠ (a : _)(_ : a ∈ ⋃ i : ι, t i), f a) = ∏ᶠ i, ∏ᶠ (a : _)(_ : a ∈ t i), f a :=
  by 
    lift t to ι → Finset α using ht 
    classical 
    rw [←bUnion_univ, ←Finset.coe_univ, ←Finset.coe_bUnion, finprod_mem_coe_finset, Finset.prod_bUnion]
    ·
      simp only [finprod_mem_coe_finset, finprod_eq_prod_of_fintype]
    ·
      exact fun x _ y _ hxy => Finset.disjoint_iff_disjoint_coe.2 (h x y hxy)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » I)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » «expr⋃ , »((x «expr ∈ » I), t x))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » I)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » I)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » t i)
/-- Given a family of sets `t : ι → set α`, a finite set `I` in the index type such that all
sets `t i`, `i ∈ I`, are finite, if all `t i`, `i ∈ I`, are pairwise disjoint, then
the product of `f a` over `a ∈ ⋃ i ∈ I, t i` is equal to the product over `i ∈ I`
of the products of `f a` over `a ∈ t i`. -/
@[toAdditive]
theorem finprod_mem_bUnion {I : Set ι} {t : ι → Set α} (h : I.pairwise_disjoint t) (hI : I.finite)
  (ht : ∀ i _ : i ∈ I, (t i).Finite) :
  (∏ᶠ (a : _)(_ : a ∈ ⋃ (x : _)(_ : x ∈ I), t x), f a) = ∏ᶠ (i : _)(_ : i ∈ I), ∏ᶠ (j : _)(_ : j ∈ t i), f j :=
  by 
    have  := hI.fintype 
    rw [bUnion_eq_Union, finprod_mem_Union, ←finprod_set_coe_eq_finprod_mem]
    exacts[fun x y hxy => h x.2 y.2 (subtype.coe_injective.ne hxy), fun b => ht b b.2]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » «expr⋃₀ »(t))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
/-- If `t` is a finite set of pairwise disjoint finite sets, then the product of `f a`
over `a ∈ ⋃₀ t` is the product over `s ∈ t` of the products of `f a` over `a ∈ s`. -/
@[toAdditive]
theorem finprod_mem_sUnion {t : Set (Set α)} (h : t.pairwise_disjoint id) (ht₀ : t.finite)
  (ht₁ : ∀ x _ : x ∈ t, Set.Finite x) :
  (∏ᶠ (a : _)(_ : a ∈ ⋃₀t), f a) = ∏ᶠ (s : _)(_ : s ∈ t), ∏ᶠ (a : _)(_ : a ∈ s), f a :=
  by 
    rw [Set.sUnion_eq_bUnion]
    exact finprod_mem_bUnion h ht₀ ht₁

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ≠ » a)
@[toAdditive]
theorem mul_finprod_cond_ne (a : α) (hf : finite (mul_support f)) : (f a*∏ᶠ (i : _)(_ : i ≠ a), f i) = ∏ᶠ i, f i :=
  by 
    classical 
    rw [finprod_eq_prod _ hf]
    have h : ∀ x : α, f x ≠ 1 → (x ≠ a ↔ x ∈ hf.to_finset \ {a})
    ·
      intro x hx 
      rw [Finset.mem_sdiff, Finset.mem_singleton, finite.mem_to_finset, mem_mul_support]
      exact ⟨fun h => And.intro hx h, fun h => h.2⟩
    rw [finprod_cond_eq_prod_of_cond_iff f h, Finset.sdiff_singleton_eq_erase]
    byCases' ha : a ∈ mul_support f
    ·
      apply Finset.mul_prod_erase _ _ ((finite.mem_to_finset _).mpr ha)
    ·
      rw [mem_mul_support, not_not] at ha 
      rw [ha, one_mulₓ]
      apply Finset.prod_erase _ ha

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- If `s : set α` and `t : set β` are finite sets, then the product over `s` commutes
with the product over `t`. -/
@[toAdditive]
theorem finprod_mem_comm {s : Set α} {t : Set β} (f : α → β → M) (hs : s.finite) (ht : t.finite) :
  (∏ᶠ (i : _)(_ : i ∈ s), ∏ᶠ (j : _)(_ : j ∈ t), f i j) = ∏ᶠ (j : _)(_ : j ∈ t), ∏ᶠ (i : _)(_ : i ∈ s), f i j :=
  by 
    lift s to Finset α using hs 
    lift t to Finset β using ht 
    simp only [finprod_mem_coe_finset]
    exact Finset.prod_comm

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr ∈ » s)
/-- To prove a property of a finite product, it suffices to prove that the property is
multiplicative and holds on multipliers. -/
@[toAdditive]
theorem finprod_mem_induction (p : M → Prop) (hp₀ : p 1) (hp₁ : ∀ x y, p x → p y → p (x*y))
  (hp₂ : ∀ x _ : x ∈ s, p$ f x) : p (∏ᶠ (i : _)(_ : i ∈ s), f i) :=
  finprod_induction _ hp₀ hp₁$ fun x => finprod_induction _ hp₀ hp₁$ hp₂ x

theorem finprod_cond_nonneg {R : Type _} [OrderedCommSemiring R] {p : α → Prop} {f : α → R} (hf : ∀ x, p x → 0 ≤ f x) :
  0 ≤ ∏ᶠ (x : _)(h : p x), f x :=
  finprod_nonneg$ fun x => finprod_nonneg$ hf x

@[toAdditive]
theorem single_le_finprod {M : Type _} [OrderedCommMonoid M] (i : α) {f : α → M} (hf : finite (mul_support f))
  (h : ∀ j, 1 ≤ f j) : f i ≤ ∏ᶠ j, f j :=
  by 
    classical <;>
      calc f i ≤ ∏ j in insert i hf.to_finset, f j :=
        Finset.single_le_prod' (fun j hj => h j) (Finset.mem_insert_self _ _)_ = ∏ᶠ j, f j :=
        (finprod_eq_prod_of_mul_support_to_finset_subset _ hf (Finset.subset_insert _ _)).symm

theorem finprod_eq_zero {M₀ : Type _} [CommMonoidWithZero M₀] (f : α → M₀) (x : α) (hx : f x = 0)
  (hf : finite (mul_support f)) : (∏ᶠ x, f x) = 0 :=
  by 
    nontriviality 
    rw [finprod_eq_prod f hf]
    refine' Finset.prod_eq_zero (hf.mem_to_finset.2 _) hx 
    simp [hx]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (b «expr ∈ » s)
@[toAdditive]
theorem finprod_prod_comm (s : Finset β) (f : α → β → M) (h : ∀ b _ : b ∈ s, (mul_support fun a => f a b).Finite) :
  (∏ᶠ a : α, ∏ b in s, f a b) = ∏ b in s, ∏ᶠ a : α, f a b :=
  by 
    have hU :
      (mul_support fun a => ∏ b in s, f a b) ⊆ (s.finite_to_set.bUnion fun b hb => h b (Finset.mem_coe.1 hb)).toFinset
    ·
      rw [finite.coe_to_finset]
      intro x hx 
      simp only [exists_prop, mem_Union, Ne.def, mem_mul_support, Finset.mem_coe]
      contrapose! hx 
      rw [mem_mul_support, not_not, Finset.prod_congr rfl hx, Finset.prod_const_one]
    rw [finprod_eq_prod_of_mul_support_subset _ hU, Finset.prod_comm]
    refine' Finset.prod_congr rfl fun b hb => (finprod_eq_prod_of_mul_support_subset _ _).symm 
    intro a ha 
    simp only [finite.coe_to_finset, mem_Union]
    exact ⟨b, hb, ha⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
@[toAdditive]
theorem prod_finprod_comm (s : Finset α) (f : α → β → M) (h : ∀ a _ : a ∈ s, (mul_support (f a)).Finite) :
  (∏ a in s, ∏ᶠ b : β, f a b) = ∏ᶠ b : β, ∏ a in s, f a b :=
  (finprod_prod_comm s (fun b a => f a b) h).symm

theorem mul_finsum {R : Type _} [Semiringₓ R] (f : α → R) (r : R) (h : (Function.Support f).Finite) :
  (r*∑ᶠ a : α, f a) = ∑ᶠ a : α, r*f a :=
  (AddMonoidHom.mulLeft r).map_finsum h

theorem finsum_mul {R : Type _} [Semiringₓ R] (f : α → R) (r : R) (h : (Function.Support f).Finite) :
  ((∑ᶠ a : α, f a)*r) = ∑ᶠ a : α, f a*r :=
  (AddMonoidHom.mulRight r).map_finsum h

@[toAdditive]
theorem Finset.mul_support_of_fiberwise_prod_subset_image [DecidableEq β] (s : Finset α) (f : α → M) (g : α → β) :
  (mul_support fun b => (s.filter fun a => g a = b).Prod f) ⊆ s.image g :=
  by 
    simp only [Finset.coe_image, Set.mem_image, Finset.mem_coe, Function.support_subset_iff]
    intro b h 
    suffices  : (s.filter fun a : α => g a = b).Nonempty
    ·
      simpa only [s.fiber_nonempty_iff_mem_image g b, Finset.mem_image, exists_prop]
    exact Finset.nonempty_of_prod_ne_one h

/-- Note that `b ∈ (s.filter (λ ab, prod.fst ab = a)).image prod.snd` iff `(a, b) ∈ s` so we can
simplify the right hand side of this lemma. However the form stated here is more useful for
iterating this lemma, e.g., if we have `f : α × β × γ → M`. -/
@[toAdditive]
theorem finprod_mem_finset_product' [DecidableEq α] [DecidableEq β] (s : Finset (α × β)) (f : α × β → M) :
  (∏ᶠ (ab : _)(h : ab ∈ s), f ab) =
    ∏ᶠ (a b : _)(h : b ∈ (s.filter fun ab => Prod.fst ab = a).Image Prod.snd), f (a, b) :=
  by 
    have  :
      ∀ a,
        (∏ i : β in (s.filter fun ab => Prod.fst ab = a).Image Prod.snd, f (a, i)) =
          (Finset.filter (fun ab => Prod.fst ab = a) s).Prod f
    ·
      intro a 
      apply Finset.prod_bij fun b _ => (a, b) <;> finish 
    rw [finprod_mem_finset_eq_prod]
    simpRw [finprod_mem_finset_eq_prod, this]
    rw [finprod_eq_prod_of_mul_support_subset _ (s.mul_support_of_fiberwise_prod_subset_image f Prod.fst),
      ←Finset.prod_fiberwise_of_maps_to _ f]
    finish

/-- See also `finprod_mem_finset_product'`. -/
@[toAdditive]
theorem finprod_mem_finset_product (s : Finset (α × β)) (f : α × β → M) :
  (∏ᶠ (ab : _)(h : ab ∈ s), f ab) = ∏ᶠ (a b : _)(h : (a, b) ∈ s), f (a, b) :=
  by 
    classical 
    rw [finprod_mem_finset_product']
    simp 

@[toAdditive]
theorem finprod_mem_finset_product₃ {γ : Type _} (s : Finset (α × β × γ)) (f : α × β × γ → M) :
  (∏ᶠ (abc : _)(h : abc ∈ s), f abc) = ∏ᶠ (a b c : _)(h : (a, b, c) ∈ s), f (a, b, c) :=
  by 
    classical 
    rw [finprod_mem_finset_product']
    simpRw [finprod_mem_finset_product']
    simp 

@[toAdditive]
theorem finprod_curry (f : α × β → M) (hf : (mul_support f).Finite) : (∏ᶠ ab, f ab) = ∏ᶠ a b, f (a, b) :=
  by 
    have h₁ : ∀ a, (∏ᶠ h : a ∈ hf.to_finset, f a) = f a
    ·
      simp 
    have h₂ : (∏ᶠ a, f a) = ∏ᶠ (a : _)(h : a ∈ hf.to_finset), f a
    ·
      simp 
    simpRw [h₂, finprod_mem_finset_product, h₁]

@[toAdditive]
theorem finprod_curry₃ {γ : Type _} (f : α × β × γ → M) (h : (mul_support f).Finite) :
  (∏ᶠ abc, f abc) = ∏ᶠ a b c, f (a, b, c) :=
  by 
    rw [finprod_curry f h]
    congr 
    ext a 
    rw [finprod_curry]
    simp [h]

@[toAdditive]
theorem finprod_dmem {s : Set α} [DecidablePred (· ∈ s)] (f : ∀ a : α, a ∈ s → M) :
  (∏ᶠ (a : α)(h : a ∈ s), f a h) = ∏ᶠ (a : α)(h : a ∈ s), if h' : a ∈ s then f a h' else 1 :=
  finprod_congr fun a => finprod_congr fun ha => (dif_pos ha).symm

@[toAdditive]
theorem finprod_emb_domain' {f : α → β} (hf : Function.Injective f) [DecidablePred (· ∈ Set.Range f)] (g : α → M) :
  (∏ᶠ b : β, if h : b ∈ Set.Range f then g (Classical.some h) else 1) = ∏ᶠ a : α, g a :=
  by 
    simpRw [←finprod_eq_dif]
    rw [finprod_dmem, finprod_mem_range hf, finprod_congr fun a => _]
    rw [dif_pos (Set.mem_range_self a), hf (Classical.some_spec (Set.mem_range_self a))]

@[toAdditive]
theorem finprod_emb_domain (f : α ↪ β) [DecidablePred (· ∈ Set.Range f)] (g : α → M) :
  (∏ᶠ b : β, if h : b ∈ Set.Range f then g (Classical.some h) else 1) = ∏ᶠ a : α, g a :=
  finprod_emb_domain' f.injective g

end Type

