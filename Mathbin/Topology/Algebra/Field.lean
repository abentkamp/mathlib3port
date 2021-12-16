import Mathbin.Topology.Algebra.Ring 
import Mathbin.Topology.Algebra.GroupWithZero

/-!
# Topological fields

A topological division ring is a topological ring whose inversion function is continuous at every
non-zero element.

-/


namespace TopologicalRing

open TopologicalSpace Function

variable (R : Type _) [Ringₓ R]

variable [TopologicalSpace R]

/-- The induced topology on units of a topological ring.
This is not a global instance since other topologies could be relevant. Instead there is a class
`induced_units` asserting that something equivalent to this construction holds. -/
def topological_space_units : TopologicalSpace (Units R) :=
  induced (coeₓ : Units R → R) ‹_›

/-- Asserts the topology on units is the induced topology.

 Note: this is not always the correct topology.
 Another good candidate is the subspace topology of $R \times R$,
 with the units embedded via $u \mapsto (u, u^{-1})$.
 These topologies are not (propositionally) equal in general. -/
class induced_units [t : TopologicalSpace$ Units R] : Prop where 
  top_eq : t = induced (coeₓ : Units R → R) ‹_›

variable [TopologicalSpace$ Units R]

theorem units_topology_eq [induced_units R] : ‹TopologicalSpace (Units R)› = induced (coeₓ : Units R → R) ‹_› :=
  induced_units.top_eq

theorem induced_units.continuous_coe [induced_units R] : Continuous (coeₓ : Units R → R) :=
  (units_topology_eq R).symm ▸ continuous_induced_dom

theorem units_embedding [induced_units R] : Embedding (coeₓ : Units R → R) :=
  { induced := units_topology_eq R, inj := fun x y h => Units.ext h }

instance top_monoid_units [TopologicalRing R] [induced_units R] : HasContinuousMul (Units R) :=
  ⟨by 
      let mulR := fun p : R × R => p.1*p.2
      let mulRx := fun p : Units R × Units R => p.1*p.2
      have key : (coeₓ ∘ mulRx) = (mulR ∘ fun p => (p.1.val, p.2.val))
      exact rfl 
      rw [continuous_iff_le_induced, units_topology_eq R, prod_induced_induced, induced_compose, key, ←induced_compose]
      apply induced_mono 
      rw [←continuous_iff_le_induced]
      exact continuous_mul⟩

end TopologicalRing

variable (K : Type _) [DivisionRing K] [TopologicalSpace K]

/-- A topological division ring is a division ring with a topology where all operations are
    continuous, including inversion. -/
class TopologicalDivisionRing extends TopologicalRing K : Prop where 
  continuous_inv : ∀ x : K, x ≠ 0 → ContinuousAt (fun x : K => x⁻¹ : K → K) x

namespace TopologicalDivisionRing

open Filter Set

/-!
In this section, we show that units of a topological division ring endowed with the
induced topology form a topological group. These are not global instances because
one could want another topology on units. To turn on this feature, use:

```lean
local attribute [instance]
topological_ring.topological_space_units topological_division_ring.units_top_group
```
-/


attribute [local instance] TopologicalRing.topologicalSpaceUnits

instance (priority := 100) induced_units : TopologicalRing.InducedUnits K :=
  ⟨rfl⟩

variable [TopologicalDivisionRing K]

theorem units_top_group : TopologicalGroup (Units K) :=
  { TopologicalRing.top_monoid_units K with
    continuous_inv :=
      by 
        have  :
          ((coeₓ : Units K → K) ∘ (fun x => x⁻¹ : Units K → Units K)) = ((fun x => x⁻¹ : K → K) ∘ (coeₓ : Units K → K))
        exact funext Units.coe_inv' 
        rw [continuous_iff_continuous_at]
        intro x 
        rw [ContinuousAt, nhds_induced, nhds_induced, tendsto_iff_comap, comap_comm this]
        apply comap_mono 
        rw [←tendsto_iff_comap, Units.coe_inv']
        exact TopologicalDivisionRing.continuous_inv (x : K) x.ne_zero }

attribute [local instance] units_top_group

theorem continuous_units_inv : Continuous fun x : Units K => (↑x⁻¹ : K) :=
  (TopologicalRing.InducedUnits.continuous_coe K).comp TopologicalGroup.continuous_inv

end TopologicalDivisionRing

section affineHomeomorph

/-!
This section is about affine homeomorphisms from a topological field `𝕜` to itself.
Technically it does not require `𝕜` to be a topological field, a topological ring that
happens to be a field is enough.
-/


variable {𝕜 : Type _} [Field 𝕜] [TopologicalSpace 𝕜] [TopologicalRing 𝕜]

/--
The map `λ x, a * x + b`, as a homeomorphism from `𝕜` (a topological field) to itself, when `a ≠ 0`.
-/
@[simps]
def affineHomeomorph (a b : 𝕜) (h : a ≠ 0) : 𝕜 ≃ₜ 𝕜 :=
  { toFun := fun x => (a*x)+b, invFun := fun y => (y - b) / a,
    left_inv :=
      fun x =>
        by 
          simp only [add_sub_cancel]
          exact mul_div_cancel_left x h,
    right_inv :=
      fun y =>
        by 
          simp [mul_div_cancel' _ h] }

end affineHomeomorph

