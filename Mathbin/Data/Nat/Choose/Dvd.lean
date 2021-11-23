import Mathbin.Data.Nat.Choose.Basic 
import Mathbin.Data.Nat.Prime

/-!
# Divisibility properties of binomial coefficients
-/


namespace Nat

open_locale Nat

namespace Prime

theorem dvd_choose_add {p a b : ℕ} (hap : a < p) (hbp : b < p) (h : p ≤ a+b) (hp : prime p) : p ∣ choose (a+b) a :=
  have h₁ : p ∣ (a+b)! := hp.dvd_factorial.2 h 
  have h₂ : ¬p ∣ a ! := mt hp.dvd_factorial.1 (not_le_of_gtₓ hap)
  have h₃ : ¬p ∣ b ! := mt hp.dvd_factorial.1 (not_le_of_gtₓ hbp)
  by 
    rw [←choose_mul_factorial_mul_factorial (le.intro rfl), mul_assocₓ, hp.dvd_mul, hp.dvd_mul,
        add_tsub_cancel_left a b] at h₁ <;>
      exact h₁.resolve_right (not_or_distrib.2 ⟨h₂, h₃⟩)

-- error in Data.Nat.Choose.Dvd: ././Mathport/Syntax/Translate/Basic.lean:177:17: failed to parenthesize: parenthesize: uncaught backtrack exception
theorem dvd_choose_self
{p k : exprℕ()}
(hk : «expr < »(0, k))
(hkp : «expr < »(k, p))
(hp : prime p) : «expr ∣ »(p, choose p k) :=
begin
  have [ident r] [":", expr «expr = »(«expr + »(k, «expr - »(p, k)), p)] [],
  by rw ["[", "<-", expr add_tsub_assoc_of_le (nat.le_of_lt hkp) k, ",", expr add_tsub_cancel_left, "]"] [],
  have [ident e] [":", expr «expr ∣ »(p, choose «expr + »(k, «expr - »(p, k)) k)] [],
  by exact [expr dvd_choose_add hkp (nat.sub_lt (hk.trans hkp) hk) (by rw [expr r] []) hp],
  rwa [expr r] ["at", ident e]
end

end Prime

end Nat

