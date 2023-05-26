CKEDITOR.dialog.add 'read_more_divider', (editor) ->  # Must match the class name of the snippet
  title: 'Read more divider',
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'read_more_info',    # Just an html id, doesn't really matter what is here
      elements: [
        {
          id: 'throwaway'
          type: 'html',
          html: 'Insert a read more divider to separate excerpt content from the full content.',
          setup: (widget) -> this.setValue(widget.data.throwaway)
          commit: (widget) -> widget.setData('throwaway', 'throwaway')
        },
        {
          type: 'html',
          html: 'Anything above the read more divider will be treated as excerpt content<br>and everything below the divider will also be included in the full content.'
        }
      ]
    }
  ]
