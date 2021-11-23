import Mathbin.Algebra.Algebra.Basic 
import Mathbin.RingTheory.Ideal.Quotient

/-!
# Quotients of non-commutative rings

Unfortunately, ideals have only been developed in the commutative case as `ideal`,
and it's not immediately clear how one should formalise ideals in the non-commutative case.

In this file, we directly define the quotient of a semiring by any relation,
by building a bigger relation that represents the ideal generated by that relation.

We prove the universal properties of the quotient, and recommend avoiding relying on the actual
definition, which is made irreducible for this purpose.

Since everything runs in parallel for quotients of `R`-algebras, we do that case at the same time.
-/


universe u₁ u₂ u₃ u₄

variable{R : Type u₁}[Semiringₓ R]

variable{S : Type u₂}[CommSemiringₓ S]

variable{A : Type u₃}[Semiringₓ A][Algebra S A]

namespace RingQuot

/--
Given an arbitrary relation `r` on a ring, we strengthen it to a relation `rel r`,
such that the equivalence relation generated by `rel r` has `x ~ y` if and only if
`x - y` is in the ideal generated by elements `a - b` such that `r a b`.
-/
inductive rel (r : R → R → Prop) : R → R → Prop
  | of ⦃x y : R⦄ (h : r x y) : rel x y
  | add_left ⦃a b c⦄ : rel a b → rel (a+c) (b+c)
  | mul_left ⦃a b c⦄ : rel a b → rel (a*c) (b*c)
  | mul_right ⦃a b c⦄ : rel b c → rel (a*b) (a*c)

theorem rel.add_right {r : R → R → Prop} ⦃a b c : R⦄ (h : rel r b c) : rel r (a+b) (a+c) :=
  by 
    rw [add_commₓ a b, add_commₓ a c]
    exact rel.add_left h

theorem rel.neg {R : Type u₁} [Ringₓ R] {r : R → R → Prop} ⦃a b : R⦄ (h : rel r a b) : rel r (-a) (-b) :=
  by 
    simp only [neg_eq_neg_one_mul a, neg_eq_neg_one_mul b, rel.mul_right h]

theorem rel.sub_left {R : Type u₁} [Ringₓ R] {r : R → R → Prop} ⦃a b c : R⦄ (h : rel r a b) : rel r (a - c) (b - c) :=
  by 
    simp only [sub_eq_add_neg, h.add_left]

theorem rel.sub_right {R : Type u₁} [Ringₓ R] {r : R → R → Prop} ⦃a b c : R⦄ (h : rel r b c) : rel r (a - b) (a - c) :=
  by 
    simp only [sub_eq_add_neg, h.neg.add_right]

theorem rel.smul {r : A → A → Prop} (k : S) ⦃a b : A⦄ (h : rel r a b) : rel r (k • a) (k • b) :=
  by 
    simp only [Algebra.smul_def, rel.mul_right h]

end RingQuot

/-- The quotient of a ring by an arbitrary relation. -/
structure RingQuot(r : R → R → Prop) where 
  toQuot : Quot (RingQuot.Rel r)

namespace RingQuot

variable(r : R → R → Prop)

@[irreducible]
private def zero : RingQuot r :=
  ⟨Quot.mk _ 0⟩

@[irreducible]
private def one : RingQuot r :=
  ⟨Quot.mk _ 1⟩

@[irreducible]
private def add : RingQuot r → RingQuot r → RingQuot r
| ⟨a⟩, ⟨b⟩ => ⟨Quot.map₂ (·+·) rel.add_right rel.add_left a b⟩

@[irreducible]
private def mul : RingQuot r → RingQuot r → RingQuot r
| ⟨a⟩, ⟨b⟩ => ⟨Quot.map₂ (·*·) rel.mul_right rel.mul_left a b⟩

@[irreducible]
private def neg {R : Type u₁} [Ringₓ R] (r : R → R → Prop) : RingQuot r → RingQuot r
| ⟨a⟩ => ⟨Quot.map (fun a => -a) rel.neg a⟩

@[irreducible]
private def sub {R : Type u₁} [Ringₓ R] (r : R → R → Prop) : RingQuot r → RingQuot r → RingQuot r
| ⟨a⟩, ⟨b⟩ => ⟨Quot.map₂ Sub.sub rel.sub_right rel.sub_left a b⟩

@[irreducible]
private def smul [Algebra S R] (n : S) : RingQuot r → RingQuot r
| ⟨a⟩ => ⟨Quot.map (fun a => n • a) (rel.smul n) a⟩

instance  : HasZero (RingQuot r) :=
  ⟨zero r⟩

instance  : HasOne (RingQuot r) :=
  ⟨one r⟩

instance  : Add (RingQuot r) :=
  ⟨add r⟩

instance  : Mul (RingQuot r) :=
  ⟨mul r⟩

instance  {R : Type u₁} [Ringₓ R] (r : R → R → Prop) : Neg (RingQuot r) :=
  ⟨neg r⟩

instance  {R : Type u₁} [Ringₓ R] (r : R → R → Prop) : Sub (RingQuot r) :=
  ⟨sub r⟩

instance  [Algebra S R] : HasScalar S (RingQuot r) :=
  ⟨smul r⟩

theorem zero_quot : (⟨Quot.mk _ 0⟩ : RingQuot r) = 0 :=
  show _ = zero r by 
    rw [zero]

theorem one_quot : (⟨Quot.mk _ 1⟩ : RingQuot r) = 1 :=
  show _ = one r by 
    rw [one]

theorem add_quot {a b} : (⟨Quot.mk _ a⟩+⟨Quot.mk _ b⟩ : RingQuot r) = ⟨Quot.mk _ (a+b)⟩ :=
  by 
    show add r _ _ = _ 
    rw [add]
    rfl

theorem mul_quot {a b} : (⟨Quot.mk _ a⟩*⟨Quot.mk _ b⟩ : RingQuot r) = ⟨Quot.mk _ (a*b)⟩ :=
  by 
    show mul r _ _ = _ 
    rw [mul]
    rfl

theorem neg_quot {R : Type u₁} [Ringₓ R] (r : R → R → Prop) {a} : (-⟨Quot.mk _ a⟩ : RingQuot r) = ⟨Quot.mk _ (-a)⟩ :=
  by 
    show neg r _ = _ 
    rw [neg]
    rfl

theorem sub_quot {R : Type u₁} [Ringₓ R] (r : R → R → Prop) {a b} :
  (⟨Quot.mk _ a⟩ - ⟨Quot.mk _ b⟩ : RingQuot r) = ⟨Quot.mk _ (a - b)⟩ :=
  by 
    show sub r _ _ = _ 
    rw [sub]
    rfl

theorem smul_quot [Algebra S R] {n : S} {a : R} : (n • ⟨Quot.mk _ a⟩ : RingQuot r) = ⟨Quot.mk _ (n • a)⟩ :=
  by 
    show smul r _ _ = _ 
    rw [smul]
    rfl

instance  (r : R → R → Prop) : Semiringₓ (RingQuot r) :=
  { add := ·+·, mul := ·*·, zero := 0, one := 1,
    add_assoc :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [add_quot, add_assocₓ],
    zero_add :=
      by 
        rintro ⟨⟨⟩⟩
        simp [add_quot, ←zero_quot],
    add_zero :=
      by 
        rintro ⟨⟨⟩⟩
        simp [add_quot, ←zero_quot],
    zero_mul :=
      by 
        rintro ⟨⟨⟩⟩
        simp [mul_quot, ←zero_quot],
    mul_zero :=
      by 
        rintro ⟨⟨⟩⟩
        simp [mul_quot, ←zero_quot],
    add_comm :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [add_quot, add_commₓ],
    mul_assoc :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [mul_quot, mul_assocₓ],
    one_mul :=
      by 
        rintro ⟨⟨⟩⟩
        simp [mul_quot, ←one_quot],
    mul_one :=
      by 
        rintro ⟨⟨⟩⟩
        simp [mul_quot, ←one_quot],
    left_distrib :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [mul_quot, add_quot, left_distrib],
    right_distrib :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [mul_quot, add_quot, right_distrib],
    nsmul := · • ·,
    nsmul_zero' :=
      by 
        rintro ⟨⟨⟩⟩
        simp [smul_quot, ←zero_quot],
    nsmul_succ' :=
      by 
        rintro n ⟨⟨⟩⟩
        simp [smul_quot, add_quot, add_mulₓ, add_commₓ] }

instance  {R : Type u₁} [Ringₓ R] (r : R → R → Prop) : Ringₓ (RingQuot r) :=
  { RingQuot.semiring r with neg := Neg.neg,
    add_left_neg :=
      by 
        rintro ⟨⟨⟩⟩
        simp [neg_quot, add_quot, ←zero_quot],
    sub := Sub.sub,
    sub_eq_add_neg :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [neg_quot, sub_quot, add_quot, sub_eq_add_neg] }

instance  {R : Type u₁} [CommSemiringₓ R] (r : R → R → Prop) : CommSemiringₓ (RingQuot r) :=
  { RingQuot.semiring r with
    mul_comm :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [mul_quot, mul_commₓ] }

instance  {R : Type u₁} [CommRingₓ R] (r : R → R → Prop) : CommRingₓ (RingQuot r) :=
  { RingQuot.commSemiring r, RingQuot.ring r with  }

instance  (r : R → R → Prop) : Inhabited (RingQuot r) :=
  ⟨0⟩

instance  [Algebra S R] (r : R → R → Prop) : Algebra S (RingQuot r) :=
  { smul := · • ·, toFun := fun r => ⟨Quot.mk _ (algebraMap S R r)⟩,
    map_one' :=
      by 
        simp [←one_quot],
    map_mul' :=
      by 
        simp [mul_quot],
    map_zero' :=
      by 
        simp [←zero_quot],
    map_add' :=
      by 
        simp [add_quot],
    commutes' :=
      fun r =>
        by 
          rintro ⟨⟨a⟩⟩
          simp [Algebra.commutes, mul_quot],
    smul_def' :=
      fun r =>
        by 
          rintro ⟨⟨a⟩⟩
          simp [smul_quot, Algebra.smul_def, mul_quot] }

/--
The quotient map from a ring to its quotient, as a homomorphism of rings.
-/
def mk_ring_hom (r : R → R → Prop) : R →+* RingQuot r :=
  { toFun := fun x => ⟨Quot.mk _ x⟩,
    map_one' :=
      by 
        simp [←one_quot],
    map_mul' :=
      by 
        simp [mul_quot],
    map_zero' :=
      by 
        simp [←zero_quot],
    map_add' :=
      by 
        simp [add_quot] }

theorem mk_ring_hom_rel {r : R → R → Prop} {x y : R} (w : r x y) : mk_ring_hom r x = mk_ring_hom r y :=
  by 
    simp [mk_ring_hom, Quot.sound (rel.of w)]

theorem mk_ring_hom_surjective (r : R → R → Prop) : Function.Surjective (mk_ring_hom r) :=
  by 
    dsimp [mk_ring_hom]
    rintro ⟨⟨⟩⟩
    simp 

@[ext]
theorem ring_quot_ext {T : Type u₄} [Semiringₓ T] {r : R → R → Prop} (f g : RingQuot r →+* T)
  (w : f.comp (mk_ring_hom r) = g.comp (mk_ring_hom r)) : f = g :=
  by 
    ext 
    rcases mk_ring_hom_surjective r x with ⟨x, rfl⟩
    exact (RingHom.congr_fun w x : _)

variable{T : Type u₄}[Semiringₓ T]

/--
Any ring homomorphism `f : R →+* T` which respects a relation `r : R → R → Prop`
factors uniquely through a morphism `ring_quot r →+* T`.
-/
def lift {r : R → R → Prop} : { f : R →+* T // ∀ ⦃x y⦄, r x y → f x = f y } ≃ (RingQuot r →+* T) :=
  { toFun :=
      fun f' =>
        let f := (f' : R →+* T)
        { toFun :=
            fun x =>
              Quot.lift f
                (by 
                  rintro _ _ r 
                  induction r 
                  case of _ _ r => 
                    exact f'.prop r 
                  case add_left _ _ _ _ r' => 
                    simp [r']
                  case mul_left _ _ _ _ r' => 
                    simp [r']
                  case mul_right _ _ _ _ r' => 
                    simp [r'])
                x.to_quot,
          map_zero' :=
            by 
              simp [←zero_quot, f.map_zero],
          map_add' :=
            by 
              rintro ⟨⟨x⟩⟩ ⟨⟨y⟩⟩
              simp [add_quot, f.map_add x y],
          map_one' :=
            by 
              simp [←one_quot, f.map_one],
          map_mul' :=
            by 
              rintro ⟨⟨x⟩⟩ ⟨⟨y⟩⟩
              simp [mul_quot, f.map_mul x y] },
    invFun :=
      fun F =>
        ⟨F.comp (mk_ring_hom r),
          fun x y h =>
            by 
              dsimp 
              rw [mk_ring_hom_rel h]⟩,
    left_inv :=
      fun f =>
        by 
          ext 
          simp 
          rfl,
    right_inv :=
      fun F =>
        by 
          ext 
          simp 
          rfl }

@[simp]
theorem lift_mk_ring_hom_apply (f : R →+* T) {r : R → R → Prop} (w : ∀ ⦃x y⦄, r x y → f x = f y) x :
  lift ⟨f, w⟩ (mk_ring_hom r x) = f x :=
  rfl

theorem lift_unique (f : R →+* T) {r : R → R → Prop} (w : ∀ ⦃x y⦄, r x y → f x = f y) (g : RingQuot r →+* T)
  (h : g.comp (mk_ring_hom r) = f) : g = lift ⟨f, w⟩ :=
  by 
    ext 
    simp [h]

theorem eq_lift_comp_mk_ring_hom {r : R → R → Prop} (f : RingQuot r →+* T) :
  f =
    lift
      ⟨f.comp (mk_ring_hom r),
        fun x y h =>
          by 
            dsimp 
            rw [mk_ring_hom_rel h]⟩ :=
  (lift.apply_symm_apply f).symm

section CommRingₓ

/-!
We now verify that in the case of a commutative ring, the `ring_quot` construction
agrees with the quotient by the appropriate ideal.
-/


variable{B : Type u₁}[CommRingₓ B]

/-- The universal ring homomorphism from `ring_quot r` to `(ideal.of_rel r).quotient`. -/
def ring_quot_to_ideal_quotient (r : B → B → Prop) : RingQuot r →+* (Ideal.ofRel r).Quotient :=
  lift
    ⟨Ideal.Quotient.mk (Ideal.ofRel r),
      fun x y h => Quot.sound (Submodule.mem_Inf.mpr fun p w => w ⟨x, y, h, sub_add_cancel x y⟩)⟩

@[simp]
theorem ring_quot_to_ideal_quotient_apply (r : B → B → Prop) (x : B) :
  ring_quot_to_ideal_quotient r (mk_ring_hom r x) = Ideal.Quotient.mk _ x :=
  rfl

/-- The universal ring homomorphism from `(ideal.of_rel r).quotient` to `ring_quot r`. -/
def ideal_quotient_to_ring_quot (r : B → B → Prop) : (Ideal.ofRel r).Quotient →+* RingQuot r :=
  Ideal.Quotient.lift (Ideal.ofRel r) (mk_ring_hom r)
    (by 
      refine' fun x h => Submodule.span_induction h _ _ _ _
      ·
        rintro y ⟨a, b, h, su⟩
        symm'  at su 
        rw [←sub_eq_iff_eq_add] at su 
        rw [←su, RingHom.map_sub, mk_ring_hom_rel h, sub_self]
      ·
        simp 
      ·
        intro a b ha hb 
        simp [ha, hb]
      ·
        intro a x hx 
        simp [hx])

@[simp]
theorem ideal_quotient_to_ring_quot_apply (r : B → B → Prop) (x : B) :
  ideal_quotient_to_ring_quot r (Ideal.Quotient.mk _ x) = mk_ring_hom r x :=
  rfl

/--
The ring equivalence between `ring_quot r` and `(ideal.of_rel r).quotient`
-/
def ring_quot_equiv_ideal_quotient (r : B → B → Prop) : RingQuot r ≃+* (Ideal.ofRel r).Quotient :=
  RingEquiv.ofHomInv (ring_quot_to_ideal_quotient r) (ideal_quotient_to_ring_quot r)
    (by 
      ext 
      rfl)
    (by 
      ext 
      rfl)

end CommRingₓ

section StarRing

variable[StarRing R](r)(hr : ∀ a b, r a b → r (star a) (star b))

include hr

theorem rel.star ⦃a b : R⦄ (h : rel r a b) : rel r (star a) (star b) :=
  by 
    induction h
    ·
      exact rel.of (hr _ _ h_h)
    ·
      rw [star_add, star_add]
      exact rel.add_left h_ih
    ·
      rw [star_mul, star_mul]
      exact rel.mul_right h_ih
    ·
      rw [star_mul, star_mul]
      exact rel.mul_left h_ih

@[irreducible]
private def star' : RingQuot r → RingQuot r
| ⟨a⟩ => ⟨Quot.map (star : R → R) (rel.star r hr) a⟩

theorem star'_quot (hr : ∀ a b, r a b → r (star a) (star b)) {a} :
  (star' r hr ⟨Quot.mk _ a⟩ : RingQuot r) = ⟨Quot.mk _ (star a)⟩ :=
  by 
    show star' r _ _ = _ 
    rw [star']
    rfl

/-- Transfer a star_ring instance through a quotient, if the quotient is invariant to `star` -/
def StarRing {R : Type u₁} [Semiringₓ R] [StarRing R] (r : R → R → Prop) (hr : ∀ a b, r a b → r (star a) (star b)) :
  StarRing (RingQuot r) :=
  { star := star' r hr,
    star_involutive :=
      by 
        rintro ⟨⟨⟩⟩
        simp [star'_quot],
    star_mul :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [star'_quot, mul_quot, star_mul],
    star_add :=
      by 
        rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩
        simp [star'_quot, add_quot, star_add] }

end StarRing

section Algebra

variable(S)

/--
The quotient map from an `S`-algebra to its quotient, as a homomorphism of `S`-algebras.
-/
def mk_alg_hom (s : A → A → Prop) : A →ₐ[S] RingQuot s :=
  { mk_ring_hom s with commutes' := fun r => rfl }

@[simp]
theorem mk_alg_hom_coe (s : A → A → Prop) : (mk_alg_hom S s : A →+* RingQuot s) = mk_ring_hom s :=
  rfl

theorem mk_alg_hom_rel {s : A → A → Prop} {x y : A} (w : s x y) : mk_alg_hom S s x = mk_alg_hom S s y :=
  by 
    simp [mk_alg_hom, mk_ring_hom, Quot.sound (rel.of w)]

theorem mk_alg_hom_surjective (s : A → A → Prop) : Function.Surjective (mk_alg_hom S s) :=
  by 
    dsimp [mk_alg_hom]
    rintro ⟨⟨a⟩⟩
    use a 
    rfl

variable{B : Type u₄}[Semiringₓ B][Algebra S B]

@[ext]
theorem ring_quot_ext' {s : A → A → Prop} (f g : RingQuot s →ₐ[S] B)
  (w : f.comp (mk_alg_hom S s) = g.comp (mk_alg_hom S s)) : f = g :=
  by 
    ext 
    rcases mk_alg_hom_surjective S s x with ⟨x, rfl⟩
    exact (AlgHom.congr_fun w x : _)

/--
Any `S`-algebra homomorphism `f : A →ₐ[S] B` which respects a relation `s : A → A → Prop`
factors uniquely through a morphism `ring_quot s →ₐ[S]  B`.
-/
def lift_alg_hom {s : A → A → Prop} : { f : A →ₐ[S] B // ∀ ⦃x y⦄, s x y → f x = f y } ≃ (RingQuot s →ₐ[S] B) :=
  { toFun :=
      fun f' =>
        let f := (f' : A →ₐ[S] B)
        { toFun :=
            fun x =>
              Quot.lift f
                (by 
                  rintro _ _ r 
                  induction r 
                  case of _ _ r => 
                    exact f'.prop r 
                  case add_left _ _ _ _ r' => 
                    simp [r']
                  case mul_left _ _ _ _ r' => 
                    simp [r']
                  case mul_right _ _ _ _ r' => 
                    simp [r'])
                x.to_quot,
          map_zero' :=
            by 
              simp [←zero_quot, f.map_zero],
          map_add' :=
            by 
              rintro ⟨⟨x⟩⟩ ⟨⟨y⟩⟩
              simp [add_quot, f.map_add x y],
          map_one' :=
            by 
              simp [←one_quot, f.map_one],
          map_mul' :=
            by 
              rintro ⟨⟨x⟩⟩ ⟨⟨y⟩⟩
              simp [mul_quot, f.map_mul x y],
          commutes' :=
            by 
              rintro x 
              simp [←one_quot, smul_quot, Algebra.algebra_map_eq_smul_one] },
    invFun :=
      fun F =>
        ⟨F.comp (mk_alg_hom S s),
          fun _ _ h =>
            by 
              dsimp 
              erw [mk_alg_hom_rel S h]⟩,
    left_inv :=
      fun f =>
        by 
          ext 
          simp 
          rfl,
    right_inv :=
      fun F =>
        by 
          ext 
          simp 
          rfl }

@[simp]
theorem lift_alg_hom_mk_alg_hom_apply (f : A →ₐ[S] B) {s : A → A → Prop} (w : ∀ ⦃x y⦄, s x y → f x = f y) x :
  (lift_alg_hom S ⟨f, w⟩) ((mk_alg_hom S s) x) = f x :=
  rfl

theorem lift_alg_hom_unique (f : A →ₐ[S] B) {s : A → A → Prop} (w : ∀ ⦃x y⦄, s x y → f x = f y) (g : RingQuot s →ₐ[S] B)
  (h : g.comp (mk_alg_hom S s) = f) : g = lift_alg_hom S ⟨f, w⟩ :=
  by 
    ext 
    simp [h]

theorem eq_lift_alg_hom_comp_mk_alg_hom {s : A → A → Prop} (f : RingQuot s →ₐ[S] B) :
  f =
    lift_alg_hom S
      ⟨f.comp (mk_alg_hom S s),
        fun x y h =>
          by 
            dsimp 
            erw [mk_alg_hom_rel S h]⟩ :=
  ((lift_alg_hom S).apply_symm_apply f).symm

end Algebra

attribute [irreducible] mk_ring_hom mk_alg_hom lift lift_alg_hom

end RingQuot

