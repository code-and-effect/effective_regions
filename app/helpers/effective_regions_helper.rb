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
    tag = options.delete(:tag) || :div

    obj = args.first
    title = args.last.to_s
    editting = request.fullpath.include?('mercury_frame')

    if obj.kind_of?(ActiveRecord::Base)
      raise StandardError.new('Object passed to page_region helper must declare act_as_regionable') unless obj.respond_to?(:acts_as_regionable)

      opts = {:id => [obj.class.name.gsub('::', '').downcase, obj.id, title].join('_'), 'data-mercury' => type, 'data-title' => title, 'data-regionable_type' => obj.class.name, 'data-regionable_id' => obj.id}.merge(options)

      region = obj.regions.to_a.find { |region| region.title == title }
      content = region.try(:content)
      can_edit = (EffectiveRegions.authorized?(controller, :update, obj) rescue false) if editting
    else
      opts = {:id => title, 'data-mercury' => type, 'data-title' => title}.merge(options)

      region = Effective::Region.global.where(:title => title).first_or_initialize
      content = region.try(:content)
      can_edit = (EffectiveRegions.authorized?(controller, :update, region) rescue false) if editting
    end

    if editting && can_edit # If we need the editable div
      content_tag(tag, opts) do
        content.present? ? expand_snippets(editable(content, region), region, options).html_safe : ((capture(&block).strip.html_safe) if block_given?)
      end
    else
      content.present? ? expand_snippets(content, region, options).html_safe : ((capture(&block).strip.html_safe) if block_given?)
    end
  end

  # We're finding [snippet_0/1] and expanding to
  # <div data-snippet="snippet_0" class="text_field_tag-snippet">[snippet_0/1]</div>
  def editable(html, region)
    html.scan(/\[snippet_\d+\]/).flatten.each do |snippet|  # Find [snippet_1]
      id = snippet.scan(/\d+/).try(:first).to_i
      html.gsub!(snippet, "<div data-snippet='snippet_#{id}' class='#{(region.snippets["snippet_#{id}"][:name] rescue '')}_snippet'>[snippet_#{id}]</div>")
    end
    html
  end

  def expand_snippets(html, region, options)
    snippets = html.scan(/\[snippet_\d+\]/).flatten  # find [snippet_1] and insert snippet content

    snippets.each { |snippet| html.gsub!(snippet, snippet_content(snippet, region, options)) }
    html
  end

  def snippet_content(code, region, options = {})
    return code unless region.present?

    key = code.scan(/\[(snippet_\d+)\]/).flatten.first # captures [(snippet_1)]

    snippet = region.snippets[key] || {}
    return code unless snippet['name'].present?

    klass = "Effective::Snippets::#{snippet['name'].try(:classify)}".safe_constantize
    return code unless klass

    snippet = klass.new(snippet['options'])
    render :partial => snippet.to_partial_path, :object => snippet, :locals => options
  end

end
