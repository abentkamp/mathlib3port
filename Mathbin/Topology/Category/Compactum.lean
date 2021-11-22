import Mathbin.CategoryTheory.Monad.Types 
import Mathbin.CategoryTheory.Monad.Limits 
import Mathbin.CategoryTheory.Equivalence 
import Mathbin.Topology.Category.CompHaus.Default 
import Mathbin.Data.Set.Constructions

/-!

# Compacta and Compact Hausdorff Spaces

Recall that, given a monad `M` on `Type*`, an *algebra* for `M` consists of the following data:
- A type `X : Type*`
- A "structure" map `M X → X`.
This data must also satisfy a distributivity and unit axiom, and algebras for `M` form a category
in an evident way.

See the file `category_theory.monad.algebra` for a general version, as well as the following link.
https://ncatlab.org/nlab/show/monad

This file proves the equivalence between the category of *compact Hausdorff topological spaces*
and the category of algebras for the *ultrafilter monad*.

## Notation:

Here are the main objects introduced in this file.
- `Compactum` is the type of compacta, which we define as algebras for the ultrafilter monad.
- `Compactum_to_CompHaus` is the functor `Compactum ⥤ CompHaus`. Here `CompHaus` is the usual
  category of compact Hausdorff spaces.
- `Compactum_to_CompHaus.is_equivalence` is a term of type `is_equivalence Compactum_to_CompHaus`.

The proof of this equivalence is a bit technical. But the idea is quite simply that the structure
map `ultrafilter X → X` for an algebra `X` of the ultrafilter monad should be considered as the map
sending an ultrafilter to its limit in `X`. The topology on `X` is then defined by mimicking the
characterization of open sets in terms of ultrafilters.

Any `X : Compactum` is endowed with a coercion to `Type*`, as well as the following instances:
- `topological_space X`.
- `compact_space X`.
- `t2_space X`.

Any morphism `f : X ⟶ Y` of is endowed with a coercion to a function `X → Y`, which is shown to
be continuous in `continuous_of_hom`.

The function `Compactum.of_topological_space` can be used to construct a `Compactum` from a
topological space which satisfies `compact_space` and `t2_space`.

We also add wrappers around structures which already exist. Here are the main ones, all in the
`Compactum` namespace:

- `forget : Compactum ⥤ Type*` is the forgetful functor, which induces a `concrete_category`
  instance for `Compactum`.
- `free : Type* ⥤ Compactum` is the left adjoint to `forget`, and the adjunction is in `adj`.
- `str : ultrafilter X → X` is the structure map for `X : Compactum`.
  The notation `X.str` is preferred.
- `join : ultrafilter (ultrafilter X) → ultrafilter X` is the monadic join for `X : Compactum`.
  Again, the notation `X.join` is preferred.
- `incl : X → ultrafilter X` is the unit for `X : Compactum`. The notation `X.incl` is preferred.

## References

- E. Manes, Algebraic Theories, Graduate Texts in Mathematics 26, Springer-Verlag, 1976.
- https://ncatlab.org/nlab/show/ultrafilter

-/


universe u

open CategoryTheory Filter Ultrafilter TopologicalSpace CategoryTheory.Limits HasFiniteInter

open_locale Classical TopologicalSpace

local notation "β" => of_type_monad Ultrafilter

-- error in Topology.Category.Compactum: ././Mathport/Syntax/Translate/Basic.lean:702:9: unsupported derive handler category
/-- The type `Compactum` of Compacta, defined as algebras for the ultrafilter monad. -/
@[derive #["[", expr category, ",", expr inhabited, "]"]]
def Compactum :=
monad.algebra exprβ()

namespace Compactum

-- error in Topology.Category.Compactum: ././Mathport/Syntax/Translate/Basic.lean:702:9: unsupported derive handler creates_limits
/-- The forgetful functor to Type* -/
@[derive #["[", expr creates_limits, ",", expr faithful, "]"]]
def forget : «expr ⥤ »(Compactum, Type*) :=
monad.forget _

/-- The "free" Compactum functor. -/
def free : Type _ ⥤ Compactum :=
  monad.free _

/-- The adjunction between `free` and `forget`. -/
def adj : free ⊣ forget :=
  monad.adj _

instance  : concrete_category Compactum :=
  { forget := forget }

instance  : CoeSort Compactum (Type _) :=
  ⟨forget.obj⟩

instance  {X Y : Compactum} : CoeFun (X ⟶ Y) fun f => X → Y :=
  ⟨fun f => f.f⟩

instance  : has_limits Compactum :=
  has_limits_of_has_limits_creates_limits forget

/-- The structure map for a compactum, essentially sending an ultrafilter to its limit. -/
def str (X : Compactum) : Ultrafilter X → X :=
  X.a

/-- The monadic join. -/
def join (X : Compactum) : Ultrafilter (Ultrafilter X) → Ultrafilter X :=
  β.μ.app _

/-- The inclusion of `X` into `ultrafilter X`. -/
def incl (X : Compactum) : X → Ultrafilter X :=
  β.η.app _

@[simp]
theorem str_incl (X : Compactum) (x : X) : X.str (X.incl x) = x :=
  by 
    change (β.η.app _ ≫ X.a) _ = _ 
    rw [monad.algebra.unit]
    rfl

@[simp]
theorem str_hom_commute (X Y : Compactum) (f : X ⟶ Y) (xs : Ultrafilter X) : f (X.str xs) = Y.str (map f xs) :=
  by 
    change (X.a ≫ f.f) _ = _ 
    rw [←f.h]
    rfl

@[simp]
theorem join_distrib (X : Compactum) (uux : Ultrafilter (Ultrafilter X)) : X.str (X.join uux) = X.str (map X.str uux) :=
  by 
    change (β.μ.app _ ≫ X.a) _ = _ 
    rw [monad.algebra.assoc]
    rfl

instance  {X : Compactum} : TopologicalSpace X :=
  { IsOpen := fun U => ∀ F : Ultrafilter X, X.str F ∈ U → U ∈ F, is_open_univ := fun _ _ => Filter.univ_sets _,
    is_open_inter := fun S T h3 h4 h5 h6 => Filter.inter_sets _ (h3 _ h6.1) (h4 _ h6.2),
    is_open_sUnion := fun S h1 F ⟨T, hT, h2⟩ => mem_of_superset (h1 T hT _ h2) (Set.subset_sUnion_of_mem hT) }

-- error in Topology.Category.Compactum: ././Mathport/Syntax/Translate/Basic.lean:340:40: in by_contradiction: ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
theorem is_closed_iff
{X : Compactum}
(S : set X) : «expr ↔ »(is_closed S, ∀ F : ultrafilter X, «expr ∈ »(S, F) → «expr ∈ »(X.str F, S)) :=
begin
  rw ["<-", expr is_open_compl_iff] [],
  split,
  { intros [ident cond, ident F, ident h],
    by_contradiction [ident c],
    specialize [expr cond F c],
    rw [expr compl_mem_iff_not_mem] ["at", ident cond],
    contradiction },
  { intros [ident h1, ident F, ident h2],
    specialize [expr h1 F],
    cases [expr F.mem_or_compl_mem S] []; finish [] [] }
end

instance  {X : Compactum} : CompactSpace X :=
  by 
    constructor 
    rw [is_compact_iff_ultrafilter_le_nhds]
    intro F h 
    refine'
      ⟨X.str F,
        by 
          tauto,
        _⟩
    rw [le_nhds_iff]
    intro S h1 h2 
    exact h2 F h1

/-- A local definition used only in the proofs. -/
private def basic {X : Compactum} (A : Set X) : Set (Ultrafilter X) :=
  { F | A ∈ F }

/-- A local definition used only in the proofs. -/
private def cl {X : Compactum} (A : Set X) : Set X :=
  X.str '' basic A

-- error in Topology.Category.Compactum: ././Mathport/Syntax/Translate/Basic.lean:340:40: in exacts: ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
private
theorem basic_inter {X : Compactum} (A B : set X) : «expr = »(basic «expr ∩ »(A, B), «expr ∩ »(basic A, basic B)) :=
begin
  ext [] [ident G] [],
  split,
  { intro [ident hG],
    split; filter_upwards ["[", expr hG, "]"] []; intro [ident x],
    exacts ["[", expr and.left, ",", expr and.right, "]"] },
  { rintros ["⟨", ident h1, ",", ident h2, "⟩"],
    exact [expr inter_mem h1 h2] }
end

private theorem subset_cl {X : Compactum} (A : Set X) : A ⊆ cl A :=
  fun a ha =>
    ⟨X.incl a, ha,
      by 
        simp ⟩

private theorem cl_cl {X : Compactum} (A : Set X) : cl (cl A) ⊆ cl A :=
  by 
    rintro _ ⟨F, hF, rfl⟩
    let fsu := Finset (Set (Ultrafilter X))
    let ssu := Set (Set (Ultrafilter X))
    let ι : fsu → ssu := coeₓ 
    let C0 : ssu := { Z | ∃ (B : _)(_ : B ∈ F), X.str ⁻¹' B = Z }
    let AA := { G : Ultrafilter X | A ∈ G }
    let C1 := insert AA C0 
    let C2 := finite_inter_closure C1 
    have claim1 : ∀ B C _ : B ∈ C0 _ : C ∈ C0, B ∩ C ∈ C0
    ·
      rintro B C ⟨Q, hQ, rfl⟩ ⟨R, hR, rfl⟩
      use Q ∩ R 
      simp only [and_trueₓ, eq_self_iff_true, Set.preimage_inter, Subtype.val_eq_coe]
      exact inter_sets _ hQ hR 
    have claim2 : ∀ B _ : B ∈ C0, Set.Nonempty B
    ·
      rintro B ⟨Q, hQ, rfl⟩
      obtain ⟨q⟩ := Filter.nonempty_of_mem hQ 
      use X.incl q 
      simpa 
    have claim3 : ∀ B _ : B ∈ C0, (AA ∩ B).Nonempty
    ·
      rintro B ⟨Q, hQ, rfl⟩
      have  : (Q ∩ cl A).Nonempty := Filter.nonempty_of_mem (inter_mem hQ hF)
      rcases this with ⟨q, hq1, P, hq2, hq3⟩
      refine' ⟨P, hq2, _⟩
      rw [←hq3] at hq1 
      simpa 
    suffices  : ∀ T : fsu, ι T ⊆ C1 → (⋂₀ι T).Nonempty
    ·
      obtain ⟨G, h1⟩ := exists_ultrafilter_of_finite_inter_nonempty _ this 
      use X.join G 
      have  : G.map X.str = F := Ultrafilter.coe_le_coe.1 fun S hS => h1 (Or.inr ⟨S, hS, rfl⟩)
      rw [join_distrib, this]
      exact ⟨h1 (Or.inl rfl), rfl⟩
    have claim4 := finite_inter_closure_has_finite_inter C1 
    have claim5 : HasFiniteInter C0 := ⟨⟨_, univ_mem, Set.preimage_univ⟩, claim1⟩
    have claim6 : ∀ P _ : P ∈ C2, (P : Set (Ultrafilter X)).Nonempty
    ·
      suffices  : ∀ P _ : P ∈ C2, P ∈ C0 ∨ ∃ (Q : _)(_ : Q ∈ C0), P = AA ∩ Q
      ·
        intro P hP 
        cases this P hP
        ·
          exact claim2 _ h
        ·
          rcases h with ⟨Q, hQ, rfl⟩
          exact claim3 _ hQ 
      intro P hP 
      exact claim5.finite_inter_closure_insert _ hP 
    intro T hT 
    suffices  : ⋂₀ι T ∈ C2
    ·
      exact claim6 _ this 
    apply claim4.finite_inter_mem 
    intro t ht 
    exact finite_inter_closure.basic (@hT t ht)

theorem is_closed_cl {X : Compactum} (A : Set X) : IsClosed (cl A) :=
  by 
    rw [is_closed_iff]
    intro F hF 
    exact cl_cl _ ⟨F, hF, rfl⟩

-- error in Topology.Category.Compactum: ././Mathport/Syntax/Translate/Basic.lean:340:40: in by_contradiction: ././Mathport/Syntax/Translate/Tactic/Basic.lean:41:45: missing argument
theorem str_eq_of_le_nhds
{X : Compactum}
(F : ultrafilter X)
(x : X) : «expr ≤ »(«expr↑ »(F), expr𝓝() x) → «expr = »(X.str F, x) :=
begin
  let [ident fsu] [] [":=", expr finset (set (ultrafilter X))],
  let [ident ssu] [] [":=", expr set (set (ultrafilter X))],
  let [ident ι] [":", expr fsu → ssu] [":=", expr coe],
  let [ident T0] [":", expr ssu] [":=", expr {S | «expr∃ , »((A «expr ∈ » F), «expr = »(S, basic A))}],
  let [ident AA] [] [":=", expr «expr ⁻¹' »(X.str, {x})],
  let [ident T1] [] [":=", expr insert AA T0],
  let [ident T2] [] [":=", expr finite_inter_closure T1],
  intro [ident cond],
  have [ident claim1] [":", expr ∀ A : set X, is_closed A → «expr ∈ »(A, F) → «expr ∈ »(x, A)] [],
  { intros [ident A, ident hA, ident h],
    by_contradiction [ident H],
    rw [expr le_nhds_iff] ["at", ident cond],
    specialize [expr cond «expr ᶜ»(A) H hA.is_open_compl],
    rw ["[", expr ultrafilter.mem_coe, ",", expr ultrafilter.compl_mem_iff_not_mem, "]"] ["at", ident cond],
    contradiction },
  have [ident claim2] [":", expr ∀ A : set X, «expr ∈ »(A, F) → «expr ∈ »(x, cl A)] [],
  { intros [ident A, ident hA],
    exact [expr claim1 (cl A) (is_closed_cl A) (mem_of_superset hA (subset_cl A))] },
  have [ident claim3] [":", expr ∀ S1 S2 «expr ∈ » T0, «expr ∈ »(«expr ∩ »(S1, S2), T0)] [],
  { rintros [ident S1, ident S2, "⟨", ident S1, ",", ident hS1, ",", ident rfl, "⟩", "⟨", ident S2, ",", ident hS2, ",", ident rfl, "⟩"],
    exact [expr ⟨«expr ∩ »(S1, S2), inter_mem hS1 hS2, by simp [] [] [] ["[", expr basic_inter, "]"] [] []⟩] },
  have [ident claim4] [":", expr ∀ S «expr ∈ » T0, «expr ∩ »(AA, S).nonempty] [],
  { rintros [ident S, "⟨", ident S, ",", ident hS, ",", ident rfl, "⟩"],
    rcases [expr claim2 _ hS, "with", "⟨", ident G, ",", ident hG, ",", ident hG2, "⟩"],
    exact [expr ⟨G, hG2, hG⟩] },
  have [ident claim5] [":", expr ∀ S «expr ∈ » T0, set.nonempty S] [],
  { rintros [ident S, "⟨", ident S, ",", ident hS, ",", ident rfl, "⟩"],
    exact [expr ⟨F, hS⟩] },
  have [ident claim6] [":", expr ∀ S «expr ∈ » T2, set.nonempty S] [],
  { suffices [] [":", expr ∀
     S «expr ∈ » T2, «expr ∨ »(«expr ∈ »(S, T0), «expr∃ , »((Q «expr ∈ » T0), «expr = »(S, «expr ∩ »(AA, Q))))],
    { intros [ident S, ident hS],
      cases [expr this _ hS] ["with", ident h, ident h],
      { exact [expr claim5 S h] },
      { rcases [expr h, "with", "⟨", ident Q, ",", ident hQ, ",", ident rfl, "⟩"],
        exact [expr claim4 Q hQ] } },
    intros [ident S, ident hS],
    apply [expr finite_inter_closure_insert],
    { split,
      { use [expr set.univ],
        refine [expr ⟨filter.univ_sets _, _⟩],
        ext [] [] [],
        refine [expr ⟨_, by tauto []⟩],
        { intro [],
          apply [expr filter.univ_sets] } },
      { exact [expr claim3] } },
    { exact [expr hS] } },
  suffices [] [":", expr ∀ F : fsu, «expr ⊆ »(«expr↑ »(F), T1) → «expr⋂₀ »(ι F).nonempty],
  { obtain ["⟨", ident G, ",", ident h1, "⟩", ":=", expr ultrafilter.exists_ultrafilter_of_finite_inter_nonempty _ this],
    have [ident c1] [":", expr «expr = »(X.join G, F)] [":=", expr ultrafilter.coe_le_coe.1 (λ
      P hP, h1 (or.inr ⟨P, hP, rfl⟩))],
    have [ident c2] [":", expr «expr = »(G.map X.str, X.incl x)] [],
    { refine [expr ultrafilter.coe_le_coe.1 (λ P hP, _)],
      apply [expr mem_of_superset (h1 (or.inl rfl))],
      rintros [ident x, "⟨", ident rfl, "⟩"],
      exact [expr hP] },
    simp [] [] [] ["[", "<-", expr c1, ",", expr c2, "]"] [] [] },
  intros [ident T, ident hT],
  refine [expr claim6 _ (finite_inter_mem (finite_inter_closure_has_finite_inter _) _ _)],
  intros [ident t, ident ht],
  exact [expr finite_inter_closure.basic (@hT t ht)]
end

theorem le_nhds_of_str_eq {X : Compactum} (F : Ultrafilter X) (x : X) : X.str F = x → «expr↑ » F ≤ 𝓝 x :=
  fun h =>
    le_nhds_iff.mpr
      fun s hx hs =>
        hs _$
          by 
            rwa [h]

instance  {X : Compactum} : T2Space X :=
  by 
    rw [t2_iff_ultrafilter]
    intro _ _ F hx hy 
    rw [←str_eq_of_le_nhds _ _ hx, ←str_eq_of_le_nhds _ _ hy]

/-- The structure map of a compactum actually computes limits. -/
theorem Lim_eq_str {X : Compactum} (F : Ultrafilter X) : F.Lim = X.str F :=
  by 
    rw [Ultrafilter.Lim_eq_iff_le_nhds, le_nhds_iff]
    tauto

theorem cl_eq_closure {X : Compactum} (A : Set X) : cl A = Closure A :=
  by 
    ext 
    rw [mem_closure_iff_ultrafilter]
    split 
    ·
      rintro ⟨F, h1, h2⟩
      exact ⟨F, h1, le_nhds_of_str_eq _ _ h2⟩
    ·
      rintro ⟨F, h1, h2⟩
      exact ⟨F, h1, str_eq_of_le_nhds _ _ h2⟩

/-- Any morphism of compacta is continuous. -/
theorem continuous_of_hom {X Y : Compactum} (f : X ⟶ Y) : Continuous f :=
  by 
    rw [continuous_iff_ultrafilter]
    intro x _ h 
    rw [tendsto, ←coe_map]
    apply le_nhds_of_str_eq 
    rw [←str_hom_commute, str_eq_of_le_nhds _ x h]

/-- Given any compact Hausdorff space, we construct a Compactum. -/
noncomputable def of_topological_space (X : Type _) [TopologicalSpace X] [CompactSpace X] [T2Space X] : Compactum :=
  { A := X, a := Ultrafilter.lim,
    unit' :=
      by 
        ext x 
        exact
          Lim_eq
            (by 
              finish [le_nhds_iff]),
    assoc' :=
      by 
        ext FF 
        change Ultrafilter (Ultrafilter X) at FF 
        set x := (Ultrafilter.map Ultrafilter.lim FF).lim with c1 
        have c2 : ∀ U : Set X F : Ultrafilter X, F.Lim ∈ U → IsOpen U → U ∈ F
        ·
          intro U F h1 hU 
          exact c1 ▸ is_open_iff_ultrafilter.mp hU _ h1 _ (Ultrafilter.le_nhds_Lim _)
        have c3 : «expr↑ » (Ultrafilter.map Ultrafilter.lim FF) ≤ 𝓝 x
        ·
          rw [le_nhds_iff]
          intro U hx hU 
          exact
            mem_coe.2
              (c2 _ _
                (by 
                  rwa [←c1])
                hU)
        have c4 : ∀ U : Set X, x ∈ U → IsOpen U → { G : Ultrafilter X | U ∈ G } ∈ FF
        ·
          intro U hx hU 
          suffices  : Ultrafilter.lim ⁻¹' U ∈ FF
          ·
            apply mem_of_superset this 
            intro P hP 
            exact c2 U P hP hU 
          exact @c3 U (IsOpen.mem_nhds hU hx)
        apply Lim_eq 
        rw [le_nhds_iff]
        exact c4 }

/-- Any continuous map between Compacta is a morphism of compacta. -/
def hom_of_continuous {X Y : Compactum} (f : X → Y) (cont : Continuous f) : X ⟶ Y :=
  { f,
    h' :=
      by 
        rw [continuous_iff_ultrafilter] at cont 
        ext (F : Ultrafilter X)
        specialize cont (X.str F) F (le_nhds_of_str_eq F (X.str F) rfl)
        have  := str_eq_of_le_nhds (Ultrafilter.map f F) _ cont 
        simpa only [←this, types_comp_apply, of_type_functor_map] }

end Compactum

/-- The functor functor from Compactum to CompHaus. -/
def compactumToCompHaus : Compactum ⥤ CompHaus :=
  { obj := fun X => { toTop := { α := X } },
    map := fun X Y f => { toFun := f, continuous_to_fun := Compactum.continuous_of_hom _ } }

namespace compactumToCompHaus

/-- The functor Compactum_to_CompHaus is full. -/
def full : full compactumToCompHaus.{u} :=
  { Preimage := fun X Y f => Compactum.homOfContinuous f.1 f.2 }

/-- The functor Compactum_to_CompHaus is faithful. -/
theorem faithful : faithful compactumToCompHaus :=
  {  }

/-- This definition is used to prove essential surjectivity of Compactum_to_CompHaus. -/
noncomputable def iso_of_topological_space {D : CompHaus} :
  compactumToCompHaus.obj (Compactum.ofTopologicalSpace D) ≅ D :=
  { Hom :=
      { toFun := id,
        continuous_to_fun :=
          continuous_def.2$
            fun _ h =>
              by 
                rw [is_open_iff_ultrafilter'] at h 
                exact h },
    inv :=
      { toFun := id,
        continuous_to_fun :=
          continuous_def.2$
            fun _ h1 =>
              by 
                rw [is_open_iff_ultrafilter']
                intro _ h2 
                exact h1 _ h2 } }

/-- The functor Compactum_to_CompHaus is essentially surjective. -/
theorem ess_surj : ess_surj compactumToCompHaus :=
  { mem_ess_image := fun X => ⟨Compactum.ofTopologicalSpace X, ⟨iso_of_topological_space⟩⟩ }

/-- The functor Compactum_to_CompHaus is an equivalence of categories. -/
noncomputable def is_equivalence : is_equivalence compactumToCompHaus :=
  by 
    apply equivalence.of_fully_faithfully_ess_surj _ 
    exact compactumToCompHaus.full 
    exact compactumToCompHaus.faithful 
    exact compactumToCompHaus.ess_surj

end compactumToCompHaus

