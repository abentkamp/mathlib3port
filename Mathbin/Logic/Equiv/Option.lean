/-
Copyright (c) 2021 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import Mathbin.Control.EquivFunctor
import Mathbin.Logic.Equiv.Basic

/-!
# Equivalences for `option α`


We define
* `equiv.option_congr`: the `option α ≃ option β` constructed from `e : α ≃ β` by sending `none` to
  `none`, and applying a `e` elsewhere.
* `equiv.remove_none`: the `α ≃ β` constructed from `option α ≃ option β` by removing `none` from
  both sides.
-/


namespace Equivₓ

open Option

variable {α β γ : Type _}

section OptionCongr

/-- A universe-polymorphic version of `equiv_functor.map_equiv option e`. -/
@[simps apply]
def optionCongr (e : α ≃ β) : Option α ≃ Option β where
  toFun := Option.map e
  invFun := Option.map e.symm
  left_inv := fun x => (Option.map_mapₓ _ _ _).trans <| e.symm_comp_self.symm ▸ congr_funₓ Option.map_id x
  right_inv := fun x => (Option.map_mapₓ _ _ _).trans <| e.self_comp_symm.symm ▸ congr_funₓ Option.map_id x

@[simp]
theorem option_congr_refl : optionCongr (Equivₓ.refl α) = Equivₓ.refl _ :=
  ext <| congr_funₓ Option.map_id

@[simp]
theorem option_congr_symm (e : α ≃ β) : (optionCongr e).symm = optionCongr e.symm :=
  rfl

@[simp]
theorem option_congr_trans (e₁ : α ≃ β) (e₂ : β ≃ γ) :
    (optionCongr e₁).trans (optionCongr e₂) = optionCongr (e₁.trans e₂) :=
  ext <| Option.map_mapₓ _ _

/-- When `α` and `β` are in the same universe, this is the same as the result of
`equiv_functor.map_equiv`. -/
theorem option_congr_eq_equiv_function_map_equiv {α β : Type _} (e : α ≃ β) :
    optionCongr e = EquivFunctor.mapEquiv Option e :=
  rfl

end OptionCongr

section RemoveNone

variable (e : Option α ≃ Option β)

private def remove_none_aux (x : α) : β :=
  if h : (e (some x)).isSome then Option.getₓ h
  else
    Option.getₓ <|
      show (e none).isSome by
        rw [← Option.ne_none_iff_is_some]
        intro hn
        rw [Option.not_is_some_iff_eq_none, ← hn] at h
        simpa only using e.injective h

private theorem remove_none_aux_some {x : α} (h : ∃ x', e (some x) = some x') : some (removeNoneAux e x) = e (some x) :=
  by
  simp [remove_none_aux, option.is_some_iff_exists.mpr h]

private theorem remove_none_aux_none {x : α} (h : e (some x) = none) : some (removeNoneAux e x) = e none := by
  simp [remove_none_aux, option.not_is_some_iff_eq_none.mpr h]

private theorem remove_none_aux_inv (x : α) : removeNoneAux e.symm (removeNoneAux e x) = x :=
  Option.some_injective _
    (by
      cases h1 : e.symm (some (remove_none_aux e x)) <;> cases h2 : e (some x)
      · rw [remove_none_aux_none _ h1]
        exact (e.eq_symm_apply.mpr h2).symm
        
      · rw [remove_none_aux_some _ ⟨_, h2⟩] at h1
        simpa using h1
        
      · rw [remove_none_aux_none _ h2] at h1
        simpa using h1
        
      · rw [remove_none_aux_some _ ⟨_, h1⟩]
        rw [remove_none_aux_some _ ⟨_, h2⟩]
        simp
        )

/-- Given an equivalence between two `option` types, eliminate `none` from that equivalence by
mapping `e.symm none` to `e none`. -/
def removeNone : α ≃ β where
  toFun := removeNoneAux e
  invFun := removeNoneAux e.symm
  left_inv := remove_none_aux_inv e
  right_inv := remove_none_aux_inv e.symm

@[simp]
theorem remove_none_symm : (removeNone e).symm = removeNone e.symm :=
  rfl

theorem remove_none_some {x : α} (h : ∃ x', e (some x) = some x') : some (removeNone e x) = e (some x) :=
  remove_none_aux_some e h

theorem remove_none_none {x : α} (h : e (some x) = none) : some (removeNone e x) = e none :=
  remove_none_aux_none e h

@[simp]
theorem option_symm_apply_none_iff : e.symm none = none ↔ e none = none :=
  ⟨fun h => by
    simpa using (congr_argₓ e h).symm, fun h => by
    simpa using (congr_argₓ e.symm h).symm⟩

theorem some_remove_none_iff {x : α} : some (removeNone e x) = e none ↔ e.symm none = some x := by
  cases' h : e (some x) with a
  · rw [remove_none_none _ h]
    simpa using (congr_argₓ e.symm h).symm
    
  · rw [remove_none_some _ ⟨a, h⟩]
    have := congr_argₓ e.symm h
    rw [symm_apply_apply] at this
    simp only [false_iffₓ, apply_eq_iff_eq]
    simp [this]
    

@[simp]
theorem remove_none_option_congr (e : α ≃ β) : removeNone e.optionCongr = e :=
  Equivₓ.ext fun x =>
    Option.some_injective _ <|
      remove_none_some _
        ⟨e x, by
          simp [EquivFunctor.map]⟩

end RemoveNone

theorem option_congr_injective : Function.Injective (optionCongr : α ≃ β → Option α ≃ Option β) :=
  Function.LeftInverse.injective remove_none_option_congr

/-- Equivalences between `option α` and `β` that send `none` to `x` are equivalent to
equivalences between `α` and `{y : β // y ≠ x}`. -/
def optionSubtype [DecidableEq β] (x : β) : { e : Option α ≃ β // e none = x } ≃ (α ≃ { y : β // y ≠ x }) where
  toFun := fun e =>
    { toFun := fun a => ⟨e a, ((EquivLike.injective _).ne_iff' e.property).2 (some_ne_none _)⟩,
      invFun := fun b =>
        get
          (ne_none_iff_is_some.1
            (((EquivLike.injective _).ne_iff' ((apply_eq_iff_eq_symm_apply _).1 e.property).symm).2 b.property)),
      left_inv := fun a => by
        rw [← some_inj, some_get, ← coe_def]
        exact symm_apply_apply (e : Option α ≃ β) a,
      right_inv := fun b => by
        ext
        simp
        exact apply_symm_apply _ _ }
  invFun := fun e =>
    ⟨{ toFun := fun a => casesOn' a x (coe ∘ e), invFun := fun b => if h : b = x then none else e.symm ⟨b, h⟩,
        left_inv := fun a => by
          cases a
          · simp
            
          simp only [cases_on'_some, Function.comp_app, Subtype.coe_eta, symm_apply_apply, dite_eq_ite]
          exact if_neg (e a).property,
        right_inv := fun b => by
          by_cases' h : b = x <;> simp [h] },
      rfl⟩
  left_inv := fun e => by
    ext a
    cases a
    · simpa using e.property.symm
      
    · simpa
      
  right_inv := fun e => by
    ext a
    rfl

@[simp]
theorem option_subtype_apply_apply [DecidableEq β] (x : β) (e : { e : Option α ≃ β // e none = x }) (a : α) (h) :
    optionSubtype x e a = ⟨(e : Option α ≃ β) a, h⟩ :=
  rfl

@[simp]
theorem coe_option_subtype_apply_apply [DecidableEq β] (x : β) (e : { e : Option α ≃ β // e none = x }) (a : α) :
    ↑(optionSubtype x e a) = (e : Option α ≃ β) a :=
  rfl

@[simp]
theorem option_subtype_apply_symm_apply [DecidableEq β] (x : β) (e : { e : Option α ≃ β // e none = x })
    (b : { y : β // y ≠ x }) : ↑((optionSubtype x e).symm b) = (e : Option α ≃ β).symm b := by
  dsimp' only [option_subtype]
  simp

@[simp]
theorem option_subtype_symm_apply_apply_coe [DecidableEq β] (x : β) (e : α ≃ { y : β // y ≠ x }) (a : α) :
    (optionSubtype x).symm e a = e a :=
  rfl

@[simp]
theorem option_subtype_symm_apply_apply_some [DecidableEq β] (x : β) (e : α ≃ { y : β // y ≠ x }) (a : α) :
    (optionSubtype x).symm e (some a) = e a :=
  rfl

@[simp]
theorem option_subtype_symm_apply_apply_none [DecidableEq β] (x : β) (e : α ≃ { y : β // y ≠ x }) :
    (optionSubtype x).symm e none = x :=
  rfl

@[simp]
theorem option_subtype_symm_apply_symm_apply [DecidableEq β] (x : β) (e : α ≃ { y : β // y ≠ x })
    (b : { y : β // y ≠ x }) : ((optionSubtype x).symm e : Option α ≃ β).symm b = e.symm b := by
  simp only [option_subtype, coe_fn_symm_mk, Subtype.coe_mk, Subtype.coe_eta, dite_eq_ite, ite_eq_right_iff]
  exact fun h => False.elim (b.property h)

end Equivₓ

