import Mathbin.Algebra.Order.Ring 
import Mathbin.Data.Nat.Basic 
import Mathbin.Data.Set.Lattice 
import Mathbin.Order.Directed 
import Mathbin.Tactic.Monotonicity.Basic

variable{α : Type _}

@[mono]
theorem mul_mono_nonneg {x y z : α} [OrderedSemiring α] (h' : 0 ≤ z) (h : x ≤ y) : (x*z) ≤ y*z :=
  by 
    apply mul_le_mul_of_nonneg_right <;> assumption

theorem lt_of_mul_lt_mul_neg_right {a b c : α} [LinearOrderedRing α] (h : (a*c) < b*c) (hc : c ≤ 0) : b < a :=
  have nhc : -c ≥ 0 := neg_nonneg_of_nonpos hc 
  have h2 : (-b*c) < -a*c := neg_lt_neg h 
  have h3 : (b*-c) < a*-c :=
    calc (b*-c) = -b*c :=
      by 
        rw [neg_mul_eq_mul_neg]
      _ < -a*c := h2 
      _ = a*-c :=
      by 
        rw [neg_mul_eq_mul_neg]
      
  lt_of_mul_lt_mul_right h3 nhc

@[mono]
theorem mul_mono_nonpos {x y z : α} [LinearOrderedRing α] (h' : z ≤ 0) (h : y ≤ x) : (x*z) ≤ y*z :=
  by 
    classical 
    byContra h'' 
    revert h 
    apply not_le_of_lt 
    apply lt_of_mul_lt_mul_neg_right _ h' 
    apply lt_of_not_geₓ h''

-- error in Tactic.Monotonicity.Lemmas: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: no declaration of attribute [parenthesizer] found for 'Lean.Meta.solveByElim'
@[mono #[]]
theorem nat.sub_mono_left_strict
{x y z : exprℕ()}
(h' : «expr ≤ »(z, x))
(h : «expr < »(x, y)) : «expr < »(«expr - »(x, z), «expr - »(y, z)) :=
begin
  have [] [":", expr «expr ≤ »(z, y)] [],
  { transitivity [],
    assumption,
    apply [expr le_of_lt h] },
  apply [expr @nat.lt_of_add_lt_add_left z],
  rw ["[", expr add_tsub_cancel_of_le, ",", expr add_tsub_cancel_of_le, "]"] []; solve_by_elim [] [] [] []
end

-- error in Tactic.Monotonicity.Lemmas: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
@[mono #[]]
theorem nat.sub_mono_right_strict
{x y z : exprℕ()}
(h' : «expr ≤ »(x, z))
(h : «expr < »(y, x)) : «expr < »(«expr - »(z, x), «expr - »(z, y)) :=
begin
  have [ident h''] [":", expr «expr ≤ »(y, z)] [],
  { transitivity [],
    apply [expr le_of_lt h],
    assumption },
  apply [expr @nat.lt_of_add_lt_add_right _ x],
  rw ["[", expr tsub_add_cancel_of_le h', "]"] [],
  apply [expr @lt_of_le_of_lt _ _ _ «expr + »(«expr - »(z, y), y)],
  rw ["[", expr tsub_add_cancel_of_le h'', "]"] [],
  apply [expr nat.add_lt_add_left h]
end

open Set

attribute [mono] inter_subset_inter union_subset_union sUnion_mono bUnion_mono sInter_subset_sInter bInter_mono
  image_subset preimage_mono prod_mono monotone_prod seq_mono image2_subset OrderEmbedding.monotone

attribute [mono] upper_bounds_mono_set lower_bounds_mono_set upper_bounds_mono_mem lower_bounds_mono_mem
  upper_bounds_mono lower_bounds_mono BddAbove.mono BddBelow.mono

attribute [mono] add_le_add mul_le_mul neg_le_neg mul_lt_mul_of_pos_left mul_lt_mul_of_pos_right imp_imp_imp
  le_implies_le_of_le_of_le sub_le_sub tsub_le_tsub tsub_le_tsub_right abs_le_abs sup_le_sup inf_le_inf

attribute [mono left] add_lt_add_of_le_of_lt mul_lt_mul'

attribute [mono right] add_lt_add_of_lt_of_le mul_lt_mul

