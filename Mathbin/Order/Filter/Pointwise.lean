/-
Copyright (c) 2019 Zhouhang Zhou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zhouhang Zhou, Yaël Dillies
-/
import Mathbin.Data.Set.Pointwise
import Mathbin.Order.Filter.NAry
import Mathbin.Order.Filter.Ultrafilter

/-!
# Pointwise operations on filters

This file defines pointwise operations on filters. This is useful because usual algebraic operations
distribute over pointwise operations. For example,
* `(f₁ * f₂).map m  = f₁.map m * f₂.map m`
* `𝓝 (x * y) = 𝓝 x * 𝓝 y`

## Main declarations

* `0` (`filter.has_zero`): Pure filter at `0 : α`, or alternatively principal filter at `0 : set α`.
* `1` (`filter.has_one`): Pure filter at `1 : α`, or alternatively principal filter at `1 : set α`.
* `f + g` (`filter.has_add`): Addition, filter generated by all `s + t` where `s ∈ f` and `t ∈ g`.
* `f * g` (`filter.has_mul`): Multiplication, filter generated by all `s * t` where `s ∈ f` and
  `t ∈ g`.
* `-f` (`filter.has_neg`): Negation, filter of all `-s` where `s ∈ f`.
* `f⁻¹` (`filter.has_inv`): Inversion, filter of all `s⁻¹` where `s ∈ f`.
* `f - g` (`filter.has_sub`): Subtraction, filter generated by all `s - t` where `s ∈ f` and
  `t ∈ g`.
* `f / g` (`filter.has_div`): Division, filter generated by all `s / t` where `s ∈ f` and `t ∈ g`.
* `f +ᵥ g` (`filter.has_vadd`): Scalar addition, filter generated by all `s +ᵥ t` where `s ∈ f` and
  `t ∈ g`.
* `f -ᵥ g` (`filter.has_vsub`): Scalar subtraction, filter generated by all `s -ᵥ t` where `s ∈ f`
  and `t ∈ g`.
* `f • g` (`filter.has_smul`): Scalar multiplication, filter generated by all `s • t` where
  `s ∈ f` and `t ∈ g`.
* `a +ᵥ f` (`filter.has_vadd_filter`): Translation, filter of all `a +ᵥ s` where `s ∈ f`.
* `a • f` (`filter.has_smul_filter`): Scaling, filter of all `a • s` where `s ∈ f`.

For `α` a semigroup/monoid, `filter α` is a semigroup/monoid.
As an unfortunate side effect, this means that `n • f`, where `n : ℕ`, is ambiguous between
pointwise scaling and repeated pointwise addition. See note [pointwise nat action].

## Implementation notes

We put all instances in the locale `pointwise`, so that these instances are not available by
default. Note that we do not mark them as reducible (as argued by note [reducible non-instances])
since we expect the locale to be open whenever the instances are actually used (and making the
instances reducible changes the behavior of `simp`.

## Tags

filter multiplication, filter addition, pointwise addition, pointwise multiplication,
-/


open Function Set

open Filter Pointwise

variable {F α β γ δ ε : Type _}

namespace Filter

/-! ### `0`/`1` as filters -/


section One

variable [One α] {f : Filter α} {s : Set α}

/-- `1 : filter α` is defined as the filter of sets containing `1 : α` in locale `pointwise`. -/
@[to_additive "`0 : filter α` is defined as the filter of sets containing `0 : α` in locale\n`pointwise`."]
protected def hasOne : One (Filter α) :=
  ⟨pure 1⟩

localized [Pointwise] attribute [instance] Filter.hasOne Filter.hasZero

@[simp, to_additive]
theorem mem_one : s ∈ (1 : Filter α) ↔ (1 : α) ∈ s :=
  mem_pure

@[to_additive]
theorem one_mem_one : (1 : Set α) ∈ (1 : Filter α) :=
  mem_pure.2 one_mem_one

@[simp, to_additive]
theorem pure_one : pure 1 = (1 : Filter α) :=
  rfl

@[simp, to_additive]
theorem principal_one : 𝓟 1 = (1 : Filter α) :=
  principal_singleton _

@[to_additive]
theorem one_ne_bot : (1 : Filter α).ne_bot :=
  Filter.pure_ne_bot

@[simp, to_additive]
protected theorem map_one' (f : α → β) : (1 : Filter α).map f = pure (f 1) :=
  rfl

@[simp, to_additive]
theorem le_one_iff : f ≤ 1 ↔ (1 : Set α) ∈ f :=
  le_pure_iff

@[to_additive]
protected theorem NeBot.le_one_iff (h : f.ne_bot) : f ≤ 1 ↔ f = 1 :=
  h.le_pure_iff

@[simp, to_additive]
theorem eventually_one {p : α → Prop} : (∀ᶠ x in 1, p x) ↔ p 1 :=
  eventually_pure

@[simp, to_additive]
theorem tendsto_one {a : Filter β} {f : β → α} : Tendsto f a 1 ↔ ∀ᶠ x in a, f x = 1 :=
  tendsto_pure

/-- `pure` as a `one_hom`. -/
@[to_additive "`pure` as a `zero_hom`."]
def pureOneHom : OneHom α (Filter α) :=
  ⟨pure, pure_one⟩

@[simp, to_additive]
theorem coe_pure_one_hom : (pureOneHom : α → Filter α) = pure :=
  rfl

@[simp, to_additive]
theorem pure_one_hom_apply (a : α) : pureOneHom a = pure a :=
  rfl

variable [One β]

@[simp, to_additive]
protected theorem map_one [OneHomClass F α β] (φ : F) : map φ 1 = 1 := by
  rw [Filter.map_one', map_one, pure_one]

end One

/-! ### Filter negation/inversion -/


section Inv

variable [Inv α] {f g : Filter α} {s : Set α} {a : α}

/-- The inverse of a filter is the pointwise preimage under `⁻¹` of its sets. -/
@[to_additive "The negation of a filter is the pointwise preimage under `-` of its sets."]
instance : Inv (Filter α) :=
  ⟨map Inv.inv⟩

@[simp, to_additive]
protected theorem map_inv : f.map Inv.inv = f⁻¹ :=
  rfl

@[to_additive]
theorem mem_inv : s ∈ f⁻¹ ↔ Inv.inv ⁻¹' s ∈ f :=
  Iff.rfl

@[to_additive]
protected theorem inv_le_inv (hf : f ≤ g) : f⁻¹ ≤ g⁻¹ :=
  map_mono hf

@[simp, to_additive]
theorem inv_pure : (pure a : Filter α)⁻¹ = pure a⁻¹ :=
  rfl

@[simp, to_additive]
theorem inv_eq_bot_iff : f⁻¹ = ⊥ ↔ f = ⊥ :=
  map_eq_bot_iff

@[simp, to_additive]
theorem ne_bot_inv_iff : f⁻¹.ne_bot ↔ NeBot f :=
  map_ne_bot_iff _

@[to_additive]
theorem NeBot.inv : f.ne_bot → f⁻¹.ne_bot := fun h => h.map _

end Inv

section HasInvolutiveInv

variable [HasInvolutiveInv α] {f : Filter α} {s : Set α}

@[to_additive]
theorem inv_mem_inv (hs : s ∈ f) : s⁻¹ ∈ f⁻¹ := by
  rwa [mem_inv, inv_preimage, inv_invₓ]

/-- Inversion is involutive on `filter α` if it is on `α`. -/
@[to_additive "Negation is involutive on `filter α` if it is on `α`."]
protected def hasInvolutiveInv : HasInvolutiveInv (Filter α) :=
  { Filter.hasInv with
    inv_inv := fun f =>
      map_map.trans <| by
        rw [inv_involutive.comp_self, map_id] }

end HasInvolutiveInv

/-! ### Filter addition/multiplication -/


section Mul

variable [Mul α] [Mul β] {f f₁ f₂ g g₁ g₂ h : Filter α} {s t : Set α} {a b : α}

/-- The filter `f * g` is generated by `{s * t | s ∈ f, t ∈ g}` in locale `pointwise`. -/
@[to_additive "The filter `f + g` is generated by `{s + t | s ∈ f, t ∈ g}` in locale `pointwise`."]
protected def hasMul : Mul (Filter α) :=
  ⟨/- This is defeq to `map₂ (*) f g`, but the hypothesis unfolds to `t₁ * t₂ ⊆ s` rather than all the
  way to `set.image2 (*) t₁ t₂ ⊆ s`. -/
  fun f g => { map₂ (· * ·) f g with Sets := { s | ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ * t₂ ⊆ s } }⟩

localized [Pointwise] attribute [instance] Filter.hasMul Filter.hasAdd

@[simp, to_additive]
theorem map₂_mul : map₂ (· * ·) f g = f * g :=
  rfl

@[to_additive]
theorem mem_mul : s ∈ f * g ↔ ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ * t₂ ⊆ s :=
  Iff.rfl

@[to_additive]
theorem mul_mem_mul : s ∈ f → t ∈ g → s * t ∈ f * g :=
  image2_mem_map₂

@[simp, to_additive]
theorem bot_mul : ⊥ * g = ⊥ :=
  map₂_bot_left

@[simp, to_additive]
theorem mul_bot : f * ⊥ = ⊥ :=
  map₂_bot_right

@[simp, to_additive]
theorem mul_eq_bot_iff : f * g = ⊥ ↔ f = ⊥ ∨ g = ⊥ :=
  map₂_eq_bot_iff

@[simp, to_additive]
theorem mul_ne_bot_iff : (f * g).ne_bot ↔ f.ne_bot ∧ g.ne_bot :=
  map₂_ne_bot_iff

@[to_additive]
theorem NeBot.mul : NeBot f → NeBot g → NeBot (f * g) :=
  ne_bot.map₂

@[to_additive]
theorem NeBot.of_mul_left : (f * g).ne_bot → f.ne_bot :=
  ne_bot.of_map₂_left

@[to_additive]
theorem NeBot.of_mul_right : (f * g).ne_bot → g.ne_bot :=
  ne_bot.of_map₂_right

@[simp, to_additive]
theorem pure_mul : pure a * g = g.map ((· * ·) a) :=
  map₂_pure_left

@[simp, to_additive]
theorem mul_pure : f * pure b = f.map (· * b) :=
  map₂_pure_right

@[simp, to_additive]
theorem pure_mul_pure : (pure a : Filter α) * pure b = pure (a * b) :=
  map₂_pure

@[simp, to_additive]
theorem le_mul_iff : h ≤ f * g ↔ ∀ ⦃s⦄, s ∈ f → ∀ ⦃t⦄, t ∈ g → s * t ∈ h :=
  le_map₂_iff

@[to_additive]
instance covariant_mul : CovariantClass (Filter α) (Filter α) (· * ·) (· ≤ ·) :=
  ⟨fun f g h => map₂_mono_left⟩

@[to_additive]
instance covariant_swap_mul : CovariantClass (Filter α) (Filter α) (swap (· * ·)) (· ≤ ·) :=
  ⟨fun f g h => map₂_mono_right⟩

@[to_additive]
protected theorem map_mul [MulHomClass F α β] (m : F) : (f₁ * f₂).map m = f₁.map m * f₂.map m :=
  map_map₂_distrib <| map_mul m

/-- `pure` operation as a `mul_hom`. -/
@[to_additive "The singleton operation as an `add_hom`."]
def pureMulHom : α →ₙ* Filter α :=
  ⟨pure, fun a b => pure_mul_pure.symm⟩

@[simp, to_additive]
theorem coe_pure_mul_hom : (pureMulHom : α → Filter α) = pure :=
  rfl

@[simp, to_additive]
theorem pure_mul_hom_apply (a : α) : pureMulHom a = pure a :=
  rfl

end Mul

/-! ### Filter subtraction/division -/


section Div

variable [Div α] {f f₁ f₂ g g₁ g₂ h : Filter α} {s t : Set α} {a b : α}

/-- The filter `f / g` is generated by `{s / t | s ∈ f, t ∈ g}` in locale `pointwise`. -/
@[to_additive "The filter `f - g` is generated by `{s - t | s ∈ f, t ∈ g}` in locale `pointwise`."]
protected def hasDiv : Div (Filter α) :=
  ⟨/- This is defeq to `map₂ (/) f g`, but the hypothesis unfolds to `t₁ / t₂ ⊆ s` rather than all the
  way to `set.image2 (/) t₁ t₂ ⊆ s`. -/
  fun f g => { map₂ (· / ·) f g with Sets := { s | ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ / t₂ ⊆ s } }⟩

localized [Pointwise] attribute [instance] Filter.hasDiv Filter.hasSub

@[simp, to_additive]
theorem map₂_div : map₂ (· / ·) f g = f / g :=
  rfl

@[to_additive]
theorem mem_div : s ∈ f / g ↔ ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ / t₂ ⊆ s :=
  Iff.rfl

@[to_additive]
theorem div_mem_div : s ∈ f → t ∈ g → s / t ∈ f / g :=
  image2_mem_map₂

@[simp, to_additive]
theorem bot_div : ⊥ / g = ⊥ :=
  map₂_bot_left

@[simp, to_additive]
theorem div_bot : f / ⊥ = ⊥ :=
  map₂_bot_right

@[simp, to_additive]
theorem div_eq_bot_iff : f / g = ⊥ ↔ f = ⊥ ∨ g = ⊥ :=
  map₂_eq_bot_iff

@[simp, to_additive]
theorem div_ne_bot_iff : (f / g).ne_bot ↔ f.ne_bot ∧ g.ne_bot :=
  map₂_ne_bot_iff

@[to_additive]
theorem NeBot.div : NeBot f → NeBot g → NeBot (f / g) :=
  ne_bot.map₂

@[to_additive]
theorem NeBot.of_div_left : (f / g).ne_bot → f.ne_bot :=
  ne_bot.of_map₂_left

@[to_additive]
theorem NeBot.of_div_right : (f / g).ne_bot → g.ne_bot :=
  ne_bot.of_map₂_right

@[simp, to_additive]
theorem pure_div : pure a / g = g.map ((· / ·) a) :=
  map₂_pure_left

@[simp, to_additive]
theorem div_pure : f / pure b = f.map (· / b) :=
  map₂_pure_right

@[simp, to_additive]
theorem pure_div_pure : (pure a : Filter α) / pure b = pure (a / b) :=
  map₂_pure

@[to_additive]
protected theorem div_le_div : f₁ ≤ f₂ → g₁ ≤ g₂ → f₁ / g₁ ≤ f₂ / g₂ :=
  map₂_mono

@[to_additive]
protected theorem div_le_div_left : g₁ ≤ g₂ → f / g₁ ≤ f / g₂ :=
  map₂_mono_left

@[to_additive]
protected theorem div_le_div_right : f₁ ≤ f₂ → f₁ / g ≤ f₂ / g :=
  map₂_mono_right

@[simp, to_additive]
protected theorem le_div_iff : h ≤ f / g ↔ ∀ ⦃s⦄, s ∈ f → ∀ ⦃t⦄, t ∈ g → s / t ∈ h :=
  le_map₂_iff

@[to_additive]
instance covariant_div : CovariantClass (Filter α) (Filter α) (· / ·) (· ≤ ·) :=
  ⟨fun f g h => map₂_mono_left⟩

@[to_additive]
instance covariant_swap_div : CovariantClass (Filter α) (Filter α) (swap (· / ·)) (· ≤ ·) :=
  ⟨fun f g h => map₂_mono_right⟩

end Div

open Pointwise

/-- Repeated pointwise addition (not the same as pointwise repeated addition!) of a `filter`. See
Note [pointwise nat action].-/
protected def hasNsmul [Zero α] [Add α] : HasSmul ℕ (Filter α) :=
  ⟨nsmulRec⟩

/-- Repeated pointwise multiplication (not the same as pointwise repeated multiplication!) of a
`filter`. See Note [pointwise nat action]. -/
@[to_additive]
protected def hasNpow [One α] [Mul α] : Pow (Filter α) ℕ :=
  ⟨fun s n => npowRec n s⟩

/-- Repeated pointwise addition/subtraction (not the same as pointwise repeated
addition/subtraction!) of a `filter`. See Note [pointwise nat action]. -/
protected def hasZsmul [Zero α] [Add α] [Neg α] : HasSmul ℤ (Filter α) :=
  ⟨zsmulRec⟩

/-- Repeated pointwise multiplication/division (not the same as pointwise repeated
multiplication/division!) of a `filter`. See Note [pointwise nat action]. -/
@[to_additive]
protected def hasZpow [One α] [Mul α] [Inv α] : Pow (Filter α) ℤ :=
  ⟨fun s n => zpowRec n s⟩

localized [Pointwise] attribute [instance] Filter.hasNsmul Filter.hasNpow Filter.hasZsmul Filter.hasZpow

/-- `filter α` is a `semigroup` under pointwise operations if `α` is.-/
@[to_additive "`filter α` is an `add_semigroup` under pointwise operations if `α` is."]
protected def semigroup [Semigroupₓ α] : Semigroupₓ (Filter α) where
  mul := (· * ·)
  mul_assoc := fun f g h => map₂_assoc mul_assoc

/-- `filter α` is a `comm_semigroup` under pointwise operations if `α` is. -/
@[to_additive "`filter α` is an `add_comm_semigroup` under pointwise operations if `α` is."]
protected def commSemigroup [CommSemigroupₓ α] : CommSemigroupₓ (Filter α) :=
  { Filter.semigroup with mul_comm := fun f g => map₂_comm mul_comm }

section MulOneClassₓ

variable [MulOneClassₓ α] [MulOneClassₓ β]

/-- `filter α` is a `mul_one_class` under pointwise operations if `α` is. -/
@[to_additive "`filter α` is an `add_zero_class` under pointwise operations if `α` is."]
protected def mulOneClass : MulOneClassₓ (Filter α) where
  one := 1
  mul := (· * ·)
  one_mul := fun f => by
    simp only [← pure_one, ← map₂_mul, map₂_pure_left, one_mulₓ, map_id']
  mul_one := fun f => by
    simp only [← pure_one, ← map₂_mul, map₂_pure_right, mul_oneₓ, map_id']

localized [Pointwise]
  attribute [instance]
    Filter.semigroup Filter.addSemigroup Filter.commSemigroup Filter.addCommSemigroup Filter.mulOneClass Filter.addZeroClass

/-- If `φ : α →* β` then `map_monoid_hom φ` is the monoid homomorphism
`filter α →* filter β` induced by `map φ`. -/
@[to_additive
      "If `φ : α →+ β` then `map_add_monoid_hom φ` is the monoid homomorphism\n`filter α →+ filter β` induced by `map φ`."]
def mapMonoidHom [MonoidHomClass F α β] (φ : F) : Filter α →* Filter β where
  toFun := map φ
  map_one' := Filter.map_one φ
  map_mul' := fun _ _ => Filter.map_mul φ

-- The other direction does not hold in general
@[to_additive]
theorem comap_mul_comap_le [MulHomClass F α β] (m : F) {f g : Filter β} : f.comap m * g.comap m ≤ (f * g).comap m :=
  fun s ⟨t, ⟨t₁, t₂, ht₁, ht₂, t₁t₂⟩, mt⟩ =>
  ⟨m ⁻¹' t₁, m ⁻¹' t₂, ⟨t₁, ht₁, Subset.rfl⟩, ⟨t₂, ht₂, Subset.rfl⟩,
    (preimage_mul_preimage_subset _).trans <| (preimage_mono t₁t₂).trans mt⟩

@[to_additive]
theorem Tendsto.mul_mul [MulHomClass F α β] (m : F) {f₁ g₁ : Filter α} {f₂ g₂ : Filter β} :
    Tendsto m f₁ f₂ → Tendsto m g₁ g₂ → Tendsto m (f₁ * g₁) (f₂ * g₂) := fun hf hg =>
  (Filter.map_mul m).trans_le <| mul_le_mul' hf hg

/-- `pure` as a `monoid_hom`. -/
@[to_additive "`pure` as an `add_monoid_hom`."]
def pureMonoidHom : α →* Filter α :=
  { pureMulHom, pureOneHom with }

@[simp, to_additive]
theorem coe_pure_monoid_hom : (pureMonoidHom : α → Filter α) = pure :=
  rfl

@[simp, to_additive]
theorem pure_monoid_hom_apply (a : α) : pureMonoidHom a = pure a :=
  rfl

end MulOneClassₓ

section Monoidₓ

variable [Monoidₓ α] {f g : Filter α} {s : Set α} {a : α} {m n : ℕ}

/-- `filter α` is a `monoid` under pointwise operations if `α` is. -/
@[to_additive "`filter α` is an `add_monoid` under pointwise operations if `α` is."]
protected def monoid : Monoidₓ (Filter α) :=
  { Filter.mulOneClass, Filter.semigroup, Filter.hasNpow with }

localized [Pointwise] attribute [instance] Filter.monoid Filter.addMonoid

@[to_additive]
theorem pow_mem_pow (hs : s ∈ f) : ∀ n : ℕ, s ^ n ∈ f ^ n
  | 0 => by
    rw [pow_zeroₓ]
    exact one_mem_one
  | n + 1 => by
    rw [pow_succₓ]
    exact mul_mem_mul hs (pow_mem_pow _)

@[simp, to_additive nsmul_bot]
theorem bot_pow {n : ℕ} (hn : n ≠ 0) : (⊥ : Filter α) ^ n = ⊥ := by
  rw [← tsub_add_cancel_of_le (Nat.succ_le_of_ltₓ <| Nat.pos_of_ne_zeroₓ hn), pow_succₓ, bot_mul]

@[to_additive]
theorem mul_top_of_one_le (hf : 1 ≤ f) : f * ⊤ = ⊤ := by
  refine' top_le_iff.1 fun s => _
  simp only [mem_mul, mem_top, exists_and_distrib_left, exists_eq_left]
  rintro ⟨t, ht, hs⟩
  rwa [mul_univ_of_one_mem (mem_one.1 <| hf ht), univ_subset_iff] at hs

@[to_additive]
theorem top_mul_of_one_le (hf : 1 ≤ f) : ⊤ * f = ⊤ := by
  refine' top_le_iff.1 fun s => _
  simp only [mem_mul, mem_top, exists_and_distrib_left, exists_eq_left]
  rintro ⟨t, ht, hs⟩
  rwa [univ_mul_of_one_mem (mem_one.1 <| hf ht), univ_subset_iff] at hs

@[simp, to_additive]
theorem top_mul_top : (⊤ : Filter α) * ⊤ = ⊤ :=
  mul_top_of_one_le le_top

--TODO: `to_additive` trips up on the `1 : ℕ` used in the pattern-matching.
theorem nsmul_top {α : Type _} [AddMonoidₓ α] : ∀ {n : ℕ}, n ≠ 0 → n • (⊤ : Filter α) = ⊤
  | 0 => fun h => (h rfl).elim
  | 1 => fun _ => one_nsmul _
  | n + 2 => fun _ => by
    rw [succ_nsmul, nsmul_top n.succ_ne_zero, top_add_top]

@[to_additive nsmul_top]
theorem top_pow : ∀ {n : ℕ}, n ≠ 0 → (⊤ : Filter α) ^ n = ⊤
  | 0 => fun h => (h rfl).elim
  | 1 => fun _ => pow_oneₓ _
  | n + 2 => fun _ => by
    rw [pow_succₓ, top_pow n.succ_ne_zero, top_mul_top]

@[to_additive]
protected theorem _root_.is_unit.filter : IsUnit a → IsUnit (pure a : Filter α) :=
  IsUnit.map (pureMonoidHom : α →* Filter α)

end Monoidₓ

/-- `filter α` is a `comm_monoid` under pointwise operations if `α` is. -/
@[to_additive "`filter α` is an `add_comm_monoid` under pointwise operations if `α` is."]
protected def commMonoid [CommMonoidₓ α] : CommMonoidₓ (Filter α) :=
  { Filter.mulOneClass, Filter.commSemigroup with }

open Pointwise

section DivisionMonoid

variable [DivisionMonoid α] {f g : Filter α}

@[to_additive]
protected theorem mul_eq_one_iff : f * g = 1 ↔ ∃ a b, f = pure a ∧ g = pure b ∧ a * b = 1 := by
  refine' ⟨fun hfg => _, _⟩
  · obtain ⟨t₁, t₂, h₁, h₂, h⟩ : (1 : Set α) ∈ f * g := hfg.symm.subst one_mem_one
    have hfg : (f * g).ne_bot := hfg.symm.subst one_ne_bot
    rw [(hfg.nonempty_of_mem <| mul_mem_mul h₁ h₂).subset_one_iff, Set.mul_eq_one_iff] at h
    obtain ⟨a, b, rfl, rfl, h⟩ := h
    refine' ⟨a, b, _, _, h⟩
    · rwa [← hfg.of_mul_left.le_pure_iff, le_pure_iff]
      
    · rwa [← hfg.of_mul_right.le_pure_iff, le_pure_iff]
      
    
  · rintro ⟨a, b, rfl, rfl, h⟩
    rw [pure_mul_pure, h, pure_one]
    

/-- `filter α` is a division monoid under pointwise operations if `α` is. -/
@[to_additive SubtractionMonoid "`filter α` is a subtraction monoid under pointwise\noperations if `α` is."]
protected def divisionMonoid : DivisionMonoid (Filter α) :=
  { Filter.monoid, Filter.hasInvolutiveInv, Filter.hasDiv, Filter.hasZpow with
    mul_inv_rev := fun s t => map_map₂_antidistrib mul_inv_rev,
    inv_eq_of_mul := fun s t h => by
      obtain ⟨a, b, rfl, rfl, hab⟩ := Filter.mul_eq_one_iff.1 h
      rw [inv_pure, inv_eq_of_mul_eq_one_right hab],
    div_eq_mul_inv := fun f g => map_map₂_distrib_right div_eq_mul_inv }

@[to_additive]
theorem is_unit_iff : IsUnit f ↔ ∃ a, f = pure a ∧ IsUnit a := by
  constructor
  · rintro ⟨u, rfl⟩
    obtain ⟨a, b, ha, hb, h⟩ := Filter.mul_eq_one_iff.1 u.mul_inv
    refine' ⟨a, ha, ⟨a, b, h, pure_injective _⟩, rfl⟩
    rw [← pure_mul_pure, ← ha, ← hb]
    exact u.inv_mul
    
  · rintro ⟨a, rfl, ha⟩
    exact ha.filter
    

end DivisionMonoid

/-- `filter α` is a commutative division monoid under pointwise operations if `α` is. -/
@[to_additive SubtractionCommMonoid
      "`filter α` is a commutative subtraction monoid under\npointwise operations if `α` is."]
protected def divisionCommMonoid [DivisionCommMonoid α] : DivisionCommMonoid (Filter α) :=
  { Filter.divisionMonoid, Filter.commSemigroup with }

/-- `filter α` has distributive negation if `α` has. -/
protected def hasDistribNeg [Mul α] [HasDistribNeg α] : HasDistribNeg (Filter α) :=
  { Filter.hasInvolutiveNeg with neg_mul := fun _ _ => map₂_map_left_comm neg_mul,
    mul_neg := fun _ _ => map_map₂_right_comm mul_neg }

localized [Pointwise]
  attribute [instance]
    Filter.commMonoid Filter.addCommMonoid Filter.divisionMonoid Filter.subtractionMonoid Filter.divisionCommMonoid Filter.subtractionCommMonoid Filter.hasDistribNeg

section Distribₓ

variable [Distribₓ α] {f g h : Filter α}

/-!
Note that `filter α` is not a `distrib` because `f * g + f * h` has cross terms that `f * (g + h)`
lacks.
-/


theorem mul_add_subset : f * (g + h) ≤ f * g + f * h :=
  map₂_distrib_le_left mul_addₓ

theorem add_mul_subset : (f + g) * h ≤ f * h + g * h :=
  map₂_distrib_le_right add_mulₓ

end Distribₓ

section MulZeroClassₓ

variable [MulZeroClassₓ α] {f g : Filter α}

/-! Note that `filter` is not a `mul_zero_class` because `0 * ⊥ ≠ 0`. -/


theorem NeBot.mul_zero_nonneg (hf : f.ne_bot) : 0 ≤ f * 0 :=
  le_mul_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨a, ha⟩ := hf.nonempty_of_mem h₁
    ⟨_, _, ha, h₂, mul_zero _⟩

theorem NeBot.zero_mul_nonneg (hg : g.ne_bot) : 0 ≤ 0 * g :=
  le_mul_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨b, hb⟩ := hg.nonempty_of_mem h₂
    ⟨_, _, h₁, hb, zero_mul _⟩

end MulZeroClassₓ

section Groupₓ

variable [Groupₓ α] [DivisionMonoid β] [MonoidHomClass F α β] (m : F) {f g f₁ g₁ : Filter α} {f₂ g₂ : Filter β}

/-! Note that `filter α` is not a group because `f / f ≠ 1` in general -/


@[simp, to_additive]
protected theorem one_le_div_iff : 1 ≤ f / g ↔ ¬Disjoint f g := by
  refine' ⟨fun h hfg => _, _⟩
  · obtain ⟨s, hs, t, ht, hst⟩ := hfg (mem_bot : ∅ ∈ ⊥)
    exact Set.one_mem_div_iff.1 (h <| div_mem_div hs ht) (disjoint_iff.2 hst.symm)
    
  · rintro h s ⟨t₁, t₂, h₁, h₂, hs⟩
    exact hs (Set.one_mem_div_iff.2 fun ht => h <| disjoint_of_disjoint_of_mem ht h₁ h₂)
    

@[to_additive]
theorem not_one_le_div_iff : ¬1 ≤ f / g ↔ Disjoint f g :=
  Filter.one_le_div_iff.not_left

@[to_additive]
theorem NeBot.one_le_div (h : f.ne_bot) : 1 ≤ f / f := by
  rintro s ⟨t₁, t₂, h₁, h₂, hs⟩
  obtain ⟨a, ha₁, ha₂⟩ := Set.not_disjoint_iff.1 (h.not_disjoint h₁ h₂)
  rw [mem_one, ← div_self' a]
  exact hs (Set.div_mem_div ha₁ ha₂)

@[to_additive]
theorem is_unit_pure (a : α) : IsUnit (pure a : Filter α) :=
  (Groupₓ.is_unit a).filter

@[simp]
theorem is_unit_iff_singleton : IsUnit f ↔ ∃ a, f = pure a := by
  simp only [is_unit_iff, Groupₓ.is_unit, and_trueₓ]

include β

@[to_additive]
theorem map_inv' : f⁻¹.map m = (f.map m)⁻¹ :=
  Semiconj.filter_map (map_inv m) f

@[to_additive]
theorem Tendsto.inv_inv : Tendsto m f₁ f₂ → Tendsto m f₁⁻¹ f₂⁻¹ := fun hf =>
  (Filter.map_inv' m).trans_le <| Filter.inv_le_inv hf

@[to_additive]
protected theorem map_div : (f / g).map m = f.map m / g.map m :=
  map_map₂_distrib <| map_div m

@[to_additive]
theorem Tendsto.div_div : Tendsto m f₁ f₂ → Tendsto m g₁ g₂ → Tendsto m (f₁ / g₁) (f₂ / g₂) := fun hf hg =>
  (Filter.map_div m).trans_le <| Filter.div_le_div hf hg

end Groupₓ

open Pointwise

section GroupWithZeroₓ

variable [GroupWithZeroₓ α] {f g : Filter α}

theorem NeBot.div_zero_nonneg (hf : f.ne_bot) : 0 ≤ f / 0 :=
  Filter.le_div_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨a, ha⟩ := hf.nonempty_of_mem h₁
    ⟨_, _, ha, h₂, div_zero _⟩

theorem NeBot.zero_div_nonneg (hg : g.ne_bot) : 0 ≤ 0 / g :=
  Filter.le_div_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨b, hb⟩ := hg.nonempty_of_mem h₂
    ⟨_, _, h₁, hb, zero_div _⟩

end GroupWithZeroₓ

/-! ### Scalar addition/multiplication of filters -/


section Smul

variable [HasSmul α β] {f f₁ f₂ : Filter α} {g g₁ g₂ h : Filter β} {s : Set α} {t : Set β} {a : α} {b : β}

/-- The filter `f • g` is generated by `{s • t | s ∈ f, t ∈ g}` in locale `pointwise`. -/
@[to_additive Filter.hasVadd "The filter `f +ᵥ g` is generated by `{s +ᵥ t | s ∈ f, t ∈ g}` in locale `pointwise`."]
protected def hasSmul : HasSmul (Filter α) (Filter β) :=
  ⟨/- This is defeq to `map₂ (•) f g`, but the hypothesis unfolds to `t₁ • t₂ ⊆ s` rather than all the
  way to `set.image2 (•) t₁ t₂ ⊆ s`. -/
  fun f g => { map₂ (· • ·) f g with Sets := { s | ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ • t₂ ⊆ s } }⟩

localized [Pointwise] attribute [instance] Filter.hasSmul Filter.hasVadd

@[simp, to_additive]
theorem map₂_smul : map₂ (· • ·) f g = f • g :=
  rfl

@[to_additive]
theorem mem_smul : t ∈ f • g ↔ ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ • t₂ ⊆ t :=
  Iff.rfl

@[to_additive]
theorem smul_mem_smul : s ∈ f → t ∈ g → s • t ∈ f • g :=
  image2_mem_map₂

@[simp, to_additive]
theorem bot_smul : (⊥ : Filter α) • g = ⊥ :=
  map₂_bot_left

@[simp, to_additive]
theorem smul_bot : f • (⊥ : Filter β) = ⊥ :=
  map₂_bot_right

@[simp, to_additive]
theorem smul_eq_bot_iff : f • g = ⊥ ↔ f = ⊥ ∨ g = ⊥ :=
  map₂_eq_bot_iff

@[simp, to_additive]
theorem smul_ne_bot_iff : (f • g).ne_bot ↔ f.ne_bot ∧ g.ne_bot :=
  map₂_ne_bot_iff

@[to_additive]
theorem NeBot.smul : NeBot f → NeBot g → NeBot (f • g) :=
  ne_bot.map₂

@[to_additive]
theorem NeBot.of_smul_left : (f • g).ne_bot → f.ne_bot :=
  ne_bot.of_map₂_left

@[to_additive]
theorem NeBot.of_smul_right : (f • g).ne_bot → g.ne_bot :=
  ne_bot.of_map₂_right

@[simp, to_additive]
theorem pure_smul : (pure a : Filter α) • g = g.map ((· • ·) a) :=
  map₂_pure_left

@[simp, to_additive]
theorem smul_pure : f • pure b = f.map (· • b) :=
  map₂_pure_right

@[simp, to_additive]
theorem pure_smul_pure : (pure a : Filter α) • (pure b : Filter β) = pure (a • b) :=
  map₂_pure

@[to_additive]
theorem smul_le_smul : f₁ ≤ f₂ → g₁ ≤ g₂ → f₁ • g₁ ≤ f₂ • g₂ :=
  map₂_mono

@[to_additive]
theorem smul_le_smul_left : g₁ ≤ g₂ → f • g₁ ≤ f • g₂ :=
  map₂_mono_left

@[to_additive]
theorem smul_le_smul_right : f₁ ≤ f₂ → f₁ • g ≤ f₂ • g :=
  map₂_mono_right

@[simp, to_additive]
theorem le_smul_iff : h ≤ f • g ↔ ∀ ⦃s⦄, s ∈ f → ∀ ⦃t⦄, t ∈ g → s • t ∈ h :=
  le_map₂_iff

@[to_additive]
instance covariant_smul : CovariantClass (Filter α) (Filter β) (· • ·) (· ≤ ·) :=
  ⟨fun f g h => map₂_mono_left⟩

end Smul

/-! ### Scalar subtraction of filters -/


section Vsub

variable [HasVsub α β] {f f₁ f₂ g g₁ g₂ : Filter β} {h : Filter α} {s t : Set β} {a b : β}

include α

/-- The filter `f -ᵥ g` is generated by `{s -ᵥ t | s ∈ f, t ∈ g}` in locale `pointwise`. -/
protected def hasVsub : HasVsub (Filter α) (Filter β) :=
  ⟨/- This is defeq to `map₂ (-ᵥ) f g`, but the hypothesis unfolds to `t₁ -ᵥ t₂ ⊆ s` rather than all
  the way to `set.image2 (-ᵥ) t₁ t₂ ⊆ s`. -/
  fun f g => { map₂ (· -ᵥ ·) f g with Sets := { s | ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ -ᵥ t₂ ⊆ s } }⟩

localized [Pointwise] attribute [instance] Filter.hasVsub

@[simp]
theorem map₂_vsub : map₂ (· -ᵥ ·) f g = f -ᵥ g :=
  rfl

theorem mem_vsub {s : Set α} : s ∈ f -ᵥ g ↔ ∃ t₁ t₂, t₁ ∈ f ∧ t₂ ∈ g ∧ t₁ -ᵥ t₂ ⊆ s :=
  Iff.rfl

theorem vsub_mem_vsub : s ∈ f → t ∈ g → s -ᵥ t ∈ f -ᵥ g :=
  image2_mem_map₂

@[simp]
theorem bot_vsub : (⊥ : Filter β) -ᵥ g = ⊥ :=
  map₂_bot_left

@[simp]
theorem vsub_bot : f -ᵥ (⊥ : Filter β) = ⊥ :=
  map₂_bot_right

@[simp]
theorem vsub_eq_bot_iff : f -ᵥ g = ⊥ ↔ f = ⊥ ∨ g = ⊥ :=
  map₂_eq_bot_iff

@[simp]
theorem vsub_ne_bot_iff : (f -ᵥ g : Filter α).ne_bot ↔ f.ne_bot ∧ g.ne_bot :=
  map₂_ne_bot_iff

theorem NeBot.vsub : NeBot f → NeBot g → NeBot (f -ᵥ g) :=
  ne_bot.map₂

theorem NeBot.of_vsub_left : (f -ᵥ g : Filter α).ne_bot → f.ne_bot :=
  ne_bot.of_map₂_left

theorem NeBot.of_vsub_right : (f -ᵥ g : Filter α).ne_bot → g.ne_bot :=
  ne_bot.of_map₂_right

@[simp]
theorem pure_vsub : (pure a : Filter β) -ᵥ g = g.map ((· -ᵥ ·) a) :=
  map₂_pure_left

@[simp]
theorem vsub_pure : f -ᵥ pure b = f.map (· -ᵥ b) :=
  map₂_pure_right

@[simp]
theorem pure_vsub_pure : (pure a : Filter β) -ᵥ pure b = (pure (a -ᵥ b) : Filter α) :=
  map₂_pure

theorem vsub_le_vsub : f₁ ≤ f₂ → g₁ ≤ g₂ → f₁ -ᵥ g₁ ≤ f₂ -ᵥ g₂ :=
  map₂_mono

theorem vsub_le_vsub_left : g₁ ≤ g₂ → f -ᵥ g₁ ≤ f -ᵥ g₂ :=
  map₂_mono_left

theorem vsub_le_vsub_right : f₁ ≤ f₂ → f₁ -ᵥ g ≤ f₂ -ᵥ g :=
  map₂_mono_right

@[simp]
theorem le_vsub_iff : h ≤ f -ᵥ g ↔ ∀ ⦃s⦄, s ∈ f → ∀ ⦃t⦄, t ∈ g → s -ᵥ t ∈ h :=
  le_map₂_iff

end Vsub

/-! ### Translation/scaling of filters -/


section Smul

variable [HasSmul α β] {f f₁ f₂ : Filter β} {s : Set β} {a : α}

/-- `a • f` is the map of `f` under `a •` in locale `pointwise`. -/
@[to_additive Filter.hasVaddFilter "`a +ᵥ f` is the map of `f` under `a +ᵥ` in locale `pointwise`."]
protected def hasSmulFilter : HasSmul α (Filter β) :=
  ⟨fun a => map ((· • ·) a)⟩

localized [Pointwise] attribute [instance] Filter.hasSmulFilter Filter.hasVaddFilter

@[simp, to_additive]
theorem map_smul : map (fun b => a • b) f = a • f :=
  rfl

@[to_additive]
theorem mem_smul_filter : s ∈ a • f ↔ (· • ·) a ⁻¹' s ∈ f :=
  Iff.rfl

@[to_additive]
theorem smul_set_mem_smul_filter : s ∈ f → a • s ∈ a • f :=
  image_mem_map

@[simp, to_additive]
theorem smul_filter_bot : a • (⊥ : Filter β) = ⊥ :=
  map_bot

@[simp, to_additive]
theorem smul_filter_eq_bot_iff : a • f = ⊥ ↔ f = ⊥ :=
  map_eq_bot_iff

@[simp, to_additive]
theorem smul_filter_ne_bot_iff : (a • f).ne_bot ↔ f.ne_bot :=
  map_ne_bot_iff _

@[to_additive]
theorem NeBot.smul_filter : f.ne_bot → (a • f).ne_bot := fun h => h.map _

@[to_additive]
theorem NeBot.of_smul_filter : (a • f).ne_bot → f.ne_bot :=
  ne_bot.of_map

@[to_additive]
theorem smul_filter_le_smul_filter (hf : f₁ ≤ f₂) : a • f₁ ≤ a • f₂ :=
  map_mono hf

@[to_additive]
instance covariant_smul_filter : CovariantClass α (Filter β) (· • ·) (· ≤ ·) :=
  ⟨fun f => map_mono⟩

end Smul

open Pointwise

@[to_additive]
instance smul_comm_class_filter [HasSmul α γ] [HasSmul β γ] [SmulCommClass α β γ] : SmulCommClass α β (Filter γ) :=
  ⟨fun _ _ _ => map_comm (funext <| smul_comm _ _) _⟩

@[to_additive]
instance smul_comm_class_filter' [HasSmul α γ] [HasSmul β γ] [SmulCommClass α β γ] :
    SmulCommClass α (Filter β) (Filter γ) :=
  ⟨fun a f g => map_map₂_distrib_right <| smul_comm a⟩

@[to_additive]
instance smul_comm_class_filter'' [HasSmul α γ] [HasSmul β γ] [SmulCommClass α β γ] :
    SmulCommClass (Filter α) β (Filter γ) :=
  haveI := SmulCommClass.symm α β γ
  SmulCommClass.symm _ _ _

@[to_additive]
instance smul_comm_class [HasSmul α γ] [HasSmul β γ] [SmulCommClass α β γ] :
    SmulCommClass (Filter α) (Filter β) (Filter γ) :=
  ⟨fun f g h => map₂_left_comm smul_comm⟩

@[to_additive]
instance is_scalar_tower [HasSmul α β] [HasSmul α γ] [HasSmul β γ] [IsScalarTower α β γ] :
    IsScalarTower α β (Filter γ) :=
  ⟨fun a b f => by
    simp only [← map_smul, map_map, smul_assoc]⟩

@[to_additive]
instance is_scalar_tower' [HasSmul α β] [HasSmul α γ] [HasSmul β γ] [IsScalarTower α β γ] :
    IsScalarTower α (Filter β) (Filter γ) :=
  ⟨fun a f g => by
    refine' (map_map₂_distrib_left fun _ _ => _).symm
    exact (smul_assoc a _ _).symm⟩

@[to_additive]
instance is_scalar_tower'' [HasSmul α β] [HasSmul α γ] [HasSmul β γ] [IsScalarTower α β γ] :
    IsScalarTower (Filter α) (Filter β) (Filter γ) :=
  ⟨fun f g h => map₂_assoc smul_assoc⟩

instance is_central_scalar [HasSmul α β] [HasSmul αᵐᵒᵖ β] [IsCentralScalar α β] : IsCentralScalar α (Filter β) :=
  ⟨fun a f => (congr_argₓ fun m => map m f) <| funext fun _ => op_smul_eq_smul _ _⟩

/-- A multiplicative action of a monoid `α` on a type `β` gives a multiplicative action of
`filter α` on `filter β`. -/
@[to_additive
      "An additive action of an additive monoid `α` on a type `β` gives an additive action\nof `filter α` on `filter β`"]
protected def mulAction [Monoidₓ α] [MulAction α β] : MulAction (Filter α) (Filter β) where
  one_smul := fun f =>
    map₂_pure_left.trans <| by
      simp_rw [one_smul, map_id']
  mul_smul := fun f g h => map₂_assoc mul_smul

/-- A multiplicative action of a monoid on a type `β` gives a multiplicative action on `filter β`.
-/
@[to_additive "An additive action of an additive monoid on a type `β` gives an additive action on\n`filter β`."]
protected def mulActionFilter [Monoidₓ α] [MulAction α β] : MulAction α (Filter β) where
  mul_smul := fun a b f => by
    simp only [← map_smul, map_map, Function.comp, ← mul_smul]
  one_smul := fun f => by
    simp only [← map_smul, one_smul, map_id']

localized [Pointwise]
  attribute [instance] Filter.mulAction Filter.addAction Filter.mulActionFilter Filter.addActionFilter

/-- A distributive multiplicative action of a monoid on an additive monoid `β` gives a distributive
multiplicative action on `filter β`. -/
protected def distribMulActionFilter [Monoidₓ α] [AddMonoidₓ β] [DistribMulAction α β] :
    DistribMulAction α (Filter β) where
  smul_add := fun _ _ _ => map_map₂_distrib <| smul_add _
  smul_zero := fun _ =>
    (map_pure _ _).trans <| by
      rw [smul_zero, pure_zero]

/-- A multiplicative action of a monoid on a monoid `β` gives a multiplicative action on `set β`. -/
protected def mulDistribMulActionFilter [Monoidₓ α] [Monoidₓ β] [MulDistribMulAction α β] :
    MulDistribMulAction α (Set β) where
  smul_mul := fun _ _ _ => image_image2_distrib <| smul_mul' _
  smul_one := fun _ =>
    image_singleton.trans <| by
      rw [smul_one, singleton_one]

localized [Pointwise] attribute [instance] Filter.distribMulActionFilter Filter.mulDistribMulActionFilter

section SmulWithZero

variable [Zero α] [Zero β] [SmulWithZero α β] {f : Filter α} {g : Filter β}

/-!
Note that we have neither `smul_with_zero α (filter β)` nor `smul_with_zero (filter α) (filter β)`
because `0 * ⊥ ≠ 0`.
-/


theorem NeBot.smul_zero_nonneg (hf : f.ne_bot) : 0 ≤ f • (0 : Filter β) :=
  le_smul_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨a, ha⟩ := hf.nonempty_of_mem h₁
    ⟨_, _, ha, h₂, smul_zero' _ _⟩

theorem NeBot.zero_smul_nonneg (hg : g.ne_bot) : 0 ≤ (0 : Filter α) • g :=
  le_smul_iff.2 fun t₁ h₁ t₂ h₂ =>
    let ⟨b, hb⟩ := hg.nonempty_of_mem h₂
    ⟨_, _, h₁, hb, zero_smul _ _⟩

theorem zero_smul_filter_nonpos : (0 : α) • g ≤ 0 := by
  refine' fun s hs => mem_smul_filter.2 _
  convert univ_mem
  refine' eq_univ_iff_forall.2 fun a => _
  rwa [mem_preimage, zero_smul]

theorem zero_smul_filter (hg : g.ne_bot) : (0 : α) • g = 0 :=
  zero_smul_filter_nonpos.antisymm <|
    le_map_iff.2 fun s hs => by
      simp_rw [Set.image_eta, zero_smul, (hg.nonempty_of_mem hs).image_const]
      exact zero_mem_zero

end SmulWithZero

end Filter

