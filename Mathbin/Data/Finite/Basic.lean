/-
Copyright (c) 2022 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller
-/
import Mathbin.Data.Fintype.Basic

/-!
# Finite types

In this file we prove some theorems about `finite` and provide some instances. This typeclass is a
`Prop`-valued counterpart of the typeclass `fintype`. See more details in the file where `finite` is
defined.

## Main definitions

* `fintype.finite`, `finite.of_fintype` creates a `finite` instance from a `fintype` instance. The
  former lemma takes `fintype α` as an explicit argument while the latter takes it as an instance
  argument.
* `fintype.of_finite` noncomputably creates a `fintype` instance from a `finite` instance.
* `finite_or_infinite` is that every type is either `finite` or `infinite`.

## Implementation notes

There is an apparent duplication of many `fintype` instances in this module,
however they follow a pattern: if a `fintype` instance depends on `decidable`
instances or other `fintype` instances, then we need to "lower" the instance
to be a `finite` instance by removing the `decidable` instances and switching
the `fintype` instances to `finite` instances. These are precisely the ones
that cannot be inferred using `finite.of_fintype`. (However, when using
`open_locale classical` or the `classical` tactic the instances relying only
on `decidable` instances will give `finite` instances.) In the future we might
consider writing automation to create these "lowered" instances.

## Tags

finiteness, finite types
-/


noncomputable section

open Classical

variable {α β γ : Type _}

theorem finite_or_infinite (α : Type _) : Finite α ∨ Infinite α := by
  rw [← not_finite_iff_infinite]
  apply em

namespace Finite

-- see Note [lower instance priority]
instance (priority := 100) of_subsingleton {α : Sort _} [Subsingleton α] : Finite α :=
  of_injective (Function.const α ()) <| Function.injective_of_subsingletonₓ _

-- Higher priority for `Prop`s
@[nolint instance_priority]
instance prop (p : Prop) : Finite p :=
  Finite.of_subsingleton

instance [Finite α] [Finite β] : Finite (α × β) := by
  haveI := Fintype.ofFinite α
  haveI := Fintype.ofFinite β
  infer_instance

instance {α β : Sort _} [Finite α] [Finite β] : Finite (PProd α β) :=
  of_equiv _ Equivₓ.pprodEquivProdPlift.symm

theorem prod_left (β) [Finite (α × β)] [Nonempty β] : Finite α :=
  of_surjective (Prod.fst : α × β → α) Prod.fst_surjective

theorem prod_right (α) [Finite (α × β)] [Nonempty α] : Finite β :=
  of_surjective (Prod.snd : α × β → β) Prod.snd_surjectiveₓ

instance [Finite α] [Finite β] : Finite (Sum α β) := by
  haveI := Fintype.ofFinite α
  haveI := Fintype.ofFinite β
  infer_instance

theorem sum_left (β) [Finite (Sum α β)] : Finite α :=
  of_injective (Sum.inl : α → Sum α β) Sum.inl_injective

theorem sum_right (α) [Finite (Sum α β)] : Finite β :=
  of_injective (Sum.inr : β → Sum α β) Sum.inr_injective

instance {β : α → Type _} [Finite α] [∀ a, Finite (β a)] : Finite (Σa, β a) := by
  letI := Fintype.ofFinite α
  letI := fun a => Fintype.ofFinite (β a)
  infer_instance

instance {ι : Sort _} {π : ι → Sort _} [Finite ι] [∀ i, Finite (π i)] : Finite (Σ'i, π i) :=
  of_equiv _ (Equivₓ.psigmaEquivSigmaPlift π).symm

instance [Finite α] : Finite (Set α) := by
  cases nonempty_fintype α
  infer_instance

end Finite

/-- This instance also provides `[finite s]` for `s : set α`. -/
instance Subtype.finite {α : Sort _} [Finite α] {p : α → Prop} : Finite { x // p x } :=
  Finite.of_injective coe Subtype.coe_injective

instance Pi.finite {α : Sort _} {β : α → Sort _} [Finite α] [∀ a, Finite (β a)] : Finite (∀ a, β a) := by
  haveI := Fintype.ofFinite (Plift α)
  haveI := fun a => Fintype.ofFinite (Plift (β a))
  exact Finite.of_equiv (∀ a : Plift α, Plift (β (Equivₓ.plift a))) (Equivₓ.piCongr Equivₓ.plift fun _ => Equivₓ.plift)

instance Vector.finite {α : Type _} [Finite α] {n : ℕ} : Finite (Vector α n) := by
  haveI := Fintype.ofFinite α
  infer_instance

instance Quot.finite {α : Sort _} [Finite α] (r : α → α → Prop) : Finite (Quot r) :=
  Finite.of_surjective _ (surjective_quot_mk r)

instance Quotientₓ.finite {α : Sort _} [Finite α] (s : Setoidₓ α) : Finite (Quotientₓ s) :=
  Quot.finite _

instance Function.Embedding.finite {α β : Sort _} [Finite β] : Finite (α ↪ β) := by
  cases' is_empty_or_nonempty (α ↪ β) with _ h
  · infer_instance
    
  · refine' h.elim fun f => _
    haveI : Finite α := Finite.of_injective _ f.injective
    exact Finite.of_injective _ FunLike.coe_injective
    

instance Equivₓ.finite_right {α β : Sort _} [Finite β] : Finite (α ≃ β) :=
  (Finite.of_injective Equivₓ.toEmbedding) fun e₁ e₂ h =>
    Equivₓ.ext <| by
      convert FunLike.congr_fun h

instance Equivₓ.finite_left {α β : Sort _} [Finite α] : Finite (α ≃ β) :=
  Finite.of_equiv _ ⟨Equivₓ.symm, Equivₓ.symm, Equivₓ.symm_symm, Equivₓ.symm_symm⟩

instance [Finite α] {n : ℕ} : Finite (Sym α n) := by
  haveI := Fintype.ofFinite α
  infer_instance

