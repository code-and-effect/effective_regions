module Effective
  class RegionsController < ::ApplicationController
    skip_authorization_check if defined?(CanCan)
    respond_to :html
    layout false

    def edit(options = {}, &block)
      render :text => '', :layout => 'effective_mercury'
      # if params[:mercury_frame]
      #   render
      # elsif resource.snippets.present?
      #   render(:file => 'effective/mercury/_load_snippets', :layout => 'effective_mercury')
      # else
      #   render(:text => '', :layout => 'effective_mercury')
      # end
    end

    def update(options = {}, &block)
      #region_params = params.require('content').permit!()  # Strong Parameters
      region_params = params[:content]

      Effective::Region.transaction do
        region_params.each do |title, vals|
          if vals[:data].present?
            region = Effective::Region.where(:title => vals[:data][:title], :regionable_type => vals[:data][:regionable_type], :regionable_id => vals[:data][:regionable_id]).first_or_initialize
          else
            region = Effective::Region.where(:title => title, :regionable_type => nil, :regionable_id => nil).first_or_initialize
          end

          region.content = cleanup(vals[:value])
          (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = vals }

          region.save!
        end

        render :text => '', :status => 200
        return
      end

      render :text => '', :status => :unprocessable_entity
    end

    private

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

  end
end

