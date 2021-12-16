import Mathbin.Topology.MetricSpace.Basic 
import Mathbin.SetTheory.CardinalOrdinal 
import Mathbin.MeasureTheory.Integral.Lebesgue 
import Mathbin.MeasureTheory.Covering.VitaliFamily

/-!
# Besicovitch covering theorems

The topological Besicovitch covering theorem ensures that, in a nice metric space, there exists a
number `N` such that, from any family of balls with bounded radii, one can extract `N` families,
each made of disjoint balls, covering together all the centers of the initial family.

By "nice metric space", we mean a technical property stated as follows: there exists no satellite
configuration of `N+1` points (with a given parameter `τ > 1`). Such a configuration is a family
of `N + 1` balls, where the first `N` balls all intersect the last one, but none of them contains
the center of another one and their radii are controlled. This property is for instance
satisfied by finite-dimensional real vector spaces.

In this file, we prove the topological Besicovitch covering theorem,
in `besicovitch.exist_disjoint_covering_families`.

The measurable Besicovitch theorem ensures that, in the same class of metric spaces, if at every
point one considers a class of balls of arbitrarily small radii, called admissible balls, then
one can cover almost all the space by a family of disjoint admissible balls.
It is deduced from the topological Besicovitch theorem, and proved
in `besicovitch.exists_disjoint_closed_ball_covering_ae`.

## Main definitions and results

* `satellite_config α N τ` is the type of all satellite configurations of `N+1` points
  in the metric space `α`, with parameter `τ`.
* `has_besicovitch_covering` is a class recording that there exist `N` and `τ > 1` such that
  there is no satellite configuration of `N+1` points with parameter `τ`.
* `exist_disjoint_covering_families` is the topological Besicovitch covering theorem: from any
  family of balls one can extract finitely many disjoint subfamilies covering the same set.
* `exists_disjoint_closed_ball_covering` is the measurable Besicovitch covering theorem: from any
  family of balls with arbitrarily small radii at every point, one can extract countably many
  disjoint balls covering almost all the space. While the value of `N` is relevant for the precise
  statement of the topological Besicovitch theorem, it becomes irrelevant for the measurable one.
  Therefore, this statement is expressed using the `Prop`-valued
  typeclass `has_besicovitch_covering`.

## Implementation

#### Sketch of proof of the topological Besicovitch theorem:

We choose balls in a greedy way. First choose a ball with maximal radius (or rather, since there
is no guarantee the maximal radius is realized, a ball with radius within a factor `τ` of the
supremum). Then, remove all balls whose center is covered by the first ball, and choose among the
remaining ones a ball with radius close to maximum. Go on forever until there is no available
center (this is a transfinite induction in general).

Then define inductively a coloring of the balls. A ball will be of color `i` if it intersects
already chosen balls of color `0`, ..., `i - 1`, but none of color `i`. In this way, balls of the
same color form a disjoint family, and the space is covered by the families of the different colors.

The nontrivial part is to show that at most `N` colors are used. If one needs `N+1` colors, consider
the first time this happens. Then the corresponding ball intersects `N` balls of the different
colors. Moreover, the inductive construction ensures that the radii of all the balls are controlled:
they form a satellite configuration with `N+1` balls (essentially by definition of satellite
configurations). Since we assume that there are no such configurations, this is a contradiction.

#### Sketch of proof of the measurable Besicovitch theorem:

From the topological Besicovitch theorem, one can find a disjoint countable family of balls
covering a proportion `> 1/(N+1)` of the space. Taking a large enough finite subset of these balls,
one gets the same property for finitely many balls. Their union is closed. Therefore, any point in
the complement has around it an admissible ball not intersecting these finitely many balls. Applying
again the topological Besicovitch theorem, one extracts from these a disjoint countable subfamily
covering a proportion `> 1/(N+1)` of the remaining points, and then even a disjoint finite
subfamily. Then one goes on again and again, covering at each step a positive proportion of the
remaining points, while remaining disjoint from the already chosen balls. The union of all these
balls is the desired almost everywhere covering.
-/


noncomputable section 

universe u

open Metric Set Filter Finₓ MeasureTheory TopologicalSpace

open_locale TopologicalSpace Classical BigOperators Ennreal MeasureTheory Nnreal

/-!
### Satellite configurations
-/


-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr < » last N)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (i «expr < » last N)
/-- A satellite configuration is a configuration of `N+1` points that shows up in the inductive
construction for the Besicovitch covering theorem. It depends on some parameter `τ ≥ 1`.

This is a family of balls (indexed by `i : fin N.succ`, with center `c i` and radius `r i`) such
that the last ball intersects all the other balls (condition `inter`),
and given any two balls there is an order between them, ensuring that the first ball does not
contain the center of the other one, and the radius of the second ball can not be larger than
the radius of the first ball (up to a factor `τ`). This order corresponds to the order of choice
in the inductive construction: otherwise, the second ball would have been chosen before.
This is the condition `h`.

Finally, the last ball is chosen after all the other ones, meaning that `h` can be strengthened
by keeping only one side of the alternative in `hlast`.
-/
structure Besicovitch.SatelliteConfig (α : Type _) [MetricSpace α] (N : ℕ) (τ : ℝ) where 
  c : Finₓ N.succ → α 
  R : Finₓ N.succ → ℝ 
  rpos : ∀ i, 0 < r i 
  h : ∀ i j, i ≠ j → (r i ≤ dist (c i) (c j) ∧ r j ≤ τ*r i) ∨ r j ≤ dist (c j) (c i) ∧ r i ≤ τ*r j 
  hlast : ∀ i _ : i < last N, r i ≤ dist (c i) (c (last N)) ∧ r (last N) ≤ τ*r i 
  inter : ∀ i _ : i < last N, dist (c i) (c (last N)) ≤ r i+r (last N)

/-- A metric space has the Besicovitch covering property if there exist `N` and `τ > 1` such that
there are no satellite configuration of parameter `τ` with `N+1` points. This is the condition that
guarantees that the measurable Besicovitch covering theorem holds. It is satified by
finite-dimensional real vector spaces. -/
class HasBesicovitchCovering (α : Type _) [MetricSpace α] : Prop where 
  no_satellite_config : ∃ (N : ℕ)(τ : ℝ), 1 < τ ∧ IsEmpty (Besicovitch.SatelliteConfig α N τ)

/-- There is always a satellite configuration with a single point. -/
instance {α : Type _} {τ : ℝ} [Inhabited α] [MetricSpace α] : Inhabited (Besicovitch.SatelliteConfig α 0 τ) :=
  ⟨{ c := fun i => default α, R := fun i => 1, rpos := fun i => zero_lt_one,
      h := fun i j hij => (hij (Subsingleton.elimₓ i j)).elim,
      hlast :=
        fun i hi =>
          by 
            rw [Subsingleton.elimₓ i (last 0)] at hi 
            exact (lt_irreflₓ _ hi).elim,
      inter :=
        fun i hi =>
          by 
            rw [Subsingleton.elimₓ i (last 0)] at hi 
            exact (lt_irreflₓ _ hi).elim }⟩

namespace Besicovitch

namespace SatelliteConfig

variable {α : Type _} [MetricSpace α] {N : ℕ} {τ : ℝ} (a : satellite_config α N τ)

theorem inter' (i : Finₓ N.succ) : dist (a.c i) (a.c (last N)) ≤ a.r i+a.r (last N) :=
  by 
    rcases lt_or_leₓ i (last N) with (H | H)
    ·
      exact a.inter i H
    ·
      have I : i = last N := top_le_iff.1 H 
      have  := (a.rpos (last N)).le 
      simp only [I, add_nonneg this this, dist_self]

theorem hlast' (i : Finₓ N.succ) (h : 1 ≤ τ) : a.r (last N) ≤ τ*a.r i :=
  by 
    rcases lt_or_leₓ i (last N) with (H | H)
    ·
      exact (a.hlast i H).2
    ·
      have  : i = last N := top_le_iff.1 H 
      rw [this]
      exact le_mul_of_one_le_left (a.rpos _).le h

end SatelliteConfig

/-! ### Extracting disjoint subfamilies from a ball covering -/


/-- A ball package is a family of balls in a metric space with positive bounded radii. -/
structure ball_package (β : Type _) (α : Type _) where 
  c : β → α 
  R : β → ℝ 
  rpos : ∀ b, 0 < r b 
  rBound : ℝ 
  r_le : ∀ b, r b ≤ r_bound

/-- The ball package made of unit balls. -/
def unit_ball_package (α : Type _) : ball_package α α :=
  { c := id, R := fun _ => 1, rpos := fun _ => zero_lt_one, rBound := 1, r_le := fun _ => le_rfl }

instance (α : Type _) : Inhabited (ball_package α α) :=
  ⟨unit_ball_package α⟩

/-- A Besicovitch tau-package is a family of balls in a metric space with positive bounded radii,
together with enough data to proceed with the Besicovitch greedy algorithm. We register this in
a single structure to make sure that all our constructions in this algorithm only depend on
one variable. -/
structure tau_package (β : Type _) (α : Type _) extends ball_package β α where 
  τ : ℝ 
  one_lt_tau : 1 < τ

instance (α : Type _) : Inhabited (tau_package α α) :=
  ⟨{ unit_ball_package α with τ := 2, one_lt_tau := one_lt_two }⟩

variable {α : Type _} [MetricSpace α] {β : Type u}

namespace TauPackage

variable [Nonempty β] (p : tau_package β α)

include p

/-- Choose inductively large balls with centers that are not contained in the union of already
chosen balls. This is a transfinite induction. -/
noncomputable def index : Ordinal.{u} → β
| i =>
  let Z := ⋃ j : { j // j < i }, ball (p.c (index j)) (p.r (index j))
  let R := supr fun b : { b : β // p.c b ∉ Z } => p.r b 
  Classical.epsilon fun b : β => p.c b ∉ Z ∧ R ≤ p.τ*p.r b

/-- The set of points that are covered by the union of balls selected at steps `< i`. -/
def Union_up_to (i : Ordinal.{u}) : Set α :=
  ⋃ j : { j // j < i }, ball (p.c (p.index j)) (p.r (p.index j))

theorem monotone_Union_up_to : Monotone p.Union_up_to :=
  by 
    intro i j hij 
    simp only [Union_up_to]
    apply Union_subset_Union2 
    intro r 
    exact ⟨⟨r, r.2.trans_le hij⟩, subset.refl _⟩

/-- Supremum of the radii of balls whose centers are not yet covered at step `i`. -/
def R (i : Ordinal.{u}) : ℝ :=
  supr fun b : { b : β // p.c b ∉ p.Union_up_to i } => p.r b

/-- Group the balls into disjoint families, by assigning to a ball the smallest color for which
it does not intersect any already chosen ball of this color. -/
noncomputable def color : Ordinal.{u} → ℕ
| i =>
  let A : Set ℕ :=
    ⋃ (j : { j // j < i })(hj :
      (closed_ball (p.c (p.index j)) (p.r (p.index j)) ∩ closed_ball (p.c (p.index i)) (p.r (p.index i))).Nonempty),
      {color j}
  Inf (univ \ A)

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    `p.last_step` is the first ordinal where the construction stops making sense, i.e., `f` returns
    garbage since there is no point left to be chosen. We will only use ordinals before this step. -/
  def last_step : Ordinal .{ u } := Inf { i | ¬ ∃ b : β , p.c b ∉ p.Union_up_to i ∧ p.R i ≤ p.τ * p.r b }

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
theorem
  last_step_nonempty
  : { i | ¬ ∃ b : β , p.c b ∉ p.Union_up_to i ∧ p.R i ≤ p.τ * p.r b } . Nonempty
  :=
    by
      byContra
        suffices H : Function.Injective p.index
        exact not_injective_of_ordinal p.index H
        intro x y hxy
        wlog x_le_y : x ≤ y := le_totalₓ x y using x y , y x
        rcases eq_or_lt_of_le x_le_y with ( rfl | H )
        · rfl
        simp
          only
          [ nonempty_def , not_exists , exists_prop , not_and , not_ltₓ , not_leₓ , mem_set_of_eq , not_forall ]
          at h
        specialize h y
        have A : p.c p.index y ∉ p.Union_up_to y
        ·
          have : p.index y = Classical.epsilon fun b : β => p.c b ∉ p.Union_up_to y ∧ p.R y ≤ p.τ * p.r b
            · · rw [ tau_package.index ] rfl
            rw [ this ]
            exact Classical.epsilon_spec h . 1
        simp
          only
          [
            Union_up_to
              ,
              not_exists
              ,
              exists_prop
              ,
              mem_Union
              ,
              mem_closed_ball
              ,
              not_and
              ,
              not_leₓ
              ,
              Subtype.exists
              ,
              Subtype.coe_mk
            ]
          at A
        specialize A x H
        simp [ hxy ] at A
        exact lt_irreflₓ _ p.rpos p.index y . trans_le A . elim

-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/-- Every point is covered by chosen balls, before `p.last_step`. -/
  theorem
    mem_Union_up_to_last_step
    ( x : β ) : p.c x ∈ p.Union_up_to p.last_step
    :=
      by
        have A : ∀ z : β , p.c z ∈ p.Union_up_to p.last_step ∨ p.τ * p.r z < p.R p.last_step
          ·
            have
                : p.last_step ∈ { i | ¬ ∃ b : β , p.c b ∉ p.Union_up_to i ∧ p.R i ≤ p.τ * p.r b }
                  :=
                  Inf_mem p.last_step_nonempty
              simpa only [ not_exists , mem_set_of_eq , not_and_distrib , not_leₓ , not_not_mem ]
          byContra
          rcases A x with ( H | H )
          · exact h H
          have Rpos : 0 < p.R p.last_step
          · apply lt_transₓ mul_pos _root_.zero_lt_one.trans p.one_lt_tau p.rpos _ H
          have B : p.τ ⁻¹ * p.R p.last_step < p.R p.last_step
          ·
            convRHS => rw [ ← one_mulₓ p.R p.last_step ]
              exact mul_lt_mul inv_lt_one p.one_lt_tau le_rfl Rpos zero_le_one
          obtain ⟨ y , hy1 , hy2 ⟩ : ∃ y : β , p.c y ∉ p.Union_up_to p.last_step ∧ p.τ ⁻¹ * p.R p.last_step < p.r y
          ·
            simpa
                only
                [ exists_prop , mem_range , exists_exists_and_eq_and , Subtype.exists , Subtype.coe_mk ]
                using exists_lt_of_lt_cSup _ B
              rw [ ← image_univ , nonempty_image_iff ]
              exact ⟨ ⟨ _ , h ⟩ , mem_univ _ ⟩
          rcases A y with ( Hy | Hy )
          · exact hy1 Hy
          ·
            rw [ ← div_eq_inv_mul ] at hy2
              have := div_le_iff' _root_.zero_lt_one.trans p.one_lt_tau . 1 hy2.le
              exact lt_irreflₓ _ Hy.trans_le this

/-- If there are no configurations of satellites with `N+1` points, one never uses more than `N`
distinct families in the Besicovitch inductive construction. -/
theorem color_lt {i : Ordinal.{u}} (hi : i < p.last_step) {N : ℕ} (hN : IsEmpty (satellite_config α N p.τ)) :
  p.color i < N :=
  by 
    induction' i using Ordinal.induction with i IH 
    let A : Set ℕ :=
      ⋃ (j : { j // j < i })(hj :
        (closed_ball (p.c (p.index j)) (p.r (p.index j)) ∩ closed_ball (p.c (p.index i)) (p.r (p.index i))).Nonempty),
        {p.color j}
    have color_i : p.color i = Inf (univ \ A)
    ·
      rw [color]
    rw [color_i]
    have N_mem : N ∈ univ \ A
    ·
      simp only [not_exists, true_andₓ, exists_prop, mem_Union, mem_singleton_iff, mem_closed_ball, not_and, mem_univ,
        mem_diff, Subtype.exists, Subtype.coe_mk]
      intro j ji hj 
      exact (IH j ji (ji.trans hi)).ne' 
    suffices  : Inf (univ \ A) ≠ N
    ·
      rcases(cInf_le (OrderBot.bdd_below (univ \ A)) N_mem).lt_or_eq with (H | H)
      ·
        exact H
      ·
        exact (this H).elim 
    intro Inf_eq_N 
    have  :
      ∀ k,
        k < N →
          ∃ j,
            j < i ∧
              (closed_ball (p.c (p.index j)) (p.r (p.index j)) ∩
                    closed_ball (p.c (p.index i)) (p.r (p.index i))).Nonempty ∧
                k = p.color j
    ·
      intro k hk 
      rw [←Inf_eq_N] at hk 
      have  : k ∈ A
      ·
        simpa only [true_andₓ, mem_univ, not_not, mem_diff] using Nat.not_mem_of_lt_Inf hk 
      simp  at this 
      simpa only [exists_prop, mem_Union, mem_singleton_iff, mem_closed_ball, Subtype.exists, Subtype.coe_mk]
    choose! g hg using this 
    let G : ℕ → Ordinal := fun n => if n = N then i else g n 
    have color_G : ∀ n, n ≤ N → p.color (G n) = n
    ·
      intro n hn
      (
        rcases hn.eq_or_lt with (rfl | H))
      ·
        simp only [G]
        simp only [color_i, Inf_eq_N, if_true, eq_self_iff_true]
      ·
        simp only [G]
        simp only [H.ne, (hg n H).right.right.symm, if_false]
    have G_lt_last : ∀ n, n ≤ N → G n < p.last_step
    ·
      intro n hn
      (
        rcases hn.eq_or_lt with (rfl | H))
      ·
        simp only [G]
        simp only [hi, if_true, eq_self_iff_true]
      ·
        simp only [G]
        simp only [H.ne, (hg n H).left.trans hi, if_false]
    have fGn : ∀ n, n ≤ N → p.c (p.index (G n)) ∉ p.Union_up_to (G n) ∧ p.R (G n) ≤ p.τ*p.r (p.index (G n))
    ·
      intro n hn 
      have  : p.index (G n) = Classical.epsilon fun t => p.c t ∉ p.Union_up_to (G n) ∧ p.R (G n) ≤ p.τ*p.r t
      ·
        ·
          rw [index]
          rfl 
      rw [this]
      have  : ∃ t, p.c t ∉ p.Union_up_to (G n) ∧ p.R (G n) ≤ p.τ*p.r t
      ·
        simpa only [not_exists, exists_prop, not_and, not_ltₓ, not_leₓ, mem_set_of_eq, not_forall] using
          not_mem_of_lt_cInf (G_lt_last n hn) (OrderBot.bdd_below _)
      exact Classical.epsilon_spec this 
    have Gab :
      ∀ a b : Finₓ (Nat.succ N),
        G a < G b →
          p.r (p.index (G a)) ≤ dist (p.c (p.index (G a))) (p.c (p.index (G b))) ∧
            p.r (p.index (G b)) ≤ p.τ*p.r (p.index (G a))
    ·
      intro a b G_lt 
      have ha : (a : ℕ) ≤ N := Nat.lt_succ_iff.1 a.2
      have hb : (b : ℕ) ≤ N := Nat.lt_succ_iff.1 b.2
      constructor
      ·
        have  := (fGn b hb).1
        simp only [Union_up_to, not_exists, exists_prop, mem_Union, mem_closed_ball, not_and, not_leₓ, Subtype.exists,
          Subtype.coe_mk] at this 
        simpa only [dist_comm, mem_ball, not_ltₓ] using this (G a) G_lt
      ·
        apply le_transₓ _ (fGn a ha).2
        have B : p.c (p.index (G b)) ∉ p.Union_up_to (G a)
        ·
          intro H 
          exact (fGn b hb).1 (p.monotone_Union_up_to G_lt.le H)
        let b' : { t // p.c t ∉ p.Union_up_to (G a) } := ⟨p.index (G b), B⟩
        apply @le_csupr _ _ _ (fun t : { t // p.c t ∉ p.Union_up_to (G a) } => p.r t) _ b' 
        refine' ⟨p.r_bound, fun t ht => _⟩
        simp only [exists_prop, mem_range, Subtype.exists, Subtype.coe_mk] at ht 
        rcases ht with ⟨u, hu⟩
        rw [←hu.2]
        exact p.r_le _ 
    let sc : satellite_config α N p.τ :=
      { c := fun k => p.c (p.index (G k)), R := fun k => p.r (p.index (G k)), rpos := fun k => p.rpos (p.index (G k)),
        h :=
          by 
            intro a b a_ne_b 
            wlog (discharger := tactic.skip) G_le : G a ≤ G b := le_totalₓ (G a) (G b) using a b, b a
            ·
              have G_lt : G a < G b
              ·
                rcases G_le.lt_or_eq with (H | H)
                ·
                  exact H 
                have A : (a : ℕ) ≠ b := fin.coe_injective.ne a_ne_b 
                rw [←color_G a (Nat.lt_succ_iff.1 a.2), ←color_G b (Nat.lt_succ_iff.1 b.2), H] at A 
                exact (A rfl).elim 
              exact Or.inl (Gab a b G_lt)
            ·
              intro a_ne_b 
              rw [or_comm]
              exact this a_ne_b.symm,
        hlast :=
          by 
            intro a ha 
            have I : (a : ℕ) < N := ha 
            have  : G a < G (Finₓ.last N)
            ·
              ·
                dsimp [G]
                simp [I.ne, (hg a I).1]
            exact Gab _ _ this,
        inter :=
          by 
            intro a ha 
            have I : (a : ℕ) < N := ha 
            have J : G (Finₓ.last N) = i
            ·
              ·
                dsimp [G]
                simp only [if_true, eq_self_iff_true]
            have K : G a = g a
            ·
              dsimp [G]
              simp [I.ne, (hg a I).1]
            convert dist_le_add_of_nonempty_closed_ball_inter_closed_ball (hg _ I).2.1 }
    exact (hN.false : _) sc

end TauPackage

open TauPackage

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (j «expr ∈ » s i)
/-- The topological Besicovitch covering theorem: there exist finitely many families of disjoint
balls covering all the centers in a package. More specifically, one can use `N` families if there
are no satellite configurations with `N+1` points. -/
theorem exist_disjoint_covering_families {N : ℕ} {τ : ℝ} (hτ : 1 < τ) (hN : IsEmpty (satellite_config α N τ))
  (q : ball_package β α) :
  ∃ s : Finₓ N → Set β,
    (∀ i : Finₓ N, (s i).PairwiseDisjoint fun j => closed_ball (q.c j) (q.r j)) ∧
      range q.c ⊆ ⋃ i : Finₓ N, ⋃ (j : _)(_ : j ∈ s i), ball (q.c j) (q.r j) :=
  by 
    cases' is_empty_or_nonempty β
    ·
      refine' ⟨fun i => ∅, fun i => pairwise_disjoint_empty, _⟩
      rw [←image_univ, eq_empty_of_is_empty (univ : Set β)]
      simp 
    let p : tau_package β α := { q with τ, one_lt_tau := hτ }
    let s := fun i : Finₓ N => ⋃ (k : Ordinal.{u})(hk : k < p.last_step)(h'k : p.color k = i), ({p.index k} : Set β)
    refine' ⟨s, fun i => _, _⟩
    ·
      intro x hx y hy x_ne_y 
      obtain ⟨jx, jx_lt, jxi, rfl⟩ : ∃ jx : Ordinal, jx < p.last_step ∧ p.color jx = i ∧ x = p.index jx
      ·
        simpa only [exists_prop, mem_Union, mem_singleton_iff] using hx 
      obtain ⟨jy, jy_lt, jyi, rfl⟩ : ∃ jy : Ordinal, jy < p.last_step ∧ p.color jy = i ∧ y = p.index jy
      ·
        simpa only [exists_prop, mem_Union, mem_singleton_iff] using hy 
      wlog (discharger := tactic.skip) jxy : jx ≤ jy := le_totalₓ jx jy using jx jy, jy jx 
      swap
      ·
        intro h1 h2 h3 h4 h5 h6 h7 
        rw [Function.onFun, Disjoint.comm]
        exact this h4 h5 h6 h1 h2 h3 h7.symm 
      replace jxy : jx < jy
      ·
        ·
          rcases lt_or_eq_of_leₓ jxy with (H | rfl)
          ·
            exact H
          ·
            exact (x_ne_y rfl).elim 
      let A : Set ℕ :=
        ⋃ (j : { j // j < jy })(hj :
          (closed_ball (p.c (p.index j)) (p.r (p.index j)) ∩
              closed_ball (p.c (p.index jy)) (p.r (p.index jy))).Nonempty),
          {p.color j}
      have color_j : p.color jy = Inf (univ \ A)
      ·
        rw [tau_package.color]
      have  : p.color jy ∈ univ \ A
      ·
        rw [color_j]
        apply Inf_mem 
        refine' ⟨N, _⟩
        simp only [not_exists, true_andₓ, exists_prop, mem_Union, mem_singleton_iff, not_and, mem_univ, mem_diff,
          Subtype.exists, Subtype.coe_mk]
        intro k hk H 
        exact (p.color_lt (hk.trans jy_lt) hN).ne' 
      simp only [not_exists, true_andₓ, exists_prop, mem_Union, mem_singleton_iff, not_and, mem_univ, mem_diff,
        Subtype.exists, Subtype.coe_mk] at this 
      specialize this jx jxy 
      contrapose! this 
      simpa only [jxi, jyi, and_trueₓ, eq_self_iff_true, ←not_disjoint_iff_nonempty_inter]
    ·
      refine' range_subset_iff.2 fun b => _ 
      obtain ⟨a, ha⟩ : ∃ a : Ordinal, a < p.last_step ∧ dist (p.c b) (p.c (p.index a)) < p.r (p.index a)
      ·
        simpa only [Union_up_to, exists_prop, mem_Union, mem_ball, Subtype.exists, Subtype.coe_mk] using
          p.mem_Union_up_to_last_step b 
      simp only [exists_prop, mem_Union, mem_ball, mem_singleton_iff, bUnion_and', exists_eq_left, Union_exists,
        exists_and_distrib_left]
      exact ⟨⟨p.color a, p.color_lt ha.1 hN⟩, p.index a, ⟨a, rfl, ha.1, rfl⟩, ha.2⟩

/-!
### The measurable Besicovitch covering theorem
-/


open_locale Nnreal

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » w)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » w)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
/-- Consider, for each `x` in a set `s`, a radius `r x ∈ (0, 1]`. Then one can find finitely
many disjoint balls of the form `closed_ball x (r x)` covering a proportion `1/(N+1)` of `s`, if
there are no satellite configurations with `N+1` points.
-/
theorem exist_finset_disjoint_balls_large_measure [second_countable_topology α] [MeasurableSpace α]
  [OpensMeasurableSpace α] (μ : Measureₓ α) [is_finite_measure μ] {N : ℕ} {τ : ℝ} (hτ : 1 < τ)
  (hN : IsEmpty (satellite_config α N τ)) (s : Set α) (r : α → ℝ) (rpos : ∀ x _ : x ∈ s, 0 < r x)
  (rle : ∀ x _ : x ∈ s, r x ≤ 1) :
  ∃ t : Finset α,
    ↑t ⊆ s ∧
      (μ (s \ ⋃ (x : _)(_ : x ∈ t), closed_ball x (r x)) ≤ (N / N+1)*μ s) ∧
        (t : Set α).PairwiseDisjoint fun x => closed_ball x (r x) :=
  by 
    rcases le_or_ltₓ (μ s) 0 with (hμs | hμs)
    ·
      have  : μ s = 0 := le_bot_iff.1 hμs 
      refine'
        ⟨∅,
          by 
            simp only [Finset.coe_empty, empty_subset],
          _, _⟩
      ·
        simp only [this, diff_empty, Union_false, Union_empty, nonpos_iff_eq_zero, mul_zero]
      ·
        simp only [Finset.coe_empty, pairwise_disjoint_empty]
    cases' is_empty_or_nonempty α
    ·
      simp only [eq_empty_of_is_empty s, measure_empty] at hμs 
      exact (lt_irreflₓ _ hμs).elim 
    have Npos : N ≠ 0
    ·
      (
        rintro rfl)
      inhabit α 
      exact (not_is_empty_of_nonempty _) hN 
    obtain ⟨o, so, omeas, μo⟩ : ∃ o : Set α, s ⊆ o ∧ MeasurableSet o ∧ μ o = μ s := exists_measurable_superset μ s 
    let a : ball_package s α :=
      { c := fun x => x, R := fun x => r x, rpos := fun x => rpos x x.2, rBound := 1, r_le := fun x => rle x x.2 }
    rcases exist_disjoint_covering_families hτ hN a with ⟨u, hu, hu'⟩
    have u_count : ∀ i, countable (u i)
    ·
      intro i 
      refine' (hu i).countable_of_nonempty_interior fun j hj => _ 
      have  : (ball (j : α) (r j)).Nonempty := nonempty_ball.2 (a.rpos _)
      exact this.mono ball_subset_interior_closed_ball 
    let v : Finₓ N → Set α := fun i => ⋃ (x : s)(hx : x ∈ u i), closed_ball x (r x)
    have  : ∀ i, MeasurableSet (v i) :=
      fun i => MeasurableSet.bUnion (u_count i) fun b hb => measurable_set_closed_ball 
    have A : s = ⋃ i : Finₓ N, s ∩ v i
    ·
      refine' subset.antisymm _ (Union_subset fun i => inter_subset_left _ _)
      intro x hx 
      obtain ⟨i, y, hxy, h'⟩ : ∃ (i : Finₓ N)(i_1 : ↥s)(i : i_1 ∈ u i), x ∈ ball (↑i_1) (r (↑i_1))
      ·
        have  : x ∈ range a.c
        ·
          simpa only [Subtype.range_coe_subtype, set_of_mem_eq]
        simpa only [mem_Union] using hu' this 
      refine' mem_Union.2 ⟨i, ⟨hx, _⟩⟩
      simp only [v, exists_prop, mem_Union, SetCoe.exists, exists_and_distrib_right, Subtype.coe_mk]
      exact
        ⟨y,
          ⟨y.2,
            by 
              simpa only [Subtype.coe_eta]⟩,
          ball_subset_closed_ball h'⟩
    have S : (∑ i : Finₓ N, μ s / N) ≤ ∑ i, μ (s ∩ v i) :=
      calc (∑ i : Finₓ N, μ s / N) = μ s :=
        by 
          simp only [Finset.card_fin, Finset.sum_const, nsmul_eq_mul]
          rw [Ennreal.mul_div_cancel']
          ·
            simp only [Npos, Ne.def, Nat.cast_eq_zero, not_false_iff]
          ·
            exact Ennreal.coe_nat_ne_top 
        _ ≤ ∑ i, μ (s ∩ v i) :=
        by 
          convLHS => rw [A]
          apply measure_Union_fintype_le 
        
    obtain ⟨i, -, hi⟩ : ∃ (i : Finₓ N)(hi : i ∈ Finset.univ), μ s / N ≤ μ (s ∩ v i)
    ·
      apply Ennreal.exists_le_of_sum_le _ S 
      exact ⟨⟨0, bot_lt_iff_ne_bot.2 Npos⟩, Finset.mem_univ _⟩
    replace hi : (μ s / N+1) < μ (s ∩ v i)
    ·
      apply lt_of_lt_of_leₓ _ hi 
      apply (Ennreal.mul_lt_mul_left hμs.ne' (measure_lt_top μ s).Ne).2
      rw [Ennreal.inv_lt_inv]
      convLHS => rw [←add_zeroₓ (N : ℝ≥0∞)]
      exact Ennreal.add_lt_add_left (Ennreal.nat_ne_top N) Ennreal.zero_lt_one 
    have B : μ (o ∩ v i) = ∑' x : u i, μ (o ∩ closed_ball x (r x))
    ·
      have  : o ∩ v i = ⋃ (x : s)(hx : x ∈ u i), o ∩ closed_ball x (r x)
      ·
        simp only [inter_Union]
      rw [this, measure_bUnion (u_count i)]
      ·
        rfl
      ·
        exact (hu i).mono fun k => inter_subset_right _ _
      ·
        exact fun b hb => omeas.inter measurable_set_closed_ball 
    obtain ⟨w, hw⟩ : ∃ w : Finset (u i), (μ s / N+1) < ∑ x : u i in w, μ (o ∩ closed_ball (x : α) (r (x : α)))
    ·
      have C : HasSum (fun x : u i => μ (o ∩ closed_ball x (r x))) (μ (o ∩ v i))
      ·
        ·
          rw [B]
          exact ennreal.summable.has_sum 
      have  : (μ s / N+1) < μ (o ∩ v i) := hi.trans_le (measure_mono (inter_subset_inter_left _ so))
      exact ((tendsto_order.1 C).1 _ this).exists 
    refine' ⟨Finset.image (fun x : u i => x) w, _, _, _⟩
    ·
      simp only [image_subset_iff, coe_coe, Finset.coe_image]
      intro y hy 
      simp only [Subtype.coe_prop, mem_preimage]
    ·
      suffices H : μ (o \ ⋃ (x : _)(_ : x ∈ w), closed_ball (↑x) (r (↑x))) ≤ (N / N+1)*μ s
      ·
        rw [Finset.set_bUnion_finset_image]
        exact le_transₓ (measure_mono (diff_subset_diff so (subset.refl _))) H 
      rw [←diff_inter_self_eq_diff, measure_diff_le_iff_le_add _ omeas (inter_subset_right _ _) (measure_lt_top μ _).Ne]
      swap
      ·
        apply MeasurableSet.inter _ omeas 
        have  : Encodable (u i) := (u_count i).toEncodable 
        exact MeasurableSet.Union fun b => MeasurableSet.Union_Prop fun hb => measurable_set_closed_ball 
      calc μ o = ((1 / N+1)*μ s)+(N / N+1)*μ s :=
        by 
          rw [μo, ←add_mulₓ, Ennreal.div_add_div_same, add_commₓ, Ennreal.div_self, one_mulₓ] <;>
            simp _ ≤ μ ((⋃ (x : _)(_ : x ∈ w), closed_ball (↑x) (r (↑x))) ∩ o)+(N / N+1)*μ s :=
        by 
          refine' add_le_add _ le_rfl 
          rw [div_eq_mul_inv, one_mulₓ, mul_commₓ, ←div_eq_mul_inv]
          apply hw.le.trans (le_of_eqₓ _)
          rw [←Finset.set_bUnion_coe, inter_comm _ o, inter_bUnion, Finset.set_bUnion_coe, measure_bUnion_finset]
          ·
            have  : (w : Set (u i)).PairwiseDisjoint fun b : u i => closed_ball (b : α) (r (b : α))
            ·
              ·
                intro k hk l hl hkl 
                exact hu i k.2 l.2 (subtype.coe_injective.ne hkl)
            exact this.mono fun k => inter_subset_right _ _
          ·
            intro b hb 
            apply omeas.inter measurable_set_closed_ball
    ·
      intro k hk l hl hkl 
      obtain ⟨k', k'w, rfl⟩ : ∃ k' : u i, k' ∈ w ∧ ↑↑k' = k
      ·
        simpa only [mem_image, Finset.mem_coe, coe_coe, Finset.coe_image] using hk 
      obtain ⟨l', l'w, rfl⟩ : ∃ l' : u i, l' ∈ w ∧ ↑↑l' = l
      ·
        simpa only [mem_image, Finset.mem_coe, coe_coe, Finset.coe_image] using hl 
      have k'nel' : (k' : s) ≠ l'
      ·
        ·
          intro h 
          rw [h] at hkl 
          exact hkl rfl 
      exact hu i k'.2 l'.2 k'nel'

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s')
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (r «expr ∈ » f x)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » v)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s')
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s')
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
/-- The measurable Besicovitch covering theorem. Assume that, for any `x` in a set `s`,
one is given a set of admissible closed balls centered at `x`, with arbitrarily small radii.
Then there exists a disjoint covering of almost all `s` by admissible closed balls centered at some
points of `s`.
This version requires that the underlying measure is finite, and that the space has the Besicovitch
covering property (which is satisfied for instance by normed real vector spaces). It expresses the
conclusion in a slightly awkward form (with a subset of `α × ℝ`) coming from the proof technique.
For a version assuming that the measure is sigma-finite,
see `exists_disjoint_closed_ball_covering_ae_aux`.
For a version giving the conclusion in a nicer form, see `exists_disjoint_closed_ball_covering_ae`.
-/
theorem exists_disjoint_closed_ball_covering_ae_of_finite_measure_aux [second_countable_topology α]
  [hb : HasBesicovitchCovering α] [MeasurableSpace α] [OpensMeasurableSpace α] (μ : Measureₓ α) [is_finite_measure μ]
  (f : α → Set ℝ) (s : Set α) (hf : ∀ x _ : x ∈ s, (f x).Nonempty) (hf' : ∀ x _ : x ∈ s, f x ⊆ Ioi 0)
  (hf'' : ∀ x _ : x ∈ s, Inf (f x) ≤ 0) :
  ∃ t : Set (α × ℝ),
    countable t ∧
      (∀ p : α × ℝ, p ∈ t → p.1 ∈ s) ∧
        (∀ p : α × ℝ, p ∈ t → p.2 ∈ f p.1) ∧
          μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ t), closed_ball p.1 p.2) = 0 ∧
            t.pairwise_disjoint fun p => closed_ball p.1 p.2 :=
  by 
    rcases hb.no_satellite_config with ⟨N, τ, hτ, hN⟩
    let P : Finset (α × ℝ) → Prop :=
      fun t =>
        ((t : Set (α × ℝ)).PairwiseDisjoint fun p => closed_ball p.1 p.2) ∧
          (∀ p : α × ℝ, p ∈ t → p.1 ∈ s) ∧ ∀ p : α × ℝ, p ∈ t → p.2 ∈ f p.1
    have  :
      ∀ t : Finset (α × ℝ),
        P t →
          ∃ u : Finset (α × ℝ),
            t ⊆ u ∧
              P u ∧
                μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ u), closed_ball p.1 p.2) ≤
                  (N / N+1)*μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ t), closed_ball p.1 p.2)
    ·
      intro t ht 
      set B := ⋃ (p : α × ℝ)(hp : p ∈ t), closed_ball p.1 p.2 with hB 
      have B_closed : IsClosed B := is_closed_bUnion (Finset.finite_to_set _) fun i hi => is_closed_ball 
      set s' := s \ B with hs' 
      have  : ∀ x _ : x ∈ s', ∃ (r : _)(_ : r ∈ f x), r ≤ 1 ∧ Disjoint B (closed_ball x r)
      ·
        intro x hx 
        have xs : x ∈ s := ((mem_diff x).1 hx).1
        rcases eq_empty_or_nonempty B with (hB | hB)
        ·
          have  : (0 : ℝ) < 1 := zero_lt_one 
          rcases exists_lt_of_cInf_lt (hf x xs) ((hf'' x xs).trans_lt zero_lt_one) with ⟨r, hr, h'r⟩
          exact
            ⟨r, hr, h'r.le,
              by 
                simp only [hB, empty_disjoint]⟩
        ·
          let R := inf_dist x B 
          have  : 0 < min R 1 := lt_minₓ ((B_closed.not_mem_iff_inf_dist_pos hB).1 ((mem_diff x).1 hx).2) zero_lt_one 
          rcases exists_lt_of_cInf_lt (hf x xs) ((hf'' x xs).trans_lt this) with ⟨r, hr, h'r⟩
          refine' ⟨r, hr, h'r.le.trans (min_le_rightₓ _ _), _⟩
          rw [Disjoint.comm]
          exact disjoint_closed_ball_of_lt_inf_dist (h'r.trans_le (min_le_leftₓ _ _))
      choose! r hr using this 
      obtain ⟨v, vs', hμv, hv⟩ :
        ∃ v : Finset α,
          ↑v ⊆ s' ∧
            (μ (s' \ ⋃ (x : _)(_ : x ∈ v), closed_ball x (r x)) ≤ (N / N+1)*μ s') ∧
              (v : Set α).PairwiseDisjoint fun x : α => closed_ball x (r x)
      ·
        have rpos : ∀ x _ : x ∈ s', 0 < r x := fun x hx => hf' x ((mem_diff x).1 hx).1 (hr x hx).1
        have rle : ∀ x _ : x ∈ s', r x ≤ 1 := fun x hx => (hr x hx).2.1 
        exact exist_finset_disjoint_balls_large_measure μ hτ hN s' r rpos rle 
      refine' ⟨t ∪ Finset.image (fun x => (x, r x)) v, Finset.subset_union_left _ _, ⟨_, _, _⟩, _⟩
      ·
        simp only [Finset.coe_union, pairwise_disjoint_union, ht.1, true_andₓ, Finset.coe_image]
        constructor
        ·
          intro p hp q hq hpq 
          rcases(mem_image _ _ _).1 hp with ⟨p', p'v, rfl⟩
          rcases(mem_image _ _ _).1 hq with ⟨q', q'v, rfl⟩
          refine' hv p'v q'v fun hp'q' => _ 
          rw [hp'q'] at hpq 
          exact hpq rfl
        ·
          intro p hp q hq hpq 
          rcases(mem_image _ _ _).1 hq with ⟨q', q'v, rfl⟩
          apply disjoint_of_subset_left _ (hr q' (vs' q'v)).2.2
          rw [hB, ←Finset.set_bUnion_coe]
          exact subset_bUnion_of_mem hp
      ·
        intro p hp 
        rcases Finset.mem_union.1 hp with (h'p | h'p)
        ·
          exact ht.2.1 p h'p
        ·
          rcases Finset.mem_image.1 h'p with ⟨p', p'v, rfl⟩
          exact ((mem_diff _).1 (vs' (Finset.mem_coe.2 p'v))).1
      ·
        intro p hp 
        rcases Finset.mem_union.1 hp with (h'p | h'p)
        ·
          exact ht.2.2 p h'p
        ·
          rcases Finset.mem_image.1 h'p with ⟨p', p'v, rfl⟩
          dsimp 
          exact (hr p' (vs' p'v)).1
      ·
        convert hμv using 2
        rw [Finset.set_bUnion_union, ←diff_diff, Finset.set_bUnion_finset_image]
    choose! F hF using this 
    let u := fun n => (F^[n]) ∅
    have u_succ : ∀ n : ℕ, u n.succ = F (u n) :=
      fun n =>
        by 
          simp only [u, Function.comp_app, Function.iterate_succ']
    have Pu : ∀ n, P (u n)
    ·
      intro n 
      induction' n with n IH
      ·
        simp only [u, P, Prod.forall, id.def, Function.iterate_zero]
        simp only [Finset.not_mem_empty, forall_false_left, Finset.coe_empty, forall_2_true_iff, and_selfₓ,
          pairwise_disjoint_empty]
      ·
        rw [u_succ]
        exact (hF (u n) IH).2.1
    refine' ⟨⋃ n, u n, countable_Union fun n => (u n).countable_to_set, _, _, _, _⟩
    ·
      intro p hp 
      rcases mem_Union.1 hp with ⟨n, hn⟩
      exact (Pu n).2.1 p (Finset.mem_coe.1 hn)
    ·
      intro p hp 
      rcases mem_Union.1 hp with ⟨n, hn⟩
      exact (Pu n).2.2 p (Finset.mem_coe.1 hn)
    ·
      have A :
        ∀ n,
          μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ ⋃ n : ℕ, (u n : Set (α × ℝ))), closed_ball p.fst p.snd) ≤
            μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ u n), closed_ball p.fst p.snd)
      ·
        intro n 
        apply measure_mono 
        apply diff_subset_diff (subset.refl _)
        exact bUnion_subset_bUnion_left (subset_Union (fun i => (u i : Set (α × ℝ))) n)
      have B : ∀ n, μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ u n), closed_ball p.fst p.snd) ≤ ((N / N+1)^n)*μ s
      ·
        intro n 
        induction' n with n IH
        ·
          simp only [le_reflₓ, diff_empty, one_mulₓ, Union_false, Union_empty, pow_zeroₓ]
        calc
          μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ u n.succ), closed_ball p.fst p.snd) ≤
            (N / N+1)*μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ u n), closed_ball p.fst p.snd) :=
          by 
            rw [u_succ]
            exact (hF (u n) (Pu n)).2.2_ ≤ ((N / N+1)^n.succ)*μ s :=
          by 
            rw [pow_succₓ, mul_assocₓ]
            exact Ennreal.mul_le_mul le_rfl IH 
      have C : tendsto (fun n : ℕ => (((N : ℝ≥0∞) / N+1)^n)*μ s) at_top (𝓝 (0*μ s))
      ·
        apply Ennreal.Tendsto.mul_const _ (Or.inr (measure_lt_top μ s).Ne)
        apply Ennreal.tendsto_pow_at_top_nhds_0_of_lt_1 
        rw [Ennreal.div_lt_iff, one_mulₓ]
        ·
          convLHS => rw [←add_zeroₓ (N : ℝ≥0∞)]
          exact Ennreal.add_lt_add_left (Ennreal.nat_ne_top N) Ennreal.zero_lt_one
        ·
          simp only [true_orₓ, add_eq_zero_iff, Ne.def, not_false_iff, one_ne_zero, and_falseₓ]
        ·
          simp only [Ennreal.nat_ne_top, Ne.def, not_false_iff, or_trueₓ]
      rw [zero_mul] at C 
      apply le_bot_iff.1 
      exact le_of_tendsto_of_tendsto' tendsto_const_nhds C fun n => (A n).trans (B n)
    ·
      refine' (pairwise_disjoint_Union _).2 fun n => (Pu n).1
      apply (monotone_nat_of_le_succ fun n => _).directed_le 
      rw [u_succ]
      exact (hF (u n) (Pu n)).1

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
/-- The measurable Besicovitch covering theorem. Assume that, for any `x` in a set `s`,
one is given a set of admissible closed balls centered at `x`, with arbitrarily small radii.
Then there exists a disjoint covering of almost all `s` by admissible closed balls centered at some
points of `s`.
This version requires that the underlying measure is sigma-finite, and that the space has the
Besicovitch covering property (which is satisfied for instance by normed real vector spaces).
It expresses the conclusion in a slightly awkward form (with a subset of `α × ℝ`) coming from the
proof technique.
For a version giving the conclusion in a nicer form, see `exists_disjoint_closed_ball_covering_ae`.
-/
theorem exists_disjoint_closed_ball_covering_ae_aux [second_countable_topology α] [HasBesicovitchCovering α]
  [MeasurableSpace α] [OpensMeasurableSpace α] (μ : Measureₓ α) [sigma_finite μ] (f : α → Set ℝ) (s : Set α)
  (hf : ∀ x _ : x ∈ s, (f x).Nonempty) (hf' : ∀ x _ : x ∈ s, f x ⊆ Ioi 0) (hf'' : ∀ x _ : x ∈ s, Inf (f x) ≤ 0) :
  ∃ t : Set (α × ℝ),
    countable t ∧
      (∀ p : α × ℝ, p ∈ t → p.1 ∈ s) ∧
        (∀ p : α × ℝ, p ∈ t → p.2 ∈ f p.1) ∧
          μ (s \ ⋃ (p : α × ℝ)(hp : p ∈ t), closed_ball p.1 p.2) = 0 ∧
            t.pairwise_disjoint fun p => closed_ball p.1 p.2 :=
  by 
    (
      rcases exists_absolutely_continuous_is_finite_measure μ with ⟨ν, hν, hμν⟩)
    rcases exists_disjoint_closed_ball_covering_ae_of_finite_measure_aux ν f s hf hf' hf'' with
      ⟨t, t_count, ts, tr, tν, tdisj⟩
    exact ⟨t, t_count, ts, tr, hμν tν, tdisj⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
    The measurable Besicovitch covering theorem. Assume that, for any `x` in a set `s`,
    one is given a set of admissible closed balls centered at `x`, with arbitrarily small radii.
    Then there exists a disjoint covering of almost all `s` by admissible closed balls centered at some
    points of `s`.
    This version requires that the underlying measure is sigma-finite, and that the space has the
    Besicovitch covering property (which is satisfied for instance by normed real vector spaces).
    -/
  theorem
    exists_disjoint_closed_ball_covering_ae
    [ second_countable_topology α ]
        [ hb : HasBesicovitchCovering α ]
        [ MeasurableSpace α ]
        [ OpensMeasurableSpace α ]
        ( μ : Measureₓ α )
        [ sigma_finite μ ]
        ( f : α → Set ℝ )
        ( s : Set α )
        ( hf : ∀ x _ : x ∈ s , f x . Nonempty )
        ( hf' : ∀ x _ : x ∈ s , f x ⊆ Ioi 0 )
        ( hf'' : ∀ x _ : x ∈ s , Inf f x ≤ 0 )
      :
        ∃
          ( t : Set α ) ( r : α → ℝ )
          ,
          countable t
            ∧
            t ⊆ s
              ∧
              ∀ x _ : x ∈ t , r x ∈ f x
                ∧
                μ s \ ⋃ ( x : _ ) ( _ : x ∈ t ) , closed_ball x r x = 0 ∧ t.pairwise_disjoint fun x => closed_ball x r x
    :=
      by
        rcases
            exists_disjoint_closed_ball_covering_ae_aux μ f s hf hf' hf''
            with ⟨ v , v_count , vs , vf , μv , v_disj ⟩
          let t := Prod.fst '' v
          have : ∀ x _ : x ∈ t , ∃ r : ℝ , ( x , r ) ∈ v
          · intro x hx rcases mem_image _ _ _ . 1 hx with ⟨ ⟨ p , q ⟩ , hp , rfl ⟩ exact ⟨ q , hp ⟩
          choose! r hr using this
          have im_t : fun x => ( x , r x ) '' t = v
          ·
            have I : ∀ p : α × ℝ , p ∈ v → 0 ≤ p . 2 := fun p hp => le_of_ltₓ hf' _ vs _ hp vf _ hp
              apply subset.antisymm
              ·
                simp only [ image_subset_iff ]
                  rintro ⟨ x , p ⟩ hxp
                  simp only [ mem_preimage ]
                  exact hr _ mem_image_of_mem _ hxp
              ·
                rintro ⟨ x , p ⟩ hxp
                  have hxrx : ( x , r x ) ∈ v := hr _ mem_image_of_mem _ hxp
                  have : p = r x
                  ·
                    byContra
                      have A : ( x , p ) ≠ ( x , r x )
                      · simpa only [ true_andₓ , Prod.mk.inj_iffₓ , eq_self_iff_true , Ne.def ] using h
                      have H := v_disj hxp hxrx A
                      contrapose H
                      rw [ not_disjoint_iff_nonempty_inter ]
                      refine' ⟨ x , by simp [ I _ hxp , I _ hxrx ] ⟩
                  rw [ this ]
                  apply mem_image_of_mem
                  exact mem_image_of_mem _ hxp
          refine' ⟨ t , r , v_count.image _ , _ , _ , _ , _ ⟩
          · intro x hx rcases mem_image _ _ _ . 1 hx with ⟨ ⟨ p , q ⟩ , hp , rfl ⟩ exact vs _ hp
          · intro x hx rcases mem_image _ _ _ . 1 hx with ⟨ ⟨ p , q ⟩ , hp , rfl ⟩ exact vf _ hr _ hx
          ·
            have
                :
                  ⋃ ( x : α ) ( H : x ∈ t ) , closed_ball x r x
                    =
                    ⋃ ( p : α × ℝ ) ( H : p ∈ fun x => ( x , r x ) '' t ) , closed_ball p . 1 p . 2
              · convRHS => rw [ bUnion_image ]
              rw [ this , im_t ]
              exact μv
          ·
            have A : inj_on fun x : α => ( x , r x ) t
              ·
                simp
                  ( config := { contextual := Bool.true._@._internal._hyg.0 } )
                  only
                  [ inj_on , Prod.mk.inj_iffₓ , implies_true_iff , eq_self_iff_true ]
              rwa [ ← im_t , A.pairwise_disjoint_image ] at v_disj

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » s)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » t)
-- failed to parenthesize: parenthesize: uncaught backtrack exception
-- failed to format: format: uncaught backtrack exception
/--
      In a space with the Besicovitch covering property, the set of closed balls with positive radius
      forms a Vitali family. This is essentially a restatement of the measurable Besicovitch theorem. -/
    protected
  def
    VitaliFamily
    [ second_countable_topology α ]
        [ HasBesicovitchCovering α ]
        [ MeasurableSpace α ]
        [ OpensMeasurableSpace α ]
        ( μ : Measureₓ α )
        [ sigma_finite μ ]
      : VitaliFamily μ
    :=
      {
        SetsAt := fun x => fun r : ℝ => closed_ball x r '' Ioi ( 0 : ℝ ) ,
          MeasurableSet'
              :=
              by
                intro x y hy
                  obtain ⟨ r , rpos , rfl ⟩ : ∃ r : ℝ , 0 < r ∧ closed_ball x r = y
                  · simpa only [ mem_image , mem_Ioi ] using hy
                  exact is_closed_ball.measurable_set
            ,
          nonempty_interior
              :=
              by
                intro x y hy
                  obtain ⟨ r , rpos , rfl ⟩ : ∃ r : ℝ , 0 < r ∧ closed_ball x r = y
                  · simpa only [ mem_image , mem_Ioi ] using hy
                  simp only [ nonempty.mono ball_subset_interior_closed_ball , rpos , nonempty_ball ]
            ,
          Nontrivial := fun x ε εpos => ⟨ closed_ball x ε , mem_image_of_mem _ εpos , subset.refl _ ⟩ ,
          covering
            :=
            by
              intro s f fsubset ffine
                let g : α → Set ℝ := fun x => { r | 0 < r ∧ closed_ball x r ∈ f x }
                have A : ∀ x _ : x ∈ s , g x . Nonempty
                ·
                  intro x xs
                    obtain
                      ⟨ t , tf , ht ⟩
                      : ∃ ( t : Set α ) ( H : t ∈ f x ) , t ⊆ closed_ball x 1
                      := ffine x xs 1 zero_lt_one
                    obtain ⟨ r , rpos , rfl ⟩ : ∃ r : ℝ , 0 < r ∧ closed_ball x r = t
                    · simpa using fsubset x xs tf
                    exact ⟨ r , rpos , tf ⟩
                have B : ∀ x _ : x ∈ s , g x ⊆ Ioi ( 0 : ℝ )
                · intro x xs r hr replace hr : 0 < r ∧ closed_ball x r ∈ f x · simpa only using hr exact hr . 1
                have C : ∀ x _ : x ∈ s , Inf g x ≤ 0
                ·
                  intro x xs
                    have g_bdd : BddBelow g x := ⟨ 0 , fun r hr => hr . 1 . le ⟩
                    refine' le_of_forall_le_of_dense fun ε εpos => _
                    obtain ⟨ t , tf , ht ⟩ : ∃ ( t : Set α ) ( H : t ∈ f x ) , t ⊆ closed_ball x ε := ffine x xs ε εpos
                    obtain ⟨ r , rpos , rfl ⟩ : ∃ r : ℝ , 0 < r ∧ closed_ball x r = t
                    · simpa using fsubset x xs tf
                    rcases le_totalₓ r ε with ( H | H )
                    · exact cInf_le g_bdd ⟨ rpos , tf ⟩ . trans H
                    ·
                      have : closed_ball x r = closed_ball x ε := subset.antisymm ht closed_ball_subset_closed_ball H
                        rw [ this ] at tf
                        exact cInf_le g_bdd ⟨ εpos , tf ⟩
                obtain
                  ⟨ t , r , t_count , ts , tg , μt , tdisj ⟩
                  :
                    ∃
                      ( t : Set α ) ( r : α → ℝ )
                      ,
                      countable t
                        ∧
                        t ⊆ s
                          ∧
                          ∀ x _ : x ∈ t , r x ∈ g x
                            ∧
                            μ s \ ⋃ ( x : _ ) ( _ : x ∈ t ) , closed_ball x r x = 0
                              ∧
                              t.pairwise_disjoint fun x => closed_ball x r x
                  := exists_disjoint_closed_ball_covering_ae μ g s A B C
                exact ⟨ t , fun x => closed_ball x r x , ts , tdisj , fun x xt => tg x xt . 2 , μt ⟩
        }

end Besicovitch

