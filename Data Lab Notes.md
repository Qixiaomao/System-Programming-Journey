
## Overview
This lab involves implementing a set of functions that perform complex logical and arithmetic operations using a highly restricted subset of the C programming language. The challenge lies in working within hardware-level constraints—no loops, no conditionals (for integer problems), and a very limited number of operators.

## Bitwise Logic & Representation

### `bitXor`

**The Insight:** XOR is essentially "one or the other, but not both."

Since you are restricted to `~` and `&`, you have to use De Morgan's Law. You identified that $x \oplus y$ is the intersection of "not both 1s" and "not both 0s."

- `a = ~(x & y)`: Filters out where both bits are 1.
    
- `b = ~((~x) & (~y))`: Filters out where both bits are 0 (effectively an OR).
    
- **Result:** The overlap is your XOR.
    

### `tmin`

**The Insight:** In Two's Complement, the most significant bit (MSB) has a negative weight. Shifting `1` to the 31st position creates a number where the value is $-2^{31}$ and all positive weights are zero.


## Testing Constraints

### `isTmax`

**The Insight:** $T_{max}$ (0x7FFFFFFF) is special because adding 1 turns it into its exact opposite, $T_{min}$ (0x80000000).

- If you add 1 to $T_{max}$ and then flip all the bits (`~`), you should get back to $T_{max}$.
    
- **The Trap:** `0xFFFFFFFF` (-1) also behaves like this when you add 1 (it becomes 0). You used `!!i` as a logical gate to disqualify -1.
    

### `allOddBits`

**The Insight:** This is a **Masking** problem. You cannot write a 32-bit constant directly, so you build it. By shifting and adding `0xAA`, you "paint" the pattern across the whole word. The final `!(... ^ mask)` check is a classic way to verify equality in bitwise-land.


## Arithmetic & Comparison logic

### `isAsciiDigit`

**The Insight:** You treated this as a boundary problem. To check $A \le x \le B$, you check if $x - A \ge 0$ and $B - x \ge 0$.

Since you can't use subtraction, you used `~0x30 + 1` (the two's complement of 0x30). The sign bit (shifted right by 31) tells you everything you need to know about the result's positivity.

### `isLessOrEqual`

**The Insight:** This is the most dangerous problem because of **Overflow**.

If you simply do $y - x$, and one is positive while the other is negative, the result might overflow and give a fake sign bit.

- **Same Signs:** Subtraction is safe.
    
- **Different Signs:** Subtraction is dangerous. You used `dangerCheck` to handle the case where $x$ is negative and $y$ is positive—in that case, $x \le y$ is _always_ true, regardless of the math.


## Advanced Bit Control

### `logicalNeg`

**The Insight:** This is a "Property of Zero" trick. For every number except zero, either $x$ or $-x$ (two's complement) will have the sign bit set to 1. Only for zero is the sign bit 0 for both. By OR-ing $x$ and $-x$, you catch any "1" that exists.

### `howManyBits`

**The Insight:** This is essentially a **Binary Search for the MSB**.

For negative numbers, you used `x ^ sign` to flip them because finding the number of bits for a negative number is equivalent to finding the bits for its bitwise inverse (e.g., -5 is `...111011`, which needs the same bits as 4 `...000100`).

- You check: "Is there a 1 in the high 16 bits? If yes, shift and count 16."
    
- Then: "Is there a 1 in the high 8 bits of what's left?"
    
- This logarithmic approach is much more efficient than checking bits one by one.


## Floating Point (The IEEE 754 Rules)

### `floatScale2`

**The Insight:** You categorized the floating-point space:

1. **Denormalized (exp=0):** Just shift the fraction. The transition to normalized happens naturally.
    
2. **Normalized:** Just increment the exponent.
    
3. **Special (exp=255):** It’s already Infinity or NaN, so don't touch it.
    

### `floatFloat2Int`

**The Insight:** You are essentially reversing the scientific notation $M \times 2^E$.

- If $E < 0$, the number is a fraction (e.g., 0.5), which casts to `0` in integer logic.
    
- If $E > 31$, it won't fit in a 32-bit signed integer (overflow).
    
- Otherwise, you take the "implied 1" (`1 << 23`), add the fraction bits, and shift them left or right depending on the exponent's value.


## Summary
This lab reinforced my interest in AI infrastructure and System Architecture. It taught me:
- Branchless Programming : How to write code that avoids "if-else" branches, which is vital for maximizing CPU pipeline efficiency and preventing side-Channel attacks.
- Architecture Constraints: How to design algorithms that respect the physical liminations of the underlying hardware.
- Edge Case Resilience: The importance of handling mathematical singularities (NaN, Infinity, $T_{min}$) Which are often the root causes of system failures.
