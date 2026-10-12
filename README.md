# luaossl C23 fix: verification files

These files check the test claims in commit 950e54e (wahern/luaossl#222). Claude Code made them on 2026-10-12, and all times are UTC. Start with `AUDIT-REPORT.md`. Claim numbers below match that report.

This is the public copy. The last section lists the few files left out of it.

How the files fit together:

- **Times in the logs.** Every log starts and ends with `=== START <time>` and `=== END <time>`. Each build or test inside a log also prints its own time, plus the commit hash or `git archive` source it used.
- **Scripts and logs.** `scripts/NN-*.sh` wrote `logs/NN-*.log`. To rerun anything, run the script with the same number, as root, on Ubuntu 24.04.
- **Checksums.** `SHA256SUMS` has a hash for every file except itself. Check them with `sha256sum -c SHA256SUMS`.

## Top level

| File | What it is |
|---|---|
| AUDIT-REPORT.md | The verdict, then claim by claim: what was claimed, what the old session ran (event and time), what the rerun found, and which logs |
| commit-message-draft.txt | A shorter replacement for the 950e54e message, worded to match what was tested. Not applied |
| README.md | This index |
| SHA256SUMS | sha256 of every file here |

## logs/: today's rerun

| File | Time (UTC) | What it shows |
|---|---|---|
| 00-setup-host.log | 07:04:02 to 07:04:22 | Host packages and versions: Ubuntu 24.04.5, gcc-14 14.2.0, clang-18 18.1.3, OpenSSL 3.0.13, Lua 5.4.6, LuaRocks 3.8.0 |
| 01-fetch-openssl.log | 07:04:13 to 07:04:27 | Clones of OpenSSL tags OpenSSL_1_1_1w and openssl-4.0.3, with their commit hashes |
| 02-setup-chroot-questing.log | 07:06:21 to 07:07:45 | A fresh Ubuntu 25.10 built with debootstrap: GCC 15.2.0 (default `202311L`, i.e. C23), OpenSSL 3.5.3, the macro's old cast in its ocsp.h |
| 02-setup-chroot-resolute.log | 07:06:21 to 07:08:01 | The same for Ubuntu 26.04: GCC 15.2.0, OpenSSL 3.5.5, the new cast |
| 03-openssl-headers.log | 07:06:57 to 07:07:22 | Generates the 1.1.1w and 4.0.3 public headers and shows the macro in them and in the host's 3.0.13 |
| 10-rockspec-gcc15.log | 07:11:19 to 07:11:35 | Claims 5 and 10. `luarocks make` with the 20260910-0 rockspec under GCC 15.2, for e5cd207, 63f211b and 950e54e, on 25.10 and 26.04 (release-pocket packages). Shows the full compiler output and whether each built module loads |
| 11-rockspec-gcc15-updated.log | 07:21:50 to 07:23:00 | The same after updating both chroots to the -updates and -security packages the old session had (libssl-dev 3.5.3-1ubuntu3.4 and 3.5.5-1ubuntu3.7) |
| 12-luarocks-install.log | 07:31:37 to 07:31:50 | Claim 5. The literal `luarocks install luaossl` fails on 25.10, with the message's error block at lines 917 to 923, and installs on 26.04 |
| 20-header-matrix.log | 07:11:55 to 07:13:19 | Claims 4 and 11. 36 compiles (3 commits × gcc-14/clang-18 × gnu17/gnu23 × 1.1.1w/3.0.13/4.0.3), with exit status, error and warning counts, first error, and before/after warning diffs |
| 20-header-matrix/*.txt | 07:11:55 to 07:13:19 | The full compiler output of each of those 36 compiles, named commit-compiler-std-openssl. Each starts with its time, directory, commit and exact command, and ends with its exit status |
| 21-warning-baseline.log | 07:33:53 | Claim 11. Each patched C23 build's warnings compared with the unpatched gnu17 build's: all 12 identical. It reads the files above and compiles nothing |
| 30-byte-identical.log | 07:14:40 to 07:14:58 | Claim 9. The objects for e5cd207, 63f211b and 950e54e from one directory: sha256, size and `cmp` results, plus or_toPEM's call relocations |
| 40-else-branch.log | 07:14:58 to 07:15:40 | Claim 13. 950e54e with the macro replaced by a function declaration: 8 compiles, and which function or_toPEM calls. Includes 8 unmodified control compiles |
| 50-make-ocsp-fixture.log | 07:16:51 to 07:16:52 | The test CA, server certificate and signed OCSP response ("Response verify OK", "server.pem: good"). `expected.pem` is computed from `resp.der` in Python |
| 52-runtime-all.log | 07:20:11 to 07:21:03 | Claim 12, on Ubuntu 24.04 (OpenSSL 3.0.13), 25.10 (3.5.3) and 26.04 (3.5.5). It builds cqueues, the fixed module (C23) and the unpatched module (gnu17), does a TLS 1.3 handshake with `openssl s_server -status_file`, calls toPEM(), and compares the output with expected.pem and between the two modules |
| 53-runtime-all-updated-chroots.log | 07:23:08 to 07:24:00 | The same, on the updated chroots. Made by running script 52 again after script 11 |
| 60-openssl-version-facts.log | 07:24:49 to 07:25:19, then 07:25:44 | Claims 6 and 7. The macro's cast at 77 OpenSSL tags (1.1.1w, 3.0.0 to 4.0.3) and at master, and at LibreSSL's 4.3.3 branch and master. The last section (07:25:44) is commit 0b7afd6d's message and files, and whether it is in 4.0.0 |
| 61-openssl-facts-extra.log | 07:32:52 to 07:33:05 | Claims 6 and 7. Every 1.0.2, 1.1.0 and 1.1.1 tag, and the commit on each release branch that cherry-picked 0b7afd6d |
| 70-compiler-boundary.log | 07:26:03 to 07:26:08 | Claim 3. Unpatched code in C23: gcc-13 and clang-15 warn, while gcc-14, clang-16 and clang-18 error |
| 80-source-scan.log | 07:39:52 to 07:39:53 | Claim 4. Which OpenSSL macros have old-style casts, and which of them luaossl uses at each commit |
| apt-clang15-16.txt | written 07:24:27 (file time) | apt output from installing clang-15 and clang-16 for log 70. It has no times inside. Log 70 prints both versions again |

## scripts/

| File | What it does |
|---|---|
| 00-setup-host.sh | Installs gcc-14, Lua 5.4, LuaRocks and debootstrap on the host and prints versions |
| 01-fetch-openssl.sh | Clones OpenSSL 1.1.1w and 4.0.3 |
| 02-setup-chroot.sh | Builds an Ubuntu chroot with debootstrap (argument `questing` or `resolute`) and installs gcc, libssl-dev, Lua 5.4 and LuaRocks from that release |
| 03-openssl-headers.sh | Generates the 1.1.1w and 4.0.3 headers without building the libraries |
| 10-rockspec-gcc15.sh | Runs `luarocks make` with the rockspec on each commit inside both chroots |
| 11-rockspec-gcc15-updated.sh | Enables -updates and -security in the chroots, upgrades, then reruns script 10 |
| 12-luarocks-install.sh | Runs the literal `luarocks install luaossl` in both chroots |
| 20-header-matrix.sh | Compiles src/openssl.c with the rockspec's patch and flags plus `-Wall -Wextra` for the 36 combinations, then diffs the warnings |
| 21-warning-baseline.sh | Compares patched C23 warnings with unpatched gnu17 warnings, using the script 20 outputs |
| 30-byte-identical.sh | Compiles each commit in the same directory and compares the objects |
| 40-else-branch.sh | Inserts `#undef` plus a function declaration above or_toPEM, compiles, and inspects the call with objdump and nm |
| 50-make-ocsp-fixture.sh | Makes the test PKI and OCSP response with `openssl ocsp` |
| 51-runtime-env.sh | Builds cqueues and both luaossl modules in one system, runs `s_server -status_file`, and runs topem-client.lua against each module |
| 52-runtime-all.sh | Runs script 51 on the host and in both chroots |
| topem-client.lua | The Lua client: connects with cqueues, asks for OCSP stapling, writes `getTLSextStatusOCSPResp():toPEM()` to a file, and prints which modules it loaded |
| 60-openssl-version-facts.sh | Reads ocsp.h at each OpenSSL tag and LibreSSL branch |
| 60b-openssl-commit-0b7afd6d.sh | The one-off command that added log 60's last section, saved word for word |
| 61-openssl-facts-extra.sh | Covers the 1.0.2, 1.1.0 and 1.1.1 tags and finds the cherry-picks |
| 70-compiler-boundary.sh | Compiles unpatched code with gcc-13, gcc-14, clang-15, clang-16 and clang-18 |
| 80-source-scan.sh | Lists the old-style-cast macros in the OpenSSL headers and greps luaossl for them |

## artifacts/

| Path | What it is |
|---|---|
| objs/*.o | The 10 object files compared in log 30, named commit-compiler-std. The unpatched gnu23 builds failed, so they have no object. Run `cmp` on them yourself |
| pki/ | The OCSP fixture from log 50: CA and server certificates, `resp.der` (the stapled response), `expected.pem`, the request, and the CA index |
| rockspecs/ | `luaossl-20260910-0.rockspec` (sha256 4f926835…, the same one the literal `luarocks install` fetched) and the cqueues rockspec used for the runtime test |
| runtime/ubuntu-24.04-host-openssl-3.0.13/, runtime/ubuntu-25.10-openssl-3.5.3/, runtime/ubuntu-26.04-openssl-3.5.5/ | Output of the log 53 runs. `topem-fixed.pem` and `topem-unpatched.pem` are what toPEM() returned. `server-*.log` is s_server's output. `build-*.log` and `cqueues-build.log` are the full luarocks build output. The log 52 runs wrote the same files and were overwritten |

## old-session-evidence/

The session that wrote the commit is claude.ai session `session_01JzeLE5e1MUyyUrQFCgJYMi`. It wrote 63f211b on 2026-10-08 and amended it into 950e54e on 2026-10-12.

| File | What it is |
|---|---|
| evidence-index.md | The 28 tool results the report cites: event id, server time, the exact command, and the output the harness recorded. A script copied them from the raw events. The 12 marked "re-fetched" were fetched from the server again during this audit and matched |
| notes-2026-10-08-walkthrough.md | A step-by-step reading of the 2026-10-08 part of that session, with every relevant command and output and a per-claim table |
| scripts-2026-10-08/ | Helper scripts the old session wrote with heredocs, extracted verbatim from the events: `cc1.sh` for compiles, `chroot-build.sh`, `mkchroot.sh`, `mkpki.sh`, `run-ocsp-test.sh`, `ocsp-topem.lua`, `ossl-fetch.sh` and `libressl-setup.sh`. |
| scripts-2026-10-12/fn-shim.h | The header the old session used on 2026-10-12 to simulate PEM_write_bio_OCSP_RESPONSE() becoming a function |

## Harness fixes before the final logs

Five scripts were fixed and rerun. Each overwrote its earlier log. No test result changed between runs.

- **10:** the first run, at 07:10:33, printed a fixed "ok" for the module-load check. It now prints the module path and the type of toPEM.
- **30:** the first run, at 07:13:54, had a misleading heading. The results were the same.
- **52:** in the first run, at 07:17:48, s_server exited when its stdin closed, before the client connected. The fix was `-www` and `</dev/null`. The second run, at 07:19:04, matched everywhere but printed versions as raw numbers. The third run is the one kept.
- **61:** the first run, at 07:32:22, used the wrong header path for 1.0.2.
- **80:** the first run, at 07:39:35, counted casts that appear in comments.

## Left out of this public copy

- `old-session-evidence/raw-events-*.jsonl`: the full export of the private session that wrote the commit. `evidence-index.md` quotes the 28 tool results the report relies on.
- `old-session-evidence/notes-2026-10-12-walkthrough.md`: it quotes that session's private chat. Item 7 of the report's "Where the message is looser than the evidence", and its "Points raised in the walkthrough notes", sum up what it found.
- `old-session-evidence/scripts-2026-10-08/commit-msg-63f211b.txt`: the first commit message, which commit 63f211b itself carries.
- The test CA's two throwaway private keys from `artifacts/pki/`. Script 50 makes a new set.
- `verification-all.zip`. GitHub's Download ZIP for this branch gives the same files.
