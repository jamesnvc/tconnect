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

TUPLE: tutorial id tutor subject time location cost ;

GENERIC: tutorial-url ( tutorial -- url )

M: tutorial tutorial-url
    id>> view-tutorial-url ;

M: tutorial feed-entry-url tutorial-url ;

tutorial "TUTORIAL" {
    { "id" "ID" INTEGER +db-assigned-id+ }
    { "tutor" "TUTOR" { VARCHAR 256 } +not-null+ }
    { "subject" "SUBJECT" TEXT +not-null+ }
    { "time" "TIME" DATETIME +not-null+ }
    { "location" "LOCATION" TEXT +not-null+ }
    { "cost" "COST" INTEGER +not-null+ }
} define-persistent

: <tutorial> ( id -- tutorial )
    \ tutorial new swap >>id ;

: tutorial-by-id ( id -- tutorial )
    <tutorial> select-tuple ;

: <view-tutorial-action> (  -- action )
    <page-action>
        "id" >>rest
        [
            validate-integer-id
            "id" value tutorial-by-id from-object
        ] >>init
    
        { tutorials "view-tutorial" } >>template ;

: list-tutorials (  -- tutorials )
    f <tutorial> select-tuples ;

: list-tutorials-by ( -- tutorials )
    f <tutorial> "tutor" value >>tutor select-tuples ;

: <list-tutorials-action> (  -- action )
    <page-action>
        [ list-tutorials "tutorials" set-value ] >>init
        { tutorials "list-tutorials" } >>template ;

: validate-tutor ( -- )
    { { "tutor" [ v-username ] } } validate-params ;
    
: validate-tutorial (  --  )
    {
        { "subject" [ v-required ] }
        { "location" [ v-required ] }
        { "time" [ v-required ] }
        {  "cost" [ v-required ] }
    } validate-params ;
    
: <new-tutorial-action> (  -- action )
    <page-action>
        [
            validate-tutorial
            username "tutor" set-value
        ] >>validate
        [
            f <tutorial>
                dup { "tutor" "subject" "location" "cost" } to-object
                "time" value rfc822>timestamp >>time
             [ insert-tuple ] [ tutorial-url <redirect> ] bi
        ] >>submit 
    { tutorials "new-tutorial" } >>template
    <protected>
        "make a new tutorial" >>description ;
    
: <tutorials-by-action> ( -- action )
    <page-action>
        "tutor" >>rest
        [
            validate-tutor
            list-tutorials-by "sessions" set-value
        ] >>init
        { tutorials "tutorials-by" } >>template ;

: authorize-author ( author -- )
    username =
    { can-administer-tutorials? } have-capabilities? or
    [ "edit a tutorial listing" f login-required ] unless ;

: <tutorials> (  -- dispatcher )
    tutorials new-dispatcher
        <list-tutorials-action> "" add-responder
        <new-tutorial-action> "new-tutorial" add-responder
        <tutorials-by-action> "by" add-responder
        <view-tutorial-action> "tutorial" add-responder
    <boilerplate>
        { tutorials "tutorials-common" } >>template ;