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
            <h>Need help getting started?</h>
            <p>Learn how to build web applications using Origami and Fold.</p>
            <a href="http://xokomola.com">View tutorials</a>
        </help>
        <categories>
            <h>Demos</h>
            <p>Try out various demos</p>
            <a href="/math/sum/10/20">Start now!</a>
        </categories>
    </page>;
    
(: ---- /math service ---- :)

declare function app:routes()
{
    route:route($app:routes)
};

declare variable $app:routes := (
    context('/math', $app:sum-routes),
    GET('/', function($req) {
        app:landing-page($app:landing-content) 
    })    
);

declare variable $app:sum-routes := (
    GET(('/sum/{a}/{b}', map { 'a': '\d+', 'b': '\d+' }),
        ('a|integer', 'b|integer'),
        app:sum#2)
);

declare function app:sum($x as xs:integer, $y as xs:integer) { 
    'Sum is: ' || $x + $y
};

declare function app:landing-page($content)
{
    app:page(['h:body',
        ['h:div', map { 'class': 'section hero' },
            ['h:div', map { 'class': 'container' },
                ['h:div', map { 'class': 'row' },
                    ['h:div', map { 'class': 'one-half column' },
                        ['h:h4', map { 'class': 'hero-heading' },
                            μ:content($content/hero/h)],
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