import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';


class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _sending = false;


  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }


  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (_scrollCtrl.hasClients) {

        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );

      }

    });

  }



  Future<void> _sendText() async {

    final text = _textCtrl.text.trim();

    if(text.isEmpty) return;


    final user = context.read<AuthProvider>().user!;


    await context.read<ChatProvider>().sendMessage(
      chatId: widget.chatId,
      senderId: user.uid,
      senderUsername: user.username,
      content: text,
    );


    _textCtrl.clear();

    _scrollToBottom();

  }




  Future<void> _sendImage() async {


    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );


    if(xFile == null || !mounted) return;


    setState(() {
      _sending = true;
    });



    final user = context.read<AuthProvider>().user!;



    await context.read<ChatProvider>().sendImage(
      chatId: widget.chatId,
      senderId: user.uid,
      senderUsername: user.username,
      imageFile: File(xFile.path),
    );



    if(mounted){

      setState(() {
        _sending = false;
      });

    }


    _scrollToBottom();

  }





  @override
  Widget build(BuildContext context) {


    final currentUid =
        context.read<AuthProvider>().user?.uid ?? '';



    return Scaffold(

      backgroundColor: AppTheme.background,


      appBar: AppBar(

        title: Row(

          children: [


            _SmallAvatar(
              url: widget.otherUser.avatarUrl,
              name: widget.otherUser.username,
            ),


            const SizedBox(width:10),


            Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  widget.otherUser.username,
                  style: const TextStyle(fontSize:15),
                ),


                const Text(
                  "online",
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize:11,
                  ),
                ),

              ],
            )

          ],

        ),

      ),



      body: Column(

        children: [


          Expanded(

            child: StreamBuilder<List<MessageModel>>(

              stream: context
                  .read<ChatProvider>()
                  .getChatMessages(widget.chatId),


              builder:(context,snap){


                final messages = snap.data ?? [];



                if(messages.isNotEmpty){
                  _scrollToBottom();
                }



                return ListView.builder(

                  controller:_scrollCtrl,

                  itemCount:messages.length,


                  itemBuilder:(context,index){


                    final msg = messages[index];


                    final isMe =
                        msg.senderId == currentUid;



                    return _MessageBubble(
                      msg:msg,
                      isMe:isMe,
                    );


                  },

                );


              },

            ),

          ),




          if(_sending)

            const LinearProgressIndicator(
              color:AppTheme.accent,
            ),




          _InputBar(

            controller:_textCtrl,

            onSend:_sendText,

            onImage:_sendImage,

            enabled:!_sending,

          )


        ],

      ),

    );

  }

}





class _MessageBubble extends StatelessWidget {


  final MessageModel msg;

  final bool isMe;


  const _MessageBubble({
    required this.msg,
    required this.isMe,
  });



  @override
  Widget build(BuildContext context){


    final isImage =
        msg.content.startsWith("http");



    return Align(

      alignment:
      isMe ? Alignment.centerRight :
      Alignment.centerLeft,


      child: Container(


        margin:
        const EdgeInsets.all(6),


        padding:
        const EdgeInsets.all(10),


        decoration:BoxDecoration(

          color:
          isMe ?
          AppTheme.accent :
          AppTheme.card,


          borderRadius:
          BorderRadius.circular(16),

        ),



        child:isImage

            ?

        CachedNetworkImage(
          imageUrl:msg.content,
          width:220,
        )


            :

        Text(

          msg.content,

          style:TextStyle(

            color:
            isMe ?
            Colors.black :
            AppTheme.textPrimary,

          ),

        ),

      ),

    );

  }

}






class _InputBar extends StatelessWidget {


  final TextEditingController controller;

  final VoidCallback onSend;

  final VoidCallback onImage;

  final bool enabled;



  const _InputBar({

    required this.controller,

    required this.onSend,

    required this.onImage,

    required this.enabled,

  });



  @override
  Widget build(BuildContext context){


    return Row(

      children:[


        IconButton(

          icon:
          const Icon(Icons.image),

          onPressed:
          enabled ? onImage : null,

        ),



        Expanded(

          child:TextField(

            controller:controller,

            enabled:enabled,

          ),

        ),



        IconButton(

          icon:
          const Icon(Icons.send),

          onPressed:
          enabled ? onSend : null,

        )


      ],

    );


  }


}






class _SmallAvatar extends StatelessWidget {


  final String? url;

  final String name;



  const _SmallAvatar({

    this.url,

    required this.name,

  });



  @override
  Widget build(BuildContext context){


    return CircleAvatar(

      child:Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : "?",
      ),

    );

  }


}
