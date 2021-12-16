import Mathbin.Data.Nat.Enat 
import Mathbin.Order.ConditionallyCompleteLattice

/-!
# Conditionally complete linear order structure on `ℕ`

In this file we

* define a `conditionally_complete_linear_order_bot` structure on `ℕ`;
* define a `complete_linear_order` structure on `enat`;
* prove a few lemmas about `supr`/`infi`/`set.Union`/`set.Inter` and natural numbers.
-/


open Set

namespace Nat

open_locale Classical

noncomputable instance : HasInfₓ ℕ :=
  ⟨fun s => if h : ∃ n, n ∈ s then @Nat.findₓ (fun n => n ∈ s) _ h else 0⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
noncomputable instance : HasSupₓ ℕ :=
  ⟨fun s => if h : ∃ n, ∀ a _ : a ∈ s, a ≤ n then @Nat.findₓ (fun n => ∀ a _ : a ∈ s, a ≤ n) _ h else 0⟩

theorem Inf_def {s : Set ℕ} (h : s.nonempty) : Inf s = @Nat.findₓ (fun n => n ∈ s) _ h :=
  dif_pos _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (a «expr ∈ » s)
theorem Sup_def {s : Set ℕ} (h : ∃ n, ∀ a _ : a ∈ s, a ≤ n) : Sup s = @Nat.findₓ (fun n => ∀ a _ : a ∈ s, a ≤ n) _ h :=
  dif_pos _

@[simp]
theorem Inf_eq_zero {s : Set ℕ} : Inf s = 0 ↔ 0 ∈ s ∨ s = ∅ :=
  by 
    cases eq_empty_or_nonempty s
    ·
      subst h 
      simp only [or_trueₓ, eq_self_iff_true, iff_trueₓ, Inf, HasInfₓ.inf, mem_empty_eq, exists_false, dif_neg,
        not_false_iff]
    ·
      have  := ne_empty_iff_nonempty.mpr h 
      simp only [this, or_falseₓ, Nat.Inf_def, h, Nat.find_eq_zero]

@[simp]
theorem Inf_empty : Inf ∅ = 0 :=
  by 
    rw [Inf_eq_zero]
    right 
    rfl

theorem Inf_mem {s : Set ℕ} (h : s.nonempty) : Inf s ∈ s :=
  by 
    rw [Nat.Inf_def h]
    exact Nat.find_specₓ h

theorem not_mem_of_lt_Inf {s : Set ℕ} {m : ℕ} (hm : m < Inf s) : m ∉ s :=
  by 
    cases eq_empty_or_nonempty s
    ·
      subst h 
      apply not_mem_empty
    ·
      rw [Nat.Inf_def h] at hm 
      exact Nat.find_minₓ h hm

protected theorem Inf_le {s : Set ℕ} {m : ℕ} (hm : m ∈ s) : Inf s ≤ m :=
  by 
    rw [Nat.Inf_def ⟨m, hm⟩]
    exact Nat.find_min'ₓ ⟨m, hm⟩ hm

theorem nonempty_of_pos_Inf {s : Set ℕ} (h : 0 < Inf s) : s.nonempty :=
  by 
    byContra contra 
    rw [Set.not_nonempty_iff_eq_empty] at contra 
    have h' : Inf s ≠ 0
    ·
      exact ne_of_gtₓ h 
    apply h' 
    rw [Nat.Inf_eq_zero]
    right 
    assumption

theorem nonempty_of_Inf_eq_succ {s : Set ℕ} {k : ℕ} (h : Inf s = k+1) : s.nonempty :=
  nonempty_of_pos_Inf (h.symm ▸ succ_pos k : Inf s > 0)

theorem eq_Ici_of_nonempty_of_upward_closed {s : Set ℕ} (hs : s.nonempty)
  (hs' : ∀ k₁ k₂ : ℕ, k₁ ≤ k₂ → k₁ ∈ s → k₂ ∈ s) : s = Ici (Inf s) :=
  ext fun n => ⟨fun H => Nat.Inf_le H, fun H => hs' (Inf s) n H (Inf_mem hs)⟩

theorem Inf_upward_closed_eq_succ_iff {s : Set ℕ} (hs : ∀ k₁ k₂ : ℕ, k₁ ≤ k₂ → k₁ ∈ s → k₂ ∈ s) (k : ℕ) :
  (Inf s = k+1) ↔ (k+1) ∈ s ∧ k ∉ s :=
  by 
    constructor
    ·
      intro H 
      rw [eq_Ici_of_nonempty_of_upward_closed (nonempty_of_Inf_eq_succ H) hs, H, mem_Ici, mem_Ici]
      exact ⟨le_reflₓ _, k.not_succ_le_self⟩
    ·
      rintro ⟨H, H'⟩
      rw [Inf_def (⟨_, H⟩ : s.nonempty), find_eq_iff]
      exact ⟨H, fun n hnk hns => H'$ hs n k (lt_succ_iff.mp hnk) hns⟩

/-- This instance is necessary, otherwise the lattice operations would be derived via
conditionally_complete_linear_order_bot and marked as noncomputable. -/
instance : Lattice ℕ :=
  latticeOfLinearOrder

noncomputable instance : ConditionallyCompleteLinearOrderBot ℕ :=
  { (inferInstance : OrderBot ℕ), (latticeOfLinearOrder : Lattice ℕ), (inferInstance : LinearOrderₓ ℕ) with sup := Sup,
    inf := Inf,
    le_cSup :=
      fun s a hb ha =>
        by 
          rw [Sup_def hb] <;> revert a ha <;> exact @Nat.find_specₓ _ _ hb,
    cSup_le :=
      fun s a hs ha =>
        by 
          rw [Sup_def ⟨a, ha⟩] <;> exact Nat.find_min'ₓ _ ha,
    le_cInf :=
      fun s a hs hb =>
        by 
          rw [Inf_def hs] <;> exact hb (@Nat.find_specₓ (fun n => n ∈ s) _ _),
    cInf_le :=
      fun s a hb ha =>
        by 
          rw [Inf_def ⟨a, ha⟩] <;> exact Nat.find_min'ₓ _ ha,
    cSup_empty :=
      by 
        simp only [Sup_def, Set.mem_empty_eq, forall_const, forall_prop_of_false, not_false_iff, exists_const]
        apply bot_unique (Nat.find_min'ₓ _ _)
        trivial }

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  Inf_add
  { n : ℕ } { p : ℕ → Prop } ( hn : n ≤ Inf { m | p m } ) : Inf { m | p m + n } + n = Inf { m | p m }
  :=
    by
      obtain h | ⟨ m , hm ⟩ := { m | p m + n } . eq_empty_or_nonempty
        ·
          rw [ h , Nat.Inf_empty , zero_addₓ ]
            obtain hnp | hnp := hn.eq_or_lt
            · exact hnp
            suffices hp : p Inf { m | p m } - n + n
            · exact h.subset hp . elim
            rw [ tsub_add_cancel_of_le hn ]
            exact Inf_mem nonempty_of_pos_Inf $ n.zero_le.trans_lt hnp
        ·
          have hp : ∃ n , n ∈ { m | p m } := ⟨ _ , hm ⟩
            rw [ Nat.Inf_def ⟨ m , hm ⟩ , Nat.Inf_def hp ]
            rw [ Nat.Inf_def hp ] at hn
            exact find_add hn

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  Inf_add'
  { n : ℕ } { p : ℕ → Prop } ( h : 0 < Inf { m | p m } ) : Inf { m | p m } + n = Inf { m | p m - n }
  :=
    by
      convert Inf_add _
        · simpRw [ add_tsub_cancel_right ]
        obtain ⟨ m , hm ⟩ := nonempty_of_pos_Inf h
        refine'
          le_cInf
            ⟨ m + n , _ ⟩
              fun
                b hb => le_of_not_ltₓ $ fun hbn => ne_of_mem_of_not_mem _ not_mem_of_lt_Inf h tsub_eq_zero_of_le hbn.le
        · dsimp rwa [ add_tsub_cancel_right ]
        · exact hb

section 

variable {α : Type _} [CompleteLattice α]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem supr_lt_succ (u : ℕ → α) (n : ℕ) : (⨆ (k : _)(_ : k < n+1), u k) = (⨆ (k : _)(_ : k < n), u k)⊔u n :=
  by 
    simp [Nat.lt_succ_iff_lt_or_eq, supr_or, supr_sup_eq]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem supr_lt_succ' (u : ℕ → α) (n : ℕ) : (⨆ (k : _)(_ : k < n+1), u k) = u 0⊔⨆ (k : _)(_ : k < n), u (k+1) :=
  by 
    rw [←sup_supr_nat_succ]
    simp 

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem infi_lt_succ (u : ℕ → α) (n : ℕ) : (⨅ (k : _)(_ : k < n+1), u k) = (⨅ (k : _)(_ : k < n), u k)⊓u n :=
  @supr_lt_succ (OrderDual α) _ _ _

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem infi_lt_succ' (u : ℕ → α) (n : ℕ) : (⨅ (k : _)(_ : k < n+1), u k) = u 0⊓⨅ (k : _)(_ : k < n), u (k+1) :=
  @supr_lt_succ' (OrderDual α) _ _ _

end 

end Nat

namespace Set

variable {α : Type _}

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem bUnion_lt_succ (u : ℕ → Set α) (n : ℕ) : (⋃ (k : _)(_ : k < n+1), u k) = (⋃ (k : _)(_ : k < n), u k) ∪ u n :=
  Nat.supr_lt_succ u n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem bUnion_lt_succ' (u : ℕ → Set α) (n : ℕ) : (⋃ (k : _)(_ : k < n+1), u k) = u 0 ∪ ⋃ (k : _)(_ : k < n), u (k+1) :=
  Nat.supr_lt_succ' u n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem bInter_lt_succ (u : ℕ → Set α) (n : ℕ) : (⋂ (k : _)(_ : k < n+1), u k) = (⋂ (k : _)(_ : k < n), u k) ∩ u n :=
  Nat.infi_lt_succ u n

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » «expr + »(n, 1))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (k «expr < » n)
theorem bInter_lt_succ' (u : ℕ → Set α) (n : ℕ) : (⋂ (k : _)(_ : k < n+1), u k) = u 0 ∩ ⋂ (k : _)(_ : k < n), u (k+1) :=
  Nat.infi_lt_succ' u n

end Set

namespace Enat

open_locale Classical

noncomputable instance : CompleteLinearOrder Enat :=
  { Enat.linearOrder, with_top_order_iso.symm.toGaloisInsertion.liftCompleteLattice with  }

end Enat

