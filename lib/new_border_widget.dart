import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewBorderWidget extends StatefulWidget {
  final Function(String, String) onClick;

  const NewBorderWidget({super.key, required this.onClick});
  @override
  State<StatefulWidget> createState() => NewBorderWidgetState();
}

class NewBorderWidgetState extends State<NewBorderWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  bool isDifferent = false;
  final TextEditingController _borderController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var style = Theme.of(context).textTheme.titleMedium;
    TableRow constructTableRow(
      BuildContext context,
      String text,
      String hinttext,
      TextEditingController controller,
      String? Function(String?) validator, {
      String prefixText = "",
      FocusNode? focusNode,
      Function? onsubmit,
    }) {
      return TableRow(
        children: [
          Text(text, style: style),
          TextFormField(
            controller: controller,
            validator: validator,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixText: prefixText,
              hintText: hinttext,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onFieldSubmitted: (String _) {
              if (onsubmit != null) onsubmit();
            },
          ),
        ],
      );
    }

    String? validator(String? value) {
      if (value == null || value.isEmpty) {
        return "Name cannot be empty";
      }
      return null;
    }

    // https://stackoverflow.com/a/62965473
    const rowSpacer = TableRow(
      children: [SizedBox(height: 6), SizedBox(height: 6)],
    );

    void submit() {
      if (_formKey.currentState!.validate()) {
        String generalName = _nameController.text;
        String borderName = isDifferent ? _borderController.text : generalName;
        widget.onClick(generalName, borderName);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double padding = max(20, (constraints.maxWidth - 1300) / 2);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
          child: Column(
            children: [
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "What region do you want to add?",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Table(
                      columnWidths: const {1: FractionColumnWidth(0.75)},
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle, // center the text
                      children: [
                        constructTableRow(
                          context,
                          "Name",
                          "Name of the country in OpenStreetMap",
                          _nameController,
                          validator,
                          onsubmit: submit,
                        ),
                        rowSpacer,
                        TableRow(
                          children: [
                            Text(
                              "Name for the border is different",
                              style: style,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Checkbox(
                                value: isDifferent,
                                onChanged: (bool? val) {
                                  setState(() {
                                    isDifferent = val!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (isDifferent)
                          constructTableRow(
                            context,
                            "Name of border",
                            "Name of the border in OpenStreetMap",
                            _borderController,
                            validator,
                            onsubmit: submit,
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 20,
                        children: [
                          FilledButton(
                            onPressed: () {
                              submit();
                            },
                            child: const Text('Add region'),
                          ),
                          FilledButton(
                            // for now: later have it in the top bar somewhere
                            onPressed: () {
                              context.goNamed("ChooseBoundary");
                            },
                            child: const Text('Go back'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
