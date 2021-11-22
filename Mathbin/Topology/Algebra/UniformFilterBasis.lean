import Mathbin.Topology.Algebra.FilterBasis 
import Mathbin.Topology.Algebra.UniformGroup

/-!
# Uniform properties of neighborhood bases in topological algebra

This files contains properties of filter bases on algebraic structures that also require the theory
of uniform spaces.

The only result so far is a characterization of Cauchy filters in topological groups.

-/


open_locale uniformity Filter

open Filter

namespace AddGroupFilterBasis

variable{G : Type _}[AddCommGroupₓ G](B : AddGroupFilterBasis G)

/-- The uniform space structure associated to an abelian group filter basis via the associated
topological abelian group structure. -/
protected def UniformSpace : UniformSpace G :=
  @TopologicalAddGroup.toUniformSpace G _ B.topology B.is_topological_add_group

/-- The uniform space structure associated to an abelian group filter basis via the associated
topological abelian group structure is compatible with its group structure. -/
protected theorem UniformAddGroup : @UniformAddGroup G B.uniform_space _ :=
  @topological_add_group_is_uniform G _ B.topology B.is_topological_add_group

theorem cauchy_iff {F : Filter G} :
  @Cauchy G B.uniform_space F ↔ F.ne_bot ∧ ∀ U _ : U ∈ B, ∃ (M : _)(_ : M ∈ F), ∀ x y _ : x ∈ M _ : y ∈ M, y - x ∈ U :=
  by 
    letI this := B.uniform_space 
    haveI  := B.uniform_add_group 
    suffices  : F ×ᶠ F ≤ 𝓤 G ↔ ∀ U _ : U ∈ B, ∃ (M : _)(_ : M ∈ F), ∀ x y _ : x ∈ M _ : y ∈ M, y - x ∈ U
    ·
      split  <;> rintro ⟨h', h⟩ <;> refine' ⟨h', _⟩ <;> [rwa [←this], rwa [this]]
    rw [uniformity_eq_comap_nhds_zero G, ←map_le_iff_le_comap]
    change tendsto _ _ _ ↔ _ 
    simp [(basis_sets F).prod_self.tendsto_iff B.nhds_zero_has_basis]

end AddGroupFilterBasis

