(* Build from within Mathematica after the source has been verified. *)
Needs["PacletTools`"];
Module[{root, result},
  root = DirectoryName[$InputFileName];
  result = PacletBuild[root];
  Print["Paclet archive: ", result["PacletArchive"]];
  result
]
