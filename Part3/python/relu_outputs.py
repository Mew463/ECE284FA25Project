# Read data like this, and return it relu-d:
# time0col7[msb-lsb],time0col6[msb-lst],....,time0col0[msb-lst]#
# time1col7[msb-lsb],time1col6[msb-lst],....,time1col0[msb-lst]#

ocg = 8
onijg = 16
bw = 16
psums = [["" for col in range(ocg)] for row in range(onijg)]

with open("vals/out.txt", "r") as file:  # read from file
    file_row = 0
    for line in file:
        if line.strip().isnumeric():
            for oc in range(ocg):
                val = line[oc * bw : bw * (oc + 1)]
                psums[file_row][ocg - oc - 1] = val
            file_row += 1

print(psums[0][7])
# Relu step
for onij in range(onijg):
    for oc in range(ocg):
        # 1. Convert to int
        # val_int = int(psums[onij][oc], 2)
        # 2. ReLU
        # val_int = max(0, val_int)
        # 3. convert to bits
        if psums[onij][oc][0] == "1":
            psums[onij][oc] = "0" * bw
            # print(f"Relud at onij {onij} and oc {oc}")


with open("vals/out_relu.txt", "w") as file:
    file.write("time0col7[msb-lsb],time0col6[msb-lst],....,time0col0[msb-lst]#\n")
    file.write("time1col7[msb-lsb],time1col6[msb-lst],....,time1col0[msb-lst]#\n")
    file.write("#................#\n")
    for onij in range(onijg):
        for oc in range(ocg - 1, -1, -1):
            file.write(psums[onij][oc])
        file.write("\n")
