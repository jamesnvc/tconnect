! Copyright (C) 2008 James Cash
! See http://factorcode.org/license.txt for BSD license.
USING: kernel accessors sequences assocs
io.files io.sockets io.sockets.secure io.servers.connection io.pathnames
namespaces db db.tuples db.sqlite smtp urls
logging logging.server logging.insomniac
html.templates.chloe html.templates.chloe.compiler html.templates.chloe.syntax
http.server http.server.dispatchers http.server.redirection http.server.static http.server.cgi
furnace.alloy
furnace.auth.login
furnace.auth.providers.db
furnace.auth.features.edit-profile
furnace.auth.features.recover-password
furnace.auth.features.registration
furnace.auth.features.deactivate-user
furnace.boilerplate
furnace.redirection
webapps.user-admin
tconnect.tutorials ;
IN: tconnect
    
: tconnect-root (  -- object )
    home "src/factor/work/tconnect" append-path ;

: test-db ( -- db ) "resource:work/tconnect/test.db" <sqlite-db> ;

: init-factor-db ( -- )
    test-db [
        init-furnace-tables
        { tutorial } ensure-tables
    ] with-db ;

TUPLE: tconnect-website < dispatcher ;    

CHLOE: unless dup if>quot [ swap unless ] append process-children ;

: <tconnect-boilerplate> ( responder -- responder' )
    <boilerplate>
        { tconnect-website "main" } >>template ;

: <login-config> ( responder -- responder' )
    "TConnect website" <login-realm>
        "TConnect" >>name
        f >>secure
        allow-registration
        allow-password-recovery
        allow-edit-profile
        allow-deactivation ;
    
: <tconnect-website> (  -- responder )
    tconnect-website new-dispatcher
        <tutorials> <login-config> "tutorials" add-responder 
        <user-admin> <login-config> "user-admin" add-responder
        tconnect-root "images" append-path <static> "images" add-responder
        URL" /tutorials" <redirect-responder> "" add-responder
    <tconnect-boilerplate> ;
    
: common-configuration ( -- )    
    init-factor-db ;

: init-testing ( -- )
    common-configuration
    <tconnect-website>
        test-db <alloy>
    main-responder set-global ;

: <tconnect-website-server> ( -- threaded-server )
    <http-server>
        8080 >>insecure ;
    
: start-testing-site (  --  )
        init-testing
        t development? set-global
        <tconnect-website-server> start-server ;