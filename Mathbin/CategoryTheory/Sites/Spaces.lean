import Mathbin.Topology.Opens 
import Mathbin.CategoryTheory.Sites.Grothendieck 
import Mathbin.CategoryTheory.Sites.Pretopology 
import Mathbin.CategoryTheory.Limits.Lattice

/-!
# Grothendieck topology on a topological space

Define the Grothendieck topology and the pretopology associated to a topological space, and show
that the pretopology induces the topology.

The covering (pre)sieves on `X` are those for which the union of domains contains `X`.

## Tags

site, Grothendieck topology, space

## References

* [https://ncatlab.org/nlab/show/Grothendieck+topology][nlab]
* [S. MacLane, I. Moerdijk, *Sheaves in Geometry and Logic*][MM92]

## Implementation notes

We define the two separately, rather than defining the Grothendieck topology as that generated
by the pretopology for the purpose of having nice definitional properties for the sieves.
-/


universe u

namespace Opens

variable (T : Type u) [TopologicalSpace T]

open CategoryTheory TopologicalSpace CategoryTheory.Limits

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » X)
/-- The Grothendieck topology associated to a topological space. -/
def grothendieck_topology : grothendieck_topology (opens T) :=
  { Sieves := fun X S => ∀ x _ : x ∈ X, ∃ (U : _)(f : U ⟶ X), S f ∧ x ∈ U,
    top_mem' := fun X x hx => ⟨_, 𝟙 _, trivialₓ, hx⟩,
    pullback_stable' :=
      fun X Y S f hf y hy =>
        by 
          rcases hf y (f.le hy) with ⟨U, g, hg, hU⟩
          refine' ⟨U⊓Y, hom_of_le inf_le_right, _, hU, hy⟩
          apply S.downward_closed hg (hom_of_le inf_le_left),
    transitive' :=
      fun X S hS R hR x hx =>
        by 
          rcases hS x hx with ⟨U, f, hf, hU⟩
          rcases hR hf _ hU with ⟨V, g, hg, hV⟩
          exact ⟨_, g ≫ f, hg, hV⟩ }

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » X)
/-- The Grothendieck pretopology associated to a topological space. -/
def pretopology : pretopology (opens T) :=
  { Coverings := fun X R => ∀ x _ : x ∈ X, ∃ (U : _)(f : U ⟶ X), R f ∧ x ∈ U,
    has_isos :=
      fun X Y f i x hx =>
        by 
          exact ⟨_, _, presieve.singleton_self _, (inv f).le hx⟩,
    pullbacks :=
      fun X Y f S hS x hx =>
        by 
          rcases hS _ (f.le hx) with ⟨U, g, hg, hU⟩
          refine' ⟨_, _, presieve.pullback_arrows.mk _ _ hg, _⟩
          have  : U⊓Y ≤ pullback g f 
          refine' le_of_hom (pullback.lift (hom_of_le inf_le_left) (hom_of_le inf_le_right) rfl)
          apply this ⟨hU, hx⟩,
    Transitive :=
      fun X S Ti hS hTi x hx =>
        by 
          rcases hS x hx with ⟨U, f, hf, hU⟩
          rcases hTi f hf x hU with ⟨V, g, hg, hV⟩
          exact ⟨_, _, ⟨_, g, f, hf, hg, rfl⟩, hV⟩ }

/--
The pretopology associated to a space induces the Grothendieck topology associated to the space.
-/
@[simp]
theorem pretopology_to_grothendieck :
  pretopology.to_grothendieck _ (Opens.pretopology T) = Opens.grothendieckTopology T :=
  by 
    apply le_antisymmₓ
    ·
      rintro X S ⟨R, hR, RS⟩ x hx 
      rcases hR x hx with ⟨U, f, hf, hU⟩
      exact ⟨_, f, RS _ hf, hU⟩
    ·
      intro X S hS 
      exact ⟨S, hS, le_reflₓ _⟩

end Opens

