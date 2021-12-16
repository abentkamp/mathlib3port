import Mathbin.LinearAlgebra.DirectSum.Finsupp 
import Mathbin.Logic.Small 
import Mathbin.LinearAlgebra.StdBasis

/-!

# Free modules

We introduce a class `module.free R M`, for `R` a `semiring` and `M` an `R`-module and we provide
several basic instances for this class.

Use `finsupp.total_id_surjective` to prove that any module is the quotient of a free module.

## Main definition

* `module.free R M` : the class of free `R`-modules.

-/


universe u v w z

variable (R : Type u) (M : Type v) (N : Type z)

open_locale TensorProduct DirectSum BigOperators

section Basic

variable [Semiringₓ R] [AddCommMonoidₓ M] [Module R M]

/-- `module.free R M` is the statement that the `R`-module `M` is free.-/
class Module.Free : Prop where 
  exists_basis{} : Nonempty (Σ I : Type v, Basis I R M)

theorem Module.free_def [Small.{w} M] : Module.Free R M ↔ ∃ I : Type w, Nonempty (Basis I R M) :=
  ⟨fun h =>
      ⟨Shrink (Set.Range h.exists_basis.some.2), ⟨(Basis.reindexRange h.exists_basis.some.2).reindex (equivShrink _)⟩⟩,
    fun h => ⟨(nonempty_sigma.2 h).map$ fun ⟨i, b⟩ => ⟨Set.Range b, b.reindex_range⟩⟩⟩

theorem Module.free_iff_set : Module.Free R M ↔ ∃ S : Set M, Nonempty (Basis S R M) :=
  ⟨fun h => ⟨Set.Range h.exists_basis.some.2, ⟨Basis.reindexRange h.exists_basis.some.2⟩⟩,
    fun ⟨S, hS⟩ => ⟨nonempty_sigma.2 ⟨S, hS⟩⟩⟩

variable {R M}

theorem Module.Free.of_basis {ι : Type w} (b : Basis ι R M) : Module.Free R M :=
  (Module.free_def R M).2 ⟨Set.Range b, ⟨b.reindex_range⟩⟩

end Basic

namespace Module.Free

section Semiringₓ

variable (R M) [Semiringₓ R] [AddCommMonoidₓ M] [Module R M] [Module.Free R M]

variable [AddCommMonoidₓ N] [Module R N]

/-- If `[finite_free R M]` then `choose_basis_index R M` is the `ι` which indexes the basis
  `ι → M`. -/
@[nolint has_inhabited_instance]
def choose_basis_index :=
  (exists_basis R M).some.1

/-- If `[finite_free R M]` then `choose_basis : ι → M` is the basis.
Here `ι = choose_basis_index R M`. -/
noncomputable def choose_basis : Basis (choose_basis_index R M) R M :=
  (exists_basis R M).some.2

/-- The isomorphism `M ≃ₗ[R] (choose_basis_index R M →₀ R)`. -/
noncomputable def reprₓ : M ≃ₗ[R] choose_basis_index R M →₀ R :=
  (choose_basis R M).repr

/-- The universal property of free modules: giving a functon `(choose_basis_index R M) → N`, for `N`
an `R`-module, is the same as giving an `R`-linear map `M →ₗ[R] N`.

This definition is parameterized over an extra `semiring S`,
such that `smul_comm_class R S M'` holds.
If `R` is commutative, you can set `S := R`; if `R` is not commutative,
you can recover an `add_equiv` by setting `S := ℕ`.
See library note [bundled maps over different rings]. -/
noncomputable def constr {S : Type z} [Semiringₓ S] [Module S N] [SmulCommClass R S N] :
  (choose_basis_index R M → N) ≃ₗ[S] M →ₗ[R] N :=
  Basis.constr (choose_basis R M) S

instance (priority := 100) NoZeroSmulDivisors [NoZeroDivisors R] : NoZeroSmulDivisors R M :=
  let ⟨⟨_, b⟩⟩ := exists_basis R M 
  b.no_zero_smul_divisors

/-- The product of finitely many free modules is free. -/
instance pi {ι : Type _} [Fintype ι] {M : ι → Type _} [∀ i : ι, AddCommGroupₓ (M i)] [∀ i : ι, Module R (M i)]
  [∀ i : ι, Module.Free R (M i)] : Module.Free R (∀ i, M i) :=
  of_basis$ Pi.basis$ fun i => choose_basis R (M i)

/-- The module of finite matrices is free. -/
instance Matrix {n : Type _} [Fintype n] {m : Type _} [Fintype m] : Module.Free R (Matrix n m R) :=
  of_basis$ Matrix.stdBasis R n m

variable {R M N}

theorem of_equiv (e : M ≃ₗ[R] N) : Module.Free R N :=
  of_basis$ (choose_basis R M).map e

/-- A variation of `of_equiv`: the assumption `module.free R P` here is explicit rather than an
instance. -/
theorem of_equiv' {P : Type v} [AddCommMonoidₓ P] [Module R P] (h : Module.Free R P) (e : P ≃ₗ[R] N) :
  Module.Free R N :=
  of_equiv e

variable (R M N)

instance {ι : Type v} : Module.Free R (ι →₀ R) :=
  of_basis (Basis.of_repr (LinearEquiv.refl _ _))

instance {ι : Type v} [Fintype ι] : Module.Free R (ι → R) :=
  of_equiv (Basis.of_repr$ LinearEquiv.refl _ _).equivFun

instance Prod [Module.Free R N] : Module.Free R (M × N) :=
  of_basis$ (choose_basis R M).Prod (choose_basis R N)

instance self : Module.Free R R :=
  of_basis$ Basis.singleton Unit R

instance (priority := 100) of_subsingleton [Subsingleton N] : Module.Free R N :=
  of_basis (Basis.empty N : Basis Pempty R N)

instance Dfinsupp {ι : Type _} (M : ι → Type _) [∀ i : ι, AddCommMonoidₓ (M i)] [∀ i : ι, Module R (M i)]
  [∀ i : ι, Module.Free R (M i)] : Module.Free R (Π₀ i, M i) :=
  of_basis$ Dfinsupp.basis$ fun i => choose_basis R (M i)

instance DirectSum {ι : Type _} (M : ι → Type _) [∀ i : ι, AddCommMonoidₓ (M i)] [∀ i : ι, Module R (M i)]
  [∀ i : ι, Module.Free R (M i)] : Module.Free R (⨁ i, M i) :=
  Module.Free.dfinsupp R M

end Semiringₓ

section CommRingₓ

variable [CommRingₓ R] [AddCommGroupₓ M] [Module R M] [Module.Free R M]

variable [AddCommGroupₓ N] [Module R N] [Module.Free R N]

instance tensor : Module.Free R (M ⊗[R] N) :=
  of_equiv' (of_equiv' (finsupp.free R) (finsuppTensorFinsupp' R _ _).symm)
    (TensorProduct.congr (choose_basis R M).repr (choose_basis R N).repr).symm

end CommRingₓ

section DivisionRing

variable [DivisionRing R] [AddCommGroupₓ M] [Module R M]

instance (priority := 100) of_division_ring : Module.Free R M :=
  of_basis (Basis.ofVectorSpace R M)

end DivisionRing

end Module.Free

