---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-8)"
date:   2015-8-24 6:00:00
description: Currently the login store's authenticate method does nothing much. Obviously it should try to login from Facebook. For this purpose we will use [facebook-chat-api](https://www.npmjs.com/package/facebook-chat-api). We will wrap actual calls to the "facebook-chat-api" inside our service classes. As of now I'm planning to use LoginService class for login, and ChatService to get the chat running.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
Currently the login store's authenticate method does nothing much. Obviously it should try to login from Facebook. For this purpose we will use
[facebook-chat-api](https://www.npmjs.com/package/facebook-chat-api). We will wrap actual calls to the "facebook-chat-api" inside our service 
classes. As of now I'm planning to use LoginService class for login, and ChatService to get the chat running.
</p>
Lets focus on login first for now.

Add following import in login.spec.tsx

```ts
import LoginService from '../../src/services/loginservice';
```

Then add following specs:

```ts
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
```
Similar to LoginAction class, LoginService will also have a method named "authenticate", since this method will involve communication over 
network it will return Promise.

npm:

```
npm install facebook-chat-api --save-dev
```

In "src/services" add new file named loginservice.ts

```ts
let electronRequire:Function = (global as any).electronRequire || require;

var login = electronRequire("facebook-chat-api");

export default class LoginService {
    authenticate(email: string, password: string): Promise<any> {
        return new Promise(function(resolve: Function, reject: Function) {
            login({ email, password }, function(err: any, api: any) {
                if (err) {
                    reject(err);
                } else {
                    resolve({ email, password, api });
                }
            });
        });
    }
}

```

Note that we are using "electronRequire", it is because facebook-chat-api package doesn't seems to work well with browserify.

Now lets integrate LoginService into LoginStore class.

```ts
import {Store} from 'delorean';
import LoginService from '../services/loginservice';

export interface ICredential {
    username: string;
    password: string;
}

export interface ILoginErrors {
    username: string;//validation error for username
    password: string;//validation error for password
    credential: string;//both username/password satisfies the validation requirements but is not registerd credential in facebook
}

export default class LoginStore extends Store {
    credential: ICredential;
    errors: ILoginErrors;
    isAuthenticated: boolean;
    isInProgress: boolean;
    loginService: LoginService;

    constructor() {
        super();
        this.loginService = new LoginService();
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
        this.isInProgress = true;
        this.emit('change');

        this.loginService.authenticate(this.credential.username, this.credential.password).then(function(response: any) {
            this.isAuthenticated = true;
            this.isInProgress = false;
            this.emit('change');
        }.bind(this)).catch(function(error: string) {
            this.isAuthenticated = false;
            this.isInProgress = false;
            this.errors = { username: "", password: "", credential: "Invalid username/password" };
            this.emit('change');
        }.bind(this));
    }

    getState() {
        return { credential: this.credential, errors: this.errors };
    }
}

```
Notice that we have imported LoginService into loginstore.ts, and instantiated the LoginSerivce in the constructor of the LoginStore class 
```js this.loginService = new LoginService();```. Then we are calling the authenticate method of LoginService in the "doLogin" method.

```ts
this.loginService.authenticate(this.credential.username, this.credential.password).then(function(response: any) {
    this.isAuthenticated = true;
    this.isInProgress = false;
    this.emit('change');
}.bind(this)).catch(function(error: string) {
    this.isAuthenticated = false;
    this.isInProgress = false;
    this.errors = { username: "", password: "", credential: "Invalid username/password" };
    this.emit('change');
}.bind(this));
```
Since, "LoginService.authenticate" takes two arguments username and password, we are passing them, and as it returns back a Promise we are 
chaining "then" and "catch" methods. The code-block in then method gets executed if login is successful, and the catch block gets executed in case
login fails.

You may have noticed that "bind" attached to each function, it is because of nature of javascript, each function has their own context and the 
keyword "this" may refer to different objects in different function. So, we are passing what "this" should means inside each function.

Another change to notice is "isAuthenticated" and "isInProgress" properties are added to the class. These properties can be used in UI, for example
depending upon "isInProgress" we may show loaders. "isAuthenticated" may be used to determine which interface to show.

With these changes in place now our login interface is quite workable, we will further polish the UX/UI but for now we want to establish basic
flow. Currently nothing happens even when login is successful. In next post we will start with showing the chatting interface.

Note on git.

I'm working directly on the master branch (bad), and committing at the end of each chapter (even bad), and syncing as soon as I commit.
