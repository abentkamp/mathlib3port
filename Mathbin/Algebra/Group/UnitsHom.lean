import Mathbin.Algebra.Group.Hom

/-!
# Lift monoid homomorphisms to group homomorphisms of their units subgroups.
-/


universe u v w

namespace Units

variable {M : Type u} {N : Type v} {P : Type w} [Monoidₓ M] [Monoidₓ N] [Monoidₓ P]

/-- The group homomorphism on units induced by a `monoid_hom`. -/
@[toAdditive "The `add_group` homomorphism on `add_unit`s induced by an `add_monoid_hom`."]
def map (f : M →* N) : Units M →* Units N :=
  MonoidHom.mk'
    (fun u =>
      ⟨f u.val, f u.inv,
        by 
          rw [←f.map_mul, u.val_inv, f.map_one],
        by 
          rw [←f.map_mul, u.inv_val, f.map_one]⟩)
    fun x y => ext (f.map_mul x y)

@[simp, toAdditive]
theorem coe_map (f : M →* N) (x : Units M) : ↑map f x = f x :=
  rfl

@[simp, toAdditive]
theorem coe_map_inv (f : M →* N) (u : Units M) : ↑map f u⁻¹ = f (↑u⁻¹) :=
  rfl

@[simp, toAdditive]
theorem map_comp (f : M →* N) (g : N →* P) : map (g.comp f) = (map g).comp (map f) :=
  rfl

variable (M)

@[simp, toAdditive]
theorem map_id : map (MonoidHom.id M) = MonoidHom.id (Units M) :=
  by 
    ext <;> rfl

/-- Coercion `units M → M` as a monoid homomorphism. -/
@[toAdditive "Coercion `add_units M → M` as an add_monoid homomorphism."]
def coe_hom : Units M →* M :=
  ⟨coeₓ, coe_one, coe_mul⟩

variable {M}

@[simp, toAdditive]
theorem coe_hom_apply (x : Units M) : coe_hom M x = ↑x :=
  rfl

/-- If a map `g : M → units N` agrees with a homomorphism `f : M →* N`, then
this map is a monoid homomorphism too. -/
@[toAdditive
      "If a map `g : M → add_units N` agrees with a homomorphism `f : M →+ N`, then this map\nis an add_monoid homomorphism too."]
def lift_right (f : M →* N) (g : M → Units N) (h : ∀ x, ↑g x = f x) : M →* Units N :=
  { toFun := g, map_one' := Units.ext$ (h 1).symm ▸ f.map_one,
    map_mul' :=
      fun x y =>
        Units.ext$
          by 
            simp only [h, coe_mul, f.map_mul] }

@[simp, toAdditive]
theorem coe_lift_right {f : M →* N} {g : M → Units N} (h : ∀ x, ↑g x = f x) x : (lift_right f g h x : N) = f x :=
  h x

@[simp, toAdditive]
theorem mul_lift_right_inv {f : M →* N} {g : M → Units N} (h : ∀ x, ↑g x = f x) x : (f x*↑lift_right f g h x⁻¹) = 1 :=
  by 
    rw [Units.mul_inv_eq_iff_eq_mul, one_mulₓ, coe_lift_right]

@[simp, toAdditive]
theorem lift_right_inv_mul {f : M →* N} {g : M → Units N} (h : ∀ x, ↑g x = f x) x : ((↑lift_right f g h x⁻¹)*f x) = 1 :=
  by 
    rw [Units.inv_mul_eq_iff_eq_mul, mul_oneₓ, coe_lift_right]

end Units

namespace MonoidHom

/-- If `f` is a homomorphism from a group `G` to a monoid `M`,
then its image lies in the units of `M`,
and `f.to_hom_units` is the corresponding monoid homomorphism from `G` to `units M`. -/
@[toAdditive
      "If `f` is a homomorphism from an additive group `G` to an additive monoid `M`,\nthen its image lies in the `add_units` of `M`,\nand `f.to_hom_units` is the corresponding homomorphism from `G` to `add_units M`."]
def to_hom_units {G M : Type _} [Groupₓ G] [Monoidₓ M] (f : G →* M) : G →* Units M :=
  { toFun :=
      fun g =>
        ⟨f g, f (g⁻¹),
          by 
            rw [←f.map_mul, mul_inv_selfₓ, f.map_one],
          by 
            rw [←f.map_mul, inv_mul_selfₓ, f.map_one]⟩,
    map_one' := Units.ext f.map_one, map_mul' := fun _ _ => Units.ext (f.map_mul _ _) }

@[simp]
theorem coe_to_hom_units {G M : Type _} [Groupₓ G] [Monoidₓ M] (f : G →* M) (g : G) : (f.to_hom_units g : M) = f g :=
  rfl

end MonoidHom

section IsUnit

variable {M : Type _} {N : Type _}

@[toAdditive]
theorem IsUnit.map [Monoidₓ M] [Monoidₓ N] (f : M →* N) {x : M} (h : IsUnit x) : IsUnit (f x) :=
  by 
    rcases h with ⟨y, rfl⟩ <;> exact (Units.map f y).IsUnit

/-- If a homomorphism `f : M →* N` sends each element to an `is_unit`, then it can be lifted
to `f : M →* units N`. See also `units.lift_right` for a computable version. -/
@[toAdditive
      "If a homomorphism `f : M →+ N` sends each element to an `is_add_unit`, then it can be\nlifted to `f : M →+ add_units N`. See also `add_units.lift_right` for a computable version."]
noncomputable def IsUnit.liftRight [Monoidₓ M] [Monoidₓ N] (f : M →* N) (hf : ∀ x, IsUnit (f x)) : M →* Units N :=
  (Units.liftRight f fun x => Classical.some (hf x))$ fun x => Classical.some_spec (hf x)

@[toAdditive]
theorem IsUnit.coe_lift_right [Monoidₓ M] [Monoidₓ N] (f : M →* N) (hf : ∀ x, IsUnit (f x)) x :
  (IsUnit.liftRight f hf x : N) = f x :=
  Units.coe_lift_right _ x

@[simp, toAdditive]
theorem IsUnit.mul_lift_right_inv [Monoidₓ M] [Monoidₓ N] (f : M →* N) (h : ∀ x, IsUnit (f x)) x :
  (f x*↑IsUnit.liftRight f h x⁻¹) = 1 :=
  Units.mul_lift_right_inv (fun y => Classical.some_spec$ h y) x

@[simp, toAdditive]
theorem IsUnit.lift_right_inv_mul [Monoidₓ M] [Monoidₓ N] (f : M →* N) (h : ∀ x, IsUnit (f x)) x :
  ((↑IsUnit.liftRight f h x⁻¹)*f x) = 1 :=
  Units.lift_right_inv_mul (fun y => Classical.some_spec$ h y) x

end IsUnit

