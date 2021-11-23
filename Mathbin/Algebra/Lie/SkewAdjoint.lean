import Mathbin.Algebra.Lie.Matrix 
import Mathbin.LinearAlgebra.BilinearForm

/-!
# Lie algebras of skew-adjoint endomorphisms of a bilinear form

When a module carries a bilinear form, the Lie algebra of endomorphisms of the module contains a
distinguished Lie subalgebra: the skew-adjoint endomorphisms. Such subalgebras are important
because they provide a simple, explicit construction of the so-called classical Lie algebras.

This file defines the Lie subalgebra of skew-adjoint endomorphims cut out by a bilinear form on
a module and proves some basic related results. It also provides the corresponding definitions and
results for the Lie algebra of square matrices.

## Main definitions

  * `skew_adjoint_lie_subalgebra`
  * `skew_adjoint_lie_subalgebra_equiv`
  * `skew_adjoint_matrices_lie_subalgebra`
  * `skew_adjoint_matrices_lie_subalgebra_equiv`

## Tags

lie algebra, skew-adjoint, bilinear form
-/


universe u v w w₁

section SkewAdjointEndomorphisms

open BilinForm

variable{R : Type u}{M : Type v}[CommRingₓ R][AddCommGroupₓ M][Module R M]

variable(B : BilinForm R M)

-- error in Algebra.Lie.SkewAdjoint: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem bilin_form.is_skew_adjoint_bracket
(f g : module.End R M)
(hf : «expr ∈ »(f, B.skew_adjoint_submodule))
(hg : «expr ∈ »(g, B.skew_adjoint_submodule)) : «expr ∈ »(«expr⁅ , ⁆»(f, g), B.skew_adjoint_submodule) :=
begin
  rw [expr mem_skew_adjoint_submodule] ["at", "*"],
  have [ident hfg] [":", expr is_adjoint_pair B B «expr * »(f, g) «expr * »(g, f)] [],
  { rw ["<-", expr neg_mul_neg g f] [],
    exact [expr hf.mul hg] },
  have [ident hgf] [":", expr is_adjoint_pair B B «expr * »(g, f) «expr * »(f, g)] [],
  { rw ["<-", expr neg_mul_neg f g] [],
    exact [expr hg.mul hf] },
  change [expr bilin_form.is_adjoint_pair B B «expr - »(«expr * »(f, g), «expr * »(g, f)) «expr- »(«expr - »(«expr * »(f, g), «expr * »(g, f)))] [] [],
  rw [expr neg_sub] [],
  exact [expr hfg.sub hgf]
end

/-- Given an `R`-module `M`, equipped with a bilinear form, the skew-adjoint endomorphisms form a
Lie subalgebra of the Lie algebra of endomorphisms. -/
def skewAdjointLieSubalgebra : LieSubalgebra R (Module.End R M) :=
  { B.skew_adjoint_submodule with lie_mem' := B.is_skew_adjoint_bracket }

variable{N : Type w}[AddCommGroupₓ N][Module R N](e : N ≃ₗ[R] M)

/-- An equivalence of modules with bilinear forms gives equivalence of Lie algebras of skew-adjoint
endomorphisms. -/
def skewAdjointLieSubalgebraEquiv :
  skewAdjointLieSubalgebra (B.comp («expr↑ » e : N →ₗ[R] M) («expr↑ » e)) ≃ₗ⁅R⁆ skewAdjointLieSubalgebra B :=
  by 
    apply LieEquiv.ofSubalgebras _ _ e.lie_conj 
    ext f 
    simp only [LieSubalgebra.mem_coe, Submodule.mem_map_equiv, LieSubalgebra.mem_map_submodule, coe_coe]
    exact (BilinForm.is_pair_self_adjoint_equiv (-B) B e f).symm

@[simp]
theorem skew_adjoint_lie_subalgebra_equiv_apply (f : skewAdjointLieSubalgebra (B.comp («expr↑ » e) («expr↑ » e))) :
  «expr↑ » (skewAdjointLieSubalgebraEquiv B e f) = e.lie_conj f :=
  by 
    simp [skewAdjointLieSubalgebraEquiv]

@[simp]
theorem skew_adjoint_lie_subalgebra_equiv_symm_apply (f : skewAdjointLieSubalgebra B) :
  «expr↑ » ((skewAdjointLieSubalgebraEquiv B e).symm f) = e.symm.lie_conj f :=
  by 
    simp [skewAdjointLieSubalgebraEquiv]

end SkewAdjointEndomorphisms

section SkewAdjointMatrices

open_locale Matrix

variable{R : Type u}{n : Type w}[CommRingₓ R][DecidableEq n][Fintype n]

variable(J : Matrix n n R)

theorem Matrix.lie_transpose (A B : Matrix n n R) : (⁅A,B⁆)ᵀ = ⁅(B)ᵀ,(A)ᵀ⁆ :=
  show ((A*B) - B*A)ᵀ = ((B)ᵀ*(A)ᵀ) - (A)ᵀ*(B)ᵀby 
    simp 

theorem Matrix.is_skew_adjoint_bracket (A B : Matrix n n R) (hA : A ∈ skewAdjointMatricesSubmodule J)
  (hB : B ∈ skewAdjointMatricesSubmodule J) : ⁅A,B⁆ ∈ skewAdjointMatricesSubmodule J :=
  by 
    simp only [mem_skew_adjoint_matrices_submodule] at *
    change (⁅A,B⁆)ᵀ ⬝ J = J ⬝ -⁅A,B⁆
    change (A)ᵀ ⬝ J = J ⬝ -A at hA 
    change (B)ᵀ ⬝ J = J ⬝ -B at hB 
    simp only [←Matrix.mul_eq_mul] at *
    rw [Matrix.lie_transpose, LieRing.of_associative_ring_bracket, LieRing.of_associative_ring_bracket, sub_mul,
      mul_assocₓ, mul_assocₓ, hA, hB, ←mul_assocₓ, ←mul_assocₓ, hA, hB]
    noncommRing

/-- The Lie subalgebra of skew-adjoint square matrices corresponding to a square matrix `J`. -/
def skewAdjointMatricesLieSubalgebra : LieSubalgebra R (Matrix n n R) :=
  { skewAdjointMatricesSubmodule J with lie_mem' := J.is_skew_adjoint_bracket }

@[simp]
theorem mem_skew_adjoint_matrices_lie_subalgebra (A : Matrix n n R) :
  A ∈ skewAdjointMatricesLieSubalgebra J ↔ A ∈ skewAdjointMatricesSubmodule J :=
  Iff.rfl

/-- An invertible matrix `P` gives a Lie algebra equivalence between those endomorphisms that are
skew-adjoint with respect to a square matrix `J` and those with respect to `PᵀJP`. -/
def skewAdjointMatricesLieSubalgebraEquiv (P : Matrix n n R) (h : Invertible P) :
  skewAdjointMatricesLieSubalgebra J ≃ₗ⁅R⁆ skewAdjointMatricesLieSubalgebra ((P)ᵀ ⬝ J ⬝ P) :=
  LieEquiv.ofSubalgebras _ _ (P.lie_conj h).symm
    (by 
      ext A 
      suffices  : P.lie_conj h A ∈ skewAdjointMatricesSubmodule J ↔ A ∈ skewAdjointMatricesSubmodule ((P)ᵀ ⬝ J ⬝ P)
      ·
        simp only [LieSubalgebra.mem_coe, Submodule.mem_map_equiv, LieSubalgebra.mem_map_submodule, coe_coe]
        exact this 
      simp [Matrix.IsSkewAdjoint, J.is_adjoint_pair_equiv _ _ P (is_unit_of_invertible P)])

theorem skew_adjoint_matrices_lie_subalgebra_equiv_apply (P : Matrix n n R) (h : Invertible P)
  (A : skewAdjointMatricesLieSubalgebra J) :
  «expr↑ » (skewAdjointMatricesLieSubalgebraEquiv J P h A) = P⁻¹ ⬝ «expr↑ » A ⬝ P :=
  by 
    simp [skewAdjointMatricesLieSubalgebraEquiv]

/-- An equivalence of matrix algebras commuting with the transpose endomorphisms restricts to an
equivalence of Lie algebras of skew-adjoint matrices. -/
def skewAdjointMatricesLieSubalgebraEquivTranspose {m : Type w} [DecidableEq m] [Fintype m]
  (e : Matrix n n R ≃ₐ[R] Matrix m m R) (h : ∀ A, (e A)ᵀ = e (A)ᵀ) :
  skewAdjointMatricesLieSubalgebra J ≃ₗ⁅R⁆ skewAdjointMatricesLieSubalgebra (e J) :=
  LieEquiv.ofSubalgebras _ _ e.to_lie_equiv
    (by 
      ext A 
      suffices  : J.is_skew_adjoint (e.symm A) ↔ (e J).IsSkewAdjoint A
      ·
        simpa [this]
      simp [Matrix.IsSkewAdjoint, Matrix.IsAdjointPair, ←Matrix.mul_eq_mul, ←h, ←Function.Injective.eq_iff e.injective])

@[simp]
theorem skew_adjoint_matrices_lie_subalgebra_equiv_transpose_apply {m : Type w} [DecidableEq m] [Fintype m]
  (e : Matrix n n R ≃ₐ[R] Matrix m m R) (h : ∀ A, (e A)ᵀ = e (A)ᵀ) (A : skewAdjointMatricesLieSubalgebra J) :
  (skewAdjointMatricesLieSubalgebraEquivTranspose J e h A : Matrix m m R) = e A :=
  rfl

theorem mem_skew_adjoint_matrices_lie_subalgebra_unit_smul (u : Units R) (J A : Matrix n n R) :
  A ∈ skewAdjointMatricesLieSubalgebra (u • J) ↔ A ∈ skewAdjointMatricesLieSubalgebra J :=
  by 
    change A ∈ skewAdjointMatricesSubmodule (u • J) ↔ A ∈ skewAdjointMatricesSubmodule J 
    simp only [mem_skew_adjoint_matrices_submodule, Matrix.IsSkewAdjoint, Matrix.IsAdjointPair]
    split  <;> intro h
    ·
      simpa using congr_argₓ (fun B => u⁻¹ • B) h
    ·
      simp [h]

end SkewAdjointMatrices

