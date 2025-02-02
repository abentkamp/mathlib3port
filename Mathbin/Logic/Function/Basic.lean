/-
Copyright (c) 2016 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro
-/
import Mathbin.Data.Option.Defs
import Mathbin.Logic.Nonempty
import Mathbin.Tactic.Cache

/-!
# Miscellaneous function constructions and lemmas
-/


universe u v w

namespace Function

section

variable {α β γ : Sort _} {f : α → β}

/-- Evaluate a function at an argument. Useful if you want to talk about the partially applied
  `function.eval x : (Π x, β x) → β x`. -/
@[reducible]
def eval {β : α → Sort _} (x : α) (f : ∀ x, β x) : β x :=
  f x

@[simp]
theorem eval_apply {β : α → Sort _} (x : α) (f : ∀ x, β x) : eval x f = f x :=
  rfl

theorem comp_applyₓ {α : Sort u} {β : Sort v} {φ : Sort w} (f : β → φ) (g : α → β) (a : α) : (f ∘ g) a = f (g a) :=
  rfl

theorem const_defₓ {y : β} : (fun x : α => y) = const α y :=
  rfl

@[simp]
theorem const_applyₓ {y : β} {x : α} : const α y x = y :=
  rfl

@[simp]
theorem const_compₓ {f : α → β} {c : γ} : const β c ∘ f = const α c :=
  rfl

@[simp]
theorem comp_constₓ {f : β → γ} {b : β} : f ∘ const α b = const α (f b) :=
  rfl

theorem const_injective [Nonempty α] : Injective (const α : β → α → β) := fun y₁ y₂ h =>
  let ⟨x⟩ := ‹Nonempty α›
  congr_funₓ h x

@[simp]
theorem const_inj [Nonempty α] {y₁ y₂ : β} : const α y₁ = const α y₂ ↔ y₁ = y₂ :=
  ⟨fun h => const_injective h, fun h => h ▸ rfl⟩

theorem id_def : @id α = fun x => x :=
  rfl

theorem hfunext {α α' : Sort u} {β : α → Sort v} {β' : α' → Sort v} {f : ∀ a, β a} {f' : ∀ a, β' a} (hα : α = α')
    (h : ∀ a a', HEq a a' → HEq (f a) (f' a')) : HEq f f' := by
  subst hα
  have : ∀ a, HEq (f a) (f' a) := by
    intro a
    exact h a a (HEq.refl a)
  have : β = β' := by
    funext a
    exact type_eq_of_heq (this a)
  subst this
  apply heq_of_eq
  funext a
  exact eq_of_heq (this a)

theorem funext_iff {β : α → Sort _} {f₁ f₂ : ∀ x : α, β x} : f₁ = f₂ ↔ ∀ a, f₁ a = f₂ a :=
  Iff.intro (fun h a => h ▸ rfl) funext

theorem ne_iff {β : α → Sort _} {f₁ f₂ : ∀ a, β a} : f₁ ≠ f₂ ↔ ∃ a, f₁ a ≠ f₂ a :=
  funext_iff.Not.trans not_forall

protected theorem Bijective.injective {f : α → β} (hf : Bijective f) : Injective f :=
  hf.1

protected theorem Bijective.surjective {f : α → β} (hf : Bijective f) : Surjective f :=
  hf.2

theorem Injective.eq_iff (I : Injective f) {a b : α} : f a = f b ↔ a = b :=
  ⟨@I _ _, congr_argₓ f⟩

theorem Injective.eq_iff' (I : Injective f) {a b : α} {c : β} (h : f b = c) : f a = c ↔ a = b :=
  h ▸ I.eq_iff

theorem Injective.ne (hf : Injective f) {a₁ a₂ : α} : a₁ ≠ a₂ → f a₁ ≠ f a₂ :=
  mt fun h => hf h

theorem Injective.ne_iff (hf : Injective f) {x y : α} : f x ≠ f y ↔ x ≠ y :=
  ⟨mt <| congr_argₓ f, hf.Ne⟩

theorem Injective.ne_iff' (hf : Injective f) {x y : α} {z : β} (h : f y = z) : f x ≠ z ↔ x ≠ y :=
  h ▸ hf.ne_iff

/-- If the co-domain `β` of an injective function `f : α → β` has decidable equality, then
the domain `α` also has decidable equality. -/
protected def Injective.decidableEq [DecidableEq β] (I : Injective f) : DecidableEq α := fun a b =>
  decidableOfIff _ I.eq_iff

theorem Injective.of_comp {g : γ → α} (I : Injective (f ∘ g)) : Injective g := fun x y h =>
  I <| show f (g x) = f (g y) from congr_argₓ f h

theorem Injective.of_comp_iff {f : α → β} (hf : Injective f) (g : γ → α) : Injective (f ∘ g) ↔ Injective g :=
  ⟨Injective.of_comp, hf.comp⟩

theorem Injective.of_comp_iff' (f : α → β) {g : γ → α} (hg : Bijective g) : Injective (f ∘ g) ↔ Injective f :=
  ⟨fun h x y =>
    let ⟨x', hx⟩ := hg.Surjective x
    let ⟨y', hy⟩ := hg.Surjective y
    hx ▸ hy ▸ fun hf => h hf ▸ rfl,
    fun h => h.comp hg.Injective⟩

/-- Composition by an injective function on the left is itself injective. -/
theorem Injective.comp_left {g : β → γ} (hg : Function.Injective g) :
    Function.Injective ((· ∘ ·) g : (α → β) → α → γ) := fun f₁ f₂ hgf => funext fun i => hg <| (congr_funₓ hgf i : _)

theorem injective_of_subsingletonₓ [Subsingleton α] (f : α → β) : Injective f := fun a b ab => Subsingleton.elim _ _

theorem Injective.dite (p : α → Prop) [DecidablePred p] {f : { a : α // p a } → β} {f' : { a : α // ¬p a } → β}
    (hf : Injective f) (hf' : Injective f')
    (im_disj : ∀ {x x' : α} {hx : p x} {hx' : ¬p x'}, f ⟨x, hx⟩ ≠ f' ⟨x', hx'⟩) :
    Function.Injective fun x => if h : p x then f ⟨x, h⟩ else f' ⟨x, h⟩ := fun x₁ x₂ h => by
  dsimp' only  at h
  by_cases' h₁ : p x₁ <;> by_cases' h₂ : p x₂
  · rw [dif_pos h₁, dif_pos h₂] at h
    injection hf h
    
  · rw [dif_pos h₁, dif_neg h₂] at h
    exact (im_disj h).elim
    
  · rw [dif_neg h₁, dif_pos h₂] at h
    exact (im_disj h.symm).elim
    
  · rw [dif_neg h₁, dif_neg h₂] at h
    injection hf' h
    

theorem Surjective.of_comp {g : γ → α} (S : Surjective (f ∘ g)) : Surjective f := fun y =>
  let ⟨x, h⟩ := S y
  ⟨g x, h⟩

theorem Surjective.of_comp_iff (f : α → β) {g : γ → α} (hg : Surjective g) : Surjective (f ∘ g) ↔ Surjective f :=
  ⟨Surjective.of_comp, fun h => h.comp hg⟩

theorem Surjective.of_comp_iff' (hf : Bijective f) (g : γ → α) : Surjective (f ∘ g) ↔ Surjective g :=
  ⟨fun h x =>
    let ⟨x', hx'⟩ := h (f x)
    ⟨x', hf.Injective hx'⟩,
    hf.Surjective.comp⟩

instance decidableEqPfun (p : Prop) [Decidable p] (α : p → Type _) [∀ hp, DecidableEq (α hp)] : DecidableEq (∀ hp, α hp)
  | f, g => decidableOfIff (∀ hp, f hp = g hp) funext_iff.symm

protected theorem Surjective.forall (hf : Surjective f) {p : β → Prop} : (∀ y, p y) ↔ ∀ x, p (f x) :=
  ⟨fun h x => h (f x), fun h y =>
    let ⟨x, hx⟩ := hf y
    hx ▸ h x⟩

protected theorem Surjective.forall₂ (hf : Surjective f) {p : β → β → Prop} :
    (∀ y₁ y₂, p y₁ y₂) ↔ ∀ x₁ x₂, p (f x₁) (f x₂) :=
  hf.forall.trans <| forall_congrₓ fun x => hf.forall

protected theorem Surjective.forall₃ (hf : Surjective f) {p : β → β → β → Prop} :
    (∀ y₁ y₂ y₃, p y₁ y₂ y₃) ↔ ∀ x₁ x₂ x₃, p (f x₁) (f x₂) (f x₃) :=
  hf.forall.trans <| forall_congrₓ fun x => hf.forall₂

protected theorem Surjective.exists (hf : Surjective f) {p : β → Prop} : (∃ y, p y) ↔ ∃ x, p (f x) :=
  ⟨fun ⟨y, hy⟩ =>
    let ⟨x, hx⟩ := hf y
    ⟨x, hx.symm ▸ hy⟩,
    fun ⟨x, hx⟩ => ⟨f x, hx⟩⟩

protected theorem Surjective.exists₂ (hf : Surjective f) {p : β → β → Prop} :
    (∃ y₁ y₂, p y₁ y₂) ↔ ∃ x₁ x₂, p (f x₁) (f x₂) :=
  hf.exists.trans <| exists_congr fun x => hf.exists

protected theorem Surjective.exists₃ (hf : Surjective f) {p : β → β → β → Prop} :
    (∃ y₁ y₂ y₃, p y₁ y₂ y₃) ↔ ∃ x₁ x₂ x₃, p (f x₁) (f x₂) (f x₃) :=
  hf.exists.trans <| exists_congr fun x => hf.exists₂

theorem Surjective.injective_comp_right (hf : Surjective f) : Injective fun g : β → γ => g ∘ f := fun g₁ g₂ h =>
  funext <| hf.forall.2 <| congr_funₓ h

protected theorem Surjective.right_cancellable (hf : Surjective f) {g₁ g₂ : β → γ} : g₁ ∘ f = g₂ ∘ f ↔ g₁ = g₂ :=
  hf.injective_comp_right.eq_iff

theorem surjective_of_right_cancellable_Prop (h : ∀ g₁ g₂ : β → Prop, g₁ ∘ f = g₂ ∘ f → g₁ = g₂) : Surjective f := by
  specialize h (fun _ => True) (fun y => ∃ x, f x = y) (funext fun x => _)
  · simp only [(· ∘ ·), exists_apply_eq_applyₓ]
    
  · intro y
    have : True = ∃ x, f x = y := congr_funₓ h y
    rw [← this]
    exact trivialₓ
    

theorem bijective_iff_exists_uniqueₓ (f : α → β) : Bijective f ↔ ∀ b : β, ∃! a : α, f a = b :=
  ⟨fun hf b =>
    let ⟨a, ha⟩ := hf.Surjective b
    ⟨a, ha, fun a' ha' => hf.Injective (ha'.trans ha.symm)⟩,
    fun he => ⟨fun a a' h => unique_of_exists_unique (he (f a')) h rfl, fun b => exists_of_exists_unique (he b)⟩⟩

/-- Shorthand for using projection notation with `function.bijective_iff_exists_unique`. -/
protected theorem Bijective.exists_unique {f : α → β} (hf : Bijective f) (b : β) : ∃! a : α, f a = b :=
  (bijective_iff_exists_uniqueₓ f).mp hf b

theorem Bijective.exists_unique_iff {f : α → β} (hf : Bijective f) {p : β → Prop} : (∃! y, p y) ↔ ∃! x, p (f x) :=
  ⟨fun ⟨y, hpy, hy⟩ =>
    let ⟨x, hx⟩ := hf.Surjective y
    ⟨x, by
      rwa [hx], fun z (hz : p (f z)) => hf.Injective <| hx.symm ▸ hy _ hz⟩,
    fun ⟨x, hpx, hx⟩ =>
    ⟨f x, hpx, fun y hy =>
      let ⟨z, hz⟩ := hf.Surjective y
      hz ▸ congr_argₓ f <|
        hx _ <| by
          rwa [hz]⟩⟩

theorem Bijective.of_comp_iff (f : α → β) {g : γ → α} (hg : Bijective g) : Bijective (f ∘ g) ↔ Bijective f :=
  and_congr (Injective.of_comp_iff' _ hg) (Surjective.of_comp_iff _ hg.Surjective)

theorem Bijective.of_comp_iff' {f : α → β} (hf : Bijective f) (g : γ → α) :
    Function.Bijective (f ∘ g) ↔ Function.Bijective g :=
  and_congr (Injective.of_comp_iff hf.Injective _) (Surjective.of_comp_iff' hf _)

/-- **Cantor's diagonal argument** implies that there are no surjective functions from `α`
to `set α`. -/
theorem cantor_surjective {α} (f : α → Set α) : ¬Function.Surjective f
  | h =>
    let ⟨D, e⟩ := h { a | ¬a ∈ f a }
    (iff_not_selfₓ (D ∈ f D)).1 <| iff_of_eq (congr_argₓ ((· ∈ ·) D) e)

/-- **Cantor's diagonal argument** implies that there are no injective functions from `set α`
to `α`. -/
theorem cantor_injective {α : Type _} (f : Set α → α) : ¬Function.Injective f
  | i =>
    (cantor_surjective fun a => { b | ∀ U, a = f U → b ∈ U }) <|
      RightInverse.surjective fun U => funext fun a => propext ⟨fun h => h U rfl, fun h' U' e => i e ▸ h'⟩

/-- There is no surjection from `α : Type u` into `Type u`. This theorem
  demonstrates why `Type : Type` would be inconsistent in Lean. -/
theorem not_surjective_Type {α : Type u} (f : α → Type max u v) : ¬Surjective f := by
  intro hf
  let T : Type max u v := Sigma f
  cases' hf (Set T) with U hU
  let g : Set T → T := fun s => ⟨U, cast hU.symm s⟩
  have hg : injective g := by
    intro s t h
    suffices cast hU (g s).2 = cast hU (g t).2 by
      simp only [cast_cast, cast_eq] at this
      assumption
    · congr
      assumption
      
  exact cantor_injective g hg

/-- `g` is a partial inverse to `f` (an injective but not necessarily
  surjective function) if `g y = some x` implies `f x = y`, and `g y = none`
  implies that `y` is not in the range of `f`. -/
def IsPartialInv {α β} (f : α → β) (g : β → Option α) : Prop :=
  ∀ x y, g y = some x ↔ f x = y

theorem is_partial_inv_leftₓ {α β} {f : α → β} {g} (H : IsPartialInv f g) (x) : g (f x) = some x :=
  (H _ _).2 rfl

theorem injective_of_partial_invₓ {α β} {f : α → β} {g} (H : IsPartialInv f g) : Injective f := fun a b h =>
  Option.some.injₓ <| ((H _ _).2 h).symm.trans ((H _ _).2 rfl)

theorem injective_of_partial_inv_rightₓ {α β} {f : α → β} {g} (H : IsPartialInv f g) (x y b) (h₁ : b ∈ g x)
    (h₂ : b ∈ g y) : x = y :=
  ((H _ _).1 h₁).symm.trans ((H _ _).1 h₂)

theorem LeftInverse.comp_eq_id {f : α → β} {g : β → α} (h : LeftInverse f g) : f ∘ g = id :=
  funext h

theorem left_inverse_iff_comp {f : α → β} {g : β → α} : LeftInverse f g ↔ f ∘ g = id :=
  ⟨LeftInverse.comp_eq_id, congr_funₓ⟩

theorem RightInverse.comp_eq_id {f : α → β} {g : β → α} (h : RightInverse f g) : g ∘ f = id :=
  funext h

theorem right_inverse_iff_comp {f : α → β} {g : β → α} : RightInverse f g ↔ g ∘ f = id :=
  ⟨RightInverse.comp_eq_id, congr_funₓ⟩

theorem LeftInverse.compₓ {f : α → β} {g : β → α} {h : β → γ} {i : γ → β} (hf : LeftInverse f g)
    (hh : LeftInverse h i) : LeftInverse (h ∘ f) (g ∘ i) := fun a =>
  show h (f (g (i a))) = a by
    rw [hf (i a), hh a]

theorem RightInverse.compₓ {f : α → β} {g : β → α} {h : β → γ} {i : γ → β} (hf : RightInverse f g)
    (hh : RightInverse h i) : RightInverse (h ∘ f) (g ∘ i) :=
  LeftInverse.compₓ hh hf

theorem LeftInverse.right_inverse {f : α → β} {g : β → α} (h : LeftInverse g f) : RightInverse f g :=
  h

theorem RightInverse.left_inverse {f : α → β} {g : β → α} (h : RightInverse g f) : LeftInverse f g :=
  h

theorem LeftInverse.surjective {f : α → β} {g : β → α} (h : LeftInverse f g) : Surjective f :=
  h.RightInverse.Surjective

theorem RightInverse.injective {f : α → β} {g : β → α} (h : RightInverse f g) : Injective f :=
  h.LeftInverse.Injective

theorem LeftInverse.right_inverse_of_injective {f : α → β} {g : β → α} (h : LeftInverse f g) (hf : Injective f) :
    RightInverse f g := fun x => hf <| h (f x)

theorem LeftInverse.right_inverse_of_surjective {f : α → β} {g : β → α} (h : LeftInverse f g) (hg : Surjective g) :
    RightInverse f g := fun x =>
  let ⟨y, hy⟩ := hg x
  hy ▸ congr_argₓ g (h y)

theorem RightInverse.left_inverse_of_surjective {f : α → β} {g : β → α} :
    RightInverse f g → Surjective f → LeftInverse f g :=
  left_inverse.right_inverse_of_surjective

theorem RightInverse.left_inverse_of_injective {f : α → β} {g : β → α} :
    RightInverse f g → Injective g → LeftInverse f g :=
  left_inverse.right_inverse_of_injective

theorem LeftInverse.eq_right_inverse {f : α → β} {g₁ g₂ : β → α} (h₁ : LeftInverse g₁ f) (h₂ : RightInverse g₂ f) :
    g₁ = g₂ :=
  calc
    g₁ = g₁ ∘ f ∘ g₂ := by
      rw [h₂.comp_eq_id, comp.right_id]
    _ = g₂ := by
      rw [← comp.assoc, h₁.comp_eq_id, comp.left_id]
    

attribute [local instance] Classical.propDecidable

/-- We can use choice to construct explicitly a partial inverse for
  a given injective function `f`. -/
noncomputable def partialInv {α β} (f : α → β) (b : β) : Option α :=
  if h : ∃ a, f a = b then some (Classical.choose h) else none

theorem partial_inv_of_injectiveₓ {α β} {f : α → β} (I : Injective f) : IsPartialInv f (partialInv f)
  | a, b =>
    ⟨fun h =>
      if h' : ∃ a, f a = b then by
        rw [partial_inv, dif_pos h'] at h
        injection h with h
        subst h
        apply Classical.choose_spec h'
      else by
        rw [partial_inv, dif_neg h'] at h <;> contradiction,
      fun e =>
      e ▸
        have h : ∃ a', f a' = f a := ⟨_, rfl⟩
        (dif_pos h).trans (congr_argₓ _ (I <| Classical.choose_spec h))⟩

theorem partial_inv_leftₓ {α β} {f : α → β} (I : Injective f) : ∀ x, partialInv f (f x) = some x :=
  is_partial_inv_leftₓ (partial_inv_of_injectiveₓ I)

end

section InvFun

variable {α β : Sort _} [Nonempty α] {f : α → β} {a : α} {b : β}

attribute [local instance] Classical.propDecidable

/-- The inverse of a function (which is a left inverse if `f` is injective
  and a right inverse if `f` is surjective). -/
noncomputable def invFun (f : α → β) : β → α := fun y => if h : ∃ x, f x = y then h.some else Classical.arbitrary α

theorem inv_fun_eqₓ (h : ∃ a, f a = b) : f (invFun f b) = b := by
  simp only [inv_fun, dif_pos h, h.some_spec]

theorem inv_fun_negₓ (h : ¬∃ a, f a = b) : invFun f b = Classical.choice ‹_› :=
  dif_neg h

theorem inv_fun_eq_of_injective_of_right_inverse {g : β → α} (hf : Injective f) (hg : RightInverse g f) :
    invFun f = g :=
  funext fun b =>
    hf
      (by
        rw [hg b]
        exact inv_fun_eq ⟨g b, hg b⟩)

theorem right_inverse_inv_fun (hf : Surjective f) : RightInverse (invFun f) f := fun b => inv_fun_eq <| hf b

theorem left_inverse_inv_fun (hf : Injective f) : LeftInverse (invFun f) f := fun b => hf <| inv_fun_eqₓ ⟨b, rfl⟩

theorem inv_fun_surjectiveₓ (hf : Injective f) : Surjective (invFun f) :=
  (left_inverse_inv_fun hf).Surjective

theorem inv_fun_compₓ (hf : Injective f) : invFun f ∘ f = id :=
  funext <| left_inverse_inv_fun hf

theorem Injective.has_left_inverse (hf : Injective f) : HasLeftInverse f :=
  ⟨invFun f, left_inverse_inv_fun hf⟩

theorem injective_iff_has_left_inverse : Injective f ↔ HasLeftInverse f :=
  ⟨Injective.has_left_inverse, HasLeftInverse.injective⟩

end InvFun

section SurjInv

variable {α : Sort u} {β : Sort v} {γ : Sort w} {f : α → β}

/-- The inverse of a surjective function. (Unlike `inv_fun`, this does not require
  `α` to be inhabited.) -/
noncomputable def surjInv {f : α → β} (h : Surjective f) (b : β) : α :=
  Classical.choose (h b)

theorem surj_inv_eq (h : Surjective f) (b) : f (surjInv h b) = b :=
  Classical.choose_spec (h b)

theorem right_inverse_surj_inv (hf : Surjective f) : RightInverse (surjInv hf) f :=
  surj_inv_eq hf

theorem left_inverse_surj_inv (hf : Bijective f) : LeftInverse (surjInv hf.2) f :=
  right_inverse_of_injective_of_left_inverse hf.1 (right_inverse_surj_inv hf.2)

theorem Surjective.has_right_inverse (hf : Surjective f) : HasRightInverse f :=
  ⟨_, right_inverse_surj_inv hf⟩

theorem surjective_iff_has_right_inverse : Surjective f ↔ HasRightInverse f :=
  ⟨Surjective.has_right_inverse, HasRightInverse.surjective⟩

theorem bijective_iff_has_inverse : Bijective f ↔ ∃ g, LeftInverse g f ∧ RightInverse g f :=
  ⟨fun hf => ⟨_, left_inverse_surj_inv hf, right_inverse_surj_inv hf.2⟩, fun ⟨g, gl, gr⟩ =>
    ⟨gl.Injective, gr.Surjective⟩⟩

theorem injective_surj_inv (h : Surjective f) : Injective (surjInv h) :=
  (right_inverse_surj_inv h).Injective

theorem surjective_to_subsingleton [na : Nonempty α] [Subsingleton β] (f : α → β) : Surjective f := fun y =>
  let ⟨a⟩ := na
  ⟨a, Subsingleton.elim _ _⟩

/-- Composition by an surjective function on the left is itself surjective. -/
theorem Surjective.comp_left {g : β → γ} (hg : Surjective g) : Surjective ((· ∘ ·) g : (α → β) → α → γ) := fun f =>
  ⟨surjInv hg ∘ f, funext fun x => right_inverse_surj_inv _ _⟩

/-- Composition by an bijective function on the left is itself bijective. -/
theorem Bijective.comp_left {g : β → γ} (hg : Bijective g) : Bijective ((· ∘ ·) g : (α → β) → α → γ) :=
  ⟨hg.Injective.compLeft, hg.Surjective.compLeft⟩

end SurjInv

section Update

variable {α : Sort u} {β : α → Sort v} {α' : Sort w} [DecidableEq α] [DecidableEq α']

/-- Replacing the value of a function at a given point by a given value. -/
def update (f : ∀ a, β a) (a' : α) (v : β a') (a : α) : β a :=
  if h : a = a' then Eq.ndrec v h.symm else f a

/-- On non-dependent functions, `function.update` can be expressed as an `ite` -/
theorem update_applyₓ {β : Sort _} (f : α → β) (a' : α) (b : β) (a : α) : update f a' b a = if a = a' then b else f a :=
  by
  dunfold update
  congr
  funext
  rw [eq_rec_constantₓ]

@[simp]
theorem update_same (a : α) (v : β a) (f : ∀ a, β a) : update f a v a = v :=
  dif_pos rfl

theorem surjective_eval {α : Sort u} {β : α → Sort v} [h : ∀ a, Nonempty (β a)] (a : α) :
    Surjective (eval a : (∀ a, β a) → β a) := fun b =>
  ⟨@update _ _ (Classical.decEq α) (fun a => (h a).some) a b, @update_same _ _ (Classical.decEq α) _ _ _⟩

theorem update_injective (f : ∀ a, β a) (a' : α) : Injective (update f a') := fun v v' h => by
  have := congr_funₓ h a'
  rwa [update_same, update_same] at this

@[simp]
theorem update_noteq {a a' : α} (h : a ≠ a') (v : β a') (f : ∀ a, β a) : update f a' v a = f a :=
  dif_neg h

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (x «expr ≠ » a)
theorem forall_update_iff (f : ∀ a, β a) {a : α} {b : β a} (p : ∀ a, β a → Prop) :
    (∀ x, p x (update f a b x)) ↔ p a b ∧ ∀ (x) (_ : x ≠ a), p x (f x) := by
  rw [← and_forall_ne a, update_same]
  simp (config := { contextual := true })

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (x «expr ≠ » a)
theorem exists_update_iff (f : ∀ a, β a) {a : α} {b : β a} (p : ∀ a, β a → Prop) :
    (∃ x, p x (update f a b x)) ↔ p a b ∨ ∃ (x : _)(_ : x ≠ a), p x (f x) := by
  rw [← not_forall_not, forall_update_iff f fun a b => ¬p a b]
  simp [not_and_distrib]

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (x «expr ≠ » a)
theorem update_eq_iff {a : α} {b : β a} {f g : ∀ a, β a} : update f a b = g ↔ b = g a ∧ ∀ (x) (_ : x ≠ a), f x = g x :=
  funext_iff.trans <| forall_update_iff _ fun x y => y = g x

-- ./././Mathport/Syntax/Translate/Basic.lean:556:2: warning: expanding binder collection (x «expr ≠ » a)
theorem eq_update_iff {a : α} {b : β a} {f g : ∀ a, β a} : g = update f a b ↔ g a = b ∧ ∀ (x) (_ : x ≠ a), g x = f x :=
  funext_iff.trans <| forall_update_iff _ fun x y => g x = y

@[simp]
theorem update_eq_self (a : α) (f : ∀ a, β a) : update f a (f a) = f :=
  update_eq_iff.2 ⟨rfl, fun _ _ => rfl⟩

theorem update_comp_eq_of_forall_ne'ₓ {α'} (g : ∀ a, β a) {f : α' → α} {i : α} (a : β i) (h : ∀ x, f x ≠ i) :
    (fun j => (update g i a) (f j)) = fun j => g (f j) :=
  funext fun x => update_noteq (h _) _ _

/-- Non-dependent version of `function.update_comp_eq_of_forall_ne'` -/
theorem update_comp_eq_of_forall_neₓ {α β : Sort _} (g : α' → β) {f : α → α'} {i : α'} (a : β) (h : ∀ x, f x ≠ i) :
    update g i a ∘ f = g ∘ f :=
  update_comp_eq_of_forall_ne'ₓ g a h

theorem update_comp_eq_of_injective' (g : ∀ a, β a) {f : α' → α} (hf : Function.Injective f) (i : α') (a : β (f i)) :
    (fun j => update g (f i) a (f j)) = update (fun i => g (f i)) i a :=
  eq_update_iff.2 ⟨update_same _ _ _, fun j hj => update_noteq (hf.Ne hj) _ _⟩

/-- Non-dependent version of `function.update_comp_eq_of_injective'` -/
theorem update_comp_eq_of_injectiveₓ {β : Sort _} (g : α' → β) {f : α → α'} (hf : Function.Injective f) (i : α)
    (a : β) : Function.update g (f i) a ∘ f = Function.update (g ∘ f) i a :=
  update_comp_eq_of_injective' g hf i a

theorem apply_updateₓ {ι : Sort _} [DecidableEq ι] {α β : ι → Sort _} (f : ∀ i, α i → β i) (g : ∀ i, α i) (i : ι)
    (v : α i) (j : ι) : f j (update g i v j) = update (fun k => f k (g k)) i (f i v) j := by
  by_cases' h : j = i
  · subst j
    simp
    
  · simp [h]
    

theorem apply_update₂ {ι : Sort _} [DecidableEq ι] {α β γ : ι → Sort _} (f : ∀ i, α i → β i → γ i) (g : ∀ i, α i)
    (h : ∀ i, β i) (i : ι) (v : α i) (w : β i) (j : ι) :
    f j (update g i v j) (update h i w j) = update (fun k => f k (g k) (h k)) i (f i v w) j := by
  by_cases' h : j = i
  · subst j
    simp
    
  · simp [h]
    

theorem comp_updateₓ {α' : Sort _} {β : Sort _} (f : α' → β) (g : α → α') (i : α) (v : α') :
    f ∘ update g i v = update (f ∘ g) i (f v) :=
  funext <| apply_updateₓ _ _ _ _

theorem update_commₓ {α} [DecidableEq α] {β : α → Sort _} {a b : α} (h : a ≠ b) (v : β a) (w : β b) (f : ∀ a, β a) :
    update (update f a v) b w = update (update f b w) a v := by
  funext c
  simp only [update]
  by_cases' h₁ : c = b <;>
    by_cases' h₂ : c = a <;>
      try
        simp [h₁, h₂]
  cases h (h₂.symm.trans h₁)

@[simp]
theorem update_idemₓ {α} [DecidableEq α] {β : α → Sort _} {a : α} (v w : β a) (f : ∀ a, β a) :
    update (update f a v) a w = update f a w := by
  funext b
  by_cases' b = a <;> simp [update, h]

end Update

section Extend

noncomputable section

attribute [local instance] Classical.propDecidable

variable {α β γ : Sort _} {f : α → β}

/-- `extend f g e'` extends a function `g : α → γ`
along a function `f : α → β` to a function `β → γ`,
by using the values of `g` on the range of `f`
and the values of an auxiliary function `e' : β → γ` elsewhere.

Mostly useful when `f` is injective. -/
def extendₓ (f : α → β) (g : α → γ) (e' : β → γ) : β → γ := fun b =>
  if h : ∃ a, f a = b then g (Classical.choose h) else e' b

theorem extend_defₓ (f : α → β) (g : α → γ) (e' : β → γ) (b : β) [Decidable (∃ a, f a = b)] :
    extendₓ f g e' b = if h : ∃ a, f a = b then g (Classical.choose h) else e' b := by
  unfold extend
  congr

@[simp]
theorem extend_applyₓ (hf : Injective f) (g : α → γ) (e' : β → γ) (a : α) : extendₓ f g e' (f a) = g a := by
  simp only [extend_def, dif_pos, exists_apply_eq_applyₓ]
  exact congr_argₓ g (hf <| Classical.choose_spec (exists_apply_eq_applyₓ f a))

@[simp]
theorem extend_apply' (g : α → γ) (e' : β → γ) (b : β) (hb : ¬∃ a, f a = b) : extendₓ f g e' b = e' b := by
  simp [Function.extend_defₓ, hb]

theorem apply_extend {δ} (hf : Injective f) (F : γ → δ) (g : α → γ) (e' : β → γ) (b : β) :
    F (extendₓ f g e' b) = extendₓ f (F ∘ g) (F ∘ e') b := by
  by_cases' hb : ∃ a, f a = b
  · cases' hb with a ha
    subst b
    rw [extend_apply hf, extend_apply hf]
    
  · rw [extend_apply' _ _ _ hb, extend_apply' _ _ _ hb]
    

theorem extend_injective (hf : Injective f) (e' : β → γ) : Injective fun g => extendₓ f g e' := by
  intro g₁ g₂ hg
  refine' funext fun x => _
  have H := congr_funₓ hg (f x)
  simp only [hf, extend_apply] at H
  exact H

@[simp]
theorem extend_compₓ (hf : Injective f) (g : α → γ) (e' : β → γ) : extendₓ f g e' ∘ f = g :=
  funext fun a => extend_applyₓ hf g e' a

theorem Injective.surjective_comp_right' (hf : Injective f) (g₀ : β → γ) : Surjective fun g : β → γ => g ∘ f := fun g =>
  ⟨extendₓ f g g₀, extend_compₓ hf _ _⟩

theorem Injective.surjective_comp_right [Nonempty γ] (hf : Injective f) : Surjective fun g : β → γ => g ∘ f :=
  hf.surjective_comp_right' fun _ => Classical.choice ‹_›

theorem Bijective.comp_right (hf : Bijective f) : Bijective fun g : β → γ => g ∘ f :=
  ⟨hf.Surjective.injective_comp_right, fun g =>
    ⟨g ∘ surjInv hf.Surjective, by
      simp only [comp.assoc g _ f, (left_inverse_surj_inv hf).comp_eq_id, comp.right_id]⟩⟩

end Extend

theorem uncurry_defₓ {α β γ} (f : α → β → γ) : uncurry f = fun p => f p.1 p.2 :=
  rfl

@[simp]
theorem uncurry_apply_pairₓ {α β γ} (f : α → β → γ) (x : α) (y : β) : uncurry f (x, y) = f x y :=
  rfl

@[simp]
theorem curry_applyₓ {α β γ} (f : α × β → γ) (x : α) (y : β) : curry f x y = f (x, y) :=
  rfl

section Bicomp

variable {α β γ δ ε : Type _}

/-- Compose a binary function `f` with a pair of unary functions `g` and `h`.
If both arguments of `f` have the same type and `g = h`, then `bicompl f g g = f on g`. -/
def bicompl (f : γ → δ → ε) (g : α → γ) (h : β → δ) (a b) :=
  f (g a) (h b)

/-- Compose an unary function `f` with a binary function `g`. -/
def bicompr (f : γ → δ) (g : α → β → γ) (a b) :=
  f (g a b)

-- mathport name: «expr ∘₂ »
-- Suggested local notation:
local notation f "∘₂" g => bicompr f g

theorem uncurry_bicomprₓ (f : α → β → γ) (g : γ → δ) : uncurry (g∘₂f) = g ∘ uncurry f :=
  rfl

theorem uncurry_bicomplₓ (f : γ → δ → ε) (g : α → γ) (h : β → δ) : uncurry (bicompl f g h) = uncurry f ∘ Prod.map g h :=
  rfl

end Bicomp

section Uncurry

variable {α β γ δ : Type _}

/-- Records a way to turn an element of `α` into a function from `β` to `γ`. The most generic use
is to recursively uncurry. For instance `f : α → β → γ → δ` will be turned into
`↿f : α × β × γ → δ`. One can also add instances for bundled maps. -/
class HasUncurry (α : Type _) (β : outParam (Type _)) (γ : outParam (Type _)) where
  uncurry : α → β → γ

-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:51:50: missing argument
-- ./././Mathport/Syntax/Translate/Command.lean:665:43: in add_decl_doc #[[ident has_uncurry.uncurry]]: ./././Mathport/Syntax/Translate/Tactic/Basic.lean:54:35: expecting parse arg
-- mathport name: uncurry
notation:arg "↿" x:arg => HasUncurry.uncurry x

instance hasUncurryBase : HasUncurry (α → β) α β :=
  ⟨id⟩

instance hasUncurryInduction [HasUncurry β γ δ] : HasUncurry (α → β) (α × γ) δ :=
  ⟨fun f p => (↿(f p.1)) p.2⟩

end Uncurry

/-- A function is involutive, if `f ∘ f = id`. -/
def Involutive {α} (f : α → α) : Prop :=
  ∀ x, f (f x) = x

theorem involutive_iff_iter_2_eq_id {α} {f : α → α} : Involutive f ↔ f^[2] = id :=
  funext_iff.symm

namespace Involutive

variable {α : Sort u} {f : α → α} (h : Involutive f)

include h

@[simp]
theorem comp_self : f ∘ f = id :=
  funext h

protected theorem left_inverse : LeftInverse f f :=
  h

protected theorem right_inverse : RightInverse f f :=
  h

protected theorem injective : Injective f :=
  h.LeftInverse.Injective

protected theorem surjective : Surjective f := fun x => ⟨f x, h x⟩

protected theorem bijective : Bijective f :=
  ⟨h.Injective, h.Surjective⟩

/-- Involuting an `ite` of an involuted value `x : α` negates the `Prop` condition in the `ite`. -/
protected theorem ite_not (P : Prop) [Decidable P] (x : α) : f (ite P x (f x)) = ite (¬P) x (f x) := by
  rw [apply_iteₓ f, h, ite_not]

/-- An involution commutes across an equality. Compare to `function.injective.eq_iff`. -/
protected theorem eq_iff {x y : α} : f x = y ↔ x = f y :=
  h.Injective.eq_iff' (h y)

end Involutive

/-- The property of a binary function `f : α → β → γ` being injective.
Mathematically this should be thought of as the corresponding function `α × β → γ` being injective.
-/
def Injective2 {α β γ} (f : α → β → γ) : Prop :=
  ∀ ⦃a₁ a₂ b₁ b₂⦄, f a₁ b₁ = f a₂ b₂ → a₁ = a₂ ∧ b₁ = b₂

namespace Injective2

variable {α β γ : Sort _} {f : α → β → γ}

/-- A binary injective function is injective when only the left argument varies. -/
protected theorem left (hf : Injective2 f) (b : β) : Function.Injective fun a => f a b := fun a₁ a₂ h => (hf h).left

/-- A binary injective function is injective when only the right argument varies. -/
protected theorem right (hf : Injective2 f) (a : α) : Function.Injective (f a) := fun a₁ a₂ h => (hf h).right

protected theorem uncurry {α β γ : Type _} {f : α → β → γ} (hf : Injective2 f) : Function.Injective (uncurry f) :=
  fun ⟨a₁, b₁⟩ ⟨a₂, b₂⟩ h => And.elimₓ (hf h) (congr_arg2ₓ _)

/-- As a map from the left argument to a unary function, `f` is injective. -/
theorem left' (hf : Injective2 f) [Nonempty β] : Function.Injective f := fun a₁ a₂ h =>
  let ⟨b⟩ := ‹Nonempty β›
  hf.left b <| (congr_funₓ h b : _)

/-- As a map from the right argument to a unary function, `f` is injective. -/
theorem right' (hf : Injective2 f) [Nonempty α] : Function.Injective fun b a => f a b := fun b₁ b₂ h =>
  let ⟨a⟩ := ‹Nonempty α›
  hf.right a <| (congr_funₓ h a : _)

theorem eq_iff (hf : Injective2 f) {a₁ a₂ b₁ b₂} : f a₁ b₁ = f a₂ b₂ ↔ a₁ = a₂ ∧ b₁ = b₂ :=
  ⟨fun h => hf h, And.ndrec <| congr_arg2ₓ f⟩

end Injective2

section Sometimes

attribute [local instance] Classical.propDecidable

/-- `sometimes f` evaluates to some value of `f`, if it exists. This function is especially
interesting in the case where `α` is a proposition, in which case `f` is necessarily a
constant function, so that `sometimes f = f a` for all `a`. -/
noncomputable def sometimes {α β} [Nonempty β] (f : α → β) : β :=
  if h : Nonempty α then f (Classical.choice h) else Classical.choice ‹_›

theorem sometimes_eq {p : Prop} {α} [Nonempty α] (f : p → α) (a : p) : sometimes f = f a :=
  dif_pos ⟨a⟩

theorem sometimes_spec {p : Prop} {α} [Nonempty α] (P : α → Prop) (f : p → α) (a : p) (h : P (f a)) : P (sometimes f) :=
  by
  rwa [sometimes_eq]

end Sometimes

end Function

/-- `s.piecewise f g` is the function equal to `f` on the set `s`, and to `g` on its complement. -/
def Set.piecewise {α : Type u} {β : α → Sort v} (s : Set α) (f g : ∀ i, β i) [∀ j, Decidable (j ∈ s)] : ∀ i, β i :=
  fun i => if i ∈ s then f i else g i

/-! ### Bijectivity of `eq.rec`, `eq.mp`, `eq.mpr`, and `cast` -/


theorem eq_rec_on_bijective {α : Sort _} {C : α → Sort _} :
    ∀ {a a' : α} (h : a = a'), Function.Bijective (@Eq.recOnₓ _ _ C _ h)
  | _, _, rfl => ⟨fun x y => id, fun x => ⟨x, rfl⟩⟩

theorem eq_mp_bijective {α β : Sort _} (h : α = β) : Function.Bijective (Eq.mp h) :=
  eq_rec_on_bijective h

theorem eq_mpr_bijective {α β : Sort _} (h : α = β) : Function.Bijective (Eq.mpr h) :=
  eq_rec_on_bijective h.symm

theorem cast_bijective {α β : Sort _} (h : α = β) : Function.Bijective (cast h) :=
  eq_rec_on_bijective h

/-! Note these lemmas apply to `Type*` not `Sort*`, as the latter interferes with `simp`, and
is trivial anyway.-/


@[simp]
theorem eq_rec_inj {α : Sort _} {a a' : α} (h : a = a') {C : α → Type _} (x y : C a) :
    (Eq.ndrec x h : C a') = Eq.ndrec y h ↔ x = y :=
  (eq_rec_on_bijective h).Injective.eq_iff

@[simp]
theorem cast_inj {α β : Type _} (h : α = β) {x y : α} : cast h x = cast h y ↔ x = y :=
  (cast_bijective h).Injective.eq_iff

theorem Function.LeftInverse.eq_rec_eq {α β : Sort _} {γ : β → Sort v} {f : α → β} {g : β → α}
    (h : Function.LeftInverse g f) (C : ∀ a : α, γ (f a)) (a : α) : (congr_argₓ f (h a)).rec (C (g (f a))) = C a :=
  eq_of_heq <|
    (eq_rec_heqₓ _ _).trans <| by
      rw [h]

theorem Function.LeftInverse.eq_rec_on_eq {α β : Sort _} {γ : β → Sort v} {f : α → β} {g : β → α}
    (h : Function.LeftInverse g f) (C : ∀ a : α, γ (f a)) (a : α) : (congr_argₓ f (h a)).recOn (C (g (f a))) = C a :=
  h.eq_rec_eq _ _

theorem Function.LeftInverse.cast_eq {α β : Sort _} {γ : β → Sort v} {f : α → β} {g : β → α}
    (h : Function.LeftInverse g f) (C : ∀ a : α, γ (f a)) (a : α) :
    cast (congr_argₓ (fun a => γ (f a)) (h a)) (C (g (f a))) = C a :=
  eq_of_heq <|
    (eq_rec_heqₓ _ _).trans <| by
      rw [h]

/-- A set of functions "separates points"
if for each pair of distinct points there is a function taking different values on them. -/
def Set.SeparatesPoints {α β : Type _} (A : Set (α → β)) : Prop :=
  ∀ ⦃x y : α⦄, x ≠ y → ∃ f ∈ A, (f x : β) ≠ f y

theorem IsSymmOp.flip_eq {α β} (op) [IsSymmOp α β op] : flip op = op :=
  funext fun a => funext fun b => (IsSymmOp.symm_op a b).symm

theorem InvImage.equivalence {α : Sort u} {β : Sort v} (r : β → β → Prop) (f : α → β) (h : Equivalenceₓ r) :
    Equivalenceₓ (InvImage r f) :=
  ⟨fun _ => h.1 _, fun _ _ x => h.2.1 x, InvImage.trans r f h.2.2⟩

