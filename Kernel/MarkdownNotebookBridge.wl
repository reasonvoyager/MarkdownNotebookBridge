(* ::Package:: *)

(* MarkdownNotebookBridge 0.1.2 — packaged version of the
   independently tested notebook-import workflow, v6.          *)

BeginPackage["MarkdownNotebookBridge`"];

BridgeMarkdown::usage =
 "BridgeMarkdown[] inserts Markdown from the Windows clipboard immediately after " <>
 "the evaluating cell as independently grouped notebook Text cells, with mathematical " <>
 "typesetting, numbered lists, non-evaluatable Code examples and formatted Grid tables. " <>
 "Option \"HeadingMode\" defaults to \"Text\".";

InsertMarkdownFromClipboard::usage =
 "InsertMarkdownFromClipboard[] is the backwards-compatible alias for " <>
 "BridgeMarkdown[]. The same options and clipboard-import behaviour are supported.";

MarkdownToNotebookCells::usage =
 "MarkdownToNotebookCells[markdown] converts a Markdown string into a list of " <>
 "formatted Cell expressions without inserting them into a notebook. " <>
 "MarkdownToNotebookCells[markdown, mode] optionally specifies the heading mode.";

RenderMarkdownTable::usage =
 "RenderMarkdownTable[markdownTable] renders a pipe-delimited Markdown table " <>
 "as a Grid, including bold text and supported inline TeX fragments.";

RenderMarkdownTableFromClipboard::usage =
 "RenderMarkdownTableFromClipboard[] renders a Markdown table from the " <>
 "Windows clipboard as a Grid expression.";

Begin["`Private`"];


(* BLOCK 1: Notebook import and clipboard insertion — v6 baseline *)

(* ============================================================ *)
(* 0. This preserves the existing cell contents and style, while instructing Mathematica not to let individual list cells form competing cell groups.                                *)
(* ============================================================ *)
normaliseImportedMarkdownListGroupingFunction[
  cell : Cell[_, style_String, ___]
] /;
 MemberQ[
  {
   "Item",
   "ItemNumbered",
   "Subitem",
   "SubitemNumbered",
   "Subsubitem",
   "SubsubitemNumbered"
  },
  style
 ] :=
 Module[{arguments},

  arguments = List @@ cell;

  Cell @@ Append[
    DeleteCases[
     arguments,
     HoldPattern[CellGroupingRules -> _]
    ],
    CellGroupingRules -> "NormalGrouping"
   ]
 ];

normaliseImportedMarkdownListGroupingFunction[cell_] := cell;

(* ============================================================ *)
(* 1. READ THE WINDOWS CLIPBOARD                                *)
(* ============================================================ *)

readPlainTextFromSystemClipboardFunction[] :=
 Module[{encodedText, clipboardText},

  (* PowerShell 5.1 may output non-ASCII characters in the active console
     encoding. Transport Base64-encoded UTF-8 to avoid information loss. *)

  encodedText =
   Quiet @ Check[
     RunProcess[
      {
       "powershell.exe",
       "-NoProfile",
       "-Command",
       "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Clipboard -Raw)))"
      },
      "StandardOutput"
     ],
     $Failed
    ];

  If[
   ! StringQ[encodedText] ||
    StringTrim[encodedText] === "",
   Return[$Failed]
  ];

  clipboardText =
   Quiet @ Check[
     ByteArrayToString[
      ByteArray[StringTrim[encodedText]],
      "UTF-8"
     ],
     $Failed
    ];

  If[
   ! StringQ[clipboardText] ||
    StringTrim[clipboardText] === "",
   $Failed,
   clipboardText
  ]
 ];


(* ============================================================ *)
(* 2. NORMALISE CHATGPT MATHEMATICAL DELIMITERS                  *)
(*    WITHOUT MODIFYING FENCED CODE BLOCKS                     *)
(* ============================================================ *)




normaliseChatGPTMarkdownForImportFunction[text_String] :=
 Module[
  {
   lines,
   outputLines = {},
   displayMathLines = {},
   inCodeBlock = False,
   inDisplayMath = False,
   displayOpenDelimiter = "",
   trimmed
  },

  (* Normalise line endings *)

  lines =
   StringSplit[
    StringReplace[
     text,
     {"\r\n" -> "\n", "\r" -> "\n"}
    ],
    "\n",
    All
   ];

  Scan[
   Function[line,

    trimmed = StringTrim[line];

    Which[

     (* Preserve fenced code blocks unchanged *)

     StringStartsQ[trimmed, "```"] ||
      StringStartsQ[trimmed, "~~~"],

     If[inDisplayMath,
      AppendTo[outputLines, displayOpenDelimiter];
      outputLines = Join[outputLines, displayMathLines];
      displayMathLines = {};
      inDisplayMath = False;
     ];

     inCodeBlock = ! inCodeBlock;
     AppendTo[outputLines, line],


     inCodeBlock,

     AppendTo[outputLines, line],


     (* Start a display equation *)

     ! inDisplayMath &&
      MemberQ[{"\\[", "$$"}, trimmed],

     inDisplayMath = True;
     displayOpenDelimiter = trimmed;
     displayMathLines = {},


     (* Close the display equation and combine into one line *)

     inDisplayMath &&
      trimmed ===
       If[displayOpenDelimiter === "\\[", "\\]", "$$"],

     AppendTo[
      outputLines,
      "$$" <>
       StringTrim[
        StringRiffle[displayMathLines, " "]
       ] <>
       "$$"
     ];

     displayMathLines = {};
     inDisplayMath = False;
     displayOpenDelimiter = "",


     (* Collect the equation body *)

     inDisplayMath,

     AppendTo[displayMathLines, line],


     (* Ordinary Markdown text and inline mathematics *)

     True,

     AppendTo[
      outputLines,
      StringReplace[
       line,
       {
        "\\(" -> "$",
        "\\)" -> "$",
        "\\[LongDash]" -> "\[LongDash]"
       }
      ]
     ]
    ]
   ],
   lines
  ];

  (* Preserve an incomplete equation rather than lose text *)

  If[inDisplayMath,
   AppendTo[outputLines, displayOpenDelimiter];
   outputLines = Join[outputLines, displayMathLines];
  ];

  StringRiffle[outputLines, "\n"]
 ];


(* ============================================================ *)
(* 3. CONVERT HEADINGS INTO FORMATTED TEXT CELLS                *)
(* ============================================================ *)

chatGPTMarkdownTextifyCellFunction[
   cell : Cell[content_, style_String, ___]
] :=
 Module[
  {headingSpecifications, specification},

  (* Font size and grouping precedence for each heading *)

headingSpecifications = <|
  "Title" -> {24, 90},
  "Chapter" -> {22, 100},
  "Section" -> {20, 110},
  "Subsection" -> {18, 120},
  "Subsubsection" -> {16, 130},
  "Subsubsubsection" -> {14, 140},
  "Subsubsubsubsection" -> {14, 150}
|>;

  Which[

   (* Headings: Text appearance, hierarchical grouping *)

   KeyExistsQ[headingSpecifications, style],

   specification = headingSpecifications[style];

   Cell[
    content,
    "Text",

    FontSize -> specification[[1]],
    FontWeight -> "Bold",

    CellGroupingRules -> {
      "SectionGrouping",
      specification[[2]]
    },

    ShowGroupOpener -> True
   ],

   (* Code blocks *)


	(* ============================================================ *)
	(* A. NATIVE MARKDOWN TABLES                                    *)
	(*    Preserve the imported Tabular representation              *)
	(*    Display inside a non-evaluatable Text cell                *)
	(* ============================================================ *)
	
	MemberQ[
	  {"Input", "Code", "Program", "ExternalLanguage"},
	  style
	] &&
	 MatchQ[
	  content,
	  BoxData[TemplateBox[_, "Tabular", ___]]
	 ],
	
	Cell[
	  content,
	  "Text",
	  ShowCellLabel -> False,
	  CellGroupingRules -> "NormalGrouping"
	],
	
	
	(* ============================================================ *)
	(* B. FENCED CODE BLOCKS                                        *)
	(*    Display as non-evaluatable Code cells                     *)
	(* ============================================================ *)
	
	MemberQ[
	  {"Input", "Code", "Program", "ExternalLanguage"},
	  style
	] &&
	 MatchQ[
	  content,
	  BoxData[_String]
	 ],
	
	Cell[
	  content,
	  "Code",
	  Evaluatable -> False,
	  ShowCellLabel -> False,
	  CellGroupingRules -> "NormalGrouping"
	],
 

   (* Imported output *)

   style === "Output",

   Cell[
    content,
    "Text",
    ShowCellLabel -> False
   ],

   (* Preserve all other imported cells *)

   True,

   cell
  ]
 ];

chatGPTMarkdownTextifyCellFunction[cell_] := cell;

(* ============================================================ *)
(* 4. resetImportedMarkdownNumberedListsFunction
      This function identifies the beginning of each numbered list and resets its counter. Subsequent items retain their existing numbering behaviour.           *)
(* ============================================================ *) 


resetImportedMarkdownNumberedListsFunction[cells_List] :=
 Module[
  {previousStyle = ""},

  Map[
   Function[cell,

    Module[
     {style, arguments, updatedCell = cell},

     style =
      Replace[
       cell,
       {
        Cell[_, s_String, ___] :> s,
        _ -> ""
       }
      ];

     (* Reset only the first item in each numbered list *)

     If[
      style === "ItemNumbered" &&
       previousStyle =!= "ItemNumbered",

      arguments =
       DeleteCases[
        List @@ cell,
        HoldPattern[CounterAssignments -> _]
       ];

      updatedCell =
       Cell @@ Append[
         arguments,
         CounterAssignments -> {{"ItemNumbered", 0}}
        ];
     ];

     previousStyle = style;

     updatedCell
    ]
   ],
   cells
  ]
 ];


(* ============================================================ *)
(* 5. IMPORT MARKDOWN AND EXTRACT NOTEBOOK CELLS                *)
(* ============================================================ *)

chatGPTMarkdownNotebookCellsFunction[
  markdown_String,
  headingMode_ : "Text"
] :=
 Module[
  {normalisedText, importedNotebook, cells},

  normalisedText =
   normaliseChatGPTMarkdownForImportFunction[markdown];

  importedNotebook =
   Quiet @ Check[
     ImportString[
      normalisedText,
      {"Markdown", "Notebook"},
      "ImportImages" -> False
     ],
     $Failed
    ];

  If[
   ! MatchQ[importedNotebook, Notebook[_List, ___]],
   Return[$Failed]
  ];

  (* Flatten notebook cell groups, preserving cell order *)

  cells =
   FixedPoint[
    ReplaceAll[
      #,
      CellGroupData[group_List, ___] :> group
    ] &,
    First[importedNotebook]
   ];

  cells = Flatten[cells];

  cells = Select[
    cells,
    MatchQ[#, _Cell] &
   ];

	If[headingMode === "Text",
	  cells = chatGPTMarkdownTextifyCellFunction /@ cells;
	];
	
(* Allow list items to participate in heading groups *)

cells =
  normaliseImportedMarkdownListGroupingFunction /@ cells;

(* Restart numbered lists *)

cells =
  resetImportedMarkdownNumberedListsFunction[cells];

(* Replace native Tabular objects with our Grid renderer *)

cells =
  replaceImportedMarkdownTablesWithGridsFunction[
    markdown,
    cells
  ];

cells
 ];
 

(* ============================================================ *)
(* 6. ONE-COMMAND CLIPBOARD-TO-NOTEBOOK WORKFLOW                 *)
(* ============================================================ *)




Options[renderOpenAIMarkdownFromClipboardFunction] = {
  "HeadingMode" -> "Text"
};

renderOpenAIMarkdownFromClipboardFunction[
  OptionsPattern[]
] :=
 Module[
  {
   clipboardText,
   cells,
   anchor
  },

  clipboardText =
   readPlainTextFromSystemClipboardFunction[];

  If[
   clipboardText === $Failed,

   Print["No usable plain text was found on the clipboard."];
   Return[$Failed];
  ];

  cells =
   chatGPTMarkdownNotebookCellsFunction[
    clipboardText,
    OptionValue["HeadingMode"]
   ];

  If[
   cells === $Failed || cells === {},

   Print["Markdown import did not produce usable cells."];
   Return[$Failed];
  ];

  anchor = EvaluationCell[];

  If[
   ! MatchQ[anchor, _CellObject],

   Print["Run this function from a notebook Input cell."];
   Return[$Failed];
  ];

  (* Insert bottom-up at the same fixed notebook location.
     The final visual order remains the original Markdown order. *)

  Scan[
   Function[cell,

    NotebookWrite[
     NotebookLocationSpecifier[anchor, "After"],
     cell,
     None
    ]

   ],
   Reverse[cells]
  ];

  Null
 ];

(* ============================================================ *)
(* BLOCK 2: TABLE EXTRACTION AND GRID SUBSTITUTION              *)
(* The following two functions match the validated v6 code.    *)
(* ============================================================ *)

extractOpenAIMarkdownTablesFunction[text_String] :=
 Module[
  {
   lines, n, i = 1, j,
   tables = {},
   fence = "",
   trimmed,
   rowCells,
   headerCells,
   separatorCells
  },

  lines =
   StringSplit[
    StringReplace[
     text,
     {"\r\n" -> "\n", "\r" -> "\n"}
    ],
    "\n",
    All
   ];

  n = Length[lines];

  rowCells[line_String] :=
   StringTrim /@
    StringSplit[
     StringTrim[StringTrim[line], "|"],
     "|"
    ];

  While[i <= n,

   trimmed = StringTrim[lines[[i]]];

   (* Track fenced code blocks *)

   If[
    StringStartsQ[trimmed, "```"] ||
     StringStartsQ[trimmed, "~~~"],

    If[
     fence === "",
     fence = StringTake[trimmed, 3],

     If[StringStartsQ[trimmed, fence],
      fence = ""
     ]
    ];

    i++;
    Continue[];
   ];

   If[
    fence =!= "" ||
     i >= n ||
     ! StringContainsQ[lines[[i]], "|"],

    i++;
    Continue[];
   ];

   headerCells = rowCells[lines[[i]]];
   separatorCells = rowCells[lines[[i + 1]]];

   (* A Markdown table begins with a header and separator *)

   If[
    Length[headerCells] >= 2 &&
     Length[headerCells] === Length[separatorCells] &&
     markdownTableSeparatorRowQ[separatorCells],

    j = i + 2;

    (* Collect rows having the same number of columns *)

    While[
     j <= n &&
      StringTrim[lines[[j]]] =!= "" &&
      StringContainsQ[lines[[j]], "|"] &&
      Length[rowCells[lines[[j]]]] === Length[headerCells],

     j++;
    ];

    AppendTo[
     tables,
     StringRiffle[
      Take[lines, {i, j - 1}],
      "\n"
     ]
    ];

    i = j,

    i++
   ];
  ];

  tables
 ];


replaceImportedMarkdownTablesWithGridsFunction[
  markdown_String,
  cells_List
] :=
 Module[
  {
   tables,
   tableCellPositions,
   newCells,
   renderedTable
  },

  (* Extract the original Markdown table definitions *)

  tables =
   extractOpenAIMarkdownTablesFunction[markdown];

  If[tables === {}, Return[cells]];

  (* Locate native Tabular objects in the imported cells *)

  tableCellPositions =
   Flatten[
    Position[
     cells,
     Cell[
      BoxData[TemplateBox[_, "Tabular", ___]],
      _String,
      ___
     ],
     {1}
    ]
   ];

  (* Never replace tables if the counts do not reconcile *)

  If[
   Length[tables] =!= Length[tableCellPositions],

   Print[
    "Table count mismatch: ",
    Length[tables],
    " Markdown tables versus ",
    Length[tableCellPositions],
    " imported Tabular cells. Original cells preserved."
   ];

   Return[cells];
  ];

  newCells = cells;

  Do[

   (* Reuse the existing, tested renderer *)

   renderedTable =
    renderOpenAIMarkdownTableFunction[
     tables[[i]]
    ];

   If[
    ! MatchQ[renderedTable, _Grid],
    Return[$Failed]
   ];

   (* Create a formatted Text cell without visible string quotes *)

   newCells[[tableCellPositions[[i]]]] =
    Cell[
     BoxData[
      ToBoxes[renderedTable, StandardForm]
     ],
     "Text",
     ShowCellLabel -> False,
     ShowStringCharacters -> False,
     CellGroupingRules -> "NormalGrouping"
    ],

   {i, Length[tables]}
  ];

  newCells
 ];

(* BLOCK 3: Original TeX-aware Markdown table renderer — v6 baseline *)

(* ============================================================ *)
(* 2. IDENTIFY THE MARKDOWN SEPARATOR ROW                       *)
(*                                                              *)
(* Examples:                                                    *)
(* |---|---|                                                    *)
(* |:---|---:|                                                  *)
(* ============================================================ *)

markdownTableSeparatorRowQ[row_List] :=
 AllTrue[
   row,
   StringMatchQ[
     StringTrim[#],
     RegularExpression[":?-{3,}:?"]
   ] &
 ];


(* ============================================================ *)
(* 3. NORMALISE SPECIAL TEXT COPIED FROM OPENAI                 *)
(*                                                              *)
(* At present this converts the literal copied text             *)
(*                                                              *)
(*     \[LongDash]                                              *)
(*                                                              *)
(* into the actual Wolfram named character.                     *)
(*                                                              *)
(* Further named-character rules can easily be added here.      *)
(* ============================================================ *)

normaliseOpenAICopiedTextFunction[text_String] :=
 StringReplace[
   text,
   {
     "\\[LongDash]" -> "\[LongDash]"
   }
 ];


(* ============================================================ *)
(* 4. RENDER ONE MATHEMATICAL FRAGMENT                          *)
(*                                                              *)
(* Ordinary expressions such as                                 *)
(*                                                              *)
(*     AV/Sales                                                 *)
(*     1 - TEC/AV                                               *)
(*     (TEC + D + A)/AV                                         *)
(*                                                              *)
(* are first interpreted as Wolfram Language expressions.       *)
(* This keeps AV, TEC, Sales, etc. as complete identifiers.     *)
(*                                                              *)
(* If that fails, genuine TeX interpretation is attempted.      *)
(* ============================================================ *)

renderOpenAIMathFragmentFunction[formula_String] :=
 Module[
   {
     formulaString,
     renderedExpression
   },

   formulaString =
     StringTrim[formula];


   (* First try ordinary Wolfram Language algebra *)

   renderedExpression =
     Quiet @
       Check[
         ToExpression[
           formulaString,
           InputForm,
           Defer
         ],
         $Failed
       ];


   (* If that fails, try genuine TeX/LaTeX *)

   If[
     renderedExpression === $Failed,

     renderedExpression =
       Quiet @
         Check[
           ToExpression[
             formulaString,
             TeXForm,
             Defer
           ],
           $Failed
         ]
   ];


   (* Final fallback: preserve the original text *)

   If[
     renderedExpression === $Failed,

     Style[
       formulaString,
       Italic
     ],

     TraditionalForm[
       renderedExpression
     ]
   ]
 ];


(* ============================================================ *)
(* 5. RENDER INLINE MATHEMATICS WITHIN ORDINARY TEXT            *)
(*                                                              *)
(* Recognises:                                                  *)
(*                                                              *)
(*     \( ... \)                                                *)
(*                                                              *)
(* Multiple formulae within one cell are supported.             *)
(* ============================================================ *)

renderOpenAIInlineMathFunction[text_String] :=
 Module[
   {
     s,
     openPositions,
     closePositions,
     numberOfFormulas,
     cursor = 1,
     pieces = {},
     openPosition,
     closePosition,
     formulaString
   },

   s =
     normaliseOpenAICopiedTextFunction[text];


   openPositions =
     StringPosition[
       s,
       "\\("
     ];

   closePositions =
     StringPosition[
       s,
       "\\)"
     ];


   (* No inline mathematics *)

   If[
     openPositions === {},
     Return[s]
   ];


   (* Malformed delimiters: leave original text untouched *)

   If[
     Length[openPositions] =!= Length[closePositions],
     Return[s]
   ];


   numberOfFormulas =
     Length[openPositions];


   Do[

     openPosition =
       openPositions[[i]];

     closePosition =
       closePositions[[i]];


     (* Ensure opening delimiter precedes closing delimiter *)

     If[
       closePosition[[1]] <= openPosition[[2]],
       Return[s]
     ];


     (* Text before the formula *)

     If[
       openPosition[[1]] > cursor,

       AppendTo[
         pieces,

         StringTake[
           s,
           {
             cursor,
             openPosition[[1]] - 1
           }
         ]
       ]
     ];


     (* Formula without \( and \) *)

     formulaString =
       StringTrim @
         StringTake[
           s,
           {
             openPosition[[2]] + 1,
             closePosition[[1]] - 1
           }
         ];


     AppendTo[
       pieces,

       renderOpenAIMathFragmentFunction[
         formulaString
       ]
     ];


     cursor =
       closePosition[[2]] + 1,

     {
       i,
       numberOfFormulas
     }
   ];


   (* Text after final formula *)

   If[
     cursor <= StringLength[s],

     AppendTo[
       pieces,

       StringTake[
         s,
         {
           cursor,
           -1
         }
       ]
     ]
   ];


   pieces =
     DeleteCases[
       pieces,
       ""
     ];


   If[
     Length[pieces] == 1,

     First[pieces],

     Row[pieces]
   ]
 ];


(* ============================================================ *)
(* 6. RENDER ONE MARKDOWN TABLE CELL                            *)
(*                                                              *)
(* In addition to inline mathematics, this now recognises       *)
(* Markdown bold syntax:                                        *)
(*                                                              *)
(*     **some text**                                            *)
(*                                                              *)
(* The bold section may itself contain \( ... \) mathematics.   *)
(* ============================================================ *)

renderOpenAIMarkdownCellFunction[cell_String] :=
 Module[
   {
     s,
     boldPositions,
     boldPairs,
     cursor = 1,
     pieces = {},
     openPosition,
     closePosition,
     ordinaryText,
     boldText
   },

   s =
     normaliseOpenAICopiedTextFunction[
       StringTrim[cell]
     ];


   boldPositions =
     StringPosition[
       s,
       "**"
     ];


   (* No Markdown bold syntax *)

   If[
     boldPositions === {},

     Return[
       renderOpenAIInlineMathFunction[
         s
       ]
     ]
   ];


   (* Uneven number of ** delimiters:
      preserve text rather than guessing *)

   If[
     OddQ[
       Length[boldPositions]
     ],

     Return[
       renderOpenAIInlineMathFunction[
         s
       ]
     ]
   ];


   (* Consecutive pairs represent opening and closing ** *)

   boldPairs =
     Partition[
       boldPositions,
       2
     ];


   Do[

     openPosition =
       boldPairs[[i, 1]];

     closePosition =
       boldPairs[[i, 2]];


     (* Ordinary text before this bold section *)

     If[
       openPosition[[1]] > cursor,

       ordinaryText =
         StringTake[
           s,
           {
             cursor,
             openPosition[[1]] - 1
           }
         ];


       AppendTo[
         pieces,

         renderOpenAIInlineMathFunction[
           ordinaryText
         ]
       ]
     ];


     (* Text between ** and ** *)

     boldText =
       StringTake[
         s,
         {
           openPosition[[2]] + 1,
           closePosition[[1]] - 1
         }
       ];


     AppendTo[
       pieces,

       Style[
         renderOpenAIInlineMathFunction[
           boldText
         ],
         Bold
       ]
     ];


     cursor =
       closePosition[[2]] + 1,

     {
       i,
       Length[boldPairs]
     }
   ];


   (* Ordinary text following final bold section *)

   If[
     cursor <= StringLength[s],

     ordinaryText =
       StringTake[
         s,
         {
           cursor,
           -1
         }
       ];


     AppendTo[
       pieces,

       renderOpenAIInlineMathFunction[
         ordinaryText
       ]
     ]
   ];


   pieces =
     DeleteCases[
       pieces,
       ""
     ];


   If[
     Length[pieces] == 1,

     First[pieces],

     Row[pieces]
   ]
 ];


(* ============================================================ *)
(* 7. CONVERT THE COMPLETE MARKDOWN TABLE INTO A GRID           *)
(* ============================================================ *)

renderOpenAIMarkdownTableFunction[
   tableText_String
 ] :=
 Module[
   {
     lines,
     rows,
     formattedRows
   },


   (* Split clipboard text into non-empty lines *)

   lines =
     Select[
       StringTrim /@
         StringSplit[
           tableText,
           {
             "\r\n",
             "\n",
             "\r"
           }
         ],

       # =!= "" &
     ];


   (* Convert Markdown pipe rows into ordinary lists *)

   rows =
     Map[
       StringTrim /@
         StringSplit[
           StringTrim[
             #,
             "|"
           ],
           "|"
         ] &,

       lines
     ];


   (* Remove the Markdown separator row *)

   rows =
     Select[
       rows,
       ! markdownTableSeparatorRowQ[#] &
     ];


   If[
     rows === {},

     Return[
       Style[
         "No Markdown table could be recognised.",
         Red
       ]
     ]
   ];


   (* Render every table cell *)

   formattedRows =
     Map[
       renderOpenAIMarkdownCellFunction,
       rows,
       {
         2
       }
     ];


   (* Header row is always bold *)

   formattedRows[[1]] =
     Style[
       #,
       Bold
     ] & /@
       formattedRows[[1]];


   (* Produce final table *)

   Grid[
     formattedRows,

     Frame -> All,

     Alignment -> {
       Left,
       Center
     },

     Spacings -> {
       1.5,
       0.8
     },

     BaseStyle -> {
       FontSize -> 12
     }
   ]
 ];


(* ============================================================ *)
(* 8. COMPLETE ONE-COMMAND CLIPBOARD WORKFLOW                   *)
(* ============================================================ *)

renderOpenAIMarkdownTableFromClipboardFunction[] :=
 Module[
   {
     clipboardText
   },

   clipboardText =
     readPlainTextFromSystemClipboardFunction[];


   If[
     clipboardText === $Failed,

     Return[
       Style[
         "No usable plain-text content was found on the Windows clipboard.",
         Red
       ]
     ]
   ];


   renderOpenAIMarkdownTableFunction[
     clipboardText
   ]
 ];

(* ============================================================ *)
(* PUBLIC INTERFACE                                             *)
(* ============================================================ *)

Options[BridgeMarkdown] = {
  "HeadingMode" -> "Text"
};

BridgeMarkdown[OptionsPattern[]] :=
 renderOpenAIMarkdownFromClipboardFunction[
  "HeadingMode" -> OptionValue["HeadingMode"]
 ];

(* Retain the v0.1.0 public command as a backwards-compatible alias. *)
Options[InsertMarkdownFromClipboard] = Options[BridgeMarkdown];

InsertMarkdownFromClipboard[OptionsPattern[]] :=
 BridgeMarkdown[
  "HeadingMode" -> OptionValue["HeadingMode"]
 ];

MarkdownToNotebookCells[markdown_String, headingMode_ : "Text"] :=
 chatGPTMarkdownNotebookCellsFunction[markdown, headingMode];

RenderMarkdownTable[tableText_String] :=
 renderOpenAIMarkdownTableFunction[tableText];

RenderMarkdownTableFromClipboard[] :=
 renderOpenAIMarkdownTableFromClipboardFunction[];

End[];
EndPackage[];
