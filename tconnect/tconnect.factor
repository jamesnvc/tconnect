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
nwebapps.wiki
webapps.user-admin
webapps.help ;
IN: tconnect

! TUPLE: tutorials < dispatcher ;

! TUPLE: tutorial id tutor time location ;

! GENERIC: tutorial-url ( tutorial -- url )

! M: tutorial feed-entry-url tutorial-url ;

TUPLE: my-dispatcher < dispatcher ;

my-dispatcher new-dispatcher
  <page-action>
    { my-dispatcher "main" } >>template
  "foo" add-responder 
  main-responder set-global