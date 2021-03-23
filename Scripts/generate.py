import sys

tcl = """
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdy} -radix hex {1 0ns}
run 100 ns
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdy} -radix hex {0 0ns}
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_req_done} -radix hex {1 0ns}
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdata} -radix hex {COMMAND_GOES_HERE 0ns}
run 100 ns
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdy} -radix hex {1 0ns}
run 200 ns

"""

if (len(sys.argv) != 3):
	exit("uh oh spaghettio")
	
file = open(sys.argv[1], "r")
inst = file.read()
file.close()

hex = inst.split(" ")

out = """
restart
add_force {/sgp_vertexShader/ACLK} -radix hex {1 0ns} {0 50000ps} -repeat_every 100000ps
add_force {/sgp_vertexShader/ARESETN} -radix hex {0 0ns}
run 100 ns
add_force {/sgp_vertexShader/ARESETN} -radix hex {1 0ns}
run 100 ns
add_force {/sgp_vertexShader/vertexshader_pc} -radix hex {80000000 0ns}
run 100 ns
add_wave {{/sgp_vertexShader/sgp_vertexShader_core}} 
add_force {/sgp_vertexShader/S_AXIS_TDATA} -radix hex {000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f 0ns}
add_force {/sgp_vertexShader/S_AXIS_TVALID} -radix hex {1 0ns}
run 200 ns

"""

for i in range(0, int(len(hex) / 4)):
	line = hex[3 + i*4] + hex[2 + i*4] + hex[1 + i*4] + hex[0 + i*4]
	out = out + tcl.replace("COMMAND_GOES_HERE", line)
	

file = open(sys.argv[2], "w")
file.write(out)
file.close()
