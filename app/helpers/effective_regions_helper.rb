module EffectiveRegionsHelper
  def effective_region(*args)
    options = args.extract_options!
    block_given? ? mercury_region(args, options) { yield } : mercury_region(args, options)
  end

  def simple_effective_region(*args)
    (options = args.extract_options!).merge!(:type => :simple)
    block_given? ? mercury_region(args, options) { yield } : mercury_region(args, options)
  end

  def snippet_effective_region(*args)
    (options = args.extract_options!).merge!(:type => :snippets)
    block_given? ? mercury_region(args, options) { yield } : mercury_region(args, options)
  end

  private

  def mercury_region(args, options = {}, &block)
    type = (options.delete(:type) || :full).to_s

    obj = args.first
    title = args.last.to_s
    editting = request.fullpath.include?('mercury_frame')

    if obj.kind_of?(ActiveRecord::Base)
      raise StandardError.new('Object passed to effective_region helper must declare act_as_regionable') unless obj.respond_to?(:acts_as_regionable)

      opts = {:id => [obj.class.name.gsub('::', '').downcase, obj.id, title].join('_'), 'data-mercury' => type, 'data-title' => title, 'data-regionable_type' => obj.class.name, 'data-regionable_id' => obj.id}.merge(options)

      region = obj.regions.find { |region| region.title == title }
      content = region.try(:content)
      can_edit = (EffectiveRegions.authorized?(controller, :update, obj) rescue false) if editting
    else
      opts = {:id => title, 'data-mercury' => type, 'data-title' => title}.merge(options)

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
  # <div data-snippet="snippet_0" class="text_field_tag-snippet">[snippet_0]</div>
  def editable(html, region)
    html.scan(/\[(snippet_\d+)\]/).flatten.each do |id|  # Finds snippet_1
      snippet = region.snippet_objects.find { |snippet| snippet.id == id }
      html.gsub!("[#{id}]", snippet.to_editable_div) if snippet
    end
    html
  end

  def expand_snippets(html, region, options)
    html.scan(/\[(snippet_\d+)\]/).flatten.each do |id| # find snippet_1 and insert snippet content
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
