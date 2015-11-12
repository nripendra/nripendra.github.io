---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-17)"
date:   2015-11-12 6:00:00
description: In this post we will clean up the chat component by dividing it further into multiple subcomponents.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    In this post we will clean up the chat component by dividing it further into multiple subcomponents.The chat component itself is consist of two major parts:
</p>

- The friend list
- Conversation history with selected friend.

We already have separate component for friend list. For conversation history we are clubbing everything right into chat
component. My plan is to move conversation section to separate component. The conversation component has
various sections, the header in which currently selected friend's detail is displayed, the actual conversation with that friend
and the textbox to type in message.

With this goal in mind, let's modify chat.tsx as follows:

```ts
import * as React from 'react';
import * as ReactDom from 'react-dom';

import {Hbox, Vbox} from './layout';

import ChatStore from '../stores/chatstore';
import ChatActions from '../actions/chatactions';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';

import FriendList from './friendlist';
import Conversation from './conversation';

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
        var currentFriend = AppStores.chatStore.currentFriend || {id: ''};
        var currentUser = AppStores.chatStore.friendList[AppStores.chatStore.currentUserId] || {id: ''};
        var messages = AppStores.chatStore.messages[currentFriend.id] || [];
        
        return (<Hbox>
                  <Vbox>
                    <FriendList friendList={friendList} currentFriend={currentFriend} />
                  </Vbox>
                  <Conversation messages={messages} currentUser={currentUser} currentFriend={currentFriend} />
            </Hbox>);
    }
}
```

As we can see, lots of code has been removed, and replaced with "conversation" tag instead. And we are passing in
the list of messages to be displayed, currentUser and currentFriend. "currentUser" is currently logged in user, while
"currentFriend" is currently selected friend from the friendlist component. "messages" variable stores the conversation
that's going on with this friend. A point to be noted is that there is no carry over conversation, i.e. all the 
conversation in messages are the ones from this login session. We will try to get some historical data too in future.

Now for the "Conversation" component, add conversation.tsx file in src/component folder.

```ts
import * as React from 'react';
import {Hbox, Vbox} from './layout';
import ConversationHistory from './conversation-history';

const Avatar = require('material-ui/lib/avatar');
const FontIcon = require('material-ui/lib/font-icon');
const IconButton = require('material-ui/lib/icon-button');
const TextField = require('material-ui/lib/text-field');
const Cards = require('material-ui/lib/card');
const Card = Cards.Card;
const CardHeader = Cards.CardHeader;
const CardActions = Cards.CardActions;
const CardText = Cards.CardText;
const CardMedia = Cards.CardMedia;


export class ConversationProps {
    messages: any;
    currentFriend: any;
	currentUser: any;
}

export default class Conversation extends React.Component<ConversationProps, any> {
    constructor(props: ConversationProps) {
        super();
        this.props = props;
    }

    render() {
        var styles = {
            rightPane: {
                flex: 2, 
                height: 'calc(100vh - 8px)',
                maxHeight: 'calc(100vh - 8px)'
            }
        };

        var currentFriend = this.props.currentFriend;
        var currentUser = this.props.currentUser;
        var messages = this.props.messages;
               
        return (<Card style={styles.rightPane}>
                    {this.renderHeader(currentFriend)}

                    <ConversationHistory messages={messages} currentUser={currentUser} currentFriend={currentFriend} />
                    
                    <CardActions style={{borderTop:'2px solid #CCC', padding:0}}>
                        <Hbox style={{margin:0, padding:0}}>
                            <TextField hintText="Write a message..." multiLine={true} rows={1} rowsMax={2} style={{flex:2}}></TextField>
                            <IconButton><FontIcon className="fa fa-paper-plane fa-2" /></IconButton>
                        </Hbox>
                    </CardActions>
                  </Card>);
    }
    
    renderHeader(currentFriend: any) {
        return (<CardHeader title={currentFriend.name} avatar={<Avatar size={32} src={currentFriend.thumbSrc} />} />);
    }
}
```
This component displays the whole right pane. It is composed of a header which displays current friend's avatar and name...
The conversation thread which displays the messages being exchanged during the course of time. And finally a textbox to type
message.

The conversation thread is displayed using "ConversationHistory" component. To add this component, lets add a file named 
"conversation-history.tsx" in /src/components folder:

```ts
import * as React from 'react';
import * as ReactDom from 'react-dom';

import {Hbox, Vbox} from './layout';
import MessageItem from './message-item';

const Cards = require('material-ui/lib/card');
const Card = Cards.Card;
const CardHeader = Cards.CardHeader;
const CardActions = Cards.CardActions;
const CardText = Cards.CardText;
const CardMedia = Cards.CardMedia;

export class ConversationHistoryProps {
    messages: any;
    currentFriend: any;
	currentUser: any;
}

export default class ConversationHistory extends React.Component<ConversationHistoryProps, any> {
    constructor(props: ConversationHistoryProps){
        super();
        this.props = props;
    }
    render() {
        var styles = {
            messageListScrollPane: {
                padding: '0 1.5em', 
                overflowX:'hidden',
                overflowY:'auto',
                height:'calc(100vh - 150px)', 
                maxHeight:'calc(100vh - 150px)',
                borderTop:'1px solid #ccc'
            },
            messageList: {
                minHeight: 'calc(100vh - 155px)',
                justifyContent: 'flex-end'
            }
        };
        
        return (<CardText style={styles.messageListScrollPane}>
                    <Vbox style={styles.messageList}>{this.renderMessages()}</Vbox>
                </CardText>);
    }
    
    renderMessages(){
        var messages = this.props.messages;
        return messages.map((message: any) => this.renderMessageItem(message));
    }
    
    renderMessageItem(message: any) {
        var currentFriend = this.props.currentFriend;
        var currentUser = this.props.currentUser;
        return (<MessageItem message={message} currentUser={currentUser} currentFriend={currentFriend} />);
    }
}
```

All it does is takes the list of messages and renders a "MessageItem" component for each of them. Hmm, yet another component.
Let's add "message-item.tsx":

```ts
import * as React from 'react';

import {Hbox, Vbox} from './layout';

const Avatar = require('material-ui/lib/avatar');

export class MessageItemProps {
    message: any;
    currentFriend: any;
	currentUser: any;
}

export class MessageContentProps {
	message: any;
	className: string;
}

export class MessageContent extends React.Component<MessageContentProps, any> {
	constructor(props: MessageContentProps) {
        super();
        this.props = props;
    }
	
	render() {
		return (<div className={this.props.className} style={{'textAlign':'justify'}}>{this.props.message.body}</div>);
	}
}

export default class MessageItem extends React.Component<MessageItemProps, any> {
    constructor(props: MessageItemProps) {
        super();
        this.props = props;
    }

    render() {
        var currentFriend = this.props.currentFriend;
        var currentUser = this.props.currentUser;
        var message = this.props.message;
        
		var threadID = (message.senderID || "").toString();
		var leftAvatar:any = null;
		var rightAvatar:any = null;
		var rightAvatarStyle = {'marginLeft':'1.2em', 'marginRight':'-5px'};
		var leftAvatarStyle = {'marginRight':'1.2em', 'marginLeft':'-5px'};
		var className = '';
		var justifyContent = '';
		
		if(threadID == currentUser.id) {
			className = 'callout right';
			justifyContent = 'flex-end';
			rightAvatar = <div style={rightAvatarStyle}><Avatar size={32} src={currentUser.thumbSrc} /></div>;
		} else {
			className = 'callout left';
			justifyContent = 'flex-start';
			leftAvatar = <div style={leftAvatarStyle}><Avatar size={32} src={currentFriend.thumbSrc} /></div>;
		}
		
		return (<Hbox style={{'justifyContent':justifyContent}}>
					{leftAvatar}
					<MessageContent className={className} message={message}  />
					{rightAvatar}
				</Hbox>);
    }
}
```

Each message item is consist of an avatar of sender and the message content. To display the message content we again
have another component "MessageContent", in same file.

Well this time we had to do quite a lot of work since chat component was really doing a lot of things. But with these
changes, hopefully we may have to do only smaller changes.

As I mentioned earlier, I'm creating a trello board to track the items that needs to be done. Ideally I'd like to have post
per trello card. If the changes are very small then, it may make sense to have a post for couple of cards.

Finally the link to [commit](https://github.com/nripendra/fb-messenger/commit/e4d49008ccac4de1e9538e07f6e884580868f768?diff=split)