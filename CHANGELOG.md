# Changelog

## 0.1.2 — Unicode clipboard patch (release candidate)

- Preserve Unicode clipboard content using Base64-encoded UTF-8 from Windows PowerShell into the Wolfram kernel.
- Fix Japanese text corruption reported by an independent Wolfram Community tester; existing Markdown rendering algorithms are unchanged.
- Add Japanese heading, Japanese table and mixed-script regression tests (ten tests in total).
- Final regression run, compiled paclet verification and GitHub release publication are pending.


## 0.1.1 — initial public beta (2026-10-15)

- Introduced `BridgeMarkdown[]` as the primary Markdown-clipboard command.
- Preserved `InsertMarkdownFromClipboard[]` as a backwards-compatible alias.
- Adopted the MIT licence with Andre Elan as copyright holder.
- Corrected the public-command regression test to verify the function has definitions, not just its displayed name.
- Added public release documentation and a self-demonstrating Markdown sample.
- **No changes to the tested Markdown rendering algorithms.**
- Seven automated tests passed and the v0.1.1 paclet was installed and functionally tested in Mathematica 15.0.1 on Windows.

## 0.1.0 — previous working baseline

- Consolidated the three original Wolfram Language definition blocks into a paclet.
- Five automated tests passed and an installed-paclet workflow was confirmed in a fresh kernel.
