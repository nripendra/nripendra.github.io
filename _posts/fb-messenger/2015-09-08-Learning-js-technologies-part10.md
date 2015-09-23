---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-10)"
date:   2015-9-8 6:00:00
description: Let's create a layout component that would enable us to organize our components in terms of hbox and vbox. You'll find an example of these layout rules
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    Let's create a layout component that would enable us to organize our components in terms of hbox and vbox. You'll find an example of these
    layout rules <a href="https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XUL/Tutorial/The_Box_Model">here</a>. Don't be lazy please go ahead and click
    the link! I'll be waiting...
</p>
If you did actually went through the article it would be quite clear how hbox and vbox components can make our life easy when it comes to laying
out our components. Add a file named "layout.tsx" in src/components folder.

```ts
import * as React from 'react';

/**
 * Style
 * @ref: https://gist.github.com/Munawwar/7926618
 */
export var Style: any = {
   merge(target: any, ...source: any[]) {
        var from:any;
        var keys:Array<string>;
        var to = Object(target);

        for (var s = 1; s < source.length; s++) {
            from = source[s];
            keys = Object.keys(Object(from));

            for (var i = 0; i < keys.length; i++) {
                to[keys[i]] = from[keys[i]];
            }
        }

        return to;
    },
    "hbox": {
        display: "flex",
        flexDirection: "row",
        alignContent: "flex-start",
        padding: "2px"
    },
    "vbox": {
        display: "flex",
        flexDirection: "column",
        alignContent: "flex-start",
        padding: "2px"
    },
    /*Stretch item along parent's main-axis*/
    "flex": function(value:number){
        value = value || 1;
        return {
        WebkitFlex: value,
        msFlex: value,
        flex: value
      };
    },
    /*Stretch item along parent's cross-axis*/
    "stretch": {
        alignSelf: "stretch"
    },

    /*Stack child items to the main-axis start*/
    "mainStart": {
        WebkitJustifyContent: "flex-start",
        msFlexPack: "flex-start",
        justifyContent: "flex-start"
    },
    /*Stack child items to the cross-axis start*/
    "crossStart": {
        WebkitAlignItems: "flex-start",
        msFlexAlign: "flex-start",
        alignItems: "flex-start",

        WebkitAlignContent: "flex-start",
        msFlexLinePack: "start",
        alignContent: "flex-start"
    },
    /*Stack child items to the main-axis center*/
    "mainCenter": {
        WebkitJustifyContent: "center",
        msFlexPack: "center",
        justifyContent: "center"
    },
    /*Stack child items to the cross-axis center*/
    "crossCenter": {
        WebkitAlignItems: "center",
        msFlexAlign: "center",
        alignItems: "center",

        webkitAlignContent: "center",
        msFlexLinePack: "center",
        alignContent: "center"
    },
    /*Stack child items to the main-axis end.*/
    "mainEnd": {
        webkitJustifyContent: "flex-end",
        msFlexPack: "end",
        justifyContent: "flex-end"
    },
    /*Stack child items to the cross-axis end.*/
    "crossEnd": {
        WebkitAlignItems: "end",
        msFlexAlign: "end",
        AlignItems: "end",

        WebkitAlignContent: "flex-end",
        msFlexlinePack: "end",
        alignContent: "flex-end"
    },
    /*Stretch child items along the cross-axis*/
    "crossStretch": {
        WebkitAlignItems: "stretch",
        msFlexAlign: "stretch",
        alignItems: "stretch",

        WebkitAlignContent: "stretch",
        msFlexlinePack: "stretch",
        alignContent: "stretch"
    },

    /*Wrap items to next line on main-axis*/
    "wrap": {
        WebkitflexWrap: "wrap",
        msFlexWrap: "wrap",
        flexWrap: "wrap"
    }
}

export class Hbox extends React.Component<any, any> {
	render() {
		var style = Style.merge(Style.hbox, this.props.style || {});
		return (
			<div style={ style } data-box-layout="hbox">
			{ this.props.children }
			</div>
		);
	}
}

export class Vbox extends React.Component<any, any> {
	render() {
		var style = Style.merge(Style.vbox, this.props.style || {});
		return (
			<div style={ style } data-box-layout="vbox">
			{ this.props.children }
			</div>
		);
	}
}

```
Simple Hbox/Vbox components, with flex layout as adapted to reactjs, from the css shown here [https://gist.github.com/Munawwar/7926618](https://gist.github.com/Munawwar/7926618).
Now, lets use this layout component into our views. Since we already have almost complete login view, let's implement it there.
We just need to change the render method of the login component as follows:

```ts
render() {
    var store = this.props.store;
    var loginButton = {marginLeft: 77};
    var error = {marginLeft: 5, color: '#cc0000'};
    return (<form ref="loginForm">
                <Vbox>
                <span style={error} ref="credentialError">{store.errors.credential}</span>
                <Hbox>
                    <Vbox>
                    <label>Username: </label>
                    <label>Password: </label>
                    </Vbox>
                    <Vbox>
                    <Hbox>
                        <input type="email" required={true} ref="username" />
                        <span style={error} ref="usernameError">{store.errors.username}</span>
                    </Hbox>
                    <Hbox>
                        <input type="password" required={true} ref="password" />
                        <span style={error} ref="passwordError">{store.errors.password}</span>
                    </Hbox>
                    </Vbox>
                </Hbox>
                <Hbox>
                    <input style={loginButton} type="button" value="Login" ref="btnLogin" onClick={this.dologin.bind(this) } />
                </Hbox>
                </Vbox>
        </form>);
}
```