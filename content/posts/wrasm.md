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

- _TODO (editorial): why owning a byte-exact encoder (and emitting `.exe`s
  directly) mattered — and how the AArch64-portable design set up MRASM._

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

> _Grounded facts:_ "the core (source → `.exe`) is complete and byte-identical to
> LLVM-MC"; the authoring layer is in and unit-tested. Committed working demo
> `.exe`s at the repo root (`brickout_fx.exe`, `overscan.exe`, `palettefx.exe`,
> `parallax.exe`) and a `release/WRASM-studio-*` bundle. _Fill specifics from the
> repo._

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

- _TODO (editorial): writing a PE by hand; the value of a frozen golden corpus as
  the correctness contract._

## Links

- Source: https://github.com/albanread/WRASM
- Extracted from: [JASM](/posts/jasm)
- macOS arm64 port: [MRASM](/posts/mrasm)
- Shares its render core with: [WF66](/posts/wf66)
