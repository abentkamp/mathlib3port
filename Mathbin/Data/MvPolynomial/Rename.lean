import Mathbin.Data.MvPolynomial.Basic

/-!
# Renaming variables of polynomials

This file establishes the `rename` operation on multivariate polynomials,
which modifies the set of variables.

## Main declarations

* `mv_polynomial.rename`
* `mv_polynomial.rename_equiv`

## Notation

As in other polynomial files, we typically use the notation:

+ `σ τ α : Type*` (indexing the variables)

+ `R S : Type*` `[comm_semiring R]` `[comm_semiring S]` (the coefficients)

+ `s : σ →₀ ℕ`, a function from `σ` to `ℕ` which is zero away from a finite set.
This will give rise to a monomial in `mv_polynomial σ R` which mathematicians might call `X^s`

+ `r : R` elements of the coefficient ring

+ `i : σ`, with corresponding monomial `X i`, often denoted `X_i` by mathematicians

+ `p : mv_polynomial σ α`

-/


noncomputable section 

open_locale Classical BigOperators

open Set Function Finsupp AddMonoidAlgebra

open_locale BigOperators

variable {σ τ α R S : Type _} [CommSemiringₓ R] [CommSemiringₓ S]

namespace MvPolynomial

section Rename

/-- Rename all the variables in a multivariable polynomial. -/
def rename (f : σ → τ) : MvPolynomial σ R →ₐ[R] MvPolynomial τ R :=
  aeval (X ∘ f)

@[simp]
theorem rename_C (f : σ → τ) (r : R) : rename f (C r) = C r :=
  eval₂_C _ _ _

@[simp]
theorem rename_X (f : σ → τ) (i : σ) : rename f (X i : MvPolynomial σ R) = X (f i) :=
  eval₂_X _ _ _

theorem map_rename (f : R →+* S) (g : σ → τ) (p : MvPolynomial σ R) : map f (rename g p) = rename g (map f p) :=
  MvPolynomial.induction_on p
    (fun a =>
      by 
        simp only [map_C, rename_C])
    (fun p q hp hq =>
      by 
        simp only [hp, hq, AlgHom.map_add, RingHom.map_add])
    fun p n hp =>
      by 
        simp only [hp, rename_X, map_X, RingHom.map_mul, AlgHom.map_mul]

@[simp]
theorem rename_rename (f : σ → τ) (g : τ → α) (p : MvPolynomial σ R) : rename g (rename f p) = rename (g ∘ f) p :=
  show rename g (eval₂ C (X ∘ f) p) = _ by 
    simp only [rename, aeval_eq_eval₂_hom]
    simp [eval₂_comp_left _ C (X ∘ f) p, · ∘ ·, eval₂_C, eval_X]
    apply eval₂_hom_congr _ rfl rfl 
    ext1 
    simp only [comp_app, RingHom.coe_comp, eval₂_hom_C]

@[simp]
theorem rename_id (p : MvPolynomial σ R) : rename id p = p :=
  eval₂_eta p

theorem rename_monomial (f : σ → τ) (d : σ →₀ ℕ) (r : R) : rename f (monomial d r) = monomial (d.map_domain f) r :=
  by 
    rw [rename, aeval_monomial, monomial_eq, Finsupp.prod_map_domain_index]
    ·
      rfl
    ·
      exact fun n => pow_zeroₓ _
    ·
      exact fun n i₁ i₂ => pow_addₓ _ _ _

theorem rename_eq (f : σ → τ) (p : MvPolynomial σ R) : rename f p = Finsupp.mapDomain (Finsupp.mapDomain f) p :=
  by 
    simp only [rename, aeval_def, eval₂, Finsupp.mapDomain, algebra_map_eq, X_pow_eq_monomial,
      ←monomial_finsupp_sum_index]
    rfl

theorem rename_injective (f : σ → τ) (hf : Function.Injective f) :
  Function.Injective (rename f : MvPolynomial σ R → MvPolynomial τ R) :=
  have  : (rename f : MvPolynomial σ R → MvPolynomial τ R) = Finsupp.mapDomain (Finsupp.mapDomain f) :=
    funext (rename_eq f)
  by 
    rw [this]
    exact Finsupp.map_domain_injective (Finsupp.map_domain_injective hf)

section 

variable (R)

/-- `mv_polynomial.rename e` is an equivalence when `e` is. -/
@[simps apply]
def rename_equiv (f : σ ≃ τ) : MvPolynomial σ R ≃ₐ[R] MvPolynomial τ R :=
  { rename f with toFun := rename f, invFun := rename f.symm,
    left_inv :=
      fun p =>
        by 
          rw [rename_rename, f.symm_comp_self, rename_id],
    right_inv :=
      fun p =>
        by 
          rw [rename_rename, f.self_comp_symm, rename_id] }

@[simp]
theorem rename_equiv_refl : rename_equiv R (Equivₓ.refl σ) = AlgEquiv.refl :=
  AlgEquiv.ext rename_id

@[simp]
theorem rename_equiv_symm (f : σ ≃ τ) : (rename_equiv R f).symm = rename_equiv R f.symm :=
  rfl

@[simp]
theorem rename_equiv_trans (e : σ ≃ τ) (f : τ ≃ α) :
  (rename_equiv R e).trans (rename_equiv R f) = rename_equiv R (e.trans f) :=
  AlgEquiv.ext (rename_rename e f)

end 

section 

variable (f : R →+* S) (k : σ → τ) (g : τ → S) (p : MvPolynomial σ R)

theorem eval₂_rename : (rename k p).eval₂ f g = p.eval₂ f (g ∘ k) :=
  by 
    apply MvPolynomial.induction_on p <;>
      ·
        intros 
        simp 

theorem eval₂_hom_rename : eval₂_hom f g (rename k p) = eval₂_hom f (g ∘ k) p :=
  eval₂_rename _ _ _ _

theorem aeval_rename [Algebra R S] : aeval g (rename k p) = aeval (g ∘ k) p :=
  eval₂_hom_rename _ _ _ _

theorem rename_eval₂ (g : τ → MvPolynomial σ R) : rename k (p.eval₂ C (g ∘ k)) = (rename k p).eval₂ C (rename k ∘ g) :=
  by 
    apply MvPolynomial.induction_on p <;>
      ·
        intros 
        simp 

theorem rename_prodmk_eval₂ (j : τ) (g : σ → MvPolynomial σ R) :
  rename (Prod.mk j) (p.eval₂ C g) = p.eval₂ C fun x => rename (Prod.mk j) (g x) :=
  by 
    apply MvPolynomial.induction_on p <;>
      ·
        intros 
        simp 

theorem eval₂_rename_prodmk (g : σ × τ → S) (i : σ) (p : MvPolynomial τ R) :
  (rename (Prod.mk i) p).eval₂ f g = eval₂ f (fun j => g (i, j)) p :=
  by 
    apply MvPolynomial.induction_on p <;>
      ·
        intros 
        simp 

theorem eval_rename_prodmk (g : σ × τ → R) (i : σ) (p : MvPolynomial τ R) :
  eval g (rename (Prod.mk i) p) = eval (fun j => g (i, j)) p :=
  eval₂_rename_prodmk (RingHom.id _) _ _ _

end 

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- Every polynomial is a polynomial in finitely many variables. -/
  theorem
    exists_finset_rename
    ( p : MvPolynomial σ R ) : ∃ ( s : Finset σ ) ( q : MvPolynomial { x // x ∈ s } R ) , p = rename coeₓ q
    :=
      by
        apply induction_on p
          · intro r exact ⟨ ∅ , C r , by rw [ rename_C ] ⟩
          ·
            rintro p q ⟨ s , p , rfl ⟩ ⟨ t , q , rfl ⟩
              refine' ⟨ s ∪ t , ⟨ _ , _ ⟩ ⟩
              ·
                refine' rename Subtype.map id _ p + rename Subtype.map id _ q
                  <;>
                  simp
                    ( config := { contextual := Bool.true._@._internal._hyg.0 } )
                    only
                    [ id.def , true_orₓ , or_trueₓ , Finset.mem_union , forall_true_iff ]
              · simp only [ rename_rename , AlgHom.map_add ] rfl
          ·
            rintro p n ⟨ s , p , rfl ⟩
              refine' ⟨ insert n s , ⟨ _ , _ ⟩ ⟩
              ·
                refine' rename Subtype.map id _ p * X ⟨ n , s.mem_insert_self n ⟩
                  simp
                    ( config := { contextual := Bool.true._@._internal._hyg.0 } )
                    only
                    [ id.def , or_trueₓ , Finset.mem_insert , forall_true_iff ]
              · simp only [ rename_rename , rename_X , Subtype.coe_mk , AlgHom.map_mul ] rfl

/-- Every polynomial is a polynomial in finitely many variables. -/
theorem exists_fin_rename (p : MvPolynomial σ R) :
  ∃ (n : ℕ)(f : Finₓ n → σ)(hf : injective f)(q : MvPolynomial (Finₓ n) R), p = rename f q :=
  by 
    obtain ⟨s, q, rfl⟩ := exists_finset_rename p 
    let n := Fintype.card { x // x ∈ s }
    let e := Fintype.equivFin { x // x ∈ s }
    refine' ⟨n, coeₓ ∘ e.symm, subtype.val_injective.comp e.symm.injective, rename e q, _⟩
    rw [←rename_rename, rename_rename e]
    simp only [Function.comp, Equivₓ.symm_apply_apply, rename_rename]

end Rename

theorem eval₂_cast_comp (f : σ → τ) (c : ℤ →+* R) (g : τ → R) (p : MvPolynomial σ ℤ) :
  eval₂ c (g ∘ f) p = eval₂ c g (rename f p) :=
  MvPolynomial.induction_on p
    (fun n =>
      by 
        simp only [eval₂_C, rename_C])
    (fun p q hp hq =>
      by 
        simp only [hp, hq, rename, eval₂_add, AlgHom.map_add])
    fun p n hp =>
      by 
        simp only [hp, rename, aeval_def, eval₂_X, eval₂_mul]

section Coeff

@[simp]
theorem coeff_rename_map_domain (f : σ → τ) (hf : injective f) (φ : MvPolynomial σ R) (d : σ →₀ ℕ) :
  (rename f φ).coeff (d.map_domain f) = φ.coeff d :=
  by 
    apply induction_on' φ
    ·
      intro u r 
      rw [rename_monomial, coeff_monomial, coeff_monomial]
      simp only [(Finsupp.map_domain_injective hf).eq_iff]
      splitIfs <;> rfl
    ·
      intros 
      simp only [AlgHom.map_add, coeff_add]

theorem coeff_rename_eq_zero (f : σ → τ) (φ : MvPolynomial σ R) (d : τ →₀ ℕ)
  (h : ∀ u : σ →₀ ℕ, u.map_domain f = d → φ.coeff u = 0) : (rename f φ).coeff d = 0 :=
  by 
    rw [rename_eq, ←not_mem_support_iff]
    intro H 
    replace H := map_domain_support H 
    rw [Finset.mem_image] at H 
    obtain ⟨u, hu, rfl⟩ := H 
    specialize h u rfl 
    simp  at h hu 
    contradiction

theorem coeff_rename_ne_zero (f : σ → τ) (φ : MvPolynomial σ R) (d : τ →₀ ℕ) (h : (rename f φ).coeff d ≠ 0) :
  ∃ u : σ →₀ ℕ, u.map_domain f = d ∧ φ.coeff u ≠ 0 :=
  by 
    contrapose! h 
    apply coeff_rename_eq_zero _ _ _ h

@[simp]
theorem constant_coeff_rename {τ : Type _} (f : σ → τ) (φ : MvPolynomial σ R) :
  constant_coeff (rename f φ) = constant_coeff φ :=
  by 
    apply φ.induction_on
    ·
      intro a 
      simp only [constant_coeff_C, rename_C]
    ·
      intro p q hp hq 
      simp only [hp, hq, RingHom.map_add, AlgHom.map_add]
    ·
      intro p n hp 
      simp only [hp, rename_X, constant_coeff_X, RingHom.map_mul, AlgHom.map_mul]

end Coeff

end MvPolynomial

