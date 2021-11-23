import Mathbin.Computability.DFA

/-!
# Nondeterministic Finite Automata
This file contains the definition of a Nondeterministic Finite Automaton (NFA), a state machine
which determines whether a string (implemented as a list over an arbitrary alphabet) is in a regular
set by evaluating the string over every possible path.
We show that DFA's are equivalent to NFA's however the construction from NFA to DFA uses an
exponential number of states.
Note that this definition allows for Automaton with infinite states, a `fintype` instance must be
supplied for true NFA's.
-/


universe u v

/-- An NFA is a set of states (`σ`), a transition function from state to state labelled by the
  alphabet (`step`), a starting state (`start`) and a set of acceptance states (`accept`).
  Note the transition function sends a state to a `set` of states. These are the states that it
  may be sent to. -/
structure NFA(α : Type u)(σ : Type v) where 
  step : σ → α → Set σ 
  start : Set σ 
  accept : Set σ

variable{α : Type u}{σ σ' : Type v}(M : NFA α σ)

namespace NFA

instance  : Inhabited (NFA α σ) :=
  ⟨NFA.mk (fun _ _ => ∅) ∅ ∅⟩

/-- `M.step_set S a` is the union of `M.step s a` for all `s ∈ S`. -/
def step_set : Set σ → α → Set σ :=
  fun Ss a => Ss >>= fun S => M.step S a

theorem mem_step_set (s : σ) (S : Set σ) (a : α) : s ∈ M.step_set S a ↔ ∃ (t : _)(_ : t ∈ S), s ∈ M.step t a :=
  by 
    simp only [step_set, Set.mem_Union, Set.bind_def]

/-- `M.eval_from S x` computes all possible paths though `M` with input `x` starting at an element
  of `S`. -/
def eval_from (start : Set σ) : List α → Set σ :=
  List.foldlₓ M.step_set start

/-- `M.eval x` computes all possible paths though `M` with input `x` starting at an element of
  `M.start`. -/
def eval :=
  M.eval_from M.start

/-- `M.accepts` is the language of `x` such that there is an accept state in `M.eval x`. -/
def accepts : Language α :=
  fun x => ∃ (S : _)(_ : S ∈ M.accept), S ∈ M.eval x

/-- `M.to_DFA` is an `DFA` constructed from a `NFA` `M` using the subset construction. The
  states is the type of `set`s of `M.state` and the step function is `M.step_set`. -/
def to_DFA : DFA α (Set σ) :=
  { step := M.step_set, start := M.start, accept := { S | ∃ (s : _)(_ : s ∈ S), s ∈ M.accept } }

@[simp]
theorem to_DFA_correct : M.to_DFA.accepts = M.accepts :=
  by 
    ext x 
    rw [accepts, DFA.Accepts, eval, DFA.eval]
    change List.foldlₓ _ _ _ ∈ { S | _ } ↔ _ 
    finish

theorem pumping_lemma [Fintype σ] {x : List α} (hx : x ∈ M.accepts) (hlen : Fintype.card (Set σ) ≤ List.length x) :
  ∃ a b c,
    x = a ++ b ++ c ∧ (a.length+b.length) ≤ Fintype.card (Set σ) ∧ b ≠ [] ∧ (({a}*Language.Star {b})*{c}) ≤ M.accepts :=
  by 
    rw [←to_DFA_correct] at hx⊢
    exact M.to_DFA.pumping_lemma hx hlen

end NFA

namespace DFA

/-- `M.to_NFA` is an `NFA` constructed from a `DFA` `M` by using the same start and accept
  states and a transition function which sends `s` with input `a` to the singleton `M.step s a`. -/
def to_NFA (M : DFA α σ') : NFA α σ' :=
  { step := fun s a => {M.step s a}, start := {M.start}, accept := M.accept }

-- error in Computability.NFA: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
@[simp]
theorem to_NFA_eval_from_match
(M : DFA α σ)
(start : σ)
(s : list α) : «expr = »(M.to_NFA.eval_from {start} s, {M.eval_from start s}) :=
begin
  change [expr «expr = »(list.foldl M.to_NFA.step_set {start} s, {list.foldl M.step start s})] [] [],
  induction [expr s] [] ["with", ident a, ident s, ident ih] ["generalizing", ident start],
  { tauto [] },
  { rw ["[", expr list.foldl, ",", expr list.foldl, "]"] [],
    have [ident h] [":", expr «expr = »(M.to_NFA.step_set {start} a, {M.step start a})] [],
    { rw [expr NFA.step_set] [],
      finish [] [] },
    rw [expr h] [],
    tauto [] }
end

@[simp]
theorem to_NFA_correct (M : DFA α σ) : M.to_NFA.accepts = M.accepts :=
  by 
    ext x 
    change (∃ S H, S ∈ M.to_NFA.eval_from {M.start} x) ↔ _ 
    rw [to_NFA_eval_from_match]
    split 
    ·
      rintro ⟨S, hS₁, hS₂⟩
      rw [Set.mem_singleton_iff] at hS₂ 
      rw [hS₂] at hS₁ 
      assumption
    ·
      intro h 
      use M.eval x 
      finish

end DFA

