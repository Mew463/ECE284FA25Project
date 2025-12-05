# kij is per file
# col0row7[msb-lsb],col0row6[msb-lst],....,col0row0[msb-lst]#
# col1row7[msb-lsb],col1row6[msb-lst],....,col1row0[msb-lst]#
# ................#

kijg = 9
out_channels = 8
input_channels = 8
bw = 4

file_list = []

for kij in range(kijg):
    file_list.append(f"vals/weight{kij}.txt")
print(file_list)


weights = [
    [["" for col in range(kijg)] for col in range(out_channels)]
    for row in range(input_channels)
]  # (input_channels, output_channels, kijg)

# print(len(weights))
# print(len(weights[0]))
# print(len(weights[0][0]))

for kij, file_name in enumerate(file_list):
    with open(file_name, "r") as file:  # read from file
        file_row = 0
        for line in file:
            line = line.strip()
            if line.isnumeric():
                for in_c_index in range(0, input_channels):
                    in_w = line[in_c_index * bw : bw * (in_c_index + 1)]
                    weights[input_channels - in_c_index - 1][file_row][kij] = in_w
                file_row += 1

print(weights[6][0][2])

# Output format
# col7kij0ic0, col6kij0ic0, col5kij0ic0......col70kij0ic0,
# col7kij1ic0, col6kij1ic0, col5kij1ic0......col70kij1ic0,
# col7kij2ic0, col6kij2ic0, col5kij2ic0......col70kij2ic0,
# ........................................................
# col7kij8ic0, col6kij8ic0, col5kij8ic0......col70kij8ic0,
# col7kij0ic1, col6kij0ic1, col5kij0ic1......col70kij0ic1,
# col7kij1ic1, col6kij1ic1, col5kij1ic1......col70kij1ic1,
with open("vals/weights_os.txt", "w") as file:
    file.write("#col7kij0ic0,col6kij0ic0,col5kij0ic0......col70kij0ic0,\n")
    file.write("#col7kij1ic0,col6kij1ic0,col5kij1ic0......col70kij1ic0,\n")
    file.write("#col7kij2ic0,col6kij2ic0,col5kij2ic0......col70kij2ic0,\n")
    file.write("#......................................................\n")
    file.write("#col7kij8ic0,col6kij8ic0,col5kij8ic0......col70kij8ic0,\n")
    file.write("#col7kij0ic1,col6kij0ic1,col5kij0ic1......col70kij0ic1,\n")
    file.write("#col7kij1ic1,col6kij1ic1,col5kij1ic1......col70kij1ic1,\n")

    for ic in range(input_channels):
        for kij in range(kijg):
            for col in range(out_channels - 1, -1, -1):
                file.write(weights[ic][col][kij])
                # print(f"col{col}kij{kij}ic{ic}", end=", ")
            # print("\n")
            file.write("\n")
