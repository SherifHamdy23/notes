import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes/db_helper/db_helper.dart';
import 'package:notes/modal_class/notes.dart';
import 'package:notes/utils/widgets.dart';

class NoteDetail extends StatefulWidget {
  final String appBarTitle;
  final Note note;

  const NoteDetail(this.note, this.appBarTitle, {super.key});

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState();
  }
}

class NoteDetailState extends State<NoteDetail> {
  DatabaseHelper helper = DatabaseHelper();

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isEdited = false;
  late Note note;

  @override
  Widget build(BuildContext context) {
    note = widget.note;
    titleController.text = note.title;
    descriptionController.text = note.description;
    return WillPopScope(
        onWillPop: () async {
          isEdited ? showDiscardDialog(context) : moveToLastScreen();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              widget.appBarTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            backgroundColor: colors[note.color],
            leading: IconButton(
                splashRadius: 22,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  isEdited ? showDiscardDialog(context) : moveToLastScreen();
                }),
            actions: <Widget>[
              IconButton(
                splashRadius: 22,
                icon: const Icon(
                  Icons.save,
                  color: Colors.black,
                ),
                onPressed: () {
                  titleController.text.isEmpty
                      ? showEmptyTitleDialog(context)
                      : _save();
                },
              ),
              IconButton(
                splashRadius: 22,
                icon: const Icon(Icons.delete, color: Colors.black),
                onPressed: () {
                  showDeleteDialog(context);
                },
              )
            ],
          ),
          body: Container(
            color: colors[note.color],
            child: Column(
              children: <Widget>[
                PriorityPicker(
                  selectedIndex: 3 - note.priority,
                  onTap: (index) {
                    isEdited = true;
                    note.priority = 3 - index;
                  },
                ),
                ColorPicker(
                  selectedIndex: note.color,
                  onTap: (index) {
                    setState(() {
                      note.color = index;
                    });
                    isEdited = true;
                    note.color = index;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: titleController,
                    maxLength: 255,
                    style: Theme.of(context).textTheme.bodyMedium,
                    onChanged: (value) {
                      updateTitle();
                    },
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Title',
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: 10,
                      maxLength: 255,
                      controller: descriptionController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      onChanged: (value) {
                        updateDescription();
                      },
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Description',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(
            "Discard Changes?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          content: Text("Are you sure you want to discard changes?",
              style: Theme.of(context).textTheme.bodyLarge),
          actions: <Widget>[
            TextButton(
              child: Text("No",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.purple)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Yes",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.purple)),
              onPressed: () {
                Navigator.of(context).pop();
                moveToLastScreen();
              },
            ),
          ],
        );
      },
    );
  }

  void showEmptyTitleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(
            "Title is empty!",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          content: Text('The title of the note cannot be empty.',
              style: Theme.of(context).textTheme.bodyLarge),
          actions: <Widget>[
            TextButton(
              child: Text("Okay",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.purple)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(
            "Delete Note?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          content: Text("Are you sure you want to delete this note?",
              style: Theme.of(context).textTheme.bodyLarge),
          actions: <Widget>[
            TextButton(
              child: Text("No",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.purple)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Yes",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.purple)),
              onPressed: () {
                Navigator.of(context).pop();
                _delete();
              },
            ),
          ],
        );
      },
    );
  }

  void moveToLastScreen() {
    Navigator.pop(context, true);
  }

  void updateTitle() {
    isEdited = true;
    note.title = titleController.text;
  }

  void updateDescription() {
    isEdited = true;
    note.description = descriptionController.text;
  }

  // Save data to database
  void _save() async {
    moveToLastScreen();

    note.date = DateFormat.yMMMd().format(DateTime.now());

    print('saving note to the database');
    print(note.id);
    if (note.id != null) {
      await helper.updateNote(note);
    } else {
      await helper.insertNote(note);
    }
  }

  void _delete() async {
    await helper.deleteNote(note.id!);
    moveToLastScreen();
  }
}
