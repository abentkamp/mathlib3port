import Mathbin.Data.Pfunctor.Multivariate.Basic

/-!
# Multivariate quotients of polynomial functors.

Basic definition of multivariate QPF. QPFs form a compositional framework
for defining inductive and coinductive types, their quotients and nesting.

The idea is based on building ever larger functors. For instance, we can define
a list using a shape functor:

```lean
inductive list_shape (a b : Type)
| nil : list_shape
| cons : a -> b -> list_shape
```

This shape can itself be decomposed as a sum of product which are themselves
QPFs. It follows that the shape is a QPF and we can take its fixed point
and create the list itself:

```lean
def list (a : Type) := fix list_shape a -- not the actual notation
```

We can continue and define the quotient on permutation of lists and create
the multiset type:

```lean
def multiset (a : Type) := qpf.quot list.perm list a -- not the actual notion
```

And `multiset` is also a QPF. We can then create a novel data type (for Lean):

```lean
inductive tree (a : Type)
| node : a -> multiset tree -> tree
```

An unordered tree. This is currently not supported by Lean because it nests
an inductive type inside of a quotient. We can go further and define
unordered, possibly infinite trees:

```lean
coinductive tree' (a : Type)
| node : a -> multiset tree' -> tree'
```

by using the `cofix` construct. Those options can all be mixed and
matched because they preserve the properties of QPF. The latter example,
`tree'`, combines fixed point, co-fixed point and quotients.

## Related modules

 * constructions
   * fix
   * cofix
   * quot
   * comp
   * sigma / pi
   * prj
   * const

each proves that some operations on functors preserves the QPF structure

## Reference

 * [Jeremy Avigad, Mario M. Carneiro and Simon Hudon, *Data Types as Quotients of Polynomial Functors*][avigad-carneiro-hudon2019]
-/


universe u

open_locale Mvfunctor

/--
Multivariate quotients of polynomial functors.
-/
class Mvqpf {n : ℕ} (F : Typevec.{u} n → Type _) [Mvfunctor F] where 
  p : Mvpfunctor.{u} n 
  abs : ∀ {α}, P.obj α → F α 
  repr : ∀ {α}, F α → P.obj α 
  abs_repr : ∀ {α} x : F α, abs (reprₓ x) = x 
  abs_map : ∀ {α β} f : α ⟹ β p : P.obj α, abs (f <$$> p) = f <$$> abs p

namespace Mvqpf

variable {n : ℕ} {F : Typevec.{u} n → Type _} [Mvfunctor F] [q : Mvqpf F]

include q

open mvfunctor(Liftp Liftr)

/-!
### Show that every mvqpf is a lawful mvfunctor.
-/


protected theorem id_map {α : Typevec n} (x : F α) : Typevec.id <$$> x = x :=
  by 
    rw [←abs_repr x]
    cases' reprₓ x with a f 
    rw [←abs_map]
    rfl

@[simp]
theorem comp_map {α β γ : Typevec n} (f : α ⟹ β) (g : β ⟹ γ) (x : F α) : (g ⊚ f) <$$> x = g <$$> f <$$> x :=
  by 
    rw [←abs_repr x]
    cases' reprₓ x with a f 
    rw [←abs_map, ←abs_map, ←abs_map]
    rfl

instance (priority := 100) IsLawfulMvfunctor : IsLawfulMvfunctor F :=
  { id_map := @Mvqpf.id_map n F _ _, comp_map := @comp_map n F _ _ }

theorem liftp_iff {α : Typevec n} (p : ∀ ⦃i⦄, α i → Prop) (x : F α) :
  liftp p x ↔ ∃ a f, x = abs ⟨a, f⟩ ∧ ∀ i j, p (f i j) :=
  by 
    constructor
    ·
      rintro ⟨y, hy⟩
      cases' h : reprₓ y with a f 
      use a, fun i j => (f i j).val 
      constructor
      ·
        rw [←hy, ←abs_repr y, h, ←abs_map]
        rfl 
      intro i j 
      apply (f i j).property 
    rintro ⟨a, f, h₀, h₁⟩
    dsimp  at *
    use abs ⟨a, fun i j => ⟨f i j, h₁ i j⟩⟩
    rw [←abs_map, h₀]
    rfl

theorem liftr_iff {α : Typevec n} (r : ∀ ⦃i⦄, α i → α i → Prop) (x y : F α) :
  liftr r x y ↔ ∃ a f₀ f₁, x = abs ⟨a, f₀⟩ ∧ y = abs ⟨a, f₁⟩ ∧ ∀ i j, r (f₀ i j) (f₁ i j) :=
  by 
    constructor
    ·
      rintro ⟨u, xeq, yeq⟩
      cases' h : reprₓ u with a f 
      use a, fun i j => (f i j).val.fst, fun i j => (f i j).val.snd 
      constructor
      ·
        rw [←xeq, ←abs_repr u, h, ←abs_map]
        rfl 
      constructor
      ·
        rw [←yeq, ←abs_repr u, h, ←abs_map]
        rfl 
      intro i j 
      exact (f i j).property 
    rintro ⟨a, f₀, f₁, xeq, yeq, h⟩
    use abs ⟨a, fun i j => ⟨(f₀ i j, f₁ i j), h i j⟩⟩
    dsimp 
    constructor
    ·
      rw [xeq, ←abs_map]
      rfl 
    rw [yeq, ←abs_map]
    rfl

open Set

open Mvfunctor

theorem mem_supp {α : Typevec n} (x : F α) i (u : α i) : u ∈ supp x i ↔ ∀ a f, abs ⟨a, f⟩ = x → u ∈ f i '' univ :=
  by 
    rw [supp]
    dsimp 
    constructor
    ·
      intro h a f haf 
      have  : liftp (fun i u => u ∈ f i '' univ) x
      ·
        rw [liftp_iff]
        refine' ⟨a, f, haf.symm, _⟩
        intro i u 
        exact mem_image_of_mem _ (mem_univ _)
      exact h this 
    intro h p 
    rw [liftp_iff]
    rintro ⟨a, f, xeq, h'⟩
    rcases h a f xeq.symm with ⟨i, _, hi⟩
    rw [←hi]
    apply h'

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  supp_eq
  { α : Typevec n } { i } ( x : F α ) : supp x i = { u | ∀ a f , abs ⟨ a , f ⟩ = x → u ∈ f i '' univ }
  := by ext <;> apply mem_supp

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (u «expr ∈ » supp x i)
theorem has_good_supp_iff {α : Typevec n} (x : F α) :
  (∀ p, liftp p x ↔ ∀ i u _ : u ∈ supp x i, p i u) ↔
    ∃ a f, abs ⟨a, f⟩ = x ∧ ∀ i a' f', abs ⟨a', f'⟩ = x → f i '' univ ⊆ f' i '' univ :=
  by 
    constructor
    ·
      intro h 
      have  : liftp (supp x) x
      ·
        ·
          rw [h]
          introv 
          exact id 
      rw [liftp_iff] at this 
      rcases this with ⟨a, f, xeq, h'⟩
      refine' ⟨a, f, xeq.symm, _⟩
      intro a' f' h'' 
      rintro hu u ⟨j, h₂, hfi⟩
      have hh : u ∈ supp x a'
      ·
        rw [←hfi] <;> apply h' 
      refine' (mem_supp x _ u).mp hh _ _ hu 
    rintro ⟨a, f, xeq, h⟩ p 
    rw [liftp_iff]
    constructor
    ·
      rintro ⟨a', f', xeq', h'⟩ i u usuppx 
      rcases(mem_supp x _ u).mp (@usuppx) a' f' xeq'.symm with ⟨i, _, f'ieq⟩
      rw [←f'ieq]
      apply h' 
    intro h' 
    refine' ⟨a, f, xeq.symm, _⟩
    intro j y 
    apply h' 
    rw [mem_supp]
    intro a' f' xeq' 
    apply h _ a' f' xeq' 
    apply mem_image_of_mem _ (mem_univ _)

variable (q)

/-- A qpf is said to be uniform if every polynomial functor
representing a single value all have the same range. -/
def is_uniform : Prop :=
  ∀ ⦃α : Typevec n⦄ a a' : q.P.A f : q.P.B a ⟹ α f' : q.P.B a' ⟹ α,
    abs ⟨a, f⟩ = abs ⟨a', f'⟩ → ∀ i, f i '' univ = f' i '' univ

/-- does `abs` preserve `liftp`? -/
def liftp_preservation : Prop :=
  ∀ ⦃α : Typevec n⦄ p : ∀ ⦃i⦄, α i → Prop x : q.P.obj α, liftp p (abs x) ↔ liftp p x

/-- does `abs` preserve `supp`? -/
def supp_preservation : Prop :=
  ∀ ⦃α⦄ x : q.P.obj α, supp (abs x) = supp x

variable (q)

theorem supp_eq_of_is_uniform (h : q.is_uniform) {α : Typevec n} (a : q.P.A) (f : q.P.B a ⟹ α) :
  ∀ i, supp (abs ⟨a, f⟩) i = f i '' univ :=
  by 
    intro 
    ext u 
    rw [mem_supp]
    constructor
    ·
      intro h' 
      apply h' _ _ rfl 
    intro h' a' f' e 
    rw [←h _ _ _ _ e.symm]
    apply h'

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (u «expr ∈ » supp x i)
theorem liftp_iff_of_is_uniform (h : q.is_uniform) {α : Typevec n} (x : F α) (p : ∀ i, α i → Prop) :
  liftp p x ↔ ∀ i u _ : u ∈ supp x i, p i u :=
  by 
    rw [liftp_iff, ←abs_repr x]
    cases' reprₓ x with a f 
    constructor
    ·
      rintro ⟨a', f', abseq, hf⟩ u 
      rw [supp_eq_of_is_uniform h, h _ _ _ _ abseq]
      rintro b ⟨i, _, hi⟩
      rw [←hi]
      apply hf 
    intro h' 
    refine' ⟨a, f, rfl, fun _ i => h' _ _ _⟩
    rw [supp_eq_of_is_uniform h]
    exact ⟨i, mem_univ i, rfl⟩

theorem supp_map (h : q.is_uniform) {α β : Typevec n} (g : α ⟹ β) (x : F α) i : supp (g <$$> x) i = g i '' supp x i :=
  by 
    rw [←abs_repr x]
    cases' reprₓ x with a f 
    rw [←abs_map, Mvpfunctor.map_eq]
    rw [supp_eq_of_is_uniform h, supp_eq_of_is_uniform h, ←image_comp]
    rfl

theorem supp_preservation_iff_uniform : q.supp_preservation ↔ q.is_uniform :=
  by 
    constructor
    ·
      intro h α a a' f f' h' i 
      rw [←Mvpfunctor.supp_eq, ←Mvpfunctor.supp_eq, ←h, h', h]
    ·
      rintro h α ⟨a, f⟩
      ext 
      rwa [supp_eq_of_is_uniform, Mvpfunctor.supp_eq]

-- failed to parenthesize: no declaration of attribute [parenthesizer] found for 'Lean.Meta.solveByElim'
-- failed to format: no declaration of attribute [formatter] found for 'Lean.Meta.solveByElim'
theorem
  supp_preservation_iff_liftp_preservation
  : q.supp_preservation ↔ q.liftp_preservation
  :=
    by
      constructor <;> intro h
        ·
          rintro α p ⟨ a , f ⟩
            have h' := h
            rw [ supp_preservation_iff_uniform ] at h'
            dsimp only [ supp_preservation , supp ] at h
            simp
              only
              [
                liftp_iff_of_is_uniform
                  ,
                  supp_eq_of_is_uniform
                  ,
                  Mvpfunctor.liftp_iff'
                  ,
                  h'
                  ,
                  image_univ
                  ,
                  mem_range
                  ,
                  exists_imp_distrib
                ]
            constructor <;> intros <;> substVars <;> solveByElim
        · rintro α ⟨ a , f ⟩ simp only [ liftp_preservation ] at h ext simp [ supp , h ]

theorem liftp_preservation_iff_uniform : q.liftp_preservation ↔ q.is_uniform :=
  by 
    rw [←supp_preservation_iff_liftp_preservation, supp_preservation_iff_uniform]

end Mvqpf

