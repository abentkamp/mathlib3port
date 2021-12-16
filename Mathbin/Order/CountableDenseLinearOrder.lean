import Mathbin.Order.Ideal

/-!
# The back and forth method and countable dense linear orders

## Results

Suppose `α β` are linear orders, with `α` countable and `β` dense, nonempty, without endpoints.
Then there is an order embedding `α ↪ β`. If in addition `α` is dense, nonempty, without
endpoints and `β` is countable, then we can upgrade this to an order isomorphism `α ≃ β`.

The idea for both results is to consider "partial isomorphisms", which
identify a finite subset of `α` with a finite subset of `β`, and prove that
for any such partial isomorphism `f` and `a : α`, we can extend `f` to
include `a` in its domain.

## References

https://en.wikipedia.org/wiki/Back-and-forth_method

## Tags

back and forth, dense, countable, order

-/


noncomputable section 

open_locale Classical

namespace Order

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » lo)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » hi)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » lo)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » hi)
/-- Suppose `α` is a nonempty dense linear order without endpoints, and
    suppose `lo`, `hi`, are finite subssets with all of `lo` strictly
    before `hi`. Then there is an element of `α` strictly between `lo`
    and `hi`. -/
theorem exists_between_finsets {α : Type _} [LinearOrderₓ α] [DenselyOrdered α] [NoBotOrder α] [NoTopOrder α]
  [nonem : Nonempty α] (lo hi : Finset α) (lo_lt_hi : ∀ x _ : x ∈ lo y _ : y ∈ hi, x < y) :
  ∃ m : α, (∀ x _ : x ∈ lo, x < m) ∧ ∀ y _ : y ∈ hi, m < y :=
  if nlo : lo.nonempty then
    if nhi : hi.nonempty then
      Exists.elim (exists_between (lo_lt_hi _ (Finset.max'_mem _ nlo) _ (Finset.min'_mem _ nhi)))
        fun m hm =>
          ⟨m, fun x hx => lt_of_le_of_ltₓ (Finset.le_max' lo x hx) hm.1,
            fun y hy => lt_of_lt_of_leₓ hm.2 (Finset.min'_le hi y hy)⟩
    else
      Exists.elim (no_top (Finset.max' lo nlo))
        fun m hm => ⟨m, fun x hx => lt_of_le_of_ltₓ (Finset.le_max' lo x hx) hm, fun y hy => (nhi ⟨y, hy⟩).elim⟩
  else
    if nhi : hi.nonempty then
      Exists.elim (no_bot (Finset.min' hi nhi))
        fun m hm => ⟨m, fun x hx => (nlo ⟨x, hx⟩).elim, fun y hy => lt_of_lt_of_leₓ hm (Finset.min'_le hi y hy)⟩
    else nonem.elim fun m => ⟨m, fun x hx => (nlo ⟨x, hx⟩).elim, fun y hy => (nhi ⟨y, hy⟩).elim⟩

variable (α β : Type _) [LinearOrderₓ α] [LinearOrderₓ β]

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p q «expr ∈ » f)
/-- The type of partial order isomorphisms between `α` and `β` defined on finite subsets.
    A partial order isomorphism is encoded as a finite subset of `α × β`, consisting
    of pairs which should be identified. -/
def partial_iso : Type _ :=
  { f : Finset (α × β) // ∀ p q _ : p ∈ f _ : q ∈ f, cmp (Prod.fst p) (Prod.fst q) = cmp (Prod.snd p) (Prod.snd q) }

namespace PartialIso

instance : Inhabited (partial_iso α β) :=
  ⟨⟨∅, fun p q h => h.elim⟩⟩

instance : Preorderₓ (partial_iso α β) :=
  Subtype.preorder _

variable {α β}

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (x «expr ∈ » (f.val.filter (λ p : «expr × »(α, β), «expr < »(p.fst, a))).image prod.snd)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (y «expr ∈ » (f.val.filter (λ p : «expr × »(α, β), «expr < »(a, p.fst))).image prod.snd)
-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (p «expr ∈ » f.val)
/-- For each `a`, we can find a `b` in the codomain, such that `a`'s relation to
the domain of `f` is `b`'s relation to the image of `f`.

Thus, if `a` is not already in `f`, then we can extend `f` by sending `a` to `b`.
-/
theorem exists_across [DenselyOrdered β] [NoBotOrder β] [NoTopOrder β] [Nonempty β] (f : partial_iso α β) (a : α) :
  ∃ b : β, ∀ p _ : p ∈ f.val, cmp (Prod.fst p) a = cmp (Prod.snd p) b :=
  by 
    byCases' h : ∃ b, (a, b) ∈ f.val
    ·
      cases' h with b hb 
      exact ⟨b, fun p hp => f.property _ _ hp hb⟩
    have  :
      ∀ x _ : x ∈ (f.val.filter fun p : α × β => p.fst < a).Image Prod.snd y _ :
        y ∈ (f.val.filter fun p : α × β => a < p.fst).Image Prod.snd, x < y
    ·
      intro x hx y hy 
      rw [Finset.mem_image] at hx hy 
      rcases hx with ⟨p, hp1, rfl⟩
      rcases hy with ⟨q, hq1, rfl⟩
      rw [Finset.mem_filter] at hp1 hq1 
      rw [←lt_iff_lt_of_cmp_eq_cmp (f.property _ _ hp1.1 hq1.1)]
      exact lt_transₓ hp1.right hq1.right 
    cases' exists_between_finsets _ _ this with b hb 
    use b 
    rintro ⟨p1, p2⟩ hp 
    have  : p1 ≠ a := fun he => h ⟨p2, he ▸ hp⟩
    cases' lt_or_gt_of_neₓ this with hl hr
    ·
      have  : p1 < a ∧ p2 < b := ⟨hl, hb.1 _ (finset.mem_image.mpr ⟨(p1, p2), finset.mem_filter.mpr ⟨hp, hl⟩, rfl⟩)⟩
      rw [←cmp_eq_lt_iff, ←cmp_eq_lt_iff] at this 
      cc
    ·
      have  : a < p1 ∧ b < p2 := ⟨hr, hb.2 _ (finset.mem_image.mpr ⟨(p1, p2), finset.mem_filter.mpr ⟨hp, hr⟩, rfl⟩)⟩
      rw [←cmp_eq_gt_iff, ←cmp_eq_gt_iff] at this 
      cc

/-- A partial isomorphism between `α` and `β` is also a partial isomorphism between `β` and `α`. -/
protected def comm : partial_iso α β → partial_iso β α :=
  Subtype.map (Finset.image (Equivₓ.prodComm _ _))$
    fun f hf p q hp hq =>
      Eq.symm$
        hf ((Equivₓ.prodComm α β).symm p) ((Equivₓ.prodComm α β).symm q)
          (by 
            rw [←Finset.mem_coe, Finset.coe_image, Equivₓ.image_eq_preimage] at hp 
            rwa [←Finset.mem_coe])
          (by 
            rw [←Finset.mem_coe, Finset.coe_image, Equivₓ.image_eq_preimage] at hq 
            rwa [←Finset.mem_coe])

variable (β)

/-- The set of partial isomorphisms defined at `a : α`, together with a proof that any
    partial isomorphism can be extended to one defined at `a`. -/
def defined_at_left [DenselyOrdered β] [NoBotOrder β] [NoTopOrder β] [Nonempty β] (a : α) : cofinal (partial_iso α β) :=
  { Carrier := fun f => ∃ b : β, (a, b) ∈ f.val,
    mem_gt :=
      by 
        intro f 
        cases' exists_across f a with b a_b 
        refine' ⟨⟨insert (a, b) f.val, _⟩, ⟨b, Finset.mem_insert_self _ _⟩, Finset.subset_insert _ _⟩
        intro p q hp hq 
        rw [Finset.mem_insert] at hp hq 
        rcases hp with (rfl | pf) <;> rcases hq with (rfl | qf)
        ·
          simp 
        ·
          rw [cmp_eq_cmp_symm]
          exact a_b _ qf
        ·
          exact a_b _ pf
        ·
          exact f.property _ _ pf qf }

variable (α) {β}

/-- The set of partial isomorphisms defined at `b : β`, together with a proof that any
    partial isomorphism can be extended to include `b`. We prove this by symmetry. -/
def defined_at_right [DenselyOrdered α] [NoBotOrder α] [NoTopOrder α] [Nonempty α] (b : β) :
  cofinal (partial_iso α β) :=
  { Carrier := fun f => ∃ a, (a, b) ∈ f.val,
    mem_gt :=
      by 
        intro f 
        rcases(defined_at_left α b).mem_gt f.comm with ⟨f', ⟨a, ha⟩, hl⟩
        use f'.comm 
        constructor
        ·
          use a 
          change (a, b) ∈ f'.val.image _ 
          rwa [←Finset.mem_coe, Finset.coe_image, Equivₓ.image_eq_preimage]
        ·
          change _ ⊆ f'.val.image _ 
          rw [←Finset.coe_subset, Finset.coe_image, ←Equivₓ.subset_image]
          change f.val.image _ ⊆ _ at hl 
          rwa [←Finset.coe_subset, Finset.coe_image] at hl }

variable {α}

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (f «expr ∈ » I)
/-- Given an ideal which intersects `defined_at_left β a`, pick `b : β` such that
    some partial function in the ideal maps `a` to `b`. -/
def fun_of_ideal [DenselyOrdered β] [NoBotOrder β] [NoTopOrder β] [Nonempty β] (a : α) (I : ideal (partial_iso α β)) :
  (∃ f, f ∈ defined_at_left β a ∧ f ∈ I) → { b // ∃ (f : _)(_ : f ∈ I), (a, b) ∈ Subtype.val f } :=
  Classical.indefiniteDescription _ ∘ fun ⟨f, ⟨b, hb⟩, hf⟩ => ⟨b, f, hf, hb⟩

-- ././Mathport/Syntax/Translate/Basic.lean:452:2: warning: expanding binder collection (f «expr ∈ » I)
/-- Given an ideal which intersects `defined_at_right α b`, pick `a : α` such that
    some partial function in the ideal maps `a` to `b`. -/
def inv_of_ideal [DenselyOrdered α] [NoBotOrder α] [NoTopOrder α] [Nonempty α] (b : β) (I : ideal (partial_iso α β)) :
  (∃ f, f ∈ defined_at_right α b ∧ f ∈ I) → { a // ∃ (f : _)(_ : f ∈ I), (a, b) ∈ Subtype.val f } :=
  Classical.indefiniteDescription _ ∘ fun ⟨f, ⟨a, ha⟩, hf⟩ => ⟨a, f, hf, ha⟩

end PartialIso

open PartialIso

variable (α β)

/-- Any countable linear order embeds in any nonempty dense linear order without endpoints. -/
def embedding_from_countable_to_dense [Encodable α] [DenselyOrdered β] [NoBotOrder β] [NoTopOrder β] [Nonempty β] :
  α ↪o β :=
  let our_ideal : ideal (partial_iso α β) := ideal_of_cofinals (default _) (defined_at_left β)
  let F := fun a => fun_of_ideal a our_ideal (cofinal_meets_ideal_of_cofinals _ _ a)
  OrderEmbedding.ofStrictMono (fun a => (F a).val)
    (by 
      intro a₁ a₂ 
      rcases(F a₁).property with ⟨f, hf, ha₁⟩
      rcases(F a₂).property with ⟨g, hg, ha₂⟩
      rcases our_ideal.directed _ hf _ hg with ⟨m, hm, fm, gm⟩
      exact (lt_iff_lt_of_cmp_eq_cmp$ m.property (a₁, _) (a₂, _) (fm ha₁) (gm ha₂)).mp)

/-- Any two countable dense, nonempty linear orders without endpoints are order isomorphic. -/
def iso_of_countable_dense [Encodable α] [DenselyOrdered α] [NoBotOrder α] [NoTopOrder α] [Nonempty α] [Encodable β]
  [DenselyOrdered β] [NoBotOrder β] [NoTopOrder β] [Nonempty β] : α ≃o β :=
  let to_cofinal : Sum α β → cofinal (partial_iso α β) := fun p => Sum.recOn p (defined_at_left β) (defined_at_right α)
  let our_ideal : ideal (partial_iso α β) := ideal_of_cofinals (default _) to_cofinal 
  let F := fun a => fun_of_ideal a our_ideal (cofinal_meets_ideal_of_cofinals _ to_cofinal (Sum.inl a))
  let G := fun b => inv_of_ideal b our_ideal (cofinal_meets_ideal_of_cofinals _ to_cofinal (Sum.inr b))
  OrderIso.ofCmpEqCmp (fun a => (F a).val) (fun b => (G b).val)
    (by 
      intro a b 
      rcases(F a).property with ⟨f, hf, ha⟩
      rcases(G b).property with ⟨g, hg, hb⟩
      rcases our_ideal.directed _ hf _ hg with ⟨m, hm, fm, gm⟩
      exact m.property (a, _) (_, b) (fm ha) (gm hb))

end Order

