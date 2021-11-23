import Mathbin.LinearAlgebra.Quotient 
import Mathbin.CategoryTheory.EpiMono 
import Mathbin.Algebra.Category.Module.Basic

/-!
# Monomorphisms in `Module R`

This file shows that an `R`-linear map is a monomorphism in the category of `R`-modules
if and only if it is injective, and similarly an epimorphism if and only if it is surjective.
-/


universe v u

open CategoryTheory

open ModuleCat

open_locale ModuleCat

namespace ModuleCat

variable{R : Type u}[Ringₓ R]{X Y : ModuleCat.{v} R}(f : X ⟶ Y)

theorem ker_eq_bot_of_mono [mono f] : f.ker = ⊥ :=
  LinearMap.ker_eq_bot_of_cancel$ fun u v => (@cancel_mono _ _ _ _ _ f _ (↟u) (↟v)).1

theorem range_eq_top_of_epi [epi f] : f.range = ⊤ :=
  LinearMap.range_eq_top_of_cancel$ fun u v => (@cancel_epi _ _ _ _ _ f _ (↟u) (↟v)).1

theorem mono_iff_ker_eq_bot : mono f ↔ f.ker = ⊥ :=
  ⟨fun hf =>
      by 
        exact ker_eq_bot_of_mono _,
    fun hf => concrete_category.mono_of_injective _$ LinearMap.ker_eq_bot.1 hf⟩

theorem mono_iff_injective : mono f ↔ Function.Injective f :=
  by 
    rw [mono_iff_ker_eq_bot, LinearMap.ker_eq_bot]

theorem epi_iff_range_eq_top : epi f ↔ f.range = ⊤ :=
  ⟨fun hf =>
      by 
        exact range_eq_top_of_epi _,
    fun hf => concrete_category.epi_of_surjective _$ LinearMap.range_eq_top.1 hf⟩

theorem epi_iff_surjective : epi f ↔ Function.Surjective f :=
  by 
    rw [epi_iff_range_eq_top, LinearMap.range_eq_top]

instance mono_as_hom'_subtype (U : Submodule R X) : mono (↾U.subtype) :=
  (mono_iff_ker_eq_bot _).mpr (Submodule.ker_subtype U)

instance epi_as_hom''_mkq (U : Submodule R X) : epi (↿U.mkq) :=
  (epi_iff_range_eq_top _).mpr$ Submodule.range_mkq _

end ModuleCat

