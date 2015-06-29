xquery version "3.0";

(:~
 : Example Fold App
 :
 : @version 0.1
 : @author Marc van Grootel
 : @see https://github.com/xokomola/fold-app
 :)
module namespace app ='http://xokomola.com/xquery/fold';

declare default function namespace 'http://xokomola.com/xquery/fold/routes';

import module namespace route = 'http://xokomola.com/xquery/fold/routes'
    at 'fold/core/routes.xqm';
import module namespace res = 'http://xokomola.com/xquery/fold/response'
    at 'fold/core/response.xqm';
import module namespace μ = 'http://xokomola.com/xquery/origami/μ'
    at 'origami/mu.xqm'; 
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at 'origami/core.xqm'; 
import module namespace wrap = 'http://xokomola.com/xquery/fold/middleware'
    at 'fold/core/middleware.xqm';
import module namespace handler = 'http://xokomola.com/xquery/fold/handler'
    at 'fold/core/handler.xqm';
import module namespace req = 'http://xokomola.com/xquery/fold/request'
    at 'fold/core/request.xqm';

declare variable $app:landing-content as element(page) :=
    <page>
        <hero>
            <h>
                Write Web applications using XQuery&#160;3 and the BaseX XML database
            </h>
        </hero>
        <values>
            <col>
                <h>BaseX</h>
                <p>A fast, lightweight XQuery&#160;3 XML database that comes with batteries included.</p>
                <a href="http://basex.org">Try BaseX</a>
            </col>
            <col>
                <h>+ Fold</h>
                <p>Compose request handlers and middleware to build web applications
                and REST services.</p>
                <a href="https://github.com/xokomola/fold">Try Fold</a>
            </col>
            <col>
                <h>+ Origami</h>
                <p>Composable page templates. Can also be used as general templating library.</p>
                <a href="https://github.com/xokomola/origami">Try Origami</a>
            </col>
        </values>
        <help>
            <h>Demos</h>
            <p>Try out various demos</p>
            <a href="/demo/templates">Start now!</a>
        </help>
        <categories>
            <h>Need help getting started?</h>
            <p>Learn how to build web applications using Origami and Fold.</p>
            <a href="http://xokomola.com">View tutorials</a>
        </categories>
    </page>;
    
(: ---- /math service ---- :)

declare function app:routes()
{
    route:route($app:routes)
};

declare variable $app:routes := (
    context('/demo/templates', $app:demos),
    context('/demo/math', $app:math),
    context('/demo/todo', $app:todo),
    (: sniffer is pretty expensive and almost triples the response time :)
    (: wrap:sniffer(context('/simple',        $app:simple-routes)), :)
    context('/simple',        $app:simple),
    GET(('/pingpong/{turns}', map { 'turns': '\d+' }), app:pingpong(app:bat('ping'), app:bat('pong'), 'turns')),
    GET('/', function($req) {
        app:landing-page($app:landing-content) 
    }),
    not-found(<not-found>No more examples for you!</not-found>)    
);

declare variable $app:todo := (
    GET('/', wrap:content-type(wrap:file(function($request) { res:redirect('/') }, fn:concat(file:base-dir(), 'demo/todomvc'))))
);

declare variable $app:base-page := 
    xf:template(
        xf:xml-resource(fn:concat(file:base-dir(),'static/base.html')), 
        ['html:div[@class="container"]', xf:content(function($n,$c) { μ:xml($c) })],
        function($nodes) { $nodes }
    );
      
declare variable $app:demos := (
    GET('/{name}', function($req) { res:ok($app:base-page(app:demo(req:get-param($req, 'name')))) }),
    GET('/', function($req) { res:ok($app:base-page(app:demo())) })
);

declare variable $app:simple := (
    GET('/greeting/{name}', function($request) { res:ok('Hello ' || req:get-param($request, 'name') || '!') }),
    GET('/dump',            wrap:params(handler:dump#1)),
    GET('/context',         function($request) { res:ok(inspect:context()) }),
    GET('/txt',             function($request) { 'hello i am ', ' just a string' }),
    GET('/xml',             function($request) { <hello><world/></hello> }),
    POST('/post',           wrap:params(handler:dump#1)),
    not-found(<not-found>No more examples for you!</not-found>)
);

declare function app:demo()
{
    app:demo(())
};

declare function app:demo($name as xs:string?)
{
    let $demo-xml := xf:xml-resource(fn:concat(file:base-dir(),'demo/templating/demos.xml'))/demos
    let $selected-demo := ($demo-xml/demo[@name = $name], $demo-xml/demo[1])[1]
    let $demo-name := fn:string($selected-demo/@name)
    return
        (
            ['h:div', ['h:p']],
            ['h:div', map { 'class': 'tabs' },
                for $demo in $demo-xml/demo
                return
                    ['h:a', 
                        map { 
                            'class': ('button', ' ', if ($demo/@name = $demo-name) then 'button-primary' else ()), 
                            'href': fn:concat('/demo/templates/', $demo/@name) }, $demo/title]
            ],
            let $demo := $selected-demo
            return
                ['h:div', map { 'class': 'example' },
                    ['h:div', map { 'class': 'row' },
                        ['h:div', map { 'class': 'one-half column' }, 
                            ['h:pre', $demo/source/template/text()]], 
                        ['h:div', map { 'class': 'one-half column' }, 
                            ['h:pre', $demo/source/xquery/text()]]
                    ],
                    ['h:div', map { 'class': 'row' },
                        ['h:div', map { 'class': 'one-half column' }, 
                            ['h:pre', 'RESULT of template']], 
                        ['h:div', map { 'class': 'one-half column' }, 
                            ['h:pre', $demo/description/text()]]
                    ]
                ]
        )
};

declare variable $app:math := (
    GET(('/sum/{a}/{b}', map { 'a': '\d+', 'b': '\d+' }),
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

declare function app:landing-page($content)
{
    app:page(['h:body',
        ['h:div', map { 'class': 'section hero' },
            ['h:div', map { 'class': 'container' },
                ['h:div', map { 'class': 'row' },
                    ['h:div', map { 'class': 'one-half column' },
                        ['h:h4', map { 'class': 'hero-heading' },
                            μ:content($content/hero/h) ],
                        for $link in $content/hero/a
                        return
                            ['h:a', map { 'class': 'button button-primary', 'href': fn:string($link/@href) },
                                μ:content($link)]
                    ],
                    ['h:div', map { 'class': 'one-half column phones' },
                        ['h:img', map { 'class': 'phone', 'src': '/static/logo240.png' }]
                    ]
                ]
            ]
        ],
        
        ['h:div', map { 'class': 'section values' },
            ['h:div', map { 'class': 'container' },
                ['h:div', map { 'class': 'row' },
                    for $sect in $content/values/col
                    return
                        ['h:div', map { 'class': 'one-third column value' },
                            ['h:h4', map { 'class': 'value-heading' }, μ:content($sect/h)],
                            ['h:p', map { 'class': 'value-description' }, μ:content($sect/p)]
                        ]
                ],
                ['h:div', map { 'class': 'row' },
                    for $sect in $content/values/col
                    return
                        ['h:div', map { 'class': 'one-third column value' },
                            for $link in $sect/a
                            return
                                ['h:a', map { 'class': 'button button-primary', 'href': fn:string($link/@href) },
                                    μ:content($link)]
                        ]

                ]
            ]
        ],
        
        ['h:div', map { 'class': 'section get-help' },
            ['h:div', map { 'class': 'container' },
                ['h:h3', map { 'class': 'section-heading' }, μ:content($content/help/h)],
                ['h:p', map { 'class': 'section-description' }, μ:content($content/help/p)],
                ['h:a', map { 'class': 'button button-primary', 'href': fn:string($content/help/a/@href) },
                    μ:content($content/help/a)]
            ]
        ],
        
        ['h:div', map { 'class': 'section categories' },
            ['h:div', map { 'class': 'container' },
                ['h:h3', map { 'class': 'section-heading' }, μ:content($content/categories/h)],
                ['h:p', map { 'class': 'section-description' },
                    μ:content($content/categories/p)],
                ['h:a', map { 'class': 'button button-primary', 'href': fn:string($content/categories/a/@href) },
                    μ:content($content/categories/a)]
            ]
        ]
    ])
};

declare function app:basepage($items as array(*)?)
{
    'TODO'
};

declare function app:page($items as array(*)?)
{
    res:ok(μ:xml(
        ['h:html',
            ['h:head',
                ['h:meta', map { 'charset': 'utf-8' }],
                ['h:title', 'Fold &amp; Origami Example App'],
                ['h:meta', map { 'name': 'viewport', 'content': 'width=device-width, initial-scale=1'}],
                ['h:link', map { 'href': 'http://fonts.googleapis.com/css?family=Raleway:400,300,600', 'rel': 'stylesheet', 'type': 'text/css' }],
                ['h:link', map { 'rel': 'stylesheet', 'href': '/static/css/normalize.css' }],
                ['h:link', map { 'rel': 'stylesheet', 'href': '/static/css/skeleton.css' }],
                ['h:link', map { 'rel': 'stylesheet', 'href': '/static/css/custom.css' }],
                ['h:link', map { 'rel': 'icon', 'type': 'image/png', 'href': '/static/images/favicon.png' }]
            ],
            $items
        ]))
};