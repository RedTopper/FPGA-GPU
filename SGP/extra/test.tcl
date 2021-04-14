restart
add_force {/sgp_rasterizer/ACLK} -radix hex {1 0ns} {0 50000ps} -repeat_every 100000ps
add_force {/sgp_rasterizer/primitiveAssembly_inst/primout_ready} -radix hex {0 0ns}
add_force {/sgp_rasterizer/triangleTest_inst/fragment_out_ready} -radix hex {1 0ns}
add_force {/sgp_rasterizer/ARESETN} -radix hex {0 0ns}
run 100 ns
add_force {/sgp_rasterizer/ARESETN} -radix hex {1 0ns}
run 100 ns
add_force {/sgp_rasterizer/primitiveAssembly_inst/primtype} -radix hex {4 0ns}
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_in_final} -radix hex {0 0ns}
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_valid} -radix hex {1 0ns}
add_force {/sgp_rasterizer/primitiveAssembly_inst/primout_ready} -radix hex {1 0ns}
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_in} -radix hex {0000000000000000000000000000000000000000000000000438000000010000 0ns}
run 100 ns
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_in} -radix hex {0000000000000000000000000000000000000000000000000434000000010000 0ns}
run 100 ns
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_in} -radix hex {0000000000000000000000000000000000000000000000000434000000050000 0ns}
run 100 ns
add_force {/sgp_rasterizer/primitiveAssembly_inst/vertex_valid} -radix hex {0 0ns}
# getst to that one point
run 4100 ns
# gets to triangle start
run 2300 ns
