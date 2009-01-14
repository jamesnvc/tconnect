! Copyright (C) 2008 James Cash
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences math math.parser math.ranges
http.server.dispatchers io
furnace.syndication furnace.redirection
furnace.auth furnace.actions
furnace.boilerplate
db db.types db.tuples
accessors present urls fry
html.forms formatting logging
validators calendar calendar.format tconnect.tags ;
IN: tconnect.tutorials

TUPLE: tutorials < dispatcher ;

SYMBOL: can-administer-tutorials?

LOG: log-obj DEBUG

: tconnect-log ( object --  )
    "tconnect" [ log-obj ] with-logging ;

can-administer-tutorials? define-capability

: view-tutorial-url ( id -- url )
    present "$tutorials/tutorial/" prepend >url ;

: list-tutorials-url ( -- url )
    "$tutorials/" >url ;

: tutorials-by-url ( tutor -- url )
    "$tutorials/by/" prepend >url ;

TUPLE: tutorial id tutor subject cost location starts ends time length day repeats ;

GENERIC: entity-url ( entity -- url )

M: tutorial entity-url
    id>> view-tutorial-url ;

M: tutorial feed-entry-url entity-url ;

tutorial "TUTORIAL" {
    { "id" "ID" INTEGER +db-assigned-id+ }
    { "tutor" "TUTOR" { VARCHAR 256 } +not-null+ }
    { "subject" "SUBJECT" { VARCHAR 256 } +not-null+ }
    { "location" "LOCATION" { VARCHAR 256 } +not-null+ }
    { "cost" "COST" INTEGER +not-null+ }
    { "starts" "STARTS" DATE +not-null+ }
    { "ends" "ENDS" DATE +not-null+ }
    { "time" "STARTTIME" TIME +not-null+ }
    { "length" "TUT_LEN" INTEGER +not-null+ }
    { "day" "DAY" { VARCHAR 9 } +not-null+ }
    { "repeats" "REPEATS" BOOLEAN }
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
            "id" value tutorial-by-id dup from-object
            [ time>> timestamp>hms "time" set-value ] keep
            [ starts>> timestamp>string "starts" set-value ] keep
            [ ends>> timestamp>string "ends" set-value ] keep
            
        ] >>init
    
        { tutorials "view-tutorial" } >>template ;

: list-tutorials (  -- tutorials )
    f <tutorial> select-tuples ;

: list-tutorials-by ( -- tutorials )
    f <tutorial> "tutor" value >>tutor select-tuples ;

: list-with-template ( responder template -- responder' )
    [
        { tutorials "list-tutorials-common" } >>template
        <boilerplate>
    ] dip >>template ;

: <list-tutorials-action> (  -- action )
    <page-action>
        [ list-tutorials "tutorials" set-value ] >>init
    { tutorials "list-tutorials" } list-with-template ;

: validate-tutor ( -- )
    { { "tutor" [ v-username ] } } validate-params ;
    
: validate-tutorial (  --  )
    {
        { "subject" [ v-required ] }
        { "location" [ v-one-line ] }
        { "length" [ v-integer ] }
        { "cost" [ v-integer ] }
        { "day" [ v-required ] }
        { "one-off" [ v-checkbox ] }
        { "starts-month" [ v-required ] }
        { "starts-day" [ v-required ] }
        { "ends-month" [ v-required ] }
        { "ends-day" [ v-required ] }
        { "time-hours" [ v-required ] }
        { "time-minutes" [ v-required ] }
    } validate-params ;

: set-time-choices (  --  )
    24 [ "%02d" sprintf ] map "tut-hours" set-value
    0 45 15 <range> [ "%02d" sprintf ] map "tut-minutes" set-value
    month-names "months" set-value
    day-names "weekdays" set-value
    31 [1,b] [ number>string ] map "days" set-value ;

: get-time (  -- timestamp )
    "time-hours" "time-minutes" [ value ] bi@ ":" glue ":00" append hms>timestamp ;

: month-ordinal ( name-string -- int-string' )
    month-names index 1+ "%02d" sprintf ;

: get-date ( field -- timestamp )
    now year>> number>string swap dup [ "-month" append value month-ordinal ] dip
    "-day" append value [ "-" glue ] bi@ ymd>timestamp ;
    
: <new-tutorial-action> (  -- action )
    <page-action>
        [ set-time-choices ] >>init
        [
            username "tutor" set-value
            validate-tutorial
        ] >>validate
        [
            f <tutorial>
                dup { "tutor" "subject" "location" "cost" "length" "day" } to-object
                "one-off" value not >>repeats
                "starts" get-date >>starts
                "ends" get-date >>ends
                get-time >>time
            [ tconnect-log ] [ insert-tuple ] [ entity-url <redirect> ] tri
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
    { tutorials "tutorials-by" } list-with-template ;

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
        [ set-time-choices do-tutorial-action ] >>init
        [ set-time-choices do-tutorial-action validate-tutorial ] >>validate
        [ "tutor" value authorize-author ] >>authorize
        [
            "id" value <tutorial>
            dup { "tutor" "subject" "location" "cost" "length" "day" } to-object
            "one-off" value not >>repeats
            get-time  >>time
            "starts" get-date >>starts
            "ends" get-date >>ends
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