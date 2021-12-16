import Mathbin.Data.Fintype.Basic 
import Mathbin.Computability.Language 
import Mathbin.Tactic.NormNum

/-!
# Deterministic Finite Automata
This file contains the definition of a Deterministic Finite Automaton (DFA), a state machine which
determines whether a string (implemented as a list over an arbitrary alphabet) is in a regular set
in linear time.
Note that this definition allows for Automaton with infinite states, a `fintype` instance must be
supplied for true DFA's.
-/


universe u v

/-- A DFA is a set of states (`σ`), a transition function from state to state labelled by the
  alphabet (`step`), a starting state (`start`) and a set of acceptance states (`accept`). -/
structure DFA (α : Type u) (σ : Type v) where 
  step : σ → α → σ 
  start : σ 
  accept : Set σ

namespace DFA

variable {α : Type u} {σ : Type v} (M : DFA α σ)

instance [Inhabited σ] : Inhabited (DFA α σ) :=
  ⟨DFA.mk (fun _ _ => default σ) (default σ) ∅⟩

/-- `M.eval_from s x` evaluates `M` with input `x` starting from the state `s`. -/
def eval_from (start : σ) : List α → σ :=
  List.foldlₓ M.step start

/-- `M.eval x` evaluates `M` with input `x` starting from the state `M.start`. -/
def eval :=
  M.eval_from M.start

/-- `M.accepts` is the language of `x` such that `M.eval x` is an accept state. -/
def accepts : Language α :=
  fun x => M.eval x ∈ M.accept

theorem mem_accepts (x : List α) : x ∈ M.accepts ↔ M.eval_from M.start x ∈ M.accept :=
  by 
    rfl

theorem eval_from_of_append (start : σ) (x y : List α) :
  M.eval_from start (x ++ y) = M.eval_from (M.eval_from start x) y :=
  x.foldl_append _ _ y

theorem eval_from_split [Fintype σ] {x : List α} {s t : σ} (hlen : Fintype.card σ ≤ x.length)
  (hx : M.eval_from s x = t) :
  ∃ q a b c,
    x = a ++ b ++ c ∧
      (a.length+b.length) ≤ Fintype.card σ ∧ b ≠ [] ∧ M.eval_from s a = q ∧ M.eval_from q b = q ∧ M.eval_from q c = t :=
  by 
    obtain ⟨n, m, hneq, heq⟩ :=
      Fintype.exists_ne_map_eq_of_card_lt (fun n : Finₓ (Fintype.card σ+1) => M.eval_from s (x.take n))
        (by 
          normNum)
    wlog hle : (n : ℕ) ≤ m using n m 
    have hlt : (n : ℕ) < m := (Ne.le_iff_lt hneq).mp hle 
    have hm : (m : ℕ) ≤ Fintype.card σ := Finₓ.is_le m 
    dsimp  at heq 
    refine'
      ⟨M.eval_from s ((x.take m).take n), (x.take m).take n, (x.take m).drop n, x.drop m, _, _, _,
        by 
          rfl,
        _⟩
    ·
      rw [List.take_append_drop, List.take_append_drop]
    ·
      simp only [List.length_drop, List.length_take]
      rw [min_eq_leftₓ (hm.trans hlen), min_eq_leftₓ hle, add_tsub_cancel_of_le hle]
      exact hm
    ·
      intro h 
      have hlen' := congr_argₓ List.length h 
      simp only [List.length_drop, List.length, List.length_take] at hlen' 
      rw [min_eq_leftₓ, tsub_eq_zero_iff_le] at hlen'
      ·
        apply hneq 
        apply le_antisymmₓ 
        assumption' 
      exact hm.trans hlen 
    have hq : M.eval_from (M.eval_from s ((x.take m).take n)) ((x.take m).drop n) = M.eval_from s ((x.take m).take n)
    ·
      rw [List.take_take, min_eq_leftₓ hle, ←eval_from_of_append, HEq, ←min_eq_leftₓ hle, ←List.take_take,
        min_eq_leftₓ hle, List.take_append_drop]
    use hq 
    rwa [←hq, ←eval_from_of_append, ←eval_from_of_append, ←List.append_assoc, List.take_append_drop,
      List.take_append_drop]

theorem eval_from_of_pow {x y : List α} {s : σ} (hx : M.eval_from s x = s) (hy : y ∈ @Language.Star α {x}) :
  M.eval_from s y = s :=
  by 
    rw [Language.mem_star] at hy 
    rcases hy with ⟨S, rfl, hS⟩
    induction' S with a S ih
    ·
      rfl
    ·
      have ha := hS a (List.mem_cons_selfₓ _ _)
      rw [Set.mem_singleton_iff] at ha 
      rw [List.join, eval_from_of_append, ha, hx]
      apply ih 
      intro z hz 
      exact hS z (List.mem_cons_of_memₓ a hz)

theorem pumping_lemma [Fintype σ] {x : List α} (hx : x ∈ M.accepts) (hlen : Fintype.card σ ≤ List.length x) :
  ∃ a b c,
    x = a ++ b ++ c ∧ (a.length+b.length) ≤ Fintype.card σ ∧ b ≠ [] ∧ (({a}*Language.Star {b})*{c}) ≤ M.accepts :=
  by 
    obtain ⟨_, a, b, c, hx, hlen, hnil, rfl, hb, hc⟩ := M.eval_from_split hlen rfl 
    use a, b, c, hx, hlen, hnil 
    intro y hy 
    rw [Language.mem_mul] at hy 
    rcases hy with ⟨ab, c', hab, hc', rfl⟩
    rw [Language.mem_mul] at hab 
    rcases hab with ⟨a', b', ha', hb', rfl⟩
    rw [Set.mem_singleton_iff] at ha' hc' 
    substs ha' hc' 
    have h := M.eval_from_of_pow hb hb' 
    rwa [mem_accepts, eval_from_of_append, eval_from_of_append, h, hc]

end DFA

