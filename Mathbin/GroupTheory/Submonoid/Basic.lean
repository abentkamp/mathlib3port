import Mathbin.Data.Set.Lattice 
import Mathbin.Data.SetLike.Basic

/-!
# Submonoids: definition and `complete_lattice` structure

This file defines bundled multiplicative and additive submonoids. We also define
a `complete_lattice` structure on `submonoid`s, define the closure of a set as the minimal submonoid
that includes this set, and prove a few results about extending properties from a dense set (i.e.
a set with `closure s = ⊤`) to the whole monoid, see `submonoid.dense_induction` and
`monoid_hom.of_mdense`.

## Main definitions

* `submonoid M`: the type of bundled submonoids of a monoid `M`; the underlying set is given in
  the `carrier` field of the structure, and should be accessed through coercion as in `(S : set M)`.
* `add_submonoid M` : the type of bundled submonoids of an additive monoid `M`.

For each of the following definitions in the `submonoid` namespace, there is a corresponding
definition in the `add_submonoid` namespace.

* `submonoid.copy` : copy of a submonoid with `carrier` replaced by a set that is equal but possibly
  not definitionally equal to the carrier of the original `submonoid`.
* `submonoid.closure` :  monoid closure of a set, i.e., the least submonoid that includes the set.
* `submonoid.gi` : `closure : set M → submonoid M` and coercion `coe : submonoid M → set M`
  form a `galois_insertion`;
* `monoid_hom.eq_mlocus`: the submonoid of elements `x : M` such that `f x = g x`;
* `monoid_hom.of_mdense`:  if a map `f : M → N` between two monoids satisfies `f 1 = 1` and
  `f (x * y) = f x * f y` for `y` from some dense set `s`, then `f` is a monoid homomorphism.
  E.g., if `f : ℕ → M` satisfies `f 0 = 0` and `f (x + 1) = f x + f 1`, then `f` is an additive
  monoid homomorphism.

## Implementation notes

Submonoid inclusion is denoted `≤` rather than `⊆`, although `∈` is defined as
membership of a submonoid's underlying set.

Note that `submonoid M` does not actually require `monoid M`, instead requiring only the weaker
`mul_one_class M`.

This file is designed to have very few dependencies. In particular, it should not use natural
numbers.

## Tags
submonoid, submonoids
-/


variable {M : Type _} {N : Type _}

variable {A : Type _}

section NonAssoc

variable [MulOneClass M] {s : Set M}

variable [AddZeroClass A] {t : Set A}

/-- A submonoid of a monoid `M` is a subset containing 1 and closed under multiplication. -/
structure Submonoid (M : Type _) [MulOneClass M] where 
  Carrier : Set M 
  one_mem' : (1 : M) ∈ carrier 
  mul_mem' {a b} : a ∈ carrier → b ∈ carrier → (a*b) ∈ carrier

/-- An additive submonoid of an additive monoid `M` is a subset containing 0 and
  closed under addition. -/
structure AddSubmonoid (M : Type _) [AddZeroClass M] where 
  Carrier : Set M 
  zero_mem' : (0 : M) ∈ carrier 
  add_mem' {a b} : a ∈ carrier → b ∈ carrier → (a+b) ∈ carrier

attribute [toAdditive] Submonoid

namespace Submonoid

@[toAdditive]
instance : SetLike (Submonoid M) M :=
  ⟨Submonoid.Carrier,
    fun p q h =>
      by 
        cases p <;> cases q <;> congr⟩

/-- See Note [custom simps projection] -/
@[toAdditive " See Note [custom simps projection]"]
def simps.coe (S : Submonoid M) : Set M :=
  S

initialize_simps_projections Submonoid (Carrier → coe)

initialize_simps_projections AddSubmonoid (Carrier → coe)

@[simp, toAdditive]
theorem mem_carrier {s : Submonoid M} {x : M} : x ∈ s.carrier ↔ x ∈ s :=
  Iff.rfl

@[simp, toAdditive]
theorem mem_mk {s : Set M} {x : M} h_one h_mul : x ∈ mk s h_one h_mul ↔ x ∈ s :=
  Iff.rfl

@[simp, toAdditive]
theorem coe_set_mk {s : Set M} h_one h_mul : (mk s h_one h_mul : Set M) = s :=
  rfl

@[simp, toAdditive]
theorem mk_le_mk {s t : Set M} h_one h_mul h_one' h_mul' : mk s h_one h_mul ≤ mk t h_one' h_mul' ↔ s ⊆ t :=
  Iff.rfl

/-- Two submonoids are equal if they have the same elements. -/
@[ext, toAdditive "Two `add_submonoid`s are equal if they have the same elements."]
theorem ext {S T : Submonoid M} (h : ∀ x, x ∈ S ↔ x ∈ T) : S = T :=
  SetLike.ext h

/-- Copy a submonoid replacing `carrier` with a set that is equal to it. -/
@[toAdditive "Copy an additive submonoid replacing `carrier` with a set that is equal to it."]
protected def copy (S : Submonoid M) (s : Set M) (hs : s = S) : Submonoid M :=
  { Carrier := s, one_mem' := hs.symm ▸ S.one_mem', mul_mem' := hs.symm ▸ S.mul_mem' }

variable {S : Submonoid M}

@[simp, toAdditive]
theorem coe_copy {s : Set M} (hs : s = S) : (S.copy s hs : Set M) = s :=
  rfl

@[toAdditive]
theorem copy_eq {s : Set M} (hs : s = S) : S.copy s hs = S :=
  SetLike.coe_injective hs

variable (S)

/-- A submonoid contains the monoid's 1. -/
@[toAdditive "An `add_submonoid` contains the monoid's 0."]
theorem one_mem : (1 : M) ∈ S :=
  S.one_mem'

/-- A submonoid is closed under multiplication. -/
@[toAdditive "An `add_submonoid` is closed under addition."]
theorem mul_mem {x y : M} : x ∈ S → y ∈ S → (x*y) ∈ S :=
  Submonoid.mul_mem' S

/-- The submonoid `M` of the monoid `M`. -/
@[toAdditive "The additive submonoid `M` of the `add_monoid M`."]
instance : HasTop (Submonoid M) :=
  ⟨{ Carrier := Set.Univ, one_mem' := Set.mem_univ 1, mul_mem' := fun _ _ _ _ => Set.mem_univ _ }⟩

/-- The trivial submonoid `{1}` of an monoid `M`. -/
@[toAdditive "The trivial `add_submonoid` `{0}` of an `add_monoid` `M`."]
instance : HasBot (Submonoid M) :=
  ⟨{ Carrier := {1}, one_mem' := Set.mem_singleton 1,
      mul_mem' :=
        fun a b ha hb =>
          by 
            simp only [Set.mem_singleton_iff] at *
            rw [ha, hb, mul_oneₓ] }⟩

@[toAdditive]
instance : Inhabited (Submonoid M) :=
  ⟨⊥⟩

@[simp, toAdditive]
theorem mem_bot {x : M} : x ∈ (⊥ : Submonoid M) ↔ x = 1 :=
  Set.mem_singleton_iff

@[simp, toAdditive]
theorem mem_top (x : M) : x ∈ (⊤ : Submonoid M) :=
  Set.mem_univ x

@[simp, toAdditive]
theorem coe_top : ((⊤ : Submonoid M) : Set M) = Set.Univ :=
  rfl

@[simp, toAdditive]
theorem coe_bot : ((⊥ : Submonoid M) : Set M) = {1} :=
  rfl

/-- The inf of two submonoids is their intersection. -/
@[toAdditive "The inf of two `add_submonoid`s is their intersection."]
instance : HasInf (Submonoid M) :=
  ⟨fun S₁ S₂ =>
      { Carrier := S₁ ∩ S₂, one_mem' := ⟨S₁.one_mem, S₂.one_mem⟩,
        mul_mem' := fun _ _ ⟨hx, hx'⟩ ⟨hy, hy'⟩ => ⟨S₁.mul_mem hx hy, S₂.mul_mem hx' hy'⟩ }⟩

@[simp, toAdditive]
theorem coe_inf (p p' : Submonoid M) : ((p⊓p' : Submonoid M) : Set M) = p ∩ p' :=
  rfl

@[simp, toAdditive]
theorem mem_inf {p p' : Submonoid M} {x : M} : x ∈ p⊓p' ↔ x ∈ p ∧ x ∈ p' :=
  Iff.rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (t «expr ∈ » s)
@[toAdditive]
instance : HasInfₓ (Submonoid M) :=
  ⟨fun s =>
      { Carrier := ⋂ (t : _)(_ : t ∈ s), ↑t, one_mem' := Set.mem_bInter$ fun i h => i.one_mem,
        mul_mem' :=
          fun x y hx hy =>
            Set.mem_bInter$
              fun i h =>
                i.mul_mem
                  (by 
                    apply Set.mem_bInter_iff.1 hx i h)
                  (by 
                    apply Set.mem_bInter_iff.1 hy i h) }⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
@[simp, normCast, toAdditive]
theorem coe_Inf (S : Set (Submonoid M)) : ((Inf S : Submonoid M) : Set M) = ⋂ (s : _)(_ : s ∈ S), ↑s :=
  rfl

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p «expr ∈ » S)
@[toAdditive]
theorem mem_Inf {S : Set (Submonoid M)} {x : M} : x ∈ Inf S ↔ ∀ p _ : p ∈ S, x ∈ p :=
  Set.mem_bInter_iff

@[toAdditive]
theorem mem_infi {ι : Sort _} {S : ι → Submonoid M} {x : M} : (x ∈ ⨅ i, S i) ↔ ∀ i, x ∈ S i :=
  by 
    simp only [infi, mem_Inf, Set.forall_range_iff]

@[simp, normCast, toAdditive]
theorem coe_infi {ι : Sort _} {S : ι → Submonoid M} : (↑⨅ i, S i : Set M) = ⋂ i, S i :=
  by 
    simp only [infi, coe_Inf, Set.bInter_range]

/-- Submonoids of a monoid form a complete lattice. -/
@[toAdditive "The `add_submonoid`s of an `add_monoid` form a complete lattice."]
instance : CompleteLattice (Submonoid M) :=
  { completeLatticeOfInf (Submonoid M)$
      fun s => IsGlb.of_image (fun S T => show (S : Set M) ≤ T ↔ S ≤ T from SetLike.coe_subset_coe) is_glb_binfi with
    le := · ≤ ·, lt := · < ·, bot := ⊥, bot_le := fun S x hx => (mem_bot.1 hx).symm ▸ S.one_mem, top := ⊤,
    le_top := fun S x hx => mem_top x, inf := ·⊓·, inf := HasInfₓ.inf, le_inf := fun a b c ha hb x hx => ⟨ha hx, hb hx⟩,
    inf_le_left := fun a b x => And.left, inf_le_right := fun a b x => And.right }

@[simp, toAdditive]
theorem subsingleton_iff : Subsingleton (Submonoid M) ↔ Subsingleton M :=
  ⟨fun h =>
      by 
        exact
          ⟨fun x y =>
              have  : ∀ i : M, i = 1 := fun i => mem_bot.mp$ Subsingleton.elimₓ (⊤ : Submonoid M) ⊥ ▸ mem_top i
              (this x).trans (this y).symm⟩,
    fun h =>
      by 
        exact
          ⟨fun x y =>
              Submonoid.ext$
                fun i =>
                  Subsingleton.elimₓ 1 i ▸
                    by 
                      simp [Submonoid.one_mem]⟩⟩

@[simp, toAdditive]
theorem nontrivial_iff : Nontrivial (Submonoid M) ↔ Nontrivial M :=
  not_iff_not.mp ((not_nontrivial_iff_subsingleton.trans subsingleton_iff).trans not_nontrivial_iff_subsingleton.symm)

@[toAdditive]
instance [Subsingleton M] : Unique (Submonoid M) :=
  ⟨⟨⊥⟩, fun a => @Subsingleton.elimₓ _ (subsingleton_iff.mpr ‹_›) a _⟩

@[toAdditive]
instance [Nontrivial M] : Nontrivial (Submonoid M) :=
  nontrivial_iff.mpr ‹_›

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The `submonoid` generated by a set. -/ @[ toAdditive "The `add_submonoid` generated by a set" ]
  def closure ( s : Set M ) : Submonoid M := Inf { S | s ⊆ S }

@[toAdditive]
theorem mem_closure {x : M} : x ∈ closure s ↔ ∀ S : Submonoid M, s ⊆ S → x ∈ S :=
  mem_Inf

/-- The submonoid generated by a set includes the set. -/
@[simp, toAdditive "The `add_submonoid` generated by a set includes the set."]
theorem subset_closure : s ⊆ closure s :=
  fun x hx => mem_closure.2$ fun S hS => hS hx

@[toAdditive]
theorem not_mem_of_not_mem_closure {P : M} (hP : P ∉ closure s) : P ∉ s :=
  fun h => hP (subset_closure h)

variable {S}

open Set

/-- A submonoid `S` includes `closure s` if and only if it includes `s`. -/
@[simp, toAdditive "An additive submonoid `S` includes `closure s` if and only if it includes `s`"]
theorem closure_le : closure s ≤ S ↔ s ⊆ S :=
  ⟨subset.trans subset_closure, fun h => Inf_le h⟩

/-- Submonoid closure of a set is monotone in its argument: if `s ⊆ t`,
then `closure s ≤ closure t`. -/
@[toAdditive
      "Additive submonoid closure of a set is monotone in its argument: if `s ⊆ t`,\nthen `closure s ≤ closure t`"]
theorem closure_mono ⦃s t : Set M⦄ (h : s ⊆ t) : closure s ≤ closure t :=
  closure_le.2$ subset.trans h subset_closure

@[toAdditive]
theorem closure_eq_of_le (h₁ : s ⊆ S) (h₂ : S ≤ closure s) : closure s = S :=
  le_antisymmₓ (closure_le.2 h₁) h₂

variable (S)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
/-- An induction principle for closure membership. If `p` holds for `1` and all elements of `s`, and
is preserved under multiplication, then `p` holds for all elements of the closure of `s`. -/
@[elab_as_eliminator,
  toAdditive
      "An induction principle for additive closure membership. If `p`\nholds for `0` and all elements of `s`, and is preserved under addition, then `p` holds for all\nelements of the additive closure of `s`."]
theorem closure_induction {p : M → Prop} {x} (h : x ∈ closure s) (Hs : ∀ x _ : x ∈ s, p x) (H1 : p 1)
  (Hmul : ∀ x y, p x → p y → p (x*y)) : p x :=
  (@closure_le _ _ _ ⟨p, H1, Hmul⟩).2 Hs h

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » closure s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
/-- If `s` is a dense set in a monoid `M`, `submonoid.closure s = ⊤`, then in order to prove that
some predicate `p` holds for all `x : M` it suffices to verify `p x` for `x ∈ s`, verify `p 1`,
and verify that `p x` and `p y` imply `p (x * y)`. -/
@[elab_as_eliminator,
  toAdditive
      "If `s` is a dense set in an additive monoid `M`,\n`add_submonoid.closure s = ⊤`, then in order to prove that some predicate `p` holds for all `x : M`\nit suffices to verify `p x` for `x ∈ s`, verify `p 0`, and verify that `p x` and `p y` imply\n`p (x + y)`."]
theorem dense_induction {p : M → Prop} (x : M) {s : Set M} (hs : closure s = ⊤) (Hs : ∀ x _ : x ∈ s, p x) (H1 : p 1)
  (Hmul : ∀ x y, p x → p y → p (x*y)) : p x :=
  have  : ∀ x _ : x ∈ closure s, p x := fun x hx => closure_induction hx Hs H1 Hmul 
  by 
    simpa [hs] using this x

variable (M)

/-- `closure` forms a Galois insertion with the coercion to set. -/
@[toAdditive "`closure` forms a Galois insertion with the coercion to set."]
protected def gi : GaloisInsertion (@closure M _) coeₓ :=
  { choice := fun s _ => closure s, gc := fun s t => closure_le, le_l_u := fun s => subset_closure,
    choice_eq := fun s h => rfl }

variable {M}

/-- Closure of a submonoid `S` equals `S`. -/
@[simp, toAdditive "Additive closure of an additive submonoid `S` equals `S`"]
theorem closure_eq : closure (S : Set M) = S :=
  (Submonoid.gi M).l_u_eq S

@[simp, toAdditive]
theorem closure_empty : closure (∅ : Set M) = ⊥ :=
  (Submonoid.gi M).gc.l_bot

@[simp, toAdditive]
theorem closure_univ : closure (univ : Set M) = ⊤ :=
  @coe_top M _ ▸ closure_eq ⊤

@[toAdditive]
theorem closure_union (s t : Set M) : closure (s ∪ t) = closure s⊔closure t :=
  (Submonoid.gi M).gc.l_sup

@[toAdditive]
theorem closure_Union {ι} (s : ι → Set M) : closure (⋃ i, s i) = ⨆ i, closure (s i) :=
  (Submonoid.gi M).gc.l_supr

end Submonoid

namespace MonoidHom

variable [MulOneClass N]

open Submonoid

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- The submonoid of elements `x : M` such that `f x = g x` -/
    @[ toAdditive "The additive submonoid of elements `x : M` such that `f x = g x`" ]
  def
    eq_mlocus
    ( f g : M →* N ) : Submonoid M
    :=
      {
        Carrier := { x | f x = g x } ,
          one_mem' := by rw [ Set.mem_set_of_eq , f.map_one , g.map_one ] ,
          mul_mem' := fun x y hx : _ = _ hy : _ = _ => by simp
        }

/-- If two monoid homomorphisms are equal on a set, then they are equal on its submonoid closure. -/
@[toAdditive]
theorem eq_on_mclosure {f g : M →* N} {s : Set M} (h : Set.EqOn f g s) : Set.EqOn f g (closure s) :=
  show closure s ≤ f.eq_mlocus g from closure_le.2 h

@[toAdditive]
theorem eq_of_eq_on_mtop {f g : M →* N} (h : Set.EqOn f g (⊤ : Submonoid M)) : f = g :=
  ext$ fun x => h trivialₓ

@[toAdditive]
theorem eq_of_eq_on_mdense {s : Set M} (hs : closure s = ⊤) {f g : M →* N} (h : s.eq_on f g) : f = g :=
  eq_of_eq_on_mtop$ hs ▸ eq_on_mclosure h

end MonoidHom

end NonAssoc

section Assoc

variable [Monoidₓ M] [Monoidₓ N] {s : Set M}

section IsUnit

/-- The submonoid consisting of the units of a monoid -/
@[toAdditive "The additive submonoid  consisting of the add units of an additive monoid"]
def IsUnit.submonoid (M : Type _) [Monoidₓ M] : Submonoid M :=
  { Carrier := SetOf IsUnit,
    one_mem' :=
      by 
        simp only [is_unit_one, Set.mem_set_of_eq],
    mul_mem' :=
      by 
        intro a b ha hb 
        rw [Set.mem_set_of_eq] at *
        exact IsUnit.mul ha hb }

@[toAdditive]
theorem IsUnit.mem_submonoid_iff {M : Type _} [Monoidₓ M] (a : M) : a ∈ IsUnit.submonoid M ↔ IsUnit a :=
  by 
    change a ∈ SetOf IsUnit ↔ IsUnit a 
    rw [Set.mem_set_of_eq]

end IsUnit

namespace MonoidHom

open Submonoid

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » s)
/-- Let `s` be a subset of a monoid `M` such that the closure of `s` is the whole monoid.
Then `monoid_hom.of_mdense` defines a monoid homomorphism from `M` asking for a proof
of `f (x * y) = f x * f y` only for `y ∈ s`. -/
@[toAdditive]
def of_mdense {M N} [Monoidₓ M] [Monoidₓ N] {s : Set M} (f : M → N) (hs : closure s = ⊤) (h1 : f 1 = 1)
  (hmul : ∀ x y _ : y ∈ s, f (x*y) = f x*f y) : M →* N :=
  { toFun := f, map_one' := h1,
    map_mul' :=
      fun x y =>
        dense_induction y hs (fun y hy x => hmul x y hy)
          (by 
            simp [h1])
          (fun y₁ y₂ h₁ h₂ x =>
            by 
              simp only [←mul_assocₓ, h₁, h₂])
          x }

/-- Let `s` be a subset of an additive monoid `M` such that the closure of `s` is the whole monoid.
Then `add_monoid_hom.of_mdense` defines an additive monoid homomorphism from `M` asking for a proof
of `f (x + y) = f x + f y` only for `y ∈ s`. -/
add_decl_doc AddMonoidHom.ofMdense

@[simp, normCast, toAdditive]
theorem coe_of_mdense (f : M → N) (hs : closure s = ⊤) h1 hmul : ⇑of_mdense f hs h1 hmul = f :=
  rfl

end MonoidHom

end Assoc

