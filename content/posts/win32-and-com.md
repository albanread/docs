+++
title = "Windows was already an operating system: Win32 and COM"
date = 2026-07-31
description = "The Mac projects had to build a bridge to an object model. The Windows-era languages had it both easier and stranger: Windows was already a complete OS — Win32 by name from metadata, COM as the component ABI, structured exceptions, and a message-pump concurrency model — so the job wasn't to build a platform but to speak its protocols."
[taxonomies]
tags = ["windows", "win32", "com", "ffi", "seh", "direct2d", "async", "metadata"]
+++

_The [Cocoa essay](/posts/cocoa-bridge) was about a bridge — how a language joins
the Objective-C object model. This is its mirror image. On Windows there was
nothing to join, because the whole operating system was already there: a GUI, a
graphics and audio stack, structured exceptions, an async concurrency model, and
a component ABI with machine-readable metadata for every last function. The
Windows-era languages didn't build a platform. They learned to speak one._

## TL;DR

- **Win32 is just DLLs and exported names**, reached by `LoadLibraryW` /
  `GetProcAddress` — and the entire surface is *machine-readable* in Microsoft's
  `Windows.Win32.winmd`, so [JASM](/posts/jasm) generates the whole API by name.
- **COM is the component ABI** — vtables, `IUnknown`, GUIDs, `HRESULT` — and the
  deepest engagement makes it part of the *type system*: in
  [MacModula2](/posts/macmodula2) a type test compiles to `QueryInterface`.
- **The OS hands you concurrency**: [NCL](/posts/newcl) adopts the Win32
  message-pump-plus-worker-thread model wholesale rather than inventing a runtime.
- **Structured exceptions are a service you hook** — a VEH crash dumper, and the
  Win64 unwind ABI you can negotiate with or opt out of.
- Porting to the Mac later revealed how much of this was *free*: every piece had
  to be rebuilt or re-targeted.

## Win32 by name, from metadata

The Windows API is, mechanically, a pile of DLLs exporting C functions. You reach
any of them the same way — load the DLL, resolve the symbol — and that's exactly
what the runtime does. From [JASM](/posts/jasm):

> "Runtime helper that pairs `Assembler::externs()` with real Win32 function
> addresses via `LoadLibraryW` / `GetProcAddress`, and registers each mapping with
> the JIT." — JASM `src/win32.rs`

An `@extern "user32.dll" MessageBoxW(4)` line becomes a live function pointer at
JIT time (the DLL cached across externs, kept loaded for the process because
"JIT'd code may hold pointers indefinitely"). The clever part isn't the loading —
it's that you never have to *write* those `@extern` lines. Microsoft ships
**`Windows.Win32.winmd`**, a complete machine-readable description of the entire
Win32 *and* COM surface — every function, struct, interface, GUID, and calling
convention — and JASM's `win32_gen.py` projects the whole API from it.

That should sound familiar: it is precisely the trick [cocoa_data](/posts/cocoa-data)
plays for the Objective-C surface — a metadata mirror the compiler queries instead
of hand-writing bindings. The difference is that on Windows **Microsoft ships the
mirror.** [NCL](/posts/newcl) leans on the same idea from the Lisp side —
"metadata-backed `win32` / `defwin32` helpers" loading a `windows_api.pack`.

## COM: the component ABI, taught to the type system

Win32's flat C functions are the easy half. The interesting half is **COM** — the
Component Object Model — because COM is how Windows exposes *objects*: vtable-based
interfaces, reference-counted through `IUnknown` (`QueryInterface` / `AddRef` /
`Release`), identified by 16-byte GUIDs, returning `HRESULT`s. A language that
wants to drive modern Windows has to speak it.

The deepest version of that doesn't wrap COM — it makes COM a first-class citizen
of the language's own type system. [MacModula2](/posts/macmodula2) (carrying its
Windows predecessor's "machine-checked COM") maps the Oberon-family type test onto
`QueryInterface` directly:

> "An interface selector discriminates by `QueryInterface`, not native RTTI …
> two runtime helpers calling the `IUnknown` vtable (`…query_interface` slot 0,
> `…release` slot 2)." — MacModula2 `guard-ismember.md`

So `GUARD x: ISomeInterface` compiles to a `QueryInterface` probe: the IID is
validated at the interface declaration, the guard binds the `AddRef`'d pointer as
a read-only reference, and the compiler emits the `Release` on the scope's
fall-through edge. `ISMEMBER(v, IFoo)` is a non-binding QI-then-`Release` probe.
COM's "is-a" question (`QueryInterface`) *becomes* the language's is-a operator,
and COM's lifetime rules become the compiler's job. This is the exact analogue of
the Cocoa side's "a class *is* an Objective-C object" — here, **a COM interface
*is* a language type.**

And it isn't abstract: the whole Windows GUI stack the family shares — the `iGui`
shell built on **Direct2D, DirectWrite, and Direct3D 11** — is COM. Driving the UI
*is* driving COM objects, which is why re-homing `iGui` to the Mac meant
re-targeting those COM interfaces onto Cocoa / Metal / Core Text (the seam the
[arm64-vs-x64](/posts/arm64-vs-x64) port story runs through).

## The OS hands you a concurrency model

This is the part the framing is really about: **Windows is a full OS, async and
all**, and a language can adopt its concurrency model instead of building one. The
Windows GUI world is single-threaded-apartment with a message pump, and
[NCL](/posts/newcl) takes it exactly as given. Under `--windows`:

> "thread 0 becomes the Win32 UI thread … thread 0 runs the Win32 message pump; a
> worker thread named `ncl-lisp-worker` runs the Lisp session." — NCL `WINDOWS_FFI.md`

Thread 0 also spins up a hidden `HWND_MESSAGE` dispatcher window — a
message-only window that serves as the cross-thread mailbox — and the language
marshals work onto the UI thread with `(%ui-execute closure)`, wrapped in macros
by `win32-threading.lisp`. That is the canonical Win32 concurrency pattern
(message pump + a message window + worker threads + `PostMessage` hand-off), and
underneath it sits the rest of the OS's async machinery — overlapped I/O,
completion ports, APCs, thread pools — available without a runtime of your own.

The shape is identical to the Mac side's "AppKit is main-thread-only, hop every UI
send onto it" doorway — because it's the same problem, and both operating systems
already solved it. The language's job is to route through the OS's answer, not to
reinvent one.

## Structured exceptions: the OS as a debugger you can hook

Windows also ships a formal fault-handling ABI, and [JASM](/posts/jasm) plugs
straight into it — a process-wide **Vectored Exception Handler**:

> "Installs a process-wide Vectored Exception Handler (VEH) that runs first for
> any exception — access violations, illegal instructions, divide-by-zero, AND
> `int 3` breakpoints." — JASM `src/seh.rs`

Two details show how much OS is really there. First, Windows has a *structured
unwind* contract — `.pdata` / `.xdata` tables registered via `RtlAddFunctionTable`,
walked by `RtlLookupFunctionEntry` → `UNWIND_INFO` — and JASM's subroutine-threaded
Forth deliberately **opts out** of it, because "the Win64 unwind contract cannot be
satisfied" when `RSP` is the Forth return stack; it does a Forth-aware stack dump
instead. You have to know the OS's exception ABI intimately just to decline it
correctly. Second, it turns the mechanism into a *tool*: a breakpoint
(`STATUS_BREAKPOINT`) is decoded specially, the handler dumps state, steps `RIP`
past the `0xCC`, and returns `EXCEPTION_CONTINUE_EXECUTION` — so `int 3` becomes a
"dump and keep going" inspector. The OS's exception dispatch, repurposed as a
debugger.

## The tell: how much was free

The cleanest proof that Windows *was* the platform is what happened when these
languages moved to Apple Silicon — every service they'd taken for granted became
work:

| On Windows (given) | On the Mac (had to build/retarget) |
|---|---|
| `Windows.Win32.winmd` metadata (Microsoft ships it) | [cocoa_data](/posts/cocoa-data) — mirror the Obj-C surface yourself |
| COM graphics: Direct2D / DirectWrite / D3D11 | Cocoa / Core Text / Metal |
| Win32 message pump + `HWND_MESSAGE` mailbox | `NSApplication` run loop + main-thread `dispatch_sync` |
| SEH / VEH structured exceptions | Mach exceptions, `NSException`, hand-rolled dumps |
| `LoadLibraryW` / `GetProcAddress` | `dlopen` / `dlsym` |

Nothing here is a knock on either OS — it's the point. Two mature operating
systems each hand a language a complete platform; the language's real work is to
speak the local protocols fluently.

## The through-line

Half the reason a language a week was possible wasn't the compiler at all — it was
that **Windows had already built the operating system.** The GUI existed, the
graphics and audio stacks existed, the async model existed, the exception
machinery existed, and — uniquely — the *entire API was described in metadata you
could compile against by name.* So the Windows-era languages spent their effort
where it mattered: reaching Win32 from `winmd`, teaching the type system to speak
COM, adopting the message pump, and hooking the exception dispatch. Where the Mac
bridge is about *joining an object model*, the Windows story is about *plugging
into a finished OS* — and discovering, only on the way out to Apple Silicon, just
how much of it had been quietly holding the whole thing up.

## Related

- [The role of Cocoa and the bridge](/posts/cocoa-bridge) — the mirror image on Apple Silicon
- [JASM](/posts/jasm) — Win32 by name from winmd; the VEH crash dumper
- [NCL](/posts/newcl) — the metadata-backed Win32 surface and the message-pump model
- [MacModula2](/posts/macmodula2) — machine-checked COM: a type test *is* `QueryInterface`
- [cocoa_data](/posts/cocoa-data) — the Mac's answer to a metadata surface Microsoft ships for free
