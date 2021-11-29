import Mathbin.Analysis.NormedSpace.ContinuousAffineMap 
import Mathbin.Analysis.Calculus.TimesContDiff

/-!
# Smooth affine maps

This file contains results about smoothness of affine maps.

## Main definitions:

 * `continuous_affine_map.times_cont_diff`: a continuous affine map is smooth

-/


namespace ContinuousAffineMap

variable {𝕜 V W : Type _} [NondiscreteNormedField 𝕜]

variable [NormedGroup V] [NormedSpace 𝕜 V]

variable [NormedGroup W] [NormedSpace 𝕜 W]

/-- A continuous affine map between normed vector spaces is smooth. -/
theorem TimesContDiff {n : WithTop ℕ} (f : V →A[𝕜] W) : TimesContDiff 𝕜 n f :=
  by 
    rw [f.decomp]
    apply f.cont_linear.times_cont_diff.add 
    simp only 
    exact times_cont_diff_const

end ContinuousAffineMap

