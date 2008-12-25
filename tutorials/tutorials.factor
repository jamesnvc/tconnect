! Copyright (C) 2008 James Cash
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences math.parser
http.server.dispatchers
furnace.syndication furnace.redirection
furnace.auth furnace.actions
furnace.boilerplate
db db.types db.tuples
accessors present urls 
html.forms
validators calendar.format ;
IN: tconnect.tutorials

TUPLE: tutorials < dispatcher ;

SYMBOL: can-administer-tutorials?

can-administer-tutorials? define-capability

: view-tutorial-url ( id -- url )
    present "$tutorials/tutorial/" prepend >url ;

: list-tutorials-url ( -- url )
    "$tutorials/" >url ;

: tutorials-by-url ( tutor -- url )
    "$tutorials/by/" prepend >url ;

TUPLE: tutorial id tutor subject time location cost ;

GENERIC: entity-url ( entity -- url )

M: tutorial entity-url
    id>> view-tutorial-url ;

M: tutorial feed-entry-url entity-url ;

tutorial "TUTORIAL" {
    { "id" "ID" INTEGER +db-assigned-id+ }
    { "tutor" "TUTOR" { VARCHAR 256 } +not-null+ }
    { "subject" "SUBJECT" { VARCHAR 256 } +not-null+ }
    { "time" "TIME" { VARCHAR 256 } +not-null+ }
    { "location" "LOCATION" { VARCHAR 256 } +not-null+ }
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
        { tutorials "list-tutorials-common" } >>template        
    <boilerplate>
        { tutorials "list-tutorials" } >>template ;

: validate-tutor ( -- )
    { { "tutor" [ v-username ] } } validate-params ;
    
: validate-tutorial (  --  )
    {
        { "subject" [ v-required ] }
        { "location" [ v-required ] }
        { "time" [ v-required ] }
        {  "cost" [ v-integer ] }
    } validate-params ;
    
: <new-tutorial-action> (  -- action )
    <page-action>
        [
            validate-tutorial
            username "tutor" set-value
        ] >>validate
        [
            f <tutorial>
                dup { "tutor" "subject" "location" "time" "cost" } to-object
             [ insert-tuple ] [ entity-url <redirect> ] bi
        ] >>submit 
    { tutorials "new-tutorial" } >>template
    <protected>
        "make a new tutorial" >>description ;
    
: <tutorials-by-action> ( -- action )
    <page-action>
        "tutor" >>rest
        [
            validate-tutor
            list-tutorials-by "tutorials" set-value
        ] >>init
        { tutorials "list-tutorials-common" } >>template        
    <boilerplate>
        { tutorials "tutorials-by" } >>template ;

: authorize-author ( author -- )
    username =
    { can-administer-tutorials? } have-capabilities? or
    [ "edit a tutorial listing" f login-required ] unless ;

: do-tutorial-action (  --  )
    validate-integer-id
    "id" value <tutorial> select-tuple from-object ;

: <edit-tutorial-action> (  -- action )
    <page-action>
        "id" >>rest
        [ do-tutorial-action ] >>init
        [ do-tutorial-action validate-tutorial ] >>validate
        [ "tutor" value authorize-author ] >>authorize
        [
            "id" value <tutorial>
            dup { "tutor" "subject" "location" "time" "cost" } to-object
            [ update-tuple ] [ entity-url <redirect> ] bi
        ] >>submit
        { tutorials "edit-tutorial" } >>template
    <protected>
        "edit a tutorial" >>description ;

: delete-tutorial ( id --  )
    <tutorial> delete-tuples ;
    
: owner? (  -- ? )
    "tutor" value username = { can-administer-tutorials? } have-capabilities? or ;
    
: <delete-tutorial-action> (  -- action )
    <action>
        [ do-tutorial-action ] >>validate
        [ "tutor" value authorize-author ] >>authorize
        [
            [ "id" value delete-tutorial ] with-transaction
            list-tutorials-url <redirect>
        ] >>submit
    <protected>
        "delete a tutorial" >>description ;

: <tutorials> (  -- dispatcher )
    tutorials new-dispatcher
        <list-tutorials-action> "" add-responder
        <new-tutorial-action> "new-tutorial" add-responder
        <tutorials-by-action> "by" add-responder
        <view-tutorial-action> "tutorial" add-responder
        <edit-tutorial-action> "edit-tutorial" add-responder
        <delete-tutorial-action> "delete-tutorial" add-responder
    <boilerplate>
        { tutorials "tutorials-common" } >>template ;