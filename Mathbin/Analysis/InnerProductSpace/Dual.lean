import Mathbin.Analysis.InnerProductSpace.Projection 
import Mathbin.Analysis.NormedSpace.Dual 
import Mathbin.Analysis.NormedSpace.Star

/-!
# The Fréchet-Riesz representation theorem

We consider an inner product space `E` over `𝕜`, which is either `ℝ` or `ℂ`. We define
`to_dual_map`, a conjugate-linear isometric embedding of `E` into its dual, which maps an element
`x` of the space to `λ y, ⟪x, y⟫`.

Under the hypothesis of completeness (i.e., for Hilbert spaces), we upgrade this to `to_dual`, a
conjugate-linear isometric *equivalence* of `E` onto its dual; that is, we establish the
surjectivity of `to_dual_map`.  This is the Fréchet-Riesz representation theorem: every element of
the dual of a Hilbert space `E` has the form `λ u, ⟪x, u⟫` for some `x : E`.

## References

* [M. Einsiedler and T. Ward, *Functional Analysis, Spectral Theory, and Applications*]
  [EinsiedlerWard2017]

## Tags

dual, Fréchet-Riesz
-/


noncomputable section 

open_locale Classical

universe u v

namespace InnerProductSpace

open IsROrC ContinuousLinearMap

variable (𝕜 : Type _)

variable (E : Type _) [IsROrC 𝕜] [InnerProductSpace 𝕜 E]

local notation "⟪" x ", " y "⟫" => @inner 𝕜 E _ x y

local postfix:90 "†" => starRingAut

/--
An element `x` of an inner product space `E` induces an element of the dual space `dual 𝕜 E`,
the map `λ y, ⟪x, y⟫`; moreover this operation is a conjugate-linear isometric embedding of `E`
into `dual 𝕜 E`.
If `E` is complete, this operation is surjective, hence a conjugate-linear isometric equivalence;
see `to_dual`.
-/
def to_dual_map : E →ₗᵢ⋆[𝕜] NormedSpace.Dual 𝕜 E :=
  { innerSL with norm_map' := fun _ => innerSL_apply_norm }

variable {E}

@[simp]
theorem to_dual_map_apply {x y : E} : to_dual_map 𝕜 E x y = ⟪x, y⟫ :=
  rfl

theorem innerSL_norm [Nontrivial E] : ∥(innerSL : E →L⋆[𝕜] E →L[𝕜] 𝕜)∥ = 1 :=
  show ∥(to_dual_map 𝕜 E).toContinuousLinearMap∥ = 1 from LinearIsometry.norm_to_continuous_linear_map _

variable (E) [CompleteSpace E]

/--
Fréchet-Riesz representation: any `ℓ` in the dual of a Hilbert space `E` is of the form
`λ u, ⟪y, u⟫` for some `y : E`, i.e. `to_dual_map` is surjective.
-/
def to_dual : E ≃ₗᵢ⋆[𝕜] NormedSpace.Dual 𝕜 E :=
  LinearIsometryEquiv.ofSurjective (to_dual_map 𝕜 E)
    (by 
      intro ℓ 
      set Y := ker ℓ with hY 
      byCases' htriv : Y = ⊤
      ·
        have hℓ : ℓ = 0
        ·
          have h' := linear_map.ker_eq_top.mp htriv 
          rw [←coe_zero] at h' 
          apply coe_injective 
          exact h' 
        exact
          ⟨0,
            by 
              simp [hℓ]⟩
      ·
        rw [←Submodule.orthogonal_eq_bot_iff] at htriv 
        change Yᗮ ≠ ⊥ at htriv 
        rw [Submodule.ne_bot_iff] at htriv 
        obtain ⟨z : E, hz : z ∈ Yᗮ, z_ne_0 : z ≠ 0⟩ := htriv 
        refine' ⟨(ℓ z† / ⟪z, z⟫) • z, _⟩
        ext x 
        have h₁ : ℓ z • x - ℓ x • z ∈ Y
        ·
          rw [mem_ker, map_sub, map_smul, map_smul, Algebra.id.smul_eq_mul, Algebra.id.smul_eq_mul, mul_commₓ]
          exact sub_self (ℓ x*ℓ z)
        have h₂ : (ℓ z*⟪z, x⟫) = ℓ x*⟪z, z⟫
        ·
          have h₃ :=
            calc 0 = ⟪z, ℓ z • x - ℓ x • z⟫ :=
              by 
                rw [(Y.mem_orthogonal' z).mp hz]
                exact h₁ 
              _ = ⟪z, ℓ z • x⟫ - ⟪z, ℓ x • z⟫ :=
              by 
                rw [inner_sub_right]
              _ = (ℓ z*⟪z, x⟫) - ℓ x*⟪z, z⟫ :=
              by 
                simp [inner_smul_right]
              
          exact sub_eq_zero.mp (Eq.symm h₃)
        have h₄ :=
          calc ⟪(ℓ z† / ⟪z, z⟫) • z, x⟫ = (ℓ z / ⟪z, z⟫)*⟪z, x⟫ :=
            by 
              simp [inner_smul_left, RingEquiv.map_div, conj_conj]
            _ = (ℓ z*⟪z, x⟫) / ⟪z, z⟫ :=
            by 
              rw [←div_mul_eq_mul_div]
            _ = (ℓ x*⟪z, z⟫) / ⟪z, z⟫ :=
            by 
              rw [h₂]
            _ = ℓ x :=
            by 
              have  : ⟪z, z⟫ ≠ 0
              ·
                change z = 0 → False at z_ne_0 
                rwa [←inner_self_eq_zero] at z_ne_0 
              fieldSimp [this]
            
        exact h₄)

variable {E}

@[simp]
theorem to_dual_apply {x y : E} : to_dual 𝕜 E x y = ⟪x, y⟫ :=
  rfl

@[simp]
theorem to_dual_symm_apply {x : E} {y : NormedSpace.Dual 𝕜 E} : ⟪(to_dual 𝕜 E).symm y, x⟫ = y x :=
  by 
    rw [←to_dual_apply]
    simp only [LinearIsometryEquiv.apply_symm_apply]

end InnerProductSpace

