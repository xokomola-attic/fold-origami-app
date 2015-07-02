xquery version "3.0";

module namespace demo = 'http://xokomola.com/xquery/origami/templating/demos';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../../origami/core.xqm';
import module namespace ui = 'http://xokomola.com/xquery/origami/demo/ui'
    at '../../ui.xqm';
(: TODO: split into view and controller :)
import module namespace req = 'http://xokomola.com/xquery/fold/request'
    at '../../fold/core/request.xqm';
import module namespace res = 'http://xokomola.com/xquery/fold/response'
    at '../../fold/core/response.xqm';
import module namespace router = 'http://xokomola.com/xquery/fold/router'
    at '../../fold/core/router.xqm';
    
declare variable $demo:ex1-template :=
    <ul>
        <li>item</li>
        <li>item</li>
        <li>item</li>
    </ul>;

(: ISSUE: matching nodes the second rule may match even if the first is more specific :)
(: ISSUE: I think I need something like xf:clone($n, $it) :)
(: FIXED: xf namespace and xf:node attribute is copied as well :)
declare variable $demo:ex1-code := 
    xf:template(
        $demo:ex1-template, 
        (
            ['li[1]',
                function($n, $c) {
                    for $i in 1 to $c
                    return $n => xf:content(concat($n/text(),' ',$i))
                }
            ],
            ['li[position() gt 1]', ()]
        ),
        function($x as xs:integer) { $x }
    );

declare variable $demo:app := (
    router:GET('/{name}', function($req) { res:ok($ui:base-page(demo:app(req:get-param($req, 'name')))) }),
    router:GET('/', function($req) { res:ok($ui:base-page(demo:app())) })
);

declare function demo:app()
{
    demo:app(())
};

declare function demo:app($name as xs:string?)
{
    let $demo-xml := xf:xml-resource(concat(file:base-dir(),'demos.xml'))/demos
    let $selected-demo := ($demo-xml/demo[@name = $name], $demo-xml/demo[1])[1]
    let $demo-name := string($selected-demo/@name)
    return
        (
            ['h:div', ['h:p']],
            ['h:div', map { 'class': 'tabs' },
                for $demo in $demo-xml/demo
                return
                    ['h:a', 
                        map { 
                            'class': ('button', ' ', if ($demo/@name = $demo-name) then 'button-primary' else ()), 
                            'href': concat('/demo/templates/', $demo/@name) }, $demo/title]
            ],
            let $demo := $selected-demo
            return
                ['h:div', map { 'class': 'example' },
                    ['h:div', map { 'class': 'row' },
                        ['h:div', map { 'class': 'one-half column' }, 
                            ['h:pre', serialize($demo/source/template/node())]], 
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
