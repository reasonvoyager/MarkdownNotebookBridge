# Testing MarkdownNotebookBridge

Load the unpacked paclet in a fresh Mathematica 15.0+ kernel:

```wolfram
pacletRoot = "C:\\path\\to\\MarkdownNotebookBridge";
PacletDirectoryLoad[pacletRoot];
Needs["MarkdownNotebookBridge`"];

TestReport[FileNameJoin[{pacletRoot, "Tests", "ImporterTests.wlt"}]]
```

Next import `Examples/SampleMarkdown.md` to a fresh notebook and visually check
heading nesting, bold/italic prose, mathematical equations, all three tables (two mathematical, one heading-level reference), list
counter resets, and non-evaluatable code blocks. Additionally test whether the
three labelled Wolfram documentation hyperlinks are clickable. Hyperlink support
has not yet been independently confirmed by the front-end test.

For version 0.1.1, test `BridgeMarkdown[]` and `InsertMarkdownFromClipboard[]`
independently after a fresh-kernel load, confirming identical rendered cells.
