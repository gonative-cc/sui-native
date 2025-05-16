module btc_execution::stack;


// ============= Constants ===========
const MaximumStackSize: u64 = 1000;
const MaximumElementSize: u64 = 520;
// ============= Errors =============
#[error]
const EReachMaximumSize: vector<u8> = b"Reach maximum element in stack";
#[error]
const EElementSizeInvalid: vector<u8> = b"Element size is greater htna 520";
#[error]
const EPopStackEmpty: vector<u8> = b"Pop stack empty";


public struct Stack has copy, drop {
    internal: vector<vector<u8>>
}

/// create stack
public fun create() : Stack {
    Stack {
        internal: vector[]
    }
}

/// size of stack
public fun size(s: &Stack): u64 {
    // u64 for type compatible
    s.internal.length()
}

/// check stack empty
public fun is_empty(s: &Stack): bool {
    s.internal.is_empty()
}

/// push new element to stack
public fun push(s: &mut Stack, element: vector<u8>) {
    assert!(s.size() <= MaximumStackSize, EReachMaximumSize);
    assert!(element.length() <= MaximumElementSize, EElementSizeInvalid);
    s.internal.push_back(element);
}

/// pop top element from stack
public fun pop(s: &mut Stack): vector<u8> {
    assert!(s.is_empty(), EPopStackEmpty);
    s.internal.pop_back()
}
