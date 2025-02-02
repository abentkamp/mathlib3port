/-
Copyright (c) 2021 Eric Rodriguez. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Rodriguez
-/
import Mathbin.Logic.Embedding

/-!
# Equivalences on embeddings

This file shows some advanced equivalences on embeddings, useful for constructing larger
embeddings from smaller ones.
-/


open Function.Embedding

namespace Equivₓ

-- ./././Mathport/Syntax/Translate/Tactic/Lean3.lean:385:22: warning: unsupported simp config option: iota_eqn
-- ./././Mathport/Syntax/Translate/Tactic/Lean3.lean:385:22: warning: unsupported simp config option: iota_eqn
-- ./././Mathport/Syntax/Translate/Tactic/Lean3.lean:385:22: warning: unsupported simp config option: iota_eqn
-- ./././Mathport/Syntax/Translate/Tactic/Lean3.lean:385:22: warning: unsupported simp config option: iota_eqn
/-- Embeddings from a sum type are equivalent to two separate embeddings with disjoint ranges. -/
def sumEmbeddingEquivProdEmbeddingDisjoint {α β γ : Type _} :
    (Sum α β ↪ γ) ≃ { f : (α ↪ γ) × (β ↪ γ) // Disjoint (Set.Range f.1) (Set.Range f.2) } where
  toFun := fun f =>
    ⟨(inl.trans f, inr.trans f), by
      rintro _ ⟨⟨a, h⟩, ⟨b, rfl⟩⟩
      simp only [trans_apply, inl_apply, inr_apply] at h
      have : Sum.inl a = Sum.inr b := f.injective h
      simp only at this
      assumption⟩
  invFun := fun ⟨⟨f, g⟩, disj⟩ =>
    ⟨fun x =>
      match x with
      | Sum.inl a => f a
      | Sum.inr b => g b,
      by
      rintro (a₁ | b₁) (a₂ | b₂) f_eq <;> simp only [Equivₓ.coe_fn_symm_mk, Sum.elim_inl, Sum.elim_inr] at f_eq
      · rw [f.injective f_eq]
        
      · simp only at f_eq
        exfalso
        exact
          disj
            ⟨⟨a₁, by
                simp ⟩,
              ⟨b₂, by
                simp [f_eq]⟩⟩
        
      · simp only at f_eq
        exfalso
        exact
          disj
            ⟨⟨a₂, by
                simp ⟩,
              ⟨b₁, by
                simp [f_eq]⟩⟩
        
      · rw [g.injective f_eq]
        ⟩
  left_inv := fun f => by
    dsimp' only
    ext
    cases x <;> simp
  right_inv := fun ⟨⟨f, g⟩, _⟩ => by
    simp only [Prod.mk.inj_iffₓ]
    constructor <;> ext <;> simp

/-- Embeddings whose range lies within a set are equivalent to embeddings to that set.
This is `function.embedding.cod_restrict` as an equiv. -/
def codRestrict (α : Type _) {β : Type _} (bs : Set β) : { f : α ↪ β // ∀ a, f a ∈ bs } ≃ (α ↪ bs) where
  toFun := fun f => (f : α ↪ β).codRestrict bs f.Prop
  invFun := fun f => ⟨f.trans (Function.Embedding.subtype _), fun a => (f a).Prop⟩
  left_inv := fun x => by
    ext <;> rfl
  right_inv := fun x => by
    ext <;> rfl

/-- Pairs of embeddings with disjoint ranges are equivalent to a dependent sum of embeddings,
in which the second embedding cannot take values in the range of the first. -/
def prodEmbeddingDisjointEquivSigmaEmbeddingRestricted {α β γ : Type _} :
    { f : (α ↪ γ) × (β ↪ γ) // Disjoint (Set.Range f.1) (Set.Range f.2) } ≃ Σf : α ↪ γ, β ↪ ↥(Set.Range fᶜ) :=
  (subtype_prod_equiv_sigma_subtype fun (a : α ↪ γ) (b : β ↪ _) => Disjoint (Set.Range a) (Set.Range b)).trans <|
    Equivₓ.sigmaCongrRight fun a =>
      (subtype_equiv_prop <| by
            ext f
            rw [← Set.range_subset_iff, Set.subset_compl_iff_disjoint_right, Disjoint.comm]).trans
        (codRestrict _ _)

/-- A combination of the above results, allowing us to turn one embedding over a sum type
into two dependent embeddings, the second of which avoids any members of the range
of the first. This is helpful for constructing larger embeddings out of smaller ones. -/
def sumEmbeddingEquivSigmaEmbeddingRestricted {α β γ : Type _} : (Sum α β ↪ γ) ≃ Σf : α ↪ γ, β ↪ ↥(Set.Range fᶜ) :=
  Equivₓ.trans sumEmbeddingEquivProdEmbeddingDisjoint prodEmbeddingDisjointEquivSigmaEmbeddingRestricted

/-- Embeddings from a single-member type are equivalent to members of the target type. -/
def uniqueEmbeddingEquivResult {α β : Type _} [Unique α] : (α ↪ β) ≃ β where
  toFun := fun f => f default
  invFun := fun x => ⟨fun _ => x, fun _ _ _ => Subsingleton.elim _ _⟩
  left_inv := fun _ => by
    ext
    simp_rw [Function.Embedding.coe_fn_mk]
    congr
  right_inv := fun _ => by
    simp

end Equivₓ

