module btc_execution::opcode;


/// isOpSuccess checks if opcode is valid
public fun isOpValid(opcode: u8): bool {
    // https://github.com/bitcoin/bitcoin/blob/master/src/script/script.cpp#L358
    opcode == 80 || opcode == 98 || (opcode >= 126 && opcode <= 129) ||
        (opcode >= 131 && opcode <= 134) || (opcode >= 137 && opcode <= 138) ||
        (opcode >= 141 && opcode <= 142) || (opcode >= 149 && opcode <= 153) ||
        (opcode >= 187 && opcode <= 254)
}
