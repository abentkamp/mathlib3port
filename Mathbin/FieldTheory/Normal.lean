import Mathbin.FieldTheory.Adjoin 
import Mathbin.FieldTheory.Tower 
import Mathbin.GroupTheory.Solvable 
import Mathbin.RingTheory.PowerBasis

/-!
# Normal field extensions

In this file we define normal field extensions and prove that for a finite extension, being normal
is the same as being a splitting field (`normal.of_is_splitting_field` and
`normal.exists_is_splitting_field`).

## Main Definitions

- `normal F K` where `K` is a field extension of `F`.
-/


noncomputable section 

open_locale BigOperators

open_locale Classical

open Polynomial IsScalarTower

variable (F K : Type _) [Field F] [Field K] [Algebra F K]

/-- Typeclass for normal field extension: `K` is a normal extension of `F` iff the minimal
polynomial of every element `x` in `K` splits in `K`, i.e. every conjugate of `x` is in `K`. -/
class Normal : Prop where 
  is_integral' (x : K) : IsIntegral F x 
  splits' (x : K) : splits (algebraMap F K) (minpoly F x)

variable {F K}

theorem Normal.is_integral (h : Normal F K) (x : K) : IsIntegral F x :=
  Normal.is_integral' x

theorem Normal.splits (h : Normal F K) (x : K) : splits (algebraMap F K) (minpoly F x) :=
  Normal.splits' x

theorem normal_iff : Normal F K ↔ ∀ x : K, IsIntegral F x ∧ splits (algebraMap F K) (minpoly F x) :=
  ⟨fun h x => ⟨h.is_integral x, h.splits x⟩, fun h => ⟨fun x => (h x).1, fun x => (h x).2⟩⟩

theorem Normal.out : Normal F K → ∀ x : K, IsIntegral F x ∧ splits (algebraMap F K) (minpoly F x) :=
  normal_iff.1

variable (F K)

instance normal_self : Normal F F :=
  ⟨fun x => is_integral_algebra_map,
    fun x =>
      by 
        rw [minpoly.eq_X_sub_C']
        exact splits_X_sub_C _⟩

variable {K}

variable (K)

theorem Normal.exists_is_splitting_field [h : Normal F K] [FiniteDimensional F K] :
  ∃ p : Polynomial F, is_splitting_field F K p :=
  by 
    let s := Basis.ofVectorSpace F K 
    refine' ⟨∏ x, minpoly F (s x), splits_prod _$ fun x hx => h.splits (s x), Subalgebra.to_submodule_injective _⟩
    rw [Algebra.top_to_submodule, eq_top_iff, ←s.span_eq, Submodule.span_le, Set.range_subset_iff]
    refine'
      fun x =>
        Algebra.subset_adjoin
          (multiset.mem_to_finset.mpr$
            (mem_roots$ mt (map_eq_zero$ algebraMap F K).1$ Finset.prod_ne_zero_iff.2$ fun x hx => _).2 _)
    ·
      exact minpoly.ne_zero (h.is_integral (s x))
    rw [is_root.def, eval_map, ←aeval_def, AlgHom.map_prod]
    exact Finset.prod_eq_zero (Finset.mem_univ _) (minpoly.aeval _ _)

section NormalTower

variable (E : Type _) [Field E] [Algebra F E] [Algebra K E] [IsScalarTower F K E]

theorem Normal.tower_top_of_normal [h : Normal F E] : Normal K E :=
  normal_iff.2$
    fun x =>
      by 
        cases' h.out x with hx hhx 
        rw [algebra_map_eq F K E] at hhx 
        exact
          ⟨is_integral_of_is_scalar_tower x hx,
            Polynomial.splits_of_splits_of_dvd (algebraMap K E) (Polynomial.map_ne_zero (minpoly.ne_zero hx))
              ((Polynomial.splits_map_iff (algebraMap F K) (algebraMap K E)).mpr hhx)
              (minpoly.dvd_map_of_is_scalar_tower F K x)⟩

theorem AlgHom.normal_bijective [h : Normal F E] (ϕ : E →ₐ[F] K) : Function.Bijective ϕ :=
  ⟨ϕ.to_ring_hom.injective,
    fun x =>
      by 
        let this' : Algebra E K := ϕ.to_ring_hom.to_algebra 
        obtain ⟨h1, h2⟩ := h.out (algebraMap K E x)
        cases'
          minpoly.mem_range_of_degree_eq_one E x
            (Or.resolve_left h2 (minpoly.ne_zero h1)
              (minpoly.irreducible
                (is_integral_of_is_scalar_tower x ((is_integral_algebra_map_iff (algebraMap K E).Injective).mp h1)))
              (minpoly.dvd E x
                ((algebraMap K E).Injective
                  (by 
                    rw [RingHom.map_zero, aeval_map, ←IsScalarTower.to_alg_hom_apply F K E, ←AlgHom.comp_apply,
                      ←aeval_alg_hom]
                    exact minpoly.aeval F (algebraMap K E x))))) with
          y hy 
        exact ⟨y, hy⟩⟩

variable {F} {E} {E' : Type _} [Field E'] [Algebra F E']

theorem Normal.of_alg_equiv [h : Normal F E] (f : E ≃ₐ[F] E') : Normal F E' :=
  normal_iff.2$
    fun x =>
      by 
        cases' h.out (f.symm x) with hx hhx 
        have H := is_integral_alg_hom f.to_alg_hom hx 
        rw [AlgEquiv.to_alg_hom_eq_coe, AlgEquiv.coe_alg_hom, AlgEquiv.apply_symm_apply] at H 
        use H 
        apply Polynomial.splits_of_splits_of_dvd (algebraMap F E') (minpoly.ne_zero hx)
        ·
          rw [←AlgHom.comp_algebra_map f.to_alg_hom]
          exact Polynomial.splits_comp_of_splits (algebraMap F E) f.to_alg_hom.to_ring_hom hhx
        ·
          apply minpoly.dvd _ _ 
          rw [←AddEquiv.map_eq_zero_iff f.symm.to_add_equiv]
          exact
            Eq.trans (Polynomial.aeval_alg_hom_apply f.symm.to_alg_hom x (minpoly F (f.symm x))).symm
              (minpoly.aeval _ _)

theorem AlgEquiv.transfer_normal (f : E ≃ₐ[F] E') : Normal F E ↔ Normal F E' :=
  ⟨fun h =>
      by 
        exact Normal.of_alg_equiv f,
    fun h =>
      by 
        exact Normal.of_alg_equiv f.symm⟩

theorem Normal.of_is_splitting_field (p : Polynomial F) [hFEp : is_splitting_field F E p] : Normal F E :=
  by 
    byCases' hp : p = 0
    ·
      have  : is_splitting_field F F p
      ·
        rw [hp]
        exact ⟨splits_zero _, Subsingleton.elimₓ _ _⟩
      exact
        (AlgEquiv.transfer_normal ((is_splitting_field.alg_equiv F p).trans (is_splitting_field.alg_equiv E p).symm)).mp
          (normal_self F)
    refine' normal_iff.2 fun x => _ 
    have hFE : FiniteDimensional F E := is_splitting_field.finite_dimensional E p 
    have Hx : IsIntegral F x := is_integral_of_noetherian (IsNoetherian.iff_fg.2 hFE) x 
    refine' ⟨Hx, Or.inr _⟩
    rintro q q_irred ⟨r, hr⟩
    let D := AdjoinRoot q 
    let pbED := AdjoinRoot.powerBasis q_irred.ne_zero 
    have  : FiniteDimensional E D := PowerBasis.finite_dimensional pbED 
    have finrankED : FiniteDimensional.finrank E D = q.nat_degree := PowerBasis.finrank pbED 
    let this' : Algebra F D := RingHom.toAlgebra ((algebraMap E D).comp (algebraMap F E))
    have  : IsScalarTower F E D := of_algebra_map_eq fun _ => rfl 
    have  : FiniteDimensional F D := FiniteDimensional.trans F E D 
    suffices  : Nonempty (D →ₐ[F] E)
    ·
      cases' this with ϕ 
      rw [←WithBot.coe_one, degree_eq_iff_nat_degree_eq q_irred.ne_zero, ←finrankED]
      have nat_lemma : ∀ a b c : ℕ, (a*b) = c → c ≤ a → 0 < c → b = 1
      ·
        intro a b c h1 h2 h3 
        nlinarith 
      exact
        nat_lemma _ _ _ (FiniteDimensional.finrank_mul_finrank F E D)
          (LinearMap.finrank_le_finrank_of_injective
            (show Function.Injective ϕ.to_linear_map from ϕ.to_ring_hom.injective))
          FiniteDimensional.finrank_pos 
    let C := AdjoinRoot (minpoly F x)
    have Hx_irred := minpoly.irreducible Hx 
    let this' : Algebra C D :=
      RingHom.toAlgebra
        (AdjoinRoot.lift (algebraMap F D) (AdjoinRoot.root q)
          (by 
            rw [algebra_map_eq F E D, ←eval₂_map, hr, AdjoinRoot.algebra_map_eq, eval₂_mul, AdjoinRoot.eval₂_root,
              zero_mul]))
    let this' : Algebra C E := RingHom.toAlgebra (AdjoinRoot.lift (algebraMap F E) x (minpoly.aeval F x))
    have  : IsScalarTower F C D := of_algebra_map_eq fun x => (AdjoinRoot.lift_of _).symm 
    have  : IsScalarTower F C E := of_algebra_map_eq fun x => (AdjoinRoot.lift_of _).symm 
    suffices  : Nonempty (D →ₐ[C] E)
    ·
      exact Nonempty.map (AlgHom.restrictScalars F) this 
    let S : Set D := ((p.map (algebraMap F E)).roots.map (algebraMap E D)).toFinset 
    suffices  : ⊤ ≤ IntermediateField.adjoin C S
    ·
      refine' IntermediateField.alg_hom_mk_adjoin_splits' (top_le_iff.mp this) fun y hy => _ 
      rcases multiset.mem_map.mp (multiset.mem_to_finset.mp hy) with ⟨z, hz1, hz2⟩
      have Hz : IsIntegral F z := is_integral_of_noetherian (IsNoetherian.iff_fg.2 hFE) z 
      use show IsIntegral C y from is_integral_of_noetherian (IsNoetherian.iff_fg.2 (FiniteDimensional.right F C D)) y 
      apply splits_of_splits_of_dvd (algebraMap C E) (map_ne_zero (minpoly.ne_zero Hz))
      ·
        rw [splits_map_iff, ←algebra_map_eq F C E]
        exact
          splits_of_splits_of_dvd _ hp hFEp.splits
            (minpoly.dvd F z (Eq.trans (eval₂_eq_eval_map _) ((mem_roots (map_ne_zero hp)).mp hz1)))
      ·
        apply minpoly.dvd 
        rw [←hz2, aeval_def, eval₂_map, ←algebra_map_eq F C D, algebra_map_eq F E D, ←hom_eval₂, ←aeval_def,
          minpoly.aeval F z, RingHom.map_zero]
    rw [←IntermediateField.to_subalgebra_le_to_subalgebra, IntermediateField.top_to_subalgebra]
    apply ge_transₓ (IntermediateField.algebra_adjoin_le_adjoin C S)
    suffices  : (Algebra.adjoin C S).restrictScalars F = (Algebra.adjoin E {AdjoinRoot.root q}).restrictScalars F
    ·
      rw [AdjoinRoot.adjoin_root_eq_top, Subalgebra.restrict_scalars_top, ←@Subalgebra.restrict_scalars_top F C] at
        this 
      exact top_le_iff.mpr (Subalgebra.restrict_scalars_injective F this)
    dsimp only [S]
    rw [←Finset.image_to_finset, Finset.coe_image]
    apply Eq.trans (Algebra.adjoin_res_eq_adjoin_res F E C D hFEp.adjoin_roots AdjoinRoot.adjoin_root_eq_top)
    rw [Set.image_singleton, RingHom.algebra_map_to_algebra, AdjoinRoot.lift_root]

instance (p : Polynomial F) : Normal F p.splitting_field :=
  Normal.of_is_splitting_field p

end NormalTower

variable {F} {K} (ϕ ψ : K →ₐ[F] K) (χ ω : K ≃ₐ[F] K)

section Restrict

variable (E : Type _) [Field E] [Algebra F E] [Algebra E K] [IsScalarTower F E K]

/-- Restrict algebra homomorphism to image of normal subfield -/
def AlgHom.restrictNormalAux [h : Normal F E] : (to_alg_hom F E K).range →ₐ[F] (to_alg_hom F E K).range :=
  { toFun :=
      fun x =>
        ⟨ϕ x,
          by 
            suffices  : (to_alg_hom F E K).range.map ϕ ≤ _
            ·
              exact this ⟨x, Subtype.mem x, rfl⟩
            rintro x ⟨y, ⟨z, hy⟩, hx⟩
            rw [←hx, ←hy]
            apply minpoly.mem_range_of_degree_eq_one E 
            exact
              Or.resolve_left (h.splits z) (minpoly.ne_zero (h.is_integral z))
                (minpoly.irreducible$
                  is_integral_of_is_scalar_tower _$ is_integral_alg_hom ϕ$ is_integral_alg_hom _$ h.is_integral z)
                (minpoly.dvd E _$
                  by 
                    rw [aeval_map, aeval_alg_hom, aeval_alg_hom, AlgHom.comp_apply, AlgHom.comp_apply, minpoly.aeval,
                      AlgHom.map_zero, AlgHom.map_zero])⟩,
    map_zero' := Subtype.ext ϕ.map_zero, map_one' := Subtype.ext ϕ.map_one,
    map_add' := fun x y => Subtype.ext (ϕ.map_add x y), map_mul' := fun x y => Subtype.ext (ϕ.map_mul x y),
    commutes' := fun x => Subtype.ext (ϕ.commutes x) }

/-- Restrict algebra homomorphism to normal subfield -/
def AlgHom.restrictNormal [Normal F E] : E →ₐ[F] E :=
  ((AlgEquiv.ofInjectiveField (IsScalarTower.toAlgHom F E K)).symm.toAlgHom.comp (ϕ.restrict_normal_aux E)).comp
    (AlgEquiv.ofInjectiveField (IsScalarTower.toAlgHom F E K)).toAlgHom

@[simp]
theorem AlgHom.restrict_normal_commutes [Normal F E] (x : E) :
  algebraMap E K (ϕ.restrict_normal E x) = ϕ (algebraMap E K x) :=
  Subtype.ext_iff.mp
    (AlgEquiv.apply_symm_apply (AlgEquiv.ofInjectiveField (IsScalarTower.toAlgHom F E K))
      (ϕ.restrict_normal_aux E ⟨IsScalarTower.toAlgHom F E K x, x, rfl⟩))

theorem AlgHom.restrict_normal_comp [Normal F E] :
  (ϕ.restrict_normal E).comp (ψ.restrict_normal E) = (ϕ.comp ψ).restrictNormal E :=
  AlgHom.ext
    fun _ =>
      (algebraMap E K).Injective
        (by 
          simp only [AlgHom.comp_apply, AlgHom.restrict_normal_commutes])

/-- Restrict algebra isomorphism to a normal subfield -/
def AlgEquiv.restrictNormal [h : Normal F E] : E ≃ₐ[F] E :=
  AlgEquiv.ofBijective (χ.to_alg_hom.restrict_normal E) (AlgHom.normal_bijective F E E _)

@[simp]
theorem AlgEquiv.restrict_normal_commutes [Normal F E] (x : E) :
  algebraMap E K (χ.restrict_normal E x) = χ (algebraMap E K x) :=
  χ.to_alg_hom.restrict_normal_commutes E x

theorem AlgEquiv.restrict_normal_trans [Normal F E] :
  (χ.trans ω).restrictNormal E = (χ.restrict_normal E).trans (ω.restrict_normal E) :=
  AlgEquiv.ext
    fun _ =>
      (algebraMap E K).Injective
        (by 
          simp only [AlgEquiv.trans_apply, AlgEquiv.restrict_normal_commutes])

/-- Restriction to an normal subfield as a group homomorphism -/
def AlgEquiv.restrictNormalHom [Normal F E] : (K ≃ₐ[F] K) →* E ≃ₐ[F] E :=
  MonoidHom.mk' (fun χ => χ.restrict_normal E) fun ω χ => χ.restrict_normal_trans ω E

end Restrict

section lift

variable {F} {K} (E : Type _) [Field E] [Algebra F E] [Algebra K E] [IsScalarTower F K E]

/-- If `E/K/F` is a tower of fields with `E/F` normal then we can lift
  an algebra homomorphism `ϕ : K →ₐ[F] K` to `ϕ.lift_normal E : E →ₐ[F] E`. -/
noncomputable def AlgHom.liftNormal [h : Normal F E] : E →ₐ[F] E :=
  @AlgHom.restrictScalars F K E E _ _ _ _ _ _ ((IsScalarTower.toAlgHom F K E).comp ϕ).toRingHom.toAlgebra _ _ _ _
    (Nonempty.some
      (@IntermediateField.alg_hom_mk_adjoin_splits' K E E _ _ _ _
        ((IsScalarTower.toAlgHom F K E).comp ϕ).toRingHom.toAlgebra ⊤ rfl
        fun x hx =>
          ⟨is_integral_of_is_scalar_tower x (h.out x).1,
            splits_of_splits_of_dvd _ (map_ne_zero (minpoly.ne_zero (h.out x).1))
              (by 
                rw [splits_map_iff, ←IsScalarTower.algebra_map_eq]
                exact (h.out x).2)
              (minpoly.dvd_map_of_is_scalar_tower F K x)⟩))

@[simp]
theorem AlgHom.lift_normal_commutes [Normal F E] (x : K) : ϕ.lift_normal E (algebraMap K E x) = algebraMap K E (ϕ x) :=
  @AlgHom.commutes K E E _ _ _ _ ((IsScalarTower.toAlgHom F K E).comp ϕ).toRingHom.toAlgebra _ x

@[simp]
theorem AlgHom.restrict_lift_normal [Normal F K] [Normal F E] : (ϕ.lift_normal E).restrictNormal K = ϕ :=
  AlgHom.ext
    fun x => (algebraMap K E).Injective (Eq.trans (AlgHom.restrict_normal_commutes _ K x) (ϕ.lift_normal_commutes E x))

/-- If `E/K/F` is a tower of fields with `E/F` normal then we can lift
  an algebra isomorphism `ϕ : K ≃ₐ[F] K` to `ϕ.lift_normal E : E ≃ₐ[F] E`. -/
noncomputable def AlgEquiv.liftNormal [Normal F E] : E ≃ₐ[F] E :=
  AlgEquiv.ofBijective (χ.to_alg_hom.lift_normal E) (AlgHom.normal_bijective F E E _)

@[simp]
theorem AlgEquiv.lift_normal_commutes [Normal F E] (x : K) :
  χ.lift_normal E (algebraMap K E x) = algebraMap K E (χ x) :=
  χ.to_alg_hom.lift_normal_commutes E x

@[simp]
theorem AlgEquiv.restrict_lift_normal [Normal F K] [Normal F E] : (χ.lift_normal E).restrictNormal K = χ :=
  AlgEquiv.ext
    fun x =>
      (algebraMap K E).Injective (Eq.trans (AlgEquiv.restrict_normal_commutes _ K x) (χ.lift_normal_commutes E x))

theorem AlgEquiv.restrict_normal_hom_surjective [Normal F K] [Normal F E] :
  Function.Surjective (AlgEquiv.restrictNormalHom K : (E ≃ₐ[F] E) → K ≃ₐ[F] K) :=
  fun χ => ⟨χ.lift_normal E, χ.restrict_lift_normal E⟩

variable (F) (K) (E)

theorem is_solvable_of_is_scalar_tower [Normal F K] [h1 : IsSolvable (K ≃ₐ[F] K)] [h2 : IsSolvable (E ≃ₐ[K] E)] :
  IsSolvable (E ≃ₐ[F] E) :=
  by 
    let f : (E ≃ₐ[K] E) →* E ≃ₐ[F] E :=
      { toFun :=
          fun ϕ =>
            AlgEquiv.ofAlgHom (ϕ.to_alg_hom.restrict_scalars F) (ϕ.symm.to_alg_hom.restrict_scalars F)
              (AlgHom.ext fun x => ϕ.apply_symm_apply x) (AlgHom.ext fun x => ϕ.symm_apply_apply x),
        map_one' := AlgEquiv.ext fun _ => rfl, map_mul' := fun _ _ => AlgEquiv.ext fun _ => rfl }
    refine'
      solvable_of_ker_le_range f (AlgEquiv.restrictNormalHom K)
        fun ϕ hϕ => ⟨{ ϕ with commutes' := fun x => _ }, AlgEquiv.ext fun _ => rfl⟩
    exact Eq.trans (ϕ.restrict_normal_commutes K x).symm (congr_argₓ _ (alg_equiv.ext_iff.mp hϕ x))

end lift

