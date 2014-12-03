module Effective
  class Region < ActiveRecord::Base
    self.table_name = EffectiveRegions.regions_table_name.to_s

    belongs_to :regionable, :polymorphic => true

    structure do
      title             :string, :validates => [:presence]
      content           :text
      snippets          :text

      timestamps
    end

    serialize :snippets, HashWithIndifferentAccess

    scope :global, -> { where("#{EffectiveRegions.regions_table_name}.regionable_type IS NULL").where("#{EffectiveRegions.regions_table_name}.regionable_id IS NULL") }

    def snippets
      self[:snippets] || HashWithIndifferentAccess.new()
    end

    # Hash of the Snippets objectified
    #
    # Returns a Hash of {'snippet_1' => CurrentUserInfo.new(snippets[:key]['options'])}
    def snippet_objects
      @snippet_objects ||= snippets.map do |key, snippet|  # Key here is 'snippet_1'
        if snippet['class_name']
          klass = "Effective::Snippets::#{snippet['class_name'].classify}".safe_constantize
          klass.new(snippet.merge!(:region => self, :id => key)) if klass
        end
      end.compact
    end

    def global?
      regionable_id == nil && regionable_type == nil
    end

  end
end




