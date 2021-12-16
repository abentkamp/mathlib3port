import Mathbin.Algebra.Group.Defs 
import Mathbin.Data.Equiv.Set 
import Mathbin.Logic.Embedding 
import Mathbin.Order.RelClasses

/-!
# Relation homomorphisms, embeddings, isomorphisms

This file defines relation homomorphisms, embeddings, isomorphisms and order embeddings and
isomorphisms.

## Main declarations

* `rel_hom`: Relation homomorphism. A `rel_hom r s` is a function `f : α → β` such that
  `r a b → s (f a) (f b)`.
* `rel_embedding`: Relation embedding. A `rel_embedding r s` is an embedding `f : α ↪ β` such that
  `r a b ↔ s (f a) (f b)`.
* `rel_iso`: Relation isomorphism. A `rel_iso r s` is an equivalence `f : α ≃ β` such that
  `r a b ↔ s (f a) (f b)`.
* `sum_lex_congr`, `prod_lex_congr`: Creates a relation homomorphism between two `sum_lex` or two
  `prod_lex` from relation homomorphisms between their arguments.

## Notation

* `→r`: `rel_hom`
* `↪r`: `rel_embedding`
* `≃r`: `rel_iso`
-/


open Function

universe u v w

variable {α β γ : Type _} {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

/-- A relation homomorphism with respect to a given pair of relations `r` and `s`
is a function `f : α → β` such that `r a b → s (f a) (f b)`. -/
@[nolint has_inhabited_instance]
structure RelHom {α β : Type _} (r : α → α → Prop) (s : β → β → Prop) where 
  toFun : α → β 
  map_rel' : ∀ {a b}, r a b → s (to_fun a) (to_fun b)

infixl:25 " →r " => RelHom

namespace RelHom

instance : CoeFun (r →r s) fun _ => α → β :=
  ⟨fun o => o.to_fun⟩

initialize_simps_projections RelHom (toFun → apply)

theorem map_rel (f : r →r s) : ∀ {a b}, r a b → s (f a) (f b) :=
  f.map_rel'

@[simp]
theorem coe_fn_mk (f : α → β) o : (@RelHom.mk _ _ r s f o : α → β) = f :=
  rfl

@[simp]
theorem coe_fn_to_fun (f : r →r s) : (f.to_fun : α → β) = f :=
  rfl

/-- The map `coe_fn : (r →r s) → (α → β)` is injective. -/
theorem coe_fn_injective : @Function.Injective (r →r s) (α → β) coeFn
| ⟨f₁, o₁⟩, ⟨f₂, o₂⟩, h =>
  by 
    congr 
    exact h

@[ext]
theorem ext ⦃f g : r →r s⦄ (h : ∀ x, f x = g x) : f = g :=
  coe_fn_injective (funext h)

theorem ext_iff {f g : r →r s} : f = g ↔ ∀ x, f x = g x :=
  ⟨fun h x => h ▸ rfl, fun h => ext h⟩

/-- Identity map is a relation homomorphism. -/
@[refl, simps]
protected def id (r : α → α → Prop) : r →r r :=
  ⟨fun x => x, fun a b x => x⟩

/-- Composition of two relation homomorphisms is a relation homomorphism. -/
@[trans, simps]
protected def comp (g : s →r t) (f : r →r s) : r →r t :=
  ⟨fun x => g (f x), fun a b h => g.2 (f.2 h)⟩

/-- A relation homomorphism is also a relation homomorphism between dual relations. -/
protected def swap (f : r →r s) : swap r →r swap s :=
  ⟨f, fun a b => f.map_rel⟩

/-- A function is a relation homomorphism from the preimage relation of `s` to `s`. -/
def preimage (f : α → β) (s : β → β → Prop) : f ⁻¹'o s →r s :=
  ⟨f, fun a b => id⟩

protected theorem IsIrrefl : ∀ f : r →r s [IsIrrefl β s], IsIrrefl α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a h => H _ (o h)⟩

protected theorem IsAsymm : ∀ f : r →r s [IsAsymm β s], IsAsymm α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a b h₁ h₂ => H _ _ (o h₁) (o h₂)⟩

protected theorem Acc (f : r →r s) (a : α) : Acc s (f a) → Acc r a :=
  by 
    generalize h : f a = b 
    intro ac 
    induction' ac with _ H IH generalizing a 
    subst h 
    exact ⟨_, fun a' h => IH (f a') (f.map_rel h) _ rfl⟩

protected theorem WellFounded : ∀ f : r →r s h : WellFounded s, WellFounded r
| f, ⟨H⟩ => ⟨fun a => f.acc _ (H _)⟩

theorem map_inf {α β : Type _} [SemilatticeInf α] [LinearOrderₓ β]
  (a : (· < · : β → β → Prop) →r (· < · : α → α → Prop)) (m n : β) : a (m⊓n) = a m⊓a n :=
  (StrictMono.monotone$ fun x y => a.map_rel).map_inf m n

theorem map_sup {α β : Type _} [SemilatticeSup α] [LinearOrderₓ β]
  (a : (· > · : β → β → Prop) →r (· > · : α → α → Prop)) (m n : β) : a (m⊔n) = a m⊔a n :=
  @RelHom.map_inf (OrderDual α) (OrderDual β) _ _ _ _ _

end RelHom

/-- An increasing function is injective -/
theorem injective_of_increasing (r : α → α → Prop) (s : β → β → Prop) [IsTrichotomous α r] [IsIrrefl β s] (f : α → β)
  (hf : ∀ {x y}, r x y → s (f x) (f y)) : injective f :=
  by 
    intro x y hxy 
    rcases trichotomous_of r x y with (h | h | h)
    have  := hf h 
    rw [hxy] at this 
    exfalso 
    exact irrefl_of s (f y) this 
    exact h 
    have  := hf h 
    rw [hxy] at this 
    exfalso 
    exact irrefl_of s (f y) this

/-- An increasing function is injective -/
theorem RelHom.injective_of_increasing [IsTrichotomous α r] [IsIrrefl β s] (f : r →r s) : injective f :=
  injective_of_increasing r s f fun x y => f.map_rel

theorem Surjective.well_founded_iff {f : α → β} (hf : surjective f) (o : ∀ {a b}, r a b ↔ s (f a) (f b)) :
  WellFounded r ↔ WellFounded s :=
  Iff.intro
    (by 
      apply RelHom.well_founded 
      refine' RelHom.mk _ _
      ·
        exact Classical.some hf.has_right_inverse 
      intro a b h 
      apply o.2
      convert h 
      iterate 2 
        apply Classical.some_spec hf.has_right_inverse)
    (RelHom.well_founded ⟨f, fun _ _ => o.1⟩)

/-- A relation embedding with respect to a given pair of relations `r` and `s`
is an embedding `f : α ↪ β` such that `r a b ↔ s (f a) (f b)`. -/
structure RelEmbedding {α β : Type _} (r : α → α → Prop) (s : β → β → Prop) extends α ↪ β where 
  map_rel_iff' : ∀ {a b}, s (to_embedding a) (to_embedding b) ↔ r a b

infixl:25 " ↪r " => RelEmbedding

/-- The induced relation on a subtype is an embedding under the natural inclusion. -/
def Subtype.relEmbedding {X : Type _} (r : X → X → Prop) (p : X → Prop) : (Subtype.val : Subtype p → X) ⁻¹'o r ↪r r :=
  ⟨embedding.subtype p, fun x y => Iff.rfl⟩

theorem preimage_equivalence {α β} (f : α → β) {s : β → β → Prop} (hs : Equivalenceₓ s) : Equivalenceₓ (f ⁻¹'o s) :=
  ⟨fun a => hs.1 _, fun a b h => hs.2.1 h, fun a b c h₁ h₂ => hs.2.2 h₁ h₂⟩

namespace RelEmbedding

/-- A relation embedding is also a relation homomorphism -/
def to_rel_hom (f : r ↪r s) : r →r s :=
  { toFun := f.to_embedding.to_fun, map_rel' := fun x y => (map_rel_iff' f).mpr }

instance : Coe (r ↪r s) (r →r s) :=
  ⟨to_rel_hom⟩

instance : CoeFun (r ↪r s) fun _ => α → β :=
  ⟨fun o => o.to_embedding⟩

/-- See Note [custom simps projection]. We need to specify this projection explicitly in this case,
because it is a composition of multiple projections. -/
def simps.apply (h : r ↪r s) : α → β :=
  h

initialize_simps_projections RelEmbedding (to_embedding_to_fun → apply, -toEmbedding)

@[simp]
theorem to_rel_hom_eq_coe (f : r ↪r s) : f.to_rel_hom = f :=
  rfl

@[simp]
theorem coe_coe_fn (f : r ↪r s) : ((f : r →r s) : α → β) = f :=
  rfl

theorem injective (f : r ↪r s) : injective f :=
  f.inj'

theorem map_rel_iff (f : r ↪r s) : ∀ {a b}, s (f a) (f b) ↔ r a b :=
  f.map_rel_iff'

@[simp]
theorem coe_fn_mk (f : α ↪ β) o : (@RelEmbedding.mk _ _ r s f o : α → β) = f :=
  rfl

@[simp]
theorem coe_fn_to_embedding (f : r ↪r s) : (f.to_embedding : α → β) = f :=
  rfl

/-- The map `coe_fn : (r ↪r s) → (α → β)` is injective. -/
theorem coe_fn_injective : @Function.Injective (r ↪r s) (α → β) coeFn
| ⟨⟨f₁, h₁⟩, o₁⟩, ⟨⟨f₂, h₂⟩, o₂⟩, h =>
  by 
    congr 
    exact h

@[ext]
theorem ext ⦃f g : r ↪r s⦄ (h : ∀ x, f x = g x) : f = g :=
  coe_fn_injective (funext h)

theorem ext_iff {f g : r ↪r s} : f = g ↔ ∀ x, f x = g x :=
  ⟨fun h x => h ▸ rfl, fun h => ext h⟩

/-- Identity map is a relation embedding. -/
@[refl, simps]
protected def refl (r : α → α → Prop) : r ↪r r :=
  ⟨embedding.refl _, fun a b => Iff.rfl⟩

/-- Composition of two relation embeddings is a relation embedding. -/
@[trans]
protected def trans (f : r ↪r s) (g : s ↪r t) : r ↪r t :=
  ⟨f.1.trans g.1,
    fun a b =>
      by 
        simp [f.map_rel_iff, g.map_rel_iff]⟩

instance (r : α → α → Prop) : Inhabited (r ↪r r) :=
  ⟨RelEmbedding.refl _⟩

theorem trans_apply (f : r ↪r s) (g : s ↪r t) (a : α) : (f.trans g) a = g (f a) :=
  rfl

@[simp]
theorem coeTransₓ (f : r ↪r s) (g : s ↪r t) : ⇑f.trans g = g ∘ f :=
  rfl

/-- A relation embedding is also a relation embedding between dual relations. -/
protected def swap (f : r ↪r s) : swap r ↪r swap s :=
  ⟨f.to_embedding, fun a b => f.map_rel_iff⟩

/-- If `f` is injective, then it is a relation embedding from the
  preimage relation of `s` to `s`. -/
def preimage (f : α ↪ β) (s : β → β → Prop) : f ⁻¹'o s ↪r s :=
  ⟨f, fun a b => Iff.rfl⟩

theorem eq_preimage (f : r ↪r s) : r = f ⁻¹'o s :=
  by 
    ext a b 
    exact f.map_rel_iff.symm

protected theorem IsIrrefl (f : r ↪r s) [IsIrrefl β s] : IsIrrefl α r :=
  ⟨fun a => mt f.map_rel_iff.2 (irrefl (f a))⟩

protected theorem IsRefl (f : r ↪r s) [IsRefl β s] : IsRefl α r :=
  ⟨fun a => f.map_rel_iff.1$ refl _⟩

protected theorem IsSymm (f : r ↪r s) [IsSymm β s] : IsSymm α r :=
  ⟨fun a b => imp_imp_imp f.map_rel_iff.2 f.map_rel_iff.1 symm⟩

protected theorem IsAsymm (f : r ↪r s) [IsAsymm β s] : IsAsymm α r :=
  ⟨fun a b h₁ h₂ => asymm (f.map_rel_iff.2 h₁) (f.map_rel_iff.2 h₂)⟩

protected theorem IsAntisymm : ∀ f : r ↪r s [IsAntisymm β s], IsAntisymm α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a b h₁ h₂ => f.inj' (H _ _ (o.2 h₁) (o.2 h₂))⟩

protected theorem IsTrans : ∀ f : r ↪r s [IsTrans β s], IsTrans α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a b c h₁ h₂ => o.1 (H _ _ _ (o.2 h₁) (o.2 h₂))⟩

protected theorem IsTotal : ∀ f : r ↪r s [IsTotal β s], IsTotal α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a b => (or_congr o o).1 (H _ _)⟩

protected theorem IsPreorder : ∀ f : r ↪r s [IsPreorder β s], IsPreorder α r
| f, H =>
  by 
    exact { f.is_refl, f.is_trans with  }

protected theorem IsPartialOrder : ∀ f : r ↪r s [IsPartialOrder β s], IsPartialOrder α r
| f, H =>
  by 
    exact { f.is_preorder, f.is_antisymm with  }

protected theorem IsLinearOrder : ∀ f : r ↪r s [IsLinearOrder β s], IsLinearOrder α r
| f, H =>
  by 
    exact { f.is_partial_order, f.is_total with  }

protected theorem IsStrictOrder : ∀ f : r ↪r s [IsStrictOrder β s], IsStrictOrder α r
| f, H =>
  by 
    exact { f.is_irrefl, f.is_trans with  }

protected theorem IsTrichotomous : ∀ f : r ↪r s [IsTrichotomous β s], IsTrichotomous α r
| ⟨f, o⟩, ⟨H⟩ => ⟨fun a b => (or_congr o (or_congr f.inj'.eq_iff o)).1 (H _ _)⟩

protected theorem IsStrictTotalOrder' : ∀ f : r ↪r s [IsStrictTotalOrder' β s], IsStrictTotalOrder' α r
| f, H =>
  by 
    exact { f.is_trichotomous, f.is_strict_order with  }

protected theorem Acc (f : r ↪r s) (a : α) : Acc s (f a) → Acc r a :=
  by 
    generalize h : f a = b 
    intro ac 
    induction' ac with _ H IH generalizing a 
    subst h 
    exact ⟨_, fun a' h => IH (f a') (f.map_rel_iff.2 h) _ rfl⟩

protected theorem WellFounded : ∀ f : r ↪r s h : WellFounded s, WellFounded r
| f, ⟨H⟩ => ⟨fun a => f.acc _ (H _)⟩

protected theorem IsWellOrder : ∀ f : r ↪r s [IsWellOrder β s], IsWellOrder α r
| f, H =>
  by 
    exact { f.is_strict_total_order' with wf := f.well_founded H.wf }

/--
To define an relation embedding from an antisymmetric relation `r` to a reflexive relation `s` it
suffices to give a function together with a proof that it satisfies `s (f a) (f b) ↔ r a b`.
-/
def of_map_rel_iff (f : α → β) [IsAntisymm α r] [IsRefl β s] (hf : ∀ a b, s (f a) (f b) ↔ r a b) : r ↪r s :=
  { toFun := f, inj' := fun x y h => antisymm ((hf _ _).1 (h ▸ refl _)) ((hf _ _).1 (h ▸ refl _)), map_rel_iff' := hf }

@[simp]
theorem of_map_rel_iff_coe (f : α → β) [IsAntisymm α r] [IsRefl β s] (hf : ∀ a b, s (f a) (f b) ↔ r a b) :
  ⇑(of_map_rel_iff f hf : r ↪r s) = f :=
  rfl

/-- It suffices to prove `f` is monotone between strict relations
  to show it is a relation embedding. -/
def of_monotone [IsTrichotomous α r] [IsAsymm β s] (f : α → β) (H : ∀ a b, r a b → s (f a) (f b)) : r ↪r s :=
  by 
    have  := @IsAsymm.is_irrefl β s _ 
    refine' ⟨⟨f, fun a b e => _⟩, fun a b => ⟨fun h => _, H _ _⟩⟩
    ·
      refine' ((@trichotomous _ r _ a b).resolve_left _).resolve_right _ <;>
        exact
          fun h =>
            @irrefl _ s _ _
              (by 
                simpa [e] using H _ _ h)
    ·
      refine' (@trichotomous _ r _ a b).resolve_right (Or.ndrec (fun e => _) fun h' => _)
      ·
        subst e 
        exact irrefl _ h
      ·
        exact asymm (H _ _ h') h

@[simp]
theorem of_monotone_coe [IsTrichotomous α r] [IsAsymm β s] (f : α → β) H : (@of_monotone _ _ r s _ _ f H : α → β) = f :=
  rfl

end RelEmbedding

/-- A relation isomorphism is an equivalence that is also a relation embedding. -/
structure RelIso {α β : Type _} (r : α → α → Prop) (s : β → β → Prop) extends α ≃ β where 
  map_rel_iff' : ∀ {a b}, s (to_equiv a) (to_equiv b) ↔ r a b

infixl:25 " ≃r " => RelIso

namespace RelIso

/-- Convert an `rel_iso` to an `rel_embedding`. This function is also available as a coercion
but often it is easier to write `f.to_rel_embedding` than to write explicitly `r` and `s`
in the target type. -/
def to_rel_embedding (f : r ≃r s) : r ↪r s :=
  ⟨f.to_equiv.to_embedding, f.map_rel_iff'⟩

instance : Coe (r ≃r s) (r ↪r s) :=
  ⟨to_rel_embedding⟩

instance : CoeFun (r ≃r s) fun _ => α → β :=
  ⟨fun f => f⟩

@[simp]
theorem to_rel_embedding_eq_coe (f : r ≃r s) : f.to_rel_embedding = f :=
  rfl

@[simp]
theorem coe_coe_fn (f : r ≃r s) : ((f : r ↪r s) : α → β) = f :=
  rfl

theorem map_rel_iff (f : r ≃r s) : ∀ {a b}, s (f a) (f b) ↔ r a b :=
  f.map_rel_iff'

@[simp]
theorem coe_fn_mk (f : α ≃ β) (o : ∀ ⦃a b⦄, s (f a) (f b) ↔ r a b) : (RelIso.mk f o : α → β) = f :=
  rfl

@[simp]
theorem coe_fn_to_equiv (f : r ≃r s) : (f.to_equiv : α → β) = f :=
  rfl

theorem to_equiv_injective : injective (to_equiv : r ≃r s → α ≃ β)
| ⟨e₁, o₁⟩, ⟨e₂, o₂⟩, h =>
  by 
    congr 
    exact h

/-- The map `coe_fn : (r ≃r s) → (α → β)` is injective. Lean fails to parse
`function.injective (λ e : r ≃r s, (e : α → β))`, so we use a trick to say the same. -/
theorem coe_fn_injective : @Function.Injective (r ≃r s) (α → β) coeFn :=
  Equivₓ.coe_fn_injective.comp to_equiv_injective

@[ext]
theorem ext ⦃f g : r ≃r s⦄ (h : ∀ x, f x = g x) : f = g :=
  coe_fn_injective (funext h)

theorem ext_iff {f g : r ≃r s} : f = g ↔ ∀ x, f x = g x :=
  ⟨fun h x => h ▸ rfl, fun h => ext h⟩

/-- Inverse map of a relation isomorphism is a relation isomorphism. -/
@[symm]
protected def symm (f : r ≃r s) : s ≃r r :=
  ⟨f.to_equiv.symm,
    fun a b =>
      by 
        erw [←f.map_rel_iff, f.1.apply_symm_apply, f.1.apply_symm_apply]⟩

/-- See Note [custom simps projection]. We need to specify this projection explicitly in this case,
  because it is a composition of multiple projections. -/
def simps.apply (h : r ≃r s) : α → β :=
  h

/-- See Note [custom simps projection]. -/
def simps.symm_apply (h : r ≃r s) : β → α :=
  h.symm

initialize_simps_projections RelIso (to_equiv_to_fun → apply, to_equiv_inv_fun → symmApply, -toEquiv)

/-- Identity map is a relation isomorphism. -/
@[refl, simps apply]
protected def refl (r : α → α → Prop) : r ≃r r :=
  ⟨Equivₓ.refl _, fun a b => Iff.rfl⟩

/-- Composition of two relation isomorphisms is a relation isomorphism. -/
@[trans, simps apply]
protected def trans (f₁ : r ≃r s) (f₂ : s ≃r t) : r ≃r t :=
  ⟨f₁.to_equiv.trans f₂.to_equiv, fun a b => f₂.map_rel_iff.trans f₁.map_rel_iff⟩

instance (r : α → α → Prop) : Inhabited (r ≃r r) :=
  ⟨RelIso.refl _⟩

@[simp]
theorem default_def (r : α → α → Prop) : default (r ≃r r) = RelIso.refl r :=
  rfl

/-- a relation isomorphism is also a relation isomorphism between dual relations. -/
protected def swap (f : r ≃r s) : swap r ≃r swap s :=
  ⟨f.to_equiv, fun _ _ => f.map_rel_iff⟩

@[simp]
theorem coe_fn_symm_mk f o : ((@RelIso.mk _ _ r s f o).symm : β → α) = f.symm :=
  rfl

@[simp]
theorem apply_symm_apply (e : r ≃r s) (x : β) : e (e.symm x) = x :=
  e.to_equiv.apply_symm_apply x

@[simp]
theorem symm_apply_apply (e : r ≃r s) (x : α) : e.symm (e x) = x :=
  e.to_equiv.symm_apply_apply x

theorem rel_symm_apply (e : r ≃r s) {x y} : r x (e.symm y) ↔ s (e x) y :=
  by 
    rw [←e.map_rel_iff, e.apply_symm_apply]

theorem symm_apply_rel (e : r ≃r s) {x y} : r (e.symm x) y ↔ s x (e y) :=
  by 
    rw [←e.map_rel_iff, e.apply_symm_apply]

protected theorem bijective (e : r ≃r s) : bijective e :=
  e.to_equiv.bijective

protected theorem injective (e : r ≃r s) : injective e :=
  e.to_equiv.injective

protected theorem surjective (e : r ≃r s) : surjective e :=
  e.to_equiv.surjective

@[simp]
theorem range_eq (e : r ≃r s) : Set.Range e = Set.Univ :=
  e.surjective.range_eq

@[simp]
theorem eq_iff_eq (f : r ≃r s) {a b} : f a = f b ↔ a = b :=
  f.injective.eq_iff

/-- Any equivalence lifts to a relation isomorphism between `s` and its preimage. -/
protected def preimage (f : α ≃ β) (s : β → β → Prop) : f ⁻¹'o s ≃r s :=
  ⟨f, fun a b => Iff.rfl⟩

/-- A surjective relation embedding is a relation isomorphism. -/
@[simps apply]
noncomputable def of_surjective (f : r ↪r s) (H : surjective f) : r ≃r s :=
  ⟨Equivₓ.ofBijective f ⟨f.injective, H⟩, fun a b => f.map_rel_iff⟩

/--
Given relation isomorphisms `r₁ ≃r s₁` and `r₂ ≃r s₂`, construct a relation isomorphism for the
lexicographic orders on the sum.
-/
def sum_lex_congr {α₁ α₂ β₁ β₂ r₁ r₂ s₁ s₂} (e₁ : @RelIso α₁ β₁ r₁ s₁) (e₂ : @RelIso α₂ β₂ r₂ s₂) :
  Sum.Lex r₁ r₂ ≃r Sum.Lex s₁ s₂ :=
  ⟨Equivₓ.sumCongr e₁.to_equiv e₂.to_equiv,
    fun a b =>
      by 
        cases' e₁ with f hf <;> cases' e₂ with g hg <;> cases a <;> cases b <;> simp [hf, hg]⟩

/--
Given relation isomorphisms `r₁ ≃r s₁` and `r₂ ≃r s₂`, construct a relation isomorphism for the
lexicographic orders on the product.
-/
def prod_lex_congr {α₁ α₂ β₁ β₂ r₁ r₂ s₁ s₂} (e₁ : @RelIso α₁ β₁ r₁ s₁) (e₂ : @RelIso α₂ β₂ r₂ s₂) :
  Prod.Lex r₁ r₂ ≃r Prod.Lex s₁ s₂ :=
  ⟨Equivₓ.prodCongr e₁.to_equiv e₂.to_equiv,
    fun a b =>
      by 
        simp [Prod.lex_def, e₁.map_rel_iff, e₂.map_rel_iff]⟩

instance : Groupₓ (r ≃r r) :=
  { one := RelIso.refl r, mul := fun f₁ f₂ => f₂.trans f₁, inv := RelIso.symm, mul_assoc := fun f₁ f₂ f₃ => rfl,
    one_mul := fun f => ext$ fun _ => rfl, mul_one := fun f => ext$ fun _ => rfl,
    mul_left_inv := fun f => ext f.symm_apply_apply }

@[simp]
theorem coe_one : ⇑(1 : r ≃r r) = id :=
  rfl

@[simp]
theorem coe_mul (e₁ e₂ : r ≃r r) : (⇑e₁*e₂) = e₁ ∘ e₂ :=
  rfl

theorem mul_apply (e₁ e₂ : r ≃r r) (x : α) : (e₁*e₂) x = e₁ (e₂ x) :=
  rfl

@[simp]
theorem inv_apply_self (e : r ≃r r) x : (e⁻¹) (e x) = x :=
  e.symm_apply_apply x

@[simp]
theorem apply_inv_self (e : r ≃r r) x : e ((e⁻¹) x) = x :=
  e.apply_symm_apply x

end RelIso

/-- `subrel r p` is the inherited relation on a subset. -/
def Subrel (r : α → α → Prop) (p : Set α) : p → p → Prop :=
  (coeₓ : p → α) ⁻¹'o r

@[simp]
theorem subrel_val (r : α → α → Prop) (p : Set α) {a b} : Subrel r p a b ↔ r a.1 b.1 :=
  Iff.rfl

namespace Subrel

/-- The relation embedding from the inherited relation on a subset. -/
protected def RelEmbedding (r : α → α → Prop) (p : Set α) : Subrel r p ↪r r :=
  ⟨embedding.subtype _, fun a b => Iff.rfl⟩

@[simp]
theorem rel_embedding_apply (r : α → α → Prop) p a : Subrel.relEmbedding r p a = a.1 :=
  rfl

instance (r : α → α → Prop) [IsWellOrder α r] (p : Set α) : IsWellOrder p (Subrel r p) :=
  RelEmbedding.is_well_order (Subrel.relEmbedding r p)

end Subrel

/-- Restrict the codomain of a relation embedding. -/
def RelEmbedding.codRestrict (p : Set β) (f : r ↪r s) (H : ∀ a, f a ∈ p) : r ↪r Subrel s p :=
  ⟨f.to_embedding.cod_restrict p H, f.map_rel_iff'⟩

@[simp]
theorem RelEmbedding.cod_restrict_apply p (f : r ↪r s) H a : RelEmbedding.codRestrict p f H a = ⟨f a, H a⟩ :=
  rfl

