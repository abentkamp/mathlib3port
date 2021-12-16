import Mathbin.Analysis.SpecialFunctions.Trigonometric.Inverse 
import Mathbin.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# derivatives of the inverse trigonometric functions

Derivatives of `arcsin` and `arccos`.
-/


noncomputable section 

open_locale Classical TopologicalSpace Filter

open Set Filter

open_locale Real

namespace Real

section Arcsin

theorem deriv_arcsin_aux {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) :
  HasStrictDerivAt arcsin (1 / sqrt (1 - (x^2))) x ∧ TimesContDiffAt ℝ ⊤ arcsin x :=
  by 
    cases' h₁.lt_or_lt with h₁ h₁
    ·
      have  : 1 - (x^2) < 0
      ·
        nlinarith [h₁]
      rw [sqrt_eq_zero'.2 this.le, div_zero]
      have  : arcsin =ᶠ[𝓝 x] fun _ => -(π / 2) := (gt_mem_nhds h₁).mono fun y hy => arcsin_of_le_neg_one hy.le 
      exact
        ⟨(has_strict_deriv_at_const _ _).congr_of_eventually_eq this.symm,
          times_cont_diff_at_const.congr_of_eventually_eq this⟩
    cases' h₂.lt_or_lt with h₂ h₂
    ·
      have  : 0 < sqrt (1 - (x^2)) :=
        sqrt_pos.2
          (by 
            nlinarith [h₁, h₂])
      simp only [←cos_arcsin h₁.le h₂.le, one_div] at this⊢
      exact
        ⟨sin_local_homeomorph.has_strict_deriv_at_symm ⟨h₁, h₂⟩ this.ne' (has_strict_deriv_at_sin _),
          sin_local_homeomorph.times_cont_diff_at_symm_deriv this.ne' ⟨h₁, h₂⟩ (has_deriv_at_sin _)
            times_cont_diff_sin.times_cont_diff_at⟩
    ·
      have  : 1 - (x^2) < 0
      ·
        nlinarith [h₂]
      rw [sqrt_eq_zero'.2 this.le, div_zero]
      have  : arcsin =ᶠ[𝓝 x] fun _ => π / 2 := (lt_mem_nhds h₂).mono fun y hy => arcsin_of_one_le hy.le 
      exact
        ⟨(has_strict_deriv_at_const _ _).congr_of_eventually_eq this.symm,
          times_cont_diff_at_const.congr_of_eventually_eq this⟩

theorem has_strict_deriv_at_arcsin {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) :
  HasStrictDerivAt arcsin (1 / sqrt (1 - (x^2))) x :=
  (deriv_arcsin_aux h₁ h₂).1

theorem has_deriv_at_arcsin {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) : HasDerivAt arcsin (1 / sqrt (1 - (x^2))) x :=
  (has_strict_deriv_at_arcsin h₁ h₂).HasDerivAt

theorem times_cont_diff_at_arcsin {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) {n : WithTop ℕ} : TimesContDiffAt ℝ n arcsin x :=
  (deriv_arcsin_aux h₁ h₂).2.of_le le_top

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  has_deriv_within_at_arcsin_Ici
  { x : ℝ } ( h : x ≠ - 1 ) : HasDerivWithinAt arcsin 1 / sqrt 1 - x ^ 2 Ici x x
  :=
    by
      rcases em x = 1 with ( rfl | h' )
        ·
          convert has_deriv_within_at_const _ _ π / 2 . congr _ _
            <;>
            simp ( config := { contextual := Bool.true._@._internal._hyg.0 } ) [ arcsin_of_one_le ]
        · exact has_deriv_at_arcsin h h' . HasDerivWithinAt

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  has_deriv_within_at_arcsin_Iic
  { x : ℝ } ( h : x ≠ 1 ) : HasDerivWithinAt arcsin 1 / sqrt 1 - x ^ 2 Iic x x
  :=
    by
      rcases em x = - 1 with ( rfl | h' )
        ·
          convert has_deriv_within_at_const _ _ - π / 2 . congr _ _
            <;>
            simp ( config := { contextual := Bool.true._@._internal._hyg.0 } ) [ arcsin_of_le_neg_one ]
        · exact has_deriv_at_arcsin h' h . HasDerivWithinAt

theorem differentiable_within_at_arcsin_Ici {x : ℝ} : DifferentiableWithinAt ℝ arcsin (Ici x) x ↔ x ≠ -1 :=
  by 
    refine' ⟨_, fun h => (has_deriv_within_at_arcsin_Ici h).DifferentiableWithinAt⟩
    rintro h rfl 
    have  : (sin ∘ arcsin) =ᶠ[𝓝[Ici (-1 : ℝ)] -1] id
    ·
      filterUpwards [Icc_mem_nhds_within_Ici ⟨le_rfl, neg_lt_self (@zero_lt_one ℝ _ _)⟩]
      exact fun x => sin_arcsin' 
    have  :=
      h.has_deriv_within_at.sin.congr_of_eventually_eq this.symm
        (by 
          simp )
    simpa using (unique_diff_on_Ici _ _ left_mem_Ici).eq_deriv _ this (has_deriv_within_at_id _ _)

theorem differentiable_within_at_arcsin_Iic {x : ℝ} : DifferentiableWithinAt ℝ arcsin (Iic x) x ↔ x ≠ 1 :=
  by 
    refine' ⟨fun h => _, fun h => (has_deriv_within_at_arcsin_Iic h).DifferentiableWithinAt⟩
    rw [←neg_negₓ x, ←image_neg_Ici] at h 
    have  := (h.comp (-x) differentiable_within_at_id.neg (maps_to_image _ _)).neg 
    simpa [· ∘ ·, differentiable_within_at_arcsin_Ici] using this

theorem differentiable_at_arcsin {x : ℝ} : DifferentiableAt ℝ arcsin x ↔ x ≠ -1 ∧ x ≠ 1 :=
  ⟨fun h =>
      ⟨differentiable_within_at_arcsin_Ici.1 h.differentiable_within_at,
        differentiable_within_at_arcsin_Iic.1 h.differentiable_within_at⟩,
    fun h => (has_deriv_at_arcsin h.1 h.2).DifferentiableAt⟩

@[simp]
theorem deriv_arcsin : deriv arcsin = fun x => 1 / sqrt (1 - (x^2)) :=
  by 
    funext x 
    byCases' h : x ≠ -1 ∧ x ≠ 1
    ·
      exact (has_deriv_at_arcsin h.1 h.2).deriv
    ·
      rw [deriv_zero_of_not_differentiable_at (mt differentiable_at_arcsin.1 h)]
      simp only [not_and_distrib, Ne.def, not_not] at h 
      rcases h with (rfl | rfl) <;> simp 

theorem differentiable_on_arcsin : DifferentiableOn ℝ arcsin ({-1, 1}ᶜ) :=
  fun x hx => (differentiable_at_arcsin.2 ⟨fun h => hx (Or.inl h), fun h => hx (Or.inr h)⟩).DifferentiableWithinAt

theorem times_cont_diff_on_arcsin {n : WithTop ℕ} : TimesContDiffOn ℝ n arcsin ({-1, 1}ᶜ) :=
  fun x hx => (times_cont_diff_at_arcsin (mt Or.inl hx) (mt Or.inr hx)).TimesContDiffWithinAt

theorem times_cont_diff_at_arcsin_iff {x : ℝ} {n : WithTop ℕ} : TimesContDiffAt ℝ n arcsin x ↔ n = 0 ∨ x ≠ -1 ∧ x ≠ 1 :=
  ⟨fun h =>
      or_iff_not_imp_left.2$
        fun hn => differentiable_at_arcsin.1$ h.differentiable_at$ WithTop.one_le_iff_pos.2 (pos_iff_ne_zero.2 hn),
    fun h =>
      (h.elim fun hn => hn.symm ▸ (times_cont_diff_zero.2 continuous_arcsin).TimesContDiffAt)$
        fun hx => times_cont_diff_at_arcsin hx.1 hx.2⟩

end Arcsin

section Arccos

theorem has_strict_deriv_at_arccos {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) :
  HasStrictDerivAt arccos (-(1 / sqrt (1 - (x^2)))) x :=
  (has_strict_deriv_at_arcsin h₁ h₂).const_sub (π / 2)

theorem has_deriv_at_arccos {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) : HasDerivAt arccos (-(1 / sqrt (1 - (x^2)))) x :=
  (has_deriv_at_arcsin h₁ h₂).const_sub (π / 2)

theorem times_cont_diff_at_arccos {x : ℝ} (h₁ : x ≠ -1) (h₂ : x ≠ 1) {n : WithTop ℕ} : TimesContDiffAt ℝ n arccos x :=
  times_cont_diff_at_const.sub (times_cont_diff_at_arcsin h₁ h₂)

theorem has_deriv_within_at_arccos_Ici {x : ℝ} (h : x ≠ -1) :
  HasDerivWithinAt arccos (-(1 / sqrt (1 - (x^2)))) (Ici x) x :=
  (has_deriv_within_at_arcsin_Ici h).const_sub _

theorem has_deriv_within_at_arccos_Iic {x : ℝ} (h : x ≠ 1) :
  HasDerivWithinAt arccos (-(1 / sqrt (1 - (x^2)))) (Iic x) x :=
  (has_deriv_within_at_arcsin_Iic h).const_sub _

theorem differentiable_within_at_arccos_Ici {x : ℝ} : DifferentiableWithinAt ℝ arccos (Ici x) x ↔ x ≠ -1 :=
  (differentiable_within_at_const_sub_iff _).trans differentiable_within_at_arcsin_Ici

theorem differentiable_within_at_arccos_Iic {x : ℝ} : DifferentiableWithinAt ℝ arccos (Iic x) x ↔ x ≠ 1 :=
  (differentiable_within_at_const_sub_iff _).trans differentiable_within_at_arcsin_Iic

theorem differentiable_at_arccos {x : ℝ} : DifferentiableAt ℝ arccos x ↔ x ≠ -1 ∧ x ≠ 1 :=
  (differentiable_at_const_sub_iff _).trans differentiable_at_arcsin

@[simp]
theorem deriv_arccos : deriv arccos = fun x => -(1 / sqrt (1 - (x^2))) :=
  funext$
    fun x =>
      (deriv_const_sub _).trans$
        by 
          simp only [deriv_arcsin]

theorem differentiable_on_arccos : DifferentiableOn ℝ arccos ({-1, 1}ᶜ) :=
  differentiable_on_arcsin.const_sub _

theorem times_cont_diff_on_arccos {n : WithTop ℕ} : TimesContDiffOn ℝ n arccos ({-1, 1}ᶜ) :=
  times_cont_diff_on_const.sub times_cont_diff_on_arcsin

theorem times_cont_diff_at_arccos_iff {x : ℝ} {n : WithTop ℕ} : TimesContDiffAt ℝ n arccos x ↔ n = 0 ∨ x ≠ -1 ∧ x ≠ 1 :=
  by 
    refine' Iff.trans ⟨fun h => _, fun h => _⟩ times_cont_diff_at_arcsin_iff <;>
      simpa [arccos] using (@times_cont_diff_at_const _ _ _ _ _ _ _ _ _ _ (π / 2)).sub h

end Arccos

end Real

