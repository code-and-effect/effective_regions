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

      to_save = [] # ActiveRecord object that declare acts_as_regionable or Effective::Region objects (also ActiveRecords)

      region_params.each do |title, vals|
        if vals.key?(:data) && vals[:data].key?(:regionable_type) && vals[:data].key?(:regionable_id)
          regionable = (vals[:data][:regionable_type].safe_constantize).find(vals[:data][:regionable_id]) rescue nil

          if regionable
            EffectiveRegions.authorized?(self, :update, regionable) # can I update the regionable object?

            region = regionable.regions.find { |region| region.title == vals[:data][:title] } 
            region ||= regionable.regions.build(:title => vals[:data][:title])

            to_save << regionable
          end
        else
          region = Effective::Region.global.where(:title => title).first_or_initialize
          EffectiveRegions.authorized?(self, :update, region) # can I update the global region?

          to_save << region
        end

        region.content = cleanup(vals[:value])

        region.snippets.clear
        (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = vals }
      end

      Effective::Region.transaction do
        to_save.uniq.each { |obj| obj.save! } # We're relying on has_many :autosave => true to save our region objects

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
        #<div data-snippet="snippet_0" class="text_field_tag-snippet">[snippet_01]</div>
        # And replace with [snippet_01]
        # So we don't have a wrapping div in our final content
        str.scan(/(<div.+?>)(\[snippet_\d+\])(<\/div>)/).each do |match|
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

          region[:value].scan(/(snippet_\d+)(\/\d+)/).each do |match|  # Replace any snippet_0/1 with snippet_0
            region[:value].gsub!(match.join(), match[0]) if match.length == 2
          end

          region[:value].gsub!('"' + key + '"', '"' + "snippet_#{id}" + '"')
          region[:value].gsub!('[' + key + ']', '[' + "snippet_#{id}" + ']')
          region[:value].gsub!("'" + key + "'", "'" + "snippet_#{id}" + "'")

          id += 1
        end
      end

      params
    end

  end
end

