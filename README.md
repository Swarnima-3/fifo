# Synchronous + Asynchronous FIFO with CDC

## 1. Synchronous FIFO
### Design
The FIFO consists of 16 memory location each of which can hold an 8 bit word. It has the following signals: 
wr_en - indicates that writing is enabled
rd_en - indicates that reading is enabled
din - input to be written into the FIFO
dout - output to be read from the FIFO
rst_n - active low reset signal
clk- input clock to the FIFO which enables it to read or write data at the positive edge

### The full-vs-empty problem and the extra-MSB trick
We need to configure the FIFO for two critical cases, i.e. when the FIFO is full and no more data can be written into it and when the FIFO is empty - i.e when no more data can be read from it.

If we use the rd_ptr and wr_ptr to be of only log2(DEPTH) bits , it would be impossible to distinguish between the two. 

Thus to help differentiate between the two conditions we will make use of an extra MSB. This bit with suitable logic will help us find the values for the full and empty bit. 

### Flag logic

empty = (wr_ptr == rd_ptr) — all bits equal thus both pointers at the same location.
full = (addresses equal) && (wrap bits differ) — writer lapped reader once.

### Read style — registered output
The sync FIFO uses a registered read: dout is updated inside the clocked block, so read data appears one clock AFTER rd_en is asserted (1-cycle latency). This is the standard FPGA default — it maps cleanly to Block RAM (whose output is registered) and breaks the combinational path for easier timing closure. The trade-off is one cycle of read latency.

### Verification (testbench + waveform)
<img width="1570" height="807" alt="image" src="https://github.com/user-attachments/assets/2f50bde8-e28c-418d-a7aa-ec3688eb9c8e" />



## 2. Asynchronous FIFO with CDC

### Why the synchronous design breaks across clocks
A flip-flop in the read domain wants to look at the write pointer. But the write pointer is being updated by a different clock. So at the moment the reader's clock ticks and grabs the value, the write pointer might be in the middle of changing and the read side may sample a garbage value that never really existed.
### Gray-code pointers
binary   gray
000      000
001      001     ← bit 0 flipped
010      011     ← bit 1 flipped
011      010     ← bit 0 flipped
100      110     ← bit 2 flipped
101      111     ← bit 0 flipped
110      101     ← bit 1 flipped
111      100     ← bit 0 flipped
(wrap)   000     ← bit 2 flipped

The real reason of using gray code over binary is that, binary can yield a never-held value; Gray yields only old-or-new.
So the chain of reasoning:
-Pointers must cross clock domains to compute full/empty.
-A multi-bit value sampled mid-change can resolve to a value that never existed.
-Gray code changes only one bit per step → a mistimed sample yields old-or-new, both legal.
-Therefore: only Gray-coded pointers cross domains. Binary pointers stay local (you still need binary internally for addressing memory and for arithmetic).

That last point is important:keep both; Binary pointer for indexing the RAM and doing +1; convert it to Gray only for the version that crosses into the other domain. 

To convert binary to graycode: MSB unchanged, each other bit = XOR of adjacent binary pair.

Verilog code in one line: assign gray = bin ^ (bin >> 1);


### 2-flop synchronizers
What metastability is (setup/hold violation → unresolved output) and that it's unavoidable when sampling async signals.
The two-flop structure: FF1 catches it, FF2 samples a clock later once settled; cost = 1 cycle latency.
The MTBF intuition: failure probability drops exponentially with settling time → 2 flops makes it effectively never; 3 only for extreme cases.
Connect back: this is why Gray code matters — even if FF1 goes metastable and resolves to old-or-new, with Gray that's a legal value; a multi-bit binary change would still corrupt.
rclk    __|‾|__________|‾|__________|‾|___ 
          10ns         20ns         30ns

d       ______________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   (changed inside window at ~10ns)

FF1.q   ____╱╲╱╲╲╱~~~~~~~~~~~|‾‾‾‾‾‾‾‾‾‾‾   wobbles after 10ns edge,
            └─── settles within the 10ns ──┘ resolves to clean 1 well before 20ns

FF2.q   ___________________________|‾‾‾‾‾   FF2 samples FF1 at 20ns —
                                   ▲20ns     FF1 is clean by now → FF2 is clean
                                             logic only ever sees FF2 → safe

A synchronizer is always clocked by the destination domain — the one receiving the value.

e.g. -The write pointer is born in the write domain (it's updated by wclk).
-The read side needs it to compute empty (empty = "has the reader caught up to the writer?").
-So the value is travelling into the read domain. The read domain is the receiver.
-The two flops doing the catching live in the read domain, so they tick on rclk.

Sync the write pointer with rclk (read side computes empty).
Sync the read pointer with wclk (write side computes full).
Each synchronizer runs on the clock of the domain it's delivering to.

### Conservative full/empty
full means binary pointers differ only in the MSB; because gray[i]=bin[i]^bin[i+1], flipping the binary MSB flips the top two Gray bits; hence the full test inverts rgray's top two bits before comparing. Empty needs no inversion because the pointers are fully equal there — zero binary bits flipped, zero Gray bits flipped.
empty is a plain equality — rgray == wgray_synced, no inversion. Why? Because empty in binary was "pointers fully equal" (same address, same lap — no MSB flip). No bits flipped in binary → no bits flipped in Gray → plain ==

### Read style — combinational (FWFT)
Unlike the sync FIFO, the async FIFO memory read is combinational (assign rdata = mem[raddr]) — data is valid the SAME cycle, with no 1-cycle latency. This is First-Word-Fall-Through (FWFT) style. It is safe here because the read address comes from an already-registered pointer (rbin), so rdata is stable for the whole read cycle without needing another register.

Why two different styles: registered read (sync FIFO) is the FPGA default — maps to BRAM, eases timing, costs 1 cycle latency. Combinational/FWFT read (async FIFO) is lower latency and is what streaming protocols like AXI-Stream expect. Both are industry standard; the right choice depends on context (timing closure vs. latency, BRAM vs. distributed RAM, protocol requirements).

Xilinx/Intel FIFO IP generators expose this as a "Standard vs. FWFT" option.

### Verification
<img width="1572" height="815" alt="image" src="https://github.com/user-attachments/assets/3ec4c741-480d-4848-b1e8-9981cace00da" />
(fig. write clock faster)
<img width="1550" height="792" alt="image" src="https://github.com/user-attachments/assets/023a3f69-cf3c-4107-a4b8-cef1de39717e" />
(fig. write clock slower)


## 3. FIFO depth derivation
General principle:
  depth = (items written during burst) − (items read in that same time)
  then round up to a power of 2.

Worked example: writer 100 MHz, reader 80 MHz, burst of 50 items
    -writing the burst takes  50 × 10 ns = 500 ns
    -reader drains at 80 MHz (1 per 12.5 ns) → removes 500 / 12.5 = 40 items
    -pileup = 50 − 40 = 10  →  round up → depth = 16

This justifies AWIDTH = 4 (depth 16) used in this design.    
### 4. Bugs & Debugging Notes
1. Silent width-mismatch made full stick high
In the sync FIFO's full flag I wrote the address comparison as wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1] — a 4-bit slice on the left but a single bit on the right (missing the :0). Verilog zero-extends the 1-bit side instead of erroring, so it compiled clean but full never dropped during reads. Caught it by adding wr_ptr/rd_ptr to the waveform and seeing full stay high even as rd_ptr advanced. Lesson: width mismatches are silent in Verilog — check both sides of a slice comparison are the same width.

2. assign driving the wrong net name left an output floating
In rptr_empty I assigned the empty flag to empty instead of the actual port rempty. Verilog treated empty as an implicit 1-bit wire, so the real output rempty was never driven and floated to X. Lesson: a typo'd LHS doesn't error — it silently creates a new net and leaves your port undriven.

3. Converted the wrong signal to Gray
In wptr_full I fed bin2gray the waddr slice (4 bits, wrap bit dropped) instead of the full wbin (5 bits). The pointer crossing the domain would have lost its wrap bit, breaking full/empty exactly like a FIFO with no extra MSB. Lesson: the Gray pointer that crosses domains must be the full pointer including the wrap bit — the address slice is only for indexing RAM.

4. Mixed blocking/non-blocking in clocked blocks
Used = in reset branches (and once in a pointer increment) while using <= elsewhere in the same always block. In the synchronizer this is especially dangerous — blocking assignment would collapse the two flops into one and destroy the metastability protection. Lesson: clocked blocks use non-blocking <= everywhere, reset included.

5. Array-vs-vector port declarations in fifomem
Declared ports as wire waddr [AWIDTH-1:0] (an array of 1-bit wires) instead of wire [AWIDTH-1:0] waddr (a 4-bit vector), and sized memory depth with $clog2(AWIDTH) instead of 1<<AWIDTH. Lesson: bracket placement decides vector vs array — width goes before the name; and address width vs memory depth are different quantities (AWIDTH addresses 2^AWIDTH slots).

## 5. Timing & Constraints (XDC)

The async crossing is intentionally not timed by static timing analysis (STA),
because wclk and rclk are unrelated clocks, metastability on that path is
handled by the 2-flop synchronizer's settling time, not by timing closure.
The constraints tell STA exactly that.

### async_fifo.xdc


- `create_clock` for wclk (10 ns / 100 MHz) and rclk (14 ns / ~71 MHz):
  defines the two clocks so STA knows their periods.
- `set_clock_groups -asynchronous -group {wclk} -group {rclk}`:
  declares the two domains unrelated, so STA does NOT analyze any path
  crossing between them (which would otherwise report false violations).
- (Alternative/complementary) `set_false_path` on the synchronizer's first
  flop targets the crossing specifically; set_clock_groups is broader and
  sufficient here-IMP - A CDC path must be marked as a false/async path so STA doesn't try to close timing on it, the crossing is made safe by the synchronizer's    settling time, not by meeting setup/hold. Without the constraint, the tool reports false violations on a path that is async by design.

### Synthesis result (Artix-7 xc7a35t)

  <img width="417" height="397" alt="image" src="https://github.com/user-attachments/assets/547509a1-2939-415d-bd62-9b70215e8daa" />
   <img width="697" height="341" alt="image" src="https://github.com/user-attachments/assets/9c44cfcb-59c6-44e0-8713-0a596ea72255" />

- Synthesis: 0 errors, 0 warnings.
- Utilization: 30 flip-flops (all async-reset + clock-enable, FDCE),
  16x8 buffer inferred as distributed RAM (no Block RAM needed at this depth),
  ~24 LUTs, 2 global clock buffers (one per clock) confirming the dual-clock
  design. <0.2% device utilization.

### Timing closure
<img width="1273" height="317" alt="image" src="https://github.com/user-attachments/assets/13649e52-274b-4563-99f9-77bc9fb7418e" />
<img width="1607" height="372" alt="image" src="https://github.com/user-attachments/assets/01512eb1-1e58-4585-9449-0c134e1325b6" />


- All timing constraints met. Setup WNS = +6.5 ns, Hold WHS = +0.036 ns,
  0 failing endpoints across 90.
- Inter-clock paths between wclk and rclk: none analyzed — correctly excluded
  by set_clock_groups, which is the expected result for an intentional CDC
  crossing.

## 6. Self-Checking Verification (Scoreboard)

Both FIFOs are verified with self-checking testbenches, not waveform inspection. The core is a reference model: a SystemVerilog queue (logic [W-1:0] model[$]) that mirrors what the FIFO should contain. On every accepted write the data is pushed to the queue; on every accepted read the queue is popped to get the EXPECTED value, which is compared against the DUT output. Mismatches are counted and a PASS/FAIL banner is printed at the end.

Key features that address real DV concerns:
- Reference model (queue) + scoreboard → automatic checking, no eyeballing.
- Constrained-random, UNGATED wr_en/rd_en → the FIFO is deliberately driven into write-while-full and read-while-empty, proving the DUT correctly ignores them. Coverage counters report how many times each corner was exercised.
- PASS/FAIL banner + error count → result is readable from the log.
- $dumpfile/$dumpvars → waveform is reproducible by anyone cloning the repo.

Driving on negedge: stimulus is driven and DUT outputs are sampled on the negedge, because the DUT updates its outputs on the posedge. Reading on the opposite edge avoids sampling signals while they are mid-change (a TB/DUT race), so full/empty/dout are always read when stable.

Registered vs combinational read in the TB: the sync TB defers its compare by one cycle (saving the expected value and checking dout the next cycle) because the sync FIFO read is registered. The async TB compares immediately, because the async read is combinational (rdata valid the same cycle).

### Sync FIFO result
Over ~2000 randomized cycles: 988 writes, 975 reads, 0 mismatches.
Corners exercised: write-while-full = 31, read-while-empty = 32. RESULT: PASS.

### Async FIFO result (both rate directions)
A WR_SLOW parameter flips which clock is faster, so both directions are tested:
- Writer faster than reader → FIFO fills, wfull repeatedly asserted (back-pressure throttles the writer to the reader's rate).
- Reader faster than writer → FIFO starves, rempty repeatedly asserted.
Both runs: 0 mismatches, FIFO ordering preserved across the clock crossing.

### Debugging note — scoreboard off-by-one
The sync scoreboard initially failed with a CONSISTENT "got = expected + 1" on every read. The constant offset (not random) pointed to a testbench timing skew, not a FIFO bug: the model captured din, but because din was incremented every cycle and the DUT samples din on the posedge, the DUT latched a din one higher than the value pushed to the model. Fixed by incrementing din first, pushing that exact value, and only advancing din on accepted writes — aligning the reference value with what the DUT actually stores. Lesson: a systematic offset in a scoreboard is almost always a drive/sample alignment issue in the TB; read the SHAPE of the failure before digging in.

