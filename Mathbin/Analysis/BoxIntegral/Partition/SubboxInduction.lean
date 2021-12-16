import Mathbin.Analysis.BoxIntegral.Box.SubboxInduction 
import Mathbin.Analysis.BoxIntegral.Partition.Tagged

/-!
# Induction on subboxes

In this file we prove (see
`box_integral.tagged_partition.exists_is_Henstock_is_subordinate_homothetic`) that for every box `I`
in `ℝⁿ` and a function `r : ℝⁿ → ℝ` positive on `I` there exists a tagged partition `π` of `I` such
that

* `π` is a Henstock partition;
* `π` is subordinate to `r`;
* each box in `π` is homothetic to `I` with coefficient of the form `1 / 2 ^ n`.

Later we will use this lemma to prove that the Henstock filter is nontrivial, hence the Henstock
integral is well-defined.

## Tags

partition, tagged partition, Henstock integral
-/


namespace BoxIntegral

open Set Metric

open_locale Classical TopologicalSpace

noncomputable section 

variable {ι : Type _} [Fintype ι] {I J : box ι}

namespace Prepartition

/-- Split a box in `ℝⁿ` into `2 ^ n` boxes by hyperplanes passing through its center. -/
def split_center (I : box ι) : prepartition I :=
  { boxes := Finset.univ.map (box.split_center_box_emb I),
    le_of_mem' :=
      by 
        simp [I.split_center_box_le],
    PairwiseDisjoint :=
      by 
        rw [Finset.coe_map, Finset.coe_univ, image_univ]
        rintro _ ⟨s, rfl⟩ _ ⟨t, rfl⟩ Hne 
        exact I.disjoint_split_center_box (mt (congr_argₓ _) Hne) }

@[simp]
theorem mem_split_center : J ∈ split_center I ↔ ∃ s, I.split_center_box s = J :=
  by 
    simp [split_center]

theorem is_partition_split_center (I : box ι) : is_partition (split_center I) :=
  fun x hx =>
    by 
      simp [hx]

theorem upper_sub_lower_of_mem_split_center (h : J ∈ split_center I) (i : ι) :
  J.upper i - J.lower i = (I.upper i - I.lower i) / 2 :=
  let ⟨s, hs⟩ := mem_split_center.1 h 
  hs ▸ I.upper_sub_lower_split_center_box s i

end Prepartition

namespace Box

open Prepartition TaggedPrepartition

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (J «expr ≤ » I)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (J' «expr ∈ » split_center J)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (z «expr ∈ » I.Icc)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (U «expr ∈ » «expr𝓝[ ] »(I.Icc, z))
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (J «expr ≤ » I)
/-- Let `p` be a predicate on `box ι`, let `I` be a box. Suppose that the following two properties
hold true.

* Consider a smaller box `J ≤ I`. The hyperplanes passing through the center of `J` split it into
  `2 ^ n` boxes. If `p` holds true on each of these boxes, then it true on `J`.
* For each `z` in the closed box `I.Icc` there exists a neighborhood `U` of `z` within `I.Icc` such
  that for every box `J ≤ I` such that `z ∈ J.Icc ⊆ U`, if `J` is homothetic to `I` with a
  coefficient of the form `1 / 2 ^ m`, then `p` is true on `J`.

Then `p I` is true. See also `box_integral.box.subbox_induction_on'` for a version using
`box_integral.box.split_center_box` instead of `box_integral.prepartition.split_center`. -/
@[elab_as_eliminator]
theorem subbox_induction_on {p : box ι → Prop} (I : box ι)
  (H_ind : ∀ J _ : J ≤ I, (∀ J' _ : J' ∈ split_center J, p J') → p J)
  (H_nhds :
    ∀ z _ : z ∈ I.Icc,
      ∃ (U : _)(_ : U ∈ 𝓝[I.Icc] z),
        ∀ J _ : J ≤ I m : ℕ,
          z ∈ J.Icc → J.Icc ⊆ U → (∀ i, J.upper i - J.lower i = (I.upper i - I.lower i) / 2 ^ m) → p J) :
  p I :=
  by 
    refine' subbox_induction_on' I (fun J hle hs => H_ind J hle$ fun J' h' => _) H_nhds 
    rcases mem_split_center.1 h' with ⟨s, rfl⟩
    exact hs s

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (J' «expr ∈ » (split_center J).bUnion_tagged πi)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (J «expr ∈ » π)
/-- Given a box `I` in `ℝⁿ` and a function `r : ℝⁿ → (0, ∞)`, there exists a tagged partition `π` of
`I` such that

* `π` is a Henstock partition;
* `π` is subordinate to `r`;
* each box in `π` is homothetic to `I` with coefficient of the form `1 / 2 ^ m`.

This lemma implies that the Henstock filter is nontrivial, hence the Henstock integral is
well-defined. -/
theorem exists_tagged_partition_is_Henstock_is_subordinate_homothetic (I : box ι) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  ∃ π : tagged_prepartition I,
    π.is_partition ∧
      π.is_Henstock ∧
        π.is_subordinate r ∧
          (∀ J _ : J ∈ π, ∃ m : ℕ, ∀ i, (J : _).upper i - J.lower i = (I.upper i - I.lower i) / 2 ^ m) ∧
            π.distortion = I.distortion :=
  by 
    refine' subbox_induction_on I (fun J hle hJ => _) fun z hz => _
    ·
      choose! πi hP hHen hr Hn Hd using hJ 
      choose! n hn using Hn 
      have hP : ((split_center J).bUnionTagged πi).IsPartition 
      exact (is_partition_split_center _).bUnionTagged hP 
      have hsub :
        ∀ J' _ : J' ∈ (split_center J).bUnionTagged πi,
          ∃ n : ℕ, ∀ i, (J' : _).upper i - J'.lower i = (J.upper i - J.lower i) / 2 ^ n
      ·
        intro J' hJ' 
        rcases(split_center J).mem_bUnion_tagged.1 hJ' with ⟨J₁, h₁, h₂⟩
        refine' ⟨n J₁ J'+1, fun i => _⟩
        simp only [hn J₁ h₁ J' h₂, upper_sub_lower_of_mem_split_center h₁, pow_succₓ, div_div_eq_div_mul]
      refine' ⟨_, hP, is_Henstock_bUnion_tagged.2 hHen, is_subordinate_bUnion_tagged.2 hr, hsub, _⟩
      refine' tagged_prepartition.distortion_of_const _ hP.nonempty_boxes fun J' h' => _ 
      rcases hsub J' h' with ⟨n, hn⟩
      exact box.distortion_eq_of_sub_eq_div hn
    ·
      refine' ⟨I.Icc ∩ closed_ball z (r z), inter_mem_nhds_within _ (closed_ball_mem_nhds _ (r z).coe_prop), _⟩
      intro J Hle n Hmem HIcc Hsub 
      rw [Set.subset_inter_iff] at HIcc 
      refine'
        ⟨single _ _ le_rfl _ Hmem, is_partition_single _, is_Henstock_single _, (is_subordinate_single _ _).2 HIcc.2, _,
          distortion_single _ _⟩
      simp only [tagged_prepartition.mem_single, forall_eq]
      refine' ⟨0, fun i => _⟩
      simp 

end Box

namespace Prepartition

open TaggedPrepartition Finset Function

/-- Given a box `I` in `ℝⁿ`, a function `r : ℝⁿ → (0, ∞)`, and a prepartition `π` of `I`, there
exists a tagged prepartition `π'` of `I` such that

* each box of `π'` is included in some box of `π`;
* `π'` is a Henstock partition;
* `π'` is subordinate to `r`;
* `π'` covers exactly the same part of `I` as `π`;
* the distortion of `π'` is equal to the distortion of `π`.
-/
theorem exists_tagged_le_is_Henstock_is_subordinate_Union_eq {I : box ι} (r : (ι → ℝ) → Ioi (0 : ℝ))
  (π : prepartition I) :
  ∃ π' : tagged_prepartition I,
    π'.to_prepartition ≤ π ∧ π'.is_Henstock ∧ π'.is_subordinate r ∧ π'.distortion = π.distortion ∧ π'.Union = π.Union :=
  by 
    have  := fun J => box.exists_tagged_partition_is_Henstock_is_subordinate_homothetic J r 
    choose! πi πip πiH πir hsub πid 
    clear hsub 
    refine'
      ⟨π.bUnion_tagged πi, bUnion_le _ _, is_Henstock_bUnion_tagged.2 fun J _ => πiH J,
        is_subordinate_bUnion_tagged.2 fun J _ => πir J, _, π.Union_bUnion_partition fun J _ => πip J⟩
    rw [distortion_bUnion_tagged]
    exact sup_congr rfl fun J _ => πid J

/-- Given a prepartition `π` of a box `I` and a function `r : ℝⁿ → (0, ∞)`, `π.to_subordinate r`
is a tagged partition `π'` such that

* each box of `π'` is included in some box of `π`;
* `π'` is a Henstock partition;
* `π'` is subordinate to `r`;
* `π'` covers exactly the same part of `I` as `π`;
* the distortion of `π'` is equal to the distortion of `π`.
-/
def to_subordinate (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) : tagged_prepartition I :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some

theorem to_subordinate_to_prepartition_le (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  (π.to_subordinate r).toPrepartition ≤ π :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some_spec.1

theorem is_Henstock_to_subordinate (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) : (π.to_subordinate r).IsHenstock :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some_spec.2.1

theorem is_subordinate_to_subordinate (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  (π.to_subordinate r).IsSubordinate r :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some_spec.2.2.1

@[simp]
theorem distortion_to_subordinate (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  (π.to_subordinate r).distortion = π.distortion :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some_spec.2.2.2.1

@[simp]
theorem Union_to_subordinate (π : prepartition I) (r : (ι → ℝ) → Ioi (0 : ℝ)) : (π.to_subordinate r).Union = π.Union :=
  (π.exists_tagged_le_is_Henstock_is_subordinate_Union_eq r).some_spec.2.2.2.2

end Prepartition

namespace TaggedPrepartition

/-- Given a tagged prepartition `π₁`, a prepartition `π₂` that covers exactly `I \ π₁.Union`, and
a function `r : ℝⁿ → (0, ∞)`, returns the union of `π₁` and `π₂.to_subordinate r`. This partition
`π` has the following properties:

* `π` is a partition, i.e. it covers the whole `I`;
* `π₁.boxes ⊆ π.boxes`;
* `π.tag J = π₁.tag J` whenever `J ∈ π₁`;
* `π` is Henstock outside of `π₁`: `π.tag J ∈ J.Icc` whenever `J ∈ π`, `J ∉ π₁`;
* `π` is subordinate to `r` outside of `π₁`;
* the distortion of `π` is equal to the maximum of the distortions of `π₁` and `π₂`.
-/
def union_compl_to_subordinate (π₁ : tagged_prepartition I) (π₂ : prepartition I) (hU : π₂.Union = I \ π₁.Union)
  (r : (ι → ℝ) → Ioi (0 : ℝ)) : tagged_prepartition I :=
  π₁.disj_union (π₂.to_subordinate r) (((π₂.Union_to_subordinate r).trans hU).symm ▸ disjoint_diff)

theorem is_partition_union_compl_to_subordinate (π₁ : tagged_prepartition I) (π₂ : prepartition I)
  (hU : π₂.Union = I \ π₁.Union) (r : (ι → ℝ) → Ioi (0 : ℝ)) : is_partition (π₁.union_compl_to_subordinate π₂ hU r) :=
  prepartition.is_partition_disj_union_of_eq_diff ((π₂.Union_to_subordinate r).trans hU)

@[simp]
theorem union_compl_to_subordinate_boxes (π₁ : tagged_prepartition I) (π₂ : prepartition I)
  (hU : π₂.Union = I \ π₁.Union) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  (π₁.union_compl_to_subordinate π₂ hU r).boxes = π₁.boxes ∪ (π₂.to_subordinate r).boxes :=
  rfl

@[simp]
theorem Union_union_compl_to_subordinate_boxes (π₁ : tagged_prepartition I) (π₂ : prepartition I)
  (hU : π₂.Union = I \ π₁.Union) (r : (ι → ℝ) → Ioi (0 : ℝ)) : (π₁.union_compl_to_subordinate π₂ hU r).Union = I :=
  (is_partition_union_compl_to_subordinate _ _ _ _).Union_eq

@[simp]
theorem distortion_union_compl_to_subordinate (π₁ : tagged_prepartition I) (π₂ : prepartition I)
  (hU : π₂.Union = I \ π₁.Union) (r : (ι → ℝ) → Ioi (0 : ℝ)) :
  (π₁.union_compl_to_subordinate π₂ hU r).distortion = max π₁.distortion π₂.distortion :=
  by 
    simp [union_compl_to_subordinate]

end TaggedPrepartition

end BoxIntegral

