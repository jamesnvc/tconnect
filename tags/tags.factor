! Copyright (C) 2009 James Cash.
! See http://factorcode.org/license.txt for BSD license.
USING: calendar.format fry html.forms html.templates.chloe html.templates.chloe.compiler
html.templates.chloe.syntax io kernel sequences ;
IN: tconnect.tags

CHLOE: unless
    dup if>quot [ swap unless ] append process-children ;

CHLOE: time
    "name" required-attr '[ _ value timestamp>hms write ] [code] ;

CHLOE: date
    "name" required-attr '[ _ value timestamp>ymd write ] [code] ;
