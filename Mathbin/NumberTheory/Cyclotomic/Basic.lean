/-
Copyright (c) 2021 Riccardo Brasca. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Riccardo Brasca
-/
import Mathbin.RingTheory.Polynomial.Cyclotomic.Basic
import Mathbin.NumberTheory.NumberField
import Mathbin.Algebra.CharP.Algebra
import Mathbin.FieldTheory.Galois

/-!
# Cyclotomic extensions

Let `A` and `B` be commutative rings with `algebra A B`. For `S : set ℕ+`, we define a class
`is_cyclotomic_extension S A B` expressing the fact that `B` is obtained from `A` by adding `n`-th
primitive roots of unity, for all `n ∈ S`.

## Main definitions

* `is_cyclotomic_extension S A B` : means that `B` is obtained from `A` by adding `n`-th primitive
  roots of unity, for all `n ∈ S`.
* `cyclotomic_field`: given `n : ℕ+` and a field `K`, we define `cyclotomic n K` as the splitting
  field of `cyclotomic n K`. If `n` is nonzero in `K`, it has the instance
  `is_cyclotomic_extension {n} K (cyclotomic_field n K)`.
* `cyclotomic_ring` : if `A` is a domain with fraction field `K` and `n : ℕ+`, we define
  `cyclotomic_ring n A K` as the `A`-subalgebra of `cyclotomic_field n K` generated by the roots of
  `X ^ n - 1`. If `n` is nonzero in `A`, it has the instance
  `is_cyclotomic_extension {n} A (cyclotomic_ring n A K)`.

## Main results

* `is_cyclotomic_extension.trans` : if `is_cyclotomic_extension S A B` and
  `is_cyclotomic_extension T B C`, then `is_cyclotomic_extension (S ∪ T) A C` if
  `no_zero_smul_divisors B C` and `nontrivial C`.
* `is_cyclotomic_extension.union_right` : given `is_cyclotomic_extension (S ∪ T) A B`, then
  `is_cyclotomic_extension T (adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }) B`.
* `is_cyclotomic_extension.union_right` : given `is_cyclotomic_extension T A B` and `S ⊆ T`, then
  `is_cyclotomic_extension S A (adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 })`.
* `is_cyclotomic_extension.finite` : if `S` is finite and `is_cyclotomic_extension S A B`, then
  `B` is a finite `A`-algebra.
* `is_cyclotomic_extension.number_field` : a finite cyclotomic extension of a number field is a
  number field.
* `is_cyclotomic_extension.splitting_field_X_pow_sub_one` : if `is_cyclotomic_extension {n} K L`,
  then `L` is the splitting field of `X ^ n - 1`.
* `is_cyclotomic_extension.splitting_field_cyclotomic` : if `is_cyclotomic_extension {n} K L`,
  then `L` is the splitting field of `cyclotomic n K`.

## Implementation details

Our definition of `is_cyclotomic_extension` is very general, to allow rings of any characteristic
and infinite extensions, but it will mainly be used in the case `S = {n}` and for integral domains.
All results are in the `is_cyclotomic_extension` namespace.
Note that some results, for example `is_cyclotomic_extension.trans`,
`is_cyclotomic_extension.finite`, `is_cyclotomic_extension.number_field`,
`is_cyclotomic_extension.finite_dimensional`, `is_cyclotomic_extension.is_galois` and
`cyclotomic_field.algebra_base` are lemmas, but they can be made local instances. Some of them are
included in the `cyclotomic` locale.

-/


open Polynomial Algebra FiniteDimensional Module Set

open BigOperators

universe u v w z

variable (n : ℕ+) (S T : Set ℕ+) (A : Type u) (B : Type v) (K : Type w) (L : Type z)

variable [CommRingₓ A] [CommRingₓ B] [Algebra A B]

variable [Field K] [Field L] [Algebra K L]

noncomputable section

/-- Given an `A`-algebra `B` and `S : set ℕ+`, we define `is_cyclotomic_extension S A B` requiring
that there is a `a`-th primitive root of unity in `B` for all `a ∈ S` and that `B` is generated
over `A` by the roots of `X ^ n - 1`. -/
@[mk_iff]
class IsCyclotomicExtension : Prop where
  exists_prim_root {a : ℕ+} (ha : a ∈ S) : ∃ r : B, IsPrimitiveRoot r a
  adjoin_roots : ∀ x : B, x ∈ adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }

namespace IsCyclotomicExtension

section Basic

/-- A reformulation of `is_cyclotomic_extension` that uses `⊤`. -/
theorem iff_adjoin_eq_top :
    IsCyclotomicExtension S A B ↔
      (∀ a : ℕ+, a ∈ S → ∃ r : B, IsPrimitiveRoot r a) ∧ adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 } = ⊤ :=
  ⟨fun h => ⟨h.exists_prim_root, Algebra.eq_top_iff.2 h.adjoin_roots⟩, fun h => ⟨h.1, Algebra.eq_top_iff.1 h.2⟩⟩

/-- A reformulation of `is_cyclotomic_extension` in the case `S` is a singleton. -/
theorem iff_singleton :
    IsCyclotomicExtension {n} A B ↔ (∃ r : B, IsPrimitiveRoot r n) ∧ ∀ x, x ∈ adjoin A { b : B | b ^ (n : ℕ) = 1 } := by
  simp [← is_cyclotomic_extension_iff]

/-- If `is_cyclotomic_extension ∅ A B`, then the image of `A` in `B` equals `B`. -/
theorem empty [h : IsCyclotomicExtension ∅ A B] : (⊥ : Subalgebra A B) = ⊤ := by
  simpa [← Algebra.eq_top_iff, ← is_cyclotomic_extension_iff] using h

/-- If `is_cyclotomic_extension {1} A B`, then the image of `A` in `B` equals `B`. -/
theorem singleton_one [h : IsCyclotomicExtension {1} A B] : (⊥ : Subalgebra A B) = ⊤ :=
  Algebra.eq_top_iff.2 fun x => by
    simpa [← adjoin_singleton_one] using ((is_cyclotomic_extension_iff _ _ _).1 h).2 x

/-- Transitivity of cyclotomic extensions. -/
theorem trans (C : Type w) [CommRingₓ C] [Nontrivial C] [Algebra A C] [Algebra B C] [IsScalarTower A B C]
    [hS : IsCyclotomicExtension S A B] [hT : IsCyclotomicExtension T B C] [NoZeroSmulDivisors B C] :
    IsCyclotomicExtension (S ∪ T) A C := by
  refine' ⟨fun n hn => _, fun x => _⟩
  · cases hn
    · obtain ⟨b, hb⟩ := ((is_cyclotomic_extension_iff _ _ _).1 hS).1 hn
      refine' ⟨algebraMap B C b, _⟩
      exact hb.map_of_injective (NoZeroSmulDivisors.algebra_map_injective B C)
      
    · exact ((is_cyclotomic_extension_iff _ _ _).1 hT).1 hn
      
    
  · refine'
      adjoin_induction (((is_cyclotomic_extension_iff _ _ _).1 hT).2 x)
        (fun c ⟨n, hn⟩ => subset_adjoin ⟨n, Or.inr hn.1, hn.2⟩) (fun b => _)
        (fun x y hx hy => Subalgebra.add_mem _ hx hy) fun x y hx hy => Subalgebra.mul_mem _ hx hy
    · let f := IsScalarTower.toAlgHom A B C
      have hb : f b ∈ (adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }).map f :=
        ⟨b, ((is_cyclotomic_extension_iff _ _ _).1 hS).2 b, rfl⟩
      rw [IsScalarTower.to_alg_hom_apply, ← adjoin_image] at hb
      refine' adjoin_mono (fun y hy => _) hb
      obtain ⟨b₁, ⟨⟨n, hn⟩, h₁⟩⟩ := hy
      exact
        ⟨n,
          ⟨mem_union_left T hn.1, by
            rw [← h₁, ← AlgHom.map_pow, hn.2, AlgHom.map_one]⟩⟩
      
    

@[nontriviality]
theorem subsingleton_iff [Subsingleton B] : IsCyclotomicExtension S A B ↔ S = {  } ∨ S = {1} := by
  constructor
  · rintro ⟨hprim, -⟩
    rw [← subset_singleton_iff_eq]
    intro t ht
    obtain ⟨ζ, hζ⟩ := hprim ht
    rw [mem_singleton_iff, ← Pnat.coe_eq_one_iff]
    exact_mod_cast hζ.unique (IsPrimitiveRoot.of_subsingleton ζ)
    
  · rintro (rfl | rfl)
    · refine'
        ⟨fun _ h => h.elim, fun x => by
          convert (mem_top : x ∈ ⊤)⟩
      
    · rw [iff_singleton]
      refine'
        ⟨⟨0, IsPrimitiveRoot.of_subsingleton 0⟩, fun x => by
          convert (mem_top : x ∈ ⊤)⟩
      
    

/-- If `B` is a cyclotomic extension of `A` given by roots of unity of order in `S ∪ T`, then `B`
is a cyclotomic extension of `adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 } ` given by
roots of unity of order in `T`. -/
theorem union_right [h : IsCyclotomicExtension (S ∪ T) A B] :
    IsCyclotomicExtension T (adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }) B := by
  have :
    { b : B | ∃ n : ℕ+, n ∈ S ∪ T ∧ b ^ (n : ℕ) = 1 } =
      { b : B | ∃ n : ℕ+, n ∈ S ∧ b ^ (n : ℕ) = 1 } ∪ { b : B | ∃ n : ℕ+, n ∈ T ∧ b ^ (n : ℕ) = 1 } :=
    by
    refine' le_antisymmₓ (fun x hx => _) fun x hx => _
    · rcases hx with ⟨n, hn₁ | hn₂, hnpow⟩
      · left
        exact ⟨n, hn₁, hnpow⟩
        
      · right
        exact ⟨n, hn₂, hnpow⟩
        
      
    · rcases hx with (⟨n, hn⟩ | ⟨n, hn⟩)
      · exact ⟨n, Or.inl hn.1, hn.2⟩
        
      · exact ⟨n, Or.inr hn.1, hn.2⟩
        
      
  refine' ⟨fun n hn => ((is_cyclotomic_extension_iff _ _ _).1 h).1 (mem_union_right S hn), fun b => _⟩
  replace h := ((is_cyclotomic_extension_iff _ _ _).1 h).2 b
  rwa [this, adjoin_union_eq_adjoin_adjoin, Subalgebra.mem_restrict_scalars] at h

/-- If `B` is a cyclotomic extension of `A` given by roots of unity of order in `T` and `S ⊆ T`,
then `adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }` is a cyclotomic extension of `B`
given by roots of unity of order in `S`. -/
theorem union_left [h : IsCyclotomicExtension T A B] (hS : S ⊆ T) :
    IsCyclotomicExtension S A (adjoin A { b : B | ∃ a : ℕ+, a ∈ S ∧ b ^ (a : ℕ) = 1 }) := by
  refine' ⟨fun n hn => _, fun b => _⟩
  · obtain ⟨b, hb⟩ := ((is_cyclotomic_extension_iff _ _ _).1 h).1 (hS hn)
    refine' ⟨⟨b, subset_adjoin ⟨n, hn, hb.pow_eq_one⟩⟩, _⟩
    rwa [← IsPrimitiveRoot.coe_submonoid_class_iff, Subtype.coe_mk]
    
  · convert mem_top
    rw [← adjoin_adjoin_coe_preimage, preimage_set_of_eq]
    norm_cast
    

@[protected]
theorem ne_zero [h : IsCyclotomicExtension {n} A B] [IsDomain B] : NeZero ((n : ℕ) : B) := by
  obtain ⟨⟨r, hr⟩, -⟩ := (iff_singleton n A B).1 h
  exact hr.ne_zero'

@[protected]
theorem ne_zero' [IsCyclotomicExtension {n} A B] [IsDomain B] : NeZero ((n : ℕ) : A) := by
  apply NeZero.nat_of_ne_zero (algebraMap A B)
  exact NeZero n A B

end Basic

section Fintype

theorem finite_of_singleton [IsDomain B] [h : IsCyclotomicExtension {n} A B] : Finite A B := by
  classical
  rw [Module.finite_def, ← top_to_submodule, ← ((iff_adjoin_eq_top _ _ _).1 h).2]
  refine' fg_adjoin_of_finite _ fun b hb => _
  · simp only [← mem_singleton_iff, ← exists_eq_left]
    have : { b : B | b ^ (n : ℕ) = 1 } = (nth_roots n (1 : B)).toFinset :=
      Set.ext fun x =>
        ⟨fun h => by
          simpa using h, fun h => by
          simpa using h⟩
    rw [this]
    exact (nth_roots (↑n) 1).toFinset.finite_to_set
    
  · simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq] at hb
    refine'
      ⟨X ^ (n : ℕ) - 1,
        ⟨monic_X_pow_sub_C _ n.pos.ne.symm, by
          simp [← hb]⟩⟩
    

/-- If `S` is finite and `is_cyclotomic_extension S A B`, then `B` is a finite `A`-algebra. -/
theorem finite [IsDomain B] [h₁ : Fintype S] [h₂ : IsCyclotomicExtension S A B] : Finite A B := by
  revert h₂ A B
  refine' Set.Finite.induction_on (Set.Finite.intro h₁) (fun A B => _) fun n S hn hS H A B => _
  · intro _ _ _ _ _
    refine' Module.finite_def.2 ⟨({1} : Finset B), _⟩
    simp [top_to_submodule, Empty, ← to_submodule_bot]
    
  · intro _ _ _ _ h
    haveI : IsCyclotomicExtension S A (adjoin A { b : B | ∃ n : ℕ+, n ∈ S ∧ b ^ (n : ℕ) = 1 }) :=
      union_left _ (insert n S) _ _ (subset_insert n S)
    haveI := H A (adjoin A { b : B | ∃ n : ℕ+, n ∈ S ∧ b ^ (n : ℕ) = 1 })
    have : Finite (adjoin A { b : B | ∃ n : ℕ+, n ∈ S ∧ b ^ (n : ℕ) = 1 }) B := by
      rw [← union_singleton] at h
      letI := @union_right S {n} A B _ _ _ h
      exact finite_of_singleton n _ _
    exact finite.trans (adjoin A { b : B | ∃ n : ℕ+, n ∈ S ∧ b ^ (n : ℕ) = 1 }) _
    

/-- A cyclotomic finite extension of a number field is a number field. -/
theorem number_field [h : NumberField K] [Fintype S] [IsCyclotomicExtension S K L] : NumberField L :=
  { to_char_zero := char_zero_of_injective_algebra_map (algebraMap K L).Injective,
    to_finite_dimensional :=
      @Finite.trans _ K L _ _ _ _ (@algebraRat L _ (char_zero_of_injective_algebra_map (algebraMap K L).Injective)) _ _
        h.to_finite_dimensional (finite S K L) }

localized [Cyclotomic] attribute [instance] IsCyclotomicExtension.number_field

/-- A finite cyclotomic extension of an integral noetherian domain is integral -/
theorem integral [IsDomain B] [IsNoetherianRing A] [Fintype S] [IsCyclotomicExtension S A B] : Algebra.IsIntegral A B :=
  is_integral_of_noetherian <| is_noetherian_of_fg_of_noetherian' <| (finite S A B).out

/-- If `S` is finite and `is_cyclotomic_extension S K A`, then `finite_dimensional K A`. -/
theorem finite_dimensional (C : Type z) [Fintype S] [CommRingₓ C] [Algebra K C] [IsDomain C]
    [IsCyclotomicExtension S K C] : FiniteDimensional K C :=
  finite S K C

localized [Cyclotomic] attribute [instance] IsCyclotomicExtension.finite_dimensional

end Fintype

section

variable {A B}

theorem adjoin_roots_cyclotomic_eq_adjoin_nth_roots [DecidableEq B] [IsDomain B] {ζ : B} {n : ℕ+}
    (hζ : IsPrimitiveRoot ζ n) :
    adjoin A ↑(map (algebraMap A B) (cyclotomic n A)).roots.toFinset =
      adjoin A { b : B | ∃ a : ℕ+, a ∈ ({n} : Set ℕ+) ∧ b ^ (a : ℕ) = 1 } :=
  by
  simp only [← mem_singleton_iff, ← exists_eq_left, ← map_cyclotomic]
  refine' le_antisymmₓ (adjoin_mono fun x hx => _) (adjoin_le fun x hx => _)
  · simp only [← Multiset.mem_to_finset, ← Finset.mem_coe, ← map_cyclotomic, ← mem_roots (cyclotomic_ne_zero n B)] at hx
    simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq]
    rw [is_root_of_unity_iff n.pos]
    exact ⟨n, Nat.mem_divisors_self n n.ne_zero, hx⟩
    
  · simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq] at hx
    obtain ⟨i, hin, rfl⟩ := hζ.eq_pow_of_pow_eq_one hx n.pos
    refine' SetLike.mem_coe.2 (Subalgebra.pow_mem _ (subset_adjoin _) _)
    rwa [Finset.mem_coe, Multiset.mem_to_finset, mem_roots <| cyclotomic_ne_zero n B]
    exact hζ.is_root_cyclotomic n.pos
    

theorem adjoin_roots_cyclotomic_eq_adjoin_root_cyclotomic {n : ℕ+} [DecidableEq B] [IsDomain B] {ζ : B}
    (hζ : IsPrimitiveRoot ζ n) :
    adjoin A ((map (algebraMap A B) (cyclotomic n A)).roots.toFinset : Set B) = adjoin A {ζ} := by
  refine' le_antisymmₓ (adjoin_le fun x hx => _) (adjoin_mono fun x hx => _)
  · suffices hx : x ^ ↑n = 1
    obtain ⟨i, hin, rfl⟩ := hζ.eq_pow_of_pow_eq_one hx n.pos
    exact SetLike.mem_coe.2 (Subalgebra.pow_mem _ (subset_adjoin <| mem_singleton ζ) _)
    rw [is_root_of_unity_iff n.pos]
    refine' ⟨n, Nat.mem_divisors_self n n.ne_zero, _⟩
    rwa [Finset.mem_coe, Multiset.mem_to_finset, map_cyclotomic, mem_roots <| cyclotomic_ne_zero n B] at hx
    
  · simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq] at hx
    simpa only [← hx, ← Multiset.mem_to_finset, ← Finset.mem_coe, ← map_cyclotomic, ←
      mem_roots (cyclotomic_ne_zero n B)] using hζ.is_root_cyclotomic n.pos
    

theorem adjoin_primitive_root_eq_top {n : ℕ+} [IsDomain B] [h : IsCyclotomicExtension {n} A B] {ζ : B}
    (hζ : IsPrimitiveRoot ζ n) : adjoin A ({ζ} : Set B) = ⊤ := by
  classical
  rw [← adjoin_roots_cyclotomic_eq_adjoin_root_cyclotomic hζ]
  rw [adjoin_roots_cyclotomic_eq_adjoin_nth_roots hζ]
  exact ((iff_adjoin_eq_top {n} A B).mp h).2

variable (A)

theorem _root_.is_primitive_root.adjoin_is_cyclotomic_extension {ζ : B} {n : ℕ+} (h : IsPrimitiveRoot ζ n) :
    IsCyclotomicExtension {n} A (adjoin A ({ζ} : Set B)) :=
  { exists_prim_root := fun i hi => by
      rw [Set.mem_singleton_iff] at hi
      refine' ⟨⟨ζ, subset_adjoin <| Set.mem_singleton ζ⟩, _⟩
      rwa [← IsPrimitiveRoot.coe_submonoid_class_iff, Subtype.coe_mk, hi],
    adjoin_roots := fun x => by
      refine' adjoin_induction' (fun b hb => _) (fun a => _) (fun b₁ b₂ hb₁ hb₂ => _) (fun b₁ b₂ hb₁ hb₂ => _) x
      · rw [Set.mem_singleton_iff] at hb
        refine' subset_adjoin _
        simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq, ← hb]
        rw [← Subalgebra.coe_eq_one, Subalgebra.coe_pow, SetLike.coe_mk]
        exact ((IsPrimitiveRoot.iff_def ζ n).1 h).1
        
      · exact Subalgebra.algebra_map_mem _ _
        
      · exact Subalgebra.add_mem _ hb₁ hb₂
        
      · exact Subalgebra.mul_mem _ hb₁ hb₂
         }

end

section Field

variable {n S}

/-- A cyclotomic extension splits `X ^ n - 1` if `n ∈ S`.-/
theorem splits_X_pow_sub_one [H : IsCyclotomicExtension S K L] (hS : n ∈ S) :
    Splits (algebraMap K L) (X ^ (n : ℕ) - 1) := by
  rw [← splits_id_iff_splits, Polynomial.map_sub, Polynomial.map_one, Polynomial.map_pow, Polynomial.map_X]
  obtain ⟨z, hz⟩ := ((is_cyclotomic_extension_iff _ _ _).1 H).1 hS
  exact X_pow_sub_one_splits hz

/-- A cyclotomic extension splits `cyclotomic n K` if `n ∈ S` and `ne_zero (n : K)`.-/
theorem splits_cyclotomic [IsCyclotomicExtension S K L] (hS : n ∈ S) : Splits (algebraMap K L) (cyclotomic n K) := by
  refine' splits_of_splits_of_dvd _ (X_pow_sub_C_ne_zero n.pos _) (splits_X_pow_sub_one K L hS) _
  use ∏ i : ℕ in (n : ℕ).properDivisors, Polynomial.cyclotomic i K
  rw [(eq_cyclotomic_iff n.pos _).1 rfl, RingHom.map_one]

variable (n S)

section Singleton

variable [IsCyclotomicExtension {n} K L]

/-- If `is_cyclotomic_extension {n} K L`, then `L` is the splitting field of `X ^ n - 1`. -/
theorem splitting_field_X_pow_sub_one : IsSplittingField K L (X ^ (n : ℕ) - 1) :=
  { Splits := splits_X_pow_sub_one K L (mem_singleton n),
    adjoin_roots := by
      rw [← ((iff_adjoin_eq_top {n} K L).1 inferInstance).2]
      congr
      refine' Set.ext fun x => _
      simp only [← Polynomial.map_pow, ← mem_singleton_iff, ← Multiset.mem_to_finset, ← exists_eq_left, ← mem_set_of_eq,
        ← Polynomial.map_X, ← Polynomial.map_one, ← Finset.mem_coe, ← Polynomial.map_sub]
      rwa [← RingHom.map_one C, mem_roots (@X_pow_sub_C_ne_zero L _ _ _ n.pos _), is_root.def, eval_sub, eval_pow,
        eval_C, eval_X, sub_eq_zero] }

localized [Cyclotomic] attribute [instance] IsCyclotomicExtension.splitting_field_X_pow_sub_one

include n

theorem is_galois : IsGalois K L := by
  letI := splitting_field_X_pow_sub_one n K L
  exact IsGalois.of_separable_splitting_field (X_pow_sub_one_separable_iff.2 (ne_zero' n K L).1)

localized [Cyclotomic] attribute [instance] IsCyclotomicExtension.is_galois

/-- If `is_cyclotomic_extension {n} K L`, then `L` is the splitting field of `cyclotomic n K`. -/
theorem splitting_field_cyclotomic : IsSplittingField K L (cyclotomic n K) :=
  { Splits := splits_cyclotomic K L (mem_singleton n),
    adjoin_roots := by
      rw [← ((iff_adjoin_eq_top {n} K L).1 inferInstance).2]
      letI := Classical.decEq L
      obtain ⟨ζ, hζ⟩ := @IsCyclotomicExtension.exists_prim_root {n} K L _ _ _ _ _ (mem_singleton n)
      exact adjoin_roots_cyclotomic_eq_adjoin_nth_roots hζ }

localized [Cyclotomic] attribute [instance] IsCyclotomicExtension.splitting_field_cyclotomic

end Singleton

end Field

end IsCyclotomicExtension

section CyclotomicField

-- ./././Mathport/Syntax/Translate/Basic.lean:1160:9: unsupported derive handler algebra K
/-- Given `n : ℕ+` and a field `K`, we define `cyclotomic_field n K` as the
splitting field of `cyclotomic n K`. If `n` is nonzero in `K`, it has
the instance `is_cyclotomic_extension {n} K (cyclotomic_field n K)`. -/
def CyclotomicField : Type w :=
  (cyclotomic n K).SplittingField deriving Field,
  «./././Mathport/Syntax/Translate/Basic.lean:1160:9: unsupported derive handler algebra K», Inhabited

namespace CyclotomicField

instance [CharZero K] : CharZero (CyclotomicField n K) :=
  char_zero_of_injective_algebra_map (algebraMap K _).Injective

instance is_cyclotomic_extension [NeZero ((n : ℕ) : K)] : IsCyclotomicExtension {n} K (CyclotomicField n K) where
  exists_prim_root := fun a han => by
    rw [mem_singleton_iff] at han
    subst a
    obtain ⟨r, hr⟩ :=
      exists_root_of_splits (algebraMap K (CyclotomicField n K)) (splitting_field.splits _)
        (degree_cyclotomic_pos n K n.pos).ne'
    refine' ⟨r, _⟩
    haveI := NeZero.of_no_zero_smul_divisors K (CyclotomicField n K) n
    rwa [← eval_map, ← is_root.def, map_cyclotomic, is_root_cyclotomic_iff] at hr
  adjoin_roots := by
    rw [← Algebra.eq_top_iff, ← splitting_field.adjoin_roots, eq_comm]
    letI := Classical.decEq (CyclotomicField n K)
    obtain ⟨ζ, hζ⟩ :=
      exists_root_of_splits _ (splitting_field.splits (cyclotomic n K)) (degree_cyclotomic_pos n _ n.pos).ne'
    haveI : NeZero ((n : ℕ) : CyclotomicField n K) := NeZero.nat_of_injective (algebraMap K _).Injective
    rw [eval₂_eq_eval_map, map_cyclotomic, ← is_root.def, is_root_cyclotomic_iff] at hζ
    exact IsCyclotomicExtension.adjoin_roots_cyclotomic_eq_adjoin_nth_roots hζ

end CyclotomicField

end CyclotomicField

section IsDomain

variable [IsDomain A] [Algebra A K] [IsFractionRing A K]

section CyclotomicRing

/-- If `K` is the fraction field of `A`, the `A`-algebra structure on `cyclotomic_field n K`.
This is not an instance since it causes diamonds when `A = ℤ`. -/
@[nolint unused_arguments]
def CyclotomicField.algebraBase : Algebra A (CyclotomicField n K) :=
  ((algebraMap K (CyclotomicField n K)).comp (algebraMap A K)).toAlgebra

attribute [local instance] CyclotomicField.algebraBase

instance CyclotomicField.no_zero_smul_divisors : NoZeroSmulDivisors A (CyclotomicField n K) :=
  NoZeroSmulDivisors.of_algebra_map_injective <|
    Function.Injective.comp (NoZeroSmulDivisors.algebra_map_injective _ _) <| IsFractionRing.injective A K

/-- If `A` is a domain with fraction field `K` and `n : ℕ+`, we define `cyclotomic_ring n A K` as
the `A`-subalgebra of `cyclotomic_field n K` generated by the roots of `X ^ n - 1`. If `n`
is nonzero in `A`, it has the instance `is_cyclotomic_extension {n} A (cyclotomic_ring n A K)`. -/
def CyclotomicRing : Type w :=
  adjoin A { b : CyclotomicField n K | b ^ (n : ℕ) = 1 }deriving CommRingₓ, IsDomain, Inhabited

namespace CyclotomicRing

/-- The `A`-algebra structure on `cyclotomic_ring n A K`.
This is not an instance since it causes diamonds when `A = ℤ`. -/
def algebraBase : Algebra A (CyclotomicRing n A K) :=
  (adjoin A _).Algebra

attribute [local instance] CyclotomicRing.algebraBase

instance : NoZeroSmulDivisors A (CyclotomicRing n A K) :=
  (adjoin A _).no_zero_smul_divisors_bot

theorem algebra_base_injective : Function.Injective <| algebraMap A (CyclotomicRing n A K) :=
  NoZeroSmulDivisors.algebra_map_injective _ _

instance : Algebra (CyclotomicRing n A K) (CyclotomicField n K) :=
  (adjoin A _).toAlgebra

theorem adjoin_algebra_injective : Function.Injective <| algebraMap (CyclotomicRing n A K) (CyclotomicField n K) :=
  Subtype.val_injective

instance : NoZeroSmulDivisors (CyclotomicRing n A K) (CyclotomicField n K) :=
  NoZeroSmulDivisors.of_algebra_map_injective (adjoin_algebra_injective n A K)

instance : IsScalarTower A (CyclotomicRing n A K) (CyclotomicField n K) :=
  IsScalarTower.subalgebra' _ _ _ _

instance is_cyclotomic_extension [NeZero ((n : ℕ) : A)] : IsCyclotomicExtension {n} A (CyclotomicRing n A K) where
  exists_prim_root := fun a han => by
    rw [mem_singleton_iff] at han
    subst a
    haveI := NeZero.of_no_zero_smul_divisors A K n
    haveI := NeZero.of_no_zero_smul_divisors A (CyclotomicField n K) n
    obtain ⟨μ, hμ⟩ :=
      let h := (CyclotomicField.is_cyclotomic_extension n K).exists_prim_root
      h <| mem_singleton n
    refine' ⟨⟨μ, subset_adjoin _⟩, _⟩
    · apply (is_root_of_unity_iff n.pos (CyclotomicField n K)).mpr
      refine' ⟨n, Nat.mem_divisors_self _ n.ne_zero, _⟩
      rwa [← is_root_cyclotomic_iff] at hμ
      
    · rwa [← IsPrimitiveRoot.coe_submonoid_class_iff, Subtype.coe_mk]
      
  adjoin_roots := fun x => by
    refine' adjoin_induction' (fun y hy => _) (fun a => _) (fun y z hy hz => _) (fun y z hy hz => _) x
    · refine' subset_adjoin _
      simp only [← mem_singleton_iff, ← exists_eq_left, ← mem_set_of_eq]
      rwa [← Subalgebra.coe_eq_one, Subalgebra.coe_pow, Subtype.coe_mk]
      
    · exact Subalgebra.algebra_map_mem _ a
      
    · exact Subalgebra.add_mem _ hy hz
      
    · exact Subalgebra.mul_mem _ hy hz
      

instance [NeZero ((n : ℕ) : A)] : IsFractionRing (CyclotomicRing n A K) (CyclotomicField n K) where
  map_units := fun ⟨x, hx⟩ => by
    rw [is_unit_iff_ne_zero]
    apply map_ne_zero_of_mem_non_zero_divisors
    apply adjoin_algebra_injective
    exact hx
  surj := fun x => by
    letI : NeZero ((n : ℕ) : K) := NeZero.nat_of_injective (IsFractionRing.injective A K)
    refine'
      Algebra.adjoin_induction
        (((IsCyclotomicExtension.iff_singleton n K _).1 (CyclotomicField.is_cyclotomic_extension n K)).2 x)
        (fun y hy => _) (fun k => _) _ _
    · exact
        ⟨⟨⟨y, subset_adjoin hy⟩, 1⟩, by
          simpa⟩
      
    · have : IsLocalization (nonZeroDivisors A) K := inferInstance
      replace := this.surj
      obtain ⟨⟨z, w⟩, hw⟩ := this k
      refine' ⟨⟨algebraMap A _ z, algebraMap A _ w, map_mem_non_zero_divisors _ (algebra_base_injective n A K) w.2⟩, _⟩
      letI : IsScalarTower A K (CyclotomicField n K) := IsScalarTower.of_algebra_map_eq (congr_fun rfl)
      rw [SetLike.coe_mk, ← IsScalarTower.algebra_map_apply, ← IsScalarTower.algebra_map_apply,
        @IsScalarTower.algebra_map_apply A K _ _ _ _ _ (_root_.cyclotomic_field.algebra n K) _ _ w, ← RingHom.map_mul,
        hw, ← IsScalarTower.algebra_map_apply]
      
    · rintro y z ⟨a, ha⟩ ⟨b, hb⟩
      refine' ⟨⟨a.1 * b.2 + b.1 * a.2, a.2 * b.2, mul_mem_non_zero_divisors.2 ⟨a.2.2, b.2.2⟩⟩, _⟩
      rw [SetLike.coe_mk, RingHom.map_mul, add_mulₓ, ← mul_assoc, ha, mul_comm ((algebraMap _ _) ↑a.2), ← mul_assoc, hb]
      simp
      
    · rintro y z ⟨a, ha⟩ ⟨b, hb⟩
      refine' ⟨⟨a.1 * b.1, a.2 * b.2, mul_mem_non_zero_divisors.2 ⟨a.2.2, b.2.2⟩⟩, _⟩
      rw [SetLike.coe_mk, RingHom.map_mul, mul_comm ((algebraMap _ _) ↑a.2), mul_assoc, ← mul_assoc z, hb, ←
        mul_comm ((algebraMap _ _) ↑a.2), ← mul_assoc, ha]
      simp
      
  eq_iff_exists := fun x y =>
    ⟨fun h =>
      ⟨1, by
        rw [adjoin_algebra_injective n A K h]⟩,
      fun ⟨c, hc⟩ => by
      rw [mul_right_cancel₀ (nonZeroDivisors.ne_zero c.prop) hc]⟩

theorem eq_adjoin_primitive_root {μ : CyclotomicField n K} (h : IsPrimitiveRoot μ n) :
    CyclotomicRing n A K = adjoin A ({μ} : Set (CyclotomicField n K)) := by
  letI := Classical.propDecidable
  rw [← IsCyclotomicExtension.adjoin_roots_cyclotomic_eq_adjoin_root_cyclotomic h,
    IsCyclotomicExtension.adjoin_roots_cyclotomic_eq_adjoin_nth_roots h]
  simp [← CyclotomicRing]

end CyclotomicRing

end CyclotomicRing

end IsDomain

section IsAlgClosed

variable [IsAlgClosed K]

/-- Algebraically closed fields are `S`-cyclotomic extensions over themselves if
`ne_zero ((a : ℕ) : K))` for all `a ∈ S`. -/
theorem IsAlgClosed.is_cyclotomic_extension (h : ∀, ∀ a ∈ S, ∀, NeZero ((a : ℕ) : K)) : IsCyclotomicExtension S K K :=
  by
  refine' ⟨fun a ha => _, algebra.eq_top_iff.mp <| Subsingleton.elimₓ _ _⟩
  obtain ⟨r, hr⟩ := IsAlgClosed.exists_aeval_eq_zero K _ (degree_cyclotomic_pos a K a.pos).ne'
  refine' ⟨r, _⟩
  haveI := h a ha
  rwa [coe_aeval_eq_eval, ← is_root.def, is_root_cyclotomic_iff] at hr

instance IsAlgClosedOfCharZero.is_cyclotomic_extension [CharZero K] : ∀ S, IsCyclotomicExtension S K K := fun S =>
  IsAlgClosed.is_cyclotomic_extension S K fun a ha => inferInstance

end IsAlgClosed

