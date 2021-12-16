import Mathbin.Analysis.InnerProductSpace.Calculus 
import Mathbin.Analysis.InnerProductSpace.Dual 
import Mathbin.Analysis.Calculus.LagrangeMultipliers 
import Mathbin.LinearAlgebra.Eigenspace

/-!
# The Rayleigh quotient

The Rayleigh quotient of a self-adjoint operator `T` on an inner product space `E` is the function
`λ x, ⟪T x, x⟫ / ∥x∥ ^ 2`.

The main results of this file are `is_self_adjoint.has_eigenvector_of_is_max_on` and
`is_self_adjoint.has_eigenvector_of_is_min_on`, which state that if `E` is complete, and if the
Rayleigh quotient attains its global maximum/minimum over some sphere at the point `x₀`, then `x₀`
is an eigenvector of `T`, and the `supr`/`infi` of `λ x, ⟪T x, x⟫ / ∥x∥ ^ 2` is the corresponding
eigenvalue.

The corollaries `is_self_adjoint.has_eigenvalue_supr_of_finite_dimensional` and
`is_self_adjoint.has_eigenvalue_supr_of_finite_dimensional` state that if `E` is finite-dimensional
and nontrivial, then `T` has some (nonzero) eigenvectors with eigenvalue the `supr`/`infi` of
`λ x, ⟪T x, x⟫ / ∥x∥ ^ 2`.

## TODO

A slightly more elaborate corollary is that if `E` is complete and `T` is a compact operator, then
`T` has some (nonzero) eigenvector with eigenvalue either `⨆ x, ⟪T x, x⟫ / ∥x∥ ^ 2` or
`⨅ x, ⟪T x, x⟫ / ∥x∥ ^ 2` (not necessarily both).

-/


variable {𝕜 : Type _} [IsROrC 𝕜]

variable {E : Type _} [InnerProductSpace 𝕜 E]

local notation "⟪" x ", " y "⟫" => @inner 𝕜 _ _ x y

open_locale Nnreal

open Module.End Metric

namespace ContinuousLinearMap

variable (T : E →L[𝕜] E)

local notation "rayleigh_quotient" => fun x : E => T.re_apply_inner_self x / (∥(x : E)∥^2)

theorem rayleigh_smul (x : E) {c : 𝕜} (hc : c ≠ 0) : rayleigh_quotient (c • x) = rayleigh_quotient x :=
  by 
    byCases' hx : x = 0
    ·
      simp [hx]
    have  : ∥c∥ ≠ 0 :=
      by 
        simp [hc]
    have  : ∥x∥ ≠ 0 :=
      by 
        simp [hx]
    fieldSimp [norm_smul, T.re_apply_inner_self_smul]
    ring

theorem image_rayleigh_eq_image_rayleigh_sphere {r : ℝ} (hr : 0 < r) :
  rayleigh_quotient '' {0}ᶜ = rayleigh_quotient '' sphere 0 r :=
  by 
    ext a 
    constructor
    ·
      rintro ⟨x, hx : x ≠ 0, hxT⟩
      have  : ∥x∥ ≠ 0 :=
        by 
          simp [hx]
      let c : 𝕜 := (↑∥x∥⁻¹)*r 
      have  : c ≠ 0 :=
        by 
          simp [c, hx, hr.ne']
      refine' ⟨c • x, _, _⟩
      ·
        fieldSimp [norm_smul, IsROrC.norm_eq_abs, abs_of_nonneg hr.le]
      ·
        rw [T.rayleigh_smul x this]
        exact hxT
    ·
      rintro ⟨x, hx, hxT⟩
      exact ⟨x, nonzero_of_mem_sphere hr ⟨x, hx⟩, hxT⟩

theorem supr_rayleigh_eq_supr_rayleigh_sphere {r : ℝ} (hr : 0 < r) :
  (⨆ x : { x : E // x ≠ 0 }, rayleigh_quotient x) = ⨆ x : sphere (0 : E) r, rayleigh_quotient x :=
  show (⨆ x : ({0} : Set E)ᶜ, rayleigh_quotient x) = _ by 
    simp only [@csupr_set _ _ _ _ rayleigh_quotient, T.image_rayleigh_eq_image_rayleigh_sphere hr]

theorem infi_rayleigh_eq_infi_rayleigh_sphere {r : ℝ} (hr : 0 < r) :
  (⨅ x : { x : E // x ≠ 0 }, rayleigh_quotient x) = ⨅ x : sphere (0 : E) r, rayleigh_quotient x :=
  show (⨅ x : ({0} : Set E)ᶜ, rayleigh_quotient x) = _ by 
    simp only [@cinfi_set _ _ _ _ rayleigh_quotient, T.image_rayleigh_eq_image_rayleigh_sphere hr]

end ContinuousLinearMap

namespace IsSelfAdjoint

section Real

variable {F : Type _} [InnerProductSpace ℝ F]

theorem has_strict_fderiv_at_re_apply_inner_self {T : F →L[ℝ] F} (hT : IsSelfAdjoint (T : F →ₗ[ℝ] F)) (x₀ : F) :
  HasStrictFderivAt T.re_apply_inner_self (bit0 (innerSL (T x₀))) x₀ :=
  by 
    convert T.has_strict_fderiv_at.inner (has_strict_fderiv_at_id x₀)
    ext y 
    simp [bit0, hT.apply_clm x₀ y, real_inner_comm x₀]

variable [CompleteSpace F] {T : F →L[ℝ] F}

local notation "rayleigh_quotient" => fun x : F => T.re_apply_inner_self x / (∥(x : F)∥^2)

theorem linearly_dependent_of_is_local_extr_on (hT : IsSelfAdjoint (T : F →ₗ[ℝ] F)) {x₀ : F}
  (hextr : IsLocalExtrOn T.re_apply_inner_self (sphere (0 : F) ∥x₀∥) x₀) :
  ∃ a b : ℝ, (a, b) ≠ 0 ∧ ((a • x₀)+b • T x₀) = 0 :=
  by 
    have H : IsLocalExtrOn T.re_apply_inner_self { x : F | (∥x∥^2) = (∥x₀∥^2) } x₀
    ·
      convert hextr 
      ext x 
      simp [dist_eq_norm]
    obtain ⟨a, b, h₁, h₂⟩ :=
      IsLocalExtrOn.exists_multipliers_of_has_strict_fderiv_at_1d H (has_strict_fderiv_at_norm_sq x₀)
        (hT.has_strict_fderiv_at_re_apply_inner_self x₀)
    refine' ⟨a, b, h₁, _⟩
    apply (InnerProductSpace.toDualMap ℝ F).Injective 
    simp only [LinearIsometry.map_add, LinearIsometry.map_smul, LinearIsometry.map_zero]
    change ((a • innerSL x₀)+b • innerSL (T x₀)) = 0
    apply smul_right_injective (F →L[ℝ] ℝ) (two_ne_zero : (2 : ℝ) ≠ 0)
    simpa only [bit0, add_smul, smul_add, one_smul, add_zeroₓ] using h₂

theorem eq_smul_self_of_is_local_extr_on_real (hT : IsSelfAdjoint (T : F →ₗ[ℝ] F)) {x₀ : F}
  (hextr : IsLocalExtrOn T.re_apply_inner_self (sphere (0 : F) ∥x₀∥) x₀) : T x₀ = rayleigh_quotient x₀ • x₀ :=
  by 
    obtain ⟨a, b, h₁, h₂⟩ := hT.linearly_dependent_of_is_local_extr_on hextr 
    byCases' hx₀ : x₀ = 0
    ·
      simp [hx₀]
    byCases' hb : b = 0
    ·
      have  : a ≠ 0 :=
        by 
          simpa [hb] using h₁ 
      refine' absurd _ hx₀ 
      apply smul_right_injective F this 
      simpa [hb] using h₂ 
    let c : ℝ := (-b⁻¹)*a 
    have hc : T x₀ = c • x₀
    ·
      have  : (b*b⁻¹*a) = a :=
        by 
          fieldSimp [mul_commₓ]
      apply smul_right_injective F hb 
      simp [c, ←neg_eq_of_add_eq_zeroₓ h₂, ←mul_smul, this]
    convert hc 
    have  : ∥x₀∥ ≠ 0 :=
      by 
        simp [hx₀]
    fieldSimp 
    simpa [inner_smul_left, real_inner_self_eq_norm_mul_norm, sq] using congr_argₓ (fun x => ⟪x, x₀⟫_ℝ) hc

end Real

section CompleteSpace

variable [CompleteSpace E] {T : E →L[𝕜] E}

local notation "rayleigh_quotient" => fun x : E => T.re_apply_inner_self x / (∥(x : E)∥^2)

theorem eq_smul_self_of_is_local_extr_on (hT : IsSelfAdjoint (T : E →ₗ[𝕜] E)) {x₀ : E}
  (hextr : IsLocalExtrOn T.re_apply_inner_self (sphere (0 : E) ∥x₀∥) x₀) : T x₀ = (↑rayleigh_quotient x₀ : 𝕜) • x₀ :=
  by 
    let this' := InnerProductSpace.isROrCToReal 𝕜 E 
    let S : E →L[ℝ] E := @ContinuousLinearMap.restrictScalars 𝕜 E E _ _ _ _ _ _ _ ℝ _ _ _ _ T 
    have hSA : IsSelfAdjoint (S : E →ₗ[ℝ] E) :=
      fun x y =>
        by 
          have  := hT x y 
          simp only [ContinuousLinearMap.coe_coe] at this 
          simp only [real_inner_eq_re_inner, this, ContinuousLinearMap.coe_restrict_scalars,
            ContinuousLinearMap.coe_coe, LinearMap.coe_restrict_scalars_eq_coe]
    exact eq_smul_self_of_is_local_extr_on_real hSA hextr

/-- For a self-adjoint operator `T`, a local extremum of the Rayleigh quotient of `T` on a sphere
centred at the origin is an eigenvector of `T`. -/
theorem has_eigenvector_of_is_local_extr_on (hT : IsSelfAdjoint (T : E →ₗ[𝕜] E)) {x₀ : E} (hx₀ : x₀ ≠ 0)
  (hextr : IsLocalExtrOn T.re_apply_inner_self (sphere (0 : E) ∥x₀∥) x₀) :
  has_eigenvector (T : E →ₗ[𝕜] E) (↑rayleigh_quotient x₀) x₀ :=
  by 
    refine' ⟨_, hx₀⟩
    rw [Module.End.mem_eigenspace_iff]
    exact hT.eq_smul_self_of_is_local_extr_on hextr

/-- For a self-adjoint operator `T`, a maximum of the Rayleigh quotient of `T` on a sphere centred
at the origin is an eigenvector of `T`, with eigenvalue the global supremum of the Rayleigh
quotient. -/
theorem has_eigenvector_of_is_max_on (hT : IsSelfAdjoint (T : E →ₗ[𝕜] E)) {x₀ : E} (hx₀ : x₀ ≠ 0)
  (hextr : IsMaxOn T.re_apply_inner_self (sphere (0 : E) ∥x₀∥) x₀) :
  has_eigenvector (T : E →ₗ[𝕜] E) (↑⨆ x : { x : E // x ≠ 0 }, rayleigh_quotient x) x₀ :=
  by 
    convert hT.has_eigenvector_of_is_local_extr_on hx₀ (Or.inr hextr.localize)
    have hx₀' : 0 < ∥x₀∥ :=
      by 
        simp [hx₀]
    have hx₀'' : x₀ ∈ sphere (0 : E) ∥x₀∥ :=
      by 
        simp 
    rw [T.supr_rayleigh_eq_supr_rayleigh_sphere hx₀']
    refine' IsMaxOn.supr_eq hx₀'' _ 
    intro x hx 
    dsimp 
    have  : ∥x∥ = ∥x₀∥ :=
      by 
        simpa using hx 
    rw [this]
    exact div_le_div_of_le (sq_nonneg ∥x₀∥) (hextr hx)

/-- For a self-adjoint operator `T`, a minimum of the Rayleigh quotient of `T` on a sphere centred
at the origin is an eigenvector of `T`, with eigenvalue the global infimum of the Rayleigh
quotient. -/
theorem has_eigenvector_of_is_min_on (hT : IsSelfAdjoint (T : E →ₗ[𝕜] E)) {x₀ : E} (hx₀ : x₀ ≠ 0)
  (hextr : IsMinOn T.re_apply_inner_self (sphere (0 : E) ∥x₀∥) x₀) :
  has_eigenvector (T : E →ₗ[𝕜] E) (↑⨅ x : { x : E // x ≠ 0 }, rayleigh_quotient x) x₀ :=
  by 
    convert hT.has_eigenvector_of_is_local_extr_on hx₀ (Or.inl hextr.localize)
    have hx₀' : 0 < ∥x₀∥ :=
      by 
        simp [hx₀]
    have hx₀'' : x₀ ∈ sphere (0 : E) ∥x₀∥ :=
      by 
        simp 
    rw [T.infi_rayleigh_eq_infi_rayleigh_sphere hx₀']
    refine' IsMinOn.infi_eq hx₀'' _ 
    intro x hx 
    dsimp 
    have  : ∥x∥ = ∥x₀∥ :=
      by 
        simpa using hx 
    rw [this]
    exact div_le_div_of_le (sq_nonneg ∥x₀∥) (hextr hx)

end CompleteSpace

section FiniteDimensional

variable [FiniteDimensional 𝕜 E] [_i : Nontrivial E] {T : E →ₗ[𝕜] E}

include _i

/-- The supremum of the Rayleigh quotient of a self-adjoint operator `T` on a nontrivial
finite-dimensional vector space is an eigenvalue for that operator. -/
theorem has_eigenvalue_supr_of_finite_dimensional (hT : IsSelfAdjoint T) :
  has_eigenvalue T (↑⨆ x : { x : E // x ≠ 0 }, IsROrC.re ⟪T x, x⟫ / (∥(x : E)∥^2)) :=
  by 
    have  := FiniteDimensional.proper_is_R_or_C 𝕜 E 
    let T' : E →L[𝕜] E := T.to_continuous_linear_map 
    have hT' : IsSelfAdjoint (T' : E →ₗ[𝕜] E) := hT 
    obtain ⟨x, hx⟩ : ∃ x : E, x ≠ 0 := exists_ne 0
    have H₁ : IsCompact (sphere (0 : E) ∥x∥) := is_compact_sphere _ _ 
    have H₂ : (sphere (0 : E) ∥x∥).Nonempty :=
      ⟨x,
        by 
          simp ⟩
    obtain ⟨x₀, hx₀', hTx₀⟩ := H₁.exists_forall_ge H₂ T'.re_apply_inner_self_continuous.continuous_on 
    have hx₀ : ∥x₀∥ = ∥x∥ :=
      by 
        simpa using hx₀' 
    have  : IsMaxOn T'.re_apply_inner_self (sphere 0 ∥x₀∥) x₀
    ·
      simpa only [←hx₀] using hTx₀ 
    have hx₀_ne : x₀ ≠ 0
    ·
      have  : ∥x₀∥ ≠ 0 :=
        by 
          simp only [hx₀, norm_eq_zero, hx, Ne.def, not_false_iff]
      simpa [←norm_eq_zero, Ne.def]
    exact has_eigenvalue_of_has_eigenvector (hT'.has_eigenvector_of_is_max_on hx₀_ne this)

/-- The infimum of the Rayleigh quotient of a self-adjoint operator `T` on a nontrivial
finite-dimensional vector space is an eigenvalue for that operator. -/
theorem has_eigenvalue_infi_of_finite_dimensional (hT : IsSelfAdjoint T) :
  has_eigenvalue T (↑⨅ x : { x : E // x ≠ 0 }, IsROrC.re ⟪T x, x⟫ / (∥(x : E)∥^2)) :=
  by 
    have  := FiniteDimensional.proper_is_R_or_C 𝕜 E 
    let T' : E →L[𝕜] E := T.to_continuous_linear_map 
    have hT' : IsSelfAdjoint (T' : E →ₗ[𝕜] E) := hT 
    obtain ⟨x, hx⟩ : ∃ x : E, x ≠ 0 := exists_ne 0
    have H₁ : IsCompact (sphere (0 : E) ∥x∥) := is_compact_sphere _ _ 
    have H₂ : (sphere (0 : E) ∥x∥).Nonempty :=
      ⟨x,
        by 
          simp ⟩
    obtain ⟨x₀, hx₀', hTx₀⟩ := H₁.exists_forall_le H₂ T'.re_apply_inner_self_continuous.continuous_on 
    have hx₀ : ∥x₀∥ = ∥x∥ :=
      by 
        simpa using hx₀' 
    have  : IsMinOn T'.re_apply_inner_self (sphere 0 ∥x₀∥) x₀
    ·
      simpa only [←hx₀] using hTx₀ 
    have hx₀_ne : x₀ ≠ 0
    ·
      have  : ∥x₀∥ ≠ 0 :=
        by 
          simp only [hx₀, norm_eq_zero, hx, Ne.def, not_false_iff]
      simpa [←norm_eq_zero, Ne.def]
    exact has_eigenvalue_of_has_eigenvector (hT'.has_eigenvector_of_is_min_on hx₀_ne this)

omit _i

theorem subsingleton_of_no_eigenvalue_finite_dimensional (hT : IsSelfAdjoint T)
  (hT' : ∀ μ : 𝕜, Module.End.eigenspace (T : E →ₗ[𝕜] E) μ = ⊥) : Subsingleton E :=
  (subsingleton_or_nontrivial E).resolve_right
    fun h =>
      by 
        exact absurd (hT' _) hT.has_eigenvalue_supr_of_finite_dimensional

end FiniteDimensional

end IsSelfAdjoint

