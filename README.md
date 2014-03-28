# Effective Regions

A drop-in CMS helper for dynamically creating editable regions in any standard ActionView view template.

Also has the use of Snippets, predefined blocks of functionality.

Use the full-page on-screen editor (effective_ckeditor) to edit content regions.


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

Mount the Rails Engine at the root location.  This should appear below your root :to => '' definition in your routes.rb file

```ruby
mount EffectiveRegions::Engine => '/', :as => 'effective_regions'
```

Add the following helper to your application layout in the <head>..</head> section.  This will have the effect of loading the appropriate javascript & stylesheets only when in 'edit mode'.

```ruby
effective_regions_include_tags
```

Do not add anything to your asset pipeline javascripts or stylesheets.


## Usage

### Authorization

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

3. Can I update the individual objects which define acts_as_regionable

can :update, ActsAsRegionableObject  # This would be your Post, or Page, or whatever.

If the method or proc returns false (user is not authorized) an Effective::AccessDenied exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb

```ruby
rescue_from Effective::AccessDenied do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```

### Creating a Snippet

Snippets are configurable blocks of content that can be dropped into an effective_region through the 'Insert Snippet' dropdown.

They consist of a model, a view, and a javascript 'options' file.

#### The Model

A model that extends from Effective::Snippets::Snippet

Any snippets defined in app/models/effective/snippets/*.rb will be automatically detected and usable.

They can define one or more attribute that is configurable.

```ruby
module Effective
  module Snippets
    class ArticleWithExcerpt < Snippet
      attribute :article_id, Integer

      def article
        Article.find(self.article_id)
      end

    end
  end
end
```

#### The View

The view partial should be placed in app/views/effective/snippets/article_with_excerpt/_article_with_excerpt.html.haml

```ruby
%p This is an article snippet
%p= article.title
%p= article_with_excerpt.article_id
```

#### The Javascript Options File

This file defines the dialog that CKEditor will present when inserting a new Snippet.

This is only the Widget Dialog Window Definition file, which you can learn more about at:

http://docs.ckeditor.com/#!/guide/widget_sdk_tutorial_2
http://docs.ckeditor.com/#!/api/CKEDITOR.dialog.definition

The javascript file should be placed in app/assets/javascripts/effective/snippets/article_with_excerpt.js.coffee

```Coffeescript
CKEDITOR.dialog.add 'article_with_excerpt', (editor) ->
  title: 'Article With Excerpt',
  minWidth: 200,
  minHeight: 100,
  contents: [
    {
      id: 'article_with_excerpt',
      elements: [
        {
          id: 'article_id',
          type: 'select',
          label: 'Article',
          items: <%= Article.all.map { |article| [article.title, article.id] } %>,
          setup: (widget) -> this.setValue(widget.data.article_id),
          commit: (widget) -> widget.setData('article_id', this.getValue())
        }
      ]
    }
  ]

```

Please note, this file should not be placed into the asset pipeline.


## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect
