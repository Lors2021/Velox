import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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


  final TextEditingController _textCtrl =
      TextEditingController();

  final ScrollController _scrollCtrl =
      ScrollController();



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

          duration:
          const Duration(milliseconds:250),

          curve:
          Curves.easeOut,

        );

      }

    });

  }




  Future<void> _sendText() async {


    final text =
        _textCtrl.text.trim();



    if(text.isEmpty) return;



    final user =
        context.read<AuthProvider>().user!;



    await context.read<ChatProvider>().sendMessage(

      chatId: widget.chatId,

      senderId: user.uid,

      senderUsername: user.username,

      content: text,

    );



    _textCtrl.clear();



    _scrollToBottom();


  }





  @override
  Widget build(BuildContext context) {


    final currentUid =
        context.read<AuthProvider>().user?.uid ?? '';



    return Scaffold(


      backgroundColor:
      AppTheme.background,



      appBar: AppBar(


        title: Row(

          children: [


            _SmallAvatar(

              name:
              widget.otherUser.username,

            ),



            const SizedBox(width:10),



            Text(

              widget.otherUser.username,

              style:
              const TextStyle(
                fontSize:16,
              ),

            )


          ],

        ),


      ),





      body: Column(

        children: [


          Expanded(


            child:
            StreamBuilder<List<MessageModel>>(


              stream:
              context
                  .read<ChatProvider>()
                  .getChatMessages(widget.chatId),



              builder:(context,snapshot){


                final messages =
                    snapshot.data ?? [];



                if(messages.isNotEmpty){

                  _scrollToBottom();

                }




                return ListView.builder(


                  controller:
                  _scrollCtrl,



                  padding:
                  const EdgeInsets.all(12),



                  itemCount:
                  messages.length,



                  itemBuilder:(context,index){



                    final msg =
                        messages[index];



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




          _InputBar(

            controller:
            _textCtrl,

            onSend:
            _sendText,


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
  Widget build(BuildContext context) {



    return Align(


      alignment:
      isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,



      child: Container(



        margin:
        const EdgeInsets.only(
          bottom:6,
        ),



        padding:
        const EdgeInsets.symmetric(

          horizontal:14,

          vertical:10,

        ),




        decoration:
        BoxDecoration(


          color:
          isMe
              ? AppTheme.accent
              : AppTheme.card,



          borderRadius:
          BorderRadius.circular(16),


        ),




        child: Text(


          msg.content,



          style:
          TextStyle(


            color:
            isMe
                ? Colors.black
                : AppTheme.textPrimary,


            fontSize:15,


          ),


        ),



      ),


    );


  }


}







class _InputBar extends StatelessWidget {


  final TextEditingController controller;

  final VoidCallback onSend;



  const _InputBar({

    required this.controller,

    required this.onSend,

  });





  @override
  Widget build(BuildContext context) {



    return Container(


      padding:
      const EdgeInsets.all(10),



      color:
      AppTheme.surface,



      child:
      Row(



        children: [



          Expanded(



            child:
            TextField(



              controller:
              controller,



              decoration:
              const InputDecoration(

                hintText:
                "Message...",

              ),



              onSubmitted:
              (_) => onSend(),



            ),



          ),





          IconButton(


            icon:
            const Icon(
              Icons.send,
            ),



            onPressed:
            onSend,


          )



        ],



      ),



    );


  }


}







class _SmallAvatar extends StatelessWidget {


  final String name;



  const _SmallAvatar({

    required this.name,

  });





  @override
  Widget build(BuildContext context) {


    return CircleAvatar(


      radius:17,


      backgroundColor:
      AppTheme.card,



      child:
      Text(


        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?',



        style:
        const TextStyle(


          color:
          AppTheme.accent,


          fontSize:13,


          fontWeight:
          FontWeight.w700,


        ),



      ),



    );


  }


}
