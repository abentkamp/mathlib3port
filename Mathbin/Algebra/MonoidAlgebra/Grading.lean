import Mathbin.LinearAlgebra.Finsupp 
import Mathbin.Algebra.MonoidAlgebra.Basic 
import Mathbin.Algebra.DirectSum.Internal

/-!
# Internal grading of an `add_monoid_algebra`

In this file, we show that an `add_monoid_algebra` has an internal direct sum structure.

## Main results

* `add_monoid_algebra.grade_by R f i`: the `i`th grade of an `add_monoid_algebra R M` given by the
  degree function `f`.
* `add_monoid_algebra.grade R i`: the `i`th grade of an `add_monoid_algebra R M` when the degree
  function is the identity.
* `add_monoid_algebra.equiv_grade_by`: the equivalence between an `add_monoid_algebra` and the
  direct sum of its grades.
* `add_monoid_algebra.equiv_grade`: the equivalence between an `add_monoid_algebra` and the direct
  sum of its grades when the degree function is the identity.
* `add_monoid_algebra.grade_by.is_internal`: propositionally, the statement that
  `add_monoid_algebra.grade_by` defines an internal graded structure.
* `add_monoid_algebra.grade.is_internal`: propositionally, the statement that
  `add_monoid_algebra.grade` defines an internal graded structure when the degree function
  is the identity.
-/


noncomputable section 

namespace AddMonoidAlgebra

variable {M : Type _} {ι : Type _} {R : Type _} [DecidableEq M]

section 

variable (R) [CommSemiringₓ R]

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The submodule corresponding to each grade given by the degree function `f`. -/
  abbrev
    grade_by
    ( f : M → ι ) ( i : ι ) : Submodule R AddMonoidAlgebra R M
    :=
      {
        Carrier := { a | ∀ m , m ∈ a.support → f m = i } ,
          zero_mem' := Set.empty_subset _ ,
          add_mem' := fun a b ha hb m h => Or.rec_on Finset.mem_union . mp Finsupp.support_add h ha m hb m ,
          smul_mem' := fun a m h => Set.Subset.trans Finsupp.support_smul h
        }

/-- The submodule corresponding to each grade. -/
abbrev grade (m : M) : Submodule R (AddMonoidAlgebra R M) :=
  grade_by R id m

theorem grade_by_id : grade_by R (id : M → M) = grade R :=
  by 
    rfl

theorem mem_grade_by_iff (f : M → ι) (i : ι) (a : AddMonoidAlgebra R M) :
  a ∈ grade_by R f i ↔ (a.support : Set M) ⊆ f ⁻¹' {i} :=
  by 
    rfl

theorem mem_grade_iff (m : M) (a : AddMonoidAlgebra R M) : a ∈ grade R m ↔ a.support ⊆ {m} :=
  by 
    rw [←Finset.coe_subset, Finset.coe_singleton]
    rfl

theorem mem_grade_iff' (m : M) (a : AddMonoidAlgebra R M) :
  a ∈ grade R m ↔ a ∈ ((Finsupp.lsingle m).range : Submodule R (AddMonoidAlgebra R M)) :=
  by 
    rw [mem_grade_iff, Finsupp.support_subset_singleton']
    apply exists_congr 
    intro r 
    constructor <;> exact Eq.symm

theorem grade_eq_lsingle_range (m : M) : grade R m = (Finsupp.lsingle m).range :=
  Submodule.ext (mem_grade_iff' R m)

theorem single_mem_grade_by {R} [CommSemiringₓ R] (f : M → ι) (i : ι) (m : M) (h : f m = i) (r : R) :
  Finsupp.single m r ∈ grade_by R f i :=
  by 
    intro x hx 
    rw [finset.mem_singleton.mp (Finsupp.support_single_subset hx)]
    exact h

theorem single_mem_grade {R} [CommSemiringₓ R] (i : M) (r : R) : Finsupp.single i r ∈ grade R i :=
  single_mem_grade_by _ _ _ rfl _

end 

open_locale DirectSum

instance grade_by.graded_monoid [AddMonoidₓ M] [AddMonoidₓ ι] [CommSemiringₓ R] (f : M →+ ι) :
  SetLike.GradedMonoid (grade_by R f : ι → Submodule R (AddMonoidAlgebra R M)) :=
  { one_mem :=
      fun m h =>
        by 
          rw [one_def] at h 
          byCases' H : (1 : R) = (0 : R)
          ·
            rw [H, Finsupp.single_zero] at h 
            exfalso 
            exact h
          ·
            rw [Finsupp.support_single_ne_zero H, Finset.mem_singleton] at h 
            rw [h, AddMonoidHom.map_zero],
    mul_mem :=
      fun i j a b ha hb c hc =>
        by 
          set h := support_mul a b hc 
          simp only [Finset.mem_bUnion] at h 
          rcases h with ⟨ma, ⟨hma, ⟨mb, ⟨hmb, hmc⟩⟩⟩⟩
          rw [←ha ma hma, ←hb mb hmb, finset.mem_singleton.mp hmc]
          apply AddMonoidHom.map_add }

instance grade.graded_monoid [AddMonoidₓ M] [CommSemiringₓ R] :
  SetLike.GradedMonoid (grade R : M → Submodule R (AddMonoidAlgebra R M)) :=
  by 
    apply grade_by.graded_monoid (AddMonoidHom.id _)

variable {R} [AddMonoidₓ M] [DecidableEq ι] [AddMonoidₓ ι] [CommSemiringₓ R] (f : M →+ ι)

/-- The canonical grade decomposition. -/
def to_grades_by : AddMonoidAlgebra R M →ₐ[R] ⨁ i : ι, grade_by R f i :=
  AddMonoidAlgebra.lift R M _
    { toFun :=
        fun m =>
          DirectSum.of (fun i : ι => grade_by R f i) (f m.to_add)
            ⟨Finsupp.single m.to_add 1, single_mem_grade_by _ _ _ rfl _⟩,
      map_one' :=
        DirectSum.of_eq_of_graded_monoid_eq
          (by 
            congr 2 <;>
              try 
                  ext <;>
                simp only [Submodule.mem_to_add_submonoid, to_add_one, AddMonoidHom.map_zero]),
      map_mul' :=
        fun i j =>
          by 
            symm 
            convert DirectSum.of_mul_of _ _ 
            apply DirectSum.of_eq_of_graded_monoid_eq 
            congr 2
            ·
              rw [to_add_mul, AddMonoidHom.map_add]
            ·
              ext 
              simp only [Submodule.mem_to_add_submonoid, AddMonoidHom.map_add, to_add_mul]
            ·
              exact
                Eq.trans
                  (by 
                    rw [one_mulₓ, to_add_mul])
                  single_mul_single.symm }

/-- The canonical grade decomposition. -/
def to_grades : AddMonoidAlgebra R M →ₐ[R] ⨁ i : M, grade R i :=
  to_grades_by (AddMonoidHom.id M)

theorem to_grades_by_single' (i : ι) (m : M) (h : f m = i) (r : R) :
  to_grades_by f (Finsupp.single m r) =
    DirectSum.of (fun i : ι => grade_by R f i) i ⟨Finsupp.single m r, single_mem_grade_by _ _ _ h _⟩ :=
  by 
    refine' (lift_single _ _ _).trans _ 
    refine' (DirectSum.of_smul _ _ _ _).symm.trans _ 
    apply DirectSum.of_eq_of_graded_monoid_eq 
    ext
    ·
      exact h
    ·
      rw [GradedMonoid.mk]
      simp only [mul_oneₓ, to_add_of_add, Submodule.coe_mk, Finsupp.smul_single', Submodule.coe_smul_of_tower]

@[simp]
theorem to_grades_by_single (m : M) (r : R) :
  to_grades_by f (Finsupp.single m r) =
    DirectSum.of (fun i : ι => grade_by R f i) (f m) ⟨Finsupp.single m r, single_mem_grade_by _ _ _ rfl _⟩ :=
  by 
    apply to_grades_by_single'

@[simp]
theorem to_grades_single (i : ι) (r : R) :
  to_grades (Finsupp.single i r) = DirectSum.of (fun i : ι => grade R i) i ⟨Finsupp.single i r, single_mem_grade _ _⟩ :=
  by 
    apply to_grades_by_single

@[simp]
theorem to_grades_by_coe {i : ι} (x : grade_by R f i) :
  to_grades_by f (↑x) = DirectSum.of (fun i => grade_by R f i) i x :=
  by 
    obtain ⟨x, hx⟩ := x 
    revert hx 
    refine' Finsupp.induction x _ _
    ·
      intro hx 
      symm 
      exact AddMonoidHom.map_zero _
    ·
      intro m b y hmy hb ih hmby 
      have  : Disjoint (Finsupp.single m b).Support y.support
      ·
        simpa only [Finsupp.support_single_ne_zero hb, Finset.disjoint_singleton_left]
      rw [mem_grade_by_iff, Finsupp.support_add_eq this, Finset.coe_union, Set.union_subset_iff] at hmby 
      cases' hmby with h1 h2 
      have  : f m = i
      ·
        rwa [Finsupp.support_single_ne_zero hb, Finset.coe_singleton, Set.singleton_subset_iff] at h1 
      simp only [AlgHom.map_add, Submodule.coe_mk, to_grades_by_single' f i m this]
      let ih' := ih h2 
      dsimp  at ih' 
      rw [ih', ←AddMonoidHom.map_add]
      apply DirectSum.of_eq_of_graded_monoid_eq 
      congr 2

@[simp]
theorem to_grades_coe {i : ι} (x : grade R i) : to_grades (↑x) = DirectSum.of (fun i => grade R i) i x :=
  by 
    apply to_grades_by_coe

/-- The canonical recombination of grades. -/
def of_grades_by : (⨁ i : ι, grade_by R f i) →ₐ[R] AddMonoidAlgebra R M :=
  DirectSum.submoduleCoeAlgHom (grade_by R f)

/-- The canonical recombination of grades. -/
def of_grades : (⨁ i : ι, grade R i) →ₐ[R] AddMonoidAlgebra R ι :=
  of_grades_by (AddMonoidHom.id ι)

@[simp]
theorem of_grades_by_of (i : ι) (x : grade_by R f i) :
  of_grades_by f (DirectSum.of (fun i => grade_by R f i) i x) = x :=
  DirectSum.submodule_coe_alg_hom_of (grade_by R f) i x

@[simp]
theorem of_grades_of (i : ι) (x : grade R i) : of_grades (DirectSum.of (fun i => grade R i) i x) = x :=
  by 
    apply of_grades_by_of

@[simp]
theorem of_grades_by_comp_to_grades_by : (of_grades_by f).comp (to_grades_by f) = AlgHom.id R (AddMonoidAlgebra R M) :=
  by 
    ext : 2
    dsimp 
    rw [to_grades_by_single, of_grades_by_of, Subtype.coe_mk]

@[simp]
theorem of_grades_comp_to_grades : of_grades.comp to_grades = AlgHom.id R (AddMonoidAlgebra R ι) :=
  by 
    apply of_grades_by_comp_to_grades_by

@[simp]
theorem of_grades_by_to_grades_by (x : AddMonoidAlgebra R M) : of_grades_by f (to_grades_by f x) = x :=
  AlgHom.congr_fun (of_grades_by_comp_to_grades_by f) x

@[simp]
theorem of_grades_to_grades (x : AddMonoidAlgebra R ι) : of_grades x.to_grades = x :=
  by 
    apply of_grades_by_to_grades_by

@[simp]
theorem to_grades_by_comp_of_grades_by :
  (to_grades_by f).comp (of_grades_by f) = AlgHom.id R (⨁ i : ι, grade_by R f i) :=
  by 
    ext : 2
    dsimp [DirectSum.lof_eq_of]
    rw [of_grades_by_of, to_grades_by_coe]

@[simp]
theorem to_grades_comp_of_grades : to_grades.comp of_grades = AlgHom.id R (⨁ i : ι, grade R i) :=
  by 
    apply to_grades_by_comp_of_grades_by

@[simp]
theorem to_grades_by_of_grades_by (g : ⨁ i : ι, grade_by R f i) : to_grades_by f (of_grades_by f g) = g :=
  AlgHom.congr_fun (to_grades_by_comp_of_grades_by f) g

@[simp]
theorem to_grades_of_grades (g : ⨁ i : ι, grade R i) : (of_grades g).toGrades = g :=
  by 
    apply to_grades_by_of_grades_by

/-- An `add_monoid_algebra R M` is equivalent as an algebra to the direct sum of its grades.
-/
@[simps]
def equiv_grades_by : AddMonoidAlgebra R M ≃ₐ[R] ⨁ i : ι, grade_by R f i :=
  AlgEquiv.ofAlgHom _ _ (to_grades_by_comp_of_grades_by f) (of_grades_by_comp_to_grades_by f)

/-- An `add_monoid_algebra R ι` is equivalent as an algebra to the direct sum of its grades.
-/
@[simps]
def equiv_grades : AddMonoidAlgebra R ι ≃ₐ[R] ⨁ i : ι, grade R i :=
  equiv_grades_by (AddMonoidHom.id ι)

/-- `add_monoid_algebra.gradesby` describe an internally graded algebra -/
theorem grade_by.is_internal : DirectSum.SubmoduleIsInternal (grade_by R f) :=
  (equiv_grades_by f).symm.Bijective

/-- `add_monoid_algebra.grades` describe an internally graded algebra -/
theorem grade.is_internal : DirectSum.SubmoduleIsInternal (grade R : ι → Submodule R _) :=
  grade_by.is_internal (AddMonoidHom.id ι)

end AddMonoidAlgebra

