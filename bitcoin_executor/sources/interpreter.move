module bitcoin_executor::interpreter;

use bitcoin_executor::reader::{Self, Reader};
use bitcoin_executor::stack::{Self, Stack};
use bitcoin_executor::utils;
use bitcoin_executor::ripemd160;
use std::hash::sha2_256;

#[test_only]
use std::unit_test::assert_eq;
//=============== Opcodes =============================================

/// These constants are the values of the official opcodes used on the btc wiki,
/// in bitcoin core and in most if not all other references and software related
/// to handling BTC scripts.
/// https://github.com/btcsuite/btcd/blob/master/txscript/opcode.go
const OP_0: u8 = 0x00; // 0
const OP_FALSE: u8 = 0x00; // 0 - AKA OP_0
const OP_PUSHBYTES_1: u8 = 0x01; // 1
const OP_PUSHBYTES_2: u8 = 0x02; // 2
const OP_PUSHBYTES_3: u8 = 0x03; // 3
const OP_PUSHBYTES_4: u8 = 0x04; // 4
const OP_PUSHBYTES_5: u8 = 0x05; // 5
const OP_PUSHBYTES_6: u8 = 0x06; // 6
const OP_PUSHBYTES_7: u8 = 0x07; // 7
const OP_PUSHBYTES_8: u8 = 0x08; // 8
const OP_PUSHBYTES_9: u8 = 0x09; // 9
const OP_PUSHBYTES_10: u8 = 0x0a; // 10
const OP_PUSHBYTES_11: u8 = 0x0b; // 11
const OP_PUSHBYTES_12: u8 = 0x0c; // 12
const OP_PUSHBYTES_13: u8 = 0x0d; // 13
const OP_PUSHBYTES_14: u8 = 0x0e; // 14
const OP_PUSHBYTES_15: u8 = 0x0f; // 15
const OP_PUSHBYTES_16: u8 = 0x10; // 16
const OP_PUSHBYTES_17: u8 = 0x11; // 17
const OP_PUSHBYTES_18: u8 = 0x12; // 18
const OP_PUSHBYTES_19: u8 = 0x13; // 19
const OP_PUSHBYTES_20: u8 = 0x14; // 20
const OP_PUSHBYTES_21: u8 = 0x15; // 21
const OP_PUSHBYTES_22: u8 = 0x16; // 22
const OP_PUSHBYTES_23: u8 = 0x17; // 23
const OP_PUSHBYTES_24: u8 = 0x18; // 24
const OP_PUSHBYTES_25: u8 = 0x19; // 25
const OP_PUSHBYTES_26: u8 = 0x1a; // 26
const OP_PUSHBYTES_27: u8 = 0x1b; // 27
const OP_PUSHBYTES_28: u8 = 0x1c; // 28
const OP_PUSHBYTES_29: u8 = 0x1d; // 29
const OP_PUSHBYTES_30: u8 = 0x1e; // 30
const OP_PUSHBYTES_31: u8 = 0x1f; // 31
const OP_PUSHBYTES_32: u8 = 0x20; // 32
const OP_PUSHBYTES_33: u8 = 0x21; // 33
const OP_PUSHBYTES_34: u8 = 0x22; // 34
const OP_PUSHBYTES_35: u8 = 0x23; // 35
const OP_PUSHBYTES_36: u8 = 0x24; // 36
const OP_PUSHBYTES_37: u8 = 0x25; // 37
const OP_PUSHBYTES_38: u8 = 0x26; // 38
const OP_PUSHBYTES_39: u8 = 0x27; // 39
const OP_PUSHBYTES_40: u8 = 0x28; // 40
const OP_PUSHBYTES_41: u8 = 0x29; // 41
const OP_PUSHBYTES_42: u8 = 0x2a; // 42
const OP_PUSHBYTES_43: u8 = 0x2b; // 43
const OP_PUSHBYTES_44: u8 = 0x2c; // 44
const OP_PUSHBYTES_45: u8 = 0x2d; // 45
const OP_PUSHBYTES_46: u8 = 0x2e; // 46
const OP_PUSHBYTES_47: u8 = 0x2f; // 47
const OP_PUSHBYTES_48: u8 = 0x30; // 48
const OP_PUSHBYTES_49: u8 = 0x31; // 49
const OP_PUSHBYTES_50: u8 = 0x32; // 50
const OP_PUSHBYTES_51: u8 = 0x33; // 51
const OP_PUSHBYTES_52: u8 = 0x34; // 52
const OP_PUSHBYTES_53: u8 = 0x35; // 53
const OP_PUSHBYTES_54: u8 = 0x36; // 54
const OP_PUSHBYTES_55: u8 = 0x37; // 55
const OP_PUSHBYTES_56: u8 = 0x38; // 56
const OP_PUSHBYTES_57: u8 = 0x39; // 57
const OP_PUSHBYTES_58: u8 = 0x3a; // 58
const OP_PUSHBYTES_59: u8 = 0x3b; // 59
const OP_PUSHBYTES_60: u8 = 0x3c; // 60
const OP_PUSHBYTES_61: u8 = 0x3d; // 61
const OP_PUSHBYTES_62: u8 = 0x3e; // 62
const OP_PUSHBYTES_63: u8 = 0x3f; // 63
const OP_PUSHBYTES_64: u8 = 0x40; // 64
const OP_PUSHBYTES_65: u8 = 0x41; // 65
const OP_PUSHBYTES_66: u8 = 0x42; // 66
const OP_PUSHBYTES_67: u8 = 0x43; // 67
const OP_PUSHBYTES_68: u8 = 0x44; // 68
const OP_PUSHBYTES_69: u8 = 0x45; // 69
const OP_PUSHBYTES_70: u8 = 0x46; // 70
const OP_PUSHBYTES_71: u8 = 0x47; // 71
const OP_PUSHBYTES_72: u8 = 0x48; // 72
const OP_PUSHBYTES_73: u8 = 0x49; // 73
const OP_PUSHBYTES_74: u8 = 0x4a; // 74
const OP_PUSHBYTES_75: u8 = 0x4b; // 75
const OP_PUSHDATA1: u8 = 0x4c; // 76
const OP_PUSHDATA2: u8 = 0x4d; // 77
const OP_PUSHDATA4: u8 = 0x4e; // 78
const OP_1NEGATE: u8 = 0x4f; // 79
const OP_RESERVED: u8 = 0x50; // 80
const OP_1: u8 = 0x51; // 81 - AKA OP_TRUE
const OP_TRUE: u8 = 0x51; // 81
const OP_2: u8 = 0x52; // 82
const OP_3: u8 = 0x53; // 83
const OP_4: u8 = 0x54; // 84
const OP_5: u8 = 0x55; // 85
const OP_6: u8 = 0x56; // 86
const OP_7: u8 = 0x57; // 87
const OP_8: u8 = 0x58; // 88
const OP_9: u8 = 0x59; // 89
const OP_10: u8 = 0x5a; // 90
const OP_11: u8 = 0x5b; // 91
const OP_12: u8 = 0x5c; // 92
const OP_13: u8 = 0x5d; // 93
const OP_14: u8 = 0x5e; // 94
const OP_15: u8 = 0x5f; // 95
const OP_16: u8 = 0x60; // 96
const OP_NOP: u8 = 0x61; // 97
const OP_VER: u8 = 0x62; // 98
const OP_IF: u8 = 0x63; // 99
const OP_NOTIF: u8 = 0x64; // 100
const OP_VERIF: u8 = 0x65; // 101
const OP_VERNOTIF: u8 = 0x66; // 102
const OP_ELSE: u8 = 0x67; // 103
const OP_ENDIF: u8 = 0x68; // 104
const OP_VERIFY: u8 = 0x69; // 105
const OP_RETURN: u8 = 0x6a; // 106
const OP_TOALTSTACK: u8 = 0x6b; // 107
const OP_FROMALTSTACK: u8 = 0x6c; // 108
const OP_2DROP: u8 = 0x6d; // 109
const OP_2DUP: u8 = 0x6e; // 110
const OP_3DUP: u8 = 0x6f; // 111
const OP_2OVER: u8 = 0x70; // 112
const OP_2ROT: u8 = 0x71; // 113
const OP_2SWAP: u8 = 0x72; // 114
const OP_IFDUP: u8 = 0x73; // 115
const OP_DEPTH: u8 = 0x74; // 116
const OP_DROP: u8 = 0x75; // 117
/// Duplicate the top item on the stack.
const OP_DUP: u8 = 0x76; // 118
const OP_NIP: u8 = 0x77; // 119
const OP_OVER: u8 = 0x78; // 120
const OP_PICK: u8 = 0x79; // 121
const OP_ROLL: u8 = 0x7a; // 122
const OP_ROT: u8 = 0x7b; // 123
const OP_SWAP: u8 = 0x7c; // 124
const OP_TUCK: u8 = 0x7d; // 125
const OP_CAT: u8 = 0x7e; // 126
const OP_SUBSTR: u8 = 0x7f; // 127
const OP_LEFT: u8 = 0x80; // 128
const OP_RIGHT: u8 = 0x81; // 129
const OP_SIZE: u8 = 0x82; // 130
const OP_INVERT: u8 = 0x83; // 131
const OP_AND: u8 = 0x84; // 132
const OP_OR: u8 = 0x85; // 133
const OP_XOR: u8 = 0x86; // 134
/// Compare the top two items on the stack and push 1 if they are equal, 0 otherwise.
const OP_EQUAL: u8 = 0x87; // 135
/// Compare the top two items on the stack and halts the script if they are not equal.
const OP_EQUALVERIFY: u8 = 0x88; // 136
const OP_RESERVED1: u8 = 0x89; // 137
const OP_RESERVED2: u8 = 0x8a; // 138
const OP_1ADD: u8 = 0x8b; // 139
const OP_1SUB: u8 = 0x8c; // 140
const OP_2MUL: u8 = 0x8d; // 141
const OP_2DIV: u8 = 0x8e; // 142
const OP_NEGATE: u8 = 0x8f; // 143
const OP_ABS: u8 = 0x90; // 144
const OP_NOT: u8 = 0x91; // 145
const OP_0NOTEQUAL: u8 = 0x92; // 146
const OP_ADD: u8 = 0x93; // 147
const OP_SUB: u8 = 0x94; // 148
const OP_MUL: u8 = 0x95; // 149
const OP_DIV: u8 = 0x96; // 150
const OP_MOD: u8 = 0x97; // 151
const OP_LSHIFT: u8 = 0x98; // 152
const OP_RSHIFT: u8 = 0x99; // 153
const OP_BOOLAND: u8 = 0x9a; // 154
const OP_BOOLOR: u8 = 0x9b; // 155
const OP_NUMEQUAL: u8 = 0x9c; // 156
const OP_NUMEQUALVERIFY: u8 = 0x9d; // 157
const OP_NUMNOTEQUAL: u8 = 0x9e; // 158
const OP_LESSTHAN: u8 = 0x9f; // 159
const OP_GREATERTHAN: u8 = 0xa0; // 160
const OP_LESSTHANOREQUAL: u8 = 0xa1; // 161
const OP_GREATERTHANOREQUAL: u8 = 0xa2; // 162
const OP_MIN: u8 = 0xa3; // 163
const OP_MAX: u8 = 0xa4; // 164
const OP_WITHIN: u8 = 0xa5; // 165
const OP_RIPEMD160: u8 = 0xa6; // 166
const OP_SHA1: u8 = 0xa7; // 167
const OP_SHA256: u8 = 0xa8; // 168
const OP_HASH160: u8 = 0xa9; // 169
const OP_HASH256: u8 = 0xaa; // 170
const OP_CODESEPARATOR: u8 = 0xab; // 171
const OP_CHECKSIG: u8 = 0xac; // 172
const OP_CHECKSIGVERIFY: u8 = 0xad; // 173
const OP_CHECKMULTISIG: u8 = 0xae; // 174
const OP_CHECKMULTISIGVERIFY: u8 = 0xaf; // 175
const OP_NOP1: u8 = 0xb0; // 176
const OP_NOP2: u8 = 0xb1; // 177
const OP_CHECKLOCKTIMEVERIFY: u8 = 0xb1; // 177 - AKA OP_NOP2
const OP_NOP3: u8 = 0xb2; // 178
const OP_CHECKSEQUENCEVERIFY: u8 = 0xb2; // 178 - AKA OP_NOP3
const OP_NOP4: u8 = 0xb3; // 179
const OP_NOP5: u8 = 0xb4; // 180
const OP_NOP6: u8 = 0xb5; // 181
const OP_NOP7: u8 = 0xb6; // 182
const OP_NOP8: u8 = 0xb7; // 183
const OP_NOP9: u8 = 0xb8; // 184
const OP_NOP10: u8 = 0xb9; // 185
const OP_CHECKSIGADD: u8 = 0xba; // 186
const OP_UNKNOWN187: u8 = 0xbb; // 187
const OP_UNKNOWN188: u8 = 0xbc; // 188
const OP_UNKNOWN189: u8 = 0xbd; // 189
const OP_UNKNOWN190: u8 = 0xbe; // 190
const OP_UNKNOWN191: u8 = 0xbf; // 191
const OP_UNKNOWN192: u8 = 0xc0; // 192
const OP_UNKNOWN193: u8 = 0xc1; // 193
const OP_UNKNOWN194: u8 = 0xc2; // 194
const OP_UNKNOWN195: u8 = 0xc3; // 195
const OP_UNKNOWN196: u8 = 0xc4; // 196
const OP_UNKNOWN197: u8 = 0xc5; // 197
const OP_UNKNOWN198: u8 = 0xc6; // 198
const OP_UNKNOWN199: u8 = 0xc7; // 199
const OP_UNKNOWN200: u8 = 0xc8; // 200
const OP_UNKNOWN201: u8 = 0xc9; // 201
const OP_UNKNOWN202: u8 = 0xca; // 202
const OP_UNKNOWN203: u8 = 0xcb; // 203
const OP_UNKNOWN204: u8 = 0xcc; // 204
const OP_UNKNOWN205: u8 = 0xcd; // 205
const OP_UNKNOWN206: u8 = 0xce; // 206
const OP_UNKNOWN207: u8 = 0xcf; // 207
const OP_UNKNOWN208: u8 = 0xd0; // 208
const OP_UNKNOWN209: u8 = 0xd1; // 209
const OP_UNKNOWN210: u8 = 0xd2; // 210
const OP_UNKNOWN211: u8 = 0xd3; // 211
const OP_UNKNOWN212: u8 = 0xd4; // 212
const OP_UNKNOWN213: u8 = 0xd5; // 213
const OP_UNKNOWN214: u8 = 0xd6; // 214
const OP_UNKNOWN215: u8 = 0xd7; // 215
const OP_UNKNOWN216: u8 = 0xd8; // 216
const OP_UNKNOWN217: u8 = 0xd9; // 217
const OP_UNKNOWN218: u8 = 0xda; // 218
const OP_UNKNOWN219: u8 = 0xdb; // 219
const OP_UNKNOWN220: u8 = 0xdc; // 220
const OP_UNKNOWN221: u8 = 0xdd; // 221
const OP_UNKNOWN222: u8 = 0xde; // 222
const OP_UNKNOWN223: u8 = 0xdf; // 223
const OP_UNKNOWN224: u8 = 0xe0; // 224
const OP_UNKNOWN225: u8 = 0xe1; // 225
const OP_UNKNOWN226: u8 = 0xe2; // 226
const OP_UNKNOWN227: u8 = 0xe3; // 227
const OP_UNKNOWN228: u8 = 0xe4; // 228
const OP_UNKNOWN229: u8 = 0xe5; // 229
const OP_UNKNOWN230: u8 = 0xe6; // 230
const OP_UNKNOWN231: u8 = 0xe7; // 231
const OP_UNKNOWN232: u8 = 0xe8; // 232
const OP_UNKNOWN233: u8 = 0xe9; // 233
const OP_UNKNOWN234: u8 = 0xea; // 234
const OP_UNKNOWN235: u8 = 0xeb; // 235
const OP_UNKNOWN236: u8 = 0xec; // 236
const OP_UNKNOWN237: u8 = 0xed; // 237
const OP_UNKNOWN238: u8 = 0xee; // 238
const OP_UNKNOWN239: u8 = 0xef; // 239
const OP_UNKNOWN240: u8 = 0xf0; // 240
const OP_UNKNOWN241: u8 = 0xf1; // 241
const OP_UNKNOWN242: u8 = 0xf2; // 242
const OP_UNKNOWN243: u8 = 0xf3; // 243
const OP_UNKNOWN244: u8 = 0xf4; // 244
const OP_UNKNOWN245: u8 = 0xf5; // 245
const OP_UNKNOWN246: u8 = 0xf6; // 246
const OP_UNKNOWN247: u8 = 0xf7; // 247
const OP_UNKNOWN248: u8 = 0xf8; // 248
const OP_UNKNOWN249: u8 = 0xf9; // 249
const OP_SMALLINTEGER: u8 = 0xfa; // 250 - bitcoin core internal
const OP_PUBKEYS: u8 = 0xfb; // 251 - bitcoin core internal
const OP_UNKNOWN252: u8 = 0xfc; // 252
const OP_PUBKEYHASH: u8 = 0xfd; // 253 - bitcoin core internal
const OP_PUBKEY: u8 = 0xfe; // 254 - bitcoin core internal
const OP_INVALIDOPCODE: u8 = 0xff; // 255 - bitcoin core internal

/// Conditional execution constants.
const CondFalse: u8 = 0;
const CondTrue: u8 = 1;
const CondSkip: u8 = 2;

// ============= Errors ================================
#[error]
const EEqualVerify: vector<u8> = b"SCRIPT_ERR_EQUALVERIFY";
#[error]
const EInvalidStackOperation: vector<u8> = b"Invalid stack operation";

public struct Interpreter has copy, drop {
    stack: Stack,
    reader: Reader,
}

public fun new(stack: Stack): Interpreter {
    Interpreter {
        stack: stack,
        reader: reader::new(vector[]), // empty reader
    }
}

/// Execute btc script
public fun run(script: vector<u8>): bool {
    let st = stack::create();
    let mut ip = new(st);
    let r = reader::new(script);
    ip.eval(r)
}

fun eval(ip: &mut Interpreter, r: Reader): bool {
    ip.reader = r; // init new  reader
    while (!r.end_stream()) {
        let op = ip.reader.next_opcode();

        if (op == OP_0) {
            ip.op_push_empty_vector();
        } else if (op >= OP_PUSHBYTES_1 && op <= OP_PUSHBYTES_75) {
            ip.op_push_n_bytes(op);
        } else if (op >= OP_1 && op <= OP_16) {
            ip.op_push_small_int(op);
        } else if (op == OP_DUP) {
            ip.op_dup();
        } else if (op == OP_DROP) {
            ip.op_drop();
        } else if (op == OP_SWAP) {
            ip.op_swap();
        } else if (op == OP_SIZE) {
            ip.op_size();
        } else if (op == OP_EQUAL) {
            ip.op_equal();
        } else if (op == OP_EQUALVERIFY) {
            ip.op_equal_verify();
        } else if (op == OP_SHA256) {
            ip.op_sha256();
        } else if (op == OP_HASH256) {
            ip.op_hash256();
        } else if (op == OP_HASH160) {
            ip.op_hash160();
        }
    };

    ip.isSuccess()
}

/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isSuccess(ip: &Interpreter): bool {
    if (ip.stack.is_empty()) {
        return false
    };
    let top = ip.stack.top();
    cast_to_bool(&top)
}

fun cast_to_bool(v: &vector<u8>): bool {
    let mut i = 0;
    while (i < v.length()) {
        if (v[i] != 0) {
            // Can be negative zero
            if (i == v.length()-1 && v[i] == 0x80) return false;
            return true;
        };
        i = i + 1;
    };
    false
}

fun op_push_empty_vector(ip: &mut Interpreter) {
    ip.stack.push(vector[]);
}

fun op_push_n_bytes(ip: &mut Interpreter, num_bytes_to_push: u8) {
    let data_to_push = ip.reader.read(num_bytes_to_push as u64);
    ip.stack.push(data_to_push);
}

fun op_push_small_int(ip: &mut Interpreter, opcode: u8) {
    // OP_1 (81) corresponds to 1  (81 - 81 + 1 = 1)
    // OP_16 (96) corresponds to 16 (96 - 81 + 1 = 16)
    let numeric_value: u8 = opcode - OP_1 + 1;
    ip.stack.push_byte(numeric_value);
}

fun op_equal(ip: &mut Interpreter) {
    let first_value = ip.stack.pop();
    let second_value = ip.stack.pop();
    let ans = if (first_value == second_value) {
        vector[1]
    } else {
        vector[0]
    };
    ip.stack.push(ans);
}

fun op_equal_verify(ip: &mut Interpreter) {
    ip.op_equal();
    assert!(ip.stack.pop() == vector[1], EEqualVerify);
}

// OP_DUP eval
fun op_dup(ip: &mut Interpreter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}

fun op_drop(ip: &mut Interpreter) {
    ip.stack.pop();
}

fun op_size(ip: &mut Interpreter) {
    let top_element = ip.stack.top();
    let size = top_element.length();
    ip.stack.push(utils::u64_to_cscriptnum(size))
}

fun op_swap(ip: &mut Interpreter) {
    assert!(ip.stack.size() >=2, EInvalidStackOperation);
    let first_element = ip.stack.pop();
    let second_element = ip.stack.pop();
    ip.stack.push(first_element);
    ip.stack.push(second_element);
}

fun op_sha256(ip: &mut Interpreter) {
    let value = ip.stack.pop();
    ip.stack.push(sha2_256(value))
}

fun op_hash256(ip: &mut Interpreter) {
    let value = ip.stack.pop();
    ip.stack.push(sha2_256(sha2_256(value)))
}

fun op_hash160(ip: &mut Interpreter) {
    let value = ip.stack.pop();
    let sha = sha2_256(value);
    let mut hasher = ripemd160::new();
    hasher.write(sha, sha.length());
    ip.stack.push(hasher.finalize())
}
#[test]
fun test_op_0() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_empty_vector();

    assert!(ip.stack.size() == 1);
    let top_val = ip.stack.top();
    assert!(top_val.length() == 0);
    assert!(!ip.isSuccess());
}

#[test]
fun test_op_push_n_bytes() {
    let stack = stack::create();
    let mut ip = new(stack);
    let script = vector[0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
    let reader = reader::new(script);
    ip.reader = reader;

    let num_bytes: u8 = 3;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x01, 0x02, 0x03]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 1;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 2);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x04]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 2;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 3);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x05, 0x06]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_1_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_1);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x01]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_5_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_5);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x05]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_16_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_16);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x10]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_equal() {
    let stack = stack::create_with_data(vector[vector[10], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
    assert!(ip.stack.top() == vector[1]);

    let stack = stack::create_with_data(vector[vector[20], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
    assert!(ip.stack.top() == vector[0]);
}

#[test]
fun test_op_equal_verify() {
    let stack = stack::create_with_data(vector[vector[10], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal_verify();
}

#[test, expected_failure(abort_code = EEqualVerify)]
fun test_op_equal_verify_fail() {
    let stack = stack::create_with_data(vector[vector[10], vector[12]]);
    let mut ip = new(stack);
    ip.op_equal_verify();
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_equal_fail() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
}

#[test]
fun test_op_dup() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_dup();
    assert_eq!(ip.stack.get_all_values(), vector[vector[10], vector[10]]);
    assert_eq!(ip.stack.size(), 2);
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_dup_fail() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_dup();
}

#[test]
fun test_op_drop() {
    let stack = stack::create_with_data(vector[vector[0x01]]);
    let mut ip = new(stack);
    ip.op_drop();
    assert_eq!(ip.stack.get_all_values(), vector[]);
    assert_eq!(ip.stack.size(), 0);
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_drop_fail() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_drop();
}

#[test]
fun test_op_swap() {
    let stack = stack::create_with_data(vector[vector[0x01], vector[0x02]]);
    let mut ip = new(stack);
    ip.op_swap();
    assert_eq!(ip.stack.size(), 2);
    assert_eq!(ip.stack.get_all_values(), vector[vector[0x02], vector[0x01]]);
}

#[test, expected_failure(abort_code = EInvalidStackOperation)]
fun test_op_swap_fail() {
    let stack = stack::create_with_data(vector[vector[0x01]]);
    let mut ip = new(stack);
    ip.op_swap();
}

#[test]
fun test_op_size() {
    let stack = stack::create_with_data(vector[vector[0x01], vector[0x01, 0x02, 0x03]]); // top element size = 3
    let mut ip = new(stack);
    ip.op_size();
    assert_eq!(ip.stack.size(), 3);
    assert_eq!(
        ip.stack.get_all_values(),
        vector[vector[0x01], vector[0x01, 0x02, 0x03], vector[0x03]],
    );
    assert_eq!(ip.stack.top(), vector[0x03]);
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_size_fail() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_size();
}

#[test]
fun test_op_sha256() {
    let stack = stack::create_with_data(vector[vector[0x01]]);
    let mut ip = new(stack);
    ip.op_sha256();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> =
        x"4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a";
    assert_eq!(ip.stack.top(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}

#[test]
fun test_op_hash256() {
    let stack = stack::create_with_data(vector[vector[0x01]]);
    let mut ip = new(stack);
    ip.op_hash256();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> =
        x"9c12cfdc04c74584d787ac3d23772132c18524bc7ab28dec4219b8fc5b425f70";
    assert_eq!(ip.stack.top(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}

#[test]
fun test_op_hash160() {
    let stack = stack::create_with_data(vector[x"12345678"]);
    let mut ip = new(stack);
    ip.op_hash160();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> =
        x"82c12e3c770a95bd17fd1d983d6b2af2037b7a4b";
    assert_eq!(ip.stack.top(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}
