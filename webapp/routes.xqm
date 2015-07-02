xquery version "3.1";

(:~
 : Example Fold App
 :
 : @version 0.1
 : @author Marc van Grootel
 : @see https://github.com/xokomola/fold-app
 :)
module namespace app ='http://xokomola.com/xquery/fold';

import module namespace router = 'http://xokomola.com/xquery/fold/router'
    at 'fold/core/router.xqm';
import module namespace res = 'http://xokomola.com/xquery/fold/response'
    at 'fold/core/response.xqm';
import module namespace wrap = 'http://xokomola.com/xquery/fold/middleware'
    at 'fold/core/middleware.xqm';
import module namespace handler = 'http://xokomola.com/xquery/fold/handler'
    at 'fold/core/handler.xqm';
import module namespace req = 'http://xokomola.com/xquery/fold/request'
    at 'fold/core/request.xqm';

import module namespace demo = 'http://xokomola.com/xquery/origami/templating/demos'
    at 'demo/templating/demos.xqm';

import module namespace ui = 'http://xokomola.com/xquery/origami/demo/ui'
    at 'ui.xqm';
    
(: ---- /math service ---- :)

declare function app:routes()
{
    router:route($app:routes)
};

declare variable $app:routes := (
    router:context('/demo/templates', $demo:app),
    router:context('/demo/math', $app:math),
    router:context('/demo/todo', $app:todo),
    (: sniffer is pretty expensive and almost triples the response time :)
    (: wrap:sniffer(context('/simple',        $app:simple-routes)), :)
    router:context('/simple',        $app:simple),
    router:GET(('/pingpong/{turns}', map { 'turns': '\d+' }), app:pingpong(app:bat('ping'), app:bat('pong'), 'turns')),
    router:GET('/', function($req) {
        ui:landing-page($ui:landing-content) 
    }),
    router:not-found(<not-found>No more examples for you!</not-found>)    
);

declare variable $app:todo := (
    router:GET('/', wrap:content-type(wrap:file(function($request) { res:redirect('/') }, fn:concat(file:base-dir(), 'demo/todomvc'))))
);

declare variable $app:simple := (
    router:GET('/greeting/{name}', function($request) { res:ok('Hello ' || req:get-param($request, 'name') || '!') }),
    router:GET('/dump',            wrap:params(handler:dump#1)),
    router:GET('/context',         function($request) { res:ok(inspect:context()) }),
    router:GET('/txt',             function($request) { 'hello i am ', ' just a string' }),
    router:GET('/xml',             function($request) { <hello><world/></hello> }),
    router:POST('/post',           wrap:params(handler:dump#1)),
    router:not-found(<not-found>No more examples for you!</not-found>)
);

declare variable $app:math := (
    router:GET(('/sum/{a}/{b}', map { 'a': '\d+', 'b': '\d+' }),
        ('a|integer', 'b|integer'),
        app:sum#2)
);

declare function app:sum($x as xs:integer, $y as xs:integer) { 
    map {
        'op1': $x, 
        'op2': $y, 
        'op': '+', 
        'result': $x + $y
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
            res:ok(hof:until(
                function($x) { $x('hits') eq $n }, 
                app:play($h2, $h1), 
                map:merge(($request, map { 'hits': 0 }))
            )('body'))
    }
};

(:~ Makes a pingpong bat :)
declare function app:bat($sound as xs:string) {
    function($request) {
        let $body := 
            $request('body') || $sound || ' #' || $request('hits') || '&#10;'
        return
            map:merge(($request, map { 'body': $body })) }
};

(:~ Take turns between player 1 and 2 :)
declare function app:play($h1, $h2)  {
    function($request) {
        let $request := map:merge(($request, map { 'hits': $request('hits') + 1 }))
        return
            if ($request('hits') mod 2 = 0) then
                $h1($request) 
            else
                $h2($request)
    }
};
