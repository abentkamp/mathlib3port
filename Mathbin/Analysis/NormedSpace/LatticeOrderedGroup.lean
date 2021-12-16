import Mathbin.Topology.Order.Lattice 
import Mathbin.Analysis.Normed.Group.Basic 
import Mathbin.Algebra.Order.LatticeGroup

/-!
# Normed lattice ordered groups

Motivated by the theory of Banach Lattices, we then define `normed_lattice_add_comm_group` as a
lattice with a covariant normed group addition satisfying the solid axiom.

## Main statements

We show that a normed lattice ordered group is a topological lattice with respect to the norm
topology.

## References

* [Meyer-Nieberg, Banach lattices][MeyerNieberg1991]

## Tags

normed, lattice, ordered, group
-/


/-!
### Normed lattice orderd groups

Motivated by the theory of Banach Lattices, this section introduces normed lattice ordered groups.
-/


local notation "|" a "|" => abs a

/--
Let `α` be a normed commutative group equipped with a partial order covariant with addition, with
respect which `α` forms a lattice. Suppose that `α` is *solid*, that is to say, for `a` and `b` in
`α`, with absolute values `|a|` and `|b|` respectively, `|a| ≤ |b|` implies `∥a∥ ≤ ∥b∥`. Then `α` is
said to be a normed lattice ordered group.
-/
class NormedLatticeAddCommGroup (α : Type _) extends NormedGroup α, Lattice α where 
  add_le_add_left : ∀ a b : α, a ≤ b → ∀ c : α, (c+a) ≤ c+b 
  solid : ∀ a b : α, |a| ≤ |b| → ∥a∥ ≤ ∥b∥

theorem solid {α : Type _} [NormedLatticeAddCommGroup α] {a b : α} (h : |a| ≤ |b|) : ∥a∥ ≤ ∥b∥ :=
  NormedLatticeAddCommGroup.solid a b h

noncomputable instance : NormedLatticeAddCommGroup ℝ :=
  { add_le_add_left := fun _ _ h _ => add_le_add le_rfl h, solid := fun _ _ => id }

/--
A normed lattice ordered group is an ordered additive commutative group
-/
instance (priority := 100) normedLatticeAddCommGroupToOrderedAddCommGroup {α : Type _}
  [h : NormedLatticeAddCommGroup α] : OrderedAddCommGroup α :=
  { h with  }

/--
Let `α` be a normed group with a partial order. Then the order dual is also a normed group.
-/
instance (priority := 100) {α : Type _} : ∀ [NormedGroup α], NormedGroup (OrderDual α) :=
  id

variable {α : Type _} [NormedLatticeAddCommGroup α]

open LatticeOrderedCommGroup

theorem dual_solid (a b : α) (h : b⊓-b ≤ a⊓-a) : ∥a∥ ≤ ∥b∥ :=
  by 
    apply solid 
    rw [abs_eq_sup_neg]
    nthRw 0[←neg_negₓ a]
    rw [←neg_inf_eq_sup_neg]
    rw [abs_eq_sup_neg]
    nthRw 0[←neg_negₓ b]
    rw [←neg_inf_eq_sup_neg]
    finish

/--
Let `α` be a normed lattice ordered group, then the order dual is also a
normed lattice ordered group.
-/
instance (priority := 100) : NormedLatticeAddCommGroup (OrderDual α) :=
  { add_le_add_left :=
      by 
        intro a b h₁ c 
        rw [←OrderDual.dual_le]
        rw [←OrderDual.dual_le] at h₁ 
        exact add_le_add_left h₁ _,
    solid :=
      by 
        intro a b h₂ 
        apply dual_solid 
        rw [←OrderDual.dual_le] at h₂ 
        finish }

theorem norm_abs_eq_norm (a : α) : ∥|a|∥ = ∥a∥ :=
  (solid (abs_abs a).le).antisymm (solid (abs_abs a).symm.le)

theorem norm_inf_sub_inf_le_add_norm (a b c d : α) : ∥a⊓b - c⊓d∥ ≤ ∥a - c∥+∥b - d∥ :=
  by 
    rw [←norm_abs_eq_norm (a - c), ←norm_abs_eq_norm (b - d)]
    refine' le_transₓ (solid _) (norm_add_le |a - c| |b - d|)
    rw [abs_of_nonneg (|a - c|+|b - d|) (add_nonneg (abs_nonneg (a - c)) (abs_nonneg (b - d)))]
    calc |a⊓b - c⊓d| = |(a⊓b - c⊓b)+c⊓b - c⊓d| :=
      by 
        rw [sub_add_sub_cancel]_ ≤ |a⊓b - c⊓b|+|c⊓b - c⊓d| :=
      abs_add_le _ _ _ ≤ |a - c|+|b - d| :=
      by 
        apply add_le_add
        ·
          exact abs_inf_sub_inf_le_abs _ _ _
        ·
          rw [@inf_comm _ _ c, @inf_comm _ _ c]
          exact abs_inf_sub_inf_le_abs _ _ _

theorem norm_sup_sub_sup_le_add_norm (a b c d : α) : ∥a⊔b - c⊔d∥ ≤ ∥a - c∥+∥b - d∥ :=
  by 
    rw [←norm_abs_eq_norm (a - c), ←norm_abs_eq_norm (b - d)]
    refine' le_transₓ (solid _) (norm_add_le |a - c| |b - d|)
    rw [abs_of_nonneg (|a - c|+|b - d|) (add_nonneg (abs_nonneg (a - c)) (abs_nonneg (b - d)))]
    calc |a⊔b - c⊔d| = |(a⊔b - c⊔b)+c⊔b - c⊔d| :=
      by 
        rw [sub_add_sub_cancel]_ ≤ |a⊔b - c⊔b|+|c⊔b - c⊔d| :=
      abs_add_le _ _ _ ≤ |a - c|+|b - d| :=
      by 
        apply add_le_add
        ·
          exact abs_sup_sub_sup_le_abs _ _ _
        ·
          rw [@sup_comm _ _ c, @sup_comm _ _ c]
          exact abs_sup_sub_sup_le_abs _ _ _

/--
Let `α` be a normed lattice ordered group. Then the infimum is jointly continuous.
-/
instance (priority := 100) normed_lattice_add_comm_group_has_continuous_inf : HasContinuousInf α :=
  by 
    refine' ⟨continuous_iff_continuous_at.2$ fun q => tendsto_iff_norm_tendsto_zero.2$ _⟩
    have  : ∀ p : α × α, ∥p.1⊓p.2 - q.1⊓q.2∥ ≤ ∥p.1 - q.1∥+∥p.2 - q.2∥
    exact fun _ => norm_inf_sub_inf_le_add_norm _ _ _ _ 
    refine' squeeze_zero (fun e => norm_nonneg _) this _ 
    convert
      ((continuous_fst.tendsto q).sub tendsto_const_nhds).norm.add
        ((continuous_snd.tendsto q).sub tendsto_const_nhds).norm 
    simp 

instance (priority := 100) normed_lattice_add_comm_group_has_continuous_sup {α : Type _} [NormedLatticeAddCommGroup α] :
  HasContinuousSup α :=
  OrderDual.has_continuous_sup (OrderDual α)

/--
Let `α` be a normed lattice ordered group. Then `α` is a topological lattice in the norm topology.
-/
instance (priority := 100) normedLatticeAddCommGroupTopologicalLattice : TopologicalLattice α :=
  TopologicalLattice.mk

theorem norm_abs_sub_abs (a b : α) : ∥|a| - |b|∥ ≤ ∥a - b∥ :=
  solid (LatticeOrderedCommGroup.abs_abs_sub_abs_le _ _)

