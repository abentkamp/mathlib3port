/-
Copyright (c) 2018 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Simon Hudon
-/
import Mathbin.Data.Pfunctor.Multivariate.W
import Mathbin.Data.Qpf.Multivariate.Basic

/-!
# The initial algebra of a multivariate qpf is again a qpf.

For a `(n+1)`-ary QPF `F (α₀,..,αₙ)`, we take the least fixed point of `F` with
regards to its last argument `αₙ`. The result is a `n`-ary functor: `fix F (α₀,..,αₙ₋₁)`.
Making `fix F` into a functor allows us to take the fixed point, compose with other functors
and take a fixed point again.

## Main definitions

 * `fix.mk`     - constructor
 * `fix.dest    - destructor
 * `fix.rec`    - recursor: basis for defining functions by structural recursion on `fix F α`
 * `fix.drec`   - dependent recursor: generalization of `fix.rec` where
                  the result type of the function is allowed to depend on the `fix F α` value
 * `fix.rec_eq` - defining equation for `recursor`
 * `fix.ind`    - induction principle for `fix F α`

## Implementation notes

For `F` a QPF`, we define `fix F α` in terms of the W-type of the polynomial functor `P` of `F`.
We define the relation `Wequiv` and take its quotient as the definition of `fix F α`.

```lean
inductive Wequiv {α : typevec n} : q.P.W α → q.P.W α → Prop
| ind (a : q.P.A) (f' : q.P.drop.B a ⟹ α) (f₀ f₁ : q.P.last.B a → q.P.W α) :
    (∀ x, Wequiv (f₀ x) (f₁ x)) → Wequiv (q.P.W_mk a f' f₀) (q.P.W_mk a f' f₁)
| abs (a₀ : q.P.A) (f'₀ : q.P.drop.B a₀ ⟹ α) (f₀ : q.P.last.B a₀ → q.P.W α)
      (a₁ : q.P.A) (f'₁ : q.P.drop.B a₁ ⟹ α) (f₁ : q.P.last.B a₁ → q.P.W α) :
      abs ⟨a₀, q.P.append_contents f'₀ f₀⟩ = abs ⟨a₁, q.P.append_contents f'₁ f₁⟩ →
        Wequiv (q.P.W_mk a₀ f'₀ f₀) (q.P.W_mk a₁ f'₁ f₁)
| trans (u v w : q.P.W α) : Wequiv u v → Wequiv v w → Wequiv u w
```

See [avigad-carneiro-hudon2019] for more details.

## Reference

 * Jeremy Avigad, Mario M. Carneiro and Simon Hudon.
   [*Data Types as Quotients of Polynomial Functors*][avigad-carneiro-hudon2019]
-/


universe u v

namespace Mvqpf

open Typevec

open Mvfunctor (Liftp Liftr)

open Mvfunctor

variable {n : ℕ} {F : Typevec.{u} (n + 1) → Type u} [Mvfunctor F] [q : Mvqpf F]

include q

/-- `recF` is used as a basis for defining the recursor on `fix F α`. `recF`
traverses recursively the W-type generated by `q.P` using a function on `F`
as a recursive step -/
def recF {α : Typevec n} {β : Type _} (g : F (α.Append1 β) → β) : q.p.W α → β :=
  q.p.wRec fun a f' f rec => g (abs ⟨a, splitFun f' rec⟩)

theorem recF_eq {α : Typevec n} {β : Type _} (g : F (α.Append1 β) → β) (a : q.p.A) (f' : q.p.drop.B a ⟹ α)
    (f : q.p.last.B a → q.p.W α) : recF g (q.p.wMk a f' f) = g (abs ⟨a, splitFun f' (recF g ∘ f)⟩) := by
  rw [recF, Mvpfunctor.W_rec_eq] <;> rfl

theorem recF_eq' {α : Typevec n} {β : Type _} (g : F (α.Append1 β) → β) (x : q.p.W α) :
    recF g x = g (abs (appendFun id (recF g) <$$> q.p.wDest' x)) := by
  apply q.P.W_cases _ x
  intro a f' f
  rw [recF_eq, q.P.W_dest'_W_mk, Mvpfunctor.map_eq, append_fun_comp_split_fun, Typevec.id_comp]

/-- Equivalence relation on W-types that represent the same `fix F`
value -/
inductive Wequiv {α : Typevec n} : q.p.W α → q.p.W α → Prop
  | ind (a : q.p.A) (f' : q.p.drop.B a ⟹ α) (f₀ f₁ : q.p.last.B a → q.p.W α) :
    (∀ x, Wequiv (f₀ x) (f₁ x)) → Wequiv (q.p.wMk a f' f₀) (q.p.wMk a f' f₁)
  | abs (a₀ : q.p.A) (f'₀ : q.p.drop.B a₀ ⟹ α) (f₀ : q.p.last.B a₀ → q.p.W α) (a₁ : q.p.A) (f'₁ : q.p.drop.B a₁ ⟹ α)
    (f₁ : q.p.last.B a₁ → q.p.W α) :
    abs ⟨a₀, q.p.appendContents f'₀ f₀⟩ = abs ⟨a₁, q.p.appendContents f'₁ f₁⟩ →
      Wequiv (q.p.wMk a₀ f'₀ f₀) (q.p.wMk a₁ f'₁ f₁)
  | trans (u v w : q.p.W α) : Wequiv u v → Wequiv v w → Wequiv u w

theorem recF_eq_of_Wequiv (α : Typevec n) {β : Type _} (u : F (α.Append1 β) → β) (x y : q.p.W α) :
    Wequiv x y → recF u x = recF u y := by
  apply q.P.W_cases _ x
  intro a₀ f'₀ f₀
  apply q.P.W_cases _ y
  intro a₁ f'₁ f₁
  intro h
  induction h
  case mvqpf.Wequiv.ind a f' f₀ f₁ h ih =>
    simp only [recF_eq, Function.comp, ih]
  case mvqpf.Wequiv.abs a₀ f'₀ f₀ a₁ f'₁ f₁ h =>
    simp only [recF_eq', abs_map, Mvpfunctor.W_dest'_W_mk, h]
  case mvqpf.Wequiv.trans x y z e₁ e₂ ih₁ ih₂ =>
    exact Eq.trans ih₁ ih₂

theorem Wequiv.abs' {α : Typevec n} (x y : q.p.W α) (h : abs (q.p.wDest' x) = abs (q.p.wDest' y)) : Wequiv x y := by
  revert h
  apply q.P.W_cases _ x
  intro a₀ f'₀ f₀
  apply q.P.W_cases _ y
  intro a₁ f'₁ f₁
  apply Wequiv.abs

theorem Wequiv.refl {α : Typevec n} (x : q.p.W α) : Wequiv x x := by
  apply q.P.W_cases _ x <;> intro a f' f <;> exact Wequiv.abs a f' f a f' f rfl

theorem Wequiv.symm {α : Typevec n} (x y : q.p.W α) : Wequiv x y → Wequiv y x := by
  intro h
  induction h
  case mvqpf.Wequiv.ind a f' f₀ f₁ h ih =>
    exact Wequiv.ind _ _ _ _ ih
  case mvqpf.Wequiv.abs a₀ f'₀ f₀ a₁ f'₁ f₁ h =>
    exact Wequiv.abs _ _ _ _ _ _ h.symm
  case mvqpf.Wequiv.trans x y z e₁ e₂ ih₁ ih₂ =>
    exact Mvqpf.Wequiv.trans _ _ _ ih₂ ih₁

/-- maps every element of the W type to a canonical representative -/
def wrepr {α : Typevec n} : q.p.W α → q.p.W α :=
  recF (q.p.wMk' ∘ reprₓ)

theorem Wrepr_W_mk {α : Typevec n} (a : q.p.A) (f' : q.p.drop.B a ⟹ α) (f : q.p.last.B a → q.p.W α) :
    wrepr (q.p.wMk a f' f) = q.p.wMk' (repr (abs (appendFun id wrepr <$$> ⟨a, q.p.appendContents f' f⟩))) := by
  rw [Wrepr, recF_eq', q.P.W_dest'_W_mk] <;> rfl

theorem Wrepr_equiv {α : Typevec n} (x : q.p.W α) : Wequiv (wrepr x) x := by
  apply q.P.W_ind _ x
  intro a f' f ih
  apply Wequiv.trans _ (q.P.W_mk' (append_fun id Wrepr <$$> ⟨a, q.P.append_contents f' f⟩))
  · apply Wequiv.abs'
    rw [Wrepr_W_mk, q.P.W_dest'_W_mk', q.P.W_dest'_W_mk', abs_repr]
    
  rw [q.P.map_eq, Mvpfunctor.wMk', append_fun_comp_split_fun, id_comp]
  apply Wequiv.ind
  exact ih

theorem Wequiv_map {α β : Typevec n} (g : α ⟹ β) (x y : q.p.W α) : Wequiv x y → Wequiv (g <$$> x) (g <$$> y) := by
  intro h
  induction h
  case mvqpf.Wequiv.ind a f' f₀ f₁ h ih =>
    rw [q.P.W_map_W_mk, q.P.W_map_W_mk]
    apply Wequiv.ind
    apply ih
  case mvqpf.Wequiv.abs a₀ f'₀ f₀ a₁ f'₁ f₁ h =>
    rw [q.P.W_map_W_mk, q.P.W_map_W_mk]
    apply Wequiv.abs
    show
      abs (q.P.obj_append1 a₀ (g ⊚ f'₀) fun x => q.P.W_map g (f₀ x)) =
        abs (q.P.obj_append1 a₁ (g ⊚ f'₁) fun x => q.P.W_map g (f₁ x))
    rw [← q.P.map_obj_append1, ← q.P.map_obj_append1, abs_map, abs_map, h]
  case mvqpf.Wequiv.trans x y z e₁ e₂ ih₁ ih₂ =>
    apply Mvqpf.Wequiv.trans
    apply ih₁
    apply ih₂

/-- Define the fixed point as the quotient of trees under the equivalence relation.
-/
def wSetoid (α : Typevec n) : Setoidₓ (q.p.W α) :=
  ⟨Wequiv, @Wequiv.refl _ _ _ _ _, @Wequiv.symm _ _ _ _ _, @Wequiv.trans _ _ _ _ _⟩

attribute [local instance] W_setoid

/-- Least fixed point of functor F. The result is a functor with one fewer parameters
than the input. For `F a b c` a ternary functor, fix F is a binary functor such that

```lean
fix F a b = F a b (fix F a b)
```
-/
def Fix {n : ℕ} (F : Typevec (n + 1) → Type _) [Mvfunctor F] [q : Mvqpf F] (α : Typevec n) :=
  Quotientₓ (wSetoid α : Setoidₓ (q.p.W α))

attribute [nolint has_nonempty_instance] fix

/-- `fix F` is a functor -/
def Fix.map {α β : Typevec n} (g : α ⟹ β) : Fix F α → Fix F β :=
  Quotientₓ.lift (fun x : q.p.W α => ⟦q.p.wMap g x⟧) fun a b h => Quot.sound (Wequiv_map _ _ _ h)

instance Fix.mvfunctor : Mvfunctor (Fix F) where map := @Fix.map _ _ _ _

variable {α : Typevec.{u} n}

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- Recursor for `fix F` -/
def Fix.rec {β : Type u} (g : F (α ::: β) → β) : Fix F α → β :=
  Quot.lift (recF g) (recF_eq_of_Wequiv α g)

/-- Access W-type underlying `fix F`  -/
def fixToW : Fix F α → q.p.W α :=
  Quotientₓ.lift wrepr (recF_eq_of_Wequiv α fun x => q.p.wMk' (repr x))

/-- Constructor for `fix F` -/
def Fix.mk (x : F (Append1 α (Fix F α))) : Fix F α :=
  Quot.mk _ (q.p.wMk' (appendFun id fixToW <$$> repr x))

/-- Destructor for `fix F` -/
def Fix.dest : Fix F α → F (Append1 α (Fix F α)) :=
  Fix.rec (Mvfunctor.map (appendFun id Fix.mk))

theorem Fix.rec_eq {β : Type u} (g : F (Append1 α β) → β) (x : F (Append1 α (Fix F α))) :
    Fix.rec g (Fix.mk x) = g (appendFun id (Fix.rec g) <$$> x) := by
  have : recF g ∘ fix_to_W = Fix.rec g := by
    apply funext
    apply Quotientₓ.ind
    intro x
    apply recF_eq_of_Wequiv
    apply Wrepr_equiv
  conv => lhs rw [fix.rec, fix.mk]dsimp
  cases' h : reprₓ x with a f
  rw [Mvpfunctor.map_eq, recF_eq', ← Mvpfunctor.map_eq, Mvpfunctor.W_dest'_W_mk']
  rw [← Mvpfunctor.comp_map, abs_map, ← h, abs_repr, ← append_fun_comp, id_comp, this]

theorem Fix.ind_aux (a : q.p.A) (f' : q.p.drop.B a ⟹ α) (f : q.p.last.B a → q.p.W α) :
    Fix.mk (abs ⟨a, q.p.appendContents f' fun x => ⟦f x⟧⟩) = ⟦q.p.wMk a f' f⟧ := by
  have : Fix.mk (abs ⟨a, q.p.appendContents f' fun x => ⟦f x⟧⟩) = ⟦wrepr (q.p.wMk a f' f)⟧ := by
    apply Quot.sound
    apply Wequiv.abs'
    rw [Mvpfunctor.W_dest'_W_mk', abs_map, abs_repr, ← abs_map, Mvpfunctor.map_eq]
    conv => rhs rw [Wrepr_W_mk, q.P.W_dest'_W_mk', abs_repr, Mvpfunctor.map_eq]
    congr 2
    rw [Mvpfunctor.appendContents, Mvpfunctor.appendContents]
    rw [append_fun, append_fun, ← split_fun_comp, ← split_fun_comp]
    rfl
  rw [this]
  apply Quot.sound
  apply Wrepr_equiv

theorem Fix.ind_rec {β : Type _} (g₁ g₂ : Fix F α → β)
    (h :
      ∀ x : F (Append1 α (Fix F α)), appendFun id g₁ <$$> x = appendFun id g₂ <$$> x → g₁ (Fix.mk x) = g₂ (Fix.mk x)) :
    ∀ x, g₁ x = g₂ x := by
  apply Quot.ind
  intro x
  apply q.P.W_ind _ x
  intro a f' f ih
  show g₁ ⟦q.P.W_mk a f' f⟧ = g₂ ⟦q.P.W_mk a f' f⟧
  rw [← fix.ind_aux a f' f]
  apply h
  rw [← abs_map, ← abs_map, Mvpfunctor.map_eq, Mvpfunctor.map_eq]
  congr 2
  rw [Mvpfunctor.appendContents, append_fun, append_fun, ← split_fun_comp, ← split_fun_comp]
  have : (g₁ ∘ fun x => ⟦f x⟧) = g₂ ∘ fun x => ⟦f x⟧ := by
    ext x
    exact ih x
  rw [this]

theorem Fix.rec_unique {β : Type _} (g : F (Append1 α β) → β) (h : Fix F α → β)
    (hyp : ∀ x, h (Fix.mk x) = g (appendFun id h <$$> x)) : Fix.rec g = h := by
  ext x
  apply fix.ind_rec
  intro x hyp'
  rw [hyp, ← hyp', fix.rec_eq]

theorem Fix.mk_dest (x : Fix F α) : Fix.mk (Fix.dest x) = x := by
  change (fix.mk ∘ fix.dest) x = x
  apply fix.ind_rec
  intro x
  dsimp'
  rw [fix.dest, fix.rec_eq, ← comp_map, ← append_fun_comp, id_comp]
  intro h
  rw [h]
  show fix.mk (append_fun id id <$$> x) = fix.mk x
  rw [append_fun_id_id, Mvfunctor.id_map]

theorem Fix.dest_mk (x : F (Append1 α (Fix F α))) : Fix.dest (Fix.mk x) = x := by
  unfold fix.dest
  rw [fix.rec_eq, ← fix.dest, ← comp_map]
  conv => rhs rw [← Mvfunctor.id_map x]
  rw [← append_fun_comp, id_comp]
  have : fix.mk ∘ fix.dest = id := by
    ext x
    apply fix.mk_dest
  rw [this, append_fun_id_id]

theorem Fix.ind {α : Typevec n} (p : Fix F α → Prop)
    (h : ∀ x : F (α.Append1 (Fix F α)), Liftp (PredLast α p) x → p (Fix.mk x)) : ∀ x, p x := by
  apply Quot.ind
  intro x
  apply q.P.W_ind _ x
  intro a f' f ih
  change p ⟦q.P.W_mk a f' f⟧
  rw [← fix.ind_aux a f' f]
  apply h
  rw [Mvqpf.liftp_iff]
  refine' ⟨_, _, rfl, _⟩
  intro i j
  cases i
  · apply ih
    
  · trivial
    

instance mvqpfFix : Mvqpf (Fix F) where
  p := q.p.wp
  abs := fun α => Quot.mk Wequiv
  repr := fun α => fixToW
  abs_repr := by
    intro α
    apply Quot.ind
    intro a
    apply Quot.sound
    apply Wrepr_equiv
  abs_map := by
    intro α β g x
    conv => rhs dsimp [Mvfunctor.map]
    rw [fix.map]
    apply Quot.sound
    apply Wequiv.refl

-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
-- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation
/-- Dependent recursor for `fix F` -/
def Fix.drec {β : Fix F α → Type u} (g : ∀ x : F (α ::: Sigma β), β (fix.mk <| (id ::: Sigma.fst) <$$> x))
    (x : Fix F α) : β x :=
  let y := @Fix.rec _ F _ _ α (Sigma β) (fun i => ⟨_, g i⟩) x
  have : x = y.1 := by
    symm
    dsimp' [y]
    apply fix.ind_rec _ id _ x
    intro x' ih
    rw [fix.rec_eq]
    dsimp'
    simp [append_fun_id_id] at ih
    congr
    conv => rhs rw [← ih]
    rw [Mvfunctor.map_map, ← append_fun_comp, id_comp]
  cast
    (by
      rw [this])
    y.2

end Mvqpf

