import Mathbin.Algebra.Order.EuclideanAbsoluteValue 
import Mathbin.Data.Polynomial.FieldDivision

/-!
# Absolute value on polynomials over a finite field.

Let `Fq` be a finite field of cardinality `q`, then the map sending a polynomial `p`
to `q ^ degree p` (where `q ^ degree 0 = 0`) is an absolute value.

## Main definitions

 * `polynomial.card_pow_degree` is an absolute value on `𝔽_q[t]`, the ring of
   polynomials over a finite field of cardinality `q`, mapping a polynomial `p`
   to `q ^ degree p` (where `q ^ degree 0 = 0`)

## Main results
 * `polynomial.card_pow_degree_is_euclidean`: `card_pow_degree` respects the
   Euclidean domain structure on the ring of polynomials

-/


namespace Polynomial

variable {Fq : Type _} [Field Fq] [Fintype Fq]

open AbsoluteValue

open_locale Classical

/-- `card_pow_degree` is the absolute value on `𝔽_q[t]` sending `f` to `q ^ degree f`.

`card_pow_degree 0` is defined to be `0`. -/
noncomputable def card_pow_degree : AbsoluteValue (Polynomial Fq) ℤ :=
  have card_pos : 0 < Fintype.card Fq := Fintype.card_pos_iff.mpr inferInstance 
  have pow_pos : ∀ n, 0 < ((Fintype.card Fq : ℤ)^n) := fun n => pow_pos (Int.coe_nat_pos.mpr card_pos) n
  { toFun := fun p => if p = 0 then 0 else Fintype.card Fq^p.nat_degree,
    nonneg' :=
      fun p =>
        by 
          dsimp 
          splitIfs
          ·
            rfl 
          exact pow_nonneg (Int.coe_zero_le _) _,
    eq_zero' :=
      fun p =>
        ite_eq_left_iff.trans$
          ⟨fun h =>
              by 
                contrapose! h 
                exact ⟨h, (pow_pos _).ne'⟩,
            absurd⟩,
    add_le' :=
      fun p q =>
        by 
          byCases' hp : p = 0
          ·
            simp [hp]
          byCases' hq : q = 0
          ·
            simp [hq]
          byCases' hpq : (p+q) = 0
          ·
            simp only [hpq, hp, hq, eq_self_iff_true, if_true, if_false]
            exact add_nonneg (pow_pos _).le (pow_pos _).le 
          simp only [hpq, hp, hq, if_false]
          refine'
            le_transₓ
              (pow_le_pow
                (by 
                  linarith)
                (Polynomial.nat_degree_add_le _ _))
              _ 
          refine'
            le_transₓ (le_max_iff.mpr _)
              (max_le_add_of_nonneg
                (pow_nonneg
                  (by 
                    linarith)
                  _)
                (pow_nonneg
                  (by 
                    linarith)
                  _))
          exact
            (max_choice p.nat_degree q.nat_degree).imp
              (fun h =>
                by 
                  rw [h])
              fun h =>
                by 
                  rw [h],
    map_mul' :=
      fun p q =>
        by 
          byCases' hp : p = 0
          ·
            simp [hp]
          byCases' hq : q = 0
          ·
            simp [hq]
          have hpq : (p*q) ≠ 0 := mul_ne_zero hp hq 
          simp only [hpq, hp, hq, eq_self_iff_true, if_true, if_false, Polynomial.nat_degree_mul hp hq, pow_addₓ] }

theorem card_pow_degree_apply (p : Polynomial Fq) :
  card_pow_degree p = if p = 0 then 0 else Fintype.card Fq^nat_degree p :=
  rfl

@[simp]
theorem card_pow_degree_zero : card_pow_degree (0 : Polynomial Fq) = 0 :=
  if_pos rfl

@[simp]
theorem card_pow_degree_nonzero (p : Polynomial Fq) (hp : p ≠ 0) : card_pow_degree p = (Fintype.card Fq^p.nat_degree) :=
  if_neg hp

theorem card_pow_degree_is_euclidean : is_euclidean (card_pow_degree : AbsoluteValue (Polynomial Fq) ℤ) :=
  have card_pos : 0 < Fintype.card Fq := Fintype.card_pos_iff.mpr inferInstance 
  have pow_pos : ∀ n, 0 < ((Fintype.card Fq : ℤ)^n) := fun n => pow_pos (Int.coe_nat_pos.mpr card_pos) n
  { map_lt_map_iff' :=
      fun p q =>
        by 
          simp only [EuclideanDomain.R, card_pow_degree_apply]
          splitIfs with hp hq hq
          ·
            simp only [hp, hq, lt_self_iff_false]
          ·
            simp only [hp, hq, degree_zero, Ne.def, bot_lt_iff_ne_bot, degree_eq_bot, pow_pos, not_false_iff]
          ·
            simp only [hp, hq, degree_zero, not_lt_bot, (pow_pos _).not_lt]
          ·
            rw [degree_eq_nat_degree hp, degree_eq_nat_degree hq, WithBot.coe_lt_coe, pow_lt_pow_iff]
            exactModCast @Fintype.one_lt_card Fq _ _ }

end Polynomial

