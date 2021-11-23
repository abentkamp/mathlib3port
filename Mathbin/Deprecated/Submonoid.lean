import Mathbin.GroupTheory.Submonoid.Basic 
import Mathbin.Algebra.BigOperators.Basic 
import Mathbin.Deprecated.Group

/-!
# Unbundled submonoids

This file defines unbundled multiplicative and additive submonoids `is_submonoid` and
`is_add_submonoid`. These are not the preferred way to talk about submonoids and should
not be used for any new projects. The preferred way in mathlib are the bundled
versions `submonoid G` and `add_submonoid G`.

## Main definitions

`is_add_submonoid (S : set G)` : the predicate that `S` is the underlying subset of an additive
submonoid of `G`. The bundled variant `add_subgroup G` should be used in preference to this.

`is_submonoid (S : set G)` : the predicate that `S` is the underlying subset of a submonoid
of `G`. The bundled variant `submonoid G` should be used in preference to this.

## Tags

subgroup, subgroups, is_subgroup

## Tags
submonoid, submonoids, is_submonoid
-/


open_locale BigOperators

variable{M : Type _}[Monoidₓ M]{s : Set M}

variable{A : Type _}[AddMonoidₓ A]{t : Set A}

/-- `s` is an additive submonoid: a set containing 0 and closed under addition.
Note that this structure is deprecated, and the bundled variant `add_submonoid A` should be
preferred. -/
structure IsAddSubmonoid(s : Set A) : Prop where 
  zero_mem : (0 : A) ∈ s 
  add_mem {a b} : a ∈ s → b ∈ s → (a+b) ∈ s

/-- `s` is a submonoid: a set containing 1 and closed under multiplication.
Note that this structure is deprecated, and the bundled variant `submonoid M` should be
preferred. -/
@[toAdditive]
structure IsSubmonoid(s : Set M) : Prop where 
  one_mem : (1 : M) ∈ s 
  mul_mem {a b} : a ∈ s → b ∈ s → (a*b) ∈ s

theorem Additive.is_add_submonoid {s : Set M} : ∀ is : IsSubmonoid s, @IsAddSubmonoid (Additive M) _ s
| ⟨h₁, h₂⟩ => ⟨h₁, @h₂⟩

theorem Additive.is_add_submonoid_iff {s : Set M} : @IsAddSubmonoid (Additive M) _ s ↔ IsSubmonoid s :=
  ⟨fun ⟨h₁, h₂⟩ => ⟨h₁, @h₂⟩, Additive.is_add_submonoid⟩

theorem Multiplicative.is_submonoid {s : Set A} : ∀ is : IsAddSubmonoid s, @IsSubmonoid (Multiplicative A) _ s
| ⟨h₁, h₂⟩ => ⟨h₁, @h₂⟩

theorem Multiplicative.is_submonoid_iff {s : Set A} : @IsSubmonoid (Multiplicative A) _ s ↔ IsAddSubmonoid s :=
  ⟨fun ⟨h₁, h₂⟩ => ⟨h₁, @h₂⟩, Multiplicative.is_submonoid⟩

/-- The intersection of two submonoids of a monoid `M` is a submonoid of `M`. -/
@[toAdditive "The intersection of two `add_submonoid`s of an `add_monoid` `M` is\nan `add_submonoid` of M."]
theorem IsSubmonoid.inter {s₁ s₂ : Set M} (is₁ : IsSubmonoid s₁) (is₂ : IsSubmonoid s₂) : IsSubmonoid (s₁ ∩ s₂) :=
  { one_mem := ⟨is₁.one_mem, is₂.one_mem⟩, mul_mem := fun x y hx hy => ⟨is₁.mul_mem hx.1 hy.1, is₂.mul_mem hx.2 hy.2⟩ }

/-- The intersection of an indexed set of submonoids of a monoid `M` is a submonoid of `M`. -/
@[toAdditive
      "The intersection of an indexed set of `add_submonoid`s of an `add_monoid` `M` is\nan `add_submonoid` of `M`."]
theorem IsSubmonoid.Inter {ι : Sort _} {s : ι → Set M} (h : ∀ y : ι, IsSubmonoid (s y)) : IsSubmonoid (Set.Interₓ s) :=
  { one_mem := Set.mem_Inter.2$ fun y => (h y).one_mem,
    mul_mem :=
      fun x₁ x₂ h₁ h₂ => Set.mem_Inter.2$ fun y => (h y).mul_mem (Set.mem_Inter.1 h₁ y) (Set.mem_Inter.1 h₂ y) }

/-- The union of an indexed, directed, nonempty set of submonoids of a monoid `M` is a submonoid
    of `M`. -/
@[toAdditive
      "The union of an indexed, directed, nonempty set\nof `add_submonoid`s of an `add_monoid` `M` is an `add_submonoid` of `M`. "]
theorem is_submonoid_Union_of_directed {ι : Type _} [hι : Nonempty ι] {s : ι → Set M} (hs : ∀ i, IsSubmonoid (s i))
  (directed : ∀ i j, ∃ k, s i ⊆ s k ∧ s j ⊆ s k) : IsSubmonoid (⋃i, s i) :=
  { one_mem :=
      let ⟨i⟩ := hι 
      Set.mem_Union.2 ⟨i, (hs i).one_mem⟩,
    mul_mem :=
      fun a b ha hb =>
        let ⟨i, hi⟩ := Set.mem_Union.1 ha 
        let ⟨j, hj⟩ := Set.mem_Union.1 hb 
        let ⟨k, hk⟩ := Directed i j 
        Set.mem_Union.2 ⟨k, (hs k).mul_mem (hk.1 hi) (hk.2 hj)⟩ }

section Powers

/-- The set of natural number powers `1, x, x², ...` of an element `x` of a monoid. -/
@[toAdditive Multiples "The set of natural number multiples `0, x, 2x, ...` of an element `x` of an `add_monoid`."]
def Powers (x : M) : Set M :=
  { y | ∃ n : ℕ, x ^ n = y }

/-- 1 is in the set of natural number powers of an element of a monoid. -/
@[toAdditive "0 is in the set of natural number multiples of an element of an `add_monoid`."]
theorem Powers.one_mem {x : M} : (1 : M) ∈ Powers x :=
  ⟨0, pow_zeroₓ _⟩

/-- An element of a monoid is in the set of that element's natural number powers. -/
@[toAdditive "An element of an `add_monoid` is in the set of that element's natural number multiples."]
theorem Powers.self_mem {x : M} : x ∈ Powers x :=
  ⟨1, pow_oneₓ _⟩

/-- The set of natural number powers of an element of a monoid is closed under multiplication. -/
@[toAdditive "The set of natural number multiples of an element of an `add_monoid` is closed under addition."]
theorem Powers.mul_mem {x y z : M} : y ∈ Powers x → z ∈ Powers x → (y*z) ∈ Powers x :=
  fun ⟨n₁, h₁⟩ ⟨n₂, h₂⟩ =>
    ⟨n₁+n₂,
      by 
        simp only [pow_addₓ]⟩

/-- The set of natural number powers of an element of a monoid `M` is a submonoid of `M`. -/
@[toAdditive "The set of natural number multiples of an element of\nan `add_monoid` `M` is an `add_submonoid` of `M`."]
theorem Powers.is_submonoid (x : M) : IsSubmonoid (Powers x) :=
  { one_mem := Powers.one_mem, mul_mem := fun y z => Powers.mul_mem }

/-- A monoid is a submonoid of itself. -/
@[toAdditive "An `add_monoid` is an `add_submonoid` of itself."]
theorem Univ.is_submonoid : IsSubmonoid (@Set.Univ M) :=
  by 
    split  <;> simp 

/-- The preimage of a submonoid under a monoid hom is a submonoid of the domain. -/
@[toAdditive "The preimage of an `add_submonoid` under an `add_monoid` hom is\nan `add_submonoid` of the domain."]
theorem IsSubmonoid.preimage {N : Type _} [Monoidₓ N] {f : M → N} (hf : IsMonoidHom f) {s : Set N}
  (hs : IsSubmonoid s) : IsSubmonoid (f ⁻¹' s) :=
  { one_mem :=
      show f 1 ∈ s by 
        rw [IsMonoidHom.map_one hf] <;> exact hs.one_mem,
    mul_mem :=
      fun a b ha : f a ∈ s hb : f b ∈ s =>
        show f (a*b) ∈ s by 
          rw [IsMonoidHom.map_mul hf] <;> exact hs.mul_mem ha hb }

/-- The image of a submonoid under a monoid hom is a submonoid of the codomain. -/
@[toAdditive "The image of an `add_submonoid` under an `add_monoid`\nhom is an `add_submonoid` of the codomain."]
theorem IsSubmonoid.image {γ : Type _} [Monoidₓ γ] {f : M → γ} (hf : IsMonoidHom f) {s : Set M} (hs : IsSubmonoid s) :
  IsSubmonoid (f '' s) :=
  { one_mem := ⟨1, hs.one_mem, hf.map_one⟩,
    mul_mem :=
      fun a b ⟨x, hx⟩ ⟨y, hy⟩ =>
        ⟨x*y, hs.mul_mem hx.1 hy.1,
          by 
            rw [hf.map_mul, hx.2, hy.2]⟩ }

/-- The image of a monoid hom is a submonoid of the codomain. -/
@[toAdditive "The image of an `add_monoid` hom is an `add_submonoid`\nof the codomain."]
theorem Range.is_submonoid {γ : Type _} [Monoidₓ γ] {f : M → γ} (hf : IsMonoidHom f) : IsSubmonoid (Set.Range f) :=
  by 
    rw [←Set.image_univ]
    exact univ.is_submonoid.image hf

/-- Submonoids are closed under natural powers. -/
@[toAdditive IsAddSubmonoid.smul_mem "An `add_submonoid` is closed under multiplication by naturals."]
theorem IsSubmonoid.pow_mem {a : M} (hs : IsSubmonoid s) (h : a ∈ s) : ∀ {n : ℕ}, a ^ n ∈ s
| 0 =>
  by 
    rw [pow_zeroₓ]
    exact hs.one_mem
| n+1 =>
  by 
    rw [pow_succₓ]
    exact hs.mul_mem h IsSubmonoid.pow_mem

/-- The set of natural number powers of an element of a submonoid is a subset of the submonoid. -/
@[toAdditive IsAddSubmonoid.multiples_subset
      "The set of natural number multiples of an element\nof an `add_submonoid` is a subset of the `add_submonoid`."]
theorem IsSubmonoid.power_subset {a : M} (hs : IsSubmonoid s) (h : a ∈ s) : Powers a ⊆ s :=
  fun x ⟨n, hx⟩ => hx ▸ hs.pow_mem h

end Powers

namespace IsSubmonoid

/-- The product of a list of elements of a submonoid is an element of the submonoid. -/
@[toAdditive "The sum of a list of elements of an `add_submonoid` is an element of the\n`add_submonoid`."]
theorem list_prod_mem (hs : IsSubmonoid s) : ∀ {l : List M}, (∀ x _ : x ∈ l, x ∈ s) → l.prod ∈ s
| [], h => hs.one_mem
| a :: l, h =>
  suffices (a*l.prod) ∈ s by 
    simpa 
  have  : a ∈ s ∧ ∀ x _ : x ∈ l, x ∈ s :=
    by 
      simpa using h 
  hs.mul_mem this.1 (list_prod_mem this.2)

/-- The product of a multiset of elements of a submonoid of a `comm_monoid` is an element of
the submonoid. -/
@[toAdditive
      "The sum of a multiset of elements of an `add_submonoid` of an `add_comm_monoid`\nis an element of the `add_submonoid`. "]
theorem multiset_prod_mem {M} [CommMonoidₓ M] {s : Set M} (hs : IsSubmonoid s) (m : Multiset M) :
  (∀ a _ : a ∈ m, a ∈ s) → m.prod ∈ s :=
  by 
    refine' Quotientₓ.induction_on m fun l hl => _ 
    rw [Multiset.quot_mk_to_coe, Multiset.coe_prod]
    exact list_prod_mem hs hl

/-- The product of elements of a submonoid of a `comm_monoid` indexed by a `finset` is an element
of the submonoid. -/
@[toAdditive
      "The sum of elements of an `add_submonoid` of an `add_comm_monoid` indexed by\na `finset` is an element of the `add_submonoid`."]
theorem finset_prod_mem {M A} [CommMonoidₓ M] {s : Set M} (hs : IsSubmonoid s) (f : A → M) :
  ∀ t : Finset A, (∀ b _ : b ∈ t, f b ∈ s) → (∏b in t, f b) ∈ s
| ⟨m, hm⟩, _ =>
  multiset_prod_mem hs _
    (by 
      simpa)

end IsSubmonoid

namespace AddMonoidₓ

/-- The inductively defined membership predicate for the submonoid generated by a subset of a
    monoid. -/
inductive in_closure (s : Set A) : A → Prop
  | basic {a : A} : a ∈ s → in_closure a
  | zero : in_closure 0
  | add {a b : A} : in_closure a → in_closure b → in_closure (a+b)

end AddMonoidₓ

namespace Monoidₓ

/-- The inductively defined membership predicate for the `submonoid` generated by a subset of an
    monoid. -/
@[toAdditive]
inductive in_closure (s : Set M) : M → Prop
  | basic {a : M} : a ∈ s → in_closure a
  | one : in_closure 1
  | mul {a b : M} : in_closure a → in_closure b → in_closure (a*b)

/-- The inductively defined submonoid generated by a subset of a monoid. -/
@[toAdditive "The inductively defined `add_submonoid` genrated by a subset of an `add_monoid`."]
def closure (s : Set M) : Set M :=
  { a | in_closure s a }

@[toAdditive]
theorem closure.is_submonoid (s : Set M) : IsSubmonoid (closure s) :=
  { one_mem := in_closure.one, mul_mem := fun a b => in_closure.mul }

/-- A subset of a monoid is contained in the submonoid it generates. -/
@[toAdditive "A subset of an `add_monoid` is contained in the `add_submonoid` it generates."]
theorem subset_closure {s : Set M} : s ⊆ closure s :=
  fun a => in_closure.basic

/-- The submonoid generated by a set is contained in any submonoid that contains the set. -/
@[toAdditive "The `add_submonoid` generated by a set is contained in any `add_submonoid` that\ncontains the set."]
theorem closure_subset {s t : Set M} (ht : IsSubmonoid t) (h : s ⊆ t) : closure s ⊆ t :=
  fun a ha =>
    by 
      induction ha <;> simp [h _, IsSubmonoid.one_mem, IsSubmonoid.mul_mem]

/-- Given subsets `t` and `s` of a monoid `M`, if `s ⊆ t`, the submonoid of `M` generated by `s` is
    contained in the submonoid generated by `t`. -/
@[toAdditive
      "Given subsets `t` and `s` of an `add_monoid M`, if `s ⊆ t`, the `add_submonoid`\nof `M` generated by `s` is contained in the `add_submonoid` generated by `t`."]
theorem closure_mono {s t : Set M} (h : s ⊆ t) : closure s ⊆ closure t :=
  closure_subset (closure.is_submonoid t)$ Set.Subset.trans h subset_closure

/-- The submonoid generated by an element of a monoid equals the set of natural number powers of
    the element. -/
@[toAdditive
      "The `add_submonoid` generated by an element of an `add_monoid` equals the set of\nnatural number multiples of the element."]
theorem closure_singleton {x : M} : closure ({x} : Set M) = Powers x :=
  Set.eq_of_subset_of_subset (closure_subset (Powers.is_submonoid x)$ Set.singleton_subset_iff.2$ Powers.self_mem)$
    IsSubmonoid.power_subset (closure.is_submonoid _)$ Set.singleton_subset_iff.1$ subset_closure

-- error in Deprecated.Submonoid: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: no declaration of attribute [parenthesizer] found for 'Lean.Meta.solveByElim'
/-- The image under a monoid hom of the submonoid generated by a set equals the submonoid generated
    by the image of the set under the monoid hom. -/
@[to_additive #[expr "The image under an `add_monoid` hom of the `add_submonoid` generated by a set equals\nthe `add_submonoid` generated by the image of the set under the `add_monoid` hom."]]
theorem image_closure
{A : Type*}
[monoid A]
{f : M → A}
(hf : is_monoid_hom f)
(s : set M) : «expr = »(«expr '' »(f, closure s), closure «expr '' »(f, s)) :=
le_antisymm (begin
   rintros ["_", "⟨", ident x, ",", ident hx, ",", ident rfl, "⟩"],
   apply [expr in_closure.rec_on hx]; intros [],
   { solve_by_elim [] [] ["[", expr subset_closure, ",", expr set.mem_image_of_mem, "]"] [] },
   { rw ["[", expr hf.map_one, "]"] [],
     apply [expr is_submonoid.one_mem (closure.is_submonoid «expr '' »(f, s))] },
   { rw ["[", expr hf.map_mul, "]"] [],
     solve_by_elim [] [] ["[", expr (closure.is_submonoid _).mul_mem, "]"] [] }
 end) «expr $ »(closure_subset (is_submonoid.image hf (closure.is_submonoid _)), set.image_subset _ subset_closure)

/-- Given an element `a` of the submonoid of a monoid `M` generated by a set `s`, there exists
a list of elements of `s` whose product is `a`. -/
@[toAdditive
      "Given an element `a` of the `add_submonoid` of an `add_monoid M` generated by\na set `s`, there exists a list of elements of `s` whose sum is `a`."]
theorem exists_list_of_mem_closure {s : Set M} {a : M} (h : a ∈ closure s) :
  ∃ l : List M, (∀ x _ : x ∈ l, x ∈ s) ∧ l.prod = a :=
  by 
    induction h 
    case in_closure.basic a ha => 
      exists [a]
      simp [ha]
    case in_closure.one => 
      exists []
      simp 
    case in_closure.mul a b _ _ ha hb => 
      rcases ha with ⟨la, ha, eqa⟩
      rcases hb with ⟨lb, hb, eqb⟩
      exists la ++ lb 
      simp [eqa.symm, eqb.symm, or_imp_distrib]
      exact fun a => ⟨ha a, hb a⟩

/-- Given sets `s, t` of a commutative monoid `M`, `x ∈ M` is in the submonoid of `M` generated by
    `s ∪ t` iff there exists an element of the submonoid generated by `s` and an element of the
    submonoid generated by `t` whose product is `x`. -/
@[toAdditive
      "Given sets `s, t` of a commutative `add_monoid M`, `x ∈ M` is in the `add_submonoid`\nof `M` generated by `s ∪ t` iff there exists an element of the `add_submonoid` generated by `s`\nand an element of the `add_submonoid` generated by `t` whose sum is `x`."]
theorem mem_closure_union_iff {M : Type _} [CommMonoidₓ M] {s t : Set M} {x : M} :
  x ∈ closure (s ∪ t) ↔ ∃ (y : _)(_ : y ∈ closure s), ∃ (z : _)(_ : z ∈ closure t), (y*z) = x :=
  ⟨fun hx =>
      let ⟨L, HL1, HL2⟩ := exists_list_of_mem_closure hx 
      HL2 ▸
        List.recOn L (fun _ => ⟨1, (closure.is_submonoid _).one_mem, 1, (closure.is_submonoid _).one_mem, mul_oneₓ _⟩)
          (fun hd tl ih HL1 =>
            let ⟨y, hy, z, hz, hyzx⟩ := ih (List.forall_mem_of_forall_mem_consₓ HL1)
            Or.cases_on (HL1 hd$ List.mem_cons_selfₓ _ _)
              (fun hs =>
                ⟨hd*y, (closure.is_submonoid _).mul_mem (subset_closure hs) hy, z, hz,
                  by 
                    rw [mul_assocₓ, List.prod_cons, ←hyzx] <;> rfl⟩)
              fun ht =>
                ⟨y, hy, z*hd, (closure.is_submonoid _).mul_mem hz (subset_closure ht),
                  by 
                    rw [←mul_assocₓ, List.prod_cons, ←hyzx, mul_commₓ hd] <;> rfl⟩)
          HL1,
    fun ⟨y, hy, z, hz, hyzx⟩ =>
      hyzx ▸
        (closure.is_submonoid _).mul_mem (closure_mono (Set.subset_union_left _ _) hy)
          (closure_mono (Set.subset_union_right _ _) hz)⟩

end Monoidₓ

/-- Create a bundled submonoid from a set `s` and `[is_submonoid s]`. -/
@[toAdditive "Create a bundled additive submonoid from a set `s` and `[is_add_submonoid s]`."]
def Submonoid.of {s : Set M} (h : IsSubmonoid s) : Submonoid M :=
  ⟨s, h.1, h.2⟩

@[toAdditive]
theorem Submonoid.is_submonoid (S : Submonoid M) : IsSubmonoid (S : Set M) :=
  ⟨S.2, S.3⟩

