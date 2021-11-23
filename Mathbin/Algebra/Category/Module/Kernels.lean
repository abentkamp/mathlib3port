import Mathbin.Algebra.Category.Module.EpiMono

/-!
# The concrete (co)kernels in the category of modules are (co)kernels in the categorical sense.
-/


open CategoryTheory

open CategoryTheory.Limits

open CategoryTheory.Limits.WalkingParallelPair

universe u v

namespace ModuleCat

variable{R : Type u}[Ringₓ R]

section 

variable{M N : ModuleCat.{v} R}(f : M ⟶ N)

/-- The kernel cone induced by the concrete kernel. -/
def kernel_cone : kernel_fork f :=
  kernel_fork.of_ι (as_hom f.ker.subtype)$
    by 
      tidy

/-- The kernel of a linear map is a kernel in the categorical sense. -/
def kernel_is_limit : is_limit (kernel_cone f) :=
  fork.is_limit.mk _
    (fun s =>
      LinearMap.codRestrict f.ker (fork.ι s)
        fun c =>
          LinearMap.mem_ker.2$
            by 
              rw [←@Function.comp_apply _ _ _ f (fork.ι s) c, ←coe_comp, fork.condition,
                has_zero_morphisms.comp_zero (fork.ι s) N]
              rfl)
    (fun s => LinearMap.subtype_comp_cod_restrict _ _ _)
    fun s m h =>
      LinearMap.ext$
        fun x =>
          Subtype.ext_iff_val.2$
            have h₁ : (m ≫ (kernel_cone f).π.app zero).toFun = (s.π.app zero).toFun :=
              by 
                congr 
                exact h zero 
            by 
              convert @congr_funₓ _ _ _ _ h₁ x

/-- The cokernel cocone induced by the projection onto the quotient. -/
def cokernel_cocone : cokernel_cofork f :=
  cokernel_cofork.of_π (as_hom f.range.mkq)$ LinearMap.range_mkq_comp _

-- error in Algebra.Category.Module.Kernels: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
/-- The projection onto the quotient is a cokernel in the categorical sense. -/
def cokernel_is_colimit : is_colimit (cokernel_cocone f) :=
cofork.is_colimit.mk _ (λ
 s, «expr $ »(f.range.liftq (cofork.π s), «expr $ »(linear_map.range_le_ker_iff.2, cokernel_cofork.condition s))) (λ
 s, f.range.liftq_mkq (cofork.π s) _) (λ s m h, begin
   haveI [] [":", expr epi (as_hom f.range.mkq)] [":=", expr (epi_iff_range_eq_top _).mpr (submodule.range_mkq _)],
   apply [expr (cancel_epi (as_hom f.range.mkq)).1],
   convert [] [expr h walking_parallel_pair.one] [],
   exact [expr submodule.liftq_mkq _ _ _]
 end)

end 

/-- The category of R-modules has kernels, given by the inclusion of the kernel submodule. -/
theorem has_kernels_Module : has_kernels (ModuleCat R) :=
  ⟨fun X Y f => has_limit.mk ⟨_, kernel_is_limit f⟩⟩

/-- The category or R-modules has cokernels, given by the projection onto the quotient. -/
theorem has_cokernels_Module : has_cokernels (ModuleCat R) :=
  ⟨fun X Y f => has_colimit.mk ⟨_, cokernel_is_colimit f⟩⟩

open_locale ModuleCat

attribute [local instance] has_kernels_Module

attribute [local instance] has_cokernels_Module

variable{G H : ModuleCat.{v} R}(f : G ⟶ H)

/--
The categorical kernel of a morphism in `Module`
agrees with the usual module-theoretical kernel.
-/
noncomputable def kernel_iso_ker {G H : ModuleCat.{v} R} (f : G ⟶ H) : kernel f ≅ ModuleCat.of R f.ker :=
  limit.iso_limit_cone ⟨_, kernel_is_limit f⟩

@[simp, elementwise]
theorem kernel_iso_ker_inv_kernel_ι : (kernel_iso_ker f).inv ≫ kernel.ι f = f.ker.subtype :=
  limit.iso_limit_cone_inv_π _ _

@[simp, elementwise]
theorem kernel_iso_ker_hom_ker_subtype : (kernel_iso_ker f).hom ≫ f.ker.subtype = kernel.ι f :=
  is_limit.cone_point_unique_up_to_iso_inv_comp _ (limit.is_limit _) zero

/--
The categorical cokernel of a morphism in `Module`
agrees with the usual module-theoretical quotient.
-/
noncomputable def cokernel_iso_range_quotient {G H : ModuleCat.{v} R} (f : G ⟶ H) :
  cokernel f ≅ ModuleCat.of R f.range.quotient :=
  colimit.iso_colimit_cocone ⟨_, cokernel_is_colimit f⟩

@[simp, elementwise]
theorem cokernel_π_cokernel_iso_range_quotient_hom : cokernel.π f ≫ (cokernel_iso_range_quotient f).hom = f.range.mkq :=
  by 
    convert colimit.iso_colimit_cocone_ι_hom _ _ <;> rfl

@[simp, elementwise]
theorem range_mkq_cokernel_iso_range_quotient_inv : ↿f.range.mkq ≫ (cokernel_iso_range_quotient f).inv = cokernel.π f :=
  by 
    convert colimit.iso_colimit_cocone_ι_inv ⟨_, cokernel_is_colimit f⟩ _ <;> rfl

end ModuleCat

