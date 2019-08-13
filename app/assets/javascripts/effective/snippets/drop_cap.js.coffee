CKEDITOR.dialog.add 'drop_cap', (editor) ->  # Must match the class name of the snippet
  title: 'A drop cap',
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'drop_cap_id',    # Just an html id, doesn't really matter what is here
      elements: [
        {
          id: 'letter'
          type: 'text',
          label: 'Letter (required)',
          setup: (widget) -> this.setValue(widget.data.letter)
          commit: (widget) -> widget.setData('letter', this.getValue())
        },
        {
          id: 'html_class'
          type: 'text',
          label: 'Additional html classes (optional)',
          setup: (widget) -> this.setValue(widget.data.html_class)
          commit: (widget) -> widget.setData('html_class', this.getValue())
        }
      ]
    }
  ]
