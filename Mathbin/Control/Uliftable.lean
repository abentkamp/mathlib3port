import Mathbin.Control.Monad.Basic 
import Mathbin.Control.Monad.Cont 
import Mathbin.Control.Monad.Writer 
import Mathbin.Data.Equiv.Basic 
import Mathbin.Tactic.Interactive

/-!
# Universe lifting for type families

Some functors such as `option` and `list` are universe polymorphic. Unlike
type polymorphism where `option α` is a function application and reasoning and
generalizations that apply to functions can be used, `option.{u}` and `option.{v}`
are not one function applied to two universe names but one polymorphic definition
instantiated twice. This means that whatever works on `option.{u}` is hard
to transport over to `option.{v}`. `uliftable` is an attempt at improving the situation.

`uliftable option.{u} option.{v}` gives us a generic and composable way to use
`option.{u}` in a context that requires `option.{v}`. It is often used in tandem with
`ulift` but the two are purposefully decoupled.


## Main definitions
  * `uliftable` class

## Tags

universe polymorphism functor

-/


universe u₀ u₁ v₀ v₁ v₂ w w₀ w₁

variable {s : Type u₀} {s' : Type u₁} {r r' w w' : Type _}

/-- Given a universe polymorphic type family `M.{u} : Type u₁ → Type
u₂`, this class convert between instantiations, from
`M.{u} : Type u₁ → Type u₂` to `M.{v} : Type v₁ → Type v₂` and back -/
class Uliftable (f : Type u₀ → Type u₁) (g : Type v₀ → Type v₁) where 
  congr{} {α β} : α ≃ β → f α ≃ g β

namespace Uliftable

/-- The most common practical use `uliftable` (together with `up`), this function takes
`x : M.{u} α` and lifts it to M.{max u v} (ulift.{v} α) -/
@[reducible]
def up {f : Type u₀ → Type u₁} {g : Type max u₀ v₀ → Type v₁} [Uliftable f g] {α} : f α → g (Ulift α) :=
  (Uliftable.congr f g Equivₓ.ulift.symm).toFun

/-- The most common practical use of `uliftable` (together with `up`), this function takes
`x : M.{max u v} (ulift.{v} α)` and lowers it to `M.{u} α` -/
@[reducible]
def down {f : Type u₀ → Type u₁} {g : Type max u₀ v₀ → Type v₁} [Uliftable f g] {α} : g (Ulift α) → f α :=
  (Uliftable.congr f g Equivₓ.ulift.symm).invFun

/-- convenient shortcut to avoid manipulating `ulift` -/
def adapt_up (F : Type v₀ → Type v₁) (G : Type max v₀ u₀ → Type u₁) [Uliftable F G] [Monadₓ G] {α β} (x : F α)
  (f : α → G β) : G β :=
  up x >>= f ∘ Ulift.down

/-- convenient shortcut to avoid manipulating `ulift` -/
def adapt_down {F : Type max u₀ v₀ → Type u₁} {G : Type v₀ → Type v₁} [L : Uliftable G F] [Monadₓ F] {α β} (x : F α)
  (f : α → G β) : G β :=
  @down.{v₀, v₁, max u₀ v₀} G F L β$ x >>= @up.{v₀, v₁, max u₀ v₀} G F L β ∘ f

/-- map function that moves up universes -/
def up_map {F : Type u₀ → Type u₁} {G : Type max u₀ v₀ → Type v₁} [inst : Uliftable F G] [Functor G] {α β} (f : α → β)
  (x : F α) : G β :=
  Functor.map (f ∘ Ulift.down) (up x)

/-- map function that moves down universes -/
def down_map {F : Type max u₀ v₀ → Type u₁} {G : Type u₀ → Type v₁} [inst : Uliftable G F] [Functor F] {α β} (f : α → β)
  (x : F α) : G β :=
  down (Functor.map (Ulift.up ∘ f) x : F (Ulift β))

@[simp]
theorem up_down {f : Type u₀ → Type u₁} {g : Type max u₀ v₀ → Type v₁} [Uliftable f g] {α} (x : g (Ulift α)) :
  up (down x : f α) = x :=
  (Uliftable.congr f g Equivₓ.ulift.symm).right_inv _

@[simp]
theorem down_up {f : Type u₀ → Type u₁} {g : Type max u₀ v₀ → Type v₁} [Uliftable f g] {α} (x : f α) :
  down (up x : g _) = x :=
  (Uliftable.congr f g Equivₓ.ulift.symm).left_inv _

end Uliftable

open Ulift

instance : Uliftable id id :=
  { congr := fun α β F => F }

/-- for specific state types, this function helps to create a uliftable instance -/
def StateTₓ.uliftable' {m : Type u₀ → Type v₀} {m' : Type u₁ → Type v₁} [Uliftable m m'] (F : s ≃ s') :
  Uliftable (StateTₓ s m) (StateTₓ s' m') :=
  { congr := fun α β G => StateTₓ.equiv$ Equivₓ.piCongr F$ fun _ => Uliftable.congr _ _$ Equivₓ.prodCongr G F }

instance {m m'} [Uliftable m m'] : Uliftable (StateTₓ s m) (StateTₓ (Ulift s) m') :=
  StateTₓ.uliftable' Equivₓ.ulift.symm

/-- for specific reader monads, this function helps to create a uliftable instance -/
def ReaderTₓ.uliftable' {m m'} [Uliftable m m'] (F : s ≃ s') : Uliftable (ReaderTₓ s m) (ReaderTₓ s' m') :=
  { congr := fun α β G => ReaderTₓ.equiv$ Equivₓ.piCongr F$ fun _ => Uliftable.congr _ _ G }

instance {m m'} [Uliftable m m'] : Uliftable (ReaderTₓ s m) (ReaderTₓ (Ulift s) m') :=
  ReaderTₓ.uliftable' Equivₓ.ulift.symm

/-- for specific continuation passing monads, this function helps to create a uliftable instance -/
def ContT.uliftable' {m m'} [Uliftable m m'] (F : r ≃ r') : Uliftable (ContT r m) (ContT r' m') :=
  { congr := fun α β => ContT.equiv (Uliftable.congr _ _ F) }

instance {s m m'} [Uliftable m m'] : Uliftable (ContT s m) (ContT (Ulift s) m') :=
  ContT.uliftable' Equivₓ.ulift.symm

/-- for specific writer monads, this function helps to create a uliftable instance -/
def WriterT.uliftable' {m m'} [Uliftable m m'] (F : w ≃ w') : Uliftable (WriterT w m) (WriterT w' m') :=
  { congr := fun α β G => WriterT.equiv$ Uliftable.congr _ _$ Equivₓ.prodCongr G F }

instance {m m'} [Uliftable m m'] : Uliftable (WriterT s m) (WriterT (Ulift s) m') :=
  WriterT.uliftable' Equivₓ.ulift.symm

