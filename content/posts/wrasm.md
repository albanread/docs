+++
title = "WRASM — a from-scratch x86-64 assembler, source text to a running .exe"
date = 2026-06-19
description = "JASM's native encoder, grown up: a self-contained Windows x86-64 assembler with no LLVM, no JIT and no external linker — source in, a complete PE .exe out — byte-identical to LLVM-MC, wrapped in a Direct2D knowledge IDE. The Windows original that MRASM ports to arm64."
[taxonomies]
tags = ["assembler", "x86-64", "rust", "windows", "pe", "ide"]
[extra]
repo = "https://github.com/albanread/WRASM"
language = "Rust (native x86-64 encoder; LLVM-MC as a build-time oracle)"
platform = "x86-64 Windows (emits PE .exe / COFF .obj)"
status = "Working — source→.exe complete, byte-identical to LLVM-MC"
period = "2026-06 → 2026-07"
downloads = []
+++

_The point where the project stopped renting encoding from LLVM: a standalone
x86-64 assembler that writes a complete Windows `.exe` directly — its own imports,
no linker — and proves every byte against LLVM-MC._

## TL;DR

- **What:** a from-scratch, self-contained **x86-64 assembler for Windows**. "No
  LLVM, no JIT, no external linker: source text goes in, a running `.exe` comes
  out."
- **Correctness:** the encoder is **byte-identical to LLVM-MC**, validated against
  it as a differential oracle across integer, SSE/SSE2, AVX/AVX2 (VEX) and AVX-512
  (EVEX). A frozen corpus of **5,109 goldens** gates every build — with no LLVM
  present at test time.
- **More than an assembler:** a **`winkb`** knowledge layer (~165,000 Win32 symbols)
  and a Direct2D "studio" IDE.
- **Lineage:** WRASM **is** JASM's native encoder, extracted (first commit: "rasm:
  standalone x86-64 encoder (extracted from JASM)"). Its macOS arm64 port is
  [MRASM](/posts/mrasm).
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/WRASM)

## Where it sits

The assembler line runs MASM32-era ergonomics → [JASM](/posts/jasm) (JIT, x86-64
Windows) → **WRASM** (AOT, `.exe`-out) → [MRASM](/posts/mrasm) (the macOS arm64
port). WRASM shares its Direct2D render core (`docpane`) with the
[WF66](/posts/wf66) line. _(On disk the repository directory is `RASM`; the project,
git remote and IDE are all "WRASM".)_ See the [timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch, self-contained x86-64 assembler for Windows"
> that emits Windows **PE `.exe`** and COFF `.obj` with its own import directory and
> thunks — no `link.exe`. Two-pass encoder with branch relaxation. **No JIT, no LLVM
> at runtime**; LLVM-MC is used only at build time as the differential oracle.

## Why I built it

An assembler is the one tool in the chain with no right to be approximate:
either it emits the bytes the manual specifies or it does not. For a long
time this portfolio *rented* that certainty from LLVM-MC. WRASM is the point
where renting stopped — and the only honest way to stop is the way it does:
prove the native encoder **byte-identical** to the oracle across thousands
of cases, then remove the oracle from the build. "It passes our tests" is a
claim; "it emits the same bytes as LLVM-MC across 5,109 goldens, and LLVM is
no longer installed" is a measurement.

Writing the `.exe` directly was the same instinct applied to the other end
of the pipeline. A linker is not magic — it is a file format and some
bookkeeping — but as long as `link.exe` sat at the end of the chain, the
chain had a black box in it. Source text to a running program with every
byte accounted for: that was the goal, and it is a deeply satisfying thing
to have. The encoder was also designed portable from the start — encoding
tables and emission separated from x86-64 specifics — which is why
[MRASM](/posts/mrasm), the AArch64 macOS version, was a port rather than a
second project.

## How it works

- **Encoder → PE:** source → two-pass encode + relaxation → COFF `.obj` **and** a
  complete PE `.exe` (self-written import directory/thunks). No external linker.
- **Differential oracle:** every build is gated against a frozen 5,109-instruction
  golden corpus proving byte-identity with LLVM-MC (integer, SSE, VEX, EVEX).
- **`winkb` knowledge layer:** ~165,000 Win32 symbols (functions + parameter types,
  constants, enums, struct byte-offsets, COM IIDs/vtable slots) over
  `windows_api.db`.
- **Transparent macros:** `invoke` (Win64 ABI marshalling, incl. float → `xmm`),
  `comobj`/`comcall`/`iid` (COM), `struct` instances, `sizeof(T)`, `.include` — all
  lowering to instructions you can see.
- **Checked procedures:** `proc … endproc` with `uses`/`in`/`out`/optional `frame`
  and caller-side clobber / in-out / stack-alignment checks.
- **Studio IDE:** a Windows-only Direct2D/DirectWrite editor (via the shared
  `docpane` render core) with a single `!Sync` "language thread," live checks,
  ghost-byte seam, caret cards, autocomplete, scriptable via embedded TCL.

## What works today

The core — source in, `.exe` out — is complete and byte-identical to
LLVM-MC; the authoring layer (macros, checked procedures, `winkb`) is in
and unit-tested. The proof is committed to the repo root as running
programs: `brickout_fx.exe`, `overscan.exe`, `palettefx.exe` and
`parallax.exe` are demo games and effects assembled entirely by WRASM, and
a `release/WRASM-studio-*` bundle carries the IDE. An assembler whose test
artifacts you can play is an assembler that is telling the truth.

## Screenshots

The **studio** IDE — source on the right, the **assembled bytes shown beside each
line** (`48 83 ec 40` ↔ `mov`), syntax highlighting, and the live Windows-API
knowledge panel (`winkb`) resolving names to their DLLs. (Captured by the IDE
itself, headless, via `studio --script`.)

![WRASM studio: source, the assembled bytes beside it, and the Windows-API knowledge panel](/images/wrasm/studio-ide.png)

The go-to-label palette (`Ctrl+G`) — jump across a program's 368 labels as you type:

![WRASM studio's go-to-label palette](/images/wrasm/studio-labels.png)

WRASM assembles the demos and games these shots come from — several are captured in
[little pixel-art games are a serious compiler test](/posts/games-for-compiler-testing).

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/WRASM/releases).

```bash
git clone https://github.com/albanread/WRASM
cd WRASM
cargo build --release
```

## Notes, dead-ends, lessons

- **A PE file is a format, not a mystery.** Writing the import directory and
  thunks by hand demystifies the last step of the toolchain permanently —
  and once the emitter owns the whole file, features linkers make awkward
  (deterministic layout, byte-exact diffs between builds) come free. The
  two-pass encode with branch relaxation is the only genuinely fiddly part,
  and it is fiddly once.
- **A frozen golden corpus is a correctness *contract*, not a test suite.**
  The 5,109 goldens were generated against LLVM-MC and then frozen — so the
  gate runs with no LLVM present, forever, and any encoder change that
  alters one byte of one instruction fails loudly. Test suites drift with
  the code they test; a frozen corpus can't. This is the single practice
  from the Windows years that every later project kept.
- The studio IDE captures its own screenshots headless (`studio --script`,
  driven by the embedded TCL) — the same agent-first pattern the
  [Snapdragon series](/posts/smalltalk-on-a-snapdragon) later leans on. Test
  rigs that can drive the product turn out to be the gift that keeps giving.

## Links

- Source: https://github.com/albanread/WRASM
- Extracted from: [JASM](/posts/jasm)
- macOS arm64 port: [MRASM](/posts/mrasm)
- Shares its render core with: [WF66](/posts/wf66)
