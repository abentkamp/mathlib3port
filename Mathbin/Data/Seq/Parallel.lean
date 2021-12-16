import Mathbin.Data.Seq.Wseq

universe u v

namespace Computation

open Wseq

variable {α : Type u} {β : Type v}

def parallel.aux2 : List (Computation α) → Sum α (List (Computation α)) :=
  List.foldr
    (fun c o =>
      match o with 
      | Sum.inl a => Sum.inl a
      | Sum.inr ls => rmap (fun c' => c' :: ls) (destruct c))
    (Sum.inr [])

def parallel.aux1 : List (Computation α) × Wseq (Computation α) → Sum α (List (Computation α) × Wseq (Computation α))
| (l, S) =>
  rmap
    (fun l' =>
      match Seqₓₓ.destruct S with 
      | none => (l', nil)
      | some (none, S') => (l', S')
      | some (some c, S') => (c :: l', S'))
    (parallel.aux2 l)

/-- Parallel computation of an infinite stream of computations,
  taking the first result -/
def parallel (S : Wseq (Computation α)) : Computation α :=
  corec parallel.aux1 ([], S)

theorem terminates_parallel.aux :
  ∀ {l : List (Computation α)} {S c}, c ∈ l → terminates c → terminates (corec parallel.aux1 (l, S)) :=
  by 
    have lem1 : ∀ l S, (∃ a : α, parallel.aux2 l = Sum.inl a) → terminates (corec parallel.aux1 (l, S))
    ·
      intro l S e 
      cases' e with a e 
      have this : corec parallel.aux1 (l, S) = return a
      ·
        apply destruct_eq_ret 
        simp [parallel.aux1]
        rw [e]
        simp [rmap]
      rw [this]
      infer_instance 
    intro l S c m T 
    revert l S 
    apply @terminates_rec_on _ _ c T _ _
    ·
      intro a l S m 
      apply lem1 
      induction' l with c l IH generalizing m <;> simp  at m
      ·
        contradiction 
      cases' m with e m
      ·
        rw [←e]
        simp [parallel.aux2]
        cases' List.foldr parallel.aux2._match_1 (Sum.inr List.nil) l with a' ls 
        exacts[⟨a', rfl⟩, ⟨a, rfl⟩]
      ·
        cases' IH m with a' e 
        simp [parallel.aux2]
        simp [parallel.aux2] at e 
        rw [e]
        exact ⟨a', rfl⟩
    ·
      intro s IH l S m 
      have H1 : ∀ l', parallel.aux2 l = Sum.inr l' → s ∈ l'
      ·
        induction' l with c l IH' generalizing m <;> intro l' e' <;> simp  at m
        ·
          contradiction 
        cases' m with e m <;> simp [parallel.aux2] at e'
        ·
          rw [←e] at e' 
          cases' List.foldr parallel.aux2._match_1 (Sum.inr List.nil) l with a' ls <;> injection e' with e' 
          rw [←e']
          simp 
        ·
          induction' e : List.foldr parallel.aux2._match_1 (Sum.inr List.nil) l with a' ls <;> rw [e] at e'
          ·
            contradiction 
          have  := IH' m _ e 
          simp [parallel.aux2] at e' 
          cases destruct c <;> injection e' with h' 
          rw [←h']
          simp [this]
      induction' h : parallel.aux2 l with a l'
      ·
        exact lem1 _ _ ⟨a, h⟩
      ·
        have H2 : corec parallel.aux1 (l, S) = think _
        ·
          apply destruct_eq_think 
          simp [parallel.aux1]
          rw [h]
          simp [rmap]
        rw [H2]
        apply @Computation.think_terminates _ _ _ 
        have  := H1 _ h 
        rcases Seqₓₓ.destruct S with (_ | ⟨_ | c, S'⟩) <;> simp [parallel.aux1] <;> apply IH <;> simp [this]

theorem terminates_parallel {S : Wseq (Computation α)} {c} (h : c ∈ S) [T : terminates c] : terminates (parallel S) :=
  suffices
    ∀ n l : List (Computation α) S c,
      c ∈ l ∨ some (some c) = Seqₓₓ.nth S n → terminates c → terminates (corec parallel.aux1 (l, S)) from
    let ⟨n, h⟩ := h 
    this n [] S c (Or.inr h) T 
  by 
    intro n 
    induction' n with n IH <;> intro l S c o T
    ·
      cases' o with a a
      ·
        exact terminates_parallel.aux a T 
      have H : Seqₓₓ.destruct S = some (some c, _)
      ·
        unfold Seqₓₓ.destruct Functor.map 
        rw [←a]
        simp 
      induction' h : parallel.aux2 l with a l' <;> have C : corec parallel.aux1 (l, S) = _
      ·
        apply destruct_eq_ret 
        simp [parallel.aux1]
        rw [h]
        simp [rmap]
      ·
        rw [C]
        skip 
        infer_instance
      ·
        apply destruct_eq_think 
        simp [parallel.aux1]
        rw [h, H]
        simp [rmap]
      ·
        rw [C]
        apply @Computation.think_terminates _ _ _ 
        apply terminates_parallel.aux _ T 
        simp 
    ·
      cases' o with a a
      ·
        exact terminates_parallel.aux a T 
      induction' h : parallel.aux2 l with a l' <;> have C : corec parallel.aux1 (l, S) = _
      ·
        apply destruct_eq_ret 
        simp [parallel.aux1]
        rw [h]
        simp [rmap]
      ·
        rw [C]
        skip 
        infer_instance
      ·
        apply destruct_eq_think 
        simp [parallel.aux1]
        rw [h]
        simp [rmap]
      ·
        rw [C]
        apply @Computation.think_terminates _ _ _ 
        have TT : ∀ l', terminates (corec parallel.aux1 (l', S.tail))
        ·
          intro 
          apply IH _ _ _ (Or.inr _) T 
          rw [a]
          cases' S with f al 
          rfl 
        induction' e : Seqₓₓ.nth S 0 with o
        ·
          have D : Seqₓₓ.destruct S = none
          ·
            dsimp [Seqₓₓ.destruct]
            rw [e]
            rfl 
          rw [D]
          simp [parallel.aux1]
          have TT := TT l' 
          rwa [Seqₓₓ.destruct_eq_nil D, Seqₓₓ.tail_nil] at TT
        ·
          have D : Seqₓₓ.destruct S = some (o, S.tail)
          ·
            dsimp [Seqₓₓ.destruct]
            rw [e]
            rfl 
          rw [D]
          cases' o with c <;> simp [parallel.aux1, TT]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » l)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » l')
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » l)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (c «expr ∈ » S)
theorem exists_of_mem_parallel {S : Wseq (Computation α)} {a} (h : a ∈ parallel S) : ∃ (c : _)(_ : c ∈ S), a ∈ c :=
  suffices ∀ C, a ∈ C → ∀ l : List (Computation α) S, corec parallel.aux1 (l, S) = C → ∃ c, (c ∈ l ∨ c ∈ S) ∧ a ∈ c from
    let ⟨c, h1, h2⟩ := this _ h [] S rfl
    ⟨c, h1.resolve_left id, h2⟩
  by 
    let F : List (Computation α) → Sum α (List (Computation α)) → Prop
    ·
      intro l a 
      cases' a with a l' 
      exact ∃ (c : _)(_ : c ∈ l), a ∈ c 
      exact ∀ a', (∃ (c : _)(_ : c ∈ l'), a' ∈ c) → ∃ (c : _)(_ : c ∈ l), a' ∈ c 
    have lem1 : ∀ l : List (Computation α), F l (parallel.aux2 l)
    ·
      intro l 
      induction' l with c l IH <;> simp [parallel.aux2]
      ·
        intro a h 
        rcases h with ⟨c, hn, _⟩
        exact False.elim hn
      ·
        simp [parallel.aux2] at IH 
        cases' List.foldr parallel.aux2._match_1 (Sum.inr List.nil) l with a ls <;> simp [parallel.aux2]
        ·
          rcases IH with ⟨c', cl, ac⟩
          refine' ⟨c', Or.inr cl, ac⟩
        ·
          induction' h : destruct c with a c' <;> simp [rmap]
          ·
            refine' ⟨c, List.mem_cons_selfₓ _ _, _⟩
            rw [destruct_eq_ret h]
            apply ret_mem
          ·
            intro a' h 
            rcases h with ⟨d, dm, ad⟩
            simp  at dm 
            cases' dm with e dl
            ·
              rw [e] at ad 
              refine' ⟨c, List.mem_cons_selfₓ _ _, _⟩
              rw [destruct_eq_think h]
              exact think_mem ad
            ·
              cases' IH a' ⟨d, dl, ad⟩ with d dm 
              cases' dm with dm ad 
              exact ⟨d, Or.inr dm, ad⟩
    intro C aC 
    refine' mem_rec_on aC _ fun C' IH => _ <;>
      intro l S e <;>
        have e' := congr_argₓ destruct e <;>
          have  := lem1 l <;> simp [parallel.aux1] at e' <;> cases' parallel.aux2 l with a' l' <;> injection e' with h'
    ·
      rw [h'] at this 
      rcases this with ⟨c, cl, ac⟩
      exact ⟨c, Or.inl cl, ac⟩
    ·
      induction' e : Seqₓₓ.destruct S with a <;> rw [e] at h'
      ·
        exact
          let ⟨d, o, ad⟩ := IH _ _ h' 
          let ⟨c, cl, ac⟩ := this a ⟨d, o.resolve_right (not_mem_nil _), ad⟩
          ⟨c, Or.inl cl, ac⟩
      ·
        cases' a with o S' 
        cases' o with c <;> simp [parallel.aux1] at h' <;> rcases IH _ _ h' with ⟨d, dl | dS', ad⟩
        ·
          exact
            let ⟨c, cl, ac⟩ := this a ⟨d, dl, ad⟩
            ⟨c, Or.inl cl, ac⟩
        ·
          refine' ⟨d, Or.inr _, ad⟩
          rw [Seqₓₓ.destruct_eq_cons e]
          exact Seqₓₓ.mem_cons_of_mem _ dS'
        ·
          simp  at dl 
          cases' dl with dc dl
          ·
            rw [dc] at ad 
            refine' ⟨c, Or.inr _, ad⟩
            rw [Seqₓₓ.destruct_eq_cons e]
            apply Seqₓₓ.mem_cons
          ·
            exact
              let ⟨c, cl, ac⟩ := this a ⟨d, dl, ad⟩
              ⟨c, Or.inl cl, ac⟩
        ·
          refine' ⟨d, Or.inr _, ad⟩
          rw [Seqₓₓ.destruct_eq_cons e]
          exact Seqₓₓ.mem_cons_of_mem _ dS'

theorem map_parallel (f : α → β) S : map f (parallel S) = parallel (S.map (map f)) :=
  by 
    refine'
      eq_of_bisim
        (fun c1 c2 =>
          ∃ l S, c1 = map f (corec parallel.aux1 (l, S)) ∧ c2 = corec parallel.aux1 (l.map (map f), S.map (map f)))
        _ ⟨[], S, rfl, rfl⟩
    intro c1 c2 h 
    exact
      match c1, c2, h with 
      | _, _, ⟨l, S, rfl, rfl⟩ =>
        by 
          clear _match 
          have  : parallel.aux2 (l.map (map f)) = lmap f (rmap (List.map (map f)) (parallel.aux2 l))
          ·
            simp [parallel.aux2]
            induction' l with c l IH <;> simp 
            rw [IH]
            cases List.foldr parallel.aux2._match_1 (Sum.inr List.nil) l <;> simp [parallel.aux2]
            cases destruct c <;> simp 
          simp [parallel.aux1]
          rw [this]
          cases' parallel.aux2 l with a l' <;> simp 
          apply S.cases_on _ (fun c S => _) fun S => _ <;> simp  <;> simp [parallel.aux1] <;> exact ⟨_, _, rfl, rfl⟩

theorem parallel_empty (S : Wseq (Computation α)) (h : S.head ~> none) : parallel S = Empty _ :=
  eq_empty_of_not_terminates$
    fun ⟨⟨a, m⟩⟩ =>
      let ⟨c, cs, ac⟩ := exists_of_mem_parallel m 
      let ⟨n, nm⟩ := exists_nth_of_mem cs 
      let ⟨c', h'⟩ := head_some_of_nth_some nm 
      by 
        injection h h'

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
def parallel_rec {S : Wseq (Computation α)} (C : α → Sort v) (H : ∀ s _ : s ∈ S, ∀ a _ : a ∈ s, C a) {a}
  (h : a ∈ parallel S) : C a :=
  by 
    let T : Wseq (Computation (α × Computation α)) := S.map fun c => c.map fun a => (a, c)
    have  : S = T.map (map fun c => c.1)
    ·
      rw [←Wseq.map_comp]
      refine' (Wseq.map_id _).symm.trans (congr_argₓ (fun f => Wseq.map f S) _)
      funext c 
      dsimp [id, Function.comp]
      rw [←map_comp]
      exact (map_id _).symm 
    have pe := congr_argₓ parallel this 
    rw [←map_parallel] at pe 
    have h' := h 
    rw [pe] at h' 
    have  : terminates (parallel T) := (terminates_map_iff _ _).1 ⟨⟨_, h'⟩⟩
    induction' e : get (parallel T) with a' c 
    have  : a ∈ c ∧ c ∈ S
    ·
      rcases exists_of_mem_map h' with ⟨d, dT, cd⟩
      rw [get_eq_of_mem _ dT] at e 
      cases e 
      dsimp  at cd 
      cases cd 
      rcases exists_of_mem_parallel dT with ⟨d', dT', ad'⟩
      rcases Wseq.exists_of_mem_map dT' with ⟨c', cs', e'⟩
      rw [←e'] at ad' 
      rcases exists_of_mem_map ad' with ⟨a', ac', e'⟩
      injection e' with i1 i2 
      constructor 
      rwa [i1, i2] at ac' 
      rwa [i2] at cs' 
    cases' this with ac cs 
    apply H _ cs _ ac

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
theorem parallel_promises {S : Wseq (Computation α)} {a} (H : ∀ s _ : s ∈ S, s ~> a) : parallel S ~> a :=
  fun a' ma' =>
    let ⟨c, cs, ac⟩ := exists_of_mem_parallel ma' 
    H _ cs ac

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
theorem mem_parallel {S : Wseq (Computation α)} {a} (H : ∀ s _ : s ∈ S, s ~> a) {c} (cs : c ∈ S) (ac : a ∈ c) :
  a ∈ parallel S :=
  by 
    have  := terminates_of_mem ac <;> have  := terminates_parallel cs <;> exact mem_of_promises _ (parallel_promises H)

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (t «expr ∈ » T)
theorem parallel_congr_lem {S T : Wseq (Computation α)} {a} (H : S.lift_rel Equivₓ T) :
  (∀ s _ : s ∈ S, s ~> a) ↔ ∀ t _ : t ∈ T, t ~> a :=
  ⟨fun h1 t tT =>
      let ⟨s, sS, se⟩ := Wseq.exists_of_lift_rel_right H tT
      (promises_congr se _).1 (h1 _ sS),
    fun h2 s sS =>
      let ⟨t, tT, se⟩ := Wseq.exists_of_lift_rel_left H sS
      (promises_congr se _).2 (h2 _ tT)⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (s «expr ∈ » S)
theorem parallel_congr_left {S T : Wseq (Computation α)} {a} (h1 : ∀ s _ : s ∈ S, s ~> a) (H : S.lift_rel Equivₓ T) :
  parallel S ~ parallel T :=
  let h2 := (parallel_congr_lem H).1 h1 
  fun a' =>
    ⟨fun h =>
        by 
          have aa := parallel_promises h1 h <;>
            rw [←aa] <;>
              rw [←aa] at h <;>
                exact
                  let ⟨s, sS, as⟩ := exists_of_mem_parallel h 
                  let ⟨t, tT, st⟩ := Wseq.exists_of_lift_rel_left H sS 
                  let aT := (st _).1 as 
                  mem_parallel h2 tT aT,
      fun h =>
        by 
          have aa := parallel_promises h2 h <;>
            rw [←aa] <;>
              rw [←aa] at h <;>
                exact
                  let ⟨s, sS, as⟩ := exists_of_mem_parallel h 
                  let ⟨t, tT, st⟩ := Wseq.exists_of_lift_rel_right H sS 
                  let aT := (st _).2 as 
                  mem_parallel h1 tT aT⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (t «expr ∈ » T)
theorem parallel_congr_right {S T : Wseq (Computation α)} {a} (h2 : ∀ t _ : t ∈ T, t ~> a) (H : S.lift_rel Equivₓ T) :
  parallel S ~ parallel T :=
  parallel_congr_left ((parallel_congr_lem H).2 h2) H

end Computation

