# MarkdownNotebookBridge

**Import Markdown as independently grouped research notes inside an existing Mathematica notebook.**

**Author:** Andre Elan · **GitHub:** [@reasonvoyager](https://github.com/reasonvoyager) · **Licence:** MIT · **Version:** 0.1.1 (initial public beta)

Tested with **Mathematica 15.0.1 on Windows**, including light and Dracula-themed notebooks, source-package and installed-paclet tests, and seven Wolfram Language regression tests (7/7 passed after correcting one test assertion). Other Wolfram Language versions and operating systems have not yet been verified.

## Why this exists

Markdown is an effective exchange format for ChatGPT and many other AI or research platforms. Mathematica notebooks are an excellent place to explore, calculate and retain research. But ordinary copy-and-paste into a Text cell leaves Markdown markers, TeX delimiters, code fences and tables to be repaired manually.

**MarkdownNotebookBridge** converts clipboard Markdown into *editable notebook cells at the current point of work*. Crucially, its Markdown headings become **collapsible, nested `"Text"` cells**, not new native `"Chapter"`, `"Section"` or `"Subsection"` cells. This keeps the notebook's existing section organisation and customised numbering separate from imported notes.

It builds on Wolfram's built-in `ImportString[..., {"Markdown", "Notebook"}]` rather than attempting to replace a full Markdown parser.

## One-command use

Once installed:

```wolfram
Needs["MarkdownNotebookBridge`"];

(* Copy the Markdown source to the Windows clipboard, then evaluate: *)
BridgeMarkdown[]
```

Evaluate this in an **Input** cell of your destination notebook. The imported cells are inserted directly after that cell, respecting their Markdown order and creating expandable heading groups.

![Nested text-cell headings, maths and tables in a Mathematica notebook](docs/images/nested-notes-light.png)

*Real Mathematica front-end output from an earlier manual acceptance test. The public demonstration file uses a separate, neutral scientific example.*

## Capabilities

| Markdown input | Imported notebook content |
|---|---|
| Headings `#` ... `######` | Bold, hierarchical **Text** cells; collapsible cell groups |
| Ordinary paragraphs, `**bold**`, `*italic*` | Readable Text cells with preserved emphasis |
| `\(...\)` and `\[...\]` | Typeset inline and display mathematics |
| Pipe tables, including inline TeX | Formatted **Grid** cells (not narrow native Tabular displays) |
| Numbered lists | Grouped list cells; separate lists restart at 1 |
| Fenced code blocks | **Code** cells with `Evaluatable -> False` |
| Markdown hyperlinks | Delegated to Wolfram's native Markdown importer; link behaviour may depend on the front end |

The importer currently recognises the six standard Markdown heading levels. Internally, the style mapping also includes a seventh heading specification, but seventh-level Markdown recognition is not guaranteed by the native parser.

### Heading appearance

| Markdown level | Approximate Mathematica equivalent | Font size |
|---|---|---:|
| `#` | Title | 24 pt |
| `##` | Chapter | 22 pt |
| `###` | Section | 20 pt |
| `####` | Subsection | 18 pt |
| `#####` | Subsubsection | 16 pt |
| `######` | Subsubsubsection | 14 pt |

**These are all rendered as `"Text"` cells**, not the native heading styles listed for comparison.

## Install

### Recommended: prebuilt paclet from GitHub Releases

After the first release is published, download `MarkdownNotebookBridge-0.1.1.paclet` from its GitHub release assets, then run:

```wolfram
PacletInstall[File["C:\\path\\to\\MarkdownNotebookBridge-0.1.1.paclet"]];
Needs["MarkdownNotebookBridge`"];
BridgeMarkdown[]
```

**Note:** The separate `.paclet` file is built using Wolfram's `PacletBuild`. A source ZIP is **not** interchangeable with the `.paclet` archive. The public binary release asset must be supplied from a Wolfram-built archive; it is not embedded in this source repository.

### Use or build from source

Clone or download the repository, then point `pacletRoot` to the directory containing `PacletInfo.wl`:

```wolfram
pacletRoot = "C:\\path\\to\\MarkdownNotebookBridge";
PacletDirectoryLoad[pacletRoot];
Needs["MarkdownNotebookBridge`"];
```

To build a distributable archive:

```wolfram
Needs["PacletTools`"];
buildResult = PacletBuild[pacletRoot];
pacletArchive = buildResult["PacletArchive"];
```

Run the tests before publishing any locally built archive:

```wolfram
TestReport[
  FileNameJoin[{pacletRoot, "Tests", "ImporterTests.wlt"}]
]
```

## Public API

```wolfram
BridgeMarkdown[]                      (* Primary clipboard command *)
InsertMarkdownFromClipboard[]        (* Backwards-compatible alias *)
MarkdownToNotebookCells[markdown]    (* String -> list of Cell expressions *)
RenderMarkdownTable[tableMarkdown]   (* String -> formatted Grid *)
RenderMarkdownTableFromClipboard[]   (* Clipboard table -> Grid *)
```

Both clipboard insertion commands accept the option `"HeadingMode" -> "Text"` (the default). The string conversion and table rendering functions can be used independently of the Windows clipboard.

## Try the self-demonstrating sample

`Examples/SampleMarkdown.md` explains why this package exists *while exercising its features*. It includes long paragraphs, formatted emphasis, labelled links, nested headings, complex TeX and **two mathematical Markdown tables plus one heading-level reference table**, separate numbered lists and a fenced Wolfram Language code example.

Read and render it without modifying any notebook:

```wolfram
sample = Import[
  FileNameJoin[{pacletRoot, "Examples", "SampleMarkdown.md"}],
  "Text"
];
NotebookPut[
  Notebook[
    MarkdownToNotebookCells[sample],
    CellGrouping -> Automatic
  ]
]
```

For the actual clipboard workflow, copy the *raw Markdown source* from the file and evaluate `BridgeMarkdown[]` in a notebook Input cell.

## Compatibility, known limitations and safety

- **Tested environment:** Windows, Mathematica 15.0.1. Clipboard reading currently calls PowerShell `Get-Clipboard -Raw`.
- Affected notebook themes may show **poor contrast in `"Code"` cells with `Evaluatable -> False`**, especially light themes. This is a front-end style issue observed in manual testing, not a failure of the Markdown parser. The option is retained deliberately so reference code is non-evaluatable by default but can be enabled through **Cell → Cell Properties → Evaluatable**.
- Markdown tables currently expect ordinary pipe separators. Complex escaped pipes, nested tables, and advanced TeX environments may not be handled correctly.
- Inline mathematical rendering is based on supported TeX conventions and the existing specialised Grid renderer, not a complete LaTeX implementation.
- The package is intended for **trusted Markdown inputs**. Review unfamiliar content before importing it into a computational notebook.
- The reverse Mathematica-to-Markdown exporter is **not part of this project**; it is a possible separate future tool.

## Repository contents

- `Kernel/MarkdownNotebookBridge.wl`: the consolidated v6 import and table-rendering implementation, with public wrappers.
- `PacletInfo.wl`: paclet metadata.
- `Tests/ImporterTests.wlt`: seven kernel regression tests.
- `Examples/SampleMarkdown.md`: expanded manual demonstration and acceptance test.
- `docs/images/`: authentic, cropped Mathematica screenshots from manual tests.
- `CHANGELOG.md`, `LICENSE`, `BuildPaclet.wl`: release history, MIT licence and build helper.

## Author, feedback and licence

**Andre Elan** · [ReasonVoyager on GitHub](https://github.com/reasonvoyager)

Copyright © 2026 Andre Elan. Distributed under the [MIT licence](LICENSE).

Please submit issues and improvement suggestions through GitHub Issues after the repository is published. Contributions are welcome, particularly platform testing, front-end theme fixes and Markdown edge cases.

## Wolfram reference

- [Markdown import format](https://reference.wolfram.com/language/ref/format/Markdown.html)
- [Creating paclets](https://reference.wolfram.com/language/PacletTools/tutorial/CreatingPaclets.html)
- [CellGroupingRules](https://reference.wolfram.com/language/ref/CellGroupingRules.html)
- [CounterAssignments](https://reference.wolfram.com/language/ref/CounterAssignments.html)
