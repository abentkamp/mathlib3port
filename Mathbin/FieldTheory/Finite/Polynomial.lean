import Mathbin.LinearAlgebra.FiniteDimensional 
import Mathbin.LinearAlgebra.Basic 
import Mathbin.RingTheory.MvPolynomial.Basic 
import Mathbin.Data.MvPolynomial.Expand 
import Mathbin.FieldTheory.Finite.Basic

/-!
## Polynomials over finite fields
-/


namespace MvPolynomial

variable{σ : Type _}

/-- A polynomial over the integers is divisible by `n : ℕ`
if and only if it is zero over `zmod n`. -/
theorem C_dvd_iff_zmod (n : ℕ) (φ : MvPolynomial σ ℤ) : C (n : ℤ) ∣ φ ↔ map (Int.castRingHom (Zmod n)) φ = 0 :=
  C_dvd_iff_map_hom_eq_zero _ _ (CharP.int_cast_eq_zero_iff (Zmod n) n) _

section frobenius

variable{p : ℕ}[Fact p.prime]

theorem frobenius_zmod (f : MvPolynomial σ (Zmod p)) : frobenius _ p f = expand p f :=
  by 
    apply induction_on f
    ·
      intro a 
      rw [expand_C, frobenius_def, ←C_pow, Zmod.pow_card]
    ·
      simp only [AlgHom.map_add, RingHom.map_add]
      intro _ _ hf hg 
      rw [hf, hg]
    ·
      simp only [expand_X, RingHom.map_mul, AlgHom.map_mul]
      intro _ _ hf 
      rw [hf, frobenius_def]

theorem expand_zmod (f : MvPolynomial σ (Zmod p)) : expand p f = (f^p) :=
  (frobenius_zmod _).symm

end frobenius

end MvPolynomial

namespace MvPolynomial

noncomputable theory

open_locale BigOperators Classical

open Set LinearMap Submodule

variable{K : Type _}{σ : Type _}

variable[Field K][Fintype K][Fintype σ]

def indicator (a : σ → K) : MvPolynomial σ K :=
  ∏n, 1 - (X n - C (a n)^Fintype.card K - 1)

theorem eval_indicator_apply_eq_one (a : σ → K) : eval a (indicator a) = 1 :=
  have  : 0 < Fintype.card K - 1 :=
    by 
      rw [←Fintype.card_units, Fintype.card_pos_iff]
      exact ⟨1⟩
  by 
    simp only [indicator, (eval a).map_prod, RingHom.map_sub, (eval a).map_one, (eval a).map_pow, eval_X, eval_C,
      sub_self, zero_pow this, sub_zero, Finset.prod_const_one]

theorem eval_indicator_apply_eq_zero (a b : σ → K) (h : a ≠ b) : eval a (indicator b) = 0 :=
  have  : ∃ i, a i ≠ b i :=
    by 
      rwa [· ≠ ·, Function.funext_iffₓ, not_forall] at h 
  by 
    rcases this with ⟨i, hi⟩
    simp only [indicator, (eval a).map_prod, RingHom.map_sub, (eval a).map_one, (eval a).map_pow, eval_X, eval_C,
      sub_self, Finset.prod_eq_zero_iff]
    refine' ⟨i, Finset.mem_univ _, _⟩
    rw [FiniteField.pow_card_sub_one_eq_one, sub_self]
    rwa [· ≠ ·, sub_eq_zero]

theorem degrees_indicator (c : σ → K) : degrees (indicator c) ≤ ∑s : σ, (Fintype.card K - 1) • {s} :=
  by 
    rw [indicator]
    refine' le_transₓ (degrees_prod _ _) (Finset.sum_le_sum$ fun s hs => _)
    refine' le_transₓ (degrees_sub _ _) _ 
    rw [degrees_one, ←bot_eq_zero, bot_sup_eq]
    refine' le_transₓ (degrees_pow _ _) (nsmul_le_nsmul_of_le_right _ _)
    refine' le_transₓ (degrees_sub _ _) _ 
    rw [degrees_C, ←bot_eq_zero, sup_bot_eq]
    exact degrees_X' _

theorem indicator_mem_restrict_degree (c : σ → K) : indicator c ∈ restrict_degree σ K (Fintype.card K - 1) :=
  by 
    rw [mem_restrict_degree_iff_sup, indicator]
    intro n 
    refine' le_transₓ (Multiset.count_le_of_le _$ degrees_indicator _) (le_of_eqₓ _)
    simpRw [←Multiset.coe_count_add_monoid_hom, (Multiset.countAddMonoidHom n).map_sum, AddMonoidHom.map_nsmul,
      Multiset.coe_count_add_monoid_hom, nsmul_eq_mul, Nat.cast_id]
    trans 
    refine' Finset.sum_eq_single n _ _
    ·
      intro b hb ne 
      rw [Multiset.count_singleton, if_neg Ne.symm, mul_zero]
    ·
      intro h 
      exact (h$ Finset.mem_univ _).elim
    ·
      rw [Multiset.count_singleton_self, mul_oneₓ]

section 

variable(K σ)

def evalₗ : MvPolynomial σ K →ₗ[K] (σ → K) → K :=
  { toFun := fun p e => eval e p,
    map_add' :=
      fun p q =>
        by 
          ext x 
          rw [RingHom.map_add]
          rfl,
    map_smul' :=
      fun a p =>
        by 
          ext e 
          rw [smul_eq_C_mul, RingHom.map_mul, eval_C]
          rfl }

end 

theorem evalₗ_apply (p : MvPolynomial σ K) (e : σ → K) : evalₗ K σ p e = eval e p :=
  rfl

theorem map_restrict_dom_evalₗ : (restrict_degree σ K (Fintype.card K - 1)).map (evalₗ K σ) = ⊤ :=
  by 
    refine' top_unique (SetLike.le_def.2$ fun e _ => mem_map.2 _)
    refine' ⟨∑n : σ → K, e n • indicator n, _, _⟩
    ·
      exact sum_mem _ fun c _ => smul_mem _ _ (indicator_mem_restrict_degree _)
    ·
      ext n 
      simp only [LinearMap.map_sum, @Finset.sum_apply (σ → K) (fun _ => K) _ _ _ _ _, Pi.smul_apply, LinearMap.map_smul]
      simp only [evalₗ_apply]
      trans 
      refine' Finset.sum_eq_single n _ _
      ·
        intro b _ h 
        rw [eval_indicator_apply_eq_zero _ _ h.symm, smul_zero]
      ·
        intro h 
        exact (h$ Finset.mem_univ n).elim
      ·
        rw [eval_indicator_apply_eq_one, smul_eq_mul, mul_oneₓ]

end MvPolynomial

namespace MvPolynomial

open_locale Classical Cardinal

open LinearMap Submodule

universe u

variable(σ : Type u)(K : Type u)[Fintype σ][Field K][Fintype K]

-- error in FieldTheory.Finite.Polynomial: ././Mathport/Syntax/Translate/Basic.lean:704:9: unsupported derive handler add_comm_group
@[derive #["[", expr add_comm_group, ",", expr module K, ",", expr inhabited, "]"]] def R : Type u :=
restrict_degree σ K «expr - »(fintype.card K, 1)

noncomputable instance decidable_restrict_degree (m : ℕ) : DecidablePred (· ∈ { n:σ →₀ ℕ | ∀ i, n i ≤ m }) :=
  by 
    simp only [Set.mem_set_of_eq] <;> infer_instance

theorem dim_R : Module.rank K (R σ K) = Fintype.card (σ → K) :=
  calc Module.rank K (R σ K) = Module.rank K («expr↥ » { s:σ →₀ ℕ | ∀ n : σ, s n ≤ Fintype.card K - 1 } →₀ K) :=
    LinearEquiv.dim_eq (Finsupp.supportedEquivFinsupp { s:σ →₀ ℕ | ∀ n : σ, s n ≤ Fintype.card K - 1 })
    _ = # { s:σ →₀ ℕ | ∀ n : σ, s n ≤ Fintype.card K - 1 } :=
    by 
      rw [Finsupp.dim_eq, dim_self, mul_oneₓ]
    _ = # { s:σ → ℕ | ∀ n : σ, s n < Fintype.card K } :=
    by 
      refine' Quotientₓ.sound ⟨Equiv.subtypeEquiv Finsupp.equivFunOnFintype$ fun f => _⟩
      refine' forall_congrₓ fun n => le_tsub_iff_right _ 
      exact Fintype.card_pos_iff.2 ⟨0⟩
    _ = # (σ → { n // n < Fintype.card K }) :=
    (@Equiv.subtypePiEquivPi σ (fun _ => ℕ) fun s n => n < Fintype.card K).cardinal_eq 
    _ = # (σ → Finₓ (Fintype.card K)) := (Equiv.arrowCongr (Equiv.refl σ) (Equiv.finEquivSubtype _).symm).cardinal_eq 
    _ = # (σ → K) := (Equiv.arrowCongr (Equiv.refl σ) (Fintype.equivFin K).symm).cardinal_eq 
    _ = Fintype.card (σ → K) := Cardinal.mk_fintype _
    

instance  : FiniteDimensional K (R σ K) :=
  IsNoetherian.iff_fg.1$
    IsNoetherian.iff_dim_lt_omega.mpr
      (by 
        simpa only [dim_R] using Cardinal.nat_lt_omega (Fintype.card (σ → K)))

theorem finrank_R : FiniteDimensional.finrank K (R σ K) = Fintype.card (σ → K) :=
  FiniteDimensional.finrank_eq_of_dim_eq (dim_R σ K)

def evalᵢ : R σ K →ₗ[K] (σ → K) → K :=
  (evalₗ K σ).comp (restrict_degree σ K (Fintype.card K - 1)).Subtype

theorem range_evalᵢ : (evalᵢ σ K).range = ⊤ :=
  by 
    rw [evalᵢ, LinearMap.range_comp, range_subtype]
    exact map_restrict_dom_evalₗ

theorem ker_evalₗ : (evalᵢ σ K).ker = ⊥ :=
  by 
    refine' (ker_eq_bot_iff_range_eq_top_of_finrank_eq_finrank _).mpr (range_evalᵢ _ _)
    rw [FiniteDimensional.finrank_fintype_fun_eq_card, finrank_R]

theorem eq_zero_of_eval_eq_zero (p : MvPolynomial σ K) (h : ∀ v : σ → K, eval v p = 0)
  (hp : p ∈ restrict_degree σ K (Fintype.card K - 1)) : p = 0 :=
  let p' : R σ K := ⟨p, hp⟩
  have  : p' ∈ (evalᵢ σ K).ker :=
    by 
      rw [mem_ker]
      ext v 
      exact h v 
  show p'.1 = (0 : R σ K).1by 
    rw [ker_evalₗ, mem_bot] at this 
    rw [this]

end MvPolynomial

