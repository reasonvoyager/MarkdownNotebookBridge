# MarkdownNotebookBridge v0.1.2 — Unicode clipboard compatibility

**Author:** Andre Elan · **GitHub:** @reasonvoyager · **Licence:** MIT

## Fixed

Windows clipboard import now preserves Japanese and other Unicode text by transferring Base64-encoded UTF-8 bytes from PowerShell and decoding them explicitly in Wolfram Language.

This resolves a bug reported by an independent Wolfram Community user: v0.1.1 displayed corrupted Japanese headings and Markdown table cells when using `BridgeMarkdown[]`.

**The existing Markdown parser, notebook heading grouping, mathematical table renderer and public commands are unchanged.**

## Verification

Tested with **Mathematica 15.0.1 on Windows** on 28 October 2026:

- All **10/10 Wolfram Language regression tests** passed (seven original tests plus three additional Unicode tests).
- Built the versioned `MarkdownNotebookBridge-0.1.2.paclet` archive successfully.
- Installed the built archive into Mathematica's standard paclet repository.
- Verified the installed version `0.1.2` and the UTF-8/Base64 clipboard reader in a fresh kernel.
- End-to-end `BridgeMarkdown[]` tests passed for Japanese headings and tables, and for the existing English-language mathematical workflow.

The original 0.1.1 release remains available unchanged. Support on other operating systems and Mathematica versions remains unverified.

## Installation

Once the release asset is published, download `MarkdownNotebookBridge-0.1.2.paclet` from the v0.1.2 GitHub release and install it in Mathematica using `PacletInstall`.

This release changes only clipboard Unicode transport and associated tests; see the README for the usage walkthrough and the established limitations.
