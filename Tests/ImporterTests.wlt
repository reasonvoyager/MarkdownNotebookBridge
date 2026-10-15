(* Kernel-level smoke/regression tests; Mathematica 15.0+ is required.
   The graphical appearance and link clickability require manual inspection. *)

Needs["MarkdownNotebookBridge`"];

VerificationTest[
  MatchQ[
    RenderMarkdownTable[
      "| Heading | Equation |\n|---|---|\n| **A** | \\(x^2\\) |"
    ],
    _Grid
  ],
  True,
  TestID -> "Simple Markdown table becomes Grid"
]

VerificationTest[
  MatchQ[
    MarkdownToNotebookCells["# Heading\n\nA **bold** paragraph."],
    {__Cell}
  ],
  True,
  TestID -> "Markdown becomes notebook cells"
]

VerificationTest[
  Count[
    MarkdownToNotebookCells["# First\n\n## Second\n\nText."],
    Cell[_, "Text", ___],
    {1}
  ] >= 2,
  True,
  TestID -> "Nested headings become Text cells"
]

VerificationTest[
  Count[
    MarkdownToNotebookCells[
      "# Code sample\n\n```wolfram\nClearAll[f];\nf[x_] := x^2;\n```"
    ],
    Cell[_, "Code", ___],
    {1}
  ] >= 1,
  True,
  TestID -> "Fenced code becomes Code cell"
]

VerificationTest[
  MatchQ[
    MarkdownToNotebookCells[
      "# A table\n\n| Quantity | Value |\n|---|---|\n| Mean | \\(\\mu\\) |"
    ],
    {__Cell}
  ],
  True,
  TestID -> "Document import includes table"
]

VerificationTest[
  Length[
    DownValues[MarkdownNotebookBridge`BridgeMarkdown]
  ] > 0,
  True,
  TestID -> "BridgeMarkdown exported as public command"
]

VerificationTest[
  Options[BridgeMarkdown] === Options[InsertMarkdownFromClipboard],
  True,
  TestID -> "Legacy insertion alias retains BridgeMarkdown options"
]
