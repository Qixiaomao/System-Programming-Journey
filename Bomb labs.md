#asm #C 

`Welcome to CMU 15-213!`

This lab is based on Chapter 3 and is designed to help reinforce your knowledge of assembly language. The core content of Chapter 3 focuses on the ALU (Arithmetic Logic Unit), exploring how data is represented in assembly and how it is transferred between registers and memory. It also emphasizes understanding how the stack changes throughout the execution of the Bomb Lab code, which consists of six phases. The following are the preliminary conditions for this lab.
## Preliminary Conditions
Need to download the official lab package in the WSL2 environment and extract it to the corresponding folder.

```c:

// Self-Study  for download 
wget http://csapp.cs.cmu.edu/3e/bomb.tar

// Extract the folder
tar -xvf bomb.tar

// Verify files
/*
bomb // executable program
bomb.c  // source code (not visible)
README // documentation

*/

// Run this command jin the terminal to generate the assembly file
objdump -d bomb > bomb.s

// To enable execution ./bomb in WSL ，grant necessary permissions 
chmod +x bomb

```

Using GDB to view disassembly is quite different from typical debugging workflows.  
Here’s a handy quick-reference card for GDB commands.


| Target                            | GDB Command      | Reasons                                                               |
| --------------------------------- | ---------------- | --------------------------------------------------------------------- |
| Set breakpoint at `explode_bomb`  | `b explode_bomb` | The program won't exit even if you make a wrong input.                |
| View code and registers           | `layout regs`    | Split the screen to display assembly code and register values.        |
| Step one instruction              | `ni`             | Execute the next assembly instruction (without entering a function).  |
| Step into function call           | `si`             | Step into the function called by the `call` instruction.              |
| Examine string at register        | `x/s $rdi`       | Examine the string pointed to by the register (useful for C strings). |
| Print register integer value      | `p $rax`         | Print the integer value stored in the register.                       |
| Examine integer at memory address | `x/d 0x123456`   | Examine the integer value at the specified memory address.            |

## Phase 1 

First of all, use GDB open this codes and play a breakpoint at this application, after run it and input some words, like `abc`.

![[image-53.png]]
                                     *Fig 1*

Prompted to enter phase_1(), I first opened `bomb.s` in VSCode and searched for phase_1(). There I found the familiar `call` instruction (Fig. 2), with the address `400ee0`. Continuing the search for this address in the static code, I quickly located the disassembly of the function. And so, the battleground for this experiment was set (Fig. 3).

![[image-54.png]]
fig 2

![[image-55.png]]
fig 3

Use VSCode to analyze the static code, use GDB for dynamic verification and to observe register value changes, and finally run the program once to see the result.

```c:
0000000000400ee0 <phase_1>:
  400ee0:	48 83 ec 08          	sub    $0x8,%rsp   // Align stack to 16-byte boundary (System V ABI requirement)
  400ee4:	be 00 24 40 00       	mov    $0x402400,%esi // Load address of the reference string (solution) into 2nd argument (%rsi)
  400ee9:	e8 4a 04 00 00       	call   401338 <strings_not_equal> // Call comparison function: strings_not_equal(input, reference)
  400eee:	85 c0                	test   %eax,%eax // Check return value (%eax). 0 means equal, 1 means not equal.
  400ef0:	74 05                	je     400ef7 <phase_1+0x17> // If %eax == 0 (Equal), jump to safe exit (Success)
  400ef2:	e8 43 05 00 00       	call   40143a <explode_bomb> // If %eax != 0, trigger bomb explosion (Fail)
  400ef7:	48 83 c4 08          	add    $0x8,%rsp // Restore stack pointer (Deallocate stack frame)
  400efb:	c3                   	ret    // Return to caller (main)
```

Thought process: Noticed that the `esi` register holds a value that looks like an address — `0x402400`. The next line calls `strings_not_equal`, so it's likely that we can directly examine the memory content using `x/s 0x402400`.

![[image-56.png]]
fig 4
- x check memory(Examine)
- /s Display in string format

### Like OllyDbg Operated

| Operation          | OllyDbg / x64dbg           | GDB Command                                                 |
| ------------------ | -------------------------- | ----------------------------------------------------------- |
| Step Over (F8)     | Step Over                  | `ni` (Next Instruction)                                     |
| Step Into (F7)     | Step Into                  | `si` (Step Instruction)                                     |
| View registers     | Right-side register window | `layout regs` or `i r` (info registers)                     |
| View memory        | Bottom Hex Dump window     | `x/s address` (view string) or `x/d address` (view integer) |
| Run to cursor (F4) | F4                         | `until *address`                                            |

as blow fig 5, it actually changed
![[image-57.png]]

this phase just focus on these registers's num changed, finally we could run this app whether ture.

| Register | Approximate value from your screenshot | Meaning and importance      | Your focus points                                                                                                                                                                                                           |
| -------- | -------------------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rip`    | `0x400ee4`                             | Current instruction pointer | Corresponds to the highlighted line `mov $0x402400,%esi`. GDB automatically highlights the current instruction, so you don't need to watch this closely.                                                                    |
| `rsi`    | `0x603780` (before being overwritten)  | Second function argument    | Before executing `mov`, it holds leftover garbage (or an address from a previous operation). It is about to be overwritten with the address of the secret password, so its current value is irrelevant.                     |
| `rdi`    | `0x603780...`                          | First function argument     | **Critical!** This usually points to the input string you entered. `read_line` stores your input (e.g., "abc") at the address in this register.                                                                             |
| `rax`    | `0x0` (or other value)                 | Return value                | After `read_line` executes, it doesn't return a special value, so you can ignore it. However, after `strings_not_equal` executes, you must watch it closely: `0` means the strings are equal, `1` means they are not equal. |




## Phase_2
 
Into the `bomb` catalogs, start GDB then set the breakpoint.

```c:

gdb bomb  

b phase_2
```

We could use last phase's key, so run ans.txt.

```c:
(gdb) run ans.txt
```

Open The Sharingan
```c:
(gdb) layout asm    <-- Open the assembly window
(gdb) layout regs   <-- Open the register window (this is really cool, you can see registers change color)
(gdb) ni            <-- Single-step execution (Next Instruction)
```

![[image-58.png]]


As shown blow, after the single-step execution , firstly read the disassembled code , I find it just push data into `rbx` , then `rsp` minus 0x28 (Dec 40), which means ` it move the stack pointer downward to make room for storing data.`

![[image-59.png]]

Continued single-step execution then bomb the first code lol.
![[image-60.png]]

Therefore, the goal of this `phase_2` is to reversely deduce 6 correct integers. As you can see at `<phase_2+14>`, the value at the address pointed to by `rsp` is compared with the number 1. If they are equal, the program jumps to the address `0x400f30`; otherwise, the bomb explodes.

```c:
0x400f0a <phase_2+14>   cmpl   $0x1, (%rsp)
0x400f0e <phase_2+18>   je     0x400f30 <phase_2+52>
0x400f10 <phase_2+20>   callq  0x40143a <explode_bomb>
```

for the best call `explode_bomb` this function what happen, so I input this command to the GDB:
```c
disas phase_2
```

Combine static code analysis with dynamic debugging to reverse-engineer data values.

 `Code Analysis`
 The initial stack structure should be as follows:

| Memory Address | Offset relative to %rsp | Content Stored       | Corresponding Instruction / Note          |
| -------------- | ----------------------- | -------------------- | ----------------------------------------- |
| 124            | `%rsp + 0x18` (24)      | (Out-of-bounds area) | `%rbp` (Finish line / end of frame)       |
| 120            | `%rsp + 0x14` (20)      | Number 6             |                                           |
| 116            | `%rsp + 0x10` (16)      | Number 5             |                                           |
| 112            | `%rsp + 0x0c` (12)      | Number 4             |                                           |
| 108            | `%rsp + 0x08` (8)       | Number 3             |                                           |
| 104            | `%rsp + 0x04` (4)       | **Number 2**         | **`%rbx` (Starting line / base of loop)** |
| 100            | `%rsp + 0`              | Number 1             | ← Current `%rsp` points here              |


```c
400f30:	48 8d 5c 24 04       	lea    0x4(%rsp),%rbx
400f35:	48 8d 6c 24 18       	lea    0x18(%rsp),%rbp
400f3a:	eb db                	jmp    400f17 <phase_2+0x1b>
```
Throughtout the `lea` codes discount address
$address = basic + offset$   for example, rbx = rsp + 4, which means simply increment the RSP register by one number, then use RBP as a sentinel to retrieve boundary values within this stack. This time it will jump this  `400f17` address.

`400f17`
```c:

  400f17:	8b 43 fc             	mov    -0x4(%rbx),%eax
  400f1a:	01 c0                	add    %eax,%eax
  400f1c:	39 03                	cmp    %eax,(%rbx)
  400f1e:	74 05                	je     400f25 <phase_2+0x29>
  400f20:	e8 15 05 00 00       	call   40143a <explode_bomb>
```

The code analysis is as follows: The `mov` instruction reads a value from memory and stores it in the `eax` register. Then it performs an addition operation: `eax = eax + eax`.
Afterward, it compares the value read by the cursor register `rbx` with the value in `eax`. If they are equal, execution continues downward; if they are not equal, it calls `explode_bomb` again.
After reverse engineering, recreate this code segment—it's likely a looping conditional structure.

```c:

void phase_2(char *input) {
int numbers[6];
read_six_numbers(input,numbers);  // Read 6 numbers from input and store them in the stack

// In assembly：cmpl $1, (%rsp)
if (numbers[0] != 1) { explode_bomb(); }



// In assembly：lea 0x4(%rsp), %rbx <-- rbx points to &numbers[1]
// In assembly：lea 0x18(%rsp), %rbp <-- rbp points to &numbers[6] (out-of-bounds position)
int *rbx = &numbers[1]; 
int *rbp = &numbers[6];

// In assembly：jmp 400f17 (enter loop)
while (rbx != rbp) { // Loop until the cussor reaches the boundary

// In assembly：mov -0x4(%rbx), %eax <-- Fetch the previous num 
int prev_val = *(rbx - 1);

// add %eax, %eax <-- Double the value (equivalue to multiplying by 2) 
int expected_val = prev_val + prev_val;

// cmp %eax, (%rbx) <-- Compare current value with expected value 
if (*rbx != expected_val) { explode_bomb(); }

// add $0x4, %rbx <-- Move the cursor forward by 4 bytes(1 int)
rbx++; }
}

```



```c:

void phase_2(char *input) {
    int numbers[6];
    read_six_numbers(input, numbers);

    // 1. Check the firstly number
    if (numbers[0] != 1) {
        explode_bomb();
    }

    // 2. Loop and check the five numbers following
    // The assembly starts from numbers[1] because it needs to locate numbers[i-1].
    for (int i = 1; i < 6; i++) {
        
        int prev = numbers[i-1];
        int current = numbers[i];

        // Rule: The current number must be twice the previous number.
        if (current != prev * 2) {
            explode_bomb();
        }
    }
}
```


### Critical operation
```c:
layout asm // Visualize what a loop looks like
x/6wd $rsp // Display the contents of memory in decimal format
```

## Phrase_3
Search keyword phrase_3. Treat the static-end code as white-box code review, then open GDB for dynamic verification of my reverse engineering approach.

```c:
0000000000400f43 <phase_3>:
  400f43:	48 83 ec 18          	sub    $0x18,%rsp
  400f47:	48 8d 4c 24 0c       	lea    0xc(%rsp),%rcx
  400f4c:	48 8d 54 24 08       	lea    0x8(%rsp),%rdx
  400f51:	be cf 25 40 00       	mov    $0x4025cf,%esi
  400f56:	b8 00 00 00 00       	mov    $0x0,%eax
  400f5b:	e8 90 fc ff ff       	call   400bf0 <__isoc99_sscanf@plt>
```

This code segment first allocates a 24-byte stack frame. The lea instruction then calculates addresses, assigning values to two parameters—here referred to as x and y. x is assigned to 0x8, and y is assigned to 0xc. My initial thought is that this code aims to input the correct x and y values to trigger an exploit.

Here's a new tidbit I picked up. Lines 5–7 of the code, specifically the section in line 6, involve a special case related to `Variadic Functions`. This means that when compilers like gcc/clang generate assembly code, they must adhere to the System V AMD64 ABI (Application Binary Interface). This document contains a specific rule for variadic functions (functions with a variable number of arguments, such as `printf`, `scanf`, `open`, etc.) :

> When calling a function with variable-length arguments, the caller must use the `%al` register (the lower 8 bits of `%rax`) to inform the callee: “How many arguments are stored in XMM (floating-point) registers?”

So why do this? I believe it's primarily for performance optimization. We know that integer units and floating-point units are different in computing. That is, functions like `printf` don't know what you'll pass to them. If it's an integer, there's no need to access XMM registers; only floating-point values require it. To prevent unnecessary overhead, the function call specifies how many XMM registers it uses beforehand. If it's zero, that means no XMM register access is needed. Line 7 calls the sscanf function, which I believe prompts for input parameters. I also examined the memory at `x/s 0x4025cf` via instructions to determine whether the input is integer or string type. I found two `%d` parameters, not `%s`. Therefore, two integers are input. This aligns with the earlier special stipulation, providing mutual corroboration.

```c:
  400f60:	83 f8 01             	cmp    $0x1,%eax
  400f63:	7f 05                	jg     400f6a <phase_3+0x27>
  400f65:	e8 d0 04 00 00       	call   40143a <explode_bomb>
  400f6a:	83 7c 24 08 07       	cmpl   $0x7,0x8(%rsp)
  400f6f:	77 3c                	ja     400fad <phase_3+0x6a>
  400f71:	8b 44 24 08          	mov    0x8(%rsp),%eax
```

Lines 1 to 3 here actually compare the value in EAX. If this parameter is greater than the threshold, it triggers an explosion. The critical part is the fourth line of code, which compares the data on the stack—specifically the value in RDX—with 7. If it's less than 7, execution continues; otherwise, it triggers an explosion.

```c:
  400f75:	ff 24 c5 70 24 40 00 	jmp    *0x402470(,%rax,8)
```

As shown blow, this jump marked with an asterisk `*` indicates an indirect jump to a fixed address, which is actually a table. Based on this table, it jumps to different code blocks.

![[image-61.png]]

Analyzing this code segment reveals a flow similar to a switch statement. At address `400fbe`, it directly evaluates the input y value. This suggests the code functions like a lockbox: matching x and y values bypasses the explosion trigger. Based on previous x inputs, x should be a number no greater than 7 (0-7). The corresponding MOV instructions also indicate this.

  

Corresponding code block case 0 ~ 7 :

| **Hypothetical input x** | **Code key (Hex)**         | **Corresponding decimal input y** |
| ------------------------ | -------------------------- | --------------------------------- |
| **0**                    | `mov $0xcf, %eax`          | **207**                           |
| **1**                    | `mov $0x2c3, %eax`         | **707**                           |
| **2**                    | `mov $0x100, %eax`         | **256**                           |
| **3**                    | `mov $0x185, %eax`         | **389**                           |
| **4**                    | `mov $0xce, %eax`          | **206**                           |
| **5**                    | `mov $0x2aa, %eax`         | **682**                           |
| **6**                    | `mov $0x147, %eax`         | **327**                           |
| **7**                    | `mov $0x137, %eax` (below) | **311**                           |

### Summary
Finally, I discovered that the input x values did not correspond to the y values in this table. This revealed that the switch statement actually performs a random mapping at the underlying level. The sequence itself is determined by the Jump Table (`0x402470`), and the compiler does not necessarily arrange the values in the order I had envisioned, such as 0, 1, 2, 3.


## Phase_4
It remains static analysis of disassembled code.

```c:
  40100c:	48 83 ec 18          	sub    $0x18,%rsp
  401010:	48 8d 4c 24 0c       	lea    0xc(%rsp),%rcx
  401015:	48 8d 54 24 08       	lea    0x8(%rsp),%rdx
  40101a:	be cf 25 40 00       	mov    $0x4025cf,%esi
  40101f:	b8 00 00 00 00       	mov    $0x0,%eax
  401024:	e8 c7 fb ff ff       	call   400bf0 <__isoc99_sscanf@plt>
```

Still the familiar formula: the stack frame allocates 24 bytes of space, then calculates the addresses for rcx and rdx respectively. That is, the address at rsp+8 is assigned to the rdx register, and the address at rcx+c is assigned to the rcx register. Lines 4–6 call the sscanf function to input two variables. For simplicity, let's denote x as rdx and y as rcx. At this point, the input values are placed into the ESI register, so I need to determine the types of these two inputs.
![[image-62.png]]

As shown above，it could be judge int style. I guess it if whether two numbers from the number 5 code judgement.

```c:
40102e:	83 7c 24 08 0e       	cmpl   $0xe,0x8(%rsp)
401033:	76 05                	jbe    40103a <phase_4+0x2e>
```

Compare x with 14. If x is less than 14, jump to address `40103a`.

`40103a `
```c:
40103a:	ba 0e 00 00 00       	mov    $0xe,%edx
40103f:	be 00 00 00 00       	mov    $0x0,%esi
401044:	8b 7c 24 08          	mov    0x8(%rsp),%edi
401048:	e8 81 ff ff ff       	call   400fce <func4>
```

This code assigns values to the edx, esi, and edi registers respectively. It then calls the function func4.

Therefore, the parameter passing is:
- edi = x (the data of input)
- esi = 0 (low)
- edx = 14 (high)

`func4`

```c:
400fd2: mov %edx, %eax     ; eax = High (14)
400fd4: sub %esi, %eax     ; eax = High - Low
400fd6: mov %eax, %ecx     ; ecx = High - Low
400fd8: shr $0x1f, %ecx    ; (This step handles the sign bit. If it's a positive number, it's 0 and can be ignored.)
400fdb: add %ecx, %eax     ; (Ibid., common compiler optimization techniques for division)
400fdd: sar %eax           ; eax = (High - Low) / 2  <-- Arithmetic right shift equals division by 2.
400fdf: lea (%rax,%rsi,1), %ecx  ; ecx = Low + (High - Low) / 2
```

Reconstructing this formula is roughly
$ecx = Low + \frac{High-Low}{2} = Mid \tag 1$

Therefore, the function func4 performs a binary search within the range of 0 to 14.

```C:
  400fe2:	39 f9                	cmp    %edi,%ecx
  400fe4:	7e 0c                	jle    400ff2 <func4+0x24>
  400fe6:	8d 51 ff             	lea    -0x1(%rcx),%edx
  400fe9:	e8 e0 ff ff ff       	call   400fce <func4>
  400fee:	01 c0                	add    %eax,%eax
  400ff0:	eb 15                	jmp    401007 <func4+0x39>
  400ff2:	b8 00 00 00 00       	mov    $0x0,%eax
```

This code compares input x with mid. If x is less than mid, it proceeds downward. The range is defined as High = mid - 1. The return value is calculated as `add %eax, %eax`, then multiplied by 2.

```c:
  400ff7:	39 f9                	cmp    %edi,%ecx
  400ff9:	7d 0c                	jge    401007 <func4+0x39>
  400ffb:	8d 71 01             	lea    0x1(%rcx),%esi
  400ffe:	e8 cb ff ff ff       	call   400fce <func4>
  401003:	8d 44 00 01          	lea    0x1(%rax,%rax,1),%eax
  401007:	48 83 c4 08          	add    $0x8,%rsp
  40100b:	c3                   	ret  
```

If x > Mid, take the right branch. The code proceeds to 400ffb, where low = Mid + 1. The return value `lea 0x1 (%rax, %rax, 1), %eax` is multiplied by 2 and incremented by 1. If x = mid, the target is found at `400ff2` and returns 0.
 
![[image-63.png]]

Since we know it's a binary search, the solution is straightforward. The key question is: what value should func4 return for this lab? This code clearly provides the value for y. So the next step is to write the answer to ans.txt, hoping to skip the explosion and move on to the next lab.

![[image-64.png]]

Through this phase!

### Summary 
Let's review the lea (Load Effective Address) instruction again. Originally designed for address calculation, compilers favor it for mixed addition and multiplication operations because it's fast and doesn't consume flag bits.
In this phase, the standard format is as follows:
`D(Base, Index, Scale)`

The mathematical formula is as follows:

$result = Base + (Index x scale) + Displacement$

Therefore, in the code of this example
```c:
400fdf: lea (%rax,%rsi,1), %ecx  ;
```

- Base = rax
- Index = rsi
- Scale = 1
- Displacement = If it's not written here, it's zero.
> ecx = %rax + (%rsi x 1) + 0

we can see this lea(a,b,c),d  -> d = a + (bxc)

Of course, this line alone isn't enough to determine it's a binary search; we need to consider the preceding code. Specifically, when entering func4, ESI is the second argument (ESI = 0). But what about RAX?

```c:
400fd2: mov %edx, %eax    ; eax = High (14)
400fd4: sub %esi, %eax    ; eax = High - Low
...
400fdd: sar %eax          ; eax = eax / 2 (A right shift by one bit is equivalent to division by two)
```

rax = （High - low) / 2

Final Fusion（lea)
ecx = rax + rsi
$ecx = Low + \frac{High-Low}{2} = Mid \tag 1$

#### The code before func4 all uses eax, esi, ecx, but why does it switch to rax, rsi at 400fdf? I was completely baffled when analyzing this part—why the sudden change?
1. Russian nesting dolls: Registers are actually “the same one.”

First, don't treat `eax` and `rax` like two strangers. They actually share a **parent-child relationship** (or a whole-part relationship).

- **`%rax`**：It's that **64-bit** big box (the standard width for modern computers).
    
- **`%eax`**：Right inside `%rax`, occupying the **lower 32 bits**.
    

This is like:

- `%rax` It is a box containing **8 bottles of water**.
    
- `%eax` The first four bottles in this box.
    

2. Why does assembly code sometimes use `e` and sometimes use `r`?

#### (1) The width of the operands differs.

- The instructions preceding the code, such as `sub %esi, %eax`, operate on the `int` type (integer). In C, `int` is only **32 bits**. Therefore, for simplicity and efficiency, the compiler directly manipulates `%eax` and `%esi`.
    

#### (2) Why did `lea` suddenly use `rax`?

At the line `400fdf: lea (%rax,%rsi,1), %ecx`:

  

**The `lea` instruction essentially simulates “address calculation”.** In x86-64 systems, **memory addresses (pointers) must be 64 bits**.

  

Although we're using `lea` here to perform arithmetic (addition), because its syntax follows the `Base + Index` format, the CPU customarily uses **64-bit registers** (`%rax`, `%rsi`) to serve as the base and index.

**You might ask:**

>“But earlier we were calculating with `eax` (32-bit), and now suddenly we're using `rax` (64-bit). **Won't the junk data in the upper 32 bits mess up the result?**”

 3. Core Secret: The “Auto-Zeroing” Rule in x86-64

This is the most crucial point! Be sure to remember this “unwritten rule”:

> **In x86-64 mode, any write operation to a 32-bit register (such as `%eax`) automatically clears the upper 32 bits of the corresponding 64-bit register (`%rax`)!**

recall this process of code：

1. **`mov %edx, %eax`**
    
    - You think it only changed the lower 32 bits?
        
    - **Actual behavior**: It copies the value of `%edx` to `%eax`, **while simultaneously clearing the upper 32 bits of `%rax` to zero**.
        
    - At this point: The value of `%rax` === The value of `%eax` (numerically identical).
        
2. **`sub %esi, %eax`** ... **`sar %eax`**
    
    - These operations all update `%eax` while simultaneously ensuring that the high-order bits of `%rax` remain 0.
        
3. **`lea (%rax, %rsi, 1), ...`**
    
    - At this stage, the compiler is highly confident: it knows that the high bits of `%rax` are all zeros, and the number stored there (such as 7) is both a 32-bit 7 and a 64-bit 7.
        
    - Therefore, it can safely use `%rax` in 64-bit `lea` operations, and the result will be absolutely correct.
        

##### Summary of the phase

- **Why did it change?** Because `lea`, as an “address calculation” instruction, uses 64-bit source register names (`rax`, `rsi`) to comply with the specifications for 64-bit address addressing.
    
- **Why did it work?** Because all previous operations on `eax` leveraged the hardware feature where **“writing 32 bits automatically clears the upper 32 bits”**, ensuring that `rax` contained clean values free of garbage data.


## Phase_5
Today we'll continue this lab. When opening this program, the basic operations are as follows:
```c:
gdb bomb
run ans.txt
```

Open the bomb's disassembled code simultaneously for static analysis. Set breakpoints for this program in GDB.

```c:
0000000000401062 <phase_5>:
  401062:	53                   	push   %rbx
  401063:	48 83 ec 20          	sub    $0x20,%rsp
  401067:	48 89 fb             	mov    %rdi,%rbx
  40106a:	64 48 8b 04 25 28 00 	mov    %fs:0x28,%rax
  401071:	00 00 
  401073:	48 89 44 24 18       	mov    %rax,0x18(%rsp)
  401078:	31 c0                	xor    %eax,%eax
  40107a:	e8 9c 02 00 00       	call   40131b <string_length>
  40107f:	83 f8 06             	cmp    $0x6,%eax
```

In this code snippet, I noticed that line 9 calls a `string_length` function, and the next line compares a value to 6. Is this checking if the character length is 6?

![[image-65.png]]

This is part of the code for phase5. The circled sections explain what each code segment does.

```c:
 401078:	31 c0                	xor    %eax,%eax
```

Assuming i=0, XORing with itself always yields 0. Here, `%eax` and the subsequent `rax` are both used as the `Index`.

```c:
  40108b:	0f b6 0c 03          	movzbl (%rbx,%rax,1),%ecx
```

`rbx` is the address of the input string, and `rax` is the index value `i`, likely corresponding to `char c = input[i]`.

```c:
and $0xf, %edx
```
Extract the lower 4 bits. `0xf` is binary 0000 1111, retaining only the last 4 bits of the character. Thus, regardless of the input character, this step converts it into a number between 0 and 15. For example: ‘a’ (ASCII 97, hex 0x61) -> `0x61 & 0xF = 1`.

  

Therefore, this code likely performs a lookup in a table. Based on previous experiments, the assembly code uses XOR, array indexing, and bitwise operations, suggesting it's employed for “encryption” or “hashing” purposes.

```c:
movzbl 0x4024b0(%rdx), %edx
```
Therefore, a lookup table mapping is required. Here, `0x4024b0` is a memory address (the start of the array), and `%rdx` is the calculated number between 0 and 15. This means `new_char = table[c & 0xF]`, essentially using the calculated number as an index to look up a new character in this ciphertext table.

```c:
  4010bd:	e8 76 02 00 00       	call   401338 <strings_not_equal>
  4010c2:	85 c0                	test   %eax,%eax
  4010c4:	74 13                	je     4010d9 <phase_5+0x77>
  4010c6:	e8 6f 03 00 00       	call   40143a <explode_bomb>
  4010cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  4010d0:	eb 07                	jmp    4010d9 <phase_5+0x77>
  4010d2:	b8 00 00 00 00       	mov    $0x0,%eax
  4010d7:	eb b2                	jmp    40108b <phase_5+0x29>
  4010d9:	48 8b 44 24 18       	mov    0x18(%rsp),%rax
  4010de:	64 48 33 04 25 28 00 	xor    %fs:0x28,%rax
```
Based on the subsequent code, this performs an encryption method on the input string. For example, when a character is input, it examines its last four digits (converting them to an index between 0 and 15) and looks up the corresponding character in the character table at `0x4024b0`. Finally, it concatenates the retrieved characters into a new string and compares this new string with the target string (`0x40245e`) to determine if they are equal.

### Dynamic Verification
```c:
x/s 0x4024b0
```
So let's work backward logically and first examine this **code book**.

![[image-67.png]]
As shown in the figure above, this string is the table we need to search. Therefore, we now need to examine the **target string**.

```c:
x/s 0x40245e
```

As shown below:
![[image-68.png]]

We already have the code book and the target string, so we need to create a **mapping table** for this.


Map the 16 characters in the code book to their corresponding indices:

| **Index** | **Char** | **Binary (last 4 bits)** |
| --------- | -------- | ------------------------ |
| 0         | m        | 0000                     |
| 1         | a        | 0001                     |
| 2         | d        | 0010                     |
| 3         | u        | 0011                     |
| 4         | i        | 0100                     |
| **5**     | **e**    | **0101**                 |
| **6**     | **r**    | **0110**                 |
| **7**     | **s**    | **0111**                 |
| 8         | n        | 1000                     |
| **9**     | **f**    | **1001**                 |
| 10        | o        | 1010                     |
| 11        | t        | 1011                     |
| 12        | v        | 1100                     |
| 13        | b        | 1101                     |
| **14**    | **y**    | **1110**                 |
| **15**    | **l**    | **1111**                 |
Therefore, we need to find the input character `input`, which requires `input & 0xF == Index`.
The simplest approach is to find the ASCII code whose lower 4 bits match the corresponding Index's lowercase letter.
For example:
1. f->Looking up the table yields index 9, which requires one character. The lower 4 bits of ASCII are 1001 (9), corresponding to ‘i’ (ASCII 0x69) -> 0x69 & 0xF = 9. Similarly for subsequent characters.
2. l-> index 15, 'o' -> 0x6F & 0xF = 15
3. y -> index 14, 'n' -> 0x6E & 0xF = 14
4. e->index 5, 'e'-> 0x65 & 0xF = 5
5. r -> index 6,'f' -> 0x66 & 0xF = 6
6. s->index 7->'g'->0x67 & 0xF = 7

Therefore, the resulting password is `ionefg`.

![[image-70.png]]

## Phase_6
After verifying the answers from the previous phase, we proceed to the final phase. Following the usual routine, we open the disassembled code in GDB.

```c:
00000000004010f4 <phase_6>:
  4010f4:	41 56                	push   %r14
  4010f6:	41 55                	push   %r13
  4010f8:	41 54                	push   %r12
  4010fa:	55                   	push   %rbp
  4010fb:	53                   	push   %rbx
  4010fc:	48 83 ec 50          	sub    $0x50,%rsp
  401100:	49 89 e5             	mov    %rsp,%r13
  401103:	48 89 e6             	mov    %rsp,%rsi
  401106:	e8 51 03 00 00       	call   40145c <read_six_numbers>
```
The assembly code here revealed an “abnormal” stack operation. Upon investigation, I discovered this is a crucial rule in assembly language: `Callee-Saved Registers`.
In the x86-64 ecosystem (ABI standard), registers are categorized into two types:
- Caller-Saved: For example, `%rax`, `%rcx`, `%rdx`, `%rsi`, `%rdi`. Functions can use these freely; it's no big deal if the original values are lost.
- **Must Be Saved (Callee-Saved)**: For example, `%rbx`, `%rbp`, `%r12`, `%r13`, `%r14`, `%r15`**. The rule is: if you need to use these registers, you must first save their original values onto the stack. After use, before returning, you must restore them to their original state (Pop). It's like borrowing a friend's car (register) for off-roading. When you pick up the car, there's a can of gas (the original value) in the trunk. You can take the gas out and set it aside (Push), then load your own stuff and drive off. But when you return the car, you must put that can of gas back exactly as it was (Pop). You can't let your friend see that the car has been tampered with.
Why are so many registers being borrowed here? Because this is a linked list operation, requiring simultaneous tracking of the current node's address, the next node's address, the loop counter, temporary comparison values, and so on. Then immediately follows `sub $0x50, %rsp`.

`read_six_numbers`
```c:
000000000040145c <read_six_numbers>:
  40145c:	48 83 ec 18          	sub    $0x18,%rsp
  401460:	48 89 f2             	mov    %rsi,%rdx
  401463:	48 8d 4e 04          	lea    0x4(%rsi),%rcx
  401467:	48 8d 46 14          	lea    0x14(%rsi),%rax
  40146b:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
  401470:	48 8d 46 10          	lea    0x10(%rsi),%rax
  401474:	48 89 04 24          	mov    %rax,(%rsp)
  401478:	4c 8d 4e 0c          	lea    0xc(%rsi),%r9
  40147c:	4c 8d 46 08          	lea    0x8(%rsi),%r8
  401480:	be c3 25 40 00       	mov    $0x4025c3,%esi
  401485:	b8 00 00 00 00       	mov    $0x0,%eax
  40148a:	e8 61 f7 ff ff       	call   400bf0 <__isoc99_sscanf@plt>
  40148f:	83 f8 05             	cmp    $0x5,%eax
  401492:	7f 05                	jg     401499 <read_six_numbers+0x3d>
  401494:	e8 a1 ff ff ff       	call   40143a <explode_bomb>
  401499:	48 83 c4 18          	add    $0x18,%rsp
  40149d:	c3                   	ret  
```

First, examine the latter part of this function—specifically line 14 of the code. Here, `$0x5` effectively restricts the input numbers to be between 1 and 6 (since it's an unsigned comparison, typically using 1-based indexing, or the code logic includes a `-1` operation). This indicates that each of the six input numbers must not exceed 6.
`Scope Check`
```c:
40111b: sub $0x1, %eax     ; Subtract 1 from the number you input
40111e: cmp $0x5, %eax     ; Compare whether (Num - 1) is greater than 5
401121: jbe ...            ; If the result is ≤ 5, this means Num is between 1 and 6 → valid!
```
It can be determined that this number must be between 1 and 6.

`Double-loop check for duplicates (in progress)`
```c:
  401121:	76 05                	jbe    401128 <phase_6+0x34>
  401123:	e8 12 03 00 00       	call   40143a <explode_bomb>
  401128:	41 83 c4 01          	add    $0x1,%r12d
  40112c:	41 83 fc 06          	cmp    $0x6,%r12d
  401130:	74 21                	je     401153 <phase_6+0x5f>
  401132:	44 89 e3             	mov    %r12d,%ebx
```
This is an outer loop where the counter i increments from 0 to 5. After processing these 6 numbers, if i == 6, the check completes and the loop exits (to process the subsequent linked list). The current index i is copied to %ebx (serving as the inner loop counter j).

`7 - x Trap`
```c:
40115b:	b9 07 00 00 00       	mov    $0x7,%ecx
  401160:	89 ca                	mov    %ecx,%edx
  401162:	2b 10                	sub    (%rax),%edx
  401164:	89 10                	mov    %edx,(%rax)
```
Here, each input number x is transformed into 7-x. If 1 is entered, it becomes 6; if 3 is entered, it becomes 4.

`Mapping: Converting Numbers into Pointers`
The subsequent loop (around `401183`)
```c:
401183:	ba d0 32 60 00       	mov    $0x6032d0,%edx
  401188:	48 89 54 74 20       	mov    %rdx,0x20(%rsp,%rsi,2)
```
The logic is as follows: based on your (reversed) number, locate the corresponding node in the linked list and arrange them in sequence to form a queue.

`Check the value of the linked list`
What order should the linked list be arranged in? Typically, Phase 6 of Bomb Lab requires descending order (Descending Order), meaning `largest to smallest`. This requires examining the values stored in each of the six child nodes.

```c:
x/24wx 0x6032d0
```
(This will print the memory contents starting from the root node. You will see each node's value and the pointer to the next node.)

```c:
0x6032d0 <node1>:       332     1       6304480 0
0x6032e0 <node2>:       168     2       6304496 0
0x6032f0 <node3>:       924     3       6304512 0
0x603300 <node4>:       691     4       6304528 0
0x603310 <node5>:       477     5       6304544 0
0x603320 <node6>:       443     6       0       0
```

For these values, the experimental rule is to reconnect the linked list nodes in descending order. Therefore, the reordered sequence is: Node 3 -> 4 -> 5 -> 6 -> 1 -> 2.

*Key Conversion*  The preceding code contains a 7-x logic, so to obtain a specific node, the input number must be 7 minus N. This involves converting the number 7 and the input number. The final result should be the answer.

![[image-74.png]]

