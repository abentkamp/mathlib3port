import Mathbin.CategoryTheory.ConcreteCategory.BundledHom

/-!
# Category instances for structures that use unbundled homs

This file provides basic infrastructure to define concrete
categories using unbundled homs (see `class unbundled_hom`), and
define forgetful functors between them (see
`unbundled_hom.mk_has_forget₂`).
-/


universe v u

namespace CategoryTheory

/-- A class for unbundled homs used to define a category. `hom` must
take two types `α`, `β` and instances of the corresponding structures,
and return a predicate on `α → β`. -/
class unbundled_hom {c : Type u → Type u} (hom : ∀ {α β}, c α → c β → (α → β) → Prop) where
  hom_id {} : ∀ {α} ia : c α, hom ia ia id
  hom_comp {} :
    ∀ {α β γ} {Iα : c α} {Iβ : c β} {Iγ : c γ} {g : β → γ} {f : α → β} hg : hom Iβ Iγ g hf : hom Iα Iβ f,
      hom Iα Iγ (g ∘ f)

namespace UnbundledHom

variable (c : Type u → Type u) (hom : ∀ ⦃α β⦄, c α → c β → (α → β) → Prop) [𝒞 : unbundled_hom hom]

include 𝒞

instance bundled_hom : bundled_hom fun α β Iα : c α Iβ : c β => Subtype (hom Iα Iβ) where
  toFun := fun _ _ _ _ => Subtype.val
  id := fun α Iα => ⟨id, hom_id hom Iα⟩
  id_to_fun := by
    intros <;> rfl
  comp := fun _ _ _ _ _ _ g f => ⟨g.1 ∘ f.1, hom_comp c g.2 f.2⟩
  comp_to_fun := by
    intros <;> rfl
  hom_ext := by
    intros <;> apply Subtype.eq

section HasForget₂

variable {c hom} {c' : Type u → Type u} {hom' : ∀ ⦃α β⦄, c' α → c' β → (α → β) → Prop} [𝒞' : unbundled_hom hom']

include 𝒞'

variable (obj : ∀ ⦃α⦄, c α → c' α) (map : ∀ ⦃α β Iα Iβ f⦄, @hom α β Iα Iβ f → hom' (obj Iα) (obj Iβ) f)

/-- A custom constructor for forgetful functor
between concrete categories defined using `unbundled_hom`. -/
def mk_has_forget₂ : has_forget₂ (bundled c) (bundled c') :=
  bundled_hom.mk_has_forget₂ obj (fun X Y f => ⟨f.val, map f.property⟩) fun _ _ _ => rfl

end HasForget₂

end UnbundledHom

end CategoryTheory

