# 1. Setup Library & Design
create_lib picorv32_design_lib -technology "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/tech/saed32nm_1p9m.tf" -ref_libs "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/CLIBs/saed32_lvt.ndm"
read_verilog /home/deepen/Desktop/synthesis/Module6/picorv32_netlist_test.v
link_block
read_sdc /home/deepen/Desktop/synthesis/Module6/picorv32.sdc

# 2. Floorplan Initialization
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true
initialize_floorplan -core_utilization 0.7 -core_offset 10

# 3. Power Network Synthesis (PNS) & Pins
connect_pg_net -automatic
set_block_pin_constraints -self -allowed_layers {M2 M3} 
place_pins -self
create_pg_ring_pattern ring_pattern -nets {VDD VSS} -horizontal_layer M7 -vertical_layer M8 -horizontal_width {2} -vertical_width {2}
set_pg_strategy ring -core -pattern {{name : ring_pattern}{nets : {VDD VSS}}{offset : {1 1}}} -extension {{stop : design_boundary_and_generate_pin}}
compile_pg -strategies ring
create_pg_std_cell_conn_pattern std_pattern -check_std_cell_drc false -mark_as_follow_pin false
set_pg_strategy std_cell -core -pattern {{name : std_pattern}{nets : {VDD VSS}}} -extension {{{stop : innermost_ring}}}
compile_pg -strategies std_cell -ignore_via_drc
create_pg_mesh_pattern mesh_M7M8 -layers {{{horizontal_layer : M7} {width : 1} {spacing : 1} {offset : 54} {pitch : 56} {trim : true}} {{vertical_layer : M8} {width : 1} {spacing : 1} {offset : 54} {pitch : 57} {trim : true}}}
set_pg_strategy mesh -core -pattern {{name : mesh_M7M8}{nets : {VDD VSS}}} -extension {{{stop : innermost_ring}}}
compile_pg -strategies mesh

# 4. Parasitics & Placement
read_parasitic_tech -tlup "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/tech/saed32nm_1p9m_Cmax.lv.tluplus" -layermap "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/tech/saed32nm_tf_itf_tluplus.map" -name maxTLU
read_parasitic_tech -tlup "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus" -layermap "/home/deepen/Desktop/riscv_upm_project_core_icc2/ref/tech/saed32nm_tf_itf_tluplus.map" -name minTLU
set_parasitic_parameters -early_spec minTLU -late_spec maxTLU
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt

# 5. Clock Tree Synthesis & Routing Iterations
clock_opt
route_auto
route_opt

save_block -as picorv32_final_routed
