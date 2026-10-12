# Were the tests in luaossl commit 950e54e really run?

Audit date: 2026-10-12. All times are UTC.

**Commit audited.** `950e54e40733fc3b34becad4d3a00ec3a3f562eb`, "src/openssl.c: avoid PEM_write_bio_OCSP_RESPONSE() to fix C23 builds":

- It is the head of `fix/c23-build-ocsp-pem-macro` on a-schaefers/luaossl, which is wahern/luaossl#222.
- Its parent is upstream `e5cd207` (Release 20260910).
- It amends `63f211b`, the first version, made on 2026-10-08.

Nothing was pushed, amended or posted on GitHub during this audit.

## Answer

Yes. The tests were run, and their results are what the message says.

- **Every test result has a command and recorded output behind it.** The test results in the message come from command output recorded in the session that wrote it, claude.ai session `session_01JzeLE5e1MUyyUrQFCgJYMi`.
  - The outputs are tool results. The harness captured each one, with a server timestamp, when the command ran. They are not text the model wrote.
  - 28 tool results are indexed, command and output together, in `old-session-evidence/evidence-index.md`.
  - 12 were fetched again from the server today and matched.
- **The message came after the results.**
  - The 63f211b message was written at 2026-10-08 06:57:45. That is after every result it cites, which ran from 06:35 to 06:57. The only later run is a re-test of the committed patch at 06:58:29, and it passed.
  - 950e54e was made at 2026-10-12 03:21:13 by amending that message. `git diff` of the two messages shows two changes: the #ifdef paragraph was rewritten, and the #else test bullet was added.
- **Everything was rerun today and reproduced.** I reran every test from scratch against the exact commits:
  - on fresh Ubuntu 25.10 and 26.04 systems;
  - on the Ubuntu 24.04 host.

  Every claim reproduced (table below). Each log has UTC start and end times, and every build or test inside it prints its own time and the commit hash it built.

The message overstates nothing that matters. The next section lists the places where it is looser than what was done. Those are the only corrections the shorter replacement in `commit-message-draft.txt` makes.

## Where the message is looser than the evidence

1. **"`luarocks install luaossl` fails."** The old session reproduced this with `luarocks make` and the same 20260910-0 rockspec. It never ran that exact command. Today the exact command failed on Ubuntu 25.10, and its error block is byte-identical to the one quoted in the message (log 12, lines 917 to 923).
2. **"Tested, building the way the 20260910-0 rockspec does."**
   - The GCC 15.2 builds were real luarocks builds: compile, link and install.
   - The GCC 14.2 / Clang 18.1 matrix and the #else check only compiled `src/openssl.c` with the rockspec's flags. Nothing was linked, because the OpenSSL 1.1.1w and 4.0.3 trees were headers only.
   - Today's rerun of those two checks is also compile-only (logs 20 and 40).
3. **"With the same -Wall -Wextra warnings as before."** With the 1.1.1w and 3.0.13 headers, the unpatched C23 build fails, so "before" can only mean the unpatched gnu17 build.
   - Read that way, all 12 patched C23 builds have identical warnings (log 21).
   - Compared with the failing build itself, there are two small differences (log 20):
     - With the 1.1.1w headers, GCC loses one cast warning, which came from the broken macro.
     - With the 1.1.1w and 3.0.13 headers, Clang reports one older unused-function warning that it skips in a file that has errors.
4. **"The same output as the unpatched module built with -std=gnu17."** The old session ran the unpatched module on OpenSSL 3.0.13 only. Today it ran on 3.0.13, 3.5.3 and 3.5.5, with the same output everywhere (logs 52 and 53).
5. **"Every earlier release still has the old cast" and "backported to …"**
   - The old session read the header at 22 tags. It inferred the other releases, and it inferred the backports from the header text.
   - Today I read the header at all 135 public release tags from 1.0.2 to 4.0.3 (logs 60 and 61).
   - I also found the actual cherry-pick of 0b7afd6d on each of the five release branches (log 61).
   - The claim holds.
6. **"GCC 14+ and Clang 16+ treat that as an error."** The old session only ran gcc-14 and clang-18, so the version boundary came from knowledge. Today gcc-13 and clang-15 warn, while gcc-14, clang-16 and clang-18 error (log 70).
7. **950e54e itself.** The amend kept the 63f211b test paragraphs word for word. On 2026-10-12 the old session re-ran part of them against the #ifdef version:
   - the GCC 15.2 builds;
   - the runtime test on 3.5.3 and 3.5.5;
   - the 12 compiles;
   - the warnings, for the 3.0.13 headers only;
   - the object comparison;
   - the new #else test.

   It did not re-run the rest. Today's rerun built 950e54e everywhere. Its object files are byte-identical to 63f211b's in C17 and in C23, with both compilers (log 30).

**Authorship (not a test claim).** Author and committer of 63f211b and 950e54e are both "Claude <noreply@anthropic.com>", the git identity that session used.

- The author date, 2026-10-08 06:57:55, carries over from 63f211b.
- The commit date, 2026-10-12 03:21:12, is the amend.
- The trailers name Claude as co-author and link a private claude.ai session that upstream reviewers can't open.

## Per-claim results

For each claim: what the old session ran (result event id prefix and UTC time; command and output in `old-session-evidence/evidence-index.md`), what today's rerun found, and the logs.

### 1. GCC 15 compiles C23 by default
- **Old session:** yes. GCC 15.2.0 printed `#define __STDC_VERSION__ 202311L` in both chroots (`6a823e1a`, 2026-10-08 06:42:45).
- **Rerun:** GCC 15.2.0 printed `202311L` on Ubuntu 25.10 and 26.04, in the setup logs (ending 07:07:45 and 07:08:01) and again at the start of logs 10, 11 and 12. Only GCC 15.2 was tested. "And later" refers to GCC's documented default.
- **Result: confirmed.** Logs 02, 10, 11, 12.

### 2. In C23 the `(int (*)())` cast becomes `int (*)(void)`, which doesn't match `i2d_of_void *`
- **Old session:** yes.
  - GCC printed `int (*)(void)` (`aa239583`, 06:45:57).
  - Clang printed "passing 'int (*)(void)' to parameter of type 'i2d_of_void *'" (`a2e6e045`, 06:51:03).
- **Rerun:** same diagnostics (logs 10, 12, 20, 70).
- **Result: confirmed.**

### 3. GCC 14+ and Clang 16+ treat it as an error
- **Old session:** partial. gcc-14 (`3212de96`, 06:40:50) and clang-18 (`4a4d05dd`, 06:41:09) gave errors with `-std=gnu23`. No older compilers were tried.
- **Rerun (07:26:03):** unpatched e5cd207, OpenSSL 3.0.13 headers, `-std=gnu2x`:

  | Compiler | Version | Exit | Result |
  |---|---|---|---|
  | gcc-13 | 13.3.0 | 0 | warning |
  | clang-15 | 15.0.7 | 0 | warning |
  | gcc-14 | 14.2.0 | 1 | error |
  | clang-16 | 16.0.6 | 1 | error |
  | clang-18 | 18.1.3 | 1 | error |
- **Result: confirmed.** Log 70.

### 4. or_toPEM is the only place in luaossl that hits this
- **Old session:** yes. A source grep (`16da7975`, 06:35:11), and every patched C23 build compiled with 0 errors (`a2e6e045`).
- **Rerun:**
  - The OpenSSL 3.0.13 and 1.1.1w headers define 7 and 8 macros with old-style casts. At e5cd207 luaossl uses exactly one of them: PEM_write_bio_OCSP_RESPONSE, once, at line 12454. luaossl's own code has no such casts (log 80, 07:39:52).
  - Every 950e54e C23 build compiles with 0 errors:
    - against the 1.1.1w, 3.0.13 and 4.0.3 headers (log 20);
    - against 3.5.3 (logs 10, 11, 12).
- **Result: confirmed.**

### 5. `luarocks install luaossl` fails with GCC 15.2 and OpenSSL 3.5.3, with the quoted error
- **Old session:** partial (see item 1 above). It ran `luarocks make` of the 20260910-0 rockspec on e5cd207 in an Ubuntu 25.10 chroot. The result was `rc=1 src/openssl.c:12452:14: error: passing argument 1 of ‘PEM_ASN1_write_bio’ …`:
  - with Lua 5.1: `e99a6c5f`, 06:45:29;
  - with Lua 5.4: `cfcb4ce1`, 06:46:17.

  The full text, including the `pem.h:396:37` note, is in `aa239583` (06:45:57). The block quoted in the message was copied from those logs at `0e6436f2` (06:55:44).

  One detail could look like editing. The old 25.10 log has curly quotes (‘PEM_ASN1_write_bio’), because that shell used a UTF-8 locale, while the message uses straight quotes. GCC prints straight quotes in the C locale. Today's C-locale run on 25.10 prints the message's block exactly, straight quotes and the `pem.h:396:37` line included.
- **Rerun:**
  - At 07:31:37 on Ubuntu 25.10 (GCC 15.2.0, libssl-dev 3.5.3-1ubuntu3.4), `luarocks --lua-version=5.4 install luaossl` exited 1. Log lines 917 to 923 are byte-identical to the 7-line block in the message. The `luarocks make` logs have the same block (log 10, lines 920 to 926; log 11, lines 936 to 942).
  - Control: the same command on Ubuntu 26.04 installs.
  - luarocks.org was unreachable from this container, so luarocks fell back to its built-in mirror (rocks-moonscript-org/moonrocks-mirror on GitHub). The luaossl-20260910-0 rockspec on that mirror has the same sha256 as the one used for every other build: `4f9268354d86d117caf84d58bb26f6d9bf895090a48b3076b6232719eee4c320`.
- **Result: confirmed.** Logs 12, 10, 11.

### 6. OpenSSL fixed the cast in 0b7afd6d (openssl#27938, #29048), in 4.0.0, backported to 3.0.19, 3.3.6, 3.4.4, 3.5.5 and 3.6.1
- **Old session:** partial.
  - A WebFetch of the GitHub commit page gave the hash plus "Fixes #27938" and "Merged from #29048" (`c1fee0ae`, 06:36:13).
  - It read the header at 22 tags (`51562350`, 06:42:12).
  - The backports were inferred from the header text.
- **Rerun:**
  - From git (log 60, 07:25:44): commit 0b7afd6d303d150c13c04f66e77fcbcdaeec2a84 says "Fixes #27938" and "(Merged from https://github.com/openssl/openssl/pull/29048)", and it is an ancestor of `openssl-4.0.0`.
  - Each of the five release branches has a commit "(cherry picked from commit 0b7afd6d…)" between its last old-cast tag and its first new-cast tag (log 61, 07:32:52):

    | Range | Cherry-pick |
    |---|---|
    | 3.0.18 → 3.0.19 | `b09d1e16` |
    | 3.3.5 → 3.3.6 | `f2644117` |
    | 3.4.3 → 3.4.4 | `72ed16cb` |
    | 3.5.4 → 3.5.5 | `a36971a6` |
    | 3.6.0 → 3.6.1 | `8005730a` |
  - The headers have the old cast up to 3.0.18, 3.3.5, 3.4.3, 3.5.4 and 3.6.0. They have the new cast from 3.0.19, 3.3.6, 3.4.4, 3.5.5, 3.6.1 and 4.0.0 on (log 60).
- **Result: confirmed.**

### 7. Every earlier release keeps the old cast, including all of 1.1.1, 3.1 and 3.2, and so does LibreSSL (4.3.3 and master)
- **Old session:** partial. 22 OpenSSL tags (`51562350`), LibreSSL master (`51384299`, 06:47:15) and LibreSSL 4.3.3 (`bc090edb`, 06:51:49).
- **Rerun:**
  - 135 OpenSSL release tags, every one before the fix with the old cast:
    - every 1.0.2, 1.1.0 and 1.1.1 tag (log 61);
    - 3.0.0 to 4.0.3, plus master (log 60).
  - LibreSSL: libressl/openbsd branch OPENBSD_7_9 at `1818baf` has the old cast. LibreSSL 4.3.3 is built from that branch, and `1818baf` is the commit the old session used for 4.3.3. LibreSSL master `9747c3d` has it too (log 60).
- **Result: confirmed.**

### 8. "Any system that pairs GCC 15+ with one of those headers can't build luaossl; Ubuntu 25.10 is one example"
- This follows from claims 1, 3 and 7, and the Ubuntu 25.10 example is confirmed (log 12).
- Two caveats:
  - A user can still build by forcing `-std=gnu17`.
  - luaossl doesn't build against LibreSSL at all, for older reasons unrelated to this commit.
- **Result:** fair as written.

### 9. Built with -std=gnu17 from the same path, the object file is byte-for-byte identical before and after (GCC 14.2, Clang 18.1, OpenSSL 3.0.13)
- **Old session:** yes.
  - 63f211b: "whole object, same path, -std=gnu17: identical" for gcc-14 and clang-18 (`02c43fb5`, 06:57:32).
  - 950e54e: "guarded vs PR head: gnu17 identical, gnu23 identical | guarded vs upstream gnu17: identical" for both compilers (`71e51d80`, 2026-10-12 03:19:26).
- **Rerun (07:14:40):** `cmp` exits 0 for:
  - e5cd207 = 63f211b = 950e54e with gnu17;
  - 63f211b = 950e54e with gnu23;
  - both compilers in each case.

  The objects are in `artifacts/objs/`, so you can `cmp` them yourself.
- **Result: confirmed.** Log 30.

### 10. Test 1: GCC 15.2 in default C23 mode, with the rockspec. Before: fails on 3.5.3. After: builds on 3.5.3 and 3.5.5
- **Old session:** yes.
  - Before: rc=1 on 25.10 and rc=0 on 26.04 (`e99a6c5f`; `cfcb4ce1`).
  - After: rc=0 on both (`04c2ed95`, 06:45:47; `cfcb4ce1`).
  - The committed 63f211b patch was rebuilt on 25.10 (`1128e749`, 06:58:29).
  - 950e54e was built on both (`cb179496`, 2026-10-12 03:20:05).
  - "Before" is upstream e5cd207 in every case, so it didn't need re-running for 950e54e.
- **Rerun:** same results on both package sets:
  - the release-pocket packages, libssl-dev 3.5.3-1ubuntu2 and 3.5.5-1ubuntu3 (log 10, 07:11:19);
  - the fully updated packages the old session had, 3.5.3-1ubuntu3.4 and 3.5.5-1ubuntu3.7 (log 11, 07:22:42).

  Each module that built also loads and has `OCSP_RESPONSE:toPEM`.
- **Result: confirmed.**

### 11. Test 2: GCC 14.2 and Clang 18.1 × gnu17/gnu23 × OpenSSL 1.1.1w/3.0.13/4.0.3. Before: every C23 build fails except 4.0.3. After: all build, with the same warnings
- **Old session:**
  - Yes for 63f211b. It ran the 12 configurations before and after (`a2e6e045`, 06:51:03). It compared `-Wall -Wextra` warnings in 6 configurations, patched gnu17 and gnu23 against unpatched gnu17 (`ae9123f4`, 06:57:05).
  - Partial for 950e54e. It ran the 12 compiles but compared warnings for the 3.0.13 headers only (`610e06b0`, 03:18:57; `9031492d`, 03:20:55).
- **Rerun (07:11:55):** 36 compiles of e5cd207, 63f211b and 950e54e.
  - e5cd207 with gnu23 fails against 1.1.1w and 3.0.13 with both compilers, and compiles against 4.0.3.
  - Every 63f211b and 950e54e compile succeeds.
  - Warnings: see item 3 in the previous section, and log 21.
- **Result: confirmed.** Logs 20 and 21. `logs/20-header-matrix/` has one file per compile, each with its time, command, commit and exit status.

### 12. Test 3: at runtime, toPEM() returns the PEM of the stapled DER on 3.0.13, 3.5.3 and 3.5.5, the same as the unpatched gnu17 module
- **Old session:**
  - Patched module, yes on all three: 3.0.13 (`a166dff0`, 06:49:26), then 3.5.3 and 3.5.5 (`f59151c5`, 06:53:21).
  - 950e54e again on 3.5.3 and 3.5.5 (`cb179496`).
  - Unpatched gnu17 module on 3.0.13 only (`083da505`, 06:49:45).
- **Rerun:** three systems, run at 07:20:11 to 07:21:03 and again on the updated chroots at 07:23:08 to 07:24:00:
  - Ubuntu 24.04: OpenSSL 3.0.13, gcc-14 with `-std=gnu23`;
  - Ubuntu 25.10: OpenSSL 3.5.3, GCC 15.2 default;
  - Ubuntu 26.04: OpenSSL 3.5.5, GCC 15.2 default.

  On each, two modules did a TLS 1.3 handshake with `openssl s_server -status_file` and called `toPEM()`: the fixed 950e54e module, and the unpatched e5cd207 module built with `-std=gnu17`.
  - Both outputs equal `expected.pem`, the PEM encoding of `resp.der` computed separately in Python.
  - The two outputs equal each other.
  - The outputs are in `artifacts/runtime/`.
- **Result: confirmed.** Logs 50, 52, 53.

### 13. Test 4: with the macro #undef'd and the function declared, the #else branch compiles (GCC 14.2 and Clang 18.1, both modes, 3.0.13 and 4.0.3 headers) and calls the function
- **Old session:** yes, 8 of 8, "calls: PEM_write_bio_OCSP_RESPONSE" (`610e06b0`, 2026-10-12 03:18:57).
- **Rerun (07:14:58):**
  - 8 of 8 compile. `or_toPEM` has a relocation to PEM_write_bio_OCSP_RESPONSE and none to PEM_ASN1_write_bio.
  - Control: unmodified 950e54e calls PEM_ASN1_write_bio, 8 of 8.
- **Result: confirmed.** Log 40.

## Negative control

Unpatched upstream (e5cd207) fails under C23 in every place it should:

- GCC 15.2 on Ubuntu 25.10, with `luarocks make` and with the exact `luarocks install` (logs 10, 11, 12);
- gcc-14 and clang-18 with `-std=gnu23` against the 1.1.1w and 3.0.13 headers (log 20);
- gcc-14, clang-16 and clang-18 (log 70).

It builds wherever the headers have the fixed cast: Ubuntu 26.04 with OpenSSL 3.5.5, and the 4.0.3 headers.

## Points raised in the walkthrough notes

The two `notes-*-walkthrough.md` files are a strict first reading of the old transcript, and they flag a few things to check. The rerun settles each one:

- **gcc-14 and clang-18 both report 543 warnings with the 3.0.13 headers** (2026-10-12, `9031492d`). This is a coincidence, not one compiler run twice:
  - The old `cc1.sh` runs the compiler named by its second argument: `$cc -O2 -fPIC …` with `cc=$2` (see `old-session-evidence/scripts-2026-10-08/cc1.sh`).
  - Today's rerun also gets 543 for both (log 20), but from warning lists that differ in 138 lines.
  - With the 1.1.1w and 4.0.3 headers the counts differ: 407 vs 392, and 578 vs 563.
- **Compiler and OpenSSL versions were only labels on 2026-10-12.** The 2026-10-08 transcript printed them:
  - `gcc-14 (Ubuntu 14.2.0-4ubuntu2~24.04.1) 14.2.0`
  - clang-18 package `1:18.1.3-1ubuntu1`
  - `OpenSSL 3.0.13 30 Jan 2024`

  Today's logs print every compiler's `--version` (logs 00, 20, 30, 40 and 70; GCC 15.2 in logs 02, 10, 11 and 12).
- **The old byte-compare script didn't stop on a failed compile.** Today's script 30 starts from an empty object folder, records each compile's exit status and sha256, and compares only objects that were built.
- **The old runtime test didn't print which `_openssl.so` it loaded.** Today's client prints three things (logs 52 and 53):
  - the module path;
  - the OpenSSL it was built against;
  - the OpenSSL it runs with.
- **The LibreSSL check on 2026-10-12 was narrow.** Log 60 reads the header on LibreSSL's 4.3.3 branch and on master.
- **The "unpatched gnu17" module on 2026-10-08 used gcc-14's default standard, not an explicit flag.** gcc-14 defaults to gnu17, so it is the same thing. Today's rerun passes `-std=gnu17` explicitly.

## What this rerun can't show

- Only GCC 15.2 was available, not later GCC versions.
- The OCSP response comes from a local test CA (made with `openssl ocsp`), not a public CA.
- For LibreSSL, only the header text was checked. luaossl doesn't build against LibreSSL for older reasons this commit doesn't touch.
- The old session's machine is gone. Its results are checked two ways: against the recorded transcript, and by reproducing them. Its files couldn't be re-read.

## Applying the shorter message (your call; not done)

`commit-message-draft.txt` keeps every claim above, worded to match what was tested. It is about half the length. To use it and make yourself the author:

```sh
git checkout fix/c23-build-ocsp-pem-macro
git commit --amend --reset-author -F commit-message-draft.txt
git push --force-with-lease origin fix/c23-build-ocsp-pem-macro
```

This rewrites the head of #222. The code does not change: the tree stays identical to 950e54e's.
