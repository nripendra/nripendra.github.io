---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-13)"
date:   2015-10-01 6:00:00
description: In this post we will add a very basic interactivity functionality. When any friend in friend list is clicked that friend should be the active friend.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    In this post we will add a very basic interactivity functionality. When any friend in friend list is clicked that friend should be the active friend.
</p>
I had to make changes in total of 5 files all together to get this functinality working... One change would have been rather unnecessary if I had
followed proper unit testing :)

The problem was with merge method in layout.tsx's Style component. Now over all layout.tsx looks like this:


```ts
import * as React from 'react';

/**
 * Style
 * @ref: https://gist.github.com/Munawwar/7926618
 */
export var Style: any = {
  merge(target: any) {
      //@ref = https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
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

        var keysArray = Object.keys(nextSource);
        for (var nextIndex = 0, len = keysArray.length; nextIndex < len; nextIndex++) {
          var nextKey = keysArray[nextIndex];
          var desc = Object.getOwnPropertyDescriptor(nextSource, nextKey);
          if (desc !== undefined && desc.enumerable) {
            to[nextKey] = nextSource[nextKey];
          }
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
    var style = Style.merge({}, Style.hbox, this.props.style || {});
		return (
			<div style={ style } data-box-layout="hbox">
			{ this.props.children }
			</div>
		);
	}
}

export class Vbox extends React.Component<any, any> {
	render() {
    var style = Style.merge({}, Style.vbox, this.props.style || {});
		return (
			<div style={ style } data-box-layout="vbox">
			{ this.props.children }
			</div>
		);
	}
}

```

Well! Shamelessly copied code from [here...](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/assign)
Another problem was in Hbox and Vbox style calculation:

```ts
Style.merge(Style.hbox, this.props.style || {});
```

was causing the hbox property of Style component to change, so changed it to:

```ts
Style.merge({}, Style.hbox, this.props.style || {});
```

Friendlist component is now modified to listen for click on individual friend and make that friend as active..

```ts
import * as React from 'react';
import {Hbox, Vbox} from './layout';
import ChatAction from '../actions/chatactions';

export class FriendListProps {
    friendList: { [id: string] : any; } = {};//Dictionary<string, any>;
    currentFriend: any;
}

export default class FriendList extends React.Component<FriendListProps, any> {
    constructor(props: FriendListProps) {
        super();
        this.props = props;
    }

    friendClicked(friend: any, event: any){
        ChatAction.friendSelected(friend);
    }
    
    render() {
        var state = {
            'online': {
                border: '1px solid gray',
                borderLeft: '3px solid green'
            },
            'offline': {
                border: '1px solid gray',
                borderLeft: '3px solid gray'
            },
            'selected':{
                backgroundColor:'#6d84b4'
            }
        };
        
        var friendlistStyle = {
            'overflow':'auto',
            'maxHeight':'calc(100vh - 8px)'
        };
        
        var _this = this;
        var friendList = Object.keys(this.props.friendList || []).map(id => this.props.friendList[id]);
        return (<div style={friendlistStyle}>
                  {friendList.map(function(friend: any) {
                      var currentFriend = (_this.props.currentFriend || {id: ''});
                      var isCurrentFriend = friend.id == currentFriend.id;
                      var style = isCurrentFriend ? state.selected : {};
                      
                      return (<Hbox style={style} >
                                <div onClick={_this.friendClicked.bind(_this, friend)} >  
                                <img src={friend.thumbSrc} style={state[friend.onlineState || 'offline']} />
                                {friend.name}
                                </div>
                          </Hbox>);
                  })}
                  </div>);
    }
}

```
I had to add one more div to handle onClick event! Adding onClick to Hbox didn't work... If you look into the code, all it does is: whenever any friend is clicked..
``` ChatAction.friendSelected(friend);``` is called. This in turn will make changes to store and make that friend the currently active friend with whom we want to chat. Also,
it will change the background color of the friend to highlighted dark blue..

ChatAction.ts now looks like this:

```ts
import dispatcher from '../appdispatcher';
import {ILoginErrors, ICredential} from "../stores/loginstore";

export default {
    initApi(api: any): void {
        dispatcher.dispatch('initApi', api);
    },
    setCurrentChatThread(chatThread: string): void {
        dispatcher.dispatch('setCurrentChatThread', chatThread);
    },
    friendSelected(friend: any): void {
        dispatcher.dispatch('friendSelected', friend);
    }
};

```
Notice that we have added a new friendSelected method. All it does is dispatch friendSelected action with selected friend as the payload.

ChatStore.ts looks as follows:

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
    friendList: { [id: string] : any; };//Dictionary<string, any>;
    messages: { [chatThreadId: string]: Array<any> };//Dictionary<string, Array<any>>
    currentFriend: any;
    
    get actions() {
        return {
            'initApi': 'loadFriendList',
            'setCurrentChatThread': 'setCurrentChatThread',
            'friendSelected': 'friendSelected'
        };
    }

    loadFriendList(api: any) {
        this.api = api;
        this.chatService = new ChatService(api);
        this.currentUserId = this.chatService.currentUserId;

        this.chatService.getFriendList().then(function(data: Array<any>) {
            this.friendList = data;
            this.currentFriend = this.friendList[Object.keys(this.friendList)[0]];
            console.log("Friendlist");
            console.log(this.friendList);
            this.emit('change');
            this.listen();
        }.bind(this)).catch(function(err: any) {
            this.error = err;
            this.emit('change');
        }.bind(this));
    }
    
    friendSelected(friend: any) {
        this.currentFriend = friend;
        this.emit('change');
    }

    setCurrentChatThread(chatThread: string) {
        this.currentChatThread = chatThread;
        this.emit('change');
    }

    listen() {
        this.chatService.listen();

        this.chatService.listener.on('error', function(error: any, stopListening: Function) {
            console.log(error);
        });

        this.chatService.listener.on('message', function(event: any, stopListening: Function) {
            console.log(event);
        });

        this.chatService.listener.on('event', function(event: any, stopListening: Function) {
            console.log(event);
        });

        this.chatService.listener.on('presence', function(event: any, stopListening: Function) {
            console.log(event);
        });
    }
}

```

Nothing much has changed except, we are setting "currentFriend" to the first friend in the friendList inside loadFriendList method, and added 
handler for friendSelected action.

Finally we compose all these pieces through the use of controller component in our case Chat.tsx...

```ts
import * as React from 'react';
import ChatStore from '../stores/chatstore';
import ChatActions from '../actions/chatactions';
import {Hbox, Vbox} from './layout';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';
import FriendList from './friendlist';

export class ChatProps {
    api: any;
    store: ChatStore
}

@connectToStore(['chatStore'])
export default class Chat extends React.Component<ChatProps, any> {
    constructor(props: ChatProps) {
        super();
        this.props = props;
        ChatActions.initApi(this.props.api);
    }

    render() {
        var friendList = AppStores.chatStore.friendList;
        var currentFriend = AppStores.chatStore.currentFriend;

        return (<Hbox>
                  <Vbox>
                  <FriendList friendList={friendList} currentFriend={currentFriend} />
                  </Vbox>
                  <Vbox>
                  <textarea></textarea>
                  </Vbox>
            </Hbox>);
    }
}

```

Well not much has changed! Just passing currentFriend along with friendList, and added a textarea to make the chat pane not look empty.

That's it folks! Just added very basic interactivity to our chat component. In next post we will try to do some more interactivity stuff.