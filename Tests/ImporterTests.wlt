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

(* Regression coverage for non-Latin text and mathematical tables. *)

VerificationTest[
  Module[{cells},
    cells = MarkdownToNotebookCells[
      "# 世界の人口上位3カ国\n\n日本語のテストです。"
    ];
    MatchQ[cells, {__Cell}] &&
      ! FreeQ[
        cells,
        s_String /; StringContainsQ[s, "世界の人口上位3カ国"]
      ] &&
      ! FreeQ[
        cells,
        s_String /; StringContainsQ[s, "日本語のテスト"]
      ]
  ],
  True,
  TestID -> "Japanese heading and paragraph retained"
]

VerificationTest[
  Module[{table},
    table = RenderMarkdownTable[
      "| 順位 | 国名 |\n|---|---|\n| 1 | インド |\n| 2 | 中国 |"
    ];
    MatchQ[table, _Grid] &&
      ! FreeQ[table, "インド"] &&
      ! FreeQ[table, "中国"]
  ],
  True,
  TestID -> "Japanese and Chinese characters retained in Grid"
]

VerificationTest[
  Module[{cells},
    cells = MarkdownToNotebookCells[
      "# Multilingual notes\n\nРусский текст. Ελληνικά. 中文。"
    ];
    MatchQ[cells, {__Cell}] &&
      AllTrue[
        {"Русский", "Ελληνικά", "中文"},
        Function[token,
          ! FreeQ[cells, s_String /; StringContainsQ[s, token]]
        ]
      ]
  ],
  True,
  TestID -> "Multilingual non-Latin text retained"
]
