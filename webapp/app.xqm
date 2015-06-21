xquery version "3.0";

(:~
 : Example Fold App
 :
 : @version 0.1
 : @author Marc van Grootel
 : @see https://github.com/xokomola/fold-app
 :)
module namespace app ='http://xokomola.com/xquery/fold-app';

declare default function namespace 'http://xokomola.com/xquery/fold/routes';

import module namespace handler = 'http://xokomola.com/xquery/fold/handler'
    at '../fold/handler.xqm';
import module namespace route = 'http://xokomola.com/xquery/fold/routes'
    at '../fold/routes.xqm';
import module namespace wrap = 'http://xokomola.com/xquery/fold/middleware'
    at '../fold/middleware.xqm';
import module namespace res = 'http://xokomola.com/xquery/fold/response'
    at '../fold/response.xqm';
import module namespace req = 'http://xokomola.com/xquery/fold/request'
    at '../fold/request.xqm';

import module namespace request = "http://exquery.org/ns/request";

declare option db:chop 'false';

(:~
 : Main routing handler. Called by fold:serve#1.
 :
 : @return the response map.
 :)
declare function app:serve() {
    function($request) { route($app:routes)($request) }
};

(:~ 404 response :)
declare variable $app:not-found := not-found(<not-found>No more examples for you!</not-found>);

(:~ Main examples routing table :)
declare variable $app:routes := (
    $app:not-found
);

declare variable $app:routes := (
    wrap:sniffer(context('/simple',        $app:simple-routes)),
    wrap:sniffer(context('/upload',        $app:uploads)),
    GET('/fold/docs.{ext}',   app:docs#1),
    GET(('/pingpong/{turns}', map { 'turns': '\d+' }), app:pingpong(app:bat('ping'), app:bat('pong'), 'turns')),
    GET('/',                  function($request) { res:content-type(res:ok(html:parse(file:read-text(file:base-dir() || 'index.html'))), 'text/html')}),
    $app:not-found
);

(:~ Simple examples routing table :)
declare variable $app:simple-routes := (
    GET('/greeting/{name}', function($request) { res:ok('Hello ' || req:get-param($request, 'name') || '!') }),
    GET('/dump',            wrap:params(handler:dump#1)),
    GET('/context',         function($request) { res:ok(inspect:context()) }),
    GET('/txt',             function($request) { 'hello i am ', ' just a string' }),
    GET('/xml',             function($request) { <hello><world/></hello> }),
    POST('/post',           wrap:params(handler:dump#1)),
    GET('/post',            app:form#1),
    GET('/*',      wrap:file(?, 
                                    file:resolve-path(file:base-dir() || 'assets'))),
    
    (: When no route matches return a 404 :)
    $app:not-found
);

(:
 : Handler for getting file resources including handling not-modified correctly
 :)
declare function app:modified($request) {
    let $path := req:get-param($request,'*')
    return
        res:file-response($path, map { 'root': file:resolve-path(file:base-dir() || 'assets') })
};
    
(:
 : TODO: file uploads require more work.
 :
 : Routing table for file uploads.
 :)
declare variable $app:uploads := (
    GET('/form', app:upload-form#1),
    POST('/form', wrap:multipart-params(app:upload#1)));
    
declare function app:upload-form($request) {
    res:content-type(
        res:ok(
            <html>
              <head>
                <title>Upload form</title>
              </head>
              <body>
                <form action="/examples/upload/form" method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="MAX_FILE_SIZE" value="1000000" />
                    <input type="file" name="files" multiple="multiple"/>
                    <input type="file" name="abc" multiple="multiple"/>
                    <input type="submit"/>
                </form>
                <form action="/examples/upload/form" method="POST">
                    <input type="text" name="foo"/>
                    <input type="submit"/>
                </form>
              </body>
            </html>), 'text/html')
};

declare function app:form($request) {
    res:content-type(
        res:ok(
            <html>
              <head>
                <title>Simple form</title>
              </head>
              <body>
                <form action="/examples/simple/post" method="POST">
                    <input type="text" name="foo"/>
                    <select name="fruit">
                     <option value="apple">Apple</option>
                     <option value="banana">Banana</option>
                     <option value="orange">Orange</option>
                   </select>
                    <input type="submit"/>
                </form>
              </body>
            </html>), 'text/html')
};

(: TODO :)
declare function app:upload($request) {
    res:ok(map:serialize($request))
};

(:~
 : Documentation browser
 :)
declare function app:docs($request) {
    let $path-info := fn:substring-after(req:path-info($request), '/docs/xml')
    let $default-module := '../apps.xqm'
    let $module-path :=
        if ($path-info = '/' or $path-info = '') then
            $default-module
        else
            '..' || $path-info || '.xqm'
    return
        try {
            res:ok(inspect:xqdoc($module-path))
        } catch err:FODC0002 {
            res:not-found(<not-found/>)
        }
};

(:~
 : Wraps documentation browser in an HTML view
 :
 : NOTE: this requires Saxon 9 installed as the default XSLT engine.
 :)
declare function app:html-viewer($handler, $xslt-transform) {
    function($request) {
        res:content-type(
            map:new(($request, 
                map { 'body': 
                    xslt:transform($request('body'), $xslt-transform)
                }
            )),
            'text/html'
        )
    }
};

(:~
 : Example middleware function.
 :)
declare function app:middleware($handler, $arg) {
    function($request) { 
        $handler(map:new(($request, map{'middleware-arg': $arg })))
    }
};

(:~
 : A silly ping-pong game.
 :
 : /examples/pingpong/40 
 : starts a game of 40 turns between two players.
 :)
declare function app:pingpong($h1, $h2, $turns) {
    function($request) {
        let $n := xs:integer($request('params')($turns))
        return
            res:status(
                hof:until(
                    function($x) { $x('hits') eq $n }, 
                    app:play($h2, $h1), 
                    map:new(($request, map { 'hits': 0 }))
                ),
                200
            )
    }
};

(:~ Makes a pingpong bat :)
declare function app:bat($sound as xs:string) {
    function($request) {
        let $body := 
            $request('body') || $sound || ' #' || $request('hits') || '&#10;'
        return
            map:new(($request, map { 'body': $body })) }
};

(:~ Take turns between player 1 and 2 :)
declare function app:play($h1, $h2)  {
    function($request) {
        let $request := map:new(($request, map { 'hits': $request('hits') + 1 }))
        return
            if ($request('hits') mod 2 = 0) then
                $h1($request) 
            else
                $h2($request)
    }
};
