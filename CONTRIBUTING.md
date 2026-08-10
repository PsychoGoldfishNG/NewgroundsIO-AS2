# Contributing / Maintainer Guide

This document is for people **working on** the NewgroundsIO-AS2 library.
If you just want to *use* the library in a game, you want the [README](README.md) instead.

---

## Contents

- [What lives where](#what-lives-where)
- [Prerequisites](#prerequisites)
- [The release pipeline](#the-release-pipeline)
- [Step 1 — Regenerate the model classes](#step-1--regenerate-the-model-classes)
- [Step 2 — Rebuild the compiled class library](#step-2--rebuild-the-compiled-class-library)
- [Step 3 — Re-import the component into components.fla](#step-3--re-import-the-component-into-componentsfla)
- [Step 4 — Commit, tag, release](#step-4--commit-tag-release)
- [Verification checklist](#verification-checklist)

---

## What lives where

| Path | What it is | Edited by |
|---|---|---|
| `build/` | Generated model classes + hand-written core classes | `npm run build` (models), by hand (core) |
| `src/modelgen/` | Generator config + helpers | by hand |
| `src/templates/` | EJS templates the generator renders | by hand |
| `src/library/NgioClassLib.fla` | Wrapper FLA that produces the drag-and-drop component | Flash |
| `bin/components.fla` | **The release artifact.** All user-facing components | Flash |
| `docs/` | Images used by the README | — |

`build/` mixes generated and hand-written code:

```
build/NGIO.as                  hand-written
build/io/newgrounds/*.as       hand-written (Core, AppState, Errors, SessionStatus, Base*)
build/io/newgrounds/helpers/   hand-written
build/io/newgrounds/encoders/  hand-written
build/io/newgrounds/models/    GENERATED - do not hand-edit, it gets overwritten
```

---

## Prerequisites

### ⚠️ Flash version: committed `.fla` files must be in **Flash 8** format

What matters is the format of the file you commit, not which IDE you type in.

**Use Flash 8, or any later version still capable of saving down to Flash 8 format** — CS3 can do
this, for example. If you're on a version above Flash 8, the workflow is:

1. Open and edit normally
2. Before committing, **File ▸ Save As** and choose **Flash 8 Document** as the file type
3. Commit that Flash 8-format file

> **Never commit a `.fla` saved in a newer format.**
>
> Save As reaches back only a limited number of versions, and Flash 8 is far enough back that most
> modern releases cannot reach it at all. The intermediate versions you'd need to walk a file back
> down are increasingly hard to obtain, with several no longer running reliably on current Windows.
>
> Before assuming your version works, check that **Flash 8 Document** actually appears in its Save
> As type list. If it doesn't, use an older IDE — don't save the file.
>
> This applies to both `src/library/NgioClassLib.fla` and `bin/components.fla`.

| Requirement | Version |
|---|---|
| Committed `.fla` format | **Flash 8** |
| Authoring IDE | **Flash 8**, or any later version that can save down to Flash 8 (e.g. CS3) |
| Model generator | **Node.js 20+** |

Note that a committed `.fla` is an opaque binary as far as Git is concerned — every change lands as
a blob with no reviewable diff. That makes the [verification checklist](#verification-checklist)
worth actually running; a mistake here cannot be caught in review.

> Sister project note: the AS3 library targets **Flash CS5** instead. Keep the two toolchains
> straight if you work on both.

---

## The release pipeline

```
  1. npm run build          regenerates build/io/newgrounds/models/
             |
  2. NgioClassLib.fla       recompile the class library into NgioClassLibCompiled   [MANUAL, Flash 8]
             |
  3. components.fla         re-import the updated NgioLibraryComponent              [MANUAL, Flash 8]
             |
  4. commit + tag v*        GitHub Action attaches bin/components.fla to the release
```

> ### ⚠️ The CI build does not rebuild the compiled clip
>
> The release workflow runs `npm run build`, which regenerates `build/`. It **cannot** touch the
> compiled clip inside `components.fla` — that requires Flash.
>
> So if you change the core library and tag a release **without doing steps 2 and 3 by hand**, the
> published `components.fla` ships a *stale* compiled class library, even though the repo's
> `build/` folder looks correct. Users installing via the Connector or Library component get the
> old code; only users copying source files get the new code.
>
> **Any change under `build/` means you must redo steps 2 and 3 before tagging.**

---

## Step 1 — Regenerate the model classes

Only needed if the Newgrounds.io API schema changed, or you edited anything in `src/templates/`
or `src/modelgen/`.

```bash
npm install      # first time only
npm run build
```

This downloads the latest `objects_and_components.json` and rewrites
`build/io/newgrounds/models/`. Review the diff before continuing — a schema change can add or
remove whole component classes.

If you only hand-edited core classes (`Core.as`, `AppState.as`, a helper, etc.), skip to Step 2.

---

## Step 2 — Rebuild the compiled class library

**File:** `src/library/NgioClassLib.fla`
**Why:** this FLA's classpath points at `../../build`, so opening and recompiling it is what pulls
your updated classes into a distributable form.

### How it's put together

The stage contains one clip, **`NgioLibraryComponent`**, which hides itself on frame 1. It has two
layers:

| Layer | Contents | Purpose |
|---|---|---|
| `banner` (top) | A graphical banner | What the developer sees when they drag the component onto their stage |
| `class library` (bottom) | The `NgioClassLibCompiled` clip | Every class in `build/`, pre-compiled |

Pre-compiling is what lets novice users skip importing classes entirely, and saves advanced users
from long republish times.

### The procedure

1. Open `src/library/NgioClassLib.fla` in Flash 8.

2. **Clear out the old compiled clip.** Two places — both are required:

   a. On the stage, enter the `NgioLibraryComponent` clip, select the **`class library`** layer,
      and delete the `NgioClassLibCompiled` instance sitting on it.

   b. In the Library panel, go to `Newgrounds.IO ▸ assets ▸ library` and delete the
      **`NgioClassLibCompiled`** symbol.

   > Leaving either one behind means you'll recompile but keep shipping the old code.

3. **Recompile.** Still in the Library panel at `Newgrounds.IO ▸ assets ▸ library`, right-click
   **`NgioClassLib`** (the *uncompiled* symbol — note the name has no `Compiled` suffix) and choose
   **Convert to Compiled Clip**.

   This is the step that actually reads `../../build` and bakes the classes in.

4. **Rename** the newly created compiled symbol to exactly **`NgioClassLibCompiled`**.

   The name matters — Step 3 and the components FLA depend on it.

5. **Place it.** Drag a copy of `NgioClassLibCompiled` from the Library onto the
   **`class library`** layer inside the `NgioLibraryComponent` clip — the same layer you emptied
   in 2a.

6. **Save** `NgioClassLib.fla` and stage it for commit.

---

## Step 3 — Re-import the component into components.fla

The updated `NgioLibraryComponent` now has to be carried across into the release artifact.

1. Open `bin/components.fla` in Flash 8.

2. **Clear out the old symbols.** Two places in the Library panel — both are required:

   a. Delete **`NgioLibraryComponent`** (it sits at the top level of the library, not inside a
      folder).

   b. Go to `Newgrounds.IO ▸ assets ▸ library` and delete **`NgioClassLibCompiled`**.

   > Same library path as in `NgioClassLib.fla`.

3. Switch back to `NgioClassLib.fla`, select **`NgioLibraryComponent`** on the root stage, and
   copy it.

4. Switch to `components.fla` and paste **anywhere** — the stage, any frame. Pasting is what
   imports the symbol (and its nested compiled clip) into the library.

   **If Flash asks whether to replace or duplicate existing library items, choose "Replace".**
   Duplicating leaves the stale symbols behind under `Copy of …` names and the component will keep
   using the old code.

   > **The symbol will land at the library root — that's expected, leave it there.**
   > Flash 8 drops the source library path on paste, so `NgioLibraryComponent` arrives at the top
   > level rather than in a folder. That's the natural paste behaviour and it's the preferred
   > outcome here: the AS2 audience skews toward newer developers, so having the component front
   > and centre makes it easier to find. **Don't file it into a folder.**
   >
   > (The AS3 project differs for the same reason — CS5 *preserves* the path on paste, so its copy
   > stays under `Newgrounds.IO ▸ library`. Also left as-is.)

5. Now **delete the pasted instance from the stage.** The symbol stays in the library, which is
   all we need; `components.fla`'s stage should end up unchanged.

6. **Save** `components.fla` and stage it for commit.

---

## Step 4 — Commit, tag, release

```bash
git add src/library/NgioClassLib.fla bin/components.fla
git add build/                              # if Step 1 regenerated anything
git commit -m "Rebuild compiled class library"
git push

git tag v1.0.1                              # your new version
git push origin v1.0.1
```

Pushing a `v*` tag triggers `.github/workflows/release.yml`, which installs dependencies, runs
`npm run build`, and attaches **`bin/components.fla`** to the GitHub release.

---

## Verification checklist

Before tagging:

- [ ] `build/io/newgrounds/models/` reflects the current schema (if Step 1 was run)
- [ ] `Newgrounds.IO ▸ assets ▸ library` in `NgioClassLib.fla` contains exactly one
      `NgioClassLibCompiled`, and it was created *after* your latest `build/` change
- [ ] The `class library` layer inside `NgioLibraryComponent` has the compiled clip on it
- [ ] `components.fla`'s library **root** has exactly one `NgioLibraryComponent`
- [ ] `components.fla`'s `Newgrounds.IO ▸ assets ▸ library` has exactly one `NgioClassLibCompiled`
- [ ] No `Copy of …` symbols anywhere in `components.fla`'s library (means "Duplicate" was picked
      instead of "Replace")
- [ ] `components.fla`'s **stage is empty** — no leftover pasted instance
- [ ] Both FLAs saved in **Flash 8** format — if you authored in a later IDE, you did the
      **Save As ▸ Flash 8 Document** step before staging
- [ ] Both FLAs saved and staged

A quick smoke test: publish `components.fla`, drag the Library component into a scratch FLA, and
confirm a class you just changed behaves as expected.

---

## Related

- Model generator: [ngio-object-model-generator](https://github.com/PsychoGoldfishNG/ngio-object-model-generator)
- Cross-platform design spec: [ngio-developer-guide](https://github.com/PsychoGoldfishNG/ngio-developer-guide)
