import Mathbin.GroupTheory.OrderOfElement

/-!
# Complements

In this file we define the complement of a subgroup.

## Main definitions

- `is_complement S T` where `S` and `T` are subsets of `G` states that every `g : G` can be
  written uniquely as a product `s * t` for `s ∈ S`, `t ∈ T`.
- `left_transversals T` where `T` is a subset of `G` is the set of all left-complements of `T`,
  i.e. the set of all `S : set G` that contain exactly one element of each left coset of `T`.
- `right_transversals S` where `S` is a subset of `G` is the set of all right-complements of `S`,
  i.e. the set of all `T : set G` that contain exactly one element of each right coset of `S`.

## Main results

- `is_complement_of_coprime` : Subgroups of coprime order are complements.
-/


open_locale BigOperators

namespace Subgroup

variable {G : Type _} [Groupₓ G] (H K : Subgroup G) (S T : Set G)

/-- `S` and `T` are complements if `(*) : S × T → G` is a bijection.
  This notion generalizes left transversals, right transversals, and complementary subgroups. -/
@[toAdditive "`S` and `T` are complements if `(*) : S × T → G` is a bijection"]
def is_complement : Prop :=
  Function.Bijective fun x : S × T => x.1.1*x.2.1

/-- `H` and `K` are complements if `(*) : H × K → G` is a bijection -/
@[toAdditive "`H` and `K` are complements if `(*) : H × K → G` is a bijection"]
abbrev is_complement' :=
  is_complement (H : Set G) (K : Set G)

/-- The set of left-complements of `T : set G` -/
@[toAdditive "The set of left-complements of `T : set G`"]
def left_transversals : Set (Set G) :=
  { S : Set G | is_complement S T }

/-- The set of right-complements of `S : set G` -/
@[toAdditive "The set of right-complements of `S : set G`"]
def right_transversals : Set (Set G) :=
  { T : Set G | is_complement S T }

variable {H K S T}

@[toAdditive]
theorem is_complement'_def : is_complement' H K ↔ is_complement (H : Set G) (K : Set G) :=
  Iff.rfl

@[toAdditive]
theorem is_complement_iff_exists_unique : is_complement S T ↔ ∀ g : G, ∃! x : S × T, (x.1.1*x.2.1) = g :=
  Function.bijective_iff_exists_unique _

@[toAdditive]
theorem is_complement.exists_unique (h : is_complement S T) (g : G) : ∃! x : S × T, (x.1.1*x.2.1) = g :=
  is_complement_iff_exists_unique.mp h g

@[toAdditive]
theorem is_complement'.symm (h : is_complement' H K) : is_complement' K H :=
  by 
    let ϕ : H × K ≃ K × H :=
      Equivₓ.mk (fun x => ⟨x.2⁻¹, x.1⁻¹⟩) (fun x => ⟨x.2⁻¹, x.1⁻¹⟩) (fun x => Prod.extₓ (inv_invₓ _) (inv_invₓ _))
        fun x => Prod.extₓ (inv_invₓ _) (inv_invₓ _)
    let ψ : G ≃ G := Equivₓ.mk (fun g : G => g⁻¹) (fun g : G => g⁻¹) inv_invₓ inv_invₓ 
    suffices  : (ψ ∘ fun x : H × K => x.1.1*x.2.1) = (fun x : K × H => x.1.1*x.2.1) ∘ ϕ
    ·
      rwa [is_complement'_def, is_complement, ←Equivₓ.bijective_comp, ←this, Equivₓ.comp_bijective]
    exact funext fun x => mul_inv_rev _ _

@[toAdditive]
theorem is_complement'_comm : is_complement' H K ↔ is_complement' K H :=
  ⟨is_complement'.symm, is_complement'.symm⟩

@[toAdditive]
theorem is_complement_top_singleton {g : G} : is_complement (⊤ : Set G) {g} :=
  ⟨fun ⟨x, _, rfl⟩ ⟨y, _, rfl⟩ h => Prod.extₓ (Subtype.ext (mul_right_cancelₓ h)) rfl,
    fun x => ⟨⟨⟨x*g⁻¹, ⟨⟩⟩, g, rfl⟩, inv_mul_cancel_right x g⟩⟩

@[toAdditive]
theorem is_complement_singleton_top {g : G} : is_complement ({g} : Set G) ⊤ :=
  ⟨fun ⟨⟨_, rfl⟩, x⟩ ⟨⟨_, rfl⟩, y⟩ h => Prod.extₓ rfl (Subtype.ext (mul_left_cancelₓ h)),
    fun x => ⟨⟨⟨g, rfl⟩, g⁻¹*x, ⟨⟩⟩, mul_inv_cancel_left g x⟩⟩

@[toAdditive]
theorem is_complement_singleton_left {g : G} : is_complement {g} S ↔ S = ⊤ :=
  by 
    refine' ⟨fun h => top_le_iff.mp fun x hx => _, fun h => (congr_argₓ _ h).mpr is_complement_singleton_top⟩
    obtain ⟨⟨⟨z, rfl : z = g⟩, y, _⟩, hy⟩ := h.2 (g*x)
    rwa [←mul_left_cancelₓ hy]

@[toAdditive]
theorem is_complement_singleton_right {g : G} : is_complement S {g} ↔ S = ⊤ :=
  by 
    refine' ⟨fun h => top_le_iff.mp fun x hx => _, fun h => (congr_argₓ _ h).mpr is_complement_top_singleton⟩
    obtain ⟨y, hy⟩ := h.2 (x*g)
    convRHS at hy => rw [←show y.2.1 = g from y.2.2]
    rw [←mul_right_cancelₓ hy]
    exact y.1.2

@[toAdditive]
theorem is_complement_top_left : is_complement ⊤ S ↔ ∃ g : G, S = {g} :=
  by 
    refine' ⟨fun h => set.exists_eq_singleton_iff_nonempty_unique_mem.mpr ⟨_, fun a b ha hb => _⟩, _⟩
    ·
      obtain ⟨a, ha⟩ := h.2 1 
      exact ⟨a.2.1, a.2.2⟩
    ·
      have  : (⟨⟨_, mem_top (a⁻¹)⟩, ⟨a, ha⟩⟩ : (⊤ : Set G) × S) = ⟨⟨_, mem_top (b⁻¹)⟩, ⟨b, hb⟩⟩ :=
        h.1 ((inv_mul_selfₓ a).trans (inv_mul_selfₓ b).symm)
      exact subtype.ext_iff.mp (prod.ext_iff.mp this).2
    ·
      rintro ⟨g, rfl⟩
      exact is_complement_top_singleton

@[toAdditive]
theorem is_complement_top_right : is_complement S ⊤ ↔ ∃ g : G, S = {g} :=
  by 
    refine' ⟨fun h => set.exists_eq_singleton_iff_nonempty_unique_mem.mpr ⟨_, fun a b ha hb => _⟩, _⟩
    ·
      obtain ⟨a, ha⟩ := h.2 1 
      exact ⟨a.1.1, a.1.2⟩
    ·
      have  : (⟨⟨a, ha⟩, ⟨_, mem_top (a⁻¹)⟩⟩ : S × (⊤ : Set G)) = ⟨⟨b, hb⟩, ⟨_, mem_top (b⁻¹)⟩⟩ :=
        h.1 ((mul_inv_selfₓ a).trans (mul_inv_selfₓ b).symm)
      exact subtype.ext_iff.mp (prod.ext_iff.mp this).1
    ·
      rintro ⟨g, rfl⟩
      exact is_complement_singleton_top

@[toAdditive]
theorem is_complement'_top_bot : is_complement' (⊤ : Subgroup G) ⊥ :=
  is_complement_top_singleton

@[toAdditive]
theorem is_complement'_bot_top : is_complement' (⊥ : Subgroup G) ⊤ :=
  is_complement_singleton_top

@[simp, toAdditive]
theorem is_complement'_bot_left : is_complement' ⊥ H ↔ H = ⊤ :=
  is_complement_singleton_left.trans coe_eq_univ

@[simp, toAdditive]
theorem is_complement'_bot_right : is_complement' H ⊥ ↔ H = ⊤ :=
  is_complement_singleton_right.trans coe_eq_univ

@[simp, toAdditive]
theorem is_complement'_top_left : is_complement' ⊤ H ↔ H = ⊥ :=
  is_complement_top_left.trans coe_eq_singleton

@[simp, toAdditive]
theorem is_complement'_top_right : is_complement' H ⊤ ↔ H = ⊥ :=
  is_complement_top_right.trans coe_eq_singleton

@[toAdditive]
theorem mem_left_transversals_iff_exists_unique_inv_mul_mem :
  S ∈ left_transversals T ↔ ∀ g : G, ∃! s : S, ((s : G)⁻¹*g) ∈ T :=
  by 
    rw [left_transversals, Set.mem_set_of_eq, is_complement_iff_exists_unique]
    refine' ⟨fun h g => _, fun h g => _⟩
    ·
      obtain ⟨x, h1, h2⟩ := h g 
      exact
        ⟨x.1, (congr_argₓ (· ∈ T) (eq_inv_mul_of_mul_eq h1)).mp x.2.2,
          fun y hy => (prod.ext_iff.mp (h2 ⟨y, y⁻¹*g, hy⟩ (mul_inv_cancel_left y g))).1⟩
    ·
      obtain ⟨x, h1, h2⟩ := h g 
      refine' ⟨⟨x, x⁻¹*g, h1⟩, mul_inv_cancel_left x g, fun y hy => _⟩
      have  := h2 y.1 ((congr_argₓ (· ∈ T) (eq_inv_mul_of_mul_eq hy)).mp y.2.2)
      exact Prod.extₓ this (Subtype.ext (eq_inv_mul_of_mul_eq ((congr_argₓ _ this).mp hy)))

@[toAdditive]
theorem mem_right_transversals_iff_exists_unique_mul_inv_mem :
  S ∈ right_transversals T ↔ ∀ g : G, ∃! s : S, (g*(s : G)⁻¹) ∈ T :=
  by 
    rw [right_transversals, Set.mem_set_of_eq, is_complement_iff_exists_unique]
    refine' ⟨fun h g => _, fun h g => _⟩
    ·
      obtain ⟨x, h1, h2⟩ := h g 
      exact
        ⟨x.2, (congr_argₓ (· ∈ T) (eq_mul_inv_of_mul_eq h1)).mp x.1.2,
          fun y hy => (prod.ext_iff.mp (h2 ⟨⟨g*y⁻¹, hy⟩, y⟩ (inv_mul_cancel_right g y))).2⟩
    ·
      obtain ⟨x, h1, h2⟩ := h g 
      refine' ⟨⟨⟨g*x⁻¹, h1⟩, x⟩, inv_mul_cancel_right g x, fun y hy => _⟩
      have  := h2 y.2 ((congr_argₓ (· ∈ T) (eq_mul_inv_of_mul_eq hy)).mp y.1.2)
      exact Prod.extₓ (Subtype.ext (eq_mul_inv_of_mul_eq ((congr_argₓ _ this).mp hy))) this

@[toAdditive]
theorem mem_left_transversals_iff_exists_unique_quotient_mk'_eq :
  S ∈ left_transversals (H : Set G) ↔ ∀ q : Quotientₓ (QuotientGroup.leftRel H), ∃! s : S, Quotientₓ.mk' s.1 = q :=
  by 
    have key : ∀ g h, Quotientₓ.mk' g = Quotientₓ.mk' h ↔ (g⁻¹*h) ∈ H := @Quotientₓ.eq' G (QuotientGroup.leftRel H)
    simpRw [mem_left_transversals_iff_exists_unique_inv_mul_mem, SetLike.mem_coe, ←key]
    exact ⟨fun h q => Quotientₓ.induction_on' q h, fun h g => h (Quotientₓ.mk' g)⟩

@[toAdditive]
theorem mem_right_transversals_iff_exists_unique_quotient_mk'_eq :
  S ∈ right_transversals (H : Set G) ↔ ∀ q : Quotientₓ (QuotientGroup.rightRel H), ∃! s : S, Quotientₓ.mk' s.1 = q :=
  by 
    have key : ∀ g h, Quotientₓ.mk' g = Quotientₓ.mk' h ↔ (h*g⁻¹) ∈ H := @Quotientₓ.eq' G (QuotientGroup.rightRel H)
    simpRw [mem_right_transversals_iff_exists_unique_mul_inv_mem, SetLike.mem_coe, ←key]
    exact ⟨fun h q => Quotientₓ.induction_on' q h, fun h g => h (Quotientₓ.mk' g)⟩

@[toAdditive]
theorem mem_left_transversals_iff_bijective :
  S ∈ left_transversals (H : Set G) ↔
    Function.Bijective (S.restrict (Quotientₓ.mk' : G → Quotientₓ (QuotientGroup.leftRel H))) :=
  mem_left_transversals_iff_exists_unique_quotient_mk'_eq.trans
    (Function.bijective_iff_exists_unique (S.restrict Quotientₓ.mk')).symm

@[toAdditive]
theorem mem_right_transversals_iff_bijective :
  S ∈ right_transversals (H : Set G) ↔
    Function.Bijective (Set.restrict (Quotientₓ.mk' : G → Quotientₓ (QuotientGroup.rightRel H)) S) :=
  mem_right_transversals_iff_exists_unique_quotient_mk'_eq.trans
    (Function.bijective_iff_exists_unique (S.restrict Quotientₓ.mk')).symm

@[toAdditive]
instance : Inhabited (left_transversals (H : Set G)) :=
  ⟨⟨Set.Range Quotientₓ.out',
      mem_left_transversals_iff_bijective.mpr
        ⟨by 
            rintro ⟨_, q₁, rfl⟩ ⟨_, q₂, rfl⟩ hg 
            rw [(q₁.out_eq'.symm.trans hg).trans q₂.out_eq'],
          fun q => ⟨⟨q.out', q, rfl⟩, Quotientₓ.out_eq' q⟩⟩⟩⟩

@[toAdditive]
instance : Inhabited (right_transversals (H : Set G)) :=
  ⟨⟨Set.Range Quotientₓ.out',
      mem_right_transversals_iff_bijective.mpr
        ⟨by 
            rintro ⟨_, q₁, rfl⟩ ⟨_, q₂, rfl⟩ hg 
            rw [(q₁.out_eq'.symm.trans hg).trans q₂.out_eq'],
          fun q => ⟨⟨q.out', q, rfl⟩, Quotientₓ.out_eq' q⟩⟩⟩⟩

theorem is_complement'.is_compl (h : is_complement' H K) : IsCompl H K :=
  by 
    refine'
      ⟨fun g ⟨p, q⟩ =>
          let x : H × K := ⟨⟨g, p⟩, 1⟩
          let y : H × K := ⟨1, g, q⟩
          subtype.ext_iff.mp (prod.ext_iff.mp (show x = y from h.1 ((mul_oneₓ g).trans (one_mulₓ g).symm))).1,
        fun g _ => _⟩
    obtain ⟨⟨h, k⟩, rfl⟩ := h.2 g 
    exact Subgroup.mul_mem_sup h.2 k.2

theorem is_complement'.sup_eq_top (h : Subgroup.IsComplement' H K) : H⊔K = ⊤ :=
  h.is_compl.sup_eq_top

theorem is_complement'.disjoint (h : is_complement' H K) : Disjoint H K :=
  h.is_compl.disjoint

theorem is_complement.card_mul [Fintype G] [Fintype S] [Fintype T] (h : is_complement S T) :
  (Fintype.card S*Fintype.card T) = Fintype.card G :=
  (Fintype.card_prod _ _).symm.trans (Fintype.card_of_bijective h)

theorem is_complement'.card_mul [Fintype G] [Fintype H] [Fintype K] (h : is_complement' H K) :
  (Fintype.card H*Fintype.card K) = Fintype.card G :=
  h.card_mul

theorem is_complement'_of_card_mul_and_disjoint [Fintype G] [Fintype H] [Fintype K]
  (h1 : (Fintype.card H*Fintype.card K) = Fintype.card G) (h2 : Disjoint H K) : is_complement' H K :=
  by 
    refine' (Fintype.bijective_iff_injective_and_card _).mpr ⟨fun x y h => _, (Fintype.card_prod H K).trans h1⟩
    rw [←eq_inv_mul_iff_mul_eq, ←mul_assocₓ, ←mul_inv_eq_iff_eq_mul] at h 
    change (↑x.2*y.2⁻¹) = ↑x.1⁻¹*y.1 at h 
    rw [Prod.ext_iff, ←@inv_mul_eq_one H _ x.1 y.1, ←@mul_inv_eq_one K _ x.2 y.2, Subtype.ext_iff, Subtype.ext_iff,
      coe_one, coe_one, h, and_selfₓ, ←mem_bot, ←h2.eq_bot, mem_inf]
    exact ⟨Subtype.mem (x.1⁻¹*y.1), (congr_argₓ (· ∈ K) h).mp (Subtype.mem (x.2*y.2⁻¹))⟩

theorem is_complement'_iff_card_mul_and_disjoint [Fintype G] [Fintype H] [Fintype K] :
  is_complement' H K ↔ (Fintype.card H*Fintype.card K) = Fintype.card G ∧ Disjoint H K :=
  ⟨fun h => ⟨h.card_mul, h.disjoint⟩, fun h => is_complement'_of_card_mul_and_disjoint h.1 h.2⟩

theorem is_complement'_of_coprime [Fintype G] [Fintype H] [Fintype K]
  (h1 : (Fintype.card H*Fintype.card K) = Fintype.card G) (h2 : Nat.Coprime (Fintype.card H) (Fintype.card K)) :
  is_complement' H K :=
  is_complement'_of_card_mul_and_disjoint h1 (disjoint_iff.mpr (inf_eq_bot_of_coprime h2))

end Subgroup

