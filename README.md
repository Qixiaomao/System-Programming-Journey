# System-Programming-Journey
A deep dive into Computer Systems. Focuses on recverse engineering (GDB/Assembly), bit-level optimization (relevant to Model Quantization), and memory hierarchy analysis. Documents the underlying mechanisms behind efficient software execution. 

> **Note:** This repository documents my self-study journey through *Computer Systems: A Programmer's Perspective (3rd Ed)*. 
> Instead of posting direct solution codes, this project focuses on **reverse engineering**, **low-level analysis**, and **hardware-aware optimization notes**.

##  Overview & Motivation
As a researcher aiming for **Edge AI** and **Deep Learning System Optimization**, understanding the underlying hardware mechanisms is crucial. I use these labs to build a rigorous foundation in:
* **Data Representation:** Bit-level manipulation and IEEE 754 floating-point standards (Fundamental for **Model Quantization**).
* **Machine Level Programming:** x86-64 Assembly, Control Flow, and Stack Frame management (Fundamental for **Compiler Backend Design**).
* **Memory Hierarchy:** Cache locality and memory allocation (Fundamental for **Inference Acceleration**).

---

##  Lab Analysis Highlights

### 1. Data Lab: Bit-Level Manipulation
**Focus:** Implementing standard arithmetic and logical operations using a restricted set of bitwise operators.

* **Key Challenge:** `floatScale2` & `floatPower2`
* **System Insight:**
    * Deep dive into **IEEE 754** single-precision representation (Sign, Exponent, Mantissa).
    * Handled corner cases (Denormalized values, Infinity, NaN) purely via bit-masks.
    * *Relevance to Research:* This low-level understanding of floating-point representation is directly applicable to implementing **Mixed-Precision Quantization (FP8/INT8)** in deep learning compilers.

### 2. Bomb Lab: Reverse Engineering & Control Flow
**Focus:** Analyzing a binary executable (`bomb`) without source code to understand procedural calls, stack discipline, and control flow.

* **Tools Used:** `GDB` (GNU Debugger), `objdump`, `x86-64 Assembly`.
* **Methodology:**
    1.  **Static Analysis:** Disassembled the binary to locate critical function entry points (`phase_1` to `phase_6`).
    2.  **Dynamic Analysis:** Used GDB `layout regs` to monitor register state changes (`%rdi`, `%rsi`, `%rax`) and verify parameters before function calls.
    3.  **Logic Reconstruction:** Translated raw assembly instructions back into C-level control structures (loops, switch statements, recursion).

####  Analysis Snapshot (Phase 1 & 2)
*Below represents my workflow of tracing stack pointers and analyzing register values during runtime:*



<img width="2471" height="385" alt="image" src="https://github.com/user-attachments/assets/367c3365-d6cc-47e3-9d5a-df4e9f790430" />
*(Fig 1: Tracing the comparison logic in Phase 1 using GDB register layout)*

---

##  Tech Stack & Environment
* **Environment:** Windows Subsystem for Linux (WSL2) - Ubuntu 20.04
* **Compiler:** GCC with `-Og` optimization level
* **Debugger:** GDB with TUI mode
* **Build Tools:** Make

---

##  Future Roadmap
* **Attack Lab:** Exploring buffer overflow vulnerabilities and code injection (Security).
* **Cache Lab:** Optimizing C programs for memory locality to minimize cache misses (Performance).
* **Malloc Lab:** Implementing a dynamic memory allocator (Heap Management).

---

##  Academic Integrity Disclaimer
This repository contains **analysis notes, logic flowcharts, and generic snippets** only. Full solution files (e.g., `bomb` answer strings) are intentionally excluded to uphold the honor code and encourage independent learning.

