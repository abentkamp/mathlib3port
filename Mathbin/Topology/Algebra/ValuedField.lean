import Mathbin.Topology.Algebra.Valuation 
import Mathbin.Topology.Algebra.WithZeroTopology 
import Mathbin.Topology.Algebra.UniformField

/-!
# Valued fields and their completions

In this file we study the topology of a field `K` endowed with a valuation (in our application
to adic spaces, `K` will be the valuation field associated to some valuation on a ring, defined in
valuation.basic).

We already know from valuation.topology that one can build a topology on `K` which
makes it a topological ring.

The first goal is to show `K` is a topological *field*, ie inversion is continuous
at every non-zero element.

The next goal is to prove `K` is a *completable* topological field. This gives us
a completion `hat K` which is a topological field. We also prove that `K` is automatically
separated, so the map from `K` to `hat K` is injective.

Then we extend the valuation given on `K` to a valuation on `hat K`.
-/


open Filter Set

open_locale TopologicalSpace

section DivisionRing

variable {K : Type _} [DivisionRing K]

section ValuationTopologicalDivisionRing

section InversionEstimate

variable {Γ₀ : Type _} [LinearOrderedCommGroupWithZero Γ₀] (v : Valuation K Γ₀)

theorem Valuation.inversion_estimate {x y : K} {γ : Units Γ₀} (y_ne : y ≠ 0) (h : v (x - y) < min (γ*v y*v y) (v y)) :
  v (x⁻¹ - y⁻¹) < γ :=
  by 
    have hyp1 : v (x - y) < γ*v y*v y 
    exact lt_of_lt_of_leₓ h (min_le_leftₓ _ _)
    have hyp1' : (v (x - y)*(v y*v y)⁻¹) < γ 
    exact mul_inv_lt_of_lt_mul₀ hyp1 
    have hyp2 : v (x - y) < v y 
    exact lt_of_lt_of_leₓ h (min_le_rightₓ _ _)
    have key : v x = v y 
    exact Valuation.map_eq_of_sub_lt v hyp2 
    have x_ne : x ≠ 0
    ·
      intro h 
      apply y_ne 
      rw [h, v.map_zero] at key 
      exact v.zero_iff.1 key.symm 
    have decomp : x⁻¹ - y⁻¹ = (x⁻¹*y - x)*y⁻¹
    ·
      rw [mul_sub_left_distrib, sub_mul, mul_assocₓ, show (y*y⁻¹) = 1 from mul_inv_cancel y_ne,
        show (x⁻¹*x) = 1 from inv_mul_cancel x_ne, mul_oneₓ, one_mulₓ]
    calc v (x⁻¹ - y⁻¹) = v ((x⁻¹*y - x)*y⁻¹) :=
      by 
        rw [decomp]_ = (v (x⁻¹)*v$ y - x)*v (y⁻¹) :=
      by 
        repeat' 
          rw [Valuation.map_mul]_ = (v x⁻¹*v$ y - x)*v y⁻¹ :=
      by 
        rw [v.map_inv, v.map_inv]_ = (v$ y - x)*(v y*v y)⁻¹ :=
      by 
        rw [mul_assocₓ, mul_commₓ, key, mul_assocₓ, mul_inv_rev₀]_ = (v$ y - x)*(v y*v y)⁻¹ :=
      rfl _ = (v$ x - y)*(v y*v y)⁻¹ :=
      by 
        rw [Valuation.map_sub_swap]_ < γ :=
      hyp1'

end InversionEstimate

open Valued

/-- The topology coming from a valuation on a division ring makes it a topological division ring
    [BouAC, VI.5.1 middle of Proposition 1] -/
instance (priority := 100) Valued.topological_division_ring [Valued K] : TopologicalDivisionRing K :=
  { (by 
      infer_instance :
    TopologicalRing K) with
    continuous_inv :=
      by 
        intro x x_ne s s_in 
        cases' valued.mem_nhds.mp s_in with γ hs 
        clear s_in 
        rw [mem_map, Valued.mem_nhds]
        change ∃ γ : Units (Valued.Γ₀ K), { y : K | v (y - x) < γ } ⊆ { x : K | x⁻¹ ∈ s }
        have vx_ne := (Valuation.ne_zero_iff$ v).mpr x_ne 
        let γ' := Units.mk0 _ vx_ne 
        use min (γ*γ'*γ') γ' 
        intro y y_in 
        apply hs 
        simp only [mem_set_of_eq] at y_in 
        rw [Units.min_coe, Units.coe_mul, Units.coe_mul] at y_in 
        exact Valuation.inversion_estimate _ x_ne y_in }

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- A valued division ring is separated. -/
  instance
    ( priority := 100 )
    ValuedRing.separated
    [ Valued K ] : SeparatedSpace K
    :=
      by
        apply TopologicalAddGroup.separated_of_zero_sep
          intro x x_ne
          refine' ⟨ { k | v k < v x } , _ , fun h => lt_irreflₓ _ h ⟩
          rw [ Valued.mem_nhds ]
          have vx_ne := Valuation.ne_zero_iff $ v . mpr x_ne
          let γ' := Units.mk0 _ vx_ne
          exact ⟨ γ' , fun y hy => by simpa using hy ⟩

section 

attribute [local instance] LinearOrderedCommGroupWithZero.topologicalSpace

open Valued

theorem Valued.continuous_valuation [Valued K] : Continuous (v : K → Γ₀ K) :=
  by 
    rw [continuous_iff_continuous_at]
    intro x 
    classical 
    byCases' h : x = 0
    ·
      rw [h]
      change tendsto _ _ (𝓝 (v (0 : K)))
      erw [Valuation.map_zero]
      rw [LinearOrderedCommGroupWithZero.tendsto_zero]
      intro γ 
      rw [Valued.mem_nhds_zero]
      use γ, Set.Subset.refl _
    ·
      change tendsto _ _ _ 
      have v_ne : v x ≠ 0 
      exact (Valuation.ne_zero_iff _).mpr h 
      rw [LinearOrderedCommGroupWithZero.tendsto_of_ne_zero v_ne]
      apply Valued.loc_const v_ne

end 

end ValuationTopologicalDivisionRing

end DivisionRing

section ValuationOnValuedFieldCompletion

open UniformSpace

variable {K : Type _} [Field K] [Valued K]

open Valued UniformSpace

local notation "hat " => completion

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (M «expr ∈ » F)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » M)
/-- A valued field is completable. -/
instance (priority := 100) Valued.completable : CompletableTopField K :=
  { ValuedRing.separated with
    nice :=
      by 
        rintro F hF h0 
        have  : ∃ (γ₀ : Units (Γ₀ K))(M : _)(_ : M ∈ F), ∀ x _ : x ∈ M, (γ₀ : Γ₀ K) ≤ v x
        ·
          rcases filter.inf_eq_bot_iff.mp h0 with ⟨U, U_in, M, M_in, H⟩
          rcases valued.mem_nhds_zero.mp U_in with ⟨γ₀, hU⟩
          exists γ₀, M, M_in 
          intro x xM 
          apply le_of_not_ltₓ _ 
          intro hyp 
          have  : x ∈ U ∩ M := ⟨hU hyp, xM⟩
          rwa [H] at this 
        rcases this with ⟨γ₀, M₀, M₀_in, H₀⟩
        rw [Valued.cauchy_iff] at hF⊢
        refine' ⟨hF.1.map _, _⟩
        replace hF := hF.2
        intro γ 
        rcases hF (min ((γ*γ₀)*γ₀) γ₀) with ⟨M₁, M₁_in, H₁⟩
        clear hF 
        use (fun x : K => x⁻¹) '' (M₀ ∩ M₁)
        constructor
        ·
          rw [mem_map]
          apply mem_of_superset (Filter.inter_mem M₀_in M₁_in)
          exact subset_preimage_image _ _
        ·
          rintro _ _ ⟨x, ⟨x_in₀, x_in₁⟩, rfl⟩ ⟨y, ⟨y_in₀, y_in₁⟩, rfl⟩
          simp only [mem_set_of_eq]
          specialize H₁ x y x_in₁ y_in₁ 
          replace x_in₀ := H₀ x x_in₀ 
          replace y_in₀ := H₀ y y_in₀ 
          clear H₀ 
          apply Valuation.inversion_estimate
          ·
            have  : v x ≠ 0
            ·
              intro h 
              rw [h] at x_in₀ 
              simpa using x_in₀ 
            exact (Valuation.ne_zero_iff _).mp this
          ·
            refine' lt_of_lt_of_leₓ H₁ _ 
            rw [Units.min_coe]
            apply min_le_min _ x_in₀ 
            rw [mul_assocₓ]
            have  : ((γ₀*γ₀ : Units (Γ₀ K)) : Γ₀ K) ≤ v x*v x 
            exact
              calc ((↑γ₀)*↑γ₀) ≤ (↑γ₀)*v x := mul_le_mul_left' x_in₀ (↑γ₀)
                _ ≤ _ := mul_le_mul_right' x_in₀ (v x)
                
            rw [Units.coe_mul]
            exact mul_le_mul_left' this γ }

attribute [local instance] LinearOrderedCommGroupWithZero.topologicalSpace

/-- The extension of the valuation of a valued field to the completion of the field. -/
noncomputable def Valued.extension : hat  K → Γ₀ K :=
  completion.dense_inducing_coe.extend (v : K → Γ₀ K)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (V «expr ∈ » expr𝓝() (1 : exprhat() K))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (V' «expr ∈ » expr𝓝() (1 : exprhat() K))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x y «expr ∈ » V')
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y₀ «expr ∈ » V')
-- failed to parenthesize: no declaration of attribute [parenthesizer] found for 'Lean.Meta.solveByElim'
-- failed to format: no declaration of attribute [formatter] found for 'Lean.Meta.solveByElim'
theorem
  Valued.continuous_extension
  : Continuous ( Valued.extension : hat K → Γ₀ K )
  :=
    by
      refine' completion.dense_inducing_coe.continuous_extend _
        intro x₀
        byCases' h : x₀ = coeₓ 0
        ·
          refine' ⟨ 0 , _ ⟩
            erw [ h , ← completion.dense_inducing_coe.to_inducing.nhds_eq_comap ] <;> try infer_instance
            rw [ LinearOrderedCommGroupWithZero.tendsto_zero ]
            intro γ₀
            rw [ Valued.mem_nhds ]
            exact ⟨ γ₀ , by simp ⟩
        ·
          have preimage_one : v ⁻¹' { ( 1 : Γ₀ K ) } ∈ 𝓝 ( 1 : K )
            ·
              have : v ( 1 : K ) ≠ 0
                · rw [ Valuation.map_one ] exact zero_ne_one.symm
                convert Valued.loc_const this
                ext x
                rw [ Valuation.map_one , mem_preimage , mem_singleton_iff , mem_set_of_eq ]
            obtain ⟨ V , V_in , hV ⟩ : ∃ ( V : _ ) ( _ : V ∈ 𝓝 ( 1 : hat K ) ) , ∀ x : K , ( x : hat K ) ∈ V → v x = 1
            · rwa [ completion.dense_inducing_coe.nhds_eq_comap , mem_comap ] at preimage_one
            have
              :
                ∃
                  ( V' : _ ) ( _ : V' ∈ 𝓝 ( 1 : hat K ) )
                  ,
                  ( 0 : hat K ) ∉ V' ∧ ∀ x y _ : x ∈ V' _ : y ∈ V' , x * y ⁻¹ ∈ V
            ·
              have : tendsto fun p : hat K × hat K => p . 1 * p . 2 ⁻¹ 𝓝 1 . Prod 𝓝 1 𝓝 1
                ·
                  rw [ ← nhds_prod_eq ]
                    conv => congr skip skip rw [ ← one_mulₓ ( 1 : hat K ) ]
                    refine' tendsto.mul continuous_fst.continuous_at tendsto.comp _ continuous_snd.continuous_at
                    convert TopologicalDivisionRing.continuous_inv ( 1 : hat K ) zero_ne_one.symm
                    exact inv_one.symm
                rcases tendsto_prod_self_iff.mp this V V_in with ⟨ U , U_in , hU ⟩
                let hatKstar := ( { 0 } ᶜ : Set $ hat K )
                have : hatKstar ∈ 𝓝 ( 1 : hat K )
                exact compl_singleton_mem_nhds zero_ne_one.symm
                use U ∩ hatKstar , Filter.inter_mem U_in this
                constructor
                · rintro ⟨ h , h' ⟩ rw [ mem_compl_singleton_iff ] at h' exact h' rfl
                · rintro x y ⟨ hx , _ ⟩ ⟨ hy , _ ⟩ apply hU <;> assumption
            rcases this with ⟨ V' , V'_in , zeroV' , hV' ⟩
            have nhds_right : fun x => x * x₀ '' V' ∈ 𝓝 x₀
            ·
              have l : Function.LeftInverse fun x : hat K => x * x₀ ⁻¹ fun x : hat K => x * x₀
                · intro x simp only [ mul_assocₓ , mul_inv_cancel h , mul_oneₓ ]
                have r : Function.RightInverse fun x : hat K => x * x₀ ⁻¹ fun x : hat K => x * x₀
                · intro x simp only [ mul_assocₓ , inv_mul_cancel h , mul_oneₓ ]
                have c : Continuous fun x : hat K => x * x₀ ⁻¹
                exact continuous_id.mul continuous_const
                rw [ image_eq_preimage_of_inverse l r ]
                rw [ ← mul_inv_cancel h ] at V'_in
                exact c.continuous_at V'_in
            have : ∃ ( z₀ : K ) ( y₀ : _ ) ( _ : y₀ ∈ V' ) , coeₓ z₀ = y₀ * x₀ ∧ z₀ ≠ 0
            ·
              rcases DenseRange.mem_nhds completion.dense_range_coe nhds_right with ⟨ z₀ , y₀ , y₀_in , h ⟩
                refine' ⟨ z₀ , y₀ , y₀_in , ⟨ h.symm , _ ⟩ ⟩
                intro hz
                rw [ hz ] at h
                cases zero_eq_mul.mp h.symm <;> finish
            rcases this with ⟨ z₀ , y₀ , y₀_in , hz₀ , z₀_ne ⟩
            have vz₀_ne : v z₀ ≠ 0 := by rwa [ Valuation.ne_zero_iff ]
            refine' ⟨ v z₀ , _ ⟩
            rw [ LinearOrderedCommGroupWithZero.tendsto_of_ne_zero vz₀_ne , mem_comap ]
            use fun x => x * x₀ '' V' , nhds_right
            intro x x_in
            rcases mem_preimage . 1 x_in with ⟨ y , y_in , hy ⟩
            clear x_in
            change y * x₀ = coeₓ x at hy
            have : v x * z₀ ⁻¹ = 1
            ·
              apply hV
                have : ( ( z₀ ⁻¹ : K ) : hat K ) = z₀ ⁻¹
                exact RingHom.map_inv ( completion.coe_ring_hom : K →+* hat K ) z₀
                rw
                  [
                    completion.coe_mul
                      ,
                      this
                      ,
                      ← hy
                      ,
                      hz₀
                      ,
                      mul_inv₀
                      ,
                      mul_commₓ y₀ ⁻¹
                      ,
                      ← mul_assocₓ
                      ,
                      mul_assocₓ y
                      ,
                      mul_inv_cancel h
                      ,
                      mul_oneₓ
                    ]
                solveByElim
            calc
              v x = v x * z₀ ⁻¹ * z₀ := by rw [ mul_assocₓ , inv_mul_cancel z₀_ne , mul_oneₓ ]
                _ = v x * z₀ ⁻¹ * v z₀ := Valuation.map_mul _ _ _
                _ = v z₀ := by rw [ this , one_mulₓ ]

@[normCast]
theorem Valued.extension_extends (x : K) : Valued.extension (x : hat  K) = v x :=
  by 
    have  : T2Space (Valued.Γ₀ K) := RegularSpace.t2_space _ 
    refine' completion.dense_inducing_coe.extend_eq_of_tendsto _ 
    rw [←completion.dense_inducing_coe.nhds_eq_comap]
    exact valued.continuous_valuation.continuous_at

/-- the extension of a valuation on a division ring to its completion. -/
noncomputable def Valued.extensionValuation : Valuation (hat  K) (Γ₀ K) :=
  { toFun := Valued.extension,
    map_zero' :=
      by 
        simpa [←v.map_zero, ←Valued.extension_extends (0 : K)],
    map_one' :=
      by 
        rw [←completion.coe_one, Valued.extension_extends (1 : K)]
        exact Valuation.map_one _,
    map_mul' :=
      fun x y =>
        by 
          apply completion.induction_on₂ x y
          ·
            have c1 : Continuous fun x : hat  K × hat  K => Valued.extension (x.1*x.2)
            exact valued.continuous_extension.comp (continuous_fst.mul continuous_snd)
            have c2 : Continuous fun x : hat  K × hat  K => Valued.extension x.1*Valued.extension x.2 
            exact
              (valued.continuous_extension.comp continuous_fst).mul (valued.continuous_extension.comp continuous_snd)
            exact is_closed_eq c1 c2
          ·
            intro x y 
            normCast 
            exact Valuation.map_mul _ _ _,
    map_add' :=
      fun x y =>
        by 
          rw [le_max_iff]
          apply completion.induction_on₂ x y
          ·
            have cont : Continuous (Valued.extension : hat  K → Γ₀ K) := Valued.continuous_extension 
            exact
              (is_closed_le (cont.comp continuous_add)$ cont.comp continuous_fst).union
                (is_closed_le (cont.comp continuous_add)$ cont.comp continuous_snd)
          ·
            intro x y 
            dsimp 
            normCast 
            rw [←le_max_iff]
            exact v.map_add x y }

end ValuationOnValuedFieldCompletion

