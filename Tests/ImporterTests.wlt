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

(* Regression coverage for Unicode without non-ASCII source-file characters. *)
(* TestReport may read .wlt files using a Windows system encoding. *)

VerificationTest[
  Module[{heading, paragraph, cells},
    heading = FromCharacterCode[{19990, 30028, 12398, 20154, 21475, 19978, 20301, 51, 12459, 22269}];
    paragraph = FromCharacterCode[{26085, 26412, 35486, 12398, 12486, 12473, 12488, 12391, 12377, 12290}];
    cells = MarkdownToNotebookCells[
      "# " <> heading <> "\n\n" <> paragraph
    ];
    MatchQ[cells, {__Cell}] &&
      ! FreeQ[cells, s_String /; StringContainsQ[s, heading]] &&
      ! FreeQ[cells, s_String /; StringContainsQ[s, paragraph]]
  ],
  True,
  TestID -> "Japanese heading and paragraph retained"
]

VerificationTest[
  Module[{rank, country, india, china, markdown, table},
    rank = FromCharacterCode[{38918, 20301}];
    country = FromCharacterCode[{22269, 21517}];
    india = FromCharacterCode[{12452, 12531, 12489}];
    china = FromCharacterCode[{20013, 22269}];
    markdown = StringRiffle[
      {
        "| " <> rank <> " | " <> country <> " |",
        "|---|---|",
        "| 1 | " <> india <> " |",
        "| 2 | " <> china <> " |"
      },
      "\n"
    ];
    table = RenderMarkdownTable[markdown];
    MatchQ[table, _Grid] &&
      ! FreeQ[table, india] &&
      ! FreeQ[table, china]
  ],
  True,
  TestID -> "Japanese and Chinese characters retained in Grid"
]

VerificationTest[
  Module[{russian, greek, chinese, cells},
    russian = FromCharacterCode[{1056, 1091, 1089, 1089, 1082, 1080, 1081}];
    greek = FromCharacterCode[{917, 955, 955, 951, 957, 953, 954, 940}];
    chinese = FromCharacterCode[{20013, 25991}];
    cells = MarkdownToNotebookCells[
      "# Multilingual notes\n\n" <>
        russian <> " text. " <> greek <> ". " <> chinese <> "."
    ];
    MatchQ[cells, {__Cell}] &&
      AllTrue[
        {russian, greek, chinese},
        Function[token,
          ! FreeQ[cells, s_String /; StringContainsQ[s, token]]
        ]
      ]
  ],
  True,
  TestID -> "Multilingual non-Latin text retained"
]
