IN: tconnect.tags
USING: help.markup help.syntax ;

ARTICLE: "tconnect.tags" "Additional Chloe tags"
"The " { $vocab-link "tconnect.tags" } " vocabulary implements the following additional Chloe tags:"
{ $table
  { { $snippet "t:unless" } "Identical to the t:if tag, except displays children if the " { $snippet "code" } " parameter is false." }
  { { $snippet "t:time" } "Displays the timestamp given by the value of " { $snippet "name" } " in h:m:s form."  }
  { { $snippet "t:date" } "Displays the timestamp given by the value of " { $snippet "name" } " in y-m-d form."  }
}
;

ABOUT: "tconnect.tags"