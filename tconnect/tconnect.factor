! Copyright (C) 2008 James Cash
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel sequences assocs io.files io.sockets
io.sockets.secure io.servers.connection
namespaces db db.tuples db.sqlite smtp urls
logging.insomniac
html.templates.chloe
http.server
http.server.dispatchers
http.server.redirection
http.server.static
http.server.cgi
furnace.alloy
furnace.auth.login
furnace.auth.providers.db
furnace.auth.features.edit-profile
furnace.auth.features.recover-password
furnace.auth.features.registration
furnace.auth.features.deactivate-user
furnace.boilerplate
furnace.redirection
webapps.pastebin
webapps.planet
webapps.wiki
webapps.user-admin
webapps.help 
tconnect.tutorials ;
IN: tconnect

: test-db ( -- db ) "resource:work/tconnect/test.db" <sqlite-db> ;

: init-factor-db ( -- )
    test-db [
        init-furnace-tables
        { tutorial } ensure-tables
    ] with-db ;

TUPLE: tconnect-website < dispatcher ;    

: <login-config> ( responder -- responder' )
    "TConnect website" <login-realm>
        "TConnect" >>name
        allow-registration
        allow-password-recovery
        allow-edit-profile
        allow-deactivation ;
    
: <tconnect-website> (  -- responder )
    tconnect-website new-dispatcher
        <tutorials> "tutorials" add-responder 
        <user-admin> <login-config> "user-admin" add-responder
        URL" /tutorials" <redirect-responder> "" add-responder ;
    
: common-configuration ( -- )    
    init-factor-db ;

: init-testing (  --  )
    common-configuration
    <tconnect-website>
    test-db <alloy>
    main-responder set-global ;

: <tconnect-website-server> ( -- threaded-server )
    <http-server>
        8888 >>insecure ;
    
: start-testing-site (  --  )
    init-testing
    t development? set-global
    <tconnect-website-server> start-server ;