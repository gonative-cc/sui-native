// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::stack;

// ============= Constants ===========
const MaximumStackSize: u64 = 1000;
const MaximumElementSize: u64 = 520; // in bytes
// ============= Errors =============
#[error]
const EReachMaximumSize: vector<u8> = b"Reach maximum element in stack";
#[error]
const EElementSizeInvalid: vector<u8> = b"Element size is greater than 520";
#[error]
const EPopStackEmpty: vector<u8> = b"Pop stack empty";

public struct Stack has copy, drop {
    internal: vector<vector<u8>>,
}

/// creates stack
public fun create(): Stack {
    Stack {
        internal: vector[],
    }
}

public fun create_with_data(data: vector<vector<u8>>): Stack {
    Stack {
        internal: data,
    }
}

/// returns size of the stack
public fun size(s: &Stack): u64 {
    // u64 for type compatible
    s.internal.length()
}

/// checks if the stack is empty
public fun is_empty(s: &Stack): bool {
    s.internal.is_empty()
}

/// pushes new element to the stack
public fun push(s: &mut Stack, element: vector<u8>) {
    assert!(s.size() < MaximumStackSize, EReachMaximumSize);
    assert!(element.length() <= MaximumElementSize, EElementSizeInvalid);
    s.internal.push_back(element);
}

/// pushes one byte to the stack
public fun push_byte(s: &mut Stack, byte: u8) {
    assert!(s.size() < MaximumStackSize, EReachMaximumSize);
    s.internal.push_back(vector[byte]);
}

/// pops top element from the stack
public fun pop(s: &mut Stack): vector<u8> {
    assert!(!s.is_empty(), EPopStackEmpty);
    s.internal.pop_back()
}

/// returns top element from the stack
public fun top(s: &Stack): vector<u8> {
    assert!(!s.is_empty(), EPopStackEmpty);
    s.internal[s.internal.length() - 1]
}

#[test_only]
public fun get_all_values(s: &Stack): vector<vector<u8>> {
    s.internal
}
