/-
Copyright (c) 2022 Adam Topaz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adam Topaz, Junyan Xu, Jack McKoen
-/
import Mathbin.RingTheory.Valuation.ValuationRing
import Mathbin.RingTheory.Localization.AsSubring
import Mathbin.RingTheory.Subring.Pointwise
import Mathbin.AlgebraicGeometry.PrimeSpectrum.Basic

/-!

# Valuation subrings of a field

## Projects

The order structure on `valuation_subring K`.

-/


open Classical

noncomputable section

variable (K : Type _) [Field K]

/-- A valuation subring of a field `K` is a subring `A` such that for every `x : K`,
either `x ∈ A` or `x⁻¹ ∈ A`. -/
structure ValuationSubring extends Subring K where
  mem_or_inv_mem' : ∀ x : K, x ∈ carrier ∨ x⁻¹ ∈ carrier

namespace ValuationSubring

variable {K} (A : ValuationSubring K)

instance : SetLike (ValuationSubring K) K where
  coe := fun A => A.toSubring
  coe_injective' := by
    rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ _
    congr

@[simp]
theorem mem_carrier (x : K) : x ∈ A.Carrier ↔ x ∈ A :=
  Iff.refl _

@[simp]
theorem mem_to_subring (x : K) : x ∈ A.toSubring ↔ x ∈ A :=
  Iff.refl _

@[ext]
theorem ext (A B : ValuationSubring K) (h : ∀ x, x ∈ A ↔ x ∈ B) : A = B :=
  SetLike.ext h

theorem zero_mem : (0 : K) ∈ A :=
  A.toSubring.zero_mem

theorem one_mem : (1 : K) ∈ A :=
  A.toSubring.one_mem

theorem add_mem (x y : K) : x ∈ A → y ∈ A → x + y ∈ A :=
  A.toSubring.add_mem

theorem mul_mem (x y : K) : x ∈ A → y ∈ A → x * y ∈ A :=
  A.toSubring.mul_mem

theorem neg_mem (x : K) : x ∈ A → -x ∈ A :=
  A.toSubring.neg_mem

theorem mem_or_inv_mem (x : K) : x ∈ A ∨ x⁻¹ ∈ A :=
  A.mem_or_inv_mem' _

theorem to_subring_injective : Function.Injective (toSubring : ValuationSubring K → Subring K) := fun x y h => by
  cases x
  cases y
  congr

instance : CommRingₓ A :=
  show CommRingₓ A.toSubring by
    infer_instance

instance : IsDomain A :=
  show IsDomain A.toSubring by
    infer_instance

instance : HasTop (ValuationSubring K) :=
  HasTop.mk <| { (⊤ : Subring K) with mem_or_inv_mem' := fun x => Or.inl trivialₓ }

theorem mem_top (x : K) : x ∈ (⊤ : ValuationSubring K) :=
  trivialₓ

theorem le_top : A ≤ ⊤ := fun a ha => mem_top _

instance : OrderTop (ValuationSubring K) where
  top := ⊤
  le_top := le_top

instance : Inhabited (ValuationSubring K) :=
  ⟨⊤⟩

instance :
    ValuationRing A where cond := fun a b => by
    by_cases' (b : K) = 0
    · use 0
      left
      ext
      simp [h]
      
    by_cases' (a : K) = 0
    · use 0
      right
      ext
      simp [h]
      
    cases' A.mem_or_inv_mem (a / b) with hh hh
    · use ⟨a / b, hh⟩
      right
      ext
      field_simp
      ring
      
    · rw
        [show (a / b : K)⁻¹ = b / a by
          field_simp] at
        hh
      use ⟨b / a, hh⟩
      left
      ext
      field_simp
      ring
      

instance : Algebra A K :=
  show Algebra A.toSubring K by
    infer_instance

@[simp]
theorem algebra_map_apply (a : A) : algebraMap A K a = a :=
  rfl

instance : IsFractionRing A K where
  map_units := fun ⟨y, hy⟩ => (Units.mk0 (y : K) fun c => nonZeroDivisors.ne_zero hy <| Subtype.ext c).IsUnit
  surj := fun z => by
    by_cases' z = 0
    · use (0, 1)
      simp [h]
      
    cases' A.mem_or_inv_mem z with hh hh
    · use (⟨z, hh⟩, 1)
      simp
      
    · refine' ⟨⟨1, ⟨⟨_, hh⟩, _⟩⟩, mul_inv_cancel h⟩
      exact mem_non_zero_divisors_iff_ne_zero.2 fun c => h (inv_eq_zero.mp (congr_argₓ coe c))
      
  eq_iff_exists := fun a b =>
    ⟨fun h =>
      ⟨1, by
        ext
        simpa using h⟩,
      fun ⟨c, h⟩ => congr_argₓ coe ((mul_eq_mul_right_iff.1 h).resolve_right (nonZeroDivisors.ne_zero c.2))⟩

/-- The value group of the valuation associated to `A`. Note: it is actually a group with zero. -/
def ValueGroup :=
  ValuationRing.ValueGroup A K deriving LinearOrderedCommGroupWithZero

/-- Any valuation subring of `K` induces a natural valuation on `K`. -/
def valuation : Valuation K A.ValueGroup :=
  ValuationRing.valuation A K

instance inhabitedValueGroup : Inhabited A.ValueGroup :=
  ⟨A.Valuation 0⟩

theorem valuation_le_one (a : A) : A.Valuation a ≤ 1 :=
  (ValuationRing.mem_integer_iff A K _).2 ⟨a, rfl⟩

theorem mem_of_valuation_le_one (x : K) (h : A.Valuation x ≤ 1) : x ∈ A :=
  let ⟨a, ha⟩ := (ValuationRing.mem_integer_iff A K x).1 h
  ha ▸ a.2

theorem valuation_le_one_iff (x : K) : A.Valuation x ≤ 1 ↔ x ∈ A :=
  ⟨mem_of_valuation_le_one _ _, fun ha => A.valuation_le_one ⟨x, ha⟩⟩

theorem valuation_eq_iff (x y : K) : A.Valuation x = A.Valuation y ↔ ∃ a : Aˣ, (a : K) * y = x :=
  Quotientₓ.eq'

theorem valuation_le_iff (x y : K) : A.Valuation x ≤ A.Valuation y ↔ ∃ a : A, (a : K) * y = x :=
  Iff.rfl

theorem valuation_surjective : Function.Surjective A.Valuation :=
  surjective_quot_mk _

theorem valuation_unit (a : Aˣ) : A.Valuation a = 1 := by
  rw [← A.valuation.map_one, valuation_eq_iff]
  use a
  simp

theorem valuation_eq_one_iff (a : A) : IsUnit a ↔ A.Valuation a = 1 :=
  ⟨fun h => A.valuation_unit h.Unit, fun h => by
    have ha : (a : K) ≠ 0 := by
      intro c
      rw [c, A.valuation.map_zero] at h
      exact zero_ne_one h
    have ha' : (a : K)⁻¹ ∈ A := by
      rw [← valuation_le_one_iff, map_inv₀, h, inv_one]
    apply is_unit_of_mul_eq_one a ⟨a⁻¹, ha'⟩
    ext
    field_simp⟩

theorem valuation_lt_one_or_eq_one (a : A) : A.Valuation a < 1 ∨ A.Valuation a = 1 :=
  lt_or_eq_of_leₓ (A.valuation_le_one a)

theorem valuation_lt_one_iff (a : A) : a ∈ LocalRing.maximalIdeal A ↔ A.Valuation a < 1 := by
  rw [LocalRing.mem_maximal_ideal]
  dsimp' [Nonunits]
  rw [valuation_eq_one_iff]
  exact (A.valuation_le_one a).lt_iff_ne.symm

/-- A subring `R` of `K` such that for all `x : K` either `x ∈ R` or `x⁻¹ ∈ R` is
  a valuation subring of `K`. -/
def ofSubring (R : Subring K) (hR : ∀ x : K, x ∈ R ∨ x⁻¹ ∈ R) : ValuationSubring K :=
  { R with mem_or_inv_mem' := hR }

@[simp]
theorem mem_of_subring (R : Subring K) (hR : ∀ x : K, x ∈ R ∨ x⁻¹ ∈ R) (x : K) : x ∈ ofSubring R hR ↔ x ∈ R :=
  Iff.refl _

/-- An overring of a valuation ring is a valuation ring. -/
def ofLe (R : ValuationSubring K) (S : Subring K) (h : R.toSubring ≤ S) : ValuationSubring K :=
  { S with mem_or_inv_mem' := fun x => (R.mem_or_inv_mem x).imp (@h x) (@h _) }

section Order

instance : SemilatticeSup (ValuationSubring K) :=
  { (inferInstance : PartialOrderₓ (ValuationSubring K)) with
    sup := fun R S => ofLe R (R.toSubring⊔S.toSubring) <| le_sup_left,
    le_sup_left := fun R S x hx => (le_sup_left : R.toSubring ≤ R.toSubring⊔S.toSubring) hx,
    le_sup_right := fun R S x hx => (le_sup_right : S.toSubring ≤ R.toSubring⊔S.toSubring) hx,
    sup_le := fun R S T hR hT x hx => (sup_le hR hT : R.toSubring⊔S.toSubring ≤ T.toSubring) hx }

/-- The ring homomorphism induced by the partial order. -/
def inclusion (R S : ValuationSubring K) (h : R ≤ S) : R →+* S :=
  Subring.inclusion h

/-- The canonical ring homomorphism from a valuation ring to its field of fractions. -/
def subtype (R : ValuationSubring K) : R →+* K :=
  Subring.subtype R.toSubring

/-- The canonical map on value groups induced by a coarsening of valuation rings. -/
def mapOfLe (R S : ValuationSubring K) (h : R ≤ S) : R.ValueGroup →*₀ S.ValueGroup where
  toFun := (Quotientₓ.map' id) fun x y ⟨u, hu⟩ => ⟨Units.map (R.inclusion S h).toMonoidHom u, hu⟩
  map_zero' := rfl
  map_one' := rfl
  map_mul' := by
    rintro ⟨⟩ ⟨⟩
    rfl

@[mono]
theorem monotone_map_of_le (R S : ValuationSubring K) (h : R ≤ S) : Monotone (R.mapOfLe S h) := by
  rintro ⟨⟩ ⟨⟩ ⟨a, ha⟩
  exact ⟨R.inclusion S h a, ha⟩

@[simp]
theorem map_of_le_comp_valuation (R S : ValuationSubring K) (h : R ≤ S) : R.mapOfLe S h ∘ R.Valuation = S.Valuation :=
  by
  ext
  rfl

@[simp]
theorem map_of_le_valuation_apply (R S : ValuationSubring K) (h : R ≤ S) (x : K) :
    R.mapOfLe S h (R.Valuation x) = S.Valuation x :=
  rfl

/-- The ideal corresponding to a coarsening of a valuation ring. -/
def idealOfLe (R S : ValuationSubring K) (h : R ≤ S) : Ideal R :=
  (LocalRing.maximalIdeal S).comap (R.inclusion S h)

instance prime_ideal_of_le (R S : ValuationSubring K) (h : R ≤ S) : (idealOfLe R S h).IsPrime :=
  (LocalRing.maximalIdeal S).comap_is_prime _

/-- The coarsening of a valuation ring associated to a prime ideal. -/
def ofPrime (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] : ValuationSubring K :=
  (ofLe A
      (Localization.subalgebra.ofField K P.primeCompl <|
          le_non_zero_divisors_of_no_zero_divisors <| not_not_intro P.zero_mem).toSubring)
    fun a ha => Subalgebra.algebra_map_mem _ (⟨a, ha⟩ : A)

instance ofPrimeAlgebra (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] : Algebra A (A.ofPrime P) :=
  Subalgebra.algebra _

instance of_prime_scalar_tower (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] : IsScalarTower A (A.ofPrime P) K :=
  IsScalarTower.subalgebra' A K K _

instance of_prime_localization (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] :
    IsLocalization.AtPrime (A.ofPrime P) P := by
  apply Localization.subalgebra.is_localization_of_field K

theorem le_of_prime (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] : A ≤ ofPrime A P := fun a ha =>
  Subalgebra.algebra_map_mem _ (⟨a, ha⟩ : A)

theorem of_prime_valuation_eq_one_iff_mem_prime_compl (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] (x : A) :
    (ofPrime A P).Valuation x = 1 ↔ x ∈ P.primeCompl := by
  rw [← IsLocalization.AtPrime.is_unit_to_map_iff (A.of_prime P) P x, valuation_eq_one_iff]
  rfl

@[simp]
theorem ideal_of_le_of_prime (A : ValuationSubring K) (P : Ideal A) [P.IsPrime] :
    idealOfLe A (ofPrime A P) (le_of_prime A P) = P := by
  ext
  apply IsLocalization.AtPrime.to_map_mem_maximal_iff

@[simp]
theorem of_prime_ideal_of_le (R S : ValuationSubring K) (h : R ≤ S) : ofPrime R (idealOfLe R S h) = S := by
  ext x
  constructor
  · rintro ⟨a, r, hr, rfl⟩
    apply mul_mem
    · exact h a.2
      
    · rw [← valuation_le_one_iff, map_inv₀, ← inv_one, inv_le_inv₀]
      · exact not_ltₓ.1 ((not_iff_not.2 <| valuation_lt_one_iff S _).1 hr)
        
      · intro hh
        erw [Valuation.zero_iff, Subring.coe_eq_zero_iff] at hh
        apply hr
        rw [hh]
        apply Ideal.zero_mem (R.ideal_of_le S h)
        
      · exact one_ne_zero
        
      
    
  · intro hx
    by_cases' hr : x ∈ R
    · exact R.le_of_prime _ hr
      
    have : x ≠ 0 := fun h =>
      hr
        (by
          rw [h]
          exact R.zero_mem)
    replace hr := (R.mem_or_inv_mem x).resolve_left hr
    · use 1, x⁻¹, hr
      constructor
      · change (⟨x⁻¹, h hr⟩ : S) ∉ Nonunits S
        erw [mem_nonunits_iff, not_not]
        apply is_unit_of_mul_eq_one _ (⟨x, hx⟩ : S)
        ext
        field_simp
        
      · field_simp
        
      
    

theorem of_prime_le_of_le (P Q : Ideal A) [P.IsPrime] [Q.IsPrime] (h : P ≤ Q) : ofPrime A Q ≤ ofPrime A P :=
  fun x ⟨a, s, hs, he⟩ => ⟨a, s, fun c => hs (h c), he⟩

theorem ideal_of_le_le_of_le (R S : ValuationSubring K) (hR : A ≤ R) (hS : A ≤ S) (h : R ≤ S) :
    idealOfLe A S hS ≤ idealOfLe A R hR := fun x hx =>
  (valuation_lt_one_iff R _).2
    (by
      by_contra c
      push_neg  at c
      replace c := monotone_map_of_le R S h c
      rw [(map_of_le _ _ _).map_one, map_of_le_valuation_apply] at c
      apply not_le_of_ltₓ ((valuation_lt_one_iff S _).1 hx) c)

/-- The equivalence between coarsenings of a valuation ring and its prime ideals.-/
@[simps]
def primeSpectrumEquiv : PrimeSpectrum A ≃ { S | A ≤ S } where
  toFun := fun P => ⟨ofPrime A P.asIdeal, le_of_prime _ _⟩
  invFun := fun S => ⟨idealOfLe _ S S.2, inferInstance⟩
  left_inv := fun P => by
    ext1
    simpa
  right_inv := fun S => by
    ext1
    simp

/-- An ordered variant of `prime_spectrum_equiv`. -/
@[simps]
def primeSpectrumOrderEquiv : (PrimeSpectrum A)ᵒᵈ ≃o { S | A ≤ S } :=
  { primeSpectrumEquiv A with
    map_rel_iff' := fun P Q =>
      ⟨fun h => by
        have := ideal_of_le_le_of_le A _ _ _ _ h
        iterate 2 
          erw [ideal_of_le_of_prime] at this
        exact this, fun h => by
        apply of_prime_le_of_le
        exact h⟩ }

instance linearOrderOverring : LinearOrderₓ { S | A ≤ S } :=
  { (inferInstance : PartialOrderₓ _) with
    le_total :=
      let i : IsTotal (PrimeSpectrum A) (· ≤ ·) := (Subtype.relEmbedding _ _).IsTotal
      (prime_spectrum_order_equiv A).symm.toRelEmbedding.IsTotal.Total,
    decidableLe := inferInstance }

end Order

end ValuationSubring

namespace Valuation

variable {K} {Γ Γ₁ Γ₂ : Type _} [LinearOrderedCommGroupWithZero Γ] [LinearOrderedCommGroupWithZero Γ₁]
  [LinearOrderedCommGroupWithZero Γ₂] (v : Valuation K Γ) (v₁ : Valuation K Γ₁) (v₂ : Valuation K Γ₂)

/-- The valuation subring associated to a valuation. -/
def valuationSubring : ValuationSubring K :=
  { v.integer with
    mem_or_inv_mem' := by
      intro x
      cases le_or_ltₓ (v x) 1
      · left
        exact h
        
      · right
        change v x⁻¹ ≤ 1
        rw [map_inv₀ v, ← inv_one, inv_le_inv₀]
        · exact le_of_ltₓ h
          
        · intro c
          simpa [c] using h
          
        · exact one_ne_zero
          
         }

@[simp]
theorem mem_valuation_subring_iff (x : K) : x ∈ v.ValuationSubring ↔ v x ≤ 1 :=
  Iff.refl _

theorem is_equiv_iff_valuation_subring : v₁.IsEquiv v₂ ↔ v₁.ValuationSubring = v₂.ValuationSubring := by
  constructor
  · intro h
    ext x
    specialize h x 1
    simpa using h
    
  · intro h
    apply is_equiv_of_val_le_one
    intro x
    have : x ∈ v₁.valuation_subring ↔ x ∈ v₂.valuation_subring := by
      rw [h]
    simpa using this
    

theorem is_equiv_valuation_valuation_subring : v.IsEquiv v.ValuationSubring.Valuation := by
  rw [is_equiv_iff_val_le_one]
  intro x
  rw [ValuationSubring.valuation_le_one_iff]
  rfl

end Valuation

namespace ValuationSubring

variable {K} (A : ValuationSubring K)

@[simp]
theorem valuation_subring_valuation : A.Valuation.ValuationSubring = A := by
  ext
  rw [← A.valuation_le_one_iff]
  rfl

section UnitGroup

/-- The unit group of a valuation subring, as a subgroup of `Kˣ`. -/
def unitGroup : Subgroup Kˣ :=
  (A.Valuation.toMonoidWithZeroHom.toMonoidHom.comp (Units.coeHom K)).ker

theorem mem_unit_group_iff (x : Kˣ) : x ∈ A.unitGroup ↔ A.Valuation x = 1 :=
  Iff.rfl

/-- For a valuation subring `A`, `A.unit_group` agrees with the units of `A`. -/
def unitGroupMulEquiv : A.unitGroup ≃* Aˣ where
  toFun := fun x =>
    { val := ⟨x, mem_of_valuation_le_one A _ x.Prop.le⟩, inv := ⟨↑x⁻¹, mem_of_valuation_le_one _ _ x⁻¹.Prop.le⟩,
      val_inv := Subtype.ext (Units.mul_inv x), inv_val := Subtype.ext (Units.inv_mul x) }
  invFun := fun x => ⟨Units.map A.Subtype.toMonoidHom x, A.valuation_unit x⟩
  left_inv := fun a => by
    ext
    rfl
  right_inv := fun a => by
    ext
    rfl
  map_mul' := fun a b => by
    ext
    rfl

@[simp]
theorem coe_unit_group_mul_equiv_apply (a : A.unitGroup) : (A.unitGroupMulEquiv a : K) = a :=
  rfl

@[simp]
theorem coe_unit_group_mul_equiv_symm_apply (a : Aˣ) : (A.unitGroupMulEquiv.symm a : K) = a :=
  rfl

theorem unit_group_le_unit_group {A B : ValuationSubring K} : A.unitGroup ≤ B.unitGroup ↔ A ≤ B := by
  constructor
  · intro h x hx
    rw [← A.valuation_le_one_iff x, le_iff_lt_or_eqₓ] at hx
    by_cases' h_1 : x = 0
    · simp only [h_1, zero_mem]
      
    by_cases' h_2 : 1 + x = 0
    · simp only [← add_eq_zero_iff_neg_eq.1 h_2, neg_mem _ _ (one_mem _)]
      
    cases hx
    · have := h (show Units.mk0 _ h_2 ∈ A.unit_group from A.valuation.map_one_add_of_lt hx)
      simpa using
        B.add_mem _ _ (show 1 + x ∈ B from SetLike.coe_mem (B.unit_group_mul_equiv ⟨_, this⟩ : B))
          (B.neg_mem _ B.one_mem)
      
    · have := h (show Units.mk0 x h_1 ∈ A.unit_group from hx)
      refine' SetLike.coe_mem (B.unit_group_mul_equiv ⟨_, this⟩ : B)
      
    
  · rintro h x (hx : A.valuation x = 1)
    apply_fun A.map_of_le B h  at hx
    simpa using hx
    

theorem unit_group_injective : Function.Injective (unitGroup : ValuationSubring K → Subgroup _) := fun A B h => by
  simpa only [le_antisymm_iffₓ, unit_group_le_unit_group] using h

theorem eq_iff_unit_group {A B : ValuationSubring K} : A = B ↔ A.unitGroup = B.unitGroup :=
  unit_group_injective.eq_iff.symm

/-- The map on valuation subrings to their unit groups is an order embedding. -/
def unitGroupOrderEmbedding : ValuationSubring K ↪o Subgroup Kˣ where
  toFun := fun A => A.unitGroup
  inj' := unit_group_injective
  map_rel_iff' := fun A B => unit_group_le_unit_group

theorem unit_group_strict_mono : StrictMono (unitGroup : ValuationSubring K → Subgroup _) :=
  unitGroupOrderEmbedding.StrictMono

end UnitGroup

section Nonunits

/-- The nonunits of a valuation subring of `K`, as a subsemigroup of `K`-/
def nonunits : Subsemigroup K where
  Carrier := { x | A.Valuation x < 1 }
  mul_mem' := fun a b ha hb => (mul_lt_mul₀ ha hb).trans_eq <| mul_oneₓ _

theorem mem_nonunits_iff {x : K} : x ∈ A.Nonunits ↔ A.Valuation x < 1 :=
  Iff.rfl

theorem nonunits_le_nonunits {A B : ValuationSubring K} : B.Nonunits ≤ A.Nonunits ↔ A ≤ B := by
  constructor
  · intro h x hx
    by_cases' h_1 : x = 0
    · simp only [h_1, zero_mem]
      
    rw [← valuation_le_one_iff, ← not_ltₓ, Valuation.one_lt_val_iff _ h_1] at hx⊢
    by_contra h_2
    exact hx (h h_2)
    
  · intro h x hx
    by_contra h_1
    exact not_ltₓ.2 (monotone_map_of_le _ _ h (not_ltₓ.1 h_1)) hx
    

theorem nonunits_injective : Function.Injective (nonunits : ValuationSubring K → Subsemigroup _) := fun A B h => by
  simpa only [le_antisymm_iffₓ, nonunits_le_nonunits] using h.symm

theorem nonunits_inj {A B : ValuationSubring K} : A.Nonunits = B.Nonunits ↔ A = B :=
  nonunits_injective.eq_iff

/-- The map on valuation subrings to their nonunits is a dual order embedding. -/
def nonunitsOrderEmbedding : ValuationSubring K ↪o (Subsemigroup K)ᵒᵈ where
  toFun := fun A => A.Nonunits
  inj' := nonunits_injective
  map_rel_iff' := fun A B => nonunits_le_nonunits

variable {A}

/-- The elements of `A.nonunits` are those of the maximal ideal of `A` after coercion to `K`.

See also `mem_nonunits_iff_exists_mem_maximal_ideal`, which gets rid of the coercion to `K`,
at the expense of a more complicated right hand side.
 -/
theorem coe_mem_nonunits_iff {a : A} : (a : K) ∈ A.Nonunits ↔ a ∈ LocalRing.maximalIdeal A :=
  (valuation_lt_one_iff _ _).symm

theorem nonunits_le : A.Nonunits ≤ A.toSubring.toSubmonoid.toSubsemigroup := fun a ha =>
  (A.valuation_le_one_iff _).mp (A.mem_nonunits_iff.mp ha).le

theorem nonunits_subset : (A.Nonunits : Set K) ⊆ A :=
  nonunits_le

/-- The elements of `A.nonunits` are those of the maximal ideal of `A`.

See also `coe_mem_nonunits_iff`, which has a simpler right hand side but requires the element
to be in `A` already.
 -/
theorem mem_nonunits_iff_exists_mem_maximal_ideal {a : K} :
    a ∈ A.Nonunits ↔ ∃ ha, (⟨a, ha⟩ : A) ∈ LocalRing.maximalIdeal A :=
  ⟨fun h => ⟨nonunits_subset h, coe_mem_nonunits_iff.mp h⟩, fun ⟨ha, h⟩ => coe_mem_nonunits_iff.mpr h⟩

/-- `A.nonunits` agrees with the maximal ideal of `A`, after taking its image in `K`. -/
theorem image_maximal_ideal : (coe : A → K) '' LocalRing.maximalIdeal A = A.Nonunits := by
  ext a
  simp only [Set.mem_image, SetLike.mem_coe, mem_nonunits_iff_exists_mem_maximal_ideal]
  erw [Subtype.exists]
  simp_rw [Subtype.coe_mk, exists_and_distrib_right, exists_eq_right]

end Nonunits

section PrincipalUnitGroup

/-- The principal unit group of a valuation subring, as a subgroup of `Kˣ`. -/
def principalUnitGroup : Subgroup Kˣ where
  Carrier := { x | A.Valuation (x - 1) < 1 }
  mul_mem' := by
    intro a b ha hb
    refine' lt_of_le_of_ltₓ _ (max_ltₓ hb ha)
    rw [← one_mulₓ (A.valuation (b - 1)), ← A.valuation.map_one_add_of_lt ha, add_sub_cancel'_right, ←
      Valuation.map_mul, mul_sub_one, ← sub_add_sub_cancel]
    exact A.valuation.map_add _ _
  one_mem' := by
    simpa using zero_lt_one₀
  inv_mem' := by
    dsimp'
    intro a ha
    conv => lhs rw [← mul_oneₓ (A.valuation _), ← A.valuation.map_one_add_of_lt ha]
    rwa [add_sub_cancel'_right, ← Valuation.map_mul, sub_mul, Units.inv_mul, ← neg_sub, one_mulₓ, Valuation.map_neg]

theorem principal_units_le_units : A.principalUnitGroup ≤ A.unitGroup := fun a h => by
  simpa only [add_sub_cancel'_right] using A.valuation.map_one_add_of_lt h

theorem mem_principal_unit_group_iff (x : Kˣ) : x ∈ A.principalUnitGroup ↔ A.Valuation ((x : K) - 1) < 1 :=
  Iff.rfl

theorem principal_unit_group_le_principal_unit_group {A B : ValuationSubring K} :
    B.principalUnitGroup ≤ A.principalUnitGroup ↔ A ≤ B := by
  constructor
  · intro h x hx
    by_cases' h_1 : x = 0
    · simp only [h_1, zero_mem]
      
    by_cases' h_2 : x⁻¹ + 1 = 0
    · rw [add_eq_zero_iff_eq_neg, inv_eq_iff_inv_eq, inv_neg, inv_one] at h_2
      simpa only [h_2] using B.neg_mem _ B.one_mem
      
    · rw [← valuation_le_one_iff, ← not_ltₓ, Valuation.one_lt_val_iff _ h_1, ← add_sub_cancel x⁻¹, ← Units.coe_mk0 h_2,
        ← mem_principal_unit_group_iff] at hx⊢
      simpa only [hx] using @h (Units.mk0 (x⁻¹ + 1) h_2)
      
    
  · intro h x hx
    by_contra h_1
    exact not_ltₓ.2 (monotone_map_of_le _ _ h (not_ltₓ.1 h_1)) hx
    

theorem principal_unit_group_injective : Function.Injective (principalUnitGroup : ValuationSubring K → Subgroup _) :=
  fun A B h => by
  simpa [le_antisymm_iffₓ, principal_unit_group_le_principal_unit_group] using h.symm

theorem eq_iff_principal_unit_group {A B : ValuationSubring K} : A = B ↔ A.principalUnitGroup = B.principalUnitGroup :=
  principal_unit_group_injective.eq_iff.symm

/-- The map on valuation subrings to their principal unit groups is an order embedding. -/
def principalUnitGroupOrderEmbedding : ValuationSubring K ↪o (Subgroup Kˣ)ᵒᵈ where
  toFun := fun A => A.principalUnitGroup
  inj' := principal_unit_group_injective
  map_rel_iff' := fun A B => principal_unit_group_le_principal_unit_group

theorem coe_mem_principal_unit_group_iff {x : A.unitGroup} :
    (x : Kˣ) ∈ A.principalUnitGroup ↔ A.unitGroupMulEquiv x ∈ (Units.map (LocalRing.residue A).toMonoidHom).ker := by
  rw [MonoidHom.mem_ker, Units.ext_iff]
  dsimp'
  let π := Ideal.Quotient.mk (LocalRing.maximalIdeal A)
  change _ ↔ π _ = _
  rw [← π.map_one, ← sub_eq_zero, ← π.map_sub, Ideal.Quotient.eq_zero_iff_mem, valuation_lt_one_iff]
  simpa

/-- The principal unit group agrees with the kernel of the canonical map from
the units of `A` to the units of the residue field of `A`. -/
def principalUnitGroupEquiv : A.principalUnitGroup ≃* (Units.map (LocalRing.residue A).toMonoidHom).ker where
  toFun := fun x => ⟨A.unitGroupMulEquiv ⟨_, A.principal_units_le_units x.2⟩, A.coe_mem_principal_unit_group_iff.1 x.2⟩
  invFun := fun x =>
    ⟨A.unitGroupMulEquiv.symm x, by
      rw [A.coe_mem_principal_unit_group_iff]
      simpa using SetLike.coe_mem x⟩
  left_inv := fun x => by
    simp
  right_inv := fun x => by
    simp
  map_mul' := fun x y => by
    rfl

@[simp]
theorem principal_unit_group_equiv_apply (a : A.principalUnitGroup) : (principalUnitGroupEquiv A a : K) = a :=
  rfl

@[simp]
theorem principal_unit_group_symm_apply (a : (Units.map (LocalRing.residue A).toMonoidHom).ker) :
    (A.principalUnitGroupEquiv.symm a : K) = a :=
  rfl

/-- The canonical map from the unit group of `A` to the units of the residue field of `A`. -/
def unitGroupToResidueFieldUnits : A.unitGroup →* (LocalRing.ResidueField A)ˣ :=
  MonoidHom.comp (Units.map <| (Ideal.Quotient.mk _).toMonoidHom) A.unitGroupMulEquiv.toMonoidHom

@[simp]
theorem coe_unit_group_to_residue_field_units_apply (x : A.unitGroup) :
    (A.unitGroupToResidueFieldUnits x : LocalRing.ResidueField A) = Ideal.Quotient.mk _ (A.unitGroupMulEquiv x : A) :=
  rfl

theorem ker_unit_group_to_residue_field_units :
    A.unitGroupToResidueFieldUnits.ker = A.principalUnitGroup.comap A.unitGroup.Subtype := by
  ext
  simpa only [Subgroup.mem_comap, Subgroup.coe_subtype, coe_mem_principal_unit_group_iff]

theorem surjective_unit_group_to_residue_field_units : Function.Surjective A.unitGroupToResidueFieldUnits :=
  (LocalRing.surjective_units_map_of_local_ring_hom _ Ideal.Quotient.mk_surjective
        LocalRing.is_local_ring_hom_residue).comp
    (MulEquiv.surjective _)

/-- The quotient of the unit group of `A` by the principal unit group of `A` agrees with
the units of the residue field of `A`. -/
def unitsModPrincipalUnitsEquivResidueFieldUnits :
    A.unitGroup ⧸ A.principalUnitGroup.comap A.unitGroup.Subtype ≃* (LocalRing.ResidueField A)ˣ :=
  MulEquiv.trans (QuotientGroup.equivQuotientOfEq A.ker_unit_group_to_residue_field_units.symm)
    (QuotientGroup.quotientKerEquivOfSurjective _ A.surjective_unit_group_to_residue_field_units)

@[simp]
theorem units_mod_principal_units_equiv_residue_field_units_comp_quotient_group_mk :
    A.unitsModPrincipalUnitsEquivResidueFieldUnits.toMonoidHom.comp (QuotientGroup.mk' _) =
      A.unitGroupToResidueFieldUnits :=
  rfl

@[simp]
theorem units_mod_principal_units_equiv_residue_field_units_comp_quotient_group_mk_apply (x : A.unitGroup) :
    A.unitsModPrincipalUnitsEquivResidueFieldUnits.toMonoidHom (QuotientGroup.mk x) =
      A.unitGroupToResidueFieldUnits x :=
  rfl

end PrincipalUnitGroup

/-! ### Pointwise actions

This transfers the action from `subring.pointwise_mul_action`, noting that it only applies when
the action is by a group. Notably this provides an instances when `G` is `K ≃+* K`.

These instances are in the `pointwise` locale.

The lemmas in this section are copied from `ring_theory/subring/pointwise.lean`; try to keep these
in sync.
-/


section PointwiseActions

open Pointwise

variable {G : Type _} [Groupₓ G] [MulSemiringAction G K]

/-- The action on a valuation subring corresponding to applying the action to every element.

This is available as an instance in the `pointwise` locale. -/
def pointwiseHasSmul :
    HasSmul G
      (ValuationSubring
        K) where smul := fun g S =>
    -- TODO: if we add `valuation_subring.map` at a later date, we should use it here
    { g • S.toSubring with
      mem_or_inv_mem' := fun x =>
        (mem_or_inv_mem S (g⁻¹ • x)).imp Subring.mem_pointwise_smul_iff_inv_smul_mem.mpr fun h =>
          Subring.mem_pointwise_smul_iff_inv_smul_mem.mpr <| by
            rwa [smul_inv''] }

localized [Pointwise] attribute [instance] ValuationSubring.pointwiseHasSmul

open Pointwise

@[simp]
theorem coe_pointwise_smul (g : G) (S : ValuationSubring K) : ↑(g • S) = g • (S : Set K) :=
  rfl

@[simp]
theorem pointwise_smul_to_subring (g : G) (S : ValuationSubring K) : (g • S).toSubring = g • S.toSubring :=
  rfl

/-- The action on a valuation subring corresponding to applying the action to every element.

This is available as an instance in the `pointwise` locale.

This is a stronger version of `valuation_subring.pointwise_has_smul`. -/
def pointwiseMulAction : MulAction G (ValuationSubring K) :=
  to_subring_injective.MulAction toSubring pointwise_smul_to_subring

localized [Pointwise] attribute [instance] ValuationSubring.pointwiseMulAction

open Pointwise

theorem smul_mem_pointwise_smul (g : G) (x : K) (S : ValuationSubring K) : x ∈ S → g • x ∈ g • S :=
  (Set.smul_mem_smul_set : _ → _ ∈ g • (S : Set K))

theorem mem_smul_pointwise_iff_exists (g : G) (x : K) (S : ValuationSubring K) :
    x ∈ g • S ↔ ∃ s : K, s ∈ S ∧ g • s = x :=
  (Set.mem_smul_set : x ∈ g • (S : Set K) ↔ _)

instance pointwise_central_scalar [MulSemiringAction Gᵐᵒᵖ K] [IsCentralScalar G K] :
    IsCentralScalar G (ValuationSubring K) :=
  ⟨fun g S => to_subring_injective <| op_smul_eq_smul g S.to_subring⟩

@[simp]
theorem smul_mem_pointwise_smul_iff {g : G} {S : ValuationSubring K} {x : K} : g • x ∈ g • S ↔ x ∈ S :=
  Set.smul_mem_smul_set_iff

theorem mem_pointwise_smul_iff_inv_smul_mem {g : G} {S : ValuationSubring K} {x : K} : x ∈ g • S ↔ g⁻¹ • x ∈ S :=
  Set.mem_smul_set_iff_inv_smul_mem

theorem mem_inv_pointwise_smul_iff {g : G} {S : ValuationSubring K} {x : K} : x ∈ g⁻¹ • S ↔ g • x ∈ S :=
  Set.mem_inv_smul_set_iff

@[simp]
theorem pointwise_smul_le_pointwise_smul_iff {g : G} {S T : ValuationSubring K} : g • S ≤ g • T ↔ S ≤ T :=
  Set.set_smul_subset_set_smul_iff

theorem pointwise_smul_subset_iff {g : G} {S T : ValuationSubring K} : g • S ≤ T ↔ S ≤ g⁻¹ • T :=
  Set.set_smul_subset_iff

theorem subset_pointwise_smul_iff {g : G} {S T : ValuationSubring K} : S ≤ g • T ↔ g⁻¹ • S ≤ T :=
  Set.subset_set_smul_iff

end PointwiseActions

end ValuationSubring

