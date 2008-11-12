! Copyright (C) 2008 James Cash
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences
http.server.dispatchers
furnace.syndication furnace.redirection
furnace.auth furnace.actions
furnace.boilerplate
db.types db.tuples
accessors present urls 
html.forms
validators calendar.format
;
IN: tconnect.tutorials

TUPLE: tutorials < dispatcher ;

SYMBOL: can-administer-tutorials?

can-administer-tutorials? define-capability

: view-tutorial-url ( id -- url )
    present "$tutorials/tutorial/" prepend >url ;

: list-tutorials-url ( -- url )
    "$tutorials/" >url ;

TUPLE: tutorial id tutor subject time location ;

GENERIC: tutorial-url ( tutorial -- url )

M: tutorial feed-entry-url tutorial-url ;

tutorial f {
    { "id" "ID" INTEGER +db-assigned-id+ }
    { "tutor" "TUTOR" { VARCHAR 256 } +not-null+ }
    { "subject" "SUBJECT" TEXT +not-null+ }
    { "time" "TIME" DATETIME +not-null+ }
    { "location" "LOCATION" TEXT +not-null+ }
} define-persistent

: <tutorial> ( id -- tutorial )
    \ tutorial new swap >>id ;

: list-tutorials (  -- tutorials )
    f <tutorial> select-tuples ;

: <list-tutorials-action> (  -- action )
    <page-action>
        [ list-tutorials "tutorials" set-value ] >>init
        { tutorials "list-tutorials" } >>template ;
    
: validate-tutorial (  --  )
    {
        { "subject" [ v-required ] }
        { "location" [ v-required ] }
        { "time" [ v-required ] }
    } validate-params ;
    
: <new-tutorial-action> (  -- action )
    <page-action>
        [
            validate-tutorial
            username "tutor" set-value
        ] >>validate
        [
            f <tutorial>
                dup { "subject" "location" } to-object
                username >>tutor
                "time" value rfc822>timestamp >>time
             [ insert-tuple ] [ tutorial-url <redirect> ] bi
        ] >>submit 
    { tutorials "new-tutorial" } >>template
    <protected>
        "make a new tutorial" >>description ;

: authorize-author ( author -- )
    username =
    { can-administer-tutorials? } have-capabilities? or
    [ "edit a tutorial listing" f login-required ] unless ;

: <tutorials> (  -- dispatcher )
    tutorials new-dispatcher
        <list-tutorials-action> "" add-responder
        <new-tutorial-action> "new-tutorial" add-responder
    <boilerplate>
        { tutorials "tutorials-common" } >>template ;