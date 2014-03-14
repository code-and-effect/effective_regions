CKEDITOR.dialog.add 'current_user_info', (editor) ->
  title: 'Current User info',
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'info',
      elements: [
        {
          id: 'method',
          type: 'select',
          label: 'Current User Info',
          items: [
            ['E-mail', 'email'],
            ['Full Name', 'full_name'],
            ['First Name', 'first_name'],
            ['Last Name', 'last_name']
          ],
          setup: (widget) ->
            this.setValue(widget.data.method)
          commit: (widget) ->
            widget.setData('method', this.getValue())
        }
      ]
    }
  ]
