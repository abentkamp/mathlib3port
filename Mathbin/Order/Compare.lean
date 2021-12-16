import Mathbin.Order.Basic

/-!
# Comparison

This file provides basic results about orderings and comparison in linear orders.


## Definitions

* `cmp_le`: An `ordering` from `≤`.
* `ordering.compares`: Turns an `ordering` into `<` and `=` propositions.
* `linear_order_of_compares`: Constructs a `linear_order` instance from the fact that any two
  elements that are not one strictly less than the other either way are equal.
-/


variable {α : Type _}

/-- Like `cmp`, but uses a `≤` on the type instead of `<`. Given two elements `x` and `y`, returns a
three-way comparison result `ordering`. -/
def cmpLe {α} [LE α] [@DecidableRel α (· ≤ ·)] (x y : α) : Ordering :=
  if x ≤ y then if y ≤ x then Ordering.eq else Ordering.lt else Ordering.gt

theorem cmp_le_swap {α} [LE α] [IsTotal α (· ≤ ·)] [@DecidableRel α (· ≤ ·)] (x y : α) : (cmpLe x y).swap = cmpLe y x :=
  by 
    byCases' xy : x ≤ y <;> byCases' yx : y ≤ x <;> simp [cmpLe, Ordering.swap]
    cases not_orₓ xy yx (total_of _ _ _)

theorem cmp_le_eq_cmp {α} [Preorderₓ α] [IsTotal α (· ≤ ·)] [@DecidableRel α (· ≤ ·)] [@DecidableRel α (· < ·)]
  (x y : α) : cmpLe x y = cmp x y :=
  by 
    byCases' xy : x ≤ y <;> byCases' yx : y ≤ x <;> simp [cmpLe, lt_iff_le_not_leₓ, cmp, cmpUsing]
    cases not_orₓ xy yx (total_of _ _ _)

namespace Ordering

/-- `compares o a b` means that `a` and `b` have the ordering relation `o` between them, assuming
that the relation `a < b` is defined. -/
@[simp]
def compares [LT α] : Ordering → α → α → Prop
| lt, a, b => a < b
| Eq, a, b => a = b
| Gt, a, b => a > b

theorem compares_swap [LT α] {a b : α} {o : Ordering} : o.swap.compares a b ↔ o.compares b a :=
  by 
    cases o 
    exacts[Iff.rfl, eq_comm, Iff.rfl]

alias compares_swap ↔ Ordering.Compares.of_swap Ordering.Compares.swap

theorem swap_eq_iff_eq_swap {o o' : Ordering} : o.swap = o' ↔ o = o'.swap :=
  ⟨fun h =>
      by 
        rw [←swap_swap o, h],
    fun h =>
      by 
        rw [←swap_swap o', h]⟩

theorem compares.eq_lt [Preorderₓ α] : ∀ {o} {a b : α}, compares o a b → (o = lt ↔ a < b)
| lt, a, b, h => ⟨fun _ => h, fun _ => rfl⟩
| Eq, a, b, h =>
  ⟨fun h =>
      by 
        injection h,
    fun h' => (ne_of_ltₓ h' h).elim⟩
| Gt, a, b, h =>
  ⟨fun h =>
      by 
        injection h,
    fun h' => (lt_asymmₓ h h').elim⟩

theorem compares.ne_lt [Preorderₓ α] : ∀ {o} {a b : α}, compares o a b → (o ≠ lt ↔ b ≤ a)
| lt, a, b, h => ⟨absurd rfl, fun h' => (not_le_of_lt h h').elim⟩
| Eq, a, b, h =>
  ⟨fun _ => ge_of_eq h,
    fun _ h =>
      by 
        injection h⟩
| Gt, a, b, h =>
  ⟨fun _ => le_of_ltₓ h,
    fun _ h =>
      by 
        injection h⟩

theorem compares.eq_eq [Preorderₓ α] : ∀ {o} {a b : α}, compares o a b → (o = Eq ↔ a = b)
| lt, a, b, h =>
  ⟨fun h =>
      by 
        injection h,
    fun h' => (ne_of_ltₓ h h').elim⟩
| Eq, a, b, h => ⟨fun _ => h, fun _ => rfl⟩
| Gt, a, b, h =>
  ⟨fun h =>
      by 
        injection h,
    fun h' => (ne_of_gtₓ h h').elim⟩

theorem compares.eq_gt [Preorderₓ α] {o} {a b : α} (h : compares o a b) : o = Gt ↔ b < a :=
  swap_eq_iff_eq_swap.symm.trans h.swap.eq_lt

theorem compares.ne_gt [Preorderₓ α] {o} {a b : α} (h : compares o a b) : o ≠ Gt ↔ a ≤ b :=
  (not_congr swap_eq_iff_eq_swap.symm).trans h.swap.ne_lt

theorem compares.le_total [Preorderₓ α] {a b : α} : ∀ {o}, compares o a b → a ≤ b ∨ b ≤ a
| lt, h => Or.inl (le_of_ltₓ h)
| Eq, h => Or.inl (le_of_eqₓ h)
| Gt, h => Or.inr (le_of_ltₓ h)

theorem compares.le_antisymm [Preorderₓ α] {a b : α} : ∀ {o}, compares o a b → a ≤ b → b ≤ a → a = b
| lt, h, _, hba => (not_le_of_lt h hba).elim
| Eq, h, _, _ => h
| Gt, h, hab, _ => (not_le_of_lt h hab).elim

theorem compares.inj [Preorderₓ α] {o₁} : ∀ {o₂} {a b : α}, compares o₁ a b → compares o₂ a b → o₁ = o₂
| lt, a, b, h₁, h₂ => h₁.eq_lt.2 h₂
| Eq, a, b, h₁, h₂ => h₁.eq_eq.2 h₂
| Gt, a, b, h₁, h₂ => h₁.eq_gt.2 h₂

theorem compares_iff_of_compares_impl {β : Type _} [LinearOrderₓ α] [Preorderₓ β] {a b : α} {a' b' : β}
  (h : ∀ {o}, compares o a b → compares o a' b') o : compares o a b ↔ compares o a' b' :=
  by 
    refine' ⟨h, fun ho => _⟩
    cases' lt_trichotomyₓ a b with hab hab
    ·
      change compares Ordering.lt a b at hab 
      rwa [ho.inj (h hab)]
    ·
      cases' hab with hab hab
      ·
        change compares Ordering.eq a b at hab 
        rwa [ho.inj (h hab)]
      ·
        change compares Ordering.gt a b at hab 
        rwa [ho.inj (h hab)]

theorem swap_or_else o₁ o₂ : (or_else o₁ o₂).swap = or_else o₁.swap o₂.swap :=
  by 
    cases o₁ <;>
      try 
          rfl <;>
        cases o₂ <;> rfl

theorem or_else_eq_lt o₁ o₂ : or_else o₁ o₂ = lt ↔ o₁ = lt ∨ o₁ = Eq ∧ o₂ = lt :=
  by 
    cases o₁ <;>
      cases o₂ <;>
        exact
          by 
            decide

end Ordering

theorem OrderDual.dual_compares [LT α] {a b : α} {o : Ordering} :
  @Ordering.Compares (OrderDual α) _ o a b ↔ @Ordering.Compares α _ o b a :=
  by 
    cases o 
    exacts[Iff.rfl, eq_comm, Iff.rfl]

theorem cmp_compares [LinearOrderₓ α] (a b : α) : (cmp a b).Compares a b :=
  by 
    unfold cmp cmpUsing 
    byCases' a < b <;> simp [h]
    byCases' h₂ : b < a <;> simp [h₂, Gt]
    exact (Decidable.lt_or_eq_of_leₓ (le_of_not_gtₓ h₂)).resolve_left h

theorem cmp_swap [Preorderₓ α] [@DecidableRel α (· < ·)] (a b : α) : (cmp a b).swap = cmp b a :=
  by 
    unfold cmp cmpUsing 
    byCases' a < b <;> byCases' h₂ : b < a <;> simp [h, h₂, Gt, Ordering.swap]
    exact lt_asymmₓ h h₂

theorem OrderDual.cmp_le_flip {α} [LE α] [@DecidableRel α (· ≤ ·)] (x y : α) :
  @cmpLe (OrderDual α) _ _ x y = cmpLe y x :=
  rfl

/-- Generate a linear order structure from a preorder and `cmp` function. -/
def linearOrderOfCompares [Preorderₓ α] (cmp : α → α → Ordering) (h : ∀ a b, (cmp a b).Compares a b) : LinearOrderₓ α :=
  { ‹Preorderₓ α› with le_antisymm := fun a b => (h a b).le_antisymm, le_total := fun a b => (h a b).le_total,
    decidableLe := fun a b => decidableOfIff _ (h a b).ne_gt, decidableLt := fun a b => decidableOfIff _ (h a b).eq_lt,
    DecidableEq := fun a b => decidableOfIff _ (h a b).eq_eq }

variable [LinearOrderₓ α] (x y : α)

@[simp]
theorem cmp_eq_lt_iff : cmp x y = Ordering.lt ↔ x < y :=
  Ordering.Compares.eq_lt (cmp_compares x y)

@[simp]
theorem cmp_eq_eq_iff : cmp x y = Ordering.eq ↔ x = y :=
  Ordering.Compares.eq_eq (cmp_compares x y)

@[simp]
theorem cmp_eq_gt_iff : cmp x y = Ordering.gt ↔ y < x :=
  Ordering.Compares.eq_gt (cmp_compares x y)

@[simp]
theorem cmp_self_eq_eq : cmp x x = Ordering.eq :=
  by 
    rw [cmp_eq_eq_iff]

variable {x y} {β : Type _} [LinearOrderₓ β] {x' y' : β}

theorem cmp_eq_cmp_symm : cmp x y = cmp x' y' ↔ cmp y x = cmp y' x' :=
  by 
    constructor 
    rw [←cmp_swap _ y, ←cmp_swap _ y']
    cc 
    rw [←cmp_swap _ x, ←cmp_swap _ x']
    cc

theorem lt_iff_lt_of_cmp_eq_cmp (h : cmp x y = cmp x' y') : x < y ↔ x' < y' :=
  by 
    rw [←cmp_eq_lt_iff, ←cmp_eq_lt_iff, h]

theorem le_iff_le_of_cmp_eq_cmp (h : cmp x y = cmp x' y') : x ≤ y ↔ x' ≤ y' :=
  by 
    rw [←not_ltₓ, ←not_ltₓ]
    apply not_congr 
    apply lt_iff_lt_of_cmp_eq_cmp 
    rwa [cmp_eq_cmp_symm]

