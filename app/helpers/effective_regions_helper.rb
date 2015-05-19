module EffectiveRegionsHelper
  def effective_region(*args)
    options = args.extract_options!
    block_given? ? ckeditor_region(args, options) { yield } : ckeditor_region(args, options)
  end

  def simple_effective_region(*args)
    (options = args.extract_options!).merge!(:type => :simple)
    block_given? ? ckeditor_region(args, options) { yield } : ckeditor_region(args, options)
  end

  def snippet_effective_region(*args)
    (options = args.extract_options!).merge!(:type => :snippets)
    block_given? ? ckeditor_region(args, options) { yield } : ckeditor_region(args, options)
  end

  def wrapped_snippet_effective_region(*args)
    (options = args.extract_options!).merge!(:type => :wrapped_snippets)
    block_given? ? ckeditor_region(args, options) { yield } : ckeditor_region(args, options)
  end

  # Loads the Ckeditor Javascript & Stylesheets only when in edit mode
  def effective_regions_include_tags
    if effectively_editing?
      payload = {
        :snippets => Effective::Snippets::Snippet.all(controller),
        :templates => Effective::Templates::Template.all(controller)
      }

      if defined?(EffectivePages) && defined?(EffectiveRoles)
        payload[:roles] = EffectiveRoles.roles_collection(Effective::Menu.new(), current_user)
        payload[:pages] = ([['', '']] + Effective::Page.order(:title).map { |page| [page.title, page.id] })
      end

      javascript_include_tag('effective_ckeditor') + stylesheet_link_tag('effective_ckeditor') +
      render(:partial => 'effective_regions/include_tags_javascript', :locals => {:payload => payload})
    end
  end

  private

  def ckeditor_region(args, options = {}, &block)
    obj = args.first
    title = args.last.to_s.parameterize
    editable_tag = options.delete(:editable_tag) || :div
    snippet_locals = options.delete(:snippet_locals) # These get passed into the Snippet.new() model

    # Set up the editable div options we need to send to ckeditor
    if effectively_editing?
      opts = {
        :contenteditable => true,
        'data-effective-ckeditor' => (options.delete(:type) || :full).to_s,
        'data-allowed-snippets' => [options.delete(:snippets)].flatten.compact.to_json,
        :style => ['-webkit-user-modify: read-write;', options.delete(:style), ('display: inline;' if options.delete(:inline))].compact.join(' '),
        :class => ['effective-region', options.delete(:class)].compact.join(' ')
      }.merge(options)
    end

    if obj.kind_of?(ActiveRecord::Base)
      raise StandardError.new('Object passed to effective_region helper must declare act_as_regionable') unless obj.respond_to?(:acts_as_regionable)

      region = obj.regions.find { |region| region.title == title }

      if effectively_editing?
        can_edit = (EffectiveRegions.authorized?(controller, :update, obj) rescue false)
        opts[:id] = [model_name_from_record_or_class(obj).param_key(), obj.id, title].join('_')
      end
    else # This is a global region
      regions = (@effective_regions_global ||= Effective::Region.global.to_a)
      region = regions.find { |region| region.title == title } || Effective::Region.new(:title => title)

      if effectively_editing?
        can_edit = (EffectiveRegions.authorized?(controller, :update, region) rescue false)
        opts[:id] = title.to_s.parameterize
      end
    end

    if effectively_editing? && (can_edit && options[:editable] != false) # If we need the editable div
      content_tag(editable_tag, opts) do
        region.try(:content).present? ? render_region(region, true, snippet_locals) : (capture(&block) if block_given?)
      end
    else
      region.try(:content).present? ? render_region(region, false, snippet_locals) : (capture(&block) if block_given?)
    end
  end

  def render_region(region, can_edit = true, snippet_locals = {})
    return '' unless region

    region.content.tap do |html|
      html.scan(/\[(snippet_\d+)\]/).flatten.uniq.each do |id| # find snippet_1 and replace with snippet content
        snippet = region.snippet_objects(snippet_locals).find { |snippet| snippet.id == id }
        html.gsub!("[#{id}]", render_snippet(snippet, can_edit)) if snippet
      end
    end.html_safe
  end

  def render_snippet(snippet, can_edit = true)
    return '' unless snippet

    if Rails.env.production?
      content = render(:partial => snippet.to_partial_path, :object => snippet, :locals => {:snippet => snippet}) rescue ''
    else
      content = render(:partial => snippet.to_partial_path, :object => snippet, :locals => {:snippet => snippet})
    end

    if effectively_editing? && can_edit
      content_tag(snippet.snippet_tag, content, :data => {'effective-snippet' => snippet.class_name, 'snippet-data' => snippet.data().to_json})
    else
      content
    end.html_safe
  end



end
