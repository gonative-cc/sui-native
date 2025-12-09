// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::opcode;

// === PUSH BYTES OPCODES ===

/// Push the next 1 byte as an array onto the stack
public macro fun OP_PUSHBYTES_1(): u8 {
    0x01
}

/// Push the next 2 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_2(): u8 {
    0x02
}

/// Push the next 3 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_3(): u8 {
    0x03
}

/// Push the next 4 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_4(): u8 {
    0x04
}

/// Push the next 5 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_5(): u8 {
    0x05
}

/// Push the next 6 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_6(): u8 {
    0x06
}

/// Push the next 7 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_7(): u8 {
    0x07
}

/// Push the next 8 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_8(): u8 {
    0x08
}

/// Push the next 9 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_9(): u8 {
    0x09
}

/// Push the next 10 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_10(): u8 {
    0x0a
}

/// Push the next 11 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_11(): u8 {
    0x0b
}

/// Push the next 12 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_12(): u8 {
    0x0c
}

/// Push the next 13 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_13(): u8 {
    0x0d
}

/// Push the next 14 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_14(): u8 {
    0x0e
}

/// Push the next 15 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_15(): u8 {
    0x0f
}

/// Push the next 16 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_16(): u8 {
    0x10
}

/// Push the next 17 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_17(): u8 {
    0x11
}

/// Push the next 18 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_18(): u8 {
    0x12
}

/// Push the next 19 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_19(): u8 {
    0x13
}

/// Push the next 20 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_20(): u8 {
    0x14
}

/// Push the next 21 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_21(): u8 {
    0x15
}

/// Push the next 22 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_22(): u8 {
    0x16
}

/// Push the next 23 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_23(): u8 {
    0x17
}

/// Push the next 24 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_24(): u8 {
    0x18
}

/// Push the next 25 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_25(): u8 {
    0x19
}

/// Push the next 26 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_26(): u8 {
    0x1a
}

/// Push the next 27 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_27(): u8 {
    0x1b
}

/// Push the next 28 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_28(): u8 {
    0x1c
}

/// Push the next 29 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_29(): u8 {
    0x1d
}

/// Push the next 30 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_30(): u8 {
    0x1e
}

/// Push the next 31 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_31(): u8 {
    0x1f
}

/// Push the next 32 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_32(): u8 {
    0x20
}

/// Push the next 33 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_33(): u8 {
    0x21
}

/// Push the next 34 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_34(): u8 {
    0x22
}

/// Push the next 35 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_35(): u8 {
    0x23
}

/// Push the next 36 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_36(): u8 {
    0x24
}

/// Push the next 37 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_37(): u8 {
    0x25
}

/// Push the next 38 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_38(): u8 {
    0x26
}

/// Push the next 39 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_39(): u8 {
    0x27
}

/// Push the next 40 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_40(): u8 {
    0x28
}

/// Push the next 41 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_41(): u8 {
    0x29
}

/// Push the next 42 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_42(): u8 {
    0x2a
}

/// Push the next 43 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_43(): u8 {
    0x2b
}

/// Push the next 44 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_44(): u8 {
    0x2c
}

/// Push the next 45 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_45(): u8 {
    0x2d
}

/// Push the next 46 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_46(): u8 {
    0x2e
}

/// Push the next 47 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_47(): u8 {
    0x2f
}

/// Push the next 48 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_48(): u8 {
    0x30
}

/// Push the next 49 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_49(): u8 {
    0x31
}

/// Push the next 50 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_50(): u8 {
    0x32
}

/// Push the next 51 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_51(): u8 {
    0x33
}

/// Push the next 52 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_52(): u8 {
    0x34
}

/// Push the next 53 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_53(): u8 {
    0x35
}

/// Push the next 54 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_54(): u8 {
    0x36
}

/// Push the next 55 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_55(): u8 {
    0x37
}

/// Push the next 56 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_56(): u8 {
    0x38
}

/// Push the next 57 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_57(): u8 {
    0x39
}

/// Push the next 58 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_58(): u8 {
    0x3a
}

/// Push the next 59 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_59(): u8 {
    0x3b
}

/// Push the next 60 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_60(): u8 {
    0x3c
}

/// Push the next 61 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_61(): u8 {
    0x3d
}

/// Push the next 62 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_62(): u8 {
    0x3e
}

/// Push the next 63 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_63(): u8 {
    0x3f
}

/// Push the next 64 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_64(): u8 {
    0x40
}

/// Push the next 65 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_65(): u8 {
    0x41
}

/// Push the next 66 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_66(): u8 {
    0x42
}

/// Push the next 67 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_67(): u8 {
    0x43
}

/// Push the next 68 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_68(): u8 {
    0x44
}

/// Push the next 69 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_69(): u8 {
    0x45
}

/// Push the next 70 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_70(): u8 {
    0x46
}

/// Push the next 71 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_71(): u8 {
    0x47
}

/// Push the next 72 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_72(): u8 {
    0x48
}

/// Push the next 73 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_73(): u8 {
    0x49
}

/// Push the next 74 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_74(): u8 {
    0x4a
}

/// Push the next 75 bytes as an array onto the stack
public macro fun OP_PUSHBYTES_75(): u8 {
    0x4b
}

// === DATA MANIPULATION OPCODES ===

/// Read the next byte as N. Push the next N bytes as an array onto the stack
public macro fun OP_PUSHDATA1(): u8 {
    0x4c
}

/// Read the next 2 bytes as N. Push the next N bytes as an array onto the stack
public macro fun OP_PUSHDATA2(): u8 {
    0x4d
}

/// Read the next 4 bytes as N. Push the next N bytes as an array onto the stack
public macro fun OP_PUSHDATA4(): u8 {
    0x4e
}

/// Push the number -1 onto the stack
public macro fun OP_1NEGATE(): u8 {
    0x4f
}

/// Word for the Bitcoin protocol version
public macro fun OP_RESERVED(): u8 {
    0x50
}

// === CONSTANTS ===

/// An empty array of bytes is pushed onto the stack (not a no-op: an item is added to the stack)
public macro fun OP_0(): u8 {
    0x00
}

/// The number 1 is pushed onto the stack (same as OP_TRUE)
public macro fun OP_1(): u8 {
    0x51
}

/// The number 2 is pushed onto the stack
public macro fun OP_2(): u8 {
    0x52
}

/// The number 3 is pushed onto the stack
public macro fun OP_3(): u8 {
    0x53
}

/// The number 4 is pushed onto the stack
public macro fun OP_4(): u8 {
    0x54
}

/// The number 5 is pushed onto the stack
public macro fun OP_5(): u8 {
    0x55
}

/// The number 6 is pushed onto the stack
public macro fun OP_6(): u8 {
    0x56
}

/// The number 7 is pushed onto the stack
public macro fun OP_7(): u8 {
    0x57
}

/// The number 8 is pushed onto the stack
public macro fun OP_8(): u8 {
    0x58
}

/// The number 9 is pushed onto the stack
public macro fun OP_9(): u8 {
    0x59
}

/// The number 10 is pushed onto the stack
public macro fun OP_10(): u8 {
    0x5a
}

/// The number 11 is pushed onto the stack
public macro fun OP_11(): u8 {
    0x5b
}

/// The number 12 is pushed onto the stack
public macro fun OP_12(): u8 {
    0x5c
}

/// The number 13 is pushed onto the stack
public macro fun OP_13(): u8 {
    0x5d
}

/// The number 14 is pushed onto the stack
public macro fun OP_14(): u8 {
    0x5e
}

/// The number 15 is pushed onto the stack
public macro fun OP_15(): u8 {
    0x5f
}

/// The number 16 is pushed onto the stack
public macro fun OP_16(): u8 {
    0x60
}

// === FLOW CONTROL OPCODES ===

/// Does nothing (NOP)
public macro fun OP_NOP(): u8 {
    0x61
}

/// Word for the Bitcoin protocol version
public macro fun OP_VER(): u8 {
    0x62
}

/// If the top stack value is not 0, the statements are executed. The top stack value is removed.
public macro fun OP_IF(): u8 {
    0x63
}

/// If the top stack value is 0, the statements are executed. The top stack value is removed.
public macro fun OP_NOTIF(): u8 {
    0x64
}

/// Fail the script immediately unless already in an OP_IF/OP_NOTIF statement
public macro fun OP_VERIF(): u8 {
    0x65
}

/// Fail the script immediately unless already in an OP_IF/OP_NOTIF statement
public macro fun OP_VERNOTIF(): u8 {
    0x66
}

/// If the preceding OP_IF or OP_NOTIF was not executed then these statements are executed.
public macro fun OP_ELSE(): u8 {
    0x67
}

/// Ends an if/else block. All blocks must end, or the script is invalid.
public macro fun OP_ENDIF(): u8 {
    0x68
}

/// If the top stack value is not 0, it is removed and script failure occurs.
public macro fun OP_VERIFY(): u8 {
    0x69
}

/// Marks transaction as invalid
public macro fun OP_RETURN(): u8 {
    0x6a
}

// === STACK MANIPULATION OPCODES ===

/// Puts the input onto the top of the alt stack. Removes it from the main stack.
public macro fun OP_TOALTSTACK(): u8 {
    0x6b
}

/// Puts the input onto the top of the main stack. Removes it from the alt stack.
public macro fun OP_FROMALTSTACK(): u8 {
    0x6c
}

/// Removes the top two stack items
public macro fun OP_2DROP(): u8 {
    0x6d
}

/// Duplicates the top two stack items as AB -> ABAB
public macro fun OP_2DUP(): u8 {
    0x6e
}

/// Duplicates the top three stack items as ABC -> ABCABC
public macro fun OP_3DUP(): u8 {
    0x6f
}

/// Copies the pair of items two spaces back in the stack to the front, as x1 x2 x3 x4 x5 x6 -> x3 x4 x1 x2 x3 x4 x5 x6
public macro fun OP_2OVER(): u8 {
    0x70
}

/// Rotates the top six stack items, as x1 x2 x3 x4 x5 x6 -> x3 x4 x5 x6 x1 x2
public macro fun OP_2ROT(): u8 {
    0x71
}

/// Swaps the top three stack items, as x1 x2 x3 -> x2 x3 x1
public macro fun OP_2SWAP(): u8 {
    0x72
}

/// If the top stack value is not 0, duplicate it
public macro fun OP_IFDUP(): u8 {
    0x73
}

/// Puts the number of stack items onto the stack
public macro fun OP_DEPTH(): u8 {
    0x74
}

/// Removes the top stack item
public macro fun OP_DROP(): u8 {
    0x75
}

/// Duplicates the top stack item
public macro fun OP_DUP(): u8 {
    0x76
}

/// Removes the second-to-top stack item
public macro fun OP_NIP(): u8 {
    0x77
}

/// Copies the second-to-top stack item to the top
public macro fun OP_OVER(): u8 {
    0x78
}

/// The item n back in the stack is copied to the top
public macro fun OP_PICK(): u8 {
    0x79
}

/// The item n back in the stack is moved to the top
public macro fun OP_ROLL(): u8 {
    0x7a
}

/// Rotates the top three stack items, as (x1 x2 x3) -> (x2 x3 x1)
public macro fun OP_ROT(): u8 {
    0x7b
}

/// Swaps the top two stack items
public macro fun OP_SWAP(): u8 {
    0x7c
}

/// The item at the top of the stack is copied and inserted before the second-to-top item
public macro fun OP_TUCK(): u8 {
    0x7d
}

/// Concatenates two strings
public macro fun OP_CAT(): u8 {
    0x7e
}

/// Returns a section of a string
public macro fun OP_SUBSTR(): u8 {
    0x7f
}

/// Keeps only the leftmost bytes from a string
public macro fun OP_LEFT(): u8 {
    0x80
}

/// Keeps only the rightmost bytes from a string
public macro fun OP_RIGHT(): u8 {
    0x81
}

/// Returns the length of the string at the top of the stack
public macro fun OP_SIZE(): u8 {
    0x82
}

// === BITWISE LOGIC OPCODES ===

/// Flips the bits
public macro fun OP_INVERT(): u8 {
    0x83
}

/// Boolean and between each bit in the inputs
public macro fun OP_AND(): u8 {
    0x84
}

/// Boolean or between each bit in the inputs
public macro fun OP_OR(): u8 {
    0x85
}

/// Boolean exclusive or between each bit in the inputs
public macro fun OP_XOR(): u8 {
    0x86
}

// === ARITHMETIC OPCODES ===

/// Returns 1 if the inputs are exactly equal, 0 otherwise
public macro fun OP_EQUAL(): u8 {
    0x87
}

/// Same as OP_EQUAL, but runs OP_VERIFY afterward
public macro fun OP_EQUALVERIFY(): u8 {
    0x88
}

/// Word for the Bitcoin protocol version
public macro fun OP_RESERVED1(): u8 {
    0x89
}

/// Word for the Bitcoin protocol version
public macro fun OP_RESERVED2(): u8 {
    0x8a
}

/// 1 is added to the input
public macro fun OP_1ADD(): u8 {
    0x8b
}

/// 1 is subtracted from the input
public macro fun OP_1SUB(): u8 {
    0x8c
}

/// The input is multiplied by 2
public macro fun OP_2MUL(): u8 {
    0x8d
}

/// The input is divided by 2
public macro fun OP_2DIV(): u8 {
    0x8e
}

/// The sign of the input is flipped
public macro fun OP_NEGATE(): u8 {
    0x8f
}

/// The input is made positive
public macro fun OP_ABS(): u8 {
    0x90
}

/// If the input is 0 or 1, it is flipped. Otherwise the output is 0
public macro fun OP_NOT(): u8 {
    0x91
}

/// Returns 0 if the input is 0, 1 otherwise
public macro fun OP_0NOTEQUAL(): u8 {
    0x92
}

/// a is added to b
public macro fun OP_ADD(): u8 {
    0x93
}

/// b is subtracted from a
public macro fun OP_SUB(): u8 {
    0x94
}

/// a is multiplied by b
public macro fun OP_MUL(): u8 {
    0x95
}

/// a is divided by b
public macro fun OP_DIV(): u8 {
    0x96
}

/// Returns the remainder after dividing a by b
public macro fun OP_MOD(): u8 {
    0x97
}

/// Shifts a left b bits, preserving sign
public macro fun OP_LSHIFT(): u8 {
    0x98
}

/// Shifts a right b bits, preserving sign
public macro fun OP_RSHIFT(): u8 {
    0x99
}

/// If both a and b are not 0, output 1. Otherwise output 0
public macro fun OP_BOOLAND(): u8 {
    0x9a
}

/// If a or b is not 0, output 1. Otherwise output 0
public macro fun OP_BOOLOR(): u8 {
    0x9b
}

/// Returns 1 if the inputs are exactly equal, 0 otherwise
public macro fun OP_NUMEQUAL(): u8 {
    0x9c
}

/// Same as OP_NUMEQUAL, but runs OP_VERIFY afterward
public macro fun OP_NUMEQUALVERIFY(): u8 {
    0x9d
}

/// Returns 1 if the inputs are not equal, 0 otherwise
public macro fun OP_NUMNOTEQUAL(): u8 {
    0x9e
}

/// Returns 1 if a is less than b, 0 otherwise
public macro fun OP_LESSTHAN(): u8 {
    0x9f
}

/// Returns 1 if a is greater than b, 0 otherwise
public macro fun OP_GREATERTHAN(): u8 {
    0xa0
}

/// Returns 1 if a is less than or equal to b, 0 otherwise
public macro fun OP_LESSTHANOREQUAL(): u8 {
    0xa1
}

/// Returns 1 if a is greater than or equal to b, 0 otherwise
public macro fun OP_GREATERTHANOREQUAL(): u8 {
    0xa2
}

/// Returns the smaller of a and b
public macro fun OP_MIN(): u8 {
    0xa3
}

/// Returns the larger of a and b
public macro fun OP_MAX(): u8 {
    0xa4
}

/// Returns 1 if x is within the specified range (left-inclusive), 0 otherwise
public macro fun OP_WITHIN(): u8 {
    0xa5
}

// === CRYPTO OPCODES ===

/// The input is hashed using RIPEMD-160
public macro fun OP_RIPEMD160(): u8 {
    0xa6
}

/// The input is hashed using SHA-1
public macro fun OP_SHA1(): u8 {
    0xa7
}

/// The input is hashed using SHA-256
public macro fun OP_SHA256(): u8 {
    0xa8
}

/// The input is hashed using SHA-256 and then RIPEMD-160
public macro fun OP_HASH160(): u8 {
    0xa9
}

/// The input is hashed two times with SHA-256
public macro fun OP_HASH256(): u8 {
    0xaa
}

/// Marks where to begin hashing for OP_CHECKSIG
public macro fun OP_CODESEPARATOR(): u8 {
    0xab
}

/// The entire transaction's outputs, inputs, and script (from the most recently-executed CODESEPARATOR to the end) are hashed. The signature used by OP_CHECKSIG must be a valid signature for this hash and public key. If it is, 1 is returned, 0 otherwise.
public macro fun OP_CHECKSIG(): u8 {
    0xac
}

/// Same as OP_CHECKSIG, but OP_VERIFY is executed afterward
public macro fun OP_CHECKSIGVERIFY(): u8 {
    0xad
}

/// For each signature and public key pair, an OP_CHECKSIG is executed. If more signatures are valid than are required, 1 is returned, 0 otherwise
public macro fun OP_CHECKMULTISIG(): u8 {
    0xae
}

/// Same as OP_CHECKMULTISIG, but OP_VERIFY is executed afterward
public macro fun OP_CHECKMULTISIGVERIFY(): u8 {
    0xaf
}

// === LOCKTIME OPCODES ===

/// Does nothing (NOP)
public macro fun OP_NOP1(): u8 {
    0xb0
}

/// Does nothing (NOP)
public macro fun OP_NOP2(): u8 {
    0xb1
}

/// Does nothing (NOP)
public macro fun OP_NOP3(): u8 {
    0xb2
}

/// Does nothing (NOP)
public macro fun OP_NOP4(): u8 {
    0xb3
}

/// Does nothing (NOP)
public macro fun OP_NOP5(): u8 {
    0xb4
}

/// Does nothing (NOP)
public macro fun OP_NOP6(): u8 {
    0xb5
}

/// Does nothing (NOP)
public macro fun OP_NOP7(): u8 {
    0xb6
}

/// Does nothing (NOP)
public macro fun OP_NOP8(): u8 {
    0xb7
}

/// Does nothing (NOP)
public macro fun OP_NOP9(): u8 {
    0xb8
}

/// Does nothing (NOP)
public macro fun OP_NOP10(): u8 {
    0xb9
}

/// Check if transaction sequence is as required
public macro fun OP_CHECKSEQUENCEVERIFY(): u8 {
    0xb2
}

/// Check if transaction locktime is as required
public macro fun OP_CHECKLOCKTIMEVERIFY(): u8 {
    0xb1
}

/// Adds the signature to the public key
public macro fun OP_CHECKSIGADD(): u8 {
    0xba
}

// === INTERNAL/UNKNOWN OPCODES ===

/// Unknown opcode (Bitcoin Core internal)
public macro fun OP_UNKNOWN187(): u8 {
    0xbb
}

/// Unknown opcode
public macro fun OP_UNKNOWN188(): u8 {
    0xbc
}

/// Unknown opcode
public macro fun OP_UNKNOWN189(): u8 {
    0xbd
}

/// Unknown opcode
public macro fun OP_UNKNOWN190(): u8 {
    0xbe
}

/// Unknown opcode
public macro fun OP_UNKNOWN191(): u8 {
    0xbf
}

/// Unknown opcode
public macro fun OP_UNKNOWN192(): u8 {
    0xc0
}

/// Unknown opcode
public macro fun OP_UNKNOWN193(): u8 {
    0xc1
}

/// Unknown opcode
public macro fun OP_UNKNOWN194(): u8 {
    0xc2
}

/// Unknown opcode
public macro fun OP_UNKNOWN195(): u8 {
    0xc3
}

/// Unknown opcode
public macro fun OP_UNKNOWN196(): u8 {
    0xc4
}

/// Unknown opcode
public macro fun OP_UNKNOWN197(): u8 {
    0xc5
}

/// Unknown opcode
public macro fun OP_UNKNOWN198(): u8 {
    0xc6
}

/// Unknown opcode
public macro fun OP_UNKNOWN199(): u8 {
    0xc7
}

/// Unknown opcode
public macro fun OP_UNKNOWN200(): u8 {
    0xc8
}

/// Unknown opcode
public macro fun OP_UNKNOWN201(): u8 {
    0xc9
}

/// Unknown opcode
public macro fun OP_UNKNOWN202(): u8 {
    0xca
}

/// Unknown opcode
public macro fun OP_UNKNOWN203(): u8 {
    0xcb
}

/// Unknown opcode
public macro fun OP_UNKNOWN204(): u8 {
    0xcc
}

/// Unknown opcode
public macro fun OP_UNKNOWN205(): u8 {
    0xcd
}

/// Unknown opcode
public macro fun OP_UNKNOWN206(): u8 {
    0xce
}

/// Unknown opcode
public macro fun OP_UNKNOWN207(): u8 {
    0xcf
}

/// Unknown opcode
public macro fun OP_UNKNOWN208(): u8 {
    0xd0
}

/// Unknown opcode
public macro fun OP_UNKNOWN209(): u8 {
    0xd1
}

/// Unknown opcode
public macro fun OP_UNKNOWN210(): u8 {
    0xd2
}

/// Unknown opcode
public macro fun OP_UNKNOWN211(): u8 {
    0xd3
}

/// Unknown opcode
public macro fun OP_UNKNOWN212(): u8 {
    0xd4
}

/// Unknown opcode
public macro fun OP_UNKNOWN213(): u8 {
    0xd5
}

/// Unknown opcode
public macro fun OP_UNKNOWN214(): u8 {
    0xd6
}

/// Unknown opcode
public macro fun OP_UNKNOWN215(): u8 {
    0xd7
}

/// Unknown opcode
public macro fun OP_UNKNOWN216(): u8 {
    0xd8
}

/// Unknown opcode
public macro fun OP_UNKNOWN217(): u8 {
    0xd9
}

/// Unknown opcode
public macro fun OP_UNKNOWN218(): u8 {
    0xda
}

/// Unknown opcode
public macro fun OP_UNKNOWN219(): u8 {
    0xdb
}

/// Unknown opcode
public macro fun OP_UNKNOWN220(): u8 {
    0xdc
}

/// Unknown opcode
public macro fun OP_UNKNOWN221(): u8 {
    0xdd
}

/// Unknown opcode
public macro fun OP_UNKNOWN222(): u8 {
    0xde
}

/// Unknown opcode
public macro fun OP_UNKNOWN223(): u8 {
    0xdf
}

/// Unknown opcode
public macro fun OP_UNKNOWN224(): u8 {
    0xe0
}

/// Unknown opcode
public macro fun OP_UNKNOWN225(): u8 {
    0xe1
}

/// Unknown opcode
public macro fun OP_UNKNOWN226(): u8 {
    0xe2
}

/// Unknown opcode
public macro fun OP_UNKNOWN227(): u8 {
    0xe3
}

/// Unknown opcode
public macro fun OP_UNKNOWN228(): u8 {
    0xe4
}

/// Unknown opcode
public macro fun OP_UNKNOWN229(): u8 {
    0xe5
}

/// Unknown opcode
public macro fun OP_UNKNOWN230(): u8 {
    0xe6
}

/// Unknown opcode
public macro fun OP_UNKNOWN231(): u8 {
    0xe7
}

/// Unknown opcode
public macro fun OP_UNKNOWN232(): u8 {
    0xe8
}

/// Unknown opcode
public macro fun OP_UNKNOWN233(): u8 {
    0xe9
}

/// Unknown opcode
public macro fun OP_UNKNOWN234(): u8 {
    0xea
}

/// Unknown opcode
public macro fun OP_UNKNOWN235(): u8 {
    0xeb
}

/// Unknown opcode
public macro fun OP_UNKNOWN236(): u8 {
    0xec
}

/// Unknown opcode
public macro fun OP_UNKNOWN237(): u8 {
    0xed
}

/// Unknown opcode
public macro fun OP_UNKNOWN238(): u8 {
    0xee
}

/// Unknown opcode
public macro fun OP_UNKNOWN239(): u8 {
    0xef
}

/// Unknown opcode
public macro fun OP_UNKNOWN240(): u8 {
    0xf0
}

/// Unknown opcode
public macro fun OP_UNKNOWN241(): u8 {
    0xf1
}

/// Unknown opcode
public macro fun OP_UNKNOWN242(): u8 {
    0xf2
}

/// Unknown opcode
public macro fun OP_UNKNOWN243(): u8 {
    0xf3
}

/// Unknown opcode
public macro fun OP_UNKNOWN244(): u8 {
    0xf4
}

/// Unknown opcode
public macro fun OP_UNKNOWN245(): u8 {
    0xf5
}

/// Unknown opcode
public macro fun OP_UNKNOWN246(): u8 {
    0xf6
}

/// Unknown opcode
public macro fun OP_UNKNOWN247(): u8 {
    0xf7
}

/// Unknown opcode
public macro fun OP_UNKNOWN248(): u8 {
    0xf8
}

/// Unknown opcode
public macro fun OP_UNKNOWN249(): u8 {
    0xf9
}

/// Bitcoin Core internal
public macro fun OP_SMALLINTEGER(): u8 {
    0xfa
}

/// Bitcoin Core internal
public macro fun OP_PUBKEYS(): u8 {
    0xfb
}

/// Unknown opcode
public macro fun OP_UNKNOWN252(): u8 {
    0xfc
}

/// Bitcoin Core internal
public macro fun OP_PUBKEYHASH(): u8 {
    0xfd
}

/// Bitcoin Core internal
public macro fun OP_PUBKEY(): u8 {
    0xfe
}

/// Invalid opcode
public macro fun OP_INVALIDOPCODE(): u8 {
    0xff
}
