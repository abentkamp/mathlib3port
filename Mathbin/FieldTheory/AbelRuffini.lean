import Mathbin.GroupTheory.Solvable 
import Mathbin.FieldTheory.PolynomialGaloisGroup 
import Mathbin.RingTheory.RootsOfUnity

/-!
# The Abel-Ruffini Theorem

This file proves one direction of the Abel-Ruffini theorem, namely that if an element is solvable
by radicals, then its minimal polynomial has solvable Galois group.

## Main definitions

* `solvable_by_rad F E` : the intermediate field of solvable-by-radicals elements

## Main results

* the Abel-Ruffini Theorem `solvable_by_rad.is_solvable'` : An irreducible polynomial with a root
that is solvable by radicals has a solvable Galois group.
-/


noncomputable section 

open_locale Classical

open Polynomial IntermediateField

section AbelRuffini

variable {F : Type _} [Field F] {E : Type _} [Field E] [Algebra F E]

theorem gal_zero_is_solvable : IsSolvable (0 : Polynomial F).Gal :=
  by 
    infer_instance

theorem gal_one_is_solvable : IsSolvable (1 : Polynomial F).Gal :=
  by 
    infer_instance

theorem gal_C_is_solvable (x : F) : IsSolvable (C x).Gal :=
  by 
    infer_instance

theorem gal_X_is_solvable : IsSolvable (X : Polynomial F).Gal :=
  by 
    infer_instance

theorem gal_X_sub_C_is_solvable (x : F) : IsSolvable (X - C x).Gal :=
  by 
    infer_instance

theorem gal_X_pow_is_solvable (n : ℕ) : IsSolvable (X^n : Polynomial F).Gal :=
  by 
    infer_instance

theorem gal_mul_is_solvable {p q : Polynomial F} (hp : IsSolvable p.gal) (hq : IsSolvable q.gal) :
  IsSolvable (p*q).Gal :=
  solvable_of_solvable_injective (gal.restrict_prod_injective p q)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p «expr ∈ » s)
theorem gal_prod_is_solvable {s : Multiset (Polynomial F)} (hs : ∀ p _ : p ∈ s, IsSolvable (gal p)) :
  IsSolvable s.prod.gal :=
  by 
    apply Multiset.induction_on' s
    ·
      exact gal_one_is_solvable
    ·
      intro p t hps hts ht 
      rw [Multiset.insert_eq_cons, Multiset.prod_cons]
      exact gal_mul_is_solvable (hs p hps) ht

theorem gal_is_solvable_of_splits {p q : Polynomial F} (hpq : Fact (p.splits (algebraMap F q.splitting_field)))
  (hq : IsSolvable q.gal) : IsSolvable p.gal :=
  by 
    have  : IsSolvable (q.splitting_field ≃ₐ[F] q.splitting_field) := hq 
    exact solvable_of_surjective (AlgEquiv.restrict_normal_hom_surjective q.splitting_field)

theorem gal_is_solvable_tower (p q : Polynomial F) (hpq : p.splits (algebraMap F q.splitting_field))
  (hp : IsSolvable p.gal) (hq : IsSolvable (q.map (algebraMap F p.splitting_field)).Gal) : IsSolvable q.gal :=
  by 
    let K := p.splitting_field 
    let L := q.splitting_field 
    have  : Fact (p.splits (algebraMap F L)) := ⟨hpq⟩
    let ϕ : (L ≃ₐ[K] L) ≃* (q.map (algebraMap F K)).Gal :=
      (is_splitting_field.alg_equiv L (q.map (algebraMap F K))).autCongr 
    have ϕ_inj : Function.Injective ϕ.to_monoid_hom := ϕ.injective 
    have  : IsSolvable (K ≃ₐ[F] K) := hp 
    have  : IsSolvable (L ≃ₐ[K] L) := solvable_of_solvable_injective ϕ_inj 
    exact is_solvable_of_is_scalar_tower F p.splitting_field q.splitting_field

section GalXPowSubC

theorem gal_X_pow_sub_one_is_solvable (n : ℕ) : IsSolvable ((X^n) - 1 : Polynomial F).Gal :=
  by 
    byCases' hn : n = 0
    ·
      rw [hn, pow_zeroₓ, sub_self]
      exact gal_zero_is_solvable 
    have hn' : 0 < n := pos_iff_ne_zero.mpr hn 
    have hn'' : ((X^n) - 1 : Polynomial F) ≠ 0 :=
      fun h => one_ne_zero ((leading_coeff_X_pow_sub_one hn').symm.trans (congr_argₓ leading_coeff h))
    apply is_solvable_of_comm 
    intro σ τ 
    ext a ha 
    rw [mem_root_set hn'', AlgHom.map_sub, aeval_X_pow, aeval_one, sub_eq_zero] at ha 
    have key : ∀ σ : ((X^n) - 1 : Polynomial F).Gal, ∃ m : ℕ, σ a = (a^m)
    ·
      intro σ 
      obtain ⟨m, hm⟩ :=
        σ.to_alg_hom.to_ring_hom.map_root_of_unity_eq_pow_self
          ⟨IsUnit.unit (is_unit_of_pow_eq_one a n ha hn'),
            by 
              ext 
              rwa [Units.coe_pow, IsUnit.unit_spec, Subtype.coe_mk n hn']⟩
      use m 
      convert hm 
      all_goals 
        exact (IsUnit.unit_spec _).symm 
    obtain ⟨c, hc⟩ := key σ 
    obtain ⟨d, hd⟩ := key τ 
    rw [σ.mul_apply, τ.mul_apply, hc, τ.map_pow, hd, σ.map_pow, hc, ←pow_mulₓ, pow_mul']

theorem gal_X_pow_sub_C_is_solvable_aux (n : ℕ) (a : F) (h : ((X^n) - 1 : Polynomial F).Splits (RingHom.id F)) :
  IsSolvable ((X^n) - C a).Gal :=
  by 
    byCases' ha : a = 0
    ·
      rw [ha, C_0, sub_zero]
      exact gal_X_pow_is_solvable n 
    have ha' : algebraMap F ((X^n) - C a).SplittingField a ≠ 0 :=
      mt ((RingHom.injective_iff _).mp (RingHom.injective _) a) ha 
    byCases' hn : n = 0
    ·
      rw [hn, pow_zeroₓ, ←C_1, ←C_sub]
      exact gal_C_is_solvable (1 - a)
    have hn' : 0 < n := pos_iff_ne_zero.mpr hn 
    have hn'' : (X^n) - C a ≠ 0 :=
      fun h => one_ne_zero ((leading_coeff_X_pow_sub_C hn').symm.trans (congr_argₓ leading_coeff h))
    have hn''' : ((X^n) - 1 : Polynomial F) ≠ 0 :=
      fun h => one_ne_zero ((leading_coeff_X_pow_sub_one hn').symm.trans (congr_argₓ leading_coeff h))
    have mem_range : ∀ {c}, (c^n) = 1 → ∃ d, algebraMap F ((X^n) - C a).SplittingField d = c :=
      fun c hc =>
        ring_hom.mem_range.mp
          (minpoly.mem_range_of_degree_eq_one F c
            (Or.resolve_left h hn''' (minpoly.irreducible ((splitting_field.normal ((X^n) - C a)).IsIntegral c))
              (minpoly.dvd F c
                (by 
                  rwa [map_id, AlgHom.map_sub, sub_eq_zero, aeval_X_pow, aeval_one]))))
    apply is_solvable_of_comm 
    intro σ τ 
    ext b hb 
    rw [mem_root_set hn'', AlgHom.map_sub, aeval_X_pow, aeval_C, sub_eq_zero] at hb 
    have hb' : b ≠ 0
    ·
      intro hb' 
      rw [hb', zero_pow hn'] at hb 
      exact ha' hb.symm 
    have key : ∀ σ : ((X^n) - C a).Gal, ∃ c, σ b = b*algebraMap F _ c
    ·
      intro σ 
      have key : (σ b / b^n) = 1 :=
        by 
          rw [div_pow, ←σ.map_pow, hb, σ.commutes, div_self ha']
      obtain ⟨c, hc⟩ := mem_range key 
      use c 
      rw [hc, mul_div_cancel' (σ b) hb']
    obtain ⟨c, hc⟩ := key σ 
    obtain ⟨d, hd⟩ := key τ 
    rw [σ.mul_apply, τ.mul_apply, hc, τ.map_mul, τ.commutes, hd, σ.map_mul, σ.commutes, hc]
    rw [mul_assocₓ, mul_assocₓ, mul_right_inj' hb', mul_commₓ]

theorem splits_X_pow_sub_one_of_X_pow_sub_C {F : Type _} [Field F] {E : Type _} [Field E] (i : F →+* E) (n : ℕ) {a : F}
  (ha : a ≠ 0) (h : ((X^n) - C a).Splits i) : ((X^n) - 1).Splits i :=
  by 
    have ha' : i a ≠ 0 := mt (i.injective_iff.mp i.injective a) ha 
    byCases' hn : n = 0
    ·
      rw [hn, pow_zeroₓ, sub_self]
      exact splits_zero i 
    have hn' : 0 < n := pos_iff_ne_zero.mpr hn 
    have hn'' : ((X^n) - C a).degree ≠ 0 := ne_of_eq_of_ne (degree_X_pow_sub_C hn' a) (mt with_bot.coe_eq_coe.mp hn)
    obtain ⟨b, hb⟩ := exists_root_of_splits i h hn'' 
    rw [eval₂_sub, eval₂_X_pow, eval₂_C, sub_eq_zero] at hb 
    have hb' : b ≠ 0
    ·
      intro hb' 
      rw [hb', zero_pow hn'] at hb 
      exact ha' hb.symm 
    let s := (((X^n) - C a).map i).roots 
    have hs : _ = _*(s.map _).Prod := eq_prod_roots_of_splits h 
    rw [leading_coeff_X_pow_sub_C hn', RingHom.map_one, C_1, one_mulₓ] at hs 
    have hs' : s.card = n := (nat_degree_eq_card_roots h).symm.trans nat_degree_X_pow_sub_C 
    apply @splits_of_exists_multiset F E _ _ i ((X^n) - 1) (s.map fun c : E => c / b)
    rw [leading_coeff_X_pow_sub_one hn', RingHom.map_one, C_1, one_mulₓ, Multiset.map_map]
    have C_mul_C : (C (i (a⁻¹))*C (i a)) = 1
    ·
      rw [←C_mul, ←i.map_mul, inv_mul_cancel ha, i.map_one, C_1]
    have key1 : ((X^n) - 1).map i = C (i (a⁻¹))*(((X^n) - C a).map i).comp (C b*X)
    ·
      rw [Polynomial.map_sub, Polynomial.map_sub, Polynomial.map_pow, map_X, map_C, Polynomial.map_one, sub_comp,
        pow_comp, X_comp, C_comp, mul_powₓ, ←C_pow, hb, mul_sub, ←mul_assocₓ, C_mul_C, one_mulₓ]
    have key2 : ((fun q : Polynomial E => q.comp (C b*X)) ∘ fun c : E => X - C c) = fun c : E => C b*X - C (c / b)
    ·
      ext1 c 
      change (X - C c).comp (C b*X) = C b*X - C (c / b)
      rw [sub_comp, X_comp, C_comp, mul_sub, ←C_mul, mul_div_cancel' c hb']
    rw [key1, hs, prod_comp, Multiset.map_map, key2, Multiset.prod_map_mul, Multiset.map_const, Multiset.prod_repeat,
      hs', ←C_pow, hb, ←mul_assocₓ, C_mul_C, one_mulₓ]
    all_goals 
      exact Field.to_nontrivial F

theorem gal_X_pow_sub_C_is_solvable (n : ℕ) (x : F) : IsSolvable ((X^n) - C x).Gal :=
  by 
    byCases' hx : x = 0
    ·
      rw [hx, C_0, sub_zero]
      exact gal_X_pow_is_solvable n 
    apply gal_is_solvable_tower ((X^n) - 1) ((X^n) - C x)
    ·
      exact splits_X_pow_sub_one_of_X_pow_sub_C _ n hx (splitting_field.splits _)
    ·
      exact gal_X_pow_sub_one_is_solvable n
    ·
      rw [Polynomial.map_sub, Polynomial.map_pow, map_X, map_C]
      apply gal_X_pow_sub_C_is_solvable_aux 
      have key := splitting_field.splits ((X^n) - 1 : Polynomial F)
      rwa [←splits_id_iff_splits, Polynomial.map_sub, Polynomial.map_pow, map_X, Polynomial.map_one] at key

end GalXPowSubC

variable (F)

/-- Inductive definition of solvable by radicals -/
inductive IsSolvableByRad : E → Prop
  | base (a : F) : IsSolvableByRad (algebraMap F E a)
  | add (a b : E) : IsSolvableByRad a → IsSolvableByRad b → IsSolvableByRad (a+b)
  | neg (α : E) : IsSolvableByRad α → IsSolvableByRad (-α)
  | mul (α β : E) : IsSolvableByRad α → IsSolvableByRad β → IsSolvableByRad (α*β)
  | inv (α : E) : IsSolvableByRad α → IsSolvableByRad (α⁻¹)
  | rad (α : E) (n : ℕ) (hn : n ≠ 0) : IsSolvableByRad (α^n) → IsSolvableByRad α

variable (E)

/-- The intermediate field of solvable-by-radicals elements -/
def solvableByRad : IntermediateField F E :=
  { Carrier := IsSolvableByRad F,
    zero_mem' :=
      by 
        convert IsSolvableByRad.base (0 : F)
        rw [RingHom.map_zero],
    add_mem' := IsSolvableByRad.add, neg_mem' := IsSolvableByRad.neg,
    one_mem' :=
      by 
        convert IsSolvableByRad.base (1 : F)
        rw [RingHom.map_one],
    mul_mem' := IsSolvableByRad.mul, inv_mem' := IsSolvableByRad.inv, algebra_map_mem' := IsSolvableByRad.base }

namespace solvableByRad

variable {F} {E} {α : E}

theorem induction (P : solvableByRad F E → Prop) (base : ∀ α : F, P (algebraMap F (solvableByRad F E) α))
  (add : ∀ α β : solvableByRad F E, P α → P β → P (α+β)) (neg : ∀ α : solvableByRad F E, P α → P (-α))
  (mul : ∀ α β : solvableByRad F E, P α → P β → P (α*β)) (inv : ∀ α : solvableByRad F E, P α → P (α⁻¹))
  (rad : ∀ α : solvableByRad F E, ∀ n : ℕ, n ≠ 0 → P (α^n) → P α) (α : solvableByRad F E) : P α :=
  by 
    revert α 
    suffices  : ∀ α : E, IsSolvableByRad F α → ∃ β : solvableByRad F E, ↑β = α ∧ P β
    ·
      intro α 
      obtain ⟨α₀, hα₀, Pα⟩ := this α (Subtype.mem α)
      convert Pα 
      exact Subtype.ext hα₀.symm 
    apply IsSolvableByRad.ndrec
    ·
      exact fun α => ⟨algebraMap F (solvableByRad F E) α, rfl, base α⟩
    ·
      intro α β hα hβ Pα Pβ 
      obtain ⟨⟨α₀, hα₀, Pα⟩, β₀, hβ₀, Pβ⟩ := Pα, Pβ 
      exact
        ⟨α₀+β₀,
          by 
            rw [←hα₀, ←hβ₀]
            rfl,
          add α₀ β₀ Pα Pβ⟩
    ·
      intro α hα Pα 
      obtain ⟨α₀, hα₀, Pα⟩ := Pα 
      exact
        ⟨-α₀,
          by 
            rw [←hα₀]
            rfl,
          neg α₀ Pα⟩
    ·
      intro α β hα hβ Pα Pβ 
      obtain ⟨⟨α₀, hα₀, Pα⟩, β₀, hβ₀, Pβ⟩ := Pα, Pβ 
      exact
        ⟨α₀*β₀,
          by 
            rw [←hα₀, ←hβ₀]
            rfl,
          mul α₀ β₀ Pα Pβ⟩
    ·
      intro α hα Pα 
      obtain ⟨α₀, hα₀, Pα⟩ := Pα 
      exact
        ⟨α₀⁻¹,
          by 
            rw [←hα₀]
            rfl,
          inv α₀ Pα⟩
    ·
      intro α n hn hα Pα 
      obtain ⟨α₀, hα₀, Pα⟩ := Pα 
      refine' ⟨⟨α, IsSolvableByRad.rad α n hn hα⟩, rfl, rad _ n hn _⟩
      convert Pα 
      exact Subtype.ext (Eq.trans ((solvableByRad F E).coe_pow _ n) hα₀.symm)

theorem IsIntegral (α : solvableByRad F E) : IsIntegral F α :=
  by 
    revert α 
    apply solvableByRad.induction
    ·
      exact fun _ => is_integral_algebra_map
    ·
      exact fun _ _ => is_integral_add
    ·
      exact fun _ => is_integral_neg
    ·
      exact fun _ _ => is_integral_mul
    ·
      exact
        fun α hα =>
          Subalgebra.inv_mem_of_algebraic (integralClosure F (solvableByRad F E))
            (show IsAlgebraic F (↑(⟨α, hα⟩ : integralClosure F (solvableByRad F E)))by 
              exact (is_algebraic_iff_is_integral F).mpr hα)
    ·
      intro α n hn hα 
      obtain ⟨p, h1, h2⟩ := (is_algebraic_iff_is_integral F).mpr hα 
      refine'
        (is_algebraic_iff_is_integral F).mp
          ⟨p.comp (X^n),
            ⟨fun h => h1 (leading_coeff_eq_zero.mp _),
              by 
                rw [aeval_comp, aeval_X_pow, h2]⟩⟩
      rwa [←leading_coeff_eq_zero, leading_coeff_comp, leading_coeff_X_pow, one_pow, mul_oneₓ] at h 
      rwa [nat_degree_X_pow]

/-- The statement to be proved inductively -/
def P (α : solvableByRad F E) : Prop :=
  IsSolvable (minpoly F α).Gal

/-- An auxiliary induction lemma, which is generalized by `solvable_by_rad.is_solvable`. -/
theorem induction3 {α : solvableByRad F E} {n : ℕ} (hn : n ≠ 0) (hα : P (α^n)) : P α :=
  by 
    let p := minpoly F (α^n)
    have hp : p.comp (X^n) ≠ 0
    ·
      intro h 
      cases' comp_eq_zero_iff.mp h with h' h'
      ·
        exact minpoly.ne_zero (IsIntegral (α^n)) h'
      ·
        exact
          hn
            (by 
              rw [←nat_degree_C _, ←h'.2, nat_degree_X_pow])
    apply gal_is_solvable_of_splits
    ·
      exact
        ⟨splits_of_splits_of_dvd _ hp (splitting_field.splits (p.comp (X^n)))
            (minpoly.dvd F α
              (by 
                rw [aeval_comp, aeval_X_pow, minpoly.aeval]))⟩
    ·
      refine' gal_is_solvable_tower p (p.comp (X^n)) _ hα _
      ·
        exact
          gal.splits_in_splitting_field_of_comp _ _
            (by 
              rwa [nat_degree_X_pow])
      ·
        obtain ⟨s, hs⟩ := exists_multiset_of_splits _ (splitting_field.splits p)
        rw [map_comp, Polynomial.map_pow, map_X, hs, mul_comp, C_comp]
        apply gal_mul_is_solvable (gal_C_is_solvable _)
        rw [prod_comp]
        apply gal_prod_is_solvable 
        intro q hq 
        rw [Multiset.mem_map] at hq 
        obtain ⟨q, hq, rfl⟩ := hq 
        rw [Multiset.mem_map] at hq 
        obtain ⟨q, hq, rfl⟩ := hq 
        rw [sub_comp, X_comp, C_comp]
        exact gal_X_pow_sub_C_is_solvable n q

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- An auxiliary induction lemma, which is generalized by `solvable_by_rad.is_solvable`. -/
theorem induction2 {α β γ : solvableByRad F E}
  (hγ : γ ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
  (hα : P α) (hβ : P β) : P γ :=
  by 
    let p := minpoly F α 
    let q := minpoly F β 
    have hpq :=
      Polynomial.splits_of_splits_mul _ (mul_ne_zero (minpoly.ne_zero (IsIntegral α)) (minpoly.ne_zero (IsIntegral β)))
        (splitting_field.splits (p*q))
    let f :
      «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" →ₐ[F]
        (p*q).SplittingField :=
      Classical.choice
        (alg_hom_mk_adjoin_splits
          (by 
            intro x hx 
            cases hx 
            rw [hx]
            exact ⟨IsIntegral α, hpq.1⟩
            cases hx 
            exact ⟨IsIntegral β, hpq.2⟩))
    have key : minpoly F γ = minpoly F (f ⟨γ, hγ⟩) :=
      minpoly.eq_of_irreducible_of_monic (minpoly.irreducible (IsIntegral γ))
        (by 
          suffices  :
            aeval
                (⟨γ, hγ⟩ :
                «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
                (minpoly F γ) =
              0
          ·
            rw [aeval_alg_hom_apply, this, AlgHom.map_zero]
          apply
            (algebraMap
                («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
                (solvableByRad F E)).Injective
              
          rw [RingHom.map_zero, IsScalarTower.algebra_map_aeval]
          exact minpoly.aeval F γ)
        (minpoly.monic (IsIntegral γ))
    rw [P, key]
    exact gal_is_solvable_of_splits ⟨Normal.splits (splitting_field.normal _) _⟩ (gal_mul_is_solvable hα hβ)

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- An auxiliary induction lemma, which is generalized by `solvable_by_rad.is_solvable`. -/
theorem induction1 {α β : solvableByRad F E}
  (hβ : β ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
  (hα : P α) : P β :=
  induction2 (adjoin.mono F _ _ (ge_of_eq (Set.pair_eq_singleton α)) hβ) hα hα

theorem IsSolvable (α : solvableByRad F E) : IsSolvable (minpoly F α).Gal :=
  by 
    revert α 
    apply solvableByRad.induction
    ·
      exact
        fun α =>
          by 
            rw [minpoly.eq_X_sub_C]
            exact gal_X_sub_C_is_solvable α
    ·
      exact
        fun α β =>
          induction2
            (add_mem _ (subset_adjoin F _ (Set.mem_insert α _))
              (subset_adjoin F _ (Set.mem_insert_of_mem α (Set.mem_singleton β))))
    ·
      exact fun α => induction1 (neg_mem _ (mem_adjoin_simple_self F α))
    ·
      exact
        fun α β =>
          induction2
            (mul_mem _ (subset_adjoin F _ (Set.mem_insert α _))
              (subset_adjoin F _ (Set.mem_insert_of_mem α (Set.mem_singleton β))))
    ·
      exact fun α => induction1 (inv_mem _ (mem_adjoin_simple_self F α))
    ·
      exact fun α n => induction3

/-- **Abel-Ruffini Theorem** (one direction): An irreducible polynomial with an
`is_solvable_by_rad` root has solvable Galois group -/
theorem is_solvable' {α : E} {q : Polynomial F} (q_irred : Irreducible q) (q_aeval : aeval α q = 0)
  (hα : IsSolvableByRad F α) : _root_.is_solvable q.gal :=
  by 
    have  : _root_.is_solvable (q*C (q.leading_coeff⁻¹)).Gal
    ·
      rw [minpoly.eq_of_irreducible q_irred q_aeval,
        ←show minpoly F (⟨α, hα⟩ : solvableByRad F E) = minpoly F α from
          minpoly.eq_of_algebra_map_eq (RingHom.injective _) (IsIntegral ⟨α, hα⟩) rfl]
      exact IsSolvable ⟨α, hα⟩
    refine' solvable_of_surjective (gal.restrict_dvd_surjective ⟨C (q.leading_coeff⁻¹), rfl⟩ _)
    rw [mul_ne_zero_iff, Ne, Ne, C_eq_zero, inv_eq_zero]
    exact ⟨q_irred.ne_zero, leading_coeff_ne_zero.mpr q_irred.ne_zero⟩

end solvableByRad

end AbelRuffini

