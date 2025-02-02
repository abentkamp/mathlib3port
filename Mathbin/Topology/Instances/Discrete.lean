/-
Copyright (c) 2022 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Mathbin.Order.SuccPred.Basic
import Mathbin.Topology.Algebra.Order.Basic

/-!
# Instances related to the discrete topology

We prove that the discrete topology is a first-countable topology, and is second-countable for an
encodable type. Also, in linear orders which are also `pred_order` and `succ_order`, the discrete
topology is the order topology.

When importing this file and `data.nat.succ_pred`, the instances `second_countable_topology ℕ`
and `order_topology ℕ` become available.

-/


open Order Set TopologicalSpace

variable {α : Type _} [TopologicalSpace α]

instance (priority := 100) DiscreteTopology.first_countable_topology [DiscreteTopology α] :
    FirstCountableTopology α where nhds_generated_countable := by
    rw [nhds_discrete]
    exact Filter.is_countably_generated_pure

instance (priority := 100) DiscreteTopology.second_countable_topology_of_encodable [hd : DiscreteTopology α]
    [Encodable α] : SecondCountableTopology α := by
  have : ∀ i : α, second_countable_topology ↥({i} : Set α) := fun i =>
    { is_open_generated_countable :=
        ⟨{univ}, countable_singleton _, by
          simp only [eq_iff_true_of_subsingleton]⟩ }
  exact second_countable_topology_of_countable_cover (singletons_open_iff_discrete.mpr hd) (Union_of_singleton α)

instance (priority := 100) DiscreteTopology.order_topology_of_pred_succ' [h : DiscreteTopology α] [PartialOrderₓ α]
    [PredOrder α] [SuccOrder α] [NoMinOrder α] [NoMaxOrder α] : OrderTopology α :=
  ⟨by
    rw [h.eq_bot]
    refine' (eq_bot_of_singletons_open fun a => _).symm
    have h_singleton_eq_inter : {a} = Iio (succ a) ∩ Ioi (pred a) := by
      suffices h_singleton_eq_inter' : {a} = Iic a ∩ Ici a
      · rw [h_singleton_eq_inter', ← Ioi_pred, ← Iio_succ]
        
      rw [inter_comm, Ici_inter_Iic, Icc_self a]
    rw [h_singleton_eq_inter]
    apply IsOpen.inter
    · exact is_open_generate_from_of_mem ⟨succ a, Or.inr rfl⟩
      
    · exact is_open_generate_from_of_mem ⟨pred a, Or.inl rfl⟩
      ⟩

instance (priority := 100) DiscreteTopology.order_topology_of_pred_succ [h : DiscreteTopology α] [LinearOrderₓ α]
    [PredOrder α] [SuccOrder α] : OrderTopology α :=
  ⟨by
    rw [h.eq_bot]
    refine' (eq_bot_of_singletons_open fun a => _).symm
    have h_singleton_eq_inter : {a} = Iic a ∩ Ici a := by
      rw [inter_comm, Ici_inter_Iic, Icc_self a]
    by_cases' ha_top : IsTop a
    · rw [ha_top.Iic_eq, inter_comm, inter_univ] at h_singleton_eq_inter
      by_cases' ha_bot : IsBot a
      · rw [ha_bot.Ici_eq] at h_singleton_eq_inter
        rw [h_singleton_eq_inter]
        apply is_open_univ
        
      · rw [is_bot_iff_is_min] at ha_bot
        rw [← Ioi_pred_of_not_is_min ha_bot] at h_singleton_eq_inter
        rw [h_singleton_eq_inter]
        exact is_open_generate_from_of_mem ⟨pred a, Or.inl rfl⟩
        
      
    · rw [is_top_iff_is_max] at ha_top
      rw [← Iio_succ_of_not_is_max ha_top] at h_singleton_eq_inter
      by_cases' ha_bot : IsBot a
      · rw [ha_bot.Ici_eq, inter_univ] at h_singleton_eq_inter
        rw [h_singleton_eq_inter]
        exact is_open_generate_from_of_mem ⟨succ a, Or.inr rfl⟩
        
      · rw [is_bot_iff_is_min] at ha_bot
        rw [← Ioi_pred_of_not_is_min ha_bot] at h_singleton_eq_inter
        rw [h_singleton_eq_inter]
        apply IsOpen.inter
        · exact is_open_generate_from_of_mem ⟨succ a, Or.inr rfl⟩
          
        · exact is_open_generate_from_of_mem ⟨pred a, Or.inl rfl⟩
          
        
      ⟩

