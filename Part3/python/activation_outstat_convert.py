from numpy._core.strings import isnumeric

# nij0ic7[msb-lsb], nij0ic6[msb-lst],....,nij0ic0[msb-lst]#
# nij1ic7[msb-lsb], nij1ic6[msb-lst],....,nij1ic0[msb-lst]#

input_channels = 8
input_positions = 36
bw = 4
# activations = np.zeros(
#     (input_positions, input_channels), np.uint16
# )  # nij by input_channel
activations = [["" for col in range(input_channels)] for row in range(input_positions)]
# print(activations.shape)
with open("vals/activation.txt", "r") as file:  # read from file
    file_row = 0
    for line in file:
        if isnumeric(line.strip()):
            for in_c_index in range(0, input_channels):
                in_c = line[in_c_index * bw : bw * (in_c_index + 1)]
                activations[file_row][input_channels - in_c_index - 1] = in_c
            file_row += 1
# print(len(activations))
# print(activations[7][3])
# print(activations)
# print(activations[7])


def get_nij(onij: int, kij: int):
    onij_x = onij % 4
    onij_y = onij // 4

    kij_x = kij % 3
    kij_y = kij // 3

    # k_offset_x = kij_x - 1  # in relation to onij
    # k_offset_y = kij_y - 1  # in relation to onij

    # nij_x = (onij_x + 1) + k_offset_x
    # nij_y = (onij_y + 1) + k_offset_y
    # simplified:
    nij_x = onij_x + kij_x
    nij_y = onij_y + kij_y

    return 6 * nij_y + nij_x


# print(nij(10, 4))


# nij(onij7, kij0)_ic0, nij(onij6, kij0)_ic0, nij(onij5, kij0)_ic0... nij(onij0, kij0)_ic0
# nij(onij7, kij1)_ic0, nij(onij6, kij1)_ic0, nij(onij5, kij1)_ic0... nij(onij0, kij1)_ic0
# nij(onij7, kij2)_ic0, nij(onij6, kij2)_ic0, nij(onij5, kij2)_ic0... nij(onij0, kij2)_ic0
# ...........................................................................
# nij(onij7, kij8)_ic0, nij(onij6, kij8)_ic0, nij(onij5, kij8)_ic0... nij(onij0, kij8)_ic0
# ...........................................................................
# nij(onij7, kij0)_ic1, nij(onij6, kij0)_ic1, nij(onij5, kij0)_ic1... nij(onij0, kij0)_ic1
# nij(onij7, kij1)_ic1, nij(onij6, kij1)_ic1, nij(onij5, kij1)_ic1... nij(onij0, kij1)_ic1
# nij(onij7, kij2)_ic1, nij(onij6, kij2)_ic1, nij(onij5, kij2)_ic1... nij(onij0, kij2)_ic1
# ...........................................................................
# nij(onij7, kij8)_ic1, nij(onij6, kij8)_ic1, nij(onij5, kij8)_ic1... nij(onij0, kij8)_ic1
kijg = 9
onijg = 8
with open("vals/activation_os.txt", "w") as file:
    file.write(
        "#nij(onij7,kij0)_ic0,nij(onij6,kij0)_ic0,nij(onij5,kij0)_ic0...nij(onij0,kij0)_ic0\n"
    )
    file.write(
        "#nij(onij7,kij1)_ic0,nij(onij6,kij1)_ic0,nij(onij5,kij1)_ic0...nij(onij0, kij1)_ic0\n"
    )
    file.write(
        "#nij(onij7,kij2)_ic0,nij(onij6,kij2)_ic0,nij(onij5,kij2)_ic0...nij(onij0,kij2)_ic0\n"
    )
    file.write(
        "#...........................................................................\n"
    )
    file.write(
        "#nij(onij7,kij8)_ic0,nij(onij6,kij8)_ic0,nij(onij5,kij8)_ic0...nij(onij0,kij8)_ic0 \n"
    )
    file.write("#\n")
    file.write(
        "#nij(onij7,kij0)_ic1,nij(onij6,kij0)_ic1,nij(onij5,kij0)_ic1...nij(onij0,kij0)_ic1\n"
    )
    file.write(
        "#nij(onij7,kij1)_ic1,nij(onij6,kij1)_ic1,nij(onij5,kij1)_ic1...nij(onij0,kij1)_ic1\n"
    )
    file.write(
        "#nij(onij7,kij2)_ic1,nij(onij6,kij2)_ic1,nij(onij5,kij2)_ic1...nij(onij0, kij2)_ic1\n"
    )
    file.write(
        "#...........................................................................\n"
    )
    file.write(
        "#nij(onij7,kij8)_ic1,nij(onij6,kij8)_ic1,nij(onij5,kij8)_ic1...nij(onij0,kij8)_ic1\n"
    )

    for ic in range(input_channels):
        for kij in range(kijg):
            for onij in range(onijg - 1, -1, -1):  # onijg 7 to 0
                nij = get_nij(onij, kij)
                # print(nij, end=" ")
                # print(activations[nij][ic], end=" ")
                file.write(activations[nij][ic])
            # print("\n")
            file.write("\n")
