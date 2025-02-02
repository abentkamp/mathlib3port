/-
Copyright (c) 2019 Amelia Livingston. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Amelia Livingston
-/
import Mathbin.Algebra.Group.Prod
import Mathbin.Algebra.Hom.Equiv
import Mathbin.Data.Setoid.Basic
import Mathbin.GroupTheory.Submonoid.Operations

/-!
# Congruence relations

This file defines congruence relations: equivalence relations that preserve a binary operation,
which in this case is multiplication or addition. The principal definition is a `structure`
extending a `setoid` (an equivalence relation), and the inductive definition of the smallest
congruence relation containing a binary relation is also given (see `con_gen`).

The file also proves basic properties of the quotient of a type by a congruence relation, and the
complete lattice of congruence relations on a type. We then establish an order-preserving bijection
between the set of congruence relations containing a congruence relation `c` and the set of
congruence relations on the quotient by `c`.

The second half of the file concerns congruence relations on monoids, in which case the
quotient by the congruence relation is also a monoid. There are results about the universal
property of quotients of monoids, and the isomorphism theorems for monoids.

## Implementation notes

The inductive definition of a congruence relation could be a nested inductive type, defined using
the equivalence closure of a binary relation `eqv_gen`, but the recursor generated does not work.
A nested inductive definition could conceivably shorten proofs, because they would allow invocation
of the corresponding lemmas about `eqv_gen`.

The lemmas `refl`, `symm` and `trans` are not tagged with `@[refl]`, `@[symm]`, and `@[trans]`
respectively as these tags do not work on a structure coerced to a binary relation.

There is a coercion from elements of a type to the element's equivalence class under a
congruence relation.

A congruence relation on a monoid `M` can be thought of as a submonoid of `M × M` for which
membership is an equivalence relation, but whilst this fact is established in the file, it is not
used, since this perspective adds more layers of definitional unfolding.

## Tags

congruence, congruence relation, quotient, quotient by congruence relation, monoid,
quotient monoid, isomorphism theorems
-/


variable (M : Type _) {N : Type _} {P : Type _}

open Function Setoidₓ

/-- A congruence relation on a type with an addition is an equivalence relation which
    preserves addition. -/
structure AddCon [Add M] extends Setoidₓ M where
  add' : ∀ {w x y z}, r w x → r y z → r (w + y) (x + z)

/-- A congruence relation on a type with a multiplication is an equivalence relation which
    preserves multiplication. -/
@[to_additive AddCon]
structure Con [Mul M] extends Setoidₓ M where
  mul' : ∀ {w x y z}, r w x → r y z → r (w * y) (x * z)

-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:51:50: missing argument
-- ./././Mathport/Syntax/Translate/Command.lean:665:43: in add_decl_doc #[[ident add_con.to_setoid]]: ./././Mathport/Syntax/Translate/Tactic/Basic.lean:54:35: expecting parse arg
-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:51:50: missing argument
-- ./././Mathport/Syntax/Translate/Command.lean:665:43: in add_decl_doc #[[ident con.to_setoid]]: ./././Mathport/Syntax/Translate/Tactic/Basic.lean:54:35: expecting parse arg
variable {M}

/-- The inductively defined smallest additive congruence relation containing a given binary
    relation. -/
inductive AddConGen.Rel [Add M] (r : M → M → Prop) : M → M → Prop
  | of : ∀ x y, r x y → AddConGen.Rel x y
  | refl : ∀ x, AddConGen.Rel x x
  | symm : ∀ x y, AddConGen.Rel x y → AddConGen.Rel y x
  | trans : ∀ x y z, AddConGen.Rel x y → AddConGen.Rel y z → AddConGen.Rel x z
  | add : ∀ w x y z, AddConGen.Rel w x → AddConGen.Rel y z → AddConGen.Rel (w + y) (x + z)

/-- The inductively defined smallest multiplicative congruence relation containing a given binary
    relation. -/
@[to_additive AddConGen.Rel]
inductive ConGen.Rel [Mul M] (r : M → M → Prop) : M → M → Prop
  | of : ∀ x y, r x y → ConGen.Rel x y
  | refl : ∀ x, ConGen.Rel x x
  | symm : ∀ x y, ConGen.Rel x y → ConGen.Rel y x
  | trans : ∀ x y z, ConGen.Rel x y → ConGen.Rel y z → ConGen.Rel x z
  | mul : ∀ w x y z, ConGen.Rel w x → ConGen.Rel y z → ConGen.Rel (w * y) (x * z)

/-- The inductively defined smallest multiplicative congruence relation containing a given binary
    relation. -/
@[to_additive addConGen
      "The inductively defined smallest additive congruence relation containing\na given binary relation."]
def conGen [Mul M] (r : M → M → Prop) : Con M :=
  ⟨⟨ConGen.Rel r, ⟨ConGen.Rel.refl, ConGen.Rel.symm, ConGen.Rel.trans⟩⟩, ConGen.Rel.mul⟩

namespace Con

section

variable [Mul M] [Mul N] [Mul P] (c : Con M)

@[to_additive]
instance : Inhabited (Con M) :=
  ⟨conGen EmptyRelation⟩

/-- A coercion from a congruence relation to its underlying binary relation. -/
@[to_additive "A coercion from an additive congruence relation to its underlying binary relation."]
instance : CoeFun (Con M) fun _ => M → M → Prop :=
  ⟨fun c => fun x y => @Setoidₓ.R _ c.toSetoid x y⟩

@[simp, to_additive]
theorem rel_eq_coe (c : Con M) : c.R = c :=
  rfl

/-- Congruence relations are reflexive. -/
@[to_additive "Additive congruence relations are reflexive."]
protected theorem refl (x) : c x x :=
  c.toSetoid.refl' x

/-- Congruence relations are symmetric. -/
@[to_additive "Additive congruence relations are symmetric."]
protected theorem symm : ∀ {x y}, c x y → c y x := fun _ _ h => c.toSetoid.symm' h

/-- Congruence relations are transitive. -/
@[to_additive "Additive congruence relations are transitive."]
protected theorem trans : ∀ {x y z}, c x y → c y z → c x z := fun _ _ _ h => c.toSetoid.trans' h

/-- Multiplicative congruence relations preserve multiplication. -/
@[to_additive "Additive congruence relations preserve addition."]
protected theorem mul : ∀ {w x y z}, c w x → c y z → c (w * y) (x * z) := fun _ _ _ _ h1 h2 => c.mul' h1 h2

@[simp, to_additive]
theorem rel_mk {s : Setoidₓ M} {h a b} : Con.mk s h a b ↔ R a b :=
  Iff.rfl

/-- Given a type `M` with a multiplication, a congruence relation `c` on `M`, and elements of `M`
    `x, y`, `(x, y) ∈ M × M` iff `x` is related to `y` by `c`. -/
@[to_additive
      "Given a type `M` with an addition, `x, y ∈ M`, and an additive congruence relation\n`c` on `M`, `(x, y) ∈ M × M` iff `x` is related to `y` by `c`."]
instance : Membership (M × M) (Con M) :=
  ⟨fun x c => c x.1 x.2⟩

variable {c}

/-- The map sending a congruence relation to its underlying binary relation is injective. -/
@[to_additive "The map sending an additive congruence relation to its underlying binary relation\nis injective."]
theorem ext' {c d : Con M} (H : c.R = d.R) : c = d := by
  rcases c with ⟨⟨⟩⟩
  rcases d with ⟨⟨⟩⟩
  cases H
  congr

/-- Extensionality rule for congruence relations. -/
@[ext, to_additive "Extensionality rule for additive congruence relations."]
theorem ext {c d : Con M} (H : ∀ x y, c x y ↔ d x y) : c = d :=
  ext' <| by
    ext <;> apply H

/-- The map sending a congruence relation to its underlying equivalence relation is injective. -/
@[to_additive "The map sending an additive congruence relation to its underlying equivalence\nrelation is injective."]
theorem to_setoid_inj {c d : Con M} (H : c.toSetoid = d.toSetoid) : c = d :=
  ext <| ext_iff.1 H

/-- Iff version of extensionality rule for congruence relations. -/
@[to_additive "Iff version of extensionality rule for additive congruence relations."]
theorem ext_iff {c d : Con M} : (∀ x y, c x y ↔ d x y) ↔ c = d :=
  ⟨ext, fun h _ _ => h ▸ Iff.rfl⟩

/-- Two congruence relations are equal iff their underlying binary relations are equal. -/
@[to_additive "Two additive congruence relations are equal iff their underlying binary relations\nare equal."]
theorem ext'_iff {c d : Con M} : c.R = d.R ↔ c = d :=
  ⟨ext', fun h => h ▸ rfl⟩

/-- The kernel of a multiplication-preserving function as a congruence relation. -/
@[to_additive "The kernel of an addition-preserving function as an additive congruence relation."]
def mulKer (f : M → P) (h : ∀ x y, f (x * y) = f x * f y) : Con M where
  toSetoid := Setoidₓ.ker f
  mul' := fun _ _ _ _ h1 h2 => by
    dsimp' [Setoidₓ.ker, on_fun]  at *
    rw [h, h1, h2, h]

/-- Given types with multiplications `M, N`, the product of two congruence relations `c` on `M` and
    `d` on `N`: `(x₁, x₂), (y₁, y₂) ∈ M × N` are related by `c.prod d` iff `x₁` is related to `y₁`
    by `c` and `x₂` is related to `y₂` by `d`. -/
@[to_additive Prod
      "Given types with additions `M, N`, the product of two congruence relations\n`c` on `M` and `d` on `N`: `(x₁, x₂), (y₁, y₂) ∈ M × N` are related by `c.prod d` iff `x₁`\nis related to `y₁` by `c` and `x₂` is related to `y₂` by `d`."]
protected def prod (c : Con M) (d : Con N) : Con (M × N) :=
  { c.toSetoid.Prod d.toSetoid with mul' := fun _ _ _ _ h1 h2 => ⟨c.mul h1.1 h2.1, d.mul h1.2 h2.2⟩ }

/-- The product of an indexed collection of congruence relations. -/
@[to_additive "The product of an indexed collection of additive congruence relations."]
def pi {ι : Type _} {f : ι → Type _} [∀ i, Mul (f i)] (C : ∀ i, Con (f i)) : Con (∀ i, f i) :=
  { (@piSetoid _ _) fun i => (C i).toSetoid with mul' := fun _ _ _ _ h1 h2 i => (C i).mul (h1 i) (h2 i) }

variable (c)

-- Quotients
/-- Defining the quotient by a congruence relation of a type with a multiplication. -/
@[to_additive "Defining the quotient by an additive congruence relation of a type with\nan addition."]
protected def Quotient :=
  Quotientₓ <| c.toSetoid

/-- Coercion from a type with a multiplication to its quotient by a congruence relation.

See Note [use has_coe_t]. -/
@[to_additive "Coercion from a type with an addition to its quotient by an additive congruence\nrelation"]
instance (priority := 0) : CoeTₓ M c.Quotient :=
  ⟨@Quotientₓ.mk _ c.toSetoid⟩

-- Lower the priority since it unifies with any quotient type.
/-- The quotient by a decidable congruence relation has decidable equality. -/
@[to_additive "The quotient by a decidable additive congruence relation has decidable equality."]
instance (priority := 500) [d : ∀ a b, Decidable (c a b)] : DecidableEq c.Quotient :=
  @Quotientₓ.decidableEq M c.toSetoid d

@[simp, to_additive]
theorem quot_mk_eq_coe {M : Type _} [Mul M] (c : Con M) (x : M) : Quot.mk c x = (x : c.Quotient) :=
  rfl

/-- The function on the quotient by a congruence relation `c` induced by a function that is
    constant on `c`'s equivalence classes. -/
@[elabAsElim,
  to_additive
      "The function on the quotient by a congruence relation `c`\ninduced by a function that is constant on `c`'s equivalence classes."]
protected def liftOn {β} {c : Con M} (q : c.Quotient) (f : M → β) (h : ∀ a b, c a b → f a = f b) : β :=
  Quotientₓ.liftOn' q f h

/-- The binary function on the quotient by a congruence relation `c` induced by a binary function
    that is constant on `c`'s equivalence classes. -/
@[elabAsElim,
  to_additive
      "The binary function on the quotient by a congruence relation `c`\ninduced by a binary function that is constant on `c`'s equivalence classes."]
protected def liftOn₂ {β} {c : Con M} (q r : c.Quotient) (f : M → M → β)
    (h : ∀ a₁ a₂ b₁ b₂, c a₁ b₁ → c a₂ b₂ → f a₁ a₂ = f b₁ b₂) : β :=
  Quotientₓ.liftOn₂' q r f h

/-- A version of `quotient.hrec_on₂'` for quotients by `con`. -/
@[to_additive "A version of `quotient.hrec_on₂'` for quotients by `add_con`."]
protected def hrecOn₂ {cM : Con M} {cN : Con N} {φ : cM.Quotient → cN.Quotient → Sort _} (a : cM.Quotient)
    (b : cN.Quotient) (f : ∀ (x : M) (y : N), φ x y) (h : ∀ x y x' y', cM x x' → cN y y' → HEq (f x y) (f x' y')) :
    φ a b :=
  Quotientₓ.hrecOn₂' a b f h

@[simp, to_additive]
theorem hrec_on₂_coe {cM : Con M} {cN : Con N} {φ : cM.Quotient → cN.Quotient → Sort _} (a : M) (b : N)
    (f : ∀ (x : M) (y : N), φ x y) (h : ∀ x y x' y', cM x x' → cN y y' → HEq (f x y) (f x' y')) :
    Con.hrecOn₂ (↑a) (↑b) f h = f a b :=
  rfl

variable {c}

/-- The inductive principle used to prove propositions about the elements of a quotient by a
    congruence relation. -/
@[elabAsElim,
  to_additive
      "The inductive principle used to prove propositions about\nthe elements of a quotient by an additive congruence relation."]
protected theorem induction_on {C : c.Quotient → Prop} (q : c.Quotient) (H : ∀ x : M, C x) : C q :=
  Quotientₓ.induction_on' q H

/-- A version of `con.induction_on` for predicates which take two arguments. -/
@[elabAsElim, to_additive "A version of `add_con.induction_on` for predicates which take\ntwo arguments."]
protected theorem induction_on₂ {d : Con N} {C : c.Quotient → d.Quotient → Prop} (p : c.Quotient) (q : d.Quotient)
    (H : ∀ (x : M) (y : N), C x y) : C p q :=
  Quotientₓ.induction_on₂' p q H

variable (c)

/-- Two elements are related by a congruence relation `c` iff they are represented by the same
    element of the quotient by `c`. -/
@[simp,
  to_additive
      "Two elements are related by an additive congruence relation `c` iff they\nare represented by the same element of the quotient by `c`."]
protected theorem eq {a b : M} : (a : c.Quotient) = b ↔ c a b :=
  Quotientₓ.eq'

/-- The multiplication induced on the quotient by a congruence relation on a type with a
    multiplication. -/
@[to_additive "The addition induced on the quotient by an additive congruence relation on a type\nwith an addition."]
instance hasMul : Mul c.Quotient :=
  ⟨(Quotientₓ.map₂' (· * ·)) fun _ _ h1 _ _ h2 => c.mul h1 h2⟩

/-- The kernel of the quotient map induced by a congruence relation `c` equals `c`. -/
@[simp, to_additive "The kernel of the quotient map induced by an additive congruence relation\n`c` equals `c`."]
theorem mul_ker_mk_eq : (mulKer (coe : M → c.Quotient) fun x y => rfl) = c :=
  ext fun x y => Quotientₓ.eq'

variable {c}

/-- The coercion to the quotient of a congruence relation commutes with multiplication (by
    definition). -/
@[simp,
  to_additive
      "The coercion to the quotient of an additive congruence relation commutes with\naddition (by definition)."]
theorem coe_mul (x y : M) : (↑(x * y) : c.Quotient) = ↑x * ↑y :=
  rfl

/-- Definition of the function on the quotient by a congruence relation `c` induced by a function
    that is constant on `c`'s equivalence classes. -/
@[simp,
  to_additive
      "Definition of the function on the quotient by an additive congruence\nrelation `c` induced by a function that is constant on `c`'s equivalence classes."]
protected theorem lift_on_coe {β} (c : Con M) (f : M → β) (h : ∀ a b, c a b → f a = f b) (x : M) :
    Con.liftOn (x : c.Quotient) f h = f x :=
  rfl

/-- Makes an isomorphism of quotients by two congruence relations, given that the relations are
    equal. -/
@[to_additive
      "Makes an additive isomorphism of quotients by two additive congruence relations,\ngiven that the relations are equal."]
protected def congr {c d : Con M} (h : c = d) : c.Quotient ≃* d.Quotient :=
  { Quotientₓ.congr (Equivₓ.refl M) <| by
      apply ext_iff.2 h with
    map_mul' := fun x y => by
      rcases x with ⟨⟩ <;> rcases y with ⟨⟩ <;> rfl }

-- The complete lattice of congruence relations on a type
/-- For congruence relations `c, d` on a type `M` with a multiplication, `c ≤ d` iff `∀ x y ∈ M`,
    `x` is related to `y` by `d` if `x` is related to `y` by `c`. -/
@[to_additive
      "For additive congruence relations `c, d` on a type `M` with an addition, `c ≤ d` iff\n`∀ x y ∈ M`, `x` is related to `y` by `d` if `x` is related to `y` by `c`."]
instance : LE (Con M) :=
  ⟨fun c d => ∀ ⦃x y⦄, c x y → d x y⟩

/-- Definition of `≤` for congruence relations. -/
@[to_additive "Definition of `≤` for additive congruence relations."]
theorem le_def {c d : Con M} : c ≤ d ↔ ∀ {x y}, c x y → d x y :=
  Iff.rfl

/-- The infimum of a set of congruence relations on a given type with a multiplication. -/
@[to_additive "The infimum of a set of additive congruence relations on a given type with\nan addition."]
instance : HasInfₓ (Con M) :=
  ⟨fun S =>
    ⟨⟨fun x y => ∀ c : Con M, c ∈ S → c x y,
        ⟨fun x c hc => c.refl x, fun _ _ h c hc => c.symm <| h c hc, fun _ _ _ h1 h2 c hc =>
          c.trans (h1 c hc) <| h2 c hc⟩⟩,
      fun _ _ _ _ h1 h2 c hc => c.mul (h1 c hc) <| h2 c hc⟩⟩

/-- The infimum of a set of congruence relations is the same as the infimum of the set's image
    under the map to the underlying equivalence relation. -/
@[to_additive
      "The infimum of a set of additive congruence relations is the same as the infimum of\nthe set's image under the map to the underlying equivalence relation."]
theorem Inf_to_setoid (S : Set (Con M)) : (inf S).toSetoid = inf (to_setoid '' S) :=
  Setoidₓ.ext' fun x y =>
    ⟨fun h r ⟨c, hS, hr⟩ => by
      rw [← hr] <;> exact h c hS, fun h c hS => h c.toSetoid ⟨c, hS, rfl⟩⟩

/-- The infimum of a set of congruence relations is the same as the infimum of the set's image
    under the map to the underlying binary relation. -/
@[to_additive
      "The infimum of a set of additive congruence relations is the same as the infimum\nof the set's image under the map to the underlying binary relation."]
theorem Inf_def (S : Set (Con M)) : ⇑(inf S) = inf (@Set.Image (Con M) (M → M → Prop) coeFn S) := by
  ext
  simp only [Inf_image, infi_apply, infi_Prop_eq]
  rfl

@[to_additive]
instance : PartialOrderₓ (Con M) where
  le := (· ≤ ·)
  lt := fun c d => c ≤ d ∧ ¬d ≤ c
  le_refl := fun c _ _ => id
  le_trans := fun c1 c2 c3 h1 h2 x y h => h2 <| h1 h
  lt_iff_le_not_le := fun _ _ => Iff.rfl
  le_antisymm := fun c d hc hd => ext fun x y => ⟨fun h => hc h, fun h => hd h⟩

/-- The complete lattice of congruence relations on a given type with a multiplication. -/
@[to_additive "The complete lattice of additive congruence relations on a given type with\nan addition."]
instance : CompleteLattice (Con M) :=
  { (completeLatticeOfInf (Con M)) fun s =>
      ⟨fun r hr x y h => (h : ∀ r ∈ s, (r : Con M) x y) r hr, fun r hr x y h r' hr' => hr hr' h⟩ with
    inf := fun c d => ⟨c.toSetoid⊓d.toSetoid, fun _ _ _ _ h1 h2 => ⟨c.mul h1.1 h2.1, d.mul h1.2 h2.2⟩⟩,
    inf_le_left := fun _ _ _ _ h => h.1, inf_le_right := fun _ _ _ _ h => h.2,
    le_inf := fun _ _ _ hb hc _ _ h => ⟨hb h, hc h⟩,
    top :=
      { Setoidₓ.completeLattice.top with
        mul' := by
          tauto },
    le_top := fun _ _ _ h => trivialₓ,
    bot := { Setoidₓ.completeLattice.bot with mul' := fun _ _ _ _ h1 h2 => h1 ▸ h2 ▸ rfl },
    bot_le := fun c x y h => h ▸ c.refl x }

/-- The infimum of two congruence relations equals the infimum of the underlying binary
    operations. -/
@[to_additive
      "The infimum of two additive congruence relations equals the infimum of the\nunderlying binary operations."]
theorem inf_def {c d : Con M} : (c⊓d).R = c.R⊓d.R :=
  rfl

/-- Definition of the infimum of two congruence relations. -/
@[to_additive "Definition of the infimum of two additive congruence relations."]
theorem inf_iff_and {c d : Con M} {x y} : (c⊓d) x y ↔ c x y ∧ d x y :=
  Iff.rfl

/-- The inductively defined smallest congruence relation containing a binary relation `r` equals
    the infimum of the set of congruence relations containing `r`. -/
@[to_additive add_con_gen_eq
      "The inductively defined smallest additive congruence relation\ncontaining a binary relation `r` equals the infimum of the set of additive congruence relations\ncontaining `r`."]
theorem con_gen_eq (r : M → M → Prop) : conGen r = inf { s : Con M | ∀ x y, r x y → s x y } :=
  le_antisymmₓ
    (fun x y H =>
      (ConGen.Rel.rec_on H (fun _ _ h _ hs => hs _ _ h) (Con.refl _) (fun _ _ _ => Con.symm _) fun _ _ _ _ _ =>
          Con.trans _)
        fun w x y z _ _ h1 h2 c hc => c.mul (h1 c hc) <| h2 c hc)
    (Inf_le fun _ _ => ConGen.Rel.of _ _)

/-- The smallest congruence relation containing a binary relation `r` is contained in any
    congruence relation containing `r`. -/
@[to_additive add_con_gen_le
      "The smallest additive congruence relation containing a binary\nrelation `r` is contained in any additive congruence relation containing `r`."]
theorem con_gen_le {r : M → M → Prop} {c : Con M} (h : ∀ x y, r x y → @Setoidₓ.R _ c.toSetoid x y) : conGen r ≤ c := by
  rw [con_gen_eq] <;> exact Inf_le h

/-- Given binary relations `r, s` with `r` contained in `s`, the smallest congruence relation
    containing `s` contains the smallest congruence relation containing `r`. -/
@[to_additive add_con_gen_mono
      "Given binary relations `r, s` with `r` contained in `s`, the\nsmallest additive congruence relation containing `s` contains the smallest additive congruence\nrelation containing `r`."]
theorem con_gen_mono {r s : M → M → Prop} (h : ∀ x y, r x y → s x y) : conGen r ≤ conGen s :=
  con_gen_le fun x y hr => ConGen.Rel.of _ _ <| h x y hr

/-- Congruence relations equal the smallest congruence relation in which they are contained. -/
@[simp,
  to_additive add_con_gen_of_add_con
      "Additive congruence relations equal the smallest\nadditive congruence relation in which they are contained."]
theorem con_gen_of_con (c : Con M) : conGen c = c :=
  le_antisymmₓ
    (by
      rw [con_gen_eq] <;> exact Inf_le fun _ _ => id)
    ConGen.Rel.of

/-- The map sending a binary relation to the smallest congruence relation in which it is
    contained is idempotent. -/
@[simp,
  to_additive add_con_gen_idem
      "The map sending a binary relation to the smallest additive\ncongruence relation in which it is contained is idempotent."]
theorem con_gen_idem (r : M → M → Prop) : conGen (conGen r) = conGen r :=
  con_gen_of_con _

/-- The supremum of congruence relations `c, d` equals the smallest congruence relation containing
    the binary relation '`x` is related to `y` by `c` or `d`'. -/
@[to_additive sup_eq_add_con_gen
      "The supremum of additive congruence relations `c, d` equals the\nsmallest additive congruence relation containing the binary relation '`x` is related to `y`\nby `c` or `d`'."]
theorem sup_eq_con_gen (c d : Con M) : c⊔d = conGen fun x y => c x y ∨ d x y := by
  rw [con_gen_eq]
  apply congr_argₓ Inf
  simp only [le_def, or_imp_distrib, ← forall_and_distrib]

/-- The supremum of two congruence relations equals the smallest congruence relation containing
    the supremum of the underlying binary operations. -/
@[to_additive
      "The supremum of two additive congruence relations equals the smallest additive\ncongruence relation containing the supremum of the underlying binary operations."]
theorem sup_def {c d : Con M} : c⊔d = conGen (c.R⊔d.R) := by
  rw [sup_eq_con_gen] <;> rfl

/-- The supremum of a set of congruence relations `S` equals the smallest congruence relation
    containing the binary relation 'there exists `c ∈ S` such that `x` is related to `y` by
    `c`'. -/
@[to_additive Sup_eq_add_con_gen
      "The supremum of a set of additive congruence relations `S` equals\nthe smallest additive congruence relation containing the binary relation 'there exists `c ∈ S`\nsuch that `x` is related to `y` by `c`'."]
theorem Sup_eq_con_gen (S : Set (Con M)) : sup S = conGen fun x y => ∃ c : Con M, c ∈ S ∧ c x y := by
  rw [con_gen_eq]
  apply congr_argₓ Inf
  ext
  exact ⟨fun h _ _ ⟨r, hr⟩ => h hr.1 hr.2, fun h r hS _ _ hr => h _ _ ⟨r, hS, hr⟩⟩

/-- The supremum of a set of congruence relations is the same as the smallest congruence relation
    containing the supremum of the set's image under the map to the underlying binary relation. -/
@[to_additive
      "The supremum of a set of additive congruence relations is the same as the smallest\nadditive congruence relation containing the supremum of the set's image under the map to the\nunderlying binary relation."]
theorem Sup_def {S : Set (Con M)} : sup S = conGen (sup (@Set.Image (Con M) (M → M → Prop) coeFn S)) := by
  rw [Sup_eq_con_gen, Sup_image]
  congr with x y
  simp only [Sup_image, supr_apply, supr_Prop_eq, exists_prop, rel_eq_coe]

variable (M)

/-- There is a Galois insertion of congruence relations on a type with a multiplication `M` into
    binary relations on `M`. -/
@[to_additive
      "There is a Galois insertion of additive congruence relations on a type with\nan addition `M` into binary relations on `M`."]
protected def gi : @GaloisInsertion (M → M → Prop) (Con M) _ _ conGen coeFn where
  choice := fun r h => conGen r
  gc := fun r c => ⟨fun H _ _ h => H <| ConGen.Rel.of _ _ h, fun H => con_gen_of_con c ▸ con_gen_mono H⟩
  le_l_u := fun x => (con_gen_of_con x).symm ▸ le_reflₓ x
  choice_eq := fun _ _ => rfl

variable {M} (c)

/-- Given a function `f`, the smallest congruence relation containing the binary relation on `f`'s
    image defined by '`x ≈ y` iff the elements of `f⁻¹(x)` are related to the elements of `f⁻¹(y)`
    by a congruence relation `c`.' -/
@[to_additive
      "Given a function `f`, the smallest additive congruence relation containing the\nbinary relation on `f`'s image defined by '`x ≈ y` iff the elements of `f⁻¹(x)` are related to the\nelements of `f⁻¹(y)` by an additive congruence relation `c`.'"]
def mapGen (f : M → N) : Con N :=
  conGen fun x y => ∃ a b, f a = x ∧ f b = y ∧ c a b

/-- Given a surjective multiplicative-preserving function `f` whose kernel is contained in a
    congruence relation `c`, the congruence relation on `f`'s codomain defined by '`x ≈ y` iff the
    elements of `f⁻¹(x)` are related to the elements of `f⁻¹(y)` by `c`.' -/
@[to_additive
      "Given a surjective addition-preserving function `f` whose kernel is contained in\nan additive congruence relation `c`, the additive congruence relation on `f`'s codomain defined\nby '`x ≈ y` iff the elements of `f⁻¹(x)` are related to the elements of `f⁻¹(y)` by `c`.'"]
def mapOfSurjective (f : M → N) (H : ∀ x y, f (x * y) = f x * f y) (h : mulKer f H ≤ c) (hf : Surjective f) : Con N :=
  { c.toSetoid.mapOfSurjective f h hf with
    mul' := fun w x y z ⟨a, b, hw, hx, h1⟩ ⟨p, q, hy, hz, h2⟩ =>
      ⟨a * p, b * q, by
        rw [H, hw, hy], by
        rw [H, hx, hz], c.mul h1 h2⟩ }

/-- A specialization of 'the smallest congruence relation containing a congruence relation `c`
    equals `c`'. -/
@[to_additive
      "A specialization of 'the smallest additive congruence relation containing\nan additive congruence relation `c` equals `c`'."]
theorem map_of_surjective_eq_map_gen {c : Con M} {f : M → N} (H : ∀ x y, f (x * y) = f x * f y) (h : mulKer f H ≤ c)
    (hf : Surjective f) : c.mapGen f = c.mapOfSurjective f H h hf := by
  rw [← con_gen_of_con (c.map_of_surjective f H h hf)] <;> rfl

/-- Given types with multiplications `M, N` and a congruence relation `c` on `N`, a
    multiplication-preserving map `f : M → N` induces a congruence relation on `f`'s domain
    defined by '`x ≈ y` iff `f(x)` is related to `f(y)` by `c`.' -/
@[to_additive
      "Given types with additions `M, N` and an additive congruence relation `c` on `N`,\nan addition-preserving map `f : M → N` induces an additive congruence relation on `f`'s domain\ndefined by '`x ≈ y` iff `f(x)` is related to `f(y)` by `c`.' "]
def comap (f : M → N) (H : ∀ x y, f (x * y) = f x * f y) (c : Con N) : Con M :=
  { c.toSetoid.comap f with
    mul' := fun w x y z h1 h2 =>
      show c (f (w * y)) (f (x * z)) by
        rw [H, H] <;> exact c.mul h1 h2 }

@[simp, to_additive]
theorem comap_rel {f : M → N} (H : ∀ x y, f (x * y) = f x * f y) {c : Con N} {x y : M} :
    comap f H c x y ↔ c (f x) (f y) :=
  Iff.rfl

section

open _Root_.Quotient

/-- Given a congruence relation `c` on a type `M` with a multiplication, the order-preserving
    bijection between the set of congruence relations containing `c` and the congruence relations
    on the quotient of `M` by `c`. -/
@[to_additive
      "Given an additive congruence relation `c` on a type `M` with an addition,\nthe order-preserving bijection between the set of additive congruence relations containing `c` and\nthe additive congruence relations on the quotient of `M` by `c`."]
def correspondence : { d // c ≤ d } ≃o Con c.Quotient where
  toFun := fun d =>
    d.1.mapOfSurjective coe _
        (by
          rw [mul_ker_mk_eq] <;> exact d.2) <|
      @exists_rep _ c.toSetoid
  invFun := fun d =>
    ⟨comap (coe : M → c.Quotient) (fun x y => rfl) d, fun _ _ h =>
      show d _ _ by
        rw [c.eq.2 h] <;> exact d.refl _⟩
  left_inv := fun d =>
    Subtype.ext_iff_val.2 <|
      ext fun _ _ =>
        ⟨fun h =>
          let ⟨a, b, hx, hy, H⟩ := h
          d.1.trans (d.1.symm <| d.2 <| c.Eq.1 hx) <| d.1.trans H <| d.2 <| c.Eq.1 hy,
          fun h => ⟨_, _, rfl, rfl, h⟩⟩
  right_inv := fun d =>
    let Hm : (mulKer (coe : M → c.Quotient) fun x y => rfl) ≤ comap (coe : M → c.Quotient) (fun x y => rfl) d :=
      fun x y h =>
      show d _ _ by
        rw [mul_ker_mk_eq] at h <;> exact c.eq.2 h ▸ d.refl _
    ext fun x y =>
      ⟨fun h =>
        let ⟨a, b, hx, hy, H⟩ := h
        hx ▸ hy ▸ H,
        (Con.induction_on₂ x y) fun w z h => ⟨w, z, rfl, rfl, h⟩⟩
  map_rel_iff' := fun s t =>
    ⟨fun h _ _ hs =>
      let ⟨a, b, hx, hy, ht⟩ := h ⟨_, _, rfl, rfl, hs⟩
      t.1.trans (t.1.symm <| t.2 <| eq_rel.1 hx) <| t.1.trans ht <| t.2 <| eq_rel.1 hy,
      fun h _ _ hs =>
      let ⟨a, b, hx, hy, Hs⟩ := hs
      ⟨a, b, hx, hy, h Hs⟩⟩

end

end

section MulOneClassₓ

variable {M} [MulOneClassₓ M] [MulOneClassₓ N] [MulOneClassₓ P] (c : Con M)

/-- The quotient of a monoid by a congruence relation is a monoid. -/
@[to_additive "The quotient of an `add_monoid` by an additive congruence relation is\nan `add_monoid`."]
instance mulOneClass : MulOneClassₓ c.Quotient where
  one := ((1 : M) : c.Quotient)
  mul := (· * ·)
  mul_one := fun x => (Quotientₓ.induction_on' x) fun _ => congr_argₓ (coe : M → c.Quotient) <| mul_oneₓ _
  one_mul := fun x => (Quotientₓ.induction_on' x) fun _ => congr_argₓ (coe : M → c.Quotient) <| one_mulₓ _

variable {c}

/-- The 1 of the quotient of a monoid by a congruence relation is the equivalence class of the
    monoid's 1. -/
@[simp,
  to_additive
      "The 0 of the quotient of an `add_monoid` by an additive congruence relation\nis the equivalence class of the `add_monoid`'s 0."]
theorem coe_one : ((1 : M) : c.Quotient) = 1 :=
  rfl

variable (M c)

/-- The submonoid of `M × M` defined by a congruence relation on a monoid `M`. -/
@[to_additive "The `add_submonoid` of `M × M` defined by an additive congruence\nrelation on an `add_monoid` `M`."]
protected def submonoid : Submonoid (M × M) where
  Carrier := { x | c x.1 x.2 }
  one_mem' := c.iseqv.1 1
  mul_mem' := fun _ _ => c.mul

variable {M c}

/-- The congruence relation on a monoid `M` from a submonoid of `M × M` for which membership
    is an equivalence relation. -/
@[to_additive
      "The additive congruence relation on an `add_monoid` `M` from\nan `add_submonoid` of `M × M` for which membership is an equivalence relation."]
def ofSubmonoid (N : Submonoid (M × M)) (H : Equivalenceₓ fun x y => (x, y) ∈ N) : Con M where
  R := fun x y => (x, y) ∈ N
  iseqv := H
  mul' := fun _ _ _ _ => N.mul_mem

/-- Coercion from a congruence relation `c` on a monoid `M` to the submonoid of `M × M` whose
    elements are `(x, y)` such that `x` is related to `y` by `c`. -/
@[to_additive
      "Coercion from a congruence relation `c` on an `add_monoid` `M`\nto the `add_submonoid` of `M × M` whose elements are `(x, y)` such that `x`\nis related to `y` by `c`."]
instance toSubmonoid : Coe (Con M) (Submonoid (M × M)) :=
  ⟨fun c => c.Submonoid M⟩

@[to_additive]
theorem mem_coe {c : Con M} {x y} : (x, y) ∈ (↑c : Submonoid (M × M)) ↔ (x, y) ∈ c :=
  Iff.rfl

@[to_additive]
theorem to_submonoid_inj (c d : Con M) (H : (c : Submonoid (M × M)) = d) : c = d :=
  ext fun x y =>
    show (x, y) ∈ (c : Submonoid (M × M)) ↔ (x, y) ∈ ↑d by
      rw [H]

@[to_additive]
theorem le_iff {c d : Con M} : c ≤ d ↔ (c : Submonoid (M × M)) ≤ d :=
  ⟨fun h x H => h H, fun h x y hc => h <| show (x, y) ∈ c from hc⟩

/-- The kernel of a monoid homomorphism as a congruence relation. -/
@[to_additive "The kernel of an `add_monoid` homomorphism as an additive congruence relation."]
def ker (f : M →* P) : Con M :=
  mulKer f f.3

/-- The definition of the congruence relation defined by a monoid homomorphism's kernel. -/
@[simp,
  to_additive "The definition of the additive congruence relation defined by an `add_monoid`\nhomomorphism's kernel."]
theorem ker_rel (f : M →* P) {x y} : ker f x y ↔ f x = f y :=
  Iff.rfl

/-- There exists an element of the quotient of a monoid by a congruence relation (namely 1). -/
@[to_additive "There exists an element of the quotient of an `add_monoid` by a congruence relation\n(namely 0)."]
instance Quotient.inhabited : Inhabited c.Quotient :=
  ⟨((1 : M) : c.Quotient)⟩

variable (c)

/-- The natural homomorphism from a monoid to its quotient by a congruence relation. -/
@[to_additive "The natural homomorphism from an `add_monoid` to its quotient by an additive\ncongruence relation."]
def mk' : M →* c.Quotient :=
  ⟨coe, rfl, fun _ _ => rfl⟩

variable (x y : M)

/-- The kernel of the natural homomorphism from a monoid to its quotient by a congruence
    relation `c` equals `c`. -/
@[simp,
  to_additive
      "The kernel of the natural homomorphism from an `add_monoid` to its quotient by\nan additive congruence relation `c` equals `c`."]
theorem mk'_ker : ker c.mk' = c :=
  ext fun _ _ => c.Eq

variable {c}

/-- The natural homomorphism from a monoid to its quotient by a congruence relation is
    surjective. -/
@[to_additive "The natural homomorphism from an `add_monoid` to its quotient by a congruence\nrelation is surjective."]
theorem mk'_surjective : Surjective c.mk' :=
  Quotientₓ.surjective_quotient_mk'

@[simp, to_additive]
theorem coe_mk' : (c.mk' : M → c.Quotient) = coe :=
  rfl

/-- The elements related to `x ∈ M`, `M` a monoid, by the kernel of a monoid homomorphism are
    those in the preimage of `f(x)` under `f`. -/
@[to_additive
      "The elements related to `x ∈ M`, `M` an `add_monoid`, by the kernel of\nan `add_monoid` homomorphism are those in the preimage of `f(x)` under `f`. "]
theorem ker_apply_eq_preimage {f : M →* P} (x) : (ker f) x = f ⁻¹' {f x} :=
  Set.ext fun x =>
    ⟨fun h => Set.mem_preimage.2 <| Set.mem_singleton_iff.2 h.symm, fun h =>
      (Set.mem_singleton_iff.1 <| Set.mem_preimage.1 h).symm⟩

/-- Given a monoid homomorphism `f : N → M` and a congruence relation `c` on `M`, the congruence
    relation induced on `N` by `f` equals the kernel of `c`'s quotient homomorphism composed with
    `f`. -/
@[to_additive
      "Given an `add_monoid` homomorphism `f : N → M` and an additive congruence relation\n`c` on `M`, the additive congruence relation induced on `N` by `f` equals the kernel of `c`'s\nquotient homomorphism composed with `f`."]
theorem comap_eq {f : N →* M} : comap f f.map_mul c = ker (c.mk'.comp f) :=
  ext fun x y =>
    show c _ _ ↔ c.mk' _ = c.mk' _ by
      rw [← c.eq] <;> rfl

variable (c) (f : M →* P)

/-- The homomorphism on the quotient of a monoid by a congruence relation `c` induced by a
    homomorphism constant on `c`'s equivalence classes. -/
@[to_additive
      "The homomorphism on the quotient of an `add_monoid` by an additive congruence\nrelation `c` induced by a homomorphism constant on `c`'s equivalence classes."]
def lift (H : c ≤ ker f) : c.Quotient →* P where
  toFun := fun x => (Con.liftOn x f) fun _ _ h => H h
  map_one' := by
    rw [← f.map_one] <;> rfl
  map_mul' := fun x y => (Con.induction_on₂ x y) fun m n => f.map_mul m n ▸ rfl

variable {c f}

/-- The diagram describing the universal property for quotients of monoids commutes. -/
@[to_additive "The diagram describing the universal property for quotients of `add_monoid`s\ncommutes."]
theorem lift_mk' (H : c ≤ ker f) (x) : c.lift f H (c.mk' x) = f x :=
  rfl

/-- The diagram describing the universal property for quotients of monoids commutes. -/
@[simp, to_additive "The diagram describing the universal property for quotients of `add_monoid`s\ncommutes."]
theorem lift_coe (H : c ≤ ker f) (x : M) : c.lift f H x = f x :=
  rfl

/-- The diagram describing the universal property for quotients of monoids commutes. -/
@[simp, to_additive "The diagram describing the universal property for quotients of `add_monoid`s\ncommutes."]
theorem lift_comp_mk' (H : c ≤ ker f) : (c.lift f H).comp c.mk' = f := by
  ext <;> rfl

/-- Given a homomorphism `f` from the quotient of a monoid by a congruence relation, `f` equals the
    homomorphism on the quotient induced by `f` composed with the natural map from the monoid to
    the quotient. -/
@[simp,
  to_additive
      "Given a homomorphism `f` from the quotient of an `add_monoid` by an additive\ncongruence relation, `f` equals the homomorphism on the quotient induced by `f` composed with the\nnatural map from the `add_monoid` to the quotient."]
theorem lift_apply_mk' (f : c.Quotient →* P) :
    (c.lift (f.comp c.mk') fun x y h =>
        show f ↑x = f ↑y by
          rw [c.eq.2 h]) =
      f :=
  by
  ext <;> rcases x with ⟨⟩ <;> rfl

/-- Homomorphisms on the quotient of a monoid by a congruence relation are equal if they
    are equal on elements that are coercions from the monoid. -/
@[to_additive
      "Homomorphisms on the quotient of an `add_monoid` by an additive congruence relation\nare equal if they are equal on elements that are coercions from the `add_monoid`."]
theorem lift_funext (f g : c.Quotient →* P) (h : ∀ a : M, f a = g a) : f = g := by
  rw [← lift_apply_mk' f, ← lift_apply_mk' g]
  congr 1
  exact MonoidHom.ext_iff.2 h

/-- The uniqueness part of the universal property for quotients of monoids. -/
@[to_additive "The uniqueness part of the universal property for quotients of `add_monoid`s."]
theorem lift_unique (H : c ≤ ker f) (g : c.Quotient →* P) (Hg : g.comp c.mk' = f) : g = c.lift f H :=
  (lift_funext g (c.lift f H)) fun x => by
    subst f
    rfl

/-- Given a congruence relation `c` on a monoid and a homomorphism `f` constant on `c`'s
    equivalence classes, `f` has the same image as the homomorphism that `f` induces on the
    quotient. -/
@[to_additive
      "Given an additive congruence relation `c` on an `add_monoid` and a homomorphism `f`\nconstant on `c`'s equivalence classes, `f` has the same image as the homomorphism that `f` induces\non the quotient."]
theorem lift_range (H : c ≤ ker f) : (c.lift f H).mrange = f.mrange :=
  Submonoid.ext fun x =>
    ⟨by
      rintro ⟨⟨y⟩, hy⟩ <;> exact ⟨y, hy⟩, fun ⟨y, hy⟩ => ⟨↑y, hy⟩⟩

/-- Surjective monoid homomorphisms constant on a congruence relation `c`'s equivalence classes
    induce a surjective homomorphism on `c`'s quotient. -/
@[to_additive
      "Surjective `add_monoid` homomorphisms constant on an additive congruence\nrelation `c`'s equivalence classes induce a surjective homomorphism on `c`'s quotient."]
theorem lift_surjective_of_surjective (h : c ≤ ker f) (hf : Surjective f) : Surjective (c.lift f h) := fun y =>
  (Exists.elim (hf y)) fun w hw => ⟨w, (lift_mk' h w).symm ▸ hw⟩

variable (c f)

/-- Given a monoid homomorphism `f` from `M` to `P`, the kernel of `f` is the unique congruence
    relation on `M` whose induced map from the quotient of `M` to `P` is injective. -/
@[to_additive
      "Given an `add_monoid` homomorphism `f` from `M` to `P`, the kernel of `f`\nis the unique additive congruence relation on `M` whose induced map from the quotient of `M`\nto `P` is injective."]
theorem ker_eq_lift_of_injective (H : c ≤ ker f) (h : Injective (c.lift f H)) : ker f = c :=
  to_setoid_inj <| ker_eq_lift_of_injective f H h

variable {c}

/-- The homomorphism induced on the quotient of a monoid by the kernel of a monoid homomorphism. -/
@[to_additive
      "The homomorphism induced on the quotient of an `add_monoid` by the kernel\nof an `add_monoid` homomorphism."]
def kerLift : (ker f).Quotient →* P :=
  ((ker f).lift f) fun _ _ => id

variable {f}

/-- The diagram described by the universal property for quotients of monoids, when the congruence
    relation is the kernel of the homomorphism, commutes. -/
@[simp,
  to_additive
      "The diagram described by the universal property for quotients\nof `add_monoid`s, when the additive congruence relation is the kernel of the homomorphism,\ncommutes."]
theorem ker_lift_mk (x : M) : kerLift f x = f x :=
  rfl

/-- Given a monoid homomorphism `f`, the induced homomorphism on the quotient by `f`'s kernel has
    the same image as `f`. -/
@[simp,
  to_additive
      "Given an `add_monoid` homomorphism `f`, the induced homomorphism\non the quotient by `f`'s kernel has the same image as `f`."]
theorem ker_lift_range_eq : (kerLift f).mrange = f.mrange :=
  lift_range fun _ _ => id

/-- A monoid homomorphism `f` induces an injective homomorphism on the quotient by `f`'s kernel. -/
@[to_additive "An `add_monoid` homomorphism `f` induces an injective homomorphism on the quotient\nby `f`'s kernel."]
theorem ker_lift_injective (f : M →* P) : Injective (kerLift f) := fun x y =>
  (Quotientₓ.induction_on₂' x y) fun _ _ => (ker f).Eq.2

/-- Given congruence relations `c, d` on a monoid such that `d` contains `c`, `d`'s quotient
    map induces a homomorphism from the quotient by `c` to the quotient by `d`. -/
@[to_additive
      "Given additive congruence relations `c, d` on an `add_monoid` such that `d`\ncontains `c`, `d`'s quotient map induces a homomorphism from the quotient by `c` to the quotient\nby `d`."]
def map (c d : Con M) (h : c ≤ d) : c.Quotient →* d.Quotient :=
  (c.lift d.mk') fun x y hc => show (ker d.mk') x y from (mk'_ker d).symm ▸ h hc

/-- Given congruence relations `c, d` on a monoid such that `d` contains `c`, the definition of
    the homomorphism from the quotient by `c` to the quotient by `d` induced by `d`'s quotient
    map. -/
@[to_additive
      "Given additive congruence relations `c, d` on an `add_monoid` such that `d`\ncontains `c`, the definition of the homomorphism from the quotient by `c` to the quotient by `d`\ninduced by `d`'s quotient map."]
theorem map_apply {c d : Con M} (h : c ≤ d) (x) : c.map d h x = c.lift d.mk' (fun x y hc => d.Eq.2 <| h hc) x :=
  rfl

variable (c)

/-- The first isomorphism theorem for monoids. -/
@[to_additive "The first isomorphism theorem for `add_monoid`s."]
noncomputable def quotientKerEquivRange (f : M →* P) : (ker f).Quotient ≃* f.mrange :=
  { Equivₓ.ofBijective
        ((@MulEquiv.toMonoidHom (kerLift f).mrange _ _ _ <| MulEquiv.submonoidCongr ker_lift_range_eq).comp
          (kerLift f).mrangeRestrict) <|
      (Equivₓ.bijective _).comp
        ⟨fun x y h =>
          ker_lift_injective f <| by
            rcases x with ⟨⟩ <;> rcases y with ⟨⟩ <;> injections,
          fun ⟨w, z, hz⟩ =>
          ⟨z, by
            rcases hz with ⟨⟩ <;> rcases _x with ⟨⟩ <;> rfl⟩⟩ with
    map_mul' := MonoidHom.map_mul _ }

/-- The first isomorphism theorem for monoids in the case of a homomorphism with right inverse. -/
@[to_additive "The first isomorphism theorem for `add_monoid`s in the case of a homomorphism\nwith right inverse.",
  simps]
def quotientKerEquivOfRightInverse (f : M →* P) (g : P → M) (hf : Function.RightInverse g f) : (ker f).Quotient ≃* P :=
  { kerLift f with toFun := kerLift f, invFun := coe ∘ g,
    left_inv := fun x =>
      ker_lift_injective _
        (by
          rw [Function.comp_app, ker_lift_mk, hf]),
    right_inv := hf }

/-- The first isomorphism theorem for monoids in the case of a surjective homomorphism.

For a `computable` version, see `con.quotient_ker_equiv_of_right_inverse`.
-/
@[to_additive
      "The first isomorphism theorem for `add_monoid`s in the case of a surjective\nhomomorphism.\n\nFor a `computable` version, see `add_con.quotient_ker_equiv_of_right_inverse`.\n"]
noncomputable def quotientKerEquivOfSurjective (f : M →* P) (hf : Surjective f) : (ker f).Quotient ≃* P :=
  quotientKerEquivOfRightInverse _ _ hf.HasRightInverse.some_spec

/-- The second isomorphism theorem for monoids. -/
@[to_additive "The second isomorphism theorem for `add_monoid`s."]
noncomputable def comapQuotientEquiv (f : N →* M) : (comap f f.map_mul c).Quotient ≃* (c.mk'.comp f).mrange :=
  (Con.congr comap_eq).trans <| quotient_ker_equiv_range <| c.mk'.comp f

/-- The third isomorphism theorem for monoids. -/
@[to_additive "The third isomorphism theorem for `add_monoid`s."]
def quotientQuotientEquivQuotient (c d : Con M) (h : c ≤ d) : (ker (c.map d h)).Quotient ≃* d.Quotient :=
  { quotientQuotientEquivQuotient c.toSetoid d.toSetoid h with
    map_mul' := fun x y =>
      (Con.induction_on₂ x y) fun w z =>
        (Con.induction_on₂ w z) fun a b =>
          show _ = d.mk' a * d.mk' b by
            rw [← d.mk'.map_mul] <;> rfl }

end MulOneClassₓ

section Monoids

/-- Multiplicative congruence relations preserve natural powers. -/
@[to_additive AddCon.nsmul "Additive congruence relations preserve natural scaling."]
protected theorem pow {M : Type _} [Monoidₓ M] (c : Con M) : ∀ (n : ℕ) {w x}, c w x → c (w ^ n) (x ^ n)
  | 0, w, x, h => by
    simpa using c.refl _
  | Nat.succ n, w, x, h => by
    simpa [pow_succₓ] using c.mul h (pow n h)

@[to_additive]
instance {M : Type _} [MulOneClassₓ M] (c : Con M) : One c.Quotient where one := ((1 : M) : c.Quotient)

instance _root_.add_con.quotient.has_nsmul {M : Type _} [AddMonoidₓ M] (c : AddCon M) :
    HasSmul ℕ c.Quotient where smul := fun n => (Quotientₓ.map' ((· • ·) n)) fun x y => c.nsmul n

@[to_additive AddCon.Quotient.hasNsmul]
instance {M : Type _} [Monoidₓ M] (c : Con M) :
    Pow c.Quotient ℕ where pow := fun x n => Quotientₓ.map' (fun x => x ^ n) (fun x y => c.pow n) x

/-- The quotient of a semigroup by a congruence relation is a semigroup. -/
@[to_additive "The quotient of an `add_semigroup` by an additive congruence relation is\nan `add_semigroup`."]
instance semigroup {M : Type _} [Semigroupₓ M] (c : Con M) : Semigroupₓ c.Quotient :=
  Function.Surjective.semigroup _ Quotientₓ.surjective_quotient_mk' fun _ _ => rfl

/-- The quotient of a commutative semigroup by a congruence relation is a semigroup. -/
@[to_additive "The quotient of an `add_comm_semigroup` by an additive congruence relation is\nan `add_semigroup`."]
instance commSemigroup {M : Type _} [CommSemigroupₓ M] (c : Con M) : CommSemigroupₓ c.Quotient :=
  Function.Surjective.commSemigroup _ Quotientₓ.surjective_quotient_mk' fun _ _ => rfl

/-- The quotient of a monoid by a congruence relation is a monoid. -/
@[to_additive "The quotient of an `add_monoid` by an additive congruence relation is\nan `add_monoid`."]
instance monoid {M : Type _} [Monoidₓ M] (c : Con M) : Monoidₓ c.Quotient :=
  Function.Surjective.monoid _ Quotientₓ.surjective_quotient_mk' rfl (fun _ _ => rfl) fun _ _ => rfl

/-- The quotient of a `comm_monoid` by a congruence relation is a `comm_monoid`. -/
@[to_additive "The quotient of an `add_comm_monoid` by an additive congruence\nrelation is an `add_comm_monoid`."]
instance commMonoid {M : Type _} [CommMonoidₓ M] (c : Con M) : CommMonoidₓ c.Quotient :=
  Function.Surjective.commMonoid _ Quotientₓ.surjective_quotient_mk' rfl (fun _ _ => rfl) fun _ _ => rfl

end Monoids

section Groups

variable {M} [Groupₓ M] [Groupₓ N] [Groupₓ P] (c : Con M)

/-- Multiplicative congruence relations preserve inversion. -/
@[to_additive "Additive congruence relations preserve negation."]
protected theorem inv : ∀ {w x}, c w x → c w⁻¹ x⁻¹ := fun x y h => by
  simpa using c.symm (c.mul (c.mul (c.refl x⁻¹) h) (c.refl y⁻¹))

/-- Multiplicative congruence relations preserve division. -/
@[to_additive "Additive congruence relations preserve subtraction."]
protected theorem div : ∀ {w x y z}, c w x → c y z → c (w / y) (x / z) := fun w x y z h1 h2 => by
  simpa only [div_eq_mul_inv] using c.mul h1 (c.inv h2)

/-- Multiplicative congruence relations preserve integer powers. -/
@[to_additive AddCon.zsmul "Additive congruence relations preserve integer scaling."]
protected theorem zpow : ∀ (n : ℤ) {w x}, c w x → c (w ^ n) (x ^ n)
  | Int.ofNat n, w, x, h => by
    simpa only [zpow_of_nat] using c.pow _ h
  | -[1 + n], w, x, h => by
    simpa only [zpow_neg_succ_of_nat] using c.inv (c.pow _ h)

/-- The inversion induced on the quotient by a congruence relation on a type with a
    inversion. -/
@[to_additive "The negation induced on the quotient by an additive congruence relation on a type\nwith an negation."]
instance hasInv : Inv c.Quotient :=
  ⟨(Quotientₓ.map' Inv.inv) fun a b => c.inv⟩

/-- The division induced on the quotient by a congruence relation on a type with a
    division. -/
@[to_additive
      "The subtraction induced on the quotient by an additive congruence relation on a type\nwith a subtraction."]
instance hasDiv : Div c.Quotient :=
  ⟨(Quotientₓ.map₂' (· / ·)) fun _ _ h₁ _ _ h₂ => c.div h₁ h₂⟩

/-- The integer scaling induced on the quotient by a congruence relation on a type with a
    subtraction. -/
instance _root_.add_con.quotient.has_zsmul {M : Type _} [AddGroupₓ M] (c : AddCon M) : HasSmul ℤ c.Quotient :=
  ⟨fun z => (Quotientₓ.map' ((· • ·) z)) fun x y => c.zsmul z⟩

/-- The integer power induced on the quotient by a congruence relation on a type with a
    division. -/
@[to_additive AddCon.Quotient.hasZsmul]
instance hasZpow : Pow c.Quotient ℤ :=
  ⟨fun x z => Quotientₓ.map' (fun x => x ^ z) (fun x y h => c.zpow z h) x⟩

/-- The quotient of a group by a congruence relation is a group. -/
@[to_additive "The quotient of an `add_group` by an additive congruence relation is\nan `add_group`."]
instance group : Groupₓ c.Quotient :=
  Function.Surjective.group _ Quotientₓ.surjective_quotient_mk' rfl (fun _ _ => rfl) (fun _ => rfl) (fun _ _ => rfl)
    (fun _ _ => rfl) fun _ _ => rfl

end Groups

section Units

variable {α : Type _} [Monoidₓ M] {c : Con M}

/-- In order to define a function `(con.quotient c)ˣ → α` on the units of `con.quotient c`,
where `c : con M` is a multiplicative congruence on a monoid, it suffices to define a function `f`
that takes elements `x y : M` with proofs of `c (x * y) 1` and `c (y * x) 1`, and returns an element
of `α` provided that `f x y _ _ = f x' y' _ _` whenever `c x x'` and `c y y'`. -/
@[to_additive]
def liftOnUnits (u : Units c.Quotient) (f : ∀ x y : M, c (x * y) 1 → c (y * x) 1 → α)
    (Hf : ∀ x y hxy hyx x' y' hxy' hyx', c x x' → c y y' → f x y hxy hyx = f x' y' hxy' hyx') : α := by
  refine'
    @Con.hrecOn₂ M M _ _ c c (fun x y => x * y = 1 → y * x = 1 → α) (u : c.quotient) (↑u⁻¹ : c.quotient)
      (fun (x y : M) (hxy : (x * y : c.quotient) = 1) (hyx : (y * x : c.quotient) = 1) =>
        f x y (c.eq.1 hxy) (c.eq.1 hyx))
      (fun x y x' y' hx hy => _) u.3 u.4
  ext1
  · rw [c.eq.2 hx, c.eq.2 hy]
    
  rintro Hxy Hxy' -
  ext1
  · rw [c.eq.2 hx, c.eq.2 hy]
    
  rintro Hyx Hyx' -
  exact heq_of_eq (Hf _ _ _ _ _ _ _ _ hx hy)

-- ./././Mathport/Syntax/Translate/Tactic/Basic.lean:51:50: missing argument
-- ./././Mathport/Syntax/Translate/Command.lean:665:43: in add_decl_doc #[[ident add_con.lift_on_add_units]]: ./././Mathport/Syntax/Translate/Tactic/Basic.lean:54:35: expecting parse arg
@[simp, to_additive]
theorem lift_on_units_mk (f : ∀ x y : M, c (x * y) 1 → c (y * x) 1 → α)
    (Hf : ∀ x y hxy hyx x' y' hxy' hyx', c x x' → c y y' → f x y hxy hyx = f x' y' hxy' hyx') (x y : M) (hxy hyx) :
    liftOnUnits ⟨(x : c.Quotient), y, hxy, hyx⟩ f Hf = f x y (c.Eq.1 hxy) (c.Eq.1 hyx) :=
  rfl

@[elabAsElim, to_additive]
theorem induction_on_units {p : Units c.Quotient → Prop} (u : Units c.Quotient)
    (H : ∀ (x y : M) (hxy : c (x * y) 1) (hyx : c (y * x) 1), p ⟨x, y, c.Eq.2 hxy, c.Eq.2 hyx⟩) : p u := by
  rcases u with ⟨⟨x⟩, ⟨y⟩, h₁, h₂⟩
  exact H x y (c.eq.1 h₁) (c.eq.1 h₂)

end Units

end Con

