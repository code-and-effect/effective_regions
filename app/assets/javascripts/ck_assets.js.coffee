getCkEditorFuncNum = ->
  reParam = new RegExp( '(?:[\?&]|&)' + 'CKEditorFuncNum' + '=([^&]+)', 'i' )
  match = window.location.search.match(reParam)

  if match && match.length > 0
    match[1]

$(document).on 'click', 'a[data-insert-ck-asset]', (event) ->
  ckeditor = getCkEditorFuncNum()

  if ckeditor && window.opener && window.opener.CKEDITOR
    event.preventDefault()

    attachment = $(event.currentTarget)

    url = attachment.attr('href') || attachment.attr('src')
    alt = attachment.attr('alt') || ''

    window.opener.CKEDITOR.tools.callFunction(ckeditor, url, ->
      dialog = this.getDialog()

      if dialog && dialog.getName() == 'image2'
        dialog.getContentElement('info', 'alt').setValue(alt)
    )

    window.close()

