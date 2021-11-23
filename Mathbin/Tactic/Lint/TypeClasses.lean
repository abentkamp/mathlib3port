import Mathbin.Data.Bool 
import Mathbin.Meta.RbMap 
import Mathbin.Tactic.Lint.Basic

/-!
# Linters about type classes

This file defines several linters checking the correct usage of type classes
and the appropriate definition of instances:

 * `instance_priority` ensures that blanket instances have low priority.
 * `has_inhabited_instances` checks that every type has an `inhabited` instance.
 * `impossible_instance` checks that there are no instances which can never apply.
 * `incorrect_type_class_argument` checks that only type classes are used in
   instance-implicit arguments.
 * `dangerous_instance` checks for instances that generate subproblems with metavariables.
 * `fails_quickly` checks that type class resolution finishes quickly.
 * `class_structure` checks that every `class` is a structure, i.e. `@[class] def` is forbidden.
 * `has_coe_variable` checks that there is no instance of type `has_coe α t`.
 * `inhabited_nonempty` checks whether `[inhabited α]` arguments could be generalized
   to `[nonempty α]`.
 * `decidable_classical` checks propositions for `[decidable_... p]` hypotheses that are not used
   in the statement, and could thus be removed by using `classical` in the proof.
 * `linter.has_coe_to_fun` checks whether necessary `has_coe_to_fun` instances are declared.
 * `linter.check_reducibility` checks whether non-instances with a class as type are reducible.
-/


open Tactic

/-- Pretty prints a list of arguments of a declaration. Assumes `l` is a list of argument positions
and binders (or any other element that can be pretty printed).
`l` can be obtained e.g. by applying `list.indexes_values` to a list obtained by
`get_pi_binders`. -/
unsafe def print_arguments {α} [has_to_tactic_format α] (l : List (ℕ × α)) : tactic Stringₓ :=
  do 
    let fs ← l.mmap fun ⟨n, b⟩ => (fun s => to_fmt "argument " ++ to_fmt (n+1) ++ ": " ++ s) <$> pp b 
    return$ fs.to_string_aux tt

/-- checks whether an instance that always applies has priority ≥ 1000. -/
private unsafe def instance_priority (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let nm := d.to_name 
    let b ← is_instance nm 
    if ¬b then return none else
        do 
          let (is_persistent, prio) ← has_attribute `instance nm 
          if prio < 1000 then return none else
              do 
                let (_, tp) ← open_pis d.type 
                let tp ← whnf tp transparency.none 
                let (fn, args) := tp.get_app_fn_args 
                let cls ← get_decl fn.const_name 
                let (pi_args, _) := cls.type.pi_binders 
                guardₓ (args.length = pi_args.length)
                let relevant_args :=
                  (args.zip pi_args).filterMap$
                    fun ⟨e, ⟨_, info, tp⟩⟩ =>
                      if info = BinderInfo.inst_implicit ∨ tp.get_app_fn.is_constant_of `out_param then none else
                        some e 
                let always_applies := relevant_args.all expr.is_local_constant ∧ relevant_args.nodup 
                if always_applies then return$ some "set priority below 1000" else return none

/--
There are places where typeclass arguments are specified with implicit `{}` brackets instead of
the usual `[]` brackets. This is done when the instances can be inferred because they are implicit
arguments to the type of one of the other arguments. When they can be inferred from these other
arguments,  it is faster to use this method than to use type class inference.

For example, when writing lemmas about `(f : α →+* β)`, it is faster to specify the fact that `α`
and `β` are `semiring`s as `{rα : semiring α} {rβ : semiring β}` rather than the usual
`[semiring α] [semiring β]`.
-/
library_note "implicit instance arguments"

/--
Certain instances always apply during type-class resolution. For example, the instance
`add_comm_group.to_add_group {α} [add_comm_group α] : add_group α` applies to all type-class
resolution problems of the form `add_group _`, and type-class inference will then do an
exhaustive search to find a commutative group. These instances take a long time to fail.
Other instances will only apply if the goal has a certain shape. For example
`int.add_group : add_group ℤ` or
`add_group.prod {α β} [add_group α] [add_group β] : add_group (α × β)`. Usually these instances
will fail quickly, and when they apply, they are almost the desired instance.
For this reason, we want the instances of the second type (that only apply in specific cases) to
always have higher priority than the instances of the first type (that always apply).
See also #1561.

Therefore, if we create an instance that always applies, we set the priority of these instances to
100 (or something similar, which is below the default value of 1000).
-/
library_note "lower instance priority"

/-- A linter object for checking instance priorities of instances that always apply.
This is in the default linter set. -/
@[linter]
unsafe def linter.instance_priority : linter :=
  { test := instance_priority, no_errors_found := "All instance priorities are good.",
    errors_found :=
      "DANGEROUS INSTANCE PRIORITIES.\nThe following instances always apply, and therefore should have a priority < 1000.\nIf you don't know what priority to choose, use priority 100.\nSee note [lower instance priority] for instructions to change the priority.",
    auto_decls := tt }

/-- Reports declarations of types that do not have an associated `inhabited` instance. -/
private unsafe def has_inhabited_instance (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← pure d.is_trusted | pure none 
    let ff ← has_attribute' `reducible d.to_name | pure none 
    let ff ← has_attribute' `class d.to_name | pure none 
    let (_, ty) ← open_pis d.type 
    let ty ← whnf ty 
    if ty = quote.1 Prop then pure none else
        do 
          let quote.1 (Sort _) ← whnf ty | pure none 
          let insts ← attribute.get_instances `instance 
          let insts_tys ← insts.mmap$ fun i => expr.pi_codomain <$> declaration.type <$> get_decl i 
          let inhabited_insts :=
            insts_tys.filter fun i => i.app_fn.const_name = `` Inhabited ∨ i.app_fn.const_name = `unique 
          let inhabited_tys := inhabited_insts.map fun i => i.app_arg.get_app_fn.const_name 
          if d.to_name ∈ inhabited_tys then pure none else pure "inhabited instance missing"

/-- A linter for missing `inhabited` instances. -/
@[linter]
unsafe def linter.has_inhabited_instance : linter :=
  { test := has_inhabited_instance, auto_decls := ff, no_errors_found := "No types have missing inhabited instances.",
    errors_found := "TYPES ARE MISSING INHABITED INSTANCES:", is_fast := ff }

attribute [nolint has_inhabited_instance] Pempty

/-- Checks whether an instance can never be applied. -/
private unsafe def impossible_instance (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_instance d.to_name | return none 
    let (binders, _) ← get_pi_binders_nondep d.type 
    let bad_arguments := binders.filter$ fun nb => nb.2.info ≠ BinderInfo.inst_implicit 
    let _ :: _ ← return bad_arguments | return none
    (fun s => some$ "Impossible to infer " ++ s) <$> print_arguments bad_arguments

/-- A linter object for `impossible_instance`. -/
@[linter]
unsafe def linter.impossible_instance : linter :=
  { test := impossible_instance, auto_decls := tt, no_errors_found := "All instances are applicable.",
    errors_found :=
      "IMPOSSIBLE INSTANCES FOUND.\nThese instances have an argument that cannot be found during type-class resolution, and " ++
          "therefore can never succeed. Either mark the arguments with square brackets (if it is a " ++
        "class), or don't make it an instance." }

/-- Checks whether an instance can never be applied. -/
private unsafe def incorrect_type_class_argument (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let (binders, _) ← get_pi_binders d.type 
    let instance_arguments := binders.indexes_values$ fun b : binder => b.info = BinderInfo.inst_implicit 
    let bad_arguments ←
      instance_arguments.mfilter
          fun ⟨_, b⟩ =>
            do 
              let (_, head) ← open_pis b.type 
              if head.get_app_fn.is_local_constant then return ff else
                  do 
                    bnot <$> is_class head 
    let _ :: _ ← return bad_arguments | return none
    (fun s => some$ "These are not classes. " ++ s) <$> print_arguments bad_arguments

/-- A linter object for `incorrect_type_class_argument`. -/
@[linter]
unsafe def linter.incorrect_type_class_argument : linter :=
  { test := incorrect_type_class_argument, auto_decls := tt,
    no_errors_found := "All declarations have correct type-class arguments.",
    errors_found := "INCORRECT TYPE-CLASS ARGUMENTS.\nSome declarations have non-classes between [square brackets]:" }

/-- Checks whether an instance is dangerous: it creates a new type-class problem with metavariable
arguments. -/
private unsafe def dangerous_instance (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_instance d.to_name | return none 
    let (local_constants, target) ← open_pis d.type 
    let instance_arguments :=
      local_constants.indexes_values$ fun e : expr => e.local_binding_info = BinderInfo.inst_implicit 
    let bad_arguments :=
      local_constants.indexes_values$
        fun x =>
          !target.has_local_constant x && x.local_binding_info ≠ BinderInfo.inst_implicit &&
            instance_arguments.any fun nb => nb.2.local_type.has_local_constant x 
    let bad_arguments : List (ℕ × binder) := bad_arguments.map$ fun ⟨n, e⟩ => ⟨n, e.to_binder⟩
    let _ :: _ ← return bad_arguments | return none
    (fun s => some$ "The following arguments become metavariables. " ++ s) <$> print_arguments bad_arguments

/-- A linter object for `dangerous_instance`. -/
@[linter]
unsafe def linter.dangerous_instance : linter :=
  { test := dangerous_instance, no_errors_found := "No dangerous instances.",
    errors_found :=
      "DANGEROUS INSTANCES FOUND.\nThese instances are recursive, and create a new " ++
          "type-class problem which will have metavariables.\nPossible solution: remove the instance attribute or make it a local instance instead.\n\nCurrently this linter does not check whether the metavariables only occur in arguments marked " ++
        "with `out_param`, in which case this linter gives a false positive.",
    auto_decls := tt }

/-- Auxilliary definition for `find_nondep` -/
unsafe def find_nondep_aux : List expr → expr_set → tactic expr_set
| [], r => return r
| h :: hs, r =>
  do 
    let type ← infer_type h 
    find_nondep_aux hs$ r.union type.list_local_consts'

/-- Finds all hypotheses that don't occur in the target or other hypotheses. -/
unsafe def find_nondep : tactic (List expr) :=
  do 
    let ctx ← local_context 
    let tgt ← target 
    let lconsts ← find_nondep_aux ctx tgt.list_local_consts' 
    return$ ctx.filter$ fun e => !lconsts.contains e

/--
Tests whether type-class inference search will end quickly on certain unsolvable
type-class problems. This is to detect loops or very slow searches, which are problematic
(recall that normal type-class search often creates unsolvable subproblems, which have to fail
quickly for type-class inference to perform well.
We create these type-class problems by taking an instance, and removing the last hypothesis that
doesn't appear in the goal (or a later hypothesis). Note: this argument is necessarily an
instance-implicit argument if it passes the `linter.incorrect_type_class_argument`.
This tactic succeeds if `mk_instance` succeeds quickly or fails quickly with the error
message that it cannot find an instance. It fails if the tactic takes too long, or if any other
error message is raised (usually a maximum depth in the search).
-/
unsafe def fails_quickly (max_steps : ℕ) (d : declaration) : tactic (Option Stringₓ) :=
  retrieve$
    do 
      let tt ← is_instance d.to_name | return none 
      let e := d.type 
      let g ← mk_meta_var e 
      set_goals [g]
      intros 
      let l@(_ :: _) ← find_nondep | return none 
      clear l.ilast 
      reset_instance_cache 
      let state ← read 
      let state_msg := "\nState:\n" ++ toString State 
      let tgt ← target >>= instantiate_mvars 
      let Sum.inr msg ← retrieve_or_report_error$ tactic.try_for max_steps$ mk_instance tgt | return none 
      return$
          if "tactic.mk_instance failed to generate instance for".isPrefixOf msg then none else
            some$
              · ++ state_msg$ if msg = "try_for tactic failed, timeout" then "type-class inference timed out" else msg

/--
A linter object for `fails_quickly`.
We currently set the number of steps in the type-class search pretty high.
Some instances take quite some time to fail, and we seem to run against the caching issue in
https://leanprover.zulipchat.com/#narrow/stream/113488-general/topic/odd.20repeated.20type.20class.20search
-/
@[linter]
unsafe def linter.fails_quickly : linter :=
  { test := fails_quickly 10000, auto_decls := tt, no_errors_found := "No type-class searches timed out.",
    errors_found :=
      "TYPE CLASS SEARCHES TIMED OUT.\nThe following instances are part of a loop, or an excessively long search.\nIt is common that the loop occurs in a different class than the one flagged below,\nbut usually an instance that is part of the loop is also flagged.\nTo debug:\n(1) run `scripts/mk_all.sh` and create a file with `import all` and\n`set_option trace.class_instances true`\n(2) Recreate the state shown in the error message. You can do this easily by copying the type of\nthe instance (the output of `#check @my_instance`), turning this into an example and removing the\nlast argument in square brackets. Prove the example using `by apply_instance`.\nFor example, if `additive.topological_add_group` raises an error, run\n```\nexample {G : Type*} [topological_space G] [group G] : topological_add_group (additive G) :=\nby apply_instance\n```\n(3) What error do you get?\n(3a) If the error is \"tactic.mk_instance failed to generate instance\",\nthere might be nothing wrong. But it might take unreasonably long for the type-class inference to\nfail. Check the trace to see if type-class inference takes any unnecessary long unexpected turns.\nIf not, feel free to increase the value in the definition of the linter `fails_quickly`.\n(3b) If the error is \"maximum class-instance resolution depth has been reached\" there is almost\ncertainly a loop in the type-class inference. Find which instance causes the type-class inference to\ngo astray, and fix that instance.",
    is_fast := ff }

/-- Checks that all uses of the `@[class]` attribute apply to structures or inductive types.
  This is future-proofing for lean 4, which no longer supports `@[class] def`. -/
private unsafe def class_structure (n : Name) : tactic (Option Stringₓ) :=
  do 
    let is_class ← has_attribute' `class n 
    if is_class then
        do 
          let env ← get_env 
          pure$ if env.is_inductive n then none else "is a non-structure or inductive type marked @[class]"
      else pure none

/-- A linter object for `class_structure`. -/
@[linter]
unsafe def linter.class_structure : linter :=
  { test := fun d => class_structure d.to_name, auto_decls := tt, no_errors_found := "All classes are structures.",
    errors_found := "USE OF @[class] def IS DISALLOWED:" }

/--
Tests whether there is no instance of type `has_coe α t` where `α` is a variable,
or `has_coe t α` where `α` does not occur in `t`.
See note [use has_coe_t].
-/
private unsafe def has_coe_variable (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_instance d.to_name | return none 
    let quote.1 (Coe (%%ₓa) (%%ₓb)) ← return d.type.pi_codomain | return none 
    if a.is_var then return$ some$ "illegal instance, first argument is variable" else
        if b.is_var ∧ ¬b.occurs a then
          return$ some$ "illegal instance, second argument is variable not occurring in first argument" else return none

/-- A linter object for `has_coe_variable`. -/
@[linter]
unsafe def linter.has_coe_variable : linter :=
  { test := has_coe_variable, auto_decls := tt, no_errors_found := "No invalid `has_coe` instances.",
    errors_found :=
      "INVALID `has_coe` INSTANCES.\nMake the following declarations instances of the class `has_coe_t` instead of `has_coe`." }

/-- Checks whether a declaration is prop-valued and takes an `inhabited _` argument that is unused
elsewhere in the type. In this case, that argument can be replaced with `nonempty _`. -/
private unsafe def inhabited_nonempty (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_prop d.type | return none 
    let (binders, _) ← get_pi_binders_nondep d.type 
    let inhd_binders := binders.filter$ fun pr => pr.2.type.is_app_of `inhabited 
    if inhd_binders.length = 0 then return none else
        (fun s => some$ "The following `inhabited` instances should be `nonempty`. " ++ s) <$>
          print_arguments inhd_binders

/-- A linter object for `inhabited_nonempty`. -/
@[linter]
unsafe def linter.inhabited_nonempty : linter :=
  { test := inhabited_nonempty, auto_decls := ff,
    no_errors_found := "No uses of `inhabited` arguments should be replaced with `nonempty`.",
    errors_found := "USES OF `inhabited` SHOULD BE REPLACED WITH `nonempty`." }

/-- Checks whether a declaration is `Prop`-valued and takes a `decidable* _`
hypothesis that is unused lsewhere in the type.
In this case, that hypothesis can be replaced with `classical` in the proof.
Theorems in the `decidable` namespace are exempt from the check. -/
private unsafe def decidable_classical (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_prop d.type | return none 
    let ff ← pure$ `decidable.isPrefixOf d.to_name | return none 
    let (binders, _) ← get_pi_binders_nondep d.type 
    let deceq_binders :=
      binders.filter$
        fun pr =>
          pr.2.type.is_app_of `decidable_eq ∨
            pr.2.type.is_app_of `decidable_pred ∨ pr.2.type.is_app_of `decidable_rel ∨ pr.2.type.is_app_of `decidable 
    if deceq_binders.length = 0 then return none else
        (fun s =>
            some$
              "The following `decidable` hypotheses should be replaced with\n                      `classical` in the proof. " ++
                s) <$>
          print_arguments deceq_binders

/-- A linter object for `decidable_classical`. -/
@[linter]
unsafe def linter.decidable_classical : linter :=
  { test := decidable_classical, auto_decls := ff,
    no_errors_found := "No uses of `decidable` arguments should be replaced with `classical`.",
    errors_found := "USES OF `decidable` SHOULD BE REPLACED WITH `classical` IN THE PROOF." }

attribute [nolint decidable_classical] dec_em dec_em' Not.decidable_imp_symm

private unsafe def has_coe_to_fun_linter (d : declaration) : tactic (Option Stringₓ) :=
  retrieve$
    do 
      let tt ← return d.is_trusted | pure none 
      mk_meta_var d.type >>= set_goals ∘ pure 
      let args ← unfreezing intros 
      let expr.sort _ ← target | pure none 
      let ty : expr := (expr.const d.to_name d.univ_levels).mk_app args 
      let some coe_fn_inst ← try_core$ to_expr (pquote.1 (_root_.has_coe_to_fun (%%ₓty) _)) >>= mk_instance | pure none 
      set_bool_option `pp.all True 
      let some trans_inst@(expr.app (expr.app _ trans_inst_1) trans_inst_2) ←
        try_core$ to_expr (pquote.1 (@_root_.coe_fn_trans (%%ₓty) _ _ _ _)) | pure none 
      let tt ← succeeds$ unify trans_inst coe_fn_inst transparency.reducible | pure none 
      set_bool_option `pp.all True 
      let trans_inst_1 ← pp trans_inst_1 
      let trans_inst_2 ← pp trans_inst_2 
      pure$
          format.to_string$
            "`has_coe_to_fun` instance is definitionally equal to a transitive instance composed of: " ++
                    trans_inst_1.group.indent 2 ++
                  format.line ++
                "and" ++
              trans_inst_2.group.indent 2

/-- Linter that checks whether `has_coe_to_fun` instances comply with Note [function coercion]. -/
@[linter]
unsafe def linter.has_coe_to_fun : linter :=
  { test := has_coe_to_fun_linter, auto_decls := tt, no_errors_found := "has_coe_to_fun is used correctly",
    errors_found :=
      "INVALID/MISSING `has_coe_to_fun` instances.\nYou should add a `has_coe_to_fun` instance for the following types.\nSee Note [function coercion]." }

/--
Checks whether an instance contains a semireducible non-instance with a class as
type in its value. We add some restrictions to get not too many false positives:
* We only consider classes with an `add` or `mul` field, since those classes are most likely to
  occur as a field to another class, and be an extension of another class.
* We only consider instances of type-valued classes and non-instances that are definitions.
* We currently ignore declarations `foo` that have a `foo._main` declaration. We could look inside,
or at the generated equation lemmas, but it's unlikely that there are many problematic instances
defined using the equation compiler.
-/
unsafe def check_reducible_non_instances (d : declaration) : tactic (Option Stringₓ) :=
  do 
    let tt ← is_instance d.to_name | return none 
    let ff ← is_prop d.type | return none 
    let env ← get_env 
    let cls := d.type.pi_codomain.get_app_fn.const_name 
    let some constrs ← return$ env.structure_fields cls | return none 
    let tt ← return$ constrs.mem `add || constrs.mem `mul | return none 
    let l ←
      d.value.list_constant.mfilter$
          fun nm =>
            do 
              let d ← env.get nm 
              let ff ← is_instance nm | return ff 
              let tt ← is_class d.type | return ff 
              let tt ← return d.is_definition | return ff 
              let cls := d.type.pi_codomain.get_app_fn.const_name 
              let some constrs ← return$ env.structure_fields cls | return ff 
              let tt ← return$ constrs.mem `add || constrs.mem `mul | return ff 
              let ff ← has_attribute' `reducible nm | return ff 
              return tt 
    if l.empty then return none else
        if l.to_list = [d.to_name ++ `_main] then return none else
          return$
            some$
              "This instance contains the declarations " ++ toString l.to_list ++
                ", which are semireducible non-instances."

/-- A linter that checks whether an instance contains a semireducible non-instance. -/
@[linter]
unsafe def linter.check_reducibility : linter :=
  { test := check_reducible_non_instances, auto_decls := ff, no_errors_found := "All non-instances are reducible.",
    errors_found :=
      "THE FOLLOWING INSTANCES MIGHT NOT REDUCE.\nThese instances contain one or more declarations that are not instances and are also not marked\n`@[reducible]`. This means that type-class inference cannot unfold these declarations, " ++
            "which might mean that type-class inference cannot infer that two instances are definitionally " ++
          "equal. This can cause unexpected errors when this class occurs " ++
        "as an *argument* to a type-class problem. See note [reducible non-instances].",
    is_fast := tt }

