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

 * [Jeremy Avigad, Mario M. Carneiro and Simon Hudon, *Data Types as Quotients of Polynomial Functors*][avigad-carneiro-hudon2019]
-/


universe u v

namespace Mvqpf

open Typevec

open mvfunctor(Liftp Liftr)

open_locale Mvfunctor

variable{n : ℕ}{F : Typevec.{u} (n+1) → Type u}[Mvfunctor F][q : Mvqpf F]

include q

/-- `recF` is used as a basis for defining the recursor on `fix F α`. `recF`
traverses recursively the W-type generated by `q.P` using a function on `F`
as a recursive step -/
def recF {α : Typevec n} {β : Type _} (g : F (α.append1 β) → β) : q.P.W α → β :=
  q.P.W_rec fun a f' f rec => g (abs ⟨a, split_fun f' rec⟩)

theorem recF_eq {α : Typevec n} {β : Type _} (g : F (α.append1 β) → β) (a : q.P.A) (f' : q.P.drop.B a ⟹ α)
  (f : q.P.last.B a → q.P.W α) : recF g (q.P.W_mk a f' f) = g (abs ⟨a, split_fun f' (recF g ∘ f)⟩) :=
  by 
    rw [recF, Mvpfunctor.W_rec_eq] <;> rfl

theorem recF_eq' {α : Typevec n} {β : Type _} (g : F (α.append1 β) → β) (x : q.P.W α) :
  recF g x = g (abs (append_fun id (recF g) <$$> q.P.W_dest' x)) :=
  by 
    apply q.P.W_cases _ x 
    intro a f' f 
    rw [recF_eq, q.P.W_dest'_W_mk, Mvpfunctor.map_eq, append_fun_comp_split_fun, Typevec.id_comp]

/-- Equivalence relation on W-types that represent the same `fix F`
value -/
inductive Wequiv {α : Typevec n} : q.P.W α → q.P.W α → Prop
  | ind (a : q.P.A) (f' : q.P.drop.B a ⟹ α) (f₀ f₁ : q.P.last.B a → q.P.W α) :
  (∀ x, Wequiv (f₀ x) (f₁ x)) → Wequiv (q.P.W_mk a f' f₀) (q.P.W_mk a f' f₁)
  | abs (a₀ : q.P.A) (f'₀ : q.P.drop.B a₀ ⟹ α) (f₀ : q.P.last.B a₀ → q.P.W α) (a₁ : q.P.A) (f'₁ : q.P.drop.B a₁ ⟹ α)
  (f₁ : q.P.last.B a₁ → q.P.W α) :
  abs ⟨a₀, q.P.append_contents f'₀ f₀⟩ = abs ⟨a₁, q.P.append_contents f'₁ f₁⟩ →
    Wequiv (q.P.W_mk a₀ f'₀ f₀) (q.P.W_mk a₁ f'₁ f₁)
  | trans (u v w : q.P.W α) : Wequiv u v → Wequiv v w → Wequiv u w

theorem recF_eq_of_Wequiv (α : Typevec n) {β : Type _} (u : F (α.append1 β) → β) (x y : q.P.W α) :
  Wequiv x y → recF u x = recF u y :=
  by 
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

theorem Wequiv.abs' {α : Typevec n} (x y : q.P.W α) (h : abs (q.P.W_dest' x) = abs (q.P.W_dest' y)) : Wequiv x y :=
  by 
    revert h 
    apply q.P.W_cases _ x 
    intro a₀ f'₀ f₀ 
    apply q.P.W_cases _ y 
    intro a₁ f'₁ f₁ 
    apply Wequiv.abs

theorem Wequiv.refl {α : Typevec n} (x : q.P.W α) : Wequiv x x :=
  by 
    apply q.P.W_cases _ x <;> intro a f' f <;> exact Wequiv.abs a f' f a f' f rfl

theorem Wequiv.symm {α : Typevec n} (x y : q.P.W α) : Wequiv x y → Wequiv y x :=
  by 
    intro h 
    induction h 
    case mvqpf.Wequiv.ind a f' f₀ f₁ h ih => 
      exact Wequiv.ind _ _ _ _ ih 
    case mvqpf.Wequiv.abs a₀ f'₀ f₀ a₁ f'₁ f₁ h => 
      exact Wequiv.abs _ _ _ _ _ _ h.symm 
    case mvqpf.Wequiv.trans x y z e₁ e₂ ih₁ ih₂ => 
      exact Mvqpf.Wequiv.trans _ _ _ ih₂ ih₁

/-- maps every element of the W type to a canonical representative -/
def Wrepr {α : Typevec n} : q.P.W α → q.P.W α :=
  recF (q.P.W_mk' ∘ reprₓ)

theorem Wrepr_W_mk {α : Typevec n} (a : q.P.A) (f' : q.P.drop.B a ⟹ α) (f : q.P.last.B a → q.P.W α) :
  Wrepr (q.P.W_mk a f' f) = q.P.W_mk' (reprₓ (abs (append_fun id Wrepr <$$> ⟨a, q.P.append_contents f' f⟩))) :=
  by 
    rw [Wrepr, recF_eq', q.P.W_dest'_W_mk] <;> rfl

theorem Wrepr_equiv {α : Typevec n} (x : q.P.W α) : Wequiv (Wrepr x) x :=
  by 
    apply q.P.W_ind _ x 
    intro a f' f ih 
    apply Wequiv.trans _ (q.P.W_mk' (append_fun id Wrepr <$$> ⟨a, q.P.append_contents f' f⟩))
    ·
      apply Wequiv.abs' 
      rw [Wrepr_W_mk, q.P.W_dest'_W_mk', q.P.W_dest'_W_mk', abs_repr]
    rw [q.P.map_eq, Mvpfunctor.wMk', append_fun_comp_split_fun, id_comp]
    apply Wequiv.ind 
    exact ih

theorem Wequiv_map {α β : Typevec n} (g : α ⟹ β) (x y : q.P.W α) : Wequiv x y → Wequiv (g <$$> x) (g <$$> y) :=
  by 
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
      rw [←q.P.map_obj_append1, ←q.P.map_obj_append1, abs_map, abs_map, h]
    case mvqpf.Wequiv.trans x y z e₁ e₂ ih₁ ih₂ => 
      apply Mvqpf.Wequiv.trans 
      apply ih₁ 
      apply ih₂

/--
Define the fixed point as the quotient of trees under the equivalence relation.
-/
def W_setoid (α : Typevec n) : Setoidₓ (q.P.W α) :=
  ⟨Wequiv, @Wequiv.refl _ _ _ _ _, @Wequiv.symm _ _ _ _ _, @Wequiv.trans _ _ _ _ _⟩

attribute [local instance] W_setoid

/-- Least fixed point of functor F. The result is a functor with one fewer parameters
than the input. For `F a b c` a ternary functor, fix F is a binary functor such that

```lean
fix F a b = F a b (fix F a b)
```
-/
def fix {n : ℕ} (F : Typevec (n+1) → Type _) [Mvfunctor F] [q : Mvqpf F] (α : Typevec n) :=
  Quotientₓ (W_setoid α : Setoidₓ (q.P.W α))

attribute [nolint has_inhabited_instance] fix

/-- `fix F` is a functor -/
def fix.map {α β : Typevec n} (g : α ⟹ β) : fix F α → fix F β :=
  Quotientₓ.lift (fun x : q.P.W α => «expr⟦ ⟧» (q.P.W_map g x)) fun a b h => Quot.sound (Wequiv_map _ _ _ h)

instance fix.mvfunctor : Mvfunctor (fix F) :=
  { map := @fix.map _ _ _ _ }

variable{α : Typevec.{u} n}

/-- Recursor for `fix F` -/
def fix.rec {β : Type u} (g : F (α ::: β) → β) : fix F α → β :=
  Quot.lift (recF g) (recF_eq_of_Wequiv α g)

/-- Access W-type underlying `fix F`  -/
def fix_to_W : fix F α → q.P.W α :=
  Quotientₓ.lift Wrepr (recF_eq_of_Wequiv α fun x => q.P.W_mk' (reprₓ x))

/-- Constructor for `fix F` -/
def fix.mk (x : F (append1 α (fix F α))) : fix F α :=
  Quot.mk _ (q.P.W_mk' (append_fun id fix_to_W <$$> reprₓ x))

/-- Destructor for `fix F` -/
def fix.dest : fix F α → F (append1 α (fix F α)) :=
  fix.rec (Mvfunctor.map (append_fun id fix.mk))

theorem fix.rec_eq {β : Type u} (g : F (append1 α β) → β) (x : F (append1 α (fix F α))) :
  fix.rec g (fix.mk x) = g (append_fun id (fix.rec g) <$$> x) :=
  have  : recF g ∘ fix_to_W = fix.rec g :=
    by 
      apply funext 
      apply Quotientₓ.ind 
      intro x 
      apply recF_eq_of_Wequiv 
      apply Wrepr_equiv 
  by 
    conv  => toLHS rw [fix.rec, fix.mk]dsimp 
    cases' h : reprₓ x with a f 
    rw [Mvpfunctor.map_eq, recF_eq', ←Mvpfunctor.map_eq, Mvpfunctor.W_dest'_W_mk']
    rw [←Mvpfunctor.comp_map, abs_map, ←h, abs_repr, ←append_fun_comp, id_comp, this]

theorem fix.ind_aux (a : q.P.A) (f' : q.P.drop.B a ⟹ α) (f : q.P.last.B a → q.P.W α) :
  fix.mk (abs ⟨a, q.P.append_contents f' fun x => «expr⟦ ⟧» (f x)⟩) = «expr⟦ ⟧» (q.P.W_mk a f' f) :=
  have  : fix.mk (abs ⟨a, q.P.append_contents f' fun x => «expr⟦ ⟧» (f x)⟩) = «expr⟦ ⟧» (Wrepr (q.P.W_mk a f' f)) :=
    by 
      apply Quot.sound 
      apply Wequiv.abs' 
      rw [Mvpfunctor.W_dest'_W_mk', abs_map, abs_repr, ←abs_map, Mvpfunctor.map_eq]
      conv  => toRHS rw [Wrepr_W_mk, q.P.W_dest'_W_mk', abs_repr, Mvpfunctor.map_eq]
      congr 2
      rw [Mvpfunctor.appendContents, Mvpfunctor.appendContents]
      rw [append_fun, append_fun, ←split_fun_comp, ←split_fun_comp]
      rfl 
  by 
    rw [this]
    apply Quot.sound 
    apply Wrepr_equiv

-- error in Data.Qpf.Multivariate.Constructions.Fix: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem fix.ind_rec
{β : Type*}
(g₁ g₂ : fix F α → β)
(h : ∀
 x : F (append1 α (fix F α)), «expr = »(«expr <$$> »(append_fun id g₁, x), «expr <$$> »(append_fun id g₂, x)) → «expr = »(g₁ (fix.mk x), g₂ (fix.mk x))) : ∀
x, «expr = »(g₁ x, g₂ x) :=
begin
  apply [expr quot.ind],
  intro [ident x],
  apply [expr q.P.W_ind _ x],
  intros [ident a, ident f', ident f, ident ih],
  show [expr «expr = »(g₁ «expr⟦ ⟧»(q.P.W_mk a f' f), g₂ «expr⟦ ⟧»(q.P.W_mk a f' f))],
  rw ["[", "<-", expr fix.ind_aux a f' f, "]"] [],
  apply [expr h],
  rw ["[", "<-", expr abs_map, ",", "<-", expr abs_map, ",", expr mvpfunctor.map_eq, ",", expr mvpfunctor.map_eq, "]"] [],
  congr' [2] [],
  rw ["[", expr mvpfunctor.append_contents, ",", expr append_fun, ",", expr append_fun, ",", "<-", expr split_fun_comp, ",", "<-", expr split_fun_comp, "]"] [],
  have [] [":", expr «expr = »(«expr ∘ »(g₁, λ x, «expr⟦ ⟧»(f x)), «expr ∘ »(g₂, λ x, «expr⟦ ⟧»(f x)))] [],
  { ext [] [ident x] [],
    exact [expr ih x] },
  rw [expr this] []
end

theorem fix.rec_unique {β : Type _} (g : F (append1 α β) → β) (h : fix F α → β)
  (hyp : ∀ x, h (fix.mk x) = g (append_fun id h <$$> x)) : fix.rec g = h :=
  by 
    ext x 
    apply fix.ind_rec 
    intro x hyp' 
    rw [hyp, ←hyp', fix.rec_eq]

theorem fix.mk_dest (x : fix F α) : fix.mk (fix.dest x) = x :=
  by 
    change (fix.mk ∘ fix.dest) x = x 
    apply fix.ind_rec 
    intro x 
    dsimp 
    rw [fix.dest, fix.rec_eq, ←comp_map, ←append_fun_comp, id_comp]
    intro h 
    rw [h]
    show fix.mk (append_fun id id <$$> x) = fix.mk x 
    rw [append_fun_id_id, Mvfunctor.id_map]

-- error in Data.Qpf.Multivariate.Constructions.Fix: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem fix.dest_mk (x : F (append1 α (fix F α))) : «expr = »(fix.dest (fix.mk x), x) :=
begin
  unfold [ident fix.dest] [],
  rw ["[", expr fix.rec_eq, ",", "<-", expr fix.dest, ",", "<-", expr comp_map, "]"] [],
  conv [] [] { to_rhs,
    rw ["<-", expr mvfunctor.id_map x] },
  rw ["[", "<-", expr append_fun_comp, ",", expr id_comp, "]"] [],
  have [] [":", expr «expr = »(«expr ∘ »(fix.mk, fix.dest), id)] [],
  { ext [] [ident x] [],
    apply [expr fix.mk_dest] },
  rw ["[", expr this, ",", expr append_fun_id_id, "]"] []
end

theorem fix.ind {α : Typevec n} (p : fix F α → Prop)
  (h : ∀ x : F (α.append1 (fix F α)), liftp (pred_last α p) x → p (fix.mk x)) : ∀ x, p x :=
  by 
    apply Quot.ind 
    intro x 
    apply q.P.W_ind _ x 
    intro a f' f ih 
    change p («expr⟦ ⟧» (q.P.W_mk a f' f))
    rw [←fix.ind_aux a f' f]
    apply h 
    rw [Mvqpf.liftp_iff]
    refine' ⟨_, _, rfl, _⟩
    intro i j 
    cases i
    ·
      apply ih
    ·
      triv

instance mvqpf_fix : Mvqpf (fix F) :=
  { p := q.P.Wp, abs := fun α => Quot.mk Wequiv, repr := fun α => fix_to_W,
    abs_repr :=
      by 
        intro α 
        apply Quot.ind 
        intro a 
        apply Quot.sound 
        apply Wrepr_equiv,
    abs_map :=
      by 
        intro α β g x 
        conv  => toRHS dsimp [Mvfunctor.map]
        rw [fix.map]
        apply Quot.sound 
        apply Wequiv.refl }

/-- Dependent recursor for `fix F` -/
def fix.drec {β : fix F α → Type u} (g : ∀ x : F (α ::: Sigma β), β (fix.mk$ (id ::: Sigma.fst) <$$> x)) (x : fix F α) :
  β x :=
  let y := @fix.rec _ F _ _ α (Sigma β) (fun i => ⟨_, g i⟩) x 
  have  : x = y.1 :=
    by 
      symm 
      dsimp [y]
      apply fix.ind_rec _ id _ x 
      intro x' ih 
      rw [fix.rec_eq]
      dsimp 
      simp [append_fun_id_id] at ih 
      congr 
      conv  => toRHS rw [←ih]
      rw [Mvfunctor.map_map, ←append_fun_comp, id_comp]
  cast
    (by 
      rw [this])
    y.2

end Mvqpf

