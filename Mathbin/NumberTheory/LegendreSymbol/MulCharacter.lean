/-
Copyright (c) 2022 Michael Stoll. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Michael Stoll
-/
import Mathbin.RingTheory.IntegralDomain

/-!
# Multiplicative characters of finite rings and fields

Let `R` and `R'` be a commutative rings.
A *multiplicative character* of `R` with values in `R'` is a morphism of
monoids from the multiplicative monoid of `R` into that of `R'`
that sends non-units to zero.

We use the namespace `mul_char` for the definitions and results.

## Main results

We show that the multiplicative characters form a group (if `R'` is commutative);
see `mul_char.comm_group`. We also provide an equivalence with the
homomorphisms `Rˣ →* R'ˣ`; see `mul_char.equiv_to_unit_hom`.

We define a multiplicative character to be *quadratic* if its values
are among `0`, `1` and `-1`, and we prove some properties of quadratic characters.

Finally, we show that the sum of all values of a nontrivial multiplicative
character vanishes; see `mul_char.is_nontrivial.sum_eq_zero`.

## Tags

multiplicative character
-/


section DefinitionAndGroup

/-!
### Definitions related to multiplicative characters

Even though the intended use is when domain and target of the characters
are commutative rings, we define them in the more general setting when
the domain is a commutative monoid and the target is a commutative monoid
with zero. (We need a zero in the target, since non-units are supposed
to map to zero.)

In this setting, there is an equivalence between multiplicative characters
`R → R'` and group homomorphisms `Rˣ → R'ˣ`, and the multiplicative characters
have a natural structure as a commutative group.
-/


universe u v

section Defi

-- The domain of our multiplicative characters
variable (R : Type u) [CommMonoidₓ R]

-- The target
variable (R' : Type v) [CommMonoidWithZero R']

/-- Define a structure for multiplicative characters.
A multiplicative character from a commutative monoid `R` to a commutative monoid with zero `R'`
is a homomorphism of (multiplicative) monoids that sends non-units to zero. -/
structure MulChar extends MonoidHom R R' where
  map_nonunit' : ∀ a : R, ¬IsUnit a → to_fun a = 0

/-- This is the corresponding extension of `monoid_hom_class`. -/
class MulCharClass (F : Type _) (R R' : outParam <| Type _) [CommMonoidₓ R] [CommMonoidWithZero R'] extends
  MonoidHomClass F R R' where
  map_nonunit : ∀ (χ : F) {a : R} (ha : ¬IsUnit a), χ a = 0

attribute [simp] MulCharClass.map_nonunit

end Defi

section Groupₓ

namespace MulChar

-- The domain of our multiplicative characters
variable {R : Type u} [CommMonoidₓ R]

-- The target
variable {R' : Type v} [CommMonoidWithZero R']

instance coeToFun : CoeFun (MulChar R R') fun _ => R → R' :=
  ⟨fun χ => χ.toFun⟩

/-- See note [custom simps projection] -/
protected def Simps.apply (χ : MulChar R R') : R → R' :=
  χ

initialize_simps_projections MulChar (to_monoid_hom_to_fun → apply, -toMonoidHom)

section trivialₓ

variable (R R')

/-- The trivial multiplicative character. It takes the value `0` on non-units and
the value `1` on units. -/
@[simps]
noncomputable def trivial : MulChar R R' where
  toFun := by
    classical
    exact fun x => if IsUnit x then 1 else 0
  map_nonunit' := by
    intro a ha
    simp only [ha, if_false]
  map_one' := by
    simp only [is_unit_one, if_true]
  map_mul' := by
    intro x y
    simp only [IsUnit.mul_iff, boole_mul]
    split_ifs <;> tauto

end trivialₓ

@[simp]
theorem coe_coe (χ : MulChar R R') : (χ.toMonoidHom : R → R') = χ :=
  rfl

@[simp]
theorem to_fun_eq_coe (χ : MulChar R R') : χ.toFun = χ :=
  rfl

@[simp]
theorem coe_mk (f : R →* R') (hf) : (MulChar.mk f hf : R → R') = f :=
  rfl

/-- Extensionality. See `ext` below for the version that will actually be used. -/
theorem ext' {χ χ' : MulChar R R'} (h : ∀ a, χ a = χ' a) : χ = χ' := by
  cases χ
  cases χ'
  congr
  exact MonoidHom.ext h

instance : MulCharClass (MulChar R R') R R' where
  coe := fun χ => χ.toMonoidHom.toFun
  coe_injective' := fun f g h => ext' fun a => congr_funₓ h a
  map_mul := fun χ => χ.map_mul'
  map_one := fun χ => χ.map_one'
  map_nonunit := fun χ => χ.map_nonunit'

theorem map_nonunit (χ : MulChar R R') {a : R} (ha : ¬IsUnit a) : χ a = 0 :=
  χ.map_nonunit' a ha

/-- Extensionality. Since `mul_char`s always take the value zero on non-units, it is sufficient
to compare the values on units. -/
@[ext]
theorem ext {χ χ' : MulChar R R'} (h : ∀ a : Rˣ, χ a = χ' a) : χ = χ' := by
  apply ext'
  intro a
  by_cases' ha : IsUnit a
  · exact h ha.unit
    
  · rw [map_nonunit χ ha, map_nonunit χ' ha]
    

theorem ext_iff {χ χ' : MulChar R R'} : χ = χ' ↔ ∀ a : Rˣ, χ a = χ' a :=
  ⟨by
    rintro rfl a
    rfl, ext⟩

/-!
### Equivalence of multiplicative characters with homomorphisms on units

We show that restriction / extension by zero gives an equivalence
between `mul_char R R'` and `Rˣ →* R'ˣ`.
-/


/-- Turn a `mul_char` into a homomorphism between the unit groups. -/
def toUnitHom (χ : MulChar R R') : Rˣ →* R'ˣ :=
  Units.map χ

theorem coe_to_unit_hom (χ : MulChar R R') (a : Rˣ) : ↑(χ.toUnitHom a) = χ a :=
  rfl

/-- Turn a homomorphism between unit groups into a `mul_char`. -/
noncomputable def ofUnitHom (f : Rˣ →* R'ˣ) : MulChar R R' where
  toFun := by
    classical
    exact fun x => if hx : IsUnit x then f hx.Unit else 0
  map_one' := by
    have h1 : (is_unit_one.unit : Rˣ) = 1 := units.eq_iff.mp rfl
    simp only [h1, dif_pos, Units.coe_eq_one, map_one, is_unit_one]
  map_mul' := by
    intro x y
    by_cases' hx : IsUnit x
    · simp only [hx, IsUnit.mul_iff, true_andₓ, dif_pos]
      by_cases' hy : IsUnit y
      · simp only [hy, dif_pos]
        have hm : (is_unit.mul_iff.mpr ⟨hx, hy⟩).Unit = hx.unit * hy.unit := units.eq_iff.mp rfl
        rw [hm, map_mul]
        norm_cast
        
      · simp only [hy, not_false_iff, dif_neg, mul_zero]
        
      
    · simp only [hx, IsUnit.mul_iff, false_andₓ, not_false_iff, dif_neg, zero_mul]
      
  map_nonunit' := by
    intro a ha
    simp only [ha, not_false_iff, dif_neg]

theorem of_unit_hom_coe (f : Rˣ →* R'ˣ) (a : Rˣ) : of_unit_hom f ↑a = f a := by
  simp [of_unit_hom]

/-- The equivalence between multiplicative characters and homomorphisms of unit groups. -/
noncomputable def equivToUnitHom : MulChar R R' ≃ (Rˣ →* R'ˣ) where
  toFun := to_unit_hom
  invFun := of_unit_hom
  left_inv := by
    intro χ
    ext x
    rw [of_unit_hom_coe, coe_to_unit_hom]
  right_inv := by
    intro f
    ext x
    rw [coe_to_unit_hom, of_unit_hom_coe]

@[simp]
theorem to_unit_hom_eq (χ : MulChar R R') : to_unit_hom χ = equiv_to_unit_hom χ :=
  rfl

@[simp]
theorem of_unit_hom_eq (χ : Rˣ →* R'ˣ) : of_unit_hom χ = equiv_to_unit_hom.symm χ :=
  rfl

@[simp]
theorem coe_equiv_to_unit_hom (χ : MulChar R R') (a : Rˣ) : ↑(equiv_to_unit_hom χ a) = χ a :=
  coe_to_unit_hom χ a

@[simp]
theorem equiv_unit_hom_symm_coe (f : Rˣ →* R'ˣ) (a : Rˣ) : equiv_to_unit_hom.symm f ↑a = f a :=
  of_unit_hom_coe f a

/-!
### Commutative group structure on multiplicative characters

The multiplicative characters `R → R'` form a commutative group.
-/


protected theorem map_one (χ : MulChar R R') : χ (1 : R) = 1 :=
  χ.map_one'

/-- If the domain has a zero (and is nontrivial), then `χ 0 = 0`. -/
protected theorem map_zero {R : Type u} [CommMonoidWithZero R] [Nontrivial R] (χ : MulChar R R') : χ (0 : R) = 0 := by
  rw [map_nonunit χ not_is_unit_zero]

/-- If the domain is a ring `R`, then `χ (ring_char R) = 0`. -/
theorem map_ring_char {R : Type u} [CommRingₓ R] [Nontrivial R] (χ : MulChar R R') : χ (ringChar R) = 0 := by
  rw [ringChar.Nat.cast_ring_char, χ.map_zero]

noncomputable instance hasOne : One (MulChar R R') :=
  ⟨trivialₓ R R'⟩

noncomputable instance inhabited : Inhabited (MulChar R R') :=
  ⟨1⟩

/-- Evaluation of the trivial character -/
@[simp]
theorem one_apply_coe (a : Rˣ) : (1 : MulChar R R') a = 1 :=
  dif_pos a.IsUnit

/-- Multiplication of multiplicative characters. (This needs the target to be commutative.) -/
def mul (χ χ' : MulChar R R') : MulChar R R' :=
  { χ.toMonoidHom * χ'.toMonoidHom with toFun := χ * χ',
    map_nonunit' := fun a ha => by
      simp [map_nonunit χ ha] }

instance hasMul : Mul (MulChar R R') :=
  ⟨mul⟩

theorem mul_apply (χ χ' : MulChar R R') (a : R) : (χ * χ') a = χ a * χ' a :=
  rfl

@[simp]
theorem coe_to_fun_mul (χ χ' : MulChar R R') : ⇑(χ * χ') = χ * χ' :=
  rfl

protected theorem one_mul (χ : MulChar R R') : (1 : MulChar R R') * χ = χ := by
  ext
  simp

protected theorem mul_one (χ : MulChar R R') : χ * 1 = χ := by
  ext
  simp

/-- The inverse of a multiplicative character. We define it as `inverse ∘ χ`. -/
noncomputable def inv (χ : MulChar R R') : MulChar R R' :=
  { MonoidWithZeroₓ.inverse.toMonoidHom.comp χ.toMonoidHom with toFun := fun a => MonoidWithZeroₓ.inverse (χ a),
    map_nonunit' := fun a ha => by
      simp [map_nonunit _ ha] }

noncomputable instance hasInv : Inv (MulChar R R') :=
  ⟨inv⟩

/-- The inverse of a multiplicative character `χ`, applied to `a`, is the inverse of `χ a`. -/
theorem inv_apply_eq_inv (χ : MulChar R R') (a : R) : χ⁻¹ a = Ring.inverse (χ a) :=
  Eq.refl <| inv χ a

/-- The inverse of a multiplicative character `χ`, applied to `a`, is the inverse of `χ a`.
Variant when the target is a field -/
theorem inv_apply_eq_inv' {R' : Type v} [Field R'] (χ : MulChar R R') (a : R) : χ⁻¹ a = (χ a)⁻¹ :=
  (inv_apply_eq_inv χ a).trans <| Ring.inverse_eq_inv (χ a)

/-- When the domain has a zero, then the inverse of a multiplicative character `χ`,
applied to `a`, is `χ` applied to the inverse of `a`. -/
theorem inv_apply {R : Type u} [CommMonoidWithZero R] (χ : MulChar R R') (a : R) : χ⁻¹ a = χ (Ring.inverse a) := by
  by_cases' ha : IsUnit a
  · rw [inv_apply_eq_inv]
    have h := IsUnit.map χ ha
    apply_fun (· * ·) (χ a) using IsUnit.mul_right_injective h
    rw [Ring.mul_inverse_cancel _ h, ← map_mul, Ring.mul_inverse_cancel _ ha, MulChar.map_one]
    
  · revert ha
    nontriviality R
    intro ha
    -- `nontriviality R` by itself doesn't do it
    rw [map_nonunit _ ha, Ring.inverse_non_unit a ha, MulChar.map_zero χ]
    

/-- When the domain has a zero, then the inverse of a multiplicative character `χ`,
applied to `a`, is `χ` applied to the inverse of `a`. -/
theorem inv_apply' {R : Type u} [Field R] (χ : MulChar R R') (a : R) : χ⁻¹ a = χ a⁻¹ :=
  (inv_apply χ a).trans <| congr_argₓ _ (Ring.inverse_eq_inv a)

/-- The product of a character with its inverse is the trivial character. -/
@[simp]
theorem inv_mul (χ : MulChar R R') : χ⁻¹ * χ = 1 := by
  ext x
  rw [coe_to_fun_mul, Pi.mul_apply, inv_apply_eq_inv, Ring.inverse_mul_cancel _ (IsUnit.map _ x.is_unit), one_apply_coe]

/-- The commutative group structure on `mul_char R R'`. -/
noncomputable instance commGroup : CommGroupₓ (MulChar R R') :=
  { one := 1, mul := (· * ·), inv := Inv.inv, mul_left_inv := inv_mul,
    mul_assoc := by
      intro χ₁ χ₂ χ₃
      ext a
      simp [mul_assoc],
    mul_comm := by
      intro χ₁ χ₂
      ext a
      simp [mul_comm],
    one_mul, mul_one }

/-- If `a` is a unit and `n : ℕ`, then `(χ ^ n) a = (χ a) ^ n`. -/
theorem pow_apply_coe (χ : MulChar R R') (n : ℕ) (a : Rˣ) : (χ ^ n) a = χ a ^ n := by
  induction' n with n ih
  · rw [pow_zeroₓ, pow_zeroₓ, one_apply_coe]
    
  · rw [pow_succₓ, pow_succₓ, mul_apply, ih]
    

/-- If `n` is positive, then `(χ ^ n) a = (χ a) ^ n`. -/
theorem pow_apply' (χ : MulChar R R') {n : ℕ} (hn : 0 < n) (a : R) : (χ ^ n) a = χ a ^ n := by
  by_cases' ha : IsUnit a
  · exact pow_apply_coe χ n ha.unit
    
  · rw [map_nonunit (χ ^ n) ha, map_nonunit χ ha, zero_pow hn]
    

end MulChar

end Groupₓ

end DefinitionAndGroup

/-!
### Properties of multiplicative characters

We introduce the properties of being nontrivial or quadratic and prove
some basic facts about them.

We now assume that domain and target are commutative rings.
-/


section Properties

namespace MulChar

universe u v w

variable {R : Type u} [CommRingₓ R] {R' : Type v} [CommRingₓ R'] {R'' : Type w} [CommRingₓ R'']

/-- A multiplicative character is *nontrivial* if it takes a value `≠ 1` on a unit. -/
def IsNontrivial (χ : MulChar R R') : Prop :=
  ∃ a : Rˣ, χ a ≠ 1

/-- A multiplicative character is nontrivial iff it is not the trivial character. -/
theorem is_nontrivial_iff (χ : MulChar R R') : χ.IsNontrivial ↔ χ ≠ 1 := by
  simp only [is_nontrivial, Ne.def, ext_iff, not_forall, one_apply_coe]

/-- A multiplicative character is *quadratic* if it takes only the values `0`, `1`, `-1`. -/
def IsQuadratic (χ : MulChar R R') : Prop :=
  ∀ a, χ a = 0 ∨ χ a = 1 ∨ χ a = -1

/-- If two values of quadratic characters with target `ℤ` agree after coercion into a ring
of characteristic not `2`, then they agree in `ℤ`. -/
theorem IsQuadratic.eq_of_eq_coe {χ : MulChar R ℤ} (hχ : IsQuadratic χ) {χ' : MulChar R' ℤ} (hχ' : IsQuadratic χ')
    [Nontrivial R''] (hR'' : ringChar R'' ≠ 2) {a : R} {a' : R'} (h : (χ a : R'') = χ' a') : χ a = χ' a' :=
  Int.cast_inj_on_of_ring_char_ne_two hR'' (hχ a) (hχ' a') h

/-- We can post-compose a multiplicative character with a ring homomorphism. -/
@[simps]
def ringHomComp (χ : MulChar R R') (f : R' →+* R'') : MulChar R R'' :=
  { f.toMonoidHom.comp χ.toMonoidHom with toFun := fun a => f (χ a),
    map_nonunit' := fun a ha => by
      simp only [map_nonunit χ ha, map_zero] }

/-- Composition with an injective ring homomorphism preserves nontriviality. -/
theorem IsNontrivial.comp {χ : MulChar R R'} (hχ : χ.IsNontrivial) {f : R' →+* R''} (hf : Function.Injective f) :
    (χ.ringHomComp f).IsNontrivial := by
  obtain ⟨a, ha⟩ := hχ
  use a
  rw [ring_hom_comp_apply, ← RingHom.map_one f]
  exact fun h => ha (hf h)

/-- Composition with a ring homomorphism preserves the property of being a quadratic character. -/
theorem IsQuadratic.comp {χ : MulChar R R'} (hχ : χ.IsQuadratic) (f : R' →+* R'') : (χ.ringHomComp f).IsQuadratic := by
  intro a
  rcases hχ a with (ha | ha | ha) <;> simp [ha]

/-- The inverse of a quadratic character is itself. →  -/
theorem IsQuadratic.inv {χ : MulChar R R'} (hχ : χ.IsQuadratic) : χ⁻¹ = χ := by
  ext x
  rw [inv_apply_eq_inv]
  rcases hχ x with (h₀ | h₁ | h₂)
  · rw [h₀, Ring.inverse_zero]
    
  · rw [h₁, Ring.inverse_one]
    
  · rw [h₂,
      (by
        norm_cast : (-1 : R') = (-1 : R'ˣ)),
      Ring.inverse_unit (-1 : R'ˣ)]
    rfl
    

/-- The square of a quadratic character is the trivial character. -/
theorem IsQuadratic.sq_eq_one {χ : MulChar R R'} (hχ : χ.IsQuadratic) : χ ^ 2 = 1 := by
  convert mul_left_invₓ _
  rw [pow_two, hχ.inv]

/-- The `p`th power of a quadratic character is itself, when `p` is the (prime) characteristic
of the target ring. -/
theorem IsQuadratic.pow_char {χ : MulChar R R'} (hχ : χ.IsQuadratic) (p : ℕ) [hp : Fact p.Prime] [CharP R' p] :
    χ ^ p = χ := by
  ext x
  rw [pow_apply_coe]
  rcases hχ x with (hx | hx | hx) <;> rw [hx]
  · rw [zero_pow (Fact.out p.prime).Pos]
    
  · rw [one_pow]
    
  · exact CharP.neg_one_pow_char R' p
    

/-- The `n`th power of a quadratic character is the trivial character, when `n` is even. -/
theorem IsQuadratic.pow_even {χ : MulChar R R'} (hχ : χ.IsQuadratic) {n : ℕ} (hn : Even n) : χ ^ n = 1 := by
  obtain ⟨n, rfl⟩ := even_iff_two_dvd.mp hn
  rw [pow_mulₓ, hχ.sq_eq_one, one_pow]

/-- The `n`th power of a quadratic character is itself, when `n` is odd. -/
theorem IsQuadratic.pow_odd {χ : MulChar R R'} (hχ : χ.IsQuadratic) {n : ℕ} (hn : Odd n) : χ ^ n = χ := by
  obtain ⟨n, rfl⟩ := hn
  rw [pow_addₓ, pow_oneₓ, hχ.pow_even (even_two_mul _), one_mulₓ]

open BigOperators

/-- The sum over all values of a nontrivial multiplicative character on a finite ring is zero
(when the target is a domain). -/
theorem IsNontrivial.sum_eq_zero [Fintype R] [IsDomain R'] {χ : MulChar R R'} (hχ : χ.IsNontrivial) : (∑ a, χ a) = 0 :=
  by
  rcases hχ with ⟨b, hb⟩
  refine' eq_zero_of_mul_eq_self_left hb _
  simp only [Finset.mul_sum, ← map_mul]
  exact Fintype.sum_bijective _ (Units.mul_left_bijective b) _ _ fun x => rfl

/-- The sum over all values of the trivial multiplicative character on a finite ring is
the cardinality of its unit group. -/
theorem sum_one_eq_card_units [Fintype R] [DecidableEq R] : (∑ a, (1 : MulChar R R') a) = Fintype.card Rˣ := by
  calc
    (∑ a, (1 : MulChar R R') a) = ∑ a : R, if IsUnit a then 1 else 0 := Finset.sum_congr rfl fun a _ => _
    _ = ((Finset.univ : Finset R).filter IsUnit).card := Finset.sum_boole
    _ = (finset.univ.map ⟨(coe : Rˣ → R), Units.ext⟩).card := _
    _ = Fintype.card Rˣ := congr_argₓ _ (Finset.card_map _)
    
  · split_ifs with h h
    · exact one_apply_coe h.unit
      
    · exact map_nonunit _ h
      
    
  · congr
    ext a
    simp only [Finset.mem_filter, Finset.mem_univ, true_andₓ, Finset.mem_map, Function.Embedding.coe_fn_mk,
      exists_true_left, IsUnit]
    

end MulChar

end Properties

