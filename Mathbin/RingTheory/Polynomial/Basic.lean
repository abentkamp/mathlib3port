import Mathbin.Algebra.CharP.Basic 
import Mathbin.Data.MvPolynomial.CommRing 
import Mathbin.Data.MvPolynomial.Equiv 
import Mathbin.RingTheory.Polynomial.Content 
import Mathbin.RingTheory.UniqueFactorizationDomain

/-!
# Ring-theoretic supplement of data.polynomial.

## Main results
* `mv_polynomial.is_domain`:
  If a ring is an integral domain, then so is its polynomial ring over finitely many variables.
* `polynomial.is_noetherian_ring`:
  Hilbert basis theorem, that if a ring is noetherian then so is its polynomial ring.
* `polynomial.wf_dvd_monoid`:
  If an integral domain is a `wf_dvd_monoid`, then so is its polynomial ring.
* `polynomial.unique_factorization_monoid`:
  If an integral domain is a `unique_factorization_monoid`, then so is its polynomial ring.
-/


noncomputable section 

open_locale Classical BigOperators

universe u v w

namespace Polynomial

instance {R : Type u} [Semiringₓ R] (p : ℕ) [h : CharP R p] : CharP (Polynomial R) p :=
  let ⟨h⟩ := h
  ⟨fun n =>
      by 
        rw [←C.map_nat_cast, ←C_0, C_inj, h]⟩

variable (R : Type u) [CommRingₓ R]

/-- The `R`-submodule of `R[X]` consisting of polynomials of degree ≤ `n`. -/
def degree_le (n : WithBot ℕ) : Submodule R (Polynomial R) :=
  ⨅ k : ℕ, ⨅ h : ↑k > n, (lcoeff R k).ker

/-- The `R`-submodule of `R[X]` consisting of polynomials of degree < `n`. -/
def degree_lt (n : ℕ) : Submodule R (Polynomial R) :=
  ⨅ k : ℕ, ⨅ h : k ≥ n, (lcoeff R k).ker

variable {R}

theorem mem_degree_le {n : WithBot ℕ} {f : Polynomial R} : f ∈ degree_le R n ↔ degree f ≤ n :=
  by 
    simp only [degree_le, Submodule.mem_infi, degree_le_iff_coeff_zero, LinearMap.mem_ker] <;> rfl

@[mono]
theorem degree_le_mono {m n : WithBot ℕ} (H : m ≤ n) : degree_le R m ≤ degree_le R n :=
  fun f hf => mem_degree_le.2 (le_transₓ (mem_degree_le.1 hf) H)

theorem degree_le_eq_span_X_pow {n : ℕ} :
  degree_le R n = Submodule.span R (↑(Finset.range (n+1)).Image fun n => (X : Polynomial R)^n) :=
  by 
    apply le_antisymmₓ
    ·
      intro p hp 
      replace hp := mem_degree_le.1 hp 
      rw [←Polynomial.sum_monomial_eq p, Polynomial.sum]
      refine' Submodule.sum_mem _ fun k hk => _ 
      show monomial _ _ ∈ _ 
      have  := WithBot.coe_le_coe.1 (Finset.sup_le_iff.1 hp k hk)
      rw [monomial_eq_C_mul_X, C_mul']
      refine'
        Submodule.smul_mem _ _
          (Submodule.subset_span$
            Finset.mem_coe.2$ Finset.mem_image.2 ⟨_, Finset.mem_range.2 (Nat.lt_succ_of_leₓ this), rfl⟩)
    rw [Submodule.span_le, Finset.coe_image, Set.image_subset_iff]
    intro k hk 
    apply mem_degree_le.2 
    exact (degree_X_pow_le _).trans (WithBot.coe_le_coe.2$ Nat.le_of_lt_succₓ$ Finset.mem_range.1 hk)

theorem mem_degree_lt {n : ℕ} {f : Polynomial R} : f ∈ degree_lt R n ↔ degree f < n :=
  by 
    simpRw [degree_lt, Submodule.mem_infi, LinearMap.mem_ker, degree, Finset.sup_lt_iff (WithBot.bot_lt_coe n),
      mem_support_iff, WithBot.some_eq_coe, WithBot.coe_lt_coe, lt_iff_not_ge', Ne, not_imp_not]
    rfl

@[mono]
theorem degree_lt_mono {m n : ℕ} (H : m ≤ n) : degree_lt R m ≤ degree_lt R n :=
  fun f hf => mem_degree_lt.2 (lt_of_lt_of_leₓ (mem_degree_lt.1 hf)$ WithBot.coe_le_coe.2 H)

theorem degree_lt_eq_span_X_pow {n : ℕ} :
  degree_lt R n = Submodule.span R (↑((Finset.range n).Image fun n => X^n : Finset (Polynomial R))) :=
  by 
    apply le_antisymmₓ
    ·
      intro p hp 
      replace hp := mem_degree_lt.1 hp 
      rw [←Polynomial.sum_monomial_eq p, Polynomial.sum]
      refine' Submodule.sum_mem _ fun k hk => _ 
      show monomial _ _ ∈ _ 
      have  := WithBot.coe_lt_coe.1 ((Finset.sup_lt_iff$ WithBot.bot_lt_coe n).1 hp k hk)
      rw [monomial_eq_C_mul_X, C_mul']
      refine'
        Submodule.smul_mem _ _
          (Submodule.subset_span$ Finset.mem_coe.2$ Finset.mem_image.2 ⟨_, Finset.mem_range.2 this, rfl⟩)
    rw [Submodule.span_le, Finset.coe_image, Set.image_subset_iff]
    intro k hk 
    apply mem_degree_lt.2 
    exact lt_of_le_of_ltₓ (degree_X_pow_le _) (WithBot.coe_lt_coe.2$ Finset.mem_range.1 hk)

/-- The first `n` coefficients on `degree_lt n` form a linear equivalence with `fin n → F`. -/
def degree_lt_equiv (F : Type _) [Field F] (n : ℕ) : degree_lt F n ≃ₗ[F] Finₓ n → F :=
  { toFun := fun p n => (↑p : Polynomial F).coeff n,
    invFun :=
      fun f =>
        ⟨∑ i : Finₓ n, monomial i (f i),
          (degree_lt F n).sum_mem
            fun i _ =>
              mem_degree_lt.mpr (lt_of_le_of_ltₓ (degree_monomial_le i (f i)) (WithBot.coe_lt_coe.mpr i.is_lt))⟩,
    map_add' :=
      fun p q =>
        by 
          ext 
          rw [Submodule.coe_add, coeff_add]
          rfl,
    map_smul' :=
      fun x p =>
        by 
          ext 
          rw [Submodule.coe_smul, coeff_smul]
          rfl,
    left_inv :=
      by 
        rintro ⟨p, hp⟩
        ext1 
        simp only [Submodule.coe_mk]
        byCases' hp0 : p = 0
        ·
          subst hp0 
          simp only [coeff_zero, LinearMap.map_zero, Finset.sum_const_zero]
        rw [mem_degree_lt, degree_eq_nat_degree hp0, WithBot.coe_lt_coe] at hp 
        convRHS => rw [p.as_sum_range' n hp, ←Finₓ.sum_univ_eq_sum_range],
    right_inv :=
      by 
        intro f 
        ext i 
        simp only [finset_sum_coeff, Submodule.coe_mk]
        rw [Finset.sum_eq_single i, coeff_monomial, if_pos rfl]
        ·
          rintro j - hji 
          rw [coeff_monomial, if_neg]
          rwa [←Subtype.ext_iff]
        ·
          intro h 
          exact (h (Finset.mem_univ _)).elim }

/-- The finset of nonzero coefficients of a polynomial. -/
def frange (p : Polynomial R) : Finset R :=
  Finset.image (fun n => p.coeff n) p.support

theorem frange_zero : frange (0 : Polynomial R) = ∅ :=
  rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (n «expr ∈ » p.support)
theorem mem_frange_iff {p : Polynomial R} {c : R} : c ∈ p.frange ↔ ∃ (n : _)(_ : n ∈ p.support), c = p.coeff n :=
  by 
    simp [frange, eq_comm]

theorem frange_one : frange (1 : Polynomial R) ⊆ {1} :=
  by 
    simp [frange, Finset.image_subset_iff]
    simp only [←C_1, coeff_C]
    intro n hn 
    simp only [exists_prop, ite_eq_right_iff, not_forall] at hn 
    simp [hn]

theorem coeff_mem_frange (p : Polynomial R) (n : ℕ) (h : p.coeff n ≠ 0) : p.coeff n ∈ p.frange :=
  by 
    simp only [frange, exists_prop, mem_support_iff, Finset.mem_image, Ne.def]
    exact ⟨n, h, rfl⟩

/-- Given a polynomial, return the polynomial whose coefficients are in
the ring closure of the original coefficients. -/
def restriction (p : Polynomial R) : Polynomial (Subring.closure (↑p.frange : Set R)) :=
  ∑ i in p.support,
    monomial i
      (⟨p.coeff i,
        if H : p.coeff i = 0 then H.symm ▸ (Subring.closure _).zero_mem else
          Subring.subset_closure (p.coeff_mem_frange _ H)⟩ :
      Subring.closure (↑p.frange : Set R))

@[simp]
theorem coeff_restriction {p : Polynomial R} {n : ℕ} : ↑coeff (restriction p) n = coeff p n :=
  by 
    simp only [restriction, coeff_monomial, finset_sum_coeff, mem_support_iff, Finset.sum_ite_eq', Ne.def, ite_not]
    splitIfs
    ·
      rw [h]
      rfl
    ·
      rfl

@[simp]
theorem coeff_restriction' {p : Polynomial R} {n : ℕ} : (coeff (restriction p) n).1 = coeff p n :=
  coeff_restriction

@[simp]
theorem support_restriction (p : Polynomial R) : support (restriction p) = support p :=
  by 
    ext i 
    simp only [mem_support_iff, not_iff_not, Ne.def]
    convRHS => rw [←coeff_restriction]
    exact
      ⟨fun H =>
          by 
            rw [H]
            rfl,
        fun H => Subtype.coe_injective H⟩

@[simp]
theorem map_restriction (p : Polynomial R) : p.restriction.map (algebraMap _ _) = p :=
  ext$
    fun n =>
      by 
        rw [coeff_map, Algebra.algebra_map_of_subring_apply, coeff_restriction]

@[simp]
theorem degree_restriction {p : Polynomial R} : (restriction p).degree = p.degree :=
  by 
    simp [degree]

@[simp]
theorem nat_degree_restriction {p : Polynomial R} : (restriction p).natDegree = p.nat_degree :=
  by 
    simp [nat_degree]

@[simp]
theorem monic_restriction {p : Polynomial R} : monic (restriction p) ↔ monic p :=
  by 
    simp only [monic, leading_coeff, nat_degree_restriction]
    rw [←@coeff_restriction _ _ p]
    exact
      ⟨fun H =>
          by 
            rw [H]
            rfl,
        fun H => Subtype.coe_injective H⟩

@[simp]
theorem restriction_zero : restriction (0 : Polynomial R) = 0 :=
  by 
    simp only [restriction, Finset.sum_empty, support_zero]

@[simp]
theorem restriction_one : restriction (1 : Polynomial R) = 1 :=
  ext$
    fun i =>
      Subtype.eq$
        by 
          rw [coeff_restriction', coeff_one, coeff_one] <;> splitIfs <;> rfl

variable {S : Type v} [Ringₓ S] {f : R →+* S} {x : S}

theorem eval₂_restriction {p : Polynomial R} : eval₂ f x p = eval₂ (f.comp (Subring.subtype _)) x p.restriction :=
  by 
    simp only [eval₂_eq_sum, Sum, support_restriction, ←@coeff_restriction _ _ p]
    rfl

section ToSubring

variable (p : Polynomial R) (T : Subring R)

/-- Given a polynomial `p` and a subring `T` that contains the coefficients of `p`,
return the corresponding polynomial whose coefficients are in `T. -/
def to_subring (hp : (↑p.frange : Set R) ⊆ T) : Polynomial T :=
  ∑ i in p.support,
    monomial i (⟨p.coeff i, if H : p.coeff i = 0 then H.symm ▸ T.zero_mem else hp (p.coeff_mem_frange _ H)⟩ : T)

variable (hp : (↑p.frange : Set R) ⊆ T)

include hp

@[simp]
theorem coeff_to_subring {n : ℕ} : ↑coeff (to_subring p T hp) n = coeff p n :=
  by 
    simp only [to_subring, coeff_monomial, finset_sum_coeff, mem_support_iff, Finset.sum_ite_eq', Ne.def, ite_not]
    splitIfs
    ·
      rw [h]
      rfl
    ·
      rfl

@[simp]
theorem coeff_to_subring' {n : ℕ} : (coeff (to_subring p T hp) n).1 = coeff p n :=
  coeff_to_subring _ _ hp

@[simp]
theorem support_to_subring : support (to_subring p T hp) = support p :=
  by 
    ext i 
    simp only [mem_support_iff, not_iff_not, Ne.def]
    convRHS => rw [←coeff_to_subring p T hp]
    exact
      ⟨fun H =>
          by 
            rw [H]
            rfl,
        fun H => Subtype.coe_injective H⟩

@[simp]
theorem degree_to_subring : (to_subring p T hp).degree = p.degree :=
  by 
    simp [degree]

@[simp]
theorem nat_degree_to_subring : (to_subring p T hp).natDegree = p.nat_degree :=
  by 
    simp [nat_degree]

@[simp]
theorem monic_to_subring : monic (to_subring p T hp) ↔ monic p :=
  by 
    simpRw [monic, leading_coeff, nat_degree_to_subring, ←coeff_to_subring p T hp]
    exact
      ⟨fun H =>
          by 
            rw [H]
            rfl,
        fun H => Subtype.coe_injective H⟩

omit hp

@[simp]
theorem to_subring_zero :
  to_subring (0 : Polynomial R) T
      (by 
        simp [frange_zero]) =
    0 :=
  by 
    ext i 
    simp 

@[simp]
theorem to_subring_one :
  to_subring (1 : Polynomial R) T (Set.Subset.trans frange_one$ Finset.singleton_subset_set_iff.2 T.one_mem) = 1 :=
  ext$
    fun i =>
      Subtype.eq$
        by 
          rw [coeff_to_subring', coeff_one, coeff_one] <;> splitIfs <;> rfl

@[simp]
theorem map_to_subring : (p.to_subring T hp).map (Subring.subtype T) = p :=
  by 
    ext n 
    simp [coeff_map]

end ToSubring

variable (T : Subring R)

/-- Given a polynomial whose coefficients are in some subring, return
the corresponding polynomial whose coefficients are in the ambient ring. -/
def of_subring (p : Polynomial T) : Polynomial R :=
  ∑ i in p.support, monomial i (p.coeff i : R)

theorem coeff_of_subring (p : Polynomial T) (n : ℕ) : coeff (of_subring T p) n = (coeff p n : T) :=
  by 
    simp only [of_subring, coeff_monomial, finset_sum_coeff, mem_support_iff, Finset.sum_ite_eq', ite_eq_right_iff,
      Ne.def, ite_not, not_not, ite_eq_left_iff]
    intro h 
    rw [h]
    rfl

@[simp]
theorem frange_of_subring {p : Polynomial T} : (↑(p.of_subring T).frange : Set R) ⊆ T :=
  by 
    intro i hi 
    simp only [frange, Set.mem_image, mem_support_iff, Ne.def, Finset.mem_coe, Finset.coe_image] at hi 
    rcases hi with ⟨n, hn, h'n⟩
    rw [←h'n, coeff_of_subring]
    exact Subtype.mem (coeff p n : T)

section ModByMonic

variable {q : Polynomial R}

theorem mem_ker_mod_by_monic [Nontrivial R] (hq : q.monic) {p : Polynomial R} : p ∈ (mod_by_monic_hom hq).ker ↔ q ∣ p :=
  LinearMap.mem_ker.trans (dvd_iff_mod_by_monic_eq_zero hq)

@[simp]
theorem ker_mod_by_monic_hom [Nontrivial R] (hq : q.monic) :
  (Polynomial.modByMonicHom hq).ker = (Ideal.span {q}).restrictScalars R :=
  Submodule.ext fun f => (mem_ker_mod_by_monic hq).trans Ideal.mem_span_singleton.symm

end ModByMonic

end Polynomial

variable {R : Type u} {S : Type _} {σ : Type v} {M : Type w}

variable [CommRingₓ R] [CommRingₓ S] [AddCommGroupₓ M] [Module R M]

namespace Ideal

open Polynomial

/-- If every coefficient of a polynomial is in an ideal `I`, then so is the polynomial itself -/
theorem polynomial_mem_ideal_of_coeff_mem_ideal (I : Ideal (Polynomial R)) (p : Polynomial R)
  (hp : ∀ n : ℕ, p.coeff n ∈ I.comap C) : p ∈ I :=
  sum_C_mul_X_eq p ▸ Submodule.sum_mem I fun n hn => I.mul_mem_right _ (hp n)

/-- The push-forward of an ideal `I` of `R` to `polynomial R` via inclusion
 is exactly the set of polynomials whose coefficients are in `I` -/
theorem mem_map_C_iff {I : Ideal R} {f : Polynomial R} :
  f ∈ (Ideal.map C I : Ideal (Polynomial R)) ↔ ∀ n : ℕ, f.coeff n ∈ I :=
  by 
    constructor
    ·
      intro hf 
      apply Submodule.span_induction hf
      ·
        intro f hf n 
        cases' (Set.mem_image _ _ _).mp hf with x hx 
        rw [←hx.right, coeff_C]
        byCases' n = 0
        ·
          simpa [h] using hx.left
        ·
          simp [h]
      ·
        simp 
      ·
        exact
          fun f g hf hg n =>
            by 
              simp [I.add_mem (hf n) (hg n)]
      ·
        refine' fun f g hg n => _ 
        rw [smul_eq_mul, coeff_mul]
        exact I.sum_mem fun c hc => I.smul_mem (f.coeff c.fst) (hg c.snd)
    ·
      intro hf 
      rw [←sum_monomial_eq f]
      refine' (I.map C : Ideal (Polynomial R)).sum_mem fun n hn => _ 
      simp [monomial_eq_C_mul_X]
      rw [mul_commₓ]
      exact (I.map C : Ideal (Polynomial R)).mul_mem_left _ (mem_map_of_mem _ (hf n))

theorem _root_.polynomial.ker_map_ring_hom (f : R →+* S) : (Polynomial.mapRingHom f).ker = f.ker.map C :=
  by 
    ext 
    rw [mem_map_C_iff, RingHom.mem_ker, Polynomial.ext_iff]
    simpRw [coe_map_ring_hom, coeff_map, coeff_zero, RingHom.mem_ker]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » I)
theorem quotient_map_C_eq_zero {I : Ideal R} :
  ∀ a _ : a ∈ I, ((Quotientₓ.mk (map C I : Ideal (Polynomial R))).comp C) a = 0 :=
  by 
    intro a ha 
    rw [RingHom.comp_apply, quotient.eq_zero_iff_mem]
    exact mem_map_of_mem _ ha

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (f «expr ∈ » (map C I : ideal (polynomial R)))
theorem eval₂_C_mk_eq_zero {I : Ideal R} :
  ∀ f _ : f ∈ (map C I : Ideal (Polynomial R)), eval₂_ring_hom (C.comp (Quotientₓ.mk I)) X f = 0 :=
  by 
    intro a ha 
    rw [←sum_monomial_eq a]
    dsimp 
    rw [eval₂_sum]
    refine' Finset.sum_eq_zero fun n hn => _ 
    dsimp 
    rw [eval₂_monomial (C.comp (Quotientₓ.mk I)) X]
    refine' mul_eq_zero_of_left (Polynomial.ext fun m => _) (X^n)
    erw [coeff_C]
    byCases' h : m = 0
    ·
      simpa [h] using quotient.eq_zero_iff_mem.2 ((mem_map_C_iff.1 ha) n)
    ·
      simp [h]

/-- If `I` is an ideal of `R`, then the ring polynomials over the quotient ring `I.quotient` is
isomorphic to the quotient of `polynomial R` by the ideal `map C I`,
where `map C I` contains exactly the polynomials whose coefficients all lie in `I` -/
def polynomial_quotient_equiv_quotient_polynomial (I : Ideal R) :
  Polynomial (R ⧸ I) ≃+* Polynomial R ⧸ (map C I : Ideal (Polynomial R)) :=
  { toFun :=
      eval₂_ring_hom (Quotientₓ.lift I ((Quotientₓ.mk (map C I : Ideal (Polynomial R))).comp C) quotient_map_C_eq_zero)
        (Quotientₓ.mk (map C I : Ideal (Polynomial R)) X),
    invFun :=
      Quotientₓ.lift (map C I : Ideal (Polynomial R)) (eval₂_ring_hom (C.comp (Quotientₓ.mk I)) X) eval₂_C_mk_eq_zero,
    map_mul' :=
      fun f g =>
        by 
          simp only [coe_eval₂_ring_hom, eval₂_mul],
    map_add' :=
      fun f g =>
        by 
          simp only [eval₂_add, coe_eval₂_ring_hom],
    left_inv :=
      by 
        intro f 
        apply Polynomial.induction_on' f
        ·
          intro p q hp hq 
          simp only [coe_eval₂_ring_hom] at hp 
          simp only [coe_eval₂_ring_hom] at hq 
          simp only [coe_eval₂_ring_hom, hp, hq, RingHom.map_add]
        ·
          rintro n ⟨x⟩
          simp only [monomial_eq_smul_X, C_mul', Quotientₓ.lift_mk, Submodule.Quotient.quot_mk_eq_mk, quotient.mk_eq_mk,
            eval₂_X_pow, eval₂_smul, coe_eval₂_ring_hom, RingHom.map_pow, eval₂_C, RingHom.coe_comp, RingHom.map_mul,
            eval₂_X],
    right_inv :=
      by 
        rintro ⟨f⟩
        apply Polynomial.induction_on' f
        ·
          simpIntro p q hp hq 
          rw [hp, hq]
        ·
          intro n a 
          simp only [monomial_eq_smul_X, ←C_mul' a (X^n), Quotientₓ.lift_mk, Submodule.Quotient.quot_mk_eq_mk,
            quotient.mk_eq_mk, eval₂_X_pow, eval₂_smul, coe_eval₂_ring_hom, RingHom.map_pow, eval₂_C, RingHom.coe_comp,
            RingHom.map_mul, eval₂_X] }

@[simp]
theorem polynomial_quotient_equiv_quotient_polynomial_symm_mk (I : Ideal R) (f : Polynomial R) :
  I.polynomial_quotient_equiv_quotient_polynomial.symm (Quotientₓ.mk _ f) = f.map (Quotientₓ.mk I) :=
  by 
    rw [polynomial_quotient_equiv_quotient_polynomial, RingEquiv.symm_mk, RingEquiv.coe_mk, Ideal.Quotient.lift_mk,
      coe_eval₂_ring_hom, eval₂_eq_eval_map, ←Polynomial.map_map, ←eval₂_eq_eval_map, Polynomial.eval₂_C_X]

@[simp]
theorem polynomial_quotient_equiv_quotient_polynomial_map_mk (I : Ideal R) (f : Polynomial R) :
  I.polynomial_quotient_equiv_quotient_polynomial (f.map I) = Quotientₓ.mk _ f :=
  by 
    apply (polynomial_quotient_equiv_quotient_polynomial I).symm.Injective 
    rw [RingEquiv.symm_apply_apply, polynomial_quotient_equiv_quotient_polynomial_symm_mk]

/-- If `P` is a prime ideal of `R`, then `R[x]/(P)` is an integral domain. -/
theorem is_domain_map_C_quotient {P : Ideal R} (H : is_prime P) :
  IsDomain (Polynomial R ⧸ (map C P : Ideal (Polynomial R))) :=
  RingEquiv.is_domain (Polynomial (R ⧸ P)) (polynomial_quotient_equiv_quotient_polynomial P).symm

/-- If `P` is a prime ideal of `R`, then `P.R[x]` is a prime ideal of `R[x]`. -/
theorem is_prime_map_C_of_is_prime {P : Ideal R} (H : is_prime P) : is_prime (map C P : Ideal (Polynomial R)) :=
  (quotient.is_domain_iff_prime (map C P : Ideal (Polynomial R))).mp (is_domain_map_C_quotient H)

/-- Given any ring `R` and an ideal `I` of `polynomial R`, we get a map `R → R[x] → R[x]/I`.
  If we let `R` be the image of `R` in `R[x]/I` then we also have a map `R[x] → R'[x]`.
  In particular we can map `I` across this map, to get `I'` and a new map `R' → R'[x] → R'[x]/I`.
  This theorem shows `I'` will not contain any non-zero constant polynomials
  -/
theorem eq_zero_of_polynomial_mem_map_range (I : Ideal (Polynomial R)) (x : ((Quotientₓ.mk I).comp C).range)
  (hx : C x ∈ I.map (Polynomial.mapRingHom ((Quotientₓ.mk I).comp C).range_restrict)) : x = 0 :=
  by 
    let i := ((Quotientₓ.mk I).comp C).range_restrict 
    have hi' : (Polynomial.mapRingHom i).ker ≤ I
    ·
      refine' fun f hf => polynomial_mem_ideal_of_coeff_mem_ideal I f fun n => _ 
      rw [mem_comap, ←quotient.eq_zero_iff_mem, ←RingHom.comp_apply]
      rw [RingHom.mem_ker, coe_map_ring_hom] at hf 
      replace hf := congr_argₓ (fun f : Polynomial _ => f.coeff n) hf 
      simp only [coeff_map, coeff_zero] at hf 
      rwa [Subtype.ext_iff, RingHom.coe_range_restrict] at hf 
    obtain ⟨x, hx'⟩ := x 
    obtain ⟨y, rfl⟩ := RingHom.mem_range.1 hx' 
    refine' Subtype.eq _ 
    simp only [RingHom.comp_apply, quotient.eq_zero_iff_mem, Subring.coe_zero, Subtype.val_eq_coe]
    suffices  : C (i y) ∈ I.map (Polynomial.mapRingHom i)
    ·
      obtain ⟨f, hf⟩ :=
        mem_image_of_mem_map_of_surjective (Polynomial.mapRingHom i)
          (Polynomial.map_surjective _ ((Quotientₓ.mk I).comp C).range_restrict_surjective) this 
      refine' sub_add_cancel (C y) f ▸ I.add_mem (hi' _ : C y - f ∈ I) hf.1
      rw [RingHom.mem_ker, RingHom.map_sub, hf.2, sub_eq_zero, coe_map_ring_hom, map_C]
    exact hx

/-- `polynomial R` is never a field for any ring `R`. -/
theorem polynomial_not_is_field : ¬IsField (Polynomial R) :=
  by 
    byContra hR 
    byCases' hR' : ∃ x y : R, x ≠ y
    ·
      have  : Nontrivial R :=
        let ⟨x, y, hxy⟩ := hR' 
        nontrivial_of_ne x y hxy 
      obtain ⟨p, hp⟩ := hR.mul_inv_cancel X_ne_zero 
      byCases' hp0 : p = 0
      ·
        replace hp := congr_argₓ degree hp 
        rw [hp0, mul_zero, degree_zero, degree_one] at hp 
        contradiction
      ·
        have  : p.degree < (X*p).degree := mul_commₓ p X ▸ degree_lt_degree_mul_X hp0 
        rw [congr_argₓ degree hp, degree_one, Nat.WithBot.lt_zero_iff, degree_eq_bot] at this 
        exact hp0 this
    ·
      pushNeg  at hR' 
      exact
        let ⟨x, y, hxy⟩ := hR.exists_pair_ne 
        hxy (Polynomial.ext fun n => hR' _ _)

/-- The only constant in a maximal ideal over a field is `0`. -/
theorem eq_zero_of_constant_mem_of_maximal (hR : IsField R) (I : Ideal (Polynomial R)) [hI : I.is_maximal] (x : R)
  (hx : C x ∈ I) : x = 0 :=
  by 
    refine' Classical.by_contradiction fun hx0 => hI.ne_top ((eq_top_iff_one I).2 _)
    obtain ⟨y, hy⟩ := hR.mul_inv_cancel hx0 
    convert I.smul_mem (C y) hx 
    rw [smul_eq_mul, ←C.map_mul, mul_commₓ y x, hy, RingHom.map_one]

/-- Transport an ideal of `R[X]` to an `R`-submodule of `R[X]`. -/
def of_polynomial (I : Ideal (Polynomial R)) : Submodule R (Polynomial R) :=
  { Carrier := I.carrier, zero_mem' := I.zero_mem, add_mem' := fun _ _ => I.add_mem,
    smul_mem' :=
      fun c x H =>
        by 
          rw [←C_mul']
          exact I.mul_mem_left _ H }

variable {I : Ideal (Polynomial R)}

theorem mem_of_polynomial x : x ∈ I.of_polynomial ↔ x ∈ I :=
  Iff.rfl

variable (I)

/-- Given an ideal `I` of `R[X]`, make the `R`-submodule of `I`
consisting of polynomials of degree ≤ `n`. -/
def degree_le (n : WithBot ℕ) : Submodule R (Polynomial R) :=
  degree_le R n⊓I.of_polynomial

/-- Given an ideal `I` of `R[X]`, make the ideal in `R` of
leading coefficients of polynomials in `I` with degree ≤ `n`. -/
def leading_coeff_nth (n : ℕ) : Ideal R :=
  (I.degree_le n).map$ lcoeff R n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p «expr ∈ » I)
theorem mem_leading_coeff_nth (n : ℕ) x :
  x ∈ I.leading_coeff_nth n ↔ ∃ (p : _)(_ : p ∈ I), degree p ≤ n ∧ leading_coeff p = x :=
  by 
    simp only [leading_coeff_nth, degree_le, Submodule.mem_map, lcoeff_apply, Submodule.mem_inf, mem_degree_le]
    constructor
    ·
      rintro ⟨p, ⟨hpdeg, hpI⟩, rfl⟩
      cases' lt_or_eq_of_leₓ hpdeg with hpdeg hpdeg
      ·
        refine' ⟨0, I.zero_mem, bot_le, _⟩
        rw [leading_coeff_zero, eq_comm]
        exact coeff_eq_zero_of_degree_lt hpdeg
      ·
        refine' ⟨p, hpI, le_of_eqₓ hpdeg, _⟩
        rw [leading_coeff, nat_degree, hpdeg]
        rfl
    ·
      rintro ⟨p, hpI, hpdeg, rfl⟩
      have  : (nat_degree p+n - nat_degree p) = n
      ·
        exact add_tsub_cancel_of_le (nat_degree_le_of_degree_le hpdeg)
      refine' ⟨p*X^n - nat_degree p, ⟨_, I.mul_mem_right _ hpI⟩, _⟩
      ·
        apply le_transₓ (degree_mul_le _ _) _ 
        apply le_transₓ (add_le_add degree_le_nat_degree (degree_X_pow_le _)) _ 
        rw [←WithBot.coe_add, this]
        exact le_reflₓ _
      ·
        rw [leading_coeff, ←coeff_mul_X_pow p (n - nat_degree p), this]

theorem mem_leading_coeff_nth_zero x : x ∈ I.leading_coeff_nth 0 ↔ C x ∈ I :=
  (mem_leading_coeff_nth _ _ _).trans
    ⟨fun ⟨p, hpI, hpdeg, hpx⟩ =>
        by 
          rwa [←hpx, leading_coeff, Nat.eq_zero_of_le_zeroₓ (nat_degree_le_of_degree_le hpdeg),
            ←eq_C_of_degree_le_zero hpdeg],
      fun hx => ⟨C x, hx, degree_C_le, leading_coeff_C x⟩⟩

theorem leading_coeff_nth_mono {m n : ℕ} (H : m ≤ n) : I.leading_coeff_nth m ≤ I.leading_coeff_nth n :=
  by 
    intro r hr 
    simp only [SetLike.mem_coe, mem_leading_coeff_nth] at hr⊢
    rcases hr with ⟨p, hpI, hpdeg, rfl⟩
    refine' ⟨p*X^n - m, I.mul_mem_right _ hpI, _, leading_coeff_mul_X_pow⟩
    refine' le_transₓ (degree_mul_le _ _) _ 
    refine' le_transₓ (add_le_add hpdeg (degree_X_pow_le _)) _ 
    rw [←WithBot.coe_add, add_tsub_cancel_of_le H]
    exact le_reflₓ _

/-- Given an ideal `I` in `R[X]`, make the ideal in `R` of the
leading coefficients in `I`. -/
def leading_coeff : Ideal R :=
  ⨆ n : ℕ, I.leading_coeff_nth n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p «expr ∈ » I)
theorem mem_leading_coeff x : x ∈ I.leading_coeff ↔ ∃ (p : _)(_ : p ∈ I), Polynomial.leadingCoeff p = x :=
  by 
    rw [leading_coeff, Submodule.mem_supr_of_directed]
    simp only [mem_leading_coeff_nth]
    ·
      constructor
      ·
        rintro ⟨i, p, hpI, hpdeg, rfl⟩
        exact ⟨p, hpI, rfl⟩
      rintro ⟨p, hpI, rfl⟩
      exact ⟨nat_degree p, p, hpI, degree_le_nat_degree, rfl⟩
    intro i j 
    exact ⟨i+j, I.leading_coeff_nth_mono (Nat.le_add_rightₓ _ _), I.leading_coeff_nth_mono (Nat.le_add_leftₓ _ _)⟩

theorem is_fg_degree_le [IsNoetherianRing R] (n : ℕ) : Submodule.Fg (I.degree_le n) :=
  is_noetherian_submodule_left.1 (is_noetherian_of_fg_of_noetherian _ ⟨_, degree_le_eq_span_X_pow.symm⟩) _

end Ideal

namespace Polynomial

instance (priority := 100) {R : Type _} [CommRingₓ R] [IsDomain R] [WfDvdMonoid R] : WfDvdMonoid (Polynomial R) :=
  { well_founded_dvd_not_unit :=
      by 
        classical 
        refine'
          RelHom.well_founded ⟨fun p => (if p = 0 then ⊤ else ↑p.degree, p.leading_coeff), _⟩
            (Prod.lex_wf (WithTop.well_founded_lt$ WithBot.well_founded_lt Nat.lt_wf)
              ‹WfDvdMonoid R›.well_founded_dvd_not_unit)
        rintro a b ⟨ane0, ⟨c, ⟨not_unit_c, rfl⟩⟩⟩
        rw [Polynomial.degree_mul, if_neg ane0]
        splitIfs with hac
        ·
          rw [hac, Polynomial.leading_coeff_zero]
          apply Prod.Lex.left 
          exact lt_of_le_of_neₓ le_top WithTop.coe_ne_top 
        have cne0 : c ≠ 0 := right_ne_zero_of_mul hac 
        simp only [cne0, ane0, Polynomial.leading_coeff_mul]
        byCases' hdeg : c.degree = 0
        ·
          simp only [hdeg, add_zeroₓ]
          refine' Prod.Lex.right _ ⟨_, ⟨c.leading_coeff, fun unit_c => not_unit_c _, rfl⟩⟩
          ·
            rwa [Ne, Polynomial.leading_coeff_eq_zero]
          rw [Polynomial.is_unit_iff, Polynomial.eq_C_of_degree_eq_zero hdeg]
          use c.leading_coeff, unit_c 
          rw [Polynomial.leadingCoeff, Polynomial.nat_degree_eq_of_degree_eq_some hdeg]
        ·
          apply Prod.Lex.left 
          rw [Polynomial.degree_eq_nat_degree cne0] at *
          rw [WithTop.coe_lt_coe, Polynomial.degree_eq_nat_degree ane0, ←WithBot.coe_add, WithBot.coe_lt_coe]
          exact lt_add_of_pos_right _ (Nat.pos_of_ne_zeroₓ fun h => hdeg (h.symm ▸ WithBot.coe_zero)) }

end Polynomial

/-- Hilbert basis theorem: a polynomial ring over a noetherian ring is a noetherian ring. -/
protected theorem Polynomial.is_noetherian_ring [IsNoetherianRing R] : IsNoetherianRing (Polynomial R) :=
  is_noetherian_ring_iff.2
    ⟨fun I : Ideal (Polynomial R) =>
        let M :=
          WellFounded.min
            (is_noetherian_iff_well_founded.1
              (by 
                infer_instance))
            (Set.Range I.leading_coeff_nth) ⟨_, ⟨0, rfl⟩⟩
        have hm : M ∈ Set.Range I.leading_coeff_nth := WellFounded.min_mem _ _ _ 
        let ⟨N, HN⟩ := hm 
        let ⟨s, hs⟩ := I.is_fg_degree_le N 
        have hm2 : ∀ k, I.leading_coeff_nth k ≤ M :=
          fun k =>
            Or.cases_on (le_or_ltₓ k N) (fun h => HN ▸ I.leading_coeff_nth_mono h)
              fun h x hx =>
                Classical.by_contradiction$
                  fun hxm =>
                    have  : ¬M < I.leading_coeff_nth k :=
                      by 
                        refine' WellFounded.not_lt_min (well_founded_submodule_gt _ _) _ _ _ <;> exact ⟨k, rfl⟩
                    this ⟨HN ▸ I.leading_coeff_nth_mono (le_of_ltₓ h), fun H => hxm (H hx)⟩
        have hs2 : ∀ {x}, x ∈ I.degree_le N → x ∈ Ideal.span (↑s : Set (Polynomial R)) :=
          hs ▸
            fun x hx =>
              Submodule.span_induction hx (fun _ hx => Ideal.subset_span hx) (Ideal.zero_mem _)
                (fun _ _ => Ideal.add_mem _) fun c f hf => f.C_mul' c ▸ Ideal.mul_mem_left _ _ hf
        ⟨s,
          le_antisymmₓ
              (Ideal.span_le.2$
                fun x hx =>
                  have  : x ∈ I.degree_le N := hs ▸ Submodule.subset_span hx 
                  this.2)$
            by 
              have  : Submodule.span (Polynomial R) (↑s) = Ideal.span (↑s)
              ·
                rfl 
              rw [this]
              intro p hp 
              generalize hn : p.nat_degree = k 
              induction' k using Nat.strong_induction_onₓ with k ih generalizing p 
              cases le_or_ltₓ k N
              ·
                subst k 
                refine'
                  hs2
                    ⟨Polynomial.mem_degree_le.2 (le_transₓ Polynomial.degree_le_nat_degree$ WithBot.coe_le_coe.2 h), hp⟩
              ·
                have hp0 : p ≠ 0
                ·
                  rintro rfl 
                  cases hn 
                  exact Nat.not_lt_zeroₓ _ h 
                have  : (0 : R) ≠ 1
                ·
                  intro h 
                  apply hp0 
                  ext i 
                  refine' (mul_oneₓ _).symm.trans _ 
                  rw [←h, mul_zero]
                  rfl 
                have  : Nontrivial R := ⟨⟨0, 1, this⟩⟩
                have  : p.leading_coeff ∈ I.leading_coeff_nth N
                ·
                  rw [HN]
                  exact hm2 k ((I.mem_leading_coeff_nth _ _).2 ⟨_, hp, hn ▸ Polynomial.degree_le_nat_degree, rfl⟩)
                rw [I.mem_leading_coeff_nth] at this 
                rcases this with ⟨q, hq, hdq, hlqp⟩
                have hq0 : q ≠ 0
                ·
                  intro H 
                  rw [←Polynomial.leading_coeff_eq_zero] at H 
                  rw [hlqp, Polynomial.leading_coeff_eq_zero] at H 
                  exact hp0 H 
                have h1 : p.degree = (q*Polynomial.x^k - q.nat_degree).degree
                ·
                  rw [Polynomial.degree_mul', Polynomial.degree_X_pow]
                  rw [Polynomial.degree_eq_nat_degree hp0, Polynomial.degree_eq_nat_degree hq0]
                  rw [←WithBot.coe_add, add_tsub_cancel_of_le, hn]
                  ·
                    refine' le_transₓ (Polynomial.nat_degree_le_of_degree_le hdq) (le_of_ltₓ h)
                  rw [Polynomial.leading_coeff_X_pow, mul_oneₓ]
                  exact mt Polynomial.leading_coeff_eq_zero.1 hq0 
                have h2 : p.leading_coeff = (q*Polynomial.x^k - q.nat_degree).leadingCoeff
                ·
                  rw [←hlqp, Polynomial.leading_coeff_mul_X_pow]
                have  := Polynomial.degree_sub_lt h1 hp0 h2 
                rw [Polynomial.degree_eq_nat_degree hp0] at this 
                rw [←sub_add_cancel p (q*Polynomial.x^k - q.nat_degree)]
                refine' (Ideal.span (↑s)).add_mem _ ((Ideal.span (↑s)).mul_mem_right _ _)
                ·
                  byCases' hpq : (p - q*Polynomial.x^k - q.nat_degree) = 0
                  ·
                    rw [hpq]
                    exact Ideal.zero_mem _ 
                  refine' ih _ _ (I.sub_mem hp (I.mul_mem_right _ hq)) rfl 
                  rwa [Polynomial.degree_eq_nat_degree hpq, WithBot.coe_lt_coe, hn] at this 
                exact hs2 ⟨Polynomial.mem_degree_le.2 hdq, hq⟩⟩⟩

attribute [instance] Polynomial.is_noetherian_ring

namespace Polynomial

theorem exists_irreducible_of_degree_pos {R : Type u} [CommRingₓ R] [IsDomain R] [WfDvdMonoid R] {f : Polynomial R}
  (hf : 0 < f.degree) : ∃ g, Irreducible g ∧ g ∣ f :=
  WfDvdMonoid.exists_irreducible_factor (fun huf => ne_of_gtₓ hf$ degree_eq_zero_of_is_unit huf)
    fun hf0 => not_lt_of_lt hf$ hf0.symm ▸ (@degree_zero R _).symm ▸ WithBot.bot_lt_coe _

theorem exists_irreducible_of_nat_degree_pos {R : Type u} [CommRingₓ R] [IsDomain R] [WfDvdMonoid R] {f : Polynomial R}
  (hf : 0 < f.nat_degree) : ∃ g, Irreducible g ∧ g ∣ f :=
  exists_irreducible_of_degree_pos$
    by 
      contrapose! hf 
      exact nat_degree_le_of_degree_le hf

theorem exists_irreducible_of_nat_degree_ne_zero {R : Type u} [CommRingₓ R] [IsDomain R] [WfDvdMonoid R]
  {f : Polynomial R} (hf : f.nat_degree ≠ 0) : ∃ g, Irreducible g ∧ g ∣ f :=
  exists_irreducible_of_nat_degree_pos$ Nat.pos_of_ne_zeroₓ hf

theorem linear_independent_powers_iff_aeval (f : M →ₗ[R] M) (v : M) :
  (LinearIndependent R fun n : ℕ => (f^n) v) ↔ ∀ p : Polynomial R, aeval f p v = 0 → p = 0 :=
  by 
    rw [linear_independent_iff]
    simp only [Finsupp.total_apply, aeval_endomorphism, forall_iff_forall_finsupp, Sum, support, coeff,
      ←zero_to_finsupp]
    exact Iff.rfl

theorem disjoint_ker_aeval_of_coprime (f : M →ₗ[R] M) {p q : Polynomial R} (hpq : IsCoprime p q) :
  Disjoint (aeval f p).ker (aeval f q).ker :=
  by 
    intro v hv 
    rcases hpq with ⟨p', q', hpq'⟩
    simpa [LinearMap.mem_ker.1 (Submodule.mem_inf.1 hv).1, LinearMap.mem_ker.1 (Submodule.mem_inf.1 hv).2] using
      congr_argₓ (fun p : Polynomial R => aeval f p v) hpq'.symm

theorem sup_aeval_range_eq_top_of_coprime (f : M →ₗ[R] M) {p q : Polynomial R} (hpq : IsCoprime p q) :
  (aeval f p).range⊔(aeval f q).range = ⊤ :=
  by 
    rw [eq_top_iff]
    intro v hv 
    rw [Submodule.mem_sup]
    rcases hpq with ⟨p', q', hpq'⟩
    use aeval f (p*p') v 
    use
      LinearMap.mem_range.2
        ⟨aeval f p' v,
          by 
            simp only [LinearMap.mul_apply, aeval_mul]⟩
    use aeval f (q*q') v 
    use
      LinearMap.mem_range.2
        ⟨aeval f q' v,
          by 
            simp only [LinearMap.mul_apply, aeval_mul]⟩
    simpa only [mul_commₓ p p', mul_commₓ q q', aeval_one, aeval_add] using
      congr_argₓ (fun p : Polynomial R => aeval f p v) hpq'

theorem sup_ker_aeval_le_ker_aeval_mul {f : M →ₗ[R] M} {p q : Polynomial R} :
  (aeval f p).ker⊔(aeval f q).ker ≤ (aeval f (p*q)).ker :=
  by 
    intro v hv 
    rcases Submodule.mem_sup.1 hv with ⟨x, hx, y, hy, hxy⟩
    have h_eval_x : aeval f (p*q) x = 0
    ·
      rw [mul_commₓ, aeval_mul, LinearMap.mul_apply, LinearMap.mem_ker.1 hx, LinearMap.map_zero]
    have h_eval_y : aeval f (p*q) y = 0
    ·
      rw [aeval_mul, LinearMap.mul_apply, LinearMap.mem_ker.1 hy, LinearMap.map_zero]
    rw [LinearMap.mem_ker, ←hxy, LinearMap.map_add, h_eval_x, h_eval_y, add_zeroₓ]

theorem sup_ker_aeval_eq_ker_aeval_mul_of_coprime (f : M →ₗ[R] M) {p q : Polynomial R} (hpq : IsCoprime p q) :
  (aeval f p).ker⊔(aeval f q).ker = (aeval f (p*q)).ker :=
  by 
    apply le_antisymmₓ sup_ker_aeval_le_ker_aeval_mul 
    intro v hv 
    rw [Submodule.mem_sup]
    rcases hpq with ⟨p', q', hpq'⟩
    have h_eval₂_qpp' :=
      calc aeval f (q*p*p') v = aeval f (p'*p*q) v :=
        by 
          rw [mul_commₓ, mul_assocₓ, mul_commₓ, mul_assocₓ, mul_commₓ q p]
        _ = 0 :=
        by 
          rw [aeval_mul, LinearMap.mul_apply, LinearMap.mem_ker.1 hv, LinearMap.map_zero]
        
    have h_eval₂_pqq' :=
      calc aeval f (p*q*q') v = aeval f (q'*p*q) v :=
        by 
          rw [←mul_assocₓ, mul_commₓ]
        _ = 0 :=
        by 
          rw [aeval_mul, LinearMap.mul_apply, LinearMap.mem_ker.1 hv, LinearMap.map_zero]
        
    rw [aeval_mul] at h_eval₂_qpp' h_eval₂_pqq' 
    refine' ⟨aeval f (q*q') v, LinearMap.mem_ker.1 h_eval₂_pqq', aeval f (p*p') v, LinearMap.mem_ker.1 h_eval₂_qpp', _⟩
    rw [add_commₓ, mul_commₓ p p', mul_commₓ q q']
    simpa using congr_argₓ (fun p : Polynomial R => aeval f p v) hpq'

end Polynomial

namespace MvPolynomial

theorem is_noetherian_ring_fin_0 [IsNoetherianRing R] : IsNoetherianRing (MvPolynomial (Finₓ 0) R) :=
  is_noetherian_ring_of_ring_equiv R
    ((MvPolynomial.isEmptyRingEquiv R Pempty).symm.trans (rename_equiv R finZeroEquiv'.symm).toRingEquiv)

theorem is_noetherian_ring_fin [IsNoetherianRing R] : ∀ {n : ℕ}, IsNoetherianRing (MvPolynomial (Finₓ n) R)
| 0 => is_noetherian_ring_fin_0
| n+1 =>
  @is_noetherian_ring_of_ring_equiv (Polynomial (MvPolynomial (Finₓ n) R)) _ _ _
    (MvPolynomial.finSuccEquiv _ n).toRingEquiv.symm
    (@Polynomial.is_noetherian_ring (MvPolynomial (Finₓ n) R) _ is_noetherian_ring_fin)

/-- The multivariate polynomial ring in finitely many variables over a noetherian ring
is itself a noetherian ring. -/
instance IsNoetherianRing [Fintype σ] [IsNoetherianRing R] : IsNoetherianRing (MvPolynomial σ R) :=
  @is_noetherian_ring_of_ring_equiv (MvPolynomial (Finₓ (Fintype.card σ)) R) _ _ _
    (rename_equiv R (Fintype.equivFin σ).symm).toRingEquiv is_noetherian_ring_fin

theorem is_domain_fin_zero (R : Type u) [CommRingₓ R] [IsDomain R] : IsDomain (MvPolynomial (Finₓ 0) R) :=
  RingEquiv.is_domain R ((rename_equiv R finZeroEquiv').toRingEquiv.trans (MvPolynomial.isEmptyRingEquiv R Pempty))

/-- Auxiliary lemma:
Multivariate polynomials over an integral domain
with variables indexed by `fin n` form an integral domain.
This fact is proven inductively,
and then used to prove the general case without any finiteness hypotheses.
See `mv_polynomial.is_domain` for the general case. -/
theorem is_domain_fin (R : Type u) [CommRingₓ R] [IsDomain R] : ∀ n : ℕ, IsDomain (MvPolynomial (Finₓ n) R)
| 0 => is_domain_fin_zero R
| n+1 =>
  by 
    have  := is_domain_fin n 
    exact RingEquiv.is_domain (Polynomial (MvPolynomial (Finₓ n) R)) (MvPolynomial.finSuccEquiv _ n).toRingEquiv

/-- Auxiliary definition:
Multivariate polynomials in finitely many variables over an integral domain form an integral domain.
This fact is proven by transport of structure from the `mv_polynomial.is_domain_fin`,
and then used to prove the general case without finiteness hypotheses.
See `mv_polynomial.is_domain` for the general case. -/
theorem is_domain_fintype (R : Type u) (σ : Type v) [CommRingₓ R] [Fintype σ] [IsDomain R] :
  IsDomain (MvPolynomial σ R) :=
  @RingEquiv.is_domain _ (MvPolynomial (Finₓ$ Fintype.card σ) R) _ _ (MvPolynomial.is_domain_fin _ _)
    (rename_equiv R (Fintype.equivFin σ)).toRingEquiv

protected theorem eq_zero_or_eq_zero_of_mul_eq_zero {R : Type u} [CommRingₓ R] [IsDomain R] {σ : Type v}
  (p q : MvPolynomial σ R) (h : (p*q) = 0) : p = 0 ∨ q = 0 :=
  by 
    obtain ⟨s, p, rfl⟩ := exists_finset_rename p 
    obtain ⟨t, q, rfl⟩ := exists_finset_rename q 
    have  :
      (rename (Subtype.map id (Finset.subset_union_left s t) : { x // x ∈ s } → { x // x ∈ s ∪ t })
            p*rename (Subtype.map id (Finset.subset_union_right s t) : { x // x ∈ t } → { x // x ∈ s ∪ t }) q) =
        0
    ·
      apply rename_injective _ Subtype.val_injective 
      simpa using h 
    let this' := MvPolynomial.is_domain_fintype R { x // x ∈ s ∪ t }
    rw [mul_eq_zero] at this 
    cases this <;> [left, right]
    all_goals 
      simpa using congr_argₓ (rename Subtype.val) this

/-- The multivariate polynomial ring over an integral domain is an integral domain. -/
instance {R : Type u} {σ : Type v} [CommRingₓ R] [IsDomain R] : IsDomain (MvPolynomial σ R) :=
  { (by 
      infer_instance :
    CommRingₓ (MvPolynomial σ R)) with
    eq_zero_or_eq_zero_of_mul_eq_zero := MvPolynomial.eq_zero_or_eq_zero_of_mul_eq_zero,
    exists_pair_ne :=
      ⟨0, 1,
        fun H =>
          by 
            have  :
              eval₂ (RingHom.id _) (fun s => (0 : R)) (0 : MvPolynomial σ R) =
                eval₂ (RingHom.id _) (fun s => (0 : R)) (1 : MvPolynomial σ R)
            ·
              congr 
              exact H 
            simpa⟩ }

theorem map_mv_polynomial_eq_eval₂ {S : Type _} [CommRingₓ S] [Fintype σ] (ϕ : MvPolynomial σ R →+* S)
  (p : MvPolynomial σ R) : ϕ p = MvPolynomial.eval₂ (ϕ.comp MvPolynomial.c) (fun s => ϕ (MvPolynomial.x s)) p :=
  by 
    refine' trans (congr_argₓ ϕ (MvPolynomial.as_sum p)) _ 
    rw [MvPolynomial.eval₂_eq', ϕ.map_sum]
    congr 
    ext 
    simp only [monomial_eq, ϕ.map_pow, ϕ.map_prod, ϕ.comp_apply, ϕ.map_mul, Finsupp.prod_pow]

theorem quotient_map_C_eq_zero {I : Ideal R} {i : R} (hi : i ∈ I) :
  (Ideal.Quotient.mk (Ideal.map C I : Ideal (MvPolynomial σ R))).comp C i = 0 :=
  by 
    simp only [Function.comp_app, RingHom.coe_comp, Ideal.Quotient.eq_zero_iff_mem]
    exact Ideal.mem_map_of_mem _ hi

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (m «expr ∈ » p.support)
/-- If every coefficient of a polynomial is in an ideal `I`, then so is the polynomial itself,
multivariate version. -/
theorem mem_ideal_of_coeff_mem_ideal (I : Ideal (MvPolynomial σ R)) (p : MvPolynomial σ R)
  (hcoe : ∀ m : σ →₀ ℕ, p.coeff m ∈ I.comap C) : p ∈ I :=
  by 
    rw [as_sum p]
    suffices  : ∀ m _ : m ∈ p.support, monomial m (MvPolynomial.coeff m p) ∈ I
    ·
      exact Submodule.sum_mem I this 
    intro m hm 
    rw [←mul_oneₓ (coeff m p), ←C_mul_monomial]
    suffices  : C (coeff m p) ∈ I
    ·
      exact I.mul_mem_right (monomial m 1) this 
    simpa [Ideal.mem_comap] using hcoe m

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (m «expr ∈ » f.support)
/-- The push-forward of an ideal `I` of `R` to `mv_polynomial σ R` via inclusion
 is exactly the set of polynomials whose coefficients are in `I` -/
theorem mem_map_C_iff {I : Ideal R} {f : MvPolynomial σ R} :
  f ∈ (Ideal.map C I : Ideal (MvPolynomial σ R)) ↔ ∀ m : σ →₀ ℕ, f.coeff m ∈ I :=
  by 
    constructor
    ·
      intro hf 
      apply Submodule.span_induction hf
      ·
        intro f hf n 
        cases' (Set.mem_image _ _ _).mp hf with x hx 
        rw [←hx.right, coeff_C]
        byCases' n = 0
        ·
          simpa [h] using hx.left
        ·
          simp [Ne.symm h]
      ·
        simp 
      ·
        exact
          fun f g hf hg n =>
            by 
              simp [I.add_mem (hf n) (hg n)]
      ·
        refine' fun f g hg n => _ 
        rw [smul_eq_mul, coeff_mul]
        exact I.sum_mem fun c hc => I.smul_mem (f.coeff c.fst) (hg c.snd)
    ·
      intro hf 
      rw [as_sum f]
      suffices  : ∀ m _ : m ∈ f.support, monomial m (coeff m f) ∈ (Ideal.map C I : Ideal (MvPolynomial σ R))
      ·
        exact Submodule.sum_mem _ this 
      intro m hm 
      rw [←mul_oneₓ (coeff m f), ←C_mul_monomial]
      suffices  : C (coeff m f) ∈ (Ideal.map C I : Ideal (MvPolynomial σ R))
      ·
        exact Ideal.mul_mem_right _ _ this 
      apply Ideal.mem_map_of_mem _ 
      exact hf m

theorem ker_map (f : R →+* S) : (map f : MvPolynomial σ R →+* MvPolynomial σ S).ker = f.ker.map C :=
  by 
    ext 
    rw [MvPolynomial.mem_map_C_iff, RingHom.mem_ker, MvPolynomial.ext_iff]
    simpRw [coeff_map, coeff_zero, RingHom.mem_ker]

theorem eval₂_C_mk_eq_zero {I : Ideal R} {a : MvPolynomial σ R} (ha : a ∈ (Ideal.map C I : Ideal (MvPolynomial σ R))) :
  eval₂_hom (C.comp (Ideal.Quotient.mk I)) X a = 0 :=
  by 
    rw [as_sum a]
    rw [coe_eval₂_hom, eval₂_sum]
    refine' Finset.sum_eq_zero fun n hn => _ 
    simp only [eval₂_monomial, Function.comp_app, RingHom.coe_comp]
    refine' mul_eq_zero_of_left _ _ 
    suffices  : coeff n a ∈ I
    ·
      rw [←@Ideal.mk_ker R _ I, RingHom.mem_ker] at this 
      simp only [this, C_0]
    exact mem_map_C_iff.1 ha n

/-- If `I` is an ideal of `R`, then the ring `mv_polynomial σ I.quotient` is isomorphic as an
`R`-algebra to the quotient of `mv_polynomial σ R` by the ideal generated by `I`. -/
def quotient_equiv_quotient_mv_polynomial (I : Ideal R) :
  MvPolynomial σ (R ⧸ I) ≃ₐ[R] MvPolynomial σ R ⧸ (Ideal.map C I : Ideal (MvPolynomial σ R)) :=
  { toFun :=
      eval₂_hom
        (Ideal.Quotient.lift I ((Ideal.Quotient.mk (Ideal.map C I : Ideal (MvPolynomial σ R))).comp C)
          fun i hi => quotient_map_C_eq_zero hi)
        fun i => Ideal.Quotient.mk (Ideal.map C I : Ideal (MvPolynomial σ R)) (X i),
    invFun :=
      Ideal.Quotient.lift (Ideal.map C I : Ideal (MvPolynomial σ R)) (eval₂_hom (C.comp (Ideal.Quotient.mk I)) X)
        fun a ha => eval₂_C_mk_eq_zero ha,
    map_mul' := RingHom.map_mul _, map_add' := RingHom.map_add _,
    left_inv :=
      by 
        intro f 
        apply induction_on f
        ·
          rintro ⟨r⟩
          rw [coe_eval₂_hom, eval₂_C]
          simp only [eval₂_hom_eq_bind₂, Submodule.Quotient.quot_mk_eq_mk, Ideal.Quotient.lift_mk,
            Ideal.Quotient.mk_eq_mk, bind₂_C_right, RingHom.coe_comp]
        ·
          simpIntro p q hp hq only [RingHom.map_add, MvPolynomial.coe_eval₂_hom, coe_eval₂_hom, MvPolynomial.eval₂_add,
            MvPolynomial.eval₂_hom_eq_bind₂, eval₂_hom_eq_bind₂]
          rw [hp, hq]
        ·
          simpIntro p i hp only [eval₂_hom_eq_bind₂, coe_eval₂_hom]
          simp only [hp, eval₂_hom_eq_bind₂, coe_eval₂_hom, Ideal.Quotient.lift_mk, bind₂_X_right, eval₂_mul,
            RingHom.map_mul, eval₂_X],
    right_inv :=
      by 
        rintro ⟨f⟩
        apply induction_on f
        ·
          intro r 
          simp only [Submodule.Quotient.quot_mk_eq_mk, Ideal.Quotient.lift_mk, Ideal.Quotient.mk_eq_mk,
            RingHom.coe_comp, eval₂_hom_C]
        ·
          simpIntro p q hp hq only [eval₂_hom_eq_bind₂, Submodule.Quotient.quot_mk_eq_mk, eval₂_add, RingHom.map_add,
            coe_eval₂_hom, Ideal.Quotient.lift_mk, Ideal.Quotient.mk_eq_mk]
          rw [hp, hq]
        ·
          simpIntro p i hp only [eval₂_hom_eq_bind₂, Submodule.Quotient.quot_mk_eq_mk, coe_eval₂_hom,
            Ideal.Quotient.lift_mk, Ideal.Quotient.mk_eq_mk, bind₂_X_right, eval₂_mul, RingHom.map_mul, eval₂_X]
          simp only [hp],
    commutes' := fun r => eval₂_hom_C _ _ (Ideal.Quotient.mk I r) }

end MvPolynomial

namespace Polynomial

open UniqueFactorizationMonoid

variable {D : Type u} [CommRingₓ D] [IsDomain D] [UniqueFactorizationMonoid D]

instance (priority := 100) UniqueFactorizationMonoid : UniqueFactorizationMonoid (Polynomial D) :=
  by 
    have  := arbitraryₓ (NormalizationMonoid D)
    have  := to_normalized_gcd_monoid D 
    exact ufm_of_gcd_of_wf_dvd_monoid

end Polynomial

