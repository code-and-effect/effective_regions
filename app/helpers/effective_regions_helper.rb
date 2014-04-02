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

  # Loads the Ckeditor Javascript & Stylesheets only when in edit mode
  def effective_regions_include_tags
    if request.fullpath.include?('?edit=true')
      javascript_include_tag('effective_ckeditor') + stylesheet_link_tag('effective_ckeditor')
    end
  end

  private

  def ckeditor_region(args, options = {}, &block)
    type = (options.delete(:type) || :full).to_s

    obj = args.first
    title = args.last.to_s.parameterize
    editting = request.fullpath.include?('?edit=true')

    if obj.kind_of?(ActiveRecord::Base)
      raise StandardError.new('Object passed to effective_region helper must declare act_as_regionable') unless obj.respond_to?(:acts_as_regionable)

      opts = {:id => [model_name_from_record_or_class(obj).param_key(), obj.id, title].join('_'), 'data-effective-ckeditor' => type, :contenteditable => true, :style => '-webkit-user-modify: read-write;', :class => 'effective-region'}.merge(options)

      region = obj.regions.find { |region| region.title == title }
      content = region.try(:content)
      can_edit = (EffectiveRegions.authorized?(controller, :update, obj) rescue false) if editting
    else
      opts = {:id => title.to_s.parameterize, 'data-effective-ckeditor' => type, :contenteditable => true, :style => '-webkit-user-modify: read-write;', :class => 'effective-region'}.merge(options)

      region = Effective::Region.global.where(:title => title).first_or_initialize
      content = region.try(:content)
      can_edit = (EffectiveRegions.authorized?(controller, :update, region) rescue false) if editting
    end

    if editting && can_edit # If we need the editable div
      content_tag(:div, opts) do
        content.present? ? expand_snippets(editable(content, region), region, options).html_safe : ((capture(&block).strip.html_safe) if block_given?)
      end
    else
      content.present? ? expand_snippets(content, region, options).html_safe : ((capture(&block).strip.html_safe) if block_given?)
    end
  end

  # We're finding [snippet_0] and expanding to
  # <div class="text_field_tag_snippet">[snippet_0]</div>
  def editable(html, region)
    html.scan(/\[(snippet_\d+)\]/).flatten.uniq.each do |id|  # Finds snippet_1
      snippet = region.snippet_objects.find { |snippet| snippet.id == id }

      if snippet
        editable_div = content_tag(:div, "[#{snippet.id}]", :class => "#{snippet.class_name}_snippet", :data => {'effective-snippet' => snippet.data}).html_safe
        html.gsub!("[#{id}]", editable_div)
      end

    end
    html
  end

  def expand_snippets(html, region, options)
    html.scan(/\[(snippet_\d+)\]/).flatten.uniq.each do |id| # find snippet_1 and insert snippet content
      content = snippet_content(id, region, options)
      html.gsub!("[#{id}]", content) if content
    end
    html
  end

  def snippet_content(id, region, options = {})
    snippet = (region.try(:snippet_objects) || []).find { |snippet| snippet.id == id }

    if snippet
      render :partial => snippet.to_partial_path, :object => snippet, :locals => options
    end
  end

end
