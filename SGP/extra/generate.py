import sys

tcl = """
RDATA_SET
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdata} -radix hex {COMMAND_GOES_HERE 0ns}
EXTRA_DELAY
"""

if (len(sys.argv) != 3):
	exit("uh oh spaghettio")
	
file = open(sys.argv[1], "r")
inst = file.read()
file.close()

hex = inst.split(" ")

out = """restart
add_wave {{/sgp_vertexShader/sgp_vertexShader_core}} 
add_force {/sgp_vertexShader/ACLK} -radix hex {1 0ns} {0 50000ps} -repeat_every 100000ps
add_force {/sgp_vertexShader/ARESETN} -radix hex {0 0ns}
run 100 ns
add_force {/sgp_vertexShader/ARESETN} -radix hex {1 0ns}
run 100 ns
add_force {/sgp_vertexShader/vertexshader_pc} -radix hex {80000000 0ns}
run 100 ns
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdata} -radix hex {00000000 0ns}
add_force {/sgp_vertexShader/S_AXIS_TDATA} -radix hex {000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f30313233343536370002000000010000 0ns}
add_force {/sgp_vertexShader/S_AXIS_TVALID} -radix hex {1 0ns}
run 400 ns

add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_rdy} -radix hex {1 0ns}
add_force {/sgp_vertexShader/sgp_vertexShader_core/imem_req_done} -radix hex {1 0ns}
add_force {/sgp_vertexShader/sgp_vertexShader_core/dmem_rdy} -radix hex {1 0ns}
add_force {/sgp_vertexShader/sgp_vertexShader_core/dmem_req_done} -radix hex {1 0ns}
"""

for i in range(0, int(len(hex) / 4)):
	line = hex[3 + i*4] + hex[2 + i*4] + hex[1 + i*4] + hex[0 + i*4]
	command = tcl.replace("COMMAND_GOES_HERE", line)
	
	delay = "run 400 ns"
	if line[0:2] == "04":
		delay = "run 500 ns"
	if line[0:2] == "05":
		delay = "run 500 ns"
	if line[0:2] == "22":
		delay = "run 700 ns"
	command = command.replace("EXTRA_DELAY", delay)
	
	rdata = ""
	if line[0:2] == "04":
		rdata = "add_force {/sgp_vertexShader/sgp_vertexShader_core/dmem_rdata} -radix hex {"
		if line == "04100F00":
			rdata += "00010000"
		if line == "04141300":
			rdata += "00020000"
		if line == "04180900":
			rdata += "00001f97"
		if line == "04180904":
			rdata += "00003f2e"
		if line == "04180908":
			rdata += "34353637"
		if line == "0418090C":
			rdata += "00010000"
		rdata += " 0ns}"
	
	command = command.replace("RDATA_SET", rdata)
	
	out = out + command
	

file = open(sys.argv[2], "w")
file.write(out)
file.close()
