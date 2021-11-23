import Mathbin.LinearAlgebra.FreeModule.Basic 
import Mathbin.LinearAlgebra.Matrix.ToLin 
import Mathbin.RingTheory.Finiteness

/-!
# Finite and free modules

We provide some instances for finite and free modules.

## Main results

* `module.free.choose_basis_index.fintype` : If a free module is finite, then any basis is
  finite.
* `module.free.linear_map.free ` : if `M` and `N` are finite and free, then `M →ₗ[R] N` is free.
* `module.finite.of_basis` : A free module with a basis indexed by a `fintype` is finite.
* `module.free.linear_map.module.finite` : if `M` and `N` are finite and free, then `M →ₗ[R] N`
  is finite.
-/


universe u v w

variable(R : Type u)(M : Type v)(N : Type w)

namespace Module.Free

section Ringₓ

variable[Ringₓ R][AddCommGroupₓ M][Module R M][Module.Free R M]

/-- If a free module is finite, then any basis is finite. -/
noncomputable instance  [Nontrivial R] [Module.Finite R M] : Fintype (Module.Free.ChooseBasisIndex R M) :=
  by 
    obtain ⟨h⟩ := id ‹Module.Finite R M›
    choose s hs using h 
    exact basisFintypeOfFiniteSpans («expr↑ » s) hs (choose_basis _ _)

end Ringₓ

section CommRingₓ

variable[CommRingₓ R][AddCommGroupₓ M][Module R M][Module.Free R M]

variable[AddCommGroupₓ N][Module R N][Module.Free R N]

instance  [Nontrivial R] [Module.Finite R M] [Module.Finite R N] : Module.Free R (M →ₗ[R] N) :=
  by 
    classical 
    exact of_equiv (LinearMap.toMatrix (Module.Free.chooseBasis R M) (Module.Free.chooseBasis R N)).symm

variable{R M}

/-- A free module with a basis indexed by a `fintype` is finite. -/
theorem _root_.module.finite.of_basis {R : Type _} {M : Type _} {ι : Type _} [CommRingₓ R] [AddCommGroupₓ M]
  [Module R M] [Fintype ι] (b : Basis ι R M) : Module.Finite R M :=
  by 
    classical 
    refine' ⟨⟨finset.univ.image b, _⟩⟩
    simp only [Set.image_univ, Finset.coe_univ, Finset.coe_image, Basis.span_eq]

instance _root_.module.finite.matrix {ι₁ : Type _} [Fintype ι₁] {ι₂ : Type _} [Fintype ι₂] :
  Module.Finite R (Matrix ι₁ ι₂ R) :=
  Module.Finite.of_basis$ Pi.basis$ fun i => Pi.basisFun R _

-- error in LinearAlgebra.FreeModule.Finite.Basic: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
instance [nontrivial R] [module.finite R M] [module.finite R N] : module.finite R «expr →ₗ[ ] »(M, R, N) :=
begin
  classical,
  have [ident f] [] [":=", expr (linear_map.to_matrix (choose_basis R M) (choose_basis R N)).symm],
  exact [expr module.finite.of_surjective f.to_linear_map (linear_equiv.surjective f)]
end

end CommRingₓ

section Integer

variable[AddCommGroupₓ M][Module.Finite ℤ M][Module.Free ℤ M]

variable[AddCommGroupₓ N][Module.Finite ℤ N][Module.Free ℤ N]

instance  : Module.Finite ℤ (M →+ N) :=
  Module.Finite.equiv (addMonoidHomLequivInt ℤ).symm

instance  : Module.Free ℤ (M →+ N) :=
  Module.Free.of_equiv (addMonoidHomLequivInt ℤ).symm

end Integer

end Module.Free

