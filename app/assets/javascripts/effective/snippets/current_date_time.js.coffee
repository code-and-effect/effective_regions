CKEDITOR.dialog.add 'current_date_time', (editor) ->
  title: 'Current Date / Time',
  minWidth: 250,
  minHeight: 200,
  contents: [
    {
      id: 'current_date_time',
      elements: [
        {
          id: 'format',
          type: 'text',
          label: 'Date / Time Format',
          setup: (widget) -> this.setValue(widget.data.format),
          commit: (widget) -> widget.setData('format', this.getValue())
        },
        {
          id: 'help-text',
          type: 'html',
          html: '<p>Examples:</p><br><table width="100%"><tr><td>%Y-%m-%d</td><td width="100%">&nbsp;&nbsp;&nbsp;</td><td>2015-12-25</td></tr><tr><td>%d-%b-%Y</td><td>&nbsp;&nbsp;&nbsp;</td><td>25-Dec-2015</td></tr><tr><td>&nbsp;</td><td></td><td></td></tr><tr><td>%H:%M:%S</td><td>&nbsp;&nbsp;&nbsp;</td><td>18:30:15</td></tr><tr><td>%I:%M%P</td><td>&nbsp;&nbsp;&nbsp;</td><td>6:30pm</td></tr></table><br><p>For a complete reference, please visit:<br><a href="http://apidock.com/ruby/DateTime/strftime" target="_blank">http://apidock.com/ruby/DateTime/strftime</a></p>'
        }
      ]
    }
  ]
