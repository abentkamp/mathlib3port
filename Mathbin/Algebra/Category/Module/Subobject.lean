import Mathbin.Algebra.Category.Module.EpiMono 
import Mathbin.CategoryTheory.Subobject.WellPowered

/-!
# Subobjects in the category of `R`-modules

We construct an explicit order isomorphism between the categorical subobjects of an `R`-module `M`
and its submodules. This immediately implies that the category of `R`-modules is well-powered.

-/


open CategoryTheory

open CategoryTheory.Subobject

open_locale ModuleCat

universe v u

namespace ModuleCat

variable {R : Type u} [Ringₓ R] (M : ModuleCat.{v} R)

/-- The categorical subobjects of a module `M` are in one-to-one correspondence with its
    submodules.-/
noncomputable def subobject_Module : subobject M ≃o Submodule R M :=
  OrderIso.symm
    { invFun := fun S => S.arrow.range, toFun := fun N => subobject.mk (↾N.subtype),
      right_inv :=
        fun S =>
          Eq.symm
            (by 
              fapply eq_mk_of_comm
              ·
                apply LinearEquiv.toModuleIso'Left 
                apply LinearEquiv.ofBijective (LinearMap.codRestrict S.arrow.range S.arrow _)
                ·
                  simpa only [←LinearMap.ker_eq_bot, LinearMap.ker_cod_restrict] using ker_eq_bot_of_mono _
                ·
                  rw [←LinearMap.range_eq_top, LinearMap.range_cod_restrict, Submodule.comap_subtype_self]
                ·
                  exact LinearMap.mem_range_self _
              ·
                apply LinearMap.ext 
                intro x 
                rfl),
      left_inv :=
        fun N =>
          by 
            convert congr_argₓ LinearMap.range (underlying_iso_arrow (↾N.subtype)) using 1
            ·
              have  : (underlying_iso (↾N.subtype)).inv = (underlying_iso (↾N.subtype)).symm.toLinearEquiv
              ·
                apply LinearMap.ext 
                intro x 
                rfl 
              rw [this, comp_def, LinearEquiv.range_comp]
            ·
              exact (Submodule.range_subtype _).symm,
      map_rel_iff' :=
        fun S T =>
          by 
            refine'
              ⟨fun h => _,
                fun h =>
                  mk_le_mk_of_comm (↟(Submodule.ofLe h))
                    (by 
                      ext 
                      rfl)⟩
            convert LinearMap.range_comp_le_range (of_mk_le_mk _ _ h) (↾T.subtype)
            ·
              simpa only [←comp_def, of_mk_le_mk_comp] using (Submodule.range_subtype _).symm
            ·
              exact (Submodule.range_subtype _).symm }

instance well_powered_Module : well_powered (ModuleCat.{v} R) :=
  ⟨fun M => ⟨⟨_, ⟨(subobject_Module M).toEquiv⟩⟩⟩⟩

end ModuleCat

