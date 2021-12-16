import Mathbin.RingTheory.Adjoin.Fg 
import Mathbin.RingTheory.Polynomial.ScaleRoots 
import Mathbin.RingTheory.Polynomial.Tower

/-!
# Integral closure of a subring.

If A is an R-algebra then `a : A` is integral over R if it is a root of a monic polynomial
with coefficients in R. Enough theory is developed to prove that integral elements
form a sub-R-algebra of A.

## Main definitions

Let `R` be a `comm_ring` and let `A` be an R-algebra.

* `ring_hom.is_integral_elem (f : R →+* A) (x : A)` : `x` is integral with respect to the map `f`,

* `is_integral (x : A)`  : `x` is integral over `R`, i.e., is a root of a monic polynomial with
                           coefficients in `R`.
* `integral_closure R A` : the integral closure of `R` in `A`, regarded as a sub-`R`-algebra of `A`.
-/


open_locale Classical

open_locale BigOperators

open Polynomial Submodule

section Ringₓ

variable {R S A : Type _}

variable [CommRingₓ R] [Ringₓ A] [Ringₓ S] (f : R →+* S)

/-- An element `x` of `A` is said to be integral over `R` with respect to `f`
if it is a root of a monic polynomial `p : polynomial R` evaluated under `f` -/
def RingHom.IsIntegralElem (f : R →+* A) (x : A) :=
  ∃ p : Polynomial R, monic p ∧ eval₂ f x p = 0

/-- A ring homomorphism `f : R →+* A` is said to be integral
if every element `A` is integral with respect to the map `f` -/
def RingHom.IsIntegral (f : R →+* A) :=
  ∀ x : A, f.is_integral_elem x

variable [Algebra R A] (R)

/-- An element `x` of an algebra `A` over a commutative ring `R` is said to be *integral*,
if it is a root of some monic polynomial `p : polynomial R`.
Equivalently, the element is integral over `R` with respect to the induced `algebra_map` -/
def IsIntegral (x : A) : Prop :=
  (algebraMap R A).IsIntegralElem x

variable (A)

/-- An algebra is integral if every element of the extension is integral over the base ring -/
def Algebra.IsIntegral : Prop :=
  (algebraMap R A).IsIntegral

variable {R A}

theorem RingHom.is_integral_map {x : R} : f.is_integral_elem (f x) :=
  ⟨X - C x, monic_X_sub_C _,
    by 
      simp ⟩

theorem is_integral_algebra_map {x : R} : IsIntegral R (algebraMap R A x) :=
  (algebraMap R A).is_integral_map

theorem is_integral_of_noetherian (H : IsNoetherian R A) (x : A) : IsIntegral R x :=
  by 
    let leval : Polynomial R →ₗ[R] A := (aeval x).toLinearMap 
    let D : ℕ → Submodule R A := fun n => (degree_le R n).map leval 
    let M := WellFounded.min (is_noetherian_iff_well_founded.1 H) (Set.Range D) ⟨_, ⟨0, rfl⟩⟩
    have HM : M ∈ Set.Range D := WellFounded.min_mem _ _ _ 
    cases' HM with N HN 
    have HM : ¬M < D (N+1) := WellFounded.not_lt_min (is_noetherian_iff_well_founded.1 H) (Set.Range D) _ ⟨N+1, rfl⟩
    rw [←HN] at HM 
    have HN2 : D (N+1) ≤ D N :=
      Classical.by_contradiction
        fun H => HM (lt_of_le_not_leₓ (map_mono (degree_le_mono (WithBot.coe_le_coe.2 (Nat.le_succₓ N)))) H)
    have HN3 : leval (X^N+1) ∈ D N
    ·
      exact HN2 (mem_map_of_mem (mem_degree_le.2 (degree_X_pow_le _)))
    rcases HN3 with ⟨p, hdp, hpe⟩
    refine' ⟨(X^N+1) - p, monic_X_pow_sub (mem_degree_le.1 hdp), _⟩
    show leval ((X^N+1) - p) = 0
    rw [LinearMap.map_sub, hpe, sub_self]

theorem is_integral_of_submodule_noetherian (S : Subalgebra R A) (H : IsNoetherian R S.to_submodule) (x : A)
  (hx : x ∈ S) : IsIntegral R x :=
  by 
    suffices  : IsIntegral R (show S from ⟨x, hx⟩)
    ·
      rcases this with ⟨p, hpm, hpx⟩
      replace hpx := congr_argₓ S.val hpx 
      refine' ⟨p, hpm, Eq.trans _ hpx⟩
      simp only [aeval_def, eval₂, sum_def]
      rw [S.val.map_sum]
      refine' Finset.sum_congr rfl fun n hn => _ 
      rw [S.val.map_mul, S.val.map_pow, S.val.commutes, S.val_apply, Subtype.coe_mk]
    refine' is_integral_of_noetherian H ⟨x, hx⟩

end Ringₓ

section 

variable {R A B S : Type _}

variable [CommRingₓ R] [CommRingₓ A] [CommRingₓ B] [CommRingₓ S]

variable [Algebra R A] [Algebra R B] (f : R →+* S)

theorem is_integral_alg_hom (f : A →ₐ[R] B) {x : A} (hx : IsIntegral R x) : IsIntegral R (f x) :=
  let ⟨p, hp, hpx⟩ := hx
  ⟨p, hp,
    by 
      rw [←aeval_def, aeval_alg_hom_apply, aeval_def, hpx, f.map_zero]⟩

@[simp]
theorem is_integral_alg_equiv (f : A ≃ₐ[R] B) {x : A} : IsIntegral R (f x) ↔ IsIntegral R x :=
  ⟨fun h =>
      by 
        simpa using is_integral_alg_hom f.symm.to_alg_hom h,
    is_integral_alg_hom f.to_alg_hom⟩

theorem is_integral_of_is_scalar_tower [Algebra A B] [IsScalarTower R A B] (x : B) (hx : IsIntegral R x) :
  IsIntegral A x :=
  let ⟨p, hp, hpx⟩ := hx
  ⟨p.map$ algebraMap R A, monic_map _ hp,
    by 
      rw [←aeval_def, ←IsScalarTower.aeval_apply, aeval_def, hpx]⟩

theorem is_integral_of_subring {x : A} (T : Subring R) (hx : IsIntegral T x) : IsIntegral R x :=
  is_integral_of_is_scalar_tower x hx

theorem IsIntegral.algebra_map [Algebra A B] [IsScalarTower R A B] {x : A} (h : IsIntegral R x) :
  IsIntegral R (algebraMap A B x) :=
  by 
    rcases h with ⟨f, hf, hx⟩
    use f, hf 
    rw [IsScalarTower.algebra_map_eq R A B, ←hom_eval₂, hx, RingHom.map_zero]

theorem is_integral_algebra_map_iff [Algebra A B] [IsScalarTower R A B] {x : A}
  (hAB : Function.Injective (algebraMap A B)) : IsIntegral R (algebraMap A B x) ↔ IsIntegral R x :=
  by 
    refine' ⟨_, fun h => h.algebra_map⟩
    rintro ⟨f, hf, hx⟩
    use f, hf 
    exact IsScalarTower.aeval_eq_zero_of_aeval_algebra_map_eq_zero R A B hAB hx

theorem is_integral_iff_is_integral_closure_finite {r : A} :
  IsIntegral R r ↔ ∃ s : Set R, s.finite ∧ IsIntegral (Subring.closure s) r :=
  by 
    constructor <;> intro hr
    ·
      rcases hr with ⟨p, hmp, hpr⟩
      refine' ⟨_, Set.finite_mem_finset _, p.restriction, monic_restriction.2 hmp, _⟩
      erw [←aeval_def, IsScalarTower.aeval_apply _ R, map_restriction, aeval_def, hpr]
    rcases hr with ⟨s, hs, hsr⟩
    exact is_integral_of_subring _ hsr

theorem fg_adjoin_singleton_of_integral (x : A) (hx : IsIntegral R x) :
  (Algebra.adjoin R ({x} : Set A)).toSubmodule.Fg :=
  by 
    rcases hx with ⟨f, hfm, hfx⟩
    exists Finset.image ((·^·) x) (Finset.range (nat_degree f+1))
    apply le_antisymmₓ
    ·
      rw [span_le]
      intro s hs 
      rw [Finset.mem_coe] at hs 
      rcases Finset.mem_image.1 hs with ⟨k, hk, rfl⟩
      clear hk 
      exact (Algebra.adjoin R {x}).pow_mem (Algebra.subset_adjoin (Set.mem_singleton _)) k 
    intro r hr 
    change r ∈ Algebra.adjoin R ({x} : Set A) at hr 
    rw [Algebra.adjoin_singleton_eq_range_aeval] at hr 
    rcases(aeval x).mem_range.mp hr with ⟨p, rfl⟩
    rw [←mod_by_monic_add_div p hfm]
    rw [←aeval_def] at hfx 
    rw [AlgHom.map_add, AlgHom.map_mul, hfx, zero_mul, add_zeroₓ]
    have  : degree (p %ₘ f) ≤ degree f := degree_mod_by_monic_le p hfm 
    generalize p %ₘ f = q  at this⊢
    rw [←sum_C_mul_X_eq q, aeval_def, eval₂_sum, sum_def]
    refine' sum_mem _ fun k hkq => _ 
    rw [eval₂_mul, eval₂_C, eval₂_pow, eval₂_X, ←Algebra.smul_def]
    refine' smul_mem _ _ (subset_span _)
    rw [Finset.mem_coe]
    refine' Finset.mem_image.2 ⟨_, _, rfl⟩
    rw [Finset.mem_range, Nat.lt_succ_iff]
    refine' le_of_not_ltₓ fun hk => _ 
    rw [degree_le_iff_coeff_zero] at this 
    rw [mem_support_iff] at hkq 
    apply hkq 
    apply this 
    exact lt_of_le_of_ltₓ degree_le_nat_degree (WithBot.coe_lt_coe.2 hk)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem fg_adjoin_of_finite {s : Set A} (hfs : s.finite) (his : ∀ x _ : x ∈ s, IsIntegral R x) :
  (Algebra.adjoin R s).toSubmodule.Fg :=
  Set.Finite.induction_on hfs
    (fun _ =>
      ⟨{1},
        Submodule.ext$
          fun x =>
            by 
              erw [Algebra.adjoin_empty, Finset.coe_singleton, ←one_eq_span, one_eq_range, LinearMap.mem_range,
                Algebra.mem_bot]
              rfl⟩)
    (fun a s has hs ih his =>
      by 
        rw [←Set.union_singleton, Algebra.adjoin_union_coe_submodule] <;>
          exact
            fg_mul _ _ (ih$ fun i hi => his i$ Set.mem_insert_of_mem a hi)
              (fg_adjoin_singleton_of_integral _$ his a$ Set.mem_insert a s))
    his

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem is_noetherian_adjoin_finset [IsNoetherianRing R] (s : Finset A) (hs : ∀ x _ : x ∈ s, IsIntegral R x) :
  IsNoetherian R (Algebra.adjoin R (↑s : Set A)) :=
  is_noetherian_of_fg_of_noetherian _ (fg_adjoin_of_finite s.finite_to_set hs)

/-- If `S` is a sub-`R`-algebra of `A` and `S` is finitely-generated as an `R`-module,
  then all elements of `S` are integral over `R`. -/
theorem is_integral_of_mem_of_fg (S : Subalgebra R A) (HS : S.to_submodule.fg) (x : A) (hx : x ∈ S) : IsIntegral R x :=
  by 
    cases' HS with y hy 
    obtain ⟨lx, hlx1, hlx2⟩ : ∃ (l : A →₀ R)(H : l ∈ Finsupp.supported R R (↑y)), (Finsupp.total A A R id) l = x
    ·
      rwa [←@Finsupp.mem_span_image_iff_total A A R _ _ _ id (↑y) x, Set.image_id (↑y), hy]
    have hyS : ∀ {p}, p ∈ y → p ∈ S :=
      fun p hp =>
        show p ∈ S.to_submodule by 
          rw [←hy]
          exact subset_span hp 
    have  : ∀ jk : (↑y.product y : Set (A × A)), (jk.1.1*jk.1.2) ∈ S.to_submodule :=
      fun jk => S.mul_mem (hyS (Finset.mem_product.1 jk.2).1) (hyS (Finset.mem_product.1 jk.2).2)
    rw [←hy, ←Set.image_id (↑y)] at this 
    simp only [Finsupp.mem_span_image_iff_total] at this 
    choose ly hly1 hly2 
    let S₀ : Subring R := Subring.closure (↑(lx.frange ∪ Finset.bUnion Finset.univ (Finsupp.frange ∘ ly)))
    refine' is_integral_of_subring S₀ _ 
    let this' : CommRingₓ S₀ := Subring.toCommRing S₀ 
    let this' : Algebra S₀ A := Algebra.ofSubring S₀ 
    have  : (span S₀ (insert 1 (↑y) : Set A)*span S₀ (insert 1 (↑y) : Set A)) ≤ span S₀ (insert 1 (↑y) : Set A)
    ·
      rw [span_mul_span]
      refine' span_le.2 fun z hz => _ 
      rcases Set.mem_mul.1 hz with ⟨p, q, rfl | hp, hq, rfl⟩
      ·
        rw [one_mulₓ]
        exact subset_span hq 
      rcases hq with (rfl | hq)
      ·
        rw [mul_oneₓ]
        exact subset_span (Or.inr hp)
      erw [←hly2 ⟨(p, q), Finset.mem_product.2 ⟨hp, hq⟩⟩]
      rw [Finsupp.total_apply, Finsupp.sum]
      refine' (span S₀ (insert 1 (↑y) : Set A)).sum_mem fun t ht => _ 
      have  : ly ⟨(p, q), Finset.mem_product.2 ⟨hp, hq⟩⟩ t ∈ S₀ :=
        Subring.subset_closure
          (Finset.mem_union_right _$
            Finset.mem_bUnion.2
              ⟨⟨(p, q), Finset.mem_product.2 ⟨hp, hq⟩⟩, Finset.mem_univ _,
                Finsupp.mem_frange.2 ⟨Finsupp.mem_support_iff.1 ht, _, rfl⟩⟩)
      change (⟨_, this⟩ : S₀) • t ∈ _ 
      exact smul_mem _ _ (subset_span$ Or.inr$ hly1 _ ht)
    let S₁ : Subring A :=
      { Carrier := span S₀ (insert 1 (↑y) : Set A), one_mem' := subset_span$ Or.inl rfl,
        mul_mem' := fun p q hp hq => this$ mul_mem_mul hp hq, zero_mem' := (span S₀ (insert 1 (↑y) : Set A)).zero_mem,
        add_mem' := fun _ _ => (span S₀ (insert 1 (↑y) : Set A)).add_mem,
        neg_mem' := fun _ => (span S₀ (insert 1 (↑y) : Set A)).neg_mem }
    have  : S₁ = (Algebra.adjoin S₀ (↑y : Set A)).toSubring
    ·
      ext z 
      suffices  : z ∈ span (↥S₀) (insert 1 (↑y) : Set A) ↔ z ∈ (Algebra.adjoin (↥S₀) (y : Set A)).toSubmodule
      ·
        simpa 
      constructor <;> intro hz
      ·
        exact (span_le.2 (Set.insert_subset.2 ⟨(Algebra.adjoin S₀ (↑y)).one_mem, Algebra.subset_adjoin⟩)) hz
      ·
        rw [Subalgebra.mem_to_submodule, Algebra.mem_adjoin_iff] at hz 
        suffices  : Subring.closure (Set.Range (⇑algebraMap (↥S₀) A) ∪ ↑y) ≤ S₁
        ·
          exact this hz 
        refine' Subring.closure_le.2 (Set.union_subset _ fun t ht => subset_span$ Or.inr ht)
        rw [Set.range_subset_iff]
        intro y 
        rw [Algebra.algebra_map_eq_smul_one]
        exact smul_mem _ y (subset_span (Or.inl rfl))
    have foo : ∀ z, z ∈ S₁ ↔ z ∈ Algebra.adjoin (↥S₀) (y : Set A)
    simp [this]
    have  : IsNoetherianRing (↥S₀) := is_noetherian_subring_closure _ (Finset.finite_to_set _)
    refine'
      is_integral_of_submodule_noetherian (Algebra.adjoin S₀ (↑y))
        (is_noetherian_of_fg_of_noetherian _
          ⟨insert 1 y,
            by 
              rw [Finset.coe_insert]
              ext z 
              simp [S₁]
              convert foo z⟩)
        _ _ 
    rw [←hlx2, Finsupp.total_apply, Finsupp.sum]
    refine' Subalgebra.sum_mem _ fun r hr => _ 
    have  : lx r ∈ S₀ := Subring.subset_closure (Finset.mem_union_left _ (Finset.mem_image_of_mem _ hr))
    change (⟨_, this⟩ : S₀) • r ∈ _ 
    rw [Finsupp.mem_supported] at hlx1 
    exact Subalgebra.smul_mem _ (Algebra.subset_adjoin$ hlx1 hr) _

theorem RingHom.is_integral_of_mem_closure {x y z : S} (hx : f.is_integral_elem x) (hy : f.is_integral_elem y)
  (hz : z ∈ Subring.closure ({x, y} : Set S)) : f.is_integral_elem z :=
  by 
    let this' : Algebra R S := f.to_algebra 
    have  := fg_mul _ _ (fg_adjoin_singleton_of_integral x hx) (fg_adjoin_singleton_of_integral y hy)
    rw [←Algebra.adjoin_union_coe_submodule, Set.singleton_union] at this 
    exact
      is_integral_of_mem_of_fg (Algebra.adjoin R {x, y}) this z
        (Algebra.mem_adjoin_iff.2$ Subring.closure_mono (Set.subset_union_right _ _) hz)

theorem is_integral_of_mem_closure {x y z : A} (hx : IsIntegral R x) (hy : IsIntegral R y)
  (hz : z ∈ Subring.closure ({x, y} : Set A)) : IsIntegral R z :=
  (algebraMap R A).is_integral_of_mem_closure hx hy hz

theorem RingHom.is_integral_zero : f.is_integral_elem 0 :=
  f.map_zero ▸ f.is_integral_map

theorem is_integral_zero : IsIntegral R (0 : A) :=
  (algebraMap R A).is_integral_zero

theorem RingHom.is_integral_one : f.is_integral_elem 1 :=
  f.map_one ▸ f.is_integral_map

theorem is_integral_one : IsIntegral R (1 : A) :=
  (algebraMap R A).is_integral_one

theorem RingHom.is_integral_add {x y : S} (hx : f.is_integral_elem x) (hy : f.is_integral_elem y) :
  f.is_integral_elem (x+y) :=
  f.is_integral_of_mem_closure hx hy$
    Subring.add_mem _ (Subring.subset_closure (Or.inl rfl)) (Subring.subset_closure (Or.inr rfl))

theorem is_integral_add {x y : A} (hx : IsIntegral R x) (hy : IsIntegral R y) : IsIntegral R (x+y) :=
  (algebraMap R A).is_integral_add hx hy

theorem RingHom.is_integral_neg {x : S} (hx : f.is_integral_elem x) : f.is_integral_elem (-x) :=
  f.is_integral_of_mem_closure hx hx (Subring.neg_mem _ (Subring.subset_closure (Or.inl rfl)))

theorem is_integral_neg {x : A} (hx : IsIntegral R x) : IsIntegral R (-x) :=
  (algebraMap R A).is_integral_neg hx

theorem RingHom.is_integral_sub {x y : S} (hx : f.is_integral_elem x) (hy : f.is_integral_elem y) :
  f.is_integral_elem (x - y) :=
  by 
    simpa only [sub_eq_add_neg] using f.is_integral_add hx (f.is_integral_neg hy)

theorem is_integral_sub {x y : A} (hx : IsIntegral R x) (hy : IsIntegral R y) : IsIntegral R (x - y) :=
  (algebraMap R A).is_integral_sub hx hy

theorem RingHom.is_integral_mul {x y : S} (hx : f.is_integral_elem x) (hy : f.is_integral_elem y) :
  f.is_integral_elem (x*y) :=
  f.is_integral_of_mem_closure hx hy
    (Subring.mul_mem _ (Subring.subset_closure (Or.inl rfl)) (Subring.subset_closure (Or.inr rfl)))

theorem is_integral_mul {x y : A} (hx : IsIntegral R x) (hy : IsIntegral R y) : IsIntegral R (x*y) :=
  (algebraMap R A).is_integral_mul hx hy

variable (R A)

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The integral closure of R in an R-algebra A. -/
  def
    integralClosure
    : Subalgebra R A
    :=
      {
        Carrier := { r | IsIntegral R r } ,
          zero_mem' := is_integral_zero ,
          one_mem' := is_integral_one ,
          add_mem' := fun _ _ => is_integral_add ,
          mul_mem' := fun _ _ => is_integral_mul ,
          algebra_map_mem' := fun x => is_integral_algebra_map
        }

theorem mem_integral_closure_iff_mem_fg {r : A} :
  r ∈ integralClosure R A ↔ ∃ M : Subalgebra R A, M.to_submodule.fg ∧ r ∈ M :=
  ⟨fun hr => ⟨Algebra.adjoin R {r}, fg_adjoin_singleton_of_integral _ hr, Algebra.subset_adjoin rfl⟩,
    fun ⟨M, Hf, hrM⟩ => is_integral_of_mem_of_fg M Hf _ hrM⟩

variable {R} {A}

/-- Mapping an integral closure along an `alg_equiv` gives the integral closure. -/
theorem integral_closure_map_alg_equiv (f : A ≃ₐ[R] B) :
  (integralClosure R A).map (f : A →ₐ[R] B) = integralClosure R B :=
  by 
    ext y 
    rw [Subalgebra.mem_map]
    constructor
    ·
      rintro ⟨x, hx, rfl⟩
      exact is_integral_alg_hom f hx
    ·
      intro hy 
      use f.symm y, is_integral_alg_hom (f.symm : B →ₐ[R] A) hy 
      simp 

theorem integralClosure.is_integral (x : integralClosure R A) : IsIntegral R x :=
  let ⟨p, hpm, hpx⟩ := x.2
  ⟨p, hpm,
    Subtype.eq$
      by 
        rwa [←aeval_def, Subtype.val_eq_coe, ←Subalgebra.val_apply, aeval_alg_hom_apply] at hpx⟩

theorem RingHom.is_integral_of_is_integral_mul_unit (x y : S) (r : R) (hr : (f r*y) = 1)
  (hx : f.is_integral_elem (x*y)) : f.is_integral_elem x :=
  by 
    obtain ⟨p, ⟨p_monic, hp⟩⟩ := hx 
    refine' ⟨scaleRoots p r, ⟨(monic_scale_roots_iff r).2 p_monic, _⟩⟩
    convert scale_roots_eval₂_eq_zero f hp 
    rw [mul_commₓ x y, ←mul_assocₓ, hr, one_mulₓ]

theorem is_integral_of_is_integral_mul_unit {x y : A} {r : R} (hr : (algebraMap R A r*y) = 1)
  (hx : IsIntegral R (x*y)) : IsIntegral R x :=
  (algebraMap R A).is_integral_of_is_integral_mul_unit x y r hr hx

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » G)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » subring.closure G)
/-- Generalization of `is_integral_of_mem_closure` bootstrapped up from that lemma -/
theorem is_integral_of_mem_closure' (G : Set A) (hG : ∀ x _ : x ∈ G, IsIntegral R x) :
  ∀ x _ : x ∈ Subring.closure G, IsIntegral R x :=
  fun x hx =>
    Subring.closure_induction hx hG is_integral_zero is_integral_one (fun _ _ => is_integral_add)
      (fun _ => is_integral_neg) fun _ _ => is_integral_mul

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » G)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » subring.closure G)
theorem is_integral_of_mem_closure'' {S : Type _} [CommRingₓ S] {f : R →+* S} (G : Set S)
  (hG : ∀ x _ : x ∈ G, f.is_integral_elem x) : ∀ x _ : x ∈ Subring.closure G, f.is_integral_elem x :=
  fun x hx => @is_integral_of_mem_closure' R S _ _ f.to_algebra G hG x hx

theorem IsIntegral.pow {x : A} (h : IsIntegral R x) (n : ℕ) : IsIntegral R (x^n) :=
  (integralClosure R A).pow_mem h n

theorem IsIntegral.nsmul {x : A} (h : IsIntegral R x) (n : ℕ) : IsIntegral R (n • x) :=
  (integralClosure R A).nsmul_mem h n

theorem IsIntegral.zsmul {x : A} (h : IsIntegral R x) (n : ℤ) : IsIntegral R (n • x) :=
  (integralClosure R A).zsmul_mem h n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem IsIntegral.multiset_prod {s : Multiset A} (h : ∀ x _ : x ∈ s, IsIntegral R x) : IsIntegral R s.prod :=
  (integralClosure R A).multiset_prod_mem h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem IsIntegral.multiset_sum {s : Multiset A} (h : ∀ x _ : x ∈ s, IsIntegral R x) : IsIntegral R s.sum :=
  (integralClosure R A).multiset_sum_mem h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem IsIntegral.prod {α : Type _} {s : Finset α} (f : α → A) (h : ∀ x _ : x ∈ s, IsIntegral R (f x)) :
  IsIntegral R (∏ x in s, f x) :=
  (integralClosure R A).prod_mem h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
theorem IsIntegral.sum {α : Type _} {s : Finset α} (f : α → A) (h : ∀ x _ : x ∈ s, IsIntegral R (f x)) :
  IsIntegral R (∑ x in s, f x) :=
  (integralClosure R A).sum_mem h

end 

section IsIntegralClosure

/-- `is_integral_closure A R B` is the characteristic predicate stating `A` is
the integral closure of `R` in `B`,
i.e. that an element of `B` is integral over `R` iff it is an element of (the image of) `A`.
-/
class IsIntegralClosure (A R B : Type _) [CommRingₓ R] [CommSemiringₓ A] [CommRingₓ B] [Algebra R B] [Algebra A B] :
  Prop where 
  algebra_map_injective{} : Function.Injective (algebraMap A B)
  is_integral_iff : ∀ {x : B}, IsIntegral R x ↔ ∃ y, algebraMap A B y = x

instance integralClosure.is_integral_closure (R A : Type _) [CommRingₓ R] [CommRingₓ A] [Algebra R A] :
  IsIntegralClosure (integralClosure R A) R A :=
  ⟨Subtype.coe_injective,
    fun x =>
      ⟨fun h => ⟨⟨x, h⟩, rfl⟩,
        by 
          rintro ⟨⟨_, h⟩, rfl⟩
          exact h⟩⟩

namespace IsIntegralClosure

variable {R A B : Type _} [CommRingₓ R] [CommRingₓ A] [CommRingₓ B]

variable [Algebra R B] [Algebra A B] [IsIntegralClosure A R B]

variable (R) {A} (B)

protected theorem IsIntegral [Algebra R A] [IsScalarTower R A B] (x : A) : IsIntegral R x :=
  (is_integral_algebra_map_iff (algebra_map_injective A R B)).mp$
    show IsIntegral R (algebraMap A B x) from is_integral_iff.mpr ⟨x, rfl⟩

theorem is_integral_algebra [Algebra R A] [IsScalarTower R A B] : Algebra.IsIntegral R A :=
  fun x => IsIntegralClosure.is_integral R B x

variable {R} (A) {B}

/-- If `x : B` is integral over `R`, then it is an element of the integral closure of `R` in `B`. -/
noncomputable def mk' (x : B) (hx : IsIntegral R x) : A :=
  Classical.some (is_integral_iff.mp hx)

@[simp]
theorem algebra_map_mk' (x : B) (hx : IsIntegral R x) : algebraMap A B (mk' A x hx) = x :=
  Classical.some_spec (is_integral_iff.mp hx)

@[simp]
theorem mk'_one (h : IsIntegral R (1 : B) := is_integral_one) : mk' A 1 h = 1 :=
  algebra_map_injective A R B$
    by 
      rw [algebra_map_mk', RingHom.map_one]

@[simp]
theorem mk'_zero (h : IsIntegral R (0 : B) := is_integral_zero) : mk' A 0 h = 0 :=
  algebra_map_injective A R B$
    by 
      rw [algebra_map_mk', RingHom.map_zero]

@[simp]
theorem mk'_add (x y : B) (hx : IsIntegral R x) (hy : IsIntegral R y) :
  mk' A (x+y) (is_integral_add hx hy) = mk' A x hx+mk' A y hy :=
  algebra_map_injective A R B$
    by 
      simp only [algebra_map_mk', RingHom.map_add]

@[simp]
theorem mk'_mul (x y : B) (hx : IsIntegral R x) (hy : IsIntegral R y) :
  mk' A (x*y) (is_integral_mul hx hy) = mk' A x hx*mk' A y hy :=
  algebra_map_injective A R B$
    by 
      simp only [algebra_map_mk', RingHom.map_mul]

@[simp]
theorem mk'_algebra_map [Algebra R A] [IsScalarTower R A B] (x : R)
  (h : IsIntegral R (algebraMap R B x) := is_integral_algebra_map) :
  IsIntegralClosure.mk' A (algebraMap R B x) h = algebraMap R A x :=
  algebra_map_injective A R B$
    by 
      rw [algebra_map_mk', ←IsScalarTower.algebra_map_apply]

section lift

variable {R} (A B) {S : Type _} [CommRingₓ S] [Algebra R S] [Algebra S B] [IsScalarTower R S B]

variable [Algebra R A] [IsScalarTower R A B] (h : Algebra.IsIntegral R S)

/-- If `B / S / R` is a tower of ring extensions where `S` is integral over `R`,
then `S` maps (uniquely) into an integral closure `B / A / R`. -/
noncomputable def lift : S →ₐ[R] A :=
  { toFun := fun x => mk' A (algebraMap S B x) (IsIntegral.algebra_map (h x)),
    map_one' :=
      by 
        simp only [RingHom.map_one, mk'_one],
    map_zero' :=
      by 
        simp only [RingHom.map_zero, mk'_zero],
    map_add' :=
      fun x y =>
        by 
          simpRw [←mk'_add, RingHom.map_add],
    map_mul' :=
      fun x y =>
        by 
          simpRw [←mk'_mul, RingHom.map_mul],
    commutes' :=
      fun x =>
        by 
          simpRw [←IsScalarTower.algebra_map_apply, mk'_algebra_map] }

@[simp]
theorem algebra_map_lift (x : S) : algebraMap A B (lift A B h x) = algebraMap S B x :=
  algebra_map_mk' _ _ _

end lift

section Equivₓ

variable (R A B) (A' : Type _) [CommRingₓ A'] [Algebra A' B] [IsIntegralClosure A' R B]

variable [Algebra R A] [Algebra R A'] [IsScalarTower R A B] [IsScalarTower R A' B]

/-- Integral closures are all isomorphic to each other. -/
noncomputable def Equivₓ : A ≃ₐ[R] A' :=
  AlgEquiv.ofAlgHom (lift _ B (is_integral_algebra R B)) (lift _ B (is_integral_algebra R B))
    (by 
      ext x 
      apply algebra_map_injective A' R B 
      simp )
    (by 
      ext x 
      apply algebra_map_injective A R B 
      simp )

@[simp]
theorem algebra_map_equiv (x : A) : algebraMap A' B (Equivₓ R A B A' x) = algebraMap A B x :=
  algebra_map_lift _ _ _ _

end Equivₓ

end IsIntegralClosure

end IsIntegralClosure

section Algebra

open Algebra

variable {R A B S T : Type _}

variable [CommRingₓ R] [CommRingₓ A] [CommRingₓ B] [CommRingₓ S] [CommRingₓ T]

variable [Algebra A B] [Algebra R B] (f : R →+* S) (g : S →+* T)

theorem is_integral_trans_aux (x : B) {p : Polynomial A} (pmonic : monic p) (hp : aeval x p = 0) :
  IsIntegral (adjoin R (↑(p.map$ algebraMap A B).frange : Set B)) x :=
  by 
    generalize hS : (↑(p.map$ algebraMap A B).frange : Set B) = S 
    have coeffs_mem : ∀ i, (p.map$ algebraMap A B).coeff i ∈ adjoin R S
    ·
      intro i 
      byCases' hi : (p.map$ algebraMap A B).coeff i = 0
      ·
        rw [hi]
        exact Subalgebra.zero_mem _ 
      rw [←hS]
      exact subset_adjoin (coeff_mem_frange _ _ hi)
    obtain ⟨q, hq⟩ : ∃ q : Polynomial (adjoin R S), q.map (algebraMap (adjoin R S) B) = (p.map$ algebraMap A B)
    ·
      rw [←Set.mem_range]
      exact (Polynomial.mem_map_range _).2 fun i => ⟨⟨_, coeffs_mem i⟩, rfl⟩
    use q 
    constructor
    ·
      suffices h : (q.map (algebraMap (adjoin R S) B)).Monic
      ·
        refine' monic_of_injective _ h 
        exact Subtype.val_injective
      ·
        rw [hq]
        exact monic_map _ pmonic
    ·
      convert hp using 1
      replace hq := congr_argₓ (eval x) hq 
      convert hq using 1 <;> symm <;> apply eval_map

variable [Algebra R A] [IsScalarTower R A B]

/-- If A is an R-algebra all of whose elements are integral over R,
and x is an element of an A-algebra that is integral over A, then x is integral over R.-/
theorem is_integral_trans (A_int : IsIntegral R A) (x : B) (hx : IsIntegral A x) : IsIntegral R x :=
  by 
    rcases hx with ⟨p, pmonic, hp⟩
    let S : Set B := ↑(p.map$ algebraMap A B).frange 
    refine' is_integral_of_mem_of_fg (adjoin R (S ∪ {x})) _ _ (subset_adjoin$ Or.inr rfl)
    refine' fg_trans (fg_adjoin_of_finite (Finset.finite_to_set _) fun x hx => _) _
    ·
      rw [Finset.mem_coe, frange, Finset.mem_image] at hx 
      rcases hx with ⟨i, _, rfl⟩
      rw [coeff_map]
      exact is_integral_alg_hom (IsScalarTower.toAlgHom R A B) (A_int _)
    ·
      apply fg_adjoin_singleton_of_integral 
      exact is_integral_trans_aux _ pmonic hp

/-- If A is an R-algebra all of whose elements are integral over R,
and B is an A-algebra all of whose elements are integral over A,
then all elements of B are integral over R.-/
theorem Algebra.is_integral_trans (hA : IsIntegral R A) (hB : IsIntegral A B) : IsIntegral R B :=
  fun x => is_integral_trans hA x (hB x)

theorem RingHom.is_integral_trans (hf : f.is_integral) (hg : g.is_integral) : (g.comp f).IsIntegral :=
  @Algebra.is_integral_trans R S T _ _ _ g.to_algebra (g.comp f).toAlgebra f.to_algebra
    (@IsScalarTower.of_algebra_map_eq R S T _ _ _ f.to_algebra g.to_algebra (g.comp f).toAlgebra
      (RingHom.comp_apply g f))
    hf hg

theorem RingHom.is_integral_of_surjective (hf : Function.Surjective f) : f.is_integral :=
  fun x => (hf x).recOn fun y hy => (hy ▸ f.is_integral_map : f.is_integral_elem x)

theorem is_integral_of_surjective (h : Function.Surjective (algebraMap R A)) : IsIntegral R A :=
  (algebraMap R A).is_integral_of_surjective h

/-- If `R → A → B` is an algebra tower with `A → B` injective,
then if the entire tower is an integral extension so is `R → A` -/
theorem is_integral_tower_bot_of_is_integral (H : Function.Injective (algebraMap A B)) {x : A}
  (h : IsIntegral R (algebraMap A B x)) : IsIntegral R x :=
  by 
    rcases h with ⟨p, ⟨hp, hp'⟩⟩
    refine' ⟨p, ⟨hp, _⟩⟩
    rw [IsScalarTower.algebra_map_eq R A B, ←eval₂_map, eval₂_hom, ←RingHom.map_zero (algebraMap A B)] at hp' 
    rw [eval₂_eq_eval_map]
    exact H hp'

theorem RingHom.is_integral_tower_bot_of_is_integral (hg : Function.Injective g) (hfg : (g.comp f).IsIntegral) :
  f.is_integral :=
  fun x =>
    @is_integral_tower_bot_of_is_integral R S T _ _ _ g.to_algebra (g.comp f).toAlgebra f.to_algebra
      (@IsScalarTower.of_algebra_map_eq R S T _ _ _ f.to_algebra g.to_algebra (g.comp f).toAlgebra
        (RingHom.comp_apply g f))
      hg x (hfg (g x))

theorem is_integral_tower_bot_of_is_integral_field {R A B : Type _} [CommRingₓ R] [Field A] [CommRingₓ B] [Nontrivial B]
  [Algebra R A] [Algebra A B] [Algebra R B] [IsScalarTower R A B] {x : A} (h : IsIntegral R (algebraMap A B x)) :
  IsIntegral R x :=
  is_integral_tower_bot_of_is_integral (algebraMap A B).Injective h

theorem RingHom.is_integral_elem_of_is_integral_elem_comp {x : T} (h : (g.comp f).IsIntegralElem x) :
  g.is_integral_elem x :=
  let ⟨p, ⟨hp, hp'⟩⟩ := h
  ⟨p.map f, monic_map f hp,
    by 
      rwa [←eval₂_map] at hp'⟩

theorem RingHom.is_integral_tower_top_of_is_integral (h : (g.comp f).IsIntegral) : g.is_integral :=
  fun x => RingHom.is_integral_elem_of_is_integral_elem_comp f g (h x)

/-- If `R → A → B` is an algebra tower,
then if the entire tower is an integral extension so is `A → B`. -/
theorem is_integral_tower_top_of_is_integral {x : B} (h : IsIntegral R x) : IsIntegral A x :=
  by 
    rcases h with ⟨p, ⟨hp, hp'⟩⟩
    refine' ⟨p.map (algebraMap R A), ⟨monic_map (algebraMap R A) hp, _⟩⟩
    rw [IsScalarTower.algebra_map_eq R A B, ←eval₂_map] at hp' 
    exact hp'

theorem RingHom.is_integral_quotient_of_is_integral {I : Ideal S} (hf : f.is_integral) :
  (Ideal.quotientMap I f le_rfl).IsIntegral :=
  by 
    rintro ⟨x⟩
    obtain ⟨p, ⟨p_monic, hpx⟩⟩ := hf x 
    refine' ⟨p.map (Ideal.Quotient.mk _), ⟨monic_map _ p_monic, _⟩⟩
    simpa only [hom_eval₂, eval₂_map] using congr_argₓ (Ideal.Quotient.mk I) hpx

theorem is_integral_quotient_of_is_integral {I : Ideal A} (hRA : IsIntegral R A) :
  IsIntegral (R ⧸ I.comap (algebraMap R A)) (A ⧸ I) :=
  (algebraMap R A).is_integral_quotient_of_is_integral hRA

theorem is_integral_quotient_map_iff {I : Ideal S} :
  (Ideal.quotientMap I f le_rfl).IsIntegral ↔ ((Ideal.Quotient.mk I).comp f : R →+* S ⧸ I).IsIntegral :=
  by 
    let g := Ideal.Quotient.mk (I.comap f)
    have  := Ideal.quotient_map_comp_mk le_rfl 
    refine' ⟨fun h => _, fun h => RingHom.is_integral_tower_top_of_is_integral g _ (this ▸ h)⟩
    refine' this ▸ RingHom.is_integral_trans g (Ideal.quotientMap I f le_rfl) _ h 
    exact RingHom.is_integral_of_surjective g Ideal.Quotient.mk_surjective

/-- If the integral extension `R → S` is injective, and `S` is a field, then `R` is also a field. -/
theorem is_field_of_is_integral_of_is_field {R S : Type _} [CommRingₓ R] [IsDomain R] [CommRingₓ S] [IsDomain S]
  [Algebra R S] (H : IsIntegral R S) (hRS : Function.Injective (algebraMap R S)) (hS : IsField S) : IsField R :=
  by 
    refine' ⟨⟨0, 1, zero_ne_one⟩, mul_commₓ, fun a ha => _⟩
    obtain ⟨a_inv, ha_inv⟩ := hS.mul_inv_cancel fun h => ha (hRS (trans h (RingHom.map_zero _).symm))
    obtain ⟨p, p_monic, hp⟩ := H a_inv 
    use -∑ i : ℕ in Finset.range p.nat_degree, p.coeff i*a^p.nat_degree - i - 1
    have hq : (∑ i : ℕ in Finset.range (p.nat_degree+1), p.coeff i*a^p.nat_degree - i) = 0
    ·
      apply (algebraMap R S).injective_iff.mp hRS 
      have a_inv_ne_zero : a_inv ≠ 0 := right_ne_zero_of_mul (mt ha_inv.symm.trans one_ne_zero)
      refine' (mul_eq_zero.mp _).resolve_right (pow_ne_zero p.nat_degree a_inv_ne_zero)
      rw [eval₂_eq_sum_range] at hp 
      rw [RingHom.map_sum, Finset.sum_mul]
      refine' (Finset.sum_congr rfl fun i hi => _).trans hp 
      rw [RingHom.map_mul, mul_assocₓ]
      congr 
      have  : (a_inv^p.nat_degree) = (a_inv^p.nat_degree - i)*a_inv^i
      ·
        rw [←pow_addₓ a_inv, tsub_add_cancel_of_le (Nat.le_of_lt_succₓ (finset.mem_range.mp hi))]
      rw [RingHom.map_pow, this, ←mul_assocₓ, ←mul_powₓ, ha_inv, one_pow, one_mulₓ]
    rw [Finset.sum_range_succ_comm, p_monic.coeff_nat_degree, one_mulₓ, tsub_self, pow_zeroₓ, add_eq_zero_iff_eq_neg,
      eq_comm] at hq 
    rw [mul_commₓ, ←neg_mul_eq_neg_mul, Finset.sum_mul]
    convert hq using 2
    refine' Finset.sum_congr rfl fun i hi => _ 
    have  : 1 ≤ p.nat_degree - i := le_tsub_of_add_le_left (finset.mem_range.mp hi)
    rw [mul_assocₓ, ←pow_succ'ₓ, tsub_add_cancel_of_le this]

end Algebra

theorem integral_closure_idem {R : Type _} {A : Type _} [CommRingₓ R] [CommRingₓ A] [Algebra R A] :
  integralClosure (integralClosure R A : Set A) A = ⊥ :=
  eq_bot_iff.2$
    fun x hx =>
      Algebra.mem_bot.2
        ⟨⟨x, @is_integral_trans _ _ _ _ _ _ _ _ (integralClosure R A).Algebra _ integralClosure.is_integral x hx⟩, rfl⟩

section IsDomain

variable {R S : Type _} [CommRingₓ R] [CommRingₓ S] [IsDomain S] [Algebra R S]

instance : IsDomain (integralClosure R S) :=
  inferInstance

end IsDomain

