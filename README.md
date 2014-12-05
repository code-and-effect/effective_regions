# Effective Regions

Create editable content regions within your existing, ordinary ActionView::Base views, and update content with an actually-good full-screen WYSIWYG editor.

Define and Insert Snippets (mini model-view components) that intelligently render content based on the user selected attributes.

Specify and Insert pre-defined HTML-only templates for small pieces of common HTML.

Uses the actually-good fullscreen editor [effective_ckeditor](https://github.com/code-and-effect/effective_ckeditor) to achieve near perfect WYSIWYG editting of content regions.


## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_regions'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_regions:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the database table name (to use something other than the default 'regions'), manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

Add the following helper to your application layout in the `<head>..</head>` section.  This will have the effect of loading the appropriate javascript & stylesheets only when in 'edit mode'.

```ruby
effective_regions_include_tags
```

Do not add anything to your asset pipeline javascripts or stylesheets.


## Usage

### Regions

Regions can be global, in which each is referenced by a unique name, or belong to a specific object.

If desired, permissions can be configured such that some users may edit global regions but not object regions or vice versa.

The regions can be created with or without default content.  The default content is displayed only when no editable content has been entered.

The names for the regions are to be created on the fly, so you can just make up new names as you go along.

It's super easy to add an effective_region into any regular view, anywhere you want a dynamic content area.

The following is an example of a global region:

```ruby
%h2 This is a header
%p= effective_region :footer_left
```

and another example of the same region with some default content:

```ruby
%h2 This is a header
%p
  = effective_region :footer_left do
    %p Default content
    %p to display when footer_left is empty
```

Anywhere in your application, in any layout or view, refering to `:footer_left` will render the same piece of content.

Effective Regions can also belong to a specific object:

```ruby
%h2= effective_region(@event, :title)

%p
  = effective_region @event, :summary do
    %p= truncate(@event.excerpt)
    %small
      created on
      = @event.created_at

%p= effective_region(@event, :body)
```

Here each `@event` will have a unique `:title`, `:summary` and `:body` regions.


### Restricting Editable Content

Using a regular `effective_region` tells the full-screen editor that any kind of HTML content and all available Snippets are allowed.

This is not always desirable - sometimes you want to lock down the content available to a specific region.

To allow text-only entry with no HTML or snippets, use `simple_effective_region`:

```haml
%h2
  = simple_effective_region @event, :title do
    Default Title
```

The above example ensures that the full-screen editor will only accept a simple title.  No HTML is allowed. No Snippets are allowed.  No newlines or <ENTER> keypresses are allowed.

This gives the user full control of the content, and allows the design and presentation to remain entirely in the hands of the developer.

Similarly, you may want to allow only Snippets to be inserted into a specific region:

```haml
%div
  = snippet_effective_region :sidebar_mentions
```

only one type of snippet to be allowed:

```haml
%div
  = snippet_effective_region(:sidebar_mentions, :snippets => [:mention])
```

or allow full content entry, but only a subset of the available Snippets:

```haml
%div
  = effective_region(:sidebar_mentions, :snippets => [:mention])
```

### Before Save Callback

Sometimes you may want to programmatically massage the content being assigned from the editor.

One use case for this would be to replace a tweet `@someone` mention with a full url to the appropriate twitter page.

Found in the `config/initializers/effective_regions.rb` file, the `config.before_save_method` hook exists for just such a purpose.

This method is called when a User clicks the 'Save' button in the full screen editor.

It will be called once for each region immediately before the regions are saved to the database.

This is not an ActiveRecord `before_save` callback and there is no way to cancel the save.

This method is run on the `controller.view_context`, so you have access to all your regular view helpers as well as the `request` object.

The second argument, `parent`, will be the `Effective::Region`'s parent `regionable` object, or the symbol `:global`.

If you are gsub'ing the `region.content` String value or altering the `region.snippets` Hash values, those changes will not be immediately visible on the front-end.

If you need the User to immediately see these changes, have your Proc or function return the symbol `:refresh`.

Returning the symbol `:refresh` will instruct javascript to perform a full page refresh after the Save is complete.

Warning: Don't change the `region.title` value or the `region.regionable` parent object, as this will just orphan the region.

Use via Proc:

```ruby
config.before_save_method = Proc.new do |region, parent|
  region.content = region.content.gsub('force', 'horse') if region.title == 'body'
  :refresh
end
```

or to use via custom method:

```ruby
config.before_save_method = :my_region_before_save_method
```

And then in your application_controller.rb:

```ruby
def my_region_before_save_method(region, parent)
  if region.title == 'body' && request.fullpath == posts_path
    region.content = region.content.gsub('force', 'horse')
    :refresh
  end
end
```

or to disable completely:

```ruby
config.before_save_method = false
```


## Authorization

All authorization checks are handled via the config.authorization_method found in the effective_regions.rb initializer.

It is intended for flow through to CanCan, but that is not required.

The authorization method can be defined as:

```ruby
EffectiveRegions.setup do |config|
  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) }
end
```

or as a method:

```ruby
EffectiveRegions.setup do |config|
  config.authorization_method = :authorize_effective_regions
end
```

and then in your application_controller.rb:

```ruby
def authorize_effective_regions(action, resource)
  can?(action, resource)
end
```

There are 3 different levels of permissions to be considered:

1. Can I use the editor at all?

can :edit, Effective::Region

2. Can I update the Effective::Region global regions?

can :update, Effective::Region

3. Can I update the individual objects which define `acts_as_regionable`

can :update, ActsAsRegionableObject  # This would be your Event, Post, or Page, or whatever.

If the method or proc returns false (user is not authorized) an `Effective::AccessDenied` exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb

```ruby
rescue_from Effective::AccessDenied do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```

## Snippets

Snippets are intelligent pieces of content that can be dropped into an effective_region through the full-screen editor's 'Insert Snippet' dropdown.

They are based on [CKEditor Widgets](http://docs.ckeditor.com/#!/guide/dev_widgets) but override some of the Widget internals to instead use the server to render content, allowing us to render Rails objects based on the user selected options.

To implement a Snippet, you must write 3 files: a model, a view, and a javascript options file.


## Simple Snippet Example

We are going to create a Snippet called `current_user_info`.

When the snippet is inserted, the user may choose whether the `.email`, `.first_name` or `.last_name` methods will be called on the `current_user` object.

These examples use HAML, but ERB or SLIM will work the same way.

### The Model

A model that extends from `Effective::Snippets::Snippet`

Any snippet models defined in app/models/effective/snippets/*.rb will be automatically detected and usable.

The models here are not ActiveRecord objects, and instead rely on [virtus](https://github.com/solnic/virtus) for the `attribute` functionality.

Any number of configurable options can be specified, but in this example we only have one.

This model file is defined in app/models/effective/snippets/current_user_info.rb

```ruby
module Effective
  module Snippets
    class CurrentUserInfo < Snippet
      attribute :display_method, String
    end
  end
end
```

### The View

The view must be defined as a partial and should be placed in app/views/effective/snippets/_current_user_info.html.haml

```haml
- if current_user.blank?
  = 'Not logged in'

- elsif current_user_info.display_method == 'email'
  = current_user.email

- elsif current_user_info.display_method == 'first_name'
  = current_user.first_name

- elsif current_user_info.display_method == 'last_name'
  = current_user.last_name
```

Or for the meta-programmers, instead of the above, we could:

```haml
= (current_user.send(current_user_info.display_method) rescue 'Not logged in')
```

In the above example, `current_user_info` is the snippet object, and `current_user` is the (probably Devise) User object.


### The Javascript Options File

This file defines the dialog that CKEditor will present when inserting a new Snippet.

This must follow the CKEditor Widget Dialog Window Definition specification, which you can learn more about at:

http://docs.ckeditor.com/#!/guide/widget_sdk_tutorial_2

http://docs.ckeditor.com/#!/api/CKEDITOR.dialog.definition

The javascript file must be placed in app/assets/javascripts/effective/snippets/current_user_info.js.coffee

```Coffeescript
CKEDITOR.dialog.add 'current_user_info', (editor) ->  // Must match the class name of the snippet
  title: 'Current User Info',
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'current_user_info',    // Just an html id, doesn't really matter what is here
      elements: [
        {                         // elements Array should contain one Hash for each Snippet attribute
          id: 'display_method',
          type: 'select',
          label: 'Current User Info',
          items: [
            ['E-mail', 'email'],
            ['First Name', 'first_name'],
            ['Last Name', 'last_name']
          ],
          setup: (widget) -> this.setValue(widget.data.display_method),
          commit: (widget) -> widget.setData('display_method', this.getValue())
        }
      ]
    }
  ]
```

Please note, this file should not be included into the asset pipeline.  It's a standalone javascript file that is read (just once, and then cached) by CKEditor when the Insert Snippet is triggered.

You may be thinking that this file won't be available due to asset digesting, but there is a custom `assets:precompile` enhancement task in the [effective_ckeditor](https://github.com/code-and-effect/effective_ckeditor) gem (a dependency of this gem) that ensures these snippet options files are available at the non-digested file path.  This just works and is not something you need to worry about.

### Summary

We have created a simple Snippet to display the current_user's email, first_name or last_name.

When any logged in user visits this page, their specific instance of current_user will be called, and they will see their own email, first or last name.

Once the Snippet is inserted, the user editting the page can double-click the Snippet and set the display_method to something else.


## Advanced Snippet Example

The above, simple, example works great because `current_user` is something always available to the application.

In this next example we are going to create a Snippet to insert a summary and link to a `Post` which is created using the standard Rails CRUD workflow.

We must use an AJAX request to query all current Posts, rather than just the ones available at compile/deploy time.

### The Model

This snippet model is defined in app/models/effective/snippets/post.rb

```ruby
module Effective
  module Snippets
    class Post < Snippet
      attribute :post_id, Integer

      def post_object
        # We're using ::Post to refer to the app/models/post.rb rather than the Effective::Snippets::Post
        @post ||= ::Post.find_by_id(post_id)
      end

    end
  end
end
```

### The View

This view partial is defined in app/views/effective/snippets/_post.html.haml

Some advanced snippet partials work best with CKEditor when you can start them with a parent div.  This one isn't advanced enough to actually matter.

```haml
.post
  %h3= post.post_object.title
  %small
    This is post number
    = post.post_object.id
    created on
    = post.created_at

  %p= post.post_object.summary
```

### The Javascript Options File

The javascript file should be placed in app/assets/javascripts/effective/snippets/post.js.coffee

```Coffeescript
getPosts = ->
  posts = []

  $.ajax
    url: '/effective/snippets/posts'
    type: 'GET'
    dataType: 'json'
    async: false
    complete: (data) -> posts = data.responseJSON

  posts

CKEDITOR.dialog.add 'post', (editor) ->
  title: 'Post'
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'post',
      elements: [
        {
          id: 'post_id',
          type: 'select',
          label: 'Post',
          items: getPosts(),  # This only runs once, when the Dialog is created.
          setup: (widget) -> this.setValue(widget.data.post_id)
          commit: (widget) -> widget.setData('post_id', this.getValue())
        }
      ]
    }
  ]
```

So when the Snippet dialog for an 'Insert Snippet' -> Post is opened, an AJAX request to the server is made, and the list of Posts is read.

### The Controller

This controller is in no way part of the effective_regions/effective_ckeditor magic.  It's just a one-off controller action.

For consistency with the other file paths (which do matter), I have namespaced the action under effective/snippets/, but this could be any valid rails route.

This controller is defined in app/controllers/effective/snippets/posts_controller.rb

```ruby
module Effective
  module Snippets
    class PostsController < ApplicationController
      respond_to :json

      def index
        authorize! :index, Post  # CanCan authorization here

        @posts = Post.order(:title).map { |post| [post.title, post.id] }.to_json

        respond_with @posts
      end
    end
  end
end
```

and then in your routes.rb:

```ruby
get '/effective/snippets/posts', :to => 'effective/snippets/posts#index'
```

### Default Content

We can pre-populate an effective_region's default content with some posts.  These posts will be displayed until a user edits that region and selects some specific posts.

```haml
%h2 Posts

= snippet_effective_region :sidebar_posts, :snippets => [:post] do
  - Post.order(:created_at).first(5).each do |post|
    = render_snippet Effective::Snippets::Post.new(:post_id => post.id)
```


### Summary

This Snippet makes an AJAX request to the server and receives a JSON response containing all the Posts.  The Posts are displayed in a select drop-down, and when one is chosen, inserted into the given region.


## Templates

Templates are small pieces of reusable HTML that can be inserted into an `effective_region` with just one or two clicks.

Unlike snippets, there are no configurable options or anything.  They're just pieces of raw HTML that can be dropped in and then immediately editted.

While handy, they were implemented as a bit of an after-thought, and will probably be refactored in future versions of effective_regions.

They take the form of two files, a model and a view.

### The Model

A model extends from `Effective::Templates::Template`

Any template models defined in app/models/effective/templates/*.rb will be automatically detected and usable.

The model here is very minimalistic.  It's basically just to inform the full-screen editor that a View with the same name exists.

This model is defined at app/models/effective/templates/two_column.rb

```ruby
module Effective
  module Templates
    class TwoColumn < Template
      def description
        'Two Column Area'
      end
    end
  end
end
```

### The View

The view is defined at app/models/effective/templates/_two_column.html.haml

```haml
.row
  .col-sm-6
    %p Left Column
  .col-sm-6
    %p Right column
```

## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect


## Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

