import Mathbin.LinearAlgebra.DirectSum.Finsupp 
import Mathbin.LinearAlgebra.FinsuppVectorSpace

/-!
# Bases and dimensionality of tensor products of modules

These can not go into `linear_algebra.tensor_product` since they depend on
`linear_algebra.finsupp_vector_space` which in turn imports `linear_algebra.tensor_product`.

-/


noncomputable theory

open Set LinearMap Submodule

section CommRingₓ

variable{R : Type _}{M : Type _}{N : Type _}{ι : Type _}{κ : Type _}

variable[CommRingₓ R][AddCommGroupₓ M][Module R M][AddCommGroupₓ N][Module R N]

/-- If b : ι → M and c : κ → N are bases then so is λ i, b i.1 ⊗ₜ c i.2 : ι × κ → M ⊗ N. -/
def Basis.tensorProduct (b : Basis ι R M) (c : Basis κ R N) : Basis (ι × κ) R (TensorProduct R M N) :=
  Finsupp.basisSingleOne.map
    ((TensorProduct.congr b.repr c.repr).trans$
        (finsuppTensorFinsupp R _ _ _ _).trans$ Finsupp.lcongr (Equiv.refl _) (TensorProduct.lid R R)).symm

end CommRingₓ

section Field

variable{K : Type _}(V W : Type _)

variable[Field K][AddCommGroupₓ V][Module K V][AddCommGroupₓ W][Module K W]

/-- If `V` and `W` are finite dimensional `K` vector spaces, so is `V ⊗ W`. -/
instance finite_dimensional_tensor_product [FiniteDimensional K V] [FiniteDimensional K W] :
  FiniteDimensional K (TensorProduct K V W) :=
  FiniteDimensional.of_fintype_basis (Basis.tensorProduct (Basis.ofVectorSpace K V) (Basis.ofVectorSpace K W))

end Field

