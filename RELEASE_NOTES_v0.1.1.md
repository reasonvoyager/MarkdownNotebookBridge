# MarkdownNotebookBridge v0.1.1 — first public beta

**Author:** Andre Elan · **GitHub:** @reasonvoyager · **Licence:** MIT

The release introduces the concise `BridgeMarkdown[]` signature command while retaining `InsertMarkdownFromClipboard[]` for backwards compatibility.

This package imports Markdown from ChatGPT or other platforms as independently grouped `"Text"` cells into existing Mathematica notebooks, preserving native notebook Chapter/Section styles and numbering. It handles supported TeX expressions, separate numbered lists, non-evaluatable fenced code and mathematical Markdown tables via formatted `Grid` output.

**Verification:** 7/7 Wolfram Language regression tests passed on Mathematica 15.0.1 (Windows). The v0.1.1 `.paclet` was built, installed in the standard Wolfram paclet repository, and successfully exercised in a fresh notebook and an existing customised notebook.

**Known limitations:** Windows PowerShell clipboard dependency; some light themes display non-evaluatable Code cells with poor contrast; advanced Markdown and LaTeX cases are not fully supported. See README for details.

**Release asset:** Attach the **exact locally built and tested** `MarkdownNotebookBridge-0.1.1.paclet` as a GitHub release asset. The source ZIP in this preparation folder does not contain that binary.
