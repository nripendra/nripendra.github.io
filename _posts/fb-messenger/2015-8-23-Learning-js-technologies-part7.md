---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-7)"
date:   2015-8-23 6:00:00
description: Lets try adding some behaviour into the login form, we created in the previous post. To get the behaviour we want, we will follow the recommended pattern from Facebook i.e. Flux.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
Lets try adding some behaviour into the login form, we created in the previous post.
To get the behaviour we want, we will follow the recommended pattern from Facebook i.e. Flux. 
</p>
There are mainly 4 parts that makes up Flux:

- Store
- Dispatcher
- Action 
- View

We already have the View part, i.e. the App and Login components we have been creating so far. For other parts we will 
use delorean. To use delorean we will install it first.

```
npm install delorean --save-dev
```
For implementation of Flux, I'm following the recommendations from the following blog post (a must read if you haven't 
already done so):
[http://blog.andrewray.me/flux-for-stupid-people/](http://blog.andrewray.me/flux-for-stupid-people/)

Lets first create a store. We will be using concepts introduced in this post itself. Below are few quotes about stores 
concepts from the article:

> * A store is a singleton
> * Store then responds to the dispatched event.
> * A store is not a model. A store contains models.
> * Store emits an event, but not using the dispatcher
> * A store is the only thing in your application that knows how to update data
> * A store represents a single "domain" of your application.

Based on these quotes, here's what my plan is:

- We will create a singleton class named "AppStores", 
- We will create another class named LoginStore, and add a property named "loginStore" to AppStores class providing
access to LoginStore.
- Similarly we will keep adding other stores to AppStores as our application will require them.

# Lets start:
First add a file named "loginstore.ts" in "src/stores" folder.

```ts
import {Store} from 'delorean';

export interface ICredential {
    username: string;
    password: string;
}

export interface ILoginErrors {
    username: string;//validation error for username
    password: string;//validation error for password
    credential: string;//both username/password satisfies the validation requirements but is not registered credential in Facebook
}

export default class LoginStore extends Store {
    credential: ICredential;
    errors: ILoginErrors;

    constructor() {
        super();
        this.reset();
    }

    get actions() {
        return {
            'authenticate': 'doLogin',
            'setErrors': 'setErrors',
            'reset': 'reset'
        };
    }

    reset() {
        this.errors = { username: "", password: "", credential: "" };
        this.credential = { username: "", password: "" };
        this.emit('change');
    }

    setErrors(errors: ILoginErrors) {
        this.errors = errors;
        console.log(this.errors);
        this.emit('change');
    }

    doLogin(credential: ICredential) {
        this.errors = { username: "", password: "", credential: "" };
        this.credential = credential;
        console.log(this.credential);
        this.emit('change');
    }

    getState() {
        return { credential: this.credential, errors: this.errors };
    }
}

```
With this if we try to build the system using "gulp" command, then we will get an error "Cannot find module 'delorean'".
![2.png](/assets/posts/fb-messenger-6/2.png)

But we just installed delorean!! What's happening? Well just having installed npm package isn't enough, we also need a
typescript definition for delorean. But, we have a problem. There is no typescript definition for delorean that I could
find. So, I manually created it. Heres how:
In "tools/typings" folder create a folder named "delorean", and inside this folder add a file named "delorean.d.ts" with
following content.

```ts
declare module Flux {
    interface IListener {
        removeListener(event: string, callback: Function): void;
    }

    class Store {
        emit(ev: string): any;
        listener: IListener
        getState(): any;
        onChange(callback: Function): void;
    }

    class Dispatcher {
        static dispatcher: Dispatcher;

        stores: { [key: string]: Store; };

        constructor(args: any);

        dispatch(key: string, payload?: any): void;

        on(event: string, callback: Function): void;
    }
}

declare module "delorean" {
    export = Flux;
}
```
Well this is not a complete definition, but will serve our purpose. Once this file is added we can try running gulp 
again. That error related to delorean should now be gone.

Now that We have login store in place, lets add another file named "appstores.ts" in "src" folder.

```ts
import LoginStore from './stores/loginstore';

var AppStores = {
  'loginStore': new LoginStore()
};

export default AppStores;
```

Now, lets create a dispatcher which should be a singleton. To create dispatcher we will add a file named 
"AppDispatcher.ts" in "src" folder.

```ts
import {Dispatcher} from 'delorean';
import AppStores from './appstores';

Dispatcher.dispatcher = new Dispatcher(AppStores);
export default Dispatcher.dispatcher;
```
In above code we saw that a Delorean dispatcher accepts a dictionary of stores in it's constructor, based on this I 
concluded that my decisions regarding AppStores is correct. AppStores does serve as singleton which in itself isn't a 
model but rather contains a model (login store). Only thing that is different here is the fact that its not the app
store that listens dispatcher or emits event, it is the login store, so this does confuse me, any recommendation/suggestion
is welcome.

Another thing to notice is the use of "Dispatcher.dispatcher", it is something that delorean themselves do when creating
a dispatcher using their API DeLorean.Flux.createDispatcher(). Since I wanted to stay more on es6/7 syntax side, I'm
directly assigning it.

Now to relate the view and store, we need actions. In "src/actions" folder lets add a file named "loginactions.ts"

```ts
import dispatcher from '../appdispatcher';
import {ILoginErrors, ICredential} from "../stores/loginstore";

export default {
    authenticate(credential: ICredential): void {
        dispatcher.dispatch('authenticate', credential);
    },
    setErrors(errors: ILoginErrors): void {
        dispatcher.dispatch('setErrors', errors);
    },
    reset(): void {
        dispatcher.dispatch('reset', null);
    }
};

```

Well in my understanding, actions are nothing more than a user friendly wrapper arround dispatcher.dispatch() method. 
Only thing that we do normally see in flux examples but I'm not using here is the constants for action names. It can be
done, and probably I'll do it in future. But the way delorean works, as you might have noticed in loginstore code above,
I think code looks clean and maintainable even without constants.

> Your View Responds to the "Change" Event

Along with action to get communication from view to store, we also need view to listen changes in store. If you have noticed
the loginstore code above, most of the function has statement "this.emit('change')".
For the purpose of listening changes in store, delorean does provide a special react mixing. But mixing has been 
depreciated by Facebook and no more supported in es6 syntax. The recommendation for such scenarios is to use 
"Higher order components". We will achieve "Higher order components" using decorator.

In "src/decorators" folder add a file named "connectToStores.tsx":

```ts
import * as React from 'react';
import {Dispatcher, Store} from 'delorean';

//poly-fill for Object.assign..
//Shamelessly copied from https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
if (!Object.assign) {
    Object.defineProperty(Object, 'assign', {
        enumerable: false,
        configurable: true,
        writeable: true,
        value: function(target: any) {
            'use strict';
            if (target === undefined || target === null) {
                throw new TypeError('Cannot convert first argument to object');
            }

            var to = Object(target);
            for (var i = 1; i < arguments.length; i++) {
                var nextSource = arguments[i];
                if (nextSource === undefined || nextSource === null) {
                    continue;
                }
                nextSource = Object(nextSource);

                var keysArray = Object.keys(Object(nextSource));
                for (var nextIndex = 0, len = keysArray.length; nextIndex < len; nextIndex++) {
                    var nextKey = keysArray[nextIndex];
                    var desc = Object.getOwnPropertyDescriptor(nextSource, nextKey);
                    if (desc !== undefined && desc.enumerable) {
                        to[nextKey] = nextSource[nextKey];
                    }
                }
            }
            return to;
        }
    });
}

export default function connectToStore(watchedStores?: Array<string>): Function {
    return function(ComposedComponent: any): any {
        return class ConnectedComponent extends React.Component<any, any> {
            stores: { [key: string]: Store; }; //dictionary of string and Store
            storesDidChange: boolean;
            watchStores: Array<string>;//array of name of stores to watch.
            __watchStores: { [key: string]: Store; };//dictionary of string and Store (subset of this.stores)
            __changeHandlers: { [key: string]: Function; };
            __dispatcher: Dispatcher;

            constructor() {
                super();
                this.__dispatcher = Dispatcher.dispatcher;
                this.state = this.getStoreStates();
                this.watchStores = watchedStores;
            }

            getStoreStates(): any {
                var state = { stores: {} }, store: any;
                /* Set `state.stores` for all present stores with a `setState` method defined. */
                for (var storeName in this.__watchStores) {
                    if (Object.prototype.hasOwnProperty.call(this.stores, storeName)) {
                        state.stores[storeName] = this.__watchStores[storeName].getState();
                    }
                }
                return state;
            }

            // After the component mounted, listen changes of the related stores
            componentDidMount() {

                var self = this, store: Store, storeName: string;

                // If `storesDidChange` method presents, it'll be called after all the stores
                // were changed.
                if (this.props.storesDidChange) {
                    this.__dispatcher.on('change:all', function() {
                        self.props.storesDidChange();
                    });
                }

                // Since `dispatcher.stores` is harder to write, there's a shortcut for it.
                // You can use `this.stores` from the React component.
                this.stores = this.__dispatcher.stores;
                this.__watchStores = {};

                if (typeof this.watchStores != "undefined" && this.watchStores != null) {
                    for (var i = 0; i < this.watchStores.length; i++) {
                        storeName = this.watchStores[i];
                        this.__watchStores[storeName] = this.stores[storeName];
                    }
                } else {
                    this.__watchStores = this.stores;
                    if (console != null && Object.keys != null && Object.keys(this.stores).length > 4) {
                        console.warn('Your component is watching changes on all stores, you may want to define a "watchStores" property in order to only watch stores relevant to this component.');
                    }
                }

                /* `__changeHandler` is a **listener generator** to pass to the `onChange` function. */
                function __changeHandler(store: any, storeName: string) {
                    return function() {
                        var state: any, args: Array<any>;
                        /* If the component is mounted, change state. */
                        self.setState(self.getStoreStates());
                        // When something changes it calls the components `storeDidChanged` method if exists.
                        if (self.props.storeDidChange) {
                            args = [storeName].concat(Array.prototype.slice.call(arguments, 0));
                            self.props.storeDidChange.apply(self, args);
                        }
                    };
                }

                // Remember the change handlers so they can be removed later
                this.__changeHandlers = {};

                /* Generate and bind the change handlers to the stores. */
                for (storeName in this.__watchStores) {
                    if (Object.prototype.hasOwnProperty.call(this.stores, storeName)) {
                        store = self.stores[storeName];
                        self.__changeHandlers[storeName] = __changeHandler(store, storeName);
                        store.onChange(self.__changeHandlers[storeName]);
                    }
                }
            }

            // When a component unmounted, it should stop listening.
            componentWillUnmount() {
                for (var storeName in this.__changeHandlers) {
                    if (Object.prototype.hasOwnProperty.call(this.stores, storeName)) {
                        var store = this.stores[storeName];
                        store.listener.removeListener('change', this.__changeHandlers[storeName]);
                    }
                }
            }

            render() {
                var props = Object.assign({}, this.props, this.state);
                return (<ComposedComponent {...props} />);
            }
        }
    }
}


```
Most of the above code is directly copied from delorean's "storeListener" mixin, and modified as required to create 
higher order component instead of mixin. This decorator hijacks the actual component, and wraps it around a special
component which listens to store change events. It also allows to filter which stores we want to listen.

To use this decorator we will change the content of app.tsx as follows.

```ts
import * as React from 'react';
import Login from './login';
import connectToStore from '../decorators/connectToStores';

@connectToStore(['loginStore'])
export default class App extends React.Component<any, any> {
  render(){
    return (<Login />);
  }
}

```

Yeah! that's it, just added "@connectToStore(['loginStore'])" line above the class decleration. This will allow us to 
listen the changes in login store, by composing the actual App component inside a higher order component. Now we will 
make the changes in loginStore reflect in the login component.

```ts
import * as React from 'react';
import Login from './login';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';

@connectToStore(['loginStore'])
export default class App extends React.Component<any, any> {
    render() {
        return (<Login store={AppStores.loginStore} />);
    }
}

```
Yes, that's it we are passing a property named "store" to login component, and passing 'AppStores.loginStore' as its value.
Now, lets add jasmine specification for the login interface, inside "tests/specs" folder add "login.spec.tsx" file.

```ts
/// <reference path="../../tools/typings/jasmine/jasmine.d.ts"/>
import Login from '../../src/components/login';
import AppStores from '../../src/appstores';

import * as jsdom from 'jsdom';
let React = require('react/addons');
let ReactTestUtils = React.addons.TestUtils;

describe("Login", () => {
    it("should show login from controls", () => {
        var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);
        expect(ReactTestUtils.scryRenderedDOMComponentsWithTag(loginForm, "input").length).toBe(3);
    });

    it("should show validation errors when there are values in errors property of loginStore", () => {

        AppStores.loginStore.setErrors({
            username: "Username cannot be empty",
            password: "password cannot be empty",
            credential: ""
        });
        var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);
        expect(React.findDOMNode(loginForm.refs["usernameError"]).innerHTML.length).toBeGreaterThan(0);
        expect(React.findDOMNode(loginForm.refs["passwordError"]).innerHTML.length).toBeGreaterThan(0);
        expect(React.findDOMNode(loginForm.refs["credentialError"]).innerHTML.length).toBe(0);
    });

    beforeEach(function() {
        (global as any).document = jsdom.jsdom('<!doctype html><html><body></body></html>');
        (global as any).window = document.defaultView;
        (global as any).Element = (global as any).window.Element;
        //(global as any).HTMLFormElement = (global as any).window.HTMLFormElement;
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

Now let's make this test pass by changing the login component as follows:

```ts
import * as React from 'react';
import LoginStore, {ICredential, ILoginErrors} from "../stores/loginstore";
import LoginActions from '../actions/loginactions';

export class LoginProps {
    store: LoginStore
}

export default class Login extends React.Component<LoginProps, any> {
    constructor(props: LoginProps) {
        super();
        this.props = props;
    }

    render() {
        var store = this.props.store;
        return (<form ref="loginForm">
                  <span ref="credentialError" dangerouslySetInnerHTML={{ __html: store.errors.credential }}></span>
                  <div>
                    <label>Username: </label>
                    <input type="email" required={true} ref="username" />
                    <span ref="usernameError" dangerouslySetInnerHTML={{ __html: store.errors.username }}></span>
                  </div>
                  <div>
                    <label>Password: </label>
                    <input type="password" required={true} ref="password" />
                    <span ref="passwordError"  dangerouslySetInnerHTML={{ __html: store.errors.password }}></span>
                  </div>
                  <div>
                    <input type="button" value="Login" ref="btnLogin" />
                  </div>
            </form>);
    }
}

```
Note that this time I'm using dangerouslySetInnerHTML, it is because I couldn't get the test pass without doing so. It 
works fine in electron though. Any Reactjs expert willing to explain this behaviour?

Lets add logic for login button. Basically login button should call "LoginActions.authenticate" if form is valid and 
"LoginActions.setErrors" if invalid. To add logic I'm adding following two test cases in login spec.

```ts
    it("should call authenticate when login button is clicked, and form is valid", () => {
        //jsdom doesn't support html5 checkValidity..
        //tried pollyfilling using H5F, but react doesn't like it.
        HTMLFormElement.prototype.checkValidity = () => true;

        spyOn(LoginActions, 'authenticate')
        var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);

        ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));

        expect(LoginActions.authenticate).toHaveBeenCalled();
    });

    it("should call setErrors when login button is clicked, and form is invalid", () => {
        //jsdom doesn't support html5 checkValidity..
        //tried pollyfilling using H5F, but react doesn't like it.
        HTMLFormElement.prototype.checkValidity = () => false;

        spyOn(LoginActions, 'setErrors')
        var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);

        ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));

        expect(LoginActions.setErrors).toHaveBeenCalled();
    });
```

Lets now add code to get this test passed:

```ts
import * as React from 'react';
import LoginStore, {ICredential, ILoginErrors} from "../stores/loginstore";
import LoginActions from '../actions/loginactions';

export class LoginProps {
    store: LoginStore
}

export default class Login extends React.Component<LoginProps, any> {
    constructor(props: LoginProps) {
        super();
        this.props = props;
    }

    dologin() {
        var form = (React.findDOMNode(this.refs["loginForm"]) as HTMLFormElement);
        var txtUsername = (React.findDOMNode(this.refs["username"]) as HTMLInputElement);
        var txtPassword = (React.findDOMNode(this.refs["password"]) as HTMLInputElement);
        var username = txtUsername.value;
        var password = txtPassword.value;

        if (form.checkValidity()) {
            LoginActions.authenticate({ username, password });
        } else {
            LoginActions.setErrors({
                username: txtUsername.validationMessage,
                password: txtPassword.validationMessage,
                credential: ""
            });
        }
    }

    render() {
        var store = this.props.store;
        return (<form ref="loginForm">
                  <span ref="credentialError" dangerouslySetInnerHTML={{ __html: store.errors.credential }}></span>
                  <div>
                    <label>Username: </label>
                    <input type="email" required={true} ref="username" />
                    <span ref="usernameError" dangerouslySetInnerHTML={{ __html: store.errors.username }}></span>
                  </div>
                  <div>
                    <label>Password: </label>
                    <input type="password" required={true} ref="password" />
                    <span ref="passwordError"  dangerouslySetInnerHTML={{ __html: store.errors.password }}></span>
                  </div>
                  <div>
                    <input type="button" value="Login" ref="btnLogin" onClick={this.dologin.bind(this) } />
                  </div>
            </form>);
    }
}
```

In summary what we are doing is, calling dologin when user clicks Login button, and displaying
the errors. Inside dologin method, we either call LoginActions.authenticate() or LoginActions.setErrors() based on
the form's validity. For validation we are using native html5 validation mechanism. FYI, this is my interpretation of 
**"pure component"** as explained here: 
[http://blog.mgechev.com/2015/05/15/flux-in-depth-overview-components/](http://blog.mgechev.com/2015/05/15/flux-in-depth-overview-components/)
(another must read article). Not sure if this captures the author's POV of pure component, but from my understanding so
far it does satisfy the requirement for pure component.
 
App component as we can see isn't a pure component yet. It is accessing "AppStores" which is a global state. May be
we can pass AppStores to App component through it's property. Probably sometime in future I'll try to re-factor this 
code to make App component too pure.


