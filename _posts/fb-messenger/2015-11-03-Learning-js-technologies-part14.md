---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-14)"
date:   2015-11-03 6:00:00
description: In this post we will add a very basic interactivity functionality. When any friend in friend list is clicked that friend should be the active friend.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    Its been quite long since I worked on this small side project of mine. Well I got busy with my day to day works and couldn't find enough time to work on this.
    I though that I should work atleast once a month even if it is for an hour or so. Hence, I continued with adding one more feature, i.e. showing received
    messages from the friend.
</p>
With these changes we won't still be able to send message, but message sent by friends will be listed.

To get started following change was made ChatStore class

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
    
    constructor(){
        super();
        this.messages = {};
        this.currentFriend = {id: ''};
    }
    
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
            this.friendList = data
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
        }.bind(this));

        this.chatService.listener.on('message', function(event: any, stopListening: Function) {
            if(!this.messages[event.sender_id]){
                this.messages[event.sender_id] = new Array<string>();
            }
            this.messages[event.sender_id].push(event);
            this.emit('change');
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
The changed sections are:

```ts
constructor(){
    super();
    this.messages = {};
    this.currentFriend = {id: ''};
}
```

And:

```ts

listen() {
    this.chatService.listen();

    this.chatService.listener.on('error', function(error: any, stopListening: Function) {
        console.log(error);
    }.bind(this));

    this.chatService.listener.on('message', function(event: any, stopListening: Function) {
        if(!this.messages[event.sender_id]){
            this.messages[event.sender_id] = new Array<string>();
        }
        this.messages[event.sender_id].push(event);
        this.emit('change');
    }.bind(this));

    this.chatService.listener.on('event', function(event: any, stopListening: Function) {
        console.log(event);
    }.bind(this));

    this.chatService.listener.on('presence', function(event: any, stopListening: Function) {
        console.log(event);
    }.bind(this));
}
```
Conceptually only change we have done so far is to push any message that chatService receives into the ChatStore's "messages" dictionary. Now,
to use this message we will change the render method of Chat class as follows:

```ts
render() {
    var friendList = AppStores.chatStore.friendList;
    var currentFriend = AppStores.chatStore.currentFriend || {id: ''};
    var messages = AppStores.chatStore.messages[currentFriend.id] || [];
    return (<Hbox>
                <Vbox>
                <FriendList friendList={friendList} currentFriend={currentFriend} />
                </Vbox>
                <Vbox>
                {messages.map(function(message: any) {
                    return (<div key={message.messageID} className="callout-in">{message.body}</div>);
                })}
                <textarea></textarea>
                </Vbox>
        </Hbox>);
}
```

Hmm! Now we are getting the list of messages belonging to current friend and listing them out, that's all! We should now be able to see the message
if anyone of our friend sends message to us in Facebook chat. There was still one problem I faced while checking if the functionality works or not.
I asked a friend to send me message but I was having hard time finding that friend in the friend list. I'm sure going forward this whole interface 
will be lot more interactive and there won't be problem finding friend, there will also be notifications about new message. But for now to make 
development easier, the friend list is changed to display in alphabetical order of name.

Old code (friendlist.tsx):

```ts
var friendList = Object.keys(this.props.friendList || []).map(id => this.props.friendList[id]);
```

New code:

```ts
var friendList = Object.keys(this.props.friendList || [])
                       .map(id => this.props.friendList[id])
                       .sort((x,y) => x.name.localeCompare(y.name))
                       .filter(x => x.id != '');
```

Two more modification are done to the friendList array:

- Sort by ascneding order of name
- Remove all entries with blank id property.

Finally the test:

```ts
describe("chat", ()=>
{
    it("should show the message list of current friend",(done: Function) => {
        AppStores.loginStore.api = {
            setOptions: function(){},
            getCurrentUserId: function(){return "0"},
            getFriendsList: function(currentUserId:any, cb:Function){
                cb(null, {'1': {id: '1', name:'Friend1'}});
            },
        };
            
        AppStores.chatStore.currentFriend = {id: '1'};
        AppStores.chatStore.messages['1'] = [{'messageID':'1','body': 'hello'}];
        var chatUI = React.render(<Chat store={AppStores.chatStore} api={AppStores.loginStore.api} />, document.body);
        expect(ReactTestUtils.scryRenderedComponentsWithType(chatUI, FriendList).length).toBe(1);
        setTimeout(function() {
            var callouts = ReactTestUtils.scryRenderedDOMComponentsWithClass(chatUI, "callout-in");
            expect(callouts[0].getDOMNode().innerHTML).toBe('hello');
            expect(callouts.length).toBe(1);
            done();
        }, 10);
    });
});
```
