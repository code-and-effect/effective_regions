module Effective
  class RegionsController < ApplicationController
    respond_to :html, :json
    layout false
    skip_before_filter :verify_authenticity_token, :only => [:update]

    def edit
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      cookies['effective_regions_editting'] = {:value => request.referrer, :path => '/'}

      # TODO: turn this into a cookie or something better.
      redirect_to request.url.gsub('/edit', '') + '?edit=true'
    end

    def update
      Effective::Region.transaction do
        region_params.each do |key, vals| # article_section_2_title => {:content => '<p></p>'}
          to_save = nil  # Which object, the regionable, or the region (if global) to save

          regionable, title = find_regionable(key)

          if regionable
            EffectiveRegions.authorized?(self, :update, regionable) # can I update the regionable object?

            region = regionable.regions.find { |region| region.title == title }
            region ||= regionable.regions.build(:title => title)

            to_save = regionable
          else
            region = Effective::Region.global.where(:title => title).first_or_initialize
            EffectiveRegions.authorized?(self, :update, region) # can I update the global region?

            to_save = region
          end

          region.content = cleanup(vals[:content])

          region.snippets = HashWithIndifferentAccess.new()
          (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = vals }

          to_save.save!
        end

        render :text => '', :status => 200
        return
      end

      render :text => 'error', :status => :unprocessable_entity
    end

    def snippets
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      retval = {}
      EffectiveRegions.snippets.each do |snippet|
        retval[snippet.class_name] = {
          :dialog_url => snippet.snippet_dialog_url, 
          :label => snippet.snippet_label, 
          :description => snippet.snippet_description,
          :inline => snippet.snippet_inline,
          :editables => snippet.snippet_editables,
          #:template => ActionView::Base.new(ActionController::Base.view_paths, {}, ActionController::Base.new).render(:partial => snippet.to_partial_path, :object => snippet, :locals => {:snippet => snippet})
        }
      end

      render :json => retval
    end

    def snippet # This is a GET.  CKEDITOR passes us data, we need to render the non-editable content
      klass = "Effective::Snippets::#{region_params[:name].try(:classify)}".safe_constantize

      if klass.present?
        @snippet = klass.new(region_params[:data])
        render :partial => @snippet.to_partial_path, :object => @snippet, :locals => {:snippet => @snippet, :snippet_preview => true}
      else
        render :text => "Missing class Effective::Snippets::#{region_params[:name].try(:classify)}"
      end
    end

    protected

    def find_regionable(key)
      regionable = nil
      title = nil

      if(class_name, id, title = key.scan(/(\w+)_(\d+)_(\w+)/).flatten).present?
        regionable = (class_name.classify.safe_constantize).find(id) rescue nil
      end

      return regionable, (title || key)
    end

    def cleanup(str)
      (str || '').tap do |str|
        str.chomp!('<p>&nbsp;</p>') # Remove any trailing empty <p>'s
        str.gsub!("\n", '')
        str.strip!
      end
    end

    def region_params
      begin
        params.require(:effective_regions).permit!
      rescue => e
        params[:effective_regions]
      end
    end
  end
end

