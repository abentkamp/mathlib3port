import Mathbin.Topology.Algebra.Module

/-!
# Weak dual topology

This file defines the weak-* topology on duals of suitable topological modules `E` over suitable
topological semirings `𝕜`. The (weak) dual consists of continuous linear functionals `E →L[𝕜] 𝕜`
from `E` to scalars `𝕜`. The weak-* topology is the coarsest topology on this dual
`weak_dual 𝕜 E := (E →L[𝕜] 𝕜)` w.r.t. which the evaluation maps at all `z : E` are continuous.

The weak dual is a module over `𝕜` if the semiring `𝕜` is commutative.

## Main definitions

The main definitions are the type `weak_dual 𝕜 E` and a topology instance on it.

* `weak_dual 𝕜 E` is a type synonym for `dual 𝕜 E` (when the latter is defined): both are equal to
  the type `E →L[𝕜] 𝕜` of continuous linear maps from a module `E` over `𝕜` to the ring `𝕜`.
* The instance `weak_dual.topological_space` is the weak-* topology on `weak_dual 𝕜 E`, i.e., the
  coarsest topology making the evaluation maps at all `z : E` continuous.

## Main results

We establish that `weak_dual 𝕜 E` has the following structure:
* `weak_dual.has_continuous_add`: The addition in `weak_dual 𝕜 E` is continuous.
* `weak_dual.module`: If the scalars `𝕜` are a commutative semiring, then `weak_dual 𝕜 E` is a
  module over `𝕜`.
* `weak_dual.has_continuous_smul`: If the scalars `𝕜` are a commutative semiring, then the scalar
  multiplication by `𝕜` in `weak_dual 𝕜 E` is continuous.

We prove the following results characterizing the weak-* topology:
* `weak_dual.eval_continuous`: For any `z : E`, the evaluation mapping `weak_dual 𝕜 E → 𝕜` taking
  `x'`to `x' z` is continuous.
* `weak_dual.continuous_of_continuous_eval`: For a mapping to `weak_dual 𝕜 E` to be continuous,
  it suffices that its compositions with evaluations at all points `z : E` are continuous.
* `weak_dual.tendsto_iff_forall_eval_tendsto`: Convergence in `weak_dual 𝕜 E` can be characterized
  in terms of convergence of the evaluations at all points `z : E`.

## Notations

No new notation is introduced.

## Implementation notes

The weak-* topology is defined as the induced topology under the mapping that associates to a dual
element `x'` the functional `E → 𝕜`, when the space `E → 𝕜` of functionals is equipped with the
topology of pointwise convergence (product topology).

Typically one might assume that `𝕜` is a topological semiring in the sense of the typeclasses
`topological_space 𝕜`, `semiring 𝕜`, `has_continuous_add 𝕜`, `has_continuous_mul 𝕜`,
and that the space `E` is a topological module over `𝕜` in the sense of the typeclasses
`topological_space E`, `add_comm_monoid E`, `has_continuous_add E`, `module 𝕜 E`,
`has_continuous_smul 𝕜 E`. The definitions and results are, however, given with weaker assumptions
when possible.

## References

* https://en.wikipedia.org/wiki/Weak_topology#Weak-*_topology

## Tags

weak-star, weak dual

-/


noncomputable section 

open Filter

open_locale TopologicalSpace

universe u v

section WeakStarTopology

/-!
### Weak star topology on duals of topological modules
-/


variable (𝕜 : Type _) [TopologicalSpace 𝕜] [Semiringₓ 𝕜]

variable (E : Type _) [TopologicalSpace E] [AddCommMonoidₓ E] [Module 𝕜 E]

-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler inhabited
-- ././Mathport/Syntax/Translate/Basic.lean:748:9: unsupported derive handler λ α, has_coe_to_fun α (λ _, E → 𝕜)
/-- The weak dual of a topological module `E` over a topological semiring `𝕜` consists of
continuous linear functionals from `E` to scalars `𝕜`. It is a type synonym with the usual dual
(when the latter is defined), but will be equipped with a different topology. -/
def WeakDual :=
  E →L[𝕜] 𝕜 deriving [anonymous], [anonymous]

instance [HasContinuousAdd 𝕜] : AddCommMonoidₓ (WeakDual 𝕜 E) :=
  ContinuousLinearMap.addCommMonoid

namespace WeakDual

/-- The weak-* topology instance `weak_dual.topological_space` on the dual of a topological module
`E` over a topological semiring `𝕜` is defined as the induced topology under the mapping that
associates to a dual element `x' : weak_dual 𝕜 E` the functional `E → 𝕜`, when the space `E → 𝕜`
of functionals is equipped with the topology of pointwise convergence (product topology). -/
instance : TopologicalSpace (WeakDual 𝕜 E) :=
  TopologicalSpace.induced (fun x' : WeakDual 𝕜 E => fun z : E => x' z) Pi.topologicalSpace

theorem coe_fn_continuous : Continuous fun x' : WeakDual 𝕜 E => fun z : E => x' z :=
  continuous_induced_dom

theorem eval_continuous (z : E) : Continuous fun x' : WeakDual 𝕜 E => x' z :=
  (continuous_pi_iff.mp (coe_fn_continuous 𝕜 E)) z

theorem continuous_of_continuous_eval {α : Type u} [TopologicalSpace α] {g : α → WeakDual 𝕜 E}
  (h : ∀ z, Continuous fun a => g a z) : Continuous g :=
  continuous_induced_rng (continuous_pi_iff.mpr h)

theorem tendsto_iff_forall_eval_tendsto {γ : Type u} {F : Filter γ} {ψs : γ → WeakDual 𝕜 E} {ψ : WeakDual 𝕜 E} :
  tendsto ψs F (𝓝 ψ) ↔ ∀ z : E, tendsto (fun i => ψs i z) F (𝓝 (ψ z)) :=
  by 
    rw [←tendsto_pi_nhds]
    constructor
    ·
      intro weak_star_conv 
      exact ((coe_fn_continuous 𝕜 E).Tendsto ψ).comp weak_star_conv
    ·
      intro h_lim_forall 
      rwa [nhds_induced, tendsto_comap_iff]

/-- Addition in `weak_dual 𝕜 E` is continuous. -/
instance [HasContinuousAdd 𝕜] : HasContinuousAdd (WeakDual 𝕜 E) :=
  { continuous_add :=
      by 
        apply continuous_of_continuous_eval 
        intro z 
        have h : Continuous fun p : 𝕜 × 𝕜 => p.1+p.2 := continuous_add 
        exact h.comp ((eval_continuous 𝕜 E z).prod_map (eval_continuous 𝕜 E z)) }

/-- If the scalars `𝕜` are a commutative semiring, then `weak_dual 𝕜 E` is a module over `𝕜`. -/
instance (𝕜 : Type u) [TopologicalSpace 𝕜] [CommSemiringₓ 𝕜] [HasContinuousAdd 𝕜] [HasContinuousMul 𝕜] (E : Type _)
  [TopologicalSpace E] [AddCommGroupₓ E] [Module 𝕜 E] : Module 𝕜 (WeakDual 𝕜 E) :=
  ContinuousLinearMap.module

/-- Scalar multiplication in `weak_dual 𝕜 E` is continuous (when `𝕜` is a commutative
semiring). -/
instance (𝕜 : Type u) [TopologicalSpace 𝕜] [CommSemiringₓ 𝕜] [HasContinuousAdd 𝕜] [HasContinuousMul 𝕜] (E : Type _)
  [TopologicalSpace E] [AddCommGroupₓ E] [Module 𝕜 E] : HasContinuousSmul 𝕜 (WeakDual 𝕜 E) :=
  { continuous_smul :=
      by 
        apply continuous_of_continuous_eval 
        intro z 
        have h : Continuous fun p : 𝕜 × 𝕜 => p.1*p.2 := continuous_mul 
        exact h.comp (continuous_id'.prod_map (eval_continuous 𝕜 E z)) }

end WeakDual

end WeakStarTopology

