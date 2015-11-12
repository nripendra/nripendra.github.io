---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-16)"
date:   2015-11-10 6:00:00
description: In previous post we converted the login form to material-ui desing. In this post we will convert the inner pages.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    In previous post we converted the login form to material-ui desing. In this post we will convert the inner pages.
</p>
To get started with I added a search bar on top of the friend list. To create search bar, '[Toolbar](http://material-ui.com/#/components/toolbars)' component was
used..

```ts
<Toolbar>
    <ToolbarGroup key={0} float="left">
        <TextField hintText="Search..." style={{width:'180px'}} />
    </ToolbarGroup>
    <ToolbarGroup key={1} float="right">
        <ToolbarSeparator/>
        <Popover listStyle={{background:'#C7C3C3', left:'calc(50% - 10.2em)'}} 
                    iconButtonElement={<IconButton><FontIcon className="fa fa-bell notification" /></IconButton>}
                    openDirection='bottom-right'
                >
                <ListItem
                leftAvatar={<Avatar>F</Avatar>}
                primaryText="Brendan Lim"
                secondaryText={
                <p>
                    I'll be in your neighborhood doing errands this weekend. Do you want to grab brunch?
                </p>
                } />
        </Popover>
        <IconButton><FontIcon className="fa fa-sign-out" /></IconButton>
    </ToolbarGroup>
</Toolbar>
```

Along with search textbox, we also have two icons one for notification and another is for showing two icons:

- notification and
- sign-out

The intension of these icons should be clear enough. My vision on notification is to show unread messages.
If found to be redundant or unnecessary, it can be removed, let's wait and watch. The plan was to show a popover
box when there are some notifications. But as it turns out that there isn't "yet" a popover component in material-ui.
The one being discussed in the project didn't quite fit to my liking. The component that came closest was the IconMenu
component. But it displayed menu, and I wanted to display a list. So, my solution was to copy the code from [IconMenu](http://material-ui.com/#/components/icon-menus),
and change it to show list instead of menu component. Worked quite great!

But in order to write the component itself I choose jsx as tsx was giving a lot of warnings and errors. In order to 
get jsx working with typescript, I also had to change gulp tasks.

Another change in the friendlist is the sorting logic:

```ts
var friendList = Object.keys(this.props.friendList || [])
                               .map((id) => {
                                   var f = this.props.friendList[id] as any;
                                   f.id = id;
                                   return f;
                               }).sort((x,y) => { 
                                   var xMessage: any = (AppStores.chatStore.messages[x.id] || []);
                                       var yMessage: any = (AppStores.chatStore.messages[y.id] || []);
                                       if(xMessage.length > 0) {
                                           xMessage = xMessage[xMessage.length - 1];
                                       } else {
                                           xMessage = {timestamp: 0};
                                       }
                                       
                                       if(yMessage.length > 0) {
                                           yMessage = yMessage[yMessage.length - 1];
                                       } else {
                                           yMessage = {timestamp: 0};
                                       }
                                       
                                       var diff = yMessage.timestamp - xMessage.timestamp;
                                       if(diff == 0) {
                                            var presencePriority = {'active': 3, 'idle': 2, 'invisible': 1, 'offline': 0 };
                                            var presence1 = (presencePriority[((x.presence || {statuses: {status: 'offline'}}).statuses ||  {status: 'offline'}).status]) || 0;
                                            var presence2 = (presencePriority[((y.presence || {statuses: {status: 'offline'}}).statuses ||  {status: 'offline'}).status]) || 0;
                                            if(presence1 == presence2) {
                                                return x.name.localeCompare(y.name); 
                                            } else {
                                                return presence2 - presence1;
                                            }       
                                       }
                                       return diff;
                               })
                               .filter(x => x.isFriend === true);
```

The basic concept is:
- Order by 'timestamp of lastmessage', then by presence and then by name. In later version facebook-chat-api
did remove id from friend object so I had to readd it.

Oh wait! Where did message timestamp come from? From here:

```ts
this.chatService.listener.on('message', function(event: any, stopListening: Function) {
    var threadID = (event.senderID || "").toString();
    if(threadID == this.currentUserId) {
        threadID = (event.threadID || "").toString();
    }
            
    if(!this.messages[threadID]){
        this.messages[threadID] = new Array<string>();
    }
    this.messages[threadID].push(event);
    this.emit('change');
    console.log(event);
}.bind(this));
```

If you don't remember this code, it is from [ChatStore.ts](https://github.com/nripendra/fb-messenger/blob/742d35f93bb400e797d9dfc820cfef5f75cf3a32/src/stores/chatstore.ts#L80) **listen()** method.

The friend list itself was converted to material-ui [List](http://material-ui.com/#/components/lists) component:

```ts
<List style={friendlistStyle}>
    {friendList.map(function(friend: any) {
        var currentFriend = (_this.props.currentFriend || {id: ''});
        var isCurrentFriend = friend.id == currentFriend.id;
        var style = isCurrentFriend ? state.selected : {};
        var presence = ((friend.presence || {statuses: {status: 'offline'}}).statuses ||  {status: 'offline'}).status;
        return (<ListItem 
                leftAvatar={<div><Avatar  size={32} src={friend.thumbSrc} /><span style={state[presence || 'offline']}></span></div>}
                style={style} 
                onClick={_this.friendClicked.bind(_this, friend)}
                primaryText={friend.name}>
            </ListItem>);
    })}
</List>
```
Yet another change that was done was while showing the conversation panel, [chat.tsx](https://github.com/nripendra/fb-messenger/blob/742d35f93bb400e797d9dfc820cfef5f75cf3a32/src/components/chat.tsx) render function is changed as follows:

```ts
render() {
        var friendList = AppStores.chatStore.friendList;
        var currentFriend = AppStores.chatStore.currentFriend || {id: ''};
        var currentUser = AppStores.chatStore.friendList[AppStores.chatStore.currentUserId] || {id: ''};
        var messages = AppStores.chatStore.messages[currentFriend.id] || [];
        
        var rightPane =  {flex:2,
                          'height':'calc(100vh - 8px)', 
                          'maxHeight':'calc(100vh - 8px)'};
                          
        var messageListScrollPane = {'padding':'0 1.5em',
                                     'overflowX':'hidden',
                                     'overflowY':'auto',
                                     'height':'calc(100vh - 150px)', 
                                     'maxHeight':'calc(100vh - 150px)',
                                     'borderTop':'1px solid #ccc'
                                    };
                                     
        var messageList = {'minHeight': 'calc(100vh - 155px)',
                            'justifyContent':'flex-end'};
        
        return (<Hbox>
                  <Vbox>
                    <FriendList friendList={friendList} currentFriend={currentFriend} />
                  </Vbox>
                  <Card style={rightPane}>
                    <CardHeader title={currentFriend.name} avatar={<Avatar size={32} src={currentFriend.thumbSrc} />} />
                    <CardText style={messageListScrollPane}>
                            <Vbox style={messageList}>
                            {messages.map(function(message: any) {
                                    var avatarSrc = currentFriend.thumbSrc;
                                    var threadID = (message.senderID || "").toString();
                                    var leftAvatar:any = null;
                                    var rightAvatar:any = null;
                                    var rightAvatarStyle = {'marginLeft':'1.2em', 'marginRight':'-5px'};
                                    var leftAvatarStyle = {'marginRight':'1.2em', 'marginLeft':'-5px'};
                                    if(threadID == AppStores.chatStore.currentUserId) {
                                        avatarSrc = currentUser.thumbSrc;
                                        rightAvatar = <div style={rightAvatarStyle}><Avatar size={32} src={avatarSrc} /></div>;
                                    } else {
                                        leftAvatar = <div style={leftAvatarStyle}><Avatar size={32} src={avatarSrc} /></div>;
                                    }
                                var className = 'callout';
                                var justifyContent = 'flex-start';
                                if(leftAvatar == null){
                                    className += ' right';
                                    justifyContent = 'flex-end';
                                } else {
                                    className += ' left';
                                }
        
                                return (<Hbox style={{'justifyContent':justifyContent}}>
                                            {leftAvatar}
                                            <div className={className} style={{'textAlign':'justify'}}>{message.body}</div>
                                            {rightAvatar}
                                        </Hbox>);
                            })}
                            </Vbox>
                    </CardText>
                    <CardActions style={{borderTop:'2px solid #CCC', padding:0}}>
                        <Hbox style={{margin:0, padding:0}}>
                            <TextField hintText="Write a message..." multiLine={true} rows={1} rowsMax={2} style={{flex:2}}></TextField>
                            <IconButton><FontIcon className="fa fa-paper-plane fa-2" /></IconButton>
                        </Hbox>
                    </CardActions>
                  </Card>
            </Hbox>);
    }
```

Not what I would call clean, but overall ui does look quite nice.

Well, although the things are now looking quite nice but the problem I faced after completion was tracking the changes for this post!! There
were so many changes and in so many files I just cannot coherently write down details in proper order. So, linking the commit [here](https://github.com/nripendra/fb-messenger/commit/742d35f93bb400e797d9dfc820cfef5f75cf3a32).

To avoid such unwieldy changes in future I have created a to-do in trello. I'll plan to make it public in future if I like the overall workflow.

I'm also not quite happy about my approach to git. Committing dirrectly to master branch for every change probably isn't something anyone would suggest, 
so I'll try to follow proper branch flow.