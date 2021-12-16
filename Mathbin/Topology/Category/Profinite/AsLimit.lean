import Mathbin.Topology.Category.Profinite.Default 
import Mathbin.Topology.DiscreteQuotient

/-!
# Profinite sets as limits of finite sets.

We show that any profinite set is isomorphic to the limit of its
discrete (hence finite) quotients.

## Definitions

There are a handful of definitions in this file, given `X : Profinite`:
1. `X.fintype_diagram` is the functor `discrete_quotient X ⥤ Fintype` whose limit
  is isomorphic to `X` (the limit taking place in `Profinite` via `Fintype_to_Profinite`, see 2).
2. `X.diagram` is an abbreviation for `X.fintype_diagram ⋙ Fintype_to_Profinite`.
3. `X.as_limit_cone` is the cone over `X.diagram` whose cone point is `X`.
4. `X.iso_as_limit_cone_lift` is the isomorphism `X ≅ (Profinite.limit_cone X.diagram).X` induced
  by lifting `X.as_limit_cone`.
5. `X.as_limit_cone_iso` is the isomorphism `X.as_limit_cone ≅ (Profinite.limit_cone X.diagram)`
  induced by `X.iso_as_limit_cone_lift`.
6. `X.as_limit` is a term of type `is_limit X.as_limit_cone`.
7. `X.lim : category_theory.limits.limit_cone X.as_limit_cone` is a bundled combination of 3 and 6.

-/


noncomputable section 

open CategoryTheory

namespace Profinite

universe u

variable (X : Profinite.{u})

/-- The functor `discrete_quotient X ⥤ Fintype` whose limit is isomorphic to `X`. -/
def fintype_diagram : DiscreteQuotient X ⥤ Fintypeₓ :=
  { obj := fun S => Fintypeₓ.of S, map := fun S T f => DiscreteQuotient.ofLe f.le }

/-- An abbreviation for `X.fintype_diagram ⋙ Fintype_to_Profinite`. -/
abbrev diagram : DiscreteQuotient X ⥤ Profinite :=
  X.fintype_diagram ⋙ Fintypeₓ.toProfinite

/-- A cone over `X.diagram` whose cone point is `X`. -/
def as_limit_cone : CategoryTheory.Limits.Cone X.diagram :=
  { x, π := { app := fun S => ⟨S.proj, S.proj_is_locally_constant.continuous⟩ } }

instance is_iso_as_limit_cone_lift : is_iso ((limit_cone_is_limit X.diagram).lift X.as_limit_cone) :=
  is_iso_of_bijective _
    (by 
      refine' ⟨fun a b => _, fun a => _⟩
      ·
        intro h 
        refine' DiscreteQuotient.eq_of_proj_eq fun S => _ 
        applyFun fun f : (limit_cone X.diagram).x => f.val S  at h 
        exact h
      ·
        obtain ⟨b, hb⟩ := DiscreteQuotient.exists_of_compat (fun S => a.val S) fun _ _ h => a.prop (hom_of_le h)
        refine' ⟨b, _⟩
        ext S : 3
        apply hb)

/--
The isomorphism between `X` and the explicit limit of `X.diagram`,
induced by lifting `X.as_limit_cone`.
-/
def iso_as_limit_cone_lift : X ≅ (limit_cone X.diagram).x :=
  as_iso$ (limit_cone_is_limit _).lift X.as_limit_cone

/--
The isomorphism of cones `X.as_limit_cone` and `Profinite.limit_cone X.diagram`.
The underlying isomorphism is defeq to `X.iso_as_limit_cone_lift`.
-/
def as_limit_cone_iso : X.as_limit_cone ≅ limit_cone _ :=
  limits.cones.ext (iso_as_limit_cone_lift _) fun _ => rfl

/-- `X.as_limit_cone` is indeed a limit cone. -/
def as_limit : CategoryTheory.Limits.IsLimit X.as_limit_cone :=
  limits.is_limit.of_iso_limit (limit_cone_is_limit _) X.as_limit_cone_iso.symm

/-- A bundled version of `X.as_limit_cone` and `X.as_limit`. -/
def limₓ : limits.limit_cone X.diagram :=
  ⟨X.as_limit_cone, X.as_limit⟩

end Profinite

