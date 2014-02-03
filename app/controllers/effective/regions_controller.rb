module Effective
  class RegionsController < ApplicationController
    respond_to :html
    layout false

    def edit
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      render :text => '', :layout => 'effective_mercury'
    end

    def update
      region_params = assign_unique_snippet_ids(params[:content])

      Effective::Region.transaction do
        region_params.each do |title, vals|

          if vals.key?(:data) && vals[:data].key?(:regionable_type) && vals[:data].key?(:regionable_id)
            region = Effective::Region.where(:title => vals[:data][:title], :regionable_type => vals[:data][:regionable_type], :regionable_id => vals[:data][:regionable_id]).first_or_initialize

            if region.persisted? == false
              region.regionable = (vals[:data][:regionable_type].safe_constantize).find(vals[:data][:regionable_id]) rescue nil
            end

            EffectiveRegions.authorized?(self, :update, region.regionable) # can I update the regionable object?
          else
            region = Effective::Region.global.where(:title => title).first_or_initialize
            EffectiveRegions.authorized?(self, :update, region) # can I update the global region?
          end

          region.content = cleanup(vals[:value])
          region.snippets.clear
          (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = vals }
          region.save!
        end

        render :text => '', :status => 200
        return
      end

      render :text => '', :status => :unprocessable_entity
    end

    def list_snippets
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())
      
      snippets = {}

      (params[:snippets] || {}).each do |key, values|
        if values[:regionable_type].present?
          region = Effective::Region.where(values).first
        else
          region = Effective::Region.global.where(values).first
        end

        snippets[key] = region.snippets[key] if (region.snippets[key].present? rescue false)
      end

      render :json => snippets, :status => 200
    end

    private

    # TODO: Also remove any trailing tags that have no content in them....<p></p><p></p>
    def cleanup(str)
      if str
        # Remove the following markup
        #<div data-snippet="snippet_0" class="text_field_tag-snippet">[snippet_0/1]</div>
        # And replace with [snippet_0/1]
        # So we don't have a wrapping div in our final content
        str.scan(/(<div.+?>)(\[snippet_\d+\/\d+\])(<\/div>)/).each do |match|
          str.gsub!(match.join(), match[1]) if match.length == 3
        end

        str.gsub!("\n", '')
        str.chomp!('<br>') # Mercury editor likes to put in extra BRs
        str.strip!
        str
      end
    end

    def assign_unique_snippet_ids(params)
      id = Time.zone.now.to_i

      params.each do |_, region|
        (region[:snippets] || {}).keys.each do |key|
          region[:snippets]["snippet_#{id}"] = region[:snippets].delete(key)
          region[:value].gsub!(key.to_s, "snippet_#{id}")
        end
      end
    end

  end
end

