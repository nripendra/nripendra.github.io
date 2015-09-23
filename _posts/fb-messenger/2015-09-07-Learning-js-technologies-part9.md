---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-9)"
date:   2015-9-7 6:00:00
description: In previous post we added functionality for login. Now user can enter their facebook username and password and get authenticated. Next step is to show chatting screen as soon as login is successful. But due to the way "facebook-chat-api" and Flux works, I'm quite confused. After login is successful we get "api" object in the callback
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    In previous post we added functionality for login. Now user can enter their facebook username and password and get authenticated. Next step is
    to show chatting screen as soon as login is successful. But due to the way "facebook-chat-api" and Flux works, I'm quite confused. After
    login is successful we get "api" object in the callback. For any further communication we need this "api" object. My plan is to have a
    separate store and services for chat interface. And confusion is over how loginStore should pass the "api" object to chatStore? As per flux
    model the communication flow should always be one-way, from view -> action -> dispatcher -> store -> view. But here we need to pass data from
    one store to next. May be I'm mis-understanding the concept of store here.
</p>

My solution here is to save "api" object as a property of loginStore, and pass it as a property of chat component when rendering. Here's what my
plan is:

```ts
return (<Chat store={AppStores.chatStore} api={AppStores.loginStore.api} />);
```
Once the Chat component has access to api, it can further pass it to chatstore using an action. So, lets start by adding api property to LoginStore.

```ts
//Add this line somewhere in class body
//In my case, I'm putting where all other properties are listed, 
//i.e. before constructor

api: any;
```
Now, lets assign the api property. We will do it inside dologin method as follows.

```ts
doLogin(credential: ICredential) {
    this.errors = { username: "", password: "", credential: "" };
    this.credential = credential;
    this.isInProgress = true;
    this.emit('change');

    this.loginService.authenticate(this.credential.username, this.credential.password).then(function(response: any) {
        this.isAuthenticated = true;
        this.isInProgress = false;

        this.api = response.api;//here..

        this.emit('change');
    }.bind(this)).catch(function(error: string) {
        this.isAuthenticated = false;
        this.isInProgress = false;
        this.errors = { username: "", password: "", credential: "Invalid username/password" };
        this.emit('change');
    }.bind(this));
}
```

lets add a ChatService class. In "src/services" folder add a file named "chatservice.ts"

```ts
import {EventEmitter} from 'events';

export interface IMessage {
    body: string;
    sticker: string;
    attachment: any;
}

export default class ChatService {
    api: any;
    listener: EventEmitter;

    constructor(api: any) {
        this.api = api;
        this.listener = new EventEmitter();
        this.api.setOptions({ selfListen: true, listenEvents: true, updatePresence: true });
    }

    get currentUserId(): string {
        return this.api.getCurrentUserId();
    }

    getFriendList(): Promise<Array<any>> {
        var api = this.api;
        return new Promise(function(resolve: Function, reject: Function) {
            api.getFriendsList(api.getCurrentUserId(), function(err: any, data: Array<any>) {
                if (err) {
                    reject(err);
                } else {
                    api.getUserInfo(data, function(err: any, ret: Array<any>) {
                        if (err) {
                            reject(err);
                        } else {
                            resolve(ret);
                        }
                    });
                }

            });
        });

    }

    sendMessage(message: IMessage, threadId: string): Promise<any> {
        return new Promise<any>(function(resolve: Function, reject: Function) {
            this.api.sendMessage(message, threadId, function(err: any, obj: any) {
                if (err) {
                    reject(err);
                } else {
                    resolve(obj);
                }
            });
        }.bind(this));
    }

    markAsRead(threadId: string): Promise<any> {
        return new Promise<any>(function(resolve: Function, reject: Function) {
            this.api.markAsRead(threadId, function(err: any) {
                if (err) {
                    reject(err);
                } else {
                    resolve(true);
                }
            });
        }.bind(this));
    }

    listen() {
        var api = this.api;

        api.listen(function(err: any, event: any, stopListening: Function) {
            if (err) {
                this.listener.emit('error', err, stopListening);
            } else {
                this.listener.emit(event.type, event, stopListening);
            }
        }.bind(this));
    }
}
```

Nothing special, just wrapping api object provided by "facebook-chat-api", and providing user friendly interfaces like promise and event emitter.
Let's add a new store named "ChatStore".

```ts
import {Store} from 'delorean';
import ChatService from '../services/chatservice';
import {EventEmitter} from 'events';

export default class ChatStore extends Store {
    private api: any;
    private chatService: ChatService;
    currentUserId: string;
    currentChatThread: string;
    error: any;
    friendList: Array<any>;
    messages: { [chatThreadId: string]: Array<any> };//Dictionary<string, Array<any>>

    get actions() {
        return {
            'initApi': 'loadFriendList',
            'setCurrentChatThread': 'setCurrentChatThread'
        };
    }

    loadFriendList(api: any) {
        this.api = api;
        this.chatService = new ChatService(api);
        this.currentUserId = this.chatService.currentUserId;

        this.chatService.getFriendList().then(function(data: Array<any>) {
            this.friendList = data;
            this.emit('change');
            this.listen();
        }.bind(this)).catch(function(err: any) {
            this.error = err;
            this.emit('change');
        }.bind(this));
    }

    setCurrentChatThread(chatThread: string) {
        this.currentChatThread = chatThread;
        this.emit('change');
    }

    listen() {
        this.chatService.listen();

        this.chatService.listener.on('error', function(error: any, stopListening: Function) {
            console.log(error);
        }.bind(this));

        this.chatService.listener.on('message', function(event: any, stopListening: Function) {
            console.log(event);
        }.bind(this));

        this.chatService.listener.on('event', function(event: any, stopListening: Function) {
            console.log(event);
        }.bind(this));

        this.chatService.listener.on('presence', function(event: any, stopListening: Function) {
            console.log(event);
        }.bind(this));
    }
}
```
Frankly, at this point I'm not very sure about the structures of various event objects given by "facebook-chat-api". I'm simply basing my code on
the documentation on their site.

Add another property named "chatStore" in AppStores..

```ts
import LoginStore from './stores/loginstore';
import ChatStore from './stores/chatstore';

var AppStores = {
    'loginStore': new LoginStore(),
    'chatStore': new ChatStore()
};

export default AppStores;
```

Lets map the chatstore services to actions. Add a new file named  "chatactions.ts" inside "src/actions/".

```ts
import dispatcher from '../appdispatcher';
import {ILoginErrors, ICredential} from "../stores/loginstore";

export default {
    initApi(api: any): void {
        dispatcher.dispatch('initApi', api);
    },
    setCurrentChatThread(chatThread: string): void {
        dispatcher.dispatch('setCurrentChatThread', chatThread);
    }
};


```

Add new component "Chat".

```ts
import * as React from 'react';
import ChatStore from '../stores/chatstore';
import ChatActions from '../actions/chatactions';

export class ChatProps {
    api: any;
    store: ChatStore
}

export default class Chat extends React.Component<ChatProps, any> {
    constructor(props: ChatProps) {
        super();
        this.props = props;
        ChatActions.initApi(this.props.api);
    }

    render() {
        return (<span>Welcome to chat</span>);
    }
}

```
Now, lets integrate this chat component in our main component (i.e. App component).

Start by adding a test case in app.spec.tsx:

```ts
it("should show chat component when loginStore.isAuthenticated is true", () => {
    AppStores.loginStore.isAuthenticated = true;
    AppStores.loginStore.api =
    {
        setOptions: () => { },
        getCurrentUserId: () => { return "123" },
    };
    var myApp = React.render(<App />, document.body);
    expect(ReactTestUtils.scryRenderedComponentsWithType(myApp, Chat).length).toBe(1);
});
```

To get it passed let's change the code for App:

```ts
import * as React from 'react';
import Login from './login';
import Chat from './chat';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';

@connectToStore(['loginStore'])
export default class App extends React.Component<any, any> {
    render() {

        if (!AppStores.loginStore.isAuthenticated) {
            return (<Login store={AppStores.loginStore} />);
        } else {
            return (<Chat store={AppStores.chatStore} api={AppStores.loginStore.api} />);
        }
    }
}
```

Oops!! test didn't pass! Well the fix we did earlier using "dangerouslySetInnerHTML" in login component doesn't seem to work anymore now. I even
posted the issue in github [here](https://github.com/facebook/react/issues/4740). The solution they suggested is to get dom initialized before 
requiring react. But looking at my test codes I have already done so. After spending many hours, trying to get test run with phantom-js and 
failing, tried  using shallow renderer but it seems to be quite in initial state as of now. I decided to debug the test. There is no good tool 
for the purpose! So, what I did? Well same old console.log(). After couple of changes, and console.logs I came to 
conclusion that the two suits "app" and "Login" are interleaving i.e. jasmine is running a test while another test is still in progress. Hmm!! 
javascript is single threaded so I got confused, and googled about it. After visiting few posts it seemed it can happend if asynchronous tests 
takes long time. Well I didn't think my tests were doing anything significant for such case to occur. But, as I was already theorizing that the 
issue is due to interleaving. There's nothing wrong with experimenting??  Right?? So I commented out everything in app.specs.tsx, and copied the 
test cases and desired imports in app.specs.tsx to login.specs.tsx. Voila! all test passing!!

So, till now this does seem to be the solution. But I didn't want to clutter my test suit will all the specs in single suit :( Then I searched 
if nesting suits is possible in jasmine? The answer: a resounding [YES!](https://www.safaribooksonline.com/library/view/javascript-testing-with/9781449356729/_nested_suites.html)

So, I changed the login.specs.tsx as follows:

```ts
/// <reference path="../../tools/typings/jasmine/jasmine.d.ts"/>
import App from '../../src/components/app';
import Chat from '../../src/components/chat';

import Login from '../../src/components/login';
import AppStores from '../../src/appstores';
import LoginActions from '../../src/actions/loginactions';
import LoginService from '../../src/services/loginservice';

import * as jsdom from 'jsdom';
let React: any = null;
let ReactTestUtils: any = null;
console.log("describing Login");
describe("fb-messenger", () => {
    describe("app", () => {
        it("should show login form", () => {
            AppStores.loginStore.isAuthenticated = false;
            var myApp = React.render(<App />, document.body);
            expect(ReactTestUtils.scryRenderedComponentsWithType(myApp, Login).length).toBe(1);
        });

        it("should show chat component when loginStore.isAuthenticated is true", () => {
            AppStores.loginStore.isAuthenticated = true;
            AppStores.loginStore.api =
            {
                setOptions: () => { },
                getCurrentUserId: () => { return "123" },
            };
            var myApp = React.render(<App />, document.body);
            expect(ReactTestUtils.scryRenderedComponentsWithType(myApp, Chat).length).toBe(1);
        });
    });

    describe("login", () => {
        it("should show login from controls", () => {
            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);
            expect(ReactTestUtils.scryRenderedDOMComponentsWithTag(loginForm, "input").length).toBe(3);
        });

        it("should show validation errors when there are values in errors property of loginStore", () => {
            AppStores.loginStore.isAuthenticated = false;
            AppStores.loginStore.setErrors({
                username: "Username cannot be empty",
                password: "password cannot be empty",
                credential: ""
            });

            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);
            expect(React.findDOMNode(loginForm.refs["usernameError"]).innerHTML).toEqual("Username cannot be empty");
            expect(React.findDOMNode(loginForm.refs["passwordError"]).innerHTML).toEqual("password cannot be empty");
            expect(React.findDOMNode(loginForm.refs["credentialError"]).innerHTML.length).toBe(0);
        });

        it("should call authenticate when login button is clicked, and form is valid", () => {
            //jsdom doesn't support html5 checkValidity..
            //tried pollyfilling using H5F, but react doesn't like it.
            HTMLFormElement.prototype.checkValidity = () => true;

            spyOn(LoginActions, 'authenticate');
            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);
            ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));
            expect(LoginActions.authenticate).toHaveBeenCalled();
        });

        it("should call setErrors when login button is clicked, and form is invalid", () => {
            //jsdom doesn't support html5 checkValidity..
            //tried pollyfilling using H5F, but react doesn't like it.
            HTMLFormElement.prototype.checkValidity = () => false;

            spyOn(LoginActions, 'setErrors');

            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);

            ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));

            expect(LoginActions.setErrors).toHaveBeenCalled();
        });

        it("should call LoginService.authenticate when login button is clicked, and form is valid", () => {
            HTMLFormElement.prototype.checkValidity = () => true;

            //We don't actually want to hit facebook in our unit test
            spyOn(LoginService.prototype, 'authenticate').and.returnValue(Promise.resolve({}));

            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);

            ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));

            expect(LoginService.prototype.authenticate).toHaveBeenCalled();
        });

        it("should warn user when username/password is wrong", (done: Function) => {
            HTMLFormElement.prototype.checkValidity = () => true;

            var rejected = Promise.reject({});
            spyOn(LoginService.prototype, 'authenticate').and.returnValue(rejected);

            var loginForm = React.render(<Login store={AppStores.loginStore} />, document.body);

            ReactTestUtils.Simulate.click(React.findDOMNode(loginForm.refs["btnLogin"]));

            expect(LoginService.prototype.authenticate).toHaveBeenCalled();

            setTimeout(function() {
                rejected.catch(function() {
                    expect(AppStores.loginStore.errors.credential).toEqual("Invalid username/password");
                    done();
                })
            }, 10);
        });
    });

    beforeEach(function() {
        (global as any).document = jsdom.jsdom('<!doctype html><html><body></body></html>');
        (global as any).window = document.defaultView;
        (global as any).Element = (global as any).window.Element;
        (global as any).HTMLFormElement = (global as any).window.HTMLFormElement;
        (global as any).navigator = {
            userAgent: 'node.js'
        };

        React = require('react/addons');

        ReactTestUtils = React.addons.TestUtils;
    });

    afterEach(function(done) {
        React.unmountComponentAtNode(document.body)
        React = null;
        ReactTestUtils = null;
        (global as any).document.body.innerHTML = "";
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

And all the tests passing without any problem! Again I tried removing the "dangerouslySetInnerHTML" from login.tsx:

```ts
import * as React from 'react';
import LoginStore, {ICredential, ILoginErrors} from "../stores/loginstore";
import LoginActions from '../actions/loginactions';
import AppStores from '../appstores';

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
                  <span ref="credentialError">{store.errors.credential}</span>
                  <div>
                    <label>Username: </label>
                    <input type="email" required={true} ref="username" />
                    <span ref="usernameError">{store.errors.username}</span>
                  </div>
                  <div>
                    <label>Password: </label>
                    <input type="password" required={true} ref="password" />
                    <span ref="passwordError">{store.errors.password}</span>
                  </div>
                  <div>
                    <input type="button" value="Login" ref="btnLogin" onClick={this.dologin.bind(this) } />
                  </div>
            </form>);
    }
}

```

And all the tests still passing!

After these very mind tiring debugging session, now we get "Welcome to chat" screen as soon as we login. If you observe the dev console of our application, you will
see various events occuring in your facebook chat. If someone sends you message, it should also be present in the console.

![01.png](/assets/posts/fb-messenger-9/01.png)

Although the tests are organized into nested suits, I'm still not very convinced to dump all the test suits into single file. So, I'm  planning to
use gulp to do the dirty stuff. I'll write the suits in different files as I originally intended to, and make a gulp task to create
nested suits out of the separate spec files. This will be something I'll do in future, I'll document about this if successful, let's see how it
goes.