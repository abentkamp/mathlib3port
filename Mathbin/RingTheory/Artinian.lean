/-
Copyright (c) 2021 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import Mathbin.RingTheory.Nakayama
import Mathbin.Data.SetLike.Fintype

/-!
# Artinian rings and modules


A module satisfying these equivalent conditions is said to be an *Artinian* R-module
if every decreasing chain of submodules is eventually constant, or equivalently,
if the relation `<` on submodules is well founded.

A ring is said to be left (or right) Artinian if it is Artinian as a left (or right) module over
itself, or simply Artinian if it is both left and right Artinian.

## Main definitions

Let `R` be a ring and let `M` and `P` be `R`-modules. Let `N` be an `R`-submodule of `M`.

* `is_artinian R M` is the proposition that `M` is a Artinian `R`-module. It is a class,
  implemented as the predicate that the `<` relation on submodules is well founded.
* `is_artinian_ring R` is the proposition that `R` is a left Artinian ring.

## References

* [M. F. Atiyah and I. G. Macdonald, *Introduction to commutative algebra*][atiyah-macdonald]
* [samuel]

## Tags

Artinian, artinian, Artinian ring, Artinian module, artinian ring, artinian module

-/


open Set

open BigOperators Pointwise

-- ./././Mathport/Syntax/Translate/Command.lean:324:30: infer kinds are unsupported in Lean 4: #[`well_founded_submodule_lt] []
/-- `is_artinian R M` is the proposition that `M` is an Artinian `R`-module,
implemented as the well-foundedness of submodule inclusion.
-/
class IsArtinian (R M) [Semiringₓ R] [AddCommMonoidₓ M] [Module R M] : Prop where
  well_founded_submodule_lt : WellFounded ((· < ·) : Submodule R M → Submodule R M → Prop)

section

variable {R M P N : Type _}

variable [Ringₓ R] [AddCommGroupₓ M] [AddCommGroupₓ P] [AddCommGroupₓ N]

variable [Module R M] [Module R P] [Module R N]

open IsArtinian

include R

theorem is_artinian_of_injective (f : M →ₗ[R] P) (h : Function.Injective f) [IsArtinian R P] : IsArtinian R M :=
  ⟨Subrelation.wfₓ (fun A B hAB => show A.map f < B.map f from Submodule.map_strict_mono_of_injective h hAB)
      (InvImage.wfₓ (Submodule.map f) (IsArtinian.well_founded_submodule_lt R P))⟩

instance is_artinian_submodule' [IsArtinian R M] (N : Submodule R M) : IsArtinian R N :=
  is_artinian_of_injective N.Subtype Subtype.val_injective

theorem is_artinian_of_le {s t : Submodule R M} [ht : IsArtinian R t] (h : s ≤ t) : IsArtinian R s :=
  is_artinian_of_injective (Submodule.ofLe h) (Submodule.of_le_injective h)

variable (M)

theorem is_artinian_of_surjective (f : M →ₗ[R] P) (hf : Function.Surjective f) [IsArtinian R M] : IsArtinian R P :=
  ⟨Subrelation.wfₓ (fun A B hAB => show A.comap f < B.comap f from Submodule.comap_strict_mono_of_surjective hf hAB)
      (InvImage.wfₓ (Submodule.comap f) (IsArtinian.well_founded_submodule_lt _ _))⟩

variable {M}

theorem is_artinian_of_linear_equiv (f : M ≃ₗ[R] P) [IsArtinian R M] : IsArtinian R P :=
  is_artinian_of_surjective _ f.toLinearMap f.toEquiv.Surjective

theorem is_artinian_of_range_eq_ker [IsArtinian R M] [IsArtinian R P] (f : M →ₗ[R] N) (g : N →ₗ[R] P)
    (hf : Function.Injective f) (hg : Function.Surjective g) (h : f.range = g.ker) : IsArtinian R N :=
  ⟨well_founded_lt_exact_sequence (IsArtinian.well_founded_submodule_lt _ _) (IsArtinian.well_founded_submodule_lt _ _)
      f.range (Submodule.map f) (Submodule.comap f) (Submodule.comap g) (Submodule.map g) (Submodule.gciMapComap hf)
      (Submodule.giMapComap hg)
      (by
        simp [Submodule.map_comap_eq, inf_comm])
      (by
        simp [Submodule.comap_map_eq, h])⟩

instance is_artinian_prod [IsArtinian R M] [IsArtinian R P] : IsArtinian R (M × P) :=
  is_artinian_of_range_eq_ker (LinearMap.inl R M P) (LinearMap.snd R M P) LinearMap.inl_injective
    LinearMap.snd_surjective (LinearMap.range_inl R M P)

instance (priority := 100) is_artinian_of_finite [Finite M] : IsArtinian R M :=
  ⟨Finite.well_founded_of_trans_of_irrefl _⟩

attribute [local elabAsElim] Finite.induction_empty_option

instance is_artinian_pi {R ι : Type _} [Finite ι] :
    ∀ {M : ι → Type _} [Ringₓ R] [∀ i, AddCommGroupₓ (M i)],
      ∀ [∀ i, Module R (M i)], ∀ [∀ i, IsArtinian R (M i)], IsArtinian R (∀ i, M i) :=
  Finite.induction_empty_option
    (by
      intro α β e hα M _ _ _ _
      exact is_artinian_of_linear_equiv (LinearEquiv.piCongrLeft R M e))
    (by
      intro M _ _ _ _
      infer_instance)
    (by
      intro α _ ih M _ _ _ _
      exact is_artinian_of_linear_equiv (LinearEquiv.piOptionEquivProd R).symm)
    ι

/-- A version of `is_artinian_pi` for non-dependent functions. We need this instance because
sometimes Lean fails to apply the dependent version in non-dependent settings (e.g., it fails to
prove that `ι → ℝ` is finite dimensional over `ℝ`). -/
instance is_artinian_pi' {R ι M : Type _} [Ringₓ R] [AddCommGroupₓ M] [Module R M] [Finite ι] [IsArtinian R M] :
    IsArtinian R (ι → M) :=
  is_artinian_pi

end

open IsArtinian Submodule Function

section Ringₓ

variable {R M : Type _} [Ringₓ R] [AddCommGroupₓ M] [Module R M]

theorem is_artinian_iff_well_founded : IsArtinian R M ↔ WellFounded ((· < ·) : Submodule R M → Submodule R M → Prop) :=
  ⟨fun h => h.1, IsArtinian.mk⟩

variable {R M}

theorem IsArtinian.finite_of_linear_independent [Nontrivial R] [IsArtinian R M] {s : Set M}
    (hs : LinearIndependent R (coe : s → M)) : s.Finite := by
  refine'
    Classical.by_contradiction fun hf =>
      (RelEmbedding.well_founded_iff_no_descending_seq.1 (well_founded_submodule_lt R M)).elim' _
  have f : ℕ ↪ s := Set.Infinite.natEmbedding s hf
  have : ∀ n, coe ∘ f '' { m | n ≤ m } ⊆ s := by
    rintro n x ⟨y, hy₁, rfl⟩
    exact (f y).2
  have : ∀ a b : ℕ, a ≤ b ↔ span R (coe ∘ f '' { m | b ≤ m }) ≤ span R (coe ∘ f '' { m | a ≤ m }) := by
    intro a b
    rw [span_le_span_iff hs (this b) (this a), Set.image_subset_image_iff (subtype.coe_injective.comp f.injective),
      Set.subset_def]
    simp only [Set.mem_set_of_eq]
    exact ⟨fun hab x => le_transₓ hab, fun h => h _ le_rflₓ⟩
  exact
    ⟨⟨fun n => span R (coe ∘ f '' { m | n ≤ m }), fun x y => by
        simp (config := { contextual := true })[le_antisymm_iffₓ, (this _ _).symm]⟩,
      by
      intro a b
      conv_rhs => rw [Gt, lt_iff_le_not_leₓ, this, this, ← lt_iff_le_not_leₓ]
      simp ⟩

/-- A module is Artinian iff every nonempty set of submodules has a minimal submodule among them.
-/
theorem set_has_minimal_iff_artinian :
    (∀ a : Set <| Submodule R M, a.Nonempty → ∃ M' ∈ a, ∀ I ∈ a, I ≤ M' → I = M') ↔ IsArtinian R M := by
  rw [is_artinian_iff_well_founded, WellFounded.well_founded_iff_has_min']

theorem IsArtinian.set_has_minimal [IsArtinian R M] (a : Set <| Submodule R M) (ha : a.Nonempty) :
    ∃ M' ∈ a, ∀ I ∈ a, I ≤ M' → I = M' :=
  set_has_minimal_iff_artinian.mpr ‹_› a ha

/-- A module is Artinian iff every decreasing chain of submodules stabilizes. -/
theorem monotone_stabilizes_iff_artinian :
    (∀ f : ℕ →o (Submodule R M)ᵒᵈ, ∃ n, ∀ m, n ≤ m → f n = f m) ↔ IsArtinian R M := by
  rw [is_artinian_iff_well_founded]
  exact well_founded.monotone_chain_condition.symm

namespace IsArtinian

variable [IsArtinian R M]

theorem monotone_stabilizes (f : ℕ →o (Submodule R M)ᵒᵈ) : ∃ n, ∀ m, n ≤ m → f n = f m :=
  monotone_stabilizes_iff_artinian.mpr ‹_› f

/-- If `∀ I > J, P I` implies `P J`, then `P` holds for all submodules. -/
theorem induction {P : Submodule R M → Prop} (hgt : ∀ I, (∀ J < I, P J) → P I) (I : Submodule R M) : P I :=
  (well_founded_submodule_lt R M).recursion I hgt

/-- For any endomorphism of a Artinian module, there is some nontrivial iterate
with disjoint kernel and range.
-/
theorem exists_endomorphism_iterate_ker_sup_range_eq_top (f : M →ₗ[R] M) :
    ∃ n : ℕ, n ≠ 0 ∧ (f ^ n).ker⊔(f ^ n).range = ⊤ := by
  obtain ⟨n, w⟩ :=
    monotone_stabilizes
      (f.iterate_range.comp
        ⟨fun n => n + 1, fun n m w => by
          linarith⟩)
  specialize
    w (n + 1 + n)
      (by
        linarith)
  dsimp'  at w
  refine' ⟨n + 1, Nat.succ_ne_zero _, _⟩
  simp_rw [eq_top_iff', mem_sup]
  intro x
  have : (f ^ (n + 1)) x ∈ (f ^ (n + 1 + n + 1)).range := by
    rw [← w]
    exact mem_range_self _
  rcases this with ⟨y, hy⟩
  use x - (f ^ (n + 1)) y
  constructor
  · rw [LinearMap.mem_ker, LinearMap.map_sub, ← hy, sub_eq_zero, pow_addₓ]
    simp [iterate_add_apply]
    
  · use (f ^ (n + 1)) y
    simp
    

/-- Any injective endomorphism of an Artinian module is surjective. -/
theorem surjective_of_injective_endomorphism (f : M →ₗ[R] M) (s : Injective f) : Surjective f := by
  obtain ⟨n, ne, w⟩ := exists_endomorphism_iterate_ker_sup_range_eq_top f
  rw [linear_map.ker_eq_bot.mpr (LinearMap.iterate_injective s n), bot_sup_eq, LinearMap.range_eq_top] at w
  exact LinearMap.surjective_of_iterate_surjective Ne w

/-- Any injective endomorphism of an Artinian module is bijective. -/
theorem bijective_of_injective_endomorphism (f : M →ₗ[R] M) (s : Injective f) : Bijective f :=
  ⟨s, surjective_of_injective_endomorphism f s⟩

-- ./././Mathport/Syntax/Translate/Tactic/Builtin.lean:64:14: unsupported tactic `rsuffices #[["⟨", ident n, ",", ident w, "⟩", ":", expr «expr∃ , »((n : exprℕ()),
    ∀ m,
    «expr ≤ »(n, m) → «expr = »(order_dual.to_dual f «expr + »(m, 1), «expr⊤»()))]]
/-- A sequence `f` of submodules of a artinian module,
with the supremum `f (n+1)` and the infinum of `f 0`, ..., `f n` being ⊤,
is eventually ⊤.
-/
theorem disjoint_partial_infs_eventually_top (f : ℕ → Submodule R M)
    (h : ∀ n, Disjoint (partialSups (OrderDual.toDual ∘ f) n) (OrderDual.toDual (f (n + 1)))) :
    ∃ n : ℕ, ∀ m, n ≤ m → f m = ⊤ := by
  trace
    "./././Mathport/Syntax/Translate/Tactic/Builtin.lean:64:14: unsupported tactic `rsuffices #[[\"⟨\", ident n, \",\", ident w, \"⟩\", \":\", expr «expr∃ , »((n : exprℕ()),\n    ∀ m,\n    «expr ≤ »(n, m) → «expr = »(order_dual.to_dual f «expr + »(m, 1), «expr⊤»()))]]"
  · use n + 1
    rintro (_ | m) p
    · cases p
      
    · apply w
      exact nat.succ_le_succ_iff.mp p
      
    
  obtain ⟨n, w⟩ := monotone_stabilizes (partialSups (OrderDual.toDual ∘ f))
  refine' ⟨n, fun m p => _⟩
  exact (h m).eq_bot_of_ge (sup_eq_left.1 <| (w (m + 1) <| le_add_right p).symm.trans <| w m p)

end IsArtinian

end Ringₓ

section CommRingₓ

variable {R : Type _} (M : Type _) [CommRingₓ R] [AddCommGroupₓ M] [Module R M] [IsArtinian R M]

namespace IsArtinian

theorem range_smul_pow_stabilizes (r : R) :
    ∃ n : ℕ, ∀ m, n ≤ m → (r ^ n • LinearMap.id : M →ₗ[R] M).range = (r ^ m • LinearMap.id : M →ₗ[R] M).range :=
  monotone_stabilizes
    ⟨fun n => (r ^ n • LinearMap.id : M →ₗ[R] M).range, fun n m h x ⟨y, hy⟩ =>
      ⟨r ^ (m - n) • y, by
        dsimp'  at hy⊢
        rw [← smul_assoc, smul_eq_mul, ← pow_addₓ, ← hy, add_tsub_cancel_of_le h]⟩⟩

variable {M}

theorem exists_pow_succ_smul_dvd (r : R) (x : M) : ∃ (n : ℕ)(y : M), r ^ n.succ • y = r ^ n • x := by
  obtain ⟨n, hn⟩ := IsArtinian.range_smul_pow_stabilizes M r
  simp_rw [SetLike.ext_iff] at hn
  exact
    ⟨n, by
      simpa using hn n.succ n.le_succ (r ^ n • x)⟩

end IsArtinian

end CommRingₓ

-- TODO: Prove this for artinian modules
-- /--
-- If `M ⊕ N` embeds into `M`, for `M` noetherian over `R`, then `N` is trivial.
-- -/
-- universe w
-- variables {N : Type w} [add_comm_group N] [module R N]
-- noncomputable def is_noetherian.equiv_punit_of_prod_injective [is_noetherian R M]
--   (f : M × N →ₗ[R] M) (i : injective f) : N ≃ₗ[R] punit.{w+1} :=
-- begin
--   apply nonempty.some,
--   obtain ⟨n, w⟩ := is_noetherian.disjoint_partial_sups_eventually_bot (f.tailing i)
--     (f.tailings_disjoint_tailing i),
--   specialize w n (le_refl n),
--   apply nonempty.intro,
--   refine (f.tailing_linear_equiv i n).symm.trans _,
--   rw w,
--   exact submodule.bot_equiv_punit,
-- end
/-- A ring is Artinian if it is Artinian as a module over itself.

Strictly speaking, this should be called `is_left_artinian_ring` but we omit the `left_` for
convenience in the commutative case. For a right Artinian ring, use `is_artinian Rᵐᵒᵖ R`. -/
@[reducible]
def IsArtinianRing (R) [Ringₓ R] :=
  IsArtinian R R

theorem is_artinian_ring_iff {R} [Ringₓ R] : IsArtinianRing R ↔ IsArtinian R R :=
  Iff.rfl

theorem Ringₓ.is_artinian_of_zero_eq_one {R} [Ringₓ R] (h01 : (0 : R) = 1) : IsArtinianRing R :=
  have := subsingleton_of_zero_eq_one h01
  inferInstance

theorem is_artinian_of_submodule_of_artinian (R M) [Ringₓ R] [AddCommGroupₓ M] [Module R M] (N : Submodule R M)
    (h : IsArtinian R M) : IsArtinian R N := by
  infer_instance

theorem is_artinian_of_quotient_of_artinian (R) [Ringₓ R] (M) [AddCommGroupₓ M] [Module R M] (N : Submodule R M)
    (h : IsArtinian R M) : IsArtinian R (M ⧸ N) :=
  is_artinian_of_surjective M (Submodule.mkq N) (Submodule.Quotient.mk_surjective N)

/-- If `M / S / R` is a scalar tower, and `M / R` is Artinian, then `M / S` is
also Artinian. -/
theorem is_artinian_of_tower (R) {S M} [CommRingₓ R] [Ringₓ S] [AddCommGroupₓ M] [Algebra R S] [Module S M] [Module R M]
    [IsScalarTower R S M] (h : IsArtinian R M) : IsArtinian S M := by
  rw [is_artinian_iff_well_founded] at h⊢
  refine' (Submodule.restrictScalarsEmbedding R S M).WellFounded h

theorem is_artinian_of_fg_of_artinian {R M} [Ringₓ R] [AddCommGroupₓ M] [Module R M] (N : Submodule R M)
    [IsArtinianRing R] (hN : N.Fg) : IsArtinian R N := by
  let ⟨s, hs⟩ := hN
  haveI := Classical.decEq M
  haveI := Classical.decEq R
  have : ∀ x ∈ s, x ∈ N := fun x hx => hs ▸ Submodule.subset_span hx
  refine' @is_artinian_of_surjective ((↑s : Set M) → R) _ _ _ (Pi.module _ _ _) _ _ _ is_artinian_pi
  · fapply LinearMap.mk
    · exact fun f => ⟨∑ i in s.attach, f i • i.1, N.sum_mem fun c _ => N.smul_mem _ <| this _ c.2⟩
      
    · intro f g
      apply Subtype.eq
      change (∑ i in s.attach, (f i + g i) • _) = _
      simp only [add_smul, Finset.sum_add_distrib]
      rfl
      
    · intro c f
      apply Subtype.eq
      change (∑ i in s.attach, (c • f i) • _) = _
      simp only [smul_eq_mul, mul_smul]
      exact finset.smul_sum.symm
      
    
  rintro ⟨n, hn⟩
  change n ∈ N at hn
  rw [← hs, ← Set.image_id ↑s, Finsupp.mem_span_image_iff_total] at hn
  rcases hn with ⟨l, hl1, hl2⟩
  refine' ⟨fun x => l x, Subtype.ext _⟩
  change (∑ i in s.attach, l i • (i : M)) = n
  rw [@Finset.sum_attach M M s _ fun i => l i • i, ← hl2, Finsupp.total_apply, Finsupp.sum, eq_comm]
  refine' Finset.sum_subset hl1 fun x _ hx => _
  rw [Finsupp.not_mem_support_iff.1 hx, zero_smul]

theorem is_artinian_of_fg_of_artinian' {R M} [Ringₓ R] [AddCommGroupₓ M] [Module R M] [IsArtinianRing R]
    (h : (⊤ : Submodule R M).Fg) : IsArtinian R M :=
  have : IsArtinian R (⊤ : Submodule R M) := is_artinian_of_fg_of_artinian _ h
  is_artinian_of_linear_equiv (LinearEquiv.ofTop (⊤ : Submodule R M) rfl)

/-- In a module over a artinian ring, the submodule generated by finitely many vectors is
artinian. -/
theorem is_artinian_span_of_finite (R) {M} [Ringₓ R] [AddCommGroupₓ M] [Module R M] [IsArtinianRing R] {A : Set M}
    (hA : A.Finite) : IsArtinian R (Submodule.span R A) :=
  is_artinian_of_fg_of_artinian _ (Submodule.fg_def.mpr ⟨A, hA, rfl⟩)

theorem Function.Surjective.is_artinian_ring {R} [Ringₓ R] {S} [Ringₓ S] {F} [RingHomClass F R S] {f : F}
    (hf : Function.Surjective f) [H : IsArtinianRing R] : IsArtinianRing S := by
  rw [is_artinian_ring_iff, is_artinian_iff_well_founded] at H⊢
  exact (Ideal.orderEmbeddingOfSurjective f hf).WellFounded H

instance is_artinian_ring_range {R} [Ringₓ R] {S} [Ringₓ S] (f : R →+* S) [IsArtinianRing R] : IsArtinianRing f.range :=
  f.range_restrict_surjective.IsArtinianRing

namespace IsArtinianRing

open IsArtinian

variable {R : Type _} [CommRingₓ R] [IsArtinianRing R]

theorem is_nilpotent_jacobson_bot : IsNilpotent (Ideal.jacobson (⊥ : Ideal R)) := by
  let Jac := Ideal.jacobson (⊥ : Ideal R)
  let f : ℕ →o (Ideal R)ᵒᵈ := ⟨fun n => Jac ^ n, fun _ _ h => Ideal.pow_le_pow h⟩
  obtain ⟨n, hn⟩ : ∃ n, ∀ m, n ≤ m → Jac ^ n = Jac ^ m := IsArtinian.monotone_stabilizes f
  refine' ⟨n, _⟩
  let J : Ideal R := annihilator (Jac ^ n)
  suffices J = ⊤ by
    have hJ : J • Jac ^ n = ⊥ := annihilator_smul (Jac ^ n)
    simpa only [this, top_smul, Ideal.zero_eq_bot] using hJ
  by_contra hJ
  change J ≠ ⊤ at hJ
  rcases IsArtinian.set_has_minimal { J' : Ideal R | J < J' } ⟨⊤, hJ.lt_top⟩ with
    ⟨J', hJJ' : J < J', hJ' : ∀ I, J < I → I ≤ J' → I = J'⟩
  rcases SetLike.exists_of_lt hJJ' with ⟨x, hxJ', hxJ⟩
  obtain rfl : J⊔Ideal.span {x} = J' := by
    refine' hJ' (J⊔Ideal.span {x}) _ _
    · rw [SetLike.lt_iff_le_and_exists]
      exact ⟨le_sup_left, ⟨x, mem_sup_right (mem_span_singleton_self x), hxJ⟩⟩
      
    · exact sup_le hJJ'.le (span_le.2 (singleton_subset_iff.2 hxJ'))
      
  have : J⊔Jac • Ideal.span {x} ≤ J⊔Ideal.span {x} := sup_le_sup_left (smul_le.2 fun _ _ _ => Submodule.smul_mem _ _) _
  have : Jac * Ideal.span {x} ≤ J := by
    --Need version 4 of Nakayamas lemma on Stacks
    classical
    by_contra H
    refine' H (smul_sup_le_of_le_smul_of_le_jacobson_bot (fg_span_singleton _) le_rflₓ (hJ' _ _ this).Ge)
    exact lt_of_le_of_neₓ le_sup_left fun h => H <| h.symm ▸ le_sup_right
  have : Ideal.span {x} * Jac ^ (n + 1) ≤ ⊥
  calc
    Ideal.span {x} * Jac ^ (n + 1) = Ideal.span {x} * Jac * Jac ^ n := by
      rw [pow_succₓ, ← mul_assoc]
    _ ≤ J * Jac ^ n :=
      mul_le_mul
        (by
          rwa [mul_comm])
        le_rflₓ
    _ = ⊥ := by
      simp [J]
    
  refine' hxJ (mem_annihilator.2 fun y hy => (mem_bot R).1 _)
  refine' this (mul_mem_mul (mem_span_singleton_self x) _)
  rwa [← hn (n + 1) (Nat.le_succₓ _)]

section Localization

variable (S : Submonoid R) (L : Type _) [CommRingₓ L] [Algebra R L] [IsLocalization S L]

include S

/-- Localizing an artinian ring can only reduce the amount of elements. -/
theorem localization_surjective : Function.Surjective (algebraMap R L) := by
  intro r'
  obtain ⟨r₁, s, rfl⟩ := IsLocalization.mk'_surjective S r'
  obtain ⟨r₂, h⟩ : ∃ r : R, IsLocalization.mk' L 1 s = algebraMap R L r
  swap
  · exact
      ⟨r₁ * r₂, by
        rw [IsLocalization.mk'_eq_mul_mk'_one, map_mul, h]⟩
    
  obtain ⟨n, r, hr⟩ := IsArtinian.exists_pow_succ_smul_dvd (s : R) (1 : R)
  use r
  rw [smul_eq_mul, smul_eq_mul, pow_succ'ₓ, mul_assoc] at hr
  apply_fun algebraMap R L  at hr
  simp only [map_mul, ← Submonoid.coe_pow] at hr
  rw [← IsLocalization.mk'_one L, IsLocalization.mk'_eq_iff_eq, one_mulₓ, Submonoid.coe_one, ←
    (IsLocalization.map_units L (s ^ n)).mul_left_cancel hr, map_mul, mul_comm]

theorem localization_artinian : IsArtinianRing L :=
  (localization_surjective S L).IsArtinianRing

/-- `is_artinian_ring.localization_artinian` can't be made an instance, as it would make `S` + `R`
into metavariables. However, this is safe. -/
instance : IsArtinianRing (Localization S) :=
  localization_artinian S _

end Localization

end IsArtinianRing

