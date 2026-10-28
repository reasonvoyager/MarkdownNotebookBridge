# MarkdownNotebookBridge v0.1.2 — Unicode clipboard patch (release candidate)

Author: Andre Elan · GitHub: @reasonvoyager · Licence: MIT

## Fix

Preserves Japanese and other non-ASCII text copied through the Windows clipboard. The PowerShell reader transports Base64-encoded UTF-8 bytes, which Wolfram Language decodes explicitly. This avoids the encoding conversion that corrupted Japanese headings and Grid tables in v0.1.1.

The notebook Markdown parser, heading hierarchy, table renderer and public API are unchanged.

## Evidence and verification

An independent user identified Japanese corruption in v0.1.1. The original clipboard method failed the Unicode round trip, whereas Base64/UTF-8 passed. Parser-only rendering and a temporary end-to-end override of the clipboard reader also passed in Mathematica 15.0.1 on Windows.

**Release-candidate status:** The changed repository source and ten tests still require execution against the new source and the built v0.1.2 paclet. Do not publish before these checks pass.

## Acceptance checks

1. Run TestReport on Tests/ImporterTests.wlt: expect 10/10.
2. Build MarkdownNotebookBridge-0.1.2.paclet using PacletBuild.
3. In a fresh kernel install that precise archive and verify PacletFind reports version 0.1.2.
4. Run BridgeMarkdown[] with Japanese Markdown containing a pipe table; then test the existing English, mathematics and heading-grouping examples.
5. Publish the exact tested archive as the v0.1.2 release asset and independently install the public download.

Other operating systems and Mathematica versions remain unverified. v0.1.1 remains available unchanged.
