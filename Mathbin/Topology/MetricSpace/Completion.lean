import Mathbin.Topology.UniformSpace.Completion 
import Mathbin.Topology.MetricSpace.Isometry 
import Mathbin.Topology.Instances.Real

/-!
# The completion of a metric space

Completion of uniform spaces are already defined in `topology.uniform_space.completion`. We show
here that the uniform space completion of a metric space inherits a metric space structure,
by extending the distance to the completion and checking that it is indeed a distance, and that
it defines the same uniformity as the already defined uniform structure on the completion
-/


open Set Filter UniformSpace UniformSpace.Completion

open_locale Filter

noncomputable theory

universe u

variable{α : Type u}[PseudoMetricSpace α]

namespace Metric

/-- The distance on the completion is obtained by extending the distance on the original space,
by uniform continuity. -/
instance  : HasDist (completion α) :=
  ⟨completion.extension₂ dist⟩

/-- The new distance is uniformly continuous. -/
protected theorem completion.uniform_continuous_dist :
  UniformContinuous fun p : completion α × completion α => dist p.1 p.2 :=
  uniform_continuous_extension₂ dist

/-- The new distance is an extension of the original distance. -/
protected theorem completion.dist_eq (x y : α) : dist (x : completion α) y = dist x y :=
  completion.extension₂_coe_coe uniform_continuous_dist _ _

protected theorem completion.dist_self (x : completion α) : dist x x = 0 :=
  by 
    apply induction_on x
    ·
      refine' is_closed_eq _ continuous_const 
      exact
        (completion.uniform_continuous_dist.continuous.comp (Continuous.prod_mk continuous_id continuous_id : _) : _)
    ·
      intro a 
      rw [completion.dist_eq, dist_self]

protected theorem completion.dist_comm (x y : completion α) : dist x y = dist y x :=
  by 
    apply induction_on₂ x y
    ·
      refine' is_closed_eq completion.uniform_continuous_dist.continuous _ 
      exact completion.uniform_continuous_dist.continuous.comp (@continuous_swap (completion α) (completion α) _ _)
    ·
      intro a b 
      rw [completion.dist_eq, completion.dist_eq, dist_comm]

protected theorem completion.dist_triangle (x y z : completion α) : dist x z ≤ dist x y+dist y z :=
  by 
    apply induction_on₃ x y z
    ·
      refine' is_closed_le _ (Continuous.add _ _)
      ·
        have  : Continuous fun p : completion α × completion α × completion α => (p.1, p.2.2) :=
          Continuous.prod_mk continuous_fst (Continuous.comp continuous_snd continuous_snd)
        exact (completion.uniform_continuous_dist.continuous.comp this : _)
      ·
        have  : Continuous fun p : completion α × completion α × completion α => (p.1, p.2.1) :=
          Continuous.prod_mk continuous_fst (continuous_fst.comp continuous_snd)
        exact (completion.uniform_continuous_dist.continuous.comp this : _)
      ·
        have  : Continuous fun p : completion α × completion α × completion α => (p.2.1, p.2.2) :=
          Continuous.prod_mk (continuous_fst.comp continuous_snd) (Continuous.comp continuous_snd continuous_snd)
        exact (Continuous.comp completion.uniform_continuous_dist.continuous this : _)
    ·
      intro a b c 
      rw [completion.dist_eq, completion.dist_eq, completion.dist_eq]
      exact dist_triangle a b c

/-- Elements of the uniformity (defined generally for completions) can be characterized in terms
of the distance. -/
protected theorem completion.mem_uniformity_dist (s : Set (completion α × completion α)) :
  s ∈ uniformity (completion α) ↔ ∃ (ε : _)(_ : ε > 0), ∀ {a b}, dist a b < ε → (a, b) ∈ s :=
  by 
    split 
    ·
      intro hs 
      rcases mem_uniformity_is_closed hs with ⟨t, ht, ⟨tclosed, ts⟩⟩
      have A : { x : α × α | (coeₓ x.1, coeₓ x.2) ∈ t } ∈ uniformity α :=
        uniform_continuous_def.1 (uniform_continuous_coe α) t ht 
      rcases mem_uniformity_dist.1 A with ⟨ε, εpos, hε⟩
      refine' ⟨ε, εpos, fun x y hxy => _⟩
      have  : ε ≤ dist x y ∨ (x, y) ∈ t
      ·
        apply induction_on₂ x y
        ·
          have  :
            { x : completion α × completion α | ε ≤ dist x.fst x.snd ∨ (x.fst, x.snd) ∈ t } =
              { p : completion α × completion α | ε ≤ dist p.1 p.2 } ∪ t
          ·
            ext <;> simp 
          rw [this]
          apply IsClosed.union _ tclosed 
          exact is_closed_le continuous_const completion.uniform_continuous_dist.continuous
        ·
          intro x y 
          rw [completion.dist_eq]
          byCases' h : ε ≤ dist x y
          ·
            exact Or.inl h
          ·
            have Z := hε (not_leₓ.1 h)
            simp only [Set.mem_set_of_eq] at Z 
            exact Or.inr Z 
      simp only [not_le.mpr hxy, false_orₓ, not_leₓ] at this 
      exact ts this
    ·
      rintro ⟨ε, εpos, hε⟩
      let r : Set (ℝ × ℝ) := { p | dist p.1 p.2 < ε }
      have  : r ∈ uniformity ℝ := Metric.dist_mem_uniformity εpos 
      have T := uniform_continuous_def.1 (@completion.uniform_continuous_dist α _) r this 
      simp only [uniformity_prod_eq_prod, mem_prod_iff, exists_prop, Filter.mem_map, Set.mem_set_of_eq] at T 
      rcases T with ⟨t1, ht1, t2, ht2, ht⟩
      refine' mem_of_superset ht1 _ 
      have A : ∀ a b : completion α, (a, b) ∈ t1 → dist a b < ε
      ·
        intro a b hab 
        have  : ((a, b), (a, a)) ∈ Set.Prod t1 t2 := ⟨hab, refl_mem_uniformity ht2⟩
        have I := ht this 
        simp [completion.dist_self, Real.dist_eq, completion.dist_comm] at I 
        exact lt_of_le_of_ltₓ (le_abs_self _) I 
      show t1 ⊆ s
      ·
        rintro ⟨a, b⟩ hp 
        have  : dist a b < ε := A a b hp 
        exact hε this

/-- If two points are at distance 0, then they coincide. -/
protected theorem completion.eq_of_dist_eq_zero (x y : completion α) (h : dist x y = 0) : x = y :=
  by 
    have  : SeparatedSpace (completion α) :=
      by 
        infer_instance 
    refine' separated_def.1 this x y fun s hs => _ 
    rcases(completion.mem_uniformity_dist s).1 hs with ⟨ε, εpos, hε⟩
    rw [←h] at εpos 
    exact hε εpos

-- error in Topology.MetricSpace.Completion: ././Mathport/Syntax/Translate/Basic.lean:176:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- Reformulate `completion.mem_uniformity_dist` in terms that are suitable for the definition
of the metric space structure. -/
protected
theorem completion.uniformity_dist' : «expr = »(uniformity (completion α), «expr⨅ , »((ε : {ε : exprℝ() // «expr < »(0, ε)}), expr𝓟() {p | «expr < »(dist p.1 p.2, ε.val)})) :=
begin
  ext [] [ident s] [],
  rw [expr mem_infi_of_directed] [],
  { simp [] [] [] ["[", expr completion.mem_uniformity_dist, ",", expr subset_def, "]"] [] [] },
  { rintro ["⟨", ident r, ",", ident hr, "⟩", "⟨", ident p, ",", ident hp, "⟩"],
    use [expr ⟨min r p, lt_min hr hp⟩],
    simp [] [] [] ["[", expr lt_min_iff, ",", expr («expr ≥ »), "]"] [] [] { contextual := tt } }
end

protected theorem completion.uniformity_dist :
  uniformity (completion α) = ⨅(ε : _)(_ : ε > 0), 𝓟 { p | dist p.1 p.2 < ε } :=
  by 
    simpa [infi_subtype] using @completion.uniformity_dist' α _

/-- Metric space structure on the completion of a pseudo_metric space. -/
instance completion.metric_space : MetricSpace (completion α) :=
  { dist_self := completion.dist_self, eq_of_dist_eq_zero := completion.eq_of_dist_eq_zero,
    dist_comm := completion.dist_comm, dist_triangle := completion.dist_triangle,
    toUniformSpace :=
      by 
        infer_instance,
    uniformity_dist := completion.uniformity_dist }

/-- The embedding of a metric space in its completion is an isometry. -/
theorem completion.coe_isometry : Isometry (coeₓ : α → completion α) :=
  isometry_emetric_iff_metric.2 completion.dist_eq

end Metric

