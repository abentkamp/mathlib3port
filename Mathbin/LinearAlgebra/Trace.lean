import Mathbin.LinearAlgebra.Matrix.ToLin 
import Mathbin.LinearAlgebra.Matrix.Trace

/-!
# Trace of a linear map

This file defines the trace of a linear map.

See also `linear_algebra/matrix/trace.lean` for the trace of a matrix.

## Tags

linear_map, trace, diagonal

-/


noncomputable theory

universe u v w

namespace LinearMap

open_locale BigOperators

open_locale Matrix

open FiniteDimensional

section 

variable(R : Type u)[CommRingₓ R]{M : Type v}[AddCommGroupₓ M][Module R M]

variable{ι : Type w}[DecidableEq ι][Fintype ι]

variable{κ : Type _}[DecidableEq κ][Fintype κ]

variable(b : Basis ι R M)(c : Basis κ R M)

/-- The trace of an endomorphism given a basis. -/
def trace_aux : (M →ₗ[R] M) →ₗ[R] R :=
  Matrix.trace ι R R ∘ₗ «expr↑ » (LinearMap.toMatrix b b)

theorem trace_aux_def (b : Basis ι R M) (f : M →ₗ[R] M) :
  trace_aux R b f = Matrix.trace ι R R (LinearMap.toMatrix b b f) :=
  rfl

theorem trace_aux_eq : trace_aux R b = trace_aux R c :=
  LinearMap.ext$
    fun f =>
      calc
        Matrix.trace ι R R (LinearMap.toMatrix b b f) =
          Matrix.trace ι R R (LinearMap.toMatrix b b ((LinearMap.id.comp f).comp LinearMap.id)) :=
        by 
          rw [LinearMap.id_comp, LinearMap.comp_id]
        _ =
          Matrix.trace ι R R
            (LinearMap.toMatrix c b LinearMap.id ⬝ LinearMap.toMatrix c c f ⬝ LinearMap.toMatrix b c LinearMap.id) :=
        by 
          rw [LinearMap.to_matrix_comp _ c, LinearMap.to_matrix_comp _ c]
        _ =
          Matrix.trace κ R R
            (LinearMap.toMatrix c c f ⬝ LinearMap.toMatrix b c LinearMap.id ⬝ LinearMap.toMatrix c b LinearMap.id) :=
        by 
          rw [Matrix.mul_assoc, Matrix.trace_mul_comm]
        _ = Matrix.trace κ R R (LinearMap.toMatrix c c ((f.comp LinearMap.id).comp LinearMap.id)) :=
        by 
          rw [LinearMap.to_matrix_comp _ b, LinearMap.to_matrix_comp _ c]
        _ = Matrix.trace κ R R (LinearMap.toMatrix c c f) :=
        by 
          rw [LinearMap.comp_id, LinearMap.comp_id]
        

open_locale Classical

variable(R)(M)

/-- Trace of an endomorphism independent of basis. -/
def trace : (M →ₗ[R] M) →ₗ[R] R :=
  if H : ∃ s : Finset M, Nonempty (Basis s R M) then trace_aux R H.some_spec.some else 0

variable(R){M}

/-- Auxiliary lemma for `trace_eq_matrix_trace`. -/
theorem trace_eq_matrix_trace_of_finset {s : Finset M} (b : Basis s R M) (f : M →ₗ[R] M) :
  trace R M f = Matrix.trace s R R (LinearMap.toMatrix b b f) :=
  have  : ∃ s : Finset M, Nonempty (Basis s R M) := ⟨s, ⟨b⟩⟩
  by 
    rw [trace, dif_pos this, ←trace_aux_def]
    congr 1
    apply trace_aux_eq

-- error in LinearAlgebra.Trace: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem trace_eq_matrix_trace
(f : «expr →ₗ[ ] »(M, R, M)) : «expr = »(trace R M f, matrix.trace ι R R (linear_map.to_matrix b b f)) :=
if hR : nontrivial R then by haveI [] [] [":=", expr hR]; rw ["[", expr trace_eq_matrix_trace_of_finset R b.reindex_finset_range, ",", "<-", expr trace_aux_def, ",", "<-", expr trace_aux_def, ",", expr trace_aux_eq R b, "]"] [] else @subsingleton.elim _ (not_nontrivial_iff_subsingleton.mp hR) _ _

theorem trace_mul_comm (f g : M →ₗ[R] M) : trace R M (f*g) = trace R M (g*f) :=
  if H : ∃ s : Finset M, Nonempty (Basis s R M) then
    let ⟨s, ⟨b⟩⟩ := H 
    by 
      simpRw [trace_eq_matrix_trace R b, LinearMap.to_matrix_mul]
      apply Matrix.trace_mul_comm
  else
    by 
      rw [trace, dif_neg H, LinearMap.zero_apply, LinearMap.zero_apply]

/-- The trace of an endomorphism is invariant under conjugation -/
@[simp]
theorem trace_conj (g : M →ₗ[R] M) (f : Units (M →ₗ[R] M)) : trace R M ((«expr↑ » f*g)*«expr↑ » (f⁻¹)) = trace R M g :=
  by 
    rw [trace_mul_comm]
    simp 

/-- The trace of an endomorphism is invariant under conjugation -/
@[simp]
theorem trace_conj' (f g : M →ₗ[R] M) [Invertible f] : trace R M ((f*g)*⅟ f) = trace R M g :=
  by 
    rw [trace_mul_comm]
    simp 

end 

section 

variable(R : Type u)[Field R]{M : Type v}[AddCommGroupₓ M][Module R M]

/-- The trace of the identity endomorphism is the dimension of the vector space -/
@[simp]
theorem trace_one : trace R M 1 = (finrank R M : R) :=
  by 
    classical 
    byCases' H : ∃ s : Finset M, Nonempty (Basis s R M)
    ·
      obtain ⟨s, ⟨b⟩⟩ := H 
      rw [trace_eq_matrix_trace R b, to_matrix_one, finrank_eq_card_finset_basis b]
      simp 
    ·
      suffices  : (finrank R M : R) = 0
      ·
        simp [this, trace, H]
      simp [finrank_eq_zero_of_not_exists_basis H]

end 

end LinearMap

