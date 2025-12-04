# Estimated power savings assuming 17.36% (100/576) weight sparsity.

### MAC unit
* We have about 288 activations ( 36 rows x 8 columns)
* We have about 576 weights ( 8 rows x 8 columns x 9 weight files)
* A given weight receives 8 activations in one mac tile.
* Assuming Multipler ~ 65% of power and Adder ~ 35% of power
  * Active: 82.64% : P_active = P_mult + P_add
  * Gated:  17.36% : P_gated $ \approx 0 $

* P_normal = 1 * P_mac
* P_gated_total = (0.8264 x P_active) + (0.1736 x P_gated)
* P_gated_total = (0.8264 x P_active)

### MAC tile
* However, we also have new flip flop buffer registers and muxes switching for the out_e and out_s ports.  
* We approximate the MAC unit is about 70% of the MAC tile's power and 30% is the additional logic
  * P_mac_gated   = 0.8264 x P_mac = 0.8264 x (0.7 x P_tile) = 0.5785 x P_tile
  * P_logic_gated = 1.0 x P_logic = 1.0 x 0.3 x P_tile = 0.30 x P_tile
  * P_gated = 0.5785 x P_tile + 0.30 x P_tile = 0.8785 x P_tile

### Power Saved = 1.0 x P_tile - 0.8785 x P_tile = 0.1215 x P_tile = 12.15%