import Mathbin.FieldTheory.Adjoin 
import Mathbin.FieldTheory.IsAlgClosed.Basic 
import Mathbin.FieldTheory.Separable 
import Mathbin.RingTheory.IntegralDomain

/-!
# Primitive Element Theorem

In this file we prove the primitive element theorem.

## Main results

- `exists_primitive_element`: a finite separable extension `E / F` has a primitive element, i.e.
  there is an `α : E` such that `F⟮α⟯ = (⊤ : subalgebra F E)`.

## Implementation notes

In declaration names, `primitive_element` abbreviates `adjoin_simple_eq_top`:
it stands for the statement `F⟮α⟯ = (⊤ : subalgebra F E)`. We did not add an extra
declaration `is_primitive_element F α := F⟮α⟯ = (⊤ : subalgebra F E)` because this
requires more unfolding without much obvious benefit.

## Tags

primitive element, separable field extension, separable extension, intermediate field, adjoin,
exists_adjoin_simple_eq_top

-/


noncomputable section 

open_locale Classical

open FiniteDimensional Polynomial IntermediateField

namespace Field

section PrimitiveElementFinite

variable (F : Type _) [Field F] (E : Type _) [Field E] [Algebra F E]

/-! ### Primitive element theorem for finite fields -/


-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- **Primitive element theorem** assuming E is finite. -/
theorem exists_primitive_element_of_fintype_top [Fintype E] :
  ∃ α : E, «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" = ⊤ :=
  by 
    obtain ⟨α, hα⟩ := IsCyclic.exists_generator (Units E)
    use α 
    apply eq_top_iff.mpr 
    rintro x -
    byCases' hx : x = 0
    ·
      rw [hx]
      exact
        («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»").zero_mem
    ·
      obtain ⟨n, hn⟩ := set.mem_range.mp (hα (Units.mk0 x hx))
      rw
        [show x = (α^n)by 
          normCast 
          rw [hn, Units.coe_mk0]]
      exact
        pow_mem («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
          (mem_adjoin_simple_self F (↑α)) n

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- Primitive element theorem for finite dimensional extension of a finite field. -/
theorem exists_primitive_element_of_fintype_bot [Fintype F] [FiniteDimensional F E] :
  ∃ α : E, «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" = ⊤ :=
  by 
    have  : Fintype E := fintype_of_fintype F E 
    exact exists_primitive_element_of_fintype_top F E

end PrimitiveElementFinite

/-! ### Primitive element theorem for infinite fields -/


section PrimitiveElementInf

variable {F : Type _} [Field F] [Infinite F] {E : Type _} [Field E] (ϕ : F →+* E) (α β : E)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (α' «expr ∈ » (f.map ϕ).roots)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (β' «expr ∈ » (g.map ϕ).roots)
theorem primitive_element_inf_aux_exists_c (f g : Polynomial F) :
  ∃ c : F, ∀ α' _ : α' ∈ (f.map ϕ).roots β' _ : β' ∈ (g.map ϕ).roots, -(α' - α) / (β' - β) ≠ ϕ c :=
  by 
    let sf := (f.map ϕ).roots 
    let sg := (g.map ϕ).roots 
    let s := (sf.bind fun α' => sg.map fun β' => -(α' - α) / (β' - β)).toFinset 
    let s' := s.preimage ϕ fun x hx y hy h => ϕ.injective h 
    obtain ⟨c, hc⟩ := Infinite.exists_not_mem_finset s' 
    simpRw [Finset.mem_preimage, Multiset.mem_to_finset, Multiset.mem_bind, Multiset.mem_map]  at hc 
    pushNeg  at hc 
    exact ⟨c, hc⟩

variable (F) [Algebra F E]

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » (h.map ιEE').roots)
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
theorem primitive_element_inf_aux [IsSeparable F E] :
  ∃ γ : E,
    «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" =
      «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" :=
  by 
    have hα := IsSeparable.is_integral F α 
    have hβ := IsSeparable.is_integral F β 
    let f := minpoly F α 
    let g := minpoly F β 
    let ιFE := algebraMap F E 
    let ιEE' := algebraMap E (splitting_field (g.map ιFE))
    obtain ⟨c, hc⟩ := primitive_element_inf_aux_exists_c (ιEE'.comp ιFE) (ιEE' α) (ιEE' β) f g 
    let γ := α+c • β 
    suffices β_in_Fγ :
      β ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»"
    ·
      use γ 
      apply le_antisymmₓ
      ·
        rw [adjoin_le_iff]
        have α_in_Fγ :
          α ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»"
        ·
          rw [←add_sub_cancel α (c • β)]
          exact
            («expr ⟮ , ⟯» F
                  "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»").sub_mem
              (mem_adjoin_simple_self F γ)
              ((«expr ⟮ , ⟯» F
                      "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»").toSubalgebra.smul_mem
                β_in_Fγ c)
        exact
          fun x hx =>
            by 
              cases hx <;> cases hx <;> cases hx <;> assumption
      ·
        rw [adjoin_le_iff]
        change {γ} ⊆ _ 
        rw [Set.singleton_subset_iff]
        have α_in_Fαβ :
          α ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" :=
          subset_adjoin F {α, β} (Set.mem_insert α {β})
        have β_in_Fαβ :
          β ∈ «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" :=
          subset_adjoin F {α, β} (Set.mem_insert_of_mem α rfl)
        exact
          («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»").add_mem
            α_in_Fαβ
            ((«expr ⟮ , ⟯» F
                  "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»").smul_mem
              β_in_Fαβ)
    let p :=
      EuclideanDomain.gcd
        ((f.map
              (algebraMap F
                («expr ⟮ , ⟯» F
                  "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»"))).comp
          (C (adjoin_simple.gen F γ) - C (↑c)*X))
        (g.map
          (algebraMap F
            («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")))
    let h := EuclideanDomain.gcd ((f.map ιFE).comp (C γ - C (ιFE c)*X)) (g.map ιFE)
    have map_g_ne_zero : g.map ιFE ≠ 0 := map_ne_zero (minpoly.ne_zero hβ)
    have h_ne_zero : h ≠ 0 := mt euclidean_domain.gcd_eq_zero_iff.mp (not_and.mpr fun _ => map_g_ne_zero)
    suffices p_linear :
      p.map
          (algebraMap
            («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»") E) =
        C h.leading_coeff*X - C β
    ·
      have finale :
        β =
          algebraMap
            («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»") E
            (-p.coeff 0 / p.coeff 1)
      ·
        rw [RingHom.map_div, RingHom.map_neg, ←coeff_map, ←coeff_map, p_linear]
        simp [mul_sub, coeff_C, mul_div_cancel_left β (mt leading_coeff_eq_zero.mp h_ne_zero)]
      rw [finale]
      exact Subtype.mem (-p.coeff 0 / p.coeff 1)
    have h_sep : h.separable := separable_gcd_right _ (IsSeparable.separable F β).map 
    have h_root : h.eval β = 0
    ·
      apply eval_gcd_eq_zero
      ·
        rw [eval_comp, eval_sub, eval_mul, eval_C, eval_C, eval_X, eval_map, ←aeval_def, ←Algebra.smul_def,
          add_sub_cancel, minpoly.aeval]
      ·
        rw [eval_map, ←aeval_def, minpoly.aeval]
    have h_splits : splits ιEE' h := splits_of_splits_gcd_right ιEE' map_g_ne_zero (splitting_field.splits _)
    have h_roots : ∀ x _ : x ∈ (h.map ιEE').roots, x = ιEE' β
    ·
      intro x hx 
      rw [mem_roots_map h_ne_zero] at hx 
      specialize
        hc (ιEE' γ - ιEE' (ιFE c)*x)
          (by 
            have f_root := root_left_of_root_gcd hx 
            rw [eval₂_comp, eval₂_sub, eval₂_mul, eval₂_C, eval₂_C, eval₂_X, eval₂_map] at f_root 
            exact (mem_roots_map (minpoly.ne_zero hα)).mpr f_root)
      specialize
        hc x
          (by 
            rw [mem_roots_map (minpoly.ne_zero hβ), ←eval₂_map]
            exact root_right_of_root_gcd hx)
      byContra a 
      apply hc 
      apply (div_eq_iff (sub_ne_zero.mpr a)).mpr 
      simp only [Algebra.smul_def, RingHom.map_add, RingHom.map_mul, RingHom.comp_apply]
      ring 
    rw [←eq_X_sub_C_of_separable_of_root_eq h_sep h_root h_splits h_roots]
    trans EuclideanDomain.gcd (_ : Polynomial E) (_ : Polynomial E)
    ·
      dsimp only [p]
      convert
        (gcd_map
            (algebraMap
              («expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
              E)).symm
    ·
      simpa [map_comp, map_map, ←IsScalarTower.algebra_map_eq, h]

end PrimitiveElementInf

variable (F E : Type _) [Field F] [Field E]

variable [Algebra F E] [FiniteDimensional F E] [IsSeparable F E]

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- Primitive element theorem: a finite separable field extension `E` of `F` has a
  primitive element, i.e. there is an `α ∈ E` such that `F⟮α⟯ = (⊤ : subalgebra F E)`.-/
theorem exists_primitive_element :
  ∃ α : E, «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" = ⊤ :=
  by 
    rcases is_empty_or_nonempty (Fintype F) with (F_inf | ⟨⟨F_finite⟩⟩)
    ·
      let P : IntermediateField F E → Prop :=
        fun K =>
          ∃ α : E,
            «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" = K 
      have base : P ⊥ := ⟨0, adjoin_zero⟩
      have ih :
        ∀ K : IntermediateField F E x : E,
          P K →
            P (↑«expr ⟮ , ⟯» K "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»")
      ·
        intro K β hK 
        cases' hK with α hK 
        rw [←hK, adjoin_simple_adjoin_simple]
        have  : Infinite F := is_empty_fintype.mp F_inf 
        cases' primitive_element_inf_aux F α β with γ hγ 
        exact ⟨γ, hγ.symm⟩
      exact induction_on_adjoin P base ih ⊤
    ·
      exact exists_primitive_element_of_fintype_bot F E

-- ././Mathport/Syntax/Translate/Basic.lean:600:4: warning: unsupported notation `«expr ⟮ , ⟯»
-- ././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»
/-- Alternative phrasing of primitive element theorem:
a finite separable field extension has a basis `1, α, α^2, ..., α^n`.

See also `exists_primitive_element`. -/
noncomputable def power_basis_of_finite_of_separable : PowerBasis F E :=
  let α := (exists_primitive_element F E).some 
  let pb := adjoin.power_basis (IsSeparable.is_integral F α)
  have e : «expr ⟮ , ⟯» F "././Mathport/Syntax/Translate/Basic.lean:601:61: unsupported notation `«expr ⟮ , ⟯»" = ⊤ :=
    (exists_primitive_element F E).some_spec 
  pb.map ((IntermediateField.equivOfEq e).trans IntermediateField.topEquiv)

/-- If `E / F` is a finite separable extension, then there are finitely many
embeddings from `E` into `K` that fix `F`, corresponding to the number of
conjugate roots of the primitive element generating `F`. -/
instance {K : Type _} [Field K] [Algebra F K] : Fintype (E →ₐ[F] K) :=
  PowerBasis.AlgHom.fintype (power_basis_of_finite_of_separable F E)

end Field

@[simp]
theorem AlgHom.card (F E K : Type _) [Field F] [Field E] [Field K] [IsAlgClosed K] [Algebra F E] [FiniteDimensional F E]
  [IsSeparable F E] [Algebra F K] : Fintype.card (E →ₐ[F] K) = finrank F E :=
  (AlgHom.card_of_power_basis (Field.powerBasisOfFiniteOfSeparable F E) (IsSeparable.separable _ _)
        (IsAlgClosed.splits_codomain _)).trans
    (PowerBasis.finrank _).symm

