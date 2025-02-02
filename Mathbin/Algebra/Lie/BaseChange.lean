/-
Copyright (c) 2021 Oliver Nash. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Oliver Nash
-/
import Mathbin.Algebra.Algebra.RestrictScalars
import Mathbin.Algebra.Lie.TensorProduct

/-!
# Extension and restriction of scalars for Lie algebras

Lie algebras have a well-behaved theory of extension and restriction of scalars.

## Main definitions

 * `lie_algebra.extend_scalars.lie_algebra`
 * `lie_algebra.restrict_scalars.lie_algebra`

## Tags

lie ring, lie algebra, extension of scalars, restriction of scalars, base change
-/


universe u v w w₁ w₂ w₃

open TensorProduct

variable (R : Type u) (A : Type w) (L : Type v)

namespace LieAlgebra

namespace ExtendScalars

variable [CommRingₓ R] [CommRingₓ A] [Algebra R A] [LieRing L] [LieAlgebra R L]

/-- The Lie bracket on the extension of a Lie algebra `L` over `R` by an algebra `A` over `R`.

In fact this bracket is fully `A`-bilinear but without a significant upgrade to our mixed-scalar
support in the tensor product library, it is far easier to bootstrap like this, starting with the
definition below. -/
private def bracket' : A ⊗[R] L →ₗ[R] A ⊗[R] L →ₗ[R] A ⊗[R] L :=
  TensorProduct.curry <|
    TensorProduct.map (LinearMap.mul' R _) (LieModule.toModuleHom R L L : L ⊗[R] L →ₗ[R] L) ∘ₗ
      ↑(TensorProduct.tensorTensorTensorComm R A L A L)

@[simp]
private theorem bracket'_tmul (s t : A) (x y : L) : bracket' R A L (s ⊗ₜ[R] x) (t ⊗ₜ[R] y) = (s * t) ⊗ₜ ⁅x,y⁆ := by
  simp [bracket']

instance : HasBracket (A ⊗[R] L) (A ⊗[R] L) where bracket := fun x y => bracket' R A L x y

private theorem bracket_def (x y : A ⊗[R] L) : ⁅x,y⁆ = bracket' R A L x y :=
  rfl

@[simp]
theorem bracket_tmul (s t : A) (x y : L) : ⁅s ⊗ₜ[R] x,t ⊗ₜ[R] y⁆ = (s * t) ⊗ₜ ⁅x,y⁆ := by
  rw [bracket_def, bracket'_tmul]

private theorem bracket_lie_self (x : A ⊗[R] L) : ⁅x,x⁆ = 0 := by
  simp only [bracket_def]
  apply x.induction_on
  · simp only [LinearMap.map_zero, eq_self_iff_true, LinearMap.zero_apply]
    
  · intro a l
    simp only [bracket'_tmul, TensorProduct.tmul_zero, eq_self_iff_true, lie_self]
    
  · intro z₁ z₂ h₁ h₂
    suffices bracket' R A L z₁ z₂ + bracket' R A L z₂ z₁ = 0 by
      rw [LinearMap.map_add, LinearMap.map_add, LinearMap.add_apply, LinearMap.add_apply, h₁, h₂, zero_addₓ, add_zeroₓ,
        add_commₓ, this]
    apply z₁.induction_on
    · simp only [LinearMap.map_zero, add_zeroₓ, LinearMap.zero_apply]
      
    · intro a₁ l₁
      apply z₂.induction_on
      · simp only [LinearMap.map_zero, add_zeroₓ, LinearMap.zero_apply]
        
      · intro a₂ l₂
        simp only [← lie_skew l₂ l₁, mul_comm a₁ a₂, TensorProduct.tmul_neg, bracket'_tmul, add_right_negₓ]
        
      · intro y₁ y₂ hy₁ hy₂
        simp only [hy₁, hy₂, add_add_add_commₓ, add_zeroₓ, LinearMap.add_apply, LinearMap.map_add]
        
      
    · intro y₁ y₂ hy₁ hy₂
      simp only [add_add_add_commₓ, hy₁, hy₂, add_zeroₓ, LinearMap.add_apply, LinearMap.map_add]
      
    

private theorem bracket_leibniz_lie (x y z : A ⊗[R] L) : ⁅x,⁅y,z⁆⁆ = ⁅⁅x,y⁆,z⁆ + ⁅y,⁅x,z⁆⁆ := by
  simp only [bracket_def]
  apply x.induction_on
  · simp only [LinearMap.map_zero, add_zeroₓ, eq_self_iff_true, LinearMap.zero_apply]
    
  · intro a₁ l₁
    apply y.induction_on
    · simp only [LinearMap.map_zero, add_zeroₓ, eq_self_iff_true, LinearMap.zero_apply]
      
    · intro a₂ l₂
      apply z.induction_on
      · simp only [LinearMap.map_zero, add_zeroₓ]
        
      · intro a₃ l₃
        simp only [bracket'_tmul]
        rw [mul_left_commₓ a₂ a₁ a₃, mul_assoc, leibniz_lie, TensorProduct.tmul_add]
        
      · intro u₁ u₂ h₁ h₂
        simp only [add_add_add_commₓ, h₁, h₂, LinearMap.map_add]
        
      
    · intro u₁ u₂ h₁ h₂
      simp only [add_add_add_commₓ, h₁, h₂, LinearMap.add_apply, LinearMap.map_add]
      
    
  · intro u₁ u₂ h₁ h₂
    simp only [add_add_add_commₓ, h₁, h₂, LinearMap.add_apply, LinearMap.map_add]
    

instance : LieRing (A ⊗[R] L) where
  add_lie := fun x y z => by
    simp only [bracket_def, LinearMap.add_apply, LinearMap.map_add]
  lie_add := fun x y z => by
    simp only [bracket_def, LinearMap.map_add]
  lie_self := bracket_lie_self R A L
  leibniz_lie := bracket_leibniz_lie R A L

private theorem bracket_lie_smul (a : A) (x y : A ⊗[R] L) : ⁅x,a • y⁆ = a • ⁅x,y⁆ := by
  apply x.induction_on
  · simp only [zero_lie, smul_zero]
    
  · intro a₁ l₁
    apply y.induction_on
    · simp only [lie_zero, smul_zero]
      
    · intro a₂ l₂
      simp only [bracket_def, bracket', TensorProduct.smul_tmul', mul_left_commₓ a₁ a a₂, TensorProduct.curry_apply,
        LinearMap.mul'_apply, Algebra.id.smul_eq_mul, Function.comp_app, LinearEquiv.coe_coe, LinearMap.coe_comp,
        TensorProduct.map_tmul, TensorProduct.tensor_tensor_tensor_comm_tmul]
      
    · intro z₁ z₂ h₁ h₂
      simp only [h₁, h₂, smul_add, lie_add]
      
    
  · intro z₁ z₂ h₁ h₂
    simp only [h₁, h₂, smul_add, add_lie]
    

instance lieAlgebra : LieAlgebra A (A ⊗[R] L) where lie_smul := bracket_lie_smul R A L

end ExtendScalars

namespace RestrictScalars

open RestrictScalars

variable [h : LieRing L]

include h

instance : LieRing (RestrictScalars R A L) :=
  h

variable [CommRingₓ A] [LieAlgebra A L]

instance lieAlgebra [CommRingₓ R] [Algebra R A] :
    LieAlgebra R
      (RestrictScalars R A
        L) where lie_smul := fun t x y =>
    (lie_smul (algebraMap R A t) (RestrictScalars.addEquiv R A L x) (RestrictScalars.addEquiv R A L y) : _)

end RestrictScalars

end LieAlgebra

