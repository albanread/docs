+++
title = "The role of the interpreter"
date = 2026-07-31
description = "FasterBASIC was an interpreter, and no matter what I did it never earned the name. The story of giving up on interpreter speed — QBE with a JIT mode and hand-added NEON, then the surprise that LLVM does the optimizing for you — and the lesson it left: an interpreter's job is not to be fast. It's to be small and get out of the way. Which is why MACVM's interpreter is 31 bytecodes."
[taxonomies]
tags = ["interpreter", "jit", "basic", "qbe", "llvm", "performance", "vm"]
+++

_I named a language FasterBASIC and then spent months failing to make the name
true. Everything I learned about what an interpreter is *for* came out of that
failure — and the punchline is that the best thing I ever did for interpreter
performance was stop working on it._

## TL;DR

- FasterBASIC started as an interpreter. However hard I optimized it, it never
  earned the "Faster."
- The puzzle that nagged me: a tiny interpreter should fit in cache and fly — yet
  a *great* interpreter loses to a *simple* compiler. It does, and here's why.
- Giving [QBE](/posts/qbejit) a JIT mode (a ChakraCore-derived assembler + a
  `MAP_JIT` loader) plus hand-added **NEON** opcodes made it *orders of magnitude*
  faster than the interpreter I'd polished for months.
- Then [LLVM](/posts/llvm-in-these-compilers) turned out not to be scary, and did
  the front-end optimization *for* me.
- Lesson: optimizing an interpreter is mostly a waste of time (unless you're Object
  Arts). So [MACVM](/posts/macvm)'s interpreter is **31 bytecodes**, and the JIT
  does the rest.

## The name was a rebuke

FasterBASIC was an interpreter first, and I threw everything I knew at it. Tight
dispatch, a compact bytecode, the usual tricks to keep the hot loop small. It got
faster. It never got *fast*. The name I'd chosen sat there as a standing rebuke —
"faster than what, exactly?" — and no amount of micro-tuning closed the gap to
code that had simply been compiled.

## The puzzle I couldn't shake

What bothered me wasn't that the interpreter was slow. It was that it *shouldn't
have been*, by the reasoning I trusted. A good interpreter is small. Its whole
dispatch loop lives in L1. The working set is a few kilobytes. Modern
out-of-order cores ought to eat that alive — no I-cache misses, everything
resident, a tight loop the branch predictor sees a million times. By that logic a
lean interpreter should approach compiled speed. Mine didn't, and neither does
anyone's, and it took me too long to see why.

The smallness is real, but it optimizes the wrong cost. An interpreter is a
program that runs a program, and the interpretive layer — fetch the bytecode,
decode it, take an indirect branch to its handler — is pure overhead that the
hardware *cannot see through*. That dispatch branch is data-dependent on the
bytecode stream, so it mispredicts; and worse, the CPU's real superpowers —
out-of-order execution, register renaming, the branch predictor learning *your
program's* shape — are aimed at the wrong target. They're optimizing the
*interpreter's* control flow, not your program's. Your actual loop, your actual
arithmetic, is hidden behind a `switch`. Fitting the interpreter in cache makes
the interpreter fast; it does nothing about the fact that you're executing five to
ten instructions of overhead per instruction of real work.

That's the thing I finally understood: **you cannot optimize your way out of a
category.** Interpretation *is* the overhead. A compiler doesn't make it cheaper —
it removes it, and hands your real program straight to the silicon that was built
to run it. Which is why even a dumb compiler beats a clever interpreter.

## So I stopped, and compiled

[QBE](https://c9x.me/compile/) is a small optimizing backend that takes an IR and
emits assembly. To turn that into a JIT I needed to assemble to memory, so I
ported an ARM64 assembler out of **ChakraCore** — Microsoft's since-deprecated
JavaScript engine, which happened to have the cleanest, most exact
executable-memory code I could find — and paired it with a `MAP_JIT` loader for
Apple Silicon's W^X rules ([QBEJIT](/posts/qbejit)). Now QBE's output ran without
ever touching disk.

Then I did the part that actually mattered for a *BASIC*: I extended QBE itself.
BASIC lives on arrays, so I added custom **NEON** opcodes straight into QBE's IR —
`neonldr`/`neonstr`, interleaved `ld2`/`st2` loads, `neonadd`/`neonmul`, a
reduction — so "the frontend can emit vectorized loops directly," as the design
note puts it. Suddenly array code compiled to real SIMD.

The interpreter I'd tuned for months was beaten *immediately*, and not by a
little — by orders of magnitude. Months of interpreter craft, erased by the most
straightforward possible compile.

## And then LLVM, which I'd been afraid of

I had avoided LLVM for years on the assumption that it was horribly complicated.
Working on FasterBASIC finally pushed me to try it, and the real surprise wasn't
that it was manageable — it was how *little I had to do*. I could emit naive,
obvious IR — no clever front-end analysis, no hand-rolled strength reduction, none
of the optimization I'd sweated over on the interpreter — and LLVM just... handled
it. Inlining, register allocation, vectorization, constant folding: all of it,
for free, from IR a first-year could emit. The front-end cleverness I thought was
the job turned out to be [LLVM](/posts/llvm-in-these-compilers)'s job, and it was
better at it than I would ever be.

## The lesson

Put the two discoveries together and the conclusion is blunt: **spending a lot of
time making an interpreter fast is a waste of time.** Not because interpreters
don't matter — because the compiler is going to beat your best interpreter anyway,
and reaching a compiler is *easier* than you think (QBE is small; LLVM does the
hard part). Every hour I spent on dispatch tricks was an hour stolen from the
thing that would actually win.

There's exactly one honorable exception, and I want to name it: the people for
whom the interpreter *is* the craft. **Object Arts**, with Dolphin Smalltalk,
spent decades on a threaded interpreter and genuinely made it sing — that is a
real, hard-won art, and if interpreter performance is your entire specialty, ignore
me. For the rest of us, it's a tar pit with a compiler sitting right next to it.

## What the interpreter is actually for

So I inverted the instinct. An interpreter's role is **not** to be fast. Its role
is to be the *smallest correct thing* that can run your program until something
better takes over — and then to get out of the way.

That belief is baked into [MACVM](/posts/macvm). Its interpreter is deliberately
tiny — "**31 opcodes, one instruction stream, no self-modifying bytecode**," as the
ISA doc says — and I put *zero* effort into making it quick. It exists to do two
things: run any method correctly, and get hot code to the JIT as fast as possible.
All the performance work went into the [real adaptive JIT](/posts/two-jits) — tiers,
type feedback, deoptimization, on-stack replacement — because that's where the
speed actually lives. The interpreter is tier-0: a small, honest fallback, not a
place to be clever.

## The through-line

I spent months trying to make an interpreter fast and learned that the fastest
thing I could do to it was replace it. The interpreter's smallness — the very
property that should have made it quick — was optimizing a cost that doesn't
dominate, while the interpretive overhead I couldn't remove is a *category*, not a
constant. A compiler deletes the category. QBE showed me that with a JIT mode and
a few NEON opcodes; LLVM showed me the optimizer was never mine to write. So now I
build the smallest interpreter that can possibly work — thirty-one bytecodes — and
spend my life on the JIT instead. The role of the interpreter is to be correct, to
be small, and to hand the hard work to something that was built for it. Unless
you're Object Arts, that's the whole job.

## Screenshots

> _Add to `static/images/role-of-the-interpreter/`: the FasterBASIC interpreter vs
> QBE-JIT vs LLVM benchmark bars; QBE's NEON opcode table; MACVM's 31-opcode ISA
> listing; a dispatch-loop disassembly next to the compiled equivalent._

![Three bars: a polished interpreter, a simple QBE JIT, LLVM — each an order of magnitude apart.](/images/role-of-the-interpreter/01.png)

## Related

- [Two things called JIT](/posts/two-jits) — why a minimal interpreter + a real JIT beats a great interpreter
- [The role of LLVM](/posts/llvm-in-these-compilers) — the optimizer I didn't have to write
- [QBEJIT](/posts/qbejit) — QBE with a JIT mode and NEON, the ChakraCore-derived loader
- [MACVM](/posts/macvm) — the 31-bytecode interpreter that trusts the JIT
- [The shared substrate](/posts/shared-substrate) — how reuse (QBE, LLVM) made all of this cheap to reach
