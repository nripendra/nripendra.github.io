---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-6)"
date:   2015-8-23 6:00:00
description: Lets establish a basic flow for our application. The initial thing that  user sees as soon as application is started is the login interface. Once user enters the credentials and is successfully validated, the user should see the chat interface. Chat interface will consist of the user's friend list, and the interface to type messages.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
Lets establish a basic flow for our application. The initial thing that  user sees as soon as application is started is
the login interface. Once user enters the credentials and is successfully validated, the user should see the chat interface.
    Chat interface will consist of the user's friend list, and the interface to type messages.
</p>

I'm not really a designer so here's basic wire frame
![wire-login.png](/assets/posts/fb-messenger-6/wire-login.png)

![wire-authenticated.png](/assets/posts/fb-messenger-6/wire-authenticated.png)

Lets start by writing some tests. We will be using jasmine and jsdom to write our tests. To begin with lets install
jasmine and jsdom.

```
npm install gulp-jasmine --save-dev
npm install jsdom --save-dev
tsd install jasmine
tsd install jsdom
```
Add following entries in the filesGlob section of tsconfig.json file.

```
"./tests/**/*.ts"
"./tests/**/*.tsx"
```
Your filesGlob should look something like this:

```
"filesGlob": [
        "./src/**/*.ts",
        "./src/**/*.tsx",
        "./tests/**/*.ts",
        "./tests/**/*.tsx",
        "./tools/typings/**/*.d.ts",
        "!./node_modules/**/*",
        "!./out/**/*",
        "!./tests/out/**/*",
        "!./electron/**/*"
]
```
<aside>
    Note: my initial plan was to write tests in js, so I didn't have filesGlob entires for test folder. But I
    noted that both jasmine and jsdom has definitelytyped entries, so I decided to use typescript itself.
</aside>


Now in "tests/specs" folder add a file named app.spec.tsx

```ts
/// <reference path="../../tools/typings/jasmine/jasmine.d.ts"/>
import App from '../../src/components/app';
import Login from '../../src/components/login';

import * as jsdom from 'jsdom';
let React = require('react/addons');
let ReactTestUtils = React.addons.TestUtils;

describe("App", () => {
    it("should show login form", () => {

        var myApp = React.render(<App />, document.body);
        expect(ReactTestUtils.scryRenderedComponentsWithType(myApp, Login).length).toBe(1);
    });

    beforeEach(function() {
        (global as any).document = jsdom.jsdom('<!doctype html><html><body></body></html>');
        (global as any).window = document.defaultView;
        (global as any).Element = (global as any).window.Element;
        (global as any).navigator = {
            userAgent: 'node.js'
        };
    });

    afterEach(function(done) {
        (global as any).document = null;
        (global as any).window = null;
        (global as any).Element = null;
        (global as any).navigator = {
            userAgent: 'node.js'
        };
        setTimeout(done)
    });
});

```
This code should have some compiler errors, as we don't have component named "Login" yet. As per rules for TDD consider
a compiler error as failure. To get rid of the compiler errors lets add the component first. For login interface, lets 
add a new file named "login.tsx" in "src/components" folder.

```ts
import * as React from 'react';

export default class Login extends React.Component<any, any> {
    render() {
        return (<form ref="loginForm">
                  <span ref="credentialError"></span>
                  <div>
                    <label>Username: </label>
                    <input type="email" required={true} ref="username" />
                    <span ref="usernameError"></span>
                  </div>
                  <div>
                    <label>Password: </label>
                    <input type="password" required={true} ref="password" />
                    <span ref="passwordError"></span>
                  </div>
                  <div>
                    <input type="button" value="Login" />
                  </div>
            </form>);
    }
}

```
Well the code is quite straight forward, it shows a login form, and adds placeholders to show various errors.
 
Time to run the test. To run test we need to build it first. Lets add two more gulp tasks:

require:

```js
jasmine = require('gulp-jasmine')
```

tasks:

```js
gulp.task('compile-test', function(){
    var sourceTsFiles = ["./tests/specs/**/*.{ts,tsx}",
    "./tools/typings/**/*.ts",
    "./src/**/*.{ts,tsx}",
    config.appTypeScriptReferences];

    var tsResult = gulp.src(sourceTsFiles)
        .pipe(tsc(tsconfig));

    tsResult.dts.pipe(gulp.dest("./tests/out/"));

    return tsResult.js
        .pipe(babel({stage: 0}))
        .pipe(gulp.dest("./tests/out/"))
});

gulp.task('test', ['compile-test'], function(){
    process.env.NODE_ENV = 'development';
    return gulp.src('./tests/out/tests/specs/**/*.js')
        .pipe(jasmine());
});
```
Note the line "process.env.NODE_ENV = 'development';", it is there because "React.addons.TestUtils" isn't available by
default, it is available only if NODE_ENV is not "production". If you are following this article from begining you should
already have babel in place, if you are not then do a "npm install gulp-bable --save-dev" and then add 
babel=require("gulp-babel"), somewhere at the begining of gulpfile.

To run test execute command "gulp test" in terminal. The test should fail.

![3.png](/assets/posts/fb-messenger-6/3.png)

Now lets make this test pass, change the app.tsx file we created earlier as follows:

```ts
import * as React from 'react';
import Login from './login';

export default class App extends React.Component<any, any> {
  render(){
    return (<Login />);
  }
}

```
After making this change, again running "gulp test" command should now show passed test
![4.png](/assets/posts/fb-messenger-6/4.png)

That's it!! now we have an app that shows login from. To see the output execute "gulp" command in the terminal.

![1.png](/assets/posts/fb-messenger-6/1.png)

In next post we will add some functionalities to the login form.